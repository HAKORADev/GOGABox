#!/usr/bin/env python3
"""
v0.3.9-6 THE PACMAN THUMB - the owner: "the game thumbnail is bad, do
in-game capturing with some programmed modifications to make it cool".

Takes the BEST raw frame from the capture rig (dev/thumb_capture, the
pacman_drive walks the dense 35x17 maze under the BLUE RUSH) and cools it:
  1. a soft BLOOM (bright pass blurred + screen) - the neon corridors glow
  2. a gentle vignette - the eye lands on the chomp
  3. a small saturation + contrast lift - the gold reads gold
  4. the universal 960x640 crop (rule R1, no text - rule R2)

Usage:
  python3 tools/v0396_pacman_thumb.py --raw /tmp/thumbs_raw/pacman_t0022.0.png \
      --out projects/gogabox/assets/thumbs/pacman.png [--focus 0.5]
"""
import argparse
import os
from PIL import Image, ImageEnhance, ImageFilter, ImageDraw

TW, TH = 960, 640


def crop3x2(img, focus=0.5):
    w, h = img.size
    if w / h > 3 / 2:
        cw, ch = int(h * 3 / 2), h
        x0 = int((w - cw) * focus)
        return img.crop((x0, 0, x0 + cw, ch))
    cw, ch = w, int(w * 2 / 3)
    y0 = int((h - ch) * focus)
    return img.crop((0, y0, w, y0 + ch))


def bloom(img, radius=14, strength=0.55):
    bright = img.filter(ImageFilter.GaussianBlur(radius))
    # keep only the bright energies (the glow lines, the gold, the blue)
    bright = ImageEnhance.Brightness(bright).enhance(1.6)
    return Image.blend(img, Image.blend(img, bright, 0.5), strength)


def vignette(img, power=0.42):
    w, h = img.size
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    d.ellipse((-w * 0.25, -h * 0.25, w * 1.25, h * 1.25), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(min(w, h) // 6))
    dark = ImageEnhance.Brightness(img).enhance(1.0 - power)
    return Image.composite(img, dark, mask)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--focus", type=float, default=0.5)
    a = ap.parse_args()

    img = Image.open(a.raw).convert("RGB")
    img = crop3x2(img, a.focus)
    img = img.resize((TW, TH), Image.LANCZOS)
    img = ImageEnhance.Color(img).enhance(1.18)
    img = ImageEnhance.Contrast(img).enhance(1.06)
    img = bloom(img)
    img = vignette(img)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    img.save(a.out)
    print("cool thumb ->", a.out)


if __name__ == "__main__":
    main()
