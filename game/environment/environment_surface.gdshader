shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D basecolor_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D orm_map : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D room_macro_map : filter_linear, repeat_disable;
uniform vec3 tint : source_color = vec3(1.0);
uniform float normal_strength : hint_range(0.0, 2.0) = 0.8;
uniform int surface_kind = 0; // 0 paper, 1 carpet, 2 mineral board, 3 painted metal, 4 rubber
uniform vec4 room_bounds = vec4(-6.1, 0.0, 12.2, 14.64);
uniform bool use_room_macro = true;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 orm = texture(orm_map, UV).rgb;
	vec3 base = texture(basecolor_map, UV).rgb;
	vec2 macro_uv = vec2((world_position.x - room_bounds.x) / room_bounds.z,
		1.0 + (world_position.z - room_bounds.y) / room_bounds.w);
	vec3 macro = use_room_macro ? texture(room_macro_map, macro_uv).rgb : vec3(0.0, 0.0, 0.5);
	float inside_room = step(0.0, macro_uv.x) * step(macro_uv.x, 1.0)
		* step(0.0, macro_uv.y) * step(macro_uv.y, 1.0);
	macro.rg *= inside_room;
	ALBEDO = base * tint * COLOR.rgb;
	ROUGHNESS = orm.g;
	METALLIC = orm.b;
	AO = orm.r;
	NORMAL_MAP = texture(normal_map, UV).rgb;
	NORMAL_MAP_DEPTH = normal_strength;
	SPECULAR = 0.36;
	if (surface_kind == 0) {
		float lower_age = exp(-max(world_position.y, 0.0) * 5.0) * 0.045;
		ALBEDO *= 1.0 - lower_age + (macro.b - 0.5) * 0.05;
	} else if (surface_kind == 1) {
		ALBEDO *= 1.0 - macro.r * 0.24 - macro.g * 0.055 + (macro.b - 0.5) * 0.16;
		ROUGHNESS = clamp(orm.g - macro.r * 0.20 - macro.g * 0.025, 0.66, 1.0);
		NORMAL_MAP_DEPTH *= 1.0 - macro.r * 0.36 - macro.g * 0.17;
		SPECULAR = 0.24 + macro.r * 0.12;
	} else if (surface_kind == 2) {
		float leak = smoothstep(0.48, 0.96, macro.r);
		ALBEDO *= mix(vec3(1.0), vec3(0.89, 0.845, 0.75), leak * 0.58);
		ALBEDO *= 1.0 + (macro.b - 0.5) * 0.08;
	}
}
