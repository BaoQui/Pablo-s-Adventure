extends Area2D

@export var damage: int = 10
@export var windup_time: float = 0.35
@export var active_time: float = 1.0
@export var beam_height: float = 42.0
@export var color_warn: Color = Color(1, 0.2, 0.2, 0.35)
@export var color_active: Color = Color(1, 0.05, 0.05, 0.9)

const LAYER_ENEMY_ATTACK := 1 << 2   # layer 2
const MASK_PLAYER := 1 << 1          # mask 1

var owner_boss: Node = null
var shape_node: CollisionShape2D
var poly: Polygon2D

func _ready() -> void:
	collision_layer = LAYER_ENEMY_ATTACK
	collision_mask  = MASK_PLAYER
	z_index = 1000

	# ensure children
	shape_node = _ensure_shape()
	poly = _ensure_poly()

	# width from walls or viewport
	var w := _beam_width()
	var hw := w * 0.5
	var hh := beam_height * 0.5

	# visual rect centered at (0,0)
	poly.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw,  hh),  Vector2(-hw, hh)
	])
	poly.color = color_warn

	# collision rect
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, beam_height)
	shape_node.shape = rect
	shape_node.position = Vector2.ZERO

	# center horizontally; EyeBoss sets our Y before add_child
	var vr := get_viewport().get_visible_rect()
	global_position.x = vr.position.x + vr.size.x * 0.5

	# arm after windup, then expire
	monitoring = false
	get_tree().create_timer(windup_time).timeout.connect(func():
		monitoring = true
		poly.color = color_active
		get_tree().create_timer(active_time).timeout.connect(func():
			queue_free()
		)
	)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _ensure_shape() -> CollisionShape2D:
	for c in get_children():
		if c is CollisionShape2D:
			return c
	var cs := CollisionShape2D.new()
	add_child(cs)
	return cs

func _ensure_poly() -> Polygon2D:
	for c in get_children():
		if c is Polygon2D:
			return c
	var p := Polygon2D.new()
	add_child(p)
	return p

func _beam_width() -> float:
	var root := get_tree().current_scene
	if root != null:
		var left := root.find_child("Left_Wall", true, false)
		var right := root.find_child("Right_Wall", true, false)
		if left is Node2D and right is Node2D:
			return absf((right as Node2D).global_position.x - (left as Node2D).global_position.x)
	var vr := get_viewport().get_visible_rect()
	return vr.size.x

func _on_body_entered(body: Node) -> void:
	if body != null and body.is_in_group("Player") and body.has_method("take_damage"):
		body.call("take_damage", damage, global_position)
