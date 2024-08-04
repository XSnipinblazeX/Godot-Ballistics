#this is the armor code, we calculate effective armor inside this script to hopefully make it simpler and take a load off of the other scripts

extends StaticBody3D

# Property to define the armor plate's penetration resistance
@export var penetration_resistance = [38.10, 38.1, 101.6]
@export var constructiveArmorAngle = [0, 47, 47]
@export var yield_strength = 1.5e9
# Method to check if the node is an armor plate
func is_armor_plate() -> bool:
	return true

# Method to get the penetration resistance
func get_penetration_resistance(theta) -> float:
	
	var armorThickness = 0
	var index = 0
	for armor in penetration_resistance:
		armorThickness += abs(abs(armor / cos(theta)) / cos(constructiveArmorAngle[index])) # effective thickness for all armor plates
		index += 1
	return armorThickness
func get_yield_strength() -> float:
	return yield_strength
