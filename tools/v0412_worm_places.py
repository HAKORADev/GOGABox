#!/usr/bin/env python3
"""v040-12 DEADLY WORM - THE ONE-PIECE GROUND LAW (the owner: "the under
ground design is inaccurate, you used something like grid or repeating
them, the correct design from you should be one big design for the whole
place ground as one piece, the other for walls accurately, this will make
it look more natural instead of literally seeing same ground repeated 4-7
times (and it is ugly as hell too)").

Bakes ONE unique underground cross-section per place (3200x800, drawn
stretched to the world's real WORLD_W x DIRT_H - aspect matched at 4:1):
- desert: sun-baked sand strata, a buried tomb chamber, bone pockets,
  hollow voids
- polar: frozen strata, blue ice veins, frost cracks
- city: packed dark soil, buried pipes + a subway rail bed
- jungle: a living root network, organic pockets, clay bands
- medieval: stony soil, a buried foundation wall, skulls

Also: dw_chomp.wav - the real bite's wet snap (the owner: "make it bite
for real"). Deterministic, idempotent.
"""
import math
import os
import random
import struct
import wave

from PIL import Image, ImageDraw, ImageFilter

OUT = ("/home/z/my-project/gogabox/projects/gogabox"
       "/assets/games/deathworm/places")
SFX = ("/home/z/my-project/gogabox/projects/gogabox"
       "/assets/audio/sfx")
os.makedirs(OUT, exist_ok=True)

W, H = 3200, 800

PLACES = {
    "desert": {"top": (146, 108, 62), "mid": (120, 86, 48),
               "deep": (86, 60, 34), "vein": (170, 130, 78),
               "bone": (222, 208, 178), "void": (30, 20, 12)},
    "polar": {"top": (150, 178, 200), "mid": (110, 142, 172),
              "deep": (74, 100, 130), "vein": (198, 228, 248),
              "bone": (220, 234, 246), "void": (22, 34, 50)},
    "city": {"top": (96, 92, 96), "mid": (74, 72, 78),
             "deep": (52, 52, 58), "vein": (128, 126, 134),
             "bone": (172, 170, 176), "void": (20, 20, 24)},
    "jungle": {"top": (94, 112, 56), "mid": (70, 88, 44),
               "deep": (48, 62, 32), "vein": (128, 148, 84),
               "bone": (196, 190, 150), "void": (18, 26, 12)},
    "medieval": {"top": (110, 96, 82), "mid": (86, 74, 62),
                 "deep": (60, 52, 44), "vein": (140, 126, 108),
                 "bone": (210, 198, 178), "void": (24, 20, 16)},
}


def strata(p, rnd):
    im = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(im)
    # the vertical base gradient (crust -> deep)
    for y in range(H):
        t = y / H
        if t < 0.18:
            c = p["top"]
        else:
            u = (t - 0.18) / 0.82
            c = tuple(int(p["mid"][i] + (p["deep"][i] - p["mid"][i]) * u)
                      for i in range(3))
        im.paste(c, (0, y, W, y + 1))
    # the strata BANDS: irregular horizontal seams, one piece - no tiles
    y = 40
    while y < H:
        bh = rnd.randint(50, 120)
        wob = []
        x = 0
        while x <= W:
            wob.append(y + rnd.randint(-14, 14))
            x += 160
        shade = rnd.uniform(0.86, 1.14)
        col = tuple(min(255, int(v * shade)) for v in p["mid"])
        pts = [(wx, wy) for wx, wy in zip(range(0, W + 160, 160), wob)]
        poly = pts + [(W, y + bh), (W, y + bh + 40)]
        d.polygon([(px, py) for px, py in zip([p2[0] for p2 in pts],
                    [p2[1] for p2 in pts])] +
                  [(W, min(H, y + bh)), (0, min(H, y + bh))],
                  fill=col)
        # the seam line
        d.line(pts, fill=tuple(int(v * 0.82) for v in p["deep"]), width=4)
        y += bh
    # pebble noise (single pass over the whole piece - never repeats)
    for i in range(900):
        x, y = rnd.randint(0, W - 8), rnd.randint(20, H - 8)
        r = rnd.randint(2, 7)
        c = tuple(int(v * rnd.uniform(0.75, 1.25)) for v in p["mid"])
        d.ellipse([x, y, x + r * 2, y + r], fill=c)
    return im


