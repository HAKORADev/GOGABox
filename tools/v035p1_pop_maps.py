#!/usr/bin/env python3
"""v0.3.5-1 POP SIEGE - the map truth rebuild.

Kills the hard-turn disease: every path is a Catmull-Rom spline sampled DENSE
(0.22-cell steps) so the game's polyline march reads as a smooth curve.
Every map bakes a PAINTED background (checker ground, soft road with borders
and wear, pooled water with shores, decor scatter, framed board) - the field
is a picture, not flat rects. Ids/names/themes/stars/prices are KEPT from the
old maps.json so saves, prices and the free trio survive.

Writes:
  game/games/pop_siege/maps.json          (geometry + props)
  game/games/pop_siege/maps_data.gd       (the export twin law)
  assets/games/pop_siege/bakes/{mid}.webp (1152x640 painted day board)
  assets/games/pop_siege/thumbs/{mid}.png + _n.png
"""
import json, math, os, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageEnhance

REPO = "/home/z/my-project/repo/GOGABox"
GDIR = f"{REPO}/projects/gogabox/game/games/pop_siege"
ADIR = f"{REPO}/projects/gogabox/assets/games/pop_siege"
PROPS = f"{ADIR}/props"
COLS, ROWS = 18, 10
BAK = 64                      # px per cell in the bake
BW, BH = COLS * BAK, ROWS * BAK
STEP = 0.22                   # spline sample step (cells)
IN = 1.4                      # offscreen entry depth (cells)

# ---------------------------------------------------------------- splines
def catmull(pts, step=STEP):
    """dense sampling through control points (closed=False)."""
    P = [pts[0]] + list(pts) + [pts[-1]]
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        d = math.dist(p1, p2)
        n = max(2, int(d / step))
        for j in range(n):
            t = j / n
            t2, t3 = t * t, t * t * t
            x = 0.5 * ((2 * p1[0]) + (-p0[0] + p2[0]) * t + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2 + (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * t3)
            y = 0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3)
            out.append((x, y))
    out.append(P[-2])
    return out

def resample(pts, step=STEP):
    """even arc-length resample."""
    out = [pts[0]]
    acc = 0.0
    for i in range(1, len(pts)):
        a, b = pts[i - 1], pts[i]
        d = math.dist(a, b)
        acc += d
        while acc >= step:
            k = 1.0 - (acc - step) / max(0.0001, d)
            out.append((a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k))
            acc -= step
        a = out[-1] if out else a
    out.append(pts[-1])
    return out

def spiral(cx, cy, r0, r1, turns, a0=math.pi, ccw=1):
    pts = []
    n = 46
    for i in range(n + 1):
        t = i / n
        a = a0 + ccw * turns * math.tau * t
        r = r0 + (r1 - r0) * t
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a) * 0.82))
    return pts

# ---------------------------------------------------------------- shapes
# each: control points (cell coords). Entry (-IN, y) exits at the HEART.
def S(*p):
    return [(-IN, p[0][1])] + [tuple(q) for q in p]

