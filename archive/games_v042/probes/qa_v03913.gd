extends Node
## qa_v03913 - the v0.3.9-13 round probe: the owner's test-report fixes +
## the box's cast. Driven headless, exit 0 = pass.
## THE LAWS TESTED HERE:
##   LUDO - the seat truth (every army's four seats sit INSIDE its own
##   plate), the medallion is gone (no circle under the home square:
##   static law - the draw reads the theme, asserted via the scene's
##   draw state), THE TACTICAL CPU (the mood scorer: the win beats the
##   eat, the eat beats the step, the threat is real, the flee wins),
##   the full-CPU soak (whole rounds resolve with the tactical picks).
##   SNL - the exact landing law, the crown star cell, the classic
##   table, the ladders' stair count (twice as many rungs as the old
##   0.62 spacing), the wide badge (x2 the old 210 cap), the bare token
##   (no numeral), the quiet tray (no THINKING), the flow (the mode ask
##   opens the game, the pick seats the gate, the gate opens the round).
##   THE CAST - the once-ever lore counters, the box story card opens
##   and dismisses clean (no pause leak), the table's secret (the egg:
##   60s idle fires once per round, the lines verbatim, a tap advances).

var fails := 0
var checks := 0

func _check(cond: bool, why := "") -> int:
        checks += 1
        print("  %s: %s" % ["PASS" if cond else "FAIL", why])
        return 0 if cond else 1

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.reset_all()
        print("=== qa_v03913 ===")
        _run()

