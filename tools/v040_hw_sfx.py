#!/usr/bin/env python3
"""HEAVY WAR sfx tool (v040) - every event sound synthesized from scratch
(numpy: noise, sines, saw swells, envelopes). 100% ours; zero source bytes.
Output: projects/gogabox/assets/audio/sfx/hw_*.ogg (the Jukebox resolves
res://assets/audio/sfx/<name>.(ogg|wav|mp3) - the game calls Jukebox.sfx).
"""
import os, subprocess
import numpy as np

SR = 44100
OUT = "/home/z/my-project/gogabox/projects/gogabox/assets/audio/sfx"
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(20260915)

def t(dur):
    return np.linspace(0, dur, int(SR * dur), endpoint=False)

def env(n, a=0.005, r=0.2, shape=1.0):
    """attack/release envelope over n samples"""
    e = np.ones(n)
    na = max(1, int(SR * a))
    nr = max(1, int(SR * r))
    e[:na] = np.linspace(0, 1, na)
    e[-nr:] *= np.linspace(1, 0, nr) ** shape
    return e

def noise(dur):
    return rng.uniform(-1, 1, int(SR * dur))

def lowpass(x, alpha):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y

def sweep_lp(x, a0, a1):
    """time-varying one-pole lowpass"""
    y = np.empty_like(x)
    acc = 0.0
    alphas = np.linspace(a0, a1, len(x))
    for i, v in enumerate(x):
        acc += alphas[i] * (v - acc)
        y[i] = acc
    return y

def sine(f, dur, ph=0.0):
    return np.sin(2 * np.pi * f * t(dur) + ph)

def saw(f, dur):
    return 2 * ((f * t(dur)) % 1.0) - 1

def norm(x, gain=0.9):
    m = np.max(np.abs(x))
    return (x / m * gain) if m > 0 else x

def save(name, x, gain=0.9):
    x = norm(np.asarray(x, dtype=np.float64), gain)
    pcm = (x * 32767).astype(np.int16)
    stereo = np.column_stack([pcm, pcm])
    raw = f"/tmp/hw_{name}.raw"
    stereo.tofile(raw)
    dst = f"{OUT}/hw_{name}.ogg"
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "s16le", "-ar",
                    str(SR), "-ac", "2", "-i", raw, "-c:a", "libvorbis",
                    "-q:a", "4", dst], check=True)
    os.remove(raw)
    print("hw_%s %.2fs" % (name, len(x) / SR))

# ---------------------------------------------------------------- the gun
x = sweep_lp(noise(0.09), 0.5, 0.08) * env(int(SR * 0.09), 0.001, 0.05)
x += 0.5 * sine(1900, 0.09) * env(int(SR * 0.09), 0.001, 0.07) ** 2
save("fire", x, 0.72)

# ---------------------------------------------------------------- the booms
def boom(dur, f0, f1, sub=0.0):
    x = sweep_lp(noise(dur), f0, f1) * env(int(SR * dur), 0.002, dur * 0.8, 2.0)
    if sub > 0:
        x += sub * sine(46, dur) * env(int(SR * dur), 0.002, dur * 0.9, 1.5)
    return x

save("boom", boom(0.55, 0.4, 0.05, 0.6), 0.95)
save("bigboom", boom(1.1, 0.3, 0.03, 0.9), 1.0)

x = boom(0.9, 0.35, 0.03, 1.0)
extra = np.concatenate([boom(0.5, 0.4, 0.05), np.zeros(int(SR * 0.35)),
                        boom(0.45, 0.35, 0.04)])
x[:len(extra)] += 0.8 * extra[:len(x)]
save("nuke", x, 1.0)

# ---------------------------------------------------------------- the whistles
d = 0.85
f = np.linspace(1400, 380, int(SR * d))
x = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(int(SR * d), 0.05, 0.3)
save("bombfall", x, 0.5)

# ---------------------------------------------------------------- metal
d = 0.28
x = (0.6 * np.sign(sine(812, d)) + 0.4 * np.sign(sine(1237, d))) \
        * env(int(SR * d), 0.001, 0.22, 3)
x += 0.3 * sine(2440, d) * env(int(SR * d), 0.001, 0.2, 4)
save("shieldhit", x, 0.7)

