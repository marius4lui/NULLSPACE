extends Node
## Automated real-scene touch regression. Not physical-device or feel acceptance.
var checks: int = 0
var failures: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var isolated := DirAccess.create_temp("nullspace_touch_test", true)
	SaveSystem.storage_directory = isolated.get_current_dir().path_join("saves")
	SettingsManager.storage_directory = isolated.get_current_dir().path_join("preferences")
	SettingsManager.reload_settings()
	var old: Dictionary = SettingsSchema.defaults()
	for key: String in ["touch_sensitivity", "touch_size", "touch_opacity"]: old.erase(key)
	_check(SettingsSchema.validate(old).is_empty(), "Previous preferences remain valid")
	_check(SettingsSchema.normalize(old)["touch_sensitivity"] == 1.0, "Previous preferences gain touch defaults")
	var section := preload("res://section/section.tscn").instantiate() as NullspaceSection
	add_child(section)
	section.listener.enabled = false
	await _frames(5)
	var overlay := section.find_child("TouchControls", true, false) as SectionTouchControls
	_check(overlay != null, "Concrete touch scene attached")
	if overlay == null:
		get_tree().quit(1)
		return
	_check(GameFlow.begin_new_game().ok, "New game loads")
	await _frames(10)
	section.pistol_pickup.use()
	await _frames(40)
	var initial_position: Vector3 = section.player.position
	_press(1, overlay.stick_center + Vector2(0, -overlay.stick_radius * 0.5))
	await _frames(2)
	_check(InputGate.movement_vector().length() > 0.3 and InputGate.movement_vector().length() < 0.8, "Analog movement retains partial strength")
	var look_at := Vector2(overlay.safe.get_center().x + 50, 150)
	_press(2, look_at)
	await _frames(1)
	var yaw: float = section.player.rotation.y
	_drag(2, look_at + Vector2(50, 0), Vector2(50, 0))
	await _frames(2)
	_check(section.player.rotation.y < yaw, "Second finger changes actual player aim")
	_press(3, overlay.buttons[&"fire"])
	await _frames(20)
	_check(section.pistol.shots_fired == 1, "Third finger fires once while moving and aiming")
	_press(3, overlay.buttons[&"fire"])
	_drag(3, overlay.buttons[&"fire"] + Vector2(20, 0), Vector2(20, 0))
	await _frames(20)
	_check(section.pistol.shots_fired == 1, "Held/duplicate fire and fire dragging do not repeat shots")
	_check(section.player.position.distance_to(initial_position) > 0.1, "Touch movement moves real CharacterBody")
	_release(3)
	await _frames(1)
	_press(3, overlay.buttons[&"fire"])
	await _frames(3)
	_check(section.pistol.shots_fired == 2, "New tap fires another shot")
	GameFlow.pause_game()
	await _frames(2)
	_check(overlay.fingers.is_empty() and InputGate.movement_vector() == Vector2.ZERO, "Pause clears every finger and analog movement")
	var shots: int = section.pistol.shots_fired
	InputGate.touch_action(&"fire")
	await _frames(2)
	_check(section.pistol.shots_fired == shots, "Paused touch action rejected")
	GameFlow.resume_game()
	await _frames(5)
	_drag(1, overlay.stick_center + Vector2(100, 0), Vector2(100, 0))
	await _frames(2)
	_check(InputGate.movement_vector() == Vector2.ZERO, "Old drag cannot resume movement")
	_press(4, overlay.buttons[&"sprint"])
	await _frames(2)
	_check(InputGate.pressed(&"sprint"), "Sprint toggles on")
	InputGate.set_touch_held(&"sprint", false)
	_check(not InputGate.pressed(&"sprint"), "Exhaustion can clear sprint toggle")
	_release(4)
	_press(5, overlay.buttons[&"crouch"])
	await _frames(2)
	_check(InputGate.pressed(&"crouch"), "Crouch toggles on")
	InputGate._notification(NOTIFICATION_APPLICATION_PAUSED)
	await _frames(2)
	_check(GameFlow.state == NullGameFlow.State.PAUSED and not InputGate.pressed(&"crouch"), "Android suspension pauses and clears toggles")
	InputGate._notification(NOTIFICATION_APPLICATION_RESUMED)
	_check(GameFlow.state == NullGameFlow.State.PAUSED, "Android resume never resumes gameplay automatically")
	GameFlow.resume_game()
	await _frames(5)
	GameFlow._notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	_check(GameFlow.state == NullGameFlow.State.PAUSED, "Android Back pauses")
	GameFlow.open_settings()
	GameFlow._notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	_check(GameFlow.state == NullGameFlow.State.PAUSED, "Android Back closes settings to pause")
	GameFlow.resume_game()
	await _frames(5)
	_press(6, overlay.stick_center)
	await _frames(1)
	var cancel := InputEventScreenTouch.new()
	cancel.index = 6
	cancel.canceled = true
	get_viewport().push_input(cancel, true)
	await _frames(2)
	_check(not overlay.fingers.has(6), "Canceled touch releases ownership")
	section.player.take_damage(100)
	await _frames(2)
	_check(overlay.fingers.is_empty() and not InputGate.accepts_input(), "Death invalidates touch")
	_check(GameFlow.continue_game().ok, "Checkpoint restarts after touch death")
	await _frames(10)
	_check(GameFlow.state == NullGameFlow.State.PLAYING and InputGate.movement_vector() == Vector2.ZERO, "Restored player has no stale movement")
	GameFlow.return_to_menu()
	section.queue_free()
	await _frames(3)
	print(JSON.stringify({"suite": "Android touch", "checks": checks, "failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _press(index: int, at: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = true
	get_viewport().push_input(event, true)

func _release(index: int) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	get_viewport().push_input(event, true)

func _drag(index: int, at: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = at
	event.relative = relative
	get_viewport().push_input(event, true)

func _frames(count: int) -> void:
	for i: int in count: await get_tree().physics_frame

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)
