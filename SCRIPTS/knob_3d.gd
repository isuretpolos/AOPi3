extends Node3D

@export var min_rotation : float = 112.0
@export var max_rotation : float = -190.0
@export var sensitivity : float = 0.5
@export var value_min : float = 0.0
@export var value_max : float = 100.0
@export var reverse_value : bool = false

var mouse_inside : bool = false
var dragging : bool = false
var just_started : bool = false
var current_rotation : float
var current_value : float

func _ready() -> void:
	current_rotation = min_rotation
	$KNOB.rotation.y = deg_to_rad(current_rotation)
	update_current_value()

# We remember if the mouse entered the Knob
func _on_static_body_3d_mouse_entered() -> void:
	mouse_inside = true

# Or if it left the boundaries
func _on_static_body_3d_mouse_exited() -> void:
	mouse_inside = false

func _unhandled_input(event: InputEvent) -> void:
	# here we check if the even contains the left mouse button
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# and if it was pressed and it is inside the boundaries of the knob
		if event.pressed and mouse_inside:
			dragging = true # then we set dragging on
			just_started = true
			get_viewport().set_input_as_handled() # and prevent the propagation of this event
		elif not event.pressed:
			dragging = false

	if event is InputEventMouseMotion and dragging:
		# add rotation to the knob
		if just_started:
			just_started = false
		else:
			current_rotation += event.relative.x * sensitivity
			current_rotation = clamp(current_rotation, max_rotation, min_rotation)
			$KNOB.rotation.y = deg_to_rad(current_rotation)
			update_current_value()
			# print(current_value)
		get_viewport().set_input_as_handled()
		
func update_current_value() -> void:
	# remap current_rotation from [max_rotation, min_rotation] to [value_min, value_max]
	if reverse_value:
		current_value = remap(current_rotation, max_rotation, min_rotation, value_max, value_min)
	else:
		current_value = remap(current_rotation, max_rotation, min_rotation, value_min, value_max)
