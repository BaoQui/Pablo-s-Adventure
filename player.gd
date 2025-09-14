extends CharacterBody2D

# --- Movement settings ---
@export var base_move_speed: float = 300.0
@export var move_speed: float = 300.0
@export var acceleration: float = 2000.0
@export var deceleration: float = 4000.0
@export var jump_force: float = 450.0
@export var gravity: float = 1200.0
@export var fall_multiplier: float = 3.0
@export var coyote_time: float = 0.15
@export var jump_cut_multiplier: float = 0.5

# --- Dash settings ---
@export var dash_speed: float = 400.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5

# --- Punch settings ---
@export var base_punch_damage: int = 10
@export var punch_damage: int = 10
@export var base_punch_cooldown: float = 0.3
@export var punch_cooldown: float = 0.3
@export var punch_duration: float = 0.25
@export var air_punch_push: float = 50.0

# --- Projectile settings ---
@export var projectile_scene: PackedScene
@export var projectile_distance: float = 500.0
@export var projectile_speed: float = 600.0
@export var projectile_damage: int = 20
@export var base_projectile_cooldown: float = 0.5
@export var projectile_cooldown: float = 0.5

# --- Player stats ---
@export var base_health: float = 100.0
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var base_money_multiplier: float = 1.0
@export var money_multiplier: float = 1.0

# --- Node references ---
@onready var punch_hitbox: Area2D = $PunchHitbox
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var card_inventory: CardInventory = $CardInventory

# --- State variables ---
var punch_timer: float = 0.0
var projectile_timer: float = 0.0
var coyote_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var current_animation: String = "idle"
var is_dashing: bool = false
var is_punching: bool = false
var freeze_velocity: bool = false
var stored_velocity: Vector2 = Vector2.ZERO
var can_dash: bool = true

# --- Card effects ---
var duelist_hit_streak: int = 0
var duelist_speed_multiplier: float = 1.0

func _ready() -> void:
	# Ensure hitbox starts off
	punch_hitbox.monitoring = false
	
	# Connect signals safely
	if not punch_hitbox.body_entered.is_connected(_on_punch_hitbox_body_entered):
		punch_hitbox.body_entered.connect(_on_punch_hitbox_body_entered)
	if not anim.animation_finished.is_connected(_on_animation_finished):
		anim.animation_finished.connect(_on_animation_finished)
	
	# Connect card inventory signals
	if card_inventory and not card_inventory.hand_changed.is_connected(_on_hand_changed):
		card_inventory.hand_changed.connect(_on_hand_changed)
	
	current_animation = ""
	play_animation("idle")
	
	# Initialize card effects
	_update_card_effects()

func _physics_process(delta: float) -> void:
	# --- timers ---
	punch_timer -= delta
	projectile_timer -= delta
	dash_timer -= delta
	dash_cooldown_timer -= delta

	var input_dir: float = Input.get_axis("ui_left", "ui_right")

	# Freeze movement during air punch (except a tiny nudge)
	if freeze_velocity:
		if not is_on_floor():
			var push: float = ( -1.0 if anim.flip_h else 1.0 ) * air_punch_push
			velocity = Vector2(push, 0.0)
		else:
			velocity = Vector2.ZERO
	else:
		# --- Horizontal movement ---
		if is_dashing:
			if dash_timer <= 0.0:
				end_dash()
		elif input_dir != 0.0 and not is_punching:
			velocity.x = move_toward(velocity.x, input_dir * move_speed, acceleration * delta)
			anim.flip_h = input_dir < 0.0
		elif not is_punching:
			velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
			if absf(velocity.x) < 1.0:
				velocity.x = 0.0

		# --- Gravity ---
		if not is_on_floor():
			if velocity.y > 0.0:
				velocity.y += gravity * fall_multiplier * delta
			else:
				velocity.y += gravity * delta

	# --- Coyote time & dash reset ---
	if is_on_floor():
		coyote_timer = coyote_time
		can_dash = true
	else:
		coyote_timer -= delta

	# --- Jumping ---
	if Input.is_action_just_pressed("ui_accept") and (is_on_floor() or coyote_timer > 0.0) and not is_punching:
		velocity.y = -jump_force
		coyote_timer = 0.0

	# --- Variable jump height ---
	if Input.is_action_just_released("ui_accept") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

	# --- Punch ---
	if Input.is_action_just_pressed("ui_punch") and punch_timer <= 0.0 and not is_dashing:
		punch()
		punch_timer = punch_cooldown * duelist_speed_multiplier

	# --- Dash ---
	if Input.is_action_just_pressed("ui_dash") and can_dash and not is_dashing and not is_punching and dash_cooldown_timer <= 0.0:
		var dir = 1 if not anim.flip_h else -1
		start_dash(dir)
		can_dash = false

	# --- Shoot projectile ---
	if Input.is_action_just_pressed("ui_shoot") and projectile_timer <= 0:
		shoot_projectile()
		projectile_timer = projectile_cooldown

	# --- Open inventory (example with ESC key) ---
	if Input.is_action_just_pressed("ui_cancel"):
		open_inventory_menu()

	update_animation(input_dir)
	move_and_slide()

