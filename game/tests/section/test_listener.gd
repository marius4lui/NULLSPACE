extends Node
## Actual scene/physics checks. Fixture positioning is automation, not a playthrough.
var checks: int = 0
var failures: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var isolated: DirAccess = DirAccess.create_temp("nullspace_listener_test", true)
	if isolated == null:
		get_tree().quit(2)
		return
	SaveSystem.storage_directory = isolated.get_current_dir().path_join("saves")
	SettingsManager.storage_directory = isolated.get_current_dir().path_join("preferences")
	SettingsManager.reload_settings()
	var section := preload("res://section/section.tscn").instantiate() as NullspaceSection
	add_child(section)
	await _frames(5)
	GameFlow.begin_new_game()
	await _frames(10)
	var enemy: Listener = section.listener
	var player: SectionPlayer = section.player
	var map: RID = section.get_world_3d().navigation_map
	_check(section.navigation_region.navigation_mesh.get_polygon_count() > 0, "Actual room collision bakes walkable navigation")
	var path := NavigationServer3D.map_get_path(map, Vector3(-1, 0, -7), Vector3(-1, 0, -5), true)
	var length: float = 0
	for i: int in range(1, path.size()): length += path[i - 1].distance_to(path[i])
	_check(path.size() > 2 and length > 4, "Navigation routes around authored solid partition")
	enemy.enabled = false
	enemy.reset_at(Vector3(-1, 0.03, -6.5))
	enemy.rotation.y = PI
	player.global_position = Vector3(-1, 0.03, -5.65)
	await _frames(3)
	enemy._perceive(1)
	_check(not enemy.sees_player, "Real partition blocks vision at close range")
	_check(not enemy._clear_attack(), "Close target across partition cannot be hit")
	player.global_position = Vector3(2, 0.03, -5)
	enemy.reset_at(Vector3(2, 0.03, -7))
	enemy.rotation.y = PI
	await _frames(3)
	enemy._perceive(1)
	_check(enemy.sees_player and enemy.state == Listener.State.CHASING, "Unobstructed nearby moving-space target acquired by sight")
	enemy.reset_at(Vector3(-1, 0.03, -7))
	enemy.rotation.y = PI
	player.global_position = Vector3(-1, 0.03, -5)
	await _frames(3)
	enemy.enabled = true
	var sound := SoundEvent.new()
	var stamp: SimulationStamp = SimulationClock.sample()
	sound.source_id = &"section_player"
	sound.kind = &"pistol_shot"
	sound.position = player.global_position
	sound.intensity = 1.0
	sound.simulation_epoch = stamp.epoch
	sound.simulation_seconds = stamp.elapsed_seconds
	EventHub.submit_sound(sound)
	_check(enemy.state == Listener.State.INVESTIGATING, "Gunshot behind partition creates investigation")
	var old_clue: Vector3 = enemy.evidence_position
	player.global_position = Vector3(-2.4, 0.03, -4.6)
	await _frames(70)
	_check(enemy.evidence_position.distance_to(old_clue) < 0.05 and not enemy.sees_player,
		"Quiet relocation behind partition does not update old sound clue")
	_check(enemy.global_position.distance_to(Vector3(-1, 0.03, -7)) > 0.5,
		"Embodied listener actually moves on navigation path")
	enemy.enabled = false
	enemy.reset_at(Vector3(3, 0.03, -12))
	player.global_position = Vector3(-2, 0.03, -4)
	await _frames(3)
	enemy.enabled = true
	await _frames(3)
	sound.kind = &"crouch_step"
	sound.intensity = 0.06
	sound.position = player.global_position
	EventHub.submit_sound(sound)
	_check(enemy.confidence == 0, "Distant crouch sound outside navigable acoustic reach ignored")
	enemy.hear_at(Vector3(3, 0.03, -12), 0.2, &"impact", SimulationClock.sample())
	await _frames(420)
	_check(enemy.state == Listener.State.ROAMING and enemy.confidence == 0,
		"Low-confidence stale search ends without acquiring hidden player")
	enemy.receive_shot(enemy.global_position, 1)
	await _frames(30)
	enemy.receive_shot(enemy.global_position, 1)
	_check(enemy.state == Listener.State.STAGGERED and enemy._state_time < 0.1, "Repeated bullet restarts interruption window")
	enemy.receive_shot(enemy.global_position, 1)
	await _frames(60)
	_check(enemy.state == Listener.State.RETREATING, "Three nearby hits force nonlethal retreat")
	print(JSON.stringify({"suite": "Listener actual-scene risks", "checks": checks, "failures": failures,
		"nav_polygons": section.navigation_region.navigation_mesh.get_polygon_count(), "wall_path_length": length,
		"scope": "automated physics fixtures, not experiential or auditory validation"}))
	section.request_quit(0 if failures.is_empty() else 1)

func _frames(count: int) -> void:
	for i: int in count: await get_tree().physics_frame

func _check(value: bool, description: String) -> void:
	checks += 1
	if not value: failures.append(description)
