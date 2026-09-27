extends Node
## qa_v029 - the v0.2.9 visual QA (the owner's rule: LOOK before shipping).
## XO: the REAL sketch marks + the clean strike + the CPU banner. Slasher:
## the position ask, the options with the vegetables row, the dusk
## background, a live slice with the halves + juice, the hearts, the
## +N/-N reader. Run under Xvfb:
##   DISPLAY=:99 godot --path . res://tests/qa_v029.tscn

const OUT := "/home/z/my-project/download/qa_v029/"

func _shot(path: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        get_viewport().get_texture().get_image().save_png(path)
        print("[qa] ", path)

func _run() -> void:
        DirAccess.make_dir_recursive_absolute(OUT)
        Box.reset_all()

        # ================= XO (the patch) =================
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
        await get_tree().create_timer(0.3).timeout
        await _shot(OUT + "01_xo_real_sketch_marks.png")
        x.board = [1, 1, 0, 2, 2, 0, 0, 0, 0]
        x.turn = x.X
        x.state = "play"
        x._tap_cell(2)
        await get_tree().create_timer(0.5).timeout
        await _shot(OUT + "02_xo_clean_strike.png")
        x.queue_free()

        # ================= FRUIT SLASHER (the rework) =================
        var s: GogaGame = load("res://game/games/slasher/slasher.gd").new()
        s.game_id = "slasher"
        add_child(s)
        await get_tree().create_timer(0.5).timeout
        await _shot(OUT + "03_slasher_position_ask.png")
        s._orient_choice("vertical")
        await get_tree().create_timer(0.2).timeout
        await _shot(OUT + "04_slasher_options.png")
        Box.dev_set_cheat("all_owned", 1)
        s._show_options()
        await get_tree().create_timer(0.2).timeout
        await _shot(OUT + "05_slasher_options_veg_toggle.png")
        s._start_run()
        await get_tree().create_timer(1.4).timeout
        await _shot(OUT + "06_slasher_fruits_flying.png")
        # a slice: force a fruit + cut it through the middle
        s.items.clear()
        var apple := Sprite2D.new()
        apple.texture = s._texs["apple"]
        apple.position = Vector2(360, 500)
        apple.scale = Vector2.ONE * 0.52
        s.world.add_child(apple)
        s.items.append({"node": apple, "kind": "apple", "v": Vector2(0, -80),
                "spin": 0.6, "sliced": false, "scale": 0.52, "g": 1560.0})
        s.trail.append({"pos": Vector2(250, 560), "age": 0.0})
        s.trail.append({"pos": Vector2(470, 440), "age": 0.0})
        s.set_score(0)
        s._cut_item(s.items[0], Vector2(250, 560), Vector2(470, 440))
        s._push_viz("+1", Color(0.45, 0.95, 0.55), 0)
        s._push_viz("-2", Color(0.98, 0.42, 0.36), 1)
        await get_tree().create_timer(0.12).timeout
        await _shot(OUT + "07_slasher_slice_halves_juice.png")
        await get_tree().create_timer(0.5).timeout
        # a bomb slash: the hearts drop + the shake
        var hearts_before: int = int(s.hearts)
        s._bomb_slashed(Vector2(360, 400))
        await get_tree().create_timer(0.25).timeout
        await _shot(OUT + "08_slasher_bomb_heart_lost.png")
        print("[qa] hearts: %d -> %d" % [hearts_before, int(s.hearts)])
        print("[qa] done")
        get_tree().quit(0)

func _ready() -> void:
        _run.call_deferred()
