class_name SectionFusePickup
extends StaticBody3D
## A single local Nightmare objective item; it deliberately does not create inventory infrastructure.

signal collected

var consumed: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 8
	collision_mask = 0
	var body := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.025
	mesh.bottom_radius = 0.025
	mesh.height = 0.12
	body.mesh = mesh
	body.rotation.z = PI / 2
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(.78, .74, .48)
	material.metallic = .55
	material.roughness = .3
	body.material_override = material
	add_child(body)
	var label := Label3D.new()
	label.text = "C  ·  FUSE"
	label.font_size = 44
	label.pixel_size = .00055
	label.position = Vector3(0, .11, .005)
	label.modulate = Color(.72, .72, .52)
	add_child(label)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(.18, .24, .10)
	collision.shape = shape
	add_child(collision)

func prompt() -> String:
	return "" if consumed else "E  ·  Take marked Emergency C fuse"

func use() -> void:
	if consumed:
		return
	set_consumed(true)
	collected.emit()

func set_consumed(value: bool) -> void:
	consumed = value
	visible = not value
	collision_layer = 0 if value else 8
