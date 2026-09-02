extends GogaGame
## XO - v0.2.8, REBORN FROM SCRATCH (the owner: "rename it to just XO
## without the word ladder and remake it"). The ladder is gone - no rungs,
## no cash out, no difficulty menu. What lives here is the owner's sketch
## design (his xo html: paper, ink, red X vs blue O, hard offset shadows)
## with smooth animations and its own pencil voices.
##
## Owner contract (v0.2.8):
##   - SKETCH design: paper page, white board, ink strokes with wobble,
##     X red / O blue, symbols pop in with overshoot, winners pulse amber
##   - smooth animations everywhere, cool designed SFX (v028_sfx.py)
##   - a YOU / DRAWS / CPU widget (his score-board shape)
##   - scoring: each WIN +1, each LOSS -1, a DRAW 0; run bonus /2
##     (registry coin_div 2)
##   - a GOGACoin lands on the board after every 3 rounds, in an EMPTY
##     cell, and WHOEVER MARKS THAT CELL TAKES IT (the CPU can steal it -
##     it is a race)
##   - the CASH OUT button is dead; banking is the PONG design: the pause
##     sheet's END button (pause_end_run)
##   - NO difficulty levels: ONE opponent, "good enough to not lose but
##     not smart enough to always win", with DIFFERENT PROFILES it wears
##     round to round, and it ADAPTS ON THE FLY: a 2-round FIFO memory -
##     repeat an opening and the burned reply never repeats, show a fork
##     once and the fork-watch wakes for the next rounds. Memory forgets
##     after 2 rounds so it never adapts to every single thing.
##
## Probe contract: the whole CPU core is STATIC - winner_of / empty_cells /
## cpu_pick / remember / adapt drive headless laws without the scene.

const X := 1                 # the player (red pencil)
const O := 2                 # the machine (blue pencil)
const WIN_LINES := [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6],
]
const COIN_EVERY := 3        # owner: one GOGACoin after each 3 rounds
const MEM_ROUNDS := 2        # owner: "short memory only for 2 rounds"

## THE FOUR PROFILES (the owner: "make it with different profiles"). Every
## round the machine wears another one - the same hand, four moods. The
## knobs keep the owner's balance law: strong blocks (rarely loses), small
## miss chances (not smart enough to always win).
const PROFILES := {
        "wall": {
                "title": "THE WALL", "miss_win": 0.05, "skip_block": 0.02,
                "fork_watch": 0.85, "noise": 0.22,
                "w_build": 1.5, "w_block": 2.7, "w_pos": 1.5,
        },
        "trick": {
                "title": "THE TRICKSTER", "miss_win": 0.03, "skip_block": 0.03,
                "fork_watch": 0.95, "noise": 0.30,
                "w_build": 2.6, "w_block": 1.9, "w_pos": 1.2,
        },
        "rusher": {
                "title": "THE RUSHER", "miss_win": 0.02, "skip_block": 0.08,
                "fork_watch": 0.55, "noise": 0.34,
                "w_build": 3.0, "w_block": 1.6, "w_pos": 1.1,
        },
        "sage": {
                "title": "THE SAGE", "miss_win": 0.04, "skip_block": 0.04,
                "fork_watch": 0.75, "noise": 0.26,
                "w_build": 2.2, "w_block": 2.2, "w_pos": 1.3,
        },
}
const POS_WEIGHT := [1.0, 0.9, 1.0, 0.9, 1.4, 0.9, 1.0, 0.9, 1.0]

# the sketch palette (the owner's html)
const INK := Color("1a1a1a")
const PAPER := Color("faf9f6")
const X_RED := Color("ef4444")
const X_DARK := Color("991b1b")
const O_BLUE := Color("3b82f6")
const O_DARK := Color("1e40af")
const AMBER := Color("f59e0b")

# ------------------------------------------------------------ state
var board: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0]
var turn := X
var state := "play"           # play | ai_wait | round_over
var clock := 0.0
var think_beat := 0.0
var rounds := 0               # rounds OPENED
var done_rounds := 0          # rounds COMPLETED (the coin clock)
var wins := 0
var losses := 0
var draws := 0
var streak := 0

# the adaptive memory (the owner's 2-round law)
var mem: Array = []           # FIFO, MEM_ROUNDS long
var cur: Dictionary = {}      # this round's record {open, reply, fork}

