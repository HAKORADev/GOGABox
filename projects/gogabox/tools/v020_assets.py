#!/usr/bin/env python3
"""v0.2.0 art + SFX - the PLACE icons (day garden / night garden optionals
boxes) and two new snake SFX (portal whoosh for the mirror wall crossing,
collapse razzle for the death fold). Re-runnable: same code -> same bytes."""

import math
import os
import wave

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UI = os.path.join(PROJ, "assets", "ui")
SFX = os.path.join(PROJ, "assets", "audio", "sfx")
SR = 22050

import numpy as np  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402


def place_day():
    """DAY GARDEN: a warm sun over a green lawn with grass tufts."""
    S = 96
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # sky band + lawn
    d.rounded_rectangle([6, 6, 90, 90], radius=14, fill=(174, 216, 134, 255))
    d.rounded_rectangle([6, 6, 90, 40], radius=14, fill=(150, 204, 116, 255))
    d.rectangle([6, 30, 90, 46], fill=(150, 204, 116, 255))
    # the sun with rays
    for i in range(8):
        a = math.tau * i / 8.0
        x0, y0 = 48 + math.cos(a) * 20, 26 + math.sin(a) * 20
        x1, y1 = 48 + math.cos(a) * 26, 26 + math.sin(a) * 26
        d.line([x0, y0, x1, y1], fill=(255, 210, 90, 255), width=4)
    d.ellipse([32, 10, 64, 42], fill=(255, 232, 154, 255))
    d.ellipse([38, 16, 58, 36], fill=(255, 244, 200, 255))
    # grass tufts
    for x in (22, 48, 74):
        d.line([x, 84, x - 5, 70], fill=(95, 148, 68, 255), width=3)
        d.line([x, 84, x + 5, 70], fill=(95, 148, 68, 255), width=3)
        d.line([x, 84, x, 66], fill=(79, 138, 62, 255), width=3)
    # a tiny flower
    for a in range(6):
        ang = math.tau * a / 6.0
        d.ellipse([34 + math.cos(ang) * 7 - 3, 62 + math.sin(ang) * 7 - 3,
                   34 + math.cos(ang) * 7 + 3, 62 + math.sin(ang) * 7 + 3],
                  fill=(255, 255, 255, 230))
    d.ellipse([31, 59, 37, 65], fill=(255, 200, 60, 255))
    img.save(os.path.join(UI, "place_day.png"))
    print("assets/ui/place_day.png")


def place_night():
    """NIGHT GARDEN: crescent moon, stars and two tiny flies over dark grass."""
    S = 96
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([6, 6, 90, 90], radius=14, fill=(44, 63, 85, 255))
    d.rounded_rectangle([6, 6, 90, 40], radius=14, fill=(28, 42, 61, 255))
    d.rectangle([6, 30, 90, 46], fill=(28, 42, 61, 255))
    # stars
    for x, y, r in ((26, 16, 2), (66, 14, 2), (78, 30, 3), (16, 34, 2),
                    (58, 26, 2)):
        d.ellipse([x - r, y - r, x + r, y + r], fill=(238, 244, 255, 235))
    # crescent moon: bright disc with a sky-colored bite
    d.ellipse([46, 14, 82, 50], fill=(238, 244, 255, 255))
    d.ellipse([56, 10, 88, 44], fill=(28, 42, 61, 255))
    # tiny flies (glow dots)
    for x, y in ((30, 52), (52, 60)):
        d.ellipse([x - 5, y - 5, x + 5, y + 5], fill=(255, 232, 102, 70))
        d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=(255, 246, 192, 240))
    # dark grass tufts
    for x in (22, 48, 74):
        d.line([x, 86, x - 5, 72], fill=(93, 130, 166, 255), width=3)
        d.line([x, 86, x + 5, 72], fill=(93, 130, 166, 255), width=3)
        d.line([x, 86, x, 68], fill=(74, 106, 138, 255), width=3)
    img.save(os.path.join(UI, "place_night.png"))
    print("assets/ui/place_night.png")


def _write_wav(name, samples):
    p = os.path.join(SFX, name)
    os.makedirs(SFX, exist_ok=True)
    data = (np.clip(samples, -1.0, 1.0) * 32767).astype(np.int16)
    with wave.open(p, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print("assets/audio/sfx/" + name)


def sfx_portal():
    """The mirror-wall crossing: a quick airy whoosh (noise sweep + a soft
    fifth slide up) - short, never annoying."""
    dur = 0.34
    n = int(SR * dur)
    t = np.linspace(0, dur, n, False)
    noise = np.random.default_rng(20).standard_normal(n)
    # band-pass-ish: moving average smooths into an airy puff
    kernel = np.ones(10) / 10.0
    noise = np.convolve(noise, kernel, mode="same")
    sweep = np.sin(2 * np.pi * (340 + 520 * t / dur) * t)
    fifth = np.sin(2 * np.pi * (510 + 780 * t / dur) * t) * 0.4
    env = np.sin(np.pi * t / dur) ** 1.5
    sig = (noise * 0.5 + sweep * 0.5 + fifth) * env * 0.55
    _write_wav("portal.wav", sig)


def sfx_collapse():
    """The death fold: a fast descending razzle (pitch zipper) with a soft
    thud at the end - the tail racing into the head."""
    dur = 0.5
    n = int(SR * dur)
    t = np.linspace(0, dur, n, False)
    f = 620 * np.exp(-3.2 * t) + 60
    phase = 2 * np.pi * np.cumsum(f) / SR
    sig = np.sin(phase) * 0.6 + np.sin(phase * 2.02) * 0.25
    # the thud
    thud_n = int(SR * 0.09)
    thud_t = np.linspace(0, 0.09, thud_n, False)
    thud = np.sin(2 * np.pi * 70 * thud_t) * np.exp(-28 * thud_t) * 0.9
    sig[-thud_n:] += thud
    env = np.minimum(1.0, t / 0.01) * np.exp(-2.2 * t)
    _write_wav("collapse.wav", sig * env * 0.8)


if __name__ == "__main__":
    place_day()
    place_night()
    sfx_portal()
    sfx_collapse()
