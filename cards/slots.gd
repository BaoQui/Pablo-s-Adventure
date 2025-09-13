extends Resource

# three slots to hold cards
var slot1: Resource = null
var slot2: Resource = null
var slot3: Resource = null

# equip a card into a specific slot
func set_card(slot: int, card: Resource) -> void:
	# remove the old card first (if one exists)
	match slot:
		1:
			if slot1: slot1.remove(self)
			slot1 = card
			if slot1: slot1.apply(self)

		2:
			if slot2: slot2.remove(self)
			slot2 = card
			if slot2: slot2.apply(self)

		3:
			if slot3: slot3.remove(self)
			slot3 = card
			if slot3: slot3.apply(self)
			
#How To Add Card
#set_card([slot_number],[Card_name].new())
#set_card(1,Joker.new())
