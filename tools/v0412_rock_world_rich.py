#!/usr/bin/env python3
"""v040-12 ROCK BREAKER - THE RICH WORLD LAW (the owner: "work harder on
the places/themes design because they are ugly, not just make them
brighter, make them more rich in design").

What changed vs v0410:
- the strips bake PORTRAIT (1200x2000, the cover-crop's real aspect) so
  the whole composition is SEEN - the old 1600x900 bake had ~2/3 of its
  width sliced off by the cover-crop;
- FOUR ridge depths with per-theme decoration: cave = crystals + glow
  mushrooms + hanging roots; forest = light shafts + mist + flowers;
  pixel = stepped mesas + floating islands + blocky waterfalls; neon =
  window grids + light beams + horizon glow; candy = icing drips +
  lollipops + gumdrops + sprinkle dust;
- dark skies wear real stars; every theme gets its own dust/sparkle
  mood layer;
- the GROUND is re-baked rich (strata, lip, pebbles, cracks, veins -
  per theme material);
- the side WALLS become baked textures (wall_<theme>.png) instead of
  flat color slivers;
- the place-cut whoosh (rb_place.wav) rides with the VEIL CUT.

Deterministic (fixed seeds). Idempotent - overwrites its own outputs.
"""
import math
import os
import random
import struct
import wave

from PIL import Image, ImageDraw, ImageFilter

OUT = ("/home/z/my-project/gogabox/projects/gogabox"
       "/assets/games/rockbreaker/world")
SFX = ("/home/z/my-project/gogabox/projects/gogabox"
       "/assets/audio/sfx")
os.makedirs(OUT, exist_ok=True)

W, H = 1200, 2000          # portrait - the cover-crop's real shape
GW, GH = 1200, 240         # the ground strip
WW, WH = 44, 2400          # the side wall


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def lum(c):
    return 0.2126 * c[0] / 255 + 0.7152 * c[1] / 255 + 0.0722 * c[2] / 255


def lift(c, target=0.21):
    l = max(lum(c), 0.004)
    if l >= target:
        return c
    f = min(2.6, target / l)
    return tuple(min(255, int(round(v * f))) for v in c)


def shade(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c)


