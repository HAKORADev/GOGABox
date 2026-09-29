extends Node
## v044 eye pass - boots the REAL main scene, then walks the seats the
## owner's order touches: the feed, the pre-play page of a BOTH-platform
## game, and the pre-play page of a PHONE-ONLY game on the pc rig (the
## honest PHONE ONLY button). Screenshots land in /tmp/v044_eye/.
func _ready() -> void:
        var dir := DirAccess.open("/tmp")
        if not dir.dir_exists("v044_eye"):
                dir.make_dir("v044_eye")
        # the rig home wears the shipping set (the artifact shape)
        GOGA.set_home("user://eye_rig")
        var repo_root := ProjectSettings.globalize_path("res://").path_join("../..")
        _copy(repo_root.path_join("GOGAs/games"), GOGA.games_dir())
        GOGA.reload_entries()
        var ps: PackedScene = load("res://main.tscn")
        var m: Node = ps.instantiate()
        add_child(m)
        await get_tree().create_timer(2.5).timeout
        await get_tree().process_frame
        await _shot("01_feed.png")
        # the pre-play page of a both-platform game (rally)
        var menu: Node = m.get_node_or_null("Menu")
        if menu != null:
                menu.call("_open_game_page", GameReg.get_game("rally"))
                await get_tree().create_timer(1.2).timeout
                await _shot("02_rally_page.png")
                menu.call("_close_sheet")
                await get_tree().create_timer(0.4).timeout
                # the pre-play page of a PHONE-ONLY game on the pc rig
                menu.call("_open_game_page", GameReg.get_game("jumpcube"))
                await get_tree().create_timer(1.2).timeout
                await _shot("03_jumpcube_phone_only.png")
                menu.call("_close_sheet")
                await get_tree().create_timer(0.4).timeout
                # the LAN sheet (join box - one LOCAL box, one honest line)
                menu.call("_open_lan")
                await get_tree().create_timer(1.0).timeout
                await _shot("04_lan_sheet.png")
                menu.call("_close_sheet")
                await get_tree().create_timer(0.4).timeout
                # the settings sheet (no APP UPDATES seat anymore)
                menu.call("_open_settings")
                await get_tree().create_timer(1.0).timeout
                await _shot("05_settings.png")
        print("[v044_eye] done")
        get_tree().quit(0)

func _shot(name_: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/v044_eye/" + name_)
        print("[v044_eye] shot " + name_)

func _copy(src: String, dst: String) -> void:
        DirAccess.make_dir_recursive_absolute(dst)
        var da := DirAccess.open(src)
        if da == null:
                return
        da.list_dir_begin()
        var n := da.get_next()
        while n != "":
                var s2 := src.path_join(n)
                var d := dst.path_join(n)
                if da.current_is_dir():
                        _copy(s2, d)
                else:
                        da.copy(s2, d)
                n = da.get_next()
        da.list_dir_end()
