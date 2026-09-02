#!/usr/bin/env python3
"""v0.3.1 audio - CURSED DARIO's voices (the platformer set).

d_jump      the hero jump (a quick rising boing)
d_stomp     the enemy stomp (a thud + a squeak)
d_hurt      Dario hurt (a soft descending squawk)
d_coin      the GOGACoin from a ? block (bright pick + sparkle)
d_bump      the block bump (a knock)
d_power     the powerup rise (an ascending 4-note)
d_clear     the level clear (a short fanfare)
d_bosshit   the Witcher hit (a heavy magic thud)
d_bossdie   the Witcher defeated (a slow dark dissolve)
d_curse     the curse bolt fired (a hissing whip)
d_shot      the shooter enemy's spit
d_lands     the death fall (a soft long drop)

Design law: bodies + edges + tails. Re-runnable: same code -> same bytes."""

import math
import os
import wave

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(PROJ, "assets", "audio", "sfx")
SR = 44100

import numpy as np  # noqa: E402

RNG = np.random.default_rng(310311)


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


def _env(n, a=0.004, r=0.10, curve=1.0):
    e = np.ones(n)
    na, nr = int(SR * a), int(SR * r)
    na, nr = min(na, n), min(nr, n)
    if na > 0:
        e[:na] = np.linspace(0, 1, na)
    if nr > 0:
        e[-nr:] *= np.linspace(1, 0, nr) ** curve
    return e


def _lowpass(x, alpha):
    y = np.empty_like(x)
    acc = 0.0
    for i in range(x.size):
        acc += alpha * (x[i] - acc)
        y[i] = acc
    return y


def _noise(dur):
    return RNG.uniform(-1.0, 1.0, int(SR * dur))


def _sweep(dur, f0, f1, kind="sine"):
    t = _t(dur)
    ph = 2 * math.pi * (f0 * t + (f1 - f0) * t * t / (2 * dur))
    if kind == "tri":
        return 2.0 / math.pi * np.arcsin(np.sin(ph))
    return np.sin(ph)


def _pluck(f0, f1, dur, vol=1.0, warm=0.3):
    t = _t(dur)
    ph = 2 * math.pi * (f0 * t + (f1 - f0) * t * t / (2 * dur))
    body = np.sin(ph) + warm * np.sin(2 * ph)
    return body * np.exp(-t * 9.0) * _env(t.size, a=0.003, r=min(0.08, dur * 0.4)) * vol


# ---------------------------------------------------------------- voices

def d_jump():
    dur = 0.16
    body = _sweep(dur, 300, 640) * np.exp(-_t(dur) * 10.0)
    _save("d_jump", body * _env(int(SR * dur), a=0.003, r=0.05), 0.5)


def d_stomp():
    dur = 0.18
    t = _t(dur)
    thud = _sweep(dur, 180, 70) * np.exp(-t * 18.0)
    squeak = _sweep(dur, 900, 500) * np.exp(-t * 26.0) * 0.4
    _save("d_stomp", thud * 0.9 + squeak, 0.62)


def d_hurt():
    dur = 0.34
    t = _t(dur)
    body = _sweep(dur, 520, 240, "tri") * np.exp(-t * 8.0)
    wob = 1.0 + 0.15 * np.sin(2 * math.pi * 30.0 * t)
    _save("d_hurt", body * wob * 0.7, 0.6)


def d_coin():
    body = _pluck(1318.5, 1318.5, 0.2, 0.5, warm=0.2)
    tail = _pluck(1975.5, 2093.0, 0.3, 0.3, warm=0.15)
    out = np.zeros(int(SR * 0.45))
    out[:body.size] += body
    i0 = int(SR * 0.09)
    out[i0:i0 + tail.size] += tail
    _save("d_coin", out, 0.6)


def d_bump():
    dur = 0.12
    t = _t(dur)
    body = _sweep(dur, 220, 120) * np.exp(-t * 24.0)
    knock = _lowpass(_noise(dur), 0.3) * np.exp(-t * 40.0) * 0.5
    _save("d_bump", body * 0.8 + knock, 0.55)


def d_power():
    total = 0.6
    out = np.zeros(int(SR * total))
    for f, at in [(392.0, 0.0), (523.25, 0.09), (659.25, 0.18), (783.99, 0.27)]:
        i0 = int(SR * at)
        pluck = _pluck(f, f, 0.28, 0.5)
        out[i0:i0 + pluck.size] += pluck
    _save("d_power", out, 0.66)


def d_clear():
    total = 1.1
    out = np.zeros(int(SR * total))
    seq = [(523.25, 0.0), (659.25, 0.12), (783.99, 0.24), (1046.5, 0.36),
           (783.99, 0.56), (1046.5, 0.68)]
    for f, at in seq:
        i0 = int(SR * at)
        pluck = _pluck(f, f, 0.34, 0.42, warm=0.25)
        out[i0:i0 + pluck.size] += pluck
    _save("d_clear", out, 0.72)


def d_bosshit():
    dur = 0.3
    t = _t(dur)
    body = _sweep(dur, 240, 90) * np.exp(-t * 12.0)
    magic = _sweep(dur, 900, 300) * np.exp(-t * 18.0) * 0.35
    _save("d_bosshit", body * 0.9 + magic, 0.68)


def d_bossdie():
    total = 1.3
    out = np.zeros(int(SR * total))
    for f, at in [(660.0, 0.0), (550.0, 0.16), (440.0, 0.34), (330.0, 0.54),
                  (220.0, 0.76)]:
        i0 = int(SR * at)
        pluck = _pluck(f, f * 0.98, 0.4, 0.42, warm=0.4)
        out[i0:i0 + pluck.size] += pluck
    hiss = _lowpass(_noise(total), 0.15) * _env(int(SR * total), a=0.3,
            r=0.7) * 0.12
    _save("d_bossdie", out + hiss, 0.7)


def d_curse():
    dur = 0.22
    n = int(SR * dur)
    body = _sweep(dur, 1200, 300) * np.exp(-_t(dur) * 10.0)
    hiss = _lowpass(_noise(dur), 0.4) * _env(n, a=0.004, r=0.1) * 0.4
    _save("d_curse", body * 0.5 + hiss, 0.5)


def d_shot():
    dur = 0.14
    body = _sweep(dur, 700, 260) * np.exp(-_t(dur) * 16.0)
    _save("d_shot", body * 0.55, 0.42)


def d_lands():
    dur = 0.8
    t = _t(dur)
    body = _sweep(dur, 600, 120, "tri") * np.exp(-t * 5.0)
    _save("d_lands", body * 0.5, 0.55)


if __name__ == "__main__":
    d_jump()
    d_stomp()
    d_hurt()
    d_coin()
    d_bump()
    d_power()
    d_clear()
    d_bosshit()
    d_bossdie()
    d_curse()
    d_shot()
    d_lands()
    print("v0.3.1 cursed dario voices done")
