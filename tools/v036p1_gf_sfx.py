#!/usr/bin/env python3
"""v036p1_gf_sfx.py - GEOMETRY FLASH v0.3.6-1 audio additions.

The power-up layer + the shield ceremony (100% synthesized, numpy):
  gf_pow      the capsule pickup - a bright two-note "take it" chime with a
              rising sparkle tail (played when any power-up is collected)
  gf_pow_end  the power expires - a soft descending two-note, never harsh
  gf_save     the EXTRA LIFE rescue - a heroic mini-fanfare (three fast
              notes up + a shimmer), the "you lived" moment
  gf_reentry  the cool out-of-screen re-entry - a whoosh that lands on a
              soft stab, the beam-drop sound

Re-derive: python3 tools/v036p1_gf_sfx.py
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from v036_gf_sfx import (SR, write_wav, t_axis, env, sine, square, saw,  # noqa
                         sweep, lowpass, highpass, noise, bell, place)

SFX_DIR = "projects/gogabox/assets/audio/sfx"


def sfx_pow():
    """Capsule pickup: E5->B5 bright chime + an upward sparkle hiss."""
    dur = 0.55
    out = np.zeros(int(SR * dur))
    place(out, 0.00, bell(659.3, 0.30), 0.55)       # E5
    place(out, 0.09, bell(987.8, 0.42), 0.60)       # B5
    hiss = highpass(noise(dur), 0.72) * env(int(SR * dur), 0.10, 0.38, 0.30)
    out += hiss * 0.16
    shimmer = sine(1975.5, dur) * np.exp(-7.0 * t_axis(dur)) * 0.12
    out += shimmer
    out *= env(len(out), 0.004, 0.30)
    return out * 0.9


def sfx_pow_end():
    """Expiry: B4->E4 soft, a gentle 'done' - the world speeds back up."""
    dur = 0.42
    out = np.zeros(int(SR * dur))
    place(out, 0.00, bell(493.9, 0.22, decay=9.0), 0.42)
    place(out, 0.13, bell(329.6, 0.30, decay=8.0), 0.46)
    out *= env(len(out), 0.004, 0.22)
    return out * 0.8


def sfx_save():
    """The rescue fanfare: A4-C5-E5 fast (A minor lift) + a shimmer cap."""
    dur = 0.85
    out = np.zeros(int(SR * dur))
    for i, f in enumerate((440.0, 523.3, 659.3)):
        n = square(f, 0.16, 0.5) * env(int(SR * 0.16), 0.006, 0.10)
        place(out, i * 0.075, lowpass(n, 0.5), 0.30)
    # the shimmer: a detuned octave sparkle
    for f in (1318.5, 1319.9):
        out += sine(f, dur) * np.exp(-5.5 * t_axis(dur)) * 0.10
    place(out, 0.225, bell(659.3, 0.5, decay=5.0), 0.5)
    place(out, 0.225, bell(1318.5, 0.5, decay=6.0), 0.25)
    out *= env(len(out), 0.004, 0.35)
    return out * 0.95


def sfx_reentry():
    """The beam drop: a falling-then-rising whoosh landing on a soft stab."""
    dur = 0.6
    out = np.zeros(int(SR * dur))
    w = sweep(900.0, 180.0, 0.30) * env(int(SR * 0.30), 0.02, 0.16, 0.8)
    out[:len(w)] += w * 0.30
    w2 = sweep(240.0, 760.0, 0.22) * env(int(SR * 0.22), 0.01, 0.12, 0.8)
    i = int(0.26 * SR)
    out[i:i + len(w2)] += w2 * 0.26
    stab = square(220.0, 0.26, 0.5) * env(int(SR * 0.26), 0.004, 0.20)
    out[i:i + len(stab)] += lowpass(stab, 0.42) * 0.34
    out[i:i + len(stab)] += bell(440.0, 0.30, decay=6.0)[:len(stab)] * 0.30
    out *= env(len(out), 0.004, 0.30)
    return out * 0.95


def main():
    os.makedirs(SFX_DIR, exist_ok=True)
    print("v036p1 sfx:")
    write_wav(os.path.join(SFX_DIR, "gf_pow.wav"), sfx_pow())
    write_wav(os.path.join(SFX_DIR, "gf_pow_end.wav"), sfx_pow_end())
    write_wav(os.path.join(SFX_DIR, "gf_save.wav"), sfx_save())
    write_wav(os.path.join(SFX_DIR, "gf_reentry.wav"), sfx_reentry())


if __name__ == "__main__":
    main()
