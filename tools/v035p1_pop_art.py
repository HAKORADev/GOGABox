#!/usr/bin/env python3
"""v0.3.5-1 POP SIEGE - THE REAL ART PATCH.

Sources (the owner's directive):
  A. the uploaded GameMaker TD template (Towers vs Monsters kit)
  B. the Gamesnacks Endless Siege web atlases (game CDN, 900 unique frames)
  C. PIL recomposition - every piece RECOLORED / RECOMPOSED into the GOGA
     identity, never a 1:1 clone (the manifest documents provenance).

Writes into projects/gogabox/assets/games/pop_siege/:
  folk/{fid}_g{1..3}.png + _head_g{1..3}.png + _base.png + _face.png
  bloons/{kind}.png (13 kinds + ceramic cracks)
  fx/ (projectiles, pop/boom/flame/bolt/snow/teleport frames, ring, shadow)
  props/ (the obstacle library the map generator references)
  ui/ (popcoin, heart, next_wave, speed chips, auto/manual, icons, badges)
"""
import json, math, os, shutil
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageEnhance

REPO = "/home/z/my-project/repo/GOGABox"
OUT = f"{REPO}/projects/gogabox/assets/games/pop_siege"
ES = "/home/z/my-project/work/es_frames"
TM = "/home/z/my-project/work/td_template/sprites"
FONT = f"{REPO}/projects/gogabox/assets/fonts/Kenney_Rocket.ttf"

# ---------------------------------------------------------------- helpers

def es(name):
    p = f"{ES}/{name}.png"
    if not os.path.exists(p):
        # zero-padded sequence fallback (plasma_9 -> plasma_09)
        if "_" in name:
            head, tail = name.rsplit("_", 1)
            if tail.isdigit():
                p2 = f"{ES}/{head}_{int(tail):02d}.png"
                if os.path.exists(p2):
                    p = p2
    return Image.open(p).convert("RGBA")

def tm(name):
    """the template keeps sprites under GUID dirs - pick the largest png."""
    d = f"{TM}/spr_{name}"
    best = None
    for root, _, files in os.walk(d):
        for f in files:
            if f.endswith(".png") and "/layers/" not in root.replace(os.sep, "/"):
                p = os.path.join(root, f)
                im = Image.open(p)
                if best is None or im.width * im.height > best[0]:
                    best = (im.width * im.height, p)
    return Image.open(best[1]).convert("RGBA")

def hsv_shift(im, dh, ds=1.0, dv=1.0):
    """hue degrees, saturation mult, value mult."""
    import colorsys
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

def recolor(im, target, keep=0.35, sat=1.0, val=1.0):
    """blend the sprite toward a flat target color while keeping some of the
    original shading - the cheap 'same art, different family' wash."""
    layer = Image.new("RGBA", im.size, target)
    out = Image.blend(im, layer, 1.0 - keep)
    out.putalpha(im.split()[3])
    return hsv_shift(out, 0.0, sat, val)

def outlined(im, width=3, color=(45, 30, 20, 255)):
    """cartoon outline from the alpha hull."""
    pad = width + 1
    base = Image.new("RGBA", (im.width + pad * 2, im.height + pad * 2), (0, 0, 0, 0))
    a = im.split()[3]
    for ox in range(-width, width + 1):
        for oy in range(-width, width + 1):
            if ox * ox + oy * oy <= width * width:
                base.paste(color, (pad + ox, pad + oy), a)
    base.alpha_composite(im, (pad, pad))
    return base

def sheet_strip(name, n, step=1, start=0):
    """grab n frames of an ES sequence."""
    out = []
    for i in range(n):
        idx = start + i * step
        for pad in (f"{idx:02d}", str(idx)):
            p = f"{ES}/{name}_{pad}.png"
            if os.path.exists(p):
                out.append(Image.open(p).convert("RGBA"))
                break
    return out

