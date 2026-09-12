extends GogaGame
## DOT EATER (v0.3.9-5, repaired v0.3.9-6) - the endless maze chomp,
## graduated from the DOT MUNCHER teaser (the owner: "i guess dot eater
## better so dot eater"). GDD: docs/goga_docs/gogames_ideas/pacman.md.
## The character is BALLDOZER - the owner's cross-game ball (it took
## Snowy Tower's roller seat in the same round) - "a hyper-active ball
## that goes through 2D and 3D universes and trapped into a game box from
## game to another and always finds itself in different worlds and just
## brain-washed to the supervisor controls (aka user inputs in a funny
## way)".
##
## THE OWNER'S LAWS (binding, from the v0.3.9-5 message):
##   - HORIZONTAL ONLY - the maze escaper frame, landscape.
##   - THE ENDLESS RANDOM LAW: the original "was supposed to be endless
##     but a bug happened in level 256" - ours IS endless and RANDOM:
##     "static one means players will get used to it almost instantly".
##     Every level 1 is fresh; the generator still wears "patterns and
##     proper design": a mirrored carve, braided loops, a spawn plaza.
##   - THE JUNCTION BUFFER (the owner's own numbers, word for word): "we
##     have a long path, and the next way is at 10 and we are at 5, doing
##     the move will not be recorded, doing the move at 7-8 will be
##     recorded to be applied at 10, doing it at 10 will do it instantly,
##     doing one at 7-8 then doing another before going through 10 will
##     not record it". ONE slot, a pre-junction window, no early records,
##     no double records. Reversal is always instant (the original's
##     mercy) and swiping the way you already go costs nothing.
##   - THE WRAP LAW: "pacman has some of it's walls opened to the other
##     side" - wrap tunnels join the left and right board edges.
##   - NO FRUIT. ("we do not need this here")
##   - THE RUSH LAW: the BLUE magical dot - "makes you faster and makes
##     ghosts slower and edible for an amount of time, do it accurately".
##     AND ITS COUNTDOWN IS VISIBLE: "i recommend you to add the count
##     down as a widget here too, will be good because original was
##     letting it hidden".
##   - THE GOLD LAW: the dots are GOLDEN. Dots are NOT score and NOT
##     currency - "1 dot 2 dot 3 dot" is a counter, nothing more.
##   - THE LIFE LAW: "collecting 500 will give one extra life, the game
##     will start with 3 life points, end will happen when all life
##     points are gone".
##   - THE SCORE LAW: "score will be based on completing mazes, each one
##     with 1 point". The box bonus is /3 (registry coin_div 3).
##   - THE COIN LAW: "a goga coin will appear in a place of a normal dot
##     after each 3 mazes to be collected".
##   - THE BALL-EATER LAW: "pacman has ghosts, here make them
##     ball-eaters" - FOUR of them, round bodies with mouths of their own.
##   - THE BITING LAW: "make sure to make the biting animation of
##     balldozer" - the mouth lives in the movement, always chewing.
##   - THE LORE LAW: lore dialogue the space invaders / cursed dario way -
##     a lore at the VERY FIRST START, a lore at the VERY FIRST END.
##     TAP ANYWHERE TO START. NO optionals / options for now (the shop
##     still sells - that is merchandise, not options).
##   - THE SHOP: skins (Balldozer coats) + "different cool themes" whose
##     default is the known NEON; "other themes should be different
##     things and not just colors somehow" - every theme changes HOW the
##     maze is drawn (glow lines / twin strokes / stone blocks / candy),
##     not just the palette.
##
## ------------------------------------------------- the v0.3.9-6 repairs
##   - THE STORY SHEET TRUTH (the owner: "the biggest L here is the
##     dialogue start button when clicked, does not close the dialogue so
##     i can start"): the lore card was built with a RAW Arc.sheet - the
##     sheet STACK stayed empty, so the button's sheet_pop() found
##     nothing and the dim never died (the tree unpaused UNDER a stuck
##     dim - the game untouchable). The pair is tracked and freed by the
##     button now - the invaders pattern, word for word.
##   - THE NAME LAW (the owner: "character name is bal.dozer instead of
##     balldozer which is weird because it is double l"): BALLDOZER,
##     everywhere, no dots.
##   - THE DOT WIDGET TRUTH (the owner: "the dots and score widgets next
##     to each other and there is no visual feedback to which is which"):
##     the dot counter wears a LIVE dot icon painted from the theme's own
##     dot color (gold on neon, pearl on arcade, ember on dungeon,
##     sugar on candy) - it re-paints when a theme equips.
##   - THE WRAP TRUTH (the owner: "the opened-wall area ... the map
##     outline itself still exist ... make sure moving through it be
##     smooth where the body go and move literally toward it and while
##     moving, the part that moved appears in the other side in a cool
##     way"): a wrap flight now walks the body OFF one edge while the
##     other half EMERGES on the far edge (two honest copies), the old
##     whole-board glide is gone, and the phantom collisions it caused
##     died with it. The mouth circles are chevron hints now.
##   - THE PEN LAW (the owner: "i saw the ball-hunters area without that
##     ghost-gate rectangle/square thing which makes it look like a
##     ...weird thing"): the pen is a SEALED house now - perimeter walls
##     close on BOTH sides (the one-way seams were walls you walked
##     through one way and ceilings the next), ONE door at the top, and
##     the door wears the classic GATE BAR. The eaters walk out of it,
##     the eyes walk home into it.
##   - THE SIZE LADDER (the owner: "make sure that it is has the
##     different maze sizes and not one size that get shuffled from
##     shape to another"): the maze grows every couple of runs - 15x9
##     up to 35x19, the cell stays human-visible (the maze escaper
##     scaling law).
##   - THE MERCY LAW: a breath of spawn protection after every READY -
##     no eater kills inside it (the run died three bites into the old
##     build).
##

## Probe contract: the maze core is STATIC - gen_sizes / gen_maze /
## open_between / mirror_c / braid / is_open / reach drive headless laws
## without the scene (the squares contract). The scene rides
## probe_reset(seed) + probe_step(dt); player / eaters / buf / dots_left
## are public.

# ------------------------------------------------------------- the boards
## THE MAZE LADDER (the v0.3.9-6 size law: the owner wants SIZES, not one
## size reshuffled - "different maze sizes and not one size that get
## shuffled from shape to another", the maze escaper scaling taste).
## cols stay 4m+3 (the seam stays an odd lattice node - the mirror law);
## rows stay odd. Growth lands every 2-3 mazes so the climb is FELT.
const BASE_COLS := 15
const BASE_ROWS := 9
const COL_STEP := 2           # +4 cols every 2 mazes (cols stay 4m+3)
const ROW_STEP := 3           # +2 rows every 3 mazes
const MAX_COLS := 35
const MAX_ROWS := 19
const MIN_CELL := 34.0
const MARGIN := 30.0
const TOP_GAP := 118.0
const BOT_GAP := 96.0

# ------------------------------------------------------------ the movement
const PLAYER_SPEED := 5.2            # cells/s, the patrol pace
const RUSH_PLAYER_MULT := 1.32       # "makes you faster"
const EATER_BASE_SPEED := 4.05       # cells/s at maze 1
const EATER_MAZE_STEP := 0.018       # + per maze (the climb)
const EATER_MAX_SPEED := 5.0
const RUSH_EATER_MULT := 0.55        # "makes ghosts slower"
const EYES_SPEED := 7.5              # the eaten run home fast
const BUF_WINDOW := 2.5              # cells: the owner's "7-8 of 10"
const RUSH_TIME := 7.0               # the magical dot's "amount of time"

# THE SPEED LAW (the owner, v0.3.9-6 round 2: "i guess original pacman
# has speed multiplier, we should make one where speed increases by
# x1.10 after each level and maximum is x3 i guess for now, the logic
# of speed widget should be like the rest of the games like snake,
# geometry flash, ping pong"): Balldozer rolls x1.10 faster EVERY maze,
# the widget wears the live multiplier, x3.00 is the ceiling.
const SPEED_LEVEL_STEP := 1.10
const SPEED_MULT_MAX := 3.0

# --------------------------------------------------------------- the lives
const START_LIVES := 3               # "the game will start with 3 life points"
const DOTS_PER_LIFE := 500           # "collecting 500 will give one extra life"
const COIN_EVERY := 3                # "a goga coin ... after each 3 mazes"

# --------------------------------------------------------------- the waves
const SCATTER_TIME := 6.0
const CHASE_TIME := 20.0

# ================================================================== THEMES
## THE THEME LAW (the owner: "other themes should be different things and
## not just colors somehow"): every theme wears a WALL STYLE that redraws
## the maze its own way - glow lines (the neon default), the 1980 twin
## strokes, thick stone blocks with a bevel, rounded candy walls on a
## LIGHT page. Palette rides along, but the draw is the identity.
const THEMES := {
        "neon": {"name": "NEON MAZE", "price": 0, "style": "glow",
                "wall": Color(0.45, 0.95, 1.0), "wall_dim": Color(0.10, 0.22, 0.42),
                "dot": Color(1.0, 0.82, 0.30), "power": Color(0.35, 0.62, 1.0),
                "bg_top": Color(0.030, 0.045, 0.11), "bg_mid": Color(0.055, 0.07, 0.16),
                "bg_bot": Color(0.015, 0.025, 0.06), "bg_grid": Color(0.14, 0.20, 0.42),
                "room": Color(0.020, 0.028, 0.07), "desc": "the known neon "
                        + "- glow walls on the geometry grid"},
        "arcade": {"name": "ARCADE '80", "price": 280, "style": "twin",
                "wall": Color(0.22, 0.32, 1.0), "wall_dim": Color(0.08, 0.10, 0.34),
                "dot": Color(0.96, 0.90, 0.72), "power": Color(0.55, 0.70, 1.0),
                "bg_top": Color(0.016, 0.016, 0.05), "bg_mid": Color(0.012, 0.012, 0.04),
                "bg_bot": Color(0.008, 0.008, 0.03), "bg_grid": Color(0.05, 0.05, 0.14),
                "room": Color(0.010, 0.010, 0.035), "desc": "the 1980 homage "
                        + "- twin-stroke blue on near-black"},
        "dungeon": {"name": "DUNGEON", "price": 380, "style": "block",
                "wall": Color(0.52, 0.46, 0.38), "wall_dim": Color(0.24, 0.20, 0.15),
                "dot": Color(1.0, 0.62, 0.22), "power": Color(0.40, 0.55, 1.0),
                "bg_top": Color(0.070, 0.055, 0.038), "bg_mid": Color(0.055, 0.042, 0.030),
                "bg_bot": Color(0.038, 0.030, 0.022), "bg_grid": Color(0.16, 0.12, 0.08),
                "room": Color(0.045, 0.036, 0.026), "desc": "thick torchlit "
                        + "stone - the corridors of the keep"},
        "candy": {"name": "CANDY PAGE", "price": 460, "style": "candy",
                "wall": Color(0.96, 0.52, 0.72), "wall_dim": Color(0.85, 0.62, 0.78),
                "dot": Color(0.72, 0.42, 0.62), "power": Color(0.30, 0.55, 0.95),
                "bg_top": Color(0.988, 0.945, 0.960), "bg_mid": Color(0.975, 0.925, 0.945),
                "bg_bot": Color(0.960, 0.905, 0.935), "bg_grid": Color(0.90, 0.80, 0.86),
                "room": Color(0.935, 0.885, 0.915), "desc": "the light page - "
                        + "rounded candy walls, sugar pearls"},
}

