#this is the armor code, we calculate effective armor inside this script to hopefully make it simpler and take a load off of the other scripts

#now takes into account spaced armor. The constructive angle is relative to the world space angle of the plate

#default values are t26e4(WOT) or t26e1-1(WT) super pershing UFP 

extends StaticBody3D

# Property to define the armor plate's penetration resistance
@export var penetration_resistance = [38.10, 38.1, 101.6]
@export var constructiveArmorAngle = [3, -7, -14] # this is x plus the actual ingame rotation of the plate
@export var distanceBetweenPlatesM = [0, 0.3, 0.3] # distance between plates in meters so we can find an exit point or determine if it even hits another plate in the array
@export var yield_strength = 1.5e9
var exitPoint = Vector3.ZERO
@export var damage_control_node = Node
# Method to check if the node is an armor plate
func is_armor_plate() -> bool:
	return true

# Method to get the penetration resistance
func get_penetration_resistance(theta) -> float:
	
	var armorThickness = 0
	var index = 0
	var distanceTraveled = 0
	for armor in penetration_resistance:
		var newDist = abs(distanceBetweenPlatesM[index] / cos(theta))
		armorThickness += abs((armor / cos(theta + deg_to_rad(constructiveArmorAngle[index]))))
		if(newDist > distanceBetweenPlatesM[index] * 2.5):
			print("didnt hit other plates")
			return armorThickness
		distanceTraveled += newDist
		index += 1
	
	return armorThickness
	print("distance traveled in armor array ", distanceTraveled)
func get_yield_strength() -> float:
	return yield_strength
