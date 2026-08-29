extends Node2D
## GOGABox main menu. Fully anchor/container-driven so portrait AND landscape
## both lay out correctly (issue: fixed pixels left the bottom dead / cropped).
## The feed grows over time via Roadmap: games start hidden, appear as mystery
## teasers, resolve into locked/soon tiles, and get a "New!" badge until tapped.

const COIN_ICON := "res://assets/ui/coin.png"
const BANNER_SAFE := 78.0      # reserves room for the 52dp ad banner

var _layer: CanvasLayer
var _root: Control
var _margin: MarginContainer
var _vb: VBoxContainer
var _hot_row: HBoxContainer
var _hot_scroll: BoxScroll
var _grid: GridContainer
var _grid_scroll: BoxScroll
var _wallet_label: Label
var _toast: Dictionary
var _sheet_open := false
var _last_wide := false

func _ready() -> void:
        _layer = CanvasLayer.new()
        _layer.layer = -1          # menu lives UNDER games (fixes games invisible)
        add_child(_layer)

        _root = Control.new()
        _root.set_anchors_preset(Control.PRESET_FULL_RECT)
        _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _layer.add_child(_root)
        _root.resized.connect(_on_resized)

        var bg := TextureRect.new()
        bg.texture = load("res://assets/ui/bg_main.png")
        bg.set_anchors_preset(Control.PRESET_FULL_RECT)
        bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _root.add_child(bg)

        _margin = MarginContainer.new()
        _margin.set_anchors_preset(Control.PRESET_FULL_RECT)
        _margin.add_theme_constant_override("margin_left", 16)
        _margin.add_theme_constant_override("margin_right", 16)
        _margin.add_theme_constant_override("margin_top", 22)
        _margin.add_theme_constant_override("margin_bottom", int(BANNER_SAFE))
        _margin.mouse_filter = Control.MOUSE_FILTER_PASS
        _root.add_child(_margin)

        _vb = VBoxContainer.new()
        _vb.add_theme_constant_override("separation", 8)
        _margin.add_child(_vb)

        _build_top_bar()
        _build_hot_row()
        _build_grid()

        _toast = Arc.toast_overlay(_root)
        Box.coins_changed.connect(func(_t: int): _wallet_label.text = str(Box.coins()))
        Box.game_unlocked.connect(func(_id: String): _after_roadmap_change())
        Box.reveal_changed.connect(func(_id: String): _after_roadmap_change())

        Jukebox.play_music_menu()
        if not Box.meta().get("asked_notif", false):
                Box.meta()["asked_notif"] = true
                Box.save()
                Notify.request_permission()
        Roadmap.tick()
        _refresh()
        Ads.banner_show()

        # slow tick so timed mysteries resolve live
        var t := Timer.new()
        t.wait_time = 2.0
        t.autostart = true
        t.timeout.connect(func(): Roadmap.tick())
        add_child(t)

# ---------------------------------------------------------------- layout

func _on_resized() -> void:
        var s := _root.size
        var wide := s.x > s.y
        if wide != _last_wide:
                _last_wide = wide
                # swap the stretch base so UI keeps its physical size in landscape
                if GameHost.active_host == null:
                        get_window().content_scale_size = Vector2i(1280, 720) if wide \
                                        else Vector2i(720, 1280)
        _layout()

func _layout() -> void:
        var w := maxf(360.0, _root.size.x)
        var cols := clampi(int((w - 8.0) / 348.0), 2, 6)
        _grid.columns = cols

