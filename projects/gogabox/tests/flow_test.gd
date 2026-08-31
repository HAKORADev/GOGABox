extends Node
## GOGABox flow test: core infra round-trips + every playable game boots,
## reports a run, and the economy lands in the store. Exit 0 = all green.

var fails := 0

func _ready() -> void:
        print("=== GOGABox flow test ===")
        fails += _test("store: wallet roundtrip", _t_wallet())
        fails += _test("store: favorites roundtrip", _t_favorites())
        fails += _test("ui: bonus ratio + badge rules", _t_bonus_badges())
        fails += _test("store: unlocks + anti-softlock", _t_unlocks())
        fails += _test("store: stats/achievements/skins", _t_slots())
        fails += _test("store: time/spent/earned tracking", _t_accounting())
        fails += _test("batteries: pools, consumption, refill", _t_batteries())
        fails += _test("windows: hour math", _t_windows())
        fails += _test("meta: registry metadata sane", _t_meta())
        fails += _test("registry: entries sane", _t_registry())
        fails += _test("xo: ladder AI sanity", _t_xo_ai())
        fails += _test("roadmap: reveal state machine", _t_roadmap())
        fails += _test("roadmap: mystery queue cap 4", _t_mystery_queue())
        fails += _test("roadmap: GOGACharges meters", _t_charging())
        fails += _test("wallet: snake partial pay", await _t_snake_pay())
        fails += _test("wallet: daily limits 12AM reset", _t_daily())
        fails += _test("time: AM/PM + live unlock", _t_time_fmt())
        fails += _test("roadmap: owner feed order + playability oracle", _t_feed_order())
        fails += _test("scroll: BoxScroll drag/tap", await _t_scroll())
        fails += _test("host: launch + finish + economy", await _t_host_flow())
        fails += _test("games: all playable boot", await _t_all_games())
        fails += _test("menu: boots and lays out", await _t_menu())
        fails += _test("isolation: own-world launch + reward tiers", await _t_isolation())
        fails += _test("sheets: fit_sheet button safety", await _t_fitsheet())
        fails += _test("plugins: GDScript/native name parity", _t_plugin_names())
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

## v0.0.9: the pre-play heart. Favorites are a box-level list; a game
## progress wipe must NOT drop the favorite (library opinion, not a stat).
func _t_favorites() -> int:
        Box.reset_all()
        var ok := _check(not Box.is_favorite("snake"), "snake not favorited at start")
        Box.set_favorite("snake", true)
        ok += _check(Box.is_favorite("snake"), "heart adds snake to favorites")
        ok += _check(not Box.is_favorite("rally"), "rally untouched")
        Box.set_favorite("snake", false)
        ok += _check(not Box.is_favorite("snake"), "heart removes it again")
        Box.set_favorite("snake", true)
        Box.reset_game("snake")
        ok += _check(Box.is_favorite("snake"), "reset_game keeps the favorite")
        Box.reset_all()
        ok += _check(not Box.is_favorite("snake"), "reset_all clears favorites")
        return ok

