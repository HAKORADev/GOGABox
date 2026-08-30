class_name Arc
extends RefCounted
## The Box chrome kit: palette, fonts, buttons, panels, toasts, chips.
## Every screen in GOGABox builds its UI through this so the box feels like ONE box.

const INK := Color("35210f")
const CARD := Color("fff3dc")
const CARD_2 := Color("f7e6c4")
const ACCENT := Color("ffb020")     # amber
const HOT := Color("ff7a1a")        # orange
const GOOD := Color("58c470")
const BAD := Color("e8574a")
const COIN := Color("ffc93c")
const DIM_BG := Color(0.09, 0.05, 0.02, 0.72)

static var _font_big: FontFile
static var _font_ui: FontFile

static func font_big() -> FontFile:
        if _font_big == null:
                _font_big = load("res://assets/fonts/Kenney_Rocket.ttf")
        return _font_big

static func font_ui() -> FontFile:
        if _font_ui == null:
                _font_ui = load("res://assets/fonts/Kenney_Mini.ttf")
        return _font_ui

# ------------------------------------------------------------------ builders

static func label(txt: String, size: int, color := INK, use_display := true) -> Label:
        var l := Label.new()
        l.text = txt
        l.add_theme_font_override("font", font_big() if use_display else font_ui())
        l.add_theme_font_size_override("font_size", size)
        l.add_theme_color_override("font_color", color)
        l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        return l

## v0.1.1 OWNER RULE ("long names will go out of space"): dynamic text size
## for fixed-width spots - the more text, the smaller the font, so the name
## ALWAYS fits its box. Steps the font down from `size` until the text fits
## `max_w` (floor 12). Used by every feed tile + carousel card title; the
## pre-play page keeps its scroll, so it stays big there.
static func fit_label(txt: String, size: int, color: Color, max_w: float,
                use_display := true) -> Label:
        var f := font_big() if use_display else font_ui()
        var fs := size
        while fs > 12 and f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_w:
                fs -= 1
        return label(txt, fs, color, use_display)

## Rendered width of a text in the Box fonts (chips position themselves with
## this instead of guessing - the "k outside the widget" bug family).
static func text_width(txt: String, size: int, use_display := false) -> float:
        var f := font_big() if use_display else font_ui()
        return f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

static func panel_style(bg: Color, radius := 22, margin := 0) -> StyleBoxFlat:
        var sb := StyleBoxFlat.new()
        sb.bg_color = bg
        sb.set_corner_radius_all(radius)
        if margin > 0:
                sb.set_content_margin_all(margin)
        return sb

static func button(txt: String, size: Vector2, font_size := 30, bg := ACCENT,
                on_press := Callable(), use_display := true) -> Button:
        var b := Button.new()
        b.text = txt
        b.custom_minimum_size = size
        b.size = size
        b.add_theme_font_override("font", font_big() if use_display else font_ui())
        b.add_theme_font_size_override("font_size", font_size)
        b.add_theme_color_override("font_color", Color.WHITE)
        b.add_theme_color_override("font_hover_color", Color.WHITE)
        b.add_theme_color_override("font_pressed_color", CARD)
        var sb := panel_style(bg, int(size.y / 2.6))
        sb.shadow_color = Color(0, 0, 0, 0.35)
        sb.shadow_size = 6
        sb.shadow_offset = Vector2(0, 4)
        b.add_theme_stylebox_override("normal", sb)
        var sbh := sb.duplicate() as StyleBoxFlat
        sbh.bg_color = bg.lightened(0.08)
        b.add_theme_stylebox_override("hover", sbh)
        var sbp := sb.duplicate() as StyleBoxFlat
        sbp.bg_color = bg.darkened(0.18)
        sbp.shadow_size = 2
        b.add_theme_stylebox_override("pressed", sbp)
        var sbd := sb.duplicate() as StyleBoxFlat
        sbd.bg_color = Color(0.45, 0.42, 0.38)
        b.add_theme_stylebox_override("disabled", sbd)
        if on_press.is_valid():
                b.pressed.connect(func():
                        Jukebox.sfx("click", -4.0)
                        on_press.call())
        return b

