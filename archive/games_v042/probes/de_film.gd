extends Node
## de_film - the visual verification rig (the Xvfb film law): boots the
## REAL game with the lore skipped, photographs the SILENT GATE (the
## owner's round-2 strip-down), then taps and drives REAL swipes and
## photographs the HUD row (the seat law: dots|lives|rush|SCORE|speed|
## coins) and the run at beats. The stills land in /tmp/de_film.

var g: GogaGame = null
var PM: GDScript
var T := 0.0
var beat := 0
var out_dir := "/tmp/de_film"

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        DirAccess.make_dir_recursive_absolute(out_dir)
        Box.reset_all()
        Box.bump_counter("pacman", "lore_start", 1)
        Box.bump_counter("pacman", "lore_end", 1)
        PM = load("res://game/games/pacman/pacman.gd")
        g = PM.new()
        g.game_id = "pacman"
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        await get_tree().create_timer(0.4).timeout
        _snap("gate")            # the SILENT GATE (one sentence only)

func _snap(name: String) -> void:
        var img := get_viewport().get_texture().get_image()
        img.save_png("%s/%s.png" % [out_dir, name])
        print("de_film: snapped %s" % name)

func _process(delta: float) -> void:
        if g == null:
                return
        T += delta
        match beat:
                0:
                        if T >= 0.6:
                                beat = 1
                                # the tap starts the run (a REAL tap)
                                _touch(Vector2(400, 500), true)
                1:
                        if T >= 0.7:
                                beat = 2
                                _touch(Vector2(400, 500), false)
                2:
                        if T >= 2.2:
                                beat = 3
                                _snap("hud_ready")
                                _swipe(Vector2i(-1, 0))
                3:
                        if T >= 3.4:
                                beat = 4
                                _snap("run_left")
                                _swipe(Vector2i(0, -1))
                4:
                        if T >= 4.6:
                                beat = 5
                                _snap("run_up")
                                _swipe(Vector2i(1, 0))
                5:
                        if T >= 5.8:
                                beat = 6
                                _snap("run_right")
                6:
                        if T >= 7.4:
                                beat = 7
                                _snap("run_late")
                                print("de_film: done dots=%d lives=%d cell=%s"
                                                % [g.dots_run, g.lives,
                                                g.player["cell"]])
                                get_tree().quit(0)

func _touch(at: Vector2, pressed: bool) -> void:
        var ev := InputEventScreenTouch.new()
        ev.position = at
        ev.pressed = pressed
        ev.index = 0
        Input.parse_input_event(ev)

func _swipe(dir: Vector2i) -> void:
        var c: Vector2 = g._cell_px(g.player["cell"])
        _touch(c, true)
        for i in 3:
                var d := InputEventScreenDrag.new()
                d.position = c + Vector2(dir) * (60.0 * (i + 1))
                d.relative = Vector2(dir) * 60.0
                d.index = 0
                Input.parse_input_event(d)
        _touch(c + Vector2(dir) * 240.0, false)
