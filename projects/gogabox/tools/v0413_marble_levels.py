#!/usr/bin/env python3
"""
v0413 MARBLE POPPER LEVELS FORGE
Generates 100 levels (10 places x 10 levels) in the owner's variety law:
- shooter at right / center / left / upper-left / upper-center / upper-right / bottom
- movable (slider) shooters, twin paths, twin (switchable) shooters
- quota (hidden length), wave size, base speed, colors per place
- difficulty grows by place (speed + quota + colors)
Emits: maps.json + maps_data.gd (embedded copy, the pop_siege law) +
preview PNGs assets/games/marble/thumbs/<id>.png (the pop siege preview law).
Design space: 720x1280.
"""
import json, math, os, random

G = "/home/z/my-project/gogabox/projects/gogabox"
os.makedirs(f"{G}/game/games/marble", exist_ok=True)
os.makedirs(f"{G}/assets/games/marble/thumbs", exist_ok=True)

W, H = 1080, 1920
PLACES = [
    ("mossy", "Mossy Shrine", 3, 62), ("sun", "Sun Steps", 3, 66),
    ("tide", "Tidal Cave", 4, 70), ("ember", "Ember Vault", 4, 74),
    ("frost", "Frost Hollow", 5, 78), ("violet", "Violet Depths", 5, 82),
    ("sky", "Sky Ruins", 6, 86), ("neon", "Neon Catacomb", 6, 90),
    ("obsidian", "Obsidian Core", 7, 94), ("cursed", "Cursed Gate", 7, 98),
]

rnd = random.Random(40130)


def curve_path(start, end, bulge, n=7, wobble=135.0):
    """A wavy control polyline from start to end."""
    pts = [start]
    for i in range(1, n - 1):
        t = i / (n - 1)
        x = start[0] + (end[0] - start[0]) * t
        y = start[1] + (end[1] - start[1]) * t
        x += math.sin(t * math.pi) * bulge + rnd.uniform(-wobble, wobble) * 0.4
        y += rnd.uniform(-wobble, wobble) * 0.5
        pts.append((x, y))
    pts.append(end)
    return pts


def clamp_pt(p):
    return (max(46.0, min(W - 46.0, p[0])), max(120.0, min(H - 46.0, p[1])))


def make_path(kind, place_idx):
    """Paths per layout kind. Returns list of point-lists + shooter spec."""
    mx, my = W * 0.5, H * 0.5
    if kind == 0:      # top entry -> hole top-left, shooter bottom center
        hole = (W * 0.16, H * 0.30)
        pts = [clamp_pt(p) for p in curve_path((W * 0.86, 195.0), hole, -180)]
        return [pts], {"x": W * 0.5, "y": H * 0.78, "mode": "fixed"}
    if kind == 1:      # right side entry, shooter left-bottom
        hole = (W * 0.86, H * 0.34)
        pts = [clamp_pt(p) for p in curve_path((W * 0.12, 225.0), hole, 220)]
        return [pts], {"x": W * 0.18, "y": H * 0.74, "mode": "fixed"}
    if kind == 2:      # left entry, shooter right-bottom
        hole = (W * 0.12, H * 0.34)
        pts = [clamp_pt(p) for p in curve_path((W * 0.88, 225.0), hole, -220)]
        return [pts], {"x": W * 0.82, "y": H * 0.74, "mode": "fixed"}
    if kind == 3:      # center spiral (snake around middle), shooter bottom
        cx, cy = W * 0.5, H * 0.42
        pts = [(cx + 250, 140)]
        pts += [(cx + 250, cy - 180), (cx - 250, cy - 160), (cx - 240, cy + 40),
                (cx + 230, cy + 60), (cx + 210, cy + 230), (cx - 60, cy + 240)]
        pts = [clamp_pt(p) for p in pts]
        return [pts], {"x": W * 0.5, "y": H * 0.86, "mode": "fixed"}
    if kind == 4:      # slider: hole top center, long S path, movable shooter at bottom
        pts = [(W * 0.12, 170), (W * 0.62, 210), (W * 0.68, 380), (W * 0.2, 430),
               (W * 0.16, 620), (W * 0.66, 660), (W * 0.6, 840), (W * 0.5, 940)]
        pts = [clamp_pt(p) for p in pts]
        return [pts], {"x": W * 0.5, "y": H * 0.88, "mode": "slider"}
    if kind == 5:      # twin paths (two entries, one hole)
        hole = (W * 0.5, H * 0.30)
        a = [clamp_pt(p) for p in curve_path((W * 0.10, 300.0), hole, -120)]
        b = [clamp_pt(p) for p in curve_path((W * 0.90, 300.0), hole, 120)]
        return [a, b], {"x": W * 0.5, "y": H * 0.80, "mode": "fixed"}
    if kind == 6:      # twin shooters (tap to swap), center hole
        hole = (W * 0.5, H * 0.26)
        pts = [clamp_pt(p) for p in curve_path((W * 0.5, 165.0), (W * 0.5, H * 0.40), 240)]
        pts = [clamp_pt(p) for p in [(pts[0][0] + rnd.uniform(-80, 80), pts[0][1])] + pts[1:]]
        return [pts], {"x": W * 0.28, "y": H * 0.74, "mode": "twin",
                       "twin": [[W * 0.28, H * 0.74], [W * 0.72, H * 0.74]]}
    if kind == 7:      # bottom entry (rises), shooter top-left
        hole = (W * 0.82, H * 0.70)
        pts = [clamp_pt(p) for p in curve_path((W * 0.16, H * 0.96), hole, -170)]
        return [pts], {"x": W * 0.2, "y": H * 0.22, "mode": "fixed"}
    if kind == 8:      # slider + long winding
        pts = [(W * 0.85, 160), (W * 0.2, 240), (W * 0.14, 420), (W * 0.8, 470),
               (W * 0.84, 650), (W * 0.2, 700), (W * 0.16, 880), (W * 0.5, 960)]
        pts = [clamp_pt(p) for p in pts]
        return [pts], {"x": W * 0.5, "y": H * 0.88, "mode": "slider"}
    # kind 9: twin paths + twin shooters (the finale feel)
    hole = (W * 0.5, H * 0.34)
    a = [clamp_pt(p) for p in curve_path((W * 0.12, H * 0.16), hole, -100)]
    b = [clamp_pt(p) for p in curve_path((W * 0.88, H * 0.16), hole, 100)]
    return [a, b], {"x": W * 0.26, "y": H * 0.82, "mode": "twin",
                    "twin": [[W * 0.26, H * 0.82], [W * 0.74, H * 0.82]]}


