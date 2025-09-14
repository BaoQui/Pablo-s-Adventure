extends Resource
class_name Banker

# Banker card: Increases money multiplier by 1.5x
func apply(player: Node) -> void:
	if "money_multiplier" in player:
		player.money_multiplier *= 1.5

func remove(player: Node) -> void:
	if "money_multiplier" in player:
		player.money_multiplier /= 1.5
