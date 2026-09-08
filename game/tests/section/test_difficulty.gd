extends Node
## Four-mode configuration, objective, persistence and restart risks in the real Room 1 scene.

var checks: int = 0
var failures: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var isolated := DirAccess.create_temp("nullspace_difficulty_test", true)
	if isolated == null:
		get_tree().quit(2)
		return
	SaveSystem.storage_directory = isolated.get_current_dir().path_join("saves")
	SettingsManager.storage_directory = isolated.get_current_dir().path_join("preferences")
	SettingsManager.reload_settings()
	var section := preload("res://section/section.tscn").instantiate() as NullspaceSection
	add_child(section)
	section.listener.enabled = false
	await _frames(5)
	_check(section.menu.selected_difficulty == "medium", "Pre-game selection defaults to Medium")
	for id: String in DifficultyConfig.IDS:
		GameFlow.return_to_menu()
		if id == "easy":
			section.menu.start_requested.emit(id)
		else:
			GameFlow.begin_new_game(id)
		await _frames(10)
		var profile := DifficultyConfig.profile(id)
		var saved := SaveSystem.load_checkpoint()
		_check(GameFlow.state == NullGameFlow.State.PLAYING and section.difficulty_id == id,
			id + " starts the actual Room 1 scene")
		_check(saved.ok and DifficultyConfig.from_snapshot(saved.payload) == id,
			id + " selection is committed to the run")
		_check(is_equal_approx(section.listener.difficulty_speed, float(profile["monster_speed"])),
			id + " applies its Listener speed multiplier")
		_check(is_equal_approx(section.room.difficulty_energy, float(profile["fixture_energy"]))
			and is_equal_approx(section.sound.atmosphere_intensity, float(profile["atmosphere"])),
			id + " applies lighting and atmosphere values")
		_check(section.service_relay.visible == (id != "easy")
			and section.emergency_relay.visible == (id in ["hard", "nightmare"])
			and section.fuse_pickup.visible == (id == "nightmare"),
			id + " exposes only its required task objects")
		await _activate(section.office_relay)
		if id != "easy":
			_check(section.exit_door.locked, id + " cannot exit after only one switch")
			await _activate(section.service_relay)
		if id in ["hard", "nightmare"]:
			_check(section.exit_door.locked, id + " requires the third switch")
			if id == "hard":
				section.emergency_relay.use()
				_check(section.emergency_relay.latch_released, "Hard releases the safety latch before Emergency C")
			else:
				section.fuse_pickup.use()
				_check(bool(section._snapshot["world"]["circuits"]["emergency_fuse_carried"]),
					"Nightmare collects the marked fuse")
				_check("Carry the marked fuse" in section.menu.objective,
					"Nightmare updates the objective after collecting the fuse")
				section.emergency_relay.use()
				_check(section.emergency_relay.fuse_inserted, "Nightmare inserts the fuse before Emergency C")
			await _activate(section.emergency_relay)
		_check(not section.exit_door.locked, id + " unlocks the exit after exactly its required switches")
		section.player.take_damage(100)
		GameFlow.continue_game()
		await _frames(10)
		_check(GameFlow.state == NullGameFlow.State.PLAYING and section.difficulty_id == id
			and not section.exit_door.locked, id + " death/restart preserves mode and solvable objective state")
		section.finish_escape()
		_check(GameFlow.state == NullGameFlow.State.ENDING and SaveSystem.load_checkpoint().payload["progress"]["ending"],
			id + " commits a valid ending with its own required switch set")
	print(JSON.stringify({"suite": "Room 1 difficulty risks", "checks": checks, "failures": failures,
		"scope": "automated actual-scene configuration/objective/restart checks; not subjective play feel or listening"}))
	section.request_quit(0 if failures.is_empty() else 1)

func _activate(relay: PowerRelay) -> void:
	relay.use()
	await _frames(50)
	relay.use()

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures.append(description)
