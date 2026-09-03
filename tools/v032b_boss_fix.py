#!/usr/bin/env python3
# v0.3.2 PATCH - boss surgery: monarch (crown/ring placement), storm (soft
# bands + real red-spot eye), reaver (blades ATTACHED to the hull)
import math, random
from PIL import Image, ImageDraw, ImageFilter

random.seed(777)
DST = "/home/z/GOGABox/projects/gogabox/assets/games/invaders/"

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

def shell(w, h, hull, hull_hi, hull_lo, edge, core_col):
    img, d = canvas(w, h)
    cx = w // 2
    pts = [(cx - w * 0.46, int(h * 0.16)), (cx + w * 0.46, int(h * 0.16)),
           (cx + w * 0.30, int(h * 0.62)), (cx + w * 0.14, int(h * 0.86)),
           (cx, h - 6), (cx - w * 0.14, int(h * 0.86)), (cx - w * 0.30, int(h * 0.62))]
    poly(d, pts, hull, edge, 6)
    poly(d, [(cx - w * 0.46, int(h * 0.16)), (cx + w * 0.46, int(h * 0.16)),
             (cx + w * 0.40, int(h * 0.30)), (cx - w * 0.40, int(h * 0.30))],
         hull_hi, edge, 3)
    poly(d, [(cx - w * 0.20, int(h * 0.58)), (cx + w * 0.20, int(h * 0.58)), (cx, h - 10)],
         hull_lo, edge, 3)
    d.rounded_rectangle([cx - w * 0.21, int(h * 0.30), cx + w * 0.21, int(h * 0.50)],
                        radius=14, fill=hull_hi, outline=edge, width=4)
    glow_disc(img, cx, int(h * 0.40), int(w * 0.085), core_col)
    return img, d, cx

def save(img, name, out_w):
    img = img.resize((out_w, int(img.height * out_w / img.width)), Image.LANCZOS)
    img.save(DST + name, "PNG")
    print(name, img.size)

# ---- MONARCH: crown sits ON the shoulder line, ring loops the upper hull
w, h = 340, 290
img, d, cx = shell(w, h, (96, 190, 176), (130, 216, 202), (60, 128, 118),
                   (14, 34, 32), (170, 255, 224))
for k in range(5):   # crown spikes rooted at the shoulder (y=0.16h)
    px = cx + (k - 2) * w * 0.15
    hh = 52 if k == 2 else 40
    d.polygon([(px - 13, int(h * 0.17) + 2), (px + 13, int(h * 0.17) + 2),
               (px, int(h * 0.17) - hh)], fill=(150, 230, 214), outline=(14, 34, 32))
# the tilt ring: one clean ellipse crossing behind the plate line
d.ellipse([cx - w * 0.40, int(h * 0.26), cx + w * 0.40, int(h * 0.56)],
          outline=(190, 255, 238), width=7)
d.line([cx - w * 0.30, int(h * 0.52), cx + w * 0.30, int(h * 0.30)],
       fill=(60, 128, 118), width=6)  # the 98-degree tilt line
save(img, "boss_monarch.png", w)

# ---- STORM: wide soft bands + one big red-spot eye
w, h = 400, 330
img, d, cx = shell(w, h, (196, 140, 92), (226, 182, 130), (150, 96, 60),
                   (44, 24, 12), (255, 160, 90))
lay = Image.new("RGBA", img.size, (0, 0, 0, 0))
dl = ImageDraw.Draw(lay)
for i, yy in enumerate(range(int(h * 0.18), int(h * 0.60), 30)):
    dl.rectangle([cx - w * 0.40, yy, cx + w * 0.40, yy + 14],
                 fill=(150, 96, 60, 110) if i % 2 == 0 else (238, 206, 160, 90))
lay = lay.filter(ImageFilter.GaussianBlur(10))
img.alpha_composite(lay)
glow_disc(img, cx + w * 0.18, int(h * 0.40), 26, (215, 70, 40), (255, 190, 150))
save(img, "boss_storm.png", w)

# ---- REAVER: blades rooted INSIDE the hull silhouette
w, h = 360, 300
img, d, cx = shell(w, h, (176, 88, 58), (208, 122, 84), (128, 58, 38),
                   (40, 14, 8), (255, 180, 90))
for k in (-1, 1):   # upper swept blades - rooted at the shoulders
    poly(d, [(cx + k * w * 0.10, int(h * 0.22)), (cx + k * w * 0.46, int(h * 0.04)),
             (cx + k * w * 0.52, int(h * 0.16)), (cx + k * w * 0.22, int(h * 0.42))],
         (208, 122, 84), (40, 14, 8), 4)
    poly(d, [(cx + k * w * 0.08, int(h * 0.48)), (cx + k * w * 0.36, int(h * 0.80)),
             (cx + k * w * 0.22, int(h * 0.88)), (cx + k * w * 0.02, int(h * 0.60))],
         (150, 78, 50), (40, 14, 8), 4)
# the dust wake: two short trails from the nose
for k in (-1, 1):
    d.line([cx + k * 14, int(h * 0.72), cx + k * 40, h - 8],
           fill=(228, 150, 100), width=7)
save(img, "boss_reaver.png", w)
