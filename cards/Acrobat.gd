extends Resource
class_name Acrobat

#Add Athelete 
func apply(player: Node) -> void:
	player.dash_count += 1 
#Remove Athelete
func remove(player: Node) -> void:
	player.dash_count -= 1
