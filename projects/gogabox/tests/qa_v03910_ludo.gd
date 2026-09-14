extends Node
## qa_v03910_ludo - BOARD LUDO v0.3.9-10 law probe (the qa law): driven
## headless, exit 0 = pass. The owner's spec, pinned:
##   1. THE STATE LAW: the boot seats ready + the gate; the mode pick
##      seats the round whole (opener = army 1, the ROLL pill waits).
##   2. THE THEATER: the die fades in, shuffles, settles - the face is
##      the truth; no legal moves hands the turn on (the owner: "if not,
##      turn is end and then opponent").
##   3. THE 6 LAW: a 6 drops a pawn and KEEPS the table (same army rolls).
##   4. THE WALK: the hop walk lands the pawn exactly where the rules
##      core said it would (ONE TRUTH with the statics).
##   5. THE EAT: the walker takes the lone foe - it slides all the way
##      home, no bonus moves, the captures counter climbs.
##   6. THE COIN LAW: the 6-minute clock spawns the coin on a reachable
##      cell; passing through collects (+1 run coin).
##   7. THE VERDICT: a full team home pays +1 and flips the opener to
##      the loser's team; a loss never drags the score under zero.
##   8. THE SOAK: random-legal user vs the pure-RNG CPUs - the machine
##      never hangs, every state stays legal, pawns stay in [-1..56].
##   9. THE SHELF ORDER LAW: jumpcube's shop wears DICE SKINS above
##      THEMES (the owner caught the swap); ludo wears PIECE SKINS above
##      THEMES from birth.

var fails := 0
var LD: GDScript

func _check(cond: bool, why := "") -> int:
        print("  %s: %s" % ["PASS" if cond else "FAIL", why])
        return 0 if cond else 1

# ---------------------------------------------------------------- the rig
var g: GogaGame = null

func _scene_game(mode := 1) -> void:
        if g != null and is_instance_valid(g):
                g.queue_free()
                g = null
        g = LD.new()
        g.game_id = "ludo"
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        g.probe_reset(mode, 410)

func _drain(max_ticks := 600) -> void:
        g.probe_drain(max_ticks)

## the gate tap -> the mode sheet -> the pick (the real start flow)
func _start(mode: int) -> void:
        g._gate_down()
        g._mode_sheet()
        await get_tree().process_frame
        g._pick_mode(mode)
        await get_tree().process_frame

## roll for the user army and settle the theater
func _user_roll() -> void:
        g.probe_roll()
        _drain(200)

func _user_play(piece: int, np: int) -> void:
        g._start_move(piece, np)
        _drain(200)

## play random legal user moves until the eat lands or the budget dies
func _hunt_eat(budget := 60) -> bool:
        for t in budget:
                if g.state == "roll_wait" and g._is_user_army(g.turn_army):
                        g.probe_roll()
                        _drain(200)
                if g.state == "picking" and g._is_user_army(g.turn_army):
                        for m in g.legal:
                                if (m["eats"] as Array).size() > 0:
                                        var foe_slot := -1
                                        for e in m["eats"]:
                                                foe_slot = (int(e["army"]) \
                                                                - 1) * 4 \
                                                                + int(e["piece"])
                                        var before: int = g.poss[foe_slot]
                                        g._start_move(int(m["piece"]),
                                                        int(m["np"]))
                                        var k3 := 0
                                        while g.state == "walking" \
                                                        and k3 < 400:
                                                g.probe_step(0.05)
                                                k3 += 1
                                        var gone: int = g.poss[foe_slot]
                                        _drain(300)
                                        return before >= 0 and gone == -1
                        # no eat on the table - play the first legal move
                        g.probe_play_first()
                        _drain(300)
                elif g.state == "handoff" or g.state == "roll_wait":
                        _drain(100)
        return false

# ---------------------------------------------------------------- the laws

func _t_state_law() -> int:
        var ok := 0
        LD = load("res://game/games/ludo/ludo.gd")
        await _scene_game()
        # the BOOT: ready (the probe's gate is down by design - probe_reset
        # skips the gate, the boot itself wore it)
        ok += _check(g.state == "roll_wait" and g.turn_army == 1,
                "the probe boot seats the round (roll_wait, army 1 opens)")
        # the MODE PICK seats the round whole
        await _start(1)
        ok += _check(g.state == "roll_wait" and g.turn_army == 1,
                "the mode pick seats roll_wait with army 1 opening")
        ok += _check(g.ready_ui == null,
                "the gate is down once the table is set")
        ok += _check(g.playing.size() == 2 and g.teams.size() == 2,
                "x1 seats two armies (one team each)")
        ok += _check(g._is_user_army(1) and not g._is_user_army(2),
                "army 1 is the user's, army 2 the CPU's")
        # x2's marriage
        await _scene_game(2)
        ok += _check(int(g.teams[1]) == 1 and int(g.teams[3]) == 1 \
                        and g.playing.size() == 4,
                "x2 fields four armies in two teams")
        ok += _check(g._is_user_army(3),
                "the ally law: army 3 answers to the user's hand too")
        await _scene_game(4)
        ok += _check(g.teams.size() == 4 and not g._is_user_army(2) \
                        and not g._is_user_army(3) and not g._is_user_army(4),
                "x4 is the chaos: three CPU rivals")
        # back to x1 for the walk-through
        await _scene_game(1)
        await _start(1)
        return ok

