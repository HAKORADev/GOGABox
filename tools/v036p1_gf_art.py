#!/usr/bin/env python3
"""v036p1_gf_art.py - GEOMETRY FLASH v0.3.6-1 art pass.

THE OWNER'S REPORT:
  - the VFXs were "repeated small shapes" -> new particle vocabulary:
    p_soft (glow disc), p_streak (motion streak), p_puff (smoke/flame puff),
    p_star (4-point star flash) - every effect is now a layered composition
    of these + the existing ring/shard/spark, all additive in-engine.
  - the EXTRA LIFE power needs its mark: shield_core (the smaller
    blacked-out inner square) + the three capsule icons pow_*.
  - the surfaces "feel empty" -> block/line/strip/pusher are REGENERATED
    with richer inner structure (corner glow studs, double bevels, a second
    pattern row, glowing seams) - same canvas sizes, drop-in.

100% original, drawn with PIL. Re-derive: python3 tools/v036p1_gf_art.py
"""
import os
import sys
import math

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from v036_gf_art import (glow_layer, vgrad, rounded_rect,  # noqa: E402
                         out_path, save)
from PIL import Image, ImageDraw, ImageFilter  # noqa: E402


# ---------------------------------------------------------------- particles
def draw_soft(size=128):
    """The glow disc: a smooth radial falloff, white (modulate tints it)."""
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = size // 2
    for r in range(c, 0, -1):
        a = int(255 * (1.0 - r / c) ** 1.8)
        d.ellipse((c - r, c - r, c + r, c + r), fill=(255, 255, 255, a))
    return im


def draw_streak(size=(128, 48)):
    """The motion streak: a horizontal comet - bright head, long tail."""
    w, h = size
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cy = h // 2
    for x in range(w):
        t = x / (w - 1)                      # 0 = tail (left), 1 = head
        a = int(255 * (t ** 1.6))
        half = max(1, int((h * 0.44) * (0.25 + 0.75 * t)))
        d.line((x, cy - half, x, cy + half), fill=(255, 255, 255, a),
               width=1)
    # the bright head cap
    d.ellipse((w - h // 2 - 2, cy - h // 2 + 2, w - 2, cy + h // 2 - 2),
              fill=(255, 255, 255, 235))
    im = im.filter(ImageFilter.GaussianBlur(1.2))
    return im


def draw_puff(size=128):
    """The smoke/flame puff: an irregular soft blob (flame tail noise)."""
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    c = size // 2
    # 5 overlapping soft discs -> an organic puff
    blobs = [(0.0, 0.10, 0.42), (-0.30, 0.22, 0.30), (0.30, 0.22, 0.30),
             (-0.18, -0.24, 0.26), (0.20, -0.20, 0.24)]
    for bx, by, br in blobs:
        layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer)
        r = int(size * br)
        cx, cy = int(c + bx * size), int(c + by * size)
        for rr in range(r, 0, -1):
            a = int(150 * (1.0 - rr / r) ** 1.4)
            ld.ellipse((cx - rr, cy - rr, cx + rr, cy + rr),
                       fill=(255, 255, 255, a))
        im.alpha_composite(layer)
    im = im.filter(ImageFilter.GaussianBlur(2))
    return im


def draw_star(size=128):
    """The 4-point star flash (the collect/bonk signature)."""
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = size // 2
    # long vertical + horizontal spikes with a soft core
    def spike(len_v, wid, ang):
        pts = []
        for i in range(2):
            a = ang + math.pi * i
            tip = (c + math.cos(a) * len_v, c + math.sin(a) * len_v)
            side = (c + math.cos(a + math.pi / 2) * wid,
                    c + math.sin(a + math.pi / 2) * wid)
            side2 = (c + math.cos(a - math.pi / 2) * wid,
                     c + math.sin(a - math.pi / 2) * wid)
            pts.append([side, tip, side2])
        for tri in pts:
            d.polygon(tri, fill=(255, 255, 255, 235))
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((c - size * 0.22, c - size * 0.22, c + size * 0.22,
                c + size * 0.22), fill=(255, 255, 255, 120))
    im.alpha_composite(glow.filter(ImageFilter.GaussianBlur(6)))
    spike(size * 0.46, size * 0.055, 0.0)
    spike(size * 0.46, size * 0.055, math.pi / 2)
    d.ellipse((c - size * 0.09, c - size * 0.09, c + size * 0.09,
               c + size * 0.09), fill=(255, 255, 255, 255))
    return im


