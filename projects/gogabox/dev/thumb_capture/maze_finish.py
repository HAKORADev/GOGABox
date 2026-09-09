#!/usr/bin/env python3
"""maze thumb finisher - v0.3.7-1 item 11: the in-game capture + the
'programmed changes to make it cooler' pass (the owner's own wording).
Pipeline: pick the frame -> 3:2 crop -> neon boost (saturate + contrast)
-> soft bloom (bright-pass gaussian overlaid) -> vignette -> 960x640."""
from PIL import Image, ImageEnhance, ImageFilter, ImageDraw
import sys

SRC = sys.argv[1] if len(sys.argv) > 1 else "/tmp/thumbs_raw/maze_t00007.5.png"
OUT = sys.argv[2] if len(sys.argv) > 2 else \
        "/home/z/my-project/GOGABox/projects/gogabox/assets/thumbs/maze.png"

im = Image.open(SRC).convert("RGB")
w, h = im.size
# 3:2 focus band (center-ish, slight upward bias - the board breathes there)
if w / h > 3 / 2:
    cw, ch = int(h * 3 / 2), h
    x0 = (w - cw) // 2
    im = im.crop((x0, 0, x0 + cw, ch))
else:
    ch = int(w * 2 / 3)
    y0 = max(0, int((h - ch) * 0.42))
    im = im.crop((0, y0, w, y0 + ch))

# THE NEON BOOST: saturate the cyan walls, deepen the night
im = ImageEnhance.Color(im).enhance(1.38)
im = ImageEnhance.Contrast(im).enhance(1.12)
im = ImageEnhance.Brightness(im).enhance(1.04)

# THE BLOOM: bright pass -> blur -> screen-ish add (the glow the shop shot
# always had in the box art but the raw frame lacks)
bright = im.point(lambda p: max(0, min(255, int((p - 150) * 2.2))))
glow = bright.filter(ImageFilter.GaussianBlur(9))
im = Image.blend(im, Image.blend(im, glow, 0.0), 0.0)
from PIL import ImageChops
im = ImageChops.screen(im, glow.point(lambda p: int(p * 0.55)))

# THE VIGNETTE: corners fall into the matrix dark
vig = Image.new("L", im.size, 0)
d = ImageDraw.Draw(vig)
d.ellipse((-im.size[0] * 0.25, -im.size[1] * 0.35,
           im.size[0] * 1.25, im.size[1] * 1.35), fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(120))
black = Image.new("RGB", im.size, (2, 4, 12))
im = Image.composite(im, black, vig)

# THE CANVAS: 960x640 (rule R1)
im = im.resize((960, 640), Image.LANCZOS)
im.save(OUT)
print("saved", OUT)
