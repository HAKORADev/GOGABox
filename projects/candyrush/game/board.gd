class_name MatchBoard
extends RefCounted
## Pure match-3 model: 8x8 grid, 5 piece types, specials, cascades.
## No rendering - returns structured "waves" the view replays as tweens.
## Deterministic under a seeded RNG (tests rely on it).
##
## Cell = {"t": int type (-1 for colorless bomb, -2 while removed), "s": special}.
## Specials: SP_H clears its row, SP_V its column, SP_WRAP a 3x3, SP_BOMB nukes
## one color. Swapping two specials fires combined effects. A horizontal
## 4-match spawns SP_V (column clearer), vertical 4-match spawns SP_H;
## L/T intersections spawn SP_WRAP; a straight 5-match spawns SP_BOMB.

const W := 8
const H := 8
const NTYPES := 5

enum { SP_NONE, SP_H, SP_V, SP_WRAP, SP_BOMB }

var rng := RandomNumberGenerator.new()
var grid: Array = []  # grid[x][y] -> cell Dictionary
var last_deal: Array = []  # [{p: Vector2i, c: cell}] for the opening drop


func setup(seed_value: int) -> void:
        rng.seed = seed_value
        for attempt in 40:
                _fill_no_matches()
                last_deal = _snapshot_all()
                if find_hint() != null:
                        return


# ---------------------------------------------------------------- helpers

static func in_bounds(v: Vector2i) -> bool:
        return v.x >= 0 and v.x < W and v.y >= 0 and v.y < H


func at(v: Vector2i) -> Dictionary:
        return grid[v.x][v.y]


func _snapshot_all() -> Array:
        var out: Array = []
        for x in W:
                for y in H:
                        out.append({"p": Vector2i(x, y), "c": grid[x][y].duplicate()})
        return out


func _fill_no_matches() -> void:
        grid = []
        for x in W:
                var col: Array = []
                for y in H:
                        var forbidden := {}
                        if x >= 2 and grid[x - 1][y]["t"] == grid[x - 2][y]["t"]:
                                forbidden[grid[x - 1][y]["t"]] = true
                        if y >= 2 and col[y - 1]["t"] == col[y - 2]["t"]:
                                forbidden[col[y - 1]["t"]] = true
                        var t := rng.randi_range(0, NTYPES - 1)
                        var guard := 0
                        while forbidden.has(t) and guard < 20:
                                t = rng.randi_range(0, NTYPES - 1)
                                guard += 1
                        col.append({"t": t, "s": SP_NONE})
                grid.append(col)


## ---------------------------------------------------------------------------
## Swapping

## Swap two adjacent cells and resolve everything.
## Returns {} when the swap is illegal (caller animates a bounce-back).
## Returns {"waves": [wave...], "score": int} on success, where
## wave = {cleared:[Vector2i], spawned:[{p,c}], fell:[{from,to,c}],
##         dealt:[{p,c,drop}], combo:int, score:int}
func try_swap(a: Vector2i, b: Vector2i) -> Dictionary:
        if not in_bounds(a) or not in_bounds(b):
                return {}
        if (a - b).length() != 1.0:
                return {}

        var ca: Dictionary = at(a)
        var cb: Dictionary = at(b)
        var combo_kind := _combo_kind(ca, cb)
        if combo_kind > 0:
                grid[a.x][a.y] = cb
                grid[b.x][b.y] = ca
                var waves := _combo_wave(a, combo_kind, cb["t"] if ca["s"] == SP_BOMB else ca["t"])
                return {"waves": waves, "score": _waves_score(waves)}

        if ca["s"] == SP_BOMB or cb["s"] == SP_BOMB:
                # bomb + normal piece: nuke everything of the normal piece's color
                var normal_type: int = ca["t"] if cb["s"] == SP_BOMB else cb["t"]
                grid[a.x][a.y] = cb
                grid[b.x][b.y] = ca
                var waves := _bomb_color_wave(normal_type)
                return {"waves": waves, "score": _waves_score(waves)}

        var groups := _swap_creates_match(a, b)
        if groups.is_empty():
                return {}
        grid[a.x][a.y] = cb
        grid[b.x][b.y] = ca

        var waves: Array = []
        var total := 0
        var combo := 0
        var pending_spawns := _spawns_from_groups(groups, a)
        while true:
                var gs := _find_matches()
                if gs.is_empty():
                        break
                combo += 1
                var wave := _resolve_wave(gs, pending_spawns, combo)
                pending_spawns = []
                waves.append(wave)
                total += wave["score"]
                _collapse_and_refill(wave)
        if waves.is_empty():
                return {}
        return {"waves": waves, "score": total}


