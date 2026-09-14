#!/usr/bin/env python3
"""v03910_audio.py - CONQUER DICE v0.3.9-10: the in/out voices re-crafted
to the owner's own onomatopoeia (the v0.3.9-9 set existed but the game
played the wrong names - cd_in / cd_out - so every theme's in/out was
100% SILENT; the fix rides in jumpcube.gd, the craft rides here).

THE OWNER'S VOICES (verbatim):
  wood  (default) "blob, bloop!" - water drops on a BOARD, not water on
        water: crisp droplet impacts on wood, close and dry, no underwater
        muffle. in = the blob (a drop lands), out = the bloop (the gulp).
  mono  "wheeph, whooph" - airy cloth whooshes: in sweeps up, out sweeps
        down and lands soft.
  pixel "dot, doot" - square 8-bit blips: in is one dot, out is two notes.
  neon  "like pixelated but with that echo and guitar like" - plucked
        string notes (karplus-strong) wearing the same dot/doot melody,
        delayed echoes trailing behind.
  candy "edible" - the mouth voice: in is a juicy pop, out is a squishy
        gulp with a happy little wobble.

The shared voices (cd_press / cd_denied / cd_coin / cd_win / cd_lose) and
the music stay from v0.3.9-9 - the owner hears them fine ("music and
illegal dice and win/lose SFXs are hearable").

The cascade law of the feel still holds: the OUT fires once, 2-4 INs
answer it, the game raises the PITCH as the chain grows - these files are
the base pitches.

Re-derive: python3 projects/gogabox/tools/v03910_audio.py
"""
import numpy as np
import os
import wave

SR = 44100
SFX_DIR = "projects/gogabox/assets/audio/sfx"


def write_wav(path, data, sr=SR):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = np.asarray(data)
    if data.ndim == 1:
        data = np.stack([data, data], axis=1)
    pcm = (np.clip(data, -1, 1) * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())
    print(f"  {os.path.basename(path):22s} {len(data)/sr:.2f}s")


def t_axis(dur):
    return np.linspace(0, dur, int(SR * dur), endpoint=False)


def env(n, a, r, hold=1.0):
    x = np.ones(n)
    na, nr = max(1, int(a * SR)), max(1, int(r * SR))
    na, nr = min(na, n), min(nr, n)
    x[:na] = np.linspace(0, hold, na)
    x[-nr:] *= np.linspace(1, 0, nr)
    return x


def sine(f, dur, ph=0.0):
    return np.sin(2 * np.pi * f * t_axis(dur) + ph)


def sweep(f0, f1, dur):
    t = t_axis(dur)
    f = np.linspace(f0, f1, t.size)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph)


def noise(dur, seed=39):
    return np.random.RandomState(seed).uniform(-1, 1, int(SR * dur))


def bandpass(x, lo, hi, passes=2):
    """crude band-pass: high-pass(lo) then low-pass(hi), one-pole chains"""
    # high-pass
    hp = x.copy()
    acc = 0.0
    a = float(np.exp(-2 * np.pi * lo / SR))
    for i, v in enumerate(x):
        acc = a * acc + (1 - a) * v
        hp[i] = v - acc
    # low-pass
    lp = hp.copy()
    acc = 0.0
    b = float(np.exp(-2 * np.pi * hi / SR))
    for _ in range(passes):
        for i, v in enumerate(hp):
            acc += (1 - b) * (v - acc)
            lp[i] = acc
        hp2 = lp
        lp = hp2
    return lp


def lowpass(x, alpha):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def square(f, dur, duty=0.5):
    t = t_axis(dur)
    return np.where((t * f) % 1.0 < duty, 1.0, -1.0)


def pluck(f, dur, damp=0.996):
    """karplus-strong: the guitar string (noise burst into a delay line)"""
    n = int(SR * dur)
    period = max(2, int(SR / f))
    buf = np.random.RandomState(int(f) % 9973).uniform(-1, 1, period)
    out = np.empty(n)
    idx = 0
    prev = 0.0
    for i in range(n):
        cur = buf[idx]
        nxt = damp * 0.5 * (cur + prev)
        out[i] = cur
        buf[idx] = nxt
        prev = cur
        idx = (idx + 1) % period
    return out


def echo(x, delay=0.11, gains=(0.42, 0.26, 0.15), tail=0.55):
    """the NEON echo: the note repeats, quieter, into the dark"""
    d = int(SR * delay)
    n = x.size + d * len(gains) + int(SR * tail)
    y = np.zeros(n)
    y[:x.size] += x
    for g in gains:
        y[d:d + x.size] += g * x
        d += d
    return y[:n] * env(n, 0.002, min(0.5, tail))


# --------------------------------------------------------------- WOOD
# "blob, bloop!" - water dots on a board

def in_wood():
    """the BLOB: a droplet lands on wood - a quick down-blip with a
    tiny wet tick at the head, dry and close"""
    d = 0.13
    body = sweep(920, 300, d) * env(int(SR * d), 0.001, 0.10)
    tick = bandpass(noise(0.018, 41), 1800, 6500) \
        * env(int(SR * 0.018), 0.0005, 0.014) * 0.5
    x = body * 0.72
    x[:tick.size] += tick
    # the board answers: a soft wooden knock under the drop
    knock = sine(240, 0.07) * env(int(SR * 0.07), 0.001, 0.055)
    x[:knock.size] += 0.30 * knock
    return x * 0.66


