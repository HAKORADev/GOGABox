#!/usr/bin/env python3
"""v040-11 DEADLY WORM - REAL MUSIC (the owner: the v040-10 beds are
"ugly and not real musics, they feel uncomfy").

Five place tracks, each a REAL piece: a drum kit (kick with a pitch
envelope, snare with a noise burst, hats), a driving bass line, detuned
chord pads, and a lead motif - arranged over 16 bars that loop seamlessly.
Each place wears its own key, tempo and mood:

  desert  - A minor  100bpm  the hunting groove
  polar   - D minor   82bpm  the cold drift
  city    - E minor  112bpm  the machines
  jungle  - G minor  104bpm  the skins and the roots
  kingdom - C minor   92bpm  the war march

All synthesis is additive/subtractive DSP written here - no samples, no
original bytes. Output: 44.1kHz 16-bit stereo WAV, loop-perfect.
"""
import math
import struct
import wave

SR = 44100
OUT = ("/home/z/my-project/gogabox/projects/gogabox"
       "/assets/audio/sfx")


def note_hz(semi):
    return 440.0 * (2.0 ** (semi / 12.0))


def saw(ph):
    return 2.0 * (ph - math.floor(ph + 0.5))


def square(ph):
    return 1.0 if (ph - math.floor(ph)) < 0.5 else -1.0


def tri(ph):
    f = ph - math.floor(ph)
    return 4.0 * abs(f - 0.5) - 1.0


def env_ad(t, a, d, sus=0.0):
    """attack-decay envelope with a sustain tail level"""
    if t < 0:
        return 0.0
    if t < a:
        return t / max(a, 1e-5)
    return sus + (1.0 - sus) * math.exp(-(t - a) / max(d, 1e-4))


class Track:
    def __init__(self):
        self.n = 0
        self.buf = []

    def add(self, start_s, dur_s, gen, vol=0.5, pan=0.0):
        i0 = int(start_s * SR)
        n = int(dur_s * SR)
        while len(self.buf) < i0 + n:
            self.buf.append([0.0, 0.0])
        for i in range(n):
            t = i / SR
            v = gen(t) * vol
            gl = v * (1.0 - max(0.0, pan))
            gr = v * (1.0 + min(0.0, pan))
            self.buf[i0 + i][0] += gl
            self.buf[i0 + i][1] += gr


def lowpass(samples, cutoff):
    out = []
    y = 0.0
    dt = 1.0 / SR
    a = dt / (dt + 1.0 / (2.0 * math.pi * cutoff))
    for s in samples:
        y += a * (s - y)
        out.append(y)
    return out


def synth_bass(track, t0, beats, bpm, root, pattern, vol=0.42):
    """the low engine: root- driven 8th-note line through a lowpass"""
    spb = 60.0 / bpm
    step = spb / 2.0
    for b in range(beats * 2):
        semi = pattern[b % len(pattern)]
        if semi is None:
            continue
        f = note_hz(root + semi)
        dur = step * 0.92
        gen_s = [0.0] * int(dur * SR)
        ph = 0.0
        for i in range(len(gen_s)):
            t = i / SR
            ph += f / SR
            e = env_ad(t, 0.004, dur * 0.6, 0.25)
            gen_s[i] = (saw(ph) * 0.7 + square(ph / 2.0) * 0.3) * e
        gen_s = lowpass(gen_s, 320.0)
        for i, v in enumerate(gen_s):
            idx = int((t0 + b * step) * SR) + i
            while len(track.buf) <= idx:
                track.buf.append([0.0, 0.0])
            track.buf[idx][0] += v * vol
            track.buf[idx][1] += v * vol