SHAPES = {
    # --- meadow ---
    "first_bloom":  [S((3.2, 2.6), (7.5, 2.2), (10.5, 5.2), (13.5, 8.0), (16.4, 7.6), (17.2, 6.2))],
    "sunny_loop":   [S((4.0, 1.8), (10.0, 1.6), (14.5, 3.4), (14.8, 7.2), (10.5, 8.6), (6.0, 8.4), (3.4, 6.2), (5.4, 4.0), (9.5, 4.4), (13.2, 4.8), (16.2, 5.0), (17.3, 5.0))],
    "twin_bloom":   [S((3.0, 2.0), (7.0, 1.8), (10.0, 3.4), (13.0, 5.4), (16.6, 5.0), (17.3, 5.0)),
                      S((3.0, 8.0), (7.0, 8.2), (10.0, 6.8), (13.0, 4.8), (16.6, 5.0), (17.3, 5.0))],
    # --- forest ---
    "pine_twist":   [S((2.8, 5.2), (5.5, 2.4), (9.0, 2.0), (11.5, 4.4), (9.8, 7.4), (13.0, 8.4), (16.0, 6.8), (17.3, 6.6))],
    "stump_waltz":  [S((3.0, 1.8), (8.0, 2.2), (10.0, 5.0), (7.0, 7.6), (12.0, 8.2), (15.0, 5.6), (17.3, 5.4))],
    "owl_spiral":   [S((4.5, 2.0), (9.0, 1.8), (12.5, 3.0))[:-1] + spiral(9.6, 5.4, 6.2, 1.5, 1.35, a0=-0.79, ccw=1)],
    # --- desert ---
    "dune_run":     [S((2.6, 2.2), (6.0, 1.8), (8.6, 3.8), (7.6, 6.4), (10.8, 8.0), (14.0, 6.6), (15.4, 4.2), (17.3, 4.0))],
    "scarab_s":     [S((2.6, 2.4), (8.5, 2.0), (12.0, 3.6), (12.4, 5.8), (10.6, 7.8), (12.8, 8.4), (15.0, 7.2), (16.6, 5.8), (17.3, 5.2))],
    "mirage_x":     [S((3.0, 1.8), (7.0, 2.2), (10.0, 4.6), (13.5, 7.0), (16.6, 6.2), (17.3, 5.2)),
                      S((3.0, 8.2), (7.0, 7.8), (10.0, 5.4), (13.5, 3.0), (16.6, 3.8), (17.3, 5.0))],
    # --- snow ---
    "frostbite":    [S((2.8, 4.6), (5.5, 7.6), (9.0, 7.8), (10.6, 5.0), (8.8, 2.4), (12.5, 1.9), (15.5, 4.0), (17.3, 4.4))],
    "snowman_march":[S((2.6, 2.0), (7.5, 2.4), (9.0, 5.0), (7.0, 7.8), (11.5, 8.2), (13.8, 5.4), (17.0, 5.0), (17.3, 5.0))],
    "aurora_twin":  [S((2.8, 2.6), (6.5, 2.2), (9.5, 3.8), (12.5, 5.8), (16.4, 5.2), (17.3, 5.2)),
                      S((2.8, 7.6), (6.5, 8.0), (9.5, 6.6), (12.5, 4.6), (16.4, 5.2), (17.3, 5.2))],
    # --- beach ---
    "boardwalk":    [S((2.6, 7.8), (6.5, 8.2), (10.0, 7.4), (12.5, 5.2), (12.0, 2.8), (15.0, 1.9), (17.0, 3.4), (17.3, 4.2))],
    "tide_zig":     [S((2.6, 2.0), (5.5, 2.2), (7.0, 4.4), (5.8, 6.8), (9.0, 8.0), (12.0, 7.0), (11.4, 4.4), (14.5, 2.4), (17.3, 3.2))],
    "crab_claw":    [S((2.6, 5.0), (5.5, 2.6), (9.0, 2.0), (12.5, 3.2), (15.5, 5.0), (17.3, 5.2)),
                      S((2.6, 5.0), (5.5, 7.6), (9.0, 8.2), (12.5, 7.0), (15.5, 5.0), (17.3, 5.2))],
    # --- swamp ---
    "murk_marsh":   [S((2.6, 2.2), (6.0, 2.6), (7.4, 5.0), (5.6, 7.4), (9.5, 8.2), (12.5, 6.4), (14.5, 3.6), (17.3, 3.4))],
    "frog_heart":   [S((2.6, 5.0), (5.0, 2.2), (8.5, 2.4), (9.6, 5.0), (8.5, 7.8), (12.0, 7.6), (13.4, 5.0), (12.2, 2.4), (15.5, 2.0), (17.3, 2.8))],
    "serpent_nile": [S((2.6, 1.8), (7.0, 2.0), (10.5, 2.6), (12.0, 5.0), (10.5, 7.4), (6.5, 7.8), (5.0, 5.4), (7.5, 4.2), (11.5, 4.6), (14.5, 5.4), (16.5, 6.0), (17.3, 6.0))],
    # --- volcano ---
    "ash_ridge":    [S((2.6, 7.6), (5.5, 8.2), (8.0, 6.6), (8.4, 4.2), (6.6, 2.4), (10.0, 1.8), (13.0, 3.4), (14.2, 6.2), (17.3, 6.6))],
    "magma_cross":  [S((2.6, 2.2), (6.5, 2.6), (9.0, 4.6), (12.0, 6.4), (15.8, 6.6), (17.3, 5.3)),
                      S((2.6, 7.8), (6.0, 8.2), (8.6, 6.8), (10.5, 4.6), (13.2, 3.2), (16.6, 4.2), (17.3, 5.05))],
    "obsidian_loop":[S((3.2, 5.0), (6.0, 2.0), (11.0, 1.8), (14.5, 3.4), (14.6, 6.8), (10.8, 8.4), (6.6, 8.2), (4.6, 6.4), (6.8, 4.8), (10.0, 4.6), (13.0, 5.0), (16.0, 5.2), (17.3, 5.2))],
    # --- candy ---
    "sugar_rush":   [S((2.6, 2.4), (6.5, 2.0), (9.0, 4.2), (6.8, 6.4), (10.5, 8.0), (14.0, 6.8), (13.6, 4.0), (16.5, 2.6), (17.3, 3.2))],
    "laby_lick":    [S((2.6, 5.2), (4.6, 2.4), (8.0, 1.9), (10.0, 4.0), (8.2, 6.6), (11.5, 8.2), (14.5, 6.6), (13.0, 4.2), (15.8, 2.6), (17.3, 3.0))],
    "gumdrop_spiral":[S((4.0, 8.2), (7.5, 8.4), (10.0, 7.6))[:-1] + spiral(9.8, 5.0, 6.0, 1.4, 1.3, a0=1.508, ccw=-1)],
    # --- graveyard ---
    "old_ground":   [S((2.6, 2.2), (7.5, 2.6), (10.5, 5.0), (8.5, 7.8), (12.5, 8.2), (15.0, 5.8), (17.3, 5.6))],
    "wailing_twin": [S((2.6, 2.0), (6.5, 2.2), (9.0, 4.0), (12.0, 5.6), (16.4, 5.4), (17.3, 5.4)),
                      S((2.6, 8.0), (6.5, 7.8), (9.0, 6.2), (12.0, 4.8), (16.4, 5.4), (17.3, 5.4))],
    "bone_spiral":  [S((4.6, 2.2), (8.0, 1.8), (10.5, 2.4))[:-1] + spiral(9.4, 5.6, 5.8, 1.3, 1.4, a0=-1.296, ccw=1)],
    # --- crystal ---
    "glow_grotto":  [S((2.6, 3.2), (5.0, 6.0), (8.5, 7.6), (12.0, 6.2), (12.6, 3.6), (15.5, 2.2), (17.3, 2.8))],
    "rune_heart":   [S((2.6, 5.0), (5.5, 1.9), (9.5, 2.2), (11.0, 5.0), (9.5, 7.9), (13.0, 8.2), (15.6, 5.8), (17.3, 5.6))],
    "the_last_siege":[S((2.6, 1.9), (7.0, 2.2), (10.0, 4.0), (13.2, 6.4), (16.6, 6.0), (17.3, 5.3)),
                       S((2.6, 8.1), (7.0, 7.8), (10.0, 6.2), (13.2, 3.8), (16.6, 4.2), (17.3, 5.05))],
}

