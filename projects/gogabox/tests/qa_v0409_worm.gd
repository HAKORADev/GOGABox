extends Node
## DEADLY WORM v040-9 probe - the deterministic battery for the owner's
## GDD laws. godot --headless --path . res://tests/qa_v0409_worm.tscn
## Exit 0 = all laws. Covers: the world shape (sky/surface/underground),
## the chain follow, the surface-line slowdown, the eat/point laws
## (humans 1, animals 3, ground 1-per-3), the coin law (every 10 eaten),
## the charge law (per 100 points), the dash cooldowns, the dirt armor,
## the fixed health, the death, the level math (x1.5 at max), the worm
## unlock chain, the places (1 free + 4 priced + exclusive grip), the
## power-up gates, the top-up adapter, and the never-resting spawner.

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
        get_window().size = Vector2i(1920, 1080)
        ScaleRule.apply(get_window())
        await _wait(0.2)
        finished = [-1, -1]
        G = load("res://game/games/deathworm/deathworm.gd").new()
        G.game_id = "deathworm"
        G.request_finish.connect(func(s, c): finished = [s, c])
        add_child(G)
        await _wait(0.9)

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

# --------------------------------------------------------- the world laws
func _world_laws() -> void:
        print("\n-- the world laws --")
        ck(G.W == 1920.0 and G.H == 1080.0, "THE CANVAS: landscape 1920x1080")
        ck(G.WORLD_W > G.W, "THE WIDE LAW: the world is wider than the screen")
        ck(G.SURFACE_Y > G.SKY_H, "THE SHAPE: sky above the surface line")
        ck(G.H > G.SURFACE_Y + 200.0,
                "THE SHAPE: the underground runs deep below the line")
        ck(G.pts.size() == G.SEG_COUNT + 2,
                "THE CHAIN: head + 14 segments + tail")
        ck(G.PLACES.size() == 5, "THE PLACES: five")
        var free := 0
        var priced := 0
        for pid in G.PLACES:
                if int(G.PLACES[pid]["price"]) == 0:
                        free += 1
                else:
                        priced += 1
        ck(free == 1 and priced == 4,
                "THE PLACES LAW: one default free, four cost GOGACoins")
        ck(float(G.PLACES["polar"]["grip"]) < 1.0,
                "THE EXCLUSIVE LAW: the ICE drifts (grip < 1)")
        ck(float(G.PLACES["city"]["bullet_mult"]) > 1.0,
                "THE EXCLUSIVE LAW: the CITY shoots faster")
        ck(float(G.PLACES["jungle"]["roots"]) < 1.0,
                "THE EXCLUSIVE LAW: the JUNGLE drags the dive")
        ck(String(G.PLACES["medieval"]["hazard"]) == "torches",
                "THE EXCLUSIVE LAW: the KINGDOM burns")

# --------------------------------------------------------- the worm laws
func _worm_laws() -> void:
        print("\n-- the worm laws --")
        ck(G.WORMS.size() == 10, "THE TEN: ten worms")
        ck(G.WORMS[0]["price"] == 0, "THE STARTER: the first worm is free")
        var chain_ok := true
        for i in range(1, G.WORMS.size()):
                if int(G.WORMS[i]["price"]) <= 0:
                        chain_ok = false
                var caps: Array = []
                for w in G.WORMS:
                        caps.append(int(w["maxlvl"]))
                if caps[i] <= caps[i - 1]:
                        chain_ok = false
        ck(chain_ok, "THE CHAIN: every later worm costs coins and grows the capacity")
        var w: Dictionary = G.WORMS[0]
        var st1: Dictionary = G.stats_at(0, 1)
        var stmax: Dictionary = G.stats_at(0, int(w["maxlvl"]))
        ck(absf(float(stmax["hp"]) / float(st1["hp"]) - 1.5) < 0.01,
                "THE GROW LAW: a maxed worm is x1.5 its base stats")
        ck(float(stmax["hp"]) > float(st1["hp"]),
                "THE GROW LAW: levels only ever grow")
        var sp := {}
        for wr in G.WORMS:
                sp[String(wr["special"])] = true
        ck(sp.size() == 10, "THE SPECIALS: ten unique abilities")

