extends Node3D

@export var label_emission_power = 1.0
var capacitorLoad = preload("res://AUDIO/capacitor_slow_fine.wav")
var illuminated_materials: Dictionary = {}

func _ready() -> void:
	print($PROTOTYPE_DEVICE.get_tree_string_pretty())
	connect_switches($PROTOTYPE_DEVICE)
	prepare_illuminated_objects($PROTOTYPE_DEVICE)

	# Anfangszustand
	set_all_illumination(false)


func prepare_illuminated_objects(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var is_text := child.name.begins_with("Text")
			var is_knob_scale := child.name.begins_with("KnobScale")

			if is_text or is_knob_scale:
				register_illuminated_mesh(child)

		prepare_illuminated_objects(child)


func register_illuminated_mesh(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance.mesh == null:
		return

	for surface_index in mesh_instance.mesh.get_surface_count():
		var original := mesh_instance.get_active_material(surface_index)

		if original is StandardMaterial3D:
			var material := original.duplicate(true) as StandardMaterial3D
			mesh_instance.set_surface_override_material(surface_index, material)

			var key := "%s:%d" % [mesh_instance.get_path(), surface_index]
			illuminated_materials[key] = {
				"node": mesh_instance,
				"material": material,
				"original_albedo": material.albedo_color,
				"original_emission": material.emission,
				"original_energy": material.emission_energy_multiplier
			}


func set_all_illumination(enabled: bool) -> void:
	for entry: Dictionary in illuminated_materials.values():
		set_material_illumination(entry, enabled)


func set_group_illumination(prefix: String, enabled: bool) -> void:
	for entry: Dictionary in illuminated_materials.values():
		var mesh_instance := entry["node"] as MeshInstance3D

		if mesh_instance.name.begins_with(prefix):
			set_material_illumination(entry, enabled)


func set_material_illumination(entry: Dictionary, enabled: bool) -> void:
	var material := entry["material"] as StandardMaterial3D

	if enabled:
		material.emission_enabled = true
		material.emission = entry["original_emission"]
		material.emission_energy_multiplier = maxf(
			entry["original_energy"],
			1.0
		)
		material.albedo_color = entry["original_albedo"]
	else:
		material.emission_energy_multiplier = 0.0

		# Diese Zeile entfernen, falls die Skala ausgeschaltet
		# weiterhin weiß sichtbar bleiben soll.
		material.albedo_color = Color(0.08, 0.08, 0.08, material.albedo_color.a)


func set_knob_scales(enabled: bool) -> void:
	set_group_illumination("KnobScale", enabled)


func set_texts(enabled: bool) -> void:
	set_group_illumination("Text", enabled)
			
func connect_switches(node: Node) -> void:
	if node.has_signal("command_triggered"):
		node.command_triggered.connect(_on_command_triggered)

	for child in node.get_children():
		connect_switches(child)

func _on_command_triggered(command_name: String) -> void:

	match command_name:
		"POWER":
			global.switch_power()
			$PROTOTYPE_DEVICE/ButtonsControlPanel/POWER_LED.switch(global.power)
			set_knob_scales(global.power)
			set_texts(global.power)
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
			global.broadcasting = !global.broadcasting
			$PROTOTYPE_DEVICE/Broadcast_Panel/BROADCAST_LED.switch(global.broadcasting)

func chargeCapacitor() -> void:
	if global.power && global.super_charge:
		if !$PROTOTYPE_DEVICE/ButtonsControlPanel/AudioStreamPlayer3D.is_playing():
			$PROTOTYPE_DEVICE/ButtonsControlPanel/AudioStreamPlayer3D.stream = capacitorLoad
			$PROTOTYPE_DEVICE/ButtonsControlPanel/AudioStreamPlayer3D.play()
	if !global.super_charge:
		$PROTOTYPE_DEVICE/ButtonsControlPanel/AudioStreamPlayer3D.stop()
