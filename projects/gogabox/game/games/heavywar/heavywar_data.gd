class_name HWData
extends RefCounted
## HEAVY WAR: ROGUE ARSENAL (v040-5) - all the tables.
## v040-5 THE OWNER'S LAWS (the test report, worked to the bone):
##   * THE SCRAP LAW: every collected scrap is ONE scrap; every collected
##     XP orb is ONE point; the level totals are tuned to that. The scrap
##     bank survives the run - the SCRAP SHOP spends it (the HTML
##     prototype is the law: same 11 items, same costs, same caps).
##   * THE WEAPON LOCK LAW: the machine guns and the rocket pods DO NOT
##     EXIST until the shop unlocks them (MG BARRELS / ROCKET PODS); the
##     racks add one more per side.
##   * THE TANK LAYOUT LAW (the owner's drawing): rockets on the outer
##     hull edges, machine guns on the shoulders pointing UP ONLY, the
##     main cannon alone follows the aim from a turret TALLER than the
##     MGs (a 180-degree swing never overlaps them), wheels visible.
##   * NO MINI TANKS. Kills = score with a plane icon. No 4 dots.

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
const PLACES := [
        {"key": "iron", "name": "IRON WASTELAND", "ex": "hauler",
                "sky_top": Color("0b0d16"), "sky_bot": Color("5a3a22"),
                "sun": Color("ff7733"), "accent": Color("ff8844"),
                "ground_top": Color("3a261a"), "ground": Color("100a06")},
        {"key": "mesa", "name": "SCORCHED MESA", "ex": "dustdevil",
                "sky_top": Color("2a1828"), "sky_bot": Color("e08a44"),
                "sun": Color("ffd06a"), "accent": Color("ffb060"),
                "ground_top": Color("8a5030"), "ground": Color("40201a")},
        {"key": "tundra", "name": "FROZEN TUNDRA", "ex": "frostmoth",
                "sky_top": Color("08182c"), "sky_bot": Color("88aacc"),
                "sun": Color("f0f8ff"), "accent": Color("88ddff"),
                "ground_top": Color("a0c0e0"), "ground": Color("4a6a88")},
        {"key": "volcano", "name": "VOLCANIC CORE", "ex": "cinderbat",
                "sky_top": Color("1a0404"), "sky_bot": Color("7a2a0a"),
                "sun": Color("ff4400"), "accent": Color("ff6622"),
                "ground_top": Color("ff4400"), "ground": Color("100404")},
        {"key": "swamp", "name": "TOXIC SWAMP", "ex": "sporewasp",
                "sky_top": Color("08180f"), "sky_bot": Color("4a6a40"),
                "sun": Color("88ff44"), "accent": Color("88ee44"),
                "ground_top": Color("4a6a20"), "ground": Color("0e1a0a")},
        {"key": "crystal", "name": "CRYSTAL CAVERNS", "ex": "shardray",
                "sky_top": Color("18082a"), "sky_bot": Color("5a3a7a"),
                "sun": Color("dd88ff"), "accent": Color("cc66ff"),
                "ground_top": Color("8844cc"), "ground": Color("1e0c38")},
        {"key": "sky", "name": "SKY ARCHIPELAGO", "ex": "cloudray",
                "sky_top": Color("4a7ab8"), "sky_bot": Color("ddeeff"),
                "sun": Color("fff5cc"), "accent": Color("fff088"),
                "ground_top": Color("88bb88"), "ground": Color("3a5a3a")},
        {"key": "trench", "name": "ABYSSAL TRENCH", "ex": "deptheel",
                "sky_top": Color("020e18"), "sky_bot": Color("0e3a5a"),
                "sun": Color("44aadd"), "accent": Color("44eeff"),
                "ground_top": Color("1a4466"), "ground": Color("02060c")},
        {"key": "neon", "name": "NEON SPRAWL", "ex": "holodrone",
                "sky_top": Color("08021a"), "sky_bot": Color("3a0a5a"),
                "sun": Color("ff44aa"), "accent": Color("ff44cc"),
                "ground_top": Color("ff2288"), "ground": Color("04020e")},
        {"key": "void", "name": "THE VOID", "ex": "voidmaw",
                "sky_top": Color("000000"), "sky_bot": Color("200848"),
                "sun": Color("ffffff"), "accent": Color("aa44ff"),
                "ground_top": Color("6633cc"), "ground": Color("03000a")},
]

