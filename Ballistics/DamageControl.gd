extends Node3D
@export var Modules = []
@export var mdHP = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_cone_volume(angle):
	var radius = abs(10 / cos(angle))
	var vol = PI * radius * radius * (10 / 3)
	print("cone volume ", vol)
	return vol
	

func calculate_damage(module_position, distance, base_damage, fragment_density):
	var distance_factor = (1.0 / pow(distance, 0.25)) - 0.025
	var density_factor = 1.0 / fragment_density
	return abs((base_damage * distance_factor * density_factor))
	
func is_within_cone(module_position, exit_vector, exit_position, cone_angle):
	var v = (exit_vector.normalized())
	var to_module = (module_position - exit_position).normalized()
	print(to_module)
	var dot_product = v.dot(to_module)
	
	var angle = rad_to_deg(acos(dot_product))
	print(angle - 90)
	return abs(angle - 90) <= (cone_angle / 2)
	
func calculate_tnt_equivalent(mass: float, re_factor: float = 1.0) -> float:
	return mass * re_factor

# Function to calculate peak pressure
func calculate_peak_pressure(tnt_mass: float, scaling_factor: float = 100000) -> float:
	return scaling_factor * tnt_mass

# Function to calculate blast radius
func calculate_blast_radius(peak_pressure: float, threshold_pressure: float = 5 * 1000) -> float:
	print("blast radius 5kPa threshold: ", sqrt(peak_pressure / threshold_pressure) / 2)
	return sqrt(peak_pressure / threshold_pressure) / 2

# Function to calculate pressure at a given distance
func pressure_at_distance(peak_pressure: float, distance: float, blast_radius: float) -> float:
	if distance * 0.8 <= blast_radius:
		return peak_pressure / pow(distance, 2)
	else:
		return 0

	
# Function to calculate and return pressure based on inputs
func get_pressure(tnt_mass: float, distance: float) -> float:
	var tnt_equiv = calculate_tnt_equivalent(tnt_mass)
	var peak_pressure = calculate_peak_pressure(tnt_equiv)
	var blast_radius = calculate_blast_radius(peak_pressure)
	var pressure = pressure_at_distance(peak_pressure, distance, blast_radius)
	return pressure
	
	
func apply_explosion_damage(explodePos, tnt):
	var index = 0
	for module in Modules:
		var module_position = get_node(module).transform.origin
		var distance = module_position.distance_to(explodePos)
		var pres = get_pressure(tnt, distance)
		print(module, " received ", pres / 1000, " kPa")
		mdHP[index] -= pres * 0.0005
		if(mdHP[index] <= 0):
			print(module, " was destroyed by explosion")
		index += 1
func apply_fragment_damage(exit_position, exit_vector, cone_angle, base_damage, fragmentDensity):
	var index = 0
	for module in Modules:
		var module_position = get_node(module).transform.origin
		var distance = module_position.distance_to(exit_position) * 1000
		if is_within_cone(module_position, exit_position, exit_vector, cone_angle):
			var den = fragmentDensity / get_cone_volume(cone_angle)
			print("new fragment density ", den)
			var damage = calculate_damage(module_position, distance, base_damage, den)
			print("module ", module, " experienced ", damage, " units of damage")
			mdHP[index] -= damage
			if(mdHP[index] < 0):
				print("module ", module, " is desroyed")
		index += 1
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
