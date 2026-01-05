extends Node3D

@export var look_at_target: Node3D
@export var zoom_at_target: Node3D
@export var mouse_sensitivity: float = 0.003
@export var panning_sensitivity: float = 0.01
@export var padding_factor := 1.0

var is_rotating := false
var is_panning := false
var orbit_angles := Vector2.ZERO  # Store yaw and pitch
var current_distance: float = 5.0  # Current distance from target
var original_target_position := Vector3.ZERO  # Store original target position
var panning_offset := Vector3.ZERO  # Store panning offset
@onready var camera_rig:=$"."

func _ready() -> void:
	if look_at_target && zoom_at_target:
		# Store the original target position
		original_target_position = look_at_target.position

		# Initialize orbit angles based on initial SpringArm position
		var initial_offset = camera_rig.position - look_at_target.position
		orbit_angles.y = atan2(initial_offset.x, initial_offset.z)  # yaw
		orbit_angles.x = atan2(initial_offset.y, sqrt(initial_offset.x * initial_offset.x + initial_offset.z * initial_offset.z))  # pitch
		# Position the SpringArm3D at the correct distance from the target
		update_camera_position()

func update_camera_position() -> void:
	if not look_at_target:
		return

	# Calculate the current panned target position
	var current_target_position = original_target_position + panning_offset

	# Calculate new camera position on sphere around target
	# Using spherical coordinates: yaw (y) and pitch (x)
	var horizontal_distance = current_distance * cos(orbit_angles.x)
	var offset_position = Vector3(
		horizontal_distance * sin(orbit_angles.y),  # x
		current_distance * sin(orbit_angles.x),     # y
		horizontal_distance * cos(orbit_angles.y)   # z
	)

	camera_rig.position = current_target_position + offset_position
	camera_rig.look_at(current_target_position, Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
	# Check for panning: SHIFT + MMB
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		var shift_pressed = Input.is_key_pressed(KEY_SHIFT)
		is_panning = event.pressed and shift_pressed
		is_rotating = event.pressed and not is_panning  # Only rotate if not panning

		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			is_panning = false
			is_rotating = false

	# Pan the camera like Blender: SHIFT + MMB
	if event is InputEventMouseMotion and is_panning and look_at_target:
		print("panning")
		# Calculate panning direction based on camera orientation
		# Get the camera's right and up vectors from its transform
		var camera_right = camera_rig.transform.basis.x
		var camera_up = camera_rig.transform.basis.y

		# Calculate the panning offset in world space
		var pan_delta = (camera_right * -event.relative.x * panning_sensitivity) + (camera_up * event.relative.y * panning_sensitivity)

		# Update the panning offset
		panning_offset += pan_delta

		# Update camera position with the new panning offset
		update_camera_position()

	# Rotate around the target like Blender: MMB only
	if event is InputEventMouseMotion and is_rotating and look_at_target:
		# Update orbit angles
		orbit_angles.y -= event.relative.x * mouse_sensitivity  # horizontal rotation (yaw)
		orbit_angles.x += event.relative.y * mouse_sensitivity  # vertical rotation (pitch) - Note the + instead of -

		# Clamp vertical angle to prevent flipping
		orbit_angles.x = clamp(orbit_angles.x, deg_to_rad(-89), deg_to_rad(89))

		# Update camera position
		update_camera_position()

	# Zoom with mouse wheel
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		current_distance *= 0.9
		update_camera_position()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		current_distance *= 1.1
		update_camera_position()
