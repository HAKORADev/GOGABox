extends Node
## v0413_ui_film (v041-3) - THE VISION LAW for the two box-wide fixes:
## snaps the REAL menu's feed (the grayed tiles: rounded thumb tops + the
## true gray), the pre-play page and the SETTINGS sheet (the widened
## panel). The frames are eyeballed with the Read tool.
## Run: xvfb DISPLAY=:96 godot --path . res://tests/v0413_ui_film.tscn

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        DirAccess.make_dir_recursive_absolute("/tmp/td_ui")
        Box.reset_all()          # the fresh-save truth: snake owned, the rest
                                 # LOCKED/GATED - the gray law's live read
        DisplayServer.window_set_size(Vector2i(810, 1440))
        await _wait(0.4)
        var main_scene: Node = load("res://main.tscn").instantiate()
        add_child(main_scene)
        await _wait(3.2)
        await _snap("feed")
        # THE GRAY LAW's studio read: the production LOCKED/GATED/CHARGING
        # tiles, photographed as the feed builds them
        var menu00 := _find_menu(main_scene)
        if menu00 != null:
                var tray := Control.new()
                tray.set_anchors_preset(Control.PRESET_FULL_RECT)
                menu00.add_child(tray)
                var states := [["LOCKED", "pong"], ["GATED", "chess"],
                        ["LOCKED", "towerdestroyer"]]
                var row_y := 90.0
                for st_info in states:
                        var g: Dictionary = GameReg.get_game(String(st_info[1]))
                        if g.is_empty():
                                continue
                        var tile: Control = menu00.call("_tile", g, String(st_info[0]))
                        tile.position = Vector2(40, row_y)
                        tray.add_child(tile)
                        row_y += 330.0
                await _wait(0.6)
                await _snap("gray_tiles")
                tray.queue_free()
                await _wait(0.3)
        # scroll to the LOCKED/GATED block: the gray law's live read
        var menu0 := _find_menu(main_scene)
        if menu0 != null:
                var scrolls: Array = menu0.find_children("*", "BoxScroll", true, false)
                for sc in scrolls:
                        var bs: Control = sc
                        if bs.size.y > 800.0:
                                (sc as BoxScroll).scroll_vertical = 7400
                                await _wait(0.5)
                                await _snap("feed_locked")
                                break
        # a locked tile's gray + the rounded thumb tops live in the feed; the
        # dev cheat all_owned would light them - keep the default wallet so
        # LOCKED/GATED tiles show their gray
        var menu := _find_menu(main_scene)
        if menu != null:
                # the pre-play page of an owned game (snake is always owned)
                menu.call("_open_game_page", GameReg.get_game("snake"))
                await _wait(0.6)
                await _snap("preplay")
                menu.call("_close_sheet")
                await _wait(0.4)
                # the settings sheet: THE MENU WIDTH LAW's live read
                menu.call("_open_settings")
                await _wait(0.6)
                await _snap("settings")
                menu.call("_close_sheet")
                await _wait(0.4)
                # the guide sheet (a widened sheet with real text rows)
                menu.call("_open_guide", GameReg.get_game("snake"))
                await _wait(0.6)
                await _snap("guide")
                menu.call("_close_sheet")
        print("[ui film] done")
        get_tree().quit(0)

func _find_menu(root: Node) -> Node:
        var stack := [root]
        while not stack.is_empty():
                var n: Node = stack.pop_back()
                if n.get_script() != null and String(n.get_script() \
                                                .resource_path).ends_with("menu.gd"):
                        return n
                for c in n.get_children():
                        stack.append(c)
        return null

func _wait(sec: float) -> void:
        await get_tree().create_timer(sec).timeout

func _snap(tag: String) -> void:
        await _wait(0.05)
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/td_ui/%s.png" % tag)
        print("[ui film] snap ", tag)
