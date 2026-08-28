extends Node2D
## The playable board screen: HUD, swipe input, juicy wave animations,
## win/lose flow with ads hooks (interstitial pacing, rewarded saves).

signal request_menu
signal request_next_level
signal request_shop

const CELL := 84.0
const BOARD_POS := Vector2(24, 214)  # 8*84 = 672 wide, screen 720

var level := 1
var target := 1000
var moves_left := 20
var score := 0
var stars := 0

var board := MatchBoard.new()
var skin: Dictionary
var pieces := {}  # Vector2i -> PieceView
var busy := true
var over := false
var used_extra_moves := false

var _board_layer: Node2D
var _fx_layer: Node2D
var _hud: CanvasLayer
var _moves_label: Label
var _score_label: Label
var _bar: Control
var _combo_label: Label
var _coins_label: Label
var _overlay: Control
var _expl: Array = []
var _selected := Vector2i(-1, -1)
var _press_cell := Vector2i(-1, -1)
var _press_px := Vector2.ZERO

func _ready() -> void:
        skin = Skins.get_skin(GameState.skin())
        level = GameState.level()
        target = Levels.target_for(level)
        moves_left = Levels.moves_for(level)
        for i in 8:
                _expl.append(load("res://assets/sprites/fx/explosion_%d.png" % i))
        Ads.banner_hide()
        _build_hud()
        _build_board()
        _deal()
        Sfx.ensure_music()

# ================================================================= build

func _build_board() -> void:
        _board_layer = Node2D.new()
        add_child(_board_layer)
        _fx_layer = Node2D.new()
        add_child(_fx_layer)

        var frame := Panel.new()
        var sb := StyleBoxFlat.new()
        sb.bg_color = skin["panel"]
        sb.set_corner_radius_all(22)
        frame.add_theme_stylebox_override("panel", sb)
        frame.position = BOARD_POS - Vector2(12, 12)
        frame.size = Vector2(CELL * 8 + 24, CELL * 8 + 24)
        # CRITICAL: STOP would eat every touch over the board before it reaches
        # _unhandled_input -> board feels frozen while buttons still work.
        frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(frame)
        move_child(frame, _board_layer.get_index())

func _piece_pos(v: Vector2i) -> Vector2:
        return BOARD_POS + Vector2(v.x * CELL + CELL / 2.0, v.y * CELL + CELL / 2.0)

func _make_piece(v: Vector2i, c: Dictionary) -> PieceView:
        var p := PieceView.new(skin, c)
        p.position = _piece_pos(v)
        _board_layer.add_child(p)
        pieces[v] = p
        return p

func _deal() -> void:
        board.setup(int(randi() % 100000000))
        busy = true
        var delay := 0.0
        for d in board.last_deal:
                var v: Vector2i = d["p"]
                var p := _make_piece(v, d["c"])
                p.scale = Vector2.ZERO
                var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                tw.tween_interval(delay)
                tw.tween_property(p, "scale", Vector2.ONE, 0.22)
                delay += 0.008
        get_tree().create_timer(delay + 0.25).timeout.connect(func():
                busy = false
                _check_deadlock())

# ================================================================= HUD

func _build_hud() -> void:
        _hud = CanvasLayer.new()
        add_child(_hud)

        var lvl := _label("LEVEL %d" % level, Vector2(0, 18), 40, skin["text"], 720)
        lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        lvl.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _coins_label = _label("%d" % GameState.coins(), Vector2(560, 22), 30, skin["text"])
        _coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        _coins_label.size.x = 130
        var coin_icon := TextureRect.new()
        coin_icon.texture = Skins.base_texture(Skins.get_skin("candy"), 3)
        coin_icon.position = Vector2(636, 18)
        coin_icon.custom_minimum_size = Vector2(40, 40)
        coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        coin_icon.size = Vector2(40, 40)
        coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _hud.add_child(coin_icon)

        _bar = ScoreBar.new()
        _bar.position = Vector2(24, 74)
        _bar.size = Vector2(672, 30)
        _bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _hud.add_child(_bar)

        _moves_label = _label("MOVES %d" % moves_left, Vector2(0, 118), 44, skin["text"], 720)
        _moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

        _score_label = _label("0 / %d" % target, Vector2(0, 168), 26, skin["text"], 720)
        _score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

        _combo_label = _label("", Vector2(0, 480), 52, Color.WHITE, 720)
        _combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _combo_label.z_index = 50

        _button("II", Vector2(16, 14), Vector2(56, 56), func(): _pause())
        # bottom row sits above the banner safe zone (banner + gesture bar)
        _button("HINT", Vector2(24, 1124), Vector2(140, 64), func(): _hint())
        _button("SKINS", Vector2(556, 1124), Vector2(140, 64), func(): _go_shop())
        GameState.coins_changed.connect(func(total: int): _coins_label.text = str(total))

