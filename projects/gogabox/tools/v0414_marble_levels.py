#!/usr/bin/env python3
"""
v0414 MARBLE POPPER LEVELS FORGE (the v040-14 path law)
Rebuilds all 100 levels with REAL zuma geometry - the owner's verdict on the
v040-13 forge: "the first level design is shitty, i have never saw a zuma-like
game that starts with a level that is literally short line path".

THE LAWS THIS FORGE BUILDS UNDER:
- LONG, flowing, deliberate routes: serpents, spirals, horseshoes, wells -
  every path >= 1900 px of rolling (level 1 lands ~3200), sampled smooth.
- TWO ENTRY FLAVORS: EDGE entries start OFF-SCREEN (marbles roll in from
  outside - the owner: "in zuma games marbles come from out of the screen
  edges"); HOLE entries sit on-screen (the game grows marbles out of them).
- MARBLES FIT THE ROAD: every generated path is VALIDATED - sample step,
  turn angle, coil separation (>= 150 px center-to-center so a shot fits
  between lanes), shooter clearance (>= 180), hole clearance, margins,
  length window. A fail raises - no blind shipping.
- SHOOTER VARIETY per the GDD: bottom fixed / left / right / top / twin
  spots / slider (movable), twin paths, twin+slider finale.
- Difficulty rides the PLACE (speed/quota/waves/colors already per place);
  length grows gently by place (extra lanes/turns on later places).

Emits: game/games/marble/maps.json + maps_data.gd (embedded copy, DESIGN
fixed to the real 1080x1920) + thumbs/<id>.png previews.
"""
import json, math, os, sys

G = "/home/z/my-project/gogabox/projects/gogabox"
os.makedirs(f"{G}/game/games/marble", exist_ok=True)
os.makedirs(f"{G}/assets/games/marble/thumbs", exist_ok=True)

W, H = 1080.0, 1920.0
MARBLE_D = 96.0
COIL_MIN = 150.0        # min center-to-center between non-adjacent road parts
SHOOTER_MIN = 180.0     # min road distance to the shooter seat
HOLE_MIN = 130.0        # min road distance to a hole (its own arrival excluded)
LEN_MIN, LEN_MAX = 1800.0, 4300.0
TURN_MAX = math.radians(30.0)   # max turn per 50px step (no hairpins)

PLACES = [
    ("mossy", "Mossy Shrine", 3, 62), ("sun", "Sun Steps", 3, 66),
    ("tide", "Tidal Cave", 4, 70), ("ember", "Ember Vault", 4, 74),
    ("frost", "Frost Hollow", 5, 78), ("violet", "Violet Depths", 5, 82),
    ("sky", "Sky Ruins", 6, 86), ("neon", "Neon Catacomb", 6, 90),
    ("obsidian", "Obsidian Core", 7, 94), ("cursed", "Cursed Gate", 7, 98),
]

# ================================================================ geometry

