#!/usr/bin/env python3
"""v0.3.5-3 POP SIEGE art pass (the owner's VFX round):
- ic_pops.png   THE SCORE ICON LAW: content fills the canvas (the old draw
                lived in the top 38% and read clipped at 34px)
- p_bomb/p_bomb_g3  real cartoon bombs (the 18px dark dot is dead)
- muzzle.png    a white-hot star flash for every muzzle
- p_trail.png   a soft fading streak darts and shells leave
- blimps nose-RIGHT (they marched backwards on standard maps)
"""
import os
from PIL import Image, ImageDraw, ImageFilter

ADIR = "/home/z/my-project/repo/GOGABox/projects/gogabox/assets/games/pop_siege"


def save(im, rel):
    im.save(f"{ADIR}/{rel}")
    print("wrote", rel, im.size)


INK = (34, 26, 20, 255)

# ---------------------------------------------------------------- ic_pops
def score_icon():
    S = 4
    W = H = 44 * S
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cx, cy = W // 2, H // 2 + 2 * S
    rx, ry = int(17 * S), int(18 * S)
    # the body: red vertical gradient clipped to the ellipse
    grad = Image.new("RGB", (1, ry * 2))
    for y in range(ry * 2):
        t = y / max(1, ry * 2 - 1)
        grad.putpixel((0, y), (int(226 - 76 * t), int(60 - 30 * t), int(60 - 30 * t)))
    grad = grad.resize((rx * 2, ry * 2))
    ellipse_mask = Image.new("L", (rx * 2, ry * 2), 0)
    ImageDraw.Draw(ellipse_mask).ellipse([0, 0, rx * 2 - 1, ry * 2 - 1], fill=255)
    im.paste(grad, (cx - rx, cy - ry), ellipse_mask)
    # the honest layers inside (blue / yellow / green), clipped the same way
    bands = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bands)
    band_cols = [(62, 122, 226), (242, 208, 40), (64, 190, 84)]
    bh = max(3, int(ry * 0.18))
    for i, c in enumerate(band_cols):
        y0 = cy - ry + int(ry * 0.30) + i * bh
        bd.rectangle([cx - rx + 2 * S, y0, cx + rx - 2 * S, y0 + bh - 1], fill=c + (235,))
    bmask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(bmask).ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=255)
    im.paste(bands, (0, 0), Image.composite(bmask, Image.new("L", (W, H), 0), bands.split()[3]))
    d = ImageDraw.Draw(im)
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], outline=INK, width=2 * S)
    # gloss
    d.ellipse([cx - int(rx * 0.55), cy - int(ry * 0.72), cx - int(rx * 0.1), cy - int(ry * 0.34)],
              fill=(255, 255, 255, 190))
    d.arc([cx - rx + 3 * S, cy - ry + 3 * S, cx + rx - 3 * S, cy + ry - 3 * S],
          200, 330, fill=(255, 255, 255, 210), width=2 * S)
    # the knot on top (centered, INSIDE the canvas)
    kx, ky = cx, cy - ry - 1 * S
    d.ellipse([kx - 5 * S, ky - 4 * S, kx + 5 * S, ky + 4 * S], fill=(120, 40, 34, 255), outline=INK, width=S)
    d.ellipse([kx - 2 * S, ky - 2 * S, kx + 1 * S, ky + 1 * S], fill=(230, 120, 100, 255))
    save(im, "ui/ic_pops.png")


