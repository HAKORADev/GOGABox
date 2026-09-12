extends Node
## rec_pacman - the AUTOMATED GAMEPLAY RIG (the rec_squares law): boots the
## REAL DOT EATER, plays REAL swipes through the game's own doors at a
## human-visible cadence - the junction buffer, a rush, a wrap ride -
## then quits. The Xvfb rig films it; PIL measures the stills.

var g: GogaGame = null
var beat := 0.0
var step_i := 0

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.reset_all()
        Box.bump_counter("pacman", "lore_start", 1)
        Box.bump_counter("pacman", "lore_end", 1)
        var PM: GDScript = load("res://game/games/pacman/pacman.gd")
        g = PM.new()
        g.game_id = "pacman"
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        g.probe_reset(4242)
        # the rush ON for the film: seat the player on a power dot
        for key in g.dots.keys():
                if String(g.dots[key]) == "p":
                        g.player["cell"] = key
                        g.player["from"] = key
                        g.player["to"] = key
                        g.player["moving"] = false
                        g._eat_at(key)
                        break
        g.probe_step(1.5)

func _process(delta: float) -> void:
        if g == null:
                return
        beat += delta
        if beat >= 0.9:
                beat = 0.0
                step_i += 1
                _drive(step_i)

func _drive(i: int) -> void:
        # the real-finger law: REAL swipe events through the engine queue
        if i % 3 == 1:
                var ev := InputEventScreenDrag.new()
                ev.position = Vector2(400, 500)
                ev.relative = Vector2(200, 0)
                Input.parse_input_event(ev)
        elif i % 3 == 2:
                var ev2 := InputEventScreenTouch.new()
                ev2.position = Vector2(400, 500)
                ev2.pressed = true
                Input.parse_input_event(ev2)
        if i >= 8:
                print("rec_pacman: done, eating dots=%d lives=%d" % [
                                g.dots_run, g.lives])
                get_tree().quit(0)
