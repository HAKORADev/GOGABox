extends Node
## film_ludo - THE EVIDENCE RIG (the v0.3.8-5 law: boot the real thing
## and LOOK at it). Runs BOARD LUDO on the Xvfb window at 1080x1920 (the
## portrait design), drives REAL finger events through the engine queue,
## and photographs every beat:
##   01 the silent gate       07 the hop walk mid-air
##   02 the mode sheet        08 the drop on the start cell
##   03 the fresh x1 table    09 the capture slide (crafted contact)
##   04 the ROLL pill         10 the blockade pair mid-to-side
##   05 the die mid-shuffle   11 the coin on its ring cell
##   06 arrows on the pawn    12 the verdict + confetti

var g: GogaGame = null
var LD: GDScript
var shots := 0

class TapSpy extends Node:
        func _unhandled_input(ev: InputEvent) -> void:
                if ev is InputEventMouseButton or ev is InputEventScreenTouch:
                        var pp: Vector2 = (ev as InputEventMouse).position \
                                        if ev is InputEventMouse \
                                        else (ev as InputEventScreenTouch).position
                        print("SPY got ", ev.get_class(), " pos=", pp,
                                        " pressed=", ev.is_pressed())

func _snap(tag: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        var path := "/tmp/ludo_film_%s.png" % tag
        img.save_png(path)
        shots += 1
        print("FILM: %s" % path)

func _tap(at: Vector2) -> void:
        # the MOUSE event drives BOTH the sheet buttons (real Controls)
        # and the game's own input branch - one tap, one truth
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

## the sheet's button whose text starts with `tag` (real tree coords)
func _find_sheet_button(tag: String) -> Rect2:
        if g.sheet_open_count() == 0:
                return Rect2()
        var cc: Control = g._sheet_stack[0]["cc"]
        var stack := [cc]
        while not stack.is_empty():
                var n: Node = stack.pop_front()
                if n is Button and String(n.text).begins_with(tag):
                        return (n as Button).get_global_rect()
                for c in n.get_children():
                        stack.append(c)
        return Rect2()

func _wait_user_roll(max_beats := 400) -> void:
        var k := 0
        while not (g.state == "roll_wait" and g._is_user_army(g.turn_army)) \
                        and k < max_beats:
                g.probe_step(0.05)
                k += 1

func _ready() -> void:
        Box.reset_all()
        Box.earn(50000)
        # THE BARE-RIG LAW (agents law 11): a bare boot skips the menu
        # governor - seat the PORTRAIT design canvas directly
        LD = load("res://game/games/ludo/ludo.gd")
        g = LD.new()
        g.game_id = "ludo"
        g.start_orientation = "portrait"
        get_window().content_scale_size = Vector2i(1080, 1920)
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        add_child(TapSpy.new())
        print("FILMDEBUG: win=", get_window().size, " content=",
                        get_window().content_scale_size, " visrect=",
                        get_viewport().get_visible_rect().size)
        await get_tree().create_timer(0.6).timeout
        await _snap("01_gate")
        # the gate tap -> the mode sheet
        await _tap(Vector2(540, 960))
        await get_tree().create_timer(0.5).timeout
        await _snap("02_modes")
        # pick X1 - the card's true seat comes from the tree, never from
        # eyeballed pixels (the film law: drive the REAL thing)
        var x1 := _find_sheet_button("X1")
        print("FILMDEBUG: X1 card at %s" % str(x1))
        if x1.size.x > 0:
                await _tap(x1.get_center())
        await get_tree().create_timer(0.3).timeout
        await get_tree().create_timer(0.4).timeout
        await _snap("03_table")
        # THE WAITING DIE at army 1's tray (the grayed die IS the roll
        # button now - the v0.3.9-11 tray redesign)
        _wait_user_roll()
        var wait_die: Rect2 = g._die_rect(1)
        await _snap("04_wait_die")
        # tap the die - catch the shuffle mid-air
        await _tap(wait_die.get_center())
        await get_tree().create_timer(0.35).timeout
        await _snap("05_shuffle")
        # the settle: place a pawn mid-track so EVERY face moves - the
        # selection film never depends on dice luck
        g.poss[0] = 10
        g.poss[1] = -1
        g.poss[2] = -1
        g.poss[3] = -1
        var k := 0
        var roll_tries := 0
        while roll_tries < 14:
                roll_tries += 1
                while g.state == "rolling" and k < 100:
                        g.probe_step(0.05)
                        k += 1
                if g.state == "picking":
                        break
                _wait_user_roll()
                g.probe_roll()
                k = 0
        await get_tree().create_timer(0.2).timeout
        await _snap("06_arrows")
        if g.state == "picking":
                # THE SELECTION ANSWER (the owner's critical round): tap a
                # movable pawn with a REAL finger - the chosen pawn must
                # lift and the landings must light up
                var mov := int(g.legal[0]["piece"])
                var ppt: Vector2 = g._pawn_point(g.turn_army, mov)
                print("FILMDEBUG: before tap state=%s army=%d user=%s "
                                % [g.state, g.turn_army,
                                g._is_user_army(g.turn_army)]
                                + "piece=%d ppt=%s cell=%.1f legal=%d"
                                % [mov, ppt, g.cell, g.legal.size()])
                await _tap(ppt)
                await get_tree().create_timer(0.25).timeout
                await _snap("06b_chosen")
                print("FILMDEBUG: sel_piece=%d sel_moves=%d"
                                % [g.sel_piece, g.sel_moves.size()])
                if g.sel_piece >= 0 and not g.sel_moves.is_empty():
                        var dest: Vector2 = g.pos_point(g.turn_army,
                                        int(g.sel_moves[0]["np"]),
                                        int(g.sel_moves[0]["piece"]))
                        await _tap(dest)
                        await get_tree().create_timer(0.12).timeout
                        print("FILMDEBUG: after dest tap state=%s (want "
                                        % g.state + "walking)")
                else:
                        var m: Dictionary = g.legal[0]
                        g._start_move(int(m["piece"]), int(m["np"]))
                # THE HOP WALK: catch a hop
                await get_tree().create_timer(0.12).timeout
                await _snap("07_hop")
                # the landing (the drop on the start cell when it is one)
                while g.state == "walking":
                        g.probe_step(0.03)
                await get_tree().create_timer(0.15).timeout
                await _snap("08_landed")
        # THE CAPTURE SLIDE: craft the contact, seed the 1, film the slide
        # (the hunt PLAYS the waiting states - a user picking never moves
        # on its own, the squares rig taught us that much)
        _wait_user_roll()
        var caps_guard := 0
        var eat_filmed := false
        while caps_guard < 80 and not eat_filmed:
                caps_guard += 1
                if g.state == "round_over":
                        break
                if g.state == "picking" and g._is_user_army(g.turn_army):
                        var found: Dictionary = {}
                        for m2 in g.legal:
                                if int(m2["np"]) == 6 \
                                                and (m2["eats"] as Array) \
                                                        .size() > 0:
                                        found = m2
                                        break
                        if not found.is_empty():
                                g._start_move(int(found["piece"]), 6)
                                await get_tree().create_timer(0.2).timeout
                                await _snap("09_eat_walk")
                                while g.state == "walking":
                                        g.probe_step(0.03)
                                await get_tree().create_timer(0.3).timeout
                                await _snap("09b_slide")
                                eat_filmed = true
                                break
                        g.probe_play_first()
                        var k5 := 0
                        while k5 < 400:
                                g.probe_step(0.05)
                                k5 += 1
                                if g._is_user_army(g.turn_army) \
                                                and (g.state == "roll_wait" \
                                                or g.state == "picking"):
                                        break
                        continue
                if g.state == "roll_wait" and g._is_user_army(g.turn_army):
                        # craft the contact fresh, then roll for the 1
                        g.poss[0] = 5
                        g.poss[4] = 45
                        g._rng.seed = 9100 + caps_guard * 7
                        g.probe_roll()
                        continue
                g.probe_step(0.05)
        print("FILMDEBUG: eat hunt done filmed=%s guards=%d captures=%d"
                        % [eat_filmed, caps_guard,
                        Box.counter("ludo", "captures")])
        # THE BLOCKADE: two user pawns share a cell - the mid-to-side
        # law (the walk wants the exact 2, so the die is seeded until it)
        _wait_user_roll()
        var bguard := 0
        var block_filmed := false
        while bguard < 80 and not block_filmed:
                bguard += 1
                if g.state == "round_over":
                        break
                if g.state == "picking" and g._is_user_army(g.turn_army):
                        var found2: Dictionary = {}
                        for m3 in g.legal:
                                if int(m3["piece"]) == 1 \
                                                and int(m3["np"]) == 10:
                                        found2 = m3
                                        break
                        if not found2.is_empty():
                                g._start_move(1, 10)
                                while g.state == "walking":
                                        g.probe_step(0.03)
                                for w in 24:
                                        g.probe_step(0.05)
                                await get_tree().create_timer(0.2).timeout
                                await _snap("10_block")
                                block_filmed = true
                                break
                        g.probe_play_first()
                        var k6 := 0
                        while k6 < 400:
                                g.probe_step(0.05)
                                k6 += 1
                                if g._is_user_army(g.turn_army) \
                                                and (g.state == "roll_wait" \
                                                or g.state == "picking"):
                                        break
                        continue
                if g.state == "roll_wait" and g._is_user_army(g.turn_army):
                        # craft the pair-to-be (data only): one pawn at the
                        # cell, its friend two steps behind
                        g.poss[0] = 10
                        g.poss[1] = 8
                        g.poss[2] = -1
                        g.poss[3] = -1
                        g._rng.seed = 9300 + bguard * 11
                        g.probe_roll()
                        continue
                g.probe_step(0.05)
        print("FILMDEBUG: block hunt done filmed=%s guards=%d"
                        % [block_filmed, bguard])
        # THE COIN: the clock to the line, the spawn on a reachable cell
        g.poss[0] = 12
        g.play_clock = float(LD.COIN_EVERY) - 0.05
        g.probe_step(0.1)
        await get_tree().create_timer(0.6).timeout
        await _snap("11_coin")
        # THE VERDICT: the user's team comes home
        for p in 4:
                g.poss[p] = 56
        g._resolve(int(g.teams[1]))
        await get_tree().create_timer(0.7).timeout
        await _snap("12_verdict")
        # THE X4 TABLE (the v0.3.9-11 slab-seat law: the bottom trays sit
        # BELOW the frame slab + shadow - no overlap on the biggest cells)
        g._resolve(int(g.teams[2]))      # a loss flips the opener, keeps books
        await get_tree().create_timer(1.2).timeout
        g.probe_reset(4, 3310)
        _wait_user_roll()
        await get_tree().create_timer(0.3).timeout
        await _snap("13_x4table")
        # THE B&W THEME (the v0.3.9-11 contrast round)
        Box.reset_all()
        Box.earn(5000)
        Box.buy_item("ludo", "theme", "mono", 260)
        Box.equip_item("ludo", "theme", "mono")
        g._repaint()
        await get_tree().create_timer(0.3).timeout
        await _snap("14_mono")
        print("FILM: done shots=%d captures=%d" % [shots,
                        Box.counter("ludo", "captures")])
        get_tree().quit(0)
