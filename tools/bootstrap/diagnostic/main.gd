extends Node3D
## Diagnostic geometry and UI only. Not a game feature or production asset.

var _camera: Camera3D
var _lamp: OmniLight3D
var _label: Label
var _animation: AnimationPlayer
var _orbit: float = 0.38
var _elapsed: float = 0.0
var _capture_index: int = 0
var _output_dir: String = ""
var _initial_capture_done: bool = false
var _headless: bool = false


func _ready() -> void:
	_headless = DisplayServer.get_name() == "headless"
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	for index: int in range(arguments.size() - 1):
		if arguments[index] == "--output-dir":
			_output_dir = arguments[index + 1]
	var imported: PackedScene = load("res://generated/bootstrap.glb") as PackedScene
	if imported == null:
		push_error("Diagnostic GLB did not import")
		get_tree().quit(2)
		return
	var asset: Node3D = imported.instantiate() as Node3D
	add_child(asset)
	var mesh_count: int = asset.find_children("*", "MeshInstance3D", true, false).size()
	var players: Array[Node] = asset.find_children("*", "AnimationPlayer", true, false)
	if mesh_count != 3 or players.is_empty():
		push_error("Diagnostic meshes or animation missing")
		get_tree().quit(3)
		return
	_animation = players[0] as AnimationPlayer
	var clips: PackedStringArray = _animation.get_animation_list()
	for clip: String in clips:
		if clip != "RESET":
			_animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
			_animation.play(clip)
			break
	_log_event("import_verified", {"meshes": mesh_count, "clips": clips,
		"godot": Engine.get_version_info()["string"], "display": DisplayServer.get_name()})
	if _headless:
		get_tree().quit(0)
		return
	_build_stage()
	_update_camera()
	_log_event("native_ready", {"renderer": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"viewport": str(get_viewport().get_visible_rect().size)})


func _build_stage() -> void:
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.025, 0.034, 0.05)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.56, 0.65, 0.8)
	environment.ambient_light_energy = 0.3
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world: WorldEnvironment = WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var floor_mesh: PlaneMesh = PlaneMesh.new()
	floor_mesh.size = Vector2(12.0, 12.0)
	var floor_material: StandardMaterial3D = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.16, 0.19, 0.23)
	floor_material.roughness = 0.7
	floor_mesh.material = floor_material
	var floor_instance: MeshInstance3D = MeshInstance3D.new()
	floor_instance.mesh = floor_mesh
	add_child(floor_instance)
	_lamp = OmniLight3D.new()
	_lamp.position = Vector3(2.4, 3.8, 2.2)
	_lamp.light_color = Color(1.0, 0.9, 0.74)
	_lamp.light_energy = 5.0
	_lamp.omni_range = 10.0
	_lamp.shadow_enabled = true
	add_child(_lamp)
	var fill: DirectionalLight3D = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30.0, -130.0, 0.0)
	fill.light_color = Color(0.55, 0.7, 1.0)
	fill.light_energy = 0.7
	add_child(fill)
	_camera = Camera3D.new()
	_camera.fov = 45.0
	_camera.current = true
	add_child(_camera)
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)
	_label = Label.new()
	_label.position = Vector2(48.0, 42.0)
	_label.add_theme_font_size_override("font_size", 28)
	canvas.add_child(_label)
	_update_label()


func _process(delta: float) -> void:
	if _headless or _camera == null:
		return
	_elapsed += delta
	var direction: float = float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
	if not is_zero_approx(direction):
		_orbit += direction * delta
		_update_camera()
	if not _initial_capture_done and _elapsed >= 2.0:
		_initial_capture_done = true
		_capture("initial")


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	_log_event("native_key", {"physical_key": key.physical_keycode})
	match key.physical_keycode:
		KEY_F:
			_lamp.visible = not _lamp.visible
			_update_label()
			_log_event("lamp_changed", {"enabled": _lamp.visible})
		KEY_SPACE:
			_animation.speed_scale = 1.0 - _animation.speed_scale
			_update_label()
			_log_event("animation_changed", {"speed": _animation.speed_scale})
		KEY_F12:
			_capture("requested")
		KEY_ESCAPE:
			_log_event("exit", {})
			get_tree().quit()


func _update_camera() -> void:
	_camera.position = Vector3(sin(_orbit) * 5.8, 3.0, cos(_orbit) * 5.8)
	_camera.look_at(Vector3(0.0, 0.8, 0.0))


func _update_label() -> void:
	_label.text = "NULLSPACE · M0 TOOLCHAIN DIAGNOSTIC\nOriginal Blender GLB · 3 PBR materials · animated transform\nA / D: orbit    Space: pause animation    F: lamp    F12: capture    Esc: quit\nLamp: %s    Animation speed: %.0f\nDiagnostic only — no production quality claim" % [str(_lamp.visible), _animation.speed_scale]


func _capture(reason: String) -> void:
	if _output_dir.is_empty():
		return
	await RenderingServer.frame_post_draw
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(_output_dir)
	if directory_error != OK:
		push_error("Cannot create screenshot directory")
		return
	var path: String = _output_dir.path_join("viewport-%03d-%s.png" % [_capture_index, reason])
	_capture_index += 1
	var screenshot: Image = get_viewport().get_texture().get_image()
	var result: Error = screenshot.save_png(path)
	_log_event("capture", {"path": path, "error": result, "width": screenshot.get_width(),
		"height": screenshot.get_height(), "orbit": _orbit, "lamp": _lamp.visible})


func _log_event(event: String, fields: Dictionary) -> void:
	fields["event"] = event
	fields["milliseconds"] = Time.get_ticks_msec()
	print("NULLSPACE_BOOTSTRAP " + JSON.stringify(fields))
