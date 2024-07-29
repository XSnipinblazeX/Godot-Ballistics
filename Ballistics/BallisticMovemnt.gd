# Made by Aj8841 @ xsnipinblazex@gmail.com 

# This is a very basic Ballistic trajectory with a *not* working hit detection
# Simulates gravity, drag, and the magnus effect
# This is all I deem necessary for a realistic trajectory for all types of projectiles.
# Magnus effect simulates magnus and possibly spin drift, haven't seen it yet since I'm making this on Godot mobile
# About 4/5 accurate when compared to my references using the F5 Sports Pitchlogic System
# Updated 7/28/2024
# Updated 7/29/24 10:37AM PST
# Updated 7/29/24 10:49AM PST

extends MeshInstance3D

var mass = 0.0167
var Active = false
var iV = 39
var initial_velocity = Vector3()
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

var lastPos = global_transform.origin
var current_time = 0.0  # Initialize current time

# Pre-calculated change in velocity data
var delta_velocity_data = []
var max_time = 5.0
var time_step = 0.1

func _ready():
    initial_velocity = iV * direction
    Active = true
    compute_delta_velocities()

func compute_delta_velocities():
    var current_velocity = initial_velocity
    for t in range(0, max_time / time_step):
        var delta_time = t * time_step
        var previous_velocity = current_velocity
        current_velocity = Move(lastPos, current_velocity, time_step)
        
        # Calculate change in velocity (stored as negative for forces adding to velocity)
        var delta_velocity = previous_velocity - current_velocity
        delta_velocity_data.append({
            "time": delta_time,
            "delta_velocity": delta_velocity
        })

func get_delta_velocity_at_time(target_time):
    for data in delta_velocity_data:
        if data["time"] >= target_time:
            return data["delta_velocity"]
    return null

func Move(pos, _velocity, delta):
    _velocity.y += GRAV * delta * c
    var drag_force = airRes * _velocity * _velocity * linDamp
    _velocity -= drag_force * delta

    var magnus_force = (spin * rps) * (Dia / 2) / (mass * (_velocity.length() * 2))
    var AngDrag = -angDamp * spin * (Dia / 2)
    var torque = -(Dia / 2) * AngDrag
    if spin.length() < 0:
        torque *= -1
    var angAccel = torque / MoI
    spin -= angAccel
    _velocity += magnus_force * delta  # Update velocity with Magnus force
    
    return _velocity

func _physics_process(delta):
    if Active:
        current_time += delta  # Increment current time by delta
        var delta_velocity_at_time = get_delta_velocity_at_time(current_time)
        
        if delta_velocity_at_time:
            # Update the velocity by subtracting the change in velocity
            
            global_transform.origin += (initial_velocity - delta_velocity_at_time) * delta
            lastPos = global_transform.origin
