extends GogaGame
## SNAKES & LADDERS - v0.3.9-12, the pure-RNG classic (graduated from the
## workshop teaser). "ludo has a little logic but this one is literally
## pure RNG!" - no opponent intelligence, no moods, no memory: the die is
## the only mind at the table.
##
## Owner contract (v0.3.9-13, the test-report round):
##   - THE STAIRS: "ladders need to have extra stairs, currently they are
##     not too much and they have too wide stairs" - the rails pinch in
##     (gap 0.10 cell) and the rungs come every 0.30 cell (twice as many)
##   - THE STAR, NOTHING ELSE: cell 100 wears the bold gold star only -
##     "just make it the star only without circles or sun rays" (the
##     medallion + the rotating rays are gone; the board layer is static
##     art now and stops repainting every tick)
##   - THE WIDE BADGE: "make it wider by let's say x2 so the dice to the
##     pawn home distance has enough space" - the tray seat doubles
##     (420 cap, the 0.48 board cap keeps the pair apart); THE QUIET
##     TRAY: the THINKING words are gone - "keeping it same size but
##     removing the text and keeping just the highlight on it" - and the
##     die's breathing seat stays INSIDE the tray (the flicker fix)
##   - THE BARE TOKEN: "remove the number that is written inside the
##     pawn" - the tray's numeral is the mark
##   - THE PROPER SNAKE (the owner: "see the snake game, it may help you
##     make a proper snake face and tail end and turns"): the body is
##     STAMPED along the drawn path with an OUTLINE pass (the turns round
##     themselves), the head wears the snake game's own face - the
##     forward eyes, the pupils, the forked tongue - and the tail closes
##     in a capped point
##   - THE JUNGLE ROUND ("the jungle theme is just the default theme with
##     poor modifications"): the vine snake is BRIGHT BROWN with dark
##     body dots ("at least make the snake be bright brown with dots on
##     it's body"), the ladders sprout LEAVES at both ends ("maybe add
##     some leaves on the ladders")
##   - THE FLOW LAW: "you showed first the 'tap anywhere' then showed the
##     optionals, it should be the opposite" - the ask opens the game and
##     wears its ONE short title ("HOW MANY PLAYERS" - law 28's
##     v0.3.9-13 note: not-too-helpful never meant write-nothing), the
##     pick seats the gate, the gate's tap starts the round
##
## Owner contract (v0.3.9-12, verbatim intent):
##   - 10x10 board, 100 steps; players 2..4 (2 = 1v1, 3 = 1v2, 4 = 1v3,
##     the CPUs are pure RNG). One figure each; the figures wait OUT of
##     the board in their owner's tray until the die brings them in.
##   - "the dice rolling and W/L logic should be as same as ludo" - the
##     grayed waiting die IS the roll button (the v0.3.9-11 law), the
##     theater (fade, shuffle, settle), win +1 / lose -1, run bonus /1,
##     no draws, the loser opens the next round.
##   - "in known S&L games, the board snakes and ladders are likely the
##     same" - the classic fixed table (Milton Bradley): ladders
##     4/13/33/42/50/62/74, snakes 27/40/43/54/66/76/89/99. Same every
##     round.
##   - THE EXACT LANDING LAW (pointed at BOTH board games): "i am at 97
##     and for 100 i need the dice to be 3, if dice was 4, it should be
##     illegal and my turn is skipped".
##   - "make sure getting up a ladder makes the figure slides in straight
##     lanes while snake make the figure fall the same way the snake body
##     is, i mean following the turns of the snake body" - the ladder
##     ride is a straight lane between the rails; the snake fall follows
##     the drawn body's turns (ONE truth: the drawn path IS the ride).
##   - "ladders should be....ladders and snake should be....snake? ofc"
##     - code-drawn rails + rungs; a tapered body with a head, eyes and
##     a belly line. Amazing code-designed art, no sprite assets.
##   - "the most satisfying look is 12121212 i guess" - the checker.
##   - the 100th and the first square wear their own special design.
##   - "a gogacoin should appear in a legal area after every 5 minutes
##     in a proper scale and whoever step on it takes it".
##   - VERTICAL; optionals at the start (2, 3, 4 - the house cards, law
##     28); TAP ANYWHERE TO START; the loser opens the next round.
##   - the shop: 5 figure skins (the user's token only) + 5 board themes
##     (the board, the snakes, the ladders AND the rivals' tokens - the
##     theme-ownership law), the shelf-truth laws from birth.
##
## Probe contract: the rules core is STATIC (cell_grid / grid_cell /
## resolve_land / legal_to / coin_spots) + the scene rides
## probe_reset(players, seed) / probe_step(dt) / probe_drain() /
## probe_roll() - the bovo/ludo contract.

const BOARD_N := 10         # the board is 10x10
const LAST := 100           # the crown cell
const COIN_EVERY := 300.0   # the owner: one GOGACoin after each 5 minutes
const HOP_T := 0.16         # one hop of the walk (up, over, drop)
const FADE_T := 0.16        # the die's fade-in
const SHUF_T := 0.62        # the shuffle
const SETTLE_T := 0.16      # the settle bounce
const CPU_THINK := 0.65     # the CPU's roll beat (pure RNG only breathes)
var _coin_rot := 0          # v042: the LAN coin spot rotates (no shared RNG)
const RIDE_BEAT := 0.20     # the pause on the base/head before the ride
const CLIMB_CPS := 3.6      # the ladder's cells per second (the glide up)
const FALL_CPS := 4.8       # the snake's cells per second (gravity helps)

# =========================================================== THE RULES CORE
## THE CLASSIC FIXED TABLE (the Milton Bradley board - the one "everyone
## played"): the same places every round, the owner's own law.

const LADDERS := {4: 25, 13: 46, 33: 49, 42: 63, 50: 69, 62: 81, 74: 92}
const SNAKES := {27: 5, 40: 3, 43: 18, 54: 31, 66: 45, 76: 58, 89: 53,
                99: 41}

## THE BOUSTROPHEDON: cell 1 bottom-left, the rows snake right/left up
## to cell 100 at the top-left. Grid (col, row), row 0 at the BOTTOM.
static func cell_grid(n: int) -> Vector2i:
        var i := clampi(int(n), 1, LAST) - 1
        var r := i / BOARD_N
        var c := i % BOARD_N
        if r % 2 == 1:
                c = BOARD_N - 1 - c
        return Vector2i(c, r)

## the inverse (a grid cell -> its number; the draw's census helper)
static func grid_cell(g: Vector2i) -> int:
        var c := int(g.x)
        if g.y % 2 == 1:
                c = BOARD_N - 1 - c
        return int(g.y) * BOARD_N + c + 1

## THE RESOLVE: what landing on `cell` becomes. The classic table wears
## NO chains (no ladder top is a head or a base; no tail is either) - a
## landing resolves at most once.
static func resolve_land(cell: int) -> Dictionary:
        if LADDERS.has(cell):
                return {"ride": "ladder", "to": int(LADDERS[cell])}
        if SNAKES.has(cell):
                return {"ride": "snake", "to": int(SNAKES[cell])}
        return {"ride": "", "to": int(cell)}

## THE EXACT LANDING LAW (the owner pointed it at both board games):
## 97 + 4 is refused - the move is illegal, the turn is skipped.
static func legal_to(pos: int, roll: int) -> int:
        var np := int(pos) + int(roll)
        return np if np <= LAST else -1

## THE COIN SPOTS: a legal area = strictly ahead of the user's figure
## (any higher cell is reachable with the right rolls) and free of
## tokens - the coin never spawns under someone.
static func coin_spots(user_pos: int, occupied: Array) -> Array:
        var out := []
        for n in range(maxi(1, int(user_pos) + 1), LAST + 1):
                if not occupied.has(n):
                        out.append(n)
        return out

# ============================================================ the themes
## 5 themes, the first is the default. A theme owns EVERYTHING but the
## user's token: the room, the frame, the checker, the ladders, the
## snakes AND the rivals' figures (the theme-ownership law). The B&W
## theme is the owner's standing ask ("me as white and enemy black");
## the 5th is JUNGLE (the owner left it open on purpose, NOT pixelated).
const THEMES := {
        "mountain": {"name": "THE MOUNTAIN", "price": 0, "style": "round",
                "room": Color("332a1c"), "floor": Color("241d10"),
                "frame": Color("6e4a26"), "frame_dark": Color("54371c"),
                "sq_a": Color("f3ead2"), "sq_b": Color("dcc59b"),
                "sq_line": Color("8a744e"), "num_ink": Color("4a3a1c"),
                "ladder": Color("8a5a2e"), "ladder_dark": Color("5f3c1c"),
                "snake": Color("3f8f4f"), "snake_belly": Color("bfe0b0"),
                "tray_ink": Color(0, 0, 0, 0.4),
                "armies": [Color("e0533f"), Color("2f9e55"),
                        Color("e8b23a"), Color("4179df")],
                "glow": false},
        "neon": {"name": "NEON", "price": 400, "style": "neon",
                "room": Color("060913"), "floor": Color("03050c"),
                "frame": Color("0e1430"), "frame_dark": Color("090d20"),
                "sq_a": Color("101a36"), "sq_b": Color("1a2a55"),
                "sq_line": Color("27407a"), "num_ink": Color("7ee8ff"),
                "ladder": Color("3df2ff"), "ladder_dark": Color("0f7f8f"),
                "snake": Color("ff4fd8"), "snake_belly": Color("ffc2f2"),
                "tray_ink": Color("27407a"),
                "armies": [Color("ff3860"), Color("3dff8e"),
                        Color("ffd23d"), Color("37c8ff")],
                "glow": true},
        "candy": {"name": "CANDY", "price": 260, "style": "round",
                "room": Color("f6d7e0"), "floor": Color("eebfcf"),
                "frame": Color("fff4f7"), "frame_dark": Color("f3dce6"),
                "sq_a": Color("ffffff"), "sq_b": Color("ffe3ee"),
                "sq_line": Color("e3bfcf"), "num_ink": Color("8a4a63"),
                "ladder": Color("c98a5e"), "ladder_dark": Color("96603c"),
                "snake": Color("5fc9a0"), "snake_belly": Color("d8f5e6"),
                "tray_ink": Color(0.55, 0.28, 0.4, 0.55),
                "armies": [Color("ff6fa5"), Color("63d1a8"),
                        Color("ffc93c"), Color("9a8cf2")],
                "glow": false},
        "mono": {"name": "BLACK & WHITE", "price": 320, "style": "mono",
                "room": Color("181818"), "floor": Color("0c0c0c"),
                "frame": Color("f2f2f2"), "frame_dark": Color("cfcfcf"),
                "sq_a": Color("e4e4e4"), "sq_b": Color("a9a9a9"),
                "sq_line": Color("5f5f5f"), "num_ink": Color("141414"),
                "ladder": Color("f2f2f2"), "ladder_dark": Color("8f8f8f"),
                "snake": Color("242424"), "snake_belly": Color("9c9c9c"),
                "tray_ink": Color(1, 1, 1, 0.8),
                "armies": [Color("ffffff"), Color("a6a6a6"),
                        Color("474747"), Color("050505")],
                "glow": false},
        "jungle": {"name": "JUNGLE", "price": 460, "style": "round",
                "room": Color("142410"), "floor": Color("0c1808"),
                "frame": Color("7a5a2a"), "frame_dark": Color("5a401c"),
                "sq_a": Color("e6d9a8"), "sq_b": Color("c9b878"),
                "sq_line": Color("7a6a3c"), "num_ink": Color("3d3212"),
                "ladder": Color("d4a94a"), "ladder_dark": Color("96722a"),
                ## THE JUNGLE ROUND (the owner: "the jungle theme is just
                ## the default theme with poor modifications, at least
                ## make the snake be bright brown with dots on it's body
                ## ... maybe add some leaves on the ladders"): the vine
                ## snake wears BRIGHT BROWN with dark body dots, the
                ## ladders sprout leaves at both ends
                "snake": Color("c07f3e"), "snake_belly": Color("ecd9a0"),
                "snake_spot": Color("5f3a16"),
                "tray_ink": Color(0, 0, 0, 0.45),
                "armies": [Color("e8604f"), Color("3fbf7f"),
                        Color("ffd24a"), Color("8f7fe8")],
                "glow": false, "spots": true, "leaves": true},
}

