extends Node
## HEAVY WAR film probe (v040-2) - the simulated gameplay session: real
## finger events, real state, SCREENSHOTS at every beat so the owner's
## "watch the game with your own eyes" law runs on the rig.
## Run: xvfb-run godot --path . --rendering-driver opengl3 \
##        res://tests/hw_film.tscn

var G: GogaGame = null
var shot_dir := "/home/z/my-project/gogabox/films/v040-2"

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout

func _shot(name: String) -> void:
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png("%s/%s.png" % [shot_dir, name])
        print("[FILM] shot ", name)

func _tap(idx: int, pos: Vector2, down: bool) -> void:
        var e := InputEventScreenTouch.new()
        e.index = idx
        e.position = pos
        e.pressed = down
        G._goga_input(e)

func _drag(idx: int, pos: Vector2) -> void:
        var e := InputEventScreenDrag.new()
        e.index = idx
        e.position = pos
        G._goga_input(e)

func _run() -> void:
        DirAccess.make_dir_recursive_absolute(shot_dir)
        Box.reset_all()
        get_window().size = Vector2i(1920, 1080)
        ScaleRule.apply(get_window())      # the house design law
        await _wait(0.3)
        G = load("res://game/games/heavywar/heavywar.gd").new()
        G.game_id = "heavywar"
        add_child(G)
        await _wait(1.2)
        await _shot("01_intro")

        # THE TAP ANYWHERE LAW: the war starts
        _tap(0, Vector2(960, 540), true)
        _tap(0, Vector2(960, 540), false)
        await _wait(1.6)
        await _shot("02_place_start")

        # TWO FINGERS: steer bottom-left, aim center-right
        _tap(1, Vector2(700, 1000), true)
        _tap(2, Vector2(1350, 480), true)
        _drag(1, Vector2(1250, 1000))
        await _wait(0.5)
        await _shot("03_two_fingers")

        # the aim finger tracks a live enemy for 4s of combat
        for i in 8:
                if not G.enemies.is_empty():
                        var tgt: Node2D = G.enemies[0]["n"]
                        _drag(2, tgt.position)
                _drag(1, Vector2(700.0 + sin(i * 0.9) * 500.0, 1000.0))
                await _wait(0.5)
        await _shot("04_combat")

        # a heavy kill near the road: explosion + crater + debris
        G._spawn_enemy("carpet", G.tank.position.x + 420.0, G.ROAD_Y - 220.0)
        G.aim_pos = G.tank.position + Vector2(420.0, -220.0)
        var carpet: Dictionary = G.enemies[-1]
        carpet["hp"] = 1
        await _wait(1.2)
        await _shot("05_impact_crater")

        # the nuke: white-out + fire + smoke
        G.run["nukes"] = 1
        _tap(3, Vector2(960, 160), true)
        _tap(3, Vector2(960, 160), false)
        await _wait(0.25)
        await _shot("06_nuke_blast")
        await _wait(1.0)
        await _shot("07_nuke_after")

        # THE FRIEND: the white helicopter's crates
        G._heli_pass("supply")
        await _wait(1.4)
        await _shot("08_heli_crates")
        await _wait(2.6)
        await _shot("09_drops_road")

        # THE SPHERES: shield layers + the bubble
        G._collect("shield")
        G._collect("shield")
        await _wait(0.6)
        await _shot("10_deflector_spheres")

        # THE MEGALASER: four parts and the cyan column
        G.run["laser_parts"] = 3
        G._collect("laser")
        await _wait(0.7)
        await _shot("11_megalaser")

        # THE BOSS: the danger sign + the face + its bar
        G._enter_boss()
        await _wait(0.5)
        await _shot("12_boss_danger")
        await _wait(2.8)
        await _shot("13_boss_fight")
        G._boss_die()
        await _wait(0.6)
        await _shot("14_armory")

        print("[FILM] done -> ", shot_dir)
        get_tree().quit(0)

func _ready() -> void:
        _run.call_deferred()
