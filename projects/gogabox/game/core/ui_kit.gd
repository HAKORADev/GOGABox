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

## v040-11 THE SHEET KEY HANDSHAKE: sheet_push / menu._sheet_base publish
## the sheet's id here; the next fit_sheet hands it to the BoxScroll it
## wraps, so every sheet's list remembers its own scroll across refreshes
## (the CONTINUITY LAW in scroll_box.gd). Consumed on use.
static var pending_key := ""

static func font_big() -> FontFile:
        if _font_big == null:
                _font_big = load("res://assets/fonts/Kenney_Rocket.ttf")
        return _font_big

static func font_ui() -> FontFile:
        if _font_ui == null:
                _font_ui = load("res://assets/fonts/Kenney_Mini.ttf")
        return _font_ui

## THE NUMBER LAW, box-side (v040-8, v040-10): big counts read at a
## glance - 999 stays "999", 1500 becomes "1.50K", 2500000 becomes
## "2.50M". The store's coins_display wears the same law (kept in sync
## by the probe: both print identical digits for the same wallet).
static func short_num(n: int) -> String:
        var v := float(absi(n))
        var s := ""
        if v < 1000.0:
                s = str(n)
        elif v < 1000000.0:
                s = "%.2fK" % (v / 1000.0)
        elif v < 1000000000.0:
                s = "%.2fM" % (v / 1000000.0)
        else:
                s = "%.2fB" % (v / 1000000000.0)
        return ("-" + s) if n < 0 else s

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
## ALWAYS fits its box. Used by every feed tile + carousel card title; the
## pre-play page keeps its scroll, so it stays big there.
static func fit_label(txt: String, size: int, color: Color, max_w: float,
                use_display := true) -> Label:
        var f := font_big() if use_display else font_ui()
        var fs := fit_size(txt, size, max_w, null, use_display)
        var l := label(txt, fs, color, use_display)
        # THE OVERFLOW LAW (v0.3.9-5, the owner's squares shop round: "too
        # wide buttons while content is smaller"): a line that will not fit
        # even AT THE FLOOR size must WRAP, never stretch its column - a
        # single-line label at min width 825 pushed the whole shop column
        # wide and the 560px buttons clipped in the 560px viewport. When
        # the fitted line still overflows, the label wraps inside max_w.
        if f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_w:
                l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                l.custom_minimum_size = Vector2(max_w, 0)
                l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        return l

## v0.1.5 THE ONE MEASURER (shared, was fit_label's private loop): step a
## font size down until the rendered line lands inside `max_w`. Any screen
## with a new text spot reuses THIS - no second guess-the-width rule.
## `f == null` -> the standard Box font for `use_display`. The floor keeps
## microscopic sizes out (callers pick their own floor when they care).
static func fit_size(txt: String, size: int, max_w: float, f: Font,
                use_display := true, floor_size := 12) -> int:
        var font := f if f != null else (font_big() if use_display else font_ui())
        var fs := size
        while fs > floor_size and font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_w:
                fs -= 1
        return fs

## Rendered width of a text in the Box fonts (chips position themselves with
## this instead of guessing - the "k outside the widget" bug family).
static func text_width(txt: String, size: int, use_display := false) -> float:
        var f := font_big() if use_display else font_ui()
        return f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## v041-1 THE SAFE POLYGON LAW (the owner's log spam: "Invalid polygon data,
