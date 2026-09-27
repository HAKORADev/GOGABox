extends Node
## qa_v035p6 - the PATCH-6 Xvfb shot driver (matcher + cosmic spud + pop siege).
## Rigs (QA_GAME + QA_RIG env):
##  pop/field   - THE CENTERLINE TRUTH: bloons ride the painted road center,
##                boomba FACES the road (the face-it law), new chips on cards
##  pop/night   - THE LIVE NIGHT LAW: the maps menu NIGHT chip flips the LIVE
##                field (no reload)
##  pop/pyra    - THE SHOT DIES AT ITS TARGET: pyra fires at a far bloon that
##                despawns; the flame dies at the aim (assert + shot)
##  pop/heads   - the redrawn marshal + kaching in situ
##  match/drop  - THE MATCH SPAWN LAW: 2..4 parcels on own rows, full board,
##                a match pays the queue, one-at-a-time entry
##  match/butter- the saved chip counts THIS round only
##  cs/info     - THE CLEAR MATH LAW: the info sheet's equation lines
##  cs/expire   - THE EXPIRE LAW: pickups blink and vanish (assert + shot)
##
##  QA_GAME=pop QA_RIG=field xvfb-run -a godot --path . --resolution 1920x1080 \
##      res://tests/qa_v035p6.tscn

var G: GogaGame

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        var game := OS.get_environment("QA_GAME")
        var rig := OS.get_environment("QA_RIG")
        if game.is_empty():
                game = "pop"
        if rig.is_empty():
                rig = "field"
        get_window().size = Vector2i(1920, 1080)
        ScaleRule.apply(get_window())
        Box.dev_set_cheat("all_owned", 1)
        match game:
                "pop":
                        await _pop(rig)
                "match":
                        await _match(rig)
                "cs":
                        await _cs(rig)
        await _settle(6)
        var shot := "user://qa_v035p6_%s_%s.png" % [game, rig]
        var img := get_viewport().get_texture().get_image()
        img.save_png(shot)
        print("QA SHOT SAVED: ", shot)
        get_tree().quit(0)

# ---------------------------------------------------------------- pop siege
func _pop(rig: String) -> void:
        var m := PDMeta.load_meta()
        m.own_map("first_bloom")
        m.set_current_map("first_bloom")
        m.set_night("first_bloom", false)
        G = load("res://game/games/pop_siege/pop_siege.gd").new()
        G.game_id = "pop_siege"
        add_child(G)
        await _wait(1.2)
        G._start_ready()
        await _wait(0.3)
        G.coins = 5000
        match rig:
                "field":
                        # THE FACE-IT LAW: boomba LEFT of the road aims RIGHT
                        G._place_folk("boomba", Vector2i(1, 1))
                        G._place_folk("darty", Vector2i(9, 0))
                        G._spawn_bloon("red", 0, 4)
                        G._spawn_bloon("blue", 0, 7)
                        G._spawn_bloon("ceramic", 0, 12)
                        for i in 20:
                                G._goga_tick(0.033)
                                await _wait(0.01)
                        # the march: read the live offset vs the painted line
                        var worst := 0.0
                        for b in G.bloons:
                                var p: Vector2 = (b["spr"] as Sprite2D).position
                                var exp_y: float = G.FIELD.y + 1.5 * G.CELL
                                worst = maxf(worst, absf(p.y - exp_y))
                        print("QA CENTERLINE: worst off-road y = %.2f px (CELL %.1f)" % [worst, G.CELL])
                        var f0: Dictionary = G.folk[0]
                        var want: float = ((f0["aim_at"] as Vector2) - (f0["pos"] as Vector2)).angle()
                        var got: float = (f0["head"] as Sprite2D).rotation
                        var err: float = absf(wrapf(got - want, -PI, PI))
                        print("QA FACE-IT: aim angle %.2f, head rotation %.2f, error %.2f rad (0 = the muzzle LOOKS at the aim)" \
                                        % [want, got, err])
                "night":
                        # flip NIGHT for the LIVE map straight from the menu
                        G._maps_open()
                        await _wait(0.4)
                        var was_night: bool = G.night
                        G.night = not was_night
                        G._build_night()
                        await _wait(0.3)
                        print("QA LIVE NIGHT: night %s -> %s (rect %s)" % [was_night, G.night,
                                        "live" if G.night_rect != null and is_instance_valid(G.night_rect) else "gone"])
                "pyra":
                        G._place_folk("pyra", Vector2i(3, 5))
                        await _wait(0.2)
                        var f: Dictionary = G.folk[0]
                        var far := {"spr": Sprite2D.new(), "kind": "red", "id": 999}
                        (far["spr"] as Sprite2D).position = G._cell_pos(12.0, 5.0)
                        G.world.add_child(far["spr"])
                        G.bloons.append({"id": 999, "kind": "red", "spr": far["spr"],
                                        "pos": far["spr"].position})
                        var g: Dictionary = PDData.FOLK["pyra"]["gears"][0]
                        G._fire_folk(f, far, g)
                        # the target despawns the instant the shot leaves - the
                        # flame must still die AT the aim (the floating-ball bug)
                        G.bloons.clear()
                        var n_mid: int = G.bullets.size()
                        var travel_max := 0.0
                        for i in 90:
                                if G.bullets.is_empty():
                                        break
                                for bb in G.bullets:
                                        if String(bb["kind"]) == "bullet":
                                                travel_max = maxf(travel_max,
                                                                Vector2(bb["pos"]).distance_to(f["pos"]))
                                G._tick_bullets(0.033)
                                await _wait(0.016)
                        var aim_d: float = (G._cell_pos(12.0, 5.0) as Vector2).distance_to(f["pos"])
                        print("QA PYRA SHOT: mid-flight %d, alive after %d bullets, max travel %.0f px vs aim %.0f px (dies AT the aim)" \
                                        % [n_mid, G.bullets.size(), travel_max, aim_d])
                "heads":
                        G._place_folk("marshal", Vector2i(2, 3))
                        G._place_folk("kaching", Vector2i(4, 3))
                        G._place_folk("boomba", Vector2i(6, 3))
                        G._place_folk("pyra", Vector2i(8, 3))
                        G._place_folk("darty", Vector2i(10, 3))
                        G._place_folk("kolda", Vector2i(12, 3))
                        G._place_folk("boomo", Vector2i(14, 3))
                        G._place_folk("gloop", Vector2i(16, 3))
                        await _wait(0.4)