def save(im, rel):
    p = os.path.join(OUT, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    im.save(p)
    print("  +", rel, im.size)

def font(sz):
    return ImageFont.truetype(FONT, sz)

def text_img(txt, sz, fill=(255, 255, 255, 255), stroke=(45, 30, 20, 255), sw=None):
    f = font(sz)
    if sw is None:
        sw = max(2, sz // 9)
    bbox = f.getbbox(txt, stroke_width=sw)
    w, h = bbox[2] - bbox[0] + 8, bbox[3] - bbox[1] + 8
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.text((4 - bbox[0], 4 - bbox[1]), txt, font=f, fill=fill, stroke_width=sw, stroke_fill=stroke)
    return im

def vertical_gradient(w, h, stops):
    """stops: list of (pos0..1, (r,g,b))"""
    im = Image.new("RGB", (1, h))
    px = im.load()
    for y in range(h):
        t = y / max(1, h - 1)
        for i in range(len(stops) - 1):
            p0, c0 = stops[i]
            p1, c1 = stops[i + 1]
            if p0 <= t <= p1:
                k = (t - p0) / max(0.0001, p1 - p0)
                px[0, y] = tuple(int(c0[j] + (c1[j] - c0[j]) * k) for j in range(3))
                break
    return im.resize((w, h))

# ================================================================ THE FOLK
# 10 gadget families x 3 gears. The ES tier lines carry the free trio +
# crystal line; the rest are recomposed (recolors + drawn heads) so every
# family wears its own silhouette and every gear jumps visibly stronger.

FAM = {
    # fid: (palette hue shift, sat, val, [base sprites per gear], [head sprites per gear], head_rotates)
    "darty":   {"dh": -0.30, "ds": 1.05, "dv": 1.02,   # emerald archers
                "bases": ["archer_1_base", "archer_2_base", "archer_3_base"],
                "heads": ["archer_1_top", "archer_2_top", "archer_3_top"], "rot": True},
    "boomba":  {"dh": +0.02, "ds": 0.95, "dv": 0.95,   # bronze mortars
                "bases": ["cannon_1_base", "cannon_2_base", "cannon_3_base"],
                "heads": ["cannon_1_top_1", "cannon_2_top_1", "cannon_3_top_1"], "rot": True},
    "pyra":    {"dh": -0.04, "ds": 1.25, "dv": 1.06,   # deep ember braziers
                "wash": (255, 128, 44, 255), "keep": 0.42,
                "bases": ["fire_1_base", "fire_2_base", "fire_3_base"],
                "heads": ["fire_1_base", "fire_2_base", "fire_3_base"], "rot": False},
    "zappy":   {"dh": +0.10, "ds": 1.15, "dv": 1.10,   # electric crystals
                "bases": ["crystal_1_base", "crystal_2_base", "crystal_3_base"],
                "heads": ["crystal_1_top_01", "crystal_2_top_01", "crystal_3_top_01"], "rot": False},
    "kolda":   {"dh": +0.44, "ds": 0.55, "dv": 1.14,   # ice crystals (fancy line)
                "bases": ["crystal_upgraded_1_base", "crystal_upgraded_2_base", "crystal_upgraded_3_base"],
                "heads": ["crystal_2_top_01", "crystal_3_top_01", "crystal_3_top_01"], "rot": False},
    "gloop":   {"dh": -0.42, "ds": 1.20, "dv": 0.92,   # toxic cauldrons
                "wash": (150, 214, 64, 255), "keep": 0.45,
                "bases": ["cannon_upgraded_1_base", "cannon_upgraded_2_base", "cannon_upgraded_3_base"],
                "heads": ["cannon_1_top_1", "cannon_2_top_1", "cannon_3_top_1"], "rot": False},
    "longeye": {"dh": +0.52, "ds": 0.30, "dv": 0.72,   # gunmetal ballista
                "bases": ["archer_upgraded_1_base", "archer_upgraded_2_base", "archer_upgraded_3_base"],
                "heads": ["archer_3_top", "archer_3_top", "archer_3_top"], "rot": True},
    "boomo":   {"dh": +0.62, "ds": 1.10, "dv": 1.00,   # violet orb throwers
                "wash": (176, 116, 244, 255), "keep": 0.42,
                "bases": ["fire_upgraded_1_base", "fire_upgraded_2_base", "fire_upgraded_3_base"],
                "heads": ["fire_2_base", "fire_3_base", "fire_upgraded_3_base"], "rot": False},
    "marshal": {"dh": -0.75, "ds": 1.05, "dv": 0.98,   # crimson drums
                "bases": ["archer_upgraded_1_base", "archer_upgraded_2_base", "archer_upgraded_3_base"],
                "heads": ["DRAW_DRUM", "DRAW_DRUM", "DRAW_DRUM"], "rot": False},
    "kaching": {"dh": +0.13, "ds": 1.30, "dv": 1.12,   # golden banks
                "bases": ["archer_upgraded_1_base", "archer_upgraded_2_base", "archer_upgraded_3_base"],
                "heads": ["DRAW_VAULT", "DRAW_VAULT", "DRAW_VAULT"], "rot": False},
}

def pad_to(im, w, h):
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.alpha_composite(im, ((w - im.width) // 2, (h - im.height) // 2))
    return out

def draw_drum(gear):
    """marshal head: a war drum on a stand with a banner."""
    S = 3
    w, h = 68 * S, 62 * S
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    ink = (60, 22, 22, 255)
    body = [(196, 52 + gear * 6, 62, 255), (232, 92 + gear * 8, 84, 255)]
    # drum shell
    d.ellipse([8 * S, 22 * S, 60 * S, 58 * S], fill=body[0], outline=ink, width=2 * S)
    d.rectangle([8 * S, 30 * S, 60 * S, 46 * S], fill=body[1])
    d.ellipse([8 * S, 22 * S, 60 * S, 40 * S], fill=(244, 226, 198, 255), outline=ink, width=2 * S)
    # laces
    for i in range(4):
        x = (12 + i * 12) * S
        d.line([x, 30 * S, x, 52 * S], fill=ink, width=S)
    # drum sticks
    d.line([16 * S, 14 * S, 40 * S, 30 * S], fill=(120, 78, 40, 255), width=3 * S)
    d.line([52 * S, 14 * S, 28 * S, 30 * S], fill=(120, 78, 40, 255), width=3 * S)
    d.ellipse([12 * S, 8 * S, 22 * S, 18 * S], fill=(244, 226, 198, 255), outline=ink, width=S)
    d.ellipse([46 * S, 8 * S, 56 * S, 18 * S], fill=(244, 226, 198, 255), outline=ink, width=S)
    # banner
    bx = (34 + gear * 4) * S
    d.line([bx, 2 * S, bx, 26 * S], fill=ink, width=S)
    d.polygon([(bx, 3 * S), (bx + 20 * S, 7 * S), (bx, 13 * S)], fill=(232, 92, 84, 255), outline=ink)
    im = im.resize((w // S, h // S), Image.LANCZOS)
    return outlined(im, 2)

def draw_vault(gear):
    """kaching head: a coin safe stacked with gold."""
    S = 3
    w, h = 70 * S, 62 * S
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    ink = (96, 64, 8, 255)
    gold = (250, 190, 40, 255)
    gold_hi = (255, 226, 120, 255)
    # coin stack grows with gear
    for c in range(gear + 1):
        y = (48 - c * 9) * S
        d.ellipse([14 * S, y, 56 * S, y + 12 * S], fill=gold, outline=ink, width=S)
        d.ellipse([20 * S, y + 2 * S, 50 * S, y + 10 * S], outline=(216, 150, 20, 255), width=S)
    # the vault gem
    d.rounded_rectangle([24 * S, 8 * S, 46 * S, 30 * S], 6 * S, fill=gold_hi, outline=ink, width=2 * S)
    d.ellipse([30 * S, 13 * S, 40 * S, 23 * S], fill=(255, 244, 180, 255), outline=ink, width=S)
    d.line([35 * S, 14 * S, 35 * S, 22 * S], fill=ink, width=S)
    im = im.resize((w // S, h // S), Image.LANCZOS)
    return outlined(im, 2)

def scope_up(head, gear):
    """longeye: bolt a longer dark barrel + scope onto the ballista head."""
    S = 2
    add = Image.new("RGBA", (head.width + 30, head.height + 14), (0, 0, 0, 0))
    add.alpha_composite(head, (0, 6))
    d = ImageDraw.Draw(add)
    ink = (30, 32, 40, 255)
    # long barrel to the right
    y = add.height // 2
    d.rounded_rectangle([head.width - 8, y - 5 - gear, head.width + 26 + gear * 4, y + 5 + gear],
                        4, fill=(70, 74, 88, 255), outline=ink, width=2)
    if gear >= 2:
        d.ellipse([head.width + 2, y - 12, head.width + 14, y], fill=(90, 200, 250, 255), outline=ink, width=2)
    if gear >= 3:
        d.line([head.width - 4, y + 8 + gear, head.width + 24 + gear * 4, y + 8 + gear], fill=(255, 210, 60, 255), width=3)
    return add

def build_folk():
    print("== folk ==")
    for fid, cfg in FAM.items():
        for gear in (1, 2, 3):
            base = es(cfg["bases"][gear - 1])
            hn = cfg["heads"][gear - 1]
            if hn == "DRAW_DRUM":
                head = draw_drum(gear)
            elif hn == "DRAW_VAULT":
                head = draw_vault(gear)
            else:
                for cand in (hn, hn.rsplit("_", 1)[0], hn + "_1", hn + "_01"):
                    try:
                        head = es(cand)
                        break
                    except Exception:
                        continue
                head = hsv_shift(head, cfg["dh"], cfg["ds"], cfg["dv"])
            if cfg.get("wash"):
                head = hsv_shift(recolor(head, cfg["wash"], cfg.get("keep", 0.42)), cfg["dh"], 1.12, 1.05)
            if fid == "longeye":
                head = scope_up(head, gear)
            base_s = hsv_shift(base, cfg["dh"], cfg["ds"] * 0.8, cfg["dv"])
            if cfg.get("wash"):
                base_s = hsv_shift(recolor(base_s, cfg["wash"], cfg.get("keep", 0.42) * 0.8), cfg["dh"], 1.12, 1.05)
            # gear shine: gold trim dot for g2+, glow ring for g3
            if gear >= 2:
                d = ImageDraw.Draw(base_s)
                d.ellipse([base_s.width // 2 - 4, 2, base_s.width // 2 + 4, 10], fill=(255, 214, 90, 255))
            W = max(base_s.width, head.width) + 8
            H = base_s.height + head.height + 2
            full = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            full.alpha_composite(base_s, ((W - base_s.width) // 2, H - base_s.height))
            full.alpha_composite(head, ((W - head.width) // 2, max(0, H - base_s.height - head.height + 2)))
            save(full, f"folk/{fid}_g{gear}.png")
            save(head, f"folk/{fid}_head_g{gear}.png")
        save(base_s, f"folk/{fid}_base.png")
        # face chip: the g1 head circle-cropped
        f0 = Image.open(f"{OUT}/folk/{fid}_head_g1.png").convert("RGBA")
        side = min(f0.width, f0.height)
        f0 = pad_to(f0, side, side)
        mask = Image.new("L", (side * 4, side * 4), 0)
        ImageDraw.Draw(mask).ellipse([8, 8, side * 4 - 8, side * 4 - 8], fill=255)
        mask = mask.resize((side, side), Image.LANCZOS)
        chip = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        chip.paste(f0, (0, 0), mask)
        ring = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        ImageDraw.Draw(ring).ellipse([1, 1, side - 2, side - 2], outline=(45, 30, 20, 255), width=max(2, side // 24))
        chip.alpha_composite(ring)
        save(chip, f"folk/{fid}_face.png")

# ================================================================ BLOONS
# the full glossy roster, drawn (13 kinds + ceramic cracks). Every kind keeps
# its BTD truth: the color ladder, the immunities look, the two blimps.

def balloon(kind, body, hi, r=46, sq=1.0, detail=None):
    """glossy balloon: radial body + rim + knot + double shine."""
    S = 2
    w, h = int((r * 2 + 26) * S), int((r * 2 + 44) * S)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = w // 2, 8 * S + r * S
    rx, ry = int(r * S), int(r * sq * S)
    ink = tuple(max(0, c - 95) for c in body) + (255,)
    # body with vertical gradient (light top -> deep bottom)
    grad = vertical_gradient(rx * 2, ry * 2, [(0.0, hi), (0.55, body), (1.0, tuple(max(0, c - 40) for c in body))])
    mask = Image.new("L", (rx * 2, ry * 2), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, rx * 2 - 1, ry * 2 - 1], fill=255)
    im.paste(grad, (cx - rx, cy - ry), mask)
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], outline=ink, width=2 * S)
    if detail:
        detail(d, im, cx, cy, rx, ry, S)
    # the shine: soft blob + hard dot
    shine = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shine)
    sd.ellipse([cx - rx * 0.52, cy - ry * 0.72, cx - rx * 0.05, cy - ry * 0.18], fill=(255, 255, 255, 130))
    shine = shine.filter(ImageFilter.GaussianBlur(3 * S))
    im.alpha_composite(shine)
    d.ellipse([cx - rx * 0.42, cy - ry * 0.62, cx - rx * 0.18, cy - ry * 0.38], fill=(255, 255, 255, 220))
    # the knot
    ky = cy + ry - 2 * S
    d.polygon([(cx - 5 * S, ky), (cx + 5 * S, ky), (cx, ky + 9 * S)], fill=body, outline=ink)
    return im.resize((w // S, h // S), Image.LANCZOS)

def zebra_detail(d, im, cx, cy, rx, ry, S):
    stripe = Image.new("RGBA", im.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(stripe)
    for i in range(-4, 5):
        sd.line([cx + rx - 4, cy + i * ry // 3 - ry, cx - rx + 4, cy + i * ry // 3 + ry // 2],
                fill=(34, 34, 40, 235), width=7 * S)
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).ellipse([cx - rx + 2, cy - ry + 2, cx + rx - 2, cy + ry - 2], fill=255)
    im.paste(stripe, (0, 0), Image.composite(stripe.split()[3], Image.new("L", im.size, 0), mask))

def lead_detail(d, im, cx, cy, rx, ry, S):
    metal = vertical_gradient(rx * 2, ry * 2, [(0.0, (190, 198, 210)), (0.5, (120, 128, 142)), (1.0, (66, 72, 84))])
    mask = Image.new("L", (rx * 2, ry * 2), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, rx * 2 - 1, ry * 2 - 1], fill=255)
    im.paste(metal, (cx - rx, cy - ry), mask)
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], outline=(40, 44, 52, 255), width=2 * S)
    for i in range(6):
        a = math.pi * i / 5.0
        px, py = cx + int(rx * 0.62 * math.cos(a)), cy + int(ry * 0.62 * math.sin(a))
        d.ellipse([px - 2 * S, py - 2 * S, px + 2 * S, py + 2 * S], fill=(52, 58, 68, 255))

def rainbow_detail(d, im, cx, cy, rx, ry, S):
    bands = [(232, 74, 74), (240, 150, 60), (244, 214, 70), (110, 200, 90), (80, 150, 235), (150, 100, 220)]
    bh = (2 * ry) // len(bands)
    mask = Image.new("L", (rx * 2, ry * 2), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, rx * 2 - 1, ry * 2 - 1], fill=255)
    band_im = Image.new("RGBA", (rx * 2, ry * 2), (0, 0, 0, 0))
    bd = ImageDraw.Draw(band_im)
    for i, c in enumerate(bands):
        bd.rectangle([0, i * bh, rx * 2, (i + 1) * bh + 1], fill=c + (255,))
    band_im = band_im.filter(ImageFilter.GaussianBlur(2))
    im.paste(band_im, (cx - rx, cy - ry), mask)

def ceramic_detail(d, im, cx, cy, rx, ry, S, cracks=0):
    shell = vertical_gradient(rx * 2, ry * 2, [(0.0, (226, 168, 110)), (0.6, (176, 116, 64)), (1.0, (120, 74, 38))])
    mask = Image.new("L", (rx * 2, ry * 2), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, rx * 2 - 1, ry * 2 - 1], fill=255)
    im.paste(shell, (cx - rx, cy - ry), mask)
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], outline=(74, 44, 22, 255), width=2 * S)
    # plates
    d.arc([cx - rx + 4 * S, cy - ry + 4 * S, cx + rx - 4 * S, cy + ry - 4 * S], 200, 340, fill=(120, 74, 38, 255), width=2 * S)
    if cracks >= 1:
        d.line([cx - rx * 0.4, cy - ry * 0.5, cx - rx * 0.1, cy - ry * 0.1, cx - rx * 0.35, cy + ry * 0.3],
               fill=(52, 30, 14, 255), width=2 * S, joint="curve")
        d.line([cx + rx * 0.5, cy - ry * 0.3, cx + rx * 0.2, cy + ry * 0.2], fill=(52, 30, 14, 255), width=2 * S)
    if cracks >= 2:
        d.line([cx + rx * 0.1, cy - ry * 0.7, cx + rx * 0.3, cy - ry * 0.2, cx + rx * 0.05, cy + ry * 0.4],
               fill=(38, 22, 10, 255), width=3 * S, joint="curve")
        d.ellipse([cx - rx * 0.15, cy + ry * 0.05, cx + rx * 0.3, cy + ry * 0.45], outline=(38, 22, 10, 255), width=2 * S)

def blimp(name, hull, dark, accent, spikes=False):
    """the two airships: armored hull, fins, gondola, face plate."""
    S = 2
    w, h = 260 * S // 2, 170 * S // 2
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    ink = tuple(max(0, c - 80) for c in hull) + (255,)
    # hull (elongated ellipse) with gradient
    gx0, gy0, gx1, gy1 = 14, 20, w - 14, h - 44
    grad = vertical_gradient(gx1 - gx0, gy1 - gy0, [(0.0, tuple(min(255, c + 50) for c in hull)), (0.55, hull), (1.0, dark)])
    mask = Image.new("L", (gx1 - gx0, gy1 - gy0), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, gx1 - gx0 - 1, gy1 - gy0 - 1], fill=255)
    im.paste(grad, (gx0, gy0), mask)
    d.ellipse([gx0, gy0, gx1, gy1], outline=ink, width=3)
    # tail fins
    for fy, flip in [(gy0 + 6, -1), (gy1 - 22, 1)]:
        d.polygon([(gx1 - 58, gy0 + (gy1 - gy0) // 2), (gx1 + 2, fy), (gx1 - 22, gy0 + (gy1 - gy0) // 2)],
                  fill=dark, outline=ink)
    # nose plate + eyes
    d.ellipse([gx0 + 6, gy0 + (gy1 - gy0) * 0.22, gx0 + 66, gy1 - (gy1 - gy0) * 0.22], fill=accent, outline=ink, width=2)
    ex = gx0 + 26
    ey = (gy0 + gy1) // 2
    for sgn in (-1, 1):
        d.ellipse([ex - 7 + 14 * (sgn + 1) // 2, ey - 9, ex + 7 + 14 * (sgn + 1) // 2, ey + 9], fill=(250, 250, 250, 255), outline=ink, width=2)
        d.ellipse([ex - 2 + 14 * (sgn + 1) // 2, ey - 3, ex + 4 + 14 * (sgn + 1) // 2, ey + 5], fill=(30, 30, 34, 255))
    # gondola
    d.rounded_rectangle([w // 2 - 34, gy1 - 12, w // 2 + 34, gy1 + 22], 8, fill=dark, outline=ink, width=2)
    if spikes:
        for i in range(5):
            sx = gx0 + 70 + i * (gx1 - gx0 - 110) // 4
            d.polygon([(sx - 8, gy0 + 6), (sx + 8, gy0 + 6), (sx, gy0 - 12)], fill=accent, outline=ink)
    return im

def build_bloons():
    print("== bloons ==")
    kinds = {
        "red": ((226, 60, 60), (255, 140, 130)),
        "blue": ((62, 122, 226), (150, 196, 255)),
        "green": ((64, 190, 84), (160, 240, 170)),
        "yellow": ((242, 208, 40), (255, 244, 150)),
        "pink": ((242, 122, 181), (255, 196, 224)),
        "black": ((52, 52, 60), (120, 120, 132)),
        "white": ((240, 240, 246), (255, 255, 255)),
        "zebra": ((244, 244, 248), (255, 255, 255)),
    }
    for k, (body, hi) in kinds.items():
        det = zebra_detail if k == "zebra" else None
        save(balloon(k, body, hi, detail=det), f"bloons/{k}.png")
    save(balloon("lead", (150, 158, 170), (210, 216, 226), detail=lead_detail), "bloons/lead.png")
    save(balloon("rainbow", (200, 90, 220), (255, 200, 255), detail=rainbow_detail), "bloons/rainbow.png")
    save(balloon("ceramic", (190, 130, 78), (235, 190, 140), r=50, sq=1.02, detail=lambda d, im, cx, cy, rx, ry, S: ceramic_detail(d, im, cx, cy, rx, ry, S, 0)), "bloons/ceramic.png")
    save(balloon("ceramic", (190, 130, 78), (235, 190, 140), r=50, sq=1.02, detail=lambda d, im, cx, cy, rx, ry, S: ceramic_detail(d, im, cx, cy, rx, ry, S, 1)), "bloons/ceramic_c1.png")
    save(balloon("ceramic", (176, 118, 66), (225, 178, 128), r=50, sq=1.02, detail=lambda d, im, cx, cy, rx, ry, S: ceramic_detail(d, im, cx, cy, rx, ry, S, 2)), "bloons/ceramic_c2.png")
    save(blimp("moab", (96, 118, 210), (54, 66, 140), (240, 210, 90)), "bloons/moab.png")
    save(blimp("brutus", (196, 62, 56), (110, 30, 30), (250, 220, 120), spikes=True), "bloons/brutus.png")

# ================================================================ FX
def build_fx():
    print("== fx ==")
    # projectiles: the ES arrows (3 tiers), cannon shells, plasma, flame
    for i, n in enumerate(["archer_1_arrow", "archer_2_arrow", "archer_3_arrow"]):
        save(outlined(hsv_shift(es(n), -0.30, 1.05, 1.02), 2), f"fx/p_dart_g{i + 1}.png")
    save(outlined(es("granade"), 2), "fx/p_bomb.png")
    save(outlined(hsv_shift(es("cannon_3_bullet_1"), 0.0, 1.0, 1.0), 2), "fx/p_shell_g3.png")
    save(outlined(es("plasma_9"), 2), "fx/p_zap.png")
    # flame jet for pyra shots (a fire frame)
    fr = sheet_strip("fire", 24)
    save(fr[6], "fx/p_flame.png")
    # goo blob (drawn)
    goo = Image.new("RGBA", (60, 54), (0, 0, 0, 0))
    gd = ImageDraw.Draw(goo)
    gd.ellipse([4, 6, 56, 50], fill=(140, 210, 60, 255), outline=(60, 110, 24, 255), width=3)
    gd.ellipse([14, 12, 32, 26], fill=(190, 240, 120, 255))
    gd.ellipse([30, 30, 44, 42], fill=(100, 170, 40, 255))
    save(goo, "fx/p_goo.png")
    # ice shard (drawn)
    ice = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    idr = ImageDraw.Draw(ice)
    idr.polygon([(24, 2), (40, 20), (30, 46), (18, 46), (8, 20)], fill=(170, 226, 250, 240), outline=(70, 130, 180, 255))
    idr.line([24, 6, 24, 44], fill=(230, 248, 255, 255), width=3)
    save(ice, "fx/p_ice.png")
    # sniper tracer dot + golden dart
    save(es("glow"), "fx/glow.png")
    dart = outlined(hsv_shift(es("archer_3_arrow"), +0.12, 1.3, 1.15), 2)
    save(dart, "fx/p_gold_dart.png")
    # the boomerang (drawn L-shape, cartoon)
    bo = Image.new("RGBA", (56, 56), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bo)
    bd.arc([4, 4, 52, 52], 300, 180, fill=(180, 120, 250, 255), width=11)
    bd.arc([10, 10, 46, 46], 305, 175, fill=(230, 200, 255, 255), width=4)
    save(outlined(bo, 2, (60, 34, 90, 255)), "fx/p_boomerang.png")
    # POP FRAMES: red_splash recolored white (modulate tints per bloon)
    for i, fr in enumerate(sheet_strip("red_splash", 10)):
        white = Image.new("RGBA", fr.size, (255, 255, 255, 255))
        wh = Image.blend(fr.convert("RGBA"), Image.new("RGBA", fr.size, (255, 255, 255, 0)), 0.0)
        a = fr.split()[3]
        lum = fr.convert("L")
        wimg = Image.merge("RGBA", [white.split()[0], white.split()[1], white.split()[2], a])
        save(wimg, f"fx/pop_{i:02d}.png")
    # BOOM FRAMES: the ES explosion, every 4th
    for i, fr in enumerate(sheet_strip("explossion", 7, step=4)):
        save(fr, f"fx/boom_{i:02d}.png")
    # flame trap frames + aura ring + storm bolts + snow + teleport
    for i, fr in enumerate(sheet_strip("fire", 6, step=4)):
        save(fr, f"fx/trap_{i:02d}.png")
    for i, fr in enumerate(sheet_strip("bolt", 7, step=2)):
        save(fr, f"fx/bolt_{i:02d}.png")
    for i, fr in enumerate(sheet_strip("fx_snow_shoot", 6, step=3)):
        save(fr, f"fx/snow_{i:02d}.png")
    for i, fr in enumerate(sheet_strip("teleport_in", 6, step=4)):
        save(fr, f"fx/tele_{i:02d}.png")
    save(es("area_freeze"), "fx/frost.png")
    save(es("glow"), "fx/spark.png")
    save(es("smoke_particle"), "fx/smoke.png")
    # placement: template land ring + smoke
    save(tm("tower_land_ring"), "fx/land_ring.png")
    for i in (1, 2, 3):
        save(tm(f"tower_land_smoke_{i}"), f"fx/land_smoke_{i}.png")
    # soft shadow ellipse
    sh = Image.new("RGBA", (96, 40), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sh)
    sd.ellipse([4, 4, 92, 36], fill=(20, 14, 8, 120))
    sh = sh.filter(ImageFilter.GaussianBlur(4))
    save(sh, "fx/shadow.png")
    # generic ring (kept from before if exists, else drawn)
    ring = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    rd = ImageDraw.Draw(ring)
    rd.ellipse([8, 8, 120, 120], outline=(255, 255, 255, 255), width=6)
    ring = ring.filter(ImageFilter.GaussianBlur(1))
    save(ring, "fx/ring.png")
    # egg + ember + firefly for old callers (kept)
    egg = Image.new("RGBA", (40, 48), (0, 0, 0, 0))
    ed = ImageDraw.Draw(egg)
    ed.ellipse([4, 6, 36, 44], fill=(250, 214, 96, 255), outline=(160, 110, 20, 255), width=3)
    ed.ellipse([12, 14, 22, 24], fill=(255, 240, 170, 255))
    save(egg, "fx/egg.png")
    emb = Image.new("RGBA", (18, 18), (0, 0, 0, 0))
    ImageDraw.Draw(emb).ellipse([2, 2, 16, 16], fill=(255, 170, 60, 255))
    save(emb, "fx/ember.png")
    ff = Image.new("RGBA", (14, 14), (0, 0, 0, 0))
    ImageDraw.Draw(ff).ellipse([3, 3, 11, 11], fill=(255, 245, 170, 255))
    save(ff.filter(ImageFilter.GaussianBlur(1)), "fx/firefly.png")
    frag = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    ImageDraw.Draw(frag).ellipse([2, 2, 14, 14], fill=(90, 60, 30, 255))
    save(frag, "fx/frag.png")

# ================================================================ PROPS
def build_props():
    print("== props ==")
    # name -> (es frame, recolor args or None)
    P = {
        "tree_round":   ("obstacle_1", None),
        "tree_round2":  ("obstacle_2", None),
        "tree_pine":    ("obstacle_3", None),
        "tree_pine2":   ("obstacle_4", None),
        "tree_fruit":   ("obstacle_10", None),
        "tree_dead":    ("obstacle_11", None),
        "mushrooms":    ("obstacle_12", None),
        "mushroom":     ("obstacle_13", None),
        "crystal_tree": ("obstacle_14", None),
        "stump":        ("obstacle_15", None),
        "pumpkin":      ("obstacle_16", None),
        "palm":         ("obstacle_17", None),
        "palm2":        ("obstacle_18", None),
        "rocks":        ("obstacle_9", None),
        "rocks2":       ("obstacle_19", None),
        "bones":        ("obstacle_20", None),
        "tuft":         ("obstacle_21", None),
        "skull":        ("obstacle_22", None),
        "cactus":       ("obstacle_23", None),
        "log":          ("obstacle_7", None),
        "branch":       ("obstacle_6", None),
        "flowers":      ("obstacle_8", None),
        "bush":         ("obstacle_5", None),
        "bush2":        ("obstacle_30", None),
    }
    for name, (src, rc) in P.items():
        im = outlined(es(src), 2)
        save(im, f"props/{name}.png")
    # template trees + the heart house + fences
    save(outlined(tm("tree_green"), 2), "props/tree_big.png")
    save(outlined(tm("tree_blue"), 2), "props/tree_frost.png")
    save(outlined(tm("tree_bare"), 2), "props/tree_bare.png")
    save(outlined(tm("rocks"), 2), "props/stones.png")
    save(outlined(tm("house"), 2), "props/house.png")
    save(outlined(tm("grave_1"), 2), "props/grave_a.png")
    save(outlined(tm("grave_2"), 2), "props/grave_b.png")
    save(outlined(tm("tombstone"), 2), "props/tombstone.png")

# ================================================================ UI
def build_ui():
    print("== ui ==")
    # POPCOIN: the ES coin washed gold + a dark bloon imprint (the owner's law)
    coin = es("coin").resize((72, 72), Image.LANCZOS)
    coin = hsv_shift(coin, +0.07, 1.25, 1.08)
    d = ImageDraw.Draw(coin)
    d.ellipse([22, 22, 50, 52], fill=(96, 60, 16, 255), outline=(70, 42, 8, 255), width=2)
    d.line([30, 34, 26, 44], fill=(240, 200, 90, 255), width=2)
    d.line([42, 34, 46, 44], fill=(240, 200, 90, 255), width=2)
    save(coin, "ui/popcoin.png")
    # heart
    save(hsv_shift(es("lives_icon").resize((56, 56), Image.LANCZOS), 0.0, 1.4, 0.9), "ui/heart.png")
    # NEXT WAVE pill (the pink ES one) + pressed variant + gold
    nw = es("box_next_wave").resize((168, 156), Image.LANCZOS)
    save(nw, "ui/next_wave.png")
    save(es("box_next wave_gold").resize((168, 156), Image.LANCZOS), "ui/next_wave_gold.png")
    save(text_img("NEXT WAVE", 30), "ui/next_wave_txt.png")
    # speed chips X1 X2 X3 (ES) + fastforward glyphs
    for i, n in enumerate(["icon_x1", "icon_x2", "icon_x3"]):
        save(es(n), f"ui/speed_x{i + 1}.png")
    save(es("btn_fastforward"), "ui/speed_glyph.png")
    save(es("btn_normal_speed"), "ui/speed_glyph_one.png")
    # AUTO WAVES chip + a manual variant (gray wash + text)
    aw = es("btn_auto_waves").resize((150, 90), Image.LANCZOS)
    save(aw, "ui/auto_waves.png")
    man = recolor(aw, (120, 126, 138, 255), keep=0.45)
    save(man, "ui/manual_waves.png")
    # upgrade menu icons (the ES set, standardized)
    save(es("icon_damage"), "ui/ic_dmg.png")
    save(es("icon_reload"), "ui/ic_rate.png")
    save(es("icon_range"), "ui/ic_rng.png")
    save(es("icon_explossion_range"), "ui/ic_blast.png")
    save(es("icon_intensity"), "ui/ic_slow.png")
    save(es("icon_inflicted"), "ui/ic_inflicted.png")
    save(es("icon_lvl_up"), "ui/ic_up.png")
    save(es("icon_sell"), "ui/ic_sell.png")
    save(es("icon_upgrade1"), "ui/ic_next1.png")
    save(es("icon_upgrade2"), "ui/ic_next2.png")
    save(es("icon_price"), "ui/ic_price.png")
    save(es("icon_waves_1"), "ui/ic_wave.png")
    # pact badges: colored chip + symbol glyph
    badges = {
        "drum": ((232, 92, 84), "ic_wave"), "swirl": ((170, 120, 250), "ic_next2"),
        "flame_snow": ((250, 150, 60), "ic_dmg"), "bolt_snow": ((90, 170, 250), "ic_dmg"),
        "crosshair": ((240, 210, 90), "ic_rng"), "ring_drum": ((240, 160, 70), "ic_blast"),
        "coin_wing": ((250, 200, 60), "ic_price"), "drop_flame": ((250, 120, 60), "ic_dmg"),
    }
    for bid, (col, sym) in badges.items():
        chip = Image.new("RGBA", (52, 52), (0, 0, 0, 0))
        cd = ImageDraw.Draw(chip)
        cd.ellipse([2, 2, 50, 50], fill=col + (235,), outline=(45, 30, 20, 255), width=3)
        glyph = Image.open(f"{OUT}/ui/{sym}.png").convert("RGBA")
        gw = 28
        gh = int(glyph.height * gw / glyph.width)
        glyph = glyph.resize((gw, gh), Image.LANCZOS)
        chip.alpha_composite(glyph, (26 - gw // 2, 26 - gh // 2))
        save(chip, f"ui/badge_{bid}.png")
    # panel nine-patch base (the ES dark panel)
    save(es("btn_base"), "ui/panel_base.png")

def main():
    build_folk()
    build_bloons()
    build_fx()
    build_props()
    build_ui()
    print("POP ART DONE")

if __name__ == "__main__":
    main()
