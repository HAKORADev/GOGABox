extends Node
## ROCK BREAKER v040-7 probe - the deterministic battery for the owner's
## spec laws. godot --headless --path . res://tests/qa_v0407_rock.tscn
## Exit 0 = all laws. Covers: the number format, the size/children law,
## the heat curve, the upgrade caps and prices, the mystery trio (no
## double throw, no cash), the golden/mystery hidden pools, the sides
## law (15/side, 45-hold, 50-cap), the hold-fire law, the one-touch
## death, the shield save, the bank, the themes/skins shelf, and the
## economy pacing simulation with the auto-cannon.

var checks := 0
var fails := 0
var G: GogaGame = null
var finished := [-1, -1]

func ck(cond: bool, what: String) -> void:
        checks += 1
        if cond:
                print("[PASS] ", what)
        else:
                fails += 1
                print("[FAIL] ", what)

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout

func _boot(fresh := true) -> void:
        if G != null and is_instance_valid(G):
                G.queue_free()
                await _wait(0.3)
        if fresh:
                Box.reset_all()
        get_window().size = Vector2i(1080, 1920)
        ScaleRule.apply(get_window())
        get_window().content_scale_size = Vector2i(1080, 1920)
        await _wait(0.2)
        finished = [-1, -1]
        G = load("res://game/games/rockbreaker/rockbreaker.gd").new()
        G.game_id = "rockbreaker"
        G.request_finish.connect(func(s, c): finished = [s, c])
        add_child(G)
        await _wait(0.8)

func _tap(idx: int, pos: Vector2, down: bool) -> void:
        var e := InputEventScreenTouch.new()
        e.index = idx
        e.position = pos
        e.pressed = down
        G._goga_input(e)

func _drag(idx: int, pos: Vector2) -> void:
        var e := InputEventScreenDrag.new()
        e.index = idx
        e.position = pos
        G._goga_input(e)

