#!/usr/bin/env python3
"""v040-10 sfx round:
   - THREE new place beds for deadly worm (city / jungle / kingdom) -
     the music law: every place sings its own loop (the desert + ice
     beds shipped in v040-9)
   - a new rb_start for rock breaker (the owner: "the start SFX is
     annoying and bad, make a better one") - a two-tone ready chirp
"""
import os
import numpy as np
import wave

SR = 44100
PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(PROJ, "assets", "audio", "sfx")


def log(m):
    print(m, flush=True)


def write_wav(path, data, sr=SR):
    d = np.clip(data, -1.0, 1.0)
    pcm = (d * 32767.0).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())
    log(f"wrote {os.path.basename(path)} ({len(data)/sr:.1f}s)")


def env(n, a, r):
    e = np.ones(n)
    an = max(1, int(a * SR))
    rn = max(1, int(r * SR))
    e[:an] = np.linspace(0, 1, an)
    e[-rn:] = np.linspace(1, 0, rn)
    return e


def osc(freq, n, kind="sine", detune=0.0):
    t = np.arange(n) / SR
    ph = 2 * np.pi * freq * t
    if detune > 0:
        ph = ph + detune * np.sin(2 * np.pi * 0.7 * t)
    if kind == "sine":
        return np.sin(ph)
    if kind == "tri":
        return 2 * np.abs(2 * ((freq * t) % 1.0) - 1) - 1
    if kind == "saw":
        return 2 * ((freq * t) % 1.0) - 1
    return np.sin(ph)


def looper(bars, bpm, root, minor=True):
    """a gentle place bed: a soft pad progression + a sub pulse."""
    beat = 60.0 / bpm
    n = int(bars * 4 * beat * SR)
    out = np.zeros(n)
    scale = [0, 3, 5, 7, 10] if minor else [0, 2, 4, 7, 9]
    prog = [0, 5, 3, 4]  # degrees into the scale
    for bar in range(bars):
        deg = prog[bar % len(prog)]
        f = root * (2 ** (scale[deg % 5] / 12.0))
        s0 = int(bar * 4 * beat * SR)
        dur = 4 * beat
        nn = int(dur * SR)
        e = env(nn, 0.8, 1.2)
        tone = (osc(f / 2, nn, "tri", 0.15) * 0.4
                + osc(f, nn, "sine", 0.1) * 0.3
                + osc(f * 1.5, nn, "sine") * 0.12)
        out[s0:s0 + nn] += tone * e * 0.5
        # the sub pulse rides the beat
        for b in range(4):
            p0 = s0 + int(b * beat * SR)
            pn = int(beat * 0.9 * SR)
            out[p0:p0 + pn] += osc(f / 4, pn, "sine") \
                * env(pn, 0.01, 0.25) * 0.35
    # a soft airy shimmer on top
    t = np.arange(n) / SR
    out += np.sin(2 * np.pi * root * 4 * t) * 0.02 \
        * (0.5 + 0.5 * np.sin(2 * np.pi * 0.13 * t))
    return out * env(n, 1.0, 1.0) * 0.9


def main():
    # ---- the three new place beds (each ~24s seamless at 84 bpm) ----
    write_wav(os.path.join(SFX, "dw_music_city.wav"),
              looper(8, 84, 146.8, minor=True) * 0.8)      # D3 - steel hum
    write_wav(os.path.join(SFX, "dw_music_jungle.wav"),
              looper(8, 92, 130.8, minor=True) * 0.8)      # C3 - dense green
    write_wav(os.path.join(SFX, "dw_music_kingdom.wav"),
              looper(8, 76, 110.0, minor=True) * 0.8)      # A2 - war dusk
    # ---- the new rock breaker start: a rising two-tone ready chirp ----
    n1 = int(0.09 * SR)
    n2 = int(0.16 * SR)
    a = osc(523.25, n1, "tri") * env(n1, 0.005, 0.03)      # C5
    b = osc(784.0, n2, "tri") * env(n2, 0.005, 0.10)       # G5
    c = osc(1046.5, int(0.22 * SR), "sine") \
        * env(int(0.22 * SR), 0.005, 0.18) * 0.7           # C6 sparkle
    s = np.concatenate([a * 0.5, b * 0.55, c])
    write_wav(os.path.join(SFX, "rb_start.wav"), s * 0.9)


if __name__ == "__main__":
    main()