# water clusters per map: [(cx, cy, rx, ry)] cell units; kind from theme
WATER = {
    "sunny_loop": [(15.6, 1.6, 1.6, 1.1), (1.6, 8.6, 1.2, 0.9)],
    "twin_bloom": [(10.2, 1.0, 1.5, 0.9)],
    "owl_spiral": [(16.0, 8.4, 1.7, 1.1), (2.0, 8.8, 1.1, 0.8)],
    "dune_run":   [(13.6, 1.8, 1.8, 1.0), (2.0, 7.4, 1.3, 0.9)],
    "mirage_x":   [(5.2, 5.0, 1.6, 1.0)],
    "frostbite":  [(15.8, 8.2, 1.9, 1.2)],
    "snowman_march": [(2.0, 5.6, 1.4, 1.0)],
    "aurora_twin": [(10.2, 8.9, 1.6, 0.9)],
    "boardwalk":  [(3.0, 1.6, 2.2, 1.2), (16.2, 8.6, 1.7, 1.0)],
    "tide_zig":   [(15.8, 6.6, 1.9, 1.3), (2.0, 8.7, 1.2, 0.9)],
    "crab_claw":  [(9.4, 5.0, 1.7, 1.1)],
    "murk_marsh": [(15.8, 5.6, 1.9, 1.2), (2.0, 5.0, 1.3, 0.9)],
    "frog_heart": [(2.0, 1.6, 1.5, 1.0), (15.8, 8.4, 1.7, 1.1)],
    "serpent_nile": [(15.9, 1.8, 1.8, 1.1), (2.0, 9.0, 1.3, 0.8)],
    "ash_ridge":  [(1.8, 1.8, 1.4, 0.9)],
    "magma_cross": [(13.4, 5.0, 1.6, 1.05)],
    "obsidian_loop": [(1.8, 8.6, 1.4, 0.9), (16.2, 1.8, 1.4, 0.9)],
    "sugar_rush": [(2.0, 6.2, 1.4, 1.0)],
    "laby_lick":  [(16.0, 8.4, 1.6, 1.0)],
    "gumdrop_spiral": [(2.0, 1.8, 1.5, 1.0), (16.0, 2.0, 1.4, 0.9)],
    "old_ground": [(15.9, 8.4, 1.7, 1.1)],
    "wailing_twin": [(9.4, 1.0, 1.6, 0.9)],
    "bone_spiral": [(16.1, 8.5, 1.6, 1.0)],
    "glow_grotto": [(2.0, 8.7, 1.4, 0.9), (16.0, 6.6, 1.5, 1.0)],
    "rune_heart": [(1.8, 8.8, 1.3, 0.9)],
    "the_last_siege": [(9.8, 5.0, 1.9, 1.15)],
}

