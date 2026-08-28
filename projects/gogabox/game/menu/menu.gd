extends Node2D
## GOGABox main menu: HOT horizontal row + ALL GAMES vertical grid, wallet,
## settings (audio only), unlock flow, game pages. All chrome via Arc kit.

const COIN_ICON := "res://assets/ui/coin.png"
const W := 720.0

var _layer: CanvasLayer
var _root: Control
var _scroll_all: ScrollContainer
var _grid: GridContainer
var _hot_row: HBoxContainer
var _wallet_label: Label
var _toast: Dictionary
var _sheet_open := false

func _ready() -> void:
        _layer = CanvasLayer.new()
        add_child(_layer)
        _root = Control.new()
        _root.set_anchors_preset(Control.PRESET_FULL_RECT)
        _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _layer.add_child(_root)

        var bg := TextureRect.new()
        bg.texture = load("res://assets/ui/bg_main.png")
        bg.set_anchors_preset(Control.PRESET_FULL_RECT)
        bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _root.add_child(bg)

        _build_top_bar()
        _build_hot_row()
        _build_grid()
        _toast = Arc.toast_overlay(_root)
        Box.coins_changed.connect(func(t: int): _wallet_label.text = str(t))
        Box.game_unlocked.connect(func(_id: String): _refresh())
        Jukebox.play_music_menu()
        Ads.banner_show()
        _refresh()

func _build_top_bar() -> void:
        var bar := HBoxContainer.new()
        bar.position = Vector2(20, 26)
        bar.custom_minimum_size = Vector2(W - 40, 74)
        bar.add_theme_constant_override("separation", 12)
        _root.add_child(bar)

        var logo := TextureRect.new()
        logo.texture = load("res://assets/ui/logo.png")
        logo.custom_minimum_size = Vector2(250, 74)
        logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
        bar.add_child(logo)

        var spacer := Control.new()
        spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        bar.add_child(spacer)

        var wallet := PanelContainer.new()
        wallet.add_theme_stylebox_override("panel", Arc.panel_style(Color(0, 0, 0, 0.42), 26, 10))
        var wh := HBoxContainer.new()
        wh.add_theme_constant_override("separation", 10)
        wallet.add_child(wh)
        var coin := TextureRect.new()
        coin.texture = load(COIN_ICON)
        coin.custom_minimum_size = Vector2(42, 42)
        coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
        wh.add_child(coin)
        _wallet_label = Arc.label(str(Box.coins()), 30, Arc.COIN, false)
        wh.add_child(_wallet_label)
        bar.add_child(wallet)

        var gear := Arc.button("MENU", Vector2(64, 64), 20, Color(0.16, 0.10, 0.05, 0.85),
                func(): _open_settings())
        gear.text = "="
        bar.add_child(gear)

func _build_hot_row() -> void:
        var hot_title := Arc.label("HOT", 34, Arc.ACCENT)
        hot_title.position = Vector2(24, 116)
        _root.add_child(hot_title)

        var sc := ScrollContainer.new()
        sc.position = Vector2(16, 162)
        sc.size = Vector2(W - 32, 224)
        sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
        sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        _root.add_child(sc)
        _hot_row = HBoxContainer.new()
        _hot_row.add_theme_constant_override("separation", 16)
        sc.add_child(_hot_row)

func _build_grid() -> void:
        var all_title := Arc.label("ALL GAMES", 34, Arc.ACCENT)
        all_title.position = Vector2(24, 412)
        _root.add_child(all_title)

        _scroll_all = ScrollContainer.new()
        _scroll_all.position = Vector2(12, 458)
        _scroll_all.size = Vector2(W - 24, 800)
        _scroll_all.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        _scroll_all.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
        _root.add_child(_scroll_all)
        _grid = GridContainer.new()
        _grid.columns = 2
        _grid.add_theme_constant_override("h_separation", 14)
        _grid.add_theme_constant_override("v_separation", 14)
        _scroll_all.add_child(_grid)

# ------------------------------------------------------------------ tiles

func _refresh() -> void:
        for c in _hot_row.get_children():
                c.queue_free()
        for c in _grid.get_children():
                c.queue_free()

        for g in GameReg.hot():
                _hot_row.add_child(_hot_card(g))
        for g in GameReg.GAMES:
                _grid.add_child(_tile(g))

        _wallet_label.text = str(Box.coins())

func _hot_card(g: Dictionary) -> Button:
        var b := Button.new()
        b.custom_minimum_size = Vector2(300, 210)
        b.size = Vector2(300, 210)
        b.clip_contents = true
        var sb := Arc.panel_style(Arc.CARD, 26)
        sb.shadow_color = Color(0, 0, 0, 0.4)
        sb.shadow_size = 8
        sb.shadow_offset = Vector2(0, 5)
        b.add_theme_stylebox_override("normal", sb)
        b.add_theme_stylebox_override("hover", sb)
        b.add_theme_stylebox_override("pressed", Arc.panel_style(Arc.CARD_2, 26))
        b.pressed.connect(func(): _open_game_page(g))
        _add_thumb(b, g, 164)
        var name_l := Arc.label(String(g["title"]), 26, Arc.INK)
        name_l.position = Vector2(14, 166)
        b.add_child(name_l)
        return b

