class_name NullspaceSectionMenu
extends Control

signal quit_requested
signal start_requested(difficulty_id: String)
## Concrete title/pause/settings and restrained in-game prompts for the playable scene.

var _shade: ColorRect
var _stack: VBoxContainer
var _panel: MarginContainer
var _prompt: Label
var _hint: Label
var _dot: Label
var _stamina: ProgressBar
var _ammo: Label
var _armed: bool = false
var _draft: Dictionary = {}
var _hint_time: float = 0.0
var _notice: String = ""
var objective: String = ""
var _injury: Label
var _injury_time: float = 0
var selected_difficulty: String = DifficultyConfig.DEFAULT_ID

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 24
	ui_theme.set_color("font_color", "Label", Color(0.87, 0.86, 0.77))
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.16, 0.18, 0.145, 0.9) if state == "normal" else Color(0.27, 0.29, 0.22, 0.95)
		box.content_margin_left = 20
		box.content_margin_right = 20
		box.content_margin_top = 10
		box.content_margin_bottom = 10
		if state == "focus":
			box.bg_color.a = 0.0
			box.set_border_width_all(2)
			box.border_color = Color(0.7, 0.72, 0.5)
		ui_theme.set_stylebox(state, "Button", box)
	theme = ui_theme
	_shade = ColorRect.new()
	_shade.color = Color(0.035, 0.044, 0.03, 0.90)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_shade)
	_panel = MarginContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		_panel.add_theme_constant_override("margin_" + side, 64)
	add_child(_panel)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	_panel.add_child(scroll)
	_stack = VBoxContainer.new()
	_stack.custom_minimum_size.x = 680
	_stack.add_theme_constant_override("separation", 12)
	scroll.add_child(_stack)
	_hint = _hud_label(Control.PRESET_TOP_LEFT, Vector2(40, 36), Vector2(1100, 95))
	_prompt = _hud_label(Control.PRESET_CENTER_BOTTOM, Vector2(-500, -110), Vector2(1000, 48))
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dot = _hud_label(Control.PRESET_CENTER, Vector2(-10, -18), Vector2(20, 36))
	_dot.text = "·"
	_dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ammo = _hud_label(Control.PRESET_BOTTOM_RIGHT, Vector2(-270, -72), Vector2(230, 36))
	_ammo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_injury = _hud_label(Control.PRESET_BOTTOM_LEFT, Vector2(40, -72), Vector2(600, 36))
	_injury.add_theme_color_override("font_color", Color(.80, .61, .48))
	_stamina = ProgressBar.new()
	_stamina.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_stamina.position += Vector2(-85, -44)
	_stamina.size = Vector2(170, 4)
	_stamina.show_percentage = false
	_stamina.max_value = 1.0
	_stamina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stamina)
	GameFlow.state_changed.connect(func(_a: int, _b: int, _reason: StringName) -> void: _show_screen())
	GameFlow.operation_failed.connect(func(result: StorageResult) -> void: _notice = result.message; _show_screen())
	_show_screen()

func _show_screen() -> void:
	for child: Node in _stack.get_children():
		_stack.remove_child(child)
		child.queue_free()
	var playing: bool = GameFlow.state == NullGameFlow.State.PLAYING
	_shade.visible = not playing
	_panel.visible = not playing
	_prompt.visible = playing
	_hint.visible = playing
	_dot.visible = playing and bool(SettingsManager.get_value("center_dot"))
	_stamina.visible = false
	_ammo.visible = playing and _armed
	_injury.visible = playing
	if playing:
		_notice = ""
		return
	_label("NULLSPACE", 58)
	match GameFlow.state:
		NullGameFlow.State.MENU:
			_label("The building has ears.", 26)
			_label("Difficulty", 20)
			var difficulty_button := _button(DifficultyConfig.title(selected_difficulty) + "  ›", func() -> void:
				var index: int = (DifficultyConfig.IDS.find(selected_difficulty) + 1) % DifficultyConfig.IDS.size()
				selected_difficulty = DifficultyConfig.IDS[index]
				_show_screen())
			difficulty_button.tooltip_text = "Click or press Enter to choose the next difficulty."
			_label(str(DifficultyConfig.profile(selected_difficulty)["summary"]), 18)
			_button("Start " + DifficultyConfig.title(selected_difficulty), func() -> void: start_requested.emit(selected_difficulty))
			var resume := _button("Continue", func() -> void: GameFlow.continue_game())
			resume.disabled = not SaveSystem.continue_available()
			_button("Settings", func() -> void: GameFlow.open_settings())
			_button("Controls", _controls)
			_button("Credits", _credits)
			_button("Quit", func() -> void: quit_requested.emit())
			_label("Room 1 difficulty build — selection is fixed for the run.", 18)
		NullGameFlow.State.PAUSED:
			_label("Paused")
			_button("Resume", func() -> void: GameFlow.resume_game())
			_button("Settings", func() -> void: GameFlow.open_settings())
			_button("Return to title", func() -> void: GameFlow.return_to_menu())
			_label(objective, 20)
		NullGameFlow.State.SETTINGS:
			_settings()
		NullGameFlow.State.DEAD:
			_label("You did not make it out.")
			_button("Restart checkpoint", func() -> void: GameFlow.continue_game())
			_button("Return to title", func() -> void: GameFlow.return_to_menu())
		NullGameFlow.State.ENDING:
			_credits()
		NullGameFlow.State.LOADING:
			_label("Restoring your last safe position…")
	if not _notice.is_empty():
		_label(_notice, 20)
	_focus_first.call_deferred()

