#!/usr/bin/env python3
"""v0.3.3 MATCHER SFX synthesis (the house gen_sfx lineage).

Everything 44.1k stereo wav, tuned warm + happy:
  pops cascade via Jukebox pitch (copied candyrush CC0 pops),
  these cover the specials, the modes and the economy.
Also synthesizes matcher_peace.wav - the calm twin theme.
"""
import numpy as np
import wave
import os

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(ROOT, "projects/gogabox/assets/audio/sfx")
MUS = os.path.join(ROOT, "projects/gogabox/assets/audio/music")


def env(n, a=0.005, r=0.12, shape=1.0):
    t = np.linspace(0, 1, n)
    at = max(1, int(a * SR))
    e = np.ones(n)
    e[:at] = np.linspace(0, 1, at)
    rel = max(1, int(r * SR))
    e[-rel:] = np.linspace(1, 0, rel) ** shape
    return e


def sine(f, dur, vol=0.5, slide=0.0):
    n = int(dur * SR)
    t = np.linspace(0, dur, n, endpoint=False)
    f_t = f + slide * t / dur
    ph = 2 * np.pi * np.cumsum(f_t) / SR
    return np.sin(ph) * vol * env(n, r=dur * 0.7)


def pluck(f, dur, vol=0.5, bright=1.0):
    n = int(dur * SR)
    t = np.linspace(0, dur, n, endpoint=False)
    s = np.sin(2 * np.pi * f * t)
    s += 0.42 * bright * np.sin(2 * np.pi * f * 2 * t)
    s += 0.18 * bright * np.sin(2 * np.pi * f * 3 * t)
    s += 0.08 * bright * np.sin(2 * np.pi * f * 4.2 * t)
    e = np.exp(-t * (6.5 / max(0.05, dur * 0.35)))
    return s * e * vol


def noise(dur, vol=0.3, seed=3):
    rng = np.random.default_rng(seed)
    return rng.standard_normal(int(dur * SR)) * vol


def bp(x, lo, hi):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    m = ((f >= lo) & (f <= hi)).astype(float)
    m = np.convolve(m, np.ones(9) / 9, mode="same")
    return np.fft.irfft(X * m, len(x))


