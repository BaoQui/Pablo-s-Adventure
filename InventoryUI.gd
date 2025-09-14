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

# Drag and drop
var dragged_item: InventorySlot = null
var drag_preview: Control = null

func _ready():
	# Set up the UI
	setup_ui()
	hide()
	print("InventoryUI ready and hidden")
	
	# Make sure we can receive input
	set_process_input(true)

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
	
	# Connect signals
	slot.slot_clicked.connect(_on_slot_clicked)
	slot.drag_started.connect(_on_drag_started)
	slot.drag_ended.connect(_on_drag_ended)
	
	return slot

func open_inventory(inventory: CardInventory):
	print("InventoryUI.open_inventory called")
	if not inventory:
		print("ERROR: No inventory passed to open_inventory!")
		return
		
	card_inventory = inventory
	refresh_display()
	show()
	get_tree().paused = true
	
	# Force the control to be visible and on top
	z_index = 100
	move_to_front()
	
	print("Inventory opened - visible: ", visible, " modulate: ", modulate)

func close_inventory():
	print("Closing inventory...")
	hide()
	get_tree().paused = false
	inventory_closed.emit()

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
			print("Set hand slot ", i, " to ", hand_cards[i].card_name)
		else:
			hand_slots[i].set_item(null)
	
	# Update inventory slots
	var inventory_cards = card_inventory.get_inventory_cards()
	for i in inventory_slots.size():
		if i < inventory_cards.size() and inventory_cards[i] != null:
			inventory_slots[i].set_item(inventory_cards[i])
			print("Set inventory slot ", i, " to ", inventory_cards[i].card_name)
		else:
			inventory_slots[i].set_item(null)

func _input(event):
	if not visible:
		return
	
	# Handle ui_inventory action to close inventory
	if Input.is_action_just_pressed("ui_inventory"):
		print("ui_inventory pressed - closing inventory")
		close_inventory()
		get_viewport().set_input_as_handled()
		return
	
	# Handle other keys to close inventory
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			print("ESC key pressed - closing inventory")
			close_inventory()
			get_viewport().set_input_as_handled()
			return
	
	# Handle dragging
	if dragged_item and drag_preview and event is InputEventMouseMotion:
		drag_preview.global_position = event.global_position - Vector2(32, 32)

func _on_slot_clicked(slot: InventorySlot):
	print("Slot clicked: ", slot.slot_index, " is_hand: ", slot.is_hand_slot)

func _on_drag_started(slot: InventorySlot):
	print("Drag started from slot: ", slot.slot_index)
	dragged_item = slot
	create_drag_preview(slot)

func _on_drag_ended(slot: InventorySlot):
	print("Drag ended from slot: ", slot.slot_index)
	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null
	dragged_item = null

func create_drag_preview(slot: InventorySlot):
	if not slot.item:
		return
	
	drag_preview = Control.new()
	add_child(drag_preview)
	
	var preview_image = TextureRect.new()
	if slot.item.icon:
		preview_image.texture = slot.item.icon
	preview_image.custom_minimum_size = Vector2(64, 64)
	preview_image.modulate.a = 0.7
	drag_preview.add_child(preview_image)
	
	drag_preview.z_index = 100

func try_drop_item(target_slot: InventorySlot) -> bool:
	if not dragged_item or not target_slot:
		print("Drop failed - no dragged item or target")
		return false
	
	print("Trying to drop item from ", dragged_item.slot_index, " to ", target_slot.slot_index)
	
	# Check if we can place the item in the target slot
	if target_slot.item != null:
		# Try to swap items
		print("Target has item - attempting swap")
		return try_swap_items(dragged_item, target_slot)
	else:
		# Check capacity constraints
		if target_slot.is_hand_slot and card_inventory.get_hand_size() >= 3 and not dragged_item.is_hand_slot:
			print("Hand is full!")
			return false
		if not target_slot.is_hand_slot and card_inventory.get_inventory_size() >= 10 and dragged_item.is_hand_slot:
			print("Inventory is full!")
			return false
		
		# Move item to target slot
		print("Moving item to empty slot")
		return move_item(dragged_item, target_slot)

func try_swap_items(source_slot: InventorySlot, target_slot: InventorySlot) -> bool:
	var source_item = source_slot.item
	var target_item = target_slot.item
	
	print("Swapping items: ", source_item.card_name, " <-> ", target_item.card_name)
	
	# Temporarily remove both items
	if source_slot.is_hand_slot:
		card_inventory.remove_from_hand(source_slot.slot_index)
	else:
		card_inventory.remove_from_inventory(source_slot.slot_index)
	
	if target_slot.is_hand_slot:
		card_inventory.remove_from_hand(target_slot.slot_index)
	else:
		card_inventory.remove_from_inventory(target_slot.slot_index)
	
	# Add items to their new positions
	if target_slot.is_hand_slot:
		card_inventory.add_to_hand_at_index(source_item, target_slot.slot_index)
	else:
		card_inventory.add_to_inventory_at_index(source_item, target_slot.slot_index)
	
	if source_slot.is_hand_slot:
		card_inventory.add_to_hand_at_index(target_item, source_slot.slot_index)
	else:
		card_inventory.add_to_inventory_at_index(target_item, source_slot.slot_index)
	
	refresh_display()
	return true

func move_item(source_slot: InventorySlot, target_slot: InventorySlot) -> bool:
	var item = source_slot.item
	
	print("Moving item: ", item.card_name)
	
	# Remove from source
	if source_slot.is_hand_slot:
		card_inventory.remove_from_hand(source_slot.slot_index)
	else:
		card_inventory.remove_from_inventory(source_slot.slot_index)
	
	# Add to target
	if target_slot.is_hand_slot:
		card_inventory.add_to_hand_at_index(item, target_slot.slot_index)
	else:
		card_inventory.add_to_inventory_at_index(item, target_slot.slot_index)
	
	refresh_display()
	return true

func _on_close_button_pressed():
	close_inventory()
	
