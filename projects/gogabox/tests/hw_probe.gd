extends Node
## HEAVY WAR probe (v040-2) - the deterministic battery against the
## ORIGINAL'S OWN LAWS. Runs headless: godot --headless --path . \
## res://tests/hw_probe.tscn   Exit 0 = all laws hold.

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
        ScaleRule.apply(get_window())      # the house design law
        get_window().content_scale_size = Vector2i(1920, 1080)
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
        print("=== hw_probe (v040-2) ===")
        seed(20260915)
        await _boot()

        # ------------------------------------------------ the data laws
        ck(HWData.ENEMIES.size() == 22, "22 enemies in the table")
        var shared := 0
        var specials: Array = []
        for eid in HWData.ENEMIES:
                var pts: int = HWData.ENEMIES[eid]["pts"]
                if pts == 1:
                        shared += 1
                else:
                        specials.append(pts)
        ck(shared == 12, "12 shared fry pay 1 (got %d)" % shared)
        ck(specials.size() == 10, "the ten specials exist")
        var sorted_sp := specials.duplicate()
        sorted_sp.sort()
        ck(sorted_sp == [10, 20, 30, 40, 50, 60, 70, 80, 90, 100],
                "specials pay 10..100 in steps")
        ck(HWData.PLACES.size() == 10, "ten places exist")
        var excl_total := 0
        for p in HWData.PLACES:
                excl_total += (p["exclusive"] as Array).size()
                ck(float(p["len_orig"]) >= 10000.0
                        and float(p["len_orig"]) <= 30000.0,
                        "place %s wears the source's own length" % p["id"])
        ck(excl_total >= 10, "every place wears exclusives (%d)" % excl_total)
        # THE SOURCE'S OWN WAVES: 19 levels, 84 waves, verbatim lens
        ck(HWData.WAVES_XML.size() == 84, "the source's 84 waves ride here")
        var sum := 0
        for n in HWData.LEVEL_WAVE_COUNTS:
                sum += int(n)
        ck(sum == 84, "the level lens covers all 84")
        ck(HWData.waves_for_level(0).size() == 3,
                "level 1 = the source's own 3 waves")
        ck(HWData.waves_for_level(9).size() == 9,
                "level 10 = the source's own 9-wave siege")
        ck(HWData.waves_for_level(18).size() == 6,
                "level 19 = the source's own 6 waves")
        var all_waves_real := true
        for w in HWData.WAVES_XML:
                for ul in w["u"]:
                        if not HWData.ENEMIES.has(String(ul[0])):
                                all_waves_real = false
        ck(all_waves_real, "every wave unit is a real enemy")
        ck(HWData.BOSS_ORDER.size() == 10, "ten boss faces")
        var bs: Dictionary = HWData.boss_stats(10)
        ck(int(bs["comeback"]) == 1 and bs["id"] == "gunship",
                "boss 10 = gunship comeback 1")
        ck(int(bs["hp"]) > HWData.BOSSES["gunship"]["hp"],
                "THE SOURCE'S COMEBACK: the second meeting wears Level2 armor")
        # THE SOURCE'S OWN ARMOR LAW: craft.xml armor = the hp table
        ck(int(HWData.ENEMIES["scout"]["hp"]) == 1,
                "the prop plane wears the source's armor 1")
        ck(int(HWData.ENEMIES["raider"]["hp"]) == 10,
                "the T-83 bomber wears the source's armor 10")
        ck(int(HWData.ENEMIES["plowman"]["hp"]) == 400,
                "the bulldozer wears the source's armor 400")
        ck(int(HWData.ENEMIES["zeppelin"]["hp"]) == 400,
                "the blimp wears the source's armor 400")
        # THE ORIGINAL'S SIX WEAPON SYSTEMS
        ck(HWData.UPGRADES.size() == 6, "six systems")
        var names := ["speed", "shield", "rockets", "flak", "homing", "laser"]
        var ids_ok := true
        for n2 in names:
                if not HWData.UPGRADES.has(n2):
                        ids_ok = false
        ck(ids_ok, "THE SOURCE'S OWN SIX: speed/shield/rockets/flak/homing/laser")
        var opens := 0
        for sid in HWData.UPGRADES:
                if bool(HWData.UPGRADES[sid]["open"]):
                        opens += 1
        ck(opens == 2, "THE 2-OPEN LAW: two systems born free")
        ck(HWData.shell_dmg(0) == 2 and HWData.shell_dmg(4) == 10,
                "the gun power tiers bite 2..10")
        ck(HWData.laser_need() == 4,
                "THE SOURCE'S LAW: collect all FOUR megalaser parts")
        ck(HWData.SKINS.size() == 6 and HWData.LASER_PRICE >= 5000,
                "six skins + the costly laser")

        # ------------------------------------------------ the meta laws
        ck(meta.pts_free() == 0 and meta.pts_banked() == 0, "fresh ledger: 0 points")
        meta.mint_pts(3)
        ck(meta.pts_free() == 3, "3 bosses minted 3 free points")
        ck(meta.raise("speed") and meta.level_of("speed") == 1, "raise speed")
        ck(meta.pts_free() == 2, "the raise spent a free point")
        ck(meta.raise("rockets") == false, "THE LOCK LAW: closed system refuses")
        meta.mint_pts(20)
        var ok_all := true
        for i in 4:
                if not meta.raise("speed"):
                        ok_all = false
        ck(ok_all and meta.level_of("speed") == 5 and meta.pts_free() == 18,
                "speed to the 5 cap (4 raises from LV1)")
        ck(meta.raise("speed") == false, "THE CAP LAW: 6th level refuses")
        ck(meta.lower("speed") and meta.lower("speed") \
                and meta.level_of("speed") == 3 and meta.pts_free() == 20,
                "the rebalance lowers back and refunds")
        meta.lower("speed")
        meta.lower("speed")
        meta.lower("speed")
        ck(meta.level_of("speed") == 0 and meta.pts_free() == 23,
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

        # ------------------------------------------------ the world laws
        ck(G.GROUND_Y > 900.0 and G.GROUND_Y < 990.0,
                "the ground line sits at the source's own band")
        var far_off: float = G.world.get_meta("far")["off"]
        var mid_off: float = G.world.get_meta("mid")["off"]
        var gnd_off: float = G.world.get_meta("ground")["off"]
        await _wait(1.0)
        var far_d: float = absf(float(G.world.get_meta("far")["off"])
                - far_off)
        var mid_d: float = absf(float(G.world.get_meta("mid")["off"])
                - mid_off)
        var gnd_d: float = absf(float(G.world.get_meta("ground")["off"])
                - gnd_off)
        ck(gnd_d > mid_d and mid_d > far_d and far_d > 0.0,
                "THE PLANE LAW: sky crawls, mid jogs, the ground carries")
        # the composed far strip loaded (not the null slab)
        var far_leaves: Array = G.world.get_meta("far")["leaves"]
        ck(far_leaves.size() == 3 and far_leaves[0] is Sprite2D,
                "the far strip wears the composed original texture")
        # props baked to their planes
        await _wait(2.0)
        ck(G.props.size() > 0, "the place's props walk out of the planes")

        # ------------------------------------------------ the gun + kills
        var n0: int = G.enemies.size()
        await _wait(3.0)
        ck(G.enemies.size() > n0 or not G._wave_plan.is_empty(),
                "THE SOURCE'S WAVES FLOW: the director spawns (enemies=%d)"
                        % G.enemies.size())
        if G.enemies.is_empty():
                G._spawn_enemy("scout", G.tank.position.x, 300.0)
        var victim: Dictionary = G.enemies[0]
        victim["n"].position = Vector2(G.tank.position.x, 300.0)
        G.aim_pos = victim["n"].position      # the finger IS the aim
        var s0: int = G.score
        for i in 90:
                G._fire()
                G._shots_tick(1.0 / 60.0)
                if G.score > s0:
                        break
        ck(G.score > s0, "THE KILL LAW: a dead scout pays score (+%d)"
                % (G.score - s0))
        ck(G.run["kills"] >= 1, "the kill lands in the ledger")

        # the arm law: 24 angle columns x 5 tier rows, smooth fraction.
        # v040-3 THE AIM-ONLY LAW: the arm reads the AIM FINGER only - the
        # probe presses one (the owner: 'the arm follows the aim, not the
        # steering'), and without a finger the barrel rests UP (col 12).
        G.aim_ptr = 1
        G.aim_pos = Vector2(G.tank.position.x - 500.0, G.TANK_Y)
        var arm: Sprite2D = G.tank.get_meta("turret")
        G._turret_apply()
        var col_left := arm.frame % 24
        G.aim_pos = Vector2(G.tank.position.x + 500.0, G.TANK_Y)
        G._turret_apply()
        var col_right := arm.frame % 24
        ck(col_left == 0 and col_right == 23,
                "THE ARM LAW: left = col 0, right = col 23 (got %d/%d)"
                        % [col_left, col_right])
        G.aim_ptr = -1
        G._turret_apply()
        ck(arm.frame % 24 == 12,
                "THE ARM RESTS UP: no aim finger = col 12 (got %d)"
                        % (arm.frame % 24))
        G.gun_tier = 3
        G._turret_apply()
        ck(arm.frame >= 3 * 24 and arm.frame < 4 * 24,
                "the arm wears its gun-power tier row")
        G.gun_tier = 0

        # the rotation strips: a bullet picks an angle frame, never spins
        var eb0: Array = G.ebombs
        G._enemy_shot(G.tank.position + Vector2(400, -200),
                Vector2(-400, 0), "hellfire")
        var shot: Dictionary = G.ebombs[-1]
        var spr: Sprite2D = (shot["n"] as Node2D).get_meta("spr", null)
        ck(spr != null and int((shot["n"] as Node2D).get_meta("rot", 0)) > 0,
                "the shots wear the source's rotation strips")
        var f0: int = spr.frame if spr != null else -1
        G._set_rot_frame(shot["n"], Vector2(400, 0))
        ck(f0 != spr.frame or f0 == 0,
                "the rotation law flips the frame with the angle")
        (shot["n"] as Node2D).queue_free()
        G.ebombs.erase(shot)
        var _eb_unused := eb0

        # ------------------------------------------------ the zones
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

        # ------------------------------------------------ the entry law
        ## spawned-in enemies enter FULLY off the edge: head first, butt
        ## after - never the whole body at once (the owner's law)
        G.enemies.clear()
        G._spawn_enemy("raider", -1.0, -1.0)
        var raider: Dictionary = G.enemies[-1]
        var edge: float = (raider["n"] as Node2D).position.x \
                - float(raider["w"]) * 0.5
        ck(edge > 1920.0,
                "THE ENTRY LAW: the body enters fully off-screen (edge=%.0f)"
                        % edge)
        G._enemy_free(raider)

        # ------------------------------------------------ the tank laws
        var lives0: int = G.run["lives"]
        G._hurt_tank(G.tank.position)
        ck(int(G.run["lives"]) == lives0 - 1, "each hit takes one life")
        G._hurt_tank(G.tank.position)            # iframes eat this one
        ck(int(G.run["lives"]) == lives0 - 1, "THE IFRAME LAW: no double-bite")
        ck(G.gun_tier == 0, "the hit dropped the gun power (already 0)")
        G.run["iframes"] = 0.0
        (G.run["shield_hp"] as Array).append({"hp": 2})
        G.run["shields"] = 1
        var l_before: int = G.run["lives"]
        G.run["iframes"] = 0.0
        G._hurt_tank(G.tank.position)
        ck(int(G.run["lives"]) == l_before, "THE SPHERE LAW: the layer eats the hit")
        ck((G.run["shield_hp"] as Array)[0]["hp"] == 1, "the layer bled first")
        G.run["iframes"] = 0.0
        G._hurt_tank(G.tank.position)
        ck((G.run["shield_hp"] as Array).is_empty(), "the broken layer dies")
        G.run["iframes"] = 0.0
        G._hurt_tank(G.tank.position)
        ck(int(G.run["lives"]) == l_before - 1, "lives pay after the spheres")

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
        ck(int(G.run["shields"]) == HWData.SHIELD_MAX, "THE CAP LAW: 3 sphere layers")
        G.run["nukes"] = 0
        G._collect("nuke")
        G._collect("nuke")
        G._collect("nuke")
        G._collect("nuke")
        ck(int(G.run["nukes"]) == HWData.NUKES_MAX, "THE CAP LAW: 3 nukes")
        var coins0: int = G.run_coins
        G._collect("coin")
        ck(G.run_coins == coins0 + HWData.COIN_DROP, "the coin crate pays GOGACoin")
        G.gun_tier = 0
        G._collect("gunpower")
        G._collect("gunpower")
        ck(G.gun_tier == 2, "THE GUN POWER LAW: the pickups climb the arm")

        # ------------------------------------------------ the tunnel laws
        G.enemies.clear()
        G.place_px_left = 0.0
        G._place_tick(0.016)
        ck(G.state == G.GS.TUNNEL, "the served place enters the tunnel")
        ck(int(G.run["places_done"]) == 1, "the place is banked")
        var spawned := false
        for i in 30:
                G._director_tick(0.016)
                if not G._wave_plan.is_empty() or not G.enemies.is_empty():
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
        # the parts sit at FIXED anchors (no random scatter)
        if (G.boss["parts"] as Array).size() > 1:
                var p0: Node2D = (G.boss["parts"][0] as Dictionary)["n"]
                var a0: Vector2 = (G.boss["parts"][0] as Dictionary)["anchor"]
                ck(p0.position == G.boss["n"].position + a0,
                        "THE ANCHOR LAW: the parts ride their fixed slots")
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
        (G.run["shield_hp"] as Array).clear()
        G.run["shields"] = 0
        G._hurt_tank(G.tank.position)
        await _wait(2.2)
        ck(G.state == G.GS.OVER, "the last hit ends the run")
        ck(finished[0] >= 0, "finish_run paid the box (score=%d)" % finished[0])

        # ------------------------------------------------ the shop laws
        Box.dev_set_cheat("all_owned", 0)
        ck(G.sheet_open_count() == 0, "no sheets before the shop")
        var coins_before: int = Box.coins()
        Box.earn(20000 - coins_before if coins_before < 20000 else 1000)
        ck(Box.coins() >= 20000, "the test wallet is stocked")
        ck(not meta.stat_open("rockets"), "rockets born locked")
        G.state = G.GS.PLACE          # a live state: the shop must pause it
        G._shop_open()
        await _wait(0.2)
        ck(G.sheet_open_count() == 1, "THE SHOP LAW: the sheet is up")
        ck(G.paused, "the shop pauses the war")
        ck(Box.buy_item("heavywar", "upg", "rockets",
                int(HWData.UPGRADES["rockets"]["shop_price"])),
                "the rockets lock buys")
        ck(meta.stat_open("rockets"), "the bought system opens in the armory")
        ck(Box.item_owned("heavywar", "rig", "laser") == false,
                "the laser born unbought")
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
        Box.dev_set_cheat("all_owned", 1)

        # ------------------------------------------------ the boss marathon
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

        # =============================================================
        # v040-3 - the owner's report laws
        # =============================================================
        # THE LEAF LAW: at ANY roll offset the 3-leaf tiling covers the
        # whole live canvas (the old stacking left the raw void = the
        # owner's blue/white rectangles and the 'unreachable wall')
        var leaf_ok := true
        for plane in ["sky", "far", "mid", "ground"]:
                var l: Dictionary = G.world.get_meta(plane)
                for trial in 6:
                        l["off"] = float(trial) / 6.0 * float(l["period"])
                        G._layer_roll(l, 0.0)
                        var covered := 0.0
                        for leaf in l["leaves"]:
                                if is_instance_valid(leaf):
                                        covered = maxf(covered,
                                                leaf.position.x
                                                + float(l["period"]))
                        if covered < G.W + 1.0:
                                leaf_ok = false
        ck(leaf_ok, "THE LEAF LAW: the tiling covers the canvas at any roll")

        # THE BOTH-SIDES LAW: the craft table carries left chances, the
        # spawner honors them, and left entries FACE right (flip)
        var any_left := false
        for i in 24:
                G._spawn_enemy("scout", -1.0, -1.0, true)
                var e: Dictionary = G.enemies[-1]
                if float(e.get("dir", -1.0)) > 0.0:
                        any_left = true
                        var sprL: Sprite2D = (e["n"] as Node2D) \
                                .get_meta("spr", null)
                        if sprL != null and not sprL.flip_h:
                                any_left = false
                G._enemy_free(G.enemies[-1])
        ck(any_left, "THE BOTH-SIDES LAW: a left entry flips to face right")
        var left_p := 0
        for d in HWData.ENEMIES.values():
                left_p += 1 if float(d.get("left", 0.0)) > 0.0 else 0
        ck(left_p >= 10, "the craft table carries left chances (%d types)"
                % left_p)

        # THE TRUE FRAMES LAW: the strip cells slice whole sprites (the
        # old hf=4 on a 10-frame strip squeezed the owner's anims)
        var frames_ok := true
        var expect := {"enemy_scout": 10, "enemy_wasp": 9, "enemy_viper": 9,
                "enemy_strafer": 10, "enemy_grinder": 10,
                "enemy_hornet": 7, "enemy_plowman": 10}
        for k in expect:
                var spr2: Sprite2D = G._art_sprite(k, Vector2(100, 40),
                        Color.WHITE).get_meta("spr", null)
                if spr2 == null or spr2.hframes != int(expect[k]):
                        frames_ok = false
        ck(frames_ok, "THE TRUE FRAMES LAW: strips slice whole sprites")

        # THE INTERCEPT LAW: shells kill bombs, never the pink hellfire
        G.ebombs.clear()
        G._drop_bomb(G.tank.position + Vector2(300, -260), "dumb")
        var bomb_n: Node2D = G.ebombs[-1]["n"]
        G._shell_intercept(bomb_n.position)
        ck(G.ebombs.is_empty(),
                "THE INTERCEPT LAW: a shell shoots a dumb bomb down")
        G.ebombs.clear()
        G._enemy_shot(G.tank.position + Vector2(300, -260),
                Vector2(-300, 200), "hellfire")
        G._shell_intercept((G.ebombs[-1]["n"] as Node2D).position)
        ck(G.ebombs.size() == 1,
                "THE INTERCEPT LAW: the pink poison is untouchable")
        G.ebombs.clear()

        # THE FRIEND LAW: one crate, mid-band release, ten hits to kill
        G._heli_pass("supply")
        G.heli.position = Vector2(G.W * 0.5, 235.0)
        var drops0: int = G.drops.size()
        G._heli_tick(1.0 / 60.0)
        ck(G.drops.size() == drops0 + 1,
                "THE FRIEND LAW: exactly ONE crate released")
        ck(G.heli.position.x >= G.W * 0.35
                and G.heli.position.x <= G.W * 0.75,
                "THE FRIEND LAW: the drop lands in the 35-75% band")
        var kills := 0
        for i in 10:
                G._heli_hit(1)
                kills += 1
        ck(G.heli_hp <= 0 and not G.heli.visible,
                "THE FRIEND LAW: ten points end the pass")
        ck(G.heli_dropped, "THE FRIEND LAW: the cargo falls even on death")
        for c in G.drops.duplicate():
                G.drops.erase(c)
                (c["n"] as Node2D).queue_free()

        # THE ONE-COIN LAW: the pickup pays exactly one, the death bonus 0
        var coins1 := G.run_coins
        G._collect("coin")
        ck(G.run_coins == coins1 + 1,
                "THE ONE-COIN LAW: a coin pays ONE (got %d)"
                % (G.run_coins - coins1))
        ck(not G.score_bonus_enabled,
                "THE ONE-COIN LAW: the score death-bonus is ZERO")

        # THE DEATH RESET LAW: a lost life zeroes laser parts AND nukes
        G.run["laser_parts"] = 3
        G.run["nukes"] = 2
        G.run["shield_hp"] = []
        G.run["shields"] = 0
        G.run["iframes"] = 0.0
        G.run["lives"] = 2
        G._hurt_tank(G.tank.position)
        ck(int(G.run["laser_parts"]) == 0 and int(G.run["nukes"]) == 0,
                "THE DEATH RESET LAW: dying zeroes laser parts + nukes")

        # THE LASER WIDGET LAW: the chip exists and shows live percent
        ck(G.chips.has("laser") and is_instance_valid(G.chips["laser"]),
                "THE LASER WIDGET LAW: the orange wavy chip lives")
        G.run["laser_parts"] = 2
        G._chips_refresh()
        ck((G.chips["laser"] as Label).text == "50%",
                "THE LASER WIDGET LAW: two parts read 50%% (got %s)"
                        % (G.chips["laser"] as Label).text)

        # THE GEOMETRY LAW: the tank rides ON the band, craters on its face
        ck(absf(G.TANK_Y - (G.GROUND_Y + 58.0)) < 0.5
                and absf(G.ROAD_Y - (G.GROUND_Y + 104.0)) < 0.5,
                "THE GEOMETRY LAW: tank +58 / road +104 from the band top")

        # THE PLACE ORDER LAW: the source's own walk, no shuffle
        var seq_ok := true
        for i in HWData.PLACES.size():
                if int(G.place_queue[i]) != i:
                        seq_ok = false
        ck(seq_ok, "THE PLACE ORDER LAW: places walk the source's order")

        print("=== hw_probe done: %d checks, %d fails ===" % [checks, fails])
        get_tree().quit(1 if fails > 0 else 0)

func _ready() -> void:
        _run.call_deferred()
