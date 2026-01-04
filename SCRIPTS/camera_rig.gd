extends Node3D

# Direction X/Y where one looks
var _look := Vector2.ZERO
@export var rotate_sensitivity := 0.003
@export var pan_sensitivity := 0.01
@export var zoom_sensitivity := 0.5

@export var min_pitch := deg_to_rad(-85)
@export var max_pitch := deg_to_rad(85)
@export var min_zoom := 1.5
@export var max_zoom := 30.0

@onready var yaw_pivot := $HorizontalPivot
@onready var pitch_pivot := $HorizontalPivot/VerticalPivot
@onready var spring_arm := $HorizontalPivot/VerticalPivot/SpringArm3D

var rotating := false
var panning := false
#@export var mouse_sensitivity :float = 0.00075

func _unhandled_input(event: InputEvent) -> void:

	# --- Mouse Motion ---
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):

			if Input.is_key_pressed(KEY_SHIFT):
				pan_camera(event.relative)
			else:
				rotate_camera(event.relative)

	# --- Zoom ---
	elif event is InputEventMouseButton:
		if Input.is_key_pressed(KEY_SHIFT):
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				spring_arm.spring_length -= zoom_sensitivity
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				spring_arm.spring_length += zoom_sensitivity

		spring_arm.spring_length = clamp(
			spring_arm.spring_length, min_zoom, max_zoom
		)


func rotate_camera(delta: Vector2) -> void:
	# Yaw
	yaw_pivot.rotate_y(-delta.x * rotate_sensitivity)

	# Pitch
	var new_pitch = pitch_pivot.rotation.x - delta.y * rotate_sensitivity
	pitch_pivot.rotation.x = clamp(new_pitch, min_pitch, max_pitch)


func pan_camera(delta: Vector2) -> void:
	var right = -yaw_pivot.global_transform.basis.x
	var up = -yaw_pivot.global_transform.basis.y

	global_translate(
		(right * delta.x + up * -delta.y) * pan_sensitivity
	)


	
