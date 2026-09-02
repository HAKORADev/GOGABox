#!/usr/bin/env python3
"""v0.2.9 art - the FRUIT SLASHER wardrobe (owner: "the current fruits are
like a pixel-art... find a better suitable ones"). The online hunt came up
empty (GameArt2D freebies carry no fruit pack; OGA fruit pages are preview
JPGs; Kenney's food kit is JS-gated) - so the fruits are PAINTED here:
silhouette first, then a GENERIC soft-shading pass (rim shadow, top-left
light, specular, bounce), then a contour. 8 fruits + 6 vegetables (the
shop "vegetables" pack). Re-runnable: same code -> same bytes."""

import math
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(PROJ, "assets", "games", "slasher")
S = 256
C = S / 2

RNG_SEED = 290903


def _img():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def _d(img):
    return ImageDraw.Draw(img)


def _leaf(w=30, h=14, col=(76, 152, 60, 255), ang=-24):
    leaf = Image.new("RGBA", (w * 3, h * 4), (0, 0, 0, 0))
    ld = ImageDraw.Draw(leaf)
    ld.ellipse([w, h, w * 2, h * 3], fill=col)
    ld.line([w * 1.1, h * 2, w * 1.9, h * 2],
            fill=tuple(max(0, c - 40) for c in col[:3]) + (255,), width=3)
    return leaf.rotate(ang, expand=True, resample=Image.BICUBIC)


def _paste(img, part, x, y):
    img.alpha_composite(part, (int(x - part.width / 2), int(y - part.height / 2)))


def _shade_pass(img, light_box=None, spec_box=None, rim=100):
    """the generic soft shading, masked to the silhouette"""
    mask = img.getchannel("A")
    # 1. the rim: the ring just inside the contour darkens
    inner = mask.filter(ImageFilter.MinFilter(13))
    ring = ImageChops.subtract(mask, inner)
    dark = Image.new("RGBA", img.size, (10, 8, 6, rim))
    dark.putalpha(ring.point(lambda v: int(v * rim / 255.0)))
    img.alpha_composite(dark)
    # 2. the top-left light cap
    lb = light_box or (S * 0.14, S * 0.08, S * 0.58, S * 0.5)
    light = Image.new("RGBA", img.size, (0, 0, 0, 0))
    _d(light).ellipse(lb, fill=(255, 250, 235, 105))
    light = light.filter(ImageFilter.GaussianBlur(20))
    light.putalpha(ImageChops.multiply(light.getchannel("A"), mask))
    img.alpha_composite(light)
    # 3. the specular kiss
    sb = spec_box or (S * 0.2, S * 0.13, S * 0.4, S * 0.3)
    spec = Image.new("RGBA", img.size, (0, 0, 0, 0))
    _d(spec).ellipse(sb, fill=(255, 255, 255, 150))
    spec = spec.filter(ImageFilter.GaussianBlur(7))
    spec.putalpha(ImageChops.multiply(spec.getchannel("A"), mask))
    img.alpha_composite(spec)
    # 4. the bounce light bottom-right (a whisper)
    bounce = Image.new("RGBA", img.size, (0, 0, 0, 0))
    _d(bounce).ellipse((S * 0.5, S * 0.55, S * 0.94, S * 0.95),
                       fill=(255, 240, 210, 46))
    bounce = bounce.filter(ImageFilter.GaussianBlur(22))
    bounce.putalpha(ImageChops.multiply(bounce.getchannel("A"), mask))
    img.alpha_composite(bounce)
    return img


def _outline(img, col=(24, 22, 20, 80)):
    a = img.getchannel("A")
    big = a.filter(ImageFilter.MaxFilter(5))
    small = a.filter(ImageFilter.MinFilter(5))
    ring = ImageChops.subtract(big, small)
    edge = Image.new("RGBA", img.size, col)
    edge.putalpha(ring)
    img.alpha_composite(edge)
    return img


def _done(img, **kw):
    _shade_pass(img, **kw)
    return _outline(img)


# ------------------------------------------------------------------ fruits

