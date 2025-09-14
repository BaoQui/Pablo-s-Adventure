# res://scripts/InventoryManager.gd
extends Node
class_name InventoryManager

const MAX_INVENTORY := 20
const MAX_EQUIPPED := 5

var inventory: Array[Item] = []  # holds 20 slots
var equipped: Array[int] = []    # stores inventory indices of equipped items

signal inventory_changed()
signal equipped_changed()

func _ready():
	inventory.resize(MAX_INVENTORY)
	for i in inventory.size():
		inventory[i] = null
	equipped.clear()

# Add an item to first empty slot
func add_item(new_item: Item) -> int:
	for i in inventory.size():
		if inventory[i] == null:
			inventory[i] = new_item
			emit_signal("inventory_changed")
			return i
	return -1  # inventory full

# Remove item from inventory (also unequip if equipped)
func remove_item(inv_index: int) -> void:
	if inv_index < 0 or inv_index >= MAX_INVENTORY:
		return
	unequip_item(inv_index)
	inventory[inv_index] = null
	emit_signal("inventory_changed")

# Equip item from inventory
func equip_item(inv_index: int) -> bool:
	if inv_index < 0 or inv_index >= MAX_INVENTORY:
		return false
	if inventory[inv_index] == null:
		return false
	if equipped.size() >= MAX_EQUIPPED:
		return false
	if inv_index in equipped:
		return false  # already equipped

	equipped.append(inv_index)
	emit_signal("equipped_changed")
	return true

# Unequip item
func unequip_item(inv_index: int) -> void:
	if inv_index in equipped:
		equipped.erase(inv_index)
		emit_signal("equipped_changed")

# Calculate total bonuses from equipped items
func get_total_bonus() -> Dictionary:
	var total = {
		"damage": 0,
		"health": 0,
		"speed": 0.0
	}
	for idx in equipped:
		var it = inventory[idx]
		if it:
			total.damage += it.bonus_damage
			total.health += it.bonus_health
			total.speed += it.bonus_speed
	return total
