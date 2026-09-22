extends Node
## tb_thumb (v041-2 r2) - THE THUMBNAIL CAPTURE LAW (law 44): the real render,
## posed. Boots Tower Ball through the real host, poses the FIREBALL SMASH
## mid-tower under the GOLDEN-HOUR living world (the forced day phase the
## composer loves), shoots raw frames; the composer (tools/v0412_thumb.py)
## makes 960x640.
## Run: xvfb (Xvfb :96 -screen 0 1080x1920x24)
##   DISPLAY=:96 godot --path . res://tests/tb_thumb.tscn

var shots := 0

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        DirAccess.make_dir_recursive_absolute("/tmp/tb_thumb")
        var GH: GDScript = load("res://game/core/game_host.gd")
        Box.reset_all()
        Box.earn(100000)
        Box.unlock_game("towerball", 0)
        var router := Node2D.new()
        add_child(router)

        # ---- BALL mode: THE FIREBALL SMASH at golden hour
        Box.set_progress("towerball", "mode", "ball")
        GH.launch(router, "towerball")
        await _wait(2.4)
        var host: Node = GH.active_host
        var game: Node = host.game
        # THE LIVING WORLD POSE: force the golden hour (the thumbnail's sky)
        game.call("_force_golden_hour")
        game.call("_intro_start")     # the intro walks to the optionals
        await _wait(0.3)
        game.call("sheet_pop")        # the optionals close - clean field
        await _wait(0.2)
        game.call("_start_run")
        await _wait(1.6)          # the transition banner clears
        # pose: the FIRE BALL mid-tower - the gauge full -> charged -> burning
        game.set("boost_v", 1.0)
        game.call("_shatter_top")
        game.set("boost_charge_t", 0.05)
        game.set("holding", true)
        await _wait(0.7)
        await _snap("ball_a")
        await _wait(0.3)
        await _snap("ball_b")
        await _wait(0.35)
        await _snap("ball_c")
        host._quit_to_menu()
        await _wait(0.4)

        # ---- PLATFORM mode: the rings + the rotate + the fall
        await _wait(0.3)
        Box.set_progress("towerball", "mode", "platform")
        GH.launch(router, "towerball")
        await _wait(2.4)
        host = GH.active_host
        game = host.game
        game.call("_force_golden_hour")
        game.call("_intro_start")
        await _wait(0.3)
        game.call("sheet_pop")
        await _wait(0.2)
        game.call("_start_run")
        await _wait(1.6)
        game.call("_rotate_tower", 1.2)
        await _wait(0.6)
        await _snap("plat_a")
        await _wait(0.5)
        await _snap("plat_b")
        host._quit_to_menu()
        await _wait(0.3)
        Box.reset_all()
        print("[tb_thumb] done: %d shots" % shots)
        get_tree().quit(0)

func _wait(sec: float) -> void:
        await get_tree().create_timer(sec).timeout

func _snap(tag: String) -> void:
        await _wait(0.05)
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/tb_thumb/%s.png" % tag)
        shots += 1
