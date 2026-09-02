extends Node
## qa_v031 - the v0.3.1 visual QA: the smaller XO marks, the slasher
## patches (the veg size, the bottom-center landscape, no glint), and the
## Cursed Dario look (the day level, the night theme, the boss arena).
##   DISPLAY=:99 godot --path . res://tests/qa_v031.tscn

const OUT := "/home/z/my-project/download/qa_v031/"

func _shot(path: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        get_viewport().get_texture().get_image().save_png(path)
        print("[qa] ", path)

func _run() -> void:
        DirAccess.make_dir_recursive_absolute(OUT)
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)

        # ================= XO (the smaller marks) =================
        var x: GogaGame = load("res://game/games/xo/xo.gd").new()
        x.game_id = "xo"
        add_child(x)
        await get_tree().create_timer(0.5).timeout
        x.board = [1, 0, 2, 0, 1, 0, 0, 0, 2]
        x._place(0, x.X)
        x._place(2, x.O)
        await get_tree().create_timer(0.12).timeout
        x._place(4, x.X)
        x._place(8, x.O)
        await get_tree().create_timer(0.35).timeout
        await _shot(OUT + "01_xo_marks_smaller.png")
        x.queue_free()

        # ================= FRUIT SLASHER =================
        var s: GogaGame = load("res://game/games/slasher/slasher.gd").new()
        s.game_id = "slasher"
        add_child(s)
        await get_tree().create_timer(0.5).timeout
        s._orient_choice("vertical")
        s._start_run()
        await get_tree().create_timer(1.2).timeout
        await _shot(OUT + "02_slasher_portrait.png")
        # the vegetables at their new size (equip + force spawns)
        Box.equip_item("slasher", "produce", "veggies")
        s.mode_id = "veggies"
        s.items.clear()
        for i in 4:
                s._launch(s._item_kind())
        await get_tree().create_timer(0.9).timeout
        await _shot(OUT + "03_slasher_vegs_bigger.png")
        s.queue_free()

        # ================= CURSED DARIO =================
        var d: GogaGame = load("res://game/games/dario/dario.gd").new()
        d.game_id = "dario"
        add_child(d)
        await get_tree().create_timer(0.6).timeout
        await get_tree().create_timer(1.2).timeout
        await _shot(OUT + "04_dario_level1_day.png")
        # the ? box bump + the powerup pickup
        Box.equip_item("dario", "power", "foot")
        Box.equip_item("dario", "power", "shield")
        Box.equip_item("dario", "power", "jump")
        d._load_level(2)
        d.p_pos = Vector2(0, 0)
        d.p_node.position = d.p_pos
        await get_tree().create_timer(0.4).timeout
        await _shot(OUT + "05_dario_blocks_level.png")
        # the NIGHT theme
        Box.equip_item("dario", "theme", "night")
        d._apply_sky()
        await get_tree().create_timer(0.3).timeout
        await _shot(OUT + "06_dario_night.png")
        # the Witcher arena
        Box.equip_item("dario", "theme", "none")
        d._apply_sky()
        d.level_i = 9
        d._load_level(9)
        d._start_boss(Vector2i(9, 6))
        await get_tree().create_timer(1.0).timeout
        await _shot(OUT + "07_dario_witcher.png")
        print("[qa] done")
        get_tree().quit(0)

func _ready() -> void:
        _run.call_deferred()
