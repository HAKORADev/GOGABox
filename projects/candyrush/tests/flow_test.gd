extends Node
## Headless integration test for Candy Rush.
## Run: godot --headless --path . res://tests/flow_test.tscn
## Exits 0 on success, 1 on any failure.

var fails := 0

func _ready() -> void:
        # fresh save file so results are deterministic
        if FileAccess.file_exists("user://save.json"):
                DirAccess.remove_absolute(ProjectSettings.globalize_path("user://save.json"))
        GameState.reset()

        fails += _test("board: deterministic setup", _t_determinism)
        fails += _test("board: 30 seeds valid deals", _t_valid_deals)
        fails += _test("board: hint swaps resolve", _t_hint_swaps)
        fails += _test("board: 5-match spawns color bomb", _t_bomb_spawn)
        fails += _test("board: 4-match spawns striped", _t_striped_spawn)
        fails += _test("board: bomb color-clear swap", _t_bomb_swap)
        fails += _test("board: shuffle stays playable", _t_shuffle)
        fails += _test("board: 200-move fuzz x5 seeds", _t_fuzz)
        fails += _test("levels: endless curve sane", _t_levels)
        fails += _test("skins: catalog + textures", _t_skins)
        fails += _test("state: coins/skins roundtrip", _t_state)
        fails += _test("sfx: all sounds load+play", _t_sfx)
        fails += _test("ads: desktop sim rewarded+interstitial", await _t_ads())
        fails += _test("scene: boot + win + lose overlays", await _t_scene())

        if fails == 0:
                print("RESULT: ALL TESTS PASSED")
        else:
                print("RESULT: %d FAILURE(S)" % fails)
        get_tree().quit(1 if fails > 0 else 0)

func _test(name_: String, fn: Variant) -> int:
        var result: int = 1
        if fn is int:
                result = fn
        elif fn is Callable:
                var r: Variant = fn.call()
                result = int(r) if r is int else 1
        if result == 0:
                print("  PASS: " + name_)
        else:
                print("  FAIL: " + name_)
        return result

func _check(cond: bool, why := "") -> int:
        if not cond and why != "":
                print("    assert failed: " + why)
        return 0 if cond else 1

func _grid_ok(b: MatchBoard) -> int:
        var ok := 0
        for x in MatchBoard.W:
                for y in MatchBoard.H:
                        var c: Dictionary = b.grid[x][y]
                        var t_ok: bool = int(c["t"]) >= 0 or int(c["s"]) == MatchBoard.SP_BOMB
                        ok += _check(t_ok, "cell %d,%d type %s" % [x, y, str(c)])
        return ok

# ---------------------------------------------------------------------------

func _t_determinism() -> int:
        var a := MatchBoard.new()
        var b2 := MatchBoard.new()
        a.setup(1234)
        b2.setup(1234)
        var same := true
        for x in MatchBoard.W:
                for y in MatchBoard.H:
                        if a.grid[x][y]["t"] != b2.grid[x][y]["t"]:
                                same = false
        return _check(same, "same seed must give same board")

func _t_valid_deals() -> int:
        var ok := 0
        for seed_v in range(1, 31):
                var b := MatchBoard.new()
                b.setup(seed_v * 7919)
                ok += _grid_ok(b)
                ok += _check(b.find_hint() != null, "seed %d must have a move" % seed_v)
                # no initial 3-matches
                ok += _check(b._find_matches().is_empty(), "seed %d must not start matched" % seed_v)
        return ok

func _t_hint_swaps() -> int:
        var ok := 0
        for seed_v in range(1, 11):
                var b := MatchBoard.new()
                b.setup(seed_v * 104729)
                var hint: Variant = b.find_hint()
                ok += _check(hint != null, "seed %d hint" % seed_v)
                var res: Dictionary = b.try_swap(hint[0], hint[1])
                ok += _check(not res.is_empty(), "hint swap must resolve")
                ok += _grid_ok(b)
                ok += _check(int(res["score"]) > 0, "score positive")
                ok += _check(res["waves"].size() >= 1, "at least one wave")
        return ok

func _seeded_board(seed_v: int) -> MatchBoard:
        var b := MatchBoard.new()
        b.setup(seed_v)
        return b

