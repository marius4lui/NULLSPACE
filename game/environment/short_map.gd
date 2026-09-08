class_name ShortMap
extends NullspaceM4ReferenceRoom
## One authored compact building assembled from the original exported room kit.
const MAP_PATH: String = "res://assets/environment/short_map.json"
var layout: Dictionary
var fixture_data: Array[Dictionary] = []
var power: Dictionary = {"office": false, "service": false}
var player: SectionPlayer
var shadow_budget: int = 2
var _light_timer: float = 0
var difficulty_energy: float = 1.0
var difficulty_reaction: float = 1.0

func _ready() -> void:
	layout = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH)) as Dictionary
	for data: Dictionary in layout["rooms"]:
		var model := (load("res://assets/environment/" + data["asset"]) as PackedScene).instantiate() as Node3D
		model.name = data["id"]
		add_child(model)
		var surfaces := EnvironmentSurfaceLibrary.new()
		var bounds: Array = data["bounds"]
		surfaces.room_bounds = Vector4(bounds[0], bounds[3], bounds[1] - bounds[0], bounds[3] - bounds[2])
		if data["style"] in ["service", "blackout"]:
			surfaces.wall_tint = Color(.83, .89, .88)
		surfaces.apply_to_tree(model)
	for data: Dictionary in layout["collision_boxes"]:
		_add_collision(data)
		var dimensions: Array = data["size"]
		if float(dimensions[1]) > 2 and minf(float(dimensions[0]), float(dimensions[2])) < .25:
			var occluder := OccluderInstance3D.new()
			var box := BoxOccluder3D.new()
			box.size = Vector3(dimensions[0], dimensions[1], dimensions[2])
			occluder.occluder = box
			var center: Array = data["center"]
			occluder.position = Vector3(center[0], center[1], center[2])
			add_child(occluder)
	for data: Dictionary in layout["fixtures"]:
		var fixture := NullspaceFluorescentFixture.new()
		add_child(fixture)
		var at: Array = data["position"]
		fixture.position = Vector3(at[0], at[1], at[2])
		fixture.configure(data, surface_library)
		fixtures.append(fixture)
		fixture_data.append(data)
	apply_power(power)
	get_viewport().use_occlusion_culling = true

func apply_power(values: Dictionary) -> void:
	power = values.duplicate()
	for i: int in fixtures.size():
		var data: Dictionary = fixture_data[i]
		var state: String = data["state"]
		if data.has("circuit") and not bool(power[data["circuit"]]):
			state = data["unpowered"]
		fixtures[i].set_fixture_state(NullspaceFluorescentFixture.State[state])
		fixtures[i].set_difficulty_lighting(difficulty_energy, difficulty_reaction)
	_light_timer = 1

func set_difficulty_lighting(energy: float, reaction: float) -> void:
	difficulty_energy = energy
	difficulty_reaction = reaction
	for fixture: NullspaceFluorescentFixture in fixtures:
		fixture.set_difficulty_lighting(energy, reaction)

func room_at(at: Vector3) -> String:
	for data: Dictionary in layout["rooms"]:
		var bounds: Array = data["bounds"]
		if at.x >= bounds[0] and at.x <= bounds[1] and at.z >= bounds[2] and at.z <= bounds[3]:
			return data["id"]
	return "office_core"

func is_dark(at: Vector3) -> bool:
	var id: String = room_at(at)
	return id == "blackout" or (id == "service_switch" and not power["service"])

func light_exposure(at: Vector3) -> float:
	if is_dark(at): return .18
	var exposure: float = .35
	for fixture: NullspaceFluorescentFixture in fixtures:
		if fixture.state == NullspaceFluorescentFixture.State.OFF: continue
		var distance: float = at.distance_to(fixture.global_position - Vector3.UP * 1.5)
		exposure = maxf(exposure, clampf(1.15 - distance / 8.0, .35, 1))
	return exposure

func _process(delta: float) -> void:
	if not is_instance_valid(player): return
	_light_timer += delta
	if _light_timer < .25: return
	_light_timer = 0
	var ordered: Array[NullspaceFluorescentFixture] = fixtures.duplicate()
	ordered.sort_custom(func(a: NullspaceFluorescentFixture, b: NullspaceFluorescentFixture) -> bool:
		return a.global_position.distance_squared_to(player.global_position) < b.global_position.distance_squared_to(player.global_position))
	var shadows: int = 0
	for fixture: NullspaceFluorescentFixture in ordered:
		var near: bool = fixture.global_position.distance_squared_to(player.global_position) < 196
		fixture.set_direct_light_active(near)
		fixture._light.shadow_enabled = near and fixture.state != NullspaceFluorescentFixture.State.OFF and shadows < shadow_budget
		if fixture._light.shadow_enabled: shadows += 1