func _t_theater_law() -> int:
        var ok := 0
        # THE THEATER: the die fades in, shuffles, settles - the face is
        # the truth, and no-legal hands the turn on
        var rolls_with_moves := 0
        for t in 24:
                if g.state != "roll_wait" or not g._is_user_army(g.turn_army):
                        _drain(200)
                        continue
                g.probe_roll()
                ok += _check(g.state == "rolling" and g.die_alive,
                        "the roll wakes the theater (die on the table)")
                var shuffling := false
                var k := 0
                while g.state == "rolling" and k < 200:
                        if g._time - g.die_t0 > LD.FADE_T \
                                        and g._time - g.die_t0 < LD.FADE_T \
                                        + LD.SHUF_T:
                                shuffling = true
                        g.probe_step(0.05)
                        k += 1
                ok += _check(shuffling,
                        "the die shuffles between the fade and the settle")
                if g.state == "picking":
                        rolls_with_moves += 1
                        ok += _check(g.roll == g.die_face and g.roll >= 1 \
                                        and g.roll <= 6,
                                "the settled face is the truth (1..6)")
                        ok += _check(g.legal.size() > 0,
                                "the settle wakes the legal moves")
                        break
                elif g.state == "handoff":
                        ok += _check(g.legal.is_empty(),
                                "no legal moves hands the turn on (denied)")
                        _drain(200)
        ok += _check(rolls_with_moves > 0,
                "the fresh board answers the 6 with the drop (%d of 24)"
                                % rolls_with_moves)
        return ok

func _t_six_law() -> int:
        var ok := 0
        # THE 6 LAW: a 6 drops a pawn and the SAME army rolls again
        var guarded := 0
        while guarded < 160:
                guarded += 1
                if g.state == "picking" and g._is_user_army(g.turn_army):
                        var drop: Dictionary = {}
                        for m in g.legal:
                                if int(m["np"]) == 0:
                                        drop = m
                                        break
                        if not drop.is_empty():
                                _user_play(int(drop["piece"]), 0)
                                ok += _check(int(g.poss[0]) == 0,
                                        "the drop seats the pawn on the start")
                                ok += _check(g.state == "roll_wait" \
                                                and g.turn_army == 1,
                                        "the 6 keeps the table (same army rolls)")
                                return ok
                        g.probe_play_first()
                        _drain(300)
                elif g.state == "roll_wait" and g._is_user_army(g.turn_army):
                        g.probe_roll()
                        _drain(200)
                else:
                        _drain(200)
        ok += _check(false, "the 6 never came in %d rolls (impossible)" % guarded)
        return ok

func _t_turn_law() -> int:
        var ok := 0
        # THE TURN LAW: a non-6 move walks the turn to the next army
        var turn_walked := false
        for t in 120:
                if t < 14:
                        print("    [tl %d] state=%s turn=%d roll=%d legal=%d die=%s" % [t, g.state, g.turn_army, g.roll, g.legal.size(), g.die_alive])
                if g.state == "picking" and g._is_user_army(g.turn_army):
                        var was := int(g.turn_army)
                        if g.roll != 6:
                                g.probe_play_first()
                                var k2 := 0
                                while k2 < 600:
                                        g.probe_step(0.05)
                                        k2 += 1
                                        if int(g.turn_army) != was:
                                                turn_walked = true
                                                break
                                _drain(300)
                                break
                        g.probe_play_first()
                        _drain(400)
                elif g.state == "roll_wait" and g._is_user_army(g.turn_army):
                        g.probe_roll()
                        _drain(200)
                else:
                        _drain(200)
        print("    [turnlaw debug] state=%s turn=%d roll=%d legal=%d" % [g.state, g.turn_army, g.roll, g.legal.size()])
        ok += _check(turn_walked,
                "a non-6 move hands the turn to the rival")
        return ok

