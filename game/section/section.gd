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
var pistol: SectionPistol
var pistol_pickup: PistolPickup
var shot_effects: PistolEffects
var listener: Listener
var navigation_region: NavigationRegion3D
var sound: SectionSound
var doors: Array[SectionDoor] = []
var _noise_sequence: int = 0
var _environment: Environment
var _fixture_states: Array[int] = []
var _snapshot: Dictionary = {}
var _frame_samples: Array[float] = []
var _sample_time: float = 0.0
var _last_frame_usec: int = 0
var _quitting: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.use_accumulated_input = false
	get_tree().auto_accept_quit = false
	_environment = EnvironmentSurfaceLibrary.make_reference_environment()
	var world := WorldEnvironment.new()
	world.environment = _environment
	add_child(world)
	room = ROOM.instantiate() as NullspaceM4ReferenceRoom
	room.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(room)
	for fixture: NullspaceFluorescentFixture in room.fixtures:
		_fixture_states.append(fixture.state)
	_bake_navigation()
	player = PLAYER.instantiate() as SectionPlayer
	player.transform = ARRIVAL
	add_child(player)
	shot_effects = PistolEffects.new()
	shot_effects.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(shot_effects)
	pistol = SectionPistol.new()
	pistol.wielder = player
	pistol.effects = shot_effects
	player.camera.add_child(pistol)
	pistol_pickup = PistolPickup.new()
	pistol_pickup.pistol = pistol
	pistol_pickup.position = Vector3(3.60, 0.008, -3.00)
	add_child(pistol_pickup)
	pistol_pickup.collected.connect(_on_pistol_collected)
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
	listener = Listener.new()
	listener.player = player
	listener.section = self
	listener.position = Vector3(-4.3, 0.05, -11.3)
	add_child(listener)
	var door := SectionDoor.new()
	door.player = player
	door.listener = listener
	door.position = Vector3(-2.44, 0, -14.64)
	add_child(door)
	doors.append(door)
	EventHub.sound_emitted.connect(_propagate_noise)
	sound = SectionSound.new()
	sound.section = self
	add_child(sound)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	menu = Menu.new()
	canvas.add_child(menu)
	menu.quit_requested.connect(request_quit)
	player.prompt_changed.connect(menu.set_prompt)
	pistol.ammunition_changed.connect(menu.set_ammunition)
	GameFlow.load_started.connect(_restore)
	SettingsManager.settings_changed.connect(_apply_settings)
	_apply_settings(SettingsManager.snapshot())
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	Telemetry.record(&"section_ready", {"room": "original_m4", "build_stage": "room_player"})

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		request_quit()

func request_quit(code: int = 0) -> void:
	if _quitting:
		return
	_quitting = true
	GameFlow.return_to_menu()
	sound.shutdown()
	shot_effects.clear()
	pistol._exit_tree()
	# AudioServer releases stopped loop playbacks on its next mix, including Dummy audio.
	await get_tree().create_timer(0.10, true, false, true).timeout
	get_tree().quit(code)

func _restore(snapshot: Dictionary, generation: int) -> void:
	_snapshot = snapshot.duplicate(true)
	# Let physics register the authored colliders before testing the spawn capsule.
	await get_tree().physics_frame
	if generation != GameFlow.pending_generation:
		return
	var powered: bool = bool(snapshot["world"]["circuits"].get("arrival_lights", true))
	light_switch.set_powered(powered)
	_apply_local_power(powered)
	shot_effects.clear()
	sound.reset()
	pistol.restore(snapshot["inventory"]["weapons"]["pistol"])
	pistol_pickup.set_consumed("arrival_pistol" in snapshot["world"]["consumed_pickups"])
	listener.reset_at(Vector3(-4.3, 0.05, -11.3))
	for door: SectionDoor in doors:
		door.restore(snapshot["world"]["doors"].get(door.door_id, "closed") == "open")
	if not player.restore_at(ARRIVAL, snapshot["player"]):
		GameFlow.fail_load(generation, "Arrival is obstructed. The checkpoint was not overwritten.")
		return
	GameFlow.complete_load(generation)
	menu.show_hint("Find your bearings.  WASD move · Shift sprint · Ctrl crouch\nF flashlight · E interact · Esc pause" + ("\nA security case lies to your right." if not pistol.owned else ""))
	Telemetry.record(&"section_restored", {"generation": generation, "position": [player.position.x, player.position.y, player.position.z]})

