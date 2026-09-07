#!/usr/bin/env python3
"""v036_gf_sfx.py - GEOMETRY FLASH (v0.3.6) audio.

100% synthesized (numpy) - nothing from the studied APK ships (THE USAGE
LAW; GD's songs/SFX are RobTop-licensed). The owner: "cool VFXs and
melodic SFXs that feels too satisfying and cool and the game music should
match the feeling... the SFXs are the most important stuff".

SFX (assets/audio/sfx/gf_*.wav):
  jump    soft square chirp up (the hop)
  land    tiny thud + tick
  orbit   bright bell ping (the game pitch-ladders it per streak)
  coin    the GOGACoin sparkle arpeggio
  flip    whoosh + tone bend (gravity inversion)
  sticky  snap + boing (the sticky leap)
  swap    3-note rising chime (the hidden mechanic reveal)
  death   boom + descending saw + sub
  speed   gentle riser (every 10 score)
  start   start whoosh + stab

THEME (assets/audio/music/gf_theme.ogg): 124 BPM A-minor synthwave loop,
16 bars (~31s): kick 4-on-floor, offbeat hats, sidechained bass, the
16th-note lead arp hook with echo, warm pads, bell sparkles.
Am F C G - two bars each, twice, B-section lead variation.

Re-derive: python3 tools/v036_gf_sfx.py
"""
import numpy as np
import os
import subprocess
import wave

SR = 44100
SFX_DIR = "projects/gogabox/assets/audio/sfx"
MUS_DIR = "projects/gogabox/assets/audio/music"


