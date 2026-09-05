extends Node
## Focused physical-door risks in the actual section. Automated fixtures, not a playthrough.
var checks: int = 0
var failures: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var isolated: DirAccess = DirAccess.create_temp("nullspace_door_test", true)
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
	var door: SectionDoor = section.doors[0]
	var player: SectionPlayer = section.player
	var enemy: Listener = section.listener
	enemy.enabled = false
	enemy.reset_at(Vector3(-2.44, .03, -14.05))
	enemy.rotation.y = 0
	player.global_position = Vector3(-2.44, .03, -15.20)
	await _frames(5)
	enemy._perceive(1)
	_check(not enemy.sees_player and not enemy._clear_attack(), "Closed physical leaves block close sight and attack")
	_check(door.attenuates_segment(enemy.global_position, player.global_position), "Closed aperture attenuates cross-door sound path")
	player.global_position = Vector3(-2.44, .03, -16.5)
	enemy.reset_at(Vector3(-2.44, .03, -12.2))
	await _frames(5)
	enemy.enabled = true
	_emit_step(player.global_position, .18)
	_check(enemy.confidence == 0, "Walking beyond closed door is too attenuated at this distance")
	enemy.enabled = false
	door.use()
	await _frames(80)
	_check(door.opened and absf(door.angle) > 1.6, "Player opens both actual leaves")
	_check(not door.attenuates_segment(enemy.global_position, player.global_position), "Open door removes acoustic attenuation")
	var leaf: SectionDoor.Leaf = door._leaves[0]
	section.shot_effects.impact(leaf.to_global(Vector3(.58, 1.4, .055)), leaf.global_basis.z, true, leaf)
	var mark: Node3D = section.shot_effects._marks.back()
	var marked_position: Vector3 = mark.global_position
	_check(mark.get_parent() == leaf, "Door puncture belongs to moving leaf, not floating world space")
	enemy.enabled = true
	_emit_step(player.global_position, .18)
	_check(enemy.confidence > 0 and enemy.state == Listener.State.INVESTIGATING, "Same walking sound audible through open door")
	enemy.enabled = false
	player.global_position = door.global_position + Vector3.UP * .03
	await _frames(3)
	door.use()
	_check(door.opened, "Door refuses to close through a body in its threshold")
	player.global_position = Vector3(-2.44, .03, -17)
	door.use()
	await _frames(80)
	_check(not door.opened and absf(door.angle) < .01, "Door closes after threshold is vacated")
	_check(mark.global_position.distance_to(marked_position) > .25, "Puncture moves with closing door")
	enemy.reset_at(Vector3(-2.44, .03, -12.3))
	enemy.enabled = true
	_emit_step(player.global_position, 1)
	await _frames(130)
	_check(door.opened and absf(door.angle) > .5, "Listener investigating a loud clue physically opens obstructing door")
	enemy.enabled = false
	section.office_relay.use()
	await _frames(50)
	section.office_relay.use()
	var saved: Dictionary = SaveSystem.load_checkpoint().payload
	_check(saved["world"]["doors"][door.door_id] == "open", "Checkpoint stores stable semantic door state")
	door.restore(false)
	player.take_damage(100)
	GameFlow.continue_game()
	await _frames(10)
	_check(door.opened and GameFlow.state == NullGameFlow.State.PLAYING, "Death restore reinstates open door and safe player")
	# Native unarmed-export-01 trapped the Listener at the open west leaf for >7s.
	# Reproduce that real corner, keeping the player hidden and the old clue fixed.
	var west: SectionDoor = section.doors[1]
	enemy.enabled = false
	player.global_position = Vector3(20.4, .03, -19.0)
	west.set_open(true, Vector3(-4, .03, -10.98))
	await _frames(80)
	enemy.reset_at(Vector3(-6.82, .03, -11.88))
	await _frames(3)
	enemy.enabled = true
	var clue := Vector3(-7.8, .03, -19.0)
	enemy.hear_at(clue, .9, &"sprint_step", SimulationClock.sample())
	var corner_path: Array[Dictionary] = []
	for i: int in 5:
		await _frames(60)
		var contacts: Array[String] = []
		for j: int in enemy.get_slide_collision_count():
			contacts.append(str(enemy.get_slide_collision(j).get_collider()))
		corner_path.append({"at": enemy.global_position, "detour": enemy._door_detour,
			"detour_time": enemy._door_detour_time, "blocked": enemy._blocked_time,
			"next": enemy.navigation.get_next_path_position(), "contacts": contacts})
	_check(enemy.global_position.z < -15, "Listener routes past open west leaf instead of pinning against it")
	_check(enemy.evidence_position.distance_to(clue) < .05 and not enemy.sees_player,
		"Open-leaf detour does not reveal hidden player or replace remembered clue")
	print(JSON.stringify({"suite": "Door actual-scene risks", "checks": checks, "failures": failures,
		"west_corner_path": corner_path,
		"scope": "automated physics fixtures; no auditory or experiential claim"}))
	section.request_quit(0 if failures.is_empty() else 1)

func _emit_step(position: Vector3, intensity: float) -> void:
	var event := SoundEvent.new()
	var stamp: SimulationStamp = SimulationClock.sample()
	event.source_id = &"section_player"
	event.kind = &"walk_step" if intensity < 1 else &"pistol_shot"
	event.position = position
	event.intensity = intensity
	event.simulation_epoch = stamp.epoch
	event.simulation_seconds = stamp.elapsed_seconds
	EventHub.submit_sound(event)

func _frames(count: int) -> void:
	for i: int in count: await get_tree().physics_frame

func _check(value: bool, description: String) -> void:
	checks += 1
	if not value: failures.append(description)