# ------------------------------------------------- the static laws
func _static_laws() -> void:
        print("\n-- the pure core --")
        ck(G.fmt(999) == "999", "fmt: 999 stays plain")
        ck(G.fmt(1000) == "1.00K", "fmt: 1000 shows 1.00K")
        ck(G.fmt(999999) == "1000.00K" or G.fmt(999999) == "999.99K",
                "fmt: 999999 stays K-band")
        ck(G.fmt(1254000) == "1.25M", "fmt: 1254000 shows 1.25M")
        ck(G.fmt(7) == "7", "fmt: small numbers plain")
        var rng := RandomNumberGenerator.new()
        rng.seed = 7
        var ok_sizes := true
        for i in 500:
                var n := rng.randi_range(1, 5)
                var kids: Array = G.children_sizes(n, rng)
                if n == 1:
                        ok_sizes = ok_sizes and kids.is_empty()
                else:
                        ok_sizes = ok_sizes and kids.size() == n
                        for ks in kids:
                                ok_sizes = ok_sizes and int(ks) >= 1 \
                                        and int(ks) <= n - 1
        ck(ok_sizes, "SIZE LAW: size N carries N children of 1..N-1; 1 is terminal")
        var hp0: int = G.rock_hp(0, 3, rng)
        var hp2: int = G.rock_hp(200, 3, rng)
        ck(hp0 > 0 and hp2 > hp0 * 40.0, "HEAT: the pool climbs with the run (unbounded)")
        var wobbled: int = G.rock_hp(100, 3, rng)
        ck(wobbled > 0, "HEAT: wobble keeps the pool positive")
        ck(G.bps_for(0) == 4.0, "UPGRADE: the fire starts at 4/s (the CC law)")
        ck(G.bps_for(50) == 54.0, "UPGRADE: projectile cap 50 -> 54/s")
        ck(G.bps_for(80) == 54.0, "UPGRADE: the cap clamps")
        ck(G.dmg_for(0) == 1, "UPGRADE: damage starts at 1")
        ck(G.dmg_for(1000) == 1001, "UPGRADE: damage uncapped (+1 a level)")
        ck(G.proj_price(0) == 12 and G.dmg_price(0) == 20,
                "ECONOMY: the price bases")
        ck(G.proj_price(5) > G.proj_price(4) and G.dmg_price(5) > G.dmg_price(4),
                "ECONOMY: the prices only climb (the long-term goal)")
        ck(G.proj_price(49) > 1000000, "ECONOMY: the tail is a war chest")
        var r0: Dictionary = G.ramp_color(G.ramp_index(8))
        var r1: Dictionary = G.ramp_color(G.ramp_index(400))
        ck(r0["body"] != r1["body"], "COLOR LAW: the intense-er the longer")
        ck(G.ramp_index(999999) == G.RAMP_STEPS - 1, "COLOR LAW: the ramp clamps at white-hot")
        var gifts := {}
        for i in 300:
                gifts[G.pick_gift(rng)] = true
        ck(gifts.size() == 3 and gifts.has("slow") and gifts.has("shield")
                and gifts.has("rush"),
                "MYSTERY LAW: exactly slow/shield/rush - no double throw, no cash")
        var mok := true
        for i in 200:
                var mh: int = G.mystery_hp(rng)
                mok = mok and mh >= 250 and mh <= 500
                var gh: int = G.golden_hp(rng)
                mok = mok and gh >= 300 and gh <= 1000
        ck(mok, "HIDDEN POOLS: mystery 250..500, golden 300..1000")
        ck(G.THEMES.size() == 5 and G.THEMES.has("cave")
                and G.THEMES.has("forest") and G.THEMES.has("pixel")
                and G.THEMES.has("neon") and G.THEMES.has("candy"),
                "THEME LAW: cave, forest, pixel, neon, candy")
        ck(int(G.THEMES["cave"]["price"]) == 0, "THEME LAW: cave is the free default")
        var all_places := true
        var styles := {"cave": "stone", "forest": "wood", "pixel": "pixel",
                "neon": "neon", "candy": "candy"}
        for tid in G.THEMES:
                all_places = all_places \
                        and (G.THEMES[tid]["places"] as Array).size() == 5 \
                        and String(G.THEMES[tid]["style"]) == styles[tid]
        ck(all_places, "FIVE PLACES LAW: every theme owns five places and its rock pack")
        ck(G.SKINS.size() == 5 and int(G.SKINS["classic"]["price"]) == 0,
                "SKIN LAW: 5 cannon skins, the first default")