func _settings() -> void:
	_draft = SettingsManager.snapshot()
	_label("Settings")
	_option("Graphics", "quality", ["low", "high"], ["Laptop — 75% render scale, no AO", "Enhanced — native scale, ambient occlusion"])
	_option("Resolution", "resolution", [[1280, 720], [1600, 900], [1920, 1080]], ["1280 × 720", "1600 × 900", "1920 × 1080"])
	_option("Display", "display_mode", ["windowed", "fullscreen"], ["Windowed", "Fullscreen"])
	_toggle("VSync", "vsync")
	_option("Frame-rate limit", "fps_limit", [60, 90, 120, 30, 0], ["60 FPS", "90 FPS", "120 FPS", "30 FPS", "Unlimited"])
	_number("Master volume", "master_volume", 0.0, 1.0, 0.05)
	_number("Ambience", "ambience_volume", 0.0, 1.0, 0.05)
	_number("Effects", "effects_volume", 0.0, 1.0, 0.05)
	_number("Mouse sensitivity", "mouse_sensitivity", 0.05, 5.0, 0.05)
	_number("Horizontal field of view", "horizontal_fov", 60, 110, 1)
	_toggle("Invert mouse Y", "invert_y")
	_number("Head movement", "head_bob", 0, 1, 0.1)
	_number("Camera shake", "camera_shake", 0, 1, 0.1)
	_toggle("Reduce light flashes", "reduced_flashes")
	_toggle("Center dot", "center_dot")
	_button("Apply", func() -> void:
		var result: StorageResult = SettingsManager.apply_settings(_draft)
		_notice = "Settings saved." if result.ok else result.message
		_show_screen())
	_button("Back", func() -> void: GameFlow.close_settings())

func _option(title: String, key: String, values: Array, captions: Array) -> void:
	var row: HBoxContainer = _row(title)
	# A few fixed choices do not need a popup window (which triggered native focus
	# connection errors on this engine build when the settings screen was rebuilt).
	var choice := Button.new()
	choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice.text = str(captions[maxi(0, values.find(_draft[key]))]) + "  ›"
	choice.tooltip_text = "Click or press Enter to choose the next value. Apply to save."
	choice.pressed.connect(func() -> void:
		var index: int = (values.find(_draft[key]) + 1) % values.size()
		_draft[key] = values[index]
		choice.text = str(captions[index]) + "  ›")
	row.add_child(choice)

func _number(title: String, key: String, minimum: float, maximum: float, step: float) -> void:
	var row: HBoxContainer = _row(title)
	var number := SpinBox.new()
	number.min_value = minimum
	number.max_value = maximum
	number.step = step
	number.value = float(_draft[key])
	number.custom_minimum_size.x = 160
	number.value_changed.connect(func(value: float) -> void: _draft[key] = value)
	row.add_child(number)

func _toggle(title: String, key: String) -> void:
	var check := CheckButton.new()
	check.text = title
	check.button_pressed = bool(_draft[key])
	check.toggled.connect(func(value: bool) -> void: _draft[key] = value)
	_stack.add_child(check)

func _row(title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	_stack.add_child(row)
	var caption := Label.new()
	caption.text = title
	caption.custom_minimum_size.x = 335
	row.add_child(caption)
	return row

func _controls() -> void:
	_notice = "WASD — move · Mouse — look · Shift — sprint · Ctrl — crouch\nF — flashlight · E — interact · Escape — pause\nLeft mouse — pistol · R — reload"
	_show_screen()

func _credits() -> void:
	_notice = "NULLSPACE — marius4lui\nOriginal project content created with GPT-6 Astra through Codex.\nMade with Godot and Blender. Bundled font: Open Sans (SIL OFL)."
	if GameFlow.state != NullGameFlow.State.ENDING:
		_show_screen()
	else:
		_label("You found the way out.")
		_label("For the first time, there is no hum.", 22)
		_button("Return to title", func() -> void: GameFlow.return_to_menu())

func _label(text: String, font_size: int = 24) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	_stack.add_child(label)
	return label

func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(action)
	_stack.add_child(button)
	return button

func _focus_first() -> void:
	for child: Node in _stack.get_children():
		if child is Button and not child.disabled:
			child.grab_focus()
			break

func _hud_label(preset: Control.LayoutPreset, offset: Vector2, dimensions: Vector2) -> Label:
	var label := Label.new()
	label.set_anchors_and_offsets_preset(preset)
	label.position += offset
	label.size = dimensions
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)
	return label

func set_prompt(text: String) -> void:
	_prompt.text = text

func show_hint(text: String) -> void:
	_hint.text = text
	_hint_time = 10.0
	_hint.modulate.a = 1.0

func set_stamina(value: float) -> void:
	_stamina.visible = value < 0.98
	_stamina.value = value

func show_injury() -> void:
	_injury_time = 4.0

func set_health(value: float) -> void:
	_injury.text = "Injured — break sight and get away." if value < 50 else ""
	_injury.modulate.a = 1.0 if _injury_time > 0 else .5

func set_ammunition(loaded: int, spare: int, armed: bool) -> void:
	_armed = armed
	_ammo.text = "%02d   /   %02d" % [loaded, spare]
	_ammo.visible = armed and GameFlow.state == NullGameFlow.State.PLAYING

func _process(delta: float) -> void:
	if GameFlow.state == NullGameFlow.State.PLAYING:
		_injury_time = maxf(0, _injury_time - delta)
		_hint_time = maxf(0.0, _hint_time - delta)
		_hint.modulate.a = minf(_hint_time, 1.0)
