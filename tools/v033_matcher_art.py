#!/usr/bin/env python3
"""v0.3.3 MATCHER art pipeline.

Sources:
  - git history: candyrush @ ec82c09 (CC0, OpenGameArt) -> gem + candy sets,
    explosion frames, pops/synth sfx, the Happy Adventure music loop
  - fresh hunt: Kenney Particle Pack via OGA (CC0) -> VFX textures
    (downloaded once to tools/_v033_fetch/, vendored pieces only)
  - fresh hunt: monarch butterfly via OGA (CC0, 'animated butterfly') ->
    background flood-fill removal
  - PIL originals: spider, ice, earth, treasures, power-up icons,
    special overlays, sky backgrounds, board cell, thumbnail

Every output lands in projects/gogabox/assets/games/matcher/ (+ thumbs,
+ audio). Deterministic; re-runnable.
"""
import os
import shutil
import math
import random
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HIST = "/home/z/candyrush_history/projects/candyrush/assets"
KP = "/tmp/asset_hunt/kp/PNG"
BUTTERFLY_SRC = "/tmp/asset_hunt/butterfly2.png"
OUT = os.path.join(ROOT, "projects/gogabox/assets/games/matcher")
SFX_OUT = os.path.join(ROOT, "projects/gogabox/assets/audio/sfx")
MUS_OUT = os.path.join(ROOT, "projects/gogabox/assets/audio/music")
THUMB_OUT = os.path.join(ROOT, "projects/gogabox/assets/thumbs")

GEM_COLS = [(110, 190, 235), (232, 76, 96), (110, 200, 120),
            (245, 196, 70), (196, 120, 220)]  # azure ruby emerald citrine amethyst


def ensure_dirs():
    for d in [OUT, os.path.join(OUT, "gems"), os.path.join(OUT, "fx"),
              os.path.join(OUT, "modes"), os.path.join(OUT, "power"),
              os.path.join(OUT, "specials"), os.path.join(OUT, "bg"),
              SFX_OUT, MUS_OUT, THUMB_OUT]:
        os.makedirs(d, exist_ok=True)


def copy_history():
    """The candyrush CC0 provenance (assets.manifest.json documents it)."""
    pairs = [
        ("sprites/gems/gem_%d.png", "gems/gem_%d.png", 5),
        ("sprites/candy/base_%d.png", "gems/candy_%d.png", 5),
        ("sprites/fx/explosion_%d.png", "fx/explosion_%d.png", 8),
    ]
    for src_fmt, dst_fmt, n in pairs:
        for i in range(n):
            shutil.copy(os.path.join(HIST, src_fmt % i),
                        os.path.join(OUT, dst_fmt % i))
    # audio provenance
    audio = {"audio/pops/pop_1.wav": "pop_1.wav", "audio/pops/pop_2.wav": "pop_2.wav",
             "audio/pops/pop_3.wav": "pop_3.wav", "audio/pops/pop_4.wav": "pop_4.wav",
             "audio/pops/pop_deep.ogg": "pop_deep.ogg",
             "audio/synth/swap.wav": "m_swap.wav", "audio/synth/sparkle.wav": "m_special.wav",
             "audio/synth/star.wav": "m_star.wav", "audio/synth/coin.wav": "m_coin.wav",
             "audio/synth/boom.wav": "m_boom.wav", "audio/synth/lose.wav": "m_fail.wav",
             "audio/jingles/win.ogg": "m_win.ogg"}
    for src, dst in audio.items():
        shutil.copy(os.path.join(HIST, src), os.path.join(SFX_OUT, dst))
    shutil.copy(os.path.join(HIST, "audio/music/loop.mp3"),
                os.path.join(MUS_OUT, "matcher_happy.mp3"))
    print("history copies done")


def soft_circle(size, color, hardness=1.0):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = size // 2
    for r in range(c, 0, -2):
        a = int(255 * (1 - r / c) ** (2.2 / max(0.2, hardness)))
        d.ellipse([c - r, c - r, c + r, c + r], fill=color + (min(255, a),))
    return im


def radial_sprite(size, inner, outer):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = size / 2
    for r in range(int(c), 0, -1):
        t = r / c
        col = tuple(int(inner[i] * (1 - t) + outer[i] * t) for i in range(3))
        d.ellipse([c - r, c - r, c + r, c + r], fill=col + (255,))
    return im


