#!/usr/bin/env python3
"""v040-9 DEADLY WORM - the voice. 15 synthesized dw_* sfx + two loops.

The house synth law (v0.2.9's): every voice has a body, an edge and a tail;
bodies are warm sines/triangles, noise is low-passed and quiet, everything
deterministic (same code -> same bytes).

dw_click   a dry wooden tick (dead buttons, dry widgets)
dw_bite    a wet crunch (biting a vehicle)
dw_chew    a soft gulp (eating a thing)
dw_coin    a bright pickup ping + sparkle tail (the wormCoin lands)
dw_power   a rising two-tone (charge ready / power-up grabbed)
dw_dash    a whoosh burst (the dash)
dw_hurt    a dull thud + growl tail (the worm takes it)
dw_boom    a vehicle explosion (body + noise burst + long tail)
dw_shot    a short crack (enemy fire)
dw_level   a rising arpeggio (the worm levels up)
dw_unlock  a triumphant three-note (a worm / a place unlocked)
dw_fly     a soft airy blip (a power-up enters)
dw_special the special's roar-swipe (per-use voice)
dw_roar    THE worm roar (intro + the roar special)
dw_die     the run's end: a falling groan + dirt fall
dw_music_desert   a 12s desert drone loop (menu / run bed)
dw_music_ice      a 12s icy drone loop (the ICE's bed)
"""
import math
import os
import wave

import numpy as np

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(PROJ, "assets", "audio", "sfx")
SR = 44100
RNG = np.random.default_rng(40909)


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
    print("  " + name)


def _t(dur):
    return np.linspace(0, dur, int(SR * dur), endpoint=False)


def _env(n, a, r, hold=1.0):
    e = np.ones(n) * hold
    na = max(1, int(a * SR))
    nr = max(1, int(r * SR))
    e[:na] *= np.linspace(0, 1, na)
    e[-nr:] *= np.linspace(1, 0, nr)
    return e


def _lp(x, alpha):
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += alpha * (x[i] - acc)
        y[i] = acc
    return y


def _noise(dur, lp_alpha=0.12):
    return _lp(RNG.normal(0, 1, int(SR * dur)), lp_alpha)


def _tone(freq, dur, kind="sine"):
    t = _t(dur)
    if kind == "sine":
        return np.sin(2 * math.pi * freq * t)
    if kind == "tri":
        return 2.0 / math.pi * np.arcsin(np.sin(2 * math.pi * freq * t))
    return np.sign(np.sin(2 * math.pi * freq * t)) * 0.6


def _sweep(f0, f1, dur, kind="sine"):
    t = _t(dur)
    ph = 2 * math.pi * (f0 * t + (f1 - f0) * t * t / (2 * dur))
    if kind == "tri":
        return 2.0 / math.pi * np.arcsin(np.sin(ph))
    return np.sin(ph)


# ------------------------------------------------------------------ voices
def sfx_click():
    d = 0.05
    v = _tone(1900, d, "tri") * _env(int(SR * d), 0.001, 0.03) * 0.5
    v += _noise(d, 0.5) * _env(int(SR * d), 0.001, 0.02) * 0.2
    _save("dw_click", v, 0.5)


def sfx_bite():
    d = 0.22
    n = int(SR * d)
    v = _noise(d, 0.09) * _env(n, 0.004, 0.12) * 1.1
    v += _sweep(220, 60, d) * _env(n, 0.002, 0.14) * 0.8
    crunch = RNG.normal(0, 1, n) * (RNG.random(n) < 0.04) * _env(n, 0.001,
                                                                0.1)
    v += _lp(crunch, 0.3) * 1.6
    _save("dw_bite", v, 0.85)


def sfx_chew():
    d = 0.16
    n = int(SR * d)
    v = _sweep(340, 110, d) * _env(n, 0.004, 0.09) * 0.9
    v += _noise(d, 0.2) * _env(n, 0.003, 0.06) * 0.35
    _save("dw_chew", v, 0.7)


def sfx_coin():
    d = 0.3
    n = int(SR * d)
    d2 = 0.12
    n2 = int(SR * d2)
    v = _tone(1180, d) * _env(n, 0.002, 0.2) * 0.6
    v += _tone(1760, d) * _env(n, 0.002, 0.24) * 0.35
    v[:n2] += _tone(2640, d2) * _env(n2, 0.002, 0.1) * 0.2
    _save("dw_coin", v, 0.62)


def sfx_power():
    d = 0.42
    n = int(SR * d)
    v = _sweep(440, 880, d, "tri") * _env(n, 0.01, 0.2) * 0.7
    v += _sweep(660, 1320, d) * _env(n, 0.01, 0.24) * 0.35
    _save("dw_power", v, 0.66)