# ------------------------------------------------------------------ SKINS
## Balldozer's coats (the maze skin law). The body is CODE-DRAWN - the
## mouth bites, the eyes ride the direction - so a skin is a palette, not
## a picture.
const SKINS := {
        "classic": {"name": "BALLDOZER", "price": 0, "body": Color(1.0, 0.80, 0.26),
                "shade": Color(0.72, 0.50, 0.10), "eye": Color(0.10, 0.08, 0.06),
                "desc": "the golden original"},
        "mint": {"name": "MINT DOZER", "price": 140, "body": Color(0.45, 0.92, 0.70),
                "shade": Color(0.22, 0.60, 0.42), "eye": Color(0.07, 0.14, 0.10),
                "desc": "the cool chewer"},
        "bubble": {"name": "BUBBLE DOZER", "price": 190, "body": Color(1.0, 0.55, 0.78),
                "shade": Color(0.76, 0.30, 0.52), "eye": Color(0.16, 0.06, 0.10),
                "desc": "the pink appetite"},
        "frost": {"name": "FROST DOZER", "price": 240, "body": Color(0.62, 0.86, 1.0),
                "shade": Color(0.30, 0.52, 0.76), "eye": Color(0.06, 0.10, 0.16),
                "desc": "the cold bite"},
        "shade": {"name": "SHADE DOZER", "price": 320, "body": Color(0.36, 0.34, 0.44),
                "shade": Color(0.16, 0.15, 0.22), "eye": Color(0.92, 0.90, 0.85),
                "desc": "the midnight maw"},
}

## the ball-eaters: four bodies, four drives (the ghost quartet, round)
const EATER_DEFS := [
        {"id": "bite", "kind": "hunter", "col": Color(0.92, 0.30, 0.28),
                "shade": Color(0.62, 0.14, 0.14), "corner": Vector2i(-1, -1)},
        {"id": "snap", "kind": "ambusher", "col": Color(0.95, 0.56, 0.72),
                "shade": Color(0.68, 0.28, 0.44), "corner": Vector2i(1, -1)},
        {"id": "gnaw", "kind": "flanker", "col": Color(0.38, 0.85, 0.85),
                "shade": Color(0.16, 0.52, 0.55), "corner": Vector2i(-1, 1)},
        {"id": "chomp", "kind": "mood", "col": Color(1.0, 0.62, 0.30),
                "shade": Color(0.72, 0.34, 0.10), "corner": Vector2i(1, 1)},
]

# ----------------------------------------------------------------- lore
## THE LORE (the owner: "write the lore in a cool way"). Balldozer falls
## into the box's maze world; the supervisor's finger is the input.
const LORE_START := "BALLDOZER ONLINE.\n\nI was born rolling. Nobody parks me.\n\nI have fallen through more worlds than I can count - flat ones, blocky ones, one made of snow (we do not talk about the snow). The BOX throws me from game to game and never once asked if I wanted to go.\n\nThis time it dropped me in a maze that glows, scattered golden dots everywhere like the box KNEW me, and gave four round idiots my scent. They have teeth. I have a bigger mouth.\n\nI do not know who the SUPERVISOR is. I only feel their finger - it swipes, and my body just... goes. Brain-washed? Please. I call it TEAMWORK.\n\nFine. You want dots? I will eat the MAZE. Every dot. Every maze. Forever - the box never runs out, and neither do I."

const LORE_END := "The lights went out mid-chomp.\n\nMaze %d. That is where they finally cornered me. FOUR of them - they planned it, I saw them smile with their whole round faces.\n\nStill. A good day's eating. The dots were golden, the rush was BLUE, and my mouth never got tired once.\n\nI wonder where I will find myself next. Back here again? Falling from a tower? Breaking bricks on some paddle's court? Or maybe... finally out of the box.\n\nHa. Who am I kidding. There is no out. There is only NEXT.\n\nBalldozer rolls on."

# ================================================================ THE MAZE
## Static so tests drive the generator without the scene (the squares
## contract). A maze = a grid of cells, each {t, b, l, r, wrap} booleans
## (true = wall). CARVE: recursive backtracker on the ODD lattice, LEFT
## HALF ONLY, mirrored to the right (the original's symmetry: "patterns
## and proper design"). BRAID: every dead end gets one wall knocked
## through (mirrored) - loops everywhere, you can never be cornered with
## no exit. PLAZA: a 3x3 open room in the middle (the pen). WRAP: 1-3
## rows open at the left and right board edges.

## the odd sizes for maze #n (0-based): the endless growth ladder
static func gen_sizes(n: int) -> Vector2i:
        var cols: int = mini(BASE_COLS + (n / COL_STEP) * 4, MAX_COLS)
        var rows: int = mini(BASE_ROWS + (n / ROW_STEP) * 2, MAX_ROWS)
        return Vector2i(cols, rows)

## the center (node) column: cols = 4m+3 keeps it an ODD lattice column
static func center_cx(cols: int) -> int:
        return (cols - 1) / 2

## is this cell inside the 3x3 pen? (the static pen test)
static func _is_pen(c: Vector2i, cx: int, cy: int) -> bool:
        return absi(c.x - cx) <= 1 and absi(c.y - cy) <= 1

## the mirror x of a column (the vertical-axis seam)
static func mirror_c(c: int, cols: int) -> int:
        return cols - 1 - c

static func _mk_grid(cols: int, rows: int) -> Array:
        var g: Array = []
        for r in rows:
                var row: Array = []
                for c in cols:
                        row.append({"t": true, "b": true, "l": true, "r": true,
                                        "wrap": false})
                g.append(row)
        return g

## open the wall between two ADJACENT cells (never on the border)
static func open_between(g: Array, a: Vector2i, b: Vector2i) -> void:
        var d := b - a
        if d == Vector2i(1, 0):
                g[a.y][a.x]["r"] = false
                g[b.y][b.x]["l"] = false
        elif d == Vector2i(-1, 0):
                g[a.y][a.x]["l"] = false
                g[b.y][b.x]["r"] = false
        elif d == Vector2i(0, 1):
                g[a.y][a.x]["b"] = false
                g[b.y][b.x]["t"] = false
        elif d == Vector2i(0, -1):
                g[a.y][a.x]["t"] = false
                g[b.y][b.x]["b"] = false

## carve ONE lattice edge (node a -> node b, 2 apart: the wall between
## them is the midpoint cell) plus its mirror across the seam
static func _carve(g: Array, cols: int, a: Vector2i, b: Vector2i) -> void:
        var mid := Vector2i((a.x + b.x) / 2, (a.y + b.y) / 2)
        open_between(g, a, mid)
        open_between(g, mid, b)
        var ma := Vector2i(mirror_c(a.x, cols), a.y)
        var mb := Vector2i(mirror_c(b.x, cols), b.y)
        var mmid := Vector2i((ma.x + mb.x) / 2, (ma.y + mb.y) / 2)
        open_between(g, ma, mmid)
        open_between(g, mmid, mb)

## THE BRAID LAW: knock a wall from every dead-end node cell (mirrored),
## looping until the maze has no dead ends left. A braided maze is a
## lattice of loops - the chomp never corners itself into a 1-exit pit.
static func braid(g: Array, cols: int, rows: int, rng: RandomNumberGenerator) -> void:
        for guard in 64:
                var dead: Array = []
                for y in range(1, rows - 1):
                        if y % 2 == 0:
                                continue
                        for x in range(1, cols - 1):
                                if x % 2 == 0:
                                        continue
                                var n := 0
                                if not g[y][x]["t"]:
                                        n += 1
                                if not g[y][x]["b"]:
                                        n += 1
                                if not g[y][x]["l"]:
                                        n += 1
                                if not g[y][x]["r"]:
                                        n += 1
                                if n <= 1:
                                        dead.append(Vector2i(x, y))
                if dead.is_empty():
                        return
                for d in dead:
                        # one knock per pass, mirrored (the symmetry holds)
                        var shut: Array = []
                        if d.x - 2 >= 1 and g[d.y][d.x]["l"]:
                                shut.append(Vector2i(d.x - 2, d.y))
                        if d.x + 2 <= cols - 2 and g[d.y][d.x]["r"]:
                                shut.append(Vector2i(d.x + 2, d.y))
                        if d.y - 2 >= 1 and g[d.y][d.x]["t"]:
                                shut.append(Vector2i(d.x, d.y - 2))
                        if d.y + 2 <= rows - 2 and g[d.y][d.x]["b"]:
                                shut.append(Vector2i(d.x, d.y + 2))
                        if shut.is_empty():
                                continue
                        var pick: Vector2i = shut[rng.randi_range(
                                        0, shut.size() - 1)]
                        _carve(g, cols, d, pick)

