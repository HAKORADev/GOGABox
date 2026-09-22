#!/usr/bin/env python3
"""
v041-2 - TOWER BALL audio (tools/v0412_sfx.py).

Designs every Tower Ball SFX as pure math (the v0.2.5 house law: SFX are
the cheapest thing that makes a game feel expensive) and writes them into
the project:

  projects/gogabox/assets/audio/sfx/tb_*.wav   (10 SFX)
  projects/gogabox/assets/audio/music/tb_theme.wav  (a 32s casual loop)

The palette: warm rubbery pops, glassy shatters, a meaty crash, a bright
win arp - the CASUAL KNOWN look in sound form, nothing harsh, nothing
neon. Every sound is deterministic (seeded noise only).

Run:  python3 tools/v0412_sfx.py
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


def pluck(freq: float, dur: float, vol: float) -> list:
    """the music-box pluck (the tower theme's voice)"""
    s = tone(freq, dur, vol, wave_fn="tri")
    h = gain(tone(freq * 2, dur * 0.5, vol * 0.3), 0.5)
    return mix(s, h)


# ------------------------------------------------------------- the ten SFX

def sfx_bounce() -> list:
    """the bounce: a soft rubbery pop - warm, never harsh"""
    return mix(
        gain(tone(220, 0.12, 0.5, slide=1.7), 0.9),
        gain(noise(0.05, 0.10, lp=0.4, seed=5), 0.7),
    )


def sfx_break() -> list:
    """the disc shatter: a glassy crack + a crumble tail"""
    return mix(
        gain(noise(0.10, 0.5, lp=0.85, seed=13), 1.0),
        gain(tone(520, 0.09, 0.3, slide=0.6), 0.8),
        gain(noise(0.28, 0.28, a=0.04, lp=0.25, seed=23), 0.9),
    )


def sfx_block() -> list:
    """the block break: a woodier knock + a short crumble"""
    return mix(
        gain(tone(340, 0.08, 0.4, slide=0.7), 0.9),
        gain(noise(0.09, 0.35, lp=0.6, seed=17), 0.9),
        gain(noise(0.20, 0.18, a=0.03, lp=0.2, seed=29), 0.8),
    )


def sfx_smash() -> list:
    """the smash start: a dive whoosh (the ball commits)"""
    return gain(tone(700, 0.28, 0.30, slide=0.32, wave_fn="tri"), 0.9)


def sfx_fire() -> list:
    """the fireball ignite: a rising whoosh + a crackle crown"""
    return mix(
        gain(tone(160, 0.5, 0.4, slide=3.2, wave_fn="tri"), 1.0),
        gain(noise(0.45, 0.30, a=0.05, lp=0.5, seed=31), 0.8),
        concat(silence(0.18),
               gain(noise(0.30, 0.25, a=0.01, lp=0.9, seed=37), 0.9)),
    )


def sfx_crash() -> list:
    """the black crash: a meaty thud + an ugly buzz (the lesson lands)"""
    return mix(
        gain(tone(120, 0.3, 0.6, slide=0.4), 1.0),
        gain(tone(97, 0.26, 0.4, wave_fn="square", slide=0.5), 0.5),
        gain(noise(0.18, 0.4, lp=0.3, seed=41), 0.9),
    )


def sfx_win() -> list:
    """the round win: a bright rising arp (C5 E5 G5 C6) + a sparkle"""
    out = []
    for i, f in enumerate([523.25, 659.25, 783.99, 1046.5]):
        out.extend(silence(0.07))
        out.extend(gain(pluck(f, 0.3, 0.4), 1.0 - i * 0.06))
    out.extend(gain(noise(0.3, 0.12, a=0.02, lp=0.9, seed=43), 0.6))
    return out


def sfx_collapse() -> list:
    """the tower slide: a soft descending rumble (platform mode)"""
    return mix(
        gain(tone(300, 0.22, 0.25, slide=0.55), 0.9),
        gain(noise(0.20, 0.20, a=0.02, lp=0.18, seed=47), 0.9),
    )


def sfx_serve() -> list:
    """the platform serve: a friendly double-click"""
    return concat(
        gain(tone(660, 0.05, 0.3), 1.0),
        silence(0.03),
        gain(tone(880, 0.07, 0.3), 1.0),
    )


def sfx_click() -> list:
    """the UI click"""
    return gain(tone(720, 0.05, 0.28, slide=1.2), 1.0)


def sfx_miss() -> list:
    """the coin missed: a soft descending two-tone sigh"""
    return concat(
        gain(tone(880, 0.12, 0.3), 1.0),
        gain(tone(587.3, 0.2, 0.3), 0.9),
    )


# ------------------------------------------------------------- the theme
# 32s casual loop: warm plucks over a soft pad, C major, steady 104 BPM -
# the "known casual" comfort, never neon, never epic.

def theme() -> list:
    bpm = 104.0
    beat = 60.0 / bpm
    bar = beat * 4
    # I - V - vi - IV in C (the forever-comfortable loop)
    chords = [
        [261.63, 329.63, 392.0],     # C
        [196.0, 246.94, 392.0],      # G
        [220.0, 261.63, 329.63],     # Am
        [174.61, 220.0, 349.23],     # F
    ]
    melody = [523.25, 659.25, 783.99, 659.25,
              587.33, 523.25, 440.0, 523.25,
              659.25, 783.99, 880.0, 783.99,
              698.46, 659.25, 587.33, 523.25]
    n_bars = 16
    total = int(SR * bar * n_bars)
    out = [0.0] * total
    # the pad: soft chord sines, one per bar
    for b in range(n_bars):
        chord = chords[b % 4]
        start = int(SR * bar * b)
        dur = bar * 0.98
        for f in chord:
            seg = gain(tone(f, dur, 0.05, a=0.4), 1.0)
            for i, s in enumerate(seg):
                if start + i < total:
                    out[start + i] += s
    # the pluck melody: one note per half-beat
    for step in range(n_bars * 8):
        f = melody[step % len(melody)]
        start = int(SR * beat * 0.5 * step)
        seg = gain(pluck(f, 0.5, 0.16), 1.0)
        for i, s in enumerate(seg):
            if start + i < total:
                out[start + i] += s
    # a soft bass heartbeat every beat
    for step in range(n_bars * 4):
        root = chords[step % 4][0] / 2.0
        start = int(SR * beat * step)
        seg = gain(tone(root, beat * 0.9, 0.12, a=0.01), 1.0)
        for i, s in enumerate(seg):
            if start + i < total:
                out[start + i] += s
    # gentle master lowpass + normalize
    out = lowpass(out, 0.5)
    peak = max(1e-6, max(abs(s) for s in out))
    return [s * 0.82 / peak for s in out]


# ------------------------------------------------------------- the drop

SFX = {
    "tb_bounce.wav": sfx_bounce,
    "tb_break.wav": sfx_break,
    "tb_block.wav": sfx_block,
    "tb_smash.wav": sfx_smash,
    "tb_fire.wav": sfx_fire,
    "tb_crash.wav": sfx_crash,
    "tb_win.wav": sfx_win,
    "tb_collapse.wav": sfx_collapse,
    "tb_serve.wav": sfx_serve,
    "tb_click.wav": sfx_click,
    "tb_miss.wav": sfx_miss,
}


def main() -> None:
    for name, fn in SFX.items():
        write_wav(os.path.join(SFX_DIR, name), fn())
    write_wav(os.path.join(MUS_DIR, "tb_theme.wav"), theme())


if __name__ == "__main__":
    main()
