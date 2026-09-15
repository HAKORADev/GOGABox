class_name HWData
extends RefCounted
## HEAVY WAR - all the tables (v040-2). THE ORIGINAL'S OWN NUMBERS ride here,
## read straight out of the source game's data files (waves.xml, craft.xml,
## levels.xml, bosses.xml) - the owner's law: "the original has many xml and
## plain-code files for logic of waves and enemies ... read everything for real".
##
## Score law (the owner's GDD): shared kills pay 1; the ten specials pay
## 10..100; run bonus = score /500 (the registry coin_div); +1 life per
## 1000 score, max 3; the tank wears 3 lives, each hit takes one.

const UPG_MAX := 5

# THE SCALE LAW: the original screen is 640x480; ours is 1920x1080.
# Every original pixel scales by 1080/480 = 2.25 - the SAME factor for
# x and y (the owner's mis-scale report killed the mixed factors).
const SC := 2.25
# The original consumed its wave lengths at a stately cruise; the ground
# carries 69 original px per second (a 1000px wave lasts ~14.5s, a
# 10000px place ~2.4 min - the campaign's real rhythm).
const ORIG_PX_PER_SEC := 69.0
const GROUND_SPEED := ORIG_PX_PER_SEC * SC          # ~155 px/s on our road

# ------------------------------------------------------------------ enemies
# hp = the original craft.xml ARMOR (hit points against the basic gun).
# pts = the owner's GDD law (shared fry pay 1, the ten specials 10..100).
# kind drives the movement brain; weapon drives the firing brain.
## THE CRAFT TABLE v040-3 - hp IS the source's craft.xml armor verbatim;
## w/h are the TRUE strip cell sizes x SC (2.25) - measured off the source's
## own pixels, no invented numbers (the owner: 'use the original game
## values'). fps drives the sheet animation (rotors/props/treads). left =
## the chance a spawn enters from the LEFT edge (the owner: 'in original
## they can appear from both sides'); the rest enter from the right - and
## the body always FACES its travel direction.
const ENEMIES := {
        "scout":     {"name": "SCOUT",     "hp": 1,   "spd": 150.0, "pts": 1,
                "kind": "sine",    "weapon": {},
                "w": 63,  "h": 68,  "fps": 30.0, "left": 0.35},
        "dart":      {"name": "DART",      "hp": 1,   "spd": 185.0, "pts": 1,
                "kind": "line",    "weapon": {"bomb": "dumb", "cd": 4.0},
                "w": 180, "h": 68,  "fps": 0.0,  "left": 0.30},
        "raider":    {"name": "RAIDER",    "hp": 10,  "spd": 95.0,  "pts": 1,
                "kind": "line",    "weapon": {"bomb": "dumb", "cd": 3.2},
                "w": 270, "h": 99,  "fps": 0.0,  "left": 0.25},
        "lynx":      {"name": "LYNX",      "hp": 6,   "spd": 140.0, "pts": 1,
                "kind": "sine",    "weapon": {"bomb": "guided", "cd": 3.6},
                "w": 180, "h": 63,  "fps": 0.0,  "left": 0.30},
        "komet":     {"name": "KOMET",     "hp": 10,  "spd": 210.0, "pts": 1,
                "kind": "ballistic", "weapon": {},
                "w": 225, "h": 90,  "fps": 0.0,  "left": 0.0},
        "skimmer":   {"name": "SKIMMER",   "hp": 75,  "spd": 230.0, "pts": 1,
                "kind": "sea",     "weapon": {},
                "w": 203, "h": 203, "fps": 0.0,  "left": 0.30},
        "fang":      {"name": "FANG",      "hp": 20,  "spd": 125.0, "pts": 1,
                "kind": "sine",    "weapon": {"bomb": "armored", "cd": 3.4},
                "w": 225, "h": 77,  "fps": 0.0,  "left": 0.30},
        "talon":     {"name": "TALON",     "hp": 30,  "spd": 115.0, "pts": 1,
                "kind": "sine",    "weapon": {"bomb": "frag", "cd": 3.0},
                "w": 248, "h": 81,  "fps": 0.0,  "left": 0.25},
        "wasp":      {"name": "WASP",      "hp": 25,  "spd": 165.0, "pts": 1,
                "kind": "swoop",   "weapon": {"gun": 0.9},
                "w": 113, "h": 90,  "fps": 24.0, "left": 0.15},
        "hornet":    {"name": "HORNET",    "hp": 80,  "spd": 105.0, "pts": 1,
                "kind": "hover",   "weapon": {"missile": 2.6},
                "w": 225, "h": 135, "fps": 20.0, "left": 0.10},
        "mirror":    {"name": "MIRROR",    "hp": 80,  "spd": 95.0,  "pts": 1,
                "kind": "guard",   "weapon": {"missile": 2.6},
                "w": 225, "h": 74,  "fps": 0.0,  "left": 0.20},
        "strafer":   {"name": "STRAFER",   "hp": 20,  "spd": 195.0, "pts": 1,
                "kind": "swoop",   "weapon": {"gun": 0.8},
                "w": 191, "h": 162, "fps": 20.0, "left": 0.30},
        "technical": {"name": "TECHNICAL", "hp": 40,  "spd": 70.0,  "pts": 10,
                "kind": "ground",  "weapon": {"rpg": 2.8},
                "w": 203, "h": 135, "fps": 12.0, "left": 0.0},
        "carpet":    {"name": "CARPET",    "hp": 40,  "spd": 100.0, "pts": 20,
                "kind": "line",    "weapon": {"carpet": "dumb", "cd": 3.8},
                "w": 360, "h": 113, "fps": 0.0,  "left": 0.25},
        "viper":     {"name": "VIPER",     "hp": 180, "spd": 95.0,  "pts": 30,
                "kind": "hover",   "weapon": {"missile": 2.4},
                "w": 225, "h": 135, "fps": 16.0, "left": 0.10},
        "mammoth":   {"name": "MAMMOTH",   "hp": 180, "spd": 75.0,  "pts": 40,
                "kind": "hover",   "weapon": {"missile": 2.0},
                "w": 326, "h": 196, "fps": 16.0, "left": 0.10},
        "fortress":  {"name": "FORTRESS",  "hp": 90,  "spd": 85.0,  "pts": 50,
                "kind": "line",    "weapon": {"bomb": "armored", "cd": 2.8},
                "w": 360, "h": 97,  "fps": 0.0,  "left": 0.20},
        "orbital":   {"name": "ORBITAL",   "hp": 200, "spd": 40.0,  "pts": 60,
                "kind": "orbit",   "weapon": {"laser": 2.2},
                "w": 171, "h": 225, "fps": 8.0,   "left": 0.0},
        "grinder":   {"name": "GRINDER",   "hp": 150, "spd": 60.0,  "pts": 70,
                "kind": "ground",  "weapon": {"gun": 1.6},
                "w": 203, "h": 135, "fps": 12.0, "left": 0.0},
        "plowman":   {"name": "PLOWMAN",   "hp": 400, "spd": 52.0,  "pts": 80,
                "kind": "plow",    "weapon": {},
                "w": 315, "h": 203, "fps": 10.0, "left": 0.0},
        "atomault":  {"name": "ATOMAULT",  "hp": 300, "spd": 70.0,  "pts": 90,
                "kind": "line",    "weapon": {"bomb": "atom", "cd": 4.5},
                "w": 450, "h": 173, "fps": 0.0,  "left": 0.15},
        "zeppelin":  {"name": "ZEPPELIN",  "hp": 400, "spd": 45.0,  "pts": 100,
                "kind": "line",    "weapon": {"bomb": "dumb", "cd": 2.4},
                "w": 675, "h": 185, "fps": 0.0,  "left": 0.15},
}

