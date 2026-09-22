extends Node
## towerball_probe (v041-2 r2) - THE LAWS OF THE TOWER, nothing ships blind.
## r2: THE EXACT BOOST LAW (the Stack Bounce decompile), the REAL Neon Tower
## ring laws (the famobi decompile), the DESIGN skins, NO LIVES, the flow
## (intro -> optionals -> PLAY) + the 3D seat boot through the REAL host in
## both modes. Pure-data fairness over hundreds of seeds + simulated play.
## Run: godot --headless --path . res://tests/towerball_probe.tscn

var ok := 0
var fails := 0

func _check(cond: bool, why: String) -> void:
        if cond:
                ok += 1
        else:
                fails += 1
                print("  FAIL: " + why)

func _ready() -> void:
        var TB: GDScript = load("res://game/games/towerball/towerball_data.gd")
        var rng := RandomNumberGenerator.new()

        # ---- the length ladder (the owner's numbers, exact)
        var want := [150, 300, 450, 600, 750, 900, 900, 900]
        for i in want.size():
                _check(int(TB.round_length(i + 1)) == want[i],
                        "round_length(%d) = %d want %d" % [i + 1,
                        TB.round_length(i + 1), want[i]])

        # ---- the coin law: after every 6 wins
        _check(not TB.coin_due(0), "no coin at 0 wins")
        _check(not TB.coin_due(5), "no coin at 5")
        _check(TB.coin_due(6), "coin at 6")
        _check(TB.coin_due(12), "coin at 12")
        _check(not TB.coin_due(7), "no coin at 7")

        # ---- r2 THE EXACT BOOST LAW (Stack Bounce verbatim)
        _check(absf(float(TB.BOOST_START) + 0.25) < 0.0001,
                "boost starts -0.25")
        _check(absf(float(TB.BOOST_PER_BREAK) - 0.03) < 0.0001,
                "+0.03 a break")
        _check(absf(float(TB.BOOST_BURN) - 0.6) < 0.0001, "burn 0.6/s")
        _check(absf(float(TB.BOOST_DECAY) - 0.15) < 0.0001, "decay 0.15/s")
        _check(absf(float(TB.BOOST_FLOOR) + 0.5) < 0.0001, "floor -0.5")
        _check(absf(float(TB.BOOST_CHARGE_TIME) - 1.6) < 0.0001,
                "the 1.6s charge")
        # the curve: 42 breaks from the start to full
        var v := float(TB.BOOST_START)
        for i in 42:
                v = float(TB.boost_after_break(v))
        _check(v >= 1.0 - 0.0001 and v < 1.0 + float(TB.BOOST_PER_BREAK),
                "42 breaks fill the gauge (v=%f)" % v)
        _check(bool(TB.boost_ready(v)), "the gauge is READY at full")
        # the burn: 1.66s of fire drains a full bar
        var burn := float(TB.boost_tick(1.0, 1.6666, true))
        _check(burn <= 0.0001, "a full bar burns out in ~1.67s")
        # the idle decay: 10s of idle drops 1.5
        var dec := float(TB.boost_tick(1.0, 10.0, false))
        _check(absf(dec + 0.5) < 0.0001, "the idle decay floors at -0.5")
        _check(absf(float(TB.streak_score(0.0)) - 1.0) < 0.0001,
                "the first break scores 1")
        _check(absf(float(TB.streak_score(4.4)) - 4.0) < 0.0001,
                "the streak rounds (4.4 -> 4)")

        # ---- ball rows: fairness across 300 seeds x 900 rows
        var rng2 := RandomNumberGenerator.new()
        for s in 300:
                rng2.seed = s
                var rl: int = TB.round_length(1 + (s % 6))
                for row in [0, 4, 8, 12, 13, 40, 200, rl - 1]:
                        var d: Dictionary = TB.gen_row(row, rl, rng2, 1)
                        var count := int(d["count"])
                        _check(count >= 10 and count <= 13,
                                "seg count sane (%d)" % count)
                        var nb := 0
                        for b in d["black"]:
                                if b:
                                        nb += 1
                        if row < 8:
                                _check(nb == 0, "no black before row 8")
                        var row_mod: int = row % 14
                        if row_mod >= 11 and row_mod <= 13:
                                _check(nb == 0,
                                        "the rhythm seam breathes (row %d)"
                                        % row)
                        _check(float(nb) / float(count) <= 0.45 + 0.001,
                                "black cap 45%% (row %d nb %d/%d)"
                                        % [row, nb, count])
                        var sp := absf(float(d["rot"]))
                        _check(sp >= 0.6 and sp <= 2.45,
                                "spin sane (%f)" % sp)

        # ---- seg_under_ball: a partition law (every rotation maps into range)
        for r in 200:
                var rot := float(r) * 0.137
                var seg := int(TB.seg_under_ball(12, rot))
                _check(seg >= 0 and seg < 12, "seg index in range")

        # ---- r2 THE NEON TOWER RING LAWS (the famobi decompile shapes)
        _check(absf(float(TB.NT_GRAVITY) + 60.0) < 0.0001, "gravity -60")
        _check(absf(float(TB.NT_BOUNCE_V) - 23.0) < 0.0001, "bounce 23")
        _check(absf(float(TB.NT_DRAG) - 0.02) < 0.0001, "drag 0.02")
        _check(absf(float(TB.NT_BALL_OFFSET) - 4.55) < 0.0001, "orbit 4.55")
        _check(absf(float(TB.NT_RING_R) - 6.3) < 0.0001, "ring radius 6.3")
        _check(absf(float(TB.NT_INTER_RING) - 8.7) < 0.0001, "spacing 8.7")
        _check(int(TB.NT_COMBO_THRESHOLD) == 4, "combo threshold 4")
        for s in 300:
                rng2.seed = 2000 + s
                var rl: int = TB.round_length(1 + (s % 6))
                for row in [0, 1, 2, 3, 6, 30, 120, rl - 1]:
                        var ring: Dictionary = TB.gen_ring(row, rl, rng2, 1)
                        # the start chunk: fully solid
                        if row < TB.NT_SOLID_START:
                                _check(absf(float(ring["gap"])) < 0.0001,
                                        "the start chunk is solid (row %d)"
                                        % row)
                                _check((ring["red"] as Array).is_empty()
                                        and (ring["walls"] as Array).is_empty(),
                                        "the start chunk is clean")
                                continue
                        # the guaranteed gap: passable, red never in it
                        var gap: float = float(ring["gap"])
                        _check(gap >= deg_to_rad(TB.NT_GAP_MIN_DEG) - 0.001,
                                "gap >= 18 deg (row %d gap %f)"
                                        % [row, rad_to_deg(gap)])
                        # every angle classifies
                        var ng := 0
                        var nr := 0
                        var ns := 0
                        var steps := 720
                        for i in steps:
                                var a := TAU * float(i) / float(steps)
                                match String(TB.ring_at(ring, a, 0.0)):
                                        "gap":
                                                ng += 1
                                        "red":
                                                nr += 1
                                        _:
                                                ns += 1
                        _check(ng + nr + ns == steps, "ring_at partitions")
                        _check(absf(float(ng) / float(steps) * TAU - gap)
                                < 0.02, "the gap arc reads true")
                        _check(float(nr) / float(steps) <= 0.36,
                                "red <= 35%% of the ring (row %d)" % row)
                        _check((ring["walls"] as Array).size() <= 2,
                                "max 2 walls")
                        var movers := 0
                        for w in ring["walls"]:
                                if absf(float(w["spd"])) > 0.0:
                                        movers += 1
                        _check(movers <= 1, "max 1 moving wall")
        # the safe rotation law: a rotation never sweeps a sector edge past
        # the ball when the ball sits in a slab
        rng2.seed = 42
        var test_ring: Dictionary = TB.gen_ring(30, 300, rng2, 1)
        for i in 40:
                var amt := 0.15 + float(i) * 0.02
                var safe := float(TB.ring_safe_rot(test_ring, 0.0, amt))
                _check(absf(safe) <= absf(amt) + 0.0001,
                        "safe <= requested")
                _check(safe * signf(amt) >= -0.0001,
                        "safe is in the rotation direction")

        # ---- the skins: 5 + 5, first free, DESIGNS (not colors)
        _check(TB.BALL_SKINS.size() == 5, "5 ball skins")
        _check(TB.BREAK_SKINS.size() == 5, "5 break skins")
        _check(int(TB.BALL_SKINS[0]["price"]) == 0, "first ball skin free")
        _check(int(TB.BREAK_SKINS[0]["price"]) == 0, "first break skin free")
        var owned_prices := true
        for s in TB.BALL_SKINS:
                if int(s["price"]) > 0 and int(s["price"]) < 200:
                        owned_prices = false
        for s in TB.BREAK_SKINS:
                if int(s["price"]) > 0 and int(s["price"]) < 200:
                        owned_prices = false
        _check(owned_prices, "paid skins cost real coins")
        var vfx_kinds := {}
        var sfx_kinds := {}
        for s in TB.BREAK_SKINS:
                for c in s["ramp"]:
                        _check(Color(String(c)) != Color.WHITE,
                                "ramp color parses (%s)" % c)
                # THE DESIGN LAW: own material character + own debris + voice
                _check(s.has("rough") and s.has("metal") and s.has("alpha")
                        and s.has("vfx") and s.has("sfx"),
                        "the skin is a DESIGN (%s)" % s["id"])
                vfx_kinds[String(s["vfx"])] = true
                sfx_kinds[String(s["sfx"])] = true
                # every break skin ships its own SFX file
                _check(ResourceLoader.exists("res://assets/audio/sfx/"
                        + String(s["sfx"]) + ".wav"),
                        "the break voice exists (%s)" % s["sfx"])
        _check(vfx_kinds.size() >= 4,
                "the debris styles differ (glass/rock/wood/water)")
        _check(sfx_kinds.size() == 5, "every skin speaks its own voice")
        # the ball skins: own material character
        for s in TB.BALL_SKINS:
                _check(s.has("rough") and s.has("metal") and s.has("alpha"),
                        "the ball skin is a DESIGN (%s)" % s["id"])

        # ---- the registry entry: the 3D seat is real
        var g: Dictionary = GameReg.get_game("towerball")
        _check(not g.is_empty(), "towerball registered")
        _check(String(g.get("dim", "")) == "3d", "dim 3d")
        _check(String(g.get("orientation", "")) == "auto", "orientation auto")
        _check(int(g.get("coin_div", 0)) == 5, "coin_div 5 (the /5 law)")
        _check((g.get("os", []) as Array).has("pc")
                and (g.get("os", []) as Array).has("android"), "os both")
        _check((g.get("controls_pc", []) as Array).size() >= 3,
                "controls_pc covers ball + platform + gamepad")
        _check(int(g.get("fee", 0)) == 8 and int(g.get("price", 0)) == 400,
                "entry 400 / fee 8")
        _check((g.get("ach", []) as Array).size() == 8, "8 achievements")
        _check(ResourceLoader.exists(String(g["script"])), "script exists")
        _check(ResourceLoader.exists(String(g["thumb"])), "thumb exists")

        # ---- the 3D seat: boot through the REAL host, both modes
        Box.reset_all()
        Box.earn(100000)
        Box.unlock_game("towerball", 0)
        var router := Node2D.new()
        add_child(router)
        # BALL mode boot
        Box.set_progress("towerball", "mode", "ball")
        var GH: GDScript = load("res://game/core/game_host.gd")
        _check(GH.launch(router, "towerball"), "ball mode launches")
        await get_tree().create_timer(2.2).timeout
        var host: Node = GH.active_host
        _check(host != null and host.game != null, "ball host+game alive")
        if host != null and host.game != null:
                var game: Node = host.game
                _check(game is Node3D, "THE 3D SEAT: the game is a Node3D")
                _check(game.get("world") != null, "world built")
                _check(game.get("cam") != null, "camera built")
                _check(game.get("round_len") == 150,
                        "round 1 = 150 rows")
                _check(game.get("phase") == "intro", "the intro waits first")
                _check(game.get("ball_mesh") != null, "Balldozer exists")
                _check(bool(game.get("ball_mesh").visible),
                        "THE BALL IS VISIBLE FROM THE FIRST FRAME")
                _check(game.get("gauge") != null, "THE FIRE GAUGE exists")
                _check(game.get("lives") == null,
                        "NO LIVES: the lives seat is gone")
                game.set_score(20)
                game.finish_run(20)
                await get_tree().create_timer(1.2).timeout
                _check(Box.stat("towerball", "plays") == 1, "play recorded")
                # the /5 law: 20 / 5 = 4 bonus + 0 pickups
                _check(host._score_to_coins(20) == 4, "score bonus /5")
                host._quit_to_menu()
                await get_tree().process_frame
        # PLATFORM mode boot (a fresh session)
        await get_tree().create_timer(0.3).timeout
        Box.set_progress("towerball", "mode", "platform")
        _check(GH.launch(router, "towerball"), "platform mode launches")
        await get_tree().create_timer(2.2).timeout
        host = GH.active_host
        _check(host != null and host.game != null, "platform host+game alive")
        if host != null and host.game != null:
                var game2: Node = host.game
                _check(game2 is Node3D, "platform game is a Node3D")
                _check(game2.get("mode") == "platform", "mode platform")
                _check(game2.get("rings").size() >= 10, "rings alive window")
                _check(game2.get("p_started") == false,
                        "the platform idles until PLAY")
                game2.finish_run(5)
                await get_tree().create_timer(0.6).timeout
                host._quit_to_menu()
                await get_tree().process_frame
        Box.reset_all()

        # ---- the simulated play: the crash/win/smash roads actually walk
        await _sim_play()

        print("towerball_probe: %d checks, %d fails" % [ok + fails, fails])
        if fails == 0:
                print("ALL PASS")
        get_tree().quit(1 if fails > 0 else 0)

