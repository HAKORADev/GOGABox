#!/usr/bin/env python3
"""v0.3.5-4 POP SIEGE - THE GRID-PERFECT TRUTH rebuild (the owner's 6-item round).

THE FILLET LAW      : the march line is GRID-PERFECT. Straight runs lie
                     EXACTLY on the cell center lines; every 90-degree turn
                     is a quarter-circle fillet (radius 0.5 cell) that stays
                     INSIDE the corner cell. No more chaikin relaxation that
                     let the curve wander off the painted road - the owner's
                     "the visual pathway is different than the coded one" is
                     dead by construction: paint and march share ONE polyline.
THE BEATEN TRACK    : the bake strokes the march polyline itself with a soft
                     worn center - the road's visual centerline IS the line
                     the bloons ride.
THE CHEVRON TRUTH   : door arrows are stamped ON the march polyline (position
                     AND angle from the local samples) - they sit exactly
                     where the bloons go and point the way they turn.
THE RANDOM DOORS LAW: every multi-door map wears wave_mode "rand" - the game
                     rolls a RANDOM door crew every wave; the crew GROWS with
                     the wave (1 door, then 2, then 3...) and every 5th wave
                     bursts from ALL of them. (The owner: "wave takes 1 door,
                     another takes two, third takes DIFFERENT two, 4th takes 3".)
THE LOOP LAW        : loop-heavy archetypes - the heart ring (the road circles
                     the house before it strikes), the detour loop, the
                     horseshoe, the double loop, deep switchbacks, long S
                     bends, looped twin branches. "Directly pointed to the
                     house" is dead.
THE GROVE LAW       : interiors wear prop GROVES (family clusters), richer
                     decor, and a sensible auto-placed pond - no more vast
                     empty fields.

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

BIG_PROPS = {"tree_round", "tree_round2", "tree_fruit", "tree_green", "tree_pine",
             "pine_a", "pine_b", "tree_pine2", "tree_big", "tree_dead", "deadtree_a",
             "deadtree_b", "tree_frost", "tree_bare", "palm", "palm2", "palm_a",
             "palm_b", "crystal_tree", "umbrella_a", "snowman_a"}

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
    c, r = cells[0]
    if c < 0:
        return "left", r
    if c >= COLS:
        return "right", r
    if r < 0:
        return "top", c
    return "bottom", c

# ---------------------------------------------- THE FILLET LAW (grid-perfect)
def fillet_walk(cells, straight_step=0.5, arc_step=0.12):
    """The grid-perfect march line:
    - every straight run lies EXACTLY on a cell center line (x or y = k + 0.5)
    - every 90-degree turn becomes a quarter-circle fillet, radius 0.5 cell,
      tangent to both center lines, staying INSIDE the corner cell
    - output: dense polyline in cell units (cell centers = k + 0.5)"""
    raw = []
    for p in cells:
        q = (p[0] + 0.5, p[1] + 0.5)
        if not raw or q != raw[-1]:
            raw.append(q)
    if len(raw) < 2:
        return raw
    # corner detection: interior points whose in/out directions differ
    pts = []          # (pos, is_corner)
    pts.append((raw[0], False))
    for i in range(1, len(raw) - 1):
        u = (raw[i][0] - raw[i - 1][0], raw[i][1] - raw[i - 1][1])
        v = (raw[i + 1][0] - raw[i][0], raw[i + 1][1] - raw[i][1])
        pts.append((raw[i], u != v))
    pts.append((raw[-1], False))
    out = [pts[0][0]]
    for i in range(1, len(pts) - 1):
        p, corner = pts[i]
        if not corner:
            # straight run: resample evenly (the movement code interpolates
            # linearly, so this is cosmetic density for the paint stroke)
            a = pts[i - 1][0]
            d = math.dist(a, p)
            n = max(1, int(round(d / straight_step)))
            for k in range(1, n + 1):
                t = k / float(n)
                out.append((a[0] + (p[0] - a[0]) * t, a[1] + (p[1] - a[1]) * t))
            continue
        # THE FILLET: quarter arc, radius 0.5, tangent to both legs
        pu, pv = pts[i - 1][0], pts[i + 1][0]
        ul = math.dist(pu, p) or 1.0
        vl = math.dist(p, pv) or 1.0
        u = ((p[0] - pu[0]) / ul, (p[1] - pu[1]) / ul)
        v = ((pv[0] - p[0]) / vl, (pv[1] - p[1]) / vl)
        r = 0.5
        e = (p[0] - u[0] * r, p[1] - u[1] * r)          # tangent point on the in-leg
        c = (e[0] + v[0] * r, e[1] + v[1] * r)          # arc center
        a0 = math.atan2(e[1] - c[1], e[0] - c[0])
        x = (p[0] + v[0] * r, p[1] + v[1] * r)          # tangent point on the out-leg
        a1 = math.atan2(x[1] - c[1], x[0] - c[0])
        # the short way round (a quarter)
        da = a1 - a0
        while da > math.pi:
            da -= 2 * math.pi
        while da < -math.pi:
            da += 2 * math.pi
        n = max(3, int(round(abs(da) * r / arc_step)))
        # straight from the previous point to the arc entry
        a_prev = out[-1]
        d = math.dist(a_prev, e)
        ns = max(1, int(round(d / straight_step)))
        for k in range(1, ns + 1):
            t = k / float(ns)
            out.append((a_prev[0] + (e[0] - a_prev[0]) * t, a_prev[1] + (e[1] - a_prev[1]) * t))
        for k in range(1, n + 1):
            a = a0 + da * k / float(n)
            out.append((c[0] + math.cos(a) * r, c[1] + math.sin(a) * r))
        out.append(x)
    # the tail run
    tail_from = out[-1]
    tail_to = pts[-1][0]
    d = math.dist(tail_from, tail_to)
    n = max(1, int(round(d / straight_step)))
    for k in range(1, n + 1):
        t = k / float(n)
        out.append((tail_from[0] + (tail_to[0] - tail_from[0]) * t,
                    tail_from[1] + (tail_to[1] - tail_from[1]) * t))
    # THE CLEAN LINE: no zero-length segments (the march cache hates dupes)
    clean = [out[0]]
    for p in out[1:]:
        if math.dist(p, clean[-1]) > 0.004:
            clean.append(p)
    return clean

# ------------------------------------------------------------ archetypes
def ring_cells(cx, cy, rad):
    """the clockwise perimeter of the box [cx-rad..cx+rad] x [cy-rad..cy+rad]."""
    return ([(c, cy - rad) for c in range(cx - rad, cx + rad + 1)] +
            [(cx + rad, r) for r in range(cy - rad + 1, cy + rad + 1)] +
            [(c, cy + rad) for c in range(cx + rad - 1, cx - rad - 1, -1)] +
            [(cx - rad, r) for r in range(cy + rad - 1, cy - rad, -1)])

def fill_gaps(cells):
    """THE UNIT-STEP LAW: every consecutive pair becomes an orthogonal walk
    (no jumps, no diagonals - the fillet walk can trust the cells)."""
    out = [tuple(cells[0])]
    for nxt in cells[1:]:
        out += lwalk([out[-1], tuple(nxt)])[1:]
    return out

def arch_heart_ring(rng, variant=0):
    """THE HEART RING: the road circles the house once before it strikes."""
    hx, hy = (13, 4) if variant == 0 else (12, 5)
    ring = ring_cells(hx, hy, 2)                       # 16 cells around the heart
    r0 = hy - 2
    pre = lwalk([(0, r0), (hx - 3, r0)])
    cells = pre + [(hx - 2, r0)] + ring                # the ring starts AT the entry
    # the driveway: from the ring's end straight into the heart
    cells += lwalk([cells[-1], (hx - 1, hy - 1), (hx - 1, hy), (hx, hy)])
    return [door(cells, "left", r0)], (hx, hy), "solo"

def arch_detour_loop(rng, variant=0):
    """a honest run that detours into a FULL loop midway, then onward.
    The exit leaves the ring's bottom row DOWNWARD (never backwards)."""
    r0 = rng.choice([1, 2])
    lc = rng.choice([6, 7])
    lr, rad = 5, 2
    anchors = [(0, r0), (lc - rad, r0), (lc - rad, lr - rad)]
    loop = ring_cells(lc, lr, rad)                     # clockwise from the top-left
    cells = lwalk(anchors) + loop[:11]                 # 3/4 around, stop on the bottom row
    ex = loop[10][0]                                   # the bottom-row exit column
    cells += lwalk([cells[-1], (ex, ROWS - 1), (15, ROWS - 1), (15, lr), (17, lr)])
    return [door(cells, "left", r0)], (17, lr), "solo"