def out_wood():
    """the BLOOP: the gulp - a drop rises and pops up, the little
    upward water blub (two quick rises, the board drinks)"""
    d = 0.22
    t = t_axis(d)
    f = np.linspace(240, 620, t.size)
    f += 90 * np.sin(2 * np.pi * 26 * t)      # the water wobble
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) * env(int(SR * d), 0.002, 0.13)
    # a second smaller bloop answers (the dots that flew out)
    d2 = 0.12
    x2 = sweep(500, 900, d2) * env(int(SR * d2), 0.002, 0.08) * 0.45
    i0 = int(SR * 0.09)
    x[i0:i0 + x2.size] += x2
    return x * 0.68


# --------------------------------------------------------------- MONO
# "wheeph, whooph"

def in_mono():
    """the WHEEPH: airy cloth sweeping UP, soft, gray"""
    d = 0.16
    n = noise(d, 43)
    body = bandpass(n, 500, 2600)
    t = t_axis(d)
    shape = np.linspace(0.25, 1.0, t.size) ** 1.5
    x = body * shape * env(int(SR * d), 0.012, 0.07)
    # the faint chalk tail
    x += 0.18 * sine(1150, d) * env(int(SR * d), 0.01, 0.12) * shape
    return x * 0.78


def out_mono():
    """the WHOOPH: airy cloth sweeping DOWN, deeper, landing soft"""
    d = 0.26
    n = noise(d, 47)
    body = bandpass(n, 220, 1700)
    t = t_axis(d)
    shape = np.linspace(1.0, 0.2, t.size) ** 1.2
    x = body * shape * env(int(SR * d), 0.008, 0.16)
    # the low landing breath
    x += 0.35 * sweep(180, 90, d) * env(int(SR * d), 0.01, 0.18)
    return x * 0.8


# --------------------------------------------------------------- PIXEL
# "dot, doot"

def in_chip():
    """the DOT: one square blip, short and certain"""
    d = 0.07
    x = square(740, d, 0.5)
    x *= env(int(SR * d), 0.001, 0.05)
    return x * 0.30


def out_chip():
    """the DOOT: two square notes stepping UP, the 8-bit answer"""
    n1 = square(620, 0.09, 0.5) * env(int(SR * 0.09), 0.001, 0.06)
    n2 = square(930, 0.14, 0.5) * env(int(SR * 0.14), 0.001, 0.10)
    d = 0.26
    x = np.zeros(int(SR * d))
    x[:n1.size] += n1 * 0.5
    i0 = int(SR * 0.085)
    x[i0:i0 + n2.size] += n2 * 0.42
    return x * 0.72


# --------------------------------------------------------------- NEON
# "like pixelated but with that echo and guitar like"

def in_neon():
    """the dot played on a PLUCKED STRING, wearing its echo"""
    x = pluck(740, 0.30, 0.9965) * env(int(SR * 0.30), 0.001, 0.24)
    x = np.tanh(x * 2.2) * 0.5                 # the electric bite
    return echo(x, 0.105, (0.40, 0.24, 0.13)) * 0.85


def out_neon():
    """the doot as a two-note POWER FIFTH pluck, longer echoes"""
    a = pluck(620, 0.22, 0.996) * env(int(SR * 0.22), 0.001, 0.18)
    b = pluck(930, 0.34, 0.9965) * env(int(SR * 0.34), 0.001, 0.28)
    d = 0.62
    x = np.zeros(int(SR * d))
    x[:a.size] += a * 0.5
    i0 = int(SR * 0.085)
    x[i0:i0 + b.size] += b * 0.46
    x = np.tanh(x * 2.4) * 0.5
    return echo(x, 0.115, (0.42, 0.27, 0.16, 0.09)) * 0.85


# --------------------------------------------------------------- CANDY
# "edible"

def in_pop():
    """the juicy POP: a candy dot bursts - wet click, sweet drop"""
    d = 0.12
    body = sweep(880, 340, d) * env(int(SR * d), 0.001, 0.08)
    click = bandpass(noise(0.014, 53), 2500, 8000) \
        * env(int(SR * 0.014), 0.0005, 0.011) * 0.7
    x = body * 0.68
    x[:click.size] += click
    # the sugar shimmer on top
    x += 0.16 * sine(1760, d) * env(int(SR * d), 0.001, 0.09)
    return x * 0.64


def out_pop():
    """the GULP: a squishy edible swallow - two soft pops down and a
    happy little wobble, like biting a gummy"""
    d = 0.28
    t = t_axis(d)
    f = np.linspace(520, 180, t.size)
    f += 70 * np.sin(2 * np.pi * 18 * t)       # the jelly wobble
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) * env(int(SR * d), 0.002, 0.16)
    # the second bite
    d2 = 0.10
    x2 = sweep(700, 320, d2) * env(int(SR * d2), 0.001, 0.07) * 0.5
    i0 = int(SR * 0.11)
    x[i0:i0 + x2.size] += x2
    # the "mmm" - a warm low hum
    x += 0.18 * sine(150, d) * env(int(SR * d), 0.03, 0.18)
    return x * 0.66


def main():
    print("conquer dice v0.3.9-10 voices (the owner's onomatopoeia):")
    for theme, fn in [("wood", in_wood), ("mono", in_mono),
                      ("chip", in_chip), ("neon", in_neon),
                      ("pop", in_pop)]:
        write_wav(f"{SFX_DIR}/cd_in_{theme}.wav", fn())
    for theme, fn in [("wood", out_wood), ("mono", out_mono),
                      ("chip", out_chip), ("neon", out_neon),
                      ("pop", out_pop)]:
        write_wav(f"{SFX_DIR}/cd_out_{theme}.wav", fn())


if __name__ == "__main__":
    main()
