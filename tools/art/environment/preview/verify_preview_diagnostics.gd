extends SceneTree
## Bounded logical checks for inspection conveniences; no native input/art/performance claim.

const PREVIEW: PackedScene = preload("res://preview.tscn")
var _errors: Array[String] = []
var _checks: int = 0


func _initialize() -> void:
	call_deferred("_verify")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_errors.append(description)


func _verify() -> void:
	var viewer: Node3D = PREVIEW.instantiate() as Node3D
	root.add_child(viewer)
	_check(not Input.use_accumulated_input, "Viewer disables motion accumulation")
	_check(viewer._capture_settling, "Initial capture begins with settling guard")
	_check(not viewer._capture_allows_motion(), "Initial settling blocks look/movement")
	await process_frame
	await process_frame
	await process_frame
	_check(not viewer._capture_settling, "Capture guard clears after two process frames")
	var baseline: Dictionary = viewer._diagnostics.state()
	_check(baseline["shadowed_fixtures"] == 4, "Reference retains original four shadow lights")
	_check(viewer._room.fixtures.size() == 11 and baseline["visible_direct_fixtures"] == 10, "Reference retains eleven fixtures with one authored OFF")
	_check(not baseline["simple_architecture_material"], "No diagnostic material enabled by default")
	_check(not baseline["fog"] and not baseline["volumetric_fog"] and not baseline["sdfgi"], "No hidden fog/GI cost in reference")
	for key: int in [KEY_F2, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10]:
		_check(viewer._diagnostics.handle_key(key), "Recognized diagnostic toggle " + OS.get_keycode_string(key))
		_check(viewer._diagnostics.state() != baseline, "Toggle changes recorded state " + OS.get_keycode_string(key))
		viewer._diagnostics.handle_key(key)
		_check(viewer._diagnostics.state() == baseline, "Toggle exactly restores baseline " + OS.get_keycode_string(key))
	for expected: float in [0.75, 0.5, 1.0]:
		viewer._diagnostics.handle_key(KEY_F3)
		_check(is_equal_approx(viewer._diagnostics.state()["scale_3d"], expected), "Render scale cycle " + str(expected))
	_check(viewer._diagnostics.state() == baseline, "Scale cycle restores baseline")
	_check(not viewer._diagnostics.handle_key(KEY_W), "Gameplay/inspection movement key is not a render toggle")
	for index: int in range(1, 11):
		viewer._set_view(index)
		_check(viewer._review_view == index and viewer._camera.global_position.is_finite(), "Valid review pose " + str(index))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	viewer._begin_capture()
	_check(viewer._capture_settling and not viewer._capture_allows_motion(), "Re-capture starts guarded")
	_check(viewer._capture_ready_frame - viewer._frames == 2, "Re-capture schedules exactly two settling frames")
	await process_frame
	await process_frame
	await process_frame
	_check(not viewer._capture_settling, "Re-capture guard clears")
	var report: Dictionary = {"schema": 1, "scope": "Headless logical diagnostic checks only; actual native recapture, appearance and timings remain pending",
		"godot": Engine.get_version_info(), "checks": _checks, "errors": _errors,
		"baseline_render_state": baseline, "result": "LOGICAL_CHECKS_PASSED" if _errors.is_empty() else "FAIL"}
	var destination: String = OS.get_environment("NULLSPACE_PREVIEW_DIAGNOSTIC_REPORT")
	if not destination.is_empty():
		DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
		var file: FileAccess = FileAccess.open(destination, FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t") + "\n")
	print("M4_PREVIEW_DIAGNOSTIC_VERIFICATION ", JSON.stringify(report))
	viewer.queue_free()
	quit(0 if _errors.is_empty() else 1)