## the play roads: the optionals -> PLAY flow, the boost law live, the
## ball crash = the run over (NO LIVES), the round win, the platform's
## combo charge -> the smash-through, the red-sector crash
func _sim_play() -> void:
        var GH: GDScript = load("res://game/core/game_host.gd")
        Box.reset_all()
        Box.earn(100000)
        Box.unlock_game("towerball", 0)
        var router := Node2D.new()
        add_child(router)
        # BALL mode
        Box.set_progress("towerball", "mode", "ball")
        _check(GH.launch(router, "towerball"), "sim: ball launches")
        await get_tree().create_timer(2.2).timeout
        var host: Node = GH.active_host
        var game: Node = host.game
        _check(String(game.get("phase")) == "intro", "sim: intro first")
        game.call("_intro_start")           # the tap-anywhere callback
        await get_tree().create_timer(0.3).timeout
        _check(String(game.get("phase")) == "optionals",
                "sim: the optionals show after the tap")
        game.call("sheet_pop")
        await get_tree().create_timer(0.2).timeout
        game.call("_start_run")
        await get_tree().create_timer(1.5).timeout
        _check(game.get("phase") == "run", "sim: ball run started")
        # the exact boost curve, LIVE: 34 breaks from the start land at 0.77
        game.set("boost_v", TB_const().BOOST_START)
        for i in 34:
                game.call("_shatter_top")
                if bool(game.get("boosting")):
                        break
        var bv := float(game.get("boost_v"))
        _check(bv > 0.7 and bv < 1.05,
                "sim: the boost fills by value (+0.03/break, v=%f)" % bv)
        # the fire ignites ONLY through the 1.6s charge
        game.set("boost_v", 1.0)
        game.call("_shatter_top")
        _check(float(game.get("boost_charge_t")) > 0.0,
                "sim: the charge arms at full")
        _check(not bool(game.get("boosting")),
                "sim: no fire until the charge runs")
        game.set("boost_charge_t", 0.01)
        game.call("_ball_tick", 0.02)
        _check(bool(game.get("boosting")), "sim: THE FIREBALL IS ON")
        # the crash: NO LIVES - one black touch ends the run
        game.set("boosting", false)
        game.set("boost_charge_t", 0.0)
        game.set("phase", "run")
        var top_before: int = game.get("top_row")
        game.call("_crash", 0.8)
        _check(String(game.get("phase")) == "over",
                "sim: ONE CRASH ENDS THE RUN (no lives)")
        _check(float(game.get("stun_t")) > 0.0, "sim: the crash grace arms")
        _check(int(game.get("top_row")) == top_before + 1,
                "sim: the black disc gave way (no chain crash)")
        await get_tree().create_timer(0.9).timeout
        _check(bool(game.get("over")), "sim: the run banks")
        host._quit_to_menu()
        await get_tree().process_frame
        # PLATFORM mode
        await get_tree().create_timer(0.3).timeout
        Box.set_progress("towerball", "mode", "platform")
        _check(GH.launch(router, "towerball"), "sim: platform launches")
        await get_tree().create_timer(2.2).timeout
        host = GH.active_host
        game = host.game
        game.call("_intro_start")
        await get_tree().create_timer(0.3).timeout
        game.call("sheet_pop")
        await get_tree().create_timer(0.2).timeout
        game.call("_start_run")
        await get_tree().create_timer(1.5).timeout
        _check(game.get("phase") == "run", "sim: platform runs (no serve)")
        # the combo law: falls charge, the charged landing SMASHES THROUGH
        game.set("p_combo", TB_const().NT_COMBO_THRESHOLD)
        var rings_before: int = game.get("rings").size()
        # land the ball ON ring 0's band in one tick (start above the band,
        # fall across its top plane)
        game.set("p_vy", -30.0)
        game.set("p_y", 1.6)
        game.call("_platform_tick", 0.016)
        _check(int(game.get("rings").size()) == rings_before - 1,
                "sim: THE CHARGED LANDING SMASHES THE PLATFORM")
        _check(int(game.get("p_combo")) == 0, "sim: the charge consumed")
        # the red crash: no lives, the run over
        game.call("_p_crash")
        _check(String(game.get("phase")) == "over",
                "sim: the red sector ends the run")
        await get_tree().create_timer(0.9).timeout
        _check(Box.stat("towerball", "plays") == 2, "sim: play recorded")
        host._quit_to_menu()
        await get_tree().process_frame
        Box.reset_all()

func TB_const() -> GDScript:
        return load("res://game/games/towerball/towerball_data.gd")
