shader_type canvas_item;
// POP SIEGE - glue: the goo mask wobbles and drips over the bloon.
uniform float seed = 0.0;
uniform float life : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv) * 2.0;
	float wob = sin(atan(uv.y, uv.x) * 5.0 + TIME * 4.0 + seed) * 0.08;
	float mask = smoothstep(0.95 + wob, 0.55, d);
	float drip = smoothstep(0.2, 0.0, abs(uv.x - sin(TIME * 2.0 + seed) * 0.1)) *
		smoothstep(0.9, 0.2, uv.y + 0.5) * 0.4;
	vec3 goo = vec3(0.55, 0.85, 0.35);
	float a = clamp(mask * life + drip * life, 0.0, 1.0) * 0.85;
	COLOR = vec4(mix(goo, vec3(0.75, 0.95, 0.5), drip), a);
}
