class_name PerceptionObservation
extends RefCounted
## Uncertain evidence, not a source node or a live transform. Aging belongs to memory.

enum Modality { VISION, HEARING }

var evidence_id: String
var listener_id: StringName
var modality: Modality
var region_id: StringName
var incoming_portal_id: StringName
var estimated_position: Vector3
var observed_direction: Vector3
var uncertainty_radius: float
var confidence: float
var observed_at_seconds: float

