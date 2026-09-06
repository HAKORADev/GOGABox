class_name PDData
extends RefCounted
## POP SIEGE - the data truth (v0.3.5). Bloons, the folk (10 x 3 gears),
## synergies, the 30 maps (maps.json, shared with the art engine), themes,
## and the wave generator. Everything the probe can verify without a scene.

const START_COINS := 250            # PopCoins at drop in (the owner's law)
const START_LIVES := 100            # the owner's law
const SELL_RATIO := 0.7
const BONUS_DIV := 1000             # run bonus = score / 1000 (the law)
const RIDER_EVERY := 10             # a GOGACoin hides in a bloon every N waves
const VICTORY_WAVE := 40            # THE SIEGE BREAKS; endless past it
const FATIGUE := 0.02               # +bloon speed per wave past victory

const FREE_FOLK := ["darty", "pyra", "boomba"]
const FREE_MAPS := ["first_bloom", "pine_twist", "dune_run"]

# damage classes
const SHARP := "sharp"
const EXPLOSION := "explosion"
const FIRE := "fire"
const ICE := "ice"
const ENERGY := "energy"

# ------------------------------------------------------------------ BLOONS
# hp, speed px/s, children, immunities, coins on pop, rbe lives on leak,
# tex scale, points note: score = hits, so hp IS the point value.
const BLOONS := {
        "red":      {"hp": 1, "sp": 1.05, "kids": [], "imm": [], "coins": 1, "rbe": 1, "scl": 0.42},
        "blue":     {"hp": 1, "sp": 1.4, "kids": ["red", "red"], "imm": [], "coins": 1, "rbe": 2, "scl": 0.42},
        "green":    {"hp": 1, "sp": 1.7, "kids": ["blue", "blue"], "imm": [], "coins": 1, "rbe": 3, "scl": 0.45},
        "yellow":   {"hp": 1, "sp": 2.35, "kids": ["green", "green"], "imm": [], "coins": 2, "rbe": 4, "scl": 0.45},
        "pink":     {"hp": 1, "sp": 3.0, "kids": ["yellow", "yellow"], "imm": [], "coins": 2, "rbe": 5, "scl": 0.45},
        "black":    {"hp": 1, "sp": 2.15, "kids": ["pink", "pink"], "imm": [EXPLOSION], "coins": 3, "rbe": 11, "scl": 0.42},
        "white":    {"hp": 1, "sp": 2.35, "kids": ["pink", "pink"], "imm": [ICE], "coins": 3, "rbe": 11, "scl": 0.42},
        "zebra":    {"hp": 1, "sp": 2.15, "kids": ["black", "white"], "imm": [EXPLOSION, ICE], "coins": 4, "rbe": 23, "scl": 0.48},
        "lead":     {"hp": 1, "sp": 0.85, "kids": ["black", "black"], "imm": [SHARP], "coins": 3, "rbe": 23, "scl": 0.5},
        "rainbow":  {"hp": 1, "sp": 2.15, "kids": ["zebra", "zebra"], "imm": [], "coins": 6, "rbe": 47, "scl": 0.48},
        "ceramic":  {"hp": 10, "sp": 2.15, "kids": ["rainbow", "rainbow"], "imm": [], "coins": 10, "rbe": 104, "scl": 0.52},
        "moab":     {"hp": 200, "sp": 0.65, "kids": ["ceramic", "ceramic", "ceramic", "ceramic"],
                        "imm": [], "coins": 40, "rbe": 616, "scl": 1.0, "blimp": true},
        "brutus":   {"hp": 700, "sp": 0.55, "kids": ["moab", "moab"], "imm": [],
                        "coins": 120, "rbe": 1932, "scl": 1.2, "blimp": true, "half_sharp": true},
}

static func rbe(kind: String) -> int:
        return int(BLOONS[kind]["rbe"])