func _t_bomb_spawn() -> int:
        var b := _seeded_board(42)
        # neutral pattern with no 3-runs
        for x in MatchBoard.W:
                for y in MatchBoard.H:
                        b.grid[x][y] = {"t": (x + 2 * y) % 5, "s": MatchBoard.SP_NONE}
        # four type-2 pieces in a row, 5th comes from the swap
        for x in range(0, 4):
                b.grid[x][4] = {"t": 2, "s": MatchBoard.SP_NONE}
        b.grid[4][3] = {"t": 2, "s": MatchBoard.SP_NONE}
        b.grid[4][4] = {"t": 1, "s": MatchBoard.SP_NONE}
        var res: Dictionary = b.try_swap(Vector2i(4, 3), Vector2i(4, 4))
        if _check(not res.is_empty(), "5-match swap must resolve"):
                return 1
        var found_bomb := false
        for w in res["waves"]:
                for sp in w["spawned"]:
                        if sp["c"]["s"] == MatchBoard.SP_BOMB:
                                found_bomb = true
        return _check(found_bomb, "straight 5-match must spawn a color bomb")

func _t_striped_spawn() -> int:
        var b := _seeded_board(77)
        for x in MatchBoard.W:
                for y in MatchBoard.H:
                        b.grid[x][y] = {"t": (x + 2 * y) % 5, "s": MatchBoard.SP_NONE}
        for x in range(0, 3):
                b.grid[x][4] = {"t": 2, "s": MatchBoard.SP_NONE}
        b.grid[3][3] = {"t": 2, "s": MatchBoard.SP_NONE}
        b.grid[3][4] = {"t": 1, "s": MatchBoard.SP_NONE}
        b.grid[4][4] = {"t": 0, "s": MatchBoard.SP_NONE}  # break the accidental 5-run
        var res: Dictionary = b.try_swap(Vector2i(3, 3), Vector2i(3, 4))
        if _check(not res.is_empty(), "4-match swap must resolve"):
                return 1
        var found := false
        for w in res["waves"]:
                for sp in w["spawned"]:
                        if sp["c"]["s"] in [MatchBoard.SP_H, MatchBoard.SP_V]:
                                found = true
        return _check(found, "4-match must spawn a striped piece")

func _t_bomb_swap() -> int:
        var b := _seeded_board(99)
        for x in MatchBoard.W:
                for y in MatchBoard.H:
                        b.grid[x][y] = {"t": (x + 2 * y) % 5, "s": MatchBoard.SP_NONE}
        b.grid[3][3] = {"t": -1, "s": MatchBoard.SP_BOMB}
        var count_before := 0
        for x in MatchBoard.W:
                for y in MatchBoard.H:
                        if b.grid[x][y]["t"] == 4:
                                count_before += 1
        if _check(count_before > 0, "need at least one type-4 on board"):
                return 1
        var res: Dictionary = b.try_swap(Vector2i(3, 3), Vector2i(4, 3))
        if _check(not res.is_empty(), "bomb swap must be valid"):
                return 1
        var cleared: int = res["waves"][0]["cleared"].size()
        return _check(cleared >= count_before, "bomb must clear all of the color (%d vs %d)" % [cleared, count_before])

func _t_shuffle() -> int:
        var ok := 0
        for seed_v in range(1, 11):
                var b := _seeded_board(seed_v * 31337)
                var res: Dictionary = b.shuffle()
                ok += _check(res.has("moved"), "shuffle returns moved list")
                ok += _grid_ok(b)
                ok += _check(b._find_matches().is_empty(), "shuffled board must not start matched")
                ok += _check(b.find_hint() != null, "shuffled board must have a move")
        return ok

func _t_fuzz() -> int:
        var ok := 0
        var swaps_done := 0
        for seed_v in range(1, 6):
                var b := _seeded_board(seed_v * 99991)
                var rng := RandomNumberGenerator.new()
                rng.seed = seed_v
                var made := 0
                for i in 200:
                        var a := Vector2i(rng.randi_range(0, 7), rng.randi_range(0, 7))
                        var dirs := [Vector2i(1, 0), Vector2i(0, 1)]
                        var d: Vector2i = dirs[rng.randi_range(0, 1)]
                        var v: Vector2i = a + d
                        if not MatchBoard.in_bounds(v):
                                continue
                        var res: Dictionary = b.try_swap(a, v)
                        if res.is_empty():
                                continue
                        made += 1
                        ok += _grid_ok(b)
                        if made >= 40:
                                break
                ok += _check(made > 0, "seed %d: fuzz must find legal swaps" % seed_v)
                swaps_done += made
        print("    fuzz swaps resolved: ", swaps_done)
        return ok