## v0.0.9: the modular score-bonus ratio text + the badge rule set.
func _t_bonus_badges() -> int:
        var ok := _check(Arc.bonus_ratio_text(230, 2) == "230/2 = 115",
                "ratio text /2 (snake)")
        ok += _check(Arc.bonus_ratio_text(45, 100) == "45/100 = 0",
                "ratio text floors below the divider")
        ok += _check(Arc.bonus_ratio_text(7, 0) == "7", "ratio text div-0 safe")
        Box.reset_all()
        Box.record_started("snake")   # v0.1.9: 'played' = a run STARTED
        ok += _check(Roadmap.state("rally") == "LOCKED", "rally buyable after snake played")
        Roadmap.tick()
        ok += _check(Box.badge("rally") == "unlocked",
                "LOCKED wears UNLOCKED! (%s)" % Box.badge("rally"))
        Box.mark_seen("rally")
        ok += _check(Box.badge("rally") == "", "tap clears the badge")
        Box.reset_all()
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
        # v0.1.9 OWNER FIX: plays count at START (a mid-turn quit stays played);
        # record_run keeps only the score story.
        Box.record_started("snake")
        Box.record_started("snake")
        Box.record_run("snake", 42)
        Box.record_run("snake", 17)
        var ok := _check(Box.stat("snake", "best") == 42, "best kept")
        ok += _check(Box.stat("snake", "last") == 17, "last updated")
        ok += _check(Box.stat("snake", "plays") == 2, "plays counted at START")
        ok += _check(Box.last_played_at("snake") > 0, "last_ts set for the lists")
        Box.bump_counter("snake", "apples", 10)
        Box.bump_counter("snake", "apples", 5)
        ok += _check(Box.counter("snake", "apples") == 15, "counters add")
        ok += _check(not Box.has_achievement("snake", "a1"), "ach unset")
        ok += _check(Box.grant_achievement("snake", "a1"), "first grant true")
        ok += _check(not Box.grant_achievement("snake", "a1"), "second grant false")
        ok += _check(Box.ach_count("snake") == 1, "ach_count tracks trophies")
        ok += _check(Box.buy_skin("snake", "gold", 300) == false, "skin refused (broke)")
        Box.earn(400)
        ok += _check(Box.buy_skin("snake", "gold", 300), "skin bought")
        ok += _check(Box.skin_on("snake") == "gold", "skin auto-equipped")
        # v0.1.9 shop shelves: items + unlocks (fruits / power-ups / pack)
        ok += _check(not Box.item_owned("snake", "fruit", "banana"), "fruit not owned")
        ok += _check(Box.buy_item("snake", "fruit", "banana", 80), "fruit bought")
        ok += _check(Box.item_owned("snake", "fruit", "banana"), "fruit owned after buy")
        ok += _check((Box.items_owned("snake", "fruit") as Array).has("banana"),
                "items_owned lists it")
        ok += _check(Box.buy_item("snake", "fruit", "banana", 80) == false,
                "double buy refused")
        ok += _check(not Box.unlock_owned("snake", "powerups"), "powerups locked")
        Box.earn(600)   # fund the shelf unlocks
        ok += _check(Box.buy_unlock("snake", "powerups", 400), "system unlock bought")
        ok += _check(Box.unlock_owned("snake", "powerups"), "powerups unlocked")
        ok += _check(Box.item_on("snake", "fruit") == "banana", "last buy auto-armed")
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
        Box.set_box_batteries(1)
        ok += _check(not Box.consume_round_batteries("rally"), "no play when bank < cost")
        ok += _check(int(Box.game_battery("rally")["count"]) == 10, "pool untouched on fail")
        Box.set_box_batteries(30)
        Box.data["game_batteries"]["rally"]["count"] = 1
        var moved := Box.refill_game_from_box("rally")
        # OWNER RULE (v0.0.6): a tap refills ONE ROUND worth (per_round), never
        # a full battery - the game pool's cap is a hard ceiling
        ok += _check(moved == 2 and int(Box.game_battery("rally")["count"]) == 3,
                "refill moves one round (2), pool 1->3")
        ok += _check(Box.box_batteries() == 28, "box bank drained to 28")
        moved = Box.refill_game_from_box("rally")
        ok += _check(moved == 2 and int(Box.game_battery("rally")["count"]) == 5,
                "second tap: another round, pool 3->5")
        Box.data["game_batteries"]["rally"]["count"] = 9
        moved = Box.refill_game_from_box("rally")
        ok += _check(moved == 1 and int(Box.game_battery("rally")["count"]) == 10,
                "cap-limited: only the missing 1 moves")
        Box.data["game_batteries"]["rally"]["count"] = 5
        Box.set_box_batteries(0)
        ok += _check(Box.refill_game_from_box("rally") == 0, "dry bank: nothing moves")
        # v0.1.1 OWNER RULE: the BOX BANK charges ONLY while the app is
        # CLOSED. Reads are pure (no lazy regen) - a stale ts must not move
        # the pool while the app is open.
        Box.data["box_batteries"] = {"count": 0,
                "ts": int(Time.get_unix_time_from_system()) - 620, "rem": 0}
        ok += _check(Box.box_batteries() == 0, "open app never self-charges (stale ts ignored)")
        Box._credit_offline()   # coming back: 620s closed -> +2, remainder 20
        ok += _check(Box.box_batteries() == 2, "620s closed -> +2 box batteries")
        ok += _check(int(Box.data["box_batteries"]["rem"]) == 20, "remainder banked toward next +1 (20s)")
        ok += _check(Box.box_regen_in() == Box.BATTERY_STEP - 20,
                "next +1 after %ds away" % (Box.BATTERY_STEP - 20))
        # pause opens the charging window, resume banks it (the real loop)
        Box.set_box_batteries(0)
        Box._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
        ok += _check(int(Box.data["box_batteries"]["ts"]) > 0, "pause opens the charging window")
        Box.data["box_batteries"]["ts"] = int(Time.get_unix_time_from_system()) - 310
        Box._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
        ok += _check(Box.box_batteries() == 1, "310s closed -> +1 battery on resume")
        ok += _check(int(Box.data["box_batteries"]["ts"]) == 0, "window shut while the app is open")
        # the game pools still refill ALWAYS (only the bank is offline-only)
        Box.data["game_batteries"]["rally"] = {"count": 0, "ts": int(Time.get_unix_time_from_system()) - 620}
        ok += _check(int(Box.game_battery("rally")["count"]) == 2, "game pool still refills live (+2)")
        # v0.1.3 OWNER RULE (final call): the in-app ping fires when a pool
        # charges back to COMPLETELY FULL - the v0.1.2 per-round ping was
        # tried on device and reverted ("the old design when it's complete
        # full is much better"). battery_full_reached mirrors the ping.
        var pings := [0]
        var ping_titles: Array = []
        var ping_cb := func(title: String):
                pings[0] += 1
                ping_titles.append(title)   # v0.1.9: the signal names the pool
        Box.battery_full_reached.connect(ping_cb)
        Box.data["game_batteries"]["rally"] = {"count": 8,
                "ts": int(Time.get_unix_time_from_system()) - 620}
        Box.meta().erase("batt_ping_at")
        Box.game_battery("rally")            # 8 -> 10 FULL -> PING
        ok += _check(pings[0] == 1, "pool reaching FULL pings once")
        ok += _check(ping_titles.size() == 1 and String(ping_titles[0]) == "PONG",
                "the ping carries WHICH game filled (%s)" % str(ping_titles))
        Box.game_battery("rally")            # steady full - no new ping
        ok += _check(pings[0] == 1, "no repeat ping while the pool sits full")
        Box.data["game_batteries"]["rally"] = {"count": 0,
                "ts": int(Time.get_unix_time_from_system()) - 620}
        Box.meta().erase("batt_ping_at")
        Box.game_battery("rally")            # 0 -> +2: a round is ready, NOT full
        ok += _check(pings[0] == 1, "no ping when the pool is not full yet")
        # the BANK pings the same way on resume credit when the closed time
        # FILLS it to the cap
        Box.data["box_batteries"] = {"count": 45,
                "ts": int(Time.get_unix_time_from_system()) - 1250, "rem": 0}
        Box.meta().erase("batt_ping_at")
        Box._credit_offline()                # 45 -> 47: charged but NOT full
        ok += _check(pings[0] == 1, "bank below full stays silent")
        Box.data["box_batteries"] = {"count": 48,
                "ts": int(Time.get_unix_time_from_system()) - 620, "rem": 0}
        Box.meta().erase("batt_ping_at")
        Box._credit_offline()                # 48 -> 50 FULL -> PING
        ok += _check(pings[0] == 2, "bank charging to full pings")
        Box.battery_full_reached.disconnect(ping_cb)
        # v0.1.1: the ONE playability oracle (feed chip + pre-play button)
        Box.reset_all()
        ok += _check(Roadmap.can_play_now("snake"), "snake is always ready (starter)")
        ok += _check(not Roadmap.can_play_now("rally"), "locked rally is not playable")
        Box.unlock_game("rally", 150)   # wallet drained to 0
        ok += _check(not Roadmap.can_play_now("rally"), "rally needs its 8-coin fee")
        Box.earn(8)
        ok += _check(Roadmap.can_play_now("rally"), "rally ready: coins + both pools full")
        Box.set_box_batteries(1)
        ok += _check(not Roadmap.can_play_now("rally"), "a round also needs 2 bank batteries")
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
        var ok := _check(GameReg.playable().size() == 8, "8 playable games")
        ok += _check(GameReg.workshop().size() == 6, "6 workshop teasers")
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
        # v0.1.8: snake supports BOTH orientations; the mode is chosen at
        # load (host_node reads the real window shape - headless falls back
        # to portrait, and the boot test below exercises that exact path)
        ok += _check(String(GameReg.get_game("snake").get("orientation")) == "auto",
                "snake auto orientation (mode chosen at load)")
        return ok

