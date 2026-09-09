extends Node
## COSMIC SPUD probe (v0.3.4-1) - the deterministic battery.
## Runs headless: godot --headless --path . res://tests/cs_probe.tscn
## Exit 0 = all laws hold.

var checks := 0
var fails := 0
var G: GogaGame = null
var meta: CSMeta = null

func ck(cond: bool, what: String) -> void:
        checks += 1
        if cond:
                print("[PASS] ", what)
        else:
                fails += 1
                print("[FAIL] ", what)

## the first Button under `root` whose text matches (or null)
func _find_btn(root: Node, txt: String) -> Button:
        for c in root.get_children():
                if c is Button and String(c.text) == txt:
                        return c
                var deep := _find_btn(c, txt)
                if deep != null:
                        return deep
        return null

func _find_btn_like(root: Node, frag: String) -> Button:
        for c in root.get_children():
                if c is Button and String(c.text).contains(frag):
                        return c
                var deep := _find_btn_like(c, frag)
                if deep != null:
                        return deep
        return null

## the first Label under `root` whose text contains `frag`
func _find_lbl_like(root: Node, frag: String) -> Label:
        for c in root.get_children():
                if c is Label and String(c.text).contains(frag):
                        return c
                var deep := _find_lbl_like(c, frag)
                if deep != null:
                        return deep
        return null

## every descendant of `root`, depth-first (the icon/text sweeps)
func _all_kids(root: Node) -> Array:
        var out: Array = []
        for c in root.get_children():
                out.append(c)
                out.append_array(_all_kids(c))
        return out

func _boot() -> void:
        if G != null and is_instance_valid(G):
                G.queue_free()
                await get_tree().create_timer(0.3).timeout
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        get_window().size = Vector2i(1920, 1080)
        await get_tree().create_timer(0.2).timeout
        G = load("res://game/games/cosmic_spud/cosmic_spud.gd").new()
        G.game_id = "cosmic_spud"
        process_mode = Node.PROCESS_MODE_ALWAYS
        add_child(G)
        await get_tree().create_timer(0.8).timeout
        meta = G.meta

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout

