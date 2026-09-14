class_name HWData
extends RefCounted
## HEAVY WAR - all the tables. Data-first: every number the game tunes lives
## here, born from the pack study (docs/goga_docs/gogames_ideas/heavywar/01_STUDY.md)
## and rewritten for the rogue-like law. Zero original-game bytes or names;
## the study's NUMBERS are the teacher, the words and art are ours.
##
## Score law (the owner's GDD): shared kills pay 1; the ten specials pay
## 10..100; run bonus = score /500 (the registry coin_div); +1 life per
## 1000 score, max 3; the tank wears 3 lives, each hit takes one.

const UPG_MAX := 5

# ------------------------------------------------------------------ enemies
# kind drives the movement brain; weapon drives the firing brain.
# hp/spd are the tier-1 truths; the director scales them with the run.
const ENEMIES := {
        "scout":     {"name": "SCOUT",     "hp": 1,   "spd": 190.0, "pts": 1,
                "kind": "sine",    "weapon": {},                          "w": 84,  "h": 30},
        "dart":      {"name": "DART",      "hp": 1,   "spd": 230.0, "pts": 1,
                "kind": "line",    "weapon": {"bomb": "dumb", "cd": 4.0}, "w": 80,  "h": 30},
        "raider":    {"name": "RAIDER",    "hp": 10,  "spd": 105.0, "pts": 1,
                "kind": "line",    "weapon": {"bomb": "dumb", "cd": 3.2}, "w": 120, "h": 44},
        "lynx":      {"name": "LYNX",      "hp": 6,   "spd": 170.0, "pts": 1,
                "kind": "sine",    "weapon": {"bomb": "guided", "cd": 3.6}, "w": 80, "h": 28},
        "komet":     {"name": "KOMET",     "hp": 10,  "spd": 300.0, "pts": 1,
                "kind": "ballistic", "weapon": {},                        "w": 44,  "h": 84},
        "skimmer":   {"name": "SKIMMER",   "hp": 75,  "spd": 330.0, "pts": 1,
                "kind": "sea",     "weapon": {},                          "w": 104, "h": 26},
        "fang":      {"name": "FANG",      "hp": 20,  "spd": 150.0, "pts": 1,
                "kind": "sine",    "weapon": {"bomb": "armored", "cd": 3.4}, "w": 100, "h": 34},
        "talon":     {"name": "TALON",     "hp": 30,  "spd": 140.0, "pts": 1,
                "kind": "sine",    "weapon": {"bomb": "frag", "cd": 3.0}, "w": 110, "h": 36},
        "wasp":      {"name": "WASP",      "hp": 20,  "spd": 230.0, "pts": 1,
                "kind": "swoop",   "weapon": {"gun": 0.9},                "w": 88,  "h": 60},
        "hornet":    {"name": "HORNET",    "hp": 25,  "spd": 130.0, "pts": 1,
                "kind": "hover",   "weapon": {"gun": 1.2},                "w": 92,  "h": 40},
        "mirror":    {"name": "MIRROR",    "hp": 80,  "spd": 120.0, "pts": 1,
                "kind": "guard",   "weapon": {"missile": 2.6},            "w": 100, "h": 33},
        "technical": {"name": "TECHNICAL", "hp": 40,  "spd": 95.0,  "pts": 10,
                "kind": "ground",  "weapon": {"rpg": 2.8},                "w": 92,  "h": 50},
        "carpet":    {"name": "CARPET",    "hp": 40,  "spd": 115.0, "pts": 20,
                "kind": "line",    "weapon": {"carpet": "dumb", "cd": 3.8}, "w": 150, "h": 48},
        "viper":     {"name": "VIPER",     "hp": 80,  "spd": 120.0, "pts": 30,
                "kind": "hover",   "weapon": {"missile": 2.4},            "w": 96,  "h": 50},
        "mammoth":   {"name": "MAMMOTH",   "hp": 180, "spd": 95.0,  "pts": 40,
                "kind": "hover",   "weapon": {"missile": 2.0},            "w": 112, "h": 54},
        "fortress":  {"name": "FORTRESS",  "hp": 90,  "spd": 100.0, "pts": 50,
                "kind": "line",    "weapon": {"bomb": "armored", "cd": 2.8}, "w": 150, "h": 48},
        "orbital":   {"name": "ORBITAL",   "hp": 200, "spd": 55.0,  "pts": 60,
                "kind": "orbit",   "weapon": {"laser": 2.2},              "w": 96,  "h": 100},
        "grinder":   {"name": "GRINDER",   "hp": 150, "spd": 80.0,  "pts": 70,
                "kind": "ground",  "weapon": {"gun": 1.6},                "w": 92,  "h": 56},
        "plowman":   {"name": "PLOWMAN",   "hp": 220, "spd": 70.0,  "pts": 80,
                "kind": "plow",    "weapon": {},                          "w": 112, "h": 56},
        "atomault":  {"name": "ATOMAULT",  "hp": 200, "spd": 85.0,  "pts": 90,
                "kind": "line",    "weapon": {"bomb": "atom", "cd": 4.5}, "w": 190, "h": 75},
        "zeppelin":  {"name": "ZEPPELIN",  "hp": 250, "spd": 55.0,  "pts": 100,
                "kind": "line",    "weapon": {"bomb": "dumb", "cd": 2.4}, "w": 280, "h": 80},
}