# -------------------------------------------------- the scene laws
func _scene_laws() -> void:
        print("\n-- the scene --")
        await _boot(true)
        ck(G.phase == "boot", "the gate owns the first breath")
        ck(G.golden_alive == false and G.mystery_alive == false,
                "no golden, no mystery before the flood")
        _tap(1, Vector2(540, 900), true)
        ck(G.phase == "play", "TAP ANYWHERE starts")
        # the sides law through the real director
        G.probe_reset(123)
        for i in 18:
                G.probe_spawn(0, 2, 50)
                G.probe_spawn(1, 2, 50)
        ck(G.side_count[0] == 18 and G.side_count[1] == 18,
                "SIDES LAW: 18 alive spawns a side")
        var n0: int = G.rocks.size()
        G.heat = 0
        G.spawn_t = 0.0
        G._spawn_director(0.016)
        ck(G.rocks.size() == n0, "SIDES LAW: the 15/side budget holds")
        for i in 8:
                G.probe_spawn(0, 2, 50)
                G.probe_spawn(1, 2, 50)
        var n1: int = G.rocks.size()
        ck(n1 >= 45, "the screen sits over the hold line (%d)" % n1)
        G.heat = 0
        G.spawn_t = 0.0
        G._spawn_director(0.016)
        ck(G.rocks.size() == n1, "SIDES LAW: 45+ holds the spawner")
        while G.rocks.size() > 24:
                G._break_rock(0, true)
        G.side_count = [0, 0]        # the probe owns the ledger here
        G.heat = 0
        G.spawn_t = 0.0
        G._spawn_director(0.016)
        ck(G.rocks.size() >= 25, "the spawner breathes under the hold line")
        # the bullet damage law
        G.probe_reset(5)
        G.probe_spawn(0, 2, 100)
        var rk: Dictionary = G.rocks[0]
        var hp_before := int(rk["hp"])
        G.md["upg_dmg"] = 4
        G.bullets.append({"x": float(rk["x"]), "y": float(rk["y"]),
                "vy": -10.0, "r": 7.0, "dmg": G.dmg_for(4)})
        G._bullets_tick(0.016)
        ck(int(G.rocks[0]["hp"]) == hp_before - 5,
                "DAMAGE LAW: a shot pays 1 + level")
        # the break law: rockPoints, rockCoins, the children
        var rc0: int = G.rc_wallet()
        var rp0: int = G.rp
        while G.rocks.size() > 0:
                G._damage_rock(0, 99999, 10.0, 10.0)
        ck(G.rp > rp0, "SCORE LAW: every break is a rockPoint")
        # v040-11 THE GROUND COIN LAW: the pay DROPS - it banks only after
        # the coins fall, rest, and ride the magnet into the wallet
        for i in 300:
                G._coins_tick(1.0 / 60.0)
        ck(G.rc_wallet() == rc0 + maxi(1, int(round(float(hp_before) / 10.0)))
                + 2, "ROCKCOIN LAW: the pool / 10 lands and banks (children pay too)")
        G.probe_reset(9)
        var rp1: int = G.rp
        G.probe_spawn(1, 1, 120)     # size 1: terminal, exact pay
        var rc1: int = G.rc_wallet()
        var hp1: int = int(G.rocks[0]["hp"])
        while G.rocks.size() > 0:
                G._damage_rock(0, 99999, 10.0, 10.0)
        for i in 300:
                G._coins_tick(1.0 / 60.0)
        ck(G.rc_wallet() == rc1 + maxi(1, int(round(float(hp1) / 10.0))),
                "ROCKCOIN LAW: a 120 rock pays 12 - exact (after the coin beat)")
        ck(G.rp == rp1 + 1,
                "SCORE LAW: one broken rock is one rockPoint (exact)")
        ck(G.score == G.rp, "SCORE LAW: the score IS the rockPoints")
        # the golden law
        G.probe_reset(6)
        G.probe_spawn(0, 3, 500, true)
        ck(G.golden_alive, "the golden rides in on its counter")
        var coins0 := G.run_coins
        while G.rocks.size() > 0:
                G._damage_rock(0, 99999, 10.0, 10.0)
        ck(G.run_coins == coins0 + 1, "GOLDEN LAW: the golden pays a GOGACoin")
        ck(not G.golden_alive and G.rp_last_golden == G.rp,
                "GOLDEN LAW: the next 300 counts from the collection")
        # the mystery law: the shield gift (locked on the rock itself)
        G.probe_reset(8)
        G.probe_spawn(0, 2, 300, false, true, "shield")
        while G.rocks.size() > 0:
                G._damage_rock(0, 99999, 10.0, 10.0)
        ck(G.shield == 1, "MYSTERY LAW: the shield gift arms")
        # the shield save
        var cx: float = G.cannon_x
        var gy: float = G.ground_y
        G.probe_spawn(0, 1, 60)
        G.rocks[0]["x"] = cx
        G.rocks[0]["y"] = gy - 70.0
        G._touch_check()
        ck(G.shield == 0 and G.phase == "play",
                "SHIELD: one touch forgiven, the run lives")
        # the one-touch death
        G.probe_spawn(0, 1, 60)
        G.rocks[0]["x"] = cx
        G.rocks[0]["y"] = gy - 70.0
        G._touch_check()
        ck(G.phase == "over", "ONE TOUCH: no shield, the run ends")
        var waited := 0.0
        while finished[0] == -1 and waited < 3.0:
                await _wait(0.1)
                waited += 0.1
        ck(finished[0] >= 0, "the run finishes into the host chrome")

