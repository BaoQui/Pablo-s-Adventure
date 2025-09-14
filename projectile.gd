extends Area2D

# --- Projectile settings ---
@export var speed: float = 600.0
@export var max_distance: float = 500.0
@export var damage: int = 20
@export var rotate_to_direction: bool = true

# --- Internal variables ---
var direction: Vector2 = Vector2.RIGHT
var start_position: Vector2
var active: bool = true

func _ready() -> void:
	start_position = global_position
	
	# Rotate sprite to face direction
	if rotate_to_direction:
		rotation = direction.angle()
	
	# Connect collision
	connect("body_entered", Callable(self, "_on_body_entered"))

	# Optional: make sprite slightly visible for debugging
	if $Sprite2D:
		$Sprite2D.visible = true
		print("Projectile ready at ", global_position)

func _physics_process(delta: float) -> void:
	if not active:
		return
	
	# Move projectile
	global_position += direction * speed * delta
	
	# Check distance traveled
	if global_position.distance_to(start_position) >= max_distance:
		active = false
		queue_free()

func _on_body_entered(body: Node) -> void:
	if not active:
		return
	
	# Deal damage if possible
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	# Destroy projectile
	active = false
	queue_free()
