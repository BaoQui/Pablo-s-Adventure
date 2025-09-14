extends CharacterBody2D

# --- Motion ---
@export var move_speed: float = 140.0
@export var acceleration: float = 1200.0
@export var deceleration: float = 2200.0
@export var pattern_duration: float = 2.5

# --- Patterns ---
enum Pattern { HOVER, SINE, BURST }
@export var pattern_weights: PackedFloat32Array = [3.0, 2.0, 1.5]
@export var wander_range: float = 140.0
@export var sine_amplitude: float = 40.0
@export var sine_freq: float = 3.0
@export var burst_speed: float = 300.0

# --- Optional roam bounds (set in Inspector). If size==0, tries to infer from named walls. ---
@export var patrol_rect: Rect2

# --- Wall awareness / steering (prevents picking moves into walls) ---
@export var lookahead_dist: float = 18.0
@export var bounce_cooldown: float = 0.12
@export var separation_push: float = 10.0 # tiny nudge off surfaces

# --- CEILING forced-down behavior ---
@export var forced_down_speed: float = 240.0
@export var forced_down_time: float = 2.0 # seconds to fly straight down

# --- Hit reaction (away from punch source) ---
@export var knockback_speed: float = 520.0
@export var knockback_duration: float = 0.22

# --- Health ---
@export var health: int = 50

@onready var pattern_timer: Timer = $PatternTimer

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var current_pattern: int = Pattern.HOVER
var base_pos: Vector2
var target_pos: Vector2
var sine_t: float = 0.0

# Knockback / anti-stick
var knockback_timer: float = 0.0
var knockback_dir: Vector2 = Vector2.ZERO
var wall_cooldown: float = 0.0

# Forced descent state
enum ForcedState { NONE, DOWN }
var forced_state: int = ForcedState.NONE
var forced_timer: float = 0.0

func _ready() -> void:
	rng.randomize()
	_try_infer_patrol_rect_from_walls()
	if not pattern_timer.is_connected("timeout", Callable(self, "_on_pattern_timeout")):
		pattern_timer.connect("timeout", Callable(self, "_on_pattern_timeout"))
	pattern_timer.wait_time = pattern_duration
	pattern_timer.start()
	_pick_new_pattern()

func _physics_process(delta: float) -> void:
	knockback_timer -= delta
	wall_cooldown = maxf(wall_cooldown - delta, 0.0)

	# --- Forced descent after hitting Ceiling ---
	if forced_state != ForcedState.NONE:
		forced_timer -= delta
		var desired_v_forced: Vector2 = Vector2(0.0, forced_down_speed)
		velocity.x = move_toward(velocity.x, desired_v_forced.x, acceleration * delta)
		velocity.y = move_toward(velocity.y, desired_v_forced.y, acceleration * delta)
		move_and_slide()
		_post_move_separation(delta) # Added from Prekene
		if forced_timer <= 0.0:
			forced_state = ForcedState.NONE
			_restart_pattern_cycle()
		return

	# --- Normal behavior ---
	var desired_v: Vector2
	if knockback_timer > 0.0:
		desired_v = knockback_dir * knockback_speed
	else:
		desired_v = _pattern_velocity(delta)
		desired_v = _steer_away_from_walls(desired_v)

	velocity.x = move_toward(velocity.x, desired_v.x, acceleration * delta)
	velocity.y = move_toward(velocity.y, desired_v.y, acceleration * delta)

	move_and_slide()
	_handle_named_bounds(delta)

func _handle_named_bounds(delta: float) -> void:
	for i in range(get_slide_collision_count()):
		var c := get_slide_collision(i)
		if c == null:
			continue
		var collider := c.get_collider()
		if collider == null or not (collider is Node):
			continue
		var name_str: String = (collider as Node).name

		if name_str == "Ceiling":
			# Enter forced downward flight for forced_down_time, restart patterns after
			forced_state = ForcedState.DOWN
			forced_timer = forced_down_time
			pattern_timer.stop() # pause pattern switching during forced state
			global_position.y += separation_push * delta # small separation so we don't keep colliding
			velocity = Vector2(0.0, forced_down_speed) # immediate downward response
			return
		elif name_str == "Floor":
			global_position.y -= separation_push * delta
			if velocity.y > -forced_down_speed:
				velocity.y = -forced_down_speed
		elif name_str == "Right_Wall":
			global_position.x -= separation_push * delta
			if velocity.x > 0.0:
				velocity.x = -absf(velocity.x)
		elif name_str == "Left_Wall":
			global_position.x += separation_push * delta
			if velocity.x < 0.0:
				velocity.x = absf(velocity.x)
	# Gentle separation from any surface we’re pressed against (from Prekene)
	_post_move_separation(delta)

func _post_move_separation(delta: float) -> void:
	# Optional gentle separation from any surface we touched to avoid micro-sticking
	for i in range(get_slide_collision_count()):
		var c := get_slide_collision(i)
		if c == null:
			continue
		var n: Vector2 = c.get_normal()
		# Nudge away a little
		global_position += n * (separation_push * 0.5 * delta)

