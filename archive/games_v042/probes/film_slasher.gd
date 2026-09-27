extends Node
## film_slasher - THE EVIDENCE RIG for the v0.3.9-11 slasher round:
## the desserts shelf, the real veg halves, the frenzy rain + banner,
## all photographed on the Xvfb rig at the real design size.

var g: GogaGame = null
var SL: GDScript
var shots := 0

func _snap(tag: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        var path := "/tmp/slasher_film_%s.png" % tag
        img.save_png(path)
        shots += 1
        print("FILM: %s" % path)

func _swipe(a: Vector2, b: Vector2) -> void:
        # the REAL finger: touch + drags through the engine queue
        var t := InputEventScreenTouch.new()
        t.position = a
        t.pressed = true
        t.index = 0
        Input.parse_input_event(t)
        await get_tree().process_frame
        var steps := 10
        for i in range(1, steps + 1):
                var d := InputEventScreenDrag.new()
                d.position = a.lerp(b, float(i) / float(steps))
                d.relative = (b - a) / float(steps)
                d.index = 0
                Input.parse_input_event(d)
                await get_tree().process_frame
        var t2 := InputEventScreenTouch.new()
        t2.position = b
        t2.pressed = false
        t2.index = 0
        Input.parse_input_event(t2)
        await get_tree().process_frame

func _ready() -> void:
        Box.reset_all()
        Box.earn(50000)
        Box.dev_set_cheat("all_owned", 1)
        SL = load("res://game/games/slasher/slasher.gd")
        g = SL.new()
        g.game_id = "slasher"
        g.start_orientation = "vertical"
        get_window().content_scale_size = Vector2i(1080, 1920)
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        await get_tree().create_timer(0.5).timeout
        await _snap("01_options")
        # the DESSERTS pick (the third card the owner asked for)
        var picked := false
        var stack := [g._overlay_root_ref()]
        while not stack.is_empty():
                var n: Node = stack.pop_front()
                if n is Button and String((n as Button).text) == "DESSERTS":
                        print("FILMDEBUG: desserts card at %s"
                                        % (n as Button).get_global_rect())
                        var ev := InputEventMouseButton.new()
                        ev.position = (n as Button).get_global_rect() \
                                        .get_center()
                        ev.button_index = MOUSE_BUTTON_LEFT
                        ev.pressed = true
                        Input.parse_input_event(ev)
                        await get_tree().process_frame
                        var ev2 := ev.duplicate()
                        ev2.pressed = false
                        Input.parse_input_event(ev2)
                        picked = true
                        break
                for c in n.get_children():
                        stack.append(c)
        print("FILMDEBUG: desserts picked=%s mode=%s" % [picked,
                        g.mode_id])
        await get_tree().create_timer(0.3).timeout
        await _snap("02_options_desserts")
        # START
        var start_btn := _find_button(g._overlay_root_ref(), "START")
        if start_btn != null:
                var ev3 := InputEventMouseButton.new()
                ev3.position = start_btn.get_global_rect().get_center()
                ev3.button_index = MOUSE_BUTTON_LEFT
                ev3.pressed = true
                Input.parse_input_event(ev3)
                await get_tree().process_frame
                var ev4 := ev3.duplicate()
                ev4.pressed = false
                Input.parse_input_event(ev4)
        await get_tree().create_timer(0.4).timeout
        # THE FRENZY: force the rain now
        g.frenzy_clock = 0.05
        g.frenzy_t = -1.0
        var k := 0
        while g.frenzy_t < 0.0 and k < 60:
                await get_tree().create_timer(0.05).timeout
                k += 1
        print("FILMDEBUG: frenzy_t=", g.frenzy_t)
        await get_tree().create_timer(0.35).timeout
        await _snap("03_rain_banner")
        await get_tree().create_timer(0.9).timeout
        await _snap("04_rain_waves")
        # cut a flying dessert mid-air (a real swipe through it)
        var target: Sprite2D = null
        var k2 := 0
        while target == null and k2 < 240:
                await get_tree().create_timer(0.05).timeout
                k2 += 1
                for it in g.items:
                        if String(it["kind"]) != "bomb" \
                                        and String(it["kind"]) != "coin" \
                                        and not bool(it["sliced"]):
                                var n: Sprite2D = it["node"]
                                if n.position.y > 300.0 \
                                                and n.position.y < 1200.0:
                                        target = n
                                        break
        if target != null:
            print("FILMDEBUG: cutting a %s at %s"
                            % [target.texture.resource_path.get_file(),
                            target.position])
            var at: Vector2 = target.position
            await _swipe(at + Vector2(-160, 140), at + Vector2(160, -140))
            await get_tree().create_timer(0.16).timeout
            await _snap("05_dessert_cut")
        # the veg shelf: re-skin + cut one
        Box.equip_item("slasher", "produce", "veggies")
        g.mode_id = "veggies"
        var veg: Sprite2D = null
        var k3 := 0
        while veg == null and k3 < 240:
                g._launch(g._item_kind())
                await get_tree().create_timer(0.05).timeout
                k3 += 1
                for it in g.items:
                        if SL.VEGGIES.has(String(it["kind"])) \
                                        and not bool(it["sliced"]):
                                var n2: Sprite2D = it["node"]
                                if n2.position.y > 400.0 \
                                                and n2.position.y < 1300.0:
                                        veg = n2
                                        break
        if veg != null:
            print("FILMDEBUG: cutting a veg at %s" % veg.position)
            var at2: Vector2 = veg.position
            await _swipe(at2 + Vector2(-160, 140), at2 + Vector2(160, -140))
            await get_tree().create_timer(0.14).timeout
            await _snap("06_veg_cut")
        print("FILM: done shots=%d" % shots)
        get_tree().quit(0)

func _find_button(root: Node, txt: String) -> Button:
        var stack := [root]
        while not stack.is_empty():
                var n: Node = stack.pop_front()
                if n is Button and String((n as Button).text) == txt:
                        return n
                for c in n.get_children():
                        stack.append(c)
        return null
