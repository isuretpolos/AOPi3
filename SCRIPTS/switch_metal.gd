extends Node3D

@export var event_name := "ON/OFF"
@export var rotation_off := -15.5
@export var rotation_on := 15.5
@export var switch_on := false

var mouse_entered := false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton && mouse_entered:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if switch_on:
				switch(false)
			else:
				switch(true)
			

func _on_static_body_3d_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	mouse_entered = true

func _on_static_body_3d_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	mouse_entered = false
	
func switch(state:bool):
	switch_on = state
	if state:
		$switchMetalHandle.rotation.x = deg_to_rad(rotation_on)
	else:
		$switchMetalHandle.rotation.x = deg_to_rad(rotation_off)
