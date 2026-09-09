#!/usr/bin/env python3
# ============================================================================
# v038p3_allies.py - THE ROSTER FACES (v0.3.8-3).
#
# The owner's report: "all allies have different effects yes and different
# descriptions, but based on the 3 ones i tested, all are same visual thing,
# no single different color at all ... you can design and draw using code
# and modify the assets directly and visualize them".
#
# The old allies reused ENEMY textures with a near-white tint - six jobs,
# four faces, zero identity. This tool DRAWS the roster: six potato crew
# members in the hero art's own style (golden body, white eyes, dark
# brows, soft shading, dark outline), each with its own STRONG color and
# its own role gear:
#
#   drone   DRONE BUDDY   teal   rotor cap + cyan visor
#   turret  TATER TURRET  orange steel hard hat + ammo band
#   guard   GUARD SPUD    green  steel riot shield + green band
#   medic   MEDIC SPROUT  white  medic helmet + red cross
#   bomber  BOMBER CHIP   red    lit fuse + black bandolier
#   scout   SCOUT FRY     yellow goggles + yellow scarf
#
# Output: assets/games/cosmic_spud/allies/ally_<id>.png (96x96, the enemy
# canvas) + /tmp/allies_sheet.png for the eyeball check.
# Deterministic - re-runs are pixel-identical.
# ============================================================================
import os
import math
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "games", "cosmic_spud", "allies")
S = 96
C = S // 2

OUTLINE = (52, 34, 22, 255)
BODY = (222, 168, 96)          # the hero gold
BODY_LO = (186, 132, 66)       # the shaded under
BODY_HI = (240, 196, 128)      # the lit top
EYE_W = (250, 248, 242, 255)
PUPIL = (40, 32, 28, 255)
BROW = (58, 38, 24, 255)
MOUTH = (120, 78, 44, 255)


def body(dr, cx=S * 0.5, cy=S * 0.56, rx=26, ry=30, tint=None, seed=0):
    """The shared potato: a soft pear-ish blob with shading + outline."""
    # slight deterministic lean per ally so silhouettes differ
    lean = math.sin(seed * 2.3) * 2.0
    top = BODY_HI if tint is None else tuple(min(255, int(c * 1.12)) for c in tint[:3]) + (255,)
    base = BODY if tint is None else tint[:3] + (255,)
    lo = BODY_LO if tint is None else tuple(int(c * 0.78) for c in tint[:3]) + (255,)
    # body: two overlapping ellipses (a potato is not a circle)
    dr.ellipse([cx - rx + lean, cy - ry, cx + rx + lean, cy + ry],
               fill=lo)
    dr.ellipse([cx - rx + lean, cy - ry, cx + rx + lean, cy + ry * 0.96],
               fill=base)
    dr.ellipse([cx - rx * 0.62 + lean, cy - ry * 0.92, cx + rx * 0.72 + lean,
                cy - ry * 0.18], fill=top)
    # outline: draw the silhouette ring
    dr.ellipse([cx - rx + lean, cy - ry, cx + rx + lean, cy + ry],
               outline=OUTLINE, width=3)
    # potato dimples
    dr.arc([cx - rx * 0.4 + lean, cy + ry * 0.15, cx + rx * 0.1 + lean,
            cy + ry * 0.55], 200, 340, fill=lo, width=2)


def eyes(dr, cx=S * 0.5, ey=S * 0.5, gap=9.5, r=6.0, pupil_dy=1.0, angry=True):
    for sgn in (-1, 1):
        ex = cx + sgn * gap
        dr.ellipse([ex - r, ey - r, ex + r, ey + r], fill=EYE_W,
                   outline=OUTLINE, width=2)
        pr = r * 0.52
        dr.ellipse([ex - pr + sgn * 0.8, ey - pr + pupil_dy,
                    ex + pr + sgn * 0.8, ey + pr + pupil_dy], fill=PUPIL)
        if angry:
            # the hero brow: a short diagonal slab
            dr.line([ex - r - 2, ey - r - 3 + (2 if sgn < 0 else 0),
                     ex + r + 1, ey - r - 1 - (2 if sgn < 0 else 0)],
                    fill=BROW, width=3)