## THE MAZE (static, deterministic under a seeded rng)
static func gen_maze(cols: int, rows: int, rng: RandomNumberGenerator) -> Dictionary:
        var g := _mk_grid(cols, rows)
        var cx := center_cx(cols)
        var cy := (rows / 4) * 2 + 1
        # the backtracker: odd cells, LEFT HALF (x <= cx) - the mirrors
        # build the right half as the left one carves (the seam is the
        # center node column, shared by both halves)
        var seen: Dictionary = {}
        var stack: Array = [Vector2i(cx, cy)]
        seen[stack[0]] = true
        while not stack.is_empty():
                var cur: Vector2i = stack.back()
                var opts: Array = []
                for off in [Vector2i(0, -2), Vector2i(0, 2), Vector2i(-2, 0),
                                Vector2i(2, 0)]:
                        var nx: Vector2i = cur + off
                        if nx.x < 1 or nx.x > cx or nx.y < 1 \
                                        or nx.y > rows - 2:
                                continue
                        if seen.has(nx):
                                continue
                        opts.append(nx)
                if opts.is_empty():
                        stack.pop_back()
                        continue
                var pick: Vector2i = opts[rng.randi_range(0, opts.size() - 1)]
                _carve(g, cols, cur, pick)
                seen[pick] = true
                stack.append(pick)
        braid(g, cols, rows, rng)
        # THE PLAZA: the pen, a 3x3 open room seated on an odd node
        for yy in range(cy - 1, cy + 2):
                for xx in range(cx - 1, cx + 2):
                        g[yy][xx]["t"] = false
                        g[yy][xx]["b"] = false
                        g[yy][xx]["l"] = false
                        g[yy][xx]["r"] = false
        # THE PEN SEAL (v0.3.9-6): every perimeter wall closes on BOTH
        # sides. The old plaza only cleared the pen cells' own flags, so
        # the walls were ONE-WAY - open from inside, shut from outside
        # (the owner's "weird thing": bodies walking through one face and
        # bouncing off the next). One door stays: the GATE at the top
        # middle - the classic's single ghost-house door.
        for yy in range(cy - 1, cy + 2):
                for xx in range(cx - 1, cx + 2):
                        # each perimeter edge once: right + bottom faces
                        for d in [[1, 0], [0, 1]]:
                                var nx: int = xx + d[0]
                                var ny: int = yy + d[1]
                                var in_p := nx >= cx - 1 and nx <= cx + 1 \
                                                and ny >= cy - 1 and ny <= cy + 1
                                if in_p:
                                        continue        # an inner wall: stays open
                                if nx < 0 or nx > cols - 1 or ny < 0 \
                                                or ny > rows - 1:
                                        continue
                                # close both sides of this shared edge
                                if d[0] == 1:
                                        g[yy][xx]["r"] = true
                                        g[ny][nx]["l"] = true
                                else:
                                        g[yy][xx]["b"] = true
                                        g[ny][nx]["t"] = true
                        # the pen's outer rim faces (left/top of the rim
                        # cells) close against their outside neighbours
                        for d in [[-1, 0], [0, -1]]:
                                var nx2: int = xx + d[0]
                                var ny2: int = yy + d[1]
                                var in_p2 := nx2 >= cx - 1 and nx2 <= cx + 1 \
                                                and ny2 >= cy - 1 and ny2 <= cy + 1
                                if in_p2:
                                        continue
                                if nx2 < 0 or nx2 > cols - 1 or ny2 < 0 \
                                                or ny2 > rows - 1:
                                        continue
                                if d[0] == -1:
                                        g[yy][xx]["l"] = true
                                        g[ny2][nx2]["r"] = true
                                else:
                                        g[yy][xx]["t"] = true
                                        g[ny2][nx2]["b"] = true
        # THE GATE: the one door, top middle - two-way open (the eaters
        # march out of it, the eyes march home into it)
        open_between(g, Vector2i(cx, cy - 1), Vector2i(cx, cy - 2))
        # THE PEN-BRAID FIXUP (v0.3.9-6): the seal restores the pen walls
        # on BOTH sides, and a corridor cell that leans on the pen wall
        # can come out with ONE exit (a dead end - the braid law broken).
        # Knock SAFE walls until no dead end remains: a knock whose path
        # never crosses the pen (midpoint + target both pen-free). The
        # pen stays sealed; the loops come back.
        for guard in 64:
                var dead: Array = []
                for y in range(1, rows - 1):
                        if y % 2 == 0:
                                continue
                        for x in range(1, cols - 1):
                                if x % 2 == 0:
                                        continue
                                var c := Vector2i(x, y)
                                if _is_pen(c, cx, cy):
                                        continue
                                var n := 0
                                for d in [Vector2i(1, 0), Vector2i(-1, 0),
                                                Vector2i(0, 1), Vector2i(0, -1)]:
                                        if is_open(g, cols, x, y, d):
                                                n += 1
                                if n <= 1:
                                        dead.append(c)
                if dead.is_empty():
                        break
                for dcell in dead:
                        var shut: Array = []
                        for off in [Vector2i(-2, 0), Vector2i(2, 0),
                                        Vector2i(0, -2), Vector2i(0, 2)]:
                                var tgt: Vector2i = dcell + off
                                if tgt.x < 1 or tgt.x > cols - 2 \
                                                or tgt.y < 1 or tgt.y > rows - 2:
                                        continue
                                var mid := Vector2i((dcell.x + tgt.x) / 2,
                                                (dcell.y + tgt.y) / 2)
                                if _is_pen(tgt, cx, cy) or _is_pen(mid, cx, cy):
                                        continue        # never through the pen
                                shut.append(tgt)
                        if shut.is_empty():
                                continue
                        var pick: Vector2i = shut[rng.randi_range(
                                        0, shut.size() - 1)]
                        _carve(g, cols, dcell, pick)
        # THE WRAP LAW: the middle row always, plus 1-2 odd rows far from
        # the middle - "some of it's walls opened to the other side"
        var wraps: Array = [cy]
        var cand: Array = []
        for y in range(1, rows - 2, 2):
                if absi(y - cy) >= 4 and not wraps.has(y):
                        cand.append(y)
        while cand.size() > 2:
                cand.remove_at(rng.randi_range(0, cand.size() - 1))
        for y in cand:
                wraps.append(y)
        for y in wraps:
                g[y][0]["l"] = false
                g[y][0]["wrap"] = true
                g[y][cols - 1]["r"] = false
                g[y][cols - 1]["wrap"] = true
        return {"g": g, "plaza": Vector2i(cx, cy), "wraps": wraps}

## the reachability map (BFS over open walls, wrap edges included) -
## every dot cell must be reachable or the maze is VOID (the flow law)
static func reach(g: Array, cols: int, start: Vector2i) -> Dictionary:
        var seen: Dictionary = {start: true}
        var q: Array = [start]
        var i := 0
        while i < q.size():
                var cur: Vector2i = q[i]
                i += 1
                for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1),
                                Vector2i(0, -1)]:
                        var key := "r"
                        if d == Vector2i(-1, 0):
                                key = "l"
                        elif d == Vector2i(0, 1):
                                key = "b"
                        elif d == Vector2i(0, -1):
                                key = "t"
                        if g[cur.y][cur.x][key]:
                                continue
                        var nx: Vector2i = cur + d
                        # THE WRAP SHIFT: the opened border edges join sides
                        if nx.x < 0:
                                nx.x = cols - 1
                        elif nx.x > cols - 1:
                                nx.x = 0
                        if nx.y < 0 or nx.y > g.size() - 1 or seen.has(nx):
                                continue
                        seen[nx] = true
                        q.append(nx)
        return seen

## is the wall toward `dir` open at cell (c, r)? (the wrap edges read
## open). THE BOUNDS LAW (v0.3.9-6 round 2): a cell outside the grid is
## NEVER open - the old raw read pushed an OOB error storm and read the
## storm's null as a wall face, freezing the run (the flight-recorder
## caught the whole class after one corrupt seat).
static func is_open(g: Array, cols: int, c: int, r: int, dir: Vector2i) -> bool:
        if c < 0 or r < 0 or r > g.size() - 1 or c > cols - 1:
                return false
        var cell: Dictionary = g[r][c]
        if dir == Vector2i(1, 0):
                if c == cols - 1 and cell["wrap"]:
                        return true
                return not cell["r"]
        if dir == Vector2i(-1, 0):
                if c == 0 and cell["wrap"]:
                        return true
                return not cell["l"]
        if dir == Vector2i(0, 1):
                return r < g.size() - 1 and not cell["b"]
        if dir == Vector2i(0, -1):
                return r > 0 and not cell["t"]
        return false

# ============================================================ THE SCENE
var us := 1.0
var rng := RandomNumberGenerator.new()
var g: Array = []               # the wall grid (static law above)
var cols := BASE_COLS
var rows := BASE_ROWS
var plaza := Vector2i.ZERO      # the pen (3x3 open room)
var wraps: Array = []           # the wrap rows
var cell_px := 60.0             # SCREEN px (the fit law)
var board := Vector2.ZERO       # the board's top-left (SCREEN px)
var maze_i := 0                 # 0-based maze index (the endless ladder)
var dots: Dictionary = {}       # cell -> "d" | "p" | "c" (dot/power/coin)
var dots_left := 0
var dots_run := 0               # the run's dot counter (the 500 life law)
var life_next := DOTS_PER_LIFE  # the next extra-life milestone
var lives := START_LIVES
var phase := "boot"             # boot|lore|ready|run|dying|clear|over
var ready_t := 0.0              # the READY beat (the between-maze breath)
var _time := 0.0                # the game clock (the living layer law)

# the player (Balldozer): cell-step movement + the bite
var player := {"cell": Vector2i.ZERO, "dir": Vector2i(1, 0),
        "from": Vector2i.ZERO, "to": Vector2i.ZERO, "t": 0.0,
        "moving": false, "mouth": 0.0, "alive": true}
var buf := Vector2i.ZERO        # THE JUNCTION BUFFER - one slot, the law

# the ball-eaters
var eaters: Array = []
var mode := "scatter"
var mode_left := SCATTER_TIME

# the rush
var rush_left := 0.0
var eaten_this_rush := 0
var mercy_t := 0.0              # THE MERCY LAW: the spawn breath

# nodes
var bg: ColorRect = null
var bg_mat: ShaderMaterial = null
var maze_layer: Node2D = null   # walls + dots (event+time driven)
var char_layer: Node2D = null   # the bodies (time driven - the bite)
var fx_layer: Node2D = null     # bursts + the coin
var gate_ui: Control = null
var banner_lbl: Label = null    # the READY / MAZE CLEAR flash
var banner_t := 0.0
var dots_lbl: Label = null
var dot_icon: TextureRect = null   # the dot counter's live dot icon
var lives_lbl: Label = null
var rush_lbl: Label = null
var rush_chip: Control = null
var speed_lbl: Label = null        # the x1.10-a-maze speed widget
var pre_dir := Vector2i.ZERO       # a swipe stashed during the READY beat
var death_t := 0.0
var clear_t := 0.0
var _fx: Array = []             # [{x, y, vx, vy, life, max, s, col}]
var tex := {}
var shop_id := ""
var _story_paused := false      # THIS node paused the tree for the lore
var _story_pair: Array = []     # the story sheet's exact dim+center pair
                                # (freed by the button - THE STORY SHEET
                                # TRUTH, the raw Arc.sheet never joined the
                                # pop stack, the old START died on a no-op)

## the pause END is a RUN-LIVE row only (the ask/gate/lore keep it hidden)
func _goga_pause_end_ok() -> bool:
        return phase == "run"

func _vp() -> Vector2:
        return get_viewport_rect().size

func _theme() -> Dictionary:
        var tid := Box.item_on(game_id, "theme")
        if not THEMES.has(tid):
                tid = "neon"
        return THEMES[tid]

func _skin() -> Dictionary:
        var sid := Box.skin_on(game_id)
        if not SKINS.has(sid):
                sid = "classic"
        return SKINS[sid]

# =================================================================== setup
func _goga_setup() -> void:
        rng.randomize()
        game_id = "pacman"
        var vp := _vp()
        us = vp.y / 1080.0
        tk.tapped.connect(_tap_anywhere)
        tk.swiped.connect(_swipe_dir)
        _build_world()
        _build_hud_extra()
        # THE SHOP LAW: merchandise in the HUD, options DO NOT EXIST here
        # (the owner: "no optionals or options for now")
        add_hud_button("SHOP", func(): _shop_open())
        pause_end_run = true         # THE PONG LAW: the pause END banks
        Jukebox.music("res://assets/audio/music/de_theme.wav")
        _new_maze(true)
        # THE LORE LAW: the first start wears its story (the invaders way)
        if Box.counter(game_id, "lore_start") == 0:
                Box.bump_counter(game_id, "lore_start", 1)
                _story_show("BALLDOZER", LORE_START, func(): _build_gate(),
                                "START")
        else:
                _build_gate()

