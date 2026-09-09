extends SceneTree
## Offline measurements of original skeleton animation; not rendered acceptance.
func _initialize() -> void:
	var model := preload("res://assets/listener/listener_gameplay.glb").instantiate() as Node3D
	root.add_child(model)
	await process_frame
	var animation := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	animation.play(&"death_grab")
	for time: float in [0.0, .32, 1.05, 1.30, 1.46, 2.40]:
		animation.seek(time, true)
		animation.advance(0)
		skeleton.force_update_all_bone_transforms()
		var sample: Dictionary = {"seconds": time}
		for bone: String in ["head", "hand.L", "hand.R", "foot.L", "foot.R"]:
			var point: Vector3 = skeleton.get_bone_global_pose(skeleton.find_bone(bone)).origin
			sample[bone] = [point.x, point.y, point.z]
		print(JSON.stringify(sample))
	quit()