## the ten specials (pts 10..100) - the study's tier map, ours named
const SPECIALS := ["technical", "carpet", "viper", "mammoth", "fortress",
        "orbital", "grinder", "plowman", "atomault", "zeppelin"]

# ------------------------------------------------------------------ places
# palette: sky top / sky bottom / far silhouette / near silhouette /
# ground / road / accent. exclusive = the place's own specials.
# len = the pressure clock in seconds (the GDD's 3-10+ min per place).
const PLACES := [
        {"id": "frostkrai", "name": "FROSTKRAI",
                "sky": [Color("bfe3ff"), Color("eef9ff")], "far": Color("9cc8e8"),
                "near": Color("cfe6f5"), "ground": Color("e8f4fb"), "road": Color("b9cede"),
                "accent": Color("4f93c8"), "exclusive": ["atomault"],
                "props": ["pine", "igloo", "aurora"], "len": 180.0},
        {"id": "gulfgate", "name": "GULFGATE",
                "sky": [Color("8fd4e8"), Color("e6f7f2")], "far": Color("5da8b8"),
                "near": Color("8fc9c2"), "ground": Color("e8dcae"), "road": Color("c9b988"),
                "accent": Color("2f88a0"), "exclusive": ["skimmer"],
                "props": ["lighthouse", "buoy", "gulls"], "len": 200.0},
        {"id": "oilreach", "name": "OILREACH",
                "sky": [Color("f2c46a"), Color("faecc8")], "far": Color("b08a4a"),
                "near": Color("8a6a38"), "ground": Color("6e5230"), "road": Color("55402a"),
                "accent": Color("c07818"), "exclusive": ["technical"],
                "props": ["derrick", "flare", "tanks"], "len": 220.0},
        {"id": "nukeflats", "name": "NUKEFLATS",
                "sky": [Color("a8c87a"), Color("e2efd0")], "far": Color("7a9a58"),
                "near": Color("9ab06e"), "ground": Color("6a7a4a"), "road": Color("4f5c38"),
                "accent": Color("5a8a3a"), "exclusive": ["orbital"],
                "props": ["cooling", "barrel", "fence"], "len": 240.0},
        {"id": "vinebelt", "name": "VINEBELT",
                "sky": [Color("7ab85a"), Color("dcf0c8")], "far": Color("4a8a3e"),
                "near": Color("3a7a34"), "ground": Color("3e6e30"), "road": Color("2f5426"),
                "accent": Color("2e8a4a"), "exclusive": ["plowman"],
                "props": ["palm", "ruin", "river"], "len": 260.0},
        {"id": "gloomkeep", "name": "GLOOMKEEP",
                "sky": [Color("3a2e58"), Color("6a5a8a")], "far": Color("2a2044"),
                "near": Color("463a66"), "ground": Color("2c2440"), "road": Color("201a30"),
                "accent": Color("8a5ac8"), "exclusive": ["zeppelin"],
                "props": ["castle", "pines", "bats"], "len": 280.0},
        {"id": "ashfall", "name": "ASHFALL",
                "sky": [Color("8a7a72"), Color("c8bcb4")], "far": Color("6a5a52"),
                "near": Color("544840"), "ground": Color("4a4038"), "road": Color("38302a"),
                "accent": Color("c85a3a"), "exclusive": ["grinder"],
                "props": ["shell", "crater", "smoke"], "len": 300.0},
        {"id": "dunefort", "name": "DUNEFORT",
                "sky": [Color("f2b46a"), Color("fae4c0")], "far": Color("d09a52"),
                "near": Color("b8823e"), "ground": Color("e0b878"), "road": Color("c89c58"),
                "accent": Color("c87828"), "exclusive": ["carpet"],
                "props": ["dune", "fort", "tents"], "len": 320.0},
        {"id": "steelcrown", "name": "STEELCROWN",
                "sky": [Color("6a8ac8"), Color("c8d8f0")], "far": Color("4a6aa8"),
                "near": Color("3a5488"), "ground": Color("5a6272"), "road": Color("444c5a"),
                "accent": Color("3a78c8"), "exclusive": ["mammoth"],
                "props": ["tower", "antenna", "signs"], "len": 340.0},
        {"id": "ironhold", "name": "IRONHOLD",
                "sky": [Color("7a3434"), Color("b86858")], "far": Color("542424"),
                "near": Color("401c1c"), "ground": Color("3a2828"), "road": Color("2c1f1f"),
                "accent": Color("d84838"), "exclusive": ["viper", "fortress"],
                "props": ["wall", "hangar", "radar"], "len": 360.0},
]

