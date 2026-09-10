#!/usr/bin/env python3
"""v038p5_domino_patch.py - the v0.3.8-5 DOMINO overhaul on
game/games/domino/domino.gd (the owner: "the ground ... major and fatal").
Idempotent via the v0.3.8-5 marker."""

import sys

PATH = "projects/gogabox/game/games/domino/domino.gd"
src = open(PATH).read()
if "v0.3.8-5" in src:
    print("already patched")
    sys.exit(0)


def rep(old, new, count=1):
    global src
    assert src.count(old) >= count, f"NOT FOUND: {old[:90]!r}"
    src = src.replace(old, new, count)


# ------------------------- 1. THE SMOOTH GROUP LAW vars + bigger constants
rep("""var BASE_L := 168.0            # board tile long side (the 1080 design law)
var hw := 236.0                # hand tile long side (v0.3.8-4: bigger - the""",
    """var BASE_L := 190.0            # board tile long side (v0.3.8-5: the
                                # magnifier glass is retired for good)
var hw := 252.0                # hand tile long side (v0.3.8-5: bigger)
# v0.3.8-5 THE SMOOTH GROUP LAW (the DominoBattle study law - the owner's
# "dominoes go down and switch positions by themselves"): the fit zoom and
# the re-center GLIDE to their target every tick (the reference tweens
# ANIM_DURATION_TILES_CENTER) - a placement never teleports the table
var _fit_target := 1.0
var _glide := false""")

# ----------------------------- 2. the fit law: tighter window, honest floor
rep("""        var bb := _chain_bbox()
        var avail := board_rect.grow(-24.0).size
        if bb.size.x <= 0.0 or bb.size.y <= 0.0:
                return 1.0
        var s: float = minf(1.0, minf(avail.x / bb.size.x, avail.y / bb.size.y))
        # v0.3.8-4: the floor walks DOWN to 0.26 - the grown table keeps
        # boxes ~1.35x the ground, so real play never gets near the floor;
        # only a pathological half-seat worst case touches it (the rig's
        # law: the WHOLE deck must seat, even in a half ground)
        return clampf(s, 0.26, 1.0)""",
    """        var bb := _chain_bbox()
        # v0.3.8-5 (the DominoBattle law): the margins are thin - the
        # ground is for dominoes, not for padding
        var avail := board_rect.grow(-16.0).size
        if bb.size.x <= 0.0 or bb.size.y <= 0.0:
                return 1.0
        var s: float = minf(1.0, minf(avail.x / bb.size.x,
                avail.y / bb.size.y))
        # v0.3.8-5: the floor walks UP to 0.45 - the spiral limits below
        # keep the box compact, so honest play never gets near the floor
        return clampf(s, 0.45, 1.0)""")

# ------------------- 3. THE SPIRAL LIMITS: a row runs max 7 tiles, then bends
rep("""## THE STEP: where a tile lands when played on `side` (1 left / 2 right),""",
    """## v0.3.8-5 THE SPIRAL LIMITS (the DominoBattle study law - its rows run
## a bounded width then the chain bends, MAX row width / MAX column height):
## a horizontal run carries at most 7 tiles before the elbow - the box
## stays compact, the fit zoom stays honest, the table never runs out of
## room (28 tiles spiral in ~5 rows instead of stretching to the walls)
const ROW_MAX := 7

## THE STEP: where a tile lands when played on `side` (1 left / 2 right),""")

