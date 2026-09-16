#!/usr/bin/env python3
# ============================================================================
# v040-4 ROGUE ARSENAL audio - every byte synthesized here (numpy), zero
# source bytes. SFX prefix rw_* + FOUR music loops (the owner: "there is
# other songs in the original game too which are better and more
# action-focused - use them" -> ours are all action-forward chiptune).
#   rw_music_menu  - the box-deploy march
#   rw_music_war   - the main battle loop (driving 16ths)
#   rw_music_press - the wave-pressure loop (tense, faster hats)
#   rw_music_boss  - the boss theme (heavy, half-time stomp)
# Output: assets/audio/sfx/rw_*.ogg   (music rides the same folder; the
# game plays them through Jukebox.music_track)
# ============================================================================
import os, subprocess
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..",
                   "projects/gogabox/assets/audio/sfx")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(20260916)

def t(dur):
    return np.linspace(0, dur, int(SR * dur), endpoint=False)

def env(n, a=0.004, r=0.1, shape=1.0):
    e = np.ones(n)
    na = max(1, int(SR * a))
    nr = max(1, int(SR * r))
    e[:na] = np.linspace(0, 1, na)
    e[-nr:] *= np.linspace(1, 0, nr) ** shape
    return e

def noise(dur):
    return rng.uniform(-1, 1, int(SR * dur))

def sine(f, dur, ph=0.0):
    return np.sin(2 * np.pi * f * t(dur) + ph)

def sq(f, dur, duty=0.5):
    return np.where((f * t(dur)) % 1.0 < duty, 1.0, -1.0)

def saw(f, dur):
    return 2 * ((f * t(dur)) % 1.0) - 1

def sweep_lp(x, a0, a1):
    y = np.empty_like(x)
    acc = 0.0
    alphas = np.linspace(a0, a1, len(x))
    for i, v in enumerate(x):
        acc += alphas[i] * (v - acc)
        y[i] = acc
    return y

def norm(x, gain=0.9):
    m = np.max(np.abs(x))
    return (x / m * gain) if m > 0 else x

def save(name, x, gain=0.9):
    x = norm(np.asarray(x, dtype=np.float64), gain)
    pcm = (x * 32767).astype(np.int16)
    stereo = np.column_stack([pcm, pcm])
    raw = f"/tmp/rw_{name}.raw"
    stereo.tofile(raw)
    dst = f"{OUT}/rw_{name}.ogg"
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "s16le", "-ar",
                    str(SR), "-ac", "2", "-i", raw, "-c:a", "libvorbis",
                    "-q:a", "4", dst], check=True)
    os.remove(raw)
    print("rw_%s %.2fs" % (name, len(x) / SR))

# ------------------------------------------------------------------ SFX
def kick(dur=0.16, f0=150, f1=42):
    x = sine(f1, dur) * env(int(SR * dur), 0.001, dur * 0.7, 1.4)
    f = np.linspace(f0, f1, len(x))
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) * env(int(SR * dur), 0.001, dur * 0.7, 1.4)
    return x

def snare(dur=0.14):
    return (0.7 * sweep_lp(noise(dur), 0.55, 0.18)
            + 0.4 * sine(190, dur)) * env(int(SR * dur), 0.001, dur * 0.8)

def hat(dur=0.05, open_=False):
    d = dur if not open_ else dur * 4
    return sweep_lp(noise(d), 0.85, 0.5) * env(int(SR * d), 0.001, d * 0.6) * 0.5

# the cannon: deep THUMP (the owner wants real balls, the sound lands too)
x = (0.9 * kick(0.20, 120, 34)
     + 0.5 * sweep_lp(noise(0.20), 0.45, 0.05) * env(int(SR * 0.2), 0.001, 0.16, 2.0))
save("cannon", x, 0.8)
# MG rattle
x = (0.6 * sweep_lp(noise(0.055), 0.7, 0.2) * env(int(SR * 0.055), 0.001, 0.035)
     + 0.5 * sq(620, 0.055, 0.3) * env(int(SR * 0.055), 0.001, 0.03))
