shader_type canvas_item;
// POP SIEGE - water/lava cell shimmer: layered sine caustics + edge foam.
uniform float is_lava = 0.0;
uniform vec4 base_a : source_color = vec4(0.20, 0.45, 0.75, 1.0);
uniform vec4 base_b : source_color = vec4(0.28, 0.60, 0.88, 1.0);

void fragment() {
	vec2 uv = UV;
	float c1 = sin(uv.x * 9.0 + TIME * 1.7) * cos(uv.y * 7.0 - TIME * 1.3);
	float c2 = sin((uv.x + uv.y) * 13.0 - TIME * 2.2);
	float m = 0.5 + 0.25 * c1 + 0.25 * c2;
	vec3 col = mix(base_a.rgb, base_b.rgb, m);
	if (is_lava > 0.5) {
		col = mix(vec3(0.45, 0.12, 0.08), vec3(1.0, 0.55, 0.15), pow(m, 2.0));
	}
	// edge foam line
	float ex = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float edge = smoothstep(0.06, 0.02, ex) * (0.5 + 0.3 * sin(TIME * 3.0 + uv.x * 20.0));
	if (is_lava > 0.5) {
		COLOR = vec4(col + vec3(0.3, 0.1, 0.0) * edge, 1.0);
	} else {
		COLOR = vec4(col + vec3(0.35, 0.4, 0.45) * edge, 1.0);
	}
}
