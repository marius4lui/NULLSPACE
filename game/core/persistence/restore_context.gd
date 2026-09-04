class_name RestoreContext
extends RefCounted
## Coordinator-created value for ONE participant. Never distribute both anchors.
## Anchor geometry/clearance/visibility validation belongs to the campaign owner.

var participant_id: StringName:
	get: return _participant_id
var generation: int:
	get: return _generation
var simulation_epoch: int:
	get: return _epoch
var reset_seed: int:
	get: return _seed
var anchor_id: StringName:
	get: return _anchor_id
var anchor_transform: Transform3D:
	get: return _anchor

var _participant_id: StringName
var _generation: int
var _epoch: int
var _seed: int
var _anchor_id: StringName
var _anchor: Transform3D

func _init(id: StringName = &"", load_generation: int = -1, epoch: int = 0,
		seed: int = 0, own_anchor_id: StringName = &"", own_anchor: Transform3D = Transform3D.IDENTITY) -> void:
	_participant_id = id
	_generation = load_generation
	_epoch = epoch
	_seed = seed
	_anchor_id = own_anchor_id
	_anchor = own_anchor

func has_anchor() -> bool:
	return not _anchor_id.is_empty()

func validate() -> StorageResult:
	if not SnapshotSchema.stable_id(String(_participant_id)) or _generation < 1 or _epoch < 1:
		return StorageResult.failure(&"restore_context", "Invalid participant, load generation or simulation epoch.")
	if _seed < 0 or _seed > 2147483647:
		return StorageResult.failure(&"restore_context", "Invalid deterministic reset seed.")
	if not _anchor.is_finite() or (has_anchor() and not SnapshotSchema.stable_id(String(_anchor_id))):
		return StorageResult.failure(&"restore_context", "Invalid participant anchor value.")
	if not has_anchor() and _anchor != Transform3D.IDENTITY:
		return StorageResult.failure(&"restore_context", "An anchor-free participant must not receive a location.")
	return StorageResult.success({})
