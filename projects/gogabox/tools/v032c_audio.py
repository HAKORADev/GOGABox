#!/usr/bin/env python3
# v0.3.2 PATCH III - THE PRESENCE PASS (the owner: "why there is no musics?"
# + "the SFXs are lite, they do not feel like we are saving the solar system").
# The tour + finale loops are rebuilt as REAL arrangements: stereo 44.1k,
# drums (kick/snare/hat), driving saw bass, wide pads, echoing lead. The
# combat voices get sub bodies, noise blast layers and longer tails.
# Same filenames -> zero code changes. Deterministic.
import os, wave
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(ROOT, "assets", "audio", "sfx")
MUS = os.path.join(ROOT, "assets", "audio", "music")
SR = 44100
rng = np.random.default_rng(322)

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
    return np.sign(np.sin(ph)) * np.abs(np.sin(ph))

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
    if x.ndim == 1:
        pcm = (x * 32767).astype(np.int16)
        ch = 1
    else:
        pcm = (x.T * 32767).astype(np.int16)
        ch = 2
    p = os.path.join(dmg_dir, name)
    with wave.open(p, "wb") as w:
        w.setnchannels(ch); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("  wrote", name, f"{len(x)/SR:.2f}s {os.path.getsize(p)//1024}KB")

# ================================================================ the music
def drum_kick(dur=0.22):
    body = sweep(130.0, 38.0, dur) * env(int(dur * SR), 0.001, 0.14, 3.2)
    click = lowpass(noise(dur), 0.4) * env(int(dur * SR), 0.001, 0.015, 5) * 0.5
    return body * 1.0 + click

def drum_snare(dur=0.16):
    n = int(dur * SR)
    nz = noise(dur) * env(n, 0.001, 0.055, 3.5)
    body = tone(190.0, dur) * env(n, 0.001, 0.03, 4) * 0.5
    return nz * 0.85 + body

def drum_hat(dur=0.05, open_=False):
    n = int(dur * SR)
    hp = noise(dur) - lowpass(noise(dur), 0.55)
    return hp * env(n, 0.001, 0.09 if open_ else 0.02, 4) * 0.55

