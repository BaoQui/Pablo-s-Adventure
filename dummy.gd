extends CharacterBody2D

# --- Tunables ---
@export var move_speed: float = 120.0
@export var pattern_duration: float = 2.5
@export var drift_range: float = 80.0
@export var sine_amplitude: float = 40.0
@export var sine_freq: float = 3.0
@export var health: int = 50  # <-- added

# Pattern names
enum Pattern { HOVER, STRAFE, SINE }

# Weighted chances (higher = more likely)
@export var pattern_weights: PackedFloat32Array = [3.0, 2.0, 2.0]  # HOVER more common

@onready var pattern_timer: Timer = $PatternTimer

var current_pattern: int = Pattern.HOVER
var rng := RandomNumberGenerator.new()

# Per-pattern state
var base_pos: Vector2
var hover_target: Vector2
var strafe_dir: float = 1.0
var sine_t: float = 0.0

# --- DAMAGE PRINTS TO CONSOLE ---
func take_damage(damage_amount: int) -> void:
	health -= damage_amount
	print("Enemy took ", damage_amount, " damage. Health is now: ", health)
	if health <= 0:
		print("Enemy defeated!")
		queue_free()

func _ready() -> void:
	rng.randomize()
	if not pattern_timer.is_connected("timeout", Callable(self, "_on_pattern_timeout")):
		pattern_timer.connect("timeout", Callable(self, "_on_pattern_timeout"))
	pattern_timer.wait_time = pattern_duration
	pattern_timer.start()
	_pick_new_pattern()

func _physics_process(delta: float) -> void:
	match current_pattern:
		Pattern.HOVER:
			_do_hover(delta)
		Pattern.STRAFE:
			_do_strafe(delta)
		Pattern.SINE:
			_do_sine(delta)
	move_and_slide()

func _on_pattern_timeout() -> void:
	_pick_new_pattern()

func _pick_new_pattern() -> void:
	current_pattern = _weighted_choice(pattern_weights)
	base_pos = global_position
	sine_t = 0.0
	match current_pattern:
		Pattern.HOVER:
			hover_target = base_pos + Vector2(
				rng.randf_range(-drift_range, drift_range),
				rng.randf_range(-drift_range, drift_range)
			)
		Pattern.STRAFE:
			if rng.randi_range(0, 1) == 1:
				strafe_dir *= -1.0
		Pattern.SINE:
			pass
	pattern_timer.wait_time = pattern_duration
	pattern_timer.start()

func _weighted_choice(weights: PackedFloat32Array) -> int:
	var total := 0.0
	for w in weights: total += max(w, 0.0)
	if total <= 0.0: return 0
	var pick := rng.randf() * total
	var run := 0.0
	for i in weights.size():
		run += max(weights[i], 0.0)
		if pick <= run:
			return i
	return 0

# --- Movement patterns ---
func _do_hover(delta: float) -> void:
	if global_position.distance_to(hover_target) < 8.0:
		hover_target = base_pos + Vector2(
			rng.randf_range(-drift_range, drift_range),
			rng.randf_range(-drift_range, drift_range)
		)
	var desired := (hover_target - global_position).limit_length(move_speed)
	velocity = velocity.lerp(desired, 6.0 * delta)

func _do_strafe(delta: float) -> void:
	var desired := Vector2(strafe_dir * move_speed, 0.0)
	velocity = velocity.lerp(desired, 8.0 * delta)
	if abs(global_position.x - base_pos.x) > drift_range:
		strafe_dir *= -1.0

func _do_sine(delta: float) -> void:
	sine_t += delta
	var vx := move_speed * 0.7
	var vy := sin(sine_t * TAU * sine_freq) * sine_amplitude
	var desired := Vector2(vx, vy)
	velocity = velocity.lerp(desired, 8.0 * delta)
