extends GogaGame
## FIVE IN ROW - v0.3.9, the gomoku sibling graduates from the workshop
## (the owner's v039 GDD round; the teaser "FIVE LINES" is renamed
## FIVE IN ROW by the owner's order).
##
## Owner contract (v0.3.9):
##   - VERTICAL ONLY (the xo law: no position ask, no horizontal table)
##   - the economy (the xo shape): win +1, loss -1 (score never
##     negative), draw 0; run bonus /2 (registry coin_div 2)
##   - a GOGACoin rests on an intersection after every 3 completed
##     rounds - the stone placed there takes it (the CPU races you)
##   - the opener law: the player opens round 1, the LOSER of a round
##     opens the next, a draw flips the opener
##   - the W/D/L cards (the dominoes/chess widget), TAP ANYWHERE TO
##     START (the chess gate, HUD index 0), pause_end_run (the pong law)
##   - THE OPTIONALS MENU (the 2048 mechanic word for word): board sizes
##     bought first, then applied - owned sizes show SWITCH behind the
##     are-you-sure, locked sizes walk to the SHOP, a switch starts a
##     fresh board, and after a YES a FRESH sheet reads the applied
##     board as ON (the v0.3.8-8 fresh-sheet law)
##   - the shop (5-5): 5 stone skins + 5 themes (board + room), the
##     defaults owned, everything else bought (coin buttons, gray when
##     the wallet is dry)
##   - ONE opponent, FOUR moods (invisible rotation), the 2-round
##     adaptive memory (the xo law): the burned reply never repeats,
##     the winning reply is trusted once; programmed failures
##     everywhere - challenging, always beatable
##   - the boards: 8x8 normal (free), 10x10 and 12x12 bought (the
##     owner's ladder)
##
## Probe contract: the whole CPU core is STATIC - winner_of / five_cells /
## threat_at / cpu_pick / remember / adapt drive headless laws without
## the scene (the xo contract).

const COIN_EVERY := 3      # owner: one GOGACoin after each 3 rounds
const MEM_ROUNDS := 2      # the xo memory law
const FIVE := 5            # the win length

# ------------------------------------------------------------- the boards
## THE BOARD SIZES (the owner: "8x8? then 10x10 then 12x12"). 8x8 is the
## free normal game; 10 and 12 are SHOP items bought first (the 2048
## mechanic).
const SIZES := {
        "8": {"name": "8 x 8", "price": 0,
                "desc": "normal - the tight tactical board"},
        "10": {"name": "10 x 10", "price": 1800,
                "desc": "the wide board - more room to breathe"},
        "12": {"name": "12 x 12", "price": 3600,
                "desc": "the monster board"},
}

# ------------------------------------------------------------- the shop
## 5 stone skins (the first owned) + 5 themes (board + room).
const SKINS := {
        "charcoal": {"name": "CHARCOAL", "price": 0,
                "p1": Color("26262e"), "p2": Color("f3ead8"),
                "desc": "charcoal vs ivory - the classic pair"},
        "berry": {"name": "BERRY", "price": 150,
                "p1": Color("8a2749"), "p2": Color("f5e6d3"),
                "desc": "deep berry vs cream"},
        "jade": {"name": "JADE", "price": 220,
                "p1": Color("0f7d5c"), "p2": Color("f1e9d2"),
                "desc": "jade vs bone"},
        "glass": {"name": "GLASS", "price": 300,
                "p1": Color("38bdf8"), "p2": Color("f472b6"),
                "desc": "the glass stones glow"},
        "royal": {"name": "ROYAL", "price": 380,
                "p1": Color("b91c1c"), "p2": Color("d4af37"),
                "desc": "garnet vs gold"},
}
const THEMES := {
        "honey": {"name": "HONEY", "price": 0,
                "board": Color("d9a95f"), "board_dark": Color("c08d47"),
                "line": Color("4a2f16"), "room": Color("2c1d10"),
                "floor": Color("22150a"),
                "desc": "the honey wood board"},
        "sakura": {"name": "SAKURA", "price": 220,
                "board": Color("f2d7c4"), "board_dark": Color("e0b8a0"),
                "line": Color("8a4b3a"), "room": Color("3a2230"),
                "floor": Color("2d1926"),
                "desc": "the pale spring board"},
        "sea": {"name": "SEA", "price": 280,
                "board": Color("9fc4b8"), "board_dark": Color("7fa99c"),
                "line": Color("1f4d44"), "room": Color("10262a"),
                "floor": Color("0c1e21"),
                "desc": "the sea-green slab"},
        "night": {"name": "NIGHT", "price": 340,
                "board": Color("23283a"), "board_dark": Color("181c2b"),
                "line": Color("8fa3c8"), "room": Color("0b0f1c"),
                "floor": Color("080b14"),
                "desc": "the midnight board"},
        "marble": {"name": "MARBLE", "price": 420,
                "board": Color("e8e6e1"), "board_dark": Color("cfccc4"),
                "line": Color("5a5f6e"), "room": Color("23252d"),
                "floor": Color("1b1d24"),
                "desc": "the cold polished slab"},
}

