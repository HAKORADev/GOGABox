class_name HWData
extends RefCounted
## HEAVY WAR (v040-6) - all the tables. The name is HEAVY WAR - no subtitle.
## v040-6 THE OWNER'S REPORT, worked to the bone:
##   * THE SHOP SPLIT: the SCRAP SHOP is a proper shop (the war's permanent
##     upgrades, paid in scrap) and the normal GOGABox SHOP is back in its
##     own place (skins, paid in GOGACoins, LOCKED until bought).
##   * THE NO-CHEAT SHOP LAW: the magnet coil, the salvage claw and the
##     neural link are GONE (the owner: "no permanent magnet or extra
##     scrap upgrades and also remove the extra XP"). 8 honest items.
##   * THE PRICE LAW: the old shelf was cheat-cheap ("someone could
##     literally finish the game in just 3 runs") - the real prices.
##   * THE COIN LAW: a GOGACoin drops after every 500 KILLS (not 22) and
##     it looks like the box's own coin. Bosses pay 5 direct.
##   * THE TANK LAYOUT LAW (the owner's drawing): the GROUND layer is WIDE
##     enough for every wheel, the BOTTOM layer is the SAME width and the
##     rockets live IN it, and only the UPPER layer is smaller - it wears
##     the machine guns on its shoulders.
##   * THE BALANCE LAW: enemies are heavier, they gain SHIELDS as the war
##     rolls on, the weapons hit a little softer - the fight breathes.

const ART := "res://assets/games/heavywar/"

# ------------------------------------------------------------------- world
const GROUND_H := 118.0               # the ground band (clears the 52dp banner)
const WORLD_SPEED := 190.0            # ground px/s of the scroll
const PLANE_FAR := 0.16
const PLANE_MID := 0.38
const PLANE_NEAR := 0.62
const PLANE_GROUND := 1.0

const WAVE_MAX_TIME := 180.0          # the 3:00 law
const WAVES_PER_PLACE := 10

# ------------------------------------------------------------- the 10 places
# "moon": a crescent moon rides this sky (the dark places); else a sun.
# "clouds": soft drifting cloud banks; "stars": a twinkling field.
const PLACES := [
        {"key": "iron", "name": "IRON WASTELAND", "ex": "hauler",
                "sky_top": Color("0b0d16"), "sky_bot": Color("5a3a22"),
                "sun": Color("ff7733"), "accent": Color("ff8844"),
                "ground_top": Color("3a261a"), "ground": Color("100a06"),
                "moon": false, "clouds": Color("6a4030"), "stars": false},
        {"key": "mesa", "name": "SCORCHED MESA", "ex": "dustdevil",
                "sky_top": Color("2a1828"), "sky_bot": Color("e08a44"),
                "sun": Color("ffd06a"), "accent": Color("ffb060"),
                "ground_top": Color("8a5030"), "ground": Color("40201a"),
                "moon": false, "clouds": Color("c07a50"), "stars": false},
        {"key": "tundra", "name": "FROZEN TUNDRA", "ex": "frostmoth",
                "sky_top": Color("08182c"), "sky_bot": Color("88aacc"),
                "sun": Color("f0f8ff"), "accent": Color("88ddff"),
                "ground_top": Color("a0c0e0"), "ground": Color("4a6a88"),
                "moon": false, "clouds": Color("d8e8f4"), "stars": false},
        {"key": "volcano", "name": "VOLCANIC CORE", "ex": "cinderbat",
                "sky_top": Color("1a0404"), "sky_bot": Color("7a2a0a"),
                "sun": Color("ff4400"), "accent": Color("ff6622"),
                "ground_top": Color("ff4400"), "ground": Color("100404"),
                "moon": false, "clouds": Color("5a1808"), "stars": false},
        {"key": "swamp", "name": "TOXIC SWAMP", "ex": "sporewasp",
                "sky_top": Color("08180f"), "sky_bot": Color("4a6a40"),
                "sun": Color("88ff44"), "accent": Color("88ee44"),
                "ground_top": Color("4a6a20"), "ground": Color("0e1a0a"),
                "moon": false, "clouds": Color("2a4a24"), "stars": false},
        {"key": "crystal", "name": "CRYSTAL CAVERNS", "ex": "shardray",
                "sky_top": Color("18082a"), "sky_bot": Color("5a3a7a"),
                "sun": Color("dd88ff"), "accent": Color("cc66ff"),
                "ground_top": Color("8844cc"), "ground": Color("1e0c38"),
                "moon": true, "clouds": Color("3a2a5a"), "stars": true},
        {"key": "sky", "name": "SKY ARCHIPELAGO", "ex": "cloudray",
                "sky_top": Color("4a7ab8"), "sky_bot": Color("ddeeff"),
                "sun": Color("fff5cc"), "accent": Color("fff088"),
                "ground_top": Color("88bb88"), "ground": Color("3a5a3a"),
                "moon": false, "clouds": Color("ffffff"), "stars": false},
        {"key": "trench", "name": "ABYSSAL TRENCH", "ex": "deptheel",
                "sky_top": Color("020e18"), "sky_bot": Color("0e3a5a"),
                "sun": Color("44aadd"), "accent": Color("44eeff"),
                "ground_top": Color("1a4466"), "ground": Color("02060c"),
                "moon": true, "clouds": Color("0a2a44"), "stars": true},
        {"key": "neon", "name": "NEON SPRAWL", "ex": "holodrone",
                "sky_top": Color("08021a"), "sky_bot": Color("3a0a5a"),
                "sun": Color("ff44aa"), "accent": Color("ff44cc"),
                "ground_top": Color("ff2288"), "ground": Color("04020e"),
                "moon": true, "clouds": Color("2a0a44"), "stars": true},
        {"key": "void", "name": "THE VOID", "ex": "voidmaw",
                "sky_top": Color("000000"), "sky_bot": Color("200848"),
                "sun": Color("ffffff"), "accent": Color("aa44ff"),
                "ground_top": Color("6633cc"), "ground": Color("03000a"),
                "moon": true, "clouds": Color("1a0a30"), "stars": true},
]