func _build_top_bar() -> void:
        var bar := HBoxContainer.new()
        bar.custom_minimum_size = Vector2(0, 74)
        bar.add_theme_constant_override("separation", 10)
        _vb.add_child(bar)

        var logo := TextureRect.new()
        logo.texture = load("res://assets/ui/logo.png")
        logo.custom_minimum_size = Vector2(240, 74)
        logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
        bar.add_child(logo)

        var spacer := Control.new()
        spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
        bar.add_child(spacer)

        var wallet := Arc.panel_style(Color(0, 0, 0, 0.42), 26, 10)
        var wchip := PanelContainer.new()
        wchip.add_theme_stylebox_override("panel", wallet)
        var wh := HBoxContainer.new()
        wh.add_theme_constant_override("separation", 10)
        wchip.add_child(wh)
        var coin := TextureRect.new()
        coin.texture = load(COIN_ICON)
        coin.custom_minimum_size = Vector2(42, 42)
        coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
        wh.add_child(coin)
        _wallet_label = Arc.label(str(Box.coins()), 30, Arc.COIN, false)
        wh.add_child(_wallet_label)
        bar.add_child(wchip)

        var trophy := _icon_button("res://assets/ui/icon_trophy.png",
                        func(): _open_trophies())
        bar.add_child(trophy)

        var gear := _icon_button("res://assets/ui/icon_gear.png",
                        func(): _open_settings())
        bar.add_child(gear)

func _icon_button(icon_path: String, cb: Callable) -> Button:
        var b := Button.new()
        b.custom_minimum_size = Vector2(64, 64)
        b.size = Vector2(64, 64)
        var sb := Arc.panel_style(Color(0.16, 0.10, 0.05, 0.85), 22)
        b.add_theme_stylebox_override("normal", sb)
        b.add_theme_stylebox_override("hover", sb)
        b.add_theme_stylebox_override("pressed", Arc.panel_style(Color(0.1, 0.06, 0.03, 0.9), 22))
        var ic := TextureRect.new()
        ic.texture = load(icon_path)
        ic.set_anchors_preset(Control.PRESET_FULL_RECT)
        ic.offset_left = 12
        ic.offset_top = 12
        ic.offset_right = -12
        ic.offset_bottom = -12
        ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(ic)
        b.pressed.connect(func():
                Jukebox.sfx("click", -4.0)
                cb.call())
        return b

func _build_hot_row() -> void:
        var hot_head := Arc.label("HOT", 32, Arc.ACCENT)
        _vb.add_child(hot_head)
        _hot_scroll = BoxScroll.new()
        _hot_scroll.custom_minimum_size = Vector2(0, 208)
        _hot_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        _vb.add_child(_hot_scroll)
        _hot_row = HBoxContainer.new()
        _hot_row.add_theme_constant_override("separation", 16)
        _hot_scroll.add_child(_hot_row)

func _build_grid() -> void:
        var all_head := Arc.label("ALL GAMES", 32, Arc.ACCENT)
        _vb.add_child(all_head)
        _grid_scroll = BoxScroll.new()
        _grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
        _grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        _vb.add_child(_grid_scroll)
        _grid = GridContainer.new()
        _grid.columns = 2
        _grid.add_theme_constant_override("h_separation", 14)
        _grid.add_theme_constant_override("v_separation", 14)
        _grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _grid_scroll.add_child(_grid)

# ---------------------------------------------------------------- feed

func _refresh() -> void:
        _layout()
        for c in _hot_row.get_children():
                _hot_row.remove_child(c)
                c.queue_free()
        for c in _grid.get_children():
                _grid.remove_child(c)
                c.queue_free()
        _hot_scroll.stop_motion()
        _grid_scroll.stop_motion()
        _hot_scroll._tappables.clear()
        _grid_scroll._tappables.clear()

        for g in GameReg.hot():
                if Roadmap.state(String(g["id"])) == "OWNED":
                        _hot_row.add_child(_hot_card(g))

        var tiles := 0
        for g in GameReg.GAMES:
                var id := String(g["id"])
                var st := Roadmap.state(id)
                if st == "HIDDEN":
                        continue
                _grid.add_child(_tile(g, st))
                tiles += 1
        if tiles == 0:
                var empty := Arc.label("play to grow your box...", 24, Color(0.55, 0.42, 0.25), false)
                empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                empty.custom_minimum_size = Vector2(0, 120)
                _grid.add_child(empty)

        _wallet_label.text = str(Box.coins())

