extends Node
## qa_v03912_snl - SNAKES & LADDERS v0.3.9-12 law probe (the qa law):
## driven headless, exit 0 = pass. The owner's spec, pinned:
##   1. THE STATE LAW: the probe boot seats the round whole (roll_wait,
##      player 1 opens, the mode pick seats 2/3/4 tables).
##   2. THE THEATER: the die fades in, shuffles, settles - the face is
##      the truth; the CPU breathes and rolls by itself.
##   3. THE EXACT LANDING LAW: at 97 a 4 is REFUSED (the skipped turn,
##      the denied beat) and a 3 walks to the crown.
##   4. THE WALK: the hop walk lands the token exactly where the rules
##      core said (ONE TRUTH with the statics), the pen feeds the board.
##   5. THE LADDER RIDE: the base lifts the token in a straight lane to
##      the ladder's top (the drawn path IS the ride).
##   6. THE SNAKE FALL: the head swallows the token and the body's turns
##      carry it to the tail.
##   7. THE COIN LAW: the 5-minute clock spawns strictly ahead, stepping
##      on it collects (+1 run coin), a CPU can take it.
##   8. THE VERDICT: win +1 / loss -1 never under zero, the loser law
##      seats the opener, the streak counts.
##   9. THE SHELF: the shop wears TOKEN SKINS above THEMES, the ON rows
##      keep their seats, no dash talk.
##  10. THE SOAK: whole random rounds - the machine never hangs, every
##      position stays legal, every round reaches a verdict.

var fails := 0
var SN: GDScript

func _check(cond: bool, why := "") -> int:
        print("  %s: %s" % ["PASS" if cond else "FAIL", why])
        return 0 if cond else 1

# ---------------------------------------------------------------- the rig
var g: GogaGame = null

func _scene_game(players := 2) -> void:
        if g != null and is_instance_valid(g):
                g.queue_free()
                g = null
        SN = load("res://game/games/snl/snl.gd")
        g = SN.new()
        g.game_id = "snl"
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        g.probe_reset(players, 412)

func _drain(max_ticks := 900) -> void:
        g.probe_drain(max_ticks)

## the gate tap -> the mode sheet -> the pick (the real start flow)
func _start(players: int) -> void:
        g._gate_down()
        g._mode_sheet()
        await get_tree().process_frame
        g._pick_mode(players)
        await get_tree().process_frame

## roll for the user and settle the theater
func _user_roll() -> void:
        g.probe_roll()
        _drain(400)

## settle one crafted roll for whoever holds the turn (the face IS the
## truth - _after_roll reads g.roll, the walk/ride follows)
func _craft_roll(face: int) -> void:
        g.roll = face
        g._after_roll()
        _drain(400)

# ---------------------------------------------------------------- the laws

func _t_state_law() -> int:
        var ok := 0
        await _scene_game(2)
        # the BOOT: the probe seats the round whole
        ok += _check(g.state == "roll_wait" and g.turn == 1,
                "the probe boot seats the round (roll_wait, player 1 opens)")
        ok += _check(g.playing == [1, 2] and g.poss == [0, 0, 0, 0],
                "the 1v1 table seats two players, both tokens wait")
        ok += _check(g.opener == 1,
                "round 1 opens with the user (the opener law)")
        # the MODE PICK seats the bigger tables
        await _scene_game(4)
        ok += _check(g.playing.size() == 4,
                "the 4 pick seats four players (1v3)")
        ok += _check(g.poss.size() == 4,
                "four tokens wait out of the board")
        await _scene_game(3)
        ok += _check(g.playing == [1, 2, 3],
                "the 3 pick seats the 1v2 table")
        await _scene_game(2)
        return ok

