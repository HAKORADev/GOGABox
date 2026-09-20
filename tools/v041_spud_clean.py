#!/usr/bin/env python3
"""v041 THE SPUD CLEAN - the owner: "every character has something that
looks like a bar on their bellies, also they have something like a bubble
on their head, i guess they have no meaning?... anyway they feel wrong".

They are the space-suit leftovers: a translucent glass DOME around the
head (the bubble) and the helmet's gray COLLAR bar across the belly.
Neither means anything in play. This pass erases the glass bubble and
inpaints the collar band out of every character sprite (hero / enemies /
allies), leaving the plain potato characters.
"""
from PIL import Image
import glob
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..",
                    "projects", "gogabox", "assets", "games", "cosmic_spud")


def is_glass(p):
    r, g, b, a = p
    # the dome's rim highlights ride up to near-opaque alpha - anything
    # translucent, bright and UNSATURATED is glass (the eyes are alpha 255,
    # the body/headband are saturated - both safe)
    return a < 253 and max(r, g, b) > 105 and (max(r, g, b) - min(r, g, b)) < 36


def is_gray_band(p):
    r, g, b, a = p
    return a > 200 and (max(r, g, b) - min(r, g, b)) < 18 and 60 < max(r, g, b) < 175


def clean(im):
    px = im.load()
    w, h = im.size
    # pass 1 - the glass bubble
    for y in range(h):
        for x in range(w):
            if is_glass(px[x, y]):
                px[x, y] = (0, 0, 0, 0)
    # pass 2 - the collar band: find the gray rows in the lower half, grow
    # the band by 2px (its dark outline), then fill each column vertically
    # from the body above to the body below
    rows = []
    for y in range(h // 2, h):
        n = 0
        for x in range(w // 5, w * 4 // 5):
            if is_gray_band(px[x, y]):
                n += 1
        if n >= 8:
            rows.append(y)
    if not rows:
        return False
    y0, y1 = max(0, rows[0] - 2), min(h - 1, rows[-1] + 2)
    changed = False
    for x in range(w):
        band = any(is_gray_band(px[x, y]) for y in range(y0, y1 + 1))
        if not band:
            continue
        ya = y0 - 1
        while ya > 0 and px[x, ya][3] < 200:
            ya -= 1
        yb = y1 + 1
        while yb < h - 1 and px[x, yb][3] < 200:
            yb += 1
        ca = px[x, ya]
        cb = px[x, yb]
        for y in range(y0, y1 + 1):
            t = (y - y0) / max(1, (y1 - y0))
            c = tuple(int(ca[i] * (1 - t) + cb[i] * t) for i in range(3)) \
                            + (255,)
            px[x, y] = c
            changed = True
    return changed


def main():
    fixed = 0
    total = 0
    for sub in ["hero", "enemies", "allies"]:
        for f in glob.glob(os.path.join(ROOT, sub, "*.png")):
            if f.endswith(".import"):
                continue
            total += 1
            im = Image.open(f).convert("RGBA")
            if clean(im):
                im.save(f)
                fixed += 1
    print("spud clean: %d/%d sprites inpainted" % (fixed, total))


if __name__ == "__main__":
    main()
