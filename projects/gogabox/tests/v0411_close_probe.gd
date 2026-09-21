extends Node
## v041-1 probe: THE DEAD CLOSE BUTTON - the owner's report: "in ping-pong
## when the time is closed... the pre-play close button when tapped/clicked,
## it does not close, but pressing ESC closes it".
## The rig: boot the real box, force-own pong, inject a blocked_hours window
## that is CLOSED at the CURRENT hour, open the pre-play page, synthesize a
## real click on the CLOSE button, then report whether the sheet died.

var fails := 0

func ck(cond: bool, what: String) -> void:
        if cond:
                print("  ok - %s" % what)
        else:
                fails += 1
                print("PROBE_FAIL - %s" % what)

func _ready() -> void:
        await get_tree().process_frame
        if DisplayServer.get_name() == "headless":
                print("PROBE_SKIP - needs a real window")
                get_tree().quit(0)
                return
        Box.reset_all()
        var main := Node2D.new()
        main.set_script(load("res://game/main.gd"))
        add_child(main)
        # let the splash cover the boot; kill it by ending the splash
        await get_tree().create_timer(2.2).timeout
        var menu: Node = main.get("Menu") if main.get("Menu") != null \
                        else main.get_node_or_null("Menu")
        if menu == null:
                # the menu node's name is "Menu" (main.gd) - retry the walk
                for c in main.get_children():
                        if c.has_method("apply_resolution"):
                                menu = c
                                break
        ck(menu != null, "the menu node exists")
        if menu == null:
                print("PROBE_FAIL - no menu")
                get_tree().quit(1)
                return

        # ---- force-own pong + make its window CLOSED right now ----
        Box.dev_grant_everything()
        var pong := GameReg.get_game("rally")
        ck(not pong.is_empty(), "pong is in the registry")
        # PING-PONG wears daily_rounds (the owner's "rate-limit of
        # time-based") - exhaust the cap like 6 played rounds would
        for i in 6:
                Box.record_started("rally")
        ck(not Box.daily_ok("rally"), "rally's daily limit is reached")

        # ---- open the pre-play page ----
        menu.call("_open_game_page", pong)
        await get_tree().process_frame
        await get_tree().process_frame
        ck(bool(menu.get("_sheet_open")), "the pre-play sheet is open")

        # ---- find the CLOSE button (the sheet's vb: last direct child) ----
        var root: Control = menu.get("_root")
        var pair: Array = menu.get("_sheet_pair")
        ck(pair.size() == 2, "the sheet pair is tracked")
        var cc: Control = pair[1] as Control
        var vb: VBoxContainer = null
        var stack := [cc]
        while not stack.is_empty():
                var n: Node = stack.pop_back()
                if n is VBoxContainer and (n as VBoxContainer).get_child_count() > 0:
                        vb = n
                        break
                stack.append_array(n.get_children())
        ck(vb != null, "the sheet's VBox found")
        if vb == null:
                get_tree().quit(1)
                return
        var close_btn: BaseButton = null
        for c in vb.get_children():
                if c is BaseButton and String((c as BaseButton).text) == "CLOSE":
                        close_btn = c
        ck(close_btn != null, "the CLOSE button found")
        if close_btn == null:
                get_tree().quit(1)
                return
        var r := close_btn.get_global_rect()
        print("  CLOSE rect=", r, " visible=", close_btn.is_visible_in_tree())
        # window px -> the click must land in WINDOW space (the rig grab space)
        var vp := get_viewport()
        var ft := vp.get_final_transform()
        var wpos := ft * r.get_center()
        print("  click at window px=", wpos, " winsize=",
                        DisplayServer.window_get_size())

        # ---- synthesize a REAL click (press + release) ----
        var mb := InputEventMouseButton.new()
        mb.button_index = MOUSE_BUTTON_LEFT
        mb.pressed = true
        mb.position = wpos
        mb.global_position = wpos
        Input.parse_input_event(mb)
        await get_tree().process_frame
        var mb2 := mb.duplicate() as InputEventMouseButton
        mb2.pressed = false
        Input.parse_input_event(mb2)
        await get_tree().create_timer(1.3).timeout
        ck(not bool(menu.get("_sheet_open")), "THE CLOSE BUTTON CLOSED THE SHEET")

        if fails == 0:
                print("PROBE_OK - close law holds")
        else:
                print("PROBE_FAIL - %d checks failed" % fails)
        get_tree().quit(1 if fails > 0 else 0)
