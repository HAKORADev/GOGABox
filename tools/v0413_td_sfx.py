#!/usr/bin/env python3
"""TOWER DESTROYER (v041-3) SFX forge - the td_* family + the theme loop.
Deterministic, idempotent (the box's forge law). THE SLIM AUDIO LAW: the
forge emits wav sources and converts to OGG (libvorbis q6) before it
finishes - assets/audio carries OGG only.
Voices: td_click, td_shot, td_hit, td_black, td_break, td_die, td_coin
        + td_theme (the 118bpm demolition loop, seamless).
"""
import numpy as np, wave, os, subprocess, sys

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "..", "projects", "gogabox", "assets", "audio")
SFX = os.path.join(OUT, "sfx")
MUS = os.path.join(OUT, "music")
os.makedirs(SFX, exist_ok=True)
os.makedirs(MUS, exist_ok=True)
rng = np.random.default_rng(20260923)


def env_exp(n, k):
    return np.exp(-np.linspace(0, k, n))


def tone(f, n, harmonics=((1, 1.0),), bend=1.0):
    t = np.arange(n) / SR
    out = np.zeros(n)
    for mult, amp in harmonics:
        freq = f * mult * np.linspace(1.0, bend, n)
        phase = 2 * np.pi * np.cumsum(freq) / SR
        out += amp * np.sin(phase)
    return out


def noise(n, lp=0.5):
    x = rng.standard_normal(n)
    y = np.zeros(n)
    acc = 0.0
    for i in range(n):
        acc += lp * (x[i] - acc)
        y[i] = acc
    return y / (np.abs(y).max() + 1e-9)


def write(name, data, gain=0.9):
    data = np.asarray(data, dtype=np.float64)
    m = np.abs(data).max()
    if m > 0:
        data = data / m * gain
    pcm = (data * 32767).astype(np.int16)
    wav_path = os.path.join(SFX, name + ".wav")
    with wave.open(wav_path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    ogg_path = os.path.join(SFX, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path,
                    "-c:a", "libvorbis", "-q:a", "6", ogg_path], check=True)
    os.remove(wav_path)
    print("  ", name + ".ogg", os.path.getsize(ogg_path))


# td_click - the soft UI tick
n = int(0.07 * SR)
write("td_click", tone(1900, n, ((1, 1.0), (2.7, 0.3))) * env_exp(n, 9), 0.5)

# td_shot - the cannon thump: a pitch-bent low body + a puff
n = int(0.16 * SR)
body = tone(150, n, ((1, 1.0), (2, 0.4), (3, 0.15)), bend=0.55)
puff = noise(int(0.03 * SR), 0.7) * env_exp(int(0.03 * SR), 7)
snd = body * env_exp(n, 6)
snd[:puff.size] += puff * 0.5
write("td_shot", snd, 0.62)

# td_hit - the colored chip: mid thunk + crunch
n = int(0.1 * SR)
snd = tone(420, n, ((1, 1.0), (2.4, 0.5)), bend=0.7) * env_exp(n, 7)
snd += noise(n, 0.35) * env_exp(n, 11) * 0.4
write("td_hit", snd, 0.6)

# td_black - the armor clang: inharmonic metal partials
n = int(0.3 * SR)
snd = (tone(523, n, ((1, 1.0),)) * 0.5 + tone(1079, n, ((1, 0.7),))
       + tone(1721, n, ((1, 0.45),)) + tone(2591, n, ((1, 0.25),)))
snd *= env_exp(n, 5)
write("td_black", snd, 0.55)

# td_break - the platform crumble: noise fall + low boom
n = int(0.42 * SR)
crumb = noise(n, 0.25) * env_exp(n, 4)
boom = tone(95, n, ((1, 1.0), (2, 0.5)), bend=0.6) * env_exp(n, 5)
write("td_break", crumb * 0.85 + boom, 0.8)

# td_die - the seat death: descending groan + crash
n = int(0.7 * SR)
groan = tone(220, n, ((1, 1.0), (1.5, 0.4)), bend=0.3) * env_exp(n, 3)
crash = noise(n, 0.4) * env_exp(n, 6) * 0.8
write("td_die", groan + crash, 0.85)

# td_coin - the bank: the box coin read (bright two-note rise)
n1 = int(0.09 * SR)
n2 = int(0.22 * SR)
a = tone(1318, n1, ((1, 1.0), (2, 0.4))) * env_exp(n1, 6)
b = tone(1760, n2, ((1, 1.0), (2, 0.4), (3, 0.2))) * env_exp(n2, 5)
snd = np.zeros(n1 + n2)
snd[:n1] += a
snd[n1:] += b
write("td_coin", snd, 0.6)

# td_theme - the demolition loop: 118bpm, bass ostinato + drums + stabs
bpm = 118.0
beat = 60.0 / bpm
bar = beat * 4
bars = 8
total = int(bar * bars * SR)
mus = np.zeros(total)
# bass ostinato (E minor-ish: E2 G2 A2 B2 walk)
roots = [82.41, 82.41, 98.0, 98.0, 110.0, 110.0, 123.47, 98.0]
for b8 in range(bars * 8):
    t0 = int(b8 * beat * 0.5 * SR)
    f = roots[(b8 // 2) % bars] * (2 if b8 % 4 == 3 else 1)
    n = int(beat * 0.42 * SR)
    seg = tone(f, n, ((1, 1.0), (2, 0.35), (0.5, 0.3)), bend=0.98)
    seg *= env_exp(n, 4)
    end = min(total, t0 + n)
    mus[t0:end] += seg[:end - t0] * 0.42
# the kick on every beat, the hat on the off-beats
for b4 in range(bars * 4):
    t0 = int(b4 * beat * SR)
    n = int(0.09 * SR)
    kick = tone(120, n, ((1, 1.0),), bend=0.4) * env_exp(n, 8)
    end = min(total, t0 + n)
    mus[t0:end] += kick[:end - t0] * 0.6
    t0h = int((b4 + 0.5) * beat * SR)
    n = int(0.04 * SR)
    hat = noise(n, 0.9) * env_exp(n, 10)
    end = min(total, t0h + n)
    mus[t0h:end] += hat[:end - t0h] * 0.16
# the drill stabs: every bar's 3rd beat, a fifth stab
for bar_i in range(bars):
    t0 = int((bar_i * bar + beat * 2.5) * SR)
    n = int(beat * 0.9 * SR)
    stab = tone(roots[bar_i % bars] * 3.0, n,
                ((1, 1.0), (1.5, 0.6), (2, 0.3))) * env_exp(n, 5)
    end = min(total, t0 + n)
    mus[t0:end] += stab[:end - t0] * 0.2
m = np.abs(mus).max()
mus = mus / m * 0.72
pcm = (mus * 32767).astype(np.int16)
wav_path = os.path.join(MUS, "td_theme.wav")
with wave.open(wav_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(pcm.tobytes())
ogg_path = os.path.join(MUS, "td_theme.ogg")
subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path,
                "-c:a", "libvorbis", "-q:a", "6", ogg_path], check=True)
os.remove(wav_path)
print("   td_theme.ogg", os.path.getsize(ogg_path))
print("OK")
