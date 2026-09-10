#!/usr/bin/env python3
"""v038p5_chess_patch.py - applies the v0.3.8-5 CHECKMATE upgrades to
game/games/chess/chess.gd (the owner's patch-5 list). Idempotent: exits 0
without touching the file when the first marker is already present."""

import re
import sys

PATH = "projects/gogabox/game/games/chess/chess.gd"
src = open(PATH).read()
if "v0.3.8-5" in src:
    print("already patched")
    sys.exit(0)
n0 = src


def rep(old, new, count=1):
    global src
    assert src.count(old) >= count, f"NOT FOUND: {old[:90]!r}"
    src = src.replace(old, new, count)


# ------------------------------------------------ 1. vars: strip -> goals
rep("""var strip_l: Node2D
""", """var goals_row: HBoxContainer  # v0.3.8-5: the W-D-L row, top right
var goal_lbls: Array = []
""")
rep("""# v0.3.8-1 THE DEAD TRAY: every piece that left the war, split by captor
var cap_w: Array = []
var cap_b: Array = []
""", """# v0.3.8-1 THE DEAD TRAY: every piece that left the war, split by captor
var cap_w: Array = []
var cap_b: Array = []
# v0.3.8-5 THE CAPTURE THEATER: the fallen piece FLIES to its tray
# [{side, idx, sq, v, t, dur}] - no more vanish-then-teleport
var cap_q: Array = []
""")

# --------------------------------------- 2. setup: parlor bg + music + btn
rep("""        var vp := get_viewport_rect().size
        world = Node2D.new()
        add_child(world)
        board_l = Node2D.new()
""", """        var vp := get_viewport_rect().size
        world = Node2D.new()
        add_child(world)
        # v0.3.8-5 THE PARLOR: the wood room behind the war (the studied
        # reference's mood - drawn by our own hand, tools/v038p5_chess_art.py)
        bg_l = Node2D.new()
        bg_l.draw.connect(_draw_bg)
        world.add_child(bg_l)
        board_l = Node2D.new()
""")
rep("""        _layout(vp)
        _build_widgets(vp)
        _load_meta()
        add_hud_button("SHOP", func(): _shop_open())
        add_hud_button("OPTIONALS", func(): _pick_open(false))
        _build_ready()
""", """        _layout(vp)
        _build_widgets(vp)
        _load_meta()
        add_hud_button("SHOP", func(): _shop_open())
        # v0.3.8-5 (the owner): the OPTIONALS button is OUT of the game
        # scene - the color shelf is reached from the ready screen (the
        # first tap) and from the optionals flow itself
        Jukebox.music("res://assets/audio/music/c_theme.ogg")
        _build_ready()
""")
rep("""var world: Node2D
var board_l: Node2D
""", """var world: Node2D
var bg_l: Node2D
var board_l: Node2D
""")

# --------------------------------------------- 3. the parlor room drawing
rep("""func _sq_rect(i: int) -> Rect2:""", """func _draw_bg() -> void:
        var vp := get_viewport_rect().size
        var tex: Texture2D = load("res://assets/games/chess/bg_wood_p.png") \\
                if vp.x <= vp.y \\
                else load("res://assets/games/chess/bg_wood_l.png")
        var s: float = maxf(vp.x / tex.get_width(),
                vp.y / tex.get_height())
        var sz := Vector2(tex.get_width(), tex.get_height()) * s
        bg_l.draw_texture_rect(tex, Rect2(-Vector2(sz.x - vp.x,
                sz.y - vp.y) * 0.5, sz), false)

func _sq_rect(i: int) -> Rect2:""")

