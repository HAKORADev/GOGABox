#!/usr/bin/env python3
"""v037_tower_geo_audio.py - SNOWY TOWER's GEOMETRIC style audio (v0.3.7).

100% synthesized (numpy) - same law as every GOGABox sound. The geometric
style is Geoquare's home turf: the SFX are the Geometry Flash voice
(bright square chirps, bell pings, soft neon thuds) re-tuned for the tower
verbs, and the theme is a 118 BPM E-minor synthwave cousin of the gf_theme
(warrier, more glass) - 8 bars, seamless loop.

SFX (assets/audio/sfx/geo_*.wav): jump land coin break crack puff wall
slap pw pw_end fall
THEME (assets/audio/music/tower_geo_theme.ogg)

Re-derive: python3 tools/v037_tower_geo_audio.py
"""
import numpy as np
import os
import subprocess
import wave

SR = 44100
SFX_DIR = "projects/gogabox/assets/audio/sfx"
MUS_DIR = "projects/gogabox/assets/audio/music"


def write_wav(path, data, sr=SR):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = np.asarray(data)
    if data.ndim == 1:
        data = np.stack([data, data], axis=1)
    pcm = (np.clip(data, -1, 1) * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())
    print(f"  {os.path.basename(path):24s} {len(data)/sr:.2f}s")


def to_ogg(wav_path, quality="3"):
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path,
                    "-c:a", "libvorbis", "-q:a", quality,
                    wav_path.replace(".wav", ".ogg")], check=True)
    os.remove(wav_path)
    print(f"  {os.path.basename(wav_path).replace('.wav', '.ogg'):24s} done")


def t_axis(dur):
    return np.linspace(0, dur, int(SR * dur), endpoint=False)


def env(n, a, r, hold=1.0):
    x = np.ones(n)
    na, nr = max(1, int(a * SR)), max(1, int(r * SR))
    na, nr = min(na, n), min(nr, n)
    x[:na] = np.linspace(0, hold, na)
    x[-nr:] *= np.linspace(1, 0, nr)
    return x


def sine(f, dur, ph=0.0):
    return np.sin(2 * np.pi * f * t_axis(dur) + ph)


def square(f, dur, duty=0.5):
    return np.where((f * t_axis(dur)) % 1.0 < duty, 1.0, -1.0)


def tri(f, dur):
    return 2.0 * np.abs(2.0 * ((f * t_axis(dur)) % 1.0) - 1.0) - 1.0


def sweep(f0, f1, dur, kind="sine"):
    t = t_axis(dur)
    f = f0 + (f1 - f0) * (t / dur)
    ph = 2 * np.pi * np.cumsum(f) / SR
    if kind == "sine":
        return np.sin(ph)
    if kind == "square":
        return np.sign(np.sin(ph)) * 0.6
    return np.sin(ph)


def noise(dur):
    return np.random.uniform(-1, 1, int(SR * dur))


def lowpass(x, alpha):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def highpass(x, alpha):
    return x - lowpass(x, alpha)


def bell(f, dur, harm=(1.0, 0.5, 0.25), decay=6.0):
    t = t_axis(dur)
    out = np.zeros_like(t)
    for i, h in enumerate(harm):
        out += h * np.sin(2 * np.pi * f * (i + 1) * t) * np.exp(-decay * t / (i + 1))
    return out


def place(buf, at, x, gain=1.0):
    i0 = int(at * SR)
    i1 = min(len(buf), i0 + len(x))
    if i1 > i0:
        buf[i0:i1] += x[:i1 - i0] * gain


def add(buf, x, gain=1.0):
    """Add x into buf at 0, truncating the longer side."""
    n = min(len(buf), len(x))
    buf[:n] += x[:n] * gain


# ----------------------------------------------------------------- the sfx
def sfx_jump():
    d = 0.16
    d_i = int(SR * d)
    buf = sweep(340, 660, d, "square") * env(d_i, 0.006, 0.10)
    add(buf, sweep(680, 1320, d) * env(d_i, 0.004, 0.10), 0.25)
    return buf * 0.5


def sfx_land():
    d = 0.13
    d_i = int(SR * d)
    buf = sweep(190, 70, d) * env(d_i, 0.002, 0.11)
    add(buf, highpass(noise(d), 0.25) * env(d_i, 0.001, 0.05), 0.30)
    add(buf, bell(880, 0.07, decay=30.0), 0.16)
    return buf * 0.62


def sfx_coin():
    buf = np.zeros(int(SR * 0.42))
    for i, f in enumerate([1318, 1661, 2093]):
        place(buf, i * 0.055, bell(f, 0.24, decay=9.0), 0.55)
    return buf


def sfx_break():
    d = 0.34
    d_i = int(SR * d)
    buf = highpass(noise(d), 0.18) * env(d_i, 0.002, 0.28) * 0.8
    add(buf, sweep(300, 90, d, "square") * env(d_i, 0.002, 0.26), 0.35)
    add(buf, bell(523, 0.2, decay=14.0), 0.22)
    return lowpass(buf, 0.5) * 0.7


def sfx_crack():
    d = 0.12
    d_i = int(SR * d)
    buf = highpass(noise(d), 0.35) * env(d_i, 0.001, 0.09) * 0.7
    add(buf, square(2200, d) * env(d_i, 0.001, 0.08), 0.08)
    return buf * 0.6


def sfx_puff():
    d = 0.2
    x = lowpass(noise(d), 0.12) * env(int(SR * d), 0.004, 0.16)
    return x * 1.1


