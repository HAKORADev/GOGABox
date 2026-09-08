#!/usr/bin/env python3
"""v037_maze_audio.py - MAZE ESCAPER (v0.3.7) audio. 100% synthesized.

SFX (assets/audio/sfx/m_*.wav):
  move    a soft glass tick (the game pitch-ladders it with the queue)
  deny    a dull low bonk (a wall ate the input)
  win     the map chime (a bright 3-note rise)
  coin    the GOGACoin sparkle arpeggio
  finder  the shimmer (the path lights up)
  over    the timeout: a descending saw + sub (the clock wins)
  start   the run-start whoosh + stab
THEME (assets/audio/music/maze_theme.ogg): 108 BPM D-minor synth loop,
8 bars (~17.8s): soft kick, ticking hats, the walking 8th bass, a thinking
16th arp (Dm Bb F C) with echo, glass bells - the contemplative-but-driving
puzzle pulse.

Re-derive: python3 tools/v037_maze_audio.py
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
    print(f"  {os.path.basename(path):22s} {len(data)/sr:.2f}s")


def to_ogg(wav_path, quality="4"):
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path,
                    "-c:a", "libvorbis", "-q:a", quality,
                    wav_path.replace(".wav", ".ogg")], check=True)
    os.remove(wav_path)
    print(f"  {os.path.basename(wav_path).replace('.wav', '.ogg'):22s} done")


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


def add(buf, x, gain=1.0):
    n = min(len(buf), len(x))
    buf[:n] += x[:n] * gain


def place(buf, at, x, gain=1.0):
    i0 = int(at * SR)
    i1 = min(len(buf), i0 + len(x))
    if i1 > i0:
        buf[i0:i1] += x[:i1 - i0] * gain


def sfx_move():
    d = 0.07
    buf = sine(1150.0, d) * env(int(SR * d), 0.001, 0.05)
    add(buf, tri(2300.0, d), 0.25)
    return lowpass(buf, 0.6) * 0.5


def sfx_deny():
    d = 0.11
    buf = sweep(180, 90, d, "square") * env(int(SR * d), 0.002, 0.08) * 0.4
    add(buf, noise(d) * env(int(SR * d), 0.001, 0.06), 0.18)
    return lowpass(buf, 0.35) * 0.7


def sfx_win():
    buf = np.zeros(int(SR * 0.6))
    for i, f in enumerate([784, 988, 1319]):
        place(buf, i * 0.07, bell(f, 0.34, decay=7.0), 0.5)
    return buf


def sfx_coin():
    buf = np.zeros(int(SR * 0.42))
    for i, f in enumerate([1318, 1661, 2093]):
        place(buf, i * 0.055, bell(f, 0.24, decay=9.0), 0.55)
    return buf


def sfx_finder():
    buf = np.zeros(int(SR * 0.55))
    for i in range(6):
        f = 660.0 + 130.0 * i
        place(buf, i * 0.045, sine(f, 0.1) * env(int(SR * 0.1), 0.004, 0.06), 0.30)
    place(buf, 0.28, bell(1760.0, 0.3, decay=8.0), 0.35)
    return buf


def sfx_over():
    d = 0.8
    buf = sweep(440, 70, d, "saw") * env(int(SR * d), 0.01, 0.55) * 0.35
    add(buf, sweep(90, 40, d) * env(int(SR * d), 0.01, 0.5), 0.5)
    return lowpass(buf, 0.4) * 0.85


def sfx_start():
    buf = np.zeros(int(SR * 0.5))
    place(buf, 0.0, lowpass(noise(0.24), 0.2) * env(int(SR * 0.24), 0.01, 0.2), 0.5)
    place(buf, 0.16, square(392.0, 0.3, 0.4) * env(int(SR * 0.3), 0.005, 0.2), 0.28)
    place(buf, 0.16, bell(784.0, 0.4, decay=6.0), 0.3)
    return buf


def theme():
    """108 BPM D-minor, 8 bars: soft kick, ticking hats, the walking 8th
    bass, the thinking 16th arp (Dm Bb F C) with echo, glass bells."""
    bpm = 108.0
    beat = 60.0 / bpm
    bars = 8
    dur = bars * 4 * beat
    n = int(SR * dur)
    L = np.zeros(n)
    R = np.zeros(n)

    kick_d = 0.14
    kick = sweep(140, 42, kick_d) * env(int(SR * kick_d), 0.001, 0.10)
    hat = highpass(noise(0.045), 0.6) * env(int(SR * 0.045), 0.001, 0.035) * 0.28
    bass_notes = [73.4, 58.3, 87.3, 65.4]          # D2 Bb1 F2 C2
    arp_root = [[293.7, 349.2, 440.0, 587.3], [233.1, 293.7, 349.2, 466.2],
                [349.2, 440.0, 523.3, 698.5], [261.6, 329.6, 392.0, 523.3]]
    pat = [0, 1, 2, 3, 2, 1, 3, 2, 0, 2, 1, 3, 2, 3, 1, 2]

    for b in range(bars * 4):
        at = b * beat
        place(L, at, kick, 0.72)
        place(R, at, kick, 0.72)
        place(L, at + beat * 0.5, hat, 0.6)
        place(R, at + beat * 0.5, hat * 0.85, 0.6)
        bn = bass_notes[(b // 4) % 4]
        for e in range(2):
            ba = at + e * beat * 0.5
            bd = beat * 0.48
            bass = (sine(bn, bd) * 0.7 + sine(bn * 2, bd) * 0.18) \
                    * env(int(SR * bd), 0.005, 0.12)
            duck = 0.5 + 0.5 * np.exp(-np.arange(int(SR * bd)) / (0.055 * SR))
            place(L, ba, bass * duck, 0.40)
            place(R, ba, bass * duck, 0.40)

    for bar in range(bars):
        chord = arp_root[bar % 4]
        for s16 in range(16):
            at = bar * 4 * beat + s16 * beat * 0.25
            f = chord[pat[s16]]
            ad = beat * 0.26
            lead = (tri(f, ad) * 0.5 + sine(f * 2, ad) * 0.2) \
                    * env(int(SR * ad), 0.004, 0.11)
            g = 0.15 if s16 % 4 == 0 else 0.10
            place(L, at, lead, g)
            place(R, at, lead * 0.92, g)
            place(L, at + beat * 0.75, lead, g * 0.33)
            place(R, at + beat * 0.75, lead, g * 0.33)

    for bar in range(0, bars, 2):
        at = bar * 4 * beat + 3 * beat
        f = [1174.7, 932.3, 1396.9, 1046.5][(bar // 2) % 4]
        place(L, at, bell(f, 0.9, decay=3.5), 0.09)
        place(R, at + 0.02, bell(f * 1.5, 0.7, decay=4.0), 0.06)

    st = np.stack([L, R], axis=1)
    return 0.82 * st / max(1.0, np.max(np.abs(st)))


def main():
    print("v0.3.7 MAZE ESCAPER audio:")
    for name, fn in [("m_move", sfx_move), ("m_deny", sfx_deny),
                     ("m_win", sfx_win), ("m_coin", sfx_coin),
                     ("m_finder", sfx_finder), ("m_over", sfx_over),
                     ("m_start", sfx_start)]:
        write_wav(os.path.join(SFX_DIR, name + ".wav"), fn())
    wav = os.path.join(MUS_DIR, "maze_theme.wav")
    write_wav(wav, theme())
    to_ogg(wav)


if __name__ == "__main__":
    main()
