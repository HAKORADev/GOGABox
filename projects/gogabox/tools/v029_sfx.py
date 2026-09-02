#!/usr/bin/env python3
"""v0.2.9 audio - the XO voices REDESIGNED (the owner: "the SFX does not
match the visual design... they were not that accurate for this current
design"). The v0.2.8 set was dry scratchy pencil noise - it fought the
clean cozy sketchbook look. The new set is the sketchbook itself: soft
warm wood/marimba plucks, a whisper of paper (never a hiss), gentle
melodies. Same names, new voices - the game code does not change.

xo_tap    a soft woody tick (cells, buttons)
xo_x      two soft warm plucks (the cross strokes)
xo_o      one round marimba bloop
xo_win    a gentle rising four-pluck melody
xo_lose   a mellow two-note sigh
xo_draw   two neutral same-note blips
xo_think  a tiny soft tick while the CPU thinks
xo_coin   a bright-but-soft pick + a sparkle tail

Design law: every voice has a body, an edge and a tail; bodies are warm
sines/triangles, noise is low-passed and quiet. Re-runnable: same code ->
same bytes."""

import math
import os
import wave

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(PROJ, "assets", "audio", "sfx")
SR = 44100

import numpy as np  # noqa: E402

RNG = np.random.default_rng(2909)


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


def _env(n, a=0.004, r=0.10, curve=1.0):
    e = np.ones(n)
    na, nr = int(SR * a), int(SR * r)
    na, nr = min(na, n), min(nr, n)
    if na > 0:
        e[:na] = np.linspace(0, 1, na)
    if nr > 0:
        e[-nr:] *= np.linspace(1, 0, nr) ** curve
    return e


def _lowpass(x, alpha):
    y = np.empty_like(x)
    acc = 0.0
    for i in range(x.size):
        acc += alpha * (x[i] - acc)
        y[i] = acc
    return y


def _pluck(f0, f1, dur, vol=1.0, warm=0.35):
    """a soft mallet pluck: a warm sine body + a touch of 2nd harmonic,
    quick attack, exponential-ish tail."""
    t = _t(dur)
    ph = 2 * math.pi * (f0 * t + (f1 - f0) * t * t / (2 * dur))
    body = np.sin(ph) + warm * np.sin(2 * ph)
    e = np.exp(-t * 9.0)
    e *= _env(t.size, a=0.003, r=min(0.08, dur * 0.4))
    return body * e * vol


def _paper_whisper(dur, vol=0.06):
    """the pencil's breath: quiet low-passed noise, NOT a hiss"""
    n = _noise(dur)
    return _lowpass(n, 0.18) * _env(n.size, a=0.004, r=dur * 0.5) * vol


def _noise(dur):
    return RNG.uniform(-1.0, 1.0, int(SR * dur))


# ---------------------------------------------------------------- voices

def xo_tap():
    dur = 0.07
    t = _t(dur)
    body = np.sin(2 * math.pi * (430 * t - 90 * t * t / (2 * dur)))
    out = body * np.exp(-t * 34.0) * _env(t.size, a=0.002, r=0.02)
    _save("xo_tap", out + _paper_whisper(dur, 0.10), 0.55)


def xo_x():
    # the two cross strokes: two warm plucks, the second a step lower
    a = _pluck(640, 600, 0.16, 0.8) + _paper_whisper(0.16, 0.35)
    gap = np.zeros(int(SR * 0.045))
    b = _pluck(540, 505, 0.18, 0.8) + _paper_whisper(0.18, 0.30)
    _save("xo_x", np.concatenate([a, gap, b]), 0.66)


def xo_o():
    # the ring: one round bloop with a little upward bend (the hand loops)
    out = _pluck(375, 405, 0.26, 0.95, warm=0.25) + _paper_whisper(0.26, 0.30)
    _save("xo_o", out, 0.68)


def xo_win():
    # the win: a gentle rising melody, soft mallet, never shrill
    notes = [(523.25, 0.0), (659.25, 0.11), (783.99, 0.22), (1046.5, 0.33)]
    total = 0.95
    out = np.zeros(int(SR * total))
    for f, at in notes:
        i0 = int(SR * at)
        d = 0.34
        pluck = _pluck(f, f * 0.997, d, 0.62, warm=0.3)
        out[i0:i0 + pluck.size] += pluck
    _save("xo_win", out, 0.78)


def xo_lose():
    # the lose: a mellow sigh - two warm notes leaning down
    notes = [(440.0, 0.0), (329.63, 0.17)]
    total = 0.75
    out = np.zeros(int(SR * total))
    for f, at in notes:
        i0 = int(SR * at)
        d = 0.45
        pluck = _pluck(f, f * 0.99, d, 0.6, warm=0.45)
        out[i0:i0 + pluck.size] += pluck
    _save("xo_lose", out, 0.66)


def xo_draw():
    # the draw: two neutral same-note blips, a shrug
    total = 0.42
    out = np.zeros(int(SR * total))
    for at in [0.0, 0.17]:
        i0 = int(SR * at)
        pluck = _pluck(440, 440, 0.2, 0.55)
        out[i0:i0 + pluck.size] += pluck
    _save("xo_draw", out, 0.6)


def xo_think():
    dur = 0.045
    t = _t(dur)
    body = np.sin(2 * math.pi * 880 * t) * np.exp(-t * 60.0)
    _save("xo_think", body * _env(t.size, a=0.002, r=0.02), 0.34)


def xo_coin():
    # the coin race: a bright but soft pick + a little sparkle
    body = _pluck(1318.5, 1318.5, 0.2, 0.5, warm=0.2)
    tail = _pluck(1975.5, 2093.0, 0.3, 0.3, warm=0.15)
    out = np.zeros(int(SR * 0.45))
    out[:body.size] += body
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
    print("v0.2.9 XO voices redesigned")