def decorations(p, rnd, place):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # the VEINS: one continuous system across the piece
    for i in range(14):
        x = rnd.randint(-100, W)
        y = rnd.randint(60, H - 60)
        pts = [(x, y)]
        for s in range(rnd.randint(5, 12)):
            x += rnd.randint(120, 340)
            y += rnd.randint(-70, 70)
            y = max(40, min(H - 20, y))
            pts.append((x, y))
        wdt = rnd.randint(4, 12)
        d.line(pts, fill=p["vein"] + (rnd.randint(70, 130),), width=wdt)
    # the VOIDS / hollows
    for i in range(10):
        x, y = rnd.randint(60, W - 60), rnd.randint(90, H - 70)
        rw, rh = rnd.randint(50, 150), rnd.randint(24, 60)
        d.ellipse([x - rw, y - rh, x + rw, y + rh], fill=p["void"] + (150,))
        d.ellipse([x - rw + 8, y - rh + 6, x + rw - 4, y + rh - 4],
                  fill=tuple(int(v * 0.7) for v in p["void"]) + (170,))
    if place == "desert":
        # the buried tomb chamber + bone pockets
        tx, ty = W // 2, int(H * 0.62)
        d.rounded_rectangle([tx - 220, ty - 90, tx + 220, ty + 90], 24,
                            fill=(52, 38, 26, 220), outline=(90, 66, 44, 255),
                            width=8)
        for i in range(6):
            bx = tx - 180 + i * 72
            d.ellipse([bx, ty - 26, bx + 54, ty + 26],
                      fill=p["bone"] + (255,))
            d.ellipse([bx + 14, ty - 12, bx + 40, ty + 12],
                      fill=(120, 96, 70, 255))
        for i in range(8):
            bx, by = rnd.randint(100, W - 100), rnd.randint(120, H - 60)
            d.ellipse([bx, by, bx + rnd.randint(24, 60), by + 14],
                      fill=p["bone"] + (200,))
    elif place == "polar":
        # ice lenses + frost cracks
        for i in range(16):
            x, y = rnd.randint(0, W), rnd.randint(60, H - 40)
            rw, rh = rnd.randint(40, 130), rnd.randint(10, 26)
            d.ellipse([x, y, x + rw, y + rh], fill=(210, 236, 252, 170))
        for i in range(24):
            x, y = rnd.randint(0, W), rnd.randint(40, H - 20)
            d.line([(x, y), (x + rnd.randint(-80, 80), y + rnd.randint(-24, 24))],
                   fill=(232, 246, 255, 110), width=2)
    elif place == "city":
        # the buried utilities: pipes + a rail bed
        for i in range(5):
            y = rnd.randint(120, H - 80)
            x = rnd.randint(-200, W - 600)
            d.rounded_rectangle([x, y, x + rnd.randint(420, 900), y + 44],
                                20, fill=(110, 104, 96, 220),
                                outline=(58, 54, 50, 255), width=5)
            d.line([(x + 20, y + 22), (x + 380, y + 22)],
                   fill=(150, 144, 134, 160), width=6)
        ry = int(H * 0.7)
        for i in range(2):
            d.line([(0, ry + i * 60), (W, ry + i * 60)],
                   fill=(96, 92, 100, 200), width=10)
        for bx in range(80, W, 320):
            d.rectangle([bx, ry - 8, bx + 26, ry + 68],
                        fill=(120, 116, 124, 210))
    elif place == "jungle":
        # the root network: branching organic curves
        for i in range(22):
            x, y = rnd.randint(0, W), rnd.randint(30, H - 30)
            pts = [(x, y)]
            for s in range(rnd.randint(4, 9)):
                x += rnd.randint(60, 240) * rnd.choice((-1, 1))
                y += rnd.randint(-50, 90)
                y = max(20, min(H - 10, y))
                pts.append((x, y))
            wdt = rnd.randint(6, 18)
            d.line(pts, fill=(74, 56, 34, 235), width=wdt)
            d.line([(a[0] + 2, a[1]) for a in pts],
                   fill=(112, 88, 52, 140), width=max(2, wdt // 3))
    else:  # medieval
        # a buried foundation wall + skulls
        wx, wy = int(W * 0.3), int(H * 0.66)
        for rowi in range(5):
            for cxi in range(10):
                bx = wx + cxi * 56 - (28 if rowi % 2 else 0)
                by = wy + rowi * 34
                d.rectangle([bx, by, bx + 50, by + 30],
                            fill=(96, 88, 78, 230), outline=(52, 46, 40, 255),
                            width=3)
        for i in range(10):
            sx, sy = rnd.randint(80, W - 80), rnd.randint(100, H - 50)
            d.ellipse([sx, sy, sx + 30, sy + 26], fill=p["bone"] + (220,))
            d.ellipse([sx + 6, sy + 8, sx + 12, sy + 14],
                      fill=(40, 34, 30, 255))
            d.ellipse([sx + 18, sy + 8, sx + 24, sy + 14],
                      fill=(40, 34, 30, 255))
    im = im.filter(ImageFilter.GaussianBlur(1))
    return im


def bake(place, p):
    rnd = random.Random(hash(place) % 99991)
    im = strata(p, rnd).convert("RGBA")
    dec = decorations(p, rnd, place)
    im = Image.alpha_composite(im, dec)
    # a gentle vertical darkening at the floor (the depth read)
    grad = Image.new("L", (1, H))
    for y in range(H):
        t = y / H
        grad.putpixel((0, y), int(90 * max(0.0, t - 0.55) / 0.45))
    grad = grad.resize((W, H))
    dark = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    dark.putalpha(grad)
    return Image.alpha_composite(im, dark)


def bake_chomp():
    """dw_chomp.wav - a wet snap: a fast jaw click + a low squelch."""
    sr = 22050
    dur = 0.22
    n = int(sr * dur)
    frames = bytearray()
    rnd = random.Random(70021)
    lp = 0.0
    for i in range(n):
        t = i / n
        # the click: two sharp noise bursts (jaw close)
        click = 0.0
        if t < 0.045 or (0.09 < t < 0.13):
            click = rnd.uniform(-1, 1) * (1.0 - t / 0.13)
        # the squelch: a falling lowpassed rumble
        lp += 0.12 * (rnd.uniform(-1, 1) - lp)
        squelch = lp * (1.0 - t) * (1.0 - t) * 1.6
        v = (0.7 * click + 0.8 * squelch)
        frames += struct.pack("<h", int(max(-1, min(1, v)) * 30000))
    with wave.open(f"{SFX}/dw_chomp.wav", "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        wf.writeframes(bytes(frames))
    print("dw_chomp.wav")


def main():
    for place, p in PLACES.items():
        im = bake(place, p)
        im.convert("RGB").save(f"{OUT}/{place}_dirt_big.png")
        print(f"{place}_dirt_big.png")
    bake_chomp()
    print("ONE-PIECE GROUND DONE")


if __name__ == "__main__":
    main()