def arch_horseshoe(rng, variant=0):
    """enter one side, sweep the WHOLE board, come back to a heart near home."""
    r_top, r_bot = (1, 8) if variant == 0 else (2, 7)
    hx = rng.choice([2, 3])
    hy = 4 if variant == 0 else 5
    cells = lwalk([(0, r_top), (15, r_top), (15, r_bot), (hx, r_bot), (hx, hy)])
    return [door(cells, "left", r_top)], (hx, hy), "solo"

def arch_double_loop(rng, variant=0):
    """two stacked loops joined by a neck, then the heart."""
    if variant == 0:
        a = ring_cells(6, 3, 2)
        b = ring_cells(11, 6, 2)
        neck = lwalk([a[-1], (6, 5), (9, 5)])
        cells = a + neck + b
        cells += lwalk([b[-1], (15, 6), (17, 6)])
        heart = (17, 6)
    else:
        a = ring_cells(5, 6, 2)
        b = ring_cells(11, 3, 2)
        neck = lwalk([a[-1], (5, 4), (8, 4)])
        cells = a + neck + b
        cells += lwalk([b[-1], (15, 3), (17, 3)])
        heart = (17, 3)
    return [door(cells, "left", cells[0][1])], heart, "solo"

def arch_switchback(rng, variant=0):
    """deep zigzag with LONG runs - the board is used edge to edge."""
    rows = [1, 3, 5, 7, 9] if variant == 0 else [8, 6, 4, 2, 0]
    cols = [0, 13, 4, 14, 4, 16]
    anchors = [(cols[0], rows[0])]
    for i in range(1, len(rows)):
        anchors.append((cols[i], rows[i - 1]))
        anchors.append((cols[i], rows[i]))
    cells = lwalk(anchors)
    heart = (17, rows[-1]) if cols[-1] + 1 <= 17 else (cells[-1][0], cells[-1][1])
    if cells[-1][0] < 17:
        cells += lwalk([cells[-1], (17, rows[-1])])
    heart = (17, rows[-1])
    return [door(cells, "left", rows[0])], heart, "solo"

