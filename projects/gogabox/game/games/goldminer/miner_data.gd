class_name MinerData
extends RefCounted
## GOLD MINER (v040-15) - the data + the PURE ground generator.
## The generator is deliberately pure (level index + rng + anchor in,
## item list out) so the probe can assert fairness on hundreds of seeds
## without booting the scene (the marble levels-forge law: nothing ships
## blind - the validator runs at forge/probe time AND at play time).

const POINTS := {
        "gold_s": 1, "gold_m": 2, "gold_l": 3,
        "rock_s": 2, "rock_m": 4, "rock_l": 6,
}

## the weight law: reel speed px/s per thing (heavy value crawls home)
const REEL_SPEED := {
        "gold_s": 820.0, "gold_m": 640.0, "gold_l": 480.0,
        "rock_s": 520.0, "rock_m": 380.0, "rock_l": 300.0,
        "bomb": 700.0, "coin": 860.0, "none": 900.0,
}

## sprite radii (the claw hit circles, px)
const RADII := {
        "gold_s": 30.0, "gold_m": 62.0, "gold_l": 76.0,
        "rock_s": 32.0, "rock_m": 58.0, "rock_l": 80.0,
        "bomb": 40.0, "coin": 30.0,
}

const MINER_SKINS := [
        {"id": "classic", "name": "TOM", "price": 0},
        {"id": "emerald", "name": "EMERALD TOM", "price": 250},
        {"id": "royal", "name": "ROYAL TOM", "price": 350},
        {"id": "crimson", "name": "CRIMSON TOM", "price": 450},
        {"id": "frost", "name": "FROST TOM", "price": 550},
]

const VEIN_SKINS := [
        {"id": "classic", "name": "GOLD VEIN", "price": 0},
        {"id": "emerald", "name": "EMERALD VEIN", "price": 250},
        {"id": "amethyst", "name": "AMETHYST VEIN", "price": 350},
        {"id": "candy", "name": "CANDY VEIN", "price": 450},
        {"id": "obsidian", "name": "EMBER VEIN", "price": 550},
]

## the generator's own geometry contract (goldminer.gd mirrors these)
const FIELD := Rect2(70, 430, 940, 1260)     # x,y,w,h in design space
const ROPE_MAX := 1580.0
const ANCHOR_Y := 176.0
const MARGIN := 30.0
const GAP := 26.0

## ------------------------------------------------------------- profiles
## classic     uniform scatter
## fortress    the owner's example: a big gold ringed by small rocks
## deep_vein   heavy golds low, smalls high
## minefield   bombs parked beside the gold clusters
## twin_pockets two clusters at the side extremes
## cross_haul  big rocks ringing medium golds (the reel-risk test)

static func profile_for(level: int, rng: RandomNumberGenerator) -> String:
        var pool := ["classic", "classic", "fortress", "deep_vein"]
        if level >= 2:
                pool += ["minefield", "twin_pockets"]
        if level >= 3:
                pool += ["cross_haul", "deep_vein", "fortress"]
        return pool[rng.randi_range(0, pool.size() - 1)]

static func _budget(level: int, rng: RandomNumberGenerator) -> Dictionary:
        var ng := clampi(4 + int(level / 2.0), 4, 10)
        ng += rng.randi_range(0, 1)
        var nr := clampi(2 + int(level / 2.0), 2, 8)
        nr += rng.randi_range(0, 1)
        var nb := 0 if level <= 1 else clampi(1 + int((level - 2) / 4.0), 1, 3)
        return {"g": ng, "r": nr, "b": nb}

static func _gold_size(level: int, rng: RandomNumberGenerator) -> String:
        var roll := rng.randf()
        if level >= 2 and roll < 0.18:
                return "gold_l"
        if roll < 0.55:
                return "gold_s"
        return "gold_m" if roll < 0.92 else "gold_l"

static func _rock_size(level: int, rng: RandomNumberGenerator) -> String:
        var roll := rng.randf()
        if level >= 3 and roll < 0.16:
                return "rock_l"
        if roll < 0.5:
                return "rock_s"
        return "rock_m" if roll < 0.92 else "rock_l"

