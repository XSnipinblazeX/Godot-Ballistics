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
		#print("Normal KE ", eKn)
		var Ep = thickness * area * yield_strength
		#print("Required KE divided by 100 ", Ep)
		result.p = eKn >= ((Ep / 100) * 0.85)
		#print("KE penetrate? ", result.p)
		result.s = (eKn / (Ep / 100)) >= 0.2 and not result.p
		result.r = (eKn / (Ep / 100)) < 0.2 and not result.s
		#print("KE ricochet? ", result.r)
		#print("stopped? ", result.s)
		result.KER = (eKn / (Ep / 100))
		#print("KER ", result.KER)
		return result

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _explode_at_pos(pos, vehicle, shell, shellDir, velocity):
	var angle = (85 / (velocity.length() / 1000)) / 2
	print("APHE fragment angle: ", angle, " degrees")
	vehicle.damage_control_node.apply_fragment_damage(pos, shellDir, angle, shell.tnt, shell.tnt * 3500)
	vehicle.damage_control_node.apply_explosion_damage(pos, shell.tnt)
	shell.queue_free()

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
	
	
	var theta = acos(abs(velocity.normalized().dot(_normal)))
	var fused = collider.fuse_shell(object.fuseSensitivity, theta)
	print("Shell fused: ", fused)
	print("Impact Angle (deg): ", rad_to_deg(theta))
	var armorT = collider.get_penetration_resistance(theta, hitPos)
	print("Encountered: ", armorT, "mm")
	depth = (penetration / armorT)
	print("penetrated ", depth, " percent of armor")
	var armorResponse = armor_interation(object.mass, object.Dia, velocity.length(), collider.get_yield_strength(), collider.get_penetration_resistance(0, hitPos), theta)
	
	if penetration >= (armorT * randf_range(0.6, 0.7)) or armorResponse.KER > 0.5:
			print("spalled")
			#did it get stuck? if the shell penetrated more than 80% of armor then the fuse will not have any chance of premature detonation
			if depth < 0.8:
				#now theres a chance of premature detonation 
				if randi_range(0, 38) >= randi_range(0, 10000):
					print("shell prematurely detonated") #2 in ten thousand or something like this. 
				if depth < 0.5: #okay we can send fragments  backwards
					_explode_at_pos(hitPos, collider, object, -velocity.normalized(), -velocity)
					#invert the velocity for the explosion fragments
				elif depth >= 0.5:
					#penetrated more than halfway, explosion will not really do anything
					return collision_response
			if fused:
				print("shell exploded correctly")
				var pos = hitPos + (velocity.normalized() * object.fuseDistanceDelay)
				_explode_at_pos(pos, collider, object, velocity.normalized(), velocity)
			var exitPos = hitPos + (velocity.normalized() * (armorT / 1000))
			collider.damage_control_node.apply_fragment_damage(exitPos, exitVector, 45, 0.5 * object.mass * velocity.length() * velocity.length(), armorT * 3500)
			
			if armorResponse.p or penetration >= (armorT * randf_range(0.7, 1.0)): #did the shell penetrate to demarre or kinetic energy
				collision_response.velocity = velocity * abs(1 - (armorT / penetration))
				collision_response.spin = Vector3.ZERO
				print("penetrated")
		
			collision_response.active = true
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
		object.queue_free() #remove the object from scene
	return collision_response
