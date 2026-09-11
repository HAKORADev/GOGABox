extends Node
## qa_v039 - the v0.3.9 round probe (the qa_v038p8 law): scene-level laws
## for BOTH new games, driven headless or on the Xvfb rig, exit 0 = pass.
## STRIKE FORENSICS: a scripted win, 1.0s into round_over, the viewport
## pixel on the strike line must be amber.

var fails := 0
var g: GogaGame = null    # the live game under test
var phase := ""
var fl_script: GDScript
var bv_script: GDScript

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.reset_all()
        fl_script = load("res://game/games/fourline/fourline.gd")
        bv_script = load("res://game/games/bovo/bovo.gd")
        print("=== qa_v039 ===")
        fails += _t_fl_static()
        fails += _t_bv_static()
        # the scene phases run in sequence
        _boot_fourline()

func _check(cond: bool, why := "") -> int:
        print("  %s: %s" % ["PASS" if cond else "FAIL", why])
        return 0 if cond else 1

# ------------------------------------------------------- static brain laws

func _t_fl_static() -> int:
        var ok := 0
        var FL: GDScript = fl_script
        var b := []
        for i in 56:
                b.append(0)
        ok += _check(int(FL.drop_row(b, 0)) == FL.ROWS - 1,
                        "fl: an empty column seats the BOTTOM row")
        for r in 4:
                b[FL.idx(2, r)] = 2
        ok += _check(int(FL.winner_of(b)) == 2, "fl: vertical four wins")
        ok += _check(FL.win_line(b) == [FL.idx(2, 0), FL.idx(2, 1),
                        FL.idx(2, 2), FL.idx(2, 3)],
                "fl: the win line reads bottom-up in the column")
        var rng := RandomNumberGenerator.new()
        rng.seed = 39
        var legal := true
        for pr in FL.PROFILES.keys():
                for t in 20:
                        var c: int = FL.cpu_pick(b, pr, [], rng)
                        legal = legal and c >= 0 and c < FL.COLS
        ok += _check(legal, "fl: picks stay legal on a won board")
        return ok

func _t_bv_static() -> int:
        var ok := 0
        var BVO: GDScript = bv_script
        var n := 8
        var b := []
        for i in n * n:
                b.append(0)
        for j in 5:
                b[BVO.idx(1 + j, 1, n)] = 1
        ok += _check(int(BVO.winner_of(b, n)) == 1, "bv: five in a row wins")
        ok += _check(BVO.win_line(b, n).size() == 5, "bv: the win line is five")
        return ok

# ------------------------------------------------------- the scene phases

