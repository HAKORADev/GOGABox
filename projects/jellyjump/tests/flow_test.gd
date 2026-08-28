extends Node
## Headless integration test for JellyJump.
## Run:  godot --headless --path . res://tests/flow_test.tscn
## Exits 0 on success, 1 on any failure. Autoloads run normally in this mode.

var fails := 0

func _ready() -> void:
        # fresh save file so results are deterministic
        var save_path := ProjectSettings.globalize_path("user://save.json")
        if FileAccess.file_exists("user://save.json"):
                DirAccess.remove_absolute(save_path)
        GameState.load_save()

        fails += _test("save roundtrip", _t_save_roundtrip)
        fails += _test("skin buy/equip", _t_skins)
        fails += _test("daily streak", _t_daily)
        fails += _test("ads sim rewarded", await _t_ads_rewarded())
        fails += _test("ads pacing", await _t_ads_pacing())
        fails += _test("main scene boot + game over + revive", await _t_main_scene())

        if fails == 0:
                print("RESULT: ALL TESTS PASSED")
        else:
                print("RESULT: %d FAILURE(S)" % fails)
        get_tree().quit(1 if fails > 0 else 0)

func _test(name_: String, fn: Variant) -> int:
        # fn is a Callable returning 0/1 or an await-derived value
        var result: int = 1
        if fn is int:
                result = fn
        elif fn is Callable:
                result = fn.call()
        if result == 0:
                print("  PASS: " + name_)
        else:
                print("  FAIL: " + name_)
        return result

func _check(cond: bool, why := "") -> int:
        if not cond and why != "":
                print("    assert failed: " + why)
        return 0 if cond else 1

# ---------------------------------------------------------------------------

func _t_save_roundtrip() -> int:
        GameState.data["coins"] = 0
        GameState.add_coins(123)
        var ok := _check(GameState.coins() == 123, "add_coins in memory")
        GameState.save()
        ok += _check(FileAccess.file_exists("user://save.json"), "save file written")
        GameState.data["coins"] = 0
        GameState.load_save()
        ok += _check(GameState.coins() == 123, "coins after reload == 123, got %d" % GameState.coins())
        GameState.data["coins"] = 0
        GameState.save()
        return ok

func _t_skins() -> int:
        GameState.data["coins"] = 1000
        var bought := GameState.buy_skin("sky")
        var ok := _check(bought and GameState.owns("sky") and GameState.coins() == 850)
        ok += _check(GameState.skin()["id"] == "sky")  # buy auto-equips
        ok += _check(not GameState.buy_skin("sky"))     # already owned
        ok += _check(not GameState.buy_skin("cosmic"))  # too expensive (1200 > 850)
        GameState.data["coins"] = 0
        GameState.data["owned"] = ["mint"]
        GameState.data["skin"] = "mint"
        GameState.save()
        return ok

func _t_daily() -> int:
        # reset any persisted daily state so the test is deterministic
        GameState.data["daily_streak"] = 0
        GameState.data["last_daily"] = ""
        var reward: int = GameState.claim_daily()
        var ok := _check(reward > 0, "first claim should reward")
        ok += _check(GameState.claim_daily() == 0, "second claim same day must be 0")
        ok += _check(GameState.daily_streak() == 1, "streak should be 1")
        return ok

func _t_ads_rewarded() -> int:
        # desktop sim: rewarded always completes
        var got := [false]
        Ads.show_rewarded(func(ok: bool): got[0] = ok)
        await get_tree().create_timer(0.4).timeout
        return _check(got[0])

func _t_ads_pacing() -> int:
        var shown := [0]
        for i in int(Ads.cfg["interstitial_every_runs"]):
                Ads.register_run()
                Ads.maybe_interstitial(func(s: bool):
                        if s:
                                shown[0] += 1)
                await get_tree().create_timer(0.05).timeout
        # pacing resets after a show
        Ads.register_run()
        Ads.maybe_interstitial(func(_s: bool): pass)
        await get_tree().create_timer(0.6).timeout   # let the sim callback land
        return _check(shown[0] == 1, "exactly one interstitial within pacing window")

func _t_main_scene() -> int:
        var main: Node2D = (load("res://game/main.tscn") as PackedScene).instantiate()
        add_child(main)
        await get_tree().process_frame
        await get_tree().process_frame

        var ok := _check(main.state == "menu")
        ok += _check(main.ui.menu.visible)

        # start a run and generate platforms
        main._start_run()
        await get_tree().physics_frame
        await get_tree().physics_frame
        ok += _check(main.state == "playing")
        ok += _check(main.ui.hud.visible)
        var plat_count := 0
        for c in main.world.get_children():
                if c is JellyPlatform:
                        plat_count += 1
        ok += _check(plat_count >= 1)

        # force game over -> panel + coins banked
        main.coins_run = 7
        main.score = 42
        main._game_over()
        await get_tree().process_frame
        ok += _check(main.state == "gameover")
        ok += _check(main.ui.gameover.visible)
        ok += _check(GameState.coins() >= 7)
        ok += _check(GameState.best() >= 42)

        # simulated rewarded revive brings the run back
        main._on_revive()
        await get_tree().create_timer(0.5).timeout
        ok += _check(main.state == "playing")
        ok += _check(main.revived)

        main.queue_free()
        return ok
