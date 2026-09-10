#!/usr/bin/env python3
"""v0.3.8-5 THE PERFORMANCE PACKAGE - texture half of the law.

The owner (v0.3.8-5 report): "high phone battery usage with no reason and
high heat even in just main menu ... the app always get closed whenever it
takes less than a minute in the background which suggests ... it uses high
memory so the device keep killing it".

The measured truth (scripts/v038p5_perf_report.py): the project imported
EVERY texture as compress/mode=0 (lossless) -> raw RGBA in RAM+VRAM.
1036 textures = ~190 MB of raw RGBA, of which the 38 big ones (>= 512x512)
are ~115 MB (four 1080x1920 matcher backgrounds alone = 33 MB, the 20
feed thumbnails = ~49 MB). A menu that carries ~100+ MB of textures is
exactly the app Android's LMK reclaims first the moment it backgrounds.

THE LAW: every source >= 512x512 imports VRAM-compressed (compress/mode=2,
ETC2/ASTC - `import_etc2_astc` is already true) + mipmaps on for clean
minification. Small crisp sprites keep lossless (no visible change).
Result: the big-texture pool drops from ~115 MB to ~20-29 MB.

Idempotent: re-running only touches files whose params still say mode=0.
Run from the repo root:  python3 tools/v038p5_perf_textures.py [--dry]
"""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "projects" / "gogabox"
MIN_PIXELS = 512 * 512


def parse_params(text: str) -> dict:
    params = {}
    in_params = False
    for line in text.splitlines():
        if line.strip() == "[params]":
            in_params = True
            continue
        if in_params:
            if line.startswith("["):
                break
            if "=" in line:
                k, v = line.split("=", 1)
                params[k.strip()] = v.strip()
    return params


def set_param(text: str, key: str, value: str) -> str:
    lines = text.splitlines()
    in_params = False
    seen = False
    for i, line in enumerate(lines):
        if line.strip() == "[params]":
            in_params = True
            continue
        if in_params and line.startswith("["):
            if not seen:
                lines.insert(i, f"{key}={value}")
                seen = True
            break
        if in_params and line.split("=", 1)[0].strip() == key:
            lines[i] = f"{key}={value}"
            seen = True
            break
    if not seen and in_params:
        lines.append(f"{key}={value}")
    return "\n".join(lines) + "\n"


def main() -> int:
    dry = "--dry" in sys.argv
    changed = 0
    skipped = 0
    saved = 0
    for imp in sorted(ROOT.glob("assets/**/*.png.import")):
        src = imp.with_suffix("")  # strip .import
        if not src.exists():
            continue
        # read the PNG header for the real pixel size (no PIL dependency
        # on the build machine - the format is fixed-width bytes 16..24)
        with open(src, "rb") as f:
            head = f.read(24)
        if len(head) < 24 or head[:8] != b"\x89PNG\r\n\x1a\n":
            continue
        w = int.from_bytes(head[16:20], "big")
        h = int.from_bytes(head[20:24], "big")
        if w * h < MIN_PIXELS:
            skipped += 1
            continue
        text = imp.read_text()
        params = parse_params(text)
        if params.get("compress/mode") == "2" and params.get("mipmaps/generate") == "true":
            continue
        saved += w * h * 4
        if dry:
            print(f"[dry] {src.relative_to(ROOT)} {w}x{h} mode0 -> 2")
            changed += 1
            continue
        text = set_param(text, "compress/mode", "2")
        text = set_param(text, "mipmaps/generate", "true")
        imp.write_text(text)
        changed += 1
        print(f"[vram] {src.relative_to(ROOT)} {w}x{h}")
    mb = saved / 1e6
    print(f"\n{changed} textures -> VRAM compressed, {skipped} small stay lossless; "
          f"raw RGBA pool trimmed ~{mb:.0f} MB -> ~{mb*0.2:.0f} MB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
