extends GogaGame
## SQUARES - v0.3.9-4, the dots-and-boxes classic (graduated v0.3.9-3; the
## teaser DOTS was renamed SQUARES by the owner's order; the brain's
## honest ancestor is KDE's KSquares - draw lines between the dots, close
## a box to claim it, close one and you go again, most boxes wins).
##
## Owner round v0.3.9-4 (the test report):
##   - THE GUIDE LATTICE: the board "looks blank with dots, not with the
##     lines that shows where a thing should go" - every edge now wears
##     a visible GRAY dashed guide (the old paper-grain stripes were the
##     "literally invisible" lines the owner reported; they are gone)
##   - THE OUTLINE LAW: "the ones at the edge are supposed to be literally
##     at the board outlines for real as same as KSquares" - the slab rim
##     is a thin breathing margin now, the outer dots sit ON the outline,
##     and the outer edge ring reads as the board's own frame
##   - THE LIVING LAYER: "after each drawn line, the animations moves a
##     frame" - the box wash only repainted when the next line landed
##     (an event-driven layer under a time-based fade); the tick repaints
##     every animated layer now, the fades breathe on their own
##   - THE TALLY SEAT: the squares widget lives UNDER the goals cards
##     (not beside them) and the D panel is GONE - "this game has no
##     draws as i told you" - the goals row reads W | L only
##
## Owner contract (v0.3.9-3):
##   - VERTICAL ONLY (the xo law: no position ask, no horizontal table)
##   - the colors are FIXED: the user is RED, the enemy is BLUE - not for
##     sale, not a skin (the owner: "user will be red and enemy will be
##     blue")
##   - the shop wears THEMES ONLY (the owner: "no skins") + the 3 board
##     sizes bought from it - the OPTIONS applies them (the 2048 mechanic
##     word for word, THE BUY LAW: the shop sells, the options applies)
##   - the economy (the owner: "a lose takes 1 score point and score bonus
##     will be /2"): win +1, loss -1 (score never negative), run bonus /2
##     (registry coin_div 2)
##   - NO DRAWS (the owner: "winner who has more squares, loser who has
##     less, no draw situation here") - enforced by ARITHMETIC: every
##     board wears an ODD box total (9 / 25 / 49), a tie cannot exist
##   - THE SQUARES WIDGET (the owner's seat law): "a widget for this game
##     before the goals one right after the score one to show red square
##     and nn and next to it blue square and nn" - RED nn | BLUE nn, live
##   - a GOGACoin rests inside a box after every 3 completed rounds -
##     whoever CLAIMS that box takes it (the CPU races you)
##   - THE KSQUARES LAW: close a box and you go AGAIN (the chain engine)
##   - THE LINE'S LIFE (the owner, verbatim): "the line will be first
##     fade-in with smooth alpha level modification to match the color of
##     the player then after it completes this part, it will smoothly
##     transform the color to normal black, make sure it is smooth and
##     fast but not very 'instant'" - phase A fades the player's color in,
##     phase B dries it into the board ink; a claimed square fades its
##     owner's color in the same way
##   - THE HOLD LAW (the owner, verbatim): "when i hold at somewhere, it
##     will apply the standby semi-transparent line and when move the
##     finger, the line will follow me to the nearest edge, when released
##     it will get applied, if the finger went out of board, it's
##     canceled" - the standby is DASHED and translucent ("striped or...
##     that thing where they are like alpha"), press/drag/release, and a
##     release outside the board places nothing
##   - TAP ANYWHERE TO START (the chess gate, HUD index 0), pause_end_run
##     (the pong END bank)
##   - ONE opponent, FOUR moods (the xo rotation) with programmed failures
##     everywhere (the blind-spot law: challenging, always beatable), and
##     THE CHAIN-SCAR MEMORY (the 2-round window): lose a round where the
##     player swallowed a chain of 4+ in one breath and the double-cross
##     eye stays WIDE for the window - the CPU learns the way it lost
##
## Probe contract: the whole CPU core is STATIC - idx_h / idx_v /
## box_edges / edge_boxes / box_sides / closers / safe_edges / greedy_run
## / hands_run / winner_of / cpu_pick / remember / adapt drive headless
## laws without the scene (the bovo contract). The scene rides
## probe_reset(seed, dots) + probe_step(dt).

const COIN_EVERY := 3      # owner: one GOGACoin after each 3 rounds
const MEM_ROUNDS := 2      # the xo memory law (the chain-scar window)

# ------------------------------------------------- the fixed ink + pens
## THE OWNER'S PENS: red is the user's, blue is the enemy's. Nobody buys
## a pen here (the shop has no skins - the owner's word).
const RED_P := Color("e0533f")
const BLUE_P := Color("4179df")

# --------------------------------------------------- the line's two lives
## THE COLOR FADE LAW: phase A fades the color in (alpha 0 -> 1), phase B
## dries the color into the board ink. Smooth and fast, never instant.
const LINE_A := 0.16
const LINE_B := 0.26       # on top of A (the dry-down)
const BOX_A := 0.26        # the claimed square's fade-in

# ------------------------------------------------------------- the boards
## THE BOARD SIZES (the owner's ladder, the no-draw arithmetic: every box
## total is ODD so a tie cannot exist). 4x4 dots is the free normal game;
## 6x6 and 8x8 are SHOP items bought first (the 2048 mechanic).
const SIZES := {
        "4": {"name": "4 x 4 DOTS", "price": 0,
                "desc": "9 boxes - the tight tactical board"},
        "6": {"name": "6 x 6 DOTS", "price": 1800,
                "desc": "25 boxes - the wide board"},
        "8": {"name": "8 x 8 DOTS", "price": 3600,
                "desc": "49 boxes - the monster board"},
}

