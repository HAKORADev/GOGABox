#!/usr/bin/env python3
"""v0.2.8 audio - the XO sketch voices (the owner: "sketch design with
smooth animations and cool SFX").

xo_tap    a soft paper tap (cells, buttons)
xo_x      the X stroke - two dry pencil scratches
xo_o      the O stroke - one round pencil swirl
xo_win    a happy little sketch chime (rising, soft)
xo_lose   a descending wah (soft, never harsh)
xo_draw   a flat two-note "meh"
xo_think  the CPU thinking tick (tiny pencil dot)
xo_coin   the coin race - a bright pick + a little sparkle tail

Same design law as v0.2.4/6/7: every voice has a body, an edge and a tail.
Re-runnable: same code -> same bytes."""

import math
import os
import wave

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(PROJ, "assets", "audio", "sfx")
SR = 44100

import numpy as np  # noqa: E402

RNG = np.random.default_rng(2808)


def _save(name, data, vol=1.0):
    data = np.clip(data * vol, -1.0, 1.0)
    pcm = (data * 32767).astype(np.int16)
    if pcm.ndim == 1:
        pcm = np.column_stack([pcm, pcm])
    with wave.open(os.path.join(SFX, name + ".wav"), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("assets/audio/sfx/%s.wav" % name)


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


def _lowpass(x, alpha):
    y = np.empty_like(x)
    acc = 0.0
    for i in range(x.size):
        acc += alpha * (x[i] - acc)
        y[i] = acc
    return y


def _noise(dur):
    return RNG.uniform(-1.0, 1.0, int(SR * dur))


def _tone(dur, f0, f1=None, kind="sine"):
    t = _t(dur)
    if f1 is None:
        f1 = f0
    ph = 2 * math.pi * (f0 * t + (f1 - f0) * t * t / (2 * dur))
    if kind == "tri":
        return 2.0 / math.pi * np.arcsin(np.sin(ph))
    if kind == "soft":
        return np.tanh(1.6 * np.sin(ph))
    return np.sin(ph)


# ---------------------------------------------------------------- voices

def xo_tap():
    # a soft paper tap: a filtered thump + a breath of paper noise
    dur = 0.09
    body = _tone(dur, 210, 130) * _env(int(SR * dur), a=0.002, r=0.05) * 0.7
    paper = _lowpass(_noise(dur), 0.24) * _env(int(SR * dur), a=0.001, r=0.045) * 0.5
    _save("xo_tap", body + paper, 0.62)


def _scratch(dur, f_lo, f_hi, punch=1.0):
    # the pencil: band-shaped noise whose brightness travels, plus the
    # grain of graphite catching on the tooth of the paper
    n = int(SR * dur)
    t = _t(dur)
    sweep = np.sin(2 * math.pi * (f_lo + (f_hi - f_lo) * t / dur) * t)
    grain = _lowpass(_noise(dur), 0.42) * 0.9
    scratch = (sweep * 0.22 + grain) * _env(n, a=0.003, r=dur * 0.35) * punch
    # the catch: 2-3 micro stutters in amplitude (real pencils stutter)
    for _ in range(3):
        c = RNG.uniform(0.2, 0.8)
        w = RNG.uniform(0.012, 0.03)
        m = np.ones(n)
        i0, i1 = int(c * n), min(n, int((c + w) * n))
        m[i0:i1] = np.linspace(0.25, 1.0, i1 - i0)
        scratch *= m
    return scratch


def xo_x():
    # the X: two dry scratches crossing - down-right, then up-right
    a = _scratch(0.11, 2600, 1500, 1.0)
    gap = np.zeros(int(SR * 0.035))
    b = _scratch(0.12, 1700, 2700, 0.95)
    _save("xo_x", np.concatenate([a, gap, b]), 0.72)


def xo_o():
    # the O: one round swirl - the brightness circles with the stroke
    dur = 0.24
    n = int(SR * dur)
    t = _t(dur)
    wob = 1500 + 900 * np.sin(2 * math.pi * 2.0 * t)   # around the loop
    n_i = int(SR * dur)
    sweep = np.sin(2 * math.pi * np.cumsum(wob) / SR)
    grain = _lowpass(_noise(dur), 0.38)
    swirl = (sweep * 0.2 + grain * 0.85) * _env(n_i, a=0.004, r=dur * 0.3)
    _save("xo_o", swirl, 0.66)


def xo_win():
    # the win: a rising sketch chime, three soft plucks + a sparkle
    notes = [(523.25, 0.0), (659.25, 0.09), (783.99, 0.18)]
    total = 0.75
    out = np.zeros(int(SR * total))
    for f, at in notes:
        i0 = int(SR * at)
        d = 0.32
        pluck = _tone(d, f, f * 0.995, "soft") * _env(int(SR * d), a=0.003, r=0.20)
        out[i0:i0 + pluck.size] += pluck * 0.42
    spark = _tone(0.34, 2093, 2637) * _env(int(SR * 0.34), a=0.02, r=0.26) * 0.10
    i0 = int(SR * 0.30)
    out[i0:i0 + spark.size] += spark
    _save("xo_win", out, 0.8)


def xo_lose():
    # the lose: a soft descending wah (sad pencil, not a buzzer)
    total = 0.66
    out = np.zeros(int(SR * total))
    for f, at in [(392.0, 0.0), (329.63, 0.16), (277.18, 0.32)]:
        i0 = int(SR * at)
        d = 0.30
        wah = _tone(d, f, f * 0.985, "tri") * _env(int(SR * d), a=0.006, r=0.20)
        out[i0:i0 + wah.size] += wah * 0.34
    _save("xo_lose", out, 0.7)


def xo_draw():
    # the draw: two flat notes, shrug-shaped
    total = 0.42
    out = np.zeros(int(SR * total))
    for f, at in [(440.0, 0.0), (440.0, 0.18)]:
        i0 = int(SR * at)
        d = 0.20
        n_ = _tone(d, f, "sine") if False else _tone(d, f) \
                * _env(int(SR * d), a=0.006, r=0.12)
        out[i0:i0 + n_.size] += n_ * 0.30
    _save("xo_draw", out, 0.62)


def xo_think():
    # the CPU thinking tick: a tiny pencil dot
    dur = 0.05
    dot = _lowpass(_noise(dur), 0.5) * _env(int(SR * dur), a=0.001, r=0.03)
    body = _tone(dur, 900, 700) * _env(int(SR * dur), a=0.001, r=0.03) * 0.4
    _save("xo_think", dot * 0.7 + body, 0.5)


def xo_coin():
    # the coin race: the bright pick + a sparkle tail (distinct from the
    # box-wide coin.wav so the grid coin feels special)
    body = _tone(0.16, 1318.5, 1318.5, "soft") * _env(int(SR * 0.16), a=0.002, r=0.10)
    tail = _tone(0.30, 1975.5, 2349.3) * _env(int(SR * 0.30), a=0.02, r=0.22) * 0.35
    out = np.zeros(int(SR * 0.42))
    out[:body.size] += body * 0.5
    i0 = int(SR * 0.09)
    out[i0:i0 + tail.size] += tail
    _save("xo_coin", out, 0.62)


if __name__ == "__main__":
    xo_tap()
    xo_x()
    xo_o()
    xo_win()
    xo_lose()
    xo_draw()
    xo_think()
    xo_coin()
    print("v0.2.8 XO voices done")
