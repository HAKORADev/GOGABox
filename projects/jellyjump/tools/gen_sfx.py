#!/usr/bin/env python3
"""Generate JellyJump's gameplay SFX as 16-bit mono WAVs (44.1 kHz).

Output: ../assets/audio/synth/{jump,coin,spring,crumble,gameover}.wav
Run from anywhere:  python3 tools/gen_sfx.py
Only needs numpy. All sounds are original (CC0 with the rest of the project).
"""
import os
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "synth")


def env(n, attack=0.005, decay=None):
    """attack/decay envelope; decay = seconds until near-zero."""
    t = np.linspace(0, 1, n)
    e = np.minimum(t / max(attack, 1e-4), 1.0)
    if decay:
        d = np.exp(-t * (SR / (decay * SR)) * 6)
        e *= d
    return e


def sweep(f0, f1, dur, shape="sine", wobble=0.0):
    n = int(SR * dur)
    t = np.arange(n) / SR
    freqs = np.geomspace(f0, f1, n)
    phase = 2 * np.pi * np.cumsum(freqs) / SR
    if wobble:
        phase += wobble * np.sin(2 * np.pi * 22 * t)
    if shape == "sine":
        return np.sin(phase)
    if shape == "tri":
        return 2 / np.pi * np.arcsin(np.sin(phase))
    if shape == "square":
        return np.sign(np.sin(phase)) * 0.6
    return np.sin(phase)


def noise(dur):
    n = int(SR * dur)
    x = np.random.default_rng(7).uniform(-1, 1, n)
    # cheap lowpass: cumulative moving average
    k = 24
    x = np.convolve(x, np.ones(k) / k, mode="same")
    return x / (np.abs(x).max() + 1e-9)


def save(name, sig, gain=0.8):
    sig = np.asarray(sig, dtype=np.float64)
    m = np.abs(sig).max()
    if m > 0:
        sig = sig / m * gain
    pcm = (sig * 32767).astype(np.int16)
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("wrote", name + ".wav", f"{len(pcm)/SR:.2f}s")


# jump: soft springy boing (sweep down with wobble)
dur = 0.22
n = int(SR * dur)
sig = sweep(520, 170, dur, wobble=1.4) * env(n, 0.004, 0.16)
save("jump", sig, 0.75)

# coin: bright two-tone ding
a = sweep(1568, 1568, 0.055) * env(int(SR * 0.055), 0.002, 0.05)
b = sweep(2093, 2093, 0.16) * env(int(SR * 0.16), 0.002, 0.14)
save("coin", np.concatenate([a, b]), 0.65)

# spring: rising twang
dur = 0.28
n = int(SR * dur)
sig = sweep(170, 760, dur, shape="tri", wobble=2.2) * env(n, 0.004, 0.22)
save("spring", sig, 0.8)

# crumble: noise burst + crackles
dur = 0.34
n = int(SR * dur)
sig = noise(dur) * env(n, 0.002, 0.24)
for at, ln in [(0.05, 0.05), (0.14, 0.04), (0.22, 0.03)]:
    i = int(SR * at)
    seg = noise(ln) * env(int(SR * ln), 0.001, 0.03) * 0.8
    sig[i:i + len(seg)] += seg[: max(0, n - i)]
save("crumble", sig, 0.85)

# gameover: descending minor arpeggio sting
notes = [440.0, 329.63, 261.63, 220.0]
parts = []
for i, f in enumerate(notes):
    d = 0.17 if i < 3 else 0.45
    n = int(SR * d)
    tone = (np.sin(2 * np.pi * f * np.arange(n) / SR)
            + 0.4 * np.sin(2 * np.pi * f / 2 * np.arange(n) / SR))
    parts.append(tone * env(n, 0.004, d * 0.8))
save("gameover", np.concatenate(parts), 0.8)