func _build_world() -> void:
        var t := _theme()
        # the neon bg rides the geometry shader (the maze escaper law) -
        # the flat themes (arcade/dungeon/candy) tint it near-invisible
        bg = ColorRect.new()
        bg.size = _vp()
        bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
        bg_mat = ShaderMaterial.new()
        bg_mat.shader = load("res://game/games/geometry/fx/gf_bg.gdshader")
        bg.material = bg_mat
        add_child(bg)
        _apply_theme()
        maze_layer = Node2D.new()
        maze_layer.draw.connect(_draw_maze)
        add_child(maze_layer)
        fx_layer = Node2D.new()
        fx_layer.draw.connect(_draw_fx)
        add_child(fx_layer)
        char_layer = Node2D.new()
        char_layer.draw.connect(_draw_chars)
        add_child(char_layer)

## THE SPEED LAW: x1.10 per maze, x3.00 the ceiling (the owner's numbers)
func _speed_mult() -> float:
        return minf(SPEED_MULT_MAX, pow(SPEED_LEVEL_STEP, float(maze_i)))

func _apply_theme() -> void:
        var t := _theme()
        bg_mat.set_shader_parameter("col_top", t["bg_top"])
        bg_mat.set_shader_parameter("col_mid", t["bg_mid"])
        bg_mat.set_shader_parameter("col_bot", t["bg_bot"])
        bg_mat.set_shader_parameter("line_col", t["bg_grid"])
        bg_mat.set_shader_parameter("pulse", 0.22)
        # the flat-page themes keep the grid whisper-quiet (the draw lives
        # in the walls, not the backdrop)
        if String(t["style"]) == "glow":
                bg_mat.set_shader_parameter("line_col", t["bg_grid"])
        else:
                bg_mat.set_shader_parameter("line_col",
                                Color(t["bg_grid"], 0.35))
        # THE DOT WIDGET TRUTH (v0.3.9-6): the counter's icon is painted
        # from THIS theme's dot color - gold on neon, pearl on arcade,
        # ember on dungeon, sugar on candy. The widget tells you what it
        # counts at a glance, and re-paints when a theme equips.
        if dot_icon != null and is_instance_valid(dot_icon):
                dot_icon.texture = _make_dot_texture(t["dot"])

## a glossy little ball in the theme's dot color (code-painted, no
## assets - the sprite IS the thing the counter counts)
func _make_dot_texture(col: Color) -> ImageTexture:
        var sz := 48
        var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
        var c := Vector2(sz, sz) * 0.5
        var r := sz * 0.40
        for y in sz:
                for x in sz:
                        var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
                        var a := clampf((r - d) / 1.6, 0.0, 1.0)
                        if a <= 0.0:
                                continue
                        var k := clampf(d / r, 0.0, 1.0)
                        var shade := 1.18 - 0.42 * k     # the top-light
                        img.set_pixel(x, y, Color(
                                clampf(col.r * shade, 0.0, 1.0),
                                clampf(col.g * shade, 0.0, 1.0),
                                clampf(col.b * shade, 0.0, 1.0), a))
        return ImageTexture.create_from_image(img)

func _build_hud_extra() -> void:
        # THE DOT COUNTER ("1 dot 2 dot 3 dot" - NOT score, the owner) -
        # it wears the theme-painted dot icon (the widget truth)
        dots_lbl = add_hud_chip("0")
        var dh := dots_lbl.get_parent() as HBoxContainer
        if dh != null:
                dot_icon = TextureRect.new()
                dot_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                dot_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                dot_icon.custom_minimum_size = Vector2(30.0, 30.0) * us
                dot_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
                dh.add_child(dot_icon)
                dh.move_child(dot_icon, 0)
                dot_icon.texture = _make_dot_texture(_theme()["dot"])
        # THE LIFE COUNTER (the heart chip)
        lives_lbl = add_hud_chip(str(START_LIVES), "res://assets/ui/heart.png")
        # THE RUSH WIDGET (the owner: "add the count down as a widget here
        # too, will be good because original was letting it hidden")
        rush_lbl = add_hud_chip("7.0")
        rush_chip = rush_lbl.get_parent().get_parent() as Control
        rush_chip.visible = false
        # THE SPEED WIDGET (the speed law: the snake seat - it reads x1.00
        # at the patrol pace and climbs x1.10 a maze to the x3.00 ceiling)
        speed_lbl = add_hud_chip("x1.00")
        # THE SEAT LAW (the owner, v0.3.9-6 round 2: "score widget should
        # be at the left side from the gogacoins widget, others comes
        # later" - the snake/geometry/ping-pong look): the dots/lives/rush
        # chips move LEFT of the score chip, the speed chip rides the
        # snake seat right after the score one, the row reads
        # dots | lives | rush | SCORE | speed | coins.
        var score_chip := _score_chip_ref()
        if score_chip != null:
                for chip in [_chip_of(dots_lbl), _chip_of(lives_lbl),
                                rush_chip]:
                        _hud_row.move_child(chip, score_chip.get_index())
        # the flash banner (READY / MAZE CLEAR / the deaths' verdict)
        banner_lbl = Arc.label("", 62, Color(1, 1, 1, 0))
        banner_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
        banner_lbl.offset_top = 150.0 * us
        banner_lbl.offset_bottom = 230.0 * us
        banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _hud.add_child(banner_lbl)

## the chip Control behind one of this game's HUD chip labels (the seat
## law's mover)
func _chip_of(lbl: Label) -> Control:
        if lbl == null or lbl.get_parent() == null \
                        or lbl.get_parent().get_parent() == null:
                return null
        return lbl.get_parent().get_parent() as Control

func _flash(txt: String, col := Color(1, 1, 1, 1)) -> void:
        banner_lbl.text = txt
        banner_lbl.modulate = Color(col, 0.0)
        banner_t = 1.0

# ============================================================ the maze fit
func _layout() -> void:
        var vp := _vp()
        cols = gen_sizes(maze_i).x
        rows = gen_sizes(maze_i).y
        var avail_w := vp.x - MARGIN * 2.0 * us
        var avail_h := vp.y - (TOP_GAP + BOT_GAP) * us
        cell_px = minf(avail_w / float(cols), avail_h / float(rows))
        cell_px = maxf(cell_px, MIN_CELL * us)
        board = Vector2((vp.x - cell_px * float(cols)) * 0.5,
                        (vp.y - cell_px * float(rows)) * 0.5
                        + (TOP_GAP - BOT_GAP) * 0.5 * us)

func _cell_px(c: Vector2i) -> Vector2:
        return board + Vector2(float(c.x) + 0.5, float(c.y) + 0.5) * cell_px

# ============================================================ the maze new
func _new_maze(first := false) -> void:
        _layout()
        var m := gen_maze(cols, rows, rng)
        g = m["g"]
        plaza = m["plaza"]
        wraps = m["wraps"]
        # THE DOTS: every reachable corridor cell wears one (the plaza
        # stays clean); the corners of the maze wear the four BLUE ones
        dots = {}
        var spawn := Vector2i(plaza.x, plaza.y + 2)
        var r := reach(g, cols, spawn)
        for y in rows:
                for x in cols:
                        var c := Vector2i(x, y)
                        if not r.has(c):
                                continue
                        if _in_plaza(c):
                                continue
                        dots[c] = "d"
        # THE QUADRANT LAW: the four blue magical dots sit at the reachable
        # node cells nearest the board's four corners (the classic's shape)
        var corners := [Vector2i(1, 1), Vector2i(cols - 2, 1),
                        Vector2i(1, rows - 2), Vector2i(cols - 2, rows - 2)]
        var got := 0
        for corner in corners:
                var best := Vector2i(-1, -1)
                var bd := 1 << 30
                for key in dots.keys():
                        if String(dots[key]) != "d":
                                continue
                        var dd: int = absi(key.x - corner.x) \
                                        + absi(key.y - corner.y)
                        if dd < bd:
                                bd = dd
                                best = key
                if best.x >= 0:
                        dots[best] = "p"
                        got += 1
        # THE COIN LAW: after each 3 mazes a GOGACoin rests where a dot was
        if not first and maze_i > 0 and maze_i % COIN_EVERY == 0:
                var pool: Array = []
                for key in dots.keys():
                        if String(dots[key]) == "d":
                                pool.append(key)
                if not pool.is_empty():
                        dots[pool[rng.randi_range(0, pool.size() - 1)]] = "c"
        dots_left = dots.size()
        _seat_actors()
        maze_layer.queue_redraw()
        # THE SPEED WIDGET: the live multiplier reads the new maze's rung
        if speed_lbl != null and is_instance_valid(speed_lbl):
                speed_lbl.text = "x%.2f" % _speed_mult()

func _in_plaza(c: Vector2i) -> bool:
        return absi(c.x - plaza.x) <= 1 and absi(c.y - plaza.y) <= 1

## the actors to their seats (a fresh maze, or a life lost - the maze
## keeps its eaten dots, the original's mercy)
func _seat_actors() -> void:
        var spawn := Vector2i(plaza.x, plaza.y + 2)
        player["cell"] = spawn
        player["from"] = spawn
        player["to"] = spawn
        player["t"] = 0.0
        player["moving"] = false
        player["dir"] = Vector2i(-1, 0)
        player["mouth"] = 0.0
        buf = Vector2i.ZERO
        pre_dir = Vector2i.ZERO       # a fresh maze owes no stale order
        eaters = []
        for def in EATER_DEFS:
                var e := {"id": String(def["id"]), "kind": String(def["kind"]),
                        "col": def["col"], "shade": def["shade"],
                        "corner": def["corner"],
                        "cell": plaza, "from": plaza, "to": plaza, "t": 0.0,
                        "dir": Vector2i(1, 0), "moving": false,
                        "state": "pen", "pen_t": 1.2 + 0.6 * float(eaters.size()),
                        "mouth": 0.0}
                eaters.append(e)
        mode = "scatter"
        mode_left = SCATTER_TIME
        char_layer.queue_redraw()

## THE READY BEAT: a breath before the chase (the original's READY!)
func _ready_beat(txt := "READY!") -> void:
        phase = "ready"
        ready_t = 1.3
        mercy_t = 1.1          # the mercy outlives the beat a moment
        _flash(txt, Color(1.0, 0.82, 0.30))