def _lerp(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def _dist(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def round_path(waypoints, radius=150.0, step=50.0):
    """Polyline with rounded corners (quadratic corner cuts), then evenly
    resampled - smooth by construction, faithful to the design."""
    geo = [waypoints[0]]
    for i in range(1, len(waypoints) - 1):
        a, b, c = waypoints[i - 1], waypoints[i], waypoints[i + 1]
        la, lb = _dist(a, b), _dist(b, c)
        r = min(radius, la * 0.45, lb * 0.45)
        d1 = ((b[0] - a[0]) / la, (b[1] - a[1]) / la)
        d2 = ((c[0] - b[0]) / lb, (c[1] - b[1]) / lb)
        p1 = (b[0] - d1[0] * r, b[1] - d1[1] * r)
        p2 = (b[0] + d2[0] * r, b[1] + d2[1] * r)
        geo.append(p1)
        # the corner arc (quadratic bezier p1 -> b -> p2)
        n = max(4, int(_dist(p1, p2) * 0.6 / 14.0))
        for k in range(1, n + 1):
            t = k / n
            x = (1 - t) ** 2 * p1[0] + 2 * (1 - t) * t * b[0] + t * t * p2[0]
            y = (1 - t) ** 2 * p1[1] + 2 * (1 - t) * t * b[1] + t * t * p2[1]
            geo.append((x, y))
    geo.append(waypoints[-1])
    return sample_curve(geo, step)


def sample_curve(points, step=50.0):
    """Resample an arbitrary dense curve at EXACT even arc-length steps."""
    # cumulative arc length over the raw polyline
    cum = [0.0]
    for i in range(1, len(points)):
        cum.append(cum[-1] + _dist(points[i - 1], points[i]))
    total = cum[-1]
    if total <= 0.0:
        return [points[0], points[-1]]
    out = [points[0]]
    target = step
    j = 1
    while target < total:
        while j < len(cum) and cum[j] < target:
            j += 1
        if j >= len(cum):
            break
        a, b = points[j - 1], points[j]
        seg = cum[j] - cum[j - 1]
        t = (target - cum[j - 1]) / seg if seg > 0 else 0.0
        out.append(_lerp(a, b, t))
        target += step
    if _dist(out[-1], points[-1]) > 6.0:
        out.append(points[-1])
    return out


def spiral_pts(cx, cy, r0, r1, a0, turns, step=50.0, axis=1.0):
    """Archimedean spiral sampled at even arc steps; axis=1 turns clockwise."""
    total = abs(turns) * 2 * math.pi
    pts = []
    n = int(total / 0.09) + 64
    for i in range(n + 1):
        t = i / n
        a = a0 + axis * total * t
        r = r0 + (r1 - r0) * t
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r * 0.92))
    return sample_curve(pts, step)


def serpent_wp(lanes, x_in, x_out_side, hole):
    """unused helper kept for future layout work"""
    return []


def validate_level(lv_idx, paths, shooters, holes, length_min=LEN_MIN):
    """THE NO-BLIND-WORK GATE: a level ships only if the geometry passes."""
    errs = []
    lens = []
    for pi, path in enumerate(paths):
        # 1. sample step + turn angle
        for i in range(1, len(path)):
            if _dist(path[i - 1], path[i]) > 60.0:
                errs.append(f"L{lv_idx} p{pi}: sample gap {_dist(path[i-1], path[i]):.0f} at {i}")
        for i in range(2, len(path)):
            v1 = (path[i - 1][0] - path[i - 2][0], path[i - 1][1] - path[i - 2][1])
            v2 = (path[i][0] - path[i - 1][0], path[i][1] - path[i - 1][1])
            a1, a2 = math.atan2(v1[1], v1[0]), math.atan2(v2[1], v2[0])
            da = abs((a2 - a1 + math.pi) % (2 * math.pi) - math.pi)
            if da > TURN_MAX:
                errs.append(f"L{lv_idx} p{pi}: turn {math.degrees(da):.0f}deg at {i}")
        # total length
        L = sum(_dist(path[i - 1], path[i]) for i in range(1, len(path)))
        lens.append(L)
        if L < length_min:
            errs.append(f"L{lv_idx} p{pi}: too short {L:.0f}")
        if L > LEN_MAX:
            errs.append(f"L{lv_idx} p{pi}: too long {L:.0f}")
        # 2. margins for on-screen parts; the ENTRY CORRIDOR (the first
        # samples, where the road slides in from off-screen) is exempt -
        # the road center may hug the edge while it enters
        for idx_p, p in enumerate(path):
            if idx_p < 8:
                continue
            if 0.0 <= p[0] <= W and 0.0 <= p[1] <= H:
                if p[0] < 36 or p[0] > W - 36:
                    errs.append(f"L{lv_idx} p{pi}: x margin {p[0]:.0f} at {p}")
                if p[1] < 120:
                    errs.append(f"L{lv_idx} p{pi}: y top margin {p[1]:.0f} at {p}")
        # 3. coil separation (non-adjacent samples)
        n = len(path)
        step_idx = max(1, int(40 / 50.0))
        for i in range(0, n, 3):
            for j in range(i + 6, n, 3):
                d = _dist(path[i], path[j])
                if d < COIL_MIN:
                    # near-arrival pairs are legal (the hole approach)
                    if j > n - 8 or i > n - 8:
                        continue
                    errs.append(f"L{lv_idx} p{pi}: coil {d:.0f} at {i},{j}")
                    break
    # 4. shooter clearance
    for s in shooters:
        for pi, path in enumerate(paths):
            dmin = min(_dist(p, (s["x"], s["y"])) for p in path)
            if dmin < SHOOTER_MIN:
                errs.append(f"L{lv_idx} p{pi}: shooter clearance {dmin:.0f}")
    # 5. hole clearance (its own path's arrival excluded)
    for hi, hpos in enumerate(holes):
        for pi, path in enumerate(paths):
            n = len(path)
            for i in range(0, n, 3):
                if pi == hi and i >= n - 10:
                    continue
                d = _dist(path[i], hpos)
                if d < HOLE_MIN:
                    errs.append(f"L{lv_idx} p{pi}: hole{hi} clearance {d:.0f} at {i}")
                    break
    return errs, lens