func _after_roadmap_change() -> void:
        Roadmap.tick()
        _refresh()

func _flash(c: Control) -> void:
        c.modulate = Color(1.25, 1.2, 1.05)
        var tw := c.create_tween()
        tw.tween_property(c, "modulate", Color.WHITE, 0.16)

func _tap_tile(g: Dictionary, st: String, panel: Control) -> void:
        _flash(panel)
        var id := String(g["id"])
        if st == "LOCKED" or st == "GATED" or st == "SOON":
                if not Box.is_seen(id):
                        Box.mark_seen(id)          # "New!" disappears after first tap
                        _refresh()
        if st == "OWNED":
                _open_game_page(g)
        elif st == "LOCKED":
                _open_unlock_page(g)
        elif st == "GATED":
                _open_gated_page(g)
        elif st == "SOON":
                _open_soon_page(g)
        elif st == "MYSTERY":
                _open_mystery_page(g)

func _card_base(size: Vector2) -> Button:
        var b := Button.new()
        b.custom_minimum_size = size
        b.size = size
        b.clip_contents = true
        b.mouse_filter = Control.MOUSE_FILTER_IGNORE   # BoxScroll owns gestures
        for st in ["normal", "hover", "pressed", "disabled"]:
                var sb := Arc.panel_style(Arc.CARD, 24)
                sb.shadow_color = Color(0, 0, 0, 0.4)
                sb.shadow_size = 8
                sb.shadow_offset = Vector2(0, 5)
                if st == "pressed":
                        sb.bg_color = Arc.CARD_2
                b.add_theme_stylebox_override(st, sb)
        return b

## FIX (issue: thumbnails 10% + 90% white): the thumb fills the card ABOVE a
## fixed label strip; offsets are anchored, so any tile size works.
func _add_thumb(b: Control, g: Dictionary, label_strip: float, faded := false) -> TextureRect:
        var t := TextureRect.new()
        var path := String(g.get("thumb", ""))
        t.texture = load(path) if ResourceLoader.exists(path) else null
        t.set_anchors_preset(Control.PRESET_FULL_RECT)
        t.offset_bottom = -label_strip
        t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        t.clip_contents = true
        t.mouse_filter = Control.MOUSE_FILTER_IGNORE
        t.modulate = Color(1, 1, 1, 0.35) if faded else Color.WHITE
        b.add_child(t)
        return t

func _ribbon(b: Control, txt: String, bg: Color, top_right := true) -> void:
        var rib := Panel.new()
        rib.add_theme_stylebox_override("panel", Arc.panel_style(bg, 12))
        rib.mouse_filter = Control.MOUSE_FILTER_IGNORE
        if top_right:
                rib.set_anchors_preset(Control.PRESET_TOP_RIGHT)
                rib.offset_left = -122
                rib.offset_right = -10
        else:
                rib.set_anchors_preset(Control.PRESET_TOP_LEFT)
                rib.offset_left = 12
                rib.offset_right = 124
        rib.offset_top = 10
        rib.offset_bottom = 52
        b.add_child(rib)
        var l := Arc.label(txt, 22, Color.WHITE)
        l.set_anchors_preset(Control.PRESET_FULL_RECT)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        rib.add_child(l)

func _hot_card(g: Dictionary) -> Control:
        var b := _card_base(Vector2(300, 208))
        _add_thumb(b, g, 48)
        var name_l := Arc.label(String(g["title"]), 25, Arc.INK)
        name_l.position = Vector2(14, 160)
        name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(name_l)
        _hot_scroll.register_tappable(b, func(): _tap_tile(g, "OWNED", b))
        return b

