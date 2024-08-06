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
	return clamp((base_damage * distance_factor * density_factor - 4501.96553907001), 0, 10e6)
	
func is_within_cone(module_position, exit_vector, exit_position, cone_angle):
	var v = (exit_vector.normalized())
	var to_module = (module_position - exit_position).normalized()
	print(to_module)
	var dot_product = v.dot(to_module)
	
	var angle = rad_to_deg(acos(dot_product))
	print(angle - 90)
	return abs(angle - 90) <= (cone_angle / 2)
	
	
	
func apply_fragment_damage(exit_position, exit_vector, cone_angle, base_damage, fragmentDensity):
	for module in Modules:
		var module_position = get_node(module).transform.origin
		var distance = module_position.distance_to(exit_position) * 1000
		if is_within_cone(module_position, exit_position, exit_vector, cone_angle):
			var den = fragmentDensity / get_cone_volume(cone_angle)
			print("new fragment density ", den)
			var damage = calculate_damage(module_position, distance, base_damage, den)
			print("module ", module, " experienced ", damage, " units of damage")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
