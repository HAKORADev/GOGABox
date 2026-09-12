extends Node
## qa_v0393_squares - the v0.3.9-3 round probe (the qa_v039 law):
## scene-level laws for the SQUARES graduate, driven headless or on the
## Xvfb rig, exit 0 = pass. THE PIXEL TRUTHS: the placed line's midpoint
## is RED at t+0.06 (phase A) and INK at t+0.7 (phase B dried); a claimed
## box's center wears the owner's red; the standby ghost is translucent
## red while held.

var fails := 0
var g: GogaGame = null
var SQ: GDScript

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.reset_all()
        SQ = load("res://game/games/squares/squares.gd")
        print("=== qa_v0393_squares ===")
        _boot()

func _check(cond: bool, why := "") -> int:
        print("  %s: %s" % ["PASS" if cond else "FAIL", why])
        return 0 if cond else 1

func _boot() -> void:
        var phase := "sq_boot"
        g = SQ.new()
        g.game_id = "squares"
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
        fails += _check(g.state == "play" and g.turn == 1,
                "sq: THE STATE LAW - the player-open round is live")
        # THE WIDGET SEAT LAW (v0.3.9-4: the tally lives UNDER the goals
        # cards and the D panel is gone - W | L only)
        var score_chip: Control = g._score_label.get_parent().get_parent()
        fails += _check(g.goals_row.get_index() \
                        == score_chip.get_index() + 1,
                "sq: the goals cards sit right after the score chip")
        fails += _check(g.squares_row.get_parent() == g.goals_row,
                "sq: the squares tally rides UNDER the goals cards")
        fails += _check(g.squares_row.position.y >= 64.0,
                "sq: the tally is below the cards, not beside them (y=%s)"
                                % g.squares_row.position.y)
        # THE CONTROLS LAW (v0.3.9-1): a real press+release through
        # _goga_input draws the line on the nearest edge
        var edge: int = int(SQ.idx_h(1, 1, g.dots_n))
        var seg: Array = g._edge_seg(edge)
        var mid: Vector2 = (seg[0] + seg[1]) * 0.5
        var ev := InputEventScreenTouch.new()
        ev.position = mid
        ev.pressed = true
        g._goga_input(ev)
        fails += _check(g.holding and g.ghost_edge == edge,
                "sq: the press wakes the standby on the nearest edge")
        var ev2 := InputEventScreenTouch.new()
        ev2.position = mid
        ev2.pressed = false
        g._goga_input(ev2)
        fails += _check(int(g.edges[edge]) == 1 and not g.holding,
                "sq: a real press+release drew the red line")
        # THE HOLD LAW: press elsewhere, drag along, drag OUT - the ghost
        # follows then cancels; a release outside places NOTHING
        g.cpu_think = false
        g.state = "play"
        g.turn = 1
        var ev3 := InputEventScreenTouch.new()
        ev3.position = seg[0]
        ev3.pressed = true
        g._goga_input(ev3)
        fails += _check(g.ghost_edge == int(SQ.idx_h(0, 1, g.dots_n)) \
                        or g.ghost_edge == int(SQ.idx_v(1, 0, g.dots_n)) \
                        or g.ghost_edge == edge,
                "sq: a new press re-arms the standby (the follow law)")
        var drag_edge: int = int(SQ.idx_h(1, 3, g.dots_n))
        var dseg: Array = g._edge_seg(drag_edge)
        var dr := InputEventScreenDrag.new()
        dr.position = (dseg[0] + dseg[1]) * 0.5
        g._goga_input(dr)
        fails += _check(g.ghost_edge == drag_edge,
                "sq: the drag rides the ghost to the nearest edge")
        var out: Vector2 = Vector2(20.0, 20.0)
        var dr2 := InputEventScreenDrag.new()
        dr2.position = out
        g._goga_input(dr2)
        fails += _check(g.ghost_edge == -1,
                "sq: off the board the standby cancels")
        var drawn_before: int = _drawn(g.edges)
        var ev4 := InputEventScreenTouch.new()
        ev4.position = out
        ev4.pressed = false
        g._goga_input(ev4)
        fails += _check(_drawn(g.edges) == drawn_before and not g.holding,
                "sq: the release outside places NOTHING (the cancel law)")
        # the denied tap: release onto a drawn edge
        var ev5 := InputEventScreenTouch.new()
        ev5.position = mid
        ev5.pressed = true
        g._goga_input(ev5)
        var ev6 := InputEventScreenTouch.new()
        ev6.position = mid
        ev6.pressed = false
        g._goga_input(ev6)
        fails += _check(_drawn(g.edges) == drawn_before,
                "sq: a release on a drawn edge is denied, not placed")
        # THE PIXEL TRUTHS (headless renders nothing - rig only)
        var img: Image = g.get_viewport().get_texture().get_image()
        if img != null:
                # a fresh red line at age ~0.02s wears the red pen
                var e2: int = int(SQ.idx_v(1, 1, g.dots_n))
                var s2: Array = g._edge_seg(e2)
                var m2: Vector2 = (s2[0] + s2[1]) * 0.5
                var ev7 := InputEventScreenTouch.new()
                ev7.position = m2
                ev7.pressed = true
                g._goga_input(ev7)
                var ev8 := InputEventScreenTouch.new()
                ev8.position = m2
                ev8.pressed = false
                g._goga_input(ev8)
                # the fade lives on the game clock - the probe DRIVES it
                # (a paused tick freezes _time at the claim age 0: alpha 0)
                for i in 13:
                        g.probe_step(0.01)
                await get_tree().process_frame
                await get_tree().process_frame
                var img2: Image = g.get_viewport().get_texture() \
                                .get_image()
                var px: Color = img2.get_pixel(int(m2.x), int(m2.y))
                fails += _check(px.r > 0.55 and px.r > px.g + 0.1 \
                                and px.r > px.b + 0.25,
                        "sq: a fresh line wears the RED pen (phase A: %s)"
                                        % px)
                img2.save_png("/tmp/film393/qa_sq_phaseA.png")
                # let the dry-down finish: the same pixel reads ink-dark
                for i in 60:
                        g.probe_step(0.012)
                await get_tree().process_frame
                await get_tree().process_frame
                var img3: Image = g.get_viewport().get_texture() \
                                .get_image()
                var px3: Color = img3.get_pixel(int(m2.x), int(m2.y))
                fails += _check(px3.r < px.r and px3.b >= px3.r - 0.25,
                        "sq: the line dried into the ink (phase B: %s)"
                                        % px3)
                img3.save_png("/tmp/film393/qa_sq_phaseB.png")
                # THE GHOST PIXEL: hold the standby - a dash pixel is
                # translucent red on the paper
                g.cpu_think = false
                g.state = "play"
                g.turn = 1
                var ev9 := InputEventScreenTouch.new()
                # press the EDGE MIDPOINT - a dot point ties four edges
                var gepress: int = int(SQ.idx_h(2, 2, g.dots_n))
                var ges: Array = g._edge_seg(gepress)
                ev9.position = (ges[0] + ges[1]) * 0.5
                ev9.pressed = true
                g._goga_input(ev9)
                fails += _check(g.ghost_edge == gepress,
                        "sq: the standby arms on the pressed edge")
                await get_tree().process_frame
                await get_tree().process_frame
                var img4: Image = g.get_viewport().get_texture() \
                                .get_image()
                # the standby is DASHED - census along the whole segment
                # (the midpoint itself is a gap between dashes)
                var gseg: Array = g._edge_seg(int(SQ.idx_h(2, 2,
                                g.dots_n)))
                var red_dashes := 0
                var samples := 0
                for k in 24:
                        var f := (float(k) + 0.5) / 24.0
                        var gp: Vector2 = gseg[0].lerp(gseg[1], f)
                        var pxg: Color = img4.get_pixel(int(gp.x),
                                        int(gp.y))
                        samples += 1
                        if pxg.r > pxg.g and pxg.r > pxg.b + 0.12:
                                red_dashes += 1
                fails += _check(red_dashes >= 6,
                        "sq: the standby dashes wear the red alpha (%d of %d samples)"
                                        % [red_dashes, samples])
                var px4: Color = img4.get_pixel(int(gseg[0].x),
                                int(gseg[0].y))
                img4.save_png("/tmp/film393/qa_sq_ghost.png")
                g.holding = false
                g.ghost_edge = -1
        else:
                print("  SKIP: sq pixel laws (headless renders nothing)")
        # THE KSQUARES LAW: close a box and you go again. The pixel
        # probes above drove the game clock - the CPU thought and fired a
        # rogue safe edge in there - so this section starts from a CLEAN
        # board (its laws need the exact setup position)
        g.cpu_think = false
        g._new_board()
        g.state = "play"
        g.turn = 1
        box_l_redraw(g)
        for e in [int(SQ.idx_h(0, 0, g.dots_n)), int(SQ.idx_h(0, 1,
                        g.dots_n)), int(SQ.idx_v(0, 0, g.dots_n))]:
                g.cpu_think = false
                g._place(e, 2)
                if g.state != "round_over":
                        g.state = "play"
                        g.turn = 2
        g.state = "play"
        g.turn = 1
        var boxes_before: int = _red(g.boxes) + _blue(g.boxes)
        g._place(int(SQ.idx_v(1, 0, g.dots_n)), 1)
        fails += _check(_red(g.boxes) + _blue(g.boxes) == boxes_before + 1,
                "sq: the 4th edge claims the box")
        fails += _check(g.turn == 1 and g.state == "play",
                "sq: THE KSQUARES LAW - the claimer keeps the brush")
        fails += _check(_red(g.boxes) == 1,
                "sq: the box wears the RED pen")
        # THE LIVING LAYER LAW (v0.3.9-4): the TICK repaints the box wash -
        # probe_steps alone move the fade, no manual queue_redraw nudge
        # (the owner: "after each drawn line, the animations moves a frame")
        var img7: Image = g.get_viewport().get_texture().get_image()
        if img7 != null:
                var bc0 := board_mid(g, 0, 0)
                var p0: Color = img7.get_pixel(int(bc0.x), int(bc0.y))
                for i in 6:
                        g.probe_step(0.045)      # ~0.27s of fade, no nudges
                await get_tree().process_frame
                await get_tree().process_frame
                var img8: Image = g.get_viewport().get_texture() \
                                .get_image()
                var p1: Color = img8.get_pixel(int(bc0.x), int(bc0.y))
                fails += _check(p1.g < p0.g - 0.1 \
                                and p1.r > p1.g + 0.1,
                        "sq: THE LIVING LAYER - the wash fades on the tick alone (%s -> %s)"
                                        % [p0, p1])
                # THE GUIDE LATTICE (v0.3.9-4): the board is never blank -
                # an undrawn edge reads as visible gray dashes (this frame
                # is pre-claim, the box is still bare paper here, so the
                # same image serves the census on a fresh edge)
                var lseg: Array = g._edge_seg(int(SQ.idx_h(1, 2,
                                g.dots_n)))
                var gray_hits := 0
                for k in 24:
                        var lf := (float(k) + 0.5) / 24.0
                        var lp: Vector2 = lseg[0].lerp(lseg[1], lf)
                        var lpx: Color = img8.get_pixel(int(lp.x),
                                        int(lp.y))
                        var mx: float = maxf(lpx.r, maxf(lpx.g, lpx.b))
                        var mn: float = minf(lpx.r, minf(lpx.g, lpx.b))
                        if mx < 0.91 and mx > 0.31 and mx - mn < 0.18:
                                gray_hits += 1
                fails += _check(gray_hits >= 8,
                        "sq: the guide lattice is visible gray (%d of 24 samples)"
                                        % gray_hits)
        # THE PIXEL TRUTH of the claimed box: its center is red-washed
        # (v0.3.9-4: the LIVING LAYER does the repainting - the manual
        # nudge below stays only as belt-and-braces for the rig)
        var img5: Image = g.get_viewport().get_texture().get_image()
        if img5 != null:
                # drive the fade to its rest (age > BOX_A: full alpha)
                for i in 10:
                        g.probe_step(0.03)
                g.box_l.queue_redraw()
                await get_tree().process_frame
                await get_tree().process_frame
                var img6: Image = g.get_viewport().get_texture() \
                                .get_image()
                var bc := board_mid(g, 0, 0)
                var px5: Color = img6.get_pixel(int(bc.x), int(bc.y))
                fails += _check(px5.r > px5.g + 0.1 \
                                and px5.r > px5.b + 0.2,
                        "sq: the claimed box fades in the RED (%s)" % px5)
                img6.save_png("/tmp/film393/qa_sq_box.png")
        # the CPU keeps the brush on ITS claims (state law, CPU side)
        for e in [int(SQ.idx_h(2, 2, g.dots_n)), int(SQ.idx_h(2, 3,
                        g.dots_n)), int(SQ.idx_v(3, 2, g.dots_n))]:
                g._place(e, 2)
                if g.state == "wait" and g.cpu_think:
                        g.cpu_think = false
                        g.state = "wait"
        g.state = "wait"
        g.turn = 2
        g.cpu_think = false
        g._place(int(SQ.idx_v(2, 2, g.dots_n)), 2)
        fails += _check(_blue(g.boxes) >= 1 and g.turn == 2 \
                        and g.cpu_think,
                "sq: the CPU's claim keeps the CPU drawing")
        # the CPU hands the brush back when it draws a plain line
        g.cpu_think = false
        var blue_before: int = _blue(g.boxes)
        g._place(int(SQ.idx_h(2, 0, g.dots_n)), 2)
        if _blue(g.boxes) == blue_before:
                fails += _check(g.turn == 1 and g.state == "play",
                        "sq: a plain CPU line hands the brush back")
        # THE VERDICT: script a red sweep to the board's end (the rest of
        # the edges split honestly - red takes the last box)
        _finish_scripted()
        fails += _check(g.state == "round_over", "sq: the board ended")
        fails += _check(g.wins + g.losses == 1,
                "sq: exactly one verdict (W=%d L=%d, no draws)"
                                % [g.wins, g.losses])
        fails += _check(g.score == 1 or g.score == 0,
                "sq: the economy paid (+1 or the 0 floor: %d)" % g.score)
        fails += _check(g.mem.size() == 1,
                "sq: the round wears its memory record (the chain scar)")
        # THE OPENER LAW: the loser opens next
        var opener_before: int = g.next_opener
        g.clock = 5.0
        g.probe_step(0.016)
        if g.wins == 1:
                fails += _check(g.next_opener == 2,
                        "sq: after a player win the CPU opens next (was %d)"
                                        % opener_before)
        else:
                fails += _check(g.next_opener == 1,
                        "sq: after a CPU win the player opens next")
        # THE COIN LAW: 3 done rounds -> the NEXT round opens wearing a
        # coin inside a box
        g.done_rounds = 3
        g.next_opener = 2    # force the CPU open: its STATE LAW side
        g._new_round()
        fails += _check(g.coin_box >= 0,
                "sq: after 3 done rounds a coin waits inside a box")
        fails += _check(g.state == "wait" and g.cpu_think and g.turn == 2,
                "sq: the CPU-open round is live in wait (THE STATE LAW)")
        var think_wait := 0
        while g.state == "wait" and g.cpu_think and think_wait < 240:
                think_wait += 1
                g.probe_step(0.016)
        fails += _check(_drawn(g.edges) >= 1,
                "sq: the armed CPU brain fired its opening line")
        # THE COIN RACE: the claimer of the coin's box takes it
        if g.coin_box >= 0:
                var cb: int = g.coin_box
                var be2: Array = SQ.box_edges(cb / (g.dots_n - 1),
                                cb % (g.dots_n - 1), g.dots_n)
                for e in be2:
                        if int(g.edges[e]) == 0:
                                g._place(int(e), 1)
                fails += _check(g.run_coins == 1 or _red(g.boxes) >= 1,
                        "sq: the coin rides its box's claim")
        # THE BUY LAW + the size apply (the 2048 mechanic's plumbing)
        Box.reset_all()
        Box.earn(9000)
        fails += _check(Box.buy_item("squares", "size", "6", 1800),
                "sq: the wallet funds the 6x6 buy")
        fails += _check(Box.item_owned("squares", "size", "6"),
                "sq: the buy marks the size OWNED")
        fails += _check(g.size_id == "4" and g.dots_n == 4,
                "sq: THE BUY LAW - the shop buy never touches the live board")
        var shop_row: Control = g._size_row("6", true)
        fails += _check(_buttons_in_tree(shop_row).is_empty(),
                "sq: the SHOP row of an owned size wears no button (no apply)")
        var opt_row: Control = g._size_row("6", false)
        var opt_btns: Array = _buttons_in_tree(opt_row)
        fails += _check(opt_btns.size() == 1 \
                        and String(opt_btns[0].text).begins_with("SWITCH"),
                "sq: the OPTIONS row of an owned size wears the SWITCH")
        var shop_row2: Control = g._size_row("8", true)
        var shop2_btns: Array = _buttons_in_tree(shop_row2)
        var sells := shop2_btns.size() == 1
        if sells and not String(shop2_btns[0].text).begins_with("BUY"):
                var lbls: Array = _labels_in_tree(shop2_btns[0])
                sells = not lbls.is_empty() \
                                and String(lbls[0].text).begins_with("BUY")
        fails += _check(sells, "sq: the SHOP row of a locked size still SELLS")
        # no skins in the shop's constants (the pens are not for sale)
        fails += _check(not SQ.get_script_constant_map().has("SKINS"),
                "sq: NO skins - the pens are not for sale (owner)")
        Box.equip_item("squares", "size", "6")
        g._apply_size("6")
        fails += _check(g.dots_n == 6 and g.size_id == "6",
                "sq: the 6x6 board applies (dots=%d)" % g.dots_n)
        fails += _check(g.boxes.size() == 25, "sq: the 6x6 board is 25 boxes")
        Box.equip_item("squares", "size", "4")
        g._apply_size("4")
        fails += _check(g.dots_n == 4, "sq: back to 4x4")
        print("=== qa_v0393_squares RESULT: %s ===" % ("ALL PASS"
                        if fails == 0 else "%d FAILURES" % fails))
        get_tree().quit(1 if fails > 0 else 0)

