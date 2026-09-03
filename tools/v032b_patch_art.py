#!/usr/bin/env python3
# v0.3.2 PATCH - the invaders art rework (the owner's playtest round)
#  1. BGs: pure ATMOSPHERE (gradient + mood + stars) - NO planet discs, NO
#     objects, NO text (the owner: "the space theme is the background only").
#     The real-world data now lives in the PALETTE only.
#  2. Enemies: derived from the SAME Kenney hulls Space Dash flies (the owner:
#     "ships and even enemy ones are the same as in the space dash game"),
#     gentle per-kind tints so waves still read apart.
#  3. Bosses: BIG layered originals (the owner: "the old bosses were looking
#     bad"). The Mimic is the Azure hull's evil twin (lore!).
#  4. The crew ships are NOT generated here - the engine now loads the Lanes
#     PNGs directly (literally the same ships as Space Dash).
import os, math, random
from PIL import Image, ImageDraw, ImageFilter

random.seed(20320)
SRC = "/home/z/GOGABox/projects/gogabox/assets/games/lanes/"
DST = "/home/z/GOGABox/projects/gogabox/assets/games/invaders/"
os.makedirs(DST, exist_ok=True)

# ================================================================ backgrounds
W, H = 960, 540

def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))

def vgrad(stops):
    """stops: list of (pos 0..1, (r,g,b)) - vertical multi-stop gradient"""
    img = Image.new("RGB", (W, H))
    px = img.load()
    for y in range(H):
        t = y / (H - 1)
        for i in range(len(stops) - 1):
            p0, c0 = stops[i]; p1, c1 = stops[i + 1]
            if p0 <= t <= p1:
                c = lerp(c0, c1, (t - p0) / max(0.0001, p1 - p0))
                break
        else:
            c = stops[-1][1]
        for x in range(W):
            px[x, y] = c
    return img

def stars(img, n=150, bright=6):
    d = ImageDraw.Draw(img, "RGBA")
    for _ in range(n):
        x, y = random.randrange(W), random.randrange(H)
        r = random.choice([1, 1, 1, 2, 2, 3])
        a = random.randint(60, 220)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, a))
    for _ in range(bright):
        x, y = random.randrange(W), random.randrange(H)
        d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=(255, 255, 255, 235))
        d.ellipse([x - 4, y - 4, x + 4, y + 4], outline=(255, 255, 255, 70))

def nebula(img, cols, n=3, blur=110, amax=30):
    lay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    for c in cols:
        for _ in range(n):
            cx, cy = random.randrange(W), random.randrange(H)
            rw, rh = random.randint(150, 330), random.randint(90, 210)
            d.ellipse([cx - rw, cy - rh, cx + rw, cy + rh],
                      fill=(c[0], c[1], c[2], random.randint(14, amax)))
    lay = lay.filter(ImageFilter.GaussianBlur(blur))
    img.paste(Image.alpha_composite(img.convert("RGBA"), lay).convert("RGB"), (0, 0))

