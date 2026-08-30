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
        fails += _test("roadmap: reveal state machine", _t_roadmap())
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
        Box.record_run("snake", 10)   # chain rule: snake played -> rally revealed
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
        ok += _check(Box.ach_count("snake") == 1, "ach_count tracks trophies")
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
        # v0.1.2 OWNER RULE: the in-app ping is "an extra ROUND became ready",
        # not "the pool is full" ("batteries-for-a-round recharged instead").
        # battery_round_ready mirrors the audible ping for tests.
        var pings := [0]
        var ping_cb := func(): pings[0] += 1
        Box.battery_round_ready.connect(ping_cb)
        Box.data["game_batteries"]["rally"] = {"count": 0,
                "ts": int(Time.get_unix_time_from_system()) - 620}
        Box.meta().erase("batt_ping_at")
        Box.game_battery("rally")            # 0 -> +2 crosses per_round 2 -> PING
        ok += _check(pings[0] == 1, "pool crossing per_round pings once")
        Box.game_battery("rally")            # steady state - no new ping
        ok += _check(pings[0] == 1, "no ping while a round is already affordable")
        Box.data["game_batteries"]["rally"] = {"count": 6,
                "ts": int(Time.get_unix_time_from_system()) - 620}
        Box.meta().erase("batt_ping_at")
        Box.game_battery("rally")            # 6 -> 8: the round was already ready
        ok += _check(pings[0] == 1, "no ping when regen does not cross per_round")
        Box.data["game_batteries"]["rally"] = {"count": 8,
                "ts": int(Time.get_unix_time_from_system()) - 620}
        Box.game_battery("rally")            # 8 -> 10 FULL: still no ping
        ok += _check(pings[0] == 1, "the old full-cap ping is gone")
        # the BANK pings the same way on resume credit (crossing _round_need)
        Box.data["box_batteries"] = {"count": 0,
                "ts": int(Time.get_unix_time_from_system()) - 310, "rem": 0}
        Box.meta().erase("batt_ping_at")
        Box._credit_offline()                # bank 0 -> +1: below a round, silent
        ok += _check(pings[0] == 1, "bank below a round's worth stays silent")
        Box.data["box_batteries"] = {"count": 0,
                "ts": int(Time.get_unix_time_from_system()) - 620, "rem": 0}
        Box._credit_offline()                # bank 0 -> +2: crosses need 2 -> PING
        ok += _check(pings[0] == 2, "bank crossing a round's worth pings")
        Box.battery_round_ready.disconnect(ping_cb)
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
        var ok := _check(GameReg.playable().size() == 6, "6 playable games")
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
        ok += _check(Box.badge("dario") == "new", "fresh teaser badge NEW! (%s)" % Box.badge("dario"))
        # playing snake reveals rally (chain) but it stays hidden until Roadmap.tick stamps it
        Box.record_run("snake", 10)
        ok += _check(Roadmap.state("rally") == "LOCKED", "rally revealed after snake played")
        Roadmap.tick()
        ok += _check(Box.badge("rally") == "unlocked", "resolved tile badge UNLOCKED! (%s)" % Box.badge("rally"))
        Box.mark_seen("rally")
        ok += _check(Box.badge("rally") == "", "tap clears the badge")
        # mystery orders progress (spend + plays + 2 snake achievements)
        var lines := Roadmap.order_lines("dario")
        ok += _check(lines.size() == 3, "dario has 3 orders (incl. achievement order)")
        ok += _check(not Roadmap._condition_done("dario", GameReg.get_game("dario")["reveal"]),
                "dario orders incomplete")
        Box.add_spent("snake", 120)
        Box.record_run("snake", 5)
        Box.record_run("snake", 5)
        Box.grant_achievement("snake", "score_30")
        ok += _check(not Roadmap._condition_done("dario", GameReg.get_game("dario")["reveal"]),
                "dario still locked at 1/2 achievements")
        Box.grant_achievement("snake", "score_60")
        ok += _check(Roadmap._condition_done("dario", GameReg.get_game("dario")["reveal"]),
                "dario orders complete after spend+plays+2 achievements")
        ok += _check(Roadmap.state("dario") == "SOON", "dario SOON (workshop game)")
        # ach_exact order: a SPECIFIC trophy line resolves with its title
        var xo_lines := Roadmap.order_lines("xo")
        var found_exact := false
        for l in xo_lines:
                if "Wall of Paddle" in String(l["text"]):
                        found_exact = true
        ok += _check(found_exact and xo_lines.size() == 3, "xo carries the exact-trophy order")
        # gated: maze needs 2 owned games (snake + rally = 2 -> teaser appears)
        Box.unlock_game("rally", 0)
        ok += _check(Roadmap.state("maze") == "MYSTERY", "maze mystery at 2 owned")
        # v0.0.9 badge rules: GATED/SOON never wear UNLOCKED! - that badge is
        # for BUYABLE (LOCKED) tiles only; fresh appearances wear NEW!
        # (matcher: appear_after 2 -> visible, needs_games 3 -> GATED at 2 owned)
        Roadmap.tick()
        ok += _check(Roadmap.state("matcher") == "GATED", "matcher gated at 2 owned")
        ok += _check(Box.badge("matcher") == "new",
                "GATED wears NEW! (%s)" % Box.badge("matcher"))
        Box.unlock_game("lanes", 0)
        ok += _check(Roadmap.state("maze") == "MYSTERY", "maze still mystery (orders pending)")
        ok += _check(Box.badge("dario") == "new" or Box.is_seen("dario"),
                "SOON/mystery teasers keep NEW! semantics")
        # timed mystery
        ok += _check(Roadmap.time_left("spud") > 23.0 * 3600.0, "spud ~24h left")
        ok += _check(Roadmap.inbox_left("hen") > 19.0 * 60.0, "hen ~20min box time left")
        Box.reset_all()
        return ok

# ------------------------------------------------------------------ scroll

## v0.1.1 OWNER FEED ORDER: owned (oldest unlock first) -> locked/soon ->
## mysteries, each block oldest->newest. Plus the can_play_now oracle that
## both the feed chip and the pre-play button read.
func _t_feed_order() -> int:
        Box.reset_all()
        Box.record_run("snake", 10)   # reveals rally (chain) + the mysteries
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
        ok += _check(Roadmap.can_play_now("dario") == false, "oracle: workshop teaser not playable")
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
                ok += _check(get_window().content_scale_size == Vector2i(1080, 1920),
                        id + " orientation restored to portrait design (1080x1920)")
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
        ok += _check(not Jukebox._music.playing,
                "box theme STOPPED inside the game scene")
        ok += _check(Jukebox._current_music == "", "jukebox forgot the menu track in-game")

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
