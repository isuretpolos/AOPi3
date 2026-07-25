extends Node3D

@export var min_rotation : float = 112.0
@export var max_rotation : float = -190.0
var mouse_inside : bool = false

func _ready() -> void:
	$KNOB.rotation.y = deg_to_rad(min_rotation)

func _on_static_body_3d_mouse_entered() -> void:
	mouse_inside = true

func _on_static_body_3d_mouse_exited() -> void:
	mouse_inside = false

func _unhandled_input(event: InputEvent) -> void:
	if mouse_inside && event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		print(event.as_text())
		
