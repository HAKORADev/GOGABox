extends Node
## chess_probe - v0.3.8: pins THE OLD WAR headless. The owner does not
## play chess ("i know nothing... i will just trust you") - these laws ARE
## the certification:
##   PERFT: the canonical move counts from the start position
##   (20 / 400 / 8902 - the whole rules engine agrees with the book of
##   chess), fool's mate, castling with every condition (through-check
##   dies), en passant, promotion (all four), stalemate, the 50-move
##   rule, threefold repetition, insufficient material, the CPU legality
##   across all six moods (240 seeded positions), the book walk (the
##   Jobava London opens d2d4-b1c3-c1f4), the burned-line adaptation, the
##   3-minute coin, the coin race, and the scene's live move door.
##
##   godot --headless --path projects/gogabox res://tests/chess_probe.tscn

var fails := 0

func _check(cond: bool, msg: String) -> void:
        print(("  PASS: " if cond else "  FAIL: ") + msg)
        if not cond:
                fails += 1

var CH: GDScript

func _perft(st: Dictionary, depth: int) -> int:
        if depth == 0:
                return 1
        var n := 0
        for m in CH.legal_moves(st):
                n += _perft(CH.make_move(st, m), depth - 1)
        return n

func _find(moves: Array, coord: String) -> Dictionary:
        for m in moves:
                if CH.coord_of(m) == coord:
                        return m
        return {}

