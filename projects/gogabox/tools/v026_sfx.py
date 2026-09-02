#!/usr/bin/env python3
"""v0.2.6 audio - the SNOWY TOWER additions: tower_melt (the warm fizz of
eating snow), tower_slap (a tumbling face slapping the platform) and
tower_puff (the melt-death poof). Same design law as v0.2.4: every voice
has a body, an edge and a tail. Re-runnable: same code -> same bytes."""

import math
import os
import wave

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(PROJ, "assets", "audio", "sfx")
SR = 44100

import numpy as np  # noqa: E402

RNG = np.random.default_rng(2606)


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
        e[-nr:] *= np.linspace(1, 0, nr)
    return e


def _lowpass(x, alpha):
    y = np.empty_like(x)
    acc = 0.0
    for i in range(x.size):
        acc += alpha * (x[i] - acc)
        y[i] = acc
    return y


def tower_melt():
    # the warm fizz: soft low-passed noise + two gentle sines gliding down
    dur = 0.55
    t = _t(dur)
    n = RNG.normal(0, 1, t.size)
    fizz = _lowpass(n, 0.12) * 0.5
    s1 = np.sin(2 * math.pi * (520 - 160 * t / dur) * t) * 0.22
    s2 = np.sin(2 * math.pi * (784 - 240 * t / dur) * t) * 0.12
    body = np.sin(2 * math.pi * 110 * t) * 0.10 * (1 - t / dur)
    _save("tower_melt", (fizz + s1 + s2 + body) * _env(t.size, 0.01, 0.20), 0.9)


def tower_slap():
    # the face-down slap: a fast low thud + a tight noise tick
    dur = 0.16
    t = _t(dur)
    thud = np.sin(2 * math.pi * (150 - 620 * t) * t) * np.exp(-t * 42) * 0.9
    tick = _lowpass(RNG.normal(0, 1, t.size), 0.30) * np.exp(-t * 90) * 0.5
    _save("tower_slap", (thud + tick) * _env(t.size, 0.002, 0.05), 0.95)


def tower_puff():
    # the melt-death poof: a breathy descending poof with a sad tail
    dur = 0.75
    t = _t(dur)
    n = _lowpass(RNG.normal(0, 1, t.size), 0.18)
    sweep = np.sin(2 * math.pi * (340 - 250 * t / dur) * t) * 0.30
    tail = np.sin(2 * math.pi * 92 * t) * 0.18 * np.exp(-t * 5)
    puff = n * np.exp(-t * 6) * 0.7
    _save("tower_puff", (puff + sweep * np.exp(-t * 4.5) + tail)
          * _env(t.size, 0.006, 0.30), 0.95)


if __name__ == "__main__":
    tower_melt()
    tower_slap()
    tower_puff()
    print("v026 sfx done")
