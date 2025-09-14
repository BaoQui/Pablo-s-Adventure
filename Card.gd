# Card.gd
extends Resource
class_name Card

enum CardType {
	HEART,
	CLUB, 
	SPADE,
	DIAMOND,
	JOKER
}

@export var card_name: String = ""
@export var card_type: CardType
@export var effect_value: float = 0.0
@export var icon: Texture2D
@export var joker_type: String = ""  # For joker cards

func _init(name: String = "", type: CardType = CardType.HEART, value: float = 0.0):
	card_name = name
	card_type = type  
	effect_value = value