def save(name, L, R=None, peak=0.86):
    if R is None:
        R = L
    st = np.stack([L, R], axis=1)
    m = np.max(np.abs(st)) / peak
    if m > 0:
        st = st / m
    data = (st * 32767).astype(np.int16)
    with wave.open(os.path.join(SFX, name), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print("sfx", name, round(len(L) / SR, 2), "s")



def add_at(buf, seg, a0):
    take = min(len(seg), max(0, len(buf) - a0))
    if take > 0:
        buf[a0:a0 + take] += seg[:take]


def wet(x, room=0.22, damp=0.35):
    """cheap stereo room: short filtered echoes widened"""
    d1 = int(0.031 * SR)
    d2 = int(0.057 * SR)
    y = np.zeros(len(x) + d2 + 64)
    y[:len(x)] += x * (1 - room)
    y[d1:d1 + len(x)] += bp(x, 300, 8000) * room * 0.55
    y[d2:d2 + len(x)] += bp(x, 200, 5200) * room * 0.35
    return y


# ------------------------------------------------------------- specials
def s_flame():
    n2 = int(0.55 * SR)
    whoosh = bp(noise(0.55, 1.0, 7), 300, 3400) * env(n2, a=0.02, r=0.3)
    boom = sine(150, 0.5, 0.9, slide=-90)
    crackle = bp(noise(0.2, 0.8, 11), 2500, 9000) * env(int(0.2 * SR), r=0.15)
    crack = np.zeros(n2)
    crack[:len(crackle)] += crackle
    bm = np.zeros(n2)
    take = min(len(boom), n2)
    bm[:take] += boom[:take]
    x = whoosh * 0.7 + bm * 0.8 + crack * 0.5
    save("m_flame.wav", wet(x), wet(x * np.roll(np.ones(n2), 31)))


def s_hyper():
    n = int(0.6 * SR)
    t = np.linspace(0, 0.6, n, endpoint=False)
    f = 900 + 2600 * (t / 0.6) ** 2
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(n, a=0.01, r=0.25)
    shimmer = bp(noise(0.6, 1.0, 13), 4000, 14000) * env(n, a=0.02, r=0.4) * 0.7
    arp = np.zeros(n)
    for i, f0 in enumerate([1318, 1568, 1976, 2637]):
        seg = pluck(f0, 0.2, 0.5)
        add_at(arp, seg, int(i * 0.07 * SR))
    save("m_hyper.wav", wet(x * 0.55 + shimmer * 0.5 + arp * 0.9))


def s_melt():
    n = int(0.4 * SR)
    x = bp(noise(0.4, 1.0, 17), 1200, 6500) * env(n, a=0.01, r=0.25)
    for i, f0 in enumerate([2400, 1900, 3000]):
        seg = pluck(f0, 0.12, 0.35)
        add_at(x, seg, int((0.05 + i * 0.08) * SR))
    save("m_melt.wav", wet(x * 0.8))


def s_freeze():
    n = int(0.5 * SR)
    t = np.linspace(0, 0.5, n, endpoint=False)
    f = 600 + 900 * t / 0.5
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(n, a=0.05, r=0.2) * 0.4
    x += bp(noise(0.5, 1.0, 19), 3500, 11000) * env(n, a=0.12, r=0.3) * 0.5
    save("m_freeze.wav", wet(x))


def s_dig():
    n = int(0.28 * SR)
    x = sine(95, 0.28, 1.0, slide=-45)
    dirt = bp(noise(0.2, 1.0, 23), 120, 900) * env(int(0.2 * SR), a=0.004, r=0.16)
    x[:len(dirt)] += dirt[:n] * 0.9
    save("m_dig.wav", wet(x))


def s_treasure(kind):
    if kind == "gold":
        seq = [(1046, 0.0), (1568, 0.055)]
        dur = 0.3
    elif kind == "diamond":
        seq = [(1976, 0.0), (2637, 0.07)]
        dur = 0.4
    else:  # artifact
        seq = [(784, 0.0), (988, 0.08), (1319, 0.16), (1568, 0.24)]
        dur = 0.6
    n = int(dur * SR)
    x = np.zeros(n)
    for f0, at in seq:
        seg = pluck(f0, 0.3, 0.6, bright=1.3)
        a0 = int(at * SR)
        take = min(len(seg), n - a0)
        if take > 0:
            x[a0:a0 + take] += seg[:take]
        if kind != "gold":
            shimmer = bp(noise(0.1, 1.0, 29 + int(f0)), 5000, 13000) * env(int(0.1 * SR), r=0.08)
            st = min(len(shimmer), n - a0)
            if st > 0:
                x[a0:a0 + st] += shimmer[:st] * 0.25
    save("m_%s.wav" % kind, wet(x))


def s_descend():
    n = int(0.8 * SR)
    rumble = bp(noise(0.8, 1.0, 31), 40, 240) * env(n, a=0.04, r=0.35)
    riser = sine(220, 0.8, 0.5, slide=+340)
    chime = np.zeros(n)
    for i, f0 in enumerate([659, 880, 1319]):
        seg = pluck(f0, 0.25, 0.4)
        add_at(chime, seg, int((0.4 + i * 0.09) * SR))
    save("m_descend.wav", wet(rumble * 0.8 + riser * 0.45 + chime * 0.8))


def s_shuffle():
    n = int(0.35 * SR)
    x = bp(noise(0.35, 1.0, 37), 500, 4200) * env(n, a=0.02, r=0.2)
    x *= (1 + 0.4 * np.sin(2 * np.pi * 9 * np.linspace(0, 0.35, n)))
    save("m_shuffle.wav", wet(x * 0.7))


def s_arm():
    n = int(0.22 * SR)
    t = np.linspace(0, 0.22, n, endpoint=False)
    x = np.sign(np.sin(2 * np.pi * 880 * t)) * 0.2 + np.sin(2 * np.pi * 1760 * t) * 0.4
    save("m_arm.wav", wet(x * env(n, r=0.08)))


def s_refill():
    n = int(0.3 * SR)
    x = np.zeros(n)
    for i, f0 in enumerate([880, 1174]):
        seg = pluck(f0, 0.22, 0.55)
        a0 = int(i * 0.06 * SR)
        x[a0:a0 + len(seg)] += seg
    save("m_refill.wav", wet(x))


def s_flutter():
    n = int(0.3 * SR)
    t = np.linspace(0, 0.3, n, endpoint=False)
    flap = bp(noise(0.3, 1.0, 41), 900, 5200) * (0.5 + 0.5 * np.sin(2 * np.pi * 16 * t) ** 2)
    save("m_flutter.wav", wet(flap * env(n, a=0.01, r=0.12) * 0.8))


def s_gulp():
    n = int(0.45 * SR)
    x = sine(520, 0.2, 0.9, slide=-380)
    boing = sine(160, 0.3, 0.8, slide=+120)
    x2 = np.zeros(n)
    add_at(x2, x, 0)
    add_at(x2, boing, int(0.12 * SR))
    save("m_gulp.wav", wet(x2))


def s_goal():
    seq = [(523, 0.0), (659, 0.09), (784, 0.18), (1046, 0.27)]
    n = int(0.8 * SR)
    x = np.zeros(n)
    for f0, at in seq:
        seg = pluck(f0, 0.45, 0.6, bright=1.2)
        a0 = int(at * SR)
        add_at(x, seg, a0)
        third = pluck(f0 * 1.5, 0.4, 0.25)
        add_at(x, third, a0 + 20)
    save("m_goal.wav", wet(x))


def s_gong():
    n = int(1.1 * SR)
    t = np.linspace(0, 1.1, n, endpoint=False)
    x = np.sin(2 * np.pi * 196 * t) + 0.5 * np.sin(2 * np.pi * 196 * 2.76 * t)
    x += 0.3 * np.sin(2 * np.pi * 196 * 4.1 * t + 0.5)
    x *= env(n, a=0.004, r=0.8, shape=0.6)
    save("m_gong.wav", wet(x * 0.8))


def s_spider():
    """the spider hiss-boop when a butterfly is taken - sad but soft"""
    n = int(0.5 * SR)
    x = sine(340, 0.5, 0.8, slide=-160) + 0.4 * sine(510, 0.5, 0.5, slide=-240)
    save("m_spider.wav", wet(x))


# ------------------------------------------------------------- peace theme
def theme_peace():
    bpm = 66
    beat = 60 / bpm
    bars = 8
    n = int(bars * 4 * beat * SR)
    t = np.linspace(0, bars * 4 * beat, n, endpoint=False)
    x = np.zeros(n)

    def pad(freq, t0, dur, vol=0.16):
        a = int(t0 * SR)
        seg_n = int(dur * SR)
        seg_t = np.linspace(0, dur, seg_n, endpoint=False)
        s = (np.sin(2 * np.pi * freq * seg_t) + 0.55 * np.sin(2 * np.pi * freq * 2 * seg_t)
             + 0.3 * np.sin(2 * np.pi * freq * 0.5 * seg_t))
        vib = 1 + 0.004 * np.sin(2 * np.pi * 0.9 * seg_t)
        s *= vib
        e = env(seg_n, a=0.6, r=1.4, shape=0.7)
        add_at(x, s * e * vol, a)

    def bell(freq, t0, vol=0.22):
        a = int(t0 * SR)
        seg = pluck(freq, 1.4, vol, bright=0.5)
        add_at(x, seg, a)

    # I - vi - IV - I in F major, airy
    F, A, C = 349.23, 440.0, 523.25
    prog = [
        [F, A, C], [293.66, 349.23, 440.0],
        [261.63, 329.63, 392.0], [F, A, C],
    ]
    for bar in range(bars):
        ch = prog[bar % 4]
        t0 = bar * 4 * beat
        for i, f0 in enumerate(ch):
            pad(f0, t0 + i * 0.05, 4 * beat * 0.98, 0.11)
    rng = np.random.default_rng(2026)
    for k in range(14):
        t0 = rng.uniform(0.5, bars * 4 * beat - 2)
        f0 = rng.choice([523.25, 587.33, 698.46, 783.99, 880.0, 1046.5])
        bell(f0, t0, 0.16)
    # slow lfo air
    x += 0.02 * np.sin(2 * np.pi * 0.25 * t) * bp(noise(n / SR, 1.0, 77), 300, 900)
    L = wet(x, room=0.3)
    R = wet(np.roll(x, 220), room=0.3)
    st = np.stack([L, R], axis=1)
    st = st / np.max(np.abs(st)) * 0.8
    data = (st * 32767).astype(np.int16)
    with wave.open(os.path.join(MUS, "matcher_peace.wav"), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print("music matcher_peace.wav", round(n / SR, 1), "s")


if __name__ == "__main__":
    s_flame()
    s_hyper()
    s_melt()
    s_freeze()
    s_dig()
    s_treasure("gold")
    s_treasure("diamond")
    s_treasure("artifact")
    s_descend()
    s_shuffle()
    s_arm()
    s_refill()
    s_flutter()
    s_gulp()
    s_goal()
    s_gong()
    s_spider()
    theme_peace()
    print("ALL v0.3.3 matcher sfx done")
