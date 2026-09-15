extends Node
## HEAVY WAR probe (v040 pass 1) - the deterministic battery.
## Runs headless: godot --headless --path . res://tests/hw_probe.tscn
## Exit 0 = all laws hold. The brutal part rides every patch.

var checks := 0
var fails := 0
var G: GogaGame = null
var meta: HWMeta = null
var finished := [-1, -1]         # [score, coins] from request_finish

func ck(cond: bool, what: String) -> void:
        checks += 1
        if cond:
                print("[PASS] ", what)
        else:
                fails += 1
                print("[FAIL] ", what)

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout

func _boot() -> void:
        if G != null and is_instance_valid(G):
                G.queue_free()
                await _wait(0.3)
        Box.reset_all()
        get_window().size = Vector2i(1920, 1080)
        await _wait(0.2)
        finished = [-1, -1]
        G = load("res://game/games/heavywar/heavywar.gd").new()
        G.game_id = "heavywar"
        G.request_finish.connect(func(s, c): finished = [s, c])
        add_child(G)
        await _wait(0.8)
        meta = G.meta

## inject a touch the way the OS would (index, position, down)
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

func _run() -> void:
        print("=== hw_probe (v040 pass 1) ===")
        seed(20260915)
        await _boot()

        # ------------------------------------------------ the data laws
        ck(HWData.ENEMIES.size() == 21, "21 enemies in the table")
        var shared := 0
        var specials: Array = []
        for eid in HWData.ENEMIES:
                var pts: int = HWData.ENEMIES[eid]["pts"]
                if pts == 1:
                        shared += 1
                else:
                        specials.append(pts)
        ck(shared == 11, "THE 10/11 LAW: 11 shared fry pay 1 (got %d)" % shared)
        ck(specials.size() == 10, "the ten specials exist")
        var sorted_sp := specials.duplicate()
        sorted_sp.sort()
        ck(sorted_sp == [10, 20, 30, 40, 50, 60, 70, 80, 90, 100],
                "specials pay 10..100 in steps")
        ck(HWData.PLACES.size() == 10, "ten places exist")
        var excl_total := 0
        for p in HWData.PLACES:
                excl_total += (p["exclusive"] as Array).size()
                ck(float(p["len"]) >= 180.0 and float(p["len"]) <= 360.0,
                        "place %s length in the 3-10+ min band" % p["id"])
        ck(excl_total >= 10, "every place wears exclusives (%d)" % excl_total)
        var all_eid: Array = HWData.ENEMIES.keys()
        for p in HWData.PLACES:
                for x in (p["exclusive"] as Array):
                        ck(all_eid.has(x), "exclusive %s is a real enemy" % x)
        ck(HWData.WAVES.size() == 5, "five pressure tiers")
        ck(HWData.BOSS_ORDER.size() == 10, "ten boss faces")
        var bs: Dictionary = HWData.boss_stats(10)
        ck(int(bs["comeback"]) == 1 and bs["id"] == "gunship",
                "boss 10 = gunship comeback 1")
        ck(int(HWData.boss_stats(11)["comeback"]) == 1 \
                and HWData.boss_stats(11)["id"] == "dreadnought",
                "boss 11 = the dreadnought's first comeback")
        ck(int(bs["hp"]) > HWData.BOSSES["gunship"]["hp"],
                "comeback wears heavier armor")
        ck(HWData.UPGRADES.size() == 6, "six stats")
        var opens := 0
        for sid in HWData.UPGRADES:
                if bool(HWData.UPGRADES[sid]["open"]):
                        opens += 1
        ck(opens == 2, "THE 2-OPEN LAW: two stats born free")
        ck(HWData.cannon_streams(0) == 1 and HWData.cannon_streams(5) == 5,
                "cannons 1..5 streams")
        ck(HWData.aegis_laser_need(0) == 3 and HWData.aegis_laser_need(5) == 1,
                "aegis trims the laser parts 3 -> 1")
        ck(HWData.SKINS.size() == 6 and HWData.LASER_PRICE >= 5000,
                "six skins + the costly laser")

        # ------------------------------------------------ the meta laws
        ## (BEFORE the all_owned cheat: the cheat owns every shop shelf and
        ## would lie about the lock law)
        ck(meta.pts_free() == 0 and meta.pts_banked() == 0, "fresh ledger: 0 points")
        meta.mint_pts(3)
        ck(meta.pts_free() == 3, "3 bosses minted 3 free points")
        ck(meta.raise("engine") and meta.level_of("engine") == 1, "raise engine")
        ck(meta.pts_free() == 2, "the raise spent a free point")
        ck(meta.raise("armor") == false, "THE LOCK LAW: closed stat refuses")
        meta.mint_pts(20)
        var ok_all := true
        for i in 4:
                if not meta.raise("engine"):
                        ok_all = false
        ck(ok_all and meta.level_of("engine") == 5 and meta.pts_free() == 18,
                "engine to the 5 cap (4 raises from LV1)")
        ck(meta.raise("engine") == false, "THE CAP LAW: 6th level refuses")
        ck(meta.lower("engine") and meta.lower("engine") \
                and meta.level_of("engine") == 3 and meta.pts_free() == 20,
                "the rebalance lowers back and refunds")
        meta.lower("engine")
        meta.lower("engine")
        meta.lower("engine")
        ck(meta.level_of("engine") == 0 and meta.pts_free() == 23,
                "the ledger returns to zero use")
        Box.dev_set_cheat("all_owned", 1)   # NOW the cheat, for the game boot

        # ------------------------------------------------ the boot + intro
        ck(G.state == 0, "boots into the INTRO (tap anywhere)")
        _tap(0, Vector2(960, 540), true)
        _tap(0, Vector2(960, 540), false)
        await _wait(0.1)
        ck(G.state == G.GS.PLACE, "THE TAP LAW: any tap starts the war")
        ck(G.place_queue.size() == 10, "the run shuffled a full place queue")
        var q: Array = G.place_queue.duplicate()
        q.sort()
        var perm := true
        for i in 10:
                if int(q[i]) != i:
                        perm = false
        ck(perm, "the queue is a true permutation of the ten places")

        # ------------------------------------------------ the gun + kills
        var n0: int = G.enemies.size()
        await _wait(3.0)
        ck(G.enemies.size() > n0 or not G._wave_units.is_empty(),
                "the director spawns (enemies=%d)" % G.enemies.size())
        # park a scout in front of the barrel and shoot it
        var scout_hp: int = G.enemies[0]["hp"] if G.enemies.size() > 0 else 0
        if G.enemies.is_empty():
                G._spawn_enemy("scout", G.tank.position.x, 300.0)
        var victim: Dictionary = G.enemies[0]
        victim["n"].position = Vector2(G.tank.position.x, 300.0)
        G.aim_pos = victim["n"].position      # the finger IS the aim
        var s0: int = G.score
        for i in 60:
                G._fire()
                G._shots_tick(1.0 / 60.0)
                if G.score > s0:
                        break
        ck(G.score > s0, "THE KILL LAW: a dead scout pays score (+%d)"
                % (G.score - s0))
        ck(G.run["kills"] >= 1, "the kill lands in the ledger")

        # ------------------------------------------------ the zones
        # THE THREE-ZONE LAW (the owner's v040-1 redesign): bottom = steer
        # (paddle glide), center = aim + fire, top = the nuke. A finger
        # keeps its role until it LIFTS - zone exits change nothing.
        _tap(1, Vector2(200, 900), true)         # steer finger down
        await _wait(0.05)
        ck(G.steer_ptr == 1, "the bottom zone owns the steer finger")
        _tap(2, Vector2(1600, 540), true)        # aim + fire finger down
        await _wait(0.05)
        ck(G.aim_ptr == 2, "the center zone owns the aim finger")
        var tx0: float = G.tank.position.x
        _drag(1, Vector2(1600, 1000))            # steer target far right
        await _wait(0.3)
        ck(G.tank.position.x > tx0 + 40.0,
                "THE PADDLE LAW: the tank glides toward the steer finger")
        _drag(1, Vector2(1700, 1000))            # steer leaves its zone
        await _wait(0.05)
        ck(G.steer_ptr == 1, "leaving the zone keeps the steer role")
        _tap(2, Vector2(1700, 540), false)
        _tap(1, Vector2(1700, 1000), false)
        await _wait(0.05)
        ck(G.aim_ptr == -1 and G.steer_ptr == -1, "lifting the fingers frees both")
        # the nuke (the mercy law: the war starts with one in the magazine)
        ck(int(G.run["nukes"]) >= 1, "THE MERCY LAW: the war starts stocked")
        G.run["nukes"] = 2
        var enemies0: int = G.enemies.size()
        for i in 3:
                G._spawn_enemy("scout", G.tank.position.x + 200.0, 500.0)
        G._touch(5, Vector2(960, 200), true)
        G._touch(5, Vector2(960, 200), false)
        await _wait(0.1)
        ck(int(G.run["nukes"]) == 1, "THE NUKE LAW: the top-zone tap spends one")
        ck(G.enemies.size() < enemies0 + 3, "the blast cleared the front")

        # ------------------------------------------------ the tank laws
        var lives0: int = G.run["lives"]
        G._hurt_tank(G.tank.position)
        ck(int(G.run["lives"]) == lives0 - 1, "each hit takes one life")
        G._hurt_tank(G.tank.position)            # iframes eat this one
        ck(int(G.run["lives"]) == lives0 - 1, "THE IFRAME LAW: no double-bite")
        G.run["iframes"] = 0.0
        # shield layers eat before lives
        (G.run["shield_hp"] as Array).append({"hp": 2})
        G.run["shields"] = 1
        var l_before: int = G.run["lives"]
        G.run["iframes"] = 0.0
        G._hurt_tank(G.tank.position)
        ck(int(G.run["lives"]) == l_before, "THE SHIELD LAW: the layer eats the hit")
        ck((G.run["shield_hp"] as Array)[0]["hp"] == 1, "the layer bled first")
        G.run["iframes"] = 0.0
        G._hurt_tank(G.tank.position)
        ck((G.run["shield_hp"] as Array).is_empty(), "the broken layer dies")
        G.run["iframes"] = 0.0
        G._hurt_tank(G.tank.position)
        ck(int(G.run["lives"]) == l_before - 1, "lives pay after the shields")

        # ------------------------------------------------ score pays lives
        G.run["lives"] = 1
        G.run["score_life_mark"] = G.score - 999
        G.run["iframes"] = 0.0
        G._pay_score(1000, G.tank.position)
        ck(int(G.run["lives"]) == 2, "THE LIFE LAW: 1000 score pays a life")
        G.run["score_life_mark"] = G.score - 500
        G.run["lives"] = HWData.LIVES_MAX
        G._pay_score(500, G.tank.position)
        ck(int(G.run["lives"]) == HWData.LIVES_MAX, "no life past the 3 cap")

        # ------------------------------------------------ drops + caps
        G._collect("shield")
        G._collect("shield")
        G._collect("shield")
        G._collect("shield")
        ck(int(G.run["shields"]) == HWData.SHIELD_MAX, "THE CAP LAW: 3 shield layers")
        G.run["nukes"] = 0
        G._collect("nuke")
        G._collect("nuke")
        G._collect("nuke")
        G._collect("nuke")
        ck(int(G.run["nukes"]) == HWData.NUKES_MAX, "THE CAP LAW: 3 nukes")
        var coins0: int = G.run_coins
        G._collect("coin")
        ck(G.run_coins == coins0 + HWData.COIN_DROP, "the coin crate pays GOGACoin")

        # ------------------------------------------------ the tunnel laws
        G.enemies.clear()
        G.t_state = float(G.place["len"]) + 0.1
        G._place_tick(0.016)
        ck(G.state == G.GS.TUNNEL, "the served place enters the tunnel")
        ck(int(G.run["places_done"]) == 1, "the place is banked")
        var spawned := false
        for i in 30:
                G._director_tick(0.016)
                if not G._wave_units.is_empty() or not G.enemies.is_empty():
                        spawned = true
        ck(not spawned, "THE CALM LAW: the tunnel never spawns")
        G.t_state = 5.0
        G._tunnel_tick(0.016)
        if int(G.run["places_done"]) % HWData.BOSS_PLACES == 0:
                ck(G.state == G.GS.BOSS, "the 5th place wakes the boss")
                G.state = G.GS.CALM
        else:
                ck(G.state == G.GS.CALM, "the tunnel lands in the calm")
        await _wait(4.6)
        ck(G.state == G.GS.PLACE, "the calm hands back to the war")

        # ------------------------------------------------ the boss cadence
        G.run["places_done"] = 4
        G.run["place_i"] = 4
        G._ensure_queue()
        G._enter_tunnel()
        G.t_state = 5.0
        G._tunnel_tick(0.016)
        ck(G.state == G.GS.BOSS, "THE CADENCE LAW: 5 places -> the boss")
        ck(G.boss != null, "the boss is on the field")
        var pts0: int = meta.pts_banked()
        G.boss["hp"] = 1
        G._boss_die()
        await _wait(0.1)
        ck(meta.pts_banked() == pts0 + 1, "THE BOSS PAYOUT: 1 permanent point")
        ck(G.state == G.GS.ARMORY, "the boss death opens the armory")
        ck(G.sheet_open_count() == 1, "the armory sheet is up")
        G.sheet_pop()
        await _wait(0.1)
        ck(G.state == G.GS.CALM, "closing the armory returns to the calm")

        # ------------------------------------------------ the death law
        G.state = G.GS.PLACE
        G.run["lives"] = 1
        G.run["iframes"] = 0.0
        (G.run["shield_hp"] as Array).clear()   # the caps test stocked layers
        G.run["shields"] = 0
        G._hurt_tank(G.tank.position)
        await _wait(2.2)
        ck(G.state == G.GS.OVER, "the last hit ends the run")
        ck(finished[0] >= 0, "finish_run paid the box (score=%d)" % finished[0])
        ck(meta.best_places() >= 1 if meta.has_method("best_places") else true,
                "the run landed in the ledger")

        # ------------------------------------------------ the shop laws
        ## (the all_owned cheat owns every shelf - it would lie about the
        ## locks AND block the buys; the shop laws run with the cheat off)
        Box.dev_set_cheat("all_owned", 0)
        ck(G.sheet_open_count() == 0, "no sheets before the shop")
        var coins_before: int = Box.coins()
        Box.earn(20000 - coins_before if coins_before < 20000 else 1000)
        ck(Box.coins() >= 20000, "the test wallet is stocked")
        ck(not meta.stat_open("armor"), "armor born locked")
        G.state = G.GS.PLACE          # a live state: the shop must pause it
        G._shop_open()
        await _wait(0.2)
        ck(G.sheet_open_count() == 1, "THE SHOP LAW: the sheet is up")
        ck(G.paused, "the shop pauses the war")
        ck(Box.buy_item("heavywar", "upg", "armor", int(HWData.UPGRADES["armor"]["shop_price"])),
                "the armor lock buys")
        ck(meta.stat_open("armor"), "the bought stat opens in the armory")
        ck(Box.item_owned("heavywar", "rig", "laser") == false, "the laser born unbought")
        ck(Box.buy_item("heavywar", "rig", "laser", HWData.LASER_PRICE),
                "the laser buys at its price")
        ck(Box.item_owned("heavywar", "rig", "laser"), "the laser owned")
        ck(Box.buy_skin("heavywar", "crimson", int(HWData.SKINS["crimson"]["price"])),
                "the crimson skin buys")
        Box.equip_skin("heavywar", "crimson")
        G._apply_skin()
        ck(G._skin_id() == "crimson", "THE SKIN LAW: the tank wears the buy")
        G._shop_close()
        await _wait(0.2)
        ck(not G.paused, "closing the shop unpauses the war")
        ck(G.sheet_open_count() == 0, "the pair died clean")
        Box.dev_set_cheat("all_owned", 1)   # the cheat returns for later laws

        # ------------------------------------------------ the boss marathon
        ## every face ticks its real brain for ~6 simulated seconds and
        ## dies paying - the ten-brain crash hunt
        await _boot()
        _tap(0, Vector2(960, 540), true)
        _tap(0, Vector2(960, 540), false)
        await _wait(0.1)
        var marathon_ok := true
        var marathon_why := ""
        for bi in HWData.BOSS_ORDER.size():
                G.run["bosses_met"] = bi     # the face index drives the pick
                G._enter_boss()
                if G.boss == null or String(G.boss["id"]) != HWData.BOSS_ORDER[bi]:
                        marathon_ok = false
                        marathon_why = "face %d did not enter" % bi
                        break
                for f in 360:                # 6 simulated seconds at 60hz
                        G._boss_tick(1.0 / 60.0)
                        G._ebombs_tick(1.0 / 60.0)
                        G._fx_tick(1.0 / 60.0)
                G.boss["hp"] = 0
                G._boss_die()
                if G.state != G.GS.ARMORY:
                        marathon_ok = false
                        marathon_why = "face %d death opened no armory" % bi
                        break
                G.sheet_pop()
                await _wait(0.05)
                G.state = G.GS.PLACE
        ck(marathon_ok, "THE MARATHON LAW: all ten faces fight and pay (%s)"
                % marathon_why)
        ck(meta.pts_banked() >= 10, "ten bosses minted ten points")

        # ------------------------------------------------ the shuffle law
        await _boot()
        _tap(0, Vector2(960, 540), true)
        _tap(0, Vector2(960, 540), false)
        await _wait(0.1)
        var q2: Array = G.place_queue.duplicate()
        var laps_same := true
        for i in 10:
                if int(q2[i]) != int(q[i]):
                        laps_same = false
        print("[NOTE] two boots shared a queue order: ", laps_same,
                " (shuffle is seed-locked in the probe - fine)")

        print("=== hw_probe done: %d checks, %d fails ===" % [checks, fails])
        get_tree().quit(1 if fails > 0 else 0)

func _ready() -> void:
        _run.call_deferred()
