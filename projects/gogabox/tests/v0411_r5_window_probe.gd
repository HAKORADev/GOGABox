extends Node
## v041-1 r5 THE WINDOW PROBE - the state-machine verification for the
## one-writer nuke. Runs under a REAL display (Xvfb rig): the window
## laws no-op on headless, so this probe is rig-only by design.
## THE DANCES:
##   1. boot shape        - re_window portrait lands the exact size
##   2. honest fullscreen - enter/exit, the mode read never lies
##   3. THE MAXIMIZE TRAP - MAXIMIZED -> fullscreen -> windowed must end
##      in a REAL windowed window at the exact portrait size (the r1-r4
##      corrupted fullscreen died here)
##   4. the quiet frame   - 120 in-game frames with ZERO window writes
## Exit 0 + PROBE_OK = all green.

var _fails := 0

func _fail(msg: String) -> void:
        _fails += 1
        print("PROBE_FAIL: ", msg)

func _check(ok: bool, msg: String) -> void:
        if ok:
                print("PROBE_OK: ", msg)
        else:
                _fail(msg)

func _ready() -> void:
        if DisplayServer.get_name() == "headless":
                print("PROBE_SKIP: headless - the window laws are phone/PC-laws")
                get_tree().quit(0)
                return
        var win := get_window()
        # a clean slate: a previous rig run may have persisted a different
        # fullscreen choice - the boot law HONORS the saved flag
        Box.reset_all()
        await get_tree().process_frame
        await get_tree().process_frame

        # ---- 1. the boot shape (re_window portrait) ----
        ScaleRule.boot_window()
        await get_tree().create_timer(0.3).timeout
        var scr := DisplayServer.screen_get_usable_rect(
                        DisplayServer.window_get_current_screen())
        var want_h := clampi(int(float(scr.size.y) * 0.9), 480, 1440)
        var want := Vector2i(want_h * 9 / 16, want_h)
        _check(ScaleRule.is_fullscreen() == false, "boot is windowed")
        _check(DisplayServer.window_get_size() == want,
                "boot size exact %s (got %s)" % [want,
                        DisplayServer.window_get_size()])

        # ---- 2. honest fullscreen dance ----
        ScaleRule.set_fullscreen(true)
        await get_tree().create_timer(0.3).timeout
        _check(ScaleRule.is_fullscreen(), "fullscreen entered, read honest")
        ScaleRule.set_fullscreen(false)
        await get_tree().create_timer(0.5).timeout
        _check(ScaleRule.is_fullscreen() == false, "windowed restored, read honest")
        _check(DisplayServer.window_get_size() == want,
                "windowed size exact after fs exit (got %s)" %
                        DisplayServer.window_get_size())

        # ---- 3. THE MAXIMIZE TRAP dance ----
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
        await get_tree().create_timer(0.3).timeout
        var seeded: bool = DisplayServer.window_get_mode() \
                        == DisplayServer.WINDOW_MODE_MAXIMIZED
        if seeded:
                _check(true, "maximized seeded")
        else:
                # a WM-less X session cannot maximize (no EWMH) - the seed
                # is a Windows-side fact; the dance below still must heal
                print("PROBE_NOTE: this display cannot seed MAXIMIZED - " \
                                + "the dance still runs")
        ScaleRule.set_fullscreen(true)
        await get_tree().create_timer(0.3).timeout
        _check(ScaleRule.is_fullscreen(), "trap: fullscreen entered")
        ScaleRule.set_fullscreen(false)
        await get_tree().create_timer(0.5).timeout
        _check(DisplayServer.window_get_mode()
                == DisplayServer.WINDOW_MODE_WINDOWED,
                "trap: bookkeeping is WINDOWED (not MAXIMIZED)")
        _check(ScaleRule.is_fullscreen() == false, "trap: honest windowed read")
        _check(DisplayServer.window_get_size() == want,
                "trap: real windowed size, not screen-covering (got %s)" %
                        DisplayServer.window_get_size())
        # F10 (re_window) in the healed state lands exact too
        ScaleRule.re_window("landscape")
        await get_tree().create_timer(0.3).timeout
        var want_w := clampi(int(float(scr.size.x) * 0.8), 640, 1600)
        var want_ls := Vector2i(want_w, want_w * 9 / 16)
        _check(DisplayServer.window_get_size() == want_ls,
                "re_window landscape exact (got %s)" %
                        DisplayServer.window_get_size())
        ScaleRule.re_window("portrait")
        await get_tree().create_timer(0.3).timeout

        # ---- 4. the quiet frame: a game runs with zero window writes ----
        Box.dev_set_cheat("all_owned", 1)
        GameHost.launch(self, "matcher")
        await get_tree().create_timer(2.0).timeout
        var w0 := DisplayServer.window_get_size()
        var mode0 := DisplayServer.window_get_mode()
        var design0 := win.content_scale_size
        var changed := 0
        for i in range(120):
                await get_tree().process_frame
                if DisplayServer.window_get_size() != w0 \
                                or DisplayServer.window_get_mode() != mode0 \
                                or win.content_scale_size != design0:
                        changed += 1
        _check(changed == 0,
                "quiet frame: 120 in-game frames, %d window changes" % changed)
        GameHost.end_session()
        await get_tree().create_timer(0.6).timeout

        if _fails == 0:
                print("PROBE_OK: ALL GREEN")
                get_tree().quit(0)
        else:
                print("PROBE_FAIL: %d failures" % _fails)
                get_tree().quit(1)
