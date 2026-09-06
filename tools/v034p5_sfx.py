#!/usr/bin/env python3
"""v0.3.4-5 - THE PEEL CLEAVER's chop: a synthesized whoosh+thud (the raw CC0
hunt from the v034 round is gone with the sandbox, so numpy it is)."""
import numpy as np, wave, os

SR = 44100
OUT = "/home/z/my-project/repo/GOGABox/projects/gogabox/assets/audio/sfx/cs_slash.wav"

t = np.linspace(0, 0.30, int(SR * 0.30), endpoint=False)
# the whoosh: band-passed noise sweeping down (the swing)
noise = np.random.default_rng(7).standard_normal(t.size)
sweep = np.sin(2 * np.pi * (900 - 2600 * t / 0.30) * t)   # the airy tone
whoosh = noise * np.exp(-t * 9.0) * 0.55 + sweep * np.exp(-t * 14.0) * 0.25
# the chop landing at 0.16s: a low thump
thump_t = np.clip(t - 0.16, 0, None)
thump = np.sin(2 * np.pi * (150 - 500 * thump_t) * np.clip(thump_t, 0, 0.06)) \
        * np.exp(-thump_t * 34.0) * (t >= 0.16) * 0.9
sig = whoosh + thump
sig = np.tanh(sig * 1.6) * 0.88
pcm = (sig * 32767).astype(np.int16)
with wave.open(OUT, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(pcm.tobytes())
print("saved", OUT)
