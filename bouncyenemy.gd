extends CharacterBody2D

# --- Horizontal motion ---
@export var move_speed: float = 100.0
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
@export var health: int = 30
@export var knockback_duration: float = 0.15   # matches groundenemy.gd
@export var knockback_strength_x: float = 400.0
@export var knockback_strength_y: float = 300.0

# --- Ground identification (hard requirement) ---
@export var ground_shape_name: String = "CollisionShape2D2"

# --- Debug ---
@export var debug_prints: bool = false

var dir: int = 1
var flip_timer: float = 0.0
var knockback_timer: float = 0.0

func _ready() -> void:
	dir = 1 if start_direction_right else -1
	add_to_group("Enemy")  # make sure the player can hit this enemy

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

	# Horizontal velocity
	if knockback_timer <= 0.0:
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
func _touched_named_ground_this_frame() -> bool:
	for i in range(get_slide_collision_count()):
		var c := get_slide_collision(i)
		if c == null:
			continue
		var collider := c.get_collider()
		if collider == null:
			continue

		if collider is Node and (collider as Node).name == ground_shape_name:
			return true

		if collider is Node:
			var node := collider as Node
			for child in node.get_children():
				if child is Node and (child as Node).name == ground_shape_name:
					return true
	return false

# --- Combat API ---
func take_damage(damage_amount: int, from_point: Vector2 = Vector2.INF) -> void:
	health -= damage_amount
	print(name, " took ", damage_amount, " damage. Health is now: ", health)

	if from_point != Vector2.INF:
		# Knockback strengths (tweak as needed)
		var knockback_strength_x: float = 400.0
		var knockback_strength_y: float = 300.0

		# If attacker is to the left of enemy → knock enemy right
		if from_point.x > global_position.x:
			velocity.x = knockback_strength_x
		else:
			# Attacker is to the right of enemy → knock enemy left
			velocity.x = -knockback_strength_x

		# Always knock upwards
		velocity.y = -knockback_strength_y

		knockback_timer = knockback_duration

	if health <= 0:
		die()
		

func die():
	print("Bouncer defeated!")
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.kill_count += 1
	queue_free()

# --- Hurt player on collision ---
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.do_damage(10, global_position)

		var knockback_strength_x: float = 600.0
		var knockback_strength_y: float = 300.0

		if body.global_position.x > global_position.x:
			body.velocity.x = -knockback_strength_x
		else:
			body.velocity.x = knockback_strength_x

		body.velocity.y = -knockback_strength_y

		if "knockback_timer" in body:
			body.knockback_timer = 0.3