# the round's profile (rotates; the owner: "different profiles")
var profile_order: Array = ["wall", "trick", "rusher", "sage"]
var profile_i := 0
var profile := "sage"

# the coin race
var coin_cell := -1
var coin_t := 0.0

# scene
var world: Node2D
var plate: Node2D
var cells_ui: Array = []
var marks: Array = []
var win_holder: Node2D
var widget: Node2D
var you_lbl: Label
var draw_lbl: Label
var cpu_lbl: Label
var you_t: Label
var draw_t: Label
var cpu_t: Label
var turn_lbl: Label
var note_lbl: Label
var cell := 190.0
var board_origin := Vector2.ZERO
var _dust: Array = []         # pencil dust particles
var _time := 0.0
var _rng := RandomNumberGenerator.new()

# ============================================================ THE CPU CORE
## Static so tests (flow_test + xo_probe) drive the brain without the
## scene - the same contract the old ladder had.

static func winner_of(b: Array) -> int:
        ## 0 = none yet, 1 = X, 2 = O, 3 = full board (draw)
        for line in WIN_LINES:
                var v: int = b[line[0]]
                if v != 0 and v == b[line[1]] and v == b[line[2]]:
                        return v
        for v in b:
                if int(v) == 0:
                        return 0
        return 3

static func empty_cells(b: Array) -> Array:
        var out := []
        for i in b.size():
                if int(b[i]) == 0:
                        out.append(i)
        return out

## the cell where `who` completes a line right now (-1 = none)
static func _finish_cell(b: Array, who: int) -> int:
        for line in WIN_LINES:
                var mine := 0
                var hole := -1
                var blocked := false
                for c in line:
                        var v: int = b[c]
                        if v == who:
                                mine += 1
                        elif v == 0:
                                hole = c
                        else:
                                blocked = true
                if mine == 2 and hole >= 0 and not blocked:
                        return hole
        return -1

## every cell that would hand `who` TWO winning lines at once (a fork)
static func _fork_cells(b: Array, who: int) -> Array:
        var out := []
        for i in empty_cells(b):
                var bb := b.duplicate()
                bb[i] = who
                if _winning_cells(bb, who).size() >= 2:
                        out.append(i)
        return out

## cells where `who` would win on their next placement
static func _winning_cells(b: Array, who: int) -> Array:
        var out := []
        for i in empty_cells(b):
                var bb := b.duplicate()
                bb[i] = who
                if winner_of(bb) == who:
                        out.append(i)
        return out

## THE MEMORY LAW (the owner: "short memory only for 2 rounds so it does
## not adapt for every single thing"): push the finished round's record,
## drop everything older than MEM_ROUNDS.
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

## WHAT THE MEMORY REMEMBERS (the owner: "if first round the user used
## pattern xx so round 2 make the CPU do not fell in same pattern"):
##   burned  - the reply the player has already seen twice to THE SAME
##             opening (a fresh response keeps the same opening from
##             replaying the same game)
##   pref    - the OPPOSITE kind of reply: the response that beat the
##             player's opening last time is trusted once more
##   forkry  - the player built a fork inside the memory window: the
##             fork-watch wakes for this round whatever the profile is
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
                        # the player replays the same opening: the reply that
                        # failed to win LAST time is burned (never twice)
                        var last: Dictionary = mem_in[mem_in.size() - 1]
                        if int(last["result"]) != O:
                                out["burned"] = int(last["reply"])
                        # the reply that WON last time is trusted
                        if int(last["result"]) == O and int(last["reply"]) >= 0:
                                out["pref"] = int(last["reply"])
        return out

