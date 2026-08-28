shader_type canvas_item;
// Jelly wobble: vertex displacement driven by recent impacts.

uniform float wobble= 0.0;      // 0..1 impulse set from script, decays there
uniform float wobble_speed= 34.0;
uniform float squash= 0.0;      // -1..1, negative = squashed flat, positive = stretched

void vertex() {
	float t = TIME * wobble_speed;
	vec2 v = VERTEX;
	// horizontal jelly jiggle, stronger near the bottom of the sprite
	float amp = wobble * 6.0 + 0.8;
	v.x += sin(t + v.y * 0.09) * amp;
	v.y += cos(t * 0.8 + v.x * 0.05) * amp * 0.6;
	// squash & stretch around the sprite center (UV y: 1 = bottom)
	v.y -= squash * (UV.y - 0.5) * 26.0;
	v.x += squash * (UV.y - 0.5) * 6.0;
	VERTEX = v;
}