def watermelon():
    img = _img()
    d = _d(img)
    d.ellipse([C - 98, C - 94, C + 98, C + 102], fill=(52, 140, 60, 255))
    for k in range(-2, 3):
        x0 = C + k * 36
        for i in range(16):
            t = i / 15.0
            y = C - 90 + t * 184
            wob = math.sin(t * 6.2 + k * 1.7) * 7.0
            w = 14.0 * math.sin(t * math.pi) ** 0.5
            d.line([x0 + wob, y, x0 + wob, y + 14], fill=(26, 88, 34, 255),
                   width=int(w) + 3)
    d.line([C, C - 92, C + 6, C - 108], fill=(84, 54, 30, 255), width=6)
    return _done(img)


def orange():
    img = _img()
    d = _d(img)
    d.ellipse([C - 88, C - 84, C + 88, C + 92], fill=(255, 152, 0, 255))
    r = __import__("random").Random(RNG_SEED)
    for _ in range(80):
        a = r.uniform(0, math.tau)
        rr = r.uniform(0, 80)
        x = C + math.cos(a) * rr
        y = C + 4 + math.sin(a) * rr * 0.98
        s = r.uniform(1.5, 3.0)
        d.ellipse([x - s, y - s, x + s, y + s], fill=(235, 128, 0, 255))
    _paste(img, _leaf(ang=-24), C - 22, C - 84)
    d.line([C - 2, C - 80, C + 2, C - 92], fill=(96, 64, 32, 255), width=5)
    return _done(img)


def apple():
    img = _img()
    d = _d(img)
    d.ellipse([C - 80, C - 62, C + 80, C + 92], fill=(229, 57, 53, 255))
    d.ellipse([C - 56, C - 82, C + 56, C - 18], fill=(229, 57, 53, 255))
    d.line([C, C - 72, C + 4, C - 98], fill=(92, 60, 30, 255), width=7)
    _paste(img, _leaf(ang=-18), C + 24, C - 88)
    return _done(img)


def lemon():
    img = _img()
    d = _d(img)
    d.ellipse([C - 92, C - 62, C + 92, C + 62], fill=(253, 216, 53, 255))
    d.ellipse([C + 80, C - 16, C + 106, C + 16], fill=(253, 216, 53, 255))
    d.ellipse([C - 106, C - 16, C - 80, C + 16], fill=(253, 216, 53, 255))
    return _done(img, light_box=(S * 0.2, S * 0.16, S * 0.6, S * 0.5))


def pear():
    img = _img()
    d = _d(img)
    # the body: stamps along a slight curve - small at the neck, full at
    # the base (no two-circle seams)
    for i in range(41):
        t = i / 40.0
        y = C - 74 + t * 176
        r = 30 + 40 * (t ** 1.5)
        x = C + math.sin(t * 2.2) * 5.0
        d.ellipse([x - r, y - r, x + r, y + r], fill=(198, 208, 62, 255))
    d.line([C, C - 76, C + 6, C - 102], fill=(92, 60, 30, 255), width=6)
    return _done(img, light_box=(S * 0.2, S * 0.1, S * 0.55, S * 0.42))


def strawberry():
    img = _img()
    d = _d(img)
    d.ellipse([C - 82, C - 62, C + 82, C + 70], fill=(214, 32, 62, 255))
    d.polygon([(C - 82, C + 2), (C + 82, C + 2), (C, C + 100)],
              fill=(214, 32, 62, 255))
    r = __import__("random").Random(RNG_SEED + 5)
    for _ in range(36):
        a = r.uniform(0, math.tau)
        rr = r.uniform(6, 66)
        x = C + math.cos(a) * rr * 0.95
        y = C + 4 + math.sin(a) * rr * 0.92
        if y > C + 88:
            continue
        d.ellipse([x - 2.4, y - 3.4, x + 2.4, y + 3.4], fill=(255, 224, 178, 255))
    for k in range(5):
        ang = -math.pi / 2 + (k - 2) * 0.5
        d.line([C, C - 56, C + math.cos(ang) * 46, C - 62 + math.sin(ang) * 26],
               fill=(56, 128, 48, 255), width=9)
    d.ellipse([C - 14, C - 72, C + 14, C - 52], fill=(76, 152, 60, 255))
    return _done(img, light_box=(S * 0.2, S * 0.12, S * 0.55, S * 0.44))


