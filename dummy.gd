extends CharacterBody2D

# --- Enemy settings ---
@export var health: int = 50

func take_damage(damage_amount: int):
	health -= damage_amount
	print("Enemy took ", damage_amount, " damage. Health is now: ", health)
	if health <= 0:
		queue_free() # Destroys the enemy node when health is 0
