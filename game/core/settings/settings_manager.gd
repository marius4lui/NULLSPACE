class_name NullSettingsManager
extends Node

signal settings_changed(values: Dictionary)
signal quality_changed(profile: QualityProfile)
signal persistence_notice(result: StorageResult)

const PROFILES: Dictionary = {
	"low": preload("res://data/quality/low.tres"), "medium": preload("res://data/quality/medium.tres"),
	"high": preload("res://data/quality/high.tres"), "ultra": preload("res://data/quality/ultra.tres")
}
const MOBILE_STANDARD: QualityProfile = preload("res://data/quality/mobile_standard.tres")
const MOBILE_BATTERY: QualityProfile = preload("res://data/quality/mobile_battery.tres")
const EFFECT_BUSES: Array[String] = ["Environment", "Player", "Weapons", "Monster", "UI"]

var storage_directory: String = "user://preferences"
var last_result: StorageResult
var _values: Dictionary = SettingsSchema.defaults()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reload_settings()

func snapshot() -> Dictionary:
	return _values.duplicate(true)

func get_value(key: String) -> Variant:
	var value: Variant = _values.get(key)
	return value.duplicate(true) if value is Array or value is Dictionary else value

func current_quality() -> QualityProfile:
	if OS.has_feature("android"):
		return MOBILE_BATTERY if int(_values["fps_limit"]) == 30 else MOBILE_STANDARD
	return PROFILES[_values["quality"]]

func reload_settings() -> StorageResult:
	last_result = _store().read()
	_values = last_result.payload.duplicate(true) if last_result.ok else SettingsSchema.defaults()
	_apply_runtime()
	if not last_result.ok and last_result.code != &"missing" or last_result.recovered:
		persistence_notice.emit(last_result)
	return last_result

func apply_settings(values: Dictionary) -> StorageResult:
	# Persist first. On failure the current runtime and current saved preferences agree.
	last_result = _store().write(values)
	if last_result.ok:
		_values = last_result.payload.duplicate(true)
		_apply_runtime()
	else:
		persistence_notice.emit(last_result)
	return last_result

func _store() -> AtomicJsonStore:
	return AtomicJsonStore.new(storage_directory.path_join("settings.json"), "settings", SettingsSchema.VERSION, SettingsSchema.validate, SettingsSchema.normalize)

func _apply_runtime() -> void:
	if DisplayServer.get_name() != "headless":
		Engine.max_fps = (30 if int(_values["fps_limit"]) == 30 else 60) if OS.has_feature("android") else int(_values["fps_limit"])
		var window: Window = get_window()
		var fullscreen: bool = OS.has_feature("android") or _values["display_mode"] == "fullscreen"
		window.mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
		if not fullscreen:
			var desired: Vector2i = Vector2i(int(_values["resolution"][0]), int(_values["resolution"][1]))
			var usable: Rect2i = DisplayServer.screen_get_usable_rect()
			# Preserve requested resolution, but do not strand the window outside the screen.
			desired = desired.min(usable.size)
			# Window owns the viewport geometry. Bypassing it through DisplayServer
			# resized only the native surface and left the rendered image cropped.
			window.size = desired
			window.position = usable.position + (usable.size - desired) / 2
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if _values["vsync"] else DisplayServer.VSYNC_DISABLED)
	_set_bus("Master", float(_values["master_volume"]))
	_set_bus("Ambience", float(_values["ambience_volume"]))
	# Fluorescent routes through Ambience. Effects buses route directly to Master.
	for bus: String in EFFECT_BUSES:
		_set_bus(bus, float(_values["effects_volume"]))
	if is_inside_tree():
		var viewport: Viewport = get_viewport()
		if viewport is Window:
			# Native fullscreen keeps the desktop mode, with the requested rendering
			# resolution inside it. This also preserves aspect on a clamped window.
			viewport.content_scale_size = Vector2i(int(_values["resolution"][0]), int(_values["resolution"][1]))
			viewport.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
			viewport.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
			if OS.has_feature("android") or OS.get_cmdline_user_args().has("--touch-ui"):
				viewport.content_scale_size = Vector2i(1280, 720)
				viewport.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
				viewport.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		var profile: QualityProfile = current_quality()
		viewport.scaling_3d_scale = profile.render_scale
		viewport.msaa_3d = profile.msaa as Viewport.MSAA
		quality_changed.emit(profile)
	settings_changed.emit(snapshot())

func _set_bus(bus_name: String, volume: float) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, volume <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
