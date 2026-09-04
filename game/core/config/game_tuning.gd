class_name GameTuning
extends Resource
## Numerical hypotheses, not validated gameplay. Runtime owners consume this resource.

@export_group("Player")
@export var walk_speed: float = 3.4
@export var crouch_speed: float = 1.8
@export var sprint_speed: float = 5.4
@export var acceleration: float = 28.0
@export var braking: float = 40.0
@export var max_health: float = 100.0
@export var mouse_radians_per_pixel: float = 0.002
@export_group("Committed ammunition")
@export var pistol_magazine_capacity: int = 12
@export var shotgun_tube_capacity: int = 5
@export var reserve_limit: int = 999
@export var initial_pistol_chamber: int = 1
@export var initial_pistol_magazine: int = 5
@export var initial_pistol_reserve: int = 6
@export_group("Initial checkpoint anchors")
@export var initial_checkpoint: String = "arrival_wake"
@export var initial_room: String = "a_01"
@export var initial_player_anchor: String = "arrival_wake_player"
@export var initial_monster_anchor: String = "arrival_listener_dormant"
@export_group("Evidence sampling")
@export var telemetry_frame_sample_seconds: float = 1.0

