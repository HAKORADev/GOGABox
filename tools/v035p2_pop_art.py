#!/usr/bin/env python3
"""v0.3.5-2 POP SIEGE - the difficulty art patch.

Built ON TOP of the v0.3.5-1 outputs (no source re-scrape needed):
  1. Bloon COLOR LEVELS (the owner's wheel law): every kind gets lv2..lv8
     recolors - a noticeable hue wheel step + brightness lift per level, so
     "black 003" reads instantly different from "black 001".
  2. ARMOR overlays: metal (only fire cracks it) + rock (only bombs crack
     it) - drawn as shells that sit ON the bloon at runtime.
  3. Two NEW blimp tiers (shapes are tiers, colors/stripes are contents):
     gargantua (the fat fortress) + titan (the sky leviathan).
  4. THE SCORE ICON: a layered bloon (bands = layers) for the HUD score
     chip - the owner asked for a bloon shape that reflects layers/damage.
"""
import os
import colorsys
from PIL import Image, ImageDraw, ImageFilter

REPO = "/home/z/my-project/repo/GOGABox"
OUT = f"{REPO}/projects/gogabox/assets/games/pop_siege"
FONT = f"{REPO}/projects/gogabox/assets/fonts/Kenney_Rocket.ttf"

def hsv_shift(im, dh, ds=1.0, dv=1.0):
    im = im.convert("RGBA")
    a = im.split()[3]
    rgb = im.convert("RGB")
    px = rgb.load()
    for y in range(rgb.height):
        for x in range(rgb.width):
            r, g, b = px[x, y]
            h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
            h = (h + dh / 360.0) % 1.0
            s = max(0.0, min(1.0, s * ds))
            v = max(0.0, min(1.0, v * dv))
            r2, g2, b2 = colorsys.hsv_to_rgb(h, s, v)
            px[x, y] = (int(r2 * 255), int(g2 * 255), int(b2 * 255))
    rgb.putalpha(a)
    return rgb

def save(im, rel):
    p = os.path.join(OUT, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    im.save(p)
    print("  +", rel, im.size)

# ================================================================ 1. LEVELS
# THE WHEEL LAW: lv1 = the honest kind art. Each extra level rotates the hue
# 36 deg (a tenth of the wheel - the human eye catches it) and lifts the
# value a touch, so dark kinds (black/lead) brighten into visible color.
MAX_LV = 8

def build_levels():
    print("== bloon color levels ==")
    for k in ["red", "blue", "green", "yellow", "pink", "black", "white",
              "zebra", "lead", "rainbow", "ceramic"]:
        base = Image.open(f"{OUT}/bloons/{k}.png").convert("RGBA")
        for lv in range(2, MAX_LV + 1):
            step = lv - 1
            # hue wheel step + gentle saturation/value growth (visible, loud)
            im = hsv_shift(base, dh=36.0 * step, ds=1.0 + 0.06 * step, dv=1.0 + 0.05 * step)
            save(im, f"bloons/{k}_lv{lv}.png")
    # the blimps wear levels too (moab + brutus only recolor well; the new
    # tiers keep their own silhouettes and get the wheel from lv2 on)
    for k in ["moab", "brutus", "gargantua", "titan"]:
        base = Image.open(f"{OUT}/bloons/{k}.png").convert("RGBA")
        for lv in range(2, MAX_LV + 1):
            step = lv - 1
            im = hsv_shift(base, dh=30.0 * step, ds=1.0 + 0.05 * step, dv=1.0 + 0.05 * step)
            save(im, f"bloons/{k}_lv{lv}.png")

# ================================================================ 2. ARMOR
def vertical_gradient(w, h, stops):
    im = Image.new("RGB", (1, h))
    px = im.load()
    for y in range(h):
        t = y / max(1, h - 1)
        for i in range(len(stops) - 1):
            p0, c0 = stops[i]
            p1, c1 = stops[i + 1]
            if p0 <= t <= p1:
                kk = (t - p0) / max(0.0001, p1 - p0)
                px[0, y] = tuple(int(c0[j] + (c1[j] - c0[j]) * kk) for j in range(3))
                break
    return im.resize((w, h))

def armor_plate(kind):
    """a round shell that covers the bloon: metal riveted plates / rock crust.
    The game draws it OVER the bloon sprite and hides it when cracked."""
    S = 2
    w, h = 116 * S, 116 * S
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy, rx, ry = w // 2, h // 2, 52 * S, 50 * S
    if kind == "metal":
        grad = vertical_gradient(rx * 2, ry * 2,
                                 [(0.0, (232, 238, 246)), (0.5, (168, 178, 192)), (1.0, (96, 104, 118))])
    else:
        grad = vertical_gradient(rx * 2, ry * 2,
                                 [(0.0, (168, 148, 122)), (0.5, (126, 108, 88)), (1.0, (78, 64, 50))])
    mask = Image.new("L", (rx * 2, ry * 2), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, rx * 2 - 1, ry * 2 - 1], fill=255)
    im.paste(grad, (cx - rx, cy - ry), mask)
    ink = (40, 34, 28, 255) if kind == "rock" else (52, 58, 68, 255)
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], outline=ink, width=3 * S)
    if kind == "metal":
        # riveted plates: a cross seam + rivets
        d.line([cx - rx, cy, cx + rx, cy], fill=ink, width=2 * S)
        d.line([cx, cy - ry, cx, cy + ry], fill=ink, width=2 * S)
        for ox in (-1, 1):
            for oy in (-1, 1):
                px_, py_ = cx + ox * rx * 0.5, cy + oy * ry * 0.5
                d.ellipse([px_ - 4 * S, py_ - 4 * S, px_ + 4 * S, py_ + 4 * S],
                          fill=(210, 216, 226, 255), outline=ink, width=S)
        # the sheen
        d.arc([cx - rx + 6 * S, cy - ry + 6 * S, cx + rx - 6 * S, cy + ry - 6 * S], 200, 320,
              fill=(255, 255, 255, 190), width=3 * S)
    else:
        # rock crust: angular chunks + cracks
        for i in range(7):
            import math as _m
            a0 = _m.tau * i / 7.0
            px_, py_ = cx + _m.cos(a0) * rx * 0.62, cy + _m.sin(a0) * ry * 0.62
            r_ = 13 * S
            d.polygon([(px_ - r_, py_), (px_, py_ - r_), (px_ + r_, py_ + r_ * 0.4), (px_ - r_ * 0.4, py_ + r_)],
                      fill=(140, 120, 96, 255), outline=ink)
        d.line([cx - rx * 0.5, cy - ry * 0.2, cx - rx * 0.1, cy + ry * 0.15, cx - rx * 0.3, cy + ry * 0.55],
               fill=(46, 34, 24, 255), width=2 * S, joint="curve")
        d.line([cx + rx * 0.45, cy - ry * 0.5, cx + rx * 0.15, cy], fill=(46, 34, 24, 255), width=2 * S)
    return im

