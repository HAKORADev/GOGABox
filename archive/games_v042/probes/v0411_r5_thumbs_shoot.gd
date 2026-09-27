extends Node
## v041-1 r5 THE THUMBNAIL FOOTAGE SHOOT (gold miner + marble popper) -
## the dw_thumb law: the REAL games' own renders, staged into their
## dramatic moment by code ("making another one by doing in-game footage
## + programmed modifications will be much better" - the owner). Raw
## frames land in /tmp/r5_thumbs for the composer
## (tools/v0411_r5_thumbs.py) to crop, grade, vignette and title.

var out_dir := "/tmp/r5_thumbs"

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        DirAccess.make_dir_recursive_absolute(out_dir)
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        ScaleRule.apply(get_window())
        await get_tree().process_frame
        await get_tree().process_frame

        # ---------------- GOLD MINER: the claw bites the big gold --------
        var GM: GDScript = load("res://game/games/goldminer/goldminer.gd")
        var g: GogaGame = GM.new()
        g.game_id = "goldminer"
        add_child(g)
        await get_tree().create_timer(0.8).timeout
        # the first-run lore card pauses the whole tree - dismiss it or the
        # game's tick never runs (the v041 rig hit the same wall)
        if g.has_method("box_story_dismiss"):
                g.call("box_story_dismiss")
        g.call("_intro_go")
        await get_tree().create_timer(0.6).timeout
        # a deeper ground: level 4 wears the BIG golds (gold_l 76px) -
        # the hero prop this thumbnail is here to sell
        g.set("level", 4)
        g.call("_populate")
        await get_tree().process_frame
        # stage: every throw, walk the chosen gold_l into the claw's path -
        # the grab, the reel home and the dust all happen NATURALLY.
        var target: Dictionary = {}
        for it in (g.get("items") as Array):
                if String(it["kind"]) == "gold_l":
                        target = it
                        break
        if target.is_empty():
                for it in (g.get("items") as Array):
                        if String(it["kind"]).begins_with("gold"):
                                target = it
                                break
        print("gm stage target: ", target.get("kind", "?"))
        var beat := 0
        var T := 0.0
        var snaps := 0
        var cool := 0
        while beat < 900 and snaps < 12:
                await get_tree().process_frame
                T += get_process_delta_time()
                cool = maxi(0, cool - 1)
                var phase := String(g.get("phase"))
                if beat % 40 == 0:
                        print("gm beat=%d phase=%s rope=%.0f carried=%s" %
                                        [beat, phase, float(g.get("rope_len")),
                                        str(not (g.get("carried") as Dictionary).is_empty())])
                if target != null and not target.is_empty() \
                                and is_instance_valid(target["spr"]):
                    if phase == "swing":
                            # park the bait deep in the aim path - it reads
                            # as an honest mid-field gold
                            var anchor: Vector2 = g.get("anchor")
                            var dir: Vector2 = g.get("claw_dir")
                            target["pos"] = anchor + dir * 700.0
                            (target["spr"] as Node2D).position = target["pos"]
                            if cool == 0:
                                    cool = 70
                                    g.call("_on_tap", Vector2.ZERO)
                    elif phase == "fly":
                            # park the bait AT the extending tip (+8px past
                            # it): the NEXT tick's sweep spans the segment
                            # that contains it - a natural grab, every time
                            var anchor2: Vector2 = g.get("anchor")
                            var dir2: Vector2 = g.get("claw_dir")
                            var plen2: float = g.get("rope_len")
                            target["pos"] = anchor2 + dir2 * (plen2 + 8.0)
                            (target["spr"] as Node2D).position = target["pos"]
                    elif (phase == "grab" or phase == "reel") and T > 0.05:
                            T = 0.0
                            await _snap("gm_%02d" % snaps)
                            snaps += 1
                beat += 1
        print("gm snaps: ", snaps)
        g.queue_free()
        await get_tree().process_frame

        # ---------------- MARBLE POPPER: the chain + the shooter ---------
        var MB: GDScript = load("res://game/games/marble/marble.gd")
        var m: GogaGame = MB.new()
        m.game_id = "marble"
        add_child(m)
        await get_tree().create_timer(0.9).timeout
        # the first-run story card (THE OLD IDOL) pauses the tree - dismiss
        if m.has_method("box_story_dismiss"):
                m.call("box_story_dismiss")
        await get_tree().create_timer(1.0).timeout
        # the game's OWN intro screen (ready_ui) is freed by _intro_go only -
        # ride the honest path: level 2, then the intro go
        m.set("level_idx", 4)   # level 4: the 1061px Mossy path - a FULL track on camera
        m.call("_intro_go")
        await get_tree().create_timer(0.9).timeout
        m.call("_begin_play")
        await get_tree().create_timer(0.5).timeout
        # pre-fill chain 0: the entry cadence is honest-slow; the thumbnail
        # needs the FULL horseshoe - spawn the run along the path directly
        var cps: Array = m.get("chains")
        if not cps.is_empty():
                var cp0 = cps[0]
                for k in range(22):
                        m.call("_spawn_one", cp0, float(k) * 99.84)
        await get_tree().create_timer(0.8).timeout
        # shoot at the chain's front marbles: live inserts + pops
        var msnaps := 0
        var mfired := 0
        for i in range(1000):
                await get_tree().process_frame
                if i % 60 == 0:
                        var c0: Array = (m.get("chains") as Array)
                        var n := 0
                        if not c0.is_empty():
                                n = (c0[0].get("marbles") as Array).size()
                        print("mb i=%d phase=%s paused=%s marbs=%d" %
                                        [i, str(m.get("phase")),
                                        str(m.get("paused")), n])
                var chains: Array = m.get("chains")
                if chains.is_empty():
                        continue
                var cp = chains[0]
                var marbs: Array = cp.get("marbles")
                if marbs.size() > 5 and mfired < 8 and i % 40 == 8:
                        var mm: Dictionary = marbs[mini(3 + mfired,
                                        marbs.size() - 1)]
                        var w: Vector2 = mm.get("pos", Vector2.ZERO)
                        if w != Vector2.ZERO:
                                m.call("_shoot_at", w)
                                mfired += 1
                if i % 9 == 4 and msnaps < 22:
                        await _snap("mb_%02d" % msnaps)
                        msnaps += 1
        print("mb snaps: ", msnaps)
        print("SHOOT_OK")
        get_tree().quit(0)

func _snap(name: String) -> void:
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png("%s/%s.png" % [out_dir, name])
        print("snapped ", name)