func _tile(g: Dictionary, st: String) -> Control:
        var b := _card_base(Vector2(334, 312))
        var id := String(g["id"])
        match st:
                "OWNED":
                        _add_thumb(b, g, 70)
                        var name_l := Arc.label(String(g["title"]), 24, Arc.INK)
                        name_l.position = Vector2(14, 242)
                        name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        b.add_child(name_l)
                        var best := Box.stat(id, "best")
                        var chip_txt := "best %d" % best if best > 0 else "ready to play"
                        var chip := Arc.chip(chip_txt, "", Color(0, 0, 0, 0.12), 18, Color("8a6a40"))
                        chip.position = Vector2(14, 272)
                        b.add_child(chip)
                "LOCKED":
                        var th := _add_thumb(b, g, 70, true)
                        th.modulate = Color(1, 1, 1, 0.45)
                        var name_l := Arc.label(String(g["title"]), 24, Arc.INK)
                        name_l.position = Vector2(14, 242)
                        name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        b.add_child(name_l)
                        var price := Arc.chip("%d" % int(g["price"]), COIN_ICON,
                                        Color(0, 0, 0, 0.5), 20, Arc.COIN)
                        price.position = Vector2(226, 268)
                        b.add_child(price)
                        var lock_ic := TextureRect.new()
                        lock_ic.texture = load("res://assets/ui/icon_lock.png")
                        lock_ic.custom_minimum_size = Vector2(56, 56)
                        lock_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                        lock_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                        lock_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        lock_ic.position = Vector2(262, 16)
                        lock_ic.modulate = Color(1, 1, 1, 0.9)
                        b.add_child(lock_ic)
                        if not Box.is_seen(id):
                                _ribbon(b, "NEW!", Arc.HOT, false)
                "GATED":
                        var th := _add_thumb(b, g, 70, true)
                        th.modulate = Color(1, 1, 1, 0.22)
                        var name_l := Arc.label(String(g["title"]), 24, Color(0.45, 0.38, 0.3))
                        name_l.position = Vector2(14, 242)
                        name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        b.add_child(name_l)
                        var need := int(g.get("reveal", {}).get("needs_games", 1))
                        var chip := Arc.chip("LOCKED - own %d games" % need, "",
                                        Color(0, 0, 0, 0.4), 16, Color(1, 1, 1, 0.85))
                        chip.position = Vector2(14, 272)
                        b.add_child(chip)
                        var lock_ic := TextureRect.new()
                        lock_ic.texture = load("res://assets/ui/icon_lock.png")
                        lock_ic.custom_minimum_size = Vector2(72, 72)
                        lock_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                        lock_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                        lock_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        lock_ic.position = Vector2(131, 96)
                        b.add_child(lock_ic)
                        if not Box.is_seen(id):
                                _ribbon(b, "NEW!", Arc.HOT, false)
                "SOON":
                        _add_thumb(b, g, 70)
                        var name_l := Arc.label(String(g["title"]), 24, Arc.INK)
                        name_l.position = Vector2(14, 242)
                        name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        b.add_child(name_l)
                        _ribbon(b, "SOON", Color("6a5ab8"))
                        var tag := Arc.label(String(g["tag"]), 16, Color("8a6a40"), false)
                        tag.position = Vector2(14, 274)
                        tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        b.add_child(tag)
                        if not Box.is_seen(id):
                                _ribbon(b, "NEW!", Arc.HOT, false)
                "MYSTERY":
                        var dark := ColorRect.new()
                        dark.color = Color(0.07, 0.05, 0.04, 1.0)
                        dark.set_anchors_preset(Control.PRESET_FULL_RECT)
                        dark.offset_bottom = -70
                        dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        b.add_child(dark)
                        var q := Arc.label("?", 110, Color(0.12, 0.1, 0.09))
                        q.add_theme_color_override("font_outline_color", Color.WHITE)
                        q.add_theme_constant_override("outline_size", 6)
                        q.set_anchors_preset(Control.PRESET_FULL_RECT)
                        q.offset_bottom = -70
                        q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
                        q.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        b.add_child(q)
                        var name_l := Arc.label("?????", 24, Color(0.85, 0.8, 0.7))
                        name_l.position = Vector2(14, 242)
                        name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        b.add_child(name_l)
                        var chip := Arc.chip("mystery", "", Color(0.25, 0.16, 0.3, 1), 18, Color(1, 1, 1, 0.9))
                        chip.position = Vector2(14, 272)
                        b.add_child(chip)
        _grid_scroll.register_tappable(b, func(): _tap_tile(g, st, b))
        return b

