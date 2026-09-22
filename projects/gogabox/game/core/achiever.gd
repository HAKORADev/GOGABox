class_name Achiever
extends CanvasLayer
## Box-wide celebration popups. ONE instance (built by main.gd) floats
## above everything (layer 90). Games never touch it directly - they call
## check_achievements() and GogaGame routes new grants here.
##
##   Achiever.award("snake", {"title": "Snack Time", "desc": "..."})
##
## v0.1.9: also home of the BATTERY FULL popup (owner: "a pop-up notification
## like the achievement one but for game batteries, to tell the user what
## exact game got its battery capacity full"). The Box emits
## battery_full_reached(title) and this layer paints it in the same
## slide-from-the-top language. Both kinds share one queue so they never
## overlap on screen.

static var instance: Achiever = null
var _queue: Array = []
var _busy := false

static func award(game_id: String, ach: Dictionary) -> void:
        if instance != null and is_instance_valid(instance):
                instance._push({"kind": "ach", "game": game_id, "ach": ach})

## title "" = the BOX BANK filled (not a game pool).
static func battery_full(title := "") -> void:
        if instance != null and is_instance_valid(instance):
                instance._push({"kind": "batt", "title": title})

func _ready() -> void:
        layer = 90
        instance = self
        # v0.1.9: the popup can fire anywhere in the box (menu OR mid-run),
        # so the connection lives here with the popup itself.
        if not Box.battery_full_reached.is_connected(_on_battery_full):
                Box.battery_full_reached.connect(_on_battery_full)

func _on_battery_full(title: String) -> void:
        battery_full(title)

func _push(item: Dictionary) -> void:
        _queue.append(item)
        if not _busy:
                _next()

func _next() -> void:
        if _queue.is_empty():
                _busy = false
                return
        _busy = true
        var item: Dictionary = _queue.pop_front()
        if String(item.get("kind", "ach")) == "batt":
                _paint_battery(item)
        else:
                _paint_achievement(item)

func _paint_achievement(item: Dictionary) -> void:
        var g := GameReg.get_game(String(item["game"]))
        var ach: Dictionary = item["ach"]
        # v0.3.7-1 THE TIER COLORS: bronze / silver / gold / platinum ride
        # the entry's tier - the border wears the medal
        var tier := int(ach.get("tier", 1))
        var tier_col := Color("b0783c")
        var tier_name := "BRONZE"
        match tier:
                2:
                        tier_col = Color("a8b0bc")
                        tier_name = "SILVER"
                3:
                        tier_col = Color("e8b23a")
                        tier_name = "GOLD"
                4:
                        tier_col = Color("7ad8e8")
                        tier_name = "PLATINUM"

        var root := Control.new()
        root.set_anchors_preset(Control.PRESET_FULL_RECT)
        root.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(root)

        var panel := PanelContainer.new()
        var sb := Arc.panel_style(Color(0.14, 0.08, 0.03, 0.94), 24, 14)
        sb.border_color = tier_col
        sb.set_border_width_all(3)
        sb.shadow_color = Color(0, 0, 0, 0.5)
        sb.shadow_size = 12
        panel.add_theme_stylebox_override("panel", sb)
        root.add_child(panel)

        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", 14)
        panel.add_child(h)

        var trophy := TextureRect.new()
        trophy.texture = load("res://assets/ui/icon_trophy.png")
        trophy.custom_minimum_size = Vector2(72, 72)
        trophy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        trophy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        trophy.mouse_filter = Control.MOUSE_FILTER_IGNORE
        h.add_child(trophy)

        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 2)
        h.add_child(v)
        var head := Arc.label("%s UNLOCKED!" % tier_name, 20, tier_col)
        v.add_child(head)
        var name_l := Arc.label("%s  -  %s" % [String(g.get("title", "")), String(ach.get("title", ""))],
                        30, Arc.CARD)
        v.add_child(name_l)
        var desc := Arc.label(String(ach.get("desc", "")), 19, Color(1, 1, 1, 0.75), false)
        v.add_child(desc)

        # v0.0.9 owner rule: trophies get their OWN longer, slower fanfare
        # (was star + win - the exact same sounds as unlocks/death).
        _fit_and_animate(root, panel, name_l, desc, 30, 19, func():
                        Jukebox.sfx("achievement", -2.0)
                        Arc.confetti(root, Vector2(panel.size.x / 2.0, 90), 18))

func _paint_battery(item: Dictionary) -> void:
        var title := String(item.get("title", ""))
        var root := Control.new()
        root.set_anchors_preset(Control.PRESET_FULL_RECT)
        root.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(root)

        var panel := PanelContainer.new()
        var sb := Arc.panel_style(Color(0.14, 0.08, 0.03, 0.94), 24, 14)
        sb.border_color = Arc.GOOD
        sb.set_border_width_all(3)
        sb.shadow_color = Color(0, 0, 0, 0.5)
        sb.shadow_size = 12
        panel.add_theme_stylebox_override("panel", sb)
        root.add_child(panel)

        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", 14)
        panel.add_child(h)

        var batt := TextureRect.new()
        batt.texture = load("res://assets/ui/icon_battery.png")
        batt.custom_minimum_size = Vector2(72, 72)
        batt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        batt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        batt.mouse_filter = Control.MOUSE_FILTER_IGNORE
        h.add_child(batt)

        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 2)
        h.add_child(v)
        var head := Arc.label("BATTERIES FULL!", 20, Arc.GOOD)
        v.add_child(head)
        var body_txt := "your GOGABattery bank is completely full!" if title == "" \
                        else "%s batteries are fully charged - back to it!" % title
        var body := Arc.label(body_txt, 26, Arc.CARD)
        v.add_child(body)

        _fit_and_animate(root, panel, body, null, 26, 19,
                        func(): Jukebox.sfx("unlock", -6.0))