func _waves_score(waves: Array) -> int:
        var total := 0
        for w in waves:
                total += w["score"]
        return total


## >0: special-vs-special combo kind; 0: none.
func _combo_kind(ca: Dictionary, cb: Dictionary) -> int:
        var both: bool = ca["s"] != SP_NONE and cb["s"] != SP_NONE
        if not both:
                return 0
        if ca["s"] == SP_BOMB and cb["s"] == SP_BOMB:
                return 1  # bomb + bomb: clear the whole board
        if ca["s"] == SP_BOMB or cb["s"] == SP_BOMB:
                return 2  # bomb + special: nuke other's color + cross at pos
        if ca["s"] == SP_WRAP and cb["s"] == SP_WRAP:
                return 4  # wrap + wrap: 5x5 blast
        return 3  # striped/wrap mix: triple cross


func _combo_wave(pos: Vector2i, kind: int, other_type: int) -> Array:
        var cleared: Array = []
        for x in W:
                for y in H:
                        var v := Vector2i(x, y)
                        var take := false
                        match kind:
                                1:
                                        take = true
                                2:
                                        take = grid[x][y]["t"] == other_type or (absi(x - pos.x) <= 1 and y == pos.y) \
                                                        or (absi(y - pos.y) <= 1 and x == pos.x)
                                3:
                                        take = absi(x - pos.x) <= 1 or absi(y - pos.y) <= 1
                                4:
                                        take = absi(x - pos.x) <= 2 and absi(y - pos.y) <= 2
                        if take:
                                cleared.append(v)
        var wave := {"cleared": cleared, "spawned": [], "fell": [], "dealt": [], "combo": 1,
                        "score": 60 * cleared.size() + 300}
        for c in cleared:
                grid[c.x][c.y] = {"t": -2, "s": SP_NONE}
        _collapse_and_refill(wave)
        return [wave]


func _bomb_color_wave(normal_type: int) -> Array:
        var cleared: Array = []
        for x in W:
                for y in H:
                        if grid[x][y]["t"] == normal_type:
                                cleared.append(Vector2i(x, y))
        if cleared.is_empty():  # degenerate, still consume the bomb visibly
                cleared.append(Vector2i(0, 0))
        var wave := {"cleared": cleared, "spawned": [], "fell": [], "dealt": [], "combo": 1,
                        "score": 60 * cleared.size() + 200}
        for c in cleared:
                grid[c.x][c.y] = {"t": -2, "s": SP_NONE}
        _collapse_and_refill(wave)
        return [wave]


func _swap_creates_match(a: Vector2i, b: Vector2i) -> Array:
        var ca: Dictionary = at(a)
        var cb: Dictionary = at(b)
        grid[a.x][a.y] = cb
        grid[b.x][b.y] = ca
        var groups := _find_matches()
        grid[a.x][a.y] = ca
        grid[b.x][b.y] = cb
        return groups


# ---------------------------------------------------------------- matching

