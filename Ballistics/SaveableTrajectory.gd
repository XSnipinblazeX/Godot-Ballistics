# Made by Aj8841 @ xsnipinblazex@gmail.com 

# This is a very basic Ballistic trajectory with a *kind of* working hit detection
# Simulates gravity, drag, and the magnus effect
# This is all I deem necessary for a realistic trajectory for all types of projectiles.
# Magnus effect simulates magnus and possibly spin drift, haven't seen it yet since I'm making this on Godot mobile
# About 4/5 accurate when compared to my references using the F5 Sports Pitchlogic System
#saves change in motion to json to reduce math workload
# Updated 7/30/2024




extends MeshInstance3D

# Exported variables for the Inspector
@export var ID: String
@export var mass: float = 0.0167
@export var iV: float = 39.0
@export var direction: Vector3 = Vector3(0, -0.04, -1)
@export var spin: Vector3 = Vector3(1252, 1480, -858)
@export var angDamp: float = 0.2
@export var linDamp: float = 0.35
@export var Dia: float = 0.075
@export var area: float = 0.01723
@export var Air_density: float = 1.225
@export var rps: float = 2 * PI / 60
@export var GRAV: float = -9.81
@export var MoI: float = 0.09
@export var max_time: float = 5.0
@export var time_step: float = 0.1
@export var file_path: String = "user://cached_data/"  # Editable path in Inspector

@export var tnt: float = 100.0 #mass of tnt in the shell if its aphe
@export var capped = false #does the shell have a ballistic cap?




# Non-exported variables
var airRes: float
var lastPos: Vector3 = Vector3.ZERO
var current_time: float = 0.0
var velocity_data: Array = []
var spin_data: Array = []
var penetration_data: Array = []
var velocity: Vector3
var Active: bool = false
@export var raycast: RayCast3D  # Add a reference to the RayCast node
@export var collision_handler: Node


var compute_thread: Thread = Thread.new()



func _get_penetration_over_speed(velocity: float):
	var cal = Dia * 1000
	var kfbr = 1900
	tnt = (tnt / mass) * 100
	var kf_apcbc = 0.9
	if capped:
		kf_apcbc = 1
	var knap = 0.75
	
	if tnt < 0.65:
		knap = 1
	elif tnt < 1.6:
		knap = 1 + (tnt - 0.65) * (0.93 - 1) / (1.6 - 0.65)
	elif tnt < 2:
		knap = 0.93 + (tnt - 1.6) * (0.9 - 0.93) / (2 - 1.6)
	elif tnt < 3:
		knap = 0.9 + (tnt - 2) * (0.85 - 0.9) / (3 - 2)
	elif tnt < 4:
		knap = 0.85 + (tnt - 3) * (0.75 - 0.85) / (4 - 3)
	
	var result = (((pow(velocity, 1.43) * pow(mass, 0.71)) / (pow(kfbr, 1.43) * pow(cal / 100, 1.07))) * 100 * knap * kf_apcbc)
	return result


func _ready():
	print("start scene")
	velocity = iV * direction
	lastPos = global_transform.origin
	Active = false
	airRes = 0.5 * Air_density * area
	#set up collision handler
	# Initialize the CollisionHandler
	
	#add_child(collision_handler)


	var full_path = file_path + ID + ".json"
	print("Initializing JSON")
	
	# Ensure the directory exists
	var dir = DirAccess.open(file_path)
	if not dir.dir_exists(file_path):
		print("Making new directory")
		dir.make_dir_recursive(file_path)
	
	# Check if the file exists and load or simulate data
	if not FileAccess.file_exists(full_path):
		simulate_data()
	else:
		if not load_data():
			simulate_data()

func simulate_data():
	print("Simulating data...")
	compute_data()
	save_data()

