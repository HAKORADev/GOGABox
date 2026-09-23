extends Node
## pause_input_probe - THE VERDICT RIG for the heavy-war XP-cards report.
## Questions (answered with pass/fail prints, no guessing):
##  A1: does a REAL Button (PROCESS_MODE_ALWAYS) receive a mouse click while
##      the tree is PAUSED?  (the sheet-stack law's own foundation)
##  A2: does a full-rect MOUSE_FILTER_STOP Control born INHERIT (=> paused)
##      sitting ABOVE that button eat the click while paused?  (the r2
##      birth shield's exact seat - if YES, the shield is the cards killer)
##  A3: does the r2 birth-shield tween (bound to the shield node) actually
##      advance + free the shield while the tree is PAUSED?
##  A4: same shield under a RUNNING tree (dies after ~0.05s)?
## Run: godot --path . res://tests/pause_input_probe.tscn (headless is fine:
##      GUI picking runs headless too).

var fails := 0

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        print("=== PAUSE INPUT PROBE ===")
        # ---- the stage: a gui root Control full-rect ----
        var root := Control.new()
        root.set_anchors_preset(Control.PRESET_FULL_RECT)
        root.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(root)

        # ============ CASE 0: the dispatch baseline - running tree, a bare
        # ALWAYS button, no dim, no shield. If THIS fails, the click road
        # itself is broken (rig disease, not engine truth).
        var b0 := _mk_button("CASE0")
        root.add_child(b0)
        await _settle(3)
        var hit0: Array = []
        b0.pressed.connect(func(): hit0.append(1))
        print("    window px: %s  visible rect: %s  btn rect: %s"
                        % [str(DisplayServer.window_get_size()),
                        str(get_window().get_visible_rect().size),
                        str(b0.get_global_rect())])
        await _click_at(b0.get_global_rect().get_center())
        await _settle(3)
        _verdict("A0 dispatch baseline (running tree, bare button)",
                        hit0.size() == 1)

        # ============ CASE 1: paused dim + ALWAYS button (the sheet law)
        var dim1 := ColorRect.new()
        dim1.color = Color(0, 0, 0, 0.5)
        dim1.set_anchors_preset(Control.PRESET_FULL_RECT)
        dim1.mouse_filter = Control.MOUSE_FILTER_STOP
        root.add_child(dim1)
        var cc1 := CenterContainer.new()
        cc1.set_anchors_preset(Control.PRESET_FULL_RECT)
        cc1.mouse_filter = Control.MOUSE_FILTER_IGNORE
        cc1.process_mode = Node.PROCESS_MODE_ALWAYS
        dim1.add_child(cc1)   # NOTE: child of dim1 - real sheet shape
        var b1 := _mk_button("CASE1")
        cc1.add_child(b1)
        await _settle(2)
        get_tree().paused = true
        await _settle(2)
        var hit1: Array = []
        b1.pressed.connect(func(): hit1.append(1))
        await _click_at(b1.get_global_rect().get_center())
        await _settle(2)
        get_tree().paused = false
        _verdict("A1 paused-tree ALWAYS button receives click", hit1.size() == 1)

        # ============ CASE 2: PAUSED BIRTH SHIELD above an ALWAYS button
        var cc2 := CenterContainer.new()
        cc2.set_anchors_preset(Control.PRESET_FULL_RECT)
        cc2.mouse_filter = Control.MOUSE_FILTER_IGNORE
        cc2.process_mode = Node.PROCESS_MODE_ALWAYS
        root.add_child(cc2)
        var b2 := _mk_button("CASE2")
        cc2.add_child(b2)
        # the shield: the r2 birth grace VERBATIM (INHERIT, tween dies)
        var shield := Control.new()
        shield.name = "SheetBirthShield"
        shield.set_anchors_preset(Control.PRESET_FULL_RECT)
        shield.mouse_filter = Control.MOUSE_FILTER_STOP
        root.add_child(shield)
        root.move_child(shield, root.get_child_count() - 1)
        shield.ready.connect(func():
                var tw := shield.create_tween()
                tw.tween_interval(0.05)
                tw.tween_callback(func():
                        if shield != null and is_instance_valid(shield):
                                shield.queue_free()))
        await _settle(2)
        get_tree().paused = true
        await _wait(0.30)      # the shield's 0.05s would long be over
        var hit2: Array = []
        b2.pressed.connect(func(): hit2.append(1))
        await _click_at(b2.get_global_rect().get_center())
        await _settle(2)
        var shield_alive := is_instance_valid(shield)
        get_tree().paused = false
        _verdict("A2 paused shield above ALWAYS button still eats click",
                        hit2.size() == 0)
        _verdict("A3 shield tween dies under PAUSED tree", not shield_alive)
        print("    (shield still alive after 0.30s paused: %s)"
                        % str(shield_alive))

        # ============ CASE 4: the FIXED shield (ready connected BEFORE the
        # add, ALWAYS process, pause-proof tween) under a RUNNING tree
        var cc4 := CenterContainer.new()
        cc4.set_anchors_preset(Control.PRESET_FULL_RECT)
        cc4.mouse_filter = Control.MOUSE_FILTER_IGNORE
        cc4.process_mode = Node.PROCESS_MODE_ALWAYS
        root.add_child(cc4)
        var b4 := _mk_button("CASE4")
        cc4.add_child(b4)
        var shield4 := Control.new()
        shield4.set_anchors_preset(Control.PRESET_FULL_RECT)
        shield4.mouse_filter = Control.MOUSE_FILTER_STOP
        shield4.process_mode = Node.PROCESS_MODE_ALWAYS
        # THE FIX: ready is connected BEFORE the node joins the tree
        shield4.ready.connect(func():
                var tw := shield4.create_tween()
                tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
                tw.tween_interval(0.05)
                tw.tween_callback(func():
                        if shield4 != null and is_instance_valid(shield4):
                                shield4.queue_free()))
        root.add_child(shield4)
        root.move_child(shield4, root.get_child_count() - 1)
        await _wait(0.30)
        var alive4 := is_instance_valid(shield4)
        var hit4: Array = []
        b4.pressed.connect(func(): hit4.append(1))
        await _click_at(b4.get_global_rect().get_center())
        await _settle(2)
        _verdict("A4 FIXED shield dies after 0.05s (running tree)", not alive4)
        _verdict("A5 click reaches button after shield death",
                        hit4.size() == 1)

        # ============ CASE 5: the FIXED shield under a PAUSED tree
        var cc5 := CenterContainer.new()
        cc5.set_anchors_preset(Control.PRESET_FULL_RECT)
        cc5.mouse_filter = Control.MOUSE_FILTER_IGNORE
        cc5.process_mode = Node.PROCESS_MODE_ALWAYS
        root.add_child(cc5)
        var b5 := _mk_button("CASE5")
        cc5.add_child(b5)
        var shield5 := Control.new()
        shield5.set_anchors_preset(Control.PRESET_FULL_RECT)
        shield5.mouse_filter = Control.MOUSE_FILTER_STOP
        shield5.process_mode = Node.PROCESS_MODE_ALWAYS
        shield5.ready.connect(func():
                var tw := shield5.create_tween()
                tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
                tw.tween_interval(0.05)
                tw.tween_callback(func():
                        if shield5 != null and is_instance_valid(shield5):
                                shield5.queue_free()))
        root.add_child(shield5)
        root.move_child(shield5, root.get_child_count() - 1)
        get_tree().paused = true
        await _wait(0.30)
        var alive5 := is_instance_valid(shield5)
        var hit5: Array = []
        b5.pressed.connect(func(): hit5.append(1))
        await _click_at(b5.get_global_rect().get_center())
        await _settle(2)
        get_tree().paused = false
        _verdict("A6 FIXED shield dies after 0.05s (PAUSED tree)", not alive5)
        _verdict("A7 click reaches button after paused-shield death",
                        hit5.size() == 1)

        print("=== PAUSE INPUT PROBE DONE: %d fails ===" % fails)
        get_tree().quit(1 if fails > 0 else 0)

