class_name NullspaceSection
extends Node3D
## The actual playable scene. New game systems extend this scene, not a second preview.

const ROOM: PackedScene = preload("res://environment/short_map.tscn")
const PLAYER: PackedScene = preload("res://player/player.tscn")
const Menu = preload("res://section/section_menu.gd")
const ARRIVAL := Transform3D(Basis(Vector3.UP, 2.43), Vector3(4.8, 0.025, 5.8))
const OFFICE_SAFE := Transform3D(Basis(Vector3.UP, 2.74), Vector3(-0.3, 0.025, -23.55))
const SERVICE_SAFE := Transform3D(Basis(Vector3.UP, PI / 2), Vector3(19.8, 0.025, -18.2))
const OFFICE_RESET := Vector3(-7.2, .03, -22.4)
const SERVICE_RESET := Vector3(19.6, .03, -16.2)

var room: ShortMap
var player: SectionPlayer
var office_relay: PowerRelay
var service_relay: PowerRelay
var emergency_relay: DifficultyRelay
var fuse_pickup: SectionFusePickup
var exit_door: SectionDoor
var exit_status: Label3D
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
var _snapshot: Dictionary = {}
var _frame_samples: Array[float] = []
var _sample_time: float = 0.0
var _last_frame_usec: int = 0
var _quitting: bool = false
var difficulty_id: String = DifficultyConfig.DEFAULT_ID
var difficulty: Dictionary = DifficultyConfig.profile(DifficultyConfig.DEFAULT_ID)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.use_accumulated_input = false
	get_tree().auto_accept_quit = false
	_environment = EnvironmentSurfaceLibrary.make_reference_environment()
	var world := WorldEnvironment.new()
	world.environment = _environment
	add_child(world)
	room = ROOM.instantiate() as ShortMap
	room.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(room)
	_bake_navigation()
	player = PLAYER.instantiate() as SectionPlayer
	player.transform = ARRIVAL
	add_child(player)
	room.player = player
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
	listener = Listener.new()
	listener.player = player
	listener.section = self
	listener.position = OFFICE_RESET
	listener.patrol = [OFFICE_RESET, Vector3(3, .03, -12), Vector3(12.6, .03, -8.2),
		Vector3(19.4, .03, -7), Vector3(15.1, .03, -18.4)]
	add_child(listener)
	_create_objectives()
	EventHub.sound_emitted.connect(_propagate_noise)
	sound = SectionSound.new()
	sound.section = self
	add_child(sound)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	menu = Menu.new()
	canvas.add_child(menu)
	if InputGate.uses_touch():
		canvas.add_child(preload("res://section/touch_controls.tscn").instantiate())
	menu.quit_requested.connect(request_quit)
	menu.start_requested.connect(_begin_new_game)
	player.prompt_changed.connect(menu.set_prompt)
	player.damaged.connect(menu.show_injury)
	pistol.ammunition_changed.connect(menu.set_ammunition)
	GameFlow.load_started.connect(_restore)
	SettingsManager.settings_changed.connect(_apply_settings)
	_apply_settings(SettingsManager.snapshot())
	_apply_difficulty(DifficultyConfig.DEFAULT_ID)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	Telemetry.record(&"section_ready", {"map": "short-map-1", "build_stage": "two_switch_flow"})

