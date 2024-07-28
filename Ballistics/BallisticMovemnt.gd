#initially made by Aj8841/Xsnipinblazex
#follows same principles as my unity Ballistic solution
#except I don't have the hit interactions yet
#this so far is just a basic Ballistic trajectory 

#just add to a node change the launch values (spin direction, velocity) and it should work

#this fork is working on custom projectiles 


extends MeshInstance3D # extends any node as long as it doesn't affect the gravity and velocity

var mass = 0.03 #mass of the object In kg
var length = 0.5 # length of the projectile in meters in the FORWARD direction...I put it as an absurb half a meter
var lengthSpinAxis = Vector3(2, 1, 1) #axis the long side is on compared to spin

var Active = false # for future initialization

var iV = 39.294816 # 87.9 mph iV: Initial velocity in m/s
var velocity = Vector3(0, 0, 0) # this is the actual velocity during runtime
var direction = Vector3(0, -0.04, -1) # direction of travel degrees/90
var spin = Vector3(1252, 1480, -858) # spin rate in rpm (sidespin, backspin, riflespin)

var angDamp = 0.2 # rotational drag Coefficient 
var linDamp = 0.35 # linear drag Coefficient 

var maxAngDamp = 0.95 #max rotational drag
var maxLinDamp = 0.8 # max linear drag

var Dia = 0.075 # diameter of object 
var area = 0.01723 # cross sectional area
var maxArea = 0.12 # area of the broad side

var Air_density = 1.225 
const c = 1 # a constant for scaling if needed
var rps = 2 * PI / 60 # rpm to radians a second conversion
var GRAV = -9.81 # acceleration of gravity in m/s
var MoI = 0.09  # moment of inertia 
var maxMOI = 0.5 # moment of inertia of the broadside
var airRes = 0.5 * Air_density #air resistance factor

var raycast
var lastPos = Vector3()

func _ready():
    velocity = iV * direction # fires in direction with velocity     
    Active = true
    # Get the RayCast node
    raycast = $RayCast
    raycast.enabled = true

func _physics_process(delta):
    if Active:
        lastPos = global_transform.origin
        velocity.y += GRAV * delta * c # accelerate to gravity
        var t = sin(abs(spin.length() * delta))
        var currentAngCoef = lerp(angDamp, maxAngDamp, t)
        var currentLinCoef = lerp(linDamp, maxLinDamp, t)
        var forceDiameter = lerp(Dia, length, t) #cycles through the different sides 
        var spinforce = (spin + (forceDiameter * (spin * lengthSpinAxis) * rps)) * (forceDiameter / 2) / (mass * (velocity.length() * 2))  # Get the force of the magnus effect then lopside it with the length
        var AngDrag = -currentAngCoef * spin * (forceDiameter / 2) 
        
        var torque = -(forceDiameter / 2) * AngDrag
        var currentMOI = lerp(MoI, maxMOI, t) # cycles through the different sides
        if spin.length() < 0:
            torque *= -1
        var angAccel = torque / currentMOI # angular drag
        spin -= angAccel
        var currentArea = lerp(area, maxArea, t) # cycles through the different sides
        var DF = airRes * currentArea * velocity * velocity * currentLinCoef #linear drag
        velocity -= DF * delta
        velocity += spinforce * delta

        # Update the position 
        global_transform.origin += velocity * delta


        #hit detection removed because idk how to do itl