def soft_bands(img, bands, blur=26):
    """bands: list of (y_center, height, (r,g,b), alpha)"""
    lay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    for yc, hh, c, a in bands:
        d.rectangle([0, yc - hh // 2, W, yc + hh // 2], fill=(c[0], c[1], c[2], a))
    lay = lay.filter(ImageFilter.GaussianBlur(blur))
    img.paste(Image.alpha_composite(img.convert("RGBA"), lay).convert("RGB"), (0, 0))

def streaks(img, n, col, amax=45):
    d = ImageDraw.Draw(img, "RGBA")
    for _ in range(n):
        y = random.randrange(20, H - 20)
        x = random.randrange(-100, W - 60)
        ln = random.randint(90, 460)
        d.line([x, y, x + ln, y], fill=(col[0], col[1], col[2], random.randint(18, amax)), width=2)

def diag_band(img, col, alpha, width, blur=40, angle_frac=0.35):
    lay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    y0 = int(H * angle_frac)
    d.polygon([(-80, y0 - width), (W + 80, y0 - width - 220),
               (W + 80, y0 - width - 160), (-80, y0 - width + 60)],
              fill=(col[0], col[1], col[2], alpha))
    lay = lay.filter(ImageFilter.GaussianBlur(blur))
    img.paste(Image.alpha_composite(img.convert("RGBA"), lay).convert("RGB"), (0, 0))

def clouds(img, n, col=(255, 255, 255), amax=55):
    lay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    for _ in range(n):
        cx, cy = random.randrange(60, W - 60), random.randrange(60, H - 60)
        rw, rh = random.randint(70, 170), random.randint(22, 52)
        d.ellipse([cx - rw, cy - rh, cx + rw, cy + rh],
                  fill=(col[0], col[1], col[2], random.randint(26, amax)))
    lay = lay.filter(ImageFilter.GaussianBlur(34))
    img.paste(Image.alpha_composite(img.convert("RGBA"), lay).convert("RGB"), (0, 0))

def side_glow(img, left=True, col=(255, 180, 90), alpha=70):
    lay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    for x in range(0, W, 8):
        t = 1.0 - (x / W) if left else x / W
        a = int(alpha * max(0.0, t) ** 2)
        d.rectangle([x, 0, x + 8, H], fill=(col[0], col[1], col[2], a))
    lay = lay.filter(ImageFilter.GaussianBlur(30))
    img.paste(Image.alpha_composite(img.convert("RGBA"), lay).convert("RGB"), (0, 0))

def bottom_glow(img, col=(255, 140, 40), alpha=90):
    lay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    for y in range(0, H, 6):
        t = y / H
        d.rectangle([0, y, W, y + 6], fill=(col[0], col[1], col[2], int(alpha * t ** 1.6)))
    lay = lay.filter(ImageFilter.GaussianBlur(24))
    img.paste(Image.alpha_composite(img.convert("RGBA"), lay).convert("RGB"), (0, 0))

def make_bg(name, stops, neb_cols, post=None):
    img = vgrad(stops)
    nebula(img, neb_cols)
    if post:
        post(img)
    stars(img)
    img.save(DST + name, "PNG")
    print("bg", name)

def p_neptune(img):
    soft_bands(img, [(120, 60, (90, 140, 230), 16), (260, 80, (60, 100, 200), 14),
                     (400, 70, (80, 130, 220), 12)], blur=40)
    streaks(img, 9, (170, 200, 255))

def p_uranus(img):
    diag_band(img, (160, 240, 230), 22, 150, blur=70)
    soft_bands(img, [(200, 90, (120, 210, 200), 14)], blur=50)

def p_saturn(img):
    diag_band(img, (230, 200, 140), 20, 120, blur=60)
    soft_bands(img, [(160, 70, (220, 190, 130), 14), (380, 90, (200, 170, 110), 12)], blur=46)

def p_jupiter(img):
    cols = [(214, 160, 110), (232, 204, 160), (186, 120, 84), (238, 216, 176),
            (198, 134, 92), (226, 194, 148), (180, 118, 86)]
    bands = [(40 + i * 70, random.randint(44, 74), cols[i % len(cols)],
              random.randint(20, 34)) for i in range(7)]
    soft_bands(img, bands, blur=30)
    # the great red spot, AS weather (a soft warm eddy, not an object)
    lay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    d.ellipse([660, 330, 820, 410], fill=(196, 92, 60, 60))
    lay = lay.filter(ImageFilter.GaussianBlur(38))
    img.paste(Image.alpha_composite(img.convert("RGBA"), lay).convert("RGB"), (0, 0))

def p_mars(img):
    clouds(img, 7, col=(226, 160, 110), amax=42)
    soft_bands(img, [(150, 60, (200, 120, 80), 16), (360, 80, (170, 95, 66), 14)], blur=50)

def p_earth(img):
    clouds(img, 9, amax=60)
    nebula(img, [(90, 160, 255)], n=2, blur=120, amax=22)

def p_venus(img):
    clouds(img, 10, col=(246, 222, 160), amax=70)
    soft_bands(img, [(140, 80, (240, 210, 140), 26), (320, 90, (236, 200, 130), 22)], blur=56)

def p_mercury(img):
    side_glow(img, left=True, col=(255, 190, 110), alpha=85)
    soft_bands(img, [(280, 100, (90, 84, 80), 18)], blur=60)

def p_sun(img):
    bottom_glow(img, col=(255, 150, 40), alpha=110)
    streaks(img, 6, (255, 210, 130), amax=60)

def p_hideout(img):
    nebula(img, [(120, 40, 190), (60, 20, 120)], n=4, blur=110, amax=40)
    d = ImageDraw.Draw(img, "RGBA")
    for _ in range(3):  # far glints of the hideout reactor
        x, y = random.randrange(100, W - 100), random.randrange(80, H - 80)
        d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=(255, 60, 60, 200))
        d.ellipse([x - 5, y - 5, x + 5, y + 5], outline=(255, 60, 60, 60))

make_bg("bg_neutral.png", [(0, (8, 10, 24)), (1, (13, 17, 38))], [(40, 60, 140)])
make_bg("bg_neptune.png", [(0, (6, 10, 34)), (0.6, (10, 18, 58)), (1, (14, 26, 78))],
        [(40, 90, 200)], p_neptune)
make_bg("bg_uranus.png", [(0, (6, 20, 30)), (1, (12, 44, 56))], [(60, 190, 190)], p_uranus)
make_bg("bg_saturn.png", [(0, (26, 20, 12)), (1, (52, 40, 24))], [(210, 170, 100)], p_saturn)
make_bg("bg_jupiter.png", [(0, (30, 20, 14)), (1, (58, 38, 26))], [(220, 160, 100)], p_jupiter)
make_bg("bg_mars.png", [(0, (30, 14, 10)), (1, (64, 30, 20))], [(220, 110, 70)], p_mars)
make_bg("bg_earth.png", [(0, (6, 14, 34)), (1, (12, 30, 66))], [(70, 130, 240)], p_earth)
make_bg("bg_venus.png", [(0, (46, 36, 18)), (1, (92, 74, 38))], [(240, 210, 140)], p_venus)
make_bg("bg_mercury.png", [(0, (24, 22, 20)), (1, (46, 42, 38))], [(150, 130, 110)], p_mercury)
make_bg("bg_sun.png", [(0, (40, 12, 6)), (1, (120, 44, 12))], [(255, 150, 50)], p_sun)
make_bg("bg_hideout.png", [(0, (14, 6, 24)), (1, (30, 12, 52))], [(120, 40, 190)], p_hideout)

# ================================================================== enemies
# the SAME Kenney hulls Space Dash flies, gentle per-kind tint (the family
# stays obvious - one universe, one war). upscaled 1.6x so the formations
# carry real presence at invaders' scale 1.0.
def tint_img(src, hue_shift=0, sat=1.0, val=1.0, scale=1.6):
    im = Image.open(SRC + src).convert("RGBA")
    im = im.resize((int(im.width * scale), int(im.height * scale)), Image.LANCZOS)
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = _rgb2hsv(r, g, b)
            h = (h + hue_shift) % 1.0
            s = min(1.0, s * sat)
            v = min(255.0, v * val)
            r2, g2, b2 = _hsv2rgb(h, s, v)
            px[x, y] = (r2, g2, b2, a)
    return im

def _rgb2hsv(r, g, b):
    r_, g_, b_ = r / 255.0, g / 255.0, b / 255.0
    mx, mn = max(r_, g_, b_), min(r_, g_, b_)
    d = mx - mn
    if d == 0: h = 0.0
    elif mx == r_: h = ((g_ - b_) / d) % 6.0
    elif mx == g_: h = (b_ - r_) / d + 2.0
    else: h = (r_ - g_) / d + 4.0
    h /= 6.0
    s = 0.0 if mx == 0 else d / mx
    return h, s, mx * 255.0

def _hsv2rgb(h, s, v):
    i = int(h * 6.0) % 6
    f = h * 6.0 - int(h * 6.0)
    p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
    lut = [(v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q)]
    r, g, b = lut[i]
    return int(r), int(g), int(b)

ENEMIES = [
    ("en_grunt.png",  "enemy_grunt.png",   0.00, 1.0, 1.00),
    ("en_swift.png",  "enemy_runner.png",  0.02, 1.1, 1.05),
    ("en_aimer.png",  "enemy_shooter.png", -0.06, 1.15, 0.98),
    ("en_diver.png",  "enemy_grunt2.png",  0.07, 1.1, 1.02),
    ("en_tank.png",   "enemy_tank.png",    0.00, 1.0, 1.02),
    ("en_split.png",  "enemy_splitter.png", 0.00, 1.05, 1.0),
    ("en_weaver.png", "enemy_shatter.png", 0.45, 1.1, 1.0),
    ("en_spit.png",   "enemy_ufo_green.png", 0.0, 1.0, 1.0),
    ("en_brute.png",  "enemy_shielded.png", -0.05, 1.2, 0.96),
    ("en_magma.png",  "enemy_ufo_red.png",  0.0, 1.15, 1.05),
    ("en_void.png",   "enemy_ufo_yellow.png", -0.30, 1.25, 0.92),
]
for dst, src, hs, st, vl in ENEMIES:
    tint_img(src, hs, st, vl).save(DST + dst, "PNG")
    print("enemy", dst, "<-", src)

# =================================================================== bosses
# big layered originals, nose-DOWN (they face the protector). every boss:
# dark outline -> armor plates -> panel lines -> glowing core -> its own
# signature structure. the Mimic wears the AZURE hull itself (evil twin).
def canvas(w, h):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)

