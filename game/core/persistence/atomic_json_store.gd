class_name AtomicJsonStore
extends RefCounted
## Same-directory replacement. Never delete a valid destination before replacement.
## SHA-256 detects corruption, not intentional save editing. No object deserialization.

const FORMAT_VERSION: int = 1
const MAX_FILE_BYTES: int = 2 * 1024 * 1024
const BUILD_ID: String = "0.2.0-m2"

var path: String
var kind: String
var content_version: int
var validator: Callable
var normalizer: Callable

func _init(file_path: String, document_kind: String, version: int, validate: Callable, normalize: Callable = Callable()) -> void:
	path = file_path
	kind = document_kind
	content_version = version
	validator = validate
	normalizer = normalize

func read() -> StorageResult:
	var primary: StorageResult = _read_file(path)
	if primary.ok:
		return primary
	# Never reinterpret a future schema as an old backup: upgrading must be explicit.
	if primary.code == &"incompatible":
		return primary
	var backup: StorageResult = _read_file(path + ".backup")
	if backup.ok:
		return StorageResult.success(backup.payload, true)
	if primary.code == &"missing" and backup.code == &"missing":
		return StorageResult.failure(&"missing", "No saved checkpoint is available.")
	return StorageResult.failure(primary.code if primary.code != &"missing" else backup.code,
		"Saved data could not be read. " + primary.message + " Previous copy: " + backup.message)

func write(payload: Dictionary) -> StorageResult:
	var problems: PackedStringArray = validator.call(payload)
	if not problems.is_empty():
		return StorageResult.failure(&"invalid", "; ".join(problems))
	var current: StorageResult = _read_file(path)
	if current.code == &"incompatible":
		return current
	var previous: StorageResult = _read_file(path + ".backup")
	if previous.code == &"incompatible":
		return previous
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if directory_error != OK:
		return StorageResult.failure(&"io", "Cannot create save directory (%s)." % directory_error)
	var encoded: String = _encode(payload)
	if encoded.to_utf8_buffer().size() > MAX_FILE_BYTES:
		return StorageResult.failure(&"oversize", "Saved data exceeds the supported size.")
	var staged: StorageResult = _write_verified(path + ".tmp", encoded)
	if not staged.ok:
		return staged
	# Preserve only validated data. A corrupt primary must never poison a good backup.
	if current.ok:
		var preserved: StorageResult = _write_verified(path + ".backup.tmp", _encode(current.payload))
		if not preserved.ok:
			return preserved
		if DirAccess.rename_absolute(path + ".backup.tmp", path + ".backup") != OK:
			return StorageResult.failure(&"io", "Cannot preserve the previous checkpoint.")
	var replace_error: Error = DirAccess.rename_absolute(path + ".tmp", path)
	if replace_error != OK:
		return StorageResult.failure(&"io", "Cannot replace checkpoint (%s). Previous data retained." % replace_error)
	return StorageResult.success(normalizer.call(payload) if normalizer.is_valid() else payload)

func _encode(payload: Dictionary) -> String:
	var payload_json: String = JSON.stringify(payload, "", true, true)
	return JSON.stringify({"format_version": FORMAT_VERSION, "kind": kind,
		"content_version": content_version, "build_id": BUILD_ID,
		"saved_utc": Time.get_datetime_string_from_system(true),
		"payload_json": payload_json, "sha256": payload_json.sha256_text()}, "\t", true, true)

func _write_verified(target: String, contents: String) -> StorageResult:
	var file: FileAccess = FileAccess.open(target, FileAccess.WRITE)
	if file == null:
		return StorageResult.failure(&"io", "Cannot write staged data (%s)." % FileAccess.get_open_error())
	file.store_string(contents)
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		return StorageResult.failure(&"io", "Staged write failed (%s)." % write_error)
	return _read_file(target)

func _read_file(target: String) -> StorageResult:
	if not FileAccess.file_exists(target):
		return StorageResult.failure(&"missing", "File is missing.")
	var file: FileAccess = FileAccess.open(target, FileAccess.READ)
	if file == null:
		return StorageResult.failure(&"io", "File is unreadable.")
	if file.get_length() > MAX_FILE_BYTES:
		file.close()
		return StorageResult.failure(&"oversize", "File is too large.")
	var text: String = file.get_as_text()
	file.close()
	var parser: JSON = JSON.new()
	if parser.parse(text) != OK or not parser.data is Dictionary:
		return StorageResult.failure(&"corrupt", "File contains incomplete or invalid JSON.")
	var envelope: Dictionary = parser.data
	if not SnapshotSchema.integer_in(envelope.get("format_version"), 0, 100000) or not SnapshotSchema.integer_in(envelope.get("content_version"), 0, 100000):
		return StorageResult.failure(&"corrupt", "Saved data has no valid version metadata.")
	if envelope.get("format_version") != FORMAT_VERSION or envelope.get("content_version") != content_version:
		return StorageResult.failure(&"incompatible", "Saved data uses an unsupported version.")
	if not envelope.get("kind") is String or envelope["kind"] != kind or not envelope.get("build_id") is String:
		return StorageResult.failure(&"corrupt", "Saved data has the wrong document type.")
	if not envelope.get("payload_json") is String or not envelope.get("sha256") is String:
		return StorageResult.failure(&"corrupt", "Saved data is incomplete.")
	var payload_json: String = envelope["payload_json"]
	if payload_json.sha256_text() != envelope["sha256"]:
		return StorageResult.failure(&"corrupt", "Saved data failed its integrity check.")
	if parser.parse(payload_json) != OK or not parser.data is Dictionary:
		return StorageResult.failure(&"corrupt", "Checkpoint content is not a valid object.")
	var payload: Dictionary = parser.data
	var problems: PackedStringArray = validator.call(payload)
	if not problems.is_empty():
		return StorageResult.failure(&"invalid", "; ".join(problems))
	return StorageResult.success(normalizer.call(payload) if normalizer.is_valid() else payload)
