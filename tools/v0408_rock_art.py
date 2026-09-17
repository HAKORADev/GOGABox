#!/usr/bin/env python3
"""v040-8 ROCK BREAKER asset forge - the Crazy Caves study sprites
(study_out/rockbreaker/cc, Gamesnacks 1.0.0 HTML5 bundle) are CODE-MODIFIED
into our own assets (the usage law: zero original bytes ship - every file
out of this script is a transform: desaturation, re-light, recolor,
composite, procedural detail on top).

Outputs -> projects/gogabox/assets/games/rockbreaker/
  rocks/  rock_<style>_<sz>.png     3 sizes x 5 theme materials (tint-ready)
          crack_1/2/3.png            baked damage webs (alpha)
  cannon/ body_<skin>.png           carriage + barrel per skin
          wheel_<skin>.png           spoked wheel per skin (spins in engine)
  world/  far_<style>_<place>.png   far decor strip (alpha top)
          ground_<style>.png         the ground strip
"""
import os
import math
import random
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance, ImageOps

CC = "/home/z/my-project/study_out/rockbreaker/cc"
OUT = "/home/z/my-project/gogabox/projects/gogabox/assets/games/rockbreaker"
for d in ["rocks", "cannon", "world"]:
    os.makedirs(f"{OUT}/{d}", exist_ok=True)

# ---------------------------------------------------------------- helpers
def lum(im):
    """RGBA -> grayscale luminance keeping alpha."""
    g = ImageOps.grayscale(im)
    r, _, b, a = im.split()
    return Image.merge("RGBA", (g, g, g, a))

def autolevel(im, lo=0.0, hi=1.0):
    """stretch luminance into [lo,hi] (per channel on rgb)."""
    a = im.getdata()
    px = [(p[0], p[1], p[2], p[3]) for p in a]
    mn = min(min(p[0], p[1], p[2]) for p in px if p[3] > 8)
    mx = max(max(p[0], p[1], p[2]) for p in px if p[3] > 8)
    rng = max(1, mx - mn)
    out = Image.new("RGBA", im.size)
    out.putdata([
        (int(255 * (lo + (hi - lo) * ((p[0] - mn) / rng))),
         int(255 * (lo + (hi - lo) * ((p[1] - mn) / rng))),
         int(255 * (lo + (hi - lo) * ((p[2] - mn) / rng))), p[3])
        for p in px])
    return out

def tint_gray(im, color, strength=1.0):
    """multiply a grayscale image by color (r,g,b floats) - the tintable
    base law: the engine modulates the same way at runtime."""
    r, g, b, a = im.split()
    r = r.point(lambda v: int(v * color[0] * strength))
    g = g.point(lambda v: int(v * color[1] * strength))
    b = b.point(lambda v: int(v * color[2] * strength))
    return Image.merge("RGBA", (r, g, b, a))

def outline(im, color=(20, 16, 12, 255), w=3):
    """hard dark outline around the alpha shape."""
    a = im.split()[3]
    edge = a.filter(ImageFilter.MaxFilter(w * 2 + 1))
    base = Image.new("RGBA", im.size, color)
    base.putalpha(edge)
    base.alpha_composite(im)
    return base

# ================================================================ ROCKS
# the study's 3 sizes -> our 5-size family: s (1-2), m (3), l (4-5)
SIZES = {"s": "e_small_r.png", "m": "e_medium_r.png", "l": "e_big_r.png"}

def rock_base(sz):
    """the desaturated, re-lit, tint-ready stone base from the study sprite."""
    im = Image.open(f"{CC}/{SIZES[sz]}").convert("RGBA")
    g = lum(im)
    g = autolevel(g, 0.30, 1.0)          # body ~0.3..1.0 - tint space
    # re-light: soft radial shade (top-left key light, bottom-right ao)
    w, h = g.size
    shade = Image.new("L", (w, h), 0)
    sd = ImageDraw.Draw(shade)
    cx, cy, rr = w * 0.38, h * 0.34, max(w, h) * 0.75
    for i in range(28):
        t = i / 27.0
        rad = rr * (1.0 - t * 0.85)
        v = int(34 - 30 * t)            # bright center -> slight dim edge
        sd.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=max(0, v))
    shade = shade.filter(ImageFilter.GaussianBlur(6))
    sh = Image.merge("RGBA", (shade, shade, shade, Image.new("L", (w, h), 255)))
    g = Image.composite(g, Image.new("RGBA", (w, h), (0, 0, 0, 0)), g.split()[3])
    lit = Image.new("RGBA", (w, h))
    lit = Image.alpha_composite(lit, g)
    # multiply by the shade (normalize around 1.0: 255 = neutral)
    n = shade.point(lambda v: 255 - int((255 - v) * 0.55))
    lit = tint_gray(lit, (1.0, 1.0, 1.0))
    r, gg, b, al = lit.split()
    r = ImageChops_Mul(r, n); gg = ImageChops_Mul(gg, n); b = ImageChops_Mul(b, n)
    lit = Image.merge("RGBA", (r, gg, b, al))
    return outline(lit, (24, 18, 14, 255), 3 if sz != "l" else 4)

from PIL import ImageChops as _IC
def ImageChops_Mul(a, b):
    return _IC.multiply(a, b)

