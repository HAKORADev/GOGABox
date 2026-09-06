#!/usr/bin/env python3
"""v0.3.4-3 THE PLATFORM LAW: every registry entry gains
"os": ["android", "pc"] (the badge/tag on all games) and a
"controls_pc": [...] (the PC keyboard/mouse controls, the owner's list).
Insertion is line-based and idempotent."""
import re, sys

P = "game/core/registry.gd"
src = open(P).read()

# ---- 1) the os tag: right after each "orientation": "X", line
os_line = '\t\t\t\t"os": ["android", "pc"],'
out = []
inserted_os = 0
for ln in src.split("\n"):
    out.append(ln)
    if '"orientation":' in ln and '"os":' not in ln:
        indent = ln[: len(ln) - len(ln.lstrip())]
        out.append(indent + '"os": ["android", "pc"],')
        inserted_os += 1
src = "\n".join(out)

# ---- 2) controls_pc: after each controls array's closing bracket
PC = {
    "snake": ["hold the LEFT MOUSE BUTTON and move - the head bends where the cursor moves"],
    "rally": ["LEFT / RIGHT arrow keys move the paddle (UP/DOWN on a vertical field)"],
    "lanes": ["LEFT / RIGHT arrow keys change lanes", "SPACE holds the fire"],
    "slasher": ["hold the LEFT MOUSE BUTTON and swipe across the fruit"],
    "hopper": ["LEFT / RIGHT arrow keys run", "SPACE jumps"],
    "merge": ["the ARROW keys slide the board"],
    "dario": ["LEFT / RIGHT arrow keys run", "SPACE jumps"],
    "xo": ["click a square with the mouse"],
    "invaders": ["LEFT / RIGHT arrow keys steer", "SPACE holds the fire"],
    "matcher": ["click two tiles with the mouse to swap them"],
    "cosmic_spud": ["hold the LEFT MOUSE BUTTON and move - the invisible stick follows the cursor; the guns aim and fire by themselves"],
}
out = []
inserted_pc = 0
i = 0
lines = src.split("\n")
current_id = ""
while i < len(lines):
    ln = lines[i]
    out.append(ln)
    m = re.search(r'"id":\s*"([a-z_0-9]+)"', ln)
    if m:
        current_id = m.group(1)
    if '"controls"' in ln:
        # find the closing bracket of this array (bracket depth from this line)
        depth = 0
        j = i
        while j < len(lines):
            depth += lines[j].count("[") - lines[j].count("]")
            if depth == 0:
                break
            j += 1
        # emit lines up to the closer
        for k in range(i + 1, j + 1):
            out.append(lines[k])
        closer = out[-1]
        indent = closer[: len(closer) - len(closer.lstrip())]
        gid = current_id
        ctrl = PC.get(gid)
        if ctrl and '"controls_pc"' not in src:
            arr = ", ".join('"%s"' % c.replace('"', '\\"') for c in ctrl)
            out.append(indent + '"controls_pc": [' + arr + "],")
            inserted_pc += 1
        i = j
    i += 1

open(P, "w").write("\n".join(out))
print("os tags inserted:", inserted_os, "controls_pc inserted:", inserted_pc)