save("mg", x, 0.42)
# rocket whoosh
n = noise(0.5)
x = sweep_lp(n, 0.12, 0.5) * env(int(SR * 0.5), 0.02, 0.4)
x += 0.3 * saw(70, 0.5) * env(int(SR * 0.5), 0.02, 0.45)
save("rocket", x, 0.55)
# rocket/mini impact
x = sweep_lp(noise(0.3), 0.5, 0.06) * env(int(SR * 0.3), 0.002, 0.24, 2.0) \
    + 0.4 * kick(0.3, 110, 40)
save("boom_small", x, 0.7)
# big explosion
x = sweep_lp(noise(0.8), 0.4, 0.03) * env(int(SR * 0.8), 0.002, 0.7, 2.2) \
    + 0.6 * kick(0.8, 90, 30)
save("boom_big", x, 0.85)
# enemy shot
x = sq(340, 0.09, 0.25) * env(int(SR * 0.09), 0.001, 0.07) \
    + 0.3 * sine(180, 0.09) * env(int(SR * 0.09), 0.001, 0.08)
save("eshot", x, 0.4)
# player hit + shield zap
x = sweep_lp(noise(0.18), 0.6, 0.1) * env(int(SR * 0.18), 0.001, 0.14, 2.0) \
    + 0.5 * saw(120, 0.18) * env(int(SR * 0.18), 0.001, 0.15)
save("hurt", x, 0.6)
x = sq(880, 0.16, 0.4) * env(int(SR * 0.16), 0.001, 0.12) \
    + 0.4 * sq(1320, 0.16, 0.4) * env(int(SR * 0.16), 0.001, 0.12)
save("shieldhit", x, 0.45)
# ice hit (shatter)
x = sq(1900, 0.12, 0.2) * env(int(SR * 0.12), 0.001, 0.1) \
    + 0.6 * sweep_lp(noise(0.12), 0.9, 0.5) * env(int(SR * 0.12), 0.001, 0.1)
save("icehit", x, 0.42)
# pickups
x = sq(920, 0.05, 0.5) * env(int(SR * 0.05), 0.001, 0.04)
save("pick_xp", x, 0.4)
x = (sq(1050, 0.06, 0.5) + 0.5 * sq(1570, 0.06, 0.5)) \
    * env(int(SR * 0.06), 0.001, 0.05)
save("pick_coin", x, 0.5)
# level up fanfare
notes = [(523, 0.09), (659, 0.09), (784, 0.09), (1046, 0.22)]
x = np.zeros(int(SR * 0.6))
pos = 0
for f, dd in notes:
    nseg = int(SR * dd)
    x[pos:pos + nseg] += (sq(f, dd, 0.5) + 0.5 * sq(f * 2, dd, 0.5)) \
        * env(nseg, 0.004, dd * 0.6)
    pos += int(SR * 0.085)
save("levelup", x, 0.6)
# card pick
x = sq(660, 0.07, 0.5) * env(int(SR * 0.07), 0.001, 0.05)
save("card", x, 0.45)
# wave start (horn)
x = saw(196, 0.35) * env(int(SR * 0.35), 0.01, 0.25) \
    + 0.6 * saw(147, 0.35) * env(int(SR * 0.35), 0.01, 0.25)
save("wave", x, 0.5)
# boss warning (two-tone klaxon)
x = np.concatenate([
    (saw(220, 0.28) + 0.5 * saw(110, 0.28)) * env(int(SR * 0.28), 0.01, 0.1),
    np.zeros(int(SR * 0.06)),
    (saw(174, 0.28) + 0.5 * saw(87, 0.28)) * env(int(SR * 0.28), 0.01, 0.1),
    np.zeros(int(SR * 0.06))])
save("boss_warn", x, 0.6)
# boss death
x = sweep_lp(noise(1.2), 0.5, 0.02) * env(int(SR * 1.2), 0.005, 1.0, 2.4) \
    + 0.7 * kick(1.2, 80, 26)
for i, f in enumerate((392, 330, 262, 196)):
    seg = int(SR * 0.3)
    off = int(SR * (0.15 * i))
    x[off:off + seg] += 0.4 * sq(f, 0.3, 0.4) * env(seg, 0.01, 0.25)