func compute_data():
	var current_velocity = velocity
	var current_spin = spin
	for t in range(0, int(max_time / time_step) + 1):
		var delta_time = t * time_step
		var previous_velocity = current_velocity
		var previous_spin = current_spin
		current_velocity = Move(lastPos, current_velocity, delta_time, false, true)
		
		var delta_velocity = previous_velocity - current_velocity
		velocity = current_velocity

		var angDrag = -angDamp * spin * (Dia / 2)
		var torque = -(Dia / 2) * angDrag
		if spin.length() < 0:
			torque *= -1
		var angAccel = torque / MoI
		current_spin -= angAccel * delta_time
		
		var delta_spin = previous_spin - current_spin
		spin = current_spin
		
		velocity_data.append({
			"time": delta_time,
			"velocity": velocity,
			"delta_velocity": delta_velocity
		})
		
		spin_data.append({
			"time": delta_time,
			"spin": spin,
			"delta_spin": delta_spin
		})
	velocity = iV * direction
	Active = true
	print("Data simulated and computed.")

func Move(_pos: Vector3, _velocity: Vector3, delta: float, _returnNewPos=false, _force=false) -> Vector3:
	_velocity.y += GRAV * delta
	
	var drag_force = airRes * _velocity.length_squared() * linDamp
	_velocity -= _velocity.normalized() * drag_force * delta * delta * time_step
	
	var magnus_force = (spin * rps) * (Dia / 2) / (mass * (_velocity.length() * 2))
	_velocity += magnus_force * delta
	
	return _velocity

func get_pen_at_speed(speed):
	return _get_penetration_over_speed(speed)
	
func closest(my_number:int, my_array:Array)->int:
	# Initialize
	var closest_num:int
	var closest_delta:int = 0
	var temp_delta:int = 0
	# Loop through entire array
	for i in range(my_array.size()):
		if my_array[i] == my_number: return my_array[i] # exact match found!
		temp_delta = int(abs(my_array[i]-my_number))
		if closest_delta == 0 or temp_delta < closest_delta:
			closest_num = my_array[i]
		closest_delta = temp_delta
	# Return closest number found
	return closest_num


func get_delta_velocity_at_time(target_time: float) -> Vector3:
	for data in velocity_data:
		if data["time"] >= target_time:
			return data["delta_velocity"]  # This should be a Vector3 as constructed in compute_data()
	
	return velocity_data[-1]["delta_velocity"] if velocity_data.size() > 0 else Vector3.ZERO

func get_delta_spin_at_time(target_time: float) -> Vector3:
	for data in spin_data:
		if data["time"] >= target_time:
			return data["delta_spin"]
	
	return spin_data[-1]["delta_spin"] if spin_data.size() > 0 else Vector3.ZERO

func Spin(delta: float):
	var angDrag = -angDamp * spin * (Dia / 2)
	var torque = -(Dia / 2) * angDrag
	
	if spin.length() < 0:
		torque *= -1
	
	var angAccel = torque / MoI
	spin -= angAccel * delta
	print("new spin vector ", spin)