# ------------------------------------------------------------------ waves
# recipes per pressure tier (1..5). Each recipe: units = [enemy, count,
# gap_s]; the director interleaves and stretches with the run knob.
const WAVES := {
        1: [
                {"u": [["scout", 6, 1.5]]},
                {"u": [["scout", 4, 1.4], ["dart", 4, 1.8]]},
                {"u": [["raider", 3, 3.0], ["scout", 5, 1.3]]},
                {"u": [["dart", 6, 1.6], ["lynx", 2, 3.0]]},
        ],
        2: [
                {"u": [["raider", 4, 2.6], ["lynx", 3, 2.4]]},
                {"u": [["talon", 3, 3.2], ["scout", 6, 1.1]]},
                {"u": [["wasp", 3, 2.8], ["dart", 5, 1.3]]},
                {"u": [["hornet", 3, 2.8], ["lynx", 4, 2.2]]},
                {"u": [["fang", 3, 3.0], ["scout", 8, 0.9]]},
        ],
        3: [
                {"u": [["carpet", 2, 4.0], ["wasp", 4, 2.4]]},
                {"u": [["viper", 2, 3.6], ["talon", 4, 2.6]]},
                {"u": [["komet", 5, 2.0], ["lynx", 4, 2.0]]},
                {"u": [["mirror", 2, 4.0], ["scout", 8, 0.9]]},
                {"u": [["fang", 4, 2.4], ["hornet", 3, 2.6]]},
        ],
        4: [
                {"u": [["mammoth", 2, 4.0], ["viper", 2, 3.2]]},
                {"u": [["fortress", 2, 3.6], ["wasp", 5, 2.2]]},
                {"u": [["technical", 3, 3.0], ["carpet", 2, 3.6]]},
                {"u": [["orbital", 1, 6.0], ["talon", 5, 2.2]]},
                {"u": [["grinder", 2, 3.4], ["hornet", 4, 2.4]]},
                {"u": [["skimmer", 4, 2.0], ["lynx", 5, 1.8]]},
        ],
        5: [
                {"u": [["fortress", 3, 3.0], ["mammoth", 2, 3.4]]},
                {"u": [["zeppelin", 1, 8.0], ["wasp", 6, 1.8]]},
                {"u": [["atomault", 1, 7.0], ["viper", 3, 2.8]]},
                {"u": [["plowman", 2, 4.5], ["grinder", 2, 3.2]]},
                {"u": [["orbital", 2, 5.0], ["carpet", 3, 3.0]]},
                {"u": [["mirror", 3, 3.2], ["fang", 5, 2.0]]},
                {"u": [["komet", 8, 1.4], ["skimmer", 4, 1.8]]},
        ],
}