## the ten specials (pts 10..100) - the study's tier map, ours named
const SPECIALS := ["technical", "carpet", "viper", "mammoth", "fortress",
        "orbital", "grinder", "plowman", "atomault", "zeppelin"]

# ------------------------------------------------------------------ places
# THE ORIGINAL'S OWN CAMPAIGN LENGTHS (levels.xml): FRIGISTAN 10000,
# BLASTNYA 15000, PETROVAKIA 25000, DICTASTROIKA 20000, ZAMBLAMIA /
# TANKYLVANIA / VODKAVANIA / ANTAGONISTAN / KILLINGRAD / RED STAR HQ 30000.
# len = ORIGINAL ground px; the run consumes them at ORIG_PX_PER_SEC.
const PLACES := [
        {"id": "frostkrai", "name": "FROSTKRAI", "len_orig": 10000,
                "exclusive": ["atomault"]},
        {"id": "gulfgate", "name": "GULFGATE", "len_orig": 15000,
                "exclusive": ["skimmer"]},
        {"id": "oilreach", "name": "OILREACH", "len_orig": 25000,
                "exclusive": ["technical"]},
        {"id": "nukeflats", "name": "NUKEFLATS", "len_orig": 20000,
                "exclusive": ["orbital"]},
        {"id": "vinebelt", "name": "VINEBELT", "len_orig": 30000,
                "exclusive": ["plowman"]},
        {"id": "gloomkeep", "name": "GLOOMKEEP", "len_orig": 30000,
                "exclusive": ["zeppelin"]},
        {"id": "ashfall", "name": "ASHFALL", "len_orig": 30000,
                "exclusive": ["grinder"]},
        {"id": "dunefort", "name": "DUNEFORT", "len_orig": 30000,
                "exclusive": ["carpet"]},
        {"id": "steelcrown", "name": "STEELCROWN", "len_orig": 30000,
                "exclusive": ["mammoth"]},
        {"id": "ironhold", "name": "IRONHOLD", "len_orig": 30000,
                "exclusive": ["viper", "fortress"]},
]