var lastHitTime = 0
var isColliding = false
func _physics_process(delta: float):
	var space_state = get_world_3d().direct_space_state
	var predicted_position = global_transform.origin + velocity * delta
	var origin = global_transform.origin
	var end = predicted_position
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [self]
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	if result and not isColliding:
		isColliding = true
		print(get_pen_at_speed(velocity.length()), "mm at ", velocity.length(), " m/s")
		print("hit")
		Active = false
		lastHitTime = current_time
		global_transform.origin = result.position
		var collision_response = collision_handler.handle_collision(self, result.collider, velocity, spin, result.normal, get_pen_at_speed(velocity.length()))
		print(collision_response)
		velocity = Vector3.ZERO
		velocity = collision_response["velocity"]
		spin -= collision_response["spin"]
		spin *= 0.1
		Active = collision_response.active
	if Active:
		isColliding = false
		
		
		current_time += delta
		
		# Predict the next position

			#Active = false #stop the simulation for now
		# Update RayCast to check from current to predicted position
		##raycast.cast_to = predicted_position - global_transform.origin
		#raycast.force_raycast_update()


	   ###    print("Hit detected with: ", collider.name)
		
		
		var delta_velocity_at_time = get_delta_velocity_at_time(current_time- lastHitTime)
		var delta_spin_at_time = get_delta_spin_at_time(current_time - lastHitTime)
		
		if delta_velocity_at_time:
			velocity -= delta_velocity_at_time * time_step
			global_transform.origin += velocity * delta
			lastPos = global_transform.origin
			
			var newSpinX = spin.x
			var newSpinY = spin.y
			var newSpinZ = spin.z
			if(newSpinX < 0):
				newSpinX += delta_spin_at_time.x * time_step
			else:
				newSpinX -= delta_spin_at_time.x * time_step
			if(newSpinY < 0):
				newSpinY += delta_spin_at_time.y * time_step
			else:
				newSpinY -= delta_spin_at_time.y * time_step
			if(newSpinZ < 0):
				newSpinZ += delta_spin_at_time.z * time_step
			else:
				newSpinZ -= delta_spin_at_time.z * time_step
			spin = Vector3(newSpinX, newSpinY, newSpinZ)
			#Spin(delta)

		


		if current_time > max_time:
			Active = false

func save_data():
	var full_path = file_path + ID + ".json"
	var file = FileAccess.open(full_path, FileAccess.WRITE)

	if file:
		var data = {
			"velocity_data": [],
			"spin_data": []
		}
		
		# Prepare velocity data for saving
		for v in velocity_data:
			data["velocity_data"].append({
				"time": v["time"],
				"velocity": {
					"x": v["velocity"].x,
					"y": v["velocity"].y,
					"z": v["velocity"].z
				},
				"delta_velocity": {
					"x": v["delta_velocity"].x,
					"y": v["delta_velocity"].y,
					"z": v["delta_velocity"].z
				}
			})
		
		# Prepare spin data for saving
		for s in spin_data:
			data["spin_data"].append({
				"time": s["time"],
				"spin": {
					"x": s["spin"].x,
					"y": s["spin"].y,
					"z": s["spin"].z
				},
				"delta_spin": {
					"x": s["delta_spin"].x,
					"y": s["delta_spin"].y,
					"z": s["delta_spin"].z
				}
			})

		var json = JSON.new()
		var json_data = json.stringify(data)
		file.store_string(json_data)
		file.close()
		print("Data saved successfully.")
	else:
		print("Failed to open file for writing.")


func load_data() -> bool:
	var full_path = file_path + ID + ".json"
	
	if FileAccess.file_exists(full_path):
		var file = FileAccess.open(full_path, FileAccess.READ)
		
		if file:
			var json_data = file.get_as_text()
			var json = JSON.new()
			var result = json.parse(json_data)
			
			if result == OK:
				var data = json.get_data()
				velocity_data = data.get("velocity_data", [])
				spin_data = data.get("spin_data", [])
				
				print("Parsed JSON Data: ")
				
				for item in velocity_data:
					# Ensure this part converts the dictionary values to Vector3 correctly
					item["velocity"] = Vector3(item["velocity"].x, item["velocity"].y, item["velocity"].z)
					item["delta_velocity"] = Vector3(item["delta_velocity"].x, item["delta_velocity"].y, item["delta_velocity"].z)
				
				for item in spin_data:
					item["spin"] = Vector3(item["spin"].x, item["spin"].y, item["spin"].z)
					item["delta_spin"] = Vector3(item["delta_spin"].x, item["delta_spin"].y, item["delta_spin"].z)
				
				print("Loaded Velocity Data: ", velocity_data)
				print("Loaded Spin Data: ", spin_data)
				
				file.close()
				Active = true
				return true
			else:
				print("Failed to parse JSON data. Error: ", result)
		else:
			print("Failed to open file for reading.")
	else:
		print("File does not exist.")
	
	return false
