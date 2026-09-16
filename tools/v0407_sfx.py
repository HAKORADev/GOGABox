#!/usr/bin/env python3
"""v0407_sfx.py - ROCK BREAKER (v040-7) audio, 100% synthesized the house
way (nothing sampled, nothing scraped).

ROCK BREAKER (assets/audio/sfx/rb_*.wav):
  start   the tap-anywhere run start - a rising crack fanfare
  shoot   the cannon's volley tick - a tight filtered pop
  hit     the crack per hit - stone chip + tone
  break   the break burst - a bigger crush (pitched live by rock size)
  bounce  the wall bounce - a soft stone thud
  ground  the ground shatter - the dusty splat of a rock the floor ate
  golden  the golden rock's hatch - the bright GOGACoin fanfare
  mystery the mystery gift - a mystical three-note chime
  shieldsave  the shield taking the touch - an electric ring
  death   the cannon crushed - the big crush + the descending wah
  click / buy / confirm - the UI voices

MUSIC (assets/audio/music/rb_theme.wav): the 118bpm cave-drill loop,
8 bars, seamless (the loop region law reads the whole stream).

Re-derive: python3 tools/v0407_sfx.py
"""
import numpy as np
import os
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


def sweep(f0, f1, dur):
    t = t_axis(dur)
    fr = np.linspace(f0, f1, t.size)
    ph = 2 * np.pi * np.cumsum(fr) / SR
    return np.sin(ph)


def noise(dur):
    return np.random.RandomState(7).uniform(-1, 1, int(SR * dur))


def lowpass(x, alpha):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def saturate(x, drive=1.6):
    return np.tanh(x * drive)


def fm(carrier, ratio, index, dur):
    t = t_axis(dur)
    mod = np.sin(2 * np.pi * carrier * ratio * t) * index
    return np.sin(2 * np.pi * carrier * t + mod)


def stone_hit(f=180.0, dur=0.09, punch=0.8):
    n = noise(dur) * 0.7
    body = fm(f, 1.4, 3.0, dur) * 0.5
    x = (lowpass(n, 0.35) + body) * env(int(SR * dur), 0.002, dur * 0.7)
    return saturate(x * punch, 1.3)


def crush(f=120.0, dur=0.4, punch=1.0):
    n = noise(dur) * 0.9
    thump = sweep(f * 2.2, f * 0.6, dur) * 0.8
    x = (lowpass(n, 0.22) + thump) * env(int(SR * dur), 0.002, dur * 0.8)
    return saturate(x * punch, 1.8)


