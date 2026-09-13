extends GogaGame
## BRICK BREAKER (v0.3.9-7) - the infinite paddle, graduated from the
## BRICK STORM teaser (the owner's rename law: "brick breaker is a genre
## and not a trademark name"). GDD: docs/goga_docs/gogames_ideas/brickbreaker.md.
##
## THE OWNER'S LAWS (binding, from the v0.3.9-7 message):
##   - HORIZONTAL ONLY ("for extra space for more bricks") - landscape.
##   - THE INFINITY LAW: endless levels, "different sizes and structures
##     ofc" - and NOT "another level = extra line of bricks with the
##     latest line requires more hits" (that "will look boring after 2
##     plays"). A mirrored pattern generator with real archetypes.
##   - THE HEART LAW: 3 hearts; "one extra heart for each 1000 brick
##     points"; a life is taken ONLY when all balls are out.
##   - THE POINT LAW: "a point is calculated as hits on one brick" - a
##     3-hit brick pays 3, a 10-hit brick pays 10. Damage dealt = points
##     paid, live, as the hits land (metal's double hits pay double).
##   - THE SCORE LAW: "each level cleared gives 1 score point, score
##     bonus is /3" (registry coin_div 3 - the dot eater shape). Brick
##     points are NOT score: they are the hearts' currency.
##   - THE COIN LAW: "a gogacoin will appear after each 300 bricks, not
##     brick points, real [bricks] broken, in one of the bricks" - every
##     300th break promotes an alive brick into the golden carrier.
##   - THE GATE LAW: "the game will start with the 'tap anywhere to
##     start' no optionals menu...yet" - the silent gate; the shop still
##     sells (merchandise, not options).
##   - THE PING-PONG CONTROL LAW: "like the game ping pong exactly, with
##     the same smooth 'platform follows finger' thing".
##   - THE FAIR TIMER LAW: "a timer that puts you to the limits, a timer
##     that is logically possible to beat but not too easy to achieve
##     from spamming ball at bricks. The algorithm should calculate size
##     of level, numbers of bricks, number of required hits, any powerups
##     pre-calculated and...that's it, so it stay fair". Time out = one
##     heart + a fresh timer; a lost ball keeps the clock running.
##   - THE DROP LAW: "2% of bricks have powerups and each one appear
##     after 40% of bricks broken, it appear at the 40%th brick and drop
##     from it". The first carrier is FORCED at the 40% mark (promoted
##     the moment the mark is crossed), the rest ride the 2% spread.
##   - THE SHOP-MAKES-DROPS LAW: "each powerup should be bought from the
##     shop for a good price so it really be able to appear in the game"
##     - only OWNED powerups join the drop pool.
##   - THE BUNDLE LAW: "the two-sided ones that make big/small slow/fast
##     should be as one bundle" - PADDLE, SPEED and SIZE sell as three
##     bundle rows (the catch picks a side).
##   - THE CAP LAW: the paddle grows "with no limits except the walls"
##     and shrinks to a hard floor (never invisible); ball speed has a
##     hard slowness floor and "speed be for x5"; ball size x0.25..x5
##     "with a size limit" (an absolute pixel ceiling).
##   - THE RESET LAW: "powerups get reset after each level" and "make
##     sure losing life resets the level powerups ofc" (hearts never
##     reset). Metal/fire wear 15-second timers; the bundles last the
##     level.
##   - THE VISUAL LAW: "speed be ball>> but size be ball but two up
##     arrows and the multiplier" - the effect chips wear a mini ball
##     icon; speed = ball + >> + xN, size = ball + ^^ + xN.
##   - THE NO-WEAPON LAW: "some brick breaker games add a powerup that
##     is basically giving the platform a weapon to shoot the bricks,
##     this eliminate the wow-factor for me" - NEVER.
##   - THE FROZEN LAW: "the frozen layer is external layer that takes
##     extra hit to reveal what is the brick under it".
##   - THE DECOR LAW: "decor platforms ... unbreakable ones ... make the
##     game more tactical where user could try to make the ball bounce
##     from one to the other".
##   - THE THEME LAW: 5 themes - "a default theme could be sky-blue with
##     fat joyful tone, also the neon one should be a theme" - and every
##     theme REDRAWS the bricks its own way, not just the palette.
##   - THE SKIN LAW: 5 paddle skins + 5 ball skins, the first of each
##     already default (free).
##   - THE FX LAW: "brick breaker game relies on audio feedback yes, but
##     i want it to have both audio and visual cool designs" - crack
##     lines grow per hit, breaks fade with particles, ice shatters,
##     metal/fire wear their own tone + trail, bricks fade in LINE BY
##     LINE from top to bottom at every level intro.
##   - THE OWNER'S ASSETS: the Drive pack's audio is vendored verbatim
##     (bb_*.mp3; the gap voices are synthesized - tools/v0397_audio.py),
##     the sprites feed the thumbnail + palette study; the game art stays
##     code-drawn (the box law).

## Probe contract: the level core is STATIC - gen_sizes / gen_level /
## timer_for / flood_ok / hp_band / ice_chance drive headless laws
## without the scene (the squares contract). The scene rides
## probe_reset(seed) + probe_step(dt); balls / paddle / ld / effects are
## public; the probe can wear an auto-paddle (_auto) that plays alone.

# =========================================================== THE LADDER
## THE SIZE LAW (the owner: "different sizes ... so it can really scale
## far away" + the maze escaper scaling taste): the grid grows with the
## level - cols 9..17, rows 5..12 - and the bricks SPAN THE FULL ARENA
## WIDTH ("the design of the levels should use the horizontal view, all
## of the pixels").
const BASE_COLS := 9
const BASE_ROWS := 5
const MAX_COLS := 17
const MAX_ROWS := 12
const COL_STEP := 3            # +1 col every 3 levels
const ROW_STEP := 4            # +1 row every 4 levels

# ------------------------------------------------------------ the core
const START_LIVES := 3         # "the game will start with 3 hearts"
const PTS_PER_LIFE := 1000     # "one extra heart for each 1000 brick points"
const BRICKS_PER_COIN := 300   # "a gogacoin will appear after each 300 bricks"
const POW_CHANCE := 0.02       # "2% of bricks have powerups"
const POW_GATE := 0.40         # "each one appear after 40% of bricks broken"
const METAL_TIME := 15.0       # "like 15 seconds is good enough"
const FIRE_TIME := 15.0
const MAX_BALLS := 6           # the multi cap (the board stays readable)

# ----------------------------------------------------------- the paddle
const PAD_BASE_W := 280.0      # design px (the 1920 canvas)
const PAD_MIN_W := 130.0       # THE HARD FLOOR ("small but not invisible")
const PAD_H := 26.0
const PAD_STEP_WIDE := 1.35    # each wide catch: x1.35, to the walls
const PAD_STEP_SMALL := 0.70   # each small catch: x0.70, to the floor
const PAD_Y_UP := 74.0         # paddle center above the arena's bottom

# -------------------------------------------------------------- the ball
const BALL_BASE_R := 15.0
const BALL_R_CAP := 58.0       # THE SIZE LIMIT (the absolute pixel ceiling)
const SIZE_MIN := 0.25         # "so it goes down to x0.25"
const SIZE_MAX := 5.0          # "and up to x5"
const SIZE_STEP_BIG := 1.45
const SIZE_STEP_SMALL := 0.72
const SPEED_MIN := 0.5         # the hard slowness floor
const SPEED_MAX := 5.0         # "speed be for x5"
const SPEED_STEP_FAST := 1.22
const SPEED_STEP_SLOW := 0.82
const BALL_BASE_SPEED := 560.0 # design px/s at level 1
const BALL_LEVEL_STEP := 1.025 # the climb (+2.5% a level, the run breathes)
const BALL_LEVEL_CAP := 1.60

# ----------------------------------------------------------- the layout
const WALL_T := 12.0           # the frame's thickness (design px)
const TOP_GAP := 118.0         # below the HUD row
const SIDE_GAP := 34.0
const BRICK_ASPECT := 0.46     # brick h = w * aspect (the pack's 75x37)
const SERVE_LAG := 0.055       # the intro's per-row lag (line by line)
const SERVE_FADE := 0.30       # each row's fade-in

# ================================================================== THEMES
## THE THEME LAW (the owner: "a default theme could be sky-blue with fat
## joyful tone, also the neon one should be a theme" + the pacman law:
## themes are not just colors). Every theme wears a BRICK STYLE that
## redraws the bricks its own way, a frame style, and its own palette.
const THEMES := {
        "sky": {"name": "SKY DAY", "price": 0, "style": "fat",
                "bricks": [Color(0.38, 0.93, 1.0), Color(0.75, 0.94, 0.36),
                        Color(1.0, 0.77, 0.49), Color(0.95, 0.70, 0.90),
                        Color(0.98, 0.55, 0.42)],
                "steel": Color(0.62, 0.68, 0.78), "ice": Color(0.72, 0.90, 1.0, 0.62),
                "bg_top": Color(0.53, 0.78, 0.97), "bg_mid": Color(0.68, 0.86, 0.98),
                "bg_bot": Color(0.85, 0.93, 0.99), "bg_grid": Color(0.72, 0.85, 0.98),
                "frame": Color(0.30, 0.52, 0.78), "room": Color(0.78, 0.90, 0.98),
                "ink": Color(0.16, 0.28, 0.44),
                "desc": "the fat joyful default - clouds and gloss"},
        "neon": {"name": "NEON COURT", "price": 300, "style": "glow",
                "bricks": [Color(0.45, 0.95, 1.0), Color(0.42, 1.0, 0.62),
                        Color(1.0, 0.82, 0.30), Color(1.0, 0.52, 0.86),
                        Color(1.0, 0.40, 0.36)],
                "steel": Color(0.55, 0.60, 0.75), "ice": Color(0.62, 0.88, 1.0, 0.55),
                "bg_top": Color(0.030, 0.045, 0.11), "bg_mid": Color(0.055, 0.07, 0.16),
                "bg_bot": Color(0.015, 0.025, 0.06), "bg_grid": Color(0.14, 0.20, 0.42),
                "frame": Color(0.45, 0.95, 1.0), "room": Color(0.020, 0.028, 0.07),
                "ink": Color(0.85, 0.95, 1.0),
                "desc": "the known neon - glow outlines on the grid"},
        "arcade": {"name": "ARCADE '80", "price": 360, "style": "flat",
                "bricks": [Color(0.22, 0.55, 1.0), Color(0.20, 0.85, 0.55),
                        Color(0.95, 0.78, 0.25), Color(0.90, 0.42, 0.78),
                        Color(0.92, 0.36, 0.32)],
                "steel": Color(0.48, 0.52, 0.62), "ice": Color(0.55, 0.80, 1.0, 0.50),
                "bg_top": Color(0.016, 0.016, 0.05), "bg_mid": Color(0.012, 0.012, 0.04),
                "bg_bot": Color(0.008, 0.008, 0.03), "bg_grid": Color(0.05, 0.05, 0.14),
                "frame": Color(0.22, 0.32, 1.0), "room": Color(0.010, 0.010, 0.035),
                "ink": Color(0.80, 0.85, 1.0),
                "desc": "the 1980 homage - flat blocks, twin strokes"},
        "dungeon": {"name": "DUNGEON", "price": 420, "style": "bevel",
                "bricks": [Color(0.45, 0.62, 0.72), Color(0.48, 0.66, 0.50),
                        Color(0.72, 0.62, 0.38), Color(0.70, 0.50, 0.55),
                        Color(0.66, 0.42, 0.40)],
                "steel": Color(0.42, 0.38, 0.34), "ice": Color(0.62, 0.80, 0.92, 0.55),
                "bg_top": Color(0.070, 0.055, 0.038), "bg_mid": Color(0.055, 0.042, 0.030),
                "bg_bot": Color(0.038, 0.030, 0.022), "bg_grid": Color(0.16, 0.12, 0.08),
                "frame": Color(0.52, 0.46, 0.38), "room": Color(0.045, 0.036, 0.026),
                "ink": Color(0.90, 0.85, 0.75),
                "desc": "torchlit stone - the bevel of the keep"},
        "candy": {"name": "CANDY PAGE", "price": 480, "style": "candy",
                "bricks": [Color(0.62, 0.88, 1.0), Color(0.78, 0.94, 0.62),
                        Color(1.0, 0.86, 0.60), Color(1.0, 0.76, 0.88),
                        Color(0.98, 0.68, 0.72)],
                "steel": Color(0.72, 0.70, 0.78), "ice": Color(0.80, 0.93, 1.0, 0.60),
                "bg_top": Color(0.988, 0.945, 0.960), "bg_mid": Color(0.975, 0.925, 0.945),
                "bg_bot": Color(0.960, 0.905, 0.935), "bg_grid": Color(0.90, 0.80, 0.86),
                "frame": Color(0.90, 0.62, 0.76), "room": Color(0.935, 0.885, 0.915),
                "ink": Color(0.45, 0.25, 0.38),
                "desc": "the sugar page - pastel rounds and sprinkles"},
}

