extends Resource
class_name Banker

#Add Banker 
func apply(player: Node) -> void:
	player.chip_gain *=  1.5 
#Remove Banker
func remove(player: Node) -> void:
	player.chip_gain /= 1.5

#How To Add A Banker
#set_card(1, Banker.new())
