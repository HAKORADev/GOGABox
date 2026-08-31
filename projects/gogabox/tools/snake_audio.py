#!/usr/bin/env python3
"""snake_audio.py — v0.1.8 THE SNAKE MAKEOVER audio, synthesized in-house.

Generates (deterministic, re-runnable):
  assets/audio/music/snake_theme.wav  - warm minimal lo-fi loop (seamless)
  assets/audio/sfx/snake_eat.wav      - juicy pop (runtime pitch ramp = dopamine)
  assets/audio/sfx/snake_die.wav      - soft descending "aww", not harsh
  assets/audio/sfx/snake_start.wav    - two soft rising blips (tap-to-start)

House rules honored: 22050 Hz mono 16-bit WAV, numpy+wave only, no sources
to vendor. Run from anywhere:
  python3 tools/snake_audio.py
"""
import os
import wave

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "audio")
SR = 22050


def _write_wav(rel, samples):
    p = os.path.join(OUT, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    data = (np.clip(samples, -1.0, 1.0) * 32767).astype(np.int16)
    with wave.open(p, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print("wrote", os.path.relpath(p, ROOT))


def _note(freq, dur, vol=1.0, harmonics=((1, 1.0),), attack=0.01, decay=None):
    """An enveloped tone. decay = exp rate (1/s); None -> sustain then release."""
    n = int(SR * dur)
    t = np.linspace(0, dur, n, False)
    sig = np.zeros(n)
    for mult, amp in harmonics:
        sig += amp * np.sin(2 * np.pi * freq * mult * t)
    env = np.minimum(1.0, t / max(attack, 1e-4))
    if decay:
        env *= np.exp(-decay * t)
    else:
        rel = np.minimum(1.0, (dur - t) / 0.08)
        env *= rel
    return sig * env * vol


# ----------------------------------------------------------------- theme

# Cozy I-vi-IV-V with 7ths. Frequencies rounded to whole loop-cycles so the
# waveform itself is phase-continuous across the seam (loop = 9.6 s).
LOOP = 9.6
CYC = SR * LOOP  # samples; freq resolution = SR/LOOP

CHORDS = [
    # (name, [C4 E4 G4 B4]-style voices in Hz, bass Hz)
    ("Cmaj7", [261.63, 329.63, 392.00, 493.88], 130.81),
    ("Am7", [220.00, 261.63, 329.63, 392.00], 110.00),
    ("Fmaj7", [174.61, 220.00, 261.63, 329.63], 87.31),
    ("G7", [196.00, 246.94, 293.66, 349.23], 98.00),
]
PENT = [523.25, 587.33, 659.26, 783.99, 880.00]  # C5 D5 E5 G5 A5


def _lock(f):
    """Snap a frequency to an integer number of cycles per loop -> seamless."""
    k = max(1, round(f * LOOP))
    return k / LOOP


def _pad(freq, dur, vol):
    """Warm pad voice: 0.45s swell in, hold, 0.5s settle OUT before the
    chord boundary. Every boundary (the loop seam included) sounds
    identical: a soft re-swelling of the next chord. Frequencies are
    cycle-locked to the loop, so the waveform is phase-continuous too."""
    n = int(SR * dur)
    t = np.linspace(0, dur, n, False)
    env = np.minimum(1.0, t / 0.45) * np.minimum(1.0, (dur - t) / 0.5)
    sig = (np.sin(2 * np.pi * freq * t)
           + 0.35 * np.sin(2 * np.pi * freq * 2 * t)
           + 0.12 * np.sin(2 * np.pi * freq * 3 * t))
    return sig * env * vol


def theme():
    chord_dur = LOOP / len(CHORDS)
    buf = np.zeros(int(SR * LOOP))
    for i, chord in enumerate(CHORDS):
        start = int(SR * i * chord_dur)
        n = int(SR * chord_dur)
        seg = np.zeros(n)
        for f in chord[1]:
            seg += _pad(_lock(f), chord_dur, 0.115)
        seg += _pad(_lock(chord[2]), chord_dur, 0.10)          # bass root
        seg += _pad(_lock(chord[2] * 2), chord_dur, 0.05)      # bass octave
        # two soft bass plucks per chord (t=0.05 and the middle)
        for bt in (0.05, chord_dur / 2 + 0.05):
            pl = _note(_lock(chord[2] * 2), 0.55, 0.16,
                       harmonics=((1, 1.0), (2, 0.25)), attack=0.006, decay=5.0)
            s = start + int(SR * bt)
            buf[s:s + pl.size] += pl[:max(0, buf.size - s)][:pl.size]
        buf[start:start + n] += seg

    # Sparse pluck melody on the pentatonic, deterministic, ends well before
    # the seam so nothing rings across the loop point.
    rng = np.random.RandomState(7)
    deg = 2
    for k in range(7):
        bar = 0.55 + 1.28 * k + float(rng.uniform(0.0, 0.5))
        if bar > LOOP - 0.9:
            break
        deg = int(np.clip(deg + rng.choice([-2, -1, 1, 1, 2]), 0, len(PENT) - 1))
        f = _lock(PENT[deg])
        start = int(SR * bar)
        seg = _note(f, 0.85, 0.16,
                    harmonics=((1, 1.0), (2, 0.28), (3, 0.10)), attack=0.004,
                    decay=3.2)
        end = min(start + seg.size, buf.size)
        buf[start:end] += seg[:end - start]

    buf = buf / max(1e-9, np.max(np.abs(buf))) * 0.72
    _write_wav(os.path.join("music", "snake_theme.wav"), buf)


# ------------------------------------------------------------------- sfx

def eat():
    dur = 0.16
    n = int(SR * dur)
    t = np.linspace(0, dur, n, False)
    f = 480 + (900 - 480) * np.minimum(1.0, t / 0.07)
    ph = 2 * np.pi * np.cumsum(f) / SR
    sig = np.sin(ph) * np.exp(-16 * t) * 0.62
    sig += 0.30 * np.sin(2 * ph) * np.exp(-20 * t)
    sig += 0.22 * np.sin(2 * np.pi * 150 * t) * np.exp(-30 * t)  # sub thump
    _write_wav(os.path.join("sfx", "snake_eat.wav"), sig)


def die():
    dur = 0.5
    n = int(SR * dur)
    t = np.linspace(0, dur, n, False)
    f = 320 * np.exp(-t * 3.4) + 55
    ph = 2 * np.pi * np.cumsum(f) / SR
    sig = (np.sin(ph) + 0.3 * np.sin(2 * ph) + 0.14 * np.sin(3 * ph))
    sig *= np.exp(-5.5 * t) * 0.55
    puff = np.random.RandomState(3).uniform(-1, 1, n) * np.exp(-40 * t) * 0.20
    _write_wav(os.path.join("sfx", "snake_die.wav"), sig + puff)


def start():
    a = _note(659.26, 0.16, 0.5, harmonics=((1, 1.0), (2, 0.2)), attack=0.004,
              decay=9.0)
    b = _note(880.00, 0.30, 0.5, harmonics=((1, 1.0), (2, 0.2)), attack=0.004,
              decay=6.0)
    gap = np.zeros(int(SR * 0.055))
    _write_wav(os.path.join("sfx", "snake_start.wav"),
               np.concatenate([a, gap, b]))


if __name__ == "__main__":
    theme()
    eat()
    die()
    start()