def poly(d, pts, fill, outline, ow=5):
    d.polygon(pts, fill=fill, outline=outline, width=ow)

def glow_disc(img, cx, cy, r, col, core=(255, 255, 255)):
    lay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(col[0], col[1], col[2], 110))
    lay = lay.filter(ImageFilter.GaussianBlur(r * 0.45))
    img.alpha_composite(lay)
    d2 = ImageDraw.Draw(img)
    d2.ellipse([cx - r * 0.55, cy - r * 0.55, cx + r * 0.55, cy + r * 0.55],
               fill=(col[0], col[1], col[2], 235))
    d2.ellipse([cx - r * 0.26, cy - r * 0.26, cx + r * 0.26, cy + r * 0.26], fill=core)

def plate(d, cx, cy, w, h, col, edge, ow=4):
    """rounded armor plate centered at cx, nose-down bias"""
    d.rounded_rectangle([cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2],
                        radius=min(w, h) * 0.22, fill=col, outline=edge, width=ow)

def pod(d, cx, cy, r, col, edge):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col, outline=edge, width=4)

def fin(d, pts, col, edge):
    poly(d, pts, col, edge, 4)

def save2x(img, name, out_w):
    img = img.resize((out_w, int(img.height * out_w / img.width)), Image.LANCZOS)
    img.save(DST + name, "PNG")
    print("boss", name, img.size)

