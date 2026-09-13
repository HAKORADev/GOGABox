#!/usr/bin/env python3
"""v0399_audio.py - CONQUER DICE (v0.3.9-9) audio, 100% synthesized, the
house way (nothing sampled, nothing scraped).

THE OWNER'S ASKS pinned here:
  - "a music for the game itself"                -> assets/audio/music/jc_theme.wav
  - "SFXs should differ from theme to another"   -> the IN and OUT voices
    wear the theme's own timbre, five sets:
      cd_in_wood / cd_out_wood   warm marimba taps, a soft knock
      cd_in_mono / cd_out_mono   dry chalk clicks, a deep dry thump
      cd_in_chip / cd_out_chip   8-bit square bleeps, a NES zap
      cd_in_neon / cd_out_neon   glassy shimmer, a synth zap sweep
      cd_in_pop  / cd_out_pop    bubble pops, a boing
  - the shared voices: cd_press (the gray-out wake), cd_denied (the
    enemy die), cd_coin (the board coin), cd_win, cd_lose.

The cascade law of the feel: the OUT fires once, 2-4 INs answer it, and
the game raises the PITCH of each voice as the chain grows - the files
here are the base pitches, the game does the rise.

Re-derive: python3 projects/gogabox/tools/v0399_audio.py
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


def sine(f, dur, ph=0.0):
    return np.sin(2 * np.pi * f * t_axis(dur) + ph)


def sweep(f0, f1, dur):
    t = t_axis(dur)
    f = np.linspace(f0, f1, t.size)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph)


def noise(dur):
    return np.random.RandomState(39).uniform(-1, 1, int(SR * dur))


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


# ---------------------------------------------------------------- voices
# the IN voices: one die grows a dot - short, warm, per-theme timbre

def in_wood():
    """marimba tap: sine + soft 4th harmonic, fast warm decay"""
    d = 0.16
    x = sine(523, d) + 0.35 * sine(1046, d) + 0.12 * sine(1568, d)
    x *= env(int(SR * d), 0.004, 0.13)
    return x * 0.62


def in_mono():
    """dry chalk click: filtered noise tick + a short wooden sine"""
    d = 0.11
    n = lowpass(noise(d), 0.35) * env(int(SR * d), 0.001, 0.05) * 0.5
    x = sine(320, d) * env(int(SR * d), 0.001, 0.09)
    return (n + 0.7 * x) * 0.6


def in_chip():
    """8-bit bleep: square up-bend, zero sustain"""
    d = 0.10
    x = square(660, d) + 0.5 * square(990, d, 0.25)
    f = np.linspace(1.0, 1.28, x.size)
    x = x * f
    x *= env(int(SR * d), 0.002, 0.07)
    return x * 0.34


def in_neon():
    """glassy shimmer: detuned sines, tiny sparkle tail"""
    d = 0.20
    x = sine(784, d) + sine(788, d) + 0.3 * sine(1568, d)
    x *= env(int(SR * d), 0.006, 0.16)
    return x * 0.5


def in_pop():
    """bubble pop: fast downward pitch drop, soft landing"""
    d = 0.12
    x = sweep(880, 380, d)
    x *= env(int(SR * d), 0.002, 0.09)
    return x * 0.6


# the OUT voices: the die pops, dots fly - bigger, the chain's bass note

def out_wood():
    """warm knock: low sine thud + wood tap body"""
    d = 0.26
    x = sweep(340, 160, d) * env(int(SR * d), 0.003, 0.2)
    x += 0.3 * sine(680, d) * env(int(SR * d), 0.002, 0.08)
    return x * 0.68


def out_mono():
    """deep dry thump: filtered noise burst + low sine"""
    d = 0.3
    n = lowpass(noise(d), 0.16) * env(int(SR * d), 0.002, 0.16) * 0.9
    x = sweep(220, 90, d) * env(int(SR * d), 0.003, 0.22)
    return (n + 0.8 * x) * 0.66


def out_chip():
    """NES zap: square sweep down + noise tail"""
    d = 0.22
    x = sweep(520, 140, d)
    x = np.where((t_axis(d) * 300) % 1.0 < 0.5, x, -x)  # square-ify
    n = noise(d) * env(int(SR * d), 0.002, 0.15) * 0.25
    x = (x + n) * env(int(SR * d), 0.002, 0.18)
    return x * 0.4


def out_neon():
    """synth zap: detuned saw-ish sweep down with a shimmer head"""
    d = 0.3
    x = sweep(760, 120, d) + 0.4 * sweep(764, 124, d)
    spark = sine(1520, 0.05) * env(int(SR * 0.05), 0.002, 0.04)
    x[:spark.size] += 0.2 * spark
    x *= env(int(SR * d), 0.004, 0.22)
    return x * 0.5


def out_pop():
    """boing: pitch drop with a wobble (the bubble gives up)"""
    d = 0.26
    f = np.linspace(420, 140, int(SR * d)) \
        + 40 * np.sin(2 * np.pi * 11 * t_axis(d))
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) * env(int(SR * d), 0.003, 0.2)
    return x * 0.62


# the shared voices

def s_press():
    """the gray-out wake: a tiny felt tick"""
    d = 0.06
    x = lowpass(noise(d), 0.3) * env(int(SR * d), 0.001, 0.045)
    return x * 0.4


def s_denied():
    """the enemy die: a dry double-buzz, low and polite"""
    d = 0.16
    x = square(196, d, 0.3) * env(int(SR * d), 0.002, 0.1)
    gate = ((t_axis(d) * 14) % 1.0 < 0.6).astype(float)
    x = x * gate
    return x * 0.3


def s_coin():
    """the board coin: bright two-note rise (the box coin law)"""
    d = 0.34
    n = int(SR * d)
    x = np.zeros(n)
    a = sine(988, 0.12) * env(int(SR * 0.12), 0.003, 0.09)
    b = sine(1319, 0.2) * env(int(SR * 0.2), 0.003, 0.16)
    x[:a.size] += a
    x[int(SR * 0.09):int(SR * 0.09) + b.size] += b
    return x * 0.5


def s_win():
    """the conquest: a rising fanfare arpeggio, warm"""
    d = 0.9
    n = int(SR * d)
    x = np.zeros(n)
    notes = [(523, 0.0, 0.22), (659, 0.11, 0.22), (784, 0.22, 0.22),
             (1047, 0.33, 0.5)]
    for f, at, dur in notes:
        seg = (sine(f, dur) + 0.4 * sine(2 * f, dur)) \
            * env(int(SR * dur), 0.005, dur * 0.7)
        i0 = int(SR * at)
        x[i0:i0 + seg.size] += seg
    return x * 0.42


def s_lose():
    """the defeat: a slow descending wah, gentle"""
    d = 0.8
    x = sweep(392, 150, d)
    x += 0.3 * sweep(196, 75, d)
    x *= env(int(SR * d), 0.02, 0.5)
    return x * 0.42


# the music: a warm 8-bar loop - the thinking player's bed
def music():
    bpm = 92.0
    beat = 60.0 / bpm
    bars = 8
    dur = bars * 4 * beat
    n = int(SR * dur)
    x = np.zeros(n)

    def put(seg, at):
        i0 = int(SR * at)
        i1 = min(n, i0 + seg.size)
        x[i0:i1] += seg[:i1 - i0]

    # the chords: Am - F - C - G, two beats each, felt-pad voicing
    chords = [
        [220.0, 261.63, 329.63],   # A minor
        [174.61, 220.0, 261.63],   # F major
        [130.81, 196.0, 261.63],   # C major
        [196.0, 246.94, 293.66],   # G major
    ]
    t_h = 2 * beat
    pad_env = env(int(SR * t_h), 0.06, 0.5)
    for bar in range(bars):
        ch = chords[(bar // 2) % 4]
        for bi in range(2):
            at = bar * 4 * beat + bi * t_h
            for f in ch:
                v = (sine(f, t_h) + 0.25 * sine(f * 2, t_h)) * pad_env
                put(v * 0.09, at)
    # the bass: root on 1 and 3, fifth on 2 and 4
    bass_env = env(int(SR * beat * 0.9), 0.01, 0.4)
    for bar in range(bars):
        root = chords[(bar // 2) % 4][0] / 2
        fifth = root * 1.5
        for bi, f in enumerate([root, fifth, root, fifth]):
            at = bar * 4 * beat + bi * beat
            v = sine(f, beat * 0.9) * bass_env
            put(v * 0.22, at)
    # the arp: a soft 8th-note sparkle up the chord
    arp_env = env(int(SR * beat * 0.5), 0.004, 0.2)
    for bar in range(bars):
        ch = chords[(bar // 2) % 4]
        for bi in range(8):
            f = ch[bi % 3] * 2
            at = bar * 4 * beat + bi * beat * 0.5
            v = sine(f, beat * 0.5) * arp_env
            put(v * 0.05, at)
    # a gentle stereo sway
    t = t_axis(dur)
    lfo = 0.12 * np.sin(2 * np.pi * 0.15 * t)
    left = x * (1.0 + lfo)
    right = x * (1.0 - lfo)
    return np.stack([left, right], axis=1) * 0.9


def main():
    print("conquer dice sfx (per-theme voices):")
    for theme, fn in [("wood", in_wood), ("mono", in_mono),
                      ("chip", in_chip), ("neon", in_neon),
                      ("pop", in_pop)]:
        write_wav(f"{SFX_DIR}/cd_in_{theme}.wav", fn())
    for theme, fn in [("wood", out_wood), ("mono", out_mono),
                      ("chip", out_chip), ("neon", out_neon),
                      ("pop", out_pop)]:
        write_wav(f"{SFX_DIR}/cd_out_{theme}.wav", fn())
    print("conquer dice shared voices:")
    write_wav(f"{SFX_DIR}/cd_press.wav", s_press())
    write_wav(f"{SFX_DIR}/cd_denied.wav", s_denied())
    write_wav(f"{SFX_DIR}/cd_coin.wav", s_coin())
    write_wav(f"{SFX_DIR}/cd_win.wav", s_win())
    write_wav(f"{SFX_DIR}/cd_lose.wav", s_lose())
    print("conquer dice music:")
    write_wav(f"{MUS_DIR}/jc_theme.wav", music())


if __name__ == "__main__":
    main()
