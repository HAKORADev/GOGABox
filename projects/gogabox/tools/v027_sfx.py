#!/usr/bin/env python3
"""v0.2.7 audio - the SNOWY TOWER shatter + the 2048 theme voices.

tower_break  the vanish platform SHATTERING (the owner: the break was
             static - the sound now carries the chunks)
m_slide      2048 classic slide (a soft wooden push)
m_pop        2048 classic merge (the bright satisfying pop, tier-pitched)
m_thud       Minecraft slide (a low blocky knock)
m_stone      Minecraft merge (stone grind + crack)
m_lava       Minecraft hot merge (the lava glug + hiss)
m_slosh      Deep Sea slide (the water swish)
m_splash     Deep Sea merge (the splash + droplets)

Same design law as v0.2.4/6: every voice has a body, an edge and a tail.
Re-runnable: same code -> same bytes."""

import math
import os
import wave

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(PROJ, "assets", "audio", "sfx")
SR = 44100

import numpy as np  # noqa: E402

RNG = np.random.default_rng(2707)


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
    for i in range(len(x)):
        acc += alpha * (x[i] - acc)
        y[i] = acc
    return y


def _noise(dur):
    return RNG.uniform(-1, 1, int(SR * dur))


def tower_break():
    # the shatter: a sharp crack burst + tumbling gravel tail
    dur = 0.55
    t = _t(dur)
    n = _noise(dur)
    crack = _lowpass(n, 0.55) * np.exp(-t * 18.0)
    gravel = _lowpass(_noise(dur), 0.18) * np.exp(-t * 6.5)
    thud = np.sin(2 * math.pi * 92 * t) * np.exp(-t * 12.0) * 0.7
    crunch = np.sign(crack) * np.minimum(np.abs(crack), 0.5) * 0.35
    data = (crack * 0.9 + gravel * 0.8 + thud + crunch) * _env(len(t), 0.002, 0.22)
    _save("tower_break", data, 0.9)


def m_slide():
    # the wooden push: a short filtered swish with a soft body
    dur = 0.09
    t = _t(dur)
    n = _lowpass(_noise(dur), 0.30)
    sweep = np.sin(2 * math.pi * (240 - 900 * t) * t)
    data = (n * 0.55 + sweep * 0.20) * np.exp(-t * 30.0) * _env(len(t), 0.003, 0.03)
    _save("m_slide", data, 0.55)


def m_pop():
    # the classic merge pop: a bright sine pop + a tiny click
    dur = 0.16
    t = _t(dur)
    body = np.sin(2 * math.pi * 660 * t) * np.exp(-t * 26.0)
    lift = np.sin(2 * math.pi * 990 * t + 1.4) * np.exp(-t * 34.0) * 0.5
    click = _lowpass(_noise(dur), 0.6) * np.exp(-t * 120.0) * 0.35
    data = (body + lift + click) * _env(len(t), 0.002, 0.05)
    _save("m_pop", data, 0.7)


def m_thud():
    # the blocky knock: a low square-ish body + a wood edge
    dur = 0.12
    t = _t(dur)
    body = np.sign(np.sin(2 * math.pi * 110 * t)) * 0.4 + np.sin(2 * math.pi * 110 * t) * 0.6
    body *= np.exp(-t * 28.0)
    edge = _lowpass(_noise(dur), 0.35) * np.exp(-t * 70.0) * 0.5
    data = (body + edge) * _env(len(t), 0.002, 0.04)
    _save("m_thud", data, 0.6)


def m_stone():
    # the grind: a gritty scrape resolving into a knock
    dur = 0.22
    t = _t(dur)
    grit = _lowpass(_noise(dur), 0.22) * np.exp(-t * 9.0)
    knock = np.sin(2 * math.pi * 165 * t) * np.exp(-t * 24.0) * 0.8
    spark = _lowpass(_noise(dur), 0.5) * np.exp(-(t - 0.10).clip(0) * 60.0) * 0.4
    data = (grit * 0.8 + knock + spark) * _env(len(t), 0.003, 0.07)
    _save("m_stone", data, 0.75)


def m_lava():
    # the glug: three descending bubbles + a hiss tail
    dur = 0.42
    t = _t(dur)
    data = np.zeros(len(t))
    for i, (f0, at) in enumerate([(220.0, 0.02), (160.0, 0.14), (110.0, 0.26)]):
        seg = t >= at
        tt = t[seg] - at
        bub = np.sin(2 * math.pi * (f0 + 90 * np.exp(-tt * 30)) * tt) \
                * np.exp(-tt * 22.0) * (0.7 - 0.12 * i)
        data[seg] += bub
    hiss = _lowpass(_noise(dur), 0.14) * np.exp(-t * 7.0) * 0.30
    data = (data + hiss) * _env(len(t), 0.004, 0.16)
    _save("m_lava", data, 0.85)


def m_slosh():
    # the swish: water pushing through a narrowed pipe (bandpassed noise)
    dur = 0.16
    t = _t(dur)
    n = _noise(dur)
    band = _lowpass(n, 0.12) - _lowpass(n, 0.05)
    shape = np.sin(math.pi * np.clip(t / dur, 0, 1)) ** 1.5
    drop = np.sin(2 * math.pi * (300 - 1200 * t) * t) * 0.18
    data = (band * 1.4 + drop) * shape * _env(len(t), 0.010, 0.05)
    _save("m_slosh", data, 0.8)


def m_splash():
    # the splash: the burst + scattered droplet pings
    dur = 0.38
    t = _t(dur)
    burst = _lowpass(_noise(dur), 0.4) * np.exp(-t * 16.0)
    body = np.sin(2 * math.pi * 240 * t) * np.exp(-t * 18.0) * 0.4
    data = (burst * 0.9 + body).copy()
    for at, f in [(0.08, 980.0), (0.15, 1240.0), (0.21, 1560.0)]:
        seg = t >= at
        tt = t[seg] - at
        ping = np.sin(2 * math.pi * f * tt) * np.exp(-tt * 30.0) * 0.16
        data[seg] += ping
    data *= _env(len(t), 0.002, 0.20)
    _save("m_splash", data, 0.85)


if __name__ == "__main__":
    tower_break()
    m_slide()
    m_pop()
    m_thud()
    m_stone()
    m_lava()
    m_slosh()
    m_splash()
    print("v0.2.7 sfx done")
