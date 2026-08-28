shader_type canvas_item;
// Vertical sky gradient that deepens from day-blue to space-dark with altitude.

uniform vec3 top_day : source_color = vec3(0.42, 0.72, 0.95);
uniform vec3 bottom_day : source_color = vec3(0.75, 0.88, 0.97);
uniform vec3 top_night : source_color = vec3(0.05, 0.05, 0.16);
uniform vec3 bottom_night : source_color = vec3(0.16, 0.12, 0.34);
uniform float altitude = 0.0;   // meters; 0 at ground, ~2000 = full night
uniform vec2 rect_size = vec2(720.0, 1280.0);

void fragment() {
	float k = clamp(altitude / 2000.0, 0.0, 1.0);
	vec3 top = mix(top_day, top_night, k);
	vec3 bottom = mix(bottom_day, bottom_night, k);
	float v = UV.y;
	COLOR = vec4(mix(top, bottom, v), 1.0);
}