## THE MOVE PIPELINE. One opponent, four moods:
##   1. take an immediate win (a small miss chance keeps it beatable)
##   2. block an immediate loss (skip is rare - "good enough to not lose")
##   3. the fork watch: kill the player's fork before it exists (memory
##      can force it awake)
##   4. profile-weighted feel for the position + the adaptation nudges +
##      a little noise so the same board never plays the same twice
static func cpu_pick(board_in: Array, profile_id: String, mem_in: Array,
                rng: RandomNumberGenerator) -> int:
        var b := board_in.duplicate()
        var empties := empty_cells(b)
        if empties.is_empty():
                return -1
        var p: Dictionary = PROFILES[profile_id]
        var flags := adapt(mem_in)

        # 1. the win is RIGHT THERE - almost always taken
        var w := _finish_cell(b, O)
        if w >= 0 and rng.randf() >= float(p["miss_win"]):
                return w
        # 2. the loss is RIGHT THERE - blocked almost always
        var d := _finish_cell(b, X)
        if d >= 0 and rng.randf() >= float(p["skip_block"]):
                return d
        # 3. the fork watch (the profile's eye, WIDE awake if the player
        # has forked inside the memory window)
        var watch := float(p["fork_watch"])
        if flags["forkry"]:
                watch = 1.0
        if rng.randf() < watch:
                var forks := _fork_cells(b, X)
                if not forks.is_empty():
                        # prefer the block that also builds the machine
                        for f in forks:
                                var bb := b.duplicate()
                                bb[f] = O
                                if _finish_cell(bb, O) >= 0:
                                        return f
                        return int(forks[rng.randi() % forks.size()])

        # 4. the feel: build, block, position, adapt, breathe
        var best := -INF
        var picks := []
        for i in empties:
                var s := 0.0
                s += float(p["w_pos"]) * float(POS_WEIGHT[i])
                for line in WIN_LINES:
                        if not line.has(i):
                                continue
                        var mine := 0
                        var theirs := 0
                        for c in line:
                                var v: int = b[c]
                                if v == O:
                                        mine += 1
                                elif v == X:
                                        theirs += 1
                        if theirs == 0 and mine > 0:
                                s += float(p["w_build"]) * float(mine)
                        if mine == 0 and theirs > 0:
                                s += float(p["w_block"]) * float(theirs) * 0.55
                # the burned reply never repeats against the same opening
                if int(flags["burned"]) == i:
                        s -= 2.5
                if int(flags["pref"]) == i:
                        s += 1.2
                s += rng.randf() * float(p["noise"])
                if s > best + 0.0001:
                        best = s
                        picks = [i]
                elif absf(s - best) <= 0.0001:
                        picks.append(i)
        return int(picks[rng.randi() % picks.size()])

static func profile_next(i: int) -> Array:
        ## the round-robin: a shuffled cycle so the player meets all four
        ## moods, never the same one twice in a row
        return [PROFILES.keys()[i % PROFILES.size()], i + 1]

# ============================================================ the scene

func _goga_setup() -> void:
        _rng.randomize()
        pause_end_run = true    # THE PONG DESIGN: the pause sheet's END is
                                # the only bank - the CASH OUT button is dead
        var vp := get_viewport_rect().size
        world = Node2D.new()
        add_child(world)
        _paint_paper(vp)
        _build_board(vp)
        _build_widget(vp)
        _refresh_widget()
        _new_round()

func _paint_paper(vp: Vector2) -> void:
        var paper := Node2D.new()
        paper.z_index = -10
        paper.draw.connect(func():
                paper.draw_rect(Rect2(Vector2.ZERO, vp), PAPER)
                # the faint ruled lines of a sketchbook page
                var y := 46.0
                var li := 0
                while y < vp.y:
                        if li % 8 != 7:      # a margin line breaks the rhythm
                                paper.draw_line(Vector2(0, y), Vector2(vp.x, y),
                                                Color(0.1, 0.1, 0.12, 0.045), 2.0)
                        y += 46.0
                        li += 1
                # the red margin line, like a real notebook
                paper.draw_line(Vector2(30, 0), Vector2(30, vp.y),
                                Color(0.85, 0.3, 0.3, 0.10), 3.0)
                # the worn corner eraser smudges (deterministic - the page
                # never changes between frames)
                for s in [[vp.x * 0.12, vp.y * 0.93, 30.0],
                                [vp.x * 0.87, vp.y * 0.14, 38.0],
                                [vp.x * 0.72, vp.y * 0.9, 26.0]]:
                        paper.draw_circle(Vector2(s[0], s[1]), s[2],
                                        Color(0.75, 0.72, 0.66, 0.10)))
        world.add_child(paper)