# ------------------------------------------- 4. widgets: the W-D-L row
rep("""func _build_widgets(vp: Vector2) -> void:
        # v0.3.8-1 THE NEW FRAME: the old horizontal 3-box row, the turn text
        # and the moves logger are gone. The score lives in a small VERTICAL
        # strip cut on the LEFT of the board; the dead pieces live in a
        # vertical tray cut on the RIGHT (two lines - one per color); the
        # turn speaks through the side-to-move's KING alone (drawn in fx).
        var strip := Node2D.new()
        strip_l = strip
        strip.draw.connect(_draw_strip)
        world.add_child(strip)
        you_lbl = Arc.label("0", 30, Color("2f7a44"))
        draw_lbl = Arc.label("0", 30, Color("4b5563"))
        cpu_lbl = Arc.label("0", 30, Color("9c3a32"))
        for l in [you_lbl, draw_lbl, cpu_lbl]:
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                world.add_child(l)
        verdict_lbl = Arc.label("", 30, Color(1, 1, 1, 0.95))
        verdict_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        verdict_lbl.visible = false
        world.add_child(verdict_lbl)
        _refresh_widget()

## the score strip geometry: three stacked boxes in the LEFT cut
func _strip_rects() -> Array:
        var vp := get_viewport_rect().size
        var mid := Vector2(board_origin.x * 0.5,
                board_origin.y + sq_px * 4.0)
        var bw := minf(128.0, board_origin.x - 24.0)
        var bh := 74.0
        var gap := 18.0
        return [mid, bw, bh, gap]

func _draw_strip() -> void:
        if board_origin == Vector2.ZERO or strip_l == null:
                return
        var geo := _strip_rects()
        var mid: Vector2 = geo[0]
        var bw: float = geo[1]
        var bh: float = geo[2]
        var gap: float = geo[3]
        var boxes := [
                [-(bh + gap) - bh / 2.0, Color("58c470"), Color("2f7a44")],
                [-bh / 2.0, Color("6b7280"), Color("4b5563")],
                [(bh + gap) - bh / 2.0, Color("e8574a"), Color("9c3a32")],
        ]
        for b in boxes:
                var cy: float = b[0]
                var col: Color = b[1]
                var r := Rect2(mid.x - bw / 2.0, mid.y + cy, bw, bh)
                strip_l.draw_rect(Rect2(r.position + Vector2(5, 5), r.size),
                        Color(0.09, 0.05, 0.02, 0.85))
                strip_l.draw_rect(r, Color(1, 1, 1, 0.95))
                strip_l.draw_rect(r, col, false, 4.0)

func _refresh_widget() -> void:
        if board_origin == Vector2.ZERO:
                return
        var geo := _strip_rects()
        var mid: Vector2 = geo[0]
        var bw: float = geo[1]
        var bh: float = geo[2]
        var gap: float = geo[3]
        var ys := [-(bh + gap) - bh / 2.0, -bh / 2.0, (bh + gap) - bh / 2.0]
        var labels := [you_lbl, draw_lbl, cpu_lbl]
        var texts := ["YOU\\n%d" % wins, "DRAWS\\n%d" % draws, "CPU\\n%d" % losses]
        for i in 3:
                var t: Label = labels[i]
                t.text = texts[i]
                t.add_theme_font_size_override("font_size", 22)
                t.position = Vector2(mid.x - bw / 2.0, mid.y + ys[i] + 8.0)
                t.custom_minimum_size = Vector2(bw, bh - 16.0)
        # the verdict sits under the board's bottom edge, board-wide
        verdict_lbl.position = Vector2(board_origin.x,
                board_origin.y + sq_px * 8.0 + 14.0)
        verdict_lbl.custom_minimum_size = Vector2(sq_px * 8.0, 44.0)
""", """func _build_widgets(vp: Vector2) -> void:
        # v0.3.8-5 THE GOALS ROW (the owner: "make the goals of cpu, you,
        # draw to be as the old way at the top right next to the score
        # widget i mean horizontal"): three chips pinned under the HUD bar
        # at the RIGHT edge - the v0.3.8-1 left vertical strip is retired.
        # The dead pieces live in two parchment trays flanking the board
        # (the studied reference's room); the turn still speaks through the
        # side-to-move's KING alone (drawn in fx).
        goals_row = HBoxContainer.new()
        goals_row.add_theme_constant_override("separation", 10)
        goals_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
        goals_row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
        goals_row.offset_left = -620.0
        goals_row.offset_right = -16.0
        goals_row.offset_top = 76.0
        goals_row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
        _overlay_root.add_child(goals_row)
        goal_lbls = []
        for pair in [["YOU", Color("2f7a44")], ["DRAW", Color("4b5563")],
                ["CPU", Color("9c3a32")]]:
                var chip := Arc.chip("0", "", Color(0, 0, 0, 0.35), 22,
                        Arc.CARD)
                chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
                goals_row.add_child(chip)
                var l: Label = chip.get_child(0).get_child(
                        chip.get_child(0).get_child_count() - 1)
                l.text = "%s 0" % pair[0]
                goal_lbls.append(l)
        verdict_lbl = Arc.label("", 30, Color(1, 1, 1, 0.95))
        verdict_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        verdict_lbl.visible = false
        world.add_child(verdict_lbl)
        _refresh_widget()

func _refresh_widget() -> void:
        if board_origin == Vector2.ZERO:
                return
        var texts := ["YOU %d" % wins, "DRAW %d" % draws, "CPU %d" % losses]
        for i in 3:
                var t: Label = goal_lbls[i]
                t.text = texts[i]
        # the verdict sits under the board's bottom edge, board-wide
        verdict_lbl.position = Vector2(board_origin.x,
                board_origin.y + sq_px * 8.0 + 14.0)
        verdict_lbl.custom_minimum_size = Vector2(sq_px * 8.0, 44.0)
""")

