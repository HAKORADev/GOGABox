#!/usr/bin/env python3
# ============================================================================
# GOGABox brand pack - app icon (letter G), adaptive layers, boot splash,
# notification icon, vector icon.svg. Deterministic PIL + hand-written SVG.
# Run:  python3 tools/make_brand.py
# ============================================================================
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))   # projects/gogabox
ASSETS = os.path.join(ROOT, "assets")
ICONS = os.path.join(ROOT, "icons")

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


def gradient(size, top, bot, radial=False):
    img = Image.new("RGB", (size, size) if isinstance(size, int) else size)
    w, h = img.size
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        row = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3))
        for x in range(w):
            px[x, y] = row
    if radial:
        # warm glow center-top
        glow = Image.new("L", (w, h), 0)
        gd = ImageDraw.Draw(glow)
        gd.ellipse([w * 0.1, -h * 0.25, w * 0.9, h * 0.55], fill=70)
        glow = glow.filter(ImageFilter.GaussianBlur(w // 6))
        warm = Image.new("RGB", (w, h), (120, 70, 20))
        img = Image.composite(Image.blend(img, warm, 0.5), img, glow)
    return img


def stripes_layer(w, h, step=64, alpha=14):
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for i in range(-h, w + h, step):
        d.polygon([(i, h), (i + 24, h), (i + h + 24, 0), (i + h, 0)],
                  fill=(255, 176, 32, alpha))
    return layer


def draw_G(d, cx, cy, size, color=ACCENT):
    """Chunky arcade G: ring open on the right + mid bar + right spine."""
    s = size / 4.2                        # stroke thickness
    r_out = size / 2.0
    box_out = [cx - r_out, cy - r_out, cx + r_out, cy + r_out]
    d.arc(box_out, 55, 305, fill=color, width=int(s))     # gap on the right
    d.rectangle([cx - s * 0.1, cy - s / 2, cx + r_out, cy + s / 2], fill=color)   # bar
    d.rectangle([cx + r_out - s, cy, cx + r_out, cy + r_out], fill=color)         # spine


def G_emblem(size, shadow=True):
    """The GOGABox G emblem on transparent square."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    m = size * 0.09
    cx = cy = size / 2.0
    gsize = size - 2 * m
    s = gsize / 4.2
    r_out = gsize / 2.0
    # drop shadow copy
    if shadow:
        sh = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        sd = ImageDraw.Draw(sh)
        draw_G(sd, cx, cy + size * 0.035, gsize, (0, 0, 0, 120))
        sh = sh.filter(ImageFilter.GaussianBlur(max(2, size // 40)))
        img.alpha_composite(sh)
    draw_G(d, cx, cy, gsize, ACCENT)
    # highlight arc riding inside the top-left stroke
    hl_r = r_out - s * 0.45
    d.arc([cx - hl_r, cy - hl_r, cx + hl_r, cy + hl_r], 200, 300,
          fill=(255, 228, 150), width=max(2, int(s * 0.20)))
    # coin dot at bottom-right of G
    cr = size * 0.075
    ccx, ccy = cx + r_out * 0.72, cy + r_out * 0.78
    d.ellipse([ccx - cr, ccy - cr, ccx + cr, ccy + cr], fill=(160, 110, 20))
    d.ellipse([ccx - cr * 0.72, ccy - cr * 0.72, ccx + cr * 0.72, ccy + cr * 0.72], fill=COIN)
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
    img.alpha_composite(G_emblem(int(S * 0.82), shadow=True),
                        (int(S * 0.09), int(S * 0.09)))
    img.convert("RGB").save(os.path.join(ICONS, "main_512x512.png"))
    img.resize((192, 192), Image.LANCZOS).save(os.path.join(ICONS, "main_192x192.png"))
    print("icons: main_512x512, main_192x192")


def adaptive():
    S = 432
    bg = gradient(S, BG_TOP, BG_BOT).convert("RGBA")
    bg.alpha_composite(stripes_layer(S, S, alpha=18))
    bg.convert("RGB").save(os.path.join(ICONS, "adaptive_background_432x432.png"))
    # foreground: G inside the 66% safe circle
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    fg.alpha_composite(G_emblem(int(S * 0.52), shadow=False),
                       (int(S * 0.24), int(S * 0.24)))
    fg.save(os.path.join(ICONS, "adaptive_foreground_432x432.png"))
    print("icons: adaptive fg/bg")


def splash():
    W, H = 720, 1280
    img = gradient((W, H), BG_TOP, BG_BOT).convert("RGBA")
    img.alpha_composite(stripes_layer(W, H, step=90, alpha=10))
    # horizon glow
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([W * 0.5 - 330, 300, W * 0.5 + 330, 900], fill=(255, 170, 40, 46))
    glow = glow.filter(ImageFilter.GaussianBlur(120))
    img.alpha_composite(glow)
    # big G emblem
    img.alpha_composite(G_emblem(380, shadow=True), (W // 2 - 190, 320))
    # wordmark (drawn on its own layer so alpha blends correctly)
    f_big = font(96)
    text = "GOGABox"
    bb = ImageDraw.Draw(img).textbbox((0, 0), text, font=f_big)
    tw = bb[2] - bb[0]
    x, y = (W - tw) // 2 - bb[0], 760
    tsh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(tsh).text((x + 5, y + 7), text, font=f_big, fill=(0, 0, 0, 150))
    img.alpha_composite(tsh)
    tt = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    td = ImageDraw.Draw(tt)
    td.text((x, y), text, font=f_big, fill=HOT + (255,))
    td.text((x, y), "GOGA", font=f_big, fill=ACCENT + (255,))
    img.alpha_composite(tt)
    # tagline
    f_small = font(30)
    tag = "GOdot GAme Box"
    bb2 = ImageDraw.Draw(img).textbbox((0, 0), tag, font=f_small)
    tg = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(tg).text(((W - (bb2[2] - bb2[0])) / 2 - bb2[0], 902), tag,
                            font=f_small, fill=(255, 220, 160, 220))
    img.alpha_composite(tg)
    img.save(os.path.join(ASSETS, "ui", "splash.png"))
    print("assets/ui/splash.png")


def notif_icon():
    # white silhouette G for the Android status bar (96px, opaque-only alpha)
    S = 96
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = cy = S / 2
    gsize = S * 0.74
    draw_G(d, cx, cy, gsize, (255, 255, 255, 255))
    dst = os.path.join(ROOT, "android-overlay", "src", "main", "res",
                       "drawable-nodpi")
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
<g transform="translate(64,64)">
<path d="M 21.5 -40.5 A 42 42 0 1 0 42 0 L 21.5 0 Z"
 fill="none" stroke="#ffb020" stroke-width="20" stroke-linejoin="round"/>
<path d="M 21.5 -40.5 A 42 42 0 0 0 -8 -34" fill="none" stroke="#ffe196"
 stroke-width="5" stroke-linecap="round" opacity="0.8"/>
</g>
<circle cx="90" cy="96" r="9" fill="#a06e14"/><circle cx="90" cy="96" r="6.6" fill="#ffc93c"/>
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
    notif_icon()
    icon_svg()
