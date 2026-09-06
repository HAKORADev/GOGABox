#!/usr/bin/env python3
"""v0.3.5 POP SIEGE art engine.
World art for the bloon siege: 13 bloons, 10 folk x 3 gears + portraits,
projectiles, PopCoin, synergy badges, props (Endless Siege frames + the owner's
GameMaker template, RECOLORS + recompositions - nothing as-is), ground grains,
the 30 map thumbs (reads maps.json - one truth), the registry tile.
Sources (recon, local-only): es_frames/ (Endless Siege atlas slices),
template/sprites (Tower_Defense_Template.zip). Outputs are COMMITTED pngs.
"""
import json, math, os, random
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

REPO = "/home/z/my-project/repo/GOGABox"
OUT = f"{REPO}/projects/gogabox/assets/games/pop_siege"
ES = "/home/z/my-project/recon/poptd/es_frames"
TPL = "/home/z/my-project/recon/poptd/template/sprites"
MAPS_JSON = f"{REPO}/projects/gogabox/game/games/pop_siege/maps.json"

INK = (58, 34, 22, 255)

def ensure(p):
    os.makedirs(p, exist_ok=True)

def canvas(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))

def ell(d, box, fill, outline=None, width=3):
    d.ellipse(box, fill=fill, outline=outline, width=width)

def shade(c, f):
    return (max(0, min(255, int(c[0] * f))), max(0, min(255, int(c[1] * f))),
            max(0, min(255, int(c[2] * f))), c[3] if len(c) > 3 else 255)

def gloss(im, box, alpha=110):
    """soft white gloss blob inside box (top-left)."""
    g = canvas(im.width, im.height)
    gd = ImageDraw.Draw(g)
    gd.ellipse(box, fill=(255, 255, 255, alpha))
    g = g.filter(ImageFilter.GaussianBlur(5))
    im.alpha_composite(g)

def vgrad(im, top, bot, box=None, oval=False):
    """vertical gradient overlay in box (or full); oval=True clips to an ellipse."""
    x0, y0, x1, y1 = box or (0, 0, im.width, im.height)
    g = canvas(im.width, im.height)
    gd = ImageDraw.Draw(g)
    h = max(1, y1 - y0)
    for y in range(y0, y1):
        t = (y - y0) / h
        c = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(4))
        gd.line([(x0, y), (x1, y)], fill=c)
    if oval:
        mask = canvas(im.width, im.height)
        ImageDraw.Draw(mask).ellipse((x0, y0, x1, y1), fill=(255, 255, 255, 255))
        g = Image.composite(g, canvas(im.width, im.height), mask)
    im.alpha_composite(g)

def hue_shift(im, deg, sat=1.0, bright=1.0):
    hsv = im.convert("RGBA")
    a = hsv.getchannel("A")
    hsv = hsv.convert("HSV")
    H, S, V = hsv.split()
    H = H.point(lambda v: (v + int(deg)) % 256)
    if sat != 1.0:
        S = S.point(lambda v: max(0, min(255, int(v * sat))))
    if bright != 1.0:
        V = V.point(lambda v: max(0, min(255, int(v * bright))))
    out = Image.merge("HSV", (H, S, V)).convert("RGBA")
    out.putalpha(a)
    return out

def outline(im, color=INK, width=3):
    """dark outline around alpha."""
    a = im.getchannel("A")
    sh = Image.new("RGBA", im.size, color)
    sh.putalpha(a)
    base = canvas(im.width + width * 2, im.height + width * 2)
    for dx in (-width, 0, width):
        for dy in (-width, 0, width):
            base.alpha_composite(sh, (width + dx, width + dy))
    base.alpha_composite(im, (width, width))
    return base

def es_frame(name):
    return Image.open(f"{ES}/{name}.png").convert("RGBA")

def tpl_sprite(spr):
    import glob
    fs = sorted(glob.glob(f"{TPL}/{spr}/*.png"))
    return Image.open(fs[0]).convert("RGBA")

def save(im, rel):
    p = f"{OUT}/{rel}"
    ensure(os.path.dirname(p))
    im.save(p)
    return p

# ============================================================ BLOONS
def balloon(color, r, kind="plain", crack=0):
    """a bloon: gradient balloon + knot + gloss. kind: plain/zebra/lead/rainbow/ceramic."""
    w = r * 2 + 16
    im = canvas(w, w + 10)
    d = ImageDraw.Draw(im)
    cx, cy, cy1 = w // 2, r + 4, r + 4
    # body
    ell(d, (cx - r, cy - int(r * 1.12), cx + r, cy + int(r * 1.12)), color)
    vgrad(im, (*shade(color, 1.28), 70), (*shade(color, 0.7), 100),
          (cx - r, cy - int(r * 1.12), cx + r, cy + int(r * 1.12)), oval=True)
    # kind dressing (clipped to the body)
    mask = canvas(w, w + 10)
    ImageDraw.Draw(mask).ellipse((cx - r, cy - int(r * 1.12), cx + r, cy + int(r * 1.12)), fill=(255, 255, 255, 255))
    dress = canvas(w, w + 10)
    dd = ImageDraw.Draw(dress)
    if kind == "zebra":
        for i in range(-w, w, 14):
            dd.polygon([(cx + i, 0), (cx + i + 7, 0), (cx + i + 7 - 14, w + 10), (cx + i - 14, w + 10)], fill=(30, 30, 34, 235))
    elif kind == "rainbow":
        cols = [(228, 60, 60), (240, 150, 40), (250, 220, 60), (70, 190, 90), (70, 120, 230), (150, 80, 220)]
        bh = (2 * int(r * 1.12)) // len(cols)
        for i, c in enumerate(cols):
            dd.rectangle((0, cy - int(r * 1.12) + i * bh, w, cy - int(r * 1.12) + (i + 1) * bh), fill=(*c, 210))
    elif kind == "lead":
        dd.rectangle((0, cy - 2, w, cy + 2), fill=(200, 205, 215, 200))
        for fx in range(3):
            fx0 = cx - r + 8 + fx * (2 * r - 16) // 2
            dd.ellipse((fx0 - 2, cy - int(r * 0.6), fx0 + 2, cy - int(r * 0.6) + 4), fill=(225, 230, 240, 220))
    elif kind == "ceramic":
        base = (186, 110, 60)
        dd.ellipse((cx - r, cy - int(r * 1.12), cx + r, cy + int(r * 1.12)), fill=base)
        dd.ellipse((cx - r + 3, cy - int(r * 1.12) + 3, cx + r - 3, cy + int(r * 1.12) - 3), outline=shade(base, 0.7), width=2)
        rng = random.Random(7 + crack)
        for _ in range(2 + crack * 2):
            x0, y0 = cx + rng.randint(-r, r), cy + rng.randint(-r, r)
            dd.line([(x0, y0), (x0 + rng.randint(-8, 8), y0 + rng.randint(-10, 10))], fill=(70, 34, 18, 230), width=3)
    im.alpha_composite(Image.composite(dress, canvas(w, w + 10), mask))
    # gloss + knot + outline
    gloss(im, (cx - int(r * 0.62), cy - int(r * 0.95), cx - 2, cy - int(r * 0.25)), 120)
    d.ellipse((cx - 5, cy + int(r * 1.12) - 2, cx + 5, cy + int(r * 1.12) + 8), fill=shade(color, 0.75))
    return outline(im, (40, 26, 20, 255), 3)

