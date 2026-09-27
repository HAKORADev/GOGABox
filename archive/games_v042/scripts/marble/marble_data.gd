class_name MarbleData
extends RefCounted
## MARBLE POPPER - the data truth (v040-13). Places are the difficulty tiers
## (the owner's law: "places to be difficulties and designs, the more you
## progress the more it gets extra complexity and hard matches and more
## length and speed"). 100 levels / 10 places x 10. The level table lives in
## maps_data.gd (GENERATED, the pop siege embedded-copy law).

const A := "res://assets/games/marble/"

# ---------------------------------------------------------------- places
# key, display, bg file, track palette (groove, rim, glow), marble color count
const PLACES := [
        {"key": "mossy", "name": "MOSSY SHRINE", "bg": "bg_0_mossy.png",
                "track": Color(0.36, 0.30, 0.22), "rim": Color(0.20, 0.16, 0.11),
                "glow": Color(0.55, 0.85, 0.60), "colors": 3, "speed": 62.0},
        {"key": "sun", "name": "SUN STEPS", "bg": "bg_1_sun.png",
                "track": Color(0.55, 0.40, 0.26), "rim": Color(0.32, 0.22, 0.13),
                "glow": Color(1.0, 0.85, 0.55), "colors": 3, "speed": 66.0},
        {"key": "tide", "name": "TIDAL CAVE", "bg": "bg_2_tide.png",
                "track": Color(0.22, 0.36, 0.44), "rim": Color(0.10, 0.20, 0.26),
                "glow": Color(0.55, 0.90, 0.95), "colors": 4, "speed": 70.0},
        {"key": "ember", "name": "EMBER VAULT", "bg": "bg_3_ember.png",
                "track": Color(0.42, 0.20, 0.14), "rim": Color(0.24, 0.10, 0.08),
                "glow": Color(1.0, 0.55, 0.30), "colors": 4, "speed": 74.0},
        {"key": "frost", "name": "FROST HOLLOW", "bg": "bg_4_frost.png",
                "track": Color(0.52, 0.62, 0.74), "rim": Color(0.30, 0.38, 0.50),
                "glow": Color(0.90, 0.97, 1.0), "colors": 5, "speed": 78.0},
        {"key": "violet", "name": "VIOLET DEPTHS", "bg": "bg_5_violet.png",
                "track": Color(0.36, 0.26, 0.52), "rim": Color(0.20, 0.13, 0.30),
                "glow": Color(0.80, 0.60, 1.0), "colors": 5, "speed": 82.0},
        {"key": "sky", "name": "SKY RUINS", "bg": "bg_6_sky.png",
                "track": Color(0.60, 0.44, 0.40), "rim": Color(0.36, 0.24, 0.24),
                "glow": Color(1.0, 0.80, 0.62), "colors": 6, "speed": 86.0},
        {"key": "neon", "name": "NEON CATACOMB", "bg": "bg_7_neon.png",
                "track": Color(0.20, 0.24, 0.36), "rim": Color(0.10, 0.12, 0.20),
                "glow": Color(0.35, 0.95, 0.85), "colors": 6, "speed": 90.0},
        {"key": "obsidian", "name": "OBSIDIAN CORE", "bg": "bg_8_obsidian.png",
                "track": Color(0.30, 0.26, 0.22), "rim": Color(0.16, 0.13, 0.11),
                "glow": Color(1.0, 0.78, 0.35), "colors": 7, "speed": 94.0},
        {"key": "cursed", "name": "THE CURSED GATE", "bg": "bg_9_cursed.png",
                "track": Color(0.28, 0.18, 0.34), "rim": Color(0.14, 0.08, 0.18),
                "glow": Color(0.70, 0.40, 1.0), "colors": 7, "speed": 98.0},
]

# ---------------------------------------------------------------- marbles
# the 7 marble colors (the totemia color law) - the ids the level forges use
# 1 blue / 2 silver / 3 green / 4 purple / 5 cyan / 6 yellow / 7 red
const COLOR_NAME := {1: "BLUE", 2: "SILVER", 3: "GREEN", 4: "PURPLE",
        5: "CYAN", 6: "YELLOW", 7: "RED"}
# the reveal order: places 1-2 roll blue/green/yellow, then purple, cyan,
# silver and finally red joins (the owner's "places reveal more colors" law)
const COLOR_REVEAL := [1, 3, 6, 4, 5, 2, 7]
const COLOR_TINT := {
        1: Color(0.30, 0.45, 1.0), 2: Color(0.75, 0.82, 0.85),
        3: Color(0.30, 0.95, 0.30), 4: Color(0.70, 0.35, 0.95),
        5: Color(0.25, 0.85, 0.85), 6: Color(0.98, 0.85, 0.20),
        7: Color(1.0, 0.28, 0.28),
}

