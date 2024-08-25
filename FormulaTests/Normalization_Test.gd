#pseudo code for shell normalization and the effective thickness it faced because of it
# future iterations will account for shell nose shape once I get thisnone figure out


func get_lprot_n (mass, Vn, Llos, In, Ia, L)
    # mass in kg
    # Vn is velocity at vector value (x, y, z)
    # Llos is line of sight thickness at impact angle
    # In is moment of inertia at vector value (x, y, z)
    # Ia is impact angle in radians

    var keD = mass * Vn * Vn * (sin(Ia) * sin(Ia)) #tangential KE numerator
    var KEt = 0.5 * keD # tangential KE 

    var tD = Vn / (Llos / 1000) #time to travel distance in direction at that velocity 

    var sigma = sqrt((2 * KEt) / In) / tD #angular acceleration 
    var tN = In * sigma # torque at vector value
    var wN = tN * tD # angular velocity
    var theta = wN * tD # new angle at Time in rads
    var L_prot = L / cos(theta)
    return L_prot

func whatever()
    var Et = Vector3(get_lprot_n (mass, velocity.x, Llos, I.x, Ia, L), get_lprot_n (mass, velocity.y, Llos, I.y, Ia, L), get_lprot_n (mass, velocity.z, Llos, I.z, Ia, L)) # here we get the effective thicknesses at all directions 
    var relativeThickness = Et.length() #get the linear thickness scalar not vector
