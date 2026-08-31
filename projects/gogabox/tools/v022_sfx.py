#!/usr/bin/env python3
"""v0.2.2 audio - PONG's own sound set + the court's music loop.

The owner: "dead and goal and hit and different hit speed and collecting
good powerup and bad powerup, all have to get its SFX and also goal for
user or on the user". Every voice is designed here (no downloads - the
asset-store trials in v0.1.0 showed audio stores are browser-only), and
the hit pitch is bent at play time by the ball's heat (Jukebox pitch).

Re-runnable: same code -> same bytes."""

import math
import os
import wave

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(PROJ, "assets", "audio", "sfx")
MUS = os.path.join(PROJ, "assets", "audio", "music")
SR = 44100

import numpy as np  # noqa: E402


def _save(name, data, vol=1.0):
    data = np.clip(data * vol, -1.0, 1.0)
    pcm = (data * 32767).astype(np.int16)
    if pcm.ndim == 1:
        pcm = np.column_stack([pcm, pcm])
    with wave.open(os.path.join(SFX if "music" not in name else MUS,
                    name + ".wav"), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("assets/audio/%s/%s.wav" % ("music" if "music" in name else "sfx",
                                      name))


def _t(dur):
    return np.linspace(0, dur, int(SR * dur), endpoint=False)


def _env(n, a=0.004, r=0.10):
    e = np.ones(n)
    na, nr = int(SR * a), int(SR * r)
    na, nr = min(na, n), min(nr, n)
    if na > 0:
        e[:na] = np.linspace(0, 1, na)
    if nr > 0:
        e[-nr:] *= np.linspace(1, 0, nr)
    return e


def sine(f, dur):
    return np.sin(2 * math.pi * f * _t(dur))


def sweep(f0, f1, dur):
    t = _t(dur)
    f = f0 + (f1 - f0) * (t / dur)
    ph = 2 * math.pi * np.cumsum(f) / SR
    return np.sin(ph)


def noise(dur):
    return np.random.default_rng(7).uniform(-1, 1, int(SR * dur))


def square(f, dur, duty=0.3):
    t = _t(dur)
    return np.where((t * f) % 1.0 < duty, 1.0, -1.0)


def pong_serve():
    a = sine(520, 0.08) * _env(int(SR * 0.08), r=0.05)
    b = sine(660, 0.10) * _env(int(SR * 0.10), r=0.07)
    gap = np.zeros(int(SR * 0.03))
    _save("pong_serve", np.concatenate([a, gap, b]) * 0.5)


def pong_hit():
    d = 0.07
    body = sweep(900, 500, d) * 0.6 + square(700, d, 0.25) * 0.25
    click = noise(0.012) * 0.4
    s = body + np.concatenate([click, np.zeros(int(SR * d) - len(click))])
    _save("pong_hit", s * _env(int(SR * d), r=0.045) * 0.75)


def pong_wall():
    d = 0.055
    n = int(SR * d)
    s = sweep(420, 260, d) * 0.7
    click = noise(0.01) * 0.15
    s[:len(click)] += click
    s = s[:n] if len(s) >= n else np.pad(s, (0, n - len(s)))
    _save("pong_wall", s * _env(n, r=0.035) * 0.6)


def pong_goal():
    notes = [(659.3, 0.0, 0.13), (830.6, 0.09, 0.13), (987.8, 0.18, 0.30)]
    total = int(SR * 0.55)
    mix = np.zeros(total)
    for f, at, dur in notes:
        i0 = int(SR * at)
        seg = (sine(f, dur) * 0.6 + sine(f * 2, dur) * 0.18) \
                * _env(int(SR * dur), r=0.10)
        mix[i0:i0 + len(seg)] += seg
    _save("pong_goal", mix * 0.6)


def pong_concede():
    d = 0.5
    fall = sweep(420, 240, d) * 0.5
    thump = sweep(160, 60, 0.28) * 0.8 * _env(int(SR * 0.28), r=0.2)
    s = fall + np.concatenate([thump, np.zeros(int(SR * d) - len(thump))])
    _save("pong_concede", s * _env(int(SR * d), a=0.003, r=0.16) * 0.7)


def pong_coin():
    a = sine(1318.5, 0.06) * _env(int(SR * 0.06), r=0.04)
    b = sine(1760.0, 0.12) * _env(int(SR * 0.12), r=0.09)
    gap = np.zeros(int(SR * 0.025))
    _save("pong_coin", np.concatenate([a, gap, b]) * 0.5)


def pong_pu_good():
    d = 0.24
    s = sweep(500, 940, d) * 0.55 + sweep(1000, 1880, d) * 0.2
    _save("pong_pu_good", s * _env(int(SR * d), r=0.09) * 0.6)


def pong_pu_bad():
    d = 0.28
    s = sweep(300, 165, d) * 0.5 + square(190, d, 0.4) * 0.22
    _save("pong_pu_bad", s * _env(int(SR * d), r=0.10) * 0.6)


def pong_strike():
    d = 0.36
    whoosh = noise(d) * 0.5
    # crude bandpass: difference of two smoothed noises
    k = 24
    sm = np.convolve(whoosh, np.ones(k) / k, mode="same")
    hp = whoosh - sm
    crack = sweep(1300, 480, 0.14) * 0.7 * _env(int(SR * 0.14), r=0.06)
    s = hp * _env(int(SR * d), a=0.01, r=0.2) * 0.9
    s[:len(crack)] += crack
    _save("pong_strike", s * 0.65)


def pong_end():
    notes = [(523.3, 0.0, 0.26), (392.0, 0.14, 0.42)]
    total = int(SR * 0.62)
    mix = np.zeros(total)
    for f, at, dur in notes:
        i0 = int(SR * at)
        seg = (sine(f, dur) * 0.5 + sine(f / 2, dur) * 0.25) \
                * _env(int(SR * dur), r=0.16)
        mix[i0:i0 + len(seg)] += seg
    _save("pong_end", mix * 0.55)


def pong_theme():
    """THE COURT - a dark pulse loop: kick + bass eighths, a soft pad, an
    offbeat hat and a sparse lead. 100 BPM, 8 bars, loop-clean."""
    bpm = 100.0
    beat = 60.0 / bpm
    bars = 8
    total = int(SR * beat * 4 * bars)
    mix = np.zeros(total)

    def put(seg, at):
        i0 = int(SR * at)
        n = min(len(seg), total - i0)
        if n > 0:
            mix[i0:i0 + n] += seg[:n]

    roots = [55.0, 55.0, 65.4, 49.0]   # A1 A1 C2 G1 per bar pair
    chords = [[220.0, 261.6, 329.6], [220.0, 261.6, 329.6],
              [261.6, 329.6, 392.0], [196.0, 246.9, 293.7]]
    lead = [(440.0, 0.0), (523.3, 0.75), (659.3, 1.5), (587.3, 3.0),
            (523.3, 4.5), (440.0, 6.0), (392.0, 6.75), (440.0, 7.5)]
    for bar in range(bars):
        t0 = bar * 4 * beat
        root = roots[bar % 4]
        # kick on 1 and 3
        for b in (0, 2):
            d = 0.22
            put(sweep(130, 44, d) * _env(int(SR * d), a=0.002, r=0.16) * 0.62,
                t0 + b * beat)
        # bass eighths
        for e8 in range(8):
            d = beat * 0.42
            sawish = (sine(root, d) * 0.7 + square(root, d, 0.5) * 0.14)
            g = 0.30 if e8 % 2 == 0 else 0.20
            put(sawish * _env(int(SR * d), a=0.004, r=0.10) * g,
                t0 + e8 * beat * 0.5)
        # the pad (per bar, one chord)
        ch = chords[bar % 4]
        d = 4 * beat
        pad = np.zeros(int(SR * d))
        for f in ch:
            pad += sine(f, d) * 0.05 + sine(f * 2.003, d) * 0.018
        put(pad * _env(int(SR * d), a=0.4, r=0.9), t0)
        # offbeat hats
        for e8 in range(4):
            d = 0.035
            put(noise(d) * _env(int(SR * d), a=0.001, r=0.03) * 0.05,
                t0 + (e8 + 0.5) * beat)
    # the lead over the first 2 bars (and a mirrored tail at bar 6)
    for f, b8 in lead:
        d = beat * 0.65
        vib = 1.0 + 0.004 * np.sin(2 * math.pi * 5.5 * _t(d))
        seg = sine(f, d) * vib
        put(seg * _env(int(SR * d), a=0.01, r=0.14) * 0.16, b8 * beat)
        put(seg * _env(int(SR * d), a=0.01, r=0.14) * 0.12, (16 + b8) * beat)
    # loop-clean: fade nothing - envelopes already end at zero
    stereo = np.column_stack([mix, np.roll(mix, int(SR * 0.0006))])
    name = "pong_theme"
    data = np.clip(stereo, -1, 1)
    pcm = (data * 32767).astype(np.int16)
    with wave.open(os.path.join(MUS, name + ".wav"), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("assets/audio/music/pong_theme.wav")


if __name__ == "__main__":
    pong_serve()
    pong_hit()
    pong_wall()
    pong_goal()
    pong_concede()
    pong_coin()
    pong_pu_good()
    pong_pu_bad()
    pong_strike()
    pong_end()
    pong_theme()
