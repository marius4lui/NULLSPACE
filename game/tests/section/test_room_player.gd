extends Node
## Short actual-physics regression for the integrated scene, not experiential play.

var failures: Array[String] = []
var checks: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var section := preload("res://section/section.tscn").instantiate() as NullspaceSection
	add_child(section)
	section.listener.enabled = false # Focused controller/collision checks, not an encounter playthrough.
	await _frames(3)
	_check(GameFlow.begin_new_game().ok, "New Game creates a valid save")
	await _frames(5)
	await get_tree().process_frame # Scene intentionally acknowledges outside the physics query phase.
	await _frames(8) # Includes gravity/contact ticks AFTER the idle-phase acknowledgement.
	_check(GameFlow.state == NullGameFlow.State.PLAYING, "Concrete scene acknowledges safe restore")
	_check(section.player.is_on_floor(), "Original carpet supports player")
	# Keep the established partition-control fixture in the retained office, not the new arrival.
	section.player.restore_at(Transform3D(Basis(Vector3.UP, .44), Vector3(2.7, .025, -.85)), SaveSystem.load_checkpoint().payload["player"])
	await _frames(5)
	Input.action_press("move_forward")
	await _frames(95)
	Input.action_release("move_forward")
	await _frames(8)
	_check(section.player.travelled > 4.0, "Input moves actual capsule")
	_check(section.player.position.z > -5.84, "Original partition blocks player")
	Input.action_press("crouch")
	await _frames(16)
	_check(section.player.crouched and section.player.collider.shape.height < 1.2, "Crouch changes physical capsule")
	Input.action_release("crouch")
	await _frames(16)
	_check(not section.player.crouched, "Standing restores when clear")
	Input.action_press("move_back")
	await _frames(8)
	GameFlow.pause_game()
	var paused_at: Vector3 = section.player.position
	await _frames(8)
	GameFlow.resume_game()
	await _frames(15)
	_check(section.player.position.distance_to(paused_at) < 0.001, "Held movement cannot leak through pause/resume")
	Input.action_release("move_back")
	await _frames(3)
	Input.action_press("move_back")
	await _frames(15)
	Input.action_release("move_back")
	_check(section.player.position.distance_to(paused_at) > 0.4, "Fresh press moves after pause")
	section.office_relay.use()
	await _frames(50)
	section.office_relay.use()
	_check(section.office_relay.powered and section.room.power["office"], "Physical office relay restores room lighting")
	_check(SaveSystem.load_checkpoint().payload["progress"]["relays"]["office"], "Actual relay checkpoint saved")
	section.player.take_damage(55)
	_check(section.player.health == 45.0, "First serious hit is survivable")
	section.player.take_damage(55)
	_check(GameFlow.state == NullGameFlow.State.DEAD, "Lethal damage enters death state")
	_check(GameFlow.continue_game().ok, "Death can request checkpoint")
	await _frames(6)
	_check(GameFlow.state == NullGameFlow.State.PLAYING and section.player.health == 100.0, "Checkpoint restores living player")
	_check(section.office_relay.powered and section.player.position.distance_to(NullspaceSection.OFFICE_SAFE.origin) < 0.1, "Checkpoint restores power and safe office anchor")
	print(JSON.stringify({"suite": "integrated room/player", "checks": checks, "failures": failures,
		"scope": "automated headless physics; not subjective play/audio"}))
	for item: Dictionary in Engine.get_copyright_info():
		if "font" in str(item.get("name", "")).to_lower() or "noto" in str(item).to_lower():
			print("BUNDLED_FONT_NOTICE ", JSON.stringify(item))
	section.request_quit(0 if failures.is_empty() else 1)

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