func _build_board(vp: Vector2) -> void:
        var top_need := 300.0
        var avail := vp.y - top_need - banner_bottom() - 26.0
        cell = minf((vp.x - 60.0) / 3.0, avail / 3.0)
        cell = minf(cell, 240.0)
        var side := cell * 3.0
        board_origin = Vector2((vp.x - side) * 0.5, top_need + maxf(0.0, (avail - side) * 0.42))
        plate = Node2D.new()
        plate.position = board_origin
        plate.draw.connect(func():
                var pad := 18.0
                var r := Rect2(-pad, -pad, side + pad * 2.0, side + pad * 2.0)
                # THE SKETCH SHADOW: the hard ink offset (the owner's html:
                # box-shadow 4px 4px 0)
                plate.draw_rect(Rect2(r.position + Vector2(6, 6), r.size), INK)
                plate.draw_rect(Rect2(r.position, r.size), Color.WHITE)
                plate.draw_rect(Rect2(r.position, r.size), INK, false, 4.0)
                # the four wobbly grid strokes (hand-drawn, never straight)
                for k in [1, 2]:
                        var off: float = float(k) * cell
                        plate.draw_polyline(_wobble_line(Vector2(off, 8), Vector2(off, side - 8), 7, 2.6),
                                        Color(INK, 0.85), 7.0, true)
                        plate.draw_polyline(_wobble_line(Vector2(8, off), Vector2(side - 8, off), 7, 2.6),
                                        Color(INK, 0.85), 7.0, true))
        world.add_child(plate)
        for i in 9:
                var cx := i % 3
                var cy := i / 3
                var t := Button.new()
                t.flat = true
                t.position = board_origin + Vector2(cx * cell, cy * cell)
                t.size = Vector2(cell, cell)
                t.pressed.connect(func(): _tap_cell(i))
                world.add_child(t)
                cells_ui.append(t)
        # the amber winners glow + the strike line live here
        win_holder = Node2D.new()
        win_holder.z_index = 3
        win_holder.draw.connect(func():
                var wl: Array = last_win_line
                if wl.is_empty():
                        return
                var a := 0.5 + 0.5 * sin(_time * 6.0)
                for i in wl:
                        var ii: int = int(i)
                        var cx: int = ii % 3
                        var cy: int = ii / 3
                        win_holder.draw_rect(Rect2(board_origin + Vector2(cx * cell + 6, cy * cell + 6),
                                        Vector2(cell - 12, cell - 12)),
                                        Color(AMBER, 0.14 + 0.10 * a))
                var p0 := _cell_mid(wl[0])
                var p1 := _cell_mid(wl[2])
                var dir := (p1 - p0).normalized()
                var perp := Vector2(-dir.y, dir.x)
                # the strike grows with the pulse (a marker swipe)
                var grow := 0.5 + 0.5 * a
                var mid := p0.lerp(p1, grow)
                var pts := _wobble_line(p0, mid, 6, 2.2)
                win_holder.draw_polyline(pts, Color(AMBER, 0.9), 12.0, true)
                win_holder.draw_circle(mid + perp * 0.0, 4.0, Color(AMBER, 0.9)))
        world.add_child(win_holder)
        # the turn line + the coin note (the thinking dots live IN the turn
        # text - no floating widgets to collide with)
        turn_lbl = Arc.label("", 30, INK)
        turn_lbl.position = Vector2(0, board_origin.y - 118.0)
        turn_lbl.custom_minimum_size = Vector2(vp.x, 40)
        turn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        world.add_child(turn_lbl)
        note_lbl = Arc.label("", 19, Color(0.45, 0.42, 0.38))
        note_lbl.position = Vector2(0, board_origin.y - 52.0)
        note_lbl.custom_minimum_size = Vector2(vp.x, 28)
        note_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        world.add_child(note_lbl)

var last_win_line: Array = []

