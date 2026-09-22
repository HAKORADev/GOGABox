#!/usr/bin/env python3
"""v041-1 r5 THE FOOTAGE THUMBNAILS - gold miner + marble popper,
the dw_thumb law verbatim (the owner: "making another one by doing
in-game footage + programmed modifications will be much better").

Takes the raw r5 shoot frames (the REAL games' own renders, staged by
tests/v0411_r5_thumbs_shoot.gd), crops to the box's 960x640 thumb
window around the action, grades (warm lift, saturation, contrast),
vignettes the edges and burns the title. Deterministic, idempotent.

Usage: v0411_r5_thumbs.py <game> <src_frame> <out_png> [crop_y]
       game in {goldminer, marble}
"""
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance, ImageFont

TITLES = {"goldminer": "GOLD MINER", "marble": "MARBLE POPPER"}
FONTS = ["/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"]
OUT_SIZE = (960, 640)


def compose(src, out, title, crop_y, color=1.2, contrast=1.1, bright=1.05):
    im = Image.open(src).convert("RGB")
    W, H = im.size                       # 720x1280 raw footage
    box = (0, crop_y, W, crop_y + 480)   # 720x480 = the thumb's 1.5 aspect
    im = im.crop(box)
    im = im.resize(OUT_SIZE, Image.LANCZOS)
    # THE GRADE: warm lift + saturation + contrast - the shop shelf pop
    im = ImageEnhance.Color(im).enhance(color)
    im = ImageEnhance.Contrast(im).enhance(contrast)
    im = ImageEnhance.Brightness(im).enhance(bright)
    # the vignette (soft, corners only)
    vig = Image.new("L", OUT_SIZE, 0)
    vd = ImageDraw.Draw(vig)
    vd.ellipse([-160, -120, OUT_SIZE[0] + 160, OUT_SIZE[1] + 120], fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(90))
    dark = Image.new("RGB", OUT_SIZE, (12, 8, 6))
    im = Image.composite(im, dark,
                         vig.point(lambda v: 140 + v * 115 // 255))
    # THE TITLE: the game's own name, bottom-center, heavy outline
    d = ImageDraw.Draw(im)
    fnt = ImageFont.truetype(FONTS[0], 74)
    ts = d.textbbox((0, 0), title, font=fnt)
    tw = ts[2] - ts[0]
    tx = (OUT_SIZE[0] - tw) // 2
    ty = OUT_SIZE[1] - 92
    for ox in (-4, -2, 0, 2, 4):
        for oy in (-4, -2, 0, 2, 4):
            if abs(ox) + abs(oy) <= 5:
                d.text((tx + ox, ty + oy), title, font=fnt,
                       fill=(24, 12, 10))
    d.text((tx, ty), title, font=fnt, fill=(255, 210, 84))
    im.save(out)
    print("thumbnail:", out)


def main():
    game, src, out = sys.argv[1], sys.argv[2], sys.argv[3]
    crop_y = int(sys.argv[4]) if len(sys.argv) > 4 else 0
    grade = {"goldminer": (1.18, 1.1, 1.06),
             "marble": (1.3, 1.14, 1.16)}[game]
    compose(src, out, TITLES[game], crop_y, *grade)


if __name__ == "__main__":
    main()
