#!/usr/bin/env python3
"""v0.3.5-3 POP SIEGE - THE DOORS TRUTH rebuild (the owner's 14-item round).

THE ONE-GRID LAW   : every entry head sits exactly ONE cell off-board (IN=1)
                     and nothing ever spawns deeper than that.
THE DOORS LAW      : multi-start maps carry SEPARATE doors. twin -> 2 doors,
                     cross/fortress/highway3 -> 3 doors. Each door owns a full
                     road to the ONE heart. wave_mode in the data:
                       solo   - one door, the classic march
                       slice  - the wave's groups alternate doors (double wave)
                       rotate - each wave marches from ONE door, the next wave
                                from the next; every 4th wave BURSTS across
                                ALL doors at once
THE PURE ARROW LAW : doors wear chevron arrows ONLY (the 3-circle worn trail
                     is dead). Chevrons draw for every door side.
THE WORLD SORT LAW : no BIG prop within 2 cells of any door corridor, none
                     within 1 cell of any road. The game y-sorts the world.
THE RICH BAKE LAW  : mottled ground, road ruts + worn shoulders + pebbles,
                     water banks, vignette, bolder decor.

Ids / names / themes / stars / prices KEPT (saves survive).
Writes maps.json, maps_data.gd, bakes + day/night thumbs.
"""
import json, math, os, random
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

REPO = "/home/z/my-project/repo/GOGABox"
GDIR = f"{REPO}/projects/gogabox/game/games/pop_siege"
ADIR = f"{REPO}/projects/gogabox/assets/games/pop_siege"
PROPS = f"{ADIR}/props"
COLS, ROWS = 18, 10
BAK = 64
SS = 2
BW, BH = COLS * BAK, ROWS * BAK
IN = 1                        # THE ONE-GRID LAW

BIG_PROPS = {"tree_round", "tree_round2", "tree_fruit", "tree_pine", "tree_pine2",
             "tree_big", "tree_dead", "tree_frost", "palm", "palm2", "crystal_tree"}

# ------------------------------------------------------------ cell walking
def lwalk(anchors, vert_first=False):
    out = [tuple(anchors[0])]
    for i in range(1, len(anchors)):
        a, b = out[-1], tuple(anchors[i])
        dc, dr = b[0] - a[0], b[1] - a[1]
        if vert_first:
            vs = [(a[0], a[1] + (1 if dr > 0 else -1) * k) for k in range(1, abs(dr) + 1)]
            hs = [(a[0] + (1 if dc > 0 else -1) * k, b[1]) for k in range(1, abs(dc) + 1)]
            seg = vs + hs
        else:
            hs = [(a[0] + (1 if dc > 0 else -1) * k, a[1]) for k in range(1, abs(dc) + 1)]
            vs = [(b[0], a[1] + (1 if dr > 0 else -1) * k) for k in range(1, abs(dr) + 1)]
            seg = hs + vs
        for c in seg:
            if c != out[-1]:
                out.append(c)
    return out

def _max_turn(pts):
    worst = 0.0
    for i in range(2, len(pts)):
        d1 = (pts[i - 1][0] - pts[i - 2][0], pts[i - 1][1] - pts[i - 2][1])
        d2 = (pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1])
        n1, n2 = math.hypot(*d1), math.hypot(*d2)
        if n1 < 0.01 or n2 < 0.01:
            continue
        a = abs(math.atan2(d2[1], d2[0]) - math.atan2(d1[1], d1[0]))
        if a > math.pi:
            a = 2 * math.pi - a
        worst = max(worst, a)
    return worst

def chaikin_resample(cells, rounds=5, step=0.28):
    raw = [(c + 0.5, r + 0.5) for (c, r) in cells]
    pts = [raw[0]]
    acc = 0.0
    for i in range(1, len(raw)):
        a, b = raw[i - 1], raw[i]
        d = math.dist(a, b)
        acc += d
        while acc >= step:
            k = 1.0 - (acc - step) / max(0.0001, d)
            pts.append((a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k))
            acc -= step
    pts.append(raw[-1])
    for _ in range(rounds):
        out = [pts[0]]
        for i in range(1, len(pts) - 1):
            px = 0.25 * pts[i - 1][0] + 0.5 * pts[i][0] + 0.25 * pts[i + 1][0]
            py = 0.25 * pts[i - 1][1] + 0.5 * pts[i][1] + 0.25 * pts[i + 1][1]
            out.append((px, py))
        out.append(pts[-1])
        pts = out
        if _max_turn(pts) < 0.7:
            break
    res = [pts[0]]
    acc = 0.0
    for i in range(1, len(pts)):
        a, b = pts[i - 1], pts[i]
        d = math.dist(a, b)
        acc += d
        while acc >= 0.26:
            k = 1.0 - (acc - 0.26) / max(0.0001, d)
            res.append((a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k))
            acc -= 0.26
    res.append(pts[-1])
    return res

