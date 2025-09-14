extends CharacterBody2D

# --- Horizontal motion ---
@export var move_speed: float = 110.0
@export var start_direction_right: bool = true

# --- Gravity & bounce ---
@export var gravity: float = 1600.0
@export var max_fall_speed: float = 1200.0
@export var bounce_up_speed: float = 540.0   # vertical speed applied on ANY contact with the named ground

# --- Wall handling (reverse horizontal; DOES NOT affect vertical bounce) ---
@export var lookahead_dist: float = 16.0
@export var separation_push: float = 10.0
@export var flip_cooldown: float = 0.08

# --- Damage (optional) ---
@export var health: int = 25
@export var knockback_speed: float = 420.0
@export var knockback_upward: float = 120.0
@export var knockback_time: float = 0.15

# --- Ground identification (hard requirement) ---
@export var ground_shape_name: String = "CollisionShape2D2"

# --- Debug ---
@export var debug_prints: bool = false

var dir: int = 1
var flip_timer: float = 0.0
var knockback_timer: float = 0.0
var knockback_dir_x: float = 0.0

func _ready() -> void:
	dir = 1 if start_direction_right else -1

func _physics_process(delta: float) -> void:
	flip_timer = maxf(flip_timer - delta, 0.0)
	knockback_timer = maxf(knockback_timer - delta, 0.0)

	# Gravity
	if not is_on_floor():
		velocity.y = min(velocity.y + gravity * delta, max_fall_speed)

	# PRE-MOVE lookahead (flip before moving if a wall is directly ahead)
	var step: Vector2 = Vector2(signf(float(dir)), 0.0) * lookahead_dist
	if flip_timer <= 0.0 and test_move(global_transform, step):
		_flip_horizontal("lookahead")

	# Horizontal velocity (knockback overrides)
	if knockback_timer > 0.0:
		velocity.x = knockback_dir_x * knockback_speed
	else:
		velocity.x = float(dir) * move_speed

	# Move
	move_and_slide()

	# Reverse on vertical walls (no vertical bounce here)
	_reverse_if_wall(delta)

	# **MANDATORY**: ALWAYS bounce if we touched the named ground node this frame
	if _touched_named_ground_this_frame():
		velocity.y = -absf(bounce_up_speed)
		if debug_prints:
			print("[Bouncer] ALWAYS bounce on ", ground_shape_name, " at y=", global_position.y)

# Flip when hitting vertical surfaces
func _reverse_if_wall(delta: float) -> void:
	if flip_timer > 0.0:
		return

	if is_on_wall():
		var c := get_last_slide_collision()
		if c != null and absf(c.get_normal().x) > 0.4:
			_flip_horizontal("is_on_wall")
			global_position += c.get_normal() * (separation_push * delta)
			return

	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		if col == null:
			continue
		var n: Vector2 = col.get_normal()
		if absf(n.x) > 0.4:
			_flip_horizontal("normal=" + str(n))
			global_position += n * (separation_push * delta)
			return

func _flip_horizontal(reason: String) -> void:
	dir = -dir
	flip_timer = flip_cooldown
	if debug_prints:
		print("[Bouncer] flip -> dir=", dir, " (", reason, ")")

# Returns true if any slide collision this frame involves the node named `ground_shape_name`
# (either the collider itself has that name OR one of its children does).
func _touched_named_ground_this_frame() -> bool:
	for i in range(get_slide_collision_count()):
		var c := get_slide_collision(i)
		if c == null:
			continue
		var collider := c.get_collider()
		if collider == null:
			continue

		# 1) Collider itself is the named node
		if collider is Node and (collider as Node).name == ground_shape_name:
			return true

		# 2) Collider owns a child node with that exact name (typical StaticBody2D -> CollisionShape2D2)
		if collider is Node:
			var node := collider as Node
			for child in node.get_children():
				if child is Node and (child as Node).name == ground_shape_name:
					return true
	return false

# --- Combat API ---
# Player should call: body.take_damage(damage, $PunchHitbox.global_position)
func take_damage(damage_amount: int, from_point: Vector2 = Vector2.INF) -> void:
	health -= damage_amount
	print("Bouncer took ", damage_amount, " damage. Health: ", health)

	if from_point != Vector2.INF:
		var away: Vector2 = (global_position - from_point).normalized()
		if away == Vector2.ZERO:
			away = Vector2.RIGHT
		knockback_dir_x = signf(away.x)
		velocity.y = -knockback_upward
		knockback_timer = knockback_time
	else:
		_flip_horizontal("damage_no_from_point")

	if health <= 0:
		print("Bouncer defeated!")
		queue_free()
