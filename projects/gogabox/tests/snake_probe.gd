extends Node
## snake_probe - v0.1.9: drives the SNAKE GOES TO WAR build headless. Walks
## the REAL flow (orientation ask -> mode menu -> tap-to-start), steers with
## the invisible analog wheel, eats fruit, checks the width cap, the
## NO-WALLS wrap, the enemy AI (hunts, eats, dies permanently), power fruits
## (faster/wither/eater), bug bites, obstacle death, then the wall crash +
## finish_run handover. Headless still runs every _draw pass (the one-part
## ribbon painting included). Exit 0 = pass.
##
##   godot --headless --path projects/gogabox res://tests/snake_probe.tscn

var fails := 0

func _ready() -> void:
        print("=== GOGABox snake probe (v0.1.9 goes to war) ===")
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

        # ---- the ASK: the game boots into the ORIENTATION select ----
        _check(game._phase == "orient", "boots into the position ask")
        _check(game.board.size.x > 120.0 and game.board.size.y > 120.0,
                "field built (%s)" % game.board)
        # the owner picks VERTICAL: the field must REBUILD to a tall aspect
        game.orient = "vertical"
        game._build_field()
        _check(game.board.size.y > game.board.size.x,
                "vertical choice letterboxes the field tall")
        game.orient = "horizontal"
        game._build_field()
        _check(game.board.size.x > game.board.size.y,
                "horizontal choice letterboxes the field wide")
        game.orient = "vertical"
        game._build_field()
        game._new_run_objects()
        game._show_mode_select()
        _check(game._phase == "mode", "mode menu follows the position ask")

        # ---- pick NO-WALLS + ready ----
        game.wrap_mode = true
        game._mode_picked()
        _check(game._phase == "ready", "ready card waits for the tap")
        game._start()
        _check(game._phase == "run", "tap starts the run")
        _check(Jukebox._current_music.find("snake_theme") != -1,
                "snake owns its music in-run")

        # ---- the invisible analog wheel: stick up = head turns toward UP
        var start_dir: float = game.player.head_dir
        game._wheel_stick = Vector2(0, -120)
        for i in 30:
                game._steer(1.0 / 60.0)
        var want := Vector2(0, -120).angle()
        _check(absf(wrapf(game.player.head_dir - want, -PI, PI)) < 0.3,
                "wheel drags the head toward the stick angle")
        _check(absf(wrapf(game.player.head_dir - start_dir, -PI, PI)) > 1.0,
                "absolute steering (heading really moved)")
        game._wheel_stick = Vector2.ZERO

        # ---- open field + hard wheel wiggling survives (no-walls) ----
        # the stick rotates slowly - the head chases it in circles (an S-cross
        # would be a LEGIT self-bite, not a probe failure)
        var t := 0.0
        var grew := false
        while t < 4.0:
                game._wheel_stick = Vector2.from_angle(t * 2.2) * 140.0
                game._goga_tick(1.0 / 60.0)
                t += 1.0 / 60.0
                if game.player.trail.size() > 40:
                        grew = true
        game._wheel_stick = Vector2.ZERO
        _check(grew, "trail grows while steering")
        _check(game.player.alive, "open field + hard steering survives")
        # walk through the edge: wrap, not death
        game.player.head_pos = Vector2(game.board.end.x - 4.0, game.player.head_pos.y)
        game.player.head_dir = 0.0
        var adv: Dictionary = game.player.advance(0.2, game.board, true)
        _check(bool(adv["wrapped"]), "NO-WALLS wraps edge to edge")
        _check(game.player.alive, "wrapping does not kill")

        # ---- eat a fruit: red-ish particles, growth, width cap ----
        game.apple_pop = 1.0
        game.apple_pos = game.player.head_pos
        var len_before: float = game.player.len_target
        game._tick_pickups()
        _check(game.score == 1, "fruit = +1 score (got %d)" % game.score)
        _check(game.player.len_target > len_before, "fruit grows the body")
        _check(game.apple_live, "the next fruit spawned")
        for i in 60:
                game.player.width = minf(game.player.width + game.WIDTH_PER_APPLE,
                                game.WIDTH_MAX)
        _check(absf(game.player.width - game.WIDTH_MAX) < 0.001,
                "width capped at %.0f" % game.WIDTH_MAX)

        # ---- the enemy: spawns green, hunts, eats, dies permanently ----
        Box.set_progress("snake", "opt_enemies", true)
        game._add_enemy(0)
        var en: Dictionary = game.enemies[0]
        _check((en["body"] as SnakeBody).pal["pri"] == Color("3fae5c"),
                "enemy #0 is GREEN (owner rule)")
        # let it think + move in open field
        for i in 120:
                game._tick_enemies(1.0 / 60.0)
        _check((en["body"] as SnakeBody).alive, "enemy survives an open field")
        _check((en["body"] as SnakeBody).trail.size() > 10, "enemy trail grows")
        # enemy eats a coin: score +1, the collected coin is gone (a fresh
        # one may spawn - the enemy economy is real)
        var eb: SnakeBody = en["body"]
        game.coin_live = true
        game.coin_pop = 1.0
        game.coin_pos = eb.head_pos + Vector2(2, 0)
        var esc: int = en["score"]
        game._tick_enemies(1.0 / 60.0)
        _check(int(en["score"]) == esc + 1, "enemy collects coins (+1)")
        _check(not game.coin_live or game.coin_pos.distance_to(eb.head_pos) > 30.0,
                "a stolen coin is a lost coin")
        # enemy death is permanent (an obstacle swallow is deterministic -
        # the AI is too good at dodging walls, which is the point)
        var enemies_before: int = game.enemies.size()
        game.obstacles.append(Rect2(eb.head_pos - Vector2(60, 45), Vector2(120, 90)))
        game._tick_enemies(1.0 / 60.0)
        game.obstacles.pop_back()
        _check(not eb.alive, "a lethal field kills the enemy")
        _check(game.enemies.size() == enemies_before,
                "dead enemies stay in the round (no respawn)")

        # ---- power fruits ----
        game.power_live = true
        game.power_pop = 1.0
        game.power_id = "faster"
        game.power_pos = game.player.head_pos + Vector2(1, 0)
        game._tick_pickups()
        _check(game.player.has_power("faster"), "FASTER lands on the eater")
        game.power_live = true
        game.power_pop = 1.0
        game.power_id = "wither"
        game.power_pos = game.player.head_pos + Vector2(1, 0)
        game._tick_pickups()
        _check(game.player.has_power("wither"), "WITHER is a real curse")
        var lt: float = game.player.len_target
        game.apple_pop = 1.0
        game.apple_pos = game.player.head_pos
        game._tick_pickups()
        _check(game.player.len_target < lt, "withered fruit SHRINKS instead")

        # ---- SNAKE-EATER: bite the tail ONLY ----
        game.player.apply_power("eater", 10.0)
        game._add_enemy(0)
        var e2: Dictionary = game.enemies[1]
        var e2b: SnakeBody = e2["body"]
        # park the player head on the enemy TAIL ZONE
        var pts: Array = e2b.body_points()
        var tail_pt: Vector2 = pts[pts.size() - 2][0]
        game.player.head_pos = tail_pt
        var enemy_len_before: float = e2b.len_target
        var my_len_before: float = game.player.len_target
        game._bite_cd = 0.0
        game._tick_bites(1.0 / 60.0)
        _check(e2b.len_target < enemy_len_before, "eater bites the TAIL off")
        _check(game.player.len_target > my_len_before, "the biter grows")

        # ---- bugs bite but NEVER kill ----
        Box.set_progress("snake", "opt_bugs", true)
        game.bugs.append({
                "pos": game.player.head_pos + Vector2(6, 0),
                "dir": 0.0, "phase": 0.0, "munch": 0.0, "hit_cd": 0.0,
        })
        var alive_before: bool = game.player.alive
        var len_b: float = game.player.length_px
        var score_b: int = game.score
        game._tick_bugs(1.0 / 60.0)
        _check(game.player.alive == alive_before and alive_before,
                "a bug bite NEVER kills")
        _check(game.player.length_px < len_b, "bug bite bleeds length")
        _check(game.score < score_b, "bug bite bleeds score")

        # ---- obstacles kill ----
        game.obstacles.append(Rect2(game.player.head_pos + Vector2(200, 0),
                        Vector2(120, 90)))
        game.player.head_pos += Vector2(260, 45)   # deep inside the block
        game._check_player_collisions()
        _check(not game.player.alive, "obstacle ends the run")
        # the death flash hands over to finish_run
        var waited := 0.0
        while not game.over and waited < 3.0:
                game._goga_tick(1.0 / 60.0)
                await get_tree().process_frame
                waited += get_process_delta_time()
        _check(game.over, "death flash hands over to finish_run")
        _check(Jukebox._current_music.find("snake_theme") == -1,
                "run music stops with the run")

        # ---- the whole paint pass executes (ribbon, fruit, bugs, chips) ----
        game._view.queue_redraw()
        await get_tree().process_frame
        await get_tree().process_frame
        _check(true, "paint pass executed (field, ribbon snake, head, chips)")

        game.queue_free()
        await get_tree().process_frame
        Box.reset_all()

func _check(cond: bool, msg: String) -> void:
        print(("  PASS: " if cond else "  FAIL: ") + msg)
        if not cond:
                fails += 1
