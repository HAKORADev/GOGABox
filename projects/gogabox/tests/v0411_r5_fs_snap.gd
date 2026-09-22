extends Node
## v041-1 r5 THE BOTTOM-BAND SNAP: boots the box in FULLSCREEN (the
## owner's saved mode) and snaps the feed - the brown band under the
## last row (the taskbar-height safe inset leak) must be gone: the feed
## runs to the screen's bottom edge. Rig-only.

func _ready() -> void:
        if DisplayServer.get_name() == "headless":
                get_tree().quit(0)
                return
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        if Box.has_method("set_pc_fullscreen"):
                Box.set_pc_fullscreen(true)
        var main: Node = load("res://main.tscn").instantiate()
        add_child(main)
        await get_tree().create_timer(4.0).timeout
        # scroll the feed a little so rows fill the bottom
        var menu: Node = main.get_node_or_null("Menu")
        if menu != null:
                menu.call("_nudge_feed", 900)
                await get_tree().create_timer(1.0).timeout
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/r5_thumbs/fs_bottom.png")
        print("SNAP_OK ", DisplayServer.window_get_size())
        # leave the rig clean: the saved fullscreen choice would leak into
        # the next probe run's boot law
        if Box.has_method("set_pc_fullscreen"):
                Box.set_pc_fullscreen(false)
        get_tree().quit(0)
