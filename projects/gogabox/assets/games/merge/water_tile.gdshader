shader_type canvas_item;
// 2048 DEEP SEA - the physical water inside every tile (v0.2.7, the owner:
// "the higher the number the more water inside it" and "the animation and
// movement moves the water inside, so it's a real physical based water i
// mean and not just some static coloring").
// Each tile owns one instance of this material:
//   fill    = the tier (0.22 for a 2 ... 0.95 for a 2048)
//   slosh   = the slide tilt (-1..1, set while the tile rides, decays)
//   amp     = the wave energy (slides + merges energize it, it settles calm)
//   time_s  = the shared clock (the surface never stops breathing)

uniform float fill = 0.35;
uniform float time_s = 0.0;
uniform float slosh = 0.0;
uniform float amp = 0.4;
uniform float rect_px = 120.0;
uniform float radius_px = 16.0;
uniform vec4 glass_col : source_color = vec4(0.05, 0.13, 0.28, 1.0);
uniform vec4 water_col : source_color = vec4(0.36, 0.68, 0.96, 0.98);
uniform vec4 water_hi : source_color = vec4(0.68, 0.88, 1.0, 1.0);

float sdf_round_rect(vec2 p, vec2 b, float r) {
        vec2 q = abs(p) - b + r;
        return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void fragment() {
        vec2 p = (UV - vec2(0.5)) * rect_px;
        float d = sdf_round_rect(p, vec2(rect_px * 0.5), radius_px);
        float inside = 1.0 - smoothstep(-1.5, 0.5, d);

        // the surface test (UV.y grows DOWN): the water surface sits at
        // p.y = (0.5 - fill) * rect_px; a point is under water when
        // p.y is BELOW it - `surf` is the depth below the surface in px
        float surf = p.y - (0.5 - fill) * rect_px;
        surf += slosh * (UV.x - 0.5) * rect_px * 0.30;
        surf += sin(UV.x * 7.3 + time_s * 3.1) * amp * rect_px * 0.045;
        surf += sin(UV.x * 12.7 - time_s * 2.2) * amp * rect_px * 0.025;

        vec4 col = glass_col;
        if (surf > 0.0) {
                float depth = clamp(surf / max(1.0, fill * rect_px), 0.0, 1.0);
                col = mix(water_hi, water_col, clamp(depth * 1.7, 0.0, 1.0));
                col = mix(col, glass_col * 1.35, depth * depth * 0.6);
                // the bright meniscus line + a little foam
                col = mix(col, water_hi, smoothstep(2.6, 0.0, abs(surf)) * 0.85);
                float foam = step(0.82, sin(UV.x * 41.0 + time_s * 5.0)) * amp * 0.35;
                col.rgb += vec3(foam);
        }
        // the glass shine (a soft top-left highlight, brighter when emptier)
        float shine = smoothstep(0.55, 0.0, length((UV - vec2(0.30, 0.24)) * vec2(1.0, 1.30)));
        col.rgb += vec3(0.10) * shine * (0.35 + 0.65 * (1.0 - fill));
        // a darker rim reads as the cell wall
        float rim = smoothstep(0.0, 2.2, -d + 1.0);
        col.rgb *= mix(0.82, 1.0, rim);

        col.a = inside * col.a;
        COLOR = col;
}
