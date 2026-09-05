class_name NullSaveSystem
extends Node

signal checkpoint_written(result: StorageResult)

var storage_directory: String = "user://saves"

func save_checkpoint(snapshot: Dictionary) -> StorageResult:
	var result: StorageResult = _store().write(snapshot)
	checkpoint_written.emit(result)
	return result

func load_checkpoint() -> StorageResult:
	return _store().read()

func continue_available() -> bool:
	var result: StorageResult = load_checkpoint()
	return result.ok and not result.payload["progress"]["ending"]

func _store() -> AtomicJsonStore:
	# Keep former development-campaign saves untouched; they describe removed content.
	return AtomicJsonStore.new(storage_directory.path_join("checkpoint-short.json"), "checkpoint", SnapshotSchema.VERSION, SnapshotSchema.validate, SnapshotSchema.normalize)