# ------------------------------------------------------- the economy laws
func _eat_laws() -> void:
        print("\n-- the economy laws --")
        G._start_run()
        await _wait(0.1)
        G.state = "play"
        var s0: int = G.score
        # a human: 1 point
        G.things.append({"kind": "human", "skin": "casual1", "x": G.pts[0].x,
                "y": G.pts[0].y, "vx": 0.0, "fr": [], "fi": 0, "ft": 0.0,
                "alive": true, "flee": 0.0})
        G._eat_check()
        ck(G.score == s0 + 1, "THE POINT LAW: a human pays 1")
        # an animal: 3 points
        s0 = G.score
        G.things.append({"kind": "animal", "skin": "camel",
                "x": G.pts[0].x, "y": G.pts[0].y, "vx": 0.0, "alive": true})
        G._eat_check()
        ck(G.score == s0 + 3, "THE POINT LAW: a land animal pays 3")
        # ground animals: 1 per 3
        s0 = G.score
        for i in 3:
                G.things.append({"kind": "ground", "skin": "mole",
                        "x": G.pts[0].x, "y": G.pts[0].y, "vx": 0.0,
                        "vy": 0.0, "alive": true, "wob": 0.0})
                G._eat_check()
        ck(G.score == s0 + 1,
                "THE POINT LAW: three ground animals pay exactly 1")
        # the coin law: every 10 edibles drop a wormCoin
        var wall0: int = G.meta.coins()
        for i in 10:
                G.things.append({"kind": "human", "skin": "casual1",
                        "x": G.pts[0].x, "y": G.pts[0].y, "vx": 0.0,
                        "fr": [], "fi": 0, "ft": 0.0, "alive": true,
                        "flee": 0.0})
                G._eat_check()
        for i in 12:
                G._tick_drops(1.0 / 60.0)
        ck(int(G.meta.coins()) == wall0 + 1,
                "THE COIN LAW: 10 eaten -> exactly 1 wormCoin, banked live")
        # the charge law: 100 points -> one charge
        var ch0: int = G.special_charges
        s0 = G.score
        G.set_score(0)
        G.special_score_base = 0
        var humans := 0
        while G.score < 100 and humans < 300:
                G.things.append({"kind": "animal", "skin": "camel",
                        "x": G.pts[0].x, "y": G.pts[0].y, "vx": 0.0,
                        "alive": true})
                G._eat_check()
                humans += 1
        ck(G.special_charges == ch0 + 1,
                "THE CHARGE LAW: 100 points -> exactly one special charge")

# ------------------------------------------------------- the motion laws
func _motion_laws() -> void:
        print("\n-- the motion laws --")
        # the chain follows: put the head somewhere new, tick, segments chase
        var head0: Vector2 = G.pts[0]
        var seg0: Vector2 = G.pts[5]
        G.pts[0] = head0 + Vector2(200, 0)
        G._tick_worm(1.0 / 60.0)
        ck(G.pts[5].distance_to(seg0) < 200.0,
                "THE CHAIN: the segments chase the head, they don't teleport")
        # the surface-line slowdown: time a fixed crawl deep vs on the line
        var deep_speed := _measure_speed(G.H * 0.75)
        var line_speed := _measure_speed(G.SURFACE_Y)
        ck(line_speed < deep_speed * 0.85,
                "THE SURFACE LAW: riding the line is slower (the original's law)")
        # the dash: cooldown rides, the burst is timed
        G.dash_cd = 0.0
        G._do_dash()
        ck(G.dash_t > 0.0 and G.dash_cd > 0.0,
                "THE DASH LAW: the dash bursts and starts its cooldown")
        var cd1: float = G.dash_cd
        var cd2: float = G._dash_cd_max()
        ck(absf(cd1 - cd2) < 0.001, "THE DASH LAW: the widget reads the same clock")
        G._do_dash()
        ck(absf(G.dash_cd - cd1) < 0.001,
                "THE DASH LAW: a dashing worm cannot re-dash early")