# ------------------------------------------------------------------ waves
# THE ORIGINAL'S OWN WAVES (data/waves.xml), VERBATIM: 19 levels, each a
# list of {len (original ground px), u: [[enemy, qty], ...]}. The ids are
# translated 1:1 onto our enemy table; nothing else is touched.
const WAVES_XML := [
        # Level 1
        {"len": 1000, "u": [["scout", 6], ["dart", 8]]},
        {"len": 1000, "u": [["raider", 2], ["scout", 3], ["dart", 5]]},
        {"len": 1000, "u": [["raider", 4], ["dart", 8]]},
        # Level 2
        {"len": 1100, "u": [["raider", 4], ["lynx", 4], ["dart", 5]]},
        {"len": 1100, "u": [["raider", 5], ["carpet", 2], ["dart", 4]]},
        {"len": 1100, "u": [["lynx", 5], ["scout", 7]]},
        {"len": 1000, "u": [["scout", 4], ["raider", 2], ["lynx", 2], ["carpet", 2]]},
        # Level 3
        {"len": 1200, "u": [["raider", 5], ["technical", 2], ["dart", 4]]},
        {"len": 1200, "u": [["wasp", 4], ["carpet", 3]]},
        {"len": 1200, "u": [["lynx", 5], ["raider", 4], ["carpet", 3]]},
        {"len": 1200, "u": [["hornet", 2], ["scout", 4], ["lynx", 5]]},
        # Level 4
        {"len": 1300, "u": [["talon", 5], ["fang", 7]]},
        {"len": 1300, "u": [["skimmer", 4], ["komet", 3], ["scout", 7]]},
        {"len": 1300, "u": [["wasp", 5], ["hornet", 3], ["dart", 4]]},
        {"len": 1300, "u": [["talon", 4], ["komet", 2], ["raider", 6], ["dart", 5]]},
        # Level 5
        {"len": 1400, "u": [["wasp", 3], ["hornet", 2], ["viper", 2]]},
        {"len": 1400, "u": [["fortress", 4], ["carpet", 5]]},
        {"len": 1400, "u": [["zeppelin", 4]]},
        {"len": 1400, "u": [["technical", 3], ["raider", 6], ["lynx", 8]]},
        # Level 6
        {"len": 1500, "u": [["atomault", 2], ["talon", 5], ["dart", 4]]},
        {"len": 1500, "u": [["strafer", 7], ["komet", 3]]},
        {"len": 1500, "u": [["fang", 14], ["carpet", 10]]},
        {"len": 1500, "u": [["mirror", 5], ["dart", 7]]},
        # Level 7
        {"len": 1600, "u": [["viper", 4], ["grinder", 3]]},
        {"len": 1600, "u": [["fortress", 6], ["fang", 10], ["komet", 2]]},
        {"len": 1600, "u": [["grinder", 3], ["skimmer", 8]]},
        {"len": 1600, "u": [["hornet", 7], ["fortress", 5]]},
        # Level 8
        {"len": 1700, "u": [["zeppelin", 4], ["strafer", 8]]},
        {"len": 1700, "u": [["carpet", 16], ["fortress", 8]]},
        {"len": 1700, "u": [["atomault", 3], ["skimmer", 7], ["fang", 10]]},
        {"len": 1700, "u": [["technical", 3], ["fortress", 5], ["viper", 3]]},
        # Level 9
        {"len": 1800, "u": [["orbital", 4], ["grinder", 3]]},
        {"len": 1800, "u": [["plowman", 3], ["fortress", 6], ["komet", 3]]},
        {"len": 1800, "u": [["skimmer", 8], ["viper", 5], ["hornet", 6]]},
        {"len": 1800, "u": [["mirror", 5], ["komet", 3], ["talon", 6]]},
        {"len": 1800, "u": [["zeppelin", 5], ["strafer", 10]]},
        # Level 10
        {"len": 2000, "u": [["wasp", 30]]},
        {"len": 2000, "u": [["hornet", 26]]},
        {"len": 2000, "u": [["viper", 16]]},
        {"len": 2000, "u": [["talon", 50]]},
        {"len": 2000, "u": [["fang", 50]]},
        {"len": 2000, "u": [["fortress", 22]]},
        {"len": 2000, "u": [["atomault", 7]]},
        {"len": 2000, "u": [["orbital", 10]]},
        {"len": 2000, "u": [["mirror", 10]]},
        # Level 11
        {"len": 2000, "u": [["carpet", 22], ["fortress", 10]]},
        {"len": 2000, "u": [["raider", 40], ["atomault", 5]]},
        {"len": 2000, "u": [["fortress", 10], ["talon", 13], ["carpet", 11]]},
        # Level 12
        {"len": 2000, "u": [["orbital", 4], ["zeppelin", 5], ["komet", 3]]},
        {"len": 2000, "u": [["grinder", 4], ["plowman", 2], ["komet", 3]]},
        {"len": 2000, "u": [["plowman", 4], ["skimmer", 12]]},
        {"len": 2000, "u": [["technical", 5], ["fortress", 8], ["strafer", 10], ["grinder", 4]]},
        # Level 13
        {"len": 2000, "u": [["mirror", 6], ["hornet", 7], ["viper", 5]]},
        {"len": 2000, "u": [["fortress", 8], ["carpet", 12], ["talon", 10], ["fang", 10]]},
        {"len": 2000, "u": [["strafer", 16], ["orbital", 6]]},
        {"len": 2000, "u": [["zeppelin", 4], ["skimmer", 9], ["fortress", 7]]},
        # Level 14
        {"len": 2000, "u": [["wasp", 15], ["hornet", 10], ["viper", 8]]},
        {"len": 2000, "u": [["viper", 8], ["grinder", 6]]},
        {"len": 2000, "u": [["plowman", 3], ["hornet", 4], ["wasp", 8]]},
        {"len": 2000, "u": [["viper", 16], ["komet", 4]]},
        {"len": 2000, "u": [["skimmer", 14], ["wasp", 10], ["viper", 6]]},
        # Level 15
        {"len": 2000, "u": [["mirror", 10], ["zeppelin", 4]]},
        {"len": 2000, "u": [["plowman", 3], ["fang", 15], ["talon", 10]]},
        {"len": 2000, "u": [["grinder", 4], ["strafer", 10], ["komet", 3]]},
        {"len": 2000, "u": [["orbital", 5], ["atomault", 4]]},
        # Level 16
        {"len": 2000, "u": [["strafer", 9], ["wasp", 9], ["mirror", 5]]},
        {"len": 2000, "u": [["orbital", 7], ["skimmer", 14]]},
        {"len": 2000, "u": [["fortress", 14], ["carpet", 15], ["talon", 16]]},
        {"len": 2000, "u": [["wasp", 10], ["hornet", 15], ["viper", 10]]},
        # Level 17
        {"len": 2000, "u": [["strafer", 10], ["grinder", 5], ["fortress", 10]]},
        {"len": 2000, "u": [["zeppelin", 5], ["atomault", 4]]},
        {"len": 2000, "u": [["fortress", 8], ["viper", 8], ["technical", 5]]},
        {"len": 2000, "u": [["komet", 3], ["fang", 15], ["hornet", 10], ["grinder", 3]]},
        # Level 18
        {"len": 2000, "u": [["orbital", 5], ["grinder", 5], ["komet", 4]]},
        {"len": 2000, "u": [["skimmer", 10], ["mirror", 8], ["viper", 8]]},
        {"len": 2000, "u": [["plowman", 4], ["zeppelin", 6]]},
        {"len": 2000, "u": [["fortress", 15], ["strafer", 20]]},
        {"len": 2000, "u": [["talon", 18], ["viper", 10], ["komet", 4]]},
        # Level 19
        {"len": 2000, "u": [["orbital", 5], ["mirror", 8], ["fang", 10]]},
        {"len": 2000, "u": [["fortress", 16], ["atomault", 6]]},
        {"len": 2000, "u": [["orbital", 5], ["grinder", 5], ["komet", 5]]},
        {"len": 1000, "u": [["hornet", 1], ["viper", 1], ["talon", 1],
                ["fang", 1], ["komet", 1], ["fortress", 1], ["orbital", 1],
                ["grinder", 1]]},
        {"len": 2000, "u": [["komet", 5], ["fortress", 10], ["strafer", 10], ["viper", 5]]},
        {"len": 2000, "u": [["plowman", 3], ["orbital", 5], ["skimmer", 10]]},
]

