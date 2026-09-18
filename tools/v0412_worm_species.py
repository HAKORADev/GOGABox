#!/usr/bin/env python3
"""v040-12 DEADLY WORM - THE SPECIES LAW (the owner: "i guess you made all
worms same look but different coloring, if yes, that is wrong, they should
differ; why the hell a deadly worm has an eye? use the whole head to be
creative and make teeth, spike, whatever dangerous").

The ten worms are redrawn as TEN REAL SPECIES - each with its own head
architecture, its own arsenal of teeth/spikes/horns/mandibles, its own
body armor and its own tail. NO EYES anywhere: worms hunt blind, the
whole head is a weapon (feelers and barbs where the eye used to be).

Also: the two diggers are rebuilt - the lizard wears the reptile sprawl
(legs at its SIDES, belly on the ground, not under it like a cow) and
the mole is a proper digger with scoop paws - both LEFT-native (the
game's facing law).

Reuses the v0411 kit (Layer/gradients/outlines/grain). Deterministic.
"""
import importlib.util
import math
import os
import random

from PIL import Image, ImageDraw

_spec = importlib.util.spec_from_file_location(
    "ours", "/home/z/my-project/gogabox/tools/v0411_worm_ours.py")
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

OUT = K.OUT
S = 250                    # the head canvas
HPI = math.pi
INK = (24, 12, 10, 255)


def grad_poly(L, pts, top, bot, outline=INK, w=4):
    """a vertical-gradient polygon (mask + paste), then its outline."""
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    x0, y0 = int(min(xs)) - 2, int(min(ys)) - 2
    x1, y1 = int(max(xs)) + 2, int(max(ys)) + 2
    gw, gh = x1 - x0, y1 - y0
    if gw <= 0 or gh <= 0:
        return
    mask = Image.new("L", (gw, gh), 0)
    md = ImageDraw.Draw(mask)
    md.polygon([(px - x0, py - y0) for px, py in pts], fill=255)
    grad = Image.new("RGBA", (gw, gh), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad)
    for yy in range(gh):
        t = yy / max(1, gh - 1)
        gd.line([(0, yy), (gw, yy)], fill=K.with_a(K.mix(top, bot, t)))
    L.im.paste(grad, (x0, y0), mask)
    L.d.polygon(pts, outline=outline, width=w)


# ============================================================ THE SPECIES
# skin / belly / fin keep each worm's color identity; the SHAPES diverge.
WORMS = [
    {"id": "w01", "skin": (214, 60, 48), "belly": (240, 150, 110),
     "fin": (110, 118, 138), "glow": None},
    {"id": "w02", "skin": (44, 160, 150), "belly": (150, 232, 210),
     "fin": (30, 108, 116), "glow": None},
    {"id": "w03", "skin": (206, 164, 96), "belly": (238, 214, 160),
     "fin": (150, 112, 62), "glow": None},
    {"id": "w04", "skin": (150, 84, 200), "belly": (216, 170, 240),
     "fin": (94, 52, 140), "glow": None},
    {"id": "w05", "skin": (170, 24, 34), "belly": (236, 110, 96),
     "fin": (96, 14, 20), "glow": None},
    {"id": "w06", "skin": (128, 92, 62), "belly": (196, 156, 112),
     "fin": (84, 58, 38), "glow": None},
    {"id": "w07", "skin": (88, 170, 70), "belly": (178, 226, 140),
     "fin": (44, 110, 44), "glow": None},
    {"id": "w08", "skin": (140, 148, 158), "belly": (198, 206, 214),
     "fin": (86, 92, 104), "glow": (80, 230, 255)},
    {"id": "w09", "skin": (52, 44, 78), "belly": (110, 96, 150),
     "fin": (30, 24, 52), "glow": (120, 255, 190)},
    {"id": "w10", "skin": (230, 150, 36), "belly": (250, 208, 120),
     "fin": (160, 84, 20), "glow": None},
]
INK = (24, 12, 10, 255)
TOOTH = (250, 246, 230, 255)
TOOTH_D = (206, 196, 170, 255)
MAW = (44, 10, 12, 255)


def _fang(d, bx, by, w, h, down, col=TOOTH):
    """one irregular fang (down=False points up)."""
    tip = by + h if down else by - h
    lean = w * 0.35 * (1 if down else -1)
    d.polygon([(bx - w, by), (bx + w, by),
               (bx + lean * 0.4, tip * 0.4 + by * 0.6),
               (bx + lean, tip)],
              fill=col, outline=(70, 40, 30, 255))


def _spike(d, pts, col, outline=INK, w=4):
    d.polygon(pts, fill=col, outline=outline, width=w)


