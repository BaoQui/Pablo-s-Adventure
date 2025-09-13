extends Resource
class_name Jester

#Add Jester
func apply(player: Node) -> void:
	player.dmg_flat_add += 10 
	
func remove(player: Node) -> void:
	player.dmg_flat_add -= 10


#How To Add A Joker
#set_card(1, Jester.new())
