#!/usr/bin/env python3
"""v041 THE MIPMAPS LAW - generate mipmaps on the 2D raster art.

The PC windows render the 1080x1920 design downscaled (a 900px-tall
monitor shows it at ~0.6-0.75) and linear sampling without mips aliased
the art into the jagged thumbnails / cloud-ish wash the owner caught
(the same art is clean on the FHD+ phone because it samples 1:1).
project.godot flips canvas items to trilinear; THIS tool flips
mipmaps/generate=true on every lossless 2D texture import so the mips
actually exist. VRAM-compressed imports (s3tc/etc2) are left alone -
the slim pack laws own those.
"""
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..",
                    "projects", "gogabox", "assets")


def main():
    touched = 0
    skipped = 0
    for base, _dirs, files in os.walk(ROOT):
        for f in files:
            if not f.endswith(".import"):
                continue
            p = os.path.join(base, f)
            with open(p, "r", encoding="utf-8") as fh:
                txt = fh.read()
            if "mipmaps/generate=" not in txt:
                skipped += 1
                continue
            # only lossless 2D textures (compress/mode=0); VRAM (2) keeps
            # its own import laws
            if "compress/mode=2" in txt:
                skipped += 1
                continue
            if "mipmaps/generate=true" in txt:
                continue
            txt = txt.replace("mipmaps/generate=false",
                              "mipmaps/generate=true")
            with open(p, "w", encoding="utf-8") as fh:
                fh.write(txt)
            touched += 1
    print("mipmaps enabled on %d textures, skipped %d" % (touched, skipped))
    return 0


if __name__ == "__main__":
    sys.exit(main())