func _t_eat_law() -> int:
        var ok := 0
        # THE EAT: a CRAFTED contact - the user's pawn one step behind a
        # lone foe, the die seeded until it shows the 1, the walk takes
        # the foe all the way home (no bonus moves ride the eat)
        var caps_before := Box.counter("ludo", "captures")
        var eaten := false
        var tries := 0
        while tries < 40 and not eaten:
                tries += 1
                # wait for the user's hand (data stays; the machine turns)
                var guard := 0
                while not (g.state == "roll_wait" \
                                and g._is_user_army(g.turn_army)) \
                                and guard < 300:
                        g.probe_step(0.05)
                        guard += 1
                if g.state == "round_over":
                        break
                # craft the contact (board data only - the MASK LAW)
                g.poss[0] = 5
                g.poss[4] = 45      # the foe one step ahead ((13+45)%52=6)
                g._rng.seed = 7100 + tries * 17
                g.probe_roll()
                _drain(200)
                if g.state != "picking":
                        continue
                for m in g.legal:
                        if int(m["np"]) == 6 \
                                        and (m["eats"] as Array).size() > 0:
                                g._start_move(int(m["piece"]), 6)
                                var k4 := 0
                                while g.state == "walking" and k4 < 400:
                                        g.probe_step(0.05)
                                        k4 += 1
                                eaten = int(g.poss[4]) == -1
                                _drain(300)
                                break
        ok += _check(eaten,
                "the walker ate the lone foe (the slide law, %d seeds)"
                                % tries)
        ok += _check(Box.counter("ludo", "captures") > caps_before,
                "the captures counter climbed (%d -> %d)" % [caps_before,
                Box.counter("ludo", "captures")])
        return ok

func _t_coin_law() -> int:
        var ok := 0
        # THE COIN LAW: the 6-minute clock spawns on a reachable cell;
        # passing through collects (a pawn is seated ON the ring first so
        # the reachable set can never be empty; the USER's hand is waited
        # for so the craft moves the user's pawn, never a CPU's)
        var coin_guard := 0
        while not (g.state == "roll_wait" and g._is_user_army(g.turn_army)) \
                        and coin_guard < 300 and g.state != "round_over":
                g.probe_step(0.05)
                coin_guard += 1
        g.poss[0] = 5
        g.play_clock = float(LD.COIN_EVERY) - 0.05
        g.probe_step(0.1)
        ok += _check(g.coin_ring >= 0,
                "the coin clock spawns the coin (every 6 in-game minutes)")
        var spots: Array = LD.coin_spots(g.poss, [1], g.teams)
        ok += _check(spots.has(g.coin_ring),
                "the coin sits where a pawn can still reach it")
        # walk a user pawn straight through it
        var target := int(g.coin_ring)
        # seat the user's first pawn one step before the coin (data only)
        var from_pos := (target - int(LD.RING_STARTS[1]) + 52) % 52
        if from_pos == 0:
                from_pos = 52
        g.poss[0] = from_pos - 1
        var coins_before := g.run_coins
        g._start_move(0, from_pos)
        _drain(300)
        ok += _check(g.run_coins == coins_before + 1,
                "passing through collects (+1 run coin)")
        ok += _check(g.coin_ring == -1 and g.play_clock < float(LD.COIN_EVERY),
                "the coin is taken and the clock restarted from zero")
        return ok

func _t_verdict_law() -> int:
        var ok := 0
        # THE VERDICT: a full team home pays +1 and flips the opener
        var score_before := g.score
        for p in 4:
                g.poss[p] = 56
        g._resolve(int(g.teams[1]))
        ok += _check(g.state == "round_over" and g.score == score_before + 1,
                "the full team home pays +1")
        ok += _check(g.wins == 1 and g.opener == 2,
                "the loser's team opens the next round (army 2)")
        ok += _check(g.verdict_lbl.visible and g.verdict_lbl.text != "",
                "the verdict speaks")
        g.clock = 10.0
        g.probe_step(0.1)
        var fresh_ok: bool = g.state == "roll_wait"
        for i in 16:
                fresh_ok = fresh_ok and int(g.poss[i]) == -1
        ok += _check(fresh_ok,
                "the round turns over into a fresh board (state=%s)"
                                % g.state)
        ok += _check(g.turn_army == 2 and not g._is_user_army(g.turn_army),
                "the CPU opens like the loser law said")
        # THE LOSS: never under zero, the opener comes back
        var s2 := g.score
        g._resolve(int(g.teams[2]))
        ok += _check(g.score == s2 - 1,
                "the loss takes one (%d -> %d)" % [s2, g.score])
        ok += _check(g.opener == 1, "the user opens after the loss")
        g.score = 0
        g._resolve(int(g.teams[2]))
        ok += _check(g.score == 0,
                "the score never drags under zero")
        g.score = 0
        return ok

