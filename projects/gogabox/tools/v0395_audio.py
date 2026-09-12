#!/usr/bin/env python3
"""v0395_audio.py - DOT EATER (v0.3.9-5) audio.
100% synthesized - the house way (nothing sampled, nothing scraped).

DOT EATER (assets/audio/sfx/de_*.wav):
  waka_a   THE CHOMP, open mouth (the golden-dot bite, up variant)
  waka_b   THE CHOMP, closed mouth (the alternating half - the original's
           waka-waka is TWO sounds, so is ours)
  power    the blue magical dot - the rush zap (a rising blue sting)
  eat      a ball-eater swallowed mid-rush (gulp down, pop up)
  eyes     the eaten ball-eater's eyes running home (soft sad blink)
  hurt     losing a life - the descending wah-wah sweep
  life     the 500th dot - an extra life rises (bright run)
  coin     the GOGACoin ding (the house coin family, warm pair)
  clear    the maze wipe - every dot eaten, the run climbs (fast rise)
  start    the READY sting (the mouth opens, the hunt begins)

THEME (assets/audio/music/):
  de_theme.wav  the maze-chomp loop - bouncy 118 bpm chiptune-ish lead
                over a round bass, 8 bars, seamless (ends where it starts)

Re-derive: python3 tools/v0395_audio.py
"""
import numpy as np
import os
import wave

SR = 44100
SFX_DIR = "projects/gogabox/assets/audio/sfx"
MUS_DIR = "projects/gogabox/assets/audio/music"


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


def sine(f, dur):
    return np.sin(2 * np.pi * f * t_axis(dur))


def square(f, dur, duty=0.5):
    t = t_axis(dur)
    return np.where((t * f) % 1.0 < duty, 1.0, -1.0)


def tri(f, dur):
    t = t_axis(dur)
    return 2.0 * np.abs(2.0 * ((t * f) % 1.0) - 1.0) - 1.0


def sweep(f0, f1, dur, shape="sine"):
    t = t_axis(dur)
    f = f0 * (f1 / f0) ** (t / max(1e-6, dur))
    ph = 2 * np.pi * np.cumsum(f) / SR
    if shape == "square":
        return np.sign(np.sin(ph))
    if shape == "tri":
        return 2.0 / np.pi * np.arcsin(np.sin(ph))
    return np.sin(ph)


def noise(dur):
    return np.random.uniform(-1, 1, int(SR * dur))


def lowpass(x, alpha):
    out = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        out[i] = acc
    return out


def place(buf, at, sig, gain=1.0):
    i = int(at * SR)
    j = min(len(buf), i + len(sig))
    if i < len(buf):
        buf[i:j] += sig[: j - i] * gain


# ----------------------------------------------------------------- the SFX
def sfx_waka(open_mouth: bool) -> np.ndarray:
    """THE CHOMP - the original's waka is two alternating half-sounds;
    ours: a warm square squelch that bends down (open) / up (closed)."""
    dur = 0.085
    if open_mouth:
        sig = sweep(410, 190, dur, "square") * 0.5
    else:
        sig = sweep(190, 430, dur, "square") * 0.5
    body = lowpass(sig, 0.24) * env(len(sig), 0.004, 0.045)
    cn = int(SR * 0.02)
    click = np.zeros_like(body)
    click[:cn] = lowpass(noise(0.02), 0.5)[:cn] * env(cn, 0.001, 0.018) * 0.25
    return body + click


def sfx_power() -> np.ndarray:
    """the blue magical dot: the rush zap - a blue rising double sting."""
    dur = 0.42
    n = int(SR * dur)
    a = sweep(300, 900, 0.20, "sine") * env(int(SR * 0.20), 0.005, 0.09)
    b = sweep(600, 1500, 0.20, "tri") * env(int(SR * 0.20), 0.005, 0.14)
    out = np.zeros(n)
    place(out, 0.0, a, 0.7)
    place(out, 0.17, b, 0.75)
    shimmer = lowpass(noise(dur), 0.7) * env(n, 0.16, 0.22) * 0.16
    return out + shimmer


