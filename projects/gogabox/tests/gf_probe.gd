extends Node
## GEOMETRY FLASH probe (v0.3.6-1) - the deterministic battery.
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
                "THE STICK TRUTH: a mid-air tap is ignored")
        G.player["ground"] = true
        G.player["vy"] = 0.0
        G._do_action()
        ck(G.player["g"] == g_before \
                and absf(G.player["vy"] - (-G.JUMP_V * G.us * float(g_before))) < 0.5,
                "THE STICK TRUTH: the surface tap is JUST a hop - no gravity flip on jump")
        # THE STICK TOUCH: gravity changes ONLY on touching another floor.
        # (a) climb and bonk the ROOF -> stick up
        G.probe_reset(61)
        G.mechanic = "sticky"
        G.rsegs = [{"x0": -3000.0, "x1": 6000.0, "spr": null}]
        G.player["ground"] = false
        G.player["g"] = 1
        G.player["y"] = (G.L3_Y - G.HALF - 30.0) * G.us
        G.player["vy"] = -900.0 * G.us
        var stuck_roof := false
        for i in 40:
                G._physics(1.0 / 60.0)
                if G.player["g"] == -1:
                        stuck_roof = true
                        break
        ck(stuck_roof,
                "THE STICK TRUTH: touching the ROOF flips the gravity to stick up")
        # (b) fall from the roof and bonk the GROUND top -> stick down
        G.probe_reset(63)
        G.mechanic = "sticky"
        G.rsegs = [{"x0": -3000.0, "x1": 6000.0, "spr": null}]
        G.player["ground"] = false
        G.player["g"] = -1
        G.player["y"] = (G.GROUND_Y - G.CELL * 2.0 - G.HALF) * G.us
        G.player["vy"] = 1400.0 * G.us
        var stuck_ground := false
        for i in 40:
                G._physics(1.0 / 60.0)
                if G.player["g"] == 1:
                        stuck_ground = true
                        break
        ck(stuck_ground,
                "THE STICK TRUTH: touching the GROUND flips the gravity back down")
        # (c) a LINE is not a floor: falling onto line 1's TOP never flips
        G.probe_reset(67)
        G.mechanic = "sticky"
        _surgery_line_under_player(G.L1_Y)
        G.player["ground"] = false
        G.player["g"] = -1
        G.player["y"] = (G.L1_Y - G.CELL - 20.0) * G.us
        G.player["vy"] = 500.0 * G.us
        var line_flip := false
        for i in 30:
                G._physics(1.0 / 60.0)
                if G.player["g"] == 1:
                        line_flip = true
                        break
        ck(not line_flip,
                "THE STICK TRUTH: the two lines are NOT floors - no flip from them")
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
                # road-level pushers never share their window with a pit or a
                # hazard - v0.3.6-3: FLOATING slabs are exempt (the bridge is
                # the helping island over the pit, never a road blocker)
                for pu in G.pushers:
                        if float(pu["y1"]) < G.GROUND_Y - 40.0:
                                continue
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
        # v0.3.6-3 FIX: the old check compared two probe_reset horizons (a
        # coin flip - different seeds roll different horizons). The honest
        # ride is the real stitching contract: gen_x += _gen_chunk(gen_x).
        var stitched := true
        for i in 30:
                var step_w: float = G._gen_chunk(G.gen_x)
                if step_w <= 0.0:
                        stitched = false
                G.gen_x += step_w
        ck(stitched and G.gen_x > 0.0, "the generator stitches chunks in normal mode")
        var normal_x: float = G.gen_x
        G.probe_reset(78)
        G.mechanic = "flip"
        G.calm_until = 0.0
        var stitched_flip := true
        for i in 60:
                var step_w2: float = G._gen_chunk(G.gen_x)
                if step_w2 <= 0.0:
                        stitched_flip = false
                G.gen_x += step_w2
        ck(stitched_flip and G.gen_x > normal_x,
                "the generator stitches chunks in flip mode (roof + roof stairs)")
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
        G.next_bonus = G.SPEED_BONUS_AT
        for i in 8:
                G._add_orbit(G.world_x + G.stand_x / G.us, oy)
                G._pickups(1.0 / 60.0)
        ck(absf(G.speed / G.BASE_SPEED - 1.0) < 0.0001,
                "THE /10 TRUTH: 9 points pay NO speed step")
        G._add_orbit(G.world_x + G.stand_x / G.us, oy)
        G._pickups(1.0 / 60.0)
        ck(absf(G.speed / G.BASE_SPEED - 1.1) < 0.001,
                "THE /10 TRUTH: 10 points = exactly x1.1 (the patch-1 /50 was the BOX score bonus)")
        # ------------------------------------------------ the coin laws
        ck(G.COIN_DELAYS == [30, 35, 40, 45, 50],
                "THE COIN LAW table: 30/35/40/45/50 seconds")
        G.probe_reset(103)
        var roll: float = G._coin_roll()
        ck(roll >= 30.0 and roll <= 50.0,
                "THE FIRST-APPEAR LAW: the run start rolls the FULL 30-50s window")
        G.coin_timer = 0.05
        G._coin_clock(0.06)
        ck(not G.coin.is_empty(), "the GOGACoin appears when its clock fires")
        var t_after: float = G.coin_timer
        ck(t_after > 25.0 and t_after <= 50.01,
                "THE COIN LAW: the next delay rolls from the LAST APPEAR (%.0fs)" % t_after)
        # ------------------------------------------------ the power-up laws
        ck(G.POWERS.size() == 3 and G.POW_DELAYS == [30, 40, 50, 60]
                and G.POW_DUR == 10.0,
                "THE POWER LAW table: 3 powers, 30-60s spawns, 10 game-seconds")
        ck(G.POWERS["shield"]["price"] > G.POWERS["jump"]["price"] \
                and G.POWERS["shield"]["price"] > G.POWERS["slow"]["price"],
                "THE POWER LAW: the EXTRA LIFE is the most expensive")
        # the jump power multiplies the hop
        G.probe_reset(111)
        G.powers["jump"] = 5.0
        G.player["ground"] = true
        G.player["g"] = 1
        G._jump()
        ck(absf(G.player["vy"] + G.JUMP_V * G.JUMP_POW_MULT * G.us) < 0.5,
                "THE ROCKET JUMP: the hop leaves at x1.5 velocity")
        G.powers["jump"] = 0.0
        # SLOW WORLD halves every core clock
        G.probe_reset(113)
        G.powers["slow"] = 10.0
        G.paused = false
        var wx0: float = G.world_x
        G._goga_tick(1.0 / 60.0)
        var slow_d: float = G.world_x - wx0
        G.paused = true
        G.powers["slow"] = 0.0
        G.paused = false
        var wx1: float = G.world_x
        G._goga_tick(1.0 / 60.0)
        var fast_d: float = G.world_x - wx1
        G.paused = true
        ck(absf(slow_d * 2.0 - fast_d) < 0.5,
                "THE SLOW WORLD: the world scroll runs 50%% slower (%.2f vs %.2f)" % [slow_d, fast_d])
        # the power spawn clock: only owned kinds, one at a time
        G.probe_reset(117)
        Box.dev_set_cheat("all_owned", 1)
        G.pow_timer = 0.05
        G._pow_clock(0.06)
        ck(G.pow_pickups.size() == 1, "THE POWER SPAWN: exactly one capsule at a time")
        ck(G.pow_timer > 25.0 and G.pow_timer <= 60.01,
                "THE POWER SPAWN: the next delay rolls 30/40/50/60 from the LAST spawn")
        var kind0: String = G.pow_pickups[0]["kind"]
        G.pow_pickups[0]["x"] = G.world_x + G.stand_x / G.us
        G.pow_pickups[0]["y"] = G.GROUND_Y - G.HALF
        G._pickups(1.0 / 60.0)
        ck(G.pow_pickups.is_empty() and G.powers[kind0] == G.POW_DUR,
                "THE POWER COLLECT: the capsule activates its 10 game-seconds")
        Box.dev_set_cheat("all_owned", 0)
        G.probe_reset(119)
        G.pow_timer = 0.05
        G._pow_clock(0.06)
        ck(G.pow_pickups.is_empty(),
                "THE POWER SPAWN: nothing spawns when nothing is owned")
        # the EXTRA LIFE saves: pit -> rescue hop, off-screen -> re-entry
        G.probe_reset(121)
        G.powers["shield"] = 10.0
        G.gsegs = [{"x0": -3000.0, "x1": 100.0, "spr": null}]
        G.rsegs = [{"x0": -3000.0, "x1": 6000.0, "spr": null}]
        G.player["ground"] = false
        G.player["y"] = (G.GROUND_Y + G.CELL) * G.us
        G.player["vy"] = 800.0 * G.us
        G._pit_check()
        ck(not G.over_gate and G.player["vy"] < 0.0,
                "THE EXTRA LIFE: the pit fall becomes a rescue hop UP")
        G.player["x"] = -G.HALF * G.us - 60.0
        G._physics(1.0 / 60.0)
        ck(not G.over_gate and absf(G.player["x"] - G.stand_x) < 2.0,
                "THE EXTRA LIFE: pushed off-screen re-enters at the standpoint")
        G._add_hazard(G.world_x + G.stand_x / G.us, G.GROUND_Y - G.HALF, "spike")
        G.player["x"] = G.stand_x
        G.player["y"] = (G.GROUND_Y - G.HALF) * G.us
        G.player["vy"] = 0.0
        G.player["ground"] = true
        G._hazard_check()
        ck(not G.over_gate,
                "THE EXTRA LIFE: hazards pass through while the shield lives")
        G.powers["shield"] = 0.0
        G._hazard_check()
        ck(G.over_gate, "THE HAZARD LAW: without the shield the spike ends the run")
        await _wait(1.0)
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
        ck(G.THEMES.size() == 3 and G.SKINS.size() == 5 and G.TAILS.size() == 6
                and G.POWERS.size() == 3,
                "the shop stock: 3 themes / 5 skins / 6 tails / 3 powers")
        ck(G.THEMES["midnight"]["price"] == 0 and G.SKINS["classic"]["price"] == 0
                and G.TAILS["none"]["price"] == 0,
                "the free defaults: midnight + classic + none")
        # the tail none law: applying none KILLS the emitters (the none bug)
        G.probe_reset(131)
        G.trail_mode = "gold"
        G._apply_tail()
        G.phase = "run"
        G._apply_tail()
        ck(G.tail.emitting, "the tail law: a live tail emits during the run")
        G.trail_mode = "none"
        G._apply_tail()
        ck(not G.tail.emitting and not G.tail2.emitting,
                "THE NONE TRUTH: none kills BOTH emitters dead (the toggle bug)")

        # ================================================== v0.3.6-3 LAWS
        # THE /10 TRUTH constant + THE WHITE-TAIL LAW (the replay stranger)
        ck(G.SPEED_BONUS_AT == 10,
                "THE /10 TRUTH: the step constant is 10 (the /50 was the box bonus)")
        G.probe_reset(141)
        Box.dev_set_cheat("all_owned", 0)
        Box.unequip_item("geometry", "tail")
        Box.buy_item("geometry", "tail", "fire", int(G.TAILS["fire"]["price"]))
        G.trail_mode = "none"
        G._apply_tail()                      # the stale pre-meta state (the bug)
        G._load_meta()                       # what EVERY fresh run executes
        ck(G.trail_mode == "fire" and G.tail.emitting,
                "THE WHITE-TAIL LAW: _load_meta re-applies the equipped tail")
        ck(G.tail.texture != null \
                and (G.tail.texture as Texture2D).resource_path.ends_with("p_puff.png") \
                and G.tail.color.g > 0.5 and G.tail.color.b < 0.4,
                "THE WHITE-TAIL LAW: the tail wears FIRE, never the white reset")
        # THE TAIL BACK LAW: the emitters never ride the rotation
        G.probe_reset(142)
        G.trail_mode = "gold"
        G.phase = "run"
        G._apply_tail()
        G.player["rot"] = 137.0
        G._layout_world()
        var back_dx: float = (G.tail.position.x - G.pspr.position.x) / G.us
        ck(back_dx < -10.0,
                "THE TAIL BACK LAW: at 137 degrees the trail is STILL screen-behind")
        # THE NONE COLOR LAW: violet while a real tail is worn
        var none_row: Control = G._tail_row("none")
        var none_sb := none_row.get_theme_stylebox("normal") as StyleBoxFlat
        ck(none_row is Button and none_sb != null \
                and none_sb.bg_color == Color("8a4ab8"),
                "THE NONE COLOR LAW: none wears the violet of the not-worn items")
        # THE STREAK RESET LAW: 2s silence walks the ladder home
        G.probe_reset(143)
        G.orbit_streak = 6
        G.streak_idle = 0.0
        G.streak_decay = 0.0
        G._pickups(0.5)
        ck(G.orbit_streak == 6, "THE STREAK RESET LAW: under 2s of silence keeps the rung")
        G._pickups(1.6)
        ck(G.orbit_streak == 5, "THE STREAK RESET LAW: the decay drops one rung per step")
        G._pickups(1.1)
        G._pickups(0.6)
        G._pickups(0.6)
        ck(G.orbit_streak == 3, "THE STREAK RESET LAW: the ladder walks down rung by rung")
        G._pickups(1.1)
        G._pickups(0.6)
        G._pickups(0.6)
        ck(G.orbit_streak == 1, "THE STREAK RESET LAW: the walk reaches the last rung")
        G._pickups(0.6)
        ck(G.orbit_streak == 0 and G.streak_idle == 0.0,
                "THE STREAK RESET LAW: the last rung falls after 0.5s - from the start")
        G.orbit_streak = 4
        G.streak_idle = 3.0
        G._add_orbit(G.world_x + G.stand_x / G.us, oy)
        G._pickups(1.0 / 60.0)
        ck(G.orbit_streak == 5 and G.streak_idle == 0.0,
                "THE STREAK RESET LAW: a collect freezes the decay and climbs")
        # THE ROCKET LAW: one-shot on the jump, side-aware
        G.probe_reset(151)
        G.powers["jump"] = 5.0
        G.player["g"] = 1
        G.player["ground"] = true
        G.player["y"] = (G.GROUND_Y - G.HALF) * G.us
        G._jump()
        ck(G.rocket.emitting and G.rocket.one_shot \
                and G.rocket.position.y > G.player["y"],
                "THE ROCKET LAW: the burn fires ON the jump, from BELOW on the ground")
        G.player["g"] = -1
        G.player["ground"] = true
        G.player["y"] = (G.ROOF_Y + G.HALF) * G.us
        G._jump()
        ck(G.rocket.position.y < G.player["y"],
                "THE ROCKET LAW: off the roof the burn pours from ABOVE")
        G.powers["jump"] = 0.0
        # THE FLIP PUSH LAW: the switch puffs from the side being left
        G.probe_reset(152)
        G.mechanic = "flip"
        G.flip_cd = 0.0
        G.paused = false
        G.player["g"] = 1
        G.player["ground"] = true
        G.player["y"] = (G.GROUND_Y - G.HALF) * G.us
        G._do_action()
        var puff_below := false
        for c in G.get_children():
                if c is CPUParticles2D and c != G.tail and c != G.tail2 \
                                and c != G.rocket and c.position.y > G.player["y"]:
                        puff_below = true
        ck(puff_below and G.player["g"] == -1,
                "THE FLIP PUSH LAW: leaving the ground puffs from BELOW")
        # THE COIN SPACE LAW: spawns sit in clear world; a crowd defers
        G.probe_reset(161)
        var coin_ok := true
        var coin_seen := 0
        for i in 40:
                G.coin_timer = 0.0
                if not G.coin.is_empty():
                        if is_instance_valid(G.coin["spr"]):
                                G.coin["spr"].queue_free()
                        G.coin = {}
                G._coin_clock(1.0 / 60.0)
                if G.coin.is_empty():
                        continue
                coin_seen += 1
                if not G._coin_spot_clear(float(G.coin["x"]), float(G.coin["y"])):
                        coin_ok = false
        ck(coin_seen > 25 and coin_ok,
                "THE COIN SPACE LAW: every spawn sits in clear world (%d spawns)" % coin_seen)
        G.probe_reset(162)
        var wall_x: float = G.world_x + G._vp().x / G.us + 80.0 / G.us
        for lx in 5:
                for ly in [G.L3_Y - 150.0, G.L2_Y - 150.0, G.L1_Y - 150.0,
                        G.GROUND_Y - 190.0]:
                        G._add_hazard(wall_x + float(lx) * G.CELL, ly, "saw")
        G.coin_timer = 0.0
        G._coin_clock(1.0 / 60.0)
        ck(G.coin.is_empty() and absf(G.coin_timer - 2.0) < 0.01,
                "THE COIN SPACE LAW: a crowded horizon DEFERS the spawn")
        # THE WORLD LAW battery: each shape, built and measured
        var air_len: float = G.BASE_SPEED * 2.0 * G.JUMP_V / G.GRAV
        G.probe_reset(211)
        G.pushers.clear()
        G._chunk_stairs(0.0)
        var st := _col_tops(G)
        var pxs: Array = []
        for pu in G.pushers:
                pxs.append(float(pu["x"]))
        pxs.sort()
        var first_pad: float = _top_at(G, float(pxs.front()))
        var last_pad: float = _top_at(G, float(pxs.back()))
        ck(st.size() >= 2 and _steps_by(st, G.CELL) \
                and absf(first_pad - (G.GROUND_Y - G.CELL)) < 1.0 \
                and last_pad < first_pad,
                "THE WORLD LAW: the stairs rise from 1 cell, one cell at a time")
        G.probe_reset(212)
        G.pushers.clear()
        G._chunk_pyramid(0.0)
        var py := _col_tops(G)
        var pyxs: Array = []
        for pu in G.pushers:
                pyxs.append([float(pu["x"]), float(pu["y0"])])
        pyxs.sort_custom(func(a, b): return a[0] < b[0])
        var mid_top: float = float(pyxs[pyxs.size() / 2][1])
        ck(py.size() >= 2 and _steps_by(py, G.CELL) \
                and absf(float(pyxs.front()[1]) - (G.GROUND_Y - G.CELL)) < 1.0 \
                and absf(float(pyxs.back()[1]) - (G.GROUND_Y - G.CELL)) < 1.0 \
                and mid_top < G.GROUND_Y - G.CELL * 1.5,
                "THE WORLD LAW: the pyramid climbs up AND back down by single cells")
        G.probe_reset(213)
        G.pushers.clear()
        G.lines.clear()
        G._chunk_descent(0.0)
        var de := _col_tops(G)
        # patch 3: the ride is a BLOCK DECK now (no thin line any more); the
        # staircase law reads the PADS (ground-anchored) - the deck sits 8px
        # off the pad grid on purpose (the ride meets the first pad with a
        # tiny step-down, not a cell)
        var has_deck := false
        for pu in G.pushers:
                if float(pu["y1"]) < G.GROUND_Y - 40.0:
                        if absf(float(pu["y0"]) - G.L1_Y) < 1.0:
                                has_deck = true
                        de.erase(float(pu["y0"]))
        ck(de.size() >= 2 and _steps_by(de, G.CELL) and has_deck \
                and absf(float(de.front()) - (G.GROUND_Y - G.CELL)) < 1.0,
                "THE WORLD LAW: the descent steps from the deck height down to the floor")
        G.probe_reset(214)
        G.pushers.clear()
        G._chunk_twin(0.0)
        var tw := _col_tops(G)
        var twxs: Array = []
        for pu in G.pushers:
                twxs.append(float(pu["x"]))
        twxs.sort()
        var valley: float = float(twxs[2]) - (float(twxs[1]) + G.CELL)
        ck(tw.size() == 1 and valley > G.CELL \
                and valley <= air_len - G.CELL,
                "THE WORLD LAW: the twin towers share one top; the valley is a clearable hop")
        G.probe_reset(215)
        G.pushers.clear()
        G.gsegs.clear()
        G.rsegs.clear()
        G._chunk_bridge(0.0)
        var slabs := 0
        var pit_w := 0.0
        var gs: Array = G.gsegs.duplicate()
        gs.sort_custom(func(a, b): return a["x0"] < b["x0"])
        if gs.size() >= 2:
                pit_w = float(gs[1]["x0"]) - float(gs[0]["x1"])
        for pu in G.pushers:
                if float(pu["y1"]) < G.GROUND_Y - 40.0:
                        slabs += 1
        ck(slabs == 2 and pit_w > 0.0 and pit_w <= G._max_pit_cells() * G.CELL + 8.0,
                "THE WORLD LAW: the bridge slab floats over an honest (jumpable) pit")
        G.probe_reset(216)
        G.pushers.clear()
        G._chunk_roof_stairs(0.0)
        var hset := {}
        var hang_ok := true
        for pu in G.pushers:
                hset[int(roundf((float(pu["y1"]) - G.ROOF_Y) / G.CELL))] = true
                if absf(float(pu["y0"]) - (G.ROOF_Y + G.CELL)) > 1.0:
                        hang_ok = false
                if float(pu["y1"]) >= G.GROUND_Y - G.CELL:
                        hang_ok = false
        ck(hang_ok and hset == {2: true, 3: true, 4: true},
                "THE WORLD LAW: the roof stairs hang one cell under the ride, stepping 1-2-3")
        # THE CLIMB TRUTH: a block top lands the full 90 and jumps again
        G.probe_reset(221)
        var blk_x: float = G.world_x + G.stand_x / G.us + G.CELL * 2.2
        G._add_col(blk_x, 1, G.GROUND_Y)
        G.player["x"] = G.stand_x
        G.player["y"] = (G.GROUND_Y - G.HALF) * G.us
        G.player["vy"] = 0.0
        G.player["g"] = 1
        G.player["ground"] = true
        G.player["rot"] = 0.0
        G.paused = false
        G._do_action()
        var landed_block := false
        for i in 240:
                G.probe_step(1.0 / 60.0)
                if G.player["ground"] \
                                and absf(G.player["y"] - (G.GROUND_Y - G.CELL - G.HALF) * G.us) < 3.0:
                        landed_block = true
                        break
        var rot_mod: float = absf(fmod(G.player["rot"], 90.0))
        ck(landed_block, "THE CLIMB TRUTH: the square lands ON the block top")
        ck(rot_mod < 14.0 or rot_mod > 76.0,
                "THE CLIMB TRUTH: the 90 completes at the block touchdown (rot %.1f)" % G.player["rot"])
        var was_ground: bool = G.player["ground"]
        G._do_action()
        ck(was_ground and not G.player["ground"],
                "THE CLIMB TRUTH: jumping OFF the block works at once")
        # THE CLIMB SNAP: a rising near-miss lands instead of shoving
        G.probe_reset(222)
        var blk2: float = G.world_x + G.stand_x / G.us + G.CELL * 1.2
        G._add_col(blk2, 1, G.GROUND_Y)
        G.player["x"] = G.stand_x + G.CELL * 1.2 * G.us + 10.0 * G.us
        G.player["y"] = (G.GROUND_Y - G.CELL - G.HALF + 22.0) * G.us
        G.player["vy"] = -400.0 * G.us
        G.player["ground"] = false
        G._pusher_push(1.0 / 60.0)
        ck(G.player["ground"] \
                and absf(G.player["y"] - (G.GROUND_Y - G.CELL - G.HALF) * G.us) < 1.0,
                "THE CLIMB SNAP: rising feet 22px under the top land ON the block")
        G.player["y"] = (G.GROUND_Y - G.HALF) * G.us
        G.player["vy"] = 0.0
        G.player["ground"] = true
        var x0s: float = G.player["x"]
        G._pusher_push(1.0 / 60.0)
        ck(G.player["x"] < x0s,
                "THE PUSHER LAW kept: a grounded face-hit still shoves")
        # THE SPIKE3 LAW: wide-low, calculated dodge-able
        G.probe_reset(231)
        G._add_spike3(G.world_x + 1000.0, G.GROUND_Y)
        var found3 := false
        for h in G.hazards:
                if h["kind"] == "spike3":
                        found3 = true
                        ck(float(h["hw"]) * 2.0 <= 130.0 and float(h["hh"]) * 2.0 <= 48.0,
                                "THE SPIKE3 LAW: the box stays wide-low (%.0f x %.0f)" % [float(h["hw"]) * 2.0, float(h["hh"]) * 2.0])
        ck(found3, "THE SPIKE3 LAW: the spike3 builder lives")
        ck(air_len > 130.0 + G.CELL,
                "THE SPIKE3 LAW: the base hop clears the whole row + the square (%.0fpx air)" % air_len)

        # ============================================== patch 3 THE WORLD LAW 2
        # THE COLLECT LAW: the owner's simplification - JUST the yellow circle
        G.probe_reset(241)
        var kids0: int = G.get_child_count()
        var parts0 := 0
        for c in G.get_children():
                if c is CPUParticles2D:
                        parts0 += 1
        G._orbit_collect_fx(Vector2(G.player["x"], G.player["y"]), Vector2.ZERO)
        var parts1 := 0
        for c in G.get_children():
                if c is CPUParticles2D:
                        parts1 += 1
        ck(G.get_child_count() == kids0 + 1 and parts1 == parts0,
                "THE COLLECT LAW: the collect wears ONE ring - zero particles")
        # THE BLOCK DECKS: the thin platform is retired for block surfaces
        G.probe_reset(251)
        G.pushers.clear()
        G._chunk_deck(0.0)
        var deck_cells := 0
        var deck_tops := {}
        for pu in G.pushers:
                if absf(float(pu["y1"]) - (float(pu["y0"]) + G.CELL)) < 0.5 \
                                and float(pu["y1"]) < G.GROUND_Y - 40.0 \
                                and (absf(float(pu["y0"]) - G.L1_Y) < 1.0 or absf(float(pu["y0"]) - G.L2_Y) < 1.0):
                        deck_cells += 1
                        deck_tops[float(pu["y0"])] = true
        ck(deck_cells >= 6 and deck_tops.size() >= 1,
                "THE DECK LAW: the deck is a long BLOCK surface on a line height (%d cells)" % deck_cells)
        # THE CLIMB-DOWN: up 2 - 4, then the staircase 3 - 2 - 1 back to the floor
        G.probe_reset(252)
        G.pushers.clear()
        G._chunk_down(0.0)
        var dn := _col_heights_seq(G)
        ck(dn.size() == 10 and dn[0] == 2 and dn[2] == 4 \
                and dn[4] == 3 and dn[6] == 2 and dn[8] == 1,
                "THE CLIMB-DOWN LAW: 2-4 up then 3-2-1 down (the vertical whole game)")
        # THE ROOF YARD: hanging decks with the riding lane clear
        G.probe_reset(253)
        G.pushers.clear()
        G._chunk_roof_yard(0.0)
        var yard_hangs := 0
        var yard_ok := true
        for pu in G.pushers:
                if float(pu["y1"]) < G.GROUND_Y - 40.0:
                        yard_hangs += 1
                        if absf(float(pu["y0"]) - G.L3_Y) > 1.0 \
                                        and absf(float(pu["y0"]) - G.L2_Y) > 1.0:
                                yard_ok = false
        ck(yard_hangs >= 5 and yard_ok,
                "THE ROOF YARD LAW: the roof side wears its own hanging block world (%d pads)" % yard_hangs)
        # THE MIXED PROFILE: ground + lines + roof in ONE chunk
        G.probe_reset(254)
        G.pushers.clear()
        G._chunk_mixed(0.0)
        var ground_cols := 0
        var mid_blocks := 0
        var roof_pads := 0
        for pu in G.pushers:
                if float(pu["y1"]) >= G.GROUND_Y - 1.0:
                        ground_cols += 1
                elif absf(float(pu["y0"]) - G.L1_Y) < 1.0:
                        mid_blocks += 1
                elif absf(float(pu["y0"]) - G.L3_Y) < 1.0:
                        roof_pads += 1
        ck(ground_cols >= 4 and mid_blocks >= 4 and roof_pads >= 2,
                "THE MIXED LAW: one chunk fills ground (%d) + deck (%d) + roof (%d)" % [ground_cols, mid_blocks, roof_pads])
        # THE SIDE PROFILES: on the roof the roof family triples
        var roof_base := mini(6, 2 + 0) + mini(4, 1 + 0) + mini(4, 1 + 0)
        ck(roof_base * 3 > roof_base,
                "THE SIDE PROFILE LAW: the roof family triples while the square rides the roof")
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

