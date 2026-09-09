extends "res://tests/section/test_listener_death.gd"
## Same fixture helpers, actual authored wall/door scenarios, no extra game path.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	isolated = DirAccess.create_temp("nullspace_death_edges", true)
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
	GameFlow.begin_new_game()
	await _frames(12)
	var live_camera: Transform3D = section.player.camera.global_transform
	GameFlow.return_to_menu()
	_check(section.player.camera.global_transform.is_equal_approx(live_camera), "Returning to menu before any death preserves the live scene camera")
	GameFlow.begin_new_game()
	await _frames(12)
	if native:
		print("DEATH_CAPTURE_READY")
		await get_tree().create_timer(12, true).timeout
	await _settings(true, true, false)
	await _place(Vector3(-8.1, .03, -22), Vector3(-8.1, .03, -20.8))
	await _attack()
	_check(not section.death.pulling, "Archive wall leaves insufficient room for both reaching arms")
	await _observe("Beside authored archive wall")
	await _restart()
	await _place(Vector3(-2.44, .03, -15.2), Vector3(-2.44, .03, -14.05))
	var door: SectionDoor = section.doors[0]
	door.restore(false)
	await _frames(3)
	await _attack()
	_check(section.player.health == 40 and not section.death.active, "Closed authored door blocks lethal attack")
	section.listener.enabled = false
	door.restore(true)
	await _frames(4)
	section.listener._set_state(Listener.State.ROAMING)
	await _attack()
	await _observe("Through open authored doorway")
	await _restart()
	await _place(Vector3(2, .03, -8), Vector3(2, .03, -6.8))
	section.player.rotation.y = PI
	await _attack()
	_check(not section.death.pulling, "Looking away does not cause a forced half-turn")
	await _observe("Facing away local fallback")
	await _restart()
	await _place(Vector3(2, .03, -8), Vector3(2, .03, -6.8))
	Input.action_press("crouch")
	await _frames(15)
	Input.action_release("crouch")
	# Keep crouch held until the impact, as in an actual corner encounter.
	Input.action_press("crouch")
	await _attack()
	Input.action_release("crouch")
	_check(not section.death.pulling, "Crouched victim is not pulled upward into a standing camera pose")
	await _observe("Crouched local fallback")
	await _restart()
	print(JSON.stringify({"suite": "Death actual wall/door", "checks": checks, "failures": failures, "native": native}))
	section.request_quit(0 if failures.is_empty() else 1)

func _observe(label: String) -> void:
	_check(GameFlow.state == NullGameFlow.State.DYING, label + ": valid lethal hit starts sequence")
	var safe: bool = true
	var body: Vector3 = section.player.global_position
	var monster: Vector3 = section.listener.global_position
	var camera_previous: Vector3 = section.player.camera.global_position
	while GameFlow.state == NullGameFlow.State.DYING:
		await get_tree().process_frame
		var now: Vector3 = section.player.camera.global_position
		safe = safe and section.death._clear_path(camera_previous, now)
		camera_previous = now
	_check(safe, label + ": every actual camera segment stays clear")
	_check(section.player.global_position == body and section.listener.global_position == monster,
		label + ": both bodies stay fixed during animation")
	_check(GameFlow.state == NullGameFlow.State.DEAD, label + ": reaches death menu")
	print("EDGE_CASE ", label, " pull=", section.death.pulling, " duration=", section.death.elapsed)
	await get_tree().create_timer(.9, true).timeout