# ------------------------------------- 5. board draw: colors + red targets
rep("""            # the last-move tint
            if i == int(last_move["f"]) or i == int(last_move["t"]):
                    board_l.draw_rect(rect, Color(1.0, 0.9, 0.3, 0.22))
""", """            # v0.3.8-5 THE TWO-COLOR TRUTH (the owner: "let the A as is
            # yellow but make the B be green instead of yellow so it be
            # more visible"): the origin keeps the yellow tint, the
            # destination wears the green
            if i == int(last_move["f"]):
                    board_l.draw_rect(rect, Color(1.0, 0.9, 0.3, 0.22))
            elif i == int(last_move["t"]):
                    board_l.draw_rect(rect, Color(0.30, 0.85, 0.42, 0.30))
""")
rep("""                for m in legal_cache:
                        var rt := _sq_rect(int(m["t"]))
                        if int(st["b"][m["t"]]) != 0 or m["flag"] == "ep":
                                board_l.draw_rect(rt.grow(-3.0),
                                        Color(0.95, 0.5, 0.3, 0.5 * pulse2),
                                        false, 5.0)
""", """                for m in legal_cache:
                        var rt := _sq_rect(int(m["t"]))
                        if int(st["b"][m["t"]]) != 0 or m["flag"] == "ep":
                                # v0.3.8-5 THE RED TRUTH (the owner: "make
                                # that other chess square where it is be
                                # outlined with red ... currently i guess it
                                # draws the gray circle under the chess and
                                # it's invisible"): a warm fill + a BOLD red
                                # line around the whole square - the enemy
                                # piece sits INSIDE the warning now
                                board_l.draw_rect(rt,
                                        Color(0.9, 0.2, 0.12, 0.16))
                                board_l.draw_rect(rt.grow(-2.0),
                                        Color(0.95, 0.20, 0.12,
                                                0.55 + 0.4 * pulse2),
                                        false, 7.0)
""")

# ------------------------------------- 6. trays: parchment, both flanks
rep("""## v0.3.8-1 THE DEAD TRAY: the vertical cut on the right - two lines, one
## per color, each carrying the pieces THAT color took off the board.
func _tray_rects() -> Array:
        var vp := get_viewport_rect().size
        var x0 := board_origin.x + sq_px * 8.0 + 14.0
        var x1 := vp.x - 14.0
        var y0 := board_origin.y
        var y1 := board_origin.y + sq_px * 8.0
        var mid_y := (y0 + y1) * 0.5
        return [Rect2(x0, y0 + 6.0, x1 - x0, mid_y - y0 - 12.0),
                Rect2(x0, mid_y + 6.0, x1 - x0, y1 - mid_y - 12.0)]
""", """## v0.3.8-1 THE DEAD TRAY -> v0.3.8-5 THE TWO TRAYS (the studied
## reference's room): parchment trays flanking the board - the player's
## pile LEFT, the CPU's pile RIGHT, each carrying the pieces that captor
## took off the board.
func _tray_rects() -> Array:
        var vp := get_viewport_rect().size
        var y0 := board_origin.y
        var y1 := board_origin.y + sq_px * 8.0
        var mid_y := (y0 + y1) * 0.5
        var lx1 := board_origin.x - 14.0
        var rx0 := board_origin.x + sq_px * 8.0 + 14.0
        return [Rect2(14.0, y0 + 6.0, maxf(60.0, lx1 - 14.0),
                        mid_y - y0 - 12.0),
                Rect2(rx0, y0 + 6.0, maxf(60.0, vp.x - 14.0 - rx0),
                        y1 - mid_y - 12.0)]
""")