# ------------------------------------------------------------------ xo AI

## v0.1.7: XO Ladder ships with a real opponent - drive its pure AI core
## directly (no scene needed) and pin the ladder's promises: the top rung
## is perfect, the bottom is beatable.
func _t_xo_ai() -> int:
        var xo: GDScript = load("res://game/games/xo/xo.gd")
        var ok := 0
        # winner_of: rows, columns, diagonals, draws, none-yet
        ok += _check(int(xo.winner_of([1, 1, 1, 2, 2, 0, 0, 0, 0])) == 1,
                "winner_of: X row")
        ok += _check(int(xo.winner_of([2, 1, 1, 2, 1, 1, 0, 0, 0])) == 0,
                "winner_of: none yet")
        ok += _check(int(xo.winner_of([1, 2, 1, 1, 2, 2, 2, 1, 1])) == 3,
                "winner_of: full board is a draw")
        ok += _check(int(xo.winner_of([1, 0, 0, 1, 2, 2, 1, 0, 2])) == 1,
                "winner_of: X column")
        ok += _check(int(xo.winner_of([1, 2, 2, 2, 1, 0, 0, 0, 1])) == 1,
                "winner_of: X diagonal")
        var rng := RandomNumberGenerator.new()
        # the top of the ladder takes wins and blocks threats
        rng.seed = 7
        ok += _check(int(xo.ai_pick([2, 2, 0, 1, 1, 0, 0, 0, 0], 10, rng)) == 2,
                "rung 10 takes the immediate win")
        rng.seed = 8
        ok += _check(int(xo.ai_pick([1, 1, 0, 2, 0, 0, 0, 2, 0], 10, rng)) == 2,
                "rung 10 blocks the X row")
        rng.seed = 9
        var reply: int = xo.ai_pick([0, 0, 0, 0, 1, 0, 0, 0, 0], 10, rng)
        ok += _check(reply == 0 or reply == 2 or reply == 6 or reply == 8,
                "rung 10 answers a center opening with a corner (got %d)" % reply)
        # perfect vs perfect (the machine plays BOTH sides via ai_pick):
        # X's turn asks the swapped board (ai_pick plays bb-O = real X),
        # O's turn asks the raw board (ai_pick plays real O). Result: the
        # top of the ladder NEVER loses.
        for g in range(3):
                rng.seed = 100 + g
                var b := [0, 0, 0, 0, 0, 0, 0, 0, 0]
                var mover: int = xo.X
                var ended := ""
                for step in range(9):
                        var ask: Array = b.duplicate()
                        if mover == xo.X:
                                ask = []
                                for v in b:
                                        ask.append(0 if int(v) == 0 else 3 - int(v))
                        var mv: int = xo.ai_pick(ask, 10, rng)
                        if mv < 0:
                                break
                        b[mv] = mover
                        var w: int = xo.winner_of(b)
                        if w != 0:
                                ended = "draw" if w == 3 else "winner %d" % w
                                break
                        mover = xo.O if mover == xo.X else xo.X
                ok += _check(ended == "draw",
                        "perfect-vs-perfect game %d is a draw (%s)" % [g, ended])
        # the bottom of the ladder is beatable: rung 1 often misses the block
        var misses := 0
        for s in range(40):
                rng.seed = 1000 + s
                if int(xo.ai_pick([1, 1, 0, 0, 2, 0, 0, 0, 0], 1, rng)) != 2:
                        misses += 1
        ok += _check(misses > 0, "rung 1 is beatable (missed the block %d/40)" % misses)
        return ok

# ------------------------------------------------------------------ roadmap

func _t_roadmap() -> int:
        Box.reset_all()
        var ok := _check(Roadmap.state("snake") == "OWNED", "snake owned from start")
        ok += _check(Roadmap.state("rally") == "HIDDEN", "rally hidden before first play")
        # v0.1.7: dario/xo LEFT the workshop - real chain games now, revealed
        # by playing the previous catalog game (merge -> dario -> xo)
        ok += _check(Roadmap.state("dario") == "HIDDEN", "dario hidden (chain: merge unplayed)")
        ok += _check(Roadmap.state("xo") == "HIDDEN", "xo hidden (chain: dario unplayed)")
        ok += _check(Roadmap.state("maze") == "HIDDEN", "maze hidden (appear_after 2)")
        # daily picks: deterministic per day, OWNED games only (v0.0.9 owner
        # rule - mystery boxes in picks were "kind of funny but wrong"), <= 5
        var picks := Roadmap.daily_picks()
        var picks2 := Roadmap.daily_picks()
        ok += _check(picks.size() >= 1 and picks.size() <= 5,
                "daily picks owned-pool 1..5 (%d)" % picks.size())
        var all_owned := true
        for p in picks:
                all_owned = all_owned and Box.owns_game(String(p["id"]))
        ok += _check(all_owned, "picks are owned-only")
        ok += _check(picks.size() == picks2.size(), "daily picks stable in a day")
        var same := true
        for i in picks.size():
                same = same and String(picks[i]["id"]) == String(picks2[i]["id"])
        ok += _check(same, "daily picks same order within a day")
        # v0.0.7 two-level badges: mystery teaser wears NEW!
        Roadmap.tick()
        ok += _check(Box.badge("hen") == "new", "fresh teaser badge NEW! (%s)" % Box.badge("hen"))
        # playing snake reveals rally (chain) but it stays hidden until Roadmap.tick stamps it
        Box.record_started("snake")
        ok += _check(Roadmap.state("rally") == "LOCKED", "rally revealed after snake played")
        Roadmap.tick()
        ok += _check(Box.badge("rally") == "unlocked", "resolved tile badge UNLOCKED! (%s)" % Box.badge("rally"))
        Box.mark_seen("rally")
        ok += _check(Box.badge("rally") == "", "tap clears the badge")
        # v0.1.7 THE EXTENDED CHAIN: merge played -> dario becomes buyable;
        # dario played -> xo becomes buyable
        Box.unlock_game("merge", 0)
        ok += _check(Roadmap.state("dario") == "HIDDEN", "dario still hidden (merge owned, unplayed)")
        Box.record_started("merge")
        ok += _check(Roadmap.state("dario") == "LOCKED", "dario LOCKED after merge played")
        Box.unlock_game("dario", 0)
        ok += _check(Roadmap.state("xo") == "HIDDEN", "xo still hidden (dario owned, unplayed)")
        Box.record_started("dario")
        ok += _check(Roadmap.state("xo") == "LOCKED", "xo LOCKED after dario played")
        # maze keeps the orders vocabulary alive (beat_best/earn_in/charges)
        var lines := Roadmap.order_lines("maze")
        ok += _check(lines.size() == 3, "maze has 3 orders (incl. GOGACharges order)")
        ok += _check(not Roadmap._condition_done("maze", GameReg.get_game("maze")["reveal"]),
                "maze orders incomplete")
        # ach_exact stays supported in the vocabulary (unworn right now)
        ok += _check(Roadmap.order_lines("dario").is_empty(),
                "chain games carry no order lines")
        # gated: maze needs 2 owned games (snake + rally = 2 -> teaser appears)
        Box.unlock_game("rally", 0)
        ok += _check(Roadmap.state("maze") == "MYSTERY", "maze mystery at 2 owned")
        # v0.0.9 badge rules: GATED/SOON never wear UNLOCKED! - that badge is
        # for BUYABLE (LOCKED) tiles only; fresh appearances wear NEW!
        # v0.1.4: matcher carries a charge_unlock meter -> CHARGING, not GATED
        # (appear_after 0 -> the tile is visible from the start, never a mystery)
        Roadmap.tick()
        ok += _check(Roadmap.state("matcher") == "CHARGING",
                "matcher CHARGING (direct + 100-charge meter)")
        ok += _check(Box.badge("matcher") == "new",
                "CHARGING wears NEW! (%s)" % Box.badge("matcher"))
        Box.unlock_game("lanes", 0)
        ok += _check(Roadmap.state("maze") == "MYSTERY", "maze still mystery (orders pending)")
        ok += _check(Box.badge("spud") == "new" or Box.is_seen("spud"),
                "mystery teasers keep NEW! semantics")
        # timed mystery
        ok += _check(Roadmap.time_left("spud") > 23.0 * 3600.0, "spud ~24h left")
        ok += _check(Roadmap.inbox_left("hen") > 19.0 * 60.0, "hen ~20min box time left")
        Box.reset_all()
        return ok