func _build_widget(vp: Vector2) -> void:
        # THE SCORE WIDGET (the owner: "a user-enemy wins/draws widget") -
        # his score-board shape: YOU / DRAWS / CPU boxes with hard shadows
        widget = Node2D.new()
        widget.position = Vector2(vp.x * 0.5, 128.0)
        widget.draw.connect(func():
                var bw := 128.0
                var bh := 74.0
                var gapw := 16.0
                var x0 := -(bw * 3.0 + gapw * 2.0) * 0.5
                var boxes := [
                        [x0, X_RED, X_DARK],
                        [x0 + bw + gapw, Color("6b7280"), Color("4b5563")],
                        [x0 + (bw + gapw) * 2.0, O_BLUE, O_DARK],
                ]
                for b in boxes:
                        var bx: float = b[0]
                        var col: Color = b[1]
                        # the sketch shadow + the white box + the colored rim
                        widget.draw_rect(Rect2(bx + 5, -bh / 2.0 + 5, bw, bh), INK)
                        widget.draw_rect(Rect2(bx, -bh / 2.0, bw, bh), Color.WHITE)
                        widget.draw_rect(Rect2(bx, -bh / 2.0, bw, bh), col, false, 4.0)
                        # the tiny colored underline under the title
                        widget.draw_rect(Rect2(bx + 40, -bh / 2.0 + 27, bw - 80, 3), col))
        world.add_child(widget)
        you_t = Arc.label("YOU", 17, X_RED)
        draw_t = Arc.label("DRAWS", 17, Color("4b5563"))
        cpu_t = Arc.label("CPU", 17, O_BLUE)
        you_lbl = Arc.label("0", 32, X_RED)
        draw_lbl = Arc.label("0", 32, Color("4b5563"))
        cpu_lbl = Arc.label("0", 32, O_BLUE)
        for l in [you_t, draw_t, cpu_t, you_lbl, draw_lbl, cpu_lbl]:
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                world.add_child(l)

func _refresh_widget() -> void:
        you_lbl.text = str(wins)
        draw_lbl.text = str(draws)
        cpu_lbl.text = str(losses)
        var w := 128.0
        var gapw := 16.0
        var x0 := widget.position.x - (w * 3.0 + gapw * 2.0) * 0.5
        var cols := [x0, x0 + w + gapw, x0 + (w + gapw) * 2.0]
        for i in 3:
                var t: Label = [you_t, draw_t, cpu_t][i]
                var v: Label = [you_lbl, draw_lbl, cpu_lbl][i]
                t.position = Vector2(cols[i], 128.0 - 34.0)
                t.custom_minimum_size = Vector2(w, 22)
                v.position = Vector2(cols[i], 128.0 - 12.0)
                v.custom_minimum_size = Vector2(w, 40)

func _cell_mid(i: int) -> Vector2:
        return board_origin + Vector2((i % 3) * cell + cell * 0.5,
                        (i / 3) * cell + cell * 0.5)

## a hand-drawn line: the points wobble perpendicular, deterministic per
## (from, to, seed) so a stroke never twitches between frames
func _wobble_line(a: Vector2, b: Vector2, segs: int, amp: float) -> PackedVector2Array:
        var pts := PackedVector2Array()
        var dir := (b - a).normalized()
        var perp := Vector2(-dir.y, dir.x)
        for k in segs + 1:
                var f := float(k) / float(segs)
                var p := a.lerp(b, f)
                var seed := hash([int(a.x), int(a.y), int(b.x), int(b.y), k])
                var w := float(seed % 1000) / 1000.0 - 0.5
                pts.append(p + perp * (w * 2.0 * amp))
        return pts

# ============================================================ the rounds

func _new_round() -> void:
        board = [0, 0, 0, 0, 0, 0, 0, 0, 0]
        for m in marks:
                if is_instance_valid(m):
                        m.queue_free()
        marks = [null, null, null, null, null, null, null, null, null]
        last_win_line = []
        win_holder.queue_redraw()
        rounds += 1
        turn = X if rounds % 2 == 1 else O   # the opener alternates
        clock = 0.0
        # the state resumes WITH the round (the round_over beat must never
        # swallow the next round)
        if turn == X:
                state = "play"
        else:
                state = "ai_wait"
                think_beat = _rng.randf_range(0.5, 0.95)
        cur = {"open": -1, "reply": -1, "fork": false}
        var pn := profile_next(profile_i)
        profile = pn[0]
        profile_i = pn[1]
        # THE COIN LAW (the owner): after every 3 completed rounds, the next
        # round opens with a GOGACoin in an EMPTY cell - whoever marks it
        # takes it (the CPU can steal it: it is a race)
        coin_cell = -1
        coin_t = 0.0
        if done_rounds > 0 and done_rounds % COIN_EVERY == 0:
                coin_cell = _rng.randi() % 9
        _note_refresh()
        _banner()