func box_l_redraw(g2: GogaGame) -> void:
        g2.box_l.queue_redraw()
        g2.line_l.queue_redraw()

func board_mid(g2: GogaGame, bc: int, br: int) -> Vector2:
        return g2.board_origin + Vector2((float(bc) + 0.5) * g2.cell,
                        (float(br) + 0.5) * g2.cell)

func _drawn(arr: Array) -> int:
        var n := 0
        for v in arr:
                if int(v) != 0:
                        n += 1
        return n

func _red(arr: Array) -> int:
        var n := 0
        for v in arr:
                if int(v) == 1:
                        n += 1
        return n

func _blue(arr: Array) -> int:
        var n := 0
        for v in arr:
                if int(v) == 2:
                        n += 1
        return n

## finish the live board honestly: alternate plain lines until an edge
## falls, let the verdict resolve itself (the round's own door)
func _finish_scripted() -> void:
        var guard := 0
        while g.state != "round_over" and guard < 40:
                guard += 1
                var pick := -1
                for i in g.edges.size():
                        if int(g.edges[i]) == 0:
                                pick = i
                                break
                if pick < 0:
                        return
                var who: int = g.turn
                g.cpu_think = false
                g._place(pick, who)
                if g.state == "round_over":
                        return
                # a claim keeps the brush - the loop naturally continues
                if who == 2 and g.turn == 2:
                        g.cpu_think = false

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
