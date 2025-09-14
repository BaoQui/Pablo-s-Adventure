extends CharacterBody2D

# --- Movement settings ---
@export var move_speed: float = 300.0
@export var acceleration: float = 2000.0
@export var deceleration: float = 4000.0
@export var jump_force: float = 450.0
@export var gravity: float = 1200.0
@export var fall_multiplier: float = 3.0
@export var coyote_time: float = 0.15
@export var jump_cut_multiplier: float = 0.5

# --- Dash settings ---
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
# (Removed cooldown entirely)

# --- Punch settings ---
@export var punch_damage: int = 10
@export var punch_cooldown: float = 0.3
@export var punch_duration: float = 0.25
@export var air_punch_push: float = 50.0

# --- Projectile settings ---
@export var projectile_scene: PackedScene
@export var projectile_distance: float = 500.0
@export var projectile_speed: float = 600.0
@export var projectile_damage: int = 20
@export var projectile_cooldown: float = 0.5

# --- Node references ---
@onready var punch_hitbox = $PunchHitbox
@onready var anim = $AnimatedSprite2D

# --- State variables ---
var punch_timer: float = 0.0
var projectile_timer: float = 0.0
var coyote_timer: float = 0.0
var dash_timer: float = 0.0
# var dash_cooldown_timer: float = 0.0   # REMOVED
var current_animation: String = "idle"
var is_dashing: bool = false
var is_punching: bool = false
var freeze_velocity: bool = false
var stored_velocity: Vector2 = Vector2.ZERO

# --- Dash availability (resets on ground) ---
var can_dash: bool = true

func _ready() -> void:
	punch_hitbox.monitoring = false
	if not punch_hitbox.body_entered.is_connected(_on_punch_hitbox_body_entered):
		punch_hitbox.body_entered.connect(_on_punch_hitbox_body_entered)
	if not anim.animation_finished.is_connected(_on_animation_finished):
		anim.animation_finished.connect(_on_animation_finished)
	current_animation = ""
	play_animation("idle")

func _physics_process(delta: float) -> void:
	punch_timer -= delta
	projectile_timer -= delta
	dash_timer -= delta
	# dash_cooldown_timer -= delta   # REMOVED
	
	var input_dir := Input.get_axis("ui_left", "ui_right")

	if freeze_velocity:
		if not is_on_floor():
			var push = (-1 if anim.flip_h else 1) * air_punch_push
			velocity = Vector2(push, 0)
		else:
			velocity = Vector2.ZERO
	else:
		# --- Horizontal movement ---
		if is_dashing:
			if dash_timer <= 0:
				end_dash()
		elif input_dir != 0 and not is_punching:
			velocity.x = move_toward(velocity.x, input_dir * move_speed, acceleration * delta)
			anim.flip_h = input_dir < 0
		elif not is_punching:
			velocity.x = move_toward(velocity.x, 0, deceleration * delta)
			if abs(velocity.x) < 1:
				velocity.x = 0

		# --- Gravity ---
		if not is_on_floor():
			if velocity.y > 0:
				velocity.y += gravity * fall_multiplier * delta
			else:
				velocity.y += gravity * delta

	# --- Coyote time & dash reset on ground ---
	if is_on_floor():
		coyote_timer = coyote_time
		can_dash = true     # reset dash when grounded
	else:
		coyote_timer -= delta

	# --- Jumping ---
	if Input.is_action_just_pressed("ui_accept") and (is_on_floor() or coyote_timer > 0) and not is_punching:
		velocity.y = -jump_force
		coyote_timer = 0

	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= jump_cut_multiplier

	# --- Punch ---
	if Input.is_action_just_pressed("ui_punch") and punch_timer <= 0 and not is_dashing:
		punch()
		punch_timer = punch_cooldown

<<<<<<< HEAD
	# --- Shoot projectile (with cooldown) ---
	if Input.is_action_just_pressed("ui_shoot") and projectile_timer <= 0:
		shoot_projectile()
		projectile_timer = projectile_cooldown
=======
	# --- Dash (Shift key, once per airtime) ---
	# Make sure you created InputMap action "ui_dash" bound to Shift.
	if Input.is_action_just_pressed("ui_dash") and can_dash and not is_dashing and not is_punching:
		var dir = 1 if not anim.flip_h else -1
		start_dash(dir)
		can_dash = false  # consume dash until you land again
>>>>>>> a97e9ce9a54f6ab087a261c58049cd1822cca11f

	update_animation(input_dir)
	move_and_slide()

# --- Animation ---
func update_animation(input_dir: float) -> void:
	if is_punching or is_dashing:
		return
	if not is_on_floor():
		if velocity.y < 0:
			play_animation("jump")
		else:
			play_animation("fall")
	elif input_dir != 0:
		play_animation("run")
	else:
		play_animation("idle")

func play_animation(anim_name: String, speed: float = 1.0) -> void:
	if current_animation != anim_name:
		current_animation = anim_name
		anim.speed_scale = speed
		anim.play(anim_name)

func _on_animation_finished() -> void:
	if current_animation == "punch":
		is_punching = false
		if freeze_velocity:
			freeze_velocity = false
	elif current_animation == "dash":
		is_dashing = false

func _on_punch_hitbox_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(punch_damage)

<<<<<<< HEAD
# --- Dash ---
=======
>>>>>>> a97e9ce9a54f6ab087a261c58049cd1822cca11f
func start_dash(input_dir: float) -> void:
	if input_dir == 0:
		input_dir = 1 if not anim.flip_h else -1
	is_dashing = true
	dash_timer = dash_duration
	velocity.x = input_dir * dash_speed
	# optional: flatten vertical velocity for a cleaner burst
	# velocity.y = 0
	play_animation("dash", 2.0)

func end_dash() -> void:
	is_dashing = false

# --- Punch ---
func punch() -> void:
	punch_hitbox.position.x = abs(punch_hitbox.position.x) * (-1 if anim.flip_h else 1)
	is_punching = true
	punch_hitbox.monitoring = true

	if not is_on_floor():
		freeze_velocity = true
		stored_velocity = velocity
		velocity = Vector2.ZERO

	var frame_count = anim.sprite_frames.get_frame_count("punch")
	var punch_speed = frame_count / punch_duration
	play_animation("punch", punch_speed)

	var hitbox_timer = get_tree().create_timer(0.1)
	hitbox_timer.timeout.connect(func() -> void:
		punch_hitbox.monitoring = false
	)

	var punch_reset_timer = get_tree().create_timer(punch_duration * 0.95)
	punch_reset_timer.timeout.connect(func() -> void:
		is_punching = false
		if freeze_velocity:
			freeze_velocity = false
<<<<<<< HEAD
	)

# --- Projectile ---
func shoot_projectile() -> void:
	if projectile_scene == null:
		print("No projectile scene assigned!")
		return

	var projectile = projectile_scene.instantiate()
	
	# Add projectile to the scene tree (same parent as player)
	get_parent().add_child(projectile)

	# Calculate spawn position (slightly in front of player)
	var spawn_offset = Vector2(30, 0)  # 30 pixels in front
	if anim.flip_h:
		spawn_offset.x *= -1
	
	projectile.global_position = global_position + spawn_offset

	# Set projectile properties
	projectile.direction = Vector2.RIGHT if not anim.flip_h else Vector2.LEFT
	projectile.max_distance = projectile_distance
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage

	# Debug confirmation
	print("Projectile fired! Position: ", projectile.global_position, " Direction: ", projectile.direction)
=======
)
>>>>>>> a97e9ce9a54f6ab087a261c58049cd1822cca11f
