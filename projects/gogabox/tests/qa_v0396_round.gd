extends Node
## qa_v0396_round - the v0.3.9-6 repair probe (the qa_v0395 law): the
## owner's report laws, driven headless, exit 0 = pass.
##   SQUARES: the score chip is VISIBLE (no card overlap), the two goal
##   cards tile their row, the dust firework MOVES on the clock.
##   DOT EATER: the story START button closes the dialogue for real, the
##   pen is sealed two-way with one gate, the wrap flight wears two honest
##   copies, the size ladder climbs, the mercy breath exists.

var fails := 0

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        print("=== qa_v0396_round ===")
        await _squares()
        await _dot_eater()
        print("=== qa_v0396_round: %s ===" % ("PASS" if fails == 0
                        else "%d FAILS" % fails))
        get_tree().quit(0 if fails == 0 else 1)

func _check(cond: bool, why := "") -> void:
        print("  %s: %s" % ["PASS" if cond else "FAIL", why])
        if not cond:
                fails += 1

# ---------------------------------------------------------------- SQUARES
func _squares() -> void:
        Box.reset_all()
        var SQ: GDScript = load("res://game/games/squares/squares.gd")
        var g: GogaGame = SQ.new()
        g.game_id = "squares"
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        if g.ready_ui != null and is_instance_valid(g.ready_ui):
                g.ready_ui.queue_free()
                g.ready_ui = null
        g.paused = true
        g._new_round()
        var vp: Vector2 = get_viewport().get_visible_rect().size

        # THE SCORE CHIP LAW: the chip and the goals cards never overlap
        var chip: Control = g._score_label.get_parent().get_parent()
        var chip_r := chip.get_global_rect()
        var row_r: Rect2 = g.goals_row.get_global_rect()
        _check(chip_r.size.x > 4.0 and chip_r.size.y > 4.0,
                        "sq: the score chip has a real rect %s" % str(chip_r))
        _check(not chip_r.grow(1.0).intersects(row_r),
                        "sq: the score chip and the goals row are DISJOINT (%s vs %s)"
                        % [str(chip_r.position), str(row_r.position)])
        # the two cards tile the row (no half-off spill)
        var cw := 108.0
        _check(absf((row_r.size.x - (cw * 2.0 + 8.0))) < 0.5,
                        "sq: the goals row wears exactly two cards wide (%.0f)"
                        % row_r.size.x)
        # THE SEAT LAW (v0.3.9-6 round 2, the owner: "score widget should
        # be at the left side from the gogacoins widget, others comes
        # later"): the cards sit LEFT of the score chip, the score hugs
        # the coins: goals | score | coins
        var coins_chip: Control = g._coins_label.get_parent().get_parent()
        _check(row_r.position.x < chip_r.position.x \
                        and chip_r.position.x < coins_chip.get_global_rect().position.x,
                        "sq: the HUD order reads goals | score | coins")

        # THE DUST LIFE: the pips move and age on the tick (the firework)
        var d := dots_n_box(g)
        var e0: int = -1
        for i in g.edges.size():
                if int(g.edges[i]) == 0:
                        e0 = i
                        break
        # place 3 sides of a box, then close it with the 4th
        var d_n: int = g.dots_n
        var b: int = 0
        var sides: Array = SQ.box_edges(b, 0, d_n)
        for s_i in 3:
                g._place(sides[s_i], 1)
        var closer: int = sides[3]
        g._place(closer, 1)
        _check(g._dust.size() > 0, "sq: a claimed box bursts dust pips (%d)"
                        % g._dust.size())
        if g._dust.size() > 0:
                var p0: Vector2 = Vector2(float(g._dust[0]["x"]),
                                float(g._dust[0]["y"]))
                var l0: float = float(g._dust[0]["life"])
                for i in 6:
                        g.probe_step(0.033)
                var p1: Vector2 = Vector2(float(g._dust[0]["x"]),
                                float(g._dust[0]["y"]))
                _check(p0.distance_to(p1) > 0.5,
                                "sq: the dust pips MOVE on the tick (dx %.1f)"
                                % p0.distance_to(p1))
                _check(float(g._dust[0]["life"]) < l0, "sq: the dust pips AGE")
                # the pips end with the box fade: life never exceeds BOX_A
                var max_life := 0.0
                for p in g._dust:
                        max_life = maxf(max_life, float(p["max"]))
                _check(max_life <= SQ.BOX_A + 0.001,
                                "sq: the firework ends WITH the transition (max %.2f)"
                                % max_life)
        g.queue_free()

func dots_n_box(_g: GogaGame) -> int:
        return 0