def write_wav(path, data, sr=SR):
    """data: float mono or (n,2) stereo in -1..1"""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = np.clip(data, -1.0, 1.0)
    pcm = (data * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(2 if pcm.ndim == 2 else 1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())
    print(f"  {os.path.basename(path):18s} {len(data)/sr:.2f}s")


def t_axis(dur):
    return np.linspace(0, dur, int(SR * dur), endpoint=False)


def env(n, a, r, hold=1.0):
    """attack/release envelope over n samples."""
    e = np.ones(n) * hold
    na = max(1, int(a * SR))
    nr = max(1, int(r * SR))
    e[:na] *= np.linspace(0, 1, na)
    e[-nr:] *= np.linspace(1, 0, nr)
    return e


def sine(f, dur, ph=0.0):
    return np.sin(2 * np.pi * f * t_axis(dur) + ph)


def square(f, dur, duty=0.5):
    return np.where((f * t_axis(dur)) % 1.0 < duty, 1.0, -1.0)


def saw(f, dur):
    return 2.0 * ((f * t_axis(dur)) % 1.0) - 1.0


def tri(f, dur):
    return 2.0 * np.abs(saw(f, dur)) - 1.0


def sweep(f0, f1, dur, kind="sine"):
    t = t_axis(dur)
    freq = f0 * (f1 / f0) ** (t / dur)
    ph = 2 * np.pi * np.cumsum(freq) / SR
    if kind == "sine":
        return np.sin(ph)
    if kind == "tri":
        return 2.0 * np.abs((ph / (2 * np.pi)) % 1.0) - 1.0
    return 2.0 * ((ph / (2 * np.pi)) % 1.0) - 1.0


def lowpass(x, alpha):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def highpass(x, alpha):
    return x - lowpass(x, alpha)


def noise(dur):
    return np.random.default_rng(7).uniform(-1, 1, int(SR * dur))


def bell(f, dur, harm=(1.0, 0.5, 0.25), decay=6.0):
    t = t_axis(dur)
    out = np.zeros_like(t)
    for i, h in enumerate(harm):
        out += h * np.sin(2 * np.pi * f * (i + 1) * t) * np.exp(-decay * t * (i + 1) * 0.6)
    return out


def place(buf, at, x, gain=1.0):
    i = int(at * SR)
    j = min(len(buf), i + len(x))
    if j > i:
        buf[i:j] += x[:j - i] * gain


# ------------------------------------------------------------------- sfx
def sfx_jump():
    dur = 0.16
    x = sweep(500, 790, dur, "tri") * env(len(t_axis(dur)), 0.004, 0.10, 0.9)
    x += 0.25 * sweep(1000, 1580, dur) * env(len(t_axis(dur)), 0.002, 0.06)
    return x * 0.5


def sfx_land():
    dur = 0.09
    x = lowpass(noise(dur), 0.12) * env(int(SR * dur), 0.001, 0.05) * 0.9
    x += 0.7 * sine(170, dur) * env(int(SR * dur), 0.001, 0.06)
    return x * 0.55


def sfx_orbit():
    dur = 0.24
    x = bell(880, dur, harm=(1.0, 0.42, 0.18), decay=10.0)
    x += 0.3 * bell(1760, dur, decay=14.0)
    return x * 0.5


def sfx_coin():
    dur = 0.72
    buf = np.zeros(int(SR * dur))
    for i, f in enumerate([659.3, 784.0, 987.8, 1318.5]):     # E5 G5 B5 E6
        place(buf, i * 0.085, bell(f, 0.42, decay=8.0), 0.42)
    place(buf, 0.34, bell(2637, 0.34, decay=10.0), 0.14)      # E7 shimmer
    sh = highpass(noise(0.5), 0.6) * env(int(SR * 0.5), 0.05, 0.4) * 0.05
    place(buf, 0.0, sh)
    return buf * 0.85


def sfx_flip():
    dur = 0.30
    wh = highpass(noise(dur), 0.08)
    e = env(int(SR * dur), 0.03, 0.18)
    x = wh * e * 0.7
    x += 0.42 * sweep(300, 640, dur, "tri") * env(int(SR * dur), 0.01, 0.14)
    return x * 0.6


def sfx_sticky():
    dur = 0.30
    buf = np.zeros(int(SR * dur))
    click = lowpass(noise(0.03), 0.4) * env(int(SR * 0.03), 0.001, 0.02) * 0.9
    place(buf, 0.0, click)
    t = t_axis(0.27)
    wob = np.sin(2 * np.pi * 250 * t + 5.0 * np.sin(2 * np.pi * 11 * t))
    boing = wob * np.exp(-9 * t) * (1 + 0.4 * np.sin(2 * np.pi * 26 * t))
    place(buf, 0.02, boing, 0.5)
    return buf * 0.7


def sfx_swap():
    dur = 0.85
    buf = np.zeros(int(SR * dur))
    for i, (f, at) in enumerate([(440.0, 0.0), (523.3, 0.11), (659.3, 0.22)]):
        place(buf, at, bell(f, 0.55, decay=6.0), 0.34)
        place(buf, at, bell(f * 2, 0.4, decay=9.0), 0.10)
    # the soft pad swell under it
    t = t_axis(0.6)
    pad = (saw(220, 0.6) + saw(277.2, 0.6) * 0.7) * env(len(t), 0.18, 0.3) * 0.10
    place(buf, 0.05, lowpass(pad, 0.12))
    return buf * 0.8


def sfx_death():
    dur = 0.8
    t = t_axis(dur)
    boom = lowpass(noise(dur), 0.09) * np.exp(-6.5 * t) * 1.5
    dsaw = sweep(420, 70, dur, "saw") * np.exp(-5.0 * t) * 0.5
    sub = sweep(120, 38, dur) * np.exp(-7.0 * t) * 0.9
    return np.tanh((boom + dsaw + sub) * 1.1) * 0.75


def sfx_speed():
    dur = 0.38
    buf = np.zeros(int(SR * dur))
    x = sweep(520, 940, dur) * env(int(SR * dur), 0.05, 0.20) * 0.30
    place(buf, 0.0, x)
    place(buf, 0.02, bell(1046, 0.3, decay=9.0) * 0.056)
    return buf * 0.8


def sfx_start():
    dur = 0.55
    buf = np.zeros(int(SR * dur))
    wh = highpass(noise(0.3), 0.05) * env(int(SR * 0.3), 0.12, 0.14) * 0.5
    place(buf, 0.0, wh)
    for i, f in enumerate([440.0, 554.4, 659.3]):             # A C# E (A major stab)
        place(buf, 0.16 + i * 0.012, bell(f, 0.4, decay=7.0), 0.22)
    return buf * 0.7


# ----------------------------------------------------------------- theme
BPM = 124.0
BEAT = 60.0 / BPM
BAR = BEAT * 4
# A minor: Am F C G, two bars each - the progression rides twice (16 bars)
PROG = [("A2", ["A3", "C4", "E4"]), ("A2", ["A3", "C4", "E4"]),
        ("F2", ["F3", "A3", "C4"]), ("F2", ["F3", "A3", "C4"]),
        ("C3", ["C4", "E4", "G4"]), ("C3", ["C4", "E4", "G4"]),
        ("G2", ["G3", "B3", "D4"]), ("G2", ["G3", "B3", "D4"])]

NOTE_FREQ = {}


def note_freq(name):
    if name in NOTE_FREQ:
        return NOTE_FREQ[name]
    names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    pitch = name[:-1]
    octv = int(name[-1])
    semi = names.index(pitch) + (octv + 1) * 12
    f = 440.0 * 2 ** ((semi - 69) / 12)
    NOTE_FREQ[name] = f
    return f


def kick(dur=0.30):
    t = t_axis(dur)
    f = 160 * (48 / 160) ** (t / dur)
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) * np.exp(-11 * t)
    x += 0.4 * lowpass(noise(dur), 0.5) * np.exp(-60 * t)
    return x


