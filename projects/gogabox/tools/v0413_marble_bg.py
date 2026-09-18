#!/usr/bin/env python3
"""
v0413 MARBLE POPPER ART FORGE (part 2: place backgrounds + previews input)
Generates 10 rich portrait place backgrounds 720x1600 by code (the rich-world
law): vertical mood gradient + far ridge + near ridge + themed decoration +
mood motes + vignette. Places double as difficulty tiers.
"""
import math, os, random
from PIL import Image, ImageDraw, ImageFilter

DST = "/home/z/my-project/gogabox/projects/gogabox/assets/games/marble"
os.makedirs(DST, exist_ok=True)
W, H = 720, 1600

PLACES = [
    ("mossy",    [(38, 80, 62), (24, 56, 46), (14, 34, 30)], (120, 200, 150), "shrine"),
    ("sun",      [(212, 150, 88), (150, 92, 60), (86, 48, 40)], (255, 214, 140), "dunes"),
    ("tide",     [(30, 110, 140), (18, 70, 104), (10, 40, 70)], (140, 220, 235), "water"),
    ("ember",    [(120, 46, 30), (74, 24, 24), (36, 12, 16)], (255, 150, 70), "lava"),
    ("frost",    [(150, 190, 215), (100, 140, 180), (60, 90, 140)], (235, 248, 255), "ice"),
    ("violet",   [(96, 60, 150), (60, 36, 100), (30, 18, 56)], (200, 150, 240), "crystal"),
    ("sky",      [(230, 140, 110), (160, 90, 120), (70, 44, 90)], (255, 210, 160), "clouds"),
    ("neon",     [(24, 26, 48), (16, 16, 34), (8, 8, 20)], (90, 240, 220), "neon"),
    ("obsidian", [(60, 52, 44), (36, 30, 26), (18, 14, 12)], (255, 200, 90), "gold"),
    ("cursed",   [(52, 30, 66), (30, 16, 44), (12, 6, 20)], (170, 90, 220), "gate"),
]


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vgrad(c_top, c_bot):
    im = Image.new("RGB", (W, H))
    px = im.load()
    for y in range(H):
        c = lerp(c_top, c_bot, y / H)
        for x in range(W):
            px[x, y] = c
    return im


def ridge(im, y_base, amp, color, seed, blur=2.0):
    rnd = random.Random(seed)
    pts = [(0, H)]
    x = 0
    while x <= W:
        y = y_base + math.sin(x * rnd.uniform(0.004, 0.010) + rnd.uniform(0, 6.28)) * amp \
            + math.sin(x * 0.021 + seed) * amp * 0.4
        pts.append((x, y))
        x += 24
    pts.append((W, H))
    d = ImageDraw.Draw(im)
    d.polygon(pts, fill=color)
    if blur:
        im.filter(ImageFilter.GaussianBlur(blur))


def deco_shrine(im, glow, rnd):
    d = ImageDraw.Draw(im, "RGBA")
    for i in range(9):
        x = rnd.uniform(30, W - 30)
        y = rnd.uniform(H * 0.55, H - 80)
        s = rnd.uniform(18, 46)
        d.polygon([(x, y - s), (x + s * 0.7, y), (x, y + s * 0.5), (x - s * 0.7, y)],
                  outline=glow + (150,), width=3)
    for i in range(14):  # hanging vines
        x = rnd.uniform(10, W - 10)
        ln = rnd.uniform(60, 220)
        d.line((x, 0, x + rnd.uniform(-30, 30), ln), fill=(20, 60, 40, 160), width=4)


def deco_dunes(im, glow, rnd):
    d = ImageDraw.Draw(im, "RGBA")
    d.ellipse((W * 0.58, H * 0.10, W * 0.58 + 150, H * 0.10 + 150), fill=(255, 230, 160, 90))
    for i in range(10):
        x = rnd.uniform(20, W - 20)
        y = rnd.uniform(H * 0.6, H - 60)
        s = rnd.uniform(12, 30)
        d.polygon([(x, y), (x + s, y - s * 2.2), (x + s * 2, y)], fill=(240, 200, 120, 70))


def deco_water(im, glow, rnd):
    d = ImageDraw.Draw(im, "RGBA")
    for i in range(12):  # light shafts
        x = rnd.uniform(0, W)
        d.polygon([(x, 0), (x + 60, 0), (x + 130, H), (x + 40, H)], fill=(180, 230, 245, 14))
    for i in range(10):  # bubbles
        x = rnd.uniform(30, W - 30)
        y = rnd.uniform(H * 0.3, H - 40)
        r = rnd.uniform(6, 16)
        d.ellipse((x - r, y - r, x + r, y + r), outline=glow + (120,), width=3)


def deco_lava(im, glow, rnd):
    d = ImageDraw.Draw(im, "RGBA")
    for i in range(9):  # lava cracks
        x = rnd.uniform(40, W - 40)
        y = rnd.uniform(H * 0.55, H - 40)
        pts = [(x, y)]
        for k in range(5):
            x += rnd.uniform(-60, 60)
            y += rnd.uniform(-30, 46)
            pts.append((x, y))
        d.line(pts, fill=glow + (150,), width=5)