# ----------------------------------------------------------------- palettes
# (lifted cave/neon ride through lift() at bake time, the v0411 law)
THEMES = {
    "cave": [
        {"sky": ((43, 29, 20), (74, 51, 32)), "r1": (53, 36, 23),
         "r2": (36, 23, 14), "r3": (24, 15, 9), "deco": (85, 64, 42),
         "glow": None, "seed": 11, "gram": "stalag", "mood": "dust"},
        {"sky": ((20, 35, 42), (30, 58, 66)), "r1": (27, 47, 54),
         "r2": (18, 33, 40), "r3": (12, 21, 26), "deco": (61, 106, 116),
         "glow": (64, 212, 224), "seed": 27, "gram": "stalag",
         "mood": "dust"},
        {"sky": ((42, 18, 12), (87, 32, 15)), "r1": (67, 25, 13),
         "r2": (48, 17, 7), "r3": (30, 10, 5), "deco": (138, 74, 31),
         "glow": (255, 122, 33), "seed": 43, "gram": "stalag",
         "mood": "ember"},
        {"sky": ((26, 38, 52), (43, 66, 88)), "r1": (35, 52, 71),
         "r2": (24, 36, 48), "r3": (15, 23, 31), "deco": (111, 147, 173),
         "glow": (158, 217, 255), "seed": 58, "gram": "stalag",
         "mood": "dust"},
        {"sky": ((41, 33, 21), (69, 55, 25)), "r1": (58, 46, 20),
         "r2": (39, 31, 13), "r3": (25, 19, 8), "deco": (138, 109, 42),
         "glow": (255, 202, 61), "seed": 71, "gram": "stalag",
         "mood": "ember"},
    ],
    "forest": [
        {"sky": ((143, 208, 239), (201, 236, 247)), "r1": (93, 158, 90),
         "r2": (63, 124, 66), "r3": (38, 82, 44), "deco": (47, 97, 52),
         "glow": None, "seed": 13, "gram": "pines", "mood": "petals"},
        {"sky": ((109, 183, 216), (168, 220, 234)), "r1": (47, 107, 58),
         "r2": (30, 77, 42), "r3": (18, 54, 28), "deco": (20, 51, 24),
         "glow": None, "seed": 29, "gram": "pines", "mood": "petals"},
        {"sky": ((232, 180, 106), (244, 217, 160)), "r1": (179, 112, 58),
         "r2": (138, 77, 40), "r3": (86, 48, 22), "deco": (194, 90, 42),
         "glow": (255, 156, 64), "seed": 47, "gram": "pines",
         "mood": "dust"},
        {"sky": ((124, 196, 224), (181, 228, 240)), "r1": (74, 138, 106),
         "r2": (47, 106, 76), "r3": (30, 70, 50), "deco": (42, 112, 96),
         "glow": None, "seed": 61, "gram": "pines", "mood": "petals"},
        {"sky": ((22, 35, 58), (36, 56, 92)), "r1": (28, 48, 64),
         "r2": (18, 34, 48), "r3": (12, 24, 36), "deco": (40, 80, 64),
         "glow": (180, 210, 255), "seed": 73, "gram": "pines",
         "mood": "fireflies"},
    ],
    "pixel": [
        {"sky": ((70, 200, 220), (150, 240, 240)), "r1": (60, 170, 190),
         "r2": (44, 130, 160), "r3": (30, 90, 120), "deco": (250, 220, 90),
         "glow": None, "seed": 17, "gram": "blocks", "mood": "sparks"},
        {"sky": ((240, 130, 90), (250, 200, 120)), "r1": (200, 90, 70),
         "r2": (150, 60, 60), "r3": (100, 40, 50), "deco": (250, 240, 160),
         "glow": (255, 230, 130), "seed": 31, "gram": "blocks",
         "mood": "sparks"},
        {"sky": ((40, 44, 90), (70, 80, 140)), "r1": (60, 66, 120),
         "r2": (44, 50, 96), "r3": (30, 34, 70), "deco": (120, 240, 220),
         "glow": (140, 250, 230), "seed": 53, "gram": "blocks",
         "mood": "sparks"},
        {"sky": ((250, 170, 200), (255, 220, 230)), "r1": (230, 140, 170),
         "r2": (190, 100, 140), "r3": (140, 70, 110), "deco": (255, 250, 200),
         "glow": None, "seed": 67, "gram": "blocks", "mood": "petals"},
        {"sky": ((30, 32, 40), (56, 60, 74)), "r1": (70, 74, 90),
         "r2": (52, 56, 70), "r3": (36, 40, 52), "deco": (240, 200, 80),
         "glow": (255, 210, 90), "seed": 79, "gram": "blocks",
         "mood": "sparks"},
    ],
    "neon": [
        {"sky": ((10, 6, 24), (26, 14, 54)), "r1": (40, 20, 80),
         "r2": (26, 12, 60), "r3": (14, 6, 40), "deco": (0, 240, 255),
         "glow": (0, 240, 255), "seed": 19, "gram": "towers",
         "mood": "rain"},
        {"sky": ((20, 4, 30), (48, 10, 70)), "r1": (70, 16, 100),
         "r2": (46, 10, 74), "r3": (28, 6, 52), "deco": (255, 60, 200),
         "glow": (255, 60, 200), "seed": 37, "gram": "towers",
         "mood": "rain"},
        {"sky": ((2, 20, 26), (6, 48, 56)), "r1": (8, 70, 80),
         "r2": (6, 50, 58), "r3": (4, 32, 38), "deco": (60, 255, 160),
         "glow": (60, 255, 160), "seed": 59, "gram": "towers",
         "mood": "rain"},
        {"sky": ((26, 6, 10), (60, 14, 22)), "r1": (86, 18, 28),
         "r2": (58, 12, 20), "r3": (36, 8, 14), "deco": (255, 90, 60),
         "glow": (255, 90, 60), "seed": 83, "gram": "towers",
         "mood": "ember"},
        {"sky": ((4, 8, 30), (12, 20, 66)), "r1": (20, 30, 90),
         "r2": (14, 20, 66), "r3": (8, 12, 46), "deco": (255, 220, 80),
         "glow": (255, 220, 80), "seed": 97, "gram": "towers",
         "mood": "rain"},
    ],
    "candy": [
        {"sky": ((255, 214, 232), (255, 240, 246)), "r1": (250, 170, 200),
         "r2": (240, 140, 180), "r3": (220, 110, 160), "deco": (255, 250, 240),
         "glow": None, "seed": 23, "gram": "sweets", "mood": "sprinkle"},
        {"sky": ((200, 236, 255), (240, 250, 255)), "r1": (160, 214, 240),
         "r2": (130, 190, 225), "r3": (100, 165, 205), "deco": (255, 255, 255),
         "glow": None, "seed": 41, "gram": "sweets", "mood": "sprinkle"},
        {"sky": ((255, 190, 140), (255, 225, 180)), "r1": (245, 160, 110),
         "r2": (230, 130, 90), "r3": (205, 105, 75), "deco": (255, 240, 200),
         "glow": None, "seed": 71, "gram": "sweets", "mood": "sprinkle"},
        {"sky": ((215, 180, 250), (240, 220, 255)), "r1": (200, 160, 240),
         "r2": (175, 135, 225), "r3": (150, 110, 200), "deco": (255, 250, 230),
         "glow": None, "seed": 89, "gram": "sweets", "mood": "sprinkle"},
        {"sky": ((180, 235, 210), (225, 250, 240)), "r1": (150, 220, 190),
         "r2": (120, 195, 170), "r3": (95, 170, 150), "deco": (255, 255, 240),
         "glow": None, "seed": 101, "gram": "sweets", "mood": "sprinkle"},
    ],
}


