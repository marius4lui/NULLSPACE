extends Node
## Small-map completion/save risks in the real scene. Scripted fixture placement, NOT a playthrough.
var checks: int = 0
var failures: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var section := preload("res://section/section.tscn").instantiate() as NullspaceSection
	add_child(section)
	section.listener.enabled = false # This isolates objective/restore risks; native runs cover escape under threat.
	await _frames(5)
	GameFlow.begin_new_game()
	await _frames(10)
	var map: RID = section.get_world_3d().navigation_map
	for destination: Vector3 in [NullspaceSection.OFFICE_SAFE.origin, NullspaceSection.SERVICE_SAFE.origin,
		Vector3(-7.1, .1, -20), Vector3(14.6, .1, -18.8), Vector3(2.44, .1, 9.8)]:
		var path: PackedVector3Array = NavigationServer3D.map_get_path(map, section.player.global_position, destination, true)
		_check(path.size() > 1 and path[-1].distance_to(destination) < .3,
			"Walkable navigation connects arrival to " + str(destination))
	section.exit_door.use()
	section.finish_escape()
	_check(section.exit_door.locked and not section.exit_door.opened and GameFlow.state == NullGameFlow.State.PLAYING,
		"Exit cannot open or finish before either circuit")
	for order: Array in [[section.office_relay, section.service_relay], [section.service_relay, section.office_relay]]:
		GameFlow.return_to_menu()
		GameFlow.begin_new_game()
		await _frames(10)
		for i: int in 2:
			var relay: PowerRelay = order[i]
			relay.use()
			_check(not relay.powered, "Opening cabinet alone does not restore power")
			await _frames(50)
			relay.use()
			var saved: StorageResult = SaveSystem.load_checkpoint()
			_check(saved.ok and saved.payload["progress"]["relays"][relay.relay_id], "Two-action physical relay commits power")
			_check(section.exit_door.locked == (i == 0), "Exit needs BOTH separated circuits in either order")
			section.player.take_damage(100)
			GameFlow.continue_game()
			await _frames(10)
			var expected: Vector3 = NullspaceSection.OFFICE_SAFE.origin if relay == section.office_relay else NullspaceSection.SERVICE_SAFE.origin
			_check(GameFlow.state == NullGameFlow.State.PLAYING and section.player.global_position.distance_to(expected) < .15
				and section.listener.global_position.distance_to(section.player.global_position) > 12,
				"Death restores the correct clear checkpoint and distant Listener")
		# Actual capsule crosses the exit threshold using movement input, with no pistol/ammo requirement.
		section.player.restore_at(Transform3D(Basis(Vector3.UP, PI), Vector3(2.44, .025, 6.9)),
			SaveSystem.load_checkpoint().payload["player"])
		section.exit_door.use()
		await _frames(80)
		Input.action_press("move_forward")
		await _frames(60)
		Input.action_release("move_forward")
		_check(GameFlow.state == NullGameFlow.State.ENDING and SaveSystem.load_checkpoint().payload["progress"]["ending"],
			"Unarmed player walks through powered exit into committed ending")
		GameFlow.return_to_menu()
		var ended: StorageResult = GameFlow.continue_game()
		await _frames(10)
		# Retain the tested core policy: completed campaigns are not resumable gameplay saves.
		_check(not ended.ok and not SaveSystem.continue_available() and GameFlow.state == NullGameFlow.State.MENU
			and SaveSystem.load_checkpoint().payload["progress"]["ending"],
			"Completed campaign disables Continue without damaging its recorded ending")
	print(JSON.stringify({"suite": "two-switch escape risks", "checks": checks, "failures": failures,
		"scope": "automated scene fixtures and exit input; not full exploration, enemy evasion, listening or first-run duration"}))
	section.request_quit(0 if failures.is_empty() else 1)

func _frames(count: int) -> void:
	for i: int in count: await get_tree().physics_frame

func _check(value: bool, description: String) -> void:
	checks += 1
	if not value: failures.append(description)
