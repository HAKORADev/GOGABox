#!/usr/bin/env python3
"""Generate candyrush synth SFX (deterministic, numpy -> 16-bit mono WAV).

Fills the gaps the CC0 downloads don't cover: coin, star, sparkle, lose, swap,
boom. (Match pops, deep pop, music loop, UI clicks, win jingle = downloaded
CC0 - see assets.manifest.json.) Run from anywhere:
    python3 projects/candyrush/tools/gen_sfx.py
"""
import os
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio", "synth")


def env(n, a=0.005, r=0.25):
    e = np.ones(n)
    na, nr = max(1, int(a * SR)), max(1, int(r * n))
    e[:na] = np.linspace(0, 1, na)
    e[-nr:] *= np.linspace(1, 0, nr)
    return e


def tone(freq, dur, vol=0.6, harmonics=((1, 1.0), (2, 0.35), (3, 0.12))):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = np.zeros(n)
    for mult, amp in harmonics:
        s += amp * np.sin(2 * np.pi * freq * mult * t)
    return vol * s * env(n, 0.004, 0.5) / max(1.0, sum(a for _, a in harmonics))


def noise_burst(dur, vol=0.4):
    n = int(dur * SR)
    x = np.random.default_rng(7).standard_normal(n)
    x = np.diff(np.concatenate([[0], x]))  # brighten
    return vol * x * env(n, 0.002, 0.6) / (np.abs(x).max() + 1e-9)


def sweep(f0, f1, dur, vol=0.5):
    n = int(dur * SR)
    t = np.arange(n) / SR
    ph = 2 * np.pi * (f0 * t + (f1 - f0) * t * t / (2 * dur))
    return vol * np.sin(ph) * env(n, 0.003, 0.4)


def save(name, x):
    os.makedirs(OUT, exist_ok=True)
    x = np.clip(x, -1, 1)
    data = (x * 32000).astype("<i2").tobytes()
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)
    print(" ", name, round(len(x) / SR, 2), "s")


# coin: two quick rising dings (B5 -> E6)
save("coin.wav", np.concatenate([tone(987, 0.09, 0.5), tone(1318, 0.16, 0.55)]))

# star: fast rising arpeggio C6-E6-G6-C7
save("star.wav", np.concatenate([tone(f, 0.07, 0.5) for f in (1046, 1318, 1568, 2093)]))

# sparkle: airy noise + high downward shimmer (special candy created)
nsp = max(int(0.22 * SR), int(0.10 * SR))
_sp = noise_burst(0.10, 0.25)
sp = np.zeros(nsp)
sp[: len(_sp)] += _sp
_s2 = sweep(4200, 1400, 0.22, 0.30)
sp[: len(_s2)] += _s2
save("sparkle.wav", sp)

# lose: soft descending three-tone sigh (G4-E4-C4)
save("lose.wav", np.concatenate([tone(392, 0.18, 0.45), tone(330, 0.18, 0.45), tone(262, 0.34, 0.5)]))

# swap: tiny airy whoosh up
n = int(0.09 * SR)
sw = np.random.default_rng(3).standard_normal(n)
k = np.exp(-np.linspace(0, 4, n))
sw = np.convolve(sw, np.ones(8) / 8, "same") * k
save("swap.wav", 0.30 * sw / (np.abs(sw).max() + 1e-9))

# boom: deep color-bomb blast (sub thump + noise)
bn = int(0.45 * SR)
t = np.arange(bn) / SR
thump = np.sin(2 * np.pi * (110 * np.exp(-t * 6)) * t) * np.exp(-t * 7)
boom = thump * 1.4 + noise_burst(0.45, 0.5) * np.exp(-t * 9)
save("boom.wav", boom * 0.9)
