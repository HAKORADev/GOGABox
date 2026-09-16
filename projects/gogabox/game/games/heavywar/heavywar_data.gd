class_name HWData
extends RefCounted
## HEAVY WAR: ROGUE ARSENAL (v040-4) - all the tables. 100% our own design
## law (docs/goga_docs/gogames_ideas/heavywar/04_ROGUE_REWORK.md):
##   * 10 places x 10 waves, a boss after every 10th wave, 10 bosses
##   * waves ride TIME (max 3:00) and enemy budget; at the cap the budget
##     keeps growing until the field is clear
##   * health system (no lives), per-XP-level cards, kills = score
##   * enemies scale with the tank's power (place + level + loop + shop)
##   * shop = gogacoins: armor/cannon/mg/rockets/wheels/reload + 4 mini
##     tanks + skins; the magnet is a MINI TANK, never an upgrade card

const ART := "res://assets/games/heavywar/"

# ------------------------------------------------------------------- world
const SC := 2.0                       # art native px -> design px (x4 pngs at 0.5)
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
		"ground_top": Color("3a261a")},
	{"key": "mesa", "name": "SCORCHED MESA", "ex": "dustdevil",
		"sky_top": Color("2a1828"), "sky_bot": Color("e08a44"),
		"sun": Color("ffd06a"), "accent": Color("ffb060"),
		"ground_top": Color("8a5030")},
	{"key": "tundra", "name": "FROZEN TUNDRA", "ex": "frostmoth",
		"sky_top": Color("08182c"), "sky_bot": Color("88aacc"),
		"sun": Color("f0f8ff"), "accent": Color("88ddff"),
		"ground_top": Color("a0c0e0")},
	{"key": "volcano", "name": "VOLCANIC CORE", "ex": "cinderbat",
		"sky_top": Color("1a0404"), "sky_bot": Color("7a2a0a"),
		"sun": Color("ff4400"), "accent": Color("ff6622"),
		"ground_top": Color("ff4400")},
	{"key": "swamp", "name": "TOXIC SWAMP", "ex": "sporewasp",
		"sky_top": Color("08180f"), "sky_bot": Color("4a6a40"),
		"sun": Color("88ff44"), "accent": Color("88ee44"),
		"ground_top": Color("4a6a20")},
	{"key": "crystal", "name": "CRYSTAL CAVERNS", "ex": "shardray",
		"sky_top": Color("18082a"), "sky_bot": Color("5a3a7a"),
		"sun": Color("dd88ff"), "accent": Color("cc66ff"),
		"ground_top": Color("8844cc")},
	{"key": "sky", "name": "SKY ARCHIPELAGO", "ex": "cloudray",
		"sky_top": Color("4a7ab8"), "sky_bot": Color("ddeeff"),
		"sun": Color("fff5cc"), "accent": Color("fff088"),
		"ground_top": Color("88bb88")},
	{"key": "trench", "name": "ABYSSAL TRENCH", "ex": "deptheel",
		"sky_top": Color("020e18"), "sky_bot": Color("0e3a5a"),
		"sun": Color("44aadd"), "accent": Color("44eeff"),
		"ground_top": Color("1a4466")},
	{"key": "neon", "name": "NEON SPRAWL", "ex": "holodrone",
		"sky_top": Color("08021a"), "sky_bot": Color("3a0a5a"),
		"sun": Color("ff44aa"), "accent": Color("ff44cc"),
		"ground_top": Color("ff2288")},
	{"key": "void", "name": "THE VOID", "ex": "voidmaw",
		"sky_top": Color("000000"), "sky_bot": Color("200848"),
		"sun": Color("ffffff"), "accent": Color("aa44ff"),
		"ground_top": Color("6633cc")},
]

