extends Node
## v043 THE EYE PASS: the feed switcher, the discover feed, the discover
## page, the age gray-out, the search sheet's new rows - real renders
## under Xvfb, saved to tests/v043_shot/ and reviewed BY EYE.

const OUT := "res://tests/v043_shot"

func _ready() -> void:
        DirAccess.make_dir_recursive_absolute(OUT)
        # THE RIG: the pilots install (the feed needs a real world)
        GOGA.set_home("user://goga_rig")
        _wipe("user://goga_rig")
        GOGA.set_home("user://goga_rig")
        var repo_root := ProjectSettings.globalize_path("res://").path_join("../..")
        GOGA.import_path(repo_root.path_join("GOGAs/games"))
        var menu: Node = load("res://game/menu/menu.gd").new()
        add_child(menu)
        await get_tree().create_timer(2.5).timeout
        await _shot("01_all_games_feed")
        # THE SWITCHER: the arrow flips to DISCOVER (local source: the repo
        # itself served through a virtual-repo sim, so the shot needs no net)
        GogaDiscover.add_source({"kind": "local",
                        "path": repo_root.path_join("GOGAs/games")})
        menu.call("_toggle_feed_kind")
        await get_tree().create_timer(2.5).timeout
        await _shot("02_discover_feed")
        # THE DISCOVER PAGE: open the first row's page
        var rows: Array = menu.get("_discover_rows")
        if not rows.is_empty():
                menu.call("_open_discover_page", rows[0])
                await get_tree().create_timer(1.0).timeout
                await _shot("03_discover_page")
                menu.call("_close_sheet")
                await get_tree().create_timer(0.5).timeout
        # THE AGE GRAY-OUT: bump an entry's age to +18 in memory (the door
        # reads the entry dict - the profile stays unset = the ceiling law)
        var g := GameReg.get_game("rally")
        g["age"] = 18
        menu.call("_open_game_page", g)
        await get_tree().create_timer(1.0).timeout
        await _shot("04_age_locked_18")
        menu.call("_close_sheet")
        g["age"] = 7
        await get_tree().create_timer(0.4).timeout
        # THE AGE OK: the same page with the tag inside the ceiling
        menu.call("_open_game_page", g)
        await get_tree().create_timer(1.0).timeout
        await _shot("05_age_open")
        menu.call("_close_sheet")
        # THE SEARCH SHEET: the AGE + CONTENT + SUB GENRES rows
        menu.call("_open_search")
        await get_tree().create_timer(1.0).timeout
        await _shot("06_search_sheet")
        print("V043SHOT: done")
        get_tree().quit(0)

func _shot(name_: String) -> void:
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png(OUT.path_join(name_ + ".png"))
        print("V043SHOT: " + name_)

func _wipe(path: String) -> void:
        if DirAccess.dir_exists_absolute(path):
                var da := DirAccess.open(path)
                if da != null:
                        da.list_dir_begin()
                        var n := da.get_next()
                        while n != "":
                                var full := path.path_join(n)
                                if da.current_is_dir():
                                        _wipe(full)
                                else:
                                        da.remove(n)
                                n = da.get_next()
                        da.list_dir_end()
                DirAccess.remove_absolute(path)
