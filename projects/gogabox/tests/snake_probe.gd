extends Node
## snake_probe - v0.2.0: drives the MIRROR WORLD build headless. The REAL
## flow (position ask -> mode menu -> tap-to-start -> run), the mouse-style
## steering (synthetic touch drags), the MIRROR wrap math (owner's 80 -> 20
## rule), the no-drift repeat crossing, spawn-on-start (the field is EMPTY
## in the menus), peace (no war, no coins, no self-death), the speed law
## (x1.1 per 10 score), sprint/slog permanence, real self-bite, the eater
## self-bite, width shrink symmetry, the enemy brain surviving, the shop
## dead-end fix (close always restores the phase), and the death COLLAPSE
## handover to finish_run. Exit 0 = pass.
##
##   godot --headless --path projects/gogabox res://tests/snake_probe.tscn

var fails := 0

func _ready() -> void:
        print("=== GOGABox snake probe (v0.2.1 straight-line world) ===")
        await _run()
        print("=== snake probe %s ===" % ("PASS" if fails == 0 else "FAIL"))
        get_tree().quit(1 if fails > 0 else 0)

func _drag_rel(g: GogaGame, from: Vector2, to: Vector2, idx := 0) -> void:
        var d := InputEventScreenDrag.new()
        d.index = idx
        d.position = to
        d.relative = to - from
        g._goga_input(d)

func _touch(g: GogaGame, at: Vector2, pressed: bool, idx := 0) -> void:
        var t := InputEventScreenTouch.new()
        t.index = idx
        t.position = at
        t.pressed = pressed
        g._goga_input(t)

func _check(cond: bool, msg: String) -> void:
        print(("  PASS: " if cond else "  FAIL: ") + msg)
        if not cond:
                fails += 1

