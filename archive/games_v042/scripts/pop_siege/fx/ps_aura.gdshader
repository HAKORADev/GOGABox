shader_type canvas_item;
// POP SIEGE - the eternal flame / storm aura ring: scrolling noise fire band.
uniform float progress : hint_range(0.0, 1.0) = 0.0; // 1 = full strength
uniform vec4 tint : source_color = vec4(1.0, 0.55, 0.15, 1.0);
uniform float speed = 2.0;

float hash(vec2 v) {
	return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = UV - vec2(0.5);
	float d = length(p) * 2.0;
	float ang = atan(p.y, p.x);
	float flick = hash(vec2(floor(ang * 10.0), floor(TIME * 8.0)));
	float band = smoothstep(0.16 + 0.06 * flick, 0.02, abs(d - 0.82));
	float breath = 0.75 + 0.25 * sin(TIME * speed * 3.0 + ang * 4.0);
	float a = band * breath * progress;
	vec3 col = mix(tint.rgb, vec3(1.0, 0.9, 0.5), flick * 0.5);
	COLOR = vec4(col, clamp(a, 0.0, 1.0) * 0.9);
}