def blimp(color, w, h, brute=False):
    im = canvas(w + 20, h + 26)
    d = ImageDraw.Draw(im)
    cx, cy = (w + 20) // 2, (h + 26) // 2
    bx0, by0, bx1, by1 = 10, 8, 10 + w, 8 + h
    d.ellipse((bx0, by0, bx1, by1), fill=color)
    vgrad(im, (*shade(color, 1.3), 70), (*shade(color, 0.6), 100), (bx0, by0, bx1, by1), oval=True)
    # armor plates
    for i in range(3):
        px = bx0 + w * (0.24 + i * 0.26)
        d.arc((px - w * 0.09, by0 + h * 0.12, px + w * 0.09, by1 - h * 0.12), -80, 80, fill=shade(color, 0.55), width=4)
    # tail fins
    d.polygon([(bx0 + w * 0.02, cy), (bx0 - 8, cy - h * 0.34), (bx0 + w * 0.14, cy - 2)], fill=shade(color, 0.75))
    d.polygon([(bx0 + w * 0.02, cy), (bx0 - 8, cy + h * 0.34), (bx0 + w * 0.14, cy + 2)], fill=shade(color, 0.75))
    # nose
    d.ellipse((bx1 - w * 0.16, cy - h * 0.2, bx1 + 6, cy + h * 0.2), fill=shade(color, 1.25))
    # gondola
    d.rounded_rectangle((cx - w * 0.13, by1 - 2, cx + w * 0.13, by1 + 14), 8, fill=(70, 52, 40, 255), outline=(40, 26, 20, 255), width=3)
    if brute:
        for i in range(4):
            rx = bx0 + w * (0.18 + i * 0.2)
            d.ellipse((rx - 4, cy - h * 0.32, rx + 4, cy - h * 0.32 + 8), fill=(230, 220, 200, 255))
            d.ellipse((rx - 4, cy + h * 0.32 - 8, rx + 4, cy + h * 0.32), fill=(230, 220, 200, 255))
        d.polygon([(bx1 - w * 0.3, by0 + 2), (bx1 - w * 0.2, by0 - 12), (bx1 - w * 0.12, by0 + 3)], fill=(230, 220, 200, 255))
        d.polygon([(bx1 - w * 0.3, by1 - 2), (bx1 - w * 0.2, by1 + 12), (bx1 - w * 0.12, by1 - 3)], fill=(230, 220, 200, 255))
    gloss(im, (bx0 + w * 0.2, by0 + h * 0.14, bx0 + w * 0.52, by0 + h * 0.4), 90)
    return outline(im, (30, 20, 16, 255), 4)

def make_bloons():
    B = {
        "red": ((214, 56, 56), 30), "blue": ((58, 118, 214), 30), "green": ((64, 178, 74), 32),
        "yellow": ((240, 200, 50), 32), "pink": ((240, 110, 170), 32), "black": ((38, 38, 44), 30),
        "white": ((238, 240, 244), 30), "zebra": ((236, 236, 240), 34), "lead": ((122, 128, 138), 34),
        "rainbow": ((228, 60, 60), 34), "ceramic": ((186, 110, 60), 38),
    }
    for k, (c, r) in B.items():
        kind = k if k in ("zebra", "lead", "rainbow", "ceramic") else "plain"
        save(outline(balloon(c, r, kind), (40, 26, 20, 255), 0), f"bloons/{k}.png")
    # ceramic crack states (by hp thirds)
    for st in (1, 2):
        save(balloon((186, 110, 60), 38, "ceramic", st), f"bloons/ceramic_c{st}.png")
    save(blimp((70, 96, 170), 200, 108), "bloons/moab.png")
    save(blimp((96, 62, 60), 236, 128, brute=True), "bloons/brutus.png")
    print("bloons ok")

# ============================================================ FOLK
FOLK = {
    # id: (body, hat, weapon, accent)
    "darty":   ((126, 168, 90), "cap", "dart", (240, 220, 160)),
    "pyra":    ((208, 96, 60), "torch_crown", "torch", (255, 160, 60)),
    "boomba":  ((110, 110, 128), "helmet", "bomb", (255, 190, 80)),
    "boomo":   ((90, 150, 160), "bandana", "rang", (230, 240, 250)),
    "gloop":   ((140, 190, 80), "hood", "goo", (180, 230, 120)),
    "kolda":   ((110, 170, 220), "crown_ice", "ice", (220, 245, 255)),
    "longeye": ((100, 120, 90), "visor", "rifle", (210, 220, 200)),
    "zappy":   ((120, 110, 200), "coils", "rod", (255, 240, 140)),
    "kaching": ((220, 180, 70), "fedora", "bag", (255, 230, 130)),
    "marshal": ((170, 90, 70), "shako", "drum", (240, 230, 210)),
}

