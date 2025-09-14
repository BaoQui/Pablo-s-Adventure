# InventoryUI.gd
extends Control
class_name InventoryUI

@onready var inventory_grid: GridContainer = $VBoxContainer/InventorySection/ScrollContainer/InventoryGrid
@onready var hand_grid: GridContainer = $VBoxContainer/HandSection/HandGrid
@onready var card_info_panel: Panel = $VBoxContainer/CardInfoPanel
@onready var card_info_label: RichTextLabel = $VBoxContainer/CardInfoPanel/CardInfoLabel
@onready var close_button: Button = $VBoxContainer/CloseButton

var card_inventory: CardInventory
var card_button_scene: PackedScene = preload("res://CardButton.tscn")  # You'll need to create this
var selected_card: Card = null

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	visible = false

func setup(inventory: CardInventory):
	card_inventory = inventory
	card_inventory.inventory_changed.connect(_refresh_inventory)
	card_inventory.hand_changed.connect(_refresh_hand)
	_refresh_inventory()
	_refresh_hand()

func show_inventory():
	visible = true
	get_tree().paused = true

func hide_inventory():
	visible = false
	get_tree().paused = false

func _on_close_pressed():
	hide_inventory()

func _refresh_inventory():
	if not inventory_grid:
		return
	
	# Clear existing buttons
	for child in inventory_grid.get_children():
		child.queue_free()
	
	# Add card buttons for inventory
	for card in card_inventory.get_inventory_cards():
		var button = _create_card_button(card, false)
		inventory_grid.add_child(button)

func _refresh_hand():
	if not hand_grid:
		return
	
	# Clear existing buttons
	for child in hand_grid.get_children():
		child.queue_free()
	
	# Add card buttons for hand
	for card in card_inventory.get_hand_cards():
		var button = _create_card_button(card, true)
		hand_grid.add_child(button)
	
	# Add empty slots for remaining hand space
	var remaining_slots = card_inventory.get_hand_space()
	for i in remaining_slots:
		var empty_button = Button.new()
		empty_button.text = "Empty"
		empty_button.custom_minimum_size = Vector2(80, 120)
		empty_button.modulate = Color(0.5, 0.5, 0.5, 0.7)
		hand_grid.add_child(empty_button)

func _create_card_button(card: Card, is_in_hand: bool) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(80, 120)
	button.text = card.card_name
	
	# Color code by suit
	button.modulate = card.get_card_color()
	
	# Connect signals
	button.pressed.connect(_on_card_button_pressed.bind(card, is_in_hand))
	button.mouse_entered.connect(_on_card_hover.bind(card))
	button.mouse_exited.connect(_on_card_unhover)
	
	return button

func _on_card_button_pressed(card: Card, is_in_hand: bool):
	if is_in_hand:
		# Remove from hand
		card_inventory.remove_card_from_hand(card)
	else:
		# Add to hand (if space available)
		card_inventory.add_card_to_hand(card)

func _on_card_hover(card: Card):
	selected_card = card
	_update_card_info()

func _on_card_unhover():
	selected_card = null
	_update_card_info()

func _update_card_info():
	if not card_info_panel or not card_info_label:
		return
	
	if selected_card:
		card_info_panel.visible = true
		var info_text = "[b]%s[/b]\n\n%s" % [selected_card.card_name, selected_card.description]
		
		if selected_card.card_type == Card.CardType.JOKER:
			match selected_card.joker_type:
				Card.JokerType.DUELIST:
					info_text += "\n\nAttack speed bonus is lost when taking damage."
		
		card_info_label.text = info_text
	else:
		card_info_panel.visible = false

func _input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		hide_inventory()
