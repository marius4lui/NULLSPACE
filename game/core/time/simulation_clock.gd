class_name NullSimulationClock
extends Node
## Gameplay's sole time authority. Consumers read sample(); only GameFlow restores.
## This clock runs before main-thread gameplay physics consumers (priority >= 0).

signal stepped(delta_seconds: float)

const PHYSICS_PRIORITY: int = -1000

var _elapsed_seconds: float = 0.0
var _physics_tick: int = 0
var _epoch: int = 0
var _restored_generation: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_physics_priority = PHYSICS_PRIORITY

func sample() -> SimulationStamp:
	return SimulationStamp.new(_elapsed_seconds, _physics_tick, _epoch)

func _physics_process(delta: float) -> void:
	if get_tree().paused or GameFlow.state != NullGameFlow.State.PLAYING:
		return
	_elapsed_seconds += delta
	_physics_tick += 1
	stepped.emit(delta)

func _restore_for_load(elapsed_seconds: float, generation: int) -> bool:
	# Internal GameFlow entry point; never a participant/Telemetry writer API.
	if GameFlow.state != NullGameFlow.State.LOADING or GameFlow.pending_generation != generation:
		return false
	if generation <= _restored_generation or not SnapshotSchema.number_in(elapsed_seconds, 0.0, 1e8):
		return false
	_elapsed_seconds = elapsed_seconds
	_physics_tick = 0
	_epoch += 1
	_restored_generation = generation
	return true
