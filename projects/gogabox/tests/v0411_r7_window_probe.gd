extends Node
## v041-1 r7 THE WINDOW PROBE - the rotation-override round. Runs under a
## REAL display (the Xvfb rig): the window laws no-op on headless, so this
## probe is rig-only by design.
##   GODOT_BIN under xvfb-run --path projects/gogabox res://tests/v0411_r7_window_probe.tscn
## THE LAWS:
##   1. THE MID-FLIGHT LAW  - a game's position ask (the host's rotation
##      reload) silences the r6 design governor for the WHOLE flight: the
##      design flips to the ASKED orientation and NEVER snaps back (the
##      owner's Windows bug: "the window really rotate itself, but the
##      rotation is not even recognized as position rotation in the app,
##      likely because that lock" - the governor re-asserted the stale
##      orientation every frame of the wait, the ask was refused after 30
##      frames, the window stood rotated around un-rotated content).
##   2. THE OVERRIDE LANDS  - the reload completes: the game reboots in the
##      asked position (start_orientation), the design is the asked one,
##      the windowed window reshapes to the asked aspect (16:9), and back
##      again - the ANDROID PARITY: the game CAN override, the user still
##      cannot (F10 stays menu-only; this probe never touches it).
##   3. THE r6 REGRESSIONS  - F11 walks the two honest states; the quiet
##      frame writes nothing for 120 in-game frames.
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
        Box.dev_set_cheat("all_owned", 1)
        await get_tree().process_frame
        await get_tree().process_frame

        # ---- the windowed seat (portrait menu shape) ----
        ScaleRule.boot_window()
        await get_tree().create_timer(0.3).timeout
        _check(not ScaleRule.is_fullscreen(), "boot is windowed")

        # ---- launch a portrait game; its host owns the design ----
        var router := Node2D.new()
        add_child(router)
        var host_script: GDScript = load("res://game/core/game_host.gd")
        var launched: bool = host_script.launch(router, "matcher")
        _check(launched, "the game launches")
        if not launched:
                get_tree().quit(1)
                return
        await get_tree().create_timer(2.0).timeout
        var host: Node = host_script.active_host
        _check(host != null and host.game != null, "the game is live")
        if host == null or host.game == null:
                host_script.end_session()
                get_tree().quit(1)
                return
        var game0: Node = host.game
        _check(win.content_scale_size == ScaleRule.DESIGN_PORTRAIT,
                "the game sits portrait (design %s)" % win.content_scale_size)

        # ---- 1. THE MID-FLIGHT LAW (THE r7 FIX) ----
        # fire the ask WITHOUT awaiting it: sample the design every frame
        # through the flight - a single portrait read means the governor
        # fought the rotation (the pre-r7 disease)
        host._on_orientation_reload("horizontal")
        var clean := true
        for i in 12:
                await get_tree().process_frame
                if win.content_scale_size != ScaleRule.DESIGN_LANDSCAPE:
                        clean = false
        _check(clean, "MID-FLIGHT: the design NEVER snaps back (%d frames sampled)"
                        % (12 if clean else 0))
        # ---- 2. THE OVERRIDE LANDS ----
        var waited := 0.0
        while String(host._orient_now) != "horizontal" and waited < 6.0:
                await get_tree().process_frame
                waited += get_process_delta_time()
        _check(String(host._orient_now) == "horizontal",
                "the override LANDS (orient_now horizontal, %.2fs)" % waited)
        _check(win.content_scale_size == ScaleRule.DESIGN_LANDSCAPE,
                "the design is landscape (got %s)" % win.content_scale_size)
        _check(win.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP,
                "the aspect stays KEEP (no stretch)")
        var wsz := DisplayServer.window_get_size()
        _check(wsz.x > wsz.y, "the windowed window reshapes WIDE (%dx%d)"
                        % [wsz.x, wsz.y])
        _check(host.game != game0,
                "the game RELOADED (a new instance wears the ask)")
        _check(String(host.game.start_orientation) == "horizontal",
                "the reloaded game wears start_orientation=horizontal")
        await get_tree().create_timer(0.6).timeout

        # ---- and back: the ask lands BOTH ways ----
        host._on_orientation_reload("vertical")
        waited = 0.0
        while String(host._orient_now) != "vertical" and waited < 6.0:
                await get_tree().process_frame
                waited += get_process_delta_time()
        _check(String(host._orient_now) == "vertical",
                "the override returns (orient_now vertical, %.2fs)" % waited)
        _check(win.content_scale_size == ScaleRule.DESIGN_PORTRAIT,
                "the design is portrait again (got %s)"
                        % win.content_scale_size)
        wsz = DisplayServer.window_get_size()
        _check(wsz.y > wsz.x, "the windowed window reshapes TALL (%dx%d)"
                        % [wsz.x, wsz.y])
        await get_tree().create_timer(0.6).timeout

        # ---- 3a. THE r6 F11 REGRESSION (two honest states) ----
        ScaleRule.set_fullscreen(true)
        await get_tree().create_timer(0.4).timeout
        _check(DisplayServer.window_get_mode()
                == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
                "F11: EXCLUSIVE fullscreen (the true seat)")
        ScaleRule.set_fullscreen(false)
        await get_tree().create_timer(0.6).timeout
        _check(DisplayServer.window_get_mode()
                == DisplayServer.WINDOW_MODE_WINDOWED, "F11 back: WINDOWED")
        _check(not ScaleRule.is_fullscreen()
                and win.content_scale_size == ScaleRule.DESIGN_PORTRAIT,
                "the design survived the dance (portrait, KEEP)")

        # ---- 3b. THE QUIET FRAME (120 in-game frames write NOTHING) ----
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

        host_script.end_session()
        await get_tree().create_timer(0.6).timeout

        if _fails == 0:
                print("PROBE_OK: ALL GREEN")
                get_tree().quit(0)
        else:
                print("PROBE_FAIL: %d failures" % _fails)
                get_tree().quit(1)