# ------------------------------------------------------------------ SKINS
## THE PADDLE SKINS (the bat's coats). Code-drawn - a skin is a palette.
const SKINS := {
        "classic": {"name": "COURT CLASSIC", "price": 0,
                "body": Color(0.94, 0.98, 1.0), "edge": Color(0.35, 0.80, 0.95),
                "desc": "the white-cyan original"},
        "sunset": {"name": "SUNSET BAT", "price": 140,
                "body": Color(1.0, 0.72, 0.38), "edge": Color(0.95, 0.42, 0.30),
                "desc": "the warm glide"},
        "lime": {"name": "LIME BAT", "price": 180,
                "body": Color(0.72, 0.95, 0.45), "edge": Color(0.35, 0.72, 0.30),
                "desc": "the sour return"},
        "grape": {"name": "GRAPE BAT", "price": 230,
                "body": Color(0.72, 0.58, 0.95), "edge": Color(0.45, 0.32, 0.70),
                "desc": "the velvet wall"},
        "steel": {"name": "STEEL BAT", "price": 300,
                "body": Color(0.58, 0.62, 0.70), "edge": Color(0.30, 0.34, 0.42),
                "desc": "the gunmetal guard"},
}

## THE BALL SKINS (Box items, cat "ballskin" - the skin shelf is the
## paddle's; the ball wears its own).
const BALLS := {
        "pearl": {"name": "PEARL", "price": 0,
                "body": Color(0.97, 0.99, 1.0), "glow": Color(0.62, 0.90, 1.0),
                "desc": "the pearl original"},
        "ember": {"name": "EMBER", "price": 140,
                "body": Color(1.0, 0.62, 0.30), "glow": Color(1.0, 0.40, 0.15),
                "desc": "the little sun"},
        "mint": {"name": "MINT ORB", "price": 180,
                "body": Color(0.55, 0.95, 0.70), "glow": Color(0.30, 0.80, 0.55),
                "desc": "the cool bounce"},
        "berry": {"name": "BERRY", "price": 230,
                "body": Color(1.0, 0.55, 0.78), "glow": Color(0.85, 0.30, 0.55),
                "desc": "the sweet hit"},
        "void": {"name": "VOID", "price": 300,
                "body": Color(0.20, 0.20, 0.28), "glow": Color(0.75, 0.60, 1.0),
                "desc": "the midnight ball"},
}

# -------------------------------------------------------------- POWERUPS
## THE SHOP-MAKES-DROPS LAW: only OWNED kinds join the drop pool. The
## three two-sided laws sell as BUNDLES (the catch picks the side).
const POWS := {
        "pad": {"name": "PADDLE WIDE/SMALL", "price": 260,
                "desc": "the paddle bundle: wide rides to the walls, "
                        + "small down to the honest floor - per level"},
        "spd": {"name": "BALL FAST/SLOW", "price": 260,
                "desc": "the speed bundle: fast up to x5, slow down to "
                        + "the x0.5 floor - per level"},
        "size": {"name": "BALL BIG/SMALL", "price": 280,
                "desc": "the size bundle: big up to x5 (capped in pixels), "
                        + "small down to x0.25 - per level"},
        "multi": {"name": "MULTIBALL", "price": 320,
                "desc": "one more ball, up to 6 - a life is lost only "
                        + "when ALL balls are out"},
        "metal": {"name": "METAL BALL", "price": 300,
                "desc": "double hits for 15s - the clang tone"},
        "fire": {"name": "FIRE BALL", "price": 340,
                "desc": "pass-through for 15s - burns through bricks"},
}

# ========================================================== THE GENERATOR
## Static so tests drive it without the scene (the squares contract). A
## level = a mirrored pattern (the pacman symmetry law - mirrored reads
## designed): archetypes + seeded params, then VALIDATED (every
## breakable brick must be reachable by the ball - the flood law).

## the grid sizes for level #n (1-based): the endless growth ladder.
## cols stay ODD - the mirror seam stays a real column (the pacman
## symmetry law; the checker and the fortress read it too).
static func gen_sizes(level: int) -> Vector2i:
        var cols: int = mini(BASE_COLS + (level - 1) / COL_STEP, MAX_COLS)
        if cols % 2 == 0:
                cols += 1
        var rows: int = mini(BASE_ROWS + (level - 1) / ROW_STEP, MAX_ROWS)
        return Vector2i(cols, rows)

## the hp band for level #n (1-based): the climb the owner wants felt
static func hp_band(level: int) -> Vector2i:
        if level <= 2:
                return Vector2i(1, 1)
        if level <= 5:
                return Vector2i(1, 2)
        if level <= 9:
                return Vector2i(1, 3)
        if level <= 14:
                return Vector2i(2, 4)
        if level <= 19:
                return Vector2i(2, 6)
        if level <= 29:
                return Vector2i(3, 7)
        return Vector2i(3, 10)

## the frozen-layer chance for level #n (the ice climbs, then caps)
static func ice_chance(level: int) -> float:
        if level <= 3:
                return 0.0
        return minf(0.05 + float(level - 3) * 0.012, 0.22)

## a weighted hp pick inside the band (the low end common, the top rare)
static func pick_hp(level: int, rng: RandomNumberGenerator) -> int:
        var band := hp_band(level)
        var pool: Array = []
        for v in range(band.x, band.y + 1):
                var w := 1
                if band.y > band.x:
                        w = maxi(1, int(round(4.0 / float(v - band.x + 1))))
                for i in w:
                        pool.append(v)
        return pool[rng.randi_range(0, pool.size() - 1)]

## one archetype cell pass: returns "b" (brick) / "d" (decor) / ""
static func _arch_cell(arch: String, c: int, r: int, cols: int, rows: int) -> String:
        var cc := (cols - 1) * 0.5
        var dc := absf(float(c) - cc)   # the mirror distance (symmetry free)
        match arch:
                "filled":
                        return "b"
                "checker":
                        # the classic checkerboard (mirrored by parity)
                        return "b" if (c + r) % 2 == 0 else ""
                "pyramid":
                        # fat top, narrow waist (the tent)
                        var hw := (float(r) + 1.0) * (cc + 0.5) / float(rows)
                        return "b" if dc <= hw else ""
                "diamond":
                        # the rhombus
                        var rr := float(rows) * 0.5
                        return "b" if (dc / (cc + 0.5) \
                                        + absf(float(r) - rr + 0.5) / rr) <= 1.0 \
                                        else ""
                "arch":
                        # the block with a hall: brick everywhere except the
                        # center arch (rows 1..rows-2); steel pillars hold it
                        if r >= 1 and r <= rows - 2 and dc < cc * 0.45:
                                return ""
                        if (r == 1 or r == rows - 2) \
                                        and dc < cc * 0.45 + 1.0 \
                                        and dc >= cc * 0.45:
                                return "d"      # the pillars
                        return "b"
                "fortress":
                        # the shell (thick, strong) around a soft core
                        if r == 0 or r == rows - 1 or dc >= cc - 1.0:
                                return "b"      # the shell (hp set later)
                        if (r == 1 or r == rows - 2) and dc >= cc - 2.0:
                                return "d"      # the inner keep walls
                        return "b"
                "rain":
                        # the columns: even columns full height, odd stubs
                        if c % 2 == 0:
                                return "b"
                        return "b" if r < ceili(float(rows) * 0.45) else ""
                "ring":
                        # the rectangle ring with a yard inside
                        if r <= 1 or r >= rows - 2 or dc >= cc - 0.5:
                                return "b"
                        if absf(float(r) - (float(rows) - 1.0) * 0.5) < 0.6 \
                                        and dc < 1.2:
                                return "d"      # the yard's stone
                        return ""
                "zigzag":
                        # the woven bands (symmetric via the mirror distance)
                        var k := float(r) + dc * 0.9
                        return "b" if int(k) % 3 != 2 else ""
                "towers":
                        # two strong towers + a thin sky bridge
                        if dc >= cc - 2.5:
                                return "b"
                        if r <= 1:
                                return "b"
                        return ""
                "tunnels":
                        # brick bands with steel shelf rows between them
                        # (the shelves leave a CENTER GAP - the ball weaves
                        # through it and the flood law stays honest)
                        var third := float(rows) / 3.0
                        if absf(fmod(float(r), third * 1.5)) < third * 0.62:
                                return "b"
                        if absf(fmod(float(r) + third * 0.75, third * 1.5)) \
                                        < third * 0.14 and dc > 1.5:
                                return "d"      # the steel shelves
                        return "b"
        return "b"

## the archetype pool for a level (the early levels teach, the rest roll)
static func _arch_pool(level: int) -> Array:
        if level <= 2:
                return ["filled", "checker"]
        if level <= 4:
                return ["filled", "checker", "pyramid", "rain"]
        return ["filled", "checker", "pyramid", "diamond", "arch",
                "fortress", "rain", "ring", "zigzag", "towers", "tunnels"]

## the FLOOD LAW: which open cells connect to the bottom air (the ball's
## world). `blocked` = brick or decor cells. Returns the flooded set.
static func flood_open(cols: int, rows: int, blocked: Dictionary) -> Dictionary:
        var seen: Dictionary = {}
        var q: Array = []
        for c in cols:
                var start := Vector2i(c, rows - 1)
                if not blocked.has(start):
                        seen[start] = true
                        q.append(start)
        var i := 0
        while i < q.size():
                var cur: Vector2i = q[i]
                i += 1
                for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1),
                                Vector2i(0, -1)]:
                        var nx: Vector2i = cur + d
                        if nx.x < 0 or nx.y < 0 or nx.x > cols - 1 \
                                        or nx.y > rows - 1:
                                continue
                        if blocked.has(nx) or seen.has(nx):
                                continue
                        seen[nx] = true
                        q.append(nx)
        return seen

## THE LEVEL (static, deterministic under a seeded rng). Every breakable
## brick must sit beside a flooded open cell - or ride the BOTTOM ROW
## (its under-face meets the open arena the ball flies in, the serve
## law) - or it is VOID: knocked out, never shipped (the flow law).
static func gen_level(level: int, rng: RandomNumberGenerator) -> Dictionary:
        var cols := gen_sizes(level).x
        var rows := gen_sizes(level).y
        var pool := _arch_pool(level)
        var arch: String = pool[rng.randi_range(0, pool.size() - 1)]
        for attempt in 8:
                var cells: Dictionary = {}
                for r in rows:
                        for c in cols:
                                var kind := _arch_cell(arch, c, r, cols, rows)
                                if kind == "":
                                        continue
                                var cell := {"decor": kind == "d", "hp": 0,
                                        "ice": false}
                                if kind == "b":
                                        cell["hp"] = pick_hp(level, rng)
                                        # the fortress shell wears the band's
                                        # top (the strong face out)
                                        if arch == "fortress" and (r == 0 \
                                                        or r == rows - 1 \
                                                        or c == 0 \
                                                        or c == cols - 1):
                                                cell["hp"] = hp_band(level).y
                                        # THE FROZEN LAW: the ice rides the
                                        # brick (never the steel)
                                        cell["ice"] = rng.randf() \
                                                        < ice_chance(level)
                                cells[Vector2i(c, r)] = cell
                # THE FLOOD LAW: knock out bricks the ball can never
                # touch. The honest model: breakable bricks are PASSABLE
                # (they fall and open the way); only the STEEL seals
                # forever - so the flood runs on decor alone, and a
                # breakable is void only when the steel entombs it.
                var blocked: Dictionary = {}
                for key in cells.keys():
                        if bool(cells[key]["decor"]):
                                blocked[key] = true
                var seen := flood_open(cols, rows, blocked)
                var dead: Array = []
                for key in cells.keys():
                        if bool(cells[key]["decor"]):
                                continue
                        if not seen.has(key):
                                dead.append(key)
                for key in dead:
                        cells.erase(key)
                # the count + the totals (ice wears the extra hit)
                var breakable := 0
                var hits := 0
                for key in cells.keys():
                        if bool(cells[key]["decor"]):
                                continue
                        breakable += 1
                        hits += int(cells[key]["hp"]) \
                                        + (1 if bool(cells[key]["ice"]) else 0)
                if breakable > 0:
                        # THE CARRIERS: the 2% of bricks that wear a
                        # powerup (the DROP LAW spreads the first one at
                        # the 40% mark at runtime). THE SEEDED SHUFFLE:
                        # Array.shuffle() rides the GLOBAL rng - a seeded
                        # Fisher-Yates keeps the whole level deterministic
                        var carriers: Array = []
                        var keys := cells.keys()
                        for i in range(keys.size() - 1, 0, -1):
                                var j := rng.randi_range(0, i)
                                var tmp = keys[i]
                                keys[i] = keys[j]
                                keys[j] = tmp
                        var want := maxi(1, int(round(float(breakable) \
                                        * POW_CHANCE)))
                        for key in keys:
                                if carriers.size() >= want:
                                        break
                                if not bool(cells[key]["decor"]):
                                        carriers.append(key)
                        return {"cols": cols, "rows": rows, "arch": arch,
                                "cells": cells, "carriers": carriers,
                                "breakable": breakable, "hits": hits}
                # the attempt drowned in decor: roll a fresh archetype
                arch = pool[rng.randi_range(0, pool.size() - 1)]
        # unreachable guard (never on these archetypes): a plain filled grid
        var cells2: Dictionary = {}
        for r in rows:
                for c in cols:
                        cells2[Vector2i(c, r)] = {"decor": false,
                                "hp": pick_hp(level, rng), "ice": false}
        return {"cols": cols, "rows": rows, "arch": "filled",
                "cells": cells2, "carriers": [],
                "breakable": cols * rows,
                "hits": cols * rows * int(hp_band(level).x)}

