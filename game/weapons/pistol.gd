class_name SectionPistol
extends Node3D
## One concrete semiautomatic pistol. Committed ammo changes only here.

signal ammunition_changed(loaded: int, spare: int, owned: bool)
signal fired

enum State { READY, CYCLING, RELOADING, EQUIPPING }
const MODEL: PackedScene = preload("res://assets/pistol/pistol.glb")
const SHOTS: Array[AudioStream] = [preload("res://assets/audio/pistol/pistol_0.wav"),
	preload("res://assets/audio/pistol/pistol_1.wav"), preload("res://assets/audio/pistol/pistol_2.wav")]
const EMPTY: AudioStream = preload("res://assets/audio/pistol/empty.wav")
const MAG_OUT: AudioStream = preload("res://assets/audio/pistol/mag_out.wav")
const MAG_IN: AudioStream = preload("res://assets/audio/pistol/mag_in.wav")
const SLIDE: AudioStream = preload("res://assets/audio/pistol/slide.wav")
const PICKUP: AudioStream = preload("res://assets/audio/pistol/pickup.wav")
const CAPACITY: int = 12
const FIRE_INTERVAL: float = 0.22
const RELOAD_TACTICAL: float = 1.55
const RELOAD_EMPTY: float = 1.85
const HIP := Vector3(0.16, -0.195, -0.43)

var wielder: SectionPlayer
var effects: PistolEffects
var owned: bool = false
var chamber: int = 0
var magazine: int = 0
var reserve: int = 0
var state: State = State.READY
var shots_fired: int = 0
var _model: Node3D
var _slide: Node3D
var _mag: Node3D
var _left: Node3D
var _flash: OmniLight3D
var _flare: MeshInstance3D
var _timer: float = 0.0
var _recoil: float = 0.0
var _flash_time: float = 0.0
var _reload_empty: bool = false
var _reload_inserted: bool = false
var _reload_racked: bool = false
var _pending_fire: int = -1
var _pending_reload: int = -1
var _settings: Dictionary = {}
var _wall_raise: float = 0.0
var _bob_time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_model = MODEL.instantiate() as Node3D
	add_child(_model)
	_slide = _model.find_child("Slide", true, false) as Node3D
	_mag = _model.find_child("Magazine", true, false) as Node3D
	_left = _model.find_child("LeftHand", true, false) as Node3D
	_flash = OmniLight3D.new()
	_flash.position = Vector3(0, 0.101, -0.154)
	_flash.light_color = Color(1, 0.68, 0.33)
	_flash.omni_range = 4.0
	_flash.light_energy = 1.9
	_flash.shadow_enabled = false
	_flash.visible = false
	add_child(_flash)
	_flare = MeshInstance3D.new()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in 6:
		var angle: float = float(i) * TAU / 6
		surface.add_vertex(Vector3(0, 0.101, -0.153))
		surface.add_vertex(Vector3(cos(angle) * 0.025, 0.101 + sin(angle) * 0.025, -0.169))
		surface.add_vertex(Vector3(0, 0.101, -0.225))
	surface.generate_normals()
	_flare.mesh = surface.commit()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.84, 0.46, 0.75)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_flare.material_override = mat
	add_child(_flare)
	_flare.visible = false
	InputGate.invalidated.connect(_cancel_pending)
	SettingsManager.settings_changed.connect(func(values: Dictionary) -> void: _settings = values)
	_settings = SettingsManager.snapshot()
	position = HIP
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if InputGate.accept_press(event, &"fire"):
		_pending_fire = InputGate.generation
	if InputGate.accept_press(event, &"reload"):
		_pending_reload = InputGate.generation

