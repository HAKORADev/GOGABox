#!/usr/bin/env python3
# v0.3.2 SPACE INVADERS - the art pass (rebuilt from the owner's contract).
# Paints every invader asset into assets/games/invaders/ :
#   7 crew ships (derived from the lanes hulls - the owner: "edit some ships and
#   change their size and colors"), 11 enemy kinds, 10 bosses, 10 planet plates
#   (+ the neutral scheme), projectiles/VFX and items.
# Deterministic: every random call is seeded. 4x supersample on painted bodies.
import os, math, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))          # projects/gogabox
PROJ = ROOT
LANES = os.path.join(PROJ, "assets", "games", "lanes")
OUT = os.path.join(PROJ, "assets", "games", "invaders")
os.makedirs(OUT, exist_ok=True)

def S(x):  # supersample factor
    return 4 if x <= 400 else 2

def canvas(w, h):
    return Image.new("RGBA", (w * S(w), h * S(h)), (0, 0, 0, 0))

def finish(im, w, h):
    return im.resize((w, h), Image.LANCZOS)

def save(im, w, h, name):
    finish(im, w, h).save(os.path.join(OUT, name))
    print("  wrote", name)

def C(hexs, a=255):
    hexs = hexs.lstrip("#")
    return (int(hexs[0:2], 16), int(hexs[2:4], 16), int(hexs[4:6], 16), a)

def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(4))

def glow_layers(base, color, radius, strength=1.0):
    """soft additive glow of the base's alpha shape, tinted."""
    g = Image.new("RGBA", base.size, (0, 0, 0, 0))
    alpha = base.split()[3]
    tint = Image.new("RGBA", base.size, color)
    g.paste(tint, (0, 0), alpha)
    g = g.filter(ImageFilter.GaussianBlur(radius))
    if strength < 1.0:
        g = g.point(lambda p: int(p * strength))
    return ImageChops.add(base, g)

def outline(im, color, width=2):
    """dark outline around the alpha shape (drawn behind)."""
    pad = width + 2
    big = Image.new("RGBA", (im.width + pad * 2, im.height + pad * 2), (0, 0, 0, 0))
    a = im.split()[3]
    mask = a.filter(ImageFilter.MaxFilter(width * 2 + 1))
    tint = Image.new("RGBA", im.size, color)
    big.paste(tint, (pad, pad), mask)
    big.paste(im, (pad, pad), im)
    return big, pad

def V(draw, pts, fill):
    draw.polygon(pts, fill=fill)

def ell(d, cx, cy, rx, ry, fill):
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=fill)

# ---------------------------------------------------------------------------
# PART 1 - THE SSDS CREW SHIPS (lanes hulls, edited: recolor + glow + mount)
# The owner's colors: ember orange, azure blue, verdant green, veteran bright
# red, phantom normal red, hornet white, titan deep red.
# ---------------------------------------------------------------------------

def hueRotate(im, deg):
    """rotate hue of every pixel by deg degrees."""
    arr = np.array(im).astype(np.float32)
    a = arr[..., 3:4] / 255.0
    rgb = arr[..., :3] / 255.0
    mx = rgb.max(-1); mn = rgb.min(-1)
    df = mx - mn + 1e-9
    h = np.zeros_like(mx)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    m = mx == r; h[m] = ((g[m] - b[m]) / df[m]) % 6
    m = mx == g; h[m] = (b[m] - r[m]) / df[m] + 2
    m = mx == b; h[m] = (r[m] - g[m]) / df[m] + 4
    h = (h * 60 + deg) % 360
    s = np.where(mx > 0, df / (mx + 1e-9), 0)
    v = mx
    c = v * s
    x = c * (1 - np.abs((h / 60) % 2 - 1))
    mzero = v - c
    hh = (h / 60).astype(int) % 6
    r2 = np.choose(hh, [c, x, np.zeros_like(c), np.zeros_like(c), mzero, v]) + mzero
    g2 = np.choose(hh, [v, c, c, x, np.zeros_like(c), mzero]) + mzero
    b2 = np.choose(hh, [mzero, mzero, v, c, c, x]) + mzero
    out = np.stack([r2, g2, b2], -1)
    res = np.concatenate([out, a], -1)
    res = (np.clip(res, 0, 1) * 255).astype(np.uint8)
    return Image.fromarray(res, "RGBA")

def tint(im, rgb, keep=0.35):
    """blend toward rgb while keeping some original color."""
    arr = np.array(im).astype(np.float32)
    tgt = np.array(rgb[:3], dtype=np.float32)
    arr[..., :3] = arr[..., :3] * keep + tgt * (1 - keep)
    return Image.fromarray(arr.astype(np.uint8), "RGBA")

def cockpit_glow(im, color, fx=0.5, fy=0.30, r=0.13):
    """add a glowing cockpit dot near the nose."""
    w, h = im.size
    glow = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(glow)
    ell(d, w * fx, h * fy, w * r, w * r, color)
    glow = glow.filter(ImageFilter.GaussianBlur(int(w * 0.06) + 1))
    core = Image.new("RGBA", im.size, (0, 0, 0, 0))
    dc = ImageDraw.Draw(core)
    ell(dc, w * fx, h * fy, w * r * 0.45, w * r * 0.45, (255, 255, 255, 230))
    return Image.alpha_composite(Image.alpha_composite(im, glow), core)