## THE FAIR TIMER (the owner's formula inputs: "size of level, numbers of
## bricks, number of required hits, any powerups pre-calculated"). The
## CALIBRATION is the sim's own truth (the qa rig plays real levels): a
## paddle round-trip crosses the field TWICE and touches only a few
## bricks - hpc models the FIELD DEPTH (rows), not the arena width, and
## the efficiency reads what the rig actually achieved. The mercy eases
## the first levels; the clamp keeps every level in the honest band.
## "Logically possible to beat, not too easy to spam" - the idle ball
## pays the clock, the aimed ball beats it.
static func timer_for(breakable: int, hits: int, arena_w: float,
                arena_h: float, ball_speed: float, level: int,
                owns_pows: bool) -> float:
        var trip := 2.0 * arena_h / maxf(1.0, ball_speed)
        var hpc := clampf(float(gen_sizes(level).y) * 0.85, 2.5, 10.0)
        var t := 8.0 + 0.32 * float(breakable) \
                        + (float(hits) / hpc) * trip / 0.42
        var mercy := 1.30
        if level >= 4:
                mercy = 1.15
        if level >= 8:
                mercy = 1.0
        var out := clampf(t * mercy, 30.0, 300.0)
        if owns_pows:
                # the pre-calculated powerup credit discounts the FINAL
                # bank (before the clamp it would vanish at the ceiling)
                out = maxf(30.0, out * 0.95)
        return out

# ============================================================ THE SCENE
var us := 1.0
var rng := RandomNumberGenerator.new()
var ld: Dictionary = {}          # the live level (the static shape above)
var level_i := 1                 # 1-based (the endless ladder)
var lives := START_LIVES
var pts := 0                     # brick points (the hearts' currency)
var life_next := PTS_PER_LIFE    # the next extra-heart milestone
var bricks_broken := 0           # run lifetime (THE COIN LAW's counter)
var coin_pending := 0            # coins owed (a level can end before)
var broken_this_level := 0
var gate_crossed := false        # the 40% drop gate
var banked_pows := 0             # carriers broken before the gate
var balls: Array = []            # [{x, y, dx, dy, r, stuck, trail: Array}]
var drops: Array = []            # falling powerups [{x, y, vy, kind, t}]
var phase := "boot"              # boot|intro|serve|play|clear|over
var level_time := 30.0           # the fair timer's bank (per level)
var time_left := 30.0
var intro_t := 0.0
var clear_t := 0.0
var _time := 0.0                 # the game clock (the living layer law)

# the effects (THE RESET LAW: per level - gone on clear/life loss/time up)
var pad_mult := 1.0
var spd_mult := 1.0
var size_mult := 1.0
var metal_t := 0.0
var fire_t := 0.0

# the paddle (the ping-pong control: the finger's wish, smoothed)
var pad_x := 960.0
var pad_target := 960.0
var pad_squash := 0.0
var _held := -1                  # THE HELD FINGER (the rally law)
var _auto := false               # the qa auto-paddle (the simulation)
var _auto_t := 0.0

# layout (design px - the static pixels law, landscape 1920x1080+)
var arena := Rect2(34, 118, 1852, 800)
var brick_zone_h := 560.0
var bw := 100.0                  # brick cell w (the grid spans the arena)
var bh := 46.0
var paddle_y := 990.0
var lose_y := 1040.0

# nodes
var bg: ColorRect = null
var bg_mat: ShaderMaterial = null
var frame_layer: Node2D = null
var brick_layer: Node2D = null
var char_layer: Node2D = null
var fx_layer: Node2D = null
var gate_ui: Control = null
var banner_lbl: Label = null
var banner_t := 0.0
var lives_lbl: Label = null
var pts_lbl: Label = null
var lvl_lbl: Label = null
var time_lbl: Label = null
var spd_lbl: Label = null
var size_lbl: Label = null
var pad_lbl: Label = null
var metal_lbl: Label = null
var fire_lbl: Label = null
var spd_chip: Control = null
var size_chip: Control = null
var pad_chip: Control = null
var metal_chip: Control = null
var fire_chip: Control = null
var _fx: Array = []              # [{x, y, vx, vy, life, max, s, col}]
var shop_id := ""
var tex := {}                    # the painted mini icons

## the pause END is a RUN-LIVE row only (the gate/intro keep it hidden)
func _goga_pause_end_ok() -> bool:
        return phase == "play" or phase == "serve"

func _vp() -> Vector2:
        return get_viewport_rect().size

func _theme() -> Dictionary:
        var tid := Box.item_on(game_id, "theme")
        if not THEMES.has(tid):
                tid = "sky"
        return THEMES[tid]

func _skin() -> Dictionary:
        var sid := Box.skin_on(game_id)
        if not SKINS.has(sid):
                sid = "classic"
        return SKINS[sid]

func _ball_skin() -> Dictionary:
        var bid := Box.item_on(game_id, "ballskin")
        if not BALLS.has(bid):
                bid = "pearl"
        return BALLS[bid]

# =================================================================== setup
func _goga_setup() -> void:
        rng.randomize()
        game_id = "brickbreaker"
        var vp := _vp()
        us = vp.y / 1080.0
        tk.tapped.connect(_tap_anywhere)
        _build_world()
        _build_hud_extra()
        # THE SHOP LAW: merchandise in the HUD, options DO NOT EXIST here
        add_hud_button("SHOP", func(): _shop_open())
        pause_end_run = true         # the pause END banks (the endless run)
        _layout()
        _new_level(1, true)
        phase = "boot"               # the gate owns the first breath
        _build_gate()

## the arena seats itself off the REAL viewport (the spare-axis law:
## the landscape canvas grows WIDER, never shorter - but the bottom
## still reads the banner strip's reservation)
func _layout() -> void:
        var vp := _vp()
        us = vp.y / 1080.0
        var bot := vp.y - banner_bottom()
        arena = Rect2(SIDE_GAP * us, TOP_GAP * us,
                        vp.x - SIDE_GAP * 2.0 * us,
                        bot - TOP_GAP * us - 40.0 * us)
        paddle_y = bot - PAD_Y_UP * us
        lose_y = bot + 24.0 * us
        pad_x = clampf(pad_x, arena.position.x + _pad_w() * 0.5,
                        arena.end.x - _pad_w() * 0.5)
        pad_target = pad_x

func _pad_w() -> float:
        var w := PAD_BASE_W * pad_mult
        return clampf(w, PAD_MIN_W * us, arena.size.x - 30.0 * us)

func _ball_speed() -> float:
        var lm := minf(BALL_LEVEL_CAP, pow(BALL_LEVEL_STEP, float(level_i - 1)))
        return BALL_BASE_SPEED * us * lm * spd_mult

func _ball_r() -> float:
        var sm := clampf(size_mult, SIZE_MIN, SIZE_MAX)
        return minf(BALL_BASE_R * us * sm, BALL_R_CAP * us)

func _build_world() -> void:
        bg = ColorRect.new()
        bg.size = _vp()
        bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
        bg_mat = ShaderMaterial.new()
        bg_mat.shader = load("res://game/games/geometry/fx/gf_bg.gdshader")
        bg.material = bg_mat
        add_child(bg)
        _apply_theme()
        frame_layer = Node2D.new()
        frame_layer.draw.connect(_draw_frame)
        add_child(frame_layer)
        brick_layer = Node2D.new()
        brick_layer.draw.connect(_draw_bricks)
        add_child(brick_layer)
        char_layer = Node2D.new()
        char_layer.draw.connect(_draw_chars)
        add_child(char_layer)
        fx_layer = Node2D.new()
        fx_layer.draw.connect(_draw_fx)
        add_child(fx_layer)

func _apply_theme() -> void:
        var t := _theme()
        bg_mat.set_shader_parameter("col_top", t["bg_top"])
        bg_mat.set_shader_parameter("col_mid", t["bg_mid"])
        bg_mat.set_shader_parameter("col_bot", t["bg_bot"])
        var style := String(t["style"])
        if style == "glow":
                bg_mat.set_shader_parameter("line_col", t["bg_grid"])
                bg_mat.set_shader_parameter("pulse", 0.22)
        else:
                # the shader ADDS line_col.rgb (alpha ignored) - the flat
                # pages wear a grid tinted INTO their own air (the sky's
                # breeze lines, the arcade's near-black whispers)
                bg_mat.set_shader_parameter("line_col", t["bg_grid"])
                bg_mat.set_shader_parameter("pulse", 0.12)
        for key in tex.keys():
                tex.erase(key)
        _paint_icons()
        # THE LIVING LAYER LAW: the theme mutates every layer's look -
        # bricks (style + palette), the chars (skins), the frame, the air
        if frame_layer != null and is_instance_valid(frame_layer):
                frame_layer.queue_redraw()
        if brick_layer != null and is_instance_valid(brick_layer):
                brick_layer.queue_redraw()
        if char_layer != null and is_instance_valid(char_layer):
                char_layer.queue_redraw()

## a glossy mini brick in the theme's tier color (the pts chip's icon)
func _make_brick_texture(col: Color) -> ImageTexture:
        var w := 52
        var h := 30
        var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
        var rr := 7.0
        for y in h:
                for x in w:
                        var px := Vector2(x + 0.5, y + 0.5)
                        # the rounded-rect mask
                        var qx := maxf(absf(px.x - w * 0.5) - (w * 0.5 - rr),
                                        0.0)
                        var qy := maxf(absf(px.y - h * 0.5) - (h * 0.5 - rr),
                                        0.0)
                        var d := Vector2(qx, qy).length() - rr
                        if d > 0.0:
                                continue
                        var shade := 1.16 - 0.36 * (px.y / float(h))
                        var a := clampf(-d / 1.4, 0.0, 1.0)
                        img.set_pixel(x, y, Color(
                                clampf(col.r * shade, 0.0, 1.0),
                                clampf(col.g * shade, 0.0, 1.0),
                                clampf(col.b * shade, 0.0, 1.0), a))
        return ImageTexture.create_from_image(img)

## the mini ball icon (the VISUAL LAW's chip ball)
func _make_ball_texture(body: Color, glow: Color) -> ImageTexture:
        var sz := 40
        var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
        var c := Vector2(sz, sz) * 0.5
        for y in sz:
                for x in sz:
                        var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
                        if d > sz * 0.46:
                                continue
                        var k := d / (sz * 0.40)
                        var col := glow if d > sz * 0.40 else body
                        var shade := 1.2 - 0.45 * clampf(k, 0.0, 1.0)
                        img.set_pixel(x, y, Color(
                                clampf(col.r * shade, 0.0, 1.0),
                                clampf(col.g * shade, 0.0, 1.0),
                                clampf(col.b * shade, 0.0, 1.0),
                                clampf(1.0 - (d - sz * 0.40) / 3.0, 0.0, 1.0)))
        return ImageTexture.create_from_image(img)

## the mini paddle icon (the pad chip's icon)
func _make_pad_texture(body: Color) -> ImageTexture:
        var w := 52
        var h := 18
        var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
        for y in h:
                for x in w:
                        var k := float(y) / float(h)
                        var shade := 1.18 - 0.4 * k
                        img.set_pixel(x, y, Color(
                                clampf(body.r * shade, 0.0, 1.0),
                                clampf(body.g * shade, 0.0, 1.0),
                                clampf(body.b * shade, 0.0, 1.0),
                                1.0 if y > 1 and y < h - 2 else 0.35))
        return ImageTexture.create_from_image(img)

func _paint_icons() -> void:
        if pts_lbl != null and is_instance_valid(pts_lbl):
                var ph := pts_lbl.get_parent() as HBoxContainer
                if ph != null and ph.get_child_count() > 0 \
                                and ph.get_child(0) is TextureRect:
                        var tr: TextureRect = ph.get_child(0)
                        tr.texture = _make_brick_texture(
                                        _theme()["bricks"][0])

func _build_hud_extra() -> void:
        # THE HEARTS (the heart chip)
        lives_lbl = add_hud_chip(str(START_LIVES),
                        "res://assets/ui/heart.png")
        # THE BRICK POINTS (the hearts' currency - NOT score; the chip
        # wears the theme-painted brick icon, the dot-counter's law)
        pts_lbl = add_hud_chip("0")
        var ph := pts_lbl.get_parent() as HBoxContainer
        if ph != null:
                var bi := TextureRect.new()
                bi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                bi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                bi.custom_minimum_size = Vector2(34.0, 22.0) * us
                bi.mouse_filter = Control.MOUSE_FILTER_IGNORE
                bi.texture = _make_brick_texture(_theme()["bricks"][0])
                ph.add_child(bi)
                ph.move_child(bi, 0)
        # THE LEVEL + THE FAIR TIMER
        lvl_lbl = add_hud_chip("L1")
        time_lbl = add_hud_chip("0:00")
        # THE EFFECT CHIPS (the VISUAL LAW: ball + arrows + multiplier)
        spd_lbl = add_hud_chip("x1.00")
        spd_chip = _chip_of(spd_lbl)
        size_lbl = add_hud_chip("x1.00")
        size_chip = _chip_of(size_lbl)
        pad_lbl = add_hud_chip("x1.00")
        pad_chip = _chip_of(pad_lbl)
        metal_lbl = add_hud_chip("15")
        metal_chip = _chip_of(metal_lbl)
        fire_lbl = add_hud_chip("15")
        fire_chip = _chip_of(fire_lbl)
        _dress_chip(spd_chip, "spd")
        _dress_chip(size_chip, "size")
        _dress_chip(pad_chip, "pad")
        _dress_chip(metal_chip, "metal")
        _dress_chip(fire_chip, "fire")
        for chip in [spd_chip, size_chip, pad_chip, metal_chip, fire_chip]:
                chip.visible = false
        # THE SEAT LAW: hearts | pts | level | time sit LEFT of the score
        # chip; the effect chips ride AFTER the score.
        var score_chip := _score_chip_ref()
        if score_chip != null:
                for chip in [_chip_of(lives_lbl), _chip_of(pts_lbl),
                                _chip_of(lvl_lbl), _chip_of(time_lbl)]:
                        _hud_row.move_child(chip, score_chip.get_index())
        # the flash banner (READY / LEVEL CLEAR / the deaths' verdicts)
        banner_lbl = Arc.label("", 60, Color(1, 1, 1, 0))
        banner_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
        banner_lbl.offset_top = 140.0 * us
        banner_lbl.offset_bottom = 216.0 * us
        banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _hud.add_child(banner_lbl)

