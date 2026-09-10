#!/usr/bin/env python3
"""v038p5_domino_real.py - THE AS-IS SCRAPE (v0.3.8-5 round 2, the owner's
law: "scrape the code and the assets and put them as-is, same thing").

Source: the studied GameSnacks DominoBattle HTML5 build (study_out/db_assets,
fetched with tools/study/fetch_webgame.py + the atlas URLs). This lifts the
REAL pre-rendered art out of the theme atlases and lands it in the repo:

  assets/games/domino/grounds/<t>.png      the real bg_game ground (per theme)
  assets/games/domino/tiles/<t>/<a>-<b>.png  the 28 real faces (a<=b)
  assets/games/domino/tiles/<t>/back.png   the real back (the blank plate)
  assets/games/domino/shadows/shadow1.png  the thin edge strip (as-is)
  assets/games/domino/shadows/shadow2.png  the soft band shadow (as-is)

Nothing here is redrawn or "improved" - the pixels ship as they ship.
"""

import json
import os
import shutil
from PIL import Image

SRC = "/home/z/my-project/study_out/db_assets"
OUT = "/home/z/my-project/gogabox/projects/gogabox/assets/games/domino"

THEMES = ["bg1", "bg2", "bg3", "bg4", "bg5", "bg6"]


def frames_of(d: dict) -> dict:
    fr = d["frames"]
    if isinstance(fr, dict):
        return fr
    return {f["filename"]: f for f in fr}


def crop(img: Image.Image, fr: dict, name: str) -> Image.Image:
    f = fr[name]["frame"]
    return img.crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"]))


def main() -> None:
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    os.makedirs(f"{OUT}/grounds", exist_ok=True)
    os.makedirs(f"{OUT}/shadows", exist_ok=True)

    # the pak atlas carries the shared shadow strips
    pak = Image.open(f"{SRC}/pak.png")
    pakfr = frames_of(json.load(open(f"{SRC}/pak.json")))
    for want, out in [("gt.png", "shadow1.png")]:
        if want in pakfr:
            crop(pak, pakfr, want).save(f"{OUT}/shadows/{out}")

    total = 0
    for t in THEMES:
        img = Image.open(f"{SRC}/{t}.png")
        fr = frames_of(json.load(open(f"{SRC}/{t}.json")))
        # the ground, as-is
        crop(img, fr, "bg_game.png").save(f"{OUT}/grounds/{t}.png")
        total += os.path.getsize(f"{OUT}/grounds/{t}.png")
        # the 28 faces + the blank back, as-is
        tdir = f"{OUT}/tiles/{t}"
        os.makedirs(tdir, exist_ok=True)
        for a in range(7):
            for b in range(a, 7):
                crop(img, fr, f"{a}-{b}.png").save(f"{tdir}/{a}-{b}.png")
        crop(img, fr, "0.png").save(f"{tdir}/back.png")
        # the real band shadow (bg_game_shadow2) once, from bg1
        if t == "bg1":
            crop(img, fr, "bg_game_shadow2.png").save(f"{OUT}/shadows/shadow2.png")
            crop(img, fr, "bg_game_shadow1.png").save(f"{OUT}/shadows/shadow1.png")

    size = 0
    for root, _, files in os.walk(OUT):
        for f in files:
            size += os.path.getsize(os.path.join(root, f))
    print(f"[ok] domino as-is assets: {size/1024:.0f} KB under {OUT}")


if __name__ == "__main__":
    main()
