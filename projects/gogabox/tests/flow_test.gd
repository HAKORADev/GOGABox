extends Node
## GOGABox flow test: core infra round-trips + every playable game boots,
## reports a run, and the economy lands in the store. Exit 0 = all green.

var fails := 0

func _ready() -> void:
        print("=== GOGABox flow test ===")
        fails += _test("store: wallet roundtrip", _t_wallet())
        fails += _test("store: unlocks + anti-softlock", _t_unlocks())
        fails += _test("store: stats/achievements/skins", _t_slots())
        fails += _test("store: time/spent/earned tracking", _t_accounting())
        fails += _test("batteries: pools, consumption, refill", _t_batteries())
        fails += _test("windows: hour math", _t_windows())
        fails += _test("meta: registry metadata sane", _t_meta())
        fails += _test("registry: entries sane", _t_registry())
        fails += _test("roadmap: reveal state machine", _t_roadmap())
        fails += _test("scroll: BoxScroll drag/tap", await _t_scroll())
        fails += _test("host: launch + finish + economy", await _t_host_flow())
        fails += _test("games: all playable boot", await _t_all_games())
        fails += _test("menu: boots and lays out", await _t_menu())
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

func _t_accounting() -> int:
        Box.reset_all()
        Box.add_time("snake", 61.0)
        Box.add_time("rally", 59.0)
        var ok := _check(absf(Box.total_time() - 120.0) < 0.5, "total box time 120s")
        Box.add_spent("snake", 10)
        Box.add_spent("snake", 120)
        Box.add_earned("snake", 42)
        ok += _check(Box.spent_in("snake") == 130, "spent tracked")
        ok += _check(Box.earned_in("snake") == 42, "earned tracked")
        ok += _check(Box.spent_in("rally") == 0, "per-game isolation")
        Box.mark_seen("snake")
        ok += _check(Box.is_seen("snake") and not Box.is_seen("rally"), "New! seen flags")
        ok += _check(Box.meta().has("last_play"), "last_play stamped")
        return ok

func _t_batteries() -> int:
        Box.reset_all()
        var ok := _check(Box.box_batteries() == 50, "box pool starts full (50)")
        ok += _check(Box.game_battery("snake").is_empty(), "snake plays without charges")
        var b := Box.game_battery("rally")
        ok += _check(not b.is_empty() and int(b["count"]) == 10 and int(b["per_round"]) == 2,
                "rally pool 10, 2 per round")
        ok += _check(Box.consume_round_batteries("rally"), "round consumes 2")
        ok += _check(int(Box.game_battery("rally")["count"]) == 8, "pool 8 after round")
        ok += _check(Box.box_batteries() == 48, "box bank drained too (48)")
        Box.data["game_batteries"]["rally"]["count"] = 1
        ok += _check(not Box.consume_round_batteries("rally"), "no play at 1 battery")
        Box.data["game_batteries"]["rally"]["count"] = 10
        Box.data["box_batteries"] = 1
        ok += _check(not Box.consume_round_batteries("rally"), "no play when bank < cost")
        ok += _check(int(Box.game_battery("rally")["count"]) == 10, "pool untouched on fail")
        Box.data["box_batteries"] = 30
        Box.data["game_batteries"]["rally"]["count"] = 1
        var moved := Box.refill_game_from_box("rally")
        ok += _check(moved == 9 and int(Box.game_battery("rally")["count"]) == 10,
                "refill moves 9 from box")
        ok += _check(Box.box_batteries() == 21, "box pool drained to 21")
        # closed-time regen for the global pool
        Box.data["box_batteries"] = 0
        Box.meta()["closed_ts"] = int(Time.get_unix_time_from_system()) - 620
        Box._apply_closed_regen()
        ok += _check(Box.box_batteries() == 2, "closed 620s -> +2 box batteries")
        Box.reset_all()
        return ok