def door(cells, side, line):
    """THE ONE-GRID LAW: exactly one off-board head cell + a bridge walk.
    side: left/right/top/bottom. line: the row (or column) of the door."""
    head = {"left": (-1, line), "right": (COLS, line),
            "top": (line, -1), "bottom": (line, ROWS)}[side]
    if side in ("left", "right"):
        bridge = lwalk([head, tuple(cells[0])])[1:-1]
    else:
        bridge = lwalk([head, tuple(cells[0])], vert_first=True)[1:-1]
    return [head] + bridge + list(cells)

def door_side_of(cells):
    """which edge the head pokes through (for the bake chevrons)."""
    c, r = cells[0]
    if c < 0:
        return "left", r
    if c >= COLS:
        return "right", r
    if r < 0:
        return "top", c
    return "bottom", c

# ------------------------------------------------------------ archetypes
def arch_snake(rng, variant=0):
    rows = [1, 8, 3, 6] if variant == 0 else [8, 1, 6, 3]
    cols = [0, 5, 9, 13, 16]
    anchors = [(cols[0], rows[0])]
    for i in range(1, len(cols)):
        nr = rows[i % len(rows)]
        anchors.append((cols[i - 1], nr))
        anchors.append((cols[i], nr))
    cells = lwalk(anchors)
    cells += lwalk([cells[-1], (17, cells[-1][1])])
    return [door(cells, "left", cells[0][1])], (17, cells[-1][1]), "solo"

def arch_highway3(rng):
    """THE 3-DOOR HIGHWAY: three SEPARATE doors (rows 2/4/6 on the left),
    each lane its own winding road, all merging at the ONE heart door."""
    rows_in = [2, 4, 6]
    paths = []
    for k, r0 in enumerate(rows_in):
        mid = 9 + k
        anchors = [(0, r0), (4 + k, r0), (4 + k, r0 + (2 if k != 1 else -2)),
                   (8, r0 + (2 if k != 1 else -2)), (8, 5), (11, 5), (13, 5 + (k - 1)),
                   (16, 5)]
        cells = lwalk(anchors)
        if cells[-1] != (17, 5):
            cells += lwalk([cells[-1], (17, 5)])
        paths.append(door(cells, "left", r0))
    return paths, (17, 5), "rotate"

def arch_twin(rng):
    merge_c = rng.randrange(9, 12)
    row_mid = 5
    shared = lwalk([(merge_c - 2, row_mid), (merge_c + 2, row_mid),
                    (merge_c + 5, row_mid + (2 if rng.random() < 0.5 else -2)), (17, row_mid + 1)])
    top = door(lwalk([(0, 1), (4, 1), (7, 2), (merge_c - 2, row_mid)]) + shared, "left", 1)
    bot = door(lwalk([(0, 8), (4, 8), (7, 7), (merge_c - 2, row_mid)]) + shared, "left", 8)
    return [top, bot], (17, row_mid + 1), "slice"

def arch_twin_ud(rng):
    """two doors from TOP + BOTTOM edges (the vertical twin)."""
    vc = rng.randrange(3, 6)
    merge_r = 5
    shared = lwalk([(vc + 2, merge_r), (10, merge_r), (13, 3), (17, 4)])
    top = door(lwalk([(vc, 0), (vc, 2), (vc + 2, 2), (vc + 2, merge_r)]) + shared, "top", vc)
    bot = door(lwalk([(vc + 5, ROWS - 1), (vc + 5, 7), (vc + 2, 7), (vc + 2, merge_r)]) + shared,
               "bottom", vc + 5)
    return [top, bot], (17, 4), "slice"