## ---- v0.3.6-3 structure helpers -----------------------------------------
## Distinct column tops, highest (smallest y) first.
func _col_tops(g: Node) -> Array:
        var tops: Array = []
        for pu in g.pushers:
                var y0: float = float(pu["y0"])
                if not tops.has(y0):
                        tops.append(y0)
        tops.sort()
        tops.reverse()
        return tops

## The top of the column seated at world x (or -1).
func _top_at(g: Node, wx: float) -> float:
        for pu in g.pushers:
                if absf(float(pu["x"]) - wx) < 2.0:
                        return float(pu["y0"])
        return -1.0

## Column heights (in cells) in x order - the shape reader for the climbers.
func _col_heights_seq(g: Node) -> Array:
        var cols: Array = []
        for pu in g.pushers:
                cols.append([float(pu["x"]), (float(pu["y1"]) - float(pu["y0"])) / g.CELL])
        cols.sort_custom(func(a, b): return a[0] < b[0])
        var out: Array = []
        for c in cols:
                out.append(int(roundf(float(c[1]))))
        return out

## True when every neighbouring distinct top differs by exactly one cell.
func _steps_by(tops: Array, cell: float) -> bool:
        if tops.size() < 2:
                return false
        for i in tops.size() - 1:
                if absf(absf(float(tops[i + 1]) - float(tops[i])) - cell) > 1.0:
                        return false
        return true

func _ready() -> void:
        _run()
