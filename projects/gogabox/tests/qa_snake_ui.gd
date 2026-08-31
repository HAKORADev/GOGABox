extends Node
## qa_snake_ui - one-off visual QA: screenshots the snake's SELECT screens
## (position ask, mode+optionals, shop) and a running frame, at portrait
## resolution. Frames land in --out (default /tmp/snakeqa_ui).
##
##   godot --path . res://tests/qa_snake_ui.tscn ++ --out=/tmp/snakeqa_ui

var _out := "/tmp/snakeqa_ui"

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

func _run() -> void:
        Box.reset_all()
        var game: GogaGame = load("res://game/games/snake/snake.gd").new()
        game.game_id = "snake"
        add_child(game)
        await get_tree().create_timer(0.6).timeout
        await _shot("1_position_ask")
        # pick vertical through the REAL card handler
        game.orient = "vertical"
        game._build_field()
        game._new_run_objects()
        game._show_mode_select()
        await get_tree().create_timer(0.4).timeout
        await _shot("2_mode_optionals")
        game._mode_picked()
        await get_tree().create_timer(0.4).timeout
        await _shot("3_ready")
        # run a little with a wiggle so the body bends on camera
        game._start()
        for i in 240:
                game._wheel_stick = Vector2.from_angle(float(i) * 0.02) * 130.0
                await get_tree().process_frame
        game._wheel_stick = Vector2.ZERO
        await _shot("4_running")
        # the shop: fund the wallet first so nothing is grayed by poverty
        Box.earn(2000)
        game._shop_open()
        await get_tree().create_timer(0.5).timeout
        await _shot("5_shop")
        game._shop_close()
        Box.reset_all()
