extends CharacterBody2D

# ---------- Lanes (Y positions) ----------
@export var top_y: float = 0.0
@export var mid_y: float = 0.0
@export var bottom_y: float = 0.0

# Movement between lanes
@export var move_speed: float = 180.0   # pixels/sec vertically
@export var dwell_time: float = 4.0     # pause 4s at each lane before moving

# Laser
@export var laser_scene: PackedScene     # assign LaserBeam.tscn in the boss instance
@export var shoot_interval: float = 2.0  # seconds between shots

# Health
@export var health: int = 200

# --- Internal state ---
var _lane_list: PackedFloat32Array = []
var _lane_index: int = 0
var _target_y: float = 0.0
var _moving: bool = false
var _dwell_left: float = 0.0
var _shoot_timer: Timer

func _ready() -> void:
	# Always process and float (no gravity)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_physics_process(true)
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	velocity = Vector2.ZERO

	# Initialize lanes (use current Y as mid if not set; small offsets)
	if mid_y == 0.0:
		mid_y = global_position.y
	if top_y == 0.0:
		top_y = mid_y - 50.0
	if bottom_y == 0.0:
		bottom_y = mid_y + 40.0

	_lane_list = PackedFloat32Array([top_y, mid_y, bottom_y, mid_y])
	_lane_index = 0
	_target_y = _lane_list[_lane_index]
	_moving = true
	_dwell_left = 0.0

	# Shoot timer (created in code)
	_shoot_timer = Timer.new()
	_shoot_timer.one_shot = false
	_shoot_timer.wait_time = shoot_interval
	_shoot_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_shoot_timer)
	_shoot_timer.timeout.connect(Callable(self, "_on_shoot_timeout"))
	_shoot_timer.start()

	if laser_scene == null:
		push_warning("[EyeBoss] laser_scene is NOT assigned on this boss instance.")
	print("[EyeBoss] Ready. shoot_interval = ", shoot_interval, " dwell_time = ", dwell_time)

func _physics_process(delta: float) -> void:
	# Float toward target lane
	if _moving:
		global_position.y = move_toward(global_position.y, _target_y, move_speed * delta)
		if absf(global_position.y - _target_y) <= 1.0:
			_moving = false
			_dwell_left = dwell_time
	else:
		_dwell_left -= delta
		if _dwell_left <= 0.0:
			_lane_index = (_lane_index + 1) % _lane_list.size()
			_target_y = _lane_list[_lane_index]
			_moving = true

	# No gravity / floor logic
	velocity = Vector2.ZERO

# -------- Shooting --------
func _on_shoot_timeout() -> void:
	_shoot_laser()

func _shoot_laser() -> void:
	if laser_scene == null:
		print("[EyeBoss] No laser_scene assigned; cannot shoot.")
		return

	var beam := laser_scene.instantiate()
	if not (beam is Node2D):
		push_error("[EyeBoss] laser_scene root must be Node2D/Area2D.")
		return

	# Place beam at boss X/Y initially
	(beam as Node2D).global_position = Vector2(global_position.x, global_position.y)

	# Add to current scene (fallback to root)
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	parent.add_child(beam)

	# Pass boss reference
	if beam is Area2D:
		(beam as Area2D).owner_boss = self

	print("[EyeBoss] Laser fired @ ", (beam as Node2D).global_position)


	print("[EyeBoss] Laser fired @ ", (beam as Node2D).global_position)

# -------- Damage --------
func take_damage(amount: int, from_point: Vector2 = Vector2.INF) -> void:
	health -= amount
	print("Boss took ", amount, " damage. Health is now: ", health)
	if health <= 0:
		print("Boss defeated!")
		queue_free()
		get_tree().change_scene_to_file("res://end_screen.tscn")
