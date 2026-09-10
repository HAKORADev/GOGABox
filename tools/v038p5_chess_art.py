#!/usr/bin/env python3
"""v038p5_chess_art.py - CHECKMATE's parlor background (v0.3.8-5).
100% procedural - nothing from the studied web game ships (THE USAGE LAW).

Study note (GameSnacks ChessClassic): the room is warm dark wood with a
vertical grain, the trays are parchment, the board sits in an ornate frame.
Ours: the same ROOM MOOD, drawn by code - deep walnut field with long grain
streaks, a soft candle-warm vignette, and a faint noise tooth so the GL
filtering never shimmers. Portrait + landscape, one seed.

Output: assets/games/chess/bg_wood_p.png (1080x1920)
        assets/games/chess/bg_wood_l.png (1920x1080)
"""

import os

import numpy as np
from PIL import Image

OUT = "projects/gogabox/assets/games/chess"


def wood(w: int, h: int, seed: int) -> Image.Image:
    rng = np.random.default_rng(seed)
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    # the grain: long VERTICAL streaks - one noise value per column, smoothed,
    # then wavied per row so the planks breathe instead of tiling
    col = rng.uniform(0, 1, w)
    k = 9
    kernel = np.hanning(k * 2 + 1)
    kernel /= kernel.sum()
    col_s = np.convolve(np.pad(col, k, mode="edge"), kernel, mode="same")[k:-k]
    grain = np.tile(col_s[None, :], (h, 1))
    # gentle wave: each row's sample point drifts a little with y
    wave = (np.sin(y * 0.011 + col_s.mean() * 6.0) * 2.2
            + np.sin(y * 0.031) * 1.1)
    idx = np.clip((x + wave).astype(int), 0, w - 1)
    grain = np.take_along_axis(grain, idx, axis=1)
    # the fine tooth along the streaks
    fine = rng.uniform(0, 1, (h // 3 + 2, w // 3 + 2))
    from PIL import Image as I
    fi = I.fromarray((fine * 255).astype(np.uint8)).resize(
        (w, h), I.BILINEAR)
    fine = np.asarray(fi, dtype=np.float32) / 255.0
    fine = np.take_along_axis(fine, idx, axis=1)
    # the base: deep walnut (the reference room reads ~ #3a2a1c mid)
    base = np.zeros((h, w, 3), dtype=np.float32)
    base[..., 0] = 0.235      # R
    base[..., 1] = 0.165      # G
    base[..., 2] = 0.105      # B
    # grain modulates lightness in long bands
    lum = (grain - 0.5) * 0.14 + (fine - 0.5) * 0.09
    # a few vertical plank seams (dark 2px lines every ~190 px, wavied)
    seam_x = (idx % 190)
    seams = (np.abs(seam_x - 95.0) < 1.6).astype(np.float32)
    lum -= seams * 0.07
    base += lum[..., None] * np.array([1.0, 0.9, 0.8])
    # the candle-warm vignette
    cx, cy = w * 0.5, h * 0.42
    d = np.sqrt(((x - cx) / (w * 0.72)) ** 2 + ((y - cy) / (h * 0.62)) ** 2)
    vig = 1.0 - np.clip(d - 0.35, 0, 1) * 0.5
    base *= vig[..., None]
    # warm highlight pool upper-center
    glow = np.exp(-(((x - cx) / (w * 0.5)) ** 2
                    + ((y - h * 0.25) / (h * 0.35)) ** 2))
    base += glow[..., None] * np.array([0.045, 0.03, 0.015])[None, None, :]
    # the tooth: tiny noise so bilinear sampling never shimmers
    base += (rng.uniform(-1, 1, (h, w, 1)) * 0.006)
    out = Image.fromarray((np.clip(base, 0, 1) * 255).astype(np.uint8))
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    print("v038p5_chess_art: the parlor room")
    wood(1080, 1920, 20260910).save(os.path.join(OUT, "bg_wood_p.png"))
    print("  bg_wood_p.png 1080x1920")
    wood(1920, 1080, 20260910).save(os.path.join(OUT, "bg_wood_l.png"))
    print("  bg_wood_l.png 1920x1080")


if __name__ == "__main__":
    main()
