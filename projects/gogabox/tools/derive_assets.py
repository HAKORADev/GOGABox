#!/usr/bin/env python3
# ============================================================================
# GOGABox asset derive - deterministic, idempotent, CC0-only.
#   - copies CC0 audio/font sources already vendored in the arsenal
#   - synthesizes the missing sfx (numpy -> wav, reproducible envelopes)
#   - draws all box chrome + game sprites with PIL (no hand-made binaries)
#   - generates 480x320 menu thumbnails for every registry game
# Re-run any time: python3 tools/derive_assets.py
# ============================================================================
import math, os, shutil, struct, wave

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))   # projects/gogabox
ASSETS = os.path.join(ROOT, "assets")
CANDY = os.path.join(ROOT, "..", "candyrush", "assets")
CACHE_FONT = "/tmp/kf/Fonts"          # from kenney.nl CC0 pack (scraped URL below)
KENNEY_FONTS_URL = ("https://kenney.nl/media/pages/assets/kenney-fonts/"
                    "8d5435c213-1677661710/kenney_kenney-fonts.zip")

INK = (53, 33, 15)
CARD = (255, 243, 220)
ACCENT = (255, 176, 32)
HOT = (255, 122, 26)
GOOD = (88, 196, 112)
COIN = (255, 201, 60)
BAD = (232, 87, 74)


def out(path):
    p = os.path.join(ASSETS, path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    return p


def ensure_fonts():
    d = out("fonts")
    src = CACHE_FONT
    if not os.path.isdir(src):
        os.makedirs("/tmp/kf", exist_ok=True)
        import subprocess, zipfile
        z = "/tmp/kf.zip"
        subprocess.run(["curl", "-sL", KENNEY_FONTS_URL, "-o", z], check=False)
        try:
            with zipfile.ZipFile(z) as zf:
                zf.extractall("/tmp/kf")
        except Exception as e:
            print("font download failed:", e)
            return False
    for name, dst in [("Kenney Rocket.ttf", "Kenney_Rocket.ttf"),
                      ("Kenney Mini.ttf", "Kenney_Mini.ttf")]:
        s = os.path.join(src, name)
        if os.path.exists(s):
            shutil.copy(s, os.path.join(d, dst))
            print("font:", dst)
    return os.path.exists(os.path.join(d, "Kenney_Rocket.ttf"))


def font(size, big=True):
    p = os.path.join(ASSETS, "fonts", "Kenney_Rocket.ttf" if big else "Kenney_Mini.ttf")
    if os.path.exists(p):
        return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def rounded(draw, box, r, fill=None, outline=None, width=1):
    draw.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)


# ============================================================ box chrome

def bg_main():
    W, H = 720, 1280
    img = Image.new("RGB", (W, H))
    top, bot = (58, 35, 19), (36, 20, 7)
    px = img.load()
    for y in range(H):
        t = y / H
        px_row = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3))
        for x in range(W):
            px[x, y] = px_row
    d = ImageDraw.Draw(img, "RGBA")
    # diagonal arcade stripes
    for i in range(-H, W + H, 90):
        d.polygon([(i, H), (i + 34, H), (i + H + 34, 0), (i + H, 0)],
                  fill=(255, 176, 32, 10))
    # soft vignette dots (arcade carpet)
    # v0.1.5 OWNER CALL ("weird dots, 3 dots per line"): RETIRED. This 5x6
    # grid of alpha-14 ellipses was the true source of the baked dots - the
    # shader recreation AND this generator both carried them. The carpet is
    # gone everywhere now; the field is pure gradient + stripes. Do NOT
    # reintroduce dot overlays here without an owner call.
    # for gy in range(6):
    #     for gx in range(5):
    #         x, y = 72 + gx * 144, 90 + gy * 220
    #         d.ellipse([x - 5, y - 5, x + 5, y + 5], fill=(255, 220, 160, 14))
    img.save(out("ui/bg_main.png"))
    print("ui/bg_main.png")


