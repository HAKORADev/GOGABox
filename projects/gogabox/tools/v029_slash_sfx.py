#!/usr/bin/env python3
"""v0.2.9 audio - the FRUIT SLASHER voices (the owner: "different SFXs to
match the juiciness").

sl_whoosh  the blade swipe (bright, short)
sl_cut_a   wet snap cut (variant 1)
sl_cut_b   low squishy cut (variant 2)
sl_cut_c   crisp bright cut (variant 3)
sl_bomb    the bomb boom (sub + burst)
sl_heart   a heart is lost (thud + sad blip)
sl_miss    a fruit fell (-2) - a soft sad plop
sl_coin_s  the GOGACoin slashed - bright pick + sparkle
sl_launch  the quiet throw whoosh
sl_over    the run is over (hearts gone)

Design law: bodies + edges + tails; wet cuts carry a noise splash plus a
pitch-dropping body. Re-runnable: same code -> same bytes."""

import math
import os
import wave

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(PROJ, "assets", "audio", "sfx")
SR = 44100

import numpy as np  # noqa: E402

RNG = np.random.default_rng(290929)


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


def _noise(dur):
    return RNG.uniform(-1.0, 1.0, int(SR * dur))


def _sweep(dur, f0, f1, kind="sine"):
    t = _t(dur)
    ph = 2 * math.pi * (f0 * t + (f1 - f0) * t * t / (2 * dur))
    if kind == "tri":
        return 2.0 / math.pi * np.arcsin(np.sin(ph))
    return np.sin(ph)


def _pluck(f0, f1, dur, vol=1.0, warm=0.3):
    t = _t(dur)
    ph = 2 * math.pi * (f0 * t + (f1 - f0) * t * t / (2 * dur))
    body = np.sin(ph) + warm * np.sin(2 * ph)
    return body * np.exp(-t * 9.0) * _env(t.size, a=0.003, r=min(0.08, dur * 0.4)) * vol


# ---------------------------------------------------------------- voices

def sl_whoosh():
    dur = 0.16
    n = int(SR * dur)
    body = _lowpass(_noise(dur), 0.35)
    # the brightness swells then fades (the blade passing)
    swell = np.sin(np.pi * _t(dur) / dur) ** 1.6
    tone = _sweep(dur, 300, 900) * 0.12
    _save("sl_whoosh", (body * swell + tone * swell) * _env(n, a=0.004, r=0.06), 0.5)


def _wet_cut(drop_f0, drop_f1, noise_lp, splash=0.5, dur=0.22):
    n = int(SR * dur)
    t = _t(dur)
    body = _sweep(dur, drop_f0, drop_f1) * np.exp(-t * 16.0)
    splash_n = _lowpass(_noise(dur), noise_lp) * _env(n, a=0.001, r=dur * 0.6)
    # the wet drops: 2-3 tiny pitch blips after the cut
    drops = np.zeros(n)
    for k, at in enumerate([0.05, 0.09, 0.14][:2 + (k := 0) or 2]):
        i0 = int(SR * at)
        if i0 + int(SR * 0.05) < n:
            blip = _sweep(0.05, 700 - k * 160, 300 - k * 60) \
                    * np.exp(-_t(0.05) * 40.0)
            drops[i0:i0 + blip.size] += blip * 0.2
    return body * 0.8 + splash_n * splash + drops


def sl_cut_a():
    _save("sl_cut_a", _wet_cut(340, 130, 0.5, 0.55), 0.62)


def sl_cut_b():
    _save("sl_cut_b", _wet_cut(260, 90, 0.3, 0.7, 0.26), 0.66)


def sl_cut_c():
    _save("sl_cut_c", _wet_cut(520, 210, 0.62, 0.45, 0.18), 0.58)


def sl_bomb():
    dur = 0.85
    t = _t(dur)
    sub = _sweep(dur, 120, 34) * np.exp(-t * 6.0)
    burst = _lowpass(_noise(dur), 0.4) * np.exp(-t * 9.0)
    crack = _noise(dur) * np.exp(-t * 30.0) * 0.4
    _save("sl_bomb", (sub * 0.9 + burst * 0.8 + crack) * _env(int(SR * dur),
            a=0.002, r=0.3), 0.9)


def sl_heart():
    dur = 0.6
    out = np.zeros(int(SR * dur))
    # the heartbeat: two thuds
    for at, f in [(0.0, 70.0), (0.16, 58.0)]:
        i0 = int(SR * at)
        d = 0.14
        t = _t(d)
        thud = _sweep(d, f, f * 0.6) * np.exp(-t * 22.0)
        out[i0:i0 + thud.size] += thud * 0.9
    # the sad blip
    i0 = int(SR * 0.3)
    blip = _pluck(392, 311, 0.26, 0.5, warm=0.4)
    out[i0:i0 + blip.size] += blip
    _save("sl_heart", out, 0.72)


def sl_miss():
    dur = 0.28
    t = _t(dur)
    body = _sweep(dur, 240, 110) * np.exp(-t * 12.0)
    soft = _lowpass(_noise(dur), 0.2) * _env(int(SR * dur), a=0.01, r=0.14) * 0.2
    _save("sl_miss", body * 0.6 + soft, 0.5)


def sl_coin_s():
    body = _pluck(1318.5, 1318.5, 0.2, 0.5, warm=0.2)
    tail = _pluck(1975.5, 2093.0, 0.3, 0.3, warm=0.15)
    out = np.zeros(int(SR * 0.45))
    out[:body.size] += body
    i0 = int(SR * 0.09)
    out[i0:i0 + tail.size] += tail
    _save("sl_coin_s", out, 0.62)


def sl_launch():
    dur = 0.12
    n = int(SR * dur)
    body = _lowpass(_noise(dur), 0.22)
    _save("sl_launch", body * _env(n, a=0.01, r=0.07) * 0.5, 0.3)


def sl_over():
    dur = 1.0
    out = np.zeros(int(SR * dur))
    for f, at in [(392.0, 0.0), (329.63, 0.18), (261.63, 0.36)]:
        i0 = int(SR * at)
        pluck = _pluck(f, f * 0.99, 0.5, 0.5, warm=0.45)
        out[i0:i0 + pluck.size] += pluck
    _save("sl_over", out, 0.7)


if __name__ == "__main__":
    sl_whoosh()
    sl_cut_a()
    sl_cut_b()
    sl_cut_c()
    sl_bomb()
    sl_heart()
    sl_miss()
    sl_coin_s()
    sl_launch()
    sl_over()
    print("v0.2.9 slasher voices done")
