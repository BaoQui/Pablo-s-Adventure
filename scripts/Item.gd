# res://scripts/Item.gd
extends Resource
class_name Item

@export var id: String
@export var display_name: String
@export var description: String
@export var icon: Texture2D

# Passive effects (you can extend this list later)
@export var bonus_damage: int = 0
@export var bonus_health: int = 0
@export var bonus_speed: float = 0.0