# ---------------------------------------------------------------- sheets

func _sheet_base(h := 0.0) -> VBoxContainer:
        _sheet_open = true
        var vb := Arc.sheet(_root, h)
        return vb

func _close_sheet() -> void:
        _sheet_open = false
        # Arc.sheet() appended exactly 2 controls (dim + center) at the end
        var kids := _root.get_children()
        for i in range(maxi(0, kids.size() - 2), kids.size()):
                kids[i].queue_free()

func _sheet_height(default_h := 880.0) -> float:
        return clampf(_root.size.y * 0.88, 480.0, default_h)

# ------------------------------------------------------------ settings

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

        var reset := Arc.button("RESET ALL PROGRESS", Vector2(480, 70), 22, Arc.BAD,
                        func(): _confirm_reset_all())
        vb.add_child(reset)
        var note := Arc.label("that wipes everything, like a fresh install", 19,
                        Color("8a6a40"), false)
        note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(note)
        vb.add_child(Arc.button("CLOSE", Vector2(480, 72), 26, Arc.ACCENT,
                        func(): _close_sheet()))

func _confirm_reset_all() -> void:
        _close_sheet()
        var vb := _sheet_base()
        var t := Arc.label("WIPE EVERYTHING?", 38, Arc.BAD)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(t)
        var warn := Arc.label("coins, games, scores, achievements,\nskins and unlocks - all gone.", 22, Arc.INK, false)
        warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(warn)
        vb.add_child(Arc.button("YES, WIPE IT ALL", Vector2(480, 80), 26, Arc.BAD, func():
                Box.reset_all()
                for g in GameReg.GAMES:
                        Box.meta().erase("state_" + String(g["id"]))
                Notify.cancel_all()
                Jukebox.sfx("boom", -4.0)
                _close_sheet()
                Roadmap.tick()
                _refresh()))
        vb.add_child(Arc.button("KEEP IT", Vector2(480, 80), 26, Arc.ACCENT,
                        func(): _close_sheet()))

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

# ------------------------------------------------------------ game page

func _header_block(vb: VBoxContainer, g: Dictionary, faded := false) -> void:
        var id := String(g["id"])
        var head := HBoxContainer.new()
        head.add_theme_constant_override("separation", 18)
        vb.add_child(head)
        var thumb := TextureRect.new()
        var tp := String(g.get("thumb", ""))
        thumb.texture = load(tp) if ResourceLoader.exists(tp) else null
        thumb.custom_minimum_size = Vector2(220, 150)
        thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        thumb.clip_contents = true
        thumb.modulate = Color(1, 1, 1, 0.4) if faded else Color.WHITE
        head.add_child(thumb)
        var hv := VBoxContainer.new()
        hv.add_theme_constant_override("separation", 4)
        head.add_child(hv)
        hv.add_child(Arc.label(String(g["title"]), 34, Arc.INK))
        hv.add_child(Arc.label(String(g["tag"]), 20, Color("8a6a40"), false))
        hv.add_child(Arc.label("best %d   last %d   plays %d" % [Box.stat(id, "best"),
                        Box.stat(id, "last"), Box.stat(id, "plays")], 20, Color("6a4a28"), false))