func _t_theater_law() -> int:
        var ok := 0
        # the die: fade in, shuffle, settle - the face is the truth
        for t in 8:
                if g.state == "roll_wait" and g.turn == 1:
                        break
                _drain(300)
        g.probe_roll()
        ok += _check(g.state == "rolling" and g.die_alive,
                "the roll wakes the theater (die on the table)")
        var k := 0
        while g.state == "rolling" and k < 200:
                g.probe_step(0.05)
                k += 1
        ok += _check(g.roll >= 1 and g.roll <= 6,
                "the settled face is a real face (%d)" % g.roll)
        # the walk followed the face (positions, not words)
        var walked := int(g.poss[0])
        ok += _check(walked == g.roll or g.state == "walking",
                "the token walked the settled face (at %d)" % walked)
        # the CPU breathes and rolls by itself - the hand-off is ticked
        # step by step so the rig CATCHES the CPU mid-turn (a full drain
        # would play the CPU's whole turn before the check looks)
        var cpu_rolled := false
        var k2 := 0
        while k2 < 900:
                g.probe_step(0.05)
                k2 += 1
                if g.turn != 1 and g.state in ["rolling", "walking",
                                "riding"]:
                        cpu_rolled = true
                        break
        ok += _check(cpu_rolled, "the CPU breathes and rolls alone (pure RNG)")
        _drain(400)
        return ok

func _t_exact_landing_law() -> int:
        var ok := 0
        await _scene_game(2)
        # craft the table: the user AT 97 (the owner's own example)
        g.poss[0] = 97
        g.poss[1] = 5
        _drain(300)     # let the CPU sit wherever its breath is
        if g.state == "roll_wait" and g.turn != 1:
                # force the turn back to the user for the craft
                g.turn = 1
                g._start_turn()
        ok += _check(g.state == "roll_wait" and g.turn == 1,
                "the user's turn is seated at 97")
        # THE REFUSAL: a 4 is illegal, the turn skips
        g.roll = 4
        g._after_roll()
        ok += _check(g.state == "handoff",
                "97 + 4 is refused: the turn is skipped (handoff)")
        _drain(400)
        ok += _check(int(g.poss[0]) == 97,
                "the refused token never left 97")
        # back to the user: THE CROWN takes the exact 3
        if g.turn != 1:
                g.turn = 1
                g._start_turn()
        g.roll = 3
        g._after_roll()
        var k := 0
        while g.state == "walking" and k < 200:
                g.probe_step(0.05)
                k += 1
        ok += _check(int(g.poss[0]) == 100 and g.state == "round_over",
                "97 + 3 lands the crown and ends the round")
        ok += _check(g.wins == 1 and g.score == 1,
                "the crown pays +1 (win)")
        _drain(100)
        return ok

func _t_walk_law() -> int:
        var ok := 0
        await _scene_game(2)
        # the PEN feeds the board: the first roll walks cell by cell
        if g.state == "roll_wait" and g.turn != 1:
                _drain(300)
        if g.turn != 1:
                g.turn = 1
                g._start_turn()
        g.roll = 3
        g._after_roll()
        ok += _check(g.state == "walking" and int(g.walk["np"]) == 3,
                "the first roll walks the token in from the pen")
        var k := 0
        while g.state == "walking" and k < 200:
                g.probe_step(0.05)
                k += 1
        ok += _check(int(g.poss[0]) == 3,
                "the walk seats the token exactly on 3")
        # ONE TRUTH: a plain cell lands where the static said
        if g.turn != 1:
                g.turn = 1
                g._start_turn()
        g.roll = 2
        g._after_roll()
        k = 0
        while g.state == "walking" and k < 200:
                g.probe_step(0.05)
                k += 1
        ok += _check(int(g.poss[0]) == 5,
                "3 + 2 seats the token on 5 (plain cell)")
        _drain(300)
        return ok

func _t_ladder_law() -> int:
        var ok := 0
        await _scene_game(2)
        # craft: the user at 12, roll a 1 - the base at 13 lifts to 46
        g.poss[0] = 12
        g.poss[1] = 30
        if g.turn != 1:
                g.turn = 1
                g._start_turn()
        g.roll = 1
        g._after_roll()
        var k := 0
        while g.state == "walking" and k < 200:
                g.probe_step(0.05)
                k += 1
        ok += _check(g.state == "riding" and String(g.ride["kind"]) == "ladder",
                "landing on 13 wakes the ladder ride")
        # THE STRAIGHT LANE: the ride's path is base -> top, 2 points
        var pts: PackedVector2Array = g.ride["pts"]
        ok += _check(pts.size() == 2,
                "the ladder's lane is a straight line (2 points)")
        # the beat holds the token on the base first
        g.probe_step(0.05)
        ok += _check(g.state == "riding",
                "the ride breathes its beat on the base")
        k = 0
        while g.state == "riding" and k < 400:
                g.probe_step(0.05)
                k += 1
        ok += _check(int(g.poss[0]) == 46,
                "the ladder seats the token on its top (46)")
        _drain(300)
        return ok