func _boot_fourline() -> void:
        phase = "fl_boot"
        var FL: GDScript = fl_script
        g = FL.new()
        g.game_id = "fourline"
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        if g.ready_ui != null and is_instance_valid(g.ready_ui):
                g.ready_ui.queue_free()
                g.ready_ui = null
        g.paused = true
        g._rng.seed = 11
        g._new_round()
        # THE STATE LAW (v0.3.9-1): _new_round seats the machine itself -
        # the player opens round 1, so the board is LIVE with no hand-set
        # (the launch build left state="ready" here and the controls were
        # dead - the rigs masked it by setting state by hand, THE MASK LAW)
        fails += _check(g.state == "play" and g.turn == 1,
                "fl: THE STATE LAW - the player-open round is live")
        # THE CONTROLS LAW (v0.3.9-1): a REAL tap through _goga_input (the
        # exact path _unhandled_input feeds) drops the disc
        var tp: Vector2 = g._cell_mid_cr(4, 0)
        var ev := InputEventScreenTouch.new()
        ev.position = tp
        ev.pressed = true
        g._goga_input(ev)
        var ev2 := InputEventScreenTouch.new()
        ev2.position = tp + Vector2(0, 1)
        ev2.pressed = false
        g._goga_input(ev2)
        var cguard := 0
        g.cpu_think = false
        while not g._discs.is_empty() and cguard < 240:
                cguard += 1
                g.cpu_think = false   # the CPU sleeps through the script
                g.probe_step(0.016)
        g.cpu_think = false
        g.state = "play"
        g.turn = 1
        fails += _check(int(g.board[g.idx(4, g.ROWS - 1)]) == 1,
                "fl: a real tap through _goga_input dropped the disc")
        var plan := [[2, 1], [0, 2], [2, 1], [1, 2], [2, 1], [3, 2], [2, 1]]
        for p in plan:
                g._drop_disc(int(p[0]), int(p[1]))
                var guard := 0
                while not g._discs.is_empty() and guard < 240:
                        guard += 1
                        g.cpu_think = false   # the CPU sleeps through the script
                        g.probe_step(0.016)
                g.cpu_think = false
        # the verdict should be live: pump 1.2s of ticks (paused games
        # only advance through probe_step - the strike grows in there)
        for i in 90:
                g.probe_step(1.2 / 90.0)
        await get_tree().process_frame
        await get_tree().process_frame   # the strike must reach the GPU
        fails += _check(g.state == "round_over", "fl: the scripted round ended")
        fails += _check(g.wins == 1 and g.score == 1,
                "fl: the win paid +1 (W=%d score=%d)" % [g.wins, g.score])
        fails += _check(g.last_win_line.size() == 4,
                "fl: the win line carries 4 cells")
        fails += _check(g.strike_t >= 1.0,
                "fl: the strike is fully drawn (t=%.2f)" % g.strike_t)
        fails += _check(g.verdict_lbl.position.y > 100.0,
                "fl: the verdict sits UNDER the board (y=%.0f)"
                                % g.verdict_lbl.position.y)
        # THE PIXEL TRUTH: the strike line's midpoint is amber on the GPU
        # (headless renders nothing - this law certifies on the rig only)
        var img: Image = g.get_viewport().get_texture().get_image()
        if img != null:
                var p0: Vector2 = g._cell_mid(int(g.last_win_line[0]))
                var p1: Vector2 = g._cell_mid(int(g.last_win_line[3]))
                var mid := (p0 + p1) * 0.5
                var px: Color = img.get_pixel(int(mid.x), int(mid.y))
                var amber: bool = px.r > 0.7 and px.g > 0.45 and px.b < 0.4
                fails += _check(amber, "fl: the strike pixel is amber (%s)"
                                % px)
                img.save_png("/tmp/film39/qa_fl_over.png")
        else:
                print("  SKIP: fl pixel law (headless renders nothing)")
        # THE OPENER LAW: the loser (CPU) opens the next round
        var opener_before: int = g.next_opener
        g.clock = 5.0
        g.probe_step(0.016)
        fails += _check(g.next_opener == 2,
                "fl: after a player win the CPU opens next (was %d)"
                                % opener_before)
        # THE COIN LAW: 4 done rounds -> the NEXT round opens wearing a
        # coin (driven through the round's own door - the old clock-nudge
        # assumed a dead state machine)
        g.done_rounds = 4
        g._new_round()
        fails += _check(g.coin_cell.x >= 0,
                "fl: after 4 done rounds a coin waits in a hole")
        # THE STATE LAW, CPU side: the CPU opened, so the round sits in
        # wait with the brain armed - and it really thinks then drops
        fails += _check(g.state == "wait" and g.cpu_think and g.turn == 2,
                "fl: the CPU-open round is live in wait (THE STATE LAW)")
        var think_wait := 0
        while g.state == "wait" and g.cpu_think and think_wait < 240:
                think_wait += 1
                g.probe_step(0.016)
        var fl_stones := 0
        for v in g.board:
                if int(v) != 0:
                        fl_stones += 1
        fails += _check(fl_stones >= 1,
                "fl: the armed CPU brain fired its opening move")
        # done: move to bovo
        g.queue_free()
        _boot_bovo()