func _open_game_page(g: Dictionary) -> void:
        if _sheet_open:
                return
        Jukebox.sfx("click", -4.0)
        var id := String(g["id"])
        var h := _sheet_height()
        var vb := _sheet_base(h)

        var scroll := BoxScroll.new()
        scroll.custom_minimum_size = Vector2(0, h - 210)
        scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
        vb.add_child(scroll)
        var content := VBoxContainer.new()
        content.add_theme_constant_override("separation", 14)
        content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        scroll.add_child(content)

        _header_block(content, g)

        var fee := int(g["fee"])
        var free_play: bool = fee > 0 and Box.coins() < Box.cheapest_owned_fee()
        var play_txt := "PLAY  -%d" % fee if (fee > 0 and not free_play) else "PLAY  FREE"
        var play_btn := Arc.button(play_txt, Vector2(540, 92), 34, Arc.ACCENT)
        content.add_child(play_btn)
        scroll.register_tappable(play_btn, func():
                Jukebox.sfx("click", -4.0)
                _close_sheet()
                GameHost.launch(self, id))

        # achievements (scrollable - some games will have tons)
        var ach: Array = g.get("ach", [])
        var got := 0
        for a in ach:
                if Box.has_achievement(id, String(a["id"])):
                        got += 1
        var a_head := Arc.label("ACHIEVEMENTS   %d / %d" % [got, ach.size()], 24, Arc.HOT)
        content.add_child(a_head)
        for a in ach:
                var done: bool = Box.has_achievement(id, String(a["id"]))
                var row := Arc.label(("+ %s  -  %s" % [String(a["title"]), String(a["desc"])])
                                if done else ("- %s  -  %s" % [String(a["title"]), String(a["desc"])]),
                                18, Arc.GOOD if done else Color("9a7a50"), false)
                row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                row.custom_minimum_size = Vector2(540, 0)
                content.add_child(row)

        var info := Arc.label("time %s   spent %d   earned %d" % [
                        Roadmap.fmt_time(_play_seconds(id)), Box.spent_in(id), Box.earned_in(id)],
                        18, Color("6a4a28"), false)
        info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        content.add_child(info)

        var reset_btn := Arc.button("RESET GAME PROGRESS", Vector2(540, 60), 20,
                        Color(0.6, 0.32, 0.24))
        content.add_child(reset_btn)
        scroll.register_tappable(reset_btn, func():
                Jukebox.sfx("click", -4.0)
                _confirm_reset(g))
        vb.add_child(Arc.button("CLOSE", Vector2(540, 64), 24, Color(0.42, 0.30, 0.16),
                        func(): _close_sheet()))

func _confirm_reset(g: Dictionary) -> void:
        _close_sheet()
        var vb := _sheet_base()
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
        vb.add_child(Arc.button("KEEP IT", Vector2(480, 80), 26, Arc.ACCENT,
                        func(): _close_sheet()))

# ------------------------------------------------------------ unlock / gated / soon / mystery

func _open_unlock_page(g: Dictionary) -> void:
        if _sheet_open:
                return
        Jukebox.sfx("click", -4.0)
        var id := String(g["id"])
        var vb := _sheet_base()
        _header_block(vb, g, true)
        var price := int(g["price"])
        vb.add_child(Arc.label("unlock with GOGACoins", 22, Color("8a6a40"), false))
        var afford := Box.coins() >= price
        var btn := Arc.button("UNLOCK  %d" % price, Vector2(540, 92), 30, Arc.GOOD, func():
                if Box.unlock_game(id, price):
                        Jukebox.jingle_win()
                        _close_sheet()
                        _after_roadmap_change()
                        _open_game_page(GameReg.get_game(id))
                else:
                        Jukebox.sfx("error", -4.0)
                        Arc.toast(_toast, "Not enough GOGACoins - play more!"))
        if not afford:
                btn.disabled = true
                vb.add_child(Arc.label("need %d more GOGACoins" % (price - Box.coins()),
                                20, Arc.BAD, false))
        vb.add_child(btn)
        vb.add_child(Arc.button("CLOSE", Vector2(540, 64), 24, Color(0.42, 0.30, 0.16),
                        func(): _close_sheet()))

