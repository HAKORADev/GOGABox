extends GogaGame
## ROCK BREAKER (v040-7) - the endless bouncing-rock cannon arena,
## graduated from the CRAZE CAVES-LIKE parking-lot note (the owner's
## rename law: "the name feels like brick breaker but actually the game
## mechanic is different"). GDD: docs/goga_docs/gogames_ideas/rockbreaker.md.
## The teachers: Gamesnacks' Crazy Caves (readable bundle - the REAL
## curves live in the GDD's THE STUDY section) and Voodoo's Ball Blast
## (the two-wheeled cannon carriage, the cracked boulders). Everything
## shipped here is our own code-drawn work (the box law).
##
## THE OWNER'S LAWS (binding, from the v040-7 message):
##   - THE ROCKCOIN LAW: a broken rock pays rockCoins = its damage / 10
##     ("a 120-damage rock will give 12 rockCoins"); NO gem-coins.
##   - THE SCORE LAW: score = rockPoints = broken rocks this run
##     ("regardless of its level"), the run bonus is /250 (coin_div).
##   - THE GOLDEN LAW: after every 300 rockPoints a golden rock appears
##     with a HIDDEN 300..1000 damage pool; breaking it drops a real
##     GOGACoin; the next one counts 300 rockPoints from the COLLECTION.
##   - THE MYSTERY LAW: hidden 250..500 damage; the gift is one of
##     SLOW-DOWN / SHIELD / x2 THROW SPEED - "without the double throw
##     from crazy caves and without the extra cash thing".
##   - THE PERSISTENCE LAW: golden and mystery rocks never leave the
##     screen - they bounce until broken.
##   - THE COLOR LAW: a rock's level IS its color - "the intense-er the
##     longer" - and "rocks never have a maximum number of required
##     damage": the damage pool is unbounded, the heat keeps climbing.
##   - THE SIZE LAW: five sizes - "1 is one and 2 has two inside and 3
##     has 3 and 4 has 4 and 5 has 5"; a size-N rock's children roll
##     their own size in 1..N-1 ("one from 3 can be 2 or 1 but not
##     3-5"); size 1 is terminal.
##   - THE ENDLESS LAW: no levels, no menus - "endless play that lasts
##     forever until the player get crushed"; ONE touch of a rock and
##     the run is over ("one rock hit and it's over").
##   - THE PRESSURE LAW: "sizes are random but the required damage is
##     dynamic for long gameplay which means it has to be intense".
##   - THE SIDES LAW: rocks enter from different sides, angles and
##     speeds; "maximum rocks can spawn from sides are 30, 15 from each
##     side, maximum allowed rocks in screen are 50, if they are 45+ do
##     not spawn extra ones until user get rid off some of the rocks".
##     Children of a break always spawn - they were already inside.
##   - THE UPGRADE LAW: two shelves only - PROJECTILE ("more of them
##     means more shot/s", capped at 50) and DAMAGE ("the one shot will
##     deal extra +1 damage point for each upgrade", uncapped) - "no
##     third upgrade (in crazy caves it was cash)" - and the prices
##     climb steep: "a very long-term goal for the player".
##   - THE HOLD LAW: "controls will be like snowy tower and space
##     invaders where the left area for moving and right for shooting
##     (holding only, tapping will not spam shots here)". Vertical only.
##   - THE GATE LAW: "will start with tap anywhere to start", "no menus
##     required for it, simple and direct".
##   - THE BUTTON LAW: "shop button at the top left and upgrades button
##     next to it at the right".
##   - THE SHOP LAW: skins and themes, "5 and 5 where first is already
##     default"; the theme covers "the places and rocks skins packs".
##   - THE RIDE LAW: "the player will be canon with two wheels moving on
##     whatever you will make" - Ball Blast's carriage, ours.
##   - THE FIVE PLACES LAW: "you have to make 5 different views/places
##     for each theme" - the run walks them while it lives.
##   - THE THEME NAMES LAW: CAVE (default), FOREST, PIXEL, NEON, CANDY.
##   - THE NEON FILL LAW: neon rocks are "filled-from-inside neon, not
##     the empty one style".
##   - THE JUICE LAW: "cool and fun bouncing physics and rock flips and
##     VFXs and SFXs".
##   - THE NUMBER LAW: "big numbers after 999 will show as 1.00K and
##     1.00M and like that".
##
## Probe contract: the pure core is STATIC (fmt / price_proj / price_dmg /
## bps_for / dmg_for / children_sizes / rock_hp / ramp_color / pick_gift)
## and the scene rides probe_reset(seed) + probe_step(dt) + public arrays
## (rocks / bullets / fx) so the headless battery plays real frames.

# =========================================================== THE NUMBERS
const DESIGN_W := 1080.0        # the portrait design canvas (the static
const DESIGN_H := 1920.0        # pixels law: grows TALLER, never narrower)

const GROUND_H := 170.0         # the ground strip the cannon rides
const WALL_T := 14.0            # the arena's side wall thickness

const SIZES := 5                # THE SIZE LAW
const RADII := [36.0, 50.0, 66.0, 84.0, 104.0]
const SIZE_COEFF := [1.5, 1.3, 1.15, 1.0, 0.9]   # small flies faster (CC)
const SIZE_HP := [0.85, 0.95, 1.0, 1.1, 1.2]     # bigger carries a bit more
const SIZE_WEIGHT := [30, 30, 22, 12, 6]         # spawn weights (%)

const HP_BASE := 10.0           # THE HEAT CURVE: hp = (10 + 0.4 x heat)
const HP_SLOPE := 0.4           #   x size x wobble - linear, unbounded
const WOBBLE := 0.20            #   (+-20% per rock)

const GRAVITY := 560.0          # the bounce physics
const SPEED_MIN := 120.0
const SPEED_MAX := 980.0
const SPIN_RATE := 0.55         # the flip law: omega = vx / r * rate
const FLOOR_BOUNCE := 0.82      # v040-8 THE BOUNCE LAW: the ground is a
const GROUND_MIN_KICK := 320.0  # trampoline, never a shatterer (the
                                # original's law): every rock bounces

const SIDE_BUDGET := 15         # THE SIDES LAW: 15 alive spawns per side
const SCREEN_CAP := 50          #   50 on screen, hold at 45+
const HOLD_AT := 45
const BURST_MAX := 4            # v040-8 THE BURST LAW: the spawner pours
                                # 1..4 rocks per event (the original's
                                # "tons of them at one time")

const GOLDEN_EVERY := 300       # THE GOLDEN LAW (rockPoints since collect)
const GOLDEN_HP_MIN := 300
const GOLDEN_HP_MAX := 1000
const MYSTERY_EVERY := 120      # the mystery rock's counter
const MYSTERY_HP_MIN := 250
const MYSTERY_HP_MAX := 500

const BULLET_SPEED := 920.0       # v040-8: a VISIBLE shot, not a laser
const BULLET_R := 13.0            # v040-8: a real ball (was 7 - too small)
const BULLET_TRAIL := 9           # the comet trail's points
const FIRE_BASE := 4.0          # shots/s at projectile level 0 (CC law)
const PROJ_CAP := 50            # THE UPGRADE LAW: the projectile cap
const PROJ_PRICE0 := 12         #   12 x 1.75^n
const PROJ_GROW := 1.75
const DMG_PRICE0 := 20          #   20 x 1.9^n, uncapped
const DMG_GROW := 1.9

const SLOW_TIME := 8.0          # the mystery trio's clocks
const RUSH_TIME := 8.0
const SLOW_FACTOR := 0.45

const PLACE_EVERY := 200        # the five places rotate on rockPoints
const PLACE_FADE := 1.6

const COOLDOWN := 0.045         # per-rock hit immunity (the brick law)

# =========================================================== THE THEMES
## THE THEME LAW: every theme redraws the WORLD and the ROCKS its own
## way (the owner: "theme will cover the places and rocks skins packs").
## Each theme carries FIVE places (THE FIVE PLACES LAW): sky, far, near,
## ground and wall tones + a decor seed, and the run walks them.
const THEMES := {
    "cave": {"name": "CAVE", "price": 0, "style": "stone",
        "places": [
            {"sky": [Color("2b1d14"), Color("4a3320")], "far": Color("352417"),
                "near": Color("241710"), "ground": Color("3d2a1a"),
                "ground2": Color("2c1e12"), "wall": Color("1c1209"),
                "deco": Color("55402a"), "glow": Color(0, 0, 0, 0), "seed": 11},
            {"sky": [Color("14232a"), Color("1e3a42")], "far": Color("1b2f36"),
                "near": Color("122128"), "ground": Color("24424a"),
                "ground2": Color("193038"), "wall": Color("0e1a20"),
                "deco": Color("3d6a74"), "glow": Color(0.25, 0.83, 0.88, 0.15), "seed": 27},
            {"sky": [Color("2a120c"), Color("57200f")], "far": Color("43190d"),
                "near": Color("301107"), "ground": Color("5c2c14"),
                "ground2": Color("431f0d"), "wall": Color("240c05"),
                "deco": Color("8a4a1f"), "glow": Color(1.0, 0.48, 0.13, 0.2), "seed": 43},
            {"sky": [Color("1a2634"), Color("2b4258")], "far": Color("233447"),
                "near": Color("182430"), "ground": Color("37536b"),
                "ground2": Color("26394b"), "wall": Color("121c26"),
                "deco": Color("6f93ad"), "glow": Color(0.62, 0.85, 1.0, 0.12), "seed": 58},
            {"sky": [Color("292115"), Color("453719")], "far": Color("3a2e14"),
                "near": Color("271f0d"), "ground": Color("554218"),
                "ground2": Color("3d2f10"), "wall": Color("1f1808"),
                "deco": Color("8a6d2a"), "glow": Color(1.0, 0.79, 0.24, 0.18), "seed": 71},
        ],
        "desc": "the cave place and the cave rocks - the owner's first"},
    "forest": {"name": "FOREST", "price": 320, "style": "wood",
        "places": [
            {"sky": [Color("8fd0ef"), Color("c9ecf7")], "far": Color("5d9e5a"),
                "near": Color("3f7c42"), "ground": Color("6f9e4c"),
                "ground2": Color("58823a"), "wall": Color("2e5230"),
                "deco": Color("2f6134"), "glow": Color(0, 0, 0, 0), "seed": 13},
            {"sky": [Color("6db7d8"), Color("a8dcea")], "far": Color("2f6b3a"),
                "near": Color("1e4d2a"), "ground": Color("4a7d3a"),
                "ground2": Color("3a6630"), "wall": Color("173d20"),
                "deco": Color("143318"), "glow": Color(0, 0, 0, 0), "seed": 29},
            {"sky": [Color("e8b46a"), Color("f4d9a0")], "far": Color("b3703a"),
                "near": Color("8a4d28"), "ground": Color("a8793f"),
                "ground2": Color("8a6030"), "wall": Color("5c3618"),
                "deco": Color("c25a2a"), "glow": Color(1.0, 0.61, 0.25, 0.13), "seed": 47},
            {"sky": [Color("7cc4e0"), Color("b5e4f0")], "far": Color("4a8a6a"),
                "near": Color("2f6a4c"), "ground": Color("5a9a58"),
                "ground2": Color("478046"), "wall": Color("24503a"),
                "deco": Color("2a7060"), "glow": Color(0, 0, 0, 0), "seed": 61},
            {"sky": [Color("16233a"), Color("24385c")], "far": Color("1c3040"),
                "near": Color("122230"), "ground": Color("1e3a2e"),
                "ground2": Color("163024"), "wall": Color("0c1c14"),
                "deco": Color("2a5a44"), "glow": Color(0.62, 1.0, 0.88, 0.2), "seed": 83},
        ],
        "desc": "the woodland - the rocks are wood"},
    "pixel": {"name": "PIXEL", "price": 380, "style": "pixel",
        "places": [
            {"sky": [Color("3a6ea8"), Color("6aa3d8")], "far": Color("4a8a4a"),
                "near": Color("3a7038"), "ground": Color("8a6a3a"),
                "ground2": Color("6e5230"), "wall": Color("2a4a2a"),
                "deco": Color("2a5a2a"), "glow": Color(0, 0, 0, 0), "seed": 7},
            {"sky": [Color("123a6a"), Color("1e5a9a")], "far": Color("1a4a3a"),
                "near": Color("123a2a"), "ground": Color("5a4a2a"),
                "ground2": Color("463a20"), "wall": Color("0e2418"),
                "deco": Color("1a3a2a"), "glow": Color(1.0, 0.88, 0.29, 0.13), "seed": 19},
            {"sky": [Color("6a3a8a"), Color("9a5ab8")], "far": Color("4a2a6a"),
                "near": Color("381e52"), "ground": Color("6a4a5a"),
                "ground2": Color("543a46"), "wall": Color("2a1438"),
                "deco": Color("3a1a52"), "glow": Color(1.0, 0.54, 0.94, 0.13), "seed": 37},
            {"sky": [Color("0e1a2a"), Color("1a2a44")], "far": Color("102030"),
                "near": Color("0a1622"), "ground": Color("26364a"),
                "ground2": Color("1c2a3a"), "wall": Color("0a1220"),
                "deco": Color("1e3a54"), "glow": Color(0.42, 0.83, 1.0, 0.15), "seed": 53},
            {"sky": [Color("c85a4a"), Color("e8925a")], "far": Color("8a4a3a"),
                "near": Color("6a3628"), "ground": Color("a86a3a"),
                "ground2": Color("8a5430"), "wall": Color("5a2a1c"),
                "deco": Color("6a2a1a"), "glow": Color(1.0, 0.85, 0.29, 0.17), "seed": 67},
        ],
        "desc": "the pixel place - stepped blocks, big squares"},
    "neon": {"name": "NEON", "price": 440, "style": "neon",
        "places": [
            {"sky": [Color("0a0e22"), Color("141a3a")], "far": Color("101632"),
                "near": Color("0a0f24"), "ground": Color("181f42"),
                "ground2": Color("10152e"), "wall": Color("060a18"),
                "deco": Color("2a3a6a"), "glow": Color(0.29, 0.88, 1.0, 0.18), "seed": 17},
            {"sky": [Color("160a22"), Color("24143a")], "far": Color("1a1030"),
                "near": Color("100a20"), "ground": Color("241842"),
                "ground2": Color("181030"), "wall": Color("0c0618"),
                "deco": Color("3a2a6a"), "glow": Color(0.78, 0.29, 1.0, 0.18), "seed": 31},
            {"sky": [Color("02180f"), Color("06281a")], "far": Color("042014"),
                "near": Color("02180f"), "ground": Color("0a3020"),
                "ground2": Color("062418"), "wall": Color("021008"),
                "deco": Color("0a4a2e"), "glow": Color(0.29, 1.0, 0.63, 0.18), "seed": 49},
            {"sky": [Color("1a0e06"), Color("2a1a0c")], "far": Color("221408"),
                "near": Color("160c04"), "ground": Color("301e0e"),
                "ground2": Color("221608"), "wall": Color("120a04"),
                "deco": Color("4a3012"), "glow": Color(1.0, 0.66, 0.29, 0.18), "seed": 59},
            {"sky": [Color("0a1420"), Color("122236")], "far": Color("0e1c2c"),
                "near": Color("081420"), "ground": Color("16283c"),
                "ground2": Color("0e1e2e"), "wall": Color("060e18"),
                "deco": Color("1e3a54"), "glow": Color(1.0, 0.29, 0.54, 0.15), "seed": 73},
        ],
        "desc": "filled-from-inside neon - never hollow (the owner's law)"},
    "candy": {"name": "CANDY", "price": 500, "style": "candy",
        "places": [
            {"sky": [Color("ffd9ec"), Color("ffeedd")], "far": Color("ffb8d8"),
                "near": Color("f79ac2"), "ground": Color("ffe3b0"),
                "ground2": Color("f8d194"), "wall": Color("e88ab8"),
                "deco": Color("ff9ad2"), "glow": Color(0, 0, 0, 0), "seed": 23},
            {"sky": [Color("c8ecff"), Color("e8f8ff")], "far": Color("a8d8f0"),
                "near": Color("8ac2e8"), "ground": Color("fdf3d0"),
                "ground2": Color("f2e4b4"), "wall": Color("88c2e0"),
                "deco": Color("b0e0f8"), "glow": Color(0, 0, 0, 0), "seed": 41},
            {"sky": [Color("e0d0ff"), Color("f2e8ff")], "far": Color("c8aaf0"),
                "near": Color("b490e8"), "ground": Color("ffe8f4"),
                "ground2": Color("f8d8ea"), "wall": Color("a888d8"),
                "deco": Color("d8b8ff"), "glow": Color(0, 0, 0, 0), "seed": 57},
            {"sky": [Color("fff0c0"), Color("fff8dc")], "far": Color("ffd88a"),
                "near": Color("ffc878"), "ground": Color("ffe0c0"),
                "ground2": Color("f8d0aa"), "wall": Color("e8b878"),
                "deco": Color("ffe0a0"), "glow": Color(0, 0, 0, 0), "seed": 69},
            {"sky": [Color("d8f8e0"), Color("eefff2")], "far": Color("a8e8c0"),
                "near": Color("88d8a8"), "ground": Color("fde8f0"),
                "ground2": Color("f4d8e4"), "wall": Color("78cc98"),
                "deco": Color("b8f0d0"), "glow": Color(0, 0, 0, 0), "seed": 79},
        ],
        "desc": "the candy place - glossy sweets with sugar sheen"},
}