# ------------------------------------------------------------------ waves
# THE LEVEL LENS: how many of the flat WAVES_XML rows belong to each of
# the source's 19 levels (3+4+4+4+4+4+4+4+5+9+3+4+4+5+4+4+4+5+6 = 84).
const LEVEL_WAVE_COUNTS := [3, 4, 4, 4, 4, 4, 4, 4, 5, 9, 3, 4, 4, 5, 4,
        4, 4, 5, 6]

## the source's own slicing: level 0 = the first three waves, etc.
static func waves_for_level(lvl: int) -> Array:
        var i := 0
        var out: Array = []
        var target := clampi(lvl, 0, LEVEL_WAVE_COUNTS.size() - 1)
        for li in LEVEL_WAVE_COUNTS.size():
                var n: int = LEVEL_WAVE_COUNTS[li]
                if li == target:
                        for k in n:
                                out.append(WAVES_XML[i + k])
                        break
                i += n
        return out

# the shop (skins; the weapon systems ride the UPGRADES locks)
const SKINS := {
        "olive":   {"name": "OLIVE",   "price": 0},
        "desert":  {"name": "DESERT",  "price": 800},
        "arctic":  {"name": "ARCTIC",  "price": 800},
        "navy":    {"name": "NAVY",    "price": 1000},
        "crimson": {"name": "CRIMSON", "price": 1200},
        "gold":    {"name": "GOLD",    "price": 2500},
}

