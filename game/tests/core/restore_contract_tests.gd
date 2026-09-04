class_name CoreRestoreContractTests
extends RefCounted
## Pure contract fakes, never a campaign coordinator or real player/AI implementation.

class ManualParticipant extends CheckpointRestoreParticipant:
	var received: Dictionary = {}
	var context: RestoreContext
	var cancels: int = 0

	func _begin_restore(snapshot: Dictionary, restore_context: RestoreContext) -> void:
		received = snapshot
		context = restore_context

	func _cancel_restore(_generation: int) -> void:
		cancels += 1

var _completed: Array[Dictionary] = []
var _participant_results: Array[Dictionary] = []

func run(check: Callable) -> void:
	var flow_before: NullGameFlow.State = GameFlow.state
	var input_before: int = InputGate.generation
	var barrier: RestoreBarrier = RestoreBarrier.new()
	barrier.completed.connect(_on_completed)
	check.call(barrier.state == RestoreBarrier.State.IDLE and not barrier.outcome().ok, "Idle barrier has no successful outcome")
	check.call(not barrier.begin(1, []).ok, "Empty participant registry cannot complete vacuously")
	check.call(not barrier.begin(1, [&"player", &"player"]).ok, "Duplicate participant registry rejected")
	check.call(not barrier.begin(1, [&"bad/id"]).ok and not barrier.begin(0, [&"player"]).ok, "Invalid participant identity and zero generation rejected")
	check.call(barrier.begin(1, [&"player", &"world", &"listener"]).ok, "Explicit participant registry begins")
	var pending: Array[StringName] = barrier.pending_ids()
	pending.clear()
	check.call(barrier.pending_ids().size() == 3, "Pending participant registry returned as detached value")
	check.call(not barrier.begin(2, [&"player"]).ok and barrier.generation == 1, "Active barrier cannot be replaced without cancellation")
	check.call(barrier.arrive(&"unknown", 1, StorageResult.success({})).code == &"restore_unknown", "Unregistered acknowledgement rejected")
	check.call(barrier.arrive(&"player", 0, StorageResult.success({})).code == &"restore_stale"
		and barrier.arrive(&"player", 2, StorageResult.success({})).code == &"restore_stale", "Older and future acknowledgement generations rejected")
	check.call(barrier.arrive(&"player", 1, StorageResult.success({})).ok and barrier.state == RestoreBarrier.State.PENDING,
		"One ready participant cannot release multiple-participant barrier")
	check.call(barrier.arrive(&"player", 1, StorageResult.success({})).code == &"restore_duplicate", "Duplicate acknowledgement cannot replace missing participant")
	barrier.arrive(&"world", 1, StorageResult.success({}))
	check.call(not barrier.outcome().ok and _completed.is_empty() and barrier.pending_ids() == [&"listener"],
		"Missing or delayed Listener leaves barrier pending without success signal")
	check.call(barrier.arrive(&"listener", 1, StorageResult.success({})).ok and barrier.outcome().ok and _completed.size() == 1,
		"Final unique participant emits one success")
	check.call(not barrier.arrive(&"listener", 1, StorageResult.success({})).ok and not barrier.cancel(1), "Terminal barrier ignores late callbacks and cancel")
	var detached: StorageResult = barrier.outcome()
	detached.ok = false
	check.call(barrier.outcome().ok and not barrier.begin(1, [&"player"]).ok, "Outcome copy and strictly newer barrier generations preserve ownership")
	barrier.begin(2, [&"player", &"listener"])
	check.call(not barrier.arrive(&"player", 2, StorageResult.failure(&"anchor", "Unsafe synthetic anchor")).ok
		and barrier.state == RestoreBarrier.State.FAILED, "Participant failure terminates the barrier")
	check.call(not barrier.arrive(&"listener", 2, StorageResult.success({})).ok and not barrier.outcome().ok, "Later success cannot revive failed barrier")
	barrier.begin(3, [&"player"])
	check.call(not barrier.arrive(&"player", 3, null).ok and barrier.state == RestoreBarrier.State.FAILED, "Missing participant result fails closed")
	barrier.begin(4, [&"player", &"listener"])
	check.call(not barrier.cancel(3) and barrier.state == RestoreBarrier.State.PENDING, "Stale cancellation cannot cancel current barrier")
	check.call(barrier.cancel(4, "Synthetic coordinator timeout") and barrier.state == RestoreBarrier.State.CANCELLED, "Coordinator timeout/cancel closes pending barrier")
	check.call(not barrier.cancel(4) and not barrier.arrive(&"player", 4, StorageResult.success({})).ok, "Cancelled generation ignores duplicate cancellation and late ready")
	barrier.begin(5, [&"player"])
	check.call(not barrier.arrive(&"player", 4, StorageResult.success({})).ok and barrier.pending_ids() == [&"player"], "Old callback cannot acknowledge replacement barrier")
	barrier.arrive(&"player", 5, StorageResult.success({}))
	check.call(_completed.size() == 5, "Each accepted barrier completes at most once across success failure and cancel")
	check.call(GameFlow.state == flow_before and InputGate.generation == input_before, "Pure restore barrier never changes GameFlow or input")
	_test_participants(check)

