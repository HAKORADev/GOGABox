#!/usr/bin/env python3
"""v040-8 ROCK BREAKER forge part 2 - the CANNON (from the study's carts,
rebuilt as our two-wheeled cannon carriage per skin) and the WORLD layers
(far decor strips + ground strips per theme)."""
import os
import math
import random
from PIL import Image, ImageDraw, ImageFilter, ImageOps, ImageEnhance
from PIL import ImageChops as IC

CC = "/home/z/my-project/study_out/rockbreaker/cc"
OUT = "/home/z/my-project/gogabox/projects/gogabox/assets/games/rockbreaker"
for d in ["cannon", "world"]:
    os.makedirs(f"{OUT}/{d}", exist_ok=True)

def lum(im):
    g = ImageOps.grayscale(im)
    return Image.merge("RGBA", (g, g, g, im.split()[3]))

def tint(im, color):
    r, g, b, a = im.split()
    r = r.point(lambda v: v * color[0] // 255)
    g = g.point(lambda v: v * color[1] // 255)
    b = b.point(lambda v: v * color[2] // 255)
    return Image.merge("RGBA", (r, g, b, a))

def autolevel(im, lo=0.0, hi=1.0):
    px = list(im.getdata())
    vals = [p[0] for p in px if p[3] > 8]
    mn, mx = min(vals), max(vals)
    rng = max(1, mx - mn)
    px = [tuple(int(255 * (lo + (hi - lo) * ((c - mn) / rng))) for c in p[:3])
          + (p[3],) for p in px]
    out = Image.new("RGBA", im.size)
    out.putdata(px)
    return out

# ================================================================ CANNON
# the study carts are the carriage; we desaturate, tint per skin, cut the
# baked wheels away, and seat our own spoked wheels + a real cannon barrel.
SKINS = {
    "classic": {"body": (150, 160, 175), "rim": (255, 176, 32),  "tire": (58, 62, 72)},
    "crimson": {"body": (205, 92, 86),   "rim": (255, 210, 74),  "tire": (74, 42, 42)},
    "mint":    {"body": (110, 190, 158), "rim": (232, 255, 244), "tire": (40, 66, 58)},
    "royal":   {"body": (146, 122, 200), "rim": (255, 210, 74),  "tire": (56, 46, 88)},
    "gold":    {"body": (222, 172, 64),  "rim": (255, 240, 176), "tire": (98, 70, 24)},
}

def carriage_base():
    im = Image.open(f"{CC}/cart0.png").convert("RGBA")
    g = lum(im)
    g = autolevel(g, 0.34, 1.0)
    # erase the baked wheels (two circles at the bottom)
    d = ImageDraw.Draw(g)
    W, H = g.size
    d.ellipse([W * 0.16, H * 0.76, W * 0.40, H * 1.05], fill=(0, 0, 0, 0))
    d.ellipse([W * 0.60, H * 0.76, W * 0.84, H * 1.05], fill=(0, 0, 0, 0))
    d.rectangle([0, int(H * 0.90), W, H], fill=(0, 0, 0, 0))
    return g, im.size

def barrel(w, h, body, rim):
    """a real metal cannon barrel: banded muzzle, cooling rings, shading."""
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    bw = int(w * 0.66)
    x0 = (w - bw) // 2
    body = tuple(int(c * 0.92) for c in body)
    for x in range(bw):
        t = abs(x - bw / 2) / (bw / 2)       # 0 center -> 1 edge
        k = 1.25 - 0.55 * t
        col = tuple(min(255, int(c * k)) for c in body)
        d.line([(x0 + x, 0), (x0 + x, h)], fill=col + (255,))
    # the muzzle collar + two cooling rings
    for fy in (0.02, 0.30, 0.62):
        y = int(h * fy)
        d.rectangle([x0 - 5, y, x0 + bw + 5, y + int(h * 0.075)],
                    fill=tuple(min(255, int(c * 1.25)) for c in body) + (255,))
    # the dark bore
    d.ellipse([x0 + bw * 0.18, 2, x0 + bw * 0.82, int(h * 0.10)],
              fill=(16, 12, 10, 255))
    return im

def wheel(r, skin):
    S = r * 2 + 8
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = S // 2
    d.ellipse([c - r, c - r, c + r, c + r], fill=skin["tire"] + (255,))
    d.ellipse([c - r, c - r, c + r, c + r], outline=(18, 14, 12, 255), width=4)
    rimc = skin["rim"]
    d.ellipse([int(c - r * 0.72), int(c - r * 0.72),
               int(c + r * 0.72), int(c + r * 0.72)], outline=rimc + (255,), width=5)
    for i in range(6):
        a = math.tau * i / 6.0
        d.line([(c, c), (c + math.cos(a) * r * 0.68, c + math.sin(a) * r * 0.68)],
               fill=rimc + (235,), width=5)
    d.ellipse([c - r * 0.22, c - r * 0.22, c + r * 0.22, c + r * 0.22],
              fill=rimc + (255,))
    d.ellipse([c - r * 0.08, c - r * 0.08, c + r * 0.08, c + r * 0.08],
              fill=(20, 16, 14, 255))
    return im

CART, CART_SIZE = carriage_base()
CW, CH = CART_SIZE
EXTRA = int(CH * 0.5)          # headroom above the cart for the barrel
for sid, sk in SKINS.items():
    body = tint(CART, sk["body"])
    # edge line: darken the alpha edge for definition
    e = body.split()[3].filter(ImageFilter.FIND_EDGES)
    e = e.filter(ImageFilter.MaxFilter(3))
    edge = Image.new("RGBA", body.size, (22, 18, 16, 255))
    edge.putalpha(e.point(lambda v: min(190, v * 3)))
    body = Image.alpha_composite(body, edge)
    # the barrel: rises well above the wagon's opening (a REAL cannon)
    comp = Image.new("RGBA", (CW, CH + EXTRA), (0, 0, 0, 0))
    brl_h = EXTRA + int(CH * 0.42)
    brl = barrel(int(CW * 0.26), brl_h, sk["body"], sk["rim"])
    comp.alpha_composite(brl, ((CW - brl.size[0]) // 2, 0))
    comp.alpha_composite(body, (0, EXTRA))
    comp.save(f"{OUT}/cannon/body_{sid}.png")
    wheel(40, sk).save(f"{OUT}/cannon/wheel_{sid}.png")
    print("cannon", sid)

# ================================================================ WORLD
# far decor strips per style (5 places each): the cave places recolor the
# study's real backgrounds; the other styles draw shaded silhouette scenes.
BG_SRC = ["background0.png", "background1.png", "background2.png",
          "background3.png"]

def cave_recolor(idx, hue, sat, bright):
    im = Image.open(f"{CC}/{BG_SRC[idx]}").convert("RGBA")
    im = im.resize((1080, int(im.size[1] * 1080 / im.size[0])), Image.LANCZOS)
    hsv = Image.merge("RGBA", [_hsv_shift(im, hue, sat, bright)])
    return hsv

def _hsv_shift(im, hue_deg, sat_mul, val_mul):
    # quick per-pixel hsv (only on load - baked once)
    px = []
    src = im.split()
    import colorsys
    data = list(im.getdata())
    out = []
    for r, g, b, a in data:
        h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        h = (h + hue_deg / 360.0) % 1.0
        s = min(1.0, s * sat_mul)
        v = min(1.0, v * val_mul)
        r2, g2, b2 = colorsys.hsv_to_rgb(h, s, v)
        out.append((int(r2 * 255), int(g2 * 255), int(b2 * 255), a))
    return Image.new("RGBA", im.size).point(lambda v: v).split() and out and None

def cave_recolor2(idx, hue, sat, bright):
    import colorsys
    im = Image.open(f"{CC}/{BG_SRC[idx]}").convert("RGBA")
    im = im.resize((1080, int(im.size[1] * 1080 / im.size[0])), Image.LANCZOS)
    data = list(im.getdata())
    out = []
    for r, g, b, a in data:
        h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        h = (h + hue / 360.0) % 1.0
        s = min(1.0, s * sat)
        v = min(1.0, v * bright)
        r2, g2, b2 = colorsys.hsv_to_rgb(h, s, v)
        out.append((int(r2 * 255), int(g2 * 255), int(b2 * 255), a))
    im.putdata(out)
    return im

# cave theme: 5 places = the 4 real backgrounds (recolored) + 1 fifth hue
CAVE_PLACES = [(0.0, 1.0, 0.9), (0.52, 0.9, 1.05), (0.62, 1.0, 0.95),
               (0.78, 0.95, 1.0), (0.30, 0.85, 0.9)]
for i, (hue, sat, val) in enumerate(CAVE_PLACES):
    im = cave_recolor2(i % 4, hue, sat, val)
    im.save(f"{OUT}/world/far_cave_{i}.png")
    print("far_cave", i, im.size)

# other themes: shaded silhouette strips (transparent above the skyline)
def strip(w, h, draw_fn, seed):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rng = random.Random(seed)
    draw_fn(d, w, h, rng)
    return im

def forest(d, w, h, rng):
    # layered pines with soft shading
    for layer, col in ((0.72, (46, 92, 52, 200)), (1.0, (30, 66, 40, 235))):
        for i in range(9):
            x = rng.uniform(-40, w)
            th = rng.uniform(h * 0.45, h * 0.95) * layer
            tw = rng.uniform(w * 0.06, w * 0.12)
            y0 = h
            for k in range(4):
                ty = y0 - th * (k + 1) / 4.6
                twk = tw * (1.0 - k * 0.21)
                d.polygon([(x - twk, ty + th * 0.30), (x + twk, ty + th * 0.30),
                           (x, ty)], fill=col)
            d.rectangle([x - tw * 0.08, y0 - th * 0.14, x + tw * 0.08, y0],
                        fill=(38, 28, 18, 235))

def pixelplace(d, w, h, rng):
    bs = 24
    cols = [(86, 138, 90, 220), (58, 108, 70, 230), (40, 84, 56, 235)]
    for li, col in enumerate(cols):
        base_y = int(h * (0.55 + li * 0.15))
        for x in range(0, w, bs):
            hh = int(rng.uniform(0.25, 1.0) * (h - base_y))
            for y in range(base_y - hh, h, bs):
                if rng.random() < 0.92:
                    c = col if rng.random() < 0.85 else tuple(min(255, v + 22) for v in col[:3]) + (col[3],)
                    d.rectangle([x, y, x + bs - 1, y + bs - 1], fill=c)

def neonplace(d, w, h, rng):
    # skyline with lit windows
    x = 0
    while x < w:
        bw = int(rng.uniform(70, 150))
        bh = int(rng.uniform(h * 0.4, h * 0.95))
        col = (24, 18, 48, 235)
        d.rectangle([x, h - bh, x + bw, h], fill=col)
        d.rectangle([x, h - bh, x + bw, h - bh + 6], fill=(90, 60, 160, 255))
        wy = h - bh + 16
        while wy < h - 12:
            wx = x + 8
            while wx < x + bw - 12:
                if rng.random() < 0.4:
                    lit = (120, 220, 255, 235) if rng.random() < 0.7 \
                        else (255, 120, 220, 235)
                    d.rectangle([wx, wy, wx + 7, wy + 9], fill=lit)
                wx += 17
            wy += 22
        x += bw + int(rng.uniform(12, 50))

def candyplace(d, w, h, rng):
    # glossy candy hills + lollipop sticks
    for li, col in ((0, (255, 178, 216, 210)), (1, (246, 148, 198, 235))):
        n = 4
        for i in range(n):
            cx = w * (i + 0.5) / n + rng.uniform(-60, 60)
            r = rng.uniform(h * 0.28, h * 0.5)
            cy = h + r * 0.35
            y0, y1 = cy - r, cy - r * 1.55
            d.ellipse([cx - r, min(y0, y1), cx + r, max(y0, y1)], fill=col)
            d.ellipse([cx - r * 0.5, cy - r * 1.25, cx - r * 0.1, cy - r * 0.95],
                      fill=(255, 235, 245, 200))

def stoneplace(d, w, h, rng):
    # rocky mesas (pixel-free, shaded like the cave walls)
    for li, col in ((0.7, (98, 76, 58, 210)), (1.0, (70, 52, 40, 235))):
        for i in range(5):
            x = rng.uniform(-60, w)
            mw = rng.uniform(w * 0.12, w * 0.3)
            mh = rng.uniform(h * 0.4, h * 0.9) * li
            d.polygon([(x, h), (x + mw * 0.18, h - mh),
                       (x + mw * 0.5, h - mh * 0.9),
                       (x + mw * 0.8, h - mh * 1.02), (x + mw, h)], fill=col)

FARS = {
    "forest": (forest, 5),
    "pixel": (pixelplace, 5),
    "neon": (neonplace, 5),
    "candy": (candyplace, 5),
    "stone": (stoneplace, 5),
}
for style, (fn, n) in FARS.items():
    for i in range(n):
        im = strip(1080, 620, fn, 1000 + i * 7 + len(style))
        im.save(f"{OUT}/world/far_{style}_{i}.png")
        print("far", style, i)

# ------------------------------------------------------------- grounds
def ground_strip(style, seed):
    W, H = 1080, 190
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rng = random.Random(seed)
    base = {
        "cave": ((62, 44, 30, 255), (44, 30, 20, 255)),
        "forest": ((96, 132, 66, 255), (70, 100, 50, 255)),
        "pixel": ((146, 112, 66, 255), (110, 84, 50, 255)),
        "neon": ((26, 32, 68, 255), (16, 20, 46, 255)),
        "candy": ((255, 224, 176, 255), (246, 204, 152, 255)),
    }[style]
    d.rectangle([0, 0, W, H], fill=base[0])
    d.rectangle([0, 52, W, H], fill=base[1])
    # the lit top edge
    d.rectangle([0, 0, W, 8], fill=tuple(min(255, int(c * 1.35)) for c in base[0][:3]) + (255,))
    # texture: pebbles / grass / blocks / circuit / sprinkles
    for i in range(70):
        x, y = rng.uniform(0, W), rng.uniform(16, H - 8)
        if style == "pixel":
            d.rectangle([int(x) // 12 * 12, int(y) // 12 * 12,
                         int(x) // 12 * 12 + 11, int(y) // 12 * 12 + 11],
                        fill=tuple(min(255, int(c * 1.2)) for c in base[1][:3]) + (255,))
        elif style == "neon":
            if i % 3 == 0:
                d.line([(x, y), (x + rng.uniform(30, 90), y)],
                       fill=(70, 200, 255, 60), width=2)
        elif style == "candy":
            cols = [(255, 120, 170, 255), (120, 220, 255, 255), (255, 230, 120, 255)]
            d.ellipse([x, y, x + 7, y + 7], fill=cols[i % 3])
        else:
            d.ellipse([x, y, x + rng.uniform(4, 10), y + rng.uniform(3, 7)],
                      fill=tuple(min(255, int(c * 1.25)) for c in base[0][:3]) + (140,))
    return im

for style in ["cave", "forest", "pixel", "neon", "candy"]:
    ground_strip(style, 55 + len(style)).save(f"{OUT}/world/ground_{style}.png")
    print("ground", style)

print("WORLD+CANNON DONE")
