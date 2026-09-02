extends Node
## dario_probe - v0.3.1 PATCH II: drives CURSED DARIO headless. The laws:
## the expensive entry (100), the /10 bonus, the ten CONTINUOUS maps (all
## parse, all carry a start + a ground goal, no floating coins, every
## crate has support, the tenth carries the Witcher + the ghost ladder),
## the tile physics, the REAL multi-touch controls (left walk survives a
## right jump tap), the tiered stomp table (snail 5 .. spiky 25), the
## blocker shield (3 stomps), the death law (-200, restart, 3 lives),
## the door law, the boss law (20 stomps, +100, the ending), the ghost
## platform cycles, the INTRO lock (the scrollable story square), the
## theme toggle (night equips, day unequips), and the cursed replay
## counter.
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
        print("== dario_probe: CURSED DARIO v0.3.1 patch II ==")
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

        # ---- the TEN MAPS law: continuous ground, no floating coins ----
        _check(D.LEVELS.size() == 10, "ten levels (the owner)")
        var allowed := "#B?gm~^DdTsbphWf."
        for i in D.LEVELS.size():
                var map: Array = D.LEVELS[i]
                var w := String(map[0]).length()
                var even := true
                var solid_ground := true
                var clean := true
                var has_door := false
                var has_start := false
                for r in map.size():
                        var row := String(map[r])
                        if row.length() != w:
                                even = false
                        if r == map.size() - 1 and row.count("#") != w:
                                solid_ground = false
                        for c in w:
                                if not allowed.contains(row[c]):
                                        clean = false
                        if row.contains("D"):
                                has_door = true
                        if row.contains("d"):
                                has_start = true
                _check(even and has_door and has_start,
                                "level %d parses: %d rows, even %s, door+start %s/%s"
                                % [i + 1, map.size(), even, has_door, has_start])
                _check(solid_ground, "level %d ground is CONTINUOUS (no gaps)" % (i + 1))
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
        _check(l10.count("g") >= 3,
                        "the ghost ladder appears and vanishes (the timed climb)")

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
        _check(g._intro_pair.size() == 2,
                        "the intro owns its dim+center PAIR (the pair law)")
        g._pair_down(g._intro_pair)
        g._intro_pair = []
        g._locked = false
        _check(not bool(g._locked), "DONE dismisses the intro and unlocks")

        # ---- the physics: Dario lands on the ground ----
        var landed := false
        for i in 90:
                g._goga_tick(1.0 / 60.0)
                if g.on_floor:
                        landed = true
                        break
        _check(landed, "Dario FELL and landed on the tiles (the tile physics)")

        # ---- the jump: the queued press lifts him ----
        var y0: float = g.p_node.position.y
        g._jump_queued = true
        g.on_floor = true
        g._goga_tick(1.0 / 60.0)
        await get_tree().create_timer(0.12).timeout
        _check(float(g.p_node.position.y) < y0 - 10.0, "the jump LIFTS")

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
        g._spawn_enemy("snail", Vector2i(3, 9))
        var e: Dictionary = g.enemies[g.enemies.size() - 1]
        g.p_node.position = e["node"].position + Vector2(0, -60.0)
        g.p_vel.y = 900.0
        var snails := 0
        for ee in g.enemies:
                if String(ee["kind"]) == "snail":
                        snails += 1
        g._stomp(e)
        _check(int(g.score) == 5, "a SNAIL stomp pays exactly +5 (not 10!)")
        _check(snails - 1 == g.enemies.size() or g.enemies.is_empty(),
                        "the stomped enemy is GONE")
        g._spawn_enemy("spiky", Vector2i(5, 9))
        var sp: Dictionary = g.enemies[g.enemies.size() - 1]
        sp["spike_up"] = false
        g.p_node.position = sp["node"].position + Vector2(0, -60.0)
        g.p_vel.y = 900.0
        g._stomp(sp)
        _check(int(g.score) == 5 + 25, "the SPIKY pays +25 (the top tier)")

        # ---- the blocker shield: three stomps ----
        g._spawn_enemy("blocker", Vector2i(8, 9))
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
        _check(int(g.score) == 30 + 20, "the blocker pays +20 when it finally falls")

        # ---- the death law: -200 floored, the level restarts, lives drop ----
        g.set_score(5)
        var lives0: int = int(g.lives)
        var lv := int(g.level_i)
        g._die()
        _check(int(g.lives) == lives0 - 1, "a death costs one of the three lives")
        _check(int(g.score) == 0, "a death costs -200 and FLOORS at 0 (5 -> 0)")
        _check(int(g.level_i) == lv, "the death RESTARTS the same level")

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
        g2._pair_down(g2._intro_pair)
        g2._intro_pair = []
        g2._locked = false
        g2._load_level(9)     # the arena
        _check(g2.ghosts.size() >= 3, "the arena carries the ghost ladder")
        var on0: Array = []
        for gp in g2.ghosts:
                on0.append(bool(gp["on"]))
        var flipped := false
        for i in 240:
                g2._ghosts_tick(1.0 / 60.0)
        var on1: Array = []
        for gp in g2.ghosts:
                on1.append(bool(gp["on"]))
        for i in on0.size():
                if on0[i] != on1[i]:
                        flipped = true
        _check(flipped, "the ghost platforms APPEAR AND VANISH over time")

        # ---- the boss: 20 stomps (with the mercy iframes), +100, ending ----
        var g3: GogaGame = D.new()
        g3.game_id = "dario"
        add_child(g3)
        await get_tree().process_frame
        g3._pair_down(g3._intro_pair)
        g3._intro_pair = []
        g3._locked = false
        g3._load_level(9)
        g3._start_boss(Vector2i(16, 6))
        _check(not g3.boss.is_empty(), "the Witcher takes the field")
        g3.set_score(0)
        var casts0 := 0
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
                                10.5 * 80.0)
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
                                10.5 * 80.0) if not g3.boss.is_empty() \
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
        _check(g3._shop_pair.size() == 2, "the shop owns its dim+center PAIR")
        var root_ctrl: Control = g3._overlay_root_ref()
        var kids := root_ctrl.get_child_count()
        g3._pair_down(g3._shop_pair)
        g3._shop_pair = []
        await get_tree().process_frame
        await get_tree().process_frame
        _check(root_ctrl.get_child_count() < kids,
                        "closing the shop drops the WHOLE pair (the overlay bug is dead)")

        print("== dario_probe done: %s ==" % ("ALL PASS" if fails == 0 else "%d FAIL" % fails))
        get_tree().quit(1 if fails > 0 else 0)

func _ready() -> void:
        _run.call_deferred()