# ------------------------------------------------------------------ enemies
# shared pool + one exclusive per place. move: straight/sine/hover/dive/
# ground/static.  weapon: none/aimed/spread/bomb/homing/arc.
# hp/speed in design px; size = the sprite's collision radius driver.
const ENEMIES := {
	"scout": {"hp": 14, "speed": 150, "size": 40, "xp": 6,
		"move": "straight", "weapon": "none"},
	"fighter": {"hp": 26, "speed": 120, "size": 56, "xp": 10,
		"move": "sine", "weapon": "aimed"},
	"bomber": {"hp": 48, "speed": 85, "size": 78, "xp": 16,
		"move": "straight", "weapon": "bomb"},
	"heli": {"hp": 34, "speed": 95, "size": 60, "xp": 13,
		"move": "hover", "weapon": "aimed"},
	"kamikaze": {"hp": 18, "speed": 210, "size": 42, "xp": 9,
		"move": "dive", "weapon": "none"},
	"gunship": {"hp": 80, "speed": 70, "size": 76, "xp": 22,
		"move": "straight", "weapon": "spread"},
	"shielded": {"hp": 40, "speed": 105, "size": 56, "xp": 18,
		"move": "hover", "weapon": "aimed", "shield": 30},
	"splitter": {"hp": 36, "speed": 125, "size": 52, "xp": 14,
		"move": "sine", "weapon": "none", "split": true},
	"missile": {"hp": 44, "speed": 90, "size": 58, "xp": 18,
		"move": "hover", "weapon": "homing"},
	"swarm": {"hp": 8, "speed": 230, "size": 26, "xp": 4,
		"move": "straight", "weapon": "none"},
	"gtank": {"hp": 110, "speed": 52, "size": 72, "xp": 26,
		"move": "ground", "weapon": "arc"},
	"turret": {"hp": 70, "speed": 0, "size": 60, "xp": 20,
		"move": "static", "weapon": "aimed"},
	# ---- place exclusives (key = the place's "ex")
	"hauler": {"hp": 60, "speed": 80, "size": 72, "xp": 20,
		"move": "hover", "weapon": "bomb"},
	"dustdevil": {"hp": 24, "speed": 175, "size": 48, "xp": 11,
		"move": "sine", "weapon": "none"},
	"frostmoth": {"hp": 34, "speed": 115, "size": 60, "xp": 14,
		"move": "sine", "weapon": "aimed"},
	"cinderbat": {"hp": 22, "speed": 190, "size": 50, "xp": 12,
		"move": "dive", "weapon": "none"},
	"sporewasp": {"hp": 30, "speed": 145, "size": 52, "xp": 14,
		"move": "sine", "weapon": "aimed"},
	"shardray": {"hp": 44, "speed": 110, "size": 60, "xp": 16,
		"move": "hover", "weapon": "spread"},
	"cloudray": {"hp": 52, "speed": 100, "size": 66, "xp": 18,
		"move": "straight", "weapon": "homing"},
	"deptheel": {"hp": 40, "speed": 150, "size": 56, "xp": 16,
		"move": "sine", "weapon": "none"},
	"holodrone": {"hp": 26, "speed": 160, "size": 46, "xp": 12,
		"move": "hover", "weapon": "aimed", "shield": 20},
	"voidmaw": {"hp": 58, "speed": 120, "size": 62, "xp": 20,
		"move": "sine", "weapon": "spread"},
}

# shared pool every place draws from (small -> heavy), plus the exclusive
const SHARED_POOL := ["scout", "fighter", "bomber", "heli", "kamikaze",
	"gunship", "shielded", "splitter", "missile", "swarm", "gtank", "turret"]

# place index (0-based) -> the enemy pool the waves roll from
static func pool_for(place_i: int) -> Array:
	var base := ["scout", "fighter", "swarm"]
	var unlock_at := 2
	for e in SHARED_POOL:
		if not base.has(e):
			base.append(e)
	var out := []
	for i in base.size():
		if i == 0 or place_i >= i - 1:
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
# magnet is a mini tank in the shop. Combat-only temporary boosts.
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