# ------------------------------------------------------------------ enemies
# move: straight/sine/hover/dive/ground/static/shadow.
# weapon: none/aimed/spread/bomb/cluster/bigbomb/homing/arc/laser.
# hp/speed in design px; size = the sprite's collision radius driver.
# xp  = the NUMBER of XP orbs dropped (one orb = ONE point - the owner's law)
# scrap = the NUMBER of scrap pieces dropped (one piece = ONE scrap)
# shreds = the enemy bursts into falling shrapnel on death (may hit the tank)
const ENEMIES := {
        "scout": {"hp": 14, "speed": 150, "size": 40, "xp": 2, "scrap": 2,
                "move": "straight", "weapon": "none"},
        "fighter": {"hp": 26, "speed": 120, "size": 56, "xp": 3, "scrap": 3,
                "move": "sine", "weapon": "aimed"},
        "bomber": {"hp": 48, "speed": 85, "size": 78, "xp": 5, "scrap": 5,
                "move": "straight", "weapon": "bomb", "shreds": 4},
        "heli": {"hp": 34, "speed": 95, "size": 60, "xp": 5, "scrap": 4,
                "move": "hover", "weapon": "aimed"},
        "kamikaze": {"hp": 18, "speed": 210, "size": 42, "xp": 3, "scrap": 2,
                "move": "dive", "weapon": "none"},
        "gunship": {"hp": 80, "speed": 70, "size": 76, "xp": 8, "scrap": 8,
                "move": "straight", "weapon": "spread", "shreds": 6},
        "shielded": {"hp": 40, "speed": 105, "size": 56, "xp": 6, "scrap": 5,
                "move": "hover", "weapon": "aimed", "shield": 30},
        "splitter": {"hp": 36, "speed": 125, "size": 52, "xp": 5, "scrap": 4,
                "move": "sine", "weapon": "none", "split": true},
        "missile": {"hp": 44, "speed": 90, "size": 58, "xp": 7, "scrap": 6,
                "move": "hover", "weapon": "homing"},
        "swarm": {"hp": 8, "speed": 230, "size": 26, "xp": 1, "scrap": 1,
                "move": "straight", "weapon": "none"},
        "gtank": {"hp": 110, "speed": 52, "size": 72, "xp": 8, "scrap": 9,
                "move": "ground", "weapon": "arc", "shreds": 6},
        "turret": {"hp": 70, "speed": 0, "size": 60, "xp": 8, "scrap": 6,
                "move": "static", "weapon": "aimed"},
        # ---- THE NEW WAR MACHINES (the owner's report) ----
        "carpet": {"hp": 90, "speed": 60, "size": 84, "xp": 8, "scrap": 12,
                "move": "straight", "weapon": "bigbomb", "shreds": 8},
        "shredder": {"hp": 55, "speed": 88, "size": 70, "xp": 6, "scrap": 8,
                "move": "sine", "weapon": "cluster", "shreds": 6},
        "laserd": {"hp": 60, "speed": 95, "size": 62, "xp": 7, "scrap": 9,
                "move": "shadow", "weapon": "laser"},
        # ---- place exclusives (key = the place's "ex") ----
        "hauler": {"hp": 60, "speed": 80, "size": 72, "xp": 7, "scrap": 8,
                "move": "hover", "weapon": "bomb", "shreds": 5},
        "dustdevil": {"hp": 24, "speed": 175, "size": 48, "xp": 4, "scrap": 3,
                "move": "sine", "weapon": "none"},
        "frostmoth": {"hp": 34, "speed": 115, "size": 60, "xp": 5, "scrap": 4,
                "move": "sine", "weapon": "aimed"},
        "cinderbat": {"hp": 22, "speed": 190, "size": 50, "xp": 4, "scrap": 3,
                "move": "dive", "weapon": "none"},
        "sporewasp": {"hp": 30, "speed": 145, "size": 52, "xp": 5, "scrap": 4,
                "move": "sine", "weapon": "aimed"},
        "shardray": {"hp": 44, "speed": 110, "size": 60, "xp": 6, "scrap": 5,
                "move": "hover", "weapon": "spread"},
        "cloudray": {"hp": 52, "speed": 100, "size": 66, "xp": 7, "scrap": 6,
                "move": "straight", "weapon": "homing"},
        "deptheel": {"hp": 40, "speed": 150, "size": 56, "xp": 6, "scrap": 5,
                "move": "sine", "weapon": "none"},
        "holodrone": {"hp": 26, "speed": 160, "size": 46, "xp": 5, "scrap": 4,
                "move": "hover", "weapon": "aimed", "shield": 20},
        "voidmaw": {"hp": 58, "speed": 120, "size": 62, "xp": 7, "scrap": 6,
                "move": "sine", "weapon": "spread"},
}

# shared pool every place draws from (small -> heavy), plus the exclusive
const SHARED_POOL := ["scout", "fighter", "bomber", "heli", "kamikaze",
        "gunship", "shielded", "splitter", "missile", "swarm", "gtank",
        "turret", "carpet", "shredder", "laserd"]

