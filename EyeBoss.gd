extends CharacterBody2D

# -------- Lanes --------
@export var top_y: float = 0.0
@export var mid_y: float = 0.0
@export var bottom_y: float = 0.0

# Movement
@export var move_speed: float = 180.0
@export var dwell_time: float = 0.8

# Laser
@export var laser_scene: PackedScene      # <-- assign LaserBeam.tscn on THIS Level2 instance
@export var shoot_interval: float = 1.75

# Health
@export var health: int = 200

# Internal lane state
var _lane_list: PackedFloat32Array = []
var _lane_index: int = 0
var _target_y: float = 0.0
var _moving: bool = false
var _dwell_left: float = 0.0

# Shoot timer created in code (no node required)
var _shoot_timer: Timer

func _ready() -> void:
	# Process even if the game is paused or this node would normally sleep
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_physics_process(true)
	set_process(true)

	# Float (no gravity)
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	velocity = Vector2.ZERO

	# Lanes (use your offsets, default from current Y)
	if mid_y == 0.0:
		mid_y = global_position.y
	if top_y == 0.0:
		top_y = mid_y - 50.0
	if bottom_y == 0.0:
		bottom_y = mid_y + 40.0
	_lane_list = [top_y, mid_y, bottom_y, mid_y]
	_lane_index = 0
	_target_y = _lane_list[_lane_index]
	_moving = true
	_dwell_left = 0.0

	# Shoot timer (robust)
	_shoot_timer = Timer.new()
	_shoot_timer.one_shot = false
	_shoot_timer.wait_time = shoot_interval
	_shoot_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_shoot_timer)
	_shoot_timer.timeout.connect(_on_shoot_timeout)
	_shoot_timer.start()

	if laser_scene == null:
		push_warning("[EyeBoss] laser_scene NOT SET on this Level2 instance.")
	print("[EyeBoss] Ready. shoot_interval = ", shoot_interval)

	# Guaranteed first shot after 0.25s (so you see it immediately)
	get_tree().create_timer(0.25).timeout.connect(func() -> void:
		print("[EyeBoss] DEBUG first-shot trigger")
		_fire_laser()
	)

func _physics_process(delta: float) -> void:
	# Lane movement (float between target Ys)
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

	velocity = Vector2.ZERO  # keep fully floating

# ----------------- Shooting -----------------
func _on_shoot_timeout() -> void:
	print("[EyeBoss] Shoot timer timeout -> firing")
	_fire_laser()

func _fire_laser() -> void:
	# 1) Try the assigned scene (with clear diagnostics)
	if laser_scene != null:
		print("[EyeBoss] laser_scene path: ", laser_scene.resource_path)
		var inst := laser_scene.instantiate()
		if inst == null:
			push_warning("[EyeBoss] instantiate() returned null. Using fallback beam.")
			_spawn_fallback_beam("instantiate null")
			return

		print("[EyeBoss] instantiated root class: ", inst.get_class())
		var area := inst as Area2D
		if area == null:
			push_warning("[EyeBoss] laser_scene root is NOT Area2D (it’s " + inst.get_class() + "). Using fallback beam.")
			_spawn_fallback_beam("root not Area2D")
			return

		# Place at boss Y; beam script will center X itself
		area.global_position = Vector2(0.0, global_position.y)
		if area.has_method("set"):
			area.set("owner_boss", self)

		var parent := get_tree().current_scene
		if parent == null:
			parent = get_tree().root
		parent.add_child(area)

		print("[EyeBoss] LaserBeam spawned OK @ y=", area.global_position.y)
		return

	# 2) Nothing assigned: fallback
	push_warning("[EyeBoss] laser_scene is NULL on this EyeBoss instance. Using fallback beam.")
	_spawn_fallback_beam("laser_scene null")

# --- Fallback laser: Area2D + CollisionShape2D + Polygon2D (always visible & damaging) ---
func _spawn_fallback_beam(reason: String) -> void:
	var beam := Area2D.new()
	beam.name = "LaserBeam_Fallback"
	beam.collision_layer = 1 << 2   # EnemyAttack = 2
	beam.collision_mask  = 1 << 1   # Player = 1
	beam.z_index = 1000
	beam.global_position = Vector2(0.0, global_position.y)

	# Collision
	var cs := CollisionShape2D.new()
	beam.add_child(cs)

	# Visual polygon (follows Node2D transforms)
	var poly := Polygon2D.new()
	beam.add_child(poly)

	# Determine width from walls if available, else viewport width
	var w := 0.0
	var root := get_tree().current_scene
	if root != null:
		var left := root.find_child("Left_Wall", true, false)
		var right := root.find_child("Right_Wall", true, false)
		if left is Node2D and right is Node2D:
			w = absf((right as Node2D).global_position.x - (left as Node2D).global_position.x)
	if w <= 0.0:
		var vr := get_viewport().get_visible_rect()
		w = vr.size.x

	var h := 42.0
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, h)
	cs.shape = rect
	cs.position = Vector2.ZERO

	# Centered rectangle (-w/2..+w/2, -h/2..+h/2)
	var hw := w * 0.5
	var hh := h * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw,  hh),  Vector2(-hw, hh)
	])
	poly.color = Color(1, 0.2, 0.2, 0.35)  # warn color (wind-up)

	# Damage window
	beam.monitoring = false
	if not beam.body_entered.is_connected(_on_fallback_beam_body_entered):
		beam.body_entered.connect(_on_fallback_beam_body_entered)

	# Add to scene
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	parent.add_child(beam)

	print("[EyeBoss] FALLBACK beam spawned (", reason, ") @ y=", beam.global_position.y, " width=", w)

	# Arm after short wind-up, then expire
	get_tree().create_timer(0.35).timeout.connect(func() -> void:
		beam.monitoring = true
		poly.color = Color(1, 0.05, 0.05, 0.9)  # active color
		print("[EyeBoss] FALLBACK beam ACTIVE")
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			print("[EyeBoss] FALLBACK beam EXPIRE")
			beam.queue_free()
		)
	)

func _on_fallback_beam_body_entered(body: Node) -> void:
	if body != null and body.is_in_group("Player") and body.has_method("take_damage"):
		body.call("take_damage", 10, global_position)
		print("[EyeBoss] FALLBACK beam damaged Player (10)")

# ----------------- Damage handling -----------------
func take_damage(amount: int, from_point: Vector2 = Vector2.INF) -> void:
	health -= amount
	print("Boss took ", amount, " damage. Health is now: ", health)
	if health <= 0:
		print("Boss defeated!")
		queue_free()
