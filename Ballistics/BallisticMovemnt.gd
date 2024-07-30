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

# Non-exported variables
var airRes: float
var lastPos: Vector3 = Vector3.ZERO
var current_time: float = 0.0
var delta_velocity_data: Array = []
var magnus_data: Array = []
var velocity: Vector3
var Active: bool = false

func _ready():
    velocity = iV * direction
    lastPos = global_transform.origin
    Active = false

    var full_path = file_path + ID + ".json"
    
    # Ensure the directory exists
    var dir = DirAccess.open(file_path)
    if not dir.dir_exists(file_path):
        dir.make_dir_recursive(file_path)
    
    # Check if the file exists and load or simulate data
    if not FileAccess.file_exists(full_path):
        simulate_data()
    else:
        if not load_data():
            simulate_data()

func simulate_data():
    print("Simulating data...")
    compute_delta_velocities()
    save_data()

func compute_delta_velocities():
    var current_velocity = velocity
    for t in range(0, int(max_time / time_step)):
        var delta_time = t * time_step
        var previous_velocity = current_velocity
        current_velocity = Move(lastPos, current_velocity, delta_time, false, true)
        
        var delta_velocity = previous_velocity - current_velocity
        velocity = current_velocity 
        
        var magnus_force = Magnus(current_velocity)
        magnus_data.append({
            "time": delta_time,
            "magnus_force": magnus_force
        })
        
        delta_velocity_data.append({
            "time": delta_time,
            "delta_velocity": delta_velocity
        })
    
    velocity = iV * direction
    Active = true
    print("Data simulated and computed.")

func get_delta_velocity_at_time(target_time: float) -> Vector3:
    for data in delta_velocity_data:
        if data["time"] >= target_time:
            return data["delta_velocity"]
    
    return delta_velocity_data[-1]["delta_velocity"] if delta_velocity_data.size() > 0 else Vector3.ZERO

func get_magnus_force_at_time(target_time: float) -> Vector3:
    for data in magnus_data:
        if data["time"] >= target_time:
            return data["magnus_force"]
    
    return magnus_data[-1]["magnus_force"] if magnus_data.size() > 0 else Vector3.ZERO

func Magnus(_velocity: Vector3) -> Vector3:
    var magnus_force = (spin * rps) * (Dia / 2) / (mass * (_velocity.length() * 2))
    return magnus_force 

func Spin(delta: float):
    var angDrag = -angDamp * spin * (Dia / 2)
    var torque = -(Dia / 2) * angDrag
    
    if spin.length() < 0:
        torque *= -1
    
    var angAccel = torque / MoI
    spin -= angAccel * delta

func Move(pos: Vector3, _velocity: Vector3, delta: float, returnNewPos=false, force=false) -> Vector3:
    _velocity.y += GRAV * delta
    
    var drag_force = airRes * _velocity.length_squared() * linDamp
    _velocity -= _velocity.normalized() * drag_force * delta
    
    return _velocity

func _physics_process(delta: float):
    if Active:
        current_time += delta
        
        var delta_velocity_at_time = get_delta_velocity_at_time(current_time)
        var magnus_force_at_time = get_magnus_force_at_time(current_time) * current_time
        
        if delta_velocity_at_time:
            velocity -= delta_velocity_at_time * time_step 
            global_transform.origin += (velocity + magnus_force_at_time) * delta
            lastPos = global_transform.origin
            Spin(delta)
            
            print("Time: ", current_time, " Velocity: ", velocity, " Position: ", global_transform.origin)
            print("Magnus Force at Time ", current_time, ": ", magnus_force_at_time)
        
        if current_time > max_time:
            Active = false

func save_data():
    var full_path = file_path + ID + ".json"
    var file = FileAccess.open(full_path, FileAccess.WRITE)
    
    if file:
        var data = {
            "delta_velocity_data": delta_velocity_data.map(func(d) -> Dictionary:
                return {
                    "time": d["time"],
                    "delta_velocity": {
                        "x": d["delta_velocity"].x,
                        "y": d["delta_velocity"].y,
                        "z": d["delta_velocity"].z
                    }
                }),
            "magnus_data": magnus_data.map(func(m) -> Dictionary:
                return {
                    "time": m["time"],
                    "magnus_force": {
                        "x": m["magnus_force"].x,
                        "y": m["magnus_force"].y,
                        "z": m["magnus_force"].z
                    }
                })
        }
        
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
                magnus_data = []

                for item in data.get("delta_velocity_data", []):
                    delta_velocity_data.append({
                        "time": item["time"],
                        "delta_velocity": Vector3(item["delta_velocity"]["x"], item["delta_velocity"]["y"], item["delta_velocity"]["z"])
                    })
                
                for item in data.get("magnus_data", []):
                    magnus_data.append({
                        "time": item["time"],
                        "magnus_force": Vector3(item["magnus_force"]["x"], item["magnus_force"]["y"], item["magnus_force"]["z"])
                    })
                
                # Debug output
                print("Loaded Delta Velocity Data: ", delta_velocity_data)
                print("Loaded Magnus Data: ", magnus_data)
                
                file.close()
                return true
            else:
                print("Failed to parse JSON data. Error: ", result)
        else:
            print("Failed to open file for reading.")
    else:
        print("File does not exist.")
    
    return false