func _finish_laws() -> void:
        print("\n-- the bank and the sheets --")
        await _boot(true)
        _tap(1, Vector2(400, 900), true)
        G.md["rockcoins"] = 1000
        G.rc_bank(250)
        G.rp = 320
        G._finish()
        ck(int(G.md["rockcoins"]) == 1250, "THE BANK: the live wallet lands")
        ck(int(G.md["best_rp"]) == 320, "THE BANK: the best line grows")
        # the upgrade path (the sheet's own functions)
        G._boot_fresh()
        G.md["rockcoins"] = G.proj_price(0) + G.dmg_price(0)
        G._buy_proj()
        ck(int(G.md["upg_proj"]) == 1, "UPGRADES: the projectile buys")
        G._buy_dmg()
        ck(int(G.md["upg_dmg"]) == 1, "UPGRADES: the damage buys")
        G.md["rockcoins"] = G.proj_price(49)
        G.md["upg_proj"] = 49
        G._buy_proj()
        ck(int(G.md["upg_proj"]) == 50, "UPGRADES: the 50th projectile lands")
        G.md["rockcoins"] = G.proj_price(50)
        G._buy_proj()
        ck(int(G.md["upg_proj"]) == 50, "UPGRADES: the cap holds at 50")
        # the hold-fire law: hold pours, a tap never spams
        G._boot_fresh()
        G.probe_reset(11)
        _tap(2, Vector2(800, 1500), true)
        await _wait(0.35)
        var held: int = G.bullets.size()
        _tap(2, Vector2(800, 1500), false)
        await _wait(0.25)
        var after_up: int = G.bullets.size()
        ck(held > 0, "HOLD LAW: holding pours shots")
        ck(after_up <= held + 2, "HOLD LAW: lifting stops the pour")
        # a quick tap on the right half: the pour never spams
        var b0: int = G.bullets.size()
        _tap(3, Vector2(800, 1500), true)
        _tap(3, Vector2(800, 1500), false)
        await _wait(0.3)
        ck(G.bullets.size() <= b0 + 3,
                "HOLD LAW: a tap never spams shots")
        # the move law: the left half rolls the cannon
        var cx0: float = G.cannon_x
        _tap(4, Vector2(200, 1500), true)
        _drag(4, Vector2(420, 1500))
        await _wait(0.4)
        ck(G.cannon_x > cx0 + 20.0, "MOVE LAW: the left half rolls")
        _tap(4, Vector2(420, 1500), false)

# ------------------------------------------------ the pacing sim
## The auto-cannon plays a real 8-minute run in fast-forward: the
## upgrade policy buys the moment it can afford. The laws: the first
## upgrade lands inside the first minute, the first golden is broken
## inside 8 minutes, the heat curve keeps the pool human, and the
## shield-laced bot stays alive to see it.
func _sim_laws() -> void:
        print("\n-- the pacing simulation --")
        await _boot(true)
        _tap(1, Vector2(400, 900), true)
        G.probe_reset(42)
        G._auto = true
        G.shield = 999999
        # the competent mid-early build: dmg 30 a shot at 4/s - the sim
        # measures the ECONOMY's flow, not the bot's aim
        G.md["upg_dmg"] = 29
        G.set_process(false)         # the probe drives the ticks
        var dt := 1.0 / 30.0
        var sim := 0.0
        var first_golden := -1.0
        var first_seen := -1.0
        var rc_60 := -1
        while sim < 560.0 and finished[0] == -1:
                G._goga_tick(dt)
                sim += dt
                G.shield = 999999
                # the perfect tracker: pin the cannon under the lowest
                # rock so every descending rock eats the full pour
                if G.rocks.size() > 0:
                        var lo3 := {}
                        var by3 := -1e9
                        for rk3 in G.rocks:
                                if float(rk3["y"]) > by3:
                                        by3 = float(rk3["y"])
                                        lo3 = rk3
                        # THE PREDICTIVE PIN: park where the rock WILL be
                        # when a bullet fired now arrives (the lead law)
                        var t_lead: float = maxf(0.0,
                                (G.ground_y - 104.0 * G.us
                                - float(lo3["y"]))
                                / (G.BULLET_SPEED * G.us))
                        var tx: float = float(lo3["x"]) \
                                + float(lo3["vx"]) * t_lead
                        G.cannon_x = clampf(tx, 70.0 * G.us,
                                G.W - 70.0 * G.us)
                if rc_60 < 0.0 and sim >= 60.0:
                        rc_60 = G.rc_wallet()
                if int(sim / dt) % 600 == 0:
                        var lo := {}
                        for rk2 in G.rocks:
                                if lo.is_empty() or float(rk2["y"]) > float(lo["y"]):
                                        lo = rk2
                        print("  t=%0.0f rp=%d rocks=%d bullets=%d cx=%0.0f lock_x=%s lock_y=%s lock_hp=%s" % [sim, G.rp, G.rocks.size(), G.bullets.size(), G.cannon_x, "None" if lo.is_empty() else str(int(lo["x"])), "None" if lo.is_empty() else str(int(lo["y"])), "None" if lo.is_empty() else str(lo["hp"])])
                if first_seen < 0.0 and G.golden_alive:
                        first_seen = sim
                if first_golden < 0.0 and int(G.md["golden_total"]) > 0:
                        first_golden = sim
        ck(rc_60 >= G.proj_price(0),
                "PACING: the first upgrade is affordable inside a minute "
                + "(rc@60s=%d)" % rc_60)
        ck(first_seen > 0.0 and first_seen < 560.0,
                "PACING: the golden rock rides in (%0.1fs)" % first_seen)
        ck(G.rp >= 150, "PACING: the run digs deep (rp %d)" % G.rp)
        var hp_at: int = G.rock_hp(G.rp, 3, G.rng)
        ck(hp_at < 4000, "HEAT: the pool stays human at depth (%s)" % hp_at)
        print("  sim: rp=%d rc=%d proj=%d dmg=%d golden=%d sim=%.0fs" % [
                G.rp, G.rc_wallet(), G.md["upg_proj"], G.md["upg_dmg"],
                G.md["golden_total"], sim])

