#!/usr/bin/env python3
"""v0.3.3 PATCH 2 - MATCHER SFX VIBE REDO (the owner: "the game SFXs are not
matching the game vibes somehow, also the combo SFXs are the most weirdest
ones" + "the peace mode music is good but painful, there is sound that is
somehow heavy in uncomfy way").

WHAT CHANGES
  - the pop family (pop_1..4): softer candy pops - rounder body, less click,
    shorter tails, warmer low end. Same filenames (the code keeps working).
  - NEW combo ladder m_combo_2..7: a warm pentatonic marimba rise - one note
    per cascade step, musical instead of the old pitched-sample weirdness.
  - m_special: a gentle two-note glass chime (birth of flame/star/hyper).
  - m_land: the coin's soft landing thump (the coin now drops like a gem).
  - matcher_peace.wav v2: the heavy low pad is gone (the "heavy in uncomfy
    way" was the 0.5x sub-octave layer + the deep sine at 87Hz territory);
    the theme now floats on soft mids, attacks even slower, level a touch
    lower.
"""
import numpy as np
import wave
import os

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(ROOT, "projects/gogabox/assets/audio/sfx")
MUS = os.path.join(ROOT, "projects/gogabox/assets/audio/music")


def env(n, a=0.005, r=0.12, shape=1.0):
    t = np.linspace(0, 1, n)
    at = max(1, int(a * SR))
    e = np.ones(n)
    e[:at] = np.linspace(0, 1, at)
    rel = max(1, int(r * SR))
    e[-rel:] = np.linspace(1, 0, rel) ** shape
    return e


def sine(f, dur, vol=0.5, slide=0.0):
    n = int(dur * SR)
    t = np.linspace(0, dur, n, endpoint=False)
    f_t = f + slide * t / dur
    ph = 2 * np.pi * np.cumsum(f_t) / SR
    return np.sin(ph) * vol * env(n, r=dur * 0.7)


def pluck(f, dur, vol=0.5, bright=1.0):
    n = int(dur * SR)
    t = np.linspace(0, dur, n, endpoint=False)
    s = np.sin(2 * np.pi * f * t)
    s += 0.42 * bright * np.sin(2 * np.pi * f * 2 * t)
    s += 0.18 * bright * np.sin(2 * np.pi * f * 3 * t)
    s += 0.08 * bright * np.sin(2 * np.pi * f * 4.2 * t)
    e = np.exp(-t * (6.5 / max(0.05, dur * 0.35)))
    return s * e * vol


def marimba(f, dur, vol=0.5):
    """warm wooden bar: fundamental + 4th, soft mallet noise tick"""
    n = int(dur * SR)
    t = np.linspace(0, dur, n, endpoint=False)
    s = np.sin(2 * np.pi * f * t)
    s += 0.34 * np.sin(2 * np.pi * f * 3.94 * t)
    s += 0.10 * np.sin(2 * np.pi * f * 9.2 * t)
    e = np.exp(-t * (7.5 / max(0.05, dur * 0.4)))
    rng = np.random.default_rng(int(f))
    tick = rng.standard_normal(int(0.008 * SR)) * 0.35
    s[:len(tick)] += tick * np.linspace(1, 0, len(tick))
    return s * e * vol


def noise(dur, vol=0.3, seed=3):
    rng = np.random.default_rng(seed)
    return rng.standard_normal(int(dur * SR)) * vol


def bp(x, lo, hi):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    m = ((f >= lo) & (f <= hi)).astype(float)
    m = np.convolve(m, np.ones(9) / 9, mode="same")
    return np.fft.irfft(X * m, len(x))