# ---------------------------------------------------------------- bombs
def bombs():
    S = 2
    W = H = 30 * S
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = W // 2, int(H * 0.62)
    r = int(9.2 * S)
    # body: near-black glossy sphere
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(44, 42, 50, 255), outline=INK, width=S)
    d.ellipse([cx - r + 2 * S, cy - r + 2 * S, cx + r - 2 * S, cy + r - 2 * S],
              outline=(70, 68, 80, 255), width=S)
    d.ellipse([cx - int(r * 0.55), cy - int(r * 0.66), cx - int(r * 0.08), cy - int(r * 0.2)],
              fill=(210, 214, 226, 200))
    # the mouth + fuse
    d.rectangle([cx - int(2.6 * S), cy - r - 1 * S, cx + int(2.6 * S), cy - r + 3 * S],
                fill=(96, 88, 76, 255), outline=INK, width=S)
    fx0, fy0 = cx, cy - r - 1 * S
    d.line([fx0, fy0, fx0 + 4 * S, fy0 - 5 * S], fill=(140, 100, 50, 255), width=2 * S)
    # the spark
    for a in range(8):
        import math
        ang = a * math.pi / 4.0
        x1 = fx0 + 4 * S + math.cos(ang) * 4 * S
        y1 = fy0 - 5 * S + math.sin(ang) * 4 * S
        d.line([fx0 + 4 * S, fy0 - 5 * S, x1, y1], fill=(255, 210, 90, 255), width=S)
    d.ellipse([fx0 + 2 * S, fy0 - 7 * S, fx0 + 6 * S, fy0 - 3 * S], fill=(255, 240, 170, 255))
    save(im, "fx/p_bomb.png")

    # G3: the mauler - bigger, red war-stripe, twin sparks
    W = H = 38 * S
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = W // 2, int(H * 0.64)
    r = int(11.5 * S)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(40, 38, 46, 255), outline=INK, width=S)
    d.rectangle([cx - r + 2 * S, cy - int(2.2 * S), cx + r - 2 * S, cy + int(2.2 * S)],
                fill=(196, 60, 52, 255))
    d.rectangle([cx - r + 2 * S, cy - int(2.2 * S), cx + r - 2 * S, cy - int(0.6 * S)],
                fill=(236, 96, 84, 255))
    d.ellipse([cx - int(r * 0.5), cy - int(r * 0.72), cx - int(r * 0.06), cy - int(r * 0.3)],
              fill=(206, 210, 222, 190))
    d.rectangle([cx - int(3 * S), cy - r - 1 * S, cx + int(3 * S), cy - r + 3 * S],
                fill=(96, 88, 76, 255), outline=INK, width=S)
    import math
    fx0, fy0 = cx, cy - r - 1 * S
    d.line([fx0 - 2 * S, fy0, fx0 - 5 * S, fy0 - 5 * S], fill=(140, 100, 50, 255), width=2 * S)
    d.line([fx0 + 2 * S, fy0, fx0 + 5 * S, fy0 - 5 * S], fill=(140, 100, 50, 255), width=2 * S)
    for dx in (-5 * S, 5 * S):
        for a in range(8):
            ang = a * math.pi / 4.0
            x1 = fx0 + dx + math.cos(ang) * 3.4 * S
            y1 = fy0 - 5 * S + math.sin(ang) * 3.4 * S
            d.line([fx0 + dx, fy0 - 5 * S, x1, y1], fill=(255, 210, 90, 255), width=S)
        d.ellipse([fx0 + dx - 2 * S, fy0 - 7 * S, fx0 + dx + 2 * S, fy0 - 3 * S],
                  fill=(255, 240, 170, 255))
    save(im, "fx/p_bomb_g3.png")


# ---------------------------------------------------------------- muzzle
def muzzle():
    S = 2
    W = H = 26 * S
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = W // 2
    # a 4-point star flash (points right/left/up/down + diagonals)
    import math
    for a, ln, wd, col in [(0.0, 12 * S, 3 * S, (255, 236, 160, 235)),
                           (math.pi / 2, 12 * S, 3 * S, (255, 236, 160, 235)),
                           (math.pi / 4, 8 * S, 2 * S, (255, 250, 210, 200)),
                           (3 * math.pi / 4, 8 * S, 2 * S, (255, 250, 210, 200))]:
        x2 = c + math.cos(a) * ln
        y2 = c + math.sin(a) * ln
        d.line([c - math.cos(a) * ln, c - math.sin(a) * ln, x2, y2], fill=col, width=wd)
    d.ellipse([c - 5 * S, c - 5 * S, c + 5 * S, c + 5 * S], fill=(255, 246, 190, 240))
    d.ellipse([c - 2 * S, c - 2 * S, c + 2 * S, c + 2 * S], fill=(255, 255, 255, 255))
    im = im.filter(ImageFilter.GaussianBlur(S // 2))
    save(im, "fx/muzzle.png")


def trail():
    S = 2
    W, H = 26 * S, 9 * S
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # a soft horizontal streak: bright head (right), fading tail (left)
    for i in range(10):
        t = i / 9.0
        a = int(200 * (1.0 - t))
        x0 = int(W * (1.0 - (i + 1) / 10.0))
        x1 = int(W * (1.0 - i / 10.0))
        mid = H // 2
        hh = max(1, int(H * 0.5 * (1.0 - t * 0.8)))
        d.rectangle([x0, mid - hh, x1, mid + hh], fill=(255, 250, 230, a))
    im = im.filter(ImageFilter.GaussianBlur(2))
    save(im, "fx/p_trail.png")


# ---------------------------------------------------------------- blimps
def flip_blimps():
    n = 0
    for f in sorted(os.listdir(f"{ADIR}/bloons")):
        if not f.endswith(".png") or ".import" in f:
            continue
        if f.split(".png")[0].split("_lv")[0] not in ("moab", "brutus", "gargantua", "titan"):
            continue
        p = f"{ADIR}/bloons/{f}"
        im = Image.open(p).convert("RGBA")
        im.transpose(Image.FLIP_LEFT_RIGHT).save(p)
        n += 1
    print("flipped", n, "blimp textures nose-right")


if __name__ == "__main__":
    score_icon()
    bombs()
    muzzle()
    trail()
    flip_blimps()
