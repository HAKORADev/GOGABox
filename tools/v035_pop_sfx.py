#!/usr/bin/env python3
"""v0.3.5 POP SIEGE sound engine - all synthesized (the repo way).
The pop is the star: a layered squeak-thump with a pitch ladder by bloon layer.
Outputs: projects/gogabox/assets/audio/sfx/ps_*.wav + assets/audio/music/ps_theme.wav
"""
import io, os, struct
import numpy as np

REPO = "/home/z/my-project/repo/GOGABox"
SFX = f"{REPO}/projects/gogabox/assets/audio/sfx"
MUS = f"{REPO}/assets/audio/music".replace("/assets/audio/music", "/projects/gogabox/assets/audio/music")
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
    os.makedirs(out, exist_ok=True)
    with open(f"{out}/{name}.wav", "wb") as f:
        f.write(buf.getvalue())

def t(dur):
    return np.linspace(0, dur, int(SR * dur), dtype=np.float32)

def env(n, a=0.005, r=0.08):
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

def noise(dur):
    return np.random.uniform(-1, 1, int(SR * dur)).astype(np.float32)

def note(freq, dur, shape="tri", vol=1.0):
    return (sweep(freq, freq, dur, shape) * env(int(SR * dur), 0.004, dur * 0.4)) * vol

# ---------------------------------------------------------------- THE POP
def mixmax(*segs):
    n = max(len(s) for s in segs)
    out = np.zeros(n, dtype=np.float32)
    for s in segs:
        out[: len(s)] += s
    return out

def pop(idx):
    """the pitch-ladder pop: squeak down + thump + click. idx 0..4 climbs."""
    dur = 0.09 + idx * 0.004
    f0 = 780 + idx * 130
    body = sweep(f0, f0 * 0.45, dur) * np.exp(-t(dur) * 42)
    click = noise(0.012) * np.exp(-t(0.012) * 260) * 0.9
    thump = sweep(190 + idx * 18, 70, 0.05) * np.exp(-t(0.05) * 60) * 0.8
    n = max(len(body), len(click), len(thump))
    mix = mixmax(body, click, thump)
    return mix * 1.5

def make_sfx():
    for i in range(5):
        wav(f"ps_pop{i}", pop(i), 0.62)
    # big bloon pops
    wav("ps_pop_big", np.concatenate([pop(2), pop(0) * 0.7]), 0.66)
    wav("ps_moab_pop", mixmax(sweep(300, 60, 0.5) * np.exp(-t(0.5) * 7), noise(0.5) * np.exp(-t(0.5) * 9) * 0.6), 0.8)
    # UI + placement
    wav("ps_click", mixmax(note(660, 0.06, "sin", 1.0), note(880, 0.05, "sin", 0.6)), 0.4)
    wav("ps_tick_ok", note(720, 0.045, "sin"), 0.34)
    wav("ps_tick_bad", note(180, 0.09, "saw"), 0.4)
    wav("ps_place", sweep(300, 520, 0.14) * np.exp(-t(0.14) * 16), 0.5)
    wav("ps_sell", sweep(640, 320, 0.16, "tri") * np.exp(-t(0.16) * 14), 0.45)
    # upgrades
    arp = np.concatenate([note(f, 0.09, "tri", 0.9) for f in (523, 659, 784)])
    wav("ps_upgrade", arp, 0.5)
    fan = np.concatenate([note(f, 0.16, "saw", 0.8) for f in (392, 523, 659, 1046)])
    wav("ps_gearup", mixmax(fan, note(1568, 0.3, "tri", 0.5)), 0.55)
    # shots
    wav("ps_shoot_dart", sweep(900, 400, 0.07) * np.exp(-t(0.07) * 50), 0.34)
    wav("ps_shoot_sniper", mixmax(noise(0.06) * np.exp(-t(0.06) * 90), sweep(1400, 200, 0.06) * 0.5), 0.5)
    wav("ps_shoot_flame", mixmax(noise(0.22) * np.exp(-t(0.22) * 11) * 0.8, sweep(220, 140, 0.22, "saw") * 0.3), 0.4)
    wav("ps_shoot_ice", mixmax(sweep(1600, 900, 0.12, "sin") * np.exp(-t(0.12) * 20), note(2400, 0.08, "sin", 0.4)), 0.36)
    wav("ps_shoot_goo", sweep(340, 130, 0.12) * np.exp(-t(0.12) * 24), 0.4)  # single
    wav("ps_shoot_bomb", sweep(220, 90, 0.18, "tri") * np.exp(-t(0.18) * 18), 0.5)
    wav("ps_shoot_zap", mixmax(noise(0.1) * 0.4, sweep(2200, 600, 0.1, "saw") * 0.7) * np.exp(-t(0.1) * 26), 0.4)
    wav("ps_shoot_rang", sweep(500, 700, 0.1, "tri") * np.exp(-t(0.1) * 14), 0.35)
    # hits / states
    wav("ps_boom", mixmax(sweep(150, 40, 0.42) * np.exp(-t(0.42) * 8), noise(0.42) * np.exp(-t(0.42) * 10) * 0.7), 0.85)
    wav("ps_freeze", mixmax(note(1800, 0.1, "sin", 0.7), note(2400, 0.14, "sin", 0.5), note(3000, 0.18, "sin", 0.35)), 0.34)
    wav("ps_splat", mixmax(sweep(260, 90, 0.1) * np.exp(-t(0.1) * 30), noise(0.05) * 0.3), 0.45)
    wav("ps_burn", mixmax(noise(0.25) * np.exp(-t(0.25) * 9) * 0.5, sweep(160, 120, 0.25, "saw") * 0.25), 0.3)
    wav("ps_teleport", sweep(200, 1900, 0.2, "sin") * np.exp(-t(0.2) * 12), 0.42)
    wav("ps_trap", mixmax(note(520, 0.06, "tri"), sweep(300, 120, 0.1) * 0.6), 0.42)
    # coins / hearts / waves
    wav("ps_coin", mixmax(note(1245, 0.07, "sin", 0.9), note(1865, 0.16, "sin", 0.8)), 0.4)
    wav("ps_gogacoin", np.concatenate([note(f, 0.12, "tri", 0.9) for f in (1046, 1318, 1568)]) , 0.5)
    wav("ps_egg", np.concatenate([note(f, 0.1, "sin", 0.8) for f in (880, 1108, 1318, 1760)]), 0.45)
    wav("ps_leak", sweep(420, 160, 0.3, "tri") * np.exp(-t(0.3) * 9), 0.5)
    wav("ps_horn", mixmax(note(196, 0.34, "saw", 0.7), note(294, 0.34, "saw", 0.5)), 0.45)
    wav("ps_wave_boss", mixmax(note(98, 0.7, "saw", 0.9), note(147, 0.7, "saw", 0.6), noise(0.7) * 0.12), 0.6)
    wav("ps_victory", np.concatenate([note(f, 0.18, "tri", 0.9) for f in (523, 659, 784, 1046, 1318)]), 0.55)
    wav("ps_lose", np.concatenate([note(f, 0.26, "saw", 0.7) for f in (392, 330, 262, 196)]), 0.5)
    print("sfx ok:", len(os.listdir(SFX)), "files in sfx/")

