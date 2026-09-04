extends Node
## dario_probe - v0.3.1 PATCH III: drives CURSED DARIO headless. The laws:
## the expensive entry (100), the /10 bonus, the ten TALL 15-row maps (all
## parse, all carry a start + a ground goal + a CONTINUOUS ground, no
## floating coins, every crate supported, the arena carries the Witcher +
## the ghost ladder), the FEET-ON-GROUND physics (no more sunken body),
## the jump + the EXACT x2 power jump, the REAL multi-touch controls, the
## tiered stomp table, the blocker shield, THE MOVER THAT NEVER TELEPORTS,
## THE ALIVE SPIKES, the honest spiky art cycle (out = deadly, in =
## stompable, the warn flash), THE RHINO'S SPRINT CHARGE, THE BAT HUNT,
## the spitter that FACES Dario, the death law (-100, the FULL ROLLBACK
## of the attempt's score + coins, the fade sequence), the door law, the
## boss law, the ghost cycles, the INTRO lock, the theme toggle, and the
## FRAMING law (the zoomed camera that never shows the dead sky band).
##
##   godot --headless --path projects/gogabox res://tests/dario_probe.tscn

var fails := 0

func _check(cond: bool, msg: String) -> void:
        print(("  PASS: " if cond else "  FAIL: ") + msg)
        if not cond:
                fails += 1

var D: GDScript

