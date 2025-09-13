extends Resource
class_name Savior

#Add Savior

var used := false # Tracks if the revive has been used

#Player Equips Savior
func apply(player: Node) -> void:
	pass
	
func remove(player: Node) -> void:
	pass
	
func try_revive(player: Node) -> bool:
	if not used and player.Hp <= 0:
		player.Hp = int(player.max_hp * 0.3)
		used = true
		return true 
	return false
	
"""
In player.gd when you take damage and check if player is dead, if(hp <= 0)
Check if one of the slots is savior && card.try_revive(self)
else if not both of those just die

"""
	
