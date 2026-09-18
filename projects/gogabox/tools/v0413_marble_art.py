#!/usr/bin/env python3
"""
v0413 MARBLE POPPER ART FORGE (part 1: sprites)
Cuts + code-modifies the scraped gamesnacks assets into our own
`projects/gogabox/assets/games/marble/` art set:
  - marble_{c}_{s}.png   7 colors x 6 styles (the 5 marble skins + classic)
  - shooter_{s}.png      6 launcher skins (classic + 5) - totem head regrades
  - shooter_base.png     the stand
  - hole_{s}.png         6 idol mouth skins (top+bottom in one sheet, 2 frames)
  - pow_{k}.png          6 powerup glyphs (back/bomb/speed/vapor/rainbow/lightning)
  - fx_pop_XX.png        pop burst frames
  - fx_ring_XX.png       cascade ring frames
  - arrow.png            path preview arrow
Every cut sprite gets: 2x lanczos upscale + our dark outline + gloss law
(the GogaBox look - see the v0411 worm OURS forge for the style roots).
"""
import json, os, re
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

SRC = "/home/z/my-project/gogabox/study_locker/gamesnacks/totemia/site"
DST = "/home/z/my-project/gogabox/projects/gogabox/assets/games/marble"
os.makedirs(DST, exist_ok=True)

d = json.load(open(SRC + "/img/game.json", encoding="utf-8-sig"))
frames = d["frames"] if isinstance(d["frames"], dict) else {f["filename"]: f for f in d["frames"]}
atlas = Image.open(SRC + "/img/game.png").convert("RGBA")

OUTLINE = (24, 18, 28, 255)  # the gogabox dark outline


def cut(name):
    f = frames[name]["frame"]
    return atlas.crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"]))


def outline_sprite(im, width=2, alpha_floor=110):
    """GogaBox outline: dilate alpha, paint dark rim under the sprite."""
    a = im.split()[3].point(lambda v: 255 if v >= alpha_floor else 0)
    ring = a.filter(ImageFilter.MaxFilter(width * 2 + 1))
    base = Image.new("RGBA", im.size, OUTLINE)
    base.putalpha(ring)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.alpha_composite(base)
    out.alpha_composite(im)
    return out


def gloss(im, strength=0.16, y0=0.12, y1=0.46):
    """Bake a soft top-left gloss band (the marble/launcher law)."""
    w, h = im.size
    g = Image.new("L", im.size, 0)
    dr = ImageDraw.Draw(g)
    dr.ellipse((w * 0.16, h * y0, w * 0.84, h * y1), fill=90)
    g = g.filter(ImageFilter.GaussianBlur(w * 0.09))
    white = Image.new("RGBA", im.size, (255, 255, 255, int(255 * strength)))
    white.putalpha(g.point(lambda v: int(v * strength / 0.35)))
    out = im.copy()
    out.alpha_composite(white)
    return out


def regrade(im, hue_shift=0.0, sat=1.0, val=1.0, contrast=1.0):
    import colorsys
    im = im.convert("RGBA")
    a = im.split()[3]
    rgb = im.convert("RGB")
    if hue_shift != 0.0:
        px = rgb.load()
        for y in range(rgb.height):
            for x in range(rgb.width):
                r, g, b = px[x, y]
                hh, ss, vv = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
                hh = (hh + hue_shift) % 1.0
                px[x, y] = tuple(int(c * 255) for c in colorsys.hsv_to_rgb(hh, ss, vv))
    rgb = ImageEnhance.Color(rgb).enhance(sat)
    rgb = ImageEnhance.Brightness(rgb).enhance(val)
    rgb = ImageEnhance.Contrast(rgb).enhance(contrast)
    out = rgb.convert("RGBA")
    out.putalpha(a)
    return out


# ---------------------------------------------------------------- marbles
# frame name law: ball<color><4-digit index> - index 0..43; style groups are
# 8 rolling frames starting at 0 (silver/purple/yellow) or 4 (blue/green/cyan/red)
COLORS = [1, 2, 3, 4, 5, 6, 7]
STYLE_STARTS = {1: [4, 12, 20, 28, 36], 2: [0, 8, 16, 24, 32, 40], 3: [4, 12, 20, 28, 36],
                4: [0, 8, 16, 24, 32, 40], 5: [4, 12, 20, 28, 36], 6: [0, 8, 16, 24, 32, 40],
                7: [4, 12, 20, 28, 36]}
