extends Node
## Concrete ammo/control/save regression in the playable scene. Automated, not gun-feel QA.
var failures: Array[String] = []
var checks: int = 0
var heard_shots: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventHub.register_sound_propagator(func(sound: SoundEvent) -> void:
		if sound.kind == &"pistol_shot": heard_shots += 1)
	var section := preload("res://section/section.tscn").instantiate() as NullspaceSection
	add_child(section)
	await _frames(4)
	_check(GameFlow.begin_new_game().ok, "New unarmed game saves")
	await _frames(8)
	var gun: SectionPistol = section.pistol
	_check(not gun.owned and not gun.try_fire(), "No firing before pickup")
	section.pistol_pickup.use()
	_check(gun.owned and gun.chamber + gun.magazine == 8 and gun.reserve == 12, "Pickup grants exact single pistol allocation")
	section.pistol_pickup.use()
	_check(gun.chamber + gun.magazine + gun.reserve == 20, "Pickup cannot duplicate ammo")
	await _frames(35)
	_check(gun.try_fire(), "Ready pistol accepts shot")
	_check(not gun.try_fire() and gun.chamber + gun.magazine == 7, "Cycle rejects duplicate shot without extra debit")
	_check(heard_shots == 1, "One accepted shot creates one gameplay sound")
	await _frames(15)
	_check(gun.try_reload(), "Tactical reload begins")
	var total: int = gun.chamber + gun.magazine + gun.reserve
	await _frames(25)
	GameFlow.pause_game()
	var paused_timer: float = gun._timer
	await _frames(15)
	_check(is_equal_approx(gun._timer, paused_timer) and not gun.try_fire(), "Pause freezes reload and rejects shots")
	GameFlow.resume_game()
	await _frames(100)
	_check(gun.chamber == 1 and gun.magazine == 12 and gun.reserve == 6, "Tactical reload tops magazine and retains chamber")
	_check(gun.chamber + gun.magazine + gun.reserve == total, "Reload conserves rounds")
	# Empty the actual weapon through accepted single shots; stale held input is not used.
	for i: int in 13:
		gun.try_fire()
		await _frames(15)
	_check(gun.chamber == 0 and gun.magazine == 0, "Last round leaves empty slide state")
	_check(not gun.try_fire() and gun.reserve == 6, "Empty trigger cannot consume spare ammo")
	await _frames(15)
	_check(gun.try_reload(), "Empty reload begins with remaining reserve")
	await _frames(120)
	_check(gun.chamber == 1 and gun.magazine == 5 and gun.reserve == 0, "Empty reload chambers one of remaining six, not a free round")
	section.light_switch.use()
	var saved: Dictionary = SaveSystem.load_checkpoint().payload
	_check(saved["inventory"]["weapons"]["pistol"] == gun.snapshot(), "Physical switch checkpoint stores committed ammo")
	_check("arrival_pistol" in saved["world"]["consumed_pickups"], "Consumed pickup persists")
	gun.try_fire()
	section.player.take_damage(100)
	GameFlow.continue_game()
	await _frames(8)
	_check(gun.snapshot() == saved["inventory"]["weapons"]["pistol"] and section.pistol_pickup.consumed,
		"Death restores committed weapon and consumed pickup")
	_check(gun.state == SectionPistol.State.READY and gun._pending_fire == -1, "No in-flight shot/reload leaks across restore")
	_check(GameFlow.state == NullGameFlow.State.PLAYING, "Actual scene resumes after weapon restore")
	print(JSON.stringify({"suite": "integrated pistol", "checks": checks, "failures": failures,
		"scope": "automated headless actual scene; no subjective or audio-listening claim"}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures.append(description)
