#!/usr/bin/env python3
"""v038p5_dc_music.py - DOMINO + CHECKMATE background themes (v0.3.8-5).
100% synthesized - nothing from the studied web games ships (THE USAGE LAW).

Study notes (what the references feel like, what we compose instead):
  GameSnacks DominoBattle music_menu.m4a: ~97s bright arcade loop, ~136 BPM
  feel, spectral centroid ~2.2 kHz, chroma piles on B/A/F#/G (B-minor / D-major
  family), light plucky timbre, constant shaker drive. Ours ("THE PARLOR"):
  the same sunny table-Game energy, but OUR melody - 120 BPM D-major, a
  marimba-ish pluck playing a call-and-answer over a rounded sub bass, brush
  shaker on the eighths. Original melody, original chord turn (I - IV - ii - V).
  GameSnacks ChessClassic: NO music at all (its sound sprite is two sfx).
  So for Checkmate we set our own room tone ("THE STUDY"): 84 BPM A-minor,
  Karplus-Strong nylon arpeggios (Am - F - C - E), a music-box lead answering
  them, warm pad underneath - the quiet club where a board game lives.

Both loop seamlessly (the loop tail is cut ON the bar grid and the pad/
shaker beds are phase-continuous across the seam).

Output: assets/audio/music/d_theme.ogg + c_theme.ogg (vorbis q4, ffmpeg).
"""

import os
import subprocess
import wave

import numpy as np

SR = 44100
MUSIC_DIR = "projects/gogabox/assets/audio/music"


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
    print(f"  {os.path.basename(path):14s} {len(data)/sr:.2f}s")


def midi_f(n: float) -> float:
    return 440.0 * 2.0 ** ((n - 69) / 12.0)


# ----------------------------------------------------------------- voices
def pluck(freq, dur, bright=0.5, sr=SR):
    """Karplus-Strong nylon-ish pluck."""
    n = int(sr * dur)
    period = max(2, int(sr / freq))
    rng = np.random.default_rng(int(freq * 13) % (2**31))
    buf = rng.uniform(-1, 1, period)
    damp = 0.996 - bright * 0.012
    out = np.zeros(n)
    for i in range(n):
        out[i] = buf[i % period]
        buf[i % period] = damp * 0.5 * (buf[i % period]
                                        + buf[(i + 1) % period])
    # gentle body + fade
    t = np.arange(n) / sr
    out *= np.exp(-t * 2.2) * (1.0 - np.exp(-t * 900))
    return out


def marimba(freq, dur, sr=SR):
    """Soft mallet: sine + 4th partial, fast decay."""
    n = int(sr * dur)
    t = np.arange(n) / sr
    out = (np.sin(2 * np.pi * freq * t) * np.exp(-t * 7.0)
           + 0.28 * np.sin(2 * np.pi * freq * 4.0 * t) * np.exp(-t * 12.0)
           + 0.12 * np.sin(2 * np.pi * freq * 9.2 * t) * np.exp(-t * 18.0))
    out *= 1.0 - np.exp(-t * 1200)
    return out


def pad_chord(freqs, dur, sr=SR):
    n = int(sr * dur)
    t = np.arange(n) / sr
    out = np.zeros(n)
    for f in freqs:
        det = f * 1.003
        out += (np.sin(2 * np.pi * f * t)
                + np.sin(2 * np.pi * det * t)) * 0.5
    # slow attack / release so the bed is seamless across the loop seam
    a = int(sr * 0.4)
    env = np.ones(n)
    env[:a] = np.linspace(0, 1, a)
    env[-a:] = np.linspace(1, 0, a)
    return out * env / max(1, len(freqs))