func _create_objectives() -> void:
	for data: Dictionary in room.layout["doors"]:
		var door := SectionDoor.new()
		door.player = player
		door.listener = listener
		door.door_id = data["id"]
		var at: Array = data["position"]
		door.position = Vector3(at[0], at[1], at[2])
		door.rotation.y = data["yaw"]
		add_child(door)
		doors.append(door)
		if door.door_id == "exit_door":
			exit_door = door
			door.locked = true
	office_relay = PowerRelay.new()
	office_relay.position = Vector3(.1, 1.5, -25.51)
	add_child(office_relay)
	office_relay.power_changed.connect(func(_powered: bool) -> void: _on_relay_power("office"))
	service_relay = PowerRelay.new()
	service_relay.relay_id = "service"
	service_relay.title = "SERVICE B"
	service_relay.position = Vector3(21.85, 1.5, -19.1)
	service_relay.rotation.y = -PI / 2
	add_child(service_relay)
	service_relay.power_changed.connect(func(_powered: bool) -> void: _on_relay_power("service"))
	emergency_relay = DifficultyRelay.new()
	emergency_relay.relay_id = "emergency"
	emergency_relay.title = "EMERGENCY C"
	emergency_relay.position = Vector3(-5.94, 1.5, -6.40)
	emergency_relay.rotation.y = -PI / 2
	emergency_relay.has_fuse = func() -> bool: return bool(_snapshot.get("world", {}).get("circuits", {}).get("emergency_fuse_carried", false))
	emergency_relay.consume_fuse = func() -> void: _snapshot["world"]["circuits"]["emergency_fuse_carried"] = false
	add_child(emergency_relay)
	emergency_relay.power_changed.connect(func(_powered: bool) -> void: _on_emergency_power())
	emergency_relay.prerequisite_changed.connect(_on_emergency_prerequisite)
	fuse_pickup = SectionFusePickup.new()
	fuse_pickup.position = Vector3(21.72, 1.38, -8.15)
	fuse_pickup.rotation.y = -PI / 2
	add_child(fuse_pickup)
	fuse_pickup.collected.connect(_on_fuse_collected)
	exit_status = _wall_sign("EXIT\nOFFICE A: OFFLINE\nSERVICE B: OFFLINE", Vector3(4.15, 1.65, 8.445), PI, 24)
	_wall_sign("OFFICE A", Vector3(-2.44, 2.59, -14.535), 0, 26)
	_wall_sign("SERVICE B", Vector3(5.99, 1.8, -6.6), -PI / 2, 28)
	_wall_sign("EXIT", Vector3(3.55, 1.65, 1.5), -PI / 2, 30)
	var exit_area := Area3D.new()
	exit_area.collision_layer = 0
	exit_area.collision_mask = 2
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.1, 2, 1.25)
	shape.shape = box
	exit_area.position = Vector3(2.44, 1, 9.7)
	exit_area.add_child(shape)
	add_child(exit_area)
	exit_area.body_entered.connect(func(body: Node3D) -> void:
		if body == player: finish_escape())

func _begin_new_game(selected: String) -> void:
	GameFlow.begin_new_game(DifficultyConfig.sanitize(selected))

func _wall_sign(text: String, at: Vector3, yaw: float, size: int) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = .0016
	label.modulate = Color(.16, .19, .13)
	label.outline_size = 0
	label.position = at
	label.rotation.y = yaw
	add_child(label)
	return label

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		request_quit()

func request_quit(code: int = 0) -> void:
	if _quitting:
		return
	_quitting = true
	GameFlow.return_to_menu()
	sound.shutdown()
	for door: SectionDoor in doors: door._audio.stop()
	office_relay.audio.stop()
	service_relay.audio.stop()
	emergency_relay.audio.stop()
	shot_effects.clear()
	pistol._exit_tree()
	# AudioServer releases stopped loop playbacks on its next mix, including Dummy audio.
	await get_tree().create_timer(0.10, true, false, true).timeout
	get_tree().quit(code)

