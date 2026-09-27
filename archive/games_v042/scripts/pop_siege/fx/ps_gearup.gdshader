shader_type canvas_item;
// POP SIEGE - the gear-up pillar: a rising golden beam with rune sparks.
uniform float progress : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 v) {
	return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float rise = 1.0 - progress;                 // the beam sweeps up
	float col = smoothstep(0.32, 0.0, abs(UV.x - 0.5));
	float band = smoothstep(0.08, 0.0, abs(UV.y - rise));
	float body = col * (0.35 + 0.65 * band);
	float sparks = step(0.965, hash(floor(vec2(UV.x * 14.0, UV.y * 40.0) + floor(progress * 10.0)))) * col;
	float a = (body + sparks) * (1.0 - progress * 0.4);
	vec3 gold = vec3(1.0, 0.84, 0.35);
	COLOR = vec4(gold, clamp(a, 0.0, 1.0));
}
