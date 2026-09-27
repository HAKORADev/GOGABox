extends Node
## qa_v021 - visual QA for the v0.2.1 fixes: the collapse frames (the
## "thin ribbon + wandering dot" bug), the peace self-overlap flicker, the
## banana centering (hit circle vs drawing), and the closed tail cap.
##
##   godot --path . res://tests/qa_v021.tscn ++ --out=/tmp/snakeqa_v021

var _out := "/tmp/snakeqa_v021"

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

func _drag(g: GogaGame, from: Vector2, to: Vector2, idx: int) -> void:
        var d := InputEventScreenDrag.new()
        d.index = idx
        d.position = to
        d.relative = to - from
        g._goga_input(d)

func _touch(g: GogaGame, at: Vector2, pressed: bool, idx: int) -> void:
        var t := InputEventScreenTouch.new()
        t.index = idx
        t.position = at
        t.pressed = pressed
        g._goga_input(t)

func _run() -> void:
        Box.reset_all()
        var game: GogaGame = load("res://game/games/snake/snake.gd").new()
        game.game_id = "snake"
        add_child(game)
        await get_tree().create_timer(0.5).timeout
        # --- v0.2.1a: the ask listens to the WINDOW - a stale pref in the
        # save must NOT light the wrong card (the owner's hang repro) ---
        await _shot("ask_fresh_boot")
        var bogus := "horizontal" if game._auto_orient() == "vertical" \
                        else "vertical"
        Box.set_progress("snake", "orient_pref", bogus)
        var ga: GogaGame = load("res://game/games/snake/snake.gd").new()
        ga.game_id = "snake"
        add_child(ga)
        await get_tree().create_timer(0.5).timeout
        await _shot("ask_window_not_pref")
        ga._orient_choice(ga._auto_orient())   # the CURRENT shape: proceeds
        await get_tree().create_timer(0.3).timeout
        await _shot("ask_accepted_mode_menu")
        ga.queue_free()
        await get_tree().process_frame
        game._show_mode_select()
        game._show_ready_card()
        game._start()
        # --- a long snake, then THE COLLAPSE frames ---
        var p: SnakeBody = game.player
        p.len_target = 900.0
        p.length_px = 900.0
        p.head_pos = game.board.get_center()
        p.head_dir = 0.0
        p.trail.clear()
        p.trail_brk.clear()
        p.trail_warp.clear()
        p.setup(p.head_pos, 0.0, p.pal["pri"], p.pal["milk"])
        p.len_target = 900.0
        p.length_px = 900.0
        for i in 130:
                p.head_dir += 0.035
                p.advance(1.0 / 60.0, game.board, false)
                game._goga_tick(1.0 / 60.0)
        await _shot("collapse_0_alive")
        game._die()
        for k in 6:
                for i in 7:
                        game._goga_tick(1.0 / 60.0)
                if not game.over:
                        await _shot("collapse_%d" % (k + 1))
        var waited := 0.0
        while not game.over and waited < 3.0:
                game._goga_tick(1.0 / 60.0)
                await get_tree().process_frame
                waited += 1.0 / 60.0
        print("[qa] collapse finished, over=", game.over)
        # --- PEACE self-overlap frames ---
        var game2: GogaGame = load("res://game/games/snake/snake.gd").new()
        game2.game_id = "snake"
        add_child(game2)
        await get_tree().create_timer(0.5).timeout
        game2.peace = true
        game2.score_bonus_enabled = false
        game2._show_mode_select()
        game2._show_ready_card()
        game2._start()
        var p2: SnakeBody = game2.player
        p2.len_target = 700.0
        p2.length_px = 700.0
        for i in 190:
                p2.head_dir += 0.085
                game2._goga_tick(1.0 / 60.0)
                if i % 6 == 0 and i > 150:
                        await _shot("peace_self_%d" % i)
        print("[qa] peace alive=", p2.alive)
        # --- BANANA centered + tail cap close-up (in bounds, no wrap) ---
        var game3: GogaGame = load("res://game/games/snake/snake.gd").new()
        game3.game_id = "snake"
        add_child(game3)
        await get_tree().create_timer(0.5).timeout
        game3._show_mode_select()
        game3._show_ready_card()
        game3._start()
        game3.apple_live = false   # park the runner apple; place OUR banana
        game3.edible_id = "banana"
        game3.apple_pos = game3.board.get_center()
        game3.apple_live = true
        game3.apple_pop = 1.0
        var p3: SnakeBody = game3.player
        var c3: Vector2 = game3.board.get_center()
        p3.setup(c3 + Vector2(0, 150.0), -PI / 2.0, p3.pal["pri"], p3.pal["milk"])
        p3.len_target = 420.0
        p3.length_px = 420.0
        for i in 110:
                p3.head_dir -= 0.014   # a gentle arc that stays in bounds
                p3.advance(1.0 / 60.0, game3.board, false)
                game3._goga_tick(1.0 / 60.0)
        await _shot("banana_and_tail")
        Box.reset_all()
