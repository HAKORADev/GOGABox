shader_type canvas_item;
// MATCHER - THE SPECIAL-ON-THE-ASSET SHADER v3 (v0.3.3-p5, the owner looked
// at the two sweeper gems and said: "see how the VFX/shader look now? just
// swap them, that's it ... i mean the shader on the gem ofc"): the ROW and
// the COLUMN sweeper bodies traded places. The material LIVES on the gem's
// own Sprite2D, so every effect rides the gem through swaps, gravity and
// cascades - no overlay to desync, any skin's texture works.
// kinds: 0 none - 1 bomb (L/T) - 2 row-h sweeper (4 vertical) -
//        3 col-v sweeper (4 horizontal) - 4 color remover (5 in a line)
uniform int special = 0;

float hash21(vec2 p) {
        p = fract(p * vec2(234.34, 435.345));
        p += dot(p, p + 34.23);
        return fract(p.x * p.y);
}

void fragment() {
        vec4 tex = texture(TEXTURE, UV);
        vec3 col = tex.rgb;
        float t = TIME;
        vec2 p = UV - vec2(0.5);
        float rr = length(p) * 2.0;
        if (special == 1) {
                // BOMB: a molten heartbeat core + orbiting ember beads + hot rim.
                float beat = 0.5 + 0.5 * sin(t * 6.0);
                float core = smoothstep(0.62, 0.0, rr);
                col = mix(col, vec3(1.0, 0.32 + 0.25 * beat, 0.08), core * (0.42 + 0.25 * beat));
                float rim = smoothstep(0.55, 1.02, rr);
                col = mix(col, vec3(1.0, 0.5, 0.1), rim * (0.5 + 0.3 * beat));
                // ember beads: 6 dots orbiting the rim
                float beads = 0.0;
                for (int i = 0; i < 6; i++) {
                        float a = float(i) * 1.047 + t * 2.4;
                        vec2 bp = vec2(cos(a), sin(a)) * (0.36 + 0.05 * sin(t * 3.0 + float(i)));
                        beads += smoothstep(0.10, 0.0, length((p - bp) * vec2(1.0, 1.0)));
                }
                col = mix(col, vec3(1.0, 0.85, 0.3), clamp(beads, 0.0, 1.0) * 0.9);
                col *= 1.0 + 0.16 * beat;
        } else if (special == 2) {
                // ROW SWEEPER (v0.3.3-p5: this body used to be the column's - the
                // owner's swap): vertical energy bands gliding across, magenta-white,
                // with a bright vertical core stripe down the middle.
                float glide = fract(UV.x * 2.0 - t * 1.6);
                float band = smoothstep(0.0, 0.12, glide) * smoothstep(0.36, 0.12, glide);
                float glow = 0.5 + 0.5 * sin(t * 4.2 + 1.7);
                col = mix(col, vec3(1.0, 0.55, 0.95), band * (0.55 + 0.3 * glow));
                float rim = smoothstep(0.6, 1.02, rr);
                col += vec3(0.55, 0.2, 0.5) * rim * (0.3 + 0.3 * glow);
                float mid = smoothstep(0.10, 0.0, abs(p.x));
                col = mix(col, vec3(1.0), mid * (0.35 + 0.25 * sin(t * 5.0)));
                col *= 1.0 + 0.1 * glow;
        } else if (special == 3) {
                // COLUMN SWEEPER (v0.3.3-p5: this body used to be the row's - the
                // owner's swap): horizontal energy bands gliding down, cyan-white,
                // with a bright horizontal core stripe across the middle.
                float glide = fract(UV.y * 2.0 + t * 1.6);
                float band = smoothstep(0.0, 0.12, glide) * smoothstep(0.36, 0.12, glide);
                float glow = 0.5 + 0.5 * sin(t * 4.2);
                col = mix(col, vec3(0.55, 0.95, 1.0), band * (0.55 + 0.3 * glow));
                float rim = smoothstep(0.6, 1.02, rr);
                col += vec3(0.2, 0.5, 0.6) * rim * (0.3 + 0.3 * glow);
                float mid = smoothstep(0.10, 0.0, abs(p.y));
                col = mix(col, vec3(1.0), mid * (0.35 + 0.25 * sin(t * 5.0)));
                col *= 1.0 + 0.1 * glow;
        } else if (special == 4) {
                // COLOR REMOVER: an iridescent swirl + white heartbeat core + sparkle.
                float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
                float swirl = (UV.x + UV.y) * 5.0 + t * 2.2 + sin((UV.x - UV.y) * 8.0 + t) * 1.4;
                vec3 iri = vec3(0.5 + 0.5 * sin(swirl),
                                0.5 + 0.5 * sin(swirl + 2.094),
                                0.5 + 0.5 * sin(swirl + 4.188));
                col = mix(iri * (0.5 + 0.8 * lum), col, 0.18);
                float beat = 0.5 + 0.5 * sin(t * 3.2);
                float core = smoothstep(0.5 + 0.12 * beat, 0.0, rr);
                col = mix(col, vec3(1.0), core * 0.65);
                // sparkle noise
                vec2 gp = floor(UV * 14.0);
                float sp = step(0.965, hash21(gp + floor(t * 4.0)));
                col += vec3(1.0, 1.0, 0.9) * sp * (0.5 + 0.5 * sin(t * 9.0 + gp.x));
                col *= 1.0 + 0.14 * beat;
        }
        COLOR = vec4(col, tex.a);
}
