class_name SoundEvent
extends RefCounted
## Raw truth is delivered only to registered propagation and audio adapters.
## This object must never be retained by perception, memory, planner or director.

var event_id: String
var source_id: StringName
var room_id: StringName
var kind: StringName
var position: Vector3
var intensity: float
var monotonic_usec: int
var simulation_seconds: float