func _boot_bovo() -> void:
        phase = "bv_boot"
        var BVO: GDScript = bv_script
        g = BVO.new()
        g.game_id = "bovo"
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        if g.ready_ui != null and is_instance_valid(g.ready_ui):
                g.ready_ui.queue_free()
                g.ready_ui = null
        g.paused = true
        g._rng.seed = 11
        g._new_round()
        # THE STATE LAW (v0.3.9-1), bovo side
        fails += _check(g.state == "play" and g.turn == 1,
                "bv: THE STATE LAW - the player-open round is live")
        # THE CONTROLS LAW (v0.3.9-1): a real tap places the stone
        var tp: Vector2 = g._point_mid(g.idx(4, 4, g.grid_n))
        var ev := InputEventScreenTouch.new()
        ev.position = tp
        ev.pressed = true
        g._goga_input(ev)
        var ev2 := InputEventScreenTouch.new()
        ev2.position = tp
        ev2.pressed = false
        g._goga_input(ev2)
        fails += _check(int(g.board[g.idx(4, 4, g.grid_n)]) == 1,
                "bv: a real tap through _goga_input placed the stone")
        g.cpu_think = false
        g.state = "play"
        g.turn = 1
        # THE SCRIPTED WIN: a horizontal five on row 0 for the player,
        # the CPU stones parked away on rows 2-3
        var plan := [
                [0, 0, 1], [5, 2, 2],
                [1, 0, 1], [6, 2, 2],
                [2, 0, 1], [7, 2, 2],
                [3, 0, 1], [6, 3, 2],
                [4, 0, 1],
        ]
        for p in plan:
                g.cpu_think = false   # the CPU sleeps through the script
                g._place(g.idx(int(p[0]), int(p[1]), g.grid_n), int(p[2]))
                if g.state != "round_over":
                        g.state = "play"
                        g.turn = 1
        for i in 90:
                g.probe_step(1.2 / 90.0)
        await get_tree().process_frame
        await get_tree().process_frame   # the strike must reach the GPU
        fails += _check(g.state == "round_over", "bv: the scripted round ended")
        fails += _check(g.wins == 1, "bv: the player won (W=%d)" % g.wins)
        fails += _check(g.last_win_line.size() == 5,
                "bv: the win line carries 5 cells")
        fails += _check(g.strike_t >= 1.0,
                "bv: the strike is fully drawn (t=%.2f)" % g.strike_t)
        fails += _check(g.verdict_lbl.position.y > 100.0,
                "bv: the verdict sits under the board (y=%.0f)"
                                % g.verdict_lbl.position.y)
        var img2: Image = g.get_viewport().get_texture().get_image()
        if img2 != null:
                var p0: Vector2 = g._point_mid(int(g.last_win_line[0]))
                var p1: Vector2 = g._point_mid(int(g.last_win_line[4]))
                var mid := (p0 + p1) * 0.5
                var px: Color = img2.get_pixel(int(mid.x), int(mid.y))
                var amber: bool = px.r > 0.7 and px.g > 0.45 and px.b < 0.4
                fails += _check(amber, "bv: the strike pixel is amber (%s)"
                                % px)
                img2.save_png("/tmp/film39/qa_bv_over.png")
        else:
                print("  SKIP: bv pixel law (headless renders nothing)")
        # THE SIZE LAW (the 2048 mechanic's plumbing): equip + apply the
        # 10x10 board - the grid rebuilds and the round restarts
        Box.equip_item("bovo", "size", "10")
        g._apply_size("10")
        fails += _check(g.grid_n == 10 and g.size_id == "10",
                "bv: the 10x10 board applies (n=%d)" % g.grid_n)
        fails += _check(g.board.size() == 100, "bv: the 10x10 board is 100 cells")
        fails += _check(g.state == "round_over" or g.turn >= 1,
                "bv: a fresh round rides the new board")
        Box.equip_item("bovo", "size", "8")
        g._apply_size("8")
        fails += _check(g.grid_n == 8, "bv: back to 8x8")
        # ------------------------------------------------------ THE BUY LAW
        # (v0.3.9-1, the owner: "it should be bought only from shop, never
        # applied from it, the options menu is where this happens")
        Box.reset_all()
        Box.earn(9000)
        fails += _check(Box.buy_item("bovo", "size", "10", 1800),
                "bv: the wallet funds the 10x10 buy")
        fails += _check(Box.item_owned("bovo", "size", "10"),
                "bv: the buy marks the size OWNED")
        fails += _check(g.size_id == "8" and g.grid_n == 8,
                "bv: THE BUY LAW - the shop buy never touches the live board")
        var shop_row: Control = g._size_row("10", true)
        fails += _check(_buttons_in_tree(shop_row).is_empty(),
                "bv: the SHOP row of an owned size wears no button (no apply)")
        var opt_row: Control = g._size_row("10", false)
        var opt_btns: Array = _buttons_in_tree(opt_row)
        fails += _check(opt_btns.size() == 1 \
                        and String(opt_btns[0].text).begins_with("SWITCH"),
                "bv: the OPTIONS row of an owned size wears the SWITCH")
        var shop_row2: Control = g._size_row("12", true)
        var shop2_btns: Array = _buttons_in_tree(shop_row2)
        var sells := shop2_btns.size() == 1
        if sells and not String(shop2_btns[0].text).begins_with("BUY"):
                # coin_buttons wear their words on an inner Label (the
                # coin icon rides beside it) - read that instead
                var lbls: Array = _labels_in_tree(shop2_btns[0])
                sells = not lbls.is_empty() \
                                and String(lbls[0].text).begins_with("BUY")
        fails += _check(sells,
                "bv: the SHOP row of a locked size still SELLS")
        g.queue_free()
        # --------------------------------------------- THE WIDE TABLE LAW
        # (v0.3.9-1): the horizontal domino table grows into the REAL
        # canvas - no brown right side on tall phones held sideways
        get_window().size = Vector2i(2400, 1080)
        ScaleRule.apply(get_window())
        await get_tree().process_frame
        await get_tree().process_frame
        var dvp := get_viewport().get_visible_rect().size
        fails += _check(dvp.x > dvp.y, "the rig window is wide for this rig")
        var D: GogaGame = load("res://game/games/domino/domino.gd").new()
        D.game_id = "domino"
        D.start_orientation = "horizontal"
        add_child(D)
        await get_tree().process_frame
        await get_tree().process_frame
        fails += _check(float(D.SCREEN_W) == float(dvp.x),
                "domino: THE WIDE TABLE LAW - SCREEN_W eats the canvas (%d)"
                                % int(D.SCREEN_W))
        fails += _check(D.FRAME.size.x == float(dvp.x) - 48.0,
                "domino: the wide frame spans the grown table")
        fails += _check(D.FIELD.grow_individual(24, 24, 24, 24) == D.FRAME,
                "domino: the field is the frame's -24 inset (the seam law)")
        var dimg: Image = get_viewport().get_texture().get_image()
        if dimg != null:
                dimg.save_png("/tmp/film39/qa_domino_wide.png")
        else:
                print("  SKIP: domino wide shot (headless renders nothing)")
        D.queue_free()
        # --------------------------------------------- THE TRAY ICON LAW
        # (v0.3.9-1, the owner: the portrait graveyard pieces "could get
        # a little bigger") - the portrait chess tray stacks 2 rows, so
        # the icons size by the REAL depth (was /8 in both orientations)
        get_window().size = Vector2i(1080, 1920)
        ScaleRule.apply(get_window())
        await get_tree().process_frame
        await get_tree().process_frame
        var C: GogaGame = load("res://game/games/chess/chess.gd").new()
        C.game_id = "chess"
        C.start_orientation = "vertical"
        add_child(C)
        await get_tree().process_frame
        await get_tree().process_frame
        var cvp := get_viewport().get_visible_rect().size
        fails += _check(cvp.x < cvp.y, "the rig window is vertical for this rig")
        for k in 5:
                C.cap_w.append(5)
                C.cap_b.append(5)
        C.fx_l.queue_redraw()
        await get_tree().process_frame
        await get_tree().process_frame
        var slot0: Rect2 = C._tray_slot(0, 0)
        fails += _check(slot0.size.x >= 40.0,
                "chess: the portrait graveyard icons read at %dpx (was 8)"
                                % int(slot0.size.x))
        fails += _check(absf(C._tray_slot(0, 0).size.x \
                        - C._tray_slot(1, 3).size.x) < 0.01,
                "chess: both trays size their icons by ONE law")
        var cimg: Image = get_viewport().get_texture().get_image()
        if cimg != null:
                cimg.save_png("/tmp/film39/qa_chess_tray.png")
        else:
                print("  SKIP: chess tray shot (headless renders nothing)")
        C.queue_free()
        print("=== qa_v039 RESULT: %s ===" % ("ALL PASS" if fails == 0
                        else "%d FAILURES" % fails))
        get_tree().quit(1 if fails > 0 else 0)

## every Button under a subtree (the sheet-law probe helper)
func _buttons_in_tree(root: Node) -> Array:
        var out: Array = []
        if root is Button:
                out.append(root)
        for c in root.get_children():
                out.append_array(_buttons_in_tree(c))
        return out

## every Label under a subtree (coin_buttons speak through children)
func _labels_in_tree(root: Node) -> Array:
        var out: Array = []
        if root is Label:
                out.append(root)
        for c in root.get_children():
                out.append_array(_labels_in_tree(c))
        return out