# ================================================== THE JUNCTION BUFFER LAW
## The owner's mechanic, word for word: "we have a long path, and the
## next way is at 10 and we are at 5, doing the move will not be
## recorded, doing the move at 7-8 will be recorded to be applied at 10,
## doing it at 10 will do it instantly, doing one at 7-8 then doing
## another before going through 10 will not record it".
##   dist 0.0   -> AT the junction: the turn happens NOW.
##   dist <= BUF_WINDOW -> inside the window: the slot takes it (if free).
##   dist >  BUF_WINDOW -> too early: not recorded.
##   slot full  -> not recorded (one at a time, the owner's law).
func _swipe_dir(dir: Vector2i, _at: Vector2 = Vector2.ZERO) -> void:
        # THE READY STASH (round 2): a swipe during the READY beat is the
        # supervisor's FIRST order - the old build swallowed it (the whole
        # 1.3s beat ate every swipe and the run opened deaf). One slot,
        # the buffer law's shape; it applies the moment the run starts.
        if phase == "ready" and not paused and not over:
                if dir != player["dir"]:
                        pre_dir = dir
                return
        if phase != "run" or paused or over:
                return
        var pd: Vector2i = player["dir"]
        # THE MERCY: reversal is always instant (the original lets you
        # flip mid-corridor; the buffer law is for TURNS ahead)
        if dir == -pd:
                _reverse_now(dir)
                return
        # swiping the way you already go costs nothing WHILE GOING - but
        # a STOPPED body wears a stale face (the spawn face, the wall
        # face): the old early-return ate that swipe whole (the flight
        # recorder's S1: the first swipe of the run, dead on the floor)
        if dir == pd and player["moving"]:
                return
        # standing still (a wall face): any open way starts instantly
        if not player["moving"]:
                if is_open(g, cols, player["cell"].x, player["cell"].y, dir):
                        _start_move(dir)
                return
        var info := _junction_info()
        var dist := float(info["d"])
        var dcell: Vector2i = info["cell"]
        if dist < 0.0 or not _dir_open_at(dcell, dir):
                return          # no decision ahead (or the way is a wall)
        if dist <= 0.05:
                # AT the decision point: "doing it at 10" - instantly
                _turn_at(dcell, dir)
                return
        if dist > BUF_WINDOW:
                return                      # "at 5" - not recorded
        if buf != Vector2i.ZERO:
                return                      # the slot is full - not recorded
        buf = dir                           # "at 7-8" - recorded for 10

## the reverse, mid-corridor: swap the flight, keep the progress
func _reverse_now(dir: Vector2i) -> void:
        if player["moving"]:
                var f: Vector2i = player["from"]
                player["from"] = player["to"]
                player["to"] = f
                player["t"] = 1.0 - float(player["t"])
                player["dir"] = dir
                buf = Vector2i.ZERO
        elif is_open(g, cols, player["cell"].x, player["cell"].y, dir):
                _start_move(dir)
                buf = Vector2i.ZERO

## the upcoming decision cell (where a turn may happen next)
func _decision_cell() -> Vector2i:
        return player["to"] if player["moving"] else player["cell"]

## is `dir` open AT cell c? (the wrap edges read open through is_open)
func _dir_open_at(c: Vector2i, dir: Vector2i) -> bool:
        if c.x < 0 or c.y < 0 or c.y > g.size() - 1 or c.x > cols - 1:
                return false
        return is_open(g, cols, c.x, c.y, dir)

## THE JUNCTION LOOKUP: one walk down the current corridor returns the
## distance (cells, fractional) to the next decision point AND that
## point's cell. A decision point = a cell where a perpendicular edge is
## open (a turn exists) OR the current direction is blocked (the walk
## must stop). The owner's "the next way is at 10" - this finds the 10.
func _junction_info() -> Dictionary:
        var head := (1.0 - float(player["t"])) if player["moving"] else 0.0
        var cur: Vector2i = _decision_cell()
        var pd: Vector2i = player["dir"]
        var d := head
        for guard in cols * rows:
                # a junction: an open edge PERPENDICULAR to the run
                for nd in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0),
                                Vector2i(-1, 0)]:
                        if nd == pd or nd == -pd:
                                continue
                        if _dir_open_at(cur, nd):
                                return {"d": d, "cell": cur}
                # the wrap edge: crossing it is a straight pass, not a turn
                if _dir_open_at(cur, pd):
                        var nx: Vector2i = cur + pd
                        if nx.x < 0:
                                nx.x = cols - 1
                        elif nx.x > cols - 1:
                                nx.x = 0
                        d += 1.0
                        cur = nx
                else:
                        # the corridor ends here - this cell IS the decision
                        return {"d": d, "cell": cur}
        return {"d": -1.0, "cell": cur}

## apply a turn AT a cell (the flight to the next cell starts clean).
## THE MID-FLIGHT TRUTH: an instant turn at the decision point lands the
## arrival here - the dot at that cell is eaten NOW, not never.
## THE HONEST TARGET (round 2): _wrap_to RETURNS the next cell - the old
## `c + _wrap_to(c, dir)` double-added it and the body flew to 2c+dir
## (the owner's video: a diagonal sweep to a cell off the board, the run
## frozen on an OOB error storm, the face turned while the body sat).
func _turn_at(c: Vector2i, dir: Vector2i) -> void:
        _eat_at(c)
        player["cell"] = c
        player["from"] = c
        player["to"] = _wrap_to(c, dir)
        player["t"] = 0.0
        player["moving"] = true
        player["dir"] = dir
        buf = Vector2i.ZERO

## the wrap-aware step target
func _wrap_to(c: Vector2i, dir: Vector2i) -> Vector2i:
        var nx: Vector2i = c + dir
        if nx.x < 0:
                nx.x = cols - 1
        elif nx.x > cols - 1:
                nx.x = 0
        return nx

func _start_move(dir: Vector2i) -> void:
        var c: Vector2i = player["cell"]
        player["from"] = c
        player["to"] = _wrap_to(c, dir)
        player["t"] = 0.0
        player["moving"] = true
        player["dir"] = dir

## the pixel position of the player (v0.3.9-6: THE WRAP TRUTH - see
## _travel_px; the old lerp of raw cells glided the body across the WHOLE
## board on a wrap step, sweeping phantom collisions through the middle)
func _player_px() -> Vector2:
        return _travel_px(player["from"], player["to"],
                        float(player["t"]))[0]

## is this flight a WRAP flight (crossing the seam)?
func _wrap_step(from: Vector2i, to: Vector2i) -> bool:
        return from.y == to.y and ((from.x == 0 and to.x == cols - 1) \
                        or (from.x == cols - 1 and to.x == 0))

## THE WRAP TRUTH (v0.3.9-6, the owner: "make sure moving through it be
## smooth where the body go and move literally toward it and while
## moving, the part that moved appears in the other side in a cool
## way"): a wrap flight returns TWO positions - the body walks OFF one
## edge (the raw step continues past the border as if the cells were
## adjacent) while its other half EMERGES on the far edge, walking IN.
## No glide across the board, no phantom sweeps - the classic's own look.
func _travel_px(from: Vector2i, to: Vector2i, t: float) -> Array:
        var a := _cell_px(from)
        var b := _cell_px(to)
        if not _wrap_step(from, to):
                return [a.lerp(b, t)]
        var step := Vector2(-cell_px if from.x == 0 else cell_px, 0.0)
        var p1 := a.lerp(a + step, t)
        var span := Vector2(float(cols) * cell_px, 0.0)
        return [p1, p1 + (span if from.x == 0 else -span)]

# ================================================================ the tick
func _goga_tick(delta: float) -> void:
        _time += delta
        if banner_t > 0.0:
                banner_t -= delta
                var a := clampf(banner_t / 0.35, 0.0, 1.0)
                banner_lbl.modulate.a = a
                if banner_t <= 0.0:
                        banner_lbl.text = ""
        match phase:
                "ready":
                        ready_t -= delta
                        if ready_t <= 0.0:
                                phase = "run"
                                # THE READY STASH: the first order applies
                                if pre_dir != Vector2i.ZERO:
                                        var d := pre_dir
                                        pre_dir = Vector2i.ZERO
                                        _swipe_dir(d)
                "dying":
                        death_t -= delta
                        _death_anim(delta)
                        if death_t <= 0.0:
                                _after_death()
                "clear":
                        clear_t -= delta
                        if clear_t <= 0.0:
                                maze_i += 1
                                _new_maze()
                                _ready_beat()
                "run":
                        _tick_run(delta)
        _tick_fx(delta)
        char_layer.queue_redraw()     # THE LIVING LAYER: the bite breathes
        maze_layer.queue_redraw()     # dots pulse + the power orbs breathe

func _tick_run(delta: float) -> void:
        # the mercy breath (no kills while it lasts)
        if mercy_t > 0.0:
                mercy_t = maxf(0.0, mercy_t - delta)
        # the rush clock (the widget countdown - the owner's ask)
        if rush_left > 0.0:
                rush_left -= delta
                if rush_left <= 0.0:
                        rush_left = 0.0
                        eaten_this_rush = 0
                        rush_chip.visible = false
                        for e in eaters:
                                if e["state"] == "fright":
                                        e["state"] = "roam"
                else:
                        rush_lbl.text = "%.1f" % maxf(0.0, rush_left)
        # the scatter/chase waves (the original's rhythm)
        mode_left -= delta
        if mode_left <= 0.0:
                if mode == "scatter":
                        mode = "chase"
                        mode_left = CHASE_TIME
                else:
                        mode = "scatter"
                        mode_left = SCATTER_TIME
        _tick_player(delta)
        _tick_eaters(delta)
        _check_collisions()

func _player_speed() -> float:
        # THE SPEED LAW: the maze multiplier (x1.10 a maze, x3.00 the cap)
        # rides the patrol pace; the rush still stacks its own x1.32
        return PLAYER_SPEED * _speed_mult() \
                        * (RUSH_PLAYER_MULT if rush_left > 0.0 else 1.0)

func _tick_player(delta: float) -> void:
        if not player["moving"]:
                # THE CHOMP NEVER SLEEPS: the mouth idles half-open
                player["mouth"] += delta * 3.0
                return
        var spd := _player_speed()
        player["t"] += spd * delta
        player["mouth"] += delta * (9.0 if rush_left > 0.0 else 6.5)
        while player["t"] >= 1.0 and player["moving"]:
                player["t"] -= 1.0
                var cell: Vector2i = player["to"]
                player["cell"] = cell
                _arrive(cell)
                if not player["moving"]:
                        player["t"] = 0.0
                        break
                player["from"] = cell
                player["to"] = _wrap_to(cell, player["dir"])

## the arrival: eat, then THE BUFFER APPLIES (the owner's "at 10").
## THE WALL FACE LAW (round 2): the corridor ends -> the chomp WAITS,
## the classic's own patience - the old auto-reverse bounced the body
## back out of every stem (the recorder filmed it oscillating between
## two cells, "the character goes to a weird side" all over again).
## The way out is the supervisor's finger: any open way starts instantly
## (_swipe_dir's standing branch), the reversal swipe included.
func _arrive(cell: Vector2i) -> void:
        _eat_at(cell)
        # the buffered turn - the single slot spends itself here
        if buf != Vector2i.ZERO and _dir_open_at(cell, buf):
                player["dir"] = buf
                buf = Vector2i.ZERO
                player["to"] = _wrap_to(cell, player["dir"])
                return
        buf = Vector2i.ZERO            # a turn that never fit dies at 10
        if _dir_open_at(cell, player["dir"]):
                player["to"] = _wrap_to(cell, player["dir"])
                return
        player["moving"] = false       # the wall face: the chomp waits