def sfx_wall():
    d = 0.1
    d_i = int(SR * d)
    buf = sweep(500, 240, d, "square") * env(d_i, 0.002, 0.07) * 0.4
    add(buf, noise(d) * env(d_i, 0.001, 0.05), 0.2)
    return lowpass(buf, 0.4) * 0.5


def sfx_slap():
    d = 0.09
    x = highpass(noise(d), 0.5) * env(int(SR * d), 0.001, 0.06)
    return x * 0.5


def sfx_pw():
    buf = np.zeros(int(SR * 0.5))
    for i, f in enumerate([659, 880, 1174]):
        place(buf, i * 0.06, square(f, 0.14, 0.4) * env(int(SR * 0.14), 0.004, 0.09), 0.30)
    place(buf, 0.18, bell(1760, 0.3, decay=8.0), 0.4)
    return buf


def sfx_pw_end():
    d = 0.3
    buf = sweep(700, 320, d, "square") * env(int(SR * d), 0.004, 0.2) * 0.22
    add(buf, bell(440, 0.24, decay=10.0), 0.2)
    return buf


def sfx_fall():
    d = 0.5
    d_i = int(SR * d)
    buf = sweep(600, 120, d) * env(d_i, 0.01, 0.34) * 0.5
    add(buf, lowpass(noise(d), 0.15) * env(d_i, 0.01, 0.4), 0.3)
    return buf * 0.8


# ---------------------------------------------------------------- the theme
def theme():
    """118 BPM E-minor synthwave, 8 bars, seamless: kick 4-on-floor, the
    offbeat hats, the sidechained 8th bass, the 16th arp lead (Em C G D)
    with one echo tap, glass bell sparkles. ~16.3s."""
    bpm = 118.0
    beat = 60.0 / bpm
    bars = 8
    dur = bars * 4 * beat
    n = int(SR * dur)
    L = np.zeros(n)
    R = np.zeros(n)

    kick_d = 0.16
    kick = sweep(150, 44, kick_d) * env(int(SR * kick_d), 0.001, 0.12)
    hat = highpass(noise(0.05), 0.6) * env(int(SR * 0.05), 0.001, 0.04) * 0.3
    bass_notes = {"E1": 41.2, "C1": 32.7, "G1": 49.0, "D1": 36.7}
    prog = ["E1", "C1", "G1", "D1"] * 2
    arp_root = {"E": [164.8, 196.0, 246.9, 329.6], "C": [130.8, 164.8, 196.0, 261.6],
                "G": [196.0, 246.9, 293.7, 392.0], "D": [146.8, 174.6, 220.0, 293.7]}
    prog_chords = ["E", "C", "G", "D"] * 2

    for b in range(bars * 4):
        at = b * beat
        place(L, at, kick, 0.9)
        place(R, at, kick, 0.9)
        place(L, at + beat * 0.5, hat, 0.7)
        place(R, at + beat * 0.5, hat * 0.8, 0.7)
        # the sidechained 8th bass
        bn = bass_notes[prog[b % len(prog)]]
        for e in range(2):
            ba = at + e * beat * 0.5
            bd = beat * 0.46
            bass = (sine(bn, bd) * 0.7 + sine(bn * 2, bd) * 0.2) \
                    * env(int(SR * bd), 0.004, 0.10)
            duck = 0.45 + 0.55 * np.exp(-np.arange(int(SR * bd)) / (0.05 * SR))
            place(L, ba, bass * duck, 0.42)
            place(R, ba, bass * duck, 0.42)

    # the 16th arp lead with one echo tap
    for bar in range(bars):
        chord = arp_root[prog_chords[bar % len(prog_chords)]]
        for s16 in range(16):
            at = bar * 4 * beat + s16 * beat * 0.25
            f = chord[[0, 1, 2, 3, 2, 1, 3, 2, 0, 2, 1, 3, 2, 3, 1, 2][s16]]
            ad = beat * 0.24
            lead = (square(f, ad, 0.35) * 0.4 + tri(f * 2, ad) * 0.2) \
                    * env(int(SR * ad), 0.004, 0.10)
            g = 0.16 if s16 % 4 == 0 else 0.11
            place(L, at, lead, g)
            place(R, at, lead * 0.9, g)
            place(L, at + beat * 0.75, lead, g * 0.35)   # the echo tap
            place(R, at + beat * 0.75, lead, g * 0.35)

    # the glass bell sparkles (bar ends)
    for bar in range(0, bars, 2):
        at = bar * 4 * beat + 3 * beat
        f = [1318.5, 987.8, 1568.0, 1174.7][(bar // 2) % 4]
        place(L, at, bell(f, 0.9, decay=3.5), 0.10)
        place(R, at + 0.02, bell(f * 1.5, 0.7, decay=4.0), 0.07)

    st = np.stack([L, R], axis=1)
    return 0.82 * st / max(1.0, np.max(np.abs(st)))


def main():
    print("v0.3.7 SNOWY TOWER geometric audio:")
    for name, fn in [("geo_jump", sfx_jump), ("geo_land", sfx_land),
                     ("geo_coin", sfx_coin), ("geo_break", sfx_break),
                     ("geo_crack", sfx_crack), ("geo_puff", sfx_puff),
                     ("geo_wall", sfx_wall), ("geo_slap", sfx_slap),
                     ("geo_pw", sfx_pw), ("geo_pw_end", sfx_pw_end),
                     ("geo_fall", sfx_fall)]:
        write_wav(os.path.join(SFX_DIR, name + ".wav"), fn())
    wav = os.path.join(MUS_DIR, "tower_geo_theme.wav")
    write_wav(wav, theme())
    to_ogg(wav, "4")


if __name__ == "__main__":
    main()
