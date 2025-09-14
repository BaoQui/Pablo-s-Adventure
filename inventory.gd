extends Control


func _ready() -> void:
	# Set up the initial state. The pause menu is hidden at the start.
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_pause"):
		toggle_visibility()


func toggle_visibility() -> void:
	visible = not visible
	get_tree().paused = visible  # This line is key. It pauses the game when the menu is visible.
