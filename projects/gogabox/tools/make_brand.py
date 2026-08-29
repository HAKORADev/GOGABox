#!/usr/bin/env python3
# ============================================================================
# GOGABox brand pack v2 - app icon (REAL letter G from the box display font),
# adaptive layers, boot splash, mystery tile art, meta icons (genres/subs/age),
# search glyph, notification glyph. Deterministic PIL.  python3 tools/make_brand.py
# ============================================================================
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))   # projects/gogabox
ASSETS = os.path.join(ROOT, "assets")
ICONS = os.path.join(ROOT, "icons")
META_ICONS = os.path.join(ASSETS, "meta")

ACCENT = (255, 176, 32)
HOT = (255, 122, 26)
COIN = (255, 201, 60)
INK = (53, 33, 15)
BG_TOP = (58, 35, 19)
BG_BOT = (30, 16, 5)


def font(size):
    p = os.path.join(ASSETS, "fonts", "Kenney_Rocket.ttf")
    if os.path.exists(p):
        return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def gfont(size):
    """The blocky G lives in the UI font - a proper chunky letter G."""
    p = os.path.join(ASSETS, "fonts", "Kenney_Mini.ttf")
    if os.path.exists(p):
        return ImageFont.truetype(p, size)
    return font(size)


def gradient(size, top, bot):
    img = Image.new("RGB", (size, size) if isinstance(size, int) else size)
    w, h = img.size
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        row = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3))
        for x in range(w):
            px[x, y] = row
    return img


def stripes_layer(w, h, step=64, alpha=14):
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for i in range(-h, w + h, step):
        d.polygon([(i, h), (i + 24, h), (i + h + 24, 0), (i + h, 0)],
                  fill=(255, 176, 32, alpha))
    return layer