rep("""        var trays := _tray_rects()
        var caps := [cap_w, cap_b]
        var cols := [Color(0.92, 0.9, 0.84, 0.9), Color(0.25, 0.22, 0.2, 0.9)]
        var kings := ["w", "b"]
        for side in 2:
                var r: Rect2 = trays[side]
                fx_l.draw_rect(Rect2(r.position + Vector2(4, 4), r.size),
                        Color(0.09, 0.05, 0.02, 0.6))
                fx_l.draw_rect(r, Color(0.14, 0.09, 0.05, 0.72))
                fx_l.draw_rect(r, cols[side], false, 3.0)
""", """        var trays := _tray_rects()
        var caps := [cap_w, cap_b]
        var cols := [Color(0.36, 0.27, 0.16), Color(0.36, 0.27, 0.16)]
        var kings := ["w", "b"]
        for side in 2:
                var r: Rect2 = trays[side]
                # v0.3.8-5 THE PARCHMENT TRAY (the reference's room): warm
                # parchment body, deep-brown edge, a soft drop and a top
                # inner shade - the fallen pieces read on it instantly
                fx_l.draw_rect(Rect2(r.position + Vector2(5, 5), r.size),
                        Color(0.09, 0.05, 0.02, 0.5))
                fx_l.draw_rect(r, Color(0.906, 0.847, 0.686, 0.97))
                fx_l.draw_rect(r, cols[side], false, 4.0)
                fx_l.draw_rect(Rect2(r.position,
                        Vector2(r.size.x, 9.0)), Color(0, 0, 0, 0.08))
""")

rep("""                # the dead pieces, wrapped rows starting right of the king
                var dead: Array = caps[side]
                if dead.is_empty():
                        continue
                var ic := minf(44.0, (r.size.x - kis - 26.0) / 4.0)
                var per_row := maxi(1, int((r.size.x - kis - 24.0) / ic))
                var row := Rect2(r.position.x + kis + 14.0, 0.0, ic, ic)
                for i in dead.size():
                        var di := i / per_row
                        var dc := i % per_row
                        var dtex := _piece_tex(int(dead[i]))
                        var dr := Rect2(
                                row.position.x + dc * (ic + 2.0),
                                r.get_center().y - (ic + 3.0) * 0.5
                                        + di * (ic + 3.0), ic, ic)
                        fx_l.draw_texture_rect(dtex, dr, false,
                                Color(1, 1, 1, 0.92))
""", """                # the dead pieces, wrapped rows starting right of the king
                # (the ones still FLYING sit out - the theater draws them)
                var dead: Array = caps[side]
                if dead.is_empty():
                        continue
                var ic := minf(44.0, (r.size.x - kis - 26.0) / 4.0)
                var per_row := maxi(1, int((r.size.x - kis - 24.0) / ic))
                var row := Rect2(r.position.x + kis + 14.0, 0.0, ic, ic)
                for i in dead.size():
                        if _cap_flying(side, i):
                                continue
                        var di := i / per_row
                        var dc := i % per_row
                        var dtex := _piece_tex(int(dead[i]))
                        var dr := Rect2(
                                row.position.x + dc * (ic + 2.0),
                                r.get_center().y - (ic + 3.0) * 0.5
                                        + di * (ic + 3.0), ic, ic)
                        fx_l.draw_texture_rect(dtex, dr, false,
                                Color(1, 1, 1, 0.92))

## the slot a fallen piece lands in (the theater's landing pad)
func _tray_slot(side: int, idx: int) -> Rect2:
        var r: Rect2 = _tray_rects()[side]
        var kis := minf(r.size.y - 18.0, 58.0)
        var ic := minf(44.0, (r.size.x - kis - 26.0) / 4.0)
        var per_row := maxi(1, int((r.size.x - kis - 24.0) / ic))
        var di := idx / per_row
        var dc := idx % per_row
        return Rect2(r.position.x + kis + 14.0 + dc * (ic + 2.0),
                r.get_center().y - (ic + 3.0) * 0.5 + di * (ic + 3.0),
                ic, ic)

func _cap_flying(side: int, idx: int) -> bool:
        for c in cap_q:
                if int(c["side"]) == side and int(c["idx"]) == idx:
                        return true
        return false
""")