func _open_gated_page(g: Dictionary) -> void:
        if _sheet_open:
                return
        Jukebox.sfx("click", -4.0)
        var need := int(g.get("reveal", {}).get("needs_games", 1))
        var vb := _sheet_base()
        _header_block(vb, g, true)
        vb.add_child(Arc.label("LOCKED", 30, Arc.BAD))
        var msg := Arc.label("this game needs %d games owned to be unlocked to buy\n(you own %d). keep growing the box!" % [need, Box.owned_count()],
                        22, Arc.INK, false)
        msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        msg.custom_minimum_size = Vector2(540, 0)
        msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(msg)
        vb.add_child(Arc.button("CLOSE", Vector2(540, 64), 24, Color(0.42, 0.30, 0.16),
                        func(): _close_sheet()))

func _open_soon_page(g: Dictionary) -> void:
        if _sheet_open:
                return
        Jukebox.sfx("click", -4.0)
        var vb := _sheet_base()
        _header_block(vb, g)
        vb.add_child(Arc.label("IN THE WORKSHOP", 30, Color("6a5ab8")))
        var msg := Arc.label("you unlocked this one's spot - the game itself\nlands in the box soon. watch this tile!", 22, Arc.INK, false)
        msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(msg)
        vb.add_child(Arc.button("CLOSE", Vector2(540, 64), 24, Color(0.42, 0.30, 0.16),
                        func(): _close_sheet()))

func _open_mystery_page(g: Dictionary) -> void:
        if _sheet_open:
                return
        Jukebox.sfx("click", -4.0)
        var id := String(g["id"])
        var rv: Dictionary = g.get("reveal", {})
        var vb := _sheet_base()
        var q := Arc.label("?", 90, Arc.ACCENT)
        q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(q)
        vb.add_child(Arc.label("MYSTERY GAME", 32, Arc.INK))

        match String(rv.get("kind", "")):
                "orders":
                        vb.add_child(Arc.label("ORDERS TO UNLOCK", 24, Arc.HOT))
                        for line in Roadmap.order_lines(id):
                                var row := Arc.label(("+ " if line["done"] else "- ") + String(line["text"])
                                                + ("   (%d/%d)" % [line["value"], line["goal"]] if not line["done"] else ""),
                                                20, Arc.GOOD if line["done"] else Color("6a4a28"), false)
                                row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                                row.custom_minimum_size = Vector2(540, 0)
                                vb.add_child(row)
                "inbox":
                        var left := Roadmap.inbox_left(id)
                        if left > 0.0:
                                var l1 := Arc.label("play %s more (total box time)\nto reveal this one" %
                                                Roadmap.fmt_clock(left), 22, Arc.INK, false)
                                l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                                vb.add_child(l1)
                        else:
                                vb.add_child(Arc.label("revealing...", 22, Arc.INK, false))
                "real":
                        var left := Roadmap.time_left(id)
                        if left > 0.0:
                                var l2 := Arc.label("reveals in %s" % Roadmap.fmt_clock(left),
                                                24, Arc.INK)
                                l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                                vb.add_child(l2)
                                var sub := Arc.label("we'll ping you when it's ready", 19, Color("8a6a40"), false)
                                sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                                vb.add_child(sub)
                                if not Notify.permission_granted():
                                        vb.add_child(Arc.button("ALLOW REMINDERS", Vector2(440, 60), 20,
                                                        Color("58a8d8"), func(): Notify.request_permission()))
                        else:
                                vb.add_child(Arc.label("revealing...", 22, Arc.INK, false))
        vb.add_child(Arc.button("CLOSE", Vector2(540, 64), 24, Color(0.42, 0.30, 0.16),
                        func(): _close_sheet()))

# ------------------------------------------------------------ trophies & stats