def _feelers(d, cx, cy, R, col, n=3, seed="f"):
    """blind-hunter feelers - the eye's replacement."""
    rr = random.Random(seed)
    for i in range(n):
        a = -0.9 + i * (1.1 / max(1, n - 1))
        bx, by = cx + R * math.cos(a) * 0.9, cy + R * math.sin(a) * 0.9
        tx, ty = cx + R * math.cos(a) * 1.45, cy + R * math.sin(a) * 1.5
        d.line([(bx, by), ((bx + tx) / 2 + R * 0.06, (by + ty) / 2),
                (tx, ty)], fill=col, width=max(3, int(R * 0.05)))
        K.draw_ellipse(d, tx, ty, R * 0.05, R * 0.05,
                       K.lighten(col[:3] if len(col) > 3 else col, 1.1))


# ---------------------------------------------------------------- heads
def species_head(w, open_mouth):
    wid = w["id"]
    skin, belly, fin = w["skin"], w["belly"], w["fin"]
    dark = K.darken(skin, 0.55)
    deeper = K.darken(skin, 0.4)
    L = K.Layer(S, S)
    d = L.d
    cx, cy = S * 0.46, S * 0.52
    R = S * 0.30
    rr = random.Random(wid + str(open_mouth))
    jaw = 0.62 if open_mouth else 0.16
    maw_y = cy + R * 0.34
    maw_w = R * 0.95
    maw_h = R * (0.30 + jaw * 0.85)

    if wid == "w01":
        # THE CLASSIC: the blunt death-worm mound - a terminal maw ring
        K.draw_grad_ellipse(d, cx, cy - R * 0.14, R * 1.02, R * 1.0,
                            K.lighten(skin, 1.0), darker_ := K.darken(skin, 0.8),
                            outline=INK, w=5)
        _maw(d, cx + R * 0.26, maw_y - R * 0.05, maw_w * 0.95, maw_h,
             jaw, rr, skin=skin)
        # horn nubs + feelers
        for hx, hy in [(-0.42, -0.78), (-0.05, -0.94), (0.3, -0.82)]:
            _spike(d, [(cx + R * hx - R * 0.14, cy + R * hy + R * 0.12),
                       (cx + R * hx + R * 0.14, cy + R * hy + R * 0.12),
                       (cx + R * hx + R * 0.02, cy + R * hy - R * 0.3)],
                   with_a2(fin))
        _feelers(d, cx + R * 0.7, cy - R * 0.3, R * 0.5,
                 with_a2(K.darken(skin, 0.5)), 3, "w01f")
        _creases(d, cx, cy, R, skin)
    elif wid == "w02":
        # THE EEL: narrow pointed snout, overbite, crest fin behind
        pts = [(cx - R * 1.0, cy - R * 0.34), (cx + R * 0.52, cy - R * 0.52),
               (cx + R * 1.04, cy - R * 0.10), (cx + R * 0.86, maw_y),
               (cx - R * 0.5, cy + R * 0.66)]
        grad_poly(L, pts, K.lighten(skin, 0.95), deeper)
        _maw(d, cx + R * 0.52, maw_y - R * 0.08, maw_w * 0.8,
             maw_h * 0.9, jaw, rr, needle=True)
        _spike(d, [(cx - R * 0.85, cy - R * 0.3), (cx - R * 1.3, cy - R * 1.05),
                   (cx - R * 0.45, cy - R * 0.72)], with_a2(fin))
        _spike(d, [(cx - R * 0.55, cy - R * 0.42), (cx - R * 0.95, cy - R * 1.0),
                   (cx - R * 0.2, cy - R * 0.7)], with_a2(K.darken(fin, 0.8)))
        _feelers(d, cx + R * 0.95, cy - R * 0.25, R * 0.35,
                 with_a2(K.darken(skin, 0.5)), 2, "w02f")
    elif wid == "w03":
        # THE DUNE REAVER: a broad shovel with two hook mandibles
        K.draw_grad_ellipse(d, cx, cy, R * 1.1, R * 0.92,
                            K.lighten(skin, 0.95), deeper, outline=INK, w=5)
        _maw(d, cx + R * 0.2, maw_y, maw_w, maw_h, jaw, rr, skin=skin)
        # the hooks: two outward curved mandibles
        for sgn in (-1, 1):
            hx = cx + R * 0.75
            pts = [(hx, cy - R * 0.5), (hx + R * 0.75 * sgn + R * 0.35,
                    cy - R * 0.05), (hx + R * 0.62 * sgn + R * 0.3,
                    cy + R * 0.22), (hx + R * 0.12, cy + R * 0.02)]
            _spike(d, pts, with_a2(K.darken(skin, 0.7)))
        _scutes(d, cx, cy - R * 0.5, R, skin, 4)
        _feelers(d, cx + R * 0.6, cy - R * 0.55, R * 0.4,
                 with_a2(K.darken(skin, 0.5)), 2, "w03f")
    elif wid == "w04":
        # THE STAR: a crown of spikes around a narrow needle maw
        K.draw_grad_ellipse(d, cx, cy - R * 0.1, R * 0.94, R * 0.96,
                            K.lighten(skin, 1.0), deeper, outline=INK, w=5)
        for i in range(6):
            a = -2.5 + i * 0.52
            bx, by = cx + R * math.cos(a) * 0.82, cy + R * math.sin(a) * 0.88
            tx, ty = cx + R * math.cos(a) * 1.5, cy + R * math.sin(a) * 1.55
            _spike(d, [(bx - R * 0.13, by), (bx + R * 0.13, by), (tx, ty)],
                   with_a2(fin))
        _maw(d, cx + R * 0.34, maw_y - R * 0.06, maw_w * 0.82, maw_h * 0.85,
             jaw, rr, needle=True)
        _feelers(d, cx + R * 0.75, cy - R * 0.35, R * 0.4,
                 with_a2(K.darken(skin, 0.55)), 3, "w04f")
    elif wid == "w05":
        # THE CRIMSON: sabre fangs out of the jaw corners
        K.draw_grad_ellipse(d, cx, cy - R * 0.1, R * 1.02, R * 0.96,
                            K.lighten(skin, 0.95), deeper, outline=INK, w=5)
        _maw(d, cx + R * 0.2, maw_y, maw_w * 1.02, maw_h, jaw, rr, skin=skin)
        for sgn, dy in ((1, -0.05), (1, 0.3)):
            bx, by = cx + R * 0.85, maw_y + R * dy - R * 0.1
            _spike(d, [(bx - R * 0.1, by), (bx + R * 0.16, by + R * 0.05),
                       (bx + R * 0.5, by - R * (0.5 if dy < 0 else 0.2))],
                   TOOTH, outline=(70, 40, 30, 255))
        _spike(d, [(cx - R * 0.5, cy - R * 0.66), (cx - R * 0.1, cy - R * 1.25),
                   (cx + R * 0.22, cy - R * 0.7)], with_a2(fin))
        _feelers(d, cx + R * 0.72, cy - R * 0.42, R * 0.4,
                 with_a2(K.darken(skin, 0.5)), 2, "w05f")
    elif wid == "w06":
        # THE TITAN: a plated box head, two forward horns, wide maw
        pts = [(cx - R * 1.05, cy - R * 0.5), (cx + R * 0.5, cy - R * 0.72),
               (cx + R * 1.05, cy - R * 0.2), (cx + R * 1.0, cy + R * 0.6),
               (cx - R * 0.7, cy + R * 0.7)]
        grad_poly(L, pts, K.lighten(skin, 0.95), deeper)
        _maw(d, cx + R * 0.32, maw_y + R * 0.04, maw_w * 0.9, maw_h,
             jaw, rr)
        for hy in (-0.45, -0.05):
            _spike(d, [(cx + R * 0.62, cy + R * hy),
                       (cx + R * 1.35, cy + R * hy - R * 0.28),
                       (cx + R * 0.7, cy + R * hy + R * 0.22)],
                   with_a2(K.darken(skin, 0.72)))
        _plates(d, cx - R * 0.5, cy - R * 0.35, R, skin)
        _feelers(d, cx + R * 0.55, cy - R * 0.6, R * 0.34,
                 with_a2(K.darken(skin, 0.5)), 2, "w06f")
    elif wid == "w07":
        # THE VIPER: a thin wedge, hinged fangs, side blades
        pts = [(cx - R * 1.05, cy - R * 0.14), (cx + R * 0.6, cy - R * 0.4),
               (cx + R * 1.05, cy + R * 0.02), (cx + R * 0.6, cy + R * 0.42),
               (cx - R * 0.8, cy + R * 0.44)]
        grad_poly(L, pts, K.lighten(skin, 0.95), deeper)
        _maw(d, cx + R * 0.55, cy + R * 0.02, maw_w * 0.62, maw_h * 0.8,
             jaw, rr, needle=True)
        for sgn in (-1, 1):
            _spike(d, [(cx - R * 0.2, cy + R * 0.28 * sgn),
                       (cx - R * 0.75, cy + R * 0.75 * sgn),
                       (cx + R * 0.1, cy + R * 0.16 * sgn)],
                   with_a2(fin))
        _feelers(d, cx + R * 0.9, cy - R * 0.12, R * 0.3,
                 with_a2(K.darken(skin, 0.5)), 2, "w07f")
    elif wid == "w08":
        # THE ROBO GOLIATH: an armored saw-jaw + sensor mast (no eye)
        K.draw_grad_ellipse(d, cx, cy, R * 1.06, R * 0.95,
                            K.lighten(skin, 0.9), deeper, outline=INK, w=5)
        _maw(d, cx + R * 0.24, maw_y, maw_w, maw_h, jaw, rr, saw=True, skin=skin)
        _plates(d, cx - R * 0.55, cy - R * 0.45, R, skin, rivets=True)
        # the sensor mast
        d.line([(cx - R * 0.3, cy - R * 0.7), (cx - R * 0.3, cy - R * 1.25)],
               fill=with_a2(K.darken(skin, 0.6)), width=5)
        gc = w["glow"] or (80, 230, 255)
        K.draw_ellipse(d, cx - R * 0.3, cy - R * 1.3, R * 0.09, R * 0.09,
                       gc + (255,))
        _feelers(d, cx + R * 0.6, cy - R * 0.5, R * 0.34,
                 with_a2(K.darken(skin, 0.55)), 2, "w08f")
    elif wid == "w09":
        # THE WRAITH: a dusk wedge with glowing maw runes + wisp feelers
        pts = [(cx - R * 1.05, cy - R * 0.2), (cx + R * 0.55, cy - R * 0.5),
               (cx + R * 1.02, cy), (cx + R * 0.55, cy + R * 0.5),
               (cx - R * 0.85, cy + R * 0.55)]
        grad_poly(L, pts, K.lighten(skin, 1.0), K.darken(skin, 0.5))
        _maw(d, cx + R * 0.45, cy + R * 0.04, maw_w * 0.8, maw_h * 0.9,
             jaw, rr, glow=w["glow"])
        gc = w["glow"]
        for i in range(3):
            a = -0.7 + i * 0.5
            bx, by = cx + R * math.cos(a) * 0.8, cy + R * math.sin(a) * 0.85
            tx, ty = cx + R * math.cos(a) * 1.35, cy + R * math.sin(a) * 1.45
            d.line([(bx, by), (tx, ty)], fill=gc + (150,), width=4)
        _feelers(d, cx + R * 0.85, cy - R * 0.2, R * 0.3, gc + (200,), 3,
                 "w09f")
    else:
        # THE DRAGON: horns + frill + a big jagged jaw
        K.draw_grad_ellipse(d, cx, cy - R * 0.08, R * 1.05, R * 0.98,
                            K.lighten(skin, 0.95), deeper, outline=INK, w=5)
        # the frill
        for i in range(5):
            a = -2.2 + i * 0.42
            bx, by = cx + R * math.cos(a) * 0.85, cy + R * math.sin(a) * 0.9
            tx, ty = cx + R * math.cos(a) * 1.42, cy + R * math.sin(a) * 1.5
            _spike(d, [(bx - R * 0.12, by), (bx + R * 0.12, by), (tx, ty)],
                   with_a2(fin))
        # the two back-swept horns
        for hx, hy in ((-0.55, -0.6), (0.05, -0.8)):
            _spike(d, [(cx + R * hx, cy + R * hy),
                       (cx + R * (hx - 0.5), cy + R * (hy - 0.62)),
                       (cx + R * (hx + 0.16), cy + R * (hy - 0.12))],
                   with_a2(K.lighten(fin, 1.1)))
        _maw(d, cx + R * 0.2, maw_y, maw_w * 1.04, maw_h, jaw, rr, skin=skin)
        _feelers(d, cx + R * 0.78, cy - R * 0.4, R * 0.36,
                 with_a2(K.darken(skin, 0.55)), 2, "w10f")
    im = K.outline_im(L.im, INK, 3)
    K.grain(im, wid + "-head2")
    return im.crop(im.getbbox())


