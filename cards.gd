extends CanvasLayer

# --- UI nodes ---
@onready var card1: TextureRect = $Card1
@onready var card2: TextureRect = $Card2

# --- Folder and card names ---
var card_folder := "res://jokers/"
var card_names := ["Athlete.png", "Banker.png", "Jester.png"]
var card_textures: Array[Texture2D] = []

# --- Map card textures to their .gd scripts ---
var card_scripts := {
	"Athlete.png": "res://cards/Athlete.gd",
	"Banker.png": "res://cards/Banker.gd",
	"Jester.png": "res://cards/Jester.gd",
}

# --- Reference to player ---
@onready var player := get_tree().get_current_scene().get_node("Player")  # Adjust path if needed

func _ready():
	if not player:
		push_error("Player node not found!")
		return

	load_card_textures()
	show_random_cards()

# --- Load card textures ---
func load_card_textures() -> void:
	card_textures.clear()
	for card_name in card_names:
		var path = card_folder + card_name
		if ResourceLoader.exists(path):
			var card_tex = load(path) as Texture2D
			if card_tex:
				card_textures.append(card_tex)
		else:
			push_error("Card not found: " + path)

# --- Show 2 random cards and apply their effects ---
func show_random_cards() -> void:
	if card_textures.size() < 2:
		push_error("You need at least 2 card textures!")
		return

	var indices: Array[int] = []
	while indices.size() < 2:
		var idx = randi() % card_textures.size()
		if idx not in indices:
			indices.append(idx)

	# Set textures
	card1.texture = card_textures[indices[0]]
	card2.texture = card_textures[indices[1]]

	# Apply effects safely
	apply_card_effect(card_names[indices[0]])
	apply_card_effect(card_names[indices[1]])

# --- Apply card effect to player ---
func apply_card_effect(card_name: String) -> void:
	if not player:
		push_error("Cannot apply card effect; player is null!")
		return

	if card_name in card_scripts:
		var card_script_path: String = card_scripts[card_name]
		var card_script = load(card_script_path)
		if card_script:
			var card_instance = card_script.new()
			if player.has_method("apply_card_effect"):
				player.apply_card_effect(card_instance)
			else:
				push_error("Player does not have apply_card_effect() method")
		else:
			push_error("Failed to load card script: " + card_script_path)
	else:
		push_error("No card script found for: " + card_name)