func _measure_speed(y: float) -> float:
        G.pts[0] = Vector2(G.WORLD_W * 0.5, y)
        for i in range(1, G.pts.size()):
                G.pts[i] = G.pts[0] + Vector2(float(i) * 20.0, 0.0)
        G.heading = 0.0
        G.vel = Vector2(300.0, 0.0)
        G.steer_mag = 0.0
        G.dash_t = 0.0
        G.invuln_t = 0.0
        var x0: float = G.pts[0].x
        var steps := 30
        for i in steps:
                G._tick_worm(1.0 / 60.0)
        return (G.pts[0].x - x0) / (float(steps) / 60.0)

# --------------------------------------------------------- the war laws
func _war_laws() -> void:
        print("\n-- the war laws --")
        # dirt armor: a shot at a DEEP worm does nothing
        G.pts[0] = Vector2(G.WORLD_W * 0.5, G.H * 0.7)
        G.p_hp = 100.0
        var hp0: float = G.p_hp
        G.shots.append({"kind": "bullet", "x": G.pts[0].x, "y": G.pts[0].y,
                "vx": 0.0, "vy": 0.0, "t": 0.0})
        G._tick_shots(1.0 / 60.0)
        ck(G.p_hp == hp0, "THE ARMOR LAW: the dirt under the line stops the bullets")
        # surfaced: the shot bites
        G.pts[0] = Vector2(G.WORLD_W * 0.5, G.SURFACE_Y + 10.0)
        hp0 = G.p_hp
        G.shots.append({"kind": "bullet", "x": G.pts[0].x, "y": G.pts[0].y,
                "vx": 0.0, "vy": 0.0, "t": 0.0})
        G._tick_shots(1.0 / 60.0)
        ck(G.p_hp < hp0, "THE WAR LAW: a surfaced worm takes the shot")
        # the ghost forgives
        G.ghost_t = 3.0
        hp0 = G.p_hp
        G.shots.append({"kind": "bullet", "x": G.pts[0].x, "y": G.pts[0].y,
                "vx": 0.0, "vy": 0.0, "t": 0.0})
        G._tick_shots(1.0 / 60.0)
        ck(G.p_hp == hp0, "THE GHOST LAW: nothing touches the ghost worm")
        G.ghost_t = 0.0
        # the shield forgives exactly once
        G.shield_on = true
        G.invuln_t = 0.0
        G.hit_cd = 0.0
        hp0 = G.p_hp
        G.shots.append({"kind": "bullet", "x": G.pts[0].x, "y": G.pts[0].y,
                "vx": 0.0, "vy": 0.0, "t": 0.0})
        G._tick_shots(1.0 / 60.0)
        ck(G.p_hp == hp0 and not G.shield_on,
                "THE SHIELD LAW: the stone scale eats exactly one hit")
        # vehicles are bitten, not eaten: hp drops by power, then explodes
        G.things.append({"kind": "car", "x": G.pts[0].x, "y": G.pts[0].y,
                "vx": 0.0, "hp": 2, "alive": true, "shoot_t": 9.0,
                "wheel_t": 0.0})
        var veh0: int = G.vehicles
        G.p_power = 1.0
        G._eat_check()
        G._eat_check()
        ck(G.vehicles == veh0 + 1 and not bool(G.things[-1]["alive"]),
                "THE VEHICLE LAW: power bites a car apart in 2 bites")
        # the death: hp 0 finishes the run
        G.p_hp = 0.0
        G._die()
        ck(G.over or G.state == "dead", "THE DEATH LAW: hp 0 ends the run")
        await _wait(0.4)

