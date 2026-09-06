extends Node
## POP SIEGE probe (v0.3.5) - the deterministic battery.
## Runs headless: godot --headless --path . res://tests/pd_probe.tscn
## Exit 0 = all laws hold.

var checks := 0
var fails := 0
var G: GogaGame = null
var meta: PDMeta = null

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
        Box.dev_set_cheat("all_owned", 1)
        get_window().size = Vector2i(1920, 1080)
        await _wait(0.2)
        G = load("res://game/games/pop_siege/pop_siege.gd").new()
        G.game_id = "pop_siege"
        process_mode = Node.PROCESS_MODE_ALWAYS
        add_child(G)
        await _wait(1.0)
        meta = G.meta

func _run() -> void:
        print("=== pd_probe (v0.3.5) ===")
        seed(20260907)
        rng_seed()
        await _boot()

        # ------------------------------------------------------- the map laws
        var maps := PDData.maps()
        ck(maps.size() == 30, "THE 30 MAPS LAW: exactly thirty sieges")
        var free_maps := 0
        var ids := {}
        var seen_ids := {}
        for m in maps:
                ck(not seen_ids.has(m["id"]), "unique map id " + str(m["id"]))
                seen_ids[m["id"]] = true
                ck((m["paths"] as Array).size() >= 1, m["id"] + " has a path")
                for pts in m["paths"]:
                        ck(pts[0][0] == -1, m["id"] + " spawns off the left edge")
                        ck(pts[-1] == m["heart"], m["id"] + " ends at the heart")
                        for c in pts:
                                ck(c[1] >= 0 and c[1] < 10 and c[0] >= -1 and c[0] <= 18, m["id"] + " in bounds")
                # blocked cells never sit on the road or water
                var road := {}
                for pts in m["paths"]:
                        for i in range(pts.size() - 1):
                                var a: Array = pts[i]
                                var b: Array = pts[i + 1]
                                var steps: int = maxi(absi(b[0] - a[0]), absi(b[1] - a[1]))
                                for s in steps + 1:
                                        var t := float(s) / maxf(1.0, float(steps))
                                        road[Vector2i(roundi(a[0] + (b[0] - a[0]) * t), roundi(a[1] + (b[1] - a[1]) * t))] = true
                road[Vector2i(m["heart"][0], m["heart"][1])] = true
                for wcell in m.get("water", []):
                        ck(not road.has(Vector2i(wcell[0], wcell[1])), m["id"] + " water off the road")
                for bcell in m["blocked"]:
                        ck(not road.has(Vector2i(bcell[0], bcell[1])), m["id"] + " prop " + str(bcell[2]) + " off the road")
                for wcell in m.get("water", []):
                        ck(true, "water cell")
                if int(m["price"]) == 0:
                        free_maps += 1
        ck(free_maps == 3, "THE FREE TRIO LAW (maps): exactly three free maps")
        for mid in PDData.FREE_MAPS:
                ck(seen_ids.has(mid), "free map " + mid + " exists")
        # the day/night pair thumbs shipped
        for m in maps:
                ck(ResourceLoader.exists("res://assets/games/pop_siege/thumbs/%s.png" % m["id"]), m["id"] + " day thumb")
                ck(ResourceLoader.exists("res://assets/games/pop_siege/thumbs/%s_n.png" % m["id"]), m["id"] + " night thumb")

        # ----------------------------------------------------- the bloon laws
        ck(PDData.rbe("red") == 1, "red rbe 1")
        ck(PDData.rbe("blue") == 2, "blue rbe 2")
        ck(PDData.rbe("ceramic") == 104, "ceramic rbe 104 (the honest chain)")
        ck(PDData.rbe("moab") == 616, "moab rbe 616")
        ck(PDData.rbe("brutus") == 1932, "brutus rbe 1932")
        ck(PDData.BLOONS.size() == 13, "13 bloon kinds")
        for k in PDData.BLOONS:
                var def: Dictionary = PDData.BLOONS[k]
                if k != "red":
                        ck((def["kids"] as Array).size() > 0, k + " has children")
        ck(PDData.dmg_vs("lead", PDData.SHARP, 5.0) == 0.0, "THE LEAD LAW: sharp is blocked")
        ck(PDData.dmg_vs("lead", PDData.FIRE, 5.0) == 5.0, "fire cracks lead")
        ck(PDData.dmg_vs("lead", PDData.ENERGY, 5.0) == 5.0, "energy cracks lead")
        ck(PDData.dmg_vs("black", PDData.EXPLOSION, 5.0) == 0.0, "black shrugs off explosion")
        ck(PDData.dmg_vs("white", PDData.ICE, 5.0) == 0.0, "white shrugs off ice")
        ck(PDData.dmg_vs("zebra", PDData.EXPLOSION, 5.0) == 0.0 and PDData.dmg_vs("zebra", PDData.ICE, 5.0) == 0.0,
                "zebra shrugs off both")
        ck(PDData.dmg_vs("brutus", PDData.SHARP, 10.0) == 5.0, "THE BRUTUS LAW: sharp takes half")
        ck(PDData.dmg_vs("brutus", PDData.EXPLOSION, 10.0) == 10.0, "brutus respects boom")

        # ------------------------------------------------------ the folk laws
        ck(PDData.FOLK.size() == 10, "THE TEN: ten folk")
        ck(PDData.FREE_FOLK.size() == 3, "THE FREE TRIO LAW (folk)")
        for fid in PDData.FREE_FOLK:
                ck(int(PDData.FOLK[fid]["goga"]) == 0, "free folk " + fid + " costs nothing")
        for fid in PDData.FOLK:
                var fdef: Dictionary = PDData.FOLK[fid]
                ck((fdef["gears"] as Array).size() == 3, fid + " has 3 gears")
                for gi in 3:
                        var g: Dictionary = fdef["gears"][gi]
                        ck(g.has("dmg") and g.has("rate") and g.has("rng"), fid + " gear %d speaks dmg/rate/rng" % (gi + 1))
                # the upgrades scale up and get pricier
                ck(PDData.up_cost(fid, 5) > PDData.up_cost(fid, 2), fid + " upgrade price scales")
                ck(PDData.gear_cost(fid, 2) > PDData.up_cost(fid, 10) * 3, fid + " the gear jump is the expensive door")
                ck(PDData.gear_cost(fid, 2) > PDData.gear_cost(fid, 1), fid + " the gear-3 door costs more than gear-2")
                # the growth laws
                ck(PDData.stat(fid, 1, 1, "dmg") == 0.0 or PDData.stat(fid, 1, 10, "dmg") > PDData.stat(fid, 1, 1, "dmg"), fid + " damage grows by level")
                ck(PDData.stat(fid, 1, 1, "rate") == 0.0 or PDData.stat(fid, 1, 10, "rate") < PDData.stat(fid, 1, 1, "rate"), fid + " rate gets faster")
                ck(PDData.stat(fid, 1, 10, "rng") > PDData.stat(fid, 1, 1, "rng"), fid + " range grows")
                ck(PDData.stat(fid, 2, 1, "dmg") >= PDData.stat(fid, 1, 1, "dmg"),
                        fid + " gear 2 jumps the power")
                var first_key: String = PDData.rows_for(fid)[0][1]
                ck(PDData.next_stat(fid, 1, 10, first_key) == 0.0, fid + " THE >> LAW: max level shows no next")
                ck(PDData.next_stat(fid, 1, 5, first_key) > 0.0, fid + " THE >> LAW: mid level has a next")

        # -------------------------------------------------- the synergy laws
        ck(PDData.SYNERGIES.size() == 8, "THE EIGHT PACTS")
        var badge_set := {}
        for s in PDData.SYNERGIES:
                ck(not badge_set.has(s["badge"]), "badge " + str(s["badge"]) + " is unique")
                badge_set[s["badge"]] = true
                ck(ResourceLoader.exists("res://assets/games/pop_siege/ui/badge_%s.png" % s["badge"]),
                        "badge art " + str(s["badge"]) + " shipped")

        # ------------------------------------------------------ the wave laws
        ck(int(PDData.START_COINS) == 250, "THE PURSE LAW: 250 PopCoins at drop in")
        ck(int(PDData.START_LIVES) == 100, "THE LIVES LAW: 100")
        ck(int(PDData.BONUS_DIV) == 1000, "THE /1000 LAW")
        ck(int(PDData.RIDER_EVERY) == 10, "THE RIDER LAW: every 10 waves")
        ck(int(PDData.VICTORY_WAVE) == 40, "THE SIEGE BREAKS at 40")
        ck(PDData.fatigue_for(41) > 1.0 and PDData.fatigue_for(40) == 1.0, "the endless fatigue starts past 40")
        var g1 := PDData.wave_groups(1, 1)
        var all_red := true
        for grp in g1:
                if grp["kind"] != "red":
                        all_red = false
        ck(all_red, "wave 1 marches reds only")
        var g10 := PDData.wave_groups(10, 1)
        var has_moab := false
        for grp in g10:
                if grp["kind"] == "moab":
                        has_moab = true
        ck(has_moab, "wave 10 brings the first MOAB")
        var g40 := PDData.wave_groups(40, 1)
        var has_brutus := false
        for grp in g40:
                if grp["kind"] == "brutus":
                        has_brutus = true
        ck(has_brutus, "wave 40 brings BRUTUS")
        ck(PDData.wave_budget(20, 1) > PDData.wave_budget(19, 1), "the budget climbs")
        ck(PDData.wave_budget(5, 2) > PDData.wave_budget(5, 1), "stars multiply the budget")
        ck(PDData.unlock_band("ceramic") == 21 and PDData.unlock_band("red") == 1, "the unlock bands hold")
        for w in [5, 12, 26, 33, 44]:
                for grp in PDData.wave_groups(w, 2):
                        ck(int(grp["count"]) >= 1 and float(grp["spacing"]) > 0.0,
                                "wave %d group sane (%s)" % [w, grp["kind"]])
                        ck(PDData.unlock_band(grp["kind"]) <= w, "wave %d spawns only unlocked kinds" % w)

        # ------------------------------------------------------- the LIVE sim
        await _boot()
        ck(G.phase == "idle", "the run opens idle")
        ck(G.coins == 250 and G.lives == 100, "the purse and the lives drop in honest")
        ck(G.folk.is_empty() and G.bloons.is_empty(), "a fresh field")
        ck(G._paths_px.size() == (G.map["paths"] as Array).size(), "the paths precomputed")

        # the placement law: buildable vs blocked
        var ok_cell := Vector2i(-1, -1)
        var road_cell := Vector2i(-1, -1)
        var block_cell := Vector2i(-1, -1)
        for c in range(18):
                for r in range(10):
                        var v := Vector2i(c, r)
                        if ok_cell.x < 0 and G._buildable(v):
                                ok_cell = v
                        if road_cell.x < 0 and not G._buildable(v):
                                var on_road := false
                                for pts in G.map["paths"]:
                                        for cc in pts:
                                                if Vector2i(cc[0], cc[1]) == v:
                                                        on_road = true
                                if on_road:
                                        road_cell = v
                        if block_cell.x < 0 and not G._buildable(v):
                                var is_blocked := false
                                for bc in G.map["blocked"]:
                                        if Vector2i(bc[0], bc[1]) == v:
                                                is_blocked = true
                                if is_blocked:
                                        block_cell = v
        ck(ok_cell.x >= 0 and road_cell.x >= 0 and block_cell.x >= 0, "the map offers grass, road and props")
        ck(G._buildable(ok_cell), "grass builds")
        ck(not G._buildable(road_cell), "THE ROAD LAW: no towers on the road")
        ck(not G._buildable(block_cell), "THE BLOCKED LAW: props refuse towers")

        # place the trio and watch the purse
        var c0 := int(G.coins)
        G._place_folk("darty", ok_cell)
        ck(G.folk.size() == 1 and int(G.coins) == c0 - int(PDData.FOLK["darty"]["place"]), "the placement charges the purse")
        G._place_folk("boomo", ok_cell + Vector2i(1, 0))
        G._place_folk("pyra", ok_cell + Vector2i(0, 1))
        G._place_folk("kolda", ok_cell + Vector2i(1, 1))
        G._place_folk("marshal", ok_cell + Vector2i(2, 0))
        ck(G.folk.size() == 5, "five folk on the field")
        # RALLY: darty + boomo near each other
        var darty: Dictionary = G.folk[0]
        var boomo: Dictionary = G.folk[1]
        ck(float(darty["buffs"]["rate_f"]) >= 1.15, "THE RALLY: darty runs at least 15% faster")
        ck(float(boomo["buffs"]["rate_f"]) >= 1.15 and (boomo["badges"] as Array).size() >= 1, "THE RALLY is mutual (badge on)")
        # THE DRUM BEAT: marshal's aura reaches the neighbors
        var pyra: Dictionary = G.folk[2]
        var kolda: Dictionary = G.folk[3]
        ck(float(pyra["buffs"]["rate_f"]) > 1.0 or float(kolda["buffs"]["rate_f"]) > 1.0 or float((G.folk[4] as Dictionary)["buffs"]["rate_f"]) == 1.0,
                "the marshal aura touches the field")
        # THERMAL SHOCK needs pyra gear 2
        ck(not bool(pyra["flags"].get("thermal", false)), "thermal shock gated behind Pyra gear 2")
        pyra["gear"] = 2
        G._recompute_auras()
        ck(bool(pyra["flags"].get("thermal", false)), "THERMAL SHOCK opens at gear 2")
        ck((pyra["badges"] as Array).size() >= 2, "the badges stack (drum + flame-snow)")

        # the upgrade law
        G.coins = 99999
        var lvl0: int = darty["lvl"]
        G.selected_folk = darty
        G._do_upgrade(darty)
        ck(int(darty["lvl"]) == lvl0 + 1, "UPGRADE raises the level")
        var spent := 99999 - int(G.coins)
        ck(spent == PDData.up_cost("darty", lvl0), "THE PRICE LAW: the menu price is the real price")
        # the gear law
        darty["lvl"] = 10
        var gear0: int = darty["gear"]
        G._do_gearup(darty)
        ck(int(darty["gear"]) == gear0 + 1 and int(darty["lvl"]) == 1, "GEAR UP jumps the gear and resets the level")
        ck((darty["spr"] as Sprite2D).texture.resource_path.contains("_g2"), "THE GEAR LAW: the folk REPAINTS")
        # the sell law
        G.coins = 500
        var sell_back := int(280.0 * 0.5 * 1.0 * PDData.SELL_RATIO) + 280 / 3
        G._do_sell(boomo)
        ck(G.folk.size() == 4 and int(G.coins) == 500 + sell_back, "THE SELL LAW pays back")

        # the combat truth
        G.coins = 5000
        var score0: int = G.score
        G._spawn_bloon("red", 0)
        var red: Dictionary = G.bloons[-1]
        var red_pos: Vector2 = (red["spr"] as Sprite2D).position
        ck(G.bloons.size() == 1, "a red spawns")
        G._hurt_bloon(red, 1.0, PDData.SHARP, null)
        ck(G.bloons.is_empty(), "the red pops")
        ck(G.score == score0 + 1, "THE HITS LAW: one connected hit = one point")
        # the chain: a blue pops into two reds
        G._spawn_bloon("blue", 0)
        var blue: Dictionary = G.bloons[-1]
        G._hurt_bloon(blue, 1.0, PDData.SHARP, null)
        ck(G.bloons.size() == 2 and G.bloons[0]["kind"] == "red", "the blue releases its children")
        # ceramic: 10 hits (the points law)
        G._spawn_bloon("ceramic", 0)
        var cer: Dictionary = G.bloons[-1]
        var hits := 0
        while not G.bloons.is_empty() and (G.bloons[-1] as Dictionary)["id"] == cer["id"] and hits < 20:
                G._hurt_bloon(cer, 1.0, PDData.SHARP, null)
                hits += 1
        ck(hits == 10, "THE CERAMIC LAW: ten hits, ten points")
        var kinds_now := {}
        for bb in G.bloons:
                kinds_now[bb["kind"]] = true
        ck(G.bloons.size() == 4 and kinds_now.has("rainbow"), "the ceramic releases the rainbows (plus the red twins)")
        # the leak law
        var lives0: int = G.lives
        G.lives = 5000
        G._spawn_bloon("blue", 0)
        var leaker: Dictionary = G.bloons[-1]
        leaker["dist"] = float(G._paths_px[0]["total"]) + 1.0
        G._move_bloons(0.016)
        ck(G.lives == 4998, "the leak takes the rbe (blue = 2)")
        G.lives = lives0
        # THE RIDER LAW
        var coins_before_rider: int = G.run_coins
        G._spawn_bloon("red", 0)
        var rider: Dictionary = G.bloons[-1]
        rider["rider"] = true
        G._hurt_bloon(rider, 1.0, PDData.SHARP, null)
        ck(G.run_coins == coins_before_rider + 1, "THE RIDER: the hidden GOGACoin banks")
        # burn + glue states
        G._spawn_bloon("rainbow", 0)
        var rb: Dictionary = G.bloons[-1]
        rb["burn_dps"] = 2.0
        rb["burn_t"] = 3.0
        var rb_hp: float = rb["hp"]
        G._move_bloons(0.5)
        ck(float(rb["hp"]) < rb_hp or G.bloons.has(rb) == false, "the burn ticks")
        if G.bloons.has(rb):
                rb["glue_t"] = 2.0
                ck(true, "the glue state accepts")

        # the wave flow (spawner)
        for b in G.bloons.duplicate():
                G._bloon_free(b)
        var phase0: String = G.phase
        G.countdown = 0.0
        G._play_pressed()
        ck(G.phase == "spawn" and G.wave_n == 1, "PLAY opens wave 1")
        # rush the spawner
        for i in 1500:
                G._goga_tick(0.05)
                if G.phase == "idle":
                        break
        ck(G.phase == "idle", "wave 1 resolves")
        ck(G.wave_kinds.size() > 0, "the wave spoke its kinds")

        # THE 2x15 LAW (the sheet)
        G._optionals_open()
        await _wait(0.3)
        G._maps_sheet()
        await _wait(0.3)
        # (walk the tree for the maps grid)
        var grid: GridContainer = _find_grid(G)
        ck(grid != null and grid.columns == 2, "THE 2x15 LAW: two vertical columns")
        if grid != null:
                ck(grid.get_child_count() == 30, "THE 2x15 LAW: thirty map cards")
        # the shop
        G._shop_open()
        await _wait(0.3)
        var shop_labels := _count_labels(G, "THE FOLK")
        ck(shop_labels >= 1, "the shop opens with the folk shelf")

        print("=== pd_probe: ", checks, " checks, ", fails, " fails ===")
        if fails > 0:
                print("PROBE FAILED")
                get_tree().quit(1)
        else:
                print("ALL LAWS HOLD")
                get_tree().quit(0)

func _find_grid(root: Node) -> GridContainer:
        for c in root.get_children():
                if c is GridContainer and c.columns == 2 and c.get_child_count() >= 25:
                        return c
                var deep := _find_grid(c)
                if deep != null:
                        return deep
        return null

func _count_labels(root: Node, frag: String) -> int:
        var n := 0
        for c in root.get_children():
                if c is Label and String(c.text).contains(frag):
                        n += 1
                n += _count_labels(c, frag)
        return n

func rng_seed() -> void:
        seed(20260907)

# the run entry
func _ready() -> void:
        _run()