# ------------------------------------------------------- the token skins
## THE THEME-OWNERSHIP LAW: the theme owns everything but the USER's
## token - the equipped skin re-inks only that one, on every theme.
const SKINS := {
        "theme": {"name": "THEME TOKEN", "price": 0,
                "col": Color(0, 0, 0), "ink": Color(0, 0, 0)},
        "ivory": {"name": "IVORY", "price": 150,
                "col": Color("f4ead2"), "ink": Color("4a3a1c")},
        "jade": {"name": "JADE", "price": 220,
                "col": Color("3fae8a"), "ink": Color("0d3024")},
        "rose": {"name": "ROSE", "price": 220,
                "col": Color("f27bb2"), "ink": Color("4d0e2b")},
        "onyx": {"name": "ONYX", "price": 300,
                "col": Color("23272e"), "ink": Color("e8e8e8")},
}

# the pip seats of the die face (the dice games' own map)
const PIPS := {
        1: [[0.5, 0.5]],
        2: [[0.3, 0.3], [0.7, 0.7]],
        3: [[0.3, 0.3], [0.5, 0.5], [0.7, 0.7]],
        4: [[0.3, 0.3], [0.7, 0.3], [0.3, 0.7], [0.7, 0.7]],
        5: [[0.3, 0.3], [0.7, 0.3], [0.5, 0.5], [0.3, 0.7], [0.7, 0.7]],
        6: [[0.32, 0.28], [0.68, 0.28], [0.32, 0.5], [0.68, 0.5],
                [0.32, 0.72], [0.68, 0.72]],
}

# ============================================================ state
var players := 2              # 2 | 3 | 4 (the mode sheet's pick)
var playing: Array = [1, 2]   # the players at the table (1 is the user)
var poss: Array = []          # poss[p-1] = the token's cell:
                              # 0 = waiting out of the board, 1..100 on it
var state := "ready"          # ready | roll_wait | rolling | walking |
                              # riding | handoff | round_over
var turn := 1                 # the player whose turn it is
var opener := 1               # who opens THIS round (the loser law)
var roll := 0                 # the settled face (0 = none yet)
var turn_note := ""           # the active tray's status line
var clock := 0.0              # the state machine's beat
var play_clock := 0.0         # THE COIN CLOCK (live play seconds)
var coin_cell := -1           # the coin's cell (-1 none)
var coin_t := 0.0
var rounds := 0
var wins := 0
var losses := 0
var streak := 0

# the die theater (one die, it lives at the turn player's tray pad)
var die_face := 1
var die_t0 := -1.0
var die_alive := false
var die_fading := false
var die_pos := Vector2.ZERO

# the walk (THE HOP WALK) + the ride (the ladder lane / the snake body)
var walk := {}                # {player, pts, cells, t0, np, coin_at}
var ride := {}                # {player, pts, t0, beat_t0, dur, kind, to}
var token_off := {}           # "p" -> Vector2 (the stacking slide)

# the dust (the squares law) + the verdict glow
var _dust: Array = []
var _time := 0.0
var _rng := RandomNumberGenerator.new()
var _hop_played := 0          # hops that already sang their tick

# the 2048 confirm law (stack-borne)
var _confirm_open_id := ""

# scene
var world: Node2D
var bg_l: Node2D
var board_l: Node2D
var token_l: Node2D
var fx_l: Node2D
var verdict_lbl: Label
var goals_row: Control
var ready_ui: Control = null
var board_origin := Vector2.ZERO
var cell := 64.0
var board_side := 640.0
var _paths := {}              # snake head cell -> PackedVector2Array (px)

# ============================================================ the scene

func _goga_setup() -> void:
        _rng.randomize()
        pause_end_run = true    # THE PONG LAW: the pause END banks
        _fresh_poss()
        var vp := get_viewport_rect().size
        world = Node2D.new()
        add_child(world)
        bg_l = Node2D.new()
        bg_l.z_index = -10
        bg_l.draw.connect(_draw_bg)
        world.add_child(bg_l)
        board_l = Node2D.new()
        board_l.draw.connect(_draw_board)
        world.add_child(board_l)
        token_l = Node2D.new()
        token_l.draw.connect(_draw_tokens)
        world.add_child(token_l)
        fx_l = Node2D.new()
        fx_l.z_index = 5
        fx_l.draw.connect(_draw_fx)
        world.add_child(fx_l)
        _layout(vp)
        _build_widgets(vp)
        add_hud_button("SHOP", func(): _shop_open())
        Jukebox.music("res://assets/audio/music/snl_theme.ogg")
        ## THE FLOW LAW (the owner: "it should be the opposite") - the
        ## optionals ask opens the game FIRST, the TAP ANYWHERE gate
        ## seats after the pick. v042: a LAN boot wears the system waiting
        ## room instead (the seats arrive from the session, never a sheet).
        if lan_hold:
                lan_hold_begin()
        else:
                _mode_sheet()

func _fresh_poss() -> void:
        poss = [0, 0, 0, 0]
        walk = {}
        ride = {}
        token_off = {}
        roll = 0
        coin_cell = -1
        play_clock = 0.0
        _hop_played = 0
        die_alive = false
        die_fading = false
        die_t0 = -1.0

# ------------------------------------------------------- the look helpers

func _theme_id() -> String:
        var tid := Box.item_on(game_id, "theme")
        if not THEMES.has(tid):
                tid = "mountain"
        return tid

func _theme() -> Dictionary:
        return THEMES[_theme_id()]

## THE THEME-OWNERSHIP LAW: the equipped skin re-inks ONLY the user's
## token (player 1 - the box's own hand at this table)
func _skin_id() -> String:
        var sid := Box.item_on(game_id, "skin")
        if not SKINS.has(sid) or not Box.item_owned(game_id, "skin", sid):
                sid = "theme"
        return sid

func _token_col(p: int) -> Color:
        if p == 1:
                var sid := _skin_id()
                if sid != "theme":
                        return SKINS[sid]["col"]
        var th: Array = _theme()["armies"]
        return th[(p - 1) % 4]

func _token_ink(p: int) -> Color:
        if p == 1:
                var sid := _skin_id()
                if sid != "theme":
                        return SKINS[sid]["ink"]
        var col := _token_col(p)
        ## THE CONTRAST LAW (the B&W round): a dark token wears a PALE
        ## ring, a light token wears the deep one - the outline always
        ## reads
        return col.darkened(0.55) if col.v > 0.4 else col.lightened(0.78)

# ------------------------------------------------- the board's geometry

## the pixel point of a cell-number's center
func _cell_point(n: int) -> Vector2:
        return _cellf_point(Vector2(cell_grid(n)))

## the pixel point of a FLOAT grid coord (col, row from the bottom) -
## the one flip point for every path on the board
func _cellf_point(g: Vector2) -> Vector2:
        return board_origin + Vector2((g.x + 0.5) * cell,
                        (float(BOARD_N - 1) - g.y + 0.5) * cell)

## the waiting token's pad seat inside its tray
func _pad_point(p: int) -> Vector2:
        var tr := _tray_rect(p)
        return tr.position + Vector2(12.0 + cell * 0.30,
                        tr.size.y * 0.5)

## the token's true seat (board cell, or the waiting pad) + its stack
## slide (the stacking law: tokens on one cell step aside, animated)
func _token_point(p: int) -> Vector2:
        var pos := int(poss[p - 1])
        var at := _pad_point(p) if pos == 0 else _cell_point(pos)
        var key := "%d" % p
        if token_off.has(key):
                at += token_off[key]
        return at

