extends Node
## v041-1 r6 THE EYES PASS - the owner never tests what the rig can see
## first (AGENTS.md method 32). Shoots the r6's visual laws at a HARSH PC
## downscale seat (a 405x720 window on the 1080x1920 design = 0.375 scale,
## where the old 2px grid lines died):
##   1. five in row  - every board line visible (the survivor width law)
##   2. snake        - survival's big land + the feast at its own sizes
## Raw PNGs land in /tmp/r6_shoot for the eye to read.

var out_dir := "/tmp/r6_shoot"

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        DirAccess.make_dir_recursive_absolute(out_dir)
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        # THE HARSH SEAT: a 405x720 window - the desktop downscale that
        # made the old 2.0px lines vanish (0.375 scale = 0.75 device px)
        DisplayServer.window_set_size(Vector2i(405, 720))
        ScaleRule.apply_pc(get_window(), ScaleRule.DESIGN_PORTRAIT)
        await get_tree().process_frame
        await get_tree().process_frame

        # ---------------- FIVE IN ROW: the board lines ----------------
        var BV: GDScript = load("res://game/games/bovo/bovo.gd")
        var bv: GogaGame = BV.new()
        bv.game_id = "bovo"
        add_child(bv)
        await get_tree().create_timer(1.0).timeout
        if bv.has_method("box_story_dismiss"):
                bv.box_story_dismiss()
        await get_tree().create_timer(0.5).timeout
        await _snap("bovo_lines.png")
        bv.queue_free()
        await get_tree().process_frame

        # ---------------- SNAKE: the big land + the feast ----------------
        # the gate law needs the pack count - the owner's own toggle path
        Box.set_progress("snake", "enemy_count", 6)
        var SN: GDScript = load("res://game/games/snake/snake.gd")
        var sn: GogaGame = SN.new()
        sn.game_id = "snake"
        add_child(sn)
        await get_tree().create_timer(1.2).timeout
        if sn.has_method("box_story_dismiss"):
                sn.box_story_dismiss()
        await get_tree().create_timer(0.4).timeout
        # the owner's exact broken path: survival OFF at load, flipped ON
        sn.call("_toggle_survival")
        await get_tree().process_frame
        sn.wrap_mode = false
        # the sheet's own PLAY door closes the overlay + shows the ready
        # card; then the ready card's go (the same road a tap takes)
        sn._phase = "ready"
        sn.call("_start")
        if sn.has_method("_clear_overlay_panel"):
                sn.call("_clear_overlay_panel")
        await get_tree().create_timer(1.0).timeout
        await _snap("snake_bigland.png")
        get_tree().quit(0)

func _snap(fname: String) -> void:
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png(out_dir + "/" + fname)
        print("SHOT: ", out_dir + "/" + fname)
