class_name RestoreBarrier
extends RefCounted
## Pure readiness accounting: no clock, SceneTree, GameFlow, anchors or world writes.
## The campaign coordinator owns timeout/cancel/teardown and the one flow acknowledgement.

signal completed(generation: int, result: StorageResult)

enum State { IDLE, PENDING, SUCCEEDED, FAILED, CANCELLED }

var state: State:
	get: return _state
var generation: int:
	get: return _generation

var _state: State = State.IDLE
var _generation: int = -1
var _expected: Dictionary = {}
var _pending: Dictionary = {}
var _result: StorageResult

func begin(load_generation: int, participant_ids: Array[StringName]) -> StorageResult:
	if _state == State.PENDING:
		return StorageResult.failure(&"restore_busy", "Cancel the active barrier before replacing it.")
	if load_generation < 1 or load_generation <= _generation:
		return StorageResult.failure(&"restore_stale", "Barrier generation must increase.")
	if participant_ids.is_empty():
		return StorageResult.failure(&"restore_registry", "A restore requires an explicit nonempty participant registry.")
	var expected: Dictionary = {}
	for id: StringName in participant_ids:
		if not SnapshotSchema.stable_id(String(id)) or expected.has(id):
			return StorageResult.failure(&"restore_registry", "Participant IDs must be stable and unique.")
		expected[id] = true
	_generation = load_generation
	_expected = expected
	_pending = expected.duplicate()
	_result = null
	_state = State.PENDING
	return StorageResult.success({})

func arrive(participant_id: StringName, load_generation: int, result: StorageResult) -> StorageResult:
	if load_generation != _generation:
		return StorageResult.failure(&"restore_stale", "Acknowledgement belongs to another load.")
	if _state != State.PENDING:
		return StorageResult.failure(&"restore_closed", "Barrier is not awaiting participants.")
	if not _expected.has(participant_id):
		return StorageResult.failure(&"restore_unknown", "Participant was not registered for this load.")
	if not _pending.has(participant_id):
		return StorageResult.failure(&"restore_duplicate", "Participant already acknowledged this load.")
	if result == null or not result.ok:
		var detail: String = "Missing participant result." if result == null else result.message
		_finish(State.FAILED, StorageResult.failure(&"restore_participant", "%s: %s" % [participant_id, detail]))
		return outcome()
	_pending.erase(participant_id)
	if _pending.is_empty():
		_finish(State.SUCCEEDED, StorageResult.success({}))
	return StorageResult.success({})

func cancel(load_generation: int, detail: String = "Coordinator cancelled or timed out restoration.") -> bool:
	if _state != State.PENDING or load_generation != _generation:
		return false
	_finish(State.CANCELLED, StorageResult.failure(&"restore_cancelled", detail))
	return true

func pending_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for id: StringName in _pending:
		result.append(id)
	return result

func outcome() -> StorageResult:
	if _result == null:
		return StorageResult.failure(&"restore_incomplete", "Restoration has not completed.")
	return StorageResult.success(_result.payload) if _result.ok else StorageResult.failure(_result.code, _result.message)

func _finish(next: State, result: StorageResult) -> void:
	_state = next
	_result = result
	completed.emit(_generation, outcome())