# prop pools per theme (blocked cells pick from these)
PROP_POOL = {
    "meadow":   ["tree_round", "tree_round2", "tree_fruit", "bush", "flowers", "stones", "tree_pine"],
    "forest":   ["tree_pine", "tree_pine2", "tree_round", "tree_big", "stump", "bush2", "log"],
    "desert":   ["cactus", "rocks", "rocks2", "tree_dead", "skull", "bones"],
    "snow":     ["tree_frost", "tree_pine", "rocks", "stump", "tuft"],
    "beach":    ["palm", "palm2", "log", "rocks2", "tuft"],
    "swamp":    ["tree_dead", "mushrooms", "mushroom", "tuft", "branch", "bush"],
    "volcano":  ["rocks", "rocks2", "tree_dead", "branch", "stones"],
    "candy":    ["mushrooms", "mushroom", "pumpkin", "bush2", "flowers"],
    "graveyard": ["grave_a", "grave_b", "tombstone", "tree_dead", "bones", "skull"],
    "crystal":  ["crystal_tree", "rocks", "mushroom", "stones"],
}
DECOR_POOL = {
    "meadow":   ["flowers", "tuft", "bush2"], "forest": ["mushroom", "tuft", "flowers"],
    "desert":   ["tuft", "rocks2", "bones"], "snow": ["tuft", "rocks"],
    "beach":    ["tuft", "rocks2"], "swamp": ["mushroom", "tuft"],
    "volcano":  ["branch", "rocks2"], "candy": ["flowers", "mushroom"],
    "graveyard": ["bones", "tuft"], "crystal": ["mushroom", "tuft"],
}

# ---------------------------------------------------------------- palettes
# (ground a, ground b, road, road edge, road wear, water a, water b, shore, speck colors)
PAL = {
    "meadow":   ("#8ec84e", "#84be45", "#e8c284", "#a87e44", "#f2d8a6", "#3fa9e8", "#7cc9f2", "#ecd8a0", ("#a2d95e", "#f6e8b0")),
    "forest":   ("#6fae3f", "#65a437", "#d8b078", "#96703c", "#e6c894", "#3f9ed8", "#78c0ee", "#e2cc94", ("#83c14f", "#e8dca8")),
    "desert":   ("#ecd28e", "#e3c87f", "#c1934f", "#8f6830", "#d0a860", "#48b4e0", "#84d0f0", "#f2e2ae", ("#f4e2a2", "#c8a869")),
    "snow":     ("#eef4fa", "#e0eaf4", "#b6c8d8", "#7e94ac", "#dae6f0", "#a8d4ee", "#d0e8f8", "#f6fbff", ("#ffffff", "#c4d6e8")),
    "beach":    ("#f2de9e", "#e9d38c", "#c99a58", "#95703a", "#e0bc7c", "#40c2e8", "#82dcf4", "#f8ecc0", ("#f8e6ae", "#d8c486")),
    "swamp":    ("#7c984a", "#728e41", "#8f7040", "#5c4626", "#a58758", "#4e8a62", "#7cb088", "#9aa878", ("#92ae5e", "#b8c48c")),
    "volcano":  ("#5c4c48", "#524440", "#78605a", "#453830", "#8a7268", "#f08838", "#f8b860", "#a06848", ("#6e5a54", "#a89088")),
    "candy":    ("#f4c2d4", "#ecb6ca", "#dfa878", "#a87450", "#f2c89c", "#58c8e8", "#98e0f4", "#fbe4ee", ("#fbe0ec", "#e2a4c0")),
    "graveyard": ("#8f9579", "#858b6f", "#a49a86", "#6c6450", "#bcb4a0", "#4e8296", "#7cb0c2", "#b0b49c", ("#a2a888", "#c8ccb4")),
    "crystal":  ("#98a2d6", "#8e98ce", "#7a82b8", "#525a88", "#9aa2ce", "#58a8e8", "#94ccf4", "#b8c0e8", ("#aab4e2", "#c8d0f2")),
}
WATER_KIND = {"volcano": "lava", "snow": "ice"}
NIGHT_TINT = {  # thumb night multiply (matches PDData.THEMES night)
    "meadow": (76, 88, 132), "forest": (66, 82, 128), "desert": (82, 78, 128),
    "snow": (92, 102, 158), "beach": (76, 82, 140), "swamp": (71, 87, 112),
    "volcano": (107, 71, 71), "candy": (102, 82, 132), "graveyard": (76, 82, 122),
    "crystal": (97, 97, 158),
}

