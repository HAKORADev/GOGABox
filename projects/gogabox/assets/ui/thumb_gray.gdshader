shader_type canvas_item;
// THE GRAY-OUT LAW (v041-3): a grayed thumbnail is GRAY, not a wash-out.
// The old look rode modulate alpha - a translucent image over the cream
// card, reading as a fade, with the square corners fighting the card's
// rounded silhouette at the same time. This shader keeps the thumbnail
// FULLY OPAQUE (the silhouette is exact), turns its colors gray and
// darkens them: strength mixes toward luminance, darken steps the value.
// strength 0 = the live art, strength 1 + darken 0.6 = the classic
// disabled read, still unmistakably the game's own art.
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float darken : hint_range(0.0, 1.0) = 0.62;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float l = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 g = mix(tex.rgb, vec3(l), strength);
	COLOR = vec4(g * darken, tex.a);
}
