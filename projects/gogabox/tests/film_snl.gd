extends Node
## film_snl - THE EVIDENCE RIG (the law: boot the real thing and LOOK at
## it). Runs SNAKES & LADDERS on the Xvfb window at 1080x1920 (the
## portrait design), drives REAL taps through the engine queue, and
## photographs every beat:
##   01 the gate            07 the ladder ride (crafted base)
##   02 the mode sheet      08 the ladder's top seat
##   03 the fresh table     09 the snake fall (crafted head)
##   04 the waiting die     10 the snake's tail seat
##   05 the die shuffle     11 the coin on its cell
##   06 the hop walk        12 the verdict + confetti
## The PIL census reads the stills AFTER the run (the checker count, the
## rails, the serpent line) - evidence, not eyeballs.

var g: GogaGame = null
var SN: GDScript
var shots := 0

func _snap(tag: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        var path := "/tmp/snl_film_%s.png" % tag
        img.save_png(path)
        shots += 1
        print("FILM: %s" % path)

func _tap(at: Vector2) -> void:
        var ev := InputEventMouseButton.new()
        ev.position = at
        ev.button_index = MOUSE_BUTTON_LEFT
        ev.pressed = true
        Input.parse_input_event(ev)
        await get_tree().process_frame
        var ev2 := InputEventMouseButton.new()
        ev2.position = at
        ev2.button_index = MOUSE_BUTTON_LEFT
        ev2.pressed = false
        Input.parse_input_event(ev2)
        await get_tree().process_frame

func _find_sheet_button(tag: String) -> Rect2:
        if g.sheet_open_count() == 0:
                return Rect2()
        var cc: Control = g._sheet_stack[0]["cc"]
        var stack := [cc]
        while not stack.is_empty():
                var n: Node = stack.pop_front()
                if n is Button and String((n as Button).text) == tag:
                        return (n as Button).get_global_rect()
                for c in n.get_children():
                        stack.append(c)
        return Rect2()

func _wait_user_roll(max_beats := 400) -> void:
        var k := 0
        while not (g.state == "roll_wait" and g.turn == 1) and k < max_beats:
                g.probe_step(0.05)
                k += 1

func _ready() -> void:
        print("== film_snl ==")
        Box.reset_all()
        Box.earn(50000)
        # THE BARE-RIG LAW: a bare boot skips the menu governor - seat
        # the PORTRAIT design canvas directly
        SN = load("res://game/games/snl/snl.gd")
        g = SN.new()
        g.game_id = "snl"
        g.start_orientation = "portrait"
        get_window().content_scale_size = Vector2i(1080, 1920)
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        print("FILMDEBUG: win=", get_window().size, " content=",
                        get_window().content_scale_size, " visrect=",
                        get_viewport().get_visible_rect().size)
        await get_tree().create_timer(0.6).timeout
        await _snap("01_gate")
        # the gate tap -> the mode sheet
        await _tap(Vector2(540, 960))
        await get_tree().create_timer(0.5).timeout
        await _snap("02_modes")
        # pick "2" - the card's true seat comes from the tree
        var two := _find_sheet_button("2")
        print("FILMDEBUG: card 2 at %s" % str(two))
        if two.size.x > 0:
                await _tap(two.get_center())
        await get_tree().create_timer(0.4).timeout
        await get_tree().create_timer(0.3).timeout
        await _snap("03_table")
        # THE WAITING DIE at the user's tray
        _wait_user_roll()
        var wait_die: Rect2 = g._die_rect(1)
        await _snap("04_wait_die")
        # tap the die - catch the shuffle mid-air
        await _tap(wait_die.get_center())
        await get_tree().create_timer(0.3).timeout
        await _snap("05_shuffle")
        # the settle + the walk (a hop mid-air)
        var k := 0
        while g.state == "rolling" and k < 100:
                g.probe_step(0.05)
                k += 1
        await get_tree().create_timer(0.1).timeout
        await _snap("06_walk")
        while g.state in ["walking", "rolling"]:
                g.probe_step(0.03)
        # THE LADDER RIDE: craft the base at 13
        _wait_user_roll()
        g.poss[0] = 12
        g.poss[1] = 60
        if g.turn != 1:
                g.turn = 1
                g._start_turn()
        g.roll = 1
        g._after_roll()
        k = 0
        while g.state == "walking" and k < 200:
                g.probe_step(0.05)
                k += 1
        await get_tree().create_timer(float(g.RIDE_BEAT) * 0.5).timeout
        await _snap("07_ladder_ride")
        k = 0
        while g.state == "riding" and k < 400:
                g.probe_step(0.05)
                k += 1
        await get_tree().create_timer(0.2).timeout
        await _snap("08_ladder_top")
        # THE SNAKE FALL: craft the head at 99
        _wait_user_roll()
        g.poss[0] = 98
        g.poss[1] = 60
        if g.turn != 1:
                g.turn = 1
                g._start_turn()
        g.roll = 1
        g._after_roll()
        k = 0
        while g.state == "walking" and k < 200:
                g.probe_step(0.05)
                k += 1
        await get_tree().create_timer(float(g.RIDE_BEAT) + 0.28).timeout
        await _snap("09_snake_fall")
        k = 0
        while g.state == "riding" and k < 600:
                g.probe_step(0.05)
                k += 1
        await get_tree().create_timer(0.2).timeout
        await _snap("10_snake_tail")
        # THE COIN: craft the clock, spawn, photograph its cell
        g.play_clock = SN.COIN_EVERY
        g._coin_maybe_spawn()
        await get_tree().create_timer(0.5).timeout
        await _snap("11_coin")
        # THE VERDICT: craft the user's crown
        _wait_user_roll()
        g.poss[0] = 97
        g.poss[1] = 60
        if g.turn != 1:
                g.turn = 1
                g._start_turn()
        g.roll = 3
        g._after_roll()
        k = 0
        while g.state in ["walking", "riding"] and k < 400:
                g.probe_step(0.05)
                k += 1
        await get_tree().create_timer(0.5).timeout
        await _snap("12_verdict")
        print("FILM: %d shots on the Xvfb rig" % shots)
        get_tree().quit(0)