func _label(txt: String, pos: Vector2, size_px: int, color: Color, width := 0.0) -> Label:
        var l := Label.new()
        l.text = txt
        l.position = pos
        var ls := LabelSettings.new()
        ls.font_size = size_px
        ls.font_color = color
        ls.outline_size = int(size_px / 3.5)
        ls.outline_color = Color(1, 1, 1, 0.85) if not skin["dark"] else Color(0, 0, 0, 0.6)
        l.label_settings = ls
        if width > 0:
                l.size.x = width
        _hud.add_child(l)
        return l

func _button(txt: String, pos: Vector2, size_px: Vector2, on_press: Callable) -> Button:
        var b := Button.new()
        b.text = txt
        b.position = pos
        b.size = size_px
        var sb := StyleBoxFlat.new()
        sb.bg_color = skin["accent"]
        sb.set_corner_radius_all(16)
        b.add_theme_stylebox_override("normal", sb)
        var sb2 := sb.duplicate()
        sb2.bg_color = (sb.bg_color as Color).darkened(0.15)
        b.add_theme_stylebox_override("pressed", sb2)
        b.add_theme_stylebox_override("hover", sb)
        b.add_theme_color_override("font_color", Color.WHITE)
        b.add_theme_font_size_override("font_size", 24)
        b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
        b.add_theme_constant_override("outline_size", 4)
        b.pressed.connect(func():
                Sfx.play("click", -4.0)
                on_press.call())
        _hud.add_child(b)
        return b

func _update_hud() -> void:
        _moves_label.text = "MOVES %d" % moves_left
        _moves_label.label_settings.font_color = Color("e83a3a") if moves_left <= 5 else skin["text"]
        _score_label.text = "%d / %d" % [score, target]
        if _bar is ScoreBar:
                _bar.score = score
                _bar.target = target
                _bar.stars = stars
                _bar.accent = skin["accent"]
                _bar.dark = skin["dark"]
                _bar.queue_redraw()

class ScoreBar:
        extends Control
        ## Progress toward the level target; star badges light up at 1x / 1.4x / 1.9x.
        var score := 0
        var target := 1000
        var stars := 0
        var accent := Color.PINK
        var dark := false

        func _draw() -> void:
                var bg := Color(0, 0, 0, 0.25) if dark else Color(1, 1, 1, 0.55)
                var full := Rect2(Vector2.ZERO, size)
                _draw_round(full, bg)
                var ratio := clampf(float(score) / float(maxi(1, target)), 0.0, 1.0)
                if ratio > 0.0:
                        _draw_round(Rect2(Vector2(4, 4), Vector2(maxf(18.0, (size.x - 140.0) * ratio), size.y - 8)), accent)
                # star badges to the right of the bar
                var marks := [1.0, 1.4, 1.9]
                for i in 3:
                        var on := stars > i
                        var c := Color("ffd54a") if on else (Color(1, 1, 1, 0.3) if not dark else Color(1, 1, 1, 0.2))
                        _draw_star(Vector2(size.x - 24 - (2 - i) * 40, size.y / 2.0), 15.0, c)

        func _draw_round(r: Rect2, c: Color) -> void:
                var sb := StyleBoxFlat.new()
                sb.bg_color = c
                sb.set_corner_radius_all(12)
                draw_style_box(sb, r)

        func _draw_star(center: Vector2, radius: float, c: Color) -> void:
                var pts := PackedVector2Array()
                for i in 10:
                        var a := -PI / 2.0 + TAU * i / 10.0
                        var r := radius if i % 2 == 0 else radius * 0.45
                        pts.append(center + Vector2.from_angle(a) * r)
                draw_colored_polygon(pts, c)


