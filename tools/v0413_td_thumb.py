#!/usr/bin/env python3
"""TOWER DESTROYER thumbnail composer (v041-3) - reads the td_thumb rig's
real captures (/tmp/td_thumb/*.png) and makes the 960x640 thumbnail
(law 44: the real render wins; law 35: a photograph of the game).
Picks the best hero frame, centers the 3:2 crop on the action, lifts the
shadows a touch so the dusk sky reads on small tiles, and writes
assets/thumbs/towerdestroyer.png. Deterministic; re-runs are identical."""
import os, sys
from PIL import Image, ImageEnhance

RIG = "/tmp/td_thumb"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "..", "projects", "gogabox", "assets", "thumbs",
                   "towerdestroyer.png")
W, H = 960, 640
# the hero ranking: the crowded firefight frames first
ORDER = ["crew_c", "crew_b", "crew_a"]


def pick() -> Image.Image:
    for name in ORDER:
        p = os.path.join(RIG, name + ".png")
        if os.path.exists(p):
            return Image.open(p).convert("RGB")
    sys.exit("no td_thumb captures found in " + RIG)


def main() -> None:
    src = pick()
    sw, sh = src.size
    # center the 3:2 crop LOW - the crew at the guns + the landing ring
    # are the story; the tower top is scenery
    target_ratio = W / H
    crop_h = int(sw / target_ratio)
    top = int((sh - crop_h) * 0.80)
    img = src.crop((0, top, sw, top + crop_h)).resize((W, H), Image.LANCZOS)
    img = ImageEnhance.Brightness(img).enhance(1.06)
    img = ImageEnhance.Color(img).enhance(1.08)
    img = ImageEnhance.Sharpness(img).enhance(1.12)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img.save(OUT)
    print("thumb:", OUT, os.path.getsize(OUT), "bytes")


if __name__ == "__main__":
    main()
