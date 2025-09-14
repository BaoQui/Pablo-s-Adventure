# CardInventory.gd
extends Node
class_name CardInventory

signal inventory_changed
signal hand_changed

const MAX_INVENTORY_SIZE = 20
const HAND_SIZE = 5

var inventory_cards: Array[Card] = []
var hand_cards: Array[Card] = []

# Card generation weights for random drops
var card_weights = {
	Card.CardType.HEART: 25,
	Card.CardType.CLUB: 25,
	Card.CardType.SPADE: 25,
	Card.CardType.DIAMOND: 25,
	Card.CardType.JOKER: 10  # Jokers are rarer
}

func _ready():
	# Initialize with some starting cards for testing
	_generate_starting_cards()

func _generate_starting_cards():
	# Give player a few basic cards to start
	add_card_to_inventory(_create_random_card(Card.CardType.HEART))
	add_card_to_inventory(_create_random_card(Card.CardType.CLUB))
	add_card_to_inventory(_create_random_card(Card.CardType.SPADE))

func add_card_to_inventory(card: Card) -> bool:
	if inventory_cards.size() >= MAX_INVENTORY_SIZE:
		print("Inventory is full!")
		return false
	
	inventory_cards.append(card)
	inventory_changed.emit()
	print("Added card to inventory: ", card.card_name)
	return true

func remove_card_from_inventory(card: Card) -> bool:
	var index = inventory_cards.find(card)
	if index != -1:
		inventory_cards.remove_at(index)
		inventory_changed.emit()
		return true
	return false

func add_card_to_hand(card: Card) -> bool:
	if hand_cards.size() >= HAND_SIZE:
		print("Hand is full!")
		return false
	
	if card in inventory_cards:
		inventory_cards.erase(card)
		hand_cards.append(card)
		inventory_changed.emit()
		hand_changed.emit()
		return true
	return false

func remove_card_from_hand(card: Card) -> bool:
	var index = hand_cards.find(card)
	if index != -1:
		hand_cards.remove_at(index)
		inventory_cards.append(card)
		hand_changed.emit()
		inventory_changed.emit()
		return true
	return false

func get_hand_modifier(card_type: Card.CardType) -> float:
	var total_modifier = 0.0
	var card_count = 0
	
	for card in hand_cards:
		if card.card_type == card_type:
			total_modifier += card.modifier_amount
			card_count += 1
	
	return total_modifier

func get_hand_joker_effects() -> Dictionary:
	var effects = {}
	
	for card in hand_cards:
		if card.card_type == Card.CardType.JOKER:
			var joker_name = Card.JokerType.keys()[card.joker_type]
			if joker_name in effects:
				effects[joker_name] += 1
			else:
				effects[joker_name] = 1
	
	return effects

func generate_random_drop() -> Card:
	var random_type = _get_weighted_random_type()
	return _create_random_card(random_type)

func _get_weighted_random_type() -> Card.CardType:
	var total_weight = 0
	for weight in card_weights.values():
		total_weight += weight
	
	var random_value = randi() % total_weight
	var current_weight = 0
	
	for type in card_weights:
		current_weight += card_weights[type]
		if random_value < current_weight:
			return type
	
	return Card.CardType.HEART  # Fallback

func _create_random_card(type: Card.CardType) -> Card:
	var card = Card.new()
	card.card_type = type
	
	if type == Card.CardType.JOKER:
		card.joker_type = randi() % Card.JokerType.size()
	else:
		card.value = randi_range(1, 13)  # 1-13 for card values
	
	card._setup_card_properties()
	return card

func get_inventory_cards() -> Array[Card]:
	return inventory_cards.duplicate()

func get_hand_cards() -> Array[Card]:
	return hand_cards.duplicate()

func is_inventory_full() -> bool:
	return inventory_cards.size() >= MAX_INVENTORY_SIZE

func is_hand_full() -> bool:
	return hand_cards.size() >= HAND_SIZE

func get_inventory_space() -> int:
	return MAX_INVENTORY_SIZE - inventory_cards.size()

func get_hand_space() -> int:
	return HAND_SIZE - hand_cards.size()

# Save/Load functionality
func get_save_data() -> Dictionary:
	var save_data = {
		"inventory": [],
		"hand": []
	}
	
	for card in inventory_cards:
		save_data.inventory.append(_card_to_dict(card))
	
	for card in hand_cards:
		save_data.hand.append(_card_to_dict(card))
	
	return save_data

func load_save_data(data: Dictionary):
	inventory_cards.clear()
	hand_cards.clear()
	
	if "inventory" in data:
		for card_data in data.inventory:
			inventory_cards.append(_dict_to_card(card_data))
	
	if "hand" in data:
		for card_data in data.hand:
			hand_cards.append(_dict_to_card(card_data))
	
	inventory_changed.emit()
	hand_changed.emit()

func _card_to_dict(card: Card) -> Dictionary:
	return {
		"type": card.card_type,
		"value": card.value,
		"joker_type": card.joker_type
	}

func _dict_to_card(data: Dictionary) -> Card:
	var card = Card.new()
	card.card_type = data.type
	card.value = data.value
	card.joker_type = data.joker_type
	card._setup_card_properties()
	return card
