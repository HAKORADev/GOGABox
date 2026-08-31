extends GogaGame
## XO Ladder - tic-tac-toe against a climbing AI. Ten rungs: the bottom is
## a sloppy random sparring partner, the top is a perfect minimax machine
## that never loses. Beat it to climb, lose and you slip one rung. Cash out
## any time - the rung is saved forever.
##
## Turn-based and calm, so it wears the ad banner (registry `banner: true`).

const X := 1                 # the player
const O := 2                 # the machine
const WIN_LINES := [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6],
]

var board: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0]
var rung := 1
var streak := 0
var rounds := 0
var turn := X                 # whose move it is (X player / O machine)
var state := "play"           # play | ai_wait | round_over
var clock := 0.0

var world: Node2D
var cells_ui: Array = []      # 9 tap targets
var marks: Array = []         # 9 Node2D marks
var rung_label: Label
var streak_label: Label
var banner: Label
var cash_btn: Button
var cell := 250
var board_origin := Vector2.ZERO

# ------------------------------------------------------------ pure AI core
# Static so tests (and future rematches) can drive the ladder without the
# scene: load("res://game/games/xo/xo.gd").ai_pick(...) etc.

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

static func _empty_cells(b: Array) -> Array:
        var out := []
        for i in b.size():
                if int(b[i]) == 0:
                        out.append(i)
        return out

static func _minimax(b: Array, to_move: int, depth: int, cap: int,
                alpha: float, beta: float) -> float:
        ## Score from O's side: win fast > win slow > draw > lose slow > lose fast.
        var w := winner_of(b)
        if w == O:
                return 10.0 - float(depth)
        if w == X:
                return float(depth) - 10.0
        if w == 3:
                return 0.0
        if depth >= cap:
                return 0.0     # shallow rungs cannot see the future
        var best := -INF if to_move == O else INF
        for i in _empty_cells(b):
                b[i] = to_move
                var s := _minimax(b, X if to_move == O else O, depth + 1, cap,
                        alpha, beta)
                b[i] = 0
                if to_move == O:
                        best = maxf(best, s)
                        alpha = maxf(alpha, s)
                else:
                        best = minf(best, s)
                        beta = minf(beta, s)
                if beta <= alpha:
                        break
        return best

static func ai_pick(board_in: Array, rung_: int,
                rng: RandomNumberGenerator) -> int:
        ## The ladder: lower rungs blunder often and see little; rung 10 is
        ## a perfect player (full minimax, no mistakes). Returns a cell 0..8.
        var b := board_in.duplicate()
        var empties := _empty_cells(b)
        if empties.is_empty():
                return -1
        # blunder chance shrinks as the ladder climbs; the TOP rung is a
        # perfect machine - it never blunders, never loses
        var mistake := 0.0 if rung_ >= 10 else \
                clampf(0.55 - float(rung_ - 1) * 0.06, 0.0, 0.55)
        if rng.randf() < mistake:
                return int(empties[rng.randi() % empties.size()])
        # vision grows with the rung: depth cap ~ 2 + rung/2 (rung 10 = full)
        var cap := 2 + int(rung_ / 2.0)
        if rung_ >= 10:
                cap = 99          # the top of the ladder sees EVERYTHING
        var best_score := -INF
        var picks := []
        for i in empties:
                b[i] = O
                var s := _minimax(b, X, 1, cap, -INF, INF)
                b[i] = 0
                if s > best_score + 0.001:
                        best_score = s
                        picks = [i]
                elif absf(s - best_score) <= 0.001:
                        picks.append(i)
        return int(picks[rng.randi() % picks.size()])

# ------------------------------------------------------------------- scene

func _goga_setup() -> void:
        rung = maxi(1, Box.counter(game_id, "rung"))
        var vp := get_viewport_rect().size
        world = Node2D.new()
        add_child(world)
        var bg := ColorRect.new()
        bg.color = Color("2a2144")
        bg.size = vp
        bg.z_index = -10
        bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
        world.add_child(bg)
        rung_label = Arc.label("", 40, Arc.CARD)
        rung_label.position = Vector2(64, 200)
        world.add_child(rung_label)
        streak_label = Arc.label("", 28, Arc.HOT)
        streak_label.position = Vector2(64, 258)
        world.add_child(streak_label)
        # board
        board_origin = Vector2((vp.x - cell * 3) / 2.0,
                vp.y * 0.5 - cell * 1.5 + 40)
        var p := Panel.new()
        p.add_theme_stylebox_override("panel",
                Arc.panel_style(Color("38305e"), 26))
        p.position = board_origin - Vector2(16, 16)
        p.size = Vector2(cell * 3 + 32, cell * 3 + 32)
        p.mouse_filter = Control.MOUSE_FILTER_IGNORE
        world.add_child(p)
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
        banner = Arc.label("", 52, Arc.CARD)
        banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        banner.position = Vector2(0, board_origin.y - 110)
        banner.custom_minimum_size = Vector2(vp.x, 60)
        world.add_child(banner)
        cash_btn = Arc.button("CASH OUT", Vector2(420, 96), 32, Arc.GOOD,
                func(): _cash_out())
        cash_btn.position = Vector2((vp.x - 420) / 2.0, vp.y - 210)
        _hud.add_child(cash_btn)
        _refresh()
        _new_round()

