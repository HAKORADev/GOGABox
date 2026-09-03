extends Node
## invaders_probe - v0.3.2 PATCH IV: drives Space Invaders headless. The
## owner's playtest-round laws, newest first:
##   PATCH IV - THE STEERING LAW (the protector steers its BODY like the
##   defenders; the aimed fire rides the steered nose),
##   THE DEFENDER WEAPON LAW (a rented ship wields its REAL held weapon at
##   level 3 - orb volleys, beam pairs, igniting fire, free weaving snakes),
##   THE BOSS AWAKENING (the keeper was parked on "enter" FOREVER - it wakes
##   after the glide), THE WAR CLOCK (keepers fire between specials),
##   THE ACT LAW (the side roll / dust dash / spiral are scripted acts the
##   tick obeys - tweens the hover stomped are dead),
##   THE SLOT LAW (96px columns, capped weave - waves are structured like
##   chicken invaders, no overlaps, no off-screen bodies, the fly-in is a
##   staggered curved train from one side),
##   THE AIRDROP LAW (the game's OWN loot rhythm restored: coin 2-10 waves,
##   power 1-2 waves, weapon icons 5% at wave end; the power point wears
##   Space Dash's PILL; kills roll NOTHING),
##   PATCH III - THE SKIN FIRST LAW, THE UNFREEZE LAW, THE BUBBLE QUEUE LAW,
##   THE RELEASE LAW, THE ACCURACY LAW, THE WHITE ARC LAW, THE 22-ROW LAW,
##   THE PROGRESSION LAW, THE SHIELD LAW, THE BUTTON LAW,
##   + the whole v0.3.2 body: the tour, the ladder, the falloffs, the breach,
##   the escapes, the finale gauntlet, the defender, the themes pack.
##
##   godot --headless --path projects/gogabox res://tests/invaders_probe.tscn

var fails := 0

func _check(cond: bool, msg: String) -> void:
        print(("  PASS: " if cond else "  FAIL: ") + msg)
        if not cond:
                fails += 1

var G: GogaGame

func _frames(n: int) -> void:
        for i in n:
                await get_tree().process_frame

func _wait(sec: float) -> void:
        await get_tree().create_timer(sec).timeout

func _boot() -> void:
        G = load("res://game/games/invaders/invaders.gd").new()
        G.game_id = "invaders"
        add_child(G)
        await _frames(4)

func _start_run() -> void:
        G._show_ready_card()         # the optionals-first flow lands here
        await _frames(2)
        G._press(Vector2(200, 500), 0)
        await _frames(2)
        G._story_end()               # the opening story (scrollable, paused, START)
        await _wait(1.6)

func _mk(kind: String, at: Vector2) -> Dictionary:
        G._summon_kind(kind, at)
        var e: Dictionary = G.enemies[G.enemies.size() - 1]
        e["state"] = "hover"
        e["dive_cd"] = -1.0
        return e

func _story_btn() -> String:
        # the text of the story sheet's action button
        for n in G._story_pair:
                if n == null or not is_instance_valid(n):
                        continue
                for b in n.find_children("*", "Button", true, false):
                        return String((b as Button).text)
        return ""