# ---------------------------------------------------------------- skins
# 5 + 5 + 5 (the owner's law) - classic rides free, the box shelf sells the rest
const PLAYER_SKINS := [
        {"id": "classic", "name": "CLASSIC TOTEM", "price": 0},
        {"id": "jade", "name": "JADE TOTEM", "price": 140},
        {"id": "obsidian", "name": "OBSIDIAN TOTEM", "price": 180},
        {"id": "royal", "name": "ROYAL TOTEM", "price": 240},
        {"id": "gold", "name": "GOLD TOTEM", "price": 320},
]
const MARBLE_SKINS := [
        {"id": "classic", "name": "CLASSIC CARVING", "price": 0, "style": 0},
        {"id": "petal", "name": "PETAL CARVING", "price": 140, "style": 1},
        {"id": "vine", "name": "VINE CARVING", "price": 180, "style": 2},
        {"id": "star", "name": "STAR CARVING", "price": 240, "style": 3},
        {"id": "tribal", "name": "TRIBAL CARVING", "price": 320, "style": 4},
]
const HOLE_SKINS := [
        {"id": "classic", "name": "STONE IDOL", "price": 0},
        {"id": "coral", "name": "CORAL IDOL", "price": 140},
        {"id": "gold", "name": "GILDED IDOL", "price": 180},
        {"id": "shadow", "name": "SHADOW IDOL", "price": 240},
        {"id": "soul", "name": "SOUL IDOL", "price": 320},
]

# ---------------------------------------------------------------- powers
# bought from the shop so they can spawn (the owner's law). Spawned as
# glowing marbles inside the chain; shot to collect; vanish unmatched in 10s.
const POWERS := [
        {"id": "back", "name": "PUSH BACK", "price": 200,
                "desc": "the whole chain slides backward"},
        {"id": "bomb", "name": "BOMB", "price": 260,
                "desc": "blasts every marble around the hit"},
        {"id": "speed", "name": "HIGH SPEED", "price": 260,
                "desc": "shots fly much faster for a while"},
        {"id": "vapor", "name": "VAPOR", "price": 300,
                "desc": "the chain dissolves marble by marble; matches eat wider"},
        {"id": "rainbow", "name": "RAINBOW", "price": 340,
                "desc": "your next 3 shots match any color"},
        {"id": "lightning", "name": "LIGHTNING", "price": 380,
                "desc": "zaps the chain's most common color"},
]
const POW_TINT := {
        "back": Color(0.35, 0.62, 1.0), "bomb": Color(1.0, 0.47, 0.31),
        "speed": Color(1.0, 0.82, 0.27), "vapor": Color(0.66, 0.51, 1.0),
        "rainbow": Color(1.0, 1.0, 1.0), "lightning": Color(0.47, 0.86, 1.0),
}

# ---------------------------------------------------------------- tables
const LEVELS_TOTAL := 100
const WAVES_PER_CHALLENGE := 10
const COIN_WAVES := 10          # a GOGACoin rides the chain every N waves
const COIN_LIFE := 5.0          # then flickers and fades (the owner's law)
const POW_LIFE := 10.0          # the unmatched powerup marble vanishes
const MARBLE_D := 96.0          # marble diameter (design px)
const CONTACT := MARBLE_D * 1.04
const CATCH_UP := 2.3           # the back-group chase multiplier
const SLOW_ZONE := 0.85         # last 15% of the path
const SLOW_MULT := 0.55         # the owner's "slow down before the hole"
const DANGER_ZONE := 0.88       # the idol's breath

# ---------------------------------------------------------------- v041 tuning
const INSERT_T := 0.22          # THE LIVING INSERT: push+settle duration
const ROLLBACK_MULT := 2.6      # THE POP-BACK LAW: faster than chain speed
const ROLLBACK_MIN := 190.0     #    (floor so early places still read fast)
const VAPOR_BASE := 0.02        # THE VAPOR SWEEP: stagger base + per-px step
const VAPOR_STEP := 0.0006      #    (marble after marble, quick but readable)

static func levels() -> Array:
        return MarbleMapsData.DATA["levels"]

static func level(i: int) -> Dictionary:
        return MarbleMapsData.DATA["levels"][clampi(i, 0, MarbleMapsData.DATA["levels"].size() - 1)]

static func place(pi: int) -> Dictionary:
        return PLACES[clampi(pi, 0, PLACES.size() - 1)]

## the color ids a place plays with (the reveal law)
static func place_colors(pi: int) -> Array:
        var n := int(place(pi)["colors"])
        return COLOR_REVEAL.slice(0, n)