# ------------------------------- 7. apply_move: capture records + timing
rep("""        # the animation record BEFORE the state flips
        anim_q.append({"from": int(m["f"]), "to": int(m["t"]),
                "sq": int(m["t"]), "v": moved_v, "t": 0.0, "dur": 0.22})
""", """        # the animation record BEFORE the state flips - v0.3.8-5: the CPU
        # gets a LONGER, calmer slide (the owner: "animate the enemy chess
        # movements, currently only the user get animated") and knights hop
        cap_anim_dur = 0.22 if by_player else 0.32
        cap_anim_hop = absi(moved_v) == 2
        anim_q.append({"from": int(m["f"]), "to": int(m["t"]),
                "sq": int(m["t"]), "v": moved_v, "t": 0.0,
                "dur": cap_anim_dur, "hop": cap_anim_hop})
""")
rep("""        st = make_move(st, m)
        history.append(coord_of(m))
        names_log.append(nm)
        if cap_v != 0:
                if cap_v < 0:
                        cap_w.append(cap_v)   # white took a black piece
                else:
                        cap_b.append(cap_v)   # black took a white piece
""", """        # the capture square BEFORE the state flips (en passant takes the
        # pawn BESIDE the destination, not on it)
        var cap_sq := int(m["t"])
        if m["flag"] == "ep":
                cap_sq = int(m["t"]) + (-8 if st["w"] else 8)
        st = make_move(st, m)
        history.append(coord_of(m))
        names_log.append(nm)
        if cap_v != 0:
                if cap_v < 0:
                        cap_w.append(cap_v)   # white took a black piece
                        cap_q.append({"side": 0, "idx": cap_w.size() - 1,
                                "sq": cap_sq, "v": cap_v, "t": 0.0,
                                "dur": 0.55})
                else:
                        cap_b.append(cap_v)   # black took a white piece
                        cap_q.append({"side": 1, "idx": cap_b.size() - 1,
                                "sq": cap_sq, "v": cap_v, "t": 0.0,
                                "dur": 0.55})
""")

# ------------------------------------- 8. fx: the hop + the capture fly
rep("""        # the animated movers
        for a in anim_q:
                var k: float = clampf(float(a["t"]) / float(a["dur"]), 0.0, 1.0)
                var ease := 1.0 - pow(1.0 - k, 3.0)
                var from := _sq_rect(int(a["from"])).get_center()
                var to := _sq_rect(int(a["to"])).get_center()
                var v: int = a["v"]
                var tex := _piece_tex(v)
                var pad := sq_px * 0.10
                var at := from.lerp(to, ease)
                fx_l.draw_texture_rect(tex, Rect2(
                        at - Vector2(sq_px, sq_px) * 0.5
                                + Vector2(pad, pad),
                        Vector2(sq_px - pad * 2, sq_px - pad * 2)), false)
""", """        # the animated movers (v0.3.8-5: knights HOP - the piece lifts
        # over the row between, both sides, so the enemy move reads at a
        # glance)
        for a in anim_q:
                var k: float = clampf(float(a["t"]) / float(a["dur"]), 0.0, 1.0)
                var ease := 1.0 - pow(1.0 - k, 3.0)
                var from := _sq_rect(int(a["from"])).get_center()
                var to := _sq_rect(int(a["to"])).get_center()
                var v: int = a["v"]
                var tex := _piece_tex(v)
                var pad := sq_px * 0.10
                var at := from.lerp(to, ease)
                if a.get("hop", false):
                        at.y -= sin(k * PI) * sq_px * 0.38
                fx_l.draw_texture_rect(tex, Rect2(
                        at - Vector2(sq_px, sq_px) * 0.5
                                + Vector2(pad, pad),
                        Vector2(sq_px - pad * 2, sq_px - pad * 2)), false)
        # v0.3.8-5 THE CAPTURE THEATER: the fallen piece flies to its tray
        # while a red ring breathes out at the square it fell on - the
        # elimination is a SCENE, not a teleport
        for c in cap_q:
                var k: float = clampf(float(c["t"]) / float(c["dur"]), 0.0, 1.0)
                var ease := 1.0 - pow(1.0 - k, 3.0)
                var from := _sq_rect(int(c["sq"])).get_center()
                var slot := _tray_slot(int(c["side"]), int(c["idx"]))
                var at := from.lerp(slot.get_center(), ease)
                var sz := lerpf(sq_px * 0.86, slot.size.x, ease)
                var ctex := _piece_tex(int(c["v"]))
                fx_l.draw_texture_rect(ctex, Rect2(
                        at - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), false,
                        Color(1, 1, 1, 1.0 - 0.25 * ease))
                var pk: float = clampf(float(c["t"])
                        / (float(c["dur"]) * 0.5), 0.0, 1.0)
                if pk < 1.0:
                        fx_l.draw_arc(from, sq_px * (0.25 + 0.5 * pk),
                                0.0, TAU, 28,
                                Color(0.95, 0.3, 0.2, 0.5 * (1.0 - pk)), 3.0)
""")

