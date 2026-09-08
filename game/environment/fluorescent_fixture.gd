class_name NullspaceFluorescentFixture
extends Node3D
## Physical original fixture wrapper. Circuit owner controls state and active light budget.
## Ballast audio belongs to the audio system and is intentionally not implemented here.

enum State { NORMAL, WEAK, INTERMITTENT, FAILING, OFF }

const ASSET_ROOT: String = "res://assets/environment/"
const NOMINAL_ENERGY: float = 2.0
const LIGHT_RANGE: float = 4.0
const LIGHT_ATTENUATION: float = 1.45
const EMISSION_ENERGY: float = 2.0

var fixture_id: String = ""
var state: State = State.NORMAL
var reduce_flashes: bool = false
var direct_light_enabled: bool = true
var _light: OmniLight3D
var _emissive: Array[StandardMaterial3D] = []
var _elapsed: float = 0.0
var _phase: float = 0.0
var _warmth: float = 0.0
var _intensity: float = -1.0
var difficulty_energy: float = 1.0
var difficulty_reaction: float = 1.0


func configure(data: Dictionary, surface_library: EnvironmentSurfaceLibrary) -> void:
	fixture_id = str(data.get("id", "fixture"))
	name = fixture_id
	_warmth = float(data.get("warmth", 0.02))
	_phase = float(abs(fixture_id.hash()) % 1709) / 100.0
	state = State.get(str(data.get("state", "NORMAL")), State.NORMAL)
	var packed := load(ASSET_ROOT + str(data.get("variant", "fixture_prismatic")) + ".gltf") as PackedScene
	var model := packed.instantiate() as Node3D
	add_child(model)
	surface_library.apply_to_tree(model)
	_collect_emissive(model)
	_light = OmniLight3D.new()
	_light.name = "FluorescentDirect"
	_light.position.y = -0.11
	_light.light_color = Color(1.0, 0.975 - _warmth * 0.3, 0.86 - _warmth)
	_light.omni_range = LIGHT_RANGE
	_light.omni_attenuation = LIGHT_ATTENUATION
	_light.light_size = 0.18
	_light.light_specular = 0.48
	_light.shadow_enabled = bool(data.get("shadow", false))
	_light.shadow_bias = 0.035
	_light.shadow_normal_bias = 0.12
	add_child(_light)
	_update_output(1.0)
	set_process(state == State.INTERMITTENT or state == State.FAILING)


func _collect_emissive(root: Node) -> void:
	if root is MeshInstance3D:
		var mesh_instance := root as MeshInstance3D
		for surface: int in range(mesh_instance.mesh.get_surface_count()):
			var original: Material = mesh_instance.get_active_material(surface)
			if original is StandardMaterial3D and original.resource_name in ["diffuser", "lamp_phosphor", "fixture_detail"]:
				var emissive := original.duplicate() as StandardMaterial3D
				emissive.emission_enabled = true
				emissive.emission = Color(1.0, 0.966 - _warmth * 0.1, 0.835 - _warmth)
				emissive.emission_energy_multiplier = EMISSION_ENERGY
				mesh_instance.set_surface_override_material(surface, emissive)
				_emissive.append(emissive)
	for child: Node in root.get_children():
		_collect_emissive(child)


func set_fixture_state(value: State) -> void:
	state = value
	_intensity = -1.0
	_update_output(1.0)
	set_process(state == State.INTERMITTENT or state == State.FAILING)


func set_direct_light_active(value: bool) -> void:
	direct_light_enabled = value
	if _light:
		_light.visible = value and state != State.OFF


func set_difficulty_lighting(energy: float, reaction: float) -> void:
	difficulty_energy = clampf(energy, .5, 1.25)
	difficulty_reaction = clampf(reaction, .25, 1.75)
	_intensity = -1.0
	_update_output(1.0)


func _process(delta: float) -> void:
	_elapsed += delta
	var modulation: float = 1.0
	if not reduce_flashes:
		var cycle: float = fmod(_elapsed + _phase, 19.7)
		if state == State.INTERMITTENT and cycle > 17.6 and cycle < 18.35:
			modulation = 1.0 - (0.21 - 0.08 * sin(cycle * 21.0) * sin(cycle * 13.0)) * difficulty_reaction
		elif state == State.FAILING:
			modulation = 1.0 - (0.17 - 0.04 * sin((_elapsed + _phase) * 5.7)) * difficulty_reaction
	_update_output(modulation)


func _update_output(modulation: float) -> void:
	if not _light:
		return
	var base: float = 1.0
	match state:
		State.WEAK: base = 0.44
		State.FAILING: base = 0.30
		State.OFF: base = 0.0
	var output: float = maxf(0.0, base * modulation * difficulty_energy)
	if is_equal_approx(output, _intensity):
		return
	_intensity = output
	_light.light_energy = NOMINAL_ENERGY * output
	_light.visible = direct_light_enabled and output > 0.0
	for emissive: StandardMaterial3D in _emissive:
		emissive.emission_energy_multiplier = EMISSION_ENERGY * output