# ================================================================= input

func _unhandled_input(event: InputEvent) -> void:
        if busy or over:
                return
        # project.godot emulates touch from mouse, so ScreenTouch covers all platforms
        if event is InputEventScreenTouch:
                if event.pressed:
                        _touch_cell(event.position)
                else:
                        _release_cell(event.position)

func _touch_cell(px: Vector2) -> void:
        _press_px = px
        _press_cell = _cell_at(px)
        if _press_cell.x < 0:
                return
        if _selected.x >= 0 and _selected != _press_cell \
                        and (_selected - _press_cell).length() == 1.0:
                var a := _selected
                _clear_selection()
                _try_swap(a, _press_cell)
                return
        _set_selected(_press_cell)

func _release_cell(px: Vector2) -> void:
        if _press_cell.x < 0:
                return
        var delta := px - _press_px
        if delta.length() > 28.0:
                var dir := Vector2i.ZERO
                if absf(delta.x) > absf(delta.y):
                        dir = Vector2i(1 if delta.x > 0 else -1, 0)
                else:
                        dir = Vector2i(0, 1 if delta.y > 0 else -1)
                var a := _press_cell
                var b: Vector2i = a + dir
                _clear_selection()
                _press_cell = Vector2i(-1, -1)
                _try_swap(a, b)

func _cell_at(px: Vector2) -> Vector2i:
        var local := px - BOARD_POS
        var v := Vector2i(int(local.x / CELL), int(local.y / CELL))
        return v if MatchBoard.in_bounds(v) else Vector2i(-1, -1)

func _set_selected(v: Vector2i) -> void:
        _clear_selection()
        _selected = v
        if pieces.has(v):
                pieces[v].set_selected(true)

func _clear_selection() -> void:
        if _selected.x >= 0 and pieces.has(_selected):
                pieces[_selected].set_selected(false)
        _selected = Vector2i(-1, -1)

# ================================================================= swapping

func _try_swap(a: Vector2i, b: Vector2i) -> void:
        if busy or over or not MatchBoard.in_bounds(b):
                return
        var res: Dictionary = board.try_swap(a, b)
        if res.is_empty():
                Sfx.play("error", -6.0)
                # bounce both pieces toward each other and back
                var pa := pieces.get(a) as PieceView
                var pb := pieces.get(b) as PieceView
                if pa and pb:
                        var mid := (_piece_pos(b) - _piece_pos(a)) * 0.25
                        var tw := create_tween()
                        tw.set_parallel(true)
                        tw.tween_property(pa, "position", _piece_pos(a) + mid, 0.08)
                        tw.tween_property(pb, "position", _piece_pos(b) - mid, 0.08)
                        tw.chain().set_parallel(true)
                        tw.tween_property(pa, "position", _piece_pos(a), 0.10)
                        tw.tween_property(pb, "position", _piece_pos(b), 0.10)
                return
        busy = true
        moves_left -= 1
        _update_hud()
        Sfx.play("swap", -6.0)
        var pa2 := pieces.get(a) as PieceView
        var pb2 := pieces.get(b) as PieceView
        if pa2 and pb2:
                var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
                tw.tween_property(pa2, "position", _piece_pos(b), 0.13)
                tw.tween_property(pb2, "position", _piece_pos(a), 0.13)
        pieces[a] = pb2
        pieces[b] = pa2
        await get_tree().create_timer(0.14).timeout
        await _play_waves(res["waves"])
        _after_action()

func _after_action() -> void:
        _check_deadlock()
        if score >= target:
                _win()
        elif moves_left <= 0:
                _lose()
        busy = over

# ================================================================= waves

func _play_waves(waves: Array) -> void:
        for wave in waves:
                await _play_wave(wave)