# ------------------------------------------------------------- the profiles
## THE FOUR MOODS (the xo law: invisible rotation, one name).
##   miss_win   - the chance it fails to take an immediate five
##   skip_block - the chance it fails to block the player's five
##   fork_eye   - how eagerly it sits on (and builds) double threats
##   noise      - root score jitter (same board never plays the same)
##   w_build/w_block/w_center - the feel
const PROFILES := {
        "wall": {
                "miss_win": 0.09, "skip_block": 0.08, "fork_eye": 0.8,
                "noise": 60.0,
                "w_build": 0.85, "w_block": 1.6, "w_center": 1.0,
        },
        "trick": {
                "miss_win": 0.08, "skip_block": 0.10, "fork_eye": 1.6,
                "noise": 110.0,
                "w_build": 1.5, "w_block": 1.15, "w_center": 0.9,
        },
        "rusher": {
                "miss_win": 0.10, "skip_block": 0.14, "fork_eye": 1.0,
                "noise": 140.0,
                "w_build": 1.9, "w_block": 0.85, "w_center": 1.1,
        },
        "sage": {
                "miss_win": 0.08, "skip_block": 0.09, "fork_eye": 1.2,
                "noise": 90.0,
                "w_build": 1.25, "w_block": 1.3, "w_center": 1.0,
        },
}
## the pattern ladder for one direction through a cell (count, open ends)
## - five is the game, open four is a guillotine, open three a promise
const P_ATTN := [4.0, 20.0, 120.0, 900.0, 6000.0, 100000.0]

# ============================================================ THE CPU CORE
## Static so tests (flow_test + the probes) drive the brain without the
## scene - the xo contract. The board is a flat n*n array; idx grows
## with the equipped size.

static func idx(c: int, r: int, n: int) -> int:
        return c * n + r

static func winner_of(b: Array, n: int, k := FIVE) -> int:
        ## 0 = none yet, 1 = player, 2 = CPU, 3 = board full (draw)
        for c in n:
                for r in n:
                        var v: int = b[idx(c, r, n)]
                        if v == 0:
                                continue
                        for d in [[1, 0], [0, 1], [1, 1], [1, -1]]:
                                var ce := c + int(d[0]) * (k - 1)
                                var re := r + int(d[1]) * (k - 1)
                                if ce < 0 or ce >= n or re < 0 or re >= n:
                                        continue
                                var all := true
                                for j in k:
                                        if int(b[idx(c + int(d[0]) * j,
                                                        r + int(d[1]) * j, n)]) != v:
                                                all = false
                                                break
                                if all:
                                        return v
        for i in b.size():
                if int(b[i]) == 0:
                        return 0
        return 3

## the winning k-line as cell indexes (empty when no win) - the strike law
static func win_line(b: Array, n: int, k := FIVE) -> Array:
        for c in n:
                for r in n:
                        var v: int = b[idx(c, r, n)]
                        if v == 0:
                                continue
                        for d in [[1, 0], [0, 1], [1, 1], [1, -1]]:
                                var ce := c + int(d[0]) * (k - 1)
                                var re := r + int(d[1]) * (k - 1)
                                if ce < 0 or ce >= n or re < 0 or re >= n:
                                        continue
                                var line := []
                                var all := true
                                for j in k:
                                        var i := idx(c + int(d[0]) * j,
                                                        r + int(d[1]) * j, n)
                                        line.append(i)
                                        if int(b[i]) != v:
                                                all = false
                                                break
                                if all:
                                        return line
        return []

## every EMPTY cell that would END the game for `who` right now
static func five_cells(b: Array, n: int, who: int, k := FIVE) -> Array:
        var out := []
        for i in b.size():
                if int(b[i]) != 0:
                        continue
                var bb := b.duplicate()
                bb[i] = who
                if winner_of(bb, n, k) == who:
                        out.append(i)
        return out

## the points that matter: empty cells within arm's reach of a stone
static func candidate_cells(b: Array, n: int) -> Array:
        var out := []
        var any := false
        for c in n:
                for r in n:
                        if int(b[idx(c, r, n)]) != 0:
                                any = true
                                for dc in range(-2, 3):
                                        for dr in range(-2, 3):
                                                var cc := c + dc
                                                var rr := r + dr
                                                if cc < 0 or cc >= n \
                                                                or rr < 0 or rr >= n:
                                                        continue
                                                var i := idx(cc, rr, n)
                                                if int(b[i]) == 0 \
                                                                and not out.has(i):
                                                        out.append(i)
        if not any:
                out.append(idx(n / 2, n / 2, n))
        return out

## the threat value of ONE direction through a cell for `who`
## (count the run the stone joins + whether the ends stay open)
static func _dir_threat(b: Array, n: int, c: int, r: int, dc: int, dr: int,
                who: int) -> float:
        var count := 1
        var open_a := false
        var open_b := false
        var cc := c + dc
        var rr := r + dr
        while cc >= 0 and cc < n and rr >= 0 and rr < n \
                        and int(b[idx(cc, rr, n)]) == who:
                count += 1
                cc += dc
                rr += dr
        if cc >= 0 and cc < n and rr >= 0 and rr < n \
                        and int(b[idx(cc, rr, n)]) == 0:
                open_a = true
        cc = c - dc
        rr = r - dr
        while cc >= 0 and cc < n and rr >= 0 and rr < n \
                        and int(b[idx(cc, rr, n)]) == who:
                count += 1
                cc -= dc
                rr -= dr
        if cc >= 0 and cc < n and rr >= 0 and rr < n \
                        and int(b[idx(cc, rr, n)]) == 0:
                open_b = true
        var opens := (1 if open_a else 0) + (1 if open_b else 0)
        if count >= FIVE:
                return P_ATTN[5]
        if opens == 0:
                return 0.0
        var tier: float = P_ATTN[clampi(count, 1, 4)]
        # a fully open run is worth a tier and a half over a half-open one
        return tier * (1.5 if opens == 2 else 1.0)

