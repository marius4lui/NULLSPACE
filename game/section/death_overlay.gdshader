shader_type canvas_item;
uniform float fade : hint_range(0.0, 1.0) = 0.0;
uniform float blood : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	// Original, transparent edge film. The middle 70% remains entirely clear.
	vec2 p = abs(UV - vec2(0.5)) * 2.0;
	float edge = smoothstep(0.72, 1.0, max(p.x, p.y));
	float uneven = 0.62 + 0.22 * sin(UV.x * 51.0 + sin(UV.y * 33.0));
	float red = edge * uneven * blood * 0.32;
	float alpha = fade + red * (1.0 - fade);
	vec3 tint = (vec3(0.008, 0.01, 0.007) * fade + vec3(0.23, 0.008, 0.005) * red * (1.0 - fade)) / max(alpha, 0.0001);
	COLOR = vec4(tint, alpha);
}
