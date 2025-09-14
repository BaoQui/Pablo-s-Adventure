extends CanvasLayer

# References to UI nodes
@onready var card1: TextureRect = $Card1
@onready var card2: TextureRect = $Card2

# Folder and card names
var card_folder := "res://jokers/"
var card_names := ["Athlete.png", "Banker.png", "Jester.png", "Savior.png"]
var card_textures: Array[Texture2D] = []

func _ready():
	load_card_textures()
	show_random_cards()

# Load card textures from folder
func load_card_textures():
	card_textures.clear()
	for card_name in card_names:
		var path = card_folder + card_name
		if ResourceLoader.exists(path):
			var card_tex = load(path) as Texture2D
			if card_tex:
				card_textures.append(card_tex)
		else:
			push_error("Card not found: " + path)


# Pick and display 2 random cards
func show_random_cards():
	if card_textures.size() < 2:
		push_error("You need at least 2 card textures!")
		return

	# Pick 2 unique random indices
	var indices = []
	while indices.size() < 2:
		var idx = randi() % card_textures.size()
		if idx not in indices:
			indices.append(idx)
	
	# Set textures
	card1.texture = card_textures[indices[0]]
	card2.texture = card_textures[indices[1]]
