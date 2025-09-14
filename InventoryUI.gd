# InventoryUI.gd
extends Control
class_name InventoryUI

signal inventory_closed

# --- Node references ---
@onready var hand_container: GridContainer = $MainContainer/HandPanel/HandGrid
@onready var inventory_container: GridContainer = $MainContainer/InventoryPanel/InventoryGrid
@onready var hand_label: Label = $MainContainer/HandPanel/HandLabel
@onready var inventory_label: Label = $MainContainer/InventoryPanel/InventoryLabel

# --- References ---
var card_inventory: CardInventory = null
var player_ref: Node = null

func _ready():
	visible = false  # Start hidden

# === OPEN / CLOSE ===
func open_inventory(_card_inventory: CardInventory, _player: Node):
	card_inventory = _card_inventory
	player_ref = _player
	visible = true
	populate_slots()
	# Connect signals for live updates
	if card_inventory and not card_inventory.hand_changed.is_connected(_on_hand_changed):
		card_inventory.hand_changed.connect(_on_hand_changed)
	if card_inventory and not card_inventory.inventory_changed.is_connected(_on_inventory_changed):
		card_inventory.inventory_changed.connect(_on_inventory_changed)

func close_inventory():
	visible = false
	emit_signal("inventory_closed")

# === SLOT POPULATION ===
func populate_slots():
	# Clear old slots
	for slot in hand_container.get_children():
		slot.queue_free()
	for slot in inventory_container.get_children():
		slot.queue_free()
	
	# Populate hand slots
	for i in range(card_inventory.max_hand_size):
		var card = card_inventory.hand_cards[i]
		var slot = InventorySlot.new()
		slot.is_hand_slot = true
		slot.slot_index = i
		slot.inventory_ui = self
		slot.set_item(card)
		slot.slot_clicked.connect(_on_slot_clicked)
		hand_container.add_child(slot)
	
	# Populate inventory slots
	for i in range(card_inventory.max_inventory_size):
		var card = card_inventory.inventory_cards[i]
		var slot = InventorySlot.new()
		slot.is_hand_slot = false
		slot.slot_index = i
		slot.inventory_ui = self
		slot.set_item(card)
		slot.slot_clicked.connect(_on_slot_clicked)
		inventory_container.add_child(slot)

# === SLOT CLICK HANDLING ===
func _on_slot_clicked(slot: InventorySlot):
	if slot.is_hand_slot:
		print("Hand slot clicked: ", slot.slot_index)
		# Example: remove from hand on click
		if card_inventory.hand_cards[slot.slot_index]:
			var removed_card = card_inventory.remove_from_hand(slot.slot_index)
			card_inventory.add_to_inventory(removed_card)
	else:
		print("Inventory slot clicked: ", slot.slot_index)
		# Example: move to hand if space available
		if card_inventory.inventory_cards[slot.slot_index] and not card_inventory.is_hand_full():
			var card = card_inventory.remove_from_inventory(slot.slot_index)
			card_inventory.add_to_hand(card)

	# Refresh slots after any change
	populate_slots()

# === SIGNAL RESPONSES ===
func _on_hand_changed():
	populate_slots()

func _on_inventory_changed():
	populate_slots()
