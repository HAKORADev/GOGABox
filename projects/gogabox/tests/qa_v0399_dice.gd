extends Node
## qa_v0399_dice - CONQUER DICE v0.3.9-9 law probe (the qa law): driven
## headless, exit 0 = pass. The owner's spec, pinned:
##   1. THE STATE LAW: probe_reset seats the machine whole (ready ->
##      play, the opener seated) - and a rig never hand-sets state.
##   2. THE KJC LAWS on the live scene: the fresh board wakes at one
##      dot per die, the tap grows, the spill cascades exactly like the
##      pure do_move plan (ONE TRUTH), the board settles clean.
##   3. THE HOLD LAW: the gray-out press wakes on the die, follows the
##      drag, the release OFF the board cancels, an enemy die refuses,
##      and a REAL finger event lands through the engine queue.
##   4. THE VERDICT: total conquest pays +1 and flips the opener to the
##      loser; a loss never drags the score under zero.
##   5. THE COIN LAW: after 3 done rounds a coin rests on a neutral die
##      and its conqueror takes it (player or CPU).
##   6. THE BUY LAW: the shop sells, the options apply - a buy never
##      touches the live board, the confirm wipes it (the 2048 law).
##   7. THE THEME-OWNERSHIP LAW: a theme re-inks everything but the
##      user's dice; a skin re-inks ONLY the user's dice.
##   8. THE SOAK: the player plays random legal dice against the four
##      moods for 16 CONSECUTIVE rounds - every verdict lands, no hangs,
##      the memory remembers, the coin rounds come on the every-3 law.

var fails := 0
var JC: GDScript

func _check(cond: bool, why := "") -> int:
        print("  %s: %s" % ["PASS" if cond else "FAIL", why])
        if not cond:
                fails += 1
        return 0 if cond else 1

# ---------------------------------------------------------------- the rig
var g: GogaGame = null

func _scene_game() -> void:
        if g != null and is_instance_valid(g):
                g.queue_free()
                g = null
        g = JC.new()
        g.game_id = "jumpcube"
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame

func _mk_rng(seed_v: int) -> RandomNumberGenerator:
        var r := RandomNumberGenerator.new()
        r.seed = seed_v
        return r

func _cell_pt(i: int) -> Vector2:
        return g.cell_center(i)

func _tap(i: int) -> void:
        g._press(_cell_pt(i))
        g._release(_cell_pt(i))

## hand the player a position without touching the state machine (data
## only - the MASK LAW bans hand-setting state, never board data)
func _set_board(owners: Array, values: Array) -> void:
        g.owners = owners.duplicate()
        g.values = values.duplicate()

func _fresh_boards() -> Array:
        var ow := []
        var va := []
        for i in g.n * g.n:
                ow.append(0)
                va.append(1)
        return [ow, va]

func _fresh(side := 4) -> void:
        g.probe_reset(9137, side)

func _drain() -> void:
        g.probe_drain()

## parse_input_event expects WINDOW coords; delivery maps them into the
## canvas via final_transform⁻¹, so we apply the forward transform
## (the flow_test _to_window law)
func _to_window(viewport_pos: Vector2) -> Vector2:
        return get_viewport().get_final_transform() * viewport_pos

## step the machine until the cascade's air is clear but the CPU has
## NOT yet replied (the plan comparison rides exactly there)
func _drain_anim() -> void:
        var k := 0
        while g.state == "anim" and k < 200:
                g.probe_step(0.02)
                k += 1

# ---------------------------------------------------------------- the laws

