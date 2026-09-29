extends Node
## v0421r4_shot — THE EYE PASS (law 32) for the ROUND-4 patch:
##   1. the SCROLLABLE profile sheet (the owner: "the profile menu is not
##      up-down scrollable, make it scrollable")
##   2. the invite card's DECLINE takes a REAL click over the feed (the
##      owner: "in menu, it is tap-through and not tappable") and the
##      decline wire fires
##   3. DOMINO horizontal -> the VERTICAL pick (a real click) -> the
##      reload -> the background covers EVERY pixel (the owner's half-bg
##      report: "background appears from top to middle, under middle is
##      the brown GOGABox fallback")
##   4. SLASHER same dance (the second game in the report)
##   5. SLASHER + TOWER DESTROYER's LAN ROOM SCREEN (the owner: "both
##      fruit slasher and tower destroyer crashed in multiplayer wait
##      menu even before the game starts")

const HOST_BROWN := Color("241407")

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        DirAccess.make_dir_recursive_absolute("/tmp/v0421r4_shots")
        print("=== v042-1 r4 EYE PASS ===")
        LanProfile.set_player_name("TESTER")
        LanProfile.save()
        Box.earn(100000)
        # THE ALWAYS-PLAYABLE CHEAT: the eye pass launches the same games
        # repeatedly - the battery/daily gates would refuse the 3rd boot
        GOGA._settings["dev_cheats"] = true   # v044-1: the rig arms the master
        Box.dev_set_cheat("all_owned", 1)
        Box.unlock_game("domino", 0)
        Box.unlock_game("slasher", 0)
        Box.unlock_game("towerdestroyer", 0)
        var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
        add_child(main)
        await _wait(5.0)
        var menu := _find_menu(main)
        if menu == null:
                print("EYE FAIL: no menu found")
                get_tree().quit(1)
                return
        # --- 1. the profile sheet (the scroll) ---
        menu.call("_close_sheet")
        menu.call("_open_profile")
        await _wait(0.7)
        await _shot("1_profile_sheet")
        menu.call("_close_sheet")
        # 1b. the profile in a LANDSCAPE seat: the bounded sheet must wrap
        # into the BoxScroll (the scrollable law on short canvases)
        if ScaleRule.is_pc():
                ScaleRule.pc_position = "landscape"
                ScaleRule.apply_pc(get_window(), ScaleRule.DESIGN_LANDSCAPE)
                ScaleRule.re_window("landscape")
                await _wait(1.0)
                menu.call("_open_profile")
                await _wait(0.7)
                await _shot("1b_profile_landscape_scroll")
                menu.call("_close_sheet")
                ScaleRule.pc_position = "portrait"
                ScaleRule.apply_pc(get_window(), ScaleRule.DESIGN_PORTRAIT)
                ScaleRule.re_window("portrait")
                await _wait(1.0)
        # --- 2. the invite card: a REAL click on DECLINE over the feed ---
        LanNotes.invite_card("HANNA", "192.168.1.44:31440", false,
                "192.168.1.44", "eyeDevDecline")
        await _wait(0.7)
        await _shot("2_invite_card_up")
        var declined_seen := {"v": false}
        LANFIND.declined.connect(func(_n, _w): declined_seen["v"] = true)
        var declined_btn := _find_button(main, "DECLINE")
        if declined_btn == null:
                print("EYE FAIL: no DECLINE button on the card")
        else:
                var rect := declined_btn.get_global_rect()
                print("DECLINE rect: %s" % rect)
                _click(rect.get_center() + Vector2(0, 2))
                await _wait(0.8)
                await _shot("2b_invite_card_down")
                print("DECLINE CLICKED: card down=%s" % str(LanNotes.blocks_point(rect.get_center()) == false))
        # --- 3. DOMINO: horizontal boot -> pick vertical -> the bg census ---
        await _rotate_eye("domino")
        # --- 4. SLASHER: same dance ---
        await _rotate_eye("slasher")
        # --- 5. the LAN ROOM SCREENS (the crash round) ---
        var lan := get_node_or_null("/root/LAN")
        var host_script: GDScript = load("res://game/core/game_host.gd")
        for gid in ["slasher", "towerdestroyer"]:
                if lan == null:
                        break
                # the seat must be free: the rotate phase's host lingers a
                # beat after end_session - wait for it honestly
                var free_wait := 0.0
                while host_script.active_host != null and free_wait < 6.0:
                        await _wait(0.5)
                        free_wait += 0.5
                lan.host_session()
                await _wait(0.4)
                lan.seats.append({"dev": "eyeDev2", "name": "HANNA", "pfp": 2,
                        "pfpm": {}, "desc": "", "links": [], "age": 0,
                        "gender": "female", "role": "gamer", "anchor": "",
                        "seat": 2, "local_slot": 0, "platform": "android",
                        "state": "lobby"})
                lan.session_changed.emit()
                print("PHASE room_screen %s begin" % gid)
                var router := Node2D.new()
                add_child(router)
                var launched: bool = host_script.launch(router, gid)
                print("%s launch: %s" % [gid, launched])
                await _wait(4.0)
                await _shot("5_room_screen_%s" % gid)
                # the owner's room view (CREATE MY ROOM via the wire, the
                # screen repaints through rooms_changed)
                if host_script.active_host != null:
                        var gh: Node = host_script.active_host
                        if gh.game != null:
                                gh.game.call("lan_hold_begin") if false else null
                var errc: String = lan.open_room(gid, {})
                print("open room: '%s'" % errc)
                await _wait(0.8)
                await _shot("5b_room_owner_%s" % gid)
                print("PHASE room_screen %s end" % gid)
                host_script.end_session()
                await _wait(1.0)
        print("=== EYE PASS DONE ===")
        get_tree().quit(0)