def music(name, bpm, bars, root, minor=True, bright=0.5, seed=5, drums=True):
    r = np.random.default_rng(seed)
    beat = 60.0 / bpm
    bar = beat * 4
    total = int(bar * bars * SR)
    L = np.zeros(total); R = np.zeros(total)
    scale = [0, 2, 3, 5, 7, 8, 10] if minor else [0, 2, 4, 5, 7, 9, 11]
    chord_prog = [(0, 4), (5, 2), (3, 2), (4, 4)] if minor else [(0, 4), (3, 4), (4, 4), (5, 4)]
    def hz(deg, octv=0):
        s = scale[deg % 7] + 12 * (deg // 7)
        return root * (2 ** ((s + 12 * octv) / 12.0))
    def put(sig, pos, pan=0.0, g=1.0):
        n = min(len(sig), total - pos)
        if n <= 0: return
        L[pos:pos + n] += sig[:n] * g * (1.0 - max(pan, 0.0) * 0.5)
        R[pos:pos + n] += sig[:n] * g * (1.0 - max(-pan, 0.0) * 0.5)
    lead_buf = np.zeros(total)   # the lead rides a feedback echo
    for b in range(bars):
        pos = int(b * bar * SR)
        deg, dur_b = chord_prog[b % len(chord_prog)]
        # THE PAD: three detuned voices, wide
        for off, pan in ((0, -0.5), (2, 0.5), (4, 0.0), (7, -0.2)):
            f = hz(deg + off, 0)
            n = int(dur_b * beat * SR * 0.98)
            if n <= 0 or pos + n >= total: continue
            w = (tone(f, n / SR) * 0.4 + tone(f * 1.004, n / SR) * 0.4
                 + tone(f * 0.996, n / SR, "tri") * 0.2)
            put(w * env(n, 0.3, dur_b * beat * 0.6, 0.6), pos, pan, 0.20)
        # THE BASS: driving 8ths, saw + sub
        for k in range(dur_b * 2):
            f = hz(deg, -1)
            n = int(beat * 0.5 * SR * 0.9)
            p2 = pos + int(k * beat * 0.5 * SR)
            if p2 + n >= total: break
            bw = tone(f, n / SR, "saw") * 0.45 + tone(f / 2.0, n / SR) * 0.55
            put(lowpass(bw, 0.35) * env(n, 0.004, beat * 0.2, 2.4), p2, 0.0, 0.42)
        # THE LEAD: brighter arpeggio into the echo buffer
        for k in range(dur_b * 2):
            if r.random() < 0.18: continue     # breathe
            deg_l = deg + int(r.choice([0, 2, 4, 6, 7]))
            f = hz(deg_l, 1)
            n = int(beat * 0.5 * SR * 0.88)
            p2 = pos + int(k * beat * 0.5 * SR)
            if p2 + n >= total: break
            lw = (tone(f, n / SR) * 0.6 + tone(f * 2.0, n / SR, "tri") * 0.25)
            put(lw * env(n, 0.003, beat * 0.18, 2.6), p2, 0.3 if k % 2 else -0.3,
                0.17 * (0.7 + bright * 0.6))
        # THE DRUMS: the drive
        if drums:
            for k in range(4):
                put(drum_kick(), pos + int(k * beat * SR), 0.0, 0.85)
            for k in (1, 3):
                put(drum_snare(), pos + int(k * beat * SR), 0.05, 0.5)
            for k in range(8):
                put(drum_hat(0.05, open_=(k == 7)),
                    pos + int(k * beat * 0.5 * SR), -0.2 if k % 2 else 0.2, 0.34)
    # the lead's echo: two feedback taps
    d1 = int(beat * 0.75 * SR)
    echo = np.zeros(total)
    echo[d1:] += lead_buf[:-d1] * 0.42
    d2 = d1 * 2
    echo[d2:] += lead_buf[:-d2] * 0.2
    L += echo * 0.9; R += np.roll(echo, int(0.0011 * SR)) * 0.9
    st = np.stack([L, R], axis=1)
    # soft clip warmth
    st = np.tanh(st * 1.25)
    save(name, st, 0.78, dmg_dir=MUS)

# the tour: solemn but DRIVEN - a fleet marching to war
music("inv_tour.wav", 118, 16, 220.0, minor=True, bright=0.6, seed=5)
# the hideout: faster, hotter - the throne room
music("inv_finale.wav", 148, 16, 196.0, minor=True, bright=1.0, seed=9, drums=True)

# ================================================================ the voices
def shot(name, f0, f1, dur, wave="sin", noise_amt=0.0, a=0.002, r=0.05, sub=0.0, gain=0.75):
    body = sweep(f0, f1, dur, wave)
    x = body * env(len(body), a, r, 2.2)
    if noise_amt > 0:
        x = x * (1 - noise_amt) + lowpass(noise(dur), 0.5) * noise_amt * env(len(body), a, r * 0.6, 3)
    if sub > 0.0:
        sd = dur * 0.8
        ns = int(sd * SR)
        x[:ns] = x[:ns] + sweep(f0 / 4.0, f1 / 5.0, sd) * env(ns, a, r * 1.4, 2.0) * sub
    save(name, x, gain)

def boom(name, dur, sub_f0, sub_f1, crackle=1.0, gain=0.9):
    n = int(dur * SR)
    x = sweep(sub_f0, sub_f1, dur) * env(n, 0.002, dur * 0.55, 1.6)
    x += lowpass(noise(dur), 0.28) * env(n, 0.001, dur * 0.4, 2.4) * 0.85
    x += lowpass(noise(dur), 0.75) * env(n, 0.001, dur * 0.12, 4) * 0.5 * crackle
    save(name, x, gain)

# the seven weapon voices - each keeps its color, all gain a body
shot("inv_shoot_azure.wav", 880, 520, 0.10, "sin", 0.10, sub=0.35)
shot("inv_shoot_ember.wav", 620, 300, 0.13, "saw", 0.30, sub=0.3)
shot("inv_shoot_verdant.wav", 300, 190, 0.16, "sin", 0.12, sub=0.45)
shot("inv_shoot_phantom.wav", 1150, 700, 0.07, "sqr", 0.22, r=0.03, sub=0.25, gain=0.62)
shot("inv_shoot_hornet.wav", 480, 210, 0.18, "saw", 0.35, sub=0.4)
shot("inv_shoot_veteran.wav", 700, 320, 0.24, "tri", 0.18, r=0.1, sub=0.5)
shot("inv_shoot_titan.wav", 260, 90, 0.5, "saw", 0.4, r=0.16, sub=0.7, gain=0.9)

# the war voices - the weight
boom("inv_boom_small.wav", 0.42, 220, 46, 0.7, 0.85)
boom("inv_boom_big.wav", 1.15, 150, 26, 1.0, 0.95)
boom("inv_bomb_boom.wav", 0.8, 180, 34, 0.9, 0.92)
shot("inv_bomb_drop.wav", 500, 160, 0.3, "sin", 0.2, sub=0.4, gain=0.7)
shot("inv_thunder.wav", 2400, 90, 0.55, "saw", 0.65, a=0.001, r=0.2, sub=0.6, gain=0.9)
shot("inv_hit.wav", 1500, 900, 0.06, "sqr", 0.3, r=0.025, gain=0.5)
shot("inv_hurt.wav", 200, 60, 0.4, "saw", 0.5, sub=0.8, gain=0.95)
# THE BREACH: the alarm - two rising sirens over a sub drop
n = int(1.4 * SR)
sir = sweep(420, 880, 0.7) * env(int(0.7 * SR), 0.02, 0.5, 0.8)
sir2 = sweep(380, 800, 0.7) * env(int(0.7 * SR), 0.02, 0.5, 0.8)
bx = sweep(120, 30, 1.4) * env(n, 0.002, 0.9, 1.4)
al = np.zeros(n); al[:len(sir)] += sir; al[int(0.7 * SR):int(0.7 * SR) + len(sir2)] += sir2
save("inv_breach.wav", al * 0.9 + bx, 0.95)
# the bosses: a riser + a hit for in, a falling whoosh for out
ris = sweep(60, 520, 0.9, "saw") * env(int(0.9 * SR), 0.05, 0.12, 1.2)
ris += lowpass(noise(0.9), 0.3) * env(int(0.9 * SR), 0.02, 0.2, 1.5) * 0.5
n2 = int(1.5 * SR)
big = sweep(140, 28, 1.5) * env(n2, 0.002, 1.0, 1.5)
boss_in = np.zeros(n2)
boss_in[:len(ris)] += ris
tail0 = len(ris)
boss_in[tail0:tail0 + (n2 - tail0)] += big[:n2 - tail0]
save("inv_boss_in.wav", boss_in, 0.92)
outw = sweep(700, 70, 1.1, "saw") * env(int(1.1 * SR), 0.01, 0.5, 1.4)
outw += lowpass(noise(1.1), 0.4) * env(int(1.1 * SR), 0.01, 0.4, 2) * 0.4
save("inv_boss_out.wav", outw, 0.8)
# the win: a rising third fanfare with weight
fw = np.concatenate([tone(392, 0.14) * env(int(0.14 * SR), 0.004, 0.1, 2),
                     tone(523, 0.14) * env(int(0.14 * SR), 0.004, 0.1, 2),
                     tone(659, 0.34) * env(int(0.34 * SR), 0.004, 0.24, 1.6)]) * 0.8
fw = fw + np.concatenate([tone(196, 0.62) * env(int(0.62 * SR), 0.004, 0.5, 1.4)])[:len(fw)] * 0.5
save("inv_win_stage.wav", fw, 0.8)
save("inv_wave.wav", sweep(180, 540, 0.5, "tri") * env(int(0.5 * SR), 0.02, 0.3, 1.6)
     + lowpass(noise(0.5), 0.35) * env(int(0.5 * SR), 0.01, 0.25, 2) * 0.3, 0.72)
save("inv_escape.wav", sweep(900, 60, 1.6, "saw") * env(int(1.6 * SR), 0.01, 0.8, 1.2), 0.85)
save("inv_over.wav", sweep(300, 45, 1.3, "tri") * env(int(1.3 * SR), 0.01, 0.7, 1.3)
     + tone(110, 1.3) * env(int(1.3 * SR), 0.01, 0.8, 1.1) * 0.4, 0.85)

# the small voices keep their old bodies (regenerate at the new presence)
def keep_old(names):
    pass
print("done - PATCH III presence pass")
