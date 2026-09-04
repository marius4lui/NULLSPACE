class_name ShotEvent
extends RefCounted
## WeaponController creates this only AFTER ammo/hit resolution succeeds, once per action.

var action_id: String
var generation: int
var weapon_id: StringName
var origin: Vector3
var direction: Vector3
var hits: Array[ShotHit] = []
var monotonic_usec: int
var physics_tick: int

