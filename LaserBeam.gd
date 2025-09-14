extends Area2D
class_name LaserBeam

# Physics-only laser: damages on actual overlap of CollisionShape2D
@export var damage: int = 25
@export var windup_time: float = 0.25
@export var active_time: float = 1.0

# Beam dimensions
@export var full_width: bool = false
@export var beam_width: float = 140.0
@export var beam_height: float = 42.0

# Who fired this beam (set by EyeBoss)
@export var owner_boss: Node2D

# Collision layers (EnemyAttack=3, Player=2)
const LAYER_ENEMY_ATTACK := 1 << 2
const MASK_PLAYER := 1 << 1

var _shape: CollisionShape2D
var _active: bool = false
var _did_damage: bool = false

func _ready() -> void:
	# Ensure proper layer/mask for physics overlap with the Player
	collision_layer = LAYER_ENEMY_ATTACK
	collision_mask  = MASK_PLAYER
	monitoring = false  # off during wind-up

	# Ensure there's a CollisionShape2D and size it
	_shape = _get_or_make_shape()
	_size_shape()

	# Connect overlap signal once
	if not body_entered.is_connected(_on_area_2d_body_entered):
		body_entered.connect(_on_area_2d_body_entered)

	# Arm after windup; then deactivate after active_time
	await get_tree().create_timer(windup_time).timeout
	_active = true
	set_deferred("monitoring", true)

	await get_tree().create_timer(active_time).timeout
	_active = false
	set_deferred("monitoring", false)
	queue_free()

func _physics_process(_delta: float) -> void:
	# *** Follow boss X exactly ***
	if is_instance_valid(owner_boss):
		global_position.x = owner_boss.global_position.x
		# If you also want to lock Y, uncomment:
		# global_position.y = owner_boss.global_position.y

func _get_or_make_shape() -> CollisionShape2D:
	for c in get_children():
		if c is CollisionShape2D:
			return c
	var cs := CollisionShape2D.new()
	add_child(cs)
	return cs

func _size_shape() -> void:
	var width := beam_width
	if full_width:
		width = get_viewport().get_visible_rect().size.x
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, beam_height)
	_shape.shape = rect
	_shape.position = Vector2.ZERO

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not _active or _did_damage:
		return
	# Apply damage during active window
	if body.is_in_group("Player") and body.has_method("do_damage"):
		body.do_damage(damage, global_position)
		_did_damage = true   # remove this line if you want repeated ticks