# ------------------------------------------------------------------ enemies
# move: straight/sine/hover/dive/ground/static/shadow/rush.
# weapon: none/aimed/spread/bomb/cluster/bigbomb/homing/arc/laser/rocketdrop.
# hp/speed in design px; size = the sprite's collision radius driver.
# xp  = the NUMBER of XP orbs dropped (one orb = ONE point - the owner's law)
# scrap = the NUMBER of scrap pieces dropped (one piece = ONE scrap)
# shreds = the enemy bursts into falling shrapnel on death (may hit the tank)
# v040-6: hp retuned HEAVIER (the instant-kill feel is dead), scrap income
# retuned LOWER (the shop is a war chest, not a vending machine).
const ENEMIES := {
        "scout": {"hp": 22, "speed": 150, "size": 40, "xp": 2, "scrap": 1,
                "move": "straight", "weapon": "none"},
        "fighter": {"hp": 44, "speed": 120, "size": 56, "xp": 3, "scrap": 2,
                "move": "sine", "weapon": "aimed"},
        "bomber": {"hp": 90, "speed": 85, "size": 78, "xp": 5, "scrap": 3,
                "move": "straight", "weapon": "bomb", "shreds": 4},
        "heli": {"hp": 60, "speed": 95, "size": 60, "xp": 5, "scrap": 2,
                "move": "hover", "weapon": "aimed"},
        "kamikaze": {"hp": 30, "speed": 215, "size": 42, "xp": 3, "scrap": 1,
                "move": "dive", "weapon": "none"},
        "gunship": {"hp": 150, "speed": 70, "size": 76, "xp": 8, "scrap": 5,
                "move": "straight", "weapon": "spread", "shreds": 6},
        "shielded": {"hp": 70, "speed": 105, "size": 56, "xp": 6, "scrap": 3,
                "move": "hover", "weapon": "aimed", "shield": 40},
        "splitter": {"hp": 64, "speed": 125, "size": 52, "xp": 5, "scrap": 2,
                "move": "sine", "weapon": "none", "split": true},
        "missile": {"hp": 80, "speed": 90, "size": 58, "xp": 7, "scrap": 3,
                "move": "hover", "weapon": "homing"},
        "swarm": {"hp": 14, "speed": 230, "size": 26, "xp": 1, "scrap": 1,
                "move": "straight", "weapon": "none"},
        "gtank": {"hp": 200, "speed": 52, "size": 72, "xp": 8, "scrap": 6,
                "move": "ground", "weapon": "arc", "shreds": 6},
        "turret": {"hp": 120, "speed": 0, "size": 60, "xp": 8, "scrap": 3,
                "move": "static", "weapon": "aimed"},
        # ---- the v040-5 war machines ----
        "carpet": {"hp": 170, "speed": 60, "size": 84, "xp": 8, "scrap": 7,
                "move": "straight", "weapon": "bigbomb", "shreds": 8},
        "shredder": {"hp": 100, "speed": 88, "size": 70, "xp": 6, "scrap": 4,
                "move": "sine", "weapon": "cluster", "shreds": 6},
        "laserd": {"hp": 110, "speed": 95, "size": 62, "xp": 7, "scrap": 4,
                "move": "shadow", "weapon": "laser"},
        # ---- THE ROCKET RUNNER (v040-6, the owner's report: fast, can not
        # be caught, drops rockets the whole way across) ----
        "raider": {"hp": 55, "speed": 285, "size": 50, "xp": 6, "scrap": 3,
                "move": "rush", "weapon": "rocketdrop", "shreds": 4},
        # ---- place exclusives (key = the place's "ex") ----
        "hauler": {"hp": 120, "speed": 80, "size": 72, "xp": 7, "scrap": 4,
                "move": "hover", "weapon": "bomb", "shreds": 5},
        "dustdevil": {"hp": 44, "speed": 175, "size": 48, "xp": 4, "scrap": 2,
                "move": "sine", "weapon": "none"},
        "frostmoth": {"hp": 62, "speed": 115, "size": 60, "xp": 5, "scrap": 2,
                "move": "sine", "weapon": "aimed"},
        "cinderbat": {"hp": 40, "speed": 190, "size": 50, "xp": 4, "scrap": 2,
                "move": "dive", "weapon": "none"},
        "sporewasp": {"hp": 54, "speed": 145, "size": 52, "xp": 5, "scrap": 2,
                "move": "sine", "weapon": "aimed"},
        "shardray": {"hp": 82, "speed": 110, "size": 60, "xp": 6, "scrap": 3,
                "move": "hover", "weapon": "spread"},
        "cloudray": {"hp": 96, "speed": 100, "size": 66, "xp": 7, "scrap": 3,
                "move": "straight", "weapon": "homing"},
        "deptheel": {"hp": 74, "speed": 150, "size": 56, "xp": 6, "scrap": 3,
                "move": "sine", "weapon": "none"},
        "holodrone": {"hp": 48, "speed": 160, "size": 46, "xp": 5, "scrap": 2,
                "move": "hover", "weapon": "aimed", "shield": 30},
        "voidmaw": {"hp": 106, "speed": 120, "size": 62, "xp": 7, "scrap": 4,
                "move": "sine", "weapon": "spread"},
}

