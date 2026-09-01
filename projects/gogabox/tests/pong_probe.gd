extends Node
## pong_probe - v0.2.3: drives rebuilt PONG headless. The laws: the ask
## listens to the window and says NOTHING but vertical/horizontal, the
## serve is born at the MIDDLE flying TOWARD the conceder's platform, the
## burn ceiling is x5 with BOOST/STRIKE riding past it, the pads are WALLS
## (a swept fast ball bounces where it touched - never tunnels or
## teleports), ONE coin at a time wearing the REAL GOGACoin asset, the AI
## reads the ball only inside a SHORT vision range, goals pay +1/-1
## (clamped at 0), the 3-points-per-coin bonus, the FIXED px size mods
## with their clamps, the controls follow the finger ALONG the axis only,
## MORE ENEMIES adds two walls that all hunt the player, the horizontal
## court gives the USER the right edge, and END shows only during the run.
## Exit 0 = pass.
##
##   godot --headless --path projects/gogabox res://tests/pong_probe.tscn

var fails := 0

func _check(cond: bool, msg: String) -> void:
        print(("  PASS: " if cond else "  FAIL: ") + msg)
        if not cond:
                fails += 1

func _touch(g: GogaGame, at: Vector2, pressed: bool, idx := 0) -> void:
        var t := InputEventScreenTouch.new()
        t.index = idx
        t.position = at
        t.pressed = pressed
        g._goga_input(t)

func _drag(g: GogaGame, at: Vector2, idx := 0) -> void:
        var d := InputEventScreenDrag.new()
        d.index = idx
        d.position = at
        g._goga_input(d)