## THE STACKING LAW: the tokens sharing one cell slide apart on a small
## ring, in player order - everyone stays visible
func _stack_target(p: int) -> Vector2:
        var pos := int(poss[p - 1])
        if pos <= 0 or pos == LAST:
                return Vector2.ZERO
        var mates := []
        for q in playing:
                if int(poss[int(q) - 1]) == pos:
                        mates.append(int(q))
        if mates.size() < 2:
                return Vector2.ZERO
        var idx := mates.find(p)
        var ang := TAU * float(idx) / float(mates.size()) - PI * 0.5
        return Vector2(cos(ang), sin(ang)) * cell * 0.16

# ------------------------------------------------------------- the layout

func _layout(vp: Vector2) -> void:
        var banner := banner_bottom()
        var top_y := 96.0
        var tray_h := 74.0
        var bot_y := vp.y - banner - 6.0
        ## THE SLAB SEAT LAW (the ludo round): the frame slab + its shadow
        ## reach past board_side - the bottom trays seat BELOW the
        ## overhang and the layout reserves the room for it
        const SLAB_SEAT := 62.0
        var avail := (bot_y - tray_h - SLAB_SEAT) \
                        - (top_y + tray_h + 14.0)
        ## THE SLAB SEAT LAW (horizontal half): the slab + shadow reach
        ## past board_side by 0.3 cell on EACH side - the side reserve
        ## keeps the frame whole on the narrowest portrait canvas
        board_side = minf((vp.x - 8.0) \
                        / (1.0 + 0.6 / float(BOARD_N)), avail)
        board_side = maxf(board_side, 220.0)
        cell = board_side / float(BOARD_N)
        var spare := avail - board_side
        board_origin = Vector2((vp.x - board_side) * 0.5,
                        top_y + tray_h + 14.0 + maxf(0.0, spare * 0.4))
        _rebuild_paths()
        _place_texts(vp)
        _repaint()

## the snake bodies: ONE truth for the draw AND the fall (the
## two-formula rule) - a deterministic zigzag through Catmull-Rom
## smoothing, in pixel space, rebuilt at every layout
func _rebuild_paths() -> void:
        _paths = {}
        for head in SNAKES:
                _paths[int(head)] = _snake_px(int(head),
                                int(SNAKES[head]))

func _snake_px(head: int, tail: int) -> PackedVector2Array:
        var h := Vector2(cell_grid(head))
        var t := Vector2(cell_grid(tail))
        var dist := absf(h.x - t.x) + absf(h.y - t.y)
        var segs := clampi(int(dist / 2.6) + 2, 3, 7)
        var dir := (t - h).normalized()
        if dir == Vector2.ZERO:
                dir = Vector2(0, -1)
        var perp := Vector2(-dir.y, dir.x)
        var ctrl := [h]
        for i in range(1, segs):
                var f := float(i) / float(segs)
                var base := h.lerp(t, f)
                ## the S of the body: alternating lateral swings, tapering
                ## toward the tail (a serpent, not a wire)
                var side := 1.0 if i % 2 == 1 else -1.0
                var amp := (0.55 + 0.35 * sin(f * PI)) * (1.0 - 0.35 * f)
                ctrl.append(base + perp * amp * side)
        ctrl.append(t)
        # the Catmull-Rom pass: 7 samples per span, the body's turns
        var pts := PackedVector2Array()
        for i in range(ctrl.size() - 1):
                var p0: Vector2 = ctrl[maxi(0, i - 1)]
                var p1: Vector2 = ctrl[i]
                var p2: Vector2 = ctrl[i + 1]
                var p3: Vector2 = ctrl[mini(ctrl.size() - 1, i + 2)]
                for k in 7:
                        pts.append(_cr(p0, p1, p2, p3,
                                        float(k) / 7.0))
        pts.append(t)
        var out := PackedVector2Array()
        for g in pts:
                out.append(_cellf_point(g))
        return out

func _cr(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2,
        t: float) -> Vector2:
        var t2 := t * t
        var t3 := t2 * t
        return 0.5 * ((2.0 * p1) + (-p0 + p2) * t
                        + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
                        + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)

func _place_texts(vp: Vector2) -> void:
        if verdict_lbl != null:
                verdict_lbl.position = Vector2(0, board_origin.y
                                + board_side * 0.5 - 60.0)
                verdict_lbl.custom_minimum_size = Vector2(vp.x, 56)

## the tray seats: 1 top-left, 2 top-right, 3 bottom-right, 4 bottom-left
## (the ludo table's own corners - the house law). THE WIDE BADGE (the
## owner's v0.3.9-13 round: "make it wider by let's say x2 so the dice
## to the pawn home distance has enough space to fit whatever without
## getting the overlaps") - the tray doubles its seat, the 0.48 cap
## keeps the top pair from ever touching.
func _tray_rect(p: int) -> Rect2:
        var tw := minf(420.0, board_side * 0.48)
        var th := 74.0
        var top_y := 96.0
        var banner := banner_bottom()
        var slab_ext := maxf(10.0, cell * 0.5) + 12.0
        var by := board_origin.y + board_side + slab_ext + 10.0
        match p:
                1:
                        return Rect2(board_origin.x, top_y, tw, th)
                2:
                        return Rect2(board_origin.x + board_side - tw,
                                        top_y, tw, th)
                3:
                        return Rect2(board_origin.x + board_side - tw,
                                        by, tw, th)
                4:
                        return Rect2(board_origin.x, by, tw, th)
        return Rect2(0, 0, 0, 0)

## the die window inside a tray - ALSO the roll button (the waiting die
## IS the button, the v0.3.9-11 law). THE FLICKER FIX (the owner's
## v0.3.9-13 round: the breathing ring was poking past the tray's rim
## and fighting the badge highlight) - a smaller die keeps its whole
## breathing seat INSIDE the tray.
func _die_rect(p: int) -> Rect2:
        var tr := _tray_rect(p)
        var s := minf(50.0, tr.size.y * 0.66)
        return Rect2(tr.position.x + tr.size.x - s - 12.0,
                        tr.position.y + (tr.size.y - s) * 0.5, s, s)

# --------------------------------------------------------- the widget row

func _build_widgets(vp: Vector2) -> void:
        # THE W-L CARDS (the squares/ludo law: this board cannot tie)
        goals_row = Control.new()
        goals_row.custom_minimum_size = Vector2(108.0 * 2.0 + 8.0, 64.0)
        goals_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
        goals_row.draw.connect(_draw_goal_cards.bind(goals_row))
        _hud_row.add_child(goals_row)
        var score_chip: Control = _score_label.get_parent().get_parent()
        # THE SEAT LAW: the cards seat BEFORE the score chip
        _hud_row.move_child(goals_row, score_chip.get_index())
        verdict_lbl = Arc.label("", 40, Color(1, 1, 1, 0.95))
        verdict_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        verdict_lbl.visible = false
        world.add_child(verdict_lbl)
        _place_texts(vp)

func _draw_goal_cards(c: Control) -> void:
        var cw := 108.0
        var ch := 46.0
        var gapw := 8.0
        var cols := [Color("58c470"), Color("e8574a")]
        var letters := ["W", "L"]
        var f := ThemeDB.fallback_font
        var mid_y := c.size.y * 0.5
        var x0 := c.size.x * 0.5
        for i in 2:
                var x: float = (cw + gapw) * (float(i) - 0.5) + x0
                var r := Rect2(x - cw * 0.5, mid_y - ch * 0.5, cw, ch)
                c.draw_rect(Rect2(r.position + Vector2(4, 4), r.size),
                                Color(0.09, 0.05, 0.02, 0.85))
                c.draw_rect(r, Color(1, 1, 1, 0.95))
                c.draw_rect(r, cols[i], false, 5.0)
                var num: int = [wins, losses][i]
                c.draw_string(f, Vector2(x - cw * 0.5 + 10.0,
                                mid_y + 15.0), letters[i],
                                HORIZONTAL_ALIGNMENT_LEFT, -1, 26, cols[i])
                c.draw_string(f, Vector2(x - cw * 0.5 + 36.0,
                                mid_y + 17.0), str(num),
                                HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Arc.INK)

func _refresh_widget() -> void:
        if goals_row != null:
                goals_row.queue_redraw()

# ------------------------------------------------------- the ready gate

func _build_ready() -> void:
        var vp := get_viewport_rect().size
        ready_ui = Control.new()
        ready_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
        ready_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _hud.add_child(ready_ui)
        _hud.move_child(ready_ui, 0)
        var l := Arc.label("TAP ANYWHERE TO START", 46, Color(1, 1, 1, 0.95))
        l.set_anchors_preset(Control.PRESET_TOP_WIDE)
        l.offset_top = vp.y * 0.40
        l.offset_bottom = vp.y * 0.40 + 76.0
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        ready_ui.add_child(l)
        var tw := l.create_tween().set_loops()
        tw.tween_property(l, "modulate:a", 0.55, 0.9) \
                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        tw.tween_property(l, "modulate:a", 1.0, 0.9) \
                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _gate_down() -> void:
        if ready_ui != null and is_instance_valid(ready_ui):
                ready_ui.queue_free()
                ready_ui = null

func _repaint() -> void:
        bg_l.queue_redraw()
        board_l.queue_redraw()
        token_l.queue_redraw()
        fx_l.queue_redraw()

# ============================================================ the drawing

## THE ROOM: wall above, floor below, one honest divider (the house room
## law - flat theme colors, primitives only)
func _draw_bg() -> void:
        var vp := get_viewport_rect().size
        var th := _theme()
        bg_l.draw_rect(Rect2(Vector2.ZERO, vp), th["room"])
        var fy := vp.y * 0.82
        bg_l.draw_rect(Rect2(0, fy, vp.x, vp.y - fy), th["floor"])
        bg_l.draw_rect(Rect2(0, fy - 3.0, vp.x, 3.0),
                        (th["floor"] as Color).lightened(0.12))

