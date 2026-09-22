extends Node
## towerball_probe (v041-2) - THE LAWS OF THE TOWER, nothing ships blind.
## Pure-data fairness (hundreds of seeds, no scene) + the 3D seat boot
## through the REAL host in BOTH modes + the economy laws.
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

        # ---- ball rows: fairness across 300 seeds x 900 rows
        var rng2 := RandomNumberGenerator.new()
        for s in 300:
                rng2.seed = s
                var rl: int = TB.round_length(1 + (s % 6))
                for row in [0, 4, 8, 40, 200, rl - 1]:
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

        # ---- platform rows: fairness + always clearable
        for s in 300:
                rng2.seed = 1000 + s
                var rl: int = TB.round_length(1 + (s % 6))
                for row in [0, 2, 3, 30, rl - 1]:
                        var blocks: Array = TB.gen_blocks(row, 9, rng2, 1, rl)
                        _check(blocks.size() == 9, "cols count")
                        var nh := 0
                        for b in blocks:
                                if not bool(b):
                                        nh += 1
                        if row < 3:
                                _check(nh == 0, "no hard before row 3")
                        _check(nh <= 2, "hard cap 25%% of 9 (row %d nh %d)"
                                        % [row, nh])
                        _check(nh < 9, "a row always clears")

        # ---- the paddle bounce law: offset picks the angle, always upward
        _check(absf(float(TB.bounce_angle(0.0))) < 0.0001,
                "center bounce is straight up")
        _check(float(TB.bounce_angle(1.0)) > 0.0, "right offset leans right")
        _check(float(TB.bounce_angle(-1.0)) < 0.0, "left offset leans left")
        _check(absf(float(TB.bounce_angle(2.0)) - float(TB.bounce_angle(1.0)))
                < 0.0001, "offset clamps at 1")
        _check(absf(float(TB.bounce_angle(1.0))) < deg_to_rad(63.0),
                "max angle under 63 deg")

        # ---- the skins: 5 + 5, first free, the ramp colors parse
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
        for s in TB.BREAK_SKINS:
                for c in s["ramp"]:
                        _check(Color(String(c)) != Color.WHITE,
                                "ramp color parses (%s)" % c)

        # ---- the registry entry: the 3D seat is real
        var g: Dictionary = GameReg.get_game("towerball")
        _check(not g.is_empty(), "towerball registered")
        _check(String(g.get("dim", "")) == "3d", "dim 3d")
        _check(String(g.get("orientation", "")) == "auto", "orientation auto")
        _check(int(g.get("coin_div", 0)) == 5, "coin_div 5 (the /5 law)")
        _check((g.get("os", []) as Array).has("pc")
                and (g.get("os", []) as Array).has("android"), "os both")
        _check((g.get("controls_pc", []) as Array).size() >= 1,
                "controls_pc exists")
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
                _check(game.get("phase") != "boot", "flow started")
                _check(game.get("ball_mesh") != null, "Balldozer exists")
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
                _check(game2.get("cols") >= 6 and game2.get("cols") <= 14,
                        "cols sane")
                _check(game2.get("paddle") != null, "paddle built")
                _check(game2.get("rows").size() >= 10, "rows alive window")
                game2.finish_run(5)
                await get_tree().create_timer(0.6).timeout
                host._quit_to_menu()
                await get_tree().process_frame
        Box.reset_all()

        # ---- the simulated play: the crash/serve/win roads actually walk
        await _sim_play()

        print("towerball_probe: %d checks, %d fails" % [ok + fails, fails])
        if fails == 0:
                print("ALL PASS")
        get_tree().quit(1 if fails > 0 else 0)

## the play roads: ball crash grace + round win, platform crash -> serve
## -> auto-launch -> the run over (the paths the stills can never prove)
func _sim_play() -> void:
        var GH: GDScript = load("res://game/core/game_host.gd")
        Box.reset_all()
        Box.earn(100000)
        Box.unlock_game("towerball", 0)
        var router := Node2D.new()
        add_child(router)
        # BALL mode: a crash then a round win
        Box.set_progress("towerball", "mode", "ball")
        _check(GH.launch(router, "towerball"), "sim: ball launches")
        await get_tree().create_timer(2.2).timeout
        var host: Node = GH.active_host
        var game: Node = host.game
        game.call("_intro_start")
        await get_tree().create_timer(0.3).timeout
        game.call("sheet_pop")
        await get_tree().create_timer(0.2).timeout
        game.call("_start_run")
        await get_tree().create_timer(1.5).timeout
        _check(game.get("phase") == "run", "sim: ball run started")
        var lives0: int = game.get("lives")
        game.call("_crash", 0.8)          # a black touch
        _check(int(game.get("lives")) == lives0 - 1, "sim: crash costs a life")
        _check(float(game.get("stun_t")) > 0.0, "sim: the crash grace arms")
        _check(int(game.get("top_row")) == 1,
                "sim: the black disc gave way (no chain crash)")
        # the round win: walk the ball onto the victory disc
        game.set("stun_t", 0.0)           # the grace ran its course
        game.set("top_row", 150)          # every disc broken
        game.set("holding", true)         # the dive continues through
        var vy_win: float = game.get("victory_y")
        game.set("by", vy_win + 1.3)
        game.set("bvy", -46.0)
        for i in 4:
                game.call("_ball_tick", 0.016)
        _check(int(game.get("score")) == 1, "sim: the win pays +1")
        _check(String(game.get("phase")) == "won", "sim: the round is won")
        await get_tree().create_timer(1.5).timeout
        _check(int(game.get("round_len")) == 300, "sim: round 2 = 300 rows")
        host._quit_to_menu()
        await get_tree().process_frame
        # PLATFORM mode: crash -> serve -> auto-launch -> the run over
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
        _check(game.get("phase") == "serve", "sim: platform serves first")
        await get_tree().create_timer(1.2).timeout
        _check(game.get("phase") == "run", "sim: the serve auto-launches")
        game.call("_p_crash")             # the ball falls past the paddle
        _check(int(game.get("lives")) == 2, "sim: the fall costs a life")
        _check(game.get("phase") == "serve", "sim: re-serve after the fall")
        game.call("_p_crash")
        game.call("_p_crash")
        await get_tree().create_timer(0.9).timeout
        _check(bool(game.get("over")), "sim: no lives ends the run")
        _check(Box.stat("towerball", "plays") == 2, "sim: play recorded")
        host._quit_to_menu()
        await get_tree().process_frame
        Box.reset_all()
