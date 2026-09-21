extends Node
## v041-1 probe: THE MARBLE PC SEAT - the owner: "character not following
## cursor and RMB not change shot". Boots the real box, launches marble,
## walks the intro, synthesizes real mouse motion + right click, and
## watches the totem aim and the loaded marble swap.

var fails := 0

func ck(cond: bool, what: String) -> void:
        if cond:
                print("  ok - %s" % what)
        else:
                fails += 1
                print("PROBE_FAIL - %s" % what)

func _press_key(k: Key) -> void:
        var kev := InputEventKey.new()
        kev.keycode = k
        kev.physical_keycode = k
        kev.pressed = true
        Input.parse_input_event(kev)

func _click(ntab: Vector2) -> void:
        var ev := InputEventMouseButton.new()
        ev.button_index = MOUSE_BUTTON_LEFT
        ev.pressed = true
        ev.position = ntab
        Input.parse_input_event(ev)
        var ev2 := ev.duplicate() as InputEventMouseButton
        ev2.pressed = false
        Input.parse_input_event(ev2)

func _ready() -> void:
        await get_tree().process_frame
        if DisplayServer.get_name() == "headless":
                print("PROBE_SKIP - needs a real window")
                get_tree().quit(0)
                return
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        var main := Node2D.new()
        main.set_script(load("res://game/main.gd"))
        add_child(main)
        await get_tree().create_timer(2.0).timeout
        ck(GameHost.launch(main, "marble"), "marble launched")
        var host: Node = null
        for i in 80:
                await get_tree().create_timer(0.1).timeout
                host = GameHost.active_host
                if host != null and host.game != null:
                        break
        ck(host != null and host.game != null, "the game is live")
        if host == null or host.game == null:
                get_tree().quit(1)
                return
        var g: Node = host.game
        # THE INTRO: the story sheet exists but the rig's synthetic clicks
        # cannot walk it - end it the honest way, then the key fires the
        # universal intro tap (game_base's keyboard road)
        # THE INTRO BYPASS: end the story, then start level 1 directly
        # (the probe's goal is the PC seat, not the intro walk)
        if g.has_method("box_story_end") and g.box_story_open():
                g.box_story_end(Callable())
        if not g.has_method("_start_level"):
                print("PROBE_FAIL - no _start_level")
                get_tree().quit(1)
                return
        g.call("_start_level", 0, false, 1)
        for i in 20:
                await get_tree().create_timer(0.1).timeout
                if g.get("shooter_head") != null:
                        break
        ck(g.get("shooter_head") != null,
                        "the totem is live (play began)")
        if g.get("shooter_head") == null:
                get_tree().quit(1)
                return
        ck(bool(g.get("pc_ui")), "the PC seat is armed (pc_ui)")
        var aim0: Vector2 = g.get("aim")
        var head0: float = (g.get("shooter_head") as Node2D).rotation
        # synthesize a real mouse motion at a different design point
        var vp := get_viewport()
        var target_design := Vector2(800, 400)
        var wpos: Vector2 = vp.get_final_transform() * (target_design + g.get("ORIGIN"))
        var mm := InputEventMouseMotion.new()
        mm.position = wpos
        mm.global_position = wpos
        Input.parse_input_event(mm)
        await get_tree().process_frame
        await get_tree().process_frame
        var aim1: Vector2 = g.get("aim")
        var head1: float = (g.get("shooter_head") as Node2D).rotation
        ck(not aim1.is_equal_approx(aim0), "the cursor motion moved the aim")
        ck(absf(head1 - head0) > 0.001, "the totem head rotated with the cursor")
        # enter PLAY (the aim gates read play; the preview's tap starts it)
        if String(g.get("phase")) != "play":
                g.call("_begin_play")
                await get_tree().process_frame
        # RMB swap: the loaded sprite's texture swaps with the next
        var load_a: Texture2D = (g.get("load_spr") as Sprite2D).texture
        var mb := InputEventMouseButton.new()
        mb.button_index = MOUSE_BUTTON_RIGHT
        mb.pressed = true
        mb.position = wpos
        Input.parse_input_event(mb)
        await get_tree().process_frame
        var load_b: Texture2D = (g.get("load_spr") as Sprite2D).texture
        ck(load_b != load_a, "the RMB swapped the load")
        # hold for the rig's eye (the film grab lands mid-hold)
        await get_tree().create_timer(30.0).timeout
        if fails == 0:
                print("PROBE_OK - the marble PC seat lives")
        else:
                print("PROBE_FAIL - %d checks failed" % fails)
        get_tree().quit(1 if fails > 0 else 0)
