extends SceneTree
## Offline imported-resource proof, not a native rendering or material review.

func _initialize() -> void:
	var records: Array[Dictionary] = []
	var errors: Array[String] = []
	var total_bytes: int = 0
	var texture_root: String = "res://assets/environment/textures"
	var names: PackedStringArray = DirAccess.get_files_at(texture_root)
	for filename: String in names:
		if not filename.ends_with(".png"):
			continue
		var resource_path: String = texture_root.path_join(filename)
		var texture := ResourceLoader.load(resource_path) as CompressedTexture2D
		if not texture:
			errors.append("Texture did not load: " + resource_path)
			continue
		var imported_image: Image = texture.get_image()
		if not imported_image:
			errors.append("Imported texture has no readable stored image: " + resource_path)
			continue
		var data_bytes: int = imported_image.get_data().size()
		total_bytes += data_bytes
		var format_id: int = imported_image.get_format()
		var normal: bool = filename.ends_with("_normal.png")
		var expected_mips: int = int(log(float(maxi(texture.get_width(), texture.get_height()))) / log(2.0))
		if not imported_image.is_compressed():
			errors.append("Not actually VRAM compressed: " + resource_path)
		if imported_image.get_mipmap_count() != expected_mips:
			errors.append("Incomplete actual mip chain: " + resource_path)
		if normal and format_id != Image.FORMAT_RGTC_RG:
			errors.append("Normal did not use BC5/RGTC_RG: " + resource_path)
		if not normal and format_id not in [Image.FORMAT_BPTC_RGBA, Image.FORMAT_RGTC_RG, Image.FORMAT_RGTC_R]:
			errors.append("Unexpected packed-data/color format: " + resource_path)
		var config := ConfigFile.new()
		var load_error: Error = config.load(resource_path + ".import")
		if load_error != OK:
			errors.append("Cannot read import metadata: " + resource_path)
		var record: Dictionary = {"path": resource_path, "width": texture.get_width(), "height": texture.get_height(),
			"uid": ResourceUID.id_to_text(ResourceLoader.get_resource_uid(resource_path)),
			"format_id": format_id, "compressed": imported_image.is_compressed(), "mipmap_count": imported_image.get_mipmap_count(),
			"expected_mips": expected_mips, "stored_image_bytes": data_bytes,
			"vram_metadata": config.get_value("remap", "metadata", {}),
			"params_normal_map": config.get_value("params", "compress/normal_map"),
			"params_high_quality": config.get_value("params", "compress/high_quality"),
			"normal_plus_y": not config.get_value("params", "process/normal_map_invert_y", false),
			"params_channel_pack": config.get_value("params", "compress/channel_pack")}
		# Stored mip0 is decoded to quantify compression, not rendered as a substitute for native art.
		var decompressed: Image = imported_image.duplicate()
		var decode_error: Error = decompressed.decompress()
		record["decode_error"] = decode_error
		if decode_error != OK:
			errors.append("Cannot decode imported image: " + resource_path)
		else:
			decompressed.clear_mipmaps()
			decompressed.convert(Image.FORMAT_RGB8)
			var original := Image.new()
			var original_error: Error = original.load_png_from_buffer(FileAccess.get_file_as_bytes(resource_path))
			if original_error != OK:
				errors.append("Cannot read original PNG: " + resource_path)
			else:
				original.convert(Image.FORMAT_RGB8)
				var a: PackedByteArray = original.get_data()
				var b: PackedByteArray = decompressed.get_data()
				var channel_error: Array[float] = [0.0, 0.0, 0.0]
				var channel_max: Array[int] = [0, 0, 0]
				var sample_pixels: int = 0
				# Uniform deterministic one-in17 pixel sample, all image rows covered.
				for index: int in range(0, mini(a.size(), b.size()), 51):
					sample_pixels += 1
					for channel: int in range(3):
						var difference: int = absi(int(a[index + channel]) - int(b[index + channel]))
						channel_error[channel] += difference
						channel_max[channel] = maxi(channel_max[channel], difference)
				for channel: int in range(3):
					channel_error[channel] /= maxi(1, sample_pixels)
				record["sample_pixels"] = sample_pixels
				record["sampled_mip0_channel_mae_8bit"] = channel_error
				record["sampled_mip0_channel_max_error_8bit"] = channel_max
				record["note"] = "Normal blue intentionally discarded/reconstructed in Godot normal mapping; RG errors are relevant."
		records.append(record)
	var report: Dictionary = {"schema": 1, "godot": Engine.get_version_info(), "scope": "Actual stored imported resources; no native graphics/performance PASS",
		"textures": records, "total_stored_image_bytes": total_bytes, "errors": errors,
		"result": "IMPORTED_RESOURCES_VERIFIED" if errors.is_empty() else "FAIL"}
	var destination: String = OS.get_environment("NULLSPACE_TEXTURE_IMPORT_REPORT")
	if not destination.is_empty():
		DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
		var file: FileAccess = FileAccess.open(destination, FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t") + "\n")
	print("M4_TEXTURE_IMPORT_VERIFICATION ", JSON.stringify({"result": report.result, "textures": records.size(),
		"stored_image_bytes": total_bytes, "errors": errors, "report": destination}))
	quit(0 if errors.is_empty() else 1)