## One game's horizontal -> vertical dance with the pixel census.
## THE OWNER'S REPRO SHAPE: his PC menu sat HORIZONTAL, the "auto" game
## booted landscape, and the VERTICAL pick reloaded through the host.
func _rotate_eye(gid: String) -> void:
        var host_script: GDScript = load("res://game/core/game_host.gd")
        # force the PC menu seat LANDSCAPE first (the owner's menu state)
        if ScaleRule.is_pc():
                ScaleRule.pc_position = "landscape"
                ScaleRule.apply_pc(get_window(), ScaleRule.DESIGN_LANDSCAPE)
                ScaleRule.re_window("landscape")
                await _wait(1.0)
        var router := Node2D.new()
        add_child(router)
        print("PHASE rotate %s begin" % gid)
        var launched: bool = host_script.launch(router, gid)
        print("%s launch: %s" % [gid, launched])
        await _wait(5.0)
        var host: Node = host_script.active_host
        if host == null or host.game == null:
                print("EYE FAIL: no %s host" % gid)
                print("PHASE rotate %s end" % gid)
                return
        await _shot("3_%s_landscape_ask" % gid)
        # a REAL click on the VERTICAL card (the ask screens' own label)
        var card := _find_button(host.game, "VERTICAL")
        if card == null:
                print("EYE FAIL: no VERTICAL card on %s's ask" % gid)
        else:
                _click(card.get_global_rect().get_center() + Vector2(0, 2))
                # the reload waits for the REAL window (up to ~1.5s) + boots
                await _wait(4.0)
                await _shot("3_%s_vertical_live" % gid)
                _census("3_%s_vertical_live" % gid)
        host_script.end_session()
        await _wait(1.0)
        print("PHASE rotate %s end" % gid)

## THE PIXEL CENSUS: how much host-brown shows in the bottom half (the
## owner's "under middle is the brown GOGABox fallback").
func _census(shot_name: String) -> void:
        var img := get_viewport().get_texture().get_image()
        var sz := img.get_size()
        var brown := 0
        var total := 0
        for y in range(int(sz.y * 0.55), sz.y, 4):
                for x in range(0, sz.x, 4):
                        total += 1
                        var c := img.get_pixel(x, y)
                        if absf(c.r - HOST_BROWN.r) < 0.02 \
                                        and absf(c.g - HOST_BROWN.g) < 0.02 \
                                        and absf(c.b - HOST_BROWN.b) < 0.02:
                                brown += 1
        print("CENSUS %s: %d/%d sampled bottom px are the host brown (%.1f%%)" % [
                        shot_name, brown, total, 100.0 * float(brown) / maxf(1.0, float(total))])

## r4 THE REAL-CLICK LAW: parse_input_event eats WINDOW px - the design
## coordinates ride the content-scale transform first (click_probe's law).
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

func _find_button(root: Node, txt: String) -> Button:
        if root is Button:
                var b := root as Button
                if String(b.text).to_upper().contains(txt) \
                                or _subtree_text(b).contains(txt):
                        return b
        for c in root.get_children():
                var f := _find_button(c, txt)
                if f != null:
                        return f
        return null

func _subtree_text(root: Node) -> String:
        var out := ""
        if root is Label or root is RichTextLabel:
                out += " " + (root as Control).get("text")
        for c in root.get_children():
                out += " " + _subtree_text(c)
        return out.to_upper()

func _shot(name_v: String) -> void:
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/v0421r4_shots/%s.png" % name_v)
        print("shot: %s" % name_v)

func _find_menu(root: Node) -> Node:
        if root.get_script() != null \
                        and String((root.get_script() as Script).resource_path).ends_with("menu.gd"):
                return root
        for c in root.get_children():
                var m := _find_menu(c)
                if m != null:
                        return m
        return null

func _wait(sec: float) -> void:
        var t := 0.0
        while t < sec:
                await get_tree().process_frame
                t += get_process_delta_time()