rep("""                var along := _tile_short() if dbl else _tile_long()
                var npos: Vector2 = cand["center"] + (cand["dir"] as Vector2) \\
                                * (along * 0.5 + SNAKE_GAP)
                cur["pos"] = npos
                # the row's horizontal heading rides the cursor (the
                # serpentine's memory)
                if absf((cand["dir"] as Vector2).x) > 0.5:
                        cur["row_dir"] = cand["dir"]
                cur["force_turn"] = false
                return""",
    """                var along := _tile_short() if dbl else _tile_long()
                var npos: Vector2 = cand["center"] + (cand["dir"] as Vector2) \\
                                * (along * 0.5 + SNAKE_GAP)
                cur["pos"] = npos
                # the row's horizontal heading rides the cursor (the
                # serpentine's memory)
                if absf((cand["dir"] as Vector2).x) > 0.5:
                        cur["row_dir"] = cand["dir"]
                        # v0.3.8-5 THE SPIRAL LIMIT: the row counts its
                        # tiles; at ROW_MAX the NEXT tile bends the chain
                        cur["row_run"] = int(cur.get("row_run", 0)) + 1
                        if int(cur["row_run"]) >= ROW_MAX:
                                cur["row_run"] = 0
                                cur["force_turn"] = true
                else:
                        cur["force_turn"] = false
                return""")

# ------------------------------- 4. the smooth glide in the tick + refresh
rep("""        chain_l.queue_redraw()
        hand_l.queue_redraw()
        fx_l.queue_redraw()""",
    """        # v0.3.8-5 THE SMOOTH GROUP LAW: the zoom glides, never jumps -
        # while it travels, every chain rect + end slot follows per frame
        if _glide:
                _fit_scale = lerpf(_fit_scale, _fit_target,
                        minf(1.0, delta * 7.5))
                if absf(_fit_target - _fit_scale) < 0.002:
                        _fit_scale = _fit_target
                        _glide = false
                _relayout_chain_rects()
        chain_l.queue_redraw()
        hand_l.queue_redraw()
        fx_l.queue_redraw()""")

# ----------------------- 5. relayout: target + glide + factored rect rebuild
rep("""        if stale:
                _snake_rebuild()
        _fit_scale = _fit_chain()
        chain_rects = []
        for t in chain:
                chain_rects.append({"rect": _pose_to_screen(t),
                                "vertical": bool(t["pv"])})""",
    """        if stale:
                _snake_rebuild()
        # v0.3.8-5 THE SMOOTH GROUP LAW: the computed fit is the TARGET -
        # the first placement of a round lands on it at once, later ones
        # glide (a 7.5/s lerp in the tick moves the WHOLE table together -
        # no tile ever moves relative to its neighbours)
        _fit_target = _fit_chain()
        if chain.size() <= 1 or absf(_fit_scale - _fit_target) > 0.35 \\
                        or _fit_scale <= 0.0:
                _fit_scale = _fit_target
        else:
                _glide = true
        _relayout_chain_rects()""")

# the factored per-frame rebuild (chain rects + the open-end slots)
rep("""## a board-space rect through the fit transform (the slot truth)
func _board_to_screen_rect(r: Rect2) -> Rect2:""",
    """## v0.3.8-5: the chain rects + end slots, rebuilt on their own so the
## tick's glide can refresh them every frame (cheap: at most 28 rects)
func _relayout_chain_rects() -> void:
        chain_rects = []
        for t in chain:
                chain_rects.append({"rect": _pose_to_screen(t),
                                "vertical": bool(t["pv"])})
        var e := ends(chain)
        end_l = Rect2()
        end_r = Rect2()
        _end_board = {}
        if e.x == -1:
                return
        var cl := _snake_candidate(cur_l, false)
        var cr := _snake_candidate(cur_r, false)
        var placed := _placed_rects()
        if not _rect_in_bounds(cl["rect"]) \\
                        or _rect_hits_tiles(cl["rect"], placed):
                var el := _snake_turn(cur_l, false, placed)
                cl = {"rect": el["rect"], "center": el["center"]}
        if not _rect_in_bounds(cr["rect"]) \\
                        or _rect_hits_tiles(cr["rect"], placed):
                var er := _snake_turn(cur_r, false, placed)
                cr = {"rect": er["rect"], "center": er["center"]}
        end_l = _board_to_screen_rect(cl["rect"])
        end_r = _board_to_screen_rect(cr["rect"])
        _end_board = {1: cl["center"], 2: cr["center"]}

## a board-space rect through the fit transform (the slot truth)
func _board_to_screen_rect(r: Rect2) -> Rect2:""")

