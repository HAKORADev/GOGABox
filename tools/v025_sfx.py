#!/usr/bin/env python3
"""
v0.2.5 - SNOWY TOWER audio (tools/v025_sfx.py).

Designs every Snowy Tower SFX as pure math (no samples, no randomness that
is not seeded) and writes them into the project:

  projects/gogabox/assets/audio/sfx/tower_*.wav   (8 SFX)
  projects/gogabox/assets/audio/music/tower_theme.wav  (a 32s loop)

The sound law from the v0.2.4 round holds: SFX are the cheapest thing that
makes a game feel expensive. Winter palette: soft thumps, crunchy noise,
music-box plucks - nothing harsh.

Run:  python3 tools/v025_sfx.py
"""
import math
import os
import struct
import wave

SR = 44100
SFX_DIR = os.path.join(os.path.dirname(__file__), "..", "projects", "gogabox",
                       "assets", "audio", "sfx")
MUS_DIR = os.path.join(os.path.dirname(__file__), "..", "projects", "gogabox",
                       "assets", "audio", "music")


def write_wav(path: str, samples: list, loop: bool = False) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(s * 32767))))
            for s in samples)
        w.writeframes(frames)
    print("wrote %s (%.2fs)" % (os.path.relpath(path), len(samples) / SR))


def env(t: float, a: float, d: float) -> float:
    """attack/decay envelope, t in seconds"""
    if t < a:
        return t / a
    return max(0.0, 1.0 - (t - a) / d)


def lowpass(samples: list, alpha: float) -> list:
    out = []
    acc = 0.0
    for s in samples:
        acc += alpha * (s - acc)
        out.append(acc)
    return out


def silence(dur: float) -> list:
    return [0.0] * int(SR * dur)


def mix(*layers) -> list:
    n = max(len(l) for l in layers)
    out = [0.0] * n
    for l in layers:
        for i, s in enumerate(l):
            out[i] += s
    return out


def gain(samples: list, g: float) -> list:
    return [s * g for s in samples]


def concat(*parts) -> list:
    out = []
    for p in parts:
        out.extend(p)
    return out


def tone(freq: float, dur: float, vol: float, a: float = 0.004,
         wave_fn: str = "sine", slide: float = 1.0) -> list:
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        f = freq * (slide ** (t / dur)) if slide != 1.0 else freq
        if wave_fn == "sine":
            s = math.sin(2 * math.pi * f * t)
        elif wave_fn == "tri":
            s = 2.0 / math.pi * math.asin(math.sin(2 * math.pi * f * t))
        else:
            s = 1.0 if math.sin(2 * math.pi * f * t) > 0 else -1.0
        out.append(s * vol * env(t, a, dur))
    return out


def noise(dur: float, vol: float, a: float = 0.001, lp: float = 0.35,
          seed: int = 7) -> list:
    state = seed
    raw = []
    for i in range(int(SR * dur)):
        state = (state * 1103515245 + 12345) & 0x7FFFFFFF
        raw.append((state / 0x3FFFFFFF - 1.0) * vol * env(i / SR, a, dur))
    return lowpass(raw, lp)


# ------------------------------------------------------------- the eight SFX

def sfx_jump() -> list:
    """the jump: a soft pow - low thump + a puff of snow"""
    return mix(
        gain(tone(300, 0.16, 0.5, slide=0.55), 0.8),
        gain(noise(0.10, 0.20, lp=0.22), 0.9),
    )


def sfx_land() -> list:
    """the landing: snow crunch - filtered noise + a tiny bounce note"""
    return mix(
        gain(noise(0.14, 0.55, lp=0.18, seed=11), 1.0),
        gain(tone(190, 0.10, 0.25, slide=0.8), 0.7),
        gain(noise(0.05, 0.30, lp=0.6, seed=3), 0.5),
    )


def sfx_coin() -> list:
    """the coin: bright music-box two-tone (E6 -> B6)"""
    return concat(
        gain(tone(1318.5, 0.07, 0.42), 1.0),
        gain(tone(1975.5, 0.16, 0.42), 1.0),
    )


def sfx_pw() -> list:
    """the powerup: a rising sparkle arpeggio (C6 E6 G6 C7)"""
    step = int(SR * 0.07)
    out = []
    for i, f in enumerate([1046.5, 1318.5, 1568.0, 2093.0]):
        seg = gain(tone(f, 0.14, 0.34), 1.0 - i * 0.08)
        pad = silence(0.07)
        out.extend(pad if i < 3 else [])
        out.extend(seg if i == 0 else [])
        if i > 0:
            out = out + seg
    # rebuild cleanly (the above overlaps are fiddly) - simple version:
    out = []
    for i, f in enumerate([1046.5, 1318.5, 1568.0, 2093.0]):
        out.extend(silence(0.062))
        out.extend(gain(tone(f, 0.16, 0.36), 1.0 - i * 0.06))
    out.extend(gain(tone(2093.0, 0.18, 0.30), 0.9))
    return out


def sfx_pw_end() -> list:
    """the powerup fades: two soft notes down (G5 -> C5)"""
    return concat(
        gain(tone(784.0, 0.10, 0.30), 1.0),
        gain(tone(523.25, 0.20, 0.30, slide=0.92), 1.0),
    )