## the effect chip's icon (the VISUAL LAW's ball/paddle dress)
func _dress_chip(chip: Control, kind: String) -> void:
        if chip == null or not is_instance_valid(chip):
                return
        var row := chip.get_child(0) as HBoxContainer
        if row == null:
                return
        var tr := TextureRect.new()
        tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tr.custom_minimum_size = Vector2(30.0, 30.0) * us
        tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
        match kind:
                "spd", "size":
                        tr.texture = _make_ball_texture(
                                        _ball_skin()["body"],
                                        _ball_skin()["glow"])
                "pad":
                        tr.texture = _make_pad_texture(_skin()["body"])
                "metal":
                        tr.texture = _make_ball_texture(
                                        Color(0.72, 0.76, 0.84),
                                        Color(0.45, 0.50, 0.60))
                "fire":
                        tr.texture = _make_ball_texture(
                                        Color(1.0, 0.55, 0.25),
                                        Color(1.0, 0.30, 0.10))
        row.add_child(tr)
        row.move_child(tr, 0)

func _chip_of(lbl: Label) -> Control:
        if lbl == null or lbl.get_parent() == null \
                        or lbl.get_parent().get_parent() == null:
                return null
        return lbl.get_parent().get_parent() as Control

func _flash(txt: String, col := Color(1, 1, 1, 1)) -> void:
        banner_lbl.text = txt
        banner_lbl.modulate = Color(col, 0.0)
        banner_t = 1.0

# ================================================== the level life-cycle
## THE STATE LAW: every transition walks through ONE door. The gate tap
## opens the intro; the intro ends into the serve; the serve's tap
## launches the play; the clear/life-loss/time-up doors re-seat the
## whole machine (phase + timers + chips) in one place each.

func _new_level(n: int, first := false) -> void:
        level_i = n
        _layout()
        ld = gen_level(n, rng)
        # the shipped-at tier (the crack lines read it back) + the gate's
        # 40% anchor (the level's ORIGINAL count - the shrinking live
        # count would walk the mark earlier every break)
        for key in ld["cells"].keys():
                var c0: Dictionary = ld["cells"][key]
                if not bool(c0["decor"]):
                        c0["hp0"] = int(c0["hp"])
        ld["total0"] = int(ld["breakable"])
        bw = arena.size.x / float(ld["cols"])
        var zone := arena.size.y - 250.0 * us
        bh = minf(bw * BRICK_ASPECT, 96.0 * us)
        if float(ld["rows"]) * bh > zone:
                bh = zone / float(ld["rows"])
        brick_zone_h = float(ld["rows"]) * bh
        # THE RESET LAW: powerups reset after each level
        _reset_effects()
        gate_crossed = false
        banked_pows = 0
        broken_this_level = 0
        drops = []
        balls = []
        _fx = []
        # THE FAIR TIMER (the owner's formula, the level's own numbers)
        level_time = timer_for(int(ld["breakable"]), int(ld["hits"]),
                        arena.size.x, arena.size.y, BALL_BASE_SPEED * us,
                        n, _owns_any_pow())
        time_left = level_time
        lvl_lbl.text = "L%d" % n
        _set_time_chip()
        time_lbl.modulate = Color(1, 1, 1, 1)
        phase = "intro"
        intro_t = 0.0
        _flash("LEVEL %d" % n, _theme()["ink"])
        brick_layer.queue_redraw()
        char_layer.queue_redraw()

func _reset_effects() -> void:
        pad_mult = 1.0
        spd_mult = 1.0
        size_mult = 1.0
        metal_t = 0.0
        fire_t = 0.0
        _sync_effect_chips()

func _owns_any_pow() -> bool:
        for id in POWS.keys():
                if Box.item_owned(game_id, "powerup", String(id)):
                        return true
        return false

func _spawn_serve_ball() -> void:
        balls = [{
                "x": pad_x, "y": paddle_y - PAD_H * us * 0.5 - _ball_r(),
                "dx": 0.0, "dy": 0.0, "r": _ball_r(), "stuck": true,
                "trail": []}]
        phase = "serve"
        Jukebox.sfx("bb_serve", -6.0)

func _launch_ball(b: Dictionary) -> void:
        var ang := -PI * 0.5 + rng.randf_range(-0.24, 0.24)
        # THE AUTO SERVE: the simulation aims its launch at the nearest
        # alive brick (a human aims; the random serve is the player's)
        if _auto:
                var target := Vector2(pad_x, arena.position.y)
                var bd := 1 << 30
                for key in ld["cells"].keys():
                        var c: Dictionary = ld["cells"][key]
                        if bool(c["decor"]) or int(c["hp"]) <= 0 \
                                        or c.has("dying"):
                                continue
                        var cr := _cell_rect(key)
                        var dd := int(absf(cr.get_center().x - b["x"]) \
                                        + absf(cr.get_center().y \
                                                        - b["y"]) * 0.4)
                        if dd < bd:
                                bd = dd
                                target = cr.get_center()
                var to := target - Vector2(float(b["x"]), float(b["y"]))
                if to.length() > 1.0:
                        var want := to.angle()
                        var up := -PI * 0.5
                        var lim := PI / 3.0
                        ang = clampf(want, up - lim, up + lim)
        var spd := _ball_speed()
        b["dx"] = cos(ang) * spd
        b["dy"] = sin(ang) * spd
        b["stuck"] = false

func _level_clear() -> void:
        # THE SCORE LAW: each level cleared gives 1 score point
        add_score(1)
        achievement_max("max_levels", level_i)
        achievement_count("clears", 1)
        phase = "clear"
        clear_t = 0.95
        _flash("LEVEL CLEAR!", Color(0.55, 1.0, 0.65))
        Jukebox.sfx("bb_clear", -2.0)
        # THE RESET LAW: powerups reset after each level
        _reset_effects()
        drops = []

func _run_over() -> void:
        if phase == "over":
                return
        phase = "over"
        achievement_max("max_pts", pts)
        finish_run(score)

## THE HEART LAW: one extra heart for each 1000 brick points
func _gain_pts(n: int) -> void:
        pts += n
        pts_lbl.text = str(pts)
        var gained := false
        while pts >= life_next:
                life_next += PTS_PER_LIFE
                lives += 1
                lives_lbl.text = str(lives)
                gained = true
        if gained:
                Jukebox.sfx("bb_heart", -3.0)
                _flash("+1 HEART", Color(1.0, 0.62, 0.72))

## a life is taken ONLY when all balls are out (the owner's note)
func _lose_life(reason := "BALL LOST") -> void:
        lives -= 1
        lives_lbl.text = str(maxi(0, lives))
        Jukebox.sfx("bb_lose", -2.0)
        _flash(reason, Color(1.0, 0.5, 0.45))
        # THE RESET LAW: losing life resets the level powerups
        _reset_effects()
        drops = []
        balls = []
        if lives <= 0:
                _run_over()
                return
        if reason == "TIME UP":
                time_left = level_time      # the fresh clock (the mercy)
                time_lbl.modulate = Color(1, 1, 1, 1)
                _set_time_chip()
        # the same layout, the eaten bricks stay eaten, the clock runs on
        _spawn_serve_ball()

# ==================================================== the drop machinery
## THE DROP LAW: 2% of bricks carry a powerup; the first one appears AT
## the 40%th brick (forced promotion when the mark is crossed); the
## carriers broken before the gate BANK their capsule (never lost).

## the brick's death bookkeeping: the coin law, the 40% gate, the
## carrier's drop, the clear check
func _on_broken(key: Vector2i) -> void:
        broken_this_level += 1
        bricks_broken += 1
        achievement_count("bricks", 1)
        # THE COIN LAW: every 300 REAL bricks, a coin hides in one brick
        if bricks_broken % BRICKS_PER_COIN == 0:
                coin_pending += 1
        if coin_pending > 0:
                _promote_coin()
        # THE DROP LAW: the forced 40% mark rides the ORIGINAL count
        if not gate_crossed and int(ld["total0"]) > 0 \
                        and broken_this_level >= int(ceil(POW_GATE \
                                        * float(ld["total0"]))):
                gate_crossed = true
                var want := 1 + banked_pows
                for i in want:
                        _promote_carrier()
                banked_pows = 0
        var c: Dictionary = ld["cells"][key]
        if bool(c.get("carrier", false)):
                if gate_crossed:
                        _spawn_drop(key)
                        c["carrier"] = false
                else:
                        banked_pows = mini(banked_pows + 1, 3)
        if bool(c.get("coin", false)):
                c["coin"] = false
                coin_pending = maxi(0, coin_pending - 1)
                add_run_coins(1)
                achievement_count("coins", 1)
                Jukebox.sfx("c_coin", -2.0)
                _burst(_cell_rect(key).get_center(),
                                Color(1.0, 0.80, 0.30), 16)

func _promote_carrier() -> void:
        var pool: Array = []
        for key in ld["cells"].keys():
                var c: Dictionary = ld["cells"][key]
                if bool(c["decor"]) or int(c["hp"]) <= 0:
                        continue
                if bool(c.get("carrier", false)) or bool(c.get("coin", false)):
                        continue
                pool.append(key)
        if pool.is_empty():
                return
        var pick: Vector2i = pool[rng.randi_range(0, pool.size() - 1)]
        ld["cells"][pick]["carrier"] = true
        brick_layer.queue_redraw()

func _promote_coin() -> void:
        var pool: Array = []
        for key in ld["cells"].keys():
                var c: Dictionary = ld["cells"][key]
                if bool(c["decor"]) or int(c["hp"]) <= 0:
                        continue
                if bool(c.get("coin", false)):
                        return      # a coin is already waiting
                pool.append(key)
        if pool.is_empty():
                return              # the level ends first; it rolls over
        var pick: Vector2i = pool[rng.randi_range(0, pool.size() - 1)]
        ld["cells"][pick]["coin"] = true
        brick_layer.queue_redraw()

func _spawn_drop(key: Vector2i) -> void:
        # only OWNED kinds join the pool (THE SHOP-MAKES-DROPS LAW)
        var pool: Array = []
        for id in POWS.keys():
                if Box.item_owned(game_id, "powerup", String(id)):
                        pool.append(String(id))
        if pool.is_empty():
                return
        var kind: String = pool[rng.randi_range(0, pool.size() - 1)]
        var r := _cell_rect(key)
        drops.append({"x": r.get_center().x, "y": r.get_center().y,
                "vy": 250.0 * us, "kind": kind, "t": rng.randf() * TAU})
        Jukebox.sfx("bb_pow_spawn", -4.0)

## the catch: the bundle law picks the side, the caps hold the line
func _apply_pow(kind: String) -> void:
        Jukebox.sfx("bb_pow", -3.0)
        match kind:
                "pad":
                        if rng.randf() < 0.6:
                                pad_mult *= PAD_STEP_WIDE
                        else:
                                pad_mult *= PAD_STEP_SMALL
                        pad_mult = clampf(pad_mult,
                                        PAD_MIN_W / PAD_BASE_W,
                                        (arena.size.x - 30.0 * us) \
                                                        / PAD_BASE_W)
                        _flash("PADDLE %s" % ("WIDE" if pad_mult > 1.4 \
                                        else "TIGHT"), _theme()["ink"])
                "spd":
                        if rng.randf() < 0.6:
                                spd_mult = minf(SPEED_MAX,
                                                spd_mult * SPEED_STEP_FAST)
                        else:
                                spd_mult = maxf(SPEED_MIN,
                                                spd_mult * SPEED_STEP_SLOW)
                "size":
                        if rng.randf() < 0.6:
                                size_mult = minf(SIZE_MAX,
                                                size_mult * SIZE_STEP_BIG)
                        else:
                                size_mult = maxf(SIZE_MIN,
                                                size_mult * SIZE_STEP_SMALL)
                "multi":
                        if balls.size() < MAX_BALLS:
                                var ang := -PI * rng.randf_range(0.35, 0.65)
                                var spd := _ball_speed()
                                balls.append({"x": pad_x,
                                        "y": paddle_y - PAD_H * us * 0.5 \
                                                        - _ball_r(),
                                        "dx": cos(ang) * spd,
                                        "dy": sin(ang) * spd,
                                        "r": _ball_r(), "stuck": false,
                                        "trail": []})
                "metal":
                        metal_t = METAL_TIME
                "fire":
                        fire_t = FIRE_TIME
        _sync_effect_chips()

