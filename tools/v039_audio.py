#!/usr/bin/env python3
"""v039_audio.py - FOUR IN LINE + FIVE IN ROW (v0.3.9) audio.
100% synthesized - the house way (nothing sampled, nothing scraped).

FOUR IN LINE (assets/audio/sfx/fl_*.wav):
  tap     the column pick (a soft toy tick)
  drop    the launch whoosh (short falling glide)
  land    THE THUD (the whole game lives on this one) - a wood knock
          with a tiny bounce tail
  denied  the full column (dull double buzz-thud)
  coin    the GOGACoin ding (bright pair, the house coin family)
  win     the round rise (warm major run)
  lose    the round fall (minor two-tone)
  draw    the neutral settle

FIVE IN ROW (assets/audio/sfx/bv_*.wav):
  stone   THE CLACK (go stone on wood - a crisp knock, glassy edge)
  denied  the occupied point (short dull tick)
  coin    the GOGACoin ding (the house coin family, warmer pair)
  win     the round rise (five stones sing up)
  lose    the round fall
  draw    the neutral settle

THEMES (assets/audio/music/):
  fl_theme.wav  the toy-shop loop - warm plucks over a soft pad, 96 bpm,
                8 bars, seamless (ends where it starts)
  bv_theme.wav  the board-room loop - slower felt-piano plucks, 80 bpm,
                8 bars, seamless

Re-derive: python3 tools/v039_audio.py
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


def bell(f, dur, decay=7.0):
    t = t_axis(dur)
    return (np.sin(2 * np.pi * f * t) * 0.7
            + np.sin(2 * np.pi * f * 2.01 * t) * 0.2
            + np.sin(2 * np.pi * f * 2.98 * t) * 0.08) * np.exp(-t * decay)


def noise(dur):
    return np.random.uniform(-1, 1, int(SR * dur))


def lowpass(x, alpha):
    out = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        out[i] = acc
    return out


def highpass(x, alpha):
    return x - lowpass(x, alpha)


def place(buf, at, sig, gain=1.0):
    i = int(at * SR)
    j = min(len(buf), i + len(sig))
    if i < len(buf):
        buf[i:j] += sig[: j - i] * gain


def knock(f_body, dur, punch=1.0):
    """the GOGABox knock: band-passed noise crack fused to a low body thump."""
    n = highpass(lowpass(noise(dur), 0.35), 0.08)
    crack = n * env(int(SR * dur), 0.001, dur * 0.85)
    body = sine(f_body, dur) * env(int(SR * dur), 0.001, dur * 0.7)
    return (crack * 0.75 + body * 0.9) * punch


# ============================================================ FOUR IN LINE

def fl_tap():
    d = 0.09
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, sine(620, 0.04) * env(int(SR * 0.04), 0.002, 0.028), 0.28)
    place(buf, 0.03, sine(880, 0.045) * env(int(SR * 0.045), 0.002, 0.032), 0.18)
    return buf


def fl_drop():
    """the falling glide: a sine that dips as the disc drops."""
    d = 0.22
    t = t_axis(d)
    f = 700.0 - 420.0 * (t / d)
    ph = 2 * np.pi * np.cumsum(f) / SR
    buf = np.sin(ph) * env(int(SR * d), 0.012, 0.14) * 0.34
    buf += lowpass(noise(d), 0.2) * env(int(SR * d), 0.01, 0.16) * 0.12
    return buf


def fl_land():
    d = 0.26
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, knock(150, 0.10), 0.95)
    # the bounce: two softer thuds, the toy seat
    place(buf, 0.09, knock(120, 0.07, 0.5), 0.34)
    place(buf, 0.16, knock(100, 0.06, 0.35), 0.18)
    return buf


def fl_denied():
    d = 0.30
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, sine(140, 0.09) * env(int(SR * 0.09), 0.003, 0.06), 0.5)
    place(buf, 0.12, sine(120, 0.11) * env(int(SR * 0.11), 0.003, 0.08), 0.5)
    return buf


def fl_coin():
    d = 0.5
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, bell(1318, 0.3, decay=9.0), 0.5)
    place(buf, 0.10, bell(1976, 0.34, decay=8.0), 0.45)
    return buf


def fl_win():
    d = 0.85
    buf = np.zeros(int(SR * d))
    for i, f in enumerate([523, 659, 784, 1046]):
        place(buf, i * 0.09, bell(f, 0.4, decay=6.0), 0.42)
    place(buf, 0.38, bell(1568, 0.46, decay=5.0), 0.3)
    return buf


def fl_lose():
    d = 0.7
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, bell(392, 0.34, decay=6.5), 0.45)
    place(buf, 0.18, bell(311, 0.42, decay=5.5), 0.45)
    place(buf, 0.18, sine(155, 0.4) * env(int(SR * 0.4), 0.01, 0.3), 0.2)
    return buf


def fl_draw():
    d = 0.5
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, bell(440, 0.3, decay=7.0), 0.4)
    place(buf, 0.14, bell(440, 0.34, decay=6.0), 0.32)
    return buf


# ============================================================== FIVE IN ROW

def bv_stone():
    """go stone on wood: a crisp knock with a glassy edge."""
    d = 0.17
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, knock(210, 0.08, 0.9), 0.9)
    place(buf, 0.0, bell(1245, 0.07, decay=18.0), 0.14)
    place(buf, 0.045, knock(150, 0.08, 0.55), 0.4)
    return buf


def bv_denied():
    d = 0.14
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, sine(180, 0.06) * env(int(SR * 0.06), 0.002, 0.045), 0.42)
    return buf


def bv_coin():
    d = 0.55
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, bell(1175, 0.3, decay=9.0), 0.48)
    place(buf, 0.11, bell(1760, 0.36, decay=8.0), 0.44)
    return buf


def bv_win():
    d = 0.9
    buf = np.zeros(int(SR * d))
    for i, f in enumerate([392, 523, 659, 784]):
        place(buf, i * 0.10, bell(f, 0.42, decay=6.0), 0.4)
    place(buf, 0.42, bell(1046, 0.5, decay=4.5), 0.32)
    return buf


def bv_lose():
    d = 0.7
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, bell(349, 0.34, decay=6.5), 0.44)
    place(buf, 0.18, bell(277, 0.44, decay=5.0), 0.44)
    place(buf, 0.18, sine(139, 0.42) * env(int(SR * 0.42), 0.01, 0.3), 0.2)
    return buf


def bv_draw():
    d = 0.5
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, bell(415, 0.3, decay=7.0), 0.38)
    place(buf, 0.14, bell(415, 0.34, decay=6.0), 0.3)
    return buf


# ================================================================== THEMES

def pluck(f, dur, decay=6.0, bright=1.0):
    t = t_axis(dur)
    sig = (np.sin(2 * np.pi * f * t)
           + 0.42 * bright * np.sin(2 * np.pi * f * 2 * t)
           + 0.16 * np.sin(2 * np.pi * f * 3 * t))
    return sig * np.exp(-t * decay)


def pad_chord(freqs, dur, gain=1.0):
    n = int(SR * dur)
    buf = np.zeros(n)
    for f in freqs:
        t = t_axis(dur)
        v = (np.sin(2 * np.pi * f * t)
             + 0.5 * np.sin(2 * np.pi * f * 1.003 * t)) / len(freqs)
        buf += v
    # swell in, sink out - a pad breathes
    x = np.ones(n)
    x[: int(0.35 * n)] = np.linspace(0, 1, int(0.35 * n))
    x[-int(0.45 * n):] *= np.linspace(1, 0, int(0.45 * n))
    return buf * x * gain


def theme(scale_root, chords, melody, bpm, bars, beat_split=2):
    """8-bar seamless loop: pad chords on the bar, plucks on the off-beats.
    The loop ends exactly where it starts (no fade-out, no click)."""
    beat = 60.0 / bpm
    bar = beat * 4
    total = bar * bars
    buf = np.zeros(int(SR * total) + SR)  # headroom; trimmed to total
    for b in range(bars):
        at = b * bar
        place(buf, at, pad_chord(chords[b % len(chords)], bar * 0.98, 0.10))
    # the melody: plucks seeded on the scale, two per beat
    step = beat / beat_split
    t_slots = int(total / step)
    for s in range(t_slots):
        deg = melody[s % len(melody)]
        if deg <= 0:
            continue
        f = scale_root * (2 ** ((deg - 1) / 12.0))
        place(buf, s * step, pluck(f, step * 2.4, 5.0, 1.0), 0.16)
    return buf[: int(SR * total)]


def fl_theme():
    # C major pentatonic toy-shop: warm I - vi - IV - V
    C, Am, F, G = 130.81, 110.0, 87.31, 98.0
    chords = [[C * 1.0, C * 1.26, C * 1.5],
              [Am * 1.0, Am * 1.2, Am * 1.5],
              [F * 1.5, F * 1.89, F * 2.24],
              [G * 1.34, G * 1.68, G * 2.0]]
    # (deg, octave-up pentatonic degrees; 0 = rest) - a gentle wandering
    mel = [1, 3, 5, 6, 5, 3, 0, 1, 3, 5, 8, 6, 5, 3, 1, 0]
    return theme(C, chords, mel, bpm=96, bars=8)


def bv_theme():
    # A minor board room: felt-piano calm, Am - F - C - G
    A, F, C, G = 110.0, 87.31, 65.41, 98.0
    chords = [[A * 1.0, A * 1.2, A * 1.5],
              [F * 1.5, F * 1.89, F * 2.24],
              [C * 2.0, C * 2.52, C * 3.0],
              [G * 1.34, G * 1.68, G * 2.0]]
    mel = [1, 0, 4, 0, 3, 0, 1, 0, 2, 0, 4, 5, 4, 0, 2, 1]
    return theme(A, chords, mel, bpm=80, bars=8, beat_split=1)


def main():
    np.random.seed(39)
    print("FOUR IN LINE:")
    write_wav(f"{SFX_DIR}/fl_tap.wav", fl_tap(), SR)
    write_wav(f"{SFX_DIR}/fl_drop.wav", fl_drop(), SR)
    write_wav(f"{SFX_DIR}/fl_land.wav", fl_land(), SR)
    write_wav(f"{SFX_DIR}/fl_denied.wav", fl_denied(), SR)
    write_wav(f"{SFX_DIR}/fl_coin.wav", fl_coin(), SR)
    write_wav(f"{SFX_DIR}/fl_win.wav", fl_win(), SR)
    write_wav(f"{SFX_DIR}/fl_lose.wav", fl_lose(), SR)
    write_wav(f"{SFX_DIR}/fl_draw.wav", fl_draw(), SR)
    print("FIVE IN ROW:")
    write_wav(f"{SFX_DIR}/bv_stone.wav", bv_stone(), SR)
    write_wav(f"{SFX_DIR}/bv_denied.wav", bv_denied(), SR)
    write_wav(f"{SFX_DIR}/bv_coin.wav", bv_coin(), SR)
    write_wav(f"{SFX_DIR}/bv_win.wav", bv_win(), SR)
    write_wav(f"{SFX_DIR}/bv_lose.wav", bv_lose(), SR)
    write_wav(f"{SFX_DIR}/bv_draw.wav", bv_draw(), SR)
    print("THEMES:")
    write_wav(f"{MUS_DIR}/fl_theme.wav", fl_theme(), SR)
    write_wav(f"{MUS_DIR}/bv_theme.wav", bv_theme(), SR)


if __name__ == "__main__":
    main()
