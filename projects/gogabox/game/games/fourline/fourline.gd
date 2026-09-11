extends GogaGame
## FOUR IN LINE - v0.3.9, the drop classic graduates from the workshop
## (the owner's v039 GDD round: four in line + five in row are siblings,
## this one drops discs).
##
## Owner contract (v0.3.9):
##   - VERTICAL ONLY (the xo law: registry orientation portrait, no
##     position ask, no horizontal table), NO optionals menu - the SHOP
##     is the only extra HUD button
##   - the economy (the xo shape): win +1, loss -1 (score never
##     negative), draw 0; run bonus /3 (registry coin_div 3)
##   - a GOGACoin rests in a hole after every 4 completed rounds - the
##     disc that lands in that hole takes it (the CPU races you)
##   - the opener law: the player opens round 1, the LOSER of a round
##     opens the next, a draw flips the opener
##   - the W/D/L cards (the dominoes/chess widget) hug the score chip
##   - TAP ANYWHERE TO START - the chess gate, seated at HUD index 0
##     (under every sheet - the v0.3.8-8 gate law)
##   - pause_end_run: the pause sheet wears RESUME / END / QUIT (the
##     pong law); END banks the run
##   - the shop (5-5): 5 disc skins + 5 themes (frame + room), the
##     defaults owned, everything else bought (the price-display law:
##     coin buttons, gray when the wallet is dry)
##   - ONE opponent, FOUR moods (invisible rotation - "just keep it one
##     name: CPU"), the 2-round adaptive memory: repeat an opening and
##     the burned reply never repeats; programmed failures everywhere so
##     it is always beatable, but it punishes the same trick twice
##   - the board is 8x7 (the owner: "a mid-sized board that is big but
##     not huge and not a small size")
##
## Probe contract: the whole CPU core is STATIC - drop_row / winner_of /
## winning_cols / cpu_pick / remember / adapt drive headless laws
## without the scene (the xo contract).

const COLS := 8
const ROWS := 7
const COIN_EVERY := 4      # owner: one GOGACoin after each 4 rounds
const MEM_ROUNDS := 2      # the xo memory law

# ------------------------------------------------------------- the shop
## 5 disc skins (the first owned) + 5 themes (frame + room).
const SKINS := {
        "classic": {"name": "CLASSIC", "price": 0,
                "p1": Color("e8574a"), "p2": Color("ffc93c"),
                "desc": "red vs yellow - the toy box pair"},
        "bubble": {"name": "BUBBLE", "price": 150,
                "p1": Color("ff7eb6"), "p2": Color("7ae0c3"),
                "desc": "candy pink vs mint cream"},
        "ocean": {"name": "OCEAN", "price": 220,
                "p1": Color("38bdf8"), "p2": Color("fb7185"),
                "desc": "wave blue vs coral"},
        "neon": {"name": "NEON", "price": 300,
                "p1": Color("22d3ee"), "p2": Color("a3e635"),
                "desc": "the night hall glows"},
        "royal": {"name": "ROYAL", "price": 380,
                "p1": Color("fbbf24"), "p2": Color("a78bfa"),
                "desc": "gold vs amethyst"},
}
const THEMES := {
        "tavern": {"name": "TAVERN", "price": 0,
                "frame": Color("b58863"), "frame_dark": Color("6b4a2e"),
                "room": Color("2c1d10"), "hole": Color("170d05"),
                "floor": Color("22150a"), "trim": Color("e8c99a"),
                "desc": "the warm wood toy"},
        "sky": {"name": "SKY", "price": 220,
                "frame": Color("3b82f6"), "frame_dark": Color("1e40af"),
                "room": Color("18263d"), "hole": Color("0c1524"),
                "floor": Color("141d30"), "trim": Color("bfdbfe"),
                "desc": "the classic bright pair"},
        "ice": {"name": "ICE", "price": 280,
                "frame": Color("7dd3fc"), "frame_dark": Color("0369a1"),
                "room": Color("10233a"), "hole": Color("081422"),
                "floor": Color("0d1b2c"), "trim": Color("e0f2fe"),
                "desc": "the frozen pond"},
        "arcade": {"name": "ARCADE", "price": 340,
                "frame": Color("3b4657"), "frame_dark": Color("161c28"),
                "room": Color("0b1020"), "hole": Color("04060e"),
                "floor": Color("080c18"), "trim": Color("22d3ee"),
                "desc": "the machine hall"},
        "royal": {"name": "ROYAL", "price": 420,
                "frame": Color("7c3aed"), "frame_dark": Color("4c1d95"),
                "room": Color("1d1030"), "hole": Color("100a1c"),
                "floor": Color("160c26"), "trim": Color("fcd34d"),
                "desc": "the gilded court"},
}

# ------------------------------------------------------------- the profiles
## THE FOUR MOODS (the xo law: invisible rotation, one name). The knobs
## keep the balance law: strong blocks, small miss chances, a noise
## floor so the same board never plays the same twice.
##   miss_win   - the chance it fails to take an immediate win
##   skip_block - the chance it fails to block an immediate loss
##   avoid      - the chance it notices a move that hands the win back
##   fork_eye   - how eagerly it builds/breaks double threats
##   w_build/w_block/w_center - the feel
const PROFILES := {
        "wall": {
                "miss_win": 0.16, "skip_block": 0.11, "avoid": 0.85,
                "fork_eye": 0.7, "noise": 22.0,
                "w_build": 0.9, "w_block": 1.7, "w_center": 1.5,
        },
        "trick": {
                "miss_win": 0.14, "skip_block": 0.13, "avoid": 0.7,
                "fork_eye": 1.6, "noise": 30.0,
                "w_build": 1.5, "w_block": 1.1, "w_center": 1.2,
        },
        "rusher": {
                "miss_win": 0.12, "skip_block": 0.18, "avoid": 0.55,
                "fork_eye": 1.1, "noise": 36.0,
                "w_build": 1.9, "w_block": 0.8, "w_center": 1.3,
        },
        "sage": {
                "miss_win": 0.15, "skip_block": 0.14, "avoid": 0.8,
                "fork_eye": 1.2, "noise": 26.0,
                "w_build": 1.3, "w_block": 1.3, "w_center": 1.4,
        },
}
## the center love: middle columns read stronger (the real-game truth)
const CENTER_W := [0.7, 0.9, 1.1, 1.3, 1.3, 1.1, 0.9, 0.7]