# =========================================================== THE SKINS
## THE SKIN LAW: 5 cannon skins, the first already default. A skin is a
## palette for the carriage: body, barrel, wheel, accent.
const SKINS := {
    "classic": {"name": "CLASSIC CANNON", "price": 0,
        "body": Color("5a6472"), "barrel": Color("424a56"),
        "wheel": Color("3a3f4a"), "rim": Color("ffb020"),
        "desc": "the steel original with amber rims"},
    "crimson": {"name": "CRIMSON CANNON", "price": 140,
        "body": Color("8a3038"), "barrel": Color("6a222a"),
        "wheel": Color("40242a"), "rim": Color("ffd24a"),
        "desc": "the war red with gold rims"},
    "mint": {"name": "MINT CANNON", "price": 180,
        "body": Color("3a8a6a"), "barrel": Color("2a6a50"),
        "wheel": Color("244038"), "rim": Color("e8fff4"),
        "desc": "the cool mint with pale rims"},
    "royal": {"name": "ROYAL CANNON", "price": 240,
        "body": Color("5a4a9a"), "barrel": Color("44367a"),
        "wheel": Color("30285a"), "rim": Color("ffd24a"),
        "desc": "the velvet purple with gold"},
    "gold": {"name": "GOLDEN CANNON", "price": 320,
        "body": Color("c89a2a"), "barrel": Color("a87a20"),
        "wheel": Color("6a4a14"), "rim": Color("fff0b0"),
        "desc": "the war chest's crown"},
}

# the color-heat ramp: THE COLOR LAW ("the intense-er the longer") -
# 24 steps, cool gray -> warm browns -> ember -> white-hot. Beyond the
# top the rock keeps the hottest tone and wears the heat shimmer.
const RAMP_STEPS := 24

# =========================================================== THE META
## The bank: rockCoins, the two upgrade levels, the records, the
## once-ever lore flag. Lives in the box save under games.rockbreaker.
const GAME := "rockbreaker"

var md := {}

func _meta_heal() -> void:
        var base := {
                "rockcoins": 0,
                "total_rockcoins": 0,
                "upg_proj": 0,
                "upg_dmg": 0,
                "best_rp": 0,
                "rocks_total": 0,
                "golden_total": 0,
                "shield_saves": 0,
                "plays": 0,
                "lore_seen": false,
        }
        for k in base:
                if not md.has(k):
                        md[k] = base[k]

func meta_save() -> void:
        Box.set_progress(GAME, "rb", md)

func rc_wallet() -> int:
        return int(md.get("rockcoins", 0))

func rc_bank(n: int) -> void:
        if n <= 0:
                return
        md["rockcoins"] = int(md.get("rockcoins", 0)) + n
        md["total_rockcoins"] = int(md.get("total_rockcoins", 0)) + n

func rc_spend(n: int) -> bool:
        if int(md.get("rockcoins", 0)) < n or n < 0:
                return false
        md["rockcoins"] = int(md["rockcoins"]) - n
        return true

# ====================================================== THE PURE CORE
## The static law functions - the headless battery reads these WITHOUT
## the scene (the squares contract).

## THE NUMBER LAW: 999 -> "999", 1000 -> "1.00K", 1254000 -> "1.25M".
static func fmt(n: int) -> String:
        var v := float(absi(n))
        var s := ""
        if v < 1000.0:
                s = str(n)
        elif v < 1000000.0:
                s = "%.2fK" % (v / 1000.0)
        elif v < 1000000000.0:
                s = "%.2fM" % (v / 1000000.0)
        elif v < 1000000000000.0:
                s = "%.2fB" % (v / 1000000000.0)
        else:
                s = "%.2fT" % (v / 1000000000000.0)
        return ("-" + s) if n < 0 else s

## THE UPGRADE LAW: the projectile level caps at 50, the damage level
## never does. The prices climb steep ("a very long-term goal").
static func proj_price(lvl: int) -> int:
        return int(round(PROJ_PRICE0 * pow(PROJ_GROW, lvl)))

static func dmg_price(lvl: int) -> int:
        return int(round(DMG_PRICE0 * pow(DMG_GROW, lvl)))

static func bps_for(proj_lvl: int) -> float:
        return FIRE_BASE + float(clampi(proj_lvl, 0, PROJ_CAP))

static func dmg_for(dmg_lvl: int) -> int:
        return 1 + dmg_lvl

## THE SIZE LAW: a size-N rock's children each roll their own size in
## 1..N-1 ("one from 3 can be 2 or 1 but not 3-5"); size 1 is terminal.
static func children_sizes(n: int, rng: RandomNumberGenerator) -> Array:
        var out: Array = []
        if n <= 1:
                return out
        for i in range(n):
                out.append(rng.randi_range(1, n - 1))
        return out

## THE HEAT CURVE: the demanded damage is dynamic - linear in the run's
## rockPoints (unbounded - "rocks never have a maximum number of
## required damage"), nudged by the rock's size and a +-20% wobble.
static func rock_hp(heat_rp: int, size: int, rng: RandomNumberGenerator) -> int:
        var base := HP_BASE + HP_SLOPE * float(heat_rp)
        base *= float(SIZE_HP[clampi(size - 1, 0, SIZES - 1)])
        base *= randf_range(1.0 - WOBBLE, 1.0 + WOBBLE)
        return maxi(4, int(round(base)))

## THE COLOR LAW: the ramp index from the damage pool - the intense-er
## the longer. Returns 0..RAMP_STEPS-1 (clamped; the top wears the
## shimmer instead of a new hue).
static func ramp_index(hp: int) -> int:
        return clampi(int(floor(log(maxf(1.0, float(hp))) / log(1.6))), 0,
                RAMP_STEPS - 1)

## the heat tint: cool gray -> warm browns -> ember -> white-hot
static func ramp_color(idx: int) -> Dictionary:
        var t := clampf(float(idx) / float(RAMP_STEPS - 1), 0.0, 1.0)
        var body: Color
        var facet: Color
        if t < 0.34:
                var u := t / 0.34
                body = Color(0.52, 0.55, 0.60).lerp(Color(0.55, 0.48, 0.40), u)
                facet = Color(0.68, 0.71, 0.76).lerp(Color(0.70, 0.62, 0.52), u)
        elif t < 0.68:
                var u2 := (t - 0.34) / 0.34
                body = Color(0.55, 0.48, 0.40).lerp(Color(0.72, 0.34, 0.16), u2)
                facet = Color(0.70, 0.62, 0.52).lerp(Color(0.92, 0.52, 0.28), u2)
        else:
                var u3 := (t - 0.68) / 0.32
                body = Color(0.72, 0.34, 0.16).lerp(Color(0.98, 0.72, 0.30), u3)
                facet = Color(0.92, 0.52, 0.28).lerp(Color(1.0, 0.92, 0.66), u3)
        return {"body": body, "facet": facet, "hot": t}

## THE MYSTERY LAW: exactly three gifts - the owner banned the double
## throw and the cash rain ("without the double throw from crazy caves
## and without the extra cash thing from it").
static func pick_gift(rng: RandomNumberGenerator) -> String:
        return ["slow", "shield", "rush"][rng.randi_range(0, 2)]

static func mystery_hp(rng: RandomNumberGenerator) -> int:
        return rng.randi_range(MYSTERY_HP_MIN, MYSTERY_HP_MAX)

static func golden_hp(rng: RandomNumberGenerator) -> int:
        return rng.randi_range(GOLDEN_HP_MIN, GOLDEN_HP_MAX)

# =========================================================== THE STATE
var us := 1.0                    # the design scale (vp.x / DESIGN_W)
var W := DESIGN_W                # the LIVE canvas (real viewport px -
var H := DESIGN_H                #  the spare-axis law: wider keeps W,
                                 #  taller keeps H; design consts x us)
var ground_y := DESIGN_H - GROUND_H
var rng := RandomNumberGenerator.new()