def mouth(dr, cx=S * 0.5, my=S * 0.72, w=10.0, frown=False):
    if frown:
        dr.arc([cx - w, my - 4, cx + w, my + 6], 20, 160, fill=MOUTH, width=3)
    else:
        dr.arc([cx - w, my - 6, cx + w, my + 4], 200, 340, fill=MOUTH, width=3)


# ---------------------------------------------------------------- the six

def draw_drone():
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dr = ImageDraw.Draw(im)
    body(dr, tint=(94, 196, 186), seed=1)
    # the rotor: a steel mast + a spinning blade bar (the hover drone reads)
    dr.line([C, 10, C, 22], fill=(110, 118, 128, 255), width=4)
    dr.rounded_rectangle([C - 26, 8, C + 26, 15], 4, fill=(150, 158, 170, 255),
                         outline=OUTLINE, width=2)
    dr.rounded_rectangle([C - 6, 6, C + 6, 17], 3, fill=(94, 196, 186, 255),
                         outline=OUTLINE, width=2)
    # the cyan visor: ONE strip above the eyes (the eyes stay the hero's)
    dr.rounded_rectangle([C - 18, 28, C + 18, 38], 5,
                         fill=(38, 48, 56, 255), outline=OUTLINE, width=2)
    dr.rounded_rectangle([C - 14, 31, C + 2, 35], 2,
                         fill=(126, 240, 255, 255))
    eyes(dr, ey=S * 0.52, pupil_dy=1.0)
    mouth(dr, my=S * 0.74, w=8)
    # hover puff
    dr.ellipse([C - 10, S - 12, C + 10, S - 2], fill=(180, 226, 224, 160))
    return im


def draw_turret():
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dr = ImageDraw.Draw(im)
    body(dr, cy=S * 0.60, rx=27, ry=27, tint=(238, 150, 66), seed=2)
    eyes(dr, ey=S * 0.52, pupil_dy=1.0)
    mouth(dr, my=S * 0.74, w=8)
    # the steel hard hat
    dr.pieslice([C - 20, 8, C + 20, 40], 180, 360, fill=(158, 166, 178, 255),
                outline=OUTLINE, width=3)
    dr.rounded_rectangle([C - 24, 32, C + 24, 40], 3, fill=(126, 134, 146, 255),
                         outline=OUTLINE, width=2)
    dr.rounded_rectangle([C - 6, 4, C + 6, 12], 2, fill=(238, 150, 66, 255),
                         outline=OUTLINE, width=2)
    # the ammo band across the belly (never over the eyes)
    dr.line([C - 22, S * 0.72, C + 22, S * 0.66], fill=(96, 72, 40, 255), width=6)
    for i in range(4):
        bx = C - 18 + i * 11
        by = S * 0.72 - i * 2.2
        dr.ellipse([bx - 3, by - 5, bx + 3, by + 1], fill=(222, 176, 92, 255),
                   outline=OUTLINE, width=1)
    return im


def draw_guard():
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dr = ImageDraw.Draw(im)
    body(dr, rx=25, ry=29, tint=(126, 186, 108), seed=3)
    eyes(dr, ey=S * 0.48, pupil_dy=1.0)
    mouth(dr, my=S * 0.70, w=9)
    # the green band (the soldier's own, the squad mark)
    dr.rounded_rectangle([C - 21, 22, C + 21, 32], 4, fill=(70, 140, 66, 255),
                         outline=OUTLINE, width=2)
    # the riot shield: a steel plate held in front, left-hand side
    dr.rounded_rectangle([4, 30, 30, 86], 8, fill=(168, 178, 192, 255),
                         outline=OUTLINE, width=3)
    dr.rounded_rectangle([9, 35, 25, 81], 6, outline=(126, 136, 150, 255),
                         width=3)
    dr.ellipse([13, 40, 21, 48], fill=(94, 196, 110, 255), outline=OUTLINE,
               width=2)
    # rivets
    for yy in (58, 72):
        dr.ellipse([15, yy - 2, 19, yy + 2], fill=(116, 126, 140, 255))
    return im