func _draw_rr(c: CanvasItem, r: Rect2, radius: float, col: Color,
        filled := true, width := -1.0) -> void:
        if radius <= 0.5:
                c.draw_rect(r, col, filled, width)
                return
        var rad := minf(radius, minf(r.size.x, r.size.y) * 0.5)
        var pts := PackedVector2Array()
        var corners := [
                Vector2(r.end.x - rad, r.position.y + rad),
                Vector2(r.end.x - rad, r.end.y - rad),
                Vector2(r.position.x + rad, r.end.y - rad),
                Vector2(r.position.x + rad, r.position.y + rad),
        ]
        for k in 4:
                var cc: Vector2 = corners[k]
                for a in range(0, 91, 15):
                        var ang := deg_to_rad(float(a)) \
                                        - PI * 0.5 + PI * 0.5 * float(k)
                        pts.append(cc + Vector2(cos(ang), sin(ang)) * rad)
        if filled:
                c.draw_colored_polygon(pts, col)
        else:
                pts.append(pts[0])
                c.draw_polyline(pts, col, width)

## THE BOARD: the slab (frame + shadow), the 1,2 checker, the numerals,
## the two special squares (the START mat + the crown cell), then the
## ladders and the snakes UNDER the tokens.
func _draw_board() -> void:
        var th := _theme()
        var br := Rect2(board_origin - Vector2(cell * 0.30, cell * 0.30),
                        Vector2(board_side + cell * 0.60,
                        board_side + cell * 0.60))
        # the slab: shadow, body, the inner face, the rim
        board_l.draw_rect(Rect2(br.position + Vector2(6, 8), br.size),
                        Color(0, 0, 0, 0.35))
        _draw_rr(board_l, br, 18.0, th["frame"])
        _draw_rr(board_l, br.grow(-6.0), 14.0, th["frame_dark"])
        var inner := Rect2(board_origin - Vector2(2, 2),
                        Vector2(board_side + 4, board_side + 4))
        _draw_rr(board_l, inner, 8.0, th["sq_line"])
        _draw_rr(board_l, inner.grow(-3.0), 7.0, th["sq_a"])
        # THE CHECKER (the owner's 1,2,1,2): cell-number parity paints
        # the two tones
        for n in range(1, LAST + 1):
                var g := cell_grid(n)
                var r := Rect2(board_origin + Vector2(float(g.x) * cell,
                                (float(BOARD_N - 1) - float(g.y)) * cell),
                                Vector2(cell, cell))
                var col: Color = th["sq_a"] if n % 2 == 1 else th["sq_b"]
                board_l.draw_rect(r.grow(-1.0), col)
        # THE CROWN STAR rides UNDER its numeral (the owner's v040-1
        # round: "draw the star under it so the number stay visible" -
        # the base pass writes the ONE 100 straight on the star)
        _draw_crown_star()
        # the numerals (every square wears its number, the classic board)
        var f := ThemeDB.fallback_font
        var num_sz := int(maxf(11.0, cell * 0.24))
        for n in range(1, LAST + 1):
                var g := cell_grid(n)
                var at := board_origin \
                                + Vector2((float(g.x) + 0.06) * cell,
                                (float(BOARD_N - 1) - float(g.y) + 0.86)
                                * cell)
                board_l.draw_string(f, at, str(n),
                                HORIZONTAL_ALIGNMENT_LEFT, -1, num_sz,
                                th["num_ink"])
        _draw_cell_specials()
        _draw_ladders()
        _draw_snakes()

## THE START MAT (cell 1) - and nothing else on it now: the owner's
## v040-1 round kills both the chevron arrow AND the overlayed 1 -
## ONE BIG numeral centered in the mat does both jobs at once.
func _draw_cell_specials() -> void:
        var th := _theme()
        var f := ThemeDB.fallback_font
        # THE START MAT (cell 1): a soft inset mat + ONE big centered 1
        var g1 := cell_grid(1)
        var c1 := _cell_point(1)
        var r1 := Rect2(board_origin + Vector2(float(g1.x) * cell + 5.0,
                        (float(BOARD_N - 1) - float(g1.y)) * cell + 5.0),
                        Vector2(cell - 10.0, cell - 10.0))
        _draw_rr(board_l, r1, 10.0, th["snake"].darkened(0.15))
        _draw_rr(board_l, r1.grow(-3.0), 8.0, th["snake"])
        board_l.draw_string(f, c1 + Vector2(-cell * 0.5, cell * 0.30),
                        str(1), HORIZONTAL_ALIGNMENT_CENTER, -1,
                        int(cell * 0.52), Color(1, 1, 1, 0.95))

## THE CROWN STAR (cell 100): one bold gold star with a deep outline,
## seated UNDER the checker's own numeral - it is drawn before the
## numerals pass so the in-square 100 stays readable on the gold (the
## owner's v040-1 catch: the number was written twice, once in the
## square and once over the star).
func _draw_crown_star() -> void:
        var c100 := _cell_point(LAST)
        var rad := cell * 0.36
        var star := PackedVector2Array()
        for k in 10:
                var ang := -PI * 0.5 + PI * float(k) / 5.0
                var rr := rad * (1.0 if k % 2 == 0 else 0.42)
                star.append(c100 + Vector2(cos(ang), sin(ang)) * rr)
        var outline := PackedVector2Array()
        for p in star:
                outline.append(c100 + (p - c100).normalized() \
                                * ((p - c100).length() + cell * 0.045))
        board_l.draw_colored_polygon(outline, Color("8a5a1e"))
        board_l.draw_colored_polygon(star, Color("ffd24a"))
        # the inner glint (a smaller star face, one shade up)
        var glint := PackedVector2Array()
        for k in 10:
                var ang := -PI * 0.5 + PI * float(k) / 5.0
                var rr := rad * (0.62 if k % 2 == 0 else 0.26)
                glint.append(c100 + Vector2(cos(ang), sin(ang)) * rr \
                                + Vector2(0, -cell * 0.02))
        board_l.draw_colored_polygon(glint, Color("ffe89a"))

## THE LADDERS: two honest rails + the rungs between them, straight
## lanes from base to top (the owner: "ladders should be....ladders").
## THE STAIR ROUND (v0.3.9-13: "ladders need to have extra stairs,
## currently they are not too much and they have too wide stairs") -
## the rails pinch in and the rungs come TWICE as often.
func _draw_ladders() -> void:
        var th := _theme()
        for base in LADDERS:
                var a := _cell_point(int(base))
                var b := _cell_point(int(LADDERS[base]))
                var dir := (b - a).normalized()
                var perp := Vector2(-dir.y, dir.x)
                var gap := cell * 0.10
                var rail_a := [a + perp * gap, b + perp * gap]
                var rail_b := [a - perp * gap, b - perp * gap]
                # the rails: shadow pass, body pass
                for rail in [rail_a, rail_b]:
                        board_l.draw_line(rail[0] + Vector2(2, 3),
                                        rail[1] + Vector2(2, 3),
                                        Color(0, 0, 0, 0.28),
                                        cell * 0.075)
                        board_l.draw_line(rail[0], rail[1],
                                        th["ladder"], cell * 0.075)
                        board_l.draw_line(rail[0], rail[1],
                                        th["ladder_dark"], cell * 0.018)
                # the rungs: every cell*0.30 along the lane (the extra
                # stairs - twice as many as before)
                var length := a.distance_to(b)
                var rungs := maxi(3, int(length / (cell * 0.30)))
                for k in range(rungs + 1):
                        var f := float(k) / float(rungs)
                        var p0 := a.lerp(b, f) + perp * gap
                        var p1 := a.lerp(b, f) - perp * gap
                        board_l.draw_line(p0, p1, th["ladder_dark"],
                                        cell * 0.042)
                # THE JUNGLE LEAVES (the owner's ask): the ladder grows
                # out of the canopy - a leaf pair at both ends
                if bool(th.get("leaves", false)):
                        for end in [a, b]:
                                var inward := -dir if end == a else dir
                                _draw_leaf(end + perp * (gap + cell * 0.10),
                                                (inward * 0.55 + perp * 0.45) \
                                                .normalized())
                                _draw_leaf(end - perp * (gap + cell * 0.10),
                                                (inward * 0.55 - perp * 0.45) \
                                                .normalized())

## one jungle leaf: a pointed teardrop with a stem line, angled along
## `dir` (the jungle theme's ladder dressing)
func _draw_leaf(at: Vector2, dir: Vector2) -> void:
        var green := Color("3f8f3f")
        var perp := Vector2(-dir.y, dir.x)
        var L := cell * 0.34
        var W := cell * 0.12
        board_l.draw_line(at - dir * cell * 0.05, at,
                        green.darkened(0.3), cell * 0.028)
        var pts := PackedVector2Array([
                at + dir * L,
                at + perp * W + dir * L * 0.28,
                at,
                at - perp * W + dir * L * 0.28,
        ])
        board_l.draw_colored_polygon(pts, green)
        board_l.draw_line(at, at + dir * L * 0.8,
                        green.darkened(0.3), cell * 0.016)