def build_armor():
    print("== armor shells ==")
    save(armor_plate("metal"), "bloons/armor_metal.png")
    save(armor_plate("rock"), "bloons/armor_rock.png")

# ================================================================ 3. BLIMPS
def vertical_gradient_rgba(w, h, stops):
    im = Image.new("RGBA", (1, h))
    px = im.load()
    for y in range(h):
        t = y / max(1, h - 1)
        for i in range(len(stops) - 1):
            p0, c0 = stops[i]
            p1, c1 = stops[i + 1]
            if p0 <= t <= p1:
                kk = (t - p0) / max(0.0001, p1 - p0)
                px[0, y] = tuple(min(255, int(c0[j] + (c1[j] - c0[j]) * kk)) for j in range(4))
                break
    return im.resize((w, h))

def blimp_tier(tier):
    """shapes are TIERS: moab=blimp, brutus=spiked blimp, gargantua=the fat
    twin-gondola fortress, titan=the huge finned leviathan."""
    S = 2
    if tier == "gargantua":
        w, h = 300 * S // 2, 220 * S // 2
    else:
        w, h = 340 * S // 2, 240 * S // 2
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    if tier == "gargantua":
        hull, dark, accent = (86, 158, 96), (40, 84, 48), (250, 226, 120)
    else:
        hull, dark, accent = (150, 70, 190), (76, 30, 100), (120, 230, 250)
    ink = tuple(max(0, c - 70) for c in hull) + (255,)
    # hull: a fat double-lobe ellipse (fortress) / long hull (leviathan)
    gx0, gy0 = 12, 26
    gx1, gy1 = w - 12, h - 56
    grad = vertical_gradient_rgba(gx1 - gx0, gy1 - gy0,
                                  [(0.0, tuple(min(255, c + 60) for c in hull) + (255,)),
                                   (0.55, hull + (255,)), (1.0, dark + (255,))])
    mask = Image.new("L", (gx1 - gx0, gy1 - gy0), 0)
    md = ImageDraw.Draw(mask)
    if tier == "gargantua":
        md.ellipse([0, 0, gx1 - gx0 - 1, gy1 - gy0 - 1], fill=255)
        # the top turret bump
        md.ellipse([(gx1 - gx0) // 2 - 40, -18, (gx1 - gx0) // 2 + 40, 40], fill=255)
    else:
        md.ellipse([0, 0, gx1 - gx0 - 1, gy1 - gy0 - 1], fill=255)
        md.rectangle([(gx1 - gx0) // 2 - 26, 0, (gx1 - gx0) // 2 + 26, 26], fill=255)
    im.paste(grad, (gx0, gy0), mask)
    d = ImageDraw.Draw(im)
    if tier == "gargantua":
        d.ellipse([gx0, gy0, gx1, gy1], outline=ink, width=3)
        d.ellipse([(gx1 - gx0) // 2 - 40 + gx0, gy0 - 16, (gx1 - gx0) // 2 + 40 + gx0, gy0 + 42],
                  outline=ink, width=3)
        # twin gondolas
        for gx in (w // 2 - 74, w // 2 + 8):
            d.rounded_rectangle([gx, gy1 - 14, gx + 64, gy1 + 26], 8, fill=dark, outline=ink, width=2)
        # armor bands
        for i in range(3):
            bx = gx0 + 40 + i * (gx1 - gx0 - 100) // 2
            d.line([bx, gy0 + 8, bx, gy1 - 8], fill=dark, width=6)
    else:
        d.ellipse([gx0, gy0, gx1, gy1], outline=ink, width=3)
        # triple tail fins
        for fy in (gy0 + 2, (gy0 + gy1) // 2 - 14, gy1 - 18):
            d.polygon([(gx1 - 66, (gy0 + gy1) // 2), (gx1 + 4, fy), (gx1 - 26, (gy0 + gy1) // 2)],
                      fill=dark, outline=ink)
        # engine pods
        for i in range(3):
            ex = gx0 + 60 + i * (gx1 - gx0 - 130) // 2
            d.ellipse([ex - 16, gy1 - 6, ex + 16, gy1 + 22], fill=dark, outline=ink, width=2)
    # the face plate + angry eyes (the family look)
    d.ellipse([gx0 + 8, gy0 + (gy1 - gy0) * 0.2, gx0 + 74, gy1 - (gy1 - gy0) * 0.2],
              fill=accent, outline=ink, width=2)
    ex, ey = gx0 + 30, (gy0 + gy1) // 2
    for sgn in (0, 1):
        exx = ex + sgn * 20
        d.polygon([(exx - 8, ey - 10 + sgn * 2), (exx + 8, ey - 6), (exx - 2, ey + 2)],
                  fill=(250, 250, 250, 255), outline=ink)
        d.ellipse([exx - 3, ey - 3, exx + 5, ey + 5], fill=(30, 30, 34, 255))
    return im

def build_blimps():
    print("== new blimp tiers ==")
    save(blimp_tier("gargantua"), "bloons/gargantua.png")
    save(blimp_tier("titan"), "bloons/titan.png")

# ================================================================ 4. SCORE ICON
def build_score_icon():
    print("== the score icon (the layered bloon) ==")
    S = 3
    w = h = 64 * S
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy, rx, ry = w // 2, h // 2, 26 * S, 27 * S
    ink = (46, 28, 16, 255)
    # the body: warm red gloss
    grad = vertical_gradient(rx * 2, ry * 2, [(0.0, (255, 128, 116)), (0.5, (226, 60, 60)), (1.0, (150, 30, 30))])
    mask = Image.new("L", (rx * 2, ry * 2), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, rx * 2 - 1, ry * 2 - 1], fill=255)
    im.paste(grad, (cx - rx, cy - ry), mask)
    # THE LAYERS: horizontal bands (blue/yellow/green) = the layers inside
    bands = [(62, 122, 226), (242, 208, 40), (64, 190, 84)]
    bh = 5 * S
    band_im = Image.new("RGBA", (rx * 2, ry * 2), (0, 0, 0, 0))
    bd = ImageDraw.Draw(band_im)
    for i, c in enumerate(bands):
        y0 = int(ry * 0.30) + i * bh
        bd.rectangle([0, y0, rx * 2, y0 + bh - 1], fill=c + (235,))
    band_im = band_im.filter(ImageFilter.GaussianBlur(S // 2))
    im.paste(band_im, (cx - rx, cy - ry), mask)
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], outline=ink, width=2 * S)
    # the gloss knot + sheen
    d.ellipse([cx - 6 * S, cy - ry - 2 * S, cx + 6 * S, cy - ry + 7 * S], fill=ink)
    d.arc([cx - rx + 5 * S, cy - ry + 5 * S, cx + rx - 5 * S, cy + ry - 5 * S], 195, 320,
          fill=(255, 255, 255, 200), width=3 * S)
    save(im, "ui/ic_pops.png")

if __name__ == "__main__":
    build_blimps()
    build_levels()
    build_armor()
    build_score_icon()
    print("V0.3.5-2 ART DONE")
