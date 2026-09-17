#!/usr/bin/env python3
"""v040-10 ROCK BREAKER - the WORLD redo (the owner: "all places except
the cave have too ugly backgrounds, ugly as shit").

Every theme's five places get a REAL scenic far strip (1600x900): a
graded sky, a sun/moon with bloom, drifting cloud banks, THREE parallax
silhouette ridges (the theme's own skyline grammar), atmospheric haze
between the ridges, and ground detail on the near ridge. The bakes are
deterministic (fixed seeds). The CAVE keeps its seat but is re-baked to
match the new quality bar.

The strips draw cover-cropped above the ground line in-game - baked wide
so the crop never slices the scenery's subject.
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

OUT = ("/home/z/my-project/gogabox/projects/gogabox"
       "/assets/games/rockbreaker/world")
os.makedirs(OUT, exist_ok=True)

W, H = 1600, 900

# theme -> prefix + the five place palettes (sky top/bot, ridge1..3,
# glow, the skyline grammar)
THEMES = {
    "cave": {
        "places": [
            {"sky": ((43, 29, 20), (74, 51, 32)), "r1": (53, 36, 23),
             "r2": (36, 23, 14), "r3": (24, 15, 9), "deco": (85, 64, 42),
             "glow": None, "seed": 11, "gram": "stalag"},
            {"sky": ((20, 35, 42), (30, 58, 66)), "r1": (27, 47, 54),
             "r2": (18, 33, 40), "r3": (12, 21, 26), "deco": (61, 106, 116),
             "glow": (64, 212, 224), "seed": 27, "gram": "stalag"},
            {"sky": ((42, 18, 12), (87, 32, 15)), "r1": (67, 25, 13),
             "r2": (48, 17, 7), "r3": (30, 10, 5), "deco": (138, 74, 31),
             "glow": (255, 122, 33), "seed": 43, "gram": "stalag"},
            {"sky": ((26, 38, 52), (43, 66, 88)), "r1": (35, 52, 71),
             "r2": (24, 36, 48), "r3": (15, 23, 31), "deco": (111, 147, 173),
             "glow": (158, 217, 255), "seed": 58, "gram": "stalag"},
            {"sky": ((41, 33, 21), (69, 55, 25)), "r1": (58, 46, 20),
             "r2": (39, 31, 13), "r3": (25, 19, 8), "deco": (138, 109, 42),
             "glow": (255, 202, 61), "seed": 71, "gram": "stalag"},
        ]},
    "forest": {
        "places": [
            {"sky": ((143, 208, 239), (201, 236, 247)), "r1": (93, 158, 90),
             "r2": (63, 124, 66), "r3": (38, 82, 44), "deco": (47, 97, 52),
             "glow": None, "seed": 13, "gram": "pines"},
            {"sky": ((109, 183, 216), (168, 220, 234)), "r1": (47, 107, 58),
             "r2": (30, 77, 42), "r3": (18, 54, 28), "deco": (20, 51, 24),
             "glow": None, "seed": 29, "gram": "pines"},
            {"sky": ((232, 180, 106), (244, 217, 160)), "r1": (179, 112, 58),
             "r2": (138, 77, 40), "r3": (86, 48, 22), "deco": (194, 90, 42),
             "glow": (255, 156, 64), "seed": 47, "gram": "pines"},
            {"sky": ((124, 196, 224), (181, 228, 240)), "r1": (74, 138, 106),
             "r2": (47, 106, 76), "r3": (30, 70, 50), "deco": (42, 112, 96),
             "glow": None, "seed": 61, "gram": "pines"},
            {"sky": ((22, 35, 58), (36, 56, 92)), "r1": (28, 48, 64),
             "r2": (18, 34, 48), "r3": (12, 24, 36), "deco": (40, 80, 64),
             "glow": (180, 210, 255), "seed": 73, "gram": "pines"},
        ]},
    "pixel": {
        "places": [
            {"sky": ((70, 200, 220), (150, 240, 240)), "r1": (60, 170, 190),
             "r2": (44, 130, 160), "r3": (30, 90, 120), "deco": (250, 220, 90),
             "glow": None, "seed": 17, "gram": "blocks"},
            {"sky": ((240, 130, 90), (250, 200, 120)), "r1": (200, 90, 70),
             "r2": (150, 60, 60), "r3": (100, 40, 50), "deco": (250, 240, 160),
             "glow": (255, 230, 130), "seed": 31, "gram": "blocks"},
            {"sky": ((40, 44, 90), (70, 80, 140)), "r1": (60, 66, 120),
             "r2": (44, 50, 96), "r3": (30, 34, 70), "deco": (120, 240, 220),
             "glow": (140, 250, 230), "seed": 53, "gram": "blocks"},
            {"sky": ((250, 170, 200), (255, 220, 230)), "r1": (230, 140, 170),
             "r2": (190, 100, 140), "r3": (140, 70, 110), "deco": (255, 250, 200),
             "glow": None, "seed": 67, "gram": "blocks"},
            {"sky": ((30, 32, 40), (56, 60, 74)), "r1": (70, 74, 90),
             "r2": (52, 56, 70), "r3": (36, 40, 52), "deco": (240, 200, 80),
             "glow": (255, 210, 90), "seed": 79, "gram": "blocks"},
        ]},
    "neon": {
        "places": [
            {"sky": ((10, 6, 24), (26, 14, 54)), "r1": (40, 20, 80),
             "r2": (26, 12, 60), "r3": (14, 6, 40), "deco": (0, 240, 255),
             "glow": (0, 240, 255), "seed": 19, "gram": "towers"},
            {"sky": ((20, 4, 30), (48, 10, 70)), "r1": (70, 16, 100),
             "r2": (46, 10, 74), "r3": (28, 6, 52), "deco": (255, 60, 200),
             "glow": (255, 60, 200), "seed": 37, "gram": "towers"},
            {"sky": ((2, 20, 26), (6, 48, 56)), "r1": (8, 70, 80),
             "r2": (6, 50, 58), "r3": (4, 32, 38), "deco": (60, 255, 160),
             "glow": (60, 255, 160), "seed": 59, "gram": "towers"},
            {"sky": ((26, 6, 10), (60, 14, 22)), "r1": (86, 18, 28),
             "r2": (58, 12, 20), "r3": (36, 8, 14), "deco": (255, 90, 60),
             "glow": (255, 90, 60), "seed": 83, "gram": "towers"},
            {"sky": ((4, 8, 30), (12, 20, 66)), "r1": (20, 30, 90),
             "r2": (14, 20, 66), "r3": (8, 12, 46), "deco": (255, 220, 80),
             "glow": (255, 220, 80), "seed": 97, "gram": "towers"},
        ]},
    "candy": {
        "places": [
            {"sky": ((255, 214, 232), (255, 240, 246)), "r1": (250, 170, 200),
             "r2": (240, 140, 180), "r3": (220, 110, 160), "deco": (255, 250, 240),
             "glow": None, "seed": 23, "gram": "sweets"},
            {"sky": ((200, 236, 255), (240, 250, 255)), "r1": (160, 214, 240),
             "r2": (130, 190, 225), "r3": (100, 165, 205), "deco": (255, 255, 255),
             "glow": None, "seed": 41, "gram": "sweets"},
            {"sky": ((255, 190, 140), (255, 225, 180)), "r1": (245, 160, 110),
             "r2": (230, 130, 90), "r3": (205, 105, 75), "deco": (255, 240, 200),
             "glow": None, "seed": 71, "gram": "sweets"},
            {"sky": ((215, 180, 250), (240, 220, 255)), "r1": (200, 160, 240),
             "r2": (175, 135, 225), "r3": (150, 110, 200), "deco": (255, 250, 230),
             "glow": None, "seed": 89, "gram": "sweets"},
            {"sky": ((180, 235, 210), (225, 250, 240)), "r1": (150, 220, 190),
             "r2": (120, 195, 170), "r3": (95, 170, 150), "deco": (255, 255, 240),
             "glow": None, "seed": 101, "gram": "sweets"},
        ]},
}


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def sky_band(p):
    """vertical gradient + a soft sun with bloom + drifting cloud banks."""
    im = Image.new("RGB", (W, H))
    top, bot = p["sky"]
    for y in range(H):
        t = y / H
        # the gradient eases toward the bottom (the horizon glows)
        tt = t ** 1.25
        im.paste(lerp(bot, top, tt), (0, y, W, y + 1))
    d = ImageDraw.Draw(im, "RGBA")
    # the sun/moon
    glow = p["glow"]
    sx, sy = int(W * 0.74), int(H * 0.2)
    if glow:
        col = glow + (255,)
        core = tuple(min(255, int(c * 0.55) + 200) for c in glow)
        for r, a in [(210, 26), (140, 40), (86, 70), (52, 120)]:
            d.ellipse([sx - r, sy - r, sx + r, sy + r],
                      fill=tuple(glow) + (a,))
        d.ellipse([sx - 34, sy - 34, sx + 34, sy + 34], fill=core + (235,))
    else:
        # a pale sun disc with a soft halo
        for r, a in [(150, 22), (96, 36), (60, 60)]:
            d.ellipse([sx - r, sy - r, sx + r, sy + r],
                      fill=(255, 246, 220, a))
        d.ellipse([sx - 30, sy - 30, sx + 30, sy + 30],
                  fill=(255, 250, 232, 240))
    # the cloud banks: soft rounded clumps, brighter than the sky behind
    rnd = random.Random(p["seed"] * 7 + 3)
    cl = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cd = ImageDraw.Draw(cl)
    for i in range(9):
        cy = int(H * (0.12 + 0.38 * rnd.random()))
        cw = int(W * rnd.uniform(0.22, 0.5))
        cx = int(W * rnd.uniform(-0.1, 1.0))
        bright = 236 if glow else 252
        col = (bright, bright, min(255, bright + 8), rnd.randint(50, 92))
        for k in range(6):
            rx = cx + int(k * cw / 6.5)
            rr = int(H * rnd.uniform(0.03, 0.062))
            cd.ellipse([rx, cy - rr, rx + int(cw / 3.2), cy + rr], fill=col)
    cl = cl.filter(ImageFilter.GaussianBlur(9))
    im = Image.alpha_composite(im.convert("RGBA"), cl)
    return im


def ridge(p, base_y, amp, col, gram, rnd, detail=True):
    """one silhouette ridge as an RGBA layer."""
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    col = col + (255,)
    if gram == "stalag":
        # jagged stalagmite/stalactite stone
        pts = [(0, H), (0, base_y)]
        x = 0
        up = True
        while x < W:
            w = rnd.randint(60, 150)
            if up:
                peak = base_y - rnd.randint(amp // 2, amp)
                pts.append((x + w // 2, peak))
                pts.append((x + w, base_y - rnd.randint(0, amp // 3)))
            else:
                pts.append((x + w // 2, base_y - rnd.randint(0, amp // 4)))
            up = not up
            x += w
        pts.append((W, base_y))
        pts.append((W, H))
        d.polygon(pts, fill=col)
        # hanging spikes from the top (a cave's roof)
        for i in range(14):
            rx = rnd.randint(0, W)
            rw = rnd.randint(18, 60)
            rh = rnd.randint(60, 260)
            d.polygon([(rx, 0), (rx + rw, 0), (rx + rw // 2, rh)], fill=col)
    elif gram == "pines":
        # rolling hills wearing triangle pines
        pts = [(0, H)]
        x = 0
        y = base_y
        while x < W:
            nx = x + rnd.randint(120, 260)
            ny = base_y + rnd.randint(-amp // 2, amp // 2)
            pts.append((nx, ny))
            x, y = nx, ny
        pts.append((W, H))
        d.polygon(pts, fill=col)
        for i in range(int(W / 46)):
            tx = rnd.randint(0, W)
            ty = base_y + rnd.randint(-amp // 3, amp // 3)
            th = rnd.randint(70, 190)
            tw = th // 2
            d.polygon([(tx - tw // 2, ty), (tx + tw // 2, ty),
                       (tx, ty - th)], fill=col)
    elif gram == "blocks":
        # stepped block mesas (the pixel grammar)
        bs = 40
        y = base_y
        for bx in range(0, W, bs):
            y = max(H * 0.25, min(H * 0.9,
                    y + rnd.choice([-bs, -bs, 0, bs, bs])))
            hh = H - y
            d.rectangle([bx, y, bx + bs, H], fill=col)
            if detail and rnd.random() < 0.3:
                hi = tuple(min(255, int(c * 1.2)) for c in col[:3]) + (255,)
                d.rectangle([bx, y, bx + bs, y + 8], fill=hi)
    elif gram == "towers":
        # the city grammar: windowed towers + antennas
        x = 0
        while x < W:
            tw = rnd.randint(70, 190)
            th = rnd.randint(amp // 2, amp)
            ty = base_y - th
            d.rectangle([x, ty, x + tw, H], fill=col)
            # the antenna
            if rnd.random() < 0.4:
                ax = x + tw // 2
                d.line([(ax, ty), (ax, ty - rnd.randint(30, 90))],
                       fill=col, width=4)
            # the windows (the deco color, sparse)
            wc = p["deco"] + (150,)
            for wy in range(ty + 14, H - 20, 26):
                for wx in range(x + 10, x + tw - 10, 22):
                    if rnd.random() < 0.28:
                        d.rectangle([wx, wy, wx + 8, wy + 12], fill=wc)
            x += tw + rnd.randint(10, 60)
    else:  # sweets: soft rounded hills + lollipops
        pts = [(0, H)]
        x = 0
        while x < W:
            nx = x + rnd.randint(140, 300)
            ny = base_y + rnd.randint(-amp // 3, amp // 3)
            pts.append((nx, ny))
            x = nx
        pts.append((W, H))
        d.polygon(pts, fill=col)
        for i in range(int(W / 220)):
            cx = rnd.randint(0, W)
            cy = base_y - rnd.randint(10, 60)
            rr = rnd.randint(26, 60)
            stick = tuple(min(255, int(c * 1.15)) for c in col[:3]) + (255,)
            d.rectangle([cx - 4, cy, cx + 4, cy + 90], fill=stick)
            d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=col)
            d.ellipse([cx - rr // 2, cy - rr // 2, cx + rr // 2, cy + rr // 2],
                      fill=stick)
    return im


def haze(im, y0, y1, col, a):
    """an atmospheric band (the depth haze between ridges)."""
    band = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(band)
    d.rectangle([0, y0, W, y1], fill=col + (a,))
    band = band.filter(ImageFilter.GaussianBlur(40))
    return Image.alpha_composite(im, band)


def bake_place(theme, p):
    rnd = random.Random(p["seed"])
    im = sky_band(p)
    # three ridges, far to near, sinking into haze
    im = Image.alpha_composite(im, ridge(p, int(H * 0.62), 220,
            p["r1"], p["gram"], rnd, detail=False))
    im = haze(im, int(H * 0.5), H, p["sky"][0], 60)
    im = Image.alpha_composite(im, ridge(p, int(H * 0.74), 190,
            p["r2"], p["gram"], rnd, detail=False))
    im = haze(im, int(H * 0.62), H, p["sky"][0], 46)
    im = Image.alpha_composite(im, ridge(p, int(H * 0.88), 150,
            p["r3"], p["gram"], rnd, detail=True))
    # a gentle vignette seats the scene
    vig = Image.new("L", (W, H), 0)
    vd = ImageDraw.Draw(vig)
    vd.ellipse([-W * 0.25, -H * 0.3, W * 1.25, H * 1.3], fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(120))
    dark = Image.new("RGBA", (W, H), (8, 6, 10, 255))
    inv = vig.point(lambda v: 255 - v)
    dark.putalpha(inv.point(lambda v: int(v * 0.24)))
    im = Image.alpha_composite(im, dark)
    return im


def main():
    for theme, cfg in THEMES.items():
        for i, p in enumerate(cfg["places"]):
            im = bake_place(theme, p)
            im.convert("RGB").save(f"{OUT}/far_{theme}_{i}.png")
            print(f"far_{theme}_{i}.png")
    print("WORLD REDO DONE")


if __name__ == "__main__":
    main()
