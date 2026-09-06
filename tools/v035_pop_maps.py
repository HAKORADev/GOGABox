#!/usr/bin/env python3
"""v0.3.5 POP SIEGE - the 30-map designer.
Writes game/games/pop_siege/maps.json: grid 18x10, waypoint paths (cell coords),
blocked prop cells, decor scatter, water/lava cells, prices, stars.
Deterministic (seeded per map id) -> the art thumbs and the game read ONE truth.
"""
import json, math, os, random

COLS, ROWS = 18, 10
OUT = "/home/z/my-project/repo/GOGABox/projects/gogabox/game/games/pop_siege/maps.json"

# ---------------------------------------------------------------- move specs
# each map: moves from the spawn edge; R/L/U/D = steps of one cell.
# a path = list of (col,row) waypoints; the heart sits at the last cell.
SPECS = [
    # --- meadow ---
    ("first_bloom", "First Bloom", "meadow", 1, 0,
     [("R", 6), ("D", 3), ("R", 5), ("U", 2), ("R", 5)], 0),
    ("sunny_loop", "Sunny Loop", "meadow", 1, 250,
     [("R", 12), ("D", 6), ("L", 10), ("U", 4), ("R", 6)], 0),
    ("twin_bloom", "Twin Bloom", "meadow", 2, 250,
     [[("R", 7), ("D", 3), ("R", 4), ("D", 3), ("R", 5)],
      [("R", 7), ("U", 2), ("R", 4), ("D", 4), ("R", 5)]], 1),
    # --- forest ---
    ("pine_twist", "Pine Twist", "forest", 1, 0,
     [("R", 5), ("U", 2), ("R", 4), ("D", 3), ("R", 4), ("U", 2), ("R", 3)], 0),
    ("stump_waltz", "Stump Waltz", "forest", 1, 300,
     [("R", 4), ("D", 4), ("R", 3), ("U", 3), ("R", 3), ("D", 4), ("R", 6)], 0),
    ("owl_spiral", "Owl Spiral", "forest", 2, 350,
     [("R", 14), ("D", 8), ("L", 12), ("U", 6), ("R", 9), ("D", 4), ("L", 5), ("D", 1)], 0),
    # --- desert ---
    ("dune_run", "Dune Run", "desert", 1, 0,
     [("R", 7), ("D", 2), ("R", 4), ("D", 2), ("R", 5), ("U", 1)], 0),
    ("scarab_s", "Scarab S", "desert", 2, 300,
     [("R", 16), ("D", 3), ("L", 13), ("D", 3), ("R", 15)], 0),
    ("mirage_x", "Mirage X", "desert", 3, 500,
     [[("R", 5), ("D", 2), ("R", 3), ("D", 2), ("R", 3), ("U", 2), ("R", 3), ("D", 2), ("R", 3)],
      [("R", 5), ("U", 2), ("R", 3), ("U", 2), ("R", 3), ("D", 2), ("R", 3), ("U", 2), ("R", 3)]], 1),
    # --- snow ---
    ("frostbite", "Frostbite", "snow", 2, 350,
     [("R", 5), ("D", 3), ("R", 5), ("U", 4), ("R", 6), ("D", 2)], 0),
    ("snowman_march", "Snowman March", "snow", 2, 350,
     [("R", 8), ("U", 3), ("R", 3), ("D", 5), ("R", 5), ("U", 3), ("R", 2)], 0),
    ("aurora_twin", "Aurora Twin", "snow", 3, 550,
     [[("D", 2), ("R", 6), ("D", 3), ("R", 6), ("D", 2), ("R", 4)],
      [("D", 6), ("R", 6), ("U", 3), ("R", 6), ("U", 2), ("R", 4)]], 1),
    # --- beach ---
    ("boardwalk", "Boardwalk", "beach", 1, 300,
     [("R", 15), ("D", 6), ("L", 9), ("D", 2), ("L", 4)], 0),
    ("tide_zig", "Tide Zig", "beach", 2, 400,
     [("R", 4), ("D", 2), ("R", 4), ("U", 2), ("R", 4), ("D", 2), ("R", 4), ("U", 2), ("R", 2)], 0),
    ("crab_claw", "Crab Claw", "beach", 3, 500,
     [[("R", 6), ("D", 4), ("R", 6), ("U", 3), ("R", 4)],
      [("R", 6), ("U", 1), ("R", 6), ("D", 2), ("R", 4)]], 1),
    # --- swamp ---
    ("murk_marsh", "Murk Marsh", "swamp", 2, 400,
     [("R", 6), ("D", 2), ("L", 3), ("D", 3), ("R", 8), ("D", 2), ("R", 5)], 2),
    ("frog_heart", "Frog Heart", "swamp", 2, 400,
     [("R", 5), ("D", 4), ("R", 3), ("U", 3), ("R", 3), ("D", 3), ("R", 5)], 2),
    ("serpent_nile", "Serpent Nile", "swamp", 3, 600,
     [("R", 16), ("D", 2), ("L", 14), ("D", 2), ("R", 14), ("D", 2), ("L", 8), ("D", 2)], 2),
    # --- volcano ---
    ("ash_ridge", "Ash Ridge", "volcano", 2, 450,
     [("R", 5), ("U", 3), ("R", 4), ("D", 5), ("R", 4), ("U", 2), ("R", 3)], 3),
    ("magma_cross", "Magma Cross", "volcano", 3, 650,
     [[("R", 9), ("D", 2), ("R", 7), ("U", 4), ("L", 4), ("U", 2), ("L", 3), ("D", 4), ("L", 1)],
      [("R", 9), ("U", 3), ("R", 7), ("D", 6), ("R", 2)]], 3),
    ("obsidian_loop", "Obsidian Loop", "volcano", 3, 650,
     [("R", 13), ("D", 7), ("L", 11), ("U", 5), ("R", 8), ("D", 3), ("L", 4), ("D", 1)], 3),
    # --- candy ---
    ("sugar_rush", "Sugar Rush", "candy", 1, 350,
     [("R", 6), ("U", 2), ("R", 4), ("D", 4), ("R", 6)], 0),
    ("laby_lick", "Labyrinth Lick", "candy", 2, 450,
     [("R", 4), ("D", 3), ("R", 3), ("U", 2), ("R", 3), ("D", 3), ("R", 3), ("U", 2), ("R", 3), ("D", 2)], 0),
    ("gumdrop_spiral", "Gumdrop Spiral", "candy", 3, 600,
     [("D", 7), ("R", 14), ("U", 6), ("L", 10), ("D", 4), ("R", 7), ("U", 2), ("L", 3), ("D", 1)], 0),
    # --- graveyard ---
    ("old_ground", "Old Ground", "graveyard", 2, 450,
     [("R", 7), ("D", 4), ("L", 4), ("D", 3), ("R", 10), ("U", 1)], 0),
    ("wailing_twin", "Wailing Twin", "graveyard", 3, 600,
     [[("R", 6), ("D", 1), ("R", 4), ("D", 4), ("R", 6)],
      [("R", 6), ("U", 2), ("R", 4), ("D", 5), ("R", 6)]], 0),
    ("bone_spiral", "Bone Spiral", "graveyard", 3, 700,
     [("R", 15), ("D", 8), ("L", 13), ("U", 6), ("R", 10), ("D", 4), ("L", 6), ("D", 2)], 0),
    # --- crystal ---
    ("glow_grotto", "Glow Grotto", "crystal", 3, 700,
     [("R", 5), ("D", 2), ("R", 4), ("U", 3), ("R", 3), ("D", 4), ("R", 4), ("U", 2)], 0),
    ("rune_heart", "Rune Heart", "crystal", 3, 800,
     [("R", 6), ("D", 3), ("L", 3), ("D", 3), ("R", 6), ("U", 3), ("L", 3), ("U", 3), ("R", 8), ("U", 1)], 0),
    ("the_last_siege", "The Last Siege", "crystal", 3, 900,
     [[("R", 6), ("D", 2), ("R", 5), ("U", 1), ("R", 5), ("D", 3), ("R", 2)],
      [("R", 6), ("U", 2), ("R", 5), ("D", 1), ("R", 5), ("U", 3), ("R", 2)]], 0),
]