def arch_s_long(rng, variant=0):
    """three big bends, long elegant straights."""
    if variant == 0:
        anchors = [(0, 2), (12, 2), (12, 5), (5, 5), (5, 8), (17, 8)]
    else:
        anchors = [(0, 7), (12, 7), (12, 4), (5, 4), (5, 1), (17, 1)]
    cells = lwalk(anchors)
    return [door(cells, "left", cells[0][1])], (17, cells[-1][1]), "solo"

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
    """THE 3-DOOR HIGHWAY: three SEPARATE doors (left), each lane its own
    winding road with a loop kink, all merging at the ONE heart door."""
    rows_in = [1, 4, 7]
    paths = []
    for k, r0 in enumerate(rows_in):
        mid = 9 + k
        anchors = [(0, r0), (3 + k, r0), (3 + k, r0 + (2 if k != 1 else -1)),
                   (7, r0 + (2 if k != 1 else -1)), (7, 5), (10, 5),
                   (13, 5 + (k - 1)), (16, 5)]
        cells = lwalk(anchors)
        if cells[-1] != (17, 5):
            cells += lwalk([cells[-1], (17, 5)])
        paths.append(door(cells, "left", r0))
    return paths, (17, 5), "rand"

def arch_twin(rng):
    """two doors; each branch wears its own full loop before the merge.
    The bot branch is the top's mirror - its ring exits WITH the march."""
    merge_c = rng.randrange(9, 11)
    row_mid = 5
    shared = lwalk([(merge_c, row_mid), (merge_c + 3, row_mid),
                    (merge_c + 6, row_mid + (2 if rng.random() < 0.5 else -2)),
                    (17, row_mid + 1)])
    top_ring = ring_cells(4, 2, 1)                     # starts (3,1) - the run joins smooth
    top = door(lwalk([(0, 1), (3, 1)]) + top_ring +
               lwalk([top_ring[-1], (merge_c, 2), (merge_c, row_mid)]) + shared, "left", 1)
    bot_ring = [(3, 8), (4, 8), (5, 8), (5, 7), (5, 6), (4, 6), (3, 6), (3, 7)]
    bot = door(lwalk([(0, 8), (3, 8)]) + bot_ring +
               lwalk([bot_ring[-1], (merge_c, 7), (merge_c, row_mid)]) + shared,
               "left", 8)
    return [top, bot], (17, row_mid + 1), "rand"