levels = []
li = 0
for pi, (pkey, pname, colors, speed) in enumerate(PLACES):
    for lv in range(10):
        li += 1
        kind = lv % 10 if pi in (0, 1) else (lv % 10 if pi >= 2 else lv)
        # every place samples all 10 layout kinds; later places twist them
        paths, shooter = make_path(kind, pi)
        quota = 34 + pi * 4 + lv * 2 + (8 if kind in (4, 8) else 0)  # hidden length
        wave = max(6, 12 - pi // 3 - (2 if lv >= 7 else 0))
        spd = speed + lv * 1.6
        entry = {
            "id": f"m{li:02d}", "name": f"{lv + 1}", "place": pi,
            "place_key": pkey, "place_name": pname,
            "paths": [[[round(x, 1), round(y, 1)] for (x, y) in path] for path in paths],
            "shooter": {"x": round(shooter["x"], 1), "y": round(shooter["y"], 1),
                        "mode": shooter["mode"]},
            "speed": round(spd, 1), "quota": quota, "wave": wave, "colors": colors,
        }
        if "twin" in shooter:
            entry["shooter"]["twin"] = [[round(a, 1), round(b, 1)] for a, b in shooter["twin"]]
        levels.append(entry)

json.dump({"v": 1, "design": [W, H], "levels": levels},
          open(f"{G}/game/games/marble/maps.json", "w"), separators=(",", ":"))

# maps_data.gd - the embedded copy (the pop siege law)
body = json.dumps({"v": 1, "design": [W, H], "levels": levels}, separators=(",", ":"))
gd = """## GENERATED by tools/v0413_marble_levels.py - do not edit by hand.
## One embedded copy of maps.json so the export never loses it (the pop siege law).
class_name MarbleMapsData

const DESIGN := Vector2(720, 1280)
const DATA := %s
""" % body
open(f"{G}/game/games/marble/maps_data.gd", "w").write(gd)

print("levels:", len(levels), "-> maps.json + maps_data.gd")

# ------------------------------------------------------------------ previews
# render each level's path over its place bg (the pop siege preview law)
from PIL import Image, ImageDraw, ImageFilter

def catmull(points, steps_per_seg=14):
    pts = [points[0]] + list(points) + [points[-1]]
    out = []
    for i in range(1, len(pts) - 2):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[i + 1], pts[i + 2]
        for t in [j / steps_per_seg for j in range(steps_per_seg)]:
            t2, t3 = t * t, t * t * t
            x = 0.5 * ((2 * p1[0]) + (-p0[0] + p2[0]) * t + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2 + (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * t3)
            y = 0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3)
            out.append((x, y))
    out.append(points[-1])
    return out

BK = "/home/z/my-project/gogabox/projects/gogabox/assets/games/marble"
for lv in levels:
    bg = Image.open(f"{BK}/bg_{lv['place']}_{lv['place_key']}.png").convert("RGB")
    tw, th = 300, 400
    thumb = bg.resize((tw, th))
    sx, sy = tw / W, th / H
    d = ImageDraw.Draw(thumb, "RGBA")
    for path in lv["paths"]:
        pts = catmull([tuple(p) for p in path])
        d.line([(x * sx, y * sy) for x, y in pts], fill=(250, 240, 210, 230), width=7)
        d.line([(x * sx, y * sy) for x, y in pts], fill=(60, 40, 30, 200), width=3)
        end = pts[-1]
        d.ellipse((end[0] * sx - 9, end[1] * sy - 9, end[0] * sx + 9, end[1] * sy + 9), fill=(20, 12, 8, 255))
    sh = lv["shooter"]
    d.ellipse((sh["x"] * sx - 12, sh["y"] * sy - 12, sh["x"] * sx + 12, sh["y"] * sy + 12),
              fill=(250, 240, 210, 255), outline=(20, 12, 8, 255), width=3)
    if sh.get("twin"):
        for tx, ty in sh["twin"]:
            d.ellipse((tx * sx - 12, ty * sy - 12, tx * sx + 12, ty * sy + 12),
                      outline=(250, 240, 210, 255), width=3)
    thumb.save(f"{BK}/thumbs/{lv['id']}.png")
print("thumbs:", len(levels))
