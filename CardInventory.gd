# CardInventory.gd
extends Node
class_name CardInventory

signal hand_changed
signal inventory_changed

# Hand can hold 3 items, inventory can hold 10
@export var max_hand_size: int = 3
@export var max_inventory_size: int = 10

var hand_cards: Array[Card] = []
var inventory_cards: Array[Card] = []

func _ready():
	# Initialize arrays with null values for proper indexing
	hand_cards.resize(max_hand_size)
	inventory_cards.resize(max_inventory_size)

# === HAND MANAGEMENT ===
func add_to_hand(card: Card) -> bool:
	for i in range(max_hand_size):
		if hand_cards[i] == null:
			hand_cards[i] = card
			hand_changed.emit()
			return true
	return false

func add_to_hand_at_index(card: Card, index: int) -> bool:
	if index < 0 or index >= max_hand_size:
		return false
	
	hand_cards[index] = card
	hand_changed.emit()
	return true

func remove_from_hand(index: int) -> Card:
	if index < 0 or index >= max_hand_size:
		return null
	
	var card = hand_cards[index]
	hand_cards[index] = null
	if card:
		hand_changed.emit()
	return card

func get_hand_cards() -> Array[Card]:
	return hand_cards

func get_hand_size() -> int:
	var count = 0
	for card in hand_cards:
		if card != null:
			count += 1
	return count

func is_hand_full() -> bool:
	return get_hand_size() >= max_hand_size

# === INVENTORY MANAGEMENT ===
func add_to_inventory(card: Card) -> bool:
	for i in range(max_inventory_size):
		if inventory_cards[i] == null:
			inventory_cards[i] = card
			inventory_changed.emit()
			return true
	return false

func add_to_inventory_at_index(card: Card, index: int) -> bool:
	if index < 0 or index >= max_inventory_size:
		return false
	
	inventory_cards[index] = card
	inventory_changed.emit()
	return true

func remove_from_inventory(index: int) -> Card:
	if index < 0 or index >= max_inventory_size:
		return null
	
	var card = inventory_cards[index]
	inventory_cards[index] = null
	if card:
		inventory_changed.emit()
	return card

func get_inventory_cards() -> Array[Card]:
	return inventory_cards

func get_inventory_size() -> int:
	var count = 0
	for card in inventory_cards:
		if card != null:
			count += 1
	return count

func is_inventory_full() -> bool:
	return get_inventory_size() >= max_inventory_size

# === CARD MANAGEMENT ===
func add_card_to_inventory(card: Card) -> bool:
	# Try to add to inventory first, then hand if inventory is full
	if add_to_inventory(card):
		return true
	elif add_to_hand(card):
		return true
	return false

func find_card_in_hand(card: Card) -> int:
	for i in range(hand_cards.size()):
		if hand_cards[i] == card:
			return i
	return -1

func find_card_in_inventory(card: Card) -> int:
	for i in range(inventory_cards.size()):
		if inventory_cards[i] == card:
			return i
	return -1

# === CARD EFFECTS (keeping your existing system) ===
func get_hand_modifier(card_type: Card.CardType) -> float:
	var modifier: float = 0.0
	for card in hand_cards:
		if card and card.card_type == card_type:
			modifier += card.effect_value
	return modifier

func get_hand_joker_effects() -> Dictionary:
	var effects = {}
	for card in hand_cards:
		if card and card.card_type == Card.CardType.JOKER:
			var joker_name = card.joker_type
			if joker_name in effects:
				effects[joker_name] += 1
			else:
				effects[joker_name] = 1
	return effects

func generate_random_drop() -> Card:
	# Your existing random card generation logic
	var new_card = Card.new()
	
	# Random card generation logic here
	var card_types = [Card.CardType.HEART, Card.CardType.CLUB, Card.CardType.SPADE, Card.CardType.DIAMOND]
	new_card.card_type = card_types[randi() % card_types.size()]
	new_card.effect_value = randi_range(5, 15)
	
	# Set card name and icon based on type
	match new_card.card_type:
		Card.CardType.HEART:
			new_card.card_name = "Heart Card"
		Card.CardType.CLUB:
			new_card.card_name = "Club Card"
		Card.CardType.SPADE:
			new_card.card_name = "Spade Card"
		Card.CardType.DIAMOND:
			new_card.card_name = "Diamond Card"
	
	return new_card

# === UTILITY FUNCTIONS ===
func get_total_cards() -> int:
	return get_hand_size() + get_inventory_size()

func has_space() -> bool:
	return not (is_hand_full() and is_inventory_full())

func print_inventory():
	print("=== INVENTORY ===")
	print("Hand (", get_hand_size(), "/", max_hand_size, "):")
	for i in range(hand_cards.size()):
		if hand_cards[i]:
			print("  [", i, "] ", hand_cards[i].card_name)
		else:
			print("  [", i, "] Empty")
	
	print("Inventory (", get_inventory_size(), "/", max_inventory_size, "):")
	for i in range(inventory_cards.size()):
		if inventory_cards[i]:
			print("  [", i, "] ", inventory_cards[i].card_name)
		else:
			print("  [", i, "] Empty")
