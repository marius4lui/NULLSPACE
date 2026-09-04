extends Node3D
## Instrumented input/render/audio fixture. It is deliberately not production art.

const AUDIO_RATE: float = 48000.0
const WALK_SPEED: float = 2.0
const SPRINT_SPEED: float = 4.0
const LOOK_SCALE: float = 0.003
var _camera: Camera3D
var _label: Label
var _flash: ColorRect
var _audio: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _events: FileAccess
var _mode: String = "menu"
var _position: Vector3 = Vector3(0.0, 1.8, 7.0)
var _yaw: float = 0.0
var _pitch: float = 0.0
var _mouse_total: Vector2 = Vector2.ZERO
var _shots: int = 0
var _flash_remaining: float = 0.0
var _pulse_samples: int = 0
var _sample_index: int = 0
var _sample_timer: float = 0.0
var _last_motion: Vector2 = Vector2.ZERO


func _ready() -> void:
	var path: String = OS.get_environment("NULLSPACE_QA_RUN_DIR")
	_events = FileAccess.open(path.path_join("fixture-events.jsonl"), FileAccess.WRITE)
	if _events == null:
		push_error("Fixture requires a writable NULLSPACE_QA_RUN_DIR")
		get_tree().quit(2)
		return
	_build_view()
	_build_audio()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_log("ready", {"display": DisplayServer.get_name(), "adapter": RenderingServer.get_video_adapter_name(),
		"window_size": _vector2(DisplayServer.window_get_size()), "user_data_dir": OS.get_user_data_dir()})
	get_window().focus_entered.connect(func() -> void: _log("focus_entered"))
	get_window().focus_exited.connect(func() -> void: _log("focus_exited"))
	get_tree().auto_accept_quit = true


func _build_view() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.08, 0.13)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.7, 0.8, 1.0)
	environment.ambient_light_energy = 0.5
	world.environment = environment
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40.0, -20.0, 0.0)
	light.light_energy = 1.2
	add_child(light)
	_box(Vector3(0.0, -0.15, -6.0), Vector3(40.0, 0.3, 40.0), Color(0.11, 0.16, 0.23))
	for index: int in range(8):
		var color := Color(0.08, 0.65, 0.8) if index % 2 == 0 else Color(0.85, 0.38, 0.12)
		_box(Vector3(-4.0, 1.0, -float(index) * 3.0), Vector3(1.0, 2.0, 1.0), color)
		_box(Vector3(4.0, 1.0, -float(index) * 3.0), Vector3(1.0, 2.0, 1.0), color)
		_box(Vector3(0.0, 0.005, -float(index) * 3.0), Vector3(8.0, 0.025, 0.15), Color(0.45, 0.55, 0.7))
	_camera = Camera3D.new()
	_camera.fov = 80.0
	_camera.position = _position
	add_child(_camera)
	_camera.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.position = Vector2(24, 24)
	panel.size = Vector2(1160, 250)
	panel.color = Color(0.015, 0.025, 0.05, 0.92)
	layer.add_child(panel)
	_label = Label.new()
	_label.position = Vector2(45, 40)
	_label.add_theme_font_size_override("font_size", 27)
	layer.add_child(_label)
	_flash = ColorRect.new()
	_flash.position = Vector2(1720, 40)
	_flash.size = Vector2(160, 160)
	_flash.color = Color(0.08, 0.08, 0.08)
	layer.add_child(_flash)
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.position = Vector2(950, 520)
	crosshair.add_theme_font_size_override("font_size", 30)
	layer.add_child(crosshair)


