extends Node
## qa_v038p7 - the v0.3.8-7 evidence rig. Headless asserts (THE FEED TRUTH
## order law + the economy bumps) + real shots for the rig: the feed order,
## the slasher optionals outlines, and the geometry flip puff EXIT direction
## (two frames per flip; the warm centroid must MOVE AWAY from the square).
##
##   godot --path . res://tests/qa_v038p7.tscn   (on the Xvfb rig)
##   godot --headless --path . res://tests/qa_v038p7.tscn   (asserts only,
##   the shots come out black - run the real thing on the rig)

var checks := 0
var fails := 0
var OUT := "/tmp/qa387"

func ck(cond: bool, what: String) -> void:
        checks += 1
        if cond:
                print("[PASS] ", what)
        else:
                fails += 1
                print("[FAIL] ", what)

func _ready() -> void:
        for a in OS.get_cmdline_user_args():
                if a.begins_with("--out="):
                        OUT = a.split("=")[1]
        DirAccess.make_dir_recursive_absolute(OUT)
        _run.call_deferred()

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout

func _shot(name_: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        img.save_png("%s/%s.png" % [OUT, name_])
        print("[qa] shot ", name_)

# ---------------------------------------------------------------- feed law
func _t_feed() -> void:
        print("== A. THE FEED TRUTH ==")
        Box.reset_all()
        Roadmap.tick()
        # unlock OUT of catalog order: dario, then rally, then lanes
        Box.unlock_game("dario", 0)
        Box.unlock_game("rally", 0)
        Box.unlock_game("lanes", 0)
        Roadmap.tick()
        var owned: Array = []
        for r in Roadmap.feed_rows():
                if int(r["bucket"]) == 0:
                        owned.append(String(r["g"]["id"]))
        ck(String(owned[0]) == "snake",
                "snake (the free starter) leads the owned block (got %s)" % [owned])
        ck(owned.find("rally") < owned.find("lanes") \
                        and owned.find("lanes") < owned.find("dario"),
                "owned block is CATALOG order despite the acquisition order "
                + "dario->rally->lanes (%s)" % [owned])
        var rally_ord := -1
        for r in Roadmap.feed_rows():
                if String(r["g"]["id"]) == "rally":
                        rally_ord = int(r["ord"])
        ck(rally_ord == 1,
                "rally's ord is its CATALOG index (1), not its acquisition rank")
        # under the all_owned cheat: the whole playable shelf, release order
        Box.dev_set_cheat("all_owned", 1)
        Roadmap.tick()
        var ids: Array = []
        for r in Roadmap.feed_rows():
                ids.append(String(r["g"]["id"]))
        var want := ["snake", "rally", "lanes", "slasher", "hopper", "merge",
                "dario", "xo", "matcher", "invaders", "cosmic_spud",
                "pop_siege", "geometry", "maze", "domino", "chess"]
        ck(ids.slice(0, 16) == want,
                "the cheat feed reads snake->pong->...->chess, release order (%s...)" \
                        % [ids.slice(0, 5)])
        ck(ids.size() > 16 and ids[16] == "fourline",
                "the SOON teasers trail the shelf in catalog order too (%s)" \
                        % [ids.slice(16, mini(ids.size(), 19))])
        Box.dev_set_cheat("all_owned", 0)
        Box.reset_all()

        # ---- the economy bumps ----
        print("== B. THE ECONOMY BUMPS ==")
        ck(int(GameReg.get_game("lanes")["coin_div"]) == 500,
                "space dash bonus /500")
        ck(int(GameReg.get_game("slasher")["coin_div"]) == 30,
                "fruit slasher bonus /30")
        ck(int(GameReg.get_game("merge")["coin_div"]) == 100,
                "2048 4x4 bonus /100")
        var MO := load("res://game/games/merge/merge2048.gd")
        ck(int(MO.SIZES["6"]["div"]) == 400 and int(MO.SIZES["8"]["div"]) == 1200,
                "2048 size scaling /400 + /1200")
        var L := load("res://game/games/lanes/lanes.gd")
        ck(int(L.COIN_KILLS_MIN) == 200 and int(L.COIN_KILLS_MAX) == 200,
                "space dash coin every 200 kills")

func _run() -> void:
        await _t_feed()
        if fails > 0:
                print("== qa_v038p7: %d/%d FAIL - stopping before the shots ==" \
                                % [fails, checks])
                get_tree().quit(1)
                return

        # ------------------------------------------------ the feed shot
        print("== C. THE SHOTS ==")
        Box.dev_set_cheat("all_owned", 1)
        Roadmap.tick()
        var ps: PackedScene = load("res://main.tscn")
        var m: Node = ps.instantiate()
        add_child(m)
        await _wait(2.2)
        # scroll the feed down to the ALL GAMES grid
        if m.has_method("get") and m.get("_feed_scroll") != null:
                m.get("_feed_scroll").scroll_vertical = 1400
        await _wait(0.4)
        await _shot("feed_order")
        m.queue_free()
        await _wait(0.4)

        # -------------------------------------------- the slasher sheet
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        var S: GogaGame = load("res://game/games/slasher/slasher.gd").new()
        S.game_id = "slasher"
        add_child(S)
        await _wait(1.0)
        if String(S.get("_phase")) != "options":
                S._show_options()
        await _wait(0.5)
        await _shot("slasher_options")
        S.queue_free()
        await _wait(0.3)

        # --------------------------------------- the geometry flip puffs
        # THE EXIT DIRECTION, read from the puff node itself (coordinate-
        # free - the census bands can fight the rotated render, the node's
        # own direction cannot lie): after a flip the puff must sit on the
        # side being left AND its emission direction must point the SAME
        # way - AWAY from the square, off that side (the v0.3.8-7 fix).
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        get_window().size = Vector2i(1920, 1080)
        await _wait(0.2)
        var G: GogaGame = load("res://game/games/geometry/geometry.gd").new()
        G.game_id = "geometry"
        add_child(G)
        await _wait(0.8)
        G.probe_reset(20260911)
        G.sheet_pop()
        await _wait(0.3)

        # FLIP FROM THE GROUND: puff below the square, direction DOWN.
        var p: Dictionary = G.player
        p["g"] = 1
        p["ground"] = true
        p["vy"] = 0.0
        G._flip_gravity(0.42)
        await get_tree().process_frame
        var puff := _find_puff(G)
        ck(not puff.is_empty(), "ground flip: the puff node exists")
        if not puff.is_empty():
                ck(int(puff["dir_y"]) > 0,
                        "ground flip: the puff MOVES DOWN off the ground (dir.y=%+.2f)" \
                                % [float(puff["dir_y"])])
                ck(puff["below"], "ground flip: the puff sits BELOW the square")
                ck(int(puff["dir_y"]) > 0 == bool(puff["below"]),
                        "ground flip: direction MATCHES the seat (away from the square)")
        await _shot("flip_from_ground")
        # settle the square back on the ground (the flip left it sailing)
        p["g"] = 1
        p["ground"] = true
        p["vy"] = 0.0
        await _wait(0.8)
        # FLIP FROM THE ROOF: puff above the square, direction UP.
        p = G.player
        p["g"] = -1
        p["ground"] = true
        p["vy"] = 0.0
        G._flip_gravity(0.42)
        await get_tree().process_frame
        puff = _find_puff(G)
        ck(not puff.is_empty(), "roof flip: the puff node exists")
        if not puff.is_empty():
                ck(int(puff["dir_y"]) < 0,
                        "roof flip: the puff MOVES UP off the roof (dir.y=%+.2f)" \
                                % [float(puff["dir_y"])])
                ck(not puff["below"], "roof flip: the puff sits ABOVE the square")
                ck((int(puff["dir_y"]) < 0) == (not bool(puff["below"])),
                        "roof flip: direction MATCHES the seat (away from the square)")
        await _shot("flip_from_roof")
        G.queue_free()

        print("== qa_v038p7: %d checks, %d fails ==" % [checks, fails])
        print("== RESULT: %s ==" % ("ALL PASS" if fails == 0 else "FAIL"))
        get_tree().quit(1 if fails > 0 else 0)

## The live flip puff (CPUParticles2D wearing the p_puff texture). Returns
## {dir_y, below} - the emission direction's y sign and whether the puff
## sits BELOW the square (both in the game's own local space, transform-
## proof). {} when no live puff exists.
func _find_puff(G: Node) -> Dictionary:
        var sq_y: float = float(G.player["y"])
        var best := {}
        for c in G.get_children():
                if c is CPUParticles2D and c.texture != null \
                                and String(c.texture.resource_path).contains("p_puff"):
                        # keep the LAST match: the flip puff is appended after
                        # the setup-time rocket trail (which also wears p_puff)
                        var dy: float = float(c.direction.y)
                        var below := float(c.position.y) > sq_y
                        best = {"dir_y": dy, "below": below}
        return best
