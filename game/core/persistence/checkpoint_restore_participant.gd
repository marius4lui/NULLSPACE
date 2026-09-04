class_name CheckpointRestoreParticipant
extends RefCounted
## Extend as a small adapter around a player/world/Listener node, not as its base node.
## A start receipt is NOT readiness. The coordinator waits for restore_finished.

signal restore_finished(participant_id: StringName, generation: int, result: StorageResult)

var participant_id: StringName:
	get: return _participant_id

var _participant_id: StringName
var _active_generation: int = -1
var _last_generation: int = -1

func _init(id: StringName = &"") -> void:
	_participant_id = id

func begin_restore(snapshot: Dictionary, context: RestoreContext) -> StorageResult:
	if _active_generation >= 0:
		return StorageResult.failure(&"restore_busy", "Cancel the active participant restore before starting another.")
	if context == null or context.participant_id != _participant_id:
		return StorageResult.failure(&"restore_context", "Restore context belongs to another participant.")
	var validation: StorageResult = context.validate()
	if not validation.ok:
		return validation
	if context.generation <= _last_generation:
		return StorageResult.failure(&"restore_stale", "Participant restore generation was already used.")
	_active_generation = context.generation
	_last_generation = context.generation
	_begin_restore(snapshot.duplicate(true), context)
	return StorageResult.success({})

func cancel_restore(generation: int) -> bool:
	if not is_restore_active(generation):
		return false
	_active_generation = -1
	_cancel_restore(generation)
	return true

func is_restore_active(generation: int) -> bool:
	# Adapters must check before deferred world mutations, not only at completion.
	return _active_generation >= 0 and generation == _active_generation

func _begin_restore(_snapshot: Dictionary, context: RestoreContext) -> void:
	# An unimplemented adapter fails closed instead of silently acknowledging.
	_finish_restore(context.generation, StorageResult.failure(&"restore_unimplemented", "Participant has no restore implementation."))

func _cancel_restore(_generation: int) -> void:
	pass

func _finish_restore(generation: int, result: StorageResult) -> bool:
	if not is_restore_active(generation):
		return false
	_active_generation = -1
	var isolated: StorageResult = StorageResult.failure(&"restore_result", "Participant returned no result.")
	if result != null:
		isolated = StorageResult.success(result.payload, result.recovered) if result.ok else StorageResult.failure(result.code, result.message)
	restore_finished.emit(_participant_id, generation, isolated)
	return true
