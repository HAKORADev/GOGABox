extends Node2D
## Menu: big juicy logo, play/skins buttons, coins, sound + music toggles.

signal play_pressed
signal shop_pressed

var skin: Dictionary
var _hud: CanvasLayer

func _ready() -> void:
        skin = Skins.get_skin(GameState.skin())
        _hud = CanvasLayer.new()
        add_child(_hud)

        var logo := Label.new()
        logo.text = "CANDY\nRUSH"
        var ls := LabelSettings.new()
        ls.font_size = 110
        ls.font_color = skin["accent"]
        ls.outline_size = 26
        ls.outline_color = Color.WHITE if not skin["dark"] else Color(0.07, 0.05, 0.12)
        ls.shadow_size = 14
        ls.shadow_color = Color(0, 0, 0, 0.25)
        ls.shadow_offset = Vector2(0, 8)
        logo.label_settings = ls
        logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        logo.position = Vector2(0, 150)
        logo.size.x = 720
        _hud.add_child(logo)

        var tag := Label.new()
        tag.text = "endless match-3"
        var tls := LabelSettings.new()
        tls.font_size = 28
        tls.font_color = skin["text"]
        tls.outline_size = 6
        tls.outline_color = Color(1, 1, 1, 0.7) if not skin["dark"] else Color(0, 0, 0, 0.5)
        tag.label_settings = tls
        tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        tag.position = Vector2(0, 400)
        tag.size.x = 720
        _hud.add_child(tag)

        var level := GameState.level()
        _button("PLAY LEVEL %d" % level, Vector2(110, 560), Vector2(500, 110), func(): play_pressed.emit(), 40)
        _button("SKINS", Vector2(110, 700), Vector2(500, 86), func(): shop_pressed.emit(), 30)

        var best := Label.new()
        best.text = "best level %d" % maxi(1, int(GameState.data["best_level"]))
        var bls := tls.duplicate()
        bls.font_size = 24
        best.label_settings = bls
        best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        best.position = Vector2(0, 810)
        best.size.x = 720
        _hud.add_child(best)

        # floating candies decoration
        for i in 7:
                var t := TextureRect.new()
                t.texture = Skins.base_texture(skin, i % 5)
                t.position = Vector2(40 + (i * 97) % 620, 900 + (i % 3) * 60)
                t.custom_minimum_size = Vector2(56, 56)
                t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                t.size = Vector2(56, 56)
                t.modulate.a = 0.85
                _hud.add_child(t)
                var tw := create_tween().set_loops()
                tw.tween_property(t, "position:y", t.position.y - 18, 1.2 + 0.2 * i) \
                                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
                tw.tween_property(t, "position:y", t.position.y, 1.2 + 0.2 * i) \
                                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

        # bottom bar: coins + toggles
        var coins := Label.new()
        coins.text = "%d coins" % GameState.coins()
        coins.label_settings = tls.duplicate()
        coins.position = Vector2(24, 1180)
        _hud.add_child(coins)
        GameState.coins_changed.connect(func(total: int): coins.text = "%d coins" % total)
        var sfx_btn := Button.new()
        sfx_btn.text = "SFX ON" if GameState.data["sound"] else "SFX OFF"
        sfx_btn.position = Vector2(300, 1170)
        sfx_btn.size = Vector2(120, 60)
        sfx_btn.pressed.connect(func():
                GameState.toggle_sound()
                sfx_btn.text = "SFX ON" if GameState.data["sound"] else "SFX OFF"
                Sfx.play("click"))
        _style_toggle(sfx_btn)
        _hud.add_child(sfx_btn)

        var music_btn := Button.new()
        music_btn.text = "MUSIC ON" if GameState.data["music"] else "MUSIC OFF"
        music_btn.position = Vector2(430, 1170)
        music_btn.size = Vector2(150, 60)
        music_btn.pressed.connect(func():
                GameState.toggle_music()
                Sfx.set_music_enabled(GameState.data["music"])
                music_btn.text = "MUSIC ON" if GameState.data["music"] else "MUSIC OFF")
        _style_toggle(music_btn)
        _hud.add_child(music_btn)
        Ads.banner_show()

func _style_toggle(b: Button) -> void:
        b.add_theme_color_override("font_color", Color.WHITE)
        b.add_theme_font_size_override("font_size", 20)
        b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
        b.add_theme_constant_override("outline_size", 4)

func _button(txt: String, pos: Vector2, size_px: Vector2, on_press: Callable, font := 26) -> Button:
        var b := Button.new()
        b.text = txt
        b.position = pos
        b.size = size_px
        var sb := StyleBoxFlat.new()
        sb.bg_color = skin["accent"]
        sb.set_corner_radius_all(int(size_px.y / 2.4))
        sb.shadow_color = Color(0, 0, 0, 0.25)
        sb.shadow_size = 8
        sb.shadow_offset = Vector2(0, 5)
        b.add_theme_stylebox_override("normal", sb)
        b.add_theme_stylebox_override("hover", sb)
        var sb2 := sb.duplicate()
        sb2.bg_color = (sb.bg_color as Color).darkened(0.15)
        sb2.shadow_size = 3
        b.add_theme_stylebox_override("pressed", sb2)
        b.add_theme_color_override("font_color", Color.WHITE)
        b.add_theme_font_size_override("font_size", font)
        b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
        b.add_theme_constant_override("outline_size", 5)
        b.pressed.connect(func():
                Sfx.play("confirm", -4.0)
                on_press.call())
        _hud.add_child(b)
        return b