func _note_refresh() -> void:
        if coin_cell >= 0:
                note_lbl.text = "- a GOGACoin is on the board - mark its cell to take it -"
                note_lbl.add_theme_color_override("font_color", Color("8a6a14"))
        else:
                var left := COIN_EVERY - (done_rounds % COIN_EVERY)
                note_lbl.text = "the next GOGACoin lands in %d round%s" % [left,
                                "" if left == 1 else "s"]
                note_lbl.add_theme_color_override("font_color", Color(0.45, 0.42, 0.38))

func _tap_cell(i: int) -> void:
        if state != "play" or turn != X or int(board[i]) != 0:
                return
        Jukebox.sfx("xo_tap", -8.0)
        if cur["open"] < 0:
                cur["open"] = i
        _place(i, X)
        _after_move()

func _ai_move() -> void:
        var rng := RandomNumberGenerator.new()
        rng.seed = int(Time.get_unix_time_from_system() * 1000.0) \
                        ^ (rounds * 7919) ^ (board.hash() & 0xffff)
        var i := cpu_pick(board, profile, mem, rng)
        if i >= 0:
                # the reply bookkeeping: the CPU's first answer to the
                # player's opening is the move the memory grades
                if cur["open"] >= 0 and cur["reply"] < 0:
                        cur["reply"] = i
                _place(i, O)
        _after_move()

func _after_move() -> void:
        var w := winner_of(board)
        if w != 0:
                _resolve(w)
                return
        turn = O if turn == X else X
        clock = 0.0
        if turn == O:
                state = "ai_wait"
                think_beat = _rng.randf_range(0.5, 0.95)
        _banner()

func _banner() -> void:
        if state == "round_over":
                return                       # the verdict text stays up
        if turn == X:
                turn_lbl.text = "YOUR MOVE"
                turn_lbl.add_theme_color_override("font_color", X_RED)
        else:
                # the thinking dots live in the text (three pencil dots cycle)
                var n := int(_time * 2.5) % 3 + 1
                turn_lbl.text = "%s IS THINKING%s" % [PROFILES[profile]["title"],
                                " .".repeat(n)]
                turn_lbl.add_theme_color_override("font_color", O_BLUE)

func _place(i: int, who: int) -> void:
        board[i] = who
        _last_placed = i
        # THE COIN RACE: whoever marks the coin cell TAKES it
        if coin_cell >= 0 and i == coin_cell:
                _coin_taken(who)
        var mid := _cell_mid(i)
        var holder := Node2D.new()
        holder.position = mid
        holder.scale = Vector2.ONE * 0.15
        holder.rotation = -0.5 if who == X else 0.4
        world.add_child(holder)
        marks[i] = holder
        var lw := 20.0
        var seed_n := i * 31 + who * 7 + rounds * 13
        if who == X:
                _draw_x(holder, seed_n, lw)
        else:
                _draw_o(holder, seed_n, lw)
        var tw := holder.create_tween().set_parallel(true)
        tw.tween_property(holder, "scale", Vector2.ONE, 0.26) \
                .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tw.tween_property(holder, "rotation", 0.0, 0.3) \
                .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        Jukebox.sfx("xo_x" if who == X else "xo_o", -4.0,
                1.0 + _rng.randf() * 0.06)
        _pencil_dust(mid, X_RED if who == X else O_BLUE)
        # the live fork spy (feeds the memory's fork flag)
        if who == X and _winning_cells(board, X).size() >= 2:
                cur["fork"] = true

func _draw_x(holder: Node2D, seed_n: int, lw: float) -> void:
        var r := cell * 0.28
        for flips in 2:
                var sign_y := 1.0 if flips == 0 else -1.0
                var a := Vector2(-r, -r * sign_y)
                var b := Vector2(r, r * sign_y)
                # the dark under-stroke (the sketch depth)
                var under := Line2D.new()
                under.width = lw
                under.default_color = X_DARK
                under.points = _wobble_pts(a + Vector2(4, 4), b + Vector2(4, 4), seed_n + flips * 91)
                under.end_cap_mode = Line2D.LINE_CAP_ROUND
                holder.add_child(under)
                var main := Line2D.new()
                main.width = lw
                main.default_color = X_RED
                main.points = _wobble_pts(a, b, seed_n + flips * 37)
                main.end_cap_mode = Line2D.LINE_CAP_ROUND
                holder.add_child(main)

