#!/usr/bin/env python3
"""v042-1 r2: regenerate assets/ui/icon_lan.png from the owner's shape
(circle head + arch body + plus top-left) - the same geometry as
icon_lan.svg, drawn with PIL at 4x supersampling, transparent plate."""

from PIL import Image, ImageDraw

SS = 4          # supersample
S = 96 * SS     # working size


def rr(d, x, y, w, h, r, fill):
    d.rounded_rectangle([x, y, x + w, y + h], radius=r, fill=fill)


def main():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    white = (255, 255, 255, 240)   # fill-opacity 0.94 like the svg
    k = SS

    # the plus, top-left
    rr(d, 7 * k, 21 * k, 25 * k, 8 * k, 4 * k, white)
    rr(d, 15.5 * k, 12.5 * k, 8 * k, 25 * k, 4 * k, white)

    # the body: one arch, flat at the bottom edge (upper half of the
    # circle centered at (62, 96) r 33.6 - the bbox dips below the canvas)
    d.pieslice([28.4 * k, (96 - 33.6) * k, 95.6 * k, (96 + 33.6) * k],
               start=180, end=360, fill=white)

    # the head: a proper round circle floating over the arch
    d.ellipse([(62 - 24) * k, (30 - 24) * k, (62 + 24) * k, (30 + 24) * k],
              fill=white)

    out = img.resize((96, 96), Image.LANCZOS)
    out.save("/home/z/my-project/gogabox/projects/gogabox/assets/ui/icon_lan.png")
    print("icon_lan.png written", out.size)


if __name__ == "__main__":
    main()
