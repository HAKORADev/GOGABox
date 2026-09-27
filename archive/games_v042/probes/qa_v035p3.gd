extends Node
## qa_v035p3 - the PATCH-3 Xvfb shot driver for POP SIEGE. Rigs (QA_RIG env):
##   field   - the siege mid-wave (single-file march, off-stage doors, aim)
##   doors   - mirage_x rotate: bloons from ALL three doors + the door chips
##   darty   - darty + longeye + boomba AIMING (the pivot + muzzle truth)
##   place   - the drag ghost + the range ring over the grid road
##   maps    - THE MAPS WALL with the DOORS chips
##   shop    - THE SHOP mid-refresh with a toast riding the pause
##   zsort   - the world sort: big props covering the small ones behind
##   DISPLAY=:95 QA_RIG=field godot --path . res://tests/qa_v035p3.tscn

var G: GogaGame

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.dev_set_cheat("all_owned", 1)
        get_window().size = Vector2i(1920, 1080)      # the landscape law
        ScaleRule.apply(get_window())
        var rig := OS.get_environment("QA_RIG")
        if rig.is_empty():
                rig = "field"
        if rig == "doors" or rig == "zsort":
                var m := PDMeta.load_meta()
                var mid := "mirage_x" if rig == "doors" else "twin_bloom"
                m.own_map(mid)          # current_map() heals unowned maps away
                m.set_current_map(mid)
        G = load("res://game/games/pop_siege/pop_siege.gd").new()
        G.game_id = "pop_siege"
        add_child(G)
        await get_tree().create_timer(1.2).timeout
        match rig:
                "field":
                        G._start_ready()
                        await _wait(0.2)
                        G.coins = 5000
                        G._spawn_bloon("red", 0, 3)
                        G._spawn_bloon("blue", 0, 5, ["red", "green"])
                        G._spawn_bloon("black", 0, 2, ["pink"], PDData.ARMOR_METAL, 4.0)
                        G._spawn_bloon("ceramic", 0, 2, ["zebra", "lead", "white"], PDData.ARMOR_ROCK, 5.0)
                        G._spawn_bloon("moab", 0, 2, ["rainbow"], "", 0.0)
                        G._place_folk("darty", Vector2i(4, 5))
                        G._place_folk("pyra", Vector2i(6, 5))
                        G._place_folk("boomba", Vector2i(2, 6))
                        G._select_folk(G.folk[0])
                        for i in 30:
                                G._goga_tick(0.033)
                                await _wait(0.01)
                        await _wait(0.3)
                "doors":
                        G._start_ready()
                        await _wait(0.2)
                        G._queue_wave()
                        G._queue_wave()
                        G._queue_wave()
                        G._queue_wave()      # wave 4 - THE BURST across all doors
                        for i in 40:
                                G._goga_tick(0.033)
                                await _wait(0.01)
                        await _wait(0.3)
                "darty":
                        G._start_ready()
                        await _wait(0.2)
                        G.coins = 5000
                        G._place_folk("darty", Vector2i(8, 5))
                        G._place_folk("longeye", Vector2i(11, 3))
                        G._place_folk("boomba", Vector2i(11, 7))
                        # targets on all sides so the heads take real bearings
                        G._spawn_bloon("red", 0, 1)
                        G._spawn_bloon("blue", 0, 1)
                        G._spawn_bloon("green", 0, 1)
                        for b in G.bloons:
                                b["dist"] = 3.0 * G.CELL
                                b["stun_t"] = 99.0      # static targets for the aim
                        G.coins = 900
                        for i in 50:
                                G._goga_tick(0.033)
                                await _wait(0.01)
                        await _wait(0.2)
                "place":
                        G._start_ready()
                        await _wait(0.2)
                        G._card_press = "boomba"
                        G._card_press_pos = Vector2(1300, 900)
                        G._begin_card_drag()
                        G._ghost_follow(G._cell_pos(7, 4))
                        await _wait(0.3)
                "maps":
                        G._start_ready()
                        await _wait(0.2)
                        G._maps_open()
                        await _wait(0.5)
                "shop":
                        G._start_ready()
                        await _wait(0.2)
                        G._shop_open()
                        await _wait(0.3)
                        G.game_toast("BOMBA JOINS THE SIEGE")
                        await _wait(0.2)
                "zsort":
                        G._start_ready()
                        await _wait(0.2)
                        G._place_folk("darty", Vector2i(6, 5))
                        await _wait(0.3)
        await _settle()
        var shot := "user://qa_v035p3_%s.png" % rig
        var img := get_viewport().get_texture().get_image()
        img.save_png(shot)
        print("QA SHOT SAVED: ", shot)
        get_tree().quit(0)

func _settle() -> void:
        for i in 12:
                await get_tree().process_frame

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout
