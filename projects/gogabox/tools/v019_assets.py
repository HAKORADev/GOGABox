#!/usr/bin/env python3
"""v0.1.9 art + SFX - the battery popup icon, the phone-position cards for
the snake's orientation select, and the four new snake SFX (power good/bad,
tail bite, bug hit). Re-runnable: same code -> same bytes."""

import math
import os
import struct
import sys

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UI = os.path.join(PROJ, "assets", "ui")
SFX = os.path.join(PROJ, "assets", "audio", "sfx")

from PIL import Image, ImageDraw  # noqa: E402

INK = (53, 33, 15, 255)
GOOD = (88, 196, 112, 255)
CARD = (255, 243, 220, 255)
ACCENT = (255, 176, 32, 255)
DARK = (24, 14, 7, 255)


def icon_battery():
    """A full battery: shell + tip + 3 charge bars + a tiny spark. Green
    reads 'charged' at popup size."""
    S = 96
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # tip
    d.rounded_rectangle([38, 8, 58, 16], radius=3, fill=CARD)
    # shell
    d.rounded_rectangle([16, 14, 80, 84], radius=12, fill=DARK,
                        outline=CARD, width=5)
    # charge bars
    for i in range(3):
        x = 25 + i * 18
        d.rounded_rectangle([x, 25, x + 13, 73], radius=4, fill=GOOD)
    img.save(os.path.join(UI, "icon_battery.png"))
    print("assets/ui/icon_battery.png")


def _phone_card(size, landscape):
    """A chunky phone glyph with a little motion arc, showing how the phone
    is held. Used at ~220px on the snake's select cards."""
    S = size
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    w, h = (S * 0.52, S * 0.86) if not landscape else (S * 0.86, S * 0.52)
    x0, y0 = (S - w) / 2, (S - h) / 2
    # motion arcs behind the phone
    for k, r in enumerate((0.62, 0.78)):
        box = [S / 2 - S * r, S / 2 - S * r, S / 2 + S * r, S / 2 + S * r]
        a0 = -35 if not landscape else 55
        a1 = 35 if not landscape else 125
        d.arc(box, a0, a1, fill=(122, 108, 180, 160), width=int(S * 0.035))
        d.arc(box, a0 + 180, a1 + 180, fill=(122, 108, 180, 160),
              width=int(S * 0.035))
    # body
    d.rounded_rectangle([x0, y0, x0 + w, y0 + h], radius=S * 0.09,
                        fill=DARK, outline=CARD, width=max(4, int(S * 0.035)))
    # screen (the snake field, tiny)
    m = S * 0.055
    d.rounded_rectangle([x0 + m, y0 + m, x0 + w - m, y0 + h - m],
                        radius=S * 0.05, fill=(246, 231, 205, 255))
    # a tiny green snake wiggle on the screen
    sw = max(3, int(S * 0.022))
    pts = []
    for i in range(24):
        t = i / 23.0
        px = x0 + m + t * (w - 2 * m)
        py = y0 + h / 2 + math.sin(t * math.pi * 2.2) * (h * 0.16)
        pts.append((px, py))
    d.line(pts, fill=(63, 127, 212, 255), width=sw, joint="curve")
    # home dot
    dot = S * 0.02
    d.ellipse([S / 2 - dot, (y0 + h - m * 0.5) - dot,
               S / 2 + dot, (y0 + h - m * 0.5) + dot], fill=CARD)
    return img


def phone_icons():
    _phone_card(320, False).save(os.path.join(UI, "phone_vertical.png"))
    print("assets/ui/phone_vertical.png")
    _phone_card(320, True).save(os.path.join(UI, "phone_horizontal.png"))
    print("assets/ui/phone_horizontal.png")


# ----------------------------------------------------------------- SFX
SR = 44100


def _env(i, n, a=0.01, r=0.6):
    """attack/release envelope"""
    t = i / n
    att = min(1.0, t / max(a, 1e-4))
    rel = min(1.0, (1.0 - t) / max(r, 1e-4))
    return att * rel


def _sine(f, t):
    return math.sin(2 * math.pi * f * t)


def write_wav(name, samples, vol=0.55):
    data = b"".join(struct.pack("<h", int(max(-1, min(1, s * vol)) * 32767))
                    for s in samples)
    hdr = b"RIFF" + struct.pack("<I", 36 + len(data)) + b"WAVE" + \
        b"fmt " + struct.pack("<IHHIIHH", 16, 1, 1, SR, SR * 2, 2, 16) + \
        b"data" + struct.pack("<I", len(data))
    with open(os.path.join(SFX, name), "wb") as f:
        f.write(hdr + data)
    print("assets/audio/sfx/%s" % name)


def power_good():
    """Bright two-note rise with a sparkle fifth on top. 0.42s."""
    n = int(SR * 0.42)
    out = []
    for i in range(n):
        t = i / SR
        f = 660.0 if t < 0.16 else 880.0
        s = _sine(f, t) + 0.45 * _sine(f * 2, t) + 0.22 * _sine(f * 3, t)
        out.append(s * _env(i, n, 0.01, 0.5))
    write_wav("power_good.wav", out)


