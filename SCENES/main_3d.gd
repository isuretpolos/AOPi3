extends Node3D

var clear:bool = false

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
		"CLEAR":
			clear = !clear
			$PROTOTYPE_DEVICE/ButtonsControlPanel/CLEAR_LED.switch(clear)
