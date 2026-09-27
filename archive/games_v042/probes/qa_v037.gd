extends Node
## qa_v037 - the v0.3.7 Xvfb shot driver.
## Rigs (QA_RIG env):
##  maze_board   - a real Wilson maze mid-map (the board, the exit, Geoquare)
##  maze_finder  - the PATH FINDER live: the next 8 cells lit + the button
##  maze_coin    - the 5th map: the coin waiting off the route
##  maze_shop    - the maze shop (skins / themes / the finder row)
##  tower_geo    - Snowy Tower wearing the GEOMETRIC style
##  gf_lore      - the Geoquare lore box on the geometry ready gate
##
##  QA_RIG=<rig> xvfb-run -a godot --path . res://tests/qa_v037.tscn

var G: GogaGame

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        var rig := OS.get_environment("QA_RIG")
        if rig.is_empty():
                rig = "maze_board"
        get_window().size = Vector2i(1920, 1080)
        ScaleRule.apply(get_window())
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        Box.dev_set_cheat("gogacoins", 0)
        Box.earn(5000)
        await _gf(rig)
        await _settle(6)
        var shot := "user://qa_v037_%s.png" % rig
        var img := get_viewport().get_texture().get_image()
        img.save_png(shot)
        print("QA SHOT SAVED: ", shot)
        get_tree().quit(0)

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout

func _settle(frames: int) -> void:
        for i in frames:
                await get_tree().process_frame

func _find_scroll(n: Node) -> void:
                for c in n.get_children():
                        if c is BoxScroll:
                                (c as BoxScroll).scroll_vertical = 20000
                                return
                        _find_scroll(c)

func _gf(rig: String) -> void:
        var script_path := "res://game/games/maze/maze.gd"
        if rig == "tower_geo":
                script_path = "res://game/games/hopper/hopper.gd"
        elif rig == "gf_lore":
                script_path = "res://game/games/geometry/geometry.gd"
        G = load(script_path).new()
        G.game_id = "maze" if rig.begins_with("maze") \
                else ("hopper" if rig == "tower_geo" else "geometry")
        add_child(G)
        await _wait(1.0)
        match rig:
                "maze_board":
                        G.probe_reset(4242)
                        G.paused = false
                        G.phase = "run"
                        for i in 30:
                                G.probe_step(1.0 / 60.0)
                        G.paused = true
                        G.maze_layer.queue_redraw()
                        G.mark_layer.queue_redraw()
                "maze_finder":
                        G.probe_reset(4242)
                        G.paused = false
                        G.phase = "run"
                        Box.buy_item("maze", "finder", "finder", 450)
                        G.finder_used = 0
                        G.map_i = 4
                        G._update_finder_btn()
                        G._finder_tap()
                        for i in 10:
                                G.probe_step(1.0 / 60.0)
                        G.paused = true
                        G.mark_layer.queue_redraw()
                        print("[qa] finder: charges=%d left=%.1f route=%d" %
                                [G._finder_charges(), G.finder_left, G._finder_route().size()])
                "maze_coin":
                        G.probe_reset(77)
                        G.map_i = 4
                        G.paused = false
                        G.phase = "run"
                        for i in 30:
                                G.probe_step(1.0 / 60.0)
                        G.paused = true
                        print("[qa] coin map: coin=%s (the 5th map wears it)" %
                                str(G.coin))
                "maze_shop":
                        G.probe_reset(4242)
                        G.paused = false
                        G._shop_open()
                        await _wait(0.4)
                        _find_scroll(G._overlay_root_ref())
                "tower_geo":
                        Box.equip_item("hopper", "style", "geometric")
                        G._apply_geo_style()   # the live re-light (the wear path)
                        G.paused = false
                        for i in 200:
                                G.probe_step(1.0 / 60.0)
                        G.paused = true
                "gf_lore":
                        # the fresh box = the first launch: the boot told the tale
                        G.paused = false
                        await _wait(0.4)
                _:
                        pass
