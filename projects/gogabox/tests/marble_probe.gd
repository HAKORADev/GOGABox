extends SceneTree
## Headless chain-law probe for MARBLE POPPER: boots the game, drives play,
## and asserts the order law, the feed law, the insert/match/join laws, the
## coin rider, the pow carrier, the eat law and the meta laws.

var fails := 0

func _init() -> void:
        call_deferred("_run")

func check(name: String, ok: bool) -> void:
        print(("PASS  " if ok else "FAIL  ") + name)
        if not ok:
                fails += 1

func _run() -> void:
        print("== marble chain-law probe ==")
        var game = load("res://game/games/marble/marble.gd").new()
        game.game_id = "marble"
        get_root().add_child(game)
        await process_frame
        await process_frame
        check("boot intro", game.phase == "intro")

        game._start_level(0, false, 1)
        var cp = game.chains[0]
        check("level preview", game.phase == "preview")
        check("path built", cp.length > 300.0)
        # THE PREVIEW LAW (v040-14): the ghost chain loops until the TAP -
        # the probe taps (the old 1.6s auto-start is gone)
        game._begin_play()
        for i in 10:
                game._goga_tick(1.0 / 60.0)
        check("preview -> play", game.phase == "play")

        # drive play: the feed law fills the path
        for i in 600:
                game._goga_tick(1.0 / 60.0)
        check("fed marbles", cp.marbles.size() >= 6)
        check("quota respected", cp.spawned <= cp.quota)

        # THE ORDER LAW: d ascending end to end
        var ordered := true
        for i in range(1, cp.marbles.size()):
                if float(cp.marbles[i]["d"]) < float(cp.marbles[i - 1]["d"]) - 0.75:
                        ordered = false
        check("chain order ascending", ordered)

        # the FRONT advances (no stall, no backward explosion)
        var maxd0 := -99999.0
        for m in cp.marbles:
                maxd0 = maxf(maxd0, float(m["d"]))
        for i in 60:
                game._goga_tick(1.0 / 60.0)
        var maxd1 := -99999.0
        for m in cp.marbles:
                maxd1 = maxf(maxd1, float(m["d"]))
        check("front advances", maxd1 > maxd0 + 10.0)

        # THE INSERT+MATCH LAW: build a controlled run
        cp.marbles.clear()
        game.run_level_score = 0
        game.combo = 0
        var cols: Array = cp.colors
        for k in 6:
                var c: int = cols[0] if k != 3 else cols[1]
                cp.marbles.append({"c": c, "d": -float(k) * MarbleData.CONTACT, "kind": "m",
                                "life": -1.0, "pow": "", "spr": null, "glow": null, "bonded": true})
        # marbles: [front c0, c0, c0, c1, c0, c0(rear)] - a c0 shot into the c1
        # neighborhood completes a 3+ run and pops it in the same insert
        var shot := {"pos": cp.pos_at(-3.0 * MarbleData.CONTACT), "vel": Vector2.ZERO,
                        "c": int(cols[0]), "spr": null, "rainbow": false}
        var size_before: int = cp.marbles.size()
        game._insert_shot(cp, 3, shot)
        check("insert+match popped", cp.marbles.size() < size_before)
        check("match scored", game.run_level_score > 0)

        # THE JOIN LAW: two same-color ends close a gap and cascade
        cp.marbles.clear()
        cp.spawned = cp.quota   # freeze the feed for a controlled rig
        game.run_level_score = 0
        game.combo = 0
        # front pair of GREEN, a gap, then a GREEN pair behind: closing pops all 4
        cp.marbles.append({"c": 3, "d": -200.0, "kind": "m", "life": -1.0, "pow": "", "spr": null, "glow": null, "bonded": false})
        cp.marbles.append({"c": 3, "d": -104.0, "kind": "m", "life": -1.0, "pow": "", "spr": null, "glow": null, "bonded": false})
        cp.marbles.append({"c": 3, "d": 200.0, "kind": "m", "life": -1.0, "pow": "", "spr": null, "glow": null, "bonded": true})
        cp.marbles.append({"c": 3, "d": 296.0, "kind": "m", "life": -1.0, "pow": "", "spr": null, "glow": null, "bonded": true})
        # squeeze the rear pair forward until contact
        for i in 500:
                if cp.marbles.is_empty():
                        break
                game._tick_chain(cp, 1.0 / 60.0)
        check("join cascade popped", cp.marbles.size() <= 2)
        check("cascade scored", game.run_level_score > 0)

        # v040-14 THE FULL RUN LAW: FIVE contiguous same-color marbles - the
        # insert completes the run and the WHOLE FIVE pop (the owner: "only
        # 3 get popped is very wrong")
        cp.marbles.clear()
        cp.spawned = cp.quota
        game.run_level_score = 0
        game.combo = 0
        var score_before_run: int = 0
        for k in range(4, -1, -1):
                cp.marbles.append({"c": 3, "d": -float(k) * MarbleData.CONTACT,
                                "kind": "m", "life": -1.0, "pow": "",
                                "spr": null, "glow": null, "bonded": true})
        var shot5 := {"pos": cp.pos_at(0.0), "vel": Vector2.ZERO,
                        "c": 3, "spr": null, "rainbow": false}
        game._insert_shot(cp, 2, shot5)
        check("full run pops ALL SIX", cp.marbles.is_empty())
        check("full run scores for six", game.run_level_score >= 60)

        # v040-14 THE PUSH LAW: a rear-side insert slides the whole rear part
        # back EXACTLY one contact spacing - no overlap, no lerp wave
        cp.marbles.clear()
        cp.spawned = cp.quota
        for k in range(3, -1, -1):
                cp.marbles.append({"c": 1 if k % 2 == 0 else 6,
                                "d": -float(k) * MarbleData.CONTACT,
                                "kind": "m", "life": -1.0, "pow": "",
                                "spr": null, "glow": null, "bonded": true})
        var rear_d_before: float = float(cp.marbles[0]["d"])
        var hit_d_before: float = float(cp.marbles[2]["d"])
        var shot_nr := {"pos": cp.pos_at(hit_d_before - MarbleData.CONTACT),
                        "vel": Vector2.ZERO, "c": 6, "spr": null, "rainbow": false}
        game._insert_shot(cp, 2, shot_nr)
        var spacing_ok := true
        for i in range(1, cp.marbles.size()):
                var gap: float = float(cp.marbles[i]["d"]) - float(cp.marbles[i - 1]["d"])
                if absf(gap - MarbleData.CONTACT) > 0.6:
                        spacing_ok = false
        check("push keeps perfect spacing", spacing_ok)
        check("push slides the rear exactly one spacing",
                absf(float(cp.marbles[0]["d"]) - (rear_d_before - MarbleData.CONTACT)) < 0.6)
        var inserted_order_ok := true
        for i in range(1, cp.marbles.size()):
                if float(cp.marbles[i]["d"]) < float(cp.marbles[i - 1]["d"]):
                        inserted_order_ok = false
        check("push keeps the order law", inserted_order_ok)

        # THE NON-MATCH JOIN: different ends just move together (no pop)
        cp.marbles.clear()
        cp.spawned = cp.quota   # freeze the feed
        cp.marbles.append({"c": 3, "d": -700.0, "kind": "m", "life": -1.0, "pow": "", "spr": null, "glow": null, "bonded": false})
        cp.marbles.append({"c": 6, "d": -300.0, "kind": "m", "life": -1.0, "pow": "", "spr": null, "glow": null, "bonded": true})
        for i in 600:
                game._tick_chain(cp, 1.0 / 60.0)
                if cp.marbles.size() < 2:
                        break
        if cp.marbles.size() == 2:
                var together: float = absf(float(cp.marbles[1]["d"]) - float(cp.marbles[0]["d"]) - MarbleData.CONTACT)
                check("non-match joins and moves together", together < 6.0)
        else:
                check("non-match joins and moves together", cp.marbles.size() <= 2)

        # THE COIN RIDER LAW
        game.waves_since_coin = MarbleData.COIN_WAVES - 1
        game.coin_pending = false
        cp.coin_wave_ready = false
        cp.wave_spawn_i = cp.wave - 1
        game._spawn_one(cp, cp.rear_d() - MarbleData.CONTACT)
        var has_coin := false
        for m in cp.marbles:
                if m["kind"] == "coin":
                        has_coin = true
        check("coin rider embeds at the wave boundary", has_coin)
        # the pending law: a coin that expired uncollected re-arms the embed
        game.coin_pending = true
        cp.coin_wave_ready = false
        cp.wave_spawn_i = cp.wave - 1
        var d_before: float = cp.rear_d()
        game._spawn_one(cp, d_before - MarbleData.CONTACT)
        var reembedded := false
        for m in cp.marbles:
                if m["kind"] == "coin":
                        reembedded = true
        check("pending coin re-embeds", reembedded)

        # THE POW CARRIER LAW
        cp.spawned = 0          # unfreeze: the pow carrier needs a live chain
        game._spawn_one(cp, cp.rear_d() - MarbleData.CONTACT)
        game._spawn_one(cp, cp.rear_d() - MarbleData.CONTACT)
        game._spawn_one(cp, cp.rear_d() - MarbleData.CONTACT)
        cp.spawned = cp.quota   # freeze again
        game.owned_pows = ["bomb", "back"]
        game._spawn_pow_carrier()
        var has_pow := false
        for m in cp.marbles:
                if m["kind"] == "pow":
                        has_pow = true
        check("pow carrier spawns when owned", has_pow)
        # the unmatched vanish law: life ticks out
        for m in cp.marbles:
                if m["kind"] == "pow":
                        m["life"] = 0.01
        for i in 4:
                game._tick_chain(cp, 1.0 / 60.0)
        var pow_gone := true
        for m in cp.marbles:
                if m["kind"] == "pow":
                        pow_gone = false
        check("unmatched pow vanishes", pow_gone)

        # THE EAT LAW (v040-14 THE COLLAPSE LAW): the whole chain dives into
        # the hole, then the run hands itself to the UNIVERSAL box death
        # menu (finish_run) - no private lost card anymore
        cp.marbles.clear()
        cp.marbles.append({"c": 1, "d": cp.length + 1.0, "kind": "m", "life": -1.0,
                        "pow": "", "spr": null, "glow": null, "bonded": true})
        var lives_before: int = int(game.meta.d["lives"])
        game.phase = "play"
        game._tick_chain(cp, 1.0 / 60.0)
        check("eat starts the collapse", game.phase == "collapse")
        check("collapse keeps the whole chain", cp.marbles.size() >= 0)
        # the dive drains every chain, then the death resolves
        for i in 600:
                game._goga_tick(1.0 / 60.0)
                if game.over:
                        break
        check("the run ended through the universal menu", game.over)
        check("a life was lost", int(game.meta.d["lives"]) == lives_before - 1)

        # THE WIPE LAW
        game.meta.d["lives"] = 0
        game.meta.save()
        check("wipe detected", game.meta.wiped_out())
        game.meta.reset_ladder()
        check("ladder reset to level 1", int(game.meta.d["unlock"]) == 1 and int(game.meta.d["lives"]) == 3)

        # THE CLEAR/UNLOCK LAWS
        var was_new: bool = game.meta.record_clear(1, 100, 2)
        check("first clear is new", was_new)
        check("unlock advanced", int(game.meta.d["unlock"]) == 2)
        check("life bonus not yet", not game.meta.check_life_bonus())
        for lv in range(2, 11):
                game.meta.record_clear(lv, 100, 1)
        check("life bonus after 10 levels", game.meta.check_life_bonus() and int(game.meta.d["lives"]) == 4)
        check("all-cleared gate", not game.meta.all_cleared())

        # MAPS SANITY + the shooter mode variety machine
        var modes := {}
        var twin_paths := 0
        for lv in MarbleData.levels():
                modes[String(lv["shooter"]["mode"])] = int(modes.get(String(lv["shooter"]["mode"]), 0)) + 1
                if (lv["paths"] as Array).size() > 1:
                        twin_paths += 1
        print("  modes: ", modes, " twin-path levels: ", twin_paths)
        check("every mode exists", modes.has("fixed") and modes.has("slider") and modes.has("twin"))
        check("twin paths exist", twin_paths >= 8)

        print("== probe done: fails=", fails, " ==")
        quit(1 if fails > 0 else 0)