# ------------------------- 6. THE TILE ART: ivory body, soft 2D drop shadow
rep("""func _draw_tile_body(onto: Node2D, r: Rect2, a: int, b: int, vertical: bool,
                sel_glow := 0.0) -> void:
        ## a GOGABox domino: rounded-ish body, the divider bar, honest pips
        var s := _skin()
        var body: Color = s["body"]
        var edge: Color = s["edge"]
        var pip: Color = s["pip"]
        var line: Color = s["line"]
        if sel_glow > 0.0:
                onto.draw_rect(r.grow(5.0),
                        Color(1.0, 0.9, 0.4, 0.40 * sel_glow), false, 4.0)
        onto.draw_rect(r.grow(2.0), Color(0, 0, 0, 0.30))
        onto.draw_rect(r, edge)
        var inner := r.grow(-3.0)
        onto.draw_rect(inner, body)
        onto.draw_rect(inner.grow(-4.0),
                Color(1, 1, 1, 0.10 if body.v > 0.4 else 0.05))
        var mid := r.get_center()
        if vertical:
                onto.draw_line(Vector2(r.position.x + 6.0, mid.y),
                        Vector2(r.end.x - 6.0, mid.y), line, 3.0)
        else:
                onto.draw_line(Vector2(mid.x, r.position.y + 6.0),
                        Vector2(mid.x, r.end.y - 6.0), line, 3.0)""",
    """## the rounded body box (v0.3.8-5 THE DOMINOBATTLE BODY: the studied
## tile is a ROUNDED ivory plate - ours draws through a StyleBoxFlat so
## every skin inherits the shape, draw call per tile, cheap)
func _body_box(r: Rect2, fill: Color, radius: float) -> void:
        var sb := StyleBoxFlat.new()
        sb.bg_color = fill
        sb.set_corner_radius_all(int(radius))
        sb.draw(chain_l.get_canvas_item(), r)

func _draw_tile_body(onto: Node2D, r: Rect2, a: int, b: int, vertical: bool,
                sel_glow := 0.0) -> void:
        ## v0.3.8-5 THE WOW TILE (the owner: "take the dominoes from it
        ## as-is ... there is something like bloom or 2D shadows"): the
        ## studied tile's anatomy, redrawn OURS - a soft drop shadow under
        ## a rounded ivory plate, a top sheen + bottom shade (the measured
        ## 245/241/241 -> 217/218/221 -> 255 white falloff), a quiet
        ## divider, pips with their own little shadow. Nothing ships from
        ## the source game - the look is rebuilt from study notes.
        var s := _skin()
        var body: Color = s["body"]
        var edge: Color = s["edge"]
        var pip: Color = s["pip"]
        var line: Color = s["line"]
        var rad := minf(r.size.x, r.size.y) * 0.18
        if sel_glow > 0.0:
                onto.draw_rect(r.grow(6.0),
                        Color(1.0, 0.9, 0.4, 0.45 * sel_glow), false, 5.0)
        # THE 2D SHADOW: one soft plate offset down-right, then the body
        var sh := Rect2(r.position + Vector2(r.size.x * 0.055,
                r.size.y * 0.075), r.size)
        _body_box_round(onto, sh.grow(2.0), Color(0, 0, 0, 0.28), rad)
        _body_box_round(onto, r, edge.darkened(0.15), rad)
        var inner := r.grow(-2.5)
        _body_box_round(onto, inner, body, rad * 0.9)
        # the vertical falloff: a sheen up top, a shade at the bottom
        var band := inner.size.y * 0.30
        var sheen := Color(1, 1, 1, 0.16 if body.v > 0.4 else 0.09)
        var shade := Color(0, 0, 0, 0.10 if body.v > 0.4 else 0.16)
        _body_box_round(onto, Rect2(inner.position,
                Vector2(inner.size.x, band)), sheen, rad * 0.9)
        _body_box_round(onto, Rect2(
                Vector2(inner.position.x, inner.end.y - band * 0.7),
                Vector2(inner.size.x, band * 0.7)), shade, rad * 0.9)
        var mid := r.get_center()
        if vertical:
                onto.draw_line(Vector2(r.position.x + 7.0, mid.y),
                        Vector2(r.end.x - 7.0, mid.y), line, 2.5)
        else:
                onto.draw_line(Vector2(mid.x, r.position.y + 7.0),
                        Vector2(mid.x, r.end.y - 7.0), line, 2.5)""")

