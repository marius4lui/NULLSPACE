class_name SectionPlayer
extends CharacterBody3D
## Concrete section player. Physics owns movement/steps; InputGate owns every control.

signal prompt_changed(text: String)
signal flashlight_changed(enabled: bool)

const STANDING_HEIGHT: float = 1.78
const CROUCHED_HEIGHT: float = 1.10
const BODY_RADIUS: float = 0.26
const INTERACTION_REACH: float = 2.1
const TUNING: GameTuning = preload("res://data/default_tuning.tres")

@onready var collider: CollisionShape3D = $CollisionShape3D
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight

var health: float = 100.0
var stamina: float = 1.0
var crouched: bool = false
var sprinting: bool = false
var travelled: float = 0.0
var steps: int = 0
var _height: float = STANDING_HEIGHT
var _pitch: float = 0.0
var _exhausted: bool = false
var _recovery_delay: float = 0.0
var _step_distance: float = 0.0
var _bob_phase: float = 0.0
var _injury: float = 0.0
var _pending_interaction: int = -1
var _prompt: String = ""
var _sample_elapsed: float = 0.0
var _settings: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.24
	floor_max_angle = deg_to_rad(44.0)
	safe_margin = 0.002
	SettingsManager.settings_changed.connect(_apply_settings)
	InputGate.invalidated.connect(_invalidate_controls)
	get_viewport().size_changed.connect(_update_fov)
	_apply_settings(SettingsManager.snapshot())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion: Vector2 = InputGate.look_delta(event)
		rotation.y -= motion.x
		_pitch = clampf(_pitch - motion.y, -1.42, 1.42)
		head.rotation.x = _pitch
	if InputGate.accept_press(event, &"flashlight"):
		flashlight.visible = not flashlight.visible
		flashlight_changed.emit(flashlight.visible)
		Telemetry.record(&"player_flashlight", {"enabled": flashlight.visible})
	if InputGate.accept_press(event, &"interact"):
		_pending_interaction = InputGate.generation

func _physics_process(delta: float) -> void:
	if GameFlow.state != NullGameFlow.State.PLAYING:
		return
	_update_posture(delta)
	var input: Vector2 = InputGate.movement_vector()
	if _exhausted and stamina >= 0.25:
		_exhausted = false
	sprinting = InputGate.pressed(&"sprint") and input.length_squared() > 0.01 and not crouched and not _exhausted
	var speed: float = TUNING.crouch_speed if crouched else (TUNING.sprint_speed if sprinting else TUNING.walk_speed)
	var wish: Vector3 = global_basis * Vector3(input.x, 0.0, input.y) * speed
	var horizontal: Vector2 = Vector2(velocity.x, velocity.z)
	horizontal = horizontal.move_toward(Vector2(wish.x, wish.z), (TUNING.acceleration if input != Vector2.ZERO else TUNING.braking) * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y
	velocity.y = -0.5 if is_on_floor() else velocity.y - 18.0 * delta
	var previous: Vector3 = global_position
	move_and_slide()
	var moved: float = Vector2(global_position.x - previous.x, global_position.z - previous.z).length()
	travelled += moved
	if sprinting and moved > 0.002 and is_on_floor():
		stamina = maxf(0.0, stamina - delta * 0.18)
		_recovery_delay = 0.65
		if stamina <= 0.0:
			_exhausted = true
	else:
		_recovery_delay = maxf(0.0, _recovery_delay - delta)
		if _recovery_delay == 0.0:
			stamina = minf(1.0, stamina + delta * 0.14)
	if is_on_floor() and moved > 0.0001:
		_step_distance += moved
		_bob_phase += moved * (6.7 if crouched else 5.4)
		var stride: float = 0.88 if crouched else (1.65 if sprinting else 1.32)
		if _step_distance >= stride:
			_step_distance = fmod(_step_distance, stride)
			_emit_step()
	_update_camera(delta, moved / maxf(delta, 0.00001))
	var target: SectionLightSwitch = interaction_target()
	var text: String = target.prompt() if target != null and InputGate.accepts_input() else ""
	if text != _prompt:
		_prompt = text
		prompt_changed.emit(text)
	if _pending_interaction >= 0:
		var valid: bool = InputGate.accepts_generation(_pending_interaction)
		_pending_interaction = -1
		if valid and target != null:
			target.use()
	_sample_elapsed += delta
	if _sample_elapsed >= 0.2:
		_sample_elapsed = 0.0
		Telemetry.record(&"player_pose", {"position": [global_position.x, global_position.y, global_position.z],
			"yaw": rotation.y, "pitch": _pitch, "speed": moved / delta, "crouched": crouched,
			"height": _height, "sprinting": sprinting, "stamina": stamina, "health": health,
			"travelled": travelled, "steps": steps, "flashlight": flashlight.visible})

func _update_posture(delta: float) -> void:
	var wanted: float = CROUCHED_HEIGHT if InputGate.pressed(&"crouch") else STANDING_HEIGHT
	var next: float = move_toward(_height, wanted, 4.2 * delta)
	if next <= _height or has_clearance(next):
		_height = next
		(collider.shape as CapsuleShape3D).height = _height
		collider.position.y = _height * 0.5
	crouched = _height < STANDING_HEIGHT - 0.001

func has_clearance(height: float = STANDING_HEIGHT) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = BODY_RADIUS
	shape.height = height
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(global_basis, global_position + Vector3.UP * (height * 0.5 + 0.012))
	query.collision_mask = 1
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func interaction_target() -> SectionLightSwitch:
	var start: Vector3 = camera.global_position
	var query := PhysicsRayQueryParameters3D.create(start, start - camera.global_basis.z * INTERACTION_REACH, 1, [get_rid()])
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return hit.get("collider") as SectionLightSwitch

func restore_at(anchor: Transform3D, values: Dictionary) -> bool:
	global_transform = anchor
	velocity = Vector3.ZERO
	_height = STANDING_HEIGHT
	(collider.shape as CapsuleShape3D).height = _height
	collider.position.y = _height * 0.5
	_pitch = 0.0
	head.rotation = Vector3.ZERO
	head.position = Vector3(0.0, _height - 0.14, 0.0)
	camera.position = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	health = float(values["health"])
	stamina = float(values["stamina"])
	flashlight.visible = bool(values["flashlight_enabled"])
	flashlight_changed.emit(flashlight.visible)
	_exhausted = stamina <= 0.0
	_recovery_delay = 0.0
	crouched = false
	sprinting = false
	travelled = 0.0
	steps = 0
	_injury = 0.0
	_invalidate_controls(InputGate.generation, &"restore")
	return has_clearance()

func take_damage(amount: float) -> void:
	if GameFlow.state != NullGameFlow.State.PLAYING or amount <= 0.0 or not is_finite(amount):
		return
	var actual: float = minf(amount, health)
	health -= actual
	_injury = 0.32
	EventHub.gameplay_metric.emit(&"damage", {"amount": actual})
	if health <= 0.0:
		GameFlow.die()

func _update_camera(delta: float, speed: float) -> void:
	_injury = maxf(0.0, _injury - delta)
	var bob: float = float(_settings["head_bob"])
	var shake: float = float(_settings["camera_shake"])
	var moving: float = minf(speed / TUNING.walk_speed, 1.3) if is_on_floor() else 0.0
	var time: float = SimulationClock.sample().elapsed_seconds
	head.position.y = _height - 0.14
	camera.position = Vector3(sin(_bob_phase * 0.5) * 0.007 * moving,
		cos(_bob_phase) * 0.009 * moving + sin(time * 1.7) * 0.002, 0.0) * bob
	camera.rotation.z = sin(time * 42.0) * _injury * 0.025 * shake

func _emit_step() -> void:
	steps += 1
	var stamp: SimulationStamp = SimulationClock.sample()
	var sound := SoundEvent.new()
	sound.event_id = "player_step_%s_%s" % [stamp.epoch, steps]
	sound.source_id = &"section_player"
	sound.room_id = &"a_01"
	sound.kind = &"crouch_step" if crouched else (&"sprint_step" if sprinting else &"walk_step")
	sound.position = global_position
	sound.intensity = 0.06 if crouched else (0.48 if sprinting else 0.18)
	sound.simulation_seconds = stamp.elapsed_seconds
	sound.simulation_epoch = stamp.epoch
	sound.monotonic_usec = Time.get_ticks_usec()
	EventHub.submit_sound(sound)
	Telemetry.record(&"player_step", {"id": sound.event_id, "kind": sound.kind, "intensity": sound.intensity})

func _invalidate_controls(_generation: int, _reason: StringName) -> void:
	velocity = Vector3.ZERO
	_pending_interaction = -1
	_step_distance = 0.0
	_bob_phase = 0.0
	_prompt = ""
	prompt_changed.emit("")

func _apply_settings(values: Dictionary) -> void:
	_settings = values
	_update_fov()

func _update_fov() -> void:
	if not is_instance_valid(camera) or _settings.is_empty():
		return
	var size: Vector2 = get_viewport().get_visible_rect().size
	camera.fov = SettingsSchema.vertical_fov(float(_settings["horizontal_fov"]), size.x / maxf(size.y, 1.0))
