class_name PistolPickup
extends StaticBody3D

signal collected
const MODEL: PackedScene = preload("res://assets/pistol/pistol.glb")
const CASE: PackedScene = preload("res://assets/pistol/pistol_case.glb")
var pistol: SectionPistol
var consumed: bool = false
var _weapon: Node3D

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_child(CASE.instantiate())
	_weapon = MODEL.instantiate() as Node3D
	_weapon.position = Vector3(0, 0.092, 0)
	_weapon.rotation = Vector3(0, 0.8, PI / 2)
	add_child(_weapon)
	for hand: String in ["LeftHand", "RightHand"]:
		(_weapon.find_child(hand, true, false) as Node3D).hide()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.39, 0.21, 0.28)
	collision.shape = shape
	collision.position.y = 0.10
	add_child(collision)
	var label := Label3D.new()
	label.text = "SECURITY  /  C-12"
	label.font_size = 24
	label.pixel_size = 0.00065
	label.position = Vector3(0, 0.033, 0.128)
	label.outline_size = 0
	label.modulate = Color(0.64, 0.64, 0.47)
	add_child(label)

func prompt() -> String:
	return "E  ·  Take pistol — 8 rounds / 12 spare" if not consumed else ""

func use() -> void:
	if consumed or GameFlow.state != NullGameFlow.State.PLAYING:
		return
	if pistol.acquire():
		set_consumed(true)
		collected.emit()

func set_consumed(value: bool) -> void:
	consumed = value
	_weapon.visible = not value
