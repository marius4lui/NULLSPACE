class_name NullspaceSection
extends Node3D
## The actual playable scene. New game systems extend this scene, not a second preview.

const ROOM: PackedScene = preload("res://environment/m4_reference_room.tscn")
const PLAYER: PackedScene = preload("res://player/player.tscn")
const Menu = preload("res://section/section_menu.gd")
const ARRIVAL := Transform3D(Basis(Vector3.UP, 0.44), Vector3(2.70, 0.025, -0.85))

var room: NullspaceM4ReferenceRoom
var player: SectionPlayer
var light_switch: SectionLightSwitch
var menu: NullspaceSectionMenu
var _environment: Environment
var _fixture_states: Array[int] = []
var _snapshot: Dictionary = {}
var _frame_samples: Array[float] = []
var _sample_time: float = 0.0
var _last_frame_usec: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.use_accumulated_input = false
	_environment = EnvironmentSurfaceLibrary.make_reference_environment()
	var world := WorldEnvironment.new()
	world.environment = _environment
	add_child(world)
	room = ROOM.instantiate() as NullspaceM4ReferenceRoom
	room.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(room)
	for fixture: NullspaceFluorescentFixture in room.fixtures:
		_fixture_states.append(fixture.state)
	player = PLAYER.instantiate() as SectionPlayer
	player.transform = ARRIVAL
	add_child(player)
	light_switch = SectionLightSwitch.new()
	light_switch.name = "LocalLightSwitch"
	light_switch.position = Vector3(0.05, 1.45, -5.993)
	add_child(light_switch)
	light_switch.power_changed.connect(_on_local_power)
	var plate_text := Label3D.new()
	plate_text.text = "LOCAL LIGHTING"
	plate_text.font_size = 24
	plate_text.pixel_size = 0.0015
	plate_text.modulate = Color(0.14, 0.15, 0.12)
	plate_text.outline_size = 0
	plate_text.position = Vector3(0, 0.23, 0)
	light_switch.add_child(plate_text)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	menu = Menu.new()
	canvas.add_child(menu)
	player.prompt_changed.connect(menu.set_prompt)
	GameFlow.load_started.connect(_restore)
	SettingsManager.settings_changed.connect(_apply_settings)
	_apply_settings(SettingsManager.snapshot())
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	Telemetry.record(&"section_ready", {"room": "original_m4", "build_stage": "room_player"})

func _restore(snapshot: Dictionary, generation: int) -> void:
	_snapshot = snapshot.duplicate(true)
	# Let physics register the authored colliders before testing the spawn capsule.
	await get_tree().physics_frame
	if generation != GameFlow.pending_generation:
		return
	var powered: bool = bool(snapshot["world"]["circuits"].get("arrival_lights", true))
	light_switch.set_powered(powered)
	_apply_local_power(powered)
	if not player.restore_at(ARRIVAL, snapshot["player"]):
		GameFlow.fail_load(generation, "Arrival is obstructed. The checkpoint was not overwritten.")
		return
	GameFlow.complete_load(generation)
	menu.show_hint("Find your bearings.  WASD move · Shift sprint · Ctrl crouch\nF flashlight · E interact · Esc pause")
	Telemetry.record(&"section_restored", {"generation": generation, "position": [player.position.x, player.position.y, player.position.z]})

func _on_local_power(enabled: bool) -> void:
	_apply_local_power(enabled)
	# Concrete local checkpoint binding; legacy schema fields are retained, not rewritten.
	_snapshot["world"]["circuits"]["arrival_lights"] = enabled
	_snapshot["player"]["health"] = player.health
	_snapshot["player"]["stamina"] = player.stamina
	_snapshot["player"]["flashlight_enabled"] = player.flashlight.visible
	_snapshot["session"]["elapsed_seconds"] = SimulationClock.sample().elapsed_seconds
	var result: StorageResult = CheckpointSystem.commit_snapshot(_snapshot)
	menu.show_hint("Local lighting " + ("restored." if enabled else "off.  F — flashlight.") + ("\nCheckpoint saved." if result.ok else "\nSave failed: " + result.message))

func _apply_local_power(enabled: bool) -> void:
	for i: int in room.fixtures.size():
		room.fixtures[i].set_fixture_state(_fixture_states[i] as NullspaceFluorescentFixture.State if enabled else NullspaceFluorescentFixture.State.OFF)
	_environment.ambient_light_energy = 0.30 if enabled else 0.018

func _apply_settings(values: Dictionary) -> void:
	var profile: QualityProfile = SettingsManager.current_quality()
	# The old room's screen-space effects dominated measured GPU time on this laptop.
	# Keep physical materials and light; enhanced adds modest AO, not expensive SSIL.
	_environment.ssil_enabled = false
	_environment.ssao_enabled = profile.id == &"high" or profile.id == &"ultra"
	_environment.glow_enabled = profile.id != &"low"
	get_viewport().use_taa = false
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	var shadow_count: int = 0
	for fixture: NullspaceFluorescentFixture in room.fixtures:
		fixture.reduce_flashes = bool(values["reduced_flashes"])
		var light := fixture.get_node("FluorescentDirect") as OmniLight3D
		light.shadow_enabled = _fixture_states[room.fixtures.find(fixture)] == NullspaceFluorescentFixture.State.NORMAL and shadow_count < profile.shadow_light_budget
		if light.shadow_enabled:
			shadow_count += 1
	Telemetry.record(&"section_render_settings", {"quality": profile.id, "render_scale": get_viewport().scaling_3d_scale,
		"ssao": _environment.ssao_enabled, "ssil": false, "shadows": shadow_count, "resolution": values["resolution"]})

func _process(delta: float) -> void:
	if GameFlow.state != NullGameFlow.State.PLAYING:
		_last_frame_usec = 0
		return
	menu.set_stamina(player.stamina)
	var now: int = Time.get_ticks_usec()
	if _last_frame_usec > 0:
		_frame_samples.append(float(now - _last_frame_usec) / 1000.0)
	_last_frame_usec = now
	_sample_time += delta
	if _sample_time >= 5.0:
		_frame_samples.sort()
		Telemetry.record(&"section_frame_window", {"samples": _frame_samples.size(),
			"frame_ms_p50": _frame_samples[int(_frame_samples.size() * 0.5)],
			"frame_ms_p95": _frame_samples[mini(int(_frame_samples.size() * 0.95), _frame_samples.size() - 1)],
			"gpu_ms_last": RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
		_frame_samples.clear()
		_sample_time = 0.0