## the whole-cell threat: four directions summed
static func threat_at(b: Array, n: int, i: int, who: int) -> float:
        var c := i / n
        var r := i % n
        var s := 0.0
        for d in [[1, 0], [0, 1], [1, 1], [1, -1]]:
                s += _dir_threat(b, n, c, r, int(d[0]), int(d[1]), who)
        return s

## THE MEMORY LAW (the xo law verbatim)
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

## WHAT THE MEMORY REMEMBERS (the xo law)
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

## THE MOVE PIPELINE (the xo pipeline on an intersection board):
##   1. take an immediate five (a small miss chance keeps it beatable)
##   2. block the player's five (skip is rare - "good enough to not lose")
##   3. the feel: attack + defense per cell, the fork eye (double-five
##      threats get built and sat on), center love, the adapt nudges,
##      a breath of noise
static func cpu_pick(board_in: Array, n: int, profile_id: String,
                mem_in: Array, rng: RandomNumberGenerator) -> int:
        var b := board_in.duplicate()
        var p: Dictionary = PROFILES[profile_id]
        var flags := adapt(mem_in)
        var cands := candidate_cells(b, n)
        if cands.is_empty():
                return -1

        # THE BLIND SPOTS (the xo miss law made real): a missed five or a
        # missed block is a point the CPU literally does not see this turn
        var blind_wins := []
        var blind_blocks := []
        # 1. the five is RIGHT THERE - almost always taken
        var mine5 := five_cells(b, n, 2)
        if not mine5.is_empty():
                if rng.randf() >= float(p["miss_win"]):
                        return int(mine5[rng.randi() % mine5.size()])
                blind_wins = mine5.duplicate()   # the whole set stays unseen
        # 2. the player's five is RIGHT HERE - blocked almost always
        var their5 := five_cells(b, n, 1)
        if not their5.is_empty():
                if rng.randf() >= float(p["skip_block"]):
                        return int(their5[rng.randi() % their5.size()])
                blind_blocks = their5.duplicate()

        # 3. the feel
        var best := -INF
        var picks := []
        for i: int in cands:
                var s := 0.0
                # THE BLIND SPOTS: the attack at the missed five and the
                # defense at the missed block stay invisible this turn
                if blind_wins.has(i) or blind_blocks.has(i):
                        s -= 50000.0   # out-scales every threat tier
                else:
                        s += threat_at(b, n, i, 2) * float(p["w_build"])
                        s += threat_at(b, n, i, 1) * float(p["w_block"])
                # THE FORK EYE: a cell that leaves two fives at once is a
                # guillotine - build ours, fear theirs (the memory wakes
                # it wide when the player forked inside the window). A
                # decided board earns no threat credit.
                var eye := float(p["fork_eye"])
                if bool(flags["forkry"]):
                        eye = maxf(eye, 2.2)
                var b2 := b.duplicate()
                b2[i] = 2
                if winner_of(b2, n) == 0:
                        var my_fives := five_cells(b2, n, 2).size()
                        if my_fives >= 2:
                                s += 9000.0 * eye
                        elif my_fives == 1:
                                s += 700.0 * eye
                var b3 := b.duplicate()
                b3[i] = 1
                if winner_of(b3, n) == 0:
                        var their_fives := five_cells(b3, n, 1).size()
                        if their_fives >= 2:
                                s -= 8500.0 * eye
                        elif their_fives == 1:
                                s -= 620.0 * eye
                # the center love (a quiet pull toward the middle)
                var c := i / n
                var r := i % n
                var mid := float(n - 1) * 0.5
                var pull := 1.0 - (absf(float(c) - mid)
                                + absf(float(r) - mid)) / float(n)
                s += pull * 30.0 * float(p["w_center"])
                # the burned reply never repeats against the same opening
                if int(flags["burned"]) == i:
                        s -= 2600.0
                if int(flags["pref"]) == i:
                        s += 950.0
                s += rng.randf() * float(p["noise"])
                if s > best + 0.0001:
                        best = s
                        picks = [i]
                elif absf(s - best) <= 0.0001:
                        picks.append(i)
        return int(picks[rng.randi() % picks.size()])

static func profile_next(i: int) -> Array:
        return [PROFILES.keys()[i % PROFILES.size()], i + 1]

# ============================================================ state
var board: Array = []
var grid_n := 8                 # THE BOARD SIZE (the equipped SIZES key)
var size_id := "8"              # the equipped size key (SIZES)
var turn := 1
var state := "ready"            # ready | play | wait | round_over
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
var coin_cell := -1
var coin_t := 0.0

# the round's profile
var profile_order: Array = ["wall", "trick", "rusher", "sage"]
var profile_i := 0
var profile := "sage"

# the 2048 confirm law (stack-borne, the fresh-sheet rule)
var _confirm_open_id := ""

# scene
var world: Node2D
var bg_l: Node2D
var board_l: Node2D
var stone_l: Node2D
var fx_l: Node2D
var strike_l: Node2D
var turn_lbl: Label
var verdict_lbl: Label
var goals_row: Control
var ready_ui: Control = null
var cell := 90.0
var board_origin := Vector2.ZERO
var strike_t := 1.0
var last_win_line: Array = []
var _stones: Array = []         # falling/settling stones {i, t0}
var _dust: Array = []
var _time := 0.0
var _rng := RandomNumberGenerator.new()
var aim_i := -1
var _pending_resolve := 0

# ============================================================ the scene