## triangulation failed" x1000s): the engine's triangulator refuses degenerate
## polygons (<3 UNIQUE points, or zero signed area - collinear/duplicated
## points) and prints an ERROR for every attempt. Every per-frame code-draw
## that can degenerate (ribbons, stars, swipe ghosts) rides THIS gate: a
## degenerate polygon is skipped silently instead of spamming the log.
static func safe_poly(c: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
        if c == null or pts.size() < 3:
                return
        var uniq := {}
        for p in pts:
                uniq[p] = true
        if uniq.size() < 3:
                return
        var area2 := 0.0
        for i in pts.size():
                var p1 := pts[i]
                var p2 := pts[(i + 1) % pts.size()]
                area2 += p1.x * p2.y - p2.x * p1.y
        if absf(area2) < 0.01:
                return
        c.draw_colored_polygon(pts, col)

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
        # v041-3 r2 THE BUTTON OUT-OF-RESOLUTION LAW (the owner: "internal
        # buttons and the width will let at least 10% free width, 5 from
        # each side on both positions on both platforms ... same logic of
        # dynamic smart detection like the pop-ups so a button can never
        # go out-of-resolution"):
        #   step 1 - THE MIN WIDTH ANSWERS TO THE SHEET: a row may never
        #   vote the panel wider than the tightest legal sheet inner
        #   width (SHEET_INNER_MIN) - the free width holds by
        #   construction on every seat.
        size.x = minf(size.x, SHEET_INNER_MIN)
        b.custom_minimum_size = size
        b.size = size
        #   step 2 - THE TEXT FITS THE ROW (the menu width law step 4):
        #   the font steps down (floor 14) instead of the row's min
        #   width voting the whole sheet wider.
        var fs := font_size
        var f := font_big() if use_display else font_ui()
        var fit_w := size.x - 40.0
        var fits := true
        if fit_w > 0.0:
                while fs > 14 and f.get_string_size(txt,
                                HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > fit_w:
                        fs -= 1
                fits = f.get_string_size(txt,
                                HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x <= fit_w
        b.add_theme_font_override("font", f)
        b.add_theme_font_size_override("font_size", fs)
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
        # v040-12 THE HONEST GRAY: a disabled button must LOOK dead at a
        # glance - darker slab, no shadow lift, dim text (the owner read the
        # old gray-green as "not grayed out")
        sbd.bg_color = Color(0.34, 0.32, 0.30)
        sbd.shadow_size = 0
        b.add_theme_stylebox_override("disabled", sbd)
        b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.38))
        #   step 3 - THE WRAP SEAT (the popups' own last step, AGENTS.md
        #   law 47): a line that cannot fit even AT THE FLOOR font wraps
        #   at the full fit width instead of overrunning the widget -
        #   the button grows the MEASURED height it needs, never the
        #   width. A button can never paint itself out of resolution.
        if not fits:
                b.text = ""
                var body := HBoxContainer.new()
                body.set_anchors_preset(Control.PRESET_FULL_RECT)
                body.alignment = BoxContainer.ALIGNMENT_CENTER
                body.mouse_filter = Control.MOUSE_FILTER_IGNORE
                var wl := label(txt, fs, Color.WHITE, use_display)
                wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                wl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                body.add_child(wl)
                b.add_child(body)
                var lines := maxi(1, int(ceil(f.get_string_size(txt,
                                HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
                                / maxf(fit_w, 1.0))))
                b.custom_minimum_size.y = maxf(b.custom_minimum_size.y,
                                float(lines) * (fs + 10.0) + 24.0)
        if on_press.is_valid():
                b.pressed.connect(func():
                        Jukebox.sfx("click", -4.0)
                        on_press.call())
        return b

## THE ON ROW (the owner's v0.3.9-11 law): an equipped shop item keeps its
## FULL-SIZE row seat and plainly says ON - it never collapses into a small
## colored description label (the old "%s  (ON) - %s" fit_label pattern is
## banned; see docs/AGENTS.md, THE SHELF TRUTH LAWS). A solid green card,
## same width and height as the shop's action buttons, one line: NAME  (ON).
static func on_row(txt: String, size := Vector2(560, 64), font_size := 22) \
                -> PanelContainer:
        var pc := PanelContainer.new()
        var sb := panel_style(Color("2f7a46"), int(size.y / 2.6))
        sb.shadow_color = Color(0, 0, 0, 0.25)
        sb.shadow_size = 4
        sb.shadow_offset = Vector2(0, 3)
        pc.add_theme_stylebox_override("panel", sb)
        pc.custom_minimum_size = size
        var l := label(txt, font_size, Color.WHITE)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        pc.add_child(l)
        pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        return pc

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

## Chip fed from the Meta tables (genres / subs / os). Unknown ids degrade
## to a text-only chip - modular by design.
static func meta_chip(kind: String, id: String, bg := Color(0, 0, 0, 0.14),
                font_size := 18, color := INK) -> PanelContainer:
        var txt := id
        match kind:
                "genre": txt = Meta.genre_label(id)
                "sub": txt = Meta.sub_label(id)
                "os": txt = Meta.os_label(id)
                "ctrl": txt = Meta.ctrl_label(id)
        return chip(txt, Meta.icon_for(kind, id), bg, font_size, color)

## Button with a trailing GOGACoin icon - use for EVERY coin-priced action so
## players never confuse GOGACoins with per-game currencies.
## v041-3 r2: the OUT-OF-RESOLUTION LAW rides here too - the min width
## clamps to the sheet stone, the label fits the row with the icon's seat
## subtracted (the coin icon is never squeezed out), and a line that
## cannot fit even at the floor font WRAPS (the popups' own last step).
static func coin_button(txt: String, size: Vector2, font_size := 30, bg := ACCENT,
                on_press := Callable()) -> Button:
        size.x = minf(size.x, SHEET_INNER_MIN)
        var b := button("", size, font_size, bg, on_press)
        var h := HBoxContainer.new()
        h.set_anchors_preset(Control.PRESET_FULL_RECT)
        h.alignment = BoxContainer.ALIGNMENT_CENTER
        h.add_theme_constant_override("separation", 10)
        h.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var fs := font_size
        var f := font_big()
        var fit_w := size.x - 40.0 - float(font_size + 10) - 10.0
        var fits := true
        if fit_w > 0.0:
                while fs > 14 and f.get_string_size(txt,
                                HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > fit_w:
                        fs -= 1
                fits = f.get_string_size(txt,
                                HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x <= fit_w
        var l := label(txt, fs, Color.WHITE)
        if not fits:
                l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        h.add_child(l)
        var c := TextureRect.new()
        c.texture = load("res://assets/ui/coin.png")
        c.custom_minimum_size = Vector2(font_size + 10, font_size + 10)
        c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        c.mouse_filter = Control.MOUSE_FILTER_IGNORE
        h.add_child(c)
        b.add_child(h)
        if not fits:
                var lines := maxi(1, int(ceil(f.get_string_size(txt,
                                HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
                                / maxf(fit_w, 1.0))))
                b.custom_minimum_size.y = maxf(b.custom_minimum_size.y,
                                float(lines) * (fs + 10.0) + 24.0)
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
        return chip(Box.coins_display(), "res://assets/ui/coin.png", Color(0, 0, 0, 0.4), 28, COIN)

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
        # THE READABLE LAW (v0.3.5-3): the toast wears a dark outline so it
        # speaks over the cream shop panel, the night field, ANY background
        t.add_theme_constant_override("outline_size", 10)
        t.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04, 0.9))
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
        # THE NEWEST WINS LAW (v0.3.5-3): a toast that fires while the old
        # one still hangs kills its tween - one message, never a stack
        if t.has("tw") and is_instance_valid(t["tw"]):
                (t["tw"] as Tween).kill()
        l.text = msg
        # v0.1.5 OWNER RULE ("hardcoded text size"): the popup measures the
        # REAL line against the LIVE canvas every time it fires - the font
        # steps down until every letter lands inside the safe 24px side
        # margins (floor 14, single line). Short toasts keep the base size;
        # long ones shrink themselves at any resolution the box runs at -
        # design px in, design px out (the stretch system makes the viewport
        # rect the universal ruler).
        var base: int = l.get_theme_font_size("font_size")
        if base <= 0:
                base = 28   # the overlay's default, if a theme ever hides the override
        var avail: float = maxf(240.0, l.get_viewport_rect().size.x - 48.0)
        l.add_theme_font_size_override("font_size",
                        fit_size(msg, base, avail, l.get_theme_font("font"), true, 14))
        l.modulate.a = 1.0
        var tw := l.create_tween()
        tw.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
        t["tw"] = tw
        tw.tween_interval(1.3)
        tw.tween_property(l, "modulate:a", 0.0, 0.4)

## Full-screen dim + centered sheet. Returns the inner VBox to fill.
## sheet_width > 0 overrides the default (THE MENU WIDTH LAW below).
## v041-3 THE MENU WIDTH LAW (the owner: "adding more width to all
## GOGABox-related menus ... why the fuck we even have left-right scrolling
## to normal menus like a shop or in settings or other areas ... make the
## base width itself be enough so user do not have to scroll it ... in both
## positions vertical/horizontal in phone/PC the menus will not have areas
## out-of-resolution"): the 620-px sheet was as wide as its rows, every
## wider row pushed the panel sideways and BoxScroll's horizontal drag
## (SHOW_NEVER, the bar hidden but alive) carried it - "left-right
## scrolling" in normal menus. The law:
##   1. THE BASE WIDTH IS MEASURED, NOT A CONSTANT: every sheet opens at
##      sheet_width_for(live canvas) - 82% of the design width, clamped
##      620..940 (portrait 1080 -> 885, landscape 1920 -> 940, a phone's
##      EXPAND canvas grows the spare axis only, so the clamp holds
##      everywhere and nothing can sit out of resolution). The mechanic
##      STAYS: a sheet taller than the screen still scrolls vertically,
##      and a pathological row can still push a horizontal scroll - it is
##      just never the base width's fault anymore.
##   2. THE AUTO SHEETS WEAR IT TOO: the width min is set even when the
##      height rides free (sheet_height 0) - an auto sheet used to be as
##      wide as its widest row, which is exactly how 560 became the box's
##      de-facto width.
##   3. THE ROWS FOLLOW: PanelContainer stretches its child, the VBox
##      stretches its FILL children - every 560-min row opens to the new
##      inner width with zero call-site edits (269 hardcoded rows across
##      27 games included).
##   4. THE TEXT ANSWERS TO THE ROW: Arc.button steps its font down when
##      a line cannot fit the row (floor 14) - a long row can never vote
##      the panel wider than its base again (fit_label's OVERFLOW LAW,
##      law 24, for buttons).
static func sheet_width_for(avail_x: float) -> float:
        return clampf(avail_x * 0.82, 620.0, 940.0)

## v041-3 r2 THE BUTTON OUT-OF-RESOLUTION LAW's floor stone - DERIVED,
## never guessed: portrait design 1080 -> sheet_width_for = 0.82*1080 =
## 885.6, minus the sheet panel's 30+30 content margins = 825.6 design px.
## Landscape/PC sheets clamp at 940 -> 880 inner, a phone's EXPAND canvas
## grows the SPARE axis only, and a PC's content scale never changes the
## design px - so 825 is the tightest legal seat on EVERY seat, both
## orientations, both platforms. Any row whose declared min width rides
## under this stone leaves >=5% of the viewport free on each side BY
## CONSTRUCTION (the sheet itself never exceeds the 82% base), and the
## horizontal drag mechanic stays for the pathological - it just can
## never be a normal row's fault again.
const SHEET_INNER_MIN := 825.0

static func sheet(parent: Control, sheet_height := 0.0, sheet_width := -1.0) -> VBoxContainer:
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
        # v041-3 r2: an EXPLICIT width can narrow the sheet, never widen
        # it past the measured base - no caller can vote a sheet out of
        # the 82% law (and out of the >=5%-per-side free width) anymore.
        var w := sheet_width_for(parent.size.x) if sheet_width <= 0.0 \
                        else minf(sheet_width, sheet_width_for(parent.size.x))
        pc.custom_minimum_size = Vector2(w, sheet_height)
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
static func fit_sheet(vb: VBoxContainer, keep_tail := 1, preserve_key := "") -> void:
        var pc: PanelContainer = vb.get_parent() as PanelContainer
        var cc: Control = (pc.get_parent() as Control) if pc != null else null
        var root: Control = (cc.get_parent() as Control) if cc != null else null
        if pc == null or cc == null or root == null:
                return
        # v040-11: the key handshake happens even when nothing wraps - a
        # builder that pre-rolled its own BoxScroll reads the id itself.
        var want_key := preserve_key if preserve_key != "" else pending_key
        pending_key = ""
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
        # THE MENU WIDTH LAW: the same measured width Arc.sheet opened with.
        var avail_w := minf(sheet_width_for(avail.x), avail.x - 24.0)
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
        # v040-11 THE CONTINUITY LAW: this scroll is THE list of the sheet
        # whose id sheet_push published - it remembers its offset across the
        # buy-refresh cycle (the owner's global top-jump nuke).
        sc.preserve_key = want_key
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
        sc.reinstate()

## Make an existing button LOOK disabled while staying clickable (the owner
## rule it was born for: turn gray, keep the tap alive for a retry).
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

# ------------------------------------------------------- THE INPUT KIT (v042-1)
## THE OWNER'S REPORT: on Android every writable field wrote double/triple
## and the caret jumped to the head — the Godot 4 Android IME failure class,
## caused by mutating LineEdit.text/caret mid-composition and by heavy work
## inside text_changed. THE INPUT LAW (docs/brainstorm/v042-1/MASTER.md §1a):
##   1. a LineEdit NEVER mutates its own text while it holds focus —
##      validation happens at the COMMIT DOORS (submit / focus-out / the
##      debounced commit), never per keystroke;
##   2. text_changed runs CHEAP work only — persistence rides the debounce;
##   3. the OS keyboard does the filtering (virtual_keyboard_type);
##   4. a sheet holding a focused field never rebuilds itself (the tickers
##      ask sheet_focused_field first).

## The ONE LineEdit factory. on_commit(text) = sanitize + persist (the
## commit door); on_preview(text) = cheap live read (no writes allowed).
## The commit doors: text_submitted + focus_exited + THE FLUSH (a sheet
## close flushes every field it frees - Arc.flush_fields). No per-keystroke
## timers: a timer touching a focused field IS an IME desync.
static func line(placeholder: String, value: String, max_len: int,
                keyboard_type: int, on_commit: Callable,
                on_preview := Callable()) -> LineEdit:
        var le := LineEdit.new()
        le.placeholder_text = placeholder
        le.text = value
        le.max_length = max_len
        le.custom_minimum_size = Vector2(0, 64)
        le.virtual_keyboard_type = keyboard_type
        le.add_theme_font_override("font", font_ui())
        le.add_theme_font_size_override("font_size", 24)
        le.set_meta("commit", on_commit)
        le.text_changed.connect(func(t: String):
                if on_preview.is_valid():
                        on_preview.call(t)
                # v042-1 r2 THE COMMIT-ON-CHANGE LAW: the field's word
                # lands in the store on EVERY keystroke now - the showcase
                # and the session seats read the store live, and the focus
                # tricks that silently dropped the last field's text on
                # Android are dead (the commit used to ride focus_exited,
                # which never fires when a button does not steal focus).
                # The commits write the STORE only - no field mutation,
                # no sheet rebuild: the IME's composition is never touched
                # mid-word (the input law holds).
                if on_commit.is_valid():
                        on_commit.call(t))
        le.text_submitted.connect(func(t: String):
                if on_commit.is_valid():
                        on_commit.call(t))
        le.focus_exited.connect(func():
                if on_commit.is_valid():
                        on_commit.call(le.text))
        return le

## v042-1 r2 THE SMART EXTRA-LINE LAW (the owner: "i recommend you to make
## all of writing fields and the buttons. viewing of the profile have the
## same logic of the smart extra line move from the pop-up of GOGABox
## in-app messages like the trophies or batteries, make it to make new
## lines for writing as soon as the current line is going to be full, it
## is better than letting the users scroll a horizontal one-line of
## text"): the LONG fields write in a multiline area - the text wraps to
## a new line the moment the current one fills. Same commit doors as
## Arc.line (change + the flush door), no horizontal scrolling anywhere.
static func area(placeholder: String, value: String, max_len: int,
                on_commit: Callable, min_lines := 3) -> TextEdit:
        var te := TextEdit.new()
        te.placeholder_text = placeholder
        te.text = value
        # NOTE: TextEdit has no max_length in Godot 4 - the cap rides the
        # COMMIT door below (the store write trims), never a mid-typing
        # field rewrite (the input law).
        te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
        te.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        te.scroll_fit_content_height = true
        te.custom_minimum_size = Vector2(0, 34.0 * min_lines + 26.0)
        te.add_theme_font_override("font", font_ui())
        te.add_theme_font_size_override("font_size", 24)
        te.set_meta("commit", on_commit)
        te.set_meta("cap", max_len)
        te.text_changed.connect(func():
                if on_commit.is_valid():
                        on_commit.call(te.text.substr(0, max_len)))
        return te

## THE FLUSH DOOR: every commit-carrier under `root` speaks its last word
## (call before freeing a sheet - the sheet close is a commit door).
static func flush_fields(root: Node) -> void:
        if root == null or not is_instance_valid(root):
                return
        var stack := [root]
        while not stack.is_empty():
                var n: Node = stack.pop_back()
                # v042-1 r2: TextEdit rides the same commit door (Arc.area)
                if (n is LineEdit or n is TextEdit) \
                                and (n as Control).has_meta("commit"):
                        var cb: Callable = (n as Control).get_meta("commit")
                        if cb.is_valid():
                                cb.call((n as Control).get("text"))
                for c in n.get_children():
                        stack.append(c)

static func _noop() -> void:
        pass

## Any field inside this subtree that currently holds focus (the ticker
## guard: a sheet with a focused field must not rebuild under the IME).
static func focused_field(root: Node) -> LineEdit:
        if root == null or not is_instance_valid(root):
                return null
        var stack := [root]
        while not stack.is_empty():
                var n: Node = stack.pop_back()
                if n is LineEdit and (n as LineEdit).has_focus():
                        return n
                for c in n.get_children():
                        stack.append(c)
        return null

## THE LINK VALIDATOR (the owner: "usually all links start with http... or
## ends with .something ... try to use some sort of lite tool that
## internally checks if link is valid in a friction of a second"). Pure
## string shape check - zero network. Accepts:
##   http(s)://<host>[more]   OR   a dotted-domain shape "name.tld[/more]"
## with tld >= 2 letters. Rejects emoji, spaces, "@-only", bare words.
static func link_ok(raw: String) -> bool:
        var s := raw.strip_edges()
        if s.length() < 4 or s.length() > 200:
                return false
        for ch in s:
                if ch == " " or ch.unicode_at(0) < 33:
                        return false
        var host := s
        if s.begins_with("http://"):
                host = s.substr(7)
        elif s.begins_with("https://"):
                host = s.substr(8)
        elif s.contains("://"):
                return false        # ftp:// and friends are not links here
        # strip a path/query tail, then a userinfo + port, keep the host
        var cut := host.find("/")
        if cut >= 0:
                host = host.substr(0, cut)
        cut = host.find("?")
        if cut >= 0:
                host = host.substr(0, cut)
        cut = host.rfind(":")
        if cut > 0 and host.find("]") < 0:
                host = host.substr(0, cut)
        cut = host.rfind("@")
        if cut >= 0:
                host = host.substr(cut + 1)
        if host.begins_with("www."):
                host = host.substr(4)
        # the host must be dotted words with a 2+ letter tail
        var parts := host.split(".")
        if parts.size() < 2:
                return false
        for p in parts:
                if String(p).length() == 0:
                        return false
                for ch in String(p):
                        if not (ch.is_valid_identifier() or ch == "-"):
                                # is_valid_identifier accepts digits too,
                                # which is what a domain wants here
                                if not (ch >= "0" and ch <= "9"):
                                        return false
        var tld := String(parts[parts.size() - 1])
        if tld.length() < 2:
                return false
        for ch in tld:
                if not (ch >= "a" and ch <= "z") and not (ch >= "A" and ch <= "Z"):
                        return false
        return true

## Normalize a saved link for display/open: bare "name.tld" gains https://.
static func link_open(raw: String) -> String:
        var s := raw.strip_edges()
        if s.begins_with("http://") or s.begins_with("https://"):
                return s
        return "https://" + s

## v042-1 r2 THE LINK DOMAIN HINT (the owner: "with a hint at the bottom
## of the button shows the domain of the link so users be notified, use
## the internal thing to extract main domain and any subdomains"): the
## host with its subdomains - "https://docs.google.com/spreadsheets/x"
## reads "docs.google.com", "www.twitch.tv/y" reads "www.twitch.tv"
## (the www is kept - it is a subdomain the owner asked to see), no
## scheme, no port, no path. Empty when the validator would refuse it.
static func link_domain(raw: String) -> String:
        var s := raw.strip_edges()
        var host := s
        if s.begins_with("http://"):
                host = s.substr(7)
        elif s.begins_with("https://"):
                host = s.substr(8)
        elif s.contains("://"):
                return ""
        var cut := host.find("/")
        if cut >= 0:
                host = host.substr(0, cut)
        cut = host.find("?")
        if cut >= 0:
                host = host.substr(0, cut)
        cut = host.find("#")
        if cut >= 0:
                host = host.substr(0, cut)
        cut = host.rfind(":")
        if cut > 0 and host.find("]") < 0:
                host = host.substr(0, cut)
        cut = host.rfind("@")
        if cut >= 0:
                host = host.substr(cut + 1)
        host = host.to_lower()
        if not link_ok(host):
                return ""
        return host

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