# shared pool every place draws from (small -> heavy), plus the exclusive
const SHARED_POOL := ["scout", "fighter", "bomber", "heli", "kamikaze",
        "gunship", "shielded", "splitter", "missile", "swarm", "gtank",
        "turret", "carpet", "shredder", "laserd", "raider"]

# place index (0-based) -> the enemy pool the waves roll from
# THE SUICIDAL LAW (the owner: "make sure they exist anyway"): the
# kamikaze rides EVERY place from the first wave on.
static func pool_for(place_i: int) -> Array:
        var base := ["scout", "fighter", "swarm", "kamikaze"]
        for e in SHARED_POOL:
                if not base.has(e):
                        base.append(e)
        var out := []
        for i in base.size():
                # light crafts always; the heavies march in one per place;
                # the v040-6 machines (carpet..raider) join from place 4
                if i <= 3 or (place_i >= i - 3 and i <= 11) \
                                or (place_i >= 4 and i >= 12):
                        out.append(base[i])
        out.append(String(PLACES[place_i % 10]["ex"]))
        if place_i >= 10:
                out.append_array(SHARED_POOL)          # loop 2: everyone comes
        return out

# ------------------------------------------------------------------- bosses
# brain: flyer / dropship / sidewinder / fortress / weaver / prime
const BOSSES := [
        {"id": "colossus", "name": "SCRAP COLOSSUS", "brain": "flyer",
                "hp": 1250, "size": 170},
        {"id": "reaver", "name": "DUST REAVER", "brain": "sidewinder",
                "hp": 1500, "size": 150},
        {"id": "titan", "name": "GLACIER TITAN", "brain": "dropship",
                "hp": 1800, "size": 175},
        {"id": "magma", "name": "MAGMA HEART", "brain": "fortress",
                "hp": 2100, "size": 170},
        {"id": "sporemother", "name": "SPORE MOTHER", "brain": "weaver",
                "hp": 2400, "size": 165},
        {"id": "prism", "name": "PRISM WARDEN", "brain": "fortress",
                "hp": 2750, "size": 165},
        {"id": "carrier", "name": "STORM CARRIER", "brain": "dropship",
                "hp": 3100, "size": 190},
        {"id": "leviathan", "name": "ABYSS LEVIATHAN", "brain": "weaver",
                "hp": 3500, "size": 200},
        {"id": "sovereign", "name": "GRID SOVEREIGN", "brain": "sidewinder",
                "hp": 3950, "size": 175},
        {"id": "avatar", "name": "THE NULL AVATAR", "brain": "prime",
                "hp": 4500, "size": 195},
]

