extends Node
## v040-8 theme shot rig: one frame per theme (the far strip, the ground,
## the sky shader, the rocks' material, the cannon) - the five rock packs
## reviewed BY EYE before the owner sees them.

var G: GogaGame = null
var shot_dir := "/home/z/my-project/gogabox/films/v040-8"

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout

func _shot(name: String) -> void:
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png("%s/%s.png" % [shot_dir, name])
        print("[FILM] shot ", name)

func _run() -> void:
        DirAccess.make_dir_recursive_absolute(shot_dir)
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        get_window().size = Vector2i(1080, 1920)
        ScaleRule.apply(get_window())
        await _wait(0.3)
        G = load("res://game/games/rockbreaker/rockbreaker.gd").new()
        G.game_id = "rockbreaker"
        add_child(G)
        await _wait(0.8)
        G.probe_reset(7)
        G._gate_down()
        # THE UNDYING LAW: a 5Hz shield refill - every touch is forgiven,
        # the run survives the whole shoot (the shield save also pops a
        # rock, which keeps the flood turning over)
        var t := Timer.new()
        t.wait_time = 0.2
        t.timeout.connect(func(): G.shield = 1)
        add_child(t)
        t.start()
        G.md["upg_proj"] = 4
        G._dbg_bg = true
        G.probe_spawn(0, 4, 300)
        G.probe_spawn(1, 3, 160)
        G.probe_spawn(0, 2, 60)
        G.probe_spawn(1, 5, 900)
        G.probe_spawn(1, 4, 300, true)
        G.probe_spawn(0, 3, 260, false, true, "shield")
        for tid in ["cave", "forest", "pixel", "neon", "candy"]:
                Box.equip_item("rockbreaker", "theme", tid)
                G.place_next = G.rp
                G._place_walk()
                for i in 3:
                        G.rp += 1
                        G._place_walk()
                print("[FILM] theme ", tid, " -> on=", Box.item_on("rockbreaker",
                        "theme"), " style=", G._theme()["style"])
                G._dbg_bg = true
                await _wait(1.2)
                await _shot("theme_" + tid)
                await _wait(0.8)
                await _shot("theme_" + tid + "_b")
        print("[FILM] done")
        get_tree().quit()

func _ready() -> void:
        _run.call_deferred()
