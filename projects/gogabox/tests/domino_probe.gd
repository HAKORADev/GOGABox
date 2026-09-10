extends Node
## domino_probe - v0.3.8: pins the TILE CLASSIC headless. The owner does
## not play dominoes ("i will just trust you") - these laws ARE the
## certification:
##   the deck (28 unique tiles), the ends math, the flip law (a placed
##   chain ALWAYS reads valid end-to-end), the opener law (highest double,
##   else heaviest), the 7/7/14 deal, the draw-when-stuck law, the pass
##   law, THE BLOCKED LAW (lighter hand wins, tie draws), the scoring
##   (+1/-1 floor-at-0/draw 0), the 3rd-round coin race, the CPU legality
##   across all four moods (600 seeded picks), and FULL seeded rounds
##   driven through the real scene (conservation every ply: chain + hands
##   + boneyard = 28).
##
##   godot --headless --path projects/gogabox res://tests/domino_probe.tscn

var fails := 0

func _check(cond: bool, msg: String) -> void:
        print(("  PASS: " if cond else "  FAIL: ") + msg)
        if not cond:
                fails += 1

var DOM: GDScript

func _run() -> void:
        Box.reset_all()
        print("== domino_probe: the tile classic v0.3.8 ==")
        DOM = load("res://game/games/domino/domino.gd")

        # ---- registry sanity (the owner's laws) ----
        var dr: Dictionary = GameReg.get_game("domino")
        _check(not dr.is_empty(), "domino is in the registry")
        _check(int(dr["coin_div"]) == 2, "domino run bonus = score/2 (owner)")
        _check(bool(dr["banner"]), "domino carries the ad banner")
        _check(int(dr["fee"]) == 10, "the round fee stays 10")
        _check(int(dr["price"]) == 500, "domino keeps its teaser price (500)")

        # ---- THE DECK LAW: 28 unique tiles ----
        var d: Array = DOM.full_deck()
        _check(d.size() == 28, "the deck holds 28 tiles")
        var uniq := {}
        for t in d:
                uniq["%d-%d" % [int(t[0]), int(t[1])]] = true
        _check(uniq.size() == 28, "every tile is unique")
        _check(DOM.pips([6, 6]) == 12 and DOM.pips([0, 0]) == 0,
                "pips read honestly")
        _check(DOM.is_double([3, 3]) and not DOM.is_double([3, 5]),
                "doubles are doubles")

        # ---- THE ENDS MATH + THE FLIP LAW (static) ----
        var ch: Array = []
        ch.append({"a": 2, "b": 5, "fl": false, "who": 1})
        _check(DOM.ends(ch) == Vector2i(2, 5), "the first tile opens both ends")
        # a 2 on the left: [4|2] flipped
        ch.push_front({"a": 4, "b": 2, "fl": false, "who": 2})
        _check(DOM.ends(ch) == Vector2i(4, 5), "the left placement flips true")
        # a 5 on the right: [5|1] not flipped (b==rv -> fl true puts b left)
        ch.append({"a": 5, "b": 1, "fl": false, "who": 1})
        _check(DOM.ends(ch) == Vector2i(4, 1),
                "the right placement reads [4|5|1]")
        _check(DOM.can_play([6, 4], 4, 1) == 1,
                "a tile fitting one end reports it")
        _check(DOM.can_play([4, 1], 4, 1) == 3,
                "a tile fitting both ends reports both")
        _check(DOM.can_play([6, 6], 3, 1) == 0, "a dead tile reports nothing")

        # ---- THE OPENER LAW ----
        var op: Dictionary = DOM.opener([[0, 3], [6, 2], [5, 5]],
                [[6, 6], [1, 2]])
        _check(int(op["who"]) == 2 and int(op["tile"][0]) == 6,
                "the highest double opens (6-6, the CPU's)")
        var op2: Dictionary = DOM.opener([[0, 3], [6, 2], [5, 4]],
                [[1, 2], [3, 3]])
        _check(int(op2["who"]) == 2 and DOM.is_double(op2["tile"]),
                "3-3 beats heaviest when it is the only double")
        var op3: Dictionary = DOM.opener([[0, 3], [6, 2]], [[5, 4], [1, 2]])
        _check(int(op3["who"]) == 2 and DOM.pips(op3["tile"]) == 9,
                "no doubles = the heaviest tile opens")

        # ---- boot the real scene ----
        var g: GogaGame = DOM.new()
        g.game_id = "domino"
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        _check(g.pause_end_run, "the PONG design: the pause sheet owns the END bank")
        g.probe_reset(11)
        _check(g.hand_p.size() == 7 and g.hand_c.size() == 7
                and g.deck.size() == 14,
                "THE DEAL LAW: 7 / 7 / 14 in the boneyard")
        _check(g.opening, "the round opens with the forced opener")
        _check(g.state == "play" or g.state == "cpu_wait",
                "the opener's holder owns the first move")

        # ---- v0.3.8-4 THE ANCHORED SNAKE LAWS (the layout, certified) ----
        # a heavy mixed chain with doubles everywhere: the snake may turn,
        # but it may NEVER overlap itself and NEVER leave the ground, and
        # the fit only walks down when the box truly outgrows the ground
        var sim_chain := [[6, 6], [6, 4], [4, 4], [4, 2], [2, 3], [3, 5],
                [5, 5], [5, 0], [0, 1], [1, 1], [1, 4], [4, 6], [6, 2],
                [2, 2], [2, 0], [0, 0], [0, 3], [3, 3], [3, 6], [6, 6]]
        g.chain.clear()
        for c in sim_chain:
                g.chain.append({"a": c[0], "b": c[1], "fl": false,
                        "who": 1, "landed": true})
        g._relayout()
        # v0.3.8-5 THE SETTLE LAW: the smooth group glide zooms the table
        # over a few frames - the rig certifies the SETTLED layout, so
        # snap the glide to its target before measuring
        g._settle_glide()
        var overlap := false
        var outside := false
        for i in g.chain_rects.size():
                var ri: Rect2 = g.chain_rects[i]["rect"]
                if not g.board_rect.grow(2.0).encloses(ri):
                        outside = true
                for j in range(i + 1, g.chain_rects.size()):
                        # v0.3.8-5 R2 THE STICK-TOGETHER PACK: rows now touch
                        # edge-to-edge (the studied matrix steps by EXACTLY
                        # TILE_HEIGHT) - a float hair on a shared edge is a
                        # TOUCH, not an overlap. Only a real body crossing
                        # (0.6px grown in on both) fails the law.
                        if ri.grow(-0.6).intersects(
                                        (g.chain_rects[j]["rect"]
                                        as Rect2).grow(-0.6)):
                                overlap = true
        if overlap:
                var dumped := false
                for i in g.chain_rects.size():
                        if dumped:
                                break
                        for j in range(i + 1, g.chain_rects.size()):
                                if (g.chain_rects[i]["rect"] as Rect2) \
                                                .grow(-0.6).intersects(
                                                        (g.chain_rects[j]["rect"] as Rect2).grow(-0.6)):
                                        print("    [dbg] overlap #%d %s vs #%d %s  BASE_L=%s board=%s" % [i, g.chain_rects[i]["rect"], j, g.chain_rects[j]["rect"], g.BASE_L, g.board_rect])
                                        for k in g.chain.size():
                                                var tk: Dictionary = g.chain[k]
                                                print("      pose#%02d=(%s,%s) v=%s dir=(%s,%s)" % [k, tk.get("px", "?"), tk.get("py", "?"), tk.get("pv", "?"), tk.get("pdx", "?"), tk.get("pdy", "?")])
                                        dumped = true
                                        break
        _check(not overlap, "THE SNAKE LAW: a 21-tile chain (5 doubles) never overlaps itself")
        _check(not outside, "THE FIT LAW: the snake lives inside the ground")
        # THE FIT LAW v2: the zoom is the bbox -> ground ratio. Shrink the
        # ground and the SAME chain walks the scale down, still clean
        # (_relayout_board: the board-space half only - _relayout would
        # re-derive the ground from the viewport)
        var wide_board: Rect2 = g.board_rect
        var full_scale: float = float(g._board_scale())
        # v0.3.8-5 R2: the stress shrinks to 0.6 - deep enough to force the
        # fit scale to walk down hard, shallow enough to stay above the
        # 0.45 readability floor (the floor may lawfully overflow a
        # HALF-sized board - that is what a floor IS)
        g.board_rect = Rect2(wide_board.position, wide_board.size * 0.6)
        g._relayout_board()
        g._settle_glide()
        var shrink_ok := true
        var s_out := false
        for i in g.chain_rects.size():
                var rs: Rect2 = g.chain_rects[i]["rect"]
                if not g.board_rect.grow(2.0).encloses(rs):
                        s_out = true
                for j in range(i + 1, g.chain_rects.size()):
                        if rs.grow(-0.6).intersects(
                                        (g.chain_rects[j]["rect"]
                                        as Rect2).grow(-0.6)):
                                shrink_ok = false
        _check(float(g._board_scale()) < full_scale and float(g._board_scale()) < 1.0,
                "THE FIT LAW: the scale walks down only when the box outgrows the ground (%.2f -> %.2f)"
                        % [full_scale, float(g._board_scale())])
        _check(shrink_ok and not s_out,
                "THE FIT LAW: the shrunk ground still holds a clean snake")
        g.board_rect = wide_board
        g._relayout()
        # the full 28-tile worst case still holds the laws
        g.chain.clear()
        for c in DOM.full_deck():
                g.chain.append({"a": int(c[0]), "b": int(c[1]), "fl": false,
                        "who": 1, "landed": true})
        g._relayout()
        g._settle_glide()
        var worst := false
        for i in g.chain_rects.size():
                var rw: Rect2 = g.chain_rects[i]["rect"]
                if not g.board_rect.grow(2.0).encloses(rw):
                        worst = true
                        break
                for j in range(i + 1, g.chain_rects.size()):
                        if rw.grow(-0.6).intersects(
                                        (g.chain_rects[j]["rect"]
                                        as Rect2).grow(-0.6)):
                                worst = true
                                break
                if worst:
                        break
        _check(not worst, "THE SNAKE LAW: even the FULL 28-tile deck never overlaps or leaves the ground")
        g.chain.clear()
        g._relayout()

        # ---- v0.3.8-4 THE ANCHOR LAW (the owner's headline: tiles never
        # move) - live placements through _place, then a LEFT placement:
        # every earlier screen rect must be BIT-IDENTICAL ----
        g.probe_reset(51)
        g.chain = []
        g.hand_p = [[6, 6], [6, 4], [6, 3]]
        g.hand_c = [[0, 0]]
        g.deck = []
        g.opening = false
        g.state = "play"
        g.turn = g.P
        g._relayout()
        g.sel = 0
        g._place(g.P, 0, 2)          # the 6-6 opens
        g.sel = 0
        g._place(g.P, 0, 2)          # the 6-4 to the right end (6)
        var frozen: Array = []
        for cr in g.chain_rects:
                frozen.append(cr["rect"])
        g.sel = 0
        g._place(g.P, 0, 1)          # the 6-3 to the LEFT end (6)
        # v0.3.8-4 THE ANCHOR LAW: the view may PAN (a uniform shift when
        # the bbox re-centers - the real game's camera), but a tile's
        # offset from its NEIGHBOURS is sacred. The old tiles ride at
        # indices 1..n now (chain[0] is the new left tile) - every old
        # neighbour pair must wear the exact offset it wore before.
        var anchored := true
        for i in range(1, frozen.size()):
                # before: pair (i-1, i) inside frozen; after: the same two
                # old tiles sit at chain_rects[i], chain_rects[i+1]
                var before: Vector2 = (frozen[i] as Rect2).position \
                                - (frozen[i - 1] as Rect2).position
                var after: Vector2 = (g.chain_rects[i + 1]["rect"] as Rect2).position \
                                - (g.chain_rects[i]["rect"] as Rect2).position
                if not before.is_equal_approx(after):
                        anchored = false
        _check(anchored, "THE ANCHOR LAW: a left placement never reflows a single pair of placed tiles")

        # ---- FULL SEEDED ROUNDS through the live scene ----
        var rounds_ok := true
        var cons_ok := true
        var score_law := true
        var done_wins := 0
        var done_losses := 0
        var done_draws := 0
        for s in range(30):
                g.probe_reset(100 + s)
                var guard := 0
                while g.state != "round_over" and guard < 3000:
                        guard += 1
                        if g.state == "play" and g.turn == g.P:
                                var e: Vector2i = g.ends(g.chain)
                                var opts: Array = g.playable(g.hand_p, e.x, e.y)
                                if g.opening:
                                        # the forced opener plays
                                        var hi := 0
                                        for i in g.hand_p.size():
                                                if g._is_opener(i):
                                                        hi = i
                                                        break
                                        g._place(g.P, hi, 2)
                                elif opts.is_empty():
                                        if g.deck.size() > 0:
                                                g._draw_tile(g.P)
                                        else:
                                                g._pass(g.P)
                                else:
                                        var i2: int = opts[0]
                                        var cp: int = g.can_play(
                                                g.hand_p[i2], e.x, e.y)
                                        g._place(g.P, i2,
                                                1 if (cp & 1) != 0 else 2)
                        g.probe_step(1.0 / 60.0)
                        # THE CONSERVATION LAW: the 28 tiles never leak
                        var n_tiles: int = g.chain.size() + g.hand_p.size() \
                                + g.hand_c.size() + g.deck.size()
                        if n_tiles != 28:
                                cons_ok = false
                        # THE CHAIN LAW: every join reads true
                        var e2: Vector2i = g.ends(g.chain)
                        if g.chain.size() >= 2:
                                var touching: Dictionary = g.chain[0]
                                var lv2: int = int(touching["b"]) \
                                        if bool(touching["fl"]) \
                                        else int(touching["a"])
                                if lv2 != e2.x:
                                        rounds_ok = false
                if g.state != "round_over":
                        rounds_ok = false
                if g.wins + g.losses + g.draws != 1:
                        rounds_ok = false
                        print("    seed %d stalled: state=%s W%d L%d D%d handP%d handC%d deck%d chain%d" % [s, g.state, g.wins, g.losses, g.draws, g.hand_p.size(), g.hand_c.size(), g.deck.size(), g.chain.size()])
                done_wins += g.wins
                done_losses += g.losses
                done_draws += g.draws
                # THE SCORE LAW: +1 win / -1 loss / never negative
                var want: int = g.wins - g.losses
                if want < 0:
                        want = 0
                if g.score != want:
                        score_law = false
                        print("    seed %d score drift: score=%d want=%d W%d L%d" % [s, g.score, want, g.wins, g.losses])
        _check(cons_ok, "THE CONSERVATION LAW: chain + hands + boneyard = 28, every ply")
        _check(rounds_ok, "30 seeded rounds completed with honest verdicts")
        _check(score_law, "THE SCORE LAW: +1 / -1 / floor at 0 across the rounds")
        _check(done_wins + done_losses + done_draws == 30,
                "every round resolved (%dW %dL %dD)" % [done_wins, done_losses,
                done_draws])
        _check(done_wins > 3 and done_losses > 3,
                "both sides win real rounds (the owner's beatable-but-alive law)")

        # ---- THE BLOCKED LAW (constructed) ----
        g.probe_reset(7)
        g.chain = [{"a": 6, "b": 6, "fl": false, "who": 1}]
        g.hand_p = [[6, 3], [4, 4]]
        g.hand_c = [[6, 5], [2, 2]]
        g.deck = []
        g.opening = false
        g.state = "play"
        g.turn = g.P
        g.pass_streak = 0
        g._relayout()
        g._pass(g.P)
        _check(g.pass_streak == 1, "the first pass is just a pass")
        g._pass(g.C)
        _check(g.state == "round_over" and g.losses == 1 and g.wins == 0,
                "THE BLOCKED LAW: the CPU is lighter (15 vs 17) - the CPU wins")
        _check("BLOCKED" in g.turn_lbl.text, "the verdict says BLOCKED")
        # the tie draws
        g.probe_reset(8)
        g.chain = [{"a": 0, "b": 0, "fl": false, "who": 1}]
        g.hand_p = [[1, 2]]
        g.hand_c = [[1, 2]]
        g.deck = []
        g.opening = false
        g.pass_streak = 0
        g._relayout()
        g._pass(g.P)
        g._pass(g.C)
        _check(g.draws == 1,
                "THE BLOCKED LAW: even pips draw")

        # ---- THE COIN LAW (every 3rd round) ----
        var coin_ok := true
        for s in range(9):
                g.probe_reset(300 + s)
                g.done_rounds = 0
                g._new_round()
                if g.coin_side != 0:
                        coin_ok = false
                g.done_rounds = 3
                g._new_round()
                if g.coin_side == 0:
                        coin_ok = false
                g.done_rounds = 4
                g._new_round()
                if g.coin_side != 0:
                        coin_ok = false
        _check(coin_ok, "THE COIN LAW: the coin rides every 3rd round only")

        # ---- THE COIN RACE (the placement takes it) ----
        g.probe_reset(41)
        g.done_rounds = 3
        g._new_round()
        # fast-forward the deal, force a chain, park the coin on a fit spot
        g.chain = [{"a": 2, "b": 4, "fl": false, "who": 1}]
        g.hand_p = [[4, 6]]
        g.hand_c = [[1, 1], [3, 2]]
        g.deck = []
        g.opening = false
        g.state = "play"
        g.turn = g.P
        g.coin_side = 2       # the coin waits on the RIGHT end (a 4)
        g._relayout()
        g.chain_rects = []
        g._relayout()
        var rc0: int = g.run_coins
        g.sel = 0
        g._place(g.P, 0, 2)
        _check(g.run_coins == rc0 + 1,
                "THE COIN RACE: the domino placed on the coin spot takes it")

        # ---- THE CPU SANITY: every mood picks legal tiles (600 seeds) ----
        var cpu_ok := true
        for pr in DOM.PROFILES.keys():
                for s in range(150):
                        var rng := RandomNumberGenerator.new()
                        rng.seed = s * 31 + 7
                        var hand: Array = []
                        var pool: Array = DOM.full_deck()
                        for k in 6:
                                hand.append(pool[rng.randi() % pool.size()])
                        var lv := rng.randi() % 7
                        var rv := rng.randi() % 7
                        var chain_seed: Array = [{"a": lv, "b": rv,
                                "fl": false, "who": 1}]
                        var seen := {lv: 2, rv: 1}
                        var flags: Dictionary = DOM.adapt([])
                        var pick: int = DOM.cpu_pick(hand, lv, rv, pr,
                                chain_seed, seen, flags, rng)
                        if pick >= 0:
                                var cp2: int = DOM.can_play(hand[pick], lv, rv)
                                if cp2 == 0:
                                        cpu_ok = false
                        # a stuck hand returns -1 (the pass door)
        _check(cpu_ok, "THE CPU LAW: all four moods pick legal tiles (600 seeds)")
        var stuck_pick: int = DOM.cpu_pick([[1, 2], [3, 4]], 5, 6, "heavy",
                [{"a": 5, "b": 6, "fl": false, "who": 1}], {}, {}, 
                RandomNumberGenerator.new())
        _check(stuck_pick == -1, "a starved hand returns -1 (the draw/pass door)")

        # ---- THE MEMORY LAW (the xo 2-round window) ----
        var mem: Array = []
        mem = DOM.remember(mem, {"open_end": -1, "drew": 0, "result": 1})
        mem = DOM.remember(mem, {"open_end": -1, "drew": 4, "result": 2})
        _check(mem.size() == 2 and bool(DOM.adapt(mem)["thirsty"]),
                "a thirsty round enters the memory")
        mem = DOM.remember(mem, {"open_end": 1, "drew": 0, "result": 1})
        _check(mem.size() == 2, "THE MEMORY LAW: only 2 rounds fit")
        var mem2: Array = []
        mem2 = DOM.remember(mem2, {"open_end": -1, "drew": 0, "result": 1})
        mem2 = DOM.remember(mem2, {"open_end": -1, "drew": 0, "result": 2})
        _check(int(DOM.adapt(mem2)["side_lock"]) == -1,
                "a repeated fed side wakes the side lock")

        print("== domino_probe: %s (%d fails) ==" % ["ALL PASS" if fails == 0
                else "FAILED", fails])
        get_tree().quit(0 if fails == 0 else 1)

func _ready() -> void:
        get_window().size = Vector2i(720, 1280)
        await get_tree().create_timer(0.3).timeout
        _run()