func _draw_o(holder: Node2D, seed_n: int, lw: float) -> void:
        var r := cell * 0.28
        var under := Line2D.new()
        under.width = lw
        under.default_color = O_DARK
        under.points = _wobble_ring(r + 3.0, seed_n + 55)
        under.end_cap_mode = Line2D.LINE_CAP_ROUND
        holder.add_child(under)
        var ring := Line2D.new()
        ring.width = lw
        ring.default_color = O_BLUE
        ring.points = _wobble_ring(r, seed_n)
        ring.end_cap_mode = Line2D.LINE_CAP_ROUND
        holder.add_child(ring)

## the wobble lives in GAME space (fixed per mark) - a rotated holder does
## not re-wobble the stroke
func _wobble_pts(a: Vector2, b: Vector2, seed_n: int) -> PackedVector2Array:
        var pts := PackedVector2Array()
        var rng := RandomNumberGenerator.new()
        rng.seed = seed_n
        var dir := (b - a).normalized()
        var perp := Vector2(-dir.y, dir.x)
        for k in 7:
                var f := float(k) / 6.0
                var p := a.lerp(b, f)
                pts.append(p + perp * rng.randf_range(-2.6, 2.6))
        return pts

func _wobble_ring(r: float, seed_n: int) -> PackedVector2Array:
        var pts := PackedVector2Array()
        var rng := RandomNumberGenerator.new()
        rng.seed = seed_n
        var a0 := rng.randf_range(0.0, TAU)
        for k in 25:
                var ang := a0 + TAU * float(k) / 24.0
                var rr := r + rng.randf_range(-2.4, 2.4)
                pts.append(Vector2(cos(ang), sin(ang)) * rr)
        pts.append(pts[0])
        return pts

func _coin_taken(who: int) -> void:
        coin_cell = -1
        if who == X:
                add_run_coins(1)
                Jukebox.sfx("xo_coin", -3.0)
                _toast_show("YOU TOOK THE GOGACOIN  +1")
                _pencil_dust(_cell_mid(_last_placed), Color("ffd24a"), 16)
        else:
                Jukebox.sfx("coin", -6.0, 0.8)
                _toast_show("THE CPU GRABBED THE COIN")
        if is_instance_valid(_coin_layer):
                _coin_layer.queue_redraw()   # the coin is GONE the same frame
        _note_refresh()

var _last_placed := 0

func _resolve(w: int) -> void:
        state = "round_over"
        clock = 0.0
        cur["result"] = w
        done_rounds += 1
        last_win_line = []
        if w == X or w == O:
                for line in WIN_LINES:
                        if int(board[line[0]]) == w and int(board[line[1]]) == w \
                                        and int(board[line[2]]) == w:
                                last_win_line = line
                                break
        if w == X:
                wins += 1
                streak += 1
                add_score(1)                     # THE OWNER'S LAW: win = +1
                turn_lbl.text = "YOU WIN  +1"
                turn_lbl.add_theme_color_override("font_color", X_RED)
                Jukebox.sfx("xo_win", -3.0)
                achievement_count("wins", 1)
                achievement_max("streak", streak)
        elif w == O:
                losses += 1
                streak = 0
                add_score(-1)                    # THE OWNER'S LAW: loss = -1
                turn_lbl.text = "%s WINS  -1" % PROFILES[profile]["title"]
                turn_lbl.add_theme_color_override("font_color", O_BLUE)
                Jukebox.sfx("xo_lose", -3.0)
        else:
                draws += 1
                add_score(0)                     # a draw pays nothing
                turn_lbl.text = "DRAW  -  THE WALL HOLDS"
                turn_lbl.add_theme_color_override("font_color", Color("4b5563"))
                Jukebox.sfx("xo_draw", -4.0)
        achievement_max("max_score", score)
        mem = remember(mem, cur)                 # THE 2-ROUND MEMORY
        _refresh_widget()
        win_holder.queue_redraw()
        check_achievements()

