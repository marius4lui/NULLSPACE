class_name DifficultyRelay
extends PowerRelay
## Room 1's single higher-difficulty relay, with one concrete prerequisite.

signal prerequisite_changed

var access_mode: String = "latch"
var latch_released: bool = false
var fuse_inserted: bool = false
var has_fuse: Callable
var consume_fuse: Callable

func prompt() -> String:
	if powered:
		return title + "  ·  Power restored"
	if access_mode == "latch" and not latch_released:
		return "E  ·  Release Emergency C safety latch"
	if access_mode == "fuse" and not fuse_inserted:
		return "E  ·  Insert marked fuse" if has_fuse.is_valid() and has_fuse.call() else "Emergency C  ·  Marked fuse required"
	return super.prompt()

func use() -> void:
	if powered:
		return
	if access_mode == "latch" and not latch_released:
		latch_released = true
		audio.play()
		prerequisite_changed.emit()
		return
	if access_mode == "fuse" and not fuse_inserted:
		if not has_fuse.is_valid() or not has_fuse.call():
			return
		if consume_fuse.is_valid():
			consume_fuse.call()
		fuse_inserted = true
		audio.play()
		prerequisite_changed.emit()
		return
	super.use()

func restore_difficulty(power_value: bool, prerequisite: bool) -> void:
	latch_released = prerequisite if access_mode == "latch" else false
	fuse_inserted = prerequisite if access_mode == "fuse" else false
	super.restore(power_value)
