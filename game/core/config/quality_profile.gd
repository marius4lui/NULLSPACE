class_name QualityProfile
extends Resource
## Consumers must respect these budgets; profile selection alone proves no performance target.

@export var id: StringName = &"high"
@export_range(0.5, 1.0, 0.05) var render_scale: float = 1.0
@export_enum("Disabled", "2x", "4x", "8x") var msaa: int = 1
@export var direct_light_budget: int = 24
@export var shadow_light_budget: int = 4
@export var volumetric_fog: bool = true
@export var ssao: bool = true
@export var particle_budget_scale: float = 1.0