# --------------------------------------------------------------- XP cards
# THE NO-CHEAT LAW (the owner): no magnet / scrap / coin / xp cards here.
# Combat-only temporary boosts.
const CARDS := [
        {"id": "dmg", "name": "+20% DAMAGE", "desc": "All weapons hit harder.", "icon": "dmg"},
        {"id": "rate", "name": "+18% FIRE RATE", "desc": "Faster trigger pull.", "icon": "rate"},
        {"id": "speed", "name": "+15% MOVE SPEED", "desc": "Wheels grip the road.", "icon": "speed"},
        {"id": "hull", "name": "+25 MAX HULL", "desc": "Heal 25 and raise the cap.", "icon": "hull"},
        {"id": "heal", "name": "FULL REPAIR", "desc": "Restore all hull.", "icon": "heal"},
        {"id": "pierce", "name": "+1 PIERCE", "desc": "Shots pass through one enemy.", "icon": "pierce"},
        {"id": "explosive", "name": "EXPLOSIVE SHELLS", "desc": "Shells burst on impact.", "icon": "boom"},
        {"id": "lifesteal", "name": "LIFESTEAL 3%", "desc": "Damage repairs the hull.", "icon": "leech"},
        {"id": "multi", "name": "+1 SHELL", "desc": "The cannon fires an extra ball.", "icon": "multi"},
        {"id": "armor", "name": "+15% RESIST", "desc": "Take less damage.", "icon": "armor"},
        {"id": "cd", "name": "-15% COOLDOWN", "desc": "Weapons recover quicker.", "icon": "cd"},
        {"id": "shield", "name": "+40 SHIELD", "desc": "Absorbs hits before hull.", "icon": "shield"},
        {"id": "crit", "name": "+10% CRITICAL", "desc": "Chance to deal double.", "icon": "crit"},
        {"id": "bounce", "name": "RICOCHET", "desc": "Shells bounce to a second target.", "icon": "bounce"},
        {"id": "slow", "name": "CRYO SHELLS", "desc": "Shots chill and slow enemies.", "icon": "slow"},
]

# ---------------------------------------------------------- THE SCRAP SHOP
# THE PROPER SHOP (v040-6): 8 honest items, the magnet coil / salvage claw
# / neural link are DEAD (the owner's no-cheat law). The real prices - a
# full shelf costs tens of thousands of scrap, the war pays it run by run.
# cost = floor(base * step^level). Unlock items are one-shot.
const SHOP_ITEMS := [
        {"id": "wheels", "name": "REINFORCED WHEELS",
                "desc": "+1 wheel per level. +12% speed.",
                "base": 200, "step": 1.6, "max": 5},
        {"id": "armor", "name": "HULL PLATING",
                "desc": "+20 max hull per level.",
                "base": 240, "step": 1.6, "max": 8},
        {"id": "cannon", "name": "MAIN CANNON",
                "desc": "+22% shell damage per level.",
                "base": 280, "step": 1.6, "max": 8},
        {"id": "reload", "name": "AUTO-LOADER",
                "desc": "-10% all weapon cooldowns.",
                "base": 260, "step": 1.6, "max": 6},
        {"id": "rockets", "name": "ROCKET PODS",
                "desc": "Unlock 1 rocket pod per side.",
                "base": 800, "max": 1, "unlock": true},
        {"id": "rocket_rack", "name": "POD RACK",
                "desc": "+1 rocket per side, +15% rocket damage.",
                "base": 400, "step": 1.6, "max": 3, "requires": "rockets"},
        {"id": "mg", "name": "MG BARRELS",
                "desc": "Unlock 1 machine gun per side.",
                "base": 900, "max": 1, "unlock": true},
        {"id": "mg_rack", "name": "BARREL RACK",
                "desc": "+1 MG per side, +15% MG damage.",
                "base": 450, "step": 1.6, "max": 3, "requires": "mg"},
]