func _physics_process(delta: float) -> void:
	if GameFlow.state != NullGameFlow.State.PLAYING:
		return
	if _pending_fire >= 0:
		var valid: bool = InputGate.accepts_generation(_pending_fire)
		_pending_fire = -1
		if valid:
			try_fire()
	if _pending_reload >= 0:
		var valid: bool = InputGate.accepts_generation(_pending_reload)
		_pending_reload = -1
		if valid:
			try_reload()
	_timer += delta
	match state:
		State.CYCLING:
			if _timer >= FIRE_INTERVAL:
				state = State.READY
		State.EQUIPPING:
			if _timer >= 0.5:
				state = State.READY
		State.RELOADING:
			if _timer >= 0.98 and not _reload_inserted:
				var transfer: int = mini(CAPACITY - magazine, reserve)
				magazine += transfer
				reserve -= transfer
				_reload_inserted = true
				_sound(MAG_IN)
				_notify()
			if _reload_empty and _timer >= 1.52 and not _reload_racked:
				_chamber_next()
				_reload_racked = true
				_sound(SLIDE)
				_notify()
			if _timer >= (RELOAD_EMPTY if _reload_empty else RELOAD_TACTICAL):
				state = State.READY
	_animate(delta)

func try_fire() -> bool:
	if not owned or state != State.READY or not InputGate.accepts_input() or wielder.sprinting:
		return false
	if chamber == 0:
		_sound(EMPTY)
		state = State.CYCLING
		_timer = 0.0
		return false
	chamber -= 1
	_chamber_next()
	shots_fired += 1
	state = State.CYCLING
	_timer = 0.0
	_recoil = 1.0
	_flash_time = 0.043
	_sound(SHOTS[(shots_fired - 1) % SHOTS.size()])
	var camera: Camera3D = wielder.camera
	var origin: Vector3 = camera.global_position
	var direction: Vector3 = -camera.global_basis.z
	var shot := ShotEvent.new()
	shot.action_id = "pistol_%s_%s" % [SimulationClock.sample().epoch, shots_fired]
	shot.generation = InputGate.generation
	shot.weapon_id = &"pistol"
	shot.origin = origin
	shot.direction = direction
	shot.monotonic_usec = Time.get_ticks_usec()
	shot.physics_tick = Engine.get_physics_frames()
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 65.0, 1 | 4, [wielder.get_rid()])
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var result := ShotHit.new()
		var target := hit["collider"] as Node
		result.target_id = target.name
		result.position = hit["position"]
		result.normal = hit["normal"]
		result.surface_id = &"metal" if target is SectionLightSwitch or target is SectionDoor.Leaf else &"plaster"
		shot.hits.append(result)
		if target.has_method("receive_shot"):
			target.call("receive_shot", result.position, 1.0)
		else:
			effects.impact(result.position, result.normal, result.surface_id == &"metal", target as SectionDoor.Leaf)
	var stamp: SimulationStamp = SimulationClock.sample()
	var sound := SoundEvent.new()
	sound.event_id = shot.action_id
	sound.source_id = &"section_player"
	sound.room_id = &"a_01"
	sound.kind = &"pistol_shot"
	sound.position = wielder.global_position
	sound.intensity = 1.0
	sound.simulation_seconds = stamp.elapsed_seconds
	sound.simulation_epoch = stamp.epoch
	sound.monotonic_usec = shot.monotonic_usec
	EventHub.submit_sound(sound)
	EventHub.shot_accepted.emit(shot)
	if _wall_raise < 0.5:
		var ejection := Transform3D(global_basis, to_global(Vector3(0.024, 0.104, -0.031)))
		effects.eject(ejection, camera.global_basis.x * 1.7 + Vector3.UP * 0.9 + wielder.velocity * 0.15)
	wielder.add_recoil(0.011, 0.002 if shots_fired % 2 == 0 else -0.0015)
	fired.emit()
	_notify()
	Telemetry.record(&"pistol_shot", {"action": shot.action_id, "loaded": chamber + magazine, "reserve": reserve,
		"hit": not hit.is_empty(), "origin": [origin.x, origin.y, origin.z]})
	return true

func try_reload() -> bool:
	if not owned or state != State.READY or not InputGate.accepts_input():
		return false
	if magazine == CAPACITY and chamber > 0 or reserve == 0 and chamber > 0:
		return false
	if magazine + reserve == 0:
		return false
	state = State.RELOADING
	_timer = 0.0
	_reload_empty = chamber == 0
	_reload_inserted = false
	_reload_racked = false
	_sound(MAG_OUT)
	Telemetry.record(&"pistol_reload", {"empty": _reload_empty, "total": chamber + magazine + reserve})
	return true

