#!/usr/bin/env python3
"""v0.3.5-3 POP SIEGE sound engine v2 (the owner's SFX round: "broken and
not matching" is dead). Same file names - only the synthesis changed:

- ONE-POLE LOWPASS noise everywhere (the raw white-noise static is dead)
- brown integrated noise for boom bodies (real air-push, not hiss)
- pops: clean squeak-thump with a soft click (no raw crack)
- shots: characterful but SOFT - airy swish, tight crack, warm roar

Regenerates only the ps_* set. Music untouched."""
import io, os, struct
import numpy as np

REPO = "/home/z/my-project/repo/GOGABox"
SFX = f"{REPO}/projects/gogabox/assets/audio/sfx"
SR = 22050

def wav(name, data, vol=0.5, out=SFX):
    data = np.asarray(data, dtype=np.float32)
    data = np.clip(data * vol, -1, 1)
    pcm = (data * 32767).astype(np.int16)
    buf = io.BytesIO()
    n = len(pcm)
    buf.write(b"RIFF"); buf.write(struct.pack("<I", 36 + n * 2)); buf.write(b"WAVE")
    buf.write(b"fmt "); buf.write(struct.pack("<IHHIIHH", 16, 1, 1, SR, SR * 2, 2, 16))
    buf.write(b"data"); buf.write(struct.pack("<I", n * 2)); buf.write(pcm.tobytes())
    with open(f"{out}/{name}.wav", "wb") as f:
        f.write(buf.getvalue())

def t(dur):
    return np.linspace(0, dur, int(SR * dur), dtype=np.float32)

def dec(dur, k):
    return np.exp(-t(dur) * k)

def env(n, a=0.004, r=0.05):
    e = np.ones(n, dtype=np.float32)
    na, nr = max(1, int(a * SR)), max(1, int(r * SR))
    e[:na] = np.linspace(0, 1, na)
    e[-nr:] *= np.linspace(1, 0, nr)
    return e

def sweep(f0, f1, dur, shape="sin"):
    tt = t(dur)
    f = f0 + (f1 - f0) * (tt / dur)
    ph = np.cumsum(2 * np.pi * f / SR)
    if shape == "tri":
        return ((ph / np.pi) % 2 - 1) * 0.7
    if shape == "saw":
        return ((ph / (2 * np.pi)) % 1 - 0.5) * 1.2
    return np.sin(ph)

def lp(sig, cutoff, k=0.0):
    """one-pole lowpass; k = extra smoothing passes."""
    a = float(np.exp(-2 * np.pi * cutoff / SR))
    out = np.empty_like(sig)
    acc = 0.0
    for i, v in enumerate(sig):
        acc = (1 - a) * v + a * acc
        out[i] = acc
    for _ in range(int(k)):
        out = lp(out, cutoff)
    return out

def lpnoise(dur, cutoff):
    return lp(np.random.uniform(-1, 1, int(SR * dur)).astype(np.float32), cutoff)

def brown(dur, damp=6.0):
    n = np.random.uniform(-1, 1, int(SR * dur)).astype(np.float32)
    out = np.empty_like(n)
    acc = 0.0
    for i, v in enumerate(n):
        acc = acc * 0.985 + v * 0.10
        out[i] = acc
    out *= dec(dur, damp) / max(0.01, np.abs(out).max())
    return out

def note(freq, dur, shape="sin", vol=1.0):
    return (sweep(freq, freq, dur, shape) * env(int(SR * dur), 0.004, dur * 0.4)) * vol

def mixmax(*segs):
    n = max(len(s) for s in segs)
    out = np.zeros(n, dtype=np.float32)
    for s in segs:
        out[: len(s)] += s
    m = max(0.01, float(np.abs(out).max()))
    return out / m

# ---------------------------------------------------------------- THE POP
def pop(idx):
    """the pitch-ladder pop: clean squeak down + soft thump + tiny tick."""
    dur = 0.10 + idx * 0.005
    f0 = 760 + idx * 120
    body = sweep(f0, f0 * 0.42, dur) * dec(dur, 34)
    thump = sweep(170 + idx * 16, 64, 0.055) * dec(0.055, 52) * 0.9
    tick = lpnoise(0.014, 3800) * dec(0.014, 220) * 0.5
    return mixmax(body, thump, tick)

