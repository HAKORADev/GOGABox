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

static func coin_chip() -> PanelContainer:
        return chip(str(Box.coins()), "res://assets/ui/coin.png", Color(0, 0, 0, 0.4), 28, COIN)

static func toast_overlay(parent: Control) -> Dictionary:
        var t := label("", 28, CARD)
        t.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
        offset_bottom_safe(t)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        t.modulate.a = 0.0
        parent.add_child(t)
        return {"label": t}

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
