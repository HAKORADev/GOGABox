extends Node
## qa_v030 - the v0.3.0 visual QA (the owner's rule: LOOK before shipping).
## XO: the pre-rendered brush marks. Slasher: the wood board, the classic
## fruits, the REAL halves mid-flight, the juice splats, the +1 float, the
## explosion. Run under Xvfb:
##   DISPLAY=:99 godot --path . res://tests/qa_v030.tscn

const OUT := "/home/z/my-project/download/qa_v030/"

func _shot(path: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        get_viewport().get_texture().get_image().save_png(path)
        print("[qa] ", path)

func _run() -> void:
        DirAccess.make_dir_recursive_absolute(OUT)
        Box.reset_all()

        # ================= XO =================
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
        await _shot(OUT + "01_xo_brush_marks.png")
        x.queue_free()

        # ================= FRUIT SLASHER =================
        var s: GogaGame = load("res://game/games/slasher/slasher.gd").new()
        s.game_id = "slasher"
        add_child(s)
        await get_tree().create_timer(0.5).timeout
        await _shot(OUT + "02_slasher_ask_clean.png")
        s._orient_choice("vertical")
        await get_tree().create_timer(0.2).timeout
        s._start_run()
        await get_tree().create_timer(1.5).timeout
        await _shot(OUT + "03_slasher_wood_fruits.png")
        # a slice mid-action: an apple cut through, halves + juice + +1
        s.items.clear()
        var ap := Sprite2D.new()
        ap.texture = s._texs["apple"]
        ap.position = Vector2(360, 520)
        ap.scale = Vector2.ONE * s._item_scale("apple", s._texs["apple"])
        s.world.add_child(ap)
        s.items.append({"node": ap, "kind": "apple", "v": Vector2(0, -60),
                "spin": 0.4, "sliced": false,
                "scale": s._item_scale("apple", s._texs["apple"]), "g": 1560.0})
        s.set_score(0)
        s._cut_item(s.items[0], Vector2(250, 580), Vector2(470, 460))
        await get_tree().create_timer(0.10).timeout
        await _shot(OUT + "04_slasher_real_slice.png")
        await get_tree().create_timer(0.8).timeout
        await _shot(OUT + "05_slasher_splat_stays.png")
        # the bomb explosion
        s._bomb_slashed(Vector2(360, 420))
        await get_tree().create_timer(0.22).timeout
        await _shot(OUT + "06_slasher_explosion.png")
        print("[qa] hearts after bomb: %d" % int(s.hearts))
        print("[qa] done")
        get_tree().quit(0)

func _ready() -> void:
        _run.call_deferred()
