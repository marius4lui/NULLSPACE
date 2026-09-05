extends Control
## Explicitly temporary M2 fixture. Uses the engine's default font, no production assets.
## Counters below test input ownership; they do not implement movement, guns or objectives.

var _content: VBoxContainer
var _status: Label
var _readout: Label
var _buttons: Array[Button] = []
var _initial_focus: Control
var _draft: Dictionary = {}
var _notice: String = ""
var _diagnostic_position: Vector2 = Vector2.ZERO
var _diagnostic_look: Vector2 = Vector2.ZERO
var _fire_edges: int = 0
var _reload_edges: int = 0
var _live_snapshot: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_frame()
	GameFlow.state_changed.connect(_on_state_changed)
	GameFlow.load_started.connect(_on_load)
	GameFlow.operation_failed.connect(_on_failure)
	if SettingsManager.last_result != null and not SettingsManager.last_result.ok and SettingsManager.last_result.code != &"missing":
		_notice = "Preferences: " + SettingsManager.last_result.message + " Defaults are active."
	_show_screen()

func _build_frame() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.045, 0.05, 0.06)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	add_child(margin)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 16)
	margin.add_child(stack)
	var title: Label = Label.new()
	title.text = "NULLSPACE  /  M2 TECHNICAL DIAGNOSTIC"
	title.add_theme_font_size_override("font_size", 32)
	stack.add_child(title)
	var disclaimer: Label = Label.new()
	disclaimer.text = "Temporary test interface and default font. No campaign, weapons, monster, production art or audio exists here."
	disclaimer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	disclaimer.add_theme_font_size_override("font_size", 20)
	stack.add_child(disclaimer)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(_status)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	stack.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	scroll.add_child(_content)

func _show_screen() -> void:
	for child: Node in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_buttons.clear()
	_initial_focus = null
	_readout = null
	_status.text = "State: %s | Input generation: %s | %s" % [NullGameFlow.State.keys()[GameFlow.state], InputGate.generation, _notice]
	match GameFlow.state:
		NullGameFlow.State.MENU:
			_title_menu()
		NullGameFlow.State.SETTINGS:
			_settings_menu()
		NullGameFlow.State.PLAYING:
			_label("INPUT OWNERSHIP FIXTURE — these counters are not gameplay.")
			_label("WASD: diagnostic displacement | Mouse: diagnostic look | LMB / R: accepted action edges\nF: flashlight state | E: save diagnostic checkpoint | Esc: pause\nF9: simulate death | F10: simulate completed save and ending. Neither is a campaign run.")
			_readout = _label("")
		NullGameFlow.State.PAUSED:
			_button("Resume", func() -> void: GameFlow.resume_game())
			_button("Settings", func() -> void: GameFlow.open_settings())
			_button("Return to title", func() -> void: GameFlow.return_to_menu())
			_label("Gameplay is paused. Held controls must be released before they can act after Resume.")
		NullGameFlow.State.DEAD:
			_label("Simulated death — test checkpoint restoration.")
			_button("Restart checkpoint", func() -> void: GameFlow.continue_game())
			_button("Return to title", func() -> void: GameFlow.return_to_menu())
		NullGameFlow.State.ENDING:
			_label("Diagnostic ending state. This did not play or complete NULLSPACE.")
			_button("Return to title", func() -> void: GameFlow.return_to_menu())
		NullGameFlow.State.LOADING:
			_label("Restoring committed snapshot. Gameplay input is disabled.")
	_focus_first.call_deferred()

func _title_menu() -> void:
	var saved: StorageResult = SaveSystem.load_checkpoint()
	var can_continue: bool = saved.ok and not saved.payload["progress"]["ending"]
	_button("New diagnostic session", func() -> void: GameFlow.begin_new_game())
	var continue_button: Button = _button("Continue", func() -> void: GameFlow.continue_game())
	continue_button.disabled = not can_continue
	continue_button.focus_mode = Control.FOCUS_ALL if can_continue else Control.FOCUS_NONE
	_button("Settings / Accessibility", func() -> void: GameFlow.open_settings())
	_button("Controls", _show_controls)
	_button("Credits / fixture notice", _show_credits)
	_button("Quit", func() -> void: get_tree().quit())
	_label("Save status: " + ("Completed diagnostic session; start a new one." if saved.ok and not can_continue else saved.message))

