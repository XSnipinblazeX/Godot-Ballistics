# Made by Aj8841 @ xsnipinblazex@gmail.com 

# This is a very basic Ballistic trajectory with a *not* working hit detection
# Simulates gravity, drag, and the magnus effect
# This is all I deem necessary for a realistic trajectory for all types of projectiles.
# Magnus effect simulates magnus and possibly spin drift, haven't seen it yet since I'm making this on Godot mobile
# About 4/5 accurate when compared to my references using the F5 Sports Pitchlogic System
# Updated 7/28/2024

extends MeshInstance3D # Extends any node as long as it doesn't affect the gravity and velocity

var mass = 0.0167 # Mass of the object in kg
var Active = false # For future initialization
var iV = 39 # iV: Initial velocity in m/s
var velocity = Vector3(0, 0, 0) # This is the actual velocity during runtime
export (Curve) var deltaVelocity = Curve.new()
var direction = Vector3(0, -0.04, -1) # Direction of travel degrees/90
var spin = Vector3(1252, 1480, -858) # Spin rate in rpm (sidespin +(CW), backspin +(CCW), riflespin +(CW)) *see commit on GitHub for more info

var angDamp = 0.2 # Rotational drag coefficient 
var linDamp = 0.35 # Linear drag coefficient 
var Dia = 0.075 # Diameter of object 
var area = 0.01723 # Cross-sectional area

var Air_density = 1.225 
const c = 1 # A constant for scaling if needed
var rps = 2 * PI / 60 # RPM to radians a second conversion
var GRAV = -9.81 # Acceleration of gravity in m/s
var MoI = 0.09  # Moment of inertia 
var airRes = 0.5 * Air_density * area # Air resistance factor

var lifetime = 10
var timeStep = 0.1


var raycast
var lastPos = global_transform.origin 

func GraphVelocity(initV)
    var lastvelo = initV
    for t in range(0, lifetime / timeStep)
        dt = t * time_step #delta time
        var newVelo = Move(Vector3.ZERO, initV, dt, false, false)
        var deltaVelo = newVelo - lastVelo
        deltaVelocity.add_point(Vector2(dt / lifetime), deltaVelo)
        lastVelo = newVelo 

func _ready():
    velocity = iV * direction # Fires in direction with velocity
    # spin *= Vector3(-1, 1, -1) # Makes spin relative to F5 Sports’ Pitchlogic system
    GraphVelocity(velocity)
    Active = true

    # Get the RayCast node
    raycast = $RayCast
    raycast.enabled = true

func Move(pos, _velocity, delta, returnNewPos, force):
    # Accelerate to gravity
    _velocity.y += GRAV * delta * c 
    
    var drag_force = airRes * _velocity * _velocity * linDamp # Linear drag
    _velocity -= drag_force * delta
    
    var magnus_force = (spin * rps) * (Dia / 2) / (mass * (_velocity.length() * 2))  # Get the force of the magnus effect
    var AngDrag = -angDamp * spin * (Dia / 2) 
    var torque = -(Dia / 2) * AngDrag
    if spin.length() < 0:
        torque *= -1
    var angAccel = torque / MoI # Angular drag
    spin -= angAccel
    _velocity += magnus_force * delta
    
    return _velocity

var currentPos = Vector3()
var nextPos = Vector3()
var current_time = 0
func _physics_process(delta):
    if Active:
        current_time += delta
        velocity = velocityCurve.interpolate(current_time / lifetime) #Move(lastPos, velocity, delta, false, true)
        global_transform.origin += velocity * delta
        currentPos = global_transform.origin
        nextPos = currentPos * Move(currentPos, velocity, delta, true, false) * delta # This should allow for hit detection because this is a frame ahead
        
        currentPos = global_transform.origin
        
        lastPos = currentPos

        # Do hit check here