# ------------------------------------------------------------- the shop
## 5 paper themes - the ONLY merchandise besides the sizes (the owner:
## "a shop but for themes only, no skins").
const THEMES := {
        "paper": {"name": "PAPER", "price": 0,
                "board": Color("f3ecd9"), "board_dark": Color("e0d4b8"),
                "line": Color("3a2c1a"), "room": Color("2c2416"),
                "floor": Color("241d11"),
                "desc": "the warm notebook page"},
        "kraft": {"name": "KRAFT", "price": 220,
                "board": Color("d9b98c"), "board_dark": Color("c4a271"),
                "line": Color("4a3319"), "room": Color("2e2214"),
                "floor": Color("251a0e"),
                "desc": "the brown wrapping paper"},
        "ocean": {"name": "OCEAN", "price": 280,
                "board": Color("cfe3df"), "board_dark": Color("b2cfc9"),
                "line": Color("1f4d44"), "room": Color("10262a"),
                "floor": Color("0c1e21"),
                "desc": "the sea-green page"},
        "midnight": {"name": "MIDNIGHT", "price": 340,
                "board": Color("23283a"), "board_dark": Color("1a1e2d"),
                "line": Color("9db1d6"), "room": Color("0b0f1c"),
                "floor": Color("080b14"),
                "desc": "the midnight chalkboard"},
        "marble": {"name": "MARBLE", "price": 420,
                "board": Color("e8e6e1"), "board_dark": Color("cfccc4"),
                "line": Color("4a4f5e"), "room": Color("23252d"),
                "floor": Color("1b1d24"),
                "desc": "the cold polished page"},
}

# ------------------------------------------------------------- the profiles
## THE FOUR MOODS (the xo law: invisible rotation, one name).
##   miss_take - the chance it fails to SEE an immediate capture (the
##               whole capture set goes blind for the turn)
##   err_safe  - the chance it fails to find a safe edge while one exists
##   chain_iq  - the double-cross eye (all-but-two) - and the concede
##               hand that hands over the SHORTEST chain
##   noise     - the feel jitter (the same board never plays the same)
const PROFILES := {
        "wall": {
                "miss_take": 0.09, "err_safe": 0.10, "chain_iq": 0.35,
                "noise": 40.0, "w_center": 1.0,
        },
        "trick": {
                "miss_take": 0.08, "err_safe": 0.12, "chain_iq": 0.75,
                "noise": 70.0, "w_center": 0.9,
        },
        "rusher": {
                "miss_take": 0.11, "err_safe": 0.14, "chain_iq": 0.55,
                "noise": 95.0, "w_center": 1.1,
        },
        "sage": {
                "miss_take": 0.07, "err_safe": 0.09, "chain_iq": 0.65,
                "noise": 60.0, "w_center": 1.0,
        },
}

# ============================================================ THE CPU CORE
## Static so tests (flow_test + the probes) drive the brain without the
## scene - the bovo contract. The board is flat arrays: edges[i] is
## 0 (undrawn) / 1 (red) / 2 (blue); boxes[b] the same. d = dots per side.

## a horizontal edge: dot (c,r) -> dot (c+1,r)
static func idx_h(c: int, r: int, d: int) -> int:
        return r * (d - 1) + c

## a vertical edge: dot (c,r) -> dot (c,r+1)
static func idx_v(c: int, r: int, d: int) -> int:
        return d * (d - 1) + c * (d - 1) + r

static func edges_total(d: int) -> int:
        return 2 * d * (d - 1)

static func boxes_total(d: int) -> int:
        return (d - 1) * (d - 1)

static func box_id(bc: int, br: int, d: int) -> int:
        return bc * (d - 1) + br

## the 4 edges of box (bc,br): top, bottom, left, right
static func box_edges(bc: int, br: int, d: int) -> Array:
        return [idx_h(bc, br, d), idx_h(bc, br + 1, d),
                        idx_v(bc, br, d), idx_v(bc + 1, br, d)]

## the boxes an edge touches (1 on the rim, 2 inside)
static func edge_boxes(i: int, d: int) -> Array:
        var out := []
        var hb := d * (d - 1)
        if i < hb:
                var c := i % (d - 1)
                var r := i / (d - 1)
                if r - 1 >= 0:
                        out.append(box_id(c, r - 1, d))
                if r <= d - 2:
                        out.append(box_id(c, r, d))
        else:
                var j := i - hb
                var c := j / (d - 1)
                var r := j % (d - 1)
                if c - 1 >= 0:
                        out.append(box_id(c - 1, r, d))
                if c <= d - 2:
                        out.append(box_id(c, r, d))
        return out

static func box_sides(edges: Array, b: int, d: int) -> int:
        var bc := b / (d - 1)
        var br := b % (d - 1)
        var n := 0
        for e in box_edges(bc, br, d):
                if int(edges[e]) != 0:
                        n += 1
        return n

## every undrawn edge that closes at least one box RIGHT NOW
static func closers(edges: Array, d: int) -> Array:
        var out := []
        for i in edges.size():
                if int(edges[i]) != 0:
                        continue
                for b in edge_boxes(i, d):
                        if box_sides(edges, b, d) == 3:
                                out.append(i)
                                break
        return out

## every undrawn edge that leaves NO box at three sides (the safe feel)
static func safe_edges(edges: Array, d: int) -> Array:
        var out := []
        for i in edges.size():
                if int(edges[i]) != 0:
                        continue
                var safe := true
                for b in edge_boxes(i, d):
                        if box_sides(edges, b, d) == 2:
                                safe = false
                                break
                if safe:
                        out.append(i)
        return out

## the eater's run from THIS position when it never stops:
## n = boxes that fall, e = the close edges in order, left = undrawn after
static func greedy_run(edges_in: Array, d: int) -> Dictionary:
        var e := edges_in.duplicate()
        var seq := []
        while true:
                var cl := closers(e, d)
                if cl.is_empty():
                        break
                var pick: int = cl[0]
                e[pick] = 3      # the neutral eater
                seq.append(pick)
        var left := 0
        for i in e.size():
                if int(e[i]) == 0:
                        left += 1
        return {"n": seq.size(), "e": seq, "left": left}

## how many boxes the OPPONENT swallows if I draw e and then sit on my
## hands (the concede hand reads this - hand over the SHORTEST chain)
static func hands_run(edges: Array, d: int, e: int) -> int:
        var b := edges.duplicate()
        b[e] = 3
        return int(greedy_run(b, d)["n"])

