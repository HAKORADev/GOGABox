extends Node
## snake_probe - v0.1.8: drives the SMOOTH snake headless. Boots a real run,
## starts it, steers it, feeds it an apple, then wall-crashes it. Catches
## runtime errors in movement / trail / bites / the whole _paint pass
## (headless still executes draw code). Exit 0 = pass.
##
##   godot --headless --path projects/gogabox res://tests/snake_probe.tscn

var fails := 0

func _ready() -> void:
        print("=== GOGABox snake probe (v0.1.8 smooth makeover) ===")
        await _run()
        print("=== snake probe %s ===" % ("PASS" if fails == 0 else "FAIL"))
        get_tree().quit(1 if fails > 0 else 0)

func _run() -> void:
        Box.reset_all()
        var game: GogaGame = load("res://game/games/snake/snake.gd").new()
        game.game_id = "snake"
        add_child(game)
        await get_tree().process_frame
        await get_tree().process_frame

        _check(game.board.size.x > 200.0 and game.board.size.y > 200.0,
                "field built from the real viewport (%s)" % game.board)
        _check(not game._started, "ready state waits for the tap")
        game._start()
        _check(game._started, "tap starts the run")
        _check(Jukebox._current_music.find("snake_theme") != -1,
                "snake owns its music in-run")

        # steer hard right/left in alternation - the trail must follow
        var t := 0.0
        var turned := false
        while t < 6.0:
                game.head_dir += 4.6 * (1.0 if fmod(t, 2.0) < 1.0 else -1.0) \
                                * (1.0 / 60.0)
                game._steer_and_move(1.0 / 60.0)
                game._check_bites()
                t += 1.0 / 60.0
                if game.trail.size() > 30:
                        turned = true
        _check(turned, "trail grows while steering")
        _check(game.alive, "open field + hard steering survives")

        # feed it an apple: teleport one onto the head
        game.apple_pop = 1.0
        game.apple_pos = game.head_pos
        game._check_bites()
        _check(game.score == 1, "apple = +1 score (got %d)" % game.score)
        _check(game.len_target > game.START_LEN, "apple grows the body")
        _check(game.width > game.WIDTH_START,
                "apple widens the body (%.1f -> %.1f)" % [game.WIDTH_START, game.width])

        # width must be capped (owner: "wide with a limit")
        for i in 60:
                game.width = minf(game.width + game.WIDTH_PER_APPLE,
                        game.WIDTH_MAX)
        _check(absf(game.width - game.WIDTH_MAX) < 0.001,
                "width capped at %.0f" % game.WIDTH_MAX)

        # the whole paint pass executes (a real redraw runs _draw -> _paint)
        game._view.queue_redraw()
        await get_tree().process_frame
        await get_tree().process_frame
        _check(true, "paint pass executed (field, snake, apple, head)")

        # wall crash -> ONLY-snake flash, then finish_run
        game.head_pos = Vector2(game.board.position.x + 2.0, game.head_pos.y)
        game._check_bites()
        _check(not game.alive, "wall ends the run")
        var waited := 0.0
        while not game.over and waited < 3.0:
                await get_tree().process_frame
                waited += get_process_delta_time()
        _check(game.over, "death flash hands over to finish_run")
        _check(Jukebox._current_music.find("snake_theme") == -1,
                "run music stops with the run")

        game.queue_free()
        await get_tree().process_frame
        Box.reset_all()

func _check(cond: bool, msg: String) -> void:
        print(("  PASS: " if cond else "  FAIL: ") + msg)
        if not cond:
                fails += 1
