extends Node
## Logical checks only. These are not independent experiential play or production QA.

var _failures: PackedStringArray = []
var _checks: int = 0
var _directory: String

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func _run() -> void:
	var temporary: DirAccess = DirAccess.create_temp("nullspace_core_tests", true)
	if temporary == null:
		push_error("Could not create an isolated test directory.")
		get_tree().quit(2)
		return
	_directory = temporary.get_current_dir()
	await get_tree().process_frame
	_test_snapshot_validation()
	_test_storage_transactions()
	_test_settings()
	await _test_flow_and_input()
	_test_passive_telemetry()
	print(JSON.stringify({"suite": "M2 core", "checks": _checks, "failures": _failures,
		"engine": Engine.get_version_info(), "isolated_data": _directory,
		"scope": "logical tests, not gameplay or experiential validation"}, "\t"))
	get_tree().quit(0 if _failures.is_empty() else 1)

func _check(condition: bool, name: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(name)
		push_error(name)

func _test_snapshot_validation() -> void:
	var initial: Dictionary = SnapshotSchema.initial_snapshot()
	_check(SnapshotSchema.validate(initial).is_empty(), "Default snapshot is valid")
	var changed: Dictionary = initial.duplicate(true)
	changed.erase("world")
	_check(not SnapshotSchema.validate(changed).is_empty(), "Missing section rejected")
	changed = initial.duplicate(true)
	changed["player"]["health"] = 0
	_check(not SnapshotSchema.validate(changed).is_empty(), "Dead checkpoint rejected")
	changed = initial.duplicate(true)
	changed["player"]["health"] = NAN
	_check(not SnapshotSchema.validate(changed).is_empty(), "NaN health rejected")
	changed = initial.duplicate(true)
	changed["inventory"]["weapons"]["pistol"]["magazine"] = 12.5
	_check(not SnapshotSchema.validate(changed).is_empty(), "Fractional ammo rejected")
	changed["inventory"]["weapons"]["pistol"]["magazine"] = 13
	_check(not SnapshotSchema.validate(changed).is_empty(), "Magazine overflow rejected independently of chamber")
	changed["inventory"]["weapons"]["pistol"]["magazine"] = 12
	_check(SnapshotSchema.validate(changed).is_empty(), "12 magazine plus 1 chamber accepted")
	changed["inventory"]["weapons"]["pistol"]["chamber"] = 2
	_check(not SnapshotSchema.validate(changed).is_empty(), "Two chambered rounds rejected")
	changed = initial.duplicate(true)
	changed["player"]["equipped_weapon"] = "shotgun"
	_check(not SnapshotSchema.validate(changed).is_empty(), "Unowned equipped weapon rejected")
	changed = initial.duplicate(true)
	changed["progress"]["phase_breaker"] = true
	_check(not SnapshotSchema.validate(changed).is_empty(), "Phase breaker without all relays rejected")
	changed = initial.duplicate(true)
	changed["progress"]["ending"] = true
	_check(not SnapshotSchema.validate(changed).is_empty(), "Ending without final progression rejected")
	changed = initial.duplicate(true)
	changed["world"]["doors"] = {"service_door": "opening"}
	_check(not SnapshotSchema.validate(changed).is_empty(), "Uncommitted door animation rejected")
	changed = initial.duplicate(true)
	changed["world"]["consumed_pickups"] = ["cache_1", "cache_1"]
	_check(not SnapshotSchema.validate(changed).is_empty(), "Duplicate consumed pickups rejected")
	changed = initial.duplicate(true)
	changed["checkpoint"]["monster_anchor"] = changed["checkpoint"]["player_anchor"]
	_check(not SnapshotSchema.validate(changed).is_empty(), "Identical player and monster checkpoint anchors rejected")
	changed = initial.duplicate(true)
	changed["progress"]["relays"]["circulation"] = []
	_check(not SnapshotSchema.validate(changed).is_empty(), "Array masquerading as relay flag rejected without throwing")
	changed = initial.duplicate(true)
	changed["progress"]["phase_breaker"] = {"enabled": true}
	_check(not SnapshotSchema.validate(changed).is_empty(), "Object masquerading as progress flag rejected without throwing")
	changed = initial.duplicate(true)
	changed["world"]["doors"]["service_door"] = ["closed"]
	_check(not SnapshotSchema.validate(changed).is_empty(), "Array masquerading as committed door state rejected without throwing")
	changed = initial.duplicate(true)
	changed["campaign_id"] = {"name": SnapshotSchema.CAMPAIGN_ID}
	_check(not SnapshotSchema.validate(changed).is_empty(), "Object masquerading as campaign identity rejected")
	changed = initial.duplicate(true)
	changed["checkpoint"]["player_anchor"] = []
	_check(not SnapshotSchema.validate(changed).is_empty(), "Non-string checkpoint anchor rejected")
	changed = initial.duplicate(true)
	changed["player"]["equipped_weapon"] = ["pistol"]
	_check(not SnapshotSchema.validate(changed).is_empty(), "Non-string equipped weapon rejected")

func _test_storage_transactions() -> void:
	var path: String = _directory.path_join("checkpoint.json")
	var store: AtomicJsonStore = AtomicJsonStore.new(path, "checkpoint", SnapshotSchema.VERSION, SnapshotSchema.validate, SnapshotSchema.normalize)
	_check(store.read().code == &"missing", "Missing checkpoint handled")
	var first: Dictionary = SnapshotSchema.initial_snapshot()
	first["inventory"]["weapons"]["pistol"] = {"owned": true, "chamber": 1, "magazine": 12, "reserve": 3}
	first["inventory"]["weapons"]["shotgun"] = {"owned": true, "chamber": 1, "magazine": 5, "reserve": 2}
	first["world"]["doors"] = {"service_door": "open"}
	first["world"]["consumed_pickups"] = ["cache_1"]
	first["progress"]["relays"]["distribution"] = true
	_check(store.write(first).ok, "First checkpoint writes")
	var loaded: StorageResult = store.read()
	_check(loaded.ok and loaded.payload == first, "Every snapshot section roundtrips")
	loaded.payload["inventory"]["weapons"]["pistol"]["reserve"] = 999
	_check(store.read().payload == first, "Read payload is an isolated value")
	var second: Dictionary = first.duplicate(true)
	second["player"]["health"] = 35.0
	second["world"]["doors"]["service_door"] = "closed"
	_check(store.write(second).ok and store.read().payload == second, "Atomic replacement saves new state")
	_write_text(path, "{\"payload_json\":")
	loaded = store.read()
	_check(loaded.ok and loaded.recovered and loaded.payload == first, "Truncated primary recovers previous validated checkpoint")
	_check(store.write(second).ok, "Write repairs primary without poisoning backup")
	_write_text(path, "{}")
	loaded = store.read()
	_check(loaded.ok and loaded.recovered and loaded.payload == first, "Incomplete envelope recovers backup")
	_write_text(path + ".backup", "broken")
	_check(not store.read().ok, "Two corrupt copies fail without resetting progress")
	_check(store.write(first).ok, "Explicit new valid snapshot can replace corrupt copies")
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var valid_json: String = file.get_as_text()
	file.close()
	var envelope: Dictionary = JSON.parse_string(valid_json)
	envelope["sha256"] = "bad"
	_write_text(path, JSON.stringify(envelope))
	_check(not store.read().ok, "Checksum mismatch without valid backup rejected")
	envelope = JSON.parse_string(valid_json)
	envelope["content_version"] = 999
	_write_text(path, JSON.stringify(envelope))
	_check(store.read().code == &"incompatible", "Future version explicitly rejected")
	_check(store.write(first).code == &"incompatible", "Older build cannot overwrite future save")
	_write_text(path, valid_json)
	DirAccess.make_dir_absolute(path + ".tmp")
	_check(not store.write(second).ok and store.read().payload == first, "Staging I/O failure preserves good checkpoint")
	var invalid: Dictionary = first.duplicate(true)
	invalid["inventory"]["weapons"]["pistol"]["reserve"] = -1
	_check(not store.write(invalid).ok and store.read().payload == first, "Invalid snapshot cannot damage saved state")
	# An interrupted tmp is never interpreted as committed progress.
	var orphan: AtomicJsonStore = AtomicJsonStore.new(_directory.path_join("orphan.json"), "checkpoint", 1, SnapshotSchema.validate)
	_write_text(orphan.path + ".tmp", valid_json)
	_check(orphan.read().code == &"missing", "Uncommitted orphan temp is ignored")

func _test_settings() -> void:
	var defaults: Dictionary = SettingsSchema.defaults()
	_check(SettingsSchema.validate(defaults).is_empty(), "All contract settings have valid defaults")
	var changed: Dictionary = defaults.duplicate(true)
	changed["mouse_sensitivity"] = 0
	_check(not SettingsSchema.validate(changed).is_empty(), "Zero mouse sensitivity rejected")
	changed = defaults.duplicate(true)
	changed["resolution"] = [1920]
	_check(not SettingsSchema.validate(changed).is_empty(), "Malformed resolution rejected")
	changed = defaults.duplicate(true)
	changed["invert_y"] = "true"
	_check(not SettingsSchema.validate(changed).is_empty(), "Wrong boolean type rejected")
	_check(is_equal_approx(SettingsSchema.vertical_fov(90.0, 16.0 / 9.0), 58.715507), "Horizontal FOV conversion explicit")
	SettingsManager.storage_directory = _directory.path_join("settings")
	changed = defaults.duplicate(true)
	changed["master_volume"] = 0.0
	changed["ambience_volume"] = 0.45
	changed["effects_volume"] = 0.6
	changed["horizontal_fov"] = 100.0
	changed["head_bob"] = 0.0
	changed["camera_shake"] = 0.0
	changed["reduced_flashes"] = true
	changed["invert_y"] = true
	changed["quality"] = "low"
	_check(SettingsManager.apply_settings(changed).ok, "Settings atomically persist")
	_check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "Zero master volume mutes the bus")
	_check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Weapons"))), 0.6), "Effects volume applies to Weapons bus")
	_check(SettingsManager.current_quality().id == &"low" and is_equal_approx(get_viewport().scaling_3d_scale, 0.75), "Low profile applies render scale")
	_check(SettingsManager.reload_settings().ok and SettingsManager.snapshot() == changed, "All settings survive reload")
	var invalid: Dictionary = changed.duplicate(true)
	invalid.erase("center_dot")
	_check(not SettingsManager.apply_settings(invalid).ok and SettingsManager.snapshot() == changed, "Incomplete settings preserve current state")
	_write_text(SettingsManager.storage_directory.path_join("settings.json"), "bad settings")
	_check(not SettingsManager.reload_settings().ok and SettingsManager.snapshot() == defaults, "Corrupt settings use complete defaults with reported failure")
	for id: String in SettingsSchema.QUALITY_IDS:
		var profile_settings: Dictionary = defaults.duplicate(true)
		profile_settings["quality"] = id
		_check(SettingsManager.apply_settings(profile_settings).ok and String(SettingsManager.current_quality().id) == id, "Quality profile applies: " + id)

