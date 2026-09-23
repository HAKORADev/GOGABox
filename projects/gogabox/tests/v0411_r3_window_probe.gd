extends Node
## v0411_r3_window_probe - THE F10-PARITY RIG (the owner: "the app only
## switches accurately to F10 switches, see why it works accurately with
## manual switches, then make the automatic switches be the same").
## Boots the REAL main scene (splash + menu + the box governors), then:
##   1. THE LAUNCH LAW: a landscape game launched from a portrait menu must
##      keep the LANDSCAPE design from its first frame - the menu's
##      size_changed stomp (r2's mis-scale engine) is dead (the
##      one-design-writer law). Sampled every frame across the flight.
##   2. THE RELOAD LAW: the orientation reload through the LIVE app lands
##      both ways with the design honest on every sampled frame.
##   3. THE QUIT LAW: quitting hands the canvas back to the menu's design
##      (pc_position) and the window follows.
## Run under Xvfb: DISPLAY=:96 godot --path . res://tests/v0411_r3_window_probe.tscn

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
                print("PROBE_SKIP: headless")
                get_tree().quit(0)
                return
        var win := get_window()
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        # the persisted position: PORTRAIT (the menu's own seat)
        if Box.has_method("set_pc_position"):
                Box.set_pc_position("portrait")
        ScaleRule.pc_position = "portrait"

        # ---- boot the REAL app (the menu lives, its governors run) ----
        var main_scene: PackedScene = load("res://main.tscn")
        var main: Node = main_scene.instantiate()
        add_child(main)
        # the splash + the menu build
        await get_tree().create_timer(2.0).timeout
        _check(win.content_scale_size == ScaleRule.DESIGN_PORTRAIT,
                "the menu boots portrait (design %s)"
                        % str(win.content_scale_size))

        # ---- 1. THE LAUNCH LAW: a landscape game from a portrait menu ----
        var GH: GDScript = load("res://game/core/game_host.gd")
        _check(GH.launch(main, "heavywar"), "heavy war launches")
        var host: Node = null
        for i in 200:
                await get_tree().process_frame
                host = GH.active_host
                if host != null and is_instance_valid(host) \
                                and host.game != null:
                        break
        _check(host != null and host.game != null, "the game is live")
        if host == null or host.game == null:
                get_tree().quit(1)
                return
        # THE SAMPLING: every frame for 90 frames the design must wear the
        # GAME'S landscape - the menu's size_changed hook used to stomp it
        # back to portrait within a frame of the re_window echo (the r2
        # mis-scale engine: "a vertical image in the horizontal view")
        var clean := true
        for i in 90:
                await get_tree().process_frame
                if win.content_scale_size != ScaleRule.DESIGN_LANDSCAPE:
                        clean = false
        _check(clean, "LAUNCH: the design stays the GAME'S through 90 "
                + "frames of live menu governors")
        _check(win.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP,
                "the aspect stays KEEP")
        var wsz := DisplayServer.window_get_size()
        _check(wsz.x > wsz.y, "the window sits WIDE (%dx%d)"
                        % [wsz.x, wsz.y])

        # ---- 2. THE RELOAD LAW through the live app (portrait ask) ----
        host._on_orientation_reload("vertical")
        var clean2 := true
        for i in 90:
                await get_tree().process_frame
                if win.content_scale_size != ScaleRule.DESIGN_PORTRAIT:
                        clean2 = false
        _check(clean2, "RELOAD: the design stays the ASK'S (portrait) "
                + "through 90 frames")
        var waited := 0.0
        while String(host._orient_now) != "vertical" and waited < 6.0:
                await get_tree().process_frame
                waited += get_process_delta_time()
        _check(String(host._orient_now) == "vertical",
                "the reload LANDS (vertical, %.2fs)" % waited)
        wsz = DisplayServer.window_get_size()
        _check(wsz.y > wsz.x, "the window sits TALL (%dx%d)"
                        % [wsz.x, wsz.y])

        # ---- 3. THE QUIT LAW: the menu takes its canvas back ----
        host._quit_to_menu()
        await get_tree().process_frame
        await get_tree().process_frame
        await get_tree().create_timer(0.3).timeout
        _check(win.content_scale_size == ScaleRule.DESIGN_PORTRAIT,
                "QUIT: the menu design returns (%s)"
                        % str(win.content_scale_size))
        _check(GH.active_host == null, "the session closed")

        # ---- 4. THE FULLSCREEN LAW: the design still follows the content
        # when the monitor cannot follow it (the owner's fullscreen
        # "vertical and stretched" report) ----
        ScaleRule.set_fullscreen(true)
        await get_tree().create_timer(0.4).timeout
        _check(ScaleRule.is_fullscreen(), "the box goes fullscreen")
        _check(GH.launch(main, "heavywar"), "heavy war launches fullscreen")
        host = null
        for i in 200:
                await get_tree().process_frame
                host = GH.active_host
                if host != null and is_instance_valid(host) \
                                and host.game != null:
                        break
        _check(host != null and host.game != null,
                "the fullscreen game is live")
        if host != null and host.game != null:
                var clean3 := true
                for i in 90:
                        await get_tree().process_frame
                        if win.content_scale_size \
                                        != ScaleRule.DESIGN_LANDSCAPE:
                                clean3 = false
                _check(clean3, "FULLSCREEN: the design stays the GAME'S "
                                + "through 90 frames")
                host._quit_to_menu()
                await get_tree().create_timer(0.3).timeout
        ScaleRule.set_fullscreen(false)
        await get_tree().create_timer(0.4).timeout
        _check(win.content_scale_size == ScaleRule.DESIGN_PORTRAIT,
                "the windowed menu returns (%s)"
                        % str(win.content_scale_size))

        print("PROBE_DONE: %d failures" % _fails)
        get_tree().quit(1 if _fails > 0 else 0)