def draw_medic():
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dr = ImageDraw.Draw(im)
    body(dr, tint=(226, 214, 196), seed=4)
    eyes(dr, ey=S * 0.50, pupil_dy=0.5, angry=False)
    mouth(dr, my=S * 0.72, w=7)
    # the medic helmet: white round cap with the red cross
    dr.pieslice([C - 22, 6, C + 22, 44], 180, 360, fill=(244, 242, 236, 255),
                outline=OUTLINE, width=3)
    dr.rounded_rectangle([C - 25, 36, C + 25, 44], 3, fill=(216, 210, 200, 255),
                         outline=OUTLINE, width=2)
    # the red cross on the helmet
    dr.rounded_rectangle([C - 3, 12, C + 3, 30], 2, fill=(212, 62, 54, 255))
    dr.rounded_rectangle([C - 9, 18, C + 9, 24], 2, fill=(212, 62, 54, 255))
    # the satchel strap (under the mouth - the care reads, not a bandolier)
    dr.line([C - 18, S * 0.78, C + 20, S * 0.86], fill=(180, 66, 58, 255), width=5)
    return im


def draw_bomber():
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dr = ImageDraw.Draw(im)
    body(dr, cy=S * 0.58, rx=26, ry=28, tint=(94, 88, 92), seed=5)
    eyes(dr, ey=S * 0.50, pupil_dy=1.0)
    mouth(dr, my=S * 0.72, w=8)
    # the fuse: a curl on top with a lit spark
    dr.line([C, 12, C + 2, 24], fill=(212, 176, 120, 255), width=4)
    dr.arc([C - 2, 6, C + 10, 18], 270, 180, fill=(212, 176, 120, 255), width=4)
    dr.ellipse([C - 4, 2, C + 6, 12], fill=(255, 196, 64, 255))
    dr.ellipse([C - 1, 5, C + 3, 9], fill=(255, 244, 180, 255))
    # the black bandolier + red buckle (low, the face stays clear)
    dr.line([C - 20, S * 0.70, C + 22, S * 0.80], fill=(38, 34, 38, 255), width=7)
    dr.rounded_rectangle([C + 8, S * 0.74, C + 18, S * 0.84], 2,
                         fill=(212, 62, 54, 255), outline=OUTLINE, width=2)
    return im


def draw_scout():
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dr = ImageDraw.Draw(im)
    # the fry: the smallest body (a scout runs light)
    body(dr, cy=S * 0.58, rx=22, ry=25, tint=(238, 202, 92), seed=6)
    eyes(dr, ey=S * 0.50, gap=8.0, r=5.5, pupil_dy=1.0)
    mouth(dr, my=S * 0.72, w=7)
    # the yellow goggles (the scout's own hero-gear, pushed up)
    dr.rounded_rectangle([C - 19, 26, C + 19, 38], 6, fill=(70, 58, 34, 255),
                         outline=OUTLINE, width=2)
    for sgn in (-1, 1):
        ex = C + sgn * 9
        dr.ellipse([ex - 7, 28, ex + 7, 40], fill=(250, 214, 96, 255),
                   outline=OUTLINE, width=2)
    # the scarf (under the mouth)
    dr.rounded_rectangle([C - 14, S * 0.74, C + 14, S * 0.82], 4,
                         fill=(226, 168, 54, 255), outline=OUTLINE, width=2)
    dr.polygon([C + 8, S * 0.81, C + 20, S * 0.88, C + 12, S * 0.91],
               fill=(226, 168, 54, 255), outline=OUTLINE)
    return im


MAKERS = {
    "drone": draw_drone,
    "turret": draw_turret,
    "guard": draw_guard,
    "medic": draw_medic,
    "bomber": draw_bomber,
    "scout": draw_scout,
}


def main():
    os.makedirs(OUT, exist_ok=True)
    sheet = Image.new("RGBA", (S * 6, S + 26), (44, 44, 50, 255))
    sdr = ImageDraw.Draw(sheet)
    for i, (aid, maker) in enumerate(MAKERS.items()):
        im = maker()
        path = os.path.join(OUT, f"ally_{aid}.png")
        im.save(path)
        sheet.paste(im, (i * S, 0), im)
        sdr.text((i * S + 18, S + 5), aid, fill=(240, 240, 240, 255))
    sheet.save("/tmp/allies_sheet.png")
    print("wrote", len(MAKERS), "ally faces + /tmp/allies_sheet.png")


if __name__ == "__main__":
    main()
