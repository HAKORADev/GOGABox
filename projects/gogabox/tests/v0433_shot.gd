extends Node
## v043 PASS 3 THE EYE PASS - the owner's Windows test round, re-shot:
##   01 the design-first boot (the persisted LANDSCAPE choice must wear
##      the landscape design from the first frame - the mis-scale kill)
##   02 the discover arrow through the REAL input stack (a synthesized
##      touch press/release on the arrow - the tappable law)
##   03 the discover feed over the schema-2 catalog (five pilots incl.
##      the web pilot)
##   04 the WEB SEAT live under X: orbit launches through the runner, the
##      app-mode browser opens, the localhost server serves it
##   05 the rebuilt APP UPDATES sheet (the schedule, auto-download)
##   06 the search sheet's chip law (the age words, the hardcoded tables)
## Renders under Xvfb, saved to tests/v0433_shot/, reviewed BY EYE.

const OUT := "res://tests/v0433_shot"

func _ready() -> void:
        DirAccess.make_dir_recursive_absolute(OUT)
        # THE RIG: the pilots install (the feed needs a real world)
        GOGA.set_home("user://goga_rig")
        _wipe("user://goga_rig")
        GOGA.set_home("user://goga_rig")
        var repo_root := ProjectSettings.globalize_path("res://").path_join("../..")
        GOGA.import_path(repo_root.path_join("GOGAs/games"))

        # ---- 01 THE DESIGN-FIRST BOOT ----
        # persist the landscape choice exactly like F10 leaves it, then run
        # the boot law: the design must LAND before any shape write, and
        # the window must agree - the owner's horizontal-window/vertical-
        # content mis-scale dies here.
        Box.set_pc_position("landscape")
        var menu: Node = load("res://game/menu/menu.gd").new()
        add_child(menu)
        menu.set("router", self)   # the launch road (main.gd's own wiring)
        await get_tree().create_timer(1.2).timeout
        var design := get_window().content_scale_size
        var ws := DisplayServer.window_get_size()
        var design_ok: bool = design == ScaleRule.DESIGN_LANDSCAPE
        var window_ok: bool = ws.x > ws.y
        print("SHOT01: design=%s (want %s) window=%s design_ok=%s window_ok=%s"
                        % [design, ScaleRule.DESIGN_LANDSCAPE, ws, design_ok, window_ok])
        await _shot("01_boot_landscape_design_first")
        var grid_cols: int = menu._grid.columns
        print("SHOT01: grid columns=%d (landscape law wants 3+)" % grid_cols)

        # ---- 02 THE ARROW THROUGH THE REAL INPUT STACK ----
        # THE REAL-CLICK LAW (r4): parse_input_event eats WINDOW px - the
        # design coords ride the content-scale transform first. A parsed
        # mouse click also breeds the emulated touch the BoxScroll owns -
        # exactly the wire a real Windows click rides.
        var arrow: Control = menu.get("_discover_arrow")
        await get_tree().create_timer(0.3).timeout
        _click(arrow.get_global_rect().get_center())
        await get_tree().create_timer(0.6).timeout
        var head_text := String(menu.get("_all_head").text)
        var kind := String(menu.get("_feed_kind"))
        print("SHOT02: headline=%s feed_kind=%s (the tappable arrow works: %s)"
                        % [head_text, kind, head_text == "DISCOVER"])
        await _shot("02_arrow_real_click_discover")
        # back to installed for the rest of the pass
        menu.call("_toggle_feed_kind")
        await get_tree().create_timer(0.4).timeout

        # ---- 03 THE FEED OVER THE SCHEMA-2 CATALOG ----
        GogaDiscover.add_source({"kind": "local", "path": repo_root})
        menu.call("_toggle_feed_kind")
        var waited := 0.0
        while (menu.get("_discover_rows") as Array).is_empty() and waited < 20.0:
                await get_tree().create_timer(0.5).timeout
                waited += 0.5
        await get_tree().create_timer(0.8).timeout
        var rows: Array = menu.get("_discover_rows")
        var ids: Array = rows.map(func(r): return String(r["game_id"]))
        print("SHOT03: rows=%d ids=%s" % [rows.size(), str(ids)])
        await _shot("03_discover_feed_catalog")

        # ---- 04 THE WEB SEAT LIVE UNDER X ----
        Box.unlock_game("orbit", 0)
        var host_script: GDScript = load("res://game/core/game_host.gd")
        var launched: bool = host_script.launch(menu.router, "orbit")
        await get_tree().create_timer(2.5).timeout
        var host: Node = host_script.active_host
        var web_live := false
        var web_url := ""
        if host != null and host._runner != null:
                web_live = host._runner.mode == "web" and host._runner.pid > 0
                web_url = String(host._runner.url)
        print("SHOT04: launched=%s live=%s url=%s" % [launched, web_live, web_url])
        await _shot("04_web_seat_running")
        if host != null:
                host._quit_to_menu()
        await get_tree().create_timer(0.8).timeout
        # the browser child must be gone with the session (the teardown law)
        var web_dead := true
        if host != null and host._runner != null:
                web_dead = host._runner.pid <= 0
        print("SHOT04: teardown dead=%s" % web_dead)

        # ---- 05 THE REBUILT APP UPDATES SHEET ----
        menu.call("_open_update_sheet")
        await get_tree().create_timer(1.5).timeout
        await _shot("05_app_updates_sheet")
        menu.call("_close_sheet")
        await get_tree().create_timer(0.4).timeout

        # ---- 06 THE SEARCH SHEET (the chip law) ----
        menu.call("_open_search")
        await get_tree().create_timer(1.2).timeout
        await _shot("06_search_chips")
        print("V0433SHOT: done")
        get_tree().quit(0)

## THE REAL-CLICK LAW (r4): parse_input_event eats WINDOW px - the design
## coordinates ride the content-scale transform first.
func _design_to_window(at: Vector2) -> Vector2:
        var win := get_window()
        var vp := win.get_visible_rect().size
        var wpx := DisplayServer.window_get_size()
        var s := minf(float(wpx.x) / vp.x, float(wpx.y) / vp.y)
        var off := (Vector2(wpx) - vp * s) * 0.5
        return off + at * s

func _click(pos: Vector2) -> void:
        var wp := _design_to_window(pos)
        var press := InputEventMouseButton.new()
        press.button_index = MOUSE_BUTTON_LEFT
        press.pressed = true
        press.position = wp
        press.global_position = wp
        Input.parse_input_event(press)
        var release := InputEventMouseButton.new()
        release.button_index = MOUSE_BUTTON_LEFT
        release.pressed = false
        release.position = wp
        release.global_position = wp
        Input.parse_input_event(release)

func _shot(name_: String) -> void:
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png(OUT.path_join(name_ + ".png"))

func _wipe(path: String) -> void:
        if DirAccess.dir_exists_absolute(path):
                _wipe_dir(path)
        DirAccess.make_dir_recursive_absolute(path)

func _wipe_dir(path: String) -> void:
        var da := DirAccess.open(path)
        if da == null:
                return
        da.list_dir_begin()
        var n := da.get_next()
        while n != "":
                var full := path.path_join(n)
                if da.current_is_dir():
                        _wipe_dir(full)
                        DirAccess.remove_absolute(full)
                else:
                        da.remove(n)
                n = da.get_next()
        da.list_dir_end()
