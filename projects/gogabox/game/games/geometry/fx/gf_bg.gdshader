shader_type canvas_item;
// GEOMETRY FLASH - the world background: theme gradient + drifting grid
// + a slow breathing band. Gentle on purpose (the owner: "the glow make
// it gentle and amazing"). Theme palettes feed the uniforms.
uniform vec3 col_top : source_color = vec3(0.030, 0.045, 0.110);
uniform vec3 col_mid : source_color = vec3(0.055, 0.070, 0.160);
uniform vec3 col_bot : source_color = vec3(0.015, 0.025, 0.060);
uniform vec3 line_col : source_color = vec3(0.14, 0.20, 0.42);
uniform float scroll_x = 0.0;
uniform float time_s = 0.0;
uniform float pulse = 0.0; // 0..1 the soft beat

void fragment() {
        vec2 uv = UV;
        vec3 col = mix(col_top, col_mid, smoothstep(0.0, 0.55, uv.y));
        col = mix(col, col_bot, smoothstep(0.55, 1.0, uv.y));
        // the drifting grid (two scales, slow parallax)
        vec2 g1 = vec2(uv.x * 18.0 - scroll_x * 0.0055, uv.y * 10.0 + time_s * 0.05);
        vec2 f1 = abs(fract(g1) - 0.5);
        float l1 = smoothstep(0.44, 0.5, max(f1.x, f1.y));
        vec2 g2 = vec2(uv.x * 6.0 - scroll_x * 0.0016, uv.y * 3.4);
        vec2 f2 = abs(fract(g2) - 0.5);
        float l2 = smoothstep(0.46, 0.5, max(f2.x, f2.y));
        col += line_col * (l1 * 0.16 + l2 * 0.30) * (0.55 + 0.45 * pulse);
        // the breathing band mid-screen
        float band = exp(-pow((uv.y - 0.5 - 0.16 * sin(time_s * 0.35)), 2.0) * 16.0);
        col += line_col * band * (0.045 + 0.06 * pulse);
        COLOR = vec4(col, 1.0);
}