func _goga_setup() -> void:
        _rng.randomize()
        pause_end_run = true    # THE PONG LAW: the pause END banks
        size_id = "8"
        var on := Box.item_on(game_id, "size")
        if SIZES.has(on):
                size_id = on
        grid_n = int(size_id)
        _new_board()
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
        stone_l = Node2D.new()
        stone_l.draw.connect(_draw_stones)
        world.add_child(stone_l)
        fx_l = Node2D.new()
        fx_l.z_index = 5
        fx_l.draw.connect(_draw_fx)
        world.add_child(fx_l)
        strike_l = Node2D.new()
        strike_l.z_index = 6
        strike_l.draw.connect(_draw_strike)
        world.add_child(strike_l)
        _layout(vp)
        _build_widgets(vp)
        _load_meta()
        # THE HUD SEAT LAW (v0.3.9-1, the owner: "the shop/options button
        # are swapped, shop should be next to back button then the options
        # be at the right side") - the flow seats in call order
        add_hud_button("SHOP", func(): _shop_open())
        add_hud_button("OPTIONS", func(): _options_open())
        Jukebox.music("res://assets/audio/music/bv_theme.wav")
        _build_ready()

func _new_board() -> void:
        board = []
        for i in grid_n * grid_n:
                board.append(0)

func _skin() -> Dictionary:
        var sid := Box.skin_on(game_id)
        if not SKINS.has(sid):
                sid = "charcoal"
        return SKINS[sid]

func _theme() -> Dictionary:
        var tid := Box.item_on(game_id, "theme")
        if not THEMES.has(tid):
                tid = "honey"
        return THEMES[tid]

func _load_meta() -> void:
        _skin()
        _theme()
        bg_l.queue_redraw()
        board_l.queue_redraw()
        stone_l.queue_redraw()

## THE ROOM: wall above, floor below, one honest divider (the fourline
## room law - flat theme colors, primitives only)
func _draw_bg() -> void:
        var vp := get_viewport_rect().size
        var th := _theme()
        bg_l.draw_rect(Rect2(Vector2.ZERO, vp), th["room"])
        var fy := vp.y * 0.80
        bg_l.draw_rect(Rect2(0, fy, vp.x, vp.y - fy), th["floor"])
        bg_l.draw_rect(Rect2(0, fy - 3.0, vp.x, 3.0),
                        (th["floor"] as Color).lightened(0.12))

func _grid_rect() -> Rect2:
        var side := float(grid_n) * cell
        return Rect2(board_origin, Vector2(side, side))

## THE BOARD: wood slab, ink grid, star points, a soft under-shadow
func _draw_board() -> void:
        var th := _theme()
        var g := _grid_rect()
        var pad := cell * 0.42
        var r := Rect2(g.position - Vector2(pad, pad),
                        g.size + Vector2(pad * 2.0, pad * 2.0))
        # the under-shadow + the slab (two flat planes, bevel tone at the
        # bottom edge - the plank reads thick)
        board_l.draw_rect(Rect2(r.position + Vector2(10, 14), r.size),
                        Color(0, 0, 0, 0.35))
        board_l.draw_rect(r, th["board"])
        board_l.draw_rect(Rect2(r.position.x, r.end.y - 10.0, r.size.x, 10.0),
                        th["board_dark"])
        # the grain: faint horizontal plank bands (deterministic)
        var yy := r.position.y + cell * 0.5
        var band := 0
        while yy < r.end.y:
                if band % 3 != 2:
                        board_l.draw_rect(Rect2(r.position.x, yy,
                                        r.size.x, 2.0),
                                        Color(th["board_dark"], 0.28))
                yy += cell * 0.86
                band += 1
        # the grid: ink lines, the border a touch heavier
        for k in grid_n:
                var t := float(k) * cell + cell * 0.5
                var w := 2.0
                if k == 0 or k == grid_n - 1:
                        w = 3.5
                board_l.draw_line(
                        Vector2(g.position.x + cell * 0.5, g.position.y + t),
                        Vector2(g.end.x - cell * 0.5, g.position.y + t),
                        th["line"], w)
                board_l.draw_line(
                        Vector2(g.position.x + t, g.position.y + cell * 0.5),
                        Vector2(g.position.x + t, g.end.y - cell * 0.5),
                        th["line"], w)
        # the star points (the hoshi dots)
        for p in _star_points():
                board_l.draw_circle(_point_mid(int(p)), cell * 0.09,
                                th["line"])

## the four hoshi dots (+ the true center on odd boards)
func _star_points() -> Array:
        var n := grid_n
        var e := 2 if n <= 10 else 3
        var m := n - 1 - e
        var pts := [idx(e, e, n), idx(m, e, n), idx(e, m, n), idx(m, m, n)]
        if n % 2 == 1:
                pts.append(idx(n / 2, n / 2, n))
        return pts

func _point_mid(i: int) -> Vector2:
        var c := i / grid_n
        var r := i % grid_n
        return board_origin + Vector2(c * cell + cell * 0.5,
                        r * cell + cell * 0.5)

## the stones: settled + the fresh ones still settling (two-tone, gloss,
## a soft contact shadow)
func _draw_stones() -> void:
        var sk := _skin()
        var rad := cell * 0.40
        for i in board.size():
                var v: int = board[i]
                if v == 0:
                        continue
                var fresh := false
                for s in _stones:
                        if int(s["i"]) == i:
                                fresh = true
                                break
                var mid := _point_mid(i)
                var scale := 1.0
                if fresh:
                        # the settle: a tiny drop-bounce (the only anim)
                        var age: float = _time - float(s_t0(i))
                        scale = _settle_scale(age)
                _paint_stone(stone_l, mid, rad * scale,
                                sk["p1"] if v == 1 else sk["p2"])
        # the last-move marker (a small dot on the freshest stone)
        if _last_i >= 0 and int(board[_last_i]) != 0:
                var col: Color = sk["p2"] if int(board[_last_i]) == 1 \
                                else sk["p1"]
                stone_l.draw_circle(_point_mid(_last_i), rad * 0.16,
                                Color(col, 0.9))

