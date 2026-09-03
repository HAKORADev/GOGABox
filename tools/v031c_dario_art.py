#!/usr/bin/env python3
"""v0.3.1 PATCH III dario art surgery:
1. mover_plank.png RE-SLICED - the old crop caught TWO platforms in one
   texture (the yellow studs row + the tan plank = the owner's "two
   platforms one yellow and one red"). Now: the single clean tan plank.
2. bg_far.png / bg_mid.png EXTENDED UPWARD (192x640 / 384x640, original
   art at the bottom, sky padding above) - the parallax layers now cover
   the full 15-row world with NO flat-color seam and NO extra pixelation
   (same 3x scale as before, just a taller canvas).
"""
from PIL import Image
import os

ROOT = "/home/z/my-project"
PA = os.path.join(ROOT, "hunt/PixelAdventure/PixelAdventure")
OUT = os.path.join(ROOT, "gogabox/projects/gogabox/assets/games/dario")


def nearest3(img):
    return img.resize((img.width * 3, img.height * 3), Image.NEAREST)


def save(img, name):
    p = os.path.join(OUT, name)
    img.save(p)
    print("wrote", name, img.size)


# ---- 1. the mover plank (Terrain sheet, the tan strip at y15-20, x272-319)
terr = Image.open(os.path.join(PA, "Terrain/Terrain (16x16).png")).convert("RGBA")
plank = terr.crop((272, 15, 320, 21))          # 48x6, the tan deck only
save(nearest3(plank), "mover_plank.png")        # 144x18

# ---- 2. the tall parallax canvases
far = Image.open(os.path.join(OUT, "bg_far.png")).convert("RGBA")
mid = Image.open(os.path.join(OUT, "bg_mid.png")).convert("RGBA")
# the CURRENT files are the tall ones already? guard: originals are 240 tall
if far.height == 240:
    TALL = 640
    # far: pad with its own top sky rows stretched over the pad
    top = far.crop((0, 0, far.width, 8)).resize((far.width, TALL - far.height),
                                                Image.NEAREST)
    ftall = Image.new("RGBA", (far.width, TALL), (0, 0, 0, 0))
    ftall.paste(top, (0, 0))
    ftall.paste(far, (0, TALL - far.height))
    save(ftall, "bg_far.png")
if mid.height == 240:
    TALL = 640
    mtall = Image.new("RGBA", (mid.width, TALL), (0, 0, 0, 0))
    mtall.paste(mid, (0, TALL - mid.height))
    save(mtall, "bg_mid.png")

print("done")