def power_bad():
    """Wobble down: the 'uh oh' of a cursed fruit. 0.5s."""
    n = int(SR * 0.5)
    out = []
    for i in range(n):
        t = i / SR
        f = 340.0 - 160.0 * (t / 0.5)
        vib = 1.0 + 0.06 * math.sin(2 * math.pi * 9.0 * t)
        s = _sine(f * vib, t) + 0.4 * _sine(f * 0.5 * vib, t)
        out.append(s * _env(i, n, 0.015, 0.45))
    write_wav("power_bad.wav", out)


def tail_bite():
    """A wet crunch: filtered noise snap + low thump. 0.28s."""
    import random
    random.seed(19)
    n = int(SR * 0.28)
    out = []
    lp = 0.0
    for i in range(n):
        t = i / SR
        noise = random.uniform(-1, 1) * (1.0 - t / 0.28) ** 2
        lp += 0.35 * (noise - lp)
        thump = _sine(150.0 - 90.0 * t, t) * (1.0 - t / 0.28)
        s = 0.8 * lp + 0.5 * thump
        out.append(s * _env(i, n, 0.004, 0.55))
    write_wav("tail_bite.wav", out)


def bug_hit():
    """Squish + ding of losing points: noise burst then minor second. 0.34s."""
    import random
    random.seed(7)
    n = int(SR * 0.34)
    out = []
    for i in range(n):
        t = i / SR
        body = 0.0
        if t < 0.08:
            body = random.uniform(-1, 1) * (1.0 - t / 0.08)
        f = 520.0 if t < 0.18 else 490.0   # minor-second rub
        tone = _sine(f, t) * (1.0 - max(0.0, (t - 0.08) / 0.26))
        s = 0.6 * body + 0.5 * tone
        out.append(s * _env(i, n, 0.004, 0.5))
    write_wav("bug_hit.wav", out)


def ghost_shimmer():
    """Airy shimmer for GHOST power. 0.4s."""
    n = int(SR * 0.4)
    out = []
    for i in range(n):
        t = i / SR
        s = _sine(1180, t) + 0.5 * _sine(1560, t) + 0.3 * _sine(2360, t)
        tremble = 0.75 + 0.25 * math.sin(2 * math.pi * 14 * t)
        out.append(s * tremble * _env(i, n, 0.05, 0.55))
    write_wav("ghost.wav", out)


# ------------------------------------------------------- optional-box glyphs
# little ink-on-cream glyphs for the snake OPTIONALS squares (enemy /
# power-ups / bugs / obstacles / fruits). Cream glyph on ink disc so they
# read on any card color.

def _glyph_disc(name, painter):
    S = 96
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([6, 6, 90, 90], fill=(35, 21, 10, 255))
    painter(d, S)
    img.save(os.path.join(UI, name))
    print("assets/ui/%s" % name)


def opt_icons():
    CREAM = (246, 231, 205, 255)

    def snake_glyph(d, S):
        pts = []
        for i in range(26):
            t = i / 25.0
            pts.append((24 + t * 48, 62 - math.sin(t * math.pi * 1.7) * 20))
        d.line(pts, fill=(96, 176, 110, 255), width=9, joint="curve")
        d.ellipse([64, 24, 84, 44], fill=(96, 176, 110, 255))
        d.ellipse([72, 30, 77, 35], fill=CREAM)

    def power_glyph(d, S):
        d.polygon([(52, 16), (34, 50), (46, 50), (40, 80), (64, 42), (50, 42)],
                  fill=(255, 176, 32, 255))

    def bug_glyph(d, S):
        d.ellipse([30, 34, 66, 74], fill=(196, 120, 60, 255))
        d.line([(48, 36), (48, 72)], fill=(35, 21, 10, 255), width=3)
        d.ellipse([41, 22, 55, 36], fill=(120, 70, 30, 255))
        for s in (-1, 1):
            for k in range(3):
                y = 42 + k * 11
                d.line([(48 + s * 18, y), (48 + s * 30, y - 8)],
                       fill=(120, 70, 30, 255), width=4)

    def obst_glyph(d, S):
        for r in range(3):
            y = 30 + r * 16
            xoff = -8 if r % 2 else 0
            for c in range(3):
                x = 20 + c * 20 + xoff
                d.rectangle([x, y, x + 17, y + 13], fill=(154, 124, 84, 255))

    def fruit_glyph(d, S):
        d.ellipse([30, 34, 66, 72], fill=(220, 90, 76, 255))
        d.rectangle([46, 24, 50, 36], fill=(120, 80, 30, 255))
        d.ellipse([50, 20, 66, 32], fill=(96, 176, 110, 255))

    _glyph_disc("opt_enemy.png", snake_glyph)
    _glyph_disc("opt_power.png", power_glyph)
    _glyph_disc("opt_bugs.png", bug_glyph)
    _glyph_disc("opt_obst.png", obst_glyph)
    _glyph_disc("opt_fruit.png", fruit_glyph)


if __name__ == "__main__":
    os.makedirs(UI, exist_ok=True)
    os.makedirs(SFX, exist_ok=True)
    icon_battery()
    phone_icons()
    power_good()
    power_bad()
    tail_bite()
    bug_hit()
    ghost_shimmer()
    opt_icons()
    print("v0.1.9 assets done")
