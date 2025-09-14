# Card.gd
extends Resource
class_name Card

enum CardType {
	HEART,     # Health modifier
	CLUB,      # Projectile cooldown reduction
	SPADE,     # Punch damage increase
	DIAMOND,   # Money multiplier
	JOKER      # Special effects
}

enum JokerType {
	JESTER,    # Punch damage boost
	BANKER,    # 1.5x money multiplier
	ATHLETE,   # Movement speed boost
	DUELIST    # Attack speed stacking
}

@export var card_name: String
@export var card_type: CardType
@export var joker_type: JokerType = JokerType.JESTER
@export var value: int = 1  # For regular cards (2-10, J, Q, K, A)
@export var modifier_amount: float = 0.0
@export var description: String
@export var icon_texture: Texture2D

func _init(type: CardType = CardType.HEART, card_value: int = 1, joker: JokerType = JokerType.JESTER):
	card_type = type
	value = card_value
	joker_type = joker
	_setup_card_properties()

func _setup_card_properties():
	match card_type:
		CardType.HEART:
			card_name = "Heart " + str(value)
			modifier_amount = value * 5.0  # 5 health per card value
			description = "Increases health by " + str(modifier_amount)
			
		CardType.CLUB:
			card_name = "Club " + str(value)
			modifier_amount = value * 0.05  # 0.05 second reduction per card value
			description = "Reduces projectile cooldown by " + str(modifier_amount) + "s"
			
		CardType.SPADE:
			card_name = "Spade " + str(value)
			modifier_amount = value * 2.0  # 2 damage per card value
			description = "Increases punch damage by " + str(modifier_amount)
			
		CardType.DIAMOND:
			card_name = "Diamond " + str(value)
			modifier_amount = value * 0.1  # 10% money increase per card value
			description = "Increases money gain by " + str(modifier_amount * 100) + "%"
			
		CardType.JOKER:
			match joker_type:
				JokerType.JESTER:
					card_name = "Jester"
					modifier_amount = 15.0
					description = "Increases punch damage by " + str(modifier_amount)
					
				JokerType.BANKER:
					card_name = "Banker"
					modifier_amount = 1.5
					description = "1.5x money multiplier"
					
				JokerType.ATHLETE:
					card_name = "Athlete"
					modifier_amount = 100.0
					description = "Increases movement speed by " + str(modifier_amount)
					
				JokerType.DUELIST:
					card_name = "Duelist"
					modifier_amount = 0.05
					description = "Attack speed increases with consecutive hits"

func get_card_color() -> Color:
	match card_type:
		CardType.HEART:
			return Color.RED
		CardType.CLUB:
			return Color.BLACK
		CardType.SPADE:
			return Color.BLACK
		CardType.DIAMOND:
			return Color.RED
		CardType.JOKER:
			return Color.PURPLE
	return Color.WHITE

func can_stack_with(other_card: Card) -> bool:
	if card_type != other_card.card_type:
		return false
	if card_type == CardType.JOKER:
		return joker_type == other_card.joker_type
	return true
