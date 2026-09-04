extends Node
## Headless fixed-render-schedule test, NOT native 30/60/120 FPS performance evidence.

var _ready_to_measure: bool = false
var _initial_frame: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_begin.call_deferred()

func _begin() -> void:
	InputGate.focused = true
	GameFlow.return_to_menu()
	var request: StorageResult = GameFlow.begin_new_game()
	if not request.ok or not GameFlow.complete_load(GameFlow.pending_generation):
		push_error("Rate probe cannot begin synthetic clock scenario")
		get_tree().quit(1)
		return
	_initial_frame = Engine.get_process_frames()
	_ready_to_measure = true

func _physics_process(_delta: float) -> void:
	if not _ready_to_measure:
		return
	var stamp: SimulationStamp = SimulationClock.sample()
	if stamp.physics_tick < 60:
		return
	var passed: bool = stamp.physics_tick == 60 and is_equal_approx(stamp.elapsed_seconds, 1.0)
	GameFlow.pause_game()
	_ready_to_measure = false
	print(JSON.stringify({"suite": "shared-clock render-schedule probe", "passed": passed,
		"physics_tick": stamp.physics_tick, "elapsed_seconds": stamp.elapsed_seconds,
		"render_frames": Engine.get_process_frames() - _initial_frame,
		"scope": "headless logical scheduling only; no native frame-rate claim"}))
	if not passed:
		push_error("Simulation elapsed time changed with render scheduling")
	get_tree().quit(0 if passed else 1)
