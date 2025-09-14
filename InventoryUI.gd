# InventoryUI.gd
extends Control

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
	card_inventory = inventory
	refresh_display()
	show()
	get_tree().paused = true

func close_inventory():
	hide()
	get_tree().paused = false
	inventory_closed.emit()

func refresh_display():
	if not card_inventory:
		return
	
	# Update hand slots
	var hand_cards = card_inventory.get_hand_cards()
	for i in hand_slots.size():
		if i < hand_cards.size():
			hand_slots[i].set_item(hand_cards[i])
		else:
			hand_slots[i].set_item(null)
	
	# Update inventory slots
	var inventory_cards = card_inventory.get_inventory_cards()
	for i in inventory_slots.size():
		if i < inventory_cards.size():
			inventory_slots[i].set_item(inventory_cards[i])
		else:
			inventory_slots[i].set_item(null)

func _on_slot_clicked(slot: InventorySlot):
	# Handle slot clicking if needed
	pass

func _on_drag_started(slot: InventorySlot):
	dragged_item = slot
	create_drag_preview(slot)

func _on_drag_ended(slot: InventorySlot):
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
	preview_image.texture = slot.item.icon
	preview_image.custom_minimum_size = Vector2(64, 64)
	preview_image.modulate.a = 0.7
	drag_preview.add_child(preview_image)
	
	drag_preview.z_index = 100

func _input(event):
	if not visible:
		return
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_I:
		close_inventory()
	
	if dragged_item and drag_preview and event is InputEventMouseMotion:
		drag_preview.global_position = event.global_position - Vector2(32, 32)

func try_drop_item(target_slot: InventorySlot) -> bool:
	if not dragged_item or not target_slot:
		return false
	
	# Check if we can place the item in the target slot
	if target_slot.item != null:
		# Try to swap items
		return try_swap_items(dragged_item, target_slot)
	else:
		# Check capacity constraints
		if target_slot.is_hand_slot and card_inventory.get_hand_size() >= 3 and not dragged_item.is_hand_slot:
			return false
		if not target_slot.is_hand_slot and card_inventory.get_inventory_size() >= 10 and dragged_item.is_hand_slot:
			return false
		
		# Move item to target slot
		return move_item(dragged_item, target_slot)

func try_swap_items(source_slot: InventorySlot, target_slot: InventorySlot) -> bool:
	var source_item = source_slot.item
	var target_item = target_slot.item
	
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
