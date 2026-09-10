class_name PDData
extends RefCounted
## POP SIEGE - the data truth (v0.3.5-2). THE WHEEL LAW: bloons wear COLOR
## LEVELS (each level cracks for +1 damage more and shifts the hue a visible
## step), STRIPS (each band hides another bloon inside - 10 on balloons, 50
## on blimps, the counts stay hidden), and ARMOR shells (metal fears only
## fire, rock fears only bombs). PopCoins pay PER LAYER POP (v0.3.8-4: 1
## layer popped = 1 popcoin, paid the moment it pops - overkill pays
## nothing). Prices climbed so
## the gear-ups are the rich door. All distances stay in CELL units.

const START_COINS := 650            # the purse at drop in (per-damage pay rebalance)
const START_LIVES := 100            # the owner's law
const SELL_RATIO := 0.7             # sell = 70% of everything invested
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

# armor shells (the top layer): metal cracks ONLY to fire, rock ONLY to bombs
const ARMOR_METAL := "metal"
const ARMOR_ROCK := "rock"
const METAL_WAVE := 22              # metal enters the siege
const ROCK_WAVE := 26               # rock joins
const LEVEL_WAVE := 11              # the color wheel starts turning
const STRIP_WAVE := 13              # the first striped bloons

# ------------------------------------------------------------------ BLOONS
# hp = the crack cost of LEVEL 1 (the honest body); speed px/s in cells;
# kids = what pops out; immunities; scl = art scale in cells; rbe = lives
# lost on leak (the full chain). PopCoins pay per LAYER POPPED (no table).
const BLOONS := {
        "red":      {"hp": 1, "sp": 1.05, "kids": [], "imm": [], "rbe": 1, "scl": 0.50},
        "blue":     {"hp": 1, "sp": 1.4, "kids": ["red", "red"], "imm": [], "rbe": 2, "scl": 0.50},
        "green":    {"hp": 1, "sp": 1.7, "kids": ["blue", "blue"], "imm": [], "rbe": 3, "scl": 0.52},
        "yellow":   {"hp": 1, "sp": 2.35, "kids": ["green", "green"], "imm": [], "rbe": 4, "scl": 0.52},
        "pink":     {"hp": 1, "sp": 3.0, "kids": ["yellow", "yellow"], "imm": [], "rbe": 5, "scl": 0.52},
        "black":    {"hp": 1, "sp": 2.15, "kids": ["pink", "pink"], "imm": [EXPLOSION], "rbe": 11, "scl": 0.50},
        "white":    {"hp": 1, "sp": 2.35, "kids": ["pink", "pink"], "imm": [ICE], "rbe": 11, "scl": 0.50},
        "zebra":    {"hp": 1, "sp": 2.15, "kids": ["black", "white"], "imm": [EXPLOSION, ICE], "rbe": 23, "scl": 0.55},
        "lead":     {"hp": 1, "sp": 0.85, "kids": ["black", "black"], "imm": [SHARP], "rbe": 23, "scl": 0.57},
        "rainbow":  {"hp": 1, "sp": 2.15, "kids": ["zebra", "zebra"], "imm": [], "rbe": 47, "scl": 0.55},
        "ceramic":  {"hp": 10, "sp": 2.15, "kids": ["rainbow", "rainbow"], "imm": [], "rbe": 104, "scl": 0.60},
        "moab":     {"hp": 200, "sp": 0.65, "kids": ["ceramic", "ceramic", "ceramic", "ceramic"],
                        "imm": [], "rbe": 616, "scl": 0.85, "blimp": true},
        "brutus":   {"hp": 700, "sp": 0.55, "kids": ["moab", "moab"], "imm": [],
                        "rbe": 1932, "scl": 1.0, "blimp": true, "half_sharp": true},
        "gargantua": {"hp": 2600, "sp": 0.45, "kids": ["brutus", "brutus", "brutus"], "imm": [],
                        "rbe": 8396, "scl": 1.12, "blimp": true},
        "titan":    {"hp": 9000, "sp": 0.38, "kids": ["gargantua", "gargantua"], "imm": [],
                        "rbe": 25792, "scl": 1.24, "blimp": true, "half_sharp": true},
}

