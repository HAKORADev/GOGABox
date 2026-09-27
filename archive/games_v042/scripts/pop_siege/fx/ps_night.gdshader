shader_type canvas_item;
// POP SIEGE - the night grade: cool multiply + warm lamp pools + soft vignette.
// One full-screen quad above the field (below the HUD).
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 heart_uv = vec2(0.94, 0.85); // the heart house in field space

void fragment() {
	vec3 night = vec3(0.34, 0.40, 0.66);
	float d_heart = distance(UV, heart_uv);
	float lamp = smoothstep(0.28, 0.0, d_heart) * 0.5;
	float vig = smoothstep(0.95, 0.35, distance(UV, vec2(0.5)));
	float k = strength;
	vec3 graded = mix(vec3(1.0), night, k);
	graded += vec3(1.0, 0.75, 0.4) * lamp * k;
	graded *= mix(1.0, 0.8 + 0.2 * vig, k);
	COLOR = vec4(graded, 1.0);
}
