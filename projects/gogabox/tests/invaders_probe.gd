extends Node
## invaders_probe - v0.3.2: drives the REBUILT Space Invaders headless. The
## owner's laws: the tour (10 stages x 10 waves, Neptune -> the Hideout),
## +1/+2/+3 enemies and +25..+200 bosses, hearts law (-500, +1 per 1000, cap 3),
## the breach law (one past the bottom = the dialogue), the power ladder
## (level IS the damage, death -3 rungs), the falloff laws (thunder chain,
## bomb rings, snake pierce - floor 1, never 0), the wave-anchored loot
## (coin 2-10 waves, power 1-2 waves), the boss escape law (3/6/9 at 20%,
## the finale gauntlet) and THE INVADER's ending.
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
        G._story_end()               # the intro lore story (scrollable, paused)
        await _wait(1.6)

func _mk(kind: String, at: Vector2) -> Dictionary:
        G._summon_kind(kind, at)
        var e: Dictionary = G.enemies[G.enemies.size() - 1]
        e["state"] = "hover"
        e["dive_cd"] = -1.0
        return e

func _run() -> void:
        Box.reset_all()
        print("== invaders_probe: the tour v0.3.2 ==")

        # ---- registry sanity (the owner's economy) ----
        var sr: Dictionary = GameReg.get_game("invaders")
        _check(not sr.is_empty(), "invaders is in the registry")
        _check(String(sr["title"]) == "Space Invaders", "the rename law: HEN -> SPACE INVADERS")
        _check(int(sr["coin_div"]) == 500, "run bonus = score/500 (owner)")
        _check(int(sr["fee"]) == 100 and int(sr["price"]) == 350,
                        "fee 100, buy price 350 (the hen teaser's own price)")
        _check(String(sr["orientation"]) == "landscape", "the tour is HORIZONTAL")
        _check(bool(sr["shop"]) and bool(sr["banner"]), "shop + banner on")
        _check(GameReg.playable().size() == 9 and GameReg.workshop().size() == 6,
                        "9 playable / 6 teasers (hen graduated)")
        _check(GameReg.playable()[GameReg.playable().size() - 1]["id"] == "invaders",
                        "invaders sits at the END of the playable chain (dario/xo links intact)")
        _check(GameReg.get_game("hen").is_empty(), "the hen teaser is gone from the workshop")

        # ---- boot ----
        await _boot()
        _check(G.phase == "ready" and G._sheet_pair.size() > 0,
                        "THE FLOW LAW: the game OPENS on the optionals screen")
        _check(G._optional_box("ember") != null, "optionals builds IMAGE boxes (the snake standard)")
        G._show_ready_card()
        await _frames(2)
        _check(G._ready_card != null, "closing optionals lands on TAP ANYWHERE TO PLAY")
        var no_ctrl_hint := true
        if G._ready_card != null:
                for c in G._ready_card.find_children("*", "Label", true, false):
                        if "left half" in String(c.get_class()):
                                no_ctrl_hint = false
        _check(no_ctrl_hint, "no controls help on the ready card (it lives in the guide)")
        _check(String(G.LINES["intro"][0]).contains("SPACE DASH"),
                        "the first dialogue references Space Dash (one universe)")
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
        _check(G.boss_chip != null and not G.boss_chip.visible,
                        "the boss % chip exists and sleeps until a boss lives")
        _check(G.STAGES.size() == 10, "the tour has 10 stages")
        _check(String(G.STAGES[0]["name"]) == "NEPTUNE" and String(G.STAGES[8]["name"]) == "THE SUN"
                        and String(G.STAGES[9]["name"]) == "THE HIDEOUT",
                        "Neptune opens, the Sun is stage 9, the Hideout is stage 10")
        var score_ok := true
        for k in G.ETYPES:
                score_ok = score_ok and int(G.ETYPES[k]["score"]) >= 1 and int(G.ETYPES[k]["score"]) <= 3
        _check(score_ok, "every enemy pays +1/+2/+3 (owner)")
        var boss_ok := true
        var boss_scores := []
        for b in G.BOSSES:
                boss_scores.append(int(G.BOSSES[b]["score"]))
                if int(G.BOSSES[b]["score"]) < 25 or int(G.BOSSES[b]["score"]) > 200:
                        boss_ok = false
        boss_scores.sort()
        _check(boss_ok and int(boss_scores[0]) == 25 and int(boss_scores[boss_scores.size() - 1]) == 200,
                        "bosses pay +25..+200 (the Invader takes the 200)")

        # ---- start the run ----
        await _start_run()
        _check(G.wave == 1, "wave 1 starts after the dialogues")
        _check(not G.enemies.is_empty(), "the formation flies in")

        # ---- the crew + their exclusive weapons ----
        _check(G.SHIPS["azure"]["price"] == 0, "Azure the PROTECTOR is the starter (price 0)")
        _check(String(G.SHIPS["azure"]["weapon"]) == "orb", "Azure carries the blue balls")
        var crew_ok := true
        for pair in [["ember", "beam"], ["verdant", "snake"], ["veteran", "arc"],
                        ["phantom", "mg"], ["hornet", "fire"], ["titan", "missile"]]:
                crew_ok = crew_ok and String(G.SHIPS[pair[0]]["weapon"]) == pair[1]
        _check(crew_ok, "ember/verdant/veteran/phantom/hornet/titan each own their weapon")
        _check(int(G.SHIPS["titan"]["price"]) == 6000 and int(G.SHIPS["ember"]["price"]) == 1500,
                        "ships price HIGH (2-in-1: hull + weapon)")

        # ---- the power ladder: the LEVEL is the damage ----
        _check(G.weapon_level() == 1, "every weapon starts at level 1 (= 1 damage)")
        G._apply_power("orb", 1)
        _check(G.weapon_level() == 1, "2 points to level 2 - one point is not enough")
        G._apply_power("orb", 1)
        _check(G.weapon_level() == 2, "level 2 at 2 points")
        G._apply_power("orb", 3)
        _check(G.weapon_level() == 3, "level 3 at 5 points")
        G._apply_power("orb", 20)
        _check(G.weapon_level() == G.POWER_MAX and G.POWER_MAX == 6,
                        "the ladder caps at SIX (the owner: space dash depth)")
        _check(G.score >= 25, "points past the cap pay +25 score (the lanes law)")

        # ---- per-hit weapons: damage = level ----
        G.wpower["orb"] = 2
        G.wpts["orb"] = 0
        var e1 := _mk("grunt", Vector2(900, 300))
        var hp0: int = e1["hp"]
        G.weapon = "orb"
        G._hit_enemy(e1, G.weapon_level())
        _check(int(e1["hp"]) == hp0 - 2, "an L2 hit takes exactly 2 (level = damage)")
        G.wpower["orb"] = 3
        G.bolts.clear()
        G._fire_orb()
        _check(G.bolts.size() == 3, "L3 azure fires 3 balls (more balls, small angle)")
        var one_dmg := true
        for b in G.bolts:
                one_dmg = one_dmg and int(b["dmg"]) == 3
        _check(one_dmg, "every ball carries the LEVEL as damage")
        for b in G.bolts.duplicate():
                b["node"].queue_free()
        G.bolts.clear()
        G.weapon = "beam"
        G.wpower["beam"] = 5
        G._fire_beam()
        _check(G.bolts.size() >= 4, "L5 ember fires a wider battery (more beams, wider range)")
        for b in G.bolts.duplicate():
                b["node"].queue_free()
        G.bolts.clear()
        G.weapon = "mg"
        G.wpower["mg"] = 1
        G._fire_mg()
        _check(G.bolts.size() == 2 and int(G.bolts[0]["dmg"]) == 1, "L1 MG: 2 barrels, small damage")
        for b in G.bolts.duplicate():
                b["node"].queue_free()
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
        _check(int(vic[1]["hp"]) == hp_before[1] - 2,
                        "the first chain hop takes base - 1")
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
        _check(int(btarget["hp"]) == hb - 5, "bomb center = 3 + 2*level (decent damage)")
        _check(int(bside["hp"]) == hs - 3, "150px out = two rings in, -2 (each ring -1, floor 1)")
        G._drop_bomb()
        _check(G.bombs.size() == 1, "no ammo limit: the launcher keeps firing")
        var bb: Dictionary = G.bombs[0]
        bb["node"].position = Vector2(-9999, -9999)
        G._bombs_tick(0.016)
        _check(G.bombs.is_empty(), "a bomb that touches NOTHING just leaves (contact fuse law)")

        # ---- the snake: pierce falloff, damage over time ----
        G.weapon = "snake"
        G.wpower["snake"] = 2
        G.wpts["snake"] = 0
        var s1 := _mk("grunt", Vector2(G.ship.position.x, G.ship.position.y - 70))
        var s2 := _mk("grunt", Vector2(G.ship.position.x, G.ship.position.y - 140))
        var h1: int = s1["hp"]
        var h2: int = s2["hp"]
        G._fire_snakes()
        G.firing = true
        for i in 34:
                for s in G.snakes:
                        s["t"] = 0.0          # pin the weave so the sweep stays on the column
                s1["node"].position = Vector2(G.ship.position.x, G.ship.position.y - 70)
                s2["node"].position = Vector2(G.ship.position.x, G.ship.position.y - 140)
                G._snakes_tick(0.016)
        _check(int(s1["hp"]) <= h1 - 2 and int(s2["hp"]) <= h2 - 1,
                        "the snake pierces through bodies over time; the further body takes less")
        _check(int(s2["hp"]) >= h2 - 2, "the falloff floors at a real 1 - never zero damage")
        G.firing = false
        for s in G.snakes:
                s["node"].queue_free()
        G.snakes.clear()

        # ---- titan: same damage to EVERY enemy (2 + the level, full field) ----
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
                        "the missile hits EVERY enemy with the SAME 2+level damage (owner law)")
        # the contact fuse: a missile detonates when it MEETS a body
        var t3 := _mk("grunt", Vector2(G.ship.position.x, G.ship.position.y - 300))
        var th3: int = t3["hp"]
        var m2 := Sprite2D.new()
        m2.texture = G._tex["w_titan"]
        m2.position = Vector2(G.ship.position.x, G.ship.position.y - 300)
        G.world.add_child(m2)
        G.missiles.append({"node": m2, "t": 0.1})
        G._missiles_tick(0.016)
        _check(int(t3["hp"]) < th3 and G.missiles.is_empty(),
                        "the missile detonates ON CONTACT (the owner's fuse law)")

        # ---- THE COPY-LAW REGRESSION (the owner's titan bug): a dense field -
        # the old blast loops erased kills mid-iteration and SKIPPED the enemies
        # after each kill. Every body must take the same damage, every time. ----
        var dense: Array = []
        var dense_hp: Array = []
        for i in 10:
                var de: Dictionary = _mk("grunt", Vector2(200.0 + 90.0 * float(i), 300.0))
                dense.append(de)
                dense_hp.append(int(de["hp"]))
        var dm := Sprite2D.new()
        dm.texture = G._tex["w_titan"]
        dm.position = Vector2(200.0, 300.0)
        G.world.add_child(dm)
        G.missiles.append({"node": dm, "t": 0.99})
        G._missiles_tick(0.016)
        var dense_ok := true
        for i in dense.size():
                if is_instance_valid(dense[i]["node"]) and int(dense[i]["hp"]) != dense_hp[i] - 3:
                        dense_ok = false
        _check(dense_ok and G.enemies.size() < 25,
                        "the full-field strike hits ALL 10 in a dense field (the copy law)")

        # ---- hearts law ----
        var sc0: int = G.score
        G.hearts = 3
        G.invuln = 0.0
        G._wreck()
        _check(G.hearts == 2 and G.score == maxi(0, sc0 - 500),
                        "a hit takes -500 score and -1 heart (owner)")
        _check(G.weapon_level() == 1 and G.weapon == "missile",
                        "the wreck drops the CURRENT weapon 3 rungs (the dash law)")
        G.next_heart_at = G.score + 500
        var h0: int = G.hearts
        G._score_gain(1000)
        _check(G.hearts == h0 + 1, "+1 heart per 1000 score (owner)")
        G.hearts = 3
        G.next_heart_at = G.score + 500
        var sc1: int = G.score
        G._score_gain(1000)
        _check(G.score >= sc1 + 25, "a 4th heart pays +25 score instead (cap 3)")

        # ---- the breach law ----
        var bre := _mk("diver", Vector2(G.ship.position.x, 200))
        bre["state"] = "dive"
        bre["dive_v"] = Vector2(0, 100)
        var vp := G.get_viewport_rect().size
        bre["node"].position = Vector2(G.ship.position.x, vp.y - G._bottom_safe() + 30.0)
        G._enemies_tick(0.016)
        _check(G.phase == "breach", "one past the bottom = THE BREACH (the run is lost)")
        _check(G._story_pair.size() > 0, "the breach wears the SCROLLABLE STORY (the dario law)")
        G._story_end()
        await _wait(1.2)
        _check(G.over, "END -> the death flow (finish_run emitted)")
        _check(G.score >= 0, "the score never goes negative")

        # ---- a fresh run: the boss laws ----
        await _boot()
        await _start_run()
        G.stage = 2
        G.wave = 10
        G._start_boss_wave()
        G._story_end()
        await _frames(3)
        _check(not G.boss.is_empty() and String(G.boss["id"]) == "duke", "stage 3 wears the RING DUKE")
        G.boss["state"] = "hover"
        G.boss["hp"] = int(ceilf(float(G.boss["hp_max"]) * 0.15))
        G._hit_boss(3, G.boss["node"].position)
        _check(String(G.boss["state"]) == "flee", "the duke RUNS at 20% hp (owner: 3/6/9 never die)")
        _check(Box.counter("invaders", "bosses_met") >= 1, "meeting a runaway keeper counts")
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
        _check(int(G.boss["hp"]) == int(G.BOSSES["duke"]["hp"]) + int(G.BOSSES["mimic"]["hp"]),
                        "the duo shares ONE health pool (damage either body)")
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

        # ---- the defender ----
        await _boot()
        await _start_run()
        Box.earn(10000)
        G._defender_call("ember")
        _check(G.defender != null and G.defender_id == "ember", "DEFEND rents a crew ship")
        _check(G.defender_waves_left == G.DEFEND_WAVES, "the defender flies 10 waves")
        _check(bool(G.defender_called.get("ember", false)), "each ship is callable once per run")
        var dw: int = G.defender_waves_left
        G._wave_end()
        _check(G.defender_waves_left == dw - 1, "every cleared wave burns one of its ten")
        G.defender_waves_left = 1
        G._wave_end()
        await _wait(1.8)
        _check(G.defender == null, "at zero it flies home with the radio")
        _check(bool(G.defender_called.get("ember", false)) and not G.defender_called.has("titan"),
                        "ember is spent, titan is still rentable")
        G._defender_call("titan")
        var ebolt := Sprite2D.new()
        ebotl_texture(ebolt)
        G.world.add_child(ebolt)
        G.ebolts.append({"node": ebolt, "vel": Vector2(0, 100)})
        ebotl_place(ebolt)
        G._ebolts_tick(0.016)
        _check(G.defender == null, "ONE hit ends the defender (the owner's fragility law)")

        # ---- the wave-anchored loot laws ----
        _check(G.COIN_WAVES_MIN == 2 and G.COIN_WAVES_MAX == 10,
                        "the coin rhythm is 2-10 waves (owner)")
        _check(G.POWER_WAVES_MIN == 1 and G.POWER_WAVES_MAX == 2,
                        "weapon points: 1 per 1-2 waves (owner)")
        G.waves_since_coin = 99
        G.waves_since_power = 99
        G.coin_target = 3
        G.power_target = 1
        var lo0: int = G.loots.size()
        G._wave_end()
        _check(G.loots.size() >= lo0 + 2, "both rolls fire when their waves ripen")
        _check(G.waves_since_coin == 0 and G.coin_target >= 2 and G.coin_target <= 10,
                        "the coin rerolls inside 2..10")

        # ---- the ship's-own-icon law + the switch law ----
        var skin_weapon := String(G.SHIPS[G.skin]["weapon"])
        G.weapon = "thunder"
        G._collect("thunder")
        _check(G.weapon == "thunder", "a pool-weapon pickup SWITCHES you to it (own ladder)")
        G._collect("wswitch")
        _check(G.weapon == skin_weapon, "the ship's OWN icon brings its weapon back")
        _check(int(G.wpts[skin_weapon]) >= 1, "own-icon pickups feed the same ladder")

        # ---- the themes pack law (the DASH SKY: one shader, palettes) ----
        _check(not G.themes_on, "without the pack the tour wears ONE neutral sky")
        G.themes_on = true
        G._apply_stage_sky(4, true)
        var mars_deep: Color = G.STAGES[4]["sky"]["deep"]
        _check(G.sky_cur["deep"].is_equal_approx(mars_deep),
                        "the pack paints each world its own DASH-SHADER sky (palette law)")
        var neutral_deep: Color = G.SKY_NEUTRAL["deep"]
        _check(neutral_deep == Color("060a1c"),
                        "the neutral sky IS Space Dash's Deep Blue (one universe)")

        # ---- done ----
        Box.reset_all()
        print("")
        if fails == 0:
                print("RESULT: ALL LAWS PASS")
        else:
                print("RESULT: %d FAILURES" % fails)
        get_tree().quit(0 if fails == 0 else 1)

func ebotl_texture(b: Sprite2D) -> void:
        b.texture = G._tex["ebolt"]

func ebotl_place(b: Sprite2D) -> void:
        b.position = G.defender.position

func _ready() -> void:
        print("=== invaders probe ===")
        _run()