# every 5 places. THE ORIGINAL'S OWN NUMBERS (data/bosses.xml): Level1 =
# the first meeting, Level2 = the comeback (the source's own escalation).
# hp = the XML armor; parts carry the XML's armor + fire (frames/100 = s).
const BOSS_ORDER := ["gunship", "dreadnought", "skystealer", "wreckball",
        "warhead", "kongo", "eyebot", "mechworm", "warbot", "secretfist"]

const BOSSES := {
        "gunship":     {"name": "TWINBLADE", "hp": 300, "score": 10000,
                "parts": {"turret": {"hp": 80, "fire": 1.75},
                          "launcher": {"hp": 100, "fire": 2.5}}},
        "dreadnought": {"name": "BATTLESHIP", "hp": 800, "score": 20000,
                "parts": {"t1": {"hp": 60, "fire": 1.5}, "t2": {"hp": 60, "fire": 2.0},
                          "t3": {"hp": 60, "fire": 2.0}, "t4": {"hp": 60, "fire": 1.5},
                          "launcher": {"hp": 90, "fire": 2.5}}},
        "skystealer":  {"name": "WAR BLIMP", "hp": 2700, "score": 30000,
                "parts": {"dish": {"hp": 0, "fire": 0.8},
                          "params": {"down": 8.0, "up": 4.0, "meteors": 15}}},
        "wreckball":   {"name": "WAR WRECKER", "hp": 2500, "score": 40000,
                "parts": {"params": {"chain": 0}}},
        "warhead":     {"name": "BUSTCZAR", "hp": 2800, "score": 60000,
                "parts": {"l1": {"hp": 0, "fire": 1.0}, "l2": {"hp": 0, "fire": 1.5},
                          "params": {"delay": 5.0, "on": 0.3, "off": 0.3, "freq": 0.06}}},
        "kongo":       {"name": "KOMMIE KONG", "hp": 2500, "score": 50000,
                "parts": {"params": {"throw_cd": 1.6, "jump_cd": 6.0}}},
        "eyebot":      {"name": "EYEBOT", "hp": 1500, "score": 50000,
                "parts": {"hand": {"hp": 300, "fire": 0.2},
                          "params": {"fire": 0.6}}},
        "mechworm":    {"name": "MECHWORM", "hp": 2000, "score": 50000,
                "parts": {"turret": {"hp": 500, "fire": 0.6},
                          "params": {"depth": 500.0, "jump": 4.0, "boulders": 8}}},
        "warbot":      {"name": "X-BOT", "hp": 2200, "score": 70000,
                "parts": {"arm": {"hp": 750}, "launcher": {"hp": 700, "fire": 2.0},
                          "params": {"eye": 3.0}}},
        "secretfist":  {"name": "SECRET WEAPON", "hp": 15000, "score": 140000,
                "parts": {"bomb": {"hp": 0, "fire": 2.0}, "laser": {"hp": 0, "fire": 0.5},
                          "turret": {"hp": 0, "fire": 0.6}, "small": {"hp": 0, "fire": 1.2},
                          "big": {"hp": 0, "fire": 1.6}}},
}