# ---------------------------------------------------------------- MUSIC
def make_music():
    bpm = 112
    beat = 60.0 / bpm
    bars = 16
    total = bars * 4 * beat
    n = int(SR * total)
    mix = np.zeros(n, dtype=np.float32)
    # I-V-vi-IV in D (happy march): D A Bm G
    chords = [(146.8, 220.0, 293.7), (110.0, 164.8, 220.0), (123.5, 185.0, 246.9), (98.0, 146.8, 196.0)]
    for bar in range(bars):
        ch = chords[(bar // 2) % 4]
        t0 = int(bar * 4 * beat * SR)
        # bass: root on beats
        for b in range(4):
            s = t0 + int(b * beat * SR)
            seg = note(ch[0] / 2, beat * 0.9, "tri", 0.5)
            e = min(n, s + len(seg)); mix[s:e] += seg[:e - s]
        # pluck arp (offbeat charm)
        for b in range(8):
            f = ch[int(b / 3) % 3] * 2
            s = t0 + int(b * beat * 0.5 * SR)
            seg = note(f, beat * 0.42, "tri", 0.34 if b % 2 else 0.5)
            e = min(n, s + len(seg)); mix[s:e] += seg[:e - s]
        # snare-ish backbeat
        for b in (1, 3):
            s = t0 + int(b * beat * SR)
            seg = noise(0.05) * np.exp(-t(0.05) * 90) * 0.5
            e = min(n, s + len(seg)); mix[s:e] += seg[:e - s]
    # melody: a simple recurring hook (D major pentatonic)
    hook = [(587.3, 1), (659.3, 1), (740.0, 2), (659.3, 1), (587.3, 1), (493.9, 2),
            (523.3, 1), (587.3, 1), (659.3, 2), (587.3, 1), (493.9, 1), (440.0, 2)]
    tpos = 0
    for rep in range(2):
        for f, beats in hook:
            s = int((rep * 8 + (tpos)) * beat * SR) % n
            seg = note(f * (2 if rep == 1 else 1), beat * beats * 0.92, "sin", 0.3)
            e = min(n, s + len(seg)); mix[s:e] += seg[:e - s]
            tpos = (tpos + beats) % 8
    mix *= env(n, 0.01, 0.4)
    # gentle loop-point crossfade so it loops clean
    xf = int(0.35 * SR)
    fade = np.linspace(0, 1, xf, dtype=np.float32)
    mix[:xf] = mix[:xf] * fade + mix[-xf:] * (1 - fade)
    wav("ps_theme", mix[: n - xf], 0.8, MUS)
    print("music ok")

if __name__ == "__main__":
    make_sfx()
    make_music()
