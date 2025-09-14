extends CharacterBody2D

# --- Motion ---
@export var move_speed: float = 100.0
@export var acceleration: float = 1000.0
@export var deceleration: float = 1000.0
@export var gravity: float = 1600.0
@export var max_fall_speed: float = 1200.0
@export var pattern_duration: float = 2.5

# --- Patterns (horizontal) ---
enum Pattern { WANDER_X, PACE, STRAFE, BURST }
@export var pattern_weights: PackedFloat32Array = [3.0, 2.0, 2.0, 1.0]
@export var pace_range: float = 80.0
@export var burst_speed: float = 300.0
@export var wander_repick_dist: float = 12.0

# --- Patrol field ---
@export var patrol_rect: Rect2

# --- Wall avoidance ---
@export var lookahead_dist: float = 18.0
@export var bounce_cooldown: float = 0.12
@export var separation_push: float = 14.0

# --- Knockback ---
@export var knockback_speed: float = 500.0
@export var knockback_duration: float = 0.18
@export var knockback_upward: float = 120.0

# --- Health ---
@export var health: int = 50

@onready var pattern_timer: Timer = $PatternTimer

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var current_pattern: int = Pattern.WANDER_X
var base_x: float
var pace_dir: int = 1
var target_x: float = 0.0

var knockback_timer: float = 0.0
var knockback_dir: Vector2 = Vector2.ZERO
var wall_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("Enemy")  # ensure player only hits "Enemy"

	rng.randomize()
	_try_infer_patrol_rect_from_walls()

	if not pattern_timer.is_connected("timeout", Callable(self, "_on_pattern_timeout")):
		pattern_timer.connect("timeout", Callable(self, "_on_pattern_timeout"))
	pattern_timer.wait_time = pattern_duration
	pattern_timer.start()
	_pick_new_pattern()

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y = min(velocity.y + gravity * delta, max_fall_speed)
	else:
		if velocity.y > 0.0:
			velocity.y = 0.0

	knockback_timer -= delta
	wall_cooldown = maxf(wall_cooldown - delta, 0.0)

	var desired_vx: float
	if knockback_timer > 0.0:
		desired_vx = knockback_dir.x * knockback_speed
	else:
		desired_vx = _pattern_desired_vx(delta)
		desired_vx = _steer_x_away_from_walls(desired_vx)

	if absf(desired_vx) > 0.1:
		velocity.x = move_toward(velocity.x, desired_vx, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		if absf(velocity.x) < 1.0:
			velocity.x = 0.0

	move_and_slide()
	_handle_side_walls(delta)

# --- Patterns ---
func _on_pattern_timeout() -> void:
	_pick_new_pattern()

func _pick_new_pattern() -> void:
	current_pattern = _weighted_choice(pattern_weights)
	base_x = global_position.x
	if current_pattern == Pattern.PACE:
		pace_dir = 1 if rng.randi_range(0, 1) == 1 else -1
	elif current_pattern == Pattern.WANDER_X:
		_pick_new_target_x()
	pattern_timer.wait_time = pattern_duration
	pattern_timer.start()

func _pick_new_target_x() -> void:
	if patrol_rect.size.x > 0.0:
		var min_x: float = patrol_rect.position.x + 8.0
		var max_x: float = patrol_rect.position.x + patrol_rect.size.x - 8.0
		target_x = rng.randf_range(min_x, max_x)
	else:
		target_x = base_x + rng.randf_range(-pace_range, pace_range)

func _pattern_desired_vx(_delta: float) -> float:
	match current_pattern:
		Pattern.WANDER_X:
			if absf(global_position.x - target_x) < wander_repick_dist:
				_pick_new_target_x()
			var dir: float = signf(target_x - global_position.x)
			if is_equal_approx(dir, 0.0):
				dir = 1.0 if rng.randi_range(0, 1) == 1 else -1.0
			return dir * move_speed

		Pattern.PACE:
			var left_bound: float = base_x - pace_range
			var right_bound: float = base_x + pace_range
			if patrol_rect.size.x > 0.0:
				var min_x: float = patrol_rect.position.x
				var max_x: float = patrol_rect.position.x + patrol_rect.size.x
				left_bound = clampf(left_bound, min_x, max_x)
				right_bound = clampf(right_bound, min_x, max_x)
			if global_position.x <= left_bound:
				pace_dir = 1
			elif global_position.x >= right_bound:
				pace_dir = -1
			return float(pace_dir) * move_speed

		Pattern.STRAFE:
			if rng.randi_range(0, 100) < 2:
				velocity.x = -velocity.x
			if velocity.x > 0.1:
				return move_speed
			elif velocity.x < -0.1:
				return -move_speed
			else:
				return move_speed

		Pattern.BURST:
			return burst_speed

	return 0.0

func _steer_x_away_from_walls(desired_vx: float) -> float:
	if wall_cooldown > 0.0:
		return desired_vx
	if absf(desired_vx) <= 0.01:
		return desired_vx
	var step_x: Vector2 = Vector2(signf(desired_vx), 0.0) * lookahead_dist
	if test_move(global_transform, step_x):
		return -desired_vx
	return desired_vx

# --- Wall handling ---
func _handle_side_walls(delta: float) -> void:
	for i in range(get_slide_collision_count()):
		var c := get_slide_collision(i)
		if c == null:
			continue
		var collider := c.get_collider()
		if collider == null or not (collider is Node):
			continue
		var name_str: String = (collider as Node).name
		if name_str == "Right_Wall":
			velocity.x = -maxf(absf(velocity.x), move_speed)
			global_position.x -= separation_push * delta
			wall_cooldown = bounce_cooldown
			_pick_new_target_x()
		elif name_str == "Left_Wall":
			velocity.x = maxf(absf(velocity.x), move_speed)
			global_position.x += separation_push * delta
			wall_cooldown = bounce_cooldown
			_pick_new_target_x()

# --- Utils ---
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
	if left_node == null or right_node == null:
		return
	var left_x: float = (left_node as Node2D).global_position.x
	var right_x: float = (right_node as Node2D).global_position.x
	var pos: Vector2 = Vector2(minf(left_x, right_x), global_position.y - 200.0)
	var size: Vector2 = Vector2(absf(right_x - left_x), 400.0)
	if size.x > 0.0:
		patrol_rect = Rect2(pos, size)

func _find_node_recursive(n: Node, target: String) -> Node:
	if n.name == target:
		return n
	for child in n.get_children():
		var found: Node = _find_node_recursive(child, target)
		if found != null:
			return found
	return null

# --- Combat ---
func take_damage(damage_amount: int, from_point: Vector2 = Vector2.INF) -> void:
	health -= damage_amount
	print(name, " took ", damage_amount, " damage. Health is now: ", health)

	if from_point != Vector2.INF:
		# Knockback based on attacker position
		var knockback_strength_x: float = 400.0
		var knockback_strength_y: float = 300.0

		if from_point.x < global_position.x:
			velocity.x = knockback_strength_x   # attacker left → knock right
		else:
			velocity.x = -knockback_strength_x  # attacker right → knock left

		velocity.y = -knockback_strength_y
		knockback_timer = knockback_duration

	if health <= 0:
		die()

func die():
	print("Ground enemy defeated!")
	queue_free()

# --- Hurt player on collision ---
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.do_damage(10, global_position)

		var knockback_strength_x: float = 500.0
		var knockback_strength_y: float = 300.0

		if body.global_position.x < global_position.x:
			body.velocity.x = -knockback_strength_x
		else:
			body.velocity.x = knockback_strength_x

		body.velocity.y = -knockback_strength_y

		if "knockback_timer" in body:
			body.knockback_timer = 0.3