def make_sfx():
    for i in range(5):
        wav(f"ps_pop{i}", pop(i), 0.60)
    # THE BOOM: sub thump + brown push + a soft crack - the real air move
    def boom(dur, f0, f1, k):
        sub = sweep(f0, f1, dur, "sin") * dec(dur, k) * 1.1
        push = brown(dur, k * 0.9)
        crack = lpnoise(0.05, 2600) * dec(0.05, 60) * 0.5
        return mixmax(sub, push, crack)
    wav("ps_boom", boom(0.5, 120, 34, 7.5), 0.8)
    wav("ps_moab_pop", boom(0.85, 90, 26, 4.5), 0.85)
    # UI + placement
    wav("ps_click", mixmax(note(660, 0.05, "sin"), note(990, 0.05, "sin", 0.5)), 0.36)
    wav("ps_tick_ok", note(760, 0.05, "sin"), 0.30)
    wav("ps_tick_bad", mixmax(note(170, 0.1, "saw"), note(120, 0.1, "saw", 0.6)), 0.34)
    wav("ps_place", mixmax(sweep(280, 500, 0.12) * dec(0.12, 14), lpnoise(0.06, 1800) * dec(0.06, 50) * 0.4), 0.46)
    wav("ps_sell", sweep(620, 300, 0.15, "tri") * dec(0.15, 12), 0.4)
    arp = np.concatenate([note(f, 0.09, "tri", 0.9) for f in (523, 659, 784)])
    wav("ps_upgrade", arp, 0.46)
    fan = np.concatenate([note(f, 0.15, "tri", 0.85) for f in (392, 523, 659, 1046)])
    wav("ps_gearup", mixmax(fan, note(1568, 0.3, "sin", 0.4), boom(0.3, 140, 60, 12) * 0.5), 0.52)
    # THE SHOTS: soft, characterful, matching what the eye sees
    wav("ps_shoot_dart", mixmax(lpnoise(0.07, 3200) * dec(0.07, 46) * 0.9,
                                sweep(880, 420, 0.06) * dec(0.06, 55) * 0.7), 0.32)
    wav("ps_shoot_sniper", mixmax(lpnoise(0.05, 4200) * dec(0.05, 80) * 1.2,
                                  sweep(190, 70, 0.09, "sin") * dec(0.09, 42) * 1.1,
                                  sweep(1500, 300, 0.05) * dec(0.05, 90) * 0.5), 0.5)
    fl = lpnoise(0.26, 900)
    fl *= dec(0.26, 9) * env(len(fl), 0.03, 0.1)
    wav("ps_shoot_flame", mixmax(fl * 1.2, sweep(200, 130, 0.26, "tri") * dec(0.26, 8) * 0.5), 0.36)
    goo = mixmax(sweep(360, 120, 0.11, "sin") * dec(0.11, 22), lpnoise(0.03, 1100) * dec(0.03, 90) * 0.6)
    wav("ps_shoot_goo", goo, 0.4)
    wav("ps_shoot_bomb", mixmax(sweep(200, 74, 0.2, "tri") * dec(0.2, 13) * 1.2,
                                lpnoise(0.08, 700) * dec(0.08, 30) * 0.7), 0.5)
    zc = lpnoise(0.09, 5000) * dec(0.09, 30)
    zspike = zc * (np.random.uniform(0, 1, len(zc)) > 0.82).astype(np.float32)
    wav("ps_shoot_zap", mixmax(zspike * 1.6, sweep(1900, 500, 0.09, "sin") * dec(0.09, 30) * 0.8), 0.34)
    wr = sweep(480, 720, 0.12, "tri") * dec(0.12, 12)
    wob = wr * (1.0 + 0.35 * np.sin(t(0.12) * 90))
    wav("ps_shoot_rang", wob, 0.32)
    # hits / states
    wav("ps_freeze", mixmax(note(1720, 0.09, "sin", 0.7), note(2300, 0.13, "sin", 0.5),
                            lpnoise(0.16, 6500) * dec(0.16, 22) * 0.5), 0.3)
    wav("ps_splat", mixmax(sweep(250, 84, 0.1) * dec(0.1, 26), lpnoise(0.05, 900) * dec(0.05, 60) * 0.7), 0.42)
    bn = lpnoise(0.24, 600)
    wav("ps_burn", mixmax(bn * dec(0.24, 8) * 1.1, sweep(150, 110, 0.24, "tri") * dec(0.24, 7) * 0.4), 0.28)
    wav("ps_teleport", sweep(220, 1700, 0.19) * dec(0.19, 10), 0.36)
    wav("ps_trap", mixmax(note(500, 0.06, "tri"), sweep(280, 110, 0.1) * 0.5), 0.36)
    # coins / hearts / waves
    wav("ps_coin", mixmax(note(1245, 0.06, "sin", 0.9), note(1865, 0.15, "sin", 0.75)), 0.36)
    wav("ps_gogacoin", np.concatenate([note(f, 0.11, "tri", 0.9) for f in (1046, 1318, 1568)]), 0.46)
    wav("ps_egg", np.concatenate([note(f, 0.1, "sin", 0.8) for f in (880, 1108, 1318, 1760)]), 0.42)
    wav("ps_leak", mixmax(sweep(400, 150, 0.3, "tri") * dec(0.3, 8), note(98, 0.24, "sin", 0.5)), 0.46)
    wav("ps_horn", mixmax(note(196, 0.32, "saw", 0.55), note(294, 0.32, "saw", 0.4),
                          note(392, 0.32, "saw", 0.25)), 0.4)
    wav("ps_wave_boss", mixmax(note(98, 0.7, "saw", 0.8), note(147, 0.7, "saw", 0.5),
                               boom(0.7, 70, 30, 5) * 0.8), 0.55)
    wav("ps_victory", np.concatenate([note(f, 0.17, "tri", 0.9) for f in (523, 659, 784, 1046, 1318)]), 0.5)
    wav("ps_lose", np.concatenate([note(f, 0.26, "tri", 0.75) for f in (392, 330, 262, 196)]), 0.46)
    print("sfx v3 ok - ps_* regenerated")

if __name__ == "__main__":
    make_sfx()