## the comeback law rides the source's own Level2 blocks: the second
## meeting of a face is harder (armor x2.5, fire x1.6, the XML pair), and
## beyond that the loop compounds. boss_i = the global boss count.
static func boss_stats(boss_i: int) -> Dictionary:
        var face := boss_i % BOSS_ORDER.size()
        var lap := boss_i / BOSS_ORDER.size()
        var base: Dictionary = BOSSES[BOSS_ORDER[face]]
        # Level1 armor for the first meeting, Level2 for every return
        var armor_mul := 1.0 if lap == 0 else 2.5
        var fire_mul := 1.0 if lap == 0 else 0.62
        var spd_mul := 1.0 if lap == 0 else 1.25
        var extra := pow(1.35, maxf(0.0, float(lap) - 1.0))
        return {"id": BOSS_ORDER[face], "comeback": lap,
                "hp": int(ceil(base["hp"] * armor_mul * extra)),
                "hp_mul": armor_mul * extra, "fire_mul": fire_mul,
                "spd_mul": spd_mul, "score": int(base.get("score", 100))}

# ---------------------------------------------------------------- upgrades
# THE ORIGINAL'S SIX WEAPON SYSTEMS (the source binary's own words):
# SHIELD (orbiting deflector spheres), ROCKETS (extra rocket per level),
# FLAK CANNON, HOMING MISSILES, THE MEGALASER (four parts, "Increased
# power"), SPEED. Six tracks x 5 levels = 30 points; first two born free,
# four shop-locked (the GDD's price law; the laser costs the most).
const UPGRADES := {
        "speed":   {"name": "SPEED",   "open": true,  "icon": "upg_6",
                "desc": "the tank rolls faster", "shop_price": 0},
        "shield":  {"name": "SHIELD",  "open": true,  "icon": "upg_1",
                "desc": "orbiting deflector spheres", "shop_price": 0},
        "rockets": {"name": "ROCKETS", "open": false, "icon": "upg_4",
                "desc": "extra rocket per level", "shop_price": 1500},
        "flak":    {"name": "FLAK",    "open": false, "icon": "upg_3",
                "desc": "every shell bursts into flak", "shop_price": 1800},
        "homing":  {"name": "HOMING",  "open": false, "icon": "upg_2",
                "desc": "the shells seek the enemy", "shop_price": 2200},
        "laser":   {"name": "LASER",   "open": false, "icon": "upg_5",
                "desc": "increased power", "shop_price": 5000},
}

