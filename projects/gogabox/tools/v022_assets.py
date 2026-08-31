#!/usr/bin/env python3
"""v0.2.2 art - the PONG thumbnail (the dark court, the burn ball, the
tail) + the optionals glyphs (size / speed / sparkles / more walls) and
the snake JUMP FRUITS glyph.

Re-runnable: same code -> same bytes."""

import math
import os

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UI = os.path.join(PROJ, "assets", "ui")
THUMBS = os.path.join(PROJ, "assets", "thumbs")

from PIL import Image, ImageDraw, ImageFilter  # noqa: E402

W, H = 960, 640


def _rr(d, box, r, **kw):
    d.rounded_rectangle(box, radius=r, **kw)


def thumb():
    """PONG: the dark court, blue vs red platforms, the hot ball with its
    tail mid-flight, the goal strips, the light shreds."""
    img = Image.new("RGB", (W, H), (14, 14, 19))
    d = ImageDraw.Draw(img)
    # light shreds
    for i in range(46):
        x = (i * 211) % W
        y = (i * 389) % H
        r = 1 + (i % 3)
        a = 26 + (i * 37) % 40
        d.ellipse([x - r, y - r, x + r, y + r], fill=(235, 238, 255, a))
    img = img.filter(ImageFilter.GaussianBlur(0.6))
    d = ImageDraw.Draw(img)
    # the center dashed line (vertical court)
    for k in range(7):
        y = 40 + k * 84
        d.rectangle([W // 2 - 3, y, W // 2 + 3, y + 44], fill=(255, 255, 255, 22))
    # goal strips
    d.rectangle([0, 0, W, 8], fill=(63, 127, 212))
    d.rectangle([0, H - 8, W, H], fill=(232, 64, 47))
    # platforms (capsules)
    def capsule(cx, cy, hl, ht, col, lit):
        d.rounded_rectangle([cx - hl - 3, cy - ht - 3, cx + hl + 3,
                             cy + ht + 3], radius=ht + 3, fill=(12, 12, 16))
        d.rounded_rectangle([cx - hl, cy - ht, cx + hl, cy + ht],
                            radius=ht, fill=col)
        d.rounded_rectangle([cx - hl * 0.8, cy + ht * 0.15,
                             cx + hl * 0.8, cy + ht * 0.62],
                            radius=6, fill=lit)
    capsule(300, 84, 150, 20, (232, 64, 47), (255, 150, 130))
    capsule(610, 556, 170, 22, (63, 127, 212), (140, 190, 255))
    # the tail: fading discs toward the ball
    bx, by = 640, 300
    for i in range(14):
        t = i / 13.0
        x = bx - (i * 21) - 8
        y = by + (i * 7)
        r = 15 * (1.0 - 0.72 * t) + 1
        a = int(200 * (1.0 - t) ** 1.5)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 120 + int(80 * t),
                                                      40, a))
    # the ball (hot, glowing)
    for gr in (30, 20, 12):
        d.ellipse([bx - gr, by - gr, bx + gr, by + gr],
                  fill=(255, 90, 40))
    d.ellipse([bx - 14, by - 14, bx + 14, by + 14], fill=(255, 210, 80))
    d.ellipse([bx - 5, by - 6, bx + 2, by + 1], fill=(255, 255, 230))
    # coins
    for cx, cy in (170, 380), (830, 210):
        d.ellipse([cx - 16, cy - 16, cx + 16, cy + 16], fill=(140, 96, 20))
        d.ellipse([cx - 13, cy - 13, cx + 13, cy + 13], fill=(255, 201, 60))
        d.ellipse([cx - 6, cy - 7, cx + 1, cy], fill=(255, 240, 180))
    # powerup badge: a speed chevron
    _rr(d, [420, 430, 476, 486], 10, fill=(16, 16, 24),
        outline=(255, 180, 60), width=3)
    for ox in (0, 14):
        d.line([438 + ox, 444, 450 + ox, 458], fill=(255, 180, 60), width=4)
        d.line([450 + ox, 458, 438 + ox, 472], fill=(255, 180, 60), width=4)
    img.save(os.path.join(THUMBS, "rally.png"))
    print("assets/thumbs/rally.png")


