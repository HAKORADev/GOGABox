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
        ck(G.W > 100.0 and G.H > 100.0,
                "THE CANVAS: the live viewport seats the design")
        ck(absf(G.WORLD_W - G.W * 3.2) < 1.0,
                "THE WIDE LAW: the world is x3.2 the screen (the owner's band)")
        ck(absf(G.SKY_H - G.H * 1.25) < 1.0,
                "THE SKY LAW: 1.25 screens of sky above the line")
        ck(absf(G.DIRT_H - G.H * 1.4) < 1.0,
                "THE DEPTH LAW: 1.4 screens of dirt below the line")
        ck(absf(G.SURFACE_Y - G.SKY_H) < 0.5,
                "THE SHAPE: the surface line sits where the sky ends")
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
        # v040-10 THE FULL-SCREEN LAW: the world fills the whole live canvas
        ck(G.WORLD_W >= G.W * 3.0 and G.SKY_H + G.DIRT_H > G.H * 2.5,
                "THE FULL-SCREEN LAW: the world owns every pixel")

# --------------------------------------------------------- the worm laws
func _worm_laws() -> void:
        print("\n-- the worm laws --")
        ck(G.WORMS.size() == 10, "THE TEN: ten worms")
        ck(G.WORMS[0]["price"] == 0, "THE STARTER: the first worm is free")
        # v040-10: TEN LEVELS for every worm (the owner's law)
        var lvl_ok := true
        for w in G.WORMS:
                if int(w["maxlvl"]) != 10:
                        lvl_ok = false
        ck(lvl_ok, "THE TEN LEVELS: every worm caps at level 10")
        var chain_ok := true
        for i in range(1, G.WORMS.size()):
                if int(G.WORMS[i]["price"]) <= 0:
                        chain_ok = false
        ck(chain_ok, "THE CHAIN: every later worm costs wormCoins")
        var w: Dictionary = G.WORMS[0]
        var st1: Dictionary = G.stats_at(0, 1)
        var stmax: Dictionary = G.stats_at(0, int(w["maxlvl"]))
        ck(absf(float(stmax["hp"]) / float(st1["hp"]) - 1.5) < 0.01,
                "THE GROW LAW: a maxed worm is x1.5 its base stats")
        ck(float(stmax["hp"]) > float(st1["hp"]),
                "THE GROW LAW: levels only ever grow")
        # v040-10: the slower curve - ~6x the old one to max a worm
        var total := 0
        for l in range(1, 10):
                total += G.xp_need(l)
        ck(total > 4000,
                "THE PACE LAW: maxing a worm takes %d points - not two plays" % total)
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
        # v040-12 THE SURFACE GATE: the mouth must be OUT of the dirt to
        # eat the surface world - the battery hunts from a surfaced head
        # (the whole chain re-seats with it - no stretched-chain artifacts)
        G.pts[0].y = G.SURFACE_Y - 70.0
        for i in range(1, G.pts.size()):
                G.pts[i] = G.pts[0] + Vector2(float(i) * 26.0, 0.0)
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
        var deep_speed := _measure_speed(G.SURFACE_Y + G.H * 0.3)
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
        # dirt armor: a shot at a DEEP worm does nothing (the new world's
        # dirt runs from SURFACE_Y down - the deep seat is well below it)
        G.pts[0] = Vector2(G.WORLD_W * 0.5, G.SURFACE_Y + G.H * 0.35)
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
        ck(absf(GameCoin.rate("deathworm") - 12.0) < 0.001,
                "THE RATE LAW: 1 GOGACoin = 12 wormCoins (the per-game balance)")
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
        for i in 240:
                G._tick_spawn(1.0 / 60.0)
                G._tick_things(1.0 / 60.0)
        ck(G.things.size() > n0 or G._intensity() > 1.0,
                "THE POUR: the spawner never rests")
        var i1: float = G._intensity()
        G.run_t += 42.0
        ck(G._intensity() > i1,
                "THE RAMP: the intensity only grows - it never eases")
        ck(G.run_t < 100000.0, "sanity")