# ------------------------------------------------------------------- sky
def sky_band(p):
    im = Image.new("RGB", (W, H))
    top, bot = p["sky"]
    for y in range(H):
        t = (y / H) ** 1.25
        im.paste(lerp(bot, top, t), (0, y, W, y + 1))
    d = ImageDraw.Draw(im, "RGBA")
    dark = lum(top) < 0.22
    rnd = random.Random(p["seed"] * 3 + 1)
    # STARS for the dark skies (twinkle sizes, a few big)
    if dark:
        for i in range(90):
            x = rnd.randint(0, W)
            y = rnd.randint(0, int(H * 0.55))
            r = rnd.choice([1, 1, 1, 2, 2, 3])
            a = rnd.randint(90, 200)
            d.ellipse([x - r, y - r, x + r, y + r],
                      fill=(235, 240, 255, a))
    # the sun/moon
    glow = p["glow"]
    sx, sy = int(W * 0.72), int(H * 0.16)
    if glow:
        core = tuple(min(255, int(c * 0.55) + 200) for c in glow)
        for r, a in [(260, 22), (170, 38), (104, 64), (62, 110)]:
            d.ellipse([sx - r, sy - r, sx + r, sy + r],
                      fill=tuple(glow) + (a,))
        d.ellipse([sx - 40, sy - 40, sx + 40, sy + 40], fill=core + (235,))
    else:
        for r, a in [(190, 20), (120, 34), (74, 56)]:
            d.ellipse([sx - r, sy - r, sx + r, sy + r],
                      fill=(255, 246, 220, a))
        d.ellipse([sx - 36, sy - 36, sx + 36, sy + 36],
                  fill=(255, 250, 232, 240))
        if dark:
            # the moon wears a crater or two
            d.ellipse([sx - 14, sy - 18, sx + 2, sy - 2],
                      fill=(228, 226, 214, 90))
            d.ellipse([sx + 4, sy + 2, sx + 16, sy + 14],
                      fill=(228, 226, 214, 70))
    # cloud banks: two depths - far wisps + near puffs
    cl = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cd = ImageDraw.Draw(cl)
    for i in range(7):
        cy = int(H * (0.05 + 0.24 * rnd.random()))
        cw = int(W * rnd.uniform(0.16, 0.34))
        cx = int(W * rnd.uniform(-0.1, 0.95))
        a = rnd.randint(26, 44)
        col = (240, 244, 252, a)
        for k in range(5):
            rx = cx + int(k * cw / 5.5)
            rr = int(H * rnd.uniform(0.012, 0.022))
            cd.ellipse([rx, cy - rr, rx + int(cw / 3), cy + rr], fill=col)
    cl = cl.filter(ImageFilter.GaussianBlur(7))
    im = Image.alpha_composite(im.convert("RGBA"), cl)
    cl2 = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cd = ImageDraw.Draw(cl2)
    for i in range(5):
        cy = int(H * (0.18 + 0.3 * rnd.random()))
        cw = int(W * rnd.uniform(0.2, 0.42))
        cx = int(W * rnd.uniform(-0.08, 0.9))
        bright = 234 if glow else 250
        col = (bright, bright, min(255, bright + 8), rnd.randint(54, 84))
        for k in range(6):
            rx = cx + int(k * cw / 6.5)
            rr = int(H * rnd.uniform(0.02, 0.045))
            cd.ellipse([rx, cy - rr, rx + int(cw / 3.2), cy + rr], fill=col)
    cl2 = cl2.filter(ImageFilter.GaussianBlur(10))
    im = Image.alpha_composite(im, cl2)
    return im