def arch_twin_ud(rng):
    """two doors from TOP + BOTTOM; each branch loops before the merge."""
    vc = rng.randrange(3, 5)
    merge_r = 5
    shared = lwalk([(vc + 2, merge_r), (10, merge_r), (13, 3), (17, 4)])
    top_ring0 = ring_cells(vc, 2, 1)                   # rotate to start at (vc,1)
    top_ring = top_ring0[1:] + top_ring0[:1]
    top = door([(vc, 0)] + top_ring[:7] +
               lwalk([top_ring[6], (vc + 2, 2), (vc + 2, merge_r)]) + shared, "top", vc)
    bot_ring0 = ring_cells(vc + 5, 7, 1)               # rotate to start at (vc+5,8)
    bot_ring = bot_ring0[5:] + bot_ring0[:5]
    bot = door([(vc + 5, ROWS - 1)] + bot_ring[:7] +
               lwalk([bot_ring[6], (vc + 2, 7), (vc + 2, merge_r)]) + shared,
               "bottom", vc + 5)
    return [top, bot], (17, 4), "rand"

def arch_split(rng, branches=2):
    """THE CLAW / TRIDENT: SEPARATE doors on the left edge, each road wears
    its own loop, then all the claws merge for the shared finish."""
    mid_r = rng.choice([4, 5])
    ec = rng.randrange(11, 13)
    door_rows = [1, 8] if branches == 2 else [1, 4, 8]
    paths = []
    for k, dr in enumerate(door_rows):
        ring = ring_cells(5 + 2 * k, dr, 1)
        cells = lwalk([(0, dr), (ring[0][0] - 1, dr)]) + ring
        cells += lwalk([ring[-1], (ec, mid_r), (17, mid_r)])
        paths.append(door(fill_gaps(cells), "left", dr))
    return paths, (17, mid_r), "rand"

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
    vc = rng.randrange(11, 13)
    heart = (vc, hr)
    hpath = door(lwalk([(0, hr), (4, hr), (4, hr - 2 if hr >= 2 else hr + 2),
                        (8, hr - 2 if hr >= 2 else hr + 2), (8, hr), (vc, hr)]), "left", hr)
    top = door(lwalk([(vc, 0), (vc - 3, 1), (vc - 3, 2), (vc, 2), (vc, hr)]), "top", vc)
    bot = door(lwalk([(vc, ROWS - 1), (vc + 2, 8), (vc + 2, 7), (vc, 7), (vc, hr)]), "bottom", vc)
    return [hpath, top, bot], heart, "rand"

