#!/usr/bin/env python3
"""v038_maze_fix.py - MAZE ESCAPER v0.3.8 audio fix.

THE OWNER: "in maze escaper, i realized the solved maze SFX is same as end
game, make another SFX for this instead". The old m_win (a 3-note bell
rise, 784/988/1319) wore the same shape as the box's own end-of-run jingle
(jingles/win.ogg) - every map solved sounded like the run ended.

m_solve is a NEW TIMBRE for the map escape: a portal-warp - an upward
frequency glissando with a shimmering fifth stack and a soft noise swoosh,
landing on a glassy high bell. Nothing bell-triad about it; the run-end
jingle keeps its meaning.

m_win.wav is REMOVED (0 refs after this change).

Re-derive: python3 tools/v038_maze_fix.py
"""
import numpy as np
import os
import wave

SR = 44100
SFX_DIR = "projects/gogabox/assets/audio/sfx"


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


def sweep(f0, f1, dur, wave_shape="sine"):
    t = t_axis(dur)
    freqs = np.linspace(f0, f1, len(t))
    phase = 2 * np.pi * np.cumsum(freqs) / SR
    if wave_shape == "saw":
        return 2 * ((phase / (2 * np.pi)) % 1.0) - 1
    if wave_shape == "square":
        return np.sign(np.sin(phase))
    return np.sin(phase)


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


def sfx_solve():
    """THE PORTAL WARP: 0.9s. A rising gliss (220 -> 880, glass sine +
    a fifth above) with a soft filtered swoosh under it, resolving on a
    high glassy bell (1760) with a slow shimmer tail. NOT a triad rise -
    a continuous warp."""
    d = 0.95
    buf = np.zeros(int(SR * d))
    # the gliss: sine + fifth, rising together
    g = sweep(220, 880, 0.62)
    g5 = sweep(330, 1320, 0.62)
    both = g * 0.5 + g5 * 0.22
    both *= env(int(SR * 0.62), 0.012, 0.16)
    place(buf, 0.0, both, 0.42)
    # the swoosh: band-limited noise swelling then vanishing
    sw = lowpass(noise(0.55), 0.12) * env(int(SR * 0.55), 0.30, 0.22)
    place(buf, 0.03, sw, 0.35)
    # the landing bell: one high glass note with a slow decay
    t = t_axis(0.42)
    bell = (np.sin(2 * np.pi * 1760 * t) * 0.6
            + np.sin(2 * np.pi * 1760 * 2.01 * t) * 0.18) \
        * np.exp(-t * 6.5)
    place(buf, 0.52, bell, 0.5)
    # the shimmer: tiny descending sparkle after the bell
    for i in range(4):
        f = 2200.0 - 180.0 * i
        tt = t_axis(0.10)
        sp = np.sin(2 * np.pi * f * tt) * np.exp(-tt * 30.0)
        place(buf, 0.66 + i * 0.06, sp, 0.16)
    return buf * 0.9


def main():
    print("v038_maze_fix: the portal-warp solve sound")
    write_wav(os.path.join(SFX_DIR, "m_solve.wav"), sfx_solve())
    old = os.path.join(SFX_DIR, "m_win.wav")
    if os.path.exists(old):
        os.remove(old)
        imp = old + ".import"
        if os.path.exists(imp):
            os.remove(imp)
        print("  m_win.wav REMOVED (+ .import)")
    print("done")


if __name__ == "__main__":
    main()
