#!/usr/bin/env python3
"""v040-3 ART PASS - three fixes the owner's report demands:

1. THE DEFLECTOR FIX: the source's own deflector.jpg + deflector_.png pair
   is MISMATCHED (color 419x72 vs mask 100x33 - not a mask at all). The
   v0402 compose cropped the jet to a 100x33 sliver - the white-asset look.
   Law: key the jpg by its own flat background (the source's colorkey era)
   and slice the strip by alpha gaps.
2. THE LASER WIDGET ICON (the owner's own design, not the source's
   megameter): an orange WAVY "I" on transparent - the chip next to it
   carries the live nn% label.
3. THE PROP SHEET AUDIT: count the real frames of every composed anim sheet
   (alpha gaps) vs the Anims.xml count - print the liars so the props table
   gets the truth.
"""
from PIL import Image, ImageDraw
import numpy as np
import os

SPR = "projects/gogabox/assets/games/hwsrc/sprites/"
ANIM = "projects/gogabox/assets/games/hwsrc/anims/"
ORIG = "/home/z/my-project/v040_2_study/hw_orig/HeavyWeapon/Images/"

# ---------------------------------------------------------------- 1. deflector
src = Image.open(ORIG + "deflector.jpg").convert("RGB")
a = np.array(src).astype(int)
# the background = the corner color; key it with a tolerance
corner = a[2, 2]
dist = np.abs(a - corner).sum(axis=2)
alpha = np.where(dist < 42, 0, 255).astype(np.uint8)
# un-key near-black gun metal? keep simple: tolerance 42 catches the flat bg
out = np.dstack([np.array(src), alpha])
im = Image.fromarray(out, "RGBA")
im.save(SPR + "deflector.png")
cols = (alpha.max(axis=0) > 10).astype(int)
runs = []
run = 0
for v in cols:
    if v == 0:
        run += 1
    else:
        if run > 3:
            runs.append(run)
        run = 0
if run > 3:
    runs.append(run)
print("DEFLECTOR recomposed:", im.size, "gap-runs:", runs[:20])

# ---------------------------------------------------------------- 2. laser icon
W, H = 44, 44
ic = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(ic)
# the orange wavy I: a vertical sine stroke, thick, with a hot core
pts = []
for yy in range(8, H - 8):
    xx = W / 2 + np.sin((yy - 8) / 5.2) * 4.6
    pts.append((xx, yy))
for (ox, wdt, col) in [(0, 8, (255, 128, 20, 255)),
                       (0, 4, (255, 210, 120, 255))]:
    for k in range(-wdt // 2, wdt // 2 + 1):
        d.point([(p[0] + k, p[1]) for p in pts], fill=col)
# the I's serifs: short horizontal bars top + bottom
d.rectangle([W / 2 - 9, 4, W / 2 + 9, 9], fill=(255, 128, 20, 255))
d.rectangle([W / 2 - 9, H - 9, W / 2 + 9, H - 4], fill=(255, 128, 20, 255))
ic.save(SPR + "laser_wavy.png")
print("LASER ICON built:", ic.size)

# ---------------------------------------------------------------- 3. prop audit
print("\nPROP SHEET AUDIT (composed size / gaps vs XML frames):")
XMLF = {
    "Nessi": 1, "GasPill": 2, "oilcans": 2, "lighthouse": 2,
    "radiotowers": 2, "oasis": 2, "Scope": 1, "Petro-Rig": 1,
    "COW": 5, "Yetti": 6, "Penguin": 6, "Igloo": 1, "eskimo": 9,
    "snocommie": 2, "MurryandMaud": 2, "Statue1": 2, "Statue2": 2,
    "PeaceBalloon": 1, "Fence": 1, "Brokenwindmill": 1, "silo": 1,
    "Grainelevator": 1, "vania_light": 1, "Hangtree": 1, "vania_ghost": 1,
    "vania_pumpkin1": 2, "vania_pumpkin2": 2, "pyramid": 1,
    "bedouin-tents": 1, "Barrelofnuke": 1, "Cooler-crack": 1,
    "Spiltnuke": 1, "WasteSpill": 1, "surrender": 1, "brontasaur": 2,
    "zambian": 2, "pterodactyl": 2,
}
for place in sorted(os.listdir(ANIM)):
    pdir = os.path.join(ANIM, place)
    if not os.path.isdir(pdir):
        continue
    for f in sorted(os.listdir(pdir)):
        if not f.endswith(".png"):
            continue
        p = os.path.join(pdir, f)
        im = Image.open(p)
        name = f[:-4]
        xml = XMLF.get(name, "?")
        if im.mode != "RGBA":
            print(f"  {place}/{f}: {im.size} NOT RGBA")
            continue
        alpha = np.array(im)[:, :, 3]
        cols = (alpha.max(axis=0) > 10).astype(int)
        gaps = []
        run = 0
        for v in cols:
            if v == 0:
                run += 1
            else:
                if run > 2:
                    gaps.append(run)
                run = 0
        if run > 2:
            gaps.append(run)
        n_content = len(gaps) + (1 if cols.max() > 0 else 0)
        # frames of equal width would be size/frames - report if the sheet
        # holds more disconnected clusters than the XML claims
        if xml != "?" and n_content > int(xml):
            print(f"  {place}/{f}: {im.size} xml={xml} clusters={n_content}"
                  f" -> SLICE NEEDED")
print("AUDIT DONE")