def boss_shell(w, h, hull, hull_hi, hull_lo, edge, core_col):
    """the shared body: swept fortress hull + 2 plates + core. returns img,d,cx,cy"""
    img, d = canvas(w, h)
    cx, cy = w // 2, int(h * 0.46)
    # main hull - wide shoulders, tapered nose (down)
    pts = [(cx - w * 0.46, int(h * 0.16)), (cx + w * 0.46, int(h * 0.16)),
           (cx + w * 0.30, int(h * 0.62)), (cx + w * 0.14, int(h * 0.86)),
           (cx, h - 6), (cx - w * 0.14, int(h * 0.86)), (cx - w * 0.30, int(h * 0.62))]
    poly(d, pts, hull, edge, 6)
    # shoulder highlight
    pts_hi = [(cx - w * 0.46, int(h * 0.16)), (cx + w * 0.46, int(h * 0.16)),
              (cx + w * 0.40, int(h * 0.30)), (cx - w * 0.40, int(h * 0.30))]
    poly(d, pts_hi, hull_hi, edge, 3)
    # nose shadow wedge
    pts_lo = [(cx - w * 0.20, int(h * 0.58)), (cx + w * 0.20, int(h * 0.58)),
              (cx, h - 10)]
    poly(d, pts_lo, hull_lo, edge, 3)
    plate(d, cx, int(h * 0.40), int(w * 0.42), int(h * 0.20), hull_hi, edge, 4)
    glow_disc(img, cx, int(h * 0.46), int(w * 0.085), core_col)
    return img, d, cx, cy, hull_lo

def b_triton():
    w, h = 340, 300
    img, d, cx, cy, lo = boss_shell(w, h, (86, 128, 190), (120, 160, 218), (56, 84, 140),
                                    (18, 26, 44), (110, 230, 255))
    # the trident: three prongs reaching at the protector
    for k in (-1, 0, 1):
        px = cx + k * w * 0.22
        fin(d, [(px - 14, int(h * 0.72)), (px + 14, int(h * 0.72)),
                (px + 6, h - 4), (px - 6, h - 4)], (150, 190, 240), (18, 26, 44))
        d.polygon([(px - 16, h - 10), (px + 16, h - 10), (px, h - 34)], fill=(210, 235, 255))
    pod(d, cx - w * 0.34, int(h * 0.30), 16, (60, 96, 150), (18, 26, 44))
    pod(d, cx + w * 0.34, int(h * 0.30), 16, (60, 96, 150), (18, 26, 44))
    save2x(img, "boss_triton.png", w)