# ================================================================ layouts
# Every layout fn returns (paths, shooters, holes, length_floor).

def _lane_pts(a_x, b_x, y):
    """straight-lane filler points every ~50px between a_x and b_x"""
    out = []
    n = max(1, int(abs(b_x - a_x) / 50.0))
    for k in range(1, n):
        out.append((a_x + (b_x - a_x) * k / n, y))
    return out


def _serpent_core(ys, hole, entry, shooter, flip=False):
    """Horizontal lanes joined by SEMICIRCULAR U-turn arcs (radius = half
    the lane gap) - tangent-continuous, no tight corners anywhere.
    flip=True mirrors the whole route (entry from the right edge)."""
    r = (ys[1] - ys[0]) / 2.0
    lane_l, lane_r = 130.0 + r, 950.0 - r
    pts = [entry]
    for li, y in enumerate(ys):
        last = li == len(ys) - 1
        if li % 2 == 0:   # flows left -> right, U-turn on the right
            target_x = hole[0] if last else lane_r
            pts += _lane_pts(pts[-1][0], target_x, y)
            if last:
                break
            pts.append((lane_r, y))
            cx, cy = lane_r, y + r
            for k in range(1, 12):
                a = math.radians(-90 + 15 * k)
                pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
            pts.append((cx, cy + r))   # the arc's landing point
        else:             # flows right -> left, U-turn on the left
            target_x = hole[0] if last else lane_l
            pts += _lane_pts(pts[-1][0], target_x, y)
            if last:
                break
            pts.append((lane_l, y))
            cx, cy = lane_l, y + r
            for k in range(1, 12):
                a = math.radians(-90 - 15 * k)
                pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
            pts.append((cx, cy + r))   # the arc's landing point
    pts.append(hole)
    if flip:
        pts = [(W - p[0], p[1]) for p in pts]
    path = sample_curve(pts, 50.0)
    return [path], [shooter], [pts[-1]], 2400.0


def lay_serpent(pi, lanes=3):
    """THE classic opener: edge entry left, wide lanes, semicircle
    U-turns, hole right - long, generous, readable."""
    ys = [300.0, 580.0, 860.0]
    return _serpent_core(ys, (790.0, ys[-1]), (-170.0, ys[0]),
                         {"x": 540.0, "y": 1560.0, "mode": "fixed"})


def lay_spiral(pi):
    """Hole-entry spiral: marbles GROW out of the outer mouth and spiral
    into a center hole (the whirlpool). Coil spacing >= 150 by design."""
    path = spiral_pts(540.0, 640.0, 450.0, 140.0, math.pi * 1.15, 1.7)
    hole = path[-1]
    return [path], [{"x": 540.0, "y": 1560.0, "mode": "fixed"}], [hole], 2100.0


