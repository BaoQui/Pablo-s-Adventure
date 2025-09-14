extends Resource

# Jester card: Increases punch damage by 10
func apply(player: Node) -> void:
	player.punch_damage += 10

func remove(player: Node) -> void:
	player.punch_damage -= 10
