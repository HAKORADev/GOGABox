extends Node
## dash_probe - v0.2.4: drives SPACE DASH headless. RESOLUTION-INDEPENDENT:
## every touch lands at a fraction of the LIVE viewport (headless windows
## are arbitrary), and the spam-law waits honor the live frame floor
## (headless runs 1 FPS -> floor 100ms - the law itself, working).
##
## The laws: the ready card starts on a press, edge taps move ONE lane and
## the walls block, the middle finger fires, the SPAM LAW eats double-fires
## but never a human cadence, beams upgrade into MORE beams, the laser
## pierces its column on the 2s/0.5s law, thunder chains (3+level), the
## bomb blasts a radius on its 2s cooldown, kills pay +score with +nn, a
## coin drops every 5-10 kills from the LAST COLLECTED one, weapon/shield
## loot exists only when bought, the ladder reads 0/1/3/6/10/15/20 and
## death drops exactly 3 rungs, hearts (+1 per 1000, wreck -500, last
## death ends), the shield eats a hit, splitters split, the shatter ring
## keeps a seam facing the PLAYER at spawn and covered arcs stop beams,
## the laser AND the thunder chain, and the director's tiers climb with
## kills. Exit 0 = pass.
##
##   godot --headless --path projects/gogabox res://tests/dash_probe.tscn

var fails := 0

func _check(cond: bool, msg: String) -> void:
        print(("  PASS: " if cond else "  FAIL: ") + msg)
        if not cond:
                fails += 1

func _touch(g: GogaGame, at: Vector2, pressed: bool) -> void:
        var t := InputEventScreenTouch.new()
        t.index = 0
        t.position = at
        t.pressed = pressed
        g._goga_input(t)

func _vp(g: GogaGame) -> Vector2:
        return g.get_viewport_rect().size

func _mk_enemy(g: GogaGame, kind: String, at: Vector2) -> Dictionary:
        return g._spawn_enemy(kind, -1, at)

func _floor_wait(g: GogaGame) -> void:
        await get_tree().create_timer(
                        maxf(0.06, g.frame_floor_ms / 1000.0 + 0.03)).timeout

## how many of `marked` were hit: erased from the live list (killed) or
## carrying less hp than before
func _hit_count(g: GogaGame, marked: Array, before: Array) -> int:
        var n := 0
        for i in marked.size():
                var e: Dictionary = marked[i]
                if not g.enemies.has(e) or int(e["hp"]) < int(before[i]):
                        n += 1
        return n