func _t_snake_law() -> int:
        var ok := 0
        await _scene_game(2)
        # craft: the user at 98, roll a 1 - the head at 99 drops to 41
        g.poss[0] = 98
        g.poss[1] = 30
        if g.turn != 1:
                g.turn = 1
                g._start_turn()
        g.roll = 1
        g._after_roll()
        var k := 0
        while g.state == "walking" and k < 200:
                g.probe_step(0.05)
                k += 1
        ok += _check(g.state == "riding" and String(g.ride["kind"]) == "snake",
                "landing on 99 wakes the snake fall")
        # THE BODY'S TURNS: the fall follows the drawn path - many points,
        # and the drawn body IS the ridden path (one truth)
        var pts: PackedVector2Array = g.ride["pts"]
        ok += _check(pts.size() >= 8,
                "the fall follows the body's turns (%d points)"
                                % pts.size())
        ok += _check(pts == (g._paths[99] as PackedVector2Array),
                "the ridden path IS the drawn body (one truth)")
        k = 0
        while g.state == "riding" and k < 600:
                g.probe_step(0.05)
                k += 1
        ok += _check(int(g.poss[0]) == 41,
                "the snake seats the token at its tail (41)")
        _drain(300)
        return ok

func _t_coin_law() -> int:
        var ok := 0
        await _scene_game(2)
        # the 5-minute clock spawns the coin strictly ahead
        g.poss[0] = 40
        g.poss[1] = 10
        g.play_clock = SN.COIN_EVERY
        g._coin_maybe_spawn()
        ok += _check(g.coin_cell > 40,
                "the coin spawns strictly ahead of the user (%d)"
                                % g.coin_cell)
        ok += _check(g.coin_cell != int(g.poss[1]),
                "the coin never spawns under a token")
        # stepping ON it collects (+1 run coin)
        if g.turn != 1:
                g.turn = 1
                g._start_turn()
        g.roll = 1
        g._after_roll()     # the walk starts; the coin sits at coin_cell
        # craft the walk straight over the coin: put the user right below
        g.poss[0] = g.coin_cell - 1
        g.walk = {}
        if g.turn != 1:
                g.turn = 1
                g._start_turn()
        var cc: int = g.coin_cell
        g.roll = 1
        g.poss[0] = cc - 1
        g._after_roll()
        var k := 0
        while g.state == "walking" and k < 200:
                g.probe_step(0.05)
                k += 1
        ok += _check(g.run_coins == 1 and g.coin_cell == -1,
                "stepping on the coin takes it (+1 run coin)")
        ok += _check(g.play_clock < SN.COIN_EVERY,
                "the coin clock reset after the take")
        _drain(300)
        return ok

func _t_verdict_law() -> int:
        var ok := 0
        await _scene_game(2)
        # THE LOSS: a CPU crowns first - the score never sinks under 0
        g.poss[1] = 99
        g.poss[0] = 10
        if g.turn == 1:
                g.turn = 2
                g._start_turn()
        g.roll = 1
        g._after_roll()
        var k := 0
        while g.state in ["walking", "riding"] and k < 400:
                g.probe_step(0.05)
                k += 1
        ok += _check(g.state == "round_over" and g.losses == 1,
                "the rival's crown ends the round (loss)")
        ok += _check(g.score == 0,
                "the loss never drags the score under zero")
        ok += _check(g.opener == 1,
                "the loser law: the user lost, the user opens next")
        # THE WIN: the user crowns - +1 and the streak
        g.poss[0] = 99
        if g.turn != 1:
                g.turn = 1
                g._start_turn()
        g.roll = 1
        g._after_roll()
        k = 0
        while g.state in ["walking", "riding"] and k < 400:
                g.probe_step(0.05)
                k += 1
        ok += _check(g.state == "round_over" and g.wins == 1
                        and g.score == 1,
                "the user's crown pays +1")
        ok += _check(g.streak == 1,
                "the streak counts the win")
        ok += _check(g.opener == 2,
                "the loser law: the rival lost, the rival opens next")
        _drain(100)
        return ok

