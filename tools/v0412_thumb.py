#!/usr/bin/env python3
"""v041-2 r3 - TOWER BALL thumbnail composer (the capture law 44: the real
render). Takes the posed captures from tests/tb_thumb.gd and composes the
960x640 thumbnail: the BALL mode smash as the full-bleed hero, the
PLATFORM mode ride in a rounded inset. No baked text (R2).
r3: the rig now captures at the real 720x1280 window (the r2 rig assumed
an 810-wide probe window - the right side came out black)."""
from PIL import Image, ImageDraw

RAW = "/tmp/tb_thumb"
OUT = "projects/gogabox/assets/thumbs/towerball.png"
W, H = 960, 640
RAW_W = Image.open(f"{RAW}/ball_a.png").size[0]  # the real capture width


def band(p, y0, h=460):
    """a wide band out of the raw capture, scaled to the canvas"""
    img = Image.open(p)
    y0 = max(0, min(y0, img.size[1] - h))
    return img.crop((0, y0, RAW_W, y0 + h)).resize((W, H), Image.LANCZOS)


# the hero: the ball-mode smash (Balldozer mid-shatter, golden hour)
canvas = band(f"{RAW}/ball_a.png", 470).convert("RGBA")

# the inset: the platform ride (the rings + the eye ball), rounded,
# bottom-right
iw, ih = 386, 257
inset = band(f"{RAW}/plat_a.png", 400, 400).resize((iw, ih), Image.LANCZOS)
rad = 24
mask = Image.new("L", (iw, ih), 0)
dm = ImageDraw.Draw(mask)
dm.rounded_rectangle([0, 0, iw, ih], radius=rad, fill=255)
ring = Image.new("RGBA", (iw, ih), (0, 0, 0, 0))
dr = ImageDraw.Draw(ring)
dr.rounded_rectangle([2, 2, iw - 3, ih - 3], radius=rad,
                     outline=(255, 214, 120, 255), width=6)
ix, iy = W - iw - 24, H - ih - 24
canvas.paste(inset, (ix, iy), mask)
canvas.alpha_composite(ring, (ix, iy))

canvas.convert("RGB").save(OUT, "PNG")
print("thumb written:", OUT)
