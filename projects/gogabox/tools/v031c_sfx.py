#!/usr/bin/env python3
"""v0.3.1 PATCH III audio - the three new voices for the new enemy AI.

d_windup   the rhino's charge telegraph (a low rising snort-grunt)
d_gallop   the rhino sprint (fast heavy double-hoof beats)
d_bat      the hunting bat's screech (a falling shriek)

Design law: bodies + edges + tails. Re-runnable: same code -> same bytes."""

import math
import os
import wave

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(PROJ, "assets", "audio", "sfx")
SR = 44100

import numpy as np  # noqa: E402

RNG = np.random.default_rng(310313)


def _save(name, data, vol=1.0):
    data = np.clip(data * vol, -1.0, 1.0)
    pcm = (data * 32767).astype(np.int16)
    if pcm.ndim == 1:
        pcm = np.column_stack([pcm, pcm])
    with wave.open(os.path.join(SFX, name + ".wav"), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("assets/audio/sfx/%s.wav" % name)


def _t(dur):
    return np.linspace(0, dur, int(SR * dur), endpoint=False)


def _env(n, a=0.004, r=0.10):
    e = np.ones(n)
    na, nr = int(SR * a), int(SR * r)
    na, nr = min(na, n), min(nr, n)
    if na > 0:
        e[:na] = np.linspace(0, 1, na)
    if nr > 0:
        e[n - nr:] = np.linspace(1, 0, nr)
    return e


# ---------------------------------------------------------------- d_windup
# the telegraph: two low snorts rising into a tense growl (0.45s)
tt = _t(0.45)
f0 = 90.0 + 130.0 * (tt / 0.45) ** 1.6
snort = np.sign(np.sin(2 * np.pi * f0 * tt)) * 0.35 \
        + np.sin(2 * np.pi * f0 * 0.5 * tt) * 0.5
growl = RNG.normal(0, 1, len(tt)) * 0.16
b = np.where((tt % 0.11) < 0.05, 1.0, 0.0)     # the snort gate
wind = (snort * b + growl * (0.4 + 0.6 * (tt / 0.45))) * _env(len(tt), 0.006, 0.09)
_save("d_windup", wind, 0.9)

# ---------------------------------------------------------------- d_gallop
# the sprint: four accelerating hoof pairs, heavy thud + dirt flick (1.1s)
dur = 1.1
tt = _t(dur)
gal = np.zeros(len(tt))
hits = [(0.02, 1.0), (0.10, 0.7), (0.26, 1.0), (0.34, 0.75),
        (0.48, 1.0), (0.56, 0.8), (0.68, 1.0), (0.76, 0.85),
        (0.88, 1.0), (0.96, 0.9)]
for at, amp in hits:
    i0 = int(at * SR)
    n = int(0.075 * SR)
    if i0 + n > len(gal):
        n = len(gal) - i0
    tb = _t(0.075)[:n]
    thud = np.sin(2 * np.pi * (70.0 - 30.0 * tb / 0.075) * tb) \
            * np.exp(-tb * 55.0) * amp
    dirt = RNG.normal(0, 1, n) * np.exp(-tb * 90.0) * 0.3 * amp
    gal[i0:i0 + n] += thud + dirt
gal *= _env(len(gal), 0.002, 0.14)
_save("d_gallop", gal, 0.95)

# ------------------------------------------------------------------- d_bat
# the hunt screech: a falling shriek with a flutter (0.5s)
tt = _t(0.5)
f0 = 2400.0 - 1500.0 * (tt / 0.5) ** 1.2
shriek = np.sin(2 * np.pi * np.cumsum(f0) / SR)
flutter = 0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 46.0 * tt))
air = RNG.normal(0, 1, len(tt)) * 0.08
bat = (shriek * flutter * 0.5 + air) * _env(len(tt), 0.004, 0.22)
_save("d_bat", bat, 0.55)

print("done")