# -------------------------------------------------------------------- shop
# permanent gogacoin shop. costs ramp base * step^level.
const SHOP_UPG := {
	"wheels": {"name": "REINFORCED WHEELS", "desc": "+1 wheel per level, +10% speed.",
		"base": 60, "step": 1.55, "max": 4},
	"armor": {"name": "HULL PLATING", "desc": "+20 max hull per level.",
		"base": 70, "step": 1.6, "max": 8},
	"cannon": {"name": "MAIN CANNON", "desc": "+20% shell damage per level.",
		"base": 90, "step": 1.65, "max": 8},
	"reload": {"name": "AUTO-LOADER", "desc": "-8% all weapon cooldowns.",
		"base": 80, "step": 1.6, "max": 6},
	"mg": {"name": "MG NESTS", "desc": "Twin machine guns on the hull.",
		"base": 150, "step": 1.7, "max": 1, "unlock": true},
	"mg_rack": {"name": "MG RACK", "desc": "+1 MG pair, +15% MG damage.",
		"base": 90, "step": 1.6, "max": 2, "requires": "mg"},
	"rockets": {"name": "ROCKET PODS", "desc": "Homing rocket pods.",
		"base": 180, "step": 1.7, "max": 1, "unlock": true},
	"rocket_rack": {"name": "POD RACK", "desc": "+1 rocket per salvo, +15% dmg.",
		"base": 110, "step": 1.6, "max": 2, "requires": "rockets"},
}

# THE 4 MINI TANKS (the owner's law): expensive gogacoins, each carries
# its own weapon on the tank's flank.
const MINIS := {
	"mt_rocket": {"name": "ROCKET MINI TANK", "desc": "A little brother that lobs heavy rockets.",
		"price": 900, "icon": "r_mt_rocket"},
	"mt_mg": {"name": "GUNNER MINI TANK", "desc": "Aim-able machine gun that tracks your aim.",
		"price": 1100, "icon": "r_mt_mg"},
	"mt_ice": {"name": "FROST MINI TANK", "desc": "Ice balls that slow whatever they touch.",
		"price": 1300, "icon": "r_mt_ice"},
	"mt_magnet": {"name": "MAGNET MINI TANK", "desc": "Collects every drop for the big tank.",
		"price": 800, "icon": "r_mt_magnet"},
}

const SKINS := {
	"olive": {"name": "THE OLIVE", "price": 0},
	"dune": {"name": "DUNE RUNNER", "price": 300},
	"frost": {"name": "WHITEOUT", "price": 450},
	"night": {"name": "NIGHT OPS", "price": 600},
	"magma": {"name": "MAGMA WORKS", "price": 900},
}

# ------------------------------------------------------------ the wave law
# budget = enemies this wave pours; interval = seconds between spawns.
# diff = the DYNAMIC ENEMY law: the tank grows, the war grows with it.
static func shop_index(mg: int, rk: int, armor: int, cannon: int,
		wheels: int, reload: int, minis: int) -> float:
	return float(mg + rk + armor + cannon + wheels + reload + minis * 2)

static func diff(place_i: int, level: int, loop: int, shop_i: float) -> float:
	return float(place_i) * 0.5 + float(level - 1) * 0.30 \
		+ float(loop - 1) * 1.5 + shop_i * 0.12

static func wave_budget(wave: int, place_i: int, loop: int, shop_i: float) -> int:
	var b := 6 + int(float(wave) * 1.9) + int(float(place_i) * 0.8) \
		+ (loop - 1) * 6 + int(shop_i * 1.2)
	return mini(b, 46)

static func wave_interval(wave: int, diffv: float) -> float:
	return maxf(0.34, 1.05 - float(wave) * 0.045 - diffv * 0.012)

static func boss_hp(place_i: int, loop: int, shop_i: float) -> int:
	var def: Dictionary = BOSSES[place_i % 10]
	var hp := float(def["hp"]) * (1.0 + float(place_i) * 0.18) \
		* (1.0 + float(loop - 1) * 1.1) * (1.0 + shop_i * 0.10)
	return int(hp)

# the GOGACOIN law: after COIN_KILLS kills OR COIN_TIME seconds (whichever
# first) the NEXT enemy death carries a coin.
const COIN_KILLS := 22
const COIN_TIME := 40.0