def draw_weapon(d, kind, x, y, gear, accent):
    g3 = gear >= 3
    if kind == "dart":
        d.line([(x, y), (x + 26 + gear * 2, y - 6)], fill=(150, 100, 60, 255), width=5)
        d.polygon([(x + 26 + gear * 2, y - 6), (x + 36 + gear * 2, y - 8), (x + 27 + gear * 2, y - 1)], fill=(*(accent), 255))
    elif kind == "bomb":
        ell(d, (x - 6, y - 8, x + 12, y + 10), (40, 40, 46, 255), (20, 20, 24, 255), 2)
        d.line([(x + 2, y - 8), (x + 7, y - 15)], fill=(150, 100, 50, 255), width=3)
        d.ellipse((x + 5, y - 19, x + 11, y - 13), fill=(255, 170, 60, 255) if g3 else (255, 210, 90, 255))
    elif kind == "torch":
        d.line([(x, y), (x + 4, y - 20)], fill=(120, 80, 50, 255), width=5)
        ell(d, (x - 3, y - 30, x + 13, y - 14), (255, 150, 40, 255) if g3 else (255, 190, 60, 255))
        ell(d, (x + 1, y - 26, x + 9, y - 18), (255, 240, 160, 255))
    elif kind == "rang":
        d.arc((x - 4, y - 22, x + 22, y + 4), 300, 120, fill=(200, 150, 80, 255), width=6)
        if g3:
            d.arc((x - 8, y - 26, x + 26, y + 8), 300, 120, fill=(*accent, 200), width=3)
    elif kind == "goo":
        d.rounded_rectangle((x - 4, y - 14, x + 12, y + 2), 4, fill=(150, 190, 90, 255), outline=INK, width=2)
        d.line([(x + 4, y - 14), (x + 4, y - 20)], fill=(100, 130, 70, 255), width=4)
        d.ellipse((x + 10, y - 4, x + 16, y + 2), fill=(180, 230, 120, 255))
    elif kind == "ice":
        d.line([(x, y), (x + 2, y - 22)], fill=(160, 200, 230, 255), width=4)
        for a in range(6):
            ang = a * math.pi / 3
            d.line([(x + 2, y - 22), (x + 2 + 9 * math.cos(ang), y - 22 + 9 * math.sin(ang))],
                   fill=(*(accent), 255), width=3)
    elif kind == "rifle":
        d.rounded_rectangle((x - 8, y - 5, x + 30, y + 1), 2, fill=(90, 70, 55, 255), outline=INK, width=2)
        d.rounded_rectangle((x + 24, y - 4, x + 34 + (4 if g3 else 0), y - 1), 1, fill=(140, 140, 150, 255))
        d.rounded_rectangle((x - 4, y + 1, x + 2, y + 8), 2, fill=(90, 70, 55, 255))
    elif kind == "rod":
        d.line([(x, y), (x + 2, y - 20)], fill=(150, 140, 190, 255), width=4)
        ell(d, (x - 3, y - 27, x + 9, y - 15), (255, 240, 140, 255) if not g3 else (255, 250, 190, 255), INK, 2)
    elif kind == "bag":
        d.polygon([(x - 8, y), (x + 10, y), (x + 7, y - 14), (x - 5, y - 14)], fill=(200, 150, 60, 255), outline=INK)
        d.arc((x - 4, y - 20, x + 6, y - 10), 180, 360, fill=(150, 110, 50, 255), width=3)
    elif kind == "drum":
        ell(d, (x - 9, y - 12, x + 11, y + 8), (200, 90, 70, 255), INK, 2)
        d.line([(x - 9, y - 2), (x + 11, y - 2)], fill=(240, 230, 210, 255), width=3)
        d.line([(x + 10, y - 8), (x + 18, y - 16)], fill=(150, 100, 60, 255), width=3)

def folk_sprite(fid, gear):
    body, hat, weapon, accent = FOLK[fid]
    S = 1.0 + (gear - 1) * 0.09
    W = int(120 * S)
    im = canvas(W + 16, W + 16)
    d = ImageDraw.Draw(im)
    c = W // 2 + 8
    base_y = int(W * 0.86)
    # shadow
    d.ellipse((c - int(26 * S), base_y - 4, c + int(26 * S), base_y + 8), fill=(0, 0, 0, 60))
    # feet
    d.ellipse((c - int(16 * S), base_y - 8, c - int(2 * S), base_y + 4), fill=shade(body, 0.55))
    d.ellipse((c + int(2 * S), base_y - 8, c + int(16 * S), base_y + 4), fill=shade(body, 0.55))
    # body capsule
    bw = int(24 * S)
    d.rounded_rectangle((c - bw, base_y - int(44 * S), c + bw, base_y - 2), bw, fill=body, outline=INK, width=3)
    d.ellipse((c - bw + 4, base_y - int(40 * S), c + bw - 4, base_y - int(18 * S)), fill=shade(body, 1.12))
    # gear trims
    if gear >= 2:
        d.rounded_rectangle((c - bw - 3, base_y - int(38 * S), c - bw + 5, base_y - int(24 * S)), 4, fill=(*accent, 255), outline=INK)
        d.rounded_rectangle((c + bw - 5, base_y - int(38 * S), c + bw + 3, base_y - int(24 * S)), 4, fill=(*accent, 255), outline=INK)
    if gear >= 3:
        d.line([(c - bw, base_y - int(44 * S)), (c + bw, base_y - int(44 * S))], fill=(255, 214, 90, 255), width=4)
        d.line([(c - bw, base_y - 4), (c + bw, base_y - 4)], fill=(255, 214, 90, 255), width=3)
    # head
    hr = int(19 * S)
    hy = base_y - int(44 * S) - hr + int(2 * S)
    d.ellipse((c - hr, hy - hr, c + hr, hy + hr), fill=(250, 224, 196), outline=INK, width=3)
    # eyes + smile
    ex = int(7 * S)
    d.ellipse((c - ex - 3, hy - 3, c - ex + 3, hy + 4), fill=(40, 30, 26, 255))
    d.ellipse((c + ex - 3, hy - 3, c + ex + 3, hy + 4), fill=(40, 30, 26, 255))
    d.arc((c - 6, hy + 4, c + 6, hy + 12), 20, 160, fill=(120, 60, 50, 255), width=2)
    # hats
    hx0, hx1 = c - hr - 2, c + hr + 2
    if hat == "cap":
        d.pieslice((hx0, hy - hr - int(8 * S), hx1, hy + int(2 * S)), 180, 360, fill=shade(body, 0.8), outline=INK)
        d.rounded_rectangle((c - hr - 2, hy - 6, c + hr + 8, hy - 1), 2, fill=shade(body, 0.7), outline=INK)
    elif hat == "helmet":
        d.pieslice((hx0 - 2, hy - hr - 6, hx1 + 2, hy + 4), 180, 360, fill=(150, 155, 170), outline=INK)
        d.line([(c, hy - hr - 4), (c, hy - 2)], fill=(120, 125, 140, 255), width=3)
    elif hat == "torch_crown":
        for a in (-40, 0, 40):
            x0 = c + int(16 * S * math.sin(math.radians(a)))
            d.line([(x0, hy - hr + 4), (x0, hy - hr - 10)], fill=(140, 90, 60, 255), width=3)
            d.ellipse((x0 - 3, hy - hr - 17, x0 + 3, hy - hr - 10), fill=(255, 170, 60, 255))
    elif hat == "bandana":
        d.pieslice((hx0, hy - hr - 4, hx1, hy + 2), 180, 360, fill=(220, 80, 90), outline=INK)
        d.polygon([(c - hr, hy - 2), (c - hr - 10, hy + 6), (c - hr + 2, hy + 4)], fill=(220, 80, 90, 255))
    elif hat == "hood":
        d.pieslice((hx0 - 3, hy - hr - 5, hx1 + 3, hy + 6), 160, 380, fill=shade(body, 0.7), outline=INK)
    elif hat == "crown_ice":
        d.polygon([(hx0 + 2, hy - 2), (hx0 + 2, hy - 10), (c - 6, hy - 5), (c, hy - 15), (c + 6, hy - 5), (hx1 - 2, hy - 10), (hx1 - 2, hy - 2)], fill=(*accent, 255), outline=INK)
    elif hat == "visor":
        d.rounded_rectangle((hx0 - 1, hy - 8, hx1 + 1, hy - 1), 3, fill=(80, 90, 80, 230), outline=INK)
        d.pieslice((hx0, hy - hr - 4, hx1, hy), 200, 340, fill=(70, 90, 60), outline=INK)
    elif hat == "coils":
        for sx in (-10, 10):
            d.arc((c + sx - 6, hy - hr - 8, c + sx + 6, hy - hr + 6), 0, 360, fill=(180, 170, 220, 255), width=3)
            d.ellipse((c + sx - 3, hy - hr - 12, c + sx + 3, hy - hr - 6), fill=(255, 240, 140, 255))
    elif hat == "fedora":
        d.ellipse((hx0 - 4, hy - 4, hx1 + 4, hy + 4), fill=(150, 110, 60, 255), outline=INK)
        d.pieslice((hx0 + 2, hy - hr - 8, hx1 - 2, hy), 180, 360, fill=(170, 125, 70, 255), outline=INK)
    elif hat == "shako":
        d.rounded_rectangle((hx0, hy - hr - 12, hx1, hy - 2), 3, fill=(70, 55, 50, 255), outline=INK)
        d.line([(hx0, hy - hr - 6), (hx1, hy - hr - 6)], fill=(240, 220, 180, 255), width=2)
        d.ellipse((c - 3, hy - hr - 16, c + 3, hy - hr - 10), fill=(255, 214, 90, 255), outline=INK)
    # weapon (in hand, right side)
    draw_weapon(d, weapon, c + int(14 * S), base_y - int(30 * S), gear, accent)
    if gear >= 3:
        glow = canvas(im.width, im.height)
        ImageDraw.Draw(glow).ellipse((c - hr - 6, hy - hr - 6, c + hr + 6, hy + hr + 6), outline=(255, 214, 90, 120), width=3)
        im.alpha_composite(glow.filter(ImageFilter.GaussianBlur(2)))
    return im