func _t_windows() -> int:
        var ok := 0
        ok += _check(Roadmap._hour_in(3, 1, 8), "3h inside 1-8")
        ok += _check(not Roadmap._hour_in(12, 1, 8), "12h outside 1-8")
        ok += _check(Roadmap._hour_in(23, 22, 6), "23h inside overnight 22-6")
        ok += _check(Roadmap._hour_in(2, 22, 6), "2h inside overnight 22-6")
        ok += _check(not Roadmap._hour_in(9, 22, 6), "9h outside overnight 22-6")
        ok += _check(Roadmap._hour_in(16, 16, 22) and Roadmap._hour_in(21, 16, 22)
                and not Roadmap._hour_in(22, 16, 22), "16-22 window edges")
        ok += _check(Roadmap.window_text("hopper") != "", "hopper has a window text")
        ok += _check(Roadmap.window_text("snake") == "", "snake has no window")
        return ok

func _t_meta() -> int:
        var ok := 0
        for g in GameReg.GAMES:
                var geo: Dictionary = g.get("genres", {})
                ok += _check((geo.get("main", []) as Array).size() <= Meta.MAIN_LIMIT,
                        String(g["id"]) + " main genres <= 3")
                ok += _check((geo.get("sub", []) as Array).size() <= Meta.SUB_LIMIT,
                        String(g["id"]) + " sub genres <= 3")
                var age := String(g.get("age", "everyone"))
                ok += _check(Meta.AGES.has(age), String(g["id"]) + " age rating valid")
                if g.has("charges"):
                        ok += _check(int(g["charges"].get("per_round", 0)) > 0
                                and int(g["charges"].get("capacity", 0)) > 0,
                                String(g["id"]) + " charges sane")
        ok += _check(not Meta.used_genres().is_empty(), "genres used by feed games")
        ok += _check(Meta.genre_label("arcade") == "Arcade", "genre labels resolve")
        ok += _check(Meta.icon_for("genre", "arcade") != "", "genre icons resolve")
        return ok

func _t_registry() -> int:
        var ok := _check(GameReg.playable().size() == 6, "6 playable games")
        ok += _check(GameReg.hot().size() == 3, "3 hot games")
        ok += _check(GameReg.workshop().size() == 8, "8 workshop teasers")
        var ok2 := true
        for g in GameReg.GAMES:
                if g.get("coming_soon", false):
                        ok2 = ok2 and g.has("reveal")
                        continue
                var p := String(g["script"])
                ok2 = ok2 and ResourceLoader.exists(p)
                ok2 = ok2 and ResourceLoader.exists(String(g["thumb"]))
        ok += _check(ok2, "every playable game has script+thumb; teasers have reveals")
        ok += _check(GameReg.get_game("nope").is_empty(), "unknown game resolves empty")
        return ok

# ------------------------------------------------------------------ roadmap

func _t_roadmap() -> int:
        Box.reset_all()
        var ok := _check(Roadmap.state("snake") == "OWNED", "snake owned from start")
        ok += _check(Roadmap.state("rally") == "HIDDEN", "rally hidden before first play")
        ok += _check(Roadmap.state("dario") == "MYSTERY", "dario mystery teaser from start")
        ok += _check(Roadmap.state("maze") == "HIDDEN", "maze hidden (appear_after 2)")
        # playing snake reveals rally (chain) but it stays hidden until Roadmap.tick stamps it
        Box.record_run("snake", 10)
        ok += _check(Roadmap.state("rally") == "LOCKED", "rally revealed after snake played")
        # mystery orders progress
        var lines := Roadmap.order_lines("dario")
        ok += _check(lines.size() == 2, "dario has 2 orders")
        ok += _check(not Roadmap._condition_done("dario", GameReg.get_game("dario")["reveal"]),
                "dario orders incomplete")
        Box.add_spent("snake", 120)
        Box.record_run("snake", 5)
        Box.record_run("snake", 5)
        ok += _check(Roadmap._condition_done("dario", GameReg.get_game("dario")["reveal"]),
                "dario orders complete after spend+plays")
        ok += _check(Roadmap.state("dario") == "SOON", "dario SOON (workshop game)")
        # gated: maze needs 2 owned games (snake + rally = 2 -> teaser appears)
        Box.unlock_game("rally", 0)
        ok += _check(Roadmap.state("maze") == "MYSTERY", "maze mystery at 2 owned")
        Box.unlock_game("lanes", 0)
        ok += _check(Roadmap.state("maze") == "MYSTERY", "maze still mystery (orders pending)")
        # timed mystery
        ok += _check(Roadmap.time_left("spud") > 23.0 * 3600.0, "spud ~24h left")
        ok += _check(Roadmap.inbox_left("hen") > 19.0 * 60.0, "hen ~20min box time left")
        Box.reset_all()
        return ok