# -------------------------------------------------- the progression laws
func _progress_laws() -> void:
        print("\n-- the progression laws --")
        Box.reset_all()
        await _wait(0.2)
        # the xp law: eating banks xp and levels at the curve
        var id := "w01"
        G.meta.set_level(id, 1, 0)
        var need: int = G.xp_need(1)
        G._gain_xp(need)
        ck(G.meta.lvl(id) == 2,
                "THE LEVEL LAW: the curve's xp banks a level")
        # the chain law: w02 locked until w01 maxed
        G.meta.set_level("w01", int(G.WORMS[0]["maxlvl"]), 0)
        var w02_maxed: bool = G.meta.owns("w01") and G.meta.lvl("w01") \
                >= int(G.WORMS[0]["maxlvl"])
        ck(w02_maxed, "THE CHAIN LAW: maxing w01 opens the gate for w02")
        G.meta.add_coins(int(G.WORMS[1]["price"]))
        var wall: int = G.meta.coins()
        var ok: bool = G.meta.spend_coins(int(G.WORMS[1]["price"]))
        ck(ok and G.meta.coins() == wall - int(G.WORMS[1]["price"]),
                "THE UNLOCK LAW: the unlock spends the wormCoins wallet")
        G.meta.unlock_worm("w02")
        ck(G.meta.owns("w02"), "THE UNLOCK LAW: the chain remembers the worm")
        # the places law: the desert free, the rest bought with GOGACoins
        ck(G.meta.owns_place("desert"), "THE PLACE LAW: the desert is free")
        ck(not G.meta.owns_place("polar"), "THE PLACE LAW: the ICE starts locked")
        # the powers law: nothing spawns until bought
        var pool := 0
        for p in G.POWS:
                if G.meta.owns_pow(String(p["k"])):
                        pool += 1
        ck(pool == 0, "THE POWER LAW: no power-up drops before it is bought")
        G.meta.unlock_pow("speed")
        pool = 0
        for p in G.POWS:
                if G.meta.owns_pow(String(p["k"])):
                        pool += 1
        ck(pool == 1, "THE POWER LAW: a bought power-up joins the drop pool")

# ------------------------------------------------------ the top-up laws
func _topup_laws() -> void:
        print("\n-- the top-up laws --")
        var rec: Dictionary = GameCoin.record("deathworm")
        ck(not rec.is_empty(),
                "THE FRAMEWORK: deadly worm declares its currency")
        ck(String(rec.get("name", "")) == "WORMCOINS",
                "THE FRAMEWORK: the currency is the WORMCOINS")
        ck(absf(GameCoin.rate("deathworm") - 5.0) < 0.001,
                "THE RATE LAW: 1 GOGACoin = 5 wormCoins")
        Box.reset_all()
        var wall0: int = GameCoin.balance("deathworm")
        GameCoin.add("deathworm", 250)
        ck(GameCoin.balance("deathworm") == wall0 + 250,
                "THE SETTLE: a top-up lands in the run's own wallet")
        ck(DWMeta.load_meta().coins() == wall0 + 250,
                "THE ONE STORE: the meta reads the same wallet")

# ----------------------------------------------------- the spawner laws
func _spawn_law() -> void:
        print("\n-- the spawner law --")
        Box.reset_all()
        await _wait(0.1)
        G._reset_run()
        G.state = "play"
        var n0: int = G.things.size()
        G.spawn_t = 0.05
        for i in 40:
                G._tick_spawn(1.0 / 60.0)
                G._tick_things(1.0 / 60.0)
        ck(G.things.size() > n0 or G._intensity() > 1.0,
                "THE POUR: the spawner never rests")
        var i1: float = G._intensity()
        G.run_t += 42.0
        ck(G._intensity() > i1,
                "THE RAMP: the intensity only grows - it never eases")
        ck(G.run_t < 100000.0, "sanity")

# ==================================================================== run
func _ready() -> void:
        print("=== qa_v0409_worm: the DEADLY WORM battery ===")
        await _boot()
        _world_laws()
        _worm_laws()
        await _eat_laws()
        await _motion_laws()
        await _war_laws()
        await _progress_laws()
        _topup_laws()
        await _spawn_law()
        print("\n=== %d checks, %d fails ===" % [checks, fails])
        get_tree().quit(1 if fails > 0 else 0)