func _t_state_law() -> int:
        var ok := 0
        await _scene_game()
        _fresh(4)
        # THE STATE LAW: the door seats everything - no hand-set here
        ok += _check(g.state == "play",
                "probe_reset seats play (the user opens first, owner law)")
        ok += _check(g.turn == 1 and g.next_opener == 1,
                "the opener is seated: the user opens round 1")
        ok += _check(g.n == 4 and g.owners.size() == 16 \
                        and g.values.size() == 16,
                "the 4x4 board wears 16 dice")
        var fresh := true
        for i in 16:
                fresh = fresh and int(g.owners[i]) == 0 \
                                and int(g.values[i]) == 1
        ok += _check(fresh,
                "every die wakes NEUTRAL with ONE dot (the original's law)")
        ok += _check(g.cell > 40.0 and g.board_origin.x > 0.0,
                "the layout landed (cell %.0f at %s)"
                                % [g.cell, str(g.board_origin)])
        ok += _check(g.ready_ui == null,
                "the gate is down under the probe")
        ok += _check(g.profile != "" and JC.PROFILES.has(g.profile),
                "the mood rotation seated a real mood (%s)" % g.profile)
        ok += _check(g.pause_end_run,
                "the pause sheet carries END (the pong banking law)")
        return ok

func _t_hold_law() -> int:
        var ok := 0
        await _scene_game()
        _fresh(4)
        # THE HOLD: the gray-out wakes under the finger
        g._press(_cell_pt(5))
        ok += _check(g.holding and g.ghost_cell == 5,
                "the press wakes the gray-out on the die under the finger")
        # the follow: the drag moves the ghost, off-board lifts it
        var drag := InputEventScreenDrag.new()
        drag.position = _cell_pt(6)
        g._goga_input(drag)
        ok += _check(g.ghost_cell == 6, "the drag moves the press")
        drag.position = Vector2(10, 10)     # far off the board
        g._goga_input(drag)
        ok += _check(g.ghost_cell == -1,
                "the drag off the board lifts the press (the cancel seat)")
        drag.position = _cell_pt(6)
        g._goga_input(drag)
        ok += _check(g.ghost_cell == 6, "back on the board it re-arms")
        # the release lands the dot
        g._release(_cell_pt(6))
        ok += _check(not g.holding and int(g.values[6]) == 2 \
                        and int(g.owners[6]) == 1,
                "the release grows the die by one and takes it")
        ok += _check(g.state == "wait" and g.turn == 2,
                "the move hands the board to the CPU (the think state)")
        _drain()
        ok += _check(g.state == "play" and g.turn == 1,
                "the CPU answered and the board came back (the drain law)")
        # the cancel: press + release OFF the board places nothing
        var before := int(g.values[9])
        g._press(_cell_pt(9))
        drag = InputEventScreenDrag.new()
        drag.position = Vector2(10, 10)
        g._goga_input(drag)
        g._release(Vector2(10, 10))
        ok += _check(int(g.values[9]) == before and not g.holding,
                "the off-board release places NOTHING (the owner's cancel)")
        # the enemy die refuses the tap
        var ow: Array = g.owners.duplicate()
        var va: Array = g.values.duplicate()
        ow[2] = 2
        _set_board(ow, va)
        var v2 := int(g.values[2])
        g._press(_cell_pt(2))
        ok += _check(g.holding and g.ghost_cell == 2,
                "the press still wakes on an enemy die (the feel)")
        g._release(_cell_pt(2))
        ok += _check(int(g.values[2]) == v2 and int(g.owners[2]) == 2,
                "the enemy die refuses the tap (the solidity law)")
        # the real finger journey: engine queue -> unhandled -> tk -> game
        var free := -1
        for i in g.n * g.n:
                if int(g.owners[i]) == 0:
                        free = i
                        break
        ok += _check(free >= 0, "a neutral die exists for the real finger")
        var ev := InputEventScreenTouch.new()
        ev.position = _to_window(_cell_pt(free))
        ev.pressed = true
        ev.index = 0
        Input.parse_input_event(ev)
        await get_tree().process_frame
        await get_tree().process_frame
        ok += _check(g.holding and g.ghost_cell == free,
                "the REAL finger press lands through the engine queue")
        var ev2 := InputEventScreenTouch.new()
        ev2.position = _to_window(_cell_pt(free))
        ev2.pressed = false
        ev2.index = 0
        Input.parse_input_event(ev2)
        await get_tree().process_frame
        await get_tree().process_frame
        _drain()
        ok += _check(int(g.owners[free]) == 1,
                "the REAL finger release conquers the die")
        return ok