# place index (0-based) -> the enemy pool the waves roll from
static func pool_for(place_i: int) -> Array:
        var base := ["scout", "fighter", "swarm"]
        for e in SHARED_POOL:
                if not base.has(e):
                        base.append(e)
        var out := []
        for i in base.size():
                # the heavy machines join from place 2 onward (one per step)
                if i <= 2 or (place_i >= i - 2 and i <= 11) \
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
                "hp": 900, "size": 170},
        {"id": "reaver", "name": "DUST REAVER", "brain": "sidewinder",
                "hp": 1050, "size": 150},
        {"id": "titan", "name": "GLACIER TITAN", "brain": "dropship",
                "hp": 1250, "size": 175},
        {"id": "magma", "name": "MAGMA HEART", "brain": "fortress",
                "hp": 1450, "size": 170},
        {"id": "sporemother", "name": "SPORE MOTHER", "brain": "weaver",
                "hp": 1650, "size": 165},
        {"id": "prism", "name": "PRISM WARDEN", "brain": "fortress",
                "hp": 1900, "size": 165},
        {"id": "carrier", "name": "STORM CARRIER", "brain": "dropship",
                "hp": 2150, "size": 190},
        {"id": "leviathan", "name": "ABYSS LEVIATHAN", "brain": "weaver",
                "hp": 2400, "size": 200},
        {"id": "sovereign", "name": "GRID SOVEREIGN", "brain": "sidewinder",
                "hp": 2700, "size": 175},
        {"id": "avatar", "name": "THE NULL AVATAR", "brain": "prime",
                "hp": 3100, "size": 195},
]

# --------------------------------------------------------------- XP cards
# THE NO-CHEAT LAW (the owner): no magnet / scrap / coin cards here - the
# magnet lives in the SCRAP SHOP. Combat-only temporary boosts.
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
# THE HTML PROTOTYPE IS THE LAW: the same 11 items, the same costs, the
# same caps. cost = floor(base * step^level). Unlock items are one-shot.
const SHOP_ITEMS := [
        {"id": "wheels", "name": "REINFORCED WHEELS",
                "desc": "+1 wheel per level. +12% speed.",
                "base": 40, "step": 1.55, "max": 5},
        {"id": "armor", "name": "HULL PLATING",
                "desc": "+20 max hull per level.",
                "base": 50, "step": 1.6, "max": 8},
        {"id": "cannon", "name": "MAIN CANNON",
                "desc": "+22% shell damage per level.",
                "base": 70, "step": 1.7, "max": 8},
        {"id": "reload", "name": "AUTO-LOADER",
                "desc": "-10% all weapon cooldowns.",
                "base": 65, "step": 1.65, "max": 6},
        {"id": "scrapGain", "name": "SALVAGE CLAW",
                "desc": "+20% scrap from kills.",
                "base": 55, "step": 1.5, "max": 6},
        {"id": "xpGain", "name": "NEURAL LINK",
                "desc": "+20% XP gain.",
                "base": 55, "step": 1.5, "max": 6},
        {"id": "magnet", "name": "MAGNET COIL",
                "desc": "+35 pickup radius per level.",
                "base": 45, "step": 1.5, "max": 6},
        {"id": "rockets", "name": "ROCKET PODS",
                "desc": "Unlock 1 rocket pod per side.",
                "base": 120, "max": 1, "unlock": true},
        {"id": "rocket_rack", "name": "POD RACK",
                "desc": "+1 rocket per side, +15% rocket damage.",
                "base": 60, "step": 1.6, "max": 3, "requires": "rockets"},
        {"id": "mg", "name": "MG BARRELS",
                "desc": "Unlock 1 machine gun per side.",
                "base": 140, "max": 1, "unlock": true},
        {"id": "mg_rack", "name": "BARREL RACK",
                "desc": "+1 MG per side, +15% MG damage.",
                "base": 55, "step": 1.6, "max": 3, "requires": "mg"},
]

static func shop_item(id: String) -> Dictionary:
        for it in SHOP_ITEMS:
                if String(it["id"]) == id:
                        return it
        return {}

static func shop_cost(it: Dictionary, lvl: int) -> int:
        return int(float(it.get("base", 50)) * pow(float(it.get("step", 1.5)), lvl))

# the 5 tank skins stay BOX cosmetics (GOGACoins) - the box owns them
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
        var hp := float(def["hp"]) * (1.0 + float(place_i) * 0.18) \
                * (1.0 + float(loop - 1) * 1.1)
        return int(hp)

# the GOGACOIN law: after COIN_KILLS kills OR COIN_TIME seconds (whichever
# first) the NEXT enemy death carries a coin.
const COIN_KILLS := 22
const COIN_TIME := 40.0