def _maw(d, mx, my, mw, mh, jaw, rr, needle=False, saw=False, glow=None,
        skin=(214, 60, 48)):
    """THE BITE WEDGE: a jaw that opens out of the head's front-bottom -
    two jaws (upper+lower) hinged at the back, spreading with `jaw`,
    the dark throat between them, teeth lining both jaws. Built from
    the hinge so everything stays INSIDE the head's silhouette."""
    # the hinge sits back-left of the maw center; the jaws open rightward
    hx, hy = mx - mw * 0.45, my - mh * 0.05
    ang = 0.18                      # the gape axis, slightly downward
    spread = (0.10 + jaw * 0.52)    # half-angle of the gape
    ln = mw * 1.05                  # jaw length
    toCol = (K.darken((205, 200, 210), 0.9) + (255,)) if saw \
        else (TOOTH_D if needle else TOOTH)
    outC = (70, 40, 30, 255)
    jaw_hi = with_a2(K.darken(skin, 0.72))
    jaw_lo = with_a2(K.darken(skin, 0.85))
    # the upper jaw
    ua = ang - spread
    ux, uy = hx + math.cos(ua) * ln, hy + math.sin(ua) * ln
    d.polygon([(hx, hy - mh * 0.16), (ux - mh * 0.05, uy - mh * 0.22),
               (ux, uy), (hx + mw * 0.1, hy + mh * 0.1)],
              fill=jaw_hi)
    d.polygon([(hx, hy - mh * 0.16), (ux - mh * 0.05, uy - mh * 0.22),
               (ux, uy), (hx + mw * 0.1, hy + mh * 0.1)],
              outline=outC, width=3)
    # the lower jaw
    la = ang + spread
    lx2, ly2 = hx + math.cos(la) * ln * 0.92, hy + math.sin(la) * ln * 0.92
    d.polygon([(hx, hy + mh * 0.1), (hx + mw * 0.1, hy + mh * 0.12),
               (lx2, ly2), (hx + mw * 0.05, hy + mh * 0.28)],
              fill=jaw_lo)
    d.polygon([(hx, hy + mh * 0.1), (hx + mw * 0.1, hy + mh * 0.12),
               (lx2, ly2), (hx + mw * 0.05, hy + mh * 0.28)],
              outline=outC, width=3)
    # the throat (between the jaws, at the hinge)
    d.polygon([(hx, hy - mh * 0.02), (hx + mw * 0.5, hy - mh * 0.1),
               (hx + mw * 0.42, hy + mh * 0.18), (hx, hy + mh * 0.2)],
              fill=(glow + (200,)) if glow else MAW)
    # teeth along the upper jaw's inner edge (pointing down-right)
    n = 4 if needle else 5
    for i in range(n):
        t = 0.25 + 0.75 * i / max(1, n - 1)
        bx = hx + math.cos(ua) * ln * t
        by = hy + math.sin(ua) * ln * t
        h = mh * (0.5 if not needle else 0.42) * (0.85 + 0.3 * rr.random())
        _fang(d, bx, by, mw * (0.055 if needle else 0.09), h, True, toCol)
    # teeth along the lower jaw's inner edge (pointing up-left)
    n2 = 3 if needle else 4
    for i in range(n2):
        t = 0.3 + 0.7 * i / max(1, n2 - 1)
        bx = hx + math.cos(la) * ln * 0.92 * t
        by = hy + math.sin(la) * ln * 0.92 * t
        h = mh * 0.4 * (0.85 + 0.3 * rr.random())
        _fang(d, bx, by, mw * (0.05 if needle else 0.08), h, False, toCol)


