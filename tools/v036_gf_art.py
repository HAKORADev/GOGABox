#!/usr/bin/env python3
"""v036_gf_art.py - GEOMETRY FLASH (v0.3.6) art set.

THE STUDY TRUTH (docs/DECOMPILATION.md USAGE LAW): the anatomy was studied
from Geometry Dash Lite 2.2.147 (GJ_GameSheet sheets: dark beveled block
bodies + bright structure lines + white glow overlays; ring_01 orbs =
filled core + white ring; starAnim 4-point twinkles; playerSquare = a white
mask colored at runtime). EVERY texture below is an ORIGINAL neon-filled
redesign drawn by this script - nothing is copied, sliced or vendored from
the APK. The APK stays in study_out/ outside the repo.

Design language (owner GDD):
  - neon that FEELS FILLED: gradient bodies, lit edges, gentle baked glow
  - no faces on the square, ever
  - edges/glow drawn near-WHITE so themes recolor the world by modulate
  - player skins carry their own identity colors (never theme-tinted)

All deterministic. Re-derive: python3 tools/v036_gf_art.py
"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter

DEST = "projects/gogabox/assets/games/geometry"


def out_path(name):
    os.makedirs(DEST, exist_ok=True)
    return os.path.join(DEST, name)


def save(im, name):
    p = out_path(name)
    im.save(p)
    print(f"  {name:24s} {im.width}x{im.height}")


def glow_layer(size, draw_fn, blur, strength=1.0):
    """Draw on a transparent layer, blur it -> the baked halo."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(layer))
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    if strength != 1.0:
        a = layer.split()[3].point(lambda v: int(v * strength))
        layer.putalpha(a)
    return layer


def vgrad(w, h, top, bottom):
    im = Image.new("RGBA", (w, h))
    px = im.load()
    for y in range(h):
        t = y / max(1, h - 1)
        c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,)
        for x in range(w):
            px[x, y] = c
    return im


