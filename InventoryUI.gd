# InventoryUI.gd
extends Control
class_name InventoryUI
signal inventory_closed

# Node references
@onready var hand_container: GridContainer = $MainContainer/HandPanel/HandGrid
@onready var inventory_container: GridContainer = $MainContainer/InventoryPanel/InventoryGrid
@onready var hand_label: Label = $MainContainer/HandPanel/HandLabel
@onready var inventory_label: Label = $MainContainer/InventoryPanel/InventoryLabel

# Inventory reference
var card_inventory: CardInventory
var hand_slots: Array[InventorySlot] = []
var inventory_slots: Array[InventorySlot] = []
var player_reference: Node = null

# Card selection system
var selected_inventory_cards: Array[int] = []  # Indices of selected cards in inventory

func _ready():
	# Set up the UI
	setup_ui()
	hide()
	process_mode = Node.PROCESS_MODE_PAUSABLE
	print("InventoryUI ready and hidden")

func setup_ui():
	# Create hand slots (3 slots)
	hand_slots.clear()
	for i in 3:
		var slot = create_inventory_slot(true, i)
		hand_container.add_child(slot)
		hand_slots.append(slot)
	
	# Create inventory slots (10 slots)
	inventory_slots.clear()
	for i in 10:
		var slot = create_inventory_slot(false, i)
		inventory_container.add_child(slot)
		inventory_slots.append(slot)

func create_inventory_slot(is_hand_slot: bool, slot_index: int) -> InventorySlot:
	var slot = preload("res://InventorySlot.tscn").instantiate()
	slot.is_hand_slot = is_hand_slot
	slot.slot_index = slot_index
	slot.inventory_ui = self
	
	# Connect signals - only need click for our new system
	slot.slot_clicked.connect(_on_slot_clicked)
	
	return slot

func open_inventory(inventory: CardInventory, player: Node = null):
	print("InventoryUI.open_inventory called")
	if not inventory:
		print("ERROR: No inventory passed to open_inventory!")
		return
		
	card_inventory = inventory
	player_reference = player
	selected_inventory_cards.clear()
	#populate_hand_from_inventory()
	refresh_display()
	
	# Position the inventory relative to camera/player
	position_inventory_on_screen()
	
	show()
	get_tree().paused = true
	
	# Force the control to be visible and on top
	z_index = 100
	move_to_front()
	
	print("Inventory opened - visible: ", visible)
	print_current_hand()  # Show what's in hand when opened

func position_inventory_on_screen():
	# Get the current camera position
	var camera = get_viewport().get_camera_2d()
	if camera:
		# Get camera's global position
		var camera_pos = camera.get_screen_center_position()
		
		# Get viewport size
		var _viewport_size = get_viewport().get_visible_rect().size
		
		# Center the inventory on the camera's view
		global_position = Vector2(
			camera_pos.x - size.x /453,
			camera_pos.y - size.y /20
		)
		
		print("Positioned inventory at camera center: ", global_position)
	elif player_reference:
		# Fallback: use player position if no camera found
		var _viewport_size = get_viewport().get_visible_rect().size
		global_position = Vector2(
			player_reference.global_position.x - size.x / 2,
			player_reference.global_position.y - size.y / 2
		)
		print("Positioned inventory at player center: ", global_position)
	else:
		# Last resort: center on viewport
		var viewport_size = get_viewport().get_visible_rect().size
		position = Vector2(
			viewport_size.x / 2 - size.x / 2,
			viewport_size.y / 2 - size.y / 2
		)
		print("Positioned inventory at viewport center")

func close_inventory():
	print("Closing inventory...")
	print_current_hand()  # Show what's in hand when closed
	hide()
	get_tree().paused = false
	inventory_closed.emit()

# Debug function to print current hand contents
func print_current_hand():
	if not card_inventory:
		return
	
	print("=== CURRENT HAND ===")
	var hand_cards = card_inventory.get_hand_cards()
	for i in range(hand_cards.size()):
		if hand_cards[i] != null:
			print("Hand slot %d: %s (Type: %s, Value: %d)" % [i, hand_cards[i].card_name, _get_card_type_name(hand_cards[i].card_type), hand_cards[i].effect_value])
		else:
			print("Hand slot %d: Empty" % i)
	print("==================")

func _get_card_type_name(card_type) -> String:
	match card_type:
		0: return "HEART"
		1: return "CLUB" 
		2: return "SPADE"
		3: return "DIAMOND"
		4: return "JOKER"
		_: return "UNKNOWN"

# New system: Populate hand with first available inventory cards
func populate_hand_from_inventory():
	if not card_inventory:
		return
	
	# Clear current hand
	for i in range(card_inventory.max_hand_size):
		card_inventory.remove_from_hand(i)
	
	# Find first 3 non-null inventory cards and move them to hand
	var hand_index = 0
	var inventory_cards = card_inventory.get_inventory_cards()
	
	for i in range(inventory_cards.size()):
		if hand_index >= card_inventory.max_hand_size:
			break
			
		if inventory_cards[i] != null:
			var card = card_inventory.remove_from_inventory(i)
			if card:
				card_inventory.add_to_hand_at_index(card, hand_index)
				hand_index += 1