# ============================================================ THE CPU CORE
## Static so tests (flow_test + the probes) drive the brain without the
## scene - the xo contract.

static func idx(c: int, r: int) -> int:
        return c * ROWS + r

static func drop_row(b: Array, c: int) -> int:
        ## the row a disc rests on when dropped into column c (-1 = full):
        ## GRAVITY SEATS AT THE BOTTOM - the lowest empty row first
        if c < 0 or c >= COLS:
                return -1
        for r in range(ROWS - 1, -1, -1):
                if int(b[idx(c, r)]) == 0:
                        return r
        return -1

static func winner_of(b: Array) -> int:
        ## 0 = none yet, 1 = player, 2 = CPU, 3 = board full (draw)
        for c in COLS:
                for r in ROWS:
                        var v: int = b[idx(c, r)]
                        if v == 0:
                                continue
                        for d in [[1, 0], [0, 1], [1, 1], [1, -1]]:
                                var c2 := c + int(d[0]) * 3
                                var r2 := r + int(d[1]) * 3
                                if c2 < 0 or c2 >= COLS or r2 < 0 or r2 >= ROWS:
                                        continue
                                var all := true
                                for k in 4:
                                        if int(b[idx(c + int(d[0]) * k,
                                                                r + int(d[1]) * k)]) != v:
                                                all = false
                                                break
                                if all:
                                        return v
        for i in b.size():
                if int(b[i]) == 0:
                        return 0
        return 3

## the winning four as cell indexes (empty when no win) - the strike law
static func win_line(b: Array) -> Array:
        for c in COLS:
                for r in ROWS:
                        var v: int = b[idx(c, r)]
                        if v == 0:
                                continue
                        for d in [[1, 0], [0, 1], [1, 1], [1, -1]]:
                                var c2 := c + int(d[0]) * 3
                                var r2 := r + int(d[1]) * 3
                                if c2 < 0 or c2 >= COLS or r2 < 0 or r2 >= ROWS:
                                        continue
                                var line := []
                                var all := true
                                for k in 4:
                                        var i := idx(c + int(d[0]) * k,
                                                        r + int(d[1]) * k)
                                        line.append(i)
                                        if int(b[i]) != v:
                                                all = false
                                                break
                                if all:
                                        return line
        return []

## every column that ends the game for `who` right now
static func winning_cols(b: Array, who: int) -> Array:
        var out := []
        for c in COLS:
                var r := drop_row(b, c)
                if r < 0:
                        continue
                var bb := b.duplicate()
                bb[idx(c, r)] = who
                if winner_of(bb) == who:
                        out.append(c)
        return out

## the windows tally: how alive the board is for the CPU's colors
static func tally(b: Array, p: Dictionary) -> float:
        var s := 0.0
        for c in COLS:
                for r in ROWS:
                        var v: int = b[idx(c, r)]
                        if v == 0:
                                continue
                        for d in [[1, 0], [0, 1], [1, 1], [1, -1]]:
                                var mine := 0
                                var theirs := 0
                                var dead := false
                                for k in 4:
                                        var cc := c + int(d[0]) * k
                                        var rr := r + int(d[1]) * k
                                        if cc < 0 or cc >= COLS or rr < 0 or rr >= ROWS:
                                                dead = true
                                                break
                                        var vv: int = b[idx(cc, rr)]
                                        if vv == 2:
                                                mine += 1
                                        elif vv == 1:
                                                theirs += 1
                                if dead:
                                        continue
                                if theirs == 0 and mine > 0:
                                        s += float(p["w_build"]) \
                                                        * [0.0, 1.0, 6.0, 30.0][clampi(mine, 0, 3)]
                                elif mine == 0 and theirs > 0:
                                        s -= float(p["w_block"]) \
                                                        * [0.0, 1.0, 8.0, 38.0][clampi(theirs, 0, 3)]
        return s

## THE MEMORY LAW (the xo law verbatim): push the finished round's
## record, drop everything older than MEM_ROUNDS.
static func remember(mem_in: Array, record: Dictionary) -> Array:
        var m := mem_in.duplicate()
        m.append({
                "open": int(record.get("open", -1)),
                "reply": int(record.get("reply", -1)),
                "fork": bool(record.get("fork", false)),
                "result": int(record.get("result", 0)),
        })
        while m.size() > MEM_ROUNDS:
                m.pop_front()
        return m

## WHAT THE MEMORY REMEMBERS (the xo law): burned - the reply the player
## already saw to THE SAME opening; pref - the reply that won last time;
## forkry - the player built a double threat inside the window.
static func adapt(mem_in: Array) -> Dictionary:
        var out := {"burned": -1, "pref": -1, "forkry": false}
        if mem_in.is_empty():
                return out
        for e in mem_in:
                if bool(e["fork"]):
                        out["forkry"] = true
        if mem_in.size() >= 2:
                var a: Dictionary = mem_in[0]
                var b: Dictionary = mem_in[1]
                if int(a["open"]) >= 0 and int(a["open"]) == int(b["open"]):
                        var last: Dictionary = mem_in[mem_in.size() - 1]
                        if int(last["result"]) != 2:
                                out["burned"] = int(last["reply"])
                        if int(last["result"]) == 2 and int(last["reply"]) >= 0:
                                out["pref"] = int(last["reply"])
        return out

