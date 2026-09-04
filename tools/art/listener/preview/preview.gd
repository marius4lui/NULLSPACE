extends Node3D
## Isolated art diagnostics only: no AI, gameplay controller or production environment.

const MODEL: PackedScene = preload("res://assets/listener/listener.glb")
const CLIPS: Array[String] = ["idle", "breathing", "listen"]

var camera: Camera3D
var model_root: Node3D
var animation: AnimationPlayer
var skeleton: Skeleton3D
var current_clip: String = "idle"
var current_view: int = 1
var capture_index: int = 0
var paused: bool = false
var elapsed: float = 0.0
var sample_start: float = 0.0
var frame_samples: Array[float] = []
var gpu_samples: Array[float] = []
var cpu_samples: Array[float] = []
var accepted_inputs: int = 0
var capture_directory: String


func _ready() -> void:
	capture_directory = OS.get_environment("NULLSPACE_LISTENER_CAPTURE_DIR")
	if capture_directory.is_empty():
		capture_directory = "res://captures"
	DirAccess.make_dir_recursive_absolute(capture_directory)
	model_root = Node3D.new()
	model_root.name = "ReviewTurntable"
	add_child(model_root)
	var imported: Node = MODEL.instantiate()
	model_root.add_child(imported)
	animation = find_type(imported, "AnimationPlayer") as AnimationPlayer
	skeleton = find_type(imported, "Skeleton3D") as Skeleton3D
	assert(animation != null and skeleton != null, "Missing exported animation or skin")
	for clip: String in CLIPS:
		assert(animation.has_animation(clip), "Missing source clip " + clip)
		animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.085, 0.094, 0.09)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.80, 0.84, 0.81)
	world.environment.ambient_light_energy = 0.45
	world.environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	world.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment.tonemap_exposure = 1.0
	world.environment.ssao_enabled = true
	world.environment.ssao_radius = 0.32
	world.environment.ssao_intensity = 1.0
	add_child(world)
	# The plain ground is labeled diagnostic and is not exported as production art.
	var ground := MeshInstance3D.new()
	ground.name = "DiagnosticGround_NotProductionAsset"
	var plane := PlaneMesh.new()
	plane.size = Vector2(200.0, 200.0)
	ground.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.11, 0.12, 0.115)
	material.roughness = 0.9
	ground.material_override = material
	ground.position.y = -0.002
	add_child(ground)
	add_review_light(Vector3(-1.8, 3.5, 2.2), Color(1.0, 0.94, 0.81), 1.6, true)
	add_review_light(Vector3(2.5, 2.6, 0.6), Color(0.85, 0.92, 1.0), 0.8, false)
	add_review_light(Vector3(0.5, 2.8, -2.0), Color(0.92, 0.97, 1.0), 1.1, false)
	camera = Camera3D.new()
	camera.fov = 38.0
	camera.near = 0.025
	add_child(camera)
	set_review_view(1)
	animation.play(current_clip)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	print("LISTENER_REVIEW_READY bones=", skeleton.get_bone_count(), " clips=", animation.get_animation_list())


func add_review_light(at: Vector3, color: Color, energy: float, shadow: bool) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 6.0
	light.omni_attenuation = 1.0
	light.light_size = 0.35
	light.shadow_enabled = shadow
	add_child(light)


func find_type(node: Node, type_name: String) -> Node:
	if node.is_class(type_name):
		return node
	for child: Node in node.get_children():
		var found: Node = find_type(child, type_name)
		if found != null:
			return found
	return null


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed - sample_start > 3.0:
		frame_samples.append(delta * 1000.0)
		gpu_samples.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()))
		cpu_samples.append(RenderingServer.viewport_get_measured_render_time_cpu(get_viewport().get_viewport_rid()))
		if frame_samples.size() > 900:
			frame_samples.pop_front()
			gpu_samples.pop_front()
			cpu_samples.pop_front()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	var accepted: bool = true
	match key.physical_keycode:
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
			set_review_view(key.physical_keycode - KEY_0)
		KEY_6, KEY_7, KEY_8:
			current_clip = CLIPS[key.physical_keycode - KEY_6]
			animation.play(current_clip, 0.20)
			paused = false
		KEY_SPACE:
			paused = not paused
			if paused:
				animation.pause()
			else:
				animation.play()
		KEY_RIGHT:
			animation.pause()
			paused = true
			animation.seek(fmod(animation.current_animation_position + 1.0 / 30.0, animation.current_animation_length), true)
		KEY_A:
			model_root.rotation_degrees.y -= 15.0
		KEY_D:
			model_root.rotation_degrees.y += 15.0
		KEY_P:
			capture()
		KEY_ESCAPE:
			get_tree().quit()
		_:
			accepted = false
	if accepted:
		accepted_inputs += 1
		var file := FileAccess.open(capture_directory.path_join("accepted_input_trace.jsonl"), FileAccess.READ_WRITE if FileAccess.file_exists(capture_directory.path_join("accepted_input_trace.jsonl")) else FileAccess.WRITE)
		file.seek_end()
		file.store_line(JSON.stringify({"frame": Engine.get_frames_drawn(), "time_ms": Time.get_ticks_msec(), "physical_keycode": key.physical_keycode, "device": key.device}))


func set_review_view(index: int) -> void:
	current_view = index
	model_root.rotation = Vector3.ZERO
	match index:
		1:
			camera.position = Vector3(3.1, 2.1, 5.4)
			camera.look_at(Vector3(0.0, 1.15, 0.0))
		2:
			camera.position = Vector3(0.64, 2.28, 1.12)
			camera.look_at(Vector3(-0.06, 2.14, 0.05))
		3:
			camera.position = Vector3(1.05, 0.97, 0.8)
			camera.look_at(Vector3(0.51, 0.67, 0.07))
		4:
			camera.position = Vector3(-2.8, 2.0, -5.3)
			camera.look_at(Vector3(0.0, 1.17, 0.0))
		5:
			camera.position = Vector3(0.65, 0.30, 0.95)
			camera.look_at(Vector3(0.0, 0.16, 0.06))
	sample_start = elapsed
	frame_samples.clear()
	gpu_samples.clear()
	cpu_samples.clear()


func timing(values: Array[float]) -> Dictionary:
	if values.is_empty():
		return {"samples": 0}
	var sorted: Array[float] = values.duplicate()
	sorted.sort()
	return {"samples": sorted.size(), "p50_ms": sorted[sorted.size() / 2], "p95_ms": sorted[min(int(sorted.size() * 0.95), sorted.size() - 1)]}


func capture() -> void:
	await RenderingServer.frame_post_draw
	capture_index += 1
	var stem: String = capture_directory.path_join("listener_%03d" % capture_index)
	var screenshot: Image = get_viewport().get_texture().get_image()
	screenshot.save_png(stem + ".png")
	var record := {"view": current_view, "clip": current_clip, "clip_position": animation.current_animation_position,
		"paused": paused, "skeleton_bones": skeleton.get_bone_count(), "accepted_inputs": accepted_inputs,
		"camera_position": [camera.position.x, camera.position.y, camera.position.z], "turntable_degrees": model_root.rotation_degrees.y,
		"width": screenshot.get_width(), "height": screenshot.get_height(), "elapsed": elapsed,
		"frame": timing(frame_samples), "gpu": timing(gpu_samples), "render_cpu": timing(cpu_samples),
		"renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"claim": "Source-art diagnostic; no AI, campaign or independent quality claim"}
	var file := FileAccess.open(stem + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(record, "\t"))
	print("LISTENER_CAPTURE ", stem)
