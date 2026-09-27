extends Node
## qa_v035p4 - the PATCH-4 Xvfb shot driver for POP SIEGE. Rigs (QA_RIG env):
##   boom1..boom6 - THE BOMBER TIMELINE: one shell, six moments (the owner:
##                  "screenshot its latest moments, you will see how buggy
##                  it is") - the shot set proves the bomb dies AT its blast
##                  and the smoke fades to NOTHING (nothing floats)
##   night     - THE NIGHT LAW v2: the WHOLE viewport sleeps (tall props too)
##   doors     - THE RANDOM DOORS: three waves rolled by the new law
##   field     - the fillet march: bloons ride the beaten track
##   maps      - the rebuilt 30-map wall (loop-heavy thumbs)
##   scroll    - THE SCROLL TRUTH: shop scrolled down, refreshed, STILL THERE
##   DISPLAY=:95 QA_RIG=night godot --path . --resolution 1920x1080 res://tests/qa_v035p4.tscn

var G: GogaGame

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.dev_set_cheat("all_owned", 1)
        get_window().size = Vector2i(1920, 1080)      # the landscape law
        ScaleRule.apply(get_window())
        var rig := OS.get_environment("QA_RIG")
        if rig.is_empty():
                rig = "field"
        if rig.begins_with("boom"):
                var m := PDMeta.load_meta()
                m.own_map("twin_bloom")
                m.set_current_map("twin_bloom")
        if rig == "night":
                var m := PDMeta.load_meta()
                m.own_map("stump_waltz")
                m.set_current_map("stump_waltz")
                m.set_night("stump_waltz", true)
        elif rig == "doors":
                var m := PDMeta.load_meta()
                m.own_map("mirage_x")
                m.set_current_map("mirage_x")
                m.set_night("mirage_x", false)
        else:
                var m := PDMeta.load_meta()
                m.set_night(m.current_map(), false)
        G = load("res://game/games/pop_siege/pop_siege.gd").new()
        G.game_id = "pop_siege"
        add_child(G)
        await get_tree().create_timer(1.2).timeout
        match rig:
                "boom1":
                        await _boom_stage(0.0, "boom1")
                "boom2":
                        await _boom_stage(0.10, "boom2")
                "boom3":
                        await _boom_stage(0.20, "boom3")
                "boom4":
                        await _boom_stage(0.34, "boom4")
                "boom5":
                        await _boom_stage(0.55, "boom5")
                "boom6":
                        await _boom_stage(0.95, "boom6")
                "night":
                        G._start_ready()
                        await _wait(0.2)
                        G.coins = 3000
                        G._place_folk("darty", Vector2i(6, 5))
                        G._spawn_bloon("red", 0, 2)
                        for i in 12:
                                G._goga_tick(0.033)
                                await _wait(0.01)
                        await _wait(0.3)
                "doors":
                        G._start_ready()
                        await _wait(0.2)
                        G._queue_wave()
                        G._queue_wave()
                        G._queue_wave()
                        for i in 46:
                                G._goga_tick(0.033)
                                await _wait(0.01)
                        await _wait(0.3)
                "field":
                        G._start_ready()
                        await _wait(0.2)
                        G.coins = 5000
                        G._place_folk("darty", Vector2i(4, 5))
                        G._place_folk("boomba", Vector2i(2, 6))
                        G._spawn_bloon("red", 0, 3)
                        G._spawn_bloon("blue", 0, 5, ["red", "green"])
                        G._spawn_bloon("ceramic", 0, 2, ["zebra", "lead"], "", 0.0)
                        for i in 26:
                                G._goga_tick(0.033)
                                await _wait(0.01)
                        await _wait(0.2)
                "maps":
                        G._start_ready()
                        await _wait(0.2)
                        G._maps_open()
                        await _wait(0.5)
                "scroll":
                        G._start_ready()
                        await _wait(0.2)
                        G._shop_open()
                        await _wait(0.4)
                        var sc: BoxScroll = G._find_box_scroll((G._sheet_stack.back() as Dictionary)["cc"])
                        sc.scroll_vertical = 900
                        await _wait(0.2)
                        G._shop_refresh()          # a buy's refresh
                        await _wait(0.5)
        await _settle(2 if rig.begins_with("boom") else 12)
        var shot := "user://qa_v035p4_%s.png" % rig
        var img := get_viewport().get_texture().get_image()
        img.save_png(shot)
        print("QA SHOT SAVED: ", shot)
        get_tree().quit(0)

## THE BOMBER TIMELINE: one shell from a fixed folk, one blast, one stage of
## its life per run. dt = the time since detonation.
func _boom_stage(dt: float, tag: String) -> void:
        G._start_ready()
        await _wait(0.2)
        var fake: Dictionary = {"pos": G._cell_pos(3, 6), "fid": "boomba", "gear": 1,
                "lvl": 1, "buffs": {"blast_f": 1.0}, "flags": {}}
        var at: Vector2 = G._cell_pos(8.0, 4.0)
        G._shell_spawn(fake, at, 3.0, 1.7, {"frags": 0, "stun": 0.0, "moab_bonus": 0.0})
        # fly the shell to its target (dur ~0.5s) with real ticks
        while G.bullets.size() > 0:
                G._tick_bullets(0.033)
                await _wait(0.016)
        # THE DETONATION just happened (the shell erased itself) - wait dt more
        if dt > 0.0:
                await _wait(dt)

func _settle(frames: int = 12) -> void:
        for i in frames:
                await get_tree().process_frame

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout
