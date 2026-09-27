shader_type canvas_item;
// GEOMETRY FLASH - the mechanic-swap flash: a soft radial breathe that
// washes the screen once per hidden-mechanic reveal. Never harsh.
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec3 flash_col : source_color = vec3(0.75, 0.88, 1.0);

void fragment() {
        float d = distance(UV, vec2(0.5));
        float ring = smoothstep(0.95, 0.15, d);
        COLOR = vec4(flash_col, ring * 0.5 * intensity);
}