## Icon + text chip (used for coin balance, best score, prices).
static func chip(txt: String, icon_path := "", bg := Color(0, 0, 0, 0.35),
                font_size := 26, color := CARD) -> PanelContainer:
        var pc := PanelContainer.new()
        pc.add_theme_stylebox_override("panel", panel_style(bg, 24, 8))
        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", 8)
        pc.add_child(h)
        if icon_path != "" and ResourceLoader.exists(icon_path):
                var ic := TextureRect.new()
                ic.texture = load(icon_path)
                ic.custom_minimum_size = Vector2(font_size + 8, font_size + 8)
                ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
                h.add_child(ic)
        var l := label(txt, font_size, color, false)
        h.add_child(l)
        pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        return pc

## Chip fed from the Meta tables (genres / subs / ages). Unknown ids degrade
## to a text-only chip - modular by design.
static func meta_chip(kind: String, id: String, bg := Color(0, 0, 0, 0.14),
                font_size := 18, color := INK) -> PanelContainer:
        var txt := id
        match kind:
                "genre": txt = Meta.genre_label(id)
                "sub": txt = Meta.sub_label(id)
                "age": txt = Meta.age_label(id)
        return chip(txt, Meta.icon_for(kind, id), bg, font_size, color)

## Button with a trailing GOGACoin icon - use for EVERY coin-priced action so
## players never confuse GOGACoins with per-game currencies.
static func coin_button(txt: String, size: Vector2, font_size := 30, bg := ACCENT,
                on_press := Callable()) -> Button:
        var b := button("", size, font_size, bg, on_press)
        var h := HBoxContainer.new()
        h.set_anchors_preset(Control.PRESET_FULL_RECT)
        h.alignment = BoxContainer.ALIGNMENT_CENTER
        h.add_theme_constant_override("separation", 10)
        h.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var l := label(txt, font_size, Color.WHITE)
        h.add_child(l)
        var c := TextureRect.new()
        c.texture = load("res://assets/ui/coin.png")
        c.custom_minimum_size = Vector2(font_size + 10, font_size + 10)
        c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        c.mouse_filter = Control.MOUSE_FILTER_IGNORE
        h.add_child(c)
        b.add_child(h)
        return b

## Dynamic GOGABattery meter: body + level fill + color by charge.
## LIVE-UPDATABLE (v0.0.7 battery sheet ticks every second): the returned
## control carries a "set_level" meta - call
##   ctrl.get_meta("set_level").call(count, cap); ctrl.queue_redraw()
## to move the fill without rebuilding the whole sheet.
static func battery_control(count: int, cap: int, w := 56.0, h := 26.0) -> Control:
        var c := Control.new()
        c.custom_minimum_size = Vector2(w + 6, h)
        c.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var state := {"lvl": _battery_level(count, cap)}
        c.draw.connect(func():
                var lvl: float = state["lvl"]
                var col := Arc.GOOD if lvl > 0.5 else (Arc.ACCENT if lvl > 0.25 else Arc.BAD)
                # tip nub
                c.draw_rect(Rect2(w, h * 0.3, 5, h * 0.4), Color(1, 1, 1, 0.75))
                # body
                c.draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.45))
                c.draw_rect(Rect2(0, 0, w, h), Color(1, 1, 1, 0.85), false, 2.0)
                # fill
                if lvl > 0.01:
                        c.draw_rect(Rect2(3, 3, (w - 6) * lvl, h - 6), col))
        c.set_meta("set_level", func(n: int, cap_: int): state["lvl"] = _battery_level(n, cap_))
        return c

static func _battery_level(count: int, cap: int) -> float:
        if cap <= 0:
                return 0.0
        return clampf(float(count) / float(cap), 0.0, 1.0)

static func coin_chip() -> PanelContainer:
        return chip(str(Box.coins()), "res://assets/ui/coin.png", Color(0, 0, 0, 0.4), 28, COIN)

## THE score-bonus ratio, in ONE place (owner rule: "show the score bonus
## ratio so users who are interested to know, know"). Every screen that
## prints the bonus prints THIS text - game HUD, dead menu, anything later.
static func bonus_ratio_text(score: int, div: int) -> String:
        if div <= 0:
                return "%d" % score
        return "%d/%d = %d" % [score, div, score / div]