# ------------------------------------------------------------------ THE FOLK
# place = the PopCoins price on the field; goga = the GOGACoins shop price.
# gears: the three stat tables; level growth: dmg x(1+.16L), rate x.97^L,
# range +0.07 cells (ALL DISTANCES ARE IN CELL UNITS - the field scale law:
# the game multiplies by CELL so the siege plays the same on every device).
# specials carry the gear extras.
const FOLK := {
        "darty": {
                "name": "Darty", "role": "quick darts, the opener", "cls": SHARP, "place": 170, "goga": 0,
                "up_base": 45, "gear_cost": [0, 500, 1400], "proj": "dart",
                "gears": [
                        {"dmg": 1.0, "rate": 0.95, "rng": 2.3, "pierce": 1, "shots": 1},
                        {"dmg": 1.0, "rate": 0.8, "rng": 2.6, "pierce": 2, "shots": 2},
                        {"dmg": 2.0, "rate": 0.72, "rng": 2.85, "pierce": 3, "shots": 2},
                ],
                "rows": ["dmg", "rate", "rng", "pierce"],
        },
        "pyra": {
                "name": "Pyra", "role": "fire that lingers", "cls": FIRE, "place": 380, "goga": 0,
                "up_base": 65, "gear_cost": [0, 700, 2000], "proj": "flame",
                "gears": [
                        {"dmg": 2.0, "rate": 1.4, "rng": 2.0, "blast": 0.85, "burn_dps": 0.8, "burn_t": 3.0},
                        {"dmg": 2.5, "rate": 1.25, "rng": 2.15, "blast": 0.95, "burn_dps": 1.2, "burn_t": 3.5,
                                "trap_every": 9.0, "trap_dps": 3.0},
                        {"dmg": 3.0, "rate": 1.15, "rng": 2.3, "blast": 1.05, "burn_dps": 1.8, "burn_t": 4.0,
                                "trap_every": 7.0, "trap_dps": 5.0, "ring_dps": 2.0},
                ],
                "rows": ["dmg", "burn", "rate", "rng", "blast"],
        },
        "boomba": {
                "name": "Boomba", "role": "lobs the boom", "cls": EXPLOSION, "place": 320, "goga": 0,
                "up_base": 60, "gear_cost": [0, 650, 1800], "proj": "bomb",
                "gears": [
                        {"dmg": 3.0, "rate": 1.9, "rng": 2.5, "blast": 0.95},
                        {"dmg": 4.0, "rate": 1.75, "rng": 2.7, "blast": 1.05, "frags": 6},
                        {"dmg": 5.0, "rate": 1.6, "rng": 2.85, "blast": 1.15, "frags": 8, "moab_bonus": 12.0, "stun": 0.4},
                ],
                "rows": ["dmg", "blast", "rate", "rng"],
        },
        "boomo": {
                "name": "Boomo", "role": "the returning arc", "cls": SHARP, "place": 280, "goga": 250,
                "up_base": 55, "gear_cost": [0, 600, 1700], "proj": "boomerang",
                "gears": [
                        {"dmg": 1.0, "rate": 1.3, "rng": 2.15, "pierce": 3},
                        {"dmg": 1.5, "rate": 1.2, "rng": 2.35, "pierce": 4, "orbit_dps": 1.0},
                        {"dmg": 2.0, "rate": 1.1, "rng": 2.6, "pierce": 5, "orbit_dps": 2.0, "moab_x": 2.0},
                ],
                "rows": ["dmg", "pierce", "rate", "rng"],
        },
        "gloop": {
                "name": "Gloop", "role": "slows the march", "cls": "glue", "place": 300, "goga": 300,
                "up_base": 55, "gear_cost": [0, 600, 1700], "proj": "goo",
                "gears": [
                        {"dmg": 0.0, "rate": 1.5, "rng": 1.8, "slow": 0.45, "slow_t": 2.5},
                        {"dmg": 0.0, "rate": 1.35, "rng": 2.0, "slow": 0.5, "slow_t": 3.0, "dps": 1.0},
                        {"dmg": 0.0, "rate": 1.2, "rng": 2.2, "slow": 0.55, "slow_t": 3.5, "dps": 2.0,
                                "flux_every": 7.0, "flux_back": 2.7},
                ],
                "rows": ["slow", "rate", "rng"],
        },
        "kolda": {
                "name": "Kolda", "role": "the deep chill", "cls": ICE, "place": 340, "goga": 350,
                "up_base": 60, "gear_cost": [0, 650, 1800], "proj": "ice",
                "gears": [
                        {"dmg": 1.0, "rate": 1.7, "rng": 1.9, "slow": 0.4, "slow_t": 2.0, "pulse": 1},
                        {"dmg": 1.5, "rate": 1.55, "rng": 2.05, "slow": 0.45, "slow_t": 2.3, "pulse": 1,
                                "patch": true},
                        {"dmg": 2.0, "rate": 1.4, "rng": 2.2, "slow": 0.5, "slow_t": 2.6, "pulse": 1,
                                "patch": true, "deep": true, "blimp_freeze": 1.2},
                ],
                "rows": ["dmg", "slow", "rate", "rng"],
        },
        "longeye": {
                "name": "Longeye", "role": "one shot, one lesson", "cls": SHARP, "place": 360, "goga": 350,
                "up_base": 65, "gear_cost": [0, 650, 1800], "proj": "sniper",
                "gears": [
                        {"dmg": 6.0, "rate": 2.3, "rng": 99.0},
                        {"dmg": 8.0, "rate": 2.1, "rng": 99.0, "fmj": true, "splash": 0.65},
                        {"dmg": 11.0, "rate": 1.9, "rng": 99.0, "fmj": true, "splash": 0.8, "moab_bonus": 25.0},
                ],
                "rows": ["dmg", "rate", "rng"],
        },
        "zappy": {
                "name": "Zappy", "role": "chains the sky", "cls": ENERGY, "place": 420, "goga": 420,
                "up_base": 70, "gear_cost": [0, 700, 2000], "proj": "zap",
                "gears": [
                        {"dmg": 2.0, "rate": 1.6, "rng": 2.05, "chain": 3},
                        {"dmg": 2.5, "rate": 1.45, "rng": 2.25, "chain": 3, "stun": 0.15},
                        {"dmg": 3.0, "rate": 1.35, "rng": 2.4, "chain": 4, "stun": 0.15,
                                "storm_every": 1.2},
                ],
                "rows": ["dmg", "chain", "rate", "rng"],
        },
        "kaching": {
                "name": "Kaching", "role": "the bank that fights back", "cls": "support", "place": 450, "goga": 450,
                "up_base": 80, "gear_cost": [0, 900, 2400], "proj": "",
                "gears": [
                        {"dmg": 0.0, "rate": 0.0, "rng": 0.0, "income": 26.0},
                        {"dmg": 0.0, "rate": 0.0, "rng": 0.0, "income": 38.0, "interest": 0.08},
                        {"dmg": 0.0, "rate": 0.0, "rng": 0.0, "income": 52.0, "interest": 0.08, "egg": 120.0},
                ],
                "rows": ["income"],
        },
        "marshal": {
                "name": "Marshal", "role": "the drum that leads", "cls": "support", "place": 400, "goga": 500,
                "up_base": 75, "gear_cost": [0, 700, 2000], "proj": "",
                "gears": [
                        {"dmg": 1.0, "rate": 2.2, "rng": 2.7, "aura_rate": 0.12},
                        {"dmg": 1.5, "rate": 2.0, "rng": 2.95, "aura_rate": 0.16, "aura_rng": 0.08},
                        {"dmg": 2.0, "rate": 1.85, "rng": 3.2, "aura_rate": 0.2, "aura_rng": 0.08, "aura_pierce": 1},
                ],
                "rows": ["aura", "dmg", "rate", "rng"],
        },
}