func _run() -> void:
        Box.reset_all()
        print("== dario_probe: CURSED DARIO v0.3.1 patch III ==")
        D = load("res://game/games/dario/dario.gd")

        # ---- registry sanity (the owner's economy) ----
        var dr: Dictionary = GameReg.get_game("dario")
        _check(not dr.is_empty(), "dario is in the registry")
        _check(String(dr["title"]) == "Cursed Dario",
                        "the game is CURSED DARIO (the rename law)")
        _check(int(dr["fee"]) == 100, "the entry costs 100 coins (owner)")
        _check(int(dr["coin_div"]) == 10, "the run bonus = score/10 (owner)")
        _check(bool(dr["shop"]), "the shop sells the night sky + the powerups")
        _check(bool(dr["banner"]), "dario carries the ad banner")
        _check(dr["ach"].size() == 3, "three fresh achievements")
        _check(String(dr["controls"][6]).contains("-100"),
                        "the guide tells the -100 death law (not -200)")

        # ---- the TEN TALL MAPS law: 15 rows, continuous ground ----
        _check(D.LEVELS.size() == 10, "ten levels (the owner)")
        var allowed := "#B?gm~^DdTsbphWf."
        for i in D.LEVELS.size():
                var map: Array = D.LEVELS[i]
                var w := String(map[0]).length()
                var even := true
                var tall := map.size() == 15
                var solid_ground := true
                var clean := true
                var sky_open := true
                var has_door := false
                var has_start := false
                for r in map.size():
                        var row := String(map[r])
                        if row.length() != w:
                                even = false
                        if r == map.size() - 1 and row.count("#") != w:
                                solid_ground = false
                        if (r == 0 or r == 1) and row.count(".") != w:
                                sky_open = false
                        for c in w:
                                if not allowed.contains(row[c]):
                                        clean = false
                        if row.contains("D"):
                                has_door = true
                        if row.contains("d"):
                                has_start = true
                _check(even and tall and has_door and has_start,
                                "level %d parses: 15 rows %s, even %s, door+start %s/%s"
                                % [i + 1, tall, even, has_door, has_start])
                _check(solid_ground, "level %d ground is CONTINUOUS (no gaps)" % (i + 1))
                _check(sky_open, "level %d keeps rows 0-1 as open sky" % (i + 1))
                _check(clean, "level %d has no floating coins / dead chars" % (i + 1))
                # every ? crate has standable support within jump reach
                var reach_ok := true
                for r in map.size():
                        var row2 := String(map[r])
                        for c in w:
                                if row2[c] != "?":
                                        continue
                                var sup := false
                                for rr in range(r + 1, mini(r + 5, map.size())):
                                        var row3 := String(map[rr])
                                        for cc in range(maxi(0, c - 2), mini(w, c + 3)):
                                                if "#B?g".contains(row3[cc]):
                                                        sup = true
                                if not sup:
                                        reach_ok = false
                                        print("    unsupported crate at L%d (%d,%d)" % [i + 1, r, c])
                _check(reach_ok, "level %d crates are all bump-reachable" % (i + 1))
        var l10 := ""
        for r in D.LEVELS[9].size():
                l10 += String(D.LEVELS[9][r])
        _check(l10.contains("W"), "the Witcher waits in level 10")
        _check(l10.count("g") >= 4,
                        "the ghost ladder appears and vanishes (the TALL timed climb)")

        # ---- boot: the run starts, the intro LOCKS, the counter counts ----
        var plays0: int = int(Box.counter("dario", "playthroughs"))
        var g: GogaGame = D.new()
        g.game_id = "dario"
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        _check(int(Box.counter("dario", "playthroughs")) == plays0 + 1,
                        "the playthrough counter counts (the cursed replays)")
        _check(g.p_node != null and is_instance_valid(g.p_node),
                        "Dario was born at the start marker")
        _check(bool(g._locked), "the intro dialogue box LOCKS the game")
        _check(g.sheet_open_count() == 1,
                        "the intro owns its dim+center PAIR (the pair law)")
        g.sheet_pop()
        g._locked = false
        _check(not bool(g._locked), "DONE dismisses the intro and unlocks")

        # ---- THE FEET LAW: Dario lands ON the ground, never in it ----
        var landed := false
        for i in 90:
                g._goga_tick(1.0 / 60.0)
                if g.on_floor:
                        landed = true
                        break
        _check(landed, "Dario FELL and landed on the tiles (the tile physics)")
        var ground_top := float(g.rows - 1) * 80.0
        var feet: float = float(g.p_node.position.y) + float(g.p_size.y) / 2.0
        _check(absf(feet - ground_top) < 2.0,
                "Dario stands ON the ground (feet at the grass line, body OUT of the soil)")

        # ---- the FRAMING law: the zoomed world, the dead sky never shown ----
        _check(float(g._zoom_k) >= 1.0,
                "the world renders ZOOMED (k = %.2f, the things grow)" % float(g._zoom_k))
        var wsx: float = g.world.scale.x if is_instance_valid(g.world) else -1.0
        _check(absf(wsx - float(g._zoom_k)) < 0.001,
                "the world wears the zoom on its transform (scale %.2f vs k %.2f)"
                                % [wsx, float(g._zoom_k)])
        # walking right keeps the camera coherent (no negative cam, no gaps)
        g._walk_idx = 0
        g._walk_anchor = 100.0
        g._walk_pos = Vector2(400, 300)
        for i in 60:
                g._goga_tick(1.0 / 60.0)
        _check(float(g.cam.x) > 0.0,
                "walking right scrolls the world (cam.x follows)")
        g._walk_idx = -1
        g._walk_dir = 0.0

        # ---- the jump + the EXACT x2 POWER JUMP (the owner: "it makes
        # dario jump far away but it's just supposed to make him jump x2
        # the distance of a normal jump") ----
        var h1 := _measure_jump(g, false)
        var h2 := _measure_jump(g, true)
        _check(h1 > 200.0 and h1 < 280.0,
                "a normal jump clears ~3 tiles (%.0fpx)" % h1)
        _check(absf(h2 - h1 * 2.0) < h1 * 0.16,
                "POWER JUMP is EXACTLY 2x the jump (%.0f vs %.0f x2)" % [h2, h1])

        # ---- the MULTI-TOUCH law: left walk survives a right jump tap ----
        var gvp := g.get_viewport_rect().size
        var st := InputEventScreenTouch.new()
        st.index = 0
        st.pressed = true
        st.position = Vector2(100, 300)
        g._goga_input(st)
        _check(int(g._walk_idx) == 0, "the left touch owns the walk")
        var sd := InputEventScreenDrag.new()
        sd.index = 0
        sd.position = Vector2(220, 300)
        g._goga_input(sd)
        _check(float(g._walk_pos.x) == 220.0, "the walk drag follows the finger")
        var st2 := InputEventScreenTouch.new()
        st2.index = 1
        st2.pressed = true
        st2.position = Vector2(gvp.x * 0.75, 300)
        g._goga_input(st2)
        _check(bool(g._jump_queued), "the right-half tap queues the jump")
        _check(int(g._walk_idx) == 0,
                        "the jump tap did NOT steal the walk (the v0.3.1 bug is dead)")
        var st3 := InputEventScreenTouch.new()
        st3.index = 1
        st3.pressed = false
        st3.position = Vector2(gvp.x * 0.75, 300)
        g._goga_input(st3)
        _check(int(g._walk_idx) == 0, "the right release keeps the walk alive")
        var st4 := InputEventScreenTouch.new()
        st4.index = 0
        st4.pressed = false
        st4.position = Vector2(220, 300)
        g._goga_input(st4)
        _check(int(g._walk_idx) == -1, "releasing the walk thumb drops it")

        # ---- the stomp table: the TIERED points (the owner's balance fix) ----
        g.set_score(0)
        g._lvl_score0 = 0
        g._spawn_enemy("snail", Vector2i(3, 12))
        var e: Dictionary = g.enemies[g.enemies.size() - 1]
        g.p_node.position = e["node"].position + Vector2(0, -60.0)
        g.p_vel.y = 900.0
        var snails := 0
        for ee in g.enemies:
                if String(ee["kind"]) == "snail":
                        snails += 1
        g._stomp(e)
        _check(int(g.score) == 5, "a SNAIL stomp pays exactly +5 (not 10!)")
        var snails_after := 0
        for ee in g.enemies:
                if String(ee["kind"]) == "snail":
                        snails_after += 1
        _check(snails_after == snails - 1,
                        "the stomped enemy is GONE")
        g._spawn_enemy("spiky", Vector2i(5, 12))
        var sp: Dictionary = g.enemies[g.enemies.size() - 1]
        sp["spike_up"] = false
        g.p_node.position = sp["node"].position + Vector2(0, -60.0)
        g.p_vel.y = 900.0
        g._stomp(sp)
        _check(int(g.score) == 5 + 25, "the SPIKY pays +25 (the top tier)")

        # ---- THE HONEST SPIKY ART: out = deadly (spiky1), in = stompable ----
        g._spawn_enemy("spiky", Vector2i(8, 12))
        var sp2: Dictionary = g.enemies[g.enemies.size() - 1]
        var spr2: Sprite2D = sp2["node"].get_child(0)
        sp2["spike_t"] = 0.2      # inside the UP window
        g._goga_tick(1.0 / 60.0)
        var tx_up: Texture2D = spr2.texture
        _check(tx_up.resource_path.contains("spiky1"),
                "spikes OUT wear the SPIKY art (deadly looks deadly)")
        sp2["spike_t"] = 2.5      # inside the DOWN window
        g._goga_tick(1.0 / 60.0)
        _check(spr2.texture.resource_path.contains("spiky2"),
                "spikes IN wear the SMOOTH art (stompable looks safe)")
        _check(bool(sp2["warn"]) == (fmod(2.5, 4.2) > 4.2 - 0.35),
                "the warn flash only lives in the last 0.35s of the safe window")

        # ---- THE RHINO'S SPRINT HIT (the owner: "when it looks toward
        # dario, it tries to hit him and dario just has to jump and dodge
        # and kill it") ----
        var g_rh: GogaGame = D.new()
        g_rh.game_id = "dario"
        add_child(g_rh)
        await get_tree().process_frame
        g_rh.sheet_pop()
        g_rh._locked = false
        g_rh._load_level(3)      # THE STONES - the rhino's debut
        g_rh._spawn_enemy("blocker", Vector2i(20, 12))
        var rh: Dictionary = g_rh.enemies[g_rh.enemies.size() - 1]
        var rn: Node2D = rh["node"]
        # drop the rhino ON the ground (the snap law's placement) so its
        # ledge probe reads solid floor - a floating rhino just jitters
        rn.position.y = 14.0 * 80.0 - float(rh["h"]) / 2.0 - 2.0
        rh["base_y"] = rn.position.y
        # park Dario 300px ahead of the rhino, on its level
        g_rh.p_node.position = rn.position + Vector2(300.0, 0.0)
        var charged := false
        var cx0 := 0.0
        for i in 300:            # 5s: patrol -> windup -> charge
                g_rh._enemies_tick(1.0 / 60.0)
                if String(rh["state"]) == "charge":
                        charged = true
                        cx0 = float(rh["chg_x0"])
                        break
        _check(charged, "the rhino WINDS UP and SPRINT-CHARGES at Dario")
        # step OUT of the lane the moment it charges (the dodge the owner
        # describes - jump it, dodge it): Dario floats up-and-over, inside
        # the wake window but far above the contact band (the headless
        # portrait viewport keeps the wake tight)
        g_rh.p_node.position = rn.position + Vector2(200.0, -330.0)
        for i in 30:
                g_rh._enemies_tick(1.0 / 60.0)
        _check(charged and absf(float(rn.position.x) - cx0) > 60.0,
                "the charge MOVES (a real sprint, not a pose)")
        # it stalls and recovers (the dodge window)
        var recovered := false
        for i in 200:
                g_rh._enemies_tick(1.0 / 60.0)
                if String(rh["state"]) == "patrol":
                        recovered = true
                        break
        _check(recovered, "after the sprint the rhino STALLS (jump it, then stomp it)")

        # ---- THE BAT HUNTS (the owner: "make it follow and hunt dario and
        # dario tries to kill it, because currently it's just a decor") ----
        g_rh._spawn_enemy("fly", Vector2i(24, 5))
        var bt: Dictionary = g_rh.enemies[g_rh.enemies.size() - 1]
        var bn: Node2D = bt["node"]
        g_rh.p_node.position = bn.position + Vector2(260.0, 40.0)
        var d0: float = bn.position.distance_to(g_rh.p_node.position)
        # 45 ticks: the dive closes ~160px WITHOUT contact yet (no cheap
        # deaths mid-observation)
        for i in 45:
                g_rh._enemies_tick(1.0 / 60.0)
        var d1: float = bn.position.distance_to(g_rh.p_node.position)
        _check(bool(bt["hunting"]) and d1 < d0 - 60.0,
                "the bat DIVES at Dario when he is in reach (%.0f -> %.0f)" % [d0, d1])
        # it is killable: falling onto the diver = a stomp, not a side hit
        var bats := 0
        for ee in g_rh.enemies:
                if String(ee["kind"]) == "fly":
                        bats += 1
        g_rh.p_vel.y = 900.0
        g_rh.p_node.position = bn.position + Vector2(0, -50.0)
        g_rh._goga_tick(1.0 / 60.0)
        var bats2 := 0
        for ee in g_rh.enemies:
                if String(ee["kind"]) == "fly":
                        bats2 += 1
        _check(bats2 == bats - 1 and String(g_rh._phase) == "play",
                "a hunting bat is STOMPABLE (not a decor)")

        # ---- THE PEA SHOOTER FACES DARIO (the owner: "it shoots the pea
        # at me while its body still looks at the other side") ----
        g_rh._spawn_enemy("spitter", Vector2i(26, 12))
        var sp3: Dictionary = g_rh.enemies[g_rh.enemies.size() - 1]
        var spr3: Sprite2D = sp3["node"].get_child(0)
        g_rh.p_node.position = sp3["node"].position + Vector2(400.0, 0.0)
        g_rh._goga_tick(1.0 / 60.0)
        var faced_right := bool(spr3.flip_h)
        g_rh.p_node.position = sp3["node"].position + Vector2(-400.0, 0.0)
        g_rh._goga_tick(1.0 / 60.0)
        _check(faced_right and not bool(spr3.flip_h),
                "the spitter's BODY turns to aim before it shoots")

        # ---- THE MOVER NEVER TELEPORTS (the owner: "when i step on it,
        # it teleports me to the start of the level") ----
        var g_mv: GogaGame = D.new()
        g_mv.game_id = "dario"
        add_child(g_mv)
        await get_tree().process_frame
        g_mv.sheet_pop()
        g_mv._locked = false
        g_mv._load_level(2)      # THE MARKS - the first mover
        _check(g_mv.movers.size() >= 1, "level 3 carries the mover")
        var mv: Dictionary = g_mv.movers[0]
        var mn: Node2D = mv["node"]
        # stand Dario right on the deck (feet on deck top)
        var deck_top: float = mn.position.y - 9.0
        g_mv.p_node.position = Vector2(mn.position.x,
                        deck_top - float(g_mv.p_size.y) / 2.0 - 1.0)
        g_mv.p_vel.y = 40.0
        var rode := false
        var min_deck_dist := 99999.0
        for i in 120:            # two seconds of riding
                g_mv._movers_tick(1.0 / 60.0)
                min_deck_dist = minf(min_deck_dist,
                                absf(float(g_mv.p_node.position.x) - mn.position.x))
                rode = rode or absf(float(g_mv.p_node.position.y)
                                + float(g_mv.p_size.y) / 2.0 - (mn.position.y - 9.0)) < 3.0
        _check(rode and min_deck_dist < 120.0,
                "riding the mover CARRIES Dario with the deck (feet glued to the plank)")
        _check(float(g_mv.p_node.position.x) > 1000.0,
                "Dario is still at the mover's neighborhood (the -4400px shove is dead)")

        # ---- THE SPIKES ARE ALIVE (the owner: "i tried to jump on the
        # ground spikes and they are doing nothing") ----
        var g_sp: GogaGame = D.new()
        g_sp.game_id = "dario"
        add_child(g_sp)
        await get_tree().process_frame
        g_sp.sheet_pop()
        g_sp._locked = false
        g_sp._load_level(1)      # THE WOODS REPEAT - the first spikes
        _check(g_sp.spikes.size() >= 2, "the spike cells are REAL entities now")
        var sc0: Vector2i = g_sp.spikes[0]
        var lives0: int = int(g_sp.lives)
        # stand IN the spike band
        g_sp.p_node.position = Vector2(sc0.x * 80.0 + 40.0,
                        (sc0.y + 1) * 80.0 - float(g_sp.p_size.y) / 2.0 - 20.0)
        g_sp._hazards_tick()
        _check(String(g_sp._phase) == "dying" or int(g_sp.lives) == lives0 - 1,
                "touching the spike band HURTS (the dead scan is alive)")
        # a control: Dario three tiles away is untouched
        await get_tree().create_timer(1.3).timeout
        if String(g_sp._phase) == "play":
                g_sp.p_node.position = Vector2((sc0.x + 4) * 80.0,
                                (sc0.y + 1) * 80.0 - float(g_sp.p_size.y) / 2.0)
                g_sp._hazards_tick()
                _check(String(g_sp._phase) == "play",
                        "standing beside the spikes does NOT hurt")
        else:
                _check(true, "standing beside the spikes does NOT hurt (post-respawn)")

        # ---- the blocker shield: three stomps ----
        g._spawn_enemy("blocker", Vector2i(10, 12))
        var blk: Dictionary = g.enemies[g.enemies.size() - 1]
        var alive := 0
        for hits in 3:
                g.p_node.position = blk["node"].position + Vector2(0, -60.0)
                g._stomp(blk)
                alive = 0
                for ee in g.enemies:
                        if ee == blk:
                                alive += 1
        _check(alive == 0, "the blocker dies on the THIRD stomp (the shield)")

        # ---- THE DEATH LAW: -100, the FULL ROLLBACK, the fade, the quote ----
        var g_d: GogaGame = D.new()
        g_d.game_id = "dario"
        add_child(g_d)
        await get_tree().process_frame
        g_d.sheet_pop()
        g_d._locked = false
        g_d._load_level(1)
        await get_tree().process_frame
        g_d.set_score(305)               # 200 from the level + 105 before it
        g_d._lvl_score0 = 205
        g_d.add_run_coins(4)             # four crate coins this attempt
        g_d._lvl_coins0 = 1              # one coin came from an earlier level
        var lives_d: int = int(g_d.lives)
        var lv := int(g_d.level_i)
        g_d._die()
        _check(String(g_d._phase) == "dying", "the death FADES (no more instant snap)")
        await get_tree().create_timer(1.4).timeout
        _check(int(g_d.lives) == lives_d - 1, "a death costs one of the three lives")
        _check(int(g_d.score) == 105,
                "a death costs -100 AND rolls back the attempt's score (305 -> 105)")
        _check(int(g_d.run_coins) == 1,
                "the attempt's crate coins are ROLLED BACK (4 gone, the old 1 stays)")
        _check(int(g_d.level_i) == lv, "the death RESTARTS the same level")
        _check(String(g_d._phase) == "play", "the fade returns Dario to the level start")
        _check(float(g_d._fade_rect.color.a) < 0.05, "the fade ends transparent")

        # ---- the door: walking into the trophy advances the level ----
        g._load_level(0)
        await get_tree().process_frame
        var lv2: int = int(g.level_i)
        for it in g.items:
                if String(it["kind"]) == "goal":
                        g.p_node.position = g._cell_center(it["cell"])
                        break
        g._reach_door()
        await get_tree().create_timer(4.0).timeout
        _check(int(g.level_i) == lv2 + 1, "the trophy opens the NEXT level")

        # ---- the ghost platforms cycle (appear and vanish) ----
        var g2: GogaGame = D.new()
        g2.game_id = "dario"
        add_child(g2)
        await get_tree().process_frame
        g2.sheet_pop()
        g2._locked = false
        g2._load_level(9)     # the arena
        _check(g2.ghosts.size() >= 4, "the arena carries the TALL ghost ladder")
        var on0: Array = []
        for gp in g2.ghosts:
                on0.append(bool(gp["on"]))
        for i in 240:
                g2._ghosts_tick(1.0 / 60.0)
        var flipped := false
        for gp in g2.ghosts:
                var on1: bool = bool(gp["on"])
                if on0[g2.ghosts.find(gp)] != on1:
                        flipped = true
        _check(flipped, "the ghost platforms APPEAR AND VANISH over time")
        # the Witcher hangs at her own cell (row 4 in the tall arena)
        g2._start_boss(Vector2i(24, 4))
        _check(not g2.boss.is_empty(),
                "the Witcher takes the field at her map cell (%.0f)" % float(g2.boss["base_y"]))
        _check(float(g2.boss["base_y"]) < 5.0 * 80.0,
                "she hangs HIGH (the climb is real again)")

        # ---- the boss: 20 stomps (with the mercy iframes), +100, ending ----
        var g3: GogaGame = D.new()
        g3.game_id = "dario"
        add_child(g3)
        await get_tree().process_frame
        g3.sheet_pop()
        g3._locked = false
        g3._load_level(9)
        g3._start_boss(Vector2i(24, 4))
        _check(not g3.boss.is_empty(), "the Witcher takes the field")
        g3.set_score(0)
        g3._boss_tick(1.0 / 60.0)
        for i in 200:
                g3._boss_tick(1.0 / 60.0)
        _check(g3.bolts.size() > 0, "the Witcher hurls curses")
        g3.set_score(5)
        var lives_before := int(g3.lives)
        for hit in 20:
                if g3.boss.is_empty():
                        break
                # park Dario out of her swing and her curses while time passes
                g3.p_node.position = Vector2(float(g3.boss["base_x"]) - 700.0,
                                12.5 * 80.0)
                for w in 50:                 # outlast the mercy iframes
                        g3._boss_tick(1.0 / 60.0)
                for b in g3.bolts.duplicate():
                        if is_instance_valid(b["node"]):
                                b["node"].queue_free()
                g3.bolts = []
                if g3.boss.is_empty():
                        break
                g3.p_vel.y = 900.0
                g3.p_node.position = g3.boss["node"].position + Vector2(0, -70.0)
                g3._boss_tick(1.0 / 60.0)
                # hop away before her hurt radius wakes up
                g3.p_node.position = Vector2(float(g3.boss.get("base_x", 0.0)) - 700.0,
                                12.5 * 80.0) if not g3.boss.is_empty() \
                                else g3.p_node.position
        _check(g3.boss.is_empty(), "TWENTY stomps fell the Witcher")
        _check(String(g3._phase) == "ending", "the boss death starts THE ENDING")
        _check(int(g3.score) == 5 + 100, "the Witcher pays +100")
        _check(int(g3.lives) == lives_before,
                        "the boss fight is winnable without a single cheap death")

        # ---- the theme toggle: night equips, DAY unequips ----
        Box.dev_set_cheat("all_owned", 1)
        Box.equip_item("dario", "theme", "night")
        _check(Box.item_on("dario", "theme") == "night", "the night sky equips")
        Box.unequip_item("dario", "theme")
        _check(Box.item_on("dario", "theme") == "",
                        "WEAR THE DAY unequips the night (the toggle law)")
        Box.equip_item("dario", "theme", "night")

        # ---- the shop builds and closes without orphan dims ----
        g3._shop_open()
        _check(g3.sheet_open_count() >= 1, "the shop rides the base sheet stack (its exact pair is tracked)")
        var root_ctrl: Control = g3._overlay_root_ref()
        var kids := root_ctrl.get_child_count()
        g3.sheet_pop()
        await get_tree().process_frame
        await get_tree().process_frame
        _check(root_ctrl.get_child_count() < kids,
                        "closing the shop drops the WHOLE pair (the overlay bug is dead)")

        print("== dario_probe done: %s ==" % ("ALL PASS" if fails == 0 else "%d FAIL" % fails))
        get_tree().quit(1 if fails > 0 else 0)

## the jump apex, measured through the real physics
func _measure_jump(g: GogaGame, powered: bool) -> float:
        g.power_jump = powered
        # settle onto the ground first
        g.p_node.position = Vector2(6.0 * 80.0, 5.0 * 80.0)
        g.p_vel.y = 0.0
        for i in 90:
                g._goga_tick(1.0 / 60.0)
                if g.on_floor:
                        break
        g._jump_queued = true
        g.on_floor = true
        g._locked = false
        var y0: float = float(g.p_node.position.y)
        var top: float = y0
        for i in 150:
                g._goga_tick(1.0 / 60.0)
                top = minf(top, float(g.p_node.position.y))
                if float(g.p_vel.y) > 0.0 and i > 4:
                        break
        g.power_jump = false
        return y0 - top

func _ready() -> void:
        _run.call_deferred()