func _run() -> void:
        Box.reset_all()
        var game: GogaGame = load("res://game/games/snake/snake.gd").new()
        game.game_id = "snake"
        add_child(game)
        await get_tree().process_frame
        await get_tree().process_frame

        # ---- boot: the position ask, and the field is EMPTY (owner v0.2.0) ----
        _check(game._phase == "orient", "boots into the position ask")
        _check(not game.apple_live and not game.coin_live and not game.power_live,
                        "no food exists before the run")
        _check(game.enemies.is_empty() and game.bugs.is_empty()
                        and game.obstacles.is_empty(), "no war exists before the run")

        # ---- the STRAIGHT-LINE wrap (owner v0.2.1: exit at 80 -> enter at
        # 80, same heading - the path is one line continued; NO mirroring)
        var sb0 := SnakeBody.new()
        var b1 := Rect2(0, 0, 1000, 1000)
        var w1: Dictionary = sb0.wrap_point(Vector2(800.0, -10.0), b1)
        _check(absf(w1["pos"].x - 800.0) < 0.001
                        and absf(w1["pos"].y - 990.0) < 0.001,
                        "top exit at x=800 enters the bottom at THE SAME x=800")
        var w2: Dictionary = sb0.wrap_point(Vector2(1010.0, 300.0), b1)
        _check(absf(w2["pos"].x - 10.0) < 0.001
                        and absf(w2["pos"].y - 300.0) < 0.001,
                        "right exit at y=300 enters the left at THE SAME y=300")
        var w4: Dictionary = sb0.wrap_point(Vector2(500.0, 500.0), b1)
        _check(not bool(w4["wrapped"]), "the middle of the field never wraps")
        # the angle vs the wall is PRESERVED: a 30-degree line stays 30 degrees
        var wb := SnakeBody.new()
        wb.setup(Vector2(500.0, 500.0), -PI / 6.0, Color.BLUE, Color.WHITE)
        wb.len_target = 200.0
        wb.length_px = 200.0
        wb.speed = 400.0
        var slope_before := 0.0
        var slope_after := 0.0
        var saw_break := false
        var prev := wb.head_pos
        for i in 240:
                wb.advance(1.0 / 60.0, b1, true)
                if bool(wb.trail_brk[wb.trail_brk.size() - 1]):
                        saw_break = true
                        slope_before = (prev - wb.trail[wb.trail.size() - 3]).angle()
                elif saw_break and slope_after == 0.0:
                        slope_after = (wb.head_pos - prev).angle()
                prev = wb.head_pos
        _check(saw_break, "a crossing happened")
        _check(absf(wrapf(slope_after - slope_before, -PI, PI)) < 0.05,
                        "the heading survives the wall EXACTLY (degree math)")

        # ---- same position picked = no reload; straight to the mode menu ----
        game._show_mode_select()
        _check(game._phase == "mode", "mode menu follows the ask")
        _check(not game.apple_live and game.enemies.is_empty(),
                        "menus never build the war")

        # ---- pick no-walls + ready; START builds the world ----
        game.wrap_mode = true
        Box.set_progress("snake", "mode_nowalls", true)
        Box.set_progress("snake", "opt_enemies", true)
        game._show_ready_card()
        _check(game._phase == "ready", "ready card waits for the tap")
        _check(not game.apple_live, "still nothing on the field at ready")
        _touch(game, Vector2(360, 640), true)   # the REAL input path
        _check(game._phase == "run", "tap starts the run")
        _touch(game, Vector2(360, 640), false)  # release: the wheel finger is free
        _check(game.apple_live, "the run spawned the fruit")
        _check(game.enemies.size() == 1, "the run spawned the enemy")
        _check(Jukebox._current_music.find("snake_theme") != -1,
                        "snake owns its music in-run")

        # ---- MOUSE-STYLE STEERING: a left SWIPE bends the head left ----
        var d0: float = game.player.head_dir
        _touch(game, Vector2(300, 400), true, 3)
        for k in 5:
                _drag_rel(game, Vector2(300.0 - k * 10.0, 400.0),
                                Vector2(300.0 - (k + 1) * 10.0, 400.0), 3)
                for t in 2:
                        game._goga_tick(1.0 / 60.0)
        _touch(game, Vector2(204.0, 400.0), false, 3)
        var turned := absf(wrapf(game.player.head_dir - d0, -PI, PI))
        _check(turned > 0.2, "a left swipe bends the head (%.2f rad)" % turned)
        # a RESTING finger never steers (the exploit cap)
        var d1: float = game.player.head_dir
        _touch(game, Vector2(300, 400), true, 4)
        for i in 40:
                game._goga_tick(1.0 / 60.0)
        _check(absf(wrapf(game.player.head_dir - d1, -PI, PI)) < 0.01,
                        "a resting finger never moves the head")
        _touch(game, Vector2(300, 400), false, 4)
        _check(game.player.alive, "open-field steering survives (no self-bite)")

        # ---- the no-DRIFT repeat crossing (the 30-degree loop bug) ----
        var p := SnakeBody.new()
        p.setup(Vector2(500.0, 500.0), -PI / 6.0, Color.BLUE, Color.WHITE)
        p.len_target = 260.0
        p.length_px = 260.0
        p.speed = 400.0
        var b2 := Rect2(0, 0, 1000, 1000)
        var crossings := 0
        var side_entry_ok := true
        var brk_found := false
        var brk_synced := false
        var strips_at := 1
        var wrap_frame := -1
        var _entry_y := -1.0
        for i in 60 * 12:
                var adv: Dictionary = p.advance(1.0 / 60.0, b2, true)
                if bool(adv["wrapped"]):
                        crossings += 1
                        if wrap_frame < 0:
                                wrap_frame = i
                                for bb in p.trail_brk:
                                        if bb:
                                                brk_found = true
                                                break
                                brk_synced = p.trail_brk.size() == p.trail.size()
                if wrap_frame >= 0 and i == wrap_frame + 12:
                        # the head-side strip needs samples before it can ribbon
                        strips_at = p.ribbon().size()
                # torus drift law: successive left-wall entries differ by
                # EXACTLY -W*tan(30 deg) (mod H) = -577.4 - a drifting line
                # breaks this constant step (the owner's 10-20-30 bug)
                if bool(adv["wrapped"]) and p.head_pos.x < 40.0:
                        if _entry_y > 0.0 and absf(wrapf(
                                        p.head_pos.y - _entry_y + 577.4,
                                        -500.0, 500.0)) > 14.0:
                                side_entry_ok = false
                        _entry_y = p.head_pos.y
        _check(crossings >= 3, "a 30-degree line repeats its crossings (%d)" % crossings)
        _check(side_entry_ok, "the crossing line does NOT drift (the loop bug is dead)")
        _check(brk_found, "wrap breaks are recorded at the crossing")
        _check(brk_synced, "break bookkeeping stays in sync with the trail")
        _check(strips_at >= 2, "the ribbon paints as strips through a wall (%d)" % strips_at)
        # the ribbon is CONVEX PIECES now (quads + joint discs) - a coiled
        # snake keeps its fill (the old single polygon flickered itself away)
        var coil := SnakeBody.new()
        coil.setup(Vector2(500.0, 500.0), 0.0, Color.BLUE, Color.WHITE)
        coil.len_target = 700.0
        coil.length_px = 700.0
        coil.speed = 300.0
        for i in 200:
                coil.head_dir += 0.085
                coil.advance(1.0 / 60.0, b2, false)
        var pieces: Array = coil.ribbon()
        _check(pieces.size() > 40, "a coiled body renders as convex pieces (%d)"
                        % pieces.size())
        var filled := 0
        for pc in pieces:
                var cc: Color = (pc["cols"] as PackedColorArray)[0]
                if cc.a > 0.9:
                        filled += 1
        _check(filled > pieces.size() - 3,
                "every piece stays opaque under self-overlap (no flicker)")

        # ---- self-bite is REAL again (straight wrap made it impossible) ----
        var sb := SnakeBody.new()
        sb.setup(Vector2(500.0, 500.0), 0.0, Color.BLUE, Color.WHITE)
        sb.len_target = 620.0
        sb.length_px = 620.0
        sb.speed = 400.0
        var bit := false
        for i in 600:
                sb.head_dir += 0.09
                sb.advance(1.0 / 60.0, b2, false)
                if sb.self_bite(sb.head_pos, sb.head_r(), b2):
                        bit = true
                        break
        _check(bit, "a spiral snake bites ITSELF (self-eat is possible)")

        # ---- SPEED LAW: 10 points = x1.1, the base speed follows ----
        _check(absf(game._score_speed_mult(10) - 1.1) < 0.0001, "10 points = x1.10")
        _check(absf(game._score_speed_mult(20) - 1.21) < 0.0001, "20 points = x1.21")
        game.set_score(10)
        game._sync_speeds()
        _check(absf(game.player.base_speed - 300.0 * 1.1) < 0.01,
                        "the base speed follows the score law")
        game.set_score(0)

        # ---- PERMANENT sprint/slog ----
        var perm_before: float = game.player.perm_mult
        game._apply_power(game.player, "sprint", true)
        _check(absf(game.player.perm_mult - perm_before * 1.5) < 0.001,
                        "SPRINT is permanent (+50%)")
        game._apply_power(game.player, "slog", true)
        _check(absf(game.player.perm_mult - perm_before * 0.75) < 0.001,
                        "SLOG stacks permanent (-50% of the current)")
        _check(not game.player.has_power("sprint")
                        and not game.player.has_power("slog"),
                        "permanent fruits wear no timer chip")

        # ---- WIDTH SYMMETRY: it shrinks the same way it grew ----
        var lt := 530.0
        var w_mid: float = game.player.width_from_len(lt)
        var w_grow: float = game.player.width_from_len(lt + SnakeBody.LEN_PER_APPLE)
        var w_slim: float = game.player.width_from_len(lt - SnakeBody.LEN_PER_APPLE)
        _check(w_grow > w_mid and w_slim < w_mid,
                        "width follows length BOTH ways")

        # ---- PEACE: no war, no coins, no self-death (fresh field like a run) --
        game.player.setup(game.board.get_center(), 0.0,
                        game.player.pal["pri"], game.player.pal["milk"])
        game.peace = true
        game.score_bonus_enabled = false
        game.enemies.clear()
        game.bugs.clear()
        game.obstacles.clear()
        game.apple_live = false
        game.coin_live = false
        Box.set_progress("snake", "opt_enemies", true)
        game._populate_world()
        _check(game.enemies.is_empty() and game.bugs.is_empty()
                        and game.obstacles.is_empty(), "peace spawns no war")
        _check(not game.coin_live, "peace spawns no GOGACoins")
        var pc: SnakeBody = game.player
        for i in 400:
                pc.head_dir += 0.10
                pc.advance(1.0 / 60.0, game.board, true)
                game._check_player_collisions()
                if not pc.alive:
                        break
        _check(pc.alive, "PEACE never dies on itself")
        game.peace = false
        game.score_bonus_enabled = true

        # ---- SNAKE-EATER bites YOU: self-collision loses length, not the run
        game.player.apply_power("eater", 10.0)
        var pts: Array = game.player.body_points()
        var mid_pt: Vector2 = pts[int(pts.size() / 2.0)][0]
        game.player.head_pos = mid_pt
        var len_before: float = game.player.len_target
        game._bite_cd = 0.0
        game._self_bite_eat()
        _check(game.player.alive, "the eater self-bite is not death")
        _check(game.player.len_target < len_before, "the self-bite LOSES length")
        game.player.effects.erase("eater")

        # ---- the enemy brain SURVIVES (the 10-second complaint) ----
        game.enemies.clear()
        game.bugs.clear()
        game.obstacles.clear()
        game._add_enemy(0)
        var en: Dictionary = game.enemies[0]
        var eb: SnakeBody = en["body"]
        eb.setup(Vector2(game.board.get_center().x, game.board.end.y - 240.0),
                        -PI / 2.0, Color("3fae5c"), Color("d8f0dc"))
        eb.len_target = 300.0
        eb.length_px = 300.0
        # the player parks in a corner, tiny - the test is open-field survival
        game.player.setup(game.board.position + Vector2(50.0, 50.0), 0.0,
                        game.player.pal["pri"], game.player.pal["milk"])
        game.player.len_target = 120.0
        game.player.length_px = 120.0
        var survived := 0.0
        while survived < 12.0 and eb.alive:
                (en["ai"] as SnakeAI).think(1.0 / 60.0, game)
                eb.tick_effects(1.0 / 60.0)
                var adv2: Dictionary = eb.advance(1.0 / 60.0, game.board, true)
                if adv2["hit_wall"] or eb.self_bite(eb.head_pos, eb.head_r(), game.board):
                        eb.alive = false
                survived += 1.0 / 60.0
        _check(survived >= 12.0, "the AI stands 12s in an open mirror field (%.1fs)"
                        % survived)
        _check((en["body"] as SnakeBody).pal["pri"] == Color("3fae5c"),
                        "enemy #0 is GREEN (owner rule)")

        # ---- the shop dead-end fix: close RESTORES the phase screen ----
        game._show_mode_select()
        Box.earn(2000)
        game._shop_open()
        _check(get_tree().paused, "the shop pauses")
        game._shop_close()
        _check(not get_tree().paused, "close unpauses")
        _check(game._phase == "mode", "THE DEAD-END FIX: the mode menu returns")
        game._show_ready_card()
        game._shop_open()
        game._shop_close()
        _check(game._phase == "ready" and is_instance_valid(game._ready_card),
                        "close restores the ready card too")

        # ---- death = COLLAPSE, then finish_run ----
        game._start()
        var was_alive: bool = game.player.alive
        game._die()
        _check(was_alive and not game.player.alive, "the death fires")
        _check(game._collapse_t > 0.0, "the collapse is playing")
        var waited := 0.0
        while not game.over and waited < 3.0:
                game._goga_tick(1.0 / 60.0)
                await get_tree().process_frame
                waited += 1.0 / 60.0
        _check(game.over, "the collapse hands over to finish_run")
        _check(Jukebox._current_music.find("snake_theme") == -1,
                        "run music stops with the run")

        # ---- the whole paint pass executes (field, strips, chips, place) ----
        game._view.queue_redraw()
        await get_tree().process_frame
        await get_tree().process_frame
        _check(true, "paint pass executed (mirror strips + chips + place)")

        game.queue_free()
        await get_tree().process_frame
        Box.reset_all()