func _goga_tick(delta: float) -> void:
        _time += delta
        if state == "ai_wait":
                clock += delta
                _banner()                    # the thinking dots cycle in text
                # a pencil tick each half-beat while the machine thinks
                if clock < think_beat and int(clock * 6.0) != int((clock - delta) * 6.0):
                        Jukebox.sfx("xo_think", -14.0,
                                        1.0 + _rng.randf() * 0.1)
                if clock >= think_beat:
                        _ai_move()
        elif state == "round_over":
                clock += delta
                # the winners pulse (marks breathe on the strike)
                var pulse := 1.0 + 0.07 * sin(_time * 6.0)
                for i in last_win_line:
                        if is_instance_valid(marks[i]):
                                marks[i].scale = Vector2.ONE * pulse
                if clock >= 1.7:
                        _new_round()
        coin_t += delta
        _tick_dust(delta)
        win_holder.queue_redraw()
        if _coin_layer == null and coin_cell >= 0:
                _make_coin_layer()
        if is_instance_valid(_coin_layer):
                _coin_layer.queue_redraw()   # breathe, bob, glint, ERASE

var _coin_layer: Node2D = null

func coin_layer() -> Node2D:
        return _coin_layer

func _make_coin_layer() -> void:
        _coin_layer = Node2D.new()
        _coin_layer.z_index = 4
        _coin_layer.draw.connect(_draw_coin)
        world.add_child(_coin_layer)

func _draw_coin() -> void:
        if coin_cell < 0:
                return
        if int(board[coin_cell]) != 0:
                coin_cell = -1                  # safety: the cell just got marked
                return
        var tex: Texture2D = load("res://assets/ui/coin.png")
        if tex == null:
                return
        var pos := _cell_mid(coin_cell)
        pos.y += sin(coin_t * 3.2) * cell * 0.05
        var fade: float = clampf(coin_t / 0.4, 0.0, 1.0)
        _coin_layer.draw_circle(pos, cell * 0.42, Color(1.0, 0.85, 0.3, 0.14 * fade))
        var s: float = cell * 0.52 / float(tex.get_width())
        var pop: float = 1.0 + 0.07 * sin(coin_t * 4.4)
        _coin_layer.draw_set_transform(pos, 0.0, Vector2(s * pop * fade,
                        s / maxf(0.05, pop) * fade))
        _coin_layer.draw_texture(tex, -Vector2(tex.get_width(), tex.get_height()) / 2.0,
                        Color(1, 1, 1, fade))
        _coin_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        var ga: float = coin_t * 2.6
        _coin_layer.draw_arc(pos, cell * 0.37, ga, ga + 1.1, 30,
                        Color(1, 1, 1, 0.5 * fade), 2.4)

# ------------------------------------------------------- pencil dust fx

func _pencil_dust(at: Vector2, col: Color, n := 9) -> void:
        for i in n:
                _dust.append({
                        "x": at.x + _rng.randf_range(-cell * 0.2, cell * 0.2),
                        "y": at.y + _rng.randf_range(-cell * 0.2, cell * 0.2),
                        "vx": _rng.randf_range(-90.0, 90.0),
                        "vy": _rng.randf_range(-140.0, -20.0),
                        "life": _rng.randf_range(0.3, 0.6),
                        "max": 0.6,
                        "s": _rng.randf_range(2.0, 5.0),
                        "col": col,
                })
        if _dust.size() > 160:
                _dust = _dust.slice(_dust.size() - 160)

func _tick_dust(delta: float) -> void:
        for p in _dust.duplicate():
                p["life"] = float(p["life"]) - delta
                p["x"] = float(p["x"]) + float(p["vx"]) * delta
                p["y"] = float(p["y"]) + float(p["vy"]) * delta
                p["vy"] = float(p["vy"]) + 420.0 * delta
                if float(p["life"]) <= 0.0:
                        _dust.erase(p)
        if _dust_layer == null and _dust.size() > 0:
                _make_dust_layer()
        if is_instance_valid(_dust_layer):
                _dust_layer.queue_redraw()

var _dust_layer: Node2D = null

func dust_layer() -> Node2D:
        return _dust_layer

func _make_dust_layer() -> void:
        _dust_layer = Node2D.new()
        _dust_layer.z_index = 8
        _dust_layer.draw.connect(func():
                for p in _dust:
                        var a: float = clampf(float(p["life"]) / float(p["max"]), 0.0, 1.0)
                        var c: Color = p["col"]
                        c.a = a * 0.85
                        _dust_layer.draw_rect(Rect2(float(p["x"]) - float(p["s"]) * 0.5,
                                        float(p["y"]) - float(p["s"]) * 0.5,
                                        float(p["s"]), float(p["s"])), c))
        world.add_child(_dust_layer)
