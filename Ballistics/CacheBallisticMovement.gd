# Made by Aj8841 @ xsnipinblazex@gmail.com 

# This is a very basic Ballistic trajectory with a *not* working hit detection
# Simulates gravity, drag, and the magnus effect
# This is all I deem necessary for a realistic trajectory for all types of projectiles.
# Magnus effect simulates magnus and possibly spin drift, haven't seen it yet since I'm making this on Godot mobile
# About 4/5 accurate when compared to my references using the F5 Sports Pitchlogic System
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

# Non-exported variables
var airRes: float
var lastPos: Vector3 = Vector3.ZERO
var current_time: float = 0.0
var velocity_data: Array = []
var spin_data: Array = []
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
	_velocity -= _velocity.normalized() * drag_force * delta
	
	var magnus_force = (spin * rps) * (Dia / 2) / (mass * (_velocity.length() * 2))
	_velocity += magnus_force * delta
	
	return _velocity

func get_delta_velocity_at_time(target_time: float) -> Vector3:
	for data in velocity_data:
		if data["time"] >= target_time:
			return data["delta_velocity"]
	
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

func _physics_process(delta: float):
	if Active:
		current_time += delta
		
		var delta_velocity_at_time = get_delta_velocity_at_time(current_time)
		var delta_spin_at_time = get_delta_spin_at_time(current_time)
		
		if delta_velocity_at_time:
			velocity -= delta_velocity_at_time * time_step 
			global_transform.origin += velocity * delta
			lastPos = global_transform.origin
			
			if(spin.x < 0):
				spin.x += delta_spin_at_time * time_step
			else:
				spin.x += delta_spin_at_time * time_step
			if(spin.y < 0):
				spin.y += delta_spin_at_time * time_step
			else:
				spin.y += delta_spin_at_time * time_step
			if(spin.z < 0):
				spin.z += delta_spin_at_time * time_step
			else:
				spin.z += delta_spin_at_time * time_step
			#Spin(delta)
		
		if current_time > max_time:
			Active = false

func save_data():
	var full_path = file_path + ID + ".json"
	var file = FileAccess.open(full_path, FileAccess.WRITE)
	
	if file:
		var data = {
			"velocity_data": velocity_data,
			"spin_data": spin_data
		}
		
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

				print("Parsed JSON Data: ", data)
				
				for item in velocity_data:
					item["velocity"] = Vector3(item["velocity"]["x"], item["velocity"]["y"], item["velocity"]["z"])
					item["delta_velocity"] = Vector3(item["delta_velocity"]["x"], item["delta_velocity"]["y"], item["delta_velocity"]["z"])
				
				for item in spin_data:
					item["spin"] = Vector3(item["spin"]["x"], item["spin"]["y"], item["spin"]["z"])
					item["delta_spin"] = Vector3(item["delta_spin"]["x"], item["delta_spin"]["y"], item["delta_spin"]["z"])
				
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