shader_type canvas_item;
// v0.2.4 SPACE DASH deep-space background - DRAWN IN CODE (effects are
// allowed to be code; only the ships must be real art, owner law).
//
// Layers, back to front:
//   1. deep space base color (per "space": blue / green / yellow)
//   2. two nebula clouds - cheap fbm value noise, slow independent drift,
//      tinted per space, riding ADDITIVE over the base so they read as
//      lit gas, not painted blobs
//   3. two parallax starfields - hashed cell stars, the far layer dim +
//      slow, the near layer brighter + faster, both drifting DOWN (the
//      ship flies up), each star twinkles on its own phase
//   4. a vertical falloff so the top of the screen stays deep and the
//      bottom (the fight) stays readable
//
// The whole thing is seamless in TIME (fract math) and resolution
// independent (pattern space = UV).

uniform vec4 deep_col : source_color = vec4(0.024, 0.039, 0.11, 1.0);
uniform vec4 neb1_col : source_color = vec4(0.10, 0.18, 0.43, 1.0);
uniform vec4 neb2_col : source_color = vec4(0.24, 0.12, 0.40, 1.0);
uniform vec4 star_col : source_color = vec4(0.82, 0.90, 1.0, 1.0);
uniform float drift = 0.010;   // nebula drift speed (uv/s)

float hash21(vec2 p) {
        p = fract(p * vec2(234.34, 435.345));
        p += dot(p, p + 34.23);
        return fract(p.x * p.y);
}

float vnoise(vec2 p) {
        vec2 i = floor(p);
        vec2 f = fract(p);
        f = f * f * (3.0 - 2.0 * f);
        float a = hash21(i);
        float b = hash21(i + vec2(1.0, 0.0));
        float c = hash21(i + vec2(0.0, 1.0));
        float d = hash21(i + vec2(1.0, 1.0));
        return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
        float v = 0.0;
        float a = 0.55;
        for (int i = 0; i < 3; i++) {
                v += a * vnoise(p);
                p = p * 2.13 + vec2(11.7, 5.3);
                a *= 0.5;
        }
        return v;
}

float star_layer(vec2 uv, float density, float t) {
        vec2 g = uv * density;
        vec2 id = floor(g);
        vec2 f = fract(g) - 0.5;
        float h = hash21(id);
        // one star per cell, only some cells are lit
        float lit = step(0.90 - density * 0.0002, h);
        vec2 off = vec2(hash21(id + 7.1), hash21(id + 3.7)) - 0.5;
        float d = length(f - off * 0.6);
        float tw = 0.65 + 0.35 * sin(t * (1.5 + h * 4.0) + h * 40.0);
        return lit * smoothstep(0.10, 0.0, d) * tw;
}

void fragment() {
        vec2 uv = UV;
        float t = TIME;

        vec3 col = deep_col.rgb;

        // nebulae - additive lit gas
        float n1 = fbm(uv * vec2(3.0, 2.2) + vec2(t * drift, -t * drift * 0.6));
        col += neb1_col.rgb * smoothstep(0.55, 0.95, n1) * 0.55;
        float n2 = fbm(uv * vec2(4.4, 3.0) - vec2(t * drift * 1.4, t * drift * 0.4) + 5.0);
        col += neb2_col.rgb * smoothstep(0.60, 1.0, n2) * 0.40;

        // starfields drifting down (the ship flies up)
        float t4 = t * 1.0;
        float s_far = star_layer(uv * vec2(1.0, 1.0) + vec2(0.0, -t4 * 0.008), 90.0, t4);
        float s_near = star_layer(uv * vec2(1.0, 1.0) + vec2(0.0, -t4 * 0.030) + 13.1, 40.0, t4 * 1.3);
        col += star_col.rgb * s_far * 0.55;
        col += star_col.rgb * s_near * 0.95;

        // depth falloff: deeper at the top, gentle lift at the bottom
        col *= mix(0.82, 1.08, 1.0 - uv.y);

        COLOR = vec4(col, 1.0);
}