func _play_wave(wave: Dictionary) -> void:
        var cleared: Array = wave["cleared"]
        if not cleared.is_empty():
                # pops + explosions
                var combo: int = wave["combo"]
                Sfx.pop(combo)
                var centroid := Vector2.ZERO
                for c in cleared:
                        centroid += _piece_pos(c)
                centroid /= cleared.size()
                _explosion_at(centroid, 1.0 + 0.12 * combo)
                for c in cleared:
                        var p := pieces.get(c) as PieceView
                        if p:
                                pieces.erase(c)
                                var tw := create_tween().set_parallel(true)
                                tw.tween_property(p, "scale", Vector2.ONE * 1.35, 0.15).set_trans(Tween.TRANS_BACK)
                                tw.tween_property(p, "modulate", Color(1, 1, 1, 0), 0.15)
                                tw.chain().tween_callback(p.queue_free)
                if wave["score"] > 0:
                        _score_popup(centroid, wave["score"])
                var praise := Levels.praise_for(combo)
                if praise != "":
                        _praise(praise)
                if combo >= 3:
                        Sfx.play("pop_deep", -4.0, 1.0 + 0.1 * combo)
                await get_tree().create_timer(0.17).timeout

        # newborn specials appear
        for sp in wave["spawned"]:
                var v: Vector2i = sp["p"]
                var old := pieces.get(v) as PieceView
                if old:
                        old.queue_free()
                var np := _make_piece(v, sp["c"])
                np.scale = Vector2.ZERO
                var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                tw.tween_property(np, "scale", Vector2.ONE, 0.2)
                Sfx.play("sparkle", -4.0)
        if not wave["spawned"].is_empty():
                await get_tree().create_timer(0.12).timeout

        # gravity: existing pieces fall
        var fall_tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
        for f in wave["fell"]:
                var p := pieces.get(f["from"]) as PieceView
                if p:
                        pieces.erase(f["from"])
                        pieces[f["to"]] = p
                        fall_tw.tween_property(p, "position", _piece_pos(f["to"]), 0.15)
        fall_tw.set_parallel(false)
        for f in wave["fell"]:
                var p := pieces.get(f["to"]) as PieceView
                if p:
                        var tw := create_tween()
                        tw.tween_property(p, "scale", Vector2(1.08, 0.92), 0.05)
                        tw.tween_property(p, "scale", Vector2.ONE, 0.07)
                        break  # one squash sample is enough (they all land together)
        # fresh pieces drop from above
        var drop_tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
        for d in wave["dealt"]:
                var v: Vector2i = d["p"]
                var p := _make_piece(v, d["c"])
                var start_y: float = BOARD_POS.y - CELL * (2.0 + float(d.get("drop", 1)))
                p.position = Vector2(_piece_pos(v).x, start_y)
                drop_tw.tween_property(p, "position", _piece_pos(v), 0.22 + 0.03 * float(d.get("drop", 1)))
        if not wave["fell"].is_empty() or not wave["dealt"].is_empty():
                Sfx.play("swap", -10.0, 0.8)
                await get_tree().create_timer(0.26).timeout
        score += wave["score"]
        stars = Levels.stars_for(score, target)
        _update_hud()

func _explosion_at(pos: Vector2, scale_f := 1.0) -> void:
        var s := Sprite2D.new()
        s.texture = _expl[0]
        s.position = pos
        s.scale = Vector2.ONE * (0.85 * scale_f)
        s.z_index = 20
        _fx_layer.add_child(s)
        for i in range(1, 8):
                var idx := i
                get_tree().create_timer(0.04 * idx).timeout.connect(func():
                        if is_instance_valid(s):
                                s.texture = _expl[idx])
        get_tree().create_timer(0.42).timeout.connect(func():
                if is_instance_valid(s):
                        s.queue_free())

func _score_popup(pos: Vector2, amount: int) -> void:
        var l := Label.new()
        l.text = "+%d" % amount
        var ls := LabelSettings.new()
        ls.font_size = 40
        ls.font_color = Color.WHITE
        ls.outline_size = 10
        ls.outline_color = skin["accent"]
        l.label_settings = ls
        l.position = pos + Vector2(-40, -30)
        l.z_index = 40
        _hud.add_child(l)
        var tw := create_tween().set_parallel(true)
        tw.tween_property(l, "position:y", l.position.y - 70, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.2)
        tw.chain().tween_callback(l.queue_free)

func _praise(txt: String) -> void:
        _combo_label.text = txt
        _combo_label.label_settings.font_color = skin["accent"]
        _combo_label.scale = Vector2.ONE * 0.3
        _combo_label.pivot_offset = Vector2(360, 30)
        var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tw.tween_property(_combo_label, "scale", Vector2.ONE, 0.25)
        tw.tween_interval(0.5)
        tw.tween_property(_combo_label, "modulate:a", 0.0, 0.25)
        tw.tween_callback(func():
                _combo_label.modulate.a = 1.0
                _combo_label.text = "")

