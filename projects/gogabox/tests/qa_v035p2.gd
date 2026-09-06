extends Node
## qa_v035p2 - the PATCH-2 Xvfb shot driver for POP SIEGE. Rigs (QA_RIG env):
##   field   - the siege mid-wave: leveled bloons + strips + armor marching
##   place   - the drag ghost + the range ring over the grid road
##   maps    - THE MAPS WALL with its X
##   shop    - THE SHOP with its X + the fat BUY buttons
##   menu    - the upgrade panel: MAX law + gray doors
##   DISPLAY=:95 QA_RIG=field godot --path . res://tests/qa_v035p2.tscn

var G: GogaGame

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.dev_set_cheat("all_owned", 1)
        # the LANDSCAPE law: pop plays on the 1920x1080 design - the rig
        # applies the same rule the box runtime does before hosting the game
        ScaleRule.apply(get_window())
        var rig := OS.get_environment("QA_RIG")
        if rig.is_empty():
                rig = "field"
        G = load("res://game/games/pop_siege/pop_siege.gd").new()
        G.game_id = "pop_siege"
        add_child(G)
        await get_tree().create_timer(1.2).timeout
        match rig:
                "field":
                        G._start_ready()
                        await _wait(0.2)
                        # a representative march: leveled + striped + armored
                        G._spawn_bloon("red", 0, 3)
                        G._spawn_bloon("blue", 0, 5, ["red", "green"])
                        G._spawn_bloon("black", 0, 2, ["pink"], PDData.ARMOR_METAL, 4.0)
                        G._spawn_bloon("ceramic", 0, 2, ["zebra", "lead", "white"], PDData.ARMOR_ROCK, 5.0)
                        G._spawn_bloon("moab", 0, 2, ["rainbow", "ceramic", "rainbow", "ceramic", "rainbow"], "", 0.0)
                        G._spawn_bloon("gargantua", 0, 1, ["rainbow", "ceramic"], "", 0.0)
                        G._place_folk("darty", Vector2i(4, 5))
                        G._place_folk("pyra", Vector2i(6, 5))
                        G._select_folk(G.folk[0])
                        await _wait(0.4)
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
                        await _wait(0.5)
                "menu":
                        G._start_ready()
                        await _wait(0.2)
                        G._place_folk("darty", Vector2i(5, 5))
                        G.coins = 120
                        G.selected_folk = G.folk[0]
                        G._build_menu()
                        G._paint_menu_afford()
                        await _wait(0.3)
        await _settle()
        var shot := "user://qa_v035p2_%s.png" % rig
        var img := get_viewport().get_texture().get_image()
        img.save_png(shot)
        print("QA SHOT SAVED: ", shot)
        get_tree().quit(0)

func _settle() -> void:
        for i in 12:
                await get_tree().process_frame

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout
