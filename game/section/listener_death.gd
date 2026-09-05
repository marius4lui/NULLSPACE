class_name ListenerDeath
extends Node3D
## One concrete, interruptible death on the existing Listener rig. The paused world
## cannot move doors, weapons or bodies while this node owns the camera/animation.
const DURATION: float = 2.6
const IMPACT: float = 1.46
const SKIP_AFTER: float = 0.65
const THUD: AudioStream = preload("res://assets/audio/room/listener_step_0.wav")
const HURT: AudioStream = preload("res://assets/audio/room/hurt.wav")
var section: NullspaceSection
var active: bool = false
var pulling: bool = false
var elapsed: float = 0
var blood_enabled: bool = false
var _attacker: Listener
var _start: Transform3D
var _has_camera_snapshot: bool = false
var _near: Vector3
var _low: Vector3
var _look: Basis
var _struck: bool = false
var _duration: float = DURATION
var _voice: AudioStreamPlayer
var _drops: Array[MeshInstance3D] = []
var _blood_origin: Vector3
var _blood_basis: Basis
var _animation_mode: int = 0
var _camera_shape: SphereShape3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camera_shape = SphereShape3D.new()
	_camera_shape.radius = .18 # Covers the near plane at the maximum supported FOV.
	_voice = AudioStreamPlayer.new()
	_voice.bus = &"Player"
	add_child(_voice)
	var mesh := SphereMesh.new()
	mesh.radius = .0045
	mesh.height = .015
	mesh.radial_segments = 6
	mesh.rings = 3
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(.23, .012, .009)
	material.roughness = .75
	mesh.material = material
	for i: int in 12:
		var drop := MeshInstance3D.new()
		drop.mesh = mesh
		drop.scale = Vector3.ONE * (.45 + absf(sin(i * 1.71)) * .65)
		drop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		drop.visible = false
		add_child(drop)
		_drops.append(drop)
	section.player.lethal_hit.connect(begin)
	GameFlow.state_changed.connect(_flow_changed)

func begin(attacker: Listener) -> void:
	if active or GameFlow.state != NullGameFlow.State.PLAYING or section.player.health > 0:
		return
	_start = section.player.camera.global_transform
	_has_camera_snapshot = true
	# A supplied cause is not sufficient: require this scene's committed, valid hit.
	_attacker = attacker if attacker == section.listener and attacker.state == Listener.State.ATTACKING \
		and attacker._attack_applied and attacker._clear_attack() else null
	blood_enabled = bool(SettingsManager.get_value("blood_effects"))
	pulling = _attacker != null and SettingsSchema.death_motion_allowed(SettingsManager.snapshot())
	if pulling:
		_near = _attacker.global_position - _attacker.global_basis.z * .82 + Vector3.UP * 1.48
		_low = _near - Vector3.UP * .30
		var face: Vector3 = _attacker.global_position + Vector3.UP * 1.97
		var toward: Vector3 = (face - _start.origin).normalized()
		# No large forced turn when the player is looking away or down.
		pulling = (-_start.basis.z).dot(toward) > .72 and _clear_path(_start.origin, _near) and _clear_path(_near, _low) and _clear_grab_space()
		_look = Basis.looking_at(face - _near, Vector3.UP).rotated((face - _near).normalized(), .035)
		pulling = pulling and _start.origin.y >= _near.y and _clear_path(_near, _near - _look.z * .025)
	_duration = DURATION if pulling else .85
	elapsed = 0
	_struck = false
	active = true
	section.pistol.visible = false
	section.sound.reset()
	if _attacker != null:
		_animation_mode = _attacker.animation.callback_mode_process
		_attacker.animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		_attacker.animation.speed_scale = 1
		_attacker.animation.play(&"death_grab" if pulling else &"death_local", .08)
		_attacker.animation.advance(0)
	GameFlow.begin_death()
	_play(THUD, -14, .82)
	Telemetry.record(&"death_sequence_started", {"listener": _attacker != null, "pull": pulling,
		"blood": blood_enabled, "duration": _duration, "camera_start": _array(_start.origin)})

