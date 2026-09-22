extends Node
## tb_film (v041-2) - THE VISION LAW rig: automated play in BOTH modes x
## BOTH orientations, recorded frame by frame, EYEBALLED before shipping.
## Run per rig (under Xvfb):
##   QA_TB=ball_h xvfb-run ... DISPLAY=:96 godot --path . --resolution 1280x720 res://tests/tb_film.tscn
## rigs: ball_v (portrait), ball_h (landscape), plat_v, plat_h, shop, opts

var frames := 0
var rig := ""

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        rig = OS.get_environment("QA_TB")
        if rig.is_empty():
                rig = "ball_v"
        DirAccess.make_dir_recursive_absolute("/tmp/tb_film")
        var GH: GDScript = load("res://game/core/game_host.gd")
        Box.reset_all()
        Box.earn(100000)
        Box.unlock_game("towerball", 0)
        var router := Node2D.new()
        add_child(router)
        var portrait := rig.ends_with("_v")
        var mode := "ball" if rig.begins_with("ball") else "platform"
        if portrait:
                DisplayServer.window_set_size(Vector2i(720, 1280))
        else:
                DisplayServer.window_set_size(Vector2i(1280, 720))
        await _settle(3)
        Box.set_progress("towerball", "mode", mode)
        GH.launch(router, "towerball")
        await _wait(2.4)
        var host: Node = GH.active_host
        var game: Node = host.game
        if rig == "opts":
                game.call("_intro_start")
                await _wait(0.4)
                await _snap("opts")
                get_tree().quit(0)
                return
        if rig == "shop":
                game.call("_intro_start")
                await _wait(0.3)
                game.call("sheet_pop")
                await _wait(0.2)
                game.call("_shop_open")
                await _wait(0.4)
                await _snap("shop")
                get_tree().quit(0)
                return
        game.call("_intro_start")
        await _wait(0.3)
        game.call("sheet_pop")
        await _wait(0.2)
        game.call("_start_run")
        await _wait(1.5)
        if mode == "ball":
                # the play: hold smashes, release bounces - three beats
                game.set("holding", true)
                await _wait(1.0)
                await _snap("a")
                await _wait(0.7)
                await _snap("b")
                game.set("holding", false)
                await _wait(0.6)
                await _snap("c")
                game.set("holding", true)
                await _wait(1.4)
                await _snap("d")
                await _wait(1.4)
                await _snap("e")
        else:
                # the play: steer right, then left - the ball rides
                game.set("ptx", 14.0)
                await _wait(1.0)
                await _snap("a")
                game.set("ptx", -14.0)
                await _wait(1.0)
                await _snap("b")
                await _wait(1.0)
                await _snap("c")
                game.set("ptx", 20.0)
                await _wait(1.2)
                await _snap("d")
                await _wait(1.0)
                await _snap("e")
        print("[tb_film] rig %s done: %d frames" % [rig, frames])
        get_tree().quit(0)

func _settle(n: int) -> void:
        for i in n:
                await get_tree().process_frame

func _wait(sec: float) -> void:
        await get_tree().create_timer(sec).timeout

func _snap(tag: String) -> void:
        await _settle(2)
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/tb_film/%s_%s.png" % [rig, tag])
        frames += 1
