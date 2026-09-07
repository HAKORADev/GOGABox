extends Node
## GEOMETRY FLASH probe (v0.3.6) - the deterministic battery.
## Runs headless: godot --headless --path . res://tests/gf_probe.tscn
## Exit 0 = every owner law holds.

var checks := 0
var fails := 0
var G: GogaGame = null

func ck(cond: bool, what: String) -> void:
        checks += 1
        if cond:
                print("[PASS] ", what)
        else:
                fails += 1
                print("[FAIL] ", what)

func _boot() -> void:
        if G != null and is_instance_valid(G):
                G.queue_free()
                await get_tree().create_timer(0.3).timeout
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        get_window().size = Vector2i(1920, 1080)
        await get_tree().create_timer(0.2).timeout
        G = load("res://game/games/geometry/geometry.gd").new()
        G.game_id = "geometry"
        process_mode = Node.PROCESS_MODE_ALWAYS
        add_child(G)
        await get_tree().create_timer(0.8).timeout
        G.probe_reset(20260908)

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout

func _run() -> void:
        print("=== gf_probe (v0.3.6) ===")
        # ------------------------------------------------ boot first
        await _boot()
        # ------------------------------------------------ the layout law
        ck(G.ROOF_Y == 300.0 and G.L3_Y == 460.0 and G.L2_Y == 620.0
                and G.L1_Y == 780.0 and G.GROUND_Y == 940.0,
                "THE LAYOUT LAW: roof 300 / lines 460-620-780 / ground 940 (the drawing)")
        var apex: float = G.JUMP_V * G.JUMP_V / (2.0 * G.GRAV)
        ck(G.GROUND_Y - apex < G.L1_Y,
                "THE APEX LAW: a ground jump clears line 1 (%.1f < %.1f)" % [G.GROUND_Y - apex, G.L1_Y])
        ck(G.GROUND_Y - apex > G.L2_Y,
                "THE APEX LAW: ...and only line 1 - no double-clear from the ground")
        ck(G.L1_Y - apex < G.L2_Y and G.L2_Y - apex < G.L3_Y,
                "THE APEX LAW: line hops chain upward one rung at a time")
        ck(G.CELL < (G.L1_Y - (G.L2_Y + G.LINE_TH)),
                "THE FIT LAW: the square travels between the lines")
        # ------------------------------------------------ the standpoint
        ck(G.phase == "run", "the probe boots straight into the run")
        ck(G.stand_x < _vp().x * 0.5,
                "THE STANDPOINT LAW: the square lives BEFORE center (%.0f < %.0f)" % [G.stand_x, _vp().x * 0.5])
        ck(absf(G.stand_x - _vp().x * 0.32) < 1.0, "the standpoint sits at 0.32w exactly")
        # ------------------------------------------------ the tap laws
        G.paused = false              # the verb needs the live gate
        G.player["x"] = G.stand_x
        G.player["ground"] = true
        G.mechanic = "normal"
        G._do_action()
        ck(G.player["vy"] == -G.JUMP_V * G.us and not G.player["ground"],
                "THE TAP LAW: normal jump = the GD hop")
        var vy_mid: float = -300.0
        G.player["vy"] = vy_mid
        G._do_action()
        ck(G.player["vy"] == vy_mid,
                "THE TAP LAW: a mid-air tap does nothing in NORMAL")
        G.mechanic = "flip"
        G._do_action()
        ck(G.player["g"] == -1,
                "THE FLIP LAW: a mid-air tap inverts gravity (air flips allowed)")
        G.mechanic = "sticky"
        var g_before: int = G.player["g"]
        G._do_action()
        ck(G.player["g"] == g_before,
                "THE STICKY LAW: a mid-air tap is ignored")
        G.player["ground"] = true
        G.player["vy"] = 0.0
        G._do_action()
        ck(G.player["g"] == -g_before and G.player["vy"] == G.JUMP_V * G.us,
                "THE STICKY LAW: the surface tap jumps AND flips with the leap")
        G.paused = true               # back to the probe clock
        # ------------------------------------------------ the spin law
        G.probe_reset(7)
        G.mechanic = "normal"
        G.player["ground"] = true
        G.player["g"] = 1
        G._jump()
        var spin_total: float = G.spin_total
        ck(spin_total > 0.2 and spin_total < 1.5,
                "THE SPIN LAW: the flight prediction sampled a real landing (%.2fs)" % spin_total)
        var steps := int(spin_total / 0.016) + 4
        var turned := false
        for i in steps:
                G._spin_tick(0.016)
                if G.player["rot"] >= 88.0:
                        turned = true
                        break
        ck(turned, "THE SPIN LAW: the square rotated its 90 degrees over the flight")
        ck(absf(fmod(G.player["rot"], 90.0)) < 3.0 or absf(fmod(G.player["rot"], 90.0)) > 87.0,
                "THE SPIN LAW: the rotation settles ON the 90-degree grid")
        # ------------------------------------------------ landing + support
        G.probe_reset(11)
        _surgery_line_under_player(G.L1_Y)
        G.player["y"] = (G.L1_Y - G.HALF - 2.0) * G.us
        G.player["vy"] = 200.0
        G.player["ground"] = false
        var landed_y := -1.0
        for i in 40:
                G._physics(1.0 / 60.0)
                if G.player["ground"]:
                        landed_y = G.player["y"]
                        break
        ck(landed_y > 0.0 and absf(landed_y + G.HALF * G.us - G.L1_Y * G.us) < 2.0,
                "THE SURFACE TRUTH: the square lands ON line 1 exactly")
        # walk off an edge = unsupported = falls
        G.probe_reset(13)
        G.gsegs = [{"x0": -3000.0, "x1": 100.0, "spr": null}]
        G.rsegs = [{"x0": -3000.0, "x1": 5000.0, "spr": null}]
        G.player["ground"] = true
        G.player["y"] = (G.GROUND_Y - G.HALF) * G.us
        G.world_x = 1500.0                       # the player now floats past the seg end
        G._support_check()
        ck(not G.player["ground"],
                "THE SUPPORT TRUTH: walking off an edge starts the fall honestly")
        # the bonk: rise into a line underside from below
        G.probe_reset(17)
        _surgery_line_under_player(G.L1_Y)
        G.player["ground"] = false
        G.player["y"] = (G.L1_Y + 200.0) * G.us
        G.player["vy"] = -900.0
        var min_head := 1e9
        for i in 30:
                G._physics(1.0 / 60.0)
                min_head = minf(min_head, G.player["y"] - G.HALF * G.us)
        ck(min_head >= (G.L1_Y + G.LINE_TH) * G.us - 3.0,
                "THE BONK TRUTH: the head never passes the line's underside")
        # THE SPACE TRUTH: landings respect the scroll offset - ground that
        # scrolled away 40000px ago must never catch the square again
        G.probe_reset(41)
        G.world_x = 40000.0
        G.player["ground"] = false
        G.player["y"] = (G.GROUND_Y - G.HALF) * G.us
        G.player["vy"] = 0.0
        for i in 16:
                G._physics(1.0 / 60.0)
        ck(G.player["y"] > G.GROUND_Y * G.us and not G.player["ground"],
                "THE SPACE TRUTH: the far-behind ground cannot catch the square")
        # ------------------------------------------------ the pit + edge + hazard
        G.probe_reset(19)
        G.gsegs = [{"x0": -3000.0, "x1": 100.0, "spr": null}]
        G.rsegs = [{"x0": -3000.0, "x1": 5000.0, "spr": null}]
        G.player["ground"] = false
        G.player["y"] = (G.GROUND_Y + G.CELL) * G.us
        G.player["vy"] = 500.0
        G._pit_check()
        ck(G.over_gate, "THE PIT LAW: falling into an opened stretch ends the run")
        await _wait(1.0)
        G.probe_reset(23)
        G.player["x"] = -G.HALF * G.us - 60.0
        G._physics(1.0 / 60.0)
        ck(G.over_gate, "THE EDGE LAW: pushed off-screen by a block = the end")
        await _wait(1.0)
        G.probe_reset(29)
        G._add_hazard(G.world_x + G.stand_x / G.us, G.GROUND_Y - G.HALF, "spike")
        G._physics(1.0 / 60.0)
        ck(G.over_gate, "THE HAZARD LAW: touching the spike ends the run")
        await _wait(1.0)
        # ------------------------------------------------ the pusher law
        G.probe_reset(31)
        var push_x: float = G.world_x + G.stand_x / G.us      # dead center overlap
        G._add_pusher(push_x, G.GROUND_Y, false, true)
        var x0: float = G.player["x"]
        for i in 12:
                G.player["ground"] = true
                G.player["y"] = (G.GROUND_Y - G.HALF) * G.us
                G._physics(1.0 / 60.0)
        ck(G.player["x"] < x0 - 20.0,
                "THE PUSHER LAW: the block rides the square back (%.1f -> %.1f)" % [x0, G.player["x"]])
        ck(G.over_gate == false,
                "THE PUSHER LAW: the shove is not death")
        # standing on top never shoves
        G.probe_reset(37)
        var px2: float = G.world_x + G.stand_x / G.us
        G._add_pusher(px2, G.GROUND_Y, false, true)
        G.player["x"] = G.stand_x
        G.player["ground"] = true
        G.player["y"] = (G.GROUND_Y - G.CELL - G.HALF) * G.us   # feet ON the pusher top
        var x_top: float = G.player["x"]
        G._pusher_push(1.0 / 60.0)
        ck(absf(G.player["x"] - x_top) < 0.5,
                "THE PUSHER LAW: standing on top is safe - no shove")
        # ------------------------------------------------ the generator fairness
        var fair_pits := true
        var fair_land := true
        var fair_push := true
        var calm_open := true
        for s in range(40):
                G.probe_reset(1000 + s)
                # pits jumpable + a landing >= 2 cells after each
                var gaps: Array = []
                var sorted_gs: Array = G.gsegs.duplicate()
                sorted_gs.sort_custom(func(a, b): return a["x0"] < b["x0"])
                for i in sorted_gs.size() - 1:
                        var gap: float = sorted_gs[i + 1]["x0"] - sorted_gs[i]["x1"]
                        if gap > 4.0:
                                gaps.append([gap, sorted_gs[i + 1]])
                for gpair in gaps:
                        if gpair[0] > G._max_pit_cells() * G.CELL + 8.0:
                                fair_pits = false
                        if float(gpair[1]["x1"]) - float(gpair[1]["x0"]) < G.CELL * 2.0:
                                fair_land = false
                # pushers never share their window with a pit or a hazard
                for pu in G.pushers:
                        for gg in gaps:
                                if float(pu["x"]) + G.CELL > float(gg[1]["x0"]) - 8.0 and float(pu["x"]) < float(gg[1]["x1"]) + 8.0:
                                        fair_push = false
                for pu in G.pushers:
                        for h in G.hazards:
                                if absf(float(h["x"]) - float(pu["x"])) < G.CELL * 1.5 \
                                                and absf(float(h["y"]) - (float(pu["y0"]) - G.HALF)) < G.CELL:
                                        fair_push = false
        ck(fair_pits, "THE FAIRNESS LAWS: every pit is jumpable at the live speed (40 seeds)")
        ck(fair_land, "THE FAIRNESS LAWS: solid landing >= 2 cells after any pit")
        ck(fair_push, "THE FAIRNESS LAWS: a pusher never shares a window with a pit/hazard")
        G.probe_reset(55)
        var calm_ok := true
        for h in G.hazards:
                if float(h["x"]) < G.calm_until:
                        calm_ok = false
        ck(calm_ok, "THE RUNWAY LAW: the opening calm holds - no hazards inside it")
        # roof content only when it can be reached
        var roof_only_ok := true
        G.probe_reset(77)
        G.mechanic = "normal"
        G.calm_until = 0.0
        var gen_before: float = G.gen_x
        for i in 30:
                G._gen_chunk(G.gen_x)
        var last_x: float = G.gen_x
        G.probe_reset(78)
        G.mechanic = "flip"
        G.calm_until = 0.0
        for i in 60:
                G._gen_chunk(G.gen_x)
        ck(G.gen_x > last_x, "the generator stitches chunks in both modes")
        # the roof-pit check: in normal mode rsegs must be gapless
        var roof_gaps := true
        G.probe_reset(81)
        G.mechanic = "normal"
        G.calm_until = 0.0
        for i in 30:
                G._gen_chunk(G.gen_x)
        var sorted_rs: Array = G.rsegs.duplicate()
        sorted_rs.sort_custom(func(a, b): return a["x0"] < b["x0"])
        for i in sorted_rs.size() - 1:
                if float(sorted_rs[i + 1]["x0"]) - float(sorted_rs[i]["x1"]) > 4.0:
                        roof_gaps = false
        ck(roof_gaps, "THE ROOF PLAY LAW: normal mode keeps the roof gapless (it cannot be reached)")
        # ------------------------------------------------ the mechanic scheduler
        G.probe_reset(91)
        var sched_ok := true
        var durs_ok := true
        var last := "normal"
        for i in 12:
                G.mech_left = 0.001
                G._mech_clock(0.01)
                if G.mechanic == last:
                        sched_ok = false
                if not G.MECH_DURS.has(int(G.mech_left)):
                        durs_ok = false
                last = G.mechanic
        ck(sched_ok, "THE HIDDEN MECHANIC LAW: the swap never repeats the mechanic")
        ck(durs_ok, "THE HIDDEN MECHANIC LAW: the clock rolls 10/20/30/40 only")
        G.probe_reset(93)
        G.mech_left = 0.001
        var wx_before: float = G.world_x
        G._mech_clock(0.01)
        ck(G.calm_until >= G.world_x + G.speed * 1.39,
                "THE SWAP CALM LAW: the swap buys ~1.4s of breathing room")
        # ------------------------------------------------ the orbit + speed laws
        G.probe_reset(101)
        var oy: float = G.GROUND_Y - G.HALF              # DESIGN px (the API's space)
        G._add_orbit(G.world_x + G.stand_x / G.us, oy)
        var sc0: int = G.score
        G._pickups(1.0 / 60.0)
        ck(G.score == sc0 + 1, "THE ORBIT LAW: a golden orbit pays exactly +1")
        G.speed_level = 0
        G.speed = G.BASE_SPEED
        for i in 10:
                G._add_orbit(G.world_x + G.stand_x / G.us, oy)
                G._pickups(1.0 / 60.0)
        ck(absf(G.speed / G.BASE_SPEED - 1.1) < 0.001,
                "THE SPEED LAW: 10 points = exactly x1.1")
        # ------------------------------------------------ the coin law
        ck(G.COIN_DELAYS == [30, 35, 40, 45, 50],
                "THE COIN LAW table: 30/35/40/45/50 seconds")
        G.probe_reset(103)
        G.coin_timer = 0.05
        G._coin_clock(0.06)
        ck(not G.coin.is_empty(), "the GOGACoin appears when its clock fires")
        var t_after: float = G.coin_timer
        ck(t_after > 25.0 and t_after <= 50.01,
                "THE COIN LAW: the next delay rolls from the LAST APPEAR (%.0fs)" % t_after)
        # ------------------------------------------------ the shop economy
        G.probe_reset(107)
        Box.dev_set_cheat("all_owned", 0)      # the honest economy - no cheats
        Box.earn(10000)
        var wallet0: int = Box.coins()
        Box.buy_skin("geometry", "prism", int(G.SKINS["prism"]["price"]))
        ck(Box.skin_owned("geometry", "prism"), "the shop: a buy OWNS the skin")
        ck(Box.skin_on("geometry") == "prism",
                "the skin law: a buy wears it at once (the hopper precedent)")
        Box.buy_item("geometry", "theme", "violet", int(G.THEMES["violet"]["price"]))
        ck(Box.item_owned("geometry", "theme", "violet"), "the shop: a buy OWNS the theme")
        var spent_a: int = wallet0 - Box.coins()
        ck(spent_a == int(G.SKINS["prism"]["price"]) + int(G.THEMES["violet"]["price"]),
                "the wallet: skin+theme prices left exactly (%d)" % spent_a)
        # THE BUY-ONLY LAW through the game's own path (a fresh theme)
        G.probe_reset(108)
        Box.dev_set_cheat("all_owned", 0)
        Box.earn(10000)
        var wore_solar: bool = G._buy_theme("solar")
        ck(wore_solar and Box.item_owned("geometry", "theme", "solar"),
                "the law path: _buy_theme buys the theme")
        ck(Box.item_on("geometry", "theme") != "solar",
                "THE BUY-ONLY LAW: a theme buys WITHOUT retheming the live world")
        Box.equip_item("geometry", "theme", "solar")
        ck(Box.item_on("geometry", "theme") == "solar", "the theme: LIGHT IT is its own tap")
        # tails: buy ON, toggle forever
        var wallet1: int = Box.coins()
        Box.buy_item("geometry", "tail", "gold", int(G.TAILS["gold"]["price"]))
        ck(Box.item_owned("geometry", "tail", "gold"), "the shop: a buy OWNS the tail")
        ck(Box.item_on("geometry", "tail") == "gold", "tails: a buy turns it ON")
        Box.unequip_item("geometry", "tail")
        ck(Box.item_on("geometry", "tail") != "gold", "tails: the toggle turns OFF")
        Box.equip_item("geometry", "tail", "gold")
        ck(Box.item_on("geometry", "tail") == "gold", "tails: the toggle turns ON again")
        ck(wallet1 - Box.coins() == int(G.TAILS["gold"]["price"]),
                "the wallet: the tail price left exactly (%d)" % (wallet1 - Box.coins()))
        # ------------------------------------------------ the tables
        ck(G.THEMES.size() == 3 and G.SKINS.size() == 5 and G.TAILS.size() == 6,
                "the shop stock: 3 themes / 5 skins / 6 tails (the owner's caps)")
        ck(G.THEMES["midnight"]["price"] == 0 and G.SKINS["classic"]["price"] == 0
                and G.TAILS["none"]["price"] == 0,
                "the free defaults: midnight + classic + none")
        print("RESULT: %d checks, %d failures" % [checks, fails])
        print("RESULT: %s" % ("ALL LAWS HOLD" if fails == 0 else "LAWS BROKEN"))
        get_tree().quit(0 if fails == 0 else 1)

func _vp() -> Vector2:
        return get_viewport().get_visible_rect().size

## Surgery: exactly ONE line segment right under the player's column.
func _surgery_line_under_player(y: float) -> void:
        G.lines = []
        var px: float = G.world_x + G.stand_x / G.us
        G._add_line(px - 500.0, px + 500.0, y)

func _ready() -> void:
        _run()