## THE MOVE PIPELINE (the xo pipeline, dropped into columns):
##   1. take an immediate win (a small miss chance keeps it beatable)
##   2. block an immediate loss (skip is rare - "good enough to not lose")
##   3. the feel: build, block, center, the fork eye, the avoid law
##      (a move that hands the player a winning reply is poisoned), the
##      adapt nudges, a breath of noise
static func cpu_pick(board_in: Array, profile_id: String, mem_in: Array,
                rng: RandomNumberGenerator) -> int:
        var b := board_in.duplicate()
        var p: Dictionary = PROFILES[profile_id]
        var flags := adapt(mem_in)

        # THE BLIND SPOTS (the xo miss law made real): a missed win or a
        # missed block is a move the CPU literally does not see this turn
        # - step 3 wears a blind spot penalty on that exact column.
        var blind_wins := []
        var blind_blocks := []
        # 1. the win is RIGHT THERE - almost always taken
        var wins := winning_cols(b, 2)
        if not wins.is_empty():
                if rng.randf() >= float(p["miss_win"]):
                        return int(wins[rng.randi() % wins.size()])
                blind_wins = wins.duplicate()    # the whole set stays unseen
        # 2. the loss is RIGHT THERE - blocked almost always
        var threats := winning_cols(b, 1)
        if not threats.is_empty():
                if rng.randf() >= float(p["skip_block"]):
                        return int(threats[rng.randi() % threats.size()])
                blind_blocks = threats.duplicate()

        # 3. the feel
        var best := -INF
        var picks := []
        for c in COLS:
                var r := drop_row(b, c)
                if r < 0:
                        continue
                var b2 := b.duplicate()
                b2[idx(c, r)] = 2
                var decided := winner_of(b2) != 0
                var s := 0.0
                # the double threat: two ways to win tomorrow (a finished
                # game is not a threat - no credit for a decided board)
                if not decided:
                        var forks := winning_cols(b2, 2).size()
                        if forks >= 2:
                                s += 85.0 * float(p["fork_eye"])
                        # THE AVOID LAW: does this move hand the player the win?
                        var gifts := winning_cols(b2, 1).size()
                        if gifts > 0:
                                var noticed: bool = rng.randf() < float(p["avoid"])
                                s -= 130.0 if noticed else 18.0
                s += tally(b2, p)
                s += float(p["w_center"]) * CENTER_W[c] * 6.0
                # the blind spot: the moves it failed to see stay unseen
                if blind_wins.has(c) or blind_blocks.has(c):
                        s -= 2000.0
                # the burned reply never repeats against the same opening
                if int(flags["burned"]) == c:
                        s -= 90.0
                if int(flags["pref"]) == c:
                        s += 40.0
                s += rng.randf() * float(p["noise"])
                if s > best + 0.0001:
                        best = s
                        picks = [c]
                elif absf(s - best) <= 0.0001:
                        picks.append(c)
        if picks.is_empty():
                return -1                 # a full board: nothing to pick
        return int(picks[rng.randi() % picks.size()])

static func profile_next(i: int) -> Array:
        return [PROFILES.keys()[i % PROFILES.size()], i + 1]

# ============================================================ state
var board: Array = []
var turn := 1
var state := "ready"          # ready | play | wait | round_over
var clock := 0.0
var think_beat := 0.0
var cpu_think := false
var rounds := 0
var done_rounds := 0
var wins := 0
var losses := 0
var draws := 0
var streak := 0

# the adaptive memory (the xo law)
var mem: Array = []
var cur: Dictionary = {}

# the opener law (the xo law)
var next_opener := 1
var last_opener := 1

# the coin race
var coin_cell := Vector2i(-1, -1)
var coin_t := 0.0

# the round's profile
var profile_order: Array = ["wall", "trick", "rusher", "sage"]
var profile_i := 0
var profile := "sage"

# scene
var world: Node2D
var bg_l: Node2D
var frame_l: Node2D
var disc_l: Node2D
var fx_l: Node2D
var strike_l: Node2D
var turn_lbl: Label
var verdict_lbl: Label
var goals_row: Control
var ready_ui: Control = null
var cell := 120.0
var board_origin := Vector2.ZERO   # grid top-left; cell (0,0) center at +half
var strike_t := 1.0
var last_win_line: Array = []
var _discs: Array = []             # falling discs {c, r, x, y, vy, who}
var _dust: Array = []
var _time := 0.0
var _rng := RandomNumberGenerator.new()
var aim_col := -1
var _pending_resolve := 0          # the verdict waiting on the fall
var _pending_cpu := false

# ============================================================ the scene

func _goga_setup() -> void:
        _rng.randomize()
        pause_end_run = true    # THE PONG LAW: the pause END banks
        board = []
        for i in COLS * ROWS:
                board.append(0)
        var vp := get_viewport_rect().size
        world = Node2D.new()
        add_child(world)
        bg_l = Node2D.new()
        bg_l.z_index = -10
        bg_l.draw.connect(_draw_bg)
        world.add_child(bg_l)
        frame_l = Node2D.new()
        frame_l.draw.connect(_draw_frame)
        world.add_child(frame_l)
        disc_l = Node2D.new()
        disc_l.draw.connect(_draw_discs)
        world.add_child(disc_l)
        fx_l = Node2D.new()
        fx_l.z_index = 5
        fx_l.draw.connect(_draw_fx)
        world.add_child(fx_l)
        # THE STRIKE (the xo law: one amber swipe, drawn once, it stays)
        strike_l = Node2D.new()
        strike_l.z_index = 6
        strike_l.draw.connect(_draw_strike)
        world.add_child(strike_l)
        _layout(vp)
        _build_widgets(vp)
        _load_meta()
        add_hud_button("SHOP", func(): _shop_open())
        Jukebox.music("res://assets/audio/music/fl_theme.wav")
        _build_ready()

