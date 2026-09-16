extends Node
## HEAVY WAR v040-6 probe - the deterministic battery for THE OWNER'S REPORT.
## godot --headless --path . res://tests/hw5_probe.tscn   Exit 0 = all laws.
## v040-6: the shop split, the no-cheat shelf (8 items, real prices), the
## 500-kill coin law, the raider, the shield progression, the boss
## entrance fix (the Dust Reaver arrives), the tank layout law.

var checks := 0
var fails := 0
var G: GogaGame = null
var meta: HWMeta = null
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
        get_window().content_scale_size = Vector2i(1920, 1080)
        await _wait(0.2)
        finished = [-1, -1]
        G = load("res://game/games/heavywar/heavywar.gd").new()
        G.game_id = "heavywar"
        G.request_finish.connect(func(s, c): finished = [s, c])
        add_child(G)
        await _wait(0.8)
        meta = G.meta

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
        print("=== hw5_probe (v040-6: THE SHOP SPLIT + THE WAR GROWS) ===")
        seed(20260916)
        await _boot()

        # --------------------------------------------- the data laws
        ck(HWData.PLACES.size() == 10, "10 places")
        var exs: Array = []
        for p in HWData.PLACES:
                exs.append(String(p["ex"]))
                ck(HWData.ENEMIES.has(String(p["ex"])),
                        "place %s exclusive %s exists" % [p["key"], p["ex"]])
        ck(HWData.BOSSES.size() == 10, "10 bosses")
        var brains: Array = []
        for b in HWData.BOSSES:
                brains.append(String(b["brain"]))
        ck(brains.has("prime"), "THE NULL AVATAR rides the prime brain")
        ck(HWData.CARDS.size() >= 14, "a real card pool (%d)" % HWData.CARDS.size())
        var cheat := false
        var banned := ["magnet", "coin", "scrap", "xp", "vacuum"]
        for c in HWData.CARDS:
                if String(c["id"]) in banned:
                        cheat = true
        ck(not cheat, "THE NO-CHEAT LAW: the economy cards are gone")
        ck(HWData.SKINS.size() == 5, "5 skins")

        # THE WAR MACHINES (the owner's reports, v040-5 + v040-6)
        for nid in ["carpet", "shredder", "laserd", "raider"]:
                ck(HWData.ENEMIES.has(nid), "the war machine %s exists" % nid)
        ck(String(HWData.ENEMIES["carpet"]["weapon"]) == "bigbomb",
                "the carpet bomber drops the BIG bomb")
        ck(String(HWData.ENEMIES["shredder"]["weapon"]) == "cluster",
                "the shred bomber drops the CLUSTER bomb")
        ck(String(HWData.ENEMIES["laserd"]["weapon"]) == "laser",
                "the shadow lancer burns the LASER")
        ck(String(HWData.ENEMIES["raider"]["weapon"]) == "rocketdrop",
                "THE RAIDER drops rockets as it moves")
        ck(String(HWData.ENEMIES["raider"]["move"]) == "rush",
                "THE RAIDER rushes - it can not be caught")
        ck(float(HWData.ENEMIES["raider"]["speed"]) >= 260.0,
                "THE RAIDER is fast (%d)" % int(HWData.ENEMIES["raider"]["speed"]))
        ck(String(HWData.ENEMIES["laserd"]["move"]) == "shadow",
                "the shadow lancer haunts above the tank")
        ck(int(HWData.ENEMIES["gtank"].get("shreds", 0)) > 0,
                "heavy enemies burst into death shreds")
        ck(HWData.ENEMIES.has("mini") == false,
                "NO MINI TANKS in the data")
        # THE SUICIDAL LAW: the kamikaze rides EVERY place from the start
        ck(HWData.pool_for(0).has("kamikaze"),
                "the SUICIDAL kamikaze exists from place 1")
        ck(HWData.pool_for(4).has("raider"), "the raider joins by place 5")

        # ------------------------------------------ the SCRAP SHOP laws
        # v040-6: 8 honest items, the cheats GONE, the REAL prices
        ck(HWData.SHOP_ITEMS.size() == 8, "8 shop items (the cheats are dead)")
        var ids := []
        for it in HWData.SHOP_ITEMS:
                ids.append(String(it["id"]))
        for dead_id in ["scrapGain", "xpGain", "magnet"]:
                ck(not ids.has(dead_id), "the %s upgrade is GONE" % dead_id)
        var expect := {"wheels": 200, "armor": 240, "cannon": 280, "reload": 260,
                "rockets": 800, "rocket_rack": 400, "mg": 900, "mg_rack": 450}
        for it in HWData.SHOP_ITEMS:
                var id := String(it["id"])
                ck(expect.has(id) and int(it["base"]) == expect[id],
                        "%s costs %d (the real price)" % [id, expect.get(id, -1)])
        # the full shelf costs a war chest - nobody maxes it in 3 runs
        var total := 0
        for it in HWData.SHOP_ITEMS:
                var lvls := int(it.get("max", 1))
                for l in lvls:
                        total += HWData.shop_cost(it, l)
        ck(total > 30000,
                "the full shelf costs %d scrap (the 3-run cheat is dead)" % total)
        # cost ramp: floor(base * step^lvl)
        var it2 := HWData.shop_item("wheels")
        ck(HWData.shop_cost(it2, 0) == 200, "wheels lvl0 = 200")
        ck(HWData.shop_cost(it2, 1) == int(200.0 * 1.6), "wheels lvl1 ramps x1.6")
        # the edge cases through the meta bank
        ck(meta.scrap() == 0 and meta.total_scrap() == 0, "a fresh bank")
        meta.bank_scrap(10)
        ck(meta.scrap() == 10 and meta.total_scrap() == 10, "bank +10")
        meta.bank_scrap(5)
        ck(meta.scrap() == 15 and meta.total_scrap() == 15, "bank +5 = 15")
        ck(meta.spend_scrap(10), "spend 10 ok")
        ck(not meta.spend_scrap(100), "no funds REFUSES the buy")
        ck(meta.scrap() == 5, "the wallet keeps the truth")
        meta.set_upg("wheels", 5)
        ck(meta.upg_lvl("wheels") == 5, "wheels to MAX")
        meta.set_upg("mg", 1)
        ck(meta.upg_lvl("mg") == 1, "MG BARRELS unlocked")

        # --------------------------------------- the weapon lock laws
        ck(G._mg_lvl() == 1, "MG BARRELS bought = 1 machine gun PER SIDE")
        ck(G._rk_lvl() == 0, "ROCKET PODS locked from birth")
        ck(G._shop_spent() == 6, "shop power counts every bought level")
        # THE TANK LAYOUT LAW: the wide ground + the wide bottom + the small top
        var wxs: Array = G._wheel_xs()
        ck(wxs.size() == 8, "3 wheels + 5 bought = 8 VISIBLE wheels")
        var wheel_fit := true
        for wx in wxs:
                if absf(float(wx)) > 172.0:
                        wheel_fit = false
        ck(wheel_fit, "the WIDE GROUND LAYER fits every wheel (span <= 344)")
        var mgxs: Array = G._mg_xs()
        ck(mgxs.size() == 2, "1 MG barrel per side")
        var mg_fit := true
        for mx in mgxs:
                if absf(float(mx)) > 122.0:
                        mg_fit = false
        ck(mg_fit, "the MGs ride the SMALL upper layer (|x| <= 122)")
        ck(G._pod_xs().is_empty(), "no rocket pods until bought")
        meta.set_upg("rockets", 1)
        meta.set_upg("rocket_rack", 1)
        ck(G._rk_lvl() == 2, "pods + rack = 2 rockets per side")
        ck(G._pod_xs().size() == 4, "4 pod cells sunk in the BOTTOM layer")
        var pod_fit := true
        for px in G._pod_xs():
                if absf(float(px)) > 190.0:
                        pod_fit = false
        ck(pod_fit, "the pods live IN the bottom slab (|x| <= 190)")

        # --------------------------------------------- the run flow laws
        ck(G.state == G.GS.INTRO, "the game boots to the INTRO")
        _tap(0, Vector2(G.W / 2, G.H / 2), true)
        _tap(0, Vector2(G.W / 2, G.H / 2), false)
        await _wait(0.2)
        ck(G.state == G.GS.MENU, "TAP ANYWHERE opens the MENU")
        ck(G.has_method("_box_shop_open"), "the normal GOGABox SHOP exists")
        G._menu_tap(Vector2(G.W / 2, G.H * 0.42 + 20.0))
        await _wait(0.3)
        ck(G.state == G.GS.PLACE, "DEPLOY starts the war")
        await _wait(1.2)
        ck(G.wave == 1 and G.wave_state != "idle", "wave 1 pours")

        # the kill economy FIRST (a lone scout, no stray fire around):
        # 1 orb = 1 point, 1 piece = 1 scrap
        var lone := {
                "kind": "scout", "hp": 10.0, "maxhp": 10.0, "size": 40.0,
                "speed": 0.0, "dir": -1, "x": 500.0, "y": 300.0, "base_y": 300.0,
                "t": 0.0, "phase": 0.0, "hit": 0.0, "shield": 0.0,
                "move": "straight", "weapon": "none", "shoot_t": 999.0,
                "ground": false, "chill": 0.0, "hover_x": 500.0,
                "diving": false, "laser_t": 0.0, "laser_on": false,
        }
        G.enemies.clear()
        G.enemies.append(lone)
        G.drops.clear()
        var sc_before: int = G.score
        G.kill_enemy(lone, true)
        ck(G.score == sc_before + 1, "SCORE = KILLS: one kill, one point")
        var orbs := 0
        var scraps := 0
        var values_ok := true
        for p in G.drops:
                var pd: Dictionary = p
                if String(pd["kind"]) == "xp":
                        orbs += 1
                        if int(pd["value"]) != 1:
                                values_ok = false
                elif String(pd["kind"]) == "scrap":
                        scraps += 1
                        if int(pd["value"]) != 1:
                                values_ok = false
        ck(values_ok, "EVERY orb and piece carries value 1 (the owner's law)")
        ck(orbs == 2, "a scout drops 2 orbs")
        ck(scraps == 1, "a scout drops 1 scrap piece (the tuned income)")

        # THE COIN LAW (v040-6): the 500th kill carries a REAL coin
        ck(HWData.COIN_KILLS == 500, "the coin law is 500 KILLS (not 22, no timer)")
        G.coin_kills = 499
        G.drops.clear()
        var coin_e := {
                "kind": "scout", "hp": 10.0, "maxhp": 10.0, "size": 40.0,
                "speed": 0.0, "dir": -1, "x": 700.0, "y": 300.0, "base_y": 300.0,
                "t": 0.0, "phase": 0.0, "hit": 0.0, "shield": 0.0,
                "move": "straight", "weapon": "none", "shoot_t": 999.0,
                "ground": false, "chill": 0.0, "hover_x": 700.0,
                "diving": false, "laser_t": 0.0, "laser_on": false,
        }
        G.enemies.append(coin_e)
        G.kill_enemy(coin_e, true)
        var got_coin := false
        for p in G.drops:
                if String((p as Dictionary)["kind"]) == "coin":
                        got_coin = true
        ck(got_coin, "the 500th kill drops a GOGACoin")
        ck(G.coin_kills == 0, "the kill counter resets after the coin")

        # THE SHIELD LAW: past place 3, ordinary enemies arrive shielded
        G.place_i = 4
        seed(77)
        var shielded_n := 0
        for i in 40:
                G.enemies.clear()
                G._spawn_enemy("scout")
                if float((G.enemies[0] as Dictionary)["shield"]) > 0.0:
                        shielded_n += 1
        ck(shielded_n > 0, "the shield progression arms (%d/40 shielded)" % shielded_n)
        G.place_i = 0
        G.enemies.clear()

        # THE AIM CURSOR law: a right-half touch shows the aim
        _tap(1, Vector2(G.W * 0.75, G.H * 0.4), true)
        await _wait(0.15)
        ck(G.aim_ptr == 1, "the right-half finger is the aim finger")
        _tap(1, Vector2(G.W * 0.75, G.H * 0.4), false)
        await _wait(0.1)

        # MG fire law: barrels shoot UP ONLY (cd pinned high so the game's
        # own auto-fire can not race the probe's volley)
        G.shots.clear()
        G.cd_mg = 99.0
        G._fire_mg()
        var up_only := true
        var mg_count := 0
        for s in G.shots:
                var d: Dictionary = s
                if String(d["kind"]) == "mg":
                        mg_count += 1
                        if float(d["vy"]) > -1200.0 or absf(float(d["vx"])) > 260.0:
                                up_only = false
        ck(mg_count == 2, "the volley fires one bullet per barrel (got %d)" % mg_count)
        ck(up_only, "THE MG LAW: the barrels point UP ONLY")

        # the cannon follows the aim
        G.p_aim = -PI / 4.0
        var nb: int = G.shots.size()
        G.cd_main = 0.0
        G._fire_main()
        ck(G.shots.size() > nb, "the main cannon fires")
        var s0: Dictionary = G.shots[G.shots.size() - 1]
        var va := Vector2(float(s0["vx"]), float(s0["vy"])).angle()
        ck(absf(angle_difference(va, -PI / 4.0)) < 0.05,
                "THE AIM LAW: the cannon fires where the aim points")

        # THE ROCKET LAW: one rocket per cell, EVERY rocket its own target
        for i in 4:
                var e := {
                        "kind": "scout", "hp": 900.0, "maxhp": 900.0, "size": 40.0,
                        "speed": 0.0, "dir": -1, "x": 300.0 + i * 260.0,
                        "y": 200.0 + float(i) * 40.0, "base_y": 220.0,
                        "t": 0.0, "phase": 0.0, "hit": 0.0, "shield": 0.0,
                        "move": "straight", "weapon": "none", "shoot_t": 99.0,
                        "ground": false, "chill": 0.0, "hover_x": 900.0,
                        "diving": false, "laser_t": 0.0, "laser_on": false,
                }
                G.enemies.append(e)
        G.rockets.clear()
        G._fire_rockets()
        await _wait(0.05)
        ck(G.rockets.size() == 4, "4 pods -> 4 rockets")
        var tgts: Array = []
        for r in G.rockets:
                var rd: Dictionary = r
                if not (rd["target"] as Dictionary).is_empty():
                        tgts.append(rd["target"])
        var distinct := {}
        for t2 in tgts:
                distinct[t2] = true
        ck(distinct.size() == mini(4, tgts.size()),
                "THE ROCKET LAW: %d rockets pick %d DISTINCT targets" % [tgts.size(), distinct.size()])

        # THE BOSS ENTRANCE LAW: the Dust Reaver (sidewinder) ARRIVES - the
        # v040-5 bug slid it off the right edge forever and the fight
        # never started
        G.enemies.clear()
        G.eshots.clear()
        G.wave_state = "boss"
        G.boss_ent = {}
        G.place_i = 1
        G._spawn_boss()
        var bw: Dictionary = G.boss_ent
        ck(String(bw["brain"]) == "sidewinder", "boss 2 is the sidewinder")
        ck(float(bw["x"]) < 0.0, "the sidewinder enters from the opposite side")
        for i in 300:
                G._update_boss(bw, 1.0 / 60.0)
        ck(bool(bw["arrived"]),
                "THE DUST REAVER FIX: the sidewinder ARRIVES and fights")
        # the boss shield phases: drop it past 66% -> shields up
        G.enemies.clear()
        G.enemies.append(bw)
        bw["hp"] = float(bw["maxhp"]) * 0.6
        G._update_boss(bw, 1.0 / 60.0)
        ck(float(bw["shield"]) > 0.0, "THE SHIELD PHASE: 66% slams shields up")
        ck(G.enemies.size() >= 2, "the shield phase summons the escort wing")
        G.enemies.clear()
        G.boss_ent = {}
        G.place_i = 0

        # the cards: a tap SELECTS, the back button NEVER closes
        G.level_up_queue = 1
        G._open_cards()
        await _wait(0.3)
        ck(G.paused, "the level-up sheet pauses the war")
        var sheet_open: bool = G._sheet_stack.size() > 0
        ck(sheet_open and String(G._sheet_stack[-1]["id"]) == "cards",
                "the cards sheet is up")
        var sheet_root: Control = (G._sheet_stack[-1]["cc"] as Control)
        G._back_pressed()
        await _wait(0.2)
        ck(G._sheet_stack.size() > 0 and String(G._sheet_stack[-1]["id"]) == "cards",
                "THE BACK LAW: back NEVER closes the cards")
        # pick card 0 through the tappable path
        var btn: Button = _find_card_button(sheet_root)
        ck(btn != null, "the cards carry real buttons")
        if btn != null:
                btn.pressed.emit()
                await _wait(0.3)
                ck(not G.paused, "tapping a card SELECTS it and unpauses")
                ck(G.level_up_queue == 0, "the queue drains")

        # death banks the scrap (carried + the ground)
        G.p_scrap = 7
        G.drops = [{"kind": "scrap", "value": 3, "x": 0.0, "y": 0.0, "vx": 0.0,
                "vy": 0.0, "t": 0.0, "life": 5.0, "grounded": true}]
        G._game_over()
        await _wait(2.0)
        ck(G.state == G.GS.OVER, "hull 0 ends the run")
        ck(meta.scrap() == 15, "THE BANK: 5 + 7 carried + 3 ground = 15")
        ck(finished[0] >= 0, "the run reports to the host")

        print("=== %d checks, %d fails ===" % [checks, fails])
        print("PROBE_VERDICT ok=", fails == 0)
        print("PROBE_DONE")
        get_tree().quit(0 if fails == 0 else 1)

func _find_card_button(root: Control) -> Button:
        var stack := [root]
        while not stack.is_empty():
                var n: Node = stack.pop_back()
                if n is Button and (n as Button).text == "":
                        var b := n as Button
                        if b.custom_minimum_size == Vector2(300, 320):
                                return b
                for c in n.get_children():
                        stack.append(c)
        return null

func _process(_delta: float) -> void:
        pass

func _ready() -> void:
        _run()