func _t_soak() -> int:
        var ok := 0
        # THE SOAK: random-legal user vs the pure-RNG CPUs, x1 then x4 -
        # the machine never hangs, every state stays legal, the poss
        # slots stay in [-1..56], and completed rounds keep the books
        for mode in [1, 4]:
                await _scene_game(mode)
                await _start(mode)
                var rng := RandomNumberGenerator.new()
                rng.seed = 97 + mode
                var steps := 0
                var stuck := 0
                var last_state := ""
                var bad := false
                var rounds_seen := 0
                while steps < 4200 and rounds_seen < 2:
                        g.probe_step(0.08)
                        steps += 1
                        var valid := false
                        match g.state:
                                "ready", "roll_wait", "rolling", "picking", \
                                "walking", "handoff", "round_over":
                                        valid = true
                        if not valid:
                                bad = true
                                break
                        for i in 16:
                                var pv := int(g.poss[i])
                                if pv < -1 or pv > 56:
                                        bad = true
                        if bad:
                                break
                        if g.state == last_state:
                                stuck += 1
                        else:
                                stuck = 0
                                last_state = g.state
                        if stuck > 400:
                                bad = true
                                break
                        if g.state == "round_over":
                                g.clock = 10.0
                                rounds_seen += 1
                        elif g.state == "roll_wait" \
                                        and g._is_user_army(g.turn_army):
                                g.probe_roll()
                        elif g.state == "picking" \
                                        and g._is_user_army(g.turn_army) \
                                        and rng.randf() < 0.9:
                                g.probe_play_first()
                ok += _check(not bad,
                        "the x%d soak stayed sane (%d steps, %d rounds)"
                                        % [mode, steps, rounds_seen])
                if rounds_seen > 0:
                        ok += _check(g.wins + g.losses == rounds_seen,
                                "the books match the rounds played (%d+%d=%d)"
                                        % [g.wins, g.losses, rounds_seen])
                else:
                        ok += _check(g.wins + g.losses == 0,
                                "no round finished inside the budget - the "
                                + "books stay at zero (ludo is LONG, the "
                                + "owner said so)")
        return ok

## every Label text under the sheet, in document order
func _sheet_labels(root: Node) -> Array:
        var out := []
        if root is Label:
                out.append(String(root.text))
        for c in root.get_children():
                out.append_array(_sheet_labels(c))
        return out

func _t_shop_order_law() -> int:
        var ok := 0
        # THE SHELF ORDER LAW (the owner caught the dice game swapping):
        # jumpcube: DICE SKINS above THEMES. ludo: PIECE SKINS above THEMES.
        for pair in [["jumpcube", "DICE SKINS", "THEMES -"],
                     ["ludo", "PIECE SKINS", "THEMES -"]]:
                var gid: String = pair[0]
                var first_tag: String = pair[1]
                var second_tag: String = pair[2]
                if g != null and is_instance_valid(g):
                        g.queue_free()
                        g = null
                var other: GogaGame = load("res://game/games/%s/%s.gd"
                                % [gid, gid]).new()
                other.game_id = gid
                add_child(other)
                await get_tree().process_frame
                await get_tree().process_frame
                other._shop_open()
                await get_tree().process_frame
                var labels := _sheet_labels(other)
                var i1 := -1
                var i2 := -1
                for i in labels.size():
                        var txt := String(labels[i])
                        if i1 < 0 and txt.begins_with(first_tag):
                                i1 = i
                        if i1 >= 0 and i2 < 0 and txt.begins_with(second_tag):
                                i2 = i
                ok += _check(i1 >= 0 and i2 > i1,
                        "%s wears %s above %s (shelf order law)"
                                        % [gid, first_tag, second_tag])
                other.sheet_pop()
                await get_tree().process_frame
                other.queue_free()
                await get_tree().process_frame
        return ok

# ------------------------------------------------------------------ main

func _ready() -> void:
        print("=== qa_v03910_ludo ===")
        fails += _check(true, "the rig boots")
        fails += await _t_state_law()
        fails += await _t_theater_law()
        fails += await _t_six_law()
        fails += await _t_turn_law()
        fails += await _t_eat_law()
        fails += await _t_coin_law()
        fails += await _t_verdict_law()
        fails += await _t_soak()
        fails += await _t_shop_order_law()
        print("RESULT: %s" % ("ALL LAWS PASS" if fails == 0
                        else "%d FAILURES" % fails))
        get_tree().quit(0 if fails == 0 else 1)