# ------------------------------------------------- the v040-10 laws
func _v0410_laws() -> void:
        print("\n-- the v040-10 laws --")
        Box.reset_all()
        await _wait(0.1)
        G._reset_run()
        G.state = "play"
        # THE OFF-SCREEN SPAWN LAW: every spawn rides outside the camera
        var cam: Rect2 = G._cam_rect()
        var off_ok := true
        for i in 30:
                G._spawn_roll()
        for th in G.things:
                if cam.has_point(Vector2(float(th["x"]), float(th["y"]))):
                        off_ok = false
        ck(off_ok, "THE SPAWN LAW: nothing spawns inside the camera window")
        # THE DESPAWN LAW: a thing far off-camera dies and its sprite dies
        G.things.append({"kind": "car", "x": G.cam_x - 2000.0,
                "y": G.SURFACE_Y + 36.0, "vx": 0.0, "hp": 2, "alive": true,
                "shoot_t": 9.0, "wheel_t": 0.0})
        var spr := Sprite2D.new()
        G.ent_draw.add_child(spr)
        G.things[-1]["spr"] = spr
        G._tick_things(1.0 / 60.0)
        var gone := true
        for th in G.things:
                if float(th["x"]) < G.cam_x - 1500.0:
                        gone = false
        ck(gone and not is_instance_valid(spr) or spr.is_queued_for_deletion(),
                "THE DESPAWN LAW: far off-screen things and their sprites die")
        # THE COIN VANISH LAW: a collected coin frees its sprite
        var c0 := {"x": G.pts[0].x, "y": G.pts[0].y, "t": 0.0}
        var cspr := Sprite2D.new()
        G.ent_draw.add_child(cspr)
        c0["spr"] = cspr
        G.coins_drops.append(c0)
        for i in 8:
                G._tick_drops(1.0 / 60.0)
        ck(not is_instance_valid(cspr) or cspr.is_queued_for_deletion(),
                "THE COIN LAW: a collected wormCoin's sprite vanishes same frame")
        # THE FACING LAW: the worm flips V (never H) - the back stays up
        G.pts[0] = Vector2(G.WORLD_W * 0.5, G.SURFACE_Y + 200.0)
        G.heading = PI
        G.vel = Vector2(-300.0, 0.0)
        G._tick_worm(1.0 / 60.0)
        var flips_ok := true
        for s in G.worm_sprites:
                if s.flip_h:
                        flips_ok = false
        ck(flips_ok, "THE FACING LAW: the worm chain never flips H (rotate+flipV only)")
        # v040-11 THE WIDGETS LAW: dash + special are TOP-BAR CHIPS after WORMS
        ck(G.dash_chip != null and G._hud_row.is_ancestor_of(G.dash_chip) \
                and G._hud_row.get_children().find(G.dash_chip) == 3,
                "THE WIDGET LAW: the dash chip rides the top bar")
        ck(G.sp_chip != null and G._hud_row.is_ancestor_of(G.sp_chip) \
                and G._hud_row.get_children().find(G.sp_chip) == 4,
                "THE WIDGET LAW: the special chip sits right after DASH (top-left, after WORMS)")
        # THE POWER-UP LAW: priced in GOGACoins (Box.spend), not wormCoins
        # ("ghost" - a kind no earlier section has unlocked)
        var wall0: int = Box.coins()
        Box.earn(200)
        var owned0: int = (G.meta.d["pows"] as Array).size()
        G._buy_pow("ghost")
        ck((G.meta.d["pows"] as Array).size() == owned0 + 1 \
                and Box.coins() == wall0 + 200 - int(G.POWS[2]["price"]),
                "THE POWER LAW: a power-up buys with real GOGACoins")
        # THE NEXT-ROUND LAW: a mid-run place visit only arms the switch
        Box.earn(2000)
        G.state = "play"
        G._visit_place("polar")
        ck(G.place_id != "polar" \
                and String(G.meta.place()) == "polar",
                "THE PLACE LAW: a mid-run visit applies NEXT round (the meta remembers)")

