shader_type canvas_item;
// POP SIEGE - the boom: white flash core + double shockwave + gritty noise
// smoke ring. One quad per explosion.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(1.0, 0.85, 0.4, 1.0);

float hash(vec2 v) {
	return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = UV - vec2(0.5);
	float d = length(p) * 2.0;
	float flash = smoothstep(0.5 * (1.0 - progress * 1.4), 0.0, d) * (1.0 - progress) * 1.6;
	float r1 = progress * 1.05;
	float w1 = smoothstep(0.16, 0.0, abs(d - r1));
	float w2 = smoothstep(0.08, 0.0, abs(d - r1 * 0.7)) * 0.6;
	float n = hash(floor(UV * 24.0) + floor(progress * 8.0));
	float smoke = smoothstep(0.35, 0.05, abs(d - r1 * 0.8)) * n * progress * 0.8;
	float a = clamp(flash + w1 + w2 + smoke, 0.0, 1.4) * (1.0 - progress * 0.85);
	vec3 col = mix(tint.rgb, vec3(1.0), clamp(flash, 0.0, 1.0));
	COLOR = vec4(col, clamp(a, 0.0, 1.0));
}