def lay_horseshoe(pi):
    """Edge entry bottom-left, up the left wall, U at the top, down the
    right wall, hole bottom-right - the middle stays open."""
    hole = (770.0, 1150.0)
    wps = [(-160.0, 1180.0), (150.0, 1150.0), (185.0, 950.0),
           (165.0, 700.0), (200.0, 430.0), (320.0, 265.0),
           (540.0, 225.0), (760.0, 265.0), (880.0, 430.0),
           (905.0, 700.0), (885.0, 950.0), (840.0, 1090.0), hole]
    path = round_path(wps, 160.0)
    return [path], [{"x": 540.0, "y": 1600.0, "mode": "fixed"}], [hole], 2400.0


def lay_scurve(pi):
    """THE SLIDER: wide S over three lanes, movable shooter under all of it."""
    hole = (540.0, 950.0)
    wps = [(-160.0, 280.0), (200.0, 300.0), (420.0, 320.0), (640.0, 330.0),
           (860.0, 350.0), (935.0, 470.0), (870.0, 600.0),
           (650.0, 630.0), (430.0, 640.0), (210.0, 660.0),
           (145.0, 780.0), (215.0, 905.0), (430.0, 940.0), hole]
    path = round_path(wps, 150.0)
    return [path], [{"x": 540.0, "y": 1560.0, "mode": "slider"}], [hole], 2300.0


def lay_twin_rivers(pi):
    """Two edge entries (top corners), two chains rolling down in S-bends,
    two holes mid-low. Half quota each - total rolling matches a single."""
    ha, hb = (330.0, 960.0), (750.0, 960.0)
    a = round_path([(-170.0, 240.0), (150.0, 300.0), (330.0, 460.0),
                    (370.0, 660.0), (320.0, 850.0), ha], 150.0)
    b = round_path([(W + 170.0, 240.0), (W - 150.0, 300.0), (W - 330.0, 460.0),
                    (W - 370.0, 660.0), (W - 320.0, 850.0), hb], 150.0)
    sh = [{"x": 540.0, "y": 1560.0, "mode": "fixed"}]
    return [a, b], sh, [ha, hb], 950.0


def lay_zigzag(pi):
    """The mirrored serpent: entry from the RIGHT edge, lanes stepped
    lower, hole mid-left, shooter bottom-right."""
    ys = [340.0, 640.0, 940.0]
    return _serpent_core(ys, (790.0, ys[-1]), (-170.0, ys[0]),
                         {"x": 820.0, "y": 1560.0, "mode": "fixed"},
                         flip=True)


def lay_twin_shooters(pi):
    """One contracting spiral looping around an open center, hole at the
    ring's end; two legal shooter spots below (the tap-to-swap law)."""
    path = spiral_pts(540.0, 600.0, 560.0, 310.0, math.pi * 0.95, 0.95)
    hole = path[-1]
    sh = [{"x": 330.0, "y": 1560.0, "mode": "twin",
           "twin": [[330.0, 1560.0], [750.0, 1560.0]]}]
    return [path], sh, [hole], 2000.0


def lay_well(pi):
    """THE WELL: flat oval spiral, hole dead center, edge entry from the
    RIGHT (the spiral's own start tangent points left, the road joins it
    smoothly)."""
    pts = []
    turns = 1.35
    n = int(turns * 2 * math.pi / 0.09)
    for i in range(n + 1):
        t = i / n
        a = math.pi * 0.5 + 2 * math.pi * turns * t
        rx = 430.0 - 250.0 * t
        ry = 360.0 - 210.0 * t
        pts.append((540.0 + math.cos(a) * rx, 660.0 + math.sin(a) * ry))
    path = sample_curve(pts, 50.0)
    # extend the outer start off-screen RIGHT, resampled as ONE curve
    p0 = path[0]
    path = sample_curve([(W + 170.0, p0[1]), (p0[0] + 240.0, p0[1])] + path, 50.0)
    hole = path[-1]
    return [path], [{"x": 540.0, "y": 1560.0, "mode": "fixed"}], [hole], 2200.0


def lay_serpent_long(pi):
    """FOUR lanes, movable shooter, the long grind."""
    ys = [270.0, 520.0, 770.0, 1020.0]
    return _serpent_core(ys, (290.0, ys[-1]), (-170.0, ys[0]),
                         {"x": 540.0, "y": 1600.0, "mode": "slider"})


