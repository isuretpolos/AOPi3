extends Node

var power:bool = false
signal power_state(state:bool)

func switch_power():
	power = !power
	power_state.emit(power)