def peach():
    img = _img()
    d = _d(img)
    d.ellipse([C - 86, C - 80, C + 86, C + 92], fill=(251, 140, 0, 255))
    # the blush: a SOFT pink cloud (blurred, masked to the body)
    blush = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    _d(blush).ellipse([C - 6, C - 52, C + 76, C + 34], fill=(240, 98, 146, 170))
    blush = blush.filter(ImageFilter.GaussianBlur(16))
    body = img.getchannel("A")
    blush.putalpha(ImageChops.multiply(blush.getchannel("A"), body))
    img.alpha_composite(blush)
    d = _d(img)
    d.line([C, C - 78, C + 2, C + 70], fill=(196, 104, 20, 200), width=4)
    _paste(img, _leaf(ang=-16), C + 22, C - 78)
    return _done(img)


def plum():
    img = _img()
    d = _d(img)
    d.ellipse([C - 82, C - 78, C + 82, C + 90], fill=(106, 27, 154, 255))
    d.line([C - 2, C - 74, C + 2, C + 66], fill=(70, 20, 100, 220), width=4)
    d.line([C, C - 76, C + 5, C - 98], fill=(92, 60, 30, 255), width=6)
    return _done(img)


# ------------------------------------------------------------- vegetables

def carrot():
    img = _img()
    d = _d(img)
    pts = [(C - 32, C - 48), (C + 32, C - 48), (C + 20, C + 26), (C, C + 98),
           (C - 20, C + 26)]
    d.polygon(pts, fill=(251, 140, 40, 255))
    for k, y in enumerate([C - 26, C - 2, C + 24, C + 48]):
        w = 24 - k * 4
        d.line([C - w, y, C + w, y], fill=(224, 110, 20, 255), width=5)
    r = __import__("random").Random(RNG_SEED + 9)
    for k in range(7):
        ang = -math.pi / 2 + (k - 3) * 0.34
        x2 = C + math.cos(ang) * 56 + r.uniform(-4, 4)
        y2 = C - 56 + math.sin(ang) * 46
        d.line([C, C - 52, x2, y2], fill=(66, 138, 52, 255), width=7)
    return _done(img, light_box=(S * 0.24, S * 0.14, S * 0.5, S * 0.4))


def tomato():
    img = _img()
    d = _d(img)
    d.ellipse([C - 86, C - 74, C + 86, C + 94], fill=(226, 44, 44, 255))
    for k in range(6):
        ang = -math.pi / 2 + (k - 2.5) * 0.55
        d.line([C, C - 54, C + math.cos(ang) * 56, C - 58 + math.sin(ang) * 30],
               fill=(56, 128, 48, 255), width=8)
    d.ellipse([C - 8, C - 72, C + 8, C - 54], fill=(76, 152, 60, 255))
    return _done(img)


def eggplant():
    img = _img()
    d = _d(img)
    d.ellipse([C - 46, C - 36, C + 46, C + 98], fill=(110, 30, 128, 255))
    d.rectangle([C - 34, C - 44, C + 34, C + 20], fill=(110, 30, 128, 255))
    d.ellipse([C - 34, C - 58, C + 34, C - 6], fill=(110, 30, 128, 255))
    for k in range(5):
        ang = -math.pi / 2 + (k - 2) * 0.5
        d.line([C, C - 48, C + math.cos(ang) * 48, C - 44 + math.sin(ang) * 26],
               fill=(56, 128, 48, 255), width=9)
    d.ellipse([C - 10, C - 82, C + 10, C - 56], fill=(76, 152, 60, 255))
    return _done(img, light_box=(S * 0.22, S * 0.16, S * 0.52, S * 0.5))


def broccoli():
    img = _img()
    d = _d(img)
    d.rounded_rectangle([C - 22, C - 6, C + 22, C + 98], radius=16,
                        fill=(178, 206, 116, 255))
    r = __import__("random").Random(RNG_SEED + 11)
    for k in range(28):
        a = r.uniform(0, math.tau)
        rr = r.uniform(0, 68)
        x = C + math.cos(a) * rr
        y = C - 24 + math.sin(a) * rr * 0.7
        s = r.uniform(16, 30)
        d.ellipse([x - s, y - s * 0.8, x + s, y + s * 0.8],
                  fill=(58, 128, 58, 255))
    for k in range(20):
        a = r.uniform(0, math.tau)
        rr = r.uniform(0, 54)
        x = C + math.cos(a) * rr
        y = C - 28 + math.sin(a) * rr * 0.64
        s = r.uniform(8, 15)
        d.ellipse([x - s, y - s * 0.8, x + s, y + s * 0.8],
                  fill=(92, 160, 82, 255))
    return _done(img, light_box=(S * 0.18, S * 0.06, S * 0.52, S * 0.36))


