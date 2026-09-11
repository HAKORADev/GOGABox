extends Node
## qa_v0392_domino - THE CHAIN-HONESTY RIG (v0.3.9-2): the owner reported
## the dominoes board "+3 logical bugs ... connects in the wrong direction
## using wrong position using wrong calculations for legibility". This rig
## plays REAL plies through the game's own doors, past the serpentine
## corners, on BOTH tables, and after every placement runs THE
## CHAIN-HONESTY CHECK (AGENTS.md law #6): for every consecutive pair the
## values the RENDERER actually paints at the touching edges must match.
## It photographs the table at every checkpoint so the eye can confirm.
## Exit 0 = the chain reads honest.

var fails := 0
var dir := "/tmp/film392"
var g: GogaGame = null
var shots := {}

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        DirAccess.make_dir_recursive_absolute(dir)
        print("=== qa_v0392_domino ===")
        var only := OS.get_environment("RIG_ORIENT")
        if only == "" or only == "vertical":
                await _run("vertical")
        if only == "" or only == "horizontal":
                await _run("horizontal")
        print("=== qa_v0392_domino RESULT: %s ===" % ("ALL PASS" if fails == 0
                                        else "%d FAILURES" % fails))
        get_tree().quit(1 if fails > 0 else 0)

func _ck(cond: bool, why: String) -> void:
        print("  %s: %s" % ["PASS" if cond else "FAIL", why])
        if not cond:
                fails += 1

func _wait(t: float) -> void:
        await get_tree().create_timer(t).timeout