## Bottom-anchored toast on ITS OWN top CanvasLayer (v0.0.9 owner report:
## "filters applied" and "ad closed early" showed up BEHIND sheets/panels -
## layer 100 paints above every sheet, dim and the achievement popup while
## staying at the bottom of the room).
static func toast_overlay(parent: Node) -> Dictionary:
        var cl := CanvasLayer.new()
        cl.layer = 100
        var root := Control.new()
        root.set_anchors_preset(Control.PRESET_FULL_RECT)
        root.mouse_filter = Control.MOUSE_FILTER_IGNORE
        cl.add_child(root)
        var t := label("", 28, CARD)
        t.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
        offset_bottom_safe(t)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        t.modulate.a = 0.0
        root.add_child(t)
        parent.add_child(cl)
        return {"label": t, "layer": cl}

## Bottom-anchored toast that stays above the banner safe area in any
## orientation (fixed y=1040 broke landscape / tall screens).
static func offset_bottom_safe(t: Label) -> void:
        t.offset_left = 24
        t.offset_right = -24
        t.offset_top = -180
        t.offset_bottom = -120

static func toast(t: Dictionary, msg: String) -> void:
        var l: Label = t["label"]
        l.text = msg
        l.modulate.a = 1.0
        var tw := l.create_tween()
        tw.tween_interval(1.3)
        tw.tween_property(l, "modulate:a", 0.0, 0.4)

## Full-screen dim + centered sheet. Returns the inner VBox to fill.
static func sheet(parent: Control, sheet_height := 0.0) -> VBoxContainer:
        var dim := ColorRect.new()
        dim.color = DIM_BG
        dim.set_anchors_preset(Control.PRESET_FULL_RECT)
        dim.mouse_filter = Control.MOUSE_FILTER_STOP
        parent.add_child(dim)
        var cc := CenterContainer.new()
        cc.set_anchors_preset(Control.PRESET_FULL_RECT)
        cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        parent.add_child(cc)
        var pc := PanelContainer.new()
        var sb := panel_style(CARD, 30, 30)
        pc.add_theme_stylebox_override("panel", sb)
        if sheet_height > 0:
                pc.custom_minimum_size = Vector2(620, sheet_height)
        cc.add_child(pc)
        var vbox := VBoxContainer.new()
        vbox.add_theme_constant_override("separation", 16)
        pc.add_child(vbox)
        return vbox

## Confetti burst on a Control layer (unlock moments, new bests).
static func confetti(parent: Control, at: Vector2, n := 26) -> void:
        var colors := [ACCENT, HOT, GOOD, COIN, Color("6fc4e8")]
        for i in n:
                var r := ColorRect.new()
                r.color = colors[i % colors.size()]
                r.size = Vector2(10, 10)
                r.rotation = randf() * TAU
                r.position = at
                r.mouse_filter = Control.MOUSE_FILTER_IGNORE
                parent.add_child(r)
                var dir := Vector2.from_angle(randf() * TAU) * (90.0 + randf() * 190.0)
                var tw := r.create_tween().set_parallel(true)
                tw.tween_property(r, "position", at + dir + Vector2(0, 160), 0.75 + randf() * 0.3) \
                        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
                tw.tween_property(r, "rotation", r.rotation + randf() * 6.0, 0.9)
                tw.tween_property(r, "modulate:a", 0.0, 0.35).set_delay(0.55)
                tw.chain().tween_callback(r.queue_free)