## THE SNAKES (the v0.3.9-13 redesign, the owner: "snake design and
## edges look bad, see the snake game, it may help you make a proper
## snake face and tail end and turns without being that ugly") - the
## body is STAMPED along the drawn path (overlapping discs, tapering
## head to tail): the turns round themselves, no seams, no jagged
## joints. An OUTLINE pass keeps the edges clean on any checker, the
## belly rides the same stamps, and the head wears the snake game's own
## face - the forward eyes with pupils, the forked tongue. The jungle's
## vine wears bright brown with dark body dots (the spots law).
func _draw_snakes() -> void:
        var th := _theme()
        var spots: bool = bool(th.get("spots", false))
        var spot_c: Color = th.get("snake_spot", Color("5f3a16"))
        var ink: Color = (th["snake"] as Color).darkened(0.45)
        for head in SNAKES:
                var pts: PackedVector2Array = _paths[int(head)]
                if pts.size() < 2:
                        continue
                var n := pts.size()
                # THE SMOOTH BODY (the owner's v040-1 round: "they are
                # circle by circle, they should be smooth one body") -
                # the path becomes ONE continuous ribbon: left and
                # right shores follow the spine, the width tapers
                # head -> tail, no stamped discs anywhere.
                var body := _ribbon(pts, cell * 0.26, cell * 0.05)
                var outline := _ribbon(pts, cell * 0.26 + cell * 0.030,
                                cell * 0.05 + cell * 0.030)
                var belly := _ribbon(pts, cell * 0.11, cell * 0.02)
                board_l.draw_colored_polygon(outline, ink)
                board_l.draw_colored_polygon(body, th["snake"])
                board_l.draw_colored_polygon(belly, th["snake_belly"])
                # THE JUNGLE DOTS: dark spots riding the smooth body
                if spots:
                        for i in range(2, n - 1, 4):
                                var f3 := float(i) / float(n - 1)
                                board_l.draw_circle(pts[i],
                                                lerpf(cell * 0.06, cell * 0.012, f3),
                                                spot_c)
                # THE HEAD (the snake game's own face): a rimmed skull,
                # the eyes look ALONG the crawl, the tongue forks ahead
                var hp := pts[0]
                var hn := pts[mini(4, n - 1)]
                var hdir := (hp - hn).normalized()
                var perp := Vector2(-hdir.y, hdir.x)
                var hr := cell * 0.24
                board_l.draw_circle(hp + Vector2(2, 3), hr,
                                Color(0, 0, 0, 0.25))
                board_l.draw_circle(hp, hr + cell * 0.028, ink)
                board_l.draw_circle(hp, hr, th["snake"])
                for s: float in [-1.0, 1.0]:
                        var eye := hp + hdir * hr * 0.30 \
                                        + perp * s * hr * 0.50
                        board_l.draw_circle(eye, hr * 0.34,
                                        Color(1, 1, 1, 0.96))
                        board_l.draw_circle(eye + hdir * hr * 0.10,
                                        hr * 0.16, Color(0.05, 0.05, 0.05))
                # the tongue: base -> tip -> the two forks
                var tb := hp + hdir * hr * 0.85
                var tt := hp + hdir * hr * 1.7
                board_l.draw_line(tb, tt, Color("e8574a"), cell * 0.028)
                board_l.draw_line(tt, tt + (hdir * 0.45 + perp * 0.55) \
                                .normalized() * cell * 0.10,
                                Color("e8574a"), cell * 0.024)
                board_l.draw_line(tt, tt + (hdir * 0.45 - perp * 0.55) \
                                .normalized() * cell * 0.10,
                                Color("e8574a"), cell * 0.024)

## THE RIBBON: one polygon out of a point path - walk the spine twice,
## offset each point along its normal by the lerped width (head->tail
## taper; w0 at the head, w1 at the tail). center=true rides the spine
## as the polygon's axis so the belly stripe stays centered. The
## shores are smoothed with one Catmull-Rom subdivision pass first so
## the body bends round, not cornered.
func _ribbon(pts: PackedVector2Array, w0: float,
                w1: float) -> PackedVector2Array:
        # subdivide: every spine segment becomes 4 sub-points
        var spine := PackedVector2Array()
        for i in pts.size() - 1:
                var p0 := pts[maxi(i - 1, 0)]
                var p1 := pts[i]
                var p2 := pts[i + 1]
                var p3 := pts[mini(i + 2, pts.size() - 1)]
                for s in 4:
                        var t := float(s) / 4.0
                        spine.append(p1.bezier_interpolate(
                                p1 + (p2 - p0) * 0.25,
                                p2 + (p1 - p3) * 0.25, p2, t))
        spine.append(pts[pts.size() - 1])
        var m := spine.size()
        var left := PackedVector2Array()
        var right := PackedVector2Array()
        for i in m:
                var prev := spine[maxi(i - 1, 0)]
                var nxt := spine[mini(i + 1, m - 1)]
                var dir := (nxt - prev).normalized()
                if dir == Vector2.ZERO:
                        dir = Vector2(1, 0)
                var nrm := Vector2(-dir.y, dir.x)
                var f := float(i) / float(maxi(m - 1, 1))
                var w := lerpf(w0, w1, f)
                var c := spine[i]
                left.append(c + nrm * w)
                right.append(c - nrm * w)
        var poly := PackedVector2Array()
        # the shores zip into one polygon: left shore head->tail, then
        # the right shore back tail->head (same shape for the centered
        # belly stripe - the spine rides its middle either way)
        for i in m:
                poly.append(left[i])
        for i in range(m - 1, -1, -1):
                poly.append(right[i])
        return poly

## THE TOKENS: a pawn disc with its ring and a specular dot - the
## walkers and the riders drawn on top. THE BARE PAWN (the owner's
## v0.3.9-13 round: "remove the number that is written inside the pawn,
## will be better") - the tray's numeral is the mark, the pawn itself
## stays clean. THE WAITING TOKENS live in the fx pass (they sit INSIDE
## the trays - the tray paint would bury them here; the rig's film
## caught that).
func _draw_tokens() -> void:
        var walker_p := -1
        if state == "walking" and not walk.is_empty():
                walker_p = int(walk["player"])
        if state == "riding" and not ride.is_empty():
                walker_p = int(ride["player"])
        for p in playing:
                if int(p) == walker_p:
                        continue
                if int(poss[int(p) - 1]) == 0:
                        continue     # the waiting pad is the fx pass's
                _draw_token(token_l, _token_point(int(p)), int(p))
        if walker_p > 0:
                var at := _walk_point() if state == "walking" \
                                else _ride_point()
                _draw_token(token_l, at, walker_p, 1.07)

func _draw_token(c: CanvasItem, at: Vector2, p: int, scale := 1.0) \
                -> void:
        var col := _token_col(p)
        var ink := _token_ink(p)
        var r := cell * 0.30 * scale
        # the floor shadow + the disc + the contrast ring (the B&W law)
        c.draw_circle(at + Vector2(2, 4), r, Color(0, 0, 0, 0.28))
        c.draw_circle(at, r, col)
        c.draw_circle(at, r, ink, false, cell * 0.045)
        # the specular dot (the token is a polished pawn)
        c.draw_circle(at + Vector2(-r * 0.32, -r * 0.34),
                        r * 0.20, Color(1, 1, 1, 0.5))

func _walk_point() -> Vector2:
        var pts: PackedVector2Array = walk["pts"]
        var n := pts.size()
        if n <= 1:
                return pts[0] if n == 1 else Vector2.ZERO
        var k := clampf((_time - float(walk["t0"])) / HOP_T, 0.0,
                        float(n - 1))
        var i := int(k)
        if i >= n - 1:
                return pts[n - 1]
        var f2 := k - float(i)
        var at: Vector2 = pts[i].lerp(pts[i + 1], f2)
        # the hop's arc: a little up, over, drop (the owner's own walk);
        # the FIRST hop from the waiting pad lifts higher (the drop-in)
        var lift := cell * 0.22
        if i == 0 and int(poss[int(walk["player"]) - 1]) == 0:
                lift = cell * 0.55
        at.y -= sin(f2 * PI) * lift
        return at

func _ride_point() -> Vector2:
        var pts: PackedVector2Array = ride["pts"]
        var n := pts.size()
        if n <= 1:
                return pts[0] if n == 1 else Vector2.ZERO
        var k := clampf((_time - float(ride["t0"])) / float(ride["dur"]),
                        0.0, 1.0)
        var fk := k * float(n - 1)
        var i := int(fk)
        if i >= n - 1:
                return pts[n - 1]
        return pts[i].lerp(pts[i + 1], fk - float(i))

# ------------------------------------------------- the trays + the fx

## THE DICE THEATER: the tray wears its numeral, its glow when the turn
## is there, the die's pad, the waiting token, and the die itself (the
## theater: fade in, shuffle, settle - then fade out when done). THE
## WAITING DIE: grayed out at its pad, breathing - the user taps IT.
func _draw_trays() -> void:
        var f := ThemeDB.fallback_font
        var tink: Color = _theme()["tray_ink"]
        for p in playing:
                var tr := _tray_rect(int(p))
                var active: bool = int(p) == turn \
                                and state != "round_over"
                var col := _token_col(int(p))
                var fill: Color = (col as Color).darkened(0.42) \
                                if not active \
                                else (col as Color).darkened(0.18)
                fx_l.draw_rect(Rect2(tr.position + Vector2(4, 5), tr.size),
                                Color(0, 0, 0, 0.30))
                _draw_rr(fx_l, tr, 12.0, fill)
                _draw_rr(fx_l, tr.grow(-1), 11.0, tink, false, 2.0)
                ## THE ADAPTIVE TRAY INK: white words on a light tray are
                ## invisible - the ink follows the fill
                var word: Color = Color(0.07, 0.07, 0.08, 0.95) \
                                if (fill as Color).v > 0.5 \
                                else Color(1, 1, 1, 0.95)
                var word_soft: Color = Color(0.07, 0.07, 0.08, 0.75) \
                                if (fill as Color).v > 0.5 \
                                else Color(1, 1, 1, 0.75)
                if active:
                        var pulse := 0.5 + 0.5 * sin(_time * 5.0)
                        _draw_rr(fx_l, tr.grow(2.0), 13.0,
                                        Color(1, 1, 1, 0.10 + 0.10 * pulse))
                # the token pad (a soft inset plate - the waiting token
                # rests somewhere)
                var pad := Rect2(tr.position + Vector2(8.0, 8.0),
                                Vector2(cell * 0.60, tr.size.y - 16.0))
                _draw_rr(fx_l, pad, 10.0, Color(0, 0, 0, 0.22))
                _draw_rr(fx_l, pad, 10.0, Color(1, 1, 1, 0.14), false, 1.6)
                # the die pad
                var dr := _die_rect(int(p))
                _draw_rr(fx_l, dr.grow(7.0), 12.0, Color(0, 0, 0, 0.22))
                _draw_rr(fx_l, dr.grow(7.0), 12.0,
                                Color(1, 1, 1, 0.14), false, 1.6)
                # THE WAITING DIE: grayed out at its seat, breathing -
                # the user taps IT to roll (the breath stays INSIDE the
                # tray now - the flicker fix)
                if active and int(p) == 1 and state == "roll_wait" \
                                and not die_alive:
                        var breath := 0.5 + 0.5 * sin(_time * 3.4)
                        var ring: Color = Color(1, 1, 1, 0.26 + 0.24 * breath) \
                                        if (fill as Color).v <= 0.5 \
                                        else Color(0.1, 0.1, 0.1,
                                        0.3 + 0.25 * breath)
                        _draw_rr(fx_l, dr.grow(7.0 + 2.5 * breath), 11.0,
                                        ring, false, 2.6)
                        _draw_waiting_die(dr)
                # THE MARK: the bare numeral + WHO (the ludo tray law),
                # seated in the badge's middle air (the wide-badge round:
                # the die and the pawn home keep their distance)
                var who := "YOU" if int(p) == 1 else (_lan_name(int(p)).to_upper() if lan_active else "CPU")
                fx_l.draw_string(f, tr.position + Vector2(
                                12.0 + cell * 0.60 + 22.0,
                                tr.size.y * 0.52), str(p),
                                HORIZONTAL_ALIGNMENT_LEFT, -1, 34, word)
                fx_l.draw_string(f, tr.position + Vector2(
                                12.0 + cell * 0.60 + 52.0,
                                tr.size.y * 0.40), who,
                                HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
                                word_soft)
        # the die itself (the theater)
        if die_alive:
                _draw_die()

