extends MeshInstance3D

# Exported variables for the Inspector
@export var ID: String
@export var mass: float = 0.0167
@export var iV: float = 35.274
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
@export var max_rpm: float = 4000

# Non-exported variables
var airRes: float
var lastPos: Vector3 = Vector3.ZERO
var current_time: float = 0.0
var delta_velocity_data: Array = []
var cached_magnus_forces: Dictionary = {}
var velocity: Vector3
var Active: bool = false

func _ready():
	print("start scene")
	velocity = iV * direction
	lastPos = global_transform.origin
	Active = false

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

	# Generate cached Magnus forces
	cache_magnus_forces()

func simulate_data():
	print("Simulating data...")
	compute_delta_velocities()
	save_data()

func compute_delta_velocities():
	var current_velocity = velocity
	for t in range(0, int(max_time / time_step) + 1):
		var delta_time = t * time_step
		var previous_velocity = current_velocity
		current_velocity = Move(lastPos, current_velocity, delta_time, false, true)
		
		var delta_velocity = previous_velocity - current_velocity
		velocity = current_velocity 
		
		delta_velocity_data.append({
			"time": delta_time,
			"delta_velocity": delta_velocity
		})
	
	velocity = iV * direction
	Active = true
	print("Data simulated and computed.")

func cache_magnus_forces():
	for rpm in range(-max_rpm, max_rpm, int(max_rpm / 50)):  # Adjust step size as needed
		var magnitude = rpm
		var magnus_force = (spin * (rpm / 60.0)) * (Dia / 2) / (mass * (velocity.length() * 2))
		cached_magnus_forces[rpm] = magnus_force
		print("Magnus at rpm ", cached_magnus_forces[rpm], " ", rpm)

func get_current_rpm() -> float:
	return spin.length() * rps

func get_magnus_force(rpm: int) -> Vector3:
	var rpm_clamped = clamp(rpm, -max_rpm, max_rpm)
	var keys = cached_magnus_forces.keys()
	keys.sort()  # Sort keys
	var lower_rpm = keys[0]
	var upper_rpm = keys[0]
	
	for key in keys:
		if key <= rpm_clamped:
			lower_rpm = key
		if key >= rpm_clamped:
			upper_rpm = key
			break
	
	var lower_force = cached_magnus_forces[lower_rpm]
	var upper_force = cached_magnus_forces[upper_rpm]
	
	if lower_rpm == upper_rpm:
		return lower_force
	
	var factor = float(rpm_clamped - lower_rpm) / float(upper_rpm - lower_rpm)
	return Vector3(
		lower_force.x + factor * (upper_force.x - lower_force.x),
		lower_force.y + factor * (upper_force.y - lower_force.y),
		lower_force.z + factor * (upper_force.z - lower_force.z)
	)

func Spin(delta: float):
	var angDrag = -angDamp * spin * (Dia / 2)
	var torque = -(Dia / 2) * angDrag
	
	if spin.length() < 0:
		torque *= -1
	
	var angAccel = torque / MoI
	spin -= angAccel * delta
	print("new spin vector ", spin)

func Move(pos: Vector3, _velocity: Vector3, delta: float, returnNewPos=false, force=false) -> Vector3:
	_velocity.y += GRAV * delta
	
	var drag_force = airRes * _velocity.length_squared() * linDamp
	_velocity -= _velocity.normalized() * drag_force * delta
	
	return _velocity

func get_delta_velocity_at_time(target_time: float) -> Vector3:
	for data in delta_velocity_data:
		if data["time"] >= target_time:
			return data["delta_velocity"]
	
	return delta_velocity_data[-1]["delta_velocity"] if delta_velocity_data.size() > 0 else Vector3.ZERO

func _physics_process(delta: float):
	if Active:
		current_time += delta
		
		var delta_velocity_at_time = get_delta_velocity_at_time(current_time)
		var rpm = get_current_rpm()
		var magnus_force_at_rpm = get_magnus_force(rpm)# Use cached Magnus force
		
		if delta_velocity_at_time:
			velocity -= delta_velocity_at_time * time_step 
			global_transform.origin += velocity * delta
            global_transform.origin += magnus_force_at_rpm / (2 * velocity.length()) * delta
			lastPos = global_transform.origin
			Spin(delta)
			
			print("Magnus Force at RPM ", rpm / rps, ": ", magnus_force_at_rpm )
		
		if current_time > max_time:
			Active = false
func save_data():
	var full_path = file_path + ID + ".json"
	var file = FileAccess.open(full_path, FileAccess.WRITE)
	
	if file:
		var magnus_forces_data = []
		for key in cached_magnus_forces.keys():
			magnus_forces_data.append({
				"rpm": key,
				"magnus_force": {
					"x": cached_magnus_forces[key].x,
					"y": cached_magnus_forces[key].y,
					"z": cached_magnus_forces[key].z
				}
			})
		
		var data = {
			"delta_velocity_data": [],
			"cached_magnus_forces": magnus_forces_data
		}
		
		for d in delta_velocity_data:
			data["delta_velocity_data"].append({
				"time": d["time"],
				"delta_velocity": {
					"x": d["delta_velocity"].x,
					"y": d["delta_velocity"].y,
					"z": d["delta_velocity"].z
				}
			})

		var json = JSON.new()  # Create a new JSON instance
		var json_data = json.stringify(data)  # Convert data to JSON string
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
			var json = JSON.new()  # Create a new JSON instance
			var result = json.parse(json_data)  # Parse JSON data
			
			if result == OK:
				var data = json.get_data()  # Get the parsed data
				delta_velocity_data = []
				cached_magnus_forces = {}

				# Debug output to check loaded JSON data
				print("Parsed JSON Data: ", data)
				
				# Convert delta_velocity_data
				for item in data.get("delta_velocity_data", []):
					delta_velocity_data.append({
						"time": item["time"],
						"delta_velocity": Vector3(item["delta_velocity"]["x"], item["delta_velocity"]["y"], item["delta_velocity"]["z"])
					})
				
				# Convert cached_magnus_forces
				for item in data.get("cached_magnus_forces", []):
					cached_magnus_forces[item["rpm"]] = Vector3(item["magnus_force"]["x"], item["magnus_force"]["y"], item["magnus_force"]["z"])
				
				# Debug output to verify conversion
				print("Loaded Delta Velocity Data: ", delta_velocity_data)
				print("Loaded Magnus Forces: ", cached_magnus_forces)
				
				file.close()
				Active = true  # Set Active to true after loading data
				return true
			else:
				print("Failed to parse JSON data. Error: ", result)
		else:
			print("Failed to open file for reading.")
	else:
		print("File does not exist.")
	
	return false