func _restore(snapshot: Dictionary, generation: int) -> void:
	_snapshot = snapshot.duplicate(true)
	_apply_difficulty(DifficultyConfig.from_snapshot(snapshot))
	# Let physics register the authored colliders before testing the spawn capsule.
	await get_tree().physics_frame
	if generation != GameFlow.pending_generation:
		return
	office_relay.restore(snapshot["progress"]["relays"]["office"])
	service_relay.restore(snapshot["progress"]["relays"]["service"])
	var circuits: Dictionary = snapshot["world"]["circuits"]
	emergency_relay.restore_difficulty(bool(circuits.get("emergency_powered", false)),
		bool(circuits.get("emergency_prerequisite", false)))
	fuse_pickup.set_consumed(bool(circuits.get("emergency_fuse_taken", false)))
	_refresh_difficulty_visibility()
	_apply_power()
	shot_effects.clear()
	sound.reset()
	pistol.restore(snapshot["inventory"]["weapons"]["pistol"])
	pistol_pickup.set_consumed("arrival_pistol" in snapshot["world"]["consumed_pickups"])
	var anchor: Transform3D = ARRIVAL
	var monster_anchor: Vector3 = OFFICE_RESET
	if snapshot["checkpoint"]["player_anchor"] == "office_safe":
		anchor = OFFICE_SAFE
		monster_anchor = SERVICE_RESET
	elif snapshot["checkpoint"]["player_anchor"] == "service_safe":
		anchor = SERVICE_SAFE
	listener.reset_at(monster_anchor)
	for door: SectionDoor in doors:
		door.restore(snapshot["world"]["doors"].get(door.door_id, "closed") == "open")
	if not player.restore_at(anchor, snapshot["player"]):
		GameFlow.fail_load(generation, "Safe checkpoint is obstructed. The save was not overwritten.")
		return
	# Do not reactivate physics halfway through its query/step cycle. Native Continue
	# with twelve animated door leaves exposed duplicate self-list entries there.
	await get_tree().process_frame
	if generation != GameFlow.pending_generation:
		return
	GameFlow.complete_load(generation)
	if snapshot["progress"]["ending"]:
		GameFlow.end_campaign()
	else:
		var controls: String = "Left stick move · Swipe right to look · USE interact · II pause" if InputGate.uses_touch() else "WASD move · Shift sprint · Ctrl crouch · F light · E interact · Esc pause"
		menu.show_hint(_objective_hint() + "\n" + controls)
	Telemetry.record(&"section_restored", {"generation": generation, "position": [player.position.x, player.position.y, player.position.z]})

func _on_relay_power(id: String) -> void:
	_snapshot["progress"]["relays"][id] = true
	_apply_power()
	player.health = 100.0
	player.stamina = 1.0
	_snapshot["checkpoint"]["id"] = id
	_snapshot["checkpoint"]["room_id"] = id
	_snapshot["checkpoint"]["player_anchor"] = id + "_safe"
	_snapshot["checkpoint"]["monster_anchor"] = "service_reset" if id == "office" else "office_reset"
	var result: StorageResult = _save_current()
	menu.show_hint(_objective_hint() + ("\nYou steady your breathing. Checkpoint saved." if result.ok else "\nSave failed: " + result.message))
	EventHub.objective_committed.emit(StringName(id))

func _on_fuse_collected() -> void:
	_snapshot["world"]["circuits"]["emergency_fuse_taken"] = true
	_snapshot["world"]["circuits"]["emergency_fuse_carried"] = true
	var result := _save_current()
	Telemetry.record(&"fuse_collected", {"id": "emergency"})
	menu.objective = _objective_hint()
	menu.show_hint("Marked fuse acquired. Carry it to EMERGENCY C in the divided offices.\n" +
		("Progress saved." if result.ok else "Save failed: " + result.message))

func _on_emergency_prerequisite() -> void:
	_snapshot["world"]["circuits"]["emergency_prerequisite"] = true
	var result := _save_current()
	menu.show_hint(("Fuse seated." if emergency_relay.access_mode == "fuse" else "Safety latch released.") +
		" Open the EMERGENCY C panel and throw its switch.\n" +
		("Progress saved." if result.ok else "Save failed: " + result.message))

func _on_emergency_power() -> void:
	_snapshot["world"]["circuits"]["emergency_powered"] = true
	_apply_power()
	var result := _save_current()
	menu.show_hint(_objective_hint() + ("\nProgress saved." if result.ok else "\nSave failed: " + result.message))
	EventHub.objective_committed.emit(&"emergency")

