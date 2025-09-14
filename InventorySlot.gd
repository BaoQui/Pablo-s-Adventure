# InventorySlot.gd
extends Control
class_name InventorySlot

signal slot_clicked(slot: InventorySlot)
signal drag_started(slot: InventorySlot)
signal drag_ended(slot: InventorySlot)

@onready var background: Panel = $Background
@onready var item_icon: TextureRect = $ItemIcon
@onready var item_count: Label = $ItemCount

var item: Card = null
var is_hand_slot: bool = false
var slot_index: int = 0
var inventory_ui: Control = null

var is_dragging: bool = false
var drag_start_position: Vector2

func _ready():
	# Set up the slot appearance
	setup_slot_appearance()
	
	# Connect mouse signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup_slot_appearance():
	# Create background if it doesn't exist
	if not background:
		background = Panel.new()
		add_child(background)
		move_child(background, 0)  # Put background behind everything
	
	if not item_icon:
		item_icon = TextureRect.new()
		add_child(item_icon)
	
	if not item_count:
		item_count = Label.new()
		add_child(item_count)
	
	# Set up sizes and positions
	custom_minimum_size = Vector2(80, 80)
	background.size = Vector2(80, 80)
	item_icon.size = Vector2(64, 64)
	item_icon.position = Vector2(8, 8)
	item_count.position = Vector2(60, 60)
	item_count.size = Vector2(20, 20)
	
	# Style the background
	var style_box = StyleBoxFlat.new()
	if is_hand_slot:
		style_box.bg_color = Color(0.3, 0.3, 0.8, 0.5)  # Blue tint for hand
		style_box.border_color = Color(0.5, 0.5, 1.0, 0.8)
	else:
		style_box.bg_color = Color(0.2, 0.2, 0.2, 0.5)  # Gray for inventory
		style_box.border_color = Color(0.6, 0.6, 0.6, 0.8)
	
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.corner_radius_top_left = 4
	style_box.corner_radius_top_right = 4
	style_box.corner_radius_bottom_left = 4
	style_box.corner_radius_bottom_right = 4
	
	# Apply the style (you might need to create a Panel instead of NinePatchRect for this to work)
	if background is Panel:
		background.add_theme_stylebox_override("panel", style_box)

func set_item(new_item: Card):
	item = new_item
	
	if item:
		item_icon.texture = item.icon
		item_icon.show()
		
		# Show count if there's a stack system
		if item.has_method("get_stack_count"):
			var count = item.get_stack_count()
			if count > 1:
				item_count.text = str(count)
				item_count.show()
			else:
				item_count.hide()
		else:
			item_count.hide()
	else:
		item_icon.texture = null
		item_icon.hide()
		item_count.hide()

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_left_click_pressed(event.global_position)
			else:
				_on_left_click_released()
	
	elif event is InputEventMouseMotion and is_dragging:
		_on_drag_motion(event.global_position)

func _on_left_click_pressed(click_position: Vector2):
	if item:
		is_dragging = true
		drag_start_position = click_position
		drag_started.emit(self)

func _on_left_click_released():
	if is_dragging:
		is_dragging = false
		drag_ended.emit(self)
		
		# Check if we're over another slot
		var drop_target = _get_slot_under_mouse()
		if drop_target and drop_target != self:
			inventory_ui.try_drop_item(drop_target)
	else:
		# Regular click
		slot_clicked.emit(self)

func _on_drag_motion(mouse_position: Vector2):
	# The drag preview is handled by the inventory UI
	pass

func _get_slot_under_mouse() -> InventorySlot:
	var mouse_pos = get_global_mouse_position()
	
	# Check all slots in the inventory UI
	if inventory_ui:
		# Check hand slots
		for slot in inventory_ui.hand_slots:
			if slot != self and slot.get_global_rect().has_point(mouse_pos):
				return slot
		
		# Check inventory slots
		for slot in inventory_ui.inventory_slots:
			if slot != self and slot.get_global_rect().has_point(mouse_pos):
				return slot
	
	return null

func _on_mouse_entered():
	# Highlight slot on hover
	modulate = Color(1.2, 1.2, 1.2, 1.0)

func _on_mouse_exited():
	# Remove highlight
	modulate = Color.WHITE

func can_accept_drop() -> bool:
	# Add any special logic for whether this slot can accept a drop
	return true