## All match groups on the current grid: [{cells:[Vector2i], horizontal:bool}]
func _find_matches() -> Array:
        var groups: Array = []
        for y in H:
                var x := 0
                while x < W:
                        var t: int = grid[x][y]["t"]
                        if t < 0 or grid[x][y]["s"] == SP_BOMB:
                                x += 1
                                continue
                        var x2 := x + 1
                        while x2 < W and grid[x2][y]["t"] == t and grid[x2][y]["s"] != SP_BOMB:
                                x2 += 1
                        if x2 - x >= 3:
                                var cells: Array = []
                                for i in range(x, x2):
                                        cells.append(Vector2i(i, y))
                                groups.append({"cells": cells, "horizontal": true})
                        x = x2
        for x in W:
                var y := 0
                while y < H:
                        var t: int = grid[x][y]["t"]
                        if t < 0 or grid[x][y]["s"] == SP_BOMB:
                                y += 1
                                continue
                        var y2 := y + 1
                        while y2 < H and grid[x][y2]["t"] == t and grid[x][y2]["s"] != SP_BOMB:
                                y2 += 1
                        if y2 - y >= 3:
                                var cells: Array = []
                                for i in range(y, y2):
                                        cells.append(Vector2i(x, i))
                                groups.append({"cells": cells, "horizontal": false})
                        y = y2
        return groups


## Decide which special candies the raw groups spawn (before activations).
func _spawns_from_groups(groups: Array, swap_pos: Vector2i) -> Array:
        var spawns: Array = []
        var claimed := {}
        # L/T shape: a cell shared by one horizontal + one vertical group -> wrapped
        for g in groups:
                if not g["horizontal"]:
                        continue
                for g2 in groups:
                        if g2["horizontal"]:
                                continue
                        for c in g["cells"]:
                                if g2["cells"].has(c) and not claimed.has(c):
                                        claimed[c] = true
                                        spawns.append({"p": c, "c": {"t": grid[c.x][c.y]["t"], "s": SP_WRAP}})
        for g in groups:
                if g["cells"].size() >= 5:
                        var p: Vector2i = g["cells"][int(g["cells"].size() / 2.0)]
                        if not claimed.has(p):
                                claimed[p] = true
                                spawns.append({"p": p, "c": {"t": -1, "s": SP_BOMB}})
        for g in groups:
                if g["cells"].size() == 4:
                        var p: Vector2i = g["cells"][0]
                        if g["cells"].has(swap_pos):
                                p = swap_pos
                        if not claimed.has(p):
                                claimed[p] = true
                                var s := SP_V if g["horizontal"] else SP_H
                                spawns.append({"p": p, "c": {"t": grid[p.x][p.y]["t"], "s": s}})
        return spawns


# ---------------------------------------------------------------- resolving

func _resolve_wave(groups: Array, spawns: Array, combo: int) -> Dictionary:
        var to_clear := {}
        var queue: Array = []  # pending special triggers [{p, s}]
        for g in groups:
                for c in g["cells"]:
                        _add_clear(c, to_clear, queue)
        for sp in spawns:
                to_clear.erase(sp["p"])  # the newborn special is protected in its birth wave
        while not queue.is_empty():
                var trig: Dictionary = queue.pop_front()
                _expand_activation(trig["p"], trig["s"], to_clear, queue)
        var cleared: Array = to_clear.keys()
        cleared.sort_custom(func(u, v): return u.y * W + u.x < v.y * W + v.x)
        var wave := {"cleared": cleared, "spawned": spawns, "fell": [], "dealt": [],
                        "combo": combo, "score": 60 * cleared.size() * mini(5, combo) + 120 * spawns.size()}
        for c in cleared:
                grid[c.x][c.y] = {"t": -2, "s": SP_NONE}
        for sp in spawns:
                grid[sp["p"].x][sp["p"].y] = sp["c"].duplicate()
        return wave


func _add_clear(c: Vector2i, to_clear: Dictionary, queue: Array) -> void:
        if not in_bounds(c) or to_clear.has(c):
                return
        if grid[c.x][c.y]["t"] == -2:
                return
        to_clear[c] = true
        var s: int = grid[c.x][c.y]["s"]
        if s != SP_NONE:
                queue.append({"p": c, "s": s})


