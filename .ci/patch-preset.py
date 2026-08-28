#!/usr/bin/env python3
"""
Safely patch a Godot export_presets.cfg from shell scripts.

Godot presets are INI-like:
    [preset.0]           <- section header; contains name="..."
    ...
    [preset.0.options]   <- options; keys like version/code=... live here

Usage:
    patch-preset.py <file> <preset-name> <key>=<value> [<key>=<value> ...]

Example:
    patch-preset.py export_presets.cfg "Android arm64" version/code=10002 \
        keystore/release=/home/me/.android/debug.keystore

If the key is missing inside the target preset's options it is appended.
Exits 1 with a message if the preset name does not exist.
"""
import re
import sys


def main() -> int:
    if len(sys.argv) < 4:
        print(__doc__)
        return 1
    path, preset_name = sys.argv[1], sys.argv[2]
    patches: dict[str, str] = {}
    for arg in sys.argv[3:]:
        k, _, v = arg.partition("=")
        patches[k.strip()] = v

    with open(path, "r", encoding="utf-8") as f:
        lines = f.read().splitlines(keepends=True)

    rx_header = re.compile(r"^\[preset\.\d+\]\s*$")
    rx_options = re.compile(r"^\[preset\.\d+\.options\]\s*$")
    rx_name = re.compile(r'^name="(.*)"\s*$')
    rx_key = re.compile(r"^([A-Za-z0-9_/.]+)\s*=")

    is_target = False       # current [preset.N] belongs to target preset
    in_options = False      # currently inside [preset.N.options] of target
    found = False
    patched: set[str] = set()
    out: list[str] = []

    def flush_missing() -> None:
        for k, v in patches.items():
            if k not in patched:
                out.append(f"{k}={v}\n")

    for line in lines:
        if rx_header.match(line):
            if in_options:
                flush_missing()
            is_target, in_options = False, False
            out.append(line)
            continue
        if rx_options.match(line):
            in_options = is_target
            out.append(line)
            continue
        if not in_options:
            nm = rx_name.match(line)
            if nm:
                is_target = nm.group(1) == preset_name
                if is_target:
                    found = True
            out.append(line)
            continue
        km = rx_key.match(line)
        if km and km.group(1) in patches:
            k = km.group(1)
            out.append(f"{k}={patches[k]}\n")
            patched.add(k)
            continue
        out.append(line)

    if in_options:
        flush_missing()

    if not found:
        print(f"ERROR: preset named '{preset_name}' not found in {path}", file=sys.stderr)
        return 1

    with open(path, "w", encoding="utf-8") as f:
        f.writelines(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