def arch_fortress(rng):
    """THREE winding doors converge on a central heart (the last siege)."""
    heart = (9, 4)
    a = lwalk([(0, 1), (3, 1), (3, 3), (6, 3), (6, 5), (8, 5), (9, 4)])
    b = lwalk([(0, 8), (3, 8), (3, 6), (6, 6), (6, 4), (8, 4), (9, 4)])
    c = lwalk([(17, 5), (13, 5), (13, 3), (11, 3), (11, 4), (9, 4)])
    return [door(a, "left", 1), door(b, "left", 8), door(c, "right", 5)], heart, "rand"

ARCH = {
    "first_bloom":   ("detour_loop", 0), "sunny_loop":    ("heart_ring", 0),
    "twin_bloom":    ("twin", 0),        "pine_twist":     ("s_long", 0),
    "stump_waltz":   ("switchback", 0),  "owl_spiral":     ("spiral", 0),
    "dune_run":      ("horseshoe", 0),   "scarab_s":       ("s_long", 1),
    "mirage_x":      ("cross", 0),       "frostbite":      ("split", 2),
    "snowman_march": ("switchback", 1),  "aurora_twin":    ("twin_ud", 0),
    "boardwalk":     ("highway3", 0),    "tide_zig":       ("comb", 1),
    "crab_claw":     ("split", 2),       "murk_marsh":     ("detour_loop", 1),
    "frog_heart":    ("heart_ring", 1),  "serpent_nile":   ("snake", 0),
    "ash_ridge":     ("switchback", 0),  "magma_cross":    ("cross", 0),
    "obsidian_loop": ("double_loop", 0), "sugar_rush":     ("split", 3),
    "laby_lick":     ("comb", 0),        "gumdrop_spiral": ("spiral", 0),
    "old_ground":    ("horseshoe", 1),   "wailing_twin":   ("twin", 0),
    "bone_spiral":   ("spiral", 0),      "glow_grotto":    ("highway3", 0),
    "rune_heart":    ("cross", 0),       "the_last_siege": ("fortress", 0),
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
WATER_THEMES = {"meadow", "forest", "beach", "swamp", "snow", "volcano", "candy"}
NIGHT_TINT = {
    "meadow": (76, 88, 132), "forest": (66, 82, 128), "desert": (82, 78, 128),
    "snow": (92, 102, 158), "beach": (76, 82, 140), "swamp": (71, 87, 112),
    "volcano": (107, 71, 71), "candy": (102, 82, 132), "graveyard": (76, 82, 122),
    "crystal": (97, 97, 158),
}
PROP_POOL = {
    "meadow":   ["tree_round", "tree_round2", "tree_fruit", "tree_green", "bush", "bush_a",
                 "bush_b", "flowers", "flowers_a", "flowers_b", "stones", "tree_pine", "fern", "pebbles"],
    "forest":   ["tree_pine", "pine_a", "pine_b", "tree_pine2", "tree_round", "tree_big",
                 "tree_green", "stump", "stump_a", "bush2", "log", "fern", "mushrooms"],
    "desert":   ["cactus", "cactus_a", "cactus_b", "dunerock", "rocks", "rocks2", "tree_dead",
                 "tree_bare", "skull", "bones", "bones_a", "pebbles"],
    "snow":     ["tree_frost", "tree_pine", "icerock_a", "icicle", "snowman_a", "snowtuft",
                 "rocks", "stump", "tuft"],
    "beach":    ["palm", "palm2", "palm_a", "palm_b", "umbrella_a", "shell_a", "starfish",
                 "log", "rocks2", "tuft"],
    "swamp":    ["tree_dead", "deadtree_a", "deadtree_b", "shroom_a", "shroom_b", "shroom_trio",
                 "lilypad", "reed_a", "reed_trio", "tuft", "branch", "bush"],
    "volcano":  ["lavarock_a", "lavarock_b", "ember_rock", "obsidian_shard", "vent_a", "rocks",
                 "rocks2", "tree_dead", "branch", "stones"],
    "candy":    ["lolly_a", "lolly_b", "gummy_a", "candy_bit", "sprinkle_dot", "mushrooms",
                 "mushroom", "pumpkin", "bush2", "flowers"],
    "graveyard": ["grave_a", "grave_b", "tomb_a", "tombstone", "tree_dead", "deadfence_h",
                  "bones", "skull", "skull_pile", "skull_rock", "tree_bare"],
    "crystal":  ["crystal_tree", "crystal_a", "crystal_b", "stalag_a", "glowshroom", "rune_dot",
                 "rocks", "mushroom", "stones"],
}
DECOR_POOL = {
    "meadow":   ["flowers", "flowers_a", "flowers_b", "tuft", "fern", "grass_d", "bush2", "pebbles"],
    "forest":   ["mushroom", "tuft", "fern", "grass_d", "flowers"],
    "desert":   ["tuft", "bones", "pebbles", "rocks2"],
    "snow":     ["snowtuft", "tuft", "icicle", "rocks"],
    "beach":    ["shell_a", "starfish", "tuft", "rocks2"],
    "swamp":    ["reed_a", "reed_trio", "lilypad", "tuft", "mushroom"],
    "volcano":  ["branch", "ember_rock", "obsidian_shard", "rocks2"],
    "candy":    ["sprinkle_dot", "candy_bit", "flowers", "mushroom"],
    "graveyard": ["bones", "tuft", "rune_dot"],
    "crystal":  ["rune_dot", "glowshroom", "tuft", "stalag_a"],
}

def hexc(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))