# the round-box helper that draws onto ANY layer (the shadow needs table/fx)
rep("""## the classic pip grid: positions in half-halfspace units""",
    """func _body_box_round(onto: Node2D, r: Rect2, fill: Color,
                radius: float) -> void:
        var sb := StyleBoxFlat.new()
        sb.bg_color = fill
        sb.set_corner_radius_all(int(radius))
        sb.draw(onto.get_canvas_item(), r)

## the classic pip grid: positions in half-halfspace units""")

# the pips wear their own micro-shadow (the studied pip depth)
rep("""                for pp in _pip_spots(v):
                        var off := Vector2(pp[0] * hx, pp[1] * hy)
                        if not vertical:
                                off = Vector2(pp[1] * hx, pp[0] * hy)
                        onto.draw_circle(c0 + off, rad, pip)""",
    """                for pp in _pip_spots(v):
                        var off := Vector2(pp[0] * hx, pp[1] * hy)
                        if not vertical:
                                off = Vector2(pp[1] * hx, pp[0] * hy)
                        # v0.3.8-5: the pip's own micro-shadow + top light -
                        # the studied tile's dots read as little wells
                        onto.draw_circle(c0 + off + Vector2(rad * 0.14,
                                rad * 0.18), rad, Color(0, 0, 0, 0.22))
                        onto.draw_circle(c0 + off, rad, pip)
                        onto.draw_circle(c0 + off + Vector2(-rad * 0.22,
                                -rad * 0.26), rad * 0.34,
                                Color(1, 1, 1, 0.20 if pip.v > 0.4 else 0.10))""")

# --------------------- 7. the spread: TWO rows, x2 tiles (the owner's mini)
rep("""        # v0.3.8-1 THE YARD SPREAD: when the player must draw, the boneyard
        # fans out face-down across the ground's middle - one rect per tile
        spread_rects = []
        if spread and deck.size() > 0:
                var sw := bw() * 0.52
                var sh := bw() * 0.92
                var cnt := deck.size()
                var gapw := 6.0
                var row_w := cnt * sw + (cnt - 1) * gapw
                var maxw2 := board_rect.size.x - 40.0
                var step := sw + gapw
                if row_w > maxw2:
                        step = (maxw2 - sw) / float(cnt - 1)
                var sx := board_rect.get_center().x - (step * (cnt - 1) + sw) * 0.5
                var sy := board_rect.get_center().y - sh * 0.5
                for i in cnt:
                        spread_rects.append(Rect2(Vector2(
                                sx + i * step, sy), Vector2(sw, sh)))""",
    """        # v0.3.8-5 THE TWO-ROW YARD (the owner: "it shows one long line
        # with small dominoes, make it two horizontal lines instead of one
        # and make the dominoes likely x2 bigger, orrr...a suitable size"):
        # the yard fans out as TWO centered rows of BIG face-down tiles
        spread_rects = []
        if spread and deck.size() > 0:
                var sw := bw() * 0.68
                var sh := bw() * 1.26
                var cnt := deck.size()
                var rows := 2
                var per := int(ceil(float(cnt) / float(rows)))
                var gapw := 12.0
                var row_gap := 16.0
                var maxw2 := board_rect.size.x - 48.0
                var step := sw + gapw
                if per * sw + (per - 1) * gapw > maxw2:
                        step = (maxw2 - sw) / float(maxi(1, per - 1))
                var roww := step * (per - 1) + sw
                var sx := board_rect.get_center().x - roww * 0.5
                var sy := board_rect.get_center().y
                sy -= (rows * sh + (rows - 1) * row_gap) * 0.5
                for i in cnt:
                        var rr := i / per
                        var cc := i % per
                        spread_rects.append(Rect2(Vector2(
                                sx + cc * step,
                                sy + rr * (sh + row_gap)), Vector2(sw, sh)))""")