# ------------------------------------------------- v0.1.4 economy suites

## THE MYSTERY QUEUE (owner brainstorm): at most 4 mysteries exist at once;
## the rest are INEXISTENT (HIDDEN, untracked) until a queue slot frees.
## v0.1.7: dario/xo left the workshop, so the queue is hen/spud/maze/poptd
## - exactly 4 mystery-able teasers = the cap is full, never overflowed.
func _t_mystery_queue() -> int:
        Box.reset_all()
        var ok := _check(Roadmap.state("hen") == "MYSTERY", "queue: hen slot 1")
        ok += _check(Roadmap.state("spud") == "MYSTERY", "queue: spud slot 2")
        ok += _check(Roadmap.state("maze") == "HIDDEN", "maze waits (appear_after 2 at 1 owned)")
        ok += _check(Roadmap.state("poptd") == "HIDDEN", "poptd waits (appear_after 4)")
        ok += _check(Roadmap.state("matcher") == "CHARGING",
                "matcher is NO mystery (direct): visible CHARGING tile")
        ok += _check(Roadmap.state("dario") == "HIDDEN" and Roadmap.state("xo") == "HIDDEN",
                "dario/xo are chain games, never queue members")
        # own 2 -> maze joins (and keys' direct meter shows up CHARGING)
        Box.unlock_game("rally", 0)
        ok += _check(Roadmap.state("maze") == "MYSTERY", "maze takes slot 3 at 2 owned")
        ok += _check(Roadmap.state("keys") == "CHARGING",
                "keys CHARGING at 2 owned (direct + 200-charge meter)")
        # own 3 -> nothing new (poptd needs 4)
        Box.unlock_game("lanes", 0)
        ok += _check(Roadmap.state("poptd") == "HIDDEN", "poptd still waiting at 3 owned")
        # own 4 -> poptd joins: the queue is FULL at MYSTERY_CAP
        Box.unlock_game("slasher", 0)
        ok += _check(Roadmap.state("poptd") == "MYSTERY", "poptd takes slot 4 at 4 owned")
        # resolve hen (20 inbox minutes of box time) -> its slot frees
        Box.add_time("snake", 21 * 60)
        ok += _check(Roadmap.state("hen") == "SOON", "hen resolved after 20 box minutes")
        ok += _check(Roadmap.state("spud") == "MYSTERY" \
                and Roadmap.state("maze") == "MYSTERY" \
                and Roadmap.state("poptd") == "MYSTERY", "rest of the queue intact")
        Box.reset_all()
        return ok

## GOGACharges: pour from the box bank into a game's unlock meter; when the
## meter reaches charge_unlock the tile resolves (CHARGING -> next state).
func _t_charging() -> int:
        Box.reset_all()
        var ok := _check(Box.charges_in("matcher") == 0, "meter starts at 0")
        Box.set_box_batteries(50)
        var moved := Box.give_charges("matcher", 60)   # bank caps the pour at 50
        ok += _check(moved == 50, "pour capped by the bank (50 of 60 asked)")
        ok += _check(Box.charges_in("matcher") == 50 and Box.charges_spent() == 50,
                "meter 50/100, charges_spent tracked")
        ok += _check(Box.box_batteries() == 0, "the bank really drained")
        ok += _check(Roadmap.state("matcher") == "CHARGING", "meter half: still CHARGING")
        Box.set_box_batteries(50)
        moved = Box.give_charges("matcher", 60)   # meter room caps the pour at 50
        ok += _check(moved == 50, "pour capped by the meter room")
        ok += _check(Box.charges_in("matcher") == 100, "matcher meter FULL (100)")
        ok += _check(Roadmap.state("matcher") == "GATED",
                "meter full -> GATED (needs 3 games, owns 1)")
        ok += _check(Box.give_charges("matcher", 10) == 0, "full meter takes no more")
        Box.unlock_game("rally", 0)
        Box.unlock_game("lanes", 0)
        ok += _check(Roadmap.state("matcher") == "SOON", "3 owned: matcher SOON")
        # keys = the 200-charge meter, deeper in the box
        Box.unlock_game("slasher", 0)   # owned 4 > appear_after 2
        ok += _check(Roadmap.state("keys") == "CHARGING", "keys CHARGING (200 meter)")
        for i in 4:
                Box.set_box_batteries(50)
                Box.give_charges("keys", 60)
        ok += _check(Box.charges_in("keys") == 200, "keys meter 200/200")
        ok += _check(Roadmap.state("keys") == "SOON",
                "keys meter full + 4 owned (needs_games 4 met) -> SOON")
        ok += _check(Box.charges_spent() == 300, "charges_spent total 300 (%d)" % Box.charges_spent())
        # refills also count as spending charges (any box-bank pour does)
        Box.set_box_batteries(10)
        Box.game_battery("rally")   # materialize the pool first
        Box.data["game_batteries"]["rally"]["count"] = 5   # room for 2 in the pool
        var rmove := Box.refill_game_from_box("rally")
        ok += _check(rmove == 2 and Box.charges_spent() == 302, "refill pours count too (+2)")
        # a progress wipe keeps the meter (spent economy is not progress)
        Box.reset_game("matcher")
        ok += _check(Box.charges_in("matcher") == 100, "reset_game keeps the charges meter")
        Box.reset_all()
        return ok

