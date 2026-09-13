extends Node
## film_jumpcube - THE EVIDENCE RIG (the v0.3.8-5 law: boot the real
## thing and LOOK at it). Runs CONQUER DICE on the Xvfb window at
## 1080x1920 (the portrait design), drives REAL finger events through
## the engine queue, and photographs every beat:
##   01 the silent gate        07 the B&W theme (white vs black)
##   02 the fresh board        08 the PIXEL theme
##   03 the gray-out press     09 the NEON theme
##   04 the spill mid-air      10 the CANDY theme
##   05 the dots landed        11 the 8x8 TOO BIG board
##   06 the coin round         12 the verdict + confetti

var g: GogaGame = null
var shots := 0

func _snap(tag: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        var path := "/tmp/jc_film_%s.png" % tag
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

func _hold(at: Vector2) -> void:
        var ev := InputEventScreenTouch.new()
        ev.position = at
        ev.pressed = true
        ev.index = 0
        Input.parse_input_event(ev)
        await get_tree().process_frame

func _lift(at: Vector2) -> void:
        var ev := InputEventScreenTouch.new()
        ev.position = at
        ev.pressed = false
        ev.index = 0
        Input.parse_input_event(ev)
        await get_tree().process_frame

func _ready() -> void:
        Box.reset_all()
        Box.earn(50000)
        # THE BARE-RIG LAW (agents law 11): a bare boot skips the menu
        # governor - seat the PORTRAIT design canvas directly (what
        # ScaleRule.apply would compute for a real portrait window)
        var JC: GDScript = load("res://game/games/jumpcube/jumpcube.gd")
        g = JC.new()
        g.game_id = "jumpcube"
        g.start_orientation = "portrait"
        get_window().content_scale_size = Vector2i(1080, 1920)
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        await get_tree().create_timer(0.6).timeout
        await _snap("01_gate")
        # the gate tap -> the fresh board
        await _tap(Vector2(540, 960))
        await get_tree().create_timer(0.5).timeout
        await _snap("02_board")
        # the gray-out press, held
        var c5: Vector2 = g.cell_center(5)
        await _hold(c5)
        await get_tree().create_timer(0.25).timeout
        await _snap("03_press")
        await _lift(c5)
        # grow the corner to its cap, then push it over - catch a fly
        for t in 3:
                await _tap(g.cell_center(0))
                for w in 14:
                        g.probe_step(0.05)
        await get_tree().create_timer(0.17).timeout
        await _snap("04_spill")
        await get_tree().create_timer(0.5).timeout
        await _snap("05_landed")
        # the coin round (the every-3 law, steered deterministically)
        g.done_rounds = 3
        g.coin_cell = 5
        g._new_round()
        for w in 10:
                g.probe_step(0.05)
        await get_tree().create_timer(0.6).timeout
        await _snap("06_coin")
        # the theme tour (the owner's ART ask - each theme re-inks the
        # room, the board wall, the neutral dice and the enemy). THE
        # OWNERSHIP LAW: equip refuses unowned items - the shop sells first
        var tno := 7
        for tid in ["mono", "pixel", "neon", "candy"]:
                Box.buy_item("jumpcube", "theme", tid,
                                int(JC.THEMES[tid]["price"]))
                Box.equip_item("jumpcube", "theme", tid)
                g._load_meta()
                await get_tree().create_timer(0.35).timeout
                await _snap("%02d_%s" % [tno, tid])
                tno += 1
        # back to wood (wood is the UNEQUIPPED default - equip refuses
        # unowned items, so the return path is the unequip), the 8x8
        Box.unequip_item("jumpcube", "theme")
        g._load_meta()
        Box.buy_item("jumpcube", "size", "8", 3600)
        Box.equip_item("jumpcube", "size", "8")
        g._apply_size("8")
        await get_tree().create_timer(0.4).timeout
        await _snap("11_big8")
        # the verdict: the door seats a fresh round, THEN the data hand
        # gives the player the board minus one die - the last tap wins
        g._apply_size("4")
        for w in 6:
                g.probe_step(0.05)
        g.next_opener = 1
        g._new_round()
        var ow := []
        var va := []
        for i in 16:
                ow.append(1)
                va.append(1)
        ow[15] = 0
        g.owners = ow
        g.values = va
        for w in 6:
                g.probe_step(0.05)
        await _tap(g.cell_center(15))
        await get_tree().create_timer(0.7).timeout
        await _snap("12_verdict")
        print("FILM DONE: %d shots" % shots)
        get_tree().quit(0)