func _eat_at(cell: Vector2i) -> void:
        if not dots.has(cell):
                return
        var kind := String(dots[cell])
        dots.erase(cell)
        dots_left -= 1
        if kind == "c":
                # THE GOGACOIN (the house currency - the only money here)
                add_run_coins(1)
                achievement_count("coins_taken", 1)
                Jukebox.sfx("de_coin", -4.0)
                _burst(_cell_px(cell), Color(1.0, 0.85, 0.35), 10)
                maze_layer.queue_redraw()
                return
        dots_run += 1
        dots_lbl.text = str(dots_run)
        achievement_count("dots", 1)
        # THE LIFE LAW: "collecting 500 will give one extra life"
        if dots_run >= life_next:
                life_next += DOTS_PER_LIFE
                lives += 1
                lives_lbl.text = str(lives)
                Jukebox.sfx("de_life", -3.0)
                _flash("+1 LIFE", Color(0.55, 1.0, 0.65))
                _burst(_cell_px(cell), Color(0.55, 1.0, 0.65), 14)
        if kind == "p":
                # THE RUSH: "makes you faster and makes ghosts slower and
                # edible for an amount of time, do it accurately" - BLUE
                rush_left = RUSH_TIME
                eaten_this_rush = 0
                rush_chip.visible = true
                rush_lbl.text = "%.1f" % rush_left
                Jukebox.sfx("de_power", -3.0)
                _burst(_cell_px(cell), Color(0.35, 0.62, 1.0), 16)
                for e in eaters:
                        if e["state"] == "roam" or e["state"] == "pen":
                                e["state"] = "fright" if e["state"] == "roam" \
                                                else e["state"]
        else:
                Jukebox.sfx("de_waka_a" if (dots_run % 2 == 1) else "de_waka_b",
                                -9.0, randf_range(0.96, 1.05))
        maze_layer.queue_redraw()
        # THE MAZE WIPES CLEAN: "winning a maze is happening by collecting
        # all dots" - +1 score, the next maze weaves itself
        if dots_left <= 0:
                add_score(1)
                achievement_max("max_mazes", score)
                achievement_count("clears", 1)
                Jukebox.sfx("de_clear", -3.0)
                _flash("MAZE CLEAR  +1", Color(1.0, 0.82, 0.30))
                phase = "clear"
                clear_t = 1.6

# ============================================================ THE EATERS
## "pacman has ghosts, here make them ball-eaters" - four round bodies,
## four drives, the original's scatter/chase rhythm, the eyes that run
## home when swallowed. Movement is the same cell-step as Balldozer.

func _eater_speed(e: Dictionary) -> float:
        if e["state"] == "eyes":
                return EYES_SPEED
        var spd: float = minf(EATER_BASE_SPEED + float(maze_i) * EATER_MAZE_STEP,
                        EATER_MAX_SPEED)
        if e["state"] == "fright":
                spd *= RUSH_EATER_MULT   # "makes ghosts slower"
        return spd

func _tick_eaters(delta: float) -> void:
        for e in eaters:
                e["mouth"] += delta * 7.0
                if e["state"] == "pen":
                        e["pen_t"] -= delta
                        if e["pen_t"] <= 0.0:
                                e["state"] = "fright" if rush_left > 0.0 \
                                                else "roam"
                        continue
                var spd := _eater_speed(e)
                if not e["moving"]:
                        _eater_pick(e)
                        if not e["moving"]:
                                continue
                e["t"] += spd * delta
                while e["t"] >= 1.0 and e["moving"]:
                        e["t"] -= 1.0
                        var cell: Vector2i = e["to"]
                        e["cell"] = cell
                        _eater_arrive(e, cell)
                        if not e["moving"]:
                                e["t"] = 0.0
                                break
                        e["from"] = cell
                        e["to"] = _wrap_to(cell, e["dir"])

## the eater's arrival: the next leg is chosen by its drive
func _eater_arrive(e: Dictionary, cell: Vector2i) -> void:
        e["cell"] = cell
        _eater_pick(e)

## THE DRIVE LAW: pick the next direction at a cell (the classic's rule -
## never reverse, minimize the distance to the target, ties read
## up-left-down-right). FRIGHT maximizes instead. EYES ignore the ban.
func _eater_pick(e: Dictionary) -> void:
        var cell: Vector2i = e["cell"]
        var opts: Array = []
        for nd in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1),
                        Vector2i(1, 0)]:
                if _dir_open_at(cell, nd):
                        opts.append(nd)
        if opts.is_empty():
                e["moving"] = false
                return
        var rev: Vector2i = -Vector2i(e["dir"])
        if e["state"] == "eyes":
                if _in_plaza(cell):
                        # the eyes are home: the round body returns
                        e["state"] = "roam" if rush_left <= 0.0 else "fright"
                        e["moving"] = false
                        return
                var tgt := plaza
                var best := _pick_dir(opts, cell, tgt, false)
                if best != Vector2i(9, 9):
                        _start_eater_move(e, best)
                        return
                # the eyes are home: reborn (the round body returns)
                e["state"] = "roam" if rush_left <= 0.0 else "fright"
                e["cell"] = cell
                e["from"] = cell
                e["to"] = cell
                e["t"] = 0.0
                e["moving"] = false
                return
        var non_rev: Array = []
        for o in opts:
                if o != rev or opts.size() == 1:
                        non_rev.append(o)
        if non_rev.is_empty():
                non_rev = opts
        var target := _eater_target(e)
        if e["state"] == "fright":
                # flee: the FARTHEST open way from Balldozer
                var best_d := -1.0
                var best_dir := Vector2i(9, 9)
                for o in non_rev:
                        var nxt := _wrap_to(cell, o)
                        var dd := float(absi(nxt.x - player["cell"].x)
                                        + absi(nxt.y - player["cell"].y))
                        if dd > best_d:
                                best_d = dd
                                best_dir = o
                if best_dir != Vector2i(9, 9):
                        _start_eater_move(e, best_dir)
                else:
                        e["moving"] = false
                return
        var pick := _pick_dir(non_rev, cell, target, false)
        if pick == Vector2i(9, 9) and not opts.is_empty():
                pick = opts[0]
        if pick != Vector2i(9, 9):
                _start_eater_move(e, pick)
        else:
                e["moving"] = false

## the min-distance dir picker (the tie order lives in the caller's opts)
func _pick_dir(opts: Array, cell: Vector2i, target: Vector2i,
                maximize := false) -> Vector2i:
        var best := Vector2i(9, 9)
        var best_d := -1.0
        for o in opts:
                var nxt := _wrap_to(cell, o)
                var dd := float(absi(nxt.x - target.x) + absi(nxt.y - target.y))
                var better := (dd > best_d) if maximize else \
                                (best_d < 0.0 or dd < best_d)
                if better:
                        best_d = dd
                        best = o
        return best

## the personality targets (the quartet's drives)
func _eater_target(e: Dictionary) -> Vector2i:
        var pc: Vector2i = player["cell"]
        if mode == "scatter":
                return Vector2i(
                        clampi(plaza.x + int(e["corner"].x) * (cols - 3), 1,
                                        cols - 2),
                        clampi(plaza.y + int(e["corner"].y) * (rows - 3), 1,
                                        rows - 2))
        match String(e["kind"]):
                "hunter":
                        return pc   # straight at Balldozer, always
                "ambusher":
                        # four cells ahead of the bite
                        var ahead: Vector2i = pc + Vector2i(player["dir"]) * 4
                        ahead.x = clampi(ahead.x, 0, cols - 1)
                        ahead.y = clampi(ahead.y, 0, rows - 1)
                        return ahead
                "flanker":
                        # the mirror seat: the far side of the chomp
                        var hunter: Dictionary = eaters[0]
                        var mirror: Vector2i = pc * 2 \
                                        - Vector2i(hunter["cell"])
                        mirror.x = clampi(mirror.x, 0, cols - 1)
                        mirror.y = clampi(mirror.y, 0, rows - 1)
                        return mirror
                "mood":
                        # the mood-swinger: chases far, sulks near
                        var dd := absi(pc.x - e["cell"].x) \
                                        + absi(pc.y - e["cell"].y)
                        if dd > 8:
                                return pc
                        return Vector2i(
                                clampi(plaza.x + int(e["corner"].x) * (cols - 3),
                                                1, cols - 2),
                                clampi(plaza.y + int(e["corner"].y) * (rows - 3),
                                                1, rows - 2))
        return pc

func _start_eater_move(e: Dictionary, dir: Vector2i) -> void:
        var c: Vector2i = e["cell"]
        if c.y < 0 or c.y > g.size() - 1 or c.x < 0 or c.x > cols - 1:
                push_error("EATER OOB seat: %s cell=%s dir=%s state=%s"
                                % [e["id"], c, dir, e["state"]])
        e["from"] = c
        e["to"] = _wrap_to(c, dir)
        e["t"] = 0.0
        e["moving"] = true
        e["dir"] = dir

func _eater_px(e: Dictionary) -> Vector2:
        return _travel_px(e["from"], e["to"], float(e["t"]))[0]

## every on-screen copy of a body (1, or 2 mid-wrap - THE WRAP TRUTH)
func _travel_copies(from: Vector2i, to: Vector2i, t: float) -> Array:
        return _travel_px(from, to, t)

# ========================================================== THE COLLISIONS
## THE HONEST SEAM (v0.3.9-6): every body wears ALL its on-screen copies
## (two mid-wrap) and every copy pair tests - the old single lerp point
## swept the whole board on a wrap flight and ate phantoms (the owner's
## "a crash happens when i swipe like 3/4 times, maybe i get eaten or
## something happen" - that was the wrap glide killing him mid-seam).
func _check_collisions() -> void:
        var pps := _travel_copies(player["from"], player["to"],
                        float(player["t"]))
        for e in eaters:
                if e["state"] == "eyes":
                        continue
                var eps := _travel_copies(e["from"], e["to"],
                                float(e["t"]))
                var hit := false
                var hit_at := Vector2.ZERO
                for pp in pps:
                        for ep in eps:
                                if pp.distance_to(ep) <= cell_px * 0.62:
                                        hit = true
                                        hit_at = ep
                                        break
                        if hit:
                                break
                if not hit:
                        continue
                if e["state"] == "fright":
                        # THE SWALLOW: "makes ghosts ... edible for an
                        # amount of time" - the eyes run home
                        e["state"] = "eyes"
                        e["moving"] = false
                        eaten_this_rush += 1
                        achievement_count("eats", 1)
                        if eaten_this_rush >= 4:
                                achievement_count("quads", 1)
                        Jukebox.sfx("de_eat", -3.0)
                        _burst(hit_at, Color(0.45, 0.75, 1.0), 14)
                else:
                        # THE MERCY LAW (v0.3.9-6): no kill inside the
                        # spawn breath - the READY beat's shadow
                        if mercy_t > 0.0:
                                continue
                        _lose_life()
                        return

