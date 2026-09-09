class_name NullInputGate
extends Node
## Every gameplay consumer must use this gate, never raw Input polling.
## It cannot distinguish human input from OS automation; provenance is explicitly unverified.

signal invalidated(generation: int, reason: StringName)
signal input_ownership_changed(gameplay: bool)
signal touch_looked(delta: Vector2)

const ACTIONS: Array[StringName] = [&"move_forward", &"move_back", &"move_left", &"move_right",
	&"sprint", &"crouch", &"fire", &"reload", &"weapon_1", &"weapon_2", &"flashlight", &"interact"]

var generation: int = 0
var gameplay_enabled: bool = false
var focused: bool = true
var input_provenance: StringName = &"unverified_os_input"
var _blocked: Dictionary = {}
var _enable_after_frame: int = 0
var touch_movement: Vector2 = Vector2.ZERO
var _touch_held: Dictionary = {}

func uses_touch() -> bool:
	return OS.has_feature("android") or OS.get_cmdline_user_args().has("--touch-ui")

func set_touch_movement(value: Vector2) -> void:
	touch_movement = value.limit_length() if accepts_input() else Vector2.ZERO

func set_touch_held(action: StringName, held: bool) -> void:
	if action in ACTIONS:
		_touch_held[action] = held and accepts_input()

func touch_action(action: StringName) -> void:
	if not accepts_input() or action not in ACTIONS:
		return
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)

func touch_look(relative: Vector2, viewport_height: float) -> void:
	if accepts_input():
		var flip: float = -1.0 if SettingsManager.get_value("invert_y") else 1.0
		touch_looked.emit(relative / maxf(viewport_height, 1.0) * float(SettingsManager.get_value("touch_sensitivity")) * Vector2(3.0, 3.0 * flip))

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	focused = DisplayServer.get_name() == "headless" or DisplayServer.window_is_focused()

func set_gameplay_enabled(enabled: bool, reason: StringName) -> void:
	invalidate(reason)
	gameplay_enabled = enabled and focused
	_enable_after_frame = Engine.get_process_frames() + 2
	if DisplayServer.get_name() != "headless" and not uses_touch():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if gameplay_enabled else Input.MOUSE_MODE_VISIBLE
	input_ownership_changed.emit(gameplay_enabled)

func invalidate(reason: StringName) -> void:
	generation += 1
	touch_movement = Vector2.ZERO
	_touch_held.clear()
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
	return accepts_input() and not _blocked.has(action) and (Input.is_action_pressed(action) or _touch_held.get(action, false))

func accept_press(event: InputEvent, action: StringName) -> bool:
	if uses_touch() and event is InputEventMouseButton:
		return false
	return accepts_input() and not _blocked.has(action) and event.is_action_pressed(action, false)

func movement_vector() -> Vector2:
	if not accepts_input():
		return Vector2.ZERO
	var direction: Vector2 = Vector2(float(pressed(&"move_right")) - float(pressed(&"move_left")),
		float(pressed(&"move_back")) - float(pressed(&"move_forward")))
	return (direction + touch_movement).limit_length()

func look_delta(event: InputEventMouseMotion) -> Vector2:
	if not accepts_input():
		return Vector2.ZERO
	var sensitivity: float = float(SettingsManager.get_value("mouse_sensitivity"))
	var flip: float = -1.0 if SettingsManager.get_value("invert_y") else 1.0
	return event.screen_relative * Vector2(1.0, flip) * sensitivity * SnapshotSchema.TUNING.mouse_radians_per_pixel

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		focused = false
		set_gameplay_enabled(false, &"focus_lost")
		if is_inside_tree():
			GameFlow.pause_game(&"focus_lost")
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		focused = true
		# Focus return never resumes gameplay on its own.