func _test_participants(check: Callable) -> void:
	var own_anchor: Transform3D = Transform3D(Basis.IDENTITY, Vector3(12.0, 0.0, 4.0))
	var player_context: RestoreContext = RestoreContext.new(&"player", 1, 7, 42, &"player_safe", own_anchor)
	var world_context: RestoreContext = RestoreContext.new(&"world", 1, 7, 42)
	check.call(player_context.validate().ok and player_context.has_anchor() and player_context.anchor_transform == own_anchor,
		"Player restore receives its own named anchor and value transform")
	check.call(world_context.validate().ok and not world_context.has_anchor() and world_context.anchor_transform == Transform3D.IDENTITY,
		"Anchor-free world participant receives no player or Listener position")
	check.call(not RestoreContext.new(&"world", 1, 7, 42, &"", own_anchor).validate().ok, "Unlabelled location cannot hide in anchor-free context")
	check.call(not RestoreContext.new(&"player", 0, 7, 42).validate().ok and not RestoreContext.new(&"player", 1, 0, 42).validate().ok,
		"Context requires valid generation and simulation epoch")
	check.call(not RestoreContext.new(&"player", 1, 7, -1).validate().ok, "Context rejects invalid reset seed")
	var player: ManualParticipant = ManualParticipant.new(&"player")
	player.restore_finished.connect(_on_participant_result)
	var snapshot: Dictionary = SnapshotSchema.initial_snapshot()
	check.call(not player.begin_restore(snapshot, world_context).ok and not player.begin_restore(snapshot, null).ok,
		"Participant rejects another owner's or null restore context")
	check.call(player.begin_restore(snapshot, player_context).ok and _participant_results.is_empty(), "Start receipt is not readiness for asynchronous participant")
	check.call(player.is_restore_active(1) and not player.is_restore_active(2), "Adapter can guard deferred mutations by active generation")
	player.received["player"]["health"] = 15.0
	check.call(snapshot["player"]["health"] == SnapshotSchema.TUNING.max_health, "Participant receives detached semantic snapshot")
	check.call(not player.begin_restore(snapshot, player_context).ok, "Participant cannot replace active restore")
	check.call(not player.cancel_restore(2) and not player._finish_restore(2, StorageResult.success({})), "Wrong-generation cancel and readiness rejected by participant")
	check.call(player._finish_restore(1, StorageResult.success({})) and _participant_results.size() == 1, "Matching participant readiness emitted once")
	check.call(not player._finish_restore(1, StorageResult.success({})) and not player.begin_restore(snapshot, player_context).ok,
		"Completed participant generation cannot restart or acknowledge twice")
	check.call(player.begin_restore(snapshot, RestoreContext.new(&"player", 2, 8, 42, &"player_safe", own_anchor)).ok,
		"Participant can start a newer load")
	check.call(player.cancel_restore(2) and player.cancels == 1 and not player._finish_restore(2, StorageResult.success({})),
		"Cancelled participant invokes teardown and rejects its stale callback")
	check.call(not player.is_restore_active(2), "Cancelled adapter cannot pass its deferred-mutation guard")
	player.begin_restore(snapshot, RestoreContext.new(&"player", 3, 9, 42, &"player_safe", own_anchor))
	check.call(not player._finish_restore(2, StorageResult.success({})) and player._finish_restore(3, null), "Old callback cannot finish new participant; null result fails current one")
	check.call(not _participant_results[-1]["ok"], "Null participant result delivered as structured failure")
	var missing: CheckpointRestoreParticipant = CheckpointRestoreParticipant.new(&"unimplemented")
	missing.restore_finished.connect(_on_participant_result)
	missing.begin_restore(snapshot, RestoreContext.new(&"unimplemented", 4, 10, 42))
	check.call(not _participant_results[-1]["ok"] and _participant_results[-1]["code"] == &"restore_unimplemented",
		"Unimplemented adapter fails rather than automatically declaring ready")

func _on_completed(generation: int, result: StorageResult) -> void:
	_completed.append({"generation": generation, "ok": result.ok})

func _on_participant_result(id: StringName, generation: int, result: StorageResult) -> void:
	_participant_results.append({"id": id, "generation": generation, "ok": result.ok, "code": result.code})
