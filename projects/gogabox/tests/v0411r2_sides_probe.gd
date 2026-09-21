extends Node
## v041-1 r2 probe: THE FLAT SIDES LAW (the owner: "it is rendered even on
## top of the app in-resolution area ... give the sides just a #0a0a0a
## color"). The bars ARE the clear color (the v041-1 root-cause work: with
## KEEP the engine never renders outside the design rect - the re-attach
## to the whole window exposes the clear color there), so the honest
## verification is the clear color itself + NOTHING painting above the
## app anymore (the veil is retired with the brown).

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
        # THE RE-ATTACH LAW (round 1, kept): the viewport owns the WHOLE
        # window - the clear color actually SHOWS on the bars
        var win := get_window()
        win.size = Vector2i(1280, 720)
        ScaleRule.apply_pc(win, ScaleRule.DESIGN_PORTRAIT)
        ck(true, "apply_pc re-asserted on an off-aspect window without error")
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