func _on_hand_changed():
	_update_card_effects()

func _update_card_effects():
	if not card_inventory:
		return
	
	# Reset to base values
	max_health = base_health
	punch_damage = base_punch_damage
	projectile_cooldown = base_projectile_cooldown
	move_speed = base_move_speed
	money_multiplier = base_money_multiplier
	
	# Apply card modifiers
	var health_bonus = card_inventory.get_hand_modifier(Card.CardType.HEART)
	var club_reduction = card_inventory.get_hand_modifier(Card.CardType.CLUB)
	var punch_bonus = card_inventory.get_hand_modifier(Card.CardType.SPADE)
	var money_bonus = card_inventory.get_hand_modifier(Card.CardType.DIAMOND)
	
	# Apply modifiers
	max_health += health_bonus
	punch_damage += int(punch_bonus)
	projectile_cooldown = max(0.1, projectile_cooldown - club_reduction)
	money_multiplier += money_bonus
	
	# Ensure current health doesn't exceed new max
	current_health = min(current_health, max_health)
	
	# Apply joker effects
	var joker_effects = card_inventory.get_hand_joker_effects()
	
	if "JESTER" in joker_effects:
		punch_damage += int(15 * joker_effects["JESTER"])
	
	if "BANKER" in joker_effects:
		money_multiplier *= pow(1.5, joker_effects["BANKER"])
	
	if "ATHLETE" in joker_effects:
		move_speed += 100 * joker_effects["ATHLETE"]
	
	# Duelist effect is handled in combat
	print("Updated stats - Health: ", max_health, " Punch: ", punch_damage, " Money: ", money_multiplier)

func take_damage(damage: int, hit_position: Vector2 = Vector2.ZERO):
	current_health -= damage
	duelist_hit_streak = 0  # Reset duelist streak when taking damage
	duelist_speed_multiplier = 1.0
	
	if current_health <= 0:
		die()

func die():
	print("Player died!")
	# Implement death logic here

func kill_enemy():
	# Called when player kills an enemy
	var joker_effects = card_inventory.get_hand_joker_effects()
	
	# Duelist effect - increase attack speed
	if "DUELIST" in joker_effects:
		duelist_hit_streak += 1
		duelist_speed_multiplier = max(0.3, 1.0 - (duelist_hit_streak * 0.05))
	
	# Chance to get a random card drop
	if randf() < 0.2:  # 20% chance
		var new_card = card_inventory.generate_random_drop()
		card_inventory.add_card_to_inventory(new_card)
		print("Card dropped: ", new_card.card_name)

func earn_money(base_amount: int) -> int:
	return int(base_amount * money_multiplier)

func open_inventory_menu():
	# This would open your inventory UI
	print("Opening inventory menu...")
	get_tree().paused = true
	# You would show your inventory UI scene here

# --- Animation ---
func update_animation(input_dir: float) -> void:
	if is_punching or is_dashing:
		return

	if not is_on_floor():
		if velocity.y < 0.0:
			play_animation("jump")
		else:
			play_animation("fall")
	elif input_dir != 0.0:
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

# When the punch hitbox touches ANY PhysicsBody2D (e.g. enemies)
func _on_punch_hitbox_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(punch_damage, $PunchHitbox.global_position)

		
		# Check if enemy died to trigger card drop
		if body.has_method("is_dead") and body.is_dead():
			kill_enemy()

# === DASH ===
func start_dash(input_dir: float) -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	velocity.x = input_dir * dash_speed
	play_animation("dash", 2.0)

func end_dash() -> void:
	is_dashing = false

# === PUNCH ===
func punch() -> void:
	if anim.flip_h:
		punch_hitbox.position.x = -absf(punch_hitbox.position.x)
	else:
		punch_hitbox.position.x = absf(punch_hitbox.position.x)
	
	is_punching = true
	punch_hitbox.monitoring = true

	if not is_on_floor():
		freeze_velocity = true
		stored_velocity = velocity
		velocity = Vector2.ZERO

	var frame_count: int = anim.sprite_frames.get_frame_count("punch")
	var punch_speed: float = (frame_count as float) / punch_duration
	play_animation("punch", punch_speed)

	var hitbox_timer: SceneTreeTimer = get_tree().create_timer(0.1)
	hitbox_timer.timeout.connect(func() -> void:
		punch_hitbox.monitoring = false
	)

	var punch_reset_timer: SceneTreeTimer = get_tree().create_timer(punch_duration * 0.95)
	punch_reset_timer.timeout.connect(func() -> void:
		is_punching = false
		if freeze_velocity:
			freeze_velocity = false
	)

# --- Projectile ---
func shoot_projectile() -> void:
	if projectile_scene == null:
		print("No projectile scene assigned!")
		return

	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)

	var spawn_offset = Vector2(30, 0)
	if anim.flip_h:
		spawn_offset.x *= -1

	projectile.global_position = global_position + spawn_offset
	projectile.direction = Vector2.RIGHT if not anim.flip_h else Vector2.LEFT
	projectile.max_distance = projectile_distance
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