static func folk_ids() -> Array:
        return FOLK.keys()

## level growth (level 1..10). dmg x(1+0.16L), rate x0.97^L, range +4L.
static func stat(fid: String, gear: int, lvl: int, key: String) -> float:
        var g: Dictionary = FOLK[fid]["gears"][gear - 1]
        var L := float(lvl - 1)
        match key:
                "dmg":
                        return float(g.get("dmg", 0.0)) * (1.0 + 0.16 * L)
                "rate":
                        return float(g.get("rate", 0.0)) * pow(0.97, L)
                "rng":
                        return float(g.get("rng", 0.0)) + 0.07 * L
                "pierce":
                        return float(g.get("pierce", 1.0))
                "blast":
                        return float(g.get("blast", 0.0)) + 0.035 * L
                "burn":
                        return float(g.get("burn_dps", 0.0)) * (1.0 + 0.16 * L)
                "slow":
                        return float(g.get("slow", 0.0))
                "chain":
                        return float(g.get("chain", 0.0))
                "income":
                        return float(g.get("income", 0.0)) + 3.0 * L * (1.0 if g.has("income") else 0.0)
                "aura":
                        return float(g.get("aura_rate", 0.0)) + 0.02 * L * (1.0 if g.has("aura_rate") else 0.0)
        return 0.0

## the >> preview: the value the SAME key reaches at level+1 (or 0 at max).
static func next_stat(fid: String, gear: int, lvl: int, key: String) -> float:
        if lvl >= 10:
                return 0.0
        return stat(fid, gear, lvl + 1, key)

