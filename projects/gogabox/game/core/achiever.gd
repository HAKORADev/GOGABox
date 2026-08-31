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

        var root := Control.new()
        root.set_anchors_preset(Control.PRESET_FULL_RECT)
        root.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(root)

        var panel := PanelContainer.new()
        var sb := Arc.panel_style(Color(0.14, 0.08, 0.03, 0.94), 24, 14)
        sb.border_color = Arc.ACCENT
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
        var head := Arc.label("ACHIEVEMENT UNLOCKED!", 20, Arc.ACCENT)
        v.add_child(head)
        var name_l := Arc.label("%s  -  %s" % [String(g.get("title", "")), String(ach.get("title", ""))],
                        30, Arc.CARD)
        v.add_child(name_l)
        var desc := Arc.label(String(ach.get("desc", "")), 19, Color(1, 1, 1, 0.75), false)
        v.add_child(desc)

        # v0.0.9 owner rule: trophies get their OWN longer, slower fanfare
        # (was star + win - the exact same sounds as unlocks/death).
        _animate_popup(root, panel, func():
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

        _animate_popup(root, panel, func(): Jukebox.sfx("unlock", -6.0))

## The shared slide language: park offscreen until sized, bounce in from
## above, hold, slide away. flourish_cb fires right after the bounce-in
## starts (kinds add their own sound/confetti there).
func _animate_popup(root: Control, panel: PanelContainer, flourish_cb: Callable) -> void:
        panel.custom_minimum_size = Vector2(640, 0)
        panel.position = Vector2(-10000, -10000)  # park offscreen until sized
        await get_tree().process_frame
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