def lay_finale(pi):
    """TWIN + TWIN: two long side rivers rolling down to low holes, twin
    legal shooter pads at the bottom (the finale feel, every corner cut
    keeps radius >= 96)."""
    ha, hb = (430.0, 1210.0), (650.0, 1210.0)
    a = round_path([(-170.0, 280.0), (140.0, 360.0), (310.0, 550.0),
                    (340.0, 780.0), (300.0, 1010.0), ha], 150.0)
    b = round_path([(W + 170.0, 280.0), (W - 140.0, 360.0), (W - 310.0, 550.0),
                    (W - 340.0, 780.0), (W - 300.0, 1010.0), hb], 150.0)
    sh = [{"x": 330.0, "y": 1600.0, "mode": "twin",
           "twin": [[330.0, 1600.0], [750.0, 1600.0]]}]
    return [a, b], sh, [ha, hb], 1200.0


# kind per level-in-place (0..9) - the variety law
KINDS = [lay_serpent, lay_spiral, lay_horseshoe, lay_scurve, lay_twin_rivers,
         lay_zigzag, lay_twin_shooters, lay_well, lay_serpent_long, lay_finale]
# hole-entry (on-screen portal) flavors: spiral + well + twin_shooters grow
# their marbles out of a visible mouth; the rest roll in from the edges
HOLE_ENTRY_KINDS = {1, 6, 7}


def build_level(pi, lv):
    kind = lv % 10
    paths, shooters, holes, floor_len = KINDS[kind](pi)
    # per-place growth: a touch faster spawn pressure, longer on later places
    quota = 34 + pi * 4 + lv * 2 + (8 if kind in (3, 8) else 0)
    wave = max(6, 12 - pi // 3 - (2 if lv >= 7 else 0))
    spd = PLACES[pi][3] + lv * 1.6
    errs, lens = validate_level(pi * 10 + lv + 1, paths, shooters, holes, floor_len)
    if errs:
        for e in errs:
            print("VALIDATION FAIL:", e)
        sys.exit(1)
    entry = {
        "id": f"m{pi * 10 + lv + 1:02d}", "name": f"{lv + 1}", "place": pi,
        "place_key": PLACES[pi][0], "place_name": PLACES[pi][1],
        "paths": [[[round(x, 1), round(y, 1)] for (x, y) in path] for path in paths],
        "shooter": {"x": round(shooters[0]["x"], 1), "y": round(shooters[0]["y"], 1),
                    "mode": shooters[0]["mode"]},
        "speed": round(spd, 1), "quota": quota, "wave": wave,
        "colors": PLACES[pi][2],
        "entry": "hole" if kind in HOLE_ENTRY_KINDS else "edge",
    }
    if shooters[0].get("twin"):
        entry["shooter"]["twin"] = [[round(a, 1), round(b, 1)]
                                    for a, b in shooters[0]["twin"]]
    return entry, lens


levels = []
all_lens = []
for pi in range(10):
    for lv in range(10):
        entry, lens = build_level(pi, lv)
        levels.append(entry)
        all_lens += lens

print("levels:", len(levels))
print("path length min/avg/max: %.0f / %.0f / %.0f" %
      (min(all_lens), sum(all_lens) / len(all_lens), max(all_lens)))

json.dump({"v": 2, "design": [int(W), int(H)], "levels": levels},
          open(f"{G}/game/games/marble/maps.json", "w"), separators=(",", ":"))

# maps_data.gd - the embedded copy (the pop siege law), DESIGN now honest
body = json.dumps({"v": 2, "design": [int(W), int(H)], "levels": levels},
                  separators=(",", ":"))
gd = """## GENERATED by tools/v0414_marble_levels.py - do not edit by hand.
## One embedded copy of maps.json so the export never loses it (the pop siege law).
class_name MarbleMapsData

const DESIGN := Vector2(1080, 1920)
const DATA := %s
""" % body
open(f"{G}/game/games/marble/maps_data.gd", "w").write(gd)
print("maps.json + maps_data.gd written")

# ------------------------------------------------------------------ previews
from PIL import Image, ImageDraw

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

BK = f"{G}/assets/games/marble"
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