func _mk_button(txt: String) -> Button:
        var b := Button.new()
        b.text = txt
        b.custom_minimum_size = Vector2(220, 70)
        return b

func _click_at(at: Vector2) -> void:
        var win := get_window()
        # design px -> window px (canvas_items stretch, KEEP/EXPAND aware)
        var vp := win.get_visible_rect().size
        var wpx := DisplayServer.window_get_size()
        var s := minf(float(wpx.x) / vp.x, float(wpx.y) / vp.y)
        var off := (Vector2(wpx) - vp * s) * 0.5
        var wp := off + at * s
        var mk := func(pressed: bool):
                var ev := InputEventMouseButton.new()
                ev.button_index = MOUSE_BUTTON_LEFT
                ev.pressed = pressed
                ev.position = wp
                ev.global_position = wp
                Input.parse_input_event(ev)
        mk.call(true)
        await _wait(0.05)
        mk.call(false)
        await _wait(0.05)

func _settle(frames: int) -> void:
        for i in frames:
                await get_tree().process_frame

func _wait(sec: float) -> void:
        await get_tree().create_timer(sec, true).timeout

func _verdict(name: String, ok: bool) -> void:
        if ok:
                print("PASS  %s" % name)
        else:
                fails += 1
                print("FAIL  %s" % name)