func _skin() -> Dictionary:
        var sid := Box.skin_on(game_id)
        if not SKINS.has(sid):
                sid = "classic"
        return SKINS[sid]

func _theme() -> Dictionary:
        var tid := Box.item_on(game_id, "theme")
        if not THEMES.has(tid):
                tid = "tavern"
        return THEMES[tid]

func _load_meta() -> void:
        _skin()
        _theme()
        bg_l.queue_redraw()
        frame_l.queue_redraw()
        disc_l.queue_redraw()

## THE ROOM: wall above, floor below, one honest divider - flat theme
## colors (the primitive law: they render everywhere)
func _draw_bg() -> void:
        var vp := get_viewport_rect().size
        var th := _theme()
        bg_l.draw_rect(Rect2(Vector2.ZERO, vp), th["room"])
        var fy := vp.y * 0.80
        bg_l.draw_rect(Rect2(0, fy, vp.x, vp.y - fy), th["floor"])
        bg_l.draw_rect(Rect2(0, fy - 3.0, vp.x, 3.0),
                        (th["floor"] as Color).lightened(0.12))

func _grid_rect() -> Rect2:
        return Rect2(board_origin, Vector2(COLS * cell, ROWS * cell))

## the toy frame: rounded slab with punched holes, bevel, feet, trim
func _draw_frame() -> void:
        var th := _theme()
        var g := _grid_rect()
        var pad := cell * 0.30
        var r := Rect2(g.position - Vector2(pad, pad),
                        g.size + Vector2(pad * 2.0, pad * 2.2))
        # feet (two little shoes tucked under the toy, at the quarters)
        var foot_w := cell * 0.85
        var foot_h := cell * 0.30
        for fx in [r.position.x + r.size.x * 0.16,
                        r.end.x - r.size.x * 0.16 - foot_w]:
                var fr := Rect2(fx, r.end.y - 6.0, foot_w, foot_h)
                _rounded(frame_l, fr, th["frame_dark"], foot_h * 0.35)
        # the bevel: a darker slab shifted down-right, then the slab
        _rounded(frame_l, Rect2(r.position + Vector2(10, 12), r.size),
                        th["frame_dark"], 34)
        _rounded(frame_l, r, th["frame"], 34)
        # the top highlight (a light kiss on the upper edge)
        frame_l.draw_rect(Rect2(r.position.x + 26, r.position.y + 8,
                        r.size.x - 52, 7),
                        (th["frame"] as Color).lightened(0.22))
        # the holes
        for c in COLS:
                for rw in ROWS:
                        var mid := _cell_mid(idx(c, rw))
                        var rad := cell * 0.40
                        # the cavity
                        frame_l.draw_circle(mid, rad, th["hole"])
                        # the inner rim: darker arc at the top (depth cue),
                        # a light lip at the bottom (the hole's far edge)
                        frame_l.draw_arc(mid, rad - 2.0, PI, PI * 2.0, 24,
                                        Color(0, 0, 0, 0.5), 5.0)
                        frame_l.draw_arc(mid, rad - 1.0, 0.0, PI, 24,
                                        (th["frame"] as Color).darkened(0.35), 3.0)
                        # the trim ring (the theme's voice, subtle)
                        frame_l.draw_arc(mid, rad + 1.5, 0, TAU, 40,
                                        Color(th["trim"], 0.14), 2.0)

## a filled rounded rect via polygon (draw_rect has no corner radius)
func _rounded(l: Node2D, r: Rect2, col: Color, rad: float) -> void:
        var pts := PackedVector2Array()
        var seg := 8
        var corners := [
                [Vector2(r.end.x - rad, r.position.y + rad), 0.0],
                [Vector2(r.end.x - rad, r.end.y - rad), PI * 0.5],
                [Vector2(r.position.x + rad, r.end.y - rad), PI],
                [Vector2(r.position.x + rad, r.position.y + rad), PI * 1.5],
        ]
        for corner in corners:
                var mid: Vector2 = corner[0]
                var a0: float = corner[1]
                for k in seg + 1:
                        var a := a0 + (PI * 0.5) * float(k) / float(seg)
                        pts.append(mid + Vector2(cos(a), sin(a)) * rad)
        l.draw_colored_polygon(pts, col)

func _cell_mid(i: int) -> Vector2:
        var c := i / ROWS
        var r := i % ROWS
        return board_origin + Vector2(c * cell + cell * 0.5,
                        r * cell + cell * 0.5)

func _cell_mid_cr(c: int, r: int) -> Vector2:
        return board_origin + Vector2(c * cell + cell * 0.5,
                        r * cell + cell * 0.5)

## the discs: settled ones + the falling ones (two-tone, gloss, shadow)
func _draw_discs() -> void:
        var sk := _skin()
        var rad := cell * 0.40
        for i in board.size():
                var v: int = board[i]
                if v == 0:
                        continue
                if _is_falling(i):
                        continue
                _paint_disc(disc_l, _cell_mid(i), rad,
                                sk["p1"] if v == 1 else sk["p2"], false)
        for d in _discs:
                _paint_disc(disc_l, Vector2(d["x"], d["y"]), rad,
                                sk["p1"] if int(d["who"]) == 1 else sk["p2"],
                                true)

## is the visual disc for cell i still mid-fall?
func _is_falling(i: int) -> bool:
        for d in _discs:
                if idx(int(d["c"]), int(d["r"])) == i:
                        return true
        return false

