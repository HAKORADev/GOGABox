#!/usr/bin/env python3
# ============================================================================
# v040-5 SMOOTH WAR AUDIO - the owner: "all designs and SFXs look like
# pixelated/retro style... they are currently poor". This rebuilds every
# rw_* SFX with a SMOOTH palette: layered sine/saw beds, filtered noise,
# soft tanh saturation, inharmonic metal partials - zero chiptune squares.
# New keys the rework needs: rw_pick_scrap / rw_laser / rw_shred / rw_no.
# The 4 music loops keep their v040-4 renders (they loop clean).
# Output: projects/gogabox/assets/audio/sfx/rw_*.ogg
# ============================================================================
import os, subprocess
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..",
                   "projects/gogabox/assets/audio/sfx")
rng = np.random.default_rng(20260916)


def t(dur):
    return np.linspace(0, dur, int(SR * dur), endpoint=False)


def env(n, a=0.004, r=0.1, shape=1.6, curve=2.0):
    e = np.ones(n)
    na = max(1, int(SR * a))
    nr = max(1, int(SR * r))
    e[:na] = np.linspace(0, 1, na) ** curve
    e[-nr:] *= np.linspace(1, 0, nr) ** shape
    return e


def noise(dur):
    return rng.uniform(-1, 1, int(SR * dur))


def sine(f, dur, ph=0.0):
    return np.sin(2 * np.pi * f * t(dur) + ph)


def saw(f, dur):
    return 2 * ((f * t(dur)) % 1.0) - 1.0


def sweep_lp(x, a0, a1):
    y = np.empty_like(x)
    acc = 0.0
    alphas = np.linspace(a0, a1, len(x))
    for i, v in enumerate(x):
        acc += alphas[i] * (v - acc)
        y[i] = acc
    return y


def sweep_hp(x, a0, a1):
    return x - sweep_lp(x, a0, a1)


def soft(x, drive=1.5):
    return np.tanh(x * drive)


def mix(*parts):
    # zero-pad every layer to the longest one, then sum
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def norm(x, gain=0.88):
    m = np.max(np.abs(x))
    return (x / m * gain) if m > 0 else x


def save(name, x, gain=0.88):
    x = norm(np.asarray(x, dtype=np.float64), gain)
    pcm = (x * 32767).astype(np.int16)
    stereo = np.column_stack([pcm, pcm])
    raw = f"/tmp/rw5_{name}.raw"
    stereo.tofile(raw)
    dst = f"{OUT}/rw_{name}.ogg"
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "s16le", "-ar",
                    str(SR), "-ac", "2", "-i", raw, "-c:a", "libvorbis",
                    "-q:a", "4", dst], check=True)
    os.remove(raw)
    print("rw_%s %.2fs" % (name, len(x) / SR))


def fm_tone(f0, f1, dur, ratio=2.0, index=3.0, fade=1.0):
    # a smooth FM bell/pluck: carrier glides f0->f1, modulator decays
    tt = t(dur)
    f = np.linspace(f0, f1, len(tt))
    ph = 2 * np.pi * np.cumsum(f) / SR
    mod = np.sin(ph * ratio) * np.exp(-tt * fade) * index
    out = np.sin(ph + mod)
    return out * env(len(tt), 0.003, dur * 0.7)


def boom(dur=0.8, f0=110, f1=36, body=0.9, grit=0.35):
    # the layered explosion: sub thump + moving noise body + debris
    n = int(SR * dur)
    sub = sine(f1, dur)
    fsw = np.linspace(f0, f1, n)
    ph = 2 * np.pi * np.cumsum(fsw) / SR
    thump = np.sin(ph) * env(n, 0.001, dur * 0.8, 2.2)
    bodyn = sweep_lp(noise(dur), 0.5, 0.06) * env(n, 0.001, dur * 0.55, 1.6)
    crack = sweep_hp(noise(dur), 0.25, 0.08) * env(n, 0.0005, dur * 0.25, 2.5)
    return thump * 1.05 + body * bodyn + grit * crack


# ------------------------------------------------------------------ guns
# THE MAIN CANNON: a heavy layered punch - sub drop + muffled crack +
# metal ring (the shell leaves with weight, never an 8-bit pop)
x = mix(boom(0.5, 130, 34, 0.65, 0.4),
        0.35 * fm_tone(320, 120, 0.28, 1.5, 2.0, 9.0),
        0.22 * sweep_lp(noise(0.5), 0.35, 0.03) * env(int(SR * 0.5), 0.001, 0.4))