func _new_round() -> void:
        board = [0, 0, 0, 0, 0, 0, 0, 0, 0]
        for m in marks:
                if is_instance_valid(m):
                        m.queue_free()
        marks = [null, null, null, null, null, null, null, null, null]
        rounds += 1
        turn = X if rounds % 2 == 1 else O   # alternate the opener
        clock = 0.0
        if turn == X:
                state = "play"
                banner.text = "YOU OPEN"
        else:
                state = "ai_wait"
                banner.text = "IT OPENS"

func _tap_cell(i: int) -> void:
        if state != "play" or turn != X or int(board[i]) != 0:
                return
        _place(i, X)
        _after_move()

func _ai_move() -> void:
        var rng := RandomNumberGenerator.new()
        rng.seed = int(Time.get_unix_time_from_system()) ^ (rounds * 7919)
        var i := ai_pick(board, rung, rng)
        if i >= 0:
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
                banner.text = ""
        else:
                state = "play"
                banner.text = ""

func _place(i: int, who: int) -> void:
        board[i] = who
        var cx := i % 3
        var cy := i / 3
        var mid: Vector2 = board_origin + Vector2(cx * cell + cell / 2.0,
                cy * cell + cell / 2.0)
        var holder := Node2D.new()
        holder.position = mid
        holder.scale = Vector2.ONE * 0.2
        world.add_child(holder)
        marks[i] = holder
        var lw := 26.0
        if who == X:
                var col := Color("ff8a3c")
                for pts in [[Vector2(-70, -70), Vector2(70, 70)],
                                [Vector2(-70, 70), Vector2(70, -70)]]:
                        var l := Line2D.new()
                        l.width = lw
                        l.default_color = col
                        l.points = PackedVector2Array(pts)
                        l.end_cap_type = Line2D.LINE_CAP_ROUND
                        holder.add_child(l)
        else:
                var ring := Line2D.new()
                ring.width = lw
                ring.default_color = Color("78dcb4")
                ring.end_cap_type = Line2D.LINE_CAP_ROUND
                var pts := PackedVector2Array()
                for a in range(0, 361, 12):
                        var rad := deg_to_rad(float(a))
                        pts.append(Vector2(cos(rad), sin(rad)) * 72.0)
                ring.points = pts
                holder.add_child(ring)
        var tw := holder.create_tween()
        tw.tween_property(holder, "scale", Vector2.ONE, 0.22) \
                .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        Jukebox.sfx("pop", -6.0, 1.2 if who == X else 0.9)

func _resolve(w: int) -> void:
        state = "round_over"
        clock = 0.0
        if w == X:
                streak += 1
                rung = mini(10, rung + 1)
                add_score(5)
                add_run_coins(1)
                banner.text = "YOU WIN  -  RUNG %d" % rung
                Jukebox.sfx("star", -4.0)
        elif w == O:
                streak = 0
                rung = maxi(1, rung - 1)
                banner.text = "IT WINS  -  BACK TO RUNG %d" % rung
                Jukebox.sfx("error", -4.0)
        else:
                add_score(1)
                banner.text = "DRAW  -  THE WALL HOLDS"
                Jukebox.sfx("confirm", -6.0)
        achievement_max("rung", rung)
        achievement_max("streak", streak)
        check_achievements()
        _refresh()

func _goga_tick(delta: float) -> void:
        if state == "ai_wait":
                clock += delta
                if clock >= 0.55:          # a thinking beat
                        _ai_move()
        elif state == "round_over":
                clock += delta
                if clock >= 1.25:
                        _new_round()

func _refresh() -> void:
        rung_label.text = "RUNG %d / 10" % rung
        if streak >= 2:
                streak_label.text = "ON FIRE x%d" % streak
        else:
                streak_label.text = "win streak %d" % streak

func _cash_out() -> void:
        if over:
                return
        banner.text = "CASHED OUT AT RUNG %d" % rung
        check_achievements()
        finish_run(score)