# ================================================================= flow

func _hint() -> void:
        if busy or over:
                return
        var hint: Variant = board.find_hint()
        if hint == null:
                _check_deadlock()
                return
        Sfx.play("click", -4.0, 1.2)
        for v in hint:
                if pieces.has(v):
                        pieces[v].set_hinted(true)
        get_tree().create_timer(1.2).timeout.connect(func():
                for v in hint:
                        if pieces.has(v):
                                pieces[v].set_hinted(false))

func _check_deadlock() -> void:
        if over or busy:
                return
        if board.find_hint() == null:
                _praise("NO MOVES - RESHUFFLING!")
                var res: Dictionary = board.shuffle()
                for m in res["moved"]:
                        var v: Vector2i = m["p"]
                        var p := pieces.get(v) as PieceView
                        if p:
                                p.cell = m["c"]
                                p.refresh()
                                var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                                tw.tween_property(p, "scale", Vector2.ONE * 1.15, 0.12)
                                tw.tween_property(p, "scale", Vector2.ONE, 0.12)
                Sfx.play("sparkle", -2.0)

func _win() -> void:
        if over:
                return
        over = true
        busy = true
        _clear_selection()
        stars = Levels.stars_for(score, target)
        Ads.register_run()
        GameState.complete_level(level, score, stars)
        var earned := Levels.coins_for(stars)
        Sfx.play("win", -2.0)
        _show_win_overlay(earned, false)

func _lose() -> void:
        if over:
                return
        over = true
        busy = true
        _clear_selection()
        Ads.register_run()
        Sfx.play("lose", -2.0)
        _show_lose_overlay()

func _go_shop() -> void:
        if over:
                return
        Ads.register_run()
        request_shop.emit()

# ================================================================= overlays

func _overlay_base() -> VBoxContainer:
        _overlay = Control.new()
        _overlay.size = Vector2(720, 1280)
        _hud.add_child(_overlay)
        var dim := ColorRect.new()
        dim.color = Color(0, 0, 0, 0.55)
        dim.size = Vector2(720, 1280)
        _overlay.add_child(dim)
        var panel := PanelContainer.new()
        var sb := StyleBoxFlat.new()
        sb.bg_color = skin["panel"]
        sb.set_corner_radius_all(28)
        sb.content_margin_left = 36
        sb.content_margin_right = 36
        sb.content_margin_top = 30
        sb.content_margin_bottom = 30
        panel.add_theme_stylebox_override("panel", sb)
        panel.position = Vector2(90, 400)
        panel.size = Vector2(540, 480)
        _overlay.add_child(panel)
        var vbox := VBoxContainer.new()
        vbox.add_theme_constant_override("separation", 18)
        panel.add_child(vbox)
        return vbox

func _big_button(parent: Control, txt: String, cb: Callable, color := Color.TRANSPARENT) -> Button:
        var b := Button.new()
        b.text = txt
        b.custom_minimum_size = Vector2(460, 74)
        var sb := StyleBoxFlat.new()
        sb.bg_color = skin["accent"] if color == Color.TRANSPARENT else color
        sb.set_corner_radius_all(18)
        b.add_theme_stylebox_override("normal", sb)
        b.add_theme_stylebox_override("hover", sb)
        var sb2 := sb.duplicate()
        sb2.bg_color = (sb.bg_color as Color).darkened(0.15)
        b.add_theme_stylebox_override("pressed", sb2)
        b.add_theme_color_override("font_color", Color.WHITE)
        b.add_theme_font_size_override("font_size", 26)
        b.pressed.connect(func():
                Sfx.play("click", -4.0)
                cb.call())
        parent.add_child(b)
        return b