def shaker(dur, bpm, sr=SR):
    """Brush on the eighths - white noise bursts, high-passed by differencing."""
    step = 60.0 / bpm / 2.0
    n = int(sr * dur)
    out = np.zeros(n)
    rng = np.random.default_rng(7717)
    t_step = int(sr * step)
    for i in range(0, n - t_step, t_step):
        ln = int(sr * 0.05)
        g = rng.uniform(-1, 1, ln)
        g = np.diff(g, prepend=0)          # crude high-pass
        env = np.exp(-np.arange(ln) / sr * 90.0)
        acc = 1.0 if (i // t_step) % 2 == 0 else 0.62
        out[i:i + ln] += g * env * 0.22 * acc
    return out


def sub_bass(freq, dur, sr=SR):
    n = int(sr * dur)
    t = np.arange(n) / sr
    out = np.sin(2 * np.pi * freq * t) * np.exp(-t * 3.0)
    out += 0.3 * np.sin(2 * np.pi * freq * 2 * t) * np.exp(-t * 6.0)
    out *= 1.0 - np.exp(-t * 700)
    return out


def wrap_fold(buf, total_s):
    """fold everything past the loop end back onto the head - the seam
    becomes phase-continuous (a real seamless loop, no click)."""
    n = int(total_s * SR)
    src = buf
    if src.size < n:
        src = np.pad(src, (0, n - src.size))
    head, tail = src[:n].copy(), src[n:]
    m = min(n, tail.size)
    head[:m] += tail[:m]
    return head


def place(buf, at, sig, gain=1.0):
    i = int(at * SR)
    j = min(buf.size, i + sig.size)
    if j > i:
        buf[i:j] += sig[:j - i] * gain


# ------------------------------------------------------------- the parlor
def d_theme():
    """DOMINO - 'THE PARLOR': 120 BPM D-major table Game, 16 bars."""
    bpm = 120.0
    bar = 60.0 / bpm * 4.0
    bars = 16
    total = bar * bars
    buf = np.zeros(int(SR * (total + 1.0)))   # +1s tail: decays wrap, not clip
    # D major: melody notes on the midi grid (D=62)
    D, E, Fs, G, A, B, Cs = 62, 64, 66, 67, 69, 71, 73
    D5 = 74
    # I - IV - ii - V  (D - G - Em - A), 2 bars each, twice
    prog = [[50, 54, 57, 62], [43, 47, 50, 55], [40, 47, 52, 55], [45, 49, 52, 57]]
    # the bed: pads + sub bass on each chord
    for pi, ch in enumerate(prog * 2):
        at = pi * 2 * bar
        for k in range(2):
            place(buf, at + k * bar, pad_chord([midi_f(n) for n in ch],
                                               bar, SR), 0.10)
        place(buf, at, sub_bass(midi_f(ch[0] - 12), bar * 0.9), 0.30)
        place(buf, at + bar, sub_bass(midi_f(ch[0] - 12), bar * 0.9), 0.24)
    # the shaker drive (folded: the last burst wraps onto the head)
    buf += wrap_fold(shaker(total + 0.3, bpm) * 0.5, total + 1.0)
    # the melody: call (bars 1-4), answer (5-8), variation (9-12), close (13-16)
    phrase_a = [
        (0.0, D, 1), (0.5, E, .6), (1.0, Fs, 1), (1.5, A, .8),
        (2.0, Fs, .7), (3.0, E, 1),
        (4.0, D, 1), (4.5, E, .6), (5.0, Fs, .8), (6.0, D, 1),
        (7.0, B, .7),
        (8.0, Cs, 1), (8.5, D, .6), (9.0, E, 1), (10.0, Cs, .8),
        (11.0, A, .9),
        (12.0, Fs, 1), (13.0, G, .7), (14.0, Fs, 1), (15.0, E, .8),
        (15.5, D, .9),
    ]
    phrase_b = [
        (0.0, D5, 1), (0.5, A, .5), (1.0, B, .9), (2.0, A, .8),
        (3.0, Fs, 1),
        (4.0, G, .9), (4.5, A, .5), (5.0, B, .9), (6.0, A, .8),
        (7.0, G, .7),
        (8.0, Fs, 1), (8.5, E, .5), (9.0, Fs, .9), (10.0, D, 1),
        (11.0, B, .7),
        (12.0, A, 1), (13.0, Fs, .8), (14.0, E, .9), (15.0, D, 1.2),
    ]
    for base, ph in [(0.0, phrase_a), (bar * 4, phrase_b),
                     (bar * 8, phrase_a), (bar * 12, phrase_b)]:
        for (beat, note, amp) in ph:
            place(buf, base + beat * bar / 4.0,
                  marimba(midi_f(note), 0.9), 0.30 * amp)
            # the octave sparkle on strong beats
            if amp >= 1.0:
                place(buf, base + beat * bar / 4.0,
                      marimba(midi_f(note + 12), 0.5), 0.10)
    # stereo-ish: mirror a soft echo a hair late on the other channel
    mono = wrap_fold(buf, total)
    echo = np.roll(mono, int(SR * 0.021)) * 0.28
    st = np.stack([mono + echo * 0.5, mono + echo], axis=1)
    return st / np.max(np.abs(st)) * 0.82


# -------------------------------------------------------------- the study
def c_theme():
    """CHESS - 'THE STUDY': 84 BPM A-minor parlor, nylon + music box, 16 bars."""
    bpm = 84.0
    bar = 60.0 / bpm * 4.0
    bars = 16
    total = bar * bars
    buf = np.zeros(int(SR * (total + 1.0)))   # +1s tail: plucks wrap, not clip
    Am = [57, 60, 64]         # A3 C4 E4
    F = [53, 57, 60]          # F3 A3 C4
    C = [55, 60, 64]          # G3 C4 E4 (C/G keeps the bass kind)
    E = [52, 56, 59]          # E3 G#3 B3
    prog = [Am, F, C, E] * 2 + [Am, F, C, E] * 2
    bass_line = [45, 41, 48, 40] * 4
    for pi, ch in enumerate(prog):
        at = pi * bar
        place(buf, at, pad_chord([midi_f(n) for n in ch], bar), 0.085)
        place(buf, at, sub_bass(midi_f(bass_line[pi] - 12), bar * 1.6), 0.26)
        # the arpeggio: 8th-note sweep, Karplus-Strong nylon
        arp = [ch[0] + 12, ch[1] + 12, ch[2] + 12, ch[1] + 24,
               ch[2] + 12, ch[1] + 12, ch[0] + 12, ch[1]]
        for k, n in enumerate(arp):
            place(buf, at + k * bar / 8.0, pluck(midi_f(n), 1.1, 0.45), 0.24)
    # the music-box lead answers in the second half of each 4-bar phrase
    lead = [
        # phrase 1 (bars 4-4.5 window etc: answer 2 bars every 4)
        (4 * bar + 0.0, 76, 1.0), (4 * bar + 1.0, 74, .7),
        (4 * bar + 2.0, 72, .9), (4 * bar + 3.0, 69, 1.1),
        (5 * bar + 0.0, 71, .8), (5 * bar + 1.5, 72, .6),
        (5 * bar + 2.0, 74, .9),
        (12 * bar + 0.0, 76, 1.0), (12 * bar + 1.0, 79, .7),
        (12 * bar + 2.0, 77, .9), (12 * bar + 3.0, 72, 1.1),
        (13 * bar + 0.0, 74, .8), (13 * bar + 1.5, 72, .6),
        (13 * bar + 2.0, 71, .9), (13 * bar + 3.0, 69, 1.2),
    ]
    for (at, n, amp) in lead:
        place(buf, at, marimba(midi_f(n), 1.4), 0.16 * amp)
    mono = wrap_fold(buf, total)
    echo = np.roll(mono, int(SR * 0.031)) * 0.30
    st = np.stack([mono * 0.5 + echo * 0.35, mono * 0.5 + echo], axis=1)
    return st / np.max(np.abs(st)) * 0.8


def main():
    print("v038p5_dc_music: two parlor themes")
    d = d_theme()
    c = c_theme()
    tmp = "/tmp"
    write_wav(os.path.join(tmp, "d_theme.wav"), d)
    write_wav(os.path.join(tmp, "c_theme.wav"), c)
    for name in ["d_theme", "c_theme"]:
        out = os.path.join(MUSIC_DIR, name + ".ogg")
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-i",
                        os.path.join(tmp, name + ".wav"),
                        "-c:a", "libvorbis", "-q:a", "4", out], check=True)
        print(f"  -> {out} ({os.path.getsize(out)//1024} KB)")


if __name__ == "__main__":
    main()