func _on_pattern_timeout() -> void:
	_pick_new_pattern()

func _restart_pattern_cycle() -> void:
	_pick_new_pattern()
	pattern_timer.wait_time = pattern_duration
	pattern_timer.start()

func _pick_new_pattern() -> void:
	current_pattern = _weighted_choice(pattern_weights)
	base_pos = global_position
	sine_t = 0.0
	if current_pattern == Pattern.HOVER:
		target_pos = _pick_hover_target()

func _pick_hover_target() -> Vector2:
	var attempt_count: int = 0
	while attempt_count < 6:
		var candidate: Vector2
		if patrol_rect.size.x > 0.0 and patrol_rect.size.y > 0.0:
			candidate = Vector2(
				rng.randf_range(patrol_rect.position.x, patrol_rect.position.x + patrol_rect.size.x),
				rng.randf_range(patrol_rect.position.y, patrol_rect.position.y + patrol_rect.size.y)
			)
		else:
			candidate = base_pos + Vector2(
				rng.randf_range(-wander_range, wander_range),
				rng.randf_range(-wander_range, wander_range)
			)
		var dir: Vector2 = (candidate - global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		if not test_move(global_transform, dir * lookahead_dist):
			return candidate
		attempt_count += 1
	# fallback
	return global_position + Vector2(wander_range, 0.0)

func _pattern_velocity(delta: float) -> Vector2:
	match current_pattern:
		Pattern.HOVER:
			if global_position.distance_to(target_pos) < 8.0:
				target_pos = _pick_hover_target()
			return (target_pos - global_position).normalized() * move_speed
		Pattern.SINE:
			sine_t += delta
			var vx: float = move_speed * 0.7
			var vy: float = sin(sine_t * TAU * sine_freq) * sine_amplitude
			return Vector2(vx, vy)
		Pattern.BURST:
			return Vector2(burst_speed, 0.0)
	return Vector2.ZERO

func _steer_away_from_walls(desired_v: Vector2) -> Vector2:
	if wall_cooldown > 0.0:
		return desired_v
	var out_v: Vector2 = desired_v
	# Probe X
	if absf(out_v.x) > 0.01:
		var step_x: Vector2 = Vector2(signf(out_v.x), 0.0) * lookahead_dist
		if test_move(global_transform, step_x):
			out_v.x = -out_v.x
	# Probe Y
	if absf(out_v.y) > 0.01:
		var step_y: Vector2 = Vector2(0.0, signf(out_v.y)) * lookahead_dist
		if test_move(global_transform, step_y):
			out_v.y = -out_v.y
	return out_v

# ---- Utilities ----
func _weighted_choice(weights: PackedFloat32Array) -> int:
	var total: float = 0.0
	for w in weights:
		total += maxf(w, 0.0)
	if total <= 0.0:
		return 0
	var pick: float = rng.randf() * total
	var run: float = 0.0
	for i in weights.size():
		run += maxf(weights[i], 0.0)
		if pick <= run:
			return i
	return 0

func _try_infer_patrol_rect_from_walls() -> void:
	if patrol_rect.size.x > 0.0 and patrol_rect.size.y > 0.0:
		return
	var root: Node = get_tree().root
	var left_node: Node = _find_node_recursive(root, "Left_Wall")
	var right_node: Node = _find_node_recursive(root, "Right_Wall")
	var floor_node: Node = _find_node_recursive(root, "Floor")
	var ceiling_node: Node = _find_node_recursive(root, "Ceiling")
	if left_node == null or right_node == null or floor_node == null or ceiling_node == null:
		return
	var left_x: float = (left_node as Node2D).global_position.x
	var right_x: float = (right_node as Node2D).global_position.x
	var top_y: float = (ceiling_node as Node2D).global_position.y
	var bottom_y: float = (floor_node as Node2D).global_position.y
	var pos: Vector2 = Vector2(minf(left_x, right_x), minf(top_y, bottom_y))
	var size: Vector2 = Vector2(absf(right_x - left_x), absf(bottom_y - top_y))
	if size.x > 0.0 and size.y > 0.0:
		patrol_rect = Rect2(pos, size)

func _find_node_recursive(n: Node, target: String) -> Node:
	if n.name == target:
		return n
	for child in n.get_children():
		var found: Node = _find_node_recursive(child, target)
		if found != null:
			return found
	return null

# ---- Combat ----
func take_damage(damage_amount: int, from_point: Vector2 = Vector2.INF) -> void:
	health -= damage_amount
	print("Enemy took ", damage_amount, " damage. Health is now: ", health)
	if from_point != Vector2.INF:
		var dir: Vector2 = (global_position - from_point).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.LEFT
		knockback_dir = dir
		knockback_timer = knockback_duration
		velocity = knockback_dir * knockback_speed
	if health <= 0:
		print("Enemy defeated!")
		queue_free()