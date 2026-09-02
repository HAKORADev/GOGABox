shader_type canvas_item;
// 2048 DEEP SEA v0.2.8 - the water is PHYSICAL now (the owner: "i want it
// to react based on the square movement and motion for real, not based on
// the direction... if a square is at the left edge and i swiped to left,
// i will still see the water moves which is unreal because the square
// still in same place... i did not liked the weird wave so make it more
// natural").
//
// The game runs a per-tile damped SPRING fed ONLY by the tile's real
// position deltas (its container acceleration). What reaches the shader:
//   tilt   = the spring's surface tilt (+ = higher on the right). Born 0,
//            excited by real motion, settles calm through a few natural
//            swings. A tile that never moves keeps it at 0.0 forever.
//   energy = ripple + foam fuel, fed by the same motion and the merge
//            splash. At 0 the surface is PERFECTLY still - time_s does
//            nothing (the old time-driven "weird wave" is dead).
//   fill   = the tier (higher tile = more water) - unchanged law.
// The resting shape is natural: a flat fill with a slight meniscus that
// climbs the cell walls - static geometry, not motion.

uniform float fill = 0.35;
uniform float time_s = 0.0;        // only scrolls ripple/foam WHEN energized
uniform float tilt = 0.0;
uniform float energy = 0.0;
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

        // the resting surface: the fill line + the static meniscus (water
        // climbs the walls a hair) - this shape does NOT move by itself
        float men = pow(abs(UV.x - 0.5) * 2.0, 3.0) * 0.022 * rect_px;
        float surf = p.y - (0.5 - fill) * rect_px + men;
        // the spring tilt (the real motion answer)
        surf -= tilt * (UV.x - 0.5) * rect_px * 0.34;
        // the ripple: TWO close, small capillary waves - natural in size,
        // scaled by energy, so a calm tile shows NOTHING (no weird wave)
        float rip = sin(UV.x * 23.0 + time_s * 8.0) * 0.62
                  + sin(UV.x * 37.0 - time_s * 12.0) * 0.38;
        surf += rip * rect_px * 0.012 * min(energy, 1.0);

        vec4 col = glass_col;
        if (surf > 0.0) {
                float depth = clamp(surf / max(1.0, fill * rect_px), 0.0, 1.0);
                col = mix(water_hi, water_col, clamp(depth * 1.7, 0.0, 1.0));
                col = mix(col, glass_col * 1.35, depth * depth * 0.6);
                // the bright meniscus line + a little foam (motion only)
                col = mix(col, water_hi, smoothstep(2.6, 0.0, abs(surf)) * 0.85);
                float foam = step(0.80, sin(UV.x * 41.0 + time_s * 7.0))
                                * min(energy, 1.0) * 0.30;
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
