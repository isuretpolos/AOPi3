extends Node

var power:bool = false
signal power_state(state:bool)

var clear:bool = false
var ground:bool = false
var super_charge:bool = false
var analysis:bool = false
var broadcasting:bool = false

func switch_power():
	power = !power
	power_state.emit(power)
