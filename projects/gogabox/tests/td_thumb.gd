extends Node
## td_thumb (v041-3) - THE THUMBNAIL CAPTURE LAW (law 44): the real render,
## posed. Boots TOWER DESTROYER through the real host, runs the FULL CREW
## (4 seats: you + 3 CPU gunners), poses the firefight - balls in flight,
## a platform mid-shatter, the CPU score tags riding - and shoots raw
## frames; tools/v0413_td_thumb.py makes the 960x640.
## Run: xvfb (Xvfb :96 -screen 0 1080x1920x24)
##   DISPLAY=:96 godot --path . res://tests/td_thumb.tscn

var shots := 0

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        DirAccess.make_dir_recursive_absolute("/tmp/td_thumb")
        var GH: GDScript = load("res://game/core/game_host.gd")
        Box.reset_all()
        Box.earn(100000)
        Box.unlock_game("towerdestroyer", 0)
        var router := Node2D.new()
        add_child(router)
        # the pose window inside the 1080x1920 Xvfb screen (the r3 lesson)
        DisplayServer.window_set_size(Vector2i(810, 1440))
        await _wait(0.3)

        GH.launch(router, "towerdestroyer")
        await _wait(2.4)
        var host: Node = GH.active_host
        var game: Node = host.game
        # the FULL CREW: 4 seats (you + 3 human-like CPUs)
        game.call("_pick_players", 4)
        await _wait(0.3)
        game.call("_ready_go")
        await _wait(1.2)
        # THE FIREFIGHT POSE: hold fire, let the tower descend into the guns,
        # the CPUs answering with their own rhythm
        game.set("holding", true)
        await _wait(1.4)
        await _snap("crew_a")
        await _wait(0.4)
        await _snap("crew_b")
        # the deep pose: drop the tower low so the platforms crowd the guns
        var plats: Array = game.get("plats")
        for p in plats:
                p["y"] = maxf(3.0, float(p["y"]) - 24.0)
        await _wait(0.5)
        await _snap("crew_c")
        host._quit_to_menu()
        await _wait(0.3)
        Box.reset_all()
        print("[td_thumb] done: %d shots" % shots)
        get_tree().quit(0)

func _wait(sec: float) -> void:
        await get_tree().create_timer(sec).timeout

func _snap(tag: String) -> void:
        await _wait(0.05)
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/td_thumb/%s.png" % tag)
        shots += 1
