class_name PistolEffects
extends Node3D
## Small bounded shot presentation in the actual world. No second hit/damage authority.

const CASING: PackedScene = preload("res://assets/pistol/pistol_casing.glb")
const CASING_SOUND: AudioStream = preload("res://assets/audio/pistol/casing.wav")
const PLASTER: AudioStream = preload("res://assets/audio/pistol/plaster.wav")
const METAL: AudioStream = preload("res://assets/audio/pistol/metal.wav")
var _marks: Array[Node3D] = []
var _casings: Array[RigidBody3D] = []
var _sequence: int = 0

func impact(point: Vector3, normal: Vector3, metal: bool = false) -> void:
	_sequence += 1
	var mark := MeshInstance3D.new()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var radius: float = 0.008 if normal.dot(Vector3.UP) > 0.6 else 0.019
	for i: int in 11:
		for corner: int in 3:
			var angle: float = float(i + (1 if corner == 2 else 0)) * TAU / 11.0
			var size: float = radius * (0.85 + 0.15 * sin(float(i * 7 + _sequence))) if corner > 0 else 0.0
			surface.set_color(Color(0.025, 0.025, 0.020) if corner == 0 else Color(0.23, 0.22, 0.16))
			surface.add_vertex(Vector3(cos(angle) * size, sin(angle) * size, 0))
	surface.generate_normals()
	mark.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mark.material_override = material
	add_child(mark)
	mark.global_position = point + normal * 0.002
	mark.global_basis = Basis.looking_at(-normal, Vector3.RIGHT if absf(normal.y) > 0.9 else Vector3.UP)
	_marks.append(mark)
	if _marks.size() > 32:
		_marks.pop_front().queue_free()
	var dust := CPUParticles3D.new()
	dust.amount = 9 if not metal else 5
	dust.lifetime = 0.45
	dust.one_shot = true
	dust.explosiveness = 1.0
	dust.direction = normal
	dust.spread = 42.0
	dust.initial_velocity_min = 0.4
	dust.initial_velocity_max = 1.9
	dust.gravity = Vector3(0, -2.0, 0)
	dust.scale_amount_min = 0.005
	dust.scale_amount_max = 0.019
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE
	var dust_mat := StandardMaterial3D.new()
	dust_mat.albedo_color = Color(0.63, 0.56, 0.40, 0.38) if not metal else Color(1.0, 0.73, 0.35, 0.9)
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material = dust_mat
	dust.mesh = mesh
	add_child(dust)
	dust.global_position = point + normal * 0.02
	dust.finished.connect(dust.queue_free)
	dust.emitting = true
	play_world(METAL if metal else PLASTER, point, -8.0)

func eject(at: Transform3D, velocity: Vector3) -> void:
	var shell := RigidBody3D.new()
	shell.mass = 0.012
	shell.collision_layer = 0
	shell.collision_mask = 1
	shell.continuous_cd = true
	shell.contact_monitor = true
	shell.max_contacts_reported = 1
	shell.physics_material_override = PhysicsMaterial.new()
	shell.physics_material_override.bounce = 0.22
	shell.physics_material_override.friction = 0.8
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.005
	shape.height = 0.02
	collision.shape = shape
	shell.add_child(collision)
	shell.add_child(CASING.instantiate())
	add_child(shell)
	shell.global_transform = at
	shell.linear_velocity = velocity
	shell.angular_velocity = Vector3(15, 9, 21)
	shell.body_entered.connect(func(_body: Node) -> void:
		play_world(CASING_SOUND, shell.global_position, -13.0), CONNECT_ONE_SHOT)
	_casings.append(shell)
	if _casings.size() > 18:
		_casings.pop_front().queue_free()
	var tween := shell.create_tween()
	tween.tween_interval(4.0)
	tween.tween_callback(func() -> void: shell.freeze = true)

func play_world(stream: AudioStream, at: Vector3, volume: float) -> void:
	var voice := AudioStreamPlayer3D.new()
	voice.stream = stream
	voice.bus = &"Weapons"
	voice.volume_db = volume
	voice.max_distance = 24.0
	voice.unit_size = 2.0
	add_child(voice)
	voice.global_position = at
	voice.finished.connect(voice.queue_free)
	voice.play()

func clear() -> void:
	for child: Node in get_children():
		if child is AudioStreamPlayer3D:
			child.stop()
		child.queue_free()
	_marks.clear()
	_casings.clear()