def synth_pad(track, t0, beats, bpm, root, chords, vol=0.2):
    """detuned saw pads, one chord per bar"""
    spb = 60.0 / bpm
    for bar in range(beats // 4):
        chord = chords[bar % len(chords)]
        dur = spb * 4
        gens = []
        for semi in chord:
            f = note_hz(root + semi)
            for det in (-0.4, 0.4):
                g = []
                ph = 0.0
                for i in range(int(dur * SR)):
                    t = i / SR
                    ph += (f + det) / SR
                    e = env_ad(t, 0.4, dur * 0.8, 0.5)
                    g.append(saw(ph) * e)
                gens.append(lowpass(g, 900.0))
        for i in range(int(dur * SR)):
            v = sum(g[i] for g in gens) / len(gens)
            idx = int((t0 + bar * spb * 4) * SR) + i
            while len(track.buf) <= idx:
                track.buf.append([0.0, 0.0])
            track.buf[idx][0] += v * vol
            track.buf[idx][1] += v * vol * 0.92


def synth_lead(track, t0, beats, bpm, root, motif, vol=0.16, pan=0.15):
    """the lead voice: a soft triangle line, one note per pattern entry
    (None = rest)"""
    spb = 60.0 / bpm
    step = spb
    for b, semi in enumerate(motif):
        if semi is None:
            continue
        f = note_hz(root + semi)
        dur = step * 0.85
        g = []
        ph = 0.0
        for i in range(int(dur * SR)):
            t = i / SR
            ph += f / SR
            e = env_ad(t, 0.02, dur * 0.5, 0.3)
            vib = 1.0 + 0.006 * math.sin(math.tau * 5.5 * t)
            g.append(tri(ph * vib) * e)
        g = lowpass(g, 2200.0)
        for i, v in enumerate(g):
            idx = int((t0 + b * step) * SR) + i
            while len(track.buf) <= idx:
                track.buf.append([0.0, 0.0])
            track.buf[idx][0] += v * vol * (1.0 - max(0.0, pan))
            track.buf[idx][1] += v * vol * (1.0 + min(0.0, pan))


def drums(track, t0, beats, bpm, style, vol=0.5):
    """kick / snare / hats; style: drive | cold | march | skins | machine"""
    spb = 60.0 / bpm
    step = spb / 4.0                       # 16th grid
    kicks = {"drive": (0, 4, 8, 12, 14), "cold": (0, 8, 14),
             "march": (0, 4, 8, 12), "skins": (0, 6, 8, 14),
             "machine": (0, 4, 8, 12)}[style]
    snares = {"drive": (8,), "cold": (12,), "march": (4, 12),
              "skins": (4, 10, 12), "machine": (8,)}[style]
    hats = {"drive": 2, "cold": 4, "march": 0, "skins": 2,
            "machine": 1}[style]
    n16 = beats * 4
    for s in range(n16):
        st = t0 + s * step
        if s % 16 in kicks:
            g = []
            for i in range(int(0.16 * SR)):
                t = i / SR
                f = 120.0 * math.exp(-t * 26.0) + 42.0
                ph = 2.0 * math.pi * f * t
                e = math.exp(-t * 15.0)
                g.append(math.sin(ph) * e)
            for i, v in enumerate(g):
                idx = int(st * SR) + i
                while len(track.buf) <= idx:
                    track.buf.append([0.0, 0.0])
                track.buf[idx][0] += v * vol
                track.buf[idx][1] += v * vol
        if s % 16 in snares:
            seed = int(st * 1000)
            state = [seed & 0xFFFFFFFF]
            for i in range(int(0.14 * SR)):
                t = i / SR
                x = state[0]
                x ^= (x << 13) & 0xFFFFFFFF
                x ^= x >> 17
                x ^= (x << 5) & 0xFFFFFFFF
                state[0] = x
                nz = (x / 0x7FFFFFFF) - 1.0
                e = math.exp(-t * 26.0)
                body = math.sin(2.0 * math.pi * 190.0 * t) * math.exp(-t * 40.0)
                v = (nz * 0.6 + body * 0.5) * e
                idx = int(st * SR) + i
                while len(track.buf) <= idx:
                    track.buf.append([0.0, 0.0])
                track.buf[idx][0] += v * vol * 0.5
                track.buf[idx][1] += v * vol * 0.42
        if hats and s % hats == 0:
            state = [(int(st * 700) | 1) & 0xFFFFFFFF]
            for i in range(int(0.05 * SR)):
                t = i / SR
                x = state[0]
                x ^= (x << 13) & 0xFFFFFFFF
                x ^= x >> 17
                x ^= (x << 5) & 0xFFFFFFFF
                state[0] = x
                nz = (x / 0x7FFFFFFF) - 1.0
                e = math.exp(-t * 90.0)
                v = nz * e * 0.16
                idx = int(st * SR) + i
                while len(track.buf) <= idx:
                    track.buf.append([0.0, 0.0])
                open_i = (s % 8 == 6)
                v *= 2.0 if open_i else 1.0
                track.buf[idx][0] += v * (0.8 if s % 4 else 0.5)
                track.buf[idx][1] += v * (0.5 if s % 4 else 0.8)


def write_wav(path, track, bars, bpm):
    """loop-perfect: trim to the exact loop length, soft-clip, fade the
    first/last 8ms by 50% only (a loop-safe join)"""
    spb = 60.0 / bpm
    loop_n = int(bars * 4 * spb * SR)
    while len(track.buf) < loop_n:
        track.buf.append([0.0, 0.0])
    buf = track.buf[:loop_n]
    peak = max(0.001, max(max(abs(l), abs(r)) for l, r in buf))
    norm = 0.82 / peak
    fade_n = int(0.008 * SR)
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for i in range(loop_n):
            l, r = buf[i]
            l = math.tanh(l * norm * 1.25) * 0.9
            r = math.tanh(r * norm * 1.25) * 0.9
            if i < fade_n:
                f = 0.5 + 0.5 * i / fade_n
                l *= f
                r *= f
            if i >= loop_n - fade_n:
                f = 0.5 + 0.5 * (loop_n - 1 - i) / fade_n
                l *= f
                r *= f
            frames += struct.pack("<hh", int(l * 32767),
                                  int(r * 32767))
        w.writeframes(bytes(frames))
    print(path.split("/")[-1], "%.1fs" % (loop_n / SR))


# the place tracks: (name, bpm, bars, root, bass pattern, chords, motif, drums)
import random

TRACKS = [
    ("dw_music_desert", 100, 16, -12,  # A minor
     [0, 0, 7, 0, 3, 0, 5, 7],
     [[0, 3, 7], [-4, 3, 8], [-5, 2, 7], [-7, 0, 5]],
     [0, None, 3, None, 7, None, 3, None, 10, None, 7, None, 5, None, 3, None],
     "drive"),
    ("dw_music_ice", 82, 16, -19,  # D minor
     [0, None, 0, 7, None, 5, None, 3],
     [[0, 3, 7], [0, 3, 7], [-2, 2, 5], [-5, 0, 4]],
     [12, None, None, 7, None, None, 5, None, 3, None, None, 7, None, None,
      None, None],
     "cold"),
    ("dw_music_city", 112, 16, -17,  # E minor
     [0, 0, 0, 3, 0, 0, 5, 3],
     [[0, 3, 7], [0, 3, 7], [5, 8, 12], [3, 7, 10]],
     [0, 3, 7, 3, 0, 3, 7, 10, 12, 10, 7, 3, 5, 3, 0, None],
     "machine"),
    ("dw_music_jungle", 104, 16, -14,  # G minor
     [0, 3, 0, 5, 0, 3, 7, 5],
     [[0, 3, 7], [-2, 2, 5], [0, 3, 7], [3, 7, 10]],
     [0, None, 3, 5, None, 7, None, 5, 3, None, 5, None, 7, None, 10, 7],
     "skins"),
    ("dw_music_kingdom", 92, 16, -21,  # C minor
     [0, 0, 5, 0, 3, 0, 7, 5],
     [[0, 3, 7], [-5, 0, 4], [-7, 0, 5], [-5, 0, 4]],
     [0, 7, 5, 7, 0, 7, 5, 3, 0, 7, 5, 7, 12, 10, 7, 5],
     "march"),
]


def main():
    import os
    os.makedirs(OUT, exist_ok=True)
    rnd = random.Random("v0411-music")
    for (name, bpm, bars, root, bass, chords, motif, style) in TRACKS:
        t = Track()
        total_beats = bars * 4
        loops = 1
        for rep in range(loops):
            t0 = rep * total_beats * 60.0 / bpm
            synth_bass(t, t0, total_beats, bpm, root, bass)
            synth_pad(t, t0, total_beats, bpm, root, chords)
            synth_lead(t, t0, total_beats, bpm, root, motif)
            drums(t, t0, total_beats, bpm, style)
        write_wav(OUT + "/" + name + ".wav", t, bars, bpm)


if __name__ == "__main__":
    main()
