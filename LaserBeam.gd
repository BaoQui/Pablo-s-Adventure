extends Area2D

@export var damage: int = 10
@export var windup_time: float = 0.6
@export var active_time: float = 1.2
@export var beam_height: float = 40.0

var owner_boss: Node = null
@onready var shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	var view_rect := get_viewport().get_visible_rect()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(view_rect.size.x, beam_height)
	shape.shape = rect
	global_position.x = view_rect.position.x + view_rect.size.x * 0.5
	monitoring = false
	_set_damage_enabled_later()

func _set_damage_enabled_later() -> void:
	var t1 := get_tree().create_timer(windup_time)
	t1.timeout.connect(func():
		monitoring = true
		var t2 := get_tree().create_timer(active_time)
		t2.timeout.connect(func():
			queue_free()
		)
	)

func _on_body_entered(body: Node) -> void:
	if body != null and body.is_in_group("Player"):
		if body.has_method("take_damage"):
			body.call("take_damage", damage, global_position)

func _enter_tree() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
