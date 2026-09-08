class_name SnapshotSchema
extends RefCounted
## Only committed semantic state. Scene transforms and in-flight actions are excluded.

const VERSION: int = 2
const CAMPAIGN_ID: String = "nullspace_short_v1"
const TUNING: GameTuning = preload("res://data/default_tuning.tres")
const RELAYS: Array[String] = ["office", "service"]

static func initial_snapshot() -> Dictionary:
	return {
		"campaign_id": CAMPAIGN_ID,
		"session": {"id": Crypto.new().generate_random_bytes(16).hex_encode(), "elapsed_seconds": 0.0},
		"checkpoint": {"id": TUNING.initial_checkpoint, "room_id": TUNING.initial_room,
			"player_anchor": TUNING.initial_player_anchor, "monster_anchor": TUNING.initial_monster_anchor,
			"reset_seed": 1},
		"player": {"health": TUNING.max_health, "stamina": 1.0,
			"flashlight_enabled": false, "equipped_weapon": ""},
		"inventory": {"weapons": {
			"pistol": {"owned": false, "chamber": 0, "magazine": 0, "reserve": 0}}},
		"progress": {"relays": {"office": false, "service": false}, "ending": false},
		"world": {"doors": {}, "circuits": {}, "consumed_pickups": []}
	}