func _t_gate_hush() -> int:
        var ok := 0
        await _scene_game()             # a fresh boot wears the gate
        ok += _check(g.state == "ready" and g.ready_ui != null,
                "the boot wears the gate (TAP ANYWHERE TO START)")
        # THE GATE TAP: the touch closes the gate - and Godot's
        # mouse-from-touch emulation rides a SECOND press in the same
        # flush. THE GATE HUSH swallows it: no move plays under the tap.
        var evg := InputEventScreenTouch.new()
        evg.position = _cell_pt(10)
        evg.pressed = true
        g._goga_input(evg)
        ok += _check(g.state == "play" and g.ready_ui == null,
                "the gate tap opens the round")
        var evp := InputEventScreenTouch.new()
        evp.position = _cell_pt(10)
        evp.pressed = true
        g._goga_input(evp)              # the emulated-mouse shadow
        var evr := InputEventScreenTouch.new()
        evr.position = _cell_pt(10)
        evr.pressed = false
        g._goga_input(evr)              # the tap's own release
        ok += _check(int(g.values[10]) == 1 and int(g.owners[10]) == 0 \
                        and g.turn == 1,
                "no move played under the gate tap (the hush law)")
        for w in 6:
                g.probe_step(0.05)      # the hush expires
        g._press(_cell_pt(10))
        ok += _check(g.holding and g.ghost_cell == 10,
                "a real tap right after plays (the hush is a beat, not a lock)")
        g._release(_cell_pt(10))
        _drain()
        ok += _check(int(g.values[10]) == 2 and int(g.owners[10]) == 1,
                "the board is live after the hush")
        return ok

func _t_spill_scene() -> int:
        var ok := 0
        await _scene_game()
        _fresh(4)
        # grow the corner to its cap, then push it over: the cascade
        _tap(0)                     # 1 -> 2 (the die is ours now)
        _drain()
        ok += _check(int(g.values[0]) == 2 and int(g.owners[0]) == 1,
                "the corner grew to its cap under the taps")
        var fb: Array = _fresh_boards()
        fb[1][0] = 2                # the corner sits AT its cap
        _set_board(fb[0], fb[1])    # a clean position (data only)
        _tap(0)                     # 2 -> 3: OVER the cap - the spill
        ok += _check(g.state == "anim",
                "the spill runs through the anim state (the in and the out)")
        _drain_anim()               # the air clears BEFORE the CPU replies
        ok += _check(g.state == "wait" and g.turn == 2,
                "the cascade drained into the CPU's think (no reply yet)")
        # the scene's board must EQUAL the pure plan (the ONE-TRUTH law)
        var plan: Dictionary = JC.do_move(fb[0], fb[1], 4, 1, 0)
        var same := true
        for i in 16:
                same = same and int(g.owners[i]) == int(plan["owners"][i]) \
                                and int(g.values[i]) == int(plan["values"][i])
        ok += _check(same,
                "the live cascade matches the pure plan cell for cell")
        _drain()
        ok += _check(g.state == "play" and g.turn == 1,
                "the CPU replied and the hand-off completed")
        var settled := true
        for i in 16:
                if int(g.values[i]) > int(JC.max_of(i, g.n)):
                        settled = false
        ok += _check(settled, "the board settled clean (no die over its cap)")
        ok += _check(g.cascade.is_empty() and g.lands.is_empty() \
                        and g.move_who == 0,
                "the pipeline's air is clean after the drain")
        # THE COIN LAW: after 3 done rounds the next round opens a coin
        g.done_rounds = 3           # the docket counter (data)
        g._new_round()              # the ONLY door - it seats the coin
        ok += _check(g.coin_cell >= 0 and int(g.owners[g.coin_cell]) == 0,
                "after 3 done rounds a coin rests on a NEUTRAL die")
        ok += _check(g.state == "play" and g.turn == 1,
                "the coin round seated the machine (the state law)")
        # steer the coin onto the die the spill will feed, then take it
        g.coin_cell = 1
        var coins0 := g.run_coins
        var ow3: Array = g.owners.duplicate()
        var va3: Array = g.values.duplicate()
        va3[0] = int(JC.max_of(0, g.n))   # the corner at its cap
        _set_board(ow3, va3)
        g._place(0, 1)              # the spill feeds die 1 (the coin die)
        _drain()
        ok += _check(g.run_coins == coins0 + 1,
                "the coin die's conqueror takes it (+1 run coin)")
        ok += _check(g.coin_cell == -1, "the coin left the board")
        return ok

