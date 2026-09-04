extends Node3D
## Standalone inspection camera only. This is not the production player controller.
## WASD walk, Shift faster, mouse look, Escape release, F inspection flashlight,
## 1-8 fixed review views, P original-resolution still, L fixture states.

const ROOM: PackedScene = preload("res://environment/m4_reference_room.tscn")
const EYE_HEIGHT: float = 1.64
var _room: NullspaceM4ReferenceRoom
var _body: CharacterBody3D
var _camera: Camera3D
var _flashlight: SpotLight3D
var _pitch: float = 0.0
var _light_state: int = 0
var _frames: int = 0
var _elapsed: float = 0.0
var _frame_samples: Array[float] = []
var _input_events: int = 0
var _capture_count: int = 0
var _world: WorldEnvironment
var _measurement_elapsed: float = 0.0
var _gpu_samples: Array[float] = []
var _cpu_samples: Array[float] = []
var _input_trace: FileAccess


func _ready() -> void:
	_world = WorldEnvironment.new()
	_world.environment = EnvironmentSurfaceLibrary.make_reference_environment()
	add_child(_world)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	var trace_directory: String = OS.get_environment("NULLSPACE_M4_CAPTURE_DIR")
	if not trace_directory.is_empty():
		DirAccess.make_dir_recursive_absolute(trace_directory)
		_input_trace = FileAccess.open(trace_directory.path_join("accepted_input_trace.jsonl"), FileAccess.WRITE)
	_room = ROOM.instantiate() as NullspaceM4ReferenceRoom
	add_child(_room)
	_body = CharacterBody3D.new()
	_body.name = "InspectionCameraBody"
	_body.collision_layer = 2
	_body.collision_mask = 1
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.26
	capsule.height = 1.78
	collider.shape = capsule
	collider.position.y = 0.89
	_body.add_child(collider)
	add_child(_body)
	_camera = Camera3D.new()
	_camera.name = "InspectionCamera"
	_camera.position.y = EYE_HEIGHT
	_camera.fov = 58.24 # 88 degrees horizontally at16:9, explicit Godot vertical convention.
	_camera.near = 0.045
	_camera.far = 80.0
	_body.add_child(_camera)
	_flashlight = SpotLight3D.new()
	_flashlight.position = Vector3(0.13, -0.12, 0.0)
	_flashlight.light_energy = 3.2
	_flashlight.light_color = Color(0.91, 0.95, 1.0)
	_flashlight.spot_range = 12.0
	_flashlight.spot_angle = 31.0
	_flashlight.spot_attenuation = 1.4
	_flashlight.spot_angle_attenuation = 1.1
	_flashlight.shadow_enabled = true
	_flashlight.visible = false
	_camera.add_child(_flashlight)
	_set_view(1)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print("M4_PREVIEW_READY Forward+; native WASD/mouse inspection; no campaign or gameplay claims")
	print("M4_CONTROLS WASD Shift mouse Esc F flashlight 1-8 review views P still L fixture state; F7 SSIL F8 SSAO F9 shadows F10 TAA diagnostic toggles")


func _unhandled_input(event: InputEvent) -> void:
	_input_events += 1
	_trace_input(event)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_body.rotate_y(-event.screen_relative.x * 0.0017)
		_pitch = clampf(_pitch - event.screen_relative.y * 0.0017, -1.32, 1.32)
		_camera.rotation.x = _pitch
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_F: _flashlight.visible = not _flashlight.visible
			KEY_P: _capture()
			KEY_L:
				_light_state = (_light_state + 1) % 5
				for fixture: NullspaceFluorescentFixture in _room.fixtures:
					fixture.set_fixture_state(_light_state as NullspaceFluorescentFixture.State)
				print("M4_FIXTURE_STATE ", _light_state)
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8: _set_view(int(event.physical_keycode) - KEY_0)
			KEY_F7:
				_world.environment.ssil_enabled = not _world.environment.ssil_enabled
				_reset_measurement()
			KEY_F8:
				_world.environment.ssao_enabled = not _world.environment.ssao_enabled
				_reset_measurement()
			KEY_F9:
				for fixture: NullspaceFluorescentFixture in _room.fixtures:
					var direct_light := fixture.get_node("FluorescentDirect") as OmniLight3D
					direct_light.shadow_enabled = false
				_reset_measurement()
			KEY_F10:
				get_viewport().use_taa = not get_viewport().use_taa
				_reset_measurement()


func _trace_input(event: InputEvent) -> void:
	if not _input_trace:
		return
	var trace: Dictionary = {"frame": _frames, "time_us": Time.get_ticks_usec(), "device": event.device,
		"class": event.get_class(), "mouse_mode": Input.mouse_mode, "window_focus": get_window().has_focus()}
	if event is InputEventMouseMotion:
		trace["relative"] = [event.relative.x, event.relative.y]
		trace["screen_relative"] = [event.screen_relative.x, event.screen_relative.y]
	elif event is InputEventMouseButton:
		trace["button"] = event.button_index
		trace["pressed"] = event.pressed
	elif event is InputEventKey:
		# Log accepted game/diagnostic controls only, never text or unrelated typed content.
		var accepted: Array[int] = [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SHIFT, KEY_ESCAPE, KEY_F, KEY_P, KEY_L,
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_F7, KEY_F8, KEY_F9, KEY_F10]
		if not event.physical_keycode in accepted:
			return
		trace["physical_keycode"] = event.physical_keycode
		trace["key_name"] = OS.get_keycode_string(event.physical_keycode)
		trace["pressed"] = event.pressed
		trace["echo"] = event.echo
	_input_trace.store_line(JSON.stringify(trace))
	_input_trace.flush()


