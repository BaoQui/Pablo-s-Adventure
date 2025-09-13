extends Resource
class_name Athlete

#Add Athelete 
func apply(player: Node) -> void:
	player.move_speed *=  1.5 
#Remove Athelete
func remove(player: Node) -> void:
	player.move_speed /= 1.5
