shader_type canvas_item;
// SNOWY TOWER sky (v0.2.6) - CLEAN (the owner's v0.2.5 verdict: the busy
// sky was bad; "making it clean with some clouds and at night with some
// star-like lights that are shaders/particles will be better"). The
// mountains, tree lines, aurora ribbons and the wide cloud band are GONE.
// day: one calm gradient + a SMALL corner sun (the snake game's size law).
// night: a deep gradient + a small crescent moon + two star layers
// (dust + breathing glints) - the drifting clouds and the night sparks
// are particles in world space, not this shader's business.
// `shift` is fed from cam_y: the gradient sinks slowly as you climb.

uniform vec4 top_col : source_color = vec4(0.435, 0.725, 0.91, 1.0);
uniform vec4 hor_col : source_color = vec4(0.89, 0.949, 0.984, 1.0);
uniform vec4 orb_col : source_color = vec4(1.0, 0.955, 0.78, 1.0);
uniform float orb_kind = 1.0;    // 1 = sun (day), 2 = crescent moon (night)
uniform float star_amt = 0.0;    // 0 day, 1 night
uniform float orb_r = 0.02;      // core radius, uv.y units (set from code)
uniform float glow_r = 0.055;    // halo radius, uv.y units
uniform float aspect = 0.5;      // vp.x / vp.y (round orbs on any window)
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

        // ---- the orb: SMALL, top corner, aspect-corrected so it is ROUND
        // on every window (x carries the W/H ratio: px = uv * (W, H), so
        // dx_uv must be scaled BY the aspect, not divided) ----
        vec2 sp = vec2(0.84, clamp(0.085 + shift * 2.2, 0.055, 0.40));
        vec2 rel = (uv - sp) * vec2(aspect, 1.0);
        float d = length(rel);
        if (orb_kind < 1.5) {
                // day sun: small warm core + one tight soft halo
                col = mix(col, orb_col.rgb * 1.04, smoothstep(orb_r, orb_r * 0.66, d));
                col += orb_col.rgb * smoothstep(glow_r, 0.0, d) * 0.32;
        } else {
                // night moon: small crisp disc + tight halo + the crescent bite
                col = mix(col, orb_col.rgb, smoothstep(orb_r, orb_r * 0.78, d));
                col += orb_col.rgb * smoothstep(glow_r * 0.8, 0.0, d) * 0.20;
                float db = length((uv - sp - vec2(orb_r * 0.62 * aspect, orb_r * 0.34)) * vec2(aspect, 1.0));
                col = mix(col, grad, smoothstep(orb_r * 1.02, orb_r * 0.86, db) * 0.94);
        }

        // ---- stars (night): DUST - tiny ROUND points, softly alive ----
        if (star_amt > 0.001) {
                vec2 gp = uv * vec2(56.0, 96.0);
                vec2 cell = floor(gp);
                float h = hash21(cell);
                float breathe = 0.60 + 0.40 * sin(time_s * (0.5 + h * 1.3) + h * 41.0);
                vec2 spos = vec2(hash21(cell + 3.1), hash21(cell + 7.7)) * 0.6 + 0.2;
                float pd = length(fract(gp) - spos);
                float dust = step(0.965, h) * smoothstep(0.13, 0.03, pd) * breathe;
                col += vec3(0.86, 0.92, 1.0) * dust * star_amt * (1.0 - y * 0.55);

                // GLINTS - a few bigger stars that pulse on their own beat
                vec2 gp2 = uv * vec2(14.0, 24.0);
                vec2 cell2 = floor(gp2);
                float h2 = hash21(cell2 + 7.31);
                float tw = pow(0.5 + 0.5 * sin(time_s * (0.7 + h2 * 1.7) + h2 * 57.0), 3.0);
                vec2 spos2 = vec2(hash21(cell2 + 1.7), hash21(cell2 + 9.3)) * 0.6 + 0.2;
                float pd2 = length(fract(gp2) - spos2);
                float glint = step(0.90, h2) * smoothstep(0.16, 0.04, pd2) * tw;
                col += vec3(0.96, 0.98, 1.0) * glint * star_amt * (1.0 - y * 0.6);
        }

        COLOR = vec4(col, 1.0);
}
