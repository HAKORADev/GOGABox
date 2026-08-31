extends Node
## qa_v022 - visual QA for the pong rebuild + the snake score economy:
## the ask, the options screen, the run (pads/ball/tail/coins/powerups),
## the landscape court, the goals widget, and a snake coil for the
## multiplier accumulator.
##
##   godot --path . res://tests/qa_v022.tscn ++ --out=/tmp/qa_v022

var _out := "/tmp/qa_v022"

func _ready() -> void:
        for a in OS.get_cmdline_user_args():
                if a.begins_with("--out="):
                        _out = a.split("=")[1]
        DirAccess.make_dir_recursive_absolute(_out)
        await _run()
        get_tree().quit(0)

func _shot(name_: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        img.save_png("%s/%s.png" % [_out, name_])
        print("[qa] shot ", name_)

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
        # ---------- PONG: ask -> options -> run ----------
        var g: GogaGame = load("res://game/games/rally/pong.gd").new()
        g.game_id = "rally"
        add_child(g)
        await get_tree().create_timer(0.5).timeout
        await _shot("pong_ask")
        g._orient_choice("horizontal" if g._auto_landscape() else "vertical")
        await get_tree().create_timer(0.3).timeout
        await _shot("pong_options")
        # own + toggle everything so the shots show the full life
        for k in ["pong_size", "pong_speed", "pong_sparkles", "pong_more"]:
                Box.buy_unlock("rally", k, 0)
        Box.set_progress("rally", "opt_size", true)
        Box.set_progress("rally", "opt_speed", true)
        Box.set_progress("rally", "opt_sparkles", true)
        Box.set_progress("rally", "opt_more", true)
        Box.buy_skin("rally", "gold", 0)
        Box.equip_skin("rally", "gold")
        g._rebuild_for_orientation()
        g._show_options()
        await get_tree().create_timer(0.3).timeout
        await _shot("pong_options_full")
        g._begin_run()
        # a hot rally: let it run, then heat it by hand for the burn shot
        await get_tree().create_timer(1.4).timeout
        g.serve_t = 0.0
        g.heat = 2.6
        g.strike_on = true
        g.ball_pos = g.field.get_center()
        g.ball_dir = Vector2(0.6, -0.8).normalized()
        for i in 30:
                g._goga_tick(1.0 / 60.0)
                await get_tree().process_frame
        g.coins.append({"p": g.field.get_center() + Vector2(-160.0, 90.0),
                        "pop": 1.0})
        g.pus.append({"id": "mega", "p": g.field.get_center()
                        + Vector2(180.0, -110.0), "pop": 1.0})
        g.pus.append({"id": "strike", "p": g.field.get_center()
                        + Vector2(40.0, 160.0), "pop": 1.0})
        for i in 20:
                g._goga_tick(1.0 / 60.0)
                await get_tree().process_frame
        await _shot("pong_run_hot")
        # the BURN: max heat + strike, mid-court, before any goal resets it
        g.heat = 3.5
        g.strike_on = true
        g.ball_pos = g.field.get_center()
        g.ball_dir = Vector2(0.75, -0.66).normalized()
        for i in 16:
                g._goga_tick(1.0 / 60.0)
                await get_tree().process_frame
        await _shot("pong_burn")
        # a goal for the user: widget + conceder serve
        var epad: Dictionary = g.pads_by_id["enemy"]
        var ein: Vector2 = g._edge_inward(String(epad["edge"]))
        g.ball_pos = g._pad_serve_pos(epad) - ein * 220.0
        g._goga_tick(1.0 / 60.0)
        await get_tree().create_timer(0.2).timeout
        await _shot("pong_goal_widget")
        g.queue_free()
        await get_tree().process_frame
        # ---------- the landscape court ----------
        var g2: GogaGame = load("res://game/games/rally/pong.gd").new()
        g2.game_id = "rally"
        g2.start_orientation = "horizontal"
        add_child(g2)
        await get_tree().create_timer(0.5).timeout
        g2._begin_run()
        g2.serve_t = 0.0
        g2.heat = 2.2
        g2.ball_pos = g2.field.get_center()
        g2.ball_dir = Vector2(0.8, 0.5).normalized()
        for i in 26:
                g2._goga_tick(1.0 / 60.0)
                await get_tree().process_frame
        await _shot("pong_landscape")
        g2.queue_free()
        await get_tree().process_frame
        # ---------- SNAKE: the score accumulator coil ----------
        var s: GogaGame = load("res://game/games/snake/snake.gd").new()
        s.game_id = "snake"
        add_child(s)
        await get_tree().create_timer(0.5).timeout
        s._show_mode_select()
        s._show_ready_card()
        s._start()
        s.enemies.clear()   # a clean coil shot - the war is probed elsewhere
        s.obstacles.clear()
        var p: SnakeBody = s.player
        p.len_target = 520.0
        p.length_px = 520.0
        s.set_score(12)   # x1.1 territory - the fifth fruit's +2 lives here
        for i in 110:
                p.head_dir += 0.052
                s._goga_tick(1.0 / 60.0)
                await get_tree().process_frame
        await _shot("snake_score_world")
        Box.reset_all()