func _box(at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	mesh.material_override = material
	add_child(mesh)


func _build_audio() -> void:
	_audio = AudioStreamPlayer.new()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = AUDIO_RATE
	generator.buffer_length = 0.06
	_audio.stream = generator
	add_child(_audio)
	_audio.play()
	_playback = _audio.get_stream_playback() as AudioStreamGeneratorPlayback


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		_log("key", {"keycode": key.keycode, "physical_keycode": key.physical_keycode,
			"pressed": key.pressed, "echo": key.echo})
		if key.pressed and not key.echo:
			if key.keycode == KEY_ENTER:
				_set_mode("playing")
			elif key.keycode == KEY_ESCAPE:
				_set_mode("playing" if _mode == "paused" else "paused")
			elif key.keycode == KEY_TAB:
				_set_mode("menu")
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		_last_motion = motion.relative
		_log("mouse_motion", {"relative": _vector2(motion.relative), "captured": Input.mouse_mode == Input.MOUSE_MODE_CAPTURED})
		if _mode == "playing" and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_mouse_total += motion.relative
			_yaw -= motion.relative.x * LOOK_SCALE
			_pitch = clampf(_pitch - motion.relative.y * LOOK_SCALE, -1.0, 1.0)
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		var accepted: bool = button.pressed and button.button_index == MOUSE_BUTTON_LEFT and _mode == "playing"
		_log("mouse_button", {"button": button.button_index, "pressed": button.pressed, "accepted": accepted})
		if accepted:
			_shots += 1
			_flash_remaining = 0.2
			_pulse_samples = int(AUDIO_RATE * 0.2)
			_log("fire", {"shot": _shots, "position": _vector3(_position)})


func _set_mode(value: String) -> void:
	_mode = value
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value == "playing" else Input.MOUSE_MODE_VISIBLE
	_log("mode", {"value": value, "mouse_mode": Input.mouse_mode})


func _physics_process(delta: float) -> void:
	var w: bool = Input.is_physical_key_pressed(KEY_W)
	var a: bool = Input.is_physical_key_pressed(KEY_A)
	var s: bool = Input.is_physical_key_pressed(KEY_S)
	var d: bool = Input.is_physical_key_pressed(KEY_D)
	var sprint: bool = Input.is_physical_key_pressed(KEY_SHIFT)
	var direction := Vector3(float(d) - float(a), 0.0, float(s) - float(w))
	if _mode == "playing":
		direction = direction.normalized().rotated(Vector3.UP, _yaw)
		_position += direction * (SPRINT_SPEED if sprint else WALK_SPEED) * delta
	_camera.position = _position
	_camera.rotation = Vector3(_pitch, _yaw, 0.0)
	_sample_timer += delta
	if _sample_timer >= 0.1:
		_sample_timer = 0.0
		_log("state", {"mode": _mode, "position": _vector3(_position), "yaw": _yaw, "pitch": _pitch,
			"keys": {"w": w, "a": a, "s": s, "d": d, "shift": sprint}, "shots": _shots,
			"mouse_total": _vector2(_mouse_total), "captured": Input.mouse_mode == Input.MOUSE_MODE_CAPTURED,
			"focused": DisplayServer.window_is_focused(), "fps": Engine.get_frames_per_second(),
			"audio_skips": _playback.get_skips()})


func _process(delta: float) -> void:
	_flash_remaining = maxf(_flash_remaining - delta, 0.0)
	_flash.color = Color.WHITE if _flash_remaining > 0.0 else Color(0.08, 0.08, 0.08)
	_label.text = "NULLSPACE · NATIVE QA FIXTURE · NOT PRODUCTION\nMode: %s    Captured: %s    Shots: %d\nWASD + Shift move · Mouse look/fire · Enter play · Esc pause · Tab menu\nPosition: %.2f / %.2f / %.2f    Look: %.3f / %.3f\nRelative mouse total: %.0f / %.0f    Stereo: left 440 Hz / right 660 Hz" % [
		_mode, str(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED), _shots,
		_position.x, _position.y, _position.z, _yaw, _pitch, _mouse_total.x, _mouse_total.y]
	var frames: int = _playback.get_frames_available()
	for _index: int in range(frames):
		var t: float = float(_sample_index) / AUDIO_RATE
		var left: float = 0.025 * sin(TAU * 440.0 * t)
		var right: float = 0.025 * sin(TAU * 660.0 * t)
		if _pulse_samples > 0:
			left += 0.32 * sin(TAU * 1200.0 * t)
			right += 0.32 * sin(TAU * 1800.0 * t)
			_pulse_samples -= 1
		_playback.push_frame(Vector2(left, right))
		_sample_index += 1


func _log(kind: String, values: Dictionary = {}) -> void:
	var row: Dictionary = values.duplicate()
	row["event"] = kind
	row["utc_unix"] = Time.get_unix_time_from_system()
	row["monotonic_usec"] = Time.get_ticks_usec()
	row["frame"] = Engine.get_process_frames()
	row["physics_frame"] = Engine.get_physics_frames()
	_events.store_line(JSON.stringify(row))
	_events.flush()


func _vector2(value: Vector2) -> Array[float]:
	return [value.x, value.y]


func _vector3(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]
