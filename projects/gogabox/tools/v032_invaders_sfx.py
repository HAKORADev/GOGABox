#!/usr/bin/env python3
# v0.3.2 SPACE INVADERS - the voice pass. 27 sfx (inv_*) + 2 music loops.
# Every voice has a body, an edge and a tail (repo law). Deterministic.
import os, wave, math
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(ROOT, "assets", "audio", "sfx")
MUS = os.path.join(ROOT, "assets", "audio", "music")
os.makedirs(SFX, exist_ok=True)
os.makedirs(MUS, exist_ok=True)
SR = 22050
rng = np.random.default_rng(32)

def env(n, a=0.005, r=0.08, shape=1.0):
    t = np.arange(n) / SR
    at = max(int(a * SR), 1)
    e = np.ones(n)
    e[:at] = np.linspace(0, 1, at)
    rel = np.exp(-np.maximum(t - a, 0) / max(r, 1e-3) * shape)
    return e * rel

def tone(f, dur, wave="sin", detune=0.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    ph = 2 * np.pi * (f + detune) * t
    if wave == "sin":
        return np.sin(ph)
    if wave == "saw":
        return 2 * ((f * t) % 1.0) - 1.0
    if wave == "sqr":
        return np.sign(np.sin(ph)) * 0.7
    return np.sign(np.sin(ph)) * np.abs(np.sin(ph))  # tri-ish

def sweep(f0, f1, dur, wave="sin"):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = f0 + (f1 - f0) * (t / dur)
    ph = 2 * np.pi * np.cumsum(f) / SR
    if wave == "saw":
        return 2 * (np.cumsum(f) / SR % 1.0) - 1.0
    return np.sin(ph)

def noise(dur):
    return rng.uniform(-1, 1, int(dur * SR))

def lowpass(x, alpha=0.2):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y

def shrink(x, dur):
    n = int(dur * SR)
    return x[:n] if len(x) >= n else np.pad(x, (0, n - len(x)))

def save(name, x, gain=0.9, dmg_dir=SFX):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x)) + 1e-9
    x = x / m * gain
    pcm = (x * 32767).astype(np.int16)
    p = os.path.join(dmg_dir, name)
    with wave.open(p, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("  wrote", name, f"{len(x)/SR:.2f}s {os.path.getsize(p)//1024}KB")

def shot(name, f0, f1, dur, wave="sin", noise_amt=0.0, a=0.002, r=0.05):
    body = sweep(f0, f1, dur, wave)
    x = body * env(len(body), a, r, 2.2)
    if noise_amt > 0:
        x = x * (1 - noise_amt) + lowpass(noise(dur), 0.5) * noise_amt * env(len(body), a, r * 0.6, 3)
    save(name, x, 0.62)

# --- the seven weapon voices -------------------------------------------------
shot("inv_shoot_azure.wav", 880, 520, 0.10, "sin", 0.10)          # blue ball: soft pluck
shot("inv_shoot_ember.wav", 620, 300, 0.12, "saw", 0.28)          # red beam: raspy
shot("inv_shoot_verdant.wav", 300, 190, 0.16, "sin", 0.12)        # snake: wet low wobble
shot("inv_shoot_veteran.wav", 220, 160, 0.22, "tri", 0.06)        # sound arc: hollow pulse
shot("inv_shoot_phantom.wav", 1400, 900, 0.045, "sqr", 0.35)      # MG: tick
shot("inv_shoot_hornet.wav", 180, 640, 0.18, "saw", 0.45)         # fire: rising whoosh
shot("inv_shoot_titan.wav", 120, 60, 0.30, "sin", 0.30)           # missile: thoomp

# --- impacts / explosions ----------------------------------------------------
x = lowpass(noise(0.22), 0.35) * env(int(0.22 * SR), 0.001, 0.05, 3) + sweep(500, 160, 0.22) * env(int(0.22 * SR), 0.001, 0.07, 2.5) * 0.6
save("inv_boom_small.wav", x, 0.7)
x = lowpass(noise(0.7), 0.18) * env(int(0.7 * SR), 0.002, 0.22, 2) + sweep(220, 40, 0.7) * env(int(0.7 * SR), 0.002, 0.3, 1.6)
save("inv_boom_big.wav", x, 0.95)
x = sweep(340, 90, 0.34, "sqr") * env(int(0.34 * SR), 0.002, 0.10, 2.4) + lowpass(noise(0.34), 0.4) * 0.4 * env(int(0.34 * SR), 0.001, 0.06, 3)
save("inv_hurt.wav", x, 0.85)
x = sweep(600, 1100, 0.10) * env(int(0.10 * SR), 0.002, 0.05, 2)
save("inv_hit.wav", x, 0.45)

# --- pickups / ui ------------------------------------------------------------
x = np.concatenate([tone(740, 0.07) * env(int(0.07 * SR)), tone(1180, 0.12) * env(int(0.12 * SR))])
save("inv_coin.wav", x, 0.55)
x = sweep(300, 1400, 0.30) * env(int(0.30 * SR), 0.01, 0.12, 1.4)
save("inv_power.wav", x, 0.6)
x = np.concatenate([tone(520, 0.05, "sqr") * env(int(0.05 * SR)), tone(780, 0.08, "sqr") * env(int(0.08 * SR))])
save("inv_wswitch.wav", x, 0.5)
x = np.concatenate([tone(880, 0.06) * env(int(0.06 * SR)), tone(1320, 0.10) * env(int(0.10 * SR)), tone(1760, 0.16) * env(int(0.16 * SR))])
save("inv_heart.wav", x, 0.6)
x = tone(660, 0.05) * env(int(0.05 * SR), 0.001, 0.03, 2)
save("inv_dialog.wav", x, 0.42)
x = tone(880, 0.04, "sqr") * env(int(0.04 * SR), 0.001, 0.02, 2)
save("inv_click.wav", x, 0.4)
x = np.concatenate([tone(392, 0.09) * env(int(0.09 * SR)), tone(523, 0.09) * env(int(0.09 * SR)), tone(659, 0.09) * env(int(0.09 * SR)), tone(784, 0.22) * env(int(0.22 * SR))])
save("inv_wave.wav", x, 0.5)
x = np.concatenate([tone(523, 0.08) * env(int(0.08 * SR)), tone(659, 0.08) * env(int(0.08 * SR)), tone(784, 0.08) * env(int(0.08 * SR)), tone(1046, 0.30) * env(int(0.30 * SR))])
save("inv_win_stage.wav", x, 0.6)
x = np.concatenate([tone(440, 0.16, "tri") * env(int(0.16 * SR)), tone(349, 0.16, "tri") * env(int(0.16 * SR)), tone(261, 0.4, "tri") * env(int(0.4 * SR))])
save("inv_over.wav", x, 0.6)

# --- alarms / specials -------------------------------------------------------
a1 = tone(880, 0.18, "sqr") * env(int(0.18 * SR), 0.01, 0.06, 1)
a2 = tone(622, 0.22, "sqr") * env(int(0.22 * SR), 0.01, 0.08, 1)
save("inv_breach.wav", np.concatenate([a1, a2, a1, a2 * 0.8]), 0.6)
x = lowpass(noise(0.5), 0.30) * env(int(0.5 * SR), 0.004, 0.16, 2.2) + sweep(90, 45, 0.5) * 0.7 * env(int(0.5 * SR), 0.004, 0.2, 1.8)
save("inv_thunder.wav", x, 0.8)
x = sweep(300, 90, 0.16, "sqr") * env(int(0.16 * SR), 0.004, 0.07, 2)
save("inv_bomb_drop.wav", x, 0.55)
x = lowpass(noise(0.8), 0.14) * env(int(0.8 * SR), 0.002, 0.26, 1.8) + sweep(160, 34, 0.8) * 0.8 * env(int(0.8 * SR), 0.002, 0.32, 1.4)
save("inv_bomb_boom.wav", x, 0.95)
x = tone(98, 0.5, "saw") * env(int(0.5 * SR), 0.02, 0.30, 1.2) + tone(147, 0.5, "saw") * env(int(0.5 * SR), 0.02, 0.28, 1.2) * 0.6 + lowpass(noise(0.5), 0.2) * 0.3
save("inv_boss_in.wav", x, 0.8)
x = sweep(300, 1900, 0.65) * env(int(0.65 * SR), 0.02, 0.30, 0.8) + lowpass(noise(0.65), 0.5) * 0.25
save("inv_boss_out.wav", x, 0.7)
x = np.concatenate([tone(660, 0.09) * env(int(0.09 * SR)), tone(880, 0.14) * env(int(0.14 * SR))])
save("inv_defend.wav", x, 0.55)
x = sweep(200, 2200, 1.1) * env(int(1.1 * SR), 0.05, 0.45, 0.7) + lowpass(noise(1.1), 0.4) * 0.3 * env(int(1.1 * SR), 0.05, 0.5, 0.9)
tail = sweep(2200, 60, 0.7) * env(int(0.7 * SR), 0.002, 0.25, 1.6) * 0.9
save("inv_escape.wav", np.concatenate([x, tail]), 0.9)

# --- the two music loops ------------------------------------------------------
def music(name, bpm, bars, root, minor=True, bright=0.5, seed=5):
    r = np.random.default_rng(seed)
    beat = 60.0 / bpm
    bar = beat * 4
    total = int(bar * bars * SR)
    out = np.zeros(total)
    scale = [0, 2, 3, 5, 7, 8, 10] if minor else [0, 2, 4, 5, 7, 9, 11]
    chord_prog = [(0, 5), (5, 3), (3, 5), (4, 5)] if minor else [(0, 5), (3, 4), (4, 4), (5, 5)]
    def hz(deg, octv=0):
        s = scale[deg % 7] + 12 * (deg // 7)
        return root * (2 ** ((s + 12 * octv) / 12.0))
    for b in range(bars):
        pos = int(b * bar * SR)
        deg, dur_b = chord_prog[b % len(chord_prog)]
        # pad chord
        for off in (0, 2, 4):
            f = hz(deg + off, 0)
            n = int(dur_b * beat * SR * 0.98)
            if pos + n >= total: n = total - pos - 1
            if n <= 0: continue
            w = (tone(f, n / SR) * 0.5 + tone(f * 1.005, n / SR) * 0.5)
            out[pos:pos + n] += w * env(n, 0.25, dur_b * beat * 0.55, 0.7) * 0.16
        # bass
        for k in range(dur_b * 2):
            f = hz(deg, -1)
            n = int(beat * 0.5 * SR * 0.92)
            p2 = pos + int(k * beat * 0.5 * SR)
            if p2 + n >= total: n = total - p2 - 1
            if n <= 0: break
            out[p2:p2 + n] += tone(f, n / SR, "tri") * env(n, 0.004, beat * 0.24, 2.2) * 0.34
        # lead arpeggio (8ths)
        for k in range(dur_b * 2):
            deg_l = deg + int(r.choice([0, 2, 4, 6, 7]))
            f = hz(deg_l, 1)
            n = int(beat * 0.5 * SR * 0.9)
            p2 = pos + int(k * beat * 0.5 * SR)
            if p2 + n >= total: n = total - p2 - 1
            if n <= 0: break
            out[p2:p2 + n] += tone(f, n / SR, "sin") * env(n, 0.003, beat * 0.22, 2.4) * 0.14 * (0.7 + bright * 0.6)
    save(name, out, 0.72, dmg_dir=MUS)

music("inv_tour.wav", 112, 16, 220.0, minor=True, bright=0.5, seed=5)     # the tour: solemn, driven
music("inv_finale.wav", 140, 16, 196.0, minor=True, bright=0.95, seed=9)  # the hideout: faster, hot
print("done - invaders voices + music")