var phase := "boot"              # boot | play | over
var rocks: Array = []            # [{x,y,vx,vy,r,size,hp,hp0,golden,mystery,
                                 #   gift,rot,omega,sq,cd,seed,side,born}]
var bullets: Array = []          # [{x,y,vy,r}]
var fx: Array = []               # [{x,y,vx,vy,life,max,s,col,kind,rot,vr}]
var coins_fx: Array = []         # the rockCoin fly arcs (visual only)
var goga_fx: Array = []          # the GOGACoin fly (golden break)

var rp := 0                      # rockPoints (THE SCORE LAW)
var heat := 0                    # the spawn-era rockPoints (the heat)
var side_count := [0, 0]         # alive side-spawns [left, right]
var golden_alive := false
var mystery_alive := false
var rp_last_golden := 0          # 300 counted from the last COLLECTION
var rp_last_mystery := 0

var slow_t := 0.0                # the mystery trio's live clocks
var rush_t := 0.0
var shield := 0                  # the shield charges (0/1)

var place_i := 0                 # the five places walker
var place_next := PLACE_EVERY
var place_fade := 1.0            # the crossfade hand (1 = settled)
var place_from := 0

var spawn_t := 1.2               # the spawner's clock
var fire_cd := 0.0               # the hold-fire clock
var shake := 0.0                 # the earned screen shake
var _time := 0.0                 # the living clock

# the cannon (THE RIDE LAW: two wheels on the theme's ground)
var cannon_x := DESIGN_W * 0.5
var cannon_vx := 0.0
var wheel_rot := 0.0
var muzzle_t := 0.0
var muzzle_big := 0.0
var hit_flash := 0.0
var death_t := 0.0

# the touch law: LEFT half = the analog move, RIGHT half = HOLD to fire
var move_ptr := -1
var move_anchor := 0.0
var move_force := 0.0
var fire_ptr := -1
var mouse_fire := false          # the desktop rig's mouse
var touch_ui := false            # the heavywar controls law

# layout
var arena_top := 150.0
var hud_h := 150.0

# nodes
var bg_layer: Node2D = null
var rock_layer: Node2D = null
var char_layer: Node2D = null
var fx_layer: Node2D = null
var gate_ui: Control = null
var wallet_lbl: Label = null     # the rockCoins widget's label
var pow_lbls := {}               # the live powerup chips' labels
var _wallet_shown := -1
var _auto := false               # the qa auto-bot
var _auto_t := 0.0
var _auto_dir := 1.0

func _vp() -> Vector2:
        return get_viewport_rect().size

func _theme_id() -> String:
        var tid := Box.item_on(game_id, "theme")
        if not THEMES.has(tid):
                tid = "cave"
        return tid

func _theme() -> Dictionary:
        return THEMES[_theme_id()]

func _place() -> Dictionary:
        var th: Dictionary = _theme()
        var ps: Array = th["places"]
        return ps[place_i % ps.size()]

func _skin_id() -> String:
        var sid := Box.skin_on(game_id)
        if not SKINS.has(sid):
                sid = "classic"
        return sid

func _skin() -> Dictionary:
        return SKINS[_skin_id()]

# =============================================== THE ASSETS (v040-8)
## THE REAL ASSET LAW: the rocks, the cannon and the world are BAKED
## textures (tools/v0408_rock_art.py + v0408_rock_world.py - the Crazy
## Caves study sprites code-modified into our own), tinted at runtime by
## the heat ramp. The sky is a real shader (fx/rock_sky.gdshader).
const A := "res://assets/games/rockbreaker/"
const STYLE_PREFIX := {"stone": "cave", "wood": "forest", "pixel": "pixel",
        "neon": "neon", "candy": "candy"}
const SIZE_TEX := {1: "s", 2: "s", 3: "m", 4: "l", 5: "l"}

var _tex := {}                     # path -> Texture2D (loaded lazily)
var _sky_a: ColorRect = null       # the two sky layers (the crossfade pair)
var _sky_b: ColorRect = null
var _sky_mat_a: ShaderMaterial = null
var _sky_mat_b: ShaderMaterial = null

func _tex_at(rel: String) -> Texture2D:
        if not _tex.has(rel):
                _tex[rel] = load(A + rel)
        return _tex[rel]

func _rock_tex(style: String, size: int) -> Texture2D:
        return _tex_at("rocks/rock_%s_%s.png" % [style, SIZE_TEX[size]])

func _far_prefix() -> String:
        return STYLE_PREFIX.get(String(_theme()["style"]), "cave")

## the place's sky recipe (derived from the place's own palette - dark
## skies earn the stars and the moon automatically)
const SUN_POS := [Vector2(0.78, 0.15), Vector2(0.24, 0.13),
        Vector2(0.62, 0.11), Vector2(0.82, 0.18), Vector2(0.32, 0.14)]

func _sky_params(p: Dictionary, i: int) -> Dictionary:
        var top: Color = (p["sky"] as Array)[0]
        var bot: Color = (p["sky"] as Array)[1]
        var dark: bool = top.get_luminance() < 0.22
        var glow: Color = p["glow"]
        var sun := Color(1.0, 0.88, 0.55) if glow.a <= 0.0 \
                else Color(glow.r, glow.g, glow.b)
        return {
                "col_top": Vector3(top.r, top.g, top.b),
                "col_bot": Vector3(bot.r, bot.g, bot.b),
                "sun_col": Vector3(sun.r, sun.g, sun.b),
                "sun_pos": SUN_POS[i % 5],
                "moon": 1.0 if dark else 0.0,
                "stars": 1.0 if dark else 0.0,
                "cloud_col": Vector3(minf(1.0, bot.r + 0.25),
                        minf(1.0, bot.g + 0.25), minf(1.0, bot.b + 0.25)),
                "cloud_amt": 0.42 if dark else 0.6,
                "seed": float(p["seed"]),
        }

func _apply_sky(mat: ShaderMaterial, prm: Dictionary) -> void:
        for k in prm:
                mat.set_shader_parameter(k, prm[k])

## the pause END is a RUN-LIVE row only (the endless run banks here)
func _goga_pause_end_ok() -> bool:
        return phase == "play"

# ============================================================ SETUP
func _goga_setup() -> void:
        rng.randomize()
        game_id = GAME
        var vp := _vp()
        us = vp.x / DESIGN_W
        W = vp.x
        H = vp.y
        ground_y = H - GROUND_H * us
        # THE CONTROLS LAW: a touch screen's emulated mouse is DEAD (the
        # heavywar law) - the left finger must never become a mouse press.
        touch_ui = DisplayServer.is_touchscreen_available() \
                or OS.has_feature("mobile") or OS.has_feature("android")
        md = Box.get_progress(GAME, "rb", {})
        _meta_heal()
        set_score(0)
        _build_world()
        _build_hud_extra()
        add_hud_button("SHOP", func(): _shop_open())
        add_hud_button("UPGRADES", func(): _upgrades_open())
        pause_end_run = true
        phase = "boot"
        _build_gate()

func _layout() -> void:
        var vp := _vp()
        us = vp.x / DESIGN_W
        W = vp.x
        H = vp.y
        ground_y = H - GROUND_H * us
        hud_h = 150.0 * us + banner_bottom()
        arena_top = hud_h + 26.0 * us
        cannon_x = clampf(cannon_x, 70.0 * us, W - 70.0 * us)

func _build_world() -> void:
        _layout()
        # THE SKY (the shader law): two full-screen layers - the crossfade
        # blends the place's sky recipe from A into B while the run walks
        var sh: Shader = load("res://game/games/rockbreaker/fx/rock_sky.gdshader")
        _sky_mat_a = ShaderMaterial.new()
        _sky_mat_a.shader = sh
        _sky_mat_b = ShaderMaterial.new()
        _sky_mat_b.shader = sh
        _sky_a = ColorRect.new()
        _sky_a.material = _sky_mat_a
        _sky_a.set_anchors_preset(Control.PRESET_FULL_RECT)
        _sky_a.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _sky_b = ColorRect.new()
        _sky_b.material = _sky_mat_b
        _sky_b.set_anchors_preset(Control.PRESET_FULL_RECT)
        _sky_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(_sky_a)
        add_child(_sky_b)
        _apply_sky(_sky_mat_a, _sky_params(_place(), place_i))
        _apply_sky(_sky_mat_b, _sky_params(_place(), place_i))
        _sky_b.modulate.a = 0.0
        bg_layer = Node2D.new()
        add_child(bg_layer)
        bg_layer.draw.connect(_draw_bg)
        rock_layer = Node2D.new()
        add_child(rock_layer)
        rock_layer.draw.connect(_draw_rocks)
        char_layer = Node2D.new()
        add_child(char_layer)
        char_layer.draw.connect(_draw_char)
        fx_layer = Node2D.new()
        add_child(fx_layer)
        fx_layer.draw.connect(_draw_fx)

# ------------------------------------------------------------- the HUD
## v040-10 THE TOP BAR LAW (the owner: "the rockCoins widget still at
## bottom left while it should be upper right after the score widget"):
## the rockCoins wallet is a TOP-BAR chip now - add_hud_chip seats it
## right before the GOGACoins chip, after the score cluster, with the
## rock-coin icon on it. The live powerup chips stay under the top bar.
var rockcoin_icon := "res://assets/games/rockbreaker/world/rockcoin.png"

func _build_hud_extra() -> void:
        wallet_lbl = add_hud_chip("0", rockcoin_icon)
        for k in ["slow", "rush", "shield"]:
                var c := Label.new()
                c.add_theme_font_override("font", Arc.font_big())
                c.add_theme_font_size_override("font_size", int(22 * us) + 4)
                c.add_theme_color_override("font_color", Color(1, 1, 1))
                c.add_theme_color_override("font_outline_color",
                        Color(0, 0, 0, 0.9))
                c.add_theme_constant_override("outline_size", int(6 * us) + 2)
                c.position = Vector2(86 * us, (hud_h + 14 + 44 * (1 +
                        ["slow", "rush", "shield"].find(k))) * 1.0 * us)
                add_child(c)
                c.visible = false
                pow_lbls[k] = c

func _hud_tick() -> void:
        var ui_on: bool = phase == "play" and not paused \
                and _sheet_stack.is_empty()
        if wallet_lbl != null:
                var w := rc_wallet()
                if _wallet_shown != w:
                        _wallet_shown = w
                        wallet_lbl.text = fmt(w)
        _chip("slow", slow_t, "SLOW", Color(0.45, 0.75, 1.0), ui_on)
        _chip("rush", rush_t, "RUSH x2", Color(1.0, 0.55, 0.3), ui_on)
        var sh: Label = pow_lbls["shield"]
        sh.visible = shield > 0 and ui_on
        if shield > 0:
                sh.text = "SHIELD"

func _chip(k: String, t: float, word: String, col: Color, ui_on: bool) -> void:
        var l: Label = pow_lbls[k]
        l.visible = t > 0.0 and ui_on
        if l.visible:
                l.text = "%s %0.1f" % [word, t]
                l.add_theme_color_override("font_color", col)

# ============================================================= INPUT
# THE HOLD LAW: the LEFT half is the analog move zone - the first touch
# anchors, the X offset from the anchor is the force (the Snowy Tower
# law). The RIGHT half FIRES only while HELD - a tap taps nothing ("tap-
# ping will not spam shots here"). A finger takes its role at touchdown
# and keeps it until lift.
func _goga_input(event: InputEvent) -> void:
        if over:
                return
        if event is InputEventScreenTouch:
                var e := event as InputEventScreenTouch
                if e.pressed:
                        _touch_down(e.index, e.position)
                else:
                        _touch_up(e.index)
        elif event is InputEventScreenDrag:
                var d := event as InputEventScreenDrag
                if d.index == move_ptr:
                        move_force = clampf((d.position.x - move_anchor)
                                / (170.0 * us), -1.0, 1.0)
        elif event is InputEventMouseButton:
                if touch_ui:
                        return
                var m := event as InputEventMouseButton
                if m.pressed:
                        if phase == "boot":
                                _start_run()
                        else:
                                mouse_fire = true
                else:
                        mouse_fire = false
        elif event is InputEventMouseMotion:
                if touch_ui:
                        return
                pass

func _touch_down(idx: int, pos: Vector2) -> void:
        var px := pos.x
        if phase == "boot":
                _start_run()
                return
        if px < W * 0.5:
                if move_ptr == -1:
                        move_ptr = idx
                        move_anchor = px
                        move_force = 0.0
        else:
                if fire_ptr == -1:
                        fire_ptr = idx

func _touch_up(idx: int) -> void:
        if idx == move_ptr:
                move_ptr = -1
                move_force = 0.0
        elif idx == fire_ptr:
                fire_ptr = -1

func _start_run() -> void:
        if phase != "boot":
                return
        _gate_down()
        phase = "play"
        spawn_t = 1.0
        md["plays"] = int(md.get("plays", 0)) + 1
        meta_save()
        Jukebox.sfx("rb_start", -4.0)

