extends Node
## xo_probe - v0.2.8: drives the SKETCH REMAKE headless. The owner renamed
## it to plain XO and ordered a remake with no ladder, no cash out and no
## difficulty levels. These laws pin the remake: the scoring (+1 / -1 / 0,
## bonus /2), the 3-round coin race (whoever marks the cell takes it, the
## CPU included), the adaptive CPU (four profiles, 2-round memory, the
## burned reply never repeats, the live fork spy), the pong-style END
## banking, and the balance (hard to beat, never perfect - 600 seeded
## games).
##
##   godot --headless --path projects/gogabox res://tests/xo_probe.tscn

var fails := 0

func _check(cond: bool, msg: String) -> void:
        print(("  PASS: " if cond else "  FAIL: ") + msg)
        if not cond:
                fails += 1

var XO: GDScript   # the xo script (the static core lives here)

func _run() -> void:
        Box.reset_all()
        print("== xo_probe: the sketch remake v0.2.8 ==")
        XO = load("res://game/games/xo/xo.gd")

        # ---- registry sanity (the owner's laws) ----
        var xr: Dictionary = GameReg.get_game("xo")
        _check(not xr.is_empty(), "xo is in the registry")
        _check(String(xr["title"]) == "XO", "the title is JUST XO (no ladder)")
        _check(int(xr["coin_div"]) == 2, "xo run bonus = score/2 (owner)")
        _check(bool(xr["banner"]), "xo carries the ad banner")
        _check(int(xr["fee"]) == 10, "the round fee stays 10")

        # ---- boot the real scene ----
        var g: GogaGame = XO.new()
        g.game_id = "xo"
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        _check(g.pause_end_run, "the PONG design: the pause sheet owns the END bank")
        _check(g.marks.size() == 9, "the board built 9 cell slots")
        _check(g.turn == g.X and String(g.state) == "play", "the player opens round 1")
        _check(String(g.profile) != "", "the CPU wears a profile from round 1")
        _check(g.you_lbl != null and g.draw_lbl != null and g.cpu_lbl != null,
                "the YOU / DRAWS / CPU widget exists")
        _check(g.coin_cell < 0, "round 1 of a fresh run carries no coin")

        # ---- THE SCORING LAW: +1 / -1 / 0 ----
        g.board = [1, 1, 0, 2, 2, 0, 0, 0, 0]
        g._tap_cell(2)      # X completes the top row
        _check(int(g.score) == 1, "a WIN pays exactly +1")
        _check(int(g.wins) == 1 and int(g.done_rounds) == 1, "the round was counted")
        _check(g.mem.size() == 1, "the finished round entered the memory")
        _check(String(g.state) == "round_over", "the verdict beat holds the board")
        _check(g.last_win_line.size() == 3, "the winning line was found for the strike")
        # the LOSS: O answers and completes their row
        g.board = [2, 2, 0, 1, 1, 0, 0, 0, 0]
        g._place(2, g.O)
        g._after_move()
        _check(int(g.score) == 0, "a LOSS pays exactly -1 (1 - 1 = 0)")
        _check(int(g.losses) == 1, "the loss was counted")
        # THE FLOOR LAW (owner v0.2.9: "-1 on 0 should be 0"): a loss at
        # score 0 stays at 0 - never -1 -2 -3
        g.set_score(0)
        g._place(5, g.O)
        g.board[3] = 2
        g.board[4] = 2
        g._after_move()
        _check(int(g.score) == 0, "a loss at 0 STAYS 0 (the floor law)")
        # the DRAW pays nothing
        g.set_score(5)
        g.board = [1, 2, 1, 2, 1, 2, 2, 1, 2]
        g._after_move()
        _check(int(g.score) == 5, "a DRAW pays exactly 0")
        _check(int(g.draws) == 1, "the draw was counted")
        _check(g.mem.size() == 2, "the memory now holds the 2 latest rounds")

        # ---- THE COIN RACE (the owner: whoever marks the cell takes it) ----
        g.done_rounds = 3
        g._new_round()
        _check(g.coin_cell >= 0, "after 3 completed rounds a coin is on the board")
        var cc: int = g.coin_cell
        g.turn = g.X
        g.state = "play"
        var before: int = int(g.run_coins)
        g._tap_cell(cc)     # the player marks the coin cell
        _check(int(g.run_coins) == before + 1,
                "marking the coin cell TAKES it (+1 run coin)")
        _check(g.coin_cell < 0, "the coin is spent")
        # the CPU can steal it too
        g.done_rounds = 6
        g._new_round()
        cc = g.coin_cell
        _check(cc >= 0, "the next 3-round coin arrived")
        before = int(g.run_coins)
        g.cur["open"] = 0
        g._place(cc, g.O)
        _check(int(g.run_coins) == before, "the CPU takes the coin - the player gains NOTHING")
        _check(g.coin_cell < 0, "the stolen coin is spent too")
        # no coin on ordinary rounds
        g.done_rounds = 7
        g._new_round()
        _check(g.coin_cell < 0, "an ordinary round carries no coin")

        # ---- THE ADAPTIVE CORE: the burned reply never repeats ----
        var mem: Array = []
        mem = XO.remember(mem, {"open": 4, "reply": 0, "result": 1, "fork": false})
        mem = XO.remember(mem, {"open": 4, "reply": 0, "result": 1, "fork": false})
        var flags: Dictionary = XO.adapt(mem)
        _check(int(flags["burned"]) == 0,
                "two rounds of the same opening burned the losing reply")
        var rng := RandomNumberGenerator.new()
        var picked0 := 0
        for s in range(200):
                rng.seed = 31000 + s
                if int(XO.cpu_pick([0, 0, 0, 0, 1, 0, 0, 0, 0], "sage", mem, rng)) == 0:
                        picked0 += 1
        _check(picked0 == 0,
                "the burned reply came back 0/200 times (the owner: do not fall in the same pattern)")
        var rng2 := RandomNumberGenerator.new()
        var free_hits := 0
        for s in range(200):
                rng2.seed = 32000 + s
                if int(XO.cpu_pick([0, 0, 0, 0, 1, 0, 0, 0, 0], "sage", [], rng2)) == 0:
                        free_hits += 1
        _check(free_hits > 0,
                "without the memory the reply is free again (%d/200 picked cell 0)" % free_hits)

        # ---- THE ONE-MOVE LAW (the owner's biggest catch: the CPU played
        # round after round because the state stayed "ai_wait") ----
        var g5: GogaGame = XO.new()
        g5.game_id = "xo"
        add_child(g5)
        await get_tree().process_frame
        g5._place(4, g5.X)          # the player opens center
        g5._after_move()
        _check(String(g5.state) == "ai_wait" and g5.turn == g5.O,
                "after the player's move the CPU thinks once")
        g5.clock = 9.9              # skip the think beat
        g5._goga_tick(1.0 / 60.0)   # the CPU moves NOW
        _check(String(g5.state) == "play" and g5.turn == g5.X,
                "after the CPU's move the state is REALLY play/turn X")
        var o_marks := 0
        var x_marks := 0
        for v in g5.board:
                if int(v) == g5.O:
                        o_marks += 1
                elif int(v) == g5.X:
                        x_marks += 1
        _check(o_marks == 1 and x_marks == 1,
                "one player mark, ONE cpu mark (no 3-round CPU spree)")
        g5.clock = 0.0
        for f in 180:               # 3 seconds of ticking
                g5._goga_tick(1.0 / 60.0)
                if String(g5.state) == "play":
                        g5.clock = 0.0
        o_marks = 0
        for v in g5.board:
                if int(v) == g5.O:
                        o_marks += 1
        _check(o_marks == 1, "3 seconds of ticks: the CPU did NOT move again")

        # ---- THE OPENER LAW (owner v0.2.9: the loser starts next) ----
        var g6: GogaGame = XO.new()
        g6.game_id = "xo"
        add_child(g6)
        await get_tree().process_frame
        _check(g6.turn == g6.X, "round 1: the player opens")
        g6.board = [1, 1, 0, 2, 2, 0, 0, 0, 0]
        g6._tap_cell(2)             # X wins -> O (the loser) opens next
        _check(g6.next_opener == g6.O, "the loser (CPU) won the next opener")
        g6.board = [2, 2, 0, 1, 1, 0, 0, 0, 0]
        g6._place(2, g6.O)
        g6._after_move()            # O wins -> X (the loser) opens next
        _check(g6.next_opener == g6.X, "after a CPU win the player opens")
        g6.board = [1, 2, 1, 2, 1, 2, 2, 1, 2]
        g6._after_move()            # the draw flips
        _check(g6.next_opener == g6.O, "a draw flips the opener")

        # ---- the strike: drawn once, no pulse ----
        var g7: GogaGame = XO.new()
        g7.game_id = "xo"
        add_child(g7)
        await get_tree().process_frame
        g7.board = [1, 1, 0, 2, 2, 0, 0, 0, 0]
        g7._tap_cell(2)
        _check(g7.last_win_line.size() == 3 and g7.strike_t == 0.0,
                "the win arms the one-shot strike")
        for f in 40:
                g7._goga_tick(1.0 / 60.0)
        _check(absf(g7.strike_t - 1.0) < 0.001, "the strike grew ONCE to full")
        var stable: float = float(g7.strike_t)
        for f in 120:
                g7._goga_tick(1.0 / 60.0)
        _check(absf(g7.strike_t - stable) < 0.001,
                "the strike STAYS full (no oscillation)")

        # ---- the live fork spy + the memory flag ----
        var g2: GogaGame = XO.new()
        g2.game_id = "xo"
        add_child(g2)
        await get_tree().process_frame
        g2.board = [1, 0, 1, 0, 1, 2, 0, 2, 0]
        g2.cur = {"open": 0, "reply": -1, "fork": false}
        g2._place(4, g2.X)   # X now threatens BOTH cell 1 and cell 8
        _check(bool(g2.cur["fork"]), "the live fork spy marked the player's fork")
        var fmem: Array = []
        fmem = XO.remember(fmem, {"open": 0, "reply": 8, "result": 3, "fork": true})
        _check(bool(XO.adapt(fmem)["forkry"]), "a fork in the memory wakes the watch")
        fmem = XO.remember(fmem, {"open": 3, "reply": 1, "result": 3, "fork": false})
        fmem = XO.remember(fmem, {"open": 8, "reply": 2, "result": 2, "fork": false})
        _check(fmem.size() == 2 and int(fmem[0]["open"]) == 3,
                "the memory holds ONLY the 2 latest rounds (FIFO)")
        _check(bool(XO.adapt(fmem)["forkry"]) == false,
                "the fork memory EXPIRED after 2 rounds (the owner's law)")

        # ---- the CPU core: never illegal, always an empty cell ----
        var illegal := 0
        for s in range(300):
                rng.seed = 40000 + s
                var b: Array = [0, 2, 0, 1, 0, 0, 0, 0, 1]
                var mv: int = XO.cpu_pick(b, "rusher", [], rng)
                if mv < 0 or int(b[mv]) != 0:
                        illegal += 1
        _check(illegal == 0, "300 picks on a live board: every pick was a legal empty cell")

        # ---- the balance law, 600 seeded games (hard to beat, never perfect) ----
        var profs: Array = XO.PROFILES.keys()
        _check(profs.size() == 4, "four profiles rotate")
        var cwins := 0
        var closses := 0
        var cdraws := 0
        var games := 600
        for gi in range(games):
                rng.seed = 77000 + gi
                var pr: String = profs[gi % profs.size()]
                var b := [0, 0, 0, 0, 0, 0, 0, 0, 0]
                var cpu_is := 2 if gi % 2 == 0 else 1
                var mover := 1
                var res := 0
                for step in range(9):
                        if mover == cpu_is:
                                var mv: int = XO.cpu_pick(b, pr, [], rng)
                                if mv < 0:
                                        break
                                b[mv] = mover
                        else:
                                var es: Array = XO.empty_cells(b)
                                b[es[rng.randi() % es.size()]] = mover
                        res = XO.winner_of(b)
                        if res != 0:
                                break
                        mover = 2 if mover == 1 else 1
                if res == cpu_is:
                        cwins += 1
                elif res != 0 and res != 3:   # 3 = the draw (not a loss!)
                        closses += 1
                else:
                        cdraws += 1
        var wr := float(cwins) / float(games)
        var lr := float(closses) / float(games)
        _check(wr > 0.5 and wr < 0.92,
                "600 games: the CPU wins most but misses real chances now (%.0f%%)" % [wr * 100.0])
        _check(lr > 0.0 and lr < 0.3,
                "600 games: the user CAN win sometimes (%.0f%% losses - owner v0.2.9)" % [lr * 100.0])

        # ---- vs a DECENT player (greedy: takes wins, blocks, prefers
        # center/corners) the CPU must NOT keep winning - decent play draws
        # (the owner: not smart enough to always win)
        var dwins := 0
        var dloss := 0
        var ddraws := 0
        var dgames := 400
        for gi in range(dgames):
                rng.seed = 88000 + gi
                var pr: String = profs[gi % profs.size()]
                var b := [0, 0, 0, 0, 0, 0, 0, 0, 0]
                var cpu_is := 2 if gi % 2 == 0 else 1
                var mover := 1
                var res := 0
                for step in range(9):
                        if mover == cpu_is:
                                # cpu_pick ALWAYS plays the O side (the real
                                # game calls it for O only) - when the sim
                                # casts the CPU as X, ask it through the
                                # MIRRORED board (1<->2, cells unchanged)
                                var ask: Array = b
                                if cpu_is == 1:
                                        ask = []
                                        for v in b:
                                                ask.append(0 if int(v) == 0 else 3 - int(v))
                                var mv: int = XO.cpu_pick(ask, pr, [], rng)
                                if mv < 0:
                                        break
                                b[mv] = mover
                        else:
                                var mv2: int = _greedy_pick(b, rng,
                                                1 if cpu_is == 2 else 2)
                                if mv2 < 0:
                                        break
                                b[mv2] = mover
                        res = XO.winner_of(b)
                        if res != 0:
                                break
                        mover = 2 if mover == 1 else 1
                if res == 0 or res == 3:      # winner_of: 3 = the draw
                        ddraws += 1
                elif res == cpu_is:
                        dwins += 1
                else:
                        dloss += 1
        var dr := float(ddraws) / float(dgames)
        var dlr := float(dloss) / float(dgames)
        _check(dr > 0.25,
                "vs a DECENT player the CPU still draws most (%.0f%%)" % [dr * 100.0])
        _check(dlr < 0.45,
                "vs a DECENT player the CPU is beatable but holds (%.0f%% losses)" % [dlr * 100.0])

        # ---- the 3-round rhythm on a LIVE run ----
        var g3: GogaGame = XO.new()
        g3.game_id = "xo"
        add_child(g3)
        await get_tree().process_frame
        _check(g3.coin_cell < 0, "fresh run: no coin (round 1)")
        g3.done_rounds = 2
        g3._new_round()
        _check(g3.coin_cell < 0, "round 3: still no coin (it lands AFTER 3 rounds)")
        g3.done_rounds = 3
        g3._new_round()
        _check(g3.coin_cell >= 0, "round 4: the coin is on the board")

        print("== xo_probe done: %s ==" % ("ALL PASS" if fails == 0 else "%d FAIL" % fails))
        get_tree().quit(1 if fails > 0 else 0)

## a DECENT opponent: take the win, block the threat, then center >
## corners > edges. `side` is who the greedy is playing as.
func _greedy_pick(b: Array, r: RandomNumberGenerator, side: int) -> int:
        var es: Array = XO.empty_cells(b)
        if es.is_empty():
                return -1
        var foe := 2 if side == 1 else 1
        for who in [side, foe]:
                for line in XO.WIN_LINES:
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
        var order := [4, 0, 2, 6, 8, 1, 3, 5, 7]
        for c in order:
                if int(b[c]) == 0:
                        return c
        return int(es[r.randi() % es.size()])

func _ready() -> void:
        _run.call_deferred()