# ========================================== v041-1 r7 THE COLLISION LAW
## THE OWNER'S ORDER: the popups "are making new lines blindly, there
## should be a collision detector to process and decide if extra text
## will be out-of-resolution or not, because currently i guess the logic
## is stupid letters-limiting only and it is not that smart". He was
## right, twice over - the v041-1 fix wrapped EVERY long label at a
## FIXED 640px panel, and inside that panel the text column collapsed to
## the VBox's minimum width (an autowrapping Label's min width is its
## longest WORD - without EXPAND_FILL on the VBox the HBox starves it),
## so lines broke at ~350px even when the screen had 900px of room: the
## blind new lines. And nothing ever checked the panel's HEIGHT against
## the resolution at all. The real detector, in order:
##   1. MEASURE the text against the LIVE viewport (root.size), not a
##      const: a line that fits the available width stays ONE line.
##   2. WRAP only when the measurement says the line cannot fit - at the
##      FULL available width, with the column EXPANDED to it (fewest
##      honest lines).
##   3. COLLISION-CHECK the panel's REAL parked height against the screen
##      (a panel taller than 55% of the viewport would ride off the
##      bottom) and step the font ladder down until it fits - measured,
##      not estimated; bounded, never below readable.
func _fit_and_animate(root: Control, panel: PanelContainer,
                main_l: Label, second_l: Label, main_size: int,
                second_size: int, flourish_cb: Callable) -> void:
        var main_txt := main_l.text
        var second_txt := "" if second_l == null else second_l.text
        var ladder := [[main_size, second_size], [26, 17], [22, 15]]
        var step := 0
        var f_main: FontFile = Arc.font_big() if main_l.get_theme_font(
                        "font") == Arc.font_big() else Arc.font_ui()
        var f_second: FontFile = Arc.font_ui()
        var max_panel_w := minf(root.size.x - 48.0, 940.0)
        var text_w := maxf(200.0, max_panel_w - 116.0)
        var fits := false
        while true:
                var ms: int = ladder[step][0]
                var ss: int = ladder[step][1]
                main_l.add_theme_font_size_override("font_size", ms)
                if second_l != null:
                        second_l.add_theme_font_size_override("font_size", ss)
                # (1)+(2): the width verdict against the live viewport.
                # The text column = panel max - the icon, the HBox and
                # style paddings (icon 72 + separation 14 + margins ~30).
                var w_main: float = f_main.get_string_size(main_txt,
                                HORIZONTAL_ALIGNMENT_LEFT, -1, ms).x
                var w_second := 0.0
                if second_l != null:
                        w_second = f_second.get_string_size(second_txt,
                                        HORIZONTAL_ALIGNMENT_LEFT, -1, ss).x
                fits = w_main <= text_w and w_second <= text_w
                main_l.autowrap_mode = TextServer.AUTOWRAP_OFF if fits \
                                else TextServer.AUTOWRAP_WORD_SMART
                if second_l != null:
                        second_l.autowrap_mode = TextServer.AUTOWRAP_OFF \
                                        if fits else TextServer.AUTOWRAP_WORD_SMART
                        second_l.size_flags_horizontal = \
                                        Control.SIZE_EXPAND_FILL
                main_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                # THE NARROW-COLUMN KILL: the labels' VBox must EXPAND into
                # the wrapped panel's width, or the HBox starves it down to
                # its longest word and the lines break blindly again
                var v := main_l.get_parent() as Control
                if v != null and v != panel:
                        v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                if fits:
                        panel.custom_minimum_size = Vector2(0, 0)
                else:
                        # wrap at the FULL width (fewest honest lines)
                        panel.custom_minimum_size = Vector2(max_panel_w, 0)
                # the quick ESTIMATE gates the ladder before the park (the
                # REAL verdict lands below, on the parked panel's own size)
                var lines_main := 1 if fits else int(ceil(w_main / text_w))
                var lines_second := 0
                if second_l != null:
                        lines_second = 0 if fits else int(ceil(
                                        w_second / text_w))
                var est_h := 30.0 + float(lines_main) * (ms + 10.0) \
                                + float(lines_second) * (ss + 8.0) + 60.0
                if est_h <= root.size.y * 0.55 or step >= ladder.size() - 1:
                        break
                step += 1
        # ---- park offscreen, then the REAL collision verdict ----
        panel.position = Vector2(-10000, -10000)
        await get_tree().process_frame
        var limit := root.size.y * 0.55
        while panel.size.y > limit and step < ladder.size() - 1:
                step += 1
                main_l.add_theme_font_size_override("font_size",
                                int(ladder[step][0]))
                if second_l != null:
                        second_l.add_theme_font_size_override("font_size",
                                        int(ladder[step][1]))
                await get_tree().process_frame
        # ---- the shared slide language: bounce in from above, hold,
        # slide away. flourish_cb fires right after the bounce-in starts.
        var pw: float = panel.size.x
        var cx: float = maxf(0.0, (root.size.x - pw) / 2.0)
        panel.position = Vector2(cx, -panel.size.y - 20.0)
        var target_y := 20.0
        var tw := panel.create_tween()
        tw.tween_property(panel, "position:y", target_y, 0.45) \
                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        if flourish_cb.is_valid():
                flourish_cb.call()
        tw.tween_interval(2.1)
        tw.tween_property(panel, "position:y", -panel.size.y - 30.0, 0.35) \
                        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
        tw.tween_callback(func():
                        root.queue_free()
                        _next())
