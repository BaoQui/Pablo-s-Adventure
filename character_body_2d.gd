extends CharacterBody2D

# --- Basic settings ---
@export var move_speed: float = 140.0
@export var acceleration: float = 1200.0
@export var deceleration: float = 2200.0
@export var gravity: float = 0.0          # set >0 if you want them to fall
@export var max_fall_speed: float = 1200.0
@export var pattern_duration: float = 2.5
@export var health: int = 50

# --- Patterns ---
enum Pattern { HOVER, STRAFE, SINE, BURST }
@export var pattern_weights: PackedFloat32Array = [3.0, 2.0, 2.0, 1.0]

# --- Pattern params ---
@export var wander_range: float = 96.0
@export var sine_amplitude: float = 40.0
@export var sine_freq: float = 3.0
@export var burst_speed: float = 300.0

@onready var pattern_timer: Timer = $PatternTimer

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var current_pattern: int = Pattern.HOVER
var base_pos: Vector2
var target_pos: Vector2
var strafe_dir: int = 1
var sine_t: float = 0.0

func _ready() -> void:
	rng.randomize()
	if not pattern_timer.is_connected("timeout", Callable(self, "_on_pattern_timeout")):
		pattern_timer.connect("timeout", Callable(self, "_on_pattern_timeout"))
	pattern_timer.wait_time = pattern_duration
	pattern_timer.start()
	_pick_new_pattern()

func _physics_process(delta: float) -> void:
	# Apply gravity if desired
	if gravity > 0.0 and not is_on_floor():
		velocity.y = min(velocity.y + gravity * delta, max_fall_speed)
	else:
		if gravity > 0.0:
			velocity.y = 0.0

	# Movement pattern
	var desired_v := _pattern_velocity(delta)

	# Smooth acceleration
	velocity.x = move_toward(velocity.x, desired_v.x, acceleration * delta)
	velocity.y = move_toward(velocity.y, desired_v.y, acceleration * delta)

	move_and_slide()

func _on_pattern_timeout() -> void:
	_pick_new_pattern()

func _pick_new_pattern() -> void:
	current_pattern = _weighted_choice(pattern_weights)
	base_pos = global_position
	sine_t = 0.0

	match current_pattern:
		Pattern.HOVER:
			target_pos = base_pos + Vector2(
				rng.randf_range(-wander_range, wander_range),
				rng.randf_range(-wander_range, wander_range)
			)
		Pattern.STRAFE:
			strafe_dir = 1 if rng.randi_range(0, 1) == 1 else -1
		Pattern.SINE:
			pass
		Pattern.BURST:
			pass

	pattern_timer.start()

func _pattern_velocity(delta: float) -> Vector2:
	match current_pattern:
		Pattern.HOVER:
			if global_position.distance_to(target_pos) < 8.0:
				target_pos = base_pos + Vector2(
					rng.randf_range(-wander_range, wander_range),
					rng.randf_range(-wander_range, wander_range)
				)
			return (target_pos - global_position).normalized() * move_speed

		Pattern.STRAFE:
			return Vector2(strafe_dir * move_speed, 0.0)

		Pattern.SINE:
			sine_t += delta
			var vx: float = move_speed * 0.7
			var vy: float = sin(sine_t * TAU * sine_freq) * sine_amplitude
			return Vector2(vx, vy)

		Pattern.BURST:
			return Vector2(move_speed * 2.0, 0.0)

	return Vector2.ZERO

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

# --- Damage logging ---
func take_damage(damage_amount: int) -> void:
	health -= damage_amount
	print("Enemy took ", damage_amount, " damage. Health is now: ", health)
	if health <= 0:
		print("Enemy defeated!")
		queue_free()