static func _ok_placement(items: Array, kind: String, r: float,
                pos: Vector2, anchor: Vector2) -> bool:
        # reach law: every GRABBABLE gold must be reel-able from the anchor
        if kind.begins_with("gold") or kind == "coin":
                if pos.distance_to(anchor) + r > ROPE_MAX - 40.0:
                        return false
        for it in items:
                var rr: float = r + float(it["r"]) + GAP
                if pos.distance_to(it["pos"]) < rr:
                        return false
                # bomb sanity: bombs never nest, and never hug a gold closer
                # than the blast radius buys a fair dodge
                if kind == "bomb" and it["kind"] == "bomb" \
                                and pos.distance_to(it["pos"]) < 220.0:
                        return false
                if kind == "bomb" and it["kind"].begins_with("gold") \
                                and pos.distance_to(it["pos"]) < float(it["r"]) + r + 46.0:
                        return false
                if kind.begins_with("gold") and it["kind"] == "bomb" \
                                and pos.distance_to(it["pos"]) < r + float(it["r"]) + 46.0:
                        return false
        return true

## THE GENERATOR: level (1-based) + rng + anchor position -> item list.
## Every list element: {kind, size, pos, r}. The validator retries the
## whole level on any violation; the classic fallback is safe by design.
static func generate(level: int, rng: RandomNumberGenerator,
                anchor: Vector2) -> Array:
        for attempt in 40:
                var items := _attempt(level, rng, anchor)
                if _validate(items, anchor):
                        return items
        return _attempt(level, rng, anchor, true)

static func _rand_pos(rng: RandomNumberGenerator, r: float,
                bias_low := 0.0, x_fix := -1.0) -> Vector2:
        var x := x_fix if x_fix >= 0.0 else rng.randf_range(
                FIELD.position.x + MARGIN + r, FIELD.end.x - MARGIN - r)
        var y0 := FIELD.position.y + MARGIN + r
        var y1 := FIELD.end.y - MARGIN - r
        # bias_low 0..1 pushes the draw toward the field's bottom
        var y := rng.randf_range(y0, y1)
        if bias_low > 0.0:
                y = y1 - (y1 - y) * (1.0 - bias_low * rng.randf())
        return Vector2(x, y)