func _sync_effect_chips() -> void:
        if spd_chip == null:
                return
        spd_chip.visible = absf(spd_mult - 1.0) > 0.005
        size_chip.visible = absf(size_mult - 1.0) > 0.005
        pad_chip.visible = absf(pad_mult - 1.0) > 0.005
        metal_chip.visible = metal_t > 0.0
        fire_chip.visible = fire_t > 0.0
        spd_lbl.text = (">>" if spd_mult > 1.0 else "<<") \
                        + " x%.2f" % spd_mult
        size_lbl.text = ("^^" if size_mult > 1.0 else "vv") \
                        + " x%.2f" % size_mult
        pad_lbl.text = ("<<" if pad_mult < 1.0 else ">>") \
                        + " x%.2f" % pad_mult
        metal_lbl.text = "%.0f" % ceilf(metal_t)
        fire_lbl.text = "%.0f" % ceilf(fire_t)

# ============================================================== the tick
func _goga_tick(delta: float) -> void:
        _time += delta
        if banner_t > 0.0:
                banner_t -= delta * 1.4
                banner_lbl.modulate.a = clampf(banner_t, 0.0, 1.0)
        _tick_fx(delta)
        match phase:
                "intro":
                        intro_t += delta
                        brick_layer.queue_redraw()
                        if intro_t >= float(ld["rows"]) * SERVE_LAG \
                                        + SERVE_FADE + 0.20:
                                _spawn_serve_ball()
                "serve":
                        _ride_paddle()
                        _move_pad(delta)
                        char_layer.queue_redraw()
                "play":
                        _move_pad(delta)
                        _tick_timers(delta)
                        if phase != "play":
                                return      # the timer door may end the run
                        _tick_brick_fx(delta)
                        _tick_balls(delta)
                        if phase != "play":
                                return      # the physics door may end the run
                        _tick_drops(delta)
                        char_layer.queue_redraw()
                        brick_layer.queue_redraw()
                "clear":
                        clear_t -= delta
                        _tick_brick_fx(delta)
                        char_layer.queue_redraw()
                        brick_layer.queue_redraw()
                        if clear_t <= 0.0:
                                _new_level(level_i + 1)
                "over":
                        pass

## the paddle: THE GLIDE (the rally law, word for word) - the finger
## writes a TARGET; the tick glides toward it at a speed proportional to
## the gap (a far flick closes fast, a small drag tracks tight) -
## responsive, never a jump. Small gaps track near 1:1.
func _move_pad(delta: float) -> void:
        if _auto:
                _auto_think(delta)
        var gap := absf(pad_target - pad_x)
        if gap > 0.5:
                var step: float = clampf(gap * 14.0 * delta, 0.0,
                                minf(gap, 4200.0 * us * delta))
                pad_x = move_toward(pad_x, pad_target, step)
        var hw := _pad_w() * 0.5
        pad_x = clampf(pad_x, arena.position.x + hw, arena.end.x - hw)
        if pad_squash > 0.0:
                pad_squash = maxf(0.0, pad_squash - delta * 5.0)

## the qa auto-paddle: PREDICT the falling ball's landing x (folded off
## the walls) and steer the bounce toward the nearest surviving brick -
## a human-shaped pace, a thinking player's aim
func _auto_think(delta: float) -> void:
        _auto_t += delta
        var best: Dictionary = {}
        var by := -1.0
        for b in balls:
                if bool(b["stuck"]):
                        continue
                if float(b["dy"]) > 0.0 and float(b["y"]) > by:
                        by = float(b["y"])
                        best = b
        if best.is_empty():
                return
        # the landing prediction: fold the straight path off the walls
        var bx := float(best["x"])
        var byy := float(best["y"])
        var bdx := float(best["dx"])
        var bdy := maxf(1.0, float(best["dy"]))
        var tt := (paddle_y - byy) / bdy
        var px := bx + bdx * tt
        var lo := arena.position.x + float(best["r"])
        var hi := arena.end.x - float(best["r"])
        var span := hi - lo
        if span > 0.0:
                var k := fposmod(px - lo, span * 2.0)
                px = lo + (k if k <= span else span * 2.0 - k)
        # the steering: the arriving COLUMN decides - nearest x wins,
        # and the TOP of the field wins the tie (drill the channel up:
        # an open ceiling rakes the whole row)
        var aim := px
        var bd := 1 << 30
        for key in ld["cells"].keys():
                var c: Dictionary = ld["cells"][key]
                if bool(c["decor"]) or int(c["hp"]) <= 0 \
                                or c.has("dying"):
                        continue
                var cr := _cell_rect(key)
                var dd := int(absf(cr.get_center().x - px) \
                                + cr.get_center().y * 0.25)
                if dd < bd:
                        bd = int(dd)
                        aim = cr.get_center().x
        var hw := _pad_w() * 0.5
        var off := clampf((aim - px) / maxf(1.0, hw), -1.0, 1.0)
        px -= off * hw * 0.55
        pad_target = clampf(px, arena.position.x, arena.end.x)
        var max_step := 2300.0 * us * delta
        pad_target = clampf(pad_target, pad_x - max_step,
                        pad_x + max_step)

func _ride_paddle() -> void:
        for b in balls:
                if bool(b["stuck"]):
                        b["x"] = pad_x
                        b["y"] = paddle_y - PAD_H * us * 0.5 - float(b["r"])

## THE FAIR TIMER: it breathes only in play (the serve is free)
func _tick_timers(delta: float) -> void:
        if metal_t > 0.0:
                metal_t = maxf(0.0, metal_t - delta)
        if fire_t > 0.0:
                fire_t = maxf(0.0, fire_t - delta)
        if metal_t > 0.0 or fire_t > 0.0:
                _sync_effect_chips()
        var before := int(ceilf(time_left))
        time_left -= delta
        var after := int(ceilf(time_left))
        if after != before and after <= 10 and after > 0:
                time_lbl.modulate = Color(1.0, 0.35, 0.3)
                Jukebox.sfx("bb_tick", -8.0)
        elif after != before and after <= 30:
                time_lbl.modulate = Color(1.0, 0.72, 0.3)
        _set_time_chip()
        if time_left <= 0.0:
                _lose_life("TIME UP")

func _set_time_chip() -> void:
        var s := maxi(0, int(ceilf(time_left)))
        time_lbl.text = "%d:%02d" % [s / 60, s % 60]

func _on_drag(from: Vector2, to: Vector2) -> void:
        if over or paused:
                return
        pad_target = to.x

# ============================================================= PHYSICS
## The substep sweep (no tunneling: even at x5 speed the ball advances
## at most half a radius per step - the qa rig proves it at the cap).

func _cell_rect(key: Vector2i) -> Rect2:
        return Rect2(arena.position.x + float(key.x) * bw,
                        arena.position.y + float(key.y) * bh, bw, bh)

func _cell_at(x: float, y: float) -> Vector2i:
        var c := int(floor((x - arena.position.x) / bw))
        var r := int(floor((y - arena.position.y) / bh))
        return Vector2i(c, r)

func _in_cells(key: Vector2i) -> bool:
        return ld.has("cells") and ld["cells"].has(key)

func _tick_balls(delta: float) -> void:
        var spd := _ball_speed()
        var dead: Array = []
        for b in balls:
                if bool(b["stuck"]):
                        continue
                var dir := Vector2(float(b["dx"]), float(b["dy"]))
                if dir.length() <= 0.01:
                        dead.append(b)
                        continue
                dir = dir.normalized() * spd
                b["dx"] = dir.x
                b["dy"] = dir.y
                var dist := spd * delta
                var steps := clampi(int(ceil(dist / (float(b["r"]) * 0.5))),
                                1, 10)
                var ds := dist / float(steps)
                # THE UNIT STEP: dx/dy carry the VELOCITY (px/s) - the
                # substep walks the UNIT direction by ds pixels (the old
                # velocity x distance read px^2/s - the ball teleported
                # 8000px a frame and every launch died in one tick)
                var ux := float(b["dx"]) / maxf(1.0, spd)
                var uy := float(b["dy"]) / maxf(1.0, spd)
                for step in steps:
                        b["x"] += ux * ds
                        b["y"] += uy * ds
                        if _collide_walls(b) or _collide_paddle(b):
                                pass
                        _collide_bricks(b)
                        if float(b["y"]) - float(b["r"]) > lose_y:
                                dead.append(b)
                                _burst(Vector2(float(b["x"]), lose_y),
                                                Color(1.0, 0.4, 0.35), 12)
                                break
                # the trail (the last 10 positions, the fire rides it)
                var tr: Array = b["trail"]
                tr.append(Vector2(float(b["x"]), float(b["y"])))
                if tr.size() > 10:
                        tr.pop_front()
        for b in dead:
                balls.erase(b)
        if balls.is_empty() and phase == "play":
                # a life is taken ONLY when all balls are out
                _lose_life("BALL LOST")

## the frame: left / right / top bounce; the bottom is the open sky
func _collide_walls(b: Dictionary) -> bool:
        var r := float(b["r"])
        var hit := false
        if float(b["x"]) - r < arena.position.x:
                b["x"] = arena.position.x + r
                b["dx"] = absf(float(b["dx"]))
                hit = true
        elif float(b["x"]) + r > arena.end.x:
                b["x"] = arena.end.x - r
                b["dx"] = -absf(float(b["dx"]))
                hit = true
        if float(b["y"]) - r < arena.position.y:
                b["y"] = arena.position.y + r
                b["dy"] = absf(float(b["dy"]))
                hit = true
        if hit:
                Jukebox.sfx("bb_wall", -10.0)
        return hit

## THE PING-PONG BOUNCE: the angle rides the hit's offset (the classic),
## the paddle squashes, the sound pops.
func _collide_paddle(b: Dictionary) -> bool:
        if float(b["dy"]) <= 0.0:
                return false
        var r := float(b["r"])
        var hw := _pad_w() * 0.5
        var top := paddle_y - PAD_H * us * 0.5
        var bot := paddle_y + PAD_H * us * 0.5
        if float(b["y"]) + r < top or float(b["y"]) - r > bot:
                return false
        if float(b["x"]) < pad_x - hw - r or float(b["x"]) > pad_x + hw + r:
                return false
        var rel := clampf((float(b["x"]) - pad_x) / hw, -1.0, 1.0)
        var ang := -PI * 0.5 + rel * (PI / 3.0)     # up to 60 degrees off
        var spd := _ball_speed()
        b["dx"] = cos(ang) * spd
        b["dy"] = sin(ang) * spd
        b["y"] = top - r - 0.5
        pad_squash = 1.0
        Jukebox.sfx("bb_bathit", -6.0)
        _burst(Vector2(float(b["x"]), top), Color(1, 1, 1, 0.8), 5)
        return true

## the bricks: circle-rect resolve against every cell the ball touches.
## FIRE passes through (no bounce, burns all); METAL hits for 2.
func _collide_bricks(b: Dictionary) -> void:
        var r := float(b["r"])
        var fire := fire_t > 0.0
        var metal := metal_t > 0.0 and not fire
        var c0 := _cell_at(float(b["x"]) - r, float(b["y"]) - r)
        var c1 := _cell_at(float(b["x"]) + r, float(b["y"]) + r)
        var bounced := false
        for cc in range(maxi(0, c0.x), mini(int(ld["cols"]) - 1, c1.x) + 1):
                for rr in range(maxi(0, c0.y),
                                mini(int(ld["rows"]) - 1, c1.y) + 1):
                        var key := Vector2i(cc, rr)
                        if not _in_cells(key):
                                continue
                        var cell: Dictionary = ld["cells"][key]
                        if cell.has("dying"):
                                continue
                        var rect := _cell_rect(key)
                        var close := Vector2(
                                        clampf(float(b["x"]), rect.position.x,
                                                        rect.end.x),
                                        clampf(float(b["y"]), rect.position.y,
                                                        rect.end.y))
                        var d := Vector2(float(b["x"]), float(b["y"])) \
                                        .distance_to(close)
                        if d > r:
                                continue
                        if bool(cell["decor"]):
                                # THE DECOR LAW: the steel only bounces
                                if not fire and not bounced:
                                        _bounce_off(b, rect, close)
                                        bounced = true
                                        Jukebox.sfx("bb_wall", -6.0)
                                        _burst(close, Color(0.8, 0.85, 0.9),
                                                        4)
                                continue
                        # the damage: fire burns through (no bounce),
                        # metal deals the double hit
                        var dmg := 2 if metal else 1
                        _damage_cell(key, dmg, fire)
                        if not fire and not bounced:
                                _bounce_off(b, rect, close)
                                bounced = true