# ======================================================== THE GATE
## THE GATE LAW: "tap anywhere to start" - the silent gate with the
## best line; the shop still sells (merchandise, not options).
func _build_gate() -> void:
        gate_ui = Control.new()
        gate_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
        gate_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
        gate_ui.draw.connect(_draw_gate)
        add_child(gate_ui)

func _draw_gate() -> void:
        if gate_ui == null or phase != "boot":
                return
        var c := gate_ui
        c.draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.28))
        var f := Arc.font_big()
        var cy := H * 0.36
        var title := "ROCK BREAKER"
        var sz := int(72 * us)
        c.draw_string_outline(f, Vector2(0, cy), title,
                HORIZONTAL_ALIGNMENT_CENTER, W, sz, int(10 * us) + 2,
                Color(0, 0, 0, 0.85))
        c.draw_string(f, Vector2(0, cy), title, HORIZONTAL_ALIGNMENT_CENTER,
                W, sz, Color(1, 0.86, 0.42))
        var sub := "TAP ANYWHERE TO START"
        var sz2 := int(34 * us)
        var pulse := 0.72 + 0.28 * sin(_time * 4.2)
        c.draw_string_outline(f, Vector2(0, cy + 90 * us), sub,
                HORIZONTAL_ALIGNMENT_CENTER, W, sz2, int(8 * us) + 2,
                Color(0, 0, 0, 0.85))
        c.draw_string(f, Vector2(0, cy + 90 * us), sub,
                HORIZONTAL_ALIGNMENT_CENTER, W, sz2,
                Color(1, 1, 1, pulse))
        var best := int(md.get("best_rp", 0))
        if best > 0:
                var line := "BEST  " + fmt(best) + "  ROCK POINTS"
                c.draw_string_outline(f, Vector2(0, cy + 150 * us), line,
                        HORIZONTAL_ALIGNMENT_CENTER, W, int(24 * us),
                        int(6 * us) + 2, Color(0, 0, 0, 0.8))
                c.draw_string(f, Vector2(0, cy + 150 * us), line,
                        HORIZONTAL_ALIGNMENT_CENTER, W, int(24 * us),
                        Color(1, 0.79, 0.24, 0.95))

func _gate_down() -> void:
        if gate_ui != null and is_instance_valid(gate_ui):
                gate_ui.visible = false

# ====================================================== THE RUN TICK
func _goga_tick(delta: float) -> void:
        _time += delta
        if phase == "boot":
                queue_redraw_all()
                return
        if phase == "play":
                _spawn_director(delta)
                _fire(delta)
                _powerups_tick(delta)
                _place_walk()
                _launch_marks_tick(delta)
                _auto_tick(delta)
                _save_t += delta
                if _save_t >= 15.0:
                        _save_t = 0.0
                        meta_save()
        _rock_physics(delta)
        _bullets_tick(delta)
        _coins_tick(delta)
        _fx_tick(delta)
        _cannon_tick(delta)
        if phase == "play":
                _touch_check()
        if shake > 0.0:
                shake = maxf(0.0, shake - delta * 26.0)
        if muzzle_t > 0.0:
                muzzle_t -= delta
        if hit_flash > 0.0:
                hit_flash -= delta
        if phase == "over":
                death_t += delta
                if death_t > 1.15 and not over:
                        _finish()
        _hud_tick()
        queue_redraw_all()

func queue_redraw_all() -> void:
        if bg_layer != null:
                bg_layer.queue_redraw()
        if rock_layer != null:
                rock_layer.queue_redraw()
        if char_layer != null:
                char_layer.queue_redraw()
        if fx_layer != null:
                fx_layer.queue_redraw()

func _total_rocks() -> int:
        return rocks.size()

# ------------------------------------------------- the place walker
## THE FIVE PLACES LAW: the run walks the theme's five views on
## rockPoints, a calm crossfade between them - the SKY crossfades through
## the two shader layers while the far strip + ground crossfade in the
## draw pass.
func _place_walk() -> void:
        # v040-10 THE PREWARM LAW (the owner's "extra background things
        # then they get deleted" report): both places' far strips load
        # BEFORE the fade begins - the handover never lazy-loads mid-
        # transition, so nothing pops in late and nothing vanishes after.
        if rp >= place_next:
                place_next += PLACE_EVERY
                place_from = place_i
                var th: Dictionary = _theme()
                place_i = (place_i + 1) % (th["places"] as Array).size()
                var prefix: String = STYLE_PREFIX.get(String(th["style"]),
                        "cave")
                var ps: Array = th["places"]
                var pi_from: int = ps.find(ps[place_from % ps.size()])
                var pi_to: int = ps.find(ps[place_i % ps.size()])
                pi_from = maxi(0, pi_from if pi_from >= 0 else place_from)
                pi_to = maxi(0, pi_to if pi_to >= 0 else place_i)
                _tex_at("world/far_%s_%d.png" % [prefix, pi_from % 5])
                _tex_at("world/far_%s_%d.png" % [prefix, pi_to % 5])
                _tex_at("world/ground_%s.png" % prefix)
                place_fade = 0.0
                # the sky handover: A keeps the old recipe, B takes the new
                if _sky_mat_a != null:
                        _apply_sky(_sky_mat_a, _sky_params(
                                ps[place_from % ps.size()], place_from))
                        _apply_sky(_sky_mat_b, _sky_params(
                                ps[place_i % ps.size()], place_i))
                        _sky_b.modulate.a = 0.0
        if place_fade < 1.0:
                place_fade = minf(1.0, place_fade + _goga_dt() / PLACE_FADE)
                if _sky_b != null:
                        _sky_b.modulate.a = place_fade

var _dt_acc := 1.0 / 60.0
var _save_t := 0.0
func _goga_dt() -> float:
        return _dt_acc

# ------------------------------------------------- the spawn director
## THE SIDES LAW: rocks enter from the LEFT and RIGHT walls at random
## heights, angles and speeds (wide ranges - no fixed lanes); at most 15
## alive side-spawns per side; the screen holds at most 50; at 45+ the
## spawner holds its breath until the herd thins. v040-8 THE BURST LAW:
## each spawn event pours 1..4 rocks (the original's "tons of them at
## one time"), and every event can also LAUNCH a rock up from the
## ground - it flies, arcs, and falls (the original's throw law).
func _spawn_director(delta: float) -> void:
        _dt_acc = delta
        # THE GOLDEN LAW: after every 300 rockPoints (counted from the
        # last COLLECTION) the golden rock rides in and never leaves.
        if not golden_alive and rp - rp_last_golden >= GOLDEN_EVERY \
                        and rocks.size() < SCREEN_CAP:
                golden_alive = true
                _spawn_special("golden")
                game_toast("A GOLDEN ROCK APPEARS")
        # THE MYSTERY LAW: the gift carrier on its own counter, also
        # never leaves the screen.
        if not mystery_alive and rp - rp_last_mystery >= MYSTERY_EVERY \
                        and rocks.size() < SCREEN_CAP:
                mystery_alive = true
                _spawn_special("mystery")
        spawn_t -= delta
        if spawn_t > 0.0:
                return
        # THE WIDE CLOCK: the interval breathes over a wide range and
        # tightens as the heat climbs (dynamic for long gameplay)
        var interval := maxf(0.55, 1.9 - float(heat) * 0.003)
        spawn_t = interval * rng.randf_range(0.55, 1.5)
        if rocks.size() >= HOLD_AT:
                return                     # the hold law: 45+ waits
        if rocks.size() >= SCREEN_CAP:
                return
        # THE BURST: 1..4 rocks per event, mixed sides and launches
        var burst := mini(rng.randi_range(1, BURST_MAX),
                HOLD_AT - rocks.size())
        for i in burst:
                var roll := rng.randf()
                if roll < 0.3:
                        _launch_up()       # thrown up, arcing, falling
                else:
                        var side := rng.randi_range(0, 1)
                        if side_count[side] >= SIDE_BUDGET:
                                side = 1 - side
                        if side_count[side] >= SIDE_BUDGET:
                                continue   # 15 alive spawns per side
                        _spawn_side_rock(side)

## THE GROUND LAUNCH (v040-8, v040-10 THE FAIR THROW LAW): a rock thrown
## UP from the ground - it climbs, arcs, and falls back. The throw never
## lands on the tank: the seat keeps a wide safe ring around the cannon,
## and a dust telegraph blooms at the spot before the rock leaves the
## ground (the owner: "something comes and kills me" - never again
## without warning)
const LAUNCH_TELEGRAPH := 0.5
var launch_marks: Array = []      # [{x, t}] the dust warnings

func _launch_up() -> void:
        # the SAFE RING: pick a seat at least 360 design-px from the cannon
        var lo_x := 120.0 * us
        var hi_x := W - 120.0 * us
        var x := 0.0
        for attempt in 12:
                x = rng.randf_range(lo_x, hi_x)
                if absf(x - cannon_x) > 360.0 * us:
                        break
        var size := _pick_size()
        var hp := rock_hp(heat, size, rng)
        launch_marks.append({"x": x, "t": LAUNCH_TELEGRAPH, "size": size,
                "hp": hp})
        _dust(x, ground_y - 14.0 * us, size)

## the telegraphed throws fire when their clock runs out
func _launch_marks_tick(delta: float) -> void:
        for m in launch_marks:
                m["t"] = float(m["t"]) - delta
        var fired: Array = []
        for m in launch_marks:
                if float(m["t"]) <= 0.0:
                        fired.append(m)
        for m in fired:
                launch_marks.erase(m)
                var r := _radius(int(m["size"]))
                var vy := -rng.randf_range(720.0, 1250.0) * us
                var vx := rng.randf_range(-260.0, 260.0) * us
                _add_rock(float(m["x"]), ground_y - r - 10.0 * us, vx, vy,
                        int(m["size"]), int(m["hp"]), -1)
                _dust(float(m["x"]), ground_y - 14.0 * us, int(m["size"]))
                Jukebox.sfx("rb_ground", -12.0, rng.randf_range(0.8, 1.05))

func _spawn_side_rock(side: int) -> void:
        var size := _pick_size()
        var hp := rock_hp(heat, size, rng)
        _spawn_side_rock_ex(side, size, hp, false, false, "")

## the golden / mystery entrances ride the same walls
func _spawn_special(kind: String) -> void:
        if kind == "golden":
                _spawn_side_rock_ex(rng.randi_range(0, 1), 3,
                        golden_hp(rng), true, false, "")
        else:
                _spawn_side_rock_ex(rng.randi_range(0, 1), 2,
                        mystery_hp(rng), false, true, "")

func _spawn_side_rock_ex(side: int, size: int, hp: int, golden: bool,
                mystery: bool, gift: String) -> void:
        var r := _radius(size, golden, mystery)
        # THE WIDE BAND: heights spread across the whole upper arena - no
        # fixed lanes (the owner: "there is no high randomized ranges")
        var y := rng.randf_range(arena_top + r + 40.0 * us,
                minf(ground_y - r - 200.0 * us, arena_top + 760.0 * us))
        # THE WIDE SPEED: the full design range, size-coefficient shaped
        var speed_base := rng.randf_range(200.0, 760.0)
        speed_base *= float(SIZE_COEFF[size - 1])
        speed_base *= minf(1.6, 1.0 + float(heat) / 2500.0)
        speed_base *= us
        # THE WIDE ANGLE: mixed in-angles, sometimes thrown DOWN along the
        # wall, sometimes flat - never one behavior
        var ang := rng.randf_range(-0.75, 0.75)
        var vx := cos(ang) * speed_base
        var vy := sin(ang) * speed_base
        if rng.randf() < 0.3:
                vy = -absf(vy)            # lobbed upward as it enters
        if side == 1:
                vx = -absf(vx)
        else:
                vx = absf(vx)
        var x := (WALL_T * us + r) if side == 0 else (W - WALL_T * us - r)
        _add_rock(x, y, vx, vy, size, hp, side, golden, mystery, gift)
        if side >= 0:
                side_count[side] += 1

func _pick_size() -> int:
        var roll := rng.randi_range(1, 100)
        var acc := 0
        for i in SIZE_WEIGHT.size():
                acc += int(SIZE_WEIGHT[i])
                if roll <= acc:
                        return i + 1
        return 1

func _radius(size: int, golden := false, mystery := false) -> float:
        if golden:
                return 76.0 * us
        if mystery:
                return 56.0 * us
        return float(RADII[clampi(size - 1, 0, SIZES - 1)]) * us

