#!/usr/bin/env python3
"""v0.3.0 art - the XO marks, PRE-RENDERED (the owner: "the look of the X
and the O are weird, fix them and make them real sketches or just normal
X and O if you fail"). The runtime stamp-painter read lumpy - the marks
are now painted HERE at 4x and downscaled (crisp anti-aliased edges):
each stroke is a smooth ribbon polygon along a lightly noisy path with a
tapered width and a soft under-shadow. 3 variants per mark so no two
rounds look identical. Re-runnable: same code -> same bytes."""

import math
import os

from PIL import Image, ImageDraw, ImageFilter

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(PROJ, "assets", "games", "xo")
S = 512          # render size (4x the game draw)
C = S / 2

X_RED = (239, 68, 68)
X_DARK = (120, 22, 26)
O_BLUE = (59, 130, 246)
O_DARK = (24, 56, 130)


def _smooth_path(a, b, rng, wobble):
    """a lightly noisy line: two big soft sines only - reads hand-drawn,
    never polygonal"""
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    ln = math.hypot(dx, dy) or 1.0
    px, py = -dy / ln, dx / ln
    p1, p2 = rng.uniform(0, math.tau), rng.uniform(0, math.tau)
    f1 = rng.uniform(0.9, 1.4)
    f2 = rng.uniform(2.0, 2.8)
    pts = []
    n = 48
    for k in range(n + 1):
        t = k / n
        nz = (math.sin(t * f1 * math.pi * 2 + p1) * 0.7
              + math.sin(t * f2 * math.pi * 2 + p2) * 0.3) * wobble
        pts.append((ax + dx * t + px * nz, ay + dy * t + py * nz))
    return pts


def _ribbon(img, pts, width, color, alpha=255):
    """a tapered brush ribbon: DENSE discs along the path (step ~ w/6 so
    the edge is smooth, never scalloped), the width tapering to ~12% at
    the tips so strokes end in a point like a real brush"""
    # resample the path to even arc-length steps
    total = 0.0
    for k in range(1, len(pts)):
        total += math.hypot(pts[k][0] - pts[k - 1][0],
                            pts[k][1] - pts[k - 1][1])
    step = max(2.0, width * 0.16)
    n = max(24, int(total / step))
    dense = []
    for k in range(n + 1):
        t = k / n
        idx = t * (len(pts) - 1)
        i0 = int(idx)
        i1 = min(len(pts) - 1, i0 + 1)
        f = idx - i0
        dense.append((pts[i0][0] + (pts[i1][0] - pts[i0][0]) * f,
                      pts[i0][1] + (pts[i1][1] - pts[i0][1]) * f))
    d = ImageDraw.Draw(img)
    for k in range(n + 1):
        t = k / n
        mid = 0.5 - 0.5 * math.cos(t * math.tau)
        w = width * (0.12 + 0.88 * (mid ** 0.75))
        r = w / 2.0
        edge = min(1.0, min(t, 1 - t) * 22.0 + 0.35)
        c = color + (int(alpha * edge),)
        x, y = dense[k]
        d.ellipse([x - r, y - r, x + r, y + r], fill=c)
    return img


def _draw_x(variant):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    rng = __import__("random").Random(100 + variant)
    r = S * 0.30
    off = S * 0.012
    for a, b in [((C - r, C - r), (C + r, C + r)),
                 ((C - r, C + r), (C + r, C - r))]:
        pts = _smooth_path(a, b, rng, S * 0.009)
        # the under-shadow (offset, darker, slightly thinner)
        sh = [(x + off * 2, y + off * 2) for x, y in pts]
        _ribbon(img, sh, S * 0.085, X_DARK, 105)
        _ribbon(img, pts, S * 0.095, X_RED, 248)
    return img


def _draw_o(variant):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    rng = __import__("random").Random(200 + variant)
    r = S * 0.30
    a0 = rng.uniform(0, math.tau)
    p1, p2 = rng.uniform(0, math.tau), rng.uniform(0, math.tau)
    drift = rng.uniform(0.02, 0.045)
    pts = []
    n = 72
    for k in range(n + 1):
        t = k / n
        ang = a0 + math.tau * (1.0 + drift) * t   # the close overlaps
        wob = (math.sin(ang * 2 + p1) * 0.6
               + math.sin(ang * 3 + p2) * 0.4) * S * 0.010
        rr = r * (1.0 + drift * t * 0.4) + wob
        pts.append((C + math.cos(ang) * rr, C + math.sin(ang) * rr))
    off = S * 0.012
    sh = [(x + off * 2, y + off * 2) for x, y in pts]
    _ribbon(img, sh, S * 0.078, O_DARK, 105)
    _ribbon(img, pts, S * 0.088, O_BLUE, 248)
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    for v in range(3):
        _draw_x(v).resize((256, 256), Image.LANCZOS).save(
                os.path.join(OUT, "mark_x_%d.png" % v))
        _draw_o(v).resize((256, 256), Image.LANCZOS).save(
                os.path.join(OUT, "mark_o_%d.png" % v))
    # the review sheet
    sh = Image.new("RGB", (3 * 180 + 40, 2 * 180 + 30), (250, 249, 246))
    for v in range(3):
        for row, kind in enumerate(["x", "o"]):
            im = Image.open(os.path.join(OUT, "mark_%s_%d.png" % (kind, v)))
            sh.paste(im, (30 + v * 180, 20 + row * 180), im)
    sh.save("/tmp/xomarks_view.png")
    print("xo marks rendered (3 x 2)")


if __name__ == "__main__":
    main()