## 0 = boxes still open, 1 = red, 2 = blue, 3 is never returned (the odd
## box totals make a tie impossible - the no-draw law is arithmetic)
static func winner_of(boxes: Array) -> int:
        var red := 0
        var blue := 0
        for v in boxes:
                if int(v) == 1:
                        red += 1
                elif int(v) == 2:
                        blue += 1
        if red + blue < boxes.size():
                return 0
        return 1 if red > blue else 2

## THE MEMORY LAW (the xo law, the squares dialect): the record is the
## player's biggest chain of the round + the result
static func remember(mem_in: Array, record: Dictionary) -> Array:
        var m := mem_in.duplicate()
        m.append({
                "streak": int(record.get("streak", 0)),
                "result": int(record.get("result", 0)),
        })
        while m.size() > MEM_ROUNDS:
                m.pop_front()
        return m

## WHAT THE MEMORY REMEMBERS - THE CHAIN SCAR: a round the CPU lost while
## the player swallowed a chain of 4+ in one breath keeps the double-cross
## eye WIDE for the whole window
static func adapt(mem_in: Array) -> Dictionary:
        var out := {"alert": false}
        for e in mem_in:
                if int(e["result"]) == 2 and int(e["streak"]) >= 4:
                        out["alert"] = true
        return out

## the quiet center pull for one edge (the feel)
static func _feel(i: int, d: int) -> float:
        var hb := d * (d - 1)
        var mid := float(d - 1) * 0.5
        var m := Vector2.ZERO
        if i < hb:
                m = Vector2(float(i % (d - 1)) + 0.5,
                                float(i / (d - 1)))
        else:
                var j := i - hb
                m = Vector2(float(j / (d - 1)),
                                float(j % (d - 1)) + 0.5)
        return 1.0 - (absf(m.x - mid) + absf(m.y - mid)) / float(d)

## THE MOVE PIPELINE (the xo pipeline on an edge board):
##   1. take an immediate capture (a small miss chance blinds the whole
##      capture set - THE DOUBLE-CROSS EYE rides here: with exactly two
##      boxes about to fall and a next chain waiting after them, the eye
##      plays the LAST close edge instead and hands both boxes over so
##      the player must open the next chain)
##   2. play a safe edge (a small error chance blinds the safe set)
##   3. concede the SHORTEST chain (or fumble blind)
static func cpu_pick(edges_in: Array, d: int, profile_id: String,
                alert: bool, rng: RandomNumberGenerator) -> int:
        var edges := edges_in
        var p: Dictionary = PROFILES[profile_id]
        var eye := float(p["chain_iq"])
        if alert:
                eye = maxf(eye, 0.92)
        var undrawn := []
        for i in edges.size():
                if int(edges[i]) == 0:
                        undrawn.append(i)
        if undrawn.is_empty():
                return -1

        # 1. the capture is RIGHT THERE - almost always taken
        var cl := closers(edges, d)
        var blinded := {}
        if not cl.is_empty():
                if rng.randf() >= float(p["miss_take"]):
                        var run := greedy_run(edges, d)
                        if int(run["n"]) == 2 and int(run["left"]) > 0 \
                                        and rng.randf() < eye:
                                return int(run["e"][1])
                        return int(cl[rng.randi() % cl.size()])
                # THE BLIND SPOT: the whole capture set stays unseen THIS
                # turn - the safe feel and the concede pool never leak it
                for e in cl:
                        blinded[e] = true
                cl = []

        # 2. the safe feel: no box reaches three sides on our watch
        var safe := safe_edges(edges, d)
        if not safe.is_empty():
                if rng.randf() >= float(p["err_safe"]):
                        var best := -INF
                        var picks := []
                        for i in safe:
                                if blinded.has(i):
                                        continue
                                var s := _feel(i, d) \
                                                * float(p["w_center"]) \
                                                + rng.randf() \
                                                * float(p["noise"])
                                if s > best + 0.0001:
                                        best = s
                                        picks = [i]
                                elif absf(s - best) <= 0.0001:
                                        picks.append(i)
                        if not picks.is_empty():
                                return int(picks[rng.randi()
                                                % picks.size()])
                safe = []    # THE ERROR: the safe set stays unseen

        # 3. the concession: hand the SHORTEST chain (the smart hand)
        var seen := {}
        for e in blinded:
                seen[e] = true
        for e in safe:
                seen[e] = true
        var cands := []
        for i in undrawn:
                if not seen.has(i):
                        cands.append(i)
        if cands.is_empty():
                cands = undrawn
        var best_h := 999999
        var give := []
        for i in cands:
                var h := hands_run(edges, d, i) \
                                + int(rng.randf() * 2.0)
                if h < best_h:
                        best_h = h
                        give = [i]
                elif h == best_h:
                        give.append(i)
        return int(give[rng.randi() % give.size()])

static func profile_next(i: int) -> Array:
        return [PROFILES.keys()[i % PROFILES.size()], i + 1]

# ============================================================ state
var edges: Array = []
var boxes: Array = []
var dots_n := 4                 # THE BOARD SIZE (the equipped SIZES key)
var size_id := "4"              # the equipped size key (SIZES)
var turn := 1
var state := "ready"            # ready | play | wait | round_over
var clock := 0.0
var think_beat := 0.0
var cpu_think := false
var rounds := 0
var done_rounds := 0
var wins := 0
var losses := 0
var draws := 0                  # kept for the framework's sake - no draws
                                # can exist here (the D card is gone)
var streak := 0

# the chain-scar memory (the xo law)
var mem: Array = []

# the opener law (the xo law)
var next_opener := 1
var last_opener := 1

# the coin race
var coin_box := -1
var coin_t := 0.0

# the round's profile
var profile_order: Array = ["wall", "trick", "rusher", "sage"]
var profile_i := 0
var profile := "sage"

# the chains: boxes taken in one continuous breath (the KSquares law's
# shadow) - the player's best feeds the memory's scar
var chain_streak := 0
var player_best_streak := 0

# the round-over glow sweep (the winner's boxes breathe once)
var glow_t := -1.0

# the 2048 confirm law (stack-borne, the fresh-sheet rule)
var _confirm_open_id := ""

