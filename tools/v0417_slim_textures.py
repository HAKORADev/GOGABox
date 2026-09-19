#!/usr/bin/env python3
"""
v0.4.0-17 THE 2D TEXTURE LAW - no VRAM compression on 2D art.

A set of big 2D pieces (the box backgrounds, the game thumbnails, the chess
woods, the splash, ui plates) sat on compress/mode=2 (VRAM compressed), so
the export carried 19.4 MB of S3TC blocks (Windows) + 19.4 MB of ETC2
(Android) for 6.3 MB of source pixels - 3x the weight, blocky gradients on
top. 2D screen art gets the lossless import like every other png in the
box: crisper AND smaller on BOTH platforms.

WHAT: for every texture .import in assets/ with compress/mode=2:
  compress/mode=2  ->  compress/mode=0      (lossless, the 2D law)
  mipmaps/generate=true -> false            (2D law: the other ~2000 pngs
                                             all run mip-free)
Re-run safe: a second pass finds nothing.
"""
import os, sys, glob

ROOT = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.join(ROOT, "..", "projects", "gogabox")


def main() -> int:
    imports = sorted(glob.glob(os.path.join(PROJ, "assets", "**", "*.import"),
                               recursive=True))
    patched = 0
    for imp in imports:
        with open(imp, encoding="utf-8") as f:
            src = f.read()
        if "compress/mode=2" not in src:
            continue
        out = src.replace("compress/mode=2", "compress/mode=0")
        out = out.replace("mipmaps/generate=true", "mipmaps/generate=false")
        with open(imp, "w", encoding="utf-8") as f:
            f.write(out)
        rel = os.path.relpath(imp, PROJ)
        print("lossless:", rel[:-7])
        patched += 1
    print("patched %d texture imports to the 2D lossless law" % patched)
    return 0


if __name__ == "__main__":
    sys.exit(main())
