class_name SectionSound
extends Node3D
## A few concrete room sources and bounded Foley voices. No generalized audio framework.
const ROOT: String = "res://assets/audio/room/"
var section: NullspaceSection
var hums: Array[AudioStreamPlayer3D] = []
var steps: Array[AudioStreamPlayer3D] = []
var body_voice: AudioStreamPlayer3D
var breath: AudioStreamPlayer3D
var air: AudioStreamPlayer
var _step_index: int = 0
var _creature_index: int = 0
var _occlusion_time: float = 0
var _blocked: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	for i: int in range(0, section.room.fixtures.size(), 3):
		var source := _voice(&"Fluorescent", 9)
		source.position = section.room.fixtures[i].global_position
		source.stream = _clip("hum_%s" % (i % 3), true)
		source.volume_db = -18
		source.play(float(i % 5))
		hums.append(source)
	for i: int in 4:
		steps.append(_voice(&"Player", 8))
	body_voice = _voice(&"Monster", 22)
	body_voice.volume_db = -3
	breath = _voice(&"Monster", 14)
	breath.stream = _clip("listener_breath", true)
	breath.volume_db = -20
	breath.play()
	air = AudioStreamPlayer.new()
	air.bus = &"Ambience"
	air.stream = _clip("air", true)
	air.volume_db = -34
	add_child(air)
	air.play()
	EventHub.sound_emitted.connect(_player_foley)
	section.listener.footstep.connect(_monster_step)
	section.listener.state_changed.connect(_monster_state)

func _voice(bus: StringName, reach: float) -> AudioStreamPlayer3D:
	var voice := AudioStreamPlayer3D.new()
	voice.bus = bus
	voice.max_distance = reach
	voice.unit_size = 2.0
	add_child(voice)
	return voice

func _clip(id: String, loop: bool = false) -> AudioStreamWAV:
	var stream := load(ROOT + id + ".wav") as AudioStreamWAV
	if loop:
		stream = stream.duplicate() as AudioStreamWAV
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	return stream

func _player_foley(event: SoundEvent) -> void:
	if event.source_id != &"section_player" or not String(event.kind).ends_with("_step"):
		return
	var voice: AudioStreamPlayer3D = steps[_step_index % steps.size()]
	voice.position = event.position + Vector3.UP * 0.1
	voice.stream = _clip("carpet_%s" % (_step_index % 4))
	voice.pitch_scale = 0.96 + (_step_index % 3) * 0.035
	voice.volume_db = -18 if event.kind == &"crouch_step" else (-2 if event.kind == &"sprint_step" else -7)
	voice.play()
	_step_index += 1

func _monster_step() -> void:
	body_voice.position = section.listener.global_position + Vector3.UP * 0.15
	body_voice.stream = _clip("listener_step_%s" % (_creature_index % 4))
	body_voice.volume_db = -12 if _blocked else -3
	body_voice.play()
	_creature_index += 1

func _monster_state(next: Listener.State) -> void:
	if next not in [Listener.State.ATTACKING, Listener.State.STAGGERED]:
		return
	body_voice.position = section.listener.global_position + Vector3.UP * 1.8
	body_voice.stream = _clip("attack" if next == Listener.State.ATTACKING else "hurt")
	body_voice.volume_db = -6
	body_voice.play()

func _physics_process(delta: float) -> void:
	if GameFlow.state != NullGameFlow.State.PLAYING:
		return
	breath.position = section.listener.global_position + Vector3.UP * 1.8
	_occlusion_time += delta
	if _occlusion_time >= .25:
		_occlusion_time = 0
		var ray := PhysicsRayQueryParameters3D.create(section.player.camera.global_position, breath.position, 1)
		_blocked = not get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
		breath.volume_db = -28 if _blocked else -20
	for hum: AudioStreamPlayer3D in hums:
		hum.volume_db = move_toward(hum.volume_db, -18 if section.light_switch.powered else -80, delta * 35)

func reset() -> void:
	for voice: AudioStreamPlayer3D in steps:
		voice.stop()
	body_voice.stop()
	_step_index = 0
	_creature_index = 0

func shutdown() -> void:
	set_physics_process(false)
	for hum: AudioStreamPlayer3D in hums: hum.stop()
	for voice: AudioStreamPlayer3D in steps: voice.stop()
	if body_voice: body_voice.stop()
	if breath: breath.stop()
	if air: air.stop()

func _exit_tree() -> void:
	shutdown()