def folk_portrait(fid):
    im = folk_sprite(fid, 1)
    # crop the head region for the card portrait
    W = im.width
    crop = im.crop((W // 2 - 40, int(W * 0.10), W // 2 + 40, int(W * 0.10) + 80)).resize((96, 96), Image.LANCZOS)
    return crop

def make_folk():
    for fid in FOLK:
        for gear in (1, 2, 3):
            save(outline(folk_sprite(fid, gear), (40, 26, 20, 255), 2), f"folk/{fid}_g{gear}.png")
        save(folk_portrait(fid), f"folk/{fid}_face.png")
    print("folk ok")

# ============================================================ PROPS
# prop id -> (source, hue, sat, bright)  source: es:obstacle_N | tpl:spr_X | gen:name
PROP_SRC = {
    "tree_green":  ("tpl:spr_tree_green", 0, 1.0, 1.0),
    "tree_bare":   ("tpl:spr_tree_bare", 0, 0.8, 1.0),
    "tree_blue":   ("tpl:spr_tree_blue", 0, 0.9, 1.0),
    "bush_a":      ("es:obstacle_30", 0, 1.0, 1.0),
    "bush_b":      ("es:obstacle_16", 0, 1.0, 1.0),
    "fence_h":     ("tpl:spr_fence_straight_1", 0, 1.0, 1.0),
    "deadfence_h": ("tpl:spr_fence_straight_1", -30, 0.35, 0.85),
    "pine_a":      ("es:obstacle_3", 0, 1.0, 1.0),
    "pine_b":      ("es:obstacle_4", -14, 0.95, 0.95),
    "stump_a":     ("es:obstacle_6", 0, 1.0, 1.0),
    "shroom_trio": ("es:obstacle_12", 0, 1.0, 1.0),
    "cactus_a":    ("es:obstacle_23", 0, 1.0, 1.0),
    "cactus_b":    ("es:obstacle_15", 8, 1.0, 1.0),
    "skull_rock":  ("es:obstacle_20", 0, 1.0, 1.0),
    "dunerock":    ("es:obstacle_9", -18, 0.7, 1.05),
    "snowman_a":   ("gen:snowman", 0, 1.0, 1.0),
    "icerock_a":   ("es:obstacle_19", -55, 0.8, 1.05),
    "palm_a":      ("es:obstacle_17", 0, 1.0, 1.0),
    "palm_b":      ("es:obstacle_18", 0, 1.0, 0.95),
    "umbrella_a":  ("gen:umbrella", 0, 1.0, 1.0),
    "deadtree_a":  ("es:obstacle_11", -20, 0.5, 0.9),
    "deadtree_b":  ("es:obstacle_11", -10, 0.4, 0.8),
    "reed_trio":   ("gen:reeds", 0, 1.0, 1.0),
    "lavarock_a":  ("es:obstacle_9", 88, 0.85, 0.72),
    "lavarock_b":  ("es:obstacle_7", 92, 0.9, 0.7),
    "vent_a":      ("gen:vent", 0, 1.0, 1.0),
    "lolly_a":     ("gen:lolly_swirl", 0, 1.0, 1.0),
    "lolly_b":     ("gen:lolly_round", 0, 1.0, 1.0),
    "gummy_a":     ("es:obstacle_30", 65, 1.25, 1.05),
    "cane_a":      ("gen:cane", 0, 1.0, 1.0),
    "grave_a":     ("tpl:spr_grave_1", 0, 0.9, 0.95),
    "tomb_a":      ("tpl:spr_tombstone", 0, 0.9, 0.95),
    "crystal_a":   ("gen:crystal_a", 0, 1.0, 1.0),
    "crystal_b":   ("gen:crystal_b", 0, 1.0, 1.0),
    "stalag_a":    ("gen:stalag", 0, 1.0, 1.0),
    # decor
    "flowers_a":   ("gen:flowers_pink", 0, 1.0, 1.0),
    "flowers_b":   ("gen:flowers_yellow", 0, 1.0, 1.0),
    "tuft":        ("gen:tuft", 0, 1.0, 1.0),
    "fern":        ("es:obstacle_21", 0, 1.0, 0.95),
    "shroom_a":    ("es:obstacle_13", 0, 1.0, 1.0),
    "shroom_b":    ("es:obstacle_12", -25, 0.9, 0.9),
    "glowshroom":  ("es:obstacle_13", 100, 1.2, 1.05),
    "bones_a":     ("es:obstacle_22", 0, 1.0, 1.0),
    "skull_pile":  ("es:obstacle_22", 0, 0.9, 0.9),
    "pebbles":     ("es:obstacle_19", 0, 0.8, 1.0),
    "shell_a":     ("gen:shell", 0, 1.0, 1.0),
    "starfish":    ("gen:starfish", 0, 1.0, 1.0),
    "lilypad":     ("gen:lilypad", 0, 1.0, 1.0),
    "reed_a":      ("gen:reed", 0, 1.0, 1.0),
    "snowtuft":    ("gen:tuft", 0, 0.3, 1.35),
    "icicle":      ("gen:icicle", 0, 1.0, 1.0),
    "ember_rock":  ("es:obstacle_19", 80, 1.0, 0.8),
    "obsidian_shard": ("gen:obsidian", 0, 1.0, 1.0),
    "sprinkle_dot": ("gen:sprinkle", 0, 1.0, 1.0),
    "candy_bit":   ("gen:candy_bit", 0, 1.0, 1.0),
    "rune_dot":    ("gen:rune", 0, 1.0, 1.0),
    "grass_d":     ("gen:tuft", -30, 0.6, 0.8),
    "house":       ("tpl:spr_house", 0, 1.0, 1.0),
}

def gen_prop(name):
    im = canvas(112, 112)
    d = ImageDraw.Draw(im)
    if name == "snowman":
        ell(d, (36, 66, 76, 106), (238, 242, 248, 255), (150, 165, 185, 255), 2)
        ell(d, (40, 36, 72, 72), (240, 244, 250, 255), (150, 165, 185, 255), 2)
        ell(d, (48, 46, 54, 54), (40, 40, 46, 255)); ell(d, (58, 46, 64, 54), (40, 40, 46, 255))
        d.polygon([(56, 52), (76, 56), (56, 58)], fill=(240, 150, 60, 255))
        d.rectangle((40, 32, 72, 40), fill=(90, 60, 40, 255)); d.rectangle((48, 20, 64, 34), fill=(90, 60, 40, 255))
    elif name == "umbrella":
        d.line([(56, 54), (56, 100)], fill=(150, 110, 70, 255), width=4)
        d.pieslice((24, 18, 88, 74), 180, 360, fill=(230, 90, 90, 255), outline=(120, 50, 50, 255), width=2)
        d.pieslice((24, 18, 88, 74), 210, 250, fill=(240, 240, 240, 255))
        d.pieslice((24, 18, 88, 74), 290, 330, fill=(240, 240, 240, 255))
    elif name == "reeds":
        for x in (40, 56, 72):
            d.line([(x, 104), (x + (-6 if x == 40 else 0 if x == 56 else 6), 46)], fill=(110, 140, 70, 255), width=4)
            d.ellipse((x - 4, 38, x + 4, 50), fill=(90, 70, 50, 255))
    elif name == "reed":
        d.line([(56, 104), (52, 52)], fill=(110, 140, 70, 255), width=4)
        d.ellipse((48, 44, 58, 58), fill=(90, 70, 50, 255))
    elif name == "vent":
        d.polygon([(34, 104), (56, 30), (78, 104)], fill=(60, 50, 52, 255), outline=(30, 24, 26, 255))
        d.ellipse((46, 40, 66, 56), fill=(255, 120, 40, 255))
        d.ellipse((50, 44, 62, 52), fill=(255, 210, 90, 255))
    elif name == "lolly_swirl":
        d.line([(56, 62), (56, 104)], fill=(240, 240, 235, 255), width=5)
        for i, c in enumerate([(235, 90, 110), (250, 210, 220), (235, 90, 110), (250, 210, 220), (235, 90, 110)]):
            d.arc((30 + i * 4, 14 + i * 4, 82 - i * 4, 66 - i * 4), 0, 360, fill=(*c, 255), width=6)
    elif name == "lolly_round":
        d.line([(56, 60), (56, 104)], fill=(240, 240, 235, 255), width=5)
        ell(d, (34, 16, 78, 60), (110, 190, 235, 255), (70, 140, 190, 255), 3)
        ell(d, (44, 26, 60, 42), (200, 240, 255, 255))
    elif name == "cane":
        d.arc((36, 18, 76, 58), 180, 360, fill=(235, 70, 90, 255), width=10)
        d.line([(36, 38), (36, 100)], fill=(235, 70, 90, 255), width=10)
        for y in range(20, 100, 16):
            d.line([(30, y), (42, y + 8)], fill=(250, 250, 250, 255), width=5)
            d.line([(38, y), (30, y + 8)], fill=(250, 250, 250, 255), width=0)
    elif name.startswith("crystal"):
        pts = {"crystal_a": [(56, 8), (76, 60), (66, 104), (46, 104), (36, 60)],
               "crystal_b": [(40, 30), (60, 6), (80, 34), (72, 104), (48, 104)]}[name]
        col = (120, 200, 235, 235) if name == "crystal_a" else (170, 130, 235, 235)
        d.polygon(pts, fill=col, outline=(60, 90, 130, 255))
        d.line([pts[0], (56, 104)], fill=(230, 250, 255, 160), width=3)
    elif name == "stalag":
        d.polygon([(44, 104), (58, 20), (72, 104)], fill=(90, 105, 130, 255), outline=(50, 60, 80, 255))
        d.polygon([(64, 104), (74, 44), (86, 104)], fill=(110, 125, 150, 255), outline=(50, 60, 80, 255))
    elif name.startswith("flowers"):
        c = (235, 120, 170, 255) if name == "flowers_pink" else (245, 210, 80, 255)
        for x in (38, 58, 76):
            d.line([(x, 104), (x, 78)], fill=(90, 150, 70, 255), width=3)
            for a in range(5):
                ang = a * math.tau / 5
                ell(d, (x + 8 * math.cos(ang) - 4, 72 + 8 * math.sin(ang) - 4, x + 8 * math.cos(ang) + 4, 72 + 8 * math.sin(ang) + 4), c)
            ell(d, (x - 3, 69, x + 3, 75), (250, 240, 170, 255))
    elif name == "tuft":
        for x in (42, 56, 70):
            d.arc((x - 12, 78, x + 12, 106), 220, 320, fill=(100, 165, 80, 255), width=4)
    elif name == "shell":
        d.pieslice((38, 60, 74, 100), 180, 360, fill=(240, 215, 190, 255), outline=(170, 140, 110, 255), width=2)
        d.line([(56, 60), (56, 100)], fill=(170, 140, 110, 255), width=2)
        d.line([(44, 64), (50, 100)], fill=(170, 140, 110, 255), width=2)
        d.line([(68, 64), (62, 100)], fill=(170, 140, 110, 255), width=2)
    elif name == "starfish":
        pts = []
        for a in range(5):
            ang = a * math.tau / 5 - math.pi / 2
            pts.append((56 + 26 * math.cos(ang), 76 + 26 * math.sin(ang)))
            ang2 = ang + math.tau / 10
            pts.append((56 + 12 * math.cos(ang2), 76 + 12 * math.sin(ang2)))
        d.polygon(pts, fill=(240, 140, 90, 255), outline=(170, 90, 50, 255))
    elif name == "lilypad":
        ell(d, (26, 66, 86, 100), (70, 170, 90, 235), (40, 120, 60, 255), 3)
        d.pieslice((44, 70, 92, 106), 180, 300, fill=(0, 0, 0, 0))
    elif name == "icicle":
        for x in (40, 56, 72):
            d.polygon([(x - 6, 40), (x + 6, 40), (x, 78 + (6 if x == 56 else 0))], fill=(190, 225, 250, 235), outline=(130, 175, 210, 255))
    elif name == "obsidian":
        d.polygon([(36, 104), (56, 26), (78, 104)], fill=(45, 40, 60, 255), outline=(25, 22, 34, 255))
        d.line([(56, 26), (50, 104)], fill=(90, 85, 120, 200), width=2)
    elif name == "sprinkle":
        d.line([(44, 78), (68, 62)], fill=(240, 130, 170, 255), width=7)
    elif name == "candy_bit":
        ell(d, (42, 66, 70, 94), (250, 200, 90, 255), (200, 150, 50, 255), 2)
        d.arc((46, 70, 66, 90), 0, 360, fill=(200, 150, 50, 255), width=2)
    elif name == "rune":
        d.rounded_rectangle((40, 68, 72, 96), 6, outline=(140, 220, 255, 235), width=3)
        d.line([(56, 72), (56, 92)], fill=(140, 220, 255, 235), width=3)
        d.line([(46, 82), (66, 82)], fill=(140, 220, 255, 235), width=3)
    return im

def make_props():
    for pid, (src, hue, sat, br) in PROP_SRC.items():
        if src.startswith("gen:"):
            im = gen_prop(src[4:])
        elif src.startswith("es:"):
            im = es_frame(src[3:])
        else:
            im = tpl_sprite(src[4:])
        im = hue_shift(im, hue, sat, br)
        # normalize size (blocking props ~ 96-116 px, decor smaller)
        target = 64 if pid in ("flowers_a", "flowers_b", "tuft", "pebbles", "shell_a", "starfish",
                               "sprinkle_dot", "candy_bit", "rune_dot", "snowtuft", "icicle",
                               "reed_a", "shroom_a", "shroom_b", "glowshroom", "grass_d",
                               "ember_rock", "obsidian_shard", "bones_a", "skull_pile", "lilypad",
                               "fern") else 108
        im.thumbnail((target, target), Image.LANCZOS)
        save(im, f"props/{pid}.png")
    print("props ok")

# ============================================================ UI + FX + COINS
def make_coin():
    im = canvas(96, 96)
    d = ImageDraw.Draw(im)
    ell(d, (6, 6, 90, 90), (255, 200, 40, 255), (170, 115, 20, 255), 5)
    ell(d, (14, 14, 82, 82), (255, 220, 80, 255))
    # the darker bloon embossed inside
    ell(d, (30, 26, 66, 70), (198, 138, 28, 255), (160, 105, 18, 255), 3)
    d.polygon([(44, 66), (52, 66), (48, 74)], fill=(160, 105, 18, 255))
    gloss(im, (22, 18, 52, 44), 150)
    save(im, "ui/popcoin.png")
    print("coin ok")

BADGES = {
    "drum": ((200, 90, 70), lambda d: (d.ellipse((10, 14, 34, 38), fill=(240, 230, 210, 255), outline=(120, 50, 40, 255), width=2),
                                        d.line([(12, 26), (32, 26)], fill=(200, 90, 70, 255), width=2))),
    "swirl": ((90, 150, 200), lambda d: d.arc((8, 8, 36, 36), 40, 320, fill=(240, 248, 255, 255), width=4)),
    "flame_snow": ((230, 120, 60), lambda d: (d.polygon([(22, 8), (30, 22), (22, 34), (14, 22)], fill=(255, 180, 60, 255)),
                                                d.line([(22, 8), (22, 34)], fill=(180, 230, 250, 255), width=2),
                                                d.line([(14, 21), (30, 21)], fill=(180, 230, 250, 255), width=2))),
    "bolt_snow": ((110, 100, 210), lambda d: (d.polygon([(26, 6), (14, 22), (21, 22), (16, 36), (30, 18), (23, 18)], fill=(255, 240, 140, 255)),
                                                d.line([(8, 10), (16, 10)], fill=(200, 240, 255, 255), width=2),
                                                d.line([(12, 6), (12, 14)], fill=(200, 240, 255, 255), width=2))),
    "crosshair": ((90, 110, 90), lambda d: (d.ellipse((8, 8, 36, 36), outline=(240, 240, 220, 255), width=3),
                                              d.line([(22, 4), (22, 14)], fill=(240, 240, 220, 255), width=3),
                                              d.line([(22, 30), (22, 40)], fill=(240, 240, 220, 255), width=3),
                                              d.line([(4, 22), (14, 22)], fill=(240, 240, 220, 255), width=3),
                                              d.line([(30, 22), (40, 22)], fill=(240, 240, 220, 255), width=3))),
    "ring_drum": ((190, 120, 60), lambda d: (d.ellipse((7, 7, 37, 37), outline=(255, 230, 180, 255), width=4),
                                               d.ellipse((17, 17, 27, 27), fill=(255, 230, 180, 255)))),
    "coin_wing": ((220, 180, 60), lambda d: (d.ellipse((12, 12, 32, 32), fill=(255, 220, 90, 255), outline=(150, 110, 30, 255), width=2),
                                               d.arc((2, 12, 20, 30), 90, 270, fill=(250, 250, 250, 255), width=3),
                                               d.arc((24, 12, 42, 30), 270, 90, fill=(250, 250, 250, 255), width=3))),
    "drop_flame": ((150, 170, 70), lambda d: (d.polygon([(16, 8), (24, 20), (16, 34), (8, 20)], fill=(255, 170, 60, 255)),
                                                d.ellipse((24, 22, 38, 36), fill=(160, 220, 250, 230)))),
}

def make_badges():
    for bid, (bg, glyph) in BADGES.items():
        im = canvas(44, 44)
        d = ImageDraw.Draw(im)
        ell(d, (2, 2, 42, 42), (*bg, 245), (40, 28, 20, 255), 3)
        glyph(d)
        save(im, f"ui/badge_{bid}.png")
    print("badges ok")

def make_fx():
    # soft spark (radial)
    im = canvas(48, 48)
    d = ImageDraw.Draw(im)
    for r, a in ((22, 40), (15, 90), (9, 170), (4, 255)):
        d.ellipse((24 - r, 24 - r, 24 + r, 24 + r), fill=(255, 255, 255, a))
    save(im.filter(ImageFilter.GaussianBlur(1)), "fx/spark.png")
    # ring (shockwave)
    im = canvas(96, 96)
    d = ImageDraw.Draw(im)
    d.ellipse((6, 6, 90, 90), outline=(255, 255, 255, 200), width=10)
    im = im.filter(ImageFilter.GaussianBlur(3))
    save(im, "fx/ring.png")
    # smoke puff
    im = canvas(64, 64)
    d = ImageDraw.Draw(im)
    for x, y, r in ((24, 36, 14), (40, 30, 16), (34, 42, 12)):
        d.ellipse((x - r, y - r, x + r, y + r), fill=(235, 235, 235, 150))
    save(im.filter(ImageFilter.GaussianBlur(4)), "fx/smoke.png")
    # ember
    im = canvas(24, 24)
    d = ImageDraw.Draw(im)
    d.ellipse((6, 6, 18, 18), fill=(255, 170, 60, 235))
    save(im.filter(ImageFilter.GaussianBlur(1)), "fx/ember.png")
    # snowflake
    im = canvas(32, 32)
    d = ImageDraw.Draw(im)
    for a in range(6):
        ang = a * math.pi / 3
        d.line([(16, 16), (16 + 12 * math.cos(ang), 16 + 12 * math.sin(ang))], fill=(220, 245, 255, 235), width=3)
    save(im, "fx/snowflake.png")
    # goo drop
    im = canvas(28, 28)
    d = ImageDraw.Draw(im)
    d.polygon([(14, 2), (24, 18), (14, 26), (4, 18)], fill=(160, 220, 110, 235))
    save(im, "fx/goo.png")
    # firefly
    im = canvas(20, 20)
    d = ImageDraw.Draw(im)
    d.ellipse((6, 6, 14, 14), fill=(255, 240, 150, 255))
    save(im.filter(ImageFilter.GaussianBlur(2)), "fx/firefly.png")
    # frag shard
    im = canvas(20, 20)
    d = ImageDraw.Draw(im)
    d.polygon([(10, 2), (18, 12), (10, 18), (2, 12)], fill=(120, 120, 130, 255))
    save(im, "fx/frag.png")
    # golden egg (kaching g3)
    im = canvas(40, 48)
    d = ImageDraw.Draw(im)
    d.ellipse((6, 8, 34, 42), fill=(255, 214, 90, 255), outline=(180, 130, 30, 255), width=3)
    gloss(im, (10, 12, 26, 28), 170)
    save(im, "fx/egg.png")
    # fire trap (pyra g2)
    im = canvas(48, 40)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((8, 18, 40, 36), 6, fill=(90, 70, 55, 255), outline=(50, 36, 26, 255), width=3)
    d.ellipse((16, 4, 32, 22), fill=(255, 150, 50, 245), outline=(210, 90, 30, 255), width=2)
    d.ellipse((20, 9, 28, 17), fill=(255, 235, 160, 255))
    save(im, "fx/trap.png")
    # projectile sprites
    for pid, painter in {
        "dart": lambda d: (d.polygon([(2, 8), (22, 5), (2, 11)], fill=(180, 120, 70, 255)),
                            d.polygon([(20, 3), (28, 8), (20, 13)], fill=(240, 220, 160, 255))),
        "gold_dart": lambda d: (d.polygon([(2, 8), (22, 5), (2, 11)], fill=(240, 200, 90, 255)),
                                  d.polygon([(20, 3), (30, 8), (20, 13)], fill=(255, 240, 170, 255))),
        "boomerang": lambda d: d.arc((2, 2, 26, 26), 300, 120, fill=(210, 160, 90, 255), width=6),
        "bomb": lambda d: (d.ellipse((2, 2, 22, 22), fill=(45, 45, 52, 255), outline=(20, 20, 24, 255), width=2),
                             d.line([(12, 3), (16, 0)], fill=(150, 100, 50, 255), width=2)),
        "flame": lambda d: (d.ellipse((2, 2, 22, 22), fill=(255, 150, 50, 240)),
                              d.ellipse((7, 7, 17, 17), fill=(255, 235, 160, 255))),
        "ice": lambda d: (d.polygon([(12, 1), (20, 12), (12, 23), (4, 12)], fill=(180, 230, 250, 245),
                                      outline=(110, 170, 210, 255))),
        "goo": lambda d: (d.ellipse((2, 4, 22, 22), fill=(150, 210, 100, 240)),
                            d.ellipse((7, 8, 13, 14), fill=(200, 245, 150, 255))),
        "bullet": lambda d: d.ellipse((2, 6, 20, 14), fill=(90, 90, 100, 255)),
        "sniper": lambda d: (d.line([(1, 8), (26, 8)], fill=(230, 225, 210, 255), width=3),
                               d.polygon([(24, 5), (30, 8), (24, 11)], fill=(255, 240, 170, 255))),
    }.items():
        im = canvas(32, 26)
        painter(ImageDraw.Draw(im))
        save(im, f"fx/p_{pid}.png")
    print("fx ok")

# ============================================================ GROUND GRAINS
THEME_GROUND = {
    "meadow":    ((116, 176, 84), (104, 162, 74)),
    "forest":    ((88, 148, 82), (76, 132, 72)),
    "desert":    ((226, 196, 130), (214, 182, 116)),
    "snow":      ((226, 234, 242), (212, 222, 234)),
    "beach":     ((238, 214, 160), (228, 202, 146)),
    "swamp":     ((96, 128, 92), (84, 114, 82)),
    "volcano":   ((94, 78, 78), (82, 68, 70)),
    "candy":     ((248, 198, 214), (240, 184, 202)),
    "graveyard": ((118, 128, 112), (106, 116, 102)),
    "crystal":   ((92, 104, 136), (82, 92, 122)),
}

def grain(theme):
    base, dark = THEME_GROUND[theme]
    rng = random.Random("grain_" + theme)
    im = canvas(256, 256)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 256, 256), fill=(*base, 255))
    for _ in range(240):
        x, y = rng.randint(-8, 256), rng.randint(-8, 256)
        r = rng.randint(1, 3)
        c = (*dark, 90) if rng.random() < 0.7 else (*shade(base, 1.08)[:3], 90)
        for ox in (-256, 0, 256):
            for oy in (-256, 0, 256):
                d.ellipse((x + ox - r, y + oy - r, x + ox + r, y + oy + r), fill=c)
    for _ in range(26):
        x, y = rng.randint(0, 256), rng.randint(0, 256)
        for ox in (-256, 0, 256):
            for oy in (-256, 0, 256):
                d.ellipse((x + ox - 9, y + oy - 5, x + ox + 9, y + oy + 5), fill=(*dark, 46))
    return im.convert("RGB")