static func rbe(kind: String) -> int:
        return int(BLOONS[kind]["rbe"])

## THE SHOT LAW v1 (v0.3.8-5, the owner: "8 - 2 = 6 which means one shot can
## eliminate the whole bloon ... whatever is the damage points, they have no
## meaning at all ... not that complex thing"): every ring costs the body's
## OWN honest thickness - a red ring is 1, a ceramic ring is 10, a moab ring
## is 200. The old +1-per-level pyramid (3/2/1 ladders) is GONE: it made a
## big shot stop at ring borders and damage points meant nothing. Now a
## shot's damage flows through rings like water - 8 damage empties a 2-ring
## wheel in ONE shot and has 6 left for the next bloon.
static func crack_hp(kind: String, _lv: int) -> float:
        return float(BLOONS[kind]["hp"])

## the total damage a fully-leveled body absorbs (lv rings x the thickness).
static func body_hp(kind: String, lv: int) -> float:
        var total := 0.0
        for i in range(1, lv + 1):
                total += crack_hp(kind, i)
        return total

## what the leak costs: the whole chain + the level armor + the hidden strips.
static func threat(kind: String, lv: int, strips: Array) -> int:
        var t := rbe(kind) + maxi(0, lv - 1) * 2
        for s in strips:
                t += rbe(String(s))
        return t

## the armor shells answer to ONE class each (the tactical law).
static func armor_allows(armor: String, cls: String) -> bool:
        if armor == ARMOR_METAL:
                return cls == FIRE
        if armor == ARMOR_ROCK:
                return cls == EXPLOSION
        return false

