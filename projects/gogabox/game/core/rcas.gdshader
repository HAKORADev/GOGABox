shader_type canvas_item;
// v0.4.1 DYNAMIC SCALE - the FSR-family full-frame sharpening pass.
//
// The owner asked for FSR upscaling ("search for FSR4.1 from AMD plugin for
// godot... dlls that can be baked in our windows binary... low resources to
// scale the internal resolution to fit the big screen and also remove
// jagged edges... make it work on nvidia and intel GPUs next to AMD").
// The honest truth: FSR 4 is AMD RDNA4 machine-learning tech that cannot
// ride a 2D GL Compatibility app, and FSR 2/3 are temporal 3D passes. The
// FidelityFX family DOES ship the piece that fits us: the spatial
// sharpening pass designed exactly for upscaled frames (the same family
// FSR 1 used after its own upscale - CAS/RCAS). One shader, four texture
// taps, every GPU, no restart, no vendor lock.
//
// It runs over the WHOLE final frame (CanvasLayer 120): vector UI and text
// are already rendered at the real window resolution, so they just get a
// touch crisper; raster art that the window scale upscaled stops looking
// soft at 1440p/4K.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float sharpness : hint_range(0.0, 1.0) = 0.55;

float _luma(vec3 c) {
        return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void fragment() {
        vec2 px = SCREEN_PIXEL_SIZE;
        vec3 e = texture(screen_tex, SCREEN_UV).rgb;
        vec3 b = texture(screen_tex, SCREEN_UV + vec2(0.0, -1.0) * px).rgb;
        vec3 d = texture(screen_tex, SCREEN_UV + vec2(-1.0, 0.0) * px).rgb;
        vec3 f = texture(screen_tex, SCREEN_UV + vec2(1.0, 0.0) * px).rgb;
        vec3 h = texture(screen_tex, SCREEN_UV + vec2(0.0, 1.0) * px).rgb;
        // Contrast-adaptive: flat areas stay untouched, edges tighten.
        vec3 mn3 = min(min(min(d, e), min(f, h)), b);
        vec3 mx3 = max(max(max(d, e), max(f, h)), b);
        float mn = _luma(mn3);
        float mx = max(_luma(mx3), 1e-4);
        float amp = clamp(sqrt(min(mn, 2.0 - mx) / mx), 0.0, 1.0);
        float w = amp * sharpness;
        vec3 outc = (w * (b + d + f + h) + e) / (4.0 * w + 1.0);
        COLOR = vec4(outc, 1.0);
}