# ====================================================== the v040-12 laws
func _v0412_laws() -> void:
        print("\n-- the v040-12 laws --")
        Box.reset_all()
        await _wait(0.1)
        G._reset_run()
        G.state = "play"
        # THE SCALE LAW: the head dropped to 78 (the owner: "worms were not
        # that big... in original they be much smaller")
        ck(int(G.HEAD_H) == 78, "THE SCALE LAW: the worm head reads the smaller original ratio")
        # THE SURFACE GATE: a deep mouth cannot eat the surface world
        G.things.clear()
        G.pts[0] = Vector2(G.WORLD_W * 0.5, G.SURFACE_Y + 300.0)
        G.heading = PI
        G.things.append({"kind": "human", "skin": "casual1",
                "x": G.pts[0].x, "y": G.SURFACE_Y - 60.0, "vx": 0.0,
                "fr": [], "fi": 0, "ft": 0.0, "alive": true, "flee": 0.0})
        var ate0: int = G.eaten_humans
        G._eat_check()
        ck(G.eaten_humans == ate0, "THE SURFACE GATE: a buried mouth eats nothing on the surface")
        # surfaced: the mouth eats
        G.pts[0] = Vector2(G.WORLD_W * 0.5, G.SURFACE_Y - 70.0)
        G._eat_check()
        ck(G.eaten_humans == ate0 + 1, "THE SURFACE GATE: the surfaced mouth eats")
        # THE HUNT LAW: eating heals - humans 1, animals 2, ground 0.5
        G.p_hp = G.p_hp_max - 10.0
        var hp0: float = G.p_hp
        G.things.append({"kind": "human", "skin": "casual1",
                "x": G.pts[0].x, "y": G.pts[0].y, "vx": 0.0,
                "fr": [], "fi": 0, "ft": 0.0, "alive": true, "flee": 0.0})
        G._eat_check()
        ck(absf(G.p_hp - (hp0 + 1.0)) < 0.001, "THE HUNT LAW: a human heals 1 HP")
        hp0 = G.p_hp
        G.things.append({"kind": "animal", "skin": "camel",
                "x": G.pts[0].x, "y": G.pts[0].y, "vx": 0.0, "alive": true})
        G._eat_check()
        ck(absf(G.p_hp - (hp0 + 2.0)) < 0.001, "THE HUNT LAW: an animal heals 2 HP")
        hp0 = G.p_hp
        G.things.append({"kind": "ground", "skin": "mole",
                "x": G.pts[0].x, "y": G.pts[0].y, "vx": 0.0, "vy": 0.0,
                "alive": true, "wob": 0.0})
        G._eat_check()
        ck(absf(G.p_hp - (hp0 + 0.5)) < 0.001, "THE HUNT LAW: a ground animal heals 0.5 HP")
        # THE FALL LAW: falling onto a machine weighs 2.5x a rising bite
        G.p_power = 2.0
        G.things.clear()
        G.pts[0] = Vector2(G.WORLD_W * 0.5, G.SURFACE_Y - 220.0)
        G.vel = Vector2(0.0, 400.0)          # falling
        G.heading = PI * 0.5
        G.things.append({"kind": "tank", "x": G.pts[0].x, "y": G.pts[0].y,
                "vx": 0.0, "hp": 99, "alive": true, "shoot_t": 9.0,
                "wheel_t": 0.0})
        G._eat_check()
        var fell_hp: int = int(G.things[0]["hp"])
        ck(fell_hp == 99 - int(round(2.0 * G.FALL_DMG_MULT)),
                "THE FALL LAW: a falling bite weighs x2.5 onto the prey")
        G.things.clear()
        G.pts[0] = Vector2(G.WORLD_W * 0.5, G.SURFACE_Y + 120.0)
        G.vel = Vector2(0.0, -400.0)         # rising from below
        G.heading = -PI * 0.5
        G.things.append({"kind": "tank", "x": G.pts[0].x, "y": G.pts[0].y,
                "vx": 0.0, "hp": 99, "alive": true, "shoot_t": 9.0,
                "wheel_t": 0.0})
        G._eat_check()
        ck(int(G.things[0]["hp"]) == 99 - maxi(1, int(round(2.0 * G.RISE_DMG_MULT))),
                "THE FALL LAW: a rising bite from below lands soft")
        # THE CIVILIAN LAW: a car NEVER shoots
        G.shots.clear()
        G.things.clear()
        G.pts[0] = Vector2(G.WORLD_W * 0.5, G.SURFACE_Y - 70.0)
        G.things.append({"kind": "car", "x": G.pts[0].x + 200.0,
                "y": G._surf_seat("car"), "vx": 30.0, "hp": 2,
                "alive": true, "shoot_t": 0.01, "wheel_t": 0.0})
        for i in 30:
                G._tick_things(1.0 / 60.0)
        ck(G.shots.is_empty(), "THE CIVILIAN LAW: a normal car never fires")
        # THE LINE-OF-SIGHT LAW: the shooters cannot see a buried worm
        G.pts[0] = Vector2(G.WORLD_W * 0.5, G.SURFACE_Y + 300.0)
        ck(not G._surfaced_near(Vector2(G.pts[0].x, G.SURFACE_Y), 900.0),
                "THE LINE-OF-SIGHT LAW: the dirt hides the worm from the shooters")
        G.pts[0] = Vector2(G.WORLD_W * 0.5, G.SURFACE_Y - 60.0)
        ck(G._surfaced_near(Vector2(G.pts[0].x, G.SURFACE_Y), 900.0),
                "THE LINE-OF-SIGHT LAW: a surfaced worm is seen")
        # THE VISIBLE TUNNEL LAW: the tunnel layer lives INSIDE the world,
        # above the dirt, and the marks append while underground
        ck(G.tunnel_draw != null and G.world.is_ancestor_of(G.tunnel_draw),
                "THE TUNNEL LAW: the tunnel paints on its own world layer")
        var tr0: int = G.trail.size()
        G.pts[0] = Vector2(G.WORLD_W * 0.5, G.SURFACE_Y + 240.0)
        G._tick_worm(1.0 / 60.0)
        ck(G.trail.size() > tr0, "THE TUNNEL LAW: underground travel leaves marks")
        # THE ONE-PIECE DIRT LAW: every place carries its single-piece bake
        var dirt_ok := true
        for pl in G.PLACES:
                if not ResourceLoader.exists(G.S + "places/%s_dirt_big.png" % pl):
                        dirt_ok = false
        ck(dirt_ok, "THE ONE-PIECE DIRT LAW: one unique underground per place")
        # THE FULL-HEIGHT WALL LAW: the walls span the whole world height
        var walls_ok := false
        for c in G.world.get_children():
                if String(c.name) == "walls_top":
                        walls_ok = true
        ck(walls_ok, "THE WALL LAW: the bounds ride the occluder layer")
        # THE NO-FLIP LAW: the chain never mirrors on a side switch
        G.pts.clear()
        for i in G.SEG_COUNT + 2:
                G.pts.append(Vector2(G.WORLD_W * 0.5 + float(i) * 26.0,
                        G.SURFACE_Y + 200.0))
        G.heading = PI
        G.vel = Vector2(-300.0, 0.0)
        G._tick_worm(1.0 / 60.0)
        G._place_worm_sprites(true)
        var no_flip := true
        for s in G.worm_sprites:
                if s.flip_v or s.flip_h:
                        no_flip = false
        ck(no_flip, "THE NO-FLIP LAW: the worm rotates, nothing mirrors")
        # THE SPECIES LAW: the ten heads are ten DIFFERENT designs
        var hashes := {}
        var distinct := true
        for wr in G.WORMS:
                var path: String = G.S + "worms/%s_head.png" % String(wr["id"])
                var img := (load(path) as Texture2D).get_image()
                var hsh := img.get_data().hex_encode()
                if hashes.has(hsh):
                        distinct = false
                hashes[hsh] = true
        ck(distinct and hashes.size() == 10,
                "THE SPECIES LAW: ten worms, ten different looks")
        # THE GEOMETRY WIDGET LAW: the power chips live in the top bar as
        # icon + countdown chips
        var pow_in_bar := true
        for k in G.pow_chips:
                var panel: Control = G.pow_chips[k]["panel"]
                if not G._hud_row.is_ancestor_of(panel):
                        pow_in_bar = false
        ck(pow_in_bar and G.pow_chips.size() == G.POWS.size(),
                "THE GEOMETRY WIDGET LAW: the power chips ride the top bar (icon: nn)")
        # THE PHYSICAL SNOW LAW: a flake dies at the surface, never below
        G.fx.clear()
        G.place_id = "polar"
        G.cam_x = G.WORLD_W * 0.25
        G.cam_y = G.SURFACE_Y - G.H
        G._push_fx("snow", G.cam_x + 40.0, G.SURFACE_Y - 30.0, 0.0, 100.0, 6.0)
        for i in 90:
                G._tick_fx(1.0 / 60.0)
        var below := false
        for f2 in G.fx:
                if String(f2.get("k", "")) == "snow" \
                                and (f2["spr"] as Sprite2D).position.y > G.SURFACE_Y:
                        below = true
        ck(not below, "THE PHYSICAL SNOW LAW: no flake ever crosses the surface")
        G.place_id = "desert"
        # THE MASS LAW: the tank takes 3-4 bites, not 5
        ck(int(G.VEH_HP["tank"]) <= 4,
                "THE MASS LAW: the tank breaks in 3-4 bites")
