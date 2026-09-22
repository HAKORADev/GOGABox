extends Node
## v041-1 r6 THE WINDOW PROBE - the harder debugging round. Runs under a
## REAL display (the Xvfb rig): the window laws no-op on headless, so this
## probe is rig-only by design.
## THE LAWS:
##   1. the boot shape      - re_window portrait lands the exact size
##   2. THE TRUE FULLSCREEN - WINDOW_MODE_EXCLUSIVE_FULLSCREEN (the owner:
##      "make sure that we use true full screen" - the mode read says
##      EXCLUSIVE, never the borderless-window look-alike)
##   3. THE 2-STATE LAW     - F11's dance walks exactly two honest states:
##      enter -> exclusive, exit -> the exact windowed size, twice, no
##      look-alikes in between (the 4-state bounce is structurally dead)
##   4. THE POISON WATCHDOG - a windowed window exactly covering the
##      screen (the maximize trap's leftover, the taskbar-glitch maker)
##      is healed in ONE heal_poison_shape() call
##   5. THE DESIGN GOVERNOR - a game whose content_scale_size drifts is
##      healed within 2 frames by host_node's read-compare-assert (the
##      "stuck in mis-scale" root kill), and the QUIET FRAME law holds:
##      120 steady frames write NOTHING.
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

        # ---- 2. THE TRUE FULLSCREEN (exclusive) ----
        # the content's design seat (the menu's own road) - then the flip
        # must NOT move it (the design never rides the mode)
        ScaleRule.apply_pc(win, ScaleRule.DESIGN_PORTRAIT)
        ScaleRule.set_fullscreen(true)
        await get_tree().create_timer(0.3).timeout
        _check(DisplayServer.window_get_mode()
                == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
                "fullscreen is EXCLUSIVE (true fullscreen, not borderless)")
        _check(ScaleRule.is_fullscreen(), "the fullscreen read is honest")
        _check(win.content_scale_size == ScaleRule.DESIGN_PORTRAIT
                and win.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP,
                "the design stays glued (KEEP + portrait) inside fullscreen")

        # ---- 3. THE 2-STATE LAW (twice around, no look-alikes) ----
        ScaleRule.set_fullscreen(false)
        await get_tree().create_timer(0.5).timeout
        _check(DisplayServer.window_get_mode()
                == DisplayServer.WINDOW_MODE_WINDOWED, "exit 1: WINDOWED")
        _check(DisplayServer.window_get_size() == want,
                "exit 1: the exact windowed size (got %s)" %
                        DisplayServer.window_get_size())
        ScaleRule.set_fullscreen(true)
        await get_tree().create_timer(0.3).timeout
        _check(DisplayServer.window_get_mode()
                == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
                "re-enter: EXCLUSIVE again (no look-alike state)")
        ScaleRule.set_fullscreen(false)
        await get_tree().create_timer(0.5).timeout
        _check(DisplayServer.window_get_mode()
                == DisplayServer.WINDOW_MODE_WINDOWED, "exit 2: WINDOWED")
        _check(DisplayServer.window_get_size() == want,
                "exit 2: the exact windowed size (got %s)" %
                        DisplayServer.window_get_size())

        # ---- 4. THE POISON WATCHDOG ----
        # forge the poison shape: a WINDOWED window exactly covering the
        # screen (the maximize trap's leftover - what the taskbar glitch
        # rode). The lock would stop a user from building it; the watchdog
        # heals whatever DID build it.
        DisplayServer.window_set_position(scr.position)
        DisplayServer.window_set_size(scr.size)
        await get_tree().process_frame
        _check(DisplayServer.window_get_size() == scr.size,
                "the poison shape is seeded (windowed, screen-covering)")
        var healed := ScaleRule.heal_poison_shape()
        _check(healed, "the watchdog FIRED on the poison shape")
        await get_tree().create_timer(0.3).timeout
        _check(DisplayServer.window_get_mode()
                == DisplayServer.WINDOW_MODE_WINDOWED,
                "healed: honest WINDOWED bookkeeping")
        _check(DisplayServer.window_get_size() == want,
                "healed: the exact windowed size again (got %s)" %
                        DisplayServer.window_get_size())
        # a healthy window never trips the watchdog (read-only steady state)
        _check(ScaleRule.heal_poison_shape() == false,
                "the watchdog sleeps on a healthy window")

        # ---- 5. THE DESIGN GOVERNOR + THE QUIET FRAME ----
        Box.dev_set_cheat("all_owned", 1)
        GameHost.launch(self, "matcher")
        await get_tree().create_timer(2.0).timeout
        var host: Node = GameHost.active_host
        _check(host != null and host.game != null, "the game is live")
        if host != null:
                _check(win.content_scale_size == ScaleRule.DESIGN_PORTRAIT,
                        "the game's design is seated (portrait)")
                # forge the drift: a WM fight / missed echo strands the
                # design - the governor must heal it within 2 frames
                win.content_scale_size = Vector2i(640, 480)
                await get_tree().process_frame
                await get_tree().process_frame
                _check(win.content_scale_size == ScaleRule.DESIGN_PORTRAIT,
                        "THE DESIGN GOVERNOR healed the drift (no more stuck)")
        # THE QUIET FRAME: steady state writes NOTHING (the r5 law, held)
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