## the honest bounce: reflect on the SHALLOWER penetration axis
func _bounce_off(b: Dictionary, rect: Rect2, close: Vector2) -> void:
        var r := float(b["r"])
        var bx := float(b["x"])
        var by := float(b["y"])
        if close.x == bx and close.y == by:
                # the center is inside (a fat ball swallowed the brick):
                # exit by the shortest face
                var left := bx - rect.position.x
                var right := rect.end.x - bx
                var top := by - rect.position.y
                var bot := rect.end.y - by
                var m := minf(minf(left, right), minf(top, bot))
                if m == left:
                        b["x"] = rect.position.x - r
                        b["dx"] = -absf(float(b["dx"]))
                elif m == right:
                        b["x"] = rect.end.x + r
                        b["dx"] = absf(float(b["dx"]))
                elif m == top:
                        b["y"] = rect.position.y - r
                        b["dy"] = -absf(float(b["dy"]))
                else:
                        b["y"] = rect.end.y + r
                        b["dy"] = absf(float(b["dy"]))
                return
        var ox := r - absf(bx - close.x)
        var oy := r - absf(by - close.y)
        if ox <= oy:
                if bx < close.x:
                        b["x"] = close.x - r - 0.5
                        b["dx"] = -absf(float(b["dx"]))
                else:
                        b["x"] = close.x + r + 0.5
                        b["dx"] = absf(float(b["dx"]))
        else:
                if by < close.y:
                        b["y"] = close.y - r - 0.5
                        b["dy"] = -absf(float(b["dy"]))
                else:
                        b["y"] = close.y + r + 0.5
                        b["dy"] = absf(float(b["dy"]))

## THE DAMAGE + THE POINT LAW: damage dealt = points paid, live. The
## ice layer takes the hit first (THE FROZEN LAW), the body under it
## shows its own cracks as the damage grows.
func _damage_cell(key: Vector2i, dmg: int, fire: bool) -> void:
        var cell: Dictionary = ld["cells"][key]
        if bool(cell["decor"]) or cell.has("dying"):
                return
        var dealt := 0
        if bool(cell.get("ice", false)):
                # the ice absorbs up to the whole hit
                var ice_take := mini(dmg, 1)
                cell["ice"] = false
                dealt += ice_take
                dmg -= ice_take
                Jukebox.sfx("bb_ice", -7.0)
                _burst(_cell_rect(key).get_center(), Color(0.75, 0.92, 1.0),
                                8)
        if dmg > 0:
                var hp := int(cell["hp"])
                if fire:
                        dmg = hp          # THE BURN: the fire takes it all
                var take := mini(dmg, hp)
                cell["hp"] = hp - take
                dealt += take
                if fire:
                        Jukebox.sfx("bb_fire", -9.0)
                elif metal_t > 0.0:
                        Jukebox.sfx("bb_metal", -6.0)
                else:
                        Jukebox.sfx("bb_brickhit", -4.0,
                                        1.28 - 0.05 * float(int(cell["hp"])))
                _burst(_cell_rect(key).get_center(),
                                _brick_color(maxi(1, int(cell["hp"]))), 6)
        if dealt > 0:
                _gain_pts(dealt)
        if int(cell["hp"]) <= 0:
                # THE BREAK: fade + particles + the sound
                _break_cell(key)
        else:
                cell["flash"] = 1.0
                cell["shake"] = 1.0

func _break_cell(key: Vector2i) -> void:
        var cell: Dictionary = ld["cells"][key]
        cell["dying"] = 0.0
        ld["breakable"] = int(ld["breakable"]) - 1
        Jukebox.sfx("bb_break", -5.0)
        _burst(_cell_rect(key).get_center(),
                        _brick_color(maxi(1, int(cell["hp"]))), 12)
        _on_broken(key)
        if int(ld["breakable"]) <= 0 and phase == "play":
                _level_clear()

# ================================================================ DROPS
func _tick_drops(delta: float) -> void:
        var dead: Array = []
        for d in drops:
            d["t"] = float(d["t"]) + delta
            d["y"] = float(d["y"]) + float(d["vy"]) * delta
            d["x"] = float(d["x"]) + sin(float(d["t"]) * 3.2) * 40.0 * us \
                            * delta
            var hw := _pad_w() * 0.5
            var top := paddle_y - PAD_H * us * 0.5
            if float(d["y"]) + 20.0 * us >= top \
                            and float(d["y"]) - 20.0 * us <= paddle_y + PAD_H \
                            and float(d["x"]) >= pad_x - hw - 18.0 * us \
                            and float(d["x"]) <= pad_x + hw + 18.0 * us:
                    _apply_pow(String(d["kind"]))
                    _burst(Vector2(float(d["x"]), top), Color(1, 1, 1), 10)
                    dead.append(d)
                    continue
            if float(d["y"]) - 20.0 * us > lose_y:
                    dead.append(d)
        for d in dead:
                drops.erase(d)

# ============================================================ THE INPUT
func _tap_anywhere(_at: Vector2) -> void:
        if over:
                return
        if phase == "boot":
                # THE GATE OPENS THE INTRO (the line-by-line breath, fresh)
                _gate_down()
                phase = "intro"
                intro_t = 0.0
                return
        if phase == "serve" and not paused:
                # THE LAUNCH: the tap sends the served ball up
                for b in balls:
                        if bool(b["stuck"]):
                                _launch_ball(b)
                phase = "play"
                Jukebox.sfx("bb_serve", -2.0)

## THE HELD FINGER (the rally law, word for word): the touch that took
## the paddle owns it; its drags write the TARGET; its release frees it.
func _goga_input(event: InputEvent) -> void:
        if over:
                return
        if event is InputEventScreenTouch:
                var t := event as InputEventScreenTouch
                if t.pressed and _held == -1:
                        _held = t.index
                        _follow_finger(t.position)
                elif not t.pressed and t.index == _held:
                        _held = -1
                # the gate also answers raw touches (the tap-anywhere law)
                if t.pressed and phase == "boot":
                        _tap_anywhere(t.position)
        elif event is InputEventScreenDrag:
                var d := event as InputEventScreenDrag
                if d.index == _held:
                        _follow_finger(d.position)

## the finger's wish, clamped to the arena (the paddle's own axis)
func _follow_finger(at: Vector2) -> void:
        var hw := _pad_w() * 0.5
        pad_target = clampf(at.x, arena.position.x + hw,
                        arena.end.x - hw)

# ==================================================== THE GATE (silent)
func _build_gate() -> void:
        if gate_ui != null and is_instance_valid(gate_ui):
                gate_ui.queue_free()
        gate_ui = Control.new()
        gate_ui.position = Vector2.ZERO
        gate_ui.size = _vp()
        gate_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var dim := ColorRect.new()
        dim.color = Color(0, 0, 0, 0.45)
        dim.position = Vector2.ZERO
        dim.size = _vp()
        dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
        gate_ui.add_child(dim)
        var vb := VBoxContainer.new()
        vb.set_anchors_preset(Control.PRESET_CENTER)
        vb.add_theme_constant_override("separation", 18)
        gate_ui.add_child(vb)
        # THE SILENT GATE: its ONE sentence
        var l := Arc.label("TAP ANYWHERE TO START", 46, Color(1, 1, 1, 0.95))
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(l)
        vb.position = _vp() * 0.5 - Vector2(320, 40)
        vb.custom_minimum_size = Vector2(640, 0)
        add_child(gate_ui)
        gate_ui.visible = true

func _gate_down() -> void:
        if gate_ui != null and is_instance_valid(gate_ui):
                gate_ui.queue_free()
        gate_ui = null

# ================================================================ THE FX
## the brick fx tick: the dying fade (0.30s), the hit flash, the shake -
## the DRAW only reads these (the mutator law)
func _tick_brick_fx(delta: float) -> void:
        if ld.is_empty() or not ld.has("cells"):
                return
        var dead: Array = []
        for key in ld["cells"].keys():
                var cell: Dictionary = ld["cells"][key]
                if cell.has("dying"):
                        cell["dying"] = float(cell["dying"]) \
                                        + delta / 0.30
                        if float(cell["dying"]) >= 1.0:
                                dead.append(key)
                        continue
                if float(cell.get("flash", 0.0)) > 0.0:
                        cell["flash"] = maxf(0.0,
                                        float(cell["flash"]) - delta * 4.0)
                if float(cell.get("shake", 0.0)) > 0.0:
                        cell["shake"] = maxf(0.0,
                                        float(cell["shake"]) - delta * 5.0)
        for key in dead:
                ld["cells"].erase(key)
        if not dead.is_empty():
                brick_layer.queue_redraw()

func _burst(at: Vector2, col: Color, n := 10) -> void:
        for i in n:
                var a := randf() * TAU
                var spd := randf_range(50.0, 200.0) * us
                _fx.append({"x": at.x, "y": at.y, "vx": cos(a) * spd,
                        "vy": sin(a) * spd, "life": randf_range(0.3, 0.55),
                        "max": 0.55, "s": randf_range(3.0, 7.0) * us,
                        "col": col})

func _tick_fx(delta: float) -> void:
        var dead: Array = []
        for p in _fx:
                p["life"] -= delta
                p["x"] += p["vx"] * delta
                p["y"] += p["vy"] * delta
                p["vy"] += 260.0 * us * delta   # the crumbs fall
                p["vx"] *= 0.96
                if p["life"] <= 0.0:
                        dead.append(p)
        for p in dead:
                _fx.erase(p)
        if not _fx.is_empty():
                fx_layer.queue_redraw()

# ================================================================ DRAW
## THE LIVING LAYER LAW: every animated layer repaints on the tick.

func _brick_color(hp: int) -> Color:
        var pal: Array = _theme()["bricks"]
        var idx := clampi(hp - 1, 0, pal.size() - 1)
        var col: Color = pal[idx]
        if hp > pal.size():
                # the fat tiers darken past the palette's top
                col = pal[pal.size() - 1].darkened(
                                0.08 * float(hp - pal.size()))
        return col

func _draw_frame() -> void:
        var t := _theme()
        var style := String(t["style"])
        var fcol: Color = t["frame"]
        var top_y := arena.position.y
        var bot_y := paddle_y + PAD_H * us
        # left / right / top walls (the bottom stays open - the sky)
        var rects := [
                Rect2(arena.position.x - WALL_T * us, top_y - WALL_T * us,
                                WALL_T * us, bot_y - top_y + WALL_T * us),
                Rect2(arena.end.x, top_y - WALL_T * us, WALL_T * us,
                                bot_y - top_y + WALL_T * us),
                Rect2(arena.position.x - WALL_T * us, top_y - WALL_T * us,
                                arena.size.x + WALL_T * 2.0 * us, WALL_T * us),
        ]
        for rect in rects:
                match style:
                        "fat", "candy":
                                frame_layer.draw_rect(rect,
                                                Color(fcol, 0.92))
                                var gloss: Rect2 = rect.grow_individual(
                                                2, 2, 2, -rect.size.y * 0.55)
                                frame_layer.draw_rect(gloss,
                                                Color(1, 1, 1, 0.22))
                        "glow":
                                frame_layer.draw_rect(rect, Color(fcol, 0.16))
                                frame_layer.draw_rect(rect.grow(-2.0 * us),
                                                Color(fcol, 0.5))
                                frame_layer.draw_rect(rect.grow(-4.0 * us),
                                                fcol)
                        "flat":
                                frame_layer.draw_rect(rect, fcol)
                                frame_layer.draw_rect(rect.grow(-3.0 * us),
                                                Color(fcol.darkened(0.4),
                                                                1.0))
                        "bevel":
                                frame_layer.draw_rect(rect,
                                                fcol.darkened(0.35))
                                frame_layer.draw_rect(rect.grow(-2.0 * us),
                                                fcol)
                                frame_layer.draw_rect(Rect2(
                                                rect.position + Vector2(3, 3) * us,
                                                Vector2(rect.size.x - 6.0 * us,
                                                                4.0 * us)),
                                                Color(1, 1, 1, 0.18))
        # the lose line: a faint dashed breath under the paddle
        var ly := lose_y - 6.0 * us
        var dash := 26.0 * us
        var x := arena.position.x
        var lc := Color(fcol, 0.22 + 0.08 * sin(_time * 3.0))
        while x < arena.end.x:
                frame_layer.draw_line(Vector2(x, ly),
                                Vector2(minf(x + dash * 0.5, arena.end.x), ly),
                                lc, 3.0 * us)
                x += dash

## the intro's per-row fade (line by line, top to bottom - THE FX LAW)
func _row_alpha(r: int) -> float:
        if phase == "intro":
                return clampf((intro_t - float(r) * SERVE_LAG) / SERVE_FADE,
                                0.0, 1.0)
        return 1.0

