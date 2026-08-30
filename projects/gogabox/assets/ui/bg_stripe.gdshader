shader_type canvas_item;
// v0.1.2 GOGABox living background - DRAWN IN CODE, no source image.
//
// Owner directive: the v0.1.1 region-scrolled Sprite2D read as "a duplicated
// image with lower opacity moving to make the illusion". Fix: see the old
// bg_main.png, DETECT its two main colors, and drive the motion in code.
// scripts/v012_bg_colors.py measured:
//   base   #261508   (the dark brown field, ~55% of pixels)
//   stripe #35200d   (the lighter 45-degree bands, ~30%)
//   dots   #422a16   (the faint staggered dot grid accents)
// The stripes drift along their 45-degree normal forever - fract() math, so
// the loop is mathematically seamless at ANY speed, always full opacity.
// A soft sheen band sweeps down every 26s and the dots parallax at half
// speed: the box background breathes instead of ghosting.
//
// Pattern space = the LIVE CANVAS SIZE in design px (the "canvas" uniform,
// kept equal to the background rect by the menu on every design swap - see
// menu._bg_canvas_update). aspect EXPAND gives taller/wider phones extra
// canvas, and the pattern stays pixel-exact at ANY size: stripes always 45
// degrees at the measured period, identical look on every phone.

uniform vec4 base_col : source_color = vec4(0.1490196, 0.0823529, 0.0313726, 1.0);
uniform vec4 stripe_col : source_color = vec4(0.2078431, 0.1254902, 0.0509804, 1.0);
uniform vec4 dot_col : source_color = vec4(0.2588235, 0.1647059, 0.0862745, 1.0);
uniform vec2 canvas = vec2(1080.0, 1920.0); // live rect in design px (menu)
uniform float speed = 14.0;    // design px per second along the diagonal normal
uniform float period = 95.5;   // stripe period along the normal (design px;
                               // the png measured 90 px at 720-wide = 135 at
                               // 1080 design width = 135 / sqrt(2) here)
uniform float duty = 0.42;     // bright-band duty cycle (measured from the png)

void fragment() {
        vec2 p = UV * canvas;
        float t = TIME * speed;

        // --- stripes: 45 degrees, running bottom-left -> top-right, drifting
        // DOWN-RIGHT (d - t moves the pattern toward +x +y) forever.
        float d = (p.x + p.y) * 0.70710678 - t;
        float f = fract(d / period);
        float band = smoothstep(0.0, 0.10, f) * (1.0 - smoothstep(duty, duty + 0.10, f));
        vec3 col = mix(base_col.rgb, stripe_col.rgb, band);

        // --- dots: staggered 216x330 grid, same diagonal at HALF speed
        // (parallax depth, still mathematically seamless)
        vec2 grid = vec2(216.0, 330.0);
        vec2 q = p - vec2(0.35355339, 0.35355339) * t;
        q.x += mod(floor(q.y / grid.y), 2.0) * (grid.x * 0.5);
        vec2 c = (fract(q / grid) - 0.5) * grid;
        float dm = 1.0 - smoothstep(7.0, 10.0, length(c));
        col = mix(col, dot_col.rgb, dm * 0.9);

        // --- gentle vertical shade (the old png darkened toward the bottom)
        col *= mix(1.06, 0.92, UV.y);

        // --- the sheen: one soft 450px-wide light band sweeping down, one
        // lap every 26s - subtle life, never a second ghost image
        float sy = fract(TIME / 26.0) * (canvas.y + 900.0) - 450.0;
        float sheen = 1.0 - smoothstep(0.0, 450.0, abs(p.y - sy));
        col += stripe_col.rgb * sheen * 0.10;

        COLOR = vec4(col, 1.0);
}