var _last_i := -1

func s_t0(i: int) -> float:
        for s in _stones:
                if int(s["i"]) == i:
                        return float(s["t0"])
        return 0.0

## ease-out-back settle: pops to 1.12 then rests at 1.0
func _settle_scale(age: float) -> float:
        if age >= 0.26:
                return 1.0
        var f := age / 0.26
        var back := 1.0 + 1.9 * pow(f - 1.0, 3.0) + 0.9 * pow(f - 1.0, 2.0)
        # a small pop: 0.55 -> overshoot -> 1.0
        return clampf(0.55 + 0.45 * back * 1.0, 0.4, 1.18)

func _paint_stone(l: Node2D, mid: Vector2, rad: float, col: Color) -> void:
        var dark := col.darkened(0.45)
        var lite := col.lightened(0.22)
        # the contact shadow
        l.draw_circle(mid + Vector2(3, 5), rad, Color(0, 0, 0, 0.32))
        # the body: a lit face sliding into shade
        l.draw_circle(mid, rad, dark)
        l.draw_circle(mid + Vector2(-rad * 0.18, -rad * 0.20),
                        rad * 0.80, col)
        l.draw_circle(mid + Vector2(-rad * 0.30, -rad * 0.34),
                        rad * 0.42, lite)
        # the gloss
        l.draw_circle(mid + Vector2(-rad * 0.34, -rad * 0.42),
                        rad * 0.13, Color(1, 1, 1, 0.6))
        l.draw_arc(mid, rad - 1.2, 0, TAU, 40, Color(0, 0, 0, 0.25), 2.0)

func _draw_fx() -> void:
        var sk := _skin()
        # the aim ghost: a translucent stone on the nearest intersection
        if state == "play" and turn == 1 and aim_i >= 0:
                var rad := cell * 0.40
                var mid := _point_mid(aim_i)
                var pulse := 0.5 + 0.22 * sin(_time * 5.2)
                fx_l.draw_circle(mid, rad, Color(sk["p1"], 0.34))
                fx_l.draw_arc(mid, rad, 0, TAU, 32, Color(sk["p1"], 0.72), 3.0)
                fx_l.draw_arc(mid, rad * 1.18, 0, TAU, 32,
                                Color(1, 1, 1, 0.24 * pulse), 2.4)
        # the dust pips
        for p in _dust:
                var a: float = clampf(float(p["life"]) / float(p["max"]), 0.0, 1.0)
                var c: Color = p["col"]
                c.a = a * 0.85
                fx_l.draw_rect(Rect2(float(p["x"]) - float(p["s"]) * 0.5,
                                float(p["y"]) - float(p["s"]) * 0.5,
                                float(p["s"]), float(p["s"])), c)
        # the coin (the xo coin law)
        if coin_cell >= 0 and int(board[coin_cell]) == 0:
                var tex: Texture2D = load("res://assets/ui/coin.png")
                if tex != null:
                        var pos := _point_mid(coin_cell)
                        pos.y += sin(coin_t * 3.2) * cell * 0.06
                        var fade: float = clampf(coin_t / 0.4, 0.0, 1.0)
                        var s: float = cell * 0.5 / float(tex.get_width())
                        var pop: float = 1.0 + 0.07 * sin(coin_t * 4.4)
                        fx_l.draw_set_transform(pos, 0.0,
                                        Vector2(s * pop * fade,
                                        s / maxf(0.05, pop) * fade))
                        fx_l.draw_texture(tex,
                                        -Vector2(tex.get_width(),
                                        tex.get_height()) / 2.0,
                                        Color(1, 1, 1, fade))
                        fx_l.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
                        var ga: float = coin_t * 2.6
                        fx_l.draw_arc(pos, cell * 0.38, ga, ga + 1.1, 30,
                                        Color(1, 1, 1, 0.5 * fade), 2.2)

func _draw_strike() -> void:
        if last_win_line.is_empty() or strike_t <= 0.0:
                return
        var p0 := _point_mid(int(last_win_line[0]))
        var p1 := _point_mid(int(last_win_line[last_win_line.size() - 1]))
        var prog := clampf(strike_t, 0.0, 1.0)
        var pts := PackedVector2Array()
        var segs := 12
        for k in segs + 1:
                var f := float(k) / float(segs)
                if f <= prog:
                        pts.append(p0.lerp(p1, f))
        if pts.size() >= 2:
                strike_l.draw_polyline(pts, Color("ffb020", 0.95), 10.0, true)

func _layout(vp: Vector2) -> void:
        var top := 190.0
        var bot := banner_bottom() + 40.0
        # THE SLAB FIT LAW: the slab (grid + the 0.42 pads) stays inside
        # the screen - the wood never kisses the edges
        cell = minf((vp.x - 36.0) / float(grid_n + 0.84),
                        (vp.y - top - bot) / float(grid_n + 0.84))
        cell = minf(cell, 112.0)
        cell = maxf(cell, 34.0)
        var side := float(grid_n) * cell
        var spare := vp.y - top - bot - side
        board_origin = Vector2((vp.x - side) * 0.5,
                        top + maxf(0.0, spare * 0.40))
        _place_texts(vp)
        bg_l.queue_redraw()
        board_l.queue_redraw()
        stone_l.queue_redraw()

