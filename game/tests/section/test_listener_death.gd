extends Node
## Automated fixtures in the actual game scene. The Listener's normal attack
## applies lethal damage; positioning/low health are explicit test setup.
var checks: int = 0
var failures: Array[String] = []
var section: NullspaceSection
var isolated: DirAccess
var native: bool = false
var frames: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	isolated = DirAccess.create_temp("nullspace_death_test", true)
	if isolated == null:
		get_tree().quit(2)
		return
	SaveSystem.storage_directory = isolated.get_current_dir().path_join("saves")
	SettingsManager.storage_directory = isolated.get_current_dir().path_join("preferences")
	SettingsManager.reload_settings()
	native = DisplayServer.get_name() != "headless"
	section = preload("res://section/section.tscn").instantiate() as NullspaceSection
	add_child(section)
	await _frames(5)
	var old: Dictionary = SettingsSchema.defaults()
	old.erase("blood_effects")
	old.erase("intense_death")
	old.erase("reduced_motion")
	old["mouse_sensitivity"] = 1.7
	old["head_bob"] = 0
	old["camera_shake"] = 0
	_check(SettingsSchema.validate(old).is_empty(), "Old v1 settings remain valid")
	var normalized: Dictionary = SettingsSchema.normalize(old)
	_check(normalized["blood_effects"] and normalized["mouse_sensitivity"] == 1.7
		and not SettingsSchema.death_motion_allowed(normalized), "Missing defaults added without overwriting old preferences or motion opt-out")
	old["blood_effects"] = "false"
	_check(not SettingsSchema.validate(old).is_empty(), "Malformed present blood setting rejected")
	GameFlow.begin_new_game()
	await _frames(10)
	if native:
		# Allow the external isolated capture supervisor to attach before motion.
		await get_tree().create_timer(12, true).timeout
	for combination: Array in [[true, true], [false, true], [true, false], [false, false]]:
		await _restart()
		await _settings(combination[0], combination[1], false)
		await _place(Vector3(2, .03, -8), Vector3(2, .03, -6.8))
		var start: Transform3D = section.player.camera.global_transform
		await _attack()
		_check(GameFlow.state == NullGameFlow.State.DYING, "Lethal impact enters DYING %s" % [combination])
		_check(section.death.pulling == combination[1], "Independent camera option %s" % [combination])
		_check(not InputGate.accepts_input() and get_tree().paused, "Death gates input and pauses gameplay")
		var began: float = section.death.elapsed
		section.player.take_damage(100, section.listener)
		section.death.begin(section.listener)
		_check(section.death.elapsed == began and section.player.health == 0, "Repeated damage/death cannot restart sequence")
		var event := InputEventAction.new()
		event.action = &"ui_accept"
		event.pressed = true
		section.death._unhandled_input(event)
		_check(section.death.active, "Early skip is ignored")
		var saw_blood: bool = false
		var max_distance: float = 0
		var camera_safe: bool = true
		while GameFlow.state == NullGameFlow.State.DYING:
			await get_tree().process_frame
			for drop: MeshInstance3D in section.death._drops: saw_blood = saw_blood or drop.visible
			max_distance = maxf(max_distance, start.origin.distance_to(section.player.camera.global_position))
			camera_safe = camera_safe and section.death._clear_path(section.player.camera.global_position, section.player.camera.global_position)
		_check(GameFlow.state == NullGameFlow.State.DEAD, "Sequence reaches existing death screen")
		_check(saw_blood == combination[0], "Blood visibility independent %s" % [combination])
		_check(camera_safe, "Camera volume never intersects room/door/monster")
		_check(max_distance > .2 if combination[1] else max_distance < .001, "Camera moves only when allowed")
		_check(not section.death._voice.playing, "Death audio stops at death screen")
		print("DEATH_CASE ", JSON.stringify({"blood": combination[0], "intense": combination[1], "max_camera_distance": max_distance, "duration": section.death.elapsed}))
		await get_tree().create_timer(.9, true).timeout
	await _restart()
	await _settings(true, true, true)
	await _place(Vector3(2, .03, -8), Vector3(2, .03, -6.8))
	await _attack()
	_check(not section.death.pulling, "Reduce motion overrides intense death")
	await get_tree().create_timer(1, true).timeout
	await _restart()
	await _settings(true, true, false)
	# Existing partition fixture: within range but with a solid wall between bodies.
	await _place(Vector3(-1, .03, -6.5), Vector3(-1, .03, -5.65))
	section.listener.enabled = true
	section.listener._set_state(Listener.State.ATTACKING)
	await get_tree().create_timer(.8, true).timeout
	_check(section.player.health == 40 and not section.death.active, "No lethal hit through real partition")
	section.listener.enabled = false
	await _place(Vector3(2, .03, -8), Vector3(2, .03, -5.8))
	section.listener.enabled = true
	section.listener._set_state(Listener.State.ATTACKING)
	await get_tree().create_timer(.8, true).timeout
	_check(section.player.health == 40 and not section.death.active, "Committed attack cannot hit outside reach")
	section.listener.enabled = false
	# Thin obstacle only in the camera sweep, above the physical damage ray.
	await _place(Vector3(2, .03, -8), Vector3(2, .03, -6.8))
	var obstruction := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1, .12, .08)
	shape.shape = box
	obstruction.add_child(shape)
	obstruction.position = Vector3(2, 1.7, -7.05)
	section.add_child(obstruction)
	await _frames(3)
	await _attack()
	_check(GameFlow.state == NullGameFlow.State.DYING and not section.death.pulling, "Obstructed grab uses local fallback after valid hit")
	await get_tree().create_timer(1, true).timeout
	obstruction.queue_free()
	await _restart()
	await _place(Vector3(2, .03, -8), Vector3(2, .03, -6.8))
	await _attack()
	await get_tree().create_timer(.70, true).timeout
	var skip := InputEventAction.new()
	skip.action = &"pause"
	skip.pressed = true
	Input.parse_input_event(skip)
	await _frames(2)
	_check(GameFlow.state == NullGameFlow.State.DEAD, "Escape skips through actual input dispatch after minimum")
	await _restart()
	section.player.take_damage(100)
	_check(section.death._attacker == null and not section.death.pulling, "Other damage cause never grabs")
	await get_tree().create_timer(1, true).timeout
	# Explicitly remove only this fixture's checkpoint, then test the real fallback button.
	for file: String in DirAccess.get_files_at(SaveSystem.storage_directory):
		DirAccess.remove_absolute(SaveSystem.storage_directory.path_join(file))
	section.menu._show_screen()
	var restart: Button
	for child: Node in section.menu._stack.get_children():
		if child is Button and child.text == "Restart": restart = child
	_check(restart != null, "No checkpoint shows Restart instead of broken Continue")
	if restart: restart.pressed.emit()
	await _frames(12)
	_check(GameFlow.state == NullGameFlow.State.PLAYING, "Fallback Restart starts a valid new game")
	print(JSON.stringify({"suite": "Listener death", "checks": checks, "failures": failures,
		"method": "automated actual-scene lethal attack fixtures", "native": native}))
	section.request_quit(0 if failures.is_empty() else 1)