## the grayed die at rest - an honest EMPTY face (no pips: no face has
## settled yet), sitting quietly at its pad
func _draw_waiting_die(dr: Rect2) -> void:
        var style: String = _theme()["style"]
        var radius := dr.size.x * 0.2
        if style == "mono":
                radius = 0.0
        _draw_rr(fx_l, Rect2(dr.position + Vector2(2, 4), dr.size),
                        radius, Color(0, 0, 0, 0.30))
        _draw_rr(fx_l, dr, radius, Color(0.86, 0.86, 0.86, 0.94))
        _draw_rr(fx_l, dr, radius, Color(0.30, 0.30, 0.30, 0.85),
                        false, 2.0)

func _draw_die() -> void:
        var ds := minf(cell * 0.62, 58.0)
        var r := Rect2(die_pos - Vector2(ds * 0.5, ds * 0.5),
                        Vector2(ds, ds))
        var style: String = _theme()["style"]
        var radius := r.size.x * 0.2
        if style == "mono":
                radius = 0.0
        var age := _time - die_t0
        var alpha := 1.0
        if die_fading:
                alpha = clampf(1.0 - age / FADE_T, 0.0, 1.0)
        elif age < FADE_T:
                alpha = clampf(age / FADE_T, 0.0, 1.0)
        var ink := Color(0.12, 0.10, 0.08)
        var face := Color(1, 1, 1)
        if style == "neon":
                face = Color("eef6ff")
        # the shuffle: the die jitters, the face flickers
        var jitter := Vector2.ZERO
        if not die_fading and age < FADE_T + SHUF_T:
                var j := (age / SHUF_T) * 26.0
                jitter = Vector2(sin(_time * 41.0) * 2.2,
                                cos(_time * 37.0) * 2.2)
                var flick := 1 + (int(j) % 6)
                if age < FADE_T + SHUF_T - SETTLE_T:
                        _draw_die_face(r, jitter, flick, face, ink,
                                        radius, alpha)
                        return
        _draw_die_face(r, jitter, die_face, face, ink, radius, alpha)

func _draw_die_face(r: Rect2, jitter: Vector2, face_n: int,
        face: Color, ink: Color, radius: float, alpha: float) -> void:
        var rr := Rect2(r.position + jitter, r.size)
        _draw_rr(fx_l, rr.grow(2.0), radius + 2.0, Color(0, 0, 0, 0.35 * alpha))
        _draw_rr(fx_l, rr, radius, Color(face, alpha))
        var pr := r.size.x * 0.085
        var seats: Array = PIPS[clampi(face_n, 1, 6)]
        for seat in seats:
                var c := rr.position + Vector2(float(seat[0]) * rr.size.x,
                                float(seat[1]) * rr.size.y)
                fx_l.draw_circle(c, pr, Color(ink, alpha))

func _draw_fx() -> void:
        _draw_trays()
        # THE WAITING TOKENS: seated on their tray pads, ABOVE the tray
        # paint (the token layer sits under the trays by design)
        var walker_p2 := -1
        if state == "walking" and not walk.is_empty():
                walker_p2 = int(walk["player"])
        if state == "riding" and not ride.is_empty():
                walker_p2 = int(ride["player"])
        for p in playing:
                if int(poss[int(p) - 1]) == 0 and int(p) != walker_p2:
                        _draw_token(fx_l, _token_point(int(p)), int(p),
                                        0.9)
        # the coin (the xo coin law, seated ON its cell)
        if coin_cell >= 0:
                var tex: Texture2D = load("res://assets/ui/coin.png")
                if tex != null:
                        var pos := _cell_point(coin_cell)
                        pos.y += sin(coin_t * 3.2) * cell * 0.07
                        var fade: float = clampf(coin_t / 0.4, 0.0, 1.0)
                        var s: float = cell * 0.56 / float(tex.get_width())
                        var pop: float = 1.0 + 0.07 * sin(coin_t * 4.4)
                        fx_l.draw_set_transform(pos, 0.0,
                                        Vector2(s * pop * fade,
                                        s / maxf(0.05, pop) * fade))
                        fx_l.draw_texture(tex,
                                        -Vector2(tex.get_width(),
                                        tex.get_height()) / 2.0,
                                        Color(1, 1, 1, fade))
                        fx_l.draw_set_transform(Vector2.ZERO, 0.0,
                                        Vector2.ONE)
                        var ga: float = coin_t * 2.6
                        fx_l.draw_arc(pos, cell * 0.44, ga, ga + 1.1, 30,
                                        Color(1, 1, 1, 0.5 * fade), 2.2)
        # the dust (the squares law)
        for p in _dust:
                var a: float = clampf(float(p["life"]) / float(p["max"]),
                                0.0, 1.0)
                var c: Color = p["col"]
                c.a = a * 0.85
                fx_l.draw_rect(Rect2(float(p["x"]) - float(p["s"]) * 0.5,
                                float(p["y"]) - float(p["s"]) * 0.5,
                                float(p["s"]), float(p["s"])), c)

func _dust_burst(at: Vector2, col: Color, cnt := 6) -> void:
        for i in cnt:
                _dust.append({
                        "x": at.x + _rng.randf_range(-cell * 0.2,
                                        cell * 0.2),
                        "y": at.y + _rng.randf_range(-cell * 0.1,
                                        cell * 0.12),
                        "vx": _rng.randf_range(-90.0, 90.0),
                        "vy": _rng.randf_range(-140.0, -30.0),
                        "life": _rng.randf_range(0.3, 0.6),
                        "max": 0.6,
                        "s": _rng.randf_range(2.0, 4.5),
                        "col": col,
                })
        if _dust.size() > 120:
                _dust = _dust.slice(_dust.size() - 120)

# ============================================================ the input

# the double-delivery shield (see _goga_input)
var _tap_msec := -100000
var _tap_at := Vector2(-9999, -9999)

func _goga_input(event: InputEvent) -> void:
        if sheet_open_count() > 0:
                return
        var at := Vector2.ZERO
        var pressed := false
        if event is InputEventScreenTouch:
                var t := event as InputEventScreenTouch
                at = t.position
                pressed = t.pressed
        elif event is InputEventMouseButton:
                var mb := event as InputEventMouseButton
                at = mb.position
                pressed = mb.pressed
        else:
                return
        if not pressed:
                return
        ## THE DOUBLE-DELIVERY SHIELD (the ludo round's law): the engine
        ## walks ONE physical tap as a synthesized touch AND the original
        ## mouse - one tap per spot per heartbeat wins.
        var now := Time.get_ticks_msec()
        if now - _tap_msec < 80 and _tap_at.distance_to(at) < 14.0:
                return
        _tap_msec = now
        _tap_at = at
        ## THE FLOW LAW (the owner's v0.3.9-13 round: "you showed first
        ## the 'tap anywhere' then showed the optionals, it should be
        ## the opposite") - the ask opens the game, the pick seats the
        ## TAP ANYWHERE gate, the gate's tap opens the round
        if state == "ready":
                _gate_down()
                _mode_sheet()
                return
        if state == "gate":
                _gate_down()
                _new_round()
                return
        _tap(at)

## THE TAP: the waiting die is the only seat (one token per player - no
## picking, the die does the deciding)
func _tap(at: Vector2) -> void:
        # v042-1 COMBO: the die answers for ANY of this device's seats
        var my_turn := turn == 1 if not lan_active \
                        else _lan_my_turns().has(turn)
        if state == "roll_wait" and my_turn and not die_alive:
                if _die_rect(turn).grow(14.0).has_point(at):
                        _do_roll()
                        return

# ------------------------------------------------------- the mode sheet

func _mode_sheet() -> void:
        ## THE HOUSE OPTIONALS LAW (law 28, the v0.3.9-13 correction:
        ## the ask wears ONE short title - "do not write too helpful AI
        ## slop things" never meant "do not write anything") - the
        ## owner's own example words, then the three equal cards, ONE
        ## color, one tap seats the gate
        var sheet := sheet_push(0.0, "mode")
        var t := Arc.label("HOW MANY PLAYERS", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 14)
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        sheet.add_child(row)
        for m in [[2, "2"], [3, "3"], [4, "4"]]:
                var mode_v: int = m[0]
                row.add_child(Arc.button(String(m[1]), Vector2(164, 92),
                                30, Arc.ACCENT, func(): _pick_mode(mode_v)))
        # THE CONFIRM-SHEET LAW: plain sheet buttons keep their default
        # mouse filter (an IGNORE filter makes the cards DEAD to taps)

# ============================================================ v042 THE LAN SEAT
## The waiting room owns the boot; the seats arrive in arrival order. On
## EVERY device the local player wears id 1 and the rivals wear 2..N (the
## display laws keep working); the turn order is the session's seat order
## rotated so seat 1's device and seat 3's device agree on WHO acts while
## each device labels its own token YOU. Moves ride TURN_RELAY: the roller
## applies + broadcasts, receivers apply through the same door.

