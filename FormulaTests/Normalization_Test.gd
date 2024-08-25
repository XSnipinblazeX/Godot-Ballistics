#pseudo code for shell normalization and the effective thickness it faced because of it
# future iterations will account for shell nose shape once I get thisnone figure out


func get_lprot_sharp (mass, Vn, Llos, In, Ia, L) (not capped)
    # mass in kg
    # Vn is velocity at vector value (x, y, z)
    # Llos is line of sight thickness at impact angle
    # In is moment of inertia at vector value (x, y, z)
    # Ia is impact angle in radians
    Vn = abs(Vn)+

    var keD = mass * Vn * Vn * (sin(Ia) * sin(Ia)) #tangential KE numerator
    var KEt = 0.5 * keD # tangential KE 

    var tD = (1 / Vn) * (Llos / 1000) #time to travel distance in direction at that velocity 

    var sigma = sqrt((2 * KEt) / In) / tD #angular acceleration 
    var tN = In * sigma # torque at vector value
    var wN = tN * tD # angular velocity
    var theta = wN * tD # new angle at Time in rads
    var L_prot = (L / cos(theta)) + Llos
    var RHAe = L_prot / 2
    return RHAe

func get_lprot_blunt (mass, Vn, Llos, In, Ia, L) #blunt nose normalization (Capped)
    # mass in kg
    # Vn is velocity at vector value (x, y, z)
    # Llos is line of sight thickness at impact angle
    # In is moment of inertia at vector value (x, y, z)
    # Ia is impact angle in radians
    Vn = abs(Vn)+

    var keD = mass * Vn * Vn * (sin(Ia) * sin(Ia)) #tangential KE numerator
    var KEt = 0.5 * keD # tangential KE 

    var tD = (1 / Vn) * (Llos / 1000) #time to travel distance in direction at that velocity 

    var sigma = sqrt((2 * KEt) / In) / tD #angular acceleration 
    var tN = In * sigma # torque at vector value
    var wN = -tN * tD # angular velocity
    var theta = wN * tD # new angle at Time in rads
    var L_prot = Llos + (L / cos(theta))
    var RHAe = L_prot / 2
    return RHAe


# get the magnitude of the RHAe by getting it for the (x y or z) velocoty and moment
