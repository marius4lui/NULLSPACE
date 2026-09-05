class_name PowerRelay
extends SectionLightSwitch
## Two physical actions: open the cabinet, then throw its existing original rocker.
var relay_id: String = "office"
var title: String = "OFFICE A"
var opened: bool = false
var audio: AudioStreamPlayer3D
var _cover: Node3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	super._ready()
	set_powered(false)
	var housing: MeshInstance3D = _part(Vector3(.46, .62, .12), Color(.25,.27,.23), .016)
	housing.position.z = -.07
	add_child(housing)
	_cover = Node3D.new()
	_cover.position = Vector3(-.23, 0, .055)
	add_child(_cover)
	var plate: MeshInstance3D = _part(Vector3(.46, .62, .035), Color(.37,.39,.32), .01)
	plate.position.x = .23
	_cover.add_child(plate)
	var label := Label3D.new()
	label.text = title + "\nPOWER CIRCUIT"
	label.font_size = 72
	label.pixel_size = .00045
	label.double_sided = false
	label.modulate = Color(.12,.14,.10)
	label.outline_size = 0
	label.position = Vector3(.23, .07, .021)
	_cover.add_child(label)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(.49,.65,.16)
	shape.shape = box
	add_child(shape)
	audio = AudioStreamPlayer3D.new()
	audio.stream = preload("res://assets/audio/room/breaker.wav")
	audio.bus = &"Environment"
	audio.max_distance = 24
	audio.unit_size = 2
	audio.volume_db = -4
	add_child(audio)

func prompt() -> String:
	if powered: return title + "  ·  Power restored"
	if opened and absf(_cover.rotation.y) < 1.6: return "Opening panel…"
	return "E  ·  " + ("Throw " + title + " switch" if opened else "Open " + title + " panel")

func use() -> void:
	if powered: return
	if not opened:
		opened = true
		audio.play()
		return
	if absf(_cover.rotation.y) < 1.6: return
	uses += 1
	set_powered(true)
	audio.play()
	var event := SoundEvent.new()
	var stamp: SimulationStamp = SimulationClock.sample()
	event.source_id = &"section_player"
	event.kind = &"breaker"
	event.position = global_position
	event.intensity = .6
	event.simulation_epoch = stamp.epoch
	event.simulation_seconds = stamp.elapsed_seconds
	EventHub.submit_sound(event)
	power_changed.emit(true)
	Telemetry.record(&"relay_activated", {"id": relay_id})

func restore(value: bool) -> void:
	set_powered(value)
	opened = value
	_cover.rotation.y = -2.55 if value else 0
	audio.stop()

func _physics_process(delta: float) -> void:
	_cover.rotation.y = move_toward(_cover.rotation.y, -2.55 if opened else 0, delta * 2.4)

func _exit_tree() -> void:
	if audio: audio.stop()