func lan_match_start(seed_v: int, m_seats: Array) -> void:
        lan_active = true
        _rng.seed = seed_v
        players = m_seats.size()
        playing = []
        for i in players:
                playing.append(i + 1)
        opener = 1
        rounds = 0
        _new_round()

func lan_solo() -> void:
        lan_active = false
        _mode_sheet()

func _lan_name(p: int) -> String:
        if lan_seats.is_empty():
                return "RIVAL"
        var n: int = lan_seats.size()
        var idx: int = (LAN.my_seat_no() - 1 + p - 1) % n
        return String(lan_seats[idx].get("name", "RIVAL"))

## THE ROTATION MAPS (v042-1): the local turn p rides the session seat
## (my_seat_no + p - 1) on the n-seat circle - and the inverse for an
## arriving act. The gates below keep every device's state machine in the
## SAME absolute sequence no matter which seat it wears.
func _lan_seat_of_turn(p: int) -> int:
        var n: int = maxi(1, lan_seats.size())
        return posmod(LAN.my_seat_no() - 1 + p - 1, n) + 1

func _lan_local_turn(who: int) -> int:
        var n: int = maxi(1, lan_seats.size())
        return posmod(who - LAN.my_seat_no(), n) + 1

## this device's LOCAL turn indices (the combo seat owns two)
func _lan_my_turns() -> Array:
        var out := []
        var n: int = maxi(1, lan_seats.size())
        var mine := [LAN.my_dev(), LAN.my_dev() + LAN.COMBO_DEV]
        for p in n:
                var seat: Dictionary = lan_seats[_lan_seat_of_turn(p + 1) - 1] \
                                if lan_seats.size() >= _lan_seat_of_turn(p + 1) \
                                else {}
                if String(seat.get("dev", "")) in mine:
                        out.append(p + 1)
        return out

func lan_act(who: int, a: Dictionary) -> void:
        match String(a.get("k", "")):
                "roll":
                        # THE WHO GATE (v042-1): the roll lands only when it
                        # is THAT seat's turn here - the rotated sequences
                        # align, a stranger never steals a turn
                        if state == "roll_wait" \
                                        and turn == _lan_local_turn(who):
                                _apply_roll(int(a.get("r", 1)))

func _pick_mode(m: int) -> void:
        players = m
        playing = []
        for p in m:
                playing.append(p + 1)
        # the pick seats the TAP ANYWHERE gate (the flow law) - the
        # round opens on the gate's tap, not on the pick
        state = "gate"
        clock = -1.0
        sheet_pop()
        _build_ready()

func _goga_sheet_popped(id: String) -> void:
        if id == "shop":
                shop_id = ""
                get_tree().paused = false
                paused = false
                _repaint()
                if state in ["ready", "gate"] and ready_ui != null \
                                and is_instance_valid(ready_ui):
                        ready_ui.visible = true
        elif id == "mode" and state == "ready":
                # the back button closed the mode ask - the gate returns
                # so its tap re-opens the ask (the flow law)
                _build_ready()

# ============================================================ the rounds

func _new_round() -> void:
        _fresh_poss()
        rounds += 1
        verdict_lbl.visible = false
        # THE OPENER LAW: round 1 is the user's; after that the LOSER
        # opens (no draws on this board)
        turn = opener
        clock = 0.0
        _start_turn()
        _banner()
        _repaint()
        _refresh_widget()

## the turn opens: the waiting die wakes at the turn player's tray (the
## house theater) - or the CPU breathes and rolls by itself
func _start_turn() -> void:
        state = "roll_wait"
        roll = 0
        die_alive = false
        die_fading = false
        die_t0 = -1.0
        clock = 0.0
        _banner()

func _banner() -> void:
        ## THE QUIET TRAY (the owner's v0.3.9-13 round: "keeping it same
        ## size but removing the text and keeping just the highlight on
        ## it while it is it's turn will be cooler fix") - the tray
        ## speaks through its highlight alone; no THINKING words, no
        ## dots (guide 29: the state lives in the die and the glow)
        turn_note = ""

# ============================================================ the theater

func _do_roll() -> void:
        roll = _rng.randi_range(1, 6)
        if lan_active:
                # the roll rides THE TURN'S OWN seat (the combo seat's roll
                # carries its own number, not the primary's)
                LAN.send_act_as(_lan_seat_of_turn(turn), {"k": "roll", "r": roll})
        _apply_roll(roll)

## The ONE roll body (the local roll and the relayed roll land identically).
func _apply_roll(r: int) -> void:
        roll = r
        die_face = r
        die_alive = true
        die_fading = false
        die_t0 = _time
        var dr := _die_rect(turn)
        die_pos = dr.get_center()
        state = "rolling"
        clock = 0.0
        Jukebox.sfx("snl_roll", -6.0)
        _banner()

## the settle: the face is the truth - the walk wakes, or the overshoot
## refuses the move and the turn skips (THE EXACT LANDING LAW)
func _after_roll() -> void:
        var np := legal_to(int(poss[turn - 1]), roll)
        if np < 0:
                Jukebox.sfx("snl_denied", -8.0)
                _die_fade()
                state = "handoff"    # the refused beat, then the rival
                clock = -0.45
                _banner()
                return
        _start_walk(turn, np)

## THE DIE FADES OUT once done, the seat empties for the next turn
func _die_fade() -> void:
        if die_alive and not die_fading:
                die_fading = true
                die_t0 = _time

# ============================================================ the walk

func _start_walk(player: int, np: int) -> void:
        var from := int(poss[player - 1])
        var pts := PackedVector2Array()
        var cells := []
        pts.append(_pad_point(player) if from == 0 \
                        else _cell_point(from))
        for k in range(from + 1, np + 1):
                pts.append(_cell_point(k))
                cells.append(k)
        # the coin's seat on the walk (stepping ON it takes it - the
        # owner's law for this board)
        var coin_at := -1
        for i in cells.size():
                if int(cells[i]) == coin_cell:
                        coin_at = i + 1     # the hop index that lands it
                        break
        walk = {"player": player, "pts": pts, "cells": cells,
                "t0": _time, "np": np, "coin_at": coin_at,
                "coin_done": coin_at < 0}
        _hop_played = 0
        state = "walking"
        _banner()

func _finish_walk() -> void:
        var p := int(walk["player"])
        var np := int(walk["np"])
        var landed_at := _cell_point(np)
        poss[p - 1] = np
        walk = {}
        token_l.queue_redraw()
        # THE RESOLVE: a ladder lifts, a snake swallows, the crown ends
        var res := resolve_land(np)
        if np == LAST:
                _resolve(p)
                return
        if String(res["ride"]) != "":
                _start_ride(p, np, String(res["ride"]), int(res["to"]))
                return
        _die_fade()
        state = "handoff"
        clock = -0.35

# ============================================================ the ride
## "getting up a ladder makes the figure slides in straight lanes while
## snake make the figure fall the same way the snake body is" - the
## ladder's lane is the straight line between the rails; the snake's
## fall follows the drawn body, turn by turn (ONE truth with the draw).

func _start_ride(player: int, from: int, kind: String, to: int) -> void:
        var pts := PackedVector2Array()
        var dur := 0.0
        if kind == "ladder":
                pts.append(_cell_point(from))
                pts.append(_cell_point(to))
                var length := pts[0].distance_to(pts[1])
                dur = length / (CLIMB_CPS * cell)
                Jukebox.sfx("snl_climb", -5.0)
                _dust_burst(pts[0], _token_col(player), 8)
        else:
                pts = _paths[int(from)]
                var length := 0.0
                for i in range(pts.size() - 1):
                        length += pts[i].distance_to(pts[i + 1])
                dur = length / (FALL_CPS * cell)
                Jukebox.sfx("snl_fall", -5.0)
                _dust_burst(pts[0], _token_col(player), 10)
        ride = {"player": player, "pts": pts,
                "t0": _time + RIDE_BEAT, "beat_t0": _time,
                "dur": maxf(0.4, dur), "kind": kind, "to": to}
        state = "riding"
        _banner()

func _finish_ride() -> void:
        var p := int(ride["player"])
        var to := int(ride["to"])
        poss[p - 1] = to
        var at := _cell_point(to)
        _dust_burst(at, _token_col(p), 10)
        if String(ride["kind"]) == "ladder":
                if p == 1:
                        achievement_count("climbs", 1)
        else:
                if p == 1:
                        achievement_count("falls", 1)
        ride = {}
        token_l.queue_redraw()
        if to == LAST:
                _resolve(p)
                return
        _die_fade()
        state = "handoff"
        clock = -0.35

# ============================================================ the turns

func _next_turn() -> void:
        var idx := playing.find(turn)
        turn = int(playing[(idx + 1) % playing.size()])
        _start_turn()

# ============================================================ the verdict

func _resolve(winner: int) -> void:
        state = "round_over"
        clock = 0.0
        _die_fade()
        var w := 1 if winner == 1 else 2
        if w == 1:
                wins += 1
                streak += 1
                add_score(1)                     # THE OWNER'S LAW: win = +1
                verdict_lbl.text = "YOU REACH THE SUMMIT  +1"
                verdict_lbl.add_theme_color_override("font_color",
                                Color("7ee2a0"))
                Jukebox.sfx("snl_win", -3.0)
                achievement_count("wins", 1)
                achievement_max("streak", streak)
                var mid := board_origin + Vector2(board_side * 0.5,
                                board_side * 0.5)
                Arc.confetti(_overlay_root_ref(), mid, 34)
        else:
                losses += 1
                streak = 0
                if score > 0:
                        add_score(-1)            # never under zero
                verdict_lbl.text = "A RIVAL CLIMBS FIRST  -1"
                verdict_lbl.add_theme_color_override("font_color",
                                Color("f2a09a"))
                Jukebox.sfx("snl_lose", -3.0)
        # THE OPENER LAW: the loser opens the next round. At the 1v1
        # table that is exactly the rival; at the bigger tables the next
        # player after the winner takes the seat (the one beaten first).
        if w == 1:
                var idx := playing.find(1)
                opener = int(playing[(idx + 1) % playing.size()])
        else:
                opener = 1
        achievement_max("max_score", score)
        _refresh_widget()
        verdict_lbl.visible = true
        ## THE SMOOTH VERDICT: the line rises in instead of snapping
        verdict_lbl.modulate.a = 0.0
        var tw := verdict_lbl.create_tween().set_parallel(true)
        tw.tween_property(verdict_lbl, "modulate:a", 1.0, 0.38) \
                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
        turn_note = ""       # the tray goes quiet (the verdict speaks)
        check_achievements()

