extends Node
## v041-1 film: the box boots, then a forced off-aspect window - the grab
## must show BROWN bars (the attach law), the doomscroll shade at the
## bottom, and the new cursor.

func _ready() -> void:
        await get_tree().process_frame
        # the boot is the real main.gd box (this scene rides ON it? no -
        # this probe boots its own copy below)
        var main := Node2D.new()
        main.set_script(load("res://game/main.gd"))
        add_child(main)
        await get_tree().create_timer(2.5).timeout
        # force an off-aspect window: landscape window, portrait menu
        DisplayServer.window_set_size(Vector2i(1280, 720))
        var win := get_window()
        win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
        win.content_scale_size = Vector2i(1080, 1920)
        RenderingServer.viewport_attach_to_screen(win.get_viewport_rid(),
                        Rect2i(), 0)
        print("FILM: bars state set, holding")
        await get_tree().create_timer(10.0).timeout
        print("FILM: done")
        get_tree().quit()