func refresh_display():
	if not card_inventory:
		print("No card_inventory to refresh!")
		return
	
	print("Refreshing display...")
	
	# Update hand slots
	var hand_cards = card_inventory.get_hand_cards()
	for i in hand_slots.size():
		if i < hand_cards.size() and hand_cards[i] != null:
			hand_slots[i].set_item(hand_cards[i])
			hand_slots[i].set_selected(false)  # Hands aren't selectable
		else:
			hand_slots[i].set_item(null)
			hand_slots[i].set_selected(false)
	
	# Update inventory slots with selection highlighting
	var inventory_cards = card_inventory.get_inventory_cards()
	for i in inventory_slots.size():
		if i < inventory_cards.size() and inventory_cards[i] != null:
			inventory_slots[i].set_item(inventory_cards[i])
			inventory_slots[i].set_selected(i in selected_inventory_cards)
		else:
			inventory_slots[i].set_item(null)
			inventory_slots[i].set_selected(false)
	
	# Update labels
	update_labels()

func update_labels():
	if hand_label:
		var hand_cards = card_inventory.get_hand_cards()
		var hand_text = "Hand (%d/3)" % card_inventory.get_hand_size()
		# Add hand contents preview
		var hand_preview = []
		for i in range(hand_cards.size()):
			if hand_cards[i] != null:
				hand_preview.append(hand_cards[i].card_name.substr(0, 5))  # First 5 chars
		if hand_preview.size() > 0:
			hand_text += " [" + ", ".join(hand_preview) + "]"
		hand_label.text = hand_text
		
	if inventory_label:
		inventory_label.text = "Inventory (%d/10) | Selected: %d" % [card_inventory.get_inventory_size(), selected_inventory_cards.size()]

# Handle input using _unhandled_key_input to avoid conflicts
func _unhandled_key_input(event):
	if not visible:
		return
		
	if event.pressed:
		# Handle ui_inventory action to close inventory
		if event.is_action_pressed("ui_inventory"):
			print("ui_inventory pressed - closing inventory")
			close_inventory()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			print("ESC key pressed - closing inventory")
			close_inventory()
			get_viewport().set_input_as_handled()

func _on_slot_clicked(slot: InventorySlot):
	print("Slot clicked: ", slot.slot_index, " is_hand: ", slot.is_hand_slot)
	
	if slot.is_hand_slot:
		# Clicking hand slot - move card back to inventory
		handle_hand_slot_click(slot)
	else:
		# Clicking inventory slot - toggle selection
		handle_inventory_slot_click(slot)

func handle_hand_slot_click(slot: InventorySlot):
	if not slot.item:
		return
	
	print("Moving card from hand back to inventory: ", slot.item.card_name)
	
	# Remove from hand
	var card = card_inventory.remove_from_hand(slot.slot_index)
	if card:
		# Add back to inventory
		if card_inventory.add_to_inventory(card):
			print("Card moved back to inventory: ", card.card_name)
		else:
			# If inventory is full, put it back in hand
			card_inventory.add_to_hand_at_index(card, slot.slot_index)
			print("Inventory full - card stayed in hand")
	
	refresh_display()
	print_current_hand()  # Show updated hand

func handle_inventory_slot_click(slot: InventorySlot):
	if not slot.item:
		return
	
	var slot_index = slot.slot_index
	
	# Toggle selection
	if slot_index in selected_inventory_cards:
		selected_inventory_cards.erase(slot_index)
		print("Deselected inventory slot: ", slot_index, " (", slot.item.card_name, ")")
	else:
		# Check if we can add more to selection (max 3 for hand)
		if selected_inventory_cards.size() < 3:
			selected_inventory_cards.append(slot_index)
			print("Selected inventory slot: ", slot_index, " (", slot.item.card_name, ")")
		else:
			print("Cannot select more than 3 cards")
	
	# Update hand with currently selected cards
	update_hand_from_selection()
	refresh_display()
	print_current_hand()  # Show updated hand

func update_hand_from_selection():
	# Clear current hand
	for i in range(card_inventory.max_hand_size):
		var card = card_inventory.remove_from_hand(i)
		if card:
			# Put the card back in inventory
			card_inventory.add_to_inventory(card)
	
	# Move selected cards to hand
	selected_inventory_cards.sort()  # Keep consistent order
	var inventory_cards = card_inventory.get_inventory_cards()
	
	for i in range(selected_inventory_cards.size()):
		var inv_index = selected_inventory_cards[i]
		if inv_index < inventory_cards.size() and inventory_cards[inv_index] != null:
			var card = card_inventory.remove_from_inventory(inv_index)
			if card:
				card_inventory.add_to_hand_at_index(card, i)
	
	# Update selection indices after removal (they shift down)
	selected_inventory_cards.clear()

func _on_close_button_pressed():
	close_inventory()
