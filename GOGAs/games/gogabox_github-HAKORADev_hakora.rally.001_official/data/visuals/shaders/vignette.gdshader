shader_type canvas_item;
// the open-data law: replaceable at data/visuals/shaders/
void fragment() {
	float d = distance(UV, vec2(0.5));
	COLOR = vec4(0.0, 0.0, 0.0, smoothstep(0.55, 0.95, d) * 0.35);
}