func _on_local_power(enabled: bool) -> void:
	_apply_local_power(enabled)
	# Concrete local checkpoint binding; legacy schema fields are retained, not rewritten.
	_snapshot["world"]["circuits"]["arrival_lights"] = enabled
	_snapshot["player"]["health"] = player.health
	_snapshot["player"]["stamina"] = player.stamina
	_snapshot["player"]["flashlight_enabled"] = player.flashlight.visible
	_snapshot["inventory"]["weapons"]["pistol"] = pistol.snapshot()
	_snapshot["player"]["equipped_weapon"] = "pistol" if pistol.owned else ""
	_snapshot["session"]["elapsed_seconds"] = SimulationClock.sample().elapsed_seconds
	for door: SectionDoor in doors:
		_snapshot["world"]["doors"][door.door_id] = "open" if door.opened else "closed"
	var result: StorageResult = CheckpointSystem.commit_snapshot(_snapshot)
	menu.show_hint("Local lighting " + ("restored." if enabled else "off.  F — flashlight.") + ("\nCheckpoint saved." if result.ok else "\nSave failed: " + result.message))

func _on_pistol_collected() -> void:
	_snapshot["world"]["consumed_pickups"].append("arrival_pistol")
	_snapshot["inventory"]["weapons"]["pistol"] = pistol.snapshot()
	_snapshot["player"]["equipped_weapon"] = "pistol"
	_snapshot["player"]["health"] = player.health
	_snapshot["session"]["elapsed_seconds"] = SimulationClock.sample().elapsed_seconds
	_snapshot["player"]["stamina"] = player.stamina
	_snapshot["player"]["flashlight_enabled"] = player.flashlight.visible
	for door: SectionDoor in doors:
		_snapshot["world"]["doors"][door.door_id] = "open" if door.opened else "closed"
	var result: StorageResult = CheckpointSystem.commit_snapshot(_snapshot)
	menu.show_hint("Pistol acquired.  Left mouse — fire · R — reload\n" + ("Checkpoint saved." if result.ok else "Save failed: " + result.message))

func _bake_navigation() -> void:
	navigation_region = NavigationRegion3D.new()
	add_child(navigation_region)
	var mesh := NavigationMesh.new()
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = 1
	mesh.cell_size = 0.20
	mesh.cell_height = 0.10
	mesh.agent_radius = 0.40 # Exact two-cell clearance, covering the 0.28m physical capsule.
	mesh.agent_height = 2.30
	mesh.agent_max_climb = 0.20
	mesh.region_min_size = 1.0
	var source := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(mesh, source, room)
	NavigationServer3D.bake_from_source_geometry_data(mesh, source)
	var map: RID = get_world_3d().navigation_map
	NavigationServer3D.map_set_cell_size(map, mesh.cell_size)
	NavigationServer3D.map_set_cell_height(map, mesh.cell_height)
	navigation_region.navigation_mesh = mesh
	NavigationServer3D.map_force_update(map)
	Telemetry.record(&"navigation_ready", {"polygons": mesh.get_polygon_count()})

func _propagate_noise(sound: SoundEvent) -> void:
	if sound.source_id != &"section_player" or not sound.is_current_epoch(SimulationClock.sample()):
		return
	# This actual small scene uses navigable acoustic distance around its partitions.
	# No infinite Euclidean hearing and no retained live player transform.
	var path: PackedVector3Array = NavigationServer3D.map_get_path(get_world_3d().navigation_map,
		listener.global_position, sound.position, true)
	if path.size() < 2:
		return
	var distance: float = 0.0
	var attenuation: float = 1.0
	for i: int in range(1, path.size()):
		distance += path[i - 1].distance_to(path[i])
		for door: SectionDoor in doors:
			if door.attenuates_segment(path[i - 1], path[i]):
				attenuation *= .36
	var reach: float = 38.0 * sound.intensity * attenuation
	if distance > reach:
		return
	_noise_sequence += 1
	var certainty: float = clampf(1.0 - distance / maxf(reach, 0.01) * 0.6, 0.25, 0.95)
	var error: float = (1.0 - certainty) * 2.0
	var estimate: Vector3 = sound.position + Vector3(sin(_noise_sequence * 2.37), 0, cos(_noise_sequence * 1.53)) * error
	estimate = NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, estimate)
	listener.hear_at(estimate, certainty, sound.kind, SimulationClock.sample())

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
