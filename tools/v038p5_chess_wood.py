#!/usr/bin/env python3
"""v038p5_chess_wood.py - the parlor's wood room goes FULLY PROCEDURAL.

The generated bg_wood_{l,p}.png textures rendered as an opaque WHITE plate
on the Xvfb rig (Godot's own decoded pixels were correct brown - the
texture upload path itself broke). Canvas primitives render flawlessly on
the same stack, so the room is drawn by hand: planks + seams + grain +
vignette, deterministic, zero texture bytes. The 4.3 MB of pngs retire.
"""

import sys

PATH = "projects/gogabox/game/games/chess/chess.gd"
src = open(PATH).read()

start = src.find("func _draw_bg() -> void:")
end = src.find("func _sq_rect", start)
assert start >= 0 and end > start, "draw_bg region not found"

NEW = '''## v0.3.8-5 THE PARLOR ROOM (the studied reference's wood mood - drawn by
## hand, canvas primitives only, ZERO texture bytes: the generated wood
## textures rendered as a blank white plate on the rig's GL stack, the
## primitives render everywhere - same law that keeps the felt procedural)
func _draw_bg() -> void:
        var vp := get_viewport_rect().size
        # the base room shadow
        bg_l.draw_rect(Rect2(Vector2.ZERO, vp), Color("1d1409"))
        # the planks: vertical bands with deterministic widths, values and
        # grain streaks (the reference's warm walnut floor)
        var st := 0x2a7f3b
        var x := 0.0
        while x < vp.x:
                st = int((st * 1103515245 + 12345) & 0x7fffffff)
                var w := 92.0 + float(st % 74)
                st = int((st * 1103515245 + 12345) & 0x7fffffff)
                var v := 0.10 + float(st % 100) / 100.0 * 0.085
                bg_l.draw_rect(Rect2(x, 0.0, w + 1.0, vp.y),
                        Color(0.155 + v, 0.096 + v * 0.68,
                                0.050 + v * 0.38))
                # the plank seam
                bg_l.draw_rect(Rect2(x + w - 1.5, 0.0, 2.5, vp.y),
                        Color(0.085, 0.05, 0.026, 0.85))
                # the grain: horizontal streaks, dark and light
                for g in 6:
                        st = int((st * 1103515245 + 12345) & 0x7fffffff)
                        var gy := float(st % int(maxf(1.0, vp.y)))
                        st = int((st * 1103515245 + 12345) & 0x7fffffff)
                        var gl := 42.0 + float(st % 230)
                        if g % 3 == 2:
                                bg_l.draw_rect(Rect2(x + 5.0, gy, gl, 1.4),
                                        Color(0.42, 0.30, 0.16, 0.10))
                        else:
                                bg_l.draw_rect(Rect2(x + 5.0, gy, gl, 1.7),
                                        Color(0, 0, 0, 0.11))
                x += w
        # the room light: a radial wash - the heart of the parlor glows,
        # the walls sink into shadow (drawn big-ring-first, the smaller
        # rings ease the center back toward the raw wood)
        var c0 := Vector2(vp.x * 0.5, vp.y * 0.46)
        var rad_max := vp.length() * 0.64
        var rings := 18
        for i in range(rings, 0, -1):
                var rk := float(i) / float(rings)
                bg_l.draw_circle(c0, rad_max * rk,
                        Color(0.30, 0.20, 0.10,
                                0.30 * pow(1.0 - rk, 1.5)))
                bg_l.draw_circle(c0, rad_max * rk,
                        Color(0.02, 0.012, 0.006,
                                0.42 * pow(rk, 2.2)))

'''

src = src[:start] + NEW + src[end:]
open(PATH, "w").write(src)
print("parlor wood is procedural now")