func _clear_grab_space() -> bool:
	# The arms extend beyond the locomotion capsule. A clear camera path alone
	# still allowed the left/right reach to enter the actual archive side wall.
	var box := BoxShape3D.new()
	box.size = Vector3(1.35, 1.2, 1.3)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = box
	query.transform = Transform3D(_attacker.global_basis,
		_attacker.global_position - _attacker.global_basis.z * .58 + Vector3.UP * 1.65)
	query.collision_mask = 1
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func _clear_path(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _camera_shape
	query.transform = Transform3D(Basis.IDENTITY, from)
	query.collision_mask = 1 | 4
	query.exclude = [section.player.get_rid()]
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if not space.intersect_shape(query, 1).is_empty(): return false
	query.motion = to - from
	var sweep: PackedFloat32Array = space.cast_motion(query)
	if sweep.size() != 2 or sweep[0] < 1: return false
	query.transform.origin = to
	query.motion = Vector3.ZERO
	return space.intersect_shape(query, 1).is_empty()

func _process(delta: float) -> void:
	if not active: return
	elapsed = minf(elapsed + delta, _duration)
	if is_instance_valid(_attacker): _attacker.animation.advance(delta)
	var camera: Camera3D = section.player.camera
	if pulling:
		var pull: float = smoothstep(.20, 1.05, elapsed)
		var collapse: float = smoothstep(1.82, 2.40, elapsed)
		camera.global_position = _start.origin.lerp(_near, pull).lerp(_low, collapse)
		camera.global_basis = _start.basis.slerp(_look, pull)
		# A small single shove; no oscillation, flash or extra forced rotation.
		var shove: float = maxf(0, 1 - absf(elapsed - (IMPACT + .045)) / .045) * .025
		camera.global_position -= camera.global_basis.z * shove
	var impact_time: float = IMPACT if pulling else .16
	if not _struck and elapsed >= impact_time:
		_struck = true
		_play(HURT, -15, .88)
		_blood_basis = camera.global_basis
		_blood_origin = camera.global_position - camera.global_basis.z * .44 - camera.global_basis.y * .18
		Telemetry.record(&"death_impact", {"elapsed": elapsed, "blood": blood_enabled})
	var blood_age: float = elapsed - impact_time
	for i: int in _drops.size():
		var drop: MeshInstance3D = _drops[i]
		drop.visible = blood_enabled and blood_age >= 0 and blood_age < .40
		if drop.visible:
			var direction := Vector3(sin(i * 2.4) * .52, .12 + absf(sin(i * 1.73)) * .62,
				-.10 - absf(cos(i * 2.17)) * .22)
			drop.global_position = _blood_origin + _blood_basis * direction * blood_age + Vector3.DOWN * blood_age * blood_age
	var blood: float = (1.0 - smoothstep(.04, .55, blood_age)) if blood_enabled and blood_age >= 0 else 0.0
	var fade: float = smoothstep(1.95, DURATION, elapsed) if pulling else smoothstep(.10, .85, elapsed)
	section.menu.set_death_effects(fade, blood, elapsed >= SKIP_AFTER and pulling)
	if elapsed >= _duration: _finish(false)

func _unhandled_input(event: InputEvent) -> void:
	if not active: return
	if event.is_action_pressed(&"ui_accept", false) or event.is_action_pressed(&"pause", false):
		get_viewport().set_input_as_handled()
		if elapsed >= SKIP_AFTER: _finish(true)

func _finish(skipped: bool) -> void:
	if not active: return
	active = false
	_voice.stop()
	for drop: MeshInstance3D in _drops: drop.visible = false
	section.menu.set_death_effects(0, 0, false)
	Telemetry.record(&"death_sequence_finished", {"elapsed": elapsed, "skipped": skipped,
		"camera_end": _array(section.player.camera.global_position)})
	GameFlow.finish_death()

func reset() -> void:
	if _has_camera_snapshot:
		section.player.camera.global_transform = _start
	_has_camera_snapshot = false
	active = false
	elapsed = 0
	pulling = false
	_voice.stop()
	for drop: MeshInstance3D in _drops: drop.visible = false
	if is_instance_valid(_attacker):
		_attacker.animation.callback_mode_process = _animation_mode
		_attacker.animation.stop()
	_attacker = null
	section.menu.set_death_effects(0, 0, false)

func _flow_changed(_previous: int, current: int, _reason: StringName) -> void:
	if current in [NullGameFlow.State.LOADING, NullGameFlow.State.MENU]: reset()

func _play(stream: AudioStream, volume: float, pitch: float) -> void:
	_voice.stream = stream
	_voice.volume_db = volume
	_voice.pitch_scale = pitch
	_voice.play()

func _array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]