func _show_win_overlay(coins_earned: int, doubled: bool) -> void:
        var vb := _overlay_base()
        var title := Label.new()
        title.text = "LEVEL %d CLEAR!" % level
        var ls := LabelSettings.new()
        ls.font_size = 40
        ls.font_color = skin["accent"]
        ls.outline_size = 8
        ls.outline_color = Color(1, 1, 1, 0.8) if not skin["dark"] else Color(0, 0, 0, 0.5)
        title.label_settings = ls
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(title)

        var star_row := HBoxContainer.new()
        star_row.alignment = BoxContainer.ALIGNMENT_CENTER
        star_row.add_theme_constant_override("separation", 26)
        vb.add_child(star_row)
        for i in 3:
                var s := Label.new()
                s.text = "*"
                var sls := LabelSettings.new()
                sls.font_size = 64
                sls.font_color = Color("ffd54a") if i < stars else Color(0.3, 0.3, 0.3, 0.5)
                s.label_settings = sls
                star_row.add_child(s)
                if i < stars:
                        var idx := i
                        get_tree().create_timer(0.35 + 0.35 * idx).timeout.connect(func():
                                Sfx.play("star", -2.0, 1.0 + 0.15 * idx))

        var coins_l := Label.new()
        coins_l.text = ("+%d COINS  (DOUBLED!)" % coins_earned) if doubled else ("+%d COINS" % coins_earned)
        coins_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        coins_l.label_settings = ls.duplicate()
        coins_l.label_settings.font_size = 28
        coins_l.label_settings.font_color = skin["text"]
        vb.add_child(coins_l)

        if not doubled:
                _big_button(vb, "DOUBLE COINS  (WATCH AD)", func():
                        Ads.show_rewarded(func(watched: bool):
                                if watched and over:
                                        GameState.add_coins(coins_earned)
                                        Sfx.play("coin")
                                        _overlay.queue_free()
                                        _show_win_overlay(coins_earned, true)))
        _big_button(vb, "NEXT LEVEL", func():
                Ads.maybe_interstitial(func(_shown: bool): request_next_level.emit()))
        _overlay.scale = Vector2(0.8, 0.8)
        _overlay.pivot_offset = Vector2(360, 640)
        var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tw.tween_property(_overlay, "scale", Vector2.ONE, 0.3)

func _show_lose_overlay() -> void:
        var vb := _overlay_base()
        var title := Label.new()
        title.text = "OUT OF MOVES"
        var ls := LabelSettings.new()
        ls.font_size = 40
        ls.font_color = skin["text"]
        ls.outline_size = 8
        ls.outline_color = Color(1, 1, 1, 0.7)
        title.label_settings = ls
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(title)
        var prog := Label.new()
        prog.text = "%d / %d" % [score, target]
        prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        prog.label_settings = ls.duplicate()
        prog.label_settings.font_size = 30
        vb.add_child(prog)

        if not used_extra_moves:
                _big_button(vb, "+5 MOVES  (WATCH AD)", func():
                        Ads.show_rewarded(func(watched: bool):
                                if watched and over:
                                        used_extra_moves = true
                                        moves_left += 5
                                        over = false
                                        busy = false
                                        _overlay.queue_free()
                                        _update_hud()
                                        Sfx.play("confirm")))
        _big_button(vb, "RETRY", func():
                Ads.maybe_interstitial(func(_shown: bool): request_next_level.emit()))
        _big_button(vb, "MENU", func():
                Ads.maybe_interstitial(func(_shown: bool): request_menu.emit()),
                Color(0.4, 0.42, 0.5))
        _overlay.scale = Vector2(0.8, 0.8)
        _overlay.pivot_offset = Vector2(360, 640)
        var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tw.tween_property(_overlay, "scale", Vector2.ONE, 0.3)

func _pause() -> void:
        if over:
                return
        busy = true
        var vb := _overlay_base()
        var title := Label.new()
        title.text = "PAUSED"
        var ls := LabelSettings.new()
        ls.font_size = 40
        ls.font_color = skin["text"]
        ls.outline_size = 8
        ls.outline_color = Color(1, 1, 1, 0.7)
        title.label_settings = ls
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(title)
        _big_button(vb, "RESUME", func():
                _overlay.queue_free()
                busy = over)
        _big_button(vb, "RESTART", func():
                Ads.maybe_interstitial(func(_shown: bool): request_next_level.emit()))
        _big_button(vb, "MENU", func():
                Ads.maybe_interstitial(func(_shown: bool): request_menu.emit()),
                Color(0.4, 0.42, 0.5))