func _draw_bricks() -> void:
        if ld.is_empty() or not ld.has("cells"):
                return
        var t := _theme()
        var style := String(t["style"])
        var pulse := 0.5 + 0.5 * sin(_time * 5.0)
        for key in ld["cells"].keys():
                var cell: Dictionary = ld["cells"][key]
                var hp := int(cell["hp"])
                var decor: bool = bool(cell["decor"])
                if hp <= 0 and not decor and not cell.has("dying"):
                        continue
                var rect := _cell_rect(key)
                var a := _row_alpha(int(key.y))
                if a <= 0.0:
                        continue
                # the dying fade, the shake and the flash are TICKED in
                # _tick_brick_fx - the draw only READS them (the mutator
                # law: the mutator repaints what it mutates)
                var dying_t := -1.0
                if cell.has("dying"):
                        dying_t = float(cell["dying"])
                var shake := float(cell.get("shake", 0.0))
                var flash := float(cell.get("flash", 0.0))
                var off := Vector2(sin(_time * 70.0 + float(key.x)) * 3.0,
                                cos(_time * 63.0 + float(key.y)) * 2.0) \
                                * shake * us
                var r2 := rect.grow(-2.0 * us)
                var body: Color
                if decor:
                        body = t["steel"]
                else:
                        body = _brick_color(maxi(1, hp))
                if dying_t >= 0.0:
                        a *= 1.0 - dying_t
                        r2 = r2.grow(4.0 * us * dying_t)
                var draw_col := Color(body, a)
                match style:
                        "fat":
                                _brick_fat(r2, off, draw_col, flash, decor,
                                                a)
                        "glow":
                                _brick_glow(r2, off, draw_col, flash, decor,
                                                a)
                        "flat":
                                _brick_flat(r2, off, draw_col, flash, decor,
                                                a)
                        "bevel":
                                _brick_bevel(r2, off, draw_col, flash, decor,
                                                a)
                        "candy":
                                _brick_candy(r2, off, draw_col, flash, decor,
                                                a, key)
                # the cracks grow with the damage (the 10-hit story)
                if not decor and hp > 0 and hp < _brick_max_hp(key):
                        _draw_cracks(r2, off, key,
                                        _brick_max_hp(key) - hp, a)
                # THE FROZEN LAW: the external ice layer rides the brick
                if not decor and bool(cell.get("ice", false)):
                        _draw_ice(r2, off, a, pulse)
                # THE COIN LAW's shine + the carrier's hum
                if not decor and hp > 0:
                        if bool(cell.get("coin", false)):
                                var cc := r2.get_center() + off
                                var rr := minf(r2.size.x, r2.size.y) * 0.30 \
                                                * (1.0 + 0.10 * pulse)
                                brick_layer.draw_circle(cc, rr * 1.8,
                                                Color(1.0, 0.80, 0.30,
                                                                0.20 * a))
                                brick_layer.draw_circle(cc, rr,
                                                Color(1.0, 0.82, 0.30, a))
                                brick_layer.draw_circle(cc, rr * 0.55,
                                                Color(1.0, 0.95, 0.6,
                                                                0.9 * a))
                        elif bool(cell.get("carrier", false)):
                                var cc2 := r2.get_center() + off
                                brick_layer.draw_arc(cc2,
                                                minf(r2.size.x, r2.size.y) \
                                                                * 0.42,
                                                0, TAU, 20,
                                                Color(1, 1, 1, 0.35 + 0.25 \
                                                                * pulse * a),
                                                2.5 * us)

func _brick_max_hp(key: Vector2i) -> int:
        # the tier the brick shipped at (the crack count reads it back)
        var cell: Dictionary = ld["cells"][key]
        return maxi(1, int(cell.get("hp0", cell["hp"])))

func _brick_fat(r2: Rect2, off: Vector2, col: Color, flash: float,
                decor: bool, a: float) -> void:
        var rr := minf(r2.size.x, r2.size.y) * 0.32
        # the soft drop shadow (the fat joyful depth)
        brick_layer.draw_rect(Rect2(r2.position + off + Vector2(0, 3.5) * us,
                        r2.size), Color(0.1, 0.15, 0.3, 0.25 * a))
        _round_rect(brick_layer, r2.position + off, r2.size, rr,
                        Color(col, 1.0))
        # the gloss streak
        var g := Rect2(r2.position + off + Vector2(rr * 0.5, rr * 0.35),
                        Vector2(r2.size.x - rr, r2.size.y * 0.28))
        _round_rect(brick_layer, g.position, g.size, rr * 0.5,
                        Color(1, 1, 1, 0.35 * a))
        if flash > 0.0:
                _round_rect(brick_layer, r2.position + off, r2.size, rr,
                                Color(1, 1, 1, 0.55 * flash * a))

func _brick_glow(r2: Rect2, off: Vector2, col: Color, flash: float,
                decor: bool, a: float) -> void:
        var rr := minf(r2.size.x, r2.size.y) * 0.30
        var p := r2.position + off
        brick_layer.draw_rect(Rect2(p, r2.size), Color(col, 0.10 * a))
        _round_rect_outline(brick_layer, p, r2.size, rr,
                        Color(col, 0.35 * a), 6.0 * us)
        _round_rect_outline(brick_layer, p, r2.size, rr,
                        Color(col, 0.8 * a), 2.6 * us)
        if flash > 0.0:
                _round_rect(brick_layer, p, r2.size, rr,
                                Color(1, 1, 1, 0.4 * flash * a))

func _brick_flat(r2: Rect2, off: Vector2, col: Color, flash: float,
                decor: bool, a: float) -> void:
        var p := r2.position + off
        brick_layer.draw_rect(Rect2(p, r2.size), Color(col, 1.0))
        # the twin-stroke inset (the 1980 face)
        brick_layer.draw_rect(Rect2(p + Vector2(3, 3) * us,
                        r2.size - Vector2(6, 6) * us),
                        Color(col.darkened(0.35), 1.0), false, 2.0 * us)
        brick_layer.draw_rect(Rect2(p, r2.size),
                        Color(1, 1, 1, 0.10 * a))
        if flash > 0.0:
                brick_layer.draw_rect(Rect2(p, r2.size),
                                Color(1, 1, 1, 0.45 * flash * a))

func _brick_bevel(r2: Rect2, off: Vector2, col: Color, flash: float,
                decor: bool, a: float) -> void:
        var p := r2.position + off
        brick_layer.draw_rect(Rect2(p, r2.size), Color(col.darkened(0.4), a))
        brick_layer.draw_rect(Rect2(p + Vector2(2, 2) * us,
                        r2.size - Vector2(4, 4) * us), Color(col, a))
        # the torch light: a top bevel + a left rim
        brick_layer.draw_rect(Rect2(p + Vector2(2, 2) * us,
                        Vector2(r2.size.x - 4.0 * us, 4.0 * us)),
                        Color(1, 1, 1, 0.20 * a))
        brick_layer.draw_rect(Rect2(p + Vector2(2, 2) * us,
                        Vector2(3.0 * us, r2.size.y - 4.0 * us)),
                        Color(1, 1, 1, 0.10 * a))
        if flash > 0.0:
                brick_layer.draw_rect(Rect2(p, r2.size),
                                Color(1, 1, 1, 0.4 * flash * a))

func _brick_candy(r2: Rect2, off: Vector2, col: Color, flash: float,
                decor: bool, a: float, key: Vector2i) -> void:
        var rr := minf(r2.size.x, r2.size.y) * 0.45
        var p := r2.position + off
        _round_rect(brick_layer, p, r2.size, rr, Color(col, 1.0))
        _round_rect(brick_layer, p + Vector2(rr * 0.4, rr * 0.4),
                        Vector2(r2.size.x - rr * 0.8, r2.size.y * 0.30),
                        rr * 0.4, Color(1, 1, 1, 0.45 * a))
        # the sprinkles: seeded per cell (the sugar)
        var sd := int(key.x * 31 + key.y * 17)
        for i in 4:
                var fx := float((sd * (i + 3)) % 100) / 100.0
                var fy := float((sd * (i + 7)) % 100) / 100.0
                var sp := r2.position + off + Vector2(
                                r2.size.x * (0.15 + 0.7 * fx),
                                r2.size.y * (0.2 + 0.6 * fy))
                brick_layer.draw_circle(sp, 2.2 * us,
                                Color(1, 1, 1, 0.65 * a))
        if flash > 0.0:
                _round_rect(brick_layer, p, r2.size, rr,
                                Color(1, 1, 1, 0.45 * flash * a))

## the cracks: seeded jagged polylines from the edges inward, one per
## hit taken (the 10-hit brick tells its story)
func _draw_cracks(r2: Rect2, off: Vector2, key: Vector2i, cracks: int,
                a: float) -> void:
        var sd := int(key.x * 73 + key.y * 131)
        var c := Color(0.08, 0.08, 0.12, 0.55 * a)
        var n := mini(cracks, 5)
        for i in n:
                var fx := float((sd * (i + 5)) % 100) / 100.0
                var fy := float((sd * (i + 11)) % 100) / 100.0
                var start := Vector2(r2.position.x + r2.size.x * fx,
                                r2.position.y)
                if i % 2 == 0:
                        start = Vector2(r2.position.x,
                                        r2.position.y + r2.size.y * fy)
                var p := start + off
                var dir := (r2.get_center() + off - p).normalized()
                var steps := 3
                var prev := p
                for s in steps:
                        var jitter := Vector2(
                                        float((sd * (i * 3 + s + 2)) % 100) \
                                                        / 100.0 - 0.5,
                                        float((sd * (s * 7 + i + 1)) % 100) \
                                                        / 100.0 - 0.5) \
                                        * r2.size.y * 0.5
                        var np := prev + dir * (r2.size.y * 0.30) + jitter \
                                        * 0.4
                        np.x = clampf(np.x, r2.position.x + off.x + 2.0,
                                        r2.end.x + off.x - 2.0)
                        np.y = clampf(np.y, r2.position.y + off.y + 2.0,
                                        r2.end.y + off.y - 2.0)
                        brick_layer.draw_line(prev, np, c, 2.0 * us)
                        prev = np

## THE FROZEN LAW: the external ice layer - a crystalline plate with a
## sheen; one hit shatters it (the shards fly in _damage_cell)
func _draw_ice(r2: Rect2, off: Vector2, a: float, pulse: float) -> void:
        var p := r2.position + off
        var ic: Color = _theme()["ice"]
        _round_rect(brick_layer, p, r2.size,
                        minf(r2.size.x, r2.size.y) * 0.3,
                        Color(ic, ic.a * a))
        # the facets
        var c := r2.get_center() + off
        var w := r2.size.x * 0.5
        var h := r2.size.y * 0.5
        brick_layer.draw_colored_polygon(PackedVector2Array([
                        c + Vector2(-w * 0.7, -h * 0.5),
                        c + Vector2(-w * 0.1, -h * 0.7),
                        c + Vector2(-w * 0.3, h * 0.5)]),
                        Color(1, 1, 1, 0.30 * a))
        brick_layer.draw_colored_polygon(PackedVector2Array([
                        c + Vector2(w * 0.6, h * 0.6),
                        c + Vector2(w * 0.15, -h * 0.6),
                        c + Vector2(w * 0.75, -h * 0.1)]),
                        Color(1, 1, 1, 0.22 * a))
        _round_rect_outline(brick_layer, p, r2.size,
                        minf(r2.size.x, r2.size.y) * 0.3,
                        Color(1, 1, 1, (0.5 + 0.2 * pulse) * a), 1.8 * us)

func _round_rect(cv: CanvasItem, p: Vector2, sz: Vector2, rr: float,
                col: Color) -> void:
        cv.draw_rect(Rect2(p + Vector2(rr, 0), Vector2(sz.x - rr * 2.0,
                        sz.y)), col)
        cv.draw_rect(Rect2(p + Vector2(0, rr), Vector2(sz.x,
                        sz.y - rr * 2.0)), col)
        cv.draw_circle(p + Vector2(rr, rr), rr, col)
        cv.draw_circle(p + Vector2(sz.x - rr, rr), rr, col)
        cv.draw_circle(p + Vector2(rr, sz.y - rr), rr, col)
        cv.draw_circle(p + Vector2(sz.x - rr, sz.y - rr), rr, col)

func _round_rect_outline(cv: CanvasItem, p: Vector2, sz: Vector2,
                rr: float, col: Color, w: float) -> void:
        var steps := 10
        var pts := PackedVector2Array()
        for i in steps + 1:
                var a := -PI * 0.5 + PI * 0.5 * float(i) / float(steps)
                pts.append(p + Vector2(sz.x - rr, rr) + Vector2(cos(a),
                                sin(a)) * rr)
        for i in steps + 1:
                var a := PI * 0.5 * float(i) / float(steps)
                pts.append(p + Vector2(sz.x - rr, sz.y - rr) + Vector2(cos(a),
                                sin(a)) * rr)
        for i in steps + 1:
                var a := PI * 0.5 + PI * 0.5 * float(i) / float(steps)
                pts.append(p + Vector2(rr, sz.y - rr) + Vector2(cos(a),
                                sin(a)) * rr)
        for i in steps + 1:
                var a := PI + PI * 0.5 * float(i) / float(steps)
                pts.append(p + Vector2(rr, rr) + Vector2(cos(a), sin(a)) * rr)
        for i in pts.size():
                var np := pts[(i + 1) % pts.size()]
                cv.draw_line(pts[i], np, col, w)