def px_posterize(im, levels=5, pix=2):
    w, h = im.size
    small = im.resize((max(2, w // pix), max(2, h // pix)), Image.NEAREST)
    r, g, b, a = small.split()
    step = 255.0 / (levels - 1)
    rq = lambda v: int(round(v / step) * step)
    r = r.point(rq); g = g.point(rq); b = b.point(rq)
    out = Image.merge("RGBA", (r, g, b, a))
    # hard outline reads pixel-perfect
    out = outline(out, (16, 14, 18, 255), 2)
    return out.resize((w, h), Image.NEAREST)

def wood_rings(im, sz):
    """bake growth rings into the grayscale base."""
    w, h = im.size
    rings = Image.new("L", (w, h), 255)
    rd = ImageDraw.Draw(rings)
    rng = random.Random(77 + hash(sz) % 13)
    cx, cy = w * 0.46, h * 0.52
    for i in range(9):
        rr = (i + 1) * max(w, h) / 11.0 + rng.uniform(-3, 3)
        rd.ellipse([cx - rr, cy - rr * 0.92, cx + rr, cy + rr * 0.92],
                   outline=int(255 - 26 - (i % 3) * 12), width=3)
    rings = rings.filter(ImageFilter.GaussianBlur(1.4))
    r, g, b, a = im.split()
    r = _IC.multiply(r, rings); g = _IC.multiply(g, rings); b = _IC.multiply(b, rings)
    return Image.merge("RGBA", (r, g, b, a))

def candy_gloss(im):
    w, h = im.size
    gl = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(gl)
    gd.ellipse([w * 0.16, h * 0.10, w * 0.46, h * 0.30], fill=(255, 255, 255, 170))
    gd.ellipse([w * 0.24, h * 0.14, w * 0.40, h * 0.24], fill=(255, 255, 255, 200))
    gd.ellipse([w * 0.58, h * 0.55, w * 0.66, h * 0.63], fill=(255, 255, 255, 120))
    return Image.alpha_composite(im, gl)

def neon_core(im):
    """bright fill (the owner's FILLED-FROM-INSIDE law) that still carries
    the facet structure - the runtime tint does the hue, the seams stay."""
    g = lum(im)
    g = autolevel(g, 0.44, 0.98)
    # punch the facet seams dark so the tint reads structured
    e = g.split()[3].filter(ImageFilter.FIND_EDGES)
    e = e.filter(ImageFilter.MaxFilter(5))
    dark = Image.new("RGBA", g.size, (30, 26, 52, 255))
    dark.putalpha(e.point(lambda v: min(210, v * 4)))
    g = Image.alpha_composite(g, dark)
    # inner glow rim: lighten a band just inside the outline
    w, h = g.size
    rim = Image.new("L", (w, h), 0)
    rd = ImageDraw.Draw(rim)
    rd.ellipse([w*0.08, h*0.08, w*0.92, h*0.92], outline=150, width=6)
    rim = rim.filter(ImageFilter.GaussianBlur(3))
    rr, rg2, rb, ra = g.split()
    add = _IC.add(rr, rim); ag = _IC.add(rg2, rim); ab = _IC.add(rb, rim)
    g = Image.merge("RGBA", (add, ag, ab, ra))
    return outline(g, (18, 14, 30, 255), 3)

STYLES = {
    "stone":  lambda im, sz: im,
    "wood":   lambda im, sz: wood_rings(im, sz),
    "pixel":  lambda im, sz: px_posterize(
            autolevel(im, 0.42, 1.0), 5, 2),
    "neon":   lambda im, sz: neon_core(Image.open(f"{CC}/{SIZES[sz]}").convert("RGBA")),
    "candy":  lambda im, sz: candy_gloss(im),
}

for style, fn in STYLES.items():
    for sz in SIZES:
        base = rock_base(sz) if style != "neon" else None
        im = fn(base, sz)
        im.save(f"{OUT}/rocks/rock_{style}_{sz}.png")
        print("rock", style, sz, im.size)

# ------------------------------------------------------------- cracks
for lvl in (1, 2, 3):
    S = 260
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rng = random.Random(400 + lvl * 17)
    ink = (28, 20, 16, 235)
    webs = lvl + 2
    for w_i in range(webs):
        pts = []
        x, y = rng.uniform(S * 0.28, S * 0.72), rng.uniform(S * 0.28, S * 0.72)
        ang = rng.uniform(0, math.tau)
        segs = 7 + lvl * 3
        for seg in range(segs):
            pts.append((x, y))
            ang += rng.uniform(-0.75, 0.75)
            step = rng.uniform(S * 0.06, S * 0.12)
            x = max(6, min(S - 6, x + math.cos(ang) * step))
            y = max(6, min(S - 6, y + math.sin(ang) * step))
        d.line(pts, fill=ink, width=6 if lvl < 3 else 8, joint="curve")
        # short branch spurs off every other joint
        for j in range(1, len(pts) - 1, 2):
            bx, by = pts[j]
            ba = rng.uniform(0, math.tau)
            bl = rng.uniform(S * 0.05, S * 0.13)
            d.line([(bx, by), (bx + math.cos(ba) * bl, by + math.sin(ba) * bl)],
                   fill=ink, width=4, joint="curve")
        for p in (pts[0], pts[-1]):
            d.ellipse([p[0] - 5, p[1] - 5, p[0] + 5, p[1] + 5], fill=ink)
    im = im.filter(ImageFilter.GaussianBlur(0.6))
    im.save(f"{OUT}/rocks/crack_{lvl}.png")
    print("crack", lvl)

print("ROCKS DONE")