def make_grains():
    ensure(f"{OUT}/tiles")
    for t in THEME_GROUND:
        grain(t).save(f"{OUT}/tiles/{t}.png")
    print("grains ok")

# ============================================================ MAP THUMBS
def map_thumb(m, path_prefix=""):
    TW, TH = 240, 135
    cw = TW / 18.0
    ch = TH / 10.0
    base, dark = THEME_GROUND[m["theme"]]
    im = Image.new("RGB", (TW, TH), base)
    d = ImageDraw.Draw(im, "RGBA")
    rng = random.Random("thumb_" + m["id"])
    for _ in range(70):
        x, y = rng.randint(0, TW), rng.randint(0, TH)
        d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=(*dark, 60))
    # water
    for c, r in m.get("water", []):
        d.rectangle((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch), fill=(70, 140, 200, 255))
    # roads
    for pts in m["paths"]:
        pl = [( (c + 0.5) * cw, (r + 0.5) * ch) for c, r in pts]
        d.line(pl, fill=(214, 178, 120, 255), width=9, joint="curve")
        d.line(pl, fill=(150, 116, 70, 255), width=1)
        d.ellipse((pl[0][0] - 5, pl[0][1] - 5, pl[0][0] + 5, pl[0][1] + 5), fill=(90, 60, 40, 255))
    # blocked props
    for c, r, pid in m["blocked"]:
        d.ellipse((c * cw + 4, r * ch + 2, (c + 1) * cw - 4, (r + 1) * ch - 2), fill=(52, 96, 48, 235))
    # the heart
    hc, hr = m["heart"]
    d.ellipse(((hc + 0.1) * cw, (hr + 0.1) * ch, (hc + 0.9) * cw, (hr + 0.9) * ch), fill=(214, 70, 70, 255))
    # night variant
    night = ImageEnhance.Brightness(im.convert("RGB")).enhance(0.45)
    night = Image.merge("RGB", (night.getchannel("R"), night.getchannel("G"), night.getchannel("B").point(lambda v: int(v * 1.06))))
    return im, night

