extends Node
## v041 VISION PASS - the rig's eyes (AGENTS.md method 32). Boots the REAL
## box (main.tscn), drives it into the shapes the owner described, and
## screenshots each. PNGs land in res://../films/v041/ - eye pass, not a gate.

var _main: Node

func _ready() -> void:
        var dir := "res://../films/v041"
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
        _main = load("res://main.tscn").instantiate()
        add_child(_main)
        await get_tree().create_timer(3.2).timeout   # splash done, feed up
        await _shot(dir + "/01_menu_windowed.png")
        # fullscreen on the 16:9 screen - the brown bars + the edge veil
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        await get_tree().create_timer(0.8).timeout
        await _shot(dir + "/02_menu_fullscreen_bars.png")
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        await get_tree().create_timer(0.8).timeout
        # a dragged-off-aspect window
        DisplayServer.window_set_size(Vector2i(1000, 700))
        await get_tree().create_timer(0.8).timeout
        await _shot(dir + "/03_menu_dragged.png")
        # SQUARES, the 3-board game, at the daily shape (the film save owns
        # nothing - the all_owned dev cheat opens the door, then it's off)
        Box.dev_set_cheat("all_owned", 1)
        DisplayServer.window_set_size(Vector2i(455, 810))
        GameHost.launch(_main, "squares")
        await get_tree().create_timer(2.5).timeout
        await _shot(dir + "/04_squares_windowed.png")
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        await get_tree().create_timer(0.8).timeout
        await _shot(dir + "/05_squares_fullscreen.png")
        print("VISION_OK")
        get_tree().quit(0)

func _shot(path: String) -> void:
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png(ProjectSettings.globalize_path(path))
        print("shot -> ", path)