## THE SNAKE ENTRY FIX (owner brainstorm): 0 < coins < fee used to play FREE
## - a 9-coin player farmed forever. Now the starter pays ALL its coins.
func _t_snake_pay() -> int:
        Box.reset_all()
        var ok := _check(Box.snake_entry_cost(10) == 10, "fat wallet pays the full fee")
        Box.spend(141)   # 150 -> 9 coins
        ok += _check(Box.snake_entry_cost(10) == 9, "9 coins: the fee is ALL 9")
        var router := Node2D.new()
        add_child(router)
        var launched: bool = load("res://game/core/game_host.gd").launch(router, "snake")
        ok += _check(launched and Box.coins() == 0,
                "launch with 9 coins: plays and lands at 0 (no free farm)")
        var host: Node = load("res://game/core/game_host.gd").active_host
        if host != null:
                host._quit_to_menu()
                await get_tree().process_frame
        ok += _check(Box.snake_entry_cost(10) == 0, "0 coins: still free (anti-softlock)")
        launched = load("res://game/core/game_host.gd").launch(router, "snake")
        ok += _check(launched and Box.coins() == 0, "empty wallet still launches (starter)")
        host = load("res://game/core/game_host.gd").active_host
        if host != null:
                host._quit_to_menu()
                await get_tree().process_frame
        # NO partial pay for non-snake games: rally owns the full-fee rule
        Box.earn(5)
        Box.unlock_game("rally", 0)   # free unlock (price 0) - only the FEE matters here
        ok += _check(not load("res://game/core/game_host.gd").launch(router, "rally"),
                "rally refuses at 5 < 8 coins (the exploit dies with snake-only partial pay)")
        # v0.1.5 SHARED ENTRY POLICY: the rule is registry data now - the box
        # never hardcodes a game name, a future game just wears the same key.
        ok += _check(Box.pays_partial_fee("snake") and not Box.pays_partial_fee("rally"),
                "partial-pay is a registry policy (snake yes, rally no)")
        ok += _check(Box.entry_cost("rally", 8) == 8 and Box.entry_cost("snake", 10) == 5,
                "entry_cost: rally pays full 8, snake's thin wallet pays ALL 5")
        ok += _check(Box.snake_entry_cost(10) == Box.entry_cost("snake", 10),
                "the v0.1.4 helper stays alive as the snake flavor of entry_cost")
        router.queue_free()
        Box.reset_all()
        return ok

## DAILY LIMITS (owner brainstorm): rounds and/or playtime per day, reset at
## 12AM 00:00 - lazy day rollover, no timers.
func _t_daily() -> int:
        Box.reset_all()
        var ok := _check(Box.daily_ok("snake"), "snake has no daily cap")
        ok += _check(Roadmap.daily_text("snake") == "", "no caps -> no daily line")
        var u := Box.daily_usage("rally")
        ok += _check(int(u["rounds_cap"]) == 6 and int(u["mins_cap"]) == 0,
                "rally: 6 rounds/day")
        for i in 6:
                Box.record_started("rally")   # v0.1.9: rounds burn at START
        ok += _check(not Box.daily_ok("rally"), "6 rounds: rally is done for today")
        ok += _check(Roadmap.daily_text("rally") == "6/6 rounds",
                "daily text live (%s)" % Roadmap.daily_text("rally"))
        # 12AM 00:00: the day key flips -> counters wipe on first read
        Box.data["games"]["rally"]["daily"]["day"] = "2000-01-01"
        ok += _check(Box.daily_ok("rally") and Box.daily_usage("rally")["rounds"] == 0,
                "past midnight: the cap resets")
        # lanes: BOTH caps on one game
        u = Box.daily_usage("lanes")
        ok += _check(int(u["rounds_cap"]) == 6 and int(u["mins_cap"]) == 15,
                "lanes: 6 rounds AND 15 min")
        for i in 6:
                Box.record_started("lanes")
        ok += _check(not Box.daily_ok("lanes"), "lanes dead via rounds")
        Box.data["games"]["lanes"]["daily"]["day"] = "2000-01-01"
        Box.add_time("lanes", 15.0 * 60.0)
        ok += _check(not Box.daily_ok("lanes"), "lanes dead via playtime too")
        ok += _check(Roadmap.daily_text("lanes") == "0/6 rounds - 15/15 min",
                "both halves print (%s)" % Roadmap.daily_text("lanes"))
        # slasher: playtime-only
        Box.add_time("slasher", 19.0 * 60.0)
        ok += _check(Box.daily_ok("slasher"), "19 of 20 min: still playable")
        Box.add_time("slasher", 61.0)
        ok += _check(not Box.daily_ok("slasher"), "20 min reached: locked")
        # the oracle + the launcher respect the cap
        Box.unlock_game("rally", 0)
        Box.earn(100)
        Box.data["games"]["rally"]["daily"]["rounds"] = 6
        ok += _check(not Roadmap.can_play_now("rally"), "can_play_now false while capped")
        var router := Node2D.new()
        add_child(router)
        ok += _check(not load("res://game/core/game_host.gd").launch(router, "rally"),
                "launch REFUSES a daily-capped game")
        router.queue_free()
        Box.reset_all()
        return ok

