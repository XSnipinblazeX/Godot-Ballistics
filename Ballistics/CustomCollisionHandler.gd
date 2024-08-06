#This is the custom collision handling for the ballistic simulation
#this contains all *possible* outcomes of a projectile interaction with another solid material
#the main script will cache the ballistic data of the projecile and this script will read that to determine an outcome



extends Node

func armor_interation(mass, diameter, speed, yield_strength, thickness, angle) -> Dictionary:
		var p = false
		var r = false
		var s = false
		var KER = 1
		var area = PI * ((diameter / 2) * (diameter / 2))
		var result = {
			"penetration": p,
			"ricochet": r,
			"stopped": s,
			"KER": KER
		}
		
		var Vn = speed * cos(angle)
		var eKn = 0.5 * mass * Vn * Vn
		print("Normal KE ", eKn)
		var Ep = thickness * area * yield_strength
		print("Required KE divided by 100 ", Ep)
		result.p = eKn > Ep
		print("KE penetrate? ", result.p)
		result.s = (eKn / (Ep / 100)) >= 0.2 and not result.p
		result.r = (eKn / (Ep / 100)) < 0.2 and not result.s
		print("KE ricochet? ", result.r)
		print("stopped? ", result.s)
		result.KER = (eKn / (Ep / 100))
		print("KER ", result.KER)
		return result

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func handle_collision(object, collider, velocity, spin, _normal, penetration, hitPos) -> Dictionary:
	var penetrated = false
	var depth = 0
	var ricochet = false
	var stopped = false
	var active = false
	var collision_response = {
		"velocity": velocity,
		"spin": spin,
		"active": active
	}
	var exitVector = velocity.normalized()
	#dummy thing
	var theta = acos(abs(velocity.normalized().dot(_normal)))
	print("Impact Angle (deg): ", rad_to_deg(theta))
	var armorT = collider.get_penetration_resistance(theta)
	print("Encountered: ", armorT, "mm")
	depth = (penetration / armorT)
	print("penetrated ", depth, " percent of armor")
	var armorResponse = armor_interation(object.mass, object.Dia, velocity.length(), collider.get_yield_strength(), collider.get_penetration_resistance(0), theta)
	
	if penetration >= (armorT * randf_range(0.6, 0.7)) or armorResponse.KER > 0.5:
			print("spalled")
	
	if armorResponse.p or penetration >= (armorT * randf_range(0.7, 1.0)): #did the shell penetrate to demarre or kinetic energy
		collision_response.velocity = velocity * abs(1 - (armorT / penetration))
		collision_response.spin = Vector3.ZERO
		print("penetrated")
		var exitPos = hitPos + (velocity.normalized() * (armorT / 1000))
		collision_response.active = true
		collider.damage_control_node.apply_fragment_damage(exitPos, exitVector, 45, 0.5 * object.mass * velocity.length() * velocity.length(), armorT * 3500)
		return collision_response
	if armorResponse.r and depth < 0.45:
		print("ricochet")
		# Example logic for bouncing off a surface
		# Calculate the reflection of the velocity using the collision normal
		var reflection = velocity.bounce(_normal)
	
		# Apply some coefficient of restitution (bounciness)
		var restitution = 0.3  # This can be adjusted
		collision_response.velocity = reflection * restitution
		velocity = collision_response.velocity
		var tangential_velocity = velocity - velocity.dot(_normal) * _normal
		var friction_coefficient = 0.1  # This can be adjusted
		var spin_change = tangential_velocity * friction_coefficient * (1 - (_normal.dot(velocity.normalized())))
	
		# Apply the spin change
		collision_response.spin += spin_change
		collision_response.active = true
		# Update spin (simple inversion for now, can be more complex based on the surface)  # Invert spin for simplicity, reduce spin
		return collision_response
	else:
		print("stopped")
		collision_response.velocity = Vector3.ZERO
		collision_response.spin = Vector3.ZERO
		collision_response.active = false
		return collision_response
	return collision_response
