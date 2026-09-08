#!/usr/bin/env python3
"""v036p3_gf_art.py - GEOMETRY FLASH (v0.3.6-3) art additions.

THE WORLD LAW round: the owner retired the "one big triangle" spike - the
spike is now THREE SMALL triangles on a surface base (spike3.png), with a
calculated WIDE-LOW dodge box (120 x 48 design px) a normal hop clears from
anywhere. Same design language as v036/v036p1: neon that feels FILLED,
gradient bodies, near-white edges so the themes recolor by modulate,
gentle baked glow. All original, all deterministic.

Re-derive: python3 tools/v036p3_gf_art.py
"""
import os
from PIL import Image, ImageDraw, ImageFilter

DEST = "projects/gogabox/assets/games/geometry"


def out_path(name):
    os.makedirs(DEST, exist_ok=True)
    return os.path.join(DEST, name)


def save(im, name):
    p = out_path(name)
    im.save(p)
    print(f"  {name:16s} {im.width}x{im.height}")


def vgrad(w, h, top, bottom):
    im = Image.new("RGBA", (w, h))
    px = im.load()
    for y in range(h):
        t = y / max(1, h - 1)
        c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,)
        for x in range(w):
            px[x, y] = c
    return im


def draw_spike3(w=252, h=120):
    """The owner's spike: 3 small triangles on a base bar.

    Canvas is 2x design (126 x 60). The BASE BOTTOM edge sits on the sprite's
    bottom row - the game centers the sprite 30 design px above the surface
    so the base lands exactly ON it. Hitbox: 116 x 48 design px (the game's
    hw/hh), the drawn row stays just outside it - honest and dodge-able."""
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    base_h = 18
    tri_w, gap, m = 72, 8, 8
    y_base = h - base_h

    # 1. the baked glow behind everything (white -> theme-tinted)
    def halo(d):
        for i in range(3):
            x0 = m + i * (tri_w + gap)
            ax = (x0 + x0 + tri_w) // 2
            d.polygon([(ax, y_base - 78), (x0 + 3, y_base + 2),
                       (x0 + tri_w - 3, y_base + 2)],
                      outline=(255, 255, 255, 210), width=6)
        d.rectangle((m - 2, y_base, w - m + 2, h), fill=(255, 255, 255, 150))
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    halo(ImageDraw.Draw(layer))
    im.alpha_composite(layer.filter(ImageFilter.GaussianBlur(8)))

    # 2. the base bar: dark body + bright top edge (a surface read)
    body = vgrad(w, base_h, (30, 38, 58, 255), (14, 18, 30, 255))
    im.paste(body, (0, y_base))
    d = ImageDraw.Draw(im)
    d.rectangle((0, y_base, w, y_base + 4), fill=(246, 250, 255, 255))
    d.rectangle((0, y_base + 5, w, y_base + 10), fill=(150, 190, 255, 80))
    d.rectangle((0, h - 3, w, h), fill=(60, 74, 110, 200))

    # 3. the three triangles: filled gradient + white structure line + edge
    for i in range(3):
        x0 = m + i * (tri_w + gap)
        ax = x0 + tri_w // 2
        poly = [(ax, y_base - 76), (x0 + 4, y_base + 1), (x0 + tri_w - 4, y_base + 1)]
        grad = vgrad(tri_w, 78, (214, 230, 255, 240), (66, 86, 138, 170))
        mask = Image.new("L", (tri_w, 78), 0)
        ImageDraw.Draw(mask).polygon(
            [(tri_w // 2, 0), (4, 77), (tri_w - 4, 77)], fill=255)
        im.paste(grad, (x0, y_base - 77), mask)
        d = ImageDraw.Draw(im)
        # the inner structure line (the GD anatomy)
        d.line([(ax, y_base - 52), (ax, y_base - 6)], fill=(255, 255, 255, 120), width=3)
        d.polygon(poly, outline=(250, 252, 255, 255), width=4)
    return im


def main():
    print("v036p3 art:")
    save(draw_spike3(), "spike3.png")
    print("done")


if __name__ == "__main__":
    main()
