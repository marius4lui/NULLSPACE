class_name StorageResult
extends RefCounted

var ok: bool = false
var code: StringName = &"unknown"
var message: String = ""
var payload: Dictionary = {}
var recovered: bool = false

static func success(value: Dictionary, was_recovered: bool = false) -> StorageResult:
	var result: StorageResult = StorageResult.new()
	result.ok = true
	result.code = &"recovered" if was_recovered else &"ok"
	result.payload = value.duplicate(true)
	result.recovered = was_recovered
	result.message = "Recovered the previous valid checkpoint." if was_recovered else "Ready."
	return result

static func failure(reason: StringName, detail: String) -> StorageResult:
	var result: StorageResult = StorageResult.new()
	result.code = reason
	result.message = detail
	return result