func _expand_activation(p: Vector2i, s: int, to_clear: Dictionary, queue: Array) -> void:
        match s:
                SP_H:
                        for x in W:
                                _add_clear(Vector2i(x, p.y), to_clear, queue)
                SP_V:
                        for y in H:
                                _add_clear(Vector2i(p.x, y), to_clear, queue)
                SP_WRAP:
                        for dx in range(-1, 2):
                                for dy in range(-1, 2):
                                        _add_clear(p + Vector2i(dx, dy), to_clear, queue)
                SP_BOMB:
                        var counts := {}
                        for x in W:
                                for y in H:
                                        var t: int = grid[x][y]["t"]
                                        if t >= 0:
                                                counts[t] = int(counts.get(t, 0)) + 1
                        var best := -1
                        var best_n := 0
                        for t in counts:
                                if counts[t] > best_n:
                                        best = t
                                        best_n = counts[t]
                        if best >= 0:
                                for x in W:
                                        for y in H:
                                                if grid[x][y]["t"] == best:
                                                        _add_clear(Vector2i(x, y), to_clear, queue)


func _collapse_and_refill(wave: Dictionary) -> void:
        for x in W:
                var write := H - 1
                for y in range(H - 1, -1, -1):
                        if grid[x][y]["t"] != -2:
                                if write != y:
                                        grid[x][write] = grid[x][y]
                                        wave["fell"].append({"from": Vector2i(x, y), "to": Vector2i(x, write),
                                                        "c": grid[x][write].duplicate()})
                                write -= 1
                var dealt := 0
                for y in range(write, -1, -1):
                        var c := {"t": rng.randi_range(0, NTYPES - 1), "s": SP_NONE}
                        grid[x][y] = c
                        dealt += 1
                        wave["dealt"].append({"p": Vector2i(x, y), "c": c.duplicate(), "drop": dealt})


# ---------------------------------------------------------------- hints

## First valid move as [cell_a, cell_b], or null when deadlocked.
func find_hint() -> Variant:
        for x in W:
                for y in H:
                        var a := Vector2i(x, y)
                        for d in [Vector2i(1, 0), Vector2i(0, 1)]:
                                var b: Vector2i = a + d
                                if not in_bounds(b):
                                        continue
                                if grid[a.x][a.y]["s"] == SP_BOMB or grid[b.x][b.y]["s"] == SP_BOMB:
                                        return [a, b]
                                var ca: Dictionary = grid[a.x][a.y]
                                var cb: Dictionary = grid[b.x][b.y]
                                grid[a.x][a.y] = cb
                                grid[b.x][b.y] = ca
                                var ok := not _find_matches().is_empty()
                                grid[a.x][a.y] = ca
                                grid[b.x][b.y] = cb
                                if ok:
                                        return [a, b]
        return null


## Rearrange colors in place until the board is playable again.
## Returns {"moved": [{p, c}]} so the view can re-skin pieces in place.
func shuffle() -> Dictionary:
        for attempt in 50:
                var spots: Array = []
                for x in W:
                        for y in H:
                                if grid[x][y]["s"] != SP_BOMB:
                                        spots.append(Vector2i(x, y))
                var types: Array = []
                for p in spots:
                        types.append(grid[p.x][p.y]["t"])
                # seeded Fisher-Yates: deterministic under board.rng
                for i in range(types.size() - 1, 0, -1):
                        var j := rng.randi_range(0, i)
                        var tmp = types[i]
                        types[i] = types[j]
                        types[j] = tmp
                for i in spots.size():
                        grid[spots[i].x][spots[i].y]["t"] = types[i]
                if _find_matches().is_empty() and find_hint() != null:
                        var moved: Array = []
                        for p in spots:
                                moved.append({"p": p, "c": grid[p.x][p.y].duplicate()})
                        return {"moved": moved}
        _fill_no_matches()  # bounded fallback: fresh deal (still deterministic)
        return {"moved": _snapshot_all(), "redeal": true}