# scene
var world: Node2D
var bg_l: Node2D
var board_l: Node2D
var box_l: Node2D
var line_l: Node2D
var fx_l: Node2D
var turn_lbl: Label
var verdict_lbl: Label
var squares_row: Control        # THE SQUARES WIDGET (RED nn | BLUE nn)
var goals_row: Control
var ready_ui: Control = null
var cell := 90.0
var board_origin := Vector2.ZERO
var _time := 0.0
var _rng := RandomNumberGenerator.new()

# the hand: the standby line (THE HOLD LAW)
var holding := false
var ghost_edge := -1

# the fades (identity-keyed: edge id / box id -> t0)
var line_anim := {}
var box_anim := {}
var _dust: Array = []

# ============================================================ the scene

func _goga_setup() -> void:
        _rng.randomize()
        pause_end_run = true    # THE PONG LAW: the pause END banks
        size_id = "4"
        var on := Box.item_on(game_id, "size")
        if SIZES.has(on):
                size_id = on
        dots_n = int(size_id)
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
        box_l = Node2D.new()
        box_l.draw.connect(_draw_boxes)
        world.add_child(box_l)
        line_l = Node2D.new()
        line_l.draw.connect(_draw_lines)
        world.add_child(line_l)
        fx_l = Node2D.new()
        fx_l.z_index = 5
        fx_l.draw.connect(_draw_fx)
        world.add_child(fx_l)
        _layout(vp)
        _build_widgets(vp)
        _load_meta()
        # THE HUD SEAT LAW (v0.3.9-1): the flow seats in call order -
        # the SHOP next to the back button, the OPTIONS at the right side
        add_hud_button("SHOP", func(): _shop_open())
        add_hud_button("OPTIONS", func(): _options_open())
        Jukebox.music("res://assets/audio/music/sq_theme.wav")
        _build_ready()

func _new_board() -> void:
        edges = []
        for i in edges_total(dots_n):
                edges.append(0)
        boxes = []
        for i in boxes_total(dots_n):
                boxes.append(0)
        line_anim = {}
        box_anim = {}
        ghost_edge = -1
        holding = false
        chain_streak = 0
        player_best_streak = 0

func _theme() -> Dictionary:
        var tid := Box.item_on(game_id, "theme")
        if not THEMES.has(tid):
                tid = "paper"
        return THEMES[tid]

func _load_meta() -> void:
        _theme()
        bg_l.queue_redraw()
        board_l.queue_redraw()
        box_l.queue_redraw()
        line_l.queue_redraw()

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

## v0.3.9-4 THE OUTLINE LAW: the rim is a THIN breathing margin - the
## outer dots sit literally ON the board's outlines (the owner: "the ones
## at the edge are supposed to be literally at the board outlines for
## real as same as KSquares ... making it to be like literal outlines
## will feel more cooler"). The old 0.42-cell pad pushed the lattice
## inward - gone.
func _slab_rim() -> float:
        return maxf(10.0, cell * 0.14)

func _slab_rect() -> Rect2:
        var span := float(dots_n - 1) * cell
        var rim := _slab_rim()
        return Rect2(board_origin - Vector2(rim, rim),
                        Vector2(span + rim * 2.0, span + rim * 2.0))

## THE BOARD: the paper slab + THE GUIDE LATTICE + the ink dots. The
## owner (v0.3.9-4): "the board looks blank with dots, not with the lines
## that shows where a thing should go" - every edge wears a visible GRAY
## dashed guide (striped + alpha, the owner's own taste), the outer ring
## draws solid as the board's frame, the old grain stripes are GONE (they
## were the "literally invisible" lines the owner reported).
func _draw_board() -> void:
        var th := _theme()
        var r := _slab_rect()
        board_l.draw_rect(Rect2(r.position + Vector2(10, 14), r.size),
                        Color(0, 0, 0, 0.35))
        board_l.draw_rect(r, th["board"])
        board_l.draw_rect(Rect2(r.position.x, r.end.y - 10.0, r.size.x,
                        10.0), th["board_dark"])
        # the hint gray: between the paper and the ink, plainly visible,
        # still gray - and the drawn ink lines cover it whole later
        var hint: Color = (th["line"] as Color).lerp(th["board"], 0.62)
        var gw := maxf(2.0, cell * 0.028)
        var dashes := 5
        for e in edges_total(dots_n):
                var seg := _edge_seg(e)
                for k in dashes:
                        var f0 := (float(k) + 0.25) / float(dashes)
                        var f1 := (float(k) + 0.8) / float(dashes)
                        board_l.draw_line(seg[0].lerp(seg[1], f0),
                                        seg[0].lerp(seg[1], f1),
                                        Color(hint, 0.9), gw, true)
        # the outline ring: the OUTER edges draw solid and a touch wider
        # - the rim dots literally wear the board's outline
        var ow := gw * 1.3
        for c in dots_n - 1:
                var st := _edge_seg(idx_h(c, 0, dots_n))
                var sb := _edge_seg(idx_h(c, dots_n - 1, dots_n))
                board_l.draw_line(st[0], st[1], Color(hint, 1.0), ow, true)
                board_l.draw_line(sb[0], sb[1], Color(hint, 1.0), ow, true)
        for rr in dots_n - 1:
                var sl := _edge_seg(idx_v(0, rr, dots_n))
                var sr := _edge_seg(idx_v(dots_n - 1, rr, dots_n))
                board_l.draw_line(sl[0], sl[1], Color(hint, 1.0), ow, true)
                board_l.draw_line(sr[0], sr[1], Color(hint, 1.0), ow, true)
        # the dots (the board's whole skeleton)
        var dr := maxf(3.0, cell * 0.08)
        for c in dots_n:
                for rr in dots_n:
                        board_l.draw_circle(dot_at(c, rr), dr, th["line"])

func dot_at(c: int, r: int) -> Vector2:
        return board_origin + Vector2(float(c) * cell, float(r) * cell)

func _edge_seg(e: int) -> Array:
        var d := dots_n
        var hb := d * (d - 1)
        if e < hb:
                var c := e % (d - 1)
                var r := e / (d - 1)
                return [dot_at(c, r), dot_at(c + 1, r)]
        var j := e - hb
        var c2 := j / (d - 1)
        var r2 := j % (d - 1)
        return [dot_at(c2, r2), dot_at(c2, r2 + 1)]

