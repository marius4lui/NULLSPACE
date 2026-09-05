class_name SectionDoor
extends Node3D
## A concrete two-leaf door. Leaves always remain physical; the Listener opens them.
signal changed(open: bool)
const LEAF: PackedScene = preload("res://assets/doors/door_leaf.glb")
const FRAME: PackedScene = preload("res://assets/doors/door_frame.glb")
var player: SectionPlayer
var listener: Listener
var opened: bool = false
var door_id: String = "office_door"
var angle: float = 0
var _target: float = 0
var _speed: float = 1.65
var _leaves: Array[Leaf] = []
var _audio: AudioStreamPlayer3D

class Leaf extends AnimatableBody3D:
	var door: SectionDoor
	func prompt() -> String: return door.prompt()
	func use() -> void: door.use()

class Trigger extends Area3D:
	var door: SectionDoor
	func prompt() -> String: return door.prompt()
	func use() -> void: door.use()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(FRAME.instantiate())
	for side: float in [-1.0, 1.0]:
		var leaf := Leaf.new()
		leaf.door = self
		leaf.collision_layer = 1
		leaf.collision_mask = 0
		leaf.position.x = side * 1.16
		add_child(leaf)
		var model := LEAF.instantiate() as Node3D
		model.scale.x = -side
		leaf.add_child(model)
		if side > 0:
			(model.find_child("CenterAstragal", true, false) as Node3D).visible = false
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.18, 2.414, .10) # Astragal seals the central vision/shot seam.
		shape.shape = box
		shape.position = Vector3(-side * .58, 1.207, 0)
		leaf.add_child(shape)
		_leaves.append(leaf)
	# The open doorway remains easy to target when both leaves are beside the player.
	# Interaction-only area: it never blocks navigation, shots, sound or sight.
	var trigger := Trigger.new()
	trigger.door = self
	trigger.collision_layer = 8
	trigger.collision_mask = 0
	var trigger_shape := CollisionShape3D.new()
	var aperture := BoxShape3D.new()
	aperture.size = Vector3(2.32, 2.42, .14)
	trigger_shape.shape = aperture
	trigger_shape.position.y = 1.21
	trigger.add_child(trigger_shape)
	add_child(trigger)
	_audio = AudioStreamPlayer3D.new()
	_audio.bus = &"Environment"
	_audio.stream = preload("res://assets/audio/room/door.wav")
	_audio.max_distance = 18
	_audio.unit_size = 2
	add_child(_audio)

func prompt() -> String:
	if opened and _occupied():
		return "Doorway obstructed"
	return "E  ·  " + ("Close door" if opened else "Open door")

func use() -> void:
	set_open(not opened, player.global_position, false)

func open_for_listener(chasing: bool) -> void:
	if not opened:
		set_open(true, listener.global_position, chasing)

func set_open(value: bool, actor: Vector3, fast: bool = false) -> void:
	if opened == value:
		return
	if not value and _occupied():
		return # A body in the threshold cannot be crushed or sealed into the leaf.
	opened = value
	_speed = 4.2 if fast else 1.65
	_target = (1.67 if to_local(actor).z >= 0 else -1.67) if value else 0.0
	_audio.volume_db = -4 if fast else -10
	_audio.play()
	changed.emit(value)
	var event := SoundEvent.new()
	var stamp: SimulationStamp = SimulationClock.sample()
	event.source_id = &"section_player" if actor.distance_to(player.global_position) < .05 else &"listener"
	event.kind = &"door"
	event.position = global_position
	event.intensity = .40 if fast else .26
	event.simulation_epoch = stamp.epoch
	event.simulation_seconds = stamp.elapsed_seconds
	EventHub.submit_sound(event)
	Telemetry.record(&"door", {"id": door_id, "open": opened, "fast": fast, "actor": event.source_id})

func restore(value: bool) -> void:
	opened = value
	_target = 1.67 if value else 0
	angle = _target
	_apply_angle()
	_audio.stop()

func _physics_process(delta: float) -> void:
	if not opened and _occupied():
		return
	angle = move_toward(angle, _target, _speed * delta)
	_apply_angle()

func _apply_angle() -> void:
	_leaves[0].rotation.y = angle
	_leaves[1].rotation.y = -angle

func _occupied() -> bool:
	for actor: Node3D in [player, listener]:
		var p: Vector3 = to_local(actor.global_position)
		if absf(p.x) < 1.45 and absf(p.z) < .48:
			return true
	return false

func attenuates_segment(from: Vector3, to: Vector3) -> bool:
	if absf(angle) > .75:
		return false
	var a: Vector3 = to_local(from)
	var b: Vector3 = to_local(to)
	if a.z * b.z > 0 or absf(a.z - b.z) < .001:
		return false
	var crossing: Vector3 = a.lerp(b, a.z / (a.z - b.z))
	return absf(crossing.x) < 1.3 and crossing.y < 2.6

func _exit_tree() -> void:
	if _audio: _audio.stop()
