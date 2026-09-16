#!/usr/bin/env python3
"""HEAVY WAR thumbnail (v040-5) - 960x640, composed from the game's OWN
chroma-keyed code-drawn cutouts over a clean band of a real in-game frame.
What you see IS what the game renders.
"""
from PIL import Image, ImageEnhance, ImageFilter, ImageDraw

FILMS = "/home/z/my-project/gogabox/films/v040-5"
OUT = "/home/z/my-project/gogabox/projects/gogabox/assets/thumbs/heavywar.png"
W, H = 960, 640


def key_out(path, box):
    """crop + remove the magenta chroma -> RGBA cutout"""
    src = Image.open(path).convert("RGBA").crop(box)
    px = src.load()
    w, h = src.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if r > 110 and b > 110 and g < r * 0.75 and g < b * 0.75:
                px[x, y] = (r, g, b, 0)
    return src


def paste(dst, cut, center, scale=1.0, flip=False, shadow=None):
    if scale != 1.0:
        cut = cut.resize((int(cut.width * scale), int(cut.height * scale)),
                         Image.LANCZOS)
    if flip:
        cut = cut.transpose(Image.FLIP_LEFT_RIGHT)
    cx, cy = center
    if shadow is not None:
        sh = Image.new("RGBA", dst.size, (0, 0, 0, 0))
        d = ImageDraw.Draw(sh)
        sx, sy, sw, shh = shadow
        d.ellipse((cx - sw / 2, sy - shh / 2, cx + sw / 2, sy + shh / 2),
                  fill=(0, 0, 0, 110))
        sh = sh.filter(ImageFilter.GaussianBlur(6))
        dst.alpha_composite(sh)
    dst.alpha_composite(cut, (int(cx - cut.width / 2), int(cy - cut.height / 2)))


# ---- the battlefield: one composed in-game frame (the film's thumb shot)
bg = Image.open(f"{FILMS}/thumb_frame.png").convert("RGBA")
img = bg.crop((430, 300, 1490, 1010)).resize((W, H), Image.LANCZOS)

img = img.convert("RGB")
img = ImageEnhance.Color(img).enhance(1.07)
img = ImageEnhance.Contrast(img).enhance(1.06)
img = ImageEnhance.Brightness(img).enhance(1.02)
img.save(OUT)
print("thumbnail written:", OUT)
