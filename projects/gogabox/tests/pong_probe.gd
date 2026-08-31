extends Node
## pong_probe - v0.2.2: drives the rebuilt PONG headless. The laws:
## the ask listens to the window, the options screen follows, the serve
## is born at the conceder's edge, goals pay +1/-1 (clamped at 0), the
## 3-points-per-coin bonus, the x1.1 heat (reset per serve) with boost
## (+50% until respawn) and strike (+200% until the next hit), the FIXED
## px size mods with their clamps, the coin economy (last kicker earns,
## 5-20s window), the controls follow the finger ALONG the axis only,
## and MORE ENEMIES adds two walls that all hunt the player.
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
        _check(g._auto_landscape() == (g.landscape),
                        "the court matches the CURRENT window shape")
        # the stale pref never wins the highlight (the snake law, reused)
        var cur := "horizontal" if g._auto_landscape() else "vertical"
        Box.set_progress("rally", "orient_pref",
                        "horizontal" if cur == "vertical" else "vertical")
        g._orient_choice(cur)
        _check(g._phase == "options", "tapping the CURRENT shape proceeds")

        # ---- the run: the serve is born at the USER's edge ----
        g._begin_run()
        _check(g._phase == "run", "START begins the run")
        _check(g.serve_from == "user" and g.serve_t > 0.0,
                "the first serve waits at the user's edge")
        _check(absf(g.heat - 1.0) < 0.0001, "the ball starts cold (x1.00)")
        _check(g.pads.size() == 2, "two platforms by default")

        # ---- THE HEAT LAW: every wall hit x1.1, reset per serve ----
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

        # ---- COINS: the last kicker earns ----
        g.coins.append({"p": g.ball_pos + Vector2(1.0, 0.0), "pop": 1.0})
        g.last_kicker = "user"
        var before: int = g.run_coins
        g._goga_tick(1.0 / 60.0)
        _check(g.run_coins == before + 1, "the user's kick takes the coin")
        g.coins.append({"p": g.ball_pos + Vector2(1.0, 0.0), "pop": 1.0})
        g.last_kicker = "enemy"
        g._goga_tick(1.0 / 60.0)
        _check(g.run_coins == before + 1, "their kick takes NOTHING")
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

        # ---- the AI tracks (not stupid) ----
        var en: Dictionary = g.pads_by_id["enemy"]
        var e0 := (en["c"] as Vector2).x if int(en["axis"]) == 0 \
                        else (en["c"] as Vector2).y
        g.serve_t = 0.0
        for i in 40:
                g._goga_tick(1.0 / 60.0)
        var e1 := (en["c"] as Vector2).x if int(en["axis"]) == 0 \
                        else (en["c"] as Vector2).y
        _check(absf(e1 - e0) > 1.0, "the AI moves with intent")

        # ---- END banks the run ----
        g.finish_run(g.score)
        _check(g.over, "END hands the run to the dead menu")
        g.queue_free()
        await get_tree().process_frame
        Box.reset_all()
        print("=== pong probe %s ===" % ("PASS" if fails == 0 else "FAIL"))
        get_tree().quit(1 if fails > 0 else 0)

func _ready() -> void:
        print("=== GOGABox pong probe (v0.2.2 goals world) ===")
        await _run()
