extends Node
## v041-1 r7 THE EYES PASS - the owner never tests what the rig can see
## first (AGENTS.md method 32). Shoots the r7's visual laws:
##   1. the loader   - the straight golden frame WRAPS the thumbnail
##                     (no curved corners for the art to float over)
##   2. the popup    - the collision law: short text = one line hugging
##                     its content; long text = full-width wrap; the
##                     giant case = the stepped-down ladder
##   3. the reticle  - Heavy War's baked cursor pair, blown up 4x for the
##                     eye (the OS carries it over every Control; the
##                     bitmap itself is what the eye can judge here)
## Raw PNGs land in /tmp/r7_shoot for the eye to read.

var out_dir := "/tmp/r7_shoot"

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        DirAccess.make_dir_recursive_absolute(out_dir)
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        await get_tree().process_frame
        await get_tree().process_frame

        # ---------------- 1. THE LOADER FRAME ----------------
        var l: Node = load("res://game/core/loader.gd").new()
        add_child(l)
        l._run({"id": "heavywar", "title": "HEAVY WAR",
                "thumb": "res://assets/thumbs/heavywar.png", "script": ""})
        await get_tree().create_timer(0.7).timeout
        await _snap("loader_frame.png")
        l.queue_free()
        await get_tree().process_frame

        # ---------------- 2. THE POPUP COLLISION LAW ----------------
        var ach: Node = load("res://game/core/achiever.gd").new()
        add_child(ach)
        await get_tree().process_frame
        # the SHORT one: one line, hugging its content (no 640 box)
        Achiever.award("snake", {"title": "Snack Time",
                "desc": "eat 10 fruits in one run", "tier": 2})
        await get_tree().create_timer(1.0).timeout
        await _snap("popup_short.png")
        # the LONG one: full-width wrap, no blind 640, no overflow
        await get_tree().create_timer(2.6).timeout
        Achiever.award("heavywar", {"title":
                "The Long March Across The Whole Wide War Front Line",
                "desc": "survive every single place in one endless run "
                + "without losing a single life while the armor walks "
                + "the whole war front from the coast to the gothic night",
                "tier": 4})
        await get_tree().create_timer(1.0).timeout
        await _snap("popup_long.png")
        # the GIANT one: the ladder stepped down, still on the screen
        var giant_desc := ""
        for i in 30:
                giant_desc += "survive wave %d under the storm of steel " % i
        await get_tree().create_timer(2.6).timeout
        Achiever.award("invaders", {"title":
                "The Impossible Endless Night Watch Of The Last Battery",
                "desc": giant_desc, "tier": 3})
        await get_tree().create_timer(1.0).timeout
        await _snap("popup_giant.png")
        ach.queue_free()
        await get_tree().process_frame

        # ---------------- 3. THE RETICLE PAIR ----------------
        var hw: GDScript = load("res://game/games/heavywar/heavywar.gd")
        var inst: GogaGame = hw.new()
        # bake WITHOUT the full game boot: call the baker on a naked
        # instance (it only reads THEME + Image)
        var norm: ImageTexture = inst._bake_reticle(false)
        var fire: ImageTexture = inst._bake_reticle(true)
        _blow_up(norm, "reticle_idle_4x.png")
        _blow_up(fire, "reticle_fire_4x.png")
        get_tree().quit(0)

func _blow_up(tex: ImageTexture, fname: String) -> void:
        var img := tex.get_image()
        img.resize(img.get_width() * 4, img.get_height() * 4,
                        Image.INTERPOLATE_NEAREST)
        img.save_png(out_dir + "/" + fname)
        print("SHOT: ", out_dir + "/" + fname)

func _snap(fname: String) -> void:
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png(out_dir + "/" + fname)
        print("SHOT: ", out_dir + "/" + fname)