def _badge(name, painter):
    S = 96
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    painter(d, S)
    img.save(os.path.join(UI, name + ".png"))
    print("assets/ui/%s.png" % name)


def opt_jump():
    """SNAKE JUMPING FRUITS: an apple mid-jump with motion arcs."""
    def p(d, S):
        # jump arcs
        for i, r in enumerate((34, 26, 18)):
            d.arc([48 - r, 58 - r, 48 + r, 58 + r], 200, 340,
                  fill=(122, 180, 240, 190), width=4)
        # the apple
        d.ellipse([32, 18, 64, 50], fill=(232, 87, 74, 255))
        d.ellipse([37, 23, 45, 31], fill=(255, 220, 200, 230))
        d.line([48, 18, 51, 10], fill=(122, 74, 30, 255), width=4)
        d.ellipse([51, 4, 62, 13], fill=(88, 196, 112, 255))
        # the landing dot
        d.ellipse([43, 72, 53, 78], fill=(236, 217, 180, 200))
    _badge("opt_jump", p)


def pong_opt_size():
    def p(d, S):
        _rr(d, [14, 14, 82, 82], 16, fill=(28, 28, 38, 255),
            outline=(88, 196, 112, 255), width=4)
        for y in (34, 62):
            d.line([26, y, 40, y], fill=(88, 196, 112, 255), width=5)
            d.line([22, y, 30, y - 5], fill=(88, 196, 112, 255), width=4)
            d.line([22, y, 30, y + 5], fill=(88, 196, 112, 255), width=4)
            d.line([70, y, 56, y], fill=(88, 196, 112, 255), width=5)
            d.line([74, y, 66, y - 5], fill=(88, 196, 112, 255), width=4)
            d.line([74, y, 66, y + 5], fill=(88, 196, 112, 255), width=4)
    _badge("pong_opt_size", p)


def pong_opt_speed():
    def p(d, S):
        _rr(d, [14, 14, 82, 82], 16, fill=(28, 28, 38, 255),
            outline=(255, 180, 60, 255), width=4)
        for ox in (0, 16):
            d.line([34 + ox, 32, 52 + ox, 48], fill=(255, 180, 60, 255),
                   width=6)
            d.line([52 + ox, 48, 34 + ox, 64], fill=(255, 180, 60, 255),
                   width=6)
    _badge("pong_opt_speed", p)


def pong_opt_sparkle():
    def p(d, S):
        _rr(d, [14, 14, 82, 82], 16, fill=(28, 28, 38, 255),
            outline=(240, 240, 255, 255), width=4)
        cx, cy = 48, 48
        for r in (22, 13):
            d.polygon([(cx, cy - r), (cx + r * 0.35, cy - r * 0.35),
                       (cx + r, cy), (cx + r * 0.35, cy + r * 0.35),
                       (cx, cy + r), (cx - r * 0.35, cy + r * 0.35),
                       (cx - r, cy), (cx - r * 0.35, cy - r * 0.35)],
                      fill=(250, 250, 255, 235))
        for x, y in ((26, 26), (70, 30), (30, 68)):
            d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=(255, 255, 255, 200))
    _badge("pong_opt_sparkle", p)


def pong_opt_more():
    def p(d, S):
        _rr(d, [14, 14, 82, 82], 16, fill=(28, 28, 38, 255),
            outline=(232, 64, 47, 255), width=4)
        # three small walls
        for x, y, vert in ((30, 30, True), (66, 30, True), (48, 60, False)):
            if vert:
                _rr(d, [x - 5, y - 5, x + 5, y + 22], 5,
                    fill=(232, 64, 47, 255))
            else:
                _rr(d, [x - 14, y - 5, x + 14, y + 5], 5,
                    fill=(232, 64, 47, 255))
    _badge("pong_opt_more", p)


if __name__ == "__main__":
    thumb()
    opt_jump()
    pong_opt_size()
    pong_opt_speed()
    pong_opt_sparkle()
    pong_opt_more()
