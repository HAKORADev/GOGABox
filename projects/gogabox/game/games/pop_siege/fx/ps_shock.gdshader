shader_type canvas_item;
// POP SIEGE - the pop shockwave: an expanding soft ring with a hot core lip
// and a fading sparkle band. Pooled; one instance per pop.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(1.0);

float ring(float d, float r, float w) {
	return smoothstep(w, 0.0, abs(d - r));
}

void fragment() {
	vec2 p = UV - vec2(0.5);
	float d = length(p) * 2.0;
	float r = progress * 0.95;
	float body = ring(d, r, 0.10 + 0.10 * (1.0 - progress));
	float lip = ring(d, r * 0.86, 0.05) * 0.7;
	float a = (body + lip) * (1.0 - progress);
	// sparkle band: angular noise on the ring
	float ang = atan(p.y, p.x);
	float sp = 0.5 + 0.5 * sin(ang * 9.0 + progress * 20.0);
	a *= 0.75 + 0.25 * sp;
	COLOR = vec4(tint.rgb, clamp(a, 0.0, 1.0) * tint.a);
}
