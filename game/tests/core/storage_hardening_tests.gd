class_name CoreStorageHardeningTests
extends RefCounted
## Regressions for the independent 68ce558 storage audit; no native/gameplay claim.

func run(check: Callable, directory: String) -> void:
	_test_difficulty_flags(check, directory)
	var malformed: Array = [null, [], {}, true, false, "", "wrong", -1, 0, 0.5, 1e99, INF, NAN]
	for value: Variant in malformed:
		var changed: Dictionary = SettingsSchema.defaults()
		changed["quality"] = value
		check.call(not SettingsSchema.validate(changed).is_empty(), "Malformed quality rejected cleanly: " + str(value))
	var manager_before: Dictionary = SettingsManager.snapshot()
	var resolution: Array = SettingsManager.get_value("resolution")
	resolution[0] = -1
	check.call(SettingsManager.snapshot() == manager_before, "Mutating get_value resolution does not mutate active preferences")
	check.call(SettingsSchema.validate(SettingsManager.snapshot()).is_empty(), "Getter mutation preserves valid settings schema")
	var versions: Array = [999, 100000, 100001, 2147483647, 9223372036854775807, 1e30, 1e300]
	var index: int = 0
	for field: String in ["format_version", "content_version"]:
		for version: Variant in versions:
			index += 1
			var path: String = directory.path_join("future_primary_%s.json" % index)
			var store: AtomicJsonStore = AtomicJsonStore.new(path, "checkpoint", 1, SnapshotSchema.validate, SnapshotSchema.normalize)
			var initial: Dictionary = SnapshotSchema.initial_snapshot()
			check.call(store.write(initial).ok and store.write(initial).ok, "Future-version fixture has valid primary and backup %s" % index)
			var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
			envelope[field] = version
			_write(path, JSON.stringify(envelope, "", true, true))
			var primary_hash: String = FileAccess.get_sha256(path)
			var backup_hash: String = FileAccess.get_sha256(path + ".backup")
			var read_result: StorageResult = store.read()
			var write_result: StorageResult = store.write(initial)
			check.call(not read_result.ok and read_result.code == &"incompatible" and not read_result.recovered,
				"Future %s %s never falls back to old backup" % [field, version])
			check.call(not write_result.ok and write_result.code == &"incompatible" and FileAccess.get_sha256(path) == primary_hash
				and FileAccess.get_sha256(path + ".backup") == backup_hash, "Future %s %s primary and backup bytes retained" % [field, version])
			# A newer backup is also protected when the primary is valid and current.
			_write(path + ".backup", FileAccess.get_file_as_string(path))
			_write(path, store._encode(initial))
			primary_hash = FileAccess.get_sha256(path)
			backup_hash = FileAccess.get_sha256(path + ".backup")
			check.call(not store.write(initial).ok and FileAccess.get_sha256(path) == primary_hash
				and FileAccess.get_sha256(path + ".backup") == backup_hash, "Future backup is not replaced %s" % index)

func _test_difficulty_flags(check: Callable, directory: String) -> void:
	# Ending validation must not interpret unvalidated world values. run.sh also
	# rejects script errors, even when the validator eventually returns an error.
	var malformed: Array = [null, {}, [], [true], "true", 0, 1, 0.5]
	for difficulty: String in DifficultyConfig.IDS:
		var valid: Dictionary = SnapshotSchema.initial_snapshot()
		DifficultyConfig.write_to_snapshot(valid, difficulty)
		valid["progress"]["ending"] = true
		valid["progress"]["relays"] = {"office": true, "service": true}
		valid["world"]["circuits"]["emergency_powered"] = true
		check.call(SnapshotSchema.validate(valid).is_empty(), "Valid %s ending still accepted" % difficulty)
		for flag: String in ["difficulty_" + difficulty, "emergency_powered"]:
			for value: Variant in malformed:
				var changed: Dictionary = valid.duplicate(true)
				changed["world"]["circuits"][flag] = value
				check.call(not SnapshotSchema.validate(changed).is_empty(),
					"Malformed %s flag rejected cleanly: %s" % [flag, value])
	var path: String = directory.path_join("invalid_difficulty.json")
	var store: AtomicJsonStore = AtomicJsonStore.new(path, "checkpoint", SnapshotSchema.VERSION, SnapshotSchema.validate, SnapshotSchema.normalize)
	var previous: Dictionary = SnapshotSchema.initial_snapshot()
	check.call(store.write(previous).ok and store.write(previous).ok, "Difficulty fixture has valid primary and backup")
	var invalid: Dictionary = previous.duplicate(true)
	invalid["progress"]["ending"] = true
	invalid["progress"]["relays"] = {"office": true, "service": true}
	invalid["world"]["circuits"]["difficulty_hard"] = {"enabled": true}
	_write(path, store._encode(invalid))
	var primary_hash: String = FileAccess.get_sha256(path)
	var backup_hash: String = FileAccess.get_sha256(path + ".backup")
	var loaded: StorageResult = store.read()
	check.call(loaded.ok and loaded.recovered and loaded.payload == previous,
		"Malformed difficulty primary recovers the previous valid checkpoint")
	var result: StorageResult = store.write(invalid)
	check.call(not result.ok and result.code == &"invalid" and FileAccess.get_sha256(path) == primary_hash
		and FileAccess.get_sha256(path + ".backup") == backup_hash,
		"Rejecting malformed difficulty writes preserves primary and backup bytes")

func _write(path: String, contents: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(contents)
	file.close()