# the per-level reads (lv 0..5) - one source of truth for the run
static func engine_speed(lv: int) -> float:
        return 900.0 + 130.0 * lv

static func shell_dmg(tier: int) -> int:
        # THE GUN POWER LAW: the arm's five tiers (gun.png rows); the tier
        # climbs with pickups in the run and drops one on a hit.
        return 2 + 2 * clampi(tier, 0, 4)

static func armor_layer_hp(lv: int) -> int:
        return 1 + lv

static func rocket_volley(lv: int) -> int:
        return lv                      # rockets per auto-volley

static func flak_frags(lv: int) -> int:
        return lv * 2                  # fragments per shell burst

static func homing_turn(lv: int) -> float:
        return 2.2 * float(lv)         # rad/s the shell steers

static func laser_need() -> int:
        return 4                       # "Collect all four Megalaser parts"

static func laser_burn(lv: int) -> float:
        return 4.0 + 2.0 * lv          # "Increased power"

static func start_nukes() -> int:
        return 1                       # the mercy law: one in the magazine

# ------------------------------------------------------------------ drops
# the friend helicopter's crate table (weights; caps checked by the game)
const DROPS := [
        {"kind": "shield",   "w": 26, "icon": "pup_02", "crate": 0},
        {"kind": "nuke",     "w": 22, "icon": "pup_01", "crate": 1},
        {"kind": "gunpower", "w": 20, "icon": "pup_04", "crate": 2},
        {"kind": "speedup",  "w": 10, "icon": "pup_03", "crate": 3},
        {"kind": "laser",    "w": 12, "icon": "pup_07", "crate": 1},
        {"kind": "life",     "w": 6,  "icon": "pup_12", "crate": 3},
        {"kind": "coin",     "w": 14, "icon": "pup_05", "crate": 0},
]
const COIN_DROP := 1            # ONE COIN IS ONE COIN (the owner's law)
const SUPPLY_PERIOD := 45.0     # a supply pass every ~45s in play

# ------------------------------------------------------------------ economy
const LIVES_MAX := 3
const SHIELD_MAX := 3
const NUKES_MAX := 3
const LIFE_PER_SCORE := 1000
const BOSS_PLACES := 5          # a boss every 5 places survived
const LASER_PRICE := 5000
const GUN_TIERS := 5            # the arm's five rows (gun power tiers)
