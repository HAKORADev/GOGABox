extends Node
## ROCK BREAKER v040-7 film - THE VISION LAW: the rig has eyes, use
## them BEFORE the owner has to. Renders the gate, the flood (rocks,
## cannon, bullets, the wallet), the golden + the mystery, the powerup
## chips, all five themes' places, the shop and the upgrades sheets.
## Run: xvfb-run godot --path . --rendering-driver opengl3 \
##        res://tests/rock_film.tscn

var G: GogaGame = null
var shot_dir := "/home/z/my-project/gogabox/films/v040-7"

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout

func _shot(name: String) -> void:
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png("%s/%s.png" % [shot_dir, name])
        print("[FILM] shot ", name)

func rng_like(i: int) -> float:
        return [-1.0, 0.6, -0.4, 1.0, -0.7, 0.3][i % 6]

func _tap(idx: int, pos: Vector2, down: bool) -> void:
        var e := InputEventScreenTouch.new()
        e.index = idx
        e.position = pos
        e.pressed = down
        G._goga_input(e)

func _run() -> void:
        DirAccess.make_dir_recursive_absolute(shot_dir)
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        Box.earn(5000)
        get_window().size = Vector2i(1080, 1920)
        ScaleRule.apply(get_window())
        await _wait(0.3)
        G = load("res://game/games/rockbreaker/rockbreaker.gd").new()
        G.game_id = "rockbreaker"
        add_child(G)
        await _wait(1.0)
        await _shot("01_gate")

        # start the run
        _tap(9, Vector2(540, 900), true)
        _tap(9, Vector2(540, 900), false)
        await _wait(0.4)

        # stage the flood: a family swarm + the specials + some fire
        G.probe_reset(42)
        G._auto = false
        G.md["upg_proj"] = 6
        G.md["upg_dmg"] = 3
        G.md["rockcoins"] = 4321
        G.probe_spawn(0, 4, 260)
        G.probe_spawn(1, 3, 150)
        G.probe_spawn(0, 5, 400)
        G.probe_spawn(1, 2, 90)
        G.probe_spawn(1, 3, 700, true)          # the golden
        G.probe_spawn(0, 2, 350, false, true)   # the mystery
        await _wait(0.05)
        G.mouse_fire = true
        await _wait(0.9)
        G.mouse_fire = false
        G.slow_t = 5.0
        await _wait(0.1)
        await _shot("02_flood")

        # the shield bubble
        G.shield = 1
        await _wait(0.15)
        await _shot("03_shield")

        # a staged break burst
        if G.rocks.size() > 1:
                G._break_rock(1)
        await _wait(0.12)
        await _shot("04_break")

        # the upgrades sheet
        G._upgrades_open()
        await _wait(0.4)
        await _shot("05_upgrades")
        G.sheet_pop()
        await _wait(0.3)

        # the shop sheet
        G._shop_open()
        await _wait(0.4)
        await _shot("06_shop")
        G.sheet_pop()
        await _wait(0.3)

        # the five places of the cave theme
        var th: Dictionary = G._theme()
        var ps: Array = th["places"]
        for i in ps.size():
                G.place_i = i
                G.place_fade = 1.0
                await _wait(0.35)
                await _shot("10_place_%d" % i)

        # the deep-heat thumbnail frame: the cluster seats in the thumb
        # window (the crop law: the cannon AND the rocks share the frame)
        G.probe_reset(77)
        G.md["upg_proj"] = 14
        G.md["upg_dmg"] = 4
        G.rp = 640
        G.heat = 640
        G.probe_spawn(0, 5, 1200)
        G.probe_spawn(1, 4, 900)
        G.probe_spawn(0, 4, 760)
        G.probe_spawn(1, 5, 1500)
        G.probe_spawn(0, 3, 640, true)
        G.probe_spawn(1, 2, 480, false, true)
        var xs := [240.0, 420.0, 620.0, 830.0, 520.0, 740.0]
        var ys := [1180.0, 1110.0, 1230.0, 1160.0, 1340.0, 1300.0]
        for i in G.rocks.size():
                G.rocks[i]["x"] = xs[i % xs.size()]
                G.rocks[i]["y"] = ys[i % ys.size()]
                G.rocks[i]["vx"] = rng_like(i) * 26.0
                G.rocks[i]["vy"] = -40.0
        G.cannon_x = 540.0
        await _wait(0.05)
        G.mouse_fire = true
        await _wait(0.62)
        await _shot("thumb_frame")
        print("[FILM] done")
        get_tree().quit(0)

func _ready() -> void:
        _run.call_deferred()
