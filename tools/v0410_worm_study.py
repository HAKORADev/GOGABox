# RETIRED (v040-11): the owner ordered the original-cut art pipeline DEAD
# ("nuke all original_art and make our own one"). This tool cut/modded the
# original's own sprites - it must NEVER run again. Our art lives in
# tools/v0411_worm_ours.py (drawn by code, zero original bytes).
# =====================================================================================
#!/usr/bin/env python3
"""v040-10 - rebuild the DEADLY WORM study_out from the fresh APK pull.

Reads : study_out/com.playcreek.DeathWorm_Free/assets/game  (never committed)
Writes: study_out/deathworm/sprites/  (all sprites, RGBA pngs)
        study_out/deathworm/data/     (teacher tables, readable copies)
        study_out/deathworm/REPORT.json

The atlas law (same family as Heavy Weapon): color jpg + mask jpg
(_a suffix, luminance == alpha). DragonBones skins are cut with the
*_tex.json SubTexture rects.
"""
import json
import os
import shutil
import sys

import numpy as np
from PIL import Image

GAME = os.path.expanduser(
    "~/my-project/gogabox/study_out/com.playcreek.DeathWorm_Free/assets/game")
OUT = os.path.expanduser("~/my-project/study_out/deathworm")


def log(m):
    print(m, flush=True)


def ensure(p):
    os.makedirs(p, exist_ok=True)
    return p


def compose(color_path, mask_path):
    """color RGB + mask luminance = alpha."""
    c = Image.open(color_path).convert("RGB")
    m = Image.open(mask_path).convert("L")
    if m.size != c.size:
        m = m.resize(c.size, Image.NEAREST)
    rgba = np.dstack([np.asarray(c, np.uint8), np.asarray(m, np.uint8)])
    return Image.fromarray(rgba, "RGBA")


def cut_map(color_img, mask_img, rect, flip=False):
    x, y, w, h = rect
    c = color_img.crop((x, y, x + w, y + h))
    m = mask_img.crop((x, y, x + w, y + h))
    a = np.asarray(m.convert("L"), np.uint8)
    rgb = np.asarray(c.convert("RGB"), np.uint8)
    return Image.fromarray(np.dstack([rgb, a]), "RGBA")


def parse_atlas_txt(path):
    """count line, then per frame: name line + FOUR int lines (x,y,w,h)."""
    with open(path, "r", errors="replace") as f:
        lines = [ln.strip() for ln in f if ln.strip()]
    frames = []
    i = 0
    if lines and lines[0].isdigit():
        i = 1
    n = len(lines)
    while i < n:
        name = lines[i].replace("\\", "/")
        if i + 4 >= n + 1 and i + 4 > n:
            break
        if i + 4 < n + 1 and all(
                j < n and lines[j].lstrip("-").isdigit()
                for j in range(i + 1, i + 5)):
            try:
                x, y, w, h = (int(lines[j]) for j in range(i + 1, i + 5))
                frames.append((name, (x, y, w, h)))
                i += 5
                continue
            except ValueError:
                pass
        i += 1
    return frames


