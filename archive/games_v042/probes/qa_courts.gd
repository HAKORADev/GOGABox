extends Node
## qa_courts - the v0.2.3 patch courts: boots pong forced-horizontal and
## forced-vertical mid-run (more enemies ON) and screenshots both, so the
## new seat layout is verified by eye, not just by probe.

func _ready() -> void:
        Box.reset_all()
        Box.set_progress("rally", "opt_more", true)
        Box.buy_unlock("rally", "pong_more", 0)
        # ---- horizontal court ----
        var g: GogaGame = load("res://game/games/rally/pong.gd").new()
        g.game_id = "rally"
        g.start_orientation = "horizontal"
        add_child(g)
        await get_tree().create_timer(0.8).timeout
        g._begin_run()
        g.serve_t = 0.0
        await get_tree().create_timer(1.2).timeout
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/qa_court_horizontal.png")
        print("[qa] horizontal shot - user=", g.pads_by_id["user"]["edge"],
                        " extras=", g.pads_by_id["extra_l"]["edge"], "+",
                        g.pads_by_id["extra_r"]["edge"])
        g.queue_free()
        await get_tree().process_frame
        # ---- vertical court ----
        var g2: GogaGame = load("res://game/games/rally/pong.gd").new()
        g2.game_id = "rally"
        g2.start_orientation = "vertical"
        add_child(g2)
        await get_tree().create_timer(0.8).timeout
        g2._begin_run()
        g2.serve_t = 0.0
        await get_tree().create_timer(1.2).timeout
        img = get_viewport().get_texture().get_image()
        img.save_png("/tmp/qa_court_vertical.png")
        print("[qa] vertical shot - user=", g2.pads_by_id["user"]["edge"])
        g2.queue_free()
        Box.reset_all()
        get_tree().quit(0)