static func shop_item(id: String) -> Dictionary:
        for it in SHOP_ITEMS:
                if String(it["id"]) == id:
                        return it
        return {}

static func shop_cost(it: Dictionary, lvl: int) -> int:
        return int(float(it.get("base", 50)) * pow(float(it.get("step", 1.5)), lvl))

# the 5 tank skins stay BOX cosmetics (GOGACoins) - the box owns them,
# they live in the normal GOGABox SHOP (v040-6: the shop split).
const SKINS := {
        "olive": {"name": "THE OLIVE", "price": 0},
        "dune": {"name": "DUNE RUNNER", "price": 300},
        "frost": {"name": "WHITEOUT", "price": 450},
        "night": {"name": "NIGHT OPS", "price": 600},
        "magma": {"name": "MAGMA WORKS", "price": 900},
}

# the skins' steel palettes (hull gradient top / mid / bottom, turret tint,
# accent band) - the tank is CODE-DRAWN, a skin is a palette swap
const SKIN_COLORS := {
        "olive": {"hi": Color("5a6250"), "mid": Color("3a4034"),
                "lo": Color("1c2018"), "edge": Color("0a0c08"),
                "band": Color("8a9478"), "glow": Color("b8c4a0")},
        "dune": {"hi": Color("9a8860"), "mid": Color("6a5c40"),
                "lo": Color("38301e"), "edge": Color("14100a"),
                "band": Color("c8b088"), "glow": Color("e8d8b0")},
        "frost": {"hi": Color("9ab0bc"), "mid": Color("5a707c"),
                "lo": Color("28323a"), "edge": Color("0c1014"),
                "band": Color("c8dce8"), "glow": Color("e8f4ff")},
        "night": {"hi": Color("4a5060"), "mid": Color("2a2e3c"),
                "lo": Color("14161e"), "edge": Color("06070a"),
                "band": Color("6a7488"), "glow": Color("9aa8c8")},
        "magma": {"hi": Color("8a5240"), "mid": Color("5a3024"),
                "lo": Color("301810"), "edge": Color("120806"),
                "band": Color("c87850"), "glow": Color("ffb080")},
}

# ------------------------------------------------------------ the wave law
static func diff(place_i: int, level: int, loop: int, scrap_spent: int) -> float:
        # enemies scale with place + level + loop + the tank's SHOP power
        return float(place_i) * 0.5 + float(level - 1) * 0.30 \
                + float(loop - 1) * 1.5 + float(scrap_spent) * 0.06

static func wave_budget(wave: int, place_i: int, loop: int) -> int:
        var b := 6 + int(float(wave) * 1.9) + int(float(place_i) * 0.8) \
                + (loop - 1) * 6
        return mini(b, 46)

static func wave_interval(wave: int, diffv: float) -> float:
        return maxf(0.34, 1.05 - float(wave) * 0.045 - diffv * 0.012)

static func boss_hp(place_i: int, loop: int) -> int:
        var def: Dictionary = BOSSES[place_i % 10]
        var hp := float(def["hp"]) * (1.0 + float(place_i) * 0.22) \
                * (1.0 + float(loop - 1) * 1.1)
        return int(hp)

# the GOGACOIN law (v040-6): after COIN_KILLS kills the NEXT enemy death
# carries a real coin. No timer - the kill count is the whole law.
const COIN_KILLS := 500

# the boss's coin pay (direct, on top of the scrap rain)
const BOSS_COINS := 5
