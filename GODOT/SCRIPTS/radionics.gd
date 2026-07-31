extends Node3D

# Configurable thresholds instead of magic numbers
@export var threshold_touch := 9000
@export var threshold_hit := 9900
@export var threshold_super_hit := 9990
@export var threshold_anomalie := 9999
@export var next_round_fired: float= 1.0

@onready var timer := Timer.new()

var esp := ESP32Random.new()
var _thread: Thread
var _mutex := Mutex.new()
var _running := false

signal touch
signal hit
signal super_hit
signal anomalie
signal next_round

func _ready() -> void:
	add_child(timer)
	timer.wait_time = next_round_fired
	timer.timeout.connect(call_emit_next_round)
	timer.start()

func _on_button_pressed() -> void:
	if _running:
		return
	if not find_esp32_port():
		push_error("Port konnte nicht geoeffnet werden")
		return

	_running = true
	_thread = Thread.new()
	_thread.start(_collect_numbers)

func _collect_numbers() -> void:
	while true:
		_mutex.lock()
		var still_running := _running
		_mutex.unlock()
		if not still_running:
			break
		_check_resonance()

func _check_resonance() -> void:
	var v := esp.get_random_int(0, 100000)
	if v >= threshold_anomalie:
		call_deferred("emit_signal", "anomalie")
	elif v >= threshold_super_hit:
		call_deferred("emit_signal", "super_hit")
	elif v > threshold_hit:
		call_deferred("emit_signal", "hit")
	elif v > threshold_touch:
		call_deferred("emit_signal", "touch")
	
func call_emit_next_round() -> void:
	call_deferred("emit_signal", "next_round")

func stop_collecting() -> void:
	_mutex.lock()
	_running = false
	_mutex.unlock()
	if _thread and _thread.is_started():
		_thread.wait_to_finish()
	esp.close_port()

func _exit_tree() -> void:
	stop_collecting()
	
func find_esp32_port(baudrate: int = 921600) -> String:
	var candidates: Array[String] = []

	match OS.get_name():
		"Windows":
			for i in range(1, 33):
				candidates.append("COM%d" % i)
		"Linux":
			var dir := DirAccess.open("/dev")
			if dir:
				dir.list_dir_begin()
				var f := dir.get_next()
				while f != "":
					if f.begins_with("ttyUSB") or f.begins_with("ttyACM"):
						candidates.append("/dev/" + f)
					f = dir.get_next()
		"macOS":
			var dir := DirAccess.open("/dev")
			if dir:
				dir.list_dir_begin()
				var f := dir.get_next()
				while f != "":
					if f.begins_with("cu.usbserial") or f.begins_with("cu.SLAB") or f.begins_with("cu.usbmodem"):
						candidates.append("/dev/" + f)
					f = dir.get_next()

	for port in candidates:
		print("Teste Port: ", port)
		if esp.open_port(port, baudrate):
			var test := esp.get_random_bytes(4)   # pruefen ob wirklich Daten kommen
			if test.size() == 4:
				print("ESP32 gefunden auf: ", port)
				return port
			esp.close_port()

	return ""