def b_monarch():
    w, h = 340, 290
    img, d, cx, cy, lo = boss_shell(w, h, (96, 190, 176), (130, 216, 202), (60, 128, 118),
                                    (14, 34, 32), (170, 255, 224))
    # the tilted crown (uranus rolls at 98 degrees - so does the crown)
    crown = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dc = ImageDraw.Draw(crown)
    for k in range(5):
        px = w * 0.5 + (k - 2) * w * 0.13
        dc.polygon([(px - 13, int(h * 0.16)), (px + 13, int(h * 0.16)),
                    (px, int(h * 0.16) - 46)], fill=(150, 230, 214), outline=(14, 34, 32))
    crown = crown.rotate(-14, center=(w / 2, h * 0.2), resample=Image.BICUBIC)
    img.alpha_composite(crown)
    d.ellipse([cx - w * 0.44, int(h * 0.30), cx - w * 0.30, int(h * 0.52)],
              outline=(170, 255, 224), width=5)
    save2x(img, "boss_monarch.png", w)

def b_duke():
    w, h = 400, 330
    img, d, cx, cy, lo = boss_shell(w, h, (196, 158, 96), (224, 190, 126), (140, 108, 62),
                                    (40, 28, 12), (255, 230, 170))
    # the RING: a broad ellipse band around the hull
    ring = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dr = ImageDraw.Draw(ring)
    dr.ellipse([cx - w * 0.56, int(h * 0.34), cx + w * 0.56, int(h * 0.62)],
               outline=(238, 210, 150, 255), width=16)
    dr.ellipse([cx - w * 0.50, int(h * 0.38), cx + w * 0.50, int(h * 0.58)],
               outline=(120, 92, 50, 255), width=4)
    ring = ring.rotate(-8, resample=Image.BICUBIC)
    img.alpha_composite(ring)
    for k in (-1, 1):  # shard pods on the ring line
        pod(d, cx + k * w * 0.40, int(h * 0.47), 13, (238, 210, 150), (40, 28, 12))
    save2x(img, "boss_duke.png", w)

def b_storm():
    w, h = 400, 330
    img, d, cx, cy, lo = boss_shell(w, h, (196, 140, 92), (226, 182, 130), (150, 96, 60),
                                    (44, 24, 12), (255, 150, 80))
    # banded storm arms
    for i, yy in enumerate(range(int(h * 0.20), int(h * 0.62), 26)):
        d.line([cx - w * 0.36, yy, cx + w * 0.36, yy + (8 if i % 2 else -8)],
               fill=(150, 96, 60), width=7)
    # the red spot EYE
    glow_disc(img, cx + w * 0.20, int(h * 0.46), 20, (220, 70, 40), (255, 200, 160))
    save2x(img, "boss_storm.png", w)

def b_reaver():
    w, h = 360, 300
    img, d, cx, cy, lo = boss_shell(w, h, (176, 88, 58), (208, 122, 84), (128, 58, 38),
                                    (40, 14, 8), (255, 180, 90))
    # swept dust blades
    for k in (-1, 1):
        fin(d, [(cx + k * w * 0.20, int(h * 0.24)), (cx + k * w * 0.52, int(h * 0.06)),
                (cx + k * w * 0.56, int(h * 0.20)), (cx + k * w * 0.30, int(h * 0.44))],
            (208, 122, 84), (40, 14, 8))
        fin(d, [(cx + k * w * 0.24, int(h * 0.60)), (cx + k * w * 0.50, int(h * 0.84)),
                (cx + k * w * 0.30, int(h * 0.86)), (cx + k * w * 0.16, int(h * 0.68))],
            (150, 78, 50), (40, 14, 8))
    save2x(img, "boss_reaver.png", w)

