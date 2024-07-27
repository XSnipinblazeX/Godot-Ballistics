#initially made by Aj8841/Xsnipinblazex
#follows same principles as my unity Ballistic solution
#except I don't have the hit interactions yet
#this so far is just a basic Ballistic trajectory 

#just add to a node change the launch values (spin direction, velocity) and it should work

extends MeshInstance3D # extends any node as long as it doesn't affect the gravity and velocity

var mass = 0.0167 #mass of the object In kg

var Active = false # for future initialization

var iV = 39.294816 # 87.9 mph iV: Initial velocity in m/s
var velocity = Vector3(0, 0, 0) # this is the actual velocity during runtime
var direction = Vector3(0, -0.04, -1) # direction of travel degrees/90
var spin = Vector3(-1252, 1480, 858) # spin rate in rpm (sidespin, backspin, riflespin)

var angDamp = 0.2 # rotational drag Coefficient 
var linDamp = 0.35 # linear drag Coefficient 
var Dia = 0.075 # diameter of object 
var area = 0.01723 # cross sectional area

var Air_density = 1.225 
const c = 1 # a constant for scaling if needed
var rps = 2 * PI / 60 # rpm to radians a second conversion
var GRAV = -9.81 # acceleration of gravity in m/s
var MoI = 0.09  # moment of inertia 
var airRes = 0.5 * Air_density * area #air resistance factor

var raycast
var lastPos = Vector3()

func _ready():
    velocity = iV * direction # fires in direction with velocoty
    spin *= Vector3(-1, 1, -1) # makes spin relative to F5 Sports’ pitchlogic system
    Active = true

    # Get the RayCast node
    raycast = $RayCast
    raycast.enabled = true

func _physics_process(delta):
    if Active:
        lastPos = global_transform.origin
        velocity.y += GRAV * delta * c # accelerate to gravity
        var spinforce = (spin * rps) * (Dia / 2) / (mass * (velocity.length() * 2))  # Get the force of the magnus effect
        var AngDrag = -angDamp * spin * (Dia / 2) 
        var torque = -(Dia / 2) * AngDrag
        if spin.length() < 0:
            torque *= -1
        var angAccel = torque / MoI # angular drag
        spin -= angAccel
        var DF = airRes * velocity * velocity * linDamp #linear drag
        velocity -= DF * delta
        velocity += spinforce * delta

        # Update the position 
        global_transform.origin += velocity * delta


        # hit detection? Idk I'm shitty at gdscript

        # Perform raycast to check for collision behind the ball
        var raycastDir = lastPos - global_transform.origin
        raycast.cast_to = raycastDir.normalized() * raycastDir.length()  # Set the raycast direction
        raycast.force_raycast_update()

        if raycast.is_colliding():
            # Ball will collide with something, so revert back to the last position
            global_transform.origin = lastPos
            velocity = Vector3(0, 0, 0) #stops projectile for now

