class_name EnvironmentSurfaceLibrary
extends RefCounted
## Shared original surface resources. No textures or imported resources are mutated.

const SURFACE_SHADER: Shader = preload("res://environment/environment_surface.gdshader")
const TEXTURE_ROOT: String = "res://assets/environment/textures/"
const SURFACE_KINDS: Dictionary[String, int] = {
	"wallpaper": 0, "carpet": 1, "ceiling": 2, "painted_metal": 3, "baseboard": 4,
}
var _materials: Dictionary[String, Material] = {}
var wall_tint: Color = Color.WHITE
var room_bounds: Vector4 = Vector4(-6.1, 0, 12.2, 14.64)


func get_surface(material_name: String) -> Material:
	if _materials.has(material_name):
		return _materials[material_name]
	if not SURFACE_KINDS.has(material_name):
		return null
	var result := ShaderMaterial.new()
	result.resource_name = "NULLSPACE_" + material_name
	result.shader = SURFACE_SHADER
	for role: String in ["basecolor", "normal", "orm"]:
		result.set_shader_parameter(role + "_map", load(TEXTURE_ROOT + material_name + "_" + role + ".png"))
	result.set_shader_parameter("room_macro_map", load(TEXTURE_ROOT + "room_m4_macro.png"))
	result.set_shader_parameter("surface_kind", SURFACE_KINDS[material_name])
	if material_name == "wallpaper":
		result.set_shader_parameter("tint", Vector3(wall_tint.r, wall_tint.g, wall_tint.b))
	result.set_shader_parameter("room_bounds", room_bounds)
	result.set_shader_parameter("normal_strength", 0.78 if material_name != "carpet" else 0.85)
	_materials[material_name] = result
	return result


func apply_to_tree(root: Node) -> void:
	if root is MeshInstance3D:
		var mesh_instance := root as MeshInstance3D
		if mesh_instance.mesh:
			for surface: int in range(mesh_instance.mesh.get_surface_count()):
				var original: Material = mesh_instance.get_active_material(surface)
				if original:
					var replacement: Material = get_surface(original.resource_name)
					if replacement:
						mesh_instance.set_surface_override_material(surface, replacement)
	for child: Node in root.get_children():
		apply_to_tree(child)


static func make_reference_environment() -> Environment:
	var result := Environment.new()
	result.background_mode = Environment.BG_COLOR
	result.background_color = Color(0.065, 0.071, 0.057)
	result.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	result.ambient_light_color = Color(0.80, 0.83, 0.75)
	result.ambient_light_energy = 0.30
	result.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	result.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	result.tonemap_exposure = 1.0
	result.tonemap_white = 4.0
	result.ssao_enabled = RenderingServer.get_current_rendering_method() == "forward_plus"
	result.ssao_radius = 0.65
	result.ssao_intensity = 1.35
	result.ssao_power = 1.3
	result.ssao_detail = 0.65
	result.ssao_light_affect = 0.22
	result.ssil_enabled = RenderingServer.get_current_rendering_method() == "forward_plus"
	result.ssil_radius = 3.0
	result.ssil_intensity = 0.50
	result.ssil_sharpness = 0.65
	result.glow_enabled = true
	result.glow_intensity = 0.30
	result.glow_strength = 0.75
	result.glow_bloom = 0.0
	result.glow_hdr_threshold = 1.8
	return result