made = 0
for c in COLORS:
    for s, base in enumerate(STYLE_STARTS[c]):
        n = f"ball{c}{base:04d}"
        if n not in frames:
            continue
        im = cut(n).resize((96, 96), Image.LANCZOS)
        im = outline_sprite(im, 2)
        im = gloss(im, 0.20)
        im.save(f"{DST}/marble_{c}_{s}.png")
        made += 1
print("marbles:", made)

# ---------------------------------------------------------------- shooter
head = cut("cannonTop0000")  # ~100px totem head
base = cut("cannonBot0000")
SHOOTER_SKINS = [
    ("classic", dict(sat=1.0, val=1.0)),
    ("jade", dict(hue_shift=0.30, sat=1.05, val=1.02)),
    ("obsidian", dict(sat=0.35, val=0.62, contrast=1.18)),
    ("royal", dict(hue_shift=0.62, sat=1.1, val=1.0)),
    ("gold", dict(hue_shift=0.13, sat=1.25, val=1.12)),
    ("crimson", dict(hue_shift=0.94, sat=1.15, val=1.02)),
]
hw, hh = head.size
head2 = head.resize((hw * 2, hh * 2), Image.LANCZOS)
for name, kw in SHOOTER_SKINS:
    h = regrade(head2, **kw)
    h = outline_sprite(h, 2)
    h = gloss(h, 0.14)
    h.save(f"{DST}/shooter_{name}.png")
b2 = base.resize((base.width * 2, base.height * 2), Image.LANCZOS)
outline_sprite(b2, 2).save(f"{DST}/shooter_base.png")
print("shooters:", len(SHOOTER_SKINS) + 1)

