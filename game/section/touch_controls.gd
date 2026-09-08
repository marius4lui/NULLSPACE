class_name SectionTouchControls
extends Control
## One owner per finger. All gameplay requests pass through the existing input gate.

const LABELS: Dictionary = {&"fire": "FIRE", &"reload": "LOAD", &"interact": "USE",
	&"flashlight": "LIGHT", &"crouch": "CROUCH", &"sprint": "RUN", &"pause": "II"}
var fingers: Dictionary = {}
var buttons: Dictionary = {}
var stick_center := Vector2.ZERO
var stick_value := Vector2.ZERO
var stick_radius: float = 74.0
var button_radius: float = 34.0
var safe := Rect2()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	InputGate.invalidated.connect(_reset)
	SettingsManager.settings_changed.connect(func(_values: Dictionary) -> void: _layout())
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	safe = Rect2(Vector2.ZERO, get_viewport_rect().size)
	if OS.has_feature("android"):
		var display_size := Vector2(DisplayServer.screen_get_size())
		var area := Rect2(DisplayServer.get_display_safe_area())
		if display_size.x > 0 and display_size.y > 0 and area.size.x > 0:
			var ratio := safe.size / display_size
			safe = Rect2(area.position * ratio, area.size * ratio)
	safe = safe.grow(-24.0)
	var scale: float = minf(safe.size.y / 650.0, safe.size.x / 1150.0) * float(SettingsManager.get_value("touch_size"))
	button_radius = 34.0 * scale
	stick_radius = 74.0 * scale
	stick_center = Vector2(safe.position.x + 110.0 * scale, safe.end.y - 110.0 * scale)
	var right: float = safe.end.x - 46.0 * scale
	var bottom: float = safe.end.y - 48.0 * scale
	buttons = {
		&"fire": Vector2(right - 40 * scale, bottom - 170 * scale),
		&"interact": Vector2(right - 135 * scale, bottom - 105 * scale),
		&"reload": Vector2(right, bottom),
		&"flashlight": Vector2(right - 90 * scale, bottom),
		&"crouch": Vector2(right - 180 * scale, bottom),
		&"sprint": Vector2(stick_center.x + 145 * scale, bottom),
		&"pause": Vector2(safe.end.x - 38 * scale, safe.position.y + 38 * scale)}
	_reset(0, &"layout")

func _process(_delta: float) -> void:
	visible = InputGate.uses_touch() and GameFlow.state == NullGameFlow.State.PLAYING
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not InputGate.uses_touch() or GameFlow.state != NullGameFlow.State.PLAYING:
		return
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			_press(event.index, event.position)
		else:
			_release(event.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		_drag(event.index, event.position, event.relative)
		get_viewport().set_input_as_handled()

func _press(index: int, at: Vector2) -> void:
	if fingers.has(index) or not InputGate.accepts_input():
		return
	for action: StringName in buttons:
		if at.distance_to(buttons[action]) <= button_radius * (1.25 if action == &"fire" else 1.0):
			if fingers.values().has(action): return
			fingers[index] = action
			if action == &"pause":
				GameFlow.pause_game()
			elif action in [&"crouch", &"sprint"]:
				InputGate.set_touch_held(action, not InputGate.pressed(action))
			else:
				InputGate.touch_action(action)
			return
	if at.x < safe.position.x + safe.size.x * 0.4:
		if not fingers.values().has(&"move"):
			fingers[index] = &"move"
			_move(at)
	elif not fingers.values().has(&"look"):
		fingers[index] = &"look"

func _drag(index: int, at: Vector2, relative: Vector2) -> void:
	var role: StringName = fingers.get(index, &"")
	if role == &"move":
		_move(at)
	elif role == &"look" or role == &"fire":
		InputGate.touch_look(relative, get_viewport_rect().size.y)

func _move(at: Vector2) -> void:
	stick_value = ((at - stick_center) / stick_radius).limit_length()
	if stick_value.length() < 0.12: stick_value = Vector2.ZERO
	InputGate.set_touch_movement(stick_value)

func _release(index: int) -> void:
	if fingers.get(index, &"") == &"move":
		stick_value = Vector2.ZERO
		InputGate.set_touch_movement(Vector2.ZERO)
	fingers.erase(index)

func _reset(_generation: int, _reason: StringName) -> void:
	fingers.clear()
	stick_value = Vector2.ZERO
	InputGate.set_touch_movement(Vector2.ZERO)
	InputGate.set_touch_held(&"sprint", false)
	InputGate.set_touch_held(&"crouch", false)

func _draw() -> void:
	var alpha: float = float(SettingsManager.get_value("touch_opacity"))
	var ink := Color(0.86, 0.87, 0.73, alpha)
	var fill := Color(0.035, 0.05, 0.035, alpha * 0.7)
	draw_circle(stick_center, stick_radius, fill)
	draw_arc(stick_center, stick_radius, 0, TAU, 48, ink, 2, true)
	draw_circle(stick_center + stick_value * stick_radius * 0.65, stick_radius * 0.3, ink)
	var font: Font = ThemeDB.fallback_font
	var font_size: int = maxi(14, int(button_radius * 0.42))
	for action: StringName in buttons:
		var center: Vector2 = buttons[action]
		var radius: float = button_radius * (1.25 if action == &"fire" else 1.0)
		draw_circle(center, radius, ink.darkened(0.45) if InputGate.pressed(action) else fill)
		draw_arc(center, radius, 0, TAU, 36, ink, 2, true)
		var label: String = LABELS[action]
		var extent := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, center + Vector2(-extent.x / 2, font_size * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)