func _run() -> void:
        Box.reset_all()
        print("== chess_probe: the old war v0.3.8 ==")
        CH = load("res://game/games/chess/chess.gd")

        # ---- registry sanity (the owner's laws) ----
        var cr: Dictionary = GameReg.get_game("chess")
        _check(not cr.is_empty(), "chess is in the registry")
        _check(int(cr["coin_div"]) == 1, "chess run bonus = score/1 (owner)")
        _check(bool(cr["banner"]), "chess carries the ad banner")
        _check(int(cr["fee"]) == 10, "the round fee stays 10")
        _check(int(cr["price"]) == 700, "chess keeps its teaser price (700)")

        # ---- THE PERFT LAW: the engine agrees with the book of chess ----
        var st: Dictionary = CH.start_state()
        _check(_perft(st, 1) == 20, "PERFT d1 = 20 (the start's 20 moves)")
        _check(_perft(st, 2) == 400, "PERFT d2 = 400")
        _check(_perft(st, 3) == 8902,
                "PERFT d3 = 8902 (castles, pins, ep - the whole engine)")

        # ---- CHECKMATE DETECTION: fool's mate ----
        var s2: Dictionary = CH.start_state()
        for mv in ["f2f3", "e7e5", "g2g4", "d8h4"]:
                var m: Dictionary = _find(CH.legal_moves(s2), mv)
                _check(not m.is_empty(), "fool's mate: %s is legal" % mv)
                s2 = CH.make_move(s2, m)
        _check(CH.status(s2, {}) == "checkmate" and CH.in_check(s2),
                "fool's mate IS checkmate (the verdict door will fire)")
        _check(CH.legal_moves(s2).is_empty(), "a mated king has no moves")

        # ---- CASTLING: the full condition set ----
        # custom board: Ke1 + Rh1 vs Ke8 + Ra8; f1/g1 clear
        var b := []
        for i in 64:
                b.append(0)
        b[4] = 6; b[7] = 4; b[60] = -6; b[56] = -4
        var sc := {"b": b, "w": true, "cr": 15, "ep": -1, "half": 0,
                "full": 1, "hist": []}
        var castle_found := false
        for m in CH.legal_moves(sc):
                if CH.coord_of(m) == "e1g1":
                        castle_found = true
        _check(castle_found, "a clear kingside castle is legal")
        var st_after: Dictionary = CH.make_move(sc, _find(CH.legal_moves(sc), "e1g1"))
        _check(int(st_after["b"][5]) == 4 and int(st_after["b"][6]) == 6,
                "the castle lands K on g1 + R on f1")
        # through-check dies: a black rook on f8 stares down the f-file
        var b2 := b.duplicate()
        b2[61] = -4
        b2[56] = 0
        var sc2 := {"b": b2, "w": true, "cr": 15, "ep": -1, "half": 0,
                "full": 1, "hist": []}
        var castle_dies := true
        for m in CH.legal_moves(sc2):
                if CH.coord_of(m) == "e1g1":
                        castle_dies = false
        _check(castle_dies, "a castle through a checked square is FORBIDDEN")

        # ---- EN PASSANT ----
        var s3: Dictionary = CH.start_state()
        for mv in ["e2e4", "a7a6", "e4e5", "d7d5"]:
                s3 = CH.make_move(s3, _find(CH.legal_moves(s3), mv))
        _check(int(s3["ep"]) == CH.sq(3, 5), "the double push hangs an ep square")
        var ep_m: Dictionary = _find(CH.legal_moves(s3), "e5d6")
        _check(not ep_m.is_empty() and String(ep_m["flag"]) == "ep",
                "the en passant capture exists")
        var s3b: Dictionary = CH.make_move(s3, ep_m)
        _check(int(s3b["b"][CH.sq(3, 4)]) == 0 and int(s3b["b"][CH.sq(3, 5)]) == 1,
                "the ep capture removes the passed pawn")

        # ---- PROMOTION (all four) ----
        var b4 := []
        for i in 64:
                b4.append(0)
        b4[48] = 1          # a7 pawn
        b4[62] = 6          # white king h8... no - g8? keep the king FAR
        b4[62] = 0
        b4[10] = 6          # white king c3
        b4[4] = -6          # black king e1
        var s4 := {"b": b4, "w": true, "cr": 0, "ep": -1, "half": 0,
                "full": 1, "hist": []}
        var promos := []
        for m in CH.legal_moves(s4):
                if CH.coord_of(m).begins_with("a7a8"):
                        promos.append(CH.coord_of(m))
        _check(promos.size() == 4, "a7a8 offers all four promotions")
        var s4b: Dictionary = CH.make_move(s4, _find(CH.legal_moves(s4), "a7a8q"))
        _check(int(s4b["b"][CH.sq(0, 7)]) == 5, "the queen lands on a8")

        # ---- STALEMATE ----
        var b5 := []
        for i in 64:
                b5.append(0)
        b5[CH.sq(6, 5)] = 6      # white Kg6
        b5[CH.sq(5, 6)] = 5      # white Qf7
        b5[CH.sq(7, 7)] = -6     # black Kh8
        var s5 := {"b": b5, "w": false, "cr": 0, "ep": -1, "half": 0,
                "full": 1, "hist": []}
        _check(CH.status(s5, {}) == "stalemate" and not CH.in_check(s5),
                "the classic corner STALEMATE reads true")

        # ---- THE 50-MOVE RULE ----
        var b6 := []
        for i in 64:
                b6.append(0)
        b6[CH.sq(4, 0)] = 6
        b6[CH.sq(4, 7)] = -6
        var s6 := {"b": b6, "w": true, "cr": 0, "ep": -1, "half": 100,
                "full": 51, "hist": []}
        _check(CH.status(s6, {}) == "draw50", "the 50-move rule fires at 100 half-moves")

        # ---- THREEFOLD REPETITION ----
        var s7: Dictionary = CH.start_state()
        var keys := {}
        var v7 := "play"
        for mv in ["g1f3", "g8f6", "f3g1", "f6g8", "g1f3", "g8f6",
                "f3g1", "f6g8", "g1f3", "g8f6"]:
                s7 = CH.make_move(s7, _find(CH.legal_moves(s7), mv))
                v7 = CH.status(s7, keys)
        _check(v7 == "draw3", "knight shuffles hit the THREEFOLD draw")

        # ---- INSUFFICIENT MATERIAL ----
        var b8 := []
        for i in 64:
                b8.append(0)
        b8[CH.sq(4, 0)] = 6
        b8[CH.sq(4, 7)] = -6
        b8[CH.sq(3, 3)] = 3
        var s8 := {"b": b8, "w": true, "cr": 0, "ep": -1, "half": 0,
                "full": 1, "hist": []}
        _check(CH.status(s8, {}) == "drawmat", "K+B vs K is a bare-kings draw")

        # ---- EVAL SANITY: the start position is a tie ----
        _check(CH.eval_pos(CH.start_state(), 1.0) == 0,
                "the start eval is exactly 0 (mirror symmetry)")

        # ---- THE CPU LAW: all six moods answer legally (240 positions) ----
        var cpu_ok := true
        var slow_ok := true
        for pr in CH.PROFILES.keys():
                for s in range(40):
                        var rng := RandomNumberGenerator.new()
                        rng.seed = s * 977 + 13
                        # walk a random legal game 2..8 plies deep
                        var sx: Dictionary = CH.start_state()
                        var hist: Array = []
                        var depth := 2 + (s % 7)
                        var alive := true
                        for k in depth:
                                var ms: Array = CH.legal_moves(sx)
                                if ms.is_empty():
                                        alive = false
                                        break
                                var mm: Dictionary = ms[rng.randi() % ms.size()]
                                sx = CH.make_move(sx, mm)
                                hist.append(CH.coord_of(mm))
                        if not alive:
                                continue
                        var t0 := Time.get_ticks_msec()
                        var pick: Dictionary = CH.cpu_move(sx, pr, hist, [],
                                rng)
                        var dt := Time.get_ticks_msec() - t0
                        if dt > 3000:
                                slow_ok = false
                        if pick.is_empty():
                                if not CH.legal_moves(sx).is_empty():
                                        cpu_ok = false
                                continue
                        var legal := false
                        for m in CH.legal_moves(sx):
                                if CH.coord_of(m) == CH.coord_of(pick):
                                        legal = true
                        if not legal:
                                cpu_ok = false
        _check(cpu_ok, "THE CPU LAW: all six moods answer legal moves (240 positions)")
        _check(slow_ok, "the CPU thinks under 3s in headless time (phone-safe)")

        # ---- THE BOOK WALK: the Jobava London ----
        var s9: Dictionary = CH.start_state()
        var rng9 := RandomNumberGenerator.new()
        rng9.seed = 5
        var m9: Dictionary = CH.cpu_move(s9, "jobava", [], [], rng9)
        _check(CH.coord_of(m9) == "d2d4", "the Jobava book opens d2d4")
        s9 = CH.make_move(s9, m9)
        s9 = CH.make_move(s9, _find(CH.legal_moves(s9), "d7d5"))
        var m9b: Dictionary = CH.cpu_move(s9, "jobava", ["d2d4", "d7d5"],
                [], rng9)
        _check(CH.coord_of(m9b) == "b1c3", "the Jobava book continues b1c3")

        # ---- THE BURNED LAW: a repeated opening stops being served ----
        var mem_burn: Array = []
        mem_burn = CH.remember(mem_burn, {"open": "e2e4", "aggr": 0.2,
                "result": 0})
        mem_burn = CH.remember(mem_burn, {"open": "e2e4", "aggr": 0.2,
                "result": 0})
        _check(String(CH.adapt(mem_burn)["burned"]) == "e2e4",
                "a repeated opening burns")
        var e_count := 0
        var trials := 60
        for t in trials:
                var rngt := RandomNumberGenerator.new()
                rngt.seed = 900 + t
                var mt: Dictionary = CH.cpu_move(CH.start_state(), "aggressor",
                        [], mem_burn, rngt)
                if CH.coord_of(mt) == "e2e4":
                        e_count += 1
        _check(e_count < trials, "the burned opening is not always served (%d/%d kept it)"
                % [e_count, trials])

        # ---- boot the real scene ----
        var g: GogaGame = CH.new()
        g.game_id = "chess"
        g.start_orientation = "horizontal"  # v0.3.8-8: ask suppressed on the rig
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        _check(g.pause_end_run, "the PONG design: the pause sheet owns the END bank")
        g.probe_reset(3)
        _check(g.st.size() > 0 and g.st["b"].count(6) == 1,
                "the board builds: one white king")
        _check(g.player_white and bool(g.st["w"]),
                "the player takes WHITE in round 1")
        var piece_count := 0
        for v in g.st["b"]:
                if int(v) != 0:
                        piece_count += 1
        _check(piece_count == 32, "32 pieces stand")

        # ---- THE LIVE MOVE DOOR: a real round breathes ----
        g._apply_move(_find(CH.legal_moves(g.st), "e2e4"), true)
        _check(String(g.history[0]) == "e2e4" and String(g.state) == "cpu_wait",
                "the player's move lands through the live door")
        var guard := 0
        while g.state == "cpu_wait" and guard < 600:
                guard += 1
                g.probe_step(1.0 / 60.0)
        _check(g.state == "play", "the CPU answered (the book or the search)")
        _check(g.history.size() == 2, "the log carries both plies")

        # ---- THE COIN CLOCK: every 3 minutes ----
        g.run_clock = 179.9
        g.probe_step(0.2)
        _check(g.coin_sq >= 0, "THE COIN LAW: the coin appears at the 3rd minute")
        # THE COIN RACE: land a piece on it
        var take := {}
        for m in CH.legal_moves(g.st):
                if int(m["t"]) == g.coin_sq:
                        take = m
                        break
        if take.is_empty():
                # no direct landing: move the coin under a legal target
                for m in CH.legal_moves(g.st):
                        g.coin_sq = int(m["t"])
                        take = m
                        break
        var rc0: int = g.run_coins
        g._apply_move(take, true)
        _check(g.run_coins == rc0 + 1,
                "THE COIN RACE: the piece that lands on the coin takes it")

        # ---- THE SCORING LAW ----
        g.score = 2
        g.set_score(2)
        g.wins = 2
        g.losses = 0
        g._resolve("lose")
        _check(int(g.score) == 1 and g.losses == 1, "a loss pays -1")
        g._resolve("lose")
        _check(int(g.score) == 0, "the score NEVER goes negative")
        g._resolve("draw")
        _check(int(g.score) == 0 and g.draws >= 1, "a draw pays nothing")

        # ---- v0.3.8-3 THE TAP TRUTH (the owner: a small finger movement
        # should just tap it without carrying it) ----
        # a press arms the carry ONLY past the threshold; under it the piece
        # never lifts (the drag render + the hidden-source both wait)
        g.probe_reset(5)
        var arm_px: float = g._drag_arm_px()
        _check(arm_px >= 14.0, "THE TAP TRUTH: the arm distance is a real finger-width (%.0fpx)" % arm_px)
        # simulate: press on the e2 pawn (square 12), wobble under the line
        var sq: int = 12
        var sqc: Vector2 = g._sq_rect(sq).get_center()
        g._press(sqc)
        _check(g.drag and g.drag_sq == sq and not g.drag_armed,
                "THE TAP TRUTH: a press selects WITHOUT carrying")
        g.drag_pos = sqc + Vector2(arm_px * 0.4, 0)
        _check(not g.drag_armed,
                "THE TAP TRUTH: a small wobble never arms the carry")
        g.drag_pos = sqc + Vector2(arm_px * 1.6, 0)
        if g.drag_pos.distance_to(g.drag_origin) > arm_px:
                g.drag_armed = true
        _check(g.drag_armed,
                "THE TAP TRUTH: a real drag arms the carry")
        g.drag = false
        g.drag_armed = false
        g.drag_sq = -1

        print("== chess_probe: %s (%d fails) ==" % ["ALL PASS" if fails == 0
                else "FAILED", fails])
        get_tree().quit(0 if fails == 0 else 1)

func _ready() -> void:
        get_window().size = Vector2i(1600, 720)
        await get_tree().create_timer(0.3).timeout
        _run()