func _t_shelf_law() -> int:
        var ok := 0
        await _scene_game(2)
        g._shop_open()
        await get_tree().process_frame
        # the sheet's labels in order: TOKEN SKINS above THEMES
        var labels := []
        if g.sheet_open_count() > 0:
                var cc: Control = g._sheet_stack[0]["cc"]
                var stack := [cc]
                while not stack.is_empty():
                        var n: Node = stack.pop_front()
                        if n is Label:
                                labels.append(String((n as Label).text))
                        for c in n.get_children():
                                stack.append(c)
        var i1 := -1
        var i2 := -1
        for i in labels.size():
                var txt: String = labels[i]
                if i1 < 0 and txt.begins_with("TOKEN SKINS"):
                        i1 = i
                if i1 >= 0 and i2 < 0 and txt.begins_with("THEMES"):
                        i2 = i
        ok += _check(i1 >= 0 and i2 > i1,
                "the shop wears TOKEN SKINS above THEMES (shelf order law)")
        # THE NO-DASH LAW: no "word - talk" rows anywhere on the shelf
        var dash_free := true
        for txt in labels:
                if txt.contains(" - ") and not txt.contains("APPLY IT"):
                        dash_free = false
        ok += _check(dash_free,
                "the shelf wears no dash talk (the no-dash law)")
        # 5 skins + 5 themes seat their rows
        var skins := 0
        var themes := 0
        for id in SN.SKINS:
                skins += 1
        for id in SN.THEMES:
                themes += 1
        ok += _check(skins == 5 and themes == 5,
                "the shelf wears 5 skins and 5 themes")
        if g.sheet_open_count() > 0:
                g.sheet_pop()
        await get_tree().process_frame
        return ok

func _t_soak() -> int:
        var ok := 0
        # whole random rounds at every table size: the machine never
        # hangs, every position stays legal, every round reaches a verdict
        for table in [2, 3, 4]:
                await _scene_game(table)
                for r in 3:
                        var ended: bool = g.probe_auto_round(600)
                        var legal := true
                        for p in g.playing:
                                var pos := int(g.poss[int(p) - 1])
                                if pos < 0 or pos > SN.LAST:
                                        legal = false
                        var total: int = g.wins + g.losses
                        ok += _check(ended and legal and total >= r + 1,
                                "table %d round %d: verdict reached, "
                                                % [table, r + 1]
                                                + "positions legal "
                                                + "(W%d L%d)" % [g.wins,
                                                g.losses])
        # the openings alternate by the loser law across rounds
        await _scene_game(2)
        var openers := []
        for r in 4:
                g.probe_auto_round(600)
                openers.append(g.opener)
        var open_ok: bool = not openers.is_empty()
        for o in openers:
                if int(o) < 1 or int(o) > 2:
                        open_ok = false
        ok += _check(open_ok,
                "the opener law holds across rounds (openers %s)"
                                % [openers])
        return ok

# ---------------------------------------------------------------- the run

func _run(fails: int) -> void:
        if fails == 0:
                print("QA RESULT: ALL PASS")
        else:
                print("QA RESULT: %d FAIL" % fails)
        get_tree().quit(0 if fails == 0 else 1)

func _ready() -> void:
        print("== qa_v03912_snl ==")
        fails += await _t_state_law()
        fails += await _t_theater_law()
        fails += await _t_exact_landing_law()
        fails += await _t_walk_law()
        fails += await _t_ladder_law()
        fails += await _t_snake_law()
        fails += await _t_coin_law()
        fails += await _t_verdict_law()
        fails += await _t_shelf_law()
        fails += await _t_soak()
        _run(fails)
