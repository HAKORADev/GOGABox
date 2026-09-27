shader_type canvas_item;
// v040-8 THE SKY LAW: the sky is a real shader - a vertical gradient,
// two depths of drifting fbm clouds, a twinkling star field for the dark
// places, and a soft sun/moon disc with a halo. The place's palette feeds
// the uniforms; TIME drives the drift and the twinkle (the owner: "where
// is the physics and shaders and all these pretty things").

uniform vec3 col_top : source_color = vec3(0.09, 0.10, 0.16);
uniform vec3 col_bot : source_color = vec3(0.29, 0.22, 0.16);
uniform vec3 sun_col : source_color = vec3(1.0, 0.85, 0.5);
uniform vec2 sun_pos = vec2(0.78, 0.16);   // normalized uv
uniform float moon = 0.0;                  // 1 = crescent moon, 0 = sun
uniform float stars = 0.0;                 // 1 = the star field is on
uniform vec3 cloud_col : source_color = vec3(0.9, 0.9, 0.95);
uniform float cloud_amt = 0.55;
uniform float seed = 11.0;

float hash(vec2 p) {
        return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453);
}

float noise(vec2 p) {
        vec2 i = floor(p);
        vec2 f = fract(p);
        vec2 u = f * f * (3.0 - 2.0 * f);
        return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
                mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
                u.y);
}

float fbm(vec2 p) {
        float v = 0.0;
        float a = 0.5;
        for (int i = 0; i < 4; i++) {
                v += a * noise(p);
                p = p * 2.07 + vec2(17.3, 9.1);
                a *= 0.5;
        }
        return v;
}

void fragment() {
        vec2 uv = UV;
        // THE GRADIENT
        vec3 col = mix(col_top, col_bot, pow(clamp(uv.y, 0.0, 1.0), 0.85));
        // THE STARS (dark places only) - hash sparkle on a grid
        if (stars > 0.5) {
                vec2 g = floor(uv * vec2(90.0, 160.0));
                float h = hash(g);
                if (h > 0.978) {
                        vec2 f = fract(uv * vec2(90.0, 160.0)) - 0.5;
                        float d = length(f);
                        float tw = 0.35 + 0.65 * abs(sin(TIME * (1.5 + h * 4.0)
                                + h * 40.0));
                        col += vec3(0.9, 0.95, 1.0) * tw
                                * smoothstep(0.22, 0.0, d);
                }
        }
        // THE SUN / MOON - a soft disc + a wide halo
        vec2 sp = sun_pos;
        vec2 dir = (uv - sp) * vec2(1.0, 1.6);   // aspect-ish squash
        float d2 = length(dir);
        float halo = smoothstep(0.55, 0.0, d2) * 0.35;
        float disc = smoothstep(0.055, 0.048, d2);
        col += sun_col * halo;
        vec3 body = mix(sun_col, vec3(0.94, 0.95, 1.0), moon);
        col = mix(col, body, disc);
        if (moon > 0.5) {
                // the crescent bite
                vec2 bp = sp + vec2(0.028, -0.012);
                float bd = length((uv - bp) * vec2(1.0, 1.6));
                float bite = smoothstep(0.048, 0.043, bd);
                col = mix(col, col_top * 1.05, bite * disc);
        }
        // THE CLOUDS - two drifting fbm banks, fading with height
        float t = TIME * 0.012;
        vec2 cuv = uv * vec2(2.2, 4.4) + vec2(t * 6.0, seed);
        float c1 = fbm(cuv);
        float c2 = fbm(cuv * 2.3 + vec2(t * 9.0 + 40.0, 3.0));
        float clouds = smoothstep(0.52, 0.78, c1 * 0.65 + c2 * 0.45)
                * cloud_amt * smoothstep(0.95, 0.35, uv.y);
        col = mix(col, cloud_col, clouds * 0.55);
        // a calm vignette grounds the frame
        float vig = smoothstep(1.35, 0.55, length((uv - 0.5) * 2.0));
        col *= mix(0.86, 1.0, vig);
        COLOR = vec4(col, 1.0);
}
