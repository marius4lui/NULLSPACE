class_name ShotHit
extends RefCounted
## Committed hit result, shared by presentation and telemetry; no second damage authority.

var target_id: StringName
var position: Vector3
var normal: Vector3
var surface_id: StringName
var pellet_count: int = 1

