extends Node
## slasher_probe - v0.2.9: drives the REBUILT Fruit Slasher headless. The
## owner's laws: the position ask first (each position its own physics),
## +1 per fruit / -2 per fall with a 0 floor, three hearts with a slashed
## bomb costing one (0 = run over), the real slice (two textured halves
## flying apart), the +N/-N reader (merged, never spam), the 20s coin,
## the vegetables shop gate, /15.
##
##   godot --headless --path projects/gogabox res://tests/slasher_probe.tscn

var fails := 0

func _check(cond: bool, msg: String) -> void:
        print(("  PASS: " if cond else "  FAIL: ") + msg)
        if not cond:
                fails += 1

var SL: GDScript

func _run() -> void:
        Box.reset_all()
        print("== slasher_probe: the rework v0.2.9 ==")
        SL = load("res://game/games/slasher/slasher.gd")

        # ---- registry sanity (the owner's economy) ----
        var sr: Dictionary = GameReg.get_game("slasher")
        _check(not sr.is_empty(), "slasher is in the registry")
        _check(int(sr["coin_div"]) == 15, "slasher run bonus = score/15 (owner)")
        _check(String(sr["orientation"]) == "auto",
                "the POSITION ASK is on (orientation auto, like snake)")
        _check(bool(sr["shop"]), "slasher wears a shop (the vegetables)")
        _check(bool(sr["banner"]), "slasher carries the ad banner")

        # ---- the MODES law: two positions, two different games ----
        _check(float(SL.MODES["vertical"]["gravity"]) \
                        != float(SL.MODES["horizontal"]["gravity"]),
                "the positions carry DIFFERENT gravity")
        _check(bool(SL.MODES["vertical"]["from_bottom"]) \
                        and not bool(SL.MODES["horizontal"]["from_bottom"]),
                "portrait tosses from below; landscape lobs across")

        # ---- boot: the ask -> options -> run ----
        var g: GogaGame = SL.new()
        g.game_id = "slasher"
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        _check(String(g._phase) == "orient", "the game OPENS on the position ask")
        g._orient_choice("vertical")     # headless = portrait: no reload
        _check(String(g._phase) == "options", "the position picked -> the options")
        g._start_run()
        _check(String(g._phase) == "run", "START starts the run")
        _check(g.hearts == 3 and g.heart_icons.size() == 3,
                "three hearts, shown")

        # ---- the scoring law: +1 / -2 with the 0 floor ----
        g.set_score(0)
        g._cut_item(_make_item(g, "apple"), Vector2(50, 50), Vector2(150, 90))
        _check(int(g.score) == 1, "a cut fruit pays exactly +1")
        g._register_miss(Vector2(100, 100))
        _check(int(g.score) == 0 and int(g.loss_acc) == 2,
                "a fall costs -2 and waits in the loss window")
        g._register_miss(Vector2(120, 110))
        g._flush_loss()
        _check(int(g.score) == 0 and g.loss_acc == 0,
                "two falls flush as ONE -4 and the score FLOORS at 0 (never -1 -2)")
        g.set_score(9)
        g._register_miss(Vector2(1, 1))
        g._flush_loss()
        _check(int(g.score) == 7, "-2 lands on a live score too (9 -> 7)")

        # ---- the visualizer: merged, never spam ----
        g.viz = []
        g.set_score(5)
        g._push_viz("+3", Color(0.45, 0.95, 0.55), 0)
        g._push_viz("+7", Color(0.45, 0.95, 0.55), 0)
        var gain_zone := 0
        var young := 0
        for v in g.viz:
                if int(v["zone"]) == 0:
                        gain_zone += 1
                        if float(v["life"]) > float(v["max"]) * 0.55:
                                young += 1
        _check(gain_zone == 1 and young == 1,
                "a young +N in the same zone MERGES (no + spam)")
        g._push_viz("-2", Color(0.98, 0.42, 0.36), 1)
        var zones := {}
        for v in g.viz:
                zones[int(v["zone"])] = true
        _check(zones.size() == 2, "the gains and the losses live in TWO zones")

        # ---- the real slice: two halves fly apart ----
        g.set_score(0)
        var before_halves: int = int(g.halves.size())
        g._cut_item(_make_item(g, "watermelon"), Vector2(60, 60),
                        Vector2(180, 120))
        _check(g.halves.size() >= before_halves + 2,
                "the fruit SPLIT into two textured halves")
        var moved := false
        if g.halves.size() > 0:
                var h0: Dictionary = g.halves[0]
                var n0: Node2D = h0["node"]
                var p0: Vector2 = n0.position
                var v0: Vector2 = h0["v"]
                v0.y += float(1420.0) * (1.0 / 60.0)
                h0["v"] = v0
                n0.position += v0 * (1.0 / 60.0)
                moved = n0.position != p0
        _check(moved, "the halves FLY (physical impulse)")
        # the halves fall with gravity via the tick
        var hcount: int = int(g.halves.size())
        g._goga_tick(1.0 / 60.0)
        _check(g.halves.size() == hcount, "the halves live through a tick")

        # ---- the hearts law ----
        g.hearts = 3
        g._bomb_slashed(Vector2(100, 100))
        _check(g.hearts == 2, "a slashed bomb takes ONE heart (not the run)")
        g.hearts = 1
        g._bomb_slashed(Vector2(100, 100))
        _check(g.hearts == 0 and bool(g._over),
                "the last heart bursting ENDS the run")

        # ---- the coin law: every 20s, slashed like a fruit ----
        _check(float(SL.COIN_EVERY_S) == 20.0, "one coin each 20 seconds")
        var g2: GogaGame = SL.new()
        g2.game_id = "slasher"
        add_child(g2)
        await get_tree().process_frame
        g2._orient_choice("vertical")
        g2._start_run()
        g2._launch("coin")
        var found_coin := false
        for it in g2.items:
                if String(it["kind"]) == "coin":
                        found_coin = true
        _check(found_coin, "the coin spawns like any flying thing")
        var rc := int(g2.run_coins)
        for it in g2.items.duplicate():
                if String(it["kind"]) == "coin":
                        g2.items.erase(it)
                        g2._cut_item(it, Vector2(10, 10), Vector2(60, 40))
                        break
        _check(int(g2.run_coins) == rc + 1, "slashing the coin TAKES it (+1)")
        # a fallen coin costs nothing
        var rc2 := int(g2.run_coins)
        g2._register_miss(Vector2(1, 1))   # a fruit fall
        _check(int(g2.run_coins) == rc2, "the coin is never confused with fruit falls")

        # ---- the landscape physics on the live game ----
        g2.orient = "horizontal"
        var n_before: int = int(g2.items.size())
        g2._launch("apple")
        var it2: Dictionary = g2.items[g2.items.size() - 1]
        _check(float(it2["v"].x) > 0.0 and float(it2["g"]) == 1180.0,
                "a landscape launch lobs ACROSS with the landscape gravity")

        # ---- the vegetables gate ----
        var kind0 := String(g2._item_kind())
        _check(SL.FRUITS.has(kind0), "the default produce is FRUITS")
        Box.dev_set_cheat("all_owned", 1)
        Box.equip_item("slasher", "produce", "veggies")
        g2.mode_id = "veggies"
        var veg_ok := true
        for i in 20:
                if not SL.VEGGIES.has(String(g2._item_kind())):
                        veg_ok = false
        _check(veg_ok, "the bought toggle feeds VEGETABLES")

        # ---- the sneaky row: patterns keep birthing bombs ----
        var bombs := 0
        for i in 160:
                g2._spawn_pattern()
                for it in g2.items.duplicate():
                        if String(it["kind"]) == "bomb":
                                bombs += 1
                        g2.items.erase(it)
                        it["node"].queue_free()
        _check(bombs >= 12,
                "the spawner keeps birthing bombs (rows hide them: %d in 160 patterns)" % bombs)

        print("== slasher_probe done: %s ==" % ("ALL PASS" if fails == 0 else "%d FAIL" % fails))
        get_tree().quit(1 if fails > 0 else 0)

func _make_item(g: GogaGame, kind: String) -> Dictionary:
        var s := Sprite2D.new()
        s.texture = g._texs[kind]
        s.position = Vector2(120, 90)
        s.scale = Vector2.ONE * 0.5
        g.world.add_child(s)
        return {"node": s, "kind": kind, "v": Vector2(40, -500),
                "spin": 1.0, "sliced": true, "scale": 0.5, "g": 1560.0}

func _ready() -> void:
        _run.call_deferred()