def arch_split(rng, branches=2):
    sc = rng.randrange(4, 6)
    ec = rng.randrange(12, 14)
    mid_r = rng.choice([3, 4, 5, 6])
    head = lwalk([(0, mid_r), (sc - 1, mid_r)])
    tail = lwalk([(ec + 1, mid_r), (17, mid_r)])
    if branches == 2:
        brs = [lwalk([(sc - 1, mid_r), (sc + 2, 1), (ec - 2, 1), (ec + 1, mid_r)]),
               lwalk([(sc - 1, mid_r), (sc + 2, 8), (ec - 2, 8), (ec + 1, mid_r)])]
    else:
        brs = [lwalk([(sc - 1, mid_r), (sc + 2, 1), (ec - 2, 1), (ec + 1, mid_r)]),
               lwalk([(sc - 1, mid_r), (ec + 1, mid_r)]),
               lwalk([(sc - 1, mid_r), (sc + 2, 8), (ec - 2, 8), (ec + 1, mid_r)])]
    paths = [door(head + br + tail, "left", mid_r) for br in brs]
    return paths, (17, mid_r), "slice"

def arch_spiral(rng, tight=1.0):
    c0, c1, r0, r1 = 2, 15, 1, 8
    cells = []
    while c1 - c0 >= 2 and r1 - r0 >= 2:
        ring = ([(c, r0) for c in range(c0, c1 + 1)] +
                [(c1, r) for r in range(r0 + 1, r1 + 1)] +
                [(c, r1) for c in range(c1 - 1, c0 - 1, -1)] +
                [(c0, r) for r in range(r1 - 1, r0, -1)])
        cells += ring
        c0, c1, r0, r1 = c0 + 2, c1 - 2, r0 + 2, r1 - 2
    eye = ((c0 + c1) // 2, max(0, min(ROWS - 1, (r0 + r1) // 2)))
    if cells[-1] != eye:
        cells += lwalk([cells[-1], eye])
    return [door(cells, "left", cells[0][1])], eye, "solo"

def arch_loop(rng, double=False):
    outer = ([(c, 1) for c in range(2, 16)] + [(16, r) for r in range(1, 8)] +
             [(c, 8) for c in range(16, 1, -1)] + [(2, r) for r in range(8, 1, -1)])
    cells = list(outer)
    if double:
        inner = ([(c, 3) for c in range(5, 13)] + [(13, r) for r in range(3, 6)] +
                 [(c, 6) for c in range(13, 4, -1)] + [(5, r) for r in range(6, 2, -1)])
        cells += inner
    cells += lwalk([cells[-1], (14, 5), (17, 5)])
    return [door(cells, "left", cells[0][1])], (17, 5), "solo"

def arch_comb(rng, horizontal=True):
    anchors = []
    b = 8 if rng.random() < 0.5 else 1
    for a in range(0, 15, 2):
        nb = 1 if b == 8 else 8
        anchors.append((a, b))
        anchors.append((a, nb))
        b = nb
    door_b = b if rng.random() < 0.6 else rng.choice([3, 4, 5])
    anchors += [(16, b), (16, door_b), (17, door_b)]
    cells = lwalk(anchors)
    return [door(cells, "left", cells[0][1])], (17, door_b), "solo"

def arch_cross(rng):
    """THREE doors: left + top + bottom, all bending toward the heart."""
    hr = rng.choice([4, 5])
    vc = rng.randrange(11, 14)
    heart = (vc, hr)
    hpath = door(lwalk([(0, hr), (4, hr), (4, hr - 2 if hr >= 2 else hr + 2),
                        (8, hr - 2 if hr >= 2 else hr + 2), (8, hr), (vc, hr)]), "left", hr)
    top = door(lwalk([(vc, 0), (vc - 3, 1), (vc - 3, 2), (vc, 2), (vc, hr)]), "top", vc)
    bot = door(lwalk([(vc, ROWS - 1), (vc + 2, 8), (vc + 2, 7), (vc, 7), (vc, hr)]), "bottom", vc)
    return [hpath, top, bot], heart, "rotate"

def arch_fortress(rng):
    """THREE winding doors converge on a central heart (the last siege)."""
    heart = (9, 4)
    a = lwalk([(0, 1), (3, 1), (3, 3), (6, 3), (6, 5), (8, 5), (9, 4)])
    b = lwalk([(0, 8), (3, 8), (3, 6), (6, 6), (6, 4), (8, 4), (9, 4)])
    c = lwalk([(17, 5), (13, 5), (13, 3), (11, 3), (11, 4), (9, 4)])
    return [door(a, "left", 1), door(b, "left", 8), door(c, "right", 5)], heart, "rotate"

ARCH = {
    "first_bloom":   ("snake", 0),  "sunny_loop":    ("loop", 0),
    "twin_bloom":    ("twin", 0),   "pine_twist":    ("comb", 0),
    "stump_waltz":   ("snake", 1),  "owl_spiral":    ("spiral", 0),
    "dune_run":      ("snake", 0),  "scarab_s":      ("snake", 1),
    "mirage_x":      ("cross", 0),  "frostbite":     ("split", 2),
    "snowman_march": ("snake", 0),  "aurora_twin":   ("twin_ud", 0),
    "boardwalk":     ("highway3", 0), "tide_zig":    ("comb", 1),
    "crab_claw":     ("split", 2),  "murk_marsh":    ("spiral", 0),
    "frog_heart":    ("loop", 0),   "serpent_nile":  ("snake", 0),
    "ash_ridge":     ("snake", 1),  "magma_cross":   ("cross", 0),
    "obsidian_loop": ("loop", 1),   "sugar_rush":    ("split", 3),
    "laby_lick":     ("comb", 0),   "gumdrop_spiral": ("spiral", 0),
    "old_ground":    ("snake", 0),  "wailing_twin":  ("twin", 0),
    "bone_spiral":   ("spiral", 0), "glow_grotto":   ("highway3", 0),
    "rune_heart":    ("cross", 0),  "the_last_siege": ("fortress", 0),
}

def clamp_row(r):
    return max(0, min(ROWS - 1, int(r)))

def mirror_cells(cells, mx, my):
    if not mx and not my:
        return cells
    out = []
    for (c, r) in cells:
        cc = (COLS - 1 - c) if mx else c
        rr = (ROWS - 1 - r) if my else r
        out.append((cc, rr))
    return out

# ---------------------------------------------------------------- palettes
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
NIGHT_TINT = {
    "meadow": (76, 88, 132), "forest": (66, 82, 128), "desert": (82, 78, 128),
    "snow": (92, 102, 158), "beach": (76, 82, 140), "swamp": (71, 87, 112),
    "volcano": (107, 71, 71), "candy": (102, 82, 132), "graveyard": (76, 82, 122),
    "crystal": (97, 97, 158),
}
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
WATER = {
    "sunny_loop": [(1.6, 8.6, 1.2, 0.9)], "twin_bloom": [(10.2, 1.0, 1.5, 0.9)],
    "owl_spiral": [(16.0, 8.4, 1.7, 1.1)], "dune_run": [(13.6, 1.8, 1.8, 1.0)],
    "mirage_x": [(5.2, 5.0, 1.6, 1.0)], "frostbite": [(15.8, 8.2, 1.9, 1.2)],
    "snowman_march": [(2.0, 5.6, 1.4, 1.0)], "aurora_twin": [(10.2, 8.9, 1.6, 0.9)],
    "boardwalk": [(3.0, 1.4, 2.2, 1.0)], "tide_zig": [(15.8, 6.6, 1.9, 1.3)],
    "crab_claw": [(9.4, 5.0, 1.7, 1.1)], "murk_marsh": [(15.8, 5.6, 1.9, 1.2)],
    "frog_heart": [(2.0, 1.6, 1.5, 1.0)], "serpent_nile": [(15.9, 1.8, 1.8, 1.1)],
    "ash_ridge": [(1.8, 1.8, 1.4, 0.9)], "magma_cross": [(13.4, 8.2, 1.6, 1.0)],
    "obsidian_loop": [(1.8, 8.6, 1.4, 0.9)], "sugar_rush": [(2.0, 6.2, 1.4, 1.0)],
    "laby_lick": [(16.0, 8.4, 1.6, 1.0)], "gumdrop_spiral": [(2.0, 1.8, 1.5, 1.0)],
    "old_ground": [(15.9, 8.4, 1.7, 1.1)], "wailing_twin": [(9.4, 1.0, 1.6, 0.9)],
    "bone_spiral": [(16.1, 8.5, 1.6, 1.0)], "glow_grotto": [(16.0, 8.6, 1.5, 1.0)],
    "rune_heart": [(1.8, 8.8, 1.3, 0.9)], "the_last_siege": [(2.0, 4.6, 1.2, 1.3)],
}

def hexc(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))

