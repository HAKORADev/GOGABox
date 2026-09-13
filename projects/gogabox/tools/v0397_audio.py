#!/usr/bin/env python3
"""v0397_audio.py - BRICK BREAKER (v0.3.9-7) gap-filler audio.

THE OWNER'S PACK carries the core voices (vendored verbatim, renamed):
  bb_brickhit / bb_break / bb_bathit / bb_wall / bb_pow_spawn / bb_pow /
  bb_serve / bb_click (assets/audio/sfx, from the owner's Drive zip) and
  bb_theme / bb_menu (assets/audio/music).

THE GAPS this script fills - the voices the pack does not ship, 100%
synthesized, the house way (nothing sampled, nothing scraped):

BRICK BREAKER (assets/audio/sfx/bb_*.wav):
  metal   the metal ball's hit tone - a dense clang, a DIFFERENT tone
          than the pack's brick hit (the owner: "make metal hit different
          sound tone")
  fire    the fire ball's burn - a low whoosh crackle (pass-through)
  ice     the frozen layer cracking - glassy shatter burst
  heart   the 1000th brick point - one more heart rises (bright pair)
  clear   the level wipe - a short rising arpeggio (not the run-end win)
  tick    the timer's last 10 seconds - the dry tick
  lose    the last ball gone - the descending wah (a heart leaves)

Re-derive: python3 tools/v0397_audio.py
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


def sine(f, dur, ph=0.0):
    return np.sin(2 * np.pi * f * t_axis(dur) + ph)


def sweep(f0, f1, dur):
    t = t_axis(dur)
    fr = np.linspace(f0, f1, t.size)
    ph = 2 * np.pi * np.cumsum(fr) / SR
    return np.sin(ph)


def noise(dur):
    return np.random.default_rng(97).uniform(-1, 1, int(SR * dur))


def lowpass(x, alpha):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


# ------------------------------------------------------------ the seven
def metal():
    # dense clang: inharmonic partials (the metal family), fast decay
    dur = 0.30
    t = t_axis(dur)
    x = np.zeros_like(t)
    for f, a in [(523.0, 1.0), (1042.0, 0.72), (1583.0, 0.5), (2451.0, 0.34),
                 (3729.0, 0.22), (5210.0, 0.12)]:
        x += a * np.sin(2 * np.pi * f * t + f % 3) * np.exp(-t * (9 + f / 700))
    x += 0.30 * lowpass(noise(dur), 0.42) * np.exp(-t * 42)
    x *= env(t.size, 0.002, 0.10)
    return x * 0.52


def fire():
    # low whoosh + crackle tails (the pass-through burn)
    dur = 0.52
    t = t_axis(dur)
    base = sweep(210.0, 70.0, dur) * 0.6
    crack = lowpass(noise(dur), 0.24)
    crack *= (1.0 + 0.6 * np.sin(2 * np.pi * 13.0 * t))
    x = base + 0.8 * crack * np.exp(-t * 5.2)
    x *= env(t.size, 0.012, 0.30)
    return x * 0.60


def ice():
    # glassy shatter: bright band noise + crystalline pings
    dur = 0.34
    t = t_axis(dur)
    x = lowpass(noise(dur), 0.85) * np.exp(-t * 22) * 0.7
    for i, f in enumerate([2814.0, 3729.0, 4649.0, 5980.0]):
        st = 0.02 + i * 0.035
        tt = np.clip(t - st, 0, None)
        x += 0.34 * np.sin(2 * np.pi * f * tt) * np.exp(-tt * 26) \
                * (t >= st)
    x *= env(t.size, 0.001, 0.12)
    return x * 0.55


def heart():
    # the bright rising pair (one more heart)
    a = sine(660.0, 0.09) * env(int(SR * 0.09), 0.004, 0.03)
    b = sine(990.0, 0.16) * env(int(SR * 0.16), 0.004, 0.10)
    b2 = sine(1320.0, 0.16) * 0.4 * env(int(SR * 0.16), 0.004, 0.10)
    gap = np.zeros(int(SR * 0.045))
    return np.concatenate([a, gap, b + b2]) * 0.5


def clear():
    # the level wipe: a short rising arpeggio, warm square-ish
    notes = [523.0, 659.0, 784.0, 1046.0]
    segs = []
    for i, f in enumerate(notes):
        dur = 0.09 if i < 3 else 0.30
        n = int(SR * dur)
        x = np.sign(np.sin(2 * np.pi * f * t_axis(dur))) * 0.5 \
                + 0.5 * sine(f, dur)
        x *= env(n, 0.004, dur * 0.6)
        segs.append(x * (0.8 + 0.05 * i))
        if i < 3:
            segs.append(np.zeros(int(SR * 0.012)))
    return np.concatenate(segs) * 0.42


def tick():
    # the dry clock tick
    dur = 0.06
    t = t_axis(dur)
    x = sine(1180.0, dur) * np.exp(-t * 90) \
            + 0.3 * lowpass(noise(dur), 0.5) * np.exp(-t * 120)
    return x * 0.4


def lose():
    # the descending wah (a heart leaves the board)
    dur = 0.62
    x = sweep(420.0, 130.0, dur)
    x *= 1.0 + 0.22 * np.sin(2 * np.pi * 9.0 * t_axis(dur))
    x *= env(int(SR * dur), 0.01, 0.34)
    return x * 0.55


if __name__ == "__main__":
    os.makedirs(SFX_DIR, exist_ok=True)
    print("brick breaker gap sfx:")
    write_wav(f"{SFX_DIR}/bb_metal.wav", metal())
    write_wav(f"{SFX_DIR}/bb_fire.wav", fire())
    write_wav(f"{SFX_DIR}/bb_ice.wav", ice())
    write_wav(f"{SFX_DIR}/bb_heart.wav", heart())
    write_wav(f"{SFX_DIR}/bb_clear.wav", clear())
    write_wav(f"{SFX_DIR}/bb_tick.wav", tick())
    write_wav(f"{SFX_DIR}/bb_lose.wav", lose())
    print("done")
