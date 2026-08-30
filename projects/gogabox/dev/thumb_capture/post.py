#!/usr/bin/env python3
"""
Thumbnail POST-STAGE - runs OUTSIDE Godot, part of the dev-only capture
pipeline (dev/ is excluded from every export preset - never ships).

Takes raw native-resolution frames from capture.tscn and produces:
  1. final 960x640 candidates (focus-crop to 3:2, LANCZOS downscale)
  2. contact sheets per game (for the vision review pass)
  3. a before/after proof sheet (old thumb vs new thumb)

Owner rules implemented here (docs/THUMBNAILS.md):
  R1  universal canvas 960x640
  R2  NO text is ever added here by default; optional helpers exist
      (game-font-first per R3) but stay unused unless a drive opts in

Usage:
  python3 post.py --raw /tmp/thumbs_raw --out /tmp/thumbs_cooked \
      [--game snake] [--focus 0.5] [--all-focus 0.35,0.5,0.65]

  --all-focus renders EVERY focus variant into <out>/focus_<f>/ so the
  review can pick the best band per game in one pass.
"""
import argparse
import glob
import os
from PIL import Image, ImageDraw, ImageFont

TW, TH = 960, 640          # the universal thumbnail canvas (rule R1)
GAMES_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "thumbs")


def crop_resize(img: Image.Image, focus: float) -> Image.Image:
    """Native frame -> 3:2 focus band -> 960x640 (owner: native run, then
    downscale to the thumbnail size). focus 0=top band, 1=bottom band."""
    w, h = img.size
    if w / h > 3 / 2:                       # landscape native: crop sides
        cw, ch = int(h * 3 / 2), h
        x0 = int((w - cw) * focus)
        box = (x0, 0, x0 + cw, ch)
    else:                                   # portrait native: crop a band
        cw, ch = w, int(w * 2 / 3)
        y0 = int((h - ch) * focus)
        box = (0, y0, w, y0 + ch)
    return img.crop(box).resize((TW, TH), Image.LANCZOS)


def label_strip(img: Image.Image, txt: str) -> Image.Image:
    fnt = ImageFont.load_default(24)
    strip = Image.new("RGB", (img.width, 34), (16, 10, 6))
    d = ImageDraw.Draw(strip)
    d.text((8, 5), txt, font=fnt, fill=(255, 210, 140))
    out = Image.new("RGB", (img.width, img.height + 34), (16, 10, 6))
    out.paste(strip, (0, 0))
    out.paste(img, (0, 34))
    return out


def contact_sheet(paths, out_path, focus, cols=5):
    if not paths:
        return
    cell_w, cell_h = 480, 320 + 34
    rows = (len(paths) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cell_w, rows * cell_h), (28, 18, 10))
    d = ImageDraw.Draw(sheet)
    for i, p in enumerate(sorted(paths)):
        img = crop_resize(Image.open(p).convert("RGB"), focus)
        img = img.resize((cell_w, 320), Image.LANCZOS)
        x, y = (i % cols) * cell_w, (i // cols) * cell_h
        sheet.paste(img, (x, y + 34))
        name = os.path.basename(p).replace(".png", "")
        d.text((x + 8, y + 6), name, font=ImageFont.load_default(22),
               fill=(255, 210, 140))
    sheet.save(out_path)


def before_after(game: str, new_path: str, out_path):
    old_p = os.path.join(GAMES_DIR, "%s.png" % game)
    panel_w, panel_h = 480, 320 + 34
    sheet = Image.new("RGB", (panel_w * 2, panel_h), (28, 18, 10))
    d = ImageDraw.Draw(sheet)
    if os.path.exists(old_p):
        old = Image.open(old_p).convert("RGB").resize((panel_w, 320), Image.LANCZOS)
    else:
        old = Image.new("RGB", (panel_w, 320), (60, 40, 20))
    sheet.paste(old, (0, 34))
    new = Image.open(new_path).convert("RGB").resize((panel_w, 320), Image.LANCZOS)
    sheet.paste(new, (panel_w, 34))
    d.text((8, 6), "BEFORE (480x320 hand-drawn)", font=ImageFont.load_default(22), fill=(255, 150, 120))
    d.text((panel_w + 8, 6), "AFTER (960x640 real gameplay)", font=ImageFont.load_default(22), fill=(140, 255, 160))
    sheet.save(out_path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", default="/tmp/thumbs_raw")
    ap.add_argument("--out", default="/tmp/thumbs_cooked")
    ap.add_argument("--game", default=None)
    ap.add_argument("--focus", type=float, default=0.5)
    ap.add_argument("--all-focus", default=None,
                    help="comma list, e.g. 0.35,0.5,0.65 - renders a focus sweep")
    ap.add_argument("--pick", default=None,
                    help="raw filename to emit as the final <game>_final.png")
    ap.add_argument("--final-name", default=None)
    args = ap.parse_args()

    os.makedirs(args.out, exist_ok=True)
    games = sorted({os.path.basename(p).split("_t")[0]
                    for p in glob.glob(os.path.join(args.raw, "*.png"))})
    if args.game:
        games = [g for g in games if g == args.game]

    # single-frame pick -> final candidate
    if args.pick:
        img = Image.open(os.path.join(args.raw, args.pick)).convert("RGB")
        crop_resize(img, args.focus).save(
                os.path.join(args.out, args.final_name or (args.pick)))
        print("final ->", os.path.join(args.out, args.final_name or args.pick))
        return

    for g in games:
        paths = glob.glob(os.path.join(args.raw, "%s_t*.png" % g))
        gdir = os.path.join(args.out, g)
        os.makedirs(gdir, exist_ok=True)
        if args.all_focus:
            for f in [float(x) for x in args.all_focus.split(",")]:
                fd = os.path.join(gdir, "focus_%.2f" % f)
                os.makedirs(fd, exist_ok=True)
                contact_sheet(paths, os.path.join(fd, "_sheet.png"), f)
        else:
            contact_sheet(paths, os.path.join(gdir, "_sheet.png"), args.focus)
            for p in paths:
                crop_resize(Image.open(p).convert("RGB"), args.focus).save(
                        os.path.join(gdir, os.path.basename(p)))
        print("cooked %s: %d candidates -> %s" % (g, len(paths), gdir))


if __name__ == "__main__":
    main()
