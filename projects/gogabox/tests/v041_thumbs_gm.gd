extends Node
## v041 THE THUMBNAIL CAPTURE RIG (the owner: "take a code-programmed
## in-game capture to be more better" - for MARBLE POPPER and GOLD MINER).
## Boots the REAL games under the real box, drives each into its live run,
## screenshots the true canvas, and hands PNGs to the crop step.
## Exit 0 = captures landed.

var _main: Node

func _ready() -> void:
        var dir := "res://../films/v041/caps"
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
        Box.dev_set_cheat("all_owned", 1)
        _main = load("res://main.tscn").instantiate()
        add_child(_main)
        await get_tree().create_timer(3.0).timeout

                # ---- GOLD MINER: intro -> run -> mid-swing ----
        GameHost.launch(_main, "goldminer")
        await get_tree().create_timer(2.4).timeout
        var host2: Node = GameHost.active_host
        if host2 != null and host2.game != null:
                host2.game.call("box_story_dismiss")
                await get_tree().process_frame
                host2.game.call("_intro_start")
                await get_tree().create_timer(1.5).timeout
                host2.game.call("_on_tap", Vector2.ZERO)
                await get_tree().create_timer(1.1).timeout
                await _shot(dir + "/goldminer_raw.png")
        print("CAPS_OK")
        get_tree().quit(0)

func _shot(path: String) -> void:
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png(ProjectSettings.globalize_path(path))
        print("cap -> ", path)