def logo():
    img = Image.new("RGBA", (500, 148), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    f = font(74)
    text = "GOGABox"
    bb = d.textbbox((0, 0), text, font=f)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    x, y = (500 - tw) // 2, (148 - th) // 2 - bb[1]
    # chunky shadow + two-tone
    d.text((x + 5, y + 6), text, font=f, fill=(0, 0, 0, 140))
    d.text((x, y), text, font=f, fill=HOT)
    d.text((x, y), "GOGA", font=f, fill=ACCENT)
    img.save(out("ui/logo.png"))
    print("ui/logo.png")


def coin(path="ui/coin.png", size=128):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    m = size // 16
    d.ellipse([m, m, size - m, size - m], fill=(160, 110, 20))
    d.ellipse([m * 2, m * 2, size - m * 2, size - m * 2], fill=COIN)
    d.ellipse([m * 3, m * 3, size - m * 3, size - m * 3], outline=(255, 235, 160), width=max(2, size // 40))
    f = font(int(size * 0.52))
    bb = d.textbbox((0, 0), "G", font=f)
    d.text(((size - bb[2] + bb[0]) / 2 - bb[0], (size - bb[3] + bb[1]) / 2 - bb[1]),
           "G", font=f, fill=(150, 100, 15))
    img.save(out(path))
    print(path)


def icons():
    # lock
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rounded(d, [24, 56, 104, 116], 14, fill=CARD)
    d.arc([40, 18, 88, 66], 180, 360, fill=CARD, width=12)
    d.ellipse([56, 74, 72, 90], fill=INK)
    img.save(out("ui/icon_lock.png"))
    print("ui/icon_lock.png")
    # gear
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = 64, 64
    for i in range(8):
        a = i * math.pi / 4
        x1, y1 = cx + 58 * math.cos(a), cy + 58 * math.sin(a)
        rounded(d, [x1 - 11, y1 - 11, x1 + 11, y1 + 11], 5, fill=CARD)
    d.ellipse([30, 30, 98, 98], fill=CARD)
    d.ellipse([48, 48, 80, 80], fill=INK)
    img.save(out("ui/icon_gear.png"))
    print("ui/icon_gear.png")
    # trophy
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rounded(d, [34, 18, 94, 70], 12, fill=COIN)
    d.rectangle([56, 66, 72, 92], fill=COIN)
    d.rectangle([42, 92, 86, 106], fill=COIN)
    d.arc([18, 20, 44, 60], 90, 270, fill=COIN, width=10)
    d.arc([84, 20, 110, 60], 270, 90, fill=COIN, width=10)
    img.save(out("ui/icon_trophy.png"))
    print("ui/icon_trophy.png")


# ============================================================ snake

def _snake_palette(kind):
    base = {"classic": (70, 160, 96), "lava": (208, 90, 48),
            "ice": (74, 168, 216), "gold": (216, 176, 32)}[kind]
    dark = tuple(int(c * 0.72) for c in base)
    return base, dark


def snake_sprites():
    d_dir = out("games/snake")
    # apple (fresh draw, crisp at 100px)
    img = Image.new("RGBA", (100, 100), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([10, 22, 90, 96], fill=(200, 50, 60))
    d.ellipse([18, 30, 62, 80], fill=(235, 90, 80))
    d.rectangle([47, 8, 53, 30], fill=(110, 70, 40))
    d.ellipse([52, 6, 76, 26], fill=(90, 170, 70))
    img.save(os.path.join(d_dir, "apple.png"))

    for kind in ["classic", "lava", "ice", "gold"]:
        base, dark = _snake_palette(kind)
        # body: rounded square with inner highlight
        img = Image.new("RGBA", (CELL := 96, CELL), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        rounded(d, [4, 4, 92, 92], 26, fill=dark)
        rounded(d, [12, 12, 84, 84], 20, fill=base)
        rounded(d, [20, 18, 76, 40], 12, fill=tuple(min(255, c + 36) for c in base))
        img.save(os.path.join(d_dir, f"body_{kind}.png"))
        # head: body + eyes + tongue-friendly front
        img = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        rounded(d, [4, 4, 92, 92], 30, fill=dark)
        rounded(d, [12, 12, 84, 84], 24, fill=base)
        rounded(d, [20, 18, 76, 40], 12, fill=tuple(min(255, c + 36) for c in base))
        for ex in [30, 66]:
            d.ellipse([ex - 10, 46, ex + 10, 66], fill=(255, 255, 255))
            d.ellipse([ex - 4, 52, ex + 4, 62], fill=(20, 20, 20))
        img.save(os.path.join(d_dir, f"head_{kind}.png"))
    print("games/snake/*")


# ============================================================ lanes

def lanes_sprites():
    d_dir = out("games/lanes")
    # ship
    img = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(80, 8), (130, 120), (80, 100), (30, 120)], fill=(0, 229, 255))
    d.polygon([(80, 26), (114, 112), (80, 96), (46, 112)], fill=(120, 245, 255))
    d.ellipse([66, 52, 94, 80], fill=(10, 40, 60))
    d.polygon([(52, 118), (70, 100), (70, 130)], fill=HOT)
    d.polygon([(108, 118), (90, 100), (90, 130)], fill=HOT)
    img.save(os.path.join(d_dir, "ship.png"))
    # obstacle block
    img = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rounded(d, [10, 10, 150, 150], 24, fill=(70, 40, 120))
    rounded(d, [22, 22, 138, 138], 18, fill=(110, 70, 190))
    for i in range(3):
        y = 40 + i * 34
        d.line([34, y, 126, y], fill=(255, 255, 255, 60), width=10)
    img.save(os.path.join(d_dir, "block.png"))
    print("games/lanes/*")


# ============================================================ rally

def rally_sprites():
    d_dir = out("games/rally")
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([16, 16, 112, 112], fill=(255, 255, 255))
    d.ellipse([28, 28, 100, 100], fill=(245, 245, 245))
    d.ellipse([44, 44, 84, 84], fill=(255, 176, 32))
    img.save(os.path.join(d_dir, "ball.png"))
    img = Image.new("RGBA", (192, 56), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rounded(d, [4, 4, 188, 52], 24, fill=(255, 122, 26))
    rounded(d, [12, 10, 180, 30], 14, fill=(255, 176, 32))
    img.save(os.path.join(d_dir, "paddle.png"))
    print("games/rally/*")


# ============================================================ hopper

def hopper_sprites():
    d_dir = out("games/hopper")
    # snowy platform
    img = Image.new("RGBA", (300, 76), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rounded(d, [0, 16, 300, 72], 20, fill=(120, 96, 74))
    rounded(d, [0, 6, 300, 40], 18, fill=(250, 252, 255))
    for i in range(6):
        x = 18 + i * 48
        d.ellipse([x, 2 + (i % 2) * 3, x + 22, 20 + (i % 2) * 3], fill=(255, 255, 255))
    img.save(os.path.join(d_dir, "platform.png"))
    # player: snowball with scarf + eyes
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([10, 10, 118, 118], fill=(235, 245, 252))
    d.ellipse([22, 22, 106, 106], fill=(250, 253, 255))
    for ex in [44, 84]:
        d.ellipse([ex - 8, 46, ex + 8, 64], fill=(20, 25, 35))
        d.ellipse([ex - 3, 49, ex + 3, 56], fill=(255, 255, 255))
    d.arc([44, 66, 84, 96], 20, 160, fill=(120, 140, 160), width=5)
    d.rectangle([26, 84, 102, 98], fill=BAD)
    img.save(os.path.join(d_dir, "player.png"))
    print("games/hopper/*")


# ============================================================ slasher

def slasher_sprites():
    d_dir = out("games/slasher")
    # fruits: reuse candyrush CC0 pixel fruits, brightened + upscaled
    for i in range(5):
        src = os.path.join(CANDY, "sprites", "fruits", f"fruit_{i}.png")
        if os.path.exists(src):
            img = Image.open(src).convert("RGBA").resize((160, 160), Image.NEAREST)
        else:
            img = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
            d = ImageDraw.Draw(img)
            d.ellipse([20, 20, 140, 140], fill=(240, 140, 40))
        img.save(os.path.join(d_dir, f"fruit_{i}.png"))
    # golden fruit (recolor of fruit_0 hue -> gold)
    src = os.path.join(d_dir, "fruit_0.png")
    img = Image.open(src).convert("RGBA")
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a > 0:
                px[x, y] = (min(255, int(r * 1.15)), max(60, int(g * 0.82)), int(b * 0.25), a)
    img.save(os.path.join(d_dir, "fruit_gold.png"))
    # bomb
    img = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([20, 40, 140, 160], fill=(30, 30, 36))
    d.ellipse([34, 54, 96, 116], fill=(70, 70, 84))
    d.rectangle([74, 26, 86, 48], fill=(90, 90, 100))
    d.line([80, 30, 116, 10], fill=(160, 110, 40), width=8)
    d.ellipse([112, 2, 132, 22], fill=HOT)
    img.save(os.path.join(d_dir, "bomb.png"))
    print("games/slasher/*")


# ============================================================ thumbnails

def _thumb_base(w=480, h=320):
    img = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(img)
    return img, d


def _thumb_vignette(img):
    ov = Image.new("L", img.size, 0)
    d = ImageDraw.Draw(ov)
    d.rectangle([0, 0, img.width, img.height], outline=90, width=60)
    ov = ov.filter(ImageFilter.GaussianBlur(50))
    dark = Image.new("RGB", img.size, (0, 0, 0))
    img.paste(dark, (0, 0), ov.point(lambda v: min(110, v)))


def _thumb_title(img, text, sub=""):
    d = ImageDraw.Draw(img)
    f = font(46)
    bb = d.textbbox((0, 0), text, font=f)
    tw = bb[2] - bb[0]
    x, y = (img.width - tw) // 2, img.height - 84 - (bb[3] - bb[1])
    d.rounded_rectangle([x - 16, y + bb[1] - 10, x + tw + 16, y + bb[3] + 12],
                        radius=12, fill=(0, 0, 0, 0))
    d.text((x + 3, y + 3), text, font=f, fill=(0, 0, 0))
    d.text((x, y), text, font=f, fill=(255, 250, 240))
    if sub:
        f2 = font(20, False)
        bb2 = d.textbbox((0, 0), sub, font=f2)
        d.text(((img.width - (bb2[2] - bb2[0])) // 2, img.height - 34), sub,
               font=f2, fill=(255, 220, 170))
    return img


def thumbs():
    t = os.path.join(ASSETS, "thumbs")
    os.makedirs(t, exist_ok=True)

    # v0.1.6: SNAKE and PONG RALLY thumbs are CAPTURED REAL GAMEPLAY now
    # (dev/thumb_capture + post.py -> 960x640, no text). The hand-drawn
    # scenes below are RETIRED for those two - do NOT re-run them, they
    # would clobber the captured assets. See docs/THUMBNAILS.md.
    #
    # SNAKE (retired v0.1.6 - superseded by the capture pipeline)
    # img, d = _thumb_base()
    # for i in range(480):
    #     d.line([(i, 0), (i, 320)], fill=(30 + i // 20, 60, 32))
    # for gy in range(6):
    #     for gx in range(9):
    #         if (gx + gy) % 2 == 0:
    #             d.rectangle([gx * 56, gy * 56, gx * 56 + 56, gy * 56 + 56],
    #                         fill=(34, 72, 36))
    # img = img.convert("RGBA")
    # body = Image.open(os.path.join(ASSETS, "games/snake/body_classic.png"))
    # head = Image.open(os.path.join(ASSETS, "games/snake/head_classic.png"))
    # apple = Image.open(os.path.join(ASSETS, "games/snake/apple.png"))
    # for i, c in enumerate([(120, 180), (176, 180), (232, 180), (232, 124), (232, 68)]):
    #     img.alpha_composite(body.resize((56, 56)), c)
    # img.alpha_composite(head.resize((56, 56)), (288, 180))
    # img.alpha_composite(apple.resize((56, 56)), (392, 124))
    # _thumb_title(img, "SNAKE", "eat, grow, grab coins")
    # img.convert("RGB").save(os.path.join(t, "snake.png"))
    #
    # PONG RALLY (retired v0.1.6 - superseded by the capture pipeline)
    # img, d = _thumb_base()
    # d.rectangle([0, 0, 480, 320], fill=(26, 16, 48))
    # for i in range(8):
    #     d.rectangle([236, i * 42, 244, i * 42 + 22], fill=(255, 255, 255, 24))
    # d.rounded_rectangle([40, 60, 90, 130], radius=16, fill=HOT)
    # d.rounded_rectangle([390, 190, 440, 260], radius=16, fill=ACCENT)
    # d.ellipse([210, 130, 270, 190], fill=(255, 255, 255))
    # _thumb_title(img, "PONG RALLY", "how long can you return?")
    # img.convert("RGB").save(os.path.join(t, "rally.png"))

    # GEOMETRY FLASH
    img, d = _thumb_base()
    d.rectangle([0, 0, 480, 320], fill=(20, 16, 40))
    for i in range(4):
        d.line([(120 + i * 80, 0), (120 + i * 80, 320)], fill=(0, 229, 255), width=3)
    ship = Image.open(os.path.join(ASSETS, "games/lanes/ship.png")).resize((96, 96))
    block = Image.open(os.path.join(ASSETS, "games/lanes/block.png")).resize((80, 80))
    img = img.convert("RGBA")
    img.alpha_composite(block, (136, 60))
    img.alpha_composite(block, (296, 140))
    img.alpha_composite(ship, (196, 200))
    _thumb_title(img, "GEOMETRY FLASH", "dodge the grid")
    img.convert("RGB").save(os.path.join(t, "lanes.png"))

    # FRUIT SLASHER
    img, d = _thumb_base()
    d.rectangle([0, 0, 480, 320], fill=(74, 47, 24))
    d.rectangle([0, 200, 480, 320], fill=(94, 62, 32))
    img = img.convert("RGBA")
    for i in range(3):
        f = Image.open(os.path.join(ASSETS, "games/slasher/fruit_%d.png" % i)).resize((96, 96))
        img.alpha_composite(f, (60 + i * 140, 60 + (i % 2) * 40))
    bomb = Image.open(os.path.join(ASSETS, "games/slasher/bomb.png")).resize((96, 96))
    img.alpha_composite(bomb, (340, 120))
    d = ImageDraw.Draw(img)
    d.line([(30, 260), (180, 170), (330, 210), (450, 120)], fill=(255, 255, 255), width=8)
    _thumb_title(img, "FRUIT SLASHER", "swipe sharp, slash smart")
    img.convert("RGB").save(os.path.join(t, "slasher.png"))

    # SNOWY TOWER
    img, d = _thumb_base()
    for y in range(320):
        t2 = y / 320
        d.line([(0, y), (480, y)],
               fill=(int(140 + 70 * t2), int(200 + 30 * t2), int(235 + 20 * t2)))
    img = img.convert("RGBA")
    plat = Image.open(os.path.join(ASSETS, "games/hopper/platform.png")).resize((200, 50))
    player = Image.open(os.path.join(ASSETS, "games/hopper/player.png")).resize((72, 72))
    img.alpha_composite(plat, (30, 210))
    img.alpha_composite(plat, (260, 140))
    img.alpha_composite(plat, (110, 70))
    img.alpha_composite(player, (160, 20))
    d = ImageDraw.Draw(img)
    for i in range(24):
        x, y = (i * 53) % 480, (i * 97) % 320
        d.ellipse([x, y, x + 6, y + 6], fill=(255, 255, 255))
    _thumb_title(img, "SNOWY TOWER", "climb till you slip")
    img.convert("RGB").save(os.path.join(t, "hopper.png"))

    # 2048
    img, d = _thumb_base()
    d.rectangle([0, 0, 480, 320], fill=(187, 173, 160))
    vals = [(2, "efe6d8"), (4, "edd9b0"), (8, "f2b179"), (16, "f59563"),
            (32, "f67c5f"), (64, "f65e3b"), (128, "edcf72"), (256, "edcc61")]
    f = font(52)
    for i, (v, c) in enumerate(vals):
        x, y = 24 + (i % 4) * 112, 24 + (i // 4) * 112
        d.rounded_rectangle([x, y, x + 100, y + 100], radius=12, fill="#" + c)
        bb = d.textbbox((0, 0), str(v), font=f)
        d.text((x + (100 - bb[2] + bb[0]) / 2 - bb[0], y + (100 - bb[3] + bb[1]) / 2 - bb[1]),
               str(v), font=f, fill=INK)
    _thumb_title(img, "2048", "swipe and double")
    img.convert("RGB").save(os.path.join(t, "merge.png"))

    # coming soon tiles - v0.1.6: universal 960x640 canvas (rule R1), same
    # design, everything scaled 2x from the old 480x320
    _thumbs_soon(t)
    print("thumbs/*")


def _thumbs_soon(t):
    names = {"dario": "DARIO", "hen": "HEN INVADERS", "spud": "COSMIC SPUD",
             "maze": "ESCAPE THE MAZE", "matcher": "MATCHER", "xo": "XO LADDER",
             "keys": "KEY SINGER", "poptd": "POP TD"}
    for key, title in names.items():
        img = Image.new("RGB", (960, 640))
        d = ImageDraw.Draw(img)
        d.rectangle([0, 0, 960, 640], fill=(52, 42, 66))
        for i in range(-640, 960, 180):
            d.polygon([(i, 640), (i + 60, 640), (i + 700, 0), (i + 640, 0)],
                      fill=(64, 52, 84))
        f = font(240)
        bb = d.textbbox((0, 0), "?", font=f)
        d.text(((960 - bb[2] + bb[0]) / 2, 80), "?", font=f, fill=(122, 108, 180))
        f2 = font(60)
        bb2 = d.textbbox((0, 0), title, font=f2)
        d.text(((960 - bb2[2] + bb2[0]) / 2, 420), title, font=f2, fill=(210, 200, 240))
        f3 = font(40, False)
        d.text(((960 - 128) / 2, 524), "SOON", font=f3, fill=(150, 130, 210))
        img.save(os.path.join(t, "%s.png" % key))


# ============================================================ audio

def audio():
    # CC0 copies from the vendored candy packs
    pairs = [
        ("audio/ui/click.ogg", "audio/ui/click.ogg"),
        ("audio/ui/confirm.ogg", "audio/ui/confirm.ogg"),
        ("audio/ui/buy.ogg", "audio/ui/buy.ogg"),
        ("audio/ui/error.ogg", "audio/ui/error.ogg"),
        ("audio/jingles/win.ogg", "audio/jingles/win.ogg"),
        ("audio/synth/lose.wav", "audio/jingles/lose.wav"),
        ("audio/synth/boom.wav", "audio/sfx/boom.wav"),
        ("audio/synth/coin.wav", "audio/sfx/coin.wav"),
        ("audio/synth/sparkle.wav", "audio/sfx/sparkle.wav"),
        ("audio/synth/star.wav", "audio/sfx/star.wav"),
        ("audio/synth/swap.wav", "audio/sfx/swap.wav"),
        ("audio/pops/pop_1.wav", "audio/sfx/pop_1.wav"),
        ("audio/pops/pop_2.wav", "audio/sfx/pop_2.wav"),
        ("audio/pops/pop_3.wav", "audio/sfx/pop_3.wav"),
        ("audio/pops/pop_4.wav", "audio/sfx/pop_4.wav"),
        ("audio/pops/pop_deep.ogg", "audio/sfx/pop_deep.ogg"),
        ("audio/music/loop.mp3", "audio/music/box_theme.mp3"),
    ]
    # Jukebox looks for pop.<ext> -> prefer pop_1 as "pop" alias
    for src, dst in pairs:
        s = os.path.join(CANDY, src)
        d = out(dst)
        if os.path.exists(s):
            shutil.copy(s, d)
    # "pop" alias used by games
    shutil.copy(out("audio/sfx/pop_1.wav"), out("audio/sfx/pop.wav"))
    # synthesized extras: hop + land (deterministic envelopes)
    _write_wav("audio/sfx/hop.wav", _chirp(520, 760, 0.12, 0.5))
    _write_wav("audio/sfx/land.wav", _thud())
    print("audio/*")


def _chirp(f0, f1, dur, vol):
    import numpy as np
    sr = 22050
    t = np.linspace(0, dur, int(sr * dur), False)
    f = np.linspace(f0, f1, t.size)
    phase = 2 * np.pi * np.cumsum(f) / sr
    env = np.exp(-6 * t / dur)
    return (np.sin(phase) * env * vol * 32767).astype(np.int16)


def _thud():
    import numpy as np
    sr = 22050
    dur = 0.09
    t = np.linspace(0, dur, int(sr * dur), False)
    env = np.exp(-26 * t)
    return ((np.sin(2 * np.pi * 150 * t) + 0.4 * np.sin(2 * np.pi * 90 * t)) * env * 0.5 * 32767).astype(np.int16)


def _write_wav(rel, samples):
    import numpy as np
    if samples.dtype != np.int16:
        samples = (samples * 32767).astype(np.int16)
    p = out(rel)
    with wave.open(p, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(22050)
        w.writeframes(samples.tobytes())


# ============================================================ icon

def app_icon():
    svg = '''<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512">
  <rect width="512" height="512" rx="96" fill="#3a2313"/>
  <rect x="24" y="24" width="464" height="464" rx="80" fill="#ffb020"/>
  <circle cx="256" cy="256" r="150" fill="#ffc93c" stroke="#e8a010" stroke-width="14"/>
  <text x="256" y="330" font-family="sans-serif" font-size="200" font-weight="bold"
        text-anchor="middle" fill="#8a5a14">G</text>
</svg>
'''
    with open(os.path.join(ROOT, "icon.svg"), "w") as f:
        f.write(svg)
    print("icon.svg")


if __name__ == "__main__":
    ok = ensure_fonts()
    if not ok:
        print("WARNING: Kenney fonts missing; PIL/Godot will use fallback")
    bg_main(); logo(); coin(); icons()
    snake_sprites(); lanes_sprites(); rally_sprites(); hopper_sprites(); slasher_sprites()
    thumbs(); audio(); app_icon()
    print("GOGABox assets derived OK")