func _save_current() -> StorageResult:
	_snapshot["player"]["health"] = player.health
	_snapshot["player"]["stamina"] = player.stamina
	_snapshot["player"]["flashlight_enabled"] = player.flashlight.visible
	_snapshot["inventory"]["weapons"]["pistol"] = pistol.snapshot()
	_snapshot["player"]["equipped_weapon"] = "pistol" if pistol.owned else ""
	_snapshot["session"]["elapsed_seconds"] = SimulationClock.sample().elapsed_seconds
	for door: SectionDoor in doors:
		_snapshot["world"]["doors"][door.door_id] = "locked" if door.locked else ("open" if door.opened else "closed")
	return CheckpointSystem.commit_snapshot(_snapshot)

func _on_pistol_collected() -> void:
	_snapshot["world"]["consumed_pickups"].append("arrival_pistol")
	var result: StorageResult = _save_current()
	menu.show_hint("Pistol acquired. Left mouse — fire · R — reload\nShots draw attention. Hits buy time; you can also break sight and escape.\n" + ("Checkpoint saved." if result.ok else "Save failed: " + result.message))

func _apply_power() -> void:
	room.apply_power({"office": office_relay.powered, "service": service_relay.powered})
	exit_door.locked = not _required_power_complete()
	exit_status.text = "EXIT\nOFFICE A: " + ("ONLINE" if office_relay.powered else "OFFLINE")
	if "service" in difficulty["required_switches"]:
		exit_status.text += "\nSERVICE B: " + ("ONLINE" if service_relay.powered else "OFFLINE")
	if "emergency" in difficulty["required_switches"]:
		exit_status.text += "\nEMERGENCY C: " + ("ONLINE" if emergency_relay.powered else "OFFLINE")
	exit_status.modulate = Color(.12,.30,.15) if not exit_door.locked else Color(.24,.17,.10)
	if is_instance_valid(menu): menu.objective = _objective_hint()

func _objective_hint() -> String:
	if not exit_door.locked: return "Required power is restored. Return to the EXIT where you arrived."
	if difficulty_id == "easy": return "Restore OFFICE A, then return to the EXIT."
	if difficulty_id in ["hard", "nightmare"] and not emergency_relay.powered:
		if emergency_relay.access_mode == "fuse" and not emergency_relay.fuse_inserted:
			if bool(_snapshot.get("world", {}).get("circuits", {}).get("emergency_fuse_carried", false)):
				return "Restore three circuits. Carry the marked fuse to EMERGENCY C in the divided offices."
			return "Restore three circuits. Find the marked fuse in SERVICE BYPASS, then insert it at EMERGENCY C."
		if emergency_relay.access_mode == "latch" and not emergency_relay.latch_released:
			return "Restore three circuits. Release the safety latch at EMERGENCY C before using it."
		return "Restore OFFICE A, SERVICE B, and EMERGENCY C."
	if office_relay.powered: return "Office A restored. Find SERVICE B beyond the utility doors."
	if service_relay.powered: return "Service B restored. Find OFFICE A beyond the divided offices."
	return "The exit has no power. Restore OFFICE A and SERVICE B."

func _required_power_complete() -> bool:
	for id: String in difficulty["required_switches"]:
		if id == "office" and not office_relay.powered: return false
		if id == "service" and not service_relay.powered: return false
		if id == "emergency" and not emergency_relay.powered: return false
	return true

func _apply_difficulty(selected: String) -> void:
	difficulty_id = DifficultyConfig.sanitize(selected)
	difficulty = DifficultyConfig.profile(difficulty_id)
	listener.difficulty_speed = float(difficulty["monster_speed"])
	listener.difficulty_awareness = float(difficulty["awareness"])
	room.set_difficulty_lighting(float(difficulty["fixture_energy"]), float(difficulty["light_reaction"]))
	if is_instance_valid(sound):
		sound.set_atmosphere_intensity(float(difficulty["atmosphere"]))
	emergency_relay.access_mode = str(difficulty["extra_step"])
	_refresh_difficulty_visibility()
	menu.selected_difficulty = difficulty_id
	Telemetry.record(&"difficulty_applied", {"id": difficulty_id, "monster_speed": difficulty["monster_speed"],
		"fixture_energy": difficulty["fixture_energy"], "required_switches": difficulty["required_switches"]})