# ---------------------------------------------------------------- geometry
def dist_to_path(p, paths):
    best = 1e9
    for pts in paths:
        for q in pts:
            d = math.dist(p, q)
            if d < best:
                best = d
    return best

def water_cells(blobs):
    cells = []
    for cx, cy, rx, ry in blobs:
        for c in range(COLS):
            for r in range(ROWS):
                dx = (c + 0.5 - cx) / rx
                dy = (r + 0.5 - cy) / ry
                if dx * dx + dy * dy <= 1.0:
                    cells.append([c, r])
    return cells

def build_map(mid, meta):
    rng = random.Random(mid)
    shapes = SHAPES[mid]
    paths = []
    for ctrl in shapes:
        flat = catmull(ctrl)
        paths.append(resample(flat))
    # the heart: the shared end (right side)
    end = paths[0][-1]
    heart = [min(COLS - 1, max(0, int(end[0]))), min(ROWS - 1, max(0, int(end[1])))]
    water = water_cells(WATER.get(mid, []))
    wkind = WATER_KIND.get(meta["theme"], "water")
    # blocked prop cells: buildable land away from road + water + heart
    road = [(x, y) for pts in paths for (x, y) in pts]
    taken = set()
    for pts in paths:
        for (x, y) in pts:
            taken.add((int(x), int(y)))
    for (c, r) in water:
        taken.add((c, r))
    taken.add((heart[0], heart[1]))
    pool = PROP_POOL[meta["theme"]]
    blocked = []
    tries = 0
    target = rng.randint(11, 16)
    while len(blocked) < target and tries < 500:
        tries += 1
        c, r = rng.randrange(COLS), rng.randrange(ROWS)
        if (c, r) in taken:
            continue
        # keep the field breathe: not too many neighbors
        near = sum(1 for (bc, br, _) in blocked if abs(bc - c) <= 1 and abs(br - r) <= 1)
        if near >= 2:
            continue
        d = dist_to_path((c + 0.5, r + 0.5), paths)
        if d < 1.15:
            continue
        blocked.append([c, r, rng.choice(pool)])
        taken.add((c, r))
    m = dict(meta)
    m["paths"] = [[[round(x, 3), round(y, 3)] for (x, y) in pts] for pts in paths]
    m["heart"] = heart
    m["water"] = water
    if wkind != "water":
        m["water_kind"] = wkind
    m["blocked"] = blocked
    m.pop("decor", None)
    return m, rng

# ================================================================= BAKER
def hexc(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))

def prop_img(name):
    p = f"{PROPS}/{name}.png"
    return Image.open(p).convert("RGBA") if os.path.exists(p) else None

