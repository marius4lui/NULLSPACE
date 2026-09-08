class_name DifficultyConfig
extends RefCounted
## Four fixed Room 1 variants. This is intentionally not a general difficulty framework.

const DEFAULT_ID: String = "medium"
const IDS: Array[String] = ["easy", "medium", "hard", "nightmare"]
const PROFILES: Dictionary = {
	"easy": {
		"title": "Easy", "monster_speed": 0.75, "awareness": 0.82,
		"fixture_energy": 1.18, "light_reaction": 0.35,
		"ambient_lit": 0.34, "ambient_dark": 0.045, "atmosphere": 0.72,
		"required_switches": ["office"], "extra_step": "none",
		"summary": "One switch · brighter rooms · generous Listener pace",
	},
	"medium": {
		"title": "Medium", "monster_speed": 1.0, "awareness": 1.0,
		"fixture_energy": 1.0, "light_reaction": 1.0,
		"ambient_lit": 0.25, "ambient_dark": 0.018, "atmosphere": 1.0,
		"required_switches": ["office", "service"], "extra_step": "none",
		"summary": "Two separated switches · intended baseline",
	},
	"hard": {
		"title": "Hard", "monster_speed": 1.15, "awareness": 1.08,
		"fixture_energy": 0.82, "light_reaction": 1.35,
		"ambient_lit": 0.18, "ambient_dark": 0.012, "atmosphere": 1.18,
		"required_switches": ["office", "service", "emergency"], "extra_step": "latch",
		"summary": "Three switches · release Emergency C safety latch",
	},
	"nightmare": {
		"title": "Nightmare", "monster_speed": 1.28, "awareness": 1.12,
		"fixture_energy": 0.68, "light_reaction": 1.60,
		"ambient_lit": 0.13, "ambient_dark": 0.009, "atmosphere": 1.32,
		"required_switches": ["office", "service", "emergency"], "extra_step": "fuse",
		"summary": "Three switches · carry the marked fuse to Emergency C",
	},
}

static func sanitize(id: String) -> String:
	return id if id in IDS else DEFAULT_ID

static func profile(id: String) -> Dictionary:
	return PROFILES[sanitize(id)].duplicate(true)

static func title(id: String) -> String:
	return str(PROFILES[sanitize(id)]["title"])

static func write_to_snapshot(snapshot: Dictionary, id: String) -> void:
	var selected := sanitize(id)
	var circuits: Dictionary = snapshot["world"]["circuits"]
	for candidate: String in IDS:
		circuits["difficulty_" + candidate] = candidate == selected

static func from_snapshot(snapshot: Dictionary) -> String:
	var circuits: Dictionary = snapshot.get("world", {}).get("circuits", {})
	var selected: String = ""
	for candidate: String in IDS:
		if circuits.get("difficulty_" + candidate, false) == true:
			if not selected.is_empty():
				return DEFAULT_ID
			selected = candidate
	return DEFAULT_ID if selected.is_empty() else selected
