extends Node
## r2 menu feed shot with ALL games unlocked - the real cards.
func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        DirAccess.make_dir_recursive_absolute("/tmp/menu_film")
        var main = (load("res://main.tscn") as PackedScene).instantiate()
        add_child(main)
        await get_tree().create_timer(2.6).timeout
        var menu := get_tree().root.find_child("Menu", true, false)
        # unlock every owned-path game so real thumbs render
        var reg: Array = GameReg.GAMES
        Box.earn(1000000)
        for g in reg:
                var id: String = String(g.get("id", ""))
                Box.unlock_game(String(id), 0)
        if menu != null and menu.has_method("_refresh_all"):
                menu.call("_refresh_all")
        await get_tree().create_timer(0.6).timeout
        if menu != null and menu.has_method("_nudge_feed"):
                menu.call("_nudge_feed", 700.0)
                for i in 30:
                        await get_tree().process_frame
                await get_tree().create_timer(1.3).timeout
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/menu_film/feed_cards.png")
        if menu != null and menu.has_method("_nudge_feed"):
                menu.call("_nudge_feed", 900.0)
                for i in 30:
                        await get_tree().process_frame
                await get_tree().create_timer(1.3).timeout
        img = get_viewport().get_texture().get_image()
        img.save_png("/tmp/menu_film/feed_cards2.png")
        print("[menu_film] done")
        get_tree().quit(0)
