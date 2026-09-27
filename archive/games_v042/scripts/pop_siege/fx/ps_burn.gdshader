shader_type canvas_item;
// POP SIEGE - burn: the bloon wobbles with rising heat and pulses ember orange.
uniform float burn_t : hint_range(0.0, 1.0) = 0.0; // 0..1 burn life
uniform float seed = 0.0;

vec2 wobble(vec2 uv, float t, float s) {
	return uv + vec2(
		sin(uv.y * 14.0 + t * 9.0 + s) * 0.012,
		cos(uv.x * 12.0 + t * 7.0 + s) * 0.010);
}

void fragment() {
	vec2 uv = wobble(UV, TIME, seed);
	vec4 tex = texture(TEXTURE, uv);
	float pulse = 0.5 + 0.5 * sin(TIME * 12.0 + seed * 7.0);
	vec3 hot = vec3(1.0, 0.45 + 0.25 * pulse, 0.12);
	float glow = burn_t * (0.35 + 0.3 * pulse);
	// rim heat: stronger near the silhouette edge
	float rim = 1.0 - smoothstep(0.28, 0.5, length(UV - vec2(0.5)));
	COLOR = vec4(mix(tex.rgb, hot, clamp(glow * (0.5 + 0.5 * rim), 0.0, 0.8)), tex.a);
}
