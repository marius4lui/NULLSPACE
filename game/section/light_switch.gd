class_name SectionLightSwitch
extends StaticBody3D
## One concrete wall switch. Its original clipped-corner mesh is authored here in meters.

signal power_changed(enabled: bool)

var powered: bool = true
var uses: int = 0
var _rocker: MeshInstance3D
var _indicator: StandardMaterial3D

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var plate: MeshInstance3D = _part(Vector3(0.18, 0.28, 0.024), Color(0.41, 0.43, 0.37), 0.014)
	add_child(plate)
	_rocker = _part(Vector3(0.074, 0.12, 0.028), Color(0.22, 0.245, 0.20), 0.009)
	_rocker.position.z = 0.024
	add_child(_rocker)
	var indicator: MeshInstance3D = _part(Vector3(0.027, 0.007, 0.006), Color(0.42, 0.60, 0.27), 0.002)
	indicator.position = Vector3(0.0, 0.095, 0.018)
	_indicator = indicator.material_override as StandardMaterial3D
	_indicator.emission_enabled = true
	_indicator.emission = Color(0.26, 0.42, 0.10)
	add_child(indicator)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.19, 0.29, 0.07)
	shape.shape = box
	shape.position.z = 0.016
	add_child(shape)
	set_powered(true)

func prompt() -> String:
	return "E  ·  Local lights — " + ("switch off" if powered else "switch on")

func use() -> void:
	uses += 1
	set_powered(not powered)
	power_changed.emit(powered)
	Telemetry.record(&"section_switch", {"powered": powered, "uses": uses})

func set_powered(value: bool) -> void:
	powered = value
	if is_instance_valid(_rocker):
		_rocker.rotation.x = -0.15 if value else 0.15
		_indicator.emission_energy_multiplier = 0.7 if value else 0.0

func _part(size: Vector3, color: Color, bevel: float) -> MeshInstance3D:
	var x: float = size.x * 0.5
	var y: float = size.y * 0.5
	var outline: Array[Vector2] = [Vector2(-x + bevel, -y), Vector2(x - bevel, -y),
		Vector2(x, -y + bevel), Vector2(x, y - bevel), Vector2(x - bevel, y),
		Vector2(-x + bevel, y), Vector2(-x, y - bevel), Vector2(-x, -y + bevel)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# The plate is flat, not a rounded blob: do not average normals across its faces.
	surface.set_smooth_group(-1)
	for i: int in range(8):
		var a: Vector2 = outline[i]
		var b: Vector2 = outline[(i + 1) % 8]
		var front_a := Vector3(a.x, a.y, size.z * 0.5)
		var front_b := Vector3(b.x, b.y, size.z * 0.5)
		var back_a := Vector3(a.x, a.y, -size.z * 0.5)
		var back_b := Vector3(b.x, b.y, -size.z * 0.5)
		for vertex: Vector3 in [Vector3(0, 0, size.z * 0.5), front_b, front_a,
			Vector3(0, 0, -size.z * 0.5), back_a, back_b,
			front_a, front_b, back_b, front_a, back_b, back_a]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	var result := MeshInstance3D.new()
	result.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.62
	material.metallic = 0.15
	result.material_override = material
	return result
