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
	# Connect the body_entered signal
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# Set collision layers (optional - adjust based on your setup)
	collision_layer = 0  # Projectile doesn't collide with anything
	collision_mask = 2   # Only detects enemies (assuming they're on layer 2)
	
	start_position = global_position
	
	if rotate_to_direction:
		rotation = direction.angle()
	
	print("Projectile created at: ", global_position)

func _physics_process(delta: float) -> void:
	if not active:
		return
	
	# Move the projectile
	global_position += direction * speed * delta
	
	# Check if projectile has traveled max distance
	if global_position.distance_to(start_position) >= max_distance:
		print("Projectile reached max distance, destroying")
		destroy_projectile()

func _on_body_entered(body: Node) -> void:
	if not active:
		return
	
	print("Projectile hit: ", body.name)
	
	# Check if the body can take damage (enemy)
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("Damage dealt: ", damage)
		destroy_projectile()
	# Don't destroy on player collision (assuming player doesn't have take_damage method)
	elif body.name == "Player" or body.get_parent().name == "Player":
		return  # Ignore player collision

func destroy_projectile() -> void:
	active = false
	queue_free()