def rounded(dc, box, rad, **kw):
    dc.rounded_rectangle(box, radius=rad, **kw)


def kenney(name, size, tint=(255, 255, 255)):
    """Kenney particle textures are additive (white on black). Convert
    luminance -> alpha so they layer cleanly over anything."""
    im = Image.open(os.path.join(KP, name)).convert("L")
    im = im.resize((size, size), Image.LANCZOS)
    out = Image.new("RGBA", (size, size), tint + (0,))
    px = out.load()
    src = im.load()
    for y in range(size):
        for x in range(size):
            a = src[x, y]
            if a:
                px[x, y] = tint + (a,)
    return out


def butterfly():
    """Flood-fill the (235,235,235) studio background away, crop tight."""
    im = Image.open(BUTTERFLY_SRC).convert("RGBA")
    w, h = im.size
    px = im.load()
    bg = (235, 235, 235)
    from collections import deque
    seen = bytearray(w * h)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            q.append((x, y))
    def close(c):
        return abs(c[0] - bg[0]) < 26 and abs(c[1] - bg[1]) < 26 and abs(c[2] - bg[2]) < 26
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or seen[y * w + x]:
            continue
        seen[y * w + x] = 1
        if not close(px[x, y]):
            continue
        px[x, y] = (0, 0, 0, 0)
        q.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])
    box = im.getbbox()
    im = im.crop(box)
    side = max(im.size)
    sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    sq.paste(im, ((side - im.width) // 2, (side - im.height) // 2))
    sq = sq.resize((128, 128), Image.LANCZOS)
    sq.save(os.path.join(OUT, "modes", "butterfly.png"))
    print("butterfly ok", box)


def spider():
    """The friendly keeper of the top - round, purple, big glossy eyes."""
    S = 160
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    body = (126, 92, 180)
    dark = (92, 64, 140)
    # thread
    d.line([(S // 2, 0), (S // 2, 34)], fill=(240, 240, 245, 200), width=3)
    # legs (4 per side, arced)
    for i, (sx, sy, ex, ey) in enumerate([
            (52, 78, 18, 58), (50, 96, 12, 96), (52, 112, 18, 130),
            (108, 78, 142, 58), (110, 96, 148, 96), (108, 112, 142, 130)]):
        d.line([(sx, sy), ((sx + ex) // 2, (sy + ey) // 2 - 10), (ex, ey)],
               fill=dark + (255,), width=7)
    # body
    d.ellipse([44, 44, 116, 128], fill=body + (255,))
    d.ellipse([44, 44, 116, 128], outline=dark + (255,), width=4)
    # belly shine
    d.ellipse([56, 54, 80, 74], fill=(200, 178, 235, 160))
    # eyes
    for cx in (72, 92):
        d.ellipse([cx - 13, 76, cx + 13, 104], fill=(255, 255, 255, 255))
        d.ellipse([cx - 6, 84, cx + 6, 98], fill=(30, 26, 48, 255))
        d.ellipse([cx - 3, 85, cx + 2, 90], fill=(255, 255, 255, 220))
    # smile
    d.arc([70, 102, 94, 118], 20, 160, fill=dark + (255,), width=4)
    im.save(os.path.join(OUT, "modes", "spider.png"))
    print("spider ok")


def ice_tiles():
    """Stackable ice layers - translucent crystal blocks with cracks."""
    for layer in range(1, 4):
        S = 120
        im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        alpha = 150 + layer * 25
        rounded(d, [8, 8, S - 8, S - 8], 18, fill=(150, 205, 245, alpha),
                outline=(210, 236, 255, 230), width=4)
        # inner shine
        rounded(d, [16, 14, S - 16, 46], 14, fill=(235, 248, 255, 130))
        rng = random.Random(77 + layer)
        for _ in range(3 + layer):
            x1, y1 = rng.randint(20, S - 40), rng.randint(30, S - 30)
            pts = [(x1, y1)]
            for _ in range(3):
                pts.append((pts[-1][0] + rng.randint(-22, 22), pts[-1][1] + rng.randint(8, 26)))
            d.line(pts, fill=(225, 244, 255, 170), width=3)
        im.save(os.path.join(OUT, "modes", "ice_%d.png" % layer))
    print("ice ok")


def earth_tiles():
    """Warm buried earth + a dug-edge highlight; treasures sit inside."""
    rng = random.Random(4242)
    S = 120
    base = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(base)
    rounded(d, [6, 6, S - 6, S - 6], 14, fill=(146, 100, 62, 255),
            outline=(110, 72, 44, 255), width=5)
    for _ in range(46):
        x, y = rng.randint(12, S - 12), rng.randint(12, S - 12)
        r = rng.randint(2, 5)
        col = rng.choice([(120, 80, 48), (166, 122, 80), (98, 64, 40)])
        d.ellipse([x - r, y - r, x + r, y + r], fill=col + (255,))
    # roots
    for _ in range(5):
        x1, y1 = rng.randint(14, S - 14), rng.randint(14, S - 14)
        d.arc([x1, y1, x1 + rng.randint(20, 46), y1 + rng.randint(14, 30)],
              rng.randint(0, 180), rng.randint(180, 320), fill=(104, 70, 42, 255), width=3)
    base.save(os.path.join(OUT, "modes", "earth.png"))
    print("earth ok")


def treasure_sprites():
    # GOLD nugget
    S = 110
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.polygon([(24, 78), (14, 52), (34, 28), (66, 20), (92, 40), (96, 66), (74, 88), (40, 90)],
              fill=(244, 186, 58, 255), outline=(180, 124, 24, 255))
    d.polygon([(34, 28), (66, 20), (72, 40), (44, 48)], fill=(255, 226, 128, 255))
    d.ellipse([52, 52, 68, 66], fill=(255, 240, 170, 200))
    im.save(os.path.join(OUT, "modes", "gold.png"))
    # DIAMOND
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.polygon([(55, 14), (92, 44), (55, 96), (18, 44)],
              fill=(128, 214, 246, 255), outline=(58, 150, 200, 255))
    d.polygon([(55, 14), (92, 44), (55, 50)], fill=(206, 242, 255, 255))
    d.polygon([(55, 50), (92, 44), (55, 96)], fill=(88, 176, 224, 255))
    d.line([(18, 44), (92, 44)], fill=(230, 248, 255, 220), width=3)
    im.save(os.path.join(OUT, "modes", "diamond.png"))
    # ARTIFACT (a little golden amphora)
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([34, 34, 76, 92], fill=(214, 158, 74, 255), outline=(150, 100, 34, 255))
    d.rectangle([44, 20, 66, 40], fill=(226, 176, 96, 255), outline=(150, 100, 34, 255))
    d.ellipse([40, 12, 70, 28], fill=(226, 176, 96, 255), outline=(150, 100, 34, 255))
    d.arc([30, 44, 50, 76], 60, 250, fill=(150, 100, 34, 255), width=5)
    d.arc([60, 44, 80, 76], 290, 120 + 360, fill=(150, 100, 34, 255), width=5)
    d.arc([44, 52, 66, 70], 20, 160, fill=(255, 226, 150, 255), width=3)
    im.save(os.path.join(OUT, "modes", "artifact.png"))
    print("treasures ok")


def power_icons():
    """96px tap-power icons: shuffle / line blast / gem bomb / color vapor."""
    S = 96
    # SHUFFLE - two curved arrows in a loop
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.arc([12, 22, 84, 74], 200, 340, fill=(90, 170, 245, 255), width=9)
    d.arc([12, 30, 84, 82], 20, 160, fill=(90, 170, 245, 255), width=9)
    d.polygon([(78, 34), (94, 46), (74, 52)], fill=(90, 170, 245, 255))
    d.polygon([(18, 62), (2, 50), (22, 44)], fill=(90, 170, 245, 255))
    im.save(os.path.join(OUT, "power", "p_shuffle.png"))
    # LINE BLAST - cross burst
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for ang in range(0, 180, 45):
        a = math.radians(ang)
        x2, y2 = S / 2 + 40 * math.cos(a), S / 2 + 40 * math.sin(a)
        x3, y3 = S / 2 - 40 * math.cos(a), S / 2 - 40 * math.sin(a)
        d.line([(x3, y3), (x2, y2)], fill=(255, 176, 64, 255), width=8)
    d.ellipse([38, 38, 58, 58], fill=(255, 224, 130, 255), outline=(255, 176, 64, 255))
    im.save(os.path.join(OUT, "power", "p_line.png"))
    # GEM BOMB - round bomb + sparkle fuse
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([22, 34, 74, 86], fill=(70, 74, 96, 255), outline=(40, 44, 62, 255))
    d.ellipse([32, 44, 46, 58], fill=(120, 126, 152, 255))
    d.line([(60, 36), (72, 22)], fill=(150, 100, 50, 255), width=6)
    st = kenney("star_02.png", 34, (255, 220, 120))
    im.alpha_composite(st, (62, 6))
    im.save(os.path.join(OUT, "power", "p_bomb.png"))
    # COLOR VAPOR - gem dissolving into rainbow drops
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.polygon([(48, 12), (78, 38), (48, 78), (18, 38)], fill=(150, 120, 230, 255),
              outline=(100, 70, 190, 255))
    rng = random.Random(9)
    for i, col in enumerate([(240, 90, 90), (250, 170, 60), (120, 210, 110),
                             (90, 170, 245), (170, 110, 220)]):
        x = 20 + i * 14 + rng.randint(-3, 3)
        y = 84 + rng.randint(-4, 4)
        d.ellipse([x - 5, y - 5, x + 5, y + 5], fill=col + (255,))
    im.save(os.path.join(OUT, "power", "p_vapor.png"))
    print("power icons ok")


def special_overlays():
    """Skin-safe specials: VFX textures layered ON TOP of any base gem."""
    S = 128
    # FLAME ring - Kenney flame + ember glow ring
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ring = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    rd = ImageDraw.Draw(ring)
    for w, a in [(16, 90), (10, 150), (5, 230)]:
        rd.ellipse([S // 2 - 52, S // 2 - 52, S // 2 + 52, S // 2 + 52],
                   outline=(255, 120 + 40, 40, a), width=w)
    ring = ring.filter(ImageFilter.GaussianBlur(2))
    im.alpha_composite(ring)
    fl = kenney("flame_01.png", 64, (255, 190, 90))
    im.alpha_composite(fl, (S // 2 - 32, S // 2 - 32))
    im.save(os.path.join(OUT, "specials", "ov_flame.png"))
    # STAR sparkle - Kenney 4-point flare, white
    st = kenney("star_01.png", 120)
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    im.alpha_composite(st, (4, 4))
    im.save(os.path.join(OUT, "specials", "ov_star.png"))
    # HYPERCUBE prism - rainbow rounded square + white flare core
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    px = im.load()
    cols = [(240, 92, 92), (250, 176, 64), (244, 220, 80), (110, 206, 116),
            (96, 176, 244), (164, 116, 226)]
    for y in range(20, 108):
        t = (y - 20) / 88.0
        ci = min(4, int(t * 5))
        ft = t * 5 - ci
        col = tuple(int(cols[ci][i] * (1 - ft) + cols[ci + 1][i] * ft) for i in range(3))
        for x in range(20, 108):
            px[x, y] = col + (235,)
    mask = Image.new("L", (S, S), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle([20, 20, 108, 108], radius=26, fill=255)
    im.putalpha(mask)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([20, 20, 108, 108], radius=26, outline=(255, 255, 255, 240), width=5)
    st = kenney("star_01.png", 76)
    im.alpha_composite(st, (26, 26))
    im.save(os.path.join(OUT, "specials", "ov_hyper.png"))
    print("specials ok")


def sky_backgrounds():
    """The happy daylight sky (default) + the PEACE pastel twin."""
    W, H = 1080, 1920
    for name, top, mid, bot, sun in [
            ("bg_day", (126, 196, 240), (196, 228, 246), (255, 236, 200), (1080, 1650)),
            ("bg_peace", (168, 210, 235), (226, 226, 240), (255, 224, 224), (540, 1700))]:
        im = Image.new("RGB", (W, H))
        px = im.load()
        for y in range(H):
            t = y / H
            if t < 0.55:
                u = t / 0.55
                col = tuple(int(top[i] * (1 - u) + mid[i] * u) for i in range(3))
            else:
                u = (t - 0.55) / 0.45
                col = tuple(int(mid[i] * (1 - u) + bot[i] * u) for i in range(3))
            for x in range(W):
                px[x, y] = col
        im = im.convert("RGBA")
        # sun glow (bottom corner - warm)
        glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        for r in range(560, 40, -12):
            a = int(70 * (1 - r / 560.0))
            gd.ellipse([sun[0] - r, sun[1] - r, sun[0] + r, sun[1] + r],
                       fill=(255, 232, 170, a))
        glow = glow.filter(ImageFilter.GaussianBlur(30))
        im.alpha_composite(glow)
        # bokeh bubbles (slow, soft, floating)
        rng = random.Random(2026)
        bok = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        bd = ImageDraw.Draw(bok)
        for _ in range(26):
            x, y = rng.randint(0, W), rng.randint(0, H)
            r = rng.randint(14, 60)
            a = rng.randint(14, 40)
            bd.ellipse([x - r, y - r, x + r, y + r], outline=(255, 255, 255, a + 10), width=3)
            bd.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, max(4, a // 3)))
        bok = bok.filter(ImageFilter.GaussianBlur(2))
        im.alpha_composite(bok)
        # distant soft hills at the very bottom (green, welcoming)
        hills = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        hd = ImageDraw.Draw(hills)
        hd.ellipse([-300, H - 210, 480, H + 140], fill=(148, 206, 138, 235))
        hd.ellipse([300, H - 240, 1180, H + 120], fill=(126, 192, 122, 235))
        im.alpha_composite(hills)
        im.convert("RGB").save(os.path.join(OUT, "bg", name + ".png"))
    print("backgrounds ok")


def board_cell():
    S = 120
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rounded(d, [8, 8, S - 8, S - 8], 20, fill=(255, 255, 255, 84),
            outline=(255, 255, 255, 120), width=3)
    im.save(os.path.join(OUT, "bg", "cell.png"))
    # the board plate behind all cells
    im2 = Image.new("RGBA", (8 * S + 24, 8 * S + 24), (0, 0, 0, 0))
    d2 = ImageDraw.Draw(im2)
    rounded(d2, [0, 0, im2.width - 1, im2.height - 1], 34, fill=(255, 255, 255, 66),
            outline=(255, 255, 255, 90), width=4)
    im2.save(os.path.join(OUT, "bg", "plate.png"))
    print("board ok")


def mode_cards():
    """Mode picker card art (460x240): a scene vignette per mode."""
    W, H = 460, 240
    g0 = Image.open(os.path.join(OUT, "gems", "gem_0.png")).convert("RGBA")
    g1 = Image.open(os.path.join(OUT, "gems", "gem_1.png")).convert("RGBA")
    g2 = Image.open(os.path.join(OUT, "gems", "gem_2.png")).convert("RGBA")
    sp = Image.open(os.path.join(OUT, "specials", "ov_hyper.png")).convert("RGBA")

    def base_card(top, bot):
        im = Image.new("RGBA", (W, H))
        px = im.load()
        for y in range(H):
            t = y / H
            col = tuple(int(top[i] * (1 - t) + bot[i] * t) for i in range(3))
            for x in range(W):
                px[x, y] = col + (255,)
        d = ImageDraw.Draw(im)
        rounded(d, [6, 6, W - 6, H - 6], 26, outline=(255, 255, 255, 170), width=5)
        return im

    # CHALLENGE - the timer cup + gems
    im = base_card((255, 214, 120), (255, 176, 96))
    for i, g in enumerate([g1, g0, g2]):
        im.alpha_composite(g.resize((86, 86)), (60 + i * 100, 120))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([150, 34, 310, 96], radius=30, fill=(255, 250, 236, 235),
                        outline=(214, 138, 48, 255), width=5)
    d.ellipse([268, 40, 296, 68], fill=(255, 120, 90, 255))
    d.ellipse([164, 62, 192, 90], fill=(255, 120, 90, 255))
    im.save(os.path.join(OUT, "modes", "card_challenge.png"))
    # PEACE - pastel lotus pond
    im = base_card((186, 226, 236), (232, 200, 226))
    d = ImageDraw.Draw(im)
    for ang, cx in [(-40, 190), (0, 230), (40, 270)]:
        a = math.radians(ang - 90)
        d.ellipse([cx - 34, 110 + 30 * abs(ang) / 40 - 20, cx + 34, 190 + 30 * abs(ang) / 40 + 20],
                  fill=(250, 214, 228, 235), outline=(214, 150, 178, 255))
    d.ellipse([214, 128, 246, 160], fill=(255, 236, 170, 255))
    im.alpha_composite(g2.resize((72, 72)), (60, 130))
    im.alpha_composite(g0.resize((72, 72)), (330, 130))
    im.save(os.path.join(OUT, "modes", "card_peace.png"))
    # BUTTERFLIES - monarch + spider corner
    im = base_card((168, 214, 244), (210, 236, 208))
    bf = Image.open(os.path.join(OUT, "modes", "butterfly.png")).convert("RGBA").resize((110, 110))
    spid = Image.open(os.path.join(OUT, "modes", "spider.png")).convert("RGBA").resize((110, 110))
    im.alpha_composite(bf, (60, 40))
    im.alpha_composite(bf.resize((80, 80)), (200, 90))
    im.alpha_composite(spid, (320, 110))
    im.save(os.path.join(OUT, "modes", "card_butterflies.png"))
    # ICE STORM - ice columns
    im = base_card((150, 200, 240), (222, 242, 252))
    ice = Image.open(os.path.join(OUT, "modes", "ice_2.png")).convert("RGBA").resize((90, 90))
    for i in range(4):
        for j in range(2 - (i % 2)):
            im.alpha_composite(ice, (48 + i * 100, 140 - j * 88))
    im.alpha_composite(g0.resize((80, 80)), (300, 60))
    im.save(os.path.join(OUT, "modes", "card_ice.png"))
    # DIAMOND MINE - earth + gold
    im = base_card((196, 150, 104), (246, 214, 150))
    ea = Image.open(os.path.join(OUT, "modes", "earth.png")).convert("RGBA").resize((90, 90))
    gd = Image.open(os.path.join(OUT, "modes", "gold.png")).convert("RGBA").resize((84, 84))
    dm = Image.open(os.path.join(OUT, "modes", "diamond.png")).convert("RGBA").resize((84, 84))
    for i in range(3):
        im.alpha_composite(ea, (52 + i * 96, 130))
    im.alpha_composite(gd, (100, 44))
    im.alpha_composite(dm, (270, 52))
    im.save(os.path.join(OUT, "modes", "card_mine.png"))
    print("mode cards ok")


def thumbnail():
    """960x640 box thumbnail - the happy gem wall."""
    W, H = 960, 640
    bg = Image.open(os.path.join(OUT, "bg", "bg_day.png")).convert("RGBA").resize((W, H))
    im = bg
    d = ImageDraw.Draw(im)
    # gem wall rows
    gs = [Image.open(os.path.join(OUT, "gems", "gem_%d.png" % i)).convert("RGBA").resize((104, 104))
          for i in range(5)]
    for r in range(3):
        for c in range(9):
            g = gs[(r * 3 + c) % 5]
            jx = (r % 2) * 52
            im.alpha_composite(g, (c * 104 - 10 + jx - 40, 200 + r * 110 - 40))
    # hypercube hero + flame
    hyper = Image.open(os.path.join(OUT, "specials", "ov_hyper.png")).convert("RGBA").resize((170, 170))
    im.alpha_composite(hyper, (730, 40))
    flame = Image.open(os.path.join(OUT, "specials", "ov_flame.png")).convert("RGBA").resize((150, 150))
    im.alpha_composite(flame, (80, 30))
    # title band
    d.rounded_rectangle([120, 520, 840, 620], radius=40, fill=(255, 252, 240, 225),
                        outline=(214, 138, 48, 255), width=6)
    try:
        f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 64)
    except Exception:
        f = ImageFont.load_default()
    d.text((480, 568), "MATCHER", font=f, fill=(196, 96, 40), anchor="mm")
    im.convert("RGB").save(os.path.join(THUMB_OUT, "matcher.png"))
    print("thumb ok")


if __name__ == "__main__":
    ensure_dirs()
    copy_history()
    butterfly()
    spider()
    ice_tiles()
    earth_tiles()
    treasure_sprites()
    power_icons()
    special_overlays()
    sky_backgrounds()
    board_cell()
    mode_cards()
    thumbnail()
    print("ALL v0.3.3 matcher art done")
