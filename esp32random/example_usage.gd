extends Node

var esp := ESP32Random.new()

func _ready() -> void:
	# Linux: "/dev/ttyUSB0", macOS: "/dev/cu.usbserial-XXXX", Windows: "COM5"
	var port_name := "/dev/ttyUSB0"
	var baudrate := 921600

	if not esp.open_port(port_name, baudrate):
		push_error("Konnte seriellen Port nicht oeffnen: %s" % port_name)
		return

	# Eine einzelne Zufallszahl zwischen 0 und 1000 (inklusive)
	var single := esp.get_random_int(0, 1000)
	print("Einzelne Zufallszahl: ", single)

	# Eine Reihe von 20 Zufallszahlen zwischen 0 und 1000
	var series := esp.get_random_int_array(0, 1000, 20)
	print("Zahlenreihe: ", series)

	# Rohe Zufallsbytes, falls mal gebraucht
	var raw_bytes := esp.get_random_bytes(16)
	print("16 Zufallsbytes: ", raw_bytes)

	esp.close_port()