## the claimed squares: the owner's color, faded in (THE COLOR FADE LAW).
## THE OUTLINE TRUTH (v0.3.9-5, the owner: "a player-owned square outlines
## should be black and only the inside be the color of the player so the
## contrast be better"): the fill wears the owner's color, the RING around
## it wears a dark ink that no theme can wash out - the ownership reads
## at a glance on every paper.
func _draw_boxes() -> void:
        var d := dots_n
        var bps := d - 1
        var th := _theme()
        var ring := Color(th["line"]).darkened(0.55)
        ring.a = 1.0
        var rw := maxf(2.0, cell * 0.05)
        for b in boxes.size():
                var v: int = boxes[b]
                if v == 0:
                        continue
                var bc := b / bps
                var br := b % bps
                var col := RED_P if v == 1 else BLUE_P
                var a := 0.52
                if box_anim.has(b):
                        var age: float = _time - float(box_anim[b])
                        a *= clampf(age / BOX_A, 0.0, 1.0)
                var pos := board_origin + Vector2(float(bc) * cell,
                                float(br) * cell)
                var inner := 3.0
                box_l.draw_rect(Rect2(pos.x + inner, pos.y + inner,
                                cell - inner * 2.0, cell - inner * 2.0),
                                Color(col, a))
                box_l.draw_rect(Rect2(pos.x + inner, pos.y + inner,
                                cell - inner * 2.0, cell - inner * 2.0),
                                Color(ring, a), false, rw)
                if state == "round_over" and glow_t >= 0.0 \
                                and glow_t < 1.1 and int(v) == _glow_owner:
                        # the round-over breath: the winner's boxes bloom
                        var k: float = 1.0 - absf(glow_t - 0.45) / 0.65
                        if k > 0.0:
                                box_l.draw_rect(Rect2(pos.x + inner,
                                                pos.y + inner,
                                                cell - inner * 2.0,
                                                cell - inner * 2.0),
                                                Color(1, 1, 1, 0.28 * k))

var _glow_owner := 0

## the drawn lines: each lives its two-phase life (color in -> ink dry)
func _draw_lines() -> void:
        var th := _theme()
        var ink: Color = th["line"]
        var w := maxf(3.0, cell * 0.055)
        for e in edges.size():
                var v: int = edges[e]
                if v == 0:
                        continue
                var seg := _edge_seg(e)
                var col := ink
                var a := 1.0
                if line_anim.has(e):
                        var age: float = _time - float(line_anim[e])
                        if age < LINE_A:
                                # phase A: the player's color fades in
                                a = clampf(age / LINE_A, 0.0, 1.0)
                                col = RED_P if v == 1 else BLUE_P
                        elif age < LINE_A + LINE_B:
                                # phase B: the color dries into the ink
                                var k: float = (age - LINE_A) / LINE_B
                                k = clampf(k, 0.0, 1.0)
                                k = k * k * (3.0 - 2.0 * k)   # smoothstep
                                var pc := RED_P if v == 1 else BLUE_P
                                col = Color(pc.r + (ink.r - pc.r) * k,
                                                pc.g + (ink.g - pc.g) * k,
                                                pc.b + (ink.b - pc.b) * k)
                                a = 1.0
                line_l.draw_line(seg[0], seg[1], Color(col, a), w, true)
        # THE STANDBY (THE HOLD LAW): dashed, translucent, it breathes -
        # v0.3.9-4: brighter and chunkier, it must read at a glance over
        # the gray lattice
        if ghost_edge >= 0 and state == "play" and turn == 1:
                var seg := _edge_seg(ghost_edge)
                var pulse := 0.62 + 0.22 * sin(_time * 6.0)
                var gc := Color(RED_P, pulse)
                var dashes := 5
                for k in dashes:
                        var f0 := float(k) / float(dashes)
                        var f1 := (float(k) + 0.62) / float(dashes)
                        line_l.draw_line(seg[0].lerp(seg[1], f0),
                                        seg[0].lerp(seg[1], f1), gc,
                                        w * 1.4, true)

func _draw_fx() -> void:
        # the coin (the xo coin law, seated inside its box)
        if coin_box >= 0 and int(boxes[coin_box]) == 0:
                var tex: Texture2D = load("res://assets/ui/coin.png")
                if tex != null:
                        var bps := dots_n - 1
                        var bc := coin_box / bps
                        var br := coin_box % bps
                        var pos := board_origin + Vector2(
                                        (float(bc) + 0.5) * cell,
                                        (float(br) + 0.5) * cell)
                        pos.y += sin(coin_t * 3.2) * cell * 0.06
                        var fade: float = clampf(coin_t / 0.4, 0.0, 1.0)
                        var s: float = cell * 0.46 / float(tex.get_width())
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
                        fx_l.draw_arc(pos, cell * 0.34, ga, ga + 1.1, 30,
                                        Color(1, 1, 1, 0.5 * fade), 2.2)
        # the dust pips
        for p in _dust:
                var a: float = clampf(float(p["life"]) / float(p["max"]),
                                0.0, 1.0)
                var c: Color = p["col"]
                c.a = a * 0.85
                fx_l.draw_rect(Rect2(float(p["x"]) - float(p["s"]) * 0.5,
                                float(p["y"]) - float(p["s"]) * 0.5,
                                float(p["s"]), float(p["s"])), c)

func _layout(vp: Vector2) -> void:
        var top := 190.0
        var bot := banner_bottom() + 40.0
        # THE SLAB FIT LAW: the slab stays inside the screen - the paper
        # never kisses the edges
        var span := float(dots_n - 1)
        # the fit wears the OUTLINE LAW's own rim (0.14*cell a side ->
        # +0.28 of a cell) plus the shadow's breathing room
        cell = minf((vp.x - 44.0) / (span + 0.28),
                        (vp.y - top - bot - 30.0) / (span + 0.28))
        cell = minf(cell, 112.0)
        cell = maxf(cell, 30.0)
        var side := span * cell
        var spare := vp.y - top - bot - side
        board_origin = Vector2((vp.x - side) * 0.5,
                        top + maxf(0.0, spare * 0.40))
        _place_texts(vp)
        bg_l.queue_redraw()
        board_l.queue_redraw()
        box_l.queue_redraw()
        line_l.queue_redraw()

