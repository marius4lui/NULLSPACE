class_name NullGameFlow
extends Node

signal state_changed(previous: State, current: State, reason: StringName)
signal operation_failed(result: StorageResult)
signal load_started(snapshot: Dictionary, generation: int)

enum State { MENU, LOADING, PLAYING, PAUSED, DEAD, ENDING, SETTINGS }

var state: State = State.MENU
var pending_generation: int = -1
var _settings_return: State = State.MENU

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	CheckpointSystem.restore_requested.connect(_on_restore_requested)
	_transition(State.MENU, &"boot")

func begin_new_game(difficulty_id: String = DifficultyConfig.DEFAULT_ID) -> StorageResult:
	if state != State.MENU:
		return _invalid("New Game is only available from the title menu.")
	_transition(State.LOADING, &"new_game")
	var result: StorageResult = CheckpointSystem.begin_new_campaign(difficulty_id)
	return _finish_request(result, State.MENU)

func continue_game() -> StorageResult:
	if state != State.MENU and state != State.DEAD:
		return _invalid("Continue is only available from title or death.")
	var return_state: State = state
	_transition(State.LOADING, &"continue")
	var result: StorageResult = CheckpointSystem.restore_checkpoint()
	return _finish_request(result, return_state)

func complete_load(generation: int) -> bool:
	# LOADING is announced before synchronous storage work has issued a generation.
	# Only load_started supplies a real acknowledgement token; -1 is never readiness.
	if state != State.LOADING or generation < 1 or generation != pending_generation:
		return false
	pending_generation = -1
	# Focus can be lost during asynchronous world staging. Keep a ready world paused
	# until an explicit focused Resume; never run it while gameplay owns no input.
	_transition(State.PLAYING if InputGate.focused else State.PAUSED,
		&"load_ready" if InputGate.focused else &"load_ready_unfocused")
	return true

func fail_load(generation: int, detail: String) -> bool:
	if state != State.LOADING or generation < 1 or generation != pending_generation:
		return false
	pending_generation = -1
	_transition(State.MENU, &"load_failed")
	operation_failed.emit(StorageResult.failure(&"scene_load", detail))
	return true

func pause_game(reason: StringName = &"pause") -> bool:
	if state != State.PLAYING:
		return false
	_transition(State.PAUSED, reason)
	return true

func resume_game() -> bool:
	if state != State.PAUSED or not InputGate.focused:
		return false
	_transition(State.PLAYING, &"resume")
	return true

func open_settings() -> bool:
	if state != State.MENU and state != State.PAUSED:
		return false
	_settings_return = state
	_transition(State.SETTINGS, &"settings")
	return true

func close_settings() -> bool:
	if state != State.SETTINGS:
		return false
	_transition(_settings_return, &"settings_closed")
	return true

func die() -> bool:
	if state != State.PLAYING:
		return false
	_transition(State.DEAD, &"death")
	return true

func end_campaign() -> bool:
	if state != State.PLAYING:
		return false
	var current: Dictionary = CheckpointSystem.current_snapshot()
	if current.is_empty() or current["progress"]["ending"] != true:
		return false
	_transition(State.ENDING, &"campaign_complete")
	return true

func return_to_menu() -> void:
	pending_generation = -1
	_transition(State.MENU, &"menu")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause", false):
		if state == State.PLAYING:
			pause_game()
		elif state == State.PAUSED:
			resume_game()
		elif state == State.SETTINGS:
			close_settings()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if state == State.SETTINGS:
			close_settings()
		elif state == State.PLAYING:
			pause_game(&"android_back")

func _on_restore_requested(snapshot: Dictionary, generation: int) -> void:
	if state != State.LOADING:
		operation_failed.emit(_invalid("Restore must be initiated through GameFlow."))
		return
	pending_generation = generation
	if not SimulationClock._restore_for_load(float(snapshot["session"]["elapsed_seconds"]), generation):
		fail_load(generation, "Could not initialize the checkpoint simulation clock.")
		return
	load_started.emit(snapshot, generation)

func _finish_request(result: StorageResult, failure_state: State) -> StorageResult:
	if not result.ok:
		pending_generation = -1
		_transition(failure_state, &"storage_failed")
		operation_failed.emit(result)
	return result

func _transition(next: State, reason: StringName) -> void:
	var previous: State = state
	state = next
	if is_inside_tree():
		get_tree().paused = state != State.PLAYING
	InputGate.set_gameplay_enabled(state == State.PLAYING, reason)
	state_changed.emit(previous, state, reason)

func _invalid(detail: String) -> StorageResult:
	return StorageResult.failure(&"state", detail)