# ============================================================ the coin

func _occupied_cells() -> Array:
        var out := []
        for p in playing:
                var pos := int(poss[int(p) - 1])
                if pos > 0:
                        out.append(pos)
        return out

func _coin_maybe_spawn() -> void:
        if coin_cell >= 0 or play_clock < COIN_EVERY:
                return
        var spots := coin_spots(int(poss[0]), _occupied_cells())
        if spots.is_empty():
                play_clock = COIN_EVERY   # try again next tick
                return
        if lan_active:
                coin_cell = spots[_coin_rot % spots.size()]
                _coin_rot += 1
        else:
                coin_cell = spots[_rng.randi() % spots.size()]
        coin_t = 0.0
        game_toast("A GOGACOIN SHINES ON THE BOARD")

func _coin_taken(player: int) -> void:
        var at := _cell_point(coin_cell)
        coin_cell = -1
        play_clock = 0.0
        if player == 1:
                add_run_coins(1)
                achievement_count("coins", 1)
                Jukebox.sfx("snl_coin", -3.0)
                game_toast("YOU TOOK THE GOGACOIN  +1")
                _dust_burst(at, Color("ffd24a"), 12)
        else:
                Jukebox.sfx("snl_coin", -6.0, 0.8)
                game_toast("%s GRABBED THE COIN" % (_lan_name(player).to_upper() if lan_active else "A CPU"))

# ============================================================ the tick

func _goga_tick(delta: float) -> void:
        _time += delta
        coin_t += delta
        clock += delta
        _banner()            # the tray note breathes (the thinking dots)
        # THE COIN CLOCK: live play only, one coin every 5 in-game minutes
        if state in ["roll_wait", "rolling", "walking", "riding"]:
                play_clock += delta
        _coin_maybe_spawn()
        # the die's fade-out lives ABOVE the states - it dies wherever it
        # is, and the seat empties for whoever's turn comes next
        if die_fading and _time - die_t0 >= FADE_T:
                die_alive = false
                die_fading = false
        match state:
                "rolling":
                        var total := FADE_T + SHUF_T
                        if clock >= total and not die_fading:
                                _after_roll()
                "roll_wait":
                        if clock >= CPU_THINK and turn != 1 \
                                        and not die_alive and not lan_active:
                                _do_roll()
                "handoff":
                        if clock >= 0.0 and not die_alive:
                                _next_turn()
                "walking":
                        if not walk.is_empty():
                                var pts_n: int = (walk["pts"] as \
                                                PackedVector2Array).size()
                                var walked := (_time - float(walk["t0"])) \
                                                / HOP_T
                                var hop := int(walked)
                                # the walk sings: a tick per hop, the
                                # pitch rising along the move
                                while _hop_played < hop \
                                                and _hop_played < pts_n - 1:
                                        _hop_played += 1
                                        Jukebox.sfx("snl_hop", -9.0,
                                                        0.9 + 0.055
                                                        * float(_hop_played))
                                # the coin's hop: stepping on it takes it
                                if not bool(walk["coin_done"]) \
                                                and hop >= int(walk["coin_at"]):
                                        walk["coin_done"] = true
                                        _coin_taken(int(walk["player"]))
                                if walked >= float(pts_n - 1):
                                        _finish_walk()
                "riding":
                        if not ride.is_empty():
                                # the beat first: the token sits on the
                                # base/head and breathes (the ride's t0
                                # starts RIDE_BEAT late), THEN the ride
                                if _time - float(ride["t0"]) \
                                                        >= float(ride["dur"]):
                                                _finish_ride()
                "round_over":
                        if clock >= 2.6:
                                _new_round()
        # the stacking slide's glide (the tokens step aside, animated)
        if not token_off.is_empty():
                for p in playing:
                        var key := "%d" % int(p)
                        if not token_off.has(key):
                                token_off[key] = Vector2.ZERO
                        token_off[key] = (token_off[key] as Vector2) \
                                        .lerp(_stack_target(int(p)),
                                        minf(1.0, delta * 9.0))
        else:
                for p in playing:
                        token_off["%d" % int(p)] = Vector2.ZERO
        # the dust's life
        if not _dust.is_empty():
                var alive2 := []
                for p in _dust:
                        p["life"] = float(p["life"]) - delta
                        if float(p["life"]) <= 0.0:
                                continue
                        p["x"] = float(p["x"]) + float(p["vx"]) * delta
                        p["y"] = float(p["y"]) + float(p["vy"]) * delta
                        p["vy"] = float(p["vy"]) + 420.0 * delta
                        alive2.append(p)
                _dust = alive2
        # THE LIVING LAYER LAW: the animated layers repaint on the tick
        # (the BOARD is static art now - the crown star lost its rays,
        # so the board layer only repaints on layout/theme changes)
        token_l.queue_redraw()
        fx_l.queue_redraw()

# ============================================================ the shop
## TOKEN SKINS + THEMES (the shelf order law: "skins at the top and
## themes under them in all other games"). THE SHELF TRUTH LAWS from
## birth: short section names, no dash talk, the ON row keeps its seat.

var shop_id := ""

func _shop_open() -> void:
        if shop_id != "":
                return
        shop_id = "shop"
        if ready_ui != null and is_instance_valid(ready_ui):
                ready_ui.visible = false
        paused = true
        get_tree().paused = true
        var sheet := sheet_push(0.0, "shop")
        var t := Arc.label("SNAKES & LADDERS SHOP", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.52, 300.0,
                        640.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        # THE SHELF ORDER LAW: the skins seat first, the themes under.
        box.add_child(_shop_label("TOKEN SKINS"))
        for id in SKINS:
                box.add_child(_skin_row(id))
        box.add_child(_shop_label("THEMES"))
        for id in THEMES:
                box.add_child(_theme_row(id))
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                        func(): sheet_pop()))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _shop_label(txt: String) -> Label:
        return Arc.fit_label(txt, 24, Arc.HOT, 560)

func _price_btn(txt: String, price: int, col: Color, cb: Callable) \
                -> Button:
        var b := Arc.coin_button("%s  %d" % [txt, price], Vector2(560, 64),
                22, col, cb)
        if Box.coins() < price:
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
                ## THE ON ROW LAW: the equipped row keeps its full seat
                ## and plainly says ON
                return Arc.on_row("%s  (ON)" % c["name"])
        if owned:
                return Arc.button(c["name"], Vector2(560, 64), 22,
                        Arc.ACCENT, func():
                                Box.equip_item(game_id, "theme", id)
                                Jukebox.sfx("confirm", -4.0)
                                _shop_reopen())
        return _price_btn(c["name"], int(c["price"]), Arc.ACCENT,
                        func():
                                if Box.buy_item(game_id, "theme", id,
                                                int(c["price"])):
                                        Jukebox.sfx("buy")
                                        Box.equip_item(game_id, "theme", id)
                                _shop_reopen())

func _skin_row(id: String) -> Control:
        var s: Dictionary = SKINS[id]
        var owned := Box.item_owned(game_id, "skin", id) \
                        or int(s["price"]) == 0
        var on: bool = _skin_id() == id
        if on:
                return Arc.on_row("%s  (ON)" % s["name"])
        if owned:
                return Arc.button(s["name"], Vector2(560, 64), 22,
                        Arc.ACCENT, func():
                                Box.equip_item(game_id, "skin", id)
                                Jukebox.sfx("confirm", -4.0)
                                _shop_reopen())
        return _price_btn(s["name"], int(s["price"]), Arc.ACCENT,
                        func():
                                if Box.buy_item(game_id, "skin", id,
                                                int(s["price"])):
                                        Jukebox.sfx("buy")
                                        Box.equip_item(game_id, "skin", id)
                                _shop_reopen())

func _shop_reopen() -> void:
        if shop_id != "":
                sheet_pop()
                _shop_open.call_deferred()

# ============================================================ the probe
## The headless contract: a fresh deterministic round any probe drives.

func probe_reset(players_v: int, seed_v: int) -> void:
        _rng.seed = seed_v
        _gate_down()
        players = players_v
        playing = []
        for p in players_v:
                playing.append(p + 1)
        opener = 1
        rounds = 0
        wins = 0
        losses = 0
        streak = 0
        _fresh_poss()
        paused = true
        _layout(get_viewport_rect().size)
        _new_round()

func probe_step(dt: float) -> void:
        _goga_tick(dt)

## THE DRAIN: run the machine until the player may act or the round ends
func probe_drain(max_ticks := 900) -> void:
        var k := 0
        while (state == "rolling" or state == "handoff"
                or state == "walking" or state == "riding"
                or (state == "roll_wait" and turn != 1)) \
                and k < max_ticks:
                _goga_tick(0.05)
                k += 1

## a probe rolls for the user (the waiting die's stand-in) - it waits
## out the fade like a human tapping the die when it returns
func probe_roll() -> void:
        if state == "roll_wait" and turn == 1:
                var k := 0
                while die_alive and k < 40:
                        _goga_tick(0.05)
                        k += 1
                if not die_alive:
                        _do_roll()

## a probe plays whole user turns until the round ends (the soak's
## driver: roll, walk, ride - everything the machine asks). If the
## table is still breathing its verdict beat, the beat is ticked
## through first - the drain never crosses round_over by design, so
## the fresh round is seated here, then played.
func probe_auto_round(max_turns := 400) -> bool:
        var t := 0
        while state == "round_over" and t < max_turns:
                probe_step(0.1)
                t += 1
        while state != "round_over" and t < max_turns:
                if state == "roll_wait" and turn == 1 and not die_alive:
                        probe_roll()
                        probe_drain(400)
                        t += 1
                else:
                        probe_drain(400)
                        t += 1
        return state == "round_over"