save("boss_die", x, 0.85)
# place clear jingle
notes = [(392, 0.1), (523, 0.1), (659, 0.1), (784, 0.3)]
x = np.zeros(int(SR * 0.8))
pos = 0
for f, dd in notes:
    nseg = int(SR * dd)
    x[pos:pos + nseg] += (sq(f, dd, 0.5) + 0.4 * sq(f * 1.5, dd, 0.3)) \
        * env(nseg, 0.004, dd * 0.7)
    pos += int(SR * 0.095)
save("clear", x, 0.55)
# tunnel rumble
x = sweep_lp(noise(2.2), 0.09, 0.05) * env(int(SR * 2.2), 0.3, 1.0)
x += 0.4 * sine(48, 2.2) * env(int(SR * 2.2), 0.3, 1.0)
save("tunnel", x, 0.5)
# ui clicks
x = sq(740, 0.04, 0.5) * env(int(SR * 0.04), 0.001, 0.03)
save("click", x, 0.35)
x = (sq(520, 0.06, 0.5) + 0.4 * sq(780, 0.06, 0.5)) \
    * env(int(SR * 0.06), 0.001, 0.05)
save("buy", x, 0.5)
# game over sting
notes = [(330, 0.22), (262, 0.22), (196, 0.5)]
x = np.zeros(int(SR * 1.1))
pos = 0
for f, dd in notes:
    nseg = int(SR * dd)
    x[pos:pos + nseg] += (saw(f, dd) + 0.4 * saw(f / 2, dd)) \
        * env(nseg, 0.01, dd * 0.8)
    pos += int(SR * 0.2)
save("gameover", x, 0.6)

# ================================================================== MUSIC
# A tiny chiptune engine: pattern grid, square lead + triangle-ish bass +
# noise drums. Every loop is SEAMLESS (the pattern lengths tile exactly).
BPM_WAR = 138
BPM_PRESS = 150
BPM_BOSS = 120
BPM_MENU = 112

def note_f(n):
    """midi -> Hz"""
    return 440.0 * (2 ** ((n - 69) / 12.0))

def lead(f, dur, vol=0.22, duty=0.32):
    n = int(SR * dur)
    x = sq(f, dur, duty) * env(n, 0.004, dur * 0.5)
    x += 0.25 * sq(f * 2, dur, 0.3) * env(n, 0.004, dur * 0.4)
    return x * vol

def bass(f, dur, vol=0.3):
    n = int(SR * dur)
    x = saw(f, dur) * env(n, 0.004, dur * 0.6)
    x += 0.5 * sine(f / 2, dur) * env(n, 0.004, dur * 0.7)
    return x * vol

def place(buf, x, at):
    i = int(at * SR)
    j = min(len(buf), i + len(x))
    if i < len(buf):
        buf[i:j] += x[:j - i]

def build_track(name, bpm, bars, lead_pat, bass_pat, drum_pat, key=57,
                lead_vol=1.0):
    """patterns: list per bar of 16-step lists (None = rest)."""
    spb = 60.0 / bpm / 4.0          # 16th duration
    total = bars * 16 * spb
    buf = np.zeros(int(SR * total) + SR)
    for bar in range(bars):
        bt = bar * 16 * spb
        L = lead_pat[bar % len(lead_pat)]
        for st, n in enumerate(L):
            if n is None:
                continue
            dur = spb * (2 if st % 4 == 0 else 1)
            place(buf, lead(note_f(key + n), dur * 0.92) * lead_vol,
                  bt + st * spb)
        B = bass_pat[bar % len(bass_pat)]
        for st, n in enumerate(B):
            if n is None:
                continue
            place(buf, bass(note_f(key - 24 + n), spb * 0.9), bt + st * spb)
        D = drum_pat[bar % len(drum_pat)]
        for st, v in enumerate(D):
            if not v:
                continue
            if v == 1:
                place(buf, kick(), bt + st * spb)
            elif v == 2:
                place(buf, snare(), bt + st * spb)
            elif v == 3:
                place(buf, hat(), bt + st * spb)
            elif v == 4:
                place(buf, hat(open_=True), bt + st * spb)
    # trim to an exact loop length
    n = int(SR * total)
    buf = buf[:n]
    # quick fade-free seam: fold the tail ring into the head
    tail = buf[n:] if len(buf) > n else np.zeros(1)
    buf[:len(tail)] += tail
    save(name, buf, 0.82)