func _run() -> void:
        Box.reset_all()
        _check(ResourceLoader.exists("res://assets/audio/music/dash_theme.wav"),
                        "the deep sky has its music")
        for t in ["ship_orange", "enemy_grunt", "laser_yellow",
                  "laser_thunder", "bomb", "shield_1", "fx_flare"]:
                _check(ResourceLoader.exists("res://assets/games/lanes/%s.png" % t),
                        "real-art sprite vendored: %s" % t)
        var g: GogaGame = load("res://game/games/lanes/lanes.gd").new()
        g.game_id = "lanes"
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        var vp := _vp(g)
        _check(g.phase == "ready", "boots into the TAP ANYWHERE card")
        _check(g.LANES == 5, "five lanes (owner spec)")

        # ---- start + movement + the walls ----
        _touch(g, Vector2(vp.x * 0.5, vp.y * 0.5), true)
        _check(g.phase == "run", "any press starts the run")
        _check(g.lane == 2, "ship starts mid lane")
        _touch(g, Vector2(vp.x * 0.06, vp.y * 0.5), true)      # left edge
        _check(g.lane == 1, "left edge tap moves one lane")
        for i in 6:
                _touch(g, Vector2(vp.x * 0.94, vp.y * 0.5), true)
        _check(g.lane == 4, "the wall blocks at the last lane (lane=%d)" % g.lane)
        for i in 6:
                _touch(g, Vector2(vp.x * 0.06, vp.y * 0.5), true)
        _check(g.lane == 0, "the wall blocks at lane zero")

        # ---- the SPAM LAW ----
        var s1: bool = g._shot_ok()
        var s2: bool = g._shot_ok()
        _check(s1 and not s2, "one shot per floor: the same instant cannot fire twice")
        await _floor_wait(g)
        _check(g._shot_ok(), "past the floor a human tap fires again")
        _check(g.frame_floor_ms >= 30.0, "the floor never drops under 30ms")
        await _floor_wait(g)

        # ---- beams: tap fires, upgrades add beams ----
        g.bolts.clear()
        _touch(g, Vector2(vp.x * 0.5, vp.y * 0.78), true)      # middle press
        _check(g.firing, "a middle press is THE fire finger")
        _touch(g, Vector2(vp.x * 0.5, vp.y * 0.78), false)
        _check(not g.firing, "the release stops the hold")
        _check(g.bolts.size() >= 1, "a tap fires the beams (%d)" % g.bolts.size())
        g.bolts.clear()
        g.power["beam"] = 6       # L3 on the ladder (0/1/3/6/...)
        g._fire_beams()
        _check(g.bolts.size() == 3, "L3 = three beams per shot (%d)" % g.bolts.size())
        g.bolts.clear()
        g.power["beam"] = 20      # L6 = the max rung
        g._fire_beams()
        _check(g.bolts.size() == 4, "L6 max = four beams per shot (%d)" % g.bolts.size())
        g.bolts.clear()
        g.power["beam"] = 0

        # ---- the ladder 0/1/3/6/10/15/20 ----
        var ladder := [0, 1, 3, 6, 10, 15, 20]
        var ok_ladder := true
        for pts in 21:
                g.power["beam"] = pts
                if g.weapon_level() != _expect_level(ladder, pts):
                        ok_ladder = false
        _check(ok_ladder, "the power ladder reads 0/1/3/6/10/15/20")

        # ---- wreck: -500 clamp, -1 heart, exactly -3 rungs ----
        g.power["beam"] = 10    # level 4
        var hearts0: int = g.hearts
        g._wreck()
        _check(int(g.power["beam"]) == 1,
                "death drops exactly 3 rungs (L4/10pts -> L1/1pt)")
        _check(g.hearts == hearts0 - 1, "a wreck costs one heart")
        _check(g.score == 0, "the wreck clamps at 0 score (-500 floor)")

        # ---- kills, +nn, the coin heartbeat ----
        g.hearts = 3
        var e := _mk_enemy(g, "grunt", Vector2(g._lane_x(0), 300))
        var score0: int = g.score
        var kills0: int = g.kills
        g._hurt(e, 99)
        _check(g.score == score0 + 10, "a grunt pays its +10")
        _check(g.kills == kills0 + 1, "the kill counts")
        _check(not g._popups.is_empty(), "a +nn popup flew")
        g.coin_target = 5
        g.kills_since_coin = 0
        g.loots.clear()
        for i in 5:
                var ei := _mk_enemy(g, "grunt", Vector2(g._lane_x(1),
                                200.0 + 30.0 * i))
                g._hurt(ei, 99)
        var got_coin := false
        for l in g.loots:
                got_coin = got_coin or String(l["kind"]) == "coin"
        _check(got_coin, "the 5th kill since the last coin drops THE coin")
        for l in g.loots:
                if String(l["kind"]) == "coin":
                        g._collect("coin", l["node"].position)
                        break
        _check(g.run_coins == 1, "the coin is ONE goga coin")
        _check(g.kills_since_coin == 0, "the counter resets at COLLECTION")
        _check(g.coin_target >= 5 and g.coin_target <= 10,
                "the next coin target rerolled inside 5..10")

        # ---- loot gating: weapons/shield exist only when bought ----
        var gated := true
        for i in 400:
                g._roll_drop(Vector2(100, 100), false)
                for l in g.loots:
                        if String(l["kind"]) != "coin" \
                                        and String(l["kind"]) != "power":
                                gated = false
                g.loots.clear()
        _check(gated, "no weapon/shield loot before the shop sells it")
        Box.buy_item("lanes", "weapons", "laser", 0)
        Box.buy_item("lanes", "weapons", "thunder", 0)
        Box.buy_item("lanes", "weapons", "bomb", 0)
        Box.buy_unlock("lanes", "shield", 0)
        var saw := {}
        for i in 400:
                g._roll_drop(Vector2(100, 100), false)
                for l in g.loots:
                        saw[String(l["kind"])] = true
                g.loots.clear()
        _check(saw.has("w_laser") and saw.has("w_thunder") and saw.has("w_bomb"),
                "bought weapons join the loot pool")
        _check(saw.has("shield"), "the bought shield joins the loot pool")

        # ---- the laser: pierces the column, lives 2s, cooldown 0.5s ----
        g.enemies.clear()
        g.weapon = "laser"
        g.firing = true
        g.laser_live = 2.0
        g.laser_cd = 0.0
        var col_x: float = g.ship.position.x
        var e_tank := _mk_enemy(g, "tank", Vector2(col_x,
                        g.ship.position.y - 420.0))
        var e_col := _mk_enemy(g, "grunt", Vector2(col_x,
                        g.ship.position.y - 240.0))
        var e_off := _mk_enemy(g, "grunt", Vector2(g._lane_x(
                        clampi(g.lane + 1, 0, g.LANES - 1)),
                        g.ship.position.y - 420.0))
        var hp_a: int = int(e_tank["hp"])
        var hp_b: int = int(e_col["hp"])
        var hp_c: int = int(e_off["hp"])
        g._laser_burn(0.5)      # 12 burn -> the grunt dies, the tank burns
        _check(int(e_tank["hp"]) < hp_a and int(e_col["hp"]) <= 0,
                "the laser burns EVERY hull in its column (pierces)")
        _check(int(e_off["hp"]) == hp_c, "the laser ignores other lanes")
        g.laser_live = 0.05
        g._goga_tick(0.1)       # the live clock rides the game tick
        _check(g.laser_cd > 0.0, "2s spent -> the 0.5s cooldown starts")
        g.firing = false
        g.enemies.clear()

        # ---- thunder: chains, upgrades chain farther ----
        g.weapon = "thunder"
        g.thunder_live = 5.0
        g.thunder_cd = 0.0
        g.enemies.clear()
        var marked: Array = []
        var before: Array = []
        for i in 8:
                var t := _mk_enemy(g, "tank", Vector2(
                                g.ship.position.x,
                                g.ship.position.y - 130.0 - 92.0 * i))
                marked.append(t)
                before.append(int(t["hp"]))
        g.power["thunder"] = 0
        g._do_strike()
        _check(_hit_count(g, marked, before) == 3,
                "thunder level 0 chains 3 victims (%d)" %
                        _hit_count(g, marked, before))
        g.enemies.clear()
        marked.clear()
        before.clear()
        for i in 8:
                var t2 := _mk_enemy(g, "tank", Vector2(
                                g.ship.position.x,
                                g.ship.position.y - 130.0 - 92.0 * i))
                marked.append(t2)
                before.append(int(t2["hp"]))
        g.power["thunder"] = 6
        g._do_strike()
        _check(_hit_count(g, marked, before) == 6,
                "thunder level 3 chains 6 victims (upgrade = more enemies)")
        g.power["thunder"] = 0
        g.enemies.clear()

        # ---- the bomb: radius blast + cooldown ----
        g.weapon = "bomb"
        g.bomb_cd = 0.0
        g.bombs.clear()
        _mk_enemy(g, "grunt", Vector2(g.ship.position.x,
                        g.ship.position.y - 300.0))
        _mk_enemy(g, "grunt", Vector2(g.ship.position.x + 90.0,
                        g.ship.position.y - 340.0))
        _mk_enemy(g, "grunt", Vector2(g.ship.position.x - 600.0,
                        g.ship.position.y - 300.0))     # far away
        g._drop_bomb()
        _check(g.bombs.size() == 1 and g.bomb_cd > 0.0,
                "the bomb is single-shot on its 2s cooldown")
        var b: Dictionary = g.bombs[0]
        b["node"].position = Vector2(g.ship.position.x,
                        g.ship.position.y - 320.0)
        g._bomb_blast(b["node"].position)
        var alive := 0
        for en in g.enemies:
                if is_instance_valid(en["node"]):
                        alive += 1
        _check(alive == 1, "the blast erased the cluster, spared the far hull")
        g.enemies.clear()
        g.bombs.clear()

        # ---- hearts: +1 per 1000, the LAST death ends ----
        g.hearts = 1
        g.invuln = 0.0
        g.set_score(0)
        g.next_heart_at = 1000
        g._score_gain(1000)
        _check(g.hearts == 2, "+1 heart at the 1000 crossing")
        var done := []
        g.request_finish.connect(func(s, c): done.append(s))
        g._wreck()          # 2 -> 1
        g.invuln = 0.0
        g._wreck()          # 1 -> 0 = the last death
        _check(g.hearts == 0 and g.phase == "over",
                "the death that takes the last heart ends the run")
        await get_tree().create_timer(1.2).timeout
        _check(done.size() == 1, "the run hands its score to the host")

        # ---- fresh game: shield, splitter, shatter, director ----
        var g2: GogaGame = load("res://game/games/lanes/lanes.gd").new()
        g2.game_id = "lanes"
        add_child(g2)
        await get_tree().process_frame
        await get_tree().process_frame
        g2._start()
        g2.loots.clear()
        g2._collect("shield", g2.ship.position)
        _check(g2.shield_lvl == 1, "a shield item arms level 1")
        g2._collect("shield", g2.ship.position)
        g2._collect("shield", g2.ship.position)
        _check(g2.shield_lvl == 3, "the shield caps at 3 levels")
        var sc0: int = g2.score
        g2._collect("shield", g2.ship.position)
        _check(g2.shield_lvl == 3 and g2.score == sc0 + 25,
                "a 4th shield pays score instead")
        var hearts1: int = g2.hearts
        g2._wreck()
        _check(g2.shield_lvl == 2 and g2.hearts == hearts1,
                "the aura eats the hit: level down, heart stays")
        # splitter: dies into two small grunts
        g2.enemies.clear()
        var sp := _mk_enemy(g2, "splitter", Vector2(g2._lane_x(2), 400))
        g2._hurt(sp, 99)
        var smalls := 0
        for en in g2.enemies:
                if String(en["kind"]) == "grunt" and float(en["node"].scale.x) < 1.5:
                        smalls += 1
        _check(smalls == 2, "the splitter dies into two small grunts")
        # shatter: the seam faces the PLAYER at spawn, rings cover the rest
        g2.enemies.clear()
        var n_open := 0
        for i in 30:
                var sh := _mk_enemy(g2, "shatter",
                                Vector2(g2._lane_x(2), 400.0 + float(i)))
                var below: Vector2 = sh["node"].position \
                                + Vector2(0, float(sh["shards"][0]["rad"]))
                if not g2._point_shard_blocked(sh, below):
                        n_open += 1
        _check(n_open == 30,
                "every spawn keeps a seam facing the player (%d/30)" % n_open)
        # a covered arc stops the beam
        g2.enemies.clear()
        var sh2 := _mk_enemy(g2, "shatter", Vector2(g2._lane_x(2), 700))
        sh2["shards"][0]["spd"] = 0.0     # freeze the orbit
        var c: Vector2 = sh2["node"].position
        var ang: float = float(sh2["shards"][0]["ang"])
        var on_ring: Vector2 = c + Vector2(cos(ang), sin(ang)) \
                        * float(sh2["shards"][0]["rad"])
        _check(g2._point_shard_blocked(sh2, on_ring),
                "a bolt on a covered arc is blocked")
        _check(not g2._point_shard_blocked(sh2, c + Vector2(0, -1000)),
                "a point far off the ring is not")
        # the laser must enter through the seam: spawn state = shard at the
        # TOP, seam facing the player -> the burn GOES THROUGH
        g2.weapon = "laser"
        g2.firing = true
        g2.laser_live = 2.0
        g2.laser_cd = 0.0
        sh2["node"].position.x = g2.ship.position.x
        sh2["hp"] = 100    # beefy hull so the burn never kills mid-test
        var shp0: int = int(sh2["hp"])
        g2._laser_burn(0.25)
        _check(int(sh2["hp"]) < shp0,
                "the laser burns through the seam that faces the player")
        # rotate the orbit: shard to the BOTTOM -> the entry is covered
        sh2["shards"][0]["ang"] = PI * 0.5
        var shp1: int = int(sh2["hp"])
        g2._laser_burn(0.25)
        _check(int(sh2["hp"]) == shp1,
                "a covered entry sparks - no burn through shards")
        # and the thunder chain passes covered carriers over
        g2.weapon = "thunder"
        g2.thunder_live = 5.0
        g2.thunder_cd = 0.0
        g2._do_strike()      # only the covered carrier is in range
        _check(int(sh2["hp"]) == shp1,
                "thunder passes a covered carrier over (no free hits)")
        g2.firing = false
        # director: tiers climb with kills
        var ev0: float = g2._spawn_every()
        g2.kills = 250
        _check(g2.tier() == 10, "250 kills = the top tier")
        _check(g2._spawn_every() < ev0,
                "higher tier = faster spawns (%.2f -> %.2f)" % [ev0, g2._spawn_every()])
        _check(g2._shooter_ratio() > 0.10, "higher tier = more shooters")

        print("RESULT: %s" % ("ALL LAWS PASS" if fails == 0
                        else "%d FAILURES" % fails))
        get_tree().quit(0 if fails == 0 else 1)

func _expect_level(ladder: Array, pts: int) -> int:
        var lvl := 0
        for i in ladder.size():
                if pts >= int(ladder[i]):
                        lvl = i
        return lvl

func _ready() -> void:
        print("=== dash probe ===")
        _run()