func _settings_menu() -> void:
	_draft = SettingsManager.snapshot()
	_label("SETTINGS — Apply saves preferences before changing the runtime.")
	_option("Resolution", "resolution", [[1280, 720], [1600, 900], [1920, 1080], [2560, 1440], [3840, 2160]],
		["1280 × 720", "1600 × 900", "1920 × 1080", "2560 × 1440", "3840 × 2160"])
	_option("Display", "display_mode", ["windowed", "fullscreen"], ["Windowed", "Fullscreen"])
	_option("Quality preset", "quality", SettingsSchema.QUALITY_IDS, ["Low", "Medium", "High", "Ultra"])
	_toggle("VSync", "vsync")
	_number("Master volume", "master_volume", 0.0, 1.0, 0.05)
	_number("Music / ambience volume", "ambience_volume", 0.0, 1.0, 0.05)
	_number("Effects volume", "effects_volume", 0.0, 1.0, 0.05)
	_number("Mouse sensitivity", "mouse_sensitivity", 0.05, 5.0, 0.05)
	_number("Horizontal FOV (degrees)", "horizontal_fov", 60.0, 110.0, 1.0)
	_toggle("Invert mouse Y", "invert_y")
	_number("Head bob intensity", "head_bob", 0.0, 1.0, 0.05)
	_number("Camera shake intensity", "camera_shake", 0.0, 1.0, 0.05)
	_toggle("Subtitles / textual audio cues", "subtitles")
	_toggle("Center dot", "center_dot")
	_toggle("Reduce intense flashes", "reduced_flashes")
	_button("Apply settings", _apply_settings)
	_button("Save and apply defaults", func() -> void:
		var result: StorageResult = SettingsManager.apply_settings(SettingsSchema.defaults())
		_notice = "Defaults saved." if result.ok else result.message
		_show_screen())
	_button("Back (discard unapplied edits)", func() -> void: GameFlow.close_settings())
	_label("Resolution, display, VSync, audio bus gains and render scale/MSAA apply here. Mouse settings affect the diagnostic look counters. FOV and accessibility values are stored for future gameplay consumers; no production camera/audio/VFX exists yet.")

func _apply_settings() -> void:
	var result: StorageResult = SettingsManager.apply_settings(_draft)
	_notice = "Settings saved and applied." if result.ok else result.message
	_show_screen()

func _show_controls() -> void:
	_notice = "WASD movement; mouse look; LMB fire; R reload; 1/2 weapons; Shift sprint; Ctrl crouch; F flashlight; E interact; Esc pause. M2 only validates input ownership."
	_show_screen()

func _show_credits() -> void:
	_notice = "NULLSPACE original project. This fixture uses Godot's bundled default font solely for M2 diagnostics. Production UI, original font, credits and notices remain future work."
	_show_screen()

func _process(delta: float) -> void:
	if GameFlow.state != NullGameFlow.State.PLAYING:
		return
	_diagnostic_position += InputGate.movement_vector() * delta
	if _readout != null:
		_readout.text = "Accepted fire edges: %s  |  Reload edges: %s\nDiagnostic displacement: (%.3f, %.3f)\nDiagnostic look radians: (%.3f, %.3f)\nCheckpoint: %s  |  Saved circuit: %s  |  Flashlight: %s\nFocused: %s  |  Input enabled: %s  |  Generation: %s" % [
			_fire_edges, _reload_edges, _diagnostic_position.x, _diagnostic_position.y,
			_diagnostic_look.x, _diagnostic_look.y, _live_snapshot.get("checkpoint", {}).get("id", "none"),
			_live_snapshot.get("world", {}).get("circuits", {}).get("diagnostic_switch", false),
			_live_snapshot.get("player", {}).get("flashlight_enabled", false),
			InputGate.focused, InputGate.accepts_input(), InputGate.generation]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_diagnostic_look += InputGate.look_delta(event)
	if InputGate.accept_press(event, &"fire"):
		_fire_edges += 1
		Telemetry.record(&"diagnostic_input", {"action": "fire", "count": _fire_edges})
	if InputGate.accept_press(event, &"reload"):
		_reload_edges += 1
	if InputGate.accept_press(event, &"flashlight"):
		_live_snapshot["player"]["flashlight_enabled"] = not _live_snapshot["player"]["flashlight_enabled"]
	if InputGate.accept_press(event, &"interact"):
		_save_diagnostic()
	if event is InputEventKey and event.pressed and not event.echo and InputGate.accepts_input():
		if event.keycode == KEY_F9:
			GameFlow.die()
		elif event.keycode == KEY_F10:
			_simulate_ending()