func _paint_disc(l: Node2D, mid: Vector2, rad: float, col: Color,
                falling: bool) -> void:
        var dark := col.darkened(0.38)
        # the drop shadow (sits on the hole's lip)
        l.draw_circle(mid + Vector2(3, 5), rad, Color(0, 0, 0, 0.30))
        # the body: base + bottom shade cap + top face
        l.draw_circle(mid, rad, dark)
        l.draw_circle(mid + Vector2(0, -rad * 0.16), rad * 0.86, col)
        # the gloss
        l.draw_circle(mid + Vector2(-rad * 0.30, -rad * 0.36),
                        rad * 0.20, Color(1, 1, 1, 0.55))
        l.draw_arc(mid, rad - 1.5, 0, TAU, 40, dark, 2.5)
        if falling:
                l.draw_arc(mid, rad + 2.0, 0, TAU, 40, Color(1, 1, 1, 0.12), 2.0)

func _draw_fx() -> void:
        # the aim ghost: a translucent disc at the column mouth + the
        # landing ring at its seat
        var sk := _skin()
        if state == "play" and turn == 1 and aim_col >= 0 \
                        and drop_row(board, aim_col) >= 0:
                var rad := cell * 0.40
                var mouth := Vector2(board_origin.x + aim_col * cell + cell * 0.5,
                                board_origin.y - cell * 0.62)
                fx_l.draw_circle(mouth, rad, Color(sk["p1"], 0.38))
                fx_l.draw_arc(mouth, rad, 0, TAU, 32, Color(sk["p1"], 0.7), 3.0)
                var seat := drop_row(board, aim_col)
                var mid := _cell_mid_cr(aim_col, seat)
                var pulse := 0.55 + 0.25 * sin(_time * 5.2)
                fx_l.draw_arc(mid, rad * 1.04, 0, TAU, 32,
                                Color(1, 1, 1, 0.30 * pulse), 3.0)
        # the dust pips (the xo dust law)
        for p in _dust:
                var a: float = clampf(float(p["life"]) / float(p["max"]), 0.0, 1.0)
                var c: Color = p["col"]
                c.a = a * 0.85
                fx_l.draw_rect(Rect2(float(p["x"]) - float(p["s"]) * 0.5,
                                float(p["y"]) - float(p["s"]) * 0.5,
                                float(p["s"]), float(p["s"])), c)
        # the coin (the xo coin law: bob, glint, breathe)
        if coin_cell.x >= 0 and int(board[idx(coin_cell.x, coin_cell.y)]) == 0:
                var tex: Texture2D = load("res://assets/ui/coin.png")
                if tex != null:
                        var pos := _cell_mid_cr(coin_cell.x, coin_cell.y)
                        pos.y += sin(coin_t * 3.2) * cell * 0.05
                        var fade: float = clampf(coin_t / 0.4, 0.0, 1.0)
                        var s: float = cell * 0.44 / float(tex.get_width())
                        var pop: float = 1.0 + 0.07 * sin(coin_t * 4.4)
                        fx_l.draw_set_transform(pos, 0.0,
                                        Vector2(s * pop * fade,
                                        s / maxf(0.05, pop) * fade))
                        fx_l.draw_texture(tex,
                                        -Vector2(tex.get_width(),
                                        tex.get_height()) / 2.0,
                                        Color(1, 1, 1, fade))
                        fx_l.draw_set_transform(Vector2.ZERO, Vector2.ONE.angle() * 0.0,
                                        Vector2.ONE)
                        var ga: float = coin_t * 2.6
                        fx_l.draw_arc(pos, cell * 0.32, ga, ga + 1.1, 30,
                                        Color(1, 1, 1, 0.5 * fade), 2.2)

func _draw_strike() -> void:
        if last_win_line.is_empty() or strike_t <= 0.0:
                return
        var p0 := _cell_mid(int(last_win_line[0]))
        var p1 := _cell_mid(int(last_win_line[3]))
        var pts := PackedVector2Array()
        var segs := 10
        var prog := clampf(strike_t, 0.0, 1.0)
        for k in segs + 1:
                var f := float(k) / float(segs)
                if f <= prog:
                        pts.append(p0.lerp(p1, f))
        if pts.size() >= 2:
                strike_l.draw_polyline(pts, Color("ffb020", 0.95), 12.0, true)

func _layout(vp: Vector2) -> void:
        var top := 190.0
        var bot := banner_bottom() + 40.0
        cell = minf((vp.x - 56.0) / float(COLS),
                        (vp.y - top - bot) / float(ROWS))
        cell = minf(cell, 132.0)
        cell = maxf(cell, 44.0)
        # THE FRAME FIT LAW: the whole toy (grid + the 0.30 pads) stays
        # inside the screen - the bevel never kisses the edges
        cell = minf(cell, (vp.x - 36.0) / float(COLS + 0.6))
        var side := Vector2(COLS * cell, ROWS * cell)
        var spare := vp.y - top - bot - side.y
        board_origin = Vector2((vp.x - side.x) * 0.5,
                        top + maxf(0.0, spare * 0.40))
        _place_texts(vp)
        bg_l.queue_redraw()
        frame_l.queue_redraw()
        disc_l.queue_redraw()

## the turn + verdict texts seat once, from layout AND from build
func _place_texts(vp: Vector2) -> void:
        var side := Vector2(COLS * cell, ROWS * cell)
        if turn_lbl != null:
                turn_lbl.position = Vector2(0, board_origin.y - 86.0)
                turn_lbl.custom_minimum_size = Vector2(vp.x, 44)
        if verdict_lbl != null:
                verdict_lbl.position = Vector2(0,
                                board_origin.y + side.y + cell * 0.30 + 22.0)
                verdict_lbl.custom_minimum_size = Vector2(vp.x, 50)

# ------------------------------------------------- the W/D/L cards + text

