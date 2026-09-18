#!/usr/bin/env python3
"""
v0413 MARBLE POPPER THUMBNAIL (take 2 - sized right)
Posed real assets, 960x640, deterministic (the THUMBNAILS law).
"""
import math
from PIL import Image, ImageDraw, ImageFilter

A = "/home/z/my-project/gogabox/projects/gogabox/assets/games/marble"
OUT = "/home/z/my-project/gogabox/projects/gogabox/assets/thumbs/marble.png"
W, H = 960, 640

img = Image.open(f"{A}/bg_0_mossy.png").convert("RGBA").resize((W, int(W * 1.2)), Image.LANCZOS)
img = img.crop((0, 120, W, 120 + H))
d = ImageDraw.Draw(img, "RGBA")

raw = [(W * 0.90, H * 0.14), (W * 0.60, H * 0.30), (W * 0.30, H * 0.26),
       (W * 0.14, H * 0.46), (W * 0.30, H * 0.62), (W * 0.56, H * 0.68)]


def catmull(points, steps=24):
    pts = [points[0]] + list(points) + [points[-1]]
    out = []
    for i in range(1, len(pts) - 2):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[i + 1], pts[i + 2]
        for t in [j / steps for j in range(steps)]:
            t2, t3 = t * t, t * t * t
            x = 0.5 * ((2 * p1[0]) + (-p0[0] + p2[0]) * t + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2 + (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * t3)
            y = 0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3)
            out.append((x, y))
    out.append(points[-1])
    return out


path = catmull(raw)
for wdt, col in [(64, (32, 26, 18, 255)), (52, (92, 76, 54, 255)), (16, (48, 38, 26, 255))]:
    d.line(path, fill=col, width=wdt)

cum = [0.0]
for i in range(1, len(path)):
    cum.append(cum[-1] + math.dist(path[i - 1], path[i]))
total = cum[-1]


def point_at_len(L):
    t = max(0.0, min(1.0, L / total))
    i = t * (len(path) - 1)
    lo = int(i)
    f = i - lo
    hi = min(lo + 1, len(path) - 1)
    return (path[lo][0] * (1 - f) + path[hi][0] * f, path[lo][1] * (1 - f) + path[hi][1] * f)


# marbles rolling toward the idol (the idol sits at path end = W*0.56,H*0.68)
colors = ["marble_3_0.png", "marble_6_0.png", "marble_1_0.png",
          "marble_3_0.png", "marble_6_0.png", "marble_1_0.png", "marble_3_0.png"]
SP = 78
for k, cname in enumerate(colors):
    L = total - 58 - k * SP
    if L < total * 0.3:
        break
    x, y = point_at_len(L)
    if k == 3:  # the GOGACoin rider
        halo = Image.new("RGBA", (110, 110), (0, 0, 0, 0))
        dh = ImageDraw.Draw(halo)
        dh.ellipse((8, 8, 102, 102), fill=(255, 210, 80, 130))
        halo = halo.filter(ImageFilter.GaussianBlur(13))
        img.alpha_composite(halo, (int(x) - 55, int(y) - 55))
        coin = Image.open("/home/z/my-project/gogabox/projects/gogabox/assets/ui/coin.png").convert("RGBA").resize((64, 64), Image.LANCZOS)
        img.alpha_composite(coin, (int(x) - 32, int(y) - 32))
    else:
        mb = Image.open(f"{A}/{cname}").convert("RGBA").resize((72, 72), Image.LANCZOS)
        img.alpha_composite(mb, (int(x) - 36, int(y) - 36))

# the idol (end of path, jaws open toward the chain)
hx, hy = path[-1]
top = Image.open(f"{A}/hole_classic_top.png").convert("RGBA")
bot = Image.open(f"{A}/hole_classic_bot.png").convert("RGBA")
sc = 0.85
top = top.resize((int(top.width * sc), int(top.height * sc)), Image.LANCZOS)
bot = bot.resize((int(bot.width * sc), int(bot.height * sc)), Image.LANCZOS)
img.alpha_composite(top, (int(hx - top.width / 2), int(hy - top.height)))
img.alpha_composite(bot, (int(hx - bot.width / 2), int(hy)))

# the totem launcher (bottom right, aiming up-left at the chain)
sx, sy = W * 0.78, H * 0.80
base = Image.open(f"{A}/shooter_base.png").convert("RGBA")
head = Image.open(f"{A}/shooter_gold.png").convert("RGBA")
base = base.resize((int(base.width * 1.0), int(base.height * 1.0)), Image.LANCZOS)
head = head.resize((int(head.width * 1.0), int(head.height * 1.0)), Image.LANCZOS)
img.alpha_composite(base, (int(sx - base.width / 2), int(sy - base.height / 2) + 10))
img.alpha_composite(head, (int(sx - head.width / 2), int(sy - head.height / 2) - 10))
loaded = Image.open(f"{A}/marble_1_0.png").convert("RGBA").resize((52, 52), Image.LANCZOS)
img.alpha_composite(loaded, (int(sx - 26), int(sy - head.height / 2) - 74))
nextm = Image.open(f"{A}/marble_6_0.png").convert("RGBA").resize((40, 40), Image.LANCZOS)
img.alpha_composite(nextm, (int(sx - 20), int(sy + 30)))

# the glowing power marble (top-left chain)
px_, py_ = point_at_len(total * 0.12)
halo = Image.new("RGBA", (150, 150), (0, 0, 0, 0))
dh = ImageDraw.Draw(halo)
dh.ellipse((12, 12, 138, 138), fill=(120, 220, 255, 130))
halo = halo.filter(ImageFilter.GaussianBlur(17))
img.alpha_composite(halo, (int(px_) - 75, int(py_) - 75))
powm = Image.open(f"{A}/marble_2_0.png").convert("RGBA").resize((70, 70), Image.LANCZOS)
img.alpha_composite(powm, (int(px_) - 35, int(py_) - 35))
bolt = Image.open(f"{A}/pow_lightning.png").convert("RGBA").resize((46, 46), Image.LANCZOS)
img.alpha_composite(bolt, (int(px_) - 23, int(py_) - 23))

# vignette
vin = Image.new("L", (W, H), 0)
dv = ImageDraw.Draw(vin)
dv.ellipse((-W * 0.25, -H * 0.35, W * 1.25, H * 1.35), fill=255)
vin = vin.filter(ImageFilter.GaussianBlur(90))
dark = Image.new("RGBA", (W, H), (5, 8, 6, 255))
dark.putalpha(Image.eval(vin, lambda v: 255 - v))
img.alpha_composite(dark)

img.convert("RGB").save(OUT)
print("thumb v2 saved")
