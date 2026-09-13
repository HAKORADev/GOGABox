extends Node
## film_brick - THE EVIDENCE RIG (the v0.3.8-5 law: boot the real thing
## and LOOK at it). Runs the game on the Xvfb window at 1920x1080 (the
## landscape design, us = 1), drives REAL finger events through the
## engine queue, and photographs every beat:
##   01 the silent gate          05 the play (ball loose, brick hits)
##   02 the intro (line by line)  06 the paddle glide (finger drag)
##   03 the serve (ball on pad)   07 a powerup armed (the chips)
##   04 the launch                08 a break (the dying fade + burst)

var g: GogaGame = null
var shots := 0

func _snap(tag: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        var path := "/tmp/brick_film_%s.png" % tag
        img.save_png(path)
        shots += 1
        print("FILM: %s" % path)

func _tap(at: Vector2) -> void:
        var ev := InputEventScreenTouch.new()
        ev.position = at
        ev.pressed = true
        ev.index = 0
        Input.parse_input_event(ev)
        await get_tree().process_frame
        var ev2 := InputEventScreenTouch.new()
        ev2.position = at
        ev2.pressed = false
        ev2.index = 0
        Input.parse_input_event(ev2)
        await get_tree().process_frame

func _drag(from: Vector2, to: Vector2) -> void:
        var p := InputEventScreenTouch.new()
        p.position = from
        p.pressed = true
        p.index = 3
        Input.parse_input_event(p)
        await get_tree().process_frame
        for i in 6:
                var d := InputEventScreenDrag.new()
                d.position = from.lerp(to, float(i + 1) / 6.0)
                d.index = 3
                Input.parse_input_event(d)
                await get_tree().process_frame
        var r := InputEventScreenTouch.new()
        r.position = to
        r.pressed = false
        r.index = 3
        Input.parse_input_event(r)
        await get_tree().process_frame

func _ready() -> void:
        Box.reset_all()
        Box.bump_counter("brickbreaker", "lore_start", 1)
        var BB: GDScript = load("res://game/games/brickbreaker/brickbreaker.gd")
        g = BB.new()
        g.game_id = "brickbreaker"
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        await get_tree().create_timer(0.6).timeout
        await _snap("01_gate")
        # the gate tap -> the intro
        await _tap(Vector2(960, 540))
        await get_tree().create_timer(0.12).timeout
        await _snap("02_intro_rows")
        await get_tree().create_timer(1.6).timeout
        await _snap("03_serve")
        # the launch
        await _tap(Vector2(960, 540))
        await get_tree().create_timer(1.1).timeout
        await _snap("04_play")
        # the paddle glide (a real drag right)
        await _drag(Vector2(600, 990), Vector2(1500, 990))
        await get_tree().create_timer(0.4).timeout
        await _snap("05_glide")
        # some play, then a metal arm (the chips + the shine)
        await get_tree().create_timer(1.6).timeout
        await _snap("06_hits")
        g._apply_pow("metal")
        g._apply_pow("spd")
        g._sync_effect_chips()
        await get_tree().create_timer(0.5).timeout
        await _snap("07_powered")
        # force a break burst under the camera
        for i in 6:
                var key := Vector2i(-1, -1)
                for k in g.ld["cells"].keys():
                        var c: Dictionary = g.ld["cells"][k]
                        if not bool(c["decor"]) and int(c["hp"]) > 0 \
                                        and not c.has("dying"):
                                key = k
                                break
                if key.x >= 0:
                        g.probe_damage(key, 9)
                await get_tree().create_timer(0.08).timeout
        await _snap("08_breaks")
        # the theme law: NEON redraws the world (evidence shot) - the
        # shop law first: OWN it (equip without ownership is refused)
        Box.earn(500)
        Box.buy_item("brickbreaker", "theme", "neon", 300)
        Box.equip_item("brickbreaker", "theme", "neon")
        g._apply_theme()
        await get_tree().create_timer(0.4).timeout
        await _snap("09_neon")
        Box.equip_item("brickbreaker", "theme", "sky")
        print("FILM DONE: %d shots" % shots)
        get_tree().quit(0)