# ---------------------------------------------------------------- hole (idol)
dt = cut("daemonTop0000")
db = cut("daemonBot0000")
HOLE_SKINS = [
    ("classic", dict(sat=1.0, val=1.0)),
    ("coral", dict(hue_shift=0.02, sat=1.2, val=1.06)),
    ("gold", dict(hue_shift=0.12, sat=1.15, val=1.1)),
    ("shadow", dict(sat=0.4, val=0.55, contrast=1.2)),
    ("soul", dict(hue_shift=0.55, sat=1.3, val=0.95)),
    ("venom", dict(hue_shift=0.38, sat=1.2, val=1.0)),
]
sheet = Image.new("RGBA", (max(dt.width, db.width) * 2, (dt.height + db.height + 4) * 2), (0, 0, 0, 0))
dt2 = dt.resize((dt.width * 2, dt.height * 2), Image.LANCZOS)
db2 = db.resize((db.width * 2, db.height * 2), Image.LANCZOS)
for name, kw in HOLE_SKINS:
    t = outline_sprite(regrade(dt2, **kw), 2)
    b = outline_sprite(regrade(db2, **kw), 2)
    sh = Image.new("RGBA", (max(t.width, b.width), t.height + b.height + 6), (0, 0, 0, 0))
    sh.alpha_composite(t, ((sh.width - t.width) // 2, 0))
    sh.alpha_composite(b, ((sh.width - b.width) // 2, t.height + 6))
    sh.save(f"{DST}/hole_{name}.png")
print("holes:", len(HOLE_SKINS))

# ---------------------------------------------------------------- fx
os.makedirs(f"{DST}/fx", exist_ok=True)
pops = sorted([n for n in frames if re.match(r"^ballExplosion\d+0000$", n)])
print("pop variants:", len(pops))
for i, n in enumerate(sorted([x for x in frames if re.match(r"^ballExplosion[0-9]+", x)])):
    pass
# one variant, 12 frames
variant = sorted([n for n in frames if re.match(r"^ballExplosion\d+", n)],
                 key=lambda x: int(re.findall(r"\d+", x)[0]))
variant = [n for n in variant if n.startswith("ballExplosion1")]
for i, n in enumerate(variant[:12]):
    f = frames[n]["frame"]
    c = atlas.crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"]))
    c = c.resize((c.width, c.height), Image.LANCZOS)
    c.save(f"{DST}/fx/fx_pop_{i:02d}.png")
print("pop frames:", min(12, len(variant)))

rings = sorted([n for n in frames if re.match(r"^gapBonus\d+", n)])
for i, n in enumerate(rings[:8]):
    f = frames[n]["frame"]
    c = atlas.crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"]))
    c.save(f"{DST}/fx/fx_ring_{i:02d}.png")
print("ring frames:", min(8, len(rings)))

# arrow
arw = cut("pathArrow0000")
arw = outline_sprite(arw.resize((arw.width * 2, arw.height * 2), Image.LANCZOS), 2)
arw.save(f"{DST}/arrow.png")

# ---------------------------------------------------------------- power glyphs
def glyph(kind, size=96):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    dr = ImageDraw.Draw(im)
    w = size
    L, R, T, B = w * 0.16, w * 0.84, w * 0.16, w * 0.84
    lw = max(6, int(w * 0.10))
    col = (255, 255, 255, 255)
    if kind == "back":  # double wind arrow pointing back
        for off in (0.0, 0.30):
            dr.line((L, T + (B - T) * (0.28 + off), R - w * 0.22, T + (B - T) * (0.28 + off)), fill=col, width=lw)
            dr.line((R - w * 0.22, T + (B - T) * (0.28 + off), R - w * 0.34, T + (B - T) * (0.16 + off)), fill=col, width=lw)
            dr.line((R - w * 0.22, T + (B - T) * (0.28 + off), R - w * 0.34, T + (B - T) * (0.40 + off)), fill=col, width=lw)
    elif kind == "bomb":
        dr.ellipse((L + w * 0.08, T + w * 0.16, R - w * 0.06, B), fill=col)
        dr.line((w * 0.60, T + w * 0.16, w * 0.74, T), fill=col, width=lw)
        dr.ellipse((w * 0.70, T - w * 0.10, w * 0.82, T + w * 0.02), fill=col)
    elif kind == "speed":
        for off in (0.0, 0.26):
            dr.polygon([(L + w * 0.04 * off, T + (B - T) * off * 0.4),
                        (R * 0.72, T + (B - T) * (0.5 + off * 0.8)),
                        (L, B - (B - T) * off * 0.4)], fill=col)
        dr.polygon([(w * 0.5, T), (R, T + (B - T) * 0.5), (w * 0.5, B)], fill=col)
    elif kind == "vapor":
        for cy, r in ((0.42, 0.16), (0.34, 0.20), (0.55, 0.24), (0.66, 0.15)):
            dr.ellipse((w * (0.5 - r), w * cy - w * r, w * (0.5 + r), w * cy + w * r), fill=col)
        dr.rectangle((w * 0.28, w * 0.58, w * 0.72, B), fill=col)
    elif kind == "rainbow":
        for i, ccol in enumerate([(235, 60, 60), (245, 170, 40), (90, 200, 80), (70, 130, 235), (150, 80, 220)]):
            rr = w * (0.42 - i * 0.055)
            dr.arc((w * 0.5 - rr, w * 0.5 - rr, w * 0.5 + rr, w * 0.5 + rr), 180, 360,
                   fill=ccol + (255,), width=lw)
        dr.rectangle((w * 0.10, w * 0.5 - 1, w * 0.90, w * 0.5 + lw), fill=(0, 0, 0, 0))
    elif kind == "lightning":
        dr.polygon([(w * 0.58, T), (L + w * 0.06, w * 0.58), (w * 0.48, w * 0.58),
                    (w * 0.40, B), (R - w * 0.06, w * 0.44), (w * 0.54, w * 0.44)], fill=col)
    return im


POWS = ["back", "bomb", "speed", "vapor", "rainbow", "lightning"]
POW_TINT = {"back": (90, 160, 255), "bomb": (255, 120, 80), "speed": (255, 210, 70),
            "vapor": (170, 130, 255), "rainbow": (255, 255, 255), "lightning": (120, 220, 255)}
for k in POWS:
    g = glyph(k)
    tint = Image.new("RGBA", g.size, POW_TINT[k] + (255,))
    tinted = Image.composite(tint, Image.new("RGBA", g.size, (0, 0, 0, 0)), g.split()[3])
    tinted.putalpha(g.split()[3])
    tinted = outline_sprite(tinted, 2, 90)
    tinted.save(f"{DST}/pow_{k}.png")
print("pows:", len(POWS))
print("ART FORGE 1 DONE ->", DST)

# ---------------------------------------------------------------- hole jaws (separate, for the chew anim)
for name, kw in HOLE_SKINS:
    t = outline_sprite(regrade(dt2, **kw), 2)
    b = outline_sprite(regrade(db2, **kw), 2)
    t.save(f"{DST}/hole_{name}_top.png")
    b.save(f"{DST}/hole_{name}_bot.png")
print("hole jaws:", len(HOLE_SKINS) * 2)
