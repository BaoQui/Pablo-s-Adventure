extends CharacterBody2D

# -----------------------------
#   Movement Settings
# -----------------------------
@export var move_speed: float        = 300.0    # Max horizontal speed
@export var acceleration: float      = 2000.0   # Acceleration rate
@export var deceleration: float      = 4000.0   # Deceleration rate (tight stop)
@export var jump_force: float        = 450.0    # Jump strength
@export var gravity: float           = 1200.0   # Base gravity force
@export var fall_multiplier: float   = 3.0      # Extra gravity when falling
@export var coyote_time: float       = 0.15     # Buffer after leaving ground
@export var jump_cut_multiplier: float = 0.5    # Short hop if jump released early

# -----------------------------
#   Internal State
# -----------------------------
var coyote_timer: float = 0.0


func _physics_process(delta: float) -> void:
	# -------------------------
	#   Horizontal Movement
	# -------------------------
	var input_dir := Input.get_axis("ui_left", "ui_right")

	if input_dir != 0:
		velocity.x = move_toward(
			velocity.x,
			input_dir * move_speed,
			acceleration * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0,
			deceleration * delta
		)
		if abs(velocity.x) < 1:
			velocity.x = 0  # Snap to zero to prevent sliding

	# -------------------------
	#   Coyote Time
	# -------------------------
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	# -------------------------
	#   Jumping
	# -------------------------
	if Input.is_action_just_pressed("ui_accept") and (is_on_floor() or coyote_timer > 0):
		velocity.y = -jump_force
		coyote_timer = 0  # Consume coyote time

	# -------------------------
	#   Variable Jump Height
	# -------------------------
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= jump_cut_multiplier

	# -------------------------
	#   Gravity + Fall Multiplier
	# -------------------------
	if velocity.y > 0:
		velocity.y += gravity * fall_multiplier * delta
	else:
		velocity.y += gravity * delta

	# -------------------------
	#   Apply Movement
	# -------------------------
	move_and_slide()