## the turn + verdict texts seat once, from layout AND from build
func _place_texts(vp: Vector2) -> void:
        var side := float(grid_n) * cell
        if turn_lbl != null:
                turn_lbl.position = Vector2(0, board_origin.y - 94.0)
                turn_lbl.custom_minimum_size = Vector2(vp.x, 44)
        if verdict_lbl != null:
                verdict_lbl.position = Vector2(0,
                                board_origin.y + side + cell * 0.42 + 20.0)
                verdict_lbl.custom_minimum_size = Vector2(vp.x, 50)

# ------------------------------------------------- the W/D/L cards + text

func _build_widgets(vp: Vector2) -> void:
        # THE W-D-L CARDS (the dominoes widget verbatim, the seat law)
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
        # THE GATE LAW (v0.3.8-8): index 0 of the HUD - under the sheets
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
        _new_board()
        _stones = []
        _dust = []
        _last_i = -1
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
        # THE COIN LAW: after every 3 completed rounds the next round
        # opens with a GOGACoin on an EMPTY intersection - the stone
        # placed there takes it (the CPU races you)
        coin_cell = -1
        coin_t = 0.0
        if done_rounds > 0 and done_rounds % COIN_EVERY == 0:
                coin_cell = _random_empty_cell()
        # THE STATE LAW (v0.3.9-1): _new_round is the round's ONLY door -
        # the gate tap and the round-over advance both walk through it, so
        # it seats the state machine whole. The launch build left the
        # state wherever the caller stood ("ready" after the gate,
        # "round_over" after a verdict) and every tap/lift handler
        # early-returned - the owner played a board that could not be
        # touched. The rigs never caught it because they all set
        # state="play" by hand after _new_round (THE MASK LAW).
        if turn == 1:
                state = "play"      # the player opens: the board is live
        else:
                state = "wait"      # the CPU opens: it thinks, then places
                cpu_think = true
                think_beat = _rng.randf_range(0.4, 0.8)
        _banner()
        board_l.queue_redraw()
        stone_l.queue_redraw()

func _random_empty_cell() -> int:
        var empties := []
        for i in board.size():
                if int(board[i]) == 0:
                        empties.append(i)
        if empties.is_empty():
                return -1
        return int(empties[_rng.randi() % empties.size()])

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
                        _tap(t.position)
                else:
                        _lift(t.position)
        elif event is InputEventScreenDrag:
                if state == "play" and turn == 1:
                        _aim_at((event as InputEventScreenDrag).position)
        elif event is InputEventMouseMotion:
                if state == "play" and turn == 1:
                        _aim_at((event as InputEventMouseMotion).position)
        elif event is InputEventMouseButton:
                var mb := event as InputEventMouseButton
                if mb.pressed:
                        if state == "ready":
                                _gate_down()
                                _new_round()
                                return
                        _tap(mb.position)
                else:
                        _lift(mb.position)

## the finger slides - the ghost rides the nearest intersection
func _aim_at(at: Vector2) -> void:
        if state != "play" or turn != 1:
                return
        aim_i = _nearest_point(at)

## the tap commits on the PRESS (the snappiest read for a tap game):
## the ghost's real life is the SLIDE - a finger gliding across the
## points previews every placement before it commits
func _tap(at: Vector2) -> void:
        if state != "play" or turn != 1:
                return
        _aim_at(at)
        _lift(at)

func _lift(_at: Vector2) -> void:
        if state != "play" or turn != 1:
                return
        if aim_i < 0:
                return
        if int(board[aim_i]) != 0:
                Jukebox.sfx("bv_denied", -8.0)
                aim_i = -1
                return
        var i := aim_i
        aim_i = -1
        _place(i, 1)

func _nearest_point(at: Vector2) -> int:
        var g := _grid_rect()
        if at.x < g.position.x - cell * 0.42 \
                        or at.x > g.end.x + cell * 0.42 \
                        or at.y < g.position.y - cell * 0.42 \
                        or at.y > g.end.y + cell * 0.42:
                return -1
        var c := clampi(int(round((at.x - g.position.x) / cell - 0.5)), 0,
                        grid_n - 1)
        var r := clampi(int(round((at.y - g.position.y) / cell - 0.5)), 0,
                        grid_n - 1)
        return idx(c, r, grid_n)

func _place(i: int, who: int) -> void:
        board[i] = who
        _last_i = i
        _stones.append({"i": i, "t0": _time})
        Jukebox.sfx("bv_stone", -4.0, 1.0 + _rng.randf() * 0.06)
        _dust_burst(_point_mid(i),
                        _skin()["p1"] if who == 1 else _skin()["p2"], 6)
        state = "wait"
        turn_lbl.text = ""
        # the live fork spy (feeds the memory's fork flag)
        if who == 1 and five_cells(board, grid_n, 1).size() >= 2:
                cur["fork"] = true
        # THE COIN RACE: whoever lands there TAKES it
        if coin_cell >= 0 and i == coin_cell:
                _coin_taken(who)
        var w := winner_of(board, grid_n)
        if w != 0:
                _resolve(w)      # the stone rests - the verdict is now
                return
        if who == 1:
                turn = 2
                cpu_think = true
                think_beat = _rng.randf_range(0.4, 0.8)
                clock = 0.0
                _banner()
        else:
                turn = 1
                state = "play"
                _banner()

