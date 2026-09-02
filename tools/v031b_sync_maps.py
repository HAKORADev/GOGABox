#!/usr/bin/env python3
"""Sync the generated LEVELS literals into dario.gd."""
import re

gen = open("/tmp/maps_out.txt").read()
start = gen.index("LEVELS := [")
block = gen[start + len("LEVELS "):].strip()
# block is ":= [\n\t[...\n]" -> normalize to GDScript: "const LEVELS := [...]"
lit = block.split(":=", 1)[1].strip()

p = "/home/z/my-project/gogabox/projects/gogabox/game/games/dario/dario.gd"
src = open(p).read()
a = src.index("const LEVELS := [")
# find the closing "]"\n\n# ============================================================ state
marker = "]\n\n# ============================================================ state"
b = src.index(marker, a) + len("]")
new_src = src[:a] + "const LEVELS := " + lit + src[b:]
open(p, "w").write(new_src)
print("synced; block chars:", len(lit))
