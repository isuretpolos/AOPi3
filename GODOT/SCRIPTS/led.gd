extends Node3D

@export var collector: Node
@export var led_state := false
@export var emission_color := Color(1, 1, 1)
@export var emission_energy := 1.0
@export var signal_name := "nothing"

@onready var led_mesh: MeshInstance3D = $ledEmissionBody/LEDbody
var led_material: StandardMaterial3D

func _ready():
	if collector != null && collector.has_signal(signal_name):
		var sig_led_on := Signal(collector, signal_name)
		sig_led_on.connect(signal_led_on)
		var sig_led_off := Signal(collector, "next_round")
		sig_led_off.connect(signal_led_off)
	
	led_material = led_mesh.get_active_material(0).duplicate()
	led_mesh.set_surface_override_material(0, led_material)
	if led_material is StandardMaterial3D:
		led_material.emission = emission_color
		led_material.emission_energy = emission_energy
		led_mesh.set_surface_override_material(0, led_material)
	global.power_state.connect(_on_power_state)
	_on_power_state(global.power) # initialize LED immediately
		
func switch(state:bool):
	led_state = state
	led_material.emission_enabled = state && global.power

func _on_power_state(state: bool) -> void:
	if state:
		turn_on()
	else:
		turn_off()

func turn_on() -> void:
	led_material.emission_enabled = led_state

func turn_off() -> void:
	led_material.emission_enabled = false
	
func signal_led_on() -> void:
	led_state = true
	led_material.emission_enabled = true
	
func signal_led_off() -> void:
	led_state = false
	led_material.emission_enabled = false