func _t_levels() -> int:
        var ok := 0
        var prev_target := 0
        for lv in range(1, 61):
                var t := Levels.target_for(lv)
                ok += _check(t > prev_target, "target must grow (level %d)" % lv)
                ok += _check(Levels.moves_for(lv) >= 15, "moves floor")
                prev_target = t
        var moves_seq: Array = []
        for lv in range(1, 41):
                moves_seq.append(Levels.moves_for(lv))
        ok += _check(Levels.moves_for(1) == 22 and Levels.moves_for(6) == 21, "moves ramp")
        ok += _check(Levels.stars_for(999, 1000) == 0, "0 stars below target")
        ok += _check(Levels.stars_for(1000, 1000) == 1, "1 star at target")
        ok += _check(Levels.stars_for(1400, 1000) == 2, "2 stars at 1.4x")
        ok += _check(Levels.stars_for(1900, 1000) == 3, "3 stars at 1.9x")
        ok += _check(Levels.coins_for(3) == 55, "coins for 3 stars")
        return ok

func _t_skins() -> int:
        var ok := _check(Skins.SKINS.size() == 4, "4 skins")
        for s in Skins.SKINS:
                for i in 5:
                        var p := "res://assets/sprites/%s/%s%d.png" % [s["dir"], s["prefix"], i]
                        ok += _check(ResourceLoader.exists(p), "missing piece " + p)
                ok += _check(ResourceLoader.exists(s["bg"]), "missing bg for " + str(s["id"]))
        var tex := Skins.base_texture(Skins.get_skin("candy"), 0)
        ok += _check(tex != null, "candy base_0 loads")
        ok += _check(Skins.striped_texture(Skins.get_skin("candy"), 0, true) != null, "candy has real striped sprites")
        ok += _check(Skins.striped_texture(Skins.get_skin("gems"), 0, true) == null, "gems use overlay stripes")
        return ok

func _t_state() -> int:
        var ok := 0
        GameState.data["coins"] = 0
        GameState.add_coins(500)
        ok += _check(GameState.coins() == 500, "add coins")
        ok += _check(not GameState.owns("gems"), "gems not owned initially")
        ok += _check(not GameState.buy("gems", 600), "cannot buy without coins")
        GameState.add_coins(200)
        ok += _check(GameState.buy("gems", 700), "buy with enough coins")
        ok += _check(GameState.owns("gems") and GameState.skin() == "gems", "buy equips")
        ok += _check(GameState.coins() == 0, "coins spent")
        GameState.complete_level(1, 2000, 2)
        ok += _check(GameState.level() == 2, "level advances")
        GameState.complete_level(1, 2000, 2)
        ok += _check(GameState.level() == 2, "replaying old level does not advance")
        GameState.data["coins"] = 0
        GameState.data["skin"] = "candy"
        GameState.data["owned"] = ["candy"]
        GameState.save()
        return ok

func _t_sfx() -> int:
        for key in Sfx.SOUNDS:
                Sfx.play(key, -8.0)
        Sfx.pop(2)
        Sfx.ensure_music()
        return 0

func _t_ads() -> int:
        var ok := 0
        if not Ads.desktop_sim:
                print("    (on Android - skipping sim assertions)")
                return 0
        Ads.register_run()
        var rewarded_result := [false]
        Ads.show_rewarded(func(watched: bool): rewarded_result[0] = watched)
        await get_tree().create_timer(1.5).timeout
        ok += _check(rewarded_result[0], "desktop rewarded sim must return watched=true")
        var inter_result := [false]
        Ads.maybe_interstitial(func(shown: bool): inter_result[0] = true)
        await get_tree().create_timer(1.5).timeout
        ok += _check(inter_result[0], "desktop interstitial sim must call back")
        Ads.banner_show()
        Ads.banner_hide()
        return ok

func _t_scene() -> int:
        var main: Node = load("res://game/main.tscn").instantiate()
        add_child(main)
        await get_tree().process_frame
        await get_tree().process_frame
        await get_tree().create_timer(0.5).timeout
        # find the live match3 screen (menu -> press play is UI-driven; switch directly)
        main._switch(1)
        await get_tree().create_timer(1.6).timeout  # deal animation
        var m3: Node = main._screen
        var ok := _check(m3 != null and m3.get("board") != null, "game screen alive")
        if m3 == null:
                main.queue_free()
                return ok
        # play one hint swap through the view layer
        var hint: Variant = m3.board.find_hint()
        if hint != null:
                await m3._try_swap(hint[0], hint[1])
                ok += _check(m3.moves_left >= 0, "move consumed or level ended")
        # force a win overlay
        m3.score = m3.target
        m3.moves_left = maxi(m3.moves_left, 1)
        m3._after_action()
        ok += _check(m3.over, "win path ends level")
        # force a lose overlay on a fresh screen
        main._switch(1)
        await get_tree().create_timer(1.6).timeout
        var m3b: Node = main._screen
        m3b.score = 0
        m3b.moves_left = 0
        m3b._after_action()
        ok += _check(m3b.over, "lose path ends level")
        main.queue_free()
        await get_tree().process_frame
        return ok
