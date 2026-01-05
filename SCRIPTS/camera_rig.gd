extends Node3D

@export var look_at_target := Node3D

func _ready() -> void:
	if look_at_target:
		$SpringArm3D.position.x = look_at_target.position.x
		$SpringArm3D.position.z = look_at_target.position.z
		$SpringArm3D.look_at(look_at_target.position)
		$SpringArm3D.rotation.y = 0.0
		$SpringArm3D.position.x = look_at_target.position.x
		$SpringArm3D.position.z = look_at_target.position.z
