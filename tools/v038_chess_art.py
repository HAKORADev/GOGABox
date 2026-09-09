#!/usr/bin/env python3
"""v038_chess_art.py - CHECKMATE (v0.3.8) piece sets. 100% original art.

Four skins, six pieces each, two colors (w_*.png / b_*.png), 128px:
  classic  the free Staunton-flavored set - cream vs charcoal, warm outline
  minimal  the flat geometric set - clean shapes, no fuss
  bold     the chunky set - thick outlines, heavy base
  royal    the gilded set - gold outline + a gem dot on the crown pieces

Every silhouette is a hand-placed profile. Five pieces are symmetric
(half-outline mirrored); the knight is the one side-view exception, as
knights have always been. Drawn at 256, downscaled to 128.
NOTHING here is copied from the studied app.

Re-derive: python3 tools/v038_chess_art.py
"""
import os
from PIL import Image, ImageDraw

OUT = "projects/gogabox/assets/games/chess"
SS = 256   # supersample canvas
FS = 128   # final size
CX = SS / 2


def mirror(pts):
    """a half-profile (starts on the left base, ends on the axis x=0) ->
    the full closed outline"""
    out = list(pts)
    for x, y in reversed(pts):
        if abs(x) > 0.01:
            out.append((-x, y))
    return out


def render(layers, outline, ow, gems, sym=True):
    """layers: [(pts, fill)]; gems: [(x, y, r, col)] - all in profile units
    (y: 0 top .. 200 base bottom). Rendered at SS, downscaled to FS.
    sym=False draws the half-profile AS-IS (the knight)."""
    img = Image.new("RGBA", (SS, SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # profile y 0..200 maps to canvas y 30..230
    def m(pt):
        x, y = pt
        return (CX + x, 30 + y)
    for pts, fill in layers:
        full = mirror(pts) if sym else pts
        d.polygon([m(p) for p in full], fill=fill, outline=outline,
                  width=ow)
    for gx, gy, gr, gcol in gems:
        x, y, r = CX + gx, 30 + gy, gr
        d.ellipse([x - r, y - r, x + r, y + r], fill=gcol, outline=outline,
                  width=max(1, ow // 2))
    return img.resize((FS, FS), Image.LANCZOS)


# ---------------------------------------------------------------- profiles
# half-outlines: start bottom-LEFT, climb, end on the center axis (x=0).

def base(w=62, h=16):
    return [(-w, 200), (-w, 200 - h), (-w * 0.70, 200 - h - 8)]


def pawn():
    return base(56) + [
        (-34, 176), (-26, 162), (-22, 146),
        (-14, 132), (-12, 112), (-20, 96), (-22, 82),
        (-14, 70), (-6, 64), (0, 63),
    ]


def rook():
    return base(62) + [
        (-46, 184), (-40, 170), (-34, 162),
        (-34, 92), (-44, 84), (-44, 52),
        (-32, 52), (-32, 64), (-18, 64), (-18, 52),
        (-6, 52),
    ]


def knight():
    """the ASYMMETRIC one - a side profile facing left, no mirror.
    The muzzle is a real horizontal protrusion, the ears two small
    triangles, the mane an S-curve down to the base."""
    return [
        (-42, 200), (-48, 178), (-50, 158),
        (-44, 138), (-38, 122),
        (-50, 114), (-58, 106), (-60, 96),
        (-52, 86), (-44, 88),
        (-42, 74), (-32, 62),
        (-28, 46), (-18, 58),
        (-10, 46), (2, 62),
        (12, 84), (22, 112), (30, 142), (36, 170), (40, 200),
    ]


def bishop():
    return base(56) + [
        (-34, 176), (-26, 162), (-30, 144),
        (-32, 124), (-24, 100), (-16, 76), (-8, 60), (0, 54),
    ]


def queen():
    return base(62) + [
        (-42, 178), (-34, 162), (-34, 140), (-36, 118),
        # the crown: spike, valley, spike, valley
        (-46, 88), (-36, 96), (-28, 72), (-18, 96), (-8, 78), (0, 96),
    ]


def king():
    return base(62) + [
        (-40, 180), (-32, 164), (-32, 142), (-34, 120),
        (-38, 96), (-34, 74), (-22, 62),
        # the cross, half of it: bar right edge up + the crossbar arm
        (-8, 58), (-8, 40), (-16, 40), (-16, 26), (-8, 26), (-8, 6), (0, 4),
    ]


SETS = {
    "classic": {
        "w": ((245, 234, 214, 255), (92, 70, 50, 255), 7, 1.0),
        "b": ((58, 47, 40, 255), (216, 201, 168, 255), 7, 1.0),
    },
    "minimal": {
        "w": ((250, 246, 236, 255), (120, 110, 96, 255), 5, 0.94),
        "b": ((70, 66, 60, 255), (170, 162, 150, 255), 5, 0.94),
    },
    "bold": {
        "w": ((246, 234, 210, 255), (66, 48, 30, 255), 11, 1.06),
        "b": ((52, 42, 36, 255), (232, 216, 180, 255), 11, 1.06),
    },
    "royal": {
        "w": ((244, 230, 200, 255), (196, 148, 52, 255), 8, 1.0),
        "b": ((56, 46, 40, 255), (222, 176, 80, 255), 8, 1.0),
    },
}


def scale_pts(pts, s):
    return [(x * s, y) for x, y in pts]


def build(body, outline, ow, s):
    """s scales the widths so the sets read differently, not just colors"""
    pcs = {}
    pcs["pawn"] = render([(scale_pts(pawn(), s), body)], outline, ow, [])
    pcs["rook"] = render([(scale_pts(rook(), s), body)], outline, ow, [])
    pcs["knight"] = render([(scale_pts(knight(), s), body)], outline, ow, [], sym=False)
    pcs["bishop"] = render([(scale_pts(bishop(), s), body)], outline, ow,
                           [(0, 40, 9 * s, (body[0], body[1], body[2], 255))])
    pcs["queen"] = render([(scale_pts(queen(), s), body)], outline, ow,
                          [(0, 60, 10 * s, (body[0], body[1], body[2], 255))])
    pcs["king"] = render([(scale_pts(king(), s), body)], outline, ow, [])
    return pcs


def main():
    print("v038_chess_art: four sets, six pieces, two colors")
    for set_id, cols in SETS.items():
        od = os.path.join(OUT, set_id)
        os.makedirs(od, exist_ok=True)
        for color, (body, outline, ow, s) in cols.items():
            for pid, img in build(body, outline, ow, s).items():
                img.save(os.path.join(od, f"{color}_{pid}.png"))
    print(f"  wrote {len(SETS) * 2 * 6} piece pngs under {OUT}/<set>/")


if __name__ == "__main__":
    main()