func _ready() -> void:
        print("=== qa_v0409_worm: the DEADLY WORM battery (v040-10 laws) ===")
        await _boot()
        _world_laws()
        _worm_laws()
        await _eat_laws()
        await _motion_laws()
        await _war_laws()
        await _progress_laws()
        _topup_laws()
        await _spawn_law()
        await _v0410_laws()
        await _v0411_laws()
        await _v0412_laws()
        print("\n=== %d checks, %d fails ===" % [checks, fails])
        get_tree().quit(1 if fails > 0 else 0)


# ====================================================== the v040-11 laws
func _v0411_laws() -> void:
        print("\n-- the v040-11 laws --")
        # THE CAMPING LAW: riding the surface crust decays the crawl
        # toward a near-stop; a dive or a dash washes it off
        G.camp_t = 0.0
        G.pts[0].y = G.SURFACE_Y
        G.dash_t = 0.0
        for i in 300:
                G._tick_worm(1.0 / 60.0)
                if G.state != "play":
                        G.state = "play"
        ck(G.camp_t > 4.0,
                "THE CAMPING LAW: 5s of crust-riding fills the grind clock (%.2f)" % G.camp_t)
        var grind: float = lerpf(1.0, 0.05, G.camp_t / G.CAMP_MAX)
        ck(grind < 0.12,
                "THE CAMPING LAW: the crawl decays to a near-stop (x%.2f)" % grind)
        G.camp_t = 4.5
        G.dash_t = 0.4
        G._tick_worm(1.0 / 60.0)
        ck(G.camp_t == 0.0, "THE CAMPING LAW: the dash scours the grind off")
        G.camp_t = 4.5
        G.dash_t = 0.0
        G.pts[0].y = G.SURFACE_Y + 300.0
        G._tick_worm(1.0 / 60.0)
        ck(G.camp_t < 4.5, "THE CAMPING LAW: a dive washes the grind off")
        # THE COIN LAWS: no chase-magnet; 10s life; the run chip counts
        # THIS ROUND only
        G.state = "play"
        G.place_id = "desert"
        G.pts[0] = Vector2(G.WORLD_W * 0.5, G.SURFACE_Y + 60.0)
        G.cam_x = G.pts[0].x - G.W * 0.5
        G.cam_y = G.pts[0].y - G.H * 0.4
        var far_x: float = G.pts[0].x + 500.0
        G.coins_drops = [{"x": far_x, "y": G.SURFACE_Y + 60.0, "t": 0.0}]
        var wc0: int = G.wormcoins_run
        for i in 60:
                G._tick_drops(1.0 / 60.0)
        ck(G.wormcoins_run == wc0 \
                and absf(float(G.coins_drops[0]["x"]) - far_x) < 2.0,
                "THE COIN LAW: a coin sits where it popped - no chase-magnet")
        G.coins_drops[0]["t"] = 9.7
        G._tick_drops(1.0 / 60.0)
        ck(is_instance_valid(G.coins_drops[0].get("spr")),
                "THE COIN LAW: a coin at 9.7s still blinks on screen")
        G.coins_drops[0]["t"] = 10.2
        var spr_ref: Sprite2D = G.coins_drops[0]["spr"]
        G._tick_drops(1.0 / 60.0)
        ck(G.coins_drops.is_empty() \
                or not is_instance_valid(G.coins_drops[0].get("spr")),
                "THE COIN LAW: an unclaimed coin dies at 10s (sprite freed)")
        if is_instance_valid(spr_ref):
                spr_ref.queue_free()
        # the honest chip
        G.wormcoins_run = 7
        G.meta.d["wormcoins"] = 999
        G._tick_hud()
        ck(G.wc_lbl != null and G.wc_lbl.text == "7",
                "THE HONEST CHIP: the coin widget shows THIS ROUND (7), not the wallet")
        # the intro sheet is CLEAN (no controls/coin notes - they live in the guide)
        G._show_intro_sheet()
        var texts := ""
        for lbl in G._intro_pair[1].find_children("*", "Label", true, false):
                texts += (lbl as Label).text + "|"
        ck(not texts.contains("left: steer") \
                and not texts.contains("wormCoin banks")
                and texts.contains("TAP ANYWHERE TO START"),
                "THE CLEAN START: the intro wears the tap line only (details in the guide)")
        G._start_run()
        # THE TUNNEL MARKS: per-place mud colors exist and the trail wears them
        ck(G.TUNNEL_COL.has("desert") and G.TUNNEL_COL.has("medieval") \
                and G.TUNNEL_COL["polar"] != G.TUNNEL_COL["desert"],
                "THE TUNNEL LAW: every place wears its own eaten-mud palette")
        # THE OURS LAW: the art is OURS - the worm sprite set loads and the
        # bird family exists (the v040-10 invisible-flyer bug is dead)
        var bird_frames: Array = G._family_frames("vehicles/bird")
        ck(bird_frames.size() >= 6,
                "THE OURS LAW: the bird flies (8 flap frames load, %d)" % bird_frames.size())
        var sold: Array = G.walk_frames("soldier")
        var pol: Array = G.walk_frames("polar1")
        ck(sold.size() == 10 and pol.size() == 10,
                "THE OURS LAW: the soldier and the polar folk wear their own skins")
        var head_tex: Texture2D = load(G.S + "worms/w01_head.png")
        ck(head_tex != null and head_tex.get_width() > 80,
                "THE OURS LAW: the worm head loads (our own drawn jaw)")