func _settings(blood: bool, intense: bool, reduced: bool) -> void:
	var values: Dictionary = SettingsSchema.defaults()
	values["blood_effects"] = blood
	values["intense_death"] = intense
	values["reduced_motion"] = reduced
	_check(SettingsManager.apply_settings(values).ok, "Save independent settings")
	SettingsManager.reload_settings()
	_check(SettingsManager.snapshot() == values, "Preferences survive disk reload")
	await _frames(2)

func _place(enemy: Vector3, player: Vector3) -> void:
	section.listener.enabled = false
	section.listener.reset_at(enemy)
	section.listener.rotation.y = PI
	section.player.restore_at(Transform3D(Basis.IDENTITY, player), SnapshotSchema.initial_snapshot()["player"])
	section.player.health = 40
	await _frames(3)

func _attack() -> void:
	section.listener.enabled = true
	section.listener._set_state(Listener.State.ATTACKING)
	section.listener.evidence_position = section.player.global_position
	var timeout: float = 0
	while GameFlow.state == NullGameFlow.State.PLAYING and timeout < 1:
		await get_tree().physics_frame
		timeout += 1.0 / 60

func _restart() -> void:
	if GameFlow.state == NullGameFlow.State.DEAD: GameFlow.continue_game()
	else:
		GameFlow.return_to_menu()
		GameFlow.begin_new_game()
	await _frames(12)
	_check(GameFlow.state == NullGameFlow.State.PLAYING and section.player.health == 100, "Checkpoint restores live player")
	_check(section.player.camera.position.length() < .02 and section.player.camera.rotation.length() < .001
		and not section.death.active and not section.death._voice.playing
		and section.listener.animation.callback_mode_process != AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL,
		"Checkpoint clears camera ownership, audio and monster animation mode")
	for drop: MeshInstance3D in section.death._drops: _check(not drop.visible, "No old blood after restart")

func _frames(count: int) -> void:
	for i: int in count: await get_tree().physics_frame

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