def hat(dur=0.06):
    return highpass(noise(dur), 0.55) * env(int(SR * dur), 0.001, 0.035) * 0.5


def bass_note(f, dur, pump=1.0):
    t = t_axis(dur)
    x = (saw(f, dur) + 0.5 * saw(f * 2.02, dur)) * 0.5
    x = lowpass(x, 0.10)
    sc = 0.35 + 0.65 * (1 - np.exp(-6 * t)) ** 0.8    # the sidechain dip
    return x * sc * env(len(t), 0.004, min(0.06, dur * 0.2)) * pump


def lead_note(f, dur):
    x = square(f, dur, 0.32) * 0.6 + tri(f, dur) * 0.4
    x = lowpass(x, 0.22)
    return x * env(len(t_axis(dur)), 0.004, min(0.09, dur * 0.4))


def pad_chord(freqs, dur):
    t = t_axis(dur)
    x = np.zeros(len(t))
    for f in freqs:
        for det in (0.9965, 1.0, 1.004):
            x += saw(f * det, dur)
    x = lowpass(x / (len(freqs) * 3), 0.06)
    return x * env(len(t), 0.25, 0.5, 0.85)


def echo(x, delay_s, fb=0.34, taps=4, mix=0.30):
    out = x.copy()
    d = int(delay_s * SR)
    for i in range(1, taps + 1):
        g = mix * (fb ** (i - 1))
        shifted = np.zeros_like(x)
        if i * d < len(x):
            shifted[i * d:] = x[:len(x) - i * d] * g
            out += shifted
    return out


