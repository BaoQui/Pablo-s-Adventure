extends Area2D
# Physics-only laser: damages on actual overlap of CollisionShape2D

@export var damage: int = 10
@export var windup_time: float = 0.25   # time before it becomes dangerous
@export var active_time: float = 1.0    # time it can hurt

# Beam dimensions
@export var full_width: bool = false     # true = spans whole screen horizontally
@export var beam_width: float = 140.0    # used when full_width = false
@export var beam_height: float = 42.0

# Boss to follow (so Y matches exactly)
@export var owner_boss: Node2D

# Collision layers (EnemyAttack=2, Player=1) — adjust to your project
const LAYER_ENEMY_ATTACK := 1 << 2
const MASK_PLAYER := 1 << 1

var _shape: CollisionShape2D
var _active: bool = false
var _did_damage: bool = false  # set true to damage only once per beam

func _ready() -> void:
	# Ensure proper layer/mask for physics overlap with the Player
	collision_layer = LAYER_ENEMY_ATTACK
	collision_mask  = MASK_PLAYER
	monitoring = false  # off during wind-up

	# Ensure there's a CollisionShape2D and size it
	_shape = _get_or_make_shape()
	_size_shape()

	# Connect overlap signal (physics decides if we hit)
	var cb := Callable(self, "_on_body_entered")
	if not body_entered.is_connected(cb):
		body_entered.connect(cb)

	# Arm after windup; then deactivate after active_time
	var t1 := get_tree().create_timer(windup_time)
	t1.timeout.connect(func():
		_active = true
		# Use deferred to avoid toggling monitoring mid-physics step
		set_deferred("monitoring", true)

		var t2 := get_tree().create_timer(active_time)
		t2.timeout.connect(func():
			_active = false
			set_deferred("monitoring", false)
			queue_free()
		)
	)

func _process(_delta: float) -> void:
	# Keep laser Y exactly equal to boss Y every frame (if we have a boss)
	if owner_boss:
		global_position.y = owner_boss.global_position.y
		# If you want the beam to also lock X to the boss, uncomment:
		# global_position.x = owner_boss.global_position.x

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
		var vr := get_viewport().get_visible_rect()
		width = vr.size.x
	# Rectangle centered on the Area2D origin
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, beam_height)
	_shape.shape = rect
	_shape.position = Vector2.ZERO

func _on_body_entered(body: Node) -> void:
	# Physics says we overlapped; only apply during active window
	if not _active or _did_damage:
		return
	# Be strict: require Player group and take_damage method
	if body.is_in_group("Player") and body.has_method("take_damage"):
		body.call("take_damage", damage, global_position)
		_did_damage = true   # comment this out if you want damage on every overlap
