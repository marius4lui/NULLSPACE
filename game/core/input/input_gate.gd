class_name NullInputGate
extends Node
## Every gameplay consumer must use this gate, never raw Input polling.
## It cannot distinguish human input from OS automation; provenance is explicitly unverified.

signal invalidated(generation: int, reason: StringName)
signal input_ownership_changed(gameplay: bool)

const ACTIONS: Array[StringName] = [&"move_forward", &"move_back", &"move_left", &"move_right",
	&"sprint", &"crouch", &"fire", &"reload", &"weapon_1", &"weapon_2", &"flashlight", &"interact"]

var generation: int = 0
var gameplay_enabled: bool = false
var focused: bool = true
var input_provenance: StringName = &"unverified_os_input"
var _blocked: Dictionary = {}
var _enable_after_frame: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	focused = DisplayServer.get_name() == "headless" or DisplayServer.window_is_focused()

func set_gameplay_enabled(enabled: bool, reason: StringName) -> void:
	invalidate(reason)
	gameplay_enabled = enabled and focused
	_enable_after_frame = Engine.get_process_frames() + 2
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if gameplay_enabled else Input.MOUSE_MODE_VISIBLE
	input_ownership_changed.emit(gameplay_enabled)

func invalidate(reason: StringName) -> void:
	generation += 1
	_blocked.clear()
	for action: StringName in ACTIONS:
		if Input.is_action_pressed(action):
			_blocked[action] = true
	invalidated.emit(generation, reason)

func _process(_delta: float) -> void:
	for action: Variant in _blocked.keys():
		if not Input.is_action_pressed(action):
			_blocked.erase(action)

func accepts_input() -> bool:
	return gameplay_enabled and focused and Engine.get_process_frames() >= _enable_after_frame

func accepts_generation(action_generation: int) -> bool:
	return accepts_input() and action_generation == generation

func pressed(action: StringName) -> bool:
	return accepts_input() and not _blocked.has(action) and Input.is_action_pressed(action)

func accept_press(event: InputEvent, action: StringName) -> bool:
	return accepts_input() and not _blocked.has(action) and event.is_action_pressed(action, false)

func movement_vector() -> Vector2:
	if not accepts_input():
		return Vector2.ZERO
	var direction: Vector2 = Vector2(float(pressed(&"move_right")) - float(pressed(&"move_left")),
		float(pressed(&"move_back")) - float(pressed(&"move_forward")))
	return direction.limit_length()

func look_delta(event: InputEventMouseMotion) -> Vector2:
	if not accepts_input():
		return Vector2.ZERO
	var sensitivity: float = float(SettingsManager.get_value("mouse_sensitivity"))
	var flip: float = -1.0 if SettingsManager.get_value("invert_y") else 1.0
	return event.screen_relative * Vector2(1.0, flip) * sensitivity * SnapshotSchema.TUNING.mouse_radians_per_pixel

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		focused = false
		set_gameplay_enabled(false, &"focus_lost")
		if is_inside_tree():
			GameFlow.pause_game(&"focus_lost")
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focused = true
		# Focus return never resumes gameplay on its own.