func _tile(g: Dictionary) -> Button:
        var locked: bool = not g.get("coming_soon", false) and not Box.owns_game(String(g["id"]))
        var b := Button.new()
        b.custom_minimum_size = Vector2(334, 286)
        b.size = Vector2(334, 286)
        b.clip_contents = true
        var sb := Arc.panel_style(Arc.CARD, 24)
        sb.shadow_color = Color(0, 0, 0, 0.4)
        sb.shadow_size = 8
        sb.shadow_offset = Vector2(0, 5)
        b.add_theme_stylebox_override("normal", sb)
        b.add_theme_stylebox_override("hover", sb)
        b.add_theme_stylebox_override("pressed", Arc.panel_style(Arc.CARD_2, 24))
        b.pressed.connect(func():
                if g.get("coming_soon", false):
                        Arc.toast(_toast, "%s is coming soon!" % String(g["title"]))
                else:
                        _open_game_page(g))
        _add_thumb(b, g, 232)

        var name_l := Arc.label(String(g["title"]), 24, Arc.INK)
        name_l.position = Vector2(14, 234)
        b.add_child(name_l)

        if g.get("coming_soon", false):
                var ribbon := Arc.label("SOON", 24, Color.WHITE)
                ribbon.position = Vector2(244, 10)
                var rib_bg := Panel.new()
                rib_bg.add_theme_stylebox_override("panel", Arc.panel_style(Color("6a5ab8"), 12))
                rib_bg.position = Vector2(238, 8)
                rib_bg.size = Vector2(88, 40)
                rib_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
                b.add_child(rib_bg)
                rib_bg.add_child(ribbon)
                var tag := Arc.label(String(g["tag"]), 17, Color("8a6a40"))
                tag.position = Vector2(14, 258)
                b.add_child(tag)
        elif locked:
                var dim := ColorRect.new()
                dim.color = Color(0.1, 0.05, 0.02, 0.55)
                dim.set_anchors_preset(Control.PRESET_FULL_RECT)
                dim.offset_bottom = -54
                dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
                b.add_child(dim)
                var lock_ic := TextureRect.new()
                lock_ic.texture = load("res://assets/ui/icon_lock.png")
                lock_ic.custom_minimum_size = Vector2(64, 64)
                lock_ic.size = Vector2(64, 64)
                lock_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                lock_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                lock_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
                lock_ic.position = Vector2(135, 84)
                b.add_child(lock_ic)
                var price := Arc.chip("%d" % int(g["price"]), COIN_ICON, Color(0, 0, 0, 0.55), 24, Arc.COIN)
                price.position = Vector2(84, 236)
                price.mouse_filter = Control.MOUSE_FILTER_IGNORE
                b.add_child(price)
        else:
                var best := Box.stat(String(g["id"]), "best")
                var chip_txt := "best %d" % best if best > 0 else "new"
                var chip := Arc.chip(chip_txt, "", Color(0, 0, 0, 0.12), 20, Color("8a6a40"))
                chip.position = Vector2(14, 240)
                b.add_child(chip)
        return b

func _add_thumb(b: Button, g: Dictionary, thumb_h: float) -> void:
        var t := TextureRect.new()
        var path := String(g.get("thumb", ""))
        t.texture = load(path) if ResourceLoader.exists(path) else null
        t.set_anchors_preset(Control.PRESET_FULL_RECT)
        t.offset_left = 0
        t.offset_top = 0
        t.offset_right = 0
        t.offset_bottom = -thumb_h
        t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        t.clip_contents = true
        t.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(t)

# ------------------------------------------------------------------ sheets

func _sheet_base(h := 0.0) -> VBoxContainer:
        _sheet_open = true
        var vb := Arc.sheet(_root, h)
        return vb

func _close_sheet() -> void:
        _sheet_open = false
        # sheet() added exactly 2 controls (dim + center) at the end
        var kids := _root.get_children()
        for i in range(maxi(0, kids.size() - 2), kids.size()):
                kids[i].queue_free()

func _open_settings() -> void:
        if _sheet_open:
                return
        Jukebox.sfx("click", -4.0)
        var vb := _sheet_base()
        var title := Arc.label("SETTINGS", 42, Arc.INK)
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(title)

        vb.add_child(_volume_row("MUSIC", Box.music_volume(), func(v: float):
                Box.set_music_volume(v)
                Jukebox.apply_volumes()))
        vb.add_child(_volume_row("SFX", Box.sfx_volume(), func(v: float):
                Box.set_sfx_volume(v)
                Jukebox.apply_volumes()
                Jukebox.sfx("coin", -2.0)))

        var note := Arc.label("that's all a game box needs", 20, Color("8a6a40"), false)
        note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(note)
        vb.add_child(Arc.button("CLOSE", Vector2(480, 80), 28, Arc.ACCENT, func(): _close_sheet()))