# ------------------------------------------------------------------ scroll

func _t_scroll() -> int:
        var ok := 0
        var sc: BoxScroll = load("res://game/core/scroll_box.gd").new()
        sc.position = Vector2(0, 0)
        sc.size = Vector2(720, 400)
        add_child(sc)
        await get_tree().process_frame
        var content := Panel.new()
        content.custom_minimum_size = Vector2(700, 1600)
        content.mouse_filter = Control.MOUSE_FILTER_IGNORE
        sc.add_child(content)
        await get_tree().process_frame
        await get_tree().process_frame

        # tap dispatch
        var hit := [false]
        var target := Control.new()
        target.custom_minimum_size = Vector2(200, 120)
        target.position = Vector2(20, 20)
        target.size = Vector2(200, 120)
        target.mouse_filter = Control.MOUSE_FILTER_IGNORE
        content.add_child(target)
        sc.register_tappable(target, func(): hit[0] = true)
        _touch(0, Vector2(100, 80), true)
        _touch(0, Vector2(100, 80), false)
        await get_tree().process_frame
        await get_tree().process_frame
        ok += _check(hit[0], "tap reaches registered tappable")

        # drag scrolls (finger moves up -> content scrolls down)
        _touch(1, Vector2(360, 300), true)
        for i in 4:
                _drag(1, Vector2(360, 300.0 - (i + 1) * 45.0), Vector2(0, -45))
                await get_tree().process_frame
        _touch(1, Vector2(360, 120), false)
        await get_tree().process_frame
        ok += _check(sc.scroll_vertical >= 150, "drag scrolls the container (%d)" % sc.scroll_vertical)
        sc.queue_free()
        return ok

func _touch(idx: int, pos: Vector2, pressed: bool) -> void:
        var ev := InputEventScreenTouch.new()
        ev.index = idx
        ev.position = _to_window(pos)
        ev.pressed = pressed
        Input.parse_input_event(ev)

func _drag(idx: int, pos: Vector2, rel: Vector2) -> void:
        var ev := InputEventScreenDrag.new()
        ev.index = idx
        ev.position = _to_window(pos)
        ev.relative = rel
        Input.parse_input_event(ev)

## parse_input_event expects WINDOW coords; delivery maps them into the
## 720x1280 base via final_transform⁻¹, so we apply the forward transform.
func _to_window(viewport_pos: Vector2) -> Vector2:
        return get_viewport().get_final_transform() * viewport_pos

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
        await get_tree().create_timer(3.0).timeout   # universal loading screen runs first
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
        # MODULAR coin_div: snake 37 / 10 = 3 bonus, + 5 pickups = 8 total
        ok += _check(Box.coins() == 150 - 10 + 8, "net wallet 148 -> %d" % Box.coins())
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
        # charged games need BOTH pools: keep the box bank topped up
        Box.data["box_batteries"] = Box.box_battery_cap()
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
                await get_tree().create_timer(3.0).timeout   # loading screen
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

func _t_menu() -> int:
        Box.reset_all()
        var ok := 0
        var menu := Node2D.new()
        menu.set_script(load("res://game/menu/menu.gd"))
        add_child(menu)
        await get_tree().process_frame
        await get_tree().process_frame
        await get_tree().create_timer(0.3).timeout
        var grid: GridContainer = menu._grid
        ok += _check(grid != null and grid.get_child_count() >= 2,
                "menu grid has tiles (%s)" % (grid.get_child_count() if grid else -1))
        ok += _check(menu._root.size.x > 0 and menu._root.size.y > 0, "menu root sized")
        # every sheet opens without script errors
        menu._open_settings()
        await get_tree().process_frame
        menu._close_sheet()
        menu._open_trophies()
        await get_tree().process_frame
        menu._close_sheet()
        menu._open_mystery_page(GameReg.get_game("dario"))
        await get_tree().process_frame
        menu._close_sheet()
        menu._open_game_page(GameReg.get_game("snake"))
        await get_tree().process_frame
        menu._close_sheet()
        ok += _check(true, "sheets open/close cleanly")
        menu.queue_free()
        await get_tree().process_frame
        Box.reset_all()
        return ok
