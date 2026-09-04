extends SceneTree
## Ship the exact installed engine's own third-party license inventory.

func _initialize() -> void:
	var target: String = "res://licenses"
	DirAccess.make_dir_recursive_absolute(target)
	var output: FileAccess = FileAccess.open(target.path_join("GODOT_THIRD_PARTY.txt"), FileAccess.WRITE)
	if output == null:
		quit(1)
		return
	output.store_string("Godot " + Engine.get_version_info()["string"] + "\n\n" + Engine.get_license_text() + "\n\n")
	for part: Dictionary in Engine.get_copyright_info():
		output.store_line(JSON.stringify(part, "  "))
	var licenses: Dictionary = Engine.get_license_info()
	for id: String in licenses:
		output.store_string("\n\n" + id + "\n" + str(licenses[id]))
	output.close()
	print("Generated engine notices; current bundled fallback font: ", ThemeDB.fallback_font.get_font_name())
	quit()