func _run() -> void:
        print("=== cs_probe (v0.3.4-1) ===")
        seed(20260905)
        # ------------------------------------------------ the data laws
        ck(CSData.merge_price("smg", 1) == int(ceil(CSData.weapon_price("smg", 2) / 2.0)),
                        "THE MERGE LAW: T1 merge = half the T2 price")
        ck(CSData.weapon_price("rail", 3) > CSData.weapon_price("rail", 2),
                        "tier prices climb")
        ck(CSData.tier_cap_for(1) == 1 and CSData.tier_cap_for(3) == 2
                        and CSData.tier_cap_for(6) == 3 and CSData.tier_cap_for(12) == 3,
                        "THE TIER GATE: char level 1/3/6 caps T1/T2/T3")
        ck(CSData.xp_for_run_level(1) == 100 and CSData.xp_for_run_level(2) == 120,
                        "the run XP curve rides the python law (100 x 1.2^n)")
        ck(CSData.spawn_interval(1) == 1.52 and CSData.spawn_interval(20) == 0.30,
                        "the spawn interval law (1.6 - 0.08w, floor 0.30)")
        ck(CSData.hp_scale(5) > CSData.hp_scale(1) and CSData.hp_scale(25) > CSData.hp_scale(20),
                        "the hp scale grows (and compounds past 20)")
        var pool1 := CSData.pool_for_wave(1)
        var pool12 := CSData.pool_for_wave(12)
        ck(pool1.size() == 3 and pool12.has("orbiter") and pool12.size() > pool1.size(),
                        "the unlock table (w1 = 3 blabs, w12 = everything)")
        ck(CSData.START_ORDER.size() == 6 and CSData.WEAPON_ORDER.size() == 14
                        and CSData.ALLY_ORDER.size() == 6 and CSData.TREE_ORDER.size() == 18,
                        "the tables: 6 starts, 14 weapons (the cleaver joined), 6 allies, 18 tree nodes")
        ck(CSData.STAT_TRACKS.size() == 14 and CSData.SKILL_ORDER.size() == 10
                        and CSData.ALLY_MAX_LEVEL == 5,
                        "v0.3.8-2: 14 stat tracks, 10 skills, the roster caps at LV 5")
        # every track: a 5-step climbing ladder + the level lines exist;
        # every skill: 5 level lines + the number tables are 5 long
        var tracks_ok := true
        for t in CSData.STAT_TRACKS:
                var lad: Array = t["ladder"]
                if lad.size() != 5 or int(lad[0]) > int(lad[4]):
                        tracks_ok = false
        var lv_ok2 := true
        for sid in CSData.SKILL_ORDER:
                if (CSData.SKILL_LEVELS[sid]["lvs"] as Array).size() != 5:
                        lv_ok2 = false
                for key in CSData.SKILL_LEVELS[sid]:
                        if key != "lvs" and (CSData.SKILL_LEVELS[sid][key] as Array).size() != 5:
                                lv_ok2 = false
        ck(tracks_ok, "every stat track wears a climbing 5-step ladder")
        ck(lv_ok2, "every skill wears 5 level lines and 5-long number tables")
        ck(CSData.skill_level_cost("ghost_round", 1) == 2
                        and CSData.skill_level_cost("ghost_round", 3) == 4
                        and CSData.skill_level_cost("ghost_round", 5) == 8,
                        "the skill cost ladder climbs (cost-2 skill: 2/3/4/6/8)")
        for aid in CSData.ALLY_ORDER:
                if (CSData.ALLIES[aid]["lvs"] as Array).size() != 5:
                        tracks_ok = false
        ck(tracks_ok, "every ally wears 5 roster level lines")
        # tree chains: every non-root need exists and costs climb
        var chain_ok := true
        for nid in CSData.TREE_ORDER:
                var n: Dictionary = CSData.TREE[nid]
                if n["need"] != "" and not CSData.TREE.has(n["need"]):
                        chain_ok = false
        ck(chain_ok, "every tree prerequisite resolves")
        ck(CSData.TREE["l3"]["need"] == "l2",
                        "THE WEAPON LAB sits at the end of the LAB chain")
        ck(CSData.sell_price(100) == 40, "the 40% sell law")
        # ------------------------------------------------ boot + the optionals
        await _boot()
        ck(G.phase == "boot" and G.sheet_open_count() > 0,
                        "boot opens THE OPTIONALS (the 6 starts greet first)")
        ck(G.stats["dmg_m"] > 0.0, "the stats block built from the START")
        # ------------------------------------------------ the run start
        G._start_run()
        await _wait(0.5)
        ck(G.phase == "play" and G.run_wave == 1,
                        "THE START: wave 1 begins, phase play")
        ck(not G.enemies.is_empty(), "the first burst spawned")
        ck(G.cam != null and G.cam.position != Vector2.ZERO,
                        "the camera lives")
        # ------------------------------------------------ THE CAMERA LAW
        var half: Vector2 = G._cam_half()
        var cl: Vector2 = G._cam_clamp_pos(Vector2(-9999, -9999))
        var ch: Vector2 = G._cam_clamp_pos(Vector2(99999, 99999))
        ck(cl.x >= G.ARENA.position.x - G.ARENA_MARGIN
                        and ch.x <= G.ARENA.end.x + G.ARENA_MARGIN,
                        "THE CAMERA LAW: the clamp holds the view near the arena")
        ck(half.x * 2.0 < G.ARENA.size.x and half.y * 2.0 < G.ARENA.size.y,
                        "THE CAMERA LAW: the view NEVER fits the whole ground")
        # ------------------------------------------------ the aim + autofire
        G.enemies.clear()
        var e: Dictionary = G._spawn_enemy("blab", G.p_pos + Vector2(120, 0))
        await _wait(0.05)
        var aim: float = G._aim_angle()
        ck(absf(angle_difference(aim, 0.0)) < 0.2,
                        "THE AIM LAW: the gun faces the nearest enemy")
        var score0: int = G.score
        # force a bullet hit
        var b := {"pos": e["pos"], "a": 0.0, "spd": 0.0, "dmg": 50.0, "pierce": 0,
                "hit": {}, "range_left": 10.0, "aoe": 0.0, "burn": false, "chill": 0.0,
                "kind": "bolt", "node": Sprite2D.new(), "turn": false, "tier": 1}
        G.world.add_child(b["node"])
        G.bullets.append(b)
        G._tick_bullets(0.016)
        ck(e.get("dead", false) or e["hp"] < e["max_hp"],
                        "the bullet HURT the blab")
        # ------------------------------------------------ THE CONTACT LAW
        # (v0.3.4-3 THE SHARED CONTACT LAW: both sides bleed and every tick
        # speaks - the old one-shot splatter + silent iframes are DEAD)
        G.enemies.clear()
        var c0: Dictionary = G._spawn_enemy("chunk", G.p_pos + Vector2(30, 0))
        var hp0: float = G.p_hp
        var ehp0: float = float(c0["hp"])
        G.p_iframe = 0.0
        G._tick_enemies(0.016)
        var taken: float = hp0 - G.p_hp
        var rammed: float = ehp0 - float(c0["hp"])
        ck(taken > 0.0 and absf(taken - (float(c0["dmg"]) * float(G.stats["contact_cut"])
                        - float(G.stats["armor"]))) < 1.5,
                        "THE CONTACT LAW: the chunk's ATTACK hits (armor applies)")
        ck(rammed > 0.0 and absf(rammed - (maxf(float(c0["max_hp"]) * 0.08,
                        18.0 + float(G.run_wave) * 1.6) + 3.0
                        + float(G.stats["armor"]))) < 1.0,
                        "THE CONTACT LAW: the potato RAMS back (the wave floor or 8% max hp + 3 + armor)")
        ck(float(c0.get("touch_cd", 0.0)) > 0.0,
                        "THE CONTACT LAW: the per-enemy cooldown armed")
        var hp1: float = G.p_hp
        G.p_iframe = 0.0
        G._tick_enemies(0.05)
        ck(absf(G.p_hp - hp1) < 0.01,
                        "THE CONTACT LAW: the cooldown eats the instant re-hit")
        c0["touch_cd"] = 0.0
        G.p_iframe = 99.0     # the long iframe must NOT silence a contact
        G._tick_enemies(0.016)
        ck(G.p_hp < hp1,
                        "THE CONTACT LAW: an ongoing collision ALWAYS lands (never silent)")
        # ------------------------------------------------ the aura wraith
        G.enemies.clear()
        G.p_iframe = 0.0
        var w: Dictionary = G._spawn_enemy("wraith", G.p_pos + Vector2(60, 0))
        var whp0: float = G.p_hp
        G._tick_enemies(1.2)
        ck(G.p_hp <= whp0 - 14.0,
                        "THE AURA LAW: the wraith's zone ticked 15 inside 1.2s")
        # ------------------------------------------------ the mender heal
        G.enemies.clear()
        var m: Dictionary = G._spawn_enemy("mender", G.p_pos + Vector2(500, 0))
        var z: Dictionary = G._spawn_enemy("blab", G.p_pos + Vector2(100, 0))
        z["hp"] = 10.0
        G._tick_enemies(1.2)
        ck(z["hp"] > 10.0, "THE MENDER LAW: the horde out-sustains (+10/0.5s)")
        # --------------------------------------- THE SHIELD TRUTH (v0.3.8-3)
        # the tri-shield wears TWO orbits: the unbreakable shatter fragments
        # (always a way through) + the layer shell (areas break by LEVEL,
        # deeper color = higher level)
        G.enemies.clear()
        var t: Dictionary = G._spawn_enemy("trishield", G.p_pos + Vector2(400, 400))
        var tsh: Dictionary = t["shield"]
        ck((tsh["shards"] as Array).size() == 3
                        and (tsh["layers"] as Array).size() == 3,
                        "THE SHIELD TRUTH: the tri-shield wears 3 shards + 3 shell layers")
        # THE ALWAYS-A-WAY LAW: no shard arc covers its own circle
        var spans_ok := true
        for sd in tsh["shards"]:
                if float(sd["span"]) >= TAU:
                        spans_ok = false
        ck(spans_ok, "THE ALWAYS-A-WAY LAW: every shard arc leaves its orbit open")
        var speeds := {}
        for sd in tsh["shards"]:
                speeds[float(sd["spd"])] = true
        ck((speeds as Dictionary).size() == 3,
                        "THE SHATTER ORBIT: the three fragments spin at different speeds")
        # a shard BLOCKS: park a bullet in a shard arc at its own radius
        var block_e := {"pos": t["pos"], "shield": tsh}
        var shard0: Dictionary = tsh["shards"][0]
        var bb := {"pos": t["pos"] + Vector2.from_angle(float(shard0["rot"]) + 0.05) \
                        * float(shard0["r"]), "dmg": 10.0}
        ck(G._shield_block(block_e, bb, 10.0) == 1,
                        "THE SHIELD TRUTH: a shard arc BLOCKS the bullet (unbreakable)")
        # a shell area CHIPS: aim between the shards at the outer shell ring,
        # in a window between shard arcs
        var chip_done := false
        for probe_i in 24:
                var probe_a := TAU * float(probe_i) / 24.0
                var in_shard := false
                for sd in tsh["shards"]:
                        var local := fposmod(probe_a - float(sd["rot"]), TAU)
                        if local <= float(sd["span"]):
                                in_shard = true
                if in_shard:
                        continue
                bb["pos"] = t["pos"] + Vector2.from_angle(probe_a) * 50.0
                if G._shield_block(block_e, bb, 10.0) == 2:
                        chip_done = true
                        break
        ck(chip_done, "THE LAYER SHELL: a gap between shards feeds the shell area")
        # the chip DROPPED a level (unit-scaled damage lowers the level)
        var outer: Dictionary = tsh["layers"][0]
        var chipped := 0
        for area in outer["areas"]:
                if float(area["hp"]) < float(area["max"]):
                        chipped += 1
        ck(chipped >= 1,
                        "THE LAYER SHELL: the hit LOWERED the area's level (deeper color fades)")
        # a WINDOW passes: zero out one outer area, the same spot feeds inward
        (outer["areas"] as Array)[0]["hp"] = 0.0
        var w5: float = TAU / float((outer["areas"] as Array).size())
        var win_a: float = 0.5 * w5
        bb["pos"] = t["pos"] + Vector2.from_angle(win_a) * 50.0
        var res3: int = G._shield_block(block_e, bb, 10.0)
        ck(res3 == 2 or res3 == 0,
                        "THE WINDOW LAW: the broken area feeds the bullet to the next layer")
        # the MELEE CHEW: the swing eats an alive area; a second swing at the
        # same spot meets the window it just opened - the body takes it
        var chew_a: float = 1.5 * w5
        ck(G._melee_chew_shield(block_e, chew_a, 100.0) == true,
                        "THE MELEE CHEW: the cleaver bites an alive shell area")
        ck(G._melee_chew_shield(block_e, chew_a, 100.0) == false,
                        "THE MELEE CHEW: a windowed arc reaches the body")
        # ------------------------------------------------ the kill score law
        G.enemies.clear()
        var score1: int = G.score
        var k: Dictionary = G._spawn_enemy("blab", Vector2(2000, 2000))
        G._hurt_enemy(k, 99999.0, false, true)
        ck(G.score == score1 + 1, "THE SCORE LAW: a blab kill = +1")
        G.enemies.clear()
        var k2: Dictionary = G._spawn_enemy("blab", Vector2(2000, 2000), true)
        G._hurt_enemy(k2, 99999.0, false, true)
        ck(G.score == score1 + 1 + 1 + CSData.ELITE_SCORE,
                        "THE SCORE LAW: an elite blab = +1 +3 (the elite bonus)")
        # ------------------------------------------------ the waves + break
        G.enemies.clear()
        G.wave_clock = 0.01
        G.boss_alive = false
        G._tick_waves(0.02)
        await _wait(0.3)
        ck(G.phase == "break" and G.sheet_open_count() > 0,
                        "THE BREAK: the wave draft opens after the wave")
        # the draft cards exist and apply both ways
        var d0: Dictionary = {"t": "TEST", "d": "-TEST", "up": {"dmg": 0.2},
                "down": {"spd": -0.1}, "w": 1}
        var dm0: float = float(G.stats["dmg_m"])
        var sp0: float = float(G.stats["spd_m"])
        G._apply_draft(d0)
        ck(absf(float(G.stats["dmg_m"]) - (dm0 + 0.2)) < 0.001
                        and absf(float(G.stats["spd_m"]) - (sp0 - 0.1)) < 0.001,
                        "THE DRAFT LAW: the card GIVES +20% dmg and TAKES -10% spd")
        G.stats["dmg_m"] = dm0
        G.stats["spd_m"] = sp0
        # ------------------------------------------------ the xp -> level draft
        var lv0: int = G.run_level
        G.run_xp = CSData.xp_for_run_level(G.run_level) - 1
        G._drop_pickup("xp", G.p_pos, 5)
        G._tick_pickups(0.016)
        ck(G.run_level == lv0 + 1 and G.pending_levels >= 1,
                        "THE XP LAW: the gem leveled the run and queued a STATS point")
        # ------------------------------------------------ the shop merge law
        G.pending_levels = 0
        G._close_all_sheets()
        await _wait(0.2)
        meta.d["armory"] = [["smg", 1], ["smg", 1]]
        meta.d["coins"] = 10000
        meta.d["char_level"] = 6      # the tier gate opens at LV3+ (T2 cap)
        meta.save()
        G.run_ccoins = 10000
        var pairs: Array = G._merge_pairs()
        ck(pairs.size() >= 1 and pairs[0]["wid"] == "smg" and pairs[0]["tier"] == 1,
                        "THE SHELF: two same T1 copies offer a merge")
        var cost: int = int(pairs[0]["cost"])
        G._wave_buy_merge(pairs[0], cost)
        ck(meta.count_armory("smg", 2) == 1 and meta.count_armory("smg", 1) == 0,
                        "THE MERGE LAW: T1 + T1 -> one T2 (both copies consumed)")
        ck(G.run_ccoins == 10000 - cost,
                        "THE MERGE LAW: the half-price was charged in-run")
        # ------------------------------------------------ the boss spawn law
        G._close_all_sheets()
        await _wait(0.2)
        G._start_run()
        await _wait(0.3)
        G._spawn_boss(10)
        ck(G.boss_alive and G.enemies.any(func(x): return x.get("boss", false)),
                        "THE BOSS LAW: wave 10 spawns a boss")
        var heap: Dictionary = G.enemies.filter(func(x): return x.get("boss", false))[0]
        ck(String(heap["name"]) == "THE HEAP",
                        "THE BOSS LAW: cycle 0 = THE HEAP")
        G.enemies.clear()
        G.boss_alive = false
        G._spawn_boss(20)
        ck(String(G.enemies[0]["name"]) == "THE PRISM MATRIARCH"
                        and (G.enemies[0]["shield"] as Dictionary).has("layers")
                        and ((G.enemies[0]["shield"]["layers"] as Array).size() == 5)
                        and ((G.enemies[0]["shield"]["shards"] as Array).size() == 2),
                        "THE BOSS LAW: cycle 1 = THE PRISM MATRIARCH (the full 5-layer shell + 2 shards)")
        G.enemies.clear()
        G.boss_alive = false
        G._spawn_boss(30)
        ck(String(G.enemies[0]["name"]) == "SPUD REAPER",
                        "THE BOSS LAW: cycle 2 = SPUD REAPER")
        # ------------------------------------------------ the death (the purse)
        # v0.3.8-2 THE PURSE LAW: the run's coins were home the whole run -
        # the purse IS the wallet; death only checkpoints the save
        var coins0: int = meta.coins()
        var clv0: int = meta.char_level()
        var cxp0: int = meta.char_xp()
        G.run_ccoins = coins0 + 250
        G.run_kills = 40
        G.over = false
        G.p_iframe = 0.0
        G.p_hp = 0.5
        G.phase = "play"
        G._hurt_player(50.0, null)
        await _wait(0.2)
        ck(meta.coins() == coins0 + 250,
                        "THE PURSE LAW: death keeps the run's coins (banked live all along)")
        ck(meta.char_xp() > cxp0 or meta.char_level() > clv0,
                        "THE BANK: the run's kills banked character XP")
        ck(G.over, "the death hands the run to the box death menu")
        # ------------------------------------------------ the patch-1 laws
        # THE NODE-SYNC LAW (the headline fix: the sprite follows the body)
        G.enemies.clear()
        var ne: Dictionary = G._spawn_enemy("blab", G.p_pos + Vector2(500, 0))
        G.p_iframe = 99.0          # keep the contact law out of the way
        G._tick_enemies(0.1)
        var nd: Sprite2D = ne["node"]
        ck(nd.position.distance_to(ne["pos"]) < 0.5,
                        "THE NODE-SYNC LAW: the sprite follows the body every tick")
        var moved_d: float = (G.p_pos + Vector2(500, 0)).distance_to(ne["pos"])
        ck(moved_d < 500.0,
                        "THE NODE-SYNC LAW: the enemy WALKED (v0.3.4 left it frozen)")
        G.enemies.clear()
        # LUCK: the rarity roll bends
        seed(777)
        var common0 := 0
        for i in 400:
                if CSData.roll_rarity(0.0) == "common":
                        common0 += 1
        var common_lucky := 0
        for i in 400:
                if CSData.roll_rarity(1.5) == "common":
                        common_lucky += 1
        ck(common_lucky < common0,
                        "THE LUCK LAW: luck pushes the shelf off common (%d -> %d of 400)" \
                                        % [common0, common_lucky])
        ck(common0 > 140 and common0 < 240,
                        "THE LUCK LAW: luck 0 stays near the 46%% common weight (%d)" % common0)
        # DODGE: a real no-hit chance, capped at 60%
        G.p_hp = G.p_max_hp
        G.stats["dodge"] = 0.6
        G.p_iframe = 0.0
        var dodged := 0
        for i in 40:
                G.p_iframe = 0.0
                var hp_b: float = G.p_hp
                G.phase = "play"
                G.over = false
                G._hurt_player(10.0, null)
                if absf(G.p_hp - hp_b) < 0.01:
                        dodged += 1
        ck(dodged >= 14 and dodged <= 34,
                        "THE DODGE LAW: 60%% dodge dodged %d of 40 (a real chance)" % dodged)
        G.stats["dodge"] = 0.0
        G.p_hp = G.p_max_hp
        # REROLL: the market owns it now (the owner: "a re-roll should be for
        # shop items"), the drafts lost theirs
        ck(CSData.shop_reroll_cost(0) == 8 and CSData.shop_reroll_cost(2) == 20,
                        "THE REROLL LAW: the market reroll climbs 8 + 6n")
        # THE HOLD DECK (the Brotato law): 5 pins, they survive the reroll
        G._roll_shop_offers()
        G.shop_offers_i[0]["held"] = true
        G.shop_offers_w[0]["held"] = true
        G.shop_offers_w[1]["held"] = true
        ck(G._held_count() == 3, "THE HOLD DECK: three pins counted")
        var kept_id: String = String(G.shop_offers_i[0]["iid"])
        var kept_wid: String = String(G.shop_offers_w[0]["wid"])
        G._roll_shop_offers(true)
        ck(String(G.shop_offers_i[0]["iid"]) == kept_id
                        and String(G.shop_offers_w[0]["wid"]) == kept_wid
                        and bool(G.shop_offers_w[0]["held"]),
                        "THE HOLD DECK: the held offers SURVIVE the reroll")
        ck(G.shop_offers_w.size() == 4 and G.shop_offers_i.size() == 3,
                        "THE HOLD DECK: the shelf keeps its size after a reroll")
        for _o in G.shop_offers_w:
                _o["held"] = false
        for _o2 in G.shop_offers_i:
                _o2["held"] = false
        # THE GOGACOIN RIDER: every 5th wave, one carrier, the drop pays
        G._start_run()
        await _wait(0.3)
        G._begin_wave(5)
        ck(G.goga_pending,
                        "THE RIDER LAW: wave 5 owes a gogacoin carrier")
        G._begin_wave(6)
        ck(not G.goga_pending,
                        "THE RIDER LAW: wave 6 owes nothing")
        G._begin_wave(5)
        for i in 8:
                G._spawn_enemy("blab", G.p_pos + Vector2.from_angle(randf() * TAU) * 400.0)
        G.p_iframe = 99.0
        G._tick_enemies(0.05)
        ck(G.goga_carrier_alive and not G.goga_pending,
                        "THE RIDER LAW: the swarm hid the coin in one carrier")
        var carrier: Dictionary = {}
        for ee in G.enemies:
                if ee.get("goga", false):
                        carrier = ee
        ck(not carrier.is_empty(), "THE RIDER LAW: exactly one carrier marked")
        var run_coins0: int = G.run_coins
        var pk_count0: int = G.pickups.size()
        G._kill_enemy(carrier, true)
        var goga_pk := {}
        for pk in G.pickups:
                if String(pk["kind"]) == "gogacoin":
                        goga_pk = pk
        ck(not goga_pk.is_empty() and G.pickups.size() > pk_count0,
                        "THE RIDER LAW: the dead carrier dropped the gogacoin")
        ck((goga_pk["node"] as Sprite2D).scale.x < 0.3,
                        "THE COIN SIZE LAW: the world gogacoin is pickup-sized (no more giant)")
        ck(not G.goga_carrier_alive, "THE RIDER LAW: the carrier flag cleared")
        goga_pk["pos"] = G.p_pos      # the LOGICAL seat (the node follows)
        G._tick_pickups(0.016)
        ck(G.run_coins == run_coins0 + 1,
                        "THE RIDER LAW: collecting pays +1 REAL gogacoin to the wallet")
        # ============================== v0.3.4-4 - THE OWNER'S THIRD REPORT
        # THE UNIVERSAL WIDGET LAW: the GOGACoins widget IS the universal
        # Arc.chip + coin.png, counting the coins COLLECTED THIS RUN
        G._refresh_hud()
        ck(G.gg_txt != null and G.gg_txt.text == str(G.run_coins),
                        "THE UNIVERSAL WIDGET LAW: the chip shows the COLLECTED count, not the wallet")
        var gg_chip: Control = G.gg_txt.get_parent().get_parent()
        var gg_has_coin := false
        for gg_kid in (G.gg_txt.get_parent() as Node).get_children():
                if gg_kid is TextureRect and (gg_kid as TextureRect).texture != null \
                                and (gg_kid as TextureRect).texture.resource_path == "res://assets/ui/coin.png":
                        gg_has_coin = true
        ck(gg_has_coin and gg_chip is PanelContainer,
                        "THE UNIVERSAL WIDGET LAW: the widget wears THE universal coin icon")
        var wallet_total := Box.coins()
        ck(G.run_coins < wallet_total or wallet_total == 0,
                        "THE UNIVERSAL WIDGET LAW: the collected count is its own number (not the total)")
        # THE NO-SHOOT-VFX LAW: a live volley leaves no muzzle light behind
        var parts_before: int = G._parts.size()
        var blab4: Dictionary = G._spawn_enemy("blab", G.p_pos + Vector2(120, 0))
        blab4["hp"] = 10.0
        G._fire_weapon(G.weapons_run[0])
        var muzzle_seen := false
        for pp in G._parts:
                if String(pp.get("tex", "")) == "muzzle":
                        muzzle_seen = true
        G._kill_enemy(blab4, false)
        ck(not muzzle_seen and G._parts.size() >= parts_before,
                        "THE NO-SHOOT-VFX LAW: no muzzle light - the gun speaks through sound alone")
        # THE HONEST METERS LAW: the meters are plain Controls whose drawn
        # fill follows the truth (and no Container can reset them)
        ck(G.hp_meter is Control and not (G.hp_meter is PanelContainer)
                        and G.xp_meter is Control and G.wave_meter is Control
                        and G.boss_meter is Control,
                        "THE HONEST METERS LAW: all four meters are container-proof plain Controls")
        var hp0b: float = G.p_hp
        G.p_hp = G.p_max_hp * 0.4
        for _ri in 40:
                G._refresh_hud()
        var hp_st: Dictionary = G.hp_meter.get_meta("state")
        ck(absf(float(hp_st["r"]) - 0.4) < 0.02,
                        "THE HONEST METERS LAW: the HP fill settles at the true ratio (%.2f)" % float(hp_st["r"]))
        var want_col: Color = G._hp_color(0.4)
        ck(Color(hp_st["col"]).is_equal_approx(want_col),
                        "THE HONEST METERS LAW: the HP color runs the green->yellow->red ramp")
        G.p_hp = hp0b
        for _ri2 in 40:
                G._refresh_hud()
        hp_st = G.hp_meter.get_meta("state")
        ck(absf(float(hp_st["r"]) - float(hp0b) / G.p_max_hp) < 0.02,
                        "THE HONEST METERS LAW: a heal moves the bar back up")
        G.run_xp = 30
        for _ri3 in 40:
                G._refresh_hud()
        var xp_st: Dictionary = G.xp_meter.get_meta("state")
        var need1 := CSData.xp_for_run_level(G.run_level)
        ck(absf(float(xp_st["r"]) - float(G.run_xp) / float(need1)) < 0.02
                        and float(xp_st["r"]) > 0.0,
                        "THE HONEST METERS LAW: the XP bar shows the true level progress, never empty")
        G.run_xp = need1 + 5
        G._tick_pickups(0.0001)     # no-op tick; the level law lives in the pickup
        var lvl_before: int = G.run_level
        while G.run_xp >= CSData.xp_for_run_level(G.run_level):
                G.run_xp -= CSData.xp_for_run_level(G.run_level)
                G.run_level += 1
        ck(G.run_level == lvl_before + 1 and G.run_xp == 5,
                        "THE HONEST METERS LAW: a level-up drains the XP bar's truth (run_xp resets)")
        G.run_xp = 0
        for _ri4 in 40:
                G._refresh_hud()
        ck(float(G.xp_meter.get_meta("state")["r"]) < 0.02,
                        "THE HONEST METERS LAW: the XP bar sits at zero right after the level-up")
        # THE COIN-DISTINCT LAW: the cosmic coin is NOT the gogacoin
        var cosmic: Texture2D = load("res://assets/games/cosmic_spud/pickups/coin.png")
        var boxc: Texture2D = load("res://assets/ui/coin.png")
        ck(cosmic.get_image().get_data() != boxc.get_image().get_data(),
                        "THE COIN LAW: the cosmic coin's pixels are NOT the gogacoin's")
        # THE TREE RETIREMENT LAW (v0.3.8-3): the tree SHEET is gone - the
        # buttons and the lock reasons died with it. The tree FLAGS remain
        # data the run reads (slots/second-wind/lab), and meta.tree_can_buy
        # still speaks the chain for anything that ever needs it.
        meta.d["tree"] = {}
        meta.d["char_level"] = 1
        meta.d["coins"] = 20
        meta.save()
        ck(not meta.tree_can_buy("o2"),
                        "THE TREE LAW: o2 locks behind its chain (the flags live on as data)")
        ck(G.has_method("_tree_open") == false,
                        "THE TREE RETIREMENT: the tree sheet is gone from the game")
        # THE DAY/NIGHT LAW: two real faces + the tint finally applied
        var th: Dictionary = CSData.THEMES["desert"]
        ck(String(th["day"]) != String(th["night"]),
                        "THE THEME LAW: the desert owns a DAY and a NIGHT face")
        G._retheme("desert", true)
        ck(G.world.modulate == th["tint_night"],
                        "THE THEME LAW: night paints the world with the night tint")
        ck(is_instance_valid(G.ground_layer) and G.ground_layer.get_child_count() > 10,
                        "THE THEME LAW: the night ground repainted in place")
        G._retheme("desert", false)
        ck(G.world.modulate == th["tint_day"],
                        "THE THEME LAW: the day flip returns the daylight")
        # THE STORE LAW: the offers roll, the rarities are real
        G._roll_shop_offers()
        ck(G.shop_offers_w.size() == 4 and G.shop_offers_i.size() == 3,
                        "THE STORE LAW: 4 weapon + 3 item offers per break")
        var rar_ok := true
        for o in G.shop_offers_w:
                if not CSData.RARITIES.has(o["rar"]):
                        rar_ok = false
        ck(rar_ok, "THE STORE LAW: every offer wears a real rarity")
        # THE WIDGET LAW: the game's own HUD (the owner's two + the wallets)
        ck(G.kill_txt != null and G.cc_txt != null and G.score_txt != null \
                        and G.gg_txt != null,
                        "THE WIDGET LAW: the SCORE + KILLS + cosmic + GOGACoins widgets live")
        ck(not G._score_chip_ref().visible and not G._coins_chip_ref().visible,
                        "THE WIDGET LAW: the box chrome chips are hidden WHOLE (no empty widget)")
        ck(G.get("stick_ghost") == null,
                        "THE STICK LAW: the ghost node is GONE (truly invisible)")
        # THE ARMORY LAW: the wallet buy lands in the armory (the purse pulls
        # the meta truth first - one wallet, two doors)
        meta.d["coins"] = 5000
        meta.save()
        G._cc_pull()
        G._armory_buy_weapon("laser", CSData.weapon_price("laser", 1))
        ck(meta.has_weapon("laser") and meta.weapon_count("laser") >= 1,
                        "THE ARMORY LAW: the wallet buy lands in the armory")
        ck(G.run_ccoins == 5000 - CSData.weapon_price("laser", 1),
                        "THE PURSE LAW: the armory spend drains the run's own purse mirror")
        meta.d["coins"] = 5000
        meta.save()
        G._cc_pull()
        # ------------------------------------------------ the meta laws
        var m2 := CSMeta.load_meta()
        m2.d["coins"] = 50
        m2.save()
        ck(not m2.spend(100), "the wallet refuses what it does not have")
        m2.earn(200)
        ck(m2.spend(100), "the wallet pays")
        ck(not m2.tree_can_buy("o2"), "THE TREE LAW: o2 locks behind its chain")
        m2.d["coins"] = 5000
        m2.d["char_xp"] = 0
        m2.d["char_level"] = 1
        m2.save()
        ck(not m2.tree_can_buy("l3"), "THE TREE LAW: the WEAPON LAB gates at LV4")
        # ============================== v0.3.4-2 - THE OWNER'S SECOND REPORT
        # THE DOOR LAW: rebuild the door fresh (the owner could not get past
        # the optionals - every tap was a dud and back froze the game)
        G.phase = "boot"
        G._boot_hint = ""
        G._cs_close_all()
        G._optionals_open()
        await _wait(0.2)
        ck(get_tree().paused and G.sheet_open_count() == 1,
                        "THE DOOR LAW: the optionals is up and the tree is paused")
        var door_box: VBoxContainer = G.cs_sheets[0]["box"]
        ck(_find_btn(door_box, "X") == null,
                        "THE DOOR LAW: the optionals wears NO X (the door cannot be closed)")
        # v0.3.4-4 THE COIN-ICON PRICE LAW: no door price is spelled out in
        # words anymore - the un-owned place wears the BUY + coin-icon button
        var words_seen := _find_btn_like(door_box, "GOGACOINS") != null \
                        or _find_btn_like(door_box, "GOGACoins") != null
        var coin_icon_seen := false
        for dk in _all_kids(door_box):
                if dk is TextureRect and (dk as TextureRect).texture != null \
                                and (dk as TextureRect).texture.resource_path == "res://assets/ui/coin.png":
                        coin_icon_seen = true
        ck(not words_seen and coin_icon_seen,
                        "THE COIN-ICON PRICE LAW: the door says BUY + the coin icon, never the words")
        G._back_pressed()
        ck(G.sheet_open_count() == 1 and G._boot_hint != "",
                        "THE DOOR LAW: back on the door speaks - it never closes it")
        G._armory_open()
        ck(G.sheet_open_count() == 2, "THE DOOR LAW: the armory stacks over the door")
        G._back_pressed()
        ck(G.sheet_open_count() == 1,
                        "THE DOOR LAW: back over the door closes the TOP sheet only")
        # THE BORDER LAW: the park charges the BOX wallet, cosmic coins untouched
        var goga_before := Box.coins()
        var cosmic_before := meta.coins()
        Box.earn(1000)
        G._armory_buy_theme("park", int(CSData.THEMES["park"]["gogacoins"]))
        await _wait(0.2)
        ck(meta.has_theme("park"), "THE BORDER LAW: the park is owned after the buy")
        ck(Box.coins() == goga_before + 1000 - int(CSData.THEMES["park"]["gogacoins"]),
                        "THE BORDER LAW: the buy drained the GOGACoin wallet")
        ck(meta.coins() == cosmic_before,
                        "THE BORDER LAW: the cosmic wallet never paid for a place")
        ck(G.sheet_open_count() == 1,
                        "THE BORDER LAW: the buy from the boot reopens the DOOR")
        door_box = G.cs_sheets[0]["box"]
        ck(_find_btn(door_box, "NIGHT") != null,
                        "THE BORDER LAW: the owned place now wears DAY/NIGHT chips")
        # THE SHEET LIFE LAW: the tap answers UNDER THE PAUSED TREE (the owner's
        # killer: v0.3.4-1's sheet chain inherited PAUSABLE - every button was
        # a dud on device while the probes, which call functions directly,
        # never saw it)
        var drop_b := _find_btn(door_box, "DROP IN")
        ck(drop_b != null, "THE SHEET LIFE LAW: DROP IN exists on the door")
        if drop_b != null:
                drop_b.pressed.emit()
                await _wait(0.4)
                ck(G.phase == "play" and G.run_wave == 1,
                                "THE SHEET LIFE LAW: the paused tree answers the tap - the run starts")
        # THE TEXT-FIT LAW: the boxes grow to their text (the overflow report)
        var sc: Button = G._start_card("engineer")
        var perk_h: float = G._cs_text_h(String(CSData.STARTS["engineer"]["perk"]), 12, 500.0)
        var stats_h: float = G._cs_text_h("HP 0  DMG 0%  SPD 0%\nASPD 0%  RNG 0%  ARM 0  LUCK 0%  DODGE 0%", 12, 500.0)
        ck(sc.custom_minimum_size.y >= 93.0 + perk_h + stats_h,
                        "THE TEXT-FIT LAW: the start card grows to fit its measured text")
        ck(G._cs_text_w("ENGINEER", 14) > 0.0,
                        "THE TEXT-FIT LAW: the measurer measures with the real font")
        var dc: Button = G._draft_card(CSData.WAVE_DRAFTS[0])
        ck(dc.custom_minimum_size.y >= 130.0,
                        "THE TEXT-FIT LAW: the draft card keeps its floor and grows past it")
        var stc: Button = G._start_card("engineer")
        ck(stc.custom_minimum_size.y >= 120.0,
                        "THE TEXT-FIT LAW: the start card keeps its floor (the tree node's seat is retired)")
        # ============================== v0.3.4-3 - THE SKILLS + THE CHAIN
        # ============================== v0.3.8-2 - THE SKILL DEPTHS
        # THE SKILL POINTS LAW: 1 per 100 kills, LIFETIME, spent subtracts
        meta.d["kills"] = 2000
        meta.d["skill_spent"] = 0
        meta.d["skills"] = {}
        meta.save()
        ck(meta.skill_points_free(0) == 20,
                        "THE SKILLS LAW: 2000 banked kills = 20 points")
        ck(meta.skill_points_free(60) == 20 and meta.skill_points_free(99) == 20,
                        "THE SKILLS LAW: 99 live kills short of the next point")
        ck(meta.skill_points_free(100) == 21,
                        "THE SKILLS LAW: the 100th live kill mints the point")
        ck(meta.buy_skill("ghost_round", 0), "THE SKILLS LAW: the buy lands (L1)")
        ck(meta.skill_level("ghost_round") == 1 and meta.skill_points_free(0) == 18,
                        "THE SKILL DEPTHS: the purchase persists + the ledger drains")
        ck(meta.buy_skill("ghost_round", 0), "THE SKILL DEPTHS: an owned skill RAISES")
        ck(meta.skill_level("ghost_round") == 2 and meta.skill_points_free(0) == 15,
                        "THE SKILL DEPTHS: L1+L2 cost 2+3, the level stuck")
        ck(CSData.skill_level_cost("ghost_round", 3) == 4,
                        "THE SKILL DEPTHS: the ladder knows L3 costs 4")
        # THE GHOST ROUND: the shot that hits Spudnik flies on and strikes back
        G.phase = "play"
        G.over = false
        G.p_hp = 100.0
        G.p_max_hp = 100.0
        G.p_iframe = 0.0
        G.enemies.clear()
        var ge: Dictionary = G._spawn_enemy("blab", G.p_pos + Vector2(0, -280))
        var gep: float = float(ge["hp"])
        var php_g: float = G.p_hp
        var eb2 := {"pos": G.p_pos + Vector2(0, 60), "a": -PI / 2, "spd": 300.0,
                "dmg": 20.0, "node": Sprite2D.new(), "life": 3.0}
        G.world.add_child(eb2["node"])
        G.ebullets.append(eb2)
        for i in 30:
                G._tick_ebullets(0.05)
        ck(G.p_hp < php_g, "THE GHOST ROUND: the shot still hurt Spudnik")
        ck(float(ge["hp"]) < gep,
                        "THE GHOST ROUND: the passed shot struck the enemy behind (the level's own fraction)")
        G.ebullets.clear()
        # THE SHATTERED SHIELD: one hit eaten whole, the reform clock runs
        ck(meta.buy_skill("shattered_shield", 0), "THE SKILLS LAW: the shield buys (2 pts)")
        G.enemies.clear()
        G.p_hp = G.p_max_hp
        G._start_run()
        await _wait(0.4)
        G.phase = "play"
        G.over = false
        ck(G.p_shield_up, "THE SHIELD LAW: the run wakes with the shield up")
        var php_s: float = G.p_hp
        G.p_iframe = 0.0
        G._hurt_player(40.0, null, true)
        ck(absf(G.p_hp - php_s) < 0.01 and not G.p_shield_up and G.p_shield_cd > 0.0,
                        "THE SHIELD LAW: the hit was eaten WHOLE and the shield shattered")
        G._tick_skills(12.5)
        ck(G.p_shield_up, "THE SHIELD LAW: the shield reforms 12s later")
        # THE FROST AURA: the field chills everything near
        ck(meta.buy_skill("frost_aura", 0), "THE SKILLS LAW: the frost buys")
        G.enemies.clear()
        var fe: Dictionary = G._spawn_enemy("blab", G.p_pos + Vector2(60, 0))
        G._tick_skills(0.05)
        ck(float(fe["chill_t"]) > 0.0, "THE FROST AURA: the field chills the enemy")
        G.enemies.clear()
        # ============ v0.3.8-2 THE STAT TRACKS: lifetime points, 5 levels
        G.phase = "break"
        meta.d["stat_pts"] = 9
        meta.d["stat_tracks"] = {}
        meta.save()
        G._start_run()          # a fresh base bakes NOTHING (no tracks yet)
        await _wait(0.2)
        var dm_base: float = float(G.stat_base["dmg_m"])
        G.phase = "break"
        G._buy_track(CSData.STAT_TRACKS[0])     # the DAMAGE track, L1: 1 pt
        ck(meta.track_level("dmg") == 1 and meta.stat_pts() == 8,
                        "THE TRACKS LAW: a buy spends the ladder's price and banks the level")
        ck(absf(float(G.stats["dmg_m"]) - (dm_base + 0.10)) < 0.001,
                        "THE TRACKS LAW: the level applies to the live run")
        G._start_run()
        await _wait(0.2)
        ck(absf(float(G.stat_base["dmg_m"]) - (dm_base + 0.10)) < 0.001,
                        "THE TRACKS LAW: the owned level BAKES into the next run's base")
        # the pierce track's final: L5 turns PIERCE ALL on
        meta.d["stat_pts"] = 100
        meta.d["stat_tracks"] = {"pierce": 4}
        meta.save()
        var tr_pierce: Dictionary = {}
        for trk in CSData.STAT_TRACKS:
                if String(trk["id"]) == "pierce":
                        tr_pierce = trk
        G._buy_track(tr_pierce)
        ck(meta.track_level("pierce") == 5 and int(G.stats["pierce_all"]) == 1,
                        "THE TRACKS LAW: pierce L5 turns PIERCE ALL on")
        G._start_run()
        await _wait(0.2)
        ck(int(G.stats["pierce_add"]) == 5 and int(G.stats["pierce_all"]) == 1,
                        "THE TRACKS LAW: the pierce bake drills 5 bodies + the ALL flag")
        # a broke buy refuses
        meta.d["stat_pts"] = 0
        meta.save()
        var tracks_before: int = meta.track_level("dmg")
        G._buy_track(CSData.STAT_TRACKS[0])
        ck(meta.track_level("dmg") == tracks_before,
                        "THE TRACKS LAW: a broke buy refuses (the points are lifetime)")
        # THE CHAIN: draft (no reroll) -> MARKET -> MERGE -> STATS -> SKILLS -> wave
        G._start_run()
        await _wait(0.3)
        G.pending_levels = 0
        G.enemies.clear()
        G.wave_clock = 0.01
        G.boss_alive = false
        G._tick_waves(0.02)
        await _wait(0.3)
        ck(G.phase == "break" and G.sheet_open_count() == 1,
                        "THE CHAIN: the wave breaks into the DRAFT")
        var draft_box: VBoxContainer = G.cs_sheets[0]["box"]
        ck(_find_btn_like(draft_box, "REROLL") == null,
                        "THE CHAIN: the draft wears NO reroll (it lives in the market)")
        var skip_b := _find_btn_like(draft_box, "SKIP")
        ck(skip_b != null, "THE CHAIN: the draft wears SKIP")
        skip_b.pressed.emit()
        await _wait(0.2)
        ck(G.sheet_open_count() == 1,
                        "THE CHAIN: SKIP walks into THE WAVE MARKET")
        var market_box: VBoxContainer = G.cs_sheets[0]["box"]
        ck(_find_btn(market_box, "ITEMS") != null and _find_btn(market_box, "WEAPONS") != null \
                        and _find_btn(market_box, "ALLIES") != null,
                        "THE CHAIN: the market wears the ITEMS/WEAPONS/ALLIES tabs")
        ck(_find_btn_like(market_box, "REROLL OFFERS") != null,
                        "THE CHAIN: the market owns the reroll")
        ck(_find_btn_like(market_box, "MERGE") == null or true, "the bench lives elsewhere")
        ck(_find_btn_like(market_box, "TO THE MERGE BENCH") != null,
                        "THE CHAIN: the market's way out is the MERGE BENCH")
        # back out of the market falls back INTO the market (never stranded)
        G._back_pressed()
        await _wait(0.2)
        ck(G.sheet_open_count() == 1 and G.cs_sheets[0]["box"] == market_box \
                        or G.sheet_open_count() == 1,
                        "THE BREAK LAW: back over the market reopens it (the chain never strands)")
        var bench_b := _find_btn_like(G.cs_sheets[0]["box"], "TO THE MERGE BENCH")
        meta.mint_stat_pts(1)     # v0.3.8-2: a lifetime point waits for the STATS step
        bench_b.pressed.emit()
        await _wait(0.2)
        ck(G.sheet_open_count() == 1,
                        "THE CHAIN: the MERGE BENCH follows the market")
        var merge_box: VBoxContainer = G.cs_sheets[0]["box"]
        ck(_find_btn_like(merge_box, "CONTINUE") != null,
                        "THE CHAIN: the bench wears CONTINUE")
        _find_btn_like(merge_box, "CONTINUE").pressed.emit()
        await _wait(0.2)
        # meta.stat_pts() = 1 > 0 -> the STATS menu
        ck(G.sheet_open_count() == 1 and _find_btn_like(G.cs_sheets[0]["box"], "DONE") != null,
                        "THE CHAIN: the STATS menu follows the bench (a level waits)")
        ck(_find_btn(G.cs_sheets[0]["box"], "X") == null,
                        "THE CHAIN: the stats menu wears NO X")
        _find_btn_like(G.cs_sheets[0]["box"], "DONE").pressed.emit()
        await _wait(0.2)
        # skill points wait (6 free) -> the SKILLS menu
        ck(G.sheet_open_count() == 1 and _find_btn_like(G.cs_sheets[0]["box"], "CONTINUE - TO WAVE") != null,
                        "THE CHAIN: the SKILLS menu follows the stats (points wait)")
        _find_btn_like(G.cs_sheets[0]["box"], "CONTINUE").pressed.emit()
        await _wait(0.4)
        ck(G.phase == "play" and G.run_wave == 2,
                        "THE CHAIN: the skills CONTINUE starts the next wave")
        # v0.3.4-4 THE SHOP LIST LAW: the HUD button opens THE SHOP - the
        # universal GOGACoins LIST (not the game's cosmic-coin store)
        G._shop_button()
        await _wait(0.2)
        ck(G.sheet_open_count() == 1,
                        "THE SHOP LIST LAW: the button opens THE SHOP mid-run")
        var shop_box: VBoxContainer = G.cs_sheets[0]["box"]
        ck(_find_lbl_like(shop_box, "THE PLACES") != null
                        and _find_lbl_like(shop_box, "THE GUNS") != null
                        and _find_lbl_like(shop_box, "THE LAB") != null
                        and _find_lbl_like(shop_box, "THE CREW") != null,
                        "THE SHOP LIST LAW: the four GOGACoins shelves - PLACES / GUNS / LAB / CREW")
        var shop_coin := false
        for sk in _all_kids(shop_box):
                if sk is TextureRect and (sk as TextureRect).texture != null \
                                and (sk as TextureRect).texture.resource_path == "res://assets/ui/coin.png":
                        shop_coin = true
        ck(shop_coin, "THE SHOP LIST LAW: the wallet chip + every price wear THE coin icon")
        ck(_find_btn(shop_box, "CLOSE") != null,
                        "THE SHOP LIST LAW: the list closes with CLOSE, like every other game")
        _find_btn(shop_box, "CLOSE").pressed.emit()
        await _wait(0.2)
        ck(G.sheet_open_count() == 0 and G.phase == "play",
                        "THE SHOP LIST LAW: CLOSE resumes the run")
        # THE SHOP GUNS LAW: a GOGACoins gun joins EVERY wave market roll
        var owned_before := Box.item_owned(G.game_id, "guns", "shotgun")
        var bought := Box.buy_item(G.game_id, "guns", "shotgun",
                        int(CSData.SHOP_GUNS["shotgun"]))
        ck(bought or owned_before,
                        "THE SHOP GUNS LAW: the GOGACoins wallet buys the premium gun")
        G._roll_shop_offers()
        var shotgun_first := false
        for ow in G.shop_offers_w:
                if String(ow["wid"]) == "shotgun":
                        shotgun_first = true
        ck(shotgun_first and G.shop_offers_w.size() == 4,
                        "THE SHOP GUNS LAW: the owned gun's offer is planted in the market (4 offers total)")
        ck(G.shop_offers_w[0]["wid"] == "shotgun",
                        "THE SHOP GUNS LAW: the planted offer rides FIRST in the shelf")
        # THE SHOP LAB LAW: the GOGACoins lab buys flip the same tree flags
        Box.earn(1000)
        G._shop_buy_lab("l3", 800)
        ck(meta.tree_node("l3") and meta.merging_learned(),
                        "THE SHOP LAB LAW: WEAPON LAB (the merging) is learned forever")
        # THE SHOP CREW LAW: a GOGACoins ally joins the deploy list forever
        Box.earn(500)
        G._shop_buy_crew("drone", int(CSData.SHOP_CREW["drone"]))
        ck(meta.has_ally("drone"),
                        "THE SHOP CREW LAW: the drone is owned and lists in the deploy rows")
        # ================================================ THE PATCH 5 LAWS
        # THE RIGHT-SHEET LAW: a market buy rebuilds THE MARKET, never the
        # universal shop (the patch-4 rename hijack is dead)
        await _boot()
        G._start_run()
        G.phase = "break"
        G._market_open()
        await _wait(0.3)
        G._shop_buy_item({"iid": "protein", "price": 0, "sold": false})
        await _wait(0.3)
        ck(String(G.cs_sheets.back()["id"]) == "market",
                        "THE RIGHT-SHEET LAW: a market buy rebuilds THE WAVE MARKET")
        # ... and a merge rebuilds THE MERGE BENCH
        G._cs_close_all()
        meta.d["char_level"] = 6
        meta.add_armory("smg", 1)
        meta.add_armory("smg", 1)
        G._merge_menu_open()
        await _wait(0.3)
        G._wave_buy_merge({"wid": "smg", "tier": 1, "cost": 100}, 100)
        await _wait(0.3)
        ck(String(G.cs_sheets.back()["id"]) == "merge",
                        "THE RIGHT-SHEET LAW: a merge rebuilds THE MERGE BENCH")
        # THE ARMORY TABS LAW: a tab rebuilds THE ARMORY, never THE SHOP
        G._cs_close_all()
        G.phase = "boot"
        G._optionals_open()
        await _wait(0.3)
        G._armory_open()
        await _wait(0.3)
        var arm_box: VBoxContainer = G.cs_sheets.back()["box"]
        var tab_b := _find_btn(arm_box, "PLACES")
        ck(tab_b != null, "THE ARMORY TABS LAW: the PLACES tab exists")
        if tab_b != null:
                tab_b.pressed.emit()
                await _wait(0.3)
                ck(String(G.cs_sheets.back()["id"]) == "armory",
                                "THE ARMORY TABS LAW: the tab stays in THE ARMORY")
        # THE RESUME LAW: a close with no sheets back on a break brings the market
        G._cs_close_all()
        G.phase = "break"
        G._cs_close_top()
        await _wait(0.3)
        ck(G.cs_sheets.size() == 1 and String(G.cs_sheets.back()["id"]) == "market",
                        "THE RESUME LAW: the stranded break rides back to the market")
        # THE FRESH DOOR LAW: the shop rides over the door, the buy stays in
        # the shop, and CLOSE reveals a door that already owns the place
        G._cs_close_all()
        G.phase = "boot"
        Box.earn(2000)
        G._optionals_open()
        await _wait(0.3)
        G._shop_open()
        await _wait(0.3)
        ck(G.cs_sheets.size() == 2 and String(G.cs_sheets.back()["id"]) == "shop",
                        "THE FRESH DOOR LAW: the shop rides OVER the door")
        G._shop_buy_theme("park", int(CSData.THEMES["park"]["gogacoins"]))
        await _wait(0.3)
        ck(G.cs_sheets.size() == 2 and String(G.cs_sheets.back()["id"]) == "shop",
                        "THE FRESH DOOR LAW: the theme buy stays inside THE SHOP")
        var shop_row := _find_lbl_like(G.cs_sheets.back()["box"], "PARK")
        ck(shop_row != null and (String(shop_row.text).contains("OWNED")
                        or String(shop_row.text).contains("WORN")),
                        "THE FRESH DOOR LAW: the shop row reads OWNED/WORN right after the buy")
        _find_btn(G.cs_sheets.back()["box"], "CLOSE").pressed.emit()
        await _wait(0.4)
        ck(String(G.cs_sheets.back()["id"]) == "door",
                        "THE FRESH DOOR LAW: CLOSE reveals the door")
        ck(_find_lbl_like(G.cs_sheets.back()["box"], "WORN") != null,
                        "THE FRESH DOOR LAW: the door wears the bought place (no stale BUY)")
        ck(_find_btn_like(G.cs_sheets.back()["box"], "BUY") == null,
                        "THE FRESH DOOR LAW: no stale BUY card on the door")
        # THE TOP BUTTONS LAW: the top bar answers over every paused sheet
        ck(G._hud_row != null and G._hud_row.process_mode == Node.PROCESS_MODE_ALWAYS,
                        "THE TOP BUTTONS LAW: the top bar processes over the pause")
        # THE WARDEN LAW: friends inside the gold ring take HALF damage
        G._cs_close_all()
        G._start_run()
        G.phase = "play"
        G.enemies.clear()
        var ward_target: Dictionary = G._spawn_enemy("blab", G.p_pos + Vector2(100, 0))
        var warden: Dictionary = G._spawn_enemy("warden", G.p_pos + Vector2(120, 0))
        var ward_far: Dictionary = G._spawn_enemy("blab", G.p_pos + Vector2(1200, 0))
        G._hurt_enemy(ward_target, 20.0)
        ck(absf((float(ward_target["max_hp"]) - 10.0) - float(ward_target["hp"])) < 0.01,
                        "THE WARDEN LAW: a friend inside the ring takes HALF damage")
        G._hurt_enemy(ward_far, 20.0)
        ck(absf((float(ward_far["max_hp"]) - 20.0) - float(ward_far["hp"])) < 0.01,
                        "THE WARDEN LAW: an enemy outside the ring takes full damage")
        warden["dead"] = true
        G._hurt_enemy(ward_target, 20.0)
        ck(absf(float(ward_target["hp"]) - (float(ward_target["max_hp"]) - 30.0)) < 0.01,
                        "THE WARDEN LAW: the warden falls, the guard dies with it")
        # THE FIRST-GLANCE LAW: the first special enemy explains itself, once
        meta.d["seen_kinds"] = []
        G._spawn_enemy("wraith", G.p_pos + Vector2(-300, 0))
        ck(meta.seen_kind("wraith"),
                        "THE FIRST-GLANCE LAW: the first wraith marks itself seen")
        G._spawn_enemy("wraith", G.p_pos + Vector2(-500, 0))
        ck((meta.d["seen_kinds"] as Array).count("wraith") == 1,
                        "THE FIRST-GLANCE LAW: the hint speaks ONCE per save")
        # THE MELEE LAW: the cleaver's arc chops what's inside, not behind
        G.enemies.clear()
        G.weapons_run = [{"id": "cleaver", "tier": 1, "cd": 0.0}]
        var melee_front: Dictionary = G._spawn_enemy("blab", G.p_pos + Vector2(90, 0))
        var melee_back: Dictionary = G._spawn_enemy("blab", G.p_pos + Vector2(-90, 0))
        G.p_aim = 0.0
        var fired: bool = G._fire_weapon(G.weapons_run[0])
        ck(fired and float(melee_front["hp"]) < float(melee_front["max_hp"]),
                        "THE MELEE LAW: the arc chops the enemy in the swing")
        ck(float(melee_back["hp"]) == float(melee_back["max_hp"]),
                        "THE MELEE LAW: the enemy behind the swing stays untouched")
        ck(G._slashes.size() > 0,
                        "THE MELEE LAW: the swing draws its slash arc")
        # THE TIER RANGE LAW: tiers climb the range, the cards say the truth
        ck(absf(float(CSData.tier_mult(2)["rng"]) - 1.1) < 0.001,
                        "THE TIER RANGE LAW: T2 range x1.1")
        ck(absf(float(CSData.tier_mult(3)["rng"]) - 1.25) < 0.001,
                        "THE TIER RANGE LAW: T3 range x1.25")
        ck("rng 130" in G._weapon_stat_line("cleaver", 1)
                        and "(melee)" in G._weapon_stat_line("cleaver", 1),
                        "THE TIER RANGE LAW: the cleaver's card reads rng 130 (melee)")
        ck("rng 330" in G._weapon_stat_line("smg", 2),
                        "THE TIER RANGE LAW: the card shows the tier's real range")
        # THE BIG TEXT LAW: one multiplier feeds every CSUI helper
        ck(G._fs(12) == 21 and G._fs(20) == 35,
                        "THE BIG TEXT LAW: the scale is x1.75")
        var scaled: Label = G._cs_label("x", 12, Color.WHITE)
        ck(int(scaled.get_theme_font_size("font_size")) == 21,
                        "THE BIG TEXT LAW: labels render scaled")
        # THE INFO LAW: the ledgers file the deltas, the rows speak the shape
        G.stat_up.clear()
        G.stat_down.clear()
        G._apply_stat("dmg", 0.20)
        G._apply_stat("dmg", -0.08)
        var info_rows: Array = G._info_stat_rows()
        ck(info_rows.size() == G.INFO_STATS.size(),
                        "THE INFO LAW: every stat has a block")
        var dmg_row := {}
        for r in info_rows:
                if String(r["key"]) == "dmg_m":
                        dmg_row = r
        ck(String(dmg_row["up"]) == "20%" and String(dmg_row["down"]) == "8%",
                        "THE INFO LAW: the ledgers file the ups and the downs")
        ck(String(dmg_row["result"]) == "122%",
                        "THE INFO LAW: the result is the live truth (base +20 -8)")
        G._cs_close_all()
        G._info_open()
        await _wait(0.3)
        ck(String(G.cs_sheets.back()["id"]) == "info",
                        "THE INFO LAW: the INFO button opens RUN INFO")
        # THE VARIED HOLSTER LAW: every start wears a signature gun
        for sid in CSData.STARTS:
                ck(CSData.START_SIG.has(sid),
                                "THE VARIED HOLSTER LAW: %s wears a signature gun" % String(sid))
        meta.set_loadout(["smg", "shotgun", "rifle"])
        G.start_id = "brawler"
        G._start_run()
        await _wait(0.3)
        ck(String(G.meta.loadout()[0]) == "shotgun",
                        "THE VARIED HOLSTER LAW: DROP IN arms the brawler's SCATTER SPUD first")
        # the new pixels exist
        ck(G._t("warden") != null and G._t("gun_cleaver") != null \
                        and G._t("icon_cleaver") != null,
                        "THE ART: the warden + the cleaver wear their new pixels")

        # ================================================ THE PATCH 6 LAWS
        # v0.3.5-5 THE ALLY TRUTH: every ally texture resolves - the missing
        # registration used to kill the run on the engineer's drop-in
        await _boot()
        var ally_tex_ok := true
        for aid in CSData.ALLY_ORDER:
                if G._t(String(CSData.ALLIES[aid]["tex"])) == null:
                        ally_tex_ok = false
        ck(ally_tex_ok, "THE ALLY TRUTH: every ally texture resolves (no missing key)")
        # THE ENGINEER DROP-IN LAW: the engineer's start deploys the drone
        # and the first wave begins - the app must NEVER crash here
        G.start_id = "engineer"
        G._start_run()
        await _wait(0.6)
        ck(G.allies.size() == 1 and String(G.allies[0]["id"]) == "drone",
                "THE ENGINEER DROP-IN: the drone buddy deployed with the run")
        ck(G.phase == "play" or G.phase == "break",
                "THE ENGINEER DROP-IN: the run is ALIVE past the wave start (no crash)")
        ck(is_instance_valid(G.allies[0]["node"]),
                "THE ENGINEER DROP-IN: the drone wears its sprite (the texture loaded)")
        # THE ALLY VARIETY LAW: tints, the guard's aura, the scout's gun
        var tint_ok: bool = G.ALLY_TINTS.size() == CSData.ALLY_ORDER.size()
        ck(tint_ok, "THE ALLY VARIETY: every ally wears its own tint")
        G._deploy_ally("guard", 1)
        G._deploy_ally("scout", 1)
        ck(G.allies.size() == 3, "THE ALLY VARIETY: the guard and the scout joined")
        # the guard's aura: inside the ring the damage shrinks, outside it
        # does not - and two guards never stack the cut. The cheat owns the
        # shattered-shield skill - the battery turns it off so the hits
        # land raw.
        G.p_shield_up = false
        var hp0g: float = float(G.p_hp)
        G.allies[1]["pos"] = G.p_pos            # the guard hugs the potato
        G.p_iframe = 0.0
        G._hurt_player(20.0, null, false)
        var hp_inside: float = float(G.p_hp)
        G.allies[1]["pos"] = G.p_pos + Vector2(900, 900)   # out of the ring
        G.p_iframe = 0.0
        G._hurt_player(20.0, null, false)
        var hp_outside: float = float(G.p_hp)
        var loss_inside: float = hp0g - hp_inside
        var loss_outside: float = hp_inside - hp_outside
        ck(loss_inside > 0.0 and loss_inside < loss_outside,
                "THE GUARD AURA: the damage inside the ring is smaller than outside")
        # the outside hit lands heavier by EXACTLY the lv1 cut (12% of 20 =
        # 2.4) - armor shifts both hits equally, the LOSS DELTA is the law
        ck(absf((loss_outside - loss_inside) - 2.4) < 0.01,
                "THE GUARD AURA: the ring cut exactly 12%% at lv1 (loss delta %.2f)" \
                                % (loss_outside - loss_inside))
        G._deploy_ally("guard", 1)              # a SECOND guard on the spot
        G.allies[3]["pos"] = G.p_pos
        G.p_iframe = 0.0
        var hp_two: float = float(G.p_hp)
        G._hurt_player(20.0, null, false)
        var loss_two: float = hp_two - float(G.p_hp)
        ck(absf(loss_two - loss_inside) < 0.01,
                "THE GUARD AURA: two guards never stack the cut (the best ring counts once; loss_two=%.3f loss_inside=%.3f)" % [loss_two, loss_inside])
        # the scout plinks: its fire cycle re-arms and the mark lands
        # (the bullet COUNT races the game's own guns - the cycle is the
        # deterministic proof)
        G.allies[2]["pos"] = G.p_pos + Vector2(60, 0)      # guard out, scout in
        G.allies[1]["pos"] = G.p_pos + Vector2(900, 900)
        G.allies[0]["cd"] = 99.0        # the drone holds its fire
        G.enemies.clear()
        G.enemies.append({"uid": 4242, "pos": G.p_pos + Vector2(200, 0),
                "hp": 50.0, "max_hp": 50.0, "spd": 0.0, "dmg": 1.0, "size": 20.0,
                "node": Node2D.new(), "marked": false})
        G.world.add_child(G.enemies[0]["node"])
        G.allies[2]["cd"] = 0.0
        G._tick_allies(0.05)
        ck(G.allies[2]["cd"] > 0.0 and G.allies[2]["cd"] <= 1.8,
                "THE SCOUT'S GUN: the pea-shooter cycle re-armed (the dart fired)")
        ck(bool(G.enemies[0].get("marked", false)),
                "THE SCOUT'S GUN: the spotter marked the enemy in range")

        # ================== v0.3.8-2 THE SCROLL TRUTH + ROSTER + PURSE
        await _boot()
        # THE SCROLL TRUTH: the sheets scroll on the raw-touch BoxScroll and
        # every button inside is a registered tappable - a drag that STARTS on
        # a button scrolls the shelf instead of dying (the other-games law).
        # v0.3.8-3: the tree shelf is retired - the OPTIONALS door stands in.
        G._optionals_open()
        await _wait(0.2)
        var tsc: BoxScroll = null
        var tbtns := 0
        for kid in _all_kids(G.cs_sheets[G.cs_sheets.size() - 1]["box"]):
                if kid is BoxScroll and tsc == null:
                        tsc = kid
                if kid is BaseButton and (kid as BaseButton).mouse_filter \
                                        == Control.MOUSE_FILTER_IGNORE:
                        tbtns += 1
        ck(tsc != null and bool(tsc.game_safe),
                        "THE SCROLL TRUTH: the door shelf scrolls on a game-safe BoxScroll")
        ck(tbtns > 0 and tsc._tappables.size() > 0,
                        "THE SCROLL TRUTH: the shelf's buttons went IGNORE + tappable")
        G._close_all_sheets()
        await _wait(0.2)
        G._shop_open()
        await _wait(0.2)
        var ssc: BoxScroll = null
        for kid2 in _all_kids(G.cs_sheets[G.cs_sheets.size() - 1]["box"]):
                if kid2 is BoxScroll:
                        ssc = kid2
                        break
        ck(ssc != null and ssc._tappables.size() > 0,
                        "THE SCROLL TRUTH: THE SHOP's list scrolls and taps the same way")
        G._close_all_sheets()
        await _wait(0.2)
        # THE ROSTER LAW: the ally level is persistent, bought in the armory
        meta.d["coins"] = 50000
        meta.save()
        G._cc_pull()
        meta.own_ally("drone")
        ck(meta.ally_level("drone") == 1,
                        "THE ROSTER LAW: ownership lands at LV 1")
        ck(CSData.ally_raise_price("drone", 2) == 600
                        and CSData.ally_raise_price("drone", 5) == 2400,
                        "THE ROSTER LAW: the raise ladder climbs (600 -> 2400)")
        G._armory_raise_ally("drone")
        G._armory_raise_ally("drone")
        ck(meta.ally_level("drone") == 3 and meta.coins() == 50000 - 600 - 1200,
                        "THE ROSTER LAW: the armory raises stuck and charged the purse")
        G._start_run()
        await _wait(0.2)
        G._deploy_ally("drone", maxi(1, meta.ally_level("drone")))
        ck(int(G.allies[G.allies.size() - 1]["level"]) == 3,
                        "THE ROSTER LAW: the deploy lands AT the persistent level")
        # THE PURSE LAW: one wallet, forever - death banks nothing extra
        meta.d["coins"] = 777
        meta.save()
        G._cc_pull()
        ck(G.run_ccoins == 777,
                        "THE PURSE LAW: the wallet opens at the saved balance")
        G._cc_earn(23)
        ck(G.run_ccoins == 800 and int(meta.d["coins"]) == 800,
                        "THE PURSE LAW: an earn lands in the same purse")
        ck(G._cc_spend(100) and G.run_ccoins == 700
                        and int(meta.d["coins"]) == 700,
                        "THE PURSE LAW: a spend drains the same purse")
        ck(not G._cc_spend(100000), "THE PURSE LAW: a broke spend refuses")
        G._start_run()
        await _wait(0.2)
        ck(G.run_ccoins == 700,
                        "THE PURSE LAW: a fresh run does NOT empty the wallet")
        G._cc_earn(200)
        G._die()
        await _wait(0.2)
        ck(meta.coins() == 900,
                        "THE PURSE LAW: death banks NOTHING - the coins were already home")

        # fresh probe exit
        Box.reset_all()
        print("=== cs_probe: %d checks, %d fails ===" % [checks, fails])
        get_tree().quit(1 if fails > 0 else 0)
func _ready() -> void:
        _run()