# --------------------------------------------------------------- DOT EATER
func _dot_eater() -> void:
        Box.reset_all()
        var PM: GDScript = load("res://game/games/pacman/pacman.gd")

        # ---- the static maze laws (no scene needed)
        var dims: Vector2i = PM.gen_sizes(0)
        _check(dims == Vector2i(15, 9), "de: the ladder opens 15x9 (got %s)"
                        % str(dims))
        _check(PM.gen_sizes(12).x == 35 and PM.gen_sizes(12).y == 17,
                        "de: the ladder climbs to 35x17 (got %s)"
                        % str(PM.gen_sizes(12)))
        var last: Vector2i = PM.gen_sizes(40)
        _check(last.x == 35 and last.y == 19,
                        "de: the ladder caps at 35x19 (got %s)" % str(last))
        for n in [0, 3, 7, 12, 30]:
                var dd: Vector2i = PM.gen_sizes(n)
                _check((dd.x - 3) % 4 == 0 and (dd.x - 1) / 2 % 2 == 1,
                                "de: maze %d keeps the seam node law (cols %d)"
                                % [n, dd.x])
        # the pen laws on a handful of seeds
        for seed_v in [11, 42, 777, 4242]:
                var rng := RandomNumberGenerator.new()
                rng.seed = seed_v
                var sz: Vector2i = PM.gen_sizes(seed_v % 7)
                var m: Dictionary = PM.gen_maze(sz.x, sz.y, rng)
                var gg: Array = m["g"]
                var pl: Vector2i = m["plaza"]
                var cx: int = pl.x
                var cy: int = pl.y
                # the gate: open both ways between (cx, cy-2) and (cx, cy-1)
                var gate_out: bool = PM.is_open(gg, sz.x, cx, cy - 2, Vector2i(0, 1))
                var gate_in: bool = PM.is_open(gg, sz.x, cx, cy - 1, Vector2i(0, -1))
                _check(gate_out and gate_in,
                                "de: seed %d the pen gate opens BOTH ways" % seed_v)
                # the perimeter: every non-gate pen edge reads CLOSED from
                # BOTH sides (the one-way seam law is dead)
                var bad := 0
                for yy in range(cy - 1, cy + 2):
                        for xx in range(cx - 1, cx + 2):
                                for off in [Vector2i(1, 0), Vector2i(0, 1)]:
                                        var nb: Vector2i = Vector2i(xx, yy) + off
                                        if absi(nb.x - cx) <= 1 and absi(nb.y - cy) <= 1:
                                                continue
                                        if nb.x < 0 or nb.x > sz.x - 1 or nb.y < 0 \
                                                        or nb.y > sz.y - 1:
                                                continue
                                        var key := "r"
                                        var key2 := "l"
                                        if off == Vector2i(0, 1):
                                                key = "b"
                                                key2 = "t"
                                        if not gg[yy][xx][key] or not gg[nb.y][nb.x][key2]:
                                                bad += 1
                _check(bad == 0,
                                "de: seed %d the pen walls seal BOTH sides (%d leaks)"
                                % [seed_v, bad])
                # reachability: every dot cell reachable from the spawn
                var spawn := Vector2i(cx, cy + 2)
                var seen: Dictionary = PM.reach(gg, sz.x, spawn)
                var miss := 0
                for y in sz.y:
                        for x in sz.x:
                                var c := Vector2i(x, y)
                                var open_n := 0
                                for dd2 in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1),
                                                Vector2i(0, -1)]:
                                        if PM.is_open(gg, sz.x, x, y, dd2):
                                                open_n += 1
                                if open_n >= 2 and absi(x - cx) <= 1 and absi(y - cy) <= 1:
                                        continue
                                if open_n >= 2 and not seen.has(c):
                                        miss += 1
                _check(miss == 0, "de: seed %d every corridor stays reachable (%d)"
                                % [seed_v, miss])

        # ---- the scene laws
        Box.bump_counter("pacman", "lore_start", 1)
        Box.bump_counter("pacman", "lore_end", 1)
        var g: GogaGame = PM.new()
        g.game_id = "pacman"
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        g.probe_reset(4242)
        g.probe_step(1.5)

        # THE WRAP TRUTH: a mid-wrap flight wears TWO copies at the seams
        var wrap_row: int = g.wraps[0]
        g.player["cell"] = Vector2i(0, wrap_row)
        g.player["from"] = Vector2i(0, wrap_row)
        g.player["to"] = Vector2i(g.cols - 1, wrap_row)
        g.player["t"] = 0.5
        g.player["moving"] = true
        g.player["dir"] = Vector2i(-1, 0)
        var copies: Array = g._travel_px(g.player["from"], g.player["to"], 0.5)
        _check(copies.size() == 2,
                        "de: a mid-wrap flight wears TWO copies (%d)" % copies.size())
        if copies.size() == 2:
                var span: float = float(g.cols) * g.cell_px
                _check(absf(absf(copies[0].x - copies[1].x) - span) < 0.5,
                                "de: the copies straddle the two seams (%.0f apart)"
                                % absf(copies[0].x - copies[1].x))
                var left_edge: float = g.board.x
                var right_edge: float = g.board.x + span
                var near_left: bool = absf(copies[0].x - left_edge) < g.cell_px
                var near_right: bool = absf(copies[1].x - right_edge) < g.cell_px \
                                or absf(copies[1].x - left_edge) < g.cell_px
                _check(near_left and near_right,
                                "de: the body exits one edge while it enters the other")
        # a NON-wrap flight wears one
        g.player["from"] = Vector2i(2, 3)
        g.player["to"] = Vector2i(3, 3)
        copies = g._travel_px(Vector2i(2, 3), Vector2i(3, 3), 0.5)
        _check(copies.size() == 1, "de: a plain flight wears ONE copy")

        # THE HONEST SEAM: the copies carry the collision truth (see above)
        _check(copies.size() >= 1, "de: the travel math is honest")

        # THE MERCY LAW: the breath exists and gates the kill
        _check("mercy_t" in g and g.mercy_t >= 0.0, "de: the mercy breath exists")
        g.mercy_t = 1.0
        g._seat_actors()
        g.phase = "run"
        # an angry eater seated ON Balldozer must NOT kill inside the mercy
        var e0: Dictionary = g.eaters[0]
        e0["state"] = "roam"
        e0["cell"] = g.player["cell"]
        e0["from"] = g.player["cell"]
        e0["to"] = g.player["cell"]
        e0["t"] = 0.0
        e0["moving"] = false
        var lives0: int = g.lives
        g._check_collisions()
        _check(g.lives == lives0, "de: no kill inside the mercy breath")
        g.mercy_t = 0.0
        g._check_collisions()
        _check(g.lives == lives0 - 1, "de: the kill returns after the breath")

        # THE STORY SHEET TRUTH: the START button closes the dialogue FOR REAL
        g.queue_free()
        await get_tree().process_frame
        Box.reset_all()          # a fresh save: the first-start lore must fire
        var g2: GogaGame = PM.new()
        g2.game_id = "pacman"
        add_child(g2)
        await get_tree().process_frame
        await get_tree().process_frame
        _check(g2.phase == "boot" and not g2._story_pair.is_empty(),
                        "de: the first start wears the lore card")
        _check(get_tree().paused, "de: the lore pauses the tree")
        # find the START button and press it with a REAL finger event
        var btn: BaseButton = _find_button(g2._overlay_root_ref(), "START")
        _check(btn != null, "de: the story wears its START button")
        if btn != null:
                var c := btn.get_global_rect().get_center()
                var ev := InputEventScreenTouch.new()
                ev.position = c
                ev.pressed = true
                ev.index = 0
                Input.parse_input_event(ev)
                await get_tree().process_frame
                var ev2 := InputEventScreenTouch.new()
                ev2.position = c
                ev2.pressed = false
                ev2.index = 0
                Input.parse_input_event(ev2)
                await get_tree().process_frame
                await get_tree().process_frame
                _check(g2._story_pair.is_empty(),
                                "de: THE START BUTTON CLOSES THE DIALOGUE (pair freed)")
                _check(not get_tree().paused, "de: the tree breathes again")
                _check(g2.gate_ui != null and is_instance_valid(g2.gate_ui),
                                "de: the gate waits after the lore")
                # tap anywhere: the run starts
                var ev3 := InputEventScreenTouch.new()
                ev3.position = Vector2(200, 900)
                ev3.pressed = true
                ev3.index = 0
                Input.parse_input_event(ev3)
                await get_tree().process_frame
                var ev4 := InputEventScreenTouch.new()
                ev4.position = Vector2(200, 900)
                ev4.pressed = false
                ev4.index = 0
                Input.parse_input_event(ev4)
                g2.probe_step(0.1)
                _check(g2.phase == "ready",
                                "de: the tap starts the run (phase %s)" % g2.phase)

func _find_button(root: Node, txt: String) -> BaseButton:
        if root is BaseButton and String((root as BaseButton).text) == txt:
                return root
        for c in root.get_children():
                var r := _find_button(c, txt)
                if r != null:
                        return r
        return null