func _ai_move() -> void:
        var rng := RandomNumberGenerator.new()
        rng.seed = int(Time.get_unix_time_from_system() * 1000.0) \
                        ^ (rounds * 7919) ^ (board.hash() & 0xffff)
        var i := cpu_pick(board, grid_n, profile, mem, rng)
        if i >= 0:
                # the reply bookkeeping (the xo law)
                if cur["open"] >= 0 and cur["reply"] < 0:
                        cur["reply"] = i
                _place(i, 2)

# ============================================================ the verdict

func _resolve(w: int) -> void:
        state = "round_over"
        clock = 0.0
        cur["result"] = w
        done_rounds += 1
        if w == 1 or w == 2:
                last_win_line = win_line(board, grid_n)
        if w == 1:
                wins += 1
                streak += 1
                add_score(1)                     # THE OWNER'S LAW: win = +1
                verdict_lbl.text = "YOU WIN  +1"
                verdict_lbl.add_theme_color_override("font_color",
                                Color("7ee2a0"))
                Jukebox.sfx("bv_win", -3.0)
                achievement_count("wins", 1)
                achievement_max("streak", streak)
                if last_win_line.size() == 5:
                        var mid := (_point_mid(int(last_win_line[0]))
                                        + _point_mid(int(last_win_line[4]))) * 0.5
                        Arc.confetti(_overlay_root_ref(), mid, 30)
        elif w == 2:
                losses += 1
                streak = 0
                if score > 0:
                        add_score(-1)
                verdict_lbl.text = "CPU WINS  -1"
                verdict_lbl.add_theme_color_override("font_color",
                                Color("f2a09a"))
                Jukebox.sfx("bv_lose", -3.0)
        else:
                draws += 1
                add_score(0)
                verdict_lbl.text = "THE BOARD IS FULL - DRAW"
                verdict_lbl.add_theme_color_override("font_color",
                                Color("c8cdd4"))
                Jukebox.sfx("bv_draw", -4.0)
        # THE OPENER LAW: the loser starts next; a draw flips
        if w == 1:
                next_opener = 2
        elif w == 2:
                next_opener = 1
        else:
                next_opener = 2 if last_opener == 1 else 1
        if last_win_line.size() == 5:
                strike_t = 0.0
        achievement_max("max_score", score)
        mem = remember(mem, cur)
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
                # the settle window: the player's stone must land before
                # the state unlocks (the CPU think already rides it)
                if not cpu_think and _pending_resolve == 0 \
                                and state == "wait" and not _stones_fresh():
                        state = "play"
        elif state == "round_over":
                clock += delta
                if strike_t < 1.0:
                        strike_t = minf(1.0, strike_t + delta * 3.0)
                        strike_l.queue_redraw()
                if clock >= 1.9:
                        _new_round()
        # retire the settle entries past their window
        for s in _stones.duplicate():
                if _time - float(s["t0"]) > 0.3:
                        _stones.erase(s)
        coin_t += delta
        stone_l.queue_redraw()
        fx_l.queue_redraw()
        board_l.queue_redraw()

## is the freshest stone still inside its settle window?
func _stones_fresh() -> bool:
        for s in _stones:
                if _time - float(s["t0"]) <= 0.28:
                        return true
        return false

# ------------------------------------------------------------ dust + coin

func _dust_burst(at: Vector2, col: Color, n := 6) -> void:
        for i in n:
                _dust.append({
                        "x": at.x + _rng.randf_range(-cell * 0.2, cell * 0.2),
                        "y": at.y + _rng.randf_range(-cell * 0.1, cell * 0.12),
                        "vx": _rng.randf_range(-80.0, 80.0),
                        "vy": _rng.randf_range(-120.0, -20.0),
                        "life": _rng.randf_range(0.26, 0.46),
                        "max": 0.46,
                        "s": _rng.randf_range(2.0, 4.5),
                        "col": col,
                })
        if _dust.size() > 120:
                _dust = _dust.slice(_dust.size() - 120)

func _coin_taken(who: int) -> void:
        coin_cell = -1
        if who == 1:
                add_run_coins(1)
                Jukebox.sfx("bv_coin", -3.0)
                game_toast("YOU TOOK THE GOGACOIN  +1")
                _dust_burst(_point_mid(_last_i), Color("ffd24a"), 14)
        else:
                Jukebox.sfx("coin", -6.0, 0.8)
                game_toast("THE CPU GRABBED THE COIN")

# ============================================================ the options
## THE BOARD SIZES (the 2048 mechanic word for word): the options sheet
## is a PICKER, not a shop - owned sizes show SWITCH (with the
## are-you-sure), locked sizes are LOCKED and their tap walks to the
## SHOP. The confirm is stack-borne; a YES pops the STALE sheet under it
## and a FRESH one reads the applied board (the v0.3.8-8 fresh-sheet law).

func _options_open() -> void:
        var sheet := sheet_push(0.0, "options")
        var t := Arc.label("FIVE IN ROW OPTIONS", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var hint := Arc.fit_label("a bigger board holds a bigger game - "
                + "switching starts a fresh board", 19, Arc.HOT, 560)
        hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(hint)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.46, 260.0, 540.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        for id in SIZES:
                box.add_child(_size_row(id))
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                        func(): sheet_pop()))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