save("cannon", x, 0.9)

# THE MACHINE GUNS: a short mechanical burst - filtered tick + tiny body,
# slight round-robin pitch so rapid fire shimmers
for k, (f, g) in enumerate([(1900, 0.6), (1650, 0.62)]):
    d = 0.055
    tick = sweep_hp(noise(d), 0.5, 0.2) * env(int(SR * d), 0.0004, 0.035, 2.6)
    body = sine(f, d) * env(int(SR * d), 0.0004, 0.03, 2.0) * 0.5
    save("mg", soft(tick + body, 1.2), 0.5 if k else 0.55)

# THE ROCKETS: launch whoosh + flame rumble
d = 0.85
wh = sweep_lp(noise(d), 0.10, 0.6) * env(int(SR * d), 0.09, 0.5, 1.2)
rum = sweep_lp(noise(d), 0.18, 0.08) * env(int(SR * d), 0.12, 0.6, 1.4)
sub = sine(70, d) * env(int(SR * d), 0.12, 0.55) * 0.4
save("rocket", soft(wh * 0.9 + rum * 0.7 + sub, 1.2), 0.72)

# enemy plasma: a smooth descending chirp (soft, not buzzy)
d = 0.22
f = np.linspace(880, 240, int(SR * d))
ph = 2 * np.pi * np.cumsum(f) / SR
x = (np.sin(ph) + 0.35 * np.sin(ph * 2.0)) \
        * env(int(SR * d), 0.004, 0.16, 1.8)
save("eshot", soft(x, 1.1), 0.5)

# ------------------------------------------------------------------ hits
# shield hit: a glassy shimmer
d = 0.3
x = (fm_tone(1250, 900, d, 1.9, 2.2, 6.0) * 0.5
     + fm_tone(1870, 1400, d, 2.7, 1.5, 8.0) * 0.3)
save("shieldhit", x, 0.45)

# hurt: a muffled heavy thud + a low alarm tail
d = 0.4
x = mix(boom(d, 90, 40, 0.5, 0.2), 0.2 * fm_tone(180, 130, d, 1.0, 1.2, 5.0))
save("hurt", x, 0.72)

# ice/cryo touch
d = 0.26
x = fm_tone(1500, 1100, d, 2.4, 1.4, 7.0) * 0.55 \
        + sweep_hp(noise(d), 0.5, 0.3) * env(int(SR * d), 0.002, 0.16) * 0.2
save("icehit", x, 0.42)

# ------------------------------------------------------------- explosions
save("boom_small", boom(0.5, 120, 42, 0.55, 0.4), 0.7)
save("boom_big", mix(boom(1.1, 100, 28, 0.95, 0.45),
     0.3 * sweep_lp(noise(1.1), 0.12, 0.02) * env(int(SR * 1.1), 0.001, 0.9)), 0.95)

# SHRED: metal crack + scatter (the falling shrapnel)
d = 0.34
crack = sweep_hp(noise(d), 0.35, 0.1) * env(int(SR * d), 0.0005, 0.14, 2.4)
ring = fm_tone(2400, 1900, d, 1.35, 1.8, 10.0) * 0.3
save("shred", soft(mix(crack, ring), 1.3), 0.6)

# THE LASER: charge + burn hum
d = 1.7
n = int(SR * d)
ch = 0.45
f = np.linspace(200, 640, int(SR * ch))
phc = 2 * np.pi * np.cumsum(f) / SR
charge = np.sin(phc) * env(int(SR * ch), 0.02, ch * 0.25, 0.8)
burnn = int(SR * (d - ch))
fb = np.linspace(640, 600, burnn)
phb = 2 * np.pi * np.cumsum(fb) / SR
burn = (np.sin(phb) + 0.4 * np.sin(phb * 2.3)
        + sweep_lp(noise(d - ch), 0.4, 0.3) * 0.5) \
        * env(burnn, 0.02, (d - ch) * 0.4, 0.6)
save("laser", soft(np.concatenate([charge * 0.8, burn * 0.55]), 1.2), 0.55)