func _build_widgets(vp: Vector2) -> void:
        # THE W-D-L CARDS (the dominoes widget verbatim - the owner's
        # v0.3.8-6 seat law: IN the HUD row, hugging the score chip)
        goals_row = Control.new()
        goals_row.custom_minimum_size = Vector2(108.0 * 3.0 + 8.0 * 2.0, 64.0)
        goals_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
        goals_row.draw.connect(_draw_goal_cards.bind(goals_row))
        _hud_row.add_child(goals_row)
        var score_chip: Control = _score_label.get_parent().get_parent()
        _hud_row.move_child(goals_row, score_chip.get_index())
        turn_lbl = Arc.label("", 30, Color(1, 1, 1, 0.95))
        turn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        world.add_child(turn_lbl)
        verdict_lbl = Arc.label("", 32, Color(1, 1, 1, 0.95))
        verdict_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        verdict_lbl.visible = false
        world.add_child(verdict_lbl)
        _place_texts(get_viewport_rect().size)
        _refresh_widget()

## the dominoes widget's own draw law, ported 1:1 (same cards, colors)
func _draw_goal_cards(c: Control) -> void:
        var cw := 108.0
        var ch := 46.0
        var gapw := 8.0
        var cols := [Color("58c470"), Color("8b93a1"), Color("e8574a")]
        var letters := ["W", "D", "L"]
        var f := ThemeDB.fallback_font
        var mid_y := c.size.y * 0.5
        var x0 := c.size.x * 0.5
        for i in 3:
                var x: float = (cw + gapw) * (i - 1) + x0
                var r := Rect2(x - cw * 0.5, mid_y - ch * 0.5, cw, ch)
                c.draw_rect(Rect2(r.position + Vector2(4, 4), r.size),
                                Color(0.09, 0.05, 0.02, 0.85))
                c.draw_rect(r, Color(1, 1, 1, 0.95))
                c.draw_rect(r, cols[i], false, 5.0)
                var num: int = [wins, draws, losses][i]
                c.draw_string(f, Vector2(x - cw * 0.5 + 10.0, mid_y + 15.0),
                                letters[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 26,
                                cols[i])
                c.draw_string(f, Vector2(x - cw * 0.5 + 36.0, mid_y + 17.0),
                                str(num), HORIZONTAL_ALIGNMENT_LEFT, -1, 30,
                                Arc.INK)

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
        # THE GATE LAW (v0.3.8-8): index 0 of the HUD - UNDER the overlay
        # root, so every sheet draws above the tap-anywhere text
        _hud.move_child(ready_ui, 0)
        var l := Arc.label("TAP ANYWHERE TO START", 50, Color(1, 1, 1, 0.95))
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

# ============================================================ the rounds

func _new_round() -> void:
        for i in board.size():
                board[i] = 0
        _discs = []
        _dust = []
        _settled_discs_clear()
        last_win_line = []
        strike_t = 1.0
        strike_l.queue_redraw()
        rounds += 1
        verdict_lbl.visible = false
        # THE OPENER LAW: the loser starts; a draw flips
        last_opener = next_opener
        turn = next_opener
        clock = 0.0
        cur = {"open": -1, "reply": -1, "fork": false}
        var pn := profile_next(profile_i)
        profile = pn[0]
        profile_i = pn[1]
        # THE COIN LAW: after every 4 completed rounds the next round
        # opens with a GOGACoin in an EMPTY hole - the disc that lands
        # there takes it (the CPU races you)
        coin_cell = Vector2i(-1, -1)
        coin_t = 0.0
        if done_rounds > 0 and done_rounds % COIN_EVERY == 0:
                coin_cell = _random_empty_cell()
        _banner()

func _settled_discs_clear() -> void:
        pass  # the discs live in the draw pass - nothing to free

func _random_empty_cell() -> Vector2i:
        var empties := []
        for c in COLS:
                for r in ROWS:
                        if int(board[idx(c, r)]) == 0:
                                empties.append(Vector2i(c, r))
        if empties.is_empty():
                return Vector2i(-1, -1)
        return empties[_rng.randi() % empties.size()]

func _banner() -> void:
        if state == "round_over":
                return
        if turn == 1:
                turn_lbl.text = "YOUR MOVE"
                turn_lbl.add_theme_color_override("font_color",
                                Color(1, 1, 1, 0.95))
        else:
                var n := int(_time * 2.5) % 3 + 1
                turn_lbl.text = "CPU IS THINKING%s" % " .".repeat(n)
                turn_lbl.add_theme_color_override("font_color",
                                Color(1, 1, 1, 0.8))

# ============================================================ the moves

func _goga_input(event: InputEvent) -> void:
        if sheet_open_count() > 0:
                return
        if event is InputEventScreenTouch:
                var t := event as InputEventScreenTouch
                if t.pressed:
                        if state == "ready":
                                _gate_down()
                                _new_round()
                                return
                        _aim(t.position)
                else:
                        _release(t.position)
        elif event is InputEventScreenDrag:
                if state == "play" and turn == 1:
                        _aim((event as InputEventScreenDrag).position)
        elif event is InputEventMouseMotion:
                if state == "play" and turn == 1:
                        _aim((event as InputEventMouseMotion).position)
        elif event is InputEventMouseButton:
                var mb := event as InputEventMouseButton
                if mb.pressed:
                        if state == "ready":
                                _gate_down()
                                _new_round()
                                return
                        _aim(mb.position)
                else:
                        _release(mb.position)

## the finger slides across the columns - the ghost follows
func _aim(at: Vector2) -> void:
        if state != "play" or turn != 1:
                return
        var g := _grid_rect()
        if at.x < g.position.x - cell * 0.5 or at.x > g.end.x + cell * 0.5:
                aim_col = -1
                return
        var c := int(floor((at.x - g.position.x) / cell))
        aim_col = clampi(c, 0, COLS - 1)

func _release(at: Vector2) -> void:
        if state != "play" or turn != 1:
                return
        _aim(at)
        if aim_col >= 0 and drop_row(board, aim_col) >= 0:
                _player_drop(aim_col)
        else:
                aim_col = -1

## the player's disc takes the plunge
func _player_drop(c: int) -> void:
        if cur["open"] < 0:
                cur["open"] = c
        _drop_disc(c, 1)
        Jukebox.sfx("fl_tap", -6.0)
        aim_col = -1

func _drop_disc(c: int, who: int) -> void:
        var r := drop_row(board, c)
        if r < 0:
                Jukebox.sfx("fl_denied", -6.0)
                return
        board[idx(c, r)] = who
        var mid_x := board_origin.x + c * cell + cell * 0.5
        var start_y := board_origin.y - cell * 0.62
        var target_y := _cell_mid_cr(c, r).y
        _discs.append({
                "c": c, "r": r, "x": mid_x, "y": start_y,
                "vy": 140.0, "who": who, "ty": target_y, "bounced": false,
        })
        state = "wait"
        turn_lbl.text = ""
        Jukebox.sfx("fl_drop", -8.0)
        # the live fork spy (feeds the memory's fork flag)
        if who == 1 and winning_cols(board, 1).size() >= 2:
                cur["fork"] = true

## the disc physics: accelerate, land, one squash-bounce, then report
func _tick_discs(delta: float) -> void:
        var g := 4200.0
        for d in _discs.duplicate():
                d["vy"] = float(d["vy"]) + g * delta
                d["y"] = float(d["y"]) + float(d["vy"]) * delta
                if float(d["y"]) >= float(d["ty"]):
                        if not bool(d.get("bounced", false)) \
                                        and float(d["vy"]) > 700.0:
                                d["bounced"] = true
                                d["y"] = float(d["ty"])
                                d["vy"] = -float(d["vy"]) * 0.22
                                Jukebox.sfx("fl_land", -4.0, 1.0 + _rng.randf() * 0.05)
                                _dust_burst(Vector2(float(d["x"]), float(d["ty"])),
                                                _skin()["p1"] if int(d["who"]) == 1
                                                else _skin()["p2"])
                        else:
                                d["y"] = float(d["ty"])
                                _discs.erase(d)
                                _on_landed(int(d["c"]), int(d["r"]), int(d["who"]))
        disc_l.queue_redraw()

## the disc has rested - the coin, the verdict, the next hand
func _on_landed(c: int, r: int, who: int) -> void:
        # THE COIN RACE: whoever lands there TAKES it
        if coin_cell.x == c and coin_cell.y == r:
                _coin_taken(who)
        if _pending_resolve == 0:
                var w := winner_of(board)
                if w != 0:
                        _pending_resolve = w
        if _pending_resolve != 0:
                var w2 := _pending_resolve
                _pending_resolve = 0
                _resolve(w2)
                return
        if who == 1:
                # hand the turn to the CPU (it thinks, then drops)
                turn = 2
                cpu_think = true
                think_beat = _rng.randf_range(0.45, 0.9)
                clock = 0.0
                state = "wait"
                _banner()
        else:
                turn = 1
                state = "play"
                _banner()

func _ai_move() -> void:
        var rng := RandomNumberGenerator.new()
        rng.seed = int(Time.get_unix_time_from_system() * 1000.0) \
                        ^ (rounds * 7919) ^ (board.hash() & 0xffff)
        var c := cpu_pick(board, profile, mem, rng)
        if c >= 0:
                # the reply bookkeeping (the xo law): the CPU's first
                # answer to the player's opening is what memory grades
                if cur["open"] >= 0 and cur["reply"] < 0:
                        cur["reply"] = c
                _drop_disc(c, 2)
                Jukebox.sfx("fl_tap", -8.0, 0.9)

# ============================================================ the verdict

func _resolve(w: int) -> void:
        state = "round_over"
        clock = 0.0
        cur["result"] = w
        done_rounds += 1
        if w == 1 or w == 2:
                last_win_line = win_line(board)
        if w == 1:
                wins += 1
                streak += 1
                add_score(1)                     # THE OWNER'S LAW: win = +1
                verdict_lbl.text = "YOU WIN  +1"
                verdict_lbl.add_theme_color_override("font_color",
                                Color("7ee2a0"))
                Jukebox.sfx("fl_win", -3.0)
                achievement_count("wins", 1)
                achievement_max("streak", streak)
                if last_win_line.size() == 4:
                        var mid := (_cell_mid(int(last_win_line[0]))
                                        + _cell_mid(int(last_win_line[3]))) * 0.5
                        Arc.confetti(_overlay_root_ref(), mid, 30)
        elif w == 2:
                losses += 1
                streak = 0
                # loss = -1, the score NEVER goes negative (the xo law)
                if score > 0:
                        add_score(-1)
                verdict_lbl.text = "CPU WINS  -1"
                verdict_lbl.add_theme_color_override("font_color",
                                Color("f2a09a"))
                Jukebox.sfx("fl_lose", -3.0)
        else:
                draws += 1
                add_score(0)                     # a draw pays nothing
                verdict_lbl.text = "THE BOARD IS FULL - DRAW"
                verdict_lbl.add_theme_color_override("font_color",
                                Color("c8cdd4"))
                Jukebox.sfx("fl_draw", -4.0)
        # THE OPENER LAW: the loser starts next; a draw flips
        if w == 1:
                next_opener = 2
        elif w == 2:
                next_opener = 1
        else:
                next_opener = 2 if last_opener == 1 else 1
        if last_win_line.size() == 4:
                strike_t = 0.0                   # the strike draws ONCE
        achievement_max("max_score", score)
        mem = remember(mem, cur)                 # THE 2-ROUND MEMORY
        _refresh_widget()
        verdict_lbl.visible = true
        turn_lbl.text = ""
        check_achievements()

# ============================================================ the tick

func _goga_tick(delta: float) -> void:
        _time += delta
        if state == "wait":
                clock += delta
                if cpu_think:
                        _banner()
                        if clock >= think_beat:
                                cpu_think = false
                                _ai_move()
        elif state == "round_over":
                clock += delta
                if strike_t < 1.0:
                        strike_t = minf(1.0, strike_t + delta * 3.2)
                        strike_l.queue_redraw()
                if clock >= 1.9:
                        _new_round()
        _tick_discs(delta)
        coin_t += delta
        fx_l.queue_redraw()
        frame_l.queue_redraw()

# ------------------------------------------------------------ dust + coin

func _dust_burst(at: Vector2, col: Color, n := 8) -> void:
        for i in n:
                _dust.append({
                        "x": at.x + _rng.randf_range(-cell * 0.24, cell * 0.24),
                        "y": at.y + _rng.randf_range(-cell * 0.1, cell * 0.14),
                        "vx": _rng.randf_range(-110.0, 110.0),
                        "vy": _rng.randf_range(-160.0, -30.0),
                        "life": _rng.randf_range(0.28, 0.5),
                        "max": 0.5,
                        "s": _rng.randf_range(2.5, 5.5),
                        "col": col,
                })
        if _dust.size() > 140:
                _dust = _dust.slice(_dust.size() - 140)

func _coin_taken(who: int) -> void:
        coin_cell = Vector2i(-1, -1)
        if who == 1:
                add_run_coins(1)
                Jukebox.sfx("fl_coin", -3.0)
                game_toast("YOU TOOK THE GOGACOIN  +1")
                _dust_burst(_cell_mid_cr(
                        _last_col(), _last_row()), Color("ffd24a"), 14)
        else:
                Jukebox.sfx("coin", -6.0, 0.8)
                game_toast("THE CPU GRABBED THE COIN")

var _last_c := -1
var _last_r := -1

func _last_col() -> int:
        return _last_c

func _last_row() -> int:
        return _last_r

# ============================================================ the shop
## DIRECT (the chess law): skins + themes, everything but the defaults
## bought. The OPTIONS menu does not exist here (the owner: four in line
## carries no optionals - the shop is the only shelf).

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
        var t := Arc.label("FOUR IN LINE SHOP", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.52, 300.0, 640.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        box.add_child(_shop_label("DISCS - the pair you drop"))
        for id in SKINS:
                box.add_child(_skin_row(id))
        box.add_child(_shop_label("THE SET - frame and room"))
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
                _load_meta()
                # THE GATE TRUTH LAW: the gate comes back ONLY over ready
                if state == "ready" and ready_ui != null \
                                and is_instance_valid(ready_ui):
                        ready_ui.visible = true

func _shop_label(txt: String) -> Label:
        return Arc.fit_label(txt, 24, Arc.HOT, 560)

func _price_btn(txt: String, price: int, col: Color, cb: Callable) -> Button:
        var b := Arc.coin_button("%s  %d" % [txt, price], Vector2(560, 64),
                22, col, cb)
        if Box.coins() < price:
                b.disabled = true
        return b

func _skin_row(id: String) -> Control:
        var c: Dictionary = SKINS[id]
        var owned := Box.skin_owned(game_id, id) or int(c["price"]) == 0
        var on: bool = Box.skin_on(game_id) == id \
                or (int(c["price"]) == 0 and Box.skin_on(game_id) == "")
        if on:
                var l := Arc.fit_label("%s  (ON) - %s" % [c["name"], c["desc"]],
                        22, Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        if owned:
                return Arc.button("%s - DROP THESE" % c["name"],
                        Vector2(560, 60), 22, Color("4a5ab8"), func():
                                Box.equip_skin(game_id, id)
                                Jukebox.sfx("confirm", -4.0)
                                _shop_reopen())
        return _price_btn(c["name"], int(c["price"]), Color("4a5ab8"), func():
                if Box.buy_skin(game_id, id, int(c["price"])):
                        Jukebox.sfx("buy")
                        Box.equip_skin(game_id, id)
                _shop_reopen())

func _theme_row(id: String) -> Control:
        var c: Dictionary = THEMES[id]
        var owned := Box.item_owned(game_id, "theme", id) or int(c["price"]) == 0
        var on: bool = Box.item_on(game_id, "theme") == id \
                or (int(c["price"]) == 0 and Box.item_on(game_id, "theme") == "")
        if on:
                var l := Arc.fit_label("%s  (ON) - %s" % [c["name"], c["desc"]],
                        22, Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        if owned:
                return Arc.button("%s - PLAY ON IT" % c["name"],
                        Vector2(560, 60), 22, Color("2a7a68"), func():
                                Box.equip_item(game_id, "theme", id)
                                Jukebox.sfx("confirm", -4.0)
                                _shop_reopen())
        return _price_btn(c["name"], int(c["price"]), Color("2a7a68"), func():
                if Box.buy_item(game_id, "theme", id, int(c["price"])):
                        Jukebox.sfx("buy")
                        Box.equip_item(game_id, "theme", id)
                _shop_reopen())

func _shop_reopen() -> void:
        if shop_id != "":
                sheet_pop()
                _shop_open.call_deferred()

# ============================================================ the probe
## The headless contract: a fresh deterministic round any probe drives.

func probe_reset(seed_v: int) -> void:
        _rng.seed = seed_v
        _gate_down()
        for i in board.size():
                board[i] = 0
        _discs = []
        _dust = []
        rounds = 0
        done_rounds = 0
        wins = 0
        losses = 0
        draws = 0
        mem = []
        profile_i = 0
        next_opener = 1
        last_opener = 1
        _pending_resolve = 0
        _pending_cpu = false
        paused = true
        _new_round()
        state = "play"
        turn = 1

## fast-forward: settle any falling discs instantly (probe cadence)
func probe_settle() -> void:
        var guard := 0
        while not _discs.is_empty() and guard < 64:
                guard += 1
                probe_step(0.05)

func probe_step(dt: float) -> void:
        _goga_tick(dt)
