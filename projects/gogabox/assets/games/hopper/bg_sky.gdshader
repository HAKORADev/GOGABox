shader_type canvas_item;
// SNOWY TOWER sky (v0.2.5) - day: gradient + soft sun + drifting band.
// night: deep gradient + crescent moon + twinkling stars + TWO aurora
// ribbons. The owner: "make day and night really give different feeling
// than just different backgrounds" - the world also wears a place tint
// (CanvasModulate) and the platforms catch a moonlit rim at night.
// `shift` is fed from cam_y (tiny factor): the sky sinks slowly as you
// climb, the orb rides its own slower parallax.

uniform vec4 top_col : source_color = vec4(0.435, 0.725, 0.91, 1.0);
uniform vec4 hor_col : source_color = vec4(0.89, 0.949, 0.984, 1.0);
uniform vec4 orb_col : source_color = vec4(1.0, 0.955, 0.78, 1.0);
uniform float orb_kind = 1.0;    // 1 = sun (day), 2 = crescent moon (night)
uniform float star_amt = 0.0;    // 0 day, 1 night
uniform float aurora_amt = 0.0;  // 0 day, 1 night
uniform float shift = 0.0;       // cam parallax (uv units, tiny)
uniform float time_s = 0.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float y = clamp(uv.y + shift, 0.0, 1.0);
	vec3 grad = mix(top_col.rgb, hor_col.rgb, pow(y, 1.35));
	vec3 col = grad;

	// ---- the orb (sun or crescent moon), its own slow parallax ----
	vec2 sp = vec2(0.76, clamp(0.17 + shift * 2.2, 0.08, 0.5));
	vec2 ap = vec2(uv.x * 1.25, uv.y);
	vec2 asp = vec2(sp.x * 1.25, sp.y);
	float d = distance(ap, asp);
	if (orb_kind < 1.5) {
		// day sun: bright core + wide soft halo
		col += orb_col.rgb * smoothstep(0.085, 0.045, d) * 0.95;
		col += orb_col.rgb * smoothstep(0.30, 0.0, d) * 0.22;
	} else {
		// night moon: crisp disc + halo + a crescent bite
		col += orb_col.rgb * smoothstep(0.062, 0.05, d) * 0.98;
		col += orb_col.rgb * smoothstep(0.26, 0.0, d) * 0.16;
		vec2 sp2 = asp + vec2(0.028, 0.016);
		float d2 = distance(ap, sp2);
		col = mix(col, grad, smoothstep(0.058, 0.045, d2) * 0.92);
	}

	// ---- stars (night): a hash grid, each star twinkles on its own beat
	if (star_amt > 0.001) {
		vec2 gp = floor(uv * vec2(90.0, 150.0));
		float h = hash21(gp);
		float tw = 0.55 + 0.45 * sin(time_s * (1.0 + h * 2.4) + h * 43.0);
		float star = step(0.986, h) * tw;
		col += vec3(0.88, 0.94, 1.0) * star * star_amt * (1.0 - y * 0.55);
	}

	// ---- aurora ribbons (night): two slow sine ribbons, teal + violet
	if (aurora_amt > 0.001) {
		float a1 = sin(uv.x * 7.0 + time_s * 0.33 + sin(uv.x * 13.0 + time_s * 0.21) * 0.8);
		float b1 = smoothstep(0.16, 0.0, abs(uv.y - 0.30 - a1 * 0.055));
		float a2 = sin(uv.x * 5.0 - time_s * 0.24 + sin(uv.x * 9.0 - time_s * 0.17) * 0.9);
		float b2 = smoothstep(0.13, 0.0, abs(uv.y - 0.19 - a2 * 0.06));
		col += (vec3(0.16, 0.85, 0.62) * b1 + vec3(0.52, 0.28, 0.88) * b2) * aurora_amt * 0.5;
	}

	// ---- one drifting cloud band (both places, subtle) ----
	float cl = sin(uv.x * 4.0 + time_s * 0.045 + shift * 22.0) * 0.5
			+ sin(uv.x * 9.0 - time_s * 0.03 + shift * 9.0) * 0.5;
	float band = smoothstep(0.24, 0.0, abs(uv.y - 0.42 - cl * 0.05));
	col = mix(col, vec3(1.0), band * (0.10 + 0.05 * (1.0 - star_amt)));

	COLOR = vec4(col, 1.0);
}