THEME_PROPS = {
    "meadow":    (["tree_green", "bush_a", "bush_b", "fence_h"], ["flowers_a", "flowers_b", "tuft"]),
    "forest":    (["pine_a", "pine_b", "stump_a", "shroom_trio"], ["shroom_a", "tuft", "fern"]),
    "desert":    (["cactus_a", "cactus_b", "skull_rock", "dunerock"], ["bones_a", "pebbles"]),
    "snow":      (["tree_bare", "snowman_a", "icerock_a"], ["snowtuft", "icicle"]),
    "beach":     (["palm_a", "palm_b", "umbrella_a"], ["shell_a", "starfish", "pebbles"]),
    "swamp":     (["deadtree_a", "deadtree_b", "reed_trio"], ["lilypad", "reed_a", "shroom_b"]),
    "volcano":   (["lavarock_a", "lavarock_b", "vent_a"], ["ember_rock", "obsidian_shard"]),
    "candy":     (["lolly_a", "lolly_b", "gummy_a", "cane_a"], ["sprinkle_dot", "candy_bit"]),
    "graveyard": (["grave_a", "tomb_a", "deadfence_h", "deadtree_b"], ["skull_pile", "grass_d"]),
    "crystal":   (["crystal_a", "crystal_b", "stalag_a"], ["glowshroom", "rune_dot"]),
}
THEME_WATER = {"swamp": "water", "beach": "water", "volcano": "lava", "crystal": "water"}

