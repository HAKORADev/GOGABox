class_name PieceView
extends Node2D
## One board piece: base sprite + special overlays + selection/hint states.
## Skins with real special sprites (candy/neon) use them; others get clean
## code-drawn overlays so every skin supports every special.

const SIZE := 84.0

var skin: Dictionary
var cell: Dictionary  # {"t": int, "s": int}
var selected := false
var hinted := false

var _spr: Sprite2D
var _pulse := 0.0
var _spin := 0.0

func _init(skin_: Dictionary, cell_: Dictionary) -> void:
        skin = skin_
        cell = cell_
        _spr = Sprite2D.new()
        add_child(_spr)
        refresh()

func refresh() -> void:
        var t: int = cell["t"]
        var s: int = cell["s"]
        var tex: Texture2D = null
        match s:
                MatchBoard.SP_H, MatchBoard.SP_V:
                        tex = Skins.striped_texture(skin, t, s == MatchBoard.SP_H)
                MatchBoard.SP_WRAP:
                        tex = Skins.wrapped_texture(skin)
                MatchBoard.SP_BOMB:
                        tex = Skins.colorbomb_texture(skin)
        if tex == null:
                tex = Skins.base_texture(skin, maxi(t, 0)) if t >= 0 else Skins.colorbomb_texture(skin)
        _spr.texture = tex
        var fit := SIZE - 10.0
        var base_size := float(skin["size"])
        _spr.scale = Vector2.ONE * (fit / maxf(1.0, float(tex.get_width()) if tex else base_size))
        queue_redraw()

func _process(delta: float) -> void:
        var s: int = cell["s"]
        var redraw := false
        if s == MatchBoard.SP_BOMB and Skins.colorbomb_texture(skin) != null:
                _spin += delta * 1.5
                _spr.rotation = _spin
        if s == MatchBoard.SP_WRAP and Skins.wrapped_texture(skin) == null:
                _pulse += delta * 4.0
                redraw = true
        if selected or hinted:
                _pulse += delta * (9.0 if selected else 5.0)
                redraw = true
        if redraw:
                queue_redraw()

func _draw() -> void:
        var s: int = cell["s"]
        var t: int = cell["t"]
        var accent: Color = skin["accent"]
        if s == MatchBoard.SP_H or s == MatchBoard.SP_V:
                if Skins.striped_texture(skin, t, s == MatchBoard.SP_H) == null:
                        # three rounded stripes across the piece
                        var horiz := s == MatchBoard.SP_H
                        for i in range(-1, 2):
                                var bar := Rect2(-26, -6 + i * 14, 52, 8) if horiz else Rect2(-6 + i * 14, -26, 8, 52)
                                draw_rect(bar, Color(1, 1, 1, 0.85), true, false)
                        draw_rect(Rect2(-28, -28, 56, 56), Color(1, 1, 1, 0.25), false, 3.0)
        elif s == MatchBoard.SP_WRAP and Skins.wrapped_texture(skin) == null:
                var k := 1.0 + 0.08 * sin(_pulse)
                var pts := PackedVector2Array()
                for i in 6:
                        var a := TAU * i / 6.0
                        pts.append(Vector2.from_angle(a) * 30.0 * k)
                var closed := pts.duplicate()
                closed.append(pts[0])
                draw_polyline(closed, accent.lightened(0.2), 4.0, true)
        elif s == MatchBoard.SP_BOMB and Skins.colorbomb_texture(skin) == null:
                # dark orb with rotating rainbow arcs
                draw_circle(Vector2.ZERO, 28.0, Color(0.12, 0.10, 0.18))
                for i in 3:
                        var a0 := _spin + TAU * i / 3.0
                        draw_arc(Vector2.ZERO, 22.0, a0, a0 + TAU / 5.0, 12,
                                        Color.from_hsv(fposmod(a0, TAU) / TAU, 0.8, 1.0), 5.0)
        if selected:
                var k := 1.0 + 0.06 * sin(_pulse)
                draw_arc(Vector2.ZERO, 34.0 * k, 0, TAU, 40, Color(1, 1, 1, 0.95), 5.0, true)
        elif hinted:
                draw_arc(Vector2.ZERO, 34.0, 0, TAU, 40, Color(1, 1, 0.6, 0.6 + 0.3 * sin(_pulse)), 4.0, true)

func set_selected(v: bool) -> void:
        if selected == v:
                return
        selected = v
        var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tw.tween_property(self, "scale", Vector2.ONE * (1.12 if v else 1.0), 0.15)
        queue_redraw()

func set_hinted(v: bool) -> void:
        hinted = v
        queue_redraw()
        if v:
                var tw := create_tween().set_loops(4)
                tw.tween_property(self, "rotation", 0.12, 0.09)
                tw.tween_property(self, "rotation", -0.12, 0.09)
                tw.tween_property(self, "rotation", 0.0, 0.09)