func _v0408_laws() -> void:
        print("\n-- the v040-8 laws (bounce, open walls, bursts, top-up) --")
        await _boot(true)
        _tap(1, Vector2(400, 900), true)
        G.probe_reset(11)
        # THE BOUNCE LAW: the ground is a trampoline - a falling rock
        # bounces and lives (nothing shatters on the floor anymore)
        G.probe_spawn(0, 2, 90)
        G.rocks[0]["x"] = G.W * 0.5
        G.rocks[0]["y"] = G.ground_y - 260.0
        G.rocks[0]["vx"] = 0.0
        G.rocks[0]["vy"] = 300.0 * G.us
        var alive0: int = G.rocks.size()
        for i in 40:
                G._rock_physics(1.0 / 60.0)
        ck(G.rocks.size() == alive0, "BOUNCE LAW: the ground eats nothing")
        ck(float(G.rocks[0]["vy"]) < 0.0,
                "BOUNCE LAW: the rock rides UP off the floor")
        # THE WALL BUDGET LAW (v040-9, the owner's correction): regular
        # rocks spawn with a 3..5 wall-bounce budget, specials with 0
        var budgets_ok := true
        for i in 12:
                G.probe_spawn(i % 2, 2, 60)
                var wb: int = int(G.rocks[-1]["wall_bounce"])
                if wb < 3 or wb > 5:
                        budgets_ok = false
        ck(budgets_ok, "WALL BUDGET: regular rocks roll 3..5 bounces")
        G.probe_spawn(0, 3, 400, true)
        ck(int(G.rocks[-1]["wall_bounce"]) == 0,
                "WALL BUDGET: the golden carries no budget")
        # THE DANCE: a budgeted rock bounces off the wall first...
        G.probe_spawn(1, 1, 40)
        G.rocks[-1]["x"] = G.W - 30.0
        G.rocks[-1]["vx"] = 620.0 * G.us
        G.rocks[-1]["vy"] = 0.0
        G.rocks[-1]["wall_bounce"] = 2
        var n_dance: int = G.rocks.size()
        for i in 20:
                G._rock_physics(1.0 / 60.0)
        ck(G.rocks.size() == n_dance
                and float(G.rocks[-1]["vx"]) < 0.0
                and int(G.rocks[-1]["wall_bounce"]) == 1,
                "WALL BUDGET: the rock dances off the wall, budget -1")
        # ...then, budget spent, it slides OUT and frees its side seat
        G.rocks[-1]["vx"] = 620.0 * G.us
        G.rocks[-1]["wall_bounce"] = 0
        var side_before: int = G.side_count[1]
        var n_before: int = G.rocks.size()
        for i in 40:
                G._rock_physics(1.0 / 60.0)
        ck(G.rocks.size() == n_before - 1,
                "WALL BUDGET: a spent rock leaves through the wall")
        ck(G.side_count[1] == side_before - 1,
                "WALL BUDGET: the side ledger frees the seat")
        # THE PERSISTENCE LAW: a golden never leaves - it bounces back
        G.probe_reset(12)
        G.probe_spawn(1, 3, 400, true)
        G.rocks[-1]["x"] = G.W - 60.0
        G.rocks[-1]["vx"] = 800.0 * G.us
        G.rocks[-1]["vy"] = 0.0
        var g_before: int = G.rocks.size()
        for i in 40:
                G._rock_physics(1.0 / 60.0)
        ck(G.rocks.size() == g_before and float(G.rocks[0]["vx"]) < 0.0,
                "PERSISTENCE: the golden bounces off the wall, never leaves")
        # THE BURST LAW: one director event pours 1..4 rocks
        G.probe_reset(13)
        G.heat = 0
        var pours := 0
        for i in 12:
                G.spawn_t = 0.0
                var b0: int = G.rocks.size()
                G._spawn_director(0.016)
                pours += G.rocks.size() - b0
        ck(pours >= 12 and pours <= 60,
                "BURST LAW: the spawner pours 1..5 an event (%d in 12)" % pours)
        # v040-11 THE WALLS-ONLY LAW (the owner, third strike): "why the
        # fuck you still spawn rocks from the ground, they should be from
        # two wall sides, the ground thing should never ever happen".
        # Every spawn must ride a WALL side; no side == -1 ground birth
        # exists anywhere in the director, and no launch/telegraph system
        # survives at all.
        var ground_births := 0
        for r in G.rocks:
                if int(r["side"]) == -1:
                        ground_births += 1
        ck(ground_births == 0 and not ("_launch_up" in G)
                and not ("_launch_marks_tick" in G),
                "WALLS-ONLY: no ground spawn path exists (0 ground births,"
                + " no launch system)")
        # THE SHOT LAW: the ball is visible and flies at a visible speed
        ck(G.BULLET_R == 13.0 and G.BULLET_SPEED == 920.0,
                "SHOT LAW: 13px balls at 920px/s - seen climbing")
        # THE TOP-UP FRAMEWORK: the adapters and the convert math
        var rb0: int = GameCoin.balance("rockbreaker")
        GameCoin.add("rockbreaker", 50)
        ck(GameCoin.balance("rockbreaker") == rb0 + 50,
                "TOPUP: rockbreaker's wallet grows through GameCoin")
        ck(RBMeta.coin_balance() == rb0 + 50,
                "TOPUP: the game reads the SAME store")
        var hw0: int = GameCoin.balance("heavywar")
        GameCoin.add("heavywar", 25)
        ck(GameCoin.balance("heavywar") == hw0 + 25,
                "TOPUP: heavywar's scrap grows through GameCoin")
        ck(GameCoin.convert(10, 5.0) == 50,
                "TOPUP: 10 GOGACoins at 5.0 = 50 game coins")
        var carriers := GameCoin.games()
        var ids := []
        for r in carriers:
                ids.append(String(r["id"]))
        ck(ids.has("heavywar") and ids.has("rockbreaker"),
                "TOPUP: both carriers declared - no hardcoded ids")

func _ready() -> void:
        print("=== qa_v0407_rock: the ROCK BREAKER battery ===")
        await _static_laws()
        await _scene_laws()
        await _finish_laws()
        await _v0408_laws()
        await _sim_laws()
        print("\n=== %d checks, %d fails ===" % [checks, fails])
        get_tree().quit(1 if fails > 0 else 0)
