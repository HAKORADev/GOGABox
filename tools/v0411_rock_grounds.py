#!/usr/bin/env python3
"""v040-11 - re-bake ground_cave + ground_neon with readable-dark bases
(same layout code as v0408_rock_world.ground_strip, lifted palettes)."""
import random

from PIL import Image, ImageDraw

OUT = ("/home/z/my-project/gogabox/projects/gogabox"
       "/assets/games/rockbreaker/world")


def ground_strip(style, seed):
    W, H = 1080, 190
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rng = random.Random(seed)
    base = {
        "cave": ((104, 76, 54, 255), (76, 54, 38, 255)),
        "neon": ((48, 60, 126, 255), (30, 38, 88, 255)),
    }[style]
    d.rectangle([0, 0, W, H], fill=base[0])
    d.rectangle([0, 52, W, H], fill=base[1])
    d.rectangle([0, 0, W, 8], fill=tuple(min(255, int(c * 1.35)) for c in base[0][:3]) + (255,))
    for i in range(70):
        x, y = rng.uniform(0, W), rng.uniform(16, H - 8)
        if style == "neon":
            if i % 3 == 0:
                d.line([(x, y), (x + rng.uniform(30, 90), y)],
                       fill=(90, 220, 255, 80), width=2)
        else:
            d.ellipse([x, y, x + rng.uniform(4, 10), y + rng.uniform(3, 7)],
                      fill=tuple(min(255, int(c * 1.25)) for c in base[0][:3]) + (140,))
    return im


for style in ("cave", "neon"):
    ground_strip(style, 55 + len(style)).save(f"{OUT}/ground_{style}.png")
    print("ground", style, "re-baked")
