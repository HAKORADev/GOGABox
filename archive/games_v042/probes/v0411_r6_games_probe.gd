extends Node
## v041-1 r6 THE GAMES PROBE - the owner's report worked to the bone, the
## game-specific half. Run headless:
##   GODOT_BIN --headless --path projects/gogabox res://tests/v0411_r6_games_probe.tscn
## THE LAWS UNDER TEST:
##   PONG   - THE SPACE-INVADERS LAW: the keys drive the paddle's POSITION
##            directly (constant speed, no ramp) and it STOPS DEAD on
##            release (the old follow-target glide lagged ~300px and kept
##            sliding after the key died - "sliding and not accurately
##            moving").
##   SNAKE  - THE LAND FOLLOWS THE FLAG: flipping survival ON rebuilds the
##            world into the big land AT TAP TIME (the checker read the
##            flag once at _ready - the big map never opened).
##            THE WALLS CARD STANDS: wall-less + survival = a big land with
##            NO walls (the r1 hard-edge override is dead).
##            THE OWN SIZE LAW: every feast fruit carries its own x1/x2/x3
##            size - respawns never resize the neighbors (they rode the
##            main apple's radius before).
##            THE HONEST x3 LAW: the ladder is AREA-honest (x1 / x2 / x3
##            the food) - the r1 x3.0 radius painted 9x the food.
##            THE GARDEN SENSE: the AI's candidates include the feast
##            fruits - enemies eat the NEARBY fruit (the feast was
##            invisible to them before).
##   MINER  - THE TIME-UP LAW: clock 0 loads the NEXT GROUND (the run ends
##            only at 0 lives).
##   BOVO   - THE SURVIVOR WIDTH LAW: the grid strokes ride the consts
##            that survive the desktop's sub-scale rendering.

var fails := 0
var _n := 0

func _check(name: String, ok: bool) -> void:
        _n += 1
        print(("PASS  " if ok else "FAIL  ") + name)
        if not ok:
                fails += 1

func _ready() -> void:
        call_deferred("_run")

func _run() -> void:
        print("== v041-1 r6 games probe ==")
        await _pong_law()
        await _snake_laws()
        await _miner_law()
        _bovo_law()
        print("== %d checks, %d fails ==" % [_n, fails])
        get_tree().quit(1 if fails > 0 else 0)

# ============================================================ PONG
func _pong_law() -> void:
        Box.reset_all()
        # the roadmap seats rally BEHIND snake - the dev cheat opens the gate
        Box.dev_set_cheat("all_owned", 1)
        var router := Node2D.new()
        add_child(router)
        var host_script: GDScript = load("res://game/core/game_host.gd")
        var launched: bool = host_script.launch(router, "rally")
        _check("pong: launches", launched)
        if not launched:
                return
        await get_tree().create_timer(3.0).timeout
        var host: Node = host_script.active_host
        _check("pong: alive", host != null and host.game != null)
        if host == null or host.game == null:
                host_script.end_session()
                return
        var game: Node = host.game
        if game.has_method("box_story_dismiss"):
                game.box_story_dismiss()
        var p: Dictionary = game.pads_by_id.get("user", {})
        _check("pong: the user pad rides the horizontal axis",
                not p.is_empty() and int(p["axis"]) == 0)
        if p.is_empty():
                host_script.end_session()
                return
        # seat the run honestly (the machine's own door: the ready card's go)
        game._phase = "run"
        game.serve_t = 0.0
        # seat the pad at the field center so the hold never touches a wall
        var center_x: float = (game.field as Rect2).get_center().x
        p["c"] = Vector2(center_x, (p["c"] as Vector2).y)
        # HOLD: constant speed - each tick moves the pad exactly the same
        # distance (4200 px/s = 70 px per tick), no glide ramp
        Input.action_press("ui_left")
        game._goga_tick(1.0 / 60.0)
        var xa: float = (p["c"] as Vector2).x
        game._goga_tick(1.0 / 60.0)
        var xb: float = (p["c"] as Vector2).x
        var da := center_x - xa
        var db := xa - xb
        _check("pong: hold moves the pad LEFT (%.1f + %.1f px)" % [da, db],
                da > 60.0 and db > 60.0)
        _check("pong: THE CONSTANT SPEED (no glide ramp: |d1-d2| = %.3f)"
                        % absf(da - db), absf(da - db) < 0.5)
        _check("pong: the follow target rides the pad (no glide fight)",
                ((p["follow"] as Vector2) - (p["c"] as Vector2)).length() < 0.5)
        # RELEASE: the pad STOPS DEAD (the owner's grid-slide complaint)
        Input.action_release("ui_left")
        var stopped_at: float = (p["c"] as Vector2).x
        for i in 10:
                game._goga_tick(1.0 / 60.0)
        _check("pong: release STOPS dead (no slide)",
                absf((p["c"] as Vector2).x - stopped_at) < 0.01)
        host_script.end_session()
        await get_tree().create_timer(0.4).timeout