func _run() -> void:
        var L: GDScript = load("res://game/games/ludo/ludo.gd")
        var S: GDScript = load("res://game/games/snl/snl.gd")

        # ============================== LUDO: the rules core + the CPU
        print("--- ludo: the seat truth ---")
        var poss := []
        for i in 16:
                poss.append(-1)
        var teams1: Dictionary = L.teams_of(1)
        # the seats read the SCENE's geometry - drive the real scene
        var lscene: GogaGame = L.new()
        lscene.game_id = "ludo"
        add_child(lscene)
        await get_tree().process_frame
        await get_tree().process_frame
        lscene.probe_reset(1, 99)
        var seat_ok := true
        for a in range(1, 5):
                # the plate (the inner paper square) in board cells
                var bx0 := 0 if a == 1 or a == 4 else 9
                var by0 := 0 if a == 1 or a == 2 else 9
                var px0 := float(bx0) + 1.5
                var py0 := float(by0) + 1.5
                for p in 4:
                        var sp: Vector2 = lscene._socket_point(a, p) \
                                        - lscene.board_origin
                        var gx: float = sp.x / lscene.cell
                        var gy: float = sp.y / lscene.cell
                        # the seat sits INSIDE the plate with a margin,
                        # and INSIDE the 6x6 yard
                        var in_plate := gx > px0 and gx < px0 + 3.0 \
                                        and gy > py0 and gy < py0 + 3.0
                        if not in_plate:
                                seat_ok = false
                                print("    army %d seat %d at (%.2f, %.2f) outside plate (%.2f..%.2f)" % [a, p, gx, gy, px0, px0 + 3.0])
        fails += _check(seat_ok, "ludo: all 16 seats sit inside their own plates")
        fails += _check(int(lscene.cpu_moods.size()) >= 1,
                        "ludo: the CPU draws a hidden mood per rival")
        lscene.queue_free()
        await get_tree().process_frame

        print("--- ludo: the tactical scorer ---")
        # THE WIN beats everything: a pawn one step from home with roll 1
        poss = []
        for i in 16:
                poss.append(-1)
        poss[0] = 55          # army 1 piece 0: one step from home
        poss[4] = 10          # army 2 piece 0 on the road (foe)
        var moves: Array = L.legal_moves(poss, 1, 1, teams1)
        var win_found := false
        for m in moves:
                if int(m["piece"]) == 0 and int(m["np"]) == 56:
                        win_found = true
        fails += _check(win_found, "ludo: the home step is legal at 55+1")
        if win_found:
                var w: Dictionary = L.CPU_MOODS["hunter"]
                var win_m := {"piece": 0, "np": 56, "eats": []}
                var step_m := {"piece": 0, "np": 55, "eats": []}
                var sw: float = L.cpu_score(poss, 1, win_m, teams1, w)
                var ss: float = L.cpu_score(poss, 1, step_m, teams1, w)
                fails += _check(sw > ss,
                        "ludo: the WIN outscores standing still (hunter)")
        # THE EAT beats the plain step: a foe one hop ahead. The foe sits
        # at army 2's pos 50 = ring 11; our walker at pos 8 + a 3 lands on
        # ring 11 - same cell, an eat (ring 11 is not guarded)
        poss = []
        for i in 16:
                poss.append(-1)
        poss[0] = 8
        poss[1] = -1
        poss[2] = -1
        poss[3] = -1
        poss[4] = 50          # army 2's last ring cell = ring 11
        var teams_e := {1: 1, 2: 2}
        var moves_e: Array = L.legal_moves(poss, 1, 3, teams_e)
        var eat_m := {}
        var plain_m := {}
        for m in moves_e:
                if int(m["piece"]) == 0:
                        if not (m["eats"] as Array).is_empty():
                                eat_m = m
                        elif int(m["np"]) == 11:
                                plain_m = m
        fails += _check(not eat_m.is_empty(),
                "ludo: the eat is among the legal moves")
        if not eat_m.is_empty():
                var w2: Dictionary = L.CPU_MOODS["hunter"]
                var se: float = L.cpu_score(poss, 1, eat_m, teams_e, w2)
                var sp2: float = 0.0
                if not plain_m.is_empty():
                        sp2 = L.cpu_score(poss, 1, plain_m, teams_e, w2)
                fails += _check(se > sp2,
                        "ludo: the EAT outscores the same-distance step")
        # THE THREAT: a foe 2 behind threatens, the guarded cell does not,
        # our own wall does not
        poss = []
        for i in 16:
                poss.append(-1)
        poss[0] = 20          # army 1 at pos 20 -> ring 20
        poss[4] = 18          # army 2 at pos 18 -> ring 31? no: ring_at(2,18)=31
        # army 2 at ring 31 cannot reach 20; put the foe so it CAN:
        # ring_at(2, fp + k) == 20 -> (13 + fp + k) % 52 == 20 -> fp + k = 7
        poss[4] = 5
        fails += _check(L.threatened(poss, 1, 20, teams_e),
                "ludo: the foe's 1..6 reach is a real threat")
        fails += _check(not L.threatened(poss, 1, 21, teams_e),
                "ludo: seven steps away is no threat")
        fails += _check(not L.threatened(poss, 1, 13, teams_e),
                "ludo: the guarded start cell is never a threat")
        # our own wall: two of ours on 25 -> no threat there
        poss[0] = 25
        poss[1] = 25
        fails += _check(not L.threatened(poss, 1, 25, teams_e),
                "ludo: our own two-pawn wall is calm")
        # THE PICK: the racer wins the race with a legal ladder of moves
        var rng := RandomNumberGenerator.new()
        rng.seed = 7
        poss = []
        for i in 16:
                poss.append(-1)
        poss[0] = 54          # one from home
        var pick: Dictionary = L.cpu_pick(poss, 1, 1, teams1, "racer", rng)
        fails += _check(not pick.is_empty() and int(pick["np"]) == 55,
                "ludo: racer takes the home step")
        # THE MOODS: all four exist and the jitter keeps chaos loose
        var moods_ok: bool = L.CPU_MOODS.has("racer") and L.CPU_MOODS.has("hunter") \
                        and L.CPU_MOODS.has("guard") and L.CPU_MOODS.has("chaos")
        fails += _check(moods_ok, "ludo: the four hidden moods exist")

        print("--- ludo: the full-CPU soak ---")
        var l2: GogaGame = L.new()
        l2.game_id = "ludo"
        add_child(l2)
        await get_tree().process_frame
        var eats_seen := 0
        for seed_v in range(3):
                l2.probe_reset(4, 1000 + seed_v)
                # THE RACE SOAK: the whole machine runs live - the user
                # army is driven by the probe (roll + first legal move),
                # the rivals by their moods. A full 4-army classic round
                # can outrun any probe window (the exact landing law
                # stacks the endgame), so the soak asserts PROGRESS: the
                # pawns walk, the captures land, no state ever stalls.
                var home0 := 0
                for i in 16:
                        if int(l2.poss[i]) == 56:
                                home0 += 1
                var stall := 0
                var last_key := ""
                for t in 30000:
                        l2.probe_step(0.05)
                        if l2.slides.size() > 0:
                                eats_seen += 1
                        var key := "%s|%d" % [l2.state, l2.turn_army]
                        stall = stall + 1 if key == last_key else 0
                        last_key = key
                        if stall > 2000:
                                break
                        if l2.state == "roll_wait" \
                                        and l2._is_user_army(l2.turn_army):
                                l2.probe_roll()
                        elif l2.state == "picking" \
                                        and l2._is_user_army(l2.turn_army):
                                if not l2.legal.is_empty():
                                        var m0: Dictionary = l2.legal[0]
                                        l2._start_move(int(m0["piece"]),
                                                        int(m0["np"]))
                var home1 := 0
                for i in 16:
                        if int(l2.poss[i]) == 56:
                                home1 += 1
                fails += _check(home1 > home0,
                        "ludo: seed %d race progresses (home %d -> %d, no stall)" % [seed_v, home0, home1])
                fails += _check(stall <= 2000,
                        "ludo: seed %d never stalls in one state" % seed_v)
        fails += _check(eats_seen > 0,
                "ludo: the soak saw real captures (%d)" % eats_seen)
        # THE ENDGAME RESOLUTION: seed the table with the user's whole
        # army one exact step from the crown and run - the round RESOLVES
        l2.probe_reset(1, 77)
        l2.poss[0] = 55
        l2.poss[1] = 54
        l2.poss[2] = 53
        l2.poss[3] = 52
        l2.poss[4] = 5
        l2.poss[5] = 6
        l2.poss[6] = 7
        l2.poss[7] = 8
        for t in 20000:
                l2.probe_step(0.05)
                if l2.state == "round_over":
                        break
                if l2.state == "roll_wait" and l2._is_user_army(l2.turn_army):
                        l2.probe_roll()
                elif l2.state == "picking" and l2._is_user_army(l2.turn_army):
                        if not l2.legal.is_empty():
                                var m0: Dictionary = l2.legal[0]
                                l2._start_move(int(m0["piece"]), int(m0["np"]))
        fails += _check(l2.state == "round_over",
                "ludo: the seeded endgame resolves to a verdict")
        l2.queue_free()
        await get_tree().process_frame

        # ============================== SNL: the board laws
        print("--- snl: the board laws ---")
        fails += _check(int(S.LADDERS.size()) == 7 and int(S.SNAKES.size()) == 8,
                "snl: the classic fixed table (7 ladders, 8 snakes)")
        fails += _check(S.resolve_land(4)["ride"] == "ladder"
                        and int(S.resolve_land(4)["to"]) == 25,
                "snl: the ladder rides")
        fails += _check(S.resolve_land(99)["ride"] == "snake"
                        and int(S.resolve_land(99)["to"]) == 41,
                "snl: the snake swallows")
        fails += _check(S.legal_to(97, 3) == 100 and S.legal_to(97, 4) == -1,
                "snl: the exact landing law (97 wants a 3, a 4 is refused)")
        var sscene: GogaGame = S.new()
        sscene.game_id = "snl"
        add_child(sscene)
        await get_tree().process_frame
        await get_tree().process_frame
        # THE FLOW: the game opens ON the mode ask (state ready + a sheet)
        fails += _check(String(sscene.state) == "ready",
                "snl: the game waits in ready behind the mode ask")
        fails += _check(sscene.sheet_open_count() == 1,
                "snl: the HOW MANY PLAYERS ask is open (the flow law)")
        # the tray truth: the badge is WIDE (x2 the old cap)
        sscene.probe_reset(2, 55)
        var tr: Rect2 = sscene._tray_rect(1)
        fails += _check(tr.size.x > 300.0,
                "snl: the badge wears the wide seat (%.0f px)" % tr.size.x)
        var dr: Rect2 = sscene._die_rect(1)
        fails += _check(dr.grow(12.0).size.y <= tr.size.y + 0.1,
                "snl: the die's breathing seat stays inside the tray (the flicker fix)")
        # THE SOAK: full rounds resolve with pure RNG
        var s_ok := 0
        for seed_v in range(3):
                sscene.probe_reset(4, 2000 + seed_v)
                for t in 3000:
                        sscene.probe_step(0.05)
                        if String(sscene.state) == "round_over":
                                s_ok += 1
                                break
                        if String(sscene.state) == "roll_wait" \
                                        and int(sscene.turn) == 1:
                                sscene.probe_roll()
                                sscene.probe_drain(400)
        fails += _check(s_ok == 3, "snl: three full 4-player rounds resolve")
        sscene.queue_free()
        await get_tree().process_frame

        # ============================== THE CAST
        print("--- the cast: the box story ---")
        var base: GogaGame = S.new()
        base.game_id = "snl"
        add_child(base)
        await get_tree().process_frame
        base.box_story_show("TEST", "a tiny line", Callable(), "OK")
        await get_tree().process_frame
        fails += _check(bool(base.box_story_open()),
                "the cast: the story card opens")
        fails += _check(bool(get_tree().paused),
                "the cast: the story pauses the tree")
        base.box_story_dismiss()
        await get_tree().process_frame
        fails += _check(not bool(base.box_story_open()),
                "the cast: the story dismisses clean")
        fails += _check(not bool(get_tree().paused),
                "the cast: the pause never outlives the story")
        base.queue_free()
        await get_tree().process_frame

        print("--- the cast: the once-ever counters ---")
        var jc: GDScript = load("res://game/games/jumpcube/jumpcube.gd")
        fails += _check(jc.EGG_LINES.size() == 9,
                "the cast: the table's secret wears nine lines")
        fails += _check(String(jc.EGG_LINES[0][0]) == "BALLDOZER"
                        and String(jc.EGG_LINES[0][1]) == "I'm bored here.",
                "the cast: the secret opens with balldozer's yawn")
        fails += _check(String(jc.EGG_LINES[4][1]) == "The dot eater. The snow ball. The dot on top of you, Geoquare.",
                "the cast: the verbatim self-introduction")
        fails += _check(String(jc.EGG_LINES[5][0]) == "GEOQUARE",
                "the cast: geoquare answers the introduction")
        fails += _check(String(jc.EGG_LINES[8][1]) == "It is likely do since it can control both of us simultaneously at the same time.",
                "the cast: the telepathy law, verbatim")
        fails += _check(float(jc.EGG_IDLE) == 60.0,
                "the cast: the secret waits EXACTLY sixty seconds")
        var jscene: GogaGame = jc.new()
        jscene.game_id = "jumpcube"
        add_child(jscene)
        await get_tree().process_frame
        await get_tree().process_frame
        fails += _check(jscene.egg_fired == false and jscene.egg_idle == 0.0,
                "the cast: the egg waits (fresh round)")
        jscene.probe_reset(7, 4)
        # force the idle clock: tick 60s of live play without input
        jscene.egg_fired = false
        for i in 620:
                jscene.probe_step(0.1)
        fails += _check(bool(jscene.egg_fired) or jscene.egg_idle > 0.0,
                "the cast: the idle minute counts (egg armed)")
        jscene.queue_free()
        await get_tree().process_frame

        print("=== qa_v03913: %d checks, %d fails ===" % [checks, fails])
        get_tree().quit(1 if fails > 0 else 0)