def make_thumbs():
    data = json.load(open(MAPS_JSON))
    for m in data["maps"]:
        day, night = map_thumb(m)
        save(Image.new("RGBA", day.size, (0, 0, 0, 0)).__class__.blend(Image.new("RGBA", day.size, (0, 0, 0, 255)), day, 0.0).convert("RGB") if False else day, f"thumbs/{m['id']}.png")
        save(night, f"thumbs/{m['id']}_n.png")
    print("thumbs ok")

# ============================================================ REGISTRY TILE
def make_tile():
    im = Image.new("RGB", (960, 640))
    base, dark = THEME_GROUND["meadow"]
    d = ImageDraw.Draw(im, "RGBA")
    d.rectangle((0, 0, 960, 640), fill=base)
    rng = random.Random("tile")
    for _ in range(300):
        x, y = rng.randint(0, 960), rng.randint(0, 640)
        d.ellipse((x - 3, y - 3, x + 3, y + 3), fill=(*dark, 70))
    # a hero S-path through the middle
    pl = [(-30, 120), (240, 120), (240, 340), (560, 340), (560, 150), (880, 150), (880, 460), (990, 460)]
    pl = [(x * 0.92, y * 0.92 + 30) for x, y in pl]
    d.line(pl, fill=(214, 178, 120, 255), width=34, joint="curve")
    d.line(pl, fill=(160, 124, 76, 255), width=4)
    # the heart house at the end
    house = tpl_sprite("spr_house")
    house.thumbnail((150, 170), Image.LANCZOS)
    im.paste(house, (900 - house.width // 2, int(pl[-1][1]) - house.height + 40), house)
    # real props scattered (the ones the game ships)
    prop_layout = [("tree_green", 60, 60), ("bush_a", 420, 80), ("pine_a", 700, 300), ("tree_green", 660, 520),
                   ("bush_b", 140, 470), ("flowers_a", 320, 250), ("flowers_b", 500, 480), ("tuft", 800, 80),
                   ("shroom_a", 60, 300), ("stump_a", 380, 560)]
    for pid, x, y in prop_layout:
        p = Image.open(f"{OUT}/props/{pid}.png")
        im.paste(p, (x, y), p)
    # hero bloons riding the road
    def on_path(t):
        seg = t * (len(pl) - 1)
        i = min(int(seg), len(pl) - 2)
        f = seg - i
        return (pl[i][0] + (pl[i + 1][0] - pl[i][0]) * f, pl[i][1] + (pl[i + 1][1] - pl[i][1]) * f)
    for i, (bcol, bsize, t) in enumerate([((214, 56, 56), 46, 0.24), ((58, 118, 214), 42, 0.36), ((64, 178, 74), 44, 0.48), ((240, 200, 50), 42, 0.58)]):
        x, y = on_path(t)
        bl = balloon(bcol, bsize)
        im.paste(bl.convert("RGB"), (int(x - bl.width / 2), int(y - bl.height / 2)), bl)
    # a MOAB looming at the start
    mo = blimp((70, 96, 170), 150, 82)
    x, y = on_path(0.02)
    im.paste(mo.convert("RGB"), (int(x - mo.width / 2), int(y - mo.height / 2) - 60), mo)
    # the folk line defending
    for i, fid in enumerate(("darty", "pyra", "boomba", "kolda", "zappy")):
        f = folk_sprite(fid, 3 if i == 1 else 2)
        f.thumbnail((140, 140), Image.LANCZOS)
        im.paste(f.convert("RGB"), (70 + i * 168, 640 - f.height - 12), f)
    save(im.convert("RGB"), "../../thumbs/pop_siege.png")
    print("tile ok")

if __name__ == "__main__":
    make_bloons()
    make_folk()
    make_props()
    make_coin()
    make_badges()
    make_fx()
    make_grains()
    make_thumbs()
    make_tile()
    print("ART DONE")