func _draw_chars() -> void:
        # the falling powerup capsules first (under the paddle)
        for d in drops:
                _draw_capsule(Vector2(float(d["x"]), float(d["y"])),
                                String(d["kind"]))
        # THE PADDLE (the skin, the squash, the caps)
        var sk := _skin()
        var hw := _pad_w() * 0.5
        var sq := 1.0 + 0.22 * pad_squash
        var ph := PAD_H * us / sq
        var p0 := Vector2(pad_x - hw, paddle_y - ph * 0.5)
        var psz := Vector2(hw * 2.0, ph)
        var rr := ph * 0.5
        char_layer.draw_rect(Rect2(p0 + Vector2(0, 3.0) * us, psz),
                        Color(0.1, 0.15, 0.3, 0.25))
        _round_rect(char_layer, p0, psz, rr, Color(sk["edge"], 1.0))
        _round_rect(char_layer, p0 + Vector2(3.0 * us, 3.0 * us),
                        psz - Vector2(6.0 * us, 6.0 * us), rr * 0.8,
                        Color(sk["body"], 1.0))
        _round_rect(char_layer, p0 + Vector2(hw * 0.4, 4.0 * us),
                        Vector2(hw * 1.2, ph * 0.28), rr * 0.3,
                        Color(1, 1, 1, 0.4))
        # THE BALLS (the skin, the trail, the fire, the metal)
        var bs := _ball_skin()
        for b in balls:
                var r := float(b["r"])
                var trail: Array = b["trail"]
                var fire := fire_t > 0.0
                var metal := metal_t > 0.0 and not fire
                for i in trail.size():
                        var tp: Vector2 = trail[i]
                        var ta := float(i + 1) / float(trail.size() + 1)
                        var tc: Color = Color(1.0, 0.5, 0.2) if fire \
                                        else bs["glow"]
                        char_layer.draw_circle(tp, r * 0.8 * ta,
                                        Color(tc, 0.16 * ta))
                var bp := Vector2(float(b["x"]), float(b["y"]))
                if fire:
                        # the flame: a warm halo + flicker teeth
                        char_layer.draw_circle(bp, r * 1.7,
                                        Color(1.0, 0.45, 0.15, 0.22))
                        char_layer.draw_circle(bp, r * 1.25,
                                        Color(1.0, 0.6, 0.2, 0.4))
                elif metal:
                        char_layer.draw_circle(bp, r * 1.35,
                                        Color(0.75, 0.80, 0.9, 0.25))
                char_layer.draw_circle(bp, r, Color(bs["body"], 1.0))
                char_layer.draw_circle(bp - Vector2(r * 0.28, r * 0.3),
                                r * 0.45, Color(1, 1, 1, 0.55))
                if metal:
                        # the rivet shine
                        char_layer.draw_circle(bp + Vector2(r * 0.3, r * 0.25),
                                        r * 0.18, Color(0.9, 0.93, 1.0, 0.8))
                if bool(b["stuck"]) and phase == "serve":
                        # the launch hint: a soft up arrow breathing
                        var ay := bp.y - r - 18.0 * us \
                                        - 6.0 * us * sin(_time * 5.0)
                        char_layer.draw_colored_polygon(
                                        PackedVector2Array([
                                        Vector2(bp.x - 10.0 * us, ay),
                                        Vector2(bp.x + 10.0 * us, ay),
                                        Vector2(bp.x, ay - 16.0 * us)]),
                                        Color(1, 1, 1, 0.5))

## the capsule: a rounded pill with the kind's glyph (code-drawn)
func _draw_capsule(p: Vector2, kind: String) -> void:
        var w := 64.0 * us
        var h := 34.0 * us
        var col: Color
        match kind:
                "pad": col = Color(0.55, 0.85, 1.0)
                "spd": col = Color(1.0, 0.75, 0.30)
                "size": col = Color(0.85, 0.65, 1.0)
                "multi": col = Color(0.55, 1.0, 0.65)
                "metal": col = Color(0.75, 0.80, 0.88)
                "fire": col = Color(1.0, 0.45, 0.25)
                _: col = Color(1, 1, 1)
        var r2 := Rect2(p - Vector2(w, h) * 0.5, Vector2(w, h))
        char_layer.draw_rect(Rect2(r2.position + Vector2(0, 2.5) * us,
                        r2.size), Color(0.08, 0.1, 0.2, 0.3))
        _round_rect(char_layer, r2.position, r2.size, h * 0.5,
                        Color(col, 0.95))
        _round_rect(char_layer, r2.position + Vector2(4.0 * us, 3.5 * us),
                        Vector2(w - 8.0 * us, h * 0.34), h * 0.17,
                        Color(1, 1, 1, 0.45))
        var c := r2.get_center()
        var g := Color(0.1, 0.12, 0.2, 0.9)
        var s := h * 0.30
        match kind:
                "pad":
                        # the wide bar with side arrows
                        char_layer.draw_rect(Rect2(c - Vector2(s * 1.4,
                                        s * 0.28), Vector2(s * 2.8, s * 0.56)),
                                        g)
                        for d in [-1.0, 1.0]:
                                char_layer.draw_colored_polygon(
                                        PackedVector2Array([
                                        c + Vector2(d * s * 1.9, 0),
                                        c + Vector2(d * s * 1.4, -s * 0.5),
                                        c + Vector2(d * s * 1.4, s * 0.5)]),
                                        g)
                "spd":
                        char_layer.draw_circle(c - Vector2(s * 0.7, 0),
                                        s * 0.55, g)
                        for i in 2:
                                var xo := c.x + s * (0.15 + 0.55 * float(i))
                                char_layer.draw_colored_polygon(
                                        PackedVector2Array([
                                        Vector2(xo, c.y - s * 0.5),
                                        Vector2(xo + s * 0.45, c.y),
                                        Vector2(xo, c.y + s * 0.5)]), g)
                "size":
                        char_layer.draw_circle(c, s * 0.55, g)
                        for d in [-1.0, 1.0]:
                                char_layer.draw_colored_polygon(
                                        PackedVector2Array([
                                        c + Vector2(0, d * s * 1.5),
                                        c + Vector2(-s * 0.45,
                                                        d * s * 0.9),
                                        c + Vector2(s * 0.45, d * s * 0.9)]),
                                        g)
                "multi":
                        for i in 3:
                                char_layer.draw_circle(c + Vector2(
                                                (float(i) - 1.0) * s * 0.9,
                                                0.0), s * 0.4, g)
                "metal":
                        char_layer.draw_circle(c, s * 0.6, g)
                        char_layer.draw_circle(c, s * 0.6, Color(1, 1, 1,
                                        0.25))
                        char_layer.draw_circle(c - Vector2(s * 0.2,
                                        s * 0.2), s * 0.18,
                                        Color(1, 1, 1, 0.8))
                "fire":
                        char_layer.draw_colored_polygon(
                                        PackedVector2Array([
                                        c + Vector2(0, -s * 1.1),
                                        c + Vector2(s * 0.7, s * 0.5),
                                        c + Vector2(-s * 0.7, s * 0.5)]),
                                        g)
                        char_layer.draw_circle(c + Vector2(0, s * 0.35),
                                        s * 0.32, Color(1, 1, 1, 0.5))

func _draw_fx() -> void:
        for p in _fx:
                var a: float = clampf(p["life"] / p["max"], 0.0, 1.0)
                var c: Color = p["col"]
                c.a = a
                fx_layer.draw_rect(Rect2(p["x"] - p["s"] * 0.5,
                                p["y"] - p["s"] * 0.5, p["s"], p["s"]), c)

# ============================================================= the shop
## THE SHOP LAW: paddle skins + ball skins + themes + the powerups (the
## drops' pool). Rows read the maze shop law: coin buttons, gray when
## the wallet is dry, reopen on buy.

func _shop_open() -> void:
        if shop_id != "":
                return
        shop_id = "shop"
        if gate_ui != null and is_instance_valid(gate_ui):
                gate_ui.visible = false
        paused = true
        get_tree().paused = true
        var sheet := sheet_push(0.0, "shop")
        var t := Arc.label("BRICK BREAKER SHOP", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := _vp()
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.5, 300.0,
                        620.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        box.add_child(Arc.fit_label("PADDLE SKINS - the bounce stays the "
                        + "same, the paint changes", 24, Arc.HOT, 560))
        for id in SKINS:
                box.add_child(_skin_row(id))
        box.add_child(Arc.fit_label("BALL SKINS - the physics stay the "
                        + "same, the orb changes", 24, Arc.HOT, 560))
        for id in BALLS:
                box.add_child(_ball_row(id))
        box.add_child(Arc.fit_label("THEMES - every theme REDRAWS the "
                        + "world (bricks, frame, air), not just the colors",
                        24, Arc.HOT, 560))
        for id in THEMES:
                box.add_child(_theme_row(id))
        box.add_child(Arc.fit_label("POWERUPS - only the OWNED kinds "
                        + "appear in the drops (2% of bricks, after 40% "
                        + "is broken)", 24, Arc.HOT, 560))
        for id in POWS:
                box.add_child(_pow_row(id))
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                        func(): sheet_pop()))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _goga_sheet_popped(id: String) -> void:
        if id == "shop":
                shop_id = ""
                get_tree().paused = false
                paused = false
                _apply_theme()
                brick_layer.queue_redraw()
                # THE GATE TRUTH LAW: the gate comes back ONLY over boot
                if phase == "boot" and gate_ui != null \
                                and is_instance_valid(gate_ui):
                        gate_ui.visible = true

func _skin_row(id: String) -> Control:
        var c: Dictionary = SKINS[id]
        var owned := Box.skin_owned(game_id, id) or int(c["price"]) == 0
        var on: bool = Box.skin_on(game_id) == id \
                or (int(c["price"]) == 0 and Box.skin_on(game_id) == "")
        if on:
                var l := Arc.fit_label("%s  (ON) - %s" % [c["name"],
                                c["desc"]], 22, Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        if owned:
                return Arc.button("%s - HOLD IT" % c["name"],
                        Vector2(560, 60), 22, Color("4a5ab8"), func():
                                Box.equip_skin(game_id, id)
                                Jukebox.sfx("confirm", -4.0)
                                _shop_reopen())
        var b := Arc.coin_button("%s  %d" % [c["name"], int(c["price"])],
                        Vector2(560, 64), 22, Color("4a5ab8"), func():
                                if Box.buy_skin(game_id, id, int(c["price"])):
                                        Jukebox.sfx("buy")
                                        Box.equip_skin(game_id, id)
                                _shop_reopen())
        if Box.coins() < int(c["price"]):
                b.disabled = true
        return b

func _ball_row(id: String) -> Control:
        var c: Dictionary = BALLS[id]
        var owned := Box.item_owned(game_id, "ballskin", id) \
                or int(c["price"]) == 0
        var on: bool = Box.item_on(game_id, "ballskin") == id \
                or (int(c["price"]) == 0
                and Box.item_on(game_id, "ballskin") == "")
        if on:
                var l := Arc.fit_label("%s  (ON) - %s" % [c["name"],
                                c["desc"]], 22, Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        if owned:
                return Arc.button("%s - ROLL ON" % c["name"],
                        Vector2(560, 60), 22, Color("7a4ab8"), func():
                                Box.equip_item(game_id, "ballskin", id)
                                Jukebox.sfx("confirm", -4.0)
                                _shop_reopen())
        var b := Arc.coin_button("%s  %d" % [c["name"], int(c["price"])],
                        Vector2(560, 64), 22, Color("7a4ab8"), func():
                                if Box.buy_item(game_id, "ballskin", id,
                                                int(c["price"])):
                                        Jukebox.sfx("buy")
                                        Box.equip_item(game_id, "ballskin",
                                                        id)
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
                var l := Arc.fit_label("%s  (ON) - %s" % [c["name"],
                                c["desc"]], 22, Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        if owned:
                return Arc.button("%s - DRAW ON IT" % c["name"],
                        Vector2(560, 60), 22, Color("2a7a68"), func():
                                Box.equip_item(game_id, "theme", id)
                                Jukebox.sfx("confirm", -4.0)
                                _shop_reopen())
        var b := Arc.coin_button("%s  %d" % [c["name"], int(c["price"])],
                        Vector2(560, 64), 22, Color("2a7a68"), func():
                                if Box.buy_item(game_id, "theme", id,
                                                int(c["price"])):
                                        Jukebox.sfx("buy")
                                        Box.equip_item(game_id, "theme", id)
                                _shop_reopen())
        if Box.coins() < int(c["price"]):
                b.disabled = true
        return b

func _pow_row(id: String) -> Control:
        var c: Dictionary = POWS[id]
        var owned := Box.item_owned(game_id, "powerup", id)
        if owned:
                var l := Arc.fit_label("%s  (OWNED - IT DROPS NOW) - %s"
                                % [c["name"], c["desc"]], 22, Color("58c470"),
                                560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        var b := Arc.coin_button("%s  %d" % [c["name"], int(c["price"])],
                        Vector2(560, 64), 22, Color("b85a1e"), func():
                                if Box.buy_item(game_id, "powerup", id,
                                                int(c["price"])):
                                        Jukebox.sfx("buy")
                                _shop_reopen())
        if Box.coins() < int(c["price"]):
                b.disabled = true
        return b

func _shop_reopen() -> void:
        if shop_id != "":
                sheet_pop()
                _shop_open.call_deferred()

# =========================================================== the probe
## The headless contract: a fresh deterministic run any probe drives.

func probe_reset(seed_v: int) -> void:
        rng.seed = seed_v
        _gate_down()
        level_i = 1
        score = 0
        set_score(0)
        lives = START_LIVES
        lives_lbl.text = str(lives)
        pts = 0
        pts_lbl.text = "0"
        life_next = PTS_PER_LIFE
        bricks_broken = 0
        coin_pending = 0
        run_coins = 0
        _fx = []
        _auto = false
        _new_level(1)
        balls = []
        phase = "serve"
        _spawn_serve_ball()

func probe_step(dt: float) -> void:
        _goga_tick(dt)

## the probe's helpers (the laws stay drivable without UI surgery)
func probe_launch() -> void:
        for b in balls:
                if bool(b["stuck"]):
                        _launch_ball(b)
        phase = "play"

func probe_damage(key: Vector2i, dmg: int, fire := false) -> void:
        _damage_cell(key, dmg, fire)

func probe_pad_w() -> float:
        return _pad_w()
