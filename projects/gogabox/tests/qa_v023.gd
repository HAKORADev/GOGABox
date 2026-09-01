extends Node
## qa_v023 - v0.2.3 visual QA: boots the REAL box menu (tabs + tiles +
## soon ? art + strip thumbs), then the PONG position ask and the PONG
## shop (the BoxScroll rebuild + the default BLUE skin row). Saves PNGs.

func _ready() -> void:
        Box.reset_all()
        var ps: PackedScene = load("res://main.tscn")
        var m: Node = ps.instantiate()
        add_child(m)
        await get_tree().create_timer(2.0).timeout
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/qa_v023_menu.png")
        print("[qa] menu shot")
        m.queue_free()
        await get_tree().process_frame

        # ---- the pong ask (minimal: just the two phone cards) ----
        var g: GogaGame = load("res://game/games/rally/pong.gd").new()
        g.game_id = "rally"
        add_child(g)
        await get_tree().create_timer(0.6).timeout
        await get_tree().process_frame
        img = get_viewport().get_texture().get_image()
        img.save_png("/tmp/qa_v023_ask.png")
        print("[qa] ask shot")
        # ---- the pong shop from the options screen ----
        g._orient_choice("vertical" if g._auto_landscape() else "horizontal")
        await get_tree().process_frame
        g._shop_open()
        await get_tree().create_timer(0.4).timeout
        await get_tree().process_frame
        img = get_viewport().get_texture().get_image()
        img.save_png("/tmp/qa_v023_shop.png")
        print("[qa] shop shot")
        # ---- the run with the ball + coin ----
        g._shop_close()
        await get_tree().process_frame
        g._begin_run()
        g.coins.append({"p": g.field.get_center() + Vector2(120, -40), "pop": 1.0})
        for i in 50:
                g._goga_tick(1.0 / 60.0)
        if g._view != null:
                g._view.queue_redraw()
        await get_tree().create_timer(0.35).timeout
        await get_tree().process_frame
        img = get_viewport().get_texture().get_image()
        img.save_png("/tmp/qa_v023_run.png")
        print("[qa] run shot")
        g.queue_free()
        Box.reset_all()
        get_tree().quit(0)