def sfx_dash():
    d = 0.34
    n = int(SR * d)
    v = _noise(d, 0.05) * _env(n, 0.02, 0.2) * 1.2
    v += _sweep(180, 520, d, "tri") * _env(n, 0.01, 0.18) * 0.4
    _save("dw_dash", v, 0.72)


def sfx_hurt():
    d = 0.3
    n = int(SR * d)
    v = _sweep(200, 70, d, "tri") * _env(n, 0.004, 0.18) * 1.0
    v += _noise(d, 0.08) * _env(n, 0.002, 0.12) * 0.8
    _save("dw_hurt", v, 0.8)


def sfx_boom():
    d = 0.7
    n = int(SR * d)
    v = _noise(d, 0.035) * _env(n, 0.004, 0.5) * 2.0
    v += _sweep(120, 32, d) * _env(n, 0.002, 0.5) * 1.3
    _save("dw_boom", v, 0.95)


def sfx_shot():
    d = 0.12
    n = int(SR * d)
    v = _noise(d, 0.25) * _env(n, 0.001, 0.08) * 1.4
    v += _sweep(900, 200, d) * _env(n, 0.001, 0.08) * 0.5
    _save("dw_shot", v, 0.55)


def sfx_level():
    seq = [523, 659, 784, 1047]
    d = 0.13
    parts = [_tone(f, d, "tri") * _env(int(SR * d), 0.004, 0.06)
             for f in seq]
    _save("dw_level", np.concatenate(parts) * 0.62, 0.62)


def sfx_unlock():
    seq = [(392, 0.14), (523, 0.14), (784, 0.34)]
    parts = []
    for f, d in seq:
        n = int(SR * d)
        parts.append((_tone(f, d, "tri") + _tone(f * 2, d) * 0.4)
                     * _env(n, 0.006, d * 0.6))
    _save("dw_unlock", np.concatenate(parts) * 0.6, 0.7)


def sfx_fly():
    d = 0.4
    n = int(SR * d)
    v = _sweep(700, 1100, d) * _env(n, 0.08, 0.24) * 0.4
    v += _tone(1760, d) * _env(n, 0.06, 0.3) * 0.16
    _save("dw_fly", v, 0.5)


def sfx_special():
    d = 0.55
    n = int(SR * d)
    v = _sweep(140, 420, d, "tri") * _env(n, 0.03, 0.3) * 0.9
    v += _noise(d, 0.06) * _env(n, 0.02, 0.3) * 0.7
    v += _sweep(280, 840, d) * _env(n, 0.04, 0.3) * 0.3
    _save("dw_special", v, 0.8)


def sfx_roar():
    d = 1.1
    n = int(SR * d)
    v = _sweep(90, 46, d, "tri") * _env(n, 0.05, 0.6) * 1.2
    wob = np.sin(2 * math.pi * 11 * _t(d)) * 0.35 + 1.0
    v *= wob
    v += _noise(d, 0.045) * _env(n, 0.04, 0.5) * 0.9
    _save("dw_roar", v, 0.9)


def sfx_die():
    d = 1.3
    n = int(SR * d)
    v = _sweep(160, 38, d, "tri") * _env(n, 0.02, 0.9) * 1.1
    v += _noise(d, 0.03) * _env(n, 0.02, 1.0) * 0.7
    _save("dw_die", v, 0.85)


# ------------------------------------------------------------------- loops
def _loop(name, root, drift, shimmer, dur=12.0):
    t = _t(dur)
    v = np.zeros_like(t)
    for i, mult in enumerate([1.0, 1.5, 2.0, 3.0]):
        wob = np.sin(2 * math.pi * (0.07 + 0.03 * i) * t + i)
        v += np.sin(2 * math.pi * root * mult * t + i * 1.7) * (0.5 / (i + 1)) * (1.0 + wob * drift)
    v += _noise(dur, 0.012) * shimmer
    # the seam: crossfade the tail into the head
    f = int(0.5 * SR)
    v[:f] = v[:f] * np.linspace(0, 1, f) + v[-f:] * np.linspace(1, 0, f)
    v = v[:-f]
    _save(name, v * 0.28, 0.5)


def main():
    sfx_click()
    sfx_bite()
    sfx_chew()
    sfx_coin()
    sfx_power()
    sfx_dash()
    sfx_hurt()
    sfx_boom()
    sfx_shot()
    sfx_level()
    sfx_unlock()
    sfx_fly()
    sfx_special()
    sfx_roar()
    sfx_die()
    _loop("dw_music_desert", 55.0, 0.5, 0.05)
    _loop("dw_music_ice", 62.0, 0.6, 0.09)
    print("DONE")


if __name__ == "__main__":
    main()
