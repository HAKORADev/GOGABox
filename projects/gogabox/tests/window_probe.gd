extends Node
## v040-17 WINDOW PROBE - the PC WINDOW LAWS verified against a REAL
## windowed DisplayServer (run under Xvfb, NOT --headless: headless has no
## window and every law no-ops there by design).
##
##   THE BOOT LAW        windowed boot re-windows to the menu (portrait)
##   THE RE-WINDOW LAW   portrait <-> landscape reshape, centered, in-aspect
##   THE FULLSCREEN LAW  toggle flips the mode, persists in Box settings,
##                       and returning to windowed re-windows to the content
##   THE 1:1 LAW         the design follows the window (content_scale_size
##                       portrait while the window is portrait)
##
## Exit 0 = every law holds. Prints PROBE_OK / PROBE_FAIL lines.

var fails := 0
var checks := 0

func ck(cond: bool, what: String) -> void:
        checks += 1
        if cond:
                print("  ok - %s" % what)
        else:
                fails += 1
                print("PROBE_FAIL - %s" % what)

func _ready() -> void:
        await get_tree().process_frame
        if not ScaleRule.is_pc():
                print("PROBE_SKIP - not a PC display session")
                get_tree().quit(0)
                return
        print("WINDOW PROBE (display=%s, screen=%dx%d)" % [
                DisplayServer.get_name(),
                DisplayServer.screen_get_size(0).x,
                DisplayServer.screen_get_size(0).y])
        Box.reset_all()

        # ---- THE BOOT LAW: the real main.gd boots the box; the window must
        # end up portrait (the menu is portrait content) ----
        var main := Node2D.new()
        main.set_script(load("res://game/main.gd"))
        add_child(main)
        var win := get_window()
        var portrait := false
        for i in 60:
                await get_tree().process_frame
                var ws := DisplayServer.window_get_size()
                if ws.x > 0 and ws.y > 0 and ws.y > ws.x:
                        portrait = true
                        break
        ck(portrait, "boot law: the window opens PORTRAIT (menu content)")
        ck(win.content_scale_size == ScaleRule.DESIGN_PORTRAIT,
                        "1:1 law: content scale follows the portrait window")
        ck(not ScaleRule.is_fullscreen(), "boot law: windowed (default save)")
        var pw := DisplayServer.window_get_size()
        ck(absf(float(pw.x) / float(pw.y) - 9.0 / 16.0) < 0.03,
                        "boot window is ~9:16, no empty sides (%dx%d)" % [pw.x, pw.y])

        # ---- THE RE-WINDOW LAW: landscape reshape ----
        ScaleRule.re_window("landscape")
        var land := await _wait_shape(true)
        ck(land, "re-window: landscape game re-windows to ~16:9")
        var pos := DisplayServer.window_get_position()
        var scr := DisplayServer.screen_get_usable_rect(
                        DisplayServer.window_get_current_screen())
        ck(scr.has_point(pos), "re-window: window stays inside the screen")
        ck(ScaleRule.pc_kind == "landscape", "re-window: the kind remembers")

        # ---- THE RE-WINDOW LAW: back to portrait ----
        ScaleRule.re_window("portrait")
        var port := await _wait_shape(false)
        ck(port, "re-window: back to ~9:16 portrait")

        # ---- THE FULLSCREEN LAW: on, persisted, off re-windows ----
        ScaleRule.set_fullscreen(true)
        await get_tree().process_frame
        await get_tree().process_frame
        ck(ScaleRule.is_fullscreen(), "fullscreen law: the mode flips ON")
        ck(Box.pc_fullscreen(), "fullscreen law: the choice persists (true)")
        ScaleRule.set_fullscreen(false)
        var back := await _wait_shape(false)
        ck(not ScaleRule.is_fullscreen(), "fullscreen law: the mode flips OFF")
        ck(back, "fullscreen law: windowed again reshapes to the content")
        ck(not Box.pc_fullscreen(), "fullscreen law: the choice persists (false)")

        # ---- the menu governor keeps the design glued to the window ----
        await get_tree().process_frame
        ck(win.content_scale_size == ScaleRule.DESIGN_PORTRAIT,
                        "governor: portrait design holds on the portrait window")

        # ---- THE PC SETTINGS TOGGLE: the sheet wears the fullscreen button
        # (the owner: "make in windows build, the settings menu has toggles
        # of full screen or windowed") ----
        var menu2 := Node2D.new()
        menu2.set_script(load("res://game/menu/menu.gd"))
        add_child(menu2)
        await get_tree().process_frame
        await get_tree().process_frame
        # v0.4.1 the AAA rework: the main seat carries AUDIO / SCREEN &
        # GRAPHICS / CONTROLS - the toggles live one click deeper.
        menu2.call("_open_settings")
        await get_tree().process_frame
        await get_tree().process_frame
        ck(_has_button(menu2, "SCREEN & GRAPHICS"),
                        "settings: the main seat wears SCREEN & GRAPHICS")
        ck(_has_button(menu2, "CONTROLS"),
                        "settings: the main seat wears CONTROLS")
        menu2.call("_close_sheet")
        await get_tree().process_frame
        menu2.call("_open_screen_graphics")
        await get_tree().process_frame
        await get_tree().process_frame
        ck(_has_button_prefix(menu2, "DISPLAY: "),
                        "settings: the Screen sheet wears the DISPLAY toggle")
        ck(_has_button_prefix(menu2, "POSITION: "),
                        "settings: the Screen sheet wears the POSITION toggle")
        ck(_has_button_prefix(menu2, "DYNAMIC SCALE: "),
                        "settings: the Graphics sheet wears DYNAMIC SCALE")
        ck(_has_button_prefix(menu2, "GOGACURSOR: "),
                        "settings: the Graphics sheet wears GOGACURSOR")

        # ---- v0.4.1 THE DESIGN FOLLOWS THE CONTENT LAW: fullscreen NEVER
        # re-picks the design. The old want_for(window px) fed the LANDSCAPE
        # design to the portrait menu in fullscreen on a 16:9 monitor - the
        # owner's "vertical fullscreen is currently horizontal but tries to
        # look like vertical", the mis-aimed clicks, the clickable black
        # sides. The design must stay PORTRAIT with the bars on. ----
        ScaleRule.set_fullscreen(true)
        await get_tree().process_frame
        await get_tree().process_frame
        await get_tree().process_frame
        ck(win.content_scale_size == ScaleRule.DESIGN_PORTRAIT,
                        "content law: fullscreen keeps the PORTRAIT design")
        ck(win.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP,
                        "content law: fullscreen wears KEEP (no stretch)")
        # the bars law is shape-honest (bare Xvfb has no WM - fullscreen
        # may keep the window's 9:16 shape): bars EXACTLY when off-aspect
        var wpx := DisplayServer.window_get_size()
        var cs := win.content_scale_size
        var off_aspect := absf(float(wpx.x) / float(wpx.y)
                        - float(cs.x) / float(cs.y)) > 0.005
        ck(ScaleRule.bars_visible(win) == off_aspect,
                        "content law: the brown bars appear exactly when " +
                        "the window is off-aspect")
        menu2.call("apply_resolution")
        ck(win.content_scale_size == ScaleRule.DESIGN_PORTRAIT,
                        "content law: the governor never flips the design")
        ScaleRule.set_fullscreen(false)
        await get_tree().process_frame
        await get_tree().process_frame
        ck(ScaleRule.bars_visible(win) == false,
                        "content law: re-windowed, the bars are gone")
        ck(win.content_scale_size == ScaleRule.DESIGN_PORTRAIT,
                        "content law: windowed again, portrait design holds")

        print("WINDOW PROBE: %d checks, %d fails" % [checks, fails])
        Box.reset_all()
        get_tree().quit(1 if fails > 0 else 0)

## depth-first: does any Button under `root` carry this exact label?
func _has_button(root: Node, txt: String) -> bool:
        for c in root.get_children():
                if c is Button and String((c as Button).text) == txt:
                        return true
                if _has_button(c, txt):
                        return true
        return false

## depth-first: does any Button under `root` begin with this prefix?
func _has_button_prefix(root: Node, prefix: String) -> bool:
        for c in root.get_children():
                if c is Button and String((c as Button).text) \
                                .begins_with(prefix):
                        return true
                if _has_button_prefix(c, prefix):
                        return true
        return false

## wait up to ~1s for the window to settle into (landscape | portrait) shape
func _wait_shape(landscape: bool) -> bool:
        for i in 60:
                await get_tree().process_frame
                var ws := DisplayServer.window_get_size()
                if ws.x <= 0 or ws.y <= 0:
                        continue
                var ratio := float(ws.x) / float(ws.y)
                if landscape and ratio > 1.5:
                        return true
                if not landscape and ratio < 0.75:
                        return true
        return false