func _test_flow_and_input() -> void:
	SaveSystem.storage_directory = _directory.path_join("flow")
	InputGate.focused = true
	GameFlow.return_to_menu()
	_check(not GameFlow.complete_load(100), "Unsolicited load completion rejected")
	_check(not GameFlow.continue_game().ok and GameFlow.state == NullGameFlow.State.MENU, "Missing Continue leaves title active")
	_check(GameFlow.begin_new_game().ok and GameFlow.state == NullGameFlow.State.LOADING, "New game waits for explicit restore acknowledgment")
	_check(not InputGate.gameplay_enabled and get_tree().paused, "Loading gates input and simulation")
	var load_generation: int = GameFlow.pending_generation
	_check(not GameFlow.complete_load(load_generation + 1), "Stale load generation rejected")
	InputGate.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(GameFlow.complete_load(load_generation) and GameFlow.state == NullGameFlow.State.PAUSED and get_tree().paused,
		"Load completed without focus stays paused")
	_check(not GameFlow.resume_game() and not InputGate.gameplay_enabled, "Unfocused completed load cannot resume")
	InputGate.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	_check(GameFlow.state == NullGameFlow.State.PAUSED and not InputGate.gameplay_enabled,
		"Focus return after completed load still requires explicit resume")
	_check(GameFlow.resume_game(), "Explicit resume after focused load recaptures input")
	GameFlow.return_to_menu()
	GameFlow.continue_game()
	load_generation = GameFlow.pending_generation
	_check(GameFlow.complete_load(load_generation), "Matching restore acknowledgment enters gameplay")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_check(InputGate.accepts_input() and not get_tree().paused, "Gameplay accepts input after barrier")
	var action_generation: int = InputGate.generation
	Input.action_press(&"fire")
	Input.action_press(&"move_forward")
	GameFlow.pause_game()
	_check(not InputGate.pressed(&"fire") and InputGate.movement_vector() == Vector2.ZERO, "Pause rejects held actions and movement")
	_check(not InputGate.accepts_generation(action_generation), "Pause invalidates pending action generation")
	GameFlow.open_settings()
	_check(GameFlow.state == NullGameFlow.State.SETTINGS, "Settings can open from pause")
	GameFlow.close_settings()
	_check(GameFlow.state == NullGameFlow.State.PAUSED, "Settings returns to pause without resuming")
	GameFlow.resume_game()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_check(not InputGate.pressed(&"fire") and InputGate.movement_vector() == Vector2.ZERO, "Held fire and movement remain blocked after resume")
	Input.action_release(&"fire")
	Input.action_release(&"move_forward")
	await get_tree().process_frame
	await get_tree().process_frame
	Input.action_press(&"fire")
	_check(InputGate.pressed(&"fire"), "Fresh press works after release")
	Input.action_release(&"fire")
	InputGate.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(GameFlow.state == NullGameFlow.State.PAUSED and not InputGate.focused, "Focus loss pauses and clears ownership")
	InputGate.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	_check(GameFlow.state == NullGameFlow.State.PAUSED and not InputGate.gameplay_enabled, "Focus return does not auto-resume")
	GameFlow.resume_game()
	GameFlow.die()
	_check(GameFlow.state == NullGameFlow.State.DEAD and not InputGate.gameplay_enabled, "Death gates input")
	_check(GameFlow.continue_game().ok and GameFlow.pending_generation != load_generation, "Death restore advances checkpoint generation")
	_check(not GameFlow.complete_load(load_generation), "Old pre-death load cannot acknowledge new restore")
	GameFlow.complete_load(GameFlow.pending_generation)
	_check(not GameFlow.end_campaign(), "Ending unavailable before committed final progress")
	var complete: Dictionary = CheckpointSystem.current_snapshot()
	for relay: String in SnapshotSchema.RELAYS:
		complete["progress"]["relays"][relay] = true
	for flag: String in ["phase_breaker", "exit_isolator", "ending"]:
		complete["progress"][flag] = true
	_check(CheckpointSystem.commit_snapshot(complete).ok and GameFlow.end_campaign(), "Committed final flags permit ending state")
	GameFlow.return_to_menu()
	_check(not SaveSystem.continue_available() and not GameFlow.continue_game().ok, "Completed campaign cannot be continued into invalid play")

func _test_passive_telemetry() -> void:
	var initial_state: NullGameFlow.State = GameFlow.state
	var initial_generation: int = InputGate.generation
	Telemetry.reset_metrics()
	Telemetry.record_metric(&"damage", {"amount": 15.0})
	Telemetry.record_metric(&"ammo_collected", {"weapon_id": "pistol", "amount": 3})
	Telemetry.record_metric(&"chase_started", {})
	Telemetry.record_metric(&"chase_started", {})
	Telemetry.record_metric(&"chase_ended", {})
	Telemetry.record_metric(&"search_started", {})
	Telemetry.record_metric(&"false_investigation", {})
	_check(Telemetry.metrics["damage_taken"] == 15.0 and Telemetry.metrics["ammo_collected"]["pistol"] == 3, "Telemetry aggregates damage and ammo")
	_check(Telemetry.metrics["chases"] == 1 and Telemetry.metrics["searches"] == 1 and Telemetry.metrics["false_investigations"] == 1, "Telemetry avoids double-start chase count")
	_check(GameFlow.state == initial_state and InputGate.generation == initial_generation, "Telemetry does not change game or input state")

func _write_text(path: String, contents: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "Test fixture write failed: " + path)
		return
	file.store_string(contents)
	file.close()
