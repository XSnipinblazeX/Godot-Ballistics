#this is the armor code, we calculate effective armor inside this script to hopefully make it simpler and take a load off of the other scripts

extends StaticBody3D

# Property to define the armor plate's penetration resistance
@export var penetration_resistance = [38.10, 38.1, 101.6]
@export var constructiveArmorAngle = [3, -7, -14] # this is x plus the actual ingame rotation of the plate
@export var distanceBetweenPlatesM = [0, 0.3, 0.3] # distance between plates in meters so we can find an exit point or determine if it even hits another plate in the array
@export var PlateDimensions = [Vector2(2, 1), Vector2(2, 1), Vector2(2,1)] #Vector2 array for the height and width of the plate X is how wide, Y is how "tall"
@export var yield_strength = [3.5e8, 3.5e8, 4.5e8]
#default values are for super pershing UFP
#yield strength values:
	# Steel: 3.5e8
	# RHA: 4.5e8
	# Aluminum: 2.4e8
	# Iron: 2.562e8
	# Hardwood: 6.0e7
	# Softwood: 2.0e7
	# Ballistic Glass: 1.2e8
	# Normal Glass: 5.0e7
	# Bone: 1.0e8
	# Human: 3.0e7
	# Plastic: 4.0e7
	# Chobham Armor (estimate since its classified): 8.0e8
	# Ballistic Ceramics: 6.0e8
	# ice cream: 1000



var exitPoint = Vector3.ZERO
@export var damage_control_node = Node
# Method to check if the node is an armor plate
func is_armor_plate() -> bool:
	return true

func fuse_shell(fuseSensitivity, angle) -> bool:
		if randi_range(0, 100) >= randi_range(0, 100000): # about 51 shells out of 100,000 will fail so its extremely uncommon but it exists..this excludes premature detonation
			print("fuse failed")
			return false 
		return fuseSensitivity <= (penetration_resistance[0] / cos(angle))

# Method to get the penetration resistance
func get_penetration_resistance(theta, point) -> float:
	var LocalSpacePoint = point - self.global_transform.origin # s0 we get the local hit point relative to the plate
	print("Local Hit Point: ", LocalSpacePoint)
	var armorThickness = 0
	var index = 0
	var distanceTraveled = 0
	for armor in penetration_resistance:
		var newDist = abs(distanceBetweenPlatesM[index] / cos(theta))
		armorThickness += abs((armor / cos(theta + deg_to_rad(constructiveArmorAngle[index]))))
		if(newDist > distanceBetweenPlatesM[index] * 2.5):
			print("Exited armor array before hitting next plate")
			return armorThickness
		distanceTraveled += newDist
		index += 1
	
	return armorThickness
	print("distance traveled in armor array ", distanceTraveled)
func get_yield_strength() -> float:
	var strength = 0
	var index = 0
	for armor in penetration_resistance:
		strength += yield_strength[index]
		index += 1
	return (strength / yield_strength.size())
