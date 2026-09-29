extends Node
## v044-1 THE FULLSCREEN SETTLE PROBE - the owner's rotation report,
## reproduced on the rig: "tested the rotation half-background, it does
## not exist in windowed window, but it happens in the app in full screen".
## Runs under a REAL display (the Xvfb rig), rig-only by design.
##
## THE OLD DISEASE (PC fullscreen): a rotation ask flipped the canvas to
## the ASKED design, then the mid-flight gate waited for the PHYSICAL
## window to follow - a fullscreen window is the monitor, it NEVER follows.
## The wait expired, the refuse path "settled" by re-reading the canvas
## (already flipped - the lie), the design stayed at the refused ask, the
## world kept its OLD shape under it, and the game was never rebuilt: the
## half background + the brown fallback, forever (the kind watcher only
## re-asked into the same refuse).
##
## THE LAW NOW: in fullscreen the CANVAS is the whole truth (the same
## exemption the boot gate earned) - the ask resolves in frames, the game
## rebuilds at the asked kind, the letterbox wears the ink. A real refusal
## (a phone's rotation lock) settles on the PHYSICAL window kind and
## RE-SEATS the world when it disagrees.
##
##   GODOT_BIN under xvfb-run --path projects/gogabox res://tests/v0441_fs_settle.tscn
## Exit 0 + PROBE_OK = all green. Screenshots land in /tmp/v0441_fs/.

var _fails := 0

func _fail(msg: String) -> void:
        _fails += 1
        print("PROBE_FAIL: ", msg)

func _check(ok: bool, msg: String) -> void:
        if ok:
                print("PROBE_OK: ", msg)
        else:
                _fail(msg)

