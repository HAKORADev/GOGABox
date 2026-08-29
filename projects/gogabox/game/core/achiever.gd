class_name Achiever
extends CanvasLayer
## Box-wide achievement celebration. ONE instance (built by main.gd) floats
## above everything (layer 90). Games never touch it directly - they call
## check_achievements() and GogaGame routes new grants here.
##
##   Achiever.award("snake", {"title": "Snack Time", "desc": "..."})

static var instance: Achiever = null

var _queue: Array = []
var _busy := false

static func award(game_id: String, ach: Dictionary) -> void:
        if instance != null and is_instance_valid(instance):
                instance._push(game_id, ach)

func _ready() -> void:
        layer = 90
        instance = self

func _push(game_id: String, ach: Dictionary) -> void:
        _queue.append({"game": game_id, "ach": ach})
        if not _busy:
                _next()

func _next() -> void:
        if _queue.is_empty():
                _busy = false
                return
        _busy = true
        var item: Dictionary = _queue.pop_front()
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

        # slide from above the screen, bounce, hold, slide away
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
        Jukebox.sfx("star", -2.0)
        Jukebox.sfx("win", -6.0)
        Arc.confetti(root, Vector2(pw / 2.0, 90), 18)
        tw.tween_interval(2.1)
        tw.tween_property(panel, "position:y", -panel.size.y - 30.0, 0.35) \
                        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
        tw.tween_callback(func():
                        root.queue_free()
                        _next())