def bake(mid, m):
    theme = m["theme"]
    ga, gb, road, redge, rwear, wa, wb, shore, specks = PAL[theme]
    ga, gb, road, redge, rwear = hexc(ga), hexc(gb), hexc(road), hexc(redge), hexc(rwear)
    wa, wb, shore = hexc(wa), hexc(wb), hexc(shore)
    rng = m.get("_rng")
    im = Image.new("RGB", (BW, BH), ga)
    d = ImageDraw.Draw(im)
    # the checker ground (the ES read: alternating tones)
    for c in range(COLS):
        for r in range(ROWS):
            if (c + r) % 2 == 1:
                d.rectangle([c * BAK, r * BAK, (c + 1) * BAK - 1, (r + 1) * BAK - 1], fill=gb)
    # speckles
    sp1, sp2 = hexc(specks[0]), hexc(specks[1])
    for _ in range(int(COLS * ROWS * 2.6)):
        x, y = rng.randrange(BW), rng.randrange(BH)
        rr = rng.choice((1, 1, 2, 2, 3))
        col = sp1 if rng.random() < 0.6 else sp2
        d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=col)
    # water pools (shore ring + gradient + streaks)
    wk = m.get("water_kind", "water")
    blobs = WATER.get(mid, [])
    for (cx, cy, rx, ry) in blobs:
        x0, y0 = (cx - rx) * BAK, (cy - ry) * BAK
        x1, y1 = (cx + rx) * BAK, (cy + ry) * BAK
        pad = 7
        d.ellipse([x0 - pad, y0 - pad, x1 + pad, y1 + pad], fill=shore)
        grad = vertical_water(int(x1 - x0), int(y1 - y0), wa, wb, wk)
        mask = Image.new("L", grad.size, 0)
        ImageDraw.Draw(mask).ellipse([1, 1, grad.size[0] - 2, grad.size[1] - 2], fill=255)
        im.paste(grad, (int(x0), int(y0)), mask)
        # streaks
        sd = ImageDraw.Draw(im, "RGBA")
        for _ in range(5):
            sx = rng.uniform(x0 + 8, x1 - 8)
            sy = rng.uniform(y0 + 8, y1 - 8)
            ln = rng.uniform(8, 20)
            cc = (255, 255, 255, 70) if wk != "lava" else (255, 220, 120, 90)
            sd.line([sx - ln / 2, sy, sx + ln / 2, sy], fill=cc, width=2)
    # the road: edge pass, fill pass, wear pass, speckle
    for pts in m["paths"]:
        px = [(x * BAK, y * BAK) for (x, y) in pts]
        d.line(px, fill=redge, width=48, joint="curve")
        for endpt in (px[0], px[-1]):
            d.ellipse([endpt[0] - 24, endpt[1] - 24, endpt[0] + 24, endpt[1] + 24], fill=redge)
    for pts in m["paths"]:
        px = [(x * BAK, y * BAK) for (x, y) in pts]
        d.line(px, fill=road, width=38, joint="curve")
        for endpt in (px[0], px[-1]):
            d.ellipse([endpt[0] - 19, endpt[1] - 19, endpt[0] + 19, endpt[1] + 19], fill=road)
        # wear + speckles
        for i in range(0, len(px) - 1, 2):
            t = i / max(1, len(px) - 2)
            wx = px[i][0] + (px[i + 1][0] - px[i][0]) * 0.5
            wy = px[i][1] + (px[i + 1][1] - px[i][1]) * 0.5
            if rng.random() < 0.5:
                d.line([px[i], px[i + 1]], fill=rwear, width=7)
            if rng.random() < 0.4:
                rr = rng.choice((1, 2))
                off = rng.uniform(-9, 9)
                d.ellipse([wx + off - rr, wy + off - rr, wx + off + rr, wy + off + rr], fill=redge)
    # decor scatter (small prop sprites on free land)
    dec = DECOR_POOL[theme]
    placed = 0
    tries = 0
    while placed < 14 and tries < 220:
        tries += 1
        c, r = rng.randrange(COLS), rng.randrange(ROWS)
        if dist_to_path((c + 0.5, r + 0.5), m["paths"]) < 0.85:
            continue
        if any(bc == c and br == r for (bc, br, _) in m["blocked"]):
            continue
        if any(wc == c and wr == r for (wc, wr) in m["water"]):
            continue
        p = prop_img(rng.choice(dec))
        if p is None:
            continue
        sc = rng.uniform(0.34, 0.5)
        p = p.resize((max(1, int(p.width * sc)), max(1, int(p.height * sc))), Image.LANCZOS)
        if rng.random() < 0.5:
            p = p.transpose(Image.FLIP_LEFT_RIGHT)
        px = int((c + rng.uniform(0.15, 0.7)) * BAK)
        py = int((r + rng.uniform(0.2, 0.75)) * BAK)
        im.paste(p, (px, py), p)
        placed += 1
    # spawn pads (dark pockets at the field entries)
    for pts in m["paths"]:
        for (x, y) in pts:
            if x > 0.15:
                sx, sy = x * BAK, y * BAK
                d.ellipse([sx - 26, sy - 26, sx + 26, sy + 26], fill=hexc("#3a2a1c"))
                d.ellipse([sx - 16, sy - 16, sx + 16, sy + 16], fill=hexc("#241812"))
                d.ellipse([sx - 26, sy - 26, sx + 26, sy + 26], outline=hexc("#8a5a34"), width=3)
                break
    # the heart pad
    hx, hy = (m["heart"][0] + 0.5) * BAK, (m["heart"][1] + 0.5) * BAK
    d.ellipse([hx - 34, hy - 30, hx + 34, hy + 34], fill=hexc("#8a6a40"))
    d.ellipse([hx - 28, hy - 24, hx + 28, hy + 28], fill=hexc("#a8845a"))
    # the frame: rounded corners + border + top inner shadow
    im = im.convert("RGBA")
    mask = Image.new("L", (BW, BH), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, BW - 1, BH - 1], 20, fill=255)
    out = Image.new("RGBA", (BW, BH), (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    fd = ImageDraw.Draw(out)
    fd.rounded_rectangle([0, 0, BW - 1, BH - 1], 20, outline=(30, 22, 14, 200), width=4)
    shadow = Image.new("RGBA", (BW, BH), (0, 0, 0, 0))
    shd = ImageDraw.Draw(shadow)
    for i in range(14):
        shd.line([10, 4 + i, BW - 10, 4 + i], fill=(0, 0, 0, max(0, 30 - i * 2)))
    out.alpha_composite(Image.composite(shadow, Image.new("RGBA", (BW, BH), (0, 0, 0, 0)), mask))
    return out

def vertical_water(w, h, ca, cb, kind):
    grad = vertical_water_grad(w, h, ca, cb)
    if kind == "lava":
        grad = vertical_water_grad(w, h, (240, 120, 40), (255, 190, 70))
    elif kind == "ice":
        grad = vertical_water_grad(w, h, (190, 224, 244), (226, 242, 252))
    return grad

def vertical_water_grad(w, h, ca, cb):
    im = Image.new("RGB", (1, max(1, h)))
    px = im.load()
    for y in range(h):
        t = y / max(1, h - 1)
        px[0, y] = tuple(int(ca[i] + (cb[i] - ca[i]) * t) for i in range(3))
    return im.resize((max(1, w), max(1, h)))

def thumbs(mid, bake_im, theme):
    t = bake_im.resize((220, 122), Image.LANCZOS).convert("RGB")
    os.makedirs(f"{ADIR}/thumbs", exist_ok=True)
    t.save(f"{ADIR}/thumbs/{mid}.png")
    tint = NIGHT_TINT[theme]
    n = ImageEnhance.Color(t).enhance(0.75)
    n = ImageEnhance.Brightness(n).enhance(0.62)
    overlay = Image.new("RGB", t.size, tint)
    n = Image.blend(n, overlay, 0.42)
    n.save(f"{ADIR}/thumbs/{mid}_n.png")

def main():
    old = json.load(open(f"{GDIR}/maps.json"))
    maps = []
    os.makedirs(f"{ADIR}/bakes", exist_ok=True)
    for meta in old["maps"]:
        mid = meta["id"]
        m, rng = build_map(mid, meta)
        m["_rng"] = rng
        bk = bake(mid, m)
        bk.save(f"{ADIR}/bakes/{mid}.webp", quality=88)
        thumbs(mid, bk, meta["theme"])
        lens = [sum(math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1)) for pts in m["paths"]]
        print(f"{mid:16s} paths={len(m['paths'])} len={lens[0]:5.1f} water={len(m['water']):2d} block={len(m['blocked'])}")
        del m["_rng"]
        maps.append(m)
    json.dump({"maps": maps}, open(f"{GDIR}/maps.json", "w"), indent=1)
    # the export twin
    js = json.dumps({"maps": maps}, separators=(",", ":"))
    with open(f"{GDIR}/maps_data.gd", "w") as f:
        f.write("## GENERATED by tools/v035p1_pop_maps.py - do not edit by hand.\n")
        f.write("## The 30-map truth, embedded so the export never loses it.\n")
        f.write("class_name PDMapsData\nextends RefCounted\n\nconst DATA := " + js + "\n")
    print("MAPS DONE:", len(maps))

if __name__ == "__main__":
    main()
