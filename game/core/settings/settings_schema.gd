class_name SettingsSchema
extends RefCounted

const VERSION: int = 1
const QUALITY_IDS: Array[String] = ["low", "medium", "high", "ultra"]
const FPS_LIMITS: Array[int] = [0, 30, 60, 90, 120]
const RANGES: Dictionary = {
	"touch_sensitivity": [0.25, 3.0], "touch_size": [0.8, 1.3], "touch_opacity": [0.25, 1.0],
	"master_volume": [0.0, 1.0], "ambience_volume": [0.0, 1.0], "effects_volume": [0.0, 1.0],
	"mouse_sensitivity": [0.05, 5.0], "horizontal_fov": [60.0, 110.0],
	"head_bob": [0.0, 1.0], "camera_shake": [0.0, 1.0]
}
const DEATH_DEFAULTS: Dictionary = {"blood_effects": true, "intense_death": true, "reduced_motion": false}
const BOOLEANS: Array[String] = ["vsync", "invert_y", "subtitles", "center_dot", "reduced_flashes", "blood_effects", "intense_death", "reduced_motion"]

static func defaults() -> Dictionary:
	return {"resolution": [1920, 1080], "display_mode": "windowed", "vsync": true, "fps_limit": 60,
		"touch_sensitivity": 1.0, "touch_size": 1.0, "touch_opacity": 0.65,
		"quality": "low", "master_volume": 0.8, "ambience_volume": 0.8, "effects_volume": 0.8,
		"mouse_sensitivity": 1.0, "invert_y": false, "horizontal_fov": 88.0,
		"head_bob": 0.5, "camera_shake": 0.5, "subtitles": true,
		"center_dot": true, "reduced_flashes": false, "blood_effects": true,
		"intense_death": true, "reduced_motion": false}

static func validate(settings: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	# Additive preference: keep existing valid v1 settings and normalize its absent cap to 60.
	var with_cap: Dictionary = settings.duplicate()
	if not with_cap.has("fps_limit"): with_cap["fps_limit"] = 60
	for key: String in DEATH_DEFAULTS:
		if not with_cap.has(key): with_cap[key] = DEATH_DEFAULTS[key]
	for key: String in ["touch_sensitivity", "touch_size", "touch_opacity"]:
		if not with_cap.has(key): with_cap[key] = defaults()[key]
	if not SnapshotSchema.exact_keys(with_cap, defaults().keys()):
		return PackedStringArray(["Settings are incomplete or contain unsupported fields."])
	if not SnapshotSchema.integer_in(with_cap["fps_limit"], 0, 120) or with_cap["fps_limit"] not in FPS_LIMITS:
		errors.append("Unsupported frame-rate limit.")
	var resolution: Variant = settings["resolution"]
	if not resolution is Array or resolution.size() != 2:
		errors.append("Resolution requires width and height.")
	elif not SnapshotSchema.integer_in(resolution[0], 960, 7680) or not SnapshotSchema.integer_in(resolution[1], 540, 4320):
		errors.append("Resolution must be between 960x540 and 7680x4320.")
	if settings["display_mode"] not in ["windowed", "fullscreen"]:
		errors.append("Unknown display mode.")
	if not settings["quality"] is String or settings["quality"] not in QUALITY_IDS:
		errors.append("Unknown quality preset.")
	for key: String in RANGES:
		if not SnapshotSchema.number_in(with_cap[key], RANGES[key][0], RANGES[key][1]):
			errors.append("%s is outside its supported range." % key)
	for key: String in BOOLEANS:
		if not with_cap[key] is bool:
			errors.append("%s must be on or off." % key)
	return errors

static func vertical_fov(horizontal_degrees: float, aspect_ratio: float) -> float:
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(horizontal_degrees) * 0.5) / maxf(aspect_ratio, 0.1)))

static func normalize(settings: Dictionary) -> Dictionary:
	var result: Dictionary = settings.duplicate(true)
	for key: String in ["touch_sensitivity", "touch_size", "touch_opacity"]:
		if not result.has(key): result[key] = defaults()[key]
	result["fps_limit"] = int(result.get("fps_limit", 60))
	for key: String in DEATH_DEFAULTS:
		if not result.has(key): result[key] = DEATH_DEFAULTS[key]
	result["resolution"] = [int(result["resolution"][0]), int(result["resolution"][1])]
	for field: String in RANGES:
		result[field] = float(result[field])
	return result

static func death_motion_allowed(values: Dictionary) -> bool:
	# Zeroing both existing movement controls also remains a complete motion opt-out.
	return bool(values["intense_death"]) and not bool(values["reduced_motion"]) \
		and (float(values["head_bob"]) > 0 or float(values["camera_shake"]) > 0)
