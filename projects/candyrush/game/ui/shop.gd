extends Node2D
## Skin shop: preview cards for every theme, buy with coins, equip owned.

signal back_pressed

var skin: Dictionary
var _hud: CanvasLayer

func _ready() -> void:
        skin = Skins.get_skin(GameState.skin())
        _hud = CanvasLayer.new()
        add_child(_hud)

        var title := Label.new()
        title.text = "SKINS"
        var ls := LabelSettings.new()
        ls.font_size = 54
        ls.font_color = skin["accent"]
        ls.outline_size = 14
        ls.outline_color = Color.WHITE if not skin["dark"] else Color(0, 0, 0, 0.6)
        title.label_settings = ls
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        title.position = Vector2(0, 60)
        title.size.x = 720
        _hud.add_child(title)

        var coins := Label.new()
        coins.text = "%d coins" % GameState.coins()
        var cls := ls.duplicate()
        cls.font_size = 28
        cls.font_color = skin["text"]
        cls.outline_size = 6
        cls.outline_color = Color(1, 1, 1, 0.7) if not skin["dark"] else Color(0, 0, 0, 0.5)
        coins.label_settings = cls
        coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        coins.position = Vector2(0, 130)
        coins.size.x = 720
        _hud.add_child(coins)
        GameState.coins_changed.connect(func(total: int): coins.text = "%d coins" % total)

        var y := 190.0
        for entry in GameState.SKINS:
                _card(entry, y)
                y += 210.0

        _toast = _label("", 26, Color("e83a3a"), Vector2(0, 1120), 720)
        _toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _toast.modulate.a = 0.0

        _button("< BACK", Vector2(24, 1176), Vector2(160, 70), func(): back_pressed.emit(), 28)

func _card(entry: Dictionary, y: float) -> void:
        var s := Skins.get_skin(entry["id"])
        var card := Panel.new()
        var sb := StyleBoxFlat.new()
        sb.bg_color = s["panel"]
        sb.set_corner_radius_all(22)
        card.add_theme_stylebox_override("panel", sb)
        card.position = Vector2(30, y)
        card.size = Vector2(660, 190)
        # decorative panels must never eat board/card taps (mouse_filter STOP bug)
        card.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _hud.add_child(card)

        # preview: the 5 pieces on this skin's frame color
        for i in 5:
                var t := TextureRect.new()
                t.texture = Skins.base_texture(s, i)
                t.position = Vector2(26 + i * 62, 24)
                t.custom_minimum_size = Vector2(54, 54)
                t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                t.size = Vector2(54, 54)
                t.mouse_filter = Control.MOUSE_FILTER_IGNORE
                card.add_child(t)

        var name_l := Label.new()
        name_l.text = s["name"]
        var nls := LabelSettings.new()
        nls.font_size = 30
        nls.font_color = s["text"]
        name_l.label_settings = nls
        name_l.position = Vector2(26, 92)
        name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        card.add_child(name_l)

        var state := "EQUIPPED"
        if not GameState.owns(entry["id"]):
                state = "%d coins" % int(entry["price"])
        var st := Label.new()
        st.text = state
        var sls := nls.duplicate()
        sls.font_size = 24
        sls.font_color = s["accent"] if GameState.owns(entry["id"]) else s["text"]
        st.label_settings = sls
        st.position = Vector2(26, 132)
        st.mouse_filter = Control.MOUSE_FILTER_IGNORE
        card.add_child(st)

        # the WHOLE card is tappable: equip if owned, else try to buy
        var tap := Button.new()
        tap.flat = true
        tap.position = Vector2.ZERO
        tap.size = Vector2(660, 190)
        tap.self_modulate = Color(1, 1, 1, 0)
        tap.pressed.connect(func(): _skin_action(entry["id"], int(entry["price"])))
        card.add_child(tap)

        var btn := Button.new()
        btn.position = Vector2(480, 100)
        btn.size = Vector2(150, 66)
        btn.mouse_filter = Control.MOUSE_FILTER_IGNORE  # card tap handles it; btn is visual
        btn.focus_mode = Control.FOCUS_NONE
        var owned: bool = GameState.owns(entry["id"])
        var equipped: bool = GameState.skin() == entry["id"]
        btn.text = "EQUIP" if owned else "BUY"
        btn.disabled = equipped
        var sb2 := StyleBoxFlat.new()
        sb2.bg_color = s["accent"] if not equipped else Color(0.5, 0.5, 0.5, 0.5)
        sb2.set_corner_radius_all(16)
        btn.add_theme_stylebox_override("normal", sb2)
        btn.add_theme_stylebox_override("hover", sb2)
        btn.add_theme_stylebox_override("disabled", sb2)
        btn.add_theme_color_override("font_color", Color.WHITE)
        btn.add_theme_font_size_override("font_size", 24)
        card.add_child(btn)

        # live-refresh the card label + button when state changes
        GameState.skin_changed.connect(func(_id: String):
                var now_owned: bool = GameState.owns(entry["id"])
                var now_eq: bool = GameState.skin() == entry["id"]
                btn.text = "EQUIP" if now_owned else "BUY"
                btn.disabled = now_eq
                st.text = "EQUIPPED" if now_eq else ("%d coins" % int(entry["price"]) if not now_owned else "OWNED"))

func _skin_action(id: String, price: int) -> void:
        if GameState.skin() == id:
                return
        if GameState.owns(id):
                Sfx.play("confirm", -4.0)
                GameState.equip(id)
        elif GameState.buy(id, price):
                Sfx.play("buy")
                _toast_msg("Skin unlocked!")
        else:
                Sfx.play("error", -4.0)
                _toast_msg("Not enough coins - need %d" % price)

func _toast_msg(msg: String) -> void:
        _toast.text = msg
        _toast.modulate.a = 1.0
        var tw := create_tween()
        tw.tween_interval(1.2)
        tw.tween_property(_toast, "modulate:a", 0.0, 0.4)

func _label(txt: String, size_px: int, color: Color, pos: Vector2, width := 0.0) -> Label:
        var l := Label.new()
        l.text = txt
        var ls := LabelSettings.new()
        ls.font_size = size_px
        ls.font_color = color
        ls.outline_size = 6
        ls.outline_color = Color(1, 1, 1, 0.8) if not skin["dark"] else Color(0, 0, 0, 0.5)
        l.label_settings = ls
        l.position = pos
        if width > 0:
                l.size.x = width
        return l

func _flash(card: Panel) -> void:
        var tw := create_tween()
        tw.tween_property(card, "modulate", Color(1, 0.6, 0.6), 0.1)
        tw.tween_property(card, "modulate", Color.WHITE, 0.25)

var _toast: Label

func _button(txt: String, pos: Vector2, size_px: Vector2, on_press: Callable, font := 26) -> Button:
        var b := Button.new()
        b.text = txt
        b.position = pos
        b.size = size_px
        var sb := StyleBoxFlat.new()
        sb.bg_color = skin["accent"]
        sb.set_corner_radius_all(18)
        b.add_theme_stylebox_override("normal", sb)
        b.add_theme_stylebox_override("hover", sb)
        var sb2 := sb.duplicate()
        sb2.bg_color = (sb.bg_color as Color).darkened(0.15)
        b.add_theme_stylebox_override("pressed", sb2)
        b.add_theme_color_override("font_color", Color.WHITE)
        b.add_theme_font_size_override("font_size", font)
        b.pressed.connect(func():
                Sfx.play("click", -4.0)
                on_press.call())
        _hud.add_child(b)
        return b