def mount_cannons(im, color, y_frac=0.52):
    """twin wing gun pods (metal barrels pointing up) - reads as gear, not holes."""
    w, h = im.size
    layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cw = max(5, w // 13)
    for sx in (0.18, 0.82):
        cx = int(w * sx)
        d.rounded_rectangle([cx - cw, int(h * 0.06), cx + cw, int(h * 0.80)], radius=cw, fill=C("#8c99a8"))
        d.rounded_rectangle([cx - cw + 2, int(h * 0.06) + 2, cx + cw - 2, int(h * 0.80)], radius=cw - 2, fill=C("#b7c2cf"))
        d.ellipse([cx - cw, int(h * 0.02), cx + cw, int(h * 0.02) + cw * 2], fill=C("#5d6a78"))
    return Image.alpha_composite(layer, im)

def ship(src, hue, tcol, glow_col, cannons=True, brighten=1.0, name="x"):
    im = Image.open(os.path.join(LANES, src)).convert("RGBA")
    if hue:
        im = hueRotate(im, hue)
    if tcol:
        im = tint(im, tcol, keep=0.30)
    if brighten != 1.0:
        arr = np.array(im).astype(np.float32)
        arr[..., :3] = np.clip(arr[..., :3] * brighten, 0, 255)
        im = Image.fromarray(arr.astype(np.uint8), "RGBA")
    im = cockpit_glow(im, glow_col)
    if cannons:
        im = mount_cannons(im, C("#2b3540"))
    im, pad = outline(im, C("#141820"), 2)
    save(im, im.width // S(im.width) if False else im.width, im.height, name)

def crew_ships():
    print("crew ships (lanes hulls edited):")
    # azure - the protector: keep the blue hull, whiter armor, cyan cockpit
    ship("ship_blue.png", 0, C("#bfe8ff"), C("#9ff2ff", 200), brighten=1.08, name="ship_azure.png")
    # ember - hotter orange with red edges
    ship("ship_orange.png", -8, C("#ff9a2a"), C("#ffd27a", 210), name="ship_ember.png")
    # verdant - emerald push
    ship("ship_green.png", 6, C("#3ecf6e"), C("#a6ffbe", 200), name="ship_verdant.png")
    # veteran - BRIGHT red (owner said bright red, not orange-red)
    ship("ship_veteran.png", 175, C("#ff2222"), C("#ffb0b0", 210), brighten=1.16, name="ship_veteran.png")
    # phantom - normal red, stealthy dark panels
    ship("ship_phantom.png", 180, C("#d93636"), C("#ff9d9d", 190), brighten=0.94, name="ship_phantom.png")
    # hornet - WHITE hull with amber stripes
    ship("ship_horn.png", 0, C("#f2f5f8"), C("#ffd76a", 220), brighten=1.22, name="ship_hornet.png")
    # titan - deep red armored, smaller (the lanes titan was huge)
    im = Image.open(os.path.join(LANES, "ship_titan.png")).convert("RGBA")
    im = tint(hueRotate(im, 168), C("#8f1d2c"), keep=0.42)
    im = cockpit_glow(im, C("#ff6a5a", 210))
    im, pad = outline(im, C("#141820"), 2)
    im = im.resize((int(im.width * 0.66), int(im.height * 0.66)), Image.LANCZOS)
    save(im, im.width, im.height, "ship_titan.png")

# ---------------------------------------------------------------------------
# PART 2 - THE ENEMIES (11 kinds, alien tech, neon cores, Kenney-flat style)
# ---------------------------------------------------------------------------

def body_base(w, h, hull, hull_dark, hull_lite):
    """the shared flat-alien body: base ellipse + top light + bottom shade."""
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    W, H = im.size
    ell(d, W/2, H/2, W/2*0.86, H/2*0.80, hull)
    # bottom shade (clipped)
    sh = Image.new("RGBA", im.size, (0,0,0,0))
    ds = ImageDraw.Draw(sh)
    ell(ds, W/2, H/2 + H*0.10, W/2*0.84, H/2*0.76, hull_dark)
    mask = im.split()[3].point(lambda p: 255 if p > 0 else 0)
    sh.putalpha(ImageChops.multiply(sh.split()[3], mask))
    im = Image.alpha_composite(im, sh)
    # top light
    hl = Image.new("RGBA", im.size, (0,0,0,0))
    dh = ImageDraw.Draw(hl)
    ell(dh, W/2, H/2 - H*0.16, W/2*0.62, H/2*0.34, hull_lite)
    hl.putalpha(ImageChops.multiply(hl.split()[3], mask))
    im = Image.alpha_composite(im, hl)
    return im, d

def core_glow(im, color, fx=0.5, fy=0.42, r=0.16, hot=(255,255,255,235)):
    """the neon power core every enemy wears."""
    W, H = im.size
    g = Image.new("RGBA", im.size, (0,0,0,0))
    d = ImageDraw.Draw(g)
    ell(d, W*fx, H*fy, W*r*1.6, H*r*1.6, color)
    g = g.filter(ImageFilter.GaussianBlur(int(W*0.05)+1))
    im = Image.alpha_composite(im, g)
    d2 = ImageDraw.Draw(im)
    ell(d2, W*fx, H*fy, W*r, H*r, color)
    ell(d2, W*fx, H*fy, W*r*0.5, H*r*0.5, hot)
    return im

def finish_body(im, w, h, name, oc="#12141c", ow=2):
    im2, pad = outline(finish(im, w, h), C(oc), ow)
    im2.save(os.path.join(OUT, name))
    print("  wrote", name)

def enemy_grunt():
    w, h = 88, 80
    im, d = body_base(w, h, C("#7d7f9c"), C("#4a4b66"), C("#a9abc9"))
    W, H = im.size
    dd = ImageDraw.Draw(im)
    # side pods
    ell(dd, W*0.14, H*0.55, W*0.13, H*0.20, C("#5d5f80"))
    ell(dd, W*0.86, H*0.55, W*0.13, H*0.20, C("#5d5f80"))
    im = core_glow(im, C("#57e8ff", 235))
    finish_body(im, w, h, "en_grunt.png")

def enemy_swift():
    w, h = 96, 72
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    W, H = im.size
    V(d, [(W*0.5, H*0.06), (W*0.92, H*0.62), (W*0.5, H*0.94), (W*0.08, H*0.62)], C("#9a8fb8"))
    V(d, [(W*0.5, H*0.20), (W*0.76, H*0.60), (W*0.5, H*0.82), (W*0.24, H*0.60)], C("#6f6592"))
    im = core_glow(im, C("#ff5fd0", 235), fy=0.5, r=0.13)
    finish_body(im, w, h, "en_swift.png")

def enemy_aimer():
    w, h = 96, 84
    im, d = body_base(w, h, C("#6e9c8a"), C("#3f5f54"), C("#9ccab6"))
    dd = ImageDraw.Draw(im)
    W, H = im.size
    # the eye
    ell(dd, W/2, H*0.42, W*0.30, H*0.26, C("#1c2a26"))
    ell(dd, W/2, H*0.42, W*0.20, H*0.17, C("#8dffB0".lower()))
    ell(dd, W/2, H*0.42, W*0.09, H*0.09, C("#101418"))
    im = core_glow(im, C("#8dffb0", 200), fy=0.80, r=0.10)
    finish_body(im, w, h, "en_aimer.png")

def enemy_diver():
    w, h = 64, 88
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    W, H = im.size
    V(d, [(W*0.5, H*0.04), (W*0.86, H*0.55), (W*0.68, H*0.96), (W*0.32, H*0.96), (W*0.14, H*0.55)], C("#8a6f9e"))
    V(d, [(W*0.5, H*0.16), (W*0.70, H*0.55), (W*0.5, H*0.86), (W*0.30, H*0.55)], C("#5d4770"))
    im = core_glow(im, C("#ff7a5c", 240), fy=0.34, r=0.15)
    finish_body(im, w, h, "en_diver.png")

def enemy_tank():
    w, h = 120, 96
    im, d = body_base(w, h, C("#a08658"), C("#5f4c2e"), C("#cbb083"))
    dd = ImageDraw.Draw(im)
    W, H = im.size
    # armor plates
    for i, fx in enumerate((0.24, 0.5, 0.76)):
        dd.rounded_rectangle([W*fx-W*0.10, H*0.18, W*fx+W*0.10, H*0.62], radius=8, fill=C("#7c6540"))
        dd.rounded_rectangle([W*fx-W*0.10+2, H*0.18+2, W*fx+W*0.10-2, H*0.60], radius=6, fill=C("#b39a68"))
    im = core_glow(im, C("#ffc14d", 235), fy=0.78, r=0.11)
    finish_body(im, w, h, "en_tank.png")

def enemy_split():
    w, h = 84, 84
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    W, H = im.size
    ell(d, W*0.34, H*0.42, W*0.30, H*0.30, C("#79b8a8"))
    ell(d, W*0.66, H*0.58, W*0.30, H*0.30, C("#79b8a8"))
    ell(d, W*0.62, H*0.54, W*0.26, H*0.26, C("#9fd8c9"))
    ell(d, W*0.30, H*0.38, W*0.26, H*0.26, C("#9fd8c9"))
    ell(d, W*0.30, H*0.38, W*0.10, H*0.10, C("#ff5f8a"))
    ell(d, W*0.62, H*0.54, W*0.10, H*0.10, C("#ff5f8a"))
    finish_body(im, w, h, "en_split.png")

def enemy_weaver():
    w, h = 110, 80
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    W, H = im.size
    # ghost ray wings
    V(d, [(W*0.5, H*0.5), (W*0.04, H*0.14), (W*0.30, H*0.55), (W*0.04, H*0.86)], C("#5fb8b2"))
    V(d, [(W*0.5, H*0.5), (W*0.96, H*0.14), (W*0.70, H*0.55), (W*0.96, H*0.86)], C("#5fb8b2"))
    ell(d, W/2, H/2, W*0.16, H*0.34, C("#8fe8e2"))
    a = np.array(im).astype(np.float32)
    a[..., 3] = a[..., 3] * 0.88
    im = Image.fromarray(a.astype(np.uint8), "RGBA")
    im = core_glow(im, C("#d2fff9", 235), fy=0.5, r=0.13)
    finish_body(im, w, h, "en_weaver.png")

def enemy_spit():
    w, h = 100, 90
    im, d = body_base(w, h, C("#8f7fb0"), C("#55486e"), C("#b6a8d4"))
    dd = ImageDraw.Draw(im)
    W, H = im.size
    for fx in (0.22, 0.5, 0.78):
        dd.rectangle([W*fx-4, H*0.06, W*fx+4, H*0.30], fill=C("#3d3352"))
        ell(dd, W*fx, H*0.06, 7, 7, C("#ffd257"))
    im = core_glow(im, C("#ffd257", 235), fy=0.68, r=0.12)
    finish_body(im, w, h, "en_spit.png")

def enemy_brute():
    w, h = 130, 104
    im, d = body_base(w, h, C("#7a5f8f"), C("#463358"), C("#a288ba"))
    dd = ImageDraw.Draw(im)
    W, H = im.size
    # shoulder gun pods
    dd.rounded_rectangle([W*0.04, H*0.30, W*0.26, H*0.58], radius=10, fill=C("#332445"))
    dd.rounded_rectangle([W*0.74, H*0.30, W*0.96, H*0.58], radius=10, fill=C("#332445"))
    dd.rectangle([W*0.12, H*0.58, W*0.18, H*0.74], fill=C("#221634"))
    dd.rectangle([W*0.82, H*0.58, W*0.88, H*0.74], fill=C("#221634"))
    # visor
    dd.rounded_rectangle([W*0.32, H*0.28, W*0.68, H*0.44], radius=8, fill=C("#171126"))
    dd.rounded_rectangle([W*0.35, H*0.31, W*0.65, H*0.40], radius=6, fill=C("#ff4d6b"))
    im = core_glow(im, C("#ff4d6b", 225), fy=0.74, r=0.10)
    finish_body(im, w, h, "en_brute.png")

def enemy_magma():
    w, h = 92, 92
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    W, H = im.size
    ell(d, W/2, H/2, W*0.44, H*0.44, C("#ff8c3a"))
    ell(d, W/2, H/2, W*0.34, H*0.34, C("#ffb95e"))
    # rock shell chunks
    rng = random.Random(32)
    for _ in range(7):
        ang = rng.uniform(0, math.tau)
        rr = W*0.30
        cx, cy = W/2 + math.cos(ang)*rr, H/2 + math.sin(ang)*rr
        ell(d, cx, cy, W*0.10, H*0.10, C("#6e4a3a"))
    im = core_glow(im, C("#fff0b0", 240), fy=0.44, r=0.14)
    finish_body(im, w, h, "en_magma.png")

def enemy_void():
    w, h = 104, 104
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    W, H = im.size
    r = W*0.44
    pts = [(W/2 + r*math.cos(math.pi/6 + i*math.pi/3), H/2 + r*math.sin(math.pi/6 + i*math.pi/3)) for i in range(6)]
    V(d, pts, C("#2c2440"))
    r2 = r*0.78
    pts = [(W/2 + r2*math.cos(math.pi/6 + i*math.pi/3), H/2 + r2*math.sin(math.pi/6 + i*math.pi/3)) for i in range(6)]
    V(d, pts, C("#43365e"))
    im = core_glow(im, C("#b06bff", 240), fy=0.5, r=0.16)
    finish_body(im, w, h, "en_void.png")

# ---------------------------------------------------------------------------
# PART 3 - THE BOSSES (10, planet themed, big, characterful)
# ---------------------------------------------------------------------------

def boss_base(w, h, hull, dark, lite):
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    W, H = im.size
    # broad manta hull
    V(d, [(W*0.5, H*0.04), (W*0.97, H*0.48), (W*0.80, H*0.90), (W*0.5, H*0.98),
          (W*0.20, H*0.90), (W*0.03, H*0.48)], hull)
    inner = [(W*0.5, H*0.16), (W*0.84, H*0.50), (W*0.70, H*0.80), (W*0.5, H*0.86),
             (W*0.30, H*0.80), (W*0.16, H*0.50)]
    V(d, inner, dark)
    inner2 = [(W*0.5, H*0.22), (W*0.74, H*0.50), (W*0.5, H*0.74), (W*0.26, H*0.50)]
    V(d, inner2, lite)
    return im, d

def boss_core(im, color, r=0.17, fy=0.46):
    return core_glow(im, color, fy=fy, r=r)

def boss_finish(im, w, h, name):
    finish_body(im, w, h, name, oc="#0e1016", ow=3)

def boss_triton():
    w, h = 240, 200
    im, d = boss_base(w, h, C("#4a7fb5"), C("#2c517c"), C("#6fa3d8"))
    W, H = im.size
    # the trident crest
    t = Image.new("RGBA", im.size, (0,0,0,0)); dt = ImageDraw.Draw(t)
    cx = W*0.5
    dt.rectangle([cx-6, H*0.30, cx+6, H*0.72], fill=C("#dff2ff"))
    for sx in (-1, 1):
        dt.rectangle([cx+sx*34-5, H*0.36, cx+sx*34+5, H*0.70], fill=C("#dff2ff"))
        V(dt, [(cx+sx*34-9, H*0.40), (cx+sx*34, H*0.26), (cx+sx*34+9, H*0.40)], C("#dff2ff"))
    im = Image.alpha_composite(im, t)
    im = boss_core(im, C("#7fe4ff", 240))
    boss_finish(im, w, h, "boss_triton.png")

def boss_monarch():
    w, h = 230, 210
    im, d = boss_base(w, h, C("#7fc4cf"), C("#4b8f9c"), C("#a8e2ea"))
    W, H = im.size
    # the VERTICAL ring (uranus tilt)
    ring = Image.new("RGBA", im.size, (0,0,0,0)); dr = ImageDraw.Draw(ring)
    dr.ellipse([W*0.30, -H*0.18, W*0.70, H*1.18], outline=C("#d6f7fb", 210), width=int(W*0.035))
    im = Image.alpha_composite(im, ring)
    im = boss_core(im, C("#c9f6ff", 240))
    boss_finish(im, w, h, "boss_monarch.png")

def boss_duke():
    w, h = 280, 210
    im, d = boss_base(w, h, C("#c9a45c"), C("#8a6c36"), C("#e6c88a"))
    W, H = im.size
    # THE ring
    ring = Image.new("RGBA", im.size, (0,0,0,0)); dr = ImageDraw.Draw(ring)
    dr.ellipse([-W*0.06, H*0.30, W*1.06, H*0.66], outline=C("#f2ddad", 215), width=int(W*0.045))
    im = Image.alpha_composite(im, ring)
    # shard studs on the ring (the shard-ring boss)
    dd = ImageDraw.Draw(im)
    for fx in (0.06, 0.5, 0.94):
        ell(dd, W*fx, H*0.48, W*0.022, W*0.022, C("#fff6e0"))
    im = boss_core(im, C("#ffe9b8", 240))
    boss_finish(im, w, h, "boss_duke.png")

def boss_storm():
    w, h = 270, 210
    im, d = boss_base(w, h, C("#c98a5c"), C("#8a5436", 255), C("#e6b58a"))
    W, H = im.size
    # band stripes
    dd = ImageDraw.Draw(im)
    for fy in (0.30, 0.62, 0.80):
        dd.line([(W*0.10, H*fy), (W*0.90, H*fy)], fill=C("#8a5436"), width=int(H*0.035))
    # the great red spot core
    im = boss_core(im, C("#ff5f4d", 245), r=0.20)
    boss_finish(im, w, h, "boss_storm.png")

def boss_reaver():
    w, h = 260, 200
    im, d = boss_base(w, h, C("#b56a4a"), C("#7c3f2a"), C("#d99a72"))
    W, H = im.size
    # blade arms (the dash charger)
    dd = ImageDraw.Draw(im)
    for sx in (0.02, 0.98):
        V(dd, [(W*sx, H*0.30), (W*(0.5+(sx-0.5)*0.5), H*0.52), (W*sx, H*0.74)], C("#e8e0d2"))
    im = boss_core(im, C("#ffb37a", 240))
    boss_finish(im, w, h, "boss_reaver.png")

def boss_mimic():
    w, h = 240, 200
    im, d = boss_base(w, h, C("#5c8fd8"), C("#38639f"), C("#8ab4e8"))
    W, H = im.size
    # OUR protector's cockpit - but cracked (the wrong-blue lie)
    dd = ImageDraw.Draw(im)
    ell(dd, W*0.5, H*0.40, W*0.16, H*0.12, C("#dff2ff"))
    dd.line([(W*0.44, H*0.34), (W*0.52, H*0.44)], fill=C("#26364f"), width=5)
    dd.line([(W*0.56, H*0.36), (W*0.50, H*0.46)], fill=C("#26364f"), width=4)
    # white SSDS stripes
    dd.line([(W*0.14, H*0.66), (W*0.86, H*0.66)], fill=C("#f2f6fa"), width=int(H*0.045))
    im = boss_core(im, C("#8ab4ff", 235))
    boss_finish(im, w, h, "boss_mimic.png")

def boss_ash():
    w, h = 250, 220
    im, d = boss_base(w, h, C("#d8c069"), C("#9c8a3f"), C("#f0e0a0"))
    W, H = im.size
    # the veil (sulfur cloud deck)
    v = Image.new("RGBA", im.size, (0,0,0,0)); dv = ImageDraw.Draw(v)
    ell(dv, W*0.5, H*0.72, W*0.40, H*0.20, C("#f0e6b8", 180))
    ell(dv, W*0.30, H*0.80, W*0.22, H*0.12, C("#f0e6b8", 150))
    ell(dv, W*0.72, H*0.78, W*0.20, H*0.11, C("#f0e6b8", 150))
    im = Image.alpha_composite(im, v.filter(ImageFilter.GaussianBlur(6)))
    # crown spikes
    dd = ImageDraw.Draw(im)
    for fx in (0.30, 0.5, 0.70):
        V(dd, [(W*fx-W*0.03, H*0.22), (W*fx, H*0.02), (W*fx+W*0.03, H*0.22)], C("#f0e0a0"))
    im = boss_core(im, C("#fff3c4", 240))
    boss_finish(im, w, h, "boss_ash.png")

def boss_eater():
    w, h = 250, 210
    im, d = boss_base(w, h, C("#9a9aa4"), C("#5e5e6a"), C("#c4c4ce"))
    W, H = im.size
    # craters
    dd = ImageDraw.Draw(im)
    rng = random.Random(88)
    for _ in range(6):
        cx = rng.uniform(W*0.16, W*0.84); cy = rng.uniform(H*0.30, H*0.78)
        rr = rng.uniform(W*0.03, W*0.06)
        ell(dd, cx, cy, rr, rr, C("#6a6a76"))
        ell(dd, cx-rr*0.15, cy-rr*0.15, rr*0.7, rr*0.7, C("#b2b2bc"))
    im = boss_core(im, C("#ffd8a8", 235), r=0.15)
    boss_finish(im, w, h, "boss_eater.png")

def boss_herald():
    w, h = 270, 230
    im, d = boss_base(w, h, C("#ff9d3c"), C("#e0632a"), C("#ffd05e"))
    W, H = im.size
    # corona crown: flame spikes all around
    dd = ImageDraw.Draw(im)
    rng = random.Random(9)
    for i in range(12):
        ang = math.pi * (0.08 + 0.84 * i / 11)
        x0, y0 = W*0.5 + math.cos(ang)*W*0.30, H*0.46 + math.sin(ang)*H*0.34
        x1, y1 = W*0.5 + math.cos(ang)*W*0.46, H*0.46 + math.sin(ang)*H*0.50
        dd.line([(x0, y0), (x1, y1)], fill=C("#ffdd7a", 220), width=int(W*0.025))
    im = boss_core(im, C("#fff6d0", 250), r=0.19)
    boss_finish(im, w, h, "boss_herald.png")

def boss_invader():
    w, h = 340, 280
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    W, H = im.size
    # the overlord: dark void hexagon + spike crown + reactor veins
    r = W*0.36
    pts = [(W/2 + r*math.cos(i*math.pi/3 - math.pi/2), H*0.52 + r*math.sin(i*math.pi/3 - math.pi/2)) for i in range(6)]
    V(d, pts, C("#241d38"))
    r2 = r*0.84
    pts = [(W/2 + r2*math.cos(i*math.pi/3 - math.pi/2), H*0.52 + r2*math.sin(i*math.pi/3 - math.pi/2)) for i in range(6)]
    V(d, pts, C("#372b56"))
    # spikes
    dd = ImageDraw.Draw(im)
    for i in range(6):
        ang = i*math.pi/3 - math.pi/2
        V(dd, [(W/2 + math.cos(ang)*r*0.98 - math.sin(ang)*10, H*0.52 + math.sin(ang)*r*0.98 + math.cos(ang)*10),
               (W/2 + math.cos(ang)*r*1.28, H*0.52 + math.sin(ang)*r*1.28),
               (W/2 + math.cos(ang)*r*0.98 + math.sin(ang)*10, H*0.52 + math.sin(ang)*r*0.98 - math.cos(ang)*10)],
          C("#4a3a70"))
    # reactor veins
    rng = random.Random(666)
    for _ in range(7):
        x0 = rng.uniform(W*0.3, W*0.7); y0 = rng.uniform(H*0.3, H*0.72)
        x1 = x0 + rng.uniform(-W*0.12, W*0.12); y1 = y0 + rng.uniform(-H*0.1, H*0.1)
        dd.line([(x0, y0), (x1, y1)], fill=C("#b06bff", 200), width=5)
    im = boss_core(im, C("#c48aff", 250), r=0.17, fy=0.5)
    boss_finish(im, w, h, "boss_invader.png")

# ---------------------------------------------------------------------------
# PART 4 - THE PLANET PLATES (960x540, painted; x2 scale on the 1920 design).
# Each = atmosphere gradient + bottom surface arc + sky details + stars.
# Real-world data drives every palette/detail (the owner's law).
# ---------------------------------------------------------------------------

BW, BH = 960, 540

def stars(d, n, seed, ymax=0.62, bright=(180, 255)):
    rng = random.Random(seed)
    for _ in range(n):
        x = rng.uniform(0, BW); y = rng.uniform(0, BH * ymax)
        r = rng.uniform(0.6, 1.9)
        c = rng.randint(*bright)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(c, c, min(255, c + 20), rng.randint(120, 230)))

def grad(top, mid, bot):
    """3-stop vertical gradient as an RGB array image."""
    top = np.array(top, float); mid = np.array(mid, float); bot = np.array(bot, float)
    ys = np.linspace(0, 1, BH)[:, None]          # (BH,1)
    rows = np.where(ys < 0.5, top + (mid - top) * (ys * 2), mid + (bot - mid) * ((ys - 0.5) * 2))
    img = np.repeat(rows[:, None, :], BW, axis=1)  # (BH,BW,3)
    return Image.fromarray(img.astype(np.uint8))

def surface_arc(im, hi, lo, band=None, y_frac=0.86, noise_seed=1):
    """the planet surface: a huge ellipse arc rising from the bottom."""
    W, H = im.size
    arc = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(arc)
    ell(d, W * 0.5, H * y_frac + H * 1.1, W * 1.05, H * 1.15, lo)
    ell(d, W * 0.5, H * y_frac + H * 1.02, W * 1.03, H * 1.13, hi)
    # banded noise on the surface
    rng = random.Random(noise_seed)
    for _ in range(26):
        cx = rng.uniform(-W * 0.1, W * 1.1); cy = rng.uniform(H * y_frac, H * 1.3)
        rr = rng.uniform(W * 0.03, W * 0.16)
        col = tuple(int(np.clip(c + rng.randint(-18, 18), 0, 255)) for c in hi[:3])
        d.ellipse([cx - rr, cy - rr * 0.4, cx + rr, cy + rr * 0.4], fill=col + (70,))
    if band:
        d.ellipse([-W * 0.05, H * y_frac - H * 0.055, W * 1.05, H * y_frac + H * 0.075],
                  outline=band, width=int(H * 0.012))
    im.paste(arc, (0, 0), arc)
    # atmosphere glow above the arc
    glow = Image.new("RGBA", im.size, (0, 0, 0, 0))
    dg = ImageDraw.Draw(glow)
    dg.ellipse([-W * 0.05, H * y_frac - H * 0.10, W * 1.05, H * y_frac + H * 0.12],
               outline=hi + (120,), width=int(H * 0.05))
    glow = glow.filter(ImageFilter.GaussianBlur(18))
    im.paste(glow, (0, 0), glow)
    return im

def quantize_save(im, name):
    im = im.convert("RGB").convert("P", palette=Image.ADAPTIVE, colors=255).convert("RGBA")
    im.save(os.path.join(OUT, name), optimize=True)
    print("  wrote", name, f"{os.path.getsize(os.path.join(OUT, name))//1024}KB")

def plate(name, top, mid, bot, surf_hi, surf_lo, detail, band=None, y=0.86, seed=1):
    im = grad(top, mid, bot).convert("RGBA")
    d = ImageDraw.Draw(im)
    stars(d, 90, seed)
    im = detail(im, d) if detail else im
    im = surface_arc(im, surf_hi, surf_lo, band, y, seed * 7 + 3)
    quantize_save(im, name)

def d_neptune(im, d):
    # 2,100 km/h winds = long streak lines; the dark storm oval
    rng = random.Random(14)
    for _ in range(14):
        x0 = rng.uniform(0, BW); yy = rng.uniform(BH * 0.08, BH * 0.55)
        ln = rng.uniform(BW * 0.1, BW * 0.35)
        d.line([(x0, yy), (x0 + ln, yy - rng.uniform(4, 14))], fill=(190, 220, 255, 60), width=2)
    ell(d, BW * 0.62, BH * 0.34, 66, 26, (40, 66, 140, 70))
    ell(d, BW * 0.62, BH * 0.34, 48, 18, (34, 56, 122, 80))
    return im

def d_uranus(im, d):
    # the VERTICAL ring (98 deg tilt)
    d.ellipse([BW * 0.30, -BH * 0.30, BW * 0.56, BH * 0.95], outline=(220, 250, 252, 130), width=10)
    ell(d, BW * 0.20, BH * 0.18, 26, 26, (240, 252, 252, 220))  # a moon dot
    return im

def d_saturn(im, d):
    # the great ring band across the sky
    d.ellipse([-BW * 0.2, BH * 0.16, BW * 1.2, BH * 0.55], outline=(242, 221, 173, 150), width=16)
    d.ellipse([-BW * 0.1, BH * 0.22, BW * 1.1, BH * 0.5], outline=(200, 180, 140, 90), width=6)
    return im

def d_jupiter(im, d):
    # banded sky stripes + the red spot drifting
    for fy, a in ((0.10, 70), (0.20, 60), (0.34, 80)):
        d.line([(0, BH * fy), (BW, BH * fy - 12)], fill=(200, 150, 110, a), width=int(BH * 0.03))
    ell(d, BW * 0.68, BH * 0.30, 46, 26, (214, 92, 70, 220))
    ell(d, BW * 0.68, BH * 0.30, 30, 16, (232, 130, 100, 200))
    return im

def d_mars(im, d):
    # dust veils + the two moons
    rng = random.Random(55)
    for _ in range(8):
        x0 = rng.uniform(0, BW); yy = rng.uniform(BH * 0.1, BH * 0.5)
        d.ellipse([x0, yy, x0 + rng.uniform(120, 320), yy + rng.uniform(8, 18)], fill=(226, 160, 120, 40))
    ell(d, BW * 0.16, BH * 0.14, 9, 9, (220, 210, 200, 230))
    ell(d, BW * 0.24, BH * 0.09, 6, 6, (220, 210, 200, 200))
    return im

def d_earth(im, d):
    # cloud swirls + the moon far away
    rng = random.Random(6)
    for _ in range(10):
        x0 = rng.uniform(0, BW); yy = rng.uniform(BH * 0.08, BH * 0.5)
        rr = rng.uniform(20, 70)
        d.ellipse([x0, yy, x0 + rr * 2.4, yy + rr * 0.6], fill=(250, 252, 255, 70))
    ell(d, BW * 0.85, BH * 0.14, 14, 14, (228, 228, 236, 235))
    return im

def d_venus(im, d):
    # the sulfur deck scrolls BACKWARDS in-game (retrograde) - v-shaped cloud banks
    rng = random.Random(7)
    for _ in range(9):
        x0 = rng.uniform(0, BW); yy = rng.uniform(BH * 0.1, BH * 0.55)
        d.ellipse([x0, yy, x0 + rng.uniform(140, 340), yy + rng.uniform(16, 34)], fill=(250, 240, 200, 55))
    return im

def d_mercury(im, d):
    # soft light split (430 day / -180 night) + distant cratered rock
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    dsh = ImageDraw.Draw(sh)
    for i in range(24):
        a = int(110 * (1 - i / 23))
        dsh.rectangle([BW * 0.5 + i * (BW * 0.5 / 24), 0, BW, BH * 0.62], fill=(16, 16, 30, a))
    im.paste(sh.filter(ImageFilter.GaussianBlur(10)), (0, 0), sh.filter(ImageFilter.GaussianBlur(10)))
    ell(d, BW * 0.12, BH * 0.20, 18, 18, (150, 150, 160, 235))
    return im

def d_sun(im, d):
    # flare loops
    for fx, r in ((0.22, 60), (0.5, 90), (0.78, 55)):
        d.arc([BW * fx - r, BH * 0.30, BW * fx + r, BH * 0.30 + r * 1.6], 200, 340, fill=(255, 230, 150, 160), width=6)
    return im

def d_hideout(im, d):
    # the megastructure silhouette + reactor veins
    rng = random.Random(666)
    for i in range(7):
        x0 = BW * (0.08 + i * 0.14)
        h = rng.uniform(BH * 0.10, BH * 0.30)
        d.polygon([(x0, BH * 0.86), (x0 + BW * 0.05, BH * 0.86 - h), (x0 + BW * 0.10, BH * 0.86)],
                  fill=(24, 18, 40, 255))
        d.line([(x0 + BW * 0.05, BH * 0.86 - h * 0.9), (x0 + BW * 0.05, BH * 0.86)],
               fill=(176, 107, 255, 200), width=3)
    return im

def d_neutral(im, d):
    return im

def planet_plates():
    print("planet plates:")
    NEU = ((10, 12, 28), (8, 9, 20), (5, 6, 14))
    plate("bg_neutral.png", *NEU, (26, 30, 52), (14, 16, 30), d_neutral, seed=3)
    plate("bg_neptune.png", (8, 14, 46), (12, 28, 84), (6, 12, 40), (52, 110, 200), (22, 44, 110), d_neptune, seed=11)
    plate("bg_uranus.png", (14, 34, 44), (36, 84, 96), (18, 48, 58), (120, 200, 210), (60, 120, 132), d_uranus, seed=22)
    plate("bg_saturn.png", (36, 28, 14), (88, 66, 30), (50, 36, 16), (216, 178, 108), (130, 100, 52), d_saturn, seed=33)
    plate("bg_jupiter.png", (40, 30, 22), (120, 84, 56), (66, 44, 30), (226, 176, 128), (140, 92, 60), d_jupiter, seed=44)
    plate("bg_mars.png", (40, 18, 12), (124, 52, 32), (70, 28, 18), (208, 110, 70), (120, 56, 36), d_mars, seed=55)
    plate("bg_earth.png", (8, 20, 44), (22, 62, 120), (10, 30, 66), (90, 160, 220), (40, 90, 150), d_earth, seed=66)
    plate("bg_venus.png", (60, 48, 20), (170, 140, 80), (110, 88, 46), (240, 214, 150), (170, 140, 84), d_venus, seed=77)
    plate("bg_mercury.png", (18, 18, 24), (70, 68, 76), (36, 34, 42), (168, 164, 172), (96, 92, 102), d_mercury, seed=88)
    plate("bg_sun.png", (60, 20, 8), (190, 80, 20), (120, 44, 12), (255, 214, 120), (255, 150, 60), d_sun, y=0.92, seed=99)
    plate("bg_hideout.png", (6, 5, 12), (16, 12, 28), (8, 6, 16), (46, 34, 78), (24, 18, 44), d_hideout, seed=111)

# ---------------------------------------------------------------------------
# PART 5 - PROJECTILES / VFX / ITEMS
# ---------------------------------------------------------------------------

def bolt(w, h, col, hot=(255, 255, 255, 240), name="bolt.png", cap=True):
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    W, H = im.size
    ell(d, W / 2, H / 2, W / 2, H / 2, col)
    m = Image.new("RGBA", im.size, (0, 0, 0, 0))
    dm = ImageDraw.Draw(m)
    dm.rectangle([0, int(H * 0.18), W, int(H * 0.82)], fill=col)
    im = Image.alpha_composite(im, m)
    dd = ImageDraw.Draw(im)
    dd.ellipse([W * 0.30, H * 0.34, W * 0.70, H * 0.66], fill=hot)
    if cap:
        tri = Image.new("RGBA", im.size, (0, 0, 0, 0))
        dt = ImageDraw.Draw(tri)
        V(dt, [(W * 0.18, 0), (W * 0.82, 0), (W * 0.5, -1)], (0, 0, 0, 0))
    finish_body(im, w, h, name, oc="#00000000", ow=0)

def part5():
    print("projectiles / vfx / items:")
    bolt(12, 30, C("#c86bff"), name="ebolt.png")               # enemy bolt (alien violet)
    bolt(22, 22, C("#57a8ff"), name="w_azure.png")            # blue small ball
    bolt(14, 34, C("#ff5a3c"), name="w_ember.png")             # red beam bolt
    bolt(18, 30, C("#57e87a"), name="w_verdant.png")           # green snake segment
    bolt(8, 20, C("#ffd7a0"), name="w_phantom.png")            # MG bullet
    # veteran sound arc: a thick open ring
    im = canvas(44, 44); d = ImageDraw.Draw(im)
    d.arc([2, 2, 86, 86], 290, 70, fill=C("#ff3b3b"), width=14)
    d.arc([14, 14, 74, 74], 300, 60, fill=C("#ffdada"), width=7)
    finish_body(finish(im, 44, 44), 44, 44, "w_veteran.png", oc="#00000000", ow=0)
    # hornet fire puff
    im = canvas(28, 28); d = ImageDraw.Draw(im)
    ell(d, 56, 56, 50, 50, C("#ff8c3a", 235)); ell(d, 52, 52, 30, 30, C("#ffd05e"))
    finish_body(finish(im, 28, 28), 28, 28, "w_hornet.png", oc="#00000000", ow=0)
    # titan missile
    im = canvas(20, 44); d = ImageDraw.Draw(im)
    W, H = im.size
    d.rounded_rectangle([W*0.28, H*0.22, W*0.72, H*0.92], radius=6, fill=C("#c8c8d2"))
    V(d, [(W*0.28, H*0.24), (W*0.5, H*0.04), (W*0.72, H*0.24)], C("#e84848"))
    d.rectangle([W*0.16, H*0.66, W*0.30, H*0.92], fill=C("#9c3030"))
    d.rectangle([W*0.70, H*0.66, W*0.84, H*0.92], fill=C("#9c3030"))
    d.ellipse([W*0.38, H*0.88, W*0.62, H*1.06], fill=C("#ffb14d"))
    finish_body(im, 20, 44, "w_titan.png")
    # thunder beam segment (vertical electric rail)
    im = canvas(26, 80); d = ImageDraw.Draw(im)
    W, H = im.size
    rng = random.Random(4)
    for _ in range(5):
        x0 = rng.uniform(W*0.3, W*0.7); y0 = rng.uniform(0, H*0.8)
        x1 = x0 + rng.uniform(-W*0.3, W*0.3); y1 = y0 + rng.uniform(8, H*0.2)
        d.line([(x0, y0), (x1, y1)], fill=C("#9fe8ff"), width=4)
    d.line([(W*0.5, 0), (W*0.5, H)], fill=C("#e8f8ff"), width=3)
    im = glow_layers(finish(im, 26, 80), C("#57c8ff", 180), 6, 0.9)
    im.save(os.path.join(OUT, "fx_thunder.png")); print("  wrote fx_thunder.png")
    # bomb (contact fuse - no fuse spark, the owner's law)
    im = canvas(24, 46); d = ImageDraw.Draw(im)
    W, H = im.size
    ell(d, W/2, H*0.62, W*0.42, H*0.34, C("#2e3440"))
    ell(d, W*0.38, H*0.54, W*0.14, H*0.10, C("#4c566a"))
    d.rectangle([W*0.42, H*0.16, W*0.58, H*0.34], fill=C("#8f3030"))
    d.ellipse([W*0.42, H*0.06, W*0.58, H*0.20], fill=C("#e8c14d"))
    finish_body(im, 24, 46, "bomb.png")
    # impact ring / spark / burn / trail / hit flash
    im = canvas(64, 64); d = ImageDraw.Draw(im)
    d.ellipse([8, 8, 120, 120], outline=C("#ffffff", 200), width=10)
    finish_body(finish(im, 64, 64), 64, 64, "fx_ring.png", oc="#00000000", ow=0)
    im = canvas(24, 24); d = ImageDraw.Draw(im)
    d.line([(6, 44), (50, 50)], fill=C("#ffe9a0"), width=6)
    d.line([(44, 6), (50, 50)], fill=C("#ffe9a0"), width=6)
    finish_body(finish(im, 24, 24), 24, 24, "fx_spark.png", oc="#00000000", ow=0)
    im = canvas(48, 48); d = ImageDraw.Draw(im)
    ell(d, 96, 96, 84, 84, C("#101014", 130))
    finish_body(finish(im, 48, 48), 48, 48, "fx_burn.png", oc="#00000000", ow=0)
    im = canvas(32, 32); d = ImageDraw.Draw(im)
    for r, a in ((14, 90), (10, 150), (6, 220)):
        ell(d, 64, 64, r*4, r*4, C("#ffffff", a))
    finish_body(finish(im, 32, 32), 32, 32, "fx_trail.png", oc="#00000000", ow=0)
    im = canvas(36, 36); d = ImageDraw.Draw(im)
    V(d, [(64, 4), (78, 50), (124, 64), (78, 78), (64, 124), (50, 78), (4, 64), (50, 50)], C("#fff2c0", 230))
    finish_body(finish(im, 36, 36), 36, 36, "fx_hit.png", oc="#00000000", ow=0)
    # item icons: the 7 weapon glyphs + power core + thunder + bomb
    def icon(name, painter):
        im = canvas(36, 36); d = ImageDraw.Draw(im)
        painter(d, im)
        r = 76
        d.rounded_rectangle([4, 4, 140, 140], radius=r, outline=C("#2b3540"), width=6)
        finish_body(finish(im, 36, 36), 36, 36, name)
    def ip_azure(d, im):
        for fx, fy in ((0.35, 0.5), (0.65, 0.35), (0.65, 0.65)):
            ell(d, 144*fx, 144*fy, 16, 16, C("#57a8ff"))
    def ip_ember(d, im):
        d.rectangle([64, 30, 80, 114], fill=C("#ff5a3c"))
        V(d, [(64, 30), (80, 30), (72, 10)], C("#ff8c70"))
    def ip_verdant(d, im):
        pts = [(40, 110), (60, 70), (50, 40), (84, 60), (104, 34)]
        for i in range(len(pts) - 1):
            d.line([pts[i], pts[i+1]], fill=C("#57e87a"), width=9)
    def ip_veteran(d, im):
        d.arc([20, 20, 124, 124], 300, 60, fill=C("#ff4d4d"), width=10)
    def ip_phantom(d, im):
        for i in range(4):
            d.rectangle([40 + i*18, 44, 52 + i*18, 100], fill=C("#ffd7a0"))
    def ip_hornet(d, im):
        ell(d, 72, 84, 40, 40, C("#ff8c3a")); ell(d, 60, 70, 20, 20, C("#ffd05e"))
    def ip_titan(d, im):
        d.rounded_rectangle([60, 40, 84, 110], radius=8, fill=C("#c8c8d2"))
        V(d, [(60, 42), (72, 16), (84, 42)], C("#e84848"))
    def ip_power(d, im):
        V(d, [(72, 20), (88, 58), (124, 72), (88, 86), (72, 124), (56, 86), (20, 72), (56, 58)], C("#ffc14d"))
        ell(d, 72, 72, 14, 14, C("#fff2c0"))
    def ip_thunder(d, im):
        V(d, [(84, 16), (48, 80), (72, 80), (56, 128), (104, 62), (78, 62)], C("#9fe8ff"))
    def ip_bomb(d, im):
        ell(d, 68, 88, 40, 40, C("#2e3440")); d.rectangle([62, 34, 82, 52], fill=C("#8f3030"))
        d.ellipse([64, 20, 82, 38], fill=C("#e8c14d"))
    for nm, fn in (("item_w_azure.png", ip_azure), ("item_w_ember.png", ip_ember),
                   ("item_w_verdant.png", ip_verdant), ("item_w_veteran.png", ip_veteran),
                   ("item_w_phantom.png", ip_phantom), ("item_w_hornet.png", ip_hornet),
                   ("item_w_titan.png", ip_titan), ("item_power.png", ip_power),
                   ("item_thunder.png", ip_thunder), ("item_bomb.png", ip_bomb)):
        icon(nm, fn)

# ---------------------------------------------------------------------------

if __name__ == "__main__":
    print("v0.3.2 SPACE INVADERS art pass ->", OUT)
    crew_ships()
    for f in (enemy_grunt, enemy_swift, enemy_aimer, enemy_diver, enemy_tank, enemy_split,
              enemy_weaver, enemy_spit, enemy_brute, enemy_magma, enemy_void):
        f()
    for f in (boss_triton, boss_monarch, boss_duke, boss_storm, boss_reaver,
              boss_mimic, boss_ash, boss_eater, boss_herald, boss_invader):
        f()
    planet_plates()
    part5()
    print("done:", len(os.listdir(OUT)), "files")
