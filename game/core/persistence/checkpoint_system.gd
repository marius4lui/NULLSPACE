class_name NullCheckpointSystem
extends Node
## Gameplay must capture all sections at one committed boundary before calling commit_snapshot.
## Restore listeners stage/apply state during LOADING, then the scene owner acknowledges GameFlow.

signal checkpoint_committed(snapshot: Dictionary)
signal restore_requested(snapshot: Dictionary, generation: int)

var runtime_generation: int = 0
var _current: Dictionary = {}

func commit_snapshot(snapshot: Dictionary) -> StorageResult:
	var result: StorageResult = SaveSystem.save_checkpoint(snapshot)
	if result.ok:
		_current = result.payload.duplicate(true)
		checkpoint_committed.emit(_current.duplicate(true))
	return result

func begin_new_campaign() -> StorageResult:
	var result: StorageResult = commit_snapshot(SnapshotSchema.initial_snapshot())
	if result.ok:
		_request_restore(result.payload)
	return result

func restore_checkpoint() -> StorageResult:
	var result: StorageResult = SaveSystem.load_checkpoint()
	if result.ok and result.payload["progress"]["ending"]:
		return StorageResult.failure(&"completed", "This campaign has ended. Start a new game from the title menu.")
	if result.ok:
		_request_restore(result.payload)
	return result

func current_snapshot() -> Dictionary:
	return _current.duplicate(true)

func _request_restore(snapshot: Dictionary) -> void:
	runtime_generation += 1
	_current = snapshot.duplicate(true)
	restore_requested.emit(_current.duplicate(true), runtime_generation)
