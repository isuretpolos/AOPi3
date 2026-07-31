extends Node3D

@export var event_name := "ON/OFF"
@export var rotation_off := -5.5
@export var rotation_on := 5.5
@export var switch_on := false
@export var emission_color := Color(1, 1, 1)
@export var emission_energy := 1.0

var mouse_entered := false

func _ready():
	var mat :Material= get_child(0).get_active_material(0)
	if mat is StandardMaterial3D:
		mat = mat.duplicate()
		mat.emission = emission_color
		mat.emission_energy = emission_energy
		get_child(0).set_surface_override_material(0, mat)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton && mouse_entered:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if switch_on:
				switch(false)
			else:
				switch(true)
			

func _on_static_body_3d_mouse_entered() -> void:
	mouse_entered = true

func _on_static_body_3d_mouse_exited() -> void:
	mouse_entered = false
	
func switch(state:bool):
	
	switch_on = state
	get_child(0).get_active_material(0).emission_enabled = state
	
	if state:
		$".".rotation.x = deg_to_rad(rotation_on)
	else:
		$".".rotation.x = deg_to_rad(rotation_off)