## the turn + verdict texts seat once, from layout AND from build
func _place_texts(vp: Vector2) -> void:
        var span := float(dots_n - 1) * cell
        if turn_lbl != null:
                turn_lbl.position = Vector2(0, board_origin.y - 96.0)
                turn_lbl.custom_minimum_size = Vector2(vp.x, 44)
        if verdict_lbl != null:
                verdict_lbl.position = Vector2(0,
                                board_origin.y + span
                                + maxf(26.0, cell * 0.14) + 22.0)
                verdict_lbl.custom_minimum_size = Vector2(vp.x, 50)

# ------------------------------------------------- the widget row

func _build_widgets(vp: Vector2) -> void:
        # THE W-L CARDS (v0.3.9-4, the owner: "remove the D panel (draws)
        # because this game has no draws as i told you") - W | L only
        goals_row = Control.new()
        goals_row.custom_minimum_size = Vector2(108.0 * 2.0 + 8.0, 64.0)
        goals_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
        goals_row.draw.connect(_draw_goal_cards.bind(goals_row))
        _hud_row.add_child(goals_row)
        var score_chip: Control = _score_label.get_parent().get_parent()
        # insert AFTER the score chip (at its index + 1 - inserting AT the
        # chip's index seats the cards BEFORE it, the qa caught that)
        _hud_row.move_child(goals_row, score_chip.get_index() + 1)
        # THE TALLY SEAT (v0.3.9-4, the owner: "the widget of squares count
        # i guess it should be under the goals widget instead of being next
        # to it"): RED nn | BLUE nn rides UNDER the W/L cards as the goals
        # card's own child - it follows the card's seat wherever the row
        # puts it, and the old row-index gymnastics died with the D panel
        squares_row = Control.new()
        squares_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
        squares_row.draw.connect(_draw_squares_cards.bind(squares_row))
        goals_row.add_child(squares_row)
        squares_row.position = Vector2((224.0 - 136.0) * 0.5, 68.0)
        squares_row.size = Vector2(136.0, 46.0)
        turn_lbl = Arc.label("", 30, Color(1, 1, 1, 0.95))
        turn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        world.add_child(turn_lbl)
        verdict_lbl = Arc.label("", 32, Color(1, 1, 1, 0.95))
        verdict_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        verdict_lbl.visible = false
        world.add_child(verdict_lbl)
        _place_texts(vp)
        _refresh_widget()

func _draw_squares_cards(c: Control) -> void:
        var cw := 64.0
        var ch := 46.0
        var gapw := 8.0
        var f := ThemeDB.fallback_font
        var mid_y := c.size.y * 0.5
        var x0 := c.size.x * 0.5
        for i in 2:
                var x: float = (cw + gapw) * (i - 1) + x0
                var r := Rect2(x - cw * 0.5, mid_y - ch * 0.5, cw, ch)
                var col := RED_P if i == 0 else BLUE_P
                c.draw_rect(Rect2(r.position + Vector2(4, 4), r.size),
                                Color(0.09, 0.05, 0.02, 0.85))
                c.draw_rect(r, Color(1, 1, 1, 0.95))
                c.draw_rect(r, col, false, 5.0)
                # the glyph: a filled rounded square in the owner's color
                var g := 18.0
                c.draw_rect(Rect2(x - cw * 0.5 + 9.0,
                                mid_y - g * 0.5, g, g), col)
                var n: int = _red_boxes() if i == 0 else _blue_boxes()
                c.draw_string(f, Vector2(x - cw * 0.5 + 32.0,
                                mid_y + 13.0), str(n),
                                HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Arc.INK)

func _red_boxes() -> int:
        var n := 0
        for v in boxes:
                if int(v) == 1:
                        n += 1
        return n

func _blue_boxes() -> int:
        var n := 0
        for v in boxes:
                if int(v) == 2:
                        n += 1
        return n

func _draw_goal_cards(c: Control) -> void:
        var cw := 108.0
        var ch := 46.0
        var gapw := 8.0
        # v0.3.9-4: W | L - the D card is gone (the owner: this game has
        # no draws, "as i told you")
        var cols := [Color("58c470"), Color("e8574a")]
        var letters := ["W", "L"]
        var f := ThemeDB.fallback_font
        var mid_y := c.size.y * 0.5
        var x0 := c.size.x * 0.5
        for i in 2:
                var x: float = (cw + gapw) * (i - 1) + x0
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
        if squares_row != null:
                squares_row.queue_redraw()
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
        _dust = []
        last_win_box = -1
        glow_t = -1.0
        _glow_owner = 0
        rounds += 1
        verdict_lbl.visible = false
        # THE OPENER LAW: the loser starts (no draws - the flip never fires,
        # the var lives for the xo law's sake)
        last_opener = next_opener
        turn = next_opener
        clock = 0.0
        # THE COIN LAW: after every 3 completed rounds the next round
        # opens with a GOGACoin resting INSIDE a box - the box's claimer
        # takes it (the CPU races you)
        coin_box = -1
        coin_t = 0.0
        if done_rounds > 0 and done_rounds % COIN_EVERY == 0:
                coin_box = _random_empty_box()
        # THE STATE LAW (v0.3.9-1): _new_round is the round's ONLY door -
        # it seats the state machine whole
        if turn == 1:
                state = "play"      # the player opens: the board is live
        else:
                state = "wait"      # the CPU opens: it thinks, then draws
                cpu_think = true
                think_beat = _rng.randf_range(0.4, 0.8)
        _banner()
        box_l.queue_redraw()
        line_l.queue_redraw()

var last_win_box := -1

func _random_empty_box() -> int:
        var empties := []
        for i in boxes.size():
                if int(boxes[i]) == 0:
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

# ============================================================ the hand

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
                        _press(t.position)
                else:
                        _release(t.position)
        elif event is InputEventScreenDrag:
                if holding and state == "play" and turn == 1:
                        _drag_to((event as InputEventScreenDrag).position)
        elif event is InputEventMouseMotion:
                if holding and state == "play" and turn == 1:
                        _drag_to((event as InputEventMouseMotion).position)
        elif event is InputEventMouseButton:
                var mb := event as InputEventMouseButton
                if mb.pressed:
                        if state == "ready":
                                _gate_down()
                                _new_round()
                                return
                        _press(mb.position)
                else:
                        _release(mb.position)

