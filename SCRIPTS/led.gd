extends Node3D

@export var led_state := false
@export var emission_color := Color(1, 1, 1)
@export var emission_energy := 1.0

@onready var led_mesh: MeshInstance3D = $ledEmissionBody/Sphere
var led_material: StandardMaterial3D

func _ready():
	led_material = led_mesh.get_active_material(0).duplicate()
	led_mesh.set_surface_override_material(0, led_material)
	if led_material is StandardMaterial3D:
		led_material.emission = emission_color
		led_material.emission_energy = emission_energy
		led_mesh.set_surface_override_material(0, led_material)
	global.power_state.connect(_on_power_state)
	_on_power_state(global.power) # initialize LED immediately
		
func switch(state:bool):
	print(name + " switched and now own state is " + str(state))
	led_state = state
	led_material.emission_enabled = state && global.power

func _on_power_state(state: bool) -> void:
	print(name + ", device power is " + str(state) + " and own state is " + str(led_state))
	if state:
		turn_on()
	else:
		turn_off()

func turn_on() -> void:
	led_material.emission_enabled = led_state

func turn_off() -> void:
	led_material.emission_enabled = false