# ---- THE WAR (main battle): driving Am riff
war_lead = [
    [0, None, 3, None, 7, None, 3, None, 10, None, 7, None, 3, None, 7, None],
    [0, None, 3, None, 7, None, 3, None, 12, None, 10, None, 7, None, 3, None],
    [0, None, 3, None, 7, None, 3, None, 10, None, 7, None, 12, None, 14, None],
    [15, None, 14, None, 12, None, 10, None, 7, None, 5, None, 3, None, 2, None],
]
war_bass = [
    [0, None, 0, None, 0, None, 0, 0, 0, None, 0, None, 0, None, 0, 0],
    [0, None, 0, None, 0, None, 0, 0, 3, None, 3, None, 3, None, 3, 3],
    [0, None, 0, None, 0, None, 0, 0, 0, None, 0, None, 0, None, 0, 0],
    [5, None, 5, None, 5, None, 5, 5, 7, None, 7, None, 7, None, 7, 7],
]
war_drums = [
    [1, 0, 3, 0, 2, 0, 3, 0, 1, 0, 3, 0, 2, 0, 3, 3],
    [1, 0, 3, 0, 2, 0, 3, 0, 1, 0, 3, 0, 2, 3, 3, 4],
]
build_track("music_war", BPM_WAR, 4, war_lead, war_bass, war_drums, key=57)

# ---- THE PRESSURE: minor climb, faster hats
press_lead = [
    [12, None, None, 10, None, None, 7, None, 10, None, None, 7, None, None, 5, None],
    [12, None, None, 10, None, None, 7, None, 14, None, None, 12, None, None, 15, None],
]
press_bass = [
    [0, 0, None, 0, 0, None, 0, 0, 0, 0, None, 0, 0, None, 0, 0],
    [3, 3, None, 3, 3, None, 3, 3, 5, 5, None, 5, 7, None, 7, 7],
]
press_drums = [
    [1, 0, 3, 3, 0, 2, 0, 3, 1, 0, 3, 3, 0, 2, 3, 3],
]
build_track("music_press", BPM_PRESS, 2, press_lead, press_bass, press_drums,
            key=52)

# ---- THE BOSS: half-time stomp, chromatic menace
boss_lead = [
    [0, None, None, None, 1, None, None, None, 0, None, None, None,
     -2, None, None, None],
    [3, None, None, None, 2, None, None, None, 3, None, None, 6,
     None, None, 5, None],
]
boss_bass = [
    [0, None, None, None, 0, None, 0, None, 0, None, None, None, 0, None, 1, None],
    [3, None, None, None, 3, None, 3, None, 3, None, None, None, 6, None, 5, None],
]
boss_drums = [
    [1, 0, 0, 3, 0, 0, 2, 0, 0, 3, 1, 0, 0, 3, 2, 3],
]
build_track("music_boss", BPM_BOSS, 2, boss_lead, boss_bass, boss_drums,
            key=50, lead_vol=0.9)

# ---- THE MENU march
menu_lead = [
    [0, None, 4, None, 7, None, 12, None, 7, None, 4, None, 0, None, None, None],
    [0, None, 4, None, 7, None, 12, None, 14, None, 12, None, 7, None, None, None],
]
menu_bass = [
    [0, None, None, 0, None, None, 0, None, 0, None, None, 0, None, None, 0, None],
    [5, None, None, 5, None, None, 5, None, 7, None, None, 7, None, None, 7, None],
]
menu_drums = [
    [1, 0, 3, 0, 2, 0, 3, 0, 1, 0, 3, 0, 2, 0, 3, 0],
]
build_track("music_menu", BPM_MENU, 2, menu_lead, menu_bass, menu_drums,
            key=55, lead_vol=0.8)
print("audio done")