def _ring_fangs(d, mx, my, mw, mh, jaw):
    """the classic's outer fang ring - the teacher's signature."""
    for sgn in (-1, 1):
        bx = mx + sgn * mw * 0.52
        _fang(d, bx, my - mh * 0.1 * sgn, mw * 0.13,
              mh * (0.55 + jaw * 0.3), sgn > 0)


def _creases(d, cx, cy, R, skin):
    """the classic's ring creases (the earthworm segmentation)."""
    for i in range(3):
        a = -1.9 + i * 0.42
        x0, y0 = cx + R * math.cos(a) * 0.95, cy + R * math.sin(a) * 0.95
        x1, y1 = cx + R * math.cos(a) * 0.62, cy + R * math.sin(a) * 0.66
        d.line([(x0, y0), (x1, y1)],
               fill=K.darken(skin, 0.62) + (255,), width=5)


def _scutes(d, cx, cy, R, skin, n):
    for i in range(n):
        sx = cx - R * 0.7 + i * R * 0.34
        _spike(d, [(sx, cy - R * 0.4), (sx + R * 0.16, cy - R * 0.78),
                   (sx + R * 0.3, cy - R * 0.36)],
               K.darken(skin, 0.68) + (255,))


def _plates(d, cx, cy, R, skin, rivets=False):
    for i, dy in enumerate((0.0, 0.3)):
        bx = [cx - R * 0.85 + i * R * 0.2, cy - R * (0.55 - dy),
              cx + R * 0.05 + i * R * 0.2, cy - R * (0.2 - dy)]
        d.rounded_rectangle(bx, radius=6,
                            fill=K.darken(skin, 0.74) + (255,),
                            outline=INK, width=3)
        if rivets:
            d.ellipse([bx[0] + 4, bx[1] + 4, bx[0] + 9, bx[1] + 9],
                      fill=(220, 226, 232, 255))