## AM/PM wording + the live window math (owner: "unlocks at nn AM/PM").
func _t_time_fmt() -> int:
        var ok := _check(Roadmap.fmt_hour(0) == "12 AM", "00h is 12 AM")
        ok += _check(Roadmap.fmt_hour(9) == "9 AM", "09h is 9 AM")
        ok += _check(Roadmap.fmt_hour(12) == "12 PM", "12h is 12 PM")
        ok += _check(Roadmap.fmt_hour(13) == "1 PM", "13h is 1 PM")
        ok += _check(Roadmap.fmt_hour(16) == "4 PM", "16h is 4 PM")
        ok += _check(Roadmap.fmt_hour(23) == "11 PM", "23h is 11 PM")
        ok += _check(Roadmap.window_text("hopper") == "playable 4 PM - 10 PM",
                "hopper window in AM/PM (%s)" % Roadmap.window_text("hopper"))
        ok += _check(Roadmap.window_text("lanes") == "rests 1 AM - 8 AM",
                "lanes rest window in AM/PM (%s)" % Roadmap.window_text("lanes"))
        # next_unlock_at is 0 exactly when the window is open right now
        var na := Roadmap.next_unlock_at("hopper")
        var open_now := Roadmap.window_ok("hopper")
        ok += _check((na == 0) == open_now, "unlock ts <-> window-open agree")
        if na > 0:
                var td := Time.get_time_dict_from_unix_time(na)
                ok += _check(int(td["hour"]) == 16, "hopper unlocks AT 4 PM (hour %d)" % int(td["hour"]))
                ok += _check(na > int(Time.get_unix_time_from_system()), "unlock is in the future")
        ok += _check(Roadmap.next_unlock_at("snake") == 0, "no window -> no unlock ts")
        return ok

# ------------------------------------------------------------------ scroll

## v0.1.1 OWNER FEED ORDER: owned (oldest unlock first) -> locked/soon ->
## mysteries, each block oldest->newest. Plus the can_play_now oracle that
## both the feed chip and the pre-play button read.
func _t_feed_order() -> int:
        Box.reset_all()
        Box.record_started("snake")   # reveals rally (chain) + the mysteries
        Roadmap.tick()
        var rows := Roadmap.feed_rows()
        var ids: Array = []
        var buckets: Array = []
        for r in rows:
                ids.append(String(r["g"]["id"]))
                buckets.append(int(r["bucket"]))
        var ok := _check(ids.size() >= 4, "feed has rows (%d)" % ids.size())
        ok += _check(String(ids[0]) == "snake", "owned block first (snake is index 0: %s)" % ids[0])
        var sorted_b := buckets.duplicate()
        sorted_b.sort()
        ok += _check(buckets == sorted_b, "buckets ascend owned->locked->mystery %s" % [buckets])
        ok += _check(buckets.has(0) and buckets.has(1) and buckets.has(2),
                "all three buckets present %s" % [buckets])
        # within the owned block: acquisition order (owned[] append order)
        Box.unlock_game("rally", 0)
        rows = Roadmap.feed_rows()
        var owned_ids: Array = []
        for r in rows:
                if int(r["bucket"]) == 0:
                        owned_ids.append(String(r["g"]["id"]))
        ok += _check(owned_ids == ["snake", "rally"],
                "owned block is unlock order %s" % [owned_ids])
        ok += _check(Roadmap.can_play_now("snake"), "oracle: snake always playable")
        ok += _check(Roadmap.can_play_now("dario") == false, "oracle: unowned dario not playable")
        ok += _check(Roadmap.can_play_now("xo") == false, "oracle: unowned xo not playable")
        Box.reset_all()
        return ok

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

## v0.0.6: the BUTTON SAFETY SYSTEM. A sheet taller than the screen must wrap
## its middle into a scroll (buttons move apart instead of colliding), the
## pinned tail stays outside it, wrapped buttons become tappables, and the
## panel is clamped inside the screen edges.
func _t_fitsheet() -> int:
        Box.reset_all()
        var ok := 0
        var root := Control.new()
        root.set_anchors_preset(Control.PRESET_FULL_RECT)
        add_child(root)
        var vb := Arc.sheet(root, 0.0)
        # deliberately oversized content: v0.1.2 design is 1080x1920, so it
        # takes 40 big buttons to overflow it (~19 fit inside 0.94*1920 now)
        for i in 40:
                vb.add_child(Arc.button("B %d" % i, Vector2(480, 84), 24, Arc.ACCENT))
        vb.add_child(Arc.button("TAIL", Vector2(480, 64), 22, Color(0.42, 0.30, 0.16),
                func(): pass))
        Arc.fit_sheet(vb, 1)
        await get_tree().process_frame
        await get_tree().process_frame
        await get_tree().process_frame
        var pc := vb.get_parent() as PanelContainer
        var sc: BoxScroll = null
        var tail_found := false
        for c in vb.get_children():
                if c is BoxScroll:
                        sc = c
                elif c is Button and (c as Button).text == "TAIL":
                        tail_found = true
        ok += _check(sc != null, "overflow wrapped into a scroll")
        ok += _check(tail_found, "tail button pinned outside the scroll")
        if sc != null:
                ok += _check(sc.game_safe, "sheet scroll works inside game sessions")
                ok += _check(sc._tappables.size() >= 40,
                                "wrapped buttons auto-registered (%d)" % sc._tappables.size())
                # a registered tap REPLAYS the real press on the wrapped button
                var inner: VBoxContainer = sc.get_child(0)
                var b3: Button = null
                for c in inner.get_children():
                        if c is Button and (c as Button).text == "B 3":
                                b3 = c
                ok += _check(b3 != null, "B 3 lives inside the scroll")
                if b3 != null:
                        var hit := [false]
                        b3.pressed.connect(func(): hit[0] = true)
                        sc._hit_tappable(b3.get_global_rect().get_center())
                        ok += _check(hit[0], "tap on wrapped button fires its press")
        if pc != null:
                # v0.1.0: compare against the REAL viewport (density rule
                # changed the headless logical size from 720x1280)
                var vp := pc.get_viewport_rect().size
                ok += _check(pc.size.y <= vp.y and pc.size.x <= vp.x,
                                "panel clamped inside the screen (%dx%d vs vp %.0fx%.0f)"
                                % [int(pc.size.x), int(pc.size.y), vp.x, vp.y])
                ok += _check(pc.size.y < 40.0 * 84.0,
                                "panel no longer stacks all 40 buttons raw (%d)" % int(pc.size.y))
        root.queue_free()
        await get_tree().process_frame
        Box.reset_all()
        return ok