func _shot(name: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        var img: Image = get_viewport().get_texture().get_image()
        if img != null:
                img.save_png("%s/%s.png" % [dir, name])

func _run(orient: String) -> void:
        print("== TABLE: %s ==" % orient.to_upper())
        Box.reset_all()
        if orient == "horizontal":
                get_window().size = Vector2i(2400, 1080)
        else:
                get_window().size = Vector2i(1080, 1920)
        ScaleRule.apply(get_window())
        await _wait(0.2)
        g = load("res://game/games/domino/domino.gd").new()
        g.game_id = "domino"
        g.start_orientation = orient
        ScaleRule.apply(get_window())
        add_child(g)
        await _wait(0.3)
        g.probe_reset(11)
        await _wait(0.3)

        # THE PLAN: grow both cursors evenly so both sides cross ROW_MAX and
        # bend. Stop conditions: target chain, hand dry, blocked, or round over.
        var target: int = 14 if orient == "vertical" else 26
        var ply := 0
        var shot_at := {1: "first", 6: "six", 7: "corner", target: "final"}
        # vertical: corner lands as the 6th tile of a side; grab chain shots at
        # 7 (first bend just made) and the target.
        shot_at = {1: "c1", 6: "c6", 7: "c7", target: "cfinal"}
        while g.chain.size() < target and g.state != "round_over":
                if g.turn != g.P or g.state != "play":
                        g.probe_step(0.05)
                        await _wait(0.05)
                        continue
                var e: Vector2i = g.ends(g.chain)
                var opts: Array = g.playable(g.hand_p, e.x, e.y)
                if g.opening:
                        var hi := 0
                        for i in g.hand_p.size():
                                if g._is_opener(i):
                                        hi = i
                                        break
                        g._place(g.P, hi, 2)
                elif opts.is_empty():
                        if g.deck.size() > 0:
                                g._draw_tile(g.P)
                        else:
                                g._pass(g.P)
                else:
                        # balance: prefer the side holding fewer tiles
                        var n_l := 0
                        var n_r := 0
                        for t in g.chain:
                                if t.get("px", 0.0) < g._chain_area().get_center().x:
                                        n_l += 1
                                else:
                                        n_r += 1
                        var pick: int = -1
                        var side := 0
                        for want in [1 if n_l <= n_r else 2, 2 if want_ordered(1) else 1]:
                                pass
                        # try balanced side first, then any fitting side
                        var pref := 1 if n_l <= n_r else 2
                        for i in opts:
                                var cp: int = g.can_play(g.hand_p[i], e.x, e.y)
                                if (cp & (1 if pref == 1 else 2)) != 0:
                                        pick = i
                                        side = pref
                                        break
                        if pick < 0:
                                for i2 in opts:
                                        var cp2: int = g.can_play(g.hand_p[i2], e.x, e.y)
                                        if cp2 != 0:
                                                pick = i2
                                                side = 1 if (cp2 & 1) != 0 else 2
                                                break
                        if pick < 0:
                                break
                        g._place(g.P, pick, side)
                ply += 1
                # let every flight land (the CPU's next think may fire inside these
                # steps - keep draining until the air is clean), then settle + CHECK
                var drain := 0
                while g.flies.size() > 0 and drain < 40:
                        g.probe_step(0.3)
                        drain += 1
                g._settle_glide()
                # THE IDENTITY LAW: every tile placed must have landed - an unpainted
                # entry is a tile the owner never sees (the index-shift vanish)
                var unpainted := 0
                for t4 in g.chain:
                        if not bool(t4.get("landed", false)):
                                unpainted += 1
                if unpainted > 0:
                        for t5 in g.chain:
                                if not bool(t5.get("landed", false)):
                                        _ck(false, "ply %d: NEVER painted [%d|%d] pid=%d who=%s idx=%d"
                                                                        % [ply, int(t5["a"]), int(t5["b"]),
                                                                        int(t5.get("pid", -1)), str(t5.get("who", "?")),
                                                                        g.chain.find(t5)])
                                        break
                var bad: Array = _honesty_check()
                if not bad.is_empty():
                        for b in bad:
                                _ck(false, "ply %d chain %d: %s" % [ply, g.chain.size(), b])
                if shot_at.has(g.chain.size()):
                        await _shot("%s_%s" % [orient.substr(0, 1), shot_at[g.chain.size()]])
                await _wait(0.05)
        # the turn-wait steps may have launched one last flight - drain the air
        # before any final truth
        var drain2 := 0
        while g.flies.size() > 0 and drain2 < 40:
                g.probe_step(0.3)
                drain2 += 1
        g._settle_glide()
        await _shot("%s_end" % orient.substr(0, 1))
        # state truth at exit
        var fl_dump := ""
        for f in g.flies:
                fl_dump += "(%s t=%.2f pid=%s) " % [str(f.get("kind", "?")),
                                                float(f.get("t", 0.0)), str(f.get("pid", "?"))]
        print("  [dbg2] state=%s flies=%d [%s]" % [g.state, g.flies.size(), fl_dump])
        for i in g.chain.size():
                if not bool(g.chain[i].get("landed", false)):
                        print("  [dbg2] UNPAINTED i=%d [%d|%d] pid=%s who=%s px=%s has_px=%s"
                                                        % [i, int(g.chain[i]["a"]), int(g.chain[i]["b"]),
                                                        str(g.chain[i].get("pid", "?")),
                                                        str(g.chain[i].get("who", "?")),
                                                        str(g.chain[i].get("px", "?")),
                                                        str(g.chain[i].has("px"))])
        # pixel-truth: where does the renderer think each tile sits, and are
        # there really white tile pixels there?
        for i in g.chain.size():
                var cr: Dictionary = g.chain_rects[i]
                var rr: Rect2 = cr["rect"]
                var img2: Image = get_viewport().get_texture().get_image()
                var cx := int(rr.get_center().x)
                var cy := int(rr.get_center().y)
                var bright := 0
                if img2 != null and Rect2(Vector2.ZERO, Vector2(img2.get_width(),
                                                img2.get_height())).has_point(Vector2(cx, cy)):
                        for ox in range(-int(rr.size.x * 0.3), int(rr.size.x * 0.3), 4):
                                for oy in range(-int(rr.size.y * 0.3), int(rr.size.y * 0.3), 4):
                                        var c := img2.get_pixel(cx + ox, cy + oy)
                                        if c.r > 0.75 and c.g > 0.75 and c.b > 0.75:
                                                bright += 1
                print("  [px] i=%d [%d|%d] landed=%s rect=%s bright=%d"
                                                % [i, int(g.chain[i]["a"]), int(g.chain[i]["b"]),
                                                str(bool(g.chain[i].get("landed", false))),
                                                str(rr), bright])
        var total_bad: Array = _honesty_check()
        if total_bad.is_empty() and fails == 0:
                _ck(true, "%s: the whole %d-tile chain reads honest" % [orient,
                                                g.chain.size()])
        # dump the final poses for the record
        var dump := ""
        for t3 in g.chain:
                dump += "[%d|%d f=%s px=%.0f py=%.0f v=%s] " % [int(t3["a"]),
                                                int(t3["b"]), str(t3.get("fl")), float(t3.get("px", -1)),
                                                float(t3.get("py", -1)), str(t3.get("pv", "?"))]
        print("  poses: ", dump)

func want_ordered(_x: int) -> bool:
        return false

## THE CHAIN-HONESTY CHECK - mirrors the renderer's painted truth:
## a LYING tile paints [lo | hi] left->right (the lo-hi face tipped -90deg),
## a STANDING tile paints [lo / hi] top->bottom. For every consecutive pair,
## the values at the touching edges must match:
##   lying-lying   : near halves equal
##   lying-standing: the lying tile's near half == the standing TOP half
##   standing-lying: the standing BOTTOM half == the lying tile's near half
func _honesty_check() -> Array:
        var out: Array = []
        for i in range(g.chain.size() - 1):
                var A: Dictionary = g.chain[i]
                var B: Dictionary = g.chain[i + 1]
                if not A.has("px") or not B.has("px"):
                        continue
                var ra: Rect2 = g._pose_rect_pv(Vector2(A["px"], A["py"]), bool(A.get("pv", false)))
                var rb: Rect2 = g._pose_rect_pv(Vector2(B["px"], B["py"]), bool(B.get("pv", false)))
                var va: Array = _painted_halves(A)
                var vb: Array = _painted_halves(B)
                var av: bool = bool(A.get("pv", false))
                var bv: bool = bool(B.get("pv", false))
                if not av and not bv:
                        # near halves across the vertical contact
                        var b_right: bool = rb.get_center().x > ra.get_center().x
                        var a_half: int = va[1] if b_right else va[0]
                        var b_half: int = vb[0] if b_right else vb[1]
                        if a_half != b_half:
                                out.append("pair %d-%d tiles [%d|%d]->[%d|%d]: edge shows %d vs %d"
                                                                % [i, i + 1, int(A["a"]), int(A["b"]), int(B["a"]),
                                                                int(B["b"]), a_half, b_half])
                elif not av and bv:
                        # lying -> standing corner: its TOP half must meet the open value
                        var a_half2: int = va[1] if rb.get_center().x > ra.get_center().x \
                                                        else va[0]
                        if a_half2 != vb[0]:
                                out.append("pair %d-%d into corner: edge shows %d vs corner top %d"
                                                                % [i, i + 1, a_half2, vb[0]])
                else:
                        # standing corner -> the return row: corner BOTTOM half leads
                        var b_half2: int = vb[0] if rb.get_center().x > ra.get_center().x \
                                                        else vb[1]
                        if va[1] != b_half2:
                                out.append("pair %d-%d out of corner: corner bottom %d vs edge %d"
                                                                % [i, i + 1, va[1], b_half2])
        return out

## what the renderer ACTUALLY paints: [left_or_top, right_or_bottom]
## v0.3.9-2 THE FLOW LAW mirror: a lying tile paints [touch | open] along
## pdx; a standing corner paints [touch / open] top->bottom.
func _painted_halves(t: Dictionary) -> Array:
        var tv: int = int(t.get("tv", int(t["a"])))
        var ov: int = int(t.get("ov", int(t["b"])))
        if bool(t.get("pv", false)):
                return [tv, ov]
        if float(t.get("pdx", 1.0)) < 0.0:
                return [ov, tv]
        return [tv, ov]
