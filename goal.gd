extends Area2D

@export var next_scene_path: String = "res://Level2.tscn"

@onready var goal_label: Label = get_tree().current_scene.get_node("CanvasLayer/goal_label")

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		var player = body as CharacterBody2D  # cast so we can access vars safely
		if player.kill_count >= 5:
			print("Level Complete!")
			await get_tree().create_timer(0.2).timeout
			get_tree().change_scene_to_file(next_scene_path)
		else:
			goal_label.text = "You have %d / 5 kills" % player.kill_count
			var t = get_tree().create_timer(2.0)
			t.timeout.connect(func(): goal_label.text = "")
