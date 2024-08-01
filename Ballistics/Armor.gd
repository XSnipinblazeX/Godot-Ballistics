#this is the armor code, we calculate effective armor inside this script to hopefully make it simpler and take a load off of the other scripts

extends StaticBody3D

# Property to define the armor plate's penetration resistance
@export var penetration_resistance = 10.0
@export var yield_strength = 1.5e9
# Method to check if the node is an armor plate
func is_armor_plate() -> bool:
	return true

# Method to get the penetration resistance
func get_penetration_resistance(theta) -> float:
	return abs(penetration_resistance / cos(theta))
func get_yield_strength() -> float:
	return yield_strength