func _shot(name_: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/v0441_fs/" + name_)
        print("PROBE_SHOT: /tmp/v0441_fs/", name_)

func _ready() -> void:
        if DisplayServer.get_name() == "headless":
                print("PROBE_SKIP: headless - the window laws are phone/PC-laws")
                get_tree().quit(0)
                return
        DirAccess.make_dir_recursive_absolute("/tmp/v0441_fs")
        var win := get_window()
        Box.reset_all()
        # the rig home wears the shipping set (the artifact shape), the
        # same seat the eye pass uses - then the cheats arm on top
        GOGA.set_home("user://fs_rig")
        var repo_root := ProjectSettings.globalize_path("res://").path_join("../..")
        _copy(repo_root.path_join("GOGAs/games"), GOGA.games_dir())
        GOGA.reload_entries()
        GOGA._settings["dev_cheats"] = true   # v044-1: the rig arms the master
        Box.dev_set_cheat("all_owned", 1)
        await get_tree().process_frame
        await get_tree().process_frame

        # ---- boot windowed, launch a PORTRAIT game ----
        ScaleRule.boot_window()
        await get_tree().create_timer(0.3).timeout
        var router := Node2D.new()
        add_child(router)
        var host_script: GDScript = load("res://game/core/game_host.gd")
        var launched: bool = host_script.launch(router, "matcher")
        _check(launched, "the portrait game launches")
        if not launched:
                get_tree().quit(1)
                return
        await get_tree().create_timer(2.0).timeout
        # the world build is slow under llvmpipe - poll, don't guess
        var live := false
        var t_live := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t_live < 15000:
                var h0: Node = host_script.active_host
                if h0 != null and h0.game != null and is_instance_valid(h0.game):
                        live = true
                        break
                await get_tree().process_frame
        _check(live, "the game is live")
        var host: Node = host_script.active_host
        var game0: Node = host.game if live else null
        _check(win.content_scale_size == ScaleRule.DESIGN_PORTRAIT,
                "the game sits portrait (design %s)" % win.content_scale_size)
        _check(game0 != null and String(game0.get("view_kind")) == "vertical",
                "the world is built vertical")

        # ---- THE OWNER'S REPRO: flip to fullscreen, then rotate the ask ----
        # the session flag opens at the END of the host's boot chain - an
        # ask fired before it is (by design) ignored, the boot owns the
        # canvas. Wait for it, exactly like a player's tap would.
        win.mode = Window.MODE_FULLSCREEN
        await get_tree().create_timer(0.4).timeout
        _check(ScaleRule.is_fullscreen(), "the window sits fullscreen now")
        _check(win.content_scale_size == ScaleRule.DESIGN_PORTRAIT,
                "the design survived the mode flip")
        var t_sess := Time.get_ticks_msec()
        while not bool(host._session_open) \
                        and Time.get_ticks_msec() - t_sess < 15000:
                await get_tree().process_frame
        _check(bool(host._session_open), "the host session is open")

        # the ask to HORIZONTAL in fullscreen: the canvas honors it (the
        # window half is exempt) and the game REBUILDS - the whole ask
        # resolves in frames, not the old 1.5s refuse
        var t0 := Time.get_ticks_msec()
        print("PROBE: calling door on ", host, " script=", host.get_script().resource_path,
                        " has_door=", host.has_method("_on_orientation_reload"),
                        " orient=", host._orient_now)
        host._on_orientation_reload("horizontal")
        print("PROBE: door call returned")
        var game1: Node = null
        # the poll is WALL-CLOCK, not frames - under llvmpipe a frame can
        # take 50ms+, so a frame-count window expires before the world lands
        while Time.get_ticks_msec() - t0 < 15000:
                await get_tree().process_frame
                var h: Node = host_script.active_host
                if h != null and h.game != null and h.game != game0 \
                                and is_instance_valid(h.game):
                        game1 = h.game
                        break
        var ms := Time.get_ticks_msec() - t0
        if game1 == null:
                var h: Node = host_script.active_host
                print("PROBE_DEBUG: game0=", game0.get_instance_id(),
                                " host.game=", (h.game.get_instance_id() \
                                if h != null and h.game != null else -1),
                                " orient=", h._orient_now,
                                " gate=", h._gate_open,
                                " design=", win.content_scale_size)
        _check(game1 != null, "the world rebuilt at the asked kind (%d ms)" % ms)
        if game1 != null:
                _check(String(game1.get("start_orientation")) == "horizontal",
                                "the rebuild wears the asked orientation")
                _check(String(game1.get("view_kind")) == "horizontal",
                                "the world is built horizontal now")
        _check(win.content_scale_size == ScaleRule.DESIGN_LANDSCAPE,
                "the design is landscape under the fullscreen window")
        _check(String(host._orient_now) == "horizontal",
                "the host owns the horizontal truth (no stuck mid-flight)")
        await get_tree().create_timer(1.4).timeout
        # the watcher beat passed: the ask did not bounce back
        _check(String(host._orient_now) == "horizontal"
                        and win.content_scale_size == ScaleRule.DESIGN_LANDSCAPE,
                "the settle holds through the watcher beat")
        await _shot("01_fs_horizontal.png")

        # ---- and back: the mirror ask, same laws ----
        var game2: Node = null
        var t1 := Time.get_ticks_msec()
        host._on_orientation_reload("vertical")
        while Time.get_ticks_msec() - t1 < 15000:
                await get_tree().process_frame
                var h: Node = host_script.active_host
                if h != null and h.game != null and h.game != game1 \
                                and is_instance_valid(h.game):
                        game2 = h.game
                        break
        _check(game2 != null, "the world rebuilt back to vertical")
        _check(win.content_scale_size == ScaleRule.DESIGN_PORTRAIT,
                "the design is portrait again")
        await get_tree().create_timer(1.4).timeout
        await _shot("02_fs_vertical.png")

        # ---- the fullscreen exit leaves an honest windowed seat ----
        win.mode = Window.MODE_WINDOWED
        await get_tree().create_timer(0.6).timeout
        _check(not ScaleRule.is_fullscreen(), "back to windowed")
        host_script.end_session()
        await get_tree().create_timer(0.5).timeout
        ScaleRule.apply_pc(win, ScaleRule.pc_menu_design())
        ScaleRule.re_window(ScaleRule.pc_position)
        await get_tree().create_timer(0.4).timeout
        _check(win.content_scale_size == ScaleRule.pc_menu_design(),
                "the menu design re-asserts after the dance")

        if _fails == 0:
                print("PROBE_OK: ALL GREEN - the fullscreen settle law holds")
                get_tree().quit(0)
        else:
                print("PROBE_FAIL: %d fails" % _fails)
                get_tree().quit(1)

func _copy(src: String, dst: String) -> void:
        DirAccess.make_dir_recursive_absolute(dst)
        var da := DirAccess.open(src)
        if da == null:
                return
        da.list_dir_begin()
        var n := da.get_next()
        while n != "":
                var s2 := src.path_join(n)
                var d := dst.path_join(n)
                if da.current_is_dir():
                        _copy(s2, d)
                else:
                        da.copy(s2, d)
                n = da.get_next()
        da.list_dir_end()