# ------------------------------------------------------- button safety system
## Sheets must NEVER let their buttons overlap each other or run off the
## screen (landscape pre-play and the game-over sheet both overflowed). One
## smart pass fixes every sheet built through Arc.sheet():
##   1. MEASURE the real content height after layout.
##   2. If it exceeds the screen, wrap everything except the last `keep_tail`
##      controls (the pinned action buttons) into a BoxScroll - so buttons
##      move apart instead of colliding, and the tail stays reachable.
##   3. Auto-register every wrapped Button as a BoxScroll tappable (BoxScroll
##      owns taps inside scrolls - an unregistered button is the "refill
##      hangs pressed forever" bug class).
##   4. CLAMP the panel inside the screen edges for any rotation / aspect.
static func fit_sheet(vb: VBoxContainer, keep_tail := 1) -> void:
        var pc: PanelContainer = vb.get_parent() as PanelContainer
        var cc: Control = (pc.get_parent() as Control) if pc != null else null
        var root: Control = (cc.get_parent() as Control) if cc != null else null
        if pc == null or cc == null or root == null:
                return
        for c in vb.get_children():
                if c is BoxScroll:
                        return      # already fitted - idempotent
        await vb.get_tree().process_frame
        if not is_instance_valid(vb) or not is_instance_valid(pc):
                return
        var avail := root.size
        if avail.y < 200.0:
                return
        var avail_h := avail.y * 0.94
        var avail_w := minf(620.0, avail.x - 24.0)
        pc.custom_minimum_size = Vector2(avail_w, 0)
        var sep := float(vb.get_theme_constant("separation"))
        var margins := 60.0                    # panel_style(CARD, 30, 30)
        var need := vb.get_combined_minimum_size().y + margins
        if need <= avail_h:
                return                         # fits - nothing to do
        # sheets holding raw sliders stay untouched: BoxScroll would swallow
        # the slider drags (native overflow is the lesser evil there)
        for c in vb.get_children():
                if _has_slider(c):
                        return
        var kids := vb.get_children()
        var tail: Array = kids.slice(maxi(0, kids.size() - keep_tail))
        var tail_h := 0.0
        for c in tail:
                if c is Control:
                        tail_h += (c as Control).get_combined_minimum_size().y
        var sc := BoxScroll.new()
        sc.game_safe = true    # game-owned sheets run while the host is active
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.custom_minimum_size = Vector2(0,
                        maxf(140.0, avail_h - margins - tail_h - sep * float(keep_tail + 1)))
        var inner := VBoxContainer.new()
        inner.add_theme_constant_override("separation", int(sep))
        inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(inner)
        vb.add_child(sc)
        vb.move_child(sc, maxi(0, kids.size() - keep_tail))
        for c in kids:
                if c == sc or c in tail:
                        continue
                vb.remove_child(c)
                inner.add_child(c)
        for b in _buttons_in(sc):
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, _tap_emitter(b))

## Make an existing button LOOK disabled while staying clickable (owner rule
## for the rewarded button: after an early close it turns gray and says what
## happened, but a tap still retries the ad).
static func gray_out_button(b: Button) -> void:
        var sb := panel_style(Color(0.45, 0.42, 0.38), int(b.size.y / 2.6) if b.size.y > 0 else 24)
        sb.shadow_color = Color(0, 0, 0, 0.25)
        sb.shadow_size = 4
        sb.shadow_offset = Vector2(0, 3)
        for st in ["normal", "hover", "pressed", "disabled"]:
                b.add_theme_stylebox_override(st, sb)
        b.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
        b.add_theme_color_override("font_hover_color", Color(1, 1, 1, 0.75))
        b.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0.75))

## Undo gray_out_button - restore the palette of a fresh Arc.button.
static func repaint_button(b: Button, bg: Color) -> void:
        var sb := panel_style(bg, int(b.size.y / 2.6) if b.size.y > 0 else 24)
        sb.shadow_color = Color(0, 0, 0, 0.35)
        sb.shadow_size = 6
        sb.shadow_offset = Vector2(0, 4)
        b.add_theme_stylebox_override("normal", sb)
        var sbh := sb.duplicate() as StyleBoxFlat
        sbh.bg_color = bg.lightened(0.08)
        b.add_theme_stylebox_override("hover", sbh)
        var sbp := sb.duplicate() as StyleBoxFlat
        sbp.bg_color = bg.darkened(0.18)
        sbp.shadow_size = 2
        b.add_theme_stylebox_override("pressed", sbp)
        b.add_theme_color_override("font_color", Color.WHITE)
        b.add_theme_color_override("font_hover_color", Color.WHITE)
        b.add_theme_color_override("font_pressed_color", CARD)

## Replays a real press on a Button living inside a BoxScroll (raw emulated
## mouse is swallowed there). Toggle buttons replay a toggle instead.
static func _tap_emitter(btn: BaseButton) -> Callable:
        return func():
                if btn.toggle_mode:
                        var now := not btn.button_pressed
                        btn.set_pressed_no_signal(now)
                        btn.toggled.emit(now)
                else:
                        btn.pressed.emit()

static func _buttons_in(n: Node) -> Array:
        var out: Array = []
        var stack := [n]
        while not stack.is_empty():
                var cur: Node = stack.pop_back()
                if cur is BaseButton:
                        out.append(cur)
                for c in cur.get_children():
                        stack.append(c)
        return out

static func _has_slider(n: Node) -> bool:
        var stack := [n]
        while not stack.is_empty():
                var cur: Node = stack.pop_back()
                if cur is Slider or cur is SpinBox or cur is LineEdit or cur is TextEdit:
                        return true
                for c in cur.get_children():
                        stack.append(c)
        return false