# the shared pool: what any place may send. exclusive specials join it
# when the place wears them (01_STUDY section 2 draft).
const SHARED_FRY := ["scout", "dart", "raider", "lynx", "komet", "skimmer",
        "fang", "talon", "wasp", "hornet", "mirror"]

# ------------------------------------------------------------------ bosses
# every 5 places. comeback = n / 10 (the same face returns, faster).
# kind drives the fight brain; parts carry their own hp + fire.
const BOSS_ORDER := ["gunship", "dreadnought", "skystealer", "wreckball",
        "warhead", "kongo", "eyebot", "mechworm", "warbot", "secretfist"]

const BOSSES := {
        "gunship":     {"name": "THE GUNSHIP", "hp": 400,
                "parts": {"turret": {"hp": 120, "fire": 1.8},
                          "launcher": {"hp": 150, "fire": 2.6}}},
        "dreadnought": {"name": "THE DREADNOUGHT", "hp": 900,
                "parts": {"t1": {"hp": 70, "fire": 2.0}, "t2": {"hp": 90, "fire": 1.7},
                          "t3": {"hp": 90, "fire": 1.7}, "t4": {"hp": 70, "fire": 2.0},
                          "launcher": {"hp": 120, "fire": 2.5}}},
        "skystealer":  {"name": "THE SKYSTEALER", "hp": 1400,
                "parts": {"dish": {"hp": 0, "fire": 0.8},
                          "params": {"down": 8.0, "up": 4.0, "meteors": 12}}},
        "wreckball":   {"name": "THE WRECKBALL", "hp": 1600,
                "parts": {"params": {"chain": 1}}},
        "warhead":     {"name": "THE WARHEAD", "hp": 1800,
                "parts": {"l1": {"hp": 0, "fire": 1.0}, "l2": {"hp": 0, "fire": 1.5},
                          "params": {"delay": 5.0, "on": 0.35, "off": 0.35, "freq": 0.06}}},
        "kongo":       {"name": "KONGO", "hp": 2000,
                "parts": {"params": {"throw_cd": 1.6, "jump_cd": 6.0}}},
        "eyebot":      {"name": "THE EYEBOT", "hp": 1500,
                "parts": {"hand": {"hp": 400, "fire": 0.25},
                          "params": {"fire": 0.6}}},
        "mechworm":    {"name": "THE MECHWORM", "hp": 2000,
                "parts": {"turret": {"hp": 600, "fire": 0.8},
                          "params": {"depth": 500.0, "jump": 4.0, "boulders": 8}}},
        "warbot":      {"name": "THE WARBOT", "hp": 2200,
                "parts": {"arm": {"hp": 900}, "launcher": {"hp": 800, "fire": 1.8},
                          "params": {"eye": 3.0}}},
        "secretfist":  {"name": "THE SECRET FIST", "hp": 4000,
                "parts": {"bomb": {"hp": 0, "fire": 2.0}, "laser": {"hp": 0, "fire": 0.5},
                          "turret": {"hp": 0, "fire": 0.6}, "small": {"hp": 0, "fire": 1.2},
                          "big": {"hp": 0, "fire": 1.6}}},
}