func _open_trophies() -> void:
        if _sheet_open:
                return
        Jukebox.sfx("click", -4.0)
        _sheet_open = true

        var dim := ColorRect.new()
        dim.color = Arc.DIM_BG
        dim.set_anchors_preset(Control.PRESET_FULL_RECT)
        dim.mouse_filter = Control.MOUSE_FILTER_STOP
        _root.add_child(dim)

        var panel := PanelContainer.new()
        panel.add_theme_stylebox_override("panel", Arc.panel_style(Arc.CARD, 26, 18))
        panel.set_anchors_preset(Control.PRESET_FULL_RECT)
        panel.offset_left = 18
        panel.offset_right = -18
        panel.offset_top = 18
        panel.offset_bottom = -18
        _root.add_child(panel)

        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 10)
        panel.add_child(v)

        var head := HBoxContainer.new()
        head.add_theme_constant_override("separation", 12)
        v.add_child(head)
        var tic := TextureRect.new()
        tic.texture = load("res://assets/ui/icon_trophy.png")
        tic.custom_minimum_size = Vector2(48, 48)
        tic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        head.add_child(tic)
        head.add_child(Arc.label("TROPHIES & STATS", 34, Arc.INK))
        var sp := Control.new()
        sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        head.add_child(sp)
        head.add_child(Arc.button("X", Vector2(64, 64), 26, Color(0.42, 0.30, 0.16),
                        func(): _close_sheet()))

        var legend := Arc.label("GAME  ·  TIME  ·  PLAYS  ·  TROPHIES  ·  SPENT  ·  EARNED  ·  LAST  ·  BEST",
                        15, Color("8a6a40"), false)
        legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        v.add_child(legend)

        var scroll := BoxScroll.new()
        scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
        v.add_child(scroll)
        var list := VBoxContainer.new()
        list.add_theme_constant_override("separation", 10)
        list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        scroll.add_child(list)

        var rows := []
        for g in GameReg.playable():
                rows.append(g)
        for g in GameReg.workshop():
                rows.append(g)

        for g in rows:
                list.add_child(_stat_row(g))

func _stat_row(g: Dictionary) -> Control:
        var id := String(g["id"])
        var owned := Box.owns_game(id)
        var row := PanelContainer.new()
        row.add_theme_stylebox_override("panel", Arc.panel_style(
                        Color(1, 1, 1, 0.55) if owned else Color(0, 0, 0, 0.10), 18, 10))
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 4)
        row.add_child(v)

        var top := HBoxContainer.new()
        top.add_theme_constant_override("separation", 12)
        v.add_child(top)
        var ic := TextureRect.new()
        var tp := String(g.get("thumb", ""))
        ic.texture = load(tp) if ResourceLoader.exists(tp) else null
        ic.custom_minimum_size = Vector2(56, 40)
        ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        ic.clip_contents = true
        ic.modulate = Color(1, 1, 1, 0.35) if not owned else Color.WHITE
        top.add_child(ic)
        var name_l := Arc.label(String(g["title"]), 22, Arc.INK if owned else Color(0.5, 0.44, 0.36))
        name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        top.add_child(name_l)

        var ach: Array = g.get("ach", [])
        var got := 0
        for a in ach:
                if Box.has_achievement(id, String(a["id"])):
                        got += 1
        var tchip := Arc.chip("%d/%d" % [got, ach.size()], "res://assets/ui/icon_trophy.png",
                        Color(0, 0, 0, 0.1), 17, Color("8a6a40"))
        top.add_child(tchip)

        var lines := "time %s   ·   plays %d" % [Roadmap.fmt_time(_play_seconds(id)), Box.stat(id, "plays")]
        lines += "\nspent %d   ·   earned %d   ·   last %d   ·   best %d" % [
                        Box.spent_in(id), Box.earned_in(id), Box.stat(id, "last"), Box.stat(id, "best")]
        var detail := Arc.label(lines, 16, Color("6a4a28"), false)
        v.add_child(detail)
        if g.get("coming_soon", false):
                var soon := Arc.label("workshop", 14, Color("6a5ab8"), false)
                v.add_child(soon)
        return row

## stored as float seconds in the slot (Box.stat is int; read raw)
func _play_seconds(id: String) -> float:
        var s: Variant = Box.data["games"].get(id, {}).get("time", 0.0)
        return float(s)

## Called by GameHost when a game session ends.
func on_game_closed() -> void:
        Ads.banner_show()
        Roadmap.tick()
        _refresh()