## the row: THE BUY LAW (v0.3.9-1, the owner: "it should be bought only
## from shop, never applied from it, the options menu is where this
## happens") - the SHOP only SELLS: a locked size's BUY takes the coins
## and stops there (no confirm, no apply); an owned size reads OWNED and
## points at the options. The OPTIONS is the picker: owned sizes SWITCH
## behind the are-you-sure, locked ones walk to the shop.
func _size_row(id: String, in_shop := false) -> Control:
        var sz: Dictionary = SIZES[id]
        var owned := Box.item_owned(game_id, "size", id) or int(sz["price"]) == 0
        var on := size_id == id
        var head := Arc.label("%s%s - %s" % [sz["name"], "  (ON)" if on else "",
                        sz["desc"]], 19,
                        Color("58c470") if on else Arc.INK, false)
        head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        head.custom_minimum_size = Vector2(560, 0)
        head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 2)
        v.add_child(head)
        if on:
                return v
        if owned:
                if in_shop:
                        # THE BUY LAW: the shop never applies - the owned
                        # size just points home
                        var ol := Arc.fit_label(
                                        "OWNED - APPLY IT FROM THE OPTIONS",
                                        20, Color("58c470"), 560)
                        ol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        v.add_child(ol)
                        return v
                v.add_child(Arc.button("SWITCH", Vector2(560, 56), 22,
                                Color("4a5ab8"), func(): _size_confirm(id)))
                return v
        if not in_shop:
                var lk := Arc.button("LOCKED - %d IN THE SHOP" % int(sz["price"]),
                                Vector2(560, 56), 20, Color(0.55, 0.48, 0.38),
                                func():
                                        sheet_pop()      # the options step aside
                                        _shop_open())    # the shop answers
                v.add_child(lk)
                return v
        var b := Arc.coin_button("BUY  %d" % int(sz["price"]),
                        Vector2(560, 56), 22, Color("4a5ab8"), func():
                                        if Box.buy_item(game_id, "size", id,
                                                        int(sz["price"])):
                                                Jukebox.sfx("buy")
                                                _toast_show("%s IS YOURS - APPLY IT FROM THE OPTIONS"
                                                                % String(sz["name"]).to_upper())
                                        else:
                                                Jukebox.sfx("error", -6.0)
                                                _toast_show("need %d more GOGACoins"
                                                                % (int(sz["price"])
                                                                - Box.coins()))
                                        _shop_reopen())
        if Box.coins() < int(sz["price"]):
                b.disabled = true
        v.add_child(b)
        return v

## THE ARE-YOU-SURE SHEET (the 2048 law): the confirm PUSHES on top of
## whatever is live. YES pops it, pops the stale options sheet under it
## and applies the board (the v0.3.8-8 fresh-sheet law). It exists in the
## OPTIONS only - the shop buys, it never applies (THE BUY LAW).
func _size_confirm(id: String) -> void:
        if _confirm_open_id != "":
                sheet_pop()          # a confirm is already up - replace it
        _confirm_open_id = id
        var sheet := sheet_push(0.0, "confirm")
        var sz: Dictionary = SIZES[id]
        var t := Arc.label("SWITCH TO %s?" % String(sz["name"]).to_upper(),
                        32, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var w := Arc.fit_label("switching starts a fresh board -\nthe current round is wiped",
                        22, Arc.HOT, 560)
        w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(w)
        sheet.add_child(Arc.button("YES - SWITCH", Vector2(560, 84), 28,
                        Arc.GOOD, func():
                        sheet_pop()                      # the confirm dies first
                        _confirm_open_id = ""
                        if sheet_open_count() > 0:
                                sheet_pop()              # the stale sheet too
                        Box.equip_item(game_id, "size", id)
                        Jukebox.sfx("confirm", -4.0)
                        _apply_size(id)
                        _options_open()))                # a FRESH options sheet
                                                         # reads the board (ON)
        sheet.add_child(Arc.button("NO", Vector2(560, 74), 26, Arc.BAD, func():
                        sheet_pop()
                        _confirm_open_id = ""))

## the applied board: rebuild the grid, start a fresh round
func _apply_size(id: String) -> void:
        size_id = id
        grid_n = int(id)
        _new_board()
        _stones = []
        _last_i = -1
        last_win_line = []
        strike_t = 1.0
        aim_i = -1
        if state == "ready":
                _layout(get_viewport_rect().size)
                return
        _layout(get_viewport_rect().size)
        _new_round()

# ============================================================ the shop
## DIRECT (the chess law): stone skins + themes + the locked sizes,
## everything but the defaults bought.

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
        var t := Arc.label("FIVE IN ROW SHOP", 34, Arc.INK)
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
        box.add_child(_shop_label("STONES - the pair you hold"))
        for id in SKINS:
                box.add_child(_skin_row(id))
        box.add_child(_shop_label("BOARDS - the slab and the room"))
        for id in THEMES:
                box.add_child(_theme_row(id))
        box.add_child(_shop_label("BOARD SIZES - bigger boards, bought first"))
        for id in SIZES:
                box.add_child(_size_row(id, true))
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                        func(): sheet_pop()))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _goga_sheet_popped(id: String) -> void:
        if id == "options":
                get_tree().paused = false
                paused = false
        elif id == "confirm":
                _confirm_open_id = ""
                get_tree().paused = false
                paused = false
        elif id == "shop":
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
                return Arc.button("%s - HOLD THESE" % c["name"],
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

func probe_reset(seed_v: int, n := 8) -> void:
        _rng.seed = seed_v
        _gate_down()
        size_id = str(n)
        grid_n = n
        _new_board()
        _stones = []
        _dust = []
        _last_i = -1
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
        aim_i = -1
        paused = true
        _layout(get_viewport_rect().size)
        _new_round()
        state = "play"
        turn = 1

func probe_step(dt: float) -> void:
        _goga_tick(dt)