def with_a2(c):
    return c + (255,) if len(c) == 3 else c


# ----------------------------------------------------------------- bodies
def species_body(w, variant):
    wid = w["id"]
    skin, belly, fin = w["skin"], w["belly"], w["fin"]
    Wc, Hc = 150, 120
    L = K.Layer(Wc, Hc)
    d = L.d
    rr = random.Random(wid + "b" + str(variant))
    K.draw_grad_ellipse(d, Wc * 0.46, Hc * 0.5, Wc * 0.4, Hc * 0.36,
                        K.lighten(skin, 0.84), K.darken(skin, 0.72),
                        outline=INK, w=4)
    d.chord([Wc * 0.12, Hc * 0.42, Wc * 0.82, Hc * 0.94], 15, 165,
            fill=with_a2(belly))
    if wid == "w01":
        # ring creases + stud spikes
        for i in range(3):
            gx = Wc * (0.3 + 0.18 * i)
            d.line([(gx, Hc * 0.18), (gx, Hc * 0.42)],
                   fill=K.darken(skin, 0.62) + (255,), width=4)
            _spike(d, [(gx - 5, Hc * 0.2), (gx + 5, Hc * 0.2),
                       (gx + rr.randint(-2, 2), Hc * 0.04)],
                   with_a2(K.darken(skin, 0.7)))
    elif wid in ("w02", "w07"):
        # the eel/viper dorsal fin ridge
        _spike(d, [(Wc * 0.14, Hc * 0.34), (Wc * 0.32, Hc * 0.02),
                   (Wc * 0.46, Hc * 0.26), (Wc * 0.62, Hc * 0.0),
                   (Wc * 0.76, Hc * 0.3)], with_a2(fin))
    elif wid == "w03":
        # sand scutes
        for i in range(4):
            sx = Wc * (0.24 + 0.16 * i)
            _spike(d, [(sx, Hc * 0.22), (sx + 9, Hc * -0.06),
                       (sx + 18, Hc * 0.26)], with_a2(K.darken(fin, 0.85)))
    elif wid == "w04":
        # star studs
        for i in range(4):
            sx, sy = Wc * (0.26 + 0.14 * i), Hc * 0.2
            _spike(d, [(sx - 7, sy + 4), (sx + 7, sy + 4), (sx, sy - 12)],
                   with_a2(fin))
    elif wid == "w05":
        # jagged blade spikes
        for i in range(3):
            sx = Wc * (0.28 + 0.2 * i)
            _spike(d, [(sx, Hc * 0.24), (sx + 6, Hc * -0.1),
                       (sx + 13, Hc * 0.26)], with_a2(fin))
    elif wid == "w06":
        # heavy plates
        for i in range(2):
            d.rounded_rectangle([Wc * (0.2 + 0.26 * i), Hc * 0.12,
                                 Wc * (0.42 + 0.26 * i), Hc * 0.34], 6,
                                fill=K.darken(skin, 0.74) + (255,),
                                outline=INK, width=3)
    elif wid == "w08":
        # metal panels + rivets
        d.rounded_rectangle([Wc * 0.24, Hc * 0.1, Wc * 0.68, Hc * 0.34], 5,
                            fill=K.darken(skin, 0.78) + (255,),
                            outline=INK, width=3)
        for rx in (0.28, 0.5, 0.64):
            d.ellipse([Wc * rx, Hc * 0.14, Wc * rx + 5, Hc * 0.14 + 5],
                      fill=(225, 230, 236, 255))
    elif wid == "w09":
        # glowing pores
        for i in range(5):
            px, py = Wc * (0.24 + 0.13 * i), Hc * (0.2 + 0.05 * (i % 2))
            d.ellipse([px - 3, py - 3, px + 3, py + 3],
                      fill=w["glow"] + (220,))
    else:
        # the dragon's sail spikes
        for i in range(4):
            sx = Wc * (0.22 + 0.17 * i)
            _spike(d, [(sx, Hc * 0.24), (sx + 7, Hc * -0.08),
                       (sx + 15, Hc * 0.26)], with_a2(fin))
    im = K.outline_im(L.im, INK, 3)
    K.grain(im, wid + "-body2-" + str(variant))
    return im.crop(im.getbbox())


