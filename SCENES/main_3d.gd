extends Node3D

var clear:bool = false
var ground:bool = false
var super_charge:bool = false
var capacitorLoad = preload("res://AUDIO/capacitor_slow_fine.wav")

func _ready() -> void:
	for switch in $PROTOTYPE_DEVICE/ButtonsControlPanel.get_children():
		if switch.has_signal("command_triggered"):
			switch.command_triggered.connect(_on_command_triggered)


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
			clear = !clear
			$PROTOTYPE_DEVICE/ButtonsControlPanel/CLEAR_LED.switch(clear)
		"GROUND":
			ground = !ground
			$PROTOTYPE_DEVICE/ButtonsControlPanel/GROUND_LED.switch(ground)
		"SUPER_CHARGE":
			super_charge = !super_charge
			$PROTOTYPE_DEVICE/ButtonsControlPanel/SUPERCHARGE_LED.switch(super_charge)
			chargeCapacitor()

func chargeCapacitor() -> void:
	if global.power && super_charge:
		if !$PROTOTYPE_DEVICE/ButtonsControlPanel/AudioStreamPlayer3D.is_playing():
			$PROTOTYPE_DEVICE/ButtonsControlPanel/AudioStreamPlayer3D.stream = capacitorLoad
			$PROTOTYPE_DEVICE/ButtonsControlPanel/AudioStreamPlayer3D.play()
	if !super_charge:
		$PROTOTYPE_DEVICE/ButtonsControlPanel/AudioStreamPlayer3D.stop()