## THE PRESS: the standby wakes on the nearest edge
func _press(at: Vector2) -> void:
        if state != "play" or turn != 1:
                return
        holding = true
        ghost_edge = _nearest_edge(at)
        line_l.queue_redraw()

## THE DRAG: the line follows the finger edge to edge - off the board it
## vanishes (the cancel), back on it re-arms (the follow law)
func _drag_to(at: Vector2) -> void:
        if not holding or state != "play" or turn != 1:
                return
        ghost_edge = _nearest_edge(at)
        line_l.queue_redraw()

## THE RELEASE: the line is applied - out of the board it places nothing
func _release(_at: Vector2) -> void:
        if not holding:
                return
        holding = false
        var e := ghost_edge
        ghost_edge = -1
        line_l.queue_redraw()
        if e < 0:
                return          # the cancel: nothing is placed
        if state != "play" or turn != 1:
                return
        if int(edges[e]) != 0:
                Jukebox.sfx("sq_denied", -8.0)
                return
        _place(e, 1)

## the nearest edge to a finger point (the four edges around the nearest
## dot, segment distance, deterministic tie = the lower edge id)
func _nearest_edge(at: Vector2) -> int:
        var d := dots_n
        var span := float(d - 1) * cell
        var g := Rect2(board_origin, Vector2(span, span))
        var slack := cell * 0.5
        if at.x < g.position.x - slack or at.x > g.end.x + slack \
                        or at.y < g.position.y - slack \
                        or at.y > g.end.y + slack:
                return -1
        var c := clampi(int(round((at.x - g.position.x) / cell)), 0, d - 1)
        var r := clampi(int(round((at.y - g.position.y) / cell)), 0, d - 1)
        var best := -1
        var best_d := INF
        for e in _edge_candidates(c, r, d):
                var seg := _edge_seg(e)
                var dd := _seg_dist(at, seg[0], seg[1])
                if dd < best_d - 0.001:
                        best_d = dd
                        best = e
        return best

func _edge_candidates(c: int, r: int, d: int) -> Array:
        var out := []
        if c - 1 >= 0:
                out.append(idx_h(c - 1, r, d))
        if c <= d - 2:
                out.append(idx_h(c, r, d))
        if r - 1 >= 0:
                out.append(idx_v(c, r - 1, d))
        if r <= d - 2:
                out.append(idx_v(c, r, d))
        return out

func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
        var ab := b - a
        var l2 := ab.length_squared()
        if l2 <= 0.0001:
                return p.distance_to(a)
        var t: float = clampf((p - a).dot(ab) / l2, 0.0, 1.0)
        return p.distance_to(a + ab * t)

# ============================================================ the moves

func _place(e: int, who: int) -> void:
        edges[e] = who
        line_anim[e] = _time
        Jukebox.sfx("sq_line", -6.0, 1.0 + _rng.randf() * 0.05)
        line_l.queue_redraw()
        var took := _close_boxes(e, who)
        # the chain bookkeeping (the KSquares law's shadow)
        if took == 0:
                chain_streak = 0
        elif who == 1:
                chain_streak += took
                player_best_streak = maxi(player_best_streak, chain_streak)
        if took > 0:
                line_l.queue_redraw()
                box_l.queue_redraw()
                _refresh_widget()
        # THE VERDICT-FIRST LAW: the board's last edge ALWAYS falls as a
        # capture, so the verdict outranks the keep-brush branches - a
        # claim that ends the board must resolve, never hand the brush to
        # a dead round (the qa rig caught this: the round hung in the CPU
        # thinking forever, the verdict never came)
        var w := winner_of(boxes)
        if w != 0:
                _resolve(w)          # the board is done - the verdict is now
                return
        if who == 1 and took > 0:
                state = "play"       # THE KSQUARES LAW: close one, go again
                _banner()
                return
        if who == 2 and took > 0:
                # the CPU keeps the brush too
                cpu_think = true
                think_beat = _rng.randf_range(0.35, 0.7)
                clock = 0.0
                return
        if who == 1:
                turn = 2
                state = "wait"
                cpu_think = true
                think_beat = _rng.randf_range(0.4, 0.8)
                clock = 0.0
                _banner()
        else:
                turn = 1
                state = "play"
                _banner()

## every box this edge completes gets its owner's color (faded in), the
## coin rides with its box, the count is returned
func _close_boxes(e: int, who: int) -> int:
        var n := 0
        for b in edge_boxes(e, dots_n):
                if int(boxes[b]) != 0:
                        continue
                if box_sides(edges, b, dots_n) == 4:
                        boxes[b] = who
                        box_anim[b] = _time
                        last_win_box = b
                        n += 1
                        var bps := dots_n - 1
                        var bc := int(b) / bps
                        var br := int(b) % bps
                        _dust_burst(board_origin + Vector2(
                                        (float(bc) + 0.5) * cell,
                                        (float(br) + 0.5) * cell),
                                        RED_P if who == 1 else BLUE_P, 8)
                        # THE COIN RACE: whoever claims the box TAKES it
                        if coin_box >= 0 and b == coin_box:
                                _coin_taken(who, board_origin + Vector2(
                                                (float(bc) + 0.5) * cell,
                                                (float(br) + 0.5) * cell))
        if n > 0:
                Jukebox.sfx("sq_box", -4.0)
        return n

func _ai_move() -> void:
        var rng := RandomNumberGenerator.new()
        rng.seed = int(Time.get_unix_time_from_system() * 1000.0) \
                        ^ (rounds * 7919) ^ (edges.hash() & 0xffff)
        var flags := adapt(mem)
        var e := cpu_pick(edges, dots_n, profile, bool(flags["alert"]), rng)
        if e >= 0:
                _place(e, 2)

# ============================================================ the verdict

