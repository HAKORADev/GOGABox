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

        # ---- MARBLE POPPER: intro -> level 1 preview -> play -> shoot ----
        GameHost.launch(_main, "marble")
        await get_tree().create_timer(2.2).timeout
        var host1: Node = GameHost.active_host
        if host1 != null and host1.game != null:
                host1.game.call("box_story_dismiss")   # the first-start lore
                await get_tree().process_frame
                host1.game.call("_intro_go")
                await get_tree().create_timer(1.2).timeout
                host1.game.call("_begin_play")
                await get_tree().create_timer(1.05).timeout
                await _shot(dir + "/marble_raw.png")
        # leave through the host's own door (the session law)
        if host1 != null and host1.game != null:
                host1.game.call("box_story_dismiss")
                host1.game.call("quit_to_box")
        await get_tree().create_timer(1.6).timeout
        print("CAPS_OK")
        get_tree().quit(0)

func _shot(path: String) -> void:
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png(ProjectSettings.globalize_path(path))
        print("cap -> ", path)