func _add_rock(x: float, y: float, vx: float, vy: float, size: int,
                hp: int, side: int, golden := false, mystery := false,
                gift := "") -> void:
        var r := _radius(size, golden, mystery)
        var sp := Vector2(vx, vy).length()
        if sp < SPEED_MIN * us:
                var k := SPEED_MIN * us / maxf(1.0, sp)
                vx *= k
                vy *= k
        elif sp > SPEED_MAX * us:
                var k2 := SPEED_MAX * us / sp
                vx *= k2
                vy *= k2
        rocks.append({
                "x": x, "y": y, "vx": vx, "vy": vy, "r": r,
                "size": size, "hp": hp, "hp0": hp,
                "golden": golden, "mystery": mystery, "gift": gift,
                "rot": rng.randf_range(0.0, TAU),
                "omega": vx / r * SPIN_RATE,
                "sq": 1.0, "cd": 0.0, "side": side,
                # THE WALL BUDGET LAW (v040-9): regular rocks bounce on the
                # walls 3..5 times (the 3rd/4th exit reads best, the owner)
                # before they slide out; the specials never leave.
                "wall_bounce": (0 if (golden or mystery)
                        else rng.randi_range(3, 5)),
                "seed": rng.randf_range(0.0, 100.0),
        })

# ------------------------------------------------- the bounce physics
## THE JUICE LAW: gravity, spin flips and squash. v040-8 THE BOUNCE LAW:
## the GROUND IS A TRAMPOLINE - every rock bounces off it (the original's
## law, the owner: "rocks when hit the ground they get broken instead of
## bouncing like the original game"). THE WALL BUDGET LAW (v040-9, the
## owner's correction on the v040-8 open walls): the original let the
## regular rocks bounce on the WALLS a few times before they slide out -
## every regular rock carries a budget of 3..5 wall bounces (the 3rd/4th
## exit reads best, the owner), then it passes through and EXITS (its
## side seat frees). Only the golden and the mystery rocks never leave
## (they bounce off walls + floor forever, the persistence law).
func _rock_physics(delta: float) -> void:
        if phase == "boot":
                return
        var sf := (SLOW_FACTOR if slow_t > 0.0 else 1.0)
        var left := WALL_T * us
        var right := W - WALL_T * us
        var floor_y := ground_y - 8.0 * us
        var gone: Array = []
        for rk in rocks:
                rk["cd"] = maxf(0.0, float(rk["cd"]) - delta)
                var d := rk as Dictionary
                var vx := float(d["vx"]) * sf
                var vy := (float(d["vy"]) + GRAVITY * us * delta) * sf
                var x := float(d["x"]) + vx * delta
                var y := float(d["y"]) + vy * delta
                var r := float(d["r"])
                var bounced := false
                var special := bool(d["golden"]) or bool(d["mystery"])
                # THE WALL BUDGET LAW: a regular rock whose budget still
                # has bounces dances off the wall; once the budget is spent
                # it slides through and exits (its side seat frees). The
                # specials bounce forever (THE PERSISTENCE LAW).
                if x - r > right + 40.0 * us or x + r < left - 40.0 * us:
                        if not special:
                                gone.append(rk)   # a clean exit - no dust
                                continue
                if special:
                        if x - r < left:
                                x = left + r
                                vx = absf(vx)
                                bounced = true
                        elif x + r > right:
                                x = right - r
                                vx = -absf(vx)
                                bounced = true
                        if y - r < arena_top:
                                y = arena_top + r
                                vy = absf(vy)
                                bounced = true
                elif int(d.get("wall_bounce", 0)) > 0:
                        if x - r < left:
                                x = left + r
                                vx = absf(vx)
                                d["wall_bounce"] = int(d["wall_bounce"]) - 1
                                bounced = true
                        elif x + r > right:
                                x = right - r
                                vx = -absf(vx)
                                d["wall_bounce"] = int(d["wall_bounce"]) - 1
                                bounced = true
                # THE BOUNCE LAW: every rock dances on the ground
                if y + r > floor_y:
                        y = floor_y - r
                        var kick := maxf(absf(vy) * FLOOR_BOUNCE,
                                GROUND_MIN_KICK * us)
                        vy = -kick
                        vx *= 0.985                        # the floor's grip
                        bounced = true
                        d["ground_hits"] = int(d.get("ground_hits", 0)) + 1
                # the spin obeys the surface: a bounce flips it, the ride
                # rolls it (the flip law)
                var sp := Vector2(vx, vy).length()
                if sp > SPEED_MAX * us:
                        var k := SPEED_MAX * us / sp
                        vx *= k
                        vy *= k
                d["x"] = x
                d["y"] = y
                d["vx"] = vx
                d["vy"] = vy
                if bounced:
                        d["omega"] = -float(d["omega"]) \
                                * rng.randf_range(0.85, 1.15) \
                                + vx / maxf(20.0, r) * SPIN_RATE
                        d["sq"] = 0.82
                        if absf(vx) > 240.0 * us or absf(vy) > 240.0 * us:
                                Jukebox.sfx("rb_bounce", -16.0,
                                        rng.randf_range(0.9, 1.15))
                                if float(d["y"]) > ground_y - r - 30.0 * us:
                                        _ground_puff(x, floor_y, r)
                else:
                        d["omega"] = vx / maxf(20.0, r) * SPIN_RATE
                d["rot"] = float(d["rot"]) + float(d["omega"]) * delta
                d["sq"] = minf(1.0, float(d["sq"]) + delta * 2.2)
        for rk in gone:
                _rock_exit(rk)

## a regular rock exits through an open wall: the side ledger frees, the
## rock is gone quietly (no pay, no dust - the flood stays honest)
func _rock_exit(rk: Dictionary) -> void:
        var i := rocks.find(rk)
        if i == -1:
                return
        rocks.remove_at(i)
        var side := int(rk["side"])
        if side >= 0 and side < 2:
                side_count[side] = maxi(0, side_count[side] - 1)

## the ground bounce's dust puff (the floor is alive)
func _ground_puff(x: float, floor_y: float, r: float) -> void:
        for i in 3:
                _push_fx("dust", x + rng.randf_range(-r, r) * 0.5,
                        floor_y, rng.randf_range(-60.0, 60.0) * us,
                        -rng.randf_range(20.0, 70.0) * us,
                        rng.randf_range(0.3, 0.6), rng.randf_range(6.0, 13.0)
                        * us, Color(0.7, 0.64, 0.56, 0.42))

## THE FLOOR EATS NOTHING anymore (v040-8) - the old ground-shatter is
## dead: every rock bounces (THE BOUNCE LAW), the herd thins by breaking
## and by the open walls.

# ------------------------------------------------------ the hold fire
## THE HOLD LAW: the right half fires ONLY while held; the cadence is
## the projectile stat ("more of them means more shot/s will happen"),
## x2 while the RUSH gift lives.
func _fire(delta: float) -> void:
        var holding := fire_ptr != -1 or mouse_fire
        if not holding:
                fire_cd = minf(fire_cd, 1.0 / bps_for(_proj_lvl()))
                return
        var rate := bps_for(_proj_lvl())
        if rush_t > 0.0:
                rate *= 2.0
        fire_cd -= delta
        while fire_cd <= 0.0:
                fire_cd += 1.0 / rate
                _shoot()

func _shoot() -> void:
        var jitter := rng.randf_range(-1.0, 1.0) * 12.0 * us
        # the muzzle rides the carriage texture's barrel top (v040-8)
        var body_t := _tex_at("cannon/body_%s.png" % _skin_id())
        var k := 226.0 * us / float(body_t.get_width())
        var muzzle_y := ground_y - 4.0 * us \
                - float(body_t.get_height()) * k + 12.0 * k
        bullets.append({
                "x": cannon_x + jitter,
                "y": muzzle_y,
                "vy": -BULLET_SPEED * us,
                "r": BULLET_R * us,
                "dmg": dmg_for(_dmg_lvl()),
                "trail": [],
        })
        muzzle_t = 0.05
        muzzle_big = clampf((_proj_lvl()) / 50.0, 0.0, 1.0)
        Jukebox.sfx("rb_shoot", -11.0, rng.randf_range(0.94, 1.08))

func _proj_lvl() -> int:
        return int(md.get("upg_proj", 0))

func _dmg_lvl() -> int:
        return int(md.get("upg_dmg", 0))

# --------------------------------------------------------- the bullets
## THE SWEEP LAW: a 1350px/s bullet steps ~22px a 60Hz frame - a small
## rock's hit circle is ~43px, a 30Hz step (45px) TUNNELS right over
## it. Every bullet walks its flight in substeps small enough to never
## skip a rock.
func _bullets_tick(delta: float) -> void:
        if bullets.is_empty():
                return
        var keep: Array = []
        for b in bullets:
                var d := b as Dictionary
                var step := float(d["vy"]) * delta
                var sub := maxi(1, int(ceil(absf(step)
                        / (18.0 * us))))
                var hit_i := -1
                for s in sub:
                        d["y"] = float(d["y"]) + step / float(sub)
                        hit_i = _bullet_hit(d)
                        if hit_i != -1:
                                break
                # THE TRAIL: the comet remembers its climb
                var tr: Array = d.get("trail", [])
                tr.append(Vector2(float(d["x"]), float(d["y"])))
                while tr.size() > BULLET_TRAIL:
                        tr.pop_front()
                d["trail"] = tr
                if hit_i == -1 and float(d["y"]) >= arena_top - 60.0:
                        keep.append(b)
        bullets = keep

func _bullet_hit(b: Dictionary) -> int:
        var bx := float(b["x"])
        var by := float(b["y"])
        for i in rocks.size():
                var rk := rocks[i] as Dictionary
                var rr := float(rk["r"]) * 0.94 + float(b["r"])
                var dx := float(rk["x"]) - bx
                var dy := float(rk["y"]) - by
                if dx * dx + dy * dy <= rr * rr:
                        if float(rk["cd"]) <= 0.0:
                                _damage_rock(i, int(b["dmg"]), bx, by)
                        return i
        return -1

# ------------------------------------------------------- the damage
func _damage_rock(i: int, dmg: int, hx: float, hy: float) -> void:
        var rk := rocks[i] as Dictionary
        rk["cd"] = COOLDOWN
        rk["hp"] = int(rk["hp"]) - dmg
        _spark(hx, hy)
        Jukebox.sfx("rb_hit", -11.0, rng.randf_range(0.9, 1.2))
        if int(rk["hp"]) <= 0:
                _break_rock(i)

# ------------------------------------------------------- the break
## THE BREAK: rockPoints +1 (THE SCORE LAW), the rockCoins fly (THE
## ROCKCOIN LAW: hp/10), the family pops (THE SIZE LAW), the golden
## pays its GOGACoin (THE GOLDEN LAW), the mystery hands its gift (THE
## MYSTERY LAW - slow / shield / x2 throw speed, nothing else).
func _break_rock(i: int, silent := false) -> void:
        if i < 0 or i >= rocks.size():
                return
        var rk := rocks[i] as Dictionary
        var hp0 := int(rk["hp0"])
        var size := int(rk["size"])
        var golden := bool(rk["golden"])
        var mystery := bool(rk["mystery"])
        var gift := String(rk["gift"])
        var x := float(rk["x"])
        var y := float(rk["y"])
        var side := int(rk["side"])
        rocks.remove_at(i)
        if side >= 0 and side < 2:
                side_count[side] = maxi(0, side_count[side] - 1)
        if silent:
                _shards(x, y, size, Color(0.8, 0.8, 0.85))
                return
        # THE SCORE LAW
        rp += 1
        heat = rp
        set_score(rp)
        # THE ROCKCOIN LAW: the full damage pool / 10, banked LIVE
        # (the catch law - the wallet is spendable mid-run)
        var pay := maxi(1, int(round(float(hp0) / 10.0)))
        rc_bank(pay)
        _coin_fly(x, y, pay)
        md["rocks_total"] = int(md.get("rocks_total", 0)) + 1
        _shards(x, y, size, Color(0.9, 0.85, 0.8))
        _dust(x, y, size)
        shake = minf(14.0, shake + 1.5 + float(size) * 0.9)
        Jukebox.sfx("rb_break", -7.0,
                [1.5, 1.25, 1.05, 0.88, 0.72][clampi(size - 1, 0, 4)])
        # THE SIZE LAW: the children pop with fresh angles of their own
        if not golden and not mystery and size > 1:
                var kids := children_sizes(size, rng)
                for ks in kids:
                        var kr := _radius(ks)
                        var ang := rng.randf_range(0.0, TAU)
                        var spd := rng.randf_range(150.0, 260.0) \
                                * float(SIZE_COEFF[ks - 1]) * us
                        _add_rock(
                                clampf(x + cos(ang) * 6.0, WALL_T * us + kr,
                                        W - WALL_T * us - kr),
                                clampf(y + sin(ang) * 6.0,
                                        arena_top + kr, ground_y - kr),
                                cos(ang) * spd, sin(ang) * spd - 80.0 * us,
                                ks, rock_hp(heat, ks, rng), -1)
        if golden:
                golden_alive = false
                rp_last_golden = rp          # the 300 counts from COLLECTION
                md["golden_total"] = int(md.get("golden_total", 0)) + 1
                add_run_coins(1)
                _goga_coin_fly(x, y)
                _ring(x, y, Color(1.0, 0.82, 0.24))
                shake = minf(18.0, shake + 9.0)
                Jukebox.sfx("rb_golden", -4.0)
        if mystery:
                mystery_alive = false
                rp_last_mystery = rp
                if gift.is_empty():
                        gift = pick_gift(rng)
                _apply_gift(gift)
                _ring(x, y, Color(0.78, 0.44, 0.95))
                Jukebox.sfx("rb_mystery", -5.0)

