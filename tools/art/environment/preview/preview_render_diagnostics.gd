extends RefCounted
## Reversible controls for the isolated art viewer. Never a production quality preset.

const SCALES: Array[float] = [1.0, 0.75, 0.5]
var _room: NullspaceM4ReferenceRoom
var _environment: Environment
var _viewport: Viewport
var _original_shadows: Array[bool] = []
var _architecture_meshes: Array[MeshInstance3D] = []
var _original_overrides: Array[Material] = []
var _simple_material: StandardMaterial3D
var _simple_surfaces: bool = false
var _direct_enabled: bool = true
var _shadows_enabled: bool = true
var _scale_index: int = 0
var _probe_counts: Dictionary = {"reflection_probe": 0, "voxel_gi": 0, "lightmap_gi": 0}


func _init(room: NullspaceM4ReferenceRoom, environment: Environment, viewport: Viewport) -> void:
	_room = room
	_environment = environment
	_viewport = viewport
	for fixture: NullspaceFluorescentFixture in room.fixtures:
		_original_shadows.append((fixture.get_node("FluorescentDirect") as OmniLight3D).shadow_enabled)
	_collect_architecture(room.get_node("AuthoredArchitecture"))
	_count_probes(room)
	_simple_material = StandardMaterial3D.new()
	_simple_material.resource_name = "DIAGNOSTIC_ONLY_UniformRoughArchitecture"
	_simple_material.albedo_color = Color(0.63, 0.59, 0.46)
	_simple_material.roughness = 0.88


func _collect_architecture(node: Node) -> void:
	if node is MeshInstance3D:
		_architecture_meshes.append(node as MeshInstance3D)
		_original_overrides.append((node as MeshInstance3D).material_override)
	for child: Node in node.get_children():
		_collect_architecture(child)


func _count_probes(node: Node) -> void:
	if node is ReflectionProbe:
		_probe_counts["reflection_probe"] += 1
	elif node is VoxelGI:
		_probe_counts["voxel_gi"] += 1
	elif node is LightmapGI:
		_probe_counts["lightmap_gi"] += 1
	for child: Node in node.get_children():
		_count_probes(child)


func handle_key(key: int) -> bool:
	match key:
		KEY_F2:
			_viewport.msaa_3d = Viewport.MSAA_DISABLED if _viewport.msaa_3d != Viewport.MSAA_DISABLED else Viewport.MSAA_2X
		KEY_F3:
			_scale_index = (_scale_index + 1) % SCALES.size()
			_viewport.scaling_3d_scale = SCALES[_scale_index]
		KEY_F4:
			_simple_surfaces = not _simple_surfaces
			for index: int in _architecture_meshes.size():
				_architecture_meshes[index].material_override = _simple_material if _simple_surfaces else _original_overrides[index]
		KEY_F5:
			_direct_enabled = not _direct_enabled
			for fixture: NullspaceFluorescentFixture in _room.fixtures:
				fixture.set_direct_light_active(_direct_enabled)
		KEY_F6:
			_environment.glow_enabled = not _environment.glow_enabled
		KEY_F7:
			_environment.ssil_enabled = not _environment.ssil_enabled
		KEY_F8:
			_environment.ssao_enabled = not _environment.ssao_enabled
		KEY_F9:
			_shadows_enabled = not _shadows_enabled
			for index: int in _room.fixtures.size():
				var light := _room.fixtures[index].get_node("FluorescentDirect") as OmniLight3D
				light.shadow_enabled = _shadows_enabled and _original_shadows[index]
		KEY_F10:
			_viewport.use_taa = not _viewport.use_taa
		_:
			return false
	return true


func state() -> Dictionary:
	var shadows: int = 0
	var direct: int = 0
	var states: Array[Dictionary] = []
	for fixture: NullspaceFluorescentFixture in _room.fixtures:
		var light := fixture.get_node("FluorescentDirect") as OmniLight3D
		shadows += int(light.shadow_enabled)
		direct += int(light.visible)
		states.append({"id": fixture.fixture_id, "state": fixture.state,
			"direct_light_enabled": fixture.direct_light_enabled, "visible": light.visible})
	return {"ssao": _environment.ssao_enabled, "ssil": _environment.ssil_enabled,
		"shadowed_fixtures": shadows, "visible_direct_fixtures": direct,
		"taa": _viewport.use_taa, "msaa_3d": _viewport.msaa_3d,
		"scale_3d": _viewport.scaling_3d_scale, "scale_3d_mode": _viewport.scaling_3d_mode,
		"glow": _environment.glow_enabled, "fog": _environment.fog_enabled,
		"volumetric_fog": _environment.volumetric_fog_enabled, "sdfgi": _environment.sdfgi_enabled,
		"ssr": _environment.ssr_enabled, "room_probe_counts": _probe_counts.duplicate(),
		"ssao_quality_project": ProjectSettings.get_setting("rendering/environment/ssao/quality"),
		"ssil_quality_project": ProjectSettings.get_setting("rendering/environment/ssil/quality"),
		"anisotropic_filtering_project": ProjectSettings.get_setting("rendering/textures/default_filters/anisotropic_filtering_level"),
		"simple_architecture_material": _simple_surfaces,
		"material_diagnostic_scope": "Architecture geometry unchanged; uniform StandardMaterial replaces surface shaders. Batching may change: compare draw calls too.",
		"fixture_states": states}
