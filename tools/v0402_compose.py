#!/usr/bin/env python3
"""v040-2 THE COMPOSITOR - every original pixel lands in hwsrc EXACTLY as
the original engine drew it: color image RGB + mask twin LUMINANCE = alpha.

THE LAWS (learned by opening the files, not reading names):
  * the _ twins (X_.png / X_.gif) are fully OPAQUE white-on-black masks -
    their ALPHA channel is constant 255, the shape lives in LUMINANCE.
  * the color twins are .jpg (no alpha at all) or .gif (PopCap colorkey).
  * the strips are STATIC horizontal frames (n_frames == 1 everywhere).
  * some files already carry real alpha (red star hq_bg.png) - kept as-is.
  * target1-8 / shield.jpg / tankflash sit on black -> additive in-game.
  * powerups.png = 12 icons of 32x32; upgrades.png = 6 bubbles of 72x72.
"""
import os
import shutil
import sys

from PIL import Image
import numpy as np

ORIG = "/home/z/my-project/v040_2_study/hw_orig/HeavyWeapon/Images"
DST = "/home/z/my-project/gogabox/projects/gogabox/assets/games/hwsrc"

report = {"composed": [], "copied": [], "skipped": []}


def lum_alpha(img: Image.Image) -> np.ndarray:
    """alpha plane = mask luminance (the PopCap mask law)"""
    a = np.asarray(img.convert("RGB"), dtype=np.float32)
    return 0.299 * a[:, :, 0] + 0.587 * a[:, :, 1] + 0.114 * a[:, :, 2]


def compose(color_path: str, mask_path: str) -> Image.Image:
    col = Image.open(color_path).convert("RGB")
    msk = Image.open(mask_path).convert("RGB")
    if col.size != msk.size:
        msk = msk.resize(col.size, Image.NEAREST)
    out = np.dstack([np.asarray(col, dtype=np.uint8),
                     lum_alpha(msk).astype(np.uint8)])
    return Image.fromarray(out, "RGBA")


def key_colorkey(img: Image.Image) -> Image.Image:
    """gif with no mask twin: the corner pixel is the transparent key"""
    rgba = np.asarray(img.convert("RGBA"), dtype=np.uint8).copy()
    key = rgba[0, 0, :3].astype(np.int16)
    dist = np.abs(rgba[:, :, :3].astype(np.int16) - key).sum(axis=2)
    rgba[:, :, 3] = np.where(dist <= 24, 0, 255).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def save(img: Image.Image, rel: str) -> None:
    dst = os.path.join(DST, rel)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    img.save(dst)
    report["composed" if rel not in report["copied"] else "copied"].append(rel)


def handle_pair(dirpath: str, base: str, exts) -> bool:
    """color + _ mask twin -> composed; returns True when handled"""
    color = mask = None
    for e in exts:
        p = os.path.join(dirpath, base + e)
        if os.path.exists(p):
            color = p
            break
    if color is None:
        return False
    stem = os.path.splitext(color)[0]
    for e in (".png", ".gif", ".jpg"):
        p = stem + "_" + e
        if os.path.exists(p):
            mask = p
            break
    rel = os.path.relpath(stem, ORIG) + ".png"
    # hwsrc law: DIRECTORIES lowercase, filenames keep their true case;
    # ROOT files (no dir part) live in sprites/
    parts = rel.split(os.sep)
    if len(parts) == 1:
        parts = ["sprites"] + parts
    rel = os.path.join(*[p.lower() for p in parts[:-1]] + [parts[-1]])
    if mask is not None:
        save(compose(color, mask), rel)
    else:
        im = Image.open(color)
        if im.mode in ("P", "L"):
            save(key_colorkey(im), rel)
        elif im.mode == "RGB":
            save(im.convert("RGBA"), rel)  # opaque - the code blends it
        else:
            save(im.convert("RGBA"), rel)
    return True


def walk(root: str, sub: str = "") -> None:
    full = os.path.join(root, sub)
    for name in sorted(os.listdir(full)):
        p = os.path.join(full, name)
        if os.path.isdir(p):
            walk(root, os.path.join(sub, name))
            continue
        if name.endswith("_.png") or name.endswith("_.gif"):
            continue  # masks ride their color twins
        base, ext = os.path.splitext(name)
        if ext.lower() in (".jpg", ".gif", ".png"):
            if not handle_pair(full, base, (".jpg", ".gif", ".png")):
                report["skipped"].append(os.path.relpath(p, ORIG))


def main() -> None:
    # 1) the whole Images tree (root sprites, Backgrounds, Anims, bosses...)
    walk(ORIG)

    # 2) the icon cuts (the original sheets, sliced at their true cells)
    pups = Image.open(os.path.join(ORIG, "powerups.png")).convert("RGBA")
    for i in range(12):
        save(pups.crop((i * 32, 0, (i + 1) * 32, 32)),
             "sprites/pup_%02d.png" % (i + 1))
    upgs = Image.open(os.path.join(ORIG, "upgrades.png")).convert("RGBA")
    for i in range(6):
        save(upgs.crop((i * 72, 0, (i + 1) * 72, 72)),
             "sprites/upg_%d.png" % (i + 1))

    # 3) the mask files and stale keyed twins die in hwsrc - the composed
    #    names are the only truth the game may point at
    killed = []
    for dirpath, _dirs, files in os.walk(DST):
        for f in files:
            p = os.path.join(dirpath, f)
            if f.endswith("_.png") or f.endswith("_keyed.png"):
                os.remove(p)
                killed.append(os.path.relpath(p, DST))
            elif f.endswith(".import"):
                src_png = p[: -len(".import")]
                if not os.path.exists(src_png):
                    os.remove(p)
                    killed.append(os.path.relpath(p, DST))
    report["killed"] = killed

    print("composed/copied:", len(report["composed"]) + len(report["copied"]))
    print("killed masks:", len(killed))
    print("skipped (no twin, kept opaque):", len(report["skipped"]))
    for s in report["skipped"][:40]:
        print("   ", s)


if __name__ == "__main__":
    sys.exit(main())
