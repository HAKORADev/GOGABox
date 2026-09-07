#!/usr/bin/env python3
"""v0.3.5-4 POP SIEGE - THE BOOM TRUTH v2 (the owner's bomber round).

The old boom frames shrank into tiny lingering wisps (the owner: "screenshot
its latest moments, you will see how buggy it is") and frame 0 wore an ugly
dark-olive ring. The new set: ONE 128px canvas for every frame, the fireball
GROWS to fill the blast then the smoke puffs expand + fade to NOTHING - the
animation ends empty, nothing lingers, nothing floats.

Also: a tighter ps_boom (short body, fast decay - the old tail rang too long).
"""
import math, os, random
from PIL import Image, ImageDraw, ImageFilter

REPO = "/home/z/my-project/repo/GOGABox"
FX = f"{REPO}/projects/gogabox/assets/games/pop_siege/fx"
SFX_DIR = f"{REPO}/projects/gogabox/assets/audio/sfx"

SZ = 128
CX = CY = SZ / 2.0

def lerp(a, b, t):
    return a + (b - a) * t

def boom_frames():
    random.seed("gogaboom4")
    # timeline: 0 flash -> 1-3 fireball swell -> 4-5 smoke billow -> 6 fade-out
    # radii as a fraction of the canvas (the content peaks at ~0.94)
    plan = [
        # (fire_r, fire_alpha, smoke_r, smoke_alpha, flash)
        (0.16, 255, 0.00, 0, 1.0),
        (0.30, 255, 0.10, 70, 0.55),
        (0.42, 255, 0.22, 110, 0.0),
        (0.47, 235, 0.33, 140, 0.0),
        (0.36, 150, 0.44, 150, 0.0),
        (0.20, 70, 0.52, 120, 0.0),
        (0.05, 0, 0.56, 0, 0.0),
    ]
    for i, (fr, fa, sr, sa, flash) in enumerate(plan):
        im = Image.new("RGBA", (SZ, SZ), (0, 0, 0, 0))
        d = ImageDraw.Draw(im, "RGBA")
        # the smoke ring (behind): dark brown-grey puffs
        if sa > 0:
            n = 11
            for k in range(n):
                a = (k / n) * math.tau + (0.35 if i % 2 else 0.0)
                rr = sr * SZ * (0.42 + 0.3 * ((k * 37) % 5) / 5.0)
                px = CX + math.cos(a) * sr * SZ * 0.34
                py = CY + math.sin(a) * sr * SZ * 0.34
                col = (66, 52, 44, int(sa * 0.75)) if k % 2 == 0 else (88, 70, 56, int(sa * 0.55))
                d.ellipse([px - rr, py - rr, px + rr, py + rr], fill=col)
        # the fireball: layered cartoon flame (deep red rim -> orange -> yellow core)
        if fa > 0:
            rr = fr * SZ
            wob = [(math.cos(k * 2.3) * fr * SZ * 0.10) for k in range(12)]
            pts = []
            for k in range(12):
                a = k / 12.0 * math.tau
                r = rr * (0.86 + 0.14 * math.sin(a * 3 + i)) + wob[k] * 0.4
                pts.append((CX + math.cos(a) * r, CY + math.sin(a) * r))
            d.polygon(pts, fill=(196, 62, 22, fa))
            d.ellipse([CX - rr * 0.78, CY - rr * 0.78, CX + rr * 0.78, CY + rr * 0.78],
                      fill=(238, 116, 28, fa))
            d.ellipse([CX - rr * 0.5, CY - rr * 0.5, CX + rr * 0.5, CY + rr * 0.5],
                      fill=(252, 186, 52, fa))
            d.ellipse([CX - rr * 0.26, CY - rr * 0.26, CX + rr * 0.26, CY + rr * 0.26],
                      fill=(255, 240, 180, fa))
            # spark petals on the swell frames
            if i in (1, 2, 3):
                for k in range(7):
                    a = k / 7.0 * math.tau + i
                    sx = CX + math.cos(a) * rr * 1.05
                    sy = CY + math.sin(a) * rr * 1.05
                    d.ellipse([sx - 3.2, sy - 3.2, sx + 3.2, sy + 3.2],
                              fill=(255, 214, 96, min(255, fa + 20)))
        # the white flash core (frame 0-1 only)
        if flash > 0:
            fr2 = SZ * (0.34 if i == 0 else 0.2)
            fl = Image.new("RGBA", (SZ, SZ), (0, 0, 0, 0))
            fd = ImageDraw.Draw(fl)
            fd.ellipse([CX - fr2, CY - fr2, CX + fr2, CY + fr2], fill=(255, 255, 232, int(230 * flash)))
            fl = fl.filter(ImageFilter.GaussianBlur(6))
            im.alpha_composite(fl)
        im.save(f"{FX}/boom_0{i}.png")
    print("boom frames written: 7 (one canvas, grow then vanish)")

# ------------------------------------------------------------- the boom sfx
def write_wav(path, samples, rate=22050):
    import struct, wave
    w = wave.open(path, "w")
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(rate)
    frames = bytearray()
    for s in samples:
        s = max(-1.0, min(1.0, s))
        frames += struct.pack("<h", int(s * 32767))
    w.writeframes(bytes(frames))
    w.close()

def boom_sfx():
    """tight boom: brown-noise thump, 0.42s total, fast decay, soft crackle."""
    rate = 22050
    dur = 0.42
    n = int(rate * dur)
    out = []
    lp = 0.0
    random.seed("gogaboom4sfx")
    for i in range(n):
        t = i / float(rate)
        # the body: fast attack, exponential decay (the old tail rang ~1s)
        env = min(1.0, t / 0.004) * math.exp(-t * 11.0)
        brown = lp
        lp += (random.uniform(-1, 1) - lp) * 0.16
        body = brown * 3.1
        # a low sine thump for the chest
        thump = math.sin(math.tau * (58 - 26 * t) * t) * 0.7 * math.exp(-t * 9.0)
        # a short bright crackle in the first 90ms
        cr = random.uniform(-1, 1) * 0.32 * math.exp(-t * 34.0) if t < 0.09 else 0.0
        s = (body * 0.55 + thump * 0.6 + cr) * env * 0.9
        out.append(s)
    # a 30ms fade-out tail so the sample never clicks
    fade = int(rate * 0.03)
    for k in range(fade):
        out[n - 1 - k] *= k / float(fade)
    write_wav(f"{SFX_DIR}/ps_boom.wav", out)
    print("ps_boom.wav rewritten: 0.42s tight thump")

if __name__ == "__main__":
    boom_frames()
    boom_sfx()