# ============================================================= THE DEATHS
func _lose_life() -> void:
        lives -= 1
        lives_lbl.text = str(maxi(0, lives))
        phase = "dying"
        death_t = 1.5
        Jukebox.sfx("de_hurt", -2.0)

## the classic's exit: the mouth opens until the body is gone
func _death_anim(_delta: float) -> void:
        var k := 1.0 - clampf(death_t / 1.5, 0.0, 1.0)
        player["mouth"] = k * PI    # the bite opens wide, wider, gone

func _after_death() -> void:
        if lives <= 0:
                # THE END: bank the score (score = the mazes completed)
                rush_left = 0.0
                rush_chip.visible = false
                if Box.counter(game_id, "lore_end") == 0:
                        Box.bump_counter(game_id, "lore_end", 1)
                        _story_show("THE BOX GOES DARK",
                                        String(LORE_END % maxi(1, score)),
                                        func(): finish_run(score), "CONTINUE")
                else:
                        finish_run(score)
                return
        _seat_actors()
        _ready_beat()

# ================================================================== THE FX
func _burst(at: Vector2, col: Color, n := 10) -> void:
        for i in n:
                var a := randf() * TAU
                var spd := randf_range(60.0, 190.0) * us
                _fx.append({"x": at.x, "y": at.y, "vx": cos(a) * spd,
                        "vy": sin(a) * spd, "life": 0.5,
                        "max": 0.5, "s": randf_range(4.0, 8.0) * us,
                        "col": col})

func _tick_fx(delta: float) -> void:
        var dead: Array = []
        for p in _fx:
                p["life"] -= delta
                p["x"] += p["vx"] * delta
                p["y"] += p["vy"] * delta
                p["vx"] *= 0.92
                p["vy"] *= 0.92
                if p["life"] <= 0.0:
                        dead.append(p)
        for p in dead:
                _fx.erase(p)
        if not dead.is_empty() or not _fx.is_empty():
                fx_layer.queue_redraw()

# ============================================================== THE DRAW
## THE LIVING LAYER LAW: the dots breathe and the power orbs pulse - the
## maze layer reads the clock, so the tick repaints it every frame.

func _draw_maze() -> void:
        if g.is_empty():
                return
        var t := _theme()
        var style := String(t["style"])
        var w := maxf(3.0, cell_px * 0.115)
        # the walls: every cell edge that still stands, drawn once
        for y in rows:
                for x in cols:
                        var c: Dictionary = g[y][x]
                        var p := board + Vector2(x, y) * cell_px
                        if c["t"]:
                                _wall_seg(p + Vector2(0, 0),
                                                p + Vector2(cell_px, 0), style, t, w)
                        if c["l"]:
                                _wall_seg(p + Vector2(0, 0),
                                                p + Vector2(0, cell_px), style, t, w)
                        if x == cols - 1 and c["r"] and not c["wrap"]:
                                _wall_seg(p + Vector2(cell_px, 0),
                                                p + Vector2(cell_px, cell_px),
                                                style, t, w)
                        if y == rows - 1 and c["b"]:
                                _wall_seg(p + Vector2(0, cell_px),
                                                p + Vector2(cell_px, cell_px),
                                                style, t, w)
        # the dots (golden - THE GOLD LAW), the coin, the power orbs
        var dcol: Color = t["dot"]
        var pulse := 0.5 + 0.5 * sin(_time * 5.2)
        for key in dots.keys():
                var cell: Vector2i = key
                var kind := String(dots[key])
                var p := _cell_px(cell)
                if kind == "d":
                        if style == "candy":
                                # the sugar pearl: a ringed pearl
                                maze_layer.draw_circle(p, cell_px * 0.115,
                                                Color(dcol, 0.9))
                                maze_layer.draw_arc(p, cell_px * 0.115, 0, TAU,
                                                12, Color(1, 1, 1, 0.55), 1.4)
                        elif style == "dungeon":
                                # the ember: a diamond
                                var r := cell_px * 0.12
                                maze_layer.draw_colored_polygon(
                                                PackedVector2Array([p + Vector2(0, -r),
                                                p + Vector2(r, 0), p + Vector2(0, r),
                                                p + Vector2(-r, 0)]), dcol)
                        else:
                                maze_layer.draw_circle(p, cell_px * 0.105, dcol)
                elif kind == "p":
                        # THE BLUE MAGICAL DOT - the rush orb breathes
                        var orb: Color = t["power"]
                        var r2 := cell_px * (0.24 + 0.045 * pulse)
                        maze_layer.draw_circle(p, r2 * 1.9, Color(orb, 0.12 + 0.08 * pulse))
                        maze_layer.draw_circle(p, r2, orb)
                        maze_layer.draw_circle(p, r2 * 0.45, Color(1, 1, 1, 0.5))
        # the wrap mouth marks: chevrons pointing OFF-board (v0.3.9-6 - the
        # old half-moon circles read as leftover outline at the opening;
        # these read as a tunnel that continues)
        for wy in wraps:
                var ymid := board.y + (float(wy) + 0.5) * cell_px
                var wc: Color = Color(t["wall"], 0.5)
                var tri := cell_px * 0.13
                for i in 2:
                        var off := cell_px * (0.14 + 0.19 * float(i))
                        # left mouth: arrows pointing out through the seam
                        maze_layer.draw_colored_polygon(
                                        PackedVector2Array([
                                        Vector2(board.x + off, ymid - tri),
                                        Vector2(board.x + off, ymid + tri),
                                        Vector2(board.x + off - tri, ymid)]),
                                        wc)
                        # right mouth: mirrored, pointing out the far side
                        var xr := board.x + float(cols) * cell_px
                        maze_layer.draw_colored_polygon(
                                        PackedVector2Array([
                                        Vector2(xr - off, ymid - tri),
                                        Vector2(xr - off, ymid + tri),
                                        Vector2(xr - off + tri, ymid)]),
                                        wc)
        # THE PEN HOUSE + THE GATE (v0.3.9-6, the owner: "i saw the
        # ball-hunters area without that ghost-gate rectangle/square thing
        # which makes it look like a ...weird thing"): the classic's ghost
        # house - a ring around the 3x3 pen, one door gap at the top, and
        # the DOOR BAR across it. Always drawn, every theme.
        var p0 := board + Vector2(float(plaza.x) - 1.0,
                        float(plaza.y) - 1.0) * cell_px
        var psize := Vector2(3.0, 3.0) * cell_px
        var inset := cell_px * 0.18
        var ring_pos := p0 + Vector2(inset, inset)
        var ring_sz := psize - Vector2(inset, inset) * 2.0
        var lw := maxf(3.0, cell_px * 0.09)
        var wcol: Color = t["wall"]
        var gap := cell_px * 0.62
        var midx := ring_pos.x + ring_sz.x * 0.5
        var top_y := ring_pos.y
        var bot_y := ring_pos.y + ring_sz.y
        # top side: two runs leaving the door gap in the middle
        maze_layer.draw_line(Vector2(ring_pos.x, top_y),
                        Vector2(midx - gap * 0.5, top_y), wcol, lw, true)
        maze_layer.draw_line(Vector2(midx + gap * 0.5, top_y),
                        Vector2(ring_pos.x + ring_sz.x, top_y), wcol, lw, true)
        # the other three sides: continuous (the seal is honest)
        maze_layer.draw_line(Vector2(ring_pos.x, bot_y),
                        Vector2(ring_pos.x + ring_sz.x, bot_y), wcol, lw, true)
        maze_layer.draw_line(Vector2(ring_pos.x, top_y),
                        Vector2(ring_pos.x, bot_y), wcol, lw, true)
        maze_layer.draw_line(Vector2(ring_pos.x + ring_sz.x, top_y),
                        Vector2(ring_pos.x + ring_sz.x, bot_y), wcol, lw, true)
        # THE GATE BAR: the pale rose door across the gap (the classic's
        # own door color - it reads as THE door on every theme)
        var door := Color(1.0, 0.70, 0.78)
        maze_layer.draw_line(Vector2(midx - gap * 0.5, top_y),
                        Vector2(midx + gap * 0.5, top_y), door, lw * 1.7, true)
        maze_layer.draw_line(Vector2(midx - gap * 0.5, top_y),
                        Vector2(midx + gap * 0.5, top_y),
                        Color(1, 1, 1, 0.55), lw * 0.5, true)

## the wall styles: the theme's identity (THE THEME LAW)
func _wall_seg(a: Vector2, b: Vector2, style: String, t: Dictionary,
                w: float) -> void:
        var wc: Color = t["wall"]
        var dim: Color = t["wall_dim"]
        match style:
                "glow":
                        maze_layer.draw_line(a, b, Color(wc, 0.16), w * 2.6, true)
                        maze_layer.draw_line(a, b, Color(wc, 0.5), w * 1.4, true)
                        maze_layer.draw_line(a, b, wc, w * 0.55, true)
                "twin":
                        # the 1980 homage: two thin strokes with a gap
                        var d := (b - a).normalized()
                        var nrm := Vector2(-d.y, d.x) * w * 0.42
                        maze_layer.draw_line(a + nrm, b + nrm, wc, w * 0.34, true)
                        maze_layer.draw_line(a - nrm, b - nrm, wc, w * 0.34, true)
                "block":
                        # thick stone with a top bevel light
                        maze_layer.draw_line(a, b, dim, w * 1.9, true)
                        maze_layer.draw_line(a, b, wc, w * 1.35, true)
                        maze_layer.draw_line(a, b, Color(1, 1, 1, 0.14),
                                        w * 0.5, true)
                "candy":
                        # rounded pastel with a gloss streak
                        maze_layer.draw_line(a, b, Color(dim, 0.75), w * 1.7, true)
                        maze_layer.draw_line(a, b, wc, w * 1.25, true)
                        var d2 := (b - a).normalized()
                        var n2 := Vector2(-d2.y, d2.x) * w * 0.3
                        maze_layer.draw_line(a + n2 - d2 * w * 0.2,
                                        b + n2 + d2 * w * 0.2,
                                        Color(1, 1, 1, 0.5), w * 0.3, true)

