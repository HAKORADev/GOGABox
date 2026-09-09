#!/usr/bin/env python3
"""v0.3.7-1 - the MOLOTOV PEEL's art (the owner's item 19): the thrown
bottle, the market icon and the gun sprite. Generated, CC0-by-construction
(same as every box asset), 3 files:
  assets/games/cosmic_spud/bullets/bottle.png    (16x16)
  assets/games/cosmic_spud/weapons/icon_molotov.png (56x56)
  assets/games/cosmic_spud/weapons/gun_molotov.png  (48x22)
The language matches the shelf: chunky silhouettes, dark outline, fire
amber for the fuel."""
from PIL import Image, ImageDraw

BASE = "/home/z/my-project/GOGABox/projects/gogabox/assets/games/cosmic_spud"
INK = (28, 16, 10, 255)
GLASS = (150, 196, 168, 255)
GLASS_HI = (208, 236, 214, 255)
FUEL = (232, 112, 30, 255)
FLAME = (255, 176, 48, 255)

# ---------------- the bottle (16x16): tilted bottle with a burning rag
im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
d = ImageDraw.Draw(im)
# the body
d.ellipse((2, 6, 12, 14), fill=GLASS, outline=INK)
d.rectangle((5, 3, 9, 7), fill=GLASS, outline=INK)
# the fuel glow inside
d.ellipse((4, 9, 10, 13), fill=FUEL)
# the neck + rag
d.rectangle((6, 1, 8, 4), fill=GLASS, outline=INK)
d.line((8, 1, 11, 0), fill=(240, 220, 160, 255), width=2)
# the flame on the rag
d.polygon([(10, 0), (14, 0), (12, -0)], fill=FLAME)
d.point([(13, 0), (12, 1), (14, 1)], fill=FLAME)
im.save(BASE + "/bullets/bottle.png")

# ---------------- the icon (56x56): the bottle big, fire behind
ic = Image.new("RGBA", (56, 56), (0, 0, 0, 0))
d = ImageDraw.Draw(ic)
# the flame bloom behind
d.ellipse((10, 6, 46, 34), fill=(255, 140, 30, 70))
d.ellipse((16, 10, 40, 28), fill=(255, 190, 60, 110))
# the bottle body
d.ellipse((14, 22, 42, 50), fill=GLASS, outline=INK, width=2)
d.rectangle((23, 10, 33, 26), fill=GLASS, outline=INK, width=2)
d.ellipse((19, 30, 37, 47), fill=FUEL)
d.ellipse((22, 33, 30, 41), fill=(255, 200, 90, 200))
# the neck + the rag + the flame
d.rectangle((26, 3, 30, 11), fill=GLASS, outline=INK, width=1)
d.line((30, 4, 37, 2), fill=(240, 220, 160, 255), width=3)
d.polygon([(34, 0), (44, 2), (38, 8)], fill=FLAME)
d.polygon([(37, 2), (41, 3), (39, 6)], fill=(255, 236, 160, 255))
# the glass shine
d.line((20, 26, 18, 40), fill=GLASS_HI, width=2)
ic.save(BASE + "/weapons/icon_molotov.png")

# ---------------- the gun (48x22): the launcher that lobs the bottles
g = Image.new("RGBA", (48, 22), (0, 0, 0, 0))
d = ImageDraw.Draw(g)
# the barrel tube (short + wide - a mortar for bottles)
d.rounded_rectangle((8, 6, 40, 15), 4, fill=(96, 70, 44, 255), outline=INK)
d.rounded_rectangle((34, 4, 44, 17), 4, fill=(120, 88, 54, 255), outline=INK)
# the wood stock
d.rounded_rectangle((2, 8, 14, 18), 3, fill=(140, 96, 54, 255), outline=INK)
# the fuel tank strapped under
d.ellipse((16, 13, 28, 21), fill=FUEL, outline=INK)
d.point((20, 16), fill=FLAME)
# a scorch mark at the muzzle
d.ellipse((42, 8, 47, 13), fill=(60, 40, 26, 255))
g.save(BASE + "/weapons/gun_molotov.png")
print("molotov art: bottle.png + icon_molotov.png + gun_molotov.png")
