class_name NullspaceM4ReferenceRoom
extends Node3D
## Reusable art reference composition. Campaign graph, interactions and audio have other owners.

const ROOM_MODEL: PackedScene = preload("res://assets/environment/room_m4_architecture.gltf")
const MANIFEST_PATH: String = "res://assets/environment/environment_manifest.json"

var fixtures: Array[NullspaceFluorescentFixture] = []
var surface_library := EnvironmentSurfaceLibrary.new()


func _ready() -> void:
	var model := ROOM_MODEL.instantiate() as Node3D
	model.name = "AuthoredArchitecture"
	add_child(model)
	surface_library.apply_to_tree(model)
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH)) as Dictionary
	for data: Dictionary in manifest.get("collision_boxes", []):
		_add_collision(data)
	for data: Dictionary in manifest.get("fixtures", []):
		var fixture := NullspaceFluorescentFixture.new()
		add_child(fixture)
		var coordinates: Array = data["position"]
		fixture.position = Vector3(float(coordinates[0]), float(coordinates[1]), float(coordinates[2]))
		fixture.configure(data, surface_library)
		fixtures.append(fixture)


func _add_collision(data: Dictionary) -> void:
	var body := StaticBody3D.new()
	body.name = "Collision_" + str(data["name"])
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var dimensions: Array = data["size"]
	box.size = Vector3(float(dimensions[0]), float(dimensions[1]), float(dimensions[2]))
	shape.shape = box
	var center: Array = data["center"]
	body.position = Vector3(float(center[0]), float(center[1]), float(center[2]))
	body.add_child(shape)
	add_child(body)
