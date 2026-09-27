extends Node
## qa_v0414_laws - the v040-14 law battery: the owner's report worked to
## the bone. Covers: the dev-sheet EXTRAS gating, the marble entry law
## (hide behind the entry, grow in) and the idol facing law, the rock
## CHAOS BOUNCE (never settles, always beatable), and the deathworm
## STAY-OPEN shop law. Run: godot --headless --path . res://tests/qa_v0414_laws.tscn

var fails := 0
var _total := 0
var G = null

func ck(name: String, ok: bool) -> void:
        _total += 1
        print(("[PASS] " if ok else "[FAIL] ") + name)
        if not ok:
                fails += 1

func _boot(script_path: String, id: String):
        Box.reset_all()
        var g = (load(script_path) as GDScript).new()
        g.game_id = id
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        return g

func angle_diff(a: float, b: float) -> float:
        return wrapf(a - b, -PI, PI)

func _ready() -> void:
        await get_tree().create_timer(0.3).timeout
        print("=== qa_v0414_laws ===")

        # ------------------------------------------------ the EXTRAS law
        Box.dev_set_cheat("extras", 0)
        Box.dev_set_cheat("x_marble_unlock_all", 0)
        ck("EXTRAS: parent 0 gates everything",
                Box.extra_on("marble", "unlock_all") == false)
        Box.dev_set_cheat("x_marble_unlock_all", 1)
        ck("EXTRAS: child 1 alone is not enough",
                Box.extra_on("marble", "unlock_all") == false)
        Box.dev_set_cheat("extras", 1)
        ck("EXTRAS: parent 1 + child 1 opens",
                Box.extra_on("marble", "unlock_all") == true)
        ck("EXTRAS: other games unaffected",
                Box.extra_on("rockbreaker", "unlock_all") == false)
        var mreg: Dictionary = GameReg.get_game("marble")
        var has_extras: bool = (mreg.get("extras", []) as Array).size() > 0
        ck("EXTRAS: the registry carries the marble extra", has_extras)

        # --------------------------------------- the marble entry law
        var g = await _boot("res://game/games/marble/marble.gd", "marble")
        g._start_level(1, false, 1)   # the spiral: an ON-SCREEN hole entry
        var cp = g.chains[0]
        g._begin_play()
        var m := {"c": 1, "d": -MarbleData.CONTACT * 2.0, "kind": "m",
                "life": -1.0, "pow": "", "spr": null, "glow": null, "bonded": true}
        cp.marbles.push_front(m)
        cp.ensure_sprite(m)
        cp.sync_sprites(1.0 / 60.0)
        ck("ENTRY: a marble behind the entry hides", m["spr"].visible == false)
        m["d"] = g.GROW_IN * 0.5
        cp.sync_sprites(1.0 / 60.0)
        ck("ENTRY: crossing the entry it grows (scale < 1)",
                m["spr"].visible and m["spr"].scale.x < 1.0)
        m["d"] = 400.0
        cp.sync_sprites(1.0 / 60.0)
        ck("ENTRY: full size on the road", m["spr"].scale.x == 1.0)

        # ------------------------------------- the idol facing law
        var hole: Node2D = g.holes[0]
        var cpv: Vector2 = (cp.pts[cp.pts.size() - 1]
                - cp.pts[cp.pts.size() - 2]).normalized()
        var want := atan2(cpv.x, -cpv.y)
        ck("IDOL: the head rotates to face the incoming chain (any angle)",
                absf(angle_diff(hole.rotation, want)) < 0.02)

        # -------------------------------------- the rock chaos bounce
        G = await _boot("res://game/games/rockbreaker/rockbreaker.gd",
                "rockbreaker")
        G.phase = "play"              # a live round: the physics run
        G._add_rock(300.0 * G.us, 300.0 * G.us, 220.0 * G.us, 0.0, 2, 30, 0)
        var rk: Dictionary = G.rocks[0]
        var kicks: Array = []
        var prev_vy := 0.0
        for i in 2400:
                G._rock_physics(1.0 / 60.0)
                if i > 0 and prev_vy > 0.0 and float(rk["vy"]) < 0.0:
                        kicks.append(absf(float(rk["vy"])))
                prev_vy = float(rk["vy"])
        ck("CHAOS: the rock bounced many times", kicks.size() >= 6)
        var varied := false
        if kicks.size() > 0:
                var base: float = kicks[0]
                for k in kicks:
                        if absf(k - base) > 30.0 * G.us:
                                varied = true
        ck("CHAOS: every bounce re-rolls the energy (never the same)", varied)
        var never_dead := true
        for k in kicks:
                if k < G.GROUND_MIN_KICK * G.us * 0.98:
                        never_dead = false
        ck("CHAOS: no dead settle - every hop clears the min kick", never_dead)
        var beatable := true
        for k in kicks:
                if k > G.KICK_MAX * G.us * 1.01:
                        beatable = false
        ck("CHAOS: every hop stays under the beatable ceiling", beatable)
        var never_sank := true
        for rk2 in G.rocks:
                if float(rk2["y"]) > G.ground_y - float(rk2["r"]) * 0.4:
                        never_sank = false
        ck("CHAOS: the rock never sank into the ground (it exits or dances)",
                never_sank and G.rocks.size() <= 1)

        # --------------------------------- the deathworm stay-open law
        var dw = await _boot("res://game/games/deathworm/deathworm.gd",
                "deathworm")
        await get_tree().create_timer(0.4).timeout
        Box.dev_set_cheat("gogacoins", 1)   # the EXTREME wallet
        var sheets_before: int = dw.sheet_open_count()
        dw._open_shop()
        await get_tree().process_frame
        ck("SHOP: the shop opened over the running game",
                dw._shop_open and dw.sheet_open_count() == sheets_before + 1)
        var pow_id: String = String(dw.POWS[0]["k"])
        var owned_before: bool = dw.meta.owns_pow(pow_id)
        dw._buy_pow(pow_id)
        await get_tree().process_frame
        ck("SHOP: the buy landed", dw.meta.owns_pow(pow_id) or owned_before)
        ck("SHOP: the buy did NOT quit the shop by itself",
                dw._shop_open and dw.sheet_open_count() == sheets_before + 1)
        var place_id: String = ""
        for pid in dw.PLACES:
                if not dw.meta.owns_place(String(pid)) \
                                and int(dw.PLACES[pid]["price"]) > 0:
                        place_id = String(pid)
                        break
        if place_id != "":
                dw._buy_place(place_id)
                await get_tree().process_frame
        ck("SHOP: the place buy kept the shop open",
                dw._shop_open and dw.sheet_open_count() == sheets_before + 1)
        var wv_before: int = dw.sheet_open_count()
        dw._open_worms()
        await get_tree().process_frame
        ck("WORMS: the menu opened (stacked)",
                dw._worms_open and dw.sheet_open_count() == wv_before + 1)
        dw.sheet_pop()
        await get_tree().process_frame
        ck("SHEETS: the stack unwinds cleanly",
                dw.sheet_open_count() == wv_before)

        print("=== qa_v0414_laws: %d checks, %d fails ===" % [_total, fails])
        get_tree().quit(1 if fails > 0 else 0)