func _t_verdicts() -> int:
        var ok := 0
        await _scene_game()
        _fresh(4)
        # THE WIN: all but one die mine - the last tap conquers the board
        var ow := []
        var va := []
        for i in 16:
                ow.append(1)
                va.append(1)
        ow[15] = 0
        _set_board(ow, va)
        var s0 := g.score
        g._place(15, 1)
        _drain()
        ok += _check(g.state == "round_over",
                "total conquest ends the round (the original's verdict)")
        ok += _check(g.score == s0 + 1 and g.wins == 1 and g.streak == 1,
                "the win pays +1 and counts (the owner's economy)")
        ok += _check(g.next_opener == 2,
                "the loser opens next (the owner's opener law)")
        ok += _check(g.done_rounds == 1 and g.mem.size() == 1,
                "the round is remembered (the memory law)")
        # the round-over clock walks into a fresh round, CPU opens
        var waited := 0
        while g.state == "round_over" and waited < 80:
                g.probe_step(0.05)
                waited += 1
        ok += _check(g.state == "wait" and g.turn == 2 \
                        and g.rounds == 2,
                "the loser (CPU) opened round 2 (the state law again)")
        _drain()
        ok += _check(g.state == "play" and g.turn == 1,
                "the CPU's opening handed the board back")
        # THE LOSS: the CPU takes the board - the score never goes under
        var ow2 := []
        var va2 := []
        for i in 16:
                ow2.append(2)
                va2.append(1)
        ow2[15] = 0
        _set_board(ow2, va2)
        g.score = 0
        g._place(15, 2)
        _drain()
        ok += _check(g.state == "round_over" and g.losses == 1 \
                        and g.score == 0,
                "the loss never drags the score under zero")
        ok += _check(g.next_opener == 1,
                "the loser (the player) opens next")
        return ok

func _t_buy_law() -> int:
        var ok := 0
        await _scene_game()
        _fresh(4)
        Box.reset_all()
        Box.earn(50000)
        # THE BUY LAW: a buy NEVER touches the live board
        var v0 := int(g.values[7])
        ok += _check(Box.buy_item("jumpcube", "size", "6", 1800),
                "the shop sells the big board")
        ok += _check(g.n == 4 and int(g.values[7]) == v0,
                "the buy left the live board untouched (the 2048 law)")
        # the owned shop row points home: NO Button subtree
        var row: Control = g._size_row("6", true)
        ok += _check(Arc._buttons_in(row).is_empty(),
                "the owned size's shop row wears no button (BUY LAW)")
        # the options picker wears the SWITCH
        var row2: Control = g._size_row("6", false)
        ok += _check(Arc._buttons_in(row2).size() == 1,
                "the options picker wears the SWITCH")
        # the are-you-sure: the confirm pushes, the YES applies + re-seats
        var stack0 := g.sheet_open_count()
        g._size_confirm("6")
        ok += _check(g.sheet_open_count() == stack0 + 1,
                "the confirm pushed on the stack")
        var yes: Button = null
        for b in Arc._buttons_in(g._overlay_root_ref()):
                if b is Button and String(b.text).begins_with("YES"):
                        yes = b
        ok += _check(yes != null, "the confirm wears the YES")
        if yes != null:
                yes.pressed.emit()
                await get_tree().process_frame
        ok += _check(g.n == 6 and g.size_id == "6",
                "the YES applied the big board (36 dice)")
        ok += _check(g.owners.size() == 36 \
                        and String(Box.item_on("jumpcube", "size")) == "6",
                "the board rebuilt and the equip persisted")
        if g.sheet_open_count() > 0:
                g.sheet_pop()
        # THE THEME-OWNERSHIP LAW
        ok += _check(Box.buy_item("jumpcube", "theme", "mono", 240),
                "the shop sells the B&W theme")
        Box.equip_item("jumpcube", "theme", "mono")   # the shop equips
        ok += _check(g._theme_id() == "mono",
                "the B&W theme equips")
        ok += _check(g._user_col().v > 0.9 and g._theme()["foe"].v < 0.2,
                "B&W: you are WHITE, the enemy is BLACK (the owner's ask)")
        ok += _check(Box.buy_item("jumpcube", "skin", "crimson", 120),
                "the shop sells the crimson skin")
        Box.equip_item("jumpcube", "skin", "crimson")
        ok += _check(g._skin_id() == "crimson" \
                        and g._user_col().r > 0.8 \
                        and g._theme()["die"].v > 0.5,
                "the skin re-inks ONLY the user's dice (the ownership law)")
        Box.reset_all()
        return ok