def prop_img(name):
    p = f"{PROPS}/{name}.png"
    return Image.open(p).convert("RGBA") if os.path.exists(p) else None

# ---------------------------------------------------------------- build
def build_map(mid, meta, flip):
    rng = random.Random(mid + "v3")
    kind, variant = ARCH[mid]
    fn = {"snake": lambda: arch_snake(rng, variant),
          "highway3": lambda: arch_highway3(rng),
          "twin": lambda: arch_twin(rng),
          "twin_ud": lambda: arch_twin_ud(rng),
          "split": lambda: arch_split(rng, 3 if variant == 3 else 2),
          "spiral": lambda: arch_spiral(rng),
          "loop": lambda: arch_loop(rng, variant == 1),
          "comb": lambda: arch_comb(rng, variant == 1),
          "cross": lambda: arch_cross(rng),
          "fortress": lambda: arch_fortress(rng)}[kind]
    paths_c, heart, wave_mode = fn()
    mx, my = flip
    if mx or my:
        paths_c = [mirror_cells(p, mx, my) for p in paths_c]
        heart = mirror_cells([heart], mx, my)[0]
    # clamp into the ONE-GRID window (heads sit at -1 or COLS/ROWS)
    fixed = []
    for p in paths_c:
        cl = [(min(COLS, max(-1, c)), min(ROWS, max(-1, r))) for (c, r) in p]
        fixed.append(cl)
    paths_c = fixed
    heart = (min(COLS - 1, max(0, heart[0])), min(ROWS - 1, max(0, heart[1])))
    paths = [chaikin_resample(p) for p in paths_c]
    # the road truth: the union grid cells (on-board only) + THE PAINT TRUTH:
    # every cell the DENSE walk touches is road - the relaxation drifts the
    # curve up to ~0.4 cell, so the walked cells alone let bloons cross
    # unpainted grass at the turns (the owner's item 4)
    road = set()
    for p in paths_c:
        for (c, r) in p:
            if 0 <= c < COLS and 0 <= r < ROWS:
                road.add((c, r))
    for p in paths:
        for (x, y) in p:
            if 0 <= x < COLS and 0 <= y < ROWS:
                road.add((int(math.floor(x)), int(math.floor(y))))
    road.add(heart)
    # THE DOOR CORRIDORS: the first two ON-BOARD cells of every path
    corridors = set()
    for p in paths_c:
        onb = [(c, r) for (c, r) in p if 0 <= c < COLS and 0 <= r < ROWS][:2]
        for (c, r) in onb:
            corridors.add((c, r))
            corridors.add((c, r - 1))
            corridors.add((c, r + 1))
    # water cells (never on the road)
    water = []
    for (cx, cy, rx, ry) in WATER.get(mid, []):
        for c in range(COLS):
            for r in range(ROWS):
                if (c, r) in road:
                    continue
                dx = (c + 0.5 - cx) / rx
                dy = (r + 0.5 - cy) / ry
                if dx * dx + dy * dy <= 1.0:
                    water.append([c, r])
    wset = {(c, r) for (c, r) in water}
    pool = PROP_POOL[meta["theme"]]
    free = [(c, r) for c in range(COLS) for r in range(ROWS)
            if (c, r) not in road and (c, r) not in wset and (c, r) != heart
            and (c, r) not in corridors]
    rng.shuffle(free)
    blocked = []
    occ = set()
    target = min(54, int(len(free) * rng.uniform(0.36, 0.46)))
    for (c, r) in free:
        if len(blocked) >= target:
            break
        neigh = [(c - 1, r), (c + 1, r), (c, r - 1), (c, r + 1)]
        road_would_lose = [n for n in neigh if n in road]
        ok = True
        for n in road_would_lose:
            free_n = [q for q in [(n[0] - 1, n[1]), (n[0] + 1, n[1]), (n[0], n[1] - 1), (n[0], n[1] + 1)]
                      if q not in road and q not in occ and q not in wset and q != (c, r)]
            if len(free_n) < 1:
                ok = False
                break
        if not ok:
            continue
        name = rng.choice(pool)
        # THE WORLD SORT LAW: no BIG prop near a door corridor
        if name in BIG_PROPS:
            near_door = any(abs(c - dc) <= 2 and abs(r - dr) <= 2 for (dc, dr) in corridors)
            if near_door:
                name = rng.choice([p for p in pool if p not in BIG_PROPS] or [name])
        blocked.append([c, r, name])
        occ.add((c, r))
    m = dict(meta)
    m["paths"] = [[[round(x, 3), round(y, 3)] for (x, y) in pts] for pts in paths]
    m["road_cells"] = [[c, r] for (c, r) in sorted(road)]
    m["heart"] = [heart[0], heart[1]]
    m["water"] = water
    if WATER_KIND.get(meta["theme"], "water") != "water":
        m["water_kind"] = WATER_KIND[meta["theme"]]
    m["blocked"] = blocked
    m["wave_mode"] = wave_mode
    m.pop("decor", None)
    return m, rng

