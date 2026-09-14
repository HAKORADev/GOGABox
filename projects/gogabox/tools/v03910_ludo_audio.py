#!/usr/bin/env python3
"""v03910_ludo_audio.py - BOARD LUDO (v0.3.9-10) audio, 100% synthesized,
the house way (nothing sampled, nothing scraped).

THE OWNER'S ASKS pinned here:
  - "there should be proper VFXs matching the colors of each theme/skin
    and SFXs that feels satisfying for each state" - the whole set:
      ld_roll    the die shuffles (a dry rattle)
      ld_settle  the die lands on its face (a wooden thock)
      ld_hop     one hop of the walk (a soft tick, pitch rises per step
                 in the game - these files are the base pitches)
      ld_drop    the 6-drop: a pawn leaves its nest (a soft pop + land)
      ld_eat     the capture: a whoosh down and a felt thud (the slide
                 follows it - the sound is the bite, the slide is the drama)
      ld_home    a pawn reaches home (a warm two-note arrival chime)
      ld_denied  no legal moves (a low polite double-buzz, the dice game's
                 denied voice's cousin)
      ld_select  a pawn is tapped (a tiny felt tick)
      ld_coin    the board coin (bright two-note rise, the box coin law)
      ld_win     the round is yours (a rising fanfare)
      ld_lose    the round is gone (a slow descending wah)
  - "a music for the game" - assets/audio/music/ludo_theme.wav: a light,
    bouncing major-key loop - a family table, not a battlefield.

Re-derive: python3 projects/gogabox/tools/v03910_ludo_audio.py
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


def noise(dur, seed=39):
    return np.random.RandomState(seed).uniform(-1, 1, int(SR * dur))


def lowpass(x, alpha):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def bandpass(x, lo, hi):
    hp = x.copy()
    acc = 0.0
    a = float(np.exp(-2 * np.pi * lo / SR))
    for i, v in enumerate(x):
        acc = a * acc + (1 - a) * v
        hp[i] = v - acc
    lp = hp.copy()
    acc = 0.0
    b = float(np.exp(-2 * np.pi * hi / SR))
    for i, v in enumerate(hp):
        acc += (1 - b) * (v - acc)
        lp[i] = acc
    return lp


# ----------------------------------------------------------------- voices

def s_roll():
    """the rattle: 6 dry clicks tumbling in a hand"""
    d = 0.5
    n = int(SR * d)
    x = np.zeros(n)
    rng = np.random.RandomState(7)
    for k in range(6):
        at = int(SR * (0.03 + 0.07 * k + rng.uniform(0.0, 0.03)))
        dur = 0.035
        click = bandpass(noise(dur, 61 + k), 1400, 5200) \
            * env(int(SR * dur), 0.001, 0.03)
        i1 = min(n, at + click.size)
        x[at:i1] += click[:i1 - at] * (0.55 - 0.05 * k)
    return x * 0.6


def s_settle():
    """the thock: the die lands - wood body, tiny top click"""
    d = 0.18
    body = sweep(420, 170, d) * env(int(SR * d), 0.001, 0.14)
    tick = bandpass(noise(0.012, 67), 2200, 7000) \
        * env(int(SR * 0.012), 0.0005, 0.01) * 0.6
    x = body * 0.8
    x[:tick.size] += tick
    return x * 0.66


def s_hop():
    """the step: a soft felt tick with a tiny wooden body"""
    d = 0.07
    body = sine(310, d) * env(int(SR * d), 0.001, 0.055)
    felt = lowpass(noise(d, 71), 0.28) * env(int(SR * d), 0.001, 0.03) * 0.5
    return (body + felt) * 0.5


def s_drop():
    """the 6-drop: the pawn leaves the nest - a soft pop up, a land"""
    d = 0.2
    up = sweep(320, 640, 0.09) * env(int(SR * 0.09), 0.002, 0.06)
    land = sweep(520, 240, 0.1) * env(int(SR * 0.1), 0.002, 0.08)
    n = int(SR * d)
    x = np.zeros(n)
    x[:up.size] += up * 0.6
    i0 = int(SR * 0.1)
    x[i0:i0 + land.size] += land * 0.7
    return x * 0.6


def s_eat():
    """the bite: a whoosh down, a felt thud - the slide follows"""
    d = 0.3
    woosh = bandpass(noise(d, 73), 300, 2400)
    shape = np.linspace(1.0, 0.25, woosh.size) ** 1.3
    x = woosh * shape * env(int(SR * d), 0.006, 0.16)
    thud = sweep(200, 90, 0.14) * env(int(SR * 0.14), 0.002, 0.11)
    x[:thud.size] += thud * 0.9
    return x * 0.72


def s_home():
    """the arrival: a warm two-note chime up (the pawn is safe forever)"""
    d = 0.42
    n = int(SR * d)
    x = np.zeros(n)
    a = (sine(659, 0.14) + 0.4 * sine(1318, 0.14)) \
        * env(int(SR * 0.14), 0.004, 0.1)
    b = (sine(880, 0.26) + 0.4 * sine(1760, 0.26)) \
        * env(int(SR * 0.26), 0.004, 0.2)
    x[:a.size] += a
    x[int(SR * 0.12):int(SR * 0.12) + b.size] += b
    return x * 0.46


def s_denied():
    """no legal moves: a low polite double-buzz"""
    d = 0.24
    n = int(SR * d)
    x = np.zeros(n)
    buzz = np.sin(2 * np.pi * 150 * t_axis(0.08)) \
        * env(int(SR * 0.08), 0.003, 0.05)
    x[:buzz.size] += buzz * 0.5
    x[int(SR * 0.12):int(SR * 0.12) + buzz.size] += buzz * 0.4
    return x * 0.5


def s_select():
    """the tap: a tiny felt tick"""
    d = 0.05
    x = lowpass(noise(d, 79), 0.32) * env(int(SR * d), 0.001, 0.04)
    return x * 0.42


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
    """the round is yours: a rising fanfare arpeggio, warm"""
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
    """the round is gone: a slow descending wah, gentle"""
    d = 0.8
    x = sweep(392, 150, d)
    x += 0.3 * sweep(196, 75, d)
    x *= env(int(SR * d), 0.02, 0.5)
    return x * 0.42


# ----------------------------------------------------------------- music

def music():
    """a light bouncing major-key loop - C - Am - F - G, a family table"""
    bpm = 104.0
    beat = 60.0 / bpm
    bars = 8
    dur = bars * 4 * beat
    n = int(SR * dur)
    x = np.zeros(n)

    def put(seg, at):
        i0 = int(SR * at)
        i1 = min(n, i0 + seg.size)
        x[i0:i1] += seg[:i1 - i0]

    chords = [
        [261.63, 329.63, 392.0],    # C
        [220.0, 261.63, 329.63],    # Am
        [174.61, 220.0, 261.63],    # F
        [196.0, 246.94, 293.66],    # G
    ]
    t_h = 2 * beat
    pad_env = env(int(SR * t_h), 0.05, 0.45)
    for bar in range(bars):
        ch = chords[(bar // 2) % 4]
        for bi in range(2):
            at = bar * 4 * beat + bi * t_h
            for f in ch:
                v = (sine(f, t_h) + 0.22 * sine(f * 2, t_h)) * pad_env
                put(v * 0.085, at)
    # the bouncy bass: root on 1&3, fifth on 2&4, an octave hop of air
    bass_env = env(int(SR * beat * 0.85), 0.008, 0.3)
    for bar in range(bars):
        root = chords[(bar // 2) % 4][0] / 2
        fifth = root * 1.5
        for bi, f in enumerate([root, fifth, root, fifth]):
            at = bar * 4 * beat + bi * beat
            v = sine(f, beat * 0.85) * bass_env
            put(v * 0.22, at)
    # the music-box melody: a simple 8th-note sing-song on the chord tones
    mel_env = env(int(SR * beat * 0.5), 0.003, 0.18)
    melody = [0, 1, 2, 1, 0, 2, 1, 2]
    for bar in range(bars):
        ch = chords[(bar // 2) % 4]
        for bi in range(8):
            f = ch[melody[bi]] * 2
            at = bar * 4 * beat + bi * beat * 0.5
            v = (sine(f, beat * 0.5) + 0.3 * sine(f * 2, beat * 0.5)) \
                * mel_env
            put(v * 0.075, at)
    # a gentle stereo sway
    t = t_axis(dur)
    lfo = 0.10 * np.sin(2 * np.pi * 0.13 * t)
    left = x * (1.0 + lfo)
    right = x * (1.0 - lfo)
    return np.stack([left, right], axis=1) * 0.9


def main():
    print("board ludo sfx:")
    for name, fn in [("ld_roll", s_roll), ("ld_settle", s_settle),
                     ("ld_hop", s_hop), ("ld_drop", s_drop),
                     ("ld_eat", s_eat), ("ld_home", s_home),
                     ("ld_denied", s_denied), ("ld_select", s_select),
                     ("ld_coin", s_coin), ("ld_win", s_win),
                     ("ld_lose", s_lose)]:
        write_wav(f"{SFX_DIR}/{name}.wav", fn())
    print("board ludo music:")
    write_wav(f"{MUS_DIR}/ludo_theme.wav", music())


if __name__ == "__main__":
    main()
