extends Node
## qa_dash - the v0.2.4 SPACE DASH visual QA: boots the REAL game scene,
## then screenshots the ready card, a live battle (fleet + beams + popups),
## the laser column, a thunder chain, a bomb blast, the shop sheet, and
## the green space. Run under Xvfb:
##   DISPLAY=:99 godot --path . res://tests/qa_dash.tscn

func _shot(path: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        img.save_png(path)
        print("[qa] ", path)

func _touch(g: GogaGame, at: Vector2, pressed: bool) -> void:
        var t := InputEventScreenTouch.new()
        t.index = 0
        t.position = at
        t.pressed = pressed
        g._goga_input(t)

func _ready() -> void:
        var g: GogaGame = load("res://game/games/lanes/lanes.gd").new()
        g.game_id = "lanes"
        add_child(g)
        await get_tree().create_timer(1.0).timeout
        await get_tree().process_frame
        var vp := g.get_viewport_rect().size

        # 1. the ready card over the living sky
        await _shot("/tmp/qa_dash_ready.png")

        # 2. start + a lively battle frame
        g._start()
        for i in 9:
                var kinds := ["grunt", "grunt2", "runner", "shooter",
                        "grunt", "shielded", "splitter", "tank", "runner"]
                g._spawn_enemy(kinds[i % kinds.size()], i % 5,
                                Vector2(g._lane_x(i % 5), 180.0 + 120.0 * (i % 4)))
        g._spawn_enemy("ufo_shot", 3, Vector2(g._lane_x(3), 260.0))
        g._spawn_enemy("shatter", 1, Vector2(g._lane_x(1), 520.0))
        for i in 5:   # a burst of beams mid-flight
                g._fire_beams()
        for b in g.bolts:   # spread the bolts up the lane for the shot
                b["node"].position.y -= randf() * 500.0
        await get_tree().create_timer(0.25).timeout
        await _shot("/tmp/qa_dash_battle.png")

        # 3. the laser column
        g.weapon = "laser"
        g.laser_live = 2.0
        g.laser_cd = 0.0
        g.firing = true
        g._laser_burn(0.016)
        await _shot("/tmp/qa_dash_laser.png")
        g.firing = false

        # 4. a thunder chain
        g.weapon = "thunder"
        g.thunder_live = 5.0
        g.thunder_cd = 0.0
        g._do_strike()
        await _shot("/tmp/qa_dash_thunder.png")

        # 5. the bomb blast
        g.weapon = "bomb"
        g.bomb_cd = 0.0
        g._drop_bomb()
        var b: Dictionary = g.bombs[0]
        b["node"].position = Vector2(g._lane_x(2), 420.0)
        g._bomb_blast(b["node"].position)
        await _shot("/tmp/qa_dash_bomb.png")

        # 6. the shop
        g._shop_open()
        await get_tree().create_timer(0.35).timeout
        await _shot("/tmp/qa_dash_shop.png")
        g._shop_close()
        await get_tree().create_timer(0.2).timeout

        # 7. the green space
        Box.buy_item("lanes", "space", "green", 0)
        g._apply_space((g.bg_rect.material) as ShaderMaterial, "green")
        await get_tree().create_timer(0.35).timeout
        await _shot("/tmp/qa_dash_green.png")

        print("[qa] done")
        get_tree().quit(0)
