extends Node3D

@export var rotation_off := -15.5
@export var rotation_on := 15.5
@export var switch_on := false
@export var command_name := "TO_BE_DEFINED"

var mouse_entered := false
var switchSound = preload("res://AUDIO/switchMk12.mp3")
signal command_triggered(command_name: String)

func _ready() -> void:
	$switchMetalHandle.rotation.x = deg_to_rad(rotation_off)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton && mouse_entered:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if !$AudioStreamPlayer3D.is_playing():
				$AudioStreamPlayer3D.stream = switchSound
				$AudioStreamPlayer3D.play()
			if switch_on:
				print(name + " off")
				switch(false)
			else:
				print(name + " on")
				switch(true)
			print("... trying to emit the command " + command_name)
			command_triggered.emit(command_name)
			print("after emit")
			

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
		
