#!/usr/bin/env python3
"""v0.2.4 audio - SPACE DASH's own sound set + the deep-space music loop.

The owner's brief: "proper SFXs obviously", "realistic atmosphere" - so this
set is designed like a little sound library, not arcade bleeps: every voice
has a body (sub layer), an edge (noise or bright partial) and a tail. The
thunder strike is a real crack (noise burst + falling crackle + sub thump),
the bombs boom with a low body, the coin keeps the box's bright two-tone
language. Music is a slow dark space pad loop (Am - F - C - G) with a
sub-bass, a detuned pad, a sparse arp in the second pass and a washed
noise bed - 32s, seamless.

Re-runnable: same code -> same bytes (fixed rng seed)."""

import math
import os
import wave

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(PROJ, "assets", "audio", "sfx")
MUS = os.path.join(PROJ, "assets", "audio", "music")
SR = 44100

import numpy as np  # noqa: E402

RNG = np.random.default_rng(2404)


def _save(name, data, vol=1.0):
    data = np.clip(data * vol, -1.0, 1.0)
    pcm = (data * 32767).astype(np.int16)
    if pcm.ndim == 1:
        pcm = np.column_stack([pcm, pcm])
    d = MUS if "_theme" in name else SFX
    with wave.open(os.path.join(d, name + ".wav"), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("assets/audio/%s/%s.wav" % ("music" if "_theme" in name else "sfx",
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


def sweep(f0, f1, dur, pow_=1.0):
    t = _t(dur)
    f = f0 + (f1 - f0) * (t / dur) ** pow_
    ph = 2 * math.pi * np.cumsum(f) / SR
    return np.sin(ph)


def saw(f, dur, detune=0.0):
    t = _t(dur)
    out = 2.0 * ((f * t) % 1.0) - 1.0
    if detune > 0:
        out = 0.5 * out + 0.5 * (2.0 * ((f * (1 + detune) * t) % 1.0) - 1.0)
    return out


def square(f, dur, duty=0.3):
    t = _t(dur)
    return np.where((f * t) % 1.0 < duty, 1.0, -1.0)


def noise(dur, seed=None):
    r = np.random.default_rng(2404 + (seed or 0))
    return r.uniform(-1, 1, int(SR * dur))


def lowpass(x, alpha):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def hipass(x, alpha):
    return x - lowpass(x, alpha)


# ------------------------------------------------------------ one-shots

def beam():
    """Yellow beam - tight zap: bright square body, fast drop, tiny tail."""
    d = 0.085
    body = square(1180, d, 0.28) * 0.5 + saw(1180 * 0.5, d) * 0.4
    drop = sweep(1500, 480, d, 1.4)
    x = (body * 0.55 + drop * 0.6) * _env(len(body), 0.002, 0.03)
    _save("dash_beam", x, 0.5)


def laser():
    """Red laser - an energized hum: saw pair + 100Hz body + shimmer."""
    d = 0.55
    hum = saw(240, d, 0.012) * 0.45 + saw(360, d, 0.01) * 0.3
    body = sine(100, d) * 0.5
    shimmer = hipass(noise(d, 1), 0.4) * 0.10
    lfo = 0.75 + 0.25 * np.sin(2 * math.pi * 22 * _t(d))
    x = (hum + body + shimmer) * lfo * _env(int(SR * d), 0.01, 0.16)
    _save("dash_laser", x, 0.55)


def thunder():
    """White thunder - the crack: noise snap, falling crackle, sub thump."""
    d = 0.5
    snap = noise(d, 2) * np.exp(-_t(d) * 60)
    crack = hipass(noise(d, 3), 0.25) * np.exp(-_t(d) * 14) * 0.8
    thump = sweep(180, 46, d, 0.8) * np.exp(-_t(d) * 9) * 0.9
    x = (snap * 0.8 + crack * 0.7 + thump) * _env(int(SR * d), 0.001, 0.08)
    _save("dash_thunder", x, 0.85)


def bomb_throw():
    """Bomb launcher - a hollow launch: rising whoosh + soft clunk."""
    d = 0.28
    whoosh = hipass(lowpass(noise(d, 4), 0.28), 0.06)
    rise = sweep(160, 520, d, 1.6) * 0.25
    x = (whoosh * 0.9 + rise) * _env(int(SR * d), 0.006, 0.10)
    _save("dash_bomb", x, 0.6)


def boom(name, dur, f0, f1, body_db, seed, vol):
    t = _t(dur)
    body = sweep(f0, f1, dur, 0.6) * np.exp(-t * body_db)
    crunch = lowpass(noise(dur, seed), 0.22) * np.exp(-t * (body_db * 1.4))
    cracle = hipass(noise(dur, seed + 40), 0.35) * np.exp(-t * (body_db * 2.2)) * 0.35
    x = (body + crunch * 0.9 + cracle) * _env(len(t), 0.002, dur * 0.25)
    _save(name, x, vol)


def coin():
    """Coin - the box language: bright two-tone blip (B5 -> E6)."""
    a = sine(987, 0.07) * _env(int(SR * 0.07), 0.002, 0.02)
    b = sine(1318, 0.12) * _env(int(SR * 0.12), 0.002, 0.08)
    x = np.concatenate([a, b]) * 0.6
    x = x + 0.25 * np.concatenate([sine(1975, 0.07) * _env(int(SR * 0.07), 0.002, 0.02),
                                   sine(2636, 0.12) * _env(int(SR * 0.12), 0.002, 0.08)])
    _save("dash_coin", x, 0.5)


def pick():
    """Power point - a tidy rising arp (C6 E6 G6)."""
    segs = []
    for f, dd in [(1046, 0.055), (1318, 0.055), (1568, 0.11)]:
        s = (sine(f, dd) * 0.6 + sine(f * 2, dd) * 0.2) \
                * _env(int(SR * dd), 0.002, dd * 0.5)
        segs.append(s)
    _save("dash_pick", np.concatenate(segs), 0.55)


def weapon_pick():
    """Weapon item - a chord stab (C5 E5 G5 together, bright)."""
    d = 0.32
    x = (saw(523, d) * 0.3 + saw(659, d) * 0.3 + saw(784, d) * 0.3
         + sine(261, d) * 0.5) * _env(int(SR * d), 0.004, 0.2)
    _save("dash_weapon", x, 0.55)


def shield():
    """Shield pickup - a shimmering rise with a soft landing."""
    d = 0.4
    rise = sweep(300, 900, d, 1.2) * 0.4
    shim = hipass(noise(d, 5), 0.5) * 0.12 * (0.6 + 0.4 * np.sin(2 * math.pi * 13 * _t(d)))
    pad = sine(600, d) * 0.15 + sine(900, d) * 0.12
    x = (rise + shim + pad) * _env(int(SR * d), 0.01, 0.16)
    _save("dash_shield", x, 0.5)


def shield_hit():
    """Shield blocks - a metallic dud, not a boom."""
    d = 0.22
    x = (square(210, d, 0.4) * 0.5 + sine(160, d) * 0.5
         + hipass(noise(d, 6), 0.3) * 0.3) \
        * np.exp(-_t(d) * 22) * _env(int(SR * d), 0.001, 0.06)
    _save("dash_shield_hit", x, 0.6)


def hit():
    """Player wreck - a crash: boom body + metal debris + falling sweep."""
    d = 0.75
    t = _t(d)
    body = sweep(140, 38, d, 0.7) * np.exp(-t * 7)
    metal = hipass(noise(d, 7), 0.25) * np.exp(-t * 10) * 0.6
    fall = sweep(900, 90, d, 1.3) * np.exp(-t * 6) * 0.2
    x = (body + metal + fall) * _env(int(SR * d), 0.002, 0.2)
    _save("dash_hit", x, 0.8)


def heart():
    """+1 heart - a warm major lift (A4 -> C#5 -> E5)."""
    segs = []
    for f, dd in [(440, 0.08), (554, 0.08), (659, 0.16)]:
        s = (sine(f, dd) + sine(f * 2, dd) * 0.25) \
                * _env(int(SR * dd), 0.004, dd * 0.55)
        segs.append(s)
    _save("dash_heart", np.concatenate(segs), 0.55)


def upgrade():
    """Power upgrade - rising zip + sparkle on top."""
    d = 0.35
    zip_ = sweep(320, 980, d, 1.1) * 0.5
    spark = sine(1568, d) * 0.2 * (1 + np.sin(2 * math.pi * 30 * _t(d))) * 0.5
    x = (zip_ + spark) * _env(int(SR * d), 0.004, 0.12)
    _save("dash_upgrade", x, 0.5)


def over():
    """Game over - a slow dark fall (A4 F4 D4 A3)."""
    segs = []
    for f, dd in [(440, 0.3), (349, 0.3), (293, 0.3), (220, 0.5)]:
        s = (saw(f, dd, 0.01) * 0.3 + sine(f / 2, dd) * 0.5) \
                * _env(int(SR * dd), 0.01, dd * 0.5)
        segs.append(s)
    _save("dash_over", np.concatenate(segs), 0.6)


def start():
    """Round start - engine lift: rising hum + takeoff whoosh."""
    d = 0.6
    hum = sweep(90, 240, d, 1.3) * 0.5
    air = hipass(lowpass(noise(d, 8), 0.3), 0.05) * 0.5 \
        * (0.4 + 0.6 * _t(d) / d)
    x = (hum + air) * _env(int(SR * d), 0.01, 0.18)
    _save("dash_start", x, 0.6)


def swap():
    """Lane move - a tight air push, quiet (it fires a lot)."""
    d = 0.1
    x = hipass(lowpass(noise(d, 9), 0.4), 0.08) \
        * _env(int(SR * d), 0.004, 0.05) * 0.9
    x = x + sweep(500, 700, d, 1.0) * 0.15
    _save("dash_swap", x, 0.42)


def alert():
    """Elite incoming - two-tone alarm, not shy."""
    a = square(660, 0.16, 0.5) * _env(int(SR * 0.16), 0.004, 0.04)
    b = square(520, 0.22, 0.5) * _env(int(SR * 0.22), 0.004, 0.10)
    x = np.concatenate([a, b]) * 0.35
    _save("dash_alert", x, 0.5)


# ------------------------------------------------------------ music loop

def theme():
    """Deep-space pad loop, 32s: Am F C G, two passes.
    Pass 1 = sub + pad + wash. Pass 2 = + arp + brighter pad octave."""
    beat = 4.0  # seconds per chord
    chords = [(220.0, 261.63, 329.63),   # A3 C4 E4  - Am
              (174.61, 220.0, 261.63),   # F3 A3 C4  - F
              (130.81, 196.0, 261.63),   # C3 G3 C4  - C
              (196.0, 246.94, 293.66)]   # G3 B3 D4  - G
    out = []
    for rep in range(2):
        for (r0, r1, r2) in chords:
            n = int(SR * beat)
            t = np.linspace(0, beat, n, endpoint=False)
            sub = sine(r0 / 2, beat) * 0.30
            pad = (saw(r0, beat, 0.006) * 0.16 + saw(r1, beat, 0.006) * 0.14
                   + saw(r2, beat, 0.006) * 0.12)
            pad = lowpass(pad, 0.06)
            if rep == 1:
                pad = pad + (sine(r2 * 2, beat) * 0.05
                             + saw(r1 * 2, beat, 0.008) * 0.05)
            wash = lowpass(noise(beat, rep * 11 + int(r0)), 0.02) * 0.05
            voice = sub + pad + wash
            # slow chord-swell envelope so chords breathe into each other
            env = np.minimum(t / 1.4, 1.0) * np.minimum((beat - t) / 1.4, 1.0)
            env = np.clip(env, 0, 1) ** 0.8
            voice = voice * env
            if rep == 1:
                # sparse arp: 8th-note plucks walking the chord, every other one
                step = beat / 8
                for k in range(0, 8, 2):
                    f = [r0, r1, r2, r1][(k // 2) % 4]
                    seg = sine(f * 2, step * 0.9) * 0.10 \
                        * np.exp(-np.linspace(0, step * 0.9,
                                              int(SR * step * 0.9)) * 6)
                    i0 = int(SR * k * step)
                    voice[i0:i0 + len(seg)] += seg
            out.append(voice)
    x = np.concatenate(out)
    # seam: crossfade the last 0.4s into the first 0.4s for a clean loop
    f = int(SR * 0.4)
    ramp = np.linspace(0, 1, f)
    x[:f] = x[:f] * ramp + x[-f:] * (1 - ramp)
    x = x[:-f]
    _save("dash_theme", np.column_stack([x, np.roll(x, int(SR * 0.011))]), 0.9)


if __name__ == "__main__":
    np.random.seed(2404)
    beam()
    laser()
    thunder()
    bomb_throw()
    boom("dash_boom", 0.9, 150, 36, 6.0, 20, 0.85)      # bomb / big field boom
    boom("dash_boom_small", 0.4, 220, 70, 11.0, 21, 0.7)  # grunt pop
    boom("dash_boom_big", 1.15, 120, 30, 4.5, 22, 0.9)    # tank / elite death
    coin()
    pick()
    weapon_pick()
    shield()
    shield_hit()
    hit()
    heart()
    upgrade()
    over()
    start()
    swap()
    alert()
    theme()
    print("space dash audio complete")