# ------------------------------------------------------------- the shield
def draw_shield_core(size=128):
    """The EXTRA LIFE mark: a smaller BLACKED-OUT square with a faint frame
    - the owner's icon (drawn to sit inside the 72% cube body)."""
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    m = int(size * 0.16)
    s = size - 2 * m
    rad = int(s * 0.18)
    # the dark core (near-black, slight blue so it reads on any skin)
    rounded_rect(d, (m, m, m + s, m + s), rad, fill=(8, 10, 16, 235))
    # the faint inner frame so it never reads as a hole
    rounded_rect(d, (m, m, m + s, m + s), rad,
                 outline=(220, 235, 255, 150), width=max(2, size // 48))
    k0 = m + int(s * 0.30)
    k1 = m + int(s * 0.70)
    rounded_rect(d, (k0, k0, k1, k1), int(rad * 0.5),
                 outline=(255, 255, 255, 90), width=max(2, size // 64))
    return im


# ---------------------------------------------------------- power capsules
def _capsule(draw_fn, size=144, accent=(120, 200, 255)):
    """The neon capsule shell all three power icons share."""
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    m = int(size * 0.10)
    box = (m, m, size - m, size - m)
    rad = int(size * 0.22)

    def halo(d):
        rounded_rect(d, box, rad, outline=accent + (255,), width=8)
    im.alpha_composite(glow_layer(size, halo, size // 14, 0.9))
    body = vgrad(size, size, (24, 32, 52, 255), (10, 14, 24, 255))
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(box, radius=rad, fill=255)
    im.paste(body, (0, 0), mask)
    d = ImageDraw.Draw(im)
    rounded_rect(d, box, rad, outline=(246, 251, 255, 255),
                 width=max(3, size // 44))
    # the top gloss
    gloss = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    rounded_rect(ImageDraw.Draw(gloss), (m, m, size - m, m + int(size * 0.3)),
                 rad, fill=(255, 255, 255, 42))
    im.alpha_composite(Image.composite(
        gloss, Image.new("RGBA", (size, size), (0, 0, 0, 0)), mask))
    draw_fn(d, size, m)
    return im


def _arrow_up(d, cx, cy, s, col=(250, 252, 255, 255), w=None):
    w = w or max(3, s // 11)
    d.line((cx - s * 0.42, cy + s * 0.30, cx, cy - s * 0.34), fill=col, width=w)
    d.line((cx + s * 0.42, cy + s * 0.30, cx, cy - s * 0.34), fill=col, width=w)


def draw_pow_jump(size=144):
    """ROCKET JUMP: the up arrow with the extra > at the top (the owner's
    glyph), flame bar under it."""
    def fn(d, size, m):
        cx = size // 2
        cy = int(size * 0.46)
        s = size * 0.40
        _arrow_up(d, cx, cy, s, w=max(4, size // 26))
        # the extra > at the tip
        tipy = cy - s * 0.34
        d.line((cx - s * 0.16, tipy - s * 0.10, cx + s * 0.22, tipy - s * 0.30),
               fill=(250, 252, 255, 255), width=max(4, size // 28))
        d.line((cx - s * 0.16, tipy - s * 0.50, cx + s * 0.22, tipy - s * 0.30),
               fill=(250, 252, 255, 255), width=max(4, size // 28))
        # the rocket burn bar under the arrow
        by = int(size * 0.80)
        for i, a in ((0, 255), (1, 160), (2, 90)):
            d.line((cx - s * (0.40 - i * 0.12), by + i * 5,
                    cx + s * (0.40 - i * 0.12), by + i * 5),
                   fill=(255, 170, 60, a), width=max(3, size // 40))
    return _capsule(fn, size, accent=(255, 170, 60))


def draw_pow_slow(size=144):
    """SLOW WORLD: the << glyph (the owner's spec)."""
    def fn(d, size, m):
        cx = size // 2
        cy = int(size * 0.50)
        s = size * 0.34
        w = max(4, size // 24)
        for dx in (-s * 0.55, s * 0.55):
            d.line((cx + dx + s * 0.30, cy - s * 0.42, cx + dx - s * 0.30, cy),
                   fill=(250, 252, 255, 255), width=w)
            d.line((cx + dx - s * 0.30, cy, cx + dx + s * 0.30, cy + s * 0.42),
                   fill=(250, 252, 255, 255), width=w)
        # the two speed dots trailing (read: everything crawls)
        for i, a in ((0, 200), (1, 110)):
            d.ellipse((int(size * (0.16 - i * 0.055)) - 4, cy - 5,
                       int(size * (0.16 - i * 0.055)) + 4, cy + 5),
                      fill=(170, 215, 255, a))
    return _capsule(fn, size, accent=(110, 190, 255))


def draw_pow_shield(size=144):
    """EXTRA LIFE: the square with the smaller blacked-out inner square."""
    def fn(d, size, m):
        q0 = int(size * 0.30)
        q1 = size - q0
        rad = int(size * 0.08)
        rounded_rect(d, (q0, q0, q1, q1), rad,
                     outline=(250, 252, 255, 255), width=max(3, size // 40))
        c0 = int(size * 0.42)
        c1 = size - c0
        rounded_rect(d, (c0, c0, c1, c1), int(rad * 0.7),
                     fill=(8, 10, 16, 245),
                     outline=(190, 255, 190, 180), width=max(2, size // 56))
    return _capsule(fn, size, accent=(140, 240, 140))


# --------------------------------------------- richer surfaces (anti-empty)
def draw_block2(size=168):
    """The block, v2: the same tile, but the inner structure is DENSE -
    double bevel, corner glow studs, a lit core square, texture noise."""
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    e = 4

    def halo(d):
        d.rectangle((e, e, size - e, size - e), outline=(255, 255, 255, 210),
                    width=6)
    im.alpha_composite(glow_layer(size, halo, 9, 0.85))
    body = vgrad(size, size, (30, 37, 56, 255), (12, 16, 27, 255))
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rectangle((e, e, size - e - 1, size - e - 1), fill=255)
    im.paste(body, (0, 0), mask)
    d = ImageDraw.Draw(im)
    d.rectangle((e, e, size - e, size - e), outline=(246, 251, 255, 255),
                width=e)
    # the double bevel (outer bright, inner dim)
    b1 = int(size * 0.14)
    d.rectangle((b1, b1, size - b1, size - b1),
                outline=(140, 165, 210, 130), width=3)
    b2 = int(size * 0.22)
    d.rectangle((b2, b2, size - b2, size - b2),
                outline=(70, 88, 130, 110), width=2)
    # the lit core square (the GD structure center)
    c0 = int(size * 0.36)
    c1 = size - c0
    d.rectangle((c0, c0, c1, c1), outline=(205, 225, 255, 170), width=3)
    d.rectangle((c0 + 7, c0 + 7, c1 - 7, c1 - 7), fill=(64, 78, 112, 150))
    d.rectangle((c0 + 7, c0 + 7, c1 - 7, int((c0 + c1) / 2)),
                fill=(84, 100, 138, 90))
    # corner glow studs
    n = int(size * 0.10)
    stud = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sd = ImageDraw.Draw(stud)
    for cx, cy in [(e + n, e + n), (size - e - n, e + n),
                   (e + n, size - e - n), (size - e - n, size - e - n)]:
        sd.ellipse((cx - n // 2, cy - n // 2, cx + n // 2, cy + n // 2),
                   fill=(210, 230, 255, 220))
    im.alpha_composite(stud.filter(ImageFilter.GaussianBlur(2)))
    return im


def draw_line2(w=336, h=56):
    """The platform line, v2: block-joint seams + a glowing core seam."""
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    body = vgrad(w, h, (32, 40, 60, 255), (12, 16, 26, 255))
    im.paste(body, (0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, w, 5), fill=(248, 252, 255, 255))
    d.rectangle((0, 6, w, 13), fill=(150, 190, 255, 95))
    d.rectangle((0, h - 4, w, h), fill=(70, 84, 120, 200))
    # the block joints every 56 px (reads as built blocks, not a flat bar)
    for x in range(0, w, 56):
        d.rectangle((x, 10, x + 2, h - 4), fill=(66, 82, 118, 150))
        d.rectangle((x + 6, 16, x + 50, h - 10),
                    outline=(88, 108, 150, 80), width=2)
    # the glowing core seam
    d.rectangle((0, h // 2 - 1, w, h // 2 + 1), fill=(160, 200, 255, 70))
    halo = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(halo).rectangle((0, 0, w, 6), fill=(255, 255, 255, 200))
    im.alpha_composite(halo.filter(ImageFilter.GaussianBlur(6)))
    return im


def draw_strip2(w=512, h=600):
    """The ground/roof strip, v2: TWO pattern rows + glowing seam rhythm."""
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    body = vgrad(w, h, (26, 32, 50, 255), (9, 12, 20, 255))
    im.paste(body, (0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, w, 7), fill=(248, 252, 255, 255))
    d.rectangle((0, 7, w, 19), fill=(140, 180, 255, 88))
    for x in range(0, w, 128):
        d.rectangle((x, 0, x + 3, h), fill=(72, 88, 126, 130))
        d.rectangle((x + 3, 0, x + 128 - 3, h), outline=(54, 66, 98, 80),
                    width=2)
    # row 1: the big inner squares
    for x in range(0, w, 128):
        d.rectangle((x + 38, 92, x + 90, 144), outline=(96, 116, 162, 110),
                    width=3)
        d.rectangle((x + 52, 106, x + 76, 130), fill=(48, 58, 90, 120))
    # row 2: the small studs (the second rhythm)
    for x in range(64, w, 128):
        d.rectangle((x - 14, 232, x + 14, 260), outline=(84, 102, 146, 100),
                    width=3)
    # row 3: the long dash seams
    for x in range(0, w, 128):
        d.rectangle((x + 20, 336, x + 108, 344), fill=(60, 74, 108, 90))
    # the glowing seam dots at the surface block joints
    stud = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(stud)
    for x in range(0, w + 128, 128):
        sd.ellipse((x - 4, 2, x + 12, 18), fill=(215, 235, 255, 190))
    im.alpha_composite(stud.filter(ImageFilter.GaussianBlur(1.6)))
    halo = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(halo).rectangle((0, 0, w, 8), fill=(255, 255, 255, 215))
    im.alpha_composite(halo.filter(ImageFilter.GaussianBlur(7)))
    return im


def draw_pusher2(size=168):
    """The pusher/block, v2: draw_block2 + the up chevrons (shove, not kill)."""
    im = draw_block2(size)
    d = ImageDraw.Draw(im)
    for i in range(3):
        y0 = int(size * (0.34 + i * 0.17))
        h = 16
        pts = [(int(size * 0.32), y0 + h), (int(size * 0.50), y0),
               (int(size * 0.68), y0 + h), (int(size * 0.68), y0 + h + 9),
               (int(size * 0.50), y0 + 9), (int(size * 0.32), y0 + h + 9)]
        d.polygon(pts, fill=(215, 228, 252, 150))
    return im


def main():
    base = "projects/gogabox/assets/games/geometry"
    os.makedirs(base, exist_ok=True)
    print("v036p1 art:")
    save(draw_soft(), "p_soft.png")
    save(draw_streak(), "p_streak.png")
    save(draw_puff(), "p_puff.png")
    save(draw_star(), "p_star.png")
    save(draw_shield_core(), "shield_core.png")
    save(draw_pow_jump(), "pow_jump.png")
    save(draw_pow_slow(), "pow_slow.png")
    save(draw_pow_shield(), "pow_shield.png")
    # the anti-empty surface pass (same canvas sizes, drop-in)
    save(draw_block2(), "block.png")
    save(draw_line2(), "line.png")
    save(draw_strip2(), "strip.png")
    save(draw_pusher2(), "pusher.png")
    print("done")


if __name__ == "__main__":
    main()
