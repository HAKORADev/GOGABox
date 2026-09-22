extends Node
## tb_film (v041-2 r2) - THE VISION LAW rig: automated play in BOTH modes x
## BOTH orientations, recorded frame by frame, EYEBALLED before shipping.
## r2 rigs: intro (the ball ALIVE at the first frame), opts (the optionals
## menu), ball_v / ball_h (the smash + the fire), plat_v / plat_h (the REAL
## Neon Tower: the tower rotation, the falls, the combo), fire (the burn),
## shop (the design skins' shelf).
## Run per rig (under Xvfb):
##   QA_TB=ball_h DISPLAY=:96 godot --path . res://tests/tb_film.tscn

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
        var base := rig.trim_suffix("_v").trim_suffix("_h")
        var mode := "platform" if base == "plat" else "ball"
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
        # r2 THE FLOW: intro first - the ball bounces the tower as scenery
        if base == "intro":
                await _snap("alive")
                await _wait(0.6)
                await _snap("alive2")
                get_tree().quit(0)
                return
        if base == "opts":
                game.call("_intro_start")
                await _wait(0.5)
                await _snap("opts")
                get_tree().quit(0)
                return
        if base == "shop":
                game.call("_intro_start")
                await _wait(0.3)
                game.call("sheet_pop")
                await _wait(0.2)
                game.call("_shop_open")
                await _wait(0.5)
                await _snap("shop")
                get_tree().quit(0)
                return
        game.call("_intro_start")
        await _wait(0.3)
        game.call("sheet_pop")
        await _wait(0.2)
        game.call("_start_run")
        await _wait(1.6)
        if base == "ball":
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
        elif base == "plat":
                # THE REAL NEON TOWER: rotate the TOWER left and right -
                # the ball falls through the gaps we steer under it
                print("[tb_film] rings alive: ", (game.get("rings") as Dictionary).size())
                var ringsd: Dictionary = game.get("rings")
                if ringsd.size() > 0:
                        var first: Dictionary = ringsd[ringsd.keys()[0]]
                        var n: MeshInstance3D = first["node"]
                        print("[tb_film] ring0 pos ", n.position,
                                " aabb ", n.get_aabb(), " visible ", n.visible,
                                " mesh faces ", (n.mesh as ArrayMesh).get_faces().size() / 9)
                game.call("_rotate_tower", 0.9)
                await _wait(0.5)
                await _snap("a")
                await _wait(0.9)
                await _snap("b")
                game.call("_rotate_tower", -1.4)
                await _wait(0.9)
                await _snap("c")
                await _wait(1.0)
                await _snap("d")
                game.call("_rotate_tower", 2.2)
                await _wait(1.0)
                await _snap("e")
        elif base == "fire":
                # THE BOOST: force the gauge full -> the 1.6s charge -> the burn
                game.set("boost_v", 1.0)
                game.call("_shatter_top")
                await _wait(0.5)
                await _snap("charge")
                game.set("boost_charge_t", 0.05)
                await _wait(0.4)
                await _snap("burn")
                await _wait(0.8)
                await _snap("burn2")
                game.set("holding", true)
                await _wait(0.6)
                await _snap("burn3")
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