def main():
    print("rb_* voices:")
    # start - the rising crack fanfare
    a = fm(220, 1.0, 2.0, 0.5) * env(int(SR * 0.5), 0.01, 0.3)
    b = fm(330, 1.5, 2.0, 0.4) * env(int(SR * 0.4), 0.01, 0.25)
    c = fm(440, 2.0, 3.0, 0.5) * env(int(SR * 0.5), 0.01, 0.3)
    x = np.zeros(int(SR * 0.85))
    x[:len(a)] += a
    x[int(SR*0.16):int(SR*0.16)+len(b)] += b * 0.8
    x[int(SR*0.34):int(SR*0.34)+len(c)] += c * 0.9
    write_wav(f"{SFX_DIR}/rb_start.wav", saturate(x * 0.8))

    # shoot - the tight volley pop
    x = lowpass(noise(0.05), 0.5) * env(int(SR * 0.05), 0.001, 0.03) * 0.6
    x += sweep(900, 300, 0.05) * env(int(SR * 0.05), 0.001, 0.035) * 0.7
    write_wav(f"{SFX_DIR}/rb_shoot.wav", saturate(x, 1.2))

    # hit - the stone chip
    write_wav(f"{SFX_DIR}/rb_hit.wav", stone_hit(200, 0.07, 0.7))

    # break - the crush burst
    write_wav(f"{SFX_DIR}/rb_break.wav", crush(140, 0.38, 0.95))

    # bounce - the soft thud
    write_wav(f"{SFX_DIR}/rb_bounce.wav", crush(90, 0.12, 0.5))

    # ground - the dusty splat
    x = lowpass(noise(0.22), 0.14) * env(int(SR * 0.22), 0.003, 0.18) * 0.9
    sw = sweep(160, 50, 0.2) * env(int(SR * 0.2), 0.002, 0.16) * 0.5
    x[:len(sw)] += sw
    write_wav(f"{SFX_DIR}/rb_ground.wav", saturate(x, 1.4))

    # golden - the bright fanfare
    x = None
    for i, f in enumerate([523.25, 659.25, 783.99, 1046.5]):
        seg = fm(f, 1.0, 1.5, 0.34) * env(int(SR * 0.34), 0.005, 0.26)
        hi = fm(f * 2, 1.0, 1.0, 0.2) * env(int(SR * 0.2), 0.005, 0.15) * 0.3
        seg[:len(hi)] += hi
        if x is None:
            x = seg.copy()
        else:
            end = int(SR * 0.13 * i)
            if end + len(seg) > len(x):
                x = np.concatenate([x, np.zeros(end + len(seg) - len(x))])
            x[end:end+len(seg)] += seg * 0.85
    write_wav(f"{SFX_DIR}/rb_golden.wav", saturate(x * 0.75))

    # mystery - the mystical chime
    x = np.zeros(int(SR * 1.1))
    for i, f in enumerate([392.0, 466.16, 587.33]):
        seg = fm(f, 2.01, 2.5, 0.6) * env(int(SR * 0.6), 0.01, 0.5)
        end = int(SR * 0.22 * i)
        if end + len(seg) > len(x):
            x = np.concatenate([x, np.zeros(end + len(seg) - len(x))])
        x[end:end+len(seg)] += seg * 0.5
    write_wav(f"{SFX_DIR}/rb_mystery.wav", saturate(x))

    # shieldsave - the electric ring
    x = fm(660, 1.5, 6.0, 0.4) * env(int(SR * 0.4), 0.004, 0.3)
    sw = sweep(1200, 400, 0.35) * env(int(SR * 0.35), 0.004, 0.28) * 0.4
    x[:len(sw)] += sw
    write_wav(f"{SFX_DIR}/rb_shieldsave.wav", saturate(x * 0.7))

    # death - the big crush + the wah
    x = crush(70, 0.9, 1.0)
    wah = sweep(300, 60, 0.9) * env(int(SR * 0.9), 0.01, 0.7) * 0.7
    x[:len(wah)] += wah
    write_wav(f"{SFX_DIR}/rb_death.wav", saturate(x))

    # the UI voices
    x = fm(880, 1.0, 1.0, 0.06) * env(int(SR * 0.06), 0.002, 0.04) * 0.5
    write_wav(f"{SFX_DIR}/rb_click.wav", x)
    x = fm(660, 1.5, 1.0, 0.12) * env(int(SR * 0.12), 0.002, 0.09) * 0.6
    hi = fm(990, 1.0, 1.0, 0.07) * env(int(SR * 0.07), 0.002, 0.05) * 0.5
    x = np.concatenate([x, np.zeros(int(SR * 0.05) + len(hi) - len(x))])
    x[int(SR*0.05):int(SR*0.05)+len(hi)] += hi
    write_wav(f"{SFX_DIR}/rb_buy.wav", saturate(x, 1.2))
    x = fm(523, 1.0, 1.0, 0.16) * env(int(SR * 0.16), 0.004, 0.12) * 0.55
    hi = fm(784, 1.0, 1.0, 0.12) * env(int(SR * 0.12), 0.004, 0.09) * 0.55
    x = np.concatenate([x, np.zeros(int(SR * 0.07) + len(hi) - len(x))])
    x[int(SR*0.07):int(SR*0.07)+len(hi)] += hi
    write_wav(f"{SFX_DIR}/rb_confirm.wav", saturate(x, 1.2))

    # the music: 118bpm, 8 bars of cave-drill (seamless loop)
    bpm = 118.0
    beat = 60.0 / bpm
    bars = 8
    total = beat * 4 * bars
    n = int(SR * total)
    t = t_axis(total)
    rs = np.random.RandomState(11)
    x = np.zeros(n)
    # the bass line (A minor-ish drone walk)
    notes = [110.0, 110.0, 130.81, 98.0, 110.0, 110.0, 146.83, 130.81]
    for bar in range(bars):
        f = notes[bar % len(notes)]
        start = int(bar * 4 * beat * SR)
        durb = 4 * beat
        seg = fm(f, 0.5, 1.2, durb) * env(int(SR * durb), 0.02, 0.35) * 0.30
        end = min(n, start + len(seg))
        x[start:end] += seg[:end - start]
    # the drill arp (the eighth-note pick)
    arp = [220.0, 261.63, 329.63, 261.63, 220.0, 196.0, 261.63, 329.63]
    step = beat / 2.0
    k = 0
    tt = 0.0
    while tt < total - 0.01:
        f = arp[k % len(arp)]
        seg = fm(f, 1.0, 1.4, step * 0.9) \
            * env(int(SR * step * 0.9), 0.004, step * 0.5) * 0.10
        start = int(tt * SR)
        end = min(n, start + len(seg))
        x[start:end] += seg[:end - start]
        tt += step
        k += 1
    # the stone shaker
    sh = lowpass(rs.uniform(-1, 1, n), 0.5)
    x += sh * 0.028 * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * (bpm / 60.0) * t)))
    # the soft pad breath
    x += fm(55.0, 1.01, 3.0, total) * 0.10
    # the seamless loop: crossfade the tail into the head
    fade = int(SR * 0.05)
    x[:fade] = x[:fade] * np.linspace(0, 1, fade) \
        + x[-fade:] * np.linspace(1, 0, fade)
    x = x[:-fade]
    x = saturate(x * 0.9, 1.25)
    write_wav(f"{MUS_DIR}/rb_theme.wav", x)
    print("done")


if __name__ == "__main__":
    main()