## the comeback formula (01_STUDY section 4): the same face returns harder
static func boss_stats(boss_i: int) -> Dictionary:
        var base: Dictionary = BOSSES[BOSS_ORDER[boss_i % BOSS_ORDER.size()]]
        var cb := boss_i / BOSS_ORDER.size()
        var hp_mul := pow(2.2, minf(float(cb), 4.0))
        var fire_mul := maxf(0.5, pow(0.85, float(cb)))
        var spd_mul := minf(1.5, pow(1.06, float(cb)))
        return {"id": BOSS_ORDER[boss_i % BOSS_ORDER.size()], "comeback": cb,
                "hp": int(ceil(base["hp"] * hp_mul)), "hp_mul": hp_mul,
                "fire_mul": fire_mul, "spd_mul": spd_mul, "score": 100}

# ---------------------------------------------------------------- upgrades
# six stats x 5 levels = 30 points; each boss pays 1; the after-boss menu
# moves them (increase/decrease); permanent across runs.
# first 2 open; 4 shop-locked; prices provisional until ship.
const UPGRADES := {
        "engine":  {"name": "ENGINE",  "open": true,
                "desc": "the tank rolls faster", "shop_price": 0},
        "reload":  {"name": "RELOAD",  "open": true,
                "desc": "the gun breathes quicker", "shop_price": 0},
        "armor":   {"name": "ARMOR",   "open": false,
                "desc": "shield layers take more hits", "shop_price": 1200},
        "cannons": {"name": "CANNONS", "open": false,
                "desc": "more barrels in the fan", "shop_price": 1500},
        "shells":  {"name": "SHELLS",  "open": false,
                "desc": "every shell bites deeper", "shop_price": 1800},
        "aegis":   {"name": "AEGIS",   "open": false,
                "desc": "start stocked; bigger nukes; quicker laser", "shop_price": 2200},
}

## the per-level reads (lv 0..5) - one source of truth for the run
static func engine_speed(lv: int) -> float:
        return 900.0 + 130.0 * lv

static func reload_cd(lv: int) -> float:
        return 0.42 * pow(0.88, float(lv))

static func cannon_streams(lv: int) -> int:
        return mini(1 + lv, 5)

static func shell_dmg(lv: int) -> int:
        return 1 + lv

static func armor_layer_hp(lv: int) -> int:
        return 1 + lv

static func aegis_start_nukes(lv: int) -> int:
        return mini(1 + lv, 3)   # mercy: the war always starts with one

static func aegis_blast_w(lv: int) -> float:
        return 0.42 + 0.08 * lv   # fraction of the screen the nuke covers

static func aegis_laser_need(lv: int) -> int:
        return maxi(1, 3 - lv / 2)

# ------------------------------------------------------------------ drops
# the friend helicopter's crate table (weights; caps checked by the game)
const DROPS := [
        {"kind": "shield", "w": 30},
        {"kind": "nuke",   "w": 25},
        {"kind": "laser",  "w": 20},
        {"kind": "life",   "w": 10},
        {"kind": "coin",   "w": 15},
]
const COIN_DROP := 30           # gogacoin per crate (the every-3-places law)
const SUPPLY_PERIOD := 60.0     # a supply pass every ~60s in play

# ------------------------------------------------------------------ economy
const LIVES_MAX := 3
const SHIELD_MAX := 3
const NUKES_MAX := 3
const LIFE_PER_SCORE := 1000
const BOSS_PLACES := 5          # a boss every 5 places survived
const START_LASER_NEED := 3     # components to charge the laser (aegis trims)
const LASER_BURN := 6.0         # seconds the megabeam lives

# the shop (skins + 4 locked upgrades + the laser; provisional until ship)
const SKINS := {
        "olive":   {"name": "OLIVE",   "price": 0},
        "desert":  {"name": "DESERT",  "price": 800},
        "arctic":  {"name": "ARCTIC",  "price": 800},
        "navy":    {"name": "NAVY",    "price": 1000},
        "crimson": {"name": "CRIMSON", "price": 1200},
        "gold":    {"name": "GOLD",    "price": 2500},
}
const LASER_PRICE := 5000