# ------------------------------------------- 9. the tick advances cap_q
rep("""        for a in anim_q.duplicate():
                if float(a["t"]) >= float(a["dur"]):
                        anim_q.erase(a)
        piece_l.queue_redraw()
""", """        for a in anim_q.duplicate():
                if float(a["t"]) >= float(a["dur"]):
                        anim_q.erase(a)
        for c in cap_q.duplicate():
                c["t"] = float(c["t"]) + delta
                if float(c["t"]) >= float(c["dur"]):
                        cap_q.erase(c)
                        fx_l.queue_redraw()
        piece_l.queue_redraw()
""")

# --------------------------------- 10. new round clears the theater too
rep("""        anim_q = []
""", """        anim_q = []
        cap_q = []
""", 1)

# ------------------------------- 11. the optionals: select = state only
rep("""        b.pressed.connect(func():
                Jukebox.sfx("confirm", -4.0)
                Box.set_progress(game_id, "start_color",
                        "white" if white else "black")
                if state == "ready":
                        # THE START LAW: the pick leads straight into the war
                        _pick_down()
                        if ready_ui != null and is_instance_valid(ready_ui):
                                ready_ui.queue_free()
                                ready_ui = null
                        _new_round()
                else:
                        # mid-session: the pick rides the NEXT opener
                        color_override = "white" if white else "black"
                        game_toast("NEXT ROUND: you take %s"
                                % ("WHITE" if white else "BLACK"))
                        _pick_down())
        return b
""", """        # v0.3.8-5 (the owner: "make selecting a chess puts the state, and
        # tapping that bottom button starts the game"): the tap only PUTS
        # THE STATE - the card lights up, nothing starts; the bottom button
        # is what marches to the board
        b.pressed.connect(func():
                Jukebox.sfx("confirm", -4.0)
                Box.set_progress(game_id, "start_color",
                        "white" if white else "black")
                _paint_pick_cards()
                if state != "ready":
                        # mid-session: the pick rides the NEXT opener
                        color_override = "white" if white else "black"
                        game_toast("NEXT ROUND: you take %s"
                                % ("WHITE" if white else "BLACK")))
        if not pick_cards.has(white):
                pick_cards[white] = b
        return b

## the optionals' two cards wear their selected state live
func _paint_pick_cards() -> void:
        var picked := String(Box.get_progress(game_id, "start_color", "white"))
        for white in pick_cards:
                var card: Button = pick_cards[white]
                var sb := Arc.panel_style(Arc.CARD, 20, 6)
                if (picked == "white") == white:
                        sb.set_border_width_all(4)
                        sb.border_color = Arc.GOOD
                card.add_theme_stylebox_override("normal", sb)
                var sbp := sb.duplicate() as StyleBoxFlat
                sbp.bg_color = sbp.bg_color.darkened(0.05)
                card.add_theme_stylebox_override("pressed", sbp)
""")

# the bottom button now STARTS the war
rep("""        var cb := Arc.button("TO THE BOARD" if state == "ready" else "CLOSE",
                Vector2(0, 78), 26, Arc.GOOD, func(): _pick_down())
""", """        # v0.3.8-5 THE START LAW, MOVED: the pick leads into the war ONLY
        # through this button now
        var cb := Arc.button("TO THE BOARD" if state == "ready" else "CLOSE",
                Vector2(0, 78), 26, Arc.GOOD, func():
                        var was_ready: bool = state == "ready"
                        _pick_down()
                        if was_ready:
                                if ready_ui != null and is_instance_valid(ready_ui):
                                        ready_ui.queue_free()
                                        ready_ui = null
                                _new_round())
""")
rep("""var pick_open := false
var first_moment := true
""", """var pick_open := false
var first_moment := true
var pick_cards := {}           # white -> the card Button (live highlight)
""")

# ------------------------------ 12. cpu slide variables + music playing
rep("""var _time := 0.0
var _rng := RandomNumberGenerator.new()
""", """var cap_anim_dur := 0.22
var cap_anim_hop := false
var _time := 0.0
var _rng := RandomNumberGenerator.new()
""")

open(PATH, "w").write(src)
print(f"chess.gd patched: {len(n0)} -> {len(src)} bytes")