func _run() -> void:
        Box.reset_all()
        _check(ResourceLoader.exists("res://assets/audio/music/pong_theme.wav"),
                        "the court has its music")
        var g: GogaGame = load("res://game/games/rally/pong.gd").new()
        g.game_id = "rally"
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        _check(g._phase == "orient", "boots into the position ask")
        _check(g.pause_end_run, "END is wired - the only way to bank")
        _check(not g._goga_pause_end_ok(),
                "the ask/options screens show NO END row (the run hasn't begun)")
        _check(g._auto_landscape() == (g.landscape),
                        "the court matches the CURRENT window shape")
        # the stale pref never wins the highlight (the snake law, reused)
        var cur := "horizontal" if g._auto_landscape() else "vertical"
        Box.set_progress("rally", "orient_pref",
                        "horizontal" if cur == "vertical" else "vertical")
        g._orient_choice(cur)
        _check(g._phase == "options", "tapping the CURRENT shape proceeds")

        # ---- the run: the serve waits at the MIDDLE, aimed at the conceder
        g._begin_run()
        _check(g._phase == "run", "START begins the run")
        _check(g._goga_pause_end_ok(), "pausing the RUN offers END")
        _check(g.serve_from == "user" and g.serve_t > 0.0,
                "the first serve waits for the user's side")
        _check(g.ball_pos.distance_to(g.field.get_center()) < 1.0,
                "the ball is born at the MIDDLE of the field (owner law)")
        var u_in0: Vector2 = g._edge_inward(
                        String(g.pads_by_id["user"]["edge"]))
        _check(g.ball_dir.dot(u_in0) < -0.5,
                "the serve flies TOWARD the conceder's platform")
        _check(absf(g.heat - 1.0) < 0.0001, "the ball starts cold (x1.00)")
        _check(g.pads.size() == 2, "two platforms by default")

        # ---- THE HEAT LAW: every wall hit x1.1, reset per serve, ceiling x5
        g.serve_t = 0.0
        g.ball_pos = g.field.get_center() + Vector2(10.0, 0.0)
        g.ball_dir = Vector2(-1.0, 0.0)
        for i in 200:
                g._goga_tick(1.0 / 60.0)
                if absf(g.ball_dir.x - 1.0) < 0.01:
                        break
        _check(absf(g.heat - 1.1) < 0.001,
                        "one wall hit = x1.10 (got x%.3f)" % g.heat)
        g._serve("user")
        _check(absf(g.heat - 1.0) < 0.0001, "a serve resets the heat")
        # ---- THE CEILING (owner v0.2.3): x5, and the powerups ride PAST it
        g.heat = 4.9
        g._heat_hit()
        _check(absf(g.heat - 5.0) < 0.001,
                "the burn ceiling is x5.00 (got x%.3f)" % g.heat)
        g.boost_on = false
        g.strike_on = false
        _check(absf(g._ball_speed() - 340.0 * 5.0) < 0.01,
                "at the ceiling the ball runs 340 x 5")
        g.boost_on = true
        _check(g._ball_speed() > 340.0 * 5.0,
                "BOOST rides PAST the ceiling (x1.5 on top)")
        g.boost_on = false
        g.strike_on = true
        _check(g._ball_speed() > 340.0 * 5.0 * 2.0,
                "STRIKE rides PAST the ceiling (x3 on top)")
        g.strike_on = false
        g._serve("user")
        _check(absf(g.heat - 1.0) < 0.0001, "a serve resets the heat")

        # ---- GOALS: +1 for the user, -1 on the user (clamped), the
        # conceder serves next, 3 points pay a coin ----
        var epad: Dictionary = g.pads_by_id["enemy"]
        var upad: Dictionary = g.pads_by_id["user"]
        var e_in: Vector2 = g._edge_inward(String(epad["edge"]))
        var u_in: Vector2 = g._edge_inward(String(upad["edge"]))
        g.serve_t = 0.0
        g.ball_pos = g._pad_serve_pos(epad) - e_in * 220.0
        g.ball_dir = -e_in
        g._goga_tick(1.0 / 60.0)
        _check(g.goals_user == 1 and g.score == 1,
                "a goal past the enemy edge = +1")
        _check(g.serve_from == String(epad["edge"]),
                "the CONCEDER serves next (%s)" % String(epad["edge"]))
        g.ball_pos = g._pad_serve_pos(upad) - u_in * 220.0
        g.ball_dir = -u_in
        g._goga_tick(1.0 / 60.0)
        _check(g.goals_enemy == 1 and g.score == 0,
                "a goal on the user = -1 (clamped at 0)")
        _check(g.serve_from == String(upad["edge"]),
                "the user conceded - their serve")
        for i in 2:
                g.ball_pos = g._pad_serve_pos(epad) - e_in * 220.0
                g.ball_dir = -e_in
                g._goga_tick(1.0 / 60.0)
        _check(g.score == 2 and g.run_coins == 0, "2 points - no bonus yet")
        g.ball_pos = g._pad_serve_pos(epad) - e_in * 220.0
        g.ball_dir = -e_in
        g._goga_tick(1.0 / 60.0)
        _check(g.score == 3 and g.run_coins == 1,
                "3 points = +1 GOGACoin bonus")
        _check(g.next_coin_at == 6, "the next bonus waits for 6")

        # ---- COINS: ONE at a time, the REAL asset, the last kicker earns --
        g.coins.clear()
        g.coin_t = 0.001
        g._goga_tick(1.0 / 60.0)
        _check(g.coins.size() == 1, "one coin spawns")
        g.coin_t = 0.001
        g._goga_tick(1.0 / 60.0)
        _check(g.coins.size() == 1,
                "the timer firing again NEVER piles a second coin (owner law)")
        _check(g._coin_tex != null \
                        and String(g._coin_tex.resource_path).ends_with("coin.png"),
                "the court coin wears the REAL GOGACoin asset")
        # walk the coin to the ball so the collection is deterministic
        g.coins[0]["p"] = g.ball_pos + Vector2(1.0, 0.0)
        g.last_kicker = "user"
        var before: int = g.run_coins
        g._goga_tick(1.0 / 60.0)
        _check(g.run_coins == before + 1, "the user's kick takes the coin")
        _check(g.coins.is_empty(), "the coin is GONE after the pickup")
        g.coin_t = 0.001
        g._goga_tick(1.0 / 60.0)
        _check(g.coins.size() == 1,
                "a new coin spawns only after the last one was collected")
        g.last_kicker = "enemy"
        var mid_count: int = g.run_coins
        g._goga_tick(1.0 / 60.0)
        _check(g.run_coins == mid_count, "their kick takes NOTHING")
        _check(g.coin_t > 4.9 and g.coin_t < 20.1,
                "the next coin waits 5-20s (%.1fs)" % g.coin_t)

        # ---- SIZE MODS: fixed px + the clamps ----
        g.last_kicker = "user"
        g._apply_pu("wide", Vector2.ZERO)
        var up: Dictionary = g.pads_by_id["user"]
        _check(absf(float(up["len"]) - 204.0) < 0.001,
                "WIDE = +36px fixed (168 -> 204)")
        up["len"] = 400.0
        g._apply_pu("wide", Vector2.ZERO)
        _check(absf(float(up["len"]) - 400.0) < 0.001,
                "at the ceiling WIDE does nothing")
        up["len"] = 168.0
        g._apply_pu("shrink", Vector2.ZERO)
        _check(absf(float(up["len"]) - 132.0) < 0.001,
                "SHRINK = -36px fixed (168 -> 132)")
        up["len"] = 70.0
        g._apply_pu("shrink", Vector2.ZERO)
        _check(absf(float(up["len"]) - 70.0) < 0.001,
                "at the floor SHRINK does nothing")
        g._apply_pu("mega", Vector2.ZERO)
        _check(float(up["mega_t"]) > 9.9 and absf(float(up["mega_len"])
                        - 504.0) < 0.001, "MEGA = x3 the normal, 10s")
        g._apply_pu("mini", Vector2.ZERO)
        _check(absf(float(up["mega_len"]) - 56.0) < 0.001,
                "MINI = x1/3 the normal, 10s")

        # ---- SPEED MODS: boost until respawn, strike until the next hit --
        g._apply_pu("boost", Vector2.ZERO)
        _check(absf(g._ball_speed() - 340.0 * 1.5) < 0.01,
                "BOOST = +50% while the ball lives")
        g._apply_pu("strike", Vector2.ZERO)
        _check(absf(g._ball_speed() - 340.0 * 4.5) < 0.01,
                "STRIKE stacks +200% on top (x4.5 total)")
        g.serve_t = 0.0
        g.ball_pos = g.field.get_center() + Vector2(10.0, 0.0)
        g.ball_dir = Vector2(-1.0, 0.0)
        for i in 200:
                g._goga_tick(1.0 / 60.0)
                if not g.strike_on:
                        break
        _check(not g.strike_on, "the strike dies on the next hit")
        _check(absf(g.heat - 1.1) < 0.001,
                "the same hit still feeds the heat (x1.10)")
        g._serve("user")
        _check(not g.boost_on, "a respawn clears the boost")

        # ---- CONTROLS: the platform follows the finger ALONG its axis ----
        var axis: int = up["axis"]
        var c0 := up["c"] as Vector2
        var far: float = g.field.end.x - 200.0 if axis == 0 \
                        else g.field.end.y - 200.0
        var cross := c0.y if axis == 0 else c0.x
        var at := Vector2(far, cross + 300.0) if axis == 0 \
                        else Vector2(cross + 300.0, far)
        _touch(g, at, true, 2)
        _drag(g, at, 2)
        _touch(g, at, false, 2)
        var c1 := up["c"] as Vector2
        var moved_axis := c1.x if axis == 0 else c1.y
        var cross_after := c1.y if axis == 0 else c1.x
        _check(absf(moved_axis - far) < 2.0,
                "the platform rides the finger's axis (%.0f -> %.0f)"
                                % [(c0.x if axis == 0 else c0.y), moved_axis])
        _check(absf(cross_after - cross) < 0.001,
                "up/down finger wander NEVER moves the platform")

        # ---- MORE ENEMIES: two extra walls, all hunting the player ----
        Box.set_progress("rally", "opt_more", true)
        g._rebuild_for_orientation()
        _check(g.pads.size() == 2,
                "the walls stay two while MORE ENEMIES is locked")
        Box.buy_unlock("rally", "pong_more", 0)
        g._rebuild_for_orientation()
        _check(g.pads.size() == 4, "MORE ENEMIES adds the two extra walls")
        var extras := 0
        for p in g.pads:
                if not bool(p["user"]) and String(p["id"]).begins_with("extra"):
                        extras += 1
        _check(extras == 2, "the extras guard the other two edges")

        # ---- THE LIVE TOGGLE (owner v0.2.3 patch: "if more enemies got
        # toggled on or off, it does not take effect until next game boot,
        # fix this") - the world rebuilds on the toggle AND on every START ----
        Box.set_progress("rally", "opt_more", false)
        g._begin_run()
        _check(g._phase == "run" and g.pads.size() == 2,
                "the toggle lands THE SECOND it flips (off -> 2 walls now)")
        Box.set_progress("rally", "opt_more", true)
        g._begin_run()
        _check(g.pads.size() == 4,
                "and back on -> 4 walls, same run path, no reboot")
        g.serve_t = 0.0

        # ---- the AI tracks (not stupid): an incoming ball INSIDE its
        # vision range draws real movement ----
        var en: Dictionary = g.pads_by_id["enemy"]
        g.heat = 1.0
        g.boost_on = false
        g.strike_on = false
        g.serve_t = 0.0
        var top_plane: float = g._edge_normal_pos(String(en["edge"]))
        g.ball_pos = Vector2(g.field.get_center().x + 260.0,
                        top_plane + g.field.size.y * 0.30)
        g.ball_dir = Vector2(0, -1)
        var e0 := (en["c"] as Vector2).x if int(en["axis"]) == 0 \
                        else (en["c"] as Vector2).y
        for i in 30:
                g._goga_tick(1.0 / 60.0)
        var e1 := (en["c"] as Vector2).x if int(en["axis"]) == 0 \
                        else (en["c"] as Vector2).y
        _check(absf(e1 - e0) > 40.0, "the AI moves with intent")

        # ---- THE REAL BOUNCE (owner v0.2.3): a strike-fast ball that
        # crosses the pad's face IN ONE FRAME still bounces where it
        # touched - no tunneling into the goal behind the pad, no
        # teleporting "weird spawn" ----
        en["c"] = Vector2(g.field.get_center().x, (en["c"] as Vector2).y)
        g.serve_t = 0.0
        g.ball_prev = Vector2(g.field.get_center().x, top_plane + 300.0)
        g.ball_pos = g.ball_prev + Vector2(0, -900.0)   # 900px in one step
        g.ball_dir = Vector2(0, -1)
        g._tick_pads()
        _check(g.ball_dir.y > 0.0,
                "the 900px-step ball BOUNCED off the platform (no tunnel)")
        _check(g.ball_pos.y >= top_plane,
                "the ball never ends up behind the pad (%.0f vs %.0f)"
                                % [g.ball_pos.y, top_plane])
        _check(g.ball_pos.y < top_plane + 300.0,
                "the bounce happens AT the contact spot, not a teleport")
        # beside the pad the goal law still decides (a real goal, no wall)
        g.ball_prev = Vector2(g.field.position.x + 8.0, top_plane + 300.0)
        g.ball_pos = g.ball_prev + Vector2(0, -900.0)
        g.ball_dir = Vector2(0, -1)
        g._tick_pads()
        _check(g.ball_dir.y < 0.0,
                "a ball BESIDE the pad is not bounced by it (goal zone next)")

        # ---- THE AI VISION (owner v0.2.3): the pad only READS the ball
        # inside a short range from its own edge; outside it drifts to
        # center and can be wrong-footed. Deterministic: cold ball, the
        # ball parked at a known x near the left wall.
        var en2: Dictionary = g.pads_by_id["enemy"]
        g.heat = 1.0
        g.boost_on = false
        g.strike_on = false
        # FAR: incoming but beyond the range -> no read, drift toward center
        en2["c"] = Vector2(g.field.position.x + 120.0, (en2["c"] as Vector2).y)
        g.serve_t = 0.0
        g.ball_pos = Vector2(g.field.position.x + 90.0,
                        top_plane + g.field.size.y * 0.85)
        g.ball_dir = Vector2(0, -1)
        for i in 30:
                g._goga_tick(1.0 / 60.0)
        var far_x := (en2["c"] as Vector2).x
        _check(far_x > g.field.position.x + 220.0,
                "beyond the vision range the pad drifts BACK toward center")
        # NEAR: the same ball INSIDE the range -> the pad READS it and
        # chases ITS x (parked near the LEFT wall - LEFT of both the pad
        # start and center, in every field geometry)
        en2["c"] = Vector2(g.field.position.x + 120.0, (en2["c"] as Vector2).y)
        g.ball_pos = Vector2(g.field.position.x + 90.0,
                        top_plane + g.field.size.y * 0.30)
        g.ball_dir = Vector2(0, -1)
        for i in 30:
                g._goga_tick(1.0 / 60.0)
        var near_x := (en2["c"] as Vector2).x
        _check(near_x < far_x - 40.0,
                "inside the range the pad READS the ball and chases its x")

        # ---- THE TWO COURTS (owner v0.2.3 patch: "change the user to be
        # in the bottom wide side and the enemy on the upper one, the more
        # enemies on the small walls, this way vertical and horizontal
        # really differ and not just another angles") - BOTH courts seat
        # the user at the BOTTOM and the enemy on TOP; the court shape and
        # the extra walls are what differ. ----
        var g2: GogaGame = load("res://game/games/rally/pong.gd").new()
        g2.game_id = "rally"
        g2.start_orientation = "horizontal"
        add_child(g2)
        await get_tree().process_frame
        _check(g2.landscape, "the forced ask builds the horizontal court")
        _check(String(g2.pads_by_id["user"]["edge"]) == "bottom",
                "horizontal: the USER holds the WIDE bottom edge")
        _check(String(g2.pads_by_id["enemy"]["edge"]) == "top",
                "horizontal: the enemy sits on the top edge")
        _check(int(g2.pads_by_id["user"]["axis"]) == 0,
                "horizontal: the user's platform slides ALONG the wide side")
        Box.set_progress("rally", "opt_more", true)
        Box.buy_unlock("rally", "pong_more", 0)
        g2.landscape = true          # hold the forced court (headless lies)
        g2._build_world()
        _check(String(g2.pads_by_id["extra_l"]["edge"]) == "left" \
                        and String(g2.pads_by_id["extra_r"]["edge"]) == "right",
                "horizontal: the more-enemy walls take the SMALL left/right")
        # the vertical court: same seats, the LONG field
        var g3: GogaGame = load("res://game/games/rally/pong.gd").new()
        g3.game_id = "rally"
        g3.start_orientation = "vertical"
        add_child(g3)
        await get_tree().process_frame
        _check(not g3.landscape, "the forced ask builds the vertical court")
        _check(String(g3.pads_by_id["user"]["edge"]) == "bottom",
                "vertical: the USER holds the bottom edge too")
        _check(String(g3.pads_by_id["enemy"]["edge"]) == "top",
                "vertical: the enemy took the top edge too")
        # ---- THE MORE-ENEMIES BRAIN (owner: "make them faster and more
        # smarter" - speed is also his prescribed fix for their short land
        # of view on the small walls) ----
        for inst in [g2, g3]:
                var em: Dictionary = inst.pads_by_id["extra_l"]
                var mn: Dictionary = inst.pads_by_id["enemy"]
                _check(float(em["ai_speed"]) > float(mn["ai_speed"]),
                        "the extra walls hunt FASTER than the main rival")
                _check(float(em["think"]) < float(mn["think"]),
                        "the extra walls think FASTER (smarter)")
                _check(float(em["err_k"]) < float(mn["err_k"]),
                        "the extra walls aim STEADIER (smarter)")
        g2.queue_free()
        g3.queue_free()
        await get_tree().process_frame

        # ---- END banks the run ----
        g.finish_run(g.score)
        _check(g.over, "END hands the run to the dead menu")
        g.queue_free()
        await get_tree().process_frame
        Box.reset_all()
        print("=== pong probe %s ===" % ("PASS" if fails == 0 else "FAIL"))
        get_tree().quit(1 if fails > 0 else 0)

func _ready() -> void:
        print("=== GOGABox pong probe (v0.2.3 vision world) ===")
        await _run()
