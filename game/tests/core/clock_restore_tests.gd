class_name CoreClockRestoreTests
extends RefCounted
## Actual autoload/physics scheduling, with synthetic logical input only.

var _owner: Node
var _check: Callable
var _load_stamps: Array[SimulationStamp] = []
var _load_generations: Array[int] = []

func run(owner: Node, check: Callable, directory: String) -> void:
	_owner = owner
	_check = check
	SaveSystem.storage_directory = directory.path_join("clock")
	InputGate.focused = true
	GameFlow.return_to_menu()
	GameFlow.load_started.connect(_observe_load)
	_test_early_load_callbacks(directory)
	await _assert_frozen("MENU")
	GameFlow.open_settings()
	await _assert_frozen("title SETTINGS")
	GameFlow.close_settings()
	var before: SimulationStamp = SimulationClock.sample()
	_check.call(GameFlow.begin_new_game().ok, "Clock scenario begins a new checkpoint")
	var initial: SimulationStamp = SimulationClock.sample()
	_check.call(initial.epoch == before.epoch + 1 and initial.physics_tick == 0 and initial.elapsed_seconds == 0.0,
		"New load resets elapsed/tick and monotonically advances epoch")
	_check.call(_load_stamps[-1].epoch == initial.epoch and _load_generations[-1] == GameFlow.pending_generation,
		"Clock is restored before load_started reaches participants")
	_check.call(not SimulationClock._restore_for_load(5.0, GameFlow.pending_generation), "Duplicate clock reset in one load is rejected")
	await _assert_frozen("LOADING")
	InputGate.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	GameFlow.complete_load(GameFlow.pending_generation)
	await _assert_frozen("unfocused completed load PAUSED")
	InputGate.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await _assert_frozen("focus returned but not resumed")
	_check.call(GameFlow.resume_game(), "Clock resumes only with explicit focused gameplay")
	before = SimulationClock.sample()
	var play_metric: float = Telemetry.metrics["play_seconds"]
	await _frames()
	var running: SimulationStamp = SimulationClock.sample()
	var elapsed: float = running.elapsed_seconds - before.elapsed_seconds
	_check.call(running.physics_tick > before.physics_tick and is_equal_approx(elapsed,
		float(running.physics_tick - before.physics_tick) / Engine.physics_ticks_per_second), "Clock advances once per logical physics step")
	_check.call(is_equal_approx(float(Telemetry.metrics["play_seconds"]) - play_metric, elapsed), "Telemetry follows clock steps without a second simulation counter")
	_check.call(initial.physics_tick == 0 and initial.elapsed_seconds == 0.0, "Previously sampled clock stamp remains detached")
	before = SimulationClock.sample()
	Telemetry.reset_metrics()
	Telemetry._process(0.001)
	_check.call(_same(before, SimulationClock.sample()), "Telemetry reset/render sampling cannot advance or reset gameplay time")
	_check.call(not SimulationClock._restore_for_load(900.0, GameFlow.pending_generation), "Clock cannot be restored during PLAYING")
	GameFlow.pause_game()
	await _assert_frozen("PAUSED")
	GameFlow.open_settings()
	await _assert_frozen("pause SETTINGS")
	GameFlow.close_settings()
	GameFlow.resume_game()
	var committed: Dictionary = CheckpointSystem.current_snapshot()
	committed["session"]["elapsed_seconds"] = 17.25
	committed["inventory"]["weapons"]["pistol"] = {"owned": true, "chamber": 1, "magazine": 4, "reserve": 2}
	_check.call(CheckpointSystem.commit_snapshot(committed).ok, "Clock scenario stores coherent committed time and ammo")
	# Simulated transient state changes must not leak back into committed storage.
	committed["inventory"]["weapons"]["pistol"] = {"owned": true, "chamber": 0, "magazine": 0, "reserve": 999}
	var old_sound: SoundEvent = SoundEvent.new()
	old_sound.simulation_epoch = SimulationClock.sample().epoch
	old_sound.simulation_seconds = SimulationClock.sample().elapsed_seconds
	var old_observation: PerceptionObservation = PerceptionObservation.new()
	old_observation.simulation_epoch = old_sound.simulation_epoch
	old_observation.observed_at_seconds = old_sound.simulation_seconds
	_check.call(old_sound.is_current_epoch(SimulationClock.sample()) and old_observation.is_current_epoch(SimulationClock.sample()),
		"Current-epoch event and observation are identifiable")
	GameFlow.die()
	await _assert_frozen("DEAD")
	Input.action_press(&"fire")
	Input.action_press(&"move_forward")
	var previous_action: int = InputGate.generation
	_check.call(GameFlow.continue_game().ok, "Death reload starts clock restoration")
	var restored: SimulationStamp = SimulationClock.sample()
	_check.call(restored.elapsed_seconds == 17.25 and restored.physics_tick == 0 and restored.epoch > old_sound.simulation_epoch,
		"Checkpoint reload restores committed time with a new runtime-only epoch")
	_check.call(not old_sound.is_current_epoch(restored) and not old_observation.is_current_epoch(restored), "Prior-epoch sounds and observations are rejected after load")
	_check.call(not SoundEvent.new().is_current_epoch(restored) and not PerceptionObservation.new().is_current_epoch(null),
		"Unstamped or missing-clock evidence fails closed")
	var mouse: InputEventMouseMotion = InputEventMouseMotion.new()
	mouse.screen_relative = Vector2(80.0, 20.0)
	_check.call(InputGate.look_delta(mouse) == Vector2.ZERO and not InputGate.accepts_generation(previous_action),
		"Loading rejects mouse displacement and old action generation")
	GameFlow.complete_load(GameFlow.pending_generation)
	await _frames()
	_check.call(not InputGate.pressed(&"fire") and InputGate.movement_vector() == Vector2.ZERO,
		"Held fire and movement cannot leak through checkpoint completion")
	_check.call(CheckpointSystem.current_snapshot()["inventory"]["weapons"]["pistol"] == {"owned": true, "chamber": 1, "magazine": 4, "reserve": 2},
		"Only committed chamber magazine and reserve survive reload")
	Input.action_release(&"fire")
	Input.action_release(&"move_forward")
	await _frames()
	GameFlow.return_to_menu()
	GameFlow.continue_game()
	var failed_epoch: int = SimulationClock.sample().epoch
	_check.call(GameFlow.fail_load(GameFlow.pending_generation, "Synthetic participant failure"), "Failed load closes flow without unpausing")
	await _assert_frozen("failed load MENU")
	_check.call(SimulationClock.sample().epoch == failed_epoch, "Failed staging does not restore an old evidence epoch")
	GameFlow.continue_game()
	_check.call(SimulationClock.sample().epoch > failed_epoch, "Retry after failed staging has another fresh epoch")
	GameFlow.complete_load(GameFlow.pending_generation)
	var final_snapshot: Dictionary = CheckpointSystem.current_snapshot()
	for relay: String in SnapshotSchema.RELAYS:
		final_snapshot["progress"]["relays"][relay] = true
	final_snapshot["progress"]["ending"] = true
	_check.call(CheckpointSystem.commit_snapshot(final_snapshot).ok and GameFlow.end_campaign(), "Clock scenario enters a committed ending")
	await _assert_frozen("ENDING")
	_check.call(SnapshotSchema.VERSION == 2 and not final_snapshot.has("simulation_epoch"), "Runtime epoch does not leak into short-game save schema")
	GameFlow.return_to_menu()
	GameFlow.load_started.disconnect(_observe_load)