func _t_soak() -> int:
        var ok := 0
        await _scene_game()
        Box.reset_all()
        Box.earn(1000)
        var rng := _mk_rng(4242)
        var coin_rounds := 0
        var verdicts := 0
        _fresh(4)                   # ONE probe door - the rounds then run
        for round_i in 16:          # CONSECUTIVELY (the coin law counts)
                if g.coin_cell >= 0:
                        coin_rounds += 1
                var guard := 0
                while g.state != "round_over" and guard < 400:
                        guard += 1
                        if g.state == "play" and g.turn == 1:
                                # the random legal hand (the soak's driver)
                                var cands := []
                                for i in g.n * g.n:
                                        if JC.legal_at(g.owners, i, 1):
                                                cands.append(i)
                                if cands.is_empty():
                                        break
                                var pick: int = cands[rng.randi()
                                                % cands.size()]
                                g._place(pick, 1)
                        _drain()
                ok += _check(g.state == "round_over",
                        "round %d reached a verdict (no hangs)" % round_i)
                if g.state != "round_over":
                        break
                verdicts += 1
                ok += _check(g.wins + g.losses == g.done_rounds,
                        "round %d: the tally matches the docket (W%d L%d)"
                                        % [round_i, g.wins, g.losses])
                var full := true
                for i in g.n * g.n:
                        if int(g.owners[i]) == 0:
                                full = false
                ok += _check(full,
                        "round %d: the verdict left NO die neutral"
                                        % round_i)
                # the round-over clock walks into the next round
                var waited := 0
                while g.state == "round_over" and waited < 80:
                        g.probe_step(0.05)
                        waited += 1
                ok += _check(g.state == "play" or g.state == "wait",
                        "round %d: the next round seated itself" % round_i)
                if g.state == "round_over":
                        break
        ok += _check(verdicts == 16, "16 soak rounds, 16 verdicts")
        ok += _check(coin_rounds >= 3,
                "the coin rounds came (%d of 16 - the every-3 law)"
                                % coin_rounds)
        var mem_ok: bool = g.mem.size() <= JC.MEM_ROUNDS
        ok += _check(mem_ok, "the memory wears its 2-round window")
        return ok

# ------------------------------------------------------------------ run

func _ready() -> void:
        JC = load("res://game/games/jumpcube/jumpcube.gd")
        print("=== qa_v0399_dice: CONQUER DICE laws ===")
        fails += await _err("state law", _t_state_law)
        fails += await _err("gate hush", _t_gate_hush)
        fails += await _err("hold law", _t_hold_law)
        fails += await _err("spill scene", _t_spill_scene)
        fails += await _err("verdicts", _t_verdicts)
        fails += await _err("buy + theme laws", _t_buy_law)
        fails += await _err("the soak", _t_soak)
        print("RESULT: %s" % ("ALL PASS" if fails == 0
                        else "%d FAILURES" % fails))
        get_tree().quit(0 if fails == 0 else 1)

func _err(name_: String, fn: Callable) -> int:
        var before := fails
        await fn.call()
        var made: int = fails - before
        print("%s: %s (%d checks)" % ["PASS" if made == 0 else "FAIL",
                        name_, made])
        return made