# ---------------------------------------------------------------- baker
def paint_road_layer(draw, road, color, inset, radius):
    cs = BAK * SS
    for (c, r) in road:
        x0, y0 = c * cs + inset, r * cs + inset
        x1, y1 = (c + 1) * cs - inset, (r + 1) * cs - inset
        draw.rounded_rectangle([x0, y0, x1, y1], radius, fill=color)
        if (c + 1, r) in road:
            draw.rectangle([x1 - radius, y0, (c + 2) * cs - inset + radius, y1], fill=color)
        if (c, r + 1) in road:
            draw.rectangle([x0, y1 - radius, x1, (r + 2) * cs - inset + radius], fill=color)

def chevrons(d, cx, cy, ang, n=2, step=0.42, size=15):
    """THE PURE ARROW LAW: chevron arrows only, pointing along ang."""
    for i in range(n):
        bx = cx + math.cos(ang) * BAK * step * i
        by = cy + math.sin(ang) * BAK * step * i
        for sgn in (1, -1):
            wing = ang + math.pi * 0.72 * sgn
            wx, wy = bx + math.cos(wing) * size, by + math.sin(wing) * size
            d.line([wx, wy, bx, by], fill=(74, 50, 26, 150), width=7)
            d.line([wx, wy, bx, by], fill=(255, 244, 210, 240), width=4)

