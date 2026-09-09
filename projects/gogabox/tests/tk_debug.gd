extends Node
# instrumented maze: does _unhandled_input see the drags? does tk see them?
var G: GogaGame
var press_n := [0]
var drag_n := [0]
var tk_swiped := [false]
var tk_down_after_press := [false]

func _ready() -> void:
        var w := get_window()
        w.size = Vector2i(1920, 1080)
        ScaleRule.apply(w)
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        Box.earn(500)
        G = load("res://game/games/maze/maze.gd").new()
        G.game_id = "maze"
        add_child(G)
        G.tk.swiped.connect(func(d, p): tk_swiped[0] = true)
        await get_tree().create_timer(0.8).timeout
        var tw := get_viewport().get_final_transform()
        # start tap
        var ev := InputEventScreenTouch.new()
        ev.index = 0
        ev.position = tw * Vector2(960, 540)
        ev.pressed = true
        Input.parse_input_event(ev)
        await get_tree().process_frame
        await get_tree().process_frame
        var ev0 := InputEventScreenTouch.new()
        ev0.index = 0
        ev0.position = tw * Vector2(960, 540)
        ev0.pressed = false
        Input.parse_input_event(ev0)
        await get_tree().process_frame
        await get_tree().process_frame
        print("phase_after_start=", G.phase)
        # swipe
        var ev2 := InputEventScreenTouch.new()
        ev2.index = 1
        ev2.position = tw * Vector2(1020, 660)
        ev2.pressed = true
        Input.parse_input_event(ev2)
        await get_tree().process_frame
        tk_down_after_press[0] = G.tk.is_down()
        for i in 8:
                var dv := InputEventScreenDrag.new()
                dv.index = 1
                dv.position = tw * (Vector2(1020, 660) + Vector2(7.5 * (i + 1), 0))
                Input.parse_input_event(dv)
                await get_tree().process_frame
        var ev3 := InputEventScreenTouch.new()
        ev3.index = 1
        ev3.position = tw * Vector2(1080, 660)
        ev3.pressed = false
        Input.parse_input_event(ev3)
        await get_tree().process_frame
        print("presses=", press_n[0], " drags_seen_by_unhandled=", drag_n[0],
                        " tk_down_after_press=", tk_down_after_press[0],
                        " tk_swiped=", tk_swiped[0],
                        " queue=", G.queue.size(), " moving=", G.moving)
        get_tree().quit(0)

func _unhandled_input(event: InputEvent) -> void:
        if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
                press_n[0] += 1
        if event is InputEventScreenDrag:
                drag_n[0] += 1
        # NOTE: this node does NOT call tk.feed - the maze's base does.