func _volume_row(name_: String, value: float, on_change: Callable) -> Control:
        var row := VBoxContainer.new()
        row.add_theme_constant_override("separation", 6)
        var lab := Arc.label(name_, 26, Arc.INK, false)
        row.add_child(lab)
        var slider := HSlider.new()
        slider.min_value = 0.0
        slider.max_value = 1.0
        slider.step = 0.05
        slider.value = value
        slider.custom_minimum_size = Vector2(520, 40)
        slider.value_changed.connect(func(v: float): on_change.call(v))
        row.add_child(slider)
        return row

func _open_game_page(g: Dictionary) -> void:
        if _sheet_open:
                return
        Jukebox.sfx("click", -4.0)
        var id := String(g["id"])
        var owned: bool = Box.owns_game(id)
        var vb := _sheet_base()

        var head := HBoxContainer.new()
        head.add_theme_constant_override("separation", 18)
        vb.add_child(head)
        var thumb := TextureRect.new()
        thumb.texture = load(String(g["thumb"])) if ResourceLoader.exists(String(g["thumb"])) else null
        thumb.custom_minimum_size = Vector2(240, 160)
        thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        thumb.clip_contents = true
        head.add_child(thumb)
        var hv := VBoxContainer.new()
        hv.add_theme_constant_override("separation", 4)
        head.add_child(hv)
        hv.add_child(Arc.label(String(g["title"]), 34, Arc.INK))
        hv.add_child(Arc.label(String(g["tag"]), 20, Color("8a6a40"), false))
        var stats := Arc.label("best %d\nlast %d\nplays %d" % [Box.stat(id, "best"),
                Box.stat(id, "last"), Box.stat(id, "plays")], 20, Color("6a4a28"), false)
        hv.add_child(stats)

        if owned:
                var fee := int(g["fee"])
                var free_play: bool = fee > 0 and Box.coins() < Box.cheapest_owned_fee()
                var play_txt := "PLAY  -%d" % fee if (fee > 0 and not free_play) else "PLAY  FREE"
                vb.add_child(Arc.button(play_txt, Vector2(540, 92), 34, Arc.ACCENT, func():
                        _close_sheet()
                        GameHost.launch(self, id)))
                # achievements
                var a_title := Arc.label("ACHIEVEMENTS", 22, Arc.HOT)
                a_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                vb.add_child(a_title)
                var got := 0
                for a in g.get("ach", []):
                        var done: bool = Box.has_achievement(id, String(a["id"]))
                        got += 1 if done else 0
                        var row := Arc.label(("+" if done else "- ") + String(a["title"]) + "  -  " + String(a["desc"]),
                                17, Arc.GOOD if done else Color("9a7a50"), false)
                        row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                        row.custom_minimum_size = Vector2(540, 0)
                        vb.add_child(row)
                var summary := Arc.label("%d / %d" % [got, (g.get("ach", []) as Array).size()],
                        18, Color("8a6a40"), false)
                summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                vb.add_child(summary)

                var reset := Arc.button("RESET GAME PROGRESS", Vector2(540, 60), 20, Color(0.6, 0.32, 0.24), func():
                        _confirm_reset(g))
                vb.add_child(reset)
        else:
                var price := int(g["price"])
                vb.add_child(Arc.label("unlock with GOGACoins", 22, Color("8a6a40"), false))
                vb.add_child(Arc.button("UNLOCK  %d" % price, Vector2(540, 92), 30, Arc.GOOD, func():
                        if Box.unlock_game(id, price):
                                Jukebox.jingle_win()
                                _close_sheet()
                                _refresh()
                                _open_game_page(GameReg.get_game(id))
                        else:
                                Arc.toast(_toast, "Not enough GOGACoins - play more!")))
        vb.add_child(Arc.button("CLOSE", Vector2(540, 64), 24, Color(0.42, 0.30, 0.16), func(): _close_sheet()))

func _confirm_reset(g: Dictionary) -> void:
        _close_sheet()
        var vb := _sheet_base(0.0)
        var t := Arc.label("RESET %s?" % String(g["title"]), 36, Arc.BAD)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(t)
        var warn := Arc.label("best score, achievements and progress\nfor this game will be wiped.", 22, Arc.INK, false)
        warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(warn)
        vb.add_child(Arc.button("YES, WIPE IT", Vector2(480, 80), 26, Arc.BAD, func():
                Box.reset_game(String(g["id"]))
                Jukebox.sfx("boom", -4.0)
                _close_sheet()
                _refresh()))
        vb.add_child(Arc.button("KEEP IT", Vector2(480, 80), 26, Arc.ACCENT, func(): _close_sheet()))

## Called by GameHost when a game session ends.
func on_game_closed() -> void:
        Ads.banner_show()
        _refresh()