func _resolve(w: int) -> void:
        state = "round_over"
        clock = 0.0
        glow_t = 0.0
        _glow_owner = w
        done_rounds += 1
        mem = remember(mem, {"streak": player_best_streak, "result": w})
        if w == 1:
                wins += 1
                streak += 1
                add_score(1)                     # THE OWNER'S LAW: win = +1
                verdict_lbl.text = "YOU TAKE THE BOARD  +1"
                verdict_lbl.add_theme_color_override("font_color",
                                Color("7ee2a0"))
                Jukebox.sfx("sq_win", -3.0)
                achievement_count("wins", 1)
                achievement_max("streak", streak)
                var bps := dots_n - 1
                var mid := board_origin + Vector2(
                                (float(bps) * cell) * 0.5,
                                (float(bps) * cell) * 0.5)
                Arc.confetti(_overlay_root_ref(), mid, 30)
        else:
                losses += 1
                streak = 0
                if score > 0:
                        add_score(-1)    # never under zero (the xo law)
                verdict_lbl.text = "THE CPU TAKES THE BOARD  -1"
                verdict_lbl.add_theme_color_override("font_color",
                                Color("f2a09a"))
                Jukebox.sfx("sq_lose", -3.0)
        # THE OPENER LAW: the loser starts next (no draws on this board)
        if w == 1:
                next_opener = 2
        else:
                next_opener = 1
        achievement_max("max_score", score)
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
                if glow_t >= 0.0:
                        glow_t = minf(1.2, glow_t + delta * 1.4)
                if clock >= 2.2:
                        _new_round()
        # retire the fade entries past their windows (tiny dicts)
        if not line_anim.is_empty() or not box_anim.is_empty():
                var stale := []
                for e in line_anim:
                        if _time - float(line_anim[e]) > LINE_A + LINE_B + 0.1:
                                stale.append(e)
                for e in stale:
                        line_anim.erase(e)
                stale = []
                for b in box_anim:
                        if _time - float(box_anim[b]) > BOX_A + 0.1:
                                stale.append(b)
                for b in stale:
                        box_anim.erase(b)
        coin_t += delta
        # THE LIVING LAYER LAW (v0.3.9-4): every layer whose art reads the
        # clock repaints on the TICK - an event-driven repaint freezes a
        # time-based fade between events (the owner: "after each drawn
        # line, the animations moves a frame" - the box wash only moved
        # when the next line landed). The fades breathe on their own now.
        box_l.queue_redraw()
        line_l.queue_redraw()
        fx_l.queue_redraw()

# ------------------------------------------------------------ dust + coin

func _dust_burst(at: Vector2, col: Color, n := 6) -> void:
        for i in n:
                _dust.append({
                        "x": at.x + _rng.randf_range(-cell * 0.2,
                                        cell * 0.2),
                        "y": at.y + _rng.randf_range(-cell * 0.1,
                                        cell * 0.12),
                        "vx": _rng.randf_range(-80.0, 80.0),
                        "vy": _rng.randf_range(-120.0, -20.0),
                        "life": _rng.randf_range(0.26, 0.46),
                        "max": 0.46,
                        "s": _rng.randf_range(2.0, 4.5),
                        "col": col,
                })
        if _dust.size() > 120:
                _dust = _dust.slice(_dust.size() - 120)

func _coin_taken(who: int, at: Vector2) -> void:
        coin_box = -1
        if who == 1:
                add_run_coins(1)
                Jukebox.sfx("sq_coin", -3.0)
                game_toast("YOU TOOK THE GOGACOIN  +1")
                _dust_burst(at, Color("ffd24a"), 14)
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
        var t := Arc.label("SQUARES OPTIONS", 34, Arc.INK)
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
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.46, 260.0,
                        540.0))
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
        var owned := Box.item_owned(game_id, "size", id) \
                        or int(sz["price"]) == 0
        var on := size_id == id
        var head := Arc.label("%s%s - %s" % [sz["name"],
                        "  (ON)" if on else "", sz["desc"]], 19,
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
                var lk := Arc.button("LOCKED - %d IN THE SHOP"
                                % int(sz["price"]),
                                Vector2(560, 56), 20,
                                Color(0.55, 0.48, 0.38),
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
        sheet.add_child(Arc.button("NO", Vector2(560, 74), 26, Arc.BAD,
                        func():
                        sheet_pop()
                        _confirm_open_id = ""))

## the applied board: rebuild the grid, start a fresh round
func _apply_size(id: String) -> void:
        size_id = id
        dots_n = int(id)
        _new_board()
        ghost_edge = -1
        holding = false
        if state == "ready":
                _layout(get_viewport_rect().size)
                return
        _layout(get_viewport_rect().size)
        _new_round()

# ============================================================ the shop
## THEMES ONLY (the owner: "a shop but for themes only, no skins") + the
## board sizes, everything but the defaults bought (the chess law: coin
## buttons, gray when the wallet is dry, (ON) rows, reopen-on-buy).

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
        var t := Arc.label("SQUARES SHOP", 34, Arc.INK)
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
        box.add_child(_shop_label("PAPER - the board you draw on "
                        + "(the pens are not for sale: red is yours, blue "
                        + "is the enemy's)"))
        for id in THEMES:
                box.add_child(_theme_row(id))
        box.add_child(_shop_label(
                        "BOARD SIZES - bigger boards, bought first"))
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
        return _price_btn(c["name"], int(c["price"]), Color("2a7a68"),
                        func():
                                if Box.buy_item(game_id, "theme", id,
                                                int(c["price"])):
                                        Jukebox.sfx("buy")
                                        Box.equip_item(game_id, "theme", id)
                                _shop_reopen())

func _shop_reopen() -> void:
        if shop_id != "":
                sheet_pop()
                _shop_open.call_deferred()

# ============================================================ the probe
## The headless contract: a fresh deterministic round any probe drives.

func probe_reset(seed_v: int, d := 4) -> void:
        _rng.seed = seed_v
        _gate_down()
        size_id = str(d)
        dots_n = d
        _new_board()
        _dust = []
        last_win_box = -1
        glow_t = -1.0
        rounds = 0
        done_rounds = 0
        wins = 0
        losses = 0
        draws = 0
        mem = []
        profile_i = 0
        next_opener = 1
        last_opener = 1
        ghost_edge = -1
        holding = false
        paused = true
        _layout(get_viewport_rect().size)
        _new_round()

func probe_step(dt: float) -> void:
        _goga_tick(dt)