func _physics_process(delta: float) -> void:
	var direction := Vector3.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		direction.x = float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
		direction.z = float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
		direction = (_body.basis * direction).normalized()
	var speed: float = 4.4 if Input.is_physical_key_pressed(KEY_SHIFT) else 2.8
	_body.velocity.x = direction.x * speed
	_body.velocity.z = direction.z * speed
	_body.velocity.y = -1.0 if _body.is_on_floor() else _body.velocity.y - 9.8 * delta
	_body.move_and_slide()


func _process(delta: float) -> void:
	_frames += 1
	_elapsed += delta
	_measurement_elapsed += delta
	if _measurement_elapsed > 3.0:
		_frame_samples.append(delta * 1000.0)
		_gpu_samples.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()))
		_cpu_samples.append(RenderingServer.viewport_get_measured_render_time_cpu(get_viewport().get_viewport_rid()) + RenderingServer.get_frame_setup_time_cpu())
	if _frames % 600 == 0:
		print("M4_SAMPLE frames=", _frames, " inputs=", _input_events, " camera=", _camera.global_position,
			" fps=", Engine.get_frames_per_second(), " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			" objects=", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			" primitives=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))


func _set_view(index: int) -> void:
	var positions: Array[Vector3] = [Vector3(2.70, 0.02, -0.85), Vector3(4.78, 0.02, -5.46),
		Vector3(-4.95, 0.02, -10.70), Vector3(-3.42, 0.02, -12.62),
		Vector3(0.10, 0.02, -3.68), Vector3(4.80, 0.02, -11.36),
		Vector3(1.65, 0.02, -4.96), Vector3(-5.55, 0.02, -10.40)]
	var targets: Array[Vector3] = [Vector3(-1.1, 1.57, -8.8), Vector3(0.2, 1.52, -11.30),
		Vector3(-6.02, 1.22, -10.73), Vector3(-3.6, 0.3, -10.90),
		Vector3(-2.79, 2.36, -3.40), Vector3(4.27, 2.70, -13.11),
		Vector3(0.698, 0.13, -6.014), Vector3(-6.02, 1.58, -10.65)]
	_body.position = positions[index - 1]
	_body.rotation = Vector3.ZERO
	_camera.rotation = Vector3.ZERO
	_camera.look_at(targets[index - 1], Vector3.UP)
	_body.rotation.y = _camera.rotation.y
	_pitch = _camera.rotation.x
	_camera.rotation = Vector3(_pitch, 0, 0)
	_body.velocity = Vector3.ZERO
	_reset_measurement()
	print("M4_REVIEW_VIEW ", index, " camera=", _camera.global_position)


func _reset_measurement() -> void:
	_measurement_elapsed = 0.0
	_frame_samples.clear()
	_gpu_samples.clear()
	_cpu_samples.clear()
	if _world:
		print("M4_RENDER_STATE ", _render_state())


func _render_state() -> Dictionary:
	var shadows: int = 0
	for fixture: NullspaceFluorescentFixture in _room.fixtures:
		var direct_light := fixture.get_node("FluorescentDirect") as OmniLight3D
		if direct_light.shadow_enabled:
			shadows += 1
	return {"ssao": _world.environment.ssao_enabled, "ssil": _world.environment.ssil_enabled,
		"shadowed_fixtures": shadows, "taa": get_viewport().use_taa, "scale_3d": get_viewport().scaling_3d_scale}


func _percentile(values: Array[float], percent: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted: Array[float] = values.duplicate()
	sorted.sort()
	return sorted[mini(int(sorted.size() * percent), sorted.size() - 1)]


func _capture() -> void:
	await RenderingServer.frame_post_draw
	_capture_count += 1
	var directory: String = OS.get_environment("NULLSPACE_M4_CAPTURE_DIR")
	if directory.is_empty():
		directory = ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_recursive_absolute(directory)
	var stem: String = directory.path_join("m4_%03d" % _capture_count)
	var image: Image = get_viewport().get_texture().get_image()
	var result: Error = image.save_png(stem + ".png")
	var metadata: Dictionary = {"timestamp_utc": Time.get_datetime_string_from_system(true),
		"frame": _frames, "elapsed_s": _elapsed, "image_size": [image.get_width(), image.get_height()],
		"camera_position": var_to_str(_camera.global_position), "camera_rotation": var_to_str(_camera.global_rotation),
		"godot_version": Engine.get_version_info(), "rendering_method": RenderingServer.get_current_rendering_method(),
		"input_events": _input_events, "input_provenance": "Native user/XTEST events; view presets are inspection shortcuts, not campaign play.",
		"measurement_elapsed_s": _measurement_elapsed, "sample_count": _frame_samples.size(), "render_state": _render_state(),
		"frame_time_ms_p50": _percentile(_frame_samples, 0.5), "frame_time_ms_p95": _percentile(_frame_samples, 0.95),
		"gpu_time_ms_p50": _percentile(_gpu_samples, 0.5), "gpu_time_ms_p95": _percentile(_gpu_samples, 0.95),
		"render_cpu_time_ms_p50": _percentile(_cpu_samples, 0.5), "render_cpu_time_ms_p95": _percentile(_cpu_samples, 0.95),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"video_memory_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		"save_result": result}
	var file: FileAccess = FileAccess.open(stem + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(metadata, "\t"))
	print("M4_CAPTURE ", stem, " result=", result)