func _save_diagnostic() -> void:
	_live_snapshot["checkpoint"]["id"] = "diagnostic_checkpoint"
	_live_snapshot["world"]["circuits"]["diagnostic_switch"] = not _live_snapshot["world"]["circuits"].get("diagnostic_switch", false)
	_live_snapshot["session"]["elapsed_seconds"] = Telemetry.simulation_seconds
	var result: StorageResult = CheckpointSystem.commit_snapshot(_live_snapshot)
	_notice = "Diagnostic checkpoint saved." if result.ok else result.message
	_status.text = "State: PLAYING | " + _notice
	Telemetry.record(&"diagnostic_checkpoint", {"ok": result.ok, "circuit": _live_snapshot["world"]["circuits"]["diagnostic_switch"]})

func _simulate_ending() -> void:
	for relay: String in SnapshotSchema.RELAYS:
		_live_snapshot["progress"]["relays"][relay] = true
	_live_snapshot["progress"]["ending"] = true
	var result: StorageResult = CheckpointSystem.commit_snapshot(_live_snapshot)
	if result.ok:
		GameFlow.end_campaign()
	else:
		_on_failure(result)

func _on_load(snapshot: Dictionary, generation: int) -> void:
	_live_snapshot = snapshot.duplicate(true)
	_diagnostic_position = Vector2.ZERO
	_diagnostic_look = Vector2.ZERO
	_fire_edges = 0
	_reload_edges = 0
	_notice = "Restored " + str(snapshot["checkpoint"]["id"])
	# No world exists to stage in this fixture. A production scene must acknowledge only
	# after its actual consumers are restored and checkpoint anchors have been validated.
	GameFlow.complete_load.call_deferred(generation)

func _on_state_changed(_previous: NullGameFlow.State, _current: NullGameFlow.State, _reason: StringName) -> void:
	_show_screen()

func _on_failure(result: StorageResult) -> void:
	_notice = result.message
	_show_screen()

func _label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 22)
	_content.add_child(label)
	return label

func _button(text: String, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 48)
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(callback)
	_content.add_child(button)
	_buttons.append(button)
	if _initial_focus == null:
		_initial_focus = button
	return button

func _row(caption: String) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size.y = 44
	_content.add_child(row)
	var label: Label = Label.new()
	label.text = caption
	label.custom_minimum_size.x = 480
	label.add_theme_font_size_override("font_size", 22)
	row.add_child(label)
	return row

func _toggle(caption: String, key: String) -> void:
	var control: CheckButton = CheckButton.new()
	control.button_pressed = _draft[key]
	control.toggled.connect(func(value: bool) -> void: _draft[key] = value)
	_row(caption).add_child(control)

func _number(caption: String, key: String, minimum: float, maximum: float, step: float) -> void:
	var control: SpinBox = SpinBox.new()
	control.min_value = minimum
	control.max_value = maximum
	control.step = step
	control.value = float(_draft[key])
	control.custom_minimum_size.x = 240
	control.value_changed.connect(func(value: float) -> void: _draft[key] = value)
	_row(caption).add_child(control)

func _option(caption: String, key: String, values: Array, labels: Array) -> void:
	var control: OptionButton = OptionButton.new()
	for index: int in values.size():
		control.add_item(labels[index])
		if values[index] == _draft[key]:
			control.select(index)
	control.item_selected.connect(func(index: int) -> void: _draft[key] = values[index])
	control.custom_minimum_size.x = 320
	_row(caption).add_child(control)
	if _initial_focus == null:
		_initial_focus = control

func _focus_first() -> void:
	if is_instance_valid(_initial_focus):
		_initial_focus.grab_focus()