func acquire() -> bool:
	if owned:
		return false
	owned = true
	chamber = 1
	magazine = 7
	reserve = 12
	visible = true
	state = State.EQUIPPING
	_timer = 0.0
	_sound(PICKUP)
	_notify()
	return true

func snapshot() -> Dictionary:
	return {"owned": owned, "chamber": chamber, "magazine": magazine, "reserve": reserve}

func restore(values: Dictionary) -> void:
	# A restored life must not inherit sounds still playing from the previous shot.
	for child: Node in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.queue_free()
	owned = bool(values["owned"])
	chamber = int(values["chamber"])
	magazine = int(values["magazine"])
	reserve = int(values["reserve"])
	state = State.READY
	_timer = 0.0
	_recoil = 0.0
	_flash_time = 0.0
	_wall_raise = 0.0
	_bob_time = 0.0
	position = HIP
	rotation = Vector3(0, 0.12, 0)
	_slide.position.z = 0.027 if chamber == 0 else 0.0
	_mag.position = Vector3.ZERO
	_left.position = Vector3.ZERO
	_flash.visible = false
	_flare.visible = false
	visible = owned
	_cancel_pending(0, &"restore")
	_notify()

func _chamber_next() -> void:
	if chamber == 0 and magazine > 0:
		chamber = 1
		magazine -= 1

func _notify() -> void:
	ammunition_changed.emit(chamber + magazine, reserve, owned)

func _cancel_pending(_generation: int, _reason: StringName) -> void:
	_pending_fire = -1
	_pending_reload = -1

func _sound(stream: AudioStream) -> void:
	# Each short layer keeps its tail when the following mechanical/shot layer starts.
	var voice := AudioStreamPlayer.new()
	voice.bus = &"Weapons"
	voice.volume_db = -5.0
	voice.stream = stream
	add_child(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()

func _exit_tree() -> void:
	for child: Node in get_children():
		if child is AudioStreamPlayer:
			child.stop()

func _animate(delta: float) -> void:
	_recoil = move_toward(_recoil, 0.0, delta * 5.8)
	_flash_time = maxf(0.0, _flash_time - delta)
	_flash.visible = _flash_time > 0.0 and not _settings["reduced_flashes"]
	_flare.visible = _flash.visible and _wall_raise < 0.4
	var camera: Camera3D = wielder.camera
	var query := PhysicsRayQueryParameters3D.create(camera.global_position,
		camera.global_position - camera.global_basis.z * 0.70, 1, [wielder.get_rid()])
	var obstructed: bool = not get_world_3d().direct_space_state.intersect_ray(query).is_empty()
	_wall_raise = move_toward(_wall_raise, 1.0 if obstructed else 0.0, delta * 9.0)
	var speed: float = Vector2(wielder.velocity.x, wielder.velocity.z).length()
	_bob_time += delta * speed * 5.4
	var motion: float = float(_settings["head_bob"])
	var roll: float = 0.0
	var lower: float = 0.0
	if state == State.RELOADING:
		roll = sin(minf(_timer / 0.25, 1.0) * PI * 0.5) * minf((1.85 - _timer) / 0.35, 1.0)
		lower = roll * 0.035
	if state == State.EQUIPPING:
		lower = (1.0 - minf(_timer / 0.5, 1.0)) * 0.25
	position = HIP + Vector3(sin(_bob_time * 0.5) * 0.004 * motion - _wall_raise * 0.04,
		-lower + cos(_bob_time) * 0.003 * motion + _wall_raise * 0.09,
		_recoil * 0.026 + _wall_raise * 0.18)
	rotation = Vector3(_recoil * 0.11 + _wall_raise * 0.95 - (0.22 if wielder.sprinting else 0.0),
		0.12 + (0.3 if wielder.sprinting else 0.0), roll * -0.35)
	_slide.position.z = 0.035 * (1.0 - minf(_timer / 0.10, 1.0)) if state == State.CYCLING else (0.027 if chamber == 0 else 0.0)
	_mag.position.y = -sin(clampf((_timer - 0.2) / 0.78, 0.0, 1.0) * PI) * 0.20 if state == State.RELOADING else 0.0
	_left.position = Vector3(-0.015, -sin(clampf(_timer / 1.3, 0.0, 1.0) * PI) * 0.21, 0.025) if state == State.RELOADING else Vector3.ZERO
