extends Node
## GOGABox flow test: core infra round-trips + every playable game boots,
## reports a run, and the economy lands in the store. Exit 0 = all green.

var fails := 0

func _ready() -> void:
        print("=== GOGABox flow test ===")
        fails += _test("store: wallet roundtrip", _t_wallet())
        fails += _test("store: unlocks + anti-softlock", _t_unlocks())
        fails += _test("store: stats/achievements/skins", _t_slots())
        fails += _test("registry: entries sane", _t_registry())
        fails += _test("host: launch + finish + economy", await _t_host_flow())
        fails += _test("games: all playable boot", await _t_all_games())
        print("RESULT: %s" % ("ALL TESTS PASSED" if fails == 0 else "%d FAILURES" % fails))
        get_tree().quit(0 if fails == 0 else 1)

func _test(name_: String, fn_result: int) -> int:
        print("  %s: %s" % ["PASS" if fn_result == 0 else "FAIL", name_])
        return fn_result

func _check(cond: bool, why := "") -> int:
        if not cond:
                print("    FAIL: " + why)
                return 1
        return 0

# ------------------------------------------------------------------ core

func _t_wallet() -> int:
        Box.reset_all()
        var ok := _check(Box.coins() == 150, "start wallet 150")
        Box.earn(50)
        ok += _check(Box.coins() == 200, "earn +50")
        ok += _check(Box.spend(30), "spend ok")
        ok += _check(Box.coins() == 170, "balance 170")
        ok += _check(not Box.spend(999999), "over-spend refused")
        return ok

func _t_unlocks() -> int:
        Box.reset_all()
        var ok := _check(Box.owns_game("snake"), "snake free starter")
        ok += _check(not Box.owns_game("rally"), "rally locked")
        # anti-softlock: wallet 150 < rally price, but snake fee 10 affordable
        ok += _check(Box.cheapest_owned_fee() == 10, "cheapest fee 10")
        ok += _check(Box.unlock_game("rally", 150), "unlock rally at exactly 150")
        ok += _check(Box.coins() == 0, "wallet drained")
        ok += _check(Box.cheapest_owned_fee() == 8, "cheapest now rally fee 8")
        # with 0 coins, cheapest fee 8 > wallet -> free play path is menu-side logic
        ok += _check(not Box.unlock_game("merge", 400), "merge refused at 0 coins")
        return ok

func _t_slots() -> int:
        Box.reset_all()
        Box.record_run("snake", 42)
        Box.record_run("snake", 17)
        var ok := _check(Box.stat("snake", "best") == 42, "best kept")
        ok += _check(Box.stat("snake", "last") == 17, "last updated")
        ok += _check(Box.stat("snake", "plays") == 2, "plays counted")
        Box.bump_counter("snake", "apples", 10)
        Box.bump_counter("snake", "apples", 5)
        ok += _check(Box.counter("snake", "apples") == 15, "counters add")
        ok += _check(not Box.has_achievement("snake", "a1"), "ach unset")
        ok += _check(Box.grant_achievement("snake", "a1"), "first grant true")
        ok += _check(not Box.grant_achievement("snake", "a1"), "second grant false")
        ok += _check(Box.buy_skin("snake", "gold", 300) == false, "skin refused (broke)")
        Box.earn(400)
        ok += _check(Box.buy_skin("snake", "gold", 300), "skin bought")
        ok += _check(Box.skin_on("snake") == "gold", "skin auto-equipped")
        Box.reset_game("snake")
        ok += _check(Box.stat("snake", "best") == 0 and Box.counter("snake", "apples") == 0,
                "reset_game wipes slot")
        ok += _check(Box.skin_on("snake") == "", "reset clears skins")
        return ok

func _t_registry() -> int:
        var ok := _check(GameReg.playable().size() == 6, "6 playable games")
        ok += _check(GameReg.hot().size() == 3, "3 hot games")
        var ok2 := true
        for g in GameReg.GAMES:
                if g.get("coming_soon", false):
                        continue
                var p := String(g["script"])
                ok2 = ok2 and ResourceLoader.exists(p)
                ok2 = ok2 and ResourceLoader.exists(String(g["thumb"]))
        ok += _check(ok2, "every playable game has script+thumb")
        ok += _check(GameReg.get_game("nope").is_empty(), "unknown game resolves empty")
        return ok

# ------------------------------------------------------------------ host flow

func _t_host_flow() -> int:
        Box.reset_all()
        var router := Node2D.new()
        add_child(router)
        var launched := false
        # snake is free-owned: launch should succeed without touching wallet
        var host_script: GDScript = load("res://game/core/game_host.gd")
        launched = host_script.launch(router, "snake")
        var ok := _check(launched, "snake launches")
        await get_tree().create_timer(0.5).timeout
        var host: Node = host_script.active_host
        ok += _check(host != null, "host alive")
        if host == null:
                return ok
        var game: Node = host.game
        ok += _check(game != null, "game node alive")
        # simulate a finished run through the game's public contract
        # note: launch charged snake's 10-coin entry fee (150 -> 140)
        game.set_score(37)
        game.add_run_coins(5)
        game.finish_run(37)
        await get_tree().create_timer(1.2).timeout
        ok += _check(Box.stat("snake", "best") == 37, "run recorded (best 37)")
        # conversion: 2 + 37/3 = 14, + run_coins 5 = 19 total earned
        ok += _check(Box.coins() == 150 - 10 + 19, "net wallet 159 -> %d" % Box.coins())
        ok += _check(Box.stat("snake", "plays") == 1, "plays 1")
        # quit path
        host._quit_to_menu()
        await get_tree().process_frame
        ok += _check(host_script.active_host == null, "host session ended")
        Box.reset_all()
        return ok

func _t_all_games() -> int:
        var ok := 0
        var host_script: GDScript = load("res://game/core/game_host.gd")
        # own everything so launch() passes
        Box.reset_all()
        Box.earn(100000)
        for g in GameReg.playable():
                if not Box.owns_game(String(g["id"])):
                        Box.unlock_game(String(g["id"]), 0)
        var router := Node2D.new()
        router.set_script(GDScript.new())
        add_child(router)
        for g in GameReg.playable():
                var id := String(g["id"])
                var fee := int(g["fee"])
                var before := Box.coins()
                var launched: bool = host_script.launch(router, id)
                ok += _check(launched, id + " launches")
                if not launched:
                        continue
                await get_tree().create_timer(0.35).timeout
                var host: Node = host_script.active_host
                ok += _check(host != null and host.game != null, id + " host+game alive")
                if host == null or host.game == null:
                        continue
                var expected := before - fee
                # landscape game flips content scale; make sure it restored later
                ok += _check(Box.coins() == expected,
                        id + " fee charged (%d -> %d, want %d)" % [before, Box.coins(), expected])
                # force-finish the run
                host.game.set_score(20)
                host.game.finish_run(20)
                await get_tree().create_timer(1.0).timeout
                ok += _check(Box.stat(id, "plays") == 1, id + " play recorded")
                host._quit_to_menu()
                await get_tree().process_frame
                ok += _check(get_window().content_scale_size == Vector2i(720, 1280),
                        id + " orientation restored to portrait")
        Box.reset_all()
        return ok