# ---------------------------------- 8. THE WIDE CATCH (the owner's v0.3.8-4
# note stays law; the fatal ground made drops feel stricter - widen more)
rep("""                        var dl: float = _drop_dist(end_l.grow(18.0), drop_at)
                        if dl < best_d:
                                best_d = dl
                                best_side = 1
                if end_r.size.x > 0.0 and (cp & 2) != 0:
                        var dr: float = _drop_dist(end_r.grow(18.0), drop_at)
                        if dr < best_d:
                                best_d = dr
                                best_side = 2""",
    """                        # v0.3.8-5 THE WIDER CATCH: half a tile of slack
                        var dl: float = _drop_dist(end_l.grow(46.0), drop_at)
                        if dl < best_d:
                                best_d = dl
                                best_side = 1
                if end_r.size.x > 0.0 and (cp & 2) != 0:
                        var dr: float = _drop_dist(end_r.grow(46.0), drop_at)
                        if dr < best_d:
                                best_d = dr
                                best_side = 2""")

# ---------------------------- 9. the felt: the reference's shadow strips
rep("""        # the rail frame around the board area
        var r := board_rect.grow(12.0)
        table_l.draw_rect(r, t["rail"], false, 10.0)
        table_l.draw_rect(r.grow(4.0), Color(0, 0, 0, 0.25), false, 4.0)
        _draw_pile()
        _draw_cpu_hand()""",
    """        # the rail frame around the board area
        var r := board_rect.grow(12.0)
        table_l.draw_rect(r, t["rail"], false, 10.0)
        table_l.draw_rect(r.grow(4.0), Color(0, 0, 0, 0.25), false, 4.0)
        # v0.3.8-5 THE ROOM SHADOW (the studied ground's bg_game_shadow
        # strips - its top and bottom edges breathe): soft dark gradients
        # under the board's top rail and over its bottom rail
        var steps := 14
        for k in steps:
                var a := 0.16 * (1.0 - float(k) / float(steps))
                table_l.draw_rect(Rect2(r.position.x,
                        r.position.y + 8.0 + k * 5.0, r.size.x, 5.0),
                        Color(0, 0, 0, a))
                table_l.draw_rect(Rect2(r.position.x,
                        r.end.y - 8.0 - k * 5.0 - 5.0, r.size.x, 5.0),
                        Color(0, 0, 0, a * 0.8))
        _draw_pile()
        _draw_cpu_hand()""")

# ------------------------- 10. the music: the parlor's table rides with it
rep("""        _build_widgets(vp)
        _load_meta()
        add_hud_button("SHOP", func(): _shop_open())
        _build_ready()
        _relayout()
        _new_round()""",
    """        _build_widgets(vp)
        _load_meta()
        add_hud_button("SHOP", func(): _shop_open())
        # v0.3.8-5 THE PARLOR THEME: d_theme.ogg - the sunny table loop
        # composed for this room (tools/v038p5_dc_music.py, 120 BPM D-major,
        # original synthesis - nothing from the studied web game ships)
        Jukebox.music("res://assets/audio/music/d_theme.ogg")
        _build_ready()
        _relayout()
        _new_round()""")

open(PATH, "w").write(src)
print(f"domino.gd patched: {len(src)} bytes")