def G_emblem(size, shadow=True):
    """The GOGABox G - the real chunky letter G (UI font), outlined,
    highlighted, with the coin dot. Replaces the old shape-built G."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    f = gfont(int(size * 1.02))
    # measure and center the glyph
    probe = ImageDraw.Draw(img)
    bb = probe.textbbox((0, 0), "G", font=f, stroke_width=max(2, size // 36))
    gw, gh = bb[2] - bb[0], bb[3] - bb[1]
    x = (size - gw) // 2 - bb[0]
    y = (size - gh) // 2 - bb[1]
    sw = max(3, size // 34)
    # drop shadow
    if shadow:
        sh = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        ImageDraw.Draw(sh).text((x + size * 0.02, y + size * 0.035), "G", font=f,
                                fill=(0, 0, 0, 130), stroke_width=sw,
                                stroke_fill=(0, 0, 0, 130))
        img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(max(2, size // 48))))
    # body: amber fill + deep-brown outline
    d = ImageDraw.Draw(img)
    d.text((x, y), "G", font=f, fill=ACCENT + (255,), stroke_width=sw,
           stroke_fill=(122, 74, 20, 255))
    # top-left highlight (lighter pass, clipped to upper area)
    hl = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(hl).text((x, y), "G", font=f, fill=(255, 228, 150, 255))
    mask = Image.new("L", (size, size), 0)
    md = ImageDraw.Draw(mask)
    md.rectangle([0, 0, size, y + gh * 0.52], fill=90)
    img.alpha_composite(Image.composite(hl, Image.new("RGBA", (size, size)), mask))
    # coin dot, bottom-right
    cr = size * 0.085
    ccx, ccy = x + gw * 0.94, y + gh * 0.86
    d.ellipse([ccx - cr, ccy - cr, ccx + cr, ccy + cr], fill=(160, 110, 20, 255))
    d.ellipse([ccx - cr * 0.7, ccy - cr * 0.7, ccx + cr * 0.7, ccy + cr * 0.7],
              fill=COIN + (255,))
    return img


def main_icon():
    os.makedirs(ICONS, exist_ok=True)
    S = 512
    img = gradient(S, BG_TOP, BG_BOT).convert("RGBA")
    img.alpha_composite(stripes_layer(S, S))
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([-S * 0.25, -S * 0.35, S * 1.25, S * 0.6],
                                 fill=(90, 55, 25, 60))
    img.alpha_composite(glow)
    img.alpha_composite(G_emblem(int(S * 0.88), shadow=True),
                        (int(S * 0.06), int(S * 0.06)))
    img.convert("RGB").save(os.path.join(ICONS, "main_512x512.png"))
    img.resize((192, 192), Image.LANCZOS).save(os.path.join(ICONS, "main_192x192.png"))
    print("icons: main_512x512, main_192x192")


def adaptive():
    S = 432
    bg = gradient(S, BG_TOP, BG_BOT).convert("RGBA")
    bg.alpha_composite(stripes_layer(S, S, alpha=18))
    bg.convert("RGB").save(os.path.join(ICONS, "adaptive_background_432x432.png"))
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    fg.alpha_composite(G_emblem(int(S * 0.62), shadow=False),
                       (int(S * 0.19), int(S * 0.19)))
    fg.save(os.path.join(ICONS, "adaptive_foreground_432x432.png"))
    print("icons: adaptive fg/bg")


def splash():
    W, H = 720, 1280
    img = gradient((W, H), BG_TOP, BG_BOT).convert("RGBA")
    img.alpha_composite(stripes_layer(W, H, step=90, alpha=10))
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([W * 0.5 - 330, 280, W * 0.5 + 330, 880],
                                 fill=(255, 170, 40, 46))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(120)))
    img.alpha_composite(G_emblem(380, shadow=True), (W // 2 - 190, 290))
    d = ImageDraw.Draw(img)
    f_big = font(96)
    text = "GOGABox"
    bb = d.textbbox((0, 0), text, font=f_big)
    x, y = (W - (bb[2] - bb[0])) // 2 - bb[0], 740
    tsh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(tsh).text((x + 5, y + 7), text, font=f_big, fill=(0, 0, 0, 150))
    img.alpha_composite(tsh)
    tt = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    td = ImageDraw.Draw(tt)
    td.text((x, y), text, font=f_big, fill=HOT + (255,))
    td.text((x, y), "GOGA", font=f_big, fill=ACCENT + (255,))
    img.alpha_composite(tt)
    f_small = font(30)
    tag = "GOdot GAme Box"
    bb2 = d.textbbox((0, 0), tag, font=f_small)
    tg = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(tg).text(((W - (bb2[2] - bb2[0])) / 2 - bb2[0], 880), tag,
                            font=f_small, fill=(255, 220, 160, 220))
    img.alpha_composite(tg)
    img.save(os.path.join(ASSETS, "ui", "splash.png"))
    print("assets/ui/splash.png")


def mystery_tile():
    """Black mystery tile art: blocky ? + accent blocks on the edges."""
    W, H = 320, 220
    img = Image.new("RGBA", (W, H), (18, 14, 12, 255))
    d = ImageDraw.Draw(img)
    # subtle checker
    for cy in range(0, H, 20):
        for cx in range(0, W, 20):
            if (cx // 20 + cy // 20) % 2 == 0:
                d.rectangle([cx, cy, cx + 19, cy + 19], fill=(24, 19, 16, 255))
    B = 18  # block size
    bx = W // 2 - B * 2  # ? starts
    by = 34

    def blk(cx, cy, fill, outline=(240, 235, 225, 255)):
        d.rectangle([bx + cx * B, by + cy * B, bx + cx * B + B - 2, by + cy * B + B - 2],
                    fill=fill, outline=outline, width=3)

    # blocky question mark (grid 4 wide x 6 tall)
    Y = (243, 238, 228, 255)
    for cx in (0, 1, 2):
        blk(cx, 0, Y)
    blk(3, 1, Y)
    blk(2, 2, Y)
    for cx in (1, 2):
        blk(cx, 3, Y)
    blk(1, 5, Y)
    # edge accent blocks (arcade confetti corners)
    A = ACCENT + (255,)
    H2 = HOT + (255,)
    C = COIN + (255,)
    for (ex, ey, col) in [(0, 0, A), (1, 0, C), (0, 1, H2),
                          (9, 9, A), (8, 9, C), (9, 8, H2),
                          (9, 0, C), (0, 9, A)]:
        d.rectangle([ex * B + 2, ey * B + 2, ex * B + B - 2, ey * B + B - 2],
                    fill=col)
    img.save(os.path.join(ASSETS, "ui", "mystery.png"))
    print("assets/ui/mystery.png")


# ------------------------------------------------------------------ meta icons
# little white-on-transparent glyphs, tinted by a colored circle chip

def _glyph_canvas(size=96):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img), size


def _save_meta(name, img):
    os.makedirs(META_ICONS, exist_ok=True)
    img.save(os.path.join(META_ICONS, name + ".png"))
    print("assets/meta/%s.png" % name)


def meta_icons():
    # --- main genres ---
    img, d, s = _glyph_canvas()
    # arcade: joystick
    d.rounded_rectangle([14, 44, 82, 80], radius=10, fill=(255, 255, 255, 255))
    d.rectangle([42, 20, 54, 48], fill=(255, 255, 255, 255))
    d.ellipse([36, 8, 60, 30], fill=(255, 255, 255, 255))
    d.ellipse([22, 56, 34, 68], fill=(120, 70, 10, 255))
    d.ellipse([62, 56, 74, 68], fill=(120, 70, 10, 255))
    _save_meta("genre_arcade", img)

    img, d, s = _glyph_canvas()
    # action: lightning bolt
    d.polygon([(56, 6), (24, 52), (44, 52), (36, 90), (72, 40), (50, 40)],
              fill=(255, 255, 255, 255))
    _save_meta("genre_action", img)

    img, d, s = _glyph_canvas()
    # puzzle piece
    d.rounded_rectangle([16, 30, 80, 82], radius=8, fill=(255, 255, 255, 255))
    d.ellipse([38, 12, 62, 36], fill=(255, 255, 255, 255))
    d.ellipse([4, 46, 26, 66], fill=(255, 255, 255, 255))
    _save_meta("genre_puzzle", img)

    img, d, s = _glyph_canvas()
    # adventure: folded map
    d.polygon([(10, 24), (34, 14), (58, 24), (86, 14), (86, 74), (58, 84),
               (34, 74), (10, 84)], fill=(255, 255, 255, 255))
    d.line([(34, 16), (34, 76)], fill=(120, 70, 10, 255), width=4)
    d.line([(58, 26), (58, 86)], fill=(120, 70, 10, 255), width=4)
    _save_meta("genre_adventure", img)

    img, d, s = _glyph_canvas()
    # shooter: crosshair
    d.ellipse([18, 18, 78, 78], outline=(255, 255, 255, 255), width=8)
    d.rectangle([44, 4, 52, 30], fill=(255, 255, 255, 255))
    d.rectangle([44, 66, 52, 92], fill=(255, 255, 255, 255))
    d.rectangle([4, 44, 30, 52], fill=(255, 255, 255, 255))
    d.rectangle([66, 44, 92, 52], fill=(255, 255, 255, 255))
    _save_meta("genre_shooter", img)

    img, d, s = _glyph_canvas()
    # racing: two flags
    d.rectangle([20, 10, 28, 86], fill=(255, 255, 255, 255))
    d.polygon([(28, 12), (76, 20), (28, 44)], fill=(255, 255, 255, 255))
    d.rectangle([(28 + 76) // 2 - 4, 18, (28 + 76) // 2 + 4, 32], fill=(120, 70, 10, 255))
    _save_meta("genre_racing", img)

    img, d, s = _glyph_canvas()
    # kids: balloon
    d.ellipse([26, 8, 70, 56], fill=(255, 255, 255, 255))
    d.polygon([(46, 56), (52, 56), (48, 66)], fill=(255, 255, 255, 255))
    d.arc([34, 60, 62, 92], 200, 340, fill=(255, 255, 255, 255), width=5)
    _save_meta("genre_kids", img)

    img, d, s = _glyph_canvas()
    # music: note
    d.ellipse([18, 58, 46, 86], fill=(255, 255, 255, 255))
    d.rectangle([42, 10, 50, 70], fill=(255, 255, 255, 255))
    d.polygon([(50, 10), (78, 18), (78, 32), (50, 24)], fill=(255, 255, 255, 255))
    _save_meta("genre_music", img)

    img, d, s = _glyph_canvas()
    # story: open book
    d.polygon([(10, 22), (46, 30), (46, 80), (10, 72)], fill=(255, 255, 255, 255))
    d.polygon([(86, 22), (50, 30), (50, 80), (86, 72)], fill=(220, 214, 200, 255))
    _save_meta("genre_story", img)

    # --- sub genres ---
    img, d, s = _glyph_canvas()
    # retro: pixel heart
    B = 12
    heart = [(1, 1), (2, 1), (4, 1), (5, 1), (0, 2), (3, 2), (6, 2),
             (0, 3), (6, 3), (1, 4), (5, 4), (2, 5), (4, 5), (3, 6)]
    for cx, cy in heart:
        d.rectangle([10 + cx * B, 6 + cy * B, 10 + cx * B + B - 2, 6 + cy * B + B - 2],
                    fill=(255, 255, 255, 255))
    _save_meta("sub_retro", img)

    img, d, s = _glyph_canvas()
    # singleplayer: one person
    d.ellipse([34, 8, 62, 36], fill=(255, 255, 255, 255))
    d.pieslice([20, 40, 76, 100], 180, 360, fill=(255, 255, 255, 255))
    _save_meta("sub_singleplayer", img)

    img, d, s = _glyph_canvas()
    # survival: heart pulse
    d.polygon([(48, 84), (14, 48), (14, 30), (30, 18), (48, 30), (66, 18), (82, 30),
               (82, 48)], fill=(255, 255, 255, 255))
    _save_meta("sub_survival", img)

    img, d, s = _glyph_canvas()
    # competitive: VS badge
    d.rounded_rectangle([8, 22, 88, 74], radius=14, outline=(255, 255, 255, 255), width=7)
    f = font(34)
    d.text((22, 30), "V", font=f, fill=(255, 255, 255, 255))
    d.text((50, 30), "S", font=f, fill=(255, 255, 255, 255))
    _save_meta("sub_competitive", img)

    img, d, s = _glyph_canvas()
    # hacknslash: sword
    d.polygon([(70, 8), (84, 22), (44, 62), (30, 48)], fill=(255, 255, 255, 255))
    d.rectangle([22, 56, 44, 68], fill=(255, 255, 255, 255))
    d.rectangle([12, 70, 30, 84], fill=(255, 255, 255, 255))
    _save_meta("sub_hacknslash", img)

    img, d, s = _glyph_canvas()
    # platformer: platform + jumper
    d.rounded_rectangle([8, 64, 88, 80], radius=6, fill=(255, 255, 255, 255))
    d.ellipse([34, 12, 58, 36], fill=(255, 255, 255, 255))
    d.rounded_rectangle([30, 38, 62, 58], radius=8, fill=(255, 255, 255, 255))
    _save_meta("sub_platformer", img)

    img, d, s = _glyph_canvas()
    # minimal: three dots
    for cx in (14, 40, 66):
        d.ellipse([cx, 38, cx + 18, 56], fill=(255, 255, 255, 255))
    _save_meta("sub_minimal", img)

    img, d, s = _glyph_canvas()
    # turn-based: clock
    d.ellipse([14, 14, 82, 82], outline=(255, 255, 255, 255), width=8)
    d.line([(48, 48), (48, 26)], fill=(255, 255, 255, 255), width=6)
    d.line([(48, 48), (64, 56)], fill=(255, 255, 255, 255), width=6)
    _save_meta("sub_turnbased", img)

    # --- age ratings ---
    img, d, s = _glyph_canvas()
    # everyone: smiley
    d.ellipse([10, 10, 86, 86], fill=(255, 255, 255, 255))
    d.ellipse([30, 32, 40, 44], fill=(90, 140, 60, 255))
    d.ellipse([56, 32, 66, 44], fill=(90, 140, 60, 255))
    d.arc([28, 40, 68, 74], 20, 160, fill=(90, 140, 60, 255), width=6)
    _save_meta("age_everyone", img)

    img, d, s = _glyph_canvas()
    # kids: teddy/balloon -> duck
    d.ellipse([30, 30, 70, 70], fill=(255, 255, 255, 255))
    d.ellipse([52, 16, 76, 40], fill=(255, 255, 255, 255))
    d.polygon([(72, 26), (90, 30), (72, 36)], fill=(255, 255, 255, 255))
    d.ellipse([26, 32, 34, 42], fill=(255, 255, 255, 255))
    _save_meta("age_kids", img)

    img, d, s = _glyph_canvas()
    # teens: 12+ badge
    d.rounded_rectangle([6, 20, 90, 76], radius=16, outline=(255, 255, 255, 255), width=7)
    f = font(30)
    d.text((16, 30), "12", font=f, fill=(255, 255, 255, 255))
    d.text((58, 30), "+", font=f, fill=(255, 255, 255, 255))
    _save_meta("age_teens", img)

    # --- search glyph (magnifier) ---
    img, d, s = _glyph_canvas()
    d.ellipse([12, 12, 62, 62], outline=(255, 255, 255, 255), width=9)
    d.line([(56, 56), (84, 84)], fill=(255, 255, 255, 255), width=11)
    _save_meta("icon_search", img)


def notif_icon():
    S = 96
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    f = gfont(int(S * 0.8))
    bb = d.textbbox((0, 0), "G", font=f)
    d.text(((S - (bb[2] - bb[0])) / 2 - bb[0], (S - (bb[3] - bb[1])) / 2 - bb[1]),
           "G", font=f, fill=(255, 255, 255, 255))
    dst = os.path.join(ROOT, "android-overlay", "src", "main", "res", "drawable-nodpi")
    os.makedirs(dst, exist_ok=True)
    img.save(os.path.join(dst, "ic_notify.png"))
    print("android-overlay: drawable-nodpi/ic_notify.png")


ICON_SVG = """<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
<defs>
<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#3a2313"/><stop offset="1" stop-color="#1e1005"/>
</linearGradient>
</defs>
<rect width="128" height="128" rx="22" fill="url(#bg)"/>
<g stroke="#ffb020" stroke-opacity="0.06" stroke-width="14">
<line x1="-20" y1="140" x2="140" y2="-20"/><line x1="30" y1="160" x2="180" y2="10"/>
<line x1="90" y1="170" x2="220" y2="40"/></g>
<circle cx="64" cy="46" r="52" fill="#5a3719" opacity="0.45"/>
<text x="64" y="100" font-family="monospace" font-size="104" font-weight="bold"
 text-anchor="middle" fill="#ffb020" stroke="#7a4a14" stroke-width="4">G</text>
<circle cx="100" cy="98" r="9" fill="#a06e14"/><circle cx="100" cy="98" r="6.6" fill="#ffc93c"/>
</svg>
"""


def icon_svg():
    with open(os.path.join(ROOT, "icon.svg"), "w") as f:
        f.write(ICON_SVG)
    print("icon.svg")


if __name__ == "__main__":
    main_icon()
    adaptive()
    splash()
    mystery_tile()
    meta_icons()
    notif_icon()
    icon_svg()