func _refresh_difficulty_visibility() -> void:
	var emergency_active: bool = "emergency" in difficulty["required_switches"]
	emergency_relay.visible = emergency_active
	emergency_relay.collision_layer = 1 if emergency_active else 0
	service_relay.visible = "service" in difficulty["required_switches"]
	service_relay.collision_layer = 1 if service_relay.visible else 0
	var fuse_active: bool = difficulty_id == "nightmare" and not fuse_pickup.consumed
	fuse_pickup.visible = fuse_active
	fuse_pickup.collision_layer = 8 if fuse_active else 0

func finish_escape() -> void:
	if GameFlow.state != NullGameFlow.State.PLAYING or exit_door.locked: return
	_snapshot["progress"]["ending"] = true
	var result: StorageResult = _save_current()
	if result.ok:
		Telemetry.record(&"escape_complete", {"seconds": SimulationClock.sample().elapsed_seconds,
			"shots": pistol.shots_fired, "ammo": pistol.snapshot(), "health": player.health})
		GameFlow.end_campaign()
	else:
		_snapshot["progress"]["ending"] = false
		menu.show_hint("Could not save the ending: " + result.message + "\nStep back and enter the exit to retry.")

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

func _apply_settings(values: Dictionary) -> void:
	var profile: QualityProfile = SettingsManager.current_quality()
	# The old room's screen-space effects dominated measured GPU time on this laptop.
	# Keep physical materials and light; enhanced adds modest AO, not expensive SSIL.
	_environment.ssil_enabled = false
	_environment.ssao_enabled = profile.id == &"high" or profile.id == &"ultra"
	_environment.glow_enabled = profile.id in [&"medium", &"high", &"ultra"]
	get_viewport().use_taa = false
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	room.shadow_budget = profile.shadow_light_budget
	room.direct_light_budget = profile.direct_light_budget
	for fixture: NullspaceFluorescentFixture in room.fixtures:
		fixture.reduce_flashes = bool(values["reduced_flashes"])
	Telemetry.record(&"section_render_settings", {"quality": profile.id, "render_scale": get_viewport().scaling_3d_scale,
		"ssao": _environment.ssao_enabled, "ssil": false, "shadow_budget": room.shadow_budget, "resolution": values["resolution"]})

func _process(delta: float) -> void:
	if GameFlow.state != NullGameFlow.State.PLAYING:
		_last_frame_usec = 0
		return
	menu.set_stamina(player.stamina)
	menu.set_health(player.health)
	pistol.light_exposure = room.light_exposure(player.global_position)
	_environment.ambient_light_energy = move_toward(_environment.ambient_light_energy,
		float(difficulty["ambient_dark"] if room.is_dark(player.global_position) else difficulty["ambient_lit"]), delta * .25)
	var now: int = Time.get_ticks_usec()
	if _last_frame_usec > 0:
		var frame_ms: float = float(now - _last_frame_usec) / 1000.0
		_frame_samples.append(frame_ms)
		if frame_ms > 50:
			Telemetry.record(&"frame_hitch", {"ms": frame_ms, "room": room.room_at(player.global_position),
				"cpu_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0})
	_last_frame_usec = now
	_sample_time += delta
	if _sample_time >= 5.0 and not _frame_samples.is_empty():
		_frame_samples.sort()
		Telemetry.record(&"section_frame_window", {"samples": _frame_samples.size(),
			"frame_ms_p50": _frame_samples[int(_frame_samples.size() * 0.5)],
			"frame_ms_p95": _frame_samples[mini(int(_frame_samples.size() * 0.95), _frame_samples.size() - 1)],
			"frame_ms_max": _frame_samples.back(), "room": room.room_at(player.global_position),
			"gpu_ms_last": RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
		_frame_samples.clear()
		_sample_time = 0.0
