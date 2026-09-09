#!/usr/bin/env python3
"""v038_domino_chess_sfx.py - DOMINO + CHECKMATE (v0.3.8) audio.
100% synthesized - nothing from the studied APKs ships (THE USAGE LAW).

Study notes (what the real games sound like, what we rebuild differently):
  chess.com's set: move 0.26s / capture 0.19s / castle 0.37s / check 0.44s -
  short wooden knocks. We synthesize our own knock family (band-passed
  noise + a low thump), a different species: warmer, softer, ours.
  Loop Games' Dominoes: plastic clacks. Ours: a two-stage CLACK (noise
  burst + 170Hz body) - chunkier, real-table feel.

DOMINO (assets/audio/sfx/d_*.wav):
  pick    the tile lifts off the table (soft tick up)
  place   THE CLACK (the whole game lives on this one)
  flip    the flick when a tile flips to match its end
  draw    the boneyard slide
  pass    the dull thud (no move, you pass)
  blocked the blocked verdict (double thud, neutral)
  coin    the GOGACoin ding (two-note shimmer)
  win     the round rise (warm major)
  lose    the round fall (minor two-tone)

CHECKMATE (assets/audio/sfx/c_*.wav):
  select  the tiny tick when a piece lifts
  move    the wood knock
  capture the harder crack
  castle  the double knock
  check   the alert sting
  mate    the low boom + falling three
  promote the pawn's rise
  illegal the dull buzz
  coin    the GOGACoin ding (deeper pair)
  win     the formal rise
  lose    the formal fall
  draw    the neutral settle

Re-derive: python3 tools/v038_domino_chess_sfx.py
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
    """the GOGABox knock: a band-passed noise crack fused to a low body
    thump - wood, not plastic."""
    n = highpass(lowpass(noise(dur), 0.35), 0.08)
    crack = n * env(int(SR * dur), 0.001, dur * 0.85)
    body = sine(f_body, dur) * env(int(SR * dur), 0.001, dur * 0.7)
    return (crack * 0.75 + body * 0.9) * punch


def sfx_pick():
    d = 0.11
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, sine(520, 0.05) * env(int(SR * 0.05), 0.002, 0.03), 0.30)
    place(buf, 0.035, sine(740, 0.06) * env(int(SR * 0.06), 0.002, 0.04), 0.22)
    return buf


def sfx_place():
    d = 0.20
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, knock(170, 0.09), 0.95)
    place(buf, 0.055, knock(120, 0.11, 0.6), 0.55)
    return buf


def sfx_flip():
    d = 0.14
    buf = np.zeros(int(SR * d))
    n = highpass(lowpass(noise(0.08), 0.5), 0.2)
    place(buf, 0.0, n * env(int(SR * 0.08), 0.001, 0.06), 0.4)
    place(buf, 0.03, sine(300, 0.08) * env(int(SR * 0.08), 0.001, 0.06), 0.28)
    return buf


def sfx_draw():
    d = 0.22
    buf = np.zeros(int(SR * d))
    sw = lowpass(noise(0.18), 0.18) * env(int(SR * 0.18), 0.03, 0.10)
    place(buf, 0.0, sw, 0.5)
    place(buf, 0.15, knock(150, 0.06, 0.5), 0.35)
    return buf


def sfx_pass():
    d = 0.24
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, sine(110, 0.16) * env(int(SR * 0.16), 0.004, 0.12), 0.6)
    place(buf, 0.0, lowpass(noise(0.1), 0.1) * env(int(SR * 0.1), 0.002, 0.08), 0.3)
    return buf


def sfx_blocked():
    d = 0.42
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, knock(130, 0.1, 0.7), 0.6)
    place(buf, 0.18, knock(110, 0.12, 0.7), 0.6)
    return buf


def sfx_coin():
    d = 0.5
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, bell(1318, 0.3, decay=9.0), 0.5)
    place(buf, 0.10, bell(1976, 0.34, decay=8.0), 0.45)
    place(buf, 0.20, bell(2637, 0.26, decay=10.0), 0.28)
    return buf


def sfx_win():
    d = 0.85
    buf = np.zeros(int(SR * d))
    for i, f in enumerate([523, 659, 784, 1046]):
        place(buf, i * 0.10, bell(f, 0.42, decay=6.0), 0.42)
    place(buf, 0.40, bell(1568, 0.44, decay=5.0), 0.30)
    return buf


def sfx_lose():
    d = 0.7
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, bell(392, 0.34, decay=6.5), 0.45)
    place(buf, 0.18, bell(311, 0.42, decay=5.5), 0.45)
    place(buf, 0.18, sine(155, 0.4) * env(int(SR * 0.4), 0.01, 0.3), 0.22)
    return buf


def sfx_select():
    d = 0.07
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, sine(660, 0.045) * env(int(SR * 0.045), 0.002, 0.03), 0.26)
    return buf


def sfx_move():
    d = 0.12
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, knock(240, 0.09, 0.8), 0.8)
    return buf


def sfx_capture():
    d = 0.2
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, knock(260, 0.07, 0.9), 0.8)
    place(buf, 0.05, knock(150, 0.12, 1.0), 0.75)
    return buf


def sfx_castle():
    d = 0.42
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, knock(240, 0.08, 0.8), 0.7)
    place(buf, 0.17, knock(210, 0.09, 0.8), 0.68)
    return buf


def sfx_check():
    d = 0.38
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, bell(880, 0.16, decay=10.0), 0.42)
    place(buf, 0.10, bell(1174, 0.26, decay=8.0), 0.40)
    place(buf, 0.10, sine(587, 0.2) * env(int(SR * 0.2), 0.004, 0.14), 0.16)
    return buf


def sfx_mate():
    d = 1.0
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, sine(80, 0.5) * env(int(SR * 0.5), 0.004, 0.4), 0.6)
    place(buf, 0.0, knock(100, 0.16, 1.1), 0.7)
    for i, f in enumerate([523, 415, 311]):
        place(buf, 0.28 + i * 0.16, bell(f, 0.4, decay=6.0), 0.4)
    return buf


def sfx_promote():
    d = 0.5
    buf = np.zeros(int(SR * d))
    for i, f in enumerate([523, 784, 1046, 1568]):
        place(buf, i * 0.075, bell(f, 0.26, decay=9.0), 0.36)
    return buf


def sfx_illegal():
    d = 0.14
    buf = np.zeros(int(SR * d))
    b = (np.sign(np.sin(2 * np.pi * 140 * t_axis(0.12)))
         * 0.5 + np.sign(np.sin(2 * np.pi * 141 * t_axis(0.12))) * 0.5)
    place(buf, 0.0, b * env(int(SR * 0.12), 0.004, 0.05), 0.2)
    return buf


def sfx_drawgame():
    d = 0.6
    buf = np.zeros(int(SR * d))
    place(buf, 0.0, bell(494, 0.3, decay=6.0), 0.36)
    place(buf, 0.16, bell(494, 0.36, decay=5.0), 0.34)
    return buf


def main():
    print("v038_domino_chess_sfx: two games of table voices")
    for name, fn in [
            ("d_pick", sfx_pick), ("d_place", sfx_place), ("d_flip", sfx_flip),
            ("d_draw", sfx_draw), ("d_pass", sfx_pass), ("d_blocked", sfx_blocked),
            ("d_coin", sfx_coin), ("d_win", sfx_win), ("d_lose", sfx_lose),
            ("c_select", sfx_select), ("c_move", sfx_move),
            ("c_capture", sfx_capture), ("c_castle", sfx_castle),
            ("c_check", sfx_check), ("c_mate", sfx_mate),
            ("c_promote", sfx_promote), ("c_illegal", sfx_illegal),
            ("c_coin", sfx_coin), ("c_win", sfx_win), ("c_lose", sfx_lose),
            ("c_draw", sfx_drawgame),
    ]:
        write_wav(os.path.join(SFX_DIR, name + ".wav"), fn())
    print("done")


if __name__ == "__main__":
    main()
