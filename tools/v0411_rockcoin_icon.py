#!/usr/bin/env python3
"""v040-11 - the rockcoin chip icon re-baked in the GAME'S OWN stone-R
look (the owner: the top chip's icon is wrong; the correct one is the
chiseled stone coin with the R that the bottom-left widget drew). Draws
the same 8-gon chiseled coin + R at 128px for the top-bar chip."""
import math
import os

from PIL import Image, ImageDraw, ImageFont

OUT = ("/home/z/my-project/gogabox/projects/gogabox"
       "/assets/games/rockbreaker/world/rockcoin.png")

S = 128
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

def oct_pts(cx, cy, rx, ry, rot=math.tau / 16.0):
    pts = []
    for i in range(8):
        a = math.tau * i / 8.0 + rot
        pts.append((cx + math.cos(a) * rx, cy + math.sin(a) * ry))
    return pts

cx, cy = S / 2, S / 2
r = 54.0
# the outer stone ring
d.polygon(oct_pts(cx, cy, r, r * 0.94), fill=(184, 168, 140, 255),
          outline=(96, 82, 62, 255), width=5)
# the chiseled inner face
d.polygon(oct_pts(cx, cy, r * 0.7, r * 0.66), fill=(229, 217, 184, 255))
# a top-left shine facet
d.polygon([(cx - r * 0.42, cy - r * 0.30), (cx - r * 0.05, cy - r * 0.48),
           (cx + r * 0.18, cy - r * 0.34), (cx - r * 0.22, cy - r * 0.10)],
          fill=(244, 236, 210, 255))
# the R
fp = None
for cand in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
             "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
    try:
        fp = ImageFont.truetype(cand, int(r * 1.15))
        break
    except Exception:
        pass
if fp is not None:
    bb = d.textbbox((0, 0), "R", font=fp)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    d.text((cx - tw / 2 - bb[0], cy - th / 2 - bb[1] + r * 0.06), "R",
           font=fp, fill=(82, 66, 46, 255))
os.makedirs(os.path.dirname(OUT), exist_ok=True)
img.save(OUT)
print("rockcoin re-baked:", OUT)
