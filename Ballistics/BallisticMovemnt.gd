extends MeshInstance3D

var mass = 0.0167
var Active = false
var iV = 35.274 
var velocity = Vector3()
var direction = Vector3(0, -0.04, -1)
var spin = Vector3(1252, 1480, -858)
var angDamp = 0.2
var linDamp = 0.35
var Dia = 0.075
var area = 0.01723
var Air_density = 1.225
const c = 1
var rps = 2 * PI / 60
var GRAV = -9.81
var MoI = 0.09
var airRes = 0.5 * Air_density * area

var lastPos = Vector3.ZERO
var current_time = 0.0  # Initialize current time

# Pre-calculated change in velocity and Magnus data
var delta_velocity_data = []
var magnus_data = []
var max_time = 5.0
var time_step = 0.1

func _ready():
    velocity = iV * direction
    lastPos = global_transform.origin
    Active = false
    compute_delta_velocities()

func compute_delta_velocities():
    var current_velocity = velocity
    for t in range(0, int(max_time / time_step)):
        var delta_time = t * time_step
        var previous_velocity = current_velocity
        current_velocity = Move(lastPos, current_velocity, delta_time, false, true)
        
        # Calculate change in velocity (negative because we want to subtract from initial velocity)
        var delta_velocity = previous_velocity - current_velocity
        velocity = current_velocity 
        
        # Calculate Magnus force at this time
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

func get_delta_velocity_at_time(target_time):
    for data in delta_velocity_data:
        if data["time"] >= target_time:
            return data["delta_velocity"]
    return delta_velocity_data[-1]["delta_velocity"] if delta_velocity_data.size() > 0 else Vector3.ZERO

func get_magnus_force_at_time(target_time):
    for data in magnus_data:
        if data["time"] >= target_time:
            return data["magnus_force"]
    return magnus_data[-1]["magnus_force"] if magnus_data.size() > 0 else Vector3.ZERO

func Magnus(_velocity):
    var magnus_force = (spin * rps) * (Dia / 2) / (mass * (_velocity.length() * 2))
    return magnus_force 

func Spin(delta):
    var angDrag = -angDamp * spin * (Dia / 2)
    var torque = -(Dia / 2) * angDrag
    if spin.length() < 0:
        torque *= -1
    var angAccel = torque / MoI
    spin -= angAccel * delta

func Move(pos, _velocity, delta, returnNewPos=false, force=false):
    _velocity.y += GRAV * delta * c
    
    var drag_force = airRes * _velocity.length_squared() * linDamp
    _velocity -= _velocity.normalized() * drag_force * delta
    
    return _velocity

func _physics_process(delta):
    if Active:
        current_time += delta
        
        # Get delta velocity change for current time
        var delta_velocity_at_time = get_delta_velocity_at_time(current_time)
        var magnus_force_at_time = get_magnus_force_at_time(current_time) * current_time
        if delta_velocity_at_time:
            # Update the velocity based on the change
            velocity -= delta_velocity_at_time * time_step 
            
            # Move the object
            global_transform.origin += (velocity + magnus_force_at_time) * delta
            lastPos = global_transform.origin
            Spin(delta)
            
            # Debug output
            print("Time: ", current_time, " Velocity: ", velocity, " Position: ", global_transform.origin)
            
            # Optionally: Print Magnus force for debugging
            
            print("Magnus Force at Time ", current_time, ": ", magnus_force_at_time)
        
        # Optional: Stop simulation after the lifetime ends
        if current_time > max_time:
            Active = false