def rounded_rect(draw, box, radius, fill=None, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


# ---------------------------------------------------------------- cube skins
# The GD anatomy (playerSquare white mask, colors at runtime) recast: a
# FILLED rounded square, 2-tone gradient body, bright inner frame + inner
# square motif (the GD cube's square-in-square), neon outer edge, baked halo.
SKINS = {
    "classic": ((96, 226, 255), (32, 120, 220)),   # cyan -> deep blue
    "ember":   ((255, 176, 84), (232, 74, 60)),    # amber -> red
    "toxin":   ((168, 255, 110), (46, 170, 80)),   # lime -> green
    "ghost":   ((235, 244, 255), (130, 160, 210)), # white -> steel
    "prism":   ((255, 120, 235), (120, 70, 230)),  # pink -> violet
}


def draw_cube(size, hi, lo):
    s_sq = int(size * 0.72)                 # square side (halo margin around)
    m = (size - s_sq) // 2
    rad = int(s_sq * 0.16)
    body_box = (m, m, m + s_sq, m + s_sq)

    # 1. the body: gradient clipped by the rounded-square mask
    body = vgrad(s_sq, s_sq, hi, lo)
    mask = Image.new("L", (s_sq, s_sq), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, s_sq - 1, s_sq - 1),
                                           radius=rad, fill=255)
    cube = Image.new("RGBA", (s_sq, s_sq), (0, 0, 0, 0))
    cube.paste(body, (0, 0), mask)

    d = ImageDraw.Draw(cube)
    # inner frame line (the GD inner line)
    i1 = int(s_sq * 0.13)
    rounded_rect(d, (i1, i1, s_sq - i1, s_sq - i1), int(rad * 0.6),
                 outline=(255, 255, 255, 130), width=max(2, size // 72))
    # the inner square motif (GD's square-in-square), lit from above
    k0, k1 = int(s_sq * 0.30), int(s_sq * 0.70)
    core_hi = tuple(min(255, int(c * 0.55) + 128) for c in hi)
    rounded_rect(d, (k0, k0, k1, k1), int(rad * 0.45),
                 fill=core_hi + (235,), outline=(255, 255, 255, 210),
                 width=max(2, size // 60))
    # top gloss: lit band across the top third, CLIPPED to the square mask
    gloss = Image.new("RGBA", (s_sq, s_sq), (0, 0, 0, 0))
    rounded_rect(ImageDraw.Draw(gloss), (0, 0, s_sq - 1, int(s_sq * 0.40)),
                 rad, fill=(255, 255, 255, 52))
    gloss = Image.composite(gloss, Image.new("RGBA", (s_sq, s_sq), (0, 0, 0, 0)), mask)
    cube.alpha_composite(gloss)
    # outer edge (near-white)
    rounded_rect(d, (0, 0, s_sq - 1, s_sq - 1), rad,
                 outline=(250, 253, 255, 255), width=max(3, size // 42))

    # 2. the baked halo behind the cube (gentle neon aura)
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    def halo(dd):
        rounded_rect(dd, body_box, rad, outline=hi + (255,), width=max(4, size // 26))
    im.alpha_composite(glow_layer(size, halo, size // 15, 0.85))
    im.alpha_composite(cube, (m, m))
    return im


# ---------------------------------------------------------------- block tile
def draw_block(size=168):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    e = 4                                     # edge px (near-white, theme-tinted)
    # baked edge halo
    def halo(d):
        d.rectangle((e, e, size - e, size - e), outline=(255, 255, 255, 200), width=6)
    im.alpha_composite(glow_layer(size, halo, 9, 0.8))

    body = vgrad(size, size, (26, 32, 48, 255), (13, 17, 28, 255))
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rectangle((e, e, size - e - 1, size - e - 1), fill=255)
    im.paste(body, (0, 0), mask)
    d = ImageDraw.Draw(im)
    # the bright outer frame (GD block outline)
    d.rectangle((e, e, size - e, size - e), outline=(244, 250, 255, 255), width=e)
    # inner bevel lines (the GD structure lines)
    b = int(size * 0.18)
    d.rectangle((b, b, size - b, size - b), outline=(120, 140, 180, 110), width=3)
    # the center square motif, dim lit
    c0 = int(size * 0.36)
    c1 = size - c0
    d.rectangle((c0, c0, c1, c1), outline=(200, 220, 250, 150), width=3)
    d.rectangle((c0 + 8, c0 + 8, c1 - 8, c1 - 8), fill=(58, 70, 100, 140))
    # corner notches (GD-ish detail, subtle)
    n = int(size * 0.085)
    for cx, cy in [(e, e), (size - e - n, e), (e, size - e - n), (size - e - n, size - e - n)]:
        d.rectangle((cx, cy, cx + n, cy + n), fill=(64, 78, 112, 200))
    return im


# ------------------------------------------------------------- platform line
def draw_line(w=336, h=56):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    # body
    body = vgrad(w, h, (30, 38, 56, 255), (12, 16, 26, 255))
    im.paste(body, (0, 0))
    d = ImageDraw.Draw(im)
    # bright TOP edge (the surface the square rides)
    d.rectangle((0, 0, w, 5), fill=(248, 252, 255, 255))
    # under-glow of the top edge (neon feel)
    d.rectangle((0, 6, w, 12), fill=(150, 190, 255, 90))
    # bottom edge dim + rivets
    d.rectangle((0, h - 4, w, h), fill=(70, 84, 120, 200))
    for x in range(24, w, 64):
        d.rectangle((x, h - 16, x + 16, h - 10), fill=(90, 110, 150, 130))
    # baked top halo
    halo = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    hd.rectangle((0, 0, w, 6), fill=(255, 255, 255, 190))
    halo = halo.filter(ImageFilter.GaussianBlur(6))
    im.alpha_composite(halo)
    return im


# ------------------------------------------------------------- ground strip
def draw_strip(w=512, h=600):
    """The ground tile (roof = flip_v in engine). Tileable on x.
    300 design px tall (the roof hangs from y0 to ROOF_Y; the ground runs
    from GROUND_Y past the bottom edge under the banner)."""
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    body = vgrad(w, h, (24, 30, 46, 255), (9, 12, 20, 255))
    im.paste(body, (0, 0))
    d = ImageDraw.Draw(im)
    # surface line + under-glow
    d.rectangle((0, 0, w, 7), fill=(248, 252, 255, 255))
    d.rectangle((0, 7, w, 18), fill=(140, 180, 255, 80))
    # seams every 128 px (the GD block rhythm) + inner pattern
    for x in range(0, w, 128):
        d.rectangle((x, 0, x + 3, h), fill=(70, 86, 124, 120))
        d.rectangle((x + 3, 0, x + 128 - 3, h), outline=(52, 64, 96, 70), width=2)
    # a dim inner square row (the GD ground pattern), rhythm every ~128 px
    for row in range(1, h // 128):
        y0 = row * 128
        for x in range(0, w, 128):
            d.rectangle((x + 40, y0, x + 88, y0 + 48), outline=(90, 110, 156, 90), width=3)
            d.rectangle((x + 52, y0 + 110, x + 76, y0 + 134), fill=(44, 54, 84, 110))
    # baked surface halo
    halo = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(halo).rectangle((0, 0, w, 8), fill=(255, 255, 255, 210))
    halo = halo.filter(ImageFilter.GaussianBlur(7))
    im.alpha_composite(halo)
    return im


# ------------------------------------------------------------- pusher block
def draw_pusher(size=168):
    """The road block: reads SOLID (chevron face) - it shoves, never kills."""
    im = draw_block(size)
    d = ImageDraw.Draw(im)
    # hazard chevrons pointing UP on the face (theme-tintable near-white)
    for i in range(3):
        y0 = int(size * (0.34 + i * 0.17))
        h = 16
        pts = [(int(size * 0.32), y0 + h), (int(size * 0.50), y0),
               (int(size * 0.68), y0 + h), (int(size * 0.68), y0 + h + 9),
               (int(size * 0.50), y0 + 9), (int(size * 0.32), y0 + h + 9)]
        d.polygon(pts, fill=(215, 228, 252, 150))
    return im


# ------------------------------------------------------------------- spikes
def draw_spike(size=168, small=False):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    m = int(size * 0.10)
    apex = (size // 2, m)
    bl = (m + 4, size - m)
    br = (size - m - 4, size - m)

    def halo(d):
        d.polygon([apex, bl, br], outline=(255, 255, 255, 220), width=6)
    im.alpha_composite(glow_layer(size, halo, 9, 0.85))
    # filled inner gradient (the FILLED law) - bright core fading down
    grad = vgrad(size, size, (210, 228, 255, 235), (70, 90, 140, 160))
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).polygon([apex, bl, br], fill=255)
    im.paste(grad, (0, 0), mask)
    d = ImageDraw.Draw(im)
    d.polygon([apex, bl, br], outline=(248, 252, 255, 255), width=5)
    # short inner triangle line (the GD structure line)
    k = 0.30
    ia = (size // 2, int(m + (size - 2 * m) * k))
    ib = (int(m + 4 + (size - 2 * m - 8) * (1 - k * 0.9)), size - m - 4)
    ic = (int(size - m - 4 - (size - 2 * m - 8) * (1 - k * 0.9)), size - m - 4)
    d.polygon([ia, ib, ic], outline=(255, 255, 255, 100), width=3)
    return im


# ---------------------------------------------------------------------- saw
def draw_saw(size=168):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx = cy = size // 2
    r_out = int(size * 0.42)
    r_in = int(size * 0.33)
    teeth = 12

    def halo(d):
        d.ellipse((cx - r_out, cy - r_out, cx + r_out, cy + r_out),
                  outline=(255, 255, 255, 210), width=6)
    im.alpha_composite(glow_layer(size, halo, 9, 0.8))
    pts = []
    for i in range(teeth * 2):
        ang = math.pi * i / teeth + 0.13        # offset so a tooth points up
        r = r_out if i % 2 == 0 else r_in
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    grad = vgrad(size, size, (225, 238, 255, 245), (96, 116, 168, 210))
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    im.paste(grad, (0, 0), mask)
    d = ImageDraw.Draw(im)
    d.polygon(pts, outline=(248, 252, 255, 255), width=3)
    # the dark hub + ring (reads as a spinning blade)
    d.ellipse((cx - 26, cy - 26, cx + 26, cy + 26), fill=(13, 17, 28, 255))
    d.ellipse((cx - 26, cy - 26, cx + 26, cy + 26), outline=(210, 226, 252, 230), width=4)
    d.ellipse((cx - 8, cy - 8, cx + 8, cy + 8), fill=(190, 208, 240, 255))
    return im


# ------------------------------------------------------------- golden orbit
def draw_orbit(size=128):
    """ring_01 anatomy recast: golden filled core + white ring + baked glow."""
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx = cy = size // 2
    r_core = int(size * 0.26)
    r_ring = int(size * 0.38)

    def halo(d):
        d.ellipse((cx - r_ring, cy - r_ring, cx + r_ring, cy + r_ring),
                  outline=(255, 232, 150, 230), width=8)
    im.alpha_composite(glow_layer(size, halo, 12, 1.0))
    d = ImageDraw.Draw(im)
    # core: radial-ish golden fill (two circles)
    d.ellipse((cx - r_core, cy - r_core, cx + r_core, cy + r_core),
              fill=(255, 176, 52, 255))
    d.ellipse((cx - int(r_core * 0.62), cy - int(r_core * 0.62),
               cx + int(r_core * 0.62), cy + int(r_core * 0.62)),
              fill=(255, 232, 150, 255))
    # the white ring + the dark gap (GD anatomy)
    d.ellipse((cx - r_ring, cy - r_ring, cx + r_ring, cy + r_ring),
              outline=(255, 252, 240, 255), width=7)
    # glint
    d.ellipse((cx - int(r_core * 0.34), cy - int(r_core * 0.5),
               cx - int(r_core * 0.02), cy - int(r_core * 0.18)),
              fill=(255, 255, 255, 220))
    return im


def draw_twinkle(size=96, t=0):
    """starAnim-style 4-point star, t in 0..3 = open..closed."""
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx = cy = size // 2
    long_ = size * (0.46 - 0.09 * t)
    short = size * (0.10 + 0.02 * t)
    pts = []
    for i in range(8):
        ang = math.pi * i / 4 - math.pi / 2
        r = long_ if i % 2 == 0 else short
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    d.polygon(pts, fill=(255, 244, 200, 235 - 40 * t))
    im = im.filter(ImageFilter.GaussianBlur(1 + t * 0.6))
    return im


# ---------------------------------------------------------------- particles
def draw_dot(size=96, hard=False):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = size // 2
    steps = 14
    for i in range(steps, 0, -1):
        r = size * 0.46 * (i / steps)
        a = int(255 * (1 - i / steps) ** 1.6) if not hard else int(255 * (1 - i / steps) ** 0.8)
        d.ellipse((c - r, c - r, c + r, c + r), fill=(255, 255, 255, a))
    d.ellipse((c - size * 0.10, c - size * 0.10, c + size * 0.10, c + size * 0.10),
              fill=(255, 255, 255, 255))
    return im


def draw_flame(size=96):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = size // 2
    # teardrop: apex up (the engine points it backwards)
    pts = []
    for i in range(24):
        ang = math.pi * 2 * i / 24
        x = math.sin(ang)
        y = -(math.cos(ang) * 0.72 + 0.28)
        pts.append((c + x * size * 0.30, c + y * size * 0.42))
    d.polygon(pts, fill=(255, 255, 255, 235))
    d.ellipse((c - size * 0.16, c + size * 0.02, c + size * 0.16, c + size * 0.34),
              fill=(255, 255, 255, 255))
    return im.filter(ImageFilter.GaussianBlur(2))


def draw_spark(size=96):
    return draw_twinkle(size, 0)


def draw_shard(size=64):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.polygon([(size * 0.5, 2), (size - 4, size - 6), (4, size - 6)],
              fill=(255, 255, 255, 235))
    return im


def draw_burst(size=64):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rounded_rect(d, (8, 8, size - 8, size - 8), 10, fill=(255, 255, 255, 240))
    return im.filter(ImageFilter.GaussianBlur(1))


def draw_ring(size=192, width=8):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = size // 2
    d.ellipse((c - size // 2 + width, c - size // 2 + width,
               c + size // 2 - width, c + size // 2 - width),
              outline=(255, 255, 255, 235), width=width)
    return im.filter(ImageFilter.GaussianBlur(1.5))


# ------------------------------------------------------------ mechanic chips
def draw_chip_normal(size=144):
    """circle + up arrow (owner spec)."""
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx = int(size * 0.36)
    cy = size // 2
    r = int(size * 0.22)

    def halo(dd):
        dd.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(255, 255, 255, 220), width=8)
    im.alpha_composite(glow_layer(size, halo, 7, 0.9))
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(250, 252, 255, 255), width=8)
    d.ellipse((cx - r + 12, cy - r + 12, cx + r - 12, cy + r - 12),
              fill=(255, 255, 255, 60))
    # the up arrow, right side
    ax = int(size * 0.74)
    ay = int(size * 0.50)
    aw = int(size * 0.15)
    d.polygon([(ax, ay - int(size * 0.26)), (ax + aw, ay), (ax + aw // 3, ay),
               (ax + aw // 3, ay + int(size * 0.24)), (ax - aw // 3, ay + int(size * 0.24)),
               (ax - aw // 3, ay), (ax - aw, ay)], fill=(250, 252, 255, 255))
    return im


def _arrow(d, x, y, w, h, up=True, col=(250, 252, 255, 255)):
    """A clean block arrow centered at (x, y): h total, w bar width."""
    s = 1 if up else -1
    head_w = w * 1.9
    head_h = int(h * 0.42)
    shaft_w = int(w * 0.62)
    y0 = y + s * h // 2          # base of the arrow
    y1 = y - s * h // 2          # tip
    d.polygon([(x, y1), (x + head_w / 2, y1 + s * head_h),
               (x + shaft_w / 2, y1 + s * head_h),
               (x + shaft_w / 2, y0),
               (x - shaft_w / 2, y0),
               (x - shaft_w / 2, y1 + s * head_h),
               (x - head_w / 2, y1 + s * head_h)], fill=col)


def draw_chip_flip(size=144):
    """up + down arrows side by side (owner spec)."""
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    w = int(size * 0.17)
    y = size // 2

    def halo(dd):
        _arrow(dd, int(size * 0.33), y, w, int(size * 0.60), True)
        _arrow(dd, int(size * 0.67), y, w, int(size * 0.60), False)
    im.alpha_composite(glow_layer(size, halo, 6, 0.85))
    _arrow(d, int(size * 0.33), y, w, int(size * 0.60), True)
    _arrow(d, int(size * 0.67), y, w, int(size * 0.60), False)
    return im


def draw_chip_sticky(size=144):
    """up + down arrows LINKED by an S-curve (owner spec: connected)."""
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    w = int(size * 0.15)
    x1 = int(size * 0.32)
    x2 = int(size * 0.68)
    ya = int(size * 0.31)
    yb = int(size * 0.69)

    # the S link: two arcs between the arrows
    def link(dd, col, width):
        dd.arc((x1 - 6, ya, x2 + 6, (ya + yb) // 2 + 10), 200, 340, fill=col, width=width)
        dd.arc((x1 - 6, (ya + yb) // 2 - 10, x2 + 6, yb), 20, 160, fill=col, width=width)

    def halo(dd):
        _arrow(dd, x1, ya, w, int(size * 0.34), True)
        _arrow(dd, x2, yb, w, int(size * 0.34), False)
        link(dd, (255, 255, 255, 200), 10)
    im.alpha_composite(glow_layer(size, halo, 6, 0.85))
    link(d, (170, 205, 255, 255), 7)
    _arrow(d, x1, ya, w, int(size * 0.34), True)
    _arrow(d, x2, yb, w, int(size * 0.34), False)
    return im


# --------------------------------------------------------------- bg deco
def draw_deco(size=384, kind="diamond"):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = size // 2
    if kind == "diamond":
        d.polygon([(c, size * 0.10), (size * 0.90, c), (c, size * 0.90), (size * 0.10, c)],
                  outline=(255, 255, 255, 170), width=10)
        d.polygon([(c, size * 0.26), (size * 0.74, c), (c, size * 0.74), (size * 0.26, c)],
                  fill=(255, 255, 255, 46))
    elif kind == "square":
        rounded_rect(d, (size * 0.14, size * 0.14, size * 0.86, size * 0.86), 28,
                     outline=(255, 255, 255, 170), width=10)
        rounded_rect(d, (size * 0.30, size * 0.30, size * 0.70, size * 0.70), 14,
                     fill=(255, 255, 255, 46))
    else:  # ring
        d.ellipse((size * 0.12, size * 0.12, size * 0.88, size * 0.88),
                  outline=(255, 255, 255, 170), width=10)
        d.ellipse((size * 0.34, size * 0.34, size * 0.66, size * 0.66),
                  fill=(255, 255, 255, 46))
    return im.filter(ImageFilter.GaussianBlur(2))


def main():
    print("GEOMETRY FLASH art - original neon-filled redesigns (study-informed)")
    for sid, (hi, lo) in SKINS.items():
        save(draw_cube(160, hi, lo), f"skin_{sid}.png")
    save(draw_block(), "block.png")
    save(draw_line(), "line.png")
    save(draw_strip(), "strip.png")
    save(draw_pusher(), "pusher.png")
    save(draw_spike(), "spike.png")
    save(draw_saw(), "saw.png")
    save(draw_orbit(), "orbit.png")
    for t in range(4):
        save(draw_twinkle(96, t), f"tw_{t}.png")
    save(draw_dot(), "p_dot.png")
    save(draw_flame(), "p_flame.png")
    save(draw_spark(), "p_spark.png")
    save(draw_shard(), "p_shard.png")
    save(draw_burst(), "p_burst.png")
    save(draw_ring(), "p_ring.png")
    save(draw_glow128(), "p_glow.png")
    save(draw_chip_normal(), "chip_normal.png")
    save(draw_chip_flip(), "chip_flip.png")
    save(draw_chip_sticky(), "chip_sticky.png")
    save(draw_deco(384, "diamond"), "deco_diamond.png")
    save(draw_deco(384, "square"), "deco_square.png")
    save(draw_deco(384, "ring"), "deco_ring.png")
    save(draw_ring(256, 10), "tap_ring.png")
    print("done.")


def draw_glow128():
    return draw_dot(128)


if __name__ == "__main__":
    main()