## First Button in the subtree whose text starts with `starts`.
func _find_button(root: Node, starts: String) -> Button:
        var stack := [root]
        while not stack.is_empty():
                var n: Node = stack.pop_back()
                if n is Button and String((n as Button).text).begins_with(starts):
                        return n
                for c in n.get_children():
                        stack.append(c)
        return null

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
        await get_tree().create_timer(2.2).timeout   # payout theatre animates first
        ok += _check(Box.stat("snake", "best") == 37, "run recorded (best 37)")
        # MODULAR coin_div (v0.0.7: snake /2): 37 / 2 = 18 bonus, + 5 pickups = 23 total
        ok += _check(Box.coins() == 150 - 10 + 23, "net wallet 163 -> %d" % Box.coins())
        ok += _check(Box.stat("snake", "plays") == 1, "plays 1")
        # breakdown theatre collapsed into the sum line + chip shows the total
        ok += _check(host.has_method("_score_to_coins"), "host keeps the coin math")
        # ---- rewarded DOUBLE: sim pays instantly -> wallet + button state ----
        var dbl := _find_button(host, "DOUBLE")
        ok += _check(dbl != null, "double button on the game-over sheet")
        if dbl != null:
                dbl.pressed.emit()
                await get_tree().create_timer(1.0).timeout
                ok += _check(Box.coins() == 163 + 23,
                                "double pays the REAL amount (186) -> %d" % Box.coins())
                ok += _check(dbl.disabled and String(dbl.text).begins_with("REWARDED"),
                                "button enters rewarded state (%s)" % dbl.text)
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
        Box.set_box_batteries(Box.box_battery_cap())
        for g in GameReg.playable():
                if not Box.owns_game(String(g["id"])):
                        Box.unlock_game(String(g["id"]), 0)
        var router := Node2D.new()
        router.set_script(GDScript.new())
        add_child(router)
        for g in GameReg.playable():
                var id := String(g["id"])
                # real-hours gates (hopper 16-22 local) refuse the launch when
                # the wall clock is outside - that is the GAME WORKING AS
                # DESIGNED, so assert the gate exists and skip the boot
                # instead of flaking on the time of day
                if not Roadmap.window_ok(id):
                        ok += _check(Roadmap.window_text(id) != "",
                                        id + " window-gated right now (boot skipped by design)")
                        continue
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
                # v0.1.3: _restore decides from the REAL window px (no blind
                # pin). Headless reports a (0,0) window - the guarded no-op
                # then keeps the game's own design; a real window always
                # re-decides from true pixels.
                var ws := DisplayServer.window_get_size()
                var want_restore: Vector2i = ScaleRule.DESIGN_LANDSCAPE \
                                if String(g.get("orientation", "portrait")) == "landscape" \
                                else ScaleRule.DESIGN_PORTRAIT
                if ws.x > 0 and ws.y > 0:
                        want_restore = ScaleRule.want_for(ws)
                ok += _check(get_window().content_scale_size == want_restore,
                        id + " restore design honest (real px, else keeps game design)")
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
        # v0.0.9 carousel: ONE strip, 4 lists, arrows switch lists, dots = lists
        ok += _check(menu._lists_data.size() == 4, "carousel has 4 lists")
        ok += _check(menu._strip_title.text == "TODAY'S PICKS",
                "strip starts on TODAY'S PICKS (%s)" % menu._strip_title.text)
        ok += _check(menu._dots_row.get_child_count() == 4,
                "dots == lists (%d)" % menu._dots_row.get_child_count())
        var owned_only := true
        for it in menu._lists_data[0]["items"]:
                owned_only = owned_only and Box.owns_game(String(it["g"]["id"]))
        ok += _check(owned_only, "TODAY'S PICKS draws from owned games only")
        menu._list_move(1)
        ok += _check(menu._strip_title.text == "LAST PLAYED",
                "arrow switched to LAST PLAYED (%s)" % menu._strip_title.text)
        ok += _check(menu._dots_row.get_child_count() == 4, "dots rebuilt after list switch")
        menu._list_move(2)   # wraps around to ... NOT PLAYED YET (idx 3)
        ok += _check(menu._strip_title.text == "NOT PLAYED YET",
                "wrap lands on NOT PLAYED YET (%s)" % menu._strip_title.text)
        menu._list_move(1)   # back to TODAY'S PICKS
        ok += _check(menu._strip_title.text == "TODAY'S PICKS", "carousel wraps cleanly")
        # v0.1.9 OWNER FIX: LEAST PLAYED lists every owned+played game (it used
        # to EXCLUDE the LAST PLAYED set and go empty), fewest plays first
        Box.unlock_game("rally", 0)
        Box.record_started("rally")
        Box.record_started("rally")
        Box.record_started("snake")
        Box.record_run("rally", 5)
        Box.record_run("snake", 7)
        menu._refresh()
        menu._list_idx = 2
        menu._apply_list()
        var least: Array = menu._lists_data[2]["items"]
        ok += _check(least.size() == 2, "LEAST PLAYED lists ALL played games (%d)" % least.size())
        if least.size() == 2:
                ok += _check(String(least[0]["g"]["id"]) == "snake",
                        "fewest plays first (snake 1 play < rally 2: got %s)" % String(least[0]["g"]["id"]))
                ok += _check(String(least[0]["stat"]).begins_with("plays 1"),
                        "stat line is the play count (%s)" % String(least[0]["stat"]))
        # every sheet opens without script errors
        menu._open_settings()
        await get_tree().process_frame
        menu._close_sheet()
        menu._open_trophies()
        await get_tree().process_frame
        menu._close_sheet()
        menu._open_mystery_page(GameReg.get_game("maze"))
        await get_tree().process_frame
        menu._close_sheet()
        menu._open_game_page(GameReg.get_game("snake"))
        await get_tree().process_frame
        menu._close_sheet()
        # v0.1.4 pages: the daily-limit row (rally), the live window line
        # (hopper), and the charging meter page (matcher) all build cleanly
        menu._open_game_page(GameReg.get_game("rally"))
        await get_tree().process_frame
        menu._close_sheet()
        menu._open_game_page(GameReg.get_game("hopper"))
        await get_tree().process_frame
        menu._close_sheet()
        menu._open_charging_page(GameReg.get_game("matcher"))
        await get_tree().process_frame
        menu._close_sheet()
        menu._open_search()
        await get_tree().process_frame
        menu._close_sheet()
        ok += _check(true, "sheets open/close cleanly")
        menu.queue_free()
        await get_tree().process_frame
        Box.reset_all()
        return ok