def sfx_eat() -> np.ndarray:
    """a ball-eater swallowed: gulp DOWN then pop UP."""
    dur = 0.34
    n = int(SR * dur)
    gulp = sweep(520, 130, 0.16, "sine") * env(int(SR * 0.16), 0.004, 0.10)
    pop = sweep(180, 720, 0.14, "square") * 0.35 * env(int(SR * 0.14), 0.004, 0.10)
    out = np.zeros(n)
    place(out, 0.0, gulp, 0.85)
    place(out, 0.17, pop, 0.8)
    return out


def sfx_eyes() -> np.ndarray:
    """the eaten one runs home: a soft, sad, quick double blink."""
    dur = 0.3
    n = int(SR * dur)
    b1 = sweep(700, 480, 0.11, "tri") * env(int(SR * 0.11), 0.004, 0.08)
    b2 = sweep(560, 380, 0.11, "tri") * env(int(SR * 0.11), 0.004, 0.08)
    out = np.zeros(n)
    place(out, 0.0, b1, 0.5)
    place(out, 0.14, b2, 0.42)
    return out


def sfx_hurt() -> np.ndarray:
    """losing a life - the descending wah-wah-wah sweep."""
    dur = 1.0
    out = np.zeros(int(SR * dur))
    steps = [(0.00, 420, 0.30), (0.30, 320, 0.30), (0.60, 240, 0.34)]
    for i, (at, f0, d) in enumerate(steps):
        sig = sweep(f0, f0 * 0.55, d, "square") * 0.4
        sig = lowpass(sig, 0.22) * env(len(sig), 0.01, 0.16)
        place(out, at, sig, 0.9 - 0.12 * i)
    return out


def sfx_life() -> np.ndarray:
    """the 500th dot: an extra life - the bright rising run."""
    dur = 0.62
    out = np.zeros(int(SR * dur))
    notes = [523.25, 659.25, 783.99, 1046.5, 1318.5]
    for i, f in enumerate(notes):
        d = 0.16 if i < len(notes) - 1 else 0.30
        sig = bellish(f, d)
        place(out, i * 0.075, sig, 0.6)
    return out


def bellish(f, dur, decay=6.0):
    t = t_axis(dur)
    return (np.sin(2 * np.pi * f * t) * 0.62
            + square(f * 2, dur, 0.5) * 0.10
            + np.sin(2 * np.pi * f * 3.01 * t) * 0.06) * np.exp(-t * decay)


def sfx_coin() -> np.ndarray:
    """the GOGACoin - the house coin family: bright close pair."""
    dur = 0.26
    out = np.zeros(int(SR * dur))
    place(out, 0.0, bellish(1318.5, 0.14, 9.0), 0.55)
    place(out, 0.085, bellish(1760.0, 0.18, 8.0), 0.5)
    return out


def sfx_clear() -> np.ndarray:
    """the maze wipe: every dot eaten - the fast climbing run."""
    dur = 0.85
    out = np.zeros(int(SR * dur))
    notes = [392.0, 493.88, 587.33, 783.99, 987.77, 1174.66]
    for i, f in enumerate(notes):
        d = 0.14 if i < len(notes) - 1 else 0.4
        sig = bellish(f, d, 5.0)
        place(out, i * 0.085, sig, 0.55)
    sparkle = lowpass(noise(dur), 0.8) * env(int(SR * dur), 0.4, 0.4) * 0.05
    return out + sparkle


def sfx_start() -> np.ndarray:
    """the READY sting: the mouth opens, the hunt begins."""
    dur = 0.7
    out = np.zeros(int(SR * dur))
    place(out, 0.0, bellish(523.25, 0.2, 6.0), 0.55)
    place(out, 0.16, bellish(659.25, 0.2, 6.0), 0.55)
    place(out, 0.32, bellish(783.99, 0.36, 5.0), 0.62)
    place(out, 0.32, sweep(392, 784, 0.3, "tri") * 0.22
          * env(int(SR * 0.3), 0.01, 0.2), 0.5)
    return out