def b_mimic():
    # THE EVIL TWIN: the azure protector hull, grown huge and poisoned red
    src = Image.open(SRC + "ship_blue.png").convert("RGBA")
    w = 360
    im = src.resize((w, int(src.height * w / src.width)), Image.NEAREST)
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            # azure -> crimson, white -> bone
            if b > r and b > g:
                px[x, y] = (min(255, r + 120), g // 3, b // 3, a)
            elif r > 200 and g > 200 and b > 200:
                px[x, y] = (235, 208, 200, a)
            else:
                px[x, y] = (min(255, int(r * 1.1)), int(g * 0.8), int(b * 0.8), a)
    img = Image.new("RGBA", (w, int(im.height * 1.12)), (0, 0, 0, 0))
    img.alpha_composite(im, (0, int(im.height * 0.10)))
    d = ImageDraw.Draw(img)
    # the lying core: OUR blue, wrong
    glow_disc(img, w // 2, int(img.height * 0.52), int(w * 0.075), (90, 140, 255), (255, 120, 120))
    save2x(img, "boss_mimic.png", w)

def b_ash():
    w, h = 380, 310
    img, d, cx, cy, lo = boss_shell(w, h, (128, 120, 112), (162, 152, 142), (92, 84, 78),
                                    (30, 24, 20), (240, 220, 90))
    # jagged ash spires + sulfur cracks
    for k in (-2, -1, 0, 1, 2):
        px = cx + k * w * 0.16
        hh = 40 + (26 if k % 2 == 0 else 0)
        d.polygon([(px - 11, int(h * 0.17)), (px + 11, int(h * 0.17)), (px, int(h * 0.17) - hh)],
                  fill=(162, 152, 142), outline=(30, 24, 20))
    for k in (-1, 0, 1):
        d.line([cx - 30 + k * 30, int(h * 0.30), cx - 44 + k * 34, int(h * 0.56)],
               fill=(240, 220, 90), width=5)
    save2x(img, "boss_ash.png", w)

def b_eater():
    w, h = 400, 340
    img, d, cx, cy, lo = boss_shell(w, h, (110, 116, 126), (150, 156, 168), (76, 80, 90),
                                    (16, 16, 22), (255, 255, 230))
    # THE MAW: a dark open mouth with heat teeth
    d.ellipse([cx - w * 0.26, int(h * 0.44), cx + w * 0.26, int(h * 0.78)],
              fill=(18, 14, 18), outline=(16, 16, 22), width=6)
    for k in range(7):
        a = math.pi * (0.12 + 0.76 * k / 6.0)
        tx = cx + int(math.cos(a) * w * 0.22)
        ty = int(h * 0.61) + int(math.sin(a) * h * 0.15)
        d.polygon([(tx - 9, ty), (tx + 9, ty), (tx, ty + 18)], fill=(255, 200, 120))
    # crater pocks
    for _ in range(8):
        px = cx + random.randint(-w * 4 // 10, w * 4 // 10)
        py = random.randint(int(h * 0.20), int(h * 0.40))
        r = random.randint(7, 14)
        d.ellipse([px - r, py - r, px + r, py + r], fill=(88, 92, 102))
    save2x(img, "boss_eater.png", w)

def b_herald():
    w, h = 420, 340
    img, d, cx, cy, lo = boss_shell(w, h, (222, 160, 60), (246, 196, 100), (172, 116, 40),
                                    (60, 34, 8), (255, 250, 210))
    # the halo + solar wings
    d.ellipse([cx - w * 0.34, int(h * 0.02), cx + w * 0.34, int(h * 0.24)],
              outline=(255, 240, 170), width=8)
    for k in (-1, 1):
        fin(d, [(cx + k * w * 0.34, int(h * 0.24)), (cx + k * w * 0.52, int(h * 0.14)),
                (cx + k * w * 0.52, int(h * 0.40)), (cx + k * w * 0.36, int(h * 0.48))],
            (210, 150, 56), (60, 34, 8))
        for i in range(3):
            d.line([cx + k * (w * 0.40 + i * 18), int(h * 0.20),
                    cx + k * (w * 0.40 + i * 18), int(h * 0.42)], fill=(120, 80, 24), width=4)
    save2x(img, "boss_herald.png", w)

def b_invader():
    # THE INVADER: the mothership. deep violet, void core, spike crown,
    # side hive pods. the biggest body in the war.
    w, h = 560, 440
    img, d = canvas(w, h)
    cx = w // 2
    edge = (12, 4, 22)
    # outer hive wings
    for k in (-1, 1):
        fin(d, [(cx + k * w * 0.16, int(h * 0.18)), (cx + k * w * 0.50, int(h * 0.06)),
                (cx + k * w * 0.56, int(h * 0.34)), (cx + k * w * 0.30, int(h * 0.52))],
            (74, 34, 120), edge)
        fin(d, [(cx + k * w * 0.22, int(h * 0.50)), (cx + k * w * 0.46, int(h * 0.72)),
                (cx + k * w * 0.24, int(h * 0.86)), (cx + k * w * 0.12, int(h * 0.60))],
            (56, 24, 92), edge)
    # main hull
    pts = [(cx - w * 0.30, int(h * 0.12)), (cx + w * 0.30, int(h * 0.12)),
           (cx + w * 0.24, int(h * 0.44)), (cx + w * 0.12, int(h * 0.80)),
           (cx, h - 6), (cx - w * 0.12, int(h * 0.80)), (cx - w * 0.24, int(h * 0.44))]
    poly(d, pts, (96, 44, 150), edge, 7)
    poly(d, [(cx - w * 0.30, int(h * 0.12)), (cx + w * 0.30, int(h * 0.12)),
             (cx + w * 0.24, int(h * 0.26)), (cx - w * 0.24, int(h * 0.26))],
         (126, 62, 188), edge, 4)
    # spike crown
    for k in (-2, -1, 0, 1, 2):
        px = cx + k * w * 0.11
        hh = 44 + (20 if k == 0 else 0)
        d.polygon([(px - 13, int(h * 0.13)), (px + 13, int(h * 0.13)), (px, int(h * 0.13) - hh)],
                  fill=(150, 84, 214), outline=edge)
    # hive pods
    for k in (-1, 1):
        pod(d, cx + k * w * 0.36, int(h * 0.30), 22, (74, 34, 120), edge)
        glow_disc(img, cx + k * w * 0.36, int(h * 0.30), 9, (200, 90, 255))
    # THE VOID CORE: a black heart in a violet halo
    glow_disc(img, cx, int(h * 0.42), int(w * 0.075), (150, 60, 230), (235, 180, 255))
    d.ellipse([cx - 26, int(h * 0.42) - 26, cx + 26, int(h * 0.42) + 26], fill=(10, 4, 16))
    d.ellipse([cx - 12, int(h * 0.42) - 12, cx + 12, int(h * 0.42) + 12], fill=(60, 16, 110))
    save2x(img, "boss_invader.png", w)

b_triton(); b_monarch(); b_duke(); b_storm(); b_reaver()
b_mimic(); b_ash(); b_eater(); b_herald(); b_invader()

# the crew ships are the DASH files themselves - drop the divergent copies
for f in os.listdir(DST):
    if f.startswith("ship_") and f.endswith(".png"):
        os.remove(DST + f)
        print("removed divergent hull", f)

# ================================================================== QA sheet
sheet = Image.new("RGB", (1500, 1150), (10, 12, 26))
bgs = ["bg_neptune", "bg_uranus", "bg_saturn", "bg_jupiter", "bg_mars",
       "bg_earth", "bg_venus", "bg_mercury", "bg_sun", "bg_hideout"]
for i, b in enumerate(bgs):
    im = Image.open(DST + b + ".png").resize((296, 166))
    sheet.paste(im, (10 + (i % 5) * 298, 10 + (i // 5) * 168))
x = 10
for e in [e[0] for e in ENEMIES]:
    im = Image.open(DST + e)
    sheet.paste(im, (x, 370), im)
    x += im.width + 12
x = 10
for b in ["boss_triton", "boss_monarch", "boss_duke", "boss_storm", "boss_reaver"]:
    im = Image.open(DST + b + ".png")
    sheet.paste(im, (x, 500), im)
    x += im.width + 14
x = 10
for b in ["boss_mimic", "boss_ash", "boss_eater", "boss_herald", "boss_invader"]:
    im = Image.open(DST + b + ".png")
    sheet.paste(im, (x, 830), im)
    x += im.width + 14
az = Image.open(SRC + "ship_blue.png").resize((168, 112), Image.LANCZOS)
sheet.paste(az, (1290, 1010), az)
sheet.save("/home/z/my-project/download/qa_v032b_art_sheet.png")
print("QA sheet saved")