## v0.0.5 core regression: a game is its OWN WORLD - the box hides (BOTH the
## Node2D and its CanvasLayer) and stops processing, the host carries a real
## full-screen background, and rewarded payouts follow the watch-time tiers.
func _t_isolation() -> int:
        Box.reset_all()
        var ok := 0

        # ---- tier math (half/p75/full from ads_config) ----
        ok += _check(Ads.reward_mult(5.0) == 0.0, "5s watch pays nothing")
        ok += _check(Ads.reward_mult(14.9) == 0.0, "14.9s pays nothing")
        ok += _check(Ads.reward_mult(15.0) == 0.5, "15s = half")
        ok += _check(Ads.reward_mult(19.9) == 0.5, "19.9s = half")
        ok += _check(Ads.reward_mult(20.0) == 0.75, "20s = 75%")
        ok += _check(Ads.reward_mult(29.9) == 0.75, "29.9s = 75%")
        ok += _check(Ads.reward_mult(30.0) == 1.0, "30s = full")

        # ---- REAL main.gd as the stage: launch through its menu (the exact
        # v0.0.4 bug shape) and prove the box fully vanishes ----
        var stage := Node2D.new()
        stage.set_script(load("res://game/main.gd"))
        add_child(stage)
        await get_tree().process_frame
        await get_tree().process_frame
        var menu: Node2D = stage._menu
        ok += _check(menu != null, "main built the menu")

        var launched: bool = load("res://game/core/game_host.gd").launch(menu, "snake")
        ok += _check(launched, "launch through menu router succeeds")
        await get_tree().create_timer(3.0).timeout   # loading screen
        var host: Node = load("res://game/core/game_host.gd").active_host
        ok += _check(host != null, "host alive")
        if host != null:
                # the own-world background: a CanvasLayer (layer -1) whose
                # full-rect ColorRect ACTUALLY has size (a Control under the
                # host Node2D collapsed to 0x0 - the original big L)
                var bg_layer: CanvasLayer = null
                for c in host.get_children():
                        if c is CanvasLayer and (c as CanvasLayer).layer == -1:
                                bg_layer = c
                ok += _check(bg_layer != null, "host bg lives on a CanvasLayer")
                if bg_layer != null and bg_layer.get_child_count() > 0:
                        var bgc := bg_layer.get_child(0) as ColorRect
                        ok += _check(bgc != null and bgc.size.x > 100.0 and bgc.size.y > 100.0,
                                "bg covers the real viewport (%s)" % (bgc.size if bgc else Vector2()))

        # ---- v0.1.1 OWNER RULE: the box theme is BOX-ONLY. It used to keep
        # looping under every game scene (the menu player was never stopped).
        # v0.1.8 REFINEMENT: a game may now own its OWN track (snake does) -
        # the invariant that matters is only that the BOX theme never plays
        # inside a game scene.
        ok += _check(not Jukebox._music.playing
                        or Jukebox._current_music.find("box_theme") == -1,
                "box theme STOPPED inside the game scene")
        ok += _check(Jukebox._current_music.find("box_theme") == -1,
                "jukebox never serves the menu track in-game")

        # ---- menu really hides: Node2D AND CanvasLayer AND processing ----
        ok += _check(not menu.visible, "menu node hidden")
        ok += _check(not menu._layer.visible, "menu CanvasLayer hidden (the v0.0.4 leak)")
        ok += _check(menu.process_mode == Node.PROCESS_MODE_DISABLED, "menu processing stopped")
        ok += _check(menu._feed_scroll.input_locked, "feed scroll locked")
        ok += _check(menu._strip_scroll != null and menu._strip_scroll.input_locked,
                "carousel strip locked")

        # ---- close restores everything (main.on_game_closed -> set_active) ----
        host._quit_to_menu()
        await get_tree().process_frame
        ok += _check(menu.visible and menu._layer.visible, "menu fully visible again")
        ok += _check(menu.process_mode == Node.PROCESS_MODE_INHERIT, "menu processing restored")
        ok += _check(load("res://game/core/game_host.gd").active_host == null, "session ended")
        ok += _check(Jukebox._music.playing, "box theme back after closing the game")

        stage.queue_free()
        await get_tree().process_frame
        Box.reset_all()
        return ok

# ------------------------------------------------------------------ plugins

## THE v0.1.0 REGRESSION GUARD: Godot android plugins do NO snake_case ->
## camelCase conversion of method names ("There is no coercing snake_case to
## camelCase" - docs). A GDScript native.permission_granted() call against a
## Java permissionGranted() method silently errors out on device - that was
## the whole "allow reminders does nothing" bug (v0.0.6..v0.0.9). This test
## parses every native.NAME( call in the addon GDScript and asserts a Java
## method with that exact name exists.
func _t_plugin_names() -> int:
        var ok := 0
        # res:// = projects/gogabox -> repo root is two levels up
        var root := (ProjectSettings.globalize_path("res://") + "/../../plugins/").simplify_path() + "/"
        var plugins := [
                {"gd": root + "notify/addon/notify.gd",
                 "java": root + "notify/android/org/godotengine/plugin/notify/NotifyPlugin.java"},
                {"gd": root + "unity_ads/addon/ads.gd",
                 "java": root + "unity_ads/android/org/godotengine/plugin/unityads/UnityAdsPlugin.java"},
        ]
        # built-in Object methods that are legal on the singleton but not Java
        var builtin := {"connect": true}
        var call_re := RegEx.new()
        call_re.compile("native\\.([a-zA-Z_][a-zA-Z0-9_]*)\\s*\\(")
        var meth_re := RegEx.new()
        meth_re.compile("\\b(?:public|static)\\s+[\\w<>\\[\\], ]+?\\s([a-zA-Z_][a-zA-Z0-9_]*)\\s*\\(")
        for p in plugins:
                var gd := FileAccess.open(p["gd"], FileAccess.READ)
                ok += _check(gd != null, "addon readable: " + p["gd"])
                if gd == null:
                        continue
                var java := FileAccess.open(p["java"], FileAccess.READ)
                ok += _check(java != null, "java readable: " + p["java"])
                if java == null:
                        continue
                var java_names := {}
                for m in meth_re.search_all(java.get_as_text()):
                        java_names[m.get_string(1)] = true
                var missing := {}
                for m in call_re.search_all(gd.get_as_text()):
                        var name_ := m.get_string(1)
                        if builtin.has(name_):
                                continue
                        if not java_names.has(name_):
                                missing[name_] = true
                var list := missing.keys()
                list.sort()
                ok += _check(missing.is_empty(),
                        "%s -> GDScript calls without exact Java match: %s" % [p["gd"].get_file(), ", ".join(list)])
        return ok