func _apply_gift(gift: String) -> void:
        match gift:
                "slow":
                        slow_t = SLOW_TIME
                "rush":
                        rush_t = RUSH_TIME
                "shield":
                        shield = 1
        game_toast({
                "slow": "SLOW DOWN - the rocks crawl",
                "rush": "RUSH - throw speed x2",
                "shield": "SHIELD - one touch forgiven",
        }.get(gift, ""))

# -------------------------------------------------------- the powerups
func _powerups_tick(delta: float) -> void:
        if slow_t > 0.0:
                slow_t = maxf(0.0, slow_t - delta)
        if rush_t > 0.0:
                rush_t = maxf(0.0, rush_t - delta)

# ------------------------------------------------------- the coin flies
func _coins_tick(delta: float) -> void:
        var keep: Array = []
        for c in coins_fx:
                var d := c as Dictionary
                d["t"] = float(d["t"]) + delta * 1.9
                if float(d["t"]) < 1.0:
                        keep.append(c)
        coins_fx = keep
        var keep2: Array = []
        for c in goga_fx:
                var d := c as Dictionary
                d["t"] = float(d["t"]) + delta * 1.25
                if float(d["t"]) < 1.0:
                        keep2.append(c)
        goga_fx = keep2

func _coin_fly(x: float, y: float, n: int) -> void:
        coins_fx.append({"x": x, "y": y, "t": 0.0, "n": n,
                "sx": rng.randf_range(-30.0, 30.0) * us})

func _goga_coin_fly(x: float, y: float) -> void:
        goga_fx.append({"x": x, "y": y, "t": 0.0})

# ------------------------------------------------------------- the fx
func _fx_tick(delta: float) -> void:
        var keep: Array = []
        for f in fx:
                var d := f as Dictionary
                d["life"] = float(d["life"]) - delta
                if float(d["life"]) <= 0.0:
                        continue
                d["x"] = float(d["x"]) + float(d["vx"]) * delta
                d["y"] = float(d["y"]) + float(d["vy"]) * delta
                if String(d["kind"]) == "shard" or String(d["kind"]) == "dust":
                        d["vy"] = float(d["vy"]) + GRAVITY * 0.7 * us * delta
                d["rot"] = float(d["rot"]) + float(d["vr"]) * delta
                keep.append(f)
        fx = keep

func _push_fx(kind: String, x: float, y: float, vx: float, vy: float,
                life: float, s: float, col: Color, vr := 0.0) -> void:
        fx.append({"kind": kind, "x": x, "y": y, "vx": vx, "vy": vy,
                "life": life, "max": life, "s": s, "col": col,
                "rot": rng.randf_range(0.0, TAU), "vr": vr})

func _shards(x: float, y: float, size: int, col: Color) -> void:
        var n := 5 + size * 3
        for i in n:
                var ang := rng.randf_range(0.0, TAU)
                var spd := rng.randf_range(120.0, 380.0) * us \
                        * (0.7 + 0.12 * float(size))
                _push_fx("shard", x, y, cos(ang) * spd, sin(ang) * spd - 120.0
                        * us, rng.randf_range(0.4, 0.85),
                        rng.randf_range(4.0, 11.0) * us * (0.7 + 0.1 * size),
                        col, rng.randf_range(-9.0, 9.0))

func _dust(x: float, y: float, size: int) -> void:
        for i in 4 + size:
                var ang := rng.randf_range(0.0, TAU)
                _push_fx("dust", x + cos(ang) * 10.0 * us,
                        y + sin(ang) * 10.0 * us, cos(ang) * 60.0 * us,
                        sin(ang) * 60.0 * us - 40.0 * us,
                        rng.randf_range(0.5, 1.0), rng.randf_range(8.0, 20.0)
                        * us, Color(0.6, 0.55, 0.5, 0.5))

func _spark(x: float, y: float) -> void:
        for i in 2:
                var ang := rng.randf_range(-TAU * 0.4, -TAU * 0.1)
                _push_fx("spark", x, y, cos(ang) * 220.0 * us,
                        sin(ang) * 220.0 * us, 0.16, 3.5 * us,
                        Color(1.0, 0.9, 0.5))

func _ring(x: float, y: float, col: Color) -> void:
        _push_fx("ring", x, y, 0.0, 0.0, 0.55, 1.0 * us, col)

# --------------------------------------------------- the cannon tick
func _cannon_tick(delta: float) -> void:
        if phase == "boot":
                return
        var speed := 520.0 * us
        var want := move_force
        if _auto:
                want = _auto_move()
        var tv := want * speed
        cannon_vx = lerpf(cannon_vx, tv, minf(1.0, delta * 12.0))
        cannon_x += cannon_vx * delta
        var half := 70.0 * us
        if cannon_x < half:
                cannon_x = half
                cannon_vx = 0.0
        elif cannon_x > W - half:
                cannon_x = W - half
                cannon_vx = 0.0
        wheel_rot += cannon_vx * delta / (26.0 * us)
        if absf(cannon_vx) > 260.0 * us and rng.randf() < delta * 9.0:
                _push_fx("dust", cannon_x - signf(cannon_vx) * 40.0 * us,
                        ground_y - 6.0 * us, -cannon_vx * 0.14, -30.0 * us,
                        0.5, rng.randf_range(5.0, 10.0) * us,
                        Color(0.7, 0.65, 0.58, 0.5))

# ------------------------------------------------------ the touch law
## ONE rock touch and the run is over - unless the SHIELD forgives it
## (the toucher vaporizes, the shield dies in its place).
func _touch_check() -> void:
        if phase != "play":
                return
        var bw := 62.0 * us
        var bh := 56.0 * us
        var cy := ground_y - 60.0 * us
        for i in rocks.size():
                var rk := rocks[i] as Dictionary
                var r := float(rk["r"])
                var cxp := clampf(float(rk["x"]), cannon_x - bw,
                        cannon_x + bw)
                var cyp := clampf(float(rk["y"]), cy - bh, cy + bh)
                var dx := float(rk["x"]) - cxp
                var dy := float(rk["y"]) - cyp
                if dx * dx + dy * dy <= r * r:
                        if shield > 0:
                                shield = 0
                                md["shield_saves"] = int(md.get(
                                        "shield_saves", 0)) + 1
                                _break_rock(i, true)
                                _ring(cannon_x, cy - 20.0 * us,
                                        Color(0.5, 0.85, 1.0))
                                game_toast("THE SHIELD TAKES IT")
                                Jukebox.sfx("rb_shieldsave", -3.0)
                        else:
                                _die(float(rk["x"]), float(rk["y"]))
                        return

func _die(x: float, y: float) -> void:
        if phase != "play":
                return
        phase = "over"
        death_t = 0.0
        hit_flash = 0.9
        shake = 22.0
        _shards(cannon_x, ground_y - 60.0 * us, 5, Color(0.75, 0.78, 0.85))
        _dust(x, y, 4)
        Jukebox.sfx("rb_death", -2.0)

func _finish() -> void:
        md["best_rp"] = maxi(int(md.get("best_rp", 0)), rp)
        if rp > 0:
                Box.bump_counter(GAME, "rocks", rp)
        Box.max_counter(GAME, "best_rp", int(md["best_rp"]))
        if int(md.get("golden_total", 0)) > 0:
                Box.bump_counter(GAME, "golden", int(md["golden_total"]))
        if int(md.get("shield_saves", 0)) > 0:
                Box.bump_counter(GAME, "saves", int(md["shield_saves"]))
        meta_save()
        check_achievements()
        finish_run(rp)

# --------------------------------------------------------- the qa bot
## The auto-cannon: locks the LOWEST rock, parks under it, and keeps
## the pour on it until it breaks (children inherit the lock). The
## upgrade policy alternates shelves the moment the wallet can pay.
var _auto_buy := 0
var _auto_lock := {}

func _auto_move() -> float:
        if _auto_lock.is_empty() or not rocks.has(_auto_lock):
                _auto_lock = {}
                var best_y := -1e9
                for rk in rocks:
                        if float(rk["y"]) > best_y:
                                best_y = float(rk["y"])
                                _auto_lock = rk
        if _auto_lock.is_empty():
                return clampf((W * 0.5 - cannon_x) / (140.0 * us),
                        -1.0, 1.0)
        return clampf((float(_auto_lock["x"]) - cannon_x) / (140.0 * us),
                -1.0, 1.0)

func _auto_tick(delta: float) -> void:
        if not _auto:
                return
        _auto_t -= delta
        if _auto_t <= 0.0:
                _auto_t = 0.5
                _auto_buy_step()
        # THE LEAD LAW: straight bullets drift-behind a moving rock - the
        # bot pours only when the lock is LOW (a short flight, a real hit)
        var firing := false
        if not _auto_lock.is_empty() and rocks.has(_auto_lock):
                firing = float(_auto_lock["y"]) > ground_y - 700.0 * us
        mouse_fire = firing

## the bot's shelf policy: the cheapest AFFORDABLE upgrade wins (the
## wall-priced shelf is simply never affordable at that depth)
func _auto_buy_step() -> void:
        var pl := _proj_lvl()
        var bp := proj_price(pl) if pl < PROJ_CAP else -1
        var dp := dmg_price(_dmg_lvl())
        var w := rc_wallet()
        if bp >= 0 and w >= bp:
                if rc_spend(bp):
                        md["upg_proj"] = pl + 1
                        _auto_buy += 1
                return
        if w >= dp:
                if rc_spend(dp):
                        md["upg_dmg"] = _dmg_lvl() + 1
                        _auto_buy += 1

# ------------------------------------------------- the probe contract
func probe_reset(seed_v: int) -> void:
        rng.seed = seed_v
        rocks.clear()
        bullets.clear()
        fx.clear()
        coins_fx.clear()
        goga_fx.clear()
        rp = 0
        heat = 0
        side_count = [0, 0]
        golden_alive = false
        mystery_alive = false
        rp_last_golden = 0
        rp_last_mystery = 0
        slow_t = 0.0
        rush_t = 0.0
        shield = 0
        place_i = 0
        place_next = PLACE_EVERY
        place_fade = 1.0
        spawn_t = 1.2
        cannon_x = W * 0.5
        cannon_vx = 0.0
        phase = "play"
        md["upg_proj"] = 0
        md["upg_dmg"] = 0

func probe_spawn(side: int, size: int, hp: int, golden := false,
                mystery := false, gift := "") -> void:
        _spawn_side_rock_ex(side, size, hp, golden, mystery, gift)
        if golden:
                golden_alive = true
        if mystery:
                mystery_alive = true