def corn():
    img = _img()
    d = _d(img)
    d.ellipse([C - 44, C - 88, C + 44, C + 96], fill=(250, 205, 60, 255))
    for gy in range(-76, 90, 20):
        for gx in range(-34, 38, 17):
            x = C + gx * (1.0 - max(0.0, (gy + 40)) / 260.0)
            d.ellipse([x - 6, C + gy - 8, x + 6, C + gy + 8],
                      fill=(232, 176, 24, 255))
    d.polygon([(C - 68, C + 100), (C - 10, C - 44), (C + 8, C + 24)],
              fill=(90, 150, 60, 255))
    d.polygon([(C + 68, C + 100), (C + 10, C - 44), (C - 8, C + 24)],
              fill=(76, 132, 52, 255))
    return _done(img, light_box=(S * 0.24, S * 0.08, S * 0.52, S * 0.36))


def pepper():
    img = _img()
    d = _d(img)
    d.ellipse([C - 76, C - 26, C + 76, C + 96], fill=(76, 152, 60, 255))
    d.ellipse([C - 74, C - 48, C - 8, C + 70], fill=(76, 152, 60, 255))
    d.ellipse([C + 8, C - 48, C + 74, C + 70], fill=(76, 152, 60, 255))
    d.ellipse([C - 40, C - 56, C + 40, C + 40], fill=(76, 152, 60, 255))
    d.line([C - 72, C + 30, C + 72, C + 30], fill=(52, 110, 44, 255), width=5)
    d.line([C - 26, C - 44, C - 30, C + 88], fill=(52, 110, 44, 200), width=5)
    d.line([C + 26, C - 44, C + 30, C + 88], fill=(52, 110, 44, 200), width=5)
    d.line([C, C - 60, C, C - 92], fill=(92, 60, 30, 255), width=7)
    return _done(img)


FRUITS = {
    "watermelon": watermelon, "orange": orange, "apple": apple,
    "lemon": lemon, "pear": pear, "strawberry": strawberry,
    "peach": peach, "plum": plum,
}
VEGGIES = {
    "carrot": carrot, "tomato": tomato, "eggplant": eggplant,
    "broccoli": broccoli, "corn": corn, "pepper": pepper,
}

# the juice colors (the slash VFX tints per piece)
JUICE = {
    "watermelon": (255, 92, 109), "orange": (255, 159, 67),
    "apple": (255, 107, 107), "lemon": (255, 241, 118),
    "pear": (212, 225, 87), "strawberry": (255, 64, 129),
    "peach": (255, 171, 145), "plum": (186, 104, 200),
    "carrot": (255, 158, 64), "tomato": (255, 82, 82),
    "eggplant": (236, 239, 241), "broccoli": (156, 204, 101),
    "corn": (255, 224, 130), "pepper": (174, 221, 131),
}


def main():
    os.makedirs(OUT, exist_ok=True)
    names = []
    for name, fn in FRUITS.items():
        fn().save(os.path.join(OUT, "f_%s.png" % name))
        names.append(name)
    for name, fn in VEGGIES.items():
        fn().save(os.path.join(OUT, "v_%s.png" % name))
        names.append(name)
    cols = 5
    tw = 150
    rows = (len(names) + cols - 1) // cols
    sh = Image.new("RGB", (cols * tw + (cols + 1) * 10,
                           rows * tw + (rows + 1) * 10 + 24), (24, 34, 44))
    for i, name in enumerate(names):
        img = Image.open(os.path.join(OUT,
                ("f_%s.png" if name in FRUITS else "v_%s.png") % name))
        img = img.resize((tw - 8, tw - 8))
        x = 10 + (i % cols) * tw
        y = 24 + 10 + (i // cols) * tw
        sh.paste(img, (x + 4, y), img)
    sh.save("/tmp/fruit_sheet.png")
    print("fruits:", len(FRUITS), "veggies:", len(VEGGIES))


if __name__ == "__main__":
    main()
