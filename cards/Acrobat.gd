extends Resource
class_name Acrobat

# Acrobat card: adds one dash
func apply(player: Node) -> void:
	if player.has("dash_count"):
		player.dash_count += 1

func remove(player: Node) -> void:
	if player.has("dash_count"):
		player.dash_count -= 1