# ============================================================ SHEETS
## THE BUTTON LAW: SHOP top-left, UPGRADES next to it at the right.
## Both are sheets that pause the run; the back button closes them (the
## sheet stack law).
func _shop_open() -> void:
        if over:
                return
        Jukebox.sfx("rb_click", -6.0)
        var sheet := sheet_push(0.0, "shop")
        var t := Arc.label("ROCK BREAKER SHOP", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := _vp()
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.52, 320.0,
                        640.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        box.add_child(Arc.fit_label("CANNON SKINS", 24, Arc.HOT, 560))
        for id in SKINS:
                box.add_child(_skin_row(id))
        box.add_child(Arc.fit_label("THEMES", 24, Arc.HOT, 560))
        for id in THEMES:
                box.add_child(_theme_row(id))
        var back := Arc.button("CLOSE", Vector2(560, 72), 26, Arc.GOOD,
                func(): sheet_pop())
        sheet.add_child(back)
        # THE TAP LAW (v040-8): a BoxScroll swallows raw touches - every
        # button inside registers as a tappable (the heavywar shop law).
        # Without this the buttons freeze on press and never activate.
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _shop_reopen() -> void:
        sheet_pop()
        _shop_open()

func _skin_row(id: String) -> Control:
        var c: Dictionary = SKINS[id]
        var owned := Box.skin_owned(game_id, id) or int(c["price"]) == 0
        var on: bool = Box.skin_on(game_id) == id \
                or (int(c["price"]) == 0 and Box.skin_on(game_id) == "")
        if on:
                return Arc.on_row("%s  (ON)" % c["name"])
        if owned:
                return Arc.button(c["name"], Vector2(560, 60), 22, Arc.ACCENT,
                        func():
                                Box.equip_skin(game_id, id)
                                Jukebox.sfx("rb_confirm", -4.0)
                                _shop_reopen())
        # THE LOCKED LAW: the price row stays disabled until the wallet
        # can actually pay (the dry wallet never buys).
        var b := Arc.coin_button("%s  %d" % [c["name"], int(c["price"])],
                        Vector2(560, 64), 22, Arc.ACCENT, func():
                                if Box.buy_skin(game_id, id, int(c["price"])):
                                        Jukebox.sfx("rb_buy")
                                        Box.equip_skin(game_id, id)
                                _shop_reopen())
        if Box.coins() < int(c["price"]):
                b.disabled = true
        return b

func _theme_row(id: String) -> Control:
        var c: Dictionary = THEMES[id]
        var owned := Box.item_owned(game_id, "theme", id) \
                or int(c["price"]) == 0
        var on: bool = Box.item_on(game_id, "theme") == id \
                or (int(c["price"]) == 0
                and Box.item_on(game_id, "theme") == "")
        if on:
                return Arc.on_row("%s  (ON)" % c["name"])
        if owned:
                return Arc.button(c["name"], Vector2(560, 60), 22,
                        Color("7a4ab8"), func():
                                Box.equip_item(game_id, "theme", id)
                                Jukebox.sfx("rb_confirm", -4.0)
                                place_next = rp
                                _shop_reopen())
        var b := Arc.coin_button("%s  %d" % [c["name"], int(c["price"])],
                        Vector2(560, 64), 22, Color("7a4ab8"), func():
                                if Box.buy_item(game_id, "theme", id,
                                                int(c["price"])):
                                        Jukebox.sfx("rb_buy")
                                        Box.equip_item(game_id, "theme", id)
                                        place_next = rp
                                _shop_reopen())
        if Box.coins() < int(c["price"]):
                b.disabled = true
        return b

## THE UPGRADE SHEET: two shelves only (THE UPGRADE LAW) - the
## projectile count capped at 50, the damage uncapped, no third row.
func _upgrades_open() -> void:
        if over:
                return
        Jukebox.sfx("rb_click", -6.0)
        _upgrades_fill(sheet_push(0.0, "upg"))

func _upgrades_fill(sheet: VBoxContainer) -> void:
        var t := Arc.label("UPGRADES", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        # the rockCoins wallet chip (the game's own currency, not the box's)
        var row := HBoxContainer.new()
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        row.add_theme_constant_override("separation", 10)
        var icon := _rc_icon_widget(30)
        row.add_child(icon)
        var wl := Arc.label(fmt(rc_wallet()) + "  ROCKCOINS", 28, Arc.COIN)
        row.add_child(wl)
        sheet.add_child(row)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := _vp()
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.42, 260.0,
                        520.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        var pl := _proj_lvl()
        var pmax := pl >= PROJ_CAP
        box.add_child(Arc.fit_label("PROJECTILE", 24, Arc.HOT, 560))
        if pmax:
                box.add_child(Arc.on_row("PROJECTILE  %d/50  (MAX)" % pl))
        else:
                var pp := proj_price(pl)
                var pb := Arc.button("PROJECTILE  %d/50  -  %s"
                        % [pl, fmt(pp)], Vector2(560, 64), 22, Arc.ACCENT,
                        func(): _buy_proj())
                if rc_wallet() < pp:
                        pb.disabled = true
                box.add_child(pb)
        var dl := _dmg_lvl()
        box.add_child(Arc.fit_label("DAMAGE", 24, Arc.HOT, 560))
        var dp := dmg_price(dl)
        var db := Arc.button("DAMAGE  %d  -  %s" % [dl, fmt(dp)],
                Vector2(560, 64), 22, Arc.ACCENT, func(): _buy_dmg())
        if rc_wallet() < dp:
                db.disabled = true
        box.add_child(db)
        var back := Arc.button("CLOSE", Vector2(560, 72), 26, Arc.GOOD,
                func(): sheet_pop())
        sheet.add_child(back)
        # THE TAP LAW (v040-8): registered tappables inside the scroll -
        # the freeze-on-press is dead
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _upgrades_reopen() -> void:
        sheet_pop()
        _upgrades_open()

func _buy_proj() -> void:
        var lvl := _proj_lvl()
        if lvl >= PROJ_CAP:
                return
        var p := proj_price(lvl)
        if rc_spend(p):
                md["upg_proj"] = lvl + 1
                meta_save()
                Jukebox.sfx("rb_buy")
                _upgrades_reopen()

func _buy_dmg() -> void:
        var lvl := _dmg_lvl()
        var p := dmg_price(lvl)
        if rc_spend(p):
                md["upg_dmg"] = lvl + 1
                meta_save()
                Jukebox.sfx("rb_buy")
                _upgrades_reopen()

## the rockCoins icon: a chiseled stone-coin with an R (the box's own
## mini-widget way)
func _rc_icon_widget(px: int) -> Control:
        var c := Control.new()
        c.custom_minimum_size = Vector2(px, px)
        c.draw.connect(func():
                var cx := px * 0.5
                var r := px * 0.46
                var pts := PackedVector2Array()
                for i in 8:
                        var a := TAU * float(i) / 8.0 + TAU / 16.0
                        pts.append(Vector2(cx + cos(a) * r,
                                cx + sin(a) * r * 0.94))
                c.draw_colored_polygon(pts, Color(0.72, 0.66, 0.55))
                var inner := PackedVector2Array()
                for i in 8:
                        var a := TAU * float(i) / 8.0 + TAU / 16.0
                        inner.append(Vector2(cx + cos(a) * r * 0.72,
                                cx + sin(a) * r * 0.68))
                c.draw_colored_polygon(inner, Color(0.87, 0.82, 0.70))
                var f := Arc.font_big()
                c.draw_string(f, Vector2(0, cx + px * 0.34), "R",
                        HORIZONTAL_ALIGNMENT_CENTER, px,
                        int(px * 0.62), Color(0.32, 0.26, 0.18)))
        return c

# ============================================================ THE ART
## Everything is code-drawn (the box law). All colors come from the
## theme's place; the five places walk while the run lives (THE FIVE
## PLACES LAW) on a calm crossfade.
var _drng := RandomNumberGenerator.new()

func _draw_bg() -> void:
        if bg_layer == null:
                return
        _drng.randomize()
        var shk := Vector2(_drng.randf_range(-1.0, 1.0),
                _drng.randf_range(-1.0, 1.0)) * shake * us * 0.5
        bg_layer.draw_set_transform(Vector2(shk.x, shk.y), 0.0, Vector2.ONE)
        var th: Dictionary = _theme()
        var ps: Array = th["places"]
        if place_fade < 1.0:
                _draw_place(ps[place_from % ps.size()], th, 1.0)
                _draw_place(ps[place_i % ps.size()], th, place_fade)
        else:
                _draw_place(ps[place_i % ps.size()], th, 1.0)
        # v040-10 THE TELEGRAPH: the ground throws warn before they fire -
        # a pulsing warning ring grows at the seat (never an unseen kill)
        for m in launch_marks:
                var k := 1.0 - float(m["t"]) / LAUNCH_TELEGRAPH
                var pulse := 0.5 + 0.5 * sin(_time * 18.0)
                var rr := (26.0 + 30.0 * k) * us
                bg_layer.draw_arc(Vector2(float(m["x"]), ground_y - 6.0 * us),
                        rr, 0, TAU, 26,
                        Color(1.0, 0.5 + 0.3 * pulse, 0.2, 0.55 + 0.3 * k),
                        4.0 * us)
        bg_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_place(p: Dictionary, th: Dictionary, alpha: float) -> void:
        var d := bg_layer
        var pi: int = (th["places"] as Array).find(p)
        var prefix: String = STYLE_PREFIX.get(String(th["style"]), "cave")
        # THE FAR LAYER: the baked scene strip (the cave theme wears the
        # recolored study backgrounds) cover-cropped above the ground
        var far: Texture2D = _tex_at("world/far_%s_%d.png" % [prefix, maxi(0, pi) % 5])
        var fw := float(far.get_width())
        var fh := float(far.get_height())
        var dst_h := ground_y + 10.0
        var dst_w := W
        # COVER-CROP: the full height stays, the width slices to the aspect
        var src_w := minf(fw, fh * dst_w / dst_h)
        var src_x := (fw - src_w) * 0.5
        d.draw_texture_rect_region(far,
                Rect2(0, ground_y + 10.0 - dst_h, dst_w, dst_h),
                Rect2(src_x, 0, src_w, fh), _alpha(Color(1, 1, 1, 1), alpha))
        # THE GROUND: the baked strip (per theme), the cannon rides it
        var gt: Texture2D = _tex_at("world/ground_%s.png" % prefix)
        d.draw_texture_rect(gt, Rect2(0, ground_y - 4.0, W,
                H - ground_y + 4.0), false, _alpha(Color(1, 1, 1, 1), alpha))
        # the side walls (the arena's skin)
        var wcol: Color = p["wall"]
        wcol.a = alpha
        d.draw_rect(Rect2(0, 0, WALL_T * us, ground_y), wcol)
        d.draw_rect(Rect2(W - WALL_T * us, 0, WALL_T * us, ground_y), wcol)

func _alpha(c: Color, a: float) -> Color:
        var out := c
        out.a = a
        return out

# ========================================================= THE ROCKS
func _draw_rocks() -> void:
        if rock_layer == null:
                return
        _drng.randomize()
        var shk := Vector2(_drng.randf_range(-1.0, 1.0),
                _drng.randf_range(-1.0, 1.0)) * shake * us * 0.7
        rock_layer.draw_set_transform(Vector2(shk.x, shk.y), 0.0, Vector2.ONE)
        var th: Dictionary = _theme()
        var style := String(th["style"])
        # THE PIXEL LAW reads crisp: nearest filtering while the pixel pack
        # is on stage (the other materials keep the smooth sampling)
        rock_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST \
                if style == "pixel" else CanvasItem.TEXTURE_FILTER_LINEAR
        # THE SHOTS: bigger balls with a comet trail (v040-8) - a shot you
        # can SEE climbing (the owner: "i do not even see it going up")
        for b in bullets:
                var bd := b as Dictionary
                var trail: Array = bd.get("trail", [])
                for ti in trail.size():
                        var tp: Vector2 = trail[ti]
                        var ta := float(ti + 1) / float(trail.size() + 1)
                        rock_layer.draw_circle(tp, float(bd["r"]) * (0.3
                                + 0.5 * ta), Color(1.0, 0.86, 0.5,
                                0.30 * ta))
                rock_layer.draw_circle(Vector2(float(bd["x"]),
                        float(bd["y"])), float(bd["r"]),
                        Color(1.0, 0.94, 0.78))
                rock_layer.draw_circle(Vector2(float(bd["x"]),
                        float(bd["y"])), float(bd["r"]) * 0.45,
                        Color(1, 1, 1))
        for rk in rocks:
                _paint_rock(rock_layer, rk, style)
        rock_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## deterministic facet jitter from the rock's own seed (no per-frame rng)
func _facet_k(seed_v: float, i: int) -> float:
        return 0.86 + 0.14 * absf(sin(seed_v * 13.7 + float(i) * 7.31))

func _paint_rock(d: Node2D, rk: Dictionary, style: String) -> void:
        var x := float(rk["x"])
        var y := float(rk["y"])
        var r := float(rk["r"])
        var size := int(rk["size"])
        var hp := int(rk["hp"])
        var hp0 := maxi(1, int(rk["hp0"]))
        var golden := bool(rk["golden"])
        var mystery := bool(rk["mystery"])
        var rot := float(rk["rot"])
        var sq := float(rk["sq"])
        var seed_v := float(rk["seed"])
        var ramp := ramp_color(ramp_index(hp0))
        var hot: float = ramp["hot"]
        var tex := _rock_tex(style, size)
        # THE TINT LAW: the baked grayscale base x the heat color = the
        # rock's material wearing its heat (the color IS the level). Each
        # material reads the ramp its own way (the theme's pack).
        var tint: Color
        match style:
                "wood":
                        tint = Color(0.62, 0.44, 0.26).lerp(
                                Color(1.0, 0.62, 0.3), hot)
                "neon":
                        tint = Color.from_hsv(wrapf(0.62 - hot * 0.62,
                                0.0, 1.0), 0.55, 1.0)
                "candy":
                        tint = Color.from_hsv(wrapf(0.95 - hot * 0.62,
                                0.0, 1.0), 0.30 + 0.3 * hot, 1.0)
                _:
                        tint = ramp["body"].lightened(0.14)
        if golden:
                tint = Color(1.0, 0.84, 0.3)
        if mystery:
                tint = Color(0.62, 0.44, 0.72)
        # THE NEON FILL LAW: the glow is a filled halo, the body stays SOLID
        if style == "neon" or golden:
                var gl := tint
                gl.a = 0.16 + 0.06 * sin(_time * 5.0 + seed_v)
                d.draw_circle(Vector2(x, y), r * 1.5, gl)
                gl.a = 0.12
                d.draw_circle(Vector2(x, y), r * 1.9, gl)
        # THE BODY: the baked texture, rotated, squashed on bounce - the
        # sprite reads a touch wider than the collision circle (the art's
        # irregular silhouette)
        var s := r * 2.3
        d.draw_set_transform(Vector2(x, y), rot, Vector2(1.0, sq))
        d.draw_texture_rect(tex, Rect2(-s * 0.5, -s * 0.5, s, s),
                false, tint)
        # THE CRACK LAW: the damage shows as baked webs over the body
        var frac := float(hp) / float(hp0)
        if frac < 0.72 and not golden and not mystery:
                var lvl := 1
                if frac < 0.2:
                        lvl = 3
                elif frac < 0.4:
                        lvl = 2
                var ct := _tex_at("rocks/crack_%d.png" % lvl)
                d.draw_texture_rect(ct, Rect2(-s * 0.5, -s * 0.5, s, s),
                        false)
        d.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        # the heat shimmer on the hottest ramp (the top wears the glow)
        if hot > 0.86 and not golden and not mystery:
                var hg := Color(1.0, 0.6, 0.2, 0.14 + 0.07
                        * sin(_time * 7.0 + seed_v))
                d.draw_circle(Vector2(x, y), r * 1.32, hg)
        # the face number (THE NUMBER LAW) - hidden pools show a mark
        var fs := int(maxf(15.0, r * 0.42))
        var f := Arc.font_big()
        var txt := ""
        if golden:
                txt = ""
        elif mystery:
                txt = "?"
        else:
                txt = fmt(hp)
        var tcol := Color(1, 1, 1) if not golden else Color(0.35, 0.22, 0.05)
        d.draw_string_outline(f, Vector2(x - r, y + fs * 0.36), txt,
                HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, fs, int(5.0 * us) + 2,
                Color(0, 0, 0, 0.85))
        d.draw_string(f, Vector2(x - r, y + fs * 0.36), txt,
                HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, fs, tcol)
        if golden:
                # the golden mark: a five-point star over the face
                var st := r * 0.34
                var star := PackedVector2Array()
                for i in 10:
                        var a := -PI * 0.5 + PI * float(i) / 5.0
                        var rr2 := st if i % 2 == 0 else st * 0.45
                        star.append(Vector2(x + cos(a) * rr2,
                                y - r * 0.18 + sin(a) * rr2))
                d.draw_colored_polygon(star, Color(1.0, 0.97, 0.8))
                d.draw_polyline(star + PackedVector2Array([star[0]]),
                        Color(0.55, 0.38, 0.08), 2.0 * us)

# ====================================================== THE CANNON
func _draw_char() -> void:
        if char_layer == null:
                return
        _drng.randomize()
        var shk := Vector2(_drng.randf_range(-1.0, 1.0),
                _drng.randf_range(-1.0, 1.0)) * shake * us * 0.7
        char_layer.draw_set_transform(Vector2(shk.x, shk.y), 0.0,
                Vector2.ONE)
        var sk := _skin()
        var x := cannon_x
        # THE CANNON (v040-8): the real carriage texture - the study's
        # cart body rebuilt with our barrel, tinted by the skin, riding on
        # our own SPINNING spoked wheels (the ride law)
        var body_t := _tex_at("cannon/body_%s.png" % _skin_id())
        var wheel_t := _tex_at("cannon/wheel_%s.png" % _skin_id())
        var k := 226.0 * us / float(body_t.get_width())   # carriage scale
        var bw := float(body_t.get_width()) * k
        var bh := float(body_t.get_height()) * k
        # the wheels sit on the ground, the carriage hangs on them; the
        # barrel occupies the sprite's headroom above the cart
        var wheel_y := ground_y - 46.0 * k
        # v040-10 THE SEAT LAW (the owner: "canon body overlaps with it's
        # wheels"): the carriage rests ON the wheel tops - its floor line
        # sits at the axle top minus a breath, never down at the ground
        # where it painted over the wheels
        var body_bottom := wheel_y - 26.0 * k
        for side: float in [-1.0, 1.0]:
                var wx := x + side * 82.0 * k
                var wr := 46.0 * k
                var wsz := wr * 2.0
                char_layer.draw_set_transform(Vector2(wx, wheel_y),
                        wheel_rot * side, Vector2.ONE)
                char_layer.draw_texture_rect(wheel_t,
                        Rect2(-wsz * 0.5, -wsz * 0.5, wsz, wsz), false)
        char_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        # the carriage + barrel (one baked sprite, the barrel already seated)
        char_layer.draw_texture_rect(body_t,
                Rect2(x - bw * 0.5, body_bottom - bh, bw, bh), false)
        # the muzzle flash rides the barrel top
        var muzzle_y := body_bottom - bh + 12.0 * k
        if muzzle_t > 0.0:
                var fl := clampf(muzzle_t / 0.05, 0.0, 1.0)
                var fr := (12.0 + 18.0 * muzzle_big) * k * 2.2 * fl
                char_layer.draw_circle(Vector2(x, muzzle_y), fr,
                        Color(1.0, 0.88, 0.5, 0.8 * fl))
                char_layer.draw_circle(Vector2(x, muzzle_y),
                        fr * 0.5, Color(1, 1, 1, 0.9 * fl))
        # the shield bubble (the mystery gift)
        if shield > 0:
                var sr := 110.0 * us
                var pulse := 0.5 + 0.14 * sin(_time * 6.0)
                var scy := body_bottom - bh * 0.55
                char_layer.draw_circle(Vector2(x, scy), sr,
                        Color(0.5, 0.85, 1.0, 0.10 + 0.05 * pulse))
                char_layer.draw_arc(Vector2(x, scy), sr,
                        0, TAU, 40, Color(0.6, 0.9, 1.0, 0.6 + 0.2 * pulse),
                        4.0 * us)
        char_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ============================================================ THE FX
func _draw_fx() -> void:
        if fx_layer == null:
                return
        for f in fx:
                var d := f as Dictionary
                var life := float(d["life"])
                var mx := maxf(0.0001, float(d["max"]))
                var tt := life / mx
                var x := float(d["x"])
                var y := float(d["y"])
                var kind := String(d["kind"])
                match kind:
                        "shard":
                                fx_layer.draw_set_transform(Vector2(x, y),
                                        float(d["rot"]), Vector2.ONE)
                                var s := float(d["s"])
                                var col: Color = d["col"]
                                col.a = tt
                                fx_layer.draw_colored_polygon(
                                        PackedVector2Array([
                                                Vector2(-s, s * 0.7),
                                                Vector2(s * 0.8, s * 0.5),
                                                Vector2(0, -s)]), col)
                                fx_layer.draw_set_transform(Vector2.ZERO,
                                        0.0, Vector2.ONE)
                        "dust":
                                var col2: Color = d["col"]
                                col2.a = float(col2.a) * tt
                                fx_layer.draw_circle(Vector2(x, y),
                                        float(d["s"]) * (1.6 - tt * 0.6),
                                        col2)
                        "spark":
                                var col3: Color = d["col"]
                                col3.a = tt
                                fx_layer.draw_circle(Vector2(x, y),
                                        float(d["s"]) * tt + 1.0, col3)
                        "ring":
                                var rr := (1.0 - tt) * 120.0 * us + 14.0 * us
                                var col4: Color = d["col"]
                                col4.a = tt * 0.9
                                fx_layer.draw_arc(Vector2(x, y), rr, 0, TAU,
                                        40, col4, 5.0 * us * tt + 1.5)
        # the rockCoin fly arcs (THE ROCKCOIN LAW's visible pay)
        for c in coins_fx:
                var d := c as Dictionary
                var t := float(d["t"])
                var sx := float(d["x"])
                var sy := float(d["y"])
                var wx := 52.0 * us
                var wy := H - 52.0 * us
                var mx := lerpf(sx, wx, t)
                var my := lerpf(sy, wy, t) - sin(t * PI) * 130.0 * us
                _draw_rockcoin(fx_layer, mx, my, 13.0 * us)
                if t > 0.55:
                        var f := Arc.font_big()
                        var txt := "+" + fmt(int(d["n"]))
                        var a := clampf((1.0 - t) * 2.4, 0.0, 1.0)
                        fx_layer.draw_string(f, Vector2(sx - 60.0 * us,
                                sy - (60.0 + t * 90.0) * us), txt,
                                HORIZONTAL_ALIGNMENT_CENTER, 120.0 * us,
                                int(20.0 * us), Color(1, 0.95, 0.8, a))
        # the GOGACoin fly (THE GOLDEN LAW's drop)
        for c in goga_fx:
                var d := c as Dictionary
                var t := float(d["t"])
                var sx := float(d["x"])
                var sy := float(d["y"])
                var mx := lerpf(sx, W - 60.0 * us, t)
                var my := lerpf(sy, 34.0 * us, t) - sin(t * PI) * 180.0 * us
                _draw_gogacoin(fx_layer, mx, my, 17.0 * us, t)
        _draw_wallet()

## the rockCoin: a chiseled stone-coin with the R
func _draw_rockcoin(d: Node2D, x: float, y: float, r: float) -> void:
        var pts := PackedVector2Array()
        for i in 8:
                var a := TAU * float(i) / 8.0 + TAU / 16.0
                pts.append(Vector2(x + cos(a) * r, y + sin(a) * r * 0.94))
        d.draw_colored_polygon(pts, Color(0.72, 0.66, 0.55))
        var inner := PackedVector2Array()
        for i in 8:
                var a := TAU * float(i) / 8.0 + TAU / 16.0
                inner.append(Vector2(x + cos(a) * r * 0.7,
                        y + sin(a) * r * 0.66))
        d.draw_colored_polygon(inner, Color(0.9, 0.85, 0.72))
        var f := Arc.font_big()
        d.draw_string(f, Vector2(x - r, y + r * 0.62), "R",
                HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, int(r * 1.15),
                Color(0.32, 0.26, 0.18))

## THE COIN LAW's face: the box's GOGACoin - a gold disc, a dark rim,
## the blocky G, a shine
func _draw_gogacoin(d: Node2D, x: float, y: float, r: float,
                spin := 0.0) -> void:
        var squash := absf(sin(spin * 9.0))
        var rx := r * (0.55 + 0.45 * squash)
        d.draw_circle(Vector2(x, y), maxf(rx, r * 0.55) + 2.0 * us,
                Color(0.55, 0.4, 0.08))
        d.draw_circle(Vector2(x, y), maxf(rx, r * 0.55),
                Color(1.0, 0.82, 0.24))
        d.draw_circle(Vector2(x, y), maxf(rx, r * 0.55) * 0.66,
                Color(1.0, 0.9, 0.5))
        var f := Arc.font_big()
        if squash > 0.4:
                d.draw_string(f, Vector2(x - rx, y + r * 0.5), "G",
                        HORIZONTAL_ALIGNMENT_CENTER, rx * 2.0, int(r * 1.1),
                        Color(0.5, 0.34, 0.05))
        d.draw_circle(Vector2(x - rx * 0.35, y - r * 0.4), 2.6 * us,
                Color(1, 1, 1, 0.85))

## the rockCoins wallet: a proper widget bottom-left (the chip law) -
## the panel, the chiseled rock-coin icon, and the count's Label
func _draw_wallet() -> void:
        var px := 18.0 * us
        var py := H - 92.0 * us
        var pw := 250.0 * us
        var ph := 62.0 * us
        var st := 0.28 + 0.06 * sin(_time * 3.0)
        fx_layer.draw_rect(Rect2(px, py, pw, ph), Color(0, 0, 0, st),
                false, 0.0, 14.0 * us)
        fx_layer.draw_rect(Rect2(px + 3.0 * us, py + 3.0 * us,
                pw - 6.0 * us, ph - 6.0 * us), Color(0, 0, 0, 0.22),
                false, 0.0, 11.0 * us)
        _draw_rockcoin(fx_layer, px + 30.0 * us, py + ph * 0.5, 20.0 * us)

func _boot_fresh() -> void:
        md = {}
        _meta_heal()
        over = false
        paused = false
        run_coins = 0
        set_score(0)
        _auto = false
        probe_reset(1)
