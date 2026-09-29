extends Node
func _ready() -> void:
        var host_script: GDScript = load("res://game/core/game_host.gd")
        GOGA.set_home("user://iso_rig")
        var repo_root := ProjectSettings.globalize_path("res://").path_join("../..")
        _copy(repo_root.path_join("GOGAs/games"), GOGA.games_dir())
        GOGA.reload_entries()
        Box.reset_all()
        var router := Node2D.new()
        add_child(router)
        # the flow-test shape: every pack mounted once before the isolation
        for e in GOGA.entries():
                GOGA.mount_for(e)
        print("PROBE all packs mounted")
        GOGA._current_id = ""
        # the menu sequence the flow test runs before isolation
        for mi in 2:
                var menu: Node = load("res://game/menu/menu.gd").new()
                add_child(menu)
                await get_tree().create_timer(2.0).timeout
                menu.queue_free()
                await get_tree().process_frame
                print("PROBE menu cycle ", mi, " done")
        for round_i in 3:
                GOGA._settings["dev_cheats"] = true   # v044-1: the rig arms the master
                Box.dev_set_cheat("all_owned", 1 if round_i == 2 else 0)
                if round_i != 2:
                        Box.earn(100000)
                        Box.unlock_game("rally", 0)
                var launched: bool = host_script.launch(router, "rally")
                print("PROBE round=", round_i, " launched=", launched)
                for i in 10:
                        await get_tree().create_timer(1.0).timeout
                        var h: Node = host_script.active_host
                        print("PROBE r=", round_i, " t=", i, " host=", h != null, " game=", (h != null and h.game != null))
                        if h != null and h.game != null:
                                h._quit_to_menu()
                                await get_tree().process_frame
                                break
        get_tree().quit(0)

func _copy(src: String, dst: String) -> void:
        DirAccess.make_dir_recursive_absolute(dst)
        var da := DirAccess.open(src)
        if da == null: return
        da.list_dir_begin()
        var n := da.get_next()
        while n != "":
                var s := src.path_join(n)
                var d := dst.path_join(n)
                if da.current_is_dir(): _copy(s, d)
                else: da.copy(s, d)
                n = da.get_next()
        da.list_dir_end()
