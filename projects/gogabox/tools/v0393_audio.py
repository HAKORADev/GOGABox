#!/usr/bin/env python3
# v0.3.9-3 - SQUARES audio (the dots-and-boxes graduate). The sq_* family:
# the pencil stroke, the box pop, the denied thud, the coin, the win/lose
# chimes - plus sq_theme, a seamless 72bpm "paper and ink" loop (soft
# kalimba plucks over a warm pad, a quiet paper shaker). Deterministic.
import os, wave
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(ROOT, "assets", "audio", "sfx")
MUS = os.path.join(ROOT, "assets", "audio", "music")
SR = 44100
rng = np.random.default_rng(393)

def env(n, a=0.004, r=0.08, shape=1.0):
    t = np.arange(n) / SR
    at = max(int(a * SR), 1)
    e = np.ones(n)
    e[:at] = np.linspace(0, 1, at)
    rel = np.exp(-np.maximum(t - a, 0) / max(r, 1e-3) * shape)
    return e * rel

def tone(f, dur, wave="sin", detune=0.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    ph = 2 * np.pi * (f + detune) * t
    if wave == "sin":
        return np.sin(ph)
    if wave == "tri":
        return 2 * np.abs(2 * ((f + detune) * t) % 1.0 - 1.0) - 1.0
    if wave == "saw":
        return 2 * ((f * t) % 1.0) - 1.0
    return np.sign(np.sin(ph)) * 0.7

def sweep(f0, f1, dur, wave="sin"):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = f0 + (f1 - f0) * (t / dur)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph)

def noise(dur):
    return rng.uniform(-1, 1, int(dur * SR))

def lowpass(x, alpha=0.2):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y

def bandpass(x, lo=400.0, hi=4000.0):
    a1 = 1.0 - np.exp(-2 * np.pi * lo / SR)
    a2 = 1.0 - np.exp(-2 * np.pi * hi / SR)
    lp = lowpass(x, a2)
    hp = x - lowpass(x, a1)
    return hp * 0.7 + lp * 0.0 + 0.0  # keep simple: hp of lowpassed mix
def shrink(x, dur):
    n = int(dur * SR)
    return x[:n] if len(x) >= n else np.pad(x, (0, n - len(x)))

def mix_at(buf, sig, at, gain=1.0):
    i = int(at * SR)
    j = min(len(buf), i + len(sig))
    if j > i:
        buf[i:j] += sig[:j - i] * gain