def species_tail(w):
    wid = w["id"]
    skin, fin = w["skin"], w["fin"]
    Wc, Hc = 150, 110
    L = K.Layer(Wc, Hc)
    d = L.d
    if wid in ("w02", "w09"):
        # a fin fan
        pts = [(Wc * 0.08, Hc * 0.5), (Wc * 0.5, Hc * 0.12),
               (Wc * 0.95, Hc * 0.3), (Wc * 0.6, Hc * 0.5),
               (Wc * 0.95, Hc * 0.7), (Wc * 0.5, Hc * 0.88)]
        d.polygon(pts, fill=with_a2(K.darken(fin, 0.9)), outline=INK, width=4)
    elif wid == "w06":
        # a bone club
        d.rounded_rectangle([Wc * 0.1, Hc * 0.36, Wc * 0.6, Hc * 0.64], 10,
                            fill=with_a2(K.darken(skin, 0.8)), outline=INK,
                            width=4)
        d.ellipse([Wc * 0.55, Hc * 0.14, Wc * 0.98, Hc * 0.86],
                  fill=with_a2(K.darken(skin, 0.66)), outline=INK, width=4)
        for i in range(3):
            a = -0.8 + i * 0.8
            cx2, cy2 = Wc * 0.77, Hc * 0.5
            d.line([(cx2, cy2), (cx2 + 22 * math.cos(a),
                    cy2 + 30 * math.sin(a))], fill=INK, width=4)
    elif wid == "w08":
        # a drill cone
        d.polygon([(Wc * 0.1, Hc * 0.3), (Wc * 0.55, Hc * 0.14),
                   (Wc * 0.98, Hc * 0.5), (Wc * 0.55, Hc * 0.86),
                   (Wc * 0.1, Hc * 0.7)],
                  fill=with_a2(K.darken(skin, 0.72)), outline=INK, width=4)
        for i in range(3):
            x0 = Wc * (0.35 + 0.16 * i)
            d.line([(x0, Hc * 0.22), (x0 + 10, Hc * 0.78)],
                   fill=INK, width=3)
    else:
        # the classic tapered spike (all meat species)
        pts = [(Wc * 0.06, Hc * 0.62), (Wc * 0.42, Hc * 0.22),
               (Wc * 0.62, Hc * 0.3), (Wc * 0.96, Hc * 0.5),
               (Wc * 0.6, Hc * 0.7), (Wc * 0.4, Hc * 0.8)]
        d.polygon(pts, fill=with_a2(K.darken(skin, 0.85)), outline=INK,
                  width=4)
        d.polygon([(Wc * 0.1, Hc * 0.6), (Wc * 0.4, Hc * 0.3),
                   (Wc * 0.52, Hc * 0.44), (Wc * 0.3, Hc * 0.66)],
                  fill=with_a2(fin))
    im = K.outline_im(L.im, INK, 3)
    K.grain(im, wid + "-tail2")
    return im.crop(im.getbbox())


