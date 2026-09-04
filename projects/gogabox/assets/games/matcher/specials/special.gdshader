shader_type canvas_item;
// MATCHER - THE SPECIAL-ON-THE-ASSET SHADER (v0.3.3-p2, the owner:
// "i want it to be like a shader on the asset, not a weird VFX that is even
// not synced with the thing movement"). The material LIVES on the gem's own
// Sprite2D, so every effect rides the gem through swaps, gravity and cascades
// - there is no separate overlay to desync, and any skin's texture works.
uniform int special = 0; // 0 none - 1 flame - 2 star - 3 hypercube

void fragment() {
        vec4 tex = texture(TEXTURE, UV);
        vec3 col = tex.rgb;
        float t = TIME;
        if (special == 1) {
                // FLAME: a breathing warm rim + inner heat shimmer
                vec2 c = UV - vec2(0.5);
                float rr = length(c) * 2.0;
                float pulse = 0.5 + 0.5 * sin(t * 5.2);
                float rim = smoothstep(0.55, 1.05, rr);
                vec3 fire = vec3(1.0, 0.45 + 0.2 * pulse, 0.12);
                col = mix(tex.rgb, fire, rim * (0.45 + 0.3 * pulse));
                col *= 1.0 + 0.22 * pulse * (1.0 - rim);
        } else if (special == 2) {
                // STAR: a white-gold sparkle cross sweeping over the gem
                vec2 p = UV - vec2(0.5);
                float cross = max(smoothstep(0.045, 0.0, abs(p.x)),
                                  smoothstep(0.045, 0.0, abs(p.y)));
                float sweep = 0.5 + 0.5 * sin(t * 3.4 - length(p) * 9.0);
                float glint = clamp(cross * (0.55 + 0.45 * sweep), 0.0, 1.0);
                vec3 gold = vec3(1.0, 0.92, 0.55);
                col = mix(tex.rgb, gold, glint * 0.75);
                col *= 1.0 + 0.14 * sweep;
        } else if (special == 3) {
                // HYPERCUBE: the rainbow read - a hue rotation around the
                // gem's own luminance, breathing with time
                float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
                float ang = t * 1.9 + (UV.x + UV.y) * 4.2;
                vec3 rainbow = vec3(
                        0.5 + 0.5 * sin(ang),
                        0.5 + 0.5 * sin(ang + 2.094),
                        0.5 + 0.5 * sin(ang + 4.188));
                col = mix(rainbow * (0.45 + 0.85 * lum), tex.rgb, 0.28);
                float breath = 0.5 + 0.5 * sin(t * 2.6);
                col *= 1.0 + 0.18 * breath;
        }
        COLOR = vec4(col, tex.a);
}
