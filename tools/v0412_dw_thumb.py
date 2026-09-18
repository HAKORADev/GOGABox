#!/usr/bin/env python3
"""v040-12 THE DW THUMBNAIL - the owner: "making another one by doing
in-game footage + programmed modifications will be much better".

Takes the raw dw_thumb_shoot footage (the real game's own render: the
new species worm bursting from the crust under a fleeing camel), crops
to the box's 960x640 thumb window around the action, grades it (warm
lift, saturation, contrast), vignettes the edges and burns the title.
Deterministic, idempotent.
"""
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance, ImageFont

SRC = "/tmp/dw_thumb/02_burst_high.png"
OUT = ("/home/z/my-project/gogabox/projects/gogabox"
       "/assets/thumbs/deathworm.png")
TITLE = "DEADLY WORM"
FONTS = ["/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"]


def main():
    im = Image.open(SRC).convert("RGB")
    W, H = im.size                       # 1080x1920 raw footage
    # the crop window: 1080x720 centered on the burst (the worm head +
    # the camel share the frame; the HUD strip is cropped away)
    cy = 1080
    box = (0, cy - 360, W, cy + 360)
    im = im.crop(box)                    # 1080x720 (the thumb's 1.5 aspect)
    im = im.resize((960, 640), Image.LANCZOS)
    # THE GRADE: warm lift + saturation + contrast - the shop shelf pop
    im = ImageEnhance.Color(im).enhance(1.22)
    im = ImageEnhance.Contrast(im).enhance(1.1)
    im = ImageEnhance.Brightness(im).enhance(1.04)
    # the vignette (soft, corners only)
    vig = Image.new("L", (960, 640), 0)
    vd = ImageDraw.Draw(vig)
    vd.ellipse([-160, -120, 1120, 760], fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(90))
    dark = Image.new("RGB", (960, 640), (12, 8, 6))
    im = Image.composite(im, dark, vig.point(lambda v: 140 + v * 115 // 255))
    # THE TITLE: the game's own name, bottom-center, heavy outline
    d = ImageDraw.Draw(im)
    fnt = ImageFont.truetype(FONTS[0], 74)
    ts = d.textbbox((0, 0), TITLE, font=fnt)
    tw = ts[2] - ts[0]
    tx = (960 - tw) // 2
    ty = 640 - 92
    for ox in (-4, -2, 0, 2, 4):
        for oy in (-4, -2, 0, 2, 4):
            if abs(ox) + abs(oy) <= 5:
                d.text((tx + ox, ty + oy), TITLE, font=fnt,
                       fill=(24, 12, 10))
    d.text((tx, ty), TITLE, font=fnt, fill=(255, 210, 84))
    im.save(OUT)
    print("thumbnail:", OUT)


if __name__ == "__main__":
    main()