def save(name, L, R=None, peak=0.8, out=SFX):
    if R is None:
        R = L
    st = np.stack([L, R], axis=1)
    m = np.max(np.abs(st)) / peak
    if m > 0:
        st = st / m
    data = (st * 32767).astype(np.int16)
    with wave.open(os.path.join(out, name), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print("sfx", name, round(len(L) / SR, 2), "s")


def add_at(buf, seg, a0):
    take = min(len(seg), max(0, len(buf) - a0))
    if take > 0:
        buf[a0:a0 + take] += seg[:take]


def wet(x, room=0.22, damp=0.35):
    d1 = int(0.031 * SR)
    d2 = int(0.057 * SR)
    y = np.zeros(len(x) + d2 + 64)
    y[:len(x)] += x * (1 - room)
    y[d1:d1 + len(x)] += bp(x, 300, 8000) * room * 0.55
    y[d2:d2 + len(x)] += bp(x, 200, 5200) * room * 0.35
    return y


# ---------------------------------------------------------------- pops v2
def candy_pop(seed, f0, dur=0.16):
    """the soft candy pop: a rounded sine blip with a tiny bubble rise,
    almost no click, a warm little tail"""
    rng = np.random.default_rng(seed)
    n = int(dur * SR)
    t = np.linspace(0, dur, n, endpoint=False)
    f = f0 * (1.0 + 0.06 * t / dur)          # gentle bubble rise
    ph = 2 * np.pi * np.cumsum(f) / SR
    s = np.sin(ph)
    s += 0.22 * np.sin(2 * ph)               # a whisper of 2nd harmonic
    e = np.exp(-t * (17.0 - 4.0)) * env(n, a=0.004, r=dur * 0.5, shape=1.4)
    body = s * e
    # the faintest gel tap
    tap = bp(rng.standard_normal(int(0.012 * SR)), 700, 3200) * 0.22
    body[:len(tap)] += tap * np.linspace(1, 0, len(tap))
    return body * 0.8


def do_pops():
    save("pop_1.wav", wet(candy_pop(11, 660.0)))
    save("pop_2.wav", wet(candy_pop(23, 740.0)))
    save("pop_3.wav", wet(candy_pop(37, 830.0)))
    save("pop_4.wav", wet(candy_pop(51, 930.0)))


# ---------------------------------------------------------------- combos
def do_combos():
    # F-major pentatonic climb: F G A C D - one warm marimba per cascade step
    notes = {2: 698.46, 3: 783.99, 4: 880.0, 5: 1046.5, 6: 1174.7, 7: 1396.9}
    for step, f in notes.items():
        seg = marimba(f, 0.5, 0.72)
        sparkle = pluck(f * 2, 0.34, 0.14, bright=0.4)
        a0 = int(0.05 * SR)
        add_at(seg, sparkle, a0)
        save("m_combo_%d.wav" % step, wet(seg, room=0.26))


def do_special():
    # the gentle glass chime: two soft notes a third apart
    a = pluck(880.0, 0.5, 0.5, bright=0.55)
    b = pluck(1108.7, 0.6, 0.42, bright=0.5)
    n = int(0.75 * SR)
    x = np.zeros(n)
    add_at(x, a, 0)
    add_at(x, b, int(0.09 * SR))
    save("m_special.wav", wet(x, room=0.3))


def do_land():
    # the coin's landing: soft warm thump + tiny coin shimmer
    th = sine(150.0, 0.14, 0.5, slide=-60.0)
    sh = bp(noise(0.1, 0.5, 9), 4000, 9000) * 0.3 * env(int(0.1 * SR), r=0.08)
    x = np.zeros(int(0.2 * SR))
    x[:len(th)] += th
    add_at(x, sh, int(0.012 * SR))
    save("m_land.wav", wet(x))


# ------------------------------------------------------------- peace v2
def theme_peace():
    bpm = 66
    beat = 60 / bpm
    bars = 8
    n = int(bars * 4 * beat * SR)
    t = np.linspace(0, bars * 4 * beat, n, endpoint=False)
    x = np.zeros(n)

    def pad(freq, t0, dur, vol=0.16):
        a = int(t0 * SR)
        seg_n = int(dur * SR)
        seg_t = np.linspace(0, dur, seg_n, endpoint=False)
        # v2: NO sub-octave layer (the heavy "uncomfy" body), the octave
        # whisper softened - the pad floats on the fundamental + air
        s = (np.sin(2 * np.pi * freq * seg_t)
             + 0.30 * np.sin(2 * np.pi * freq * 2 * seg_t + 0.7))
        vib = 1 + 0.003 * np.sin(2 * np.pi * 0.9 * seg_t)
        s *= vib
        # v2: even slower attack, no sudden pad entrances
        e = env(seg_n, a=1.1, r=1.9, shape=0.6)
        add_at(x, s * e * vol, a)

    def bell(freq, t0, vol=0.22):
        a = int(t0 * SR)
        seg = marimba(freq, 1.5, vol * 0.85)
        add_at(x, seg, a)

    F, A, C = 349.23, 440.0, 523.25
    prog = [
        [F, A, C], [293.66, 349.23, 440.0],
        [261.63, 329.63, 392.0], [F, A, C],
    ]
    for bar in range(bars):
        ch = prog[bar % 4]
        t0 = bar * 4 * beat
        for i, f0 in enumerate(ch):
            pad(f0, t0 + i * 0.05, 4 * beat * 0.98, 0.085)
    rng = np.random.default_rng(2026)
    for k in range(12):
        t0 = rng.uniform(0.8, bars * 4 * beat - 2.2)
        f0 = rng.choice([523.25, 587.33, 698.46, 783.99, 880.0])
        bell(f0, t0, 0.11)
    # v2: the air layer higher + quieter (the old 300-900Hz band read heavy)
    x += 0.012 * np.sin(2 * np.pi * 0.25 * t) * bp(noise(n / SR, 1.0, 77), 700, 1600)
    L = wet(x, room=0.3)
    R = wet(np.roll(x, 220), room=0.3)
    save("matcher_peace.wav", L, R, peak=0.62, out=MUS)


if __name__ == "__main__":
    do_pops()
    do_combos()
    do_special()
    do_land()
    theme_peace()
    print("v0.3.3-p2 matcher sfx done")