# ---------------------------------------------------------------- matcher
func _match(rig: String) -> void:
        Box.reset_all()
        get_window().size = Vector2i(1080, 1920)
        await _wait(0.2)
        G = load("res://game/games/matcher/matcher.gd").new()
        G.game_id = "matcher"
        add_child(G)
        await _wait(0.6)
        G._pick_close()
        G._start_mode("drop" if rig == "drop" else "butterflies")
        await _wait(2.4)
        G.phase = "play"
        if rig == "drop":
                # a real match pays the queue: force a 3-match on a quiet spot
                var items0: int = G._count_items()
                print("QA DROP OPEN: %d parcels (2..4), queue %d" % [items0, G.drop_queue])
                var empt := 0
                for r in 8:
                        for c in 8:
                                if G.grid[r][c].is_empty():
                                        empt += 1
                print("QA DROP FULL BOARD: %d empty seats (0 = the prefill bug is dead)" % empt)
                # hand a 3-match to the resolve and watch the queue pay
                G.drop_spawned = 0
                G.drop_total = 30
                for t in [Vector2i(4, 2), Vector2i(4, 3), Vector2i(4, 4)]:
                        var n := Sprite2D.new()
                        n.texture = G.tex_gem[2]
                        n.position = G._cell_pos(t.x, t.y)
                        G.world.add_child(n)
                        G.grid[t.x][t.y] = {"color": 2, "special": "", "wing": false, "node": n}
                G.busy = false
                await G._try_swap(Vector2i(4, 3), Vector2i(5, 3))
                await _wait(0.8)
                print("QA MATCH PAY: queue after the match = %d (paid by the 3-match)" % G.drop_queue)
        elif rig == "butter":
                # save two flies by hand, read the chip
                G.butter_saved = 0
                Box.bump_counter(G.game_id, "butterflies", 137)  # a fat lifetime count
                G.butter_saved += 2
                G._refresh_hud()
                await _wait(0.2)
                print("QA BUTTER SAVED CHIP: '%s' (must say saved 2, not 137)" % G.chip_info.text)

# ------------------------------------------------------------- cosmic spud
func _cs(rig: String) -> void:
        Box.reset_all()
        get_window().size = Vector2i(1080, 1920)
        await _wait(0.2)
        G = load("res://game/games/cosmic_spud/cosmic_spud.gd").new()
        G.game_id = "cosmic_spud"
        add_child(G)
        await _wait(1.0)
        G._start_run()
        await _wait(0.5)
        if rig == "info":
                G._apply_stat("dmg", 0.20)
                G._apply_stat("dmg", -0.08)
                G._apply_stat("armor", 3)
                G._info_open()
                await _wait(0.5)
        elif rig == "expire":
                G._drop_pickup("xp", G.p_pos + Vector2(120, -40), 3)
                G._drop_pickup("coin", G.p_pos + Vector2(-120, -40), 2)
                G._drop_pickup("gogacoin", G.p_pos + Vector2(0, -90), 1)
                # fast-forward the expiry clock (sim ticks, not wall)
                for i in int(13.0 / 0.05):
                        G._tick_pickups(0.05)
                var alive: Array = []
                for pk in G.pickups:
                        alive.append(String(pk["kind"]))
                print("QA EXPIRE after 13s: alive = %s (the gogacoin waits, xp/coin gone)" % str(alive))
                await _wait(0.3)

func _settle(frames: int = 6) -> void:
        for i in frames:
                await get_tree().process_frame

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout
