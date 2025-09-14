# InventorySlot.gd
extends Control
class_name InventorySlot

signal slot_clicked(slot: InventorySlot)

@onready var background: Panel = $Background
@onready var item_icon: TextureRect = $ItemIcon
@onready var item_count: Label = $ItemCount

var item: Card = null
var is_hand_slot: bool = false
var slot_index: int = 0
var inventory_ui: Control = null
var is_selected: bool = false

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
	update_background_style()

func update_background_style():
	var style_box = StyleBoxFlat.new()
	
	if is_selected and not is_hand_slot:
		# Selected inventory slot - bright highlight
		style_box.bg_color = Color(0.8, 0.8, 0.2, 0.7)  # Yellow highlight
		style_box.border_color = Color(1.0, 1.0, 0.4, 1.0)
	elif is_hand_slot:
		# Hand slot - blue tint
		style_box.bg_color = Color(0.3, 0.3, 0.8, 0.5)  
		style_box.border_color = Color(0.5, 0.5, 1.0, 0.8)
	else:
		# Regular inventory slot - gray
		style_box.bg_color = Color(0.2, 0.2, 0.2, 0.5)  
		style_box.border_color = Color(0.6, 0.6, 0.6, 0.8)
	
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.corner_radius_top_left = 4
	style_box.corner_radius_top_right = 4
	style_box.corner_radius_bottom_left = 4
	style_box.corner_radius_bottom_right = 4
	
	# Apply the style
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

func set_selected(selected: bool):
	is_selected = selected
	update_background_style()

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Slot clicked: ", slot_index, " (", "hand" if is_hand_slot else "inventory", ")")
			slot_clicked.emit(self)

func _on_mouse_entered():
	# Highlight slot on hover
	if not is_selected:
		modulate = Color(1.2, 1.2, 1.2, 1.0)

func _on_mouse_exited():
	# Remove highlight
	if not is_selected:
		modulate = Color.WHITE