def prop_img(name):
    p = f"{PROPS}/{name}.png"
    return Image.open(p).convert("RGBA") if os.path.exists(p) else None

# ---------------------------------------------------------------- build
def build_map(mid, meta, flip):
    rng = random.Random(mid + "v4")
    kind, variant = ARCH[mid]
    fn = {"heart_ring": lambda: arch_heart_ring(rng, variant),
          "detour_loop": lambda: arch_detour_loop(rng, variant),
          "horseshoe": lambda: arch_horseshoe(rng, variant),
          "double_loop": lambda: arch_double_loop(rng, variant),
          "switchback": lambda: arch_switchback(rng, variant),
          "s_long": lambda: arch_s_long(rng, variant),
          "snake": lambda: arch_snake(rng, variant),
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
    paths_c = [fill_gaps(p) for p in paths_c]
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
    # THE FILLET LAW: one grid-perfect polyline per path - the paint AND the
    # march consume THESE points, so they can never disagree again
    paths = [fillet_walk(p) for p in paths_c]
    # the road truth: every cell the cell-walk AND the fillet polyline touch
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
    # water: ONE auto-placed pond on the freest big area (theme decides kind)
    water = []
    if meta["theme"] in WATER_THEMES:
        free_probe = [(c, r) for c in range(2, COLS - 2) for r in range(2, ROWS - 2)
                      if (c, r) not in road and (c, r) != heart
                      and all((c + dc, r + dr) not in road for dc in (-1, 0, 1) for dr in (-1, 0, 1))]
        if free_probe:
            best, best_d = None, -1.0
            for (c, r) in free_probe:
                dmin = min(math.hypot(c - rc, r - rr) for p in paths_c for (rc, rr) in p
                           if 0 <= rc < COLS and 0 <= rr < ROWS)
                if dmin > best_d:
                    best_d, best = dmin, (c, r)
            if best is not None and best_d >= 1.6:
                cx, cy = best[0] + 0.5, best[1] + 0.5
                rx = rng.uniform(1.3, 1.8)
                ry = rng.uniform(1.0, 1.4)
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
    # THE GROVE LAW: family clusters instead of uniform scatter
    blocked = []
    occ = set()
    grove_centers = []
    grove_cells = {}
    grove_target = 4 if len(free) > 40 else 3
    far_free = [(c, r) for (c, r) in free
                if all(math.hypot(c - gc[0], r - gc[1]) >= 3.0 for gc in grove_centers)]
    rng.shuffle(far_free)
    for (c, r) in far_free:
        if len(grove_centers) >= grove_target:
            break
        if any(abs(c - gc[0]) <= 3 and abs(r - gc[1]) <= 3 for gc in grove_centers):
            continue
        grove_centers.append((c, r))
    for gi, (gc, gr) in enumerate(grove_centers):
        fam = rng.sample(pool, k=min(4, len(pool)))
        cells_g = []
        for dc in range(-1, 2):
            for dr in range(-1, 2):
                q = (gc + dc, gr + dr)
                if q in road or q in wset or q == heart or q in corridors or q in occ:
                    continue
                if not (0 <= q[0] < COLS and 0 <= q[1] < ROWS):
                    continue
                if rng.random() < 0.62:
                    cells_g.append(q)
        grove_cells[gi] = (fam, cells_g)
    used_grove = set()
    for gi, (fam, cells_g) in grove_cells.items():
        for q in cells_g:
            if q in used_grove or q in occ:
                continue
            # THE WORLD SORT LAW: no BIG prop near a door corridor
            name = rng.choice(fam)
            if name in BIG_PROPS:
                near_door = any(abs(q[0] - dc) <= 2 and abs(q[1] - dr) <= 2 for (dc, dr) in corridors)
                if near_door:
                    small = [p for p in fam if p not in BIG_PROPS]
                    if small:
                        name = rng.choice(small)
            blocked.append([q[0], q[1], name])
            occ.add(q)
            used_grove.add(q)
    # the scatter fill (the rest of the free land, lighter)
    target = min(56, int(len(free) * rng.uniform(0.14, 0.2)))
    for (c, r) in free:
        if len(blocked) >= len(used_grove) + target:
            break
        if (c, r) in occ:
            continue
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
    m.pop("dual", None)
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

def chevron_at(d, x, y, ang, size=15):
    for sgn in (1, -1):
        wing = ang + math.pi * 0.72 * sgn
        wx, wy = x + math.cos(wing) * size, y + math.sin(wing) * size
        d.line([wx, wy, x, y], fill=(74, 50, 26, 150), width=7)
        d.line([wx, wy, x, y], fill=(255, 244, 210, 240), width=4)

## THE CHEVRON TRUTH: arrows stamped ON the march polyline - position AND
## angle come from the local samples, so they sit exactly where the bloons
## ride and point the way the road actually bends.
def door_marks(d, pts, rwear, BAKS):
    onb_i = next((i for i, (x, y) in enumerate(pts)
                  if -0.01 <= x <= COLS and -0.01 <= y <= ROWS and i + 1 < len(pts)), None)
    if onb_i is None or onb_i < 1:
        return
    # the worn approach strip: ALONG the polyline, from off-board into the map
    strip_pts = [(x * BAKS, y * BAKS) for (x, y) in pts[max(0, onb_i - 6):min(len(pts), onb_i + 3)]]
    d.line(strip_pts, fill=rwear + (110,), width=int(BAK * 0.62))
    # chevrons at the first on-board samples, oriented by local direction
    marks = [onb_i]
    dist_acc = 0.0
    i = onb_i
    while i < len(pts) - 1 and len(marks) < 3:
        dist_acc += math.dist(pts[i], pts[i + 1])
        if dist_acc >= 0.62:
            marks.append(i + 1)
            dist_acc = 0.0
        i += 1
    for mi in marks:
        x, y = pts[mi]
        j = min(mi + 1, len(pts) - 1)
        k = max(mi - 1, 0)
        ang = math.atan2(pts[j][1] - pts[k][1], pts[j][0] - pts[k][0])
        chevron_at(d, x * BAKS, y * BAKS, ang)

def stroke_polyline(d, pts, color, width, BAKS):
    """the beaten track: a soft stroke exactly along the march line."""
    px = [(x * BAKS, y * BAKS) for (x, y) in pts]
    if len(px) < 2:
        return
    d.line(px, fill=color, width=width)
    rr = width // 2
    for (x, y) in px:
        d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=color)

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
    d = ImageDraw.Draw(im, "RGBA")
    sp1, sp2 = hexc(specks[0]), hexc(specks[1])
    for _ in range(int(COLS * ROWS * 2.6)):
        x, y = rng.randrange(BW), rng.randrange(BH)
        rr = rng.choice((1, 1, 2, 2, 3))
        col = sp1 if rng.random() < 0.6 else sp2
        d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=col + (255,))
    # water: banks first, then the gradient body, sparkle
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
    # THE BEATEN TRACK: a soft darker stroke EXACTLY along the march line -
    # the road's visual centerline is the line the bloons ride
    track = tuple(max(0, v - 16) for v in road)
    for pts in m["paths"]:
        stroke_polyline(ssd, pts, track + (54,), int(BAK * 0.26 * SS), cs)
        # wear dashes ride the same line
        px = [(x * cs, y * cs) for (x, y) in pts]
        for i in range(0, len(px) - 1, 4):
            if rng.random() < 0.5:
                ssd.line([px[i], px[i + 1]], fill=rwear + (130,), width=4 * SS)
    im = ss_im.resize((BW, BH), Image.LANCZOS)
    d = ImageDraw.Draw(im, "RGBA")
    # road speckles + pebbles (kept OFF the beaten track's middle)
    for _ in range(150):
        c, r = rng.choice(m["road_cells"])
        x = rng.uniform(c * BAK + 8, (c + 1) * BAK - 8)
        y = rng.uniform(r * BAK + 8, (r + 1) * BAK - 8)
        rr = rng.choice((1, 2))
        d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=redge + (160,))
    for _ in range(24):
        c, r = rng.choice(m["road_cells"])
        x = rng.uniform(c * BAK + 10, (c + 1) * BAK - 10)
        y = rng.uniform(r * BAK + 10, (r + 1) * BAK - 10)
        rr = rng.uniform(2.0, 3.6)
        peb = tuple(min(255, v + 34) for v in road)
        d.ellipse([x - rr, y - rr * 0.8, x + rr, y + rr * 0.8], fill=peb + (170,))
    # THE CHEVRON TRUTH at every door
    for pts in m["paths"]:
        door_marks(d, pts, rwear, BAK)
    # grass/pebble shoulders hugging the road
    dec = DECOR_POOL[theme]
    occ = {(c, r) for (c, r, _) in m["blocked"]} | {(c, r) for (c, r) in m["water"]} | roadset | {(m["heart"][0], m["heart"][1])}
    shoulder = []
    for (c, r) in sorted(roadset):
        for q in [(c - 1, r), (c + 1, r), (c, r - 1), (c, r + 1)]:
            if q not in roadset and q not in occ and 0 <= q[0] < COLS and 0 <= q[1] < ROWS:
                shoulder.append(q)
    rng.shuffle(shoulder)
    for (c, r) in shoulder[:34]:
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
    while placed < 30 and tries < 380:
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
    # the vignette
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
        print(f"{mid:16s} paths={len(m['paths'])} doors={heads} mode={m['wave_mode']:4s} "
              f"cells={len(m['road_cells']):3d} len={lens[0]:5.1f} props={len(m['blocked']):2d} heart={m['heart']}")
        del m["_rng"]
        maps.append(m)
    json.dump({"maps": maps}, open(f"{GDIR}/maps.json", "w"), indent=1)
    js = json.dumps({"maps": maps}, separators=(",", ":"))
    with open(f"{GDIR}/maps_data.gd", "w") as f:
        f.write("## GENERATED by tools/v035p4_pop_maps.py - do not edit by hand.\n")
        f.write("## The 30-map truth (THE FILLET LAW + THE RANDOM DOORS LAW), embedded so the export never loses it.\n")
        f.write("class_name PDMapsData\nextends RefCounted\n\nconst DATA := " + js + "\n")
    print("MAPS DONE:", len(maps))

if __name__ == "__main__":
    main()
