#!/usr/bin/env python3
"""v0.3.1 art - CURSED DARIO's missing pieces, painted to match the CC0
Kenney platformer style (flat shapes, soft colors, no outlines):
  the Witcher (the boss, 2 poses: idle float + cast)
  powerup icons: the strong-foot boot, the shield, the power-jump wing
  the curse bolt (the Witcher's projectile)
Re-runnable: same code -> same bytes."""

import math
import os

from PIL import Image, ImageDraw

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(PROJ, "assets", "games", "dario")


def _img(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def _ellipse(d, box, col):
    d.ellipse(box, fill=col)


def witcher(pose="float"):
    W, H = 200, 240
    img = _img(W, H)
    d = ImageDraw.Draw(img)
    # the robe: a tall purple bell
    robe = (122, 60, 168, 255)
    robe_dark = (86, 38, 124, 255)
    d.polygon([(W // 2, 46), (W // 2 + 64, H - 6), (W // 2 - 64, H - 6)],
              fill=robe)
    d.polygon([(W // 2, 60), (W // 2 + 40, H - 6), (W // 2 - 8, H - 6)],
              fill=robe_dark)
    # the sleeves / arms
    d.ellipse([W // 2 - 76, 96, W // 2 - 30, 136], fill=robe)
    d.ellipse([W // 2 + 30, 96, W // 2 + 76, 136], fill=robe)
    # the hands (pale green like the hero family)
    d.ellipse([W // 2 - 62, 118, W // 2 - 40, 140], fill=(176, 226, 168, 255))
    if pose == "cast":
        # the cast pose: one hand raised with the curse glow
        d.ellipse([W // 2 + 44, 78, W // 2 + 70, 104], fill=(176, 226, 168, 255))
        glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        gd.ellipse([W // 2 + 34, 44, W // 2 + 82, 92], fill=(196, 96, 230, 130))
        glow = glow.filter(__import__("PIL.ImageFilter", fromlist=["GaussianBlur"])
                           .GaussianBlur(6))
        img.alpha_composite(glow)
    # the head
    d.ellipse([W // 2 - 30, 44, W // 2 + 30, 104], fill=(190, 232, 182, 255))
    # the eyes (angry)
    d.ellipse([W // 2 - 18, 64, W // 2 - 6, 78], fill=(52, 40, 66, 255))
    d.ellipse([W // 2 + 6, 64, W // 2 + 18, 78], fill=(52, 40, 66, 255))
    # the hooked nose
    d.polygon([(W // 2, 74), (W // 2 - 4, 92), (W // 2 + 8, 86)],
              fill=(160, 208, 152, 255))
    # the mouth (a crooked frown)
    d.arc([W // 2 - 12, 82, W // 2 + 12, 98], 20, 160, fill=(90, 60, 60, 255),
          width=3)
    # the hat: a tall crooked cone
    d.polygon([(W // 2 - 44, 52), (W // 2 + 44, 52), (W // 2 + 10, -10),
               (W // 2 - 2, -6)], fill=(86, 38, 124, 255))
    d.ellipse([W // 2 - 52, 44, W // 2 + 52, 62], fill=(70, 30, 102, 255))
    # the hat band + buckle
    d.rectangle([W // 2 - 44, 42, W // 2 + 44, 50], fill=(222, 170, 60, 255))
    # the hair wisps
    d.polygon([(W // 2 - 30, 70), (W // 2 - 44, 96), (W // 2 - 26, 92)],
              fill=(210, 210, 220, 255))
    d.polygon([(W // 2 + 30, 70), (W // 2 + 44, 96), (W // 2 + 26, 92)],
              fill=(210, 210, 220, 255))
    return img


def boot():
    """STRONG FOOT - a sturdy brown boot with a golden spark"""
    W, H = 96, 96
    img = _img(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([26, 18, 52, 62], fill=(146, 100, 62, 255))       # the leg
    d.rectangle([26, 18, 36, 62], fill=(120, 80, 48, 255))
    d.rounded_rectangle([22, 56, 78, 78], radius=8, fill=(110, 72, 44, 255))
    d.rounded_rectangle([22, 70, 78, 80], radius=5, fill=(84, 54, 34, 255))
    d.rectangle([46, 22, 52, 60], fill=(222, 170, 60, 255))       # the strap
    # the spark (the DOUBLE damage)
    for ang in range(0, 360, 90):
        a = math.radians(ang + 45)
        x, y = 74 + math.cos(a) * 10, 30 + math.sin(a) * 10
        d.line([74, 30, x, y], fill=(255, 210, 80, 255), width=4)
    d.ellipse([68, 24, 80, 36], fill=(255, 230, 140, 255))
    return img


def shield():
    """SHIELD - a wooden shield with a steel rim"""
    W, H = 96, 96
    img = _img(W, H)
    d = ImageDraw.Draw(img)
    pts = []
    for i in range(26):
        a = math.pi * i / 25.0
        pts.append((W // 2 + 34 * math.cos(a), 16 + 34 * math.sin(a)))
    d.polygon(pts + [(W // 2, 86)], fill=(146, 100, 62, 255))
    d.polygon([(p[0], p[1] + 4) for p in pts] + [(W // 2, 82)],
              fill=(120, 80, 48, 255))
    # the steel boss
    d.ellipse([W // 2 - 13, 32, W // 2 + 13, 58], fill=(168, 178, 190, 255))
    d.ellipse([W // 2 - 8, 36, W // 2 + 8, 50], fill=(206, 214, 224, 255))
    return img


def wing():
    """POWER JUMP - a springboard wing / feather"""
    W, H = 96, 96
    img = _img(W, H)
    d = ImageDraw.Draw(img)
    # the wing: three feathers fanning up
    for k, (dx, ln) in enumerate([(-16, 30), (0, 40), (16, 32)]):
        d.ellipse([W // 2 - 12 + dx, 22 - ln // 3, W // 2 + 12 + dx,
                   52 + ln // 3], fill=(168, 214, 244, 255))
        d.line([W // 2 + dx, 54, W // 2 + dx, 30 - ln // 4],
               fill=(120, 176, 214, 255), width=4)
    # the spring base
    d.rounded_rectangle([W // 2 - 20, 62, W // 2 + 20, 74], radius=6,
                        fill=(146, 100, 62, 255))
    d.rounded_rectangle([W // 2 - 26, 76, W // 2 + 26, 86], radius=6,
                        fill=(110, 72, 44, 255))
    return img


def curse_bolt():
    """the Witcher's projectile: a purple energy bolt with a tail"""
    W, H = 64, 40
    img = _img(W, H)
    d = ImageDraw.Draw(img)
    d.polygon([(2, H // 2), (34, 8), (W - 4, H // 2), (34, H - 8)],
              fill=(170, 90, 220, 235))
    d.polygon([(14, H // 2), (36, 15), (52, H // 2), (36, H - 15)],
              fill=(214, 150, 245, 255))
    d.ellipse([36, H // 2 - 7, 50, H // 2 + 7], fill=(240, 214, 255, 255))
    return img


def moon():
    """the night moon: a waxing crescent (the full disc minus an offset
    disc, painted on a mask so the bite is REAL transparency)"""
    W = 128
    img = _img(W, W)
    d = ImageDraw.Draw(img)
    d.ellipse([14, 14, W - 14, W - 14], fill=(245, 240, 214, 255))
    d.ellipse([30, 62, 44, 76], fill=(222, 214, 182, 255))
    d.ellipse([48, 40, 58, 50], fill=(222, 214, 182, 255))
    # the bite: a second disc up-right, CUT via the alpha mask
    bite = Image.new("L", (W, W), 0)
    bd = ImageDraw.Draw(bite)
    bd.ellipse([52, 0, W + 30, W - 34], fill=255)
    from PIL import ImageChops
    a = img.getchannel("A")
    img.putalpha(ImageChops.subtract(a, bite))
    return img


def main():
    witcher("float").save(os.path.join(OUT, "witcher.png"))
    witcher("cast").save(os.path.join(OUT, "witcher_cast.png"))
    boot().save(os.path.join(OUT, "pu_foot.png"))
    shield().save(os.path.join(OUT, "pu_shield.png"))
    wing().save(os.path.join(OUT, "pu_jump.png"))
    curse_bolt().save(os.path.join(OUT, "curse_bolt.png"))
    moon().save(os.path.join(OUT, "deco_moon.png"))
    # the review sheet on a grass-green backdrop
    sh = Image.new("RGB", (7 * 130 + 20, 250), (104, 176, 96))
    for i, f in enumerate(["witcher.png", "witcher_cast.png", "pu_foot.png",
                           "pu_shield.png", "pu_jump.png", "curse_bolt.png",
                           "deco_moon.png"]):
        im = Image.open(os.path.join(OUT, f)).convert("RGBA")
        im.thumbnail((120, 230))
        sh.paste(im, (14 + i * 130, 12), im)
    sh.save("/tmp/dario31_view.png")
    print("cursed dario pieces rendered")


if __name__ == "__main__":
    main()
