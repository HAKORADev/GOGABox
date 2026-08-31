#!/usr/bin/env python3
"""Analyze the Kenney_Rocket ? glyph: where does the tail end, what x-range
does the bottom stem occupy - so scene_soon can extend it like a real ?."""

import os
import sys
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__))))
from derive_assets import ASSETS, font  # noqa: E402

f = font(240, big=True)
img = Image.new("RGBA", (400, 400), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.text((20, 20), "?", font=f, fill=(122, 108, 180, 255))
bb = img.getbbox()
print("bbox:", bb)
px = img.load()
W, H = img.size
# per-row ink x-range, bottom half only
for y in range(bb[3] - 1, bb[1], -4):
    xs = [x for x in range(W) if px[x, y][3] > 40]
    if xs:
        print("y=%d x=[%d..%d] w=%d" % (y, min(xs), max(xs), max(xs) - min(xs)))
img.crop((bb[0] - 10, bb[1] - 10, bb[2] + 10, bb[3] + 10)).resize(
    ((bb[2] - bb[0] + 20) * 2, (bb[3] - bb[1] + 20) * 2), Image.NEAREST
).save("/tmp/q_glyph.png")
print("saved /tmp/q_glyph.png")