def build_theme():
    bars = 16
    total = bars * BAR + 1.2                     # tail for echoes
    n = int(SR * total)
    kick_b = np.zeros(n)
    hat_b = np.zeros(n)
    bass_b = np.zeros(n)
    lead_b = np.zeros(n)
    pad_b = np.zeros(n)
    bell_b = np.zeros(n)

    # the arp hook: 16th notes cycling chord tones + octave, per bar
    ARP_PAT = [0, 1, 2, 3, 2, 1, 0, 2, 1, 3, 2, 0, 1, 2, 3, 1]  # indices into [r,3,5,r+12]
    for bar in range(bars):
        root_name, chord = PROG[bar % len(PROG)]
        root = note_freq(root_name)
        tones = [note_freq(chord[0]), note_freq(chord[1]), note_freq(chord[2]), root * 4.0]
        bt = bar * BAR
        # drums
        for b in range(4):
            place(kick_b, bt + b * BEAT, kick(), 0.62)
            place(hat_b, bt + (b + 0.5) * BEAT, hat(), 0.34)
            if b == 2:
                place(hat_b, bt + b * BEAT + BEAT * 0.75, hat(), 0.16)
        # bass: 8ths, pumping
        for e8 in range(8):
            place(bass_b, bt + e8 * BEAT / 2,
                  bass_note(root, BEAT / 2 * 0.94), 0.40)
        # lead arp (every bar; B-section = bars 8..15 an octave sparkle variant)
        for s16 in range(16):
            idx = ARP_PAT[s16]
            f = tones[min(idx, 3)]
            if bar >= 8 and s16 % 4 == 2:
                f *= 2.0
            x = lead_note(f, BEAT / 4 * 0.92)
            x = echo(x, BEAT / 2, fb=0.30, taps=3, mix=0.26)
            place(lead_b, bt + s16 * BEAT / 4, x, 0.30)
        # pads each 2 bars
        if bar % 2 == 0:
            ch = [note_freq(c) for c in chord]
            place(pad_b, bt, pad_chord(ch, BAR * 2 * 0.98), 0.16)
        # bell sparkle on bar 0 of each pair
        if bar % 2 == 0:
            place(bell_b, bt, bell(note_freq(chord[2]) * 2, 0.5, decay=7.0), 0.10)

    mix = (kick_b + hat_b + bass_b + lead_b + pad_b + bell_b)
    # gentle master glue
    mix = np.tanh(mix * 1.25) * 0.82
    # loop-perfect: fold the tail back onto the head (echo tails)
    loop_n = int(SR * bars * BAR)
    out = mix[:loop_n].copy()
    tail = mix[loop_n:]
    out[:len(tail)] += tail
    # stereo: tiny haas widening on the lead
    lead_s = np.zeros_like(out)
    d = int(0.011 * SR)
    lead_s[d:] = out[:-d] * 0.18
    stereo = np.stack([out + lead_s, out - lead_s * 0.6], axis=1)
    peak = np.abs(stereo).max()
    if peak > 0.98:
        stereo *= 0.98 / peak
    return stereo


def main():
    print("GEOMETRY FLASH audio - 100% synthesized")
    write_wav(os.path.join(SFX_DIR, "gf_jump.wav"), sfx_jump())
    write_wav(os.path.join(SFX_DIR, "gf_land.wav"), sfx_land())
    write_wav(os.path.join(SFX_DIR, "gf_orbit.wav"), sfx_orbit())
    write_wav(os.path.join(SFX_DIR, "gf_coin.wav"), sfx_coin())
    write_wav(os.path.join(SFX_DIR, "gf_flip.wav"), sfx_flip())
    write_wav(os.path.join(SFX_DIR, "gf_sticky.wav"), sfx_sticky())
    write_wav(os.path.join(SFX_DIR, "gf_swap.wav"), sfx_swap())
    write_wav(os.path.join(SFX_DIR, "gf_death.wav"), sfx_death())
    write_wav(os.path.join(SFX_DIR, "gf_speed.wav"), sfx_speed())
    write_wav(os.path.join(SFX_DIR, "gf_start.wav"), sfx_start())
    theme = build_theme()
    wav_tmp = "/tmp/gf_theme.wav"
    write_wav(wav_tmp, theme)
    os.makedirs(MUS_DIR, exist_ok=True)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_tmp,
                    "-c:a", "libvorbis", "-q:a", "5",
                    os.path.join(MUS_DIR, "gf_theme.ogg")], check=True)
    print(f"  gf_theme.ogg       {os.path.getsize(os.path.join(MUS_DIR, 'gf_theme.ogg'))/1e6:.2f}MB")
    print("done.")


if __name__ == "__main__":
    main()
