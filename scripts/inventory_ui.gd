extends Control

@onready var manager: InventoryManager = InventoryManager
@onready var inventory_grid: GridContainer = $InventoryGrid
@onready var equipped_hbox: HBoxContainer = $EquippedHBox

var inv_buttons: Array = []
var eq_buttons: Array = []

func _ready():
	# Build 20 inventory buttons
	for i in range(InventoryManager.MAX_INVENTORY):
		var b = Button.new()
		b.text = "Empty"
		b.rect_min_size = Vector2(64, 64)
		b.connect("pressed", Callable(self, "_on_inventory_pressed").bind(i))
		inventory_grid.add_child(b)
		inv_buttons.append(b)

	# Build 5 equipped slots
	for i in range(InventoryManager.MAX_EQUIPPED):
		var b = Button.new()
		b.text = "Empty"
		b.rect_min_size = Vector2(64, 64)
		equipped_hbox.add_child(b)
		eq_buttons.append(b)

	manager.connect("inventory_changed", Callable(self, "_refresh"))
	manager.connect("equipped_changed", Callable(self, "_refresh"))

	_refresh()

func _refresh():
	# Refresh inventory
	for i in inv_buttons.size():
		var item = manager.inventory[i]
		if item:
			inv_buttons[i].text = item.display_name
		else:
			inv_buttons[i].text = "Empty"

	# Refresh equipped
	for i in eq_buttons.size():
		if i < manager.equipped.size():
			var idx = manager.equipped[i]
			var item = manager.inventory[idx]
			eq_buttons[i].text = item.display_name
		else:
			eq_buttons[i].text = "Empty"

func _on_inventory_pressed(inv_index: int):
	if inv_index in manager.equipped:
		manager.unequip_item(inv_index)
	else:
		manager.equip_item(inv_index)