## the bodies: Balldozer's bite + the ball-eaters (all code-drawn - the
## bite lives in the movement, THE BITING LAW). Every body draws ALL its
## on-screen copies (THE WRAP TRUTH: one per seam half mid-wrap)
func _draw_chars() -> void:
        if g.is_empty():
                return
        # the ball-eaters first (Balldozer rides on top)
        for e in eaters:
                var pps := _travel_copies(e["from"], e["to"],
                                float(e["t"]))
                for p in pps:
                        if e["state"] == "eyes":
                                _draw_eyes(p, e["dir"], Color(0.92, 0.94, 1.0),
                                                Color(0.10, 0.12, 0.2),
                                                cell_px * 0.38)
                                continue
                        var fright: bool = e["state"] == "fright"
                        var body: Color = Color(0.30, 0.42, 1.0) if fright \
                                        else e["col"]
                        var shade: Color = body.darkened(0.35) if fright \
                                        else e["shade"]
                        _draw_eater(p, e["dir"], body, shade,
                                        cell_px * 0.36, float(e["mouth"]),
                                        fright)
        # BALLDOZER - the bite (the mouth angle swings with the clock)
        var sk := _skin()
        var mouth := 0.10 + 0.38 * absf(sin(player["mouth"]))
        if phase == "dying":
                mouth = clampf(player["mouth"], 0.1, PI - 0.02)
        for p in _travel_copies(player["from"], player["to"],
                        float(player["t"])):
                _draw_balldozer(p, player["dir"], sk["body"], sk["shade"],
                                sk["eye"], cell_px * 0.42, mouth)

## a body: a fan polygon with a mouth wedge cut (the appetite)
func _draw_body(p: Vector2, dir: Vector2i, r: float, mouth: float,
                body: Color, shade: Color) -> void:
        var base := Vector2(dir).angle() if dir != Vector2i.ZERO else 0.0
        var pts := PackedVector2Array()
        pts.append(p)
        var steps := 26
        for i in steps + 1:
                var a := base + mouth + (TAU - mouth * 2.0) \
                                * float(i) / float(steps)
                pts.append(p + Vector2(cos(a), sin(a)) * r)
        char_layer.draw_colored_polygon(pts, body)
        # the shaded rim (the roundness cue): a thin arc opposite the mouth
        char_layer.draw_arc(p, r * 0.82, base + PI - 1.2, base + PI + 1.2, 14,
                        Color(shade, 0.55), r * 0.16)

func _draw_balldozer(p: Vector2, dir: Vector2i, body: Color, shade: Color,
                eye_col: Color, r: float, mouth: float) -> void:
        _draw_body(p, dir, r, mouth, body, shade)
        var base := Vector2(dir).angle() if dir != Vector2i.ZERO else 0.0
        # the two eyes ride the direction, perched on top of the bite
        for s in [-1.0, 1.0]:
                var off := Vector2(cos(base + s * 0.9), sin(base + s * 0.9)) \
                                * r * 0.48
                var ep := p + off
                char_layer.draw_circle(ep, r * 0.22, Color(0.97, 0.96, 0.92))
                char_layer.draw_circle(ep + Vector2(dir) * r * 0.07, r * 0.11,
                                eye_col)

func _draw_eater(p: Vector2, dir: Vector2i, body: Color, shade: Color,
                r: float, mouth_t: float, fright: bool) -> void:
        var mouth := 0.12 + 0.34 * absf(sin(mouth_t))
        # the ball-eaters bite TOWARD their run (they eat balls)
        _draw_body(p, dir, r, mouth, body, shade)
        var base := Vector2(dir).angle() if dir != Vector2i.ZERO else 0.0
        for s in [-1.0, 1.0]:
                var off := Vector2(cos(base + s * 0.85), sin(base + s * 0.85)) \
                                * r * 0.46
                var ep := p + off
                char_layer.draw_circle(ep, r * 0.21, Color(0.96, 0.95, 0.9))
                char_layer.draw_circle(ep + Vector2(dir) * r * 0.07, r * 0.10,
                                Color(0.10, 0.1, 0.16))
        if fright:
                # the scared wobble mouth: a little "o" of panic
                char_layer.draw_circle(p + Vector2(dir) * r * 0.45, r * 0.14,
                                Color(0.92, 0.95, 1.0, 0.85))

func _draw_eyes(p: Vector2, dir: Vector2i, white: Color, pupil: Color,
                r: float) -> void:
        var base := Vector2(dir).angle() if dir != Vector2i.ZERO else 0.0
        for s in [-1.0, 1.0]:
                var off := Vector2(cos(base + s * 0.55), sin(base + s * 0.55)) \
                                * r * 0.42
                var ep := p + off
                char_layer.draw_circle(ep, r * 0.30, white)
                char_layer.draw_circle(ep + Vector2(dir) * r * 0.11, r * 0.15,
                                pupil)

func _draw_fx() -> void:
        for p in _fx:
                var a: float = clampf(p["life"] / p["max"], 0.0, 1.0)
                var c: Color = p["col"]
                c.a = a
                fx_layer.draw_rect(Rect2(p["x"] - p["s"] * 0.5,
                                p["y"] - p["s"] * 0.5, p["s"], p["s"]), c)

# ==================================================== THE GATE + THE LORE
## TAP ANYWHERE TO START (the chess gate), and the lore cards ride the
## invader story sheet - the dim eats the taps, the button walks on.

func _build_gate() -> void:
        if gate_ui != null and is_instance_valid(gate_ui):
                gate_ui.queue_free()
        phase = "ready" if ready_t > 0.0 else "boot"
        gate_ui = Control.new()
        gate_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
        gate_ui.mouse_filter = Control.MOUSE_FILTER_STOP
        var dim := ColorRect.new()
        dim.color = Color(0, 0, 0, 0.55)
        dim.set_anchors_preset(Control.PRESET_FULL_RECT)
        dim.mouse_filter = Control.MOUSE_FILTER_STOP
        gate_ui.add_child(dim)
        var vb := VBoxContainer.new()
        vb.set_anchors_preset(Control.PRESET_CENTER)
        vb.add_theme_constant_override("separation", 18)
        gate_ui.add_child(vb)
        # THE SILENT GATE (the owner, v0.3.9-6 round 2: the gate "shows too
        # many helpful stuff, remove the title from it and the word at the
        # top and the one at the bottom, there is controls talk, it's place
        # is the guide, not to be here") - the gate says its ONE sentence:
        var l := Arc.label("TAP ANYWHERE TO START", 46, Color(1, 1, 1, 0.95))
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(l)
        vb.position = _vp() * 0.5 - Vector2(300, 40)
        vb.custom_minimum_size = Vector2(600, 0)
        add_child(gate_ui)
        gate_ui.visible = true

func _gate_down() -> void:
        if gate_ui != null and is_instance_valid(gate_ui):
                gate_ui.queue_free()
        gate_ui = null

## the gate eats a tap; the run starts here
func _tap_anywhere(_at: Vector2) -> void:
        if over:
                return
        if phase == "boot":
                _gate_down()
                _ready_beat("READY!")
                Jukebox.sfx("de_start", -4.0)

## the story sheet (the invaders way: dim + scroll + one honest button).
## THE STORY SHEET TRUTH (v0.3.9-6): the pair is TRACKED here - the raw
## Arc.sheet never joins game_base's sheet stack, so sheet_pop() is a
## silent no-op for it (the owner's biggest L: the START button clicked,
## the dialogue never closed, the game untouchable). The button frees the
## exact pair itself, then walks the story on.
func _story_show(title: String, msg: String, after := Callable(),
                btn := "START") -> void:
        _story_down()
        paused = true
        get_tree().paused = true
        _story_paused = true
        var root := _overlay_root_ref()
        var sheet := Arc.sheet(root, 0.0)
        var kids := root.get_children()
        var sdim: Control = kids[kids.size() - 2]
        var scc: Control = kids[kids.size() - 1]
        sdim.process_mode = Node.PROCESS_MODE_ALWAYS
        scc.process_mode = Node.PROCESS_MODE_ALWAYS
        _story_pair = [sdim, scc]
        var t := Arc.label(title, 34, Color(1.0, 0.82, 0.30))
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := _vp()
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.44, 240.0,
                        470.0))
        var story := Arc.label(msg, 22, Arc.INK, false)
        story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        story.custom_minimum_size = Vector2(540, 0)
        story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(story)
        sheet.add_child(sc)
        sheet.add_child(Arc.button(btn, Vector2(560, 78), 28, Arc.GOOD,
                        func(): _story_end(after)))
        for b in Arc._buttons_in(sc):
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

## the story button's body: free the EXACT pair, breathe air back into
## the tree, walk the story on (the invaders _story_end, word for word)
func _story_end(after: Callable) -> void:
        _story_down()
        get_tree().paused = false
        paused = false
        _story_paused = false
        if after.is_valid():
                after.call()

func _story_down() -> void:
        for n in _story_pair:
                if n != null and is_instance_valid(n):
                        n.queue_free()
        _story_pair = []

## THE PAUSE-EXIT LAW: a run that ends under an open story sheet (the
## boot probe force-finishes; a real player never sees it) must leave the
## tree RUNNING behind it - a node that paused the world unpauses it.
func _exit_tree() -> void:
        if _story_paused:
                get_tree().paused = false
                _story_paused = false
        _story_down()

# ============================================================= the input
func _goga_input(event: InputEvent) -> void:
        if over:
                return
        if event is InputEventScreenTouch and event.pressed:
                # the gate also answers raw touches (the tap-anywhere law)
                if phase == "boot":
                        _tap_anywhere(event.position)

# ============================================================ the shop
## THE SHOP LAW: skins + the draw-themes. NO options sheet - "no
## optionals or options for now" (the owner). The rows read the maze
## shop law: coin buttons, gray when the wallet is dry, reopen on buy.

func _shop_open() -> void:
        if shop_id != "":
                return
        shop_id = "shop"
        if gate_ui != null and is_instance_valid(gate_ui):
                gate_ui.visible = false
        paused = true
        get_tree().paused = true
        var sheet := sheet_push(0.0, "shop")
        var t := Arc.label("DOT EATER SHOP", 34, Arc.INK)
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
        box.add_child(Arc.fit_label("BALLDOZER COATS - the bite stays the "
                        + "same, the paint changes", 24, Arc.HOT, 560))
        for id in SKINS:
                box.add_child(_skin_row(id))
        box.add_child(Arc.fit_label("MAZES - every theme REDRAWS the world "
                        + "(walls, dots, the air), not just the colors", 24,
                        Arc.HOT, 560))
        for id in THEMES:
                box.add_child(_theme_row(id))
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
                maze_layer.queue_redraw()
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
                return Arc.button("%s - BITE ON" % c["name"],
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

func _shop_reopen() -> void:
        if shop_id != "":
                sheet_pop()
                _shop_open.call_deferred()

# =========================================================== the probe
## The headless contract: a fresh deterministic run any probe drives.

func probe_reset(seed_v: int) -> void:
        rng.seed = seed_v
        _gate_down()
        maze_i = 0
        score = 0
        set_score(0)
        lives = START_LIVES
        lives_lbl.text = str(lives)
        dots_run = 0
        dots_lbl.text = "0"
        life_next = DOTS_PER_LIFE
        rush_left = 0.0
        rush_chip.visible = false
        run_coins = 0
        _fx = []
        _new_maze(true)
        _ready_beat()

func probe_step(dt: float) -> void:
        _goga_tick(dt)