def species_preview(w):
    head = species_head(w, False)
    body = species_body(w, 0)
    tail = species_tail(w)
    Wc, Hc = 300, 190
    L = K.Layer(Wc, Hc)
    sc = 0.62
    b2 = body.resize((max(1, int(body.width * sc)),
                      max(1, int(body.height * sc))))
    t2 = tail.resize((max(1, int(tail.width * sc)),
                      max(1, int(tail.height * sc))))
    h2 = head.resize((max(1, int(head.width * 0.78)),
                      max(1, int(head.height * 0.78))))
    L.im.alpha_composite(t2, (8, Hc - t2.height - 42))
    L.im.alpha_composite(b2, (t2.width - 26, Hc - b2.height - 52))
    L.im.alpha_composite(h2, (t2.width + b2.width - 62,
                              Hc - h2.height - 16))
    return L.im.crop(L.im.getbbox())


# ================================================================ diggers
def digger_frame(kind, i, n=4):
    """mole + lizard - LEFT-native, reptile sprawl for the lizard
    (legs at the SIDES, belly low), a scoop-paw digger for the mole."""
    ph = math.tau * i / n
    if kind == "lizard":
        Wc, Hc = 190, 84
        L = K.Layer(Wc, Hc)
        d = L.d
        skin = (94, 158, 66)
        dark = K.darken(skin, 0.62)
        belly = (200, 226, 150)
        # the long low body: belly ON the ground (the reptile line)
        pts = [(Wc * 0.06, Hc * 0.62), (Wc * 0.2, Hc * 0.3),
               (Wc * 0.52, Hc * 0.18), (Wc * 0.8, Hc * 0.26),
               (Wc * 0.94, Hc * 0.42), (Wc * 0.86, Hc * 0.66),
               (Wc * 0.4, Hc * 0.74)]
        grad_poly(L, pts, K.lighten(skin, 1.0), dark)
        # the head (LEFT) + jaw line
        d.ellipse([Wc * 0.0, Hc * 0.3, Wc * 0.24, Hc * 0.62],
                  fill=K.lighten(skin, 1.08) + (255,), outline=INK, width=4)
        d.line([(Wc * 0.02, Hc * 0.5), (Wc * 0.2, Hc * 0.52)],
               fill=K.darken(skin, 0.5) + (255,), width=3)
        # the tail (RIGHT, long, tapering)
        d.polygon([(Wc * 0.82, Hc * 0.4), (Wc * 1.02, Hc * 0.3),
                   (Wc * 0.98, Hc * 0.6), (Wc * 0.8, Hc * 0.62)],
                  fill=dark + (255,), outline=INK, width=3)
        # THE SPRAWL: legs splayed OUT to the sides (elbows/knees out),
        # feet planted wide - never under the body like a cow
        for sgn, lx in ((-1, 0.3), (-1, 0.62), (1, 0.3), (1, 0.62)):
            swing = math.sin(ph + (0 if lx < 0.5 else HPI)) * 5.0
            hip = (Wc * lx, Hc * (0.62 if sgn > 0 else 0.5))
            knee = (hip[0] + sgn * 14 + swing, hip[1] + sgn * 12)
            foot = (hip[0] + sgn * 22 + swing * 1.4, Hc * 0.78)
            d.line([hip, knee, foot], fill=dark + (255,), width=6)
            d.ellipse([foot[0] - 6, foot[1] - 3, foot[0] + 6, foot[1] + 4],
                      fill=K.darken(skin, 0.5) + (255,), outline=INK,
                      width=2)
        # back speckles
        for sxi in range(5):
            sx = Wc * (0.3 + 0.11 * sxi)
            d.ellipse([sx, Hc * 0.3, sx + 5, Hc * 0.3 + 4],
                      fill=K.darken(skin, 0.55) + (255,))
        im = K.outline_im(L.im, INK, 3)
        K.grain(im, "lizard2-" + str(i))
        return im.crop(im.getbbox())
    # THE MOLE: a compact digger - scoop paws, pointed shield snout
    Wc, Hc = 150, 96
    L = K.Layer(Wc, Hc)
    d = L.d
    skin = (72, 62, 58)
    dark = K.darken(skin, 0.6)
    pts = [(Wc * 0.1, Hc * 0.66), (Wc * 0.24, Hc * 0.3),
           (Wc * 0.66, Hc * 0.22), (Wc * 0.9, Hc * 0.44),
           (Wc * 0.84, Hc * 0.72), (Wc * 0.3, Hc * 0.8)]
    grad_poly(L, pts, K.lighten(skin, 1.1), dark)
    # the snout (LEFT) - a pink shield tip
    d.ellipse([Wc * 0.0, Hc * 0.4, Wc * 0.24, Hc * 0.66],
              fill=K.lighten(skin, 1.15) + (255,), outline=INK, width=4)
    d.ellipse([Wc * 0.02, Hc * 0.5, Wc * 0.1, Hc * 0.6],
              fill=(226, 150, 140, 255), outline=INK, width=2)
    # the tail stub (RIGHT)
    d.ellipse([Wc * 0.88, Hc * 0.5, Wc * 1.02, Hc * 0.64],
              fill=dark + (255,), outline=INK, width=3)
    # the SCOOP PAWS (front big, splayed digits)
    for sgn, lx, big in ((-1, 0.34, True), (1, 0.66, False)):
        swing = math.sin(ph + (0 if big else HPI)) * 6.0
        hip = (Wc * lx, Hc * 0.66)
        foot = (hip[0] + sgn * (16 if big else 10) + swing, Hc * 0.86)
        d.line([hip, foot], fill=dark + (255,),
               width=8 if big else 5)
        d.polygon([(foot[0] - 10, foot[1]), (foot[0] + 10, foot[1]),
                   (foot[0] + sgn * 6, foot[1] - 10)],
                  fill=(196, 168, 150, 255), outline=INK, width=2)
    # the squint (a blind digger's slit, barely there - not a cartoon eye)
    d.line([(Wc * 0.14, Hc * 0.44), (Wc * 0.2, Hc * 0.44)],
           fill=(20, 12, 10, 255), width=3)
    im = K.outline_im(L.im, INK, 3)
    K.grain(im, "mole2-" + str(i))
    return im.crop(im.getbbox())


# ================================================================== main
def main():
    for w in WORMS:
        wid = w["id"]
        K.finish(species_head(w, False), f"worms/{wid}_head.png")
        K.finish(species_head(w, True), f"worms/{wid}_head_open.png")
        K.finish(species_body(w, 0), f"worms/{wid}_body_0.png")
        K.finish(species_body(w, 1), f"worms/{wid}_body_1.png")
        K.finish(species_tail(w), f"worms/{wid}_tail.png")
        K.finish(species_preview(w), f"worms/{wid}_preview.png")
        print(wid, "reforged")
    for i in range(4):
        K.finish(digger_frame("lizard", i), f"things/ground/lizard_{i:02d}.png")
        K.finish(digger_frame("mole", i), f"things/ground/mole_{i:02d}.png")
    print("diggers reforged")
    # the montage for the eye pass
    hdr = [species_head(w, True) for w in WORMS]
    K.montage([f"worms/{w['id']}_head_open.png" for w in WORMS], 5,
              (200, 200), "worms2.png")
    print("SPECIES FORGE DONE")


if __name__ == "__main__":
    main()