# ------------------------------------------------------------------ THE FOLK
# place = the PopCoins price on the field; goga = the GOGACoins shop price.
# gears: the three stat tables; level growth: dmg x(1+.16L), rate x.97^L,
# range +0.07 cells (ALL DISTANCES ARE IN CELL UNITS - the field scale law).
# THE PRICE LAW (the owner): the gear-ups are the VERY expensive door.
const FOLK := {
        "darty": {
                "name": "Darty", "role": "quick darts, the opener", "cls": SHARP, "place": 200, "goga": 0,
                "up_base": 110, "gear_cost": [0, 2800, 8800], "proj": "dart",
                "gears": [
                        {"dmg": 1.0, "rate": 0.95, "rng": 2.3, "pierce": 1, "shots": 1},
                        {"dmg": 1.0, "rate": 0.8, "rng": 2.6, "pierce": 2, "shots": 2},
                        {"dmg": 2.0, "rate": 0.72, "rng": 2.85, "pierce": 3, "shots": 2},
                ],
                "rows": ["dmg", "pierce", "rate", "rng"],
        },
        "pyra": {
                "name": "Pyra", "role": "fire that lingers", "cls": FIRE, "place": 400, "goga": 0,
                "up_base": 160, "gear_cost": [0, 3800, 12000], "proj": "flame",
                "gears": [
                        {"dmg": 2.0, "rate": 1.4, "rng": 2.0, "blast": 0.85, "burn_dps": 0.8, "burn_t": 3.0},
                        {"dmg": 2.5, "rate": 1.25, "rng": 2.15, "blast": 0.95, "burn_dps": 1.2, "burn_t": 3.5,
                                "trap_every": 9.0, "trap_dps": 3.0},
                        {"dmg": 3.0, "rate": 1.15, "rng": 2.3, "blast": 1.05, "burn_dps": 1.8, "burn_t": 4.0,
                                "trap_every": 7.0, "trap_dps": 5.0, "ring_dps": 2.0},
                ],
                "rows": ["dmg", "burn", "blast", "rate", "rng"],
        },
        "boomba": {
                "name": "Boomba", "role": "lobs the boom", "cls": EXPLOSION, "place": 360, "goga": 0,
                "up_base": 150, "gear_cost": [0, 3600, 11000], "proj": "bomb",
                "gears": [
                        {"dmg": 3.0, "rate": 1.9, "rng": 2.5, "blast": 0.95},
                        {"dmg": 4.0, "rate": 1.75, "rng": 2.7, "blast": 1.05, "frags": 6},
                        {"dmg": 5.0, "rate": 1.6, "rng": 2.85, "blast": 1.15, "frags": 8, "moab_bonus": 40.0, "stun": 0.4},
                ],
                "rows": ["dmg", "blast", "rate", "rng"],
        },
        "boomo": {
                "name": "Boomo", "role": "the returning arc", "cls": SHARP, "place": 520, "goga": 250,
                "up_base": 130, "gear_cost": [0, 3000, 9500], "proj": "boomerang",
                "gears": [
                        {"dmg": 1.0, "rate": 1.3, "rng": 2.15, "pierce": 3},
                        {"dmg": 1.5, "rate": 1.2, "rng": 2.35, "pierce": 4, "orbit_dps": 1.0},
                        {"dmg": 2.0, "rate": 1.1, "rng": 2.6, "pierce": 5, "orbit_dps": 2.0, "moab_x": 2.0},
                ],
                "rows": ["dmg", "pierce", "rate", "rng"],
        },
        "gloop": {
                "name": "Gloop", "role": "slows the march", "cls": "glue", "place": 540, "goga": 300,
                "up_base": 130, "gear_cost": [0, 3000, 9500], "proj": "goo",
                "gears": [
                        {"dmg": 0.0, "rate": 1.5, "rng": 1.8, "slow": 0.45, "slow_t": 2.5},
                        {"dmg": 0.0, "rate": 1.35, "rng": 2.0, "slow": 0.5, "slow_t": 3.0, "dps": 1.0},
                        {"dmg": 0.0, "rate": 1.2, "rng": 2.2, "slow": 0.55, "slow_t": 3.5, "dps": 2.0,
                                "flux_every": 7.0, "flux_back": 2.7},
                ],
                "rows": ["slow", "rate", "rng"],
        },
        "kolda": {
                "name": "Kolda", "role": "the deep chill", "cls": ICE, "place": 600, "goga": 350,
                "up_base": 150, "gear_cost": [0, 3600, 11000], "proj": "ice",
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
                "name": "Longeye", "role": "one shot, one lesson", "cls": SHARP, "place": 640, "goga": 350,
                "up_base": 160, "gear_cost": [0, 3800, 12000], "proj": "sniper",
                "gears": [
                        {"dmg": 8.0, "rate": 2.3, "rng": 7.0},
                        {"dmg": 11.0, "rate": 2.1, "rng": 7.6, "fmj": true, "splash": 0.65},
                        {"dmg": 16.0, "rate": 1.9, "rng": 8.2, "fmj": true, "splash": 0.8, "moab_bonus": 80.0},
                ],
                "rows": ["dmg", "rate", "rng"],
        },
        "zappy": {
                "name": "Zappy", "role": "chains the sky", "cls": ENERGY, "place": 740, "goga": 420,
                "up_base": 170, "gear_cost": [0, 4200, 13000], "proj": "zap",
                "gears": [
                        {"dmg": 2.0, "rate": 1.6, "rng": 2.05, "chain": 3},
                        {"dmg": 2.5, "rate": 1.45, "rng": 2.25, "chain": 3, "stun": 0.15},
                        {"dmg": 3.0, "rate": 1.35, "rng": 2.4, "chain": 4, "stun": 0.15,
                                "storm_every": 1.2},
                ],
                "rows": ["dmg", "chain", "rate", "rng"],
        },
        "kaching": {
                "name": "Kaching", "role": "the bank that fights back", "cls": "support", "place": 800, "goga": 450,
                "up_base": 200, "gear_cost": [0, 4800, 15000], "proj": "",
                "gears": [
                        {"dmg": 0.0, "rate": 0.0, "rng": 0.0, "income": 90.0},
                        {"dmg": 0.0, "rate": 0.0, "rng": 0.0, "income": 150.0, "interest": 0.08},
                        {"dmg": 0.0, "rate": 0.0, "rng": 0.0, "income": 220.0, "interest": 0.08, "egg": 900.0},
                ],
                "rows": ["income"],
        },
        "marshal": {
                "name": "Marshal", "role": "the drum that leads", "cls": "support", "place": 720, "goga": 500,
                "up_base": 190, "gear_cost": [0, 4400, 13500], "proj": "",
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

## level growth (level 1..10). dmg x(1+0.16L), rate x0.97^L, range +0.07L.
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
                        return float(g.get("income", 0.0)) + 12.0 * L * (1.0 if g.has("income") else 0.0)
                "aura":
                        return float(g.get("aura_rate", 0.0)) + 0.02 * L * (1.0 if g.has("aura_rate") else 0.0)
        return 0.0

## the >> preview: the value the SAME key reaches at level+1 (or 0 at max).
static func next_stat(fid: String, gear: int, lvl: int, key: String) -> float:
        if lvl >= 10:
                return 0.0
        return stat(fid, gear, lvl + 1, key)

static func up_cost(fid: String, lvl: int) -> int:
        # the level-up price: climbs hard (the rich ladder the owner asked for)
        return int(round(float(FOLK[fid]["up_base"]) * pow(1.22, lvl - 1)))

static func gear_cost(fid: String, gear: int) -> int:
        # THE GEAR DOOR: the very expensive jump g->g+1
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
# THE CLIMB LAW: the budget grows steeply (the siege is not a picnic anymore)
# and the difficulty bands weave LEVELS + STRIPS + ARMOR into every wave.
const WAVE_COST := {
        "red": 2, "blue": 3, "green": 4, "yellow": 5, "pink": 6, "black": 9, "white": 9,
        "zebra": 14, "lead": 14, "rainbow": 22, "ceramic": 55,
        "moab": 240, "brutus": 800, "gargantua": 3400, "titan": 10000,
}

static func unlock_band(kind: String) -> int:
        match kind:
                "red": return 1
                "blue": return 2
                "green": return 4
                "yellow": return 7
                "pink": return 10
                "black", "white": return 12
                "lead": return 15
                "zebra": return 16
                "rainbow": return 18
                "ceramic": return 20
                "moab": return 18
                "brutus": return 28
                "gargantua": return 34
                "titan": return 40
        return 99

static func wave_budget(w: int, stars: int) -> float:
        var mult: float = [1.0, 1.0, 1.22, 1.45][clampi(stars, 1, 3)]
        return (60.0 + 26.0 * w + 4.2 * pow(float(w), 1.85)) * mult

## the difficulty bands of one wave (what the spawner may weave in).
static func wave_mods(w: int) -> Dictionary:
        var lv_max := 1
        if w >= LEVEL_WAVE:
                lv_max = mini(12, 1 + int((w - LEVEL_WAVE + 4) / 4.0))
        var strips_max := 0
        if w >= STRIP_WAVE:
                strips_max = mini(10, 1 + int((w - STRIP_WAVE) / 3.0))
        var blimp_strips_max := 0
        if w >= 20:
                blimp_strips_max = mini(50, (w - 18) * 2)
        var metal := 0.0 if w < METAL_WAVE else minf(0.55, 0.08 + (w - METAL_WAVE) * 0.022)
        var rock := 0.0 if w < ROCK_WAVE else minf(0.5, 0.06 + (w - ROCK_WAVE) * 0.02)
        return {"lv_max": lv_max, "strips_max": strips_max,
                "blimp_strips_max": blimp_strips_max, "metal": metal, "rock": rock}

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
                budget -= 240.0
        elif w == 20:
                groups.append({"kind": "moab", "count": 3, "spacing": 4.0, "delay": 2.0})
                budget -= 720.0
        elif w == 30:
                groups.append({"kind": "brutus", "count": 1, "spacing": 0.0, "delay": 2.0})
                budget -= 800.0
        elif w == 35:
                groups.append({"kind": "gargantua", "count": 1, "spacing": 0.0, "delay": 2.0})
                budget -= 3400.0
        elif w == 40:
                groups.append({"kind": "titan", "count": 1, "spacing": 0.0, "delay": 1.0})
                groups.append({"kind": "brutus", "count": 2, "spacing": 8.0, "delay": 6.0})
                budget -= 11600.0
        var spacing: float = maxf(0.22, 0.85 - float(w) * 0.012)
        var n_groups := 1 + (1 if w >= 8 else 0) + (1 if w >= 18 else 0)
        var heavy := pool.slice(maxi(0, pool.size() - 4))   # the newest families
        var light := pool.slice(0, maxi(1, pool.size() - 3))
        for gi in n_groups:
                if budget <= 8.0:
                        break
                var src: Array = heavy if (gi % 2 == 1 and heavy.size() > 0) else light
                var kind: String = src[randi() % src.size()]
                var cost := float(WAVE_COST[kind])
                var cap := 80 if w < 20 else 220
                var count := clampi(int(budget * (0.55 if gi == 0 else 0.3) / cost), 1, cap)
                groups.append({"kind": kind, "count": count, "spacing": spacing, "delay": 1.0 + gi * 2.5})
                budget -= count * cost
        if groups.is_empty():
                groups.append({"kind": "red", "count": 10, "spacing": spacing, "delay": 0.0})
        return groups

## the endless law: past wave 40 everything speeds up (fatigue).
static func fatigue_for(wave: int) -> float:
        return 1.0 + FATIGUE * maxf(0.0, float(wave - VICTORY_WAVE))

## the art truth v2 (MEASURED from the drawn heads - the owner's round):
## the rotation that points a head's muzzle AT the aim. darty's crossbow tip
## points RIGHT (offset 0 - the old PI/2 aimed 90 degrees off the shot),
## longeye's tip points LEFT (PI). v0.3.5-6: boomba joins the muzzle-right
## crowd (0) - the g3 cannon's firing opening is plainly on its right end.
## The radial heads (pyra/boomo/kolda/zappy) and the static ones (kaching/
## marshal) carry 0.
static func head_offset(fid: String) -> float:
        # v0.3.5-6 THE FACE-IT LAW (the owner: "bomber looks with it's butt
        # and not the face"): the atlas mortars are drawn muzzle-RIGHT (the
        # g3 cannon wears its firing opening on the right end) - the old PI
        # spun every aim 180 degrees and marched the bomb-thrower
        # butt-first into every fight. The muzzle-right art aims with 0.
        match fid:
                "longeye": return PI
        return 0.0

## THE MUZZLE LAW: how far from the gadget's center the shot LEAVES, in CELL
## units (measured to each head's business end - the darts no longer crawl
## out of the base belly).
static func muzzle(fid: String) -> float:
        match fid:
                "darty": return 0.56
                "longeye": return 0.74
                "boomba": return 0.40
                "pyra": return 0.36
                "boomo": return 0.50
                "gloop": return 0.36
                "kolda": return 0.30
                "zappy": return 0.44
                "marshal": return 0.42
        return 0.0

## heads that never rotate (they are objects on the base, not turrets)
static func head_static(fid: String) -> bool:
        return fid == "kaching" or fid == "marshal"

# ------------------------------------------------------------------ helpers
static func imm_allows(kind: String, cls: String) -> bool:
        var imm: Array = BLOONS[kind]["imm"]
        if cls in imm:
                return false
        return true

static func dmg_vs(kind: String, cls: String, dmg: float) -> float:
        # the honest matrix: immunities block, the fat blimps halve sharp,
        # fire/energy pop lead
        if not imm_allows(kind, cls):
                return 0.0
        if BLOONS[kind].get("half_sharp", false) and cls == SHARP:
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