func _run() -> void:
        Box.reset_all()
        print("== invaders_probe: the tour v0.3.2 PATCH III ==")

        # ---- registry sanity (the owner's economy) ----
        var sr: Dictionary = GameReg.get_game("invaders")
        _check(not sr.is_empty(), "invaders is in the registry")
        _check(String(sr["title"]) == "Space Invaders", "the rename law: HEN -> SPACE INVADERS")
        _check(int(sr["coin_div"]) == 500, "run bonus = score/500 (owner)")
        _check(String(sr["orientation"]) == "landscape", "the tour is HORIZONTAL")
        _check(GameReg.playable().size() == 9 and GameReg.workshop().size() == 6,
                        "9 playable / 6 teasers (hen graduated)")

        # ---- boot ----
        await _boot()
        _check(G.phase == "ready" and G._sheet_pair.size() > 0,
                        "THE FLOW LAW: the game OPENS on the optionals screen")
        _check(G._optional_box("ember") != null, "optionals builds IMAGE boxes (the snake standard)")
        _check(Jukebox._current_music.contains("inv_tour"), "the tour MUSIC is on from boot")
        _check(String(G.LINES["intro_story"]).contains("SPACE DASH")
                        and String(G.LINES["intro_story"]).contains("PROTECTOR")
                        and String(G.LINES["intro_story"]).contains("hideout"),
                        "the OPENING STORY carries the crafted lore (one universe, the tour, the hideout)")
        var facts_gone := true
        for s in G.STAGES:
                if s.has("line"):
                        facts_gone = false
        _check(facts_gone, "the Neptune FACTS are gone - the data lives in the sky palette only")
        var lanes_hulls := true
        for id in G.SHIPS:
                if not String(G.SHIPS[id]["tex"]).contains("games/lanes"):
                        lanes_hulls = false
        _check(lanes_hulls, "the crew hulls ARE the Space Dash PNGs (loaded from Lanes)")
        _check(G.hearts_lbl.text == "x 3", "the heart law: 'x nn' then the heart shape")
        _check(G.POWER_MAX == 6 and G.LVL_PTS.size() == 6,
                        "the ladder is SIX levels deep (the space dash depth)")
        _check(G.STAGES.size() == 10, "the tour has 10 stages")
        _check(String(G.STAGES[0]["name"]) == "NEPTUNE" and String(G.STAGES[8]["name"]) == "THE SUN"
                        and String(G.STAGES[9]["name"]) == "THE HIDEOUT",
                        "Neptune opens, the Sun is stage 9, the Hideout is stage 10")
        var score_ok := true
        for k in G.ETYPES:
                score_ok = score_ok and int(G.ETYPES[k]["score"]) >= 1 and int(G.ETYPES[k]["score"]) <= 3
        _check(score_ok, "every enemy pays +1/+2/+3 (owner)")

        # ---- THE 22-ROW LAW + the fixed scale ----
        _check(G.GRID_ROWS == 22, "the grid is 22 rows (the owner's layout)")
        var vp0 := G.get_viewport_rect().size
        _check(G._grid_row_y(1.0) > G.GRID_TOP, "grid row 0 stays EMPTY above the block")
        _check(G._grid_row_y(10.0) < G._grid_row_y(11.0), "the enemy zone ends inside row 10")
        _check(G._grid_row_y(21.0) < vp0.y - G._bottom_safe() + 60.0,
                        "row 21 = the protector's row (an empty row under it)")
        _check(is_equal_approx(float(G.ENEMY_SCALE), 0.62), "the FIXED scale law: 0.62 everywhere")

        # ---- THE SKIN FIRST LAW (the owner: "it shows the azure skin as the
        # default while letting the weapon the same as the perspective ship") --
        Box.earn(100000)
        Box.buy_skin("invaders", "ember", int(G.SHIPS["ember"]["price"]))
        Box.equip_skin("invaders", "ember")
        await _boot()
        _check(G.skin == "ember", "the optionals pick is read at boot")
        _check(String(G.ship.texture.resource_path).contains("ship_orange"),
                        "the flown hull IS the picked hull (ember orange, not azure)")
        _check(G.weapon == "beam", "the exclusive weapon rides with the hull")
        Box.reset_all()
        await _boot()

        # ---- start the run (THE PROTECTOR story first) ----
        await _start_run()
        _check(G.wave == 1, "wave 1 starts after the dialogues")
        _check(not G.enemies.is_empty(), "the formation flies in")
        # ---- THE FLY-IN LAW (PATCH IV: a staggered curved train, one side) ----
        var trains := true
        var side0 := 0.0
        for e in G.enemies:
                if not e.has("p0") or not e.has("in_d") or not e.has("ctl"):
                        trains = false
                else:
                        side0 = signf((e["p0"] as Vector2).x)
        _check(trains, "THE FLY-IN LAW: every body rides a staggered curved train")
        _check(side0 != 0.0, "the train enters from ONE side (alternating per wave)")
        # ---- THE SLOT LAW (structured like chicken invaders) ----
        var slots_line: Array = G._pattern_slots("line", 22)
        var overlap_free := true
        for a in slots_line.size():
                for b2 in range(a + 1, slots_line.size()):
                        var dx: float = absf((slots_line[a] as Vector2).x - (slots_line[b2] as Vector2).x)
                        var dy: float = absf((slots_line[a] as Vector2).y - (slots_line[b2] as Vector2).y)
                        if dx < 84.0 and dy < 48.0:
                                overlap_free = false
        _check(overlap_free, "THE SLOT LAW: no two slots of the book can ever overlap (96px pitch)")
        var slots_on := true
        for s in slots_line:
                if absf((s as Vector2).x) > G.get_viewport_rect().size.x * 0.5 - 100.0:
                        slots_on = false
        _check(slots_on, "every slot stays inside the playable sky (no off-screen bodies)")
        _check(G.PATTERNS.has("wings"), "the wings pattern joined the formation book")

        # ---- THE PROGRESSION LAW: wave 1 = the base body only ----
        var kinds := {}
        for e in G.enemies:
                kinds[String(e["kind"])] = true
        _check(kinds.size() == 1 and kinds.has("grunt"),
                        "stage 1 wave 1 flies ONLY the base body (progression is visible)")
        var pools_ordered := true
        for s in G.STAGES:
                var pool: Array = s["pool"]
                if pool.size() < 3:
                        pools_ordered = false
        _check(pools_ordered and String(G.STAGES[0]["pool"][3]) == "aimer",
                        "the first SHOOTER arrives in stage 1 wave 4 (the pools are unlock order)")
        _check(int(G.ETYPES["tank"].get("shield", 0)) == 4
                        and int(G.ETYPES["brute"].get("shield", 0)) == 6
                        and bool(G.ETYPES["brute"].get("big", false)),
                        "the type infra: shields + big bodies are DECLARED per family")

        # ---- the power ladder: the LEVEL is the damage ----
        _check(G.weapon_level() == 1, "every weapon starts at level 1 (= 1 damage)")
        G._apply_power("orb", 2)
        _check(G.weapon_level() == 2, "level 2 at 2 points")
        G._apply_power("orb", 3)
        _check(G.weapon_level() == 3, "level 3 at 5 points")
        G._apply_power("orb", 20)
        _check(G.weapon_level() == G.POWER_MAX, "the ladder caps at SIX")

        # ---- the crew + their exclusive weapons ----
        var crew_ok := true
        for pair in [["azure", "orb"], ["ember", "beam"], ["verdant", "snake"],
                        ["veteran", "arc"], ["phantom", "mg"], ["hornet", "fire"], ["titan", "missile"]]:
                crew_ok = crew_ok and String(G.SHIPS[pair[0]]["weapon"]) == pair[1]
        _check(crew_ok, "the seven crew each own their exclusive weapon")

        # ---- THE STEERING LAW (the owner: "the defenders still steering their
        # bodies while normal user ship can not do that") ----
        G.move_axis = 1.0
        G.ship_v.x = 900.0
        for i in 40:
                G.steer_scan = 0.0
                G._ship_tick(0.016)
        _check(absf(G.ship.rotation) > 0.2,
                        "THE STEERING LAW: the protector banks its BODY into the run (like the defenders)")
        _check(absf(G.ship.rotation) <= 0.56, "the steer is capped (the sky stays honest)")
        G.move_axis = 0.0
        G.ship_v.x = 0.0
        G.ship.rotation = 0.3
        G.wpower["orb"] = 1
        G.bolts.clear()
        G._fire_orb()
        _check(G.bolts.size() == 1 and absf((G.bolts[0]["vel"] as Vector2).angle() - (-PI / 2.0 + 0.3)) < 0.02,
                        "the aimed fire rides the STEERED NOSE (steering steers the fire)")
        G.ship.rotation = 0.0
        G.bolts.clear()

        # ---- the thunder rework: the beam UP + chain falloff (floor 1) ----
        G.weapon = "thunder"
        G.wpower["thunder"] = 1
        var vic := [_mk("grunt", Vector2(G.ship.position.x, G.ship.position.y - 200)),
                        _mk("grunt", Vector2(G.ship.position.x + 120, G.ship.position.y - 180)),
                        _mk("grunt", Vector2(G.ship.position.x + 260, G.ship.position.y - 160))]
        var hp_before: Array = []
        for v in vic:
                hp_before.append(int(v["hp"]))
        G.fire_cd = 0.0
        G._cast_thunder()
        _check(int(vic[0]["hp"]) == hp_before[0] - 3,
                        "the beam column hits for the base (2 + level)")
        _check(int(vic[1]["hp"]) == hp_before[1] - 2, "the first chain hop takes base - 1")
        _check(int(vic[2]["hp"]) == hp_before[2] - 1,
                        "the second hop takes base - 2 (6 -> 5 -> 4 ... the owner's law)")
        for v in vic:
                if is_instance_valid(v["node"]):
                        v["node"].queue_free()

        # ---- the bomb rework: contact fuse + ring falloff ----
        G.weapon = "bomb"
        G.wpower["bomb"] = 1
        var btarget := _mk("grunt", Vector2(G.ship.position.x + 100, G.ship.position.y - 320))
        var bside := _mk("grunt", Vector2(G.ship.position.x + 250, G.ship.position.y - 320))
        var hb: int = btarget["hp"]
        var hs: int = bside["hp"]
        G._bomb_blast(Vector2(G.ship.position.x + 100, G.ship.position.y - 320))
        _check(int(btarget["hp"]) == hb - 5, "bomb center = 3 + 2*level")
        _check(int(bside["hp"]) == hs - 3, "each 60px ring pays one less, floor 1")
        G._drop_bomb()
        var bb: Dictionary = G.bombs[0]
        bb["node"].position = Vector2(-9999, -9999)
        G._bombs_tick(0.016)
        _check(G.bombs.is_empty(), "a bomb that touches NOTHING just leaves (contact fuse law)")

        # ---- THE RELEASE LAW + THE ACCURACY LAW (verdant) ----
        G.weapon = "snake"
        G.wpower["snake"] = 2
        G.wpts["snake"] = 0
        var col_x: float = G.ship.position.x
        var s1 := _mk("grunt", Vector2(col_x, G.ship.position.y - 70))
        var s2 := _mk("grunt", Vector2(col_x, G.ship.position.y - 140))
        var s_far := _mk("grunt", Vector2(col_x + 70.0, G.ship.position.y - 105))
        var h1: int = s1["hp"]
        var h2: int = s2["hp"]
        var h_far: int = s_far["hp"]
        G._fire_snakes()
        G.firing = true
        for i in 34:
                for s in G.snakes:
                        s["t"] = 0.0          # pin the weave so the sweep stays on the column
                s1["node"].position = Vector2(col_x, G.ship.position.y - 70)
                s2["node"].position = Vector2(col_x, G.ship.position.y - 140)
                s_far["node"].position = Vector2(col_x + 70.0, G.ship.position.y - 105)
                G._snakes_tick(0.016)
        _check(int(s1["hp"]) <= h1 - 2 and int(s2["hp"]) <= h2 - 1,
                        "the snake pierces through bodies over time; the further body takes less")
        _check(int(s_far["hp"]) == h_far,
                        "THE ACCURACY LAW: a body 70px OFF the beam's real path is untouched")
        # the release: the beams finish the flight - they do NOT vanish
        G.firing = false
        G._snakes_tick(0.016)
        _check(not G.snakes.is_empty(),
                        "THE RELEASE LAW: letting go never deletes the beams mid-air")
        var orphan := true
        for s in G.snakes:
                orphan = orphan and bool(s.get("orphan", false))
        _check(orphan, "released snakes stop riding the weave and fly out ONE BY ONE")
        var exited := false
        for i in 260:
                G._snakes_tick(0.016)
                if G.snakes.is_empty():
                                exited = true
                                break
        if not exited:
                for s in G.snakes:
                        var nn: Sprite2D = s["node"]
                        print("  DEBUG snake: y=", nn.position.y, " orphan=", bool(s.get("orphan", false)),
                                        " tall=", s["tall"])
        _check(exited, "released snakes EXIT the sky when their flight ends")
        if is_instance_valid(s1["node"]):
                s1["node"].queue_free()
        if is_instance_valid(s2["node"]):
                s2["node"].queue_free()
        if is_instance_valid(s_far["node"]):
                s_far["node"].queue_free()

        # ---- THE WHITE ARC LAW (veteran) ----
        G.weapon = "arc"
        G.wpower["arc"] = 3
        G.arcs.clear()
        G._fire_arc()
        _check(G.arcs.size() == 1 and not G.arcs[0].has("node"),
                        "the sound arch is NOT a stretched png sprite anymore")
        _check(G.arcs[0]["pos"] == G.ship.position, "the arch rides its shooter")
        var av := _mk("grunt", Vector2(G.ship.position.x, G.ship.position.y - 200))
        var ah: int = av["hp"]
        var grown: float = float(G.arcs[0]["r"])
        G._arcs_tick(0.1)
        grown = float(G.arcs[0]["r"])
        av["node"].position = G.ship.position + Vector2(0, -grown)
        G.arcs[0]["hit"] = {}
        G._arcs_tick(0.016)
        _check(int(av["hp"]) < ah, "the painted arch still cuts whatever its ring meets")
        if is_instance_valid(av["node"]):
                av["node"].queue_free()
        G.arcs.clear()

        # ---- THE SHIELD LAW ----
        var tk := _mk("tank", Vector2(700, 300))
        _check(int(tk["shield"]) == 4, "a tank flies with its shield pool (4)")
        var tkhp: int = tk["hp"]
        G._hit_enemy(tk, 2)
        _check(int(tk["shield"]) == 2 and int(tk["hp"]) == tkhp,
                        "a shielded body EATS the hit - the pool drains, the hp never moves")
        G._hit_enemy(tk, 3)
        _check(int(tk["shield"]) == 0 and int(tk["hp"]) == tkhp,
                        "the breaking hit is consumed by the last shield point")
        G._hit_enemy(tk, 5)
        _check(int(tk["hp"]) == tkhp - 5, "after the break the body pays for real")

        # ---- titan: same damage to EVERY enemy (full field, the copy law) ----
        G.weapon = "missile"
        var t1 := _mk("grunt", Vector2(300, 200))
        var t2 := _mk("grunt", Vector2(1500, 400))
        var th1: int = t1["hp"]
        var th2: int = t2["hp"]
        var m := Sprite2D.new()
        m.texture = G._tex["w_titan"]
        G.world.add_child(m)
        G.missiles.append({"node": m, "t": 0.99})
        G._missiles_tick(0.016)
        _check(int(t1["hp"]) == th1 - 3 and int(t2["hp"]) == th2 - 3,
                        "the missile hits EVERY enemy with the SAME damage (owner law)")

        # ---- hearts law ----
        var sc0: int = G.score
        G.hearts = 3
        G.invuln = 0.0
        G._wreck()
        _check(G.hearts == 2 and G.score == maxi(0, sc0 - 500),
                        "a hit takes -500 score and -1 heart (owner)")
        G.next_heart_at = G.score + 500
        var h0: int = G.hearts
        G._score_gain(1000)
        _check(G.hearts == h0 + 1, "+1 heart per 1000 score (owner)")

        # ---- THE AIRDROP LAW (PATCH IV: this war's OWN loot rhythm) ----
        _check(G.COIN_WAVES_MIN == 2 and G.COIN_WAVES_MAX == 10,
                        "the coin rhythm: one airdrop every 2-10 WAVES (owner)")
        _check(G.POWER_WAVES_MIN == 1 and G.POWER_WAVES_MAX == 2,
                        "the power rhythm: a point every 1-2 waves (owner)")
        G.waves_since_coin = G.coin_target
        G.waves_since_power = G.power_target + 1
        G.loots.clear()
        G.phase = "gap"
        G._wave_end()
        var dropped := {}
        for l in G.loots:
                dropped[String(l["kind"])] = l
        _check(dropped.has("coin") and dropped.has("power"),
                        "the ripe rhythms pay BOTH airdrops at the wave end")
        _check((dropped["coin"]["node"] as Sprite2D).position.y < 0.0
                        and (dropped["power"]["node"] as Sprite2D).position.y < 0.0,
                        "the airdrops enter from the TOP like every wave's payment")
        _check(is_equal_approx(float(dropped["coin"]["node"].scale.x), 74.0 / 192.0),
                        "THE COIN SIZE LAW: the dash 74px - never the raw 192 again")
        _check(is_equal_approx(float(dropped["power"]["node"].scale.x), 2.4)
                        and (dropped["power"]["node"].texture as Texture2D).get_width() == 22,
                        "THE PILL LAW: the power point wears Space Dash's PILL at the 2.4x stamp")
        # kills roll NOTHING - the wreck economy stays in Space Dash
        G.loots.clear()
        for i in 30:
                var nk := _mk("grunt", Vector2(500, 240))
                G._kill_enemy(nk, true)
        _check(G.loots.is_empty(), "kills roll NOTHING - the wreck economy stayed in Space Dash")
        # the weapon roll: 5% at wave end, thunder/bomb only once bought
        Box.earn(100000)
        Box.buy_item(G.game_id, "weapons", "thunder", 2500)
        G.rng.seed = 7
        for i in 300:
                G._roll_weapon_drop()
        var thunder_paid := false
        for l in G.loots:
                if String(l["kind"]) == "thunder":
                        thunder_paid = true
        _check(thunder_paid, "the 5% weapon roll pays the bought thunder across 300 waves")
        G.loots.clear()

        # ---- the switch law ----
        var skin_weapon := String(G.SHIPS[G.skin]["weapon"])
        G.weapon = "thunder"
        G._collect("thunder")
        _check(G.weapon == "thunder", "a pool-weapon pickup SWITCHES you to it (own ladder)")
        G._collect("wswitch")
        _check(G.weapon == skin_weapon, "the ship's OWN icon brings its weapon back")

        # ---- THE UNFREEZE LAW + THE BUBBLE QUEUE LAW (the defender radio) ----
        Box.earn(10000)
        G._defend_open()
        _check(get_tree().paused and G._sheet_pair.size() > 0, "the defend sheet pauses like every sheet")
        G._defender_call("ember")
        _check(G.defender != null and G.defender_id == "ember", "DEFEND rents a crew ship")
        G._sheet_close()
        _check(not get_tree().paused,
                        "THE UNFREEZE LAW: closing the call screen UNPAUSES - the app answers")
        _check(G._bubble_queue.size() >= 1,
                        "THE QUEUE LAW: the radio's REPLY waits behind the caller's bubble")
        G._bubble_t = 0.01
        G._bubble_tick(0.02)
        await _wait(0.4)
        _check(G._bubble_queue.is_empty(), "the reply PLAYS after the caller (never wiped)")

        # ---- THE DEFENDER WEAPON LAW (PATCH IV: the REAL held weapons) ----
        var dt := _mk("grunt", Vector2(G.defender.position.x + 180, G.defender.position.y - 160))
        var saved_enemies: Array = G.enemies.duplicate()
        G.enemies = [dt]                       # the tests aim at ONE honest target
        var ddir: Vector2 = (dt["node"].position - G.defender.position).normalized()
        G.defender_fire_cd = 0.0
        var db0: int = G.bolts.size()
        G._defender_tick(0.016)
        _check(G.bolts.size() >= db0 + 2,
                        "the rented EMBER fires a real BEAM PAIR (no more plain bolts)")
        var beams_aimed := true
        for i in range(db0, G.bolts.size()):
                var sh: Dictionary = G.bolts[i]
                beams_aimed = beams_aimed and absf((sh["vel"] as Vector2).normalized().angle()
                                                - ddir.angle()) < 0.35 \
                                and (sh["node"] as Sprite2D).texture == G._tex["w_ember"]
        _check(beams_aimed, "the beam pair is AIMED at the nearest threat, wearing ember's sprite")
        # the rented VERDANT flies the real weaving pierce - FREE snakes
        G.defender_id = "verdant"
        G.defender_fire_cd = 0.0
        var sn0: int = G.snakes.size()
        G._defender_tick(0.016)
        _check(G.snakes.size() >= sn0 + 2, "the rented VERDANT flies the REAL snakes")
        var free_true := true
        for s in G.snakes:
                free_true = free_true and bool(s.get("free", false)) \
                                and absf(((s["dir"] as Vector2).normalized().angle() - ddir.angle())) < 0.1
        _check(free_true, "the defender snakes are FREE beams aimed down their own line")
        var fs_hp: int = dt["hp"]
        for i in 90:
                G._snakes_tick(0.016)
        _check(int(dt["hp"]) < fs_hp, "the free snakes PIERCE for real (the DPS law rides along)")
        if is_instance_valid(dt["node"]):
                dt["node"].queue_free()
        G.snakes.clear()
        G.enemies = saved_enemies
        var dw: int = G.defender_waves_left
        G._wave_end()
        _check(G.defender_waves_left == dw - 1, "every cleared wave burns one of its ten")
        G.defender_waves_left = 1
        G._wave_end()
        await _wait(1.8)
        _check(G.defender == null, "at zero it flies home with the radio")
        G._defender_call("titan")
        var ebolt := Sprite2D.new()
        ebolt.texture = G._tex["ebolt"]
        G.world.add_child(ebolt)
        ebolt.position = G.defender.position
        G.ebolts.append({"node": ebolt, "vel": Vector2(0, 100)})
        G._ebolts_tick(0.016)
        _check(G.defender == null, "ONE hit ends the defender (the owner's fragility law)")

        # ---- the breach law (END button) ----
        var bre := _mk("diver", Vector2(G.ship.position.x, 200))
        bre["state"] = "dive"
        bre["dive_v"] = Vector2(0, 100)
        var vp := G.get_viewport_rect().size
        bre["node"].position = Vector2(G.ship.position.x, vp.y - G._bottom_safe() + 30.0)
        G._enemies_tick(0.016)
        _check(G.phase == "breach", "one past the bottom = THE BREACH (the run is lost)")
        _check(G._story_pair.size() > 0, "the breach wears the SCROLLABLE STORY (the dario law)")
        _check(_story_btn() == "END", "THE BUTTON LAW: the breach's button says END")
        G._story_end()
        await _wait(1.2)
        _check(G.over, "END -> the death flow (finish_run emitted)")

        # ---- a fresh run: the story + boss laws ----
        await _boot()
        await _start_run()
        G.stage = 0
        G.wave = 0
        G._begin_stage(3)
        _check(_story_btn() == "START", "THE BUTTON LAW: stage arrivals say START")
        _story_btn_ignore()
        G._story_end()
        await _wait(1.4)

        # ---- THE BOSS LAWS (PATCH IV: the keepers WAKE UP) ----
        await _boot()
        await _start_run()
        G.stage = 0
        G.wave = 10
        G._start_boss_wave()
        G._story_end()
        await _frames(3)
        _check(not G.boss.is_empty() and String(G.boss["id"]) == "triton",
                        "stage 1 wears the TRITON WARDEN")
        _check(String(G.boss["state"]) == "enter", "the keeper glides in on enter")
        for i in 90:
                G._boss_tick(0.016)
        _check(String(G.boss["state"]) == "hover",
                        "THE AWAKENING LAW: the keeper WAKES after the glide (never a punching bag again)")
        G.boss["atk_t"] = 0.01
        var eb0: int = G.ebolts.size()
        G._boss_tick(0.016)
        _check(G.ebolts.size() > eb0, "THE WAR CLOCK: the keeper fires between its specials")
        var eb1: int = G.ebolts.size()
        G._boss_move("volley")
        _check(G.ebolts.size() >= eb1 + 5, "the triton volley is a real FIVE-spear fan")
        G._boss_move("rolleroll")
        _check(not (G.boss["act"] as Dictionary).is_empty() and String(G.boss["act"]["name"]) == "roll",
                        "THE ACT LAW: the side roll is a scripted ACT (the stomped tween is dead)")
        var min_x: float = G.boss["node"].position.x
        var max_x: float = min_x
        for i in 165:
                G._boss_tick(0.016)
                min_x = minf(min_x, G.boss["node"].position.x)
                max_x = maxf(max_x, G.boss["node"].position.x)
        _check(max_x - min_x > G.get_viewport_rect().size.x * 0.4,
                        "the roll SWEEPS the frame (the owner finally sees it)")
        _check((G.boss["act"] as Dictionary).is_empty(), "the act hands the body back to the drift")
        G._boss_move("spiral")
        var sp0: int = G.ebolts.size()
        for i in 60:
                G._boss_tick(0.016)
        _check(G.ebolts.size() > sp0 + 16, "the storm spiral pours a real rotating storm")

        # ---- a fresh run: the story + boss laws ----
        G.stage = 2
        G.wave = 10
        G._start_boss_wave()
        _check(_story_btn() == "FIGHT", "THE BUTTON LAW: a boss meet says FIGHT")
        G._story_end()
        await _frames(3)
        _check(not G.boss.is_empty() and String(G.boss["id"]) == "duke", "stage 3 wears the RING DUKE")
        G.boss["state"] = "hover"
        G.boss["hp"] = int(ceilf(float(G.boss["hp_max"]) * 0.15))
        G._hit_boss(3, G.boss["node"].position)
        _check(String(G.boss["state"]) == "flee", "the duke RUNS at 20% hp (owner: 3/6/9 never die)")
        _check(_story_btn() == "CONTINUE", "THE BUTTON LAW: the escape radio says CONTINUE")
        G._story_end()
        G.boss["node"].position.y = -400.0
        G._boss_tick(0.016)
        _check(G.boss.is_empty(), "the escape ends the wave (the world moves on)")
        G.stage = 2
        G.wave = 10
        G._start_boss_wave()
        G._story_end()
        await _frames(3)
        G.boss["state"] = "hover"
        G.boss["final"] = true
        G.boss["hp"] = 2
        G._hit_boss(5, G.boss["node"].position)
        _check(G.boss.is_empty(), "a FINAL keeper dies for real (the gauntlet law)")

        # ---- the finale gauntlet chain ----
        await _boot()
        await _start_run()
        G.stage = 9
        G.wave = 10
        G._start_boss_wave()
        G._story_end()
        await _frames(3)
        _check(not G.boss.is_empty() and String(G.boss["id"]) == "duke" and G.gauntlet_i == 0,
                        "the gauntlet opens: the duke alone")
        G._gauntlet_next()
        _check(G.gauntlet_i == 1 and G.phase == "gap", "step 2: the strong wave answers the run")
        G._gauntlet_next()
        G._story_end()
        await _frames(3)
        _check(G.gauntlet_i == 2 and G.boss.has("sats") and G.boss["sats"].size() == 1,
                        "step 3: duke + mimic fly together")
        G._gauntlet_next()
        _check(G.gauntlet_i == 3, "step 4: the harder wave")
        G._gauntlet_next()
        G._story_end()
        await _frames(3)
        _check(G.gauntlet_i == 4 and bool(G.boss.get("final", false)) and G.boss["sats"].size() == 2,
                        "step 5: the trio, FINAL - nobody runs now")
        G.boss["state"] = "hover"
        G.boss["hp"] = 1
        G._hit_boss(99, G.boss["node"].position)
        G._story_end()
        await _frames(3)
        _check(G.gauntlet_i == 5 and not G.boss.is_empty() and String(G.boss["id"]) == "invader",
                        "the trio falls - THE INVADER descends")
        G.boss["state"] = "hover"
        G.boss["hp"] = 1
        G._hit_boss(99, G.boss["node"].position)
        _check(G.phase == "ending", "the Invader never dies: THE CHASE ends the tour")
        G._story_end()
        await _frames(2)

        # ---- the themes pack law ----
        await _boot()
        await _start_run()
        _check(not G.themes_on, "without the pack the tour wears ONE neutral sky")
        G.themes_on = true
        G._apply_stage_sky(4, true)
        var mars_deep: Color = G.STAGES[4]["sky"]["deep"]
        _check(G.sky_cur["deep"].is_equal_approx(mars_deep),
                        "the pack paints each world its own DASH-SHADER sky (palette law)")

        # ---- done ----
        Box.reset_all()
        print("")
        if fails == 0:
                print("RESULT: ALL LAWS PASS")
        else:
                print("RESULT: %d FAILURES" % fails)
        get_tree().quit(0 if fails == 0 else 1)

func _story_btn_ignore() -> void:
        pass

func _ready() -> void:
        print("=== invaders probe ===")
        _run()