# ============================================================ SNAKE
func _snake_laws() -> void:
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        Box.set_progress("snake", "enemy_count", 6)
        var router := Node2D.new()
        add_child(router)
        var host_script: GDScript = load("res://game/core/game_host.gd")
        var launched: bool = host_script.launch(router, "snake")
        _check("snake: launches", launched)
        if not launched:
                return
        await get_tree().create_timer(3.5).timeout
        var host: Node = host_script.active_host
        _check("snake: alive", host != null and host.game != null)
        if host == null or host.game == null:
                host_script.end_session()
                return
        var game: Node = host.game
        if game.has_method("box_story_dismiss"):
                game.box_story_dismiss()
        await get_tree().process_frame
        _check("snake: survival starts OFF on a fresh seat", not game.survival)
        var board0: Rect2 = game.board
        # THE LAND FOLLOWS THE FLAG - the toggle rebuilds the world
        game._toggle_survival()
        _check("snake: the toggle seat flips the flag", bool(game.survival))
        _check("snake: THE BIG LAND FORMS AT TAP TIME (x%.1f)" %
                        (game.board.size.x / maxf(1.0, board0.size.x)),
                game.board.size.x > board0.size.x * 3.0)
        _check("snake: the player re-seated inside the big land",
                game.board.has_point(game.player.head_pos))
        # THE WALLS CARD STANDS - wall-less survival = a wrap big land
        game.wrap_mode = true
        game._phase = "ready"
        game._start()
        _check("snake: WALL-LESS survival keeps the walls OFF",
                bool(game.wrap_mode) and bool(game.survival))
        _check("snake: the feast rides the wrap big land",
                game.extra_fruits.size() == 14)
        # THE OWN SIZE LAW + THE HONEST x3 LAW
        var ladder := [1.0, 1.41, 1.73]
        var own_sizes := true
        for f in game.extra_fruits:
                var sz := int(f.get("sz", 0))
                if sz < 1 or sz > 3 \
                                or absf(float(f["r"]) - 24.0 * ladder[sz - 1]) > 0.01:
                        own_sizes = false
        _check("snake: every feast fruit carries its OWN x1/x2/x3 radius",
                own_sizes)
        # THE GARDEN SENSE - the near fruit beats the far main apple
        var ai = (game.enemies[0]["ai"] as Object)
        var ebody = game.enemies[0]["body"]
        var head: Vector2 = ebody.head_pos
        var near_f: Dictionary = game.extra_fruits[0]
        near_f["pos"] = head + Vector2(160, 0)
        near_f["live"] = true
        near_f["pop"] = 1.0
        game.apple_pos = head + Vector2(2400, 0)
        game.apple_live = true
        var beh: Dictionary = ai._behavior(game.player_body())
        var want: Dictionary = ai._choose_target(game, game.player_body(), beh)
        var fruit_angle: float = (Vector2(head.x + 160, head.y) - head).angle()
        var got: float = float(want["angle"])
        var diff: float = absf(wrapf(got - fruit_angle, -PI, PI))
        _check("snake: THE GARDEN SENSE - the nearby fruit wins (angle err %.2f)"
                        % diff, diff < 0.3)
        host_script.end_session()
        await get_tree().create_timer(0.4).timeout

# ============================================================ GOLD MINER
func _miner_law() -> void:
        Box.reset_all()
        var game: Node = load("res://game/games/goldminer/goldminer.gd").new()
        game.game_id = "goldminer"
        game.set_process(false)
        add_child(game)
        await get_tree().process_frame
        await get_tree().process_frame
        if game.has_method("box_story_dismiss"):
                game.box_story_dismiss()
        game._intro_go()
        _check("miner: the run swings", game.phase == "swing")
        _check("miner: 3 lives at the gate", game.lives == 3)
        var level0: int = game.level
        # THE TIME-UP LAW: the clock dies mid-swing
        game.ground_clock = 0.01
        game._goga_tick(1.0 / 60.0)
        _check("miner: TIME'S UP lands the clear flow (phase clear)",
                game.phase == "clear")
        _check("miner: the run is NOT over", not bool(game.over))
        for i in 60:
                game._goga_tick(1.0 / 60.0)
        _check("miner: THE NEXT GROUND LOADS (level %d -> %d)"
                        % [level0, game.level], game.level == level0 + 1)
        _check("miner: the new ground is populated and swinging",
                game.items.size() >= 4 and game.phase == "swing")
        _check("miner: the clock re-priced for the new ground",
                game.ground_clock > 10.0)
        _check("miner: the lives never paid for the clock",
                game.lives == 3)
        game.queue_free()
        await get_tree().process_frame

# ============================================================ BOVO
func _bovo_law() -> void:
        var script: GDScript = load("res://game/games/bovo/bovo.gd")
        _check("bovo: THE SURVIVOR WIDTH LAW - the grid stroke is %s design px"
                        % script.GRID_LINE_W, float(script.GRID_LINE_W) >= 4.0)
        _check("bovo: the border stroke is %s design px"
                        % script.GRID_LINE_W_BORDER,
                float(script.GRID_LINE_W_BORDER) >= 5.5)