static func _attempt(level: int, rng: RandomNumberGenerator,
                anchor: Vector2, safe := false) -> Array:
        var items: Array = []
        var budget := _budget(level, rng)
        var profile := "classic" if safe else profile_for(level, rng)
        var fortress_c := Vector2(
                rng.randf_range(FIELD.position.x + 300, FIELD.end.x - 300),
                rng.randf_range(FIELD.position.y + 500, FIELD.end.y - 200))
        var pocket_a := Vector2(rng.randf_range(150, 330),
                rng.randf_range(FIELD.position.y + 400, FIELD.end.y - 260))
        var pocket_b := Vector2(rng.randf_range(FIELD.end.x - 330,
                FIELD.end.x - 150),
                rng.randf_range(FIELD.position.y + 400, FIELD.end.y - 260))
        var placed_gold_m := false

        # ---- the fortress core: one L gold ringed by S rocks (the owner's
        # "big gold be surrounded by many small rocks" example)
        if profile == "fortress":
                var core_r: float = RADII["gold_l"]
                var core := fortress_c
                if _ok_placement(items, "gold_l", core_r, core, anchor):
                        items.append({"kind": "gold_l", "pos": core, "r": core_r})
                        placed_gold_m = true
                        budget["g"] -= 1
                        var ring := mini(budget["r"], 5)
                        for i in ring:
                                var a := TAU * i / float(ring) + rng.randf_range(-0.3, 0.3)
                                var d := core_r + RADII["rock_s"] + rng.randf_range(46, 92)
                                var p := core + Vector2(sin(a), cos(a)) * d
                                p.x = clampf(p.x, FIELD.position.x + MARGIN + RADII["rock_s"],
                                        FIELD.end.x - MARGIN - RADII["rock_s"])
                                p.y = clampf(p.y, FIELD.position.y + MARGIN + RADII["rock_s"],
                                        FIELD.end.y - MARGIN - RADII["rock_s"])
                                if _ok_placement(items, "rock_s", RADII["rock_s"], p, anchor):
                                        items.append({"kind": "rock_s", "pos": p,
                                                "r": RADII["rock_s"]})
                                        budget["r"] -= 1

        # ---- golds
        while budget["g"] > 0:
                var kind := _gold_size(level, rng)
                if budget["g"] <= 2 and not placed_gold_m and level >= 2:
                        kind = "gold_l"          # the deep guaranteed hook
                var r: float = RADII[kind]
                var pos := Vector2.ZERO
                var ok := false
                for t in 30:
                        match profile:
                                "deep_vein":
                                        pos = _rand_pos(rng, r,
                                                0.75 if kind != "gold_s" else 0.1)
                                "twin_pockets":
                                        pos = _rand_pos(rng, r, 0.0,
                                                rng.randf_range(minf(pocket_a.x, pocket_b.x) - 40,
                                                        maxf(pocket_a.x, pocket_b.x) + 40))
                                "fortress":
                                        pos = _rand_pos(rng, r,
                                                0.6 if kind == "gold_m" else 0.0)
                                _:
                                        pos = _rand_pos(rng, r)
                        if _ok_placement(items, kind, r, pos, anchor):
                                ok = true
                                break
                if ok:
                        items.append({"kind": kind, "pos": pos, "r": r})
                        if kind != "gold_s":
                                placed_gold_m = true
                budget["g"] -= 1

        # ---- rocks
        while budget["r"] > 0:
                var kind := _rock_size(level, rng)
                if profile == "cross_haul" and budget["r"] > budget["r"] / 2:
                        kind = "rock_l"
                var r: float = RADII[kind]
                var pos := Vector2.ZERO
                var ok := false
                for t in 30:
                        match profile:
                                "cross_haul":
                                        pos = _rand_pos(rng, r, 0.3)
                                "deep_vein":
                                        pos = _rand_pos(rng, r, 0.05)
                                "twin_pockets":
                                        pos = _rand_pos(rng, r, 0.0,
                                                rng.randf_range(FIELD.position.x + MARGIN + r,
                                                        FIELD.end.x - MARGIN - r))
                                _:
                                        pos = _rand_pos(rng, r)
                        if _ok_placement(items, kind, r, pos, anchor):
                                ok = true
                                break
                if ok:
                        items.append({"kind": kind, "pos": pos, "r": r})
                budget["r"] -= 1

        # ---- bombs (the lives)
        while budget["b"] > 0:
                var r: float = RADII["bomb"]
                var pos := Vector2.ZERO
                var ok := false
                for t in 40:
                        if profile == "minefield" and not items.is_empty():
                                # park beside a random gold (the threat with it)
                                var g: Dictionary = items[rng.randi_range(0, items.size() - 1)]
                                var a := rng.randf_range(0.0, TAU)
                                var d := float(g["r"]) + r + rng.randf_range(50, 120)
                                pos = g["pos"] + Vector2(sin(a), cos(a)) * d
                                pos.x = clampf(pos.x, FIELD.position.x + MARGIN + r,
                                        FIELD.end.x - MARGIN - r)
                                pos.y = clampf(pos.y, FIELD.position.y + MARGIN + r,
                                        FIELD.end.y - MARGIN - r)
                        else:
                                pos = _rand_pos(rng, r)
                        if _ok_placement(items, "bomb", r, pos, anchor):
                                ok = true
                                break
                if ok:
                        items.append({"kind": "bomb", "pos": pos, "r": r})
                budget["b"] -= 1
        return items

## THE VALIDATOR: every gold within rope reach, no overlaps, bombs sane.
## The generator retries the whole level when this fails (nothing ships
## blind - the marble levels-forge law).
static func _validate(items: Array, anchor: Vector2) -> bool:
        var golds := 0
        for it in items:
                var k := String(it["kind"])
                var r := float(it["r"])
                var p: Vector2 = it["pos"]
                if p.x - r < FIELD.position.x - 1.0 \
                                or p.x + r > FIELD.end.x + 1.0 \
                                or p.y - r < FIELD.position.y - 1.0 \
                                or p.y + r > FIELD.end.y + 1.0:
                        return false
                if k.begins_with("gold"):
                        golds += 1
                        if p.distance_to(anchor) + r > ROPE_MAX - 38.0:
                                return false
                for ot in items:
                        if ot == it:
                                continue
                        if p.distance_to(ot["pos"]) < r + float(ot["r"]) + GAP - 0.5:
                                return false
        return golds > 0