def main():
    sprites = ensure(os.path.join(OUT, "sprites"))
    data = ensure(os.path.join(OUT, "data"))
    report = {"atlases": {}, "objects": 0, "dbskins": {}, "locations": []}

    # ---- 1. AutoAtlases ------------------------------------------------
    aa = os.path.join(GAME, "i_iphone_2x", "AutoAtlases")
    for fn in sorted(os.listdir(aa)):
        if not fn.endswith(".txt"):
            continue
        base = fn[:-4]
        jpg = os.path.join(aa, base + ".jpg")
        mask = os.path.join(aa, base + "_a.jpg")
        if not os.path.exists(jpg):
            log(f"! no jpg for {base}")
            continue
        has_mask = os.path.exists(mask)
        cimg = Image.open(jpg)
        mimg = Image.open(mask) if has_mask else None
        frames = parse_atlas_txt(os.path.join(aa, fn))
        ok = 0
        for name, rect in frames:
            flat = name.replace("/", "_")
            try:
                if mimg is not None:
                    sp = cut_map(cimg, mimg, rect)
                else:
                    x, y, w, h = rect
                    sp = cimg.convert("RGBA").crop((x, y, x + w, y + h))
                sp.save(os.path.join(sprites, flat + ".png"))
                ok += 1
            except Exception as e:
                log(f"  ! {base}:{name}: {e}")
        report["atlases"][base] = {"frames": len(frames), "cut": ok,
                                   "masked": has_mask}
        log(f"atlas {base}: {ok}/{len(frames)} cut (mask={has_mask})")

    # ---- 2. objects / particles / vehicles / worm single pairs ---------
    for sub in ("objects", "particles", "vehicles", "worm"):
        d = os.path.join(GAME, "i_iphone_2x", sub)
        if not os.path.isdir(d):
            continue
        for fn in sorted(os.listdir(d)):
            if not fn.endswith(".jpg") or fn.endswith("_a.jpg"):
                continue
            base = fn[:-4]
            mask = os.path.join(d, base + "_a.jpg")
            dst = os.path.join(sprites, f"{sub}_{base}.png")
            if os.path.exists(mask):
                compose(os.path.join(d, fn), mask).save(dst)
            else:
                Image.open(os.path.join(d, fn)).convert("RGBA").save(dst)
            report["objects"] += 1
    log(f"objects/particles/vehicles/worm pairs: {report['objects']}")

    # ---- 3. DragonBones worm skins -------------------------------------
    sk = os.path.join(GAME, "Data", "DragonBones", "Skins")
    texdir = os.path.join(GAME, "i_iphone", "DragonBones", "Skins")
    for fn in sorted(os.listdir(sk)):
        if not fn.endswith("_tex.json"):
            continue
        base = fn[:-9]  # strip _tex.json
        tj = json.load(open(os.path.join(sk, fn)))
        img_name = tj.get("imagePath", base + "_tex.png")
        jpg = os.path.join(texdir, img_name.replace(".png", ".jpg"))
        mask = os.path.join(texdir, img_name.replace(".png", "") + "_a.jpg")
        if not os.path.exists(jpg):
            jpg2 = os.path.join(texdir, base + "_tex.jpg")
            if os.path.exists(jpg2):
                jpg = jpg2
        if not os.path.exists(jpg):
            log(f"! dbskin {base}: no texture {img_name}")
            continue
        cimg = Image.open(jpg)
        mimg = Image.open(mask) if os.path.exists(mask) else None
        n = 0
        for st in tj.get("SubTexture", []):
            nm = st["name"].replace("/", "_")
            rect = (int(st.get("x", 0)), int(st.get("y", 0)),
                    int(st.get("width", 0)), int(st.get("height", 0)))
            if rect[2] <= 0 or rect[3] <= 0:
                continue
            if mimg is not None:
                sp = cut_map(cimg, mimg, rect)
            else:
                sp = cimg.convert("RGBA").crop(
                    (rect[0], rect[1], rect[0] + rect[2], rect[1] + rect[3]))
            dst = os.path.join(sprites, f"dbskin_{base}_{nm}.png")
            sp.save(dst)
            n += 1
        report["dbskins"][base] = n
        log(f"dbskin {base}: {n} parts")

    # ---- 4. location layers (1x, full cross-sections) ------------------
    locdir = os.path.join(GAME, "i_iphone", "locations")
    for loc in sorted(os.listdir(locdir)):
        if not os.path.isdir(os.path.join(locdir, loc)):
            continue
        dst = ensure(os.path.join(OUT, "locations", loc))
        n = 0
        for fn in sorted(os.listdir(os.path.join(locdir, loc))):
            if fn.endswith(".jpg"):
                shutil.copy(os.path.join(locdir, loc, fn),
                            os.path.join(dst, fn))
                n += 1
        report["locations"].append((loc, n))
    log(f"locations: {[(l, n) for l, n in report['locations']]}")

    # ---- 5. teacher data ------------------------------------------------
    for sub in ("Data", "levels_layouts"):
        src = os.path.join(GAME, sub)
        if os.path.isdir(src):
            shutil.copytree(src, os.path.join(data, sub), dirs_exist_ok=True)
            log(f"data {sub} copied")

    # sounds list (names only, study material)
    snd = os.path.join(GAME, "SoundAndroid")
    if os.path.isdir(snd):
        report["sounds"] = sorted(f for f in os.listdir(snd)
                                  if f.endswith(".ogg"))
        shutil.copytree(snd, os.path.join(data, "SoundAndroid"),
                        dirs_exist_ok=True)

    json.dump(report, open(os.path.join(OUT, "REPORT.json"), "w"), indent=1)
    log(f"DONE: {OUT} - sprites={len(os.listdir(sprites))}")


if __name__ == "__main__":
    main()