func _test_early_load_callbacks(directory: String) -> void:
	for request_kind: String in ["new", "continue"]:
		for callback_kind: String in ["complete", "fail"]:
			var label: String = "%s/%s" % [request_kind, callback_kind]
			SaveSystem.storage_directory = directory.path_join("early_load_" + request_kind + "_" + callback_kind)
			_check.call(CheckpointSystem.commit_snapshot(SnapshotSchema.initial_snapshot()).ok,
				"Early callback isolated checkpoint prepared: " + label)
			GameFlow.return_to_menu()
			var before: SimulationStamp = SimulationClock.sample()
			var load_count: int = _load_stamps.size()
			var receipts: Array[bool] = []
			var observed_pending: Array[int] = []
			var callback: Callable = func(_previous: NullGameFlow.State, current: NullGameFlow.State, _reason: StringName) -> void:
				if current != NullGameFlow.State.LOADING:
					return
				observed_pending.append(GameFlow.pending_generation)
				for generation: int in [-1, 0, -33, CheckpointSystem.runtime_generation + 1]:
					receipts.append(GameFlow.complete_load(generation) if callback_kind == "complete"
						else GameFlow.fail_load(generation, "Premature synthetic failure"))
			GameFlow.state_changed.connect(callback)
			var requested: StorageResult = GameFlow.begin_new_game() if request_kind == "new" else GameFlow.continue_game()
			GameFlow.state_changed.disconnect(callback)
			_check.call(observed_pending == [-1] and receipts == [false, false, false, false],
				"Early LOADING callbacks reject sentinel zero negative and unissued generation: " + label)
			_check.call(requested.ok and GameFlow.state == NullGameFlow.State.LOADING and _owner.get_tree().paused
				and not InputGate.gameplay_enabled and GameFlow.pending_generation > 0,
				"Premature callback cannot bypass or fail a valid paused load: " + label)
			_check.call(_load_stamps.size() == load_count + 1 and SimulationClock.sample().epoch == before.epoch + 1,
				"Rejected early callback preserves the one staged epoch and load notification: " + label)
			var generation: int = GameFlow.pending_generation
			var acknowledged: bool = GameFlow.complete_load(generation) if callback_kind == "complete" else GameFlow.fail_load(generation, "Expected staged failure")
			_check.call(acknowledged and not GameFlow.complete_load(generation) and not GameFlow.fail_load(generation, "Duplicate"),
				"Issued positive generation can be resolved exactly once: " + label)
	GameFlow.return_to_menu()
	SaveSystem.storage_directory = directory.path_join("clock")

func _observe_load(_snapshot: Dictionary, generation: int) -> void:
	_load_stamps.append(SimulationClock.sample())
	_load_generations.append(generation)

func _assert_frozen(label: String) -> void:
	var before: SimulationStamp = SimulationClock.sample()
	await _frames()
	_check.call(_same(before, SimulationClock.sample()) and _owner.get_tree().paused, "Simulation clock frozen in " + label)

func _frames() -> void:
	for index: int in 3:
		await _owner.get_tree().physics_frame
	await _owner.get_tree().process_frame

func _same(left: SimulationStamp, right: SimulationStamp) -> bool:
	return left.elapsed_seconds == right.elapsed_seconds and left.physics_tick == right.physics_tick and left.epoch == right.epoch
