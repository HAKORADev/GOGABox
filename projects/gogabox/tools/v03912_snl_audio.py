#!/usr/bin/env python3
"""v03912_snl_audio.py - SNAKES & LADDERS (v0.3.9-12) audio, 100%
synthesized, the house way (nothing sampled, nothing scraped).

THE GDD's set (docs/goga_docs/gogames_ideas/snl.md):
      snl_roll    the die shuffles (a soft rattle - the tray's own voice)
      snl_settle  the die lands on its face (a wooden thock)
      snl_hop     one hop of the walk (a soft tick; the game raises the
                  pitch a step per hop - the walk sings upward)
      snl_climb   the LADDER ride: a rising rung-gliss (rung ticks under
                  a rising marimba - "slides up in straight lanes")
      snl_fall    the SNAKE fall: a descending wobble slide (the body's
                  turns are heard in the wobble, a soft thud at the tail)
      snl_denied  the overshoot refusal (a low polite double-buzz, the
                  dice game's denied voice's cousin)
      snl_coin    the board coin (bright two-note rise, the box coin law)
      snl_win     the round is yours (a rising fanfare)
      snl_lose    the round is gone (a slow descending wah)
  - "a music for the game" - assets/audio/music/snl_theme.wav: a gentle
    pentatonic music-box loop - a dreamy climb-and-slide, not a race.

Re-derive: python3 projects/gogabox/tools/v03912_snl_audio.py
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
    """the rattle: 5 dry clicks tumbling in a cupped hand (softer, warmer
    than the ludo rattle - a wooden cup, not a tin cup)"""
    d = 0.46
    n = int(SR * d)
    x = np.zeros(n)
    rng = np.random.RandomState(11)
    for k in range(5):
        at = int(SR * (0.04 + 0.08 * k + rng.uniform(0.0, 0.035)))
        dur = 0.04
        click = bandpass(noise(dur, 83 + k), 1000, 4200) \
            * env(int(SR * dur), 0.001, 0.032)
        i1 = min(n, at + click.size)
        x[at:i1] += click[:i1 - at] * (0.5 - 0.05 * k)
    body = sweep(240, 180, d) * 0.06
    x[:body.size] += body
    return x * 0.6


def s_settle():
    """the thock: the die lands - warm wood body, tiny top click"""
    d = 0.19
    body = sweep(380, 150, d) * env(int(SR * d), 0.001, 0.15)
    tick = bandpass(noise(0.012, 87), 2000, 6600) \
        * env(int(SR * 0.012), 0.0005, 0.01) * 0.55
    x = body * 0.82
    x[:tick.size] += tick
    return x * 0.66


def s_hop():
    """the step: a soft felt tick with a tiny wooden body (the game
    raises its pitch per hop - the walk sings upward)"""
    d = 0.07
    body = sine(340, d) * env(int(SR * d), 0.001, 0.055)
    felt = lowpass(noise(d, 91), 0.28) * env(int(SR * d), 0.001, 0.03) * 0.5
    return (body + felt) * 0.5


def s_climb():
    """the ladder ride: rung ticks under a rising marimba gliss - the
    straight lane up, heard"""
    d = 0.62
    n = int(SR * d)
    x = np.zeros(n)
    # the rising gliss (a marimba-ish sweep with a woody 2nd partial)
    gliss = sweep(330, 880, d)
    gliss += 0.35 * sweep(660, 1760, d)
    gliss *= env(n, 0.01, 0.22)
    x += gliss * 0.4
    # the rungs: 7 even ticks climbing with the gliss
    rng = np.random.RandomState(17)
    for k in range(7):
        at = int(SR * (0.02 + 0.082 * k))
        dur = 0.028
        tick = bandpass(noise(dur, 101 + k), 1600, 5600) \
            * env(int(SR * dur), 0.001, 0.022)
        i1 = min(n, at + tick.size)
        x[at:i1] += tick[:i1 - at] * (0.34 - 0.02 * k)
    # the top: a small arrival bell
    bell = (sine(1046, 0.16) + 0.4 * sine(2093, 0.16)) \
        * env(int(SR * 0.16), 0.003, 0.13)
    i0 = n - bell.size
    x[i0:] += bell * 0.42
    return x * 0.56


def s_fall():
    """the snake fall: a descending wobble slide (the body's turns are
    the wobble), a soft thud at the tail"""
    d = 0.72
    n = int(SR * d)
    # the slide: 880 -> 180 with a serpent wobble riding it
    base = sweep(880, 180, d)
    wob = 0.35 * np.sin(2 * np.pi * 11.0 * t_axis(d)) \
        * sweep(300, 90, d)
    x = (base + wob) * env(n, 0.012, 0.3)
    # the hiss: a breath of air under the slide
    hiss = bandpass(noise(d, 113), 2600, 8200)
    x += hiss * np.linspace(0.1, 0.02, x.size) * 0.4
    # the tail thud
    thud = sweep(190, 80, 0.16) * env(int(SR * 0.16), 0.002, 0.13)
    i0 = n - thud.size
    x[i0:] += thud * 0.9
    return x * 0.6


def s_denied():
    """the overshoot: a low polite double-buzz (a flat third below the
    ludo one, so the family hears the difference)"""
    d = 0.26
    n = int(SR * d)
    x = np.zeros(n)
    buzz = np.sin(2 * np.pi * 133 * t_axis(0.09)) \
        * env(int(SR * 0.09), 0.003, 0.055)
    x[:buzz.size] += buzz * 0.5
    x[int(SR * 0.14):int(SR * 0.14) + buzz.size] += buzz * 0.4
    return x * 0.5


def s_coin():
    """the board coin: bright two-note rise (the box coin law)"""
    d = 0.34
    n = int(SR * d)
    x = np.zeros(n)
    a = sine(1047, 0.12) * env(int(SR * 0.12), 0.003, 0.09)
    b = sine(1568, 0.2) * env(int(SR * 0.2), 0.003, 0.16)
    x[:a.size] += a
    x[int(SR * 0.09):int(SR * 0.09) + b.size] += b
    return x * 0.5


def s_win():
    """the summit: a rising fanfare arpeggio, warm"""
    d = 0.9
    n = int(SR * d)
    x = np.zeros(n)
    notes = [(587, 0.0, 0.22), (740, 0.11, 0.22), (880, 0.22, 0.22),
             (1175, 0.33, 0.5)]
    for f, at, dur in notes:
        seg = (sine(f, dur) + 0.4 * sine(2 * f, dur)) \
            * env(int(SR * dur), 0.005, dur * 0.7)
        i0 = int(SR * at)
        x[i0:i0 + seg.size] += seg
    return x * 0.42


def s_lose():
    """the slide of shame: a slow descending wah, gentle"""
    d = 0.8
    x = sweep(370, 140, d)
    x += 0.3 * sweep(185, 70, d)
    x *= env(int(SR * d), 0.02, 0.5)
    return x * 0.42


# ----------------------------------------------------------------- music

def music():
    """a gentle pentatonic music-box loop - Am - F - C - G, a dreamy
    climb-and-slide (the melody drifts up a ladder and slides back
    down, on purpose - the game's own story in the loop)"""
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

    chords = [
        [220.0, 261.63, 329.63],    # Am
        [174.61, 220.0, 261.63],    # F
        [261.63, 329.63, 392.0],    # C
        [196.0, 246.94, 293.66],    # G
    ]
    # the soft pad
    t_h = 2 * beat
    pad_env = env(int(SR * t_h), 0.06, 0.5)
    for bar in range(bars):
        ch = chords[(bar // 2) % 4]
        for bi in range(2):
            at = bar * 4 * beat + bi * t_h
            for f in ch:
                v = (sine(f, t_h) + 0.2 * sine(f * 2, t_h)) * pad_env
                put(v * 0.08, at)
    # the round bass: root on 1&3, fifth on 2&4
    bass_env = env(int(SR * beat * 0.85), 0.008, 0.32)
    for bar in range(bars):
        root = chords[(bar // 2) % 4][0] / 2
        fifth = root * 1.5
        for bi, f in enumerate([root, fifth, root, fifth]):
            at = bar * 4 * beat + bi * beat
            v = sine(f, beat * 0.85) * bass_env
            put(v * 0.2, at)
    # THE CLIMB-AND-SLIDE MELODY: A-minor pentatonic, the phrase walks
    # UP for two bars then slides back DOWN for two - over and over,
    # the board's own story
    penta = [440.0, 523.25, 587.33, 659.25, 783.99, 880.0]
    up = [0, 1, 2, 3, 4, 5]
    down = [5, 4, 3, 2, 1, 0]
    mel_env = env(int(SR * beat * 0.62), 0.003, 0.24)
    for bar in range(bars):
        phrase = up if (bar // 2) % 2 == 0 else down
        for bi in range(4):
            step = phrase[bi if len(phrase) > bi else -1]
            f = penta[min(step, penta.size if hasattr(
                penta, "size") else len(penta) - 1)]
            at = bar * 4 * beat + bi * beat
            v = (sine(f, beat * 0.62) + 0.3 * sine(f * 2, beat * 0.62)) \
                * mel_env
            put(v * 0.085, at)
    # a gentle stereo sway
    t = t_axis(dur)
    lfo = 0.10 * np.sin(2 * np.pi * 0.11 * t)
    left = x * (1.0 + lfo)
    right = x * (1.0 - lfo)
    return np.stack([left, right], axis=1) * 0.9


def main():
    print("snakes & ladders sfx:")
    for name, fn in [("snl_roll", s_roll), ("snl_settle", s_settle),
                     ("snl_hop", s_hop), ("snl_climb", s_climb),
                     ("snl_fall", s_fall), ("snl_denied", s_denied),
                     ("snl_coin", s_coin), ("snl_win", s_win),
                     ("snl_lose", s_lose)]:
        write_wav(f"{SFX_DIR}/{name}.wav", fn())
    print("snakes & ladders music:")
    write_wav(f"{MUS_DIR}/snl_theme.wav", music())


if __name__ == "__main__":
    main()