static func up_cost(fid: String, lvl: int) -> int:
        # the level-up price: not too expensive, scaling by level (the owner's law)
        return int(round(float(FOLK[fid]["up_base"]) * pow(1.13, lvl - 1)))

static func gear_cost(fid: String, gear: int) -> int:
        # the jump g->g+1 (expensive on purpose)
        return int(FOLK[fid]["gear_cost"][gear]) if gear < 3 else 0

# ------------------------------------------------------------------ SYNERGIES
# in-range pacts (the BTD lore). gate = the required gear of the GUEST folk.
const SYNERGIES := [
        {"id": "drum", "name": "DRUM BEAT", "host": "marshal", "guest": "*",
                "badge": "drum", "desc": "Marshal's aura: faster fire (scales with his level)"},
        {"id": "rally", "name": "RALLY", "host": "darty", "guest": "boomo",
                "badge": "swirl", "desc": "Darty + Boomo near each other: both +15% attack speed"},
        {"id": "thermal", "name": "THERMAL SHOCK", "host": "pyra", "guest": "kolda",
                "badge": "flame_snow", "desc": "Pyra (G2+) near Kolda: slowed bloons take +2 from her"},
        {"id": "supercond", "name": "SUPERCONDUCT", "host": "zappy", "guest": "kolda",
                "badge": "bolt_snow", "desc": "Zappy (G2+) near Kolda: chain +2 targets"},
        {"id": "spotter", "name": "SPOTTER", "host": "longeye", "guest": "marshal",
                "badge": "crosshair", "desc": "Longeye (G2+) in a Marshal aura: +3 damage"},
        {"id": "wardrums", "name": "WAR DRUMS", "host": "boomba", "guest": "marshal",
                "badge": "ring_drum", "desc": "Boomba (G2+) in a Marshal aura: blast +15%"},
        {"id": "goldwing", "name": "GOLD WING", "host": "kaching", "guest": "marshal",
                "badge": "coin_wing", "desc": "Kaching (G2+) in a Marshal aura: +2 PopCoins per pop"},
        {"id": "ignite", "name": "IGNITE", "host": "gloop", "guest": "pyra",
                "badge": "drop_flame", "desc": "Gloop (G3) near Pyra: glued bloons burn"},
]

# ------------------------------------------------------------------ MAPS
static var _maps_cache: Variant = null

static func maps_data() -> Dictionary:
        if _maps_cache == null:
                _maps_cache = PDMapsData.DATA
        return _maps_cache

static func maps() -> Array:
        return maps_data()["maps"]

static func map_by_id(mid: String) -> Dictionary:
        for m in maps():
                if m["id"] == mid:
                        return m
        return maps()[0]

# ------------------------------------------------------------------ THEMES
const THEMES := {
        "meadow":    {"road": Color("d6b278"), "road_edge": Color("9c7848"), "night": Color(0.30, 0.34, 0.52)},
        "forest":    {"road": Color("c2a06a"), "road_edge": Color("7c6238"), "night": Color(0.26, 0.32, 0.50)},
        "desert":    {"road": Color("e8cf9a"), "road_edge": Color("a8863e"), "night": Color(0.32, 0.30, 0.50)},
        "snow":      {"road": Color("cfd8e2"), "road_edge": Color("8fa2b8"), "night": Color(0.36, 0.40, 0.62)},
        "beach":     {"road": Color("d9b26e"), "road_edge": Color("9c7440"), "night": Color(0.30, 0.32, 0.55)},
        "swamp":     {"road": Color("8a7448"), "road_edge": Color("4e4028"), "night": Color(0.28, 0.34, 0.44)},
        "volcano":   {"road": Color("4e4448"), "road_edge": Color("2c2426"), "night": Color(0.42, 0.28, 0.28)},
        "candy":     {"road": Color("f2e0c8"), "road_edge": Color("c08f98"), "night": Color(0.40, 0.32, 0.52)},
        "graveyard": {"road": Color("9a9a90"), "road_edge": Color("565650"), "night": Color(0.30, 0.32, 0.48)},
        "crystal":   {"road": Color("8e94b8"), "road_edge": Color("4e5470"), "night": Color(0.38, 0.38, 0.62)},
}

# ------------------------------------------------------------------ WAVES
# the generator: budget grows by wave; families unlock in bands; milestones
# at 10/20/30/40; a GOGACoin rider hides in a random bloon every 10.
const WAVE_COST := {
        "red": 2, "blue": 3, "green": 4, "yellow": 5, "pink": 6, "black": 9, "white": 9,
        "zebra": 14, "lead": 14, "rainbow": 22, "ceramic": 55, "moab": 220, "brutus": 700,
}

