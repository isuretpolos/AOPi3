extends Node3D

var capacitorLoad = preload("res://AUDIO/capacitor_slow_fine.wav")

func _ready() -> void:
	connect_switches($PROTOTYPE_DEVICE)
			
func connect_switches(node: Node) -> void:
	if node.has_signal("command_triggered"):
		node.command_triggered.connect(_on_command_triggered)

	for child in node.get_children():
		connect_switches(child)

func _on_command_triggered(command_name: String) -> void:
	print("COMMAND: ", command_name)

	match command_name:
		"POWER":
			global.switch_power()
			$PROTOTYPE_DEVICE/ButtonsControlPanel/POWER_LED.switch(global.power)
			if !global.power:
				$PROTOTYPE_DEVICE/ButtonsControlPanel/AudioStreamPlayer3D.stop()
			chargeCapacitor()
		"CLEAR":
			global.clear = !global.clear
			$PROTOTYPE_DEVICE/ButtonsControlPanel/CLEAR_LED.switch(global.clear)
		"GROUND":
			global.ground = !global.ground
			$PROTOTYPE_DEVICE/ButtonsControlPanel/GROUND_LED.switch(global.ground)
		"SUPER_CHARGE":
			global.super_charge = !global.super_charge
			$PROTOTYPE_DEVICE/ButtonsControlPanel/SUPERCHARGE_LED.switch(global.super_charge)
			chargeCapacitor()
		"BROADCAST":
			print("broadcast")
			global.broadcasting = !global.broadcasting
			$PROTOTYPE_DEVICE/Broadcast_Panel/BROADCAST_LED.switch(global.broadcasting)

func chargeCapacitor() -> void:
	if global.power && global.super_charge:
		if !$PROTOTYPE_DEVICE/ButtonsControlPanel/AudioStreamPlayer3D.is_playing():
			$PROTOTYPE_DEVICE/ButtonsControlPanel/AudioStreamPlayer3D.stream = capacitorLoad
			$PROTOTYPE_DEVICE/ButtonsControlPanel/AudioStreamPlayer3D.play()
	if !global.super_charge:
		$PROTOTYPE_DEVICE/ButtonsControlPanel/AudioStreamPlayer3D.stop()