def bake(mid, m):
    theme = m["theme"]
    ga, gb, road, redge, rwear, wa, wb, shore, specks = PAL[theme]
    ga, gb, road, redge, rwear = hexc(ga), hexc(gb), hexc(road), hexc(redge), hexc(rwear)
    wa, wb, shore = hexc(wa), hexc(wb), hexc(shore)
    rng = m.get("_rng")
    im = Image.new("RGB", (BW, BH), ga)
    d = ImageDraw.Draw(im)
    for c in range(COLS):
        for r in range(ROWS):
            if (c + r) % 2 == 1:
                d.rectangle([c * BAK, r * BAK, (c + 1) * BAK - 1, (r + 1) * BAK - 1], fill=gb)
    # THE RICH GROUND: two mottle octaves (big soft blotches + small freckles)
    blot = Image.new("RGBA", (BW // 4, BH // 4), (0, 0, 0, 0))
    bd = ImageDraw.Draw(blot)
    dk = tuple(max(0, v - 26) for v in hexc(specks[0]))
    lt = tuple(min(255, v + 22) for v in hexc(specks[1]))
    for _ in range(46):
        x, y = rng.randrange(blot.width), rng.randrange(blot.height)
        rr = rng.randint(6, 16)
        col = dk + (46,) if rng.random() < 0.5 else lt + (42,)
        bd.ellipse([x - rr, y - rr, x + rr, y + rr], fill=col)
    blot = blot.resize((BW, BH), Image.BILINEAR).filter(ImageFilter.GaussianBlur(7))
    im = im.convert("RGBA")
    im.alpha_composite(blot)
    d = ImageDraw.Draw(im)
    sp1, sp2 = hexc(specks[0]), hexc(specks[1])
    for _ in range(int(COLS * ROWS * 2.6)):
        x, y = rng.randrange(BW), rng.randrange(BH)
        rr = rng.choice((1, 1, 2, 2, 3))
        col = sp1 if rng.random() < 0.6 else sp2
        d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=col + (255,))
    # water: banks first, then the gradient body, sparkle, shore tufts
    wk = m.get("water_kind", "water")
    for (c, r) in m["water"]:
        x0, y0 = c * BAK, r * BAK
        d.rounded_rectangle([x0 - 7, y0 - 7, x0 + BAK + 7, y0 + BAK + 7], 16, fill=shore)
    for (c, r) in m["water"]:
        x0, y0 = c * BAK, r * BAK
        grad = vertical_water(BAK + 8, BAK + 8, wa, wb, wk)
        mask = Image.new("L", grad.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle([4, 4, grad.size[0] - 5, grad.size[1] - 5], 12, fill=255)
        im.paste(grad, (x0 - 4, y0 - 4), mask)
        sd = ImageDraw.Draw(im, "RGBA")
        for _ in range(3):
            sx = rng.uniform(x0 + 8, x0 + BAK - 8)
            sy = rng.uniform(y0 + 8, y0 + BAK - 8)
            ln = rng.uniform(8, 20)
            cc = (255, 255, 255, 70) if wk != "lava" else (255, 220, 120, 90)
            sd.line([sx - ln / 2, sy, sx + ln / 2, sy], fill=cc, width=2)
    # THE GRID ROADS: supersampled merged rounded cells
    roadset = {(c, r) for (c, r) in m["road_cells"]}
    ss_im = im.resize((BW * SS, BH * SS), Image.NEAREST).convert("RGBA")
    ssd = ImageDraw.Draw(ss_im, "RGBA")
    cs = BAK * SS
    paint_road_layer(ssd, roadset, redge + (255,), 6 * SS, 16 * SS)
    paint_road_layer(ssd, roadset, road + (255,), 11 * SS, 12 * SS)
    # wear: dashed center lines along the movement polylines
    for pts in m["paths"]:
        px = [(x * cs, y * cs) for (x, y) in pts]
        for i in range(0, len(px) - 1, 3):
            if rng.random() < 0.5:
                ssd.line([px[i], px[i + 1]], fill=rwear + (150,), width=5 * SS)
    im = ss_im.resize((BW, BH), Image.LANCZOS)
    d = ImageDraw.Draw(im, "RGBA")
    # road speckles + pebbles
    for _ in range(160):
        c, r = rng.choice(m["road_cells"])
        x = rng.uniform(c * BAK + 8, (c + 1) * BAK - 8)
        y = rng.uniform(r * BAK + 8, (r + 1) * BAK - 8)
        rr = rng.choice((1, 2))
        d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=redge + (160,))
    for _ in range(26):
        c, r = rng.choice(m["road_cells"])
        x = rng.uniform(c * BAK + 10, (c + 1) * BAK - 10)
        y = rng.uniform(r * BAK + 10, (r + 1) * BAK - 10)
        rr = rng.uniform(2.0, 3.6)
        peb = tuple(min(255, v + 34) for v in road)
        d.ellipse([x - rr, y - rr * 0.8, x + rr, y + rr * 0.8], fill=peb + (170,))
        d.ellipse([x - rr, y - rr * 0.8, x + rr * 0.4, y - rr * 0.1],
                  fill=tuple(min(255, v + 60) for v in road) + (150,))
    # THE PURE ARROW LAW: chevrons only, correct for every door side
    for pts in m["paths"]:
        if len(pts) < 4:
            continue
        p0, p1 = pts[0], pts[1]
        ang = math.atan2(p1[1] - p0[1], p1[0] - p0[0])
        onb = next((q for q in pts if 0 <= q[0] <= COLS - 1 and 0 <= q[1] <= ROWS - 1), None)
        if onb is None:
            continue
        ax, ay = (onb[0] + 0.5) * BAK, (onb[1] + 0.5) * BAK
        # the worn approach: a STRIP along the march (never a circle)
        bx, by = ax - math.cos(ang) * BAK * 0.45, ay - math.sin(ang) * BAK * 0.45
        d.line([bx, by, ax, ay], fill=rwear + (110,), width=int(BAK * 0.62))
        chevrons(d, ax, ay, ang)
    # grass/pebble shoulders hugging the road (the road reads worn into grass)
    dec = DECOR_POOL[theme]
    occ = {(c, r) for (c, r, _) in m["blocked"]} | {(c, r) for (c, r) in m["water"]} | roadset | {(m["heart"][0], m["heart"][1])}
    shoulder = []
    for (c, r) in sorted(roadset):
        for q in [(c - 1, r), (c + 1, r), (c, r - 1), (c, r + 1)]:
            if q not in roadset and q not in occ and 0 <= q[0] < COLS and 0 <= q[1] < ROWS:
                shoulder.append(q)
    rng.shuffle(shoulder)
    for (c, r) in shoulder[:30]:
        p = prop_img(rng.choice(dec))
        if p is None:
            continue
        sc = rng.uniform(0.22, 0.34)
        p = p.resize((max(1, int(p.width * sc)), max(1, int(p.height * sc))), Image.LANCZOS)
        if rng.random() < 0.5:
            p = p.transpose(Image.FLIP_LEFT_RIGHT)
        im.paste(p, (int((c + rng.uniform(0.2, 0.6)) * BAK), int((r + rng.uniform(0.24, 0.62)) * BAK)), p)
    # the heart pad
    hx, hy = (m["heart"][0] + 0.5) * BAK, (m["heart"][1] + 0.5) * BAK
    d.rounded_rectangle([hx - 46, hy - 44, hx + 46, hy + 44], 18, fill=hexc("#8a6a40") + (255,))
    d.rounded_rectangle([hx - 38, hy - 36, hx + 38, hy + 36], 14, fill=hexc("#a8845a") + (255,))
    for a in range(6):
        ang2 = a * math.pi / 3.0 + 0.3
        sx2, sy2 = hx + math.cos(ang2) * 54, hy + math.sin(ang2) * 52
        d.ellipse([sx2 - 5, sy2 - 4, sx2 + 5, sy2 + 4], fill=hexc("#c8a878") + (255,))
    # bolder decor scatter on free land
    placed, tries = 0, 0
    while placed < 22 and tries < 320:
        tries += 1
        c, r = rng.randrange(COLS), rng.randrange(ROWS)
        if (c, r) in occ:
            continue
        p = prop_img(rng.choice(dec))
        if p is None:
            continue
        sc = rng.uniform(0.34, 0.5)
        p = p.resize((max(1, int(p.width * sc)), max(1, int(p.height * sc))), Image.LANCZOS)
        if rng.random() < 0.5:
            p = p.transpose(Image.FLIP_LEFT_RIGHT)
        im.paste(p, (int((c + rng.uniform(0.15, 0.6)) * BAK), int((r + rng.uniform(0.2, 0.62)) * BAK)), p)
        placed += 1
    # the vignette: soft edge darkening (the board reads framed and deep)
    vg = Image.new("L", (BW // 4, BH // 4), 0)
    vd = ImageDraw.Draw(vg)
    vd.rounded_rectangle([2, 2, BW // 4 - 3, BH // 4 - 3], 6, fill=255)
    vd.rounded_rectangle([7, 7, BW // 4 - 8, BH // 4 - 8], 5, fill=0)
    vg = vg.resize((BW, BH), Image.BILINEAR).filter(ImageFilter.GaussianBlur(6))
    shade = Image.new("RGBA", (BW, BH), (18, 14, 8, 70))
    im.alpha_composite(Image.composite(shade, Image.new("RGBA", (BW, BH), (0, 0, 0, 0)), vg))
    # the frame
    mask = Image.new("L", (BW, BH), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, BW - 1, BH - 1], 20, fill=255)
    out = Image.new("RGBA", (BW, BH), (0, 0, 0, 0))
    out.paste(im.convert("RGB"), (0, 0), mask)
    fd = ImageDraw.Draw(out)
    fd.rounded_rectangle([0, 0, BW - 1, BH - 1], 20, outline=(30, 22, 14, 220), width=4)
    fd.rounded_rectangle([3, 3, BW - 4, BH - 4], 18, outline=(255, 240, 200, 36), width=2)
    shadow = Image.new("RGBA", (BW, BH), (0, 0, 0, 0))
    shd = ImageDraw.Draw(shadow)
    for i in range(14):
        shd.line([10, 4 + i, BW - 10, 4 + i], fill=(0, 0, 0, max(0, 30 - i * 2)))
    out.alpha_composite(Image.composite(shadow, Image.new("RGBA", (BW, BH), (0, 0, 0, 0)), mask))
    return out

def vertical_water(w, h, ca, cb, kind):
    if kind == "lava":
        ca, cb = (240, 120, 40), (255, 190, 70)
    elif kind == "ice":
        ca, cb = (190, 224, 244), (226, 242, 252)
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
    for i, meta in enumerate(old["maps"]):
        mid = meta["id"]
        flips = [(False, False), (True, False), (False, True), (True, True)]
        m, rng = build_map(mid, meta, flips[i % 4])
        m["_rng"] = rng
        bk = bake(mid, m)
        bk.save(f"{ADIR}/bakes/{mid}.webp", quality=88)
        thumbs(mid, bk, meta["theme"])
        lens = [sum(math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1)) for pts in m["paths"]]
        heads = [(int(p[0][0]), int(p[0][1])) for p in m["paths"]]
        print(f"{mid:16s} paths={len(m['paths'])} doors={heads} mode={m['wave_mode']:6s} "
              f"cells={len(m['road_cells']):3d} len={lens[0]:5.1f} props={len(m['blocked']):2d} heart={m['heart']}")
        del m["_rng"]
        maps.append(m)
    json.dump({"maps": maps}, open(f"{GDIR}/maps.json", "w"), indent=1)
    js = json.dumps({"maps": maps}, separators=(",", ":"))
    with open(f"{GDIR}/maps_data.gd", "w") as f:
        f.write("## GENERATED by tools/v035p3_pop_maps.py - do not edit by hand.\n")
        f.write("## The 30-map truth (THE DOORS LAW), embedded so the export never loses it.\n")
        f.write("class_name PDMapsData\nextends RefCounted\n\nconst DATA := " + js + "\n")
    print("MAPS DONE:", len(maps))

if __name__ == "__main__":
    main()