static func unlock_band(kind: String) -> int:
        match kind:
                "red": return 1
                "blue": return 2
                "green": return 4
                "yellow": return 7
                "pink": return 10
                "black", "white": return 13
                "lead": return 16
                "zebra": return 17
                "rainbow": return 19
                "ceramic": return 21
                "moab": return 25
                "brutus": return 32
        return 99

static func wave_budget(w: int, stars: int) -> float:
        var mult: float = [1.0, 1.0, 1.18, 1.38][clampi(stars, 1, 3)]
        return (55.0 + 20.0 * w + 3.0 * pow(float(w), 1.7)) * mult

## returns [{kind, count, spacing, delay}] - the groups of one wave.
static func wave_groups(w: int, stars: int) -> Array:
        var budget := wave_budget(w, stars)
        var pool: Array = []
        for k in WAVE_COST:
                if w >= unlock_band(k):
                        pool.append(k)
        pool.sort_custom(func(a, b): return WAVE_COST[a] < WAVE_COST[b])
        # milestones first (the boss law)
        var groups: Array = []
        if w == 10:
                groups.append({"kind": "moab", "count": 1, "spacing": 0.0, "delay": 2.0})
                budget -= 220.0
        elif w == 20:
                groups.append({"kind": "moab", "count": 3, "spacing": 4.0, "delay": 2.0})
                budget -= 660.0
        elif w == 30:
                groups.append({"kind": "brutus", "count": 1, "spacing": 0.0, "delay": 2.0})
                budget -= 700.0
        elif w == 40:
                groups.append({"kind": "brutus", "count": 2, "spacing": 8.0, "delay": 2.0})
                budget -= 1400.0
        var spacing: float = maxf(0.28, 0.9 - float(w) * 0.012)
        var n_groups := 1 + (1 if w >= 8 else 0) + (1 if w >= 18 else 0)
        var heavy := pool.slice(maxi(0, pool.size() - 4))   # the newest families
        var light := pool.slice(0, maxi(1, pool.size() - 3))
        for gi in n_groups:
                if budget <= 8.0:
                        break
                var src: Array = heavy if (gi % 2 == 1 and heavy.size() > 0) else light
                var kind: String = src[randi() % src.size()]
                var cost := float(WAVE_COST[kind])
                var count := clampi(int(budget * (0.55 if gi == 0 else 0.3) / cost), 1, 60)
                groups.append({"kind": kind, "count": count, "spacing": spacing, "delay": 1.0 + gi * 2.5})
                budget -= count * cost
        if groups.is_empty():
                groups.append({"kind": "red", "count": 10, "spacing": spacing, "delay": 0.0})
        return groups

## the endless law: past wave 40 everything speeds up (fatigue).
static func fatigue_for(wave: int) -> float:
        return 1.0 + FATIGUE * maxf(0.0, float(wave - VICTORY_WAVE))

# ------------------------------------------------------------------ helpers
static func imm_allows(kind: String, cls: String) -> bool:
        var imm: Array = BLOONS[kind]["imm"]
        if cls in imm:
                return false
        return true

static func dmg_vs(kind: String, cls: String, dmg: float) -> float:
        # the honest matrix: immunities block, BRUTUS halves sharp, fire/energy pop lead
        if not imm_allows(kind, cls):
                return 0.0
        if kind == "brutus" and BLOONS[kind].get("half_sharp", false) and cls == SHARP:
                return dmg * 0.5
        return dmg

## the menu rows for one folk (label, key) - the >> law's backbone.
static func rows_for(fid: String) -> Array:
        var out: Array = []
        for key in FOLK[fid]["rows"]:
                match key:
                        "dmg": out.append(["DAMAGE", "dmg"])
                        "rate": out.append(["RATE", "rate"])
                        "rng": out.append(["RANGE", "rng"])
                        "pierce": out.append(["PIERCE", "pierce"])
                        "blast": out.append(["BLAST", "blast"])
                        "burn": out.append(["BURN DPS", "burn"])
                        "slow": out.append(["SLOW", "slow"])
                        "chain": out.append(["CHAIN", "chain"])
                        "income": out.append(["COINS/WAVE", "income"])
                        "aura": out.append(["AURA RATE", "aura"])
        return out