static func validate(snapshot: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if not exact_keys(snapshot, ["campaign_id", "session", "checkpoint", "player", "inventory", "progress", "world"]):
		return PackedStringArray(["Snapshot is incomplete or has unsupported sections."])
	if not snapshot["campaign_id"] is String or snapshot["campaign_id"] != CAMPAIGN_ID:
		errors.append("Checkpoint belongs to another campaign.")
	for section: String in ["session", "checkpoint", "player", "inventory", "progress", "world"]:
		if not snapshot[section] is Dictionary:
			return PackedStringArray(["Snapshot section %s must be an object." % section])
	var session: Dictionary = snapshot["session"]
	if not exact_keys(session, ["id", "elapsed_seconds"]) or not stable_id(session.get("id")) or not number_in(session.get("elapsed_seconds"), 0.0, 1e8):
		errors.append("Invalid session identity or elapsed time.")
	var checkpoint: Dictionary = snapshot["checkpoint"]
	if not exact_keys(checkpoint, ["id", "room_id", "player_anchor", "monster_anchor", "reset_seed"]):
		errors.append("Checkpoint anchors are incomplete.")
	for field: String in ["id", "room_id", "player_anchor", "monster_anchor"]:
		if not stable_id(checkpoint.get(field)):
			errors.append("Invalid checkpoint %s." % field)
	if checkpoint.get("player_anchor") is String and checkpoint.get("monster_anchor") is String and checkpoint["player_anchor"] == checkpoint["monster_anchor"]:
		errors.append("Player and Listener require separate checkpoint anchors.")
	if not integer_in(checkpoint.get("reset_seed"), 0, 2147483647):
		errors.append("Invalid checkpoint seed.")
	var player: Dictionary = snapshot["player"]
	if not exact_keys(player, ["health", "stamina", "flashlight_enabled", "equipped_weapon"]):
		errors.append("Player state is incomplete.")
	if not number_in(player.get("health"), 0.001, TUNING.max_health) or not number_in(player.get("stamina"), 0.0, 1.0):
		errors.append("Checkpoint must restore living player health and valid stamina.")
	if not player.get("flashlight_enabled") is bool or player.get("equipped_weapon") not in ["", "pistol"]:
		errors.append("Invalid player equipment state.")
	_validate_inventory(snapshot["inventory"], player, errors)
	_validate_progress(snapshot["progress"], snapshot["world"], errors)
	_validate_world(snapshot["world"], errors)
	return errors

static func normalize(snapshot: Dictionary) -> Dictionary:
	# JSON reads numeric values as floats. Public runtime snapshots retain explicit types.
	var result: Dictionary = snapshot.duplicate(true)
	result["session"]["elapsed_seconds"] = float(result["session"]["elapsed_seconds"])
	result["checkpoint"]["reset_seed"] = int(result["checkpoint"]["reset_seed"])
	result["player"]["health"] = float(result["player"]["health"])
	result["player"]["stamina"] = float(result["player"]["stamina"])
	for id: String in ["pistol"]:
		for field: String in ["chamber", "magazine", "reserve"]:
			result["inventory"]["weapons"][id][field] = int(result["inventory"]["weapons"][id][field])
	return result

static func _validate_inventory(inventory: Dictionary, player: Dictionary, errors: PackedStringArray) -> void:
	if not exact_keys(inventory, ["weapons"]) or not inventory.get("weapons") is Dictionary:
		errors.append("Inventory is incomplete.")
		return
	var weapons: Dictionary = inventory["weapons"]
	if not exact_keys(weapons, ["pistol"]):
		errors.append("Weapon inventory is incomplete.")
		return
	for id: String in ["pistol"]:
		if not weapons[id] is Dictionary:
			errors.append("Invalid %s state." % id)
			continue
		var weapon: Dictionary = weapons[id]
		var capacity: int = TUNING.pistol_magazine_capacity
		if not exact_keys(weapon, ["owned", "chamber", "magazine", "reserve"]) or not weapon.get("owned") is bool:
			errors.append("Incomplete %s state." % id)
			continue
		if not integer_in(weapon.get("chamber"), 0, 1) or not integer_in(weapon.get("magazine"), 0, capacity) or not integer_in(weapon.get("reserve"), 0, TUNING.reserve_limit):
			errors.append("Invalid %s ammunition." % id)
		elif not weapon["owned"] and (weapon["chamber"] != 0 or weapon["magazine"] != 0):
			errors.append("Unowned %s cannot contain loaded ammunition." % id)
		if player.get("equipped_weapon") is String and player["equipped_weapon"] == id and not weapon["owned"]:
			errors.append("Cannot equip an unowned weapon.")

static func _validate_progress(progress: Dictionary, world: Dictionary, errors: PackedStringArray) -> void:
	if not exact_keys(progress, ["relays", "ending"]) or not progress.get("relays") is Dictionary:
		errors.append("Progress is incomplete.")
		return
	var relays: Dictionary = progress["relays"]
	if not exact_keys(relays, RELAYS):
		errors.append("Relay progress is incomplete.")
		return
	for id: String in RELAYS:
		if not relays[id] is bool:
			errors.append("Relay state must be committed boolean values.")
			return
	for flag: String in ["ending"]:
		if not progress[flag] is bool:
			errors.append("Progress flags must be boolean values.")
			return
	if progress["ending"] == true:
		var circuits: Dictionary = world["circuits"] if world.get("circuits") is Dictionary else {}
		var difficulty_id := DifficultyConfig.from_snapshot({"world": {"circuits": circuits}})
		for id: String in DifficultyConfig.profile(difficulty_id)["required_switches"]:
			var powered: bool = bool(relays.get(id, false)) if id in RELAYS else bool(circuits.get("emergency_powered", false))
			if not powered:
				errors.append("Escape requires every %s power switch." % difficulty_id)
				break

static func _validate_world(world: Dictionary, errors: PackedStringArray) -> void:
	if not exact_keys(world, ["doors", "circuits", "consumed_pickups"]):
		errors.append("World state is incomplete.")
		return
	for category: String in ["doors", "circuits"]:
		if not world[category] is Dictionary or world[category].size() > 4096:
			errors.append("Invalid world %s map." % category)
			continue
		var entries: Dictionary = world[category]
		for id: Variant in entries:
			if not stable_id(id):
				errors.append("Invalid persistent world identity.")
			if category == "doors":
				if entries[id] not in ["open", "closed", "locked"]:
					errors.append("Only stable door states may be saved.")
			elif not entries[id] is bool:
				errors.append("Circuits require committed boolean states.")
	if not world["consumed_pickups"] is Array or world["consumed_pickups"].size() > 4096:
		errors.append("Invalid consumed pickup list.")
		return
	var seen: Dictionary = {}
	for id: Variant in world["consumed_pickups"]:
		if not stable_id(id) or seen.has(id):
			errors.append("Pickup IDs must be valid and unique.")
			continue
		seen[id] = true

static func exact_keys(value: Dictionary, keys: Array) -> bool:
	return value.size() == keys.size() and keys.all(func(key: Variant) -> bool: return value.has(key))

static func number_in(value: Variant, minimum: float, maximum: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= minimum and float(value) <= maximum

static func integer_in(value: Variant, minimum: int, maximum: int) -> bool:
	return number_in(value, minimum, maximum) and float(value) == floor(float(value))

static func stable_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 96:
		return false
	for character: String in value:
		if not character in "abcdefghijklmnopqrstuvwxyz0123456789_-":
			return false
	return true