def build_path(entry_row, moves):
    """walk the moves from the left edge -> waypoints; the spawn cell [-1,row] leads."""
    pts, c, r = [], -1, entry_row
    pts.append([c, r])
    for d, n in moves:
        for _ in range(n):
            if d == "R": c += 1
            elif d == "L": c -= 1
            elif d == "D": r += 1
            elif d == "U": r -= 1
            if pts and pts[-1] == [c, r]:
                continue
            pts.append([c, r])
    return pts

def cells_on_path(pts):
    """every cell the polyline touches (half-up rounding - it must match
    the game's roundi exactly, or a prop lands on a .5 road cell)."""
    occ = set()
    for i in range(len(pts) - 1):
        x0, y0 = pts[i]; x1, y1 = pts[i + 1]
        steps = max(abs(x1 - x0), abs(y1 - y0))
        for s in range(steps + 1):
            t = s / max(1, steps)
            occ.add((math.floor(x0 + (x1 - x0) * t + 0.5), math.floor(y0 + (y1 - y0) * t + 0.5)))
    return occ

def main():
    maps = []
    for idx, (mid, name, theme, stars, price, spec, dual) in enumerate(SPECS):
        rng = random.Random("pop_siege_" + mid)
        if isinstance(spec[0][0], str):
            net_down = sum(n for d, n in spec if d == "D") - sum(n for d, n in spec if d == "U")
            room = (ROWS - 1) - net_down
            entry = rng.randint(0, max(0, room)) if room > 0 else 0
            paths = [build_path(entry, spec)]
        else:
            top = 1 if idx % 3 == 0 else 2
            paths = [build_path(top, spec[0]), build_path(ROWS - 3, spec[1])]
        # sanitize: clamp in bounds
        for p in paths:
            for pt in p:
                pt[0] = max(-1, min(COLS, pt[0]))
                pt[1] = max(0, min(ROWS - 1, pt[1]))
        # the heart: force all paths to END at the same right-side cell FIRST
        heart_col, heart_row = COLS - 1, paths[0][-1][1]
        for p in paths:
            p[-1] = [heart_col, heart_row]
        # THEN compute the final road (the props exclude the truth)
        road = set()
        for p in paths:
            road |= cells_on_path(p)
        road.add((heart_col, heart_row))
        # (props are placed AFTER this point - the road set is final now)
        # water clusters (theme flavor)
        water = []
        wkind = THEME_WATER.get(theme)
        if wkind:
            for _ in range(2 if stars < 3 else 3):
                wc, wr = rng.randint(2, COLS - 4), rng.randint(1, ROWS - 3)
                for dc, dr in [(0, 0), (1, 0), (0, 1), (1, 1), (2, 0)]:
                    c, r = wc + dc, wr + dr
                    if (c, r) not in road and c < COLS and 0 <= r < ROWS:
                        if all(abs(c - w[0]) + abs(r - w[1]) > 1 for w in water):
                            water.append([c, r])
        water_set = {tuple(w) for w in water}
        # blocked props (never on road/water, 1-cell margin from road)
        blockers, decor = [], []
        block_pool = THEME_PROPS[theme][0]
        decor_pool = THEME_PROPS[theme][1]
        n_block = 9 + stars * 4
        tries = 0
        while len(blockers) < n_block and tries < 900:
            tries += 1
            c, r = rng.randint(0, COLS - 1), rng.randint(0, ROWS - 1)
            if (c, r) in road or (c, r) in water_set:
                continue
            if any((c + dc, r + dr) in road for dc in (-1, 0, 1) for dr in (-1, 0, 1)):
                continue
            if any(b[0] == c and b[1] == r for b in blockers):
                continue
            blockers.append([c, r, rng.choice(block_pool)])
        tries = 0
        while len(decor) < 16 and tries < 900:
            tries += 1
            c, r = rng.randint(0, COLS - 1), rng.randint(0, ROWS - 1)
            if (c, r) in road or (c, r) in water_set:
                continue
            if any(b[0] == c and b[1] == r for b in blockers) or any(d[0] == c and d[1] == r for d in decor):
                continue
            decor.append([c, r, rng.choice(decor_pool)])
        maps.append({
            "id": mid, "name": name, "theme": theme, "stars": stars, "price": price,
            "dual": bool(dual),  # True = the paths ALTERNATE groups (multi-path law)
            "paths": paths, "heart": [heart_col, heart_row],
            "blocked": blockers, "decor": decor, "water": water,
            "water_kind": wkind or "",
        })
        print(f"{mid:16s} paths={len(paths)} road={len(road):3d} block={len(blockers):2d} "
              f"water={len(water)} heart=({heart_col},{heart_row})")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as f:
        json.dump({"cols": COLS, "rows": ROWS, "maps": maps}, f, indent=1)
    print("wrote", OUT, "-", len(maps), "maps")
    # the export-proof twin: the same data as a .gd const (the PCK always
    # packs scripts; raw .json rides the importer and is not worth the risk)
    gd = OUT.replace(".json", "_data.gd")
    with open(gd, "w") as f:
        f.write("## GENERATED by tools/v035_pop_maps.py - do not edit by hand.\n")
        f.write("## The 30-map truth, embedded so the export never loses it.\n")
        f.write("class_name PDMapsData\nextends RefCounted\n\n")
        f.write("const DATA := ")
        f.write(json.dumps({"cols": COLS, "rows": ROWS, "maps": maps}))
        f.write("\n")
    print("wrote", gd)

    # validation: every map's paths sane
    for m in maps:
        for p in m["paths"]:
            assert -1 <= p[0][0] <= COLS, m["id"]
            assert p[-1] == m["heart"], m["id"]
            for c, r in p:
                assert 0 <= r < ROWS and -1 <= c <= COLS, (m["id"], c, r)
    print("validation OK")

if __name__ == "__main__":
    main()