# ------------------------------------------------------------------ ridges
def _ridge_poly(d, base_y, amp, col, rnd, jag=120):
    pts = [(0, H), (0, base_y)]
    x = 0
    up = True
    while x < W:
        w = rnd.randint(jag // 2, jag)
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


def ridge_layer(p, base_y, amp, col, gram, rnd, depth):
    """one ridge as an RGBA layer; depth 0=far .. 3=near."""
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = col + (255,)
    hi = shade(col, 1.28) + (255,)
    lo = shade(col, 0.72) + (255,)
    if gram == "stalag":
        _ridge_poly(d, base_y, amp, col, rnd, jag=150)
        # rim light on the peaks (the moon/glow side)
        pts = [(0, base_y)]
        x = 0
        while x < W:
            w = rnd.randint(70, 150)
            peak = base_y - rnd.randint(amp // 2, amp)
            d.line([(x, base_y - rnd.randint(0, amp // 3)),
                    (x + w // 2, peak)], fill=hi, width=3)
            x += w
        # hanging spikes from the top (the cave roof)
        for i in range(16):
            rx = rnd.randint(0, W)
            rw = rnd.randint(16, 54)
            rh = rnd.randint(50, 200)
            d.polygon([(rx, 0), (rx + rw, 0), (rx + rw // 2, rh)], fill=c)
        # CRYSTAL CLUSTERS on the mid+near ridges
        if depth >= 2:
            gc = p["glow"] or p["deco"]
            for i in range(9 if depth == 2 else 14):
                bx = rnd.randint(10, W - 10)
                by = base_y + rnd.randint(-amp // 4, amp // 6)
                n = rnd.randint(2, 4)
                for j in range(n):
                    sw = rnd.randint(5, 13)
                    sh = rnd.randint(18, 56)
                    lean = rnd.randint(-10, 10)
                    tip = (bx + lean, by - sh)
                    d.polygon([(bx - sw, by), (bx + sw, by), tip],
                              fill=gc + (235,))
                    d.line([(bx, by), tip], fill=(255, 255, 255, 120),
                           width=2)
        # GLOW MUSHROOMS on the near ridge
        if depth == 3:
            gc = p["glow"] or p["deco"]
            for i in range(12):
                mx = rnd.randint(8, W - 8)
                my = base_y + rnd.randint(-10, amp // 5)
                st = rnd.randint(8, 18)
                capr = rnd.randint(5, 10)
                d.line([(mx, my), (mx, my - st)], fill=lo, width=3)
                d.ellipse([mx - capr, my - st - capr, mx + capr,
                           my - st + capr], fill=gc + (220,))
                d.ellipse([mx - capr // 2, my - st - capr // 2,
                           mx + capr // 2, my - st + capr // 2],
                          fill=(255, 255, 255, 90))
    elif gram == "pines":
        # rolling hills
        pts = [(0, H)]
        x = 0
        y = base_y
        while x < W:
            nx = x + rnd.randint(120, 260)
            ny = base_y + rnd.randint(-amp // 2, amp // 2)
            pts.append((nx, ny))
            x, y = nx, ny
        pts.append((W, H))
        d.polygon(pts, fill=c)
        # pines: far ridges read as textured triangles, near pines show
        # trunk + layered canopy + snow/sun rim
        n = int(W / (46 if depth < 2 else 34))
        for i in range(n):
            tx = rnd.randint(0, W)
            ty = base_y + rnd.randint(-amp // 3, amp // 3)
            th = rnd.randint(70, 190) if depth < 3 \
                else rnd.randint(120, 250)
            tw = th // 2
            d.polygon([(tx - tw // 2, ty), (tx + tw // 2, ty),
                       (tx, ty - th)], fill=c)
            if depth >= 2:
                d.polygon([(tx - tw // 3, ty - th // 3),
                           (tx + tw // 3, ty - th // 3), (tx, ty - th)],
                          fill=hi)
                d.line([(tx - 2, ty), (tx - 2, ty - th // 4)],
                       fill=lo, width=3)
        # light shafts on the day places
        if depth == 0 and lum(p["sky"][0]) > 0.4:
            shaft = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            sd = ImageDraw.Draw(shaft)
            for i in range(4):
                sx = rnd.randint(0, W)
                sw = rnd.randint(60, 150)
                sd.polygon([(sx, 0), (sx + sw, 0), (sx + sw + 260, base_y + 300),
                            (sx - 120, base_y + 300)],
                           fill=(255, 250, 220, 22))
            shaft = shaft.filter(ImageFilter.GaussianBlur(26))
            im = Image.alpha_composite(im, shaft)
    elif gram == "blocks":
        bs = 44
        y = base_y
        for bx in range(0, W, bs):
            y = max(H * 0.2, min(H * 0.92,
                    y + rnd.choice([-bs, -bs, 0, bs, bs])))
            d.rectangle([bx, y, bx + bs, H], fill=c)
            d.rectangle([bx, y, bx + bs, y + 9], fill=hi)
            d.rectangle([bx + bs - 7, y, bx + bs, H], fill=lo)
            if rnd.random() < 0.22 and depth >= 1:
                # a window/dot block
                d.rectangle([bx + 10, y + 22, bx + 30, y + 40],
                            fill=p["deco"] + (170,))
        # FLOATING ISLANDS on the far depth
        if depth <= 1:
            for i in range(3):
                ix = rnd.randint(60, W - 120)
                iy = rnd.randint(int(H * 0.08), int(H * 0.3))
                iw = rnd.randint(70, 150)
                ih = rnd.randint(24, 44)
                d.rectangle([ix, iy, ix + iw, iy + ih], fill=c)
                d.rectangle([ix, iy, ix + iw, iy + 8], fill=hi)
                d.polygon([(ix + 6, iy + ih), (ix + iw - 6, iy + ih),
                           (ix + iw // 2, iy + ih + ih // 2)], fill=c)
        # a blocky waterfall on a near mesa
        if depth == 3:
            fx = rnd.randint(W // 4, 3 * W // 4)
            fw = 26
            fy = base_y - rnd.randint(60, 120)
            for yy in range(fy, H, 8):
                cc = (200, 240, 255) if lum(p["sky"][0]) < 0.5 \
                    else (150, 210, 250)
                d.rectangle([fx + (yy // 8 % 2) * 6, yy,
                             fx + fw + (yy // 8 % 2) * 6, yy + 8],
                            fill=cc + (150,))
    elif gram == "towers":
        x = 0
        while x < W:
            tw = rnd.randint(70, 190)
            th = rnd.randint(amp // 2, amp)
            ty = base_y - th
            d.rectangle([x, ty, x + tw, H], fill=c)
            d.rectangle([x, ty, x + tw, ty + 5], fill=hi)
            if rnd.random() < 0.4:
                ax = x + tw // 2
                ah = rnd.randint(30, 90)
                d.line([(ax, ty), (ax, ty - ah)], fill=c, width=4)
                # the antenna's beacon
                d.ellipse([ax - 4, ty - ah - 8, ax + 4, ty - ah],
                          fill=p["deco"] + (220,))
            wc = p["deco"] + (150,)
            for wy in range(ty + 14, H - 20, 26):
                for wx in range(x + 10, x + tw - 10, 22):
                    if rnd.random() < 0.28:
                        d.rectangle([wx, wy, wx + 8, wy + 12], fill=wc)
            # the neon edge light down one side
            d.line([(x + 2, ty), (x + 2, H)], fill=p["deco"] + (110,),
                   width=2)
            x += tw + rnd.randint(10, 60)
        if depth == 0:
            # a horizon glow line + light beams between the towers
            d.rectangle([0, base_y - 2, W, base_y + 2],
                        fill=p["deco"] + (70,))
            for i in range(3):
                bx = rnd.randint(0, W)
                by = base_y - rnd.randint(amp // 2, amp)
                beam = Image.new("RGBA", (W, H), (0, 0, 0, 0))
                bd = ImageDraw.Draw(beam)
                bd.line([(0, base_y - 40), (bx, by)],
                        fill=p["deco"] + (36,), width=6)
                beam = beam.filter(ImageFilter.GaussianBlur(6))
                im = Image.alpha_composite(im, beam)
    else:  # sweets
        pts = [(0, H)]
        x = 0
        while x < W:
            nx = x + rnd.randint(140, 300)
            ny = base_y + rnd.randint(-amp // 3, amp // 3)
            pts.append((nx, ny))
            x = nx
        pts.append((W, H))
        d.polygon(pts, fill=c)
        # the ICING DRIP lip along the hill's top edge
        drip = shade(col, 1.22) + (255,)
        for i in range(int(W / 26)):
            dx = i * 26 + rnd.randint(-4, 4)
            dy = base_y + rnd.randint(-amp // 4, amp // 4)
            dr = rnd.randint(6, 16)
            d.ellipse([dx - dr, dy - dr, dx + dr, dy + dr], fill=drip)
        # lollipops / gumdrops / canes on the near depth
        if depth == 3:
            for i in range(int(W / 190)):
                cx2 = rnd.randint(0, W)
                cy2 = base_y - rnd.randint(10, 60)
                rr = rnd.randint(26, 60)
                stick = shade(col, 1.15) + (255,)
                d.rectangle([cx2 - 5, cy2, cx2 + 5, cy2 + 100], fill=stick)
                d.ellipse([cx2 - rr, cy2 - rr, cx2 + rr, cy2 + rr],
                          fill=c)
                d.ellipse([cx2 - rr // 2, cy2 - rr // 2,
                           cx2 + rr // 2, cy2 + rr // 2], fill=drip)
            for i in range(int(W / 120)):
                gx = rnd.randint(0, W)
                gy = base_y + rnd.randint(-amp // 5, amp // 5)
                gr = rnd.randint(14, 30)
                gc = rnd.choice([shade(col, 0.8), shade(col, 1.3),
                                 p["deco"]])
                d.ellipse([gx - gr, gy - gr, gx + gr, gy + gr],
                          fill=gc + (255,))
                d.ellipse([gx - gr // 2, gy - gr - gr // 3,
                           gx + gr // 2, gy - gr // 3],
                          fill=(255, 255, 255, 80))
    return im


def haze(im, y0, y1, col, a):
    band = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(band)
    d.rectangle([0, y0, W, y1], fill=col + (a,))
    band = band.filter(ImageFilter.GaussianBlur(50))
    return Image.alpha_composite(im, band)


def mood_layer(p, rnd):
    """the theme's floating mood: dust / embers / petals / sparks /
    fireflies / rain / sprinkles."""
    kind = p["mood"]
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    gc = p["glow"] or (255, 250, 230)
    if kind == "dust":
        for i in range(70):
            x, y = rnd.randint(0, W), rnd.randint(0, H)
            r = rnd.choice([1, 1, 2])
            d.ellipse([x - r, y - r, x + r, y + r],
                      fill=gc + (rnd.randint(24, 60),))
    elif kind == "ember":
        for i in range(60):
            x, y = rnd.randint(0, W), rnd.randint(int(H * 0.3), H)
            r = rnd.choice([1, 2, 2, 3])
            d.ellipse([x - r, y - r, x + r, y + r],
                      fill=(255, rnd.randint(120, 190), 40,
                            rnd.randint(60, 130),))
    elif kind == "petals":
        for i in range(46):
            x, y = rnd.randint(0, W), rnd.randint(0, int(H * 0.8))
            s = rnd.choice([3, 4, 5])
            col = rnd.choice([(255, 190, 210, 120), (255, 220, 160, 110),
                              (220, 240, 255, 100)])
            d.polygon([(x, y - s), (x + s, y), (x, y + s), (x - s, y)],
                      fill=col)
    elif kind == "sparks":
        for i in range(60):
            x, y = rnd.randint(0, W), rnd.randint(0, H)
            s = rnd.choice([2, 3, 4])
            d.rectangle([x, y, x + s, y + s],
                        fill=p["deco"] + (rnd.randint(50, 110),))
    elif kind == "fireflies":
        for i in range(40):
            x, y = rnd.randint(0, W), rnd.randint(int(H * 0.35), H)
            r = rnd.choice([2, 2, 3])
            d.ellipse([x - r, y - r, x + r, y + r],
                      fill=(210, 255, 150, rnd.randint(80, 160),))
    elif kind == "rain":
        for i in range(90):
            x, y = rnd.randint(0, W), rnd.randint(0, H)
            ln = rnd.randint(8, 22)
            d.line([(x, y), (x - 3, y + ln)],
                   fill=(190, 220, 255, rnd.randint(26, 56),), width=2)
    else:  # sprinkle
        for i in range(80):
            x, y = rnd.randint(0, W), rnd.randint(0, int(H * 0.75))
            col = rnd.choice([(255, 120, 160), (120, 200, 255),
                              (255, 210, 90), (150, 230, 150)])
            d.line([(x, y), (x + 6, y + 2)],
                   fill=col + (rnd.randint(70, 130),), width=3)
    return im


def bake_place(p):
    rnd = random.Random(p["seed"])
    im = sky_band(p)
    depths = [
        (0.56, 260, p["r1"], False),
        (0.70, 220, p["r2"], False),
        (0.82, 180, p["r3"], True),
        (0.93, 130, shade(p["r3"], 0.82), True),
    ]
    for di, (fy, amp, col, det) in enumerate(depths):
        im = Image.alpha_composite(im, ridge_layer(
            p, int(H * fy), amp, col, p["gram"], rnd, di))
        if di < 3:
            im = haze(im, int(H * fy) - 60, H, p["sky"][0],
                      52 - di * 10)
    im = Image.alpha_composite(im, mood_layer(p, rnd))
    # the vignette seats the scene
    vig = Image.new("L", (W, H), 0)
    vd = ImageDraw.Draw(vig)
    vd.ellipse([-W * 0.25, -H * 0.3, W * 1.25, H * 1.3], fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(140))
    dark = Image.new("RGBA", (W, H), (8, 6, 10, 255))
    inv = vig.point(lambda v: 255 - v)
    dark.putalpha(inv.point(lambda v: int(v * 0.22)))
    return Image.alpha_composite(im, dark)


# ------------------------------------------------------------------ ground
def bake_ground(theme, p0):
    """the strip the cannon rides: strata + a top lip + per-theme
    material detail. Uses the theme's FIRST place palette as the base."""
    rnd = random.Random(900 + 1)
    im = Image.new("RGBA", (GW, GH), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    base = p0["r3"]
    im.paste(base + (255,), (0, 0, GW, GH))
    # strata bands (irregular edges)
    y = 0
    while y < GH:
        bh2 = rnd.randint(26, 48)
        c = shade(base, rnd.uniform(0.82, 1.14))
        d.rectangle([0, y, GW, y + bh2], fill=c + (255,))
        y += bh2
    lip = shade(p0["deco"], 0.9)
    # the top lip: an irregular crust
    pts = [(0, 0)]
    x = 0
    while x < GW:
        nx = x + rnd.randint(26, 60)
        pts.append((nx, rnd.randint(6, 18)))
        x = nx
    pts += [(GW, 0), (GW, 26)]
    d.polygon(pts, fill=lip + (255,))
    if theme == "cave":
        # embedded gems + cracks
        gc = p0["glow"] or p0["deco"]
        for i in range(16):
            gx, gy = rnd.randint(10, GW - 10), rnd.randint(30, GH - 14)
            s = rnd.randint(4, 9)
            d.polygon([(gx - s, gy), (gx, gy - s), (gx + s, gy),
                       (gx, gy + s)], fill=gc + (200,))
        for i in range(26):
            cx2 = rnd.randint(0, GW)
            cy2 = rnd.randint(20, GH - 8)
            d.line([(cx2, cy2), (cx2 + rnd.randint(-30, 30),
                    cy2 + rnd.randint(-10, 10))],
                   fill=shade(base, 0.6) + (255,), width=2)
    elif theme == "forest":
        # pebbles + root curls in the dirt
        for i in range(40):
            px, py = rnd.randint(6, GW - 6), rnd.randint(26, GH - 8)
            pr = rnd.randint(2, 5)
            d.ellipse([px - pr, py - pr, px + pr, py + pr],
                      fill=shade(base, rnd.uniform(0.7, 1.3)) + (255,))
        for i in range(12):
            rx = rnd.randint(0, GW)
            ry = rnd.randint(40, GH - 20)
            d.arc([rx, ry, rx + rnd.randint(40, 90),
                   ry + rnd.randint(20, 40)], 0, 180,
                  fill=shade(base, 0.55) + (255,), width=3)
    elif theme == "pixel":
        # blocky two-tone checker hints
        bs = 24
        for by in range(0, GH, bs):
            for bx in range(0, GW, bs):
                if rnd.random() < 0.18:
                    d.rectangle([bx, by, bx + bs, by + bs],
                                fill=shade(base, 1.12) + (255,))
    elif theme == "neon":
        # circuit veins + grid dots
        gc = p0["glow"] or p0["deco"]
        for i in range(10):
            vx = rnd.randint(0, GW)
            vy = rnd.randint(40, GH - 10)
            pts = [(vx, vy)]
            for s in range(4):
                vx += rnd.randint(-70, 70)
                pts.append((vx, vy + rnd.randint(-8, 8)))
            d.line(pts, fill=gc + (90,), width=2)
        for i in range(50):
            gx, gy = rnd.randint(0, GW), rnd.randint(30, GH - 6)
            d.rectangle([gx, gy, gx + 3, gy + 3],
                        fill=p0["deco"] + (70,))
    else:  # candy
        # sprinkles + sponge holes
        for i in range(70):
            sx, sy = rnd.randint(0, GW), rnd.randint(20, GH - 6)
            col = rnd.choice([(255, 120, 160), (120, 200, 255),
                              (255, 210, 90), (150, 230, 150)])
            d.line([(sx, sy), (sx + 8, sy + 2)], fill=col + (220,), width=4)
        for i in range(20):
            hx, hy = rnd.randint(0, GW), rnd.randint(30, GH - 10)
            hr = rnd.randint(4, 8)
            d.ellipse([hx - hr, hy - hr, hx + hr, hy + hr],
                      fill=shade(base, 0.75) + (255,))
    return im


# ------------------------------------------------------------------- walls
def bake_wall(theme, p0):
    """the arena's side wall skin - a thin vertical strip of real
    material (the game stretches it over the 14px walls)."""
    rnd = random.Random(700 + 1)
    im = Image.new("RGBA", (WW, WH), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    base = shade(p0["wall"] if "wall" in p0 else p0["r3"], 1.0)
    im.paste(base + (255,), (0, 0, WW, WH))
    if theme == "cave":
        # rough stone blocks
        y = 0
        while y < WH:
            bh2 = rnd.randint(40, 90)
            d.line([(0, y), (WW, y)], fill=shade(base, 0.7) + (255,),
                   width=3)
            bx = rnd.randint(8, WW - 8)
            d.line([(bx, y), (bx, y + bh2)],
                   fill=shade(base, 0.7) + (255,), width=3)
            y += bh2
        gc = p0["glow"] or p0["deco"]
        for i in range(8):
            wx, wy = rnd.randint(6, WW - 6), rnd.randint(20, WH - 20)
            s = rnd.randint(3, 6)
            d.polygon([(wx - s, wy), (wx, wy - s), (wx + s, wy),
                       (wx, wy + s)], fill=gc + (190,))
    elif theme == "forest":
        # bark ridges + a moss edge on the inner side
        for i in range(30):
            by = rnd.randint(0, WH)
            d.line([(rnd.randint(0, 10), by),
                    (rnd.randint(WW - 14, WW), by + rnd.randint(-30, 30))],
                   fill=shade(base, 0.72) + (255,), width=2)
        d.rectangle([WW - 8, 0, WW, WH],
                    fill=shade(p0["deco"], 1.05) + (255,))
    elif theme == "pixel":
        bs = 30
        for by in range(0, WH, bs):
            d.line([(0, by), (WW, by)], fill=shade(base, 0.74) + (255,),
                   width=2)
            d.line([(WW - 10, by), (WW - 10, by + bs)],
                   fill=shade(base, 0.74) + (255,), width=2)
        d.rectangle([WW - 6, 0, WW, WH], fill=shade(base, 1.2) + (255,))
    elif theme == "neon":
        d.rectangle([WW - 5, 0, WW, WH], fill=p0["deco"] + (200,))
        for i in range(16):
            wy = rnd.randint(0, WH)
            d.line([(0, wy), (WW - 8, wy)],
                   fill=shade(base, 1.25) + (255,), width=2)
    else:
        # candy stripe
        for i in range(-WH, WW + WH, 34):
            d.line([(i, 0), (i + WH, WH)],
                   fill=shade(base, 1.22) + (255,), width=12)
        d.rectangle([WW - 7, 0, WW, WH],
                    fill=shade(p0["deco"], 1.0) + (255,))
    return im


# --------------------------------------------------------------------- sfx
def bake_place_sfx():
    """rb_place.wav - the veil-cut's soft descending whoosh."""
    sr = 22050
    dur = 0.55
    n = int(sr * dur)
    frames = bytearray()
    rnd = random.Random(4211)
    lp = 0.0
    for i in range(n):
        t = i / n
        # noise through a falling lowpass + a soft sine thump at the peak
        cutoff = 0.5 * (1.0 - t) + 0.06
        lp += cutoff * (rnd.uniform(-1, 1) - lp)
        amp = math.sin(math.pi * min(1.0, t * 1.25)) ** 1.5
        thump = 0.35 * math.sin(2 * math.pi * (70 - 30 * t) * t * 4) \
            if t > 0.3 else 0.0
        v = (0.8 * lp + thump) * amp * 0.5
        frames += struct.pack("<h", int(max(-1, min(1, v)) * 32000))
    with wave.open(f"{SFX}/rb_place.wav", "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        wf.writeframes(bytes(frames))
    print("rb_place.wav")


def main():
    for theme, places in THEMES.items():
        for i, p in enumerate(places):
            if theme in ("cave", "neon"):
                p["sky"] = tuple(lift(v) for v in p["sky"])
                for key in ("r1", "r2", "r3", "deco"):
                    if p[key] is not None:
                        p[key] = lift(p[key], 0.17)
            im = bake_place(p)
            im.convert("RGB").save(f"{OUT}/far_{theme}_{i}.png")
            print(f"far_{theme}_{i}.png")
        im = bake_ground(theme, places[0])
        im.convert("RGB").save(f"{OUT}/ground_{theme}.png")
        print(f"ground_{theme}.png")
        im = bake_wall(theme, places[0])
        im.save(f"{OUT}/wall_{theme}.png")
        print(f"wall_{theme}.png")
    bake_place_sfx()
    print("RICH WORLD DONE")


if __name__ == "__main__":
    main()