def deco_ice(im, glow, rnd):
    d = ImageDraw.Draw(im, "RGBA")
    for i in range(12):  # ice spikes
        x = rnd.uniform(20, W - 20)
        y = rnd.uniform(H * 0.5, H - 30)
        s = rnd.uniform(24, 70)
        d.polygon([(x, y - s), (x + s * 0.4, y), (x - s * 0.4, y)], fill=(220, 242, 255, 60))
    for i in range(10):
        x = rnd.uniform(30, W - 30)
        y = rnd.uniform(60, H * 0.4)
        r = rnd.uniform(2, 5)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 255, 255, 130))


def deco_crystal(im, glow, rnd):
    d = ImageDraw.Draw(im, "RGBA")
    for i in range(12):
        x = rnd.uniform(30, W - 30)
        y = rnd.uniform(H * 0.5, H - 40)
        s = rnd.uniform(20, 54)
        a = rnd.uniform(0, 3.14)
        d.polygon([(x + math.cos(a) * s, y + math.sin(a) * s),
                   (x + math.cos(a + 2.1) * s, y + math.sin(a + 2.1) * s),
                   (x + math.cos(a + 4.2) * s, y + math.sin(a + 4.2) * s)],
                  outline=glow + (170,), width=3)


def deco_clouds(im, glow, rnd):
    d = ImageDraw.Draw(im, "RGBA")
    for i in range(8):
        x = rnd.uniform(0, W)
        y = rnd.uniform(H * 0.25, H * 0.9)
        s = rnd.uniform(60, 150)
        d.ellipse((x, y, x + s, y + s * 0.35), fill=(255, 220, 190, 40))
    for i in range(6):  # floating ruin blocks
        x = rnd.uniform(30, W - 90)
        y = rnd.uniform(H * 0.3, H * 0.85)
        d.rectangle((x, y, x + rnd.uniform(40, 90), y + rnd.uniform(24, 50)),
                    fill=(60, 40, 70, 160), outline=(20, 12, 26, 200), width=3)


def deco_neon(im, glow, rnd):
    d = ImageDraw.Draw(im, "RGBA")
    for i in range(9):  # glowing circuit lines
        x = rnd.uniform(20, W - 20)
        y = rnd.uniform(H * 0.4, H - 40)
        pts = [(x, y)]
        for k in range(4):
            if k % 2 == 0:
                x += rnd.uniform(-90, 90)
            else:
                y += rnd.uniform(-70, 70)
            pts.append((x, y))
        d.line(pts, fill=glow + (120,), width=3)


def deco_gold(im, glow, rnd):
    d = ImageDraw.Draw(im, "RGBA")
    for i in range(14):  # gold veins
        x = rnd.uniform(20, W - 20)
        y = rnd.uniform(H * 0.4, H - 30)
        pts = [(x, y)]
        for k in range(4):
            x += rnd.uniform(-50, 50)
            y += rnd.uniform(-36, 36)
            pts.append((x, y))
        d.line(pts, fill=glow + (110,), width=3)


def deco_gate(im, glow, rnd):
    d = ImageDraw.Draw(im, "RGBA")
    # the big gate arch silhouette
    gw, gh = W * 0.62, H * 0.5
    gx, gy = (W - gw) / 2, H * 0.30
    d.rectangle((gx, gy, gx + gw, gy + gh), outline=(30, 14, 40, 220), width=10)
    d.arc((gx, gy - gh * 0.5, gx + gw, gy + gh * 0.5), 180, 360, fill=(30, 14, 40, 220), width=10)
    for i in range(8):
        x = rnd.uniform(30, W - 30)
        y = rnd.uniform(H * 0.4, H - 40)
        r = rnd.uniform(3, 8)
        d.ellipse((x - r, y - r, x + r, y + r), fill=glow + (140,))


DECO = {"shrine": deco_shrine, "dunes": deco_dunes, "water": deco_water, "lava": deco_lava,
        "ice": deco_ice, "crystal": deco_crystal, "clouds": deco_clouds, "neon": deco_neon,
        "gold": deco_gold, "gate": deco_gate}

rnd = random.Random(4013)
for idx, (name, cols, glow, kind) in enumerate(PLACES):
    im = vgrad(cols[0], cols[2]).convert("RGBA")
    ridge(im, H * 0.34, 60, cols[1] + (255,), seed=idx * 7 + 1, blur=6.0)
    ridge(im, H * 0.52, 74, lerp(cols[1], (0, 0, 0), 0.35) + (255,), seed=idx * 7 + 2, blur=3.0)
    DECO[kind](im, glow, rnd)
    # mood motes
    d = ImageDraw.Draw(im, "RGBA")
    for i in range(26):
        x = rnd.uniform(0, W)
        y = rnd.uniform(0, H)
        r = rnd.uniform(1.5, 4.0)
        d.ellipse((x - r, y - r, x + r, y + r), fill=glow + (rnd.randint(40, 110),))
    # vignette: keep the middle readable (paths live everywhere)
    vin = Image.new("L", (W, H), 0)
    dv = ImageDraw.Draw(vin)
    dv.rectangle((W * 0.06, H * 0.03, W * 0.94, H * 0.97), fill=90)
    vin = vin.filter(ImageFilter.GaussianBlur(120))
    dark = Image.new("RGBA", (W, H), (6, 4, 10, 255))
    dark.putalpha(vin)
    im.alpha_composite(dark)
    im.convert("RGB").save(f"{DST}/bg_{idx}_{name}.png")
    print("bg", idx, name)
print("ART FORGE 2 DONE")