def write_wav(path, left, right=None, gain=0.9):
    if right is None:
        right = left
    peak = max(1e-9, np.max(np.abs(left)), np.max(np.abs(right)))
    k = gain / peak
    st = np.stack([left * k, right * k], axis=1)
    data = (st * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print("wav:", os.path.basename(path),
          "%.2fs" % (len(left) / SR))

# ------------------------------------------------------------------ SFX

def sq_line():
    """the pencil stroke: a short band-passed noise scratch with a tiny
    wooden tick at the head - dry, papery, satisfying."""
    dur = 0.16
    n = int(dur * SR)
    scratch = bandpass(noise(dur), 900, 5200) * env(n, 0.004, 0.05, 2.4)
    tick = tone(1900, 0.03, "tri") * env(int(0.03 * SR), 0.001, 0.012, 3.0)
    body = scratch * 0.85
    mix_at(body, tick, 0.0, 0.5)
    return body

def sq_box():
    """the box pop: two warm notes a fifth apart, a soft marimba hit -
    the claim is a little reward every single time."""
    d1 = tone(523.25, 0.22, "sin") * env(int(0.22 * SR), 0.003, 0.10, 2.2)
    d2 = tone(784.0, 0.30, "sin") * env(int(0.30 * SR), 0.003, 0.16, 2.0)
    body = d1 * 0.8
    mix_at(body, d2, 0.055, 0.75)
    mix_at(body, tone(261.6, 0.12, "tri") * env(int(0.12 * SR), 0.002,
            0.05, 2.5), 0.0, 0.30)
    return body

def sq_denied():
    """the denied thud: a dull low knock - the edge is already drawn."""
    dur = 0.14
    th = sweep(240, 130, dur) * env(int(dur * SR), 0.002, 0.05, 2.8)
    body = th * 0.9
    mix_at(body, lowpass(noise(dur), 0.12) * env(int(dur * SR), 0.001,
            0.03, 3.0), 0.0, 0.25)
    return body

def sq_coin():
    """the coin: the bright house arpeggio (the GOGACoin voice)."""
    body = np.zeros(int(0.5 * SR))
    for i, f in enumerate([1318.5, 1568.0, 2093.0]):
        seg = tone(f, 0.20, "tri") * env(int(0.20 * SR), 0.002, 0.10, 2.2)
        mix_at(body, seg, i * 0.055, 0.62 - i * 0.08)
    return body

def sq_win():
    """the round win: a warm rising figure with a sparkling tail."""
    body = np.zeros(int(1.1 * SR))
    for i, f in enumerate([392.0, 493.9, 587.3, 784.0]):
        seg = tone(f, 0.34, "sin") * env(int(0.34 * SR), 0.004, 0.20, 1.8)
        mix_at(body, seg, i * 0.09, 0.6)
        seg2 = tone(f * 2, 0.20, "tri") * env(int(0.20 * SR), 0.002,
                0.10, 2.4)
        mix_at(body, seg2, i * 0.09 + 0.01, 0.16)
    return body

def sq_lose():
    """the round loss: the soft descending minor sigh - never harsh."""
    body = np.zeros(int(1.0 * SR))
    for i, f in enumerate([493.9, 415.3, 349.2]):
        seg = tone(f, 0.30, "sin") * env(int(0.30 * SR), 0.005, 0.18, 1.9)
        mix_at(body, seg, i * 0.11, 0.55)
    return body

# ---------------------------------------------------------------- MUSIC
# sq_theme - "paper and ink": 72bpm, D dorian, kalimba-ish plucks over a
# warm pad and a quiet paper shaker. 8 bars, seamless loop.

BPM = 72.0
BEAT = 60.0 / BPM
BARS = 8
LEN = BARS * 4 * BEAT

D3, F3, G3, A3, C4, D4, E4, F4, G4, A4, C5, D5 = \
        146.83, 174.61, 196.0, 220.0, 261.63, 293.66, 329.63, 349.23, \
        392.0, 440.0, 523.25, 587.33

MELODY = [
    # (beat, dur_beats, note, gain)
    (0.0, 1.0, D4, .50), (1.0, .5, F4, .40), (1.5, .5, G4, .40),
    (2.0, 1.5, A4, .48), (3.5, .5, G4, .34),
    (4.0, 1.0, F4, .44), (5.0, .5, E4, .36), (5.5, .5, D4, .36),
    (6.0, 2.0, C4, .42),
    (8.0, 1.0, A3, .40), (9.0, .5, C4, .36), (9.5, .5, D4, .40),
    (10.0, 1.5, F4, .46), (11.5, .5, E4, .34),
    (12.0, 1.0, D4, .46), (13.0, .5, F4, .38), (13.5, .5, G4, .38),
    (14.0, 2.0, A4, .44),
    (16.0, .5, D4, .38), (16.5, .5, E4, .34), (17.0, 1.0, F4, .44),
    (18.0, 1.0, A4, .46), (19.0, .5, G4, .36), (19.5, .5, F4, .34),
    (20.0, 1.5, E4, .42), (21.5, .5, D4, .34),
    (22.0, 2.0, C4, .40),
    (24.0, 1.0, F4, .44), (25.0, .5, G4, .38), (25.5, .5, A4, .42),
    (26.0, 1.5, C5, .48), (27.5, .5, A4, .36),
    (28.0, 1.0, G4, .44), (29.0, .5, F4, .38), (29.5, .5, E4, .34),
    (30.0, 2.0, D4, .46),
]

BASS = [
    (0.0, D3), (4.0, D3), (8.0, F3), (12.0, G3),
    (16.0, D3), (20.0, C4 / 2), (24.0, F3), (28.0, G3),
]

def pluck(f, dur, gain):
    n = int(dur * SR)
    body = (np.sin(2 * np.pi * f * np.arange(n) / SR)
            + 0.35 * np.sin(2 * np.pi * f * 2.01 * np.arange(n) / SR)
            + 0.18 * np.sin(2 * np.pi * f * 3.0 * np.arange(n) / SR))
    return body * env(n, 0.003, dur * 0.45, 2.2) * gain

def sq_theme():
    L = np.zeros(int(LEN * SR) + SR)
    R = np.zeros(int(LEN * SR) + SR)
    # the warm pad: slow saw fifths, heavy lowpass, wide
    for (beat, f) in [(0.0, D3), (8.0, F3), (16.0, D3), (24.0, G3)]:
        n = int(8 * BEAT * SR)
        pad = lowpass(2 * ((f * np.arange(n) / SR) % 1.0) - 1.0, 0.045)
        pad += lowpass(2 * ((f * 1.5 * np.arange(n) / SR) % 1.0) - 1.0,
                       0.04)
        pe = np.ones(n)
        at = int(1.2 * SR)
        pe[:at] = np.linspace(0, 1, at)
        pe[-at:] = np.linspace(1, 0, at)
        pad = pad * pe * 0.055
        mix_at(L, pad, beat * BEAT, 1.0)
        mix_at(R, pad, beat * BEAT, 0.92)
    # the bass heartbeat
    for (beat, f) in BASS:
        for k in range(4):
            n = int(0.9 * BEAT * SR)
            b = lowpass(np.sin(2 * np.pi * f * np.arange(n) / SR), 0.09)
            b *= env(n, 0.006, 0.28, 2.0)
            mix_at(L, b, (beat + k) * BEAT, 0.30)
            mix_at(R, b, (beat + k) * BEAT, 0.30)
    # the kalimba melody (slightly wide)
    for (beat, dur, f, g) in MELODY:
        p = pluck(f, min(dur * BEAT + 0.4, 1.6), g)
        mix_at(L, p, beat * BEAT, 0.95)
        mix_at(R, p, beat * BEAT + 0.012, 0.80)
    # the paper shaker: quiet band-passed ticks on the off-beats
    for i in range(int(LEN / (BEAT / 2.0))):
        at = i * (BEAT / 2.0) + BEAT / 2.0
        if at >= LEN - 0.05:
            break
        n = int(0.045 * SR)
        sh = bandpass(noise(0.045), 3200, 8200) \
                * env(n, 0.001, 0.018, 3.0)
        g = 0.085 if i % 2 == 0 else 0.055
        mix_at(L, sh, at, g)
        mix_at(R, sh, at + 0.004, g * 1.15)
    # trim to the exact loop length (the loop region law: the whole file)
    n = int(LEN * SR)
    return L[:n], R[:n]

def main():
    os.makedirs(SFX, exist_ok=True)
    os.makedirs(MUS, exist_ok=True)
    write_wav(os.path.join(SFX, "sq_line.wav"), sq_line())
    write_wav(os.path.join(SFX, "sq_box.wav"), sq_box())
    write_wav(os.path.join(SFX, "sq_denied.wav"), sq_denied())
    write_wav(os.path.join(SFX, "sq_coin.wav"), sq_coin())
    write_wav(os.path.join(SFX, "sq_win.wav"), sq_win())
    write_wav(os.path.join(SFX, "sq_lose.wav"), sq_lose())
    L, R = sq_theme()
    write_wav(os.path.join(MUS, "sq_theme.wav"), L, R, gain=0.82)

if __name__ == "__main__":
    main()
