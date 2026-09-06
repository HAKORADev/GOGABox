#!/usr/bin/env python3
"""v0.3.5-1 - the POP SIEGE box tile, composed from the real art:
the painted board + gadget folk + the glossy bloon march + the blimp."""
import json, math, os
from PIL import Image, ImageDraw, ImageFilter

REPO = "/home/z/my-project/repo/GOGABox"
ADIR = f"{REPO}/projects/gogabox/assets/games/pop_siege"
OUT = f"{REPO}/projects/gogabox/assets/thumbs/pop_siege.png"
W, H = 960, 640
CELL = W / 18.0

maps = {m["id"]: m for m in json.load(open(f"{ADIR.rsplit('/assets', 1)[0]}/game/games/pop_siege/maps.json"))["maps"]}
m = maps["first_bloom"]

im = Image.open(f"{ADIR}/bakes/first_bloom.webp").convert("RGBA").resize((W, H), Image.LANCZOS)

def put(path, cx, cy, scale=1.0):
    p = Image.open(f"{ADIR}/{path}").convert("RGBA")
    if scale != 1.0:
        p = p.resize((max(1, int(p.width * scale)), max(1, int(p.height * scale))), Image.LANCZOS)
    im.alpha_composite(p, (int(cx - p.width / 2), int(cy - p.height / 2)))

def cell_pt(c, r):
    return ((c + 0.5) * CELL, (r + 0.5) * CELL)

# blocked props + the heart house
for (bc, br, name) in m["blocked"]:
    cx, cy = cell_pt(bc, br)
    put(f"props/{name}.png", cx, cy - CELL * 0.10, CELL / 62.0)
hx, hy = cell_pt(m["heart"][0], m["heart"][1])
put("props/house.png", hx - CELL * 0.75, hy - CELL * 0.85, CELL * 2.3 / 416.0)

# the defenders
def tower(fid, head_g, cx, cy):
    """the gadget as the game draws it: base + head stacked."""
    sc = CELL * 1.18 / 74.0
    base = Image.open(f"{ADIR}/folk/{fid}_base.png").convert("RGBA")
    head = Image.open(f"{ADIR}/folk/{fid}_head_g{head_g}.png").convert("RGBA")
    base = base.resize((int(base.width * sc), int(base.height * sc)), Image.LANCZOS)
    head = head.resize((int(head.width * sc), int(head.height * sc)), Image.LANCZOS)
    im.alpha_composite(base, (int(cx - base.width / 2), int(cy - base.height / 2)))
    im.alpha_composite(head, (int(cx - head.width / 2), int(cy - base.height / 2 - head.height * 0.72)))

tower("darty", 2, 2.9 * CELL, 4.5 * CELL)
tower("pyra", 2, 6.5 * CELL, 4.3 * CELL)
tower("boomba", 2, 3.3 * CELL, 7.1 * CELL)
tower("zappy", 1, 9.2 * CELL, 1.6 * CELL)

# the march: balloons along the road + the blimp entering
pts = m["paths"][0]
def road_at(d):
    acc = 0.0
    for i in range(len(pts) - 1):
        a = (float(pts[i][0]), float(pts[i][1]))
        b = (float(pts[i + 1][0]), float(pts[i + 1][1]))
        seg = math.dist(a, b)
        if acc + seg >= d:
            t = (d - acc) / max(0.0001, seg)
            return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
        acc += seg
    return (float(pts[-1][0]), float(pts[-1][1]))

for kind, d in [("yellow", 14.2), ("red", 10.6), ("blue", 5.9), ("green", 2.6)]:
    cx, cy = road_at(d)
    put(f"bloons/{kind}.png", cx * CELL, cy * CELL, CELL * 0.78 / 118.0)
put("bloons/moab.png", 40, 46, CELL * 1.7 / 260.0)

# soft vignette for the tile read
vg = Image.new("L", (W, H), 0)
ImageDraw.Draw(vg).rounded_rectangle([0, 0, W - 1, H - 1], 24, outline=255, width=90)
vg = vg.filter(ImageFilter.GaussianBlur(60))
dark = Image.new("RGBA", (W, H), (24, 16, 8, 110))
im.alpha_composite(Image.composite(dark, Image.new("RGBA", (W, H), (0, 0, 0, 0)), vg))
os.makedirs(os.path.dirname(OUT), exist_ok=True)
im.convert("RGB").save(OUT)
print("tile written", OUT)
