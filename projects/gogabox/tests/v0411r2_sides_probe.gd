extends Node
## v041-1 r2 probe: THE FLAT SIDES LAW (the owner: "it is rendered even on
## top of the app in-resolution area ... give the sides just a #0a0a0a
## color"). r4 UPDATE: the bars ARE the near-black ink via the engine's own
## letterbox path (windowed re_window = no bars at all; fullscreen
## off-aspect = the GLES3 blit's near-black letterbox clear) - the r1
## empty-rect re-attach hack that promised "the clear color shows on the
## bars" froze the owner's Windows present path instead and is GONE (see
## scale_rule.apply_pc, THE PRESENT-PATH NUKE). The honest verification:
## the ink constant, the clear color, and NO attach call in the present
## path + nothing painting above the app anymore (the veil is retired).

var fails := 0

func ck(cond: bool, what: String) -> void:
        if cond:
                print("PROBE_OK - %s" % what)
        else:
                fails += 1
                print("PROBE_FAIL - %s" % what)

func _ready() -> void:
        await get_tree().process_frame
        Box.reset_all()
        # THE INK LAW: the constant is the owner's exact color
        ck(ScaleRule.PC_BAR_INK.is_equal_approx(Color("0a0a0a")),
                        "PC_BAR_INK is #0a0a0a (%s)" % ScaleRule.PC_BAR_INK)
        # THE PAINT LAW: apply_pc sets the CLEAR COLOR to the ink - the
        # bars wear #0a0a0a on every desktop design (KEEP), no brown
        ScaleRule.apply_pc(get_window(), ScaleRule.DESIGN_PORTRAIT)
        ck(RenderingServer.get_default_clear_color()
                        .is_equal_approx(Color("0a0a0a")),
                        "apply_pc paints the bars #0a0a0a (clear color %s)"
                        % RenderingServer.get_default_clear_color())
        # THE PRESENT PATH IS CLEAN (r4): no viewport_attach_to_screen call
        # rides the apply_pc present road anymore - the r1 empty-rect hack
        # froze the owner's real Windows GL present. Source-level guard:
        # the viewport is left to the engine's own attach law.
        var sr := FileAccess.open("res://game/core/scale_rule.gd", FileAccess.READ)
        var src_code := sr.get_as_text() if sr != null else ""
        var exec_calls := 0
        for line in src_code.split("\n"):
                var t := line.strip_edges()
                if t.begins_with("RenderingServer.viewport_attach_to_screen("):
                        exec_calls += 1
        ck(exec_calls == 0,
                        "apply_pc carries no viewport_attach_to_screen call (r4)")
        # THE VEIL IS RETIRED: boot the real box and walk its tree - no
        # veil layer (layer 95), no veil control, nothing above the app
        var main := Node2D.new()
        main.set_script(load("res://game/main.gd"))
        add_child(main)
        await get_tree().create_timer(2.0).timeout
        var veil_found := false
        for n in main.find_children("*", "CanvasLayer", true, false):
                var cl := n as CanvasLayer
                if cl != null and cl.layer == 95:
                        veil_found = true
        ck(not veil_found, "the edge veil layer (95) is retired")
        var src := FileAccess.open("res://game/main.gd", FileAccess.READ)
        var code := src.get_as_text() if src != null else ""
        ck(not code.contains("func _build_edge_veil")
                        and not code.contains("var _veil_root"),
                        "main.gd carries no veil builder anymore")
        # the boot law: the clear color STAYS the ink while the menu runs
        ck(RenderingServer.get_default_clear_color()
                        .is_equal_approx(Color("0a0a0a")),
                        "the ink holds after the menu boot")
        print("PROBE flat_sides_RESULT %s" % ("ALL OK" if fails == 0
                        else "%d FAILS" % fails))
        get_tree().quit(0)
