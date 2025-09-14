extends CharacterBody2D

# -------- Lanes (Y positions) --------
@export var top_y: float = 0.0
@export var mid_y: float = 0.0
@export var bottom_y: float = 0.0

# Movement
@export var move_speed: float = 180.0     # pixels/sec vertically between lanes
@export var dwell_time: float = 0.8       # pause at each lane

# Laser
@export var laser_scene: PackedScene       # assign LaserBeam.tscn in Inspector
@export var shoot_interval: float = 1.75   # seconds

# Health
@export var health: int = 200

@onready var move_timer: Timer = $MoveTimer
@onready var shoot_timer: Timer = $ShootTimer

var _lane_list: PackedFloat32Array = []
var _lane_index: int = 0
var _target_y: float = 0.0
var _moving: bool = false

func _ready() -> void:
	# Make sure this body behaves like a flier (no floor logic / gravity).
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	# Also ensure we never carry velocity from anywhere.
	velocity = Vector2.ZERO

	# Initialize lanes if not set
	if mid_y == 0.0:
		mid_y = global_position.y
	if top_y == 0.0:
		top_y = mid_y - 50.0
	if bottom_y == 0.0:
		bottom_y = mid_y + 50.0

	_lane_list = [top_y, mid_y, bottom_y, mid_y]
	_lane_index = 0
	_target_y = _lane_list[_lane_index]
	_moving = true

	# Timers
	if not move_timer.is_connected("timeout", Callable(self, "_on_move_timeout")):
		move_timer.connect("timeout", Callable(self, "_on_move_timeout"))
	move_timer.one_shot = true
	move_timer.stop()

	if not shoot_timer.is_connected("timeout", Callable(self, "_on_shoot_timeout")):
		shoot_timer.connect("timeout", Callable(self, "_on_shoot_timeout"))
	shoot_timer.wait_time = shoot_interval
	shoot_timer.autostart = true

func _physics_process(delta: float) -> void:
	# FLOATING MOVE: directly move y toward target; do not use gravity.
	if _moving:
		global_position.y = move_toward(global_position.y, _target_y, move_speed * delta)
		if absf(global_position.y - _target_y) <= 1.0:
			_moving = false
			move_timer.start(dwell_time)

	# Horizontal stays where you placed the boss
	velocity = Vector2.ZERO  # keep zero so gravity never creeps in anywhere

# ----- Timers -----
func _on_move_timeout() -> void:
	_lane_index = (_lane_index + 1) % _lane_list.size()
	_target_y = _lane_list[_lane_index]
	_moving = true

func _on_shoot_timeout() -> void:
	_fire_laser()
	# ShootTimer is repeating; no manual restart needed.

# ----- Laser spawn -----
func _fire_laser() -> void:
	if laser_scene == null:
		print("[EyeBoss] laser_scene not set.")
		return
	var beam := laser_scene.instantiate() as Area2D
	if beam == null:
		print("[EyeBoss] laser_scene must be an Area2D root.")
		return

	# Place the beam across the screen at the boss's current Y.
	beam.global_position = Vector2(0.0, global_position.y)
	beam.set("owner_boss", self)
	get_tree().root.add_child(beam)

# ----- Damage handling -----
func take_damage(amount: int, from_point: Vector2 = Vector2.INF) -> void:
	health -= amount
	print("Boss took ", amount, " damage. Health is now: ", health)
	if health <= 0:
		print("Boss defeated!")
		queue_free()