d = 0.42
x = lowpass(noise(d), 0.15) * env(int(SR * d), 0.001, 0.3, 2) \
        + 0.8 * sine(150, d) * env(int(SR * d), 0.001, 0.3, 2) \
        + 0.3 * sine(97, d) * env(int(SR * d), 0.001, 0.35, 2)
save("tankhit", x, 0.95)

d = 0.16
x = sine(2380, d) * env(int(SR * d), 0.001, 0.13, 5) \
        + 0.4 * sine(3170, d) * env(int(SR * d), 0.001, 0.12, 5)
save("rico", x, 0.5)

# ---------------------------------------------------------------- pickups
def ding(fs, dur, gap=0.0):
    parts = []
    for i, f in enumerate(fs):
        seg = sine(f, dur) * env(int(SR * dur), 0.004, dur * 0.7, 1.5)
        parts.append(seg)
        if gap > 0 and i < len(fs) - 1:
            parts.append(np.zeros(int(SR * gap)))
    return np.concatenate(parts)

save("pickup", ding([880, 1318], 0.16, 0.02), 0.6)
save("coin", ding([1568, 2093, 2637], 0.11, 0.015), 0.55)

# ---------------------------------------------------------------- the friend
d = 1.3
x = sine(88, d) * (0.55 + 0.45 * np.sign(np.sin(2 * np.pi * 21 * t(d))))
x = lowpass(x, 0.12) + 0.25 * lowpass(noise(d), 0.06)
x *= env(int(SR * d), 0.05, 0.1)
save("heli", x, 0.62)

# ---------------------------------------------------------------- the laser
d = 0.9
f = np.linspace(220, 1750, int(SR * d))
x = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(int(SR * d), 0.02, 0.25)
x += 0.3 * np.sin(2 * np.pi * np.cumsum(f * 2.01) / SR) * env(int(SR * d), 0.02, 0.25)
save("lasergo", x, 0.7)

d = 0.7
x = (0.5 * saw(118, d) + 0.35 * saw(237, d) + 0.2 * lowpass(noise(d), 0.4)) \
        * env(int(SR * d), 0.01, 0.2)
save("laser", x, 0.6)

# ---------------------------------------------------------------- the world
d = 1.9
x = lowpass(noise(d), 0.1) * (0.3 + 0.7 * np.sin(np.pi * t(d) / d) ** 2)
x = sweep_lp(x, 0.02, 0.3) * env(int(SR * d), 0.3, 0.5)
save("tunnel", x, 0.6)

d = 0.75
x = (sine(330, d) + 0.8 * sine(440, d)) * env(int(SR * d), 0.06, 0.35)
save("start", x, 0.6)

d = 1.5
tr = 0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 7 * t(d)))
x = (0.6 * saw(110, d) + 0.5 * saw(164.8, d) + 0.3 * saw(55, d)) * tr \
        * env(int(SR * d), 0.15, 0.6)
save("bossgo", x, 0.8)

x = boom(1.0, 0.3, 0.03, 0.9)
x = np.concatenate([x, np.zeros(int(SR * 0.15))])
jingle = 0.7 * np.concatenate([np.zeros(int(SR * 0.4)),
        ding([523, 659, 784, 1046], 0.22, 0.06)])
x[:len(jingle)] += jingle[:len(x)]
save("bossdie", x, 1.0)

d = 1.7
seq = [(392, 0.4), (311, 0.4), (233, 0.9)]
parts = []
for f, dur in seq:
    parts.append((0.6 * sine(f, dur) + 0.4 * sine(f / 2, dur))
                 * env(int(SR * dur), 0.02, dur * 0.6))
x = np.concatenate(parts)
save("gameover", x, 0.75)

d = 0.05
x = lowpass(noise(d), 0.3) * env(int(SR * d), 0.001, 0.03)
save("click", x, 0.5)

d = 0.22
x = lowpass(noise(d), 0.2) * env(int(SR * d), 0.001, 0.16, 2) \
        + 0.5 * sine(182, d) * env(int(SR * d), 0.001, 0.18, 2)
save("crate", x, 0.7)

print("ALL HEAVY WAR SFX SYNTHESIZED ->", OUT)
