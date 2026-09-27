extends Node
## maze_touch_probe - the REAL input path test (v0.3.7-1).
## The maze_probe drives _swipe_dir directly; this one feeds synthesized
## ScreenTouch/ScreenDrag events through Input.parse_input_event - the same
## road a finger takes: GUI -> unhandled -> tk.feed -> swiped -> queue.

var checks := 0
var fails := 0
var G: GogaGame

func ck(cond: bool, what: String) -> void:
        checks += 1
        if cond:
                print("[PASS] ", what)
        else:
                fails += 1
                print("[FAIL] ", what)

func _to_window(viewport_pos: Vector2) -> Vector2:
        return get_viewport().get_final_transform() * viewport_pos

func _touch(idx: int, pos: Vector2, pressed: bool) -> void:
        var ev := InputEventScreenTouch.new()
        ev.index = idx
        ev.position = _to_window(pos)
        ev.pressed = pressed
        Input.parse_input_event(ev)

func _drag(idx: int, pos: Vector2, rel: Vector2) -> void:
        var ev := InputEventScreenDrag.new()
        ev.index = idx
        ev.position = _to_window(pos)
        ev.relative = _to_window(rel) - _to_window(Vector2.ZERO)
        Input.parse_input_event(ev)

func _run() -> void:
        print("=== maze_touch_probe ===")
        get_window().size = Vector2i(1920, 1080)
        ScaleRule.apply(get_window())
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        Box.earn(500)
        G = load("res://game/games/maze/maze.gd").new()
        G.game_id = "maze"
        add_child(G)
        await get_tree().create_timer(1.0).timeout

        # ------------------------------------------------ the START tap
        ck(G.phase == "ready", "the game boots into the ready gate")
        var center := get_viewport().get_visible_rect().size * 0.5
        _touch(0, center, true)
        await get_tree().process_frame
        await get_tree().process_frame
        _touch(0, center, false)
        await get_tree().process_frame
        await get_tree().process_frame
        ck(G.phase == "run", "THE START TAP: a real touch event starts the run")
        if G.phase != "run":
                _done()
                return

        # ------------------------------------------------ the swipe walk
        # a clean swipe in the open: press -> cross the 42px threshold ->
        # release. The square must queue a step and START moving.
        var from_cell := Vector2i(G.player["c"], G.player["r"])
        # find an OPEN direction from the start cell (honest walk)
        var open := Vector2i.ZERO
        for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
                var key := "r" if d.x != 0 else "t" if d.y < 0 else "b" if d.y > 0 else "l"
                if d.x > 0:
                        key = "r"
                if not G.cells[from_cell.y][from_cell.x][key]:
                        open = d
                        break
        ck(open != Vector2i.ZERO, "the start cell has an open corridor")
        var p0 := center + Vector2(60, 120)
        _touch(1, p0, true)
        await get_tree().process_frame
        var steps := 8
        for i in steps:
                _drag(1, p0 + Vector2(open) * (60.0 * float(i + 1) / steps),
                        Vector2(open) * (60.0 / steps))
                await get_tree().process_frame
        _touch(1, p0 + Vector2(open) * 60.0, false)
        await get_tree().process_frame
        await get_tree().process_frame
        ck(G.queue.size() > 0 or G.moving,
                "THE SWIPE: a real drag reaches the queue (queue=%d moving=%s)"
                        % [G.queue.size(), str(G.moving)])
        var moved0 := Vector2(G.player["x"], G.player["y"])
        await get_tree().create_timer(0.5).timeout
        var moved1 := Vector2(G.player["x"], G.player["y"])
        ck(moved0.distance_to(moved1) > 1.0,
                "THE MOVE: the square actually travels (dx=%.1f)" % moved0.distance_to(moved1))
        var landed := Vector2i(G.player["c"], G.player["r"])
        ck(landed != from_cell,
                "THE ARRIVAL: the cell lands (start %s -> %s)" % [from_cell, landed])

        # ------------------------------------------- the shop button law
        var found_shop := false
        var stack := [G._hud_row]
        while not stack.is_empty():
                var n: Node = stack.pop_back()
                if n is Button and String((n as Button).text) == "SHOP":
                        found_shop = true
                for c in n.get_children():
                        stack.append(c)
        ck(found_shop, "THE SHOP: the SHOP button exists in the HUD row")

        _done()

func _done() -> void:
        print("RESULT: %d/%d passed" % [checks - fails, checks])
        get_tree().quit(1 if fails > 0 else 0)

func _ready() -> void:
        _run.call_deferred()