def sfx_wall() -> list:
    """the wall: a soft icy thud"""
    return mix(
        gain(tone(150, 0.12, 0.5, slide=0.7), 0.9),
        gain(noise(0.06, 0.22, lp=0.25, seed=23), 0.8),
    )


def sfx_crack() -> list:
    """the vanish platform: three little ice cracks"""
    out = []
    for i in range(3):
        out.extend(silence(0.05 + i * 0.015))
        out.extend(noise(0.035, 0.5 - i * 0.1, lp=0.5, seed=31 + i))
    return out


def sfx_fall() -> list:
    """the end of the run: a long slide-whistle down + a soft splat"""
    n = int(SR * 0.55)
    down = []
    for i in range(n):
        t = i / SR
        f = 880.0 * (0.24 ** (t / 0.55))
        down.append(math.sin(2 * math.pi * f * t) * 0.4 * (0.4 + 0.6 * t / 0.55))
    return mix(
        down + silence(0.25),
        silence(0.52) + gain(noise(0.28, 0.5, lp=0.15, seed=47), 1.0),
    )


# ------------------------------------------------------------- the 32s loop
## A gentle winter music-box waltz in A minor pentatonic - deterministic,
## loop-safe (32 bars at 120bpm 3/4 = 48s? no: 4/4 at 120bpm, 16 bars of
## 2s = 32s). Pluck = sine + soft octave, pad = slow triangle bed.

def pluck(freq: float, dur: float, vol: float) -> list:
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        s = math.sin(2 * math.pi * freq * t) * 0.7 \
            + math.sin(2 * math.pi * freq * 2 * t) * 0.18 \
            + math.sin(2 * math.pi * freq * 3 * t) * 0.06
        out.append(s * vol * math.exp(-t * 3.2) * env(t, 0.003, dur))
    return out


def pad_chord(freqs: list, dur: float, vol: float) -> list:
    n = int(SR * dur)
    out = [0.0] * n
    for f in freqs:
        for i in range(n):
            t = i / SR
            out[i] += math.sin(2 * math.pi * f * t) * vol / len(freqs) \
                * env(t, 0.6, dur)
    return out


def sfx_theme() -> list:
    bpm = 120.0
    beat = 60.0 / bpm
    bar = beat * 4
    bars = 16
    total = int(SR * bar * bars)
    song = [0.0] * total

    def put(samples: list, at: float):
        idx = int(at * SR)
        for i, s in enumerate(samples):
            if idx + i < total:
                song[idx + i] += s

    A4, C5, D5, E5, G5, A5 = 440.0, 523.25, 587.33, 659.25, 784.0, 880.0
    C4, E4, G4, A3, D4, F4 = 261.63, 329.63, 392.0, 220.0, 293.66, 349.23
    # chord beds (2 bars each): Am - F - C - G, twice
    beds = [
        [A3, C4, E4], [F4 // 2 * 2 - 21.83, C4, E4],  # F big-ish: F2? keep F3
        [C4 - 0.0, E4, G4], [G4 - 12.0 * 0 + 0.0, C4, D4],
    ]
    beds = [[A3, C4, E4], [220.0 * 0.75, C4, E4], [C4, E4, G4], [196.0, C4, D4]]
    for bi in range(8):
        put(pad_chord(beds[bi % 4], bar * 2, 0.10), bi * bar * 2)
    # the melody: a calm descending music-box line, 2 notes per bar
    melody = [
        E5, C5, A4, C5, D5, C5, A4, G4,
        E5, C5, A4, C5, G5, E5, D5, C5,
        E5, C5, A4, C5, D5, E5, G5, A5,
        G5, E5, D5, C5, A4, G4, E5, C5,
    ]
    for mi, note in enumerate(melody):
        at = (mi // 2) * bar + (mi % 2) * beat * 2 + beat * 0.25
        put(pluck(note, 1.2, 0.22), at)
        if mi % 4 == 0:
            put(pluck(note / 2.0, 1.6, 0.10), at)
    # a soft sparkle every bar's last beat (the snow glitter)
    sparkles = [A5, G5, E5, D5] * 4
    for si, note in enumerate(sparkles):
        put(pluck(note, 0.7, 0.07), si * bar + beat * 3.5)
    # normalize
    peak = max(abs(s) for s in song) or 1.0
    return [s / peak * 0.82 for s in song]


def main() -> None:
    write_wav(os.path.join(SFX_DIR, "tower_jump.wav"), gain(sfx_jump(), 0.9))
    write_wav(os.path.join(SFX_DIR, "tower_land.wav"), gain(sfx_land(), 0.9))
    write_wav(os.path.join(SFX_DIR, "tower_coin.wav"), gain(sfx_coin(), 0.8))
    write_wav(os.path.join(SFX_DIR, "tower_pw.wav"), gain(sfx_pw(), 0.85))
    write_wav(os.path.join(SFX_DIR, "tower_pw_end.wav"), gain(sfx_pw_end(), 0.8))
    write_wav(os.path.join(SFX_DIR, "tower_wall.wav"), gain(sfx_wall(), 0.85))
    write_wav(os.path.join(SFX_DIR, "tower_crack.wav"), gain(sfx_crack(), 0.8))
    write_wav(os.path.join(SFX_DIR, "tower_fall.wav"), gain(sfx_fall(), 0.95))
    write_wav(os.path.join(MUS_DIR, "tower_theme.wav"), sfx_theme())


if __name__ == "__main__":
    main()
