extends Area2D

@export var next_scene_path: String = "res://Level2.tscn"

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	print("Entered goal:", body.name, " class:", body.get_class())
	if body.is_in_group("Player"):
		print("Level Complete!")
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file(next_scene_path)