# ------------------------------------------------------------ pickups
# scrap: a warm brass chime (two inharmonic partials)
save("pick_scrap",
     mix(fm_tone(920, 900, 0.16, 1.41, 1.6, 7.0) * 0.6,
         fm_tone(1380, 1360, 0.14, 2.1, 1.2, 8.0) * 0.35), 0.5)
# xp: a soft glass note
save("pick_xp", fm_tone(1180, 1180, 0.15, 1.5, 1.2, 7.0), 0.42)
# coin: the box's warm two-tone
d = 0.2
n = int(SR * d)
a = sine(1046, d) * env(n, 0.002, 0.12) * 0.6
b = np.concatenate([sine(1568, d) * env(n, 0.002, 0.15), np.zeros(int(SR * 0.06))])[:n]
save("pick_coin", a + b * 0.5, 0.5)

# ----------------------------------------------------------------- UI/war
d = 0.07
save("click", sweep_hp(noise(d), 0.4, 0.15) * env(int(SR * d), 0.001, 0.045, 2.0), 0.4)
d = 0.24
save("buy",
     mix(fm_tone(660, 660, 0.12, 1.0, 0.6, 6.0) * 0.5,
         np.concatenate([np.zeros(int(SR * 0.07)),
                         fm_tone(990, 990, 0.15, 1.0, 0.6, 6.0) * 0.55])),
     0.5)
# NO: the refused buy - a dull double-buzz, soft but firm
d = 0.26
n = int(SR * d)
fno = np.concatenate([np.full(int(SR * 0.09), 190.0),
                      np.full(int(SR * 0.10), 150.0),
                      np.zeros(n - int(SR * 0.19))])
phno = 2 * np.pi * np.cumsum(fno) / SR
save("no", (np.sin(phno) * 0.7 + np.sin(phno * 0.5) * 0.3)
     * env(n, 0.004, 0.1, 1.2), 0.55)
d = 0.5
save("wave", mix(fm_tone(392, 392, 0.18, 1.0, 0.5, 5.0) * 0.5,
     np.concatenate([np.zeros(int(SR * 0.1)),
                     fm_tone(523, 523, 0.22, 1.0, 0.5, 5.0) * 0.6])), 0.55)
d = 0.4
save("clear",
     mix(fm_tone(523, 523, 0.14, 1.0, 0.5, 6.0) * 0.45,
         np.concatenate([np.zeros(int(SR * 0.09)),
                         fm_tone(659, 659, 0.14, 1.0, 0.5, 6.0) * 0.5]),
         np.concatenate([np.zeros(int(SR * 0.18)),
                         fm_tone(784, 784, 0.2, 1.0, 0.5, 6.0) * 0.55])), 0.55)
d = 0.5
n = int(SR * d)
save("levelup",
     np.concatenate([fm_tone(523, 523, 0.13, 1.0, 0.5, 6.0) * 0.5,
                     fm_tone(659, 659, 0.13, 1.0, 0.5, 6.0) * 0.55,
                     fm_tone(784, 784, 0.16, 1.0, 0.5, 6.0) * 0.6,
                     fm_tone(1046, 1046, 0.22, 1.0, 0.5, 6.0) * 0.65]), 0.6)
save("card", fm_tone(880, 880, 0.16, 1.41, 1.0, 7.0) * 0.6, 0.45)
save("tunnel", mix(sweep_lp(noise(1.4), 0.08, 0.5)
     * env(int(SR * 1.4), 0.3, 0.6, 1.0) * 0.8,
     sine(55, 1.4) * env(int(SR * 1.4), 0.3, 0.8) * 0.5), 0.5)
d = 1.2
n = int(SR * d)
fb = np.linspace(180, 90, n)
phb = 2 * np.pi * np.cumsum(fb) / SR
save("boss_warn", soft(mix((np.sin(phb) + 0.5 * np.sin(phb * 0.5))
     * env(n, 0.02, 0.5, 1.0),
     0.25 * sweep_lp(noise(d), 0.2, 0.05) * env(n, 0.02, 0.7)), 1.4), 0.75)
save("boss_die", mix(boom(1.5, 110, 26, 1.0, 0.5),
     0.4 * fm_tone(500, 200, 1.2, 1.5, 2.0, 4.0)), 0.95)
save("gameover", mix(boom(1.6, 90, 24, 0.9, 0.4),
     0.35 * fm_tone(400, 90, 1.6, 1.5, 2.5, 3.0)), 0.9)

print("v040-5 smooth sfx done")
