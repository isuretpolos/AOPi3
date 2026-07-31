extends Node

# Audio Random Generator für Godot 4.5
# Nutzt Mikrofon-Rauschen als Entropiequelle

var audio_effect_capture: AudioEffectCapture
var audio_stream_player: AudioStreamPlayer
var is_recording: bool = false
var collected_bits: Array = []

# Konfiguration
const SAMPLE_RATE = 44100
const BUFFER_LENGTH = 0.1  # Sekunden

func _ready():
	setup_audio_capture()
	print("Audio Random Generator bereit!")
	print("Drücke SPACE um 10.000 Zufallszahlen zu generieren")

func setup_audio_capture():
	"""Richtet Audio-Capture ein"""
	# AudioStreamPlayer erstellen
	audio_stream_player = AudioStreamPlayer.new()
	add_child(audio_stream_player)
	
	# Mikrofon als Input
	var microphone = AudioStreamMicrophone.new()
	audio_stream_player.stream = microphone
	
	# AudioEffectCapture zum Bus hinzufügen
	var bus_index = AudioServer.get_bus_index("Record")
	if bus_index == -1:
		# Bus erstellen falls nicht vorhanden
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, "Record")
	
	# Capture-Effekt hinzufügen
	audio_effect_capture = AudioEffectCapture.new()
	audio_effect_capture.buffer_length = BUFFER_LENGTH
	AudioServer.add_bus_effect(bus_index, audio_effect_capture)
	
	# Player an Record-Bus routen
	audio_stream_player.bus = "Record"

func _input(event):
	if event.is_action_pressed("ui_accept"):  # SPACE-Taste
		if not is_recording:
			start_generation()

func start_generation():
	"""Startet die Generierung von Zufallszahlen"""
	print("\n=== Starte Zufallszahlen-Generierung ===")
	is_recording = true
	collected_bits.clear()
	
	# Mikrofon starten
	audio_stream_player.play()
	audio_effect_capture.clear_buffer()
	
	print("Sammle Audio-Rauschen vom Mikrofon...")

func _process(_delta):
	if not is_recording:
		return
	
	# Audio-Frames lesen
	var frames_available = audio_effect_capture.get_frames_available()
	
	if frames_available > 0:
		var audio_frames = audio_effect_capture.get_buffer(frames_available)
		extract_entropy_from_audio(audio_frames)
		
		# Fortschritt anzeigen
		if collected_bits.size() % 10000 == 0 and collected_bits.size() > 0:
			print("Gesammelte Bits: %d / 240000" % collected_bits.size())
		
		# Genug Bits gesammelt? (10.000 Zahlen × 24 Bits)
		if collected_bits.size() >= 240000:
			finish_generation()

func extract_entropy_from_audio(audio_frames: PackedVector2Array):
	"""Extrahiert Entropie-Bits aus Audio-Daten"""
	for frame in audio_frames:
		# Beide Kanäle nutzen (L und R)
		var left_sample = int(frame.x * 32767.0)  # Float zu Int16
		var right_sample = int(frame.y * 32767.0)
		
		# Niedrigwertigste Bits extrahieren (höchste Entropie)
		collected_bits.append(left_sample & 1)
		collected_bits.append(right_sample & 1)

func finish_generation():
	"""Beendet die Generierung und speichert die Datei"""
	is_recording = false
	audio_stream_player.stop()
	
	print("\nKonvertiere Bits zu Integers...")
	
	# Bits in Integers konvertieren
	var integers = bits_to_integers(collected_bits, 10000, 16777215)
	
	# JSON erstellen
	var data = {
		"integerList": integers
	}
	
	# Dateiname mit Timestamp
	var timestamp_ms = Time.get_ticks_msec()
	var filename = "user://hotbits_%d.json" % timestamp_ms
	
	# Datei speichern
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		
		print("\n✓ Erfolgreich %d Zufallszahlen generiert!" % integers.size())
		print("✓ Datei gespeichert: %s" % filename)
		print("✓ Echter Pfad: %s" % ProjectSettings.globalize_path(filename))
		
		# Statistiken
		print("\nStatistiken:")
		print("  Min: %d" % integers.min())
		print("  Max: %d" % integers.max())
		print("  Durchschnitt: %.2f" % (integers.reduce(func(a, b): return a + b, 0) / float(integers.size())))
		print("  Erste 10: %s" % str(integers.slice(0, 10)))
		
		print("\nDrücke SPACE für weitere 10.000 Zahlen")
	else:
		print("FEHLER: Konnte Datei nicht speichern!")

func bits_to_integers(bits: Array, num_integers: int, max_value: int) -> Array:
	"""Konvertiert Bit-Array in Integer-Array"""
	var integers: Array = []
	var bits_per_int = get_bits_needed(max_value)  # 24 für 16777215
	
	for i in range(num_integers):
		var start_idx = i * bits_per_int
		var end_idx = start_idx + bits_per_int
		
		if end_idx > bits.size():
			break
		
		# Bits zu Integer konvertieren
		var value = 0
		for j in range(start_idx, end_idx):
			value = (value << 1) | bits[j]
		
		# Auf max_value begrenzen
		value = value % (max_value + 1)
		integers.append(value)
	
	return integers

func get_bits_needed(max_value: int) -> int:
	"""Berechnet benötigte Bits für max_value"""
	var bits = 0
	var n = max_value
	while n > 0:
		bits += 1
		n >>= 1
	return bits

func _exit_tree():
	"""Aufräumen beim Beenden"""
	if audio_stream_player:
		audio_stream_player.stop()