# -------------------------------------------------------------- the theme
def theme() -> np.ndarray:
    """the maze-chomp loop: bouncy 118 bpm, round bass + square lead.
    8 bars of 4 beats, seamless - the end lands where the start began."""
    bpm = 118.0
    beat = 60.0 / bpm
    bars = 8
    total = bars * 4 * beat
    buf = np.zeros(int(SR * total) + 8)

    # the bass: a walking octave bounce (A minor-ish, the arcade dark)
    bass_root = 110.0                     # A2
    bass_pat = [0, 0, 7, 0, 0, 3, 5, 7]   # semitones per half-beat pair
    for b in range(bars):
        for i, st in enumerate(bass_pat):
            f = bass_root * (2 ** (st / 12.0))
            d = beat * 0.42
            sig = tri(f, d) * env(int(SR * d), 0.004, 0.16) * 0.4
            place(buf, b * 4 * beat + i * beat * 0.5, sig)

    # the lead: the chomp melody (square, staccato, slightly squeaky)
    lead_pat = [  # (semitone from A4 or None, len in half-beats) x 16 per bar
        [0, None, 3, None, 7, None, 3, None],
        [10, None, 7, None, 3, None, 0, None],
        [0, None, 3, None, 8, None, 7, None],
        [5, None, 3, None, 2, None, 0, None],
    ]
    a4 = 440.0
    for b in range(bars):
        pat = lead_pat[b % 4]
        t0 = b * 4 * beat
        for i, st in enumerate(pat):
            if st is None:
                continue
            f = a4 * (2 ** (st / 12.0))
            d = beat * 0.46
            sig = square(f, d, 0.42) * 0.16 * env(int(SR * d), 0.006, 0.10)
            place(buf, t0 + i * beat * 0.5, sig)

    # the sprinkle: a soft hat on every off-beat
    for b in range(bars):
        for i in range(4):
            d = 0.03
            sig = lowpass(noise(d), 0.75) * env(int(SR * d), 0.001, 0.026) * 0.10
            place(buf, b * 4 * beat + i * beat + beat * 0.5, sig)

    # THE SEAMLESS LAW: trim to exact length, wrap the tail around the head
    n = int(SR * total)
    tail = buf[n:] + 0.0
    out = buf[:n].copy()
    out[: len(tail)] += tail
    return np.stack([out * 0.9, out * 0.9], axis=1)


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    sfx_dir = os.path.join(root, "assets/audio/sfx")
    mus_dir = os.path.join(root, "assets/audio/music")
    print("DOT EATER sfx:")
    write_wav(os.path.join(sfx_dir, "de_waka_a.wav"), sfx_waka(True))
    write_wav(os.path.join(sfx_dir, "de_waka_b.wav"), sfx_waka(False))
    write_wav(os.path.join(sfx_dir, "de_power.wav"), sfx_power())
    write_wav(os.path.join(sfx_dir, "de_eat.wav"), sfx_eat())
    write_wav(os.path.join(sfx_dir, "de_eyes.wav"), sfx_eyes())
    write_wav(os.path.join(sfx_dir, "de_hurt.wav"), sfx_hurt())
    write_wav(os.path.join(sfx_dir, "de_life.wav"), sfx_life())
    write_wav(os.path.join(sfx_dir, "de_coin.wav"), sfx_coin())
    write_wav(os.path.join(sfx_dir, "de_clear.wav"), sfx_clear())
    write_wav(os.path.join(sfx_dir, "de_start.wav"), sfx_start())
    print("DOT EATER theme:")
    write_wav(os.path.join(mus_dir, "de_theme.wav"), theme())


if __name__ == "__main__":
    main()
