extends Node2D
## GOGABox main menu. Fully anchor/container-driven so portrait AND landscape
## both lay out correctly (issue: fixed pixels left the bottom dead / cropped).
## The feed grows over time via Roadmap: games start hidden, appear as mystery
## teasers, resolve into locked/soon tiles, and get a "New!" badge until tapped.

const COIN_ICON := "res://assets/ui/coin.png"
# v0.1.0: computed at _ready for the LIVE density (physical 52dp banner
# divided by real-px-per-logical-px) - a fixed 78 was tuned for the old 1.5x
# stretch and under-reserved once the viewport became device-native.
var banner_safe := 78.0

var _layer: CanvasLayer
var _root: Control
var _margin: MarginContainer
var _vb: VBoxContainer
# v0.0.8 THE OVERFLOW FIX: the whole feed (picks + strips + grid) lives in ONE
# outer vertical BoxScroll. v0.0.7 stacked fixed-height sections directly in
# the VBox - on landscape / short screens the total min-height exploded and
# everything clipped on top of each other ("the new HOT thing is broken and
# not proper scale"). Now any leftover space just scrolls.
var _feed_scroll: BoxScroll
var _feed_vb: VBoxContainer
# v0.0.9 CAROUSEL: one horizontal strip, swipeable left/right by TOUCH; the
# arrows switch WHICH LIST the strip shows (owner: "scrollable left-right by
# touching and left-right arrows to change list from top picks to like last
# played and not played"). The three v0.0.8 stat strips below are gone - they
# duplicated these lists ("last played twice" bug family).
const LIST_TITLES := ["TODAY'S PICKS", "LAST PLAYED", "LEAST PLAYED", "NOT PLAYED YET"]
const LIST_HINTS := ["", "play something and it lands here",
                        "every game you played lines up here",
                        "you played everything you own!"]
var _lists_data: Array = []      # [{items: [{g, stat}], ...}] rebuilt by _refresh
var _list_idx := 0
var _strip_scroll: BoxScroll
var _strip_row: HBoxContainer
var _strip_title: Label
var _dots_row: HBoxContainer
var _pick_prev: Button
var _pick_next: Button
var _grid: GridContainer
var _all_head: Label             # "ALL GAMES" -> FAVORITES / MYSTERY with the state filter
var _wallet_label: Label
var _battery_box: HBoxContainer
var _battery_last := -1          # chip rebuilds only when the count changes
var _toast: Dictionary
var _sheet_open := false
var _trophies_open := false
var _last_wide := false
## The launch router (main.gd). GameHost.launch MUST get this, not `self` -
## passing the menu was v0.0.4's big-L bug: on_game_entered lives on main.
var router: Node = null

# search filters (id arrays; empty = no filter)
var _filter_age := ""
var _filter_genre := ""
var _filter_sub := ""
var _filter_state := ""          # "" = all | "favorites" | "mystery" (single-select)

func _ready() -> void:
        banner_safe = _banner_safe_px()
        _layer = CanvasLayer.new()
        _layer.layer = -1          # menu lives UNDER games (fixes games invisible)
        add_child(_layer)

        _root = Control.new()
        _root.set_anchors_preset(Control.PRESET_FULL_RECT)
        _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _layer.add_child(_root)
        _root.resized.connect(_on_resized)

        _build_background()

        _margin = MarginContainer.new()
        _margin.set_anchors_preset(Control.PRESET_FULL_RECT)
        _margin.add_theme_constant_override("margin_left", 16)
        _margin.add_theme_constant_override("margin_right", 16)
        _margin.add_theme_constant_override("margin_top", 22)
        _margin.add_theme_constant_override("margin_bottom", int(banner_safe))
        _margin.mouse_filter = Control.MOUSE_FILTER_PASS
        _root.add_child(_margin)

        _vb = VBoxContainer.new()
        _vb.add_theme_constant_override("separation", 8)
        _margin.add_child(_vb)

        _build_top_bar()
        _build_feed()
        _build_carousel()
        _build_grid()

        _toast = Arc.toast_overlay(_root)
        Box.coins_changed.connect(func(_t: int): _wallet_label.text = str(Box.coins()))
        Box.game_unlocked.connect(func(_id: String): _after_roadmap_change())
        Box.reveal_changed.connect(func(_id: String): _after_roadmap_change())
        Box.batteries_changed.connect(_update_battery_chip)

        Jukebox.play_music_menu()
        # v0.0.7: NO auto permission ask at boot. The single system dialog is
        # far better spent the moment the player taps ALLOW REMINDERS (the
        # mystery page) - a boot-time popup gets reflex-denied and burns the
        # one ask the OS gives us.
        Roadmap.tick()
        _refresh()
        # NOTE: the banner joins only after the splash (main.gd -> on_splash_done)

        # slow tick so timed mysteries resolve live + battery chip stays honest
        var t := Timer.new()
        t.wait_time = 2.0
        t.autostart = true
        t.timeout.connect(func():
                Roadmap.tick()
                _update_battery_chip())
        add_child(t)

        _build_particles()

## Called by main.gd when the splash fully faded out.
func on_splash_done() -> void:
        Ads.banner_show()

## Android BACK (routed from main.gd): close the top-most layer, or ask to
## leave the box. Never kills the app without a confirm.
func handle_back() -> void:
        if _sheet_open:
                _close_sheet()
                return
        if _trophies_open:
                _close_sheet()
                return
        _open_quit_confirm()

func has_open_overlay() -> bool:
        return _sheet_open or _trophies_open

## The own-world switch. Hides BOTH the Node2D and the inner CanvasLayer
## (Node2D.visible does NOT propagate to CanvasLayers - verified in 4.7) and
## hard-stops all processing so BoxScroll can never swallow taps during play.
func set_active(on: bool) -> void:
        visible = on
        if _layer != null and is_instance_valid(_layer):
                _layer.visible = on
        # the toast lives on its OWN layer-100 CanvasLayer (above sheets) -
        # Node2D.visible does not reach it, hide it by hand with the box
        if _toast.has("layer") and is_instance_valid(_toast["layer"]):
                (_toast["layer"] as CanvasLayer).visible = on
        process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
        _set_feed_lock(not on)

# ---------------------------------------------------------------- layout

func _on_resized() -> void:
        # a running game owns content_scale_size (its orientation swap) - the
        # menu must not fight it from behind (signal handlers fire even while
        # process_mode is DISABLED)
        if GameHost.active_host != null:
                return
        _apply_base()
        _update_background()
        _layout()

## THE SCALING RULE (v0.1.1 universal resolution): the design is a FIXED
## 1080x2400 portrait / 2400x1080 landscape (aspect KEEP - the engine scales
## it to the window). Re-apply the matching design on EVERY resize (launch
## state, rotation, game return) so the swap is instant and total.
func _apply_base() -> void:
        var s := _root.size
        if s.x <= 0.0 or s.y <= 0.0:
                return
        var want := Vector2i(2400, 1080) if s.x > s.y else Vector2i(1080, 2400)
        var win := get_window()
        if win.content_scale_size != want:
                win.content_scale_size = want

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
        # v0.1.1: the rebuilt wordmark (un-clipped G) is a little wider - the
        # slot grows with it so the mark renders at full width, G included
        logo.custom_minimum_size = Vector2(240, 74)
        logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
        bar.add_child(logo)

        # v0.1.1 OWNER RULE: the battery bank chip sits RIGHT AFTER the logo
        # (far left) - it used to hug the coin chip and read as one crowded
        # cluster; the universal 1080 design has the room to spread out now.
        _battery_box = HBoxContainer.new()
        _battery_box.add_theme_constant_override("separation", 8)
        bar.add_child(_battery_box)

        var spacer := Control.new()
        spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
        bar.add_child(spacer)

        var wchip := PanelContainer.new()
        wchip.add_theme_stylebox_override("panel", Arc.panel_style(Color(0, 0, 0, 0.42), 26, 10))
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

        bar.add_child(_icon_button("res://assets/meta/icon_search.png",
                        func(): _open_search()))
        bar.add_child(_icon_button("res://assets/ui/icon_help.png",
                        func(): _open_help()))
        bar.add_child(_icon_button("res://assets/ui/icon_trophy.png",
                        func(): _open_trophies()))
        bar.add_child(_icon_button("res://assets/ui/icon_gear.png",
                        func(): _open_settings()))

func _update_battery_chip() -> void:
        if _battery_box == null:
                return
        var n := Box.box_batteries()
        if n == _battery_last and _battery_box.get_child_count() > 0:
                return                     # chip only rebuilds when the pool moves
        _battery_last = n
        for c in _battery_box.get_children():
                _battery_box.remove_child(c)
                c.queue_free()
        var cap := Box.box_battery_cap()
        # tappable: opens the full battery status (pools + both timers)
        var b := Button.new()
        b.custom_minimum_size = Vector2(0, 56)
        b.flat = true
        var wchip := PanelContainer.new()
        wchip.add_theme_stylebox_override("panel", Arc.panel_style(Color(0, 0, 0, 0.42), 26, 10))
        wchip.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var wh := HBoxContainer.new()
        wh.add_theme_constant_override("separation", 8)
        wchip.add_child(wh)
        wh.add_child(Arc.battery_control(n, cap, 46.0, 24.0))
        wh.add_child(Arc.label("%d/%d" % [n, cap], 24, Color(1, 1, 1, 0.9), false))
        b.add_child(wchip)
        # v0.0.9 THE OVERLAP FIX (battery sat on top of the coin chip and the
        # search icon since v0.0.6): the button had ZERO min width, so the
        # HBox reserved no room for it and its inner panel PAINTED OVER the
        # neighbours. Measure the panel and give the button its real width -
        # then the top bar lays out chip -> coin -> icons side by side.
        wchip.set_anchors_preset(Control.PRESET_FULL_RECT)
        b.custom_minimum_size = Vector2(
                        ceilf(wchip.get_combined_minimum_size().x) + 4.0, 56.0)
        b.pressed.connect(func():
                Jukebox.sfx("click", -4.0)
                _open_batteries())
        _battery_box.add_child(b)

## Full battery status: box pool + every owned charged game, with BOTH timers.
## v0.0.7: everything here is LIVE - a 1s ticker re-reads the pools and moves
## the meters/counts/countdowns while you watch (the ticker is a child of the
## sheet, so it dies with it - no cleanup needed).
func _open_batteries() -> void:
        if _sheet_open or _trophies_open:
                return
        var h := _sheet_height()
        var vb := _sheet_base(h)
        var title := Arc.label("GOGABATTERIES", 38, Arc.INK)
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(title)

        var scroll := BoxScroll.new()
        scroll.custom_minimum_size = Vector2(0, h - 210)
        scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
        vb.add_child(scroll)
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 12)
        v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        scroll.add_child(v)

        var live: Array = []   # [{meter, count, timer, id, title}] (id="" = box)

        # --- the box bank ---
        var n := Box.box_batteries()
        var cap := Box.box_battery_cap()
        var bank := PanelContainer.new()
        bank.add_theme_stylebox_override("panel", Arc.panel_style(Color(1, 1, 1, 0.55), 18, 12))
        var bv := VBoxContainer.new()
        bv.add_theme_constant_override("separation", 6)
        bank.add_child(bv)
        var bh := HBoxContainer.new()
        bh.add_theme_constant_override("separation", 12)
        bv.add_child(bh)
        var bank_meter := Arc.battery_control(n, cap, 72.0, 30.0)
        bh.add_child(bank_meter)
        var bank_lbl := Arc.label("BOX BANK   %d/%d" % [n, cap], 24, Arc.INK)
        bh.add_child(bank_lbl)
        var bt := Arc.label(_box_timer_text(), 18, Color("6a4a28"), false)
        bv.add_child(bt)
        var bn := Arc.label("+1 every 5 min  ·  charges only while GOGABox is closed",
                        16, Color("8a6a40"), false)
        bv.add_child(bn)
        v.add_child(bank)
        live.append({"meter": bank_meter, "count": bank_lbl, "timer": bt, "id": "", "title": ""})

        # --- per-game pools ---
        for g in GameReg.playable():
                var id := String(g["id"])
                if not Box.owns_game(id):
                        continue
                var b := Box.game_battery(id)
                if b.is_empty():
                        continue
                var row := PanelContainer.new()
                row.add_theme_stylebox_override("panel", Arc.panel_style(Color(1, 1, 1, 0.4), 18, 12))
                var rv := VBoxContainer.new()
                rv.add_theme_constant_override("separation", 6)
                row.add_child(rv)
                var rh := HBoxContainer.new()
                rh.add_theme_constant_override("separation", 12)
                rv.add_child(rh)
                var gm := Arc.battery_control(int(b["count"]), int(b["cap"]), 72.0, 30.0)
                rh.add_child(gm)
                var gl := Arc.label("%s   %d/%d" % [String(g["title"]).to_upper(), int(b["count"]), int(b["cap"])], 22, Arc.INK)
                rh.add_child(gl)
                var gt := Arc.label("%d per round  ·  +1 every %d min  ·  %s"
                                                % [int(b["per_round"]), int(b["step"]) / 60, _pool_timer_text(int(b["count"]), int(b["cap"]), int(b["regen_in"]))],
                                                18, Color("6a4a28"), false)
                rv.add_child(gt)
                v.add_child(row)
                live.append({"meter": gm, "count": gl, "timer": gt, "id": id,
                                "title": String(g["title"]).to_upper(), "b": b})

        vb.add_child(Arc.button("CLOSE", Vector2(540, 64), 24, Color(0.42, 0.30, 0.16),
                        func(): _close_sheet()))
        Arc.fit_sheet(vb)

        # --- the live ticker ---
        var panel := vb.get_parent()
        var tick := Timer.new()
        tick.wait_time = 1.0
        tick.autostart = true
        panel.add_child(tick)
        tick.timeout.connect(func():
                if not is_instance_valid(vb):
                        return
                for e in live:
                        if not is_instance_valid(e["meter"]) or not is_instance_valid(e["count"]):
                                continue
                        var count: int
                        var ccap: int
                        var step: int
                        var extra := ""
                        var rin := 0
                        if String(e["id"]) == "":
                                count = Box.box_batteries()
                                ccap = Box.box_battery_cap()
                                step = Box.BATTERY_STEP
                                rin = Box.box_regen_in()
                                (e["count"] as Label).text = "BOX BANK   %d/%d" % [count, ccap]
                        else:
                                var bb := Box.game_battery(String(e["id"]))
                                if bb.is_empty():
                                        continue
                                count = int(bb["count"])
                                ccap = int(bb["cap"])
                                step = int(bb["step"])
                                rin = int(bb["regen_in"])
                                (e["count"] as Label).text = "%s   %d/%d" % [String(e["title"]), count, ccap]
                                extra = "%d per round  ·  +1 every %d min  ·  " % [int(bb["per_round"]), step / 60]
                        (e["meter"] as Control).get_meta("set_level").call(count, ccap)
                        (e["meter"] as Control).queue_redraw()
                        # the box bank counts AWAY time (offline-only charging);
                        # game pools keep their live regen countdowns
                        if String(e["id"]) == "":
                                (e["timer"] as Label).text = _box_timer_text()
                        else:
                                (e["timer"] as Label).text = extra + _pool_timer_text(count, ccap, rin))

## Honest countdown: seconds until THIS pool's next +1 (from its own regen
## clock), not the wall-clock 5-minute boundary the v0.0.7 build showed.
func _pool_timer_text(count: int, cap: int, regen_in: int) -> String:
        if count >= cap:
                return "FULL"
        var next_in := maxi(1, regen_in)
        var full_in := (cap - count - 1) * Box.BATTERY_STEP + next_in
        return "+1 in %s  ·  full in %s" % [Roadmap.fmt_clock(float(next_in)), Roadmap.fmt_clock(float(full_in))]

## Same, but for the BOX BANK (v0.1.1 offline-only charging): the pool only
## moves while the app is CLOSED, so the honest unit is AWAY time.
func _box_timer_text() -> String:
        var count := Box.box_batteries()
        var cap := Box.box_battery_cap()
        if count >= cap:
                return "FULL"
        var next_in := maxi(1, Box.box_regen_in())
        var full_in := (cap - count - 1) * Box.BATTERY_STEP + next_in
        return "+1 after %s away  ·  full after %s away" \
                        % [Roadmap.fmt_clock(float(next_in)), Roadmap.fmt_clock(float(full_in))]

## v0.1.1 THE 52dp Unity banner is a NATIVE view - its height is in REAL
## screen px. Convert with the REAL stretch scale: with aspect KEEP the
## engine scales the design by min(win/design) per axis (the letterbox axis
## binds). Reserve the banner + breathing room in logical units, floored.
## (headless/fake windows report size 0 -> floor only, no division blowups)
func _banner_safe_px() -> float:
        var dpi := DisplayServer.screen_get_dpi()
        var win := DisplayServer.window_get_size()
        var vp := get_viewport_rect().size
        if win.x <= 0 or win.y <= 0 or vp.x <= 0.0 or vp.y <= 0.0:
                return 64.0
        var px_per_logical := minf(float(win.x) / vp.x, float(win.y) / vp.y)
        var phys := 52.0 * dpi / 160.0 + 12.0   # the 52dp banner + breathing room
        return maxf(64.0, ceilf(phys / maxf(0.05, px_per_logical)))

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

## v0.0.8: one vertical scroll owns EVERYTHING below the top bar. Interactive
## children are registered tappables (BoxScroll owns taps - same rule as the
## game-over sheet's fit_sheet wrap).
func _build_feed() -> void:
        _feed_scroll = BoxScroll.new()
        _feed_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
        _vb.add_child(_feed_scroll)
        _feed_vb = VBoxContainer.new()
        _feed_vb.add_theme_constant_override("separation", 8)
        _feed_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        _feed_scroll.add_child(_feed_vb)

## v0.0.9 CAROUSEL (owner redesign): title + dots = WHICH list is shown;
## arrows switch the list; the cards themselves swipe left/right by touch.
## Lists: TODAY'S PICKS (daily random, OWNED only) / LAST PLAYED / LEAST
## PLAYED / NOT PLAYED YET (owned-never-played). One strip, zero duplication.
func _build_carousel() -> void:
        _strip_title = Arc.label(LIST_TITLES[0], 32, Arc.ACCENT)
        _feed_vb.add_child(_strip_title)
        # dots under the word: one per LIST, showing which list is on screen
        _dots_row = HBoxContainer.new()
        _dots_row.alignment = BoxContainer.ALIGNMENT_CENTER
        _dots_row.add_theme_constant_override("separation", 10)
        _feed_vb.add_child(_dots_row)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 10)
        _feed_vb.add_child(row)
        _pick_prev = _arrow_btn("<", func(): _list_move(-1))
        row.add_child(_pick_prev)
        # horizontal touch-scroll strip: finger drags the cards, BoxScroll adds
        # inertia and owns taps (cards are registered tappables)
        _strip_scroll = BoxScroll.new()
        _strip_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        _strip_scroll.custom_minimum_size = Vector2(0, 208)
        _strip_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(_strip_scroll)
        _strip_row = HBoxContainer.new()
        _strip_row.add_theme_constant_override("separation", 12)
        _strip_scroll.add_child(_strip_row)
        _pick_next = _arrow_btn(">", func(): _list_move(1))
        row.add_child(_pick_next)

func _arrow_btn(txt: String, cb: Callable) -> Button:
        var b := Arc.button(txt, Vector2(64, 208), 44, Color(0.16, 0.10, 0.05, 0.85), cb)
        b.mouse_filter = Control.MOUSE_FILTER_IGNORE   # feed scroll owns taps
        return b

func _list_move(dir: int) -> void:
        _list_idx = wrapi(_list_idx + dir, 0, LIST_TITLES.size())
        Jukebox.sfx("click", -4.0)
        _apply_list()

## Fill the strip with the CURRENT list (called on build + every refresh +
## every arrow press). Empty lists get a soft hint card instead of nothing.
func _apply_list() -> void:
        if _lists_data.is_empty():
                return
        _list_idx = clampi(_list_idx, 0, _lists_data.size() - 1)
        _strip_title.text = LIST_TITLES[_list_idx]
        _strip_title.visible = true
        _strip_scroll.visible = true
        # dots: one per list
        for c in _dots_row.get_children():
                _dots_row.remove_child(c)
                c.queue_free()
        for k in _lists_data.size():
                var dot := Panel.new()
                dot.custom_minimum_size = Vector2(18, 18)
                var on := k == _list_idx
                dot.add_theme_stylebox_override("panel",
                                Arc.panel_style(Arc.ACCENT if on else Color(0, 0, 0, 0.22), 9))
                dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
                _dots_row.add_child(dot)
        # cards
        for c in _strip_row.get_children():
                _strip_row.remove_child(c)
                c.queue_free()
        _strip_scroll.stop_motion()
        _strip_scroll._tappables.clear()
        _strip_scroll.scroll_horizontal = 0
        var items: Array = _lists_data[_list_idx]["items"]
        if items.is_empty():
                var hint := _card_base(Vector2(300, 208), true)
                var hl := Arc.label(LIST_HINTS[_list_idx], 22, Color(0.55, 0.42, 0.25), false)
                hl.set_anchors_preset(Control.PRESET_FULL_RECT)
                hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                hl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
                hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                hl.custom_minimum_size = Vector2(260, 0)
                hint.add_child(hl)
                _strip_row.add_child(hint)
                return
        for it in items:
                _strip_row.add_child(_strip_card(it["g"], String(it["stat"])))

## Big owned-game card for the strip: thumb + name + one stat line. ALL
## carousel lists are owned-only, so a tap opens the pre-play page.
func _strip_card(g: Dictionary, stat_txt: String) -> Control:
        var b := _card_base(Vector2(300, 208), true)
        _add_thumb(b, g, 58)
        var name_l := Arc.fit_label(String(g["title"]), 24, Arc.INK, 272)
        name_l.position = Vector2(14, 150)
        name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(name_l)
        var stat_l := Arc.label(stat_txt, 17, Color("6a4a28"), false)
        stat_l.position = Vector2(14, 180)
        stat_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(stat_l)
        _feed_scroll.register_tappable(b, func():
                Jukebox.sfx("click", -4.0)
                if Roadmap.state(String(g["id"])) == "OWNED":
                        _open_game_page(g)
                else:
                        _tap_tile(g, Roadmap.state(String(g["id"])), b))
        return b

## "3m ago / 5h ago / 2d ago" for the LAST PLAYED strip.
func _ago(ts: int) -> String:
        if ts <= 0:
                return "never"
        var s := maxi(0, int(Time.get_unix_time_from_system()) - ts)
        if s < 90:
                return "just now"
        if s < 3600:
                return "%dm ago" % (s / 60)
        if s < 86400:
                return "%dh ago" % (s / 3600)
        return "%dd ago" % (s / 86400)

func _build_grid() -> void:
        _all_head = Arc.label("ALL GAMES", 32, Arc.ACCENT)
        _feed_vb.add_child(_all_head)
        _grid = GridContainer.new()
        _grid.columns = 2
        _grid.add_theme_constant_override("h_separation", 14)
        _grid.add_theme_constant_override("v_separation", 14)
        _grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _feed_vb.add_child(_grid)

# ---------------------------------------------------------------- feed

func _refresh() -> void:
        _layout()
        for c in _grid.get_children():
                _grid.remove_child(c)
                c.queue_free()
        _feed_scroll.stop_motion()
        _feed_scroll._tappables.clear()

        # ---- carousel lists (v0.0.9: ONE strip, arrows switch the list) ----
        # TODAY'S PICKS: daily random over OWNED games only (owner rule).
        # LAST PLAYED:   owned + played, newest first (max 10).
        # LEAST PLAYED:  owned + played, fewest plays first (max 10).
        # NOT PLAYED YET: owned-never-played ONLY (owner rule: "soon" teasers
        #   never belonged here).
        var picks: Array = []
        for g in Roadmap.daily_picks():
                picks.append({"g": g, "stat": String(g["tag"])})
        var played: Array = []
        var never: Array = []
        for g in GameReg.playable():
                var gid := String(g["id"])
                if not Box.owns_game(gid):
                        continue
                var plays := Box.stat(gid, "plays")
                var ts := Box.last_played_at(gid)
                if plays > 0:
                        played.append({"g": g, "plays": plays, "ts": ts})
                else:
                        never.append({"g": g, "stat": "new game"})
        var by_recents := played.duplicate()
        by_recents.sort_custom(func(a, b): return int(a["ts"]) > int(b["ts"]))
        by_recents = by_recents.slice(0, 10)
        var last_ids := []
        for it in by_recents:
                last_ids.append(String(it["g"]["id"]))
        for it in by_recents:
                it["stat"] = _ago(int(it["ts"]))
        var by_least := []
        for it in played:
                if not last_ids.has(String(it["g"]["id"])):
                        it["stat"] = "plays %d" % int(it["plays"])
                        by_least.append(it)
        by_least.sort_custom(func(a, b):
                var pa := int(a["plays"])
                var pb := int(b["plays"])
                if pa != pb:
                        return pa < pb
                return int(a["ts"]) < int(b["ts"]))
        by_least = by_least.slice(0, 10)
        _lists_data = [
                {"items": picks},
                {"items": by_recents},
                {"items": by_least},
                {"items": never},
        ]
        _apply_list()
        # arrows are static controls but the tappable registry was cleared:
        # re-register them (BoxScroll owns every tap inside the feed scroll)
        _feed_scroll.register_tappable(_pick_prev, Arc._tap_emitter(_pick_prev))
        _feed_scroll.register_tappable(_pick_next, Arc._tap_emitter(_pick_next))

        # ---- the grid (ALL GAMES / FAVORITES / MYSTERY via the state filter)
        _all_head.text = "FAVORITES" if _filter_state == "favorites" \
                        else "MYSTERY" if _filter_state == "mystery" else "ALL GAMES"
        var tiles := 0
        # v0.1.1 OWNER FEED ORDER: owned (oldest unlock first) -> locked/soon
        # (catalog order) -> mysteries (catalog order). No more "uncanny"
        # interleaving of states.
        for row in Roadmap.feed_rows():
                var g: Dictionary = row["g"]
                var id := String(g["id"])
                var st := String(row["st"])
                match _filter_state:
                        "favorites":
                                if st != "OWNED" or not Box.is_favorite(id):
                                        continue
                        "mystery":
                                if st != "MYSTERY":
                                        continue
                if not _passes_filters(g):
                        continue
                _grid.add_child(_tile(g, st))
                tiles += 1
        if tiles == 0:
                var filtered := _filter_age != "" or _filter_genre != "" \
                                or _filter_sub != "" or _filter_state != ""
                var empty_txt := "play to grow your box..." \
                                if not filtered else "nothing matches these filters"
                var empty := Arc.label(empty_txt, 24, Color(0.55, 0.42, 0.25), false)
                empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                empty.custom_minimum_size = Vector2(0, 120)
                _grid.add_child(empty)
        _wallet_label.text = str(Box.coins())
        _update_battery_chip()

func _passes_filters(g: Dictionary) -> bool:
        # MYSTERY tiles bypass metadata filters: a black box carries no public
        # info, and filtering by genre would LEAK what the hidden game is.
        if Roadmap.state(String(g["id"])) == "MYSTERY":
                return true
        if _filter_age != "" and String(g.get("age", "everyone")) != _filter_age:
                return false
        var geo: Dictionary = g.get("genres", {})
        if _filter_genre != "" and not (_filter_genre in (geo.get("main", []) as Array)):
                return false
        if _filter_sub != "" and not (_filter_sub in (geo.get("sub", []) as Array)):
                return false
        return true

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

func _card_base(size: Vector2, ignore_mouse := true) -> Button:
        var b := Button.new()
        b.custom_minimum_size = size
        b.size = size
        b.clip_contents = true
        b.mouse_filter = Control.MOUSE_FILTER_IGNORE if ignore_mouse else Control.MOUSE_FILTER_STOP
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
        # v0.1.0 THE "k IS OUT OF THE WIDGET" FIX: the panel was a fixed
        # 112px strip while "UNLOCKED!" at font 22 measures ~135px in the
        # display font - the tail glyphs spilled out of the green widget AND
        # off the tile. Measure the REAL text and fit the panel to it; the
        # anchor pins the fixed edge so it grows inward, never off the tile.
        var txt_w := Arc.font_big().get_string_size(
                        txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
        var w := ceilf(txt_w) + 24.0
        if top_right:
                rib.set_anchors_preset(Control.PRESET_TOP_RIGHT)
                rib.offset_left = -10.0 - w
                rib.offset_right = -10
        else:
                rib.set_anchors_preset(Control.PRESET_TOP_LEFT)
                rib.offset_left = 12
                rib.offset_right = 12.0 + w
        rib.offset_top = 10
        rib.offset_bottom = 52
        b.add_child(rib)
        var l := Arc.label(txt, 22, Color.WHITE)
        l.set_anchors_preset(Control.PRESET_FULL_RECT)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        rib.add_child(l)

## Two-level feed badge (owner rule v0.0.9):
##   NEW!       orange    - the tile just APPEARED (any teaser state)
##   AVAILABLE! green     - it resolved into a BUYABLE tile (LOCKED only)
## Badges ALWAYS own the top-right corner; static ribbons (SOON) sit top-left.
## Any tap on the tile clears the level (Box.mark_seen).
func _feed_ribbon(b: Control, level: String) -> void:
        if level == "new":
                _ribbon(b, "NEW!", Arc.HOT, true)
        elif level == "unlocked":
                # v0.1.1 OWNER WORDING: "available", not "unlocked" - the tile
                # means BUYABLE, the player still has to purchase the game.
                _ribbon(b, "AVAILABLE!", Arc.GOOD, true)

## v0.1.1 OWNED-TILE CHIPS (owner spec):
##   LEFT  "ready to play" - ONLY when the pre-play PLAY button would really
##         open (Roadmap.can_play_now: fee + BOTH battery pools + window).
##         Snake never wears it (it is somehow always ready to be played).
##   RIGHT "best nn" - the best score, ALL owned games incl. snake. It used
##         to REPLACE the ready chip on the left ("ready to play" vs "best
##         nn" fighting for one slot) - now each owns its own corner.
## Bottom-RIGHT-anchored chip measured from the real text width (the "best
## nn" corner - it must never collide with the left chips).
func _right_chip(b: Control, txt: String, y: float, icon := "") -> void:
        var chip := Arc.chip(txt, icon, Color(0, 0, 0, 0.12), 18, Color("8a6a40"))
        var w := Arc.text_width(txt, 18) + 16.0
        chip.position = Vector2(334.0 - 14.0 - w, y)
        b.add_child(chip)

func _tile(g: Dictionary, st: String) -> Control:
        var b := _card_base(Vector2(334, 312))
        var id := String(g["id"])
        var bd := Box.badge(id)
        match st:
                "OWNED":
                        _add_thumb(b, g, 70)
                        var name_l := Arc.fit_label(String(g["title"]), 24, Arc.INK, 306)
                        name_l.position = Vector2(14, 242)
                        name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        b.add_child(name_l)
                        if id != "snake" and Roadmap.can_play_now(id):
                                var chip := Arc.chip("ready to play", "", Color(0, 0, 0, 0.12), 18, Color("8a6a40"))
                                chip.position = Vector2(14, 272)
                                b.add_child(chip)
                        var best := Box.stat(id, "best")
                        if best > 0:
                                _right_chip(b, "best %d" % best, 272)
                "LOCKED":
                        var th := _add_thumb(b, g, 70, true)
                        th.modulate = Color(1, 1, 1, 0.45)
                        var name_l := Arc.fit_label(String(g["title"]), 24, Arc.INK, 306)
                        name_l.position = Vector2(14, 242)
                        name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        b.add_child(name_l)
                        var price := Arc.chip("%d" % int(g["price"]), COIN_ICON,
                                        Color(0, 0, 0, 0.5), 20, Arc.COIN)
                        price.position = Vector2(226, 268)
                        b.add_child(price)
                        # lock moved TOP-LEFT: the badge owns the top-right corner
                        var lock_ic := TextureRect.new()
                        lock_ic.texture = load("res://assets/ui/icon_lock.png")
                        lock_ic.custom_minimum_size = Vector2(56, 56)
                        lock_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                        lock_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                        lock_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        lock_ic.position = Vector2(16, 16)
                        lock_ic.modulate = Color(1, 1, 1, 0.9)
                        b.add_child(lock_ic)
                        _feed_ribbon(b, bd)
                "GATED":
                        var th := _add_thumb(b, g, 70, true)
                        th.modulate = Color(1, 1, 1, 0.22)
                        var name_l := Arc.fit_label(String(g["title"]), 24, Color(0.45, 0.38, 0.3), 306)
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
                        _feed_ribbon(b, bd)
                "SOON":
                        _add_thumb(b, g, 70)
                        var name_l := Arc.fit_label(String(g["title"]), 24, Arc.INK, 260)
                        name_l.position = Vector2(14, 242)
                        name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        b.add_child(name_l)
                        # static ribbon TOP-LEFT - NEW!/UNLOCKED! own the right
                        _ribbon(b, "SOON", Color("6a5ab8"), false)
                        var tag := Arc.label(String(g["tag"]), 16, Color("8a6a40"), false)
                        tag.position = Vector2(14, 274)
                        tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        b.add_child(tag)
                        _feed_ribbon(b, bd)
                "MYSTERY":
                        var dark := ColorRect.new()
                        dark.color = Color(0.07, 0.05, 0.04, 1.0)
                        dark.set_anchors_preset(Control.PRESET_FULL_RECT)
                        dark.offset_bottom = -70
                        dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        b.add_child(dark)
                        var art := TextureRect.new()
                        art.texture = load("res://assets/ui/mystery.png")
                        art.set_anchors_preset(Control.PRESET_FULL_RECT)
                        art.offset_left = 10
                        art.offset_top = 10
                        art.offset_right = -10
                        art.offset_bottom = -80
                        art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                        art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                        art.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        b.add_child(art)
                        var name_l := Arc.label("?????", 24, Color(0.85, 0.8, 0.7))
                        name_l.position = Vector2(14, 242)
                        name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        b.add_child(name_l)
                        var chip := Arc.chip("mystery", "", Color(0.25, 0.16, 0.3, 1), 18, Color(1, 1, 1, 0.9))
                        chip.position = Vector2(14, 272)
                        b.add_child(chip)
                        # v0.1.0 owner rule: NO badge ever renders on a black
                        # box - "they are glitched in them, black boxes just
                        # stay a mystery". (v0.0.9 rendered NEW! there; the
                        # badge STATE is still tracked, just never shown here.)
        _feed_scroll.register_tappable(b, func(): _tap_tile(g, st, b))
        return b

# ------------------------------------------------------------ living bg

var _fx: Control
var _fx_dots: Array = []   # {pos, spd, size, phase}
var _fx_night := false

# v0.1.1 OWNER BRAINSTORM: the drifting neon STRIPES are gone ("i will remove
# that effect of weird strips") - the striped bg_main.png itself now drifts
# DOWN slowly instead ("the background move down slowly since it's stripped").
# A Sprite2D with a repeated region does the scroll; the pattern wraps forever.
var _bg: Sprite2D
var _bg_off := 0.0
const BG_SPEED := 14.0     # logical px per second - a slow, calm drift

func _build_background() -> void:
        _bg = Sprite2D.new()
        _bg.texture = load("res://assets/ui/bg_main.png")
        _bg.centered = false
        _bg.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
        _bg.region_enabled = true
        _root.add_child(_bg)
        _update_background()

func _update_background() -> void:
        if _bg == null or not is_instance_valid(_bg):
                return
        var vp := _root.size
        if vp.x <= 0.0 or vp.y <= 0.0:
                return
        # cover the viewport (KEEP_ASPECT_COVERED equivalent), crop the rest
        var tex := _bg.texture.get_size()
        var s := maxf(vp.x / tex.x, vp.y / tex.y)
        _bg.scale = Vector2(s, s)
        # region window = the visible slice of the (repeating) texture
        _bg.region_rect = Rect2(0, -_bg_off, vp.x / s, vp.y / s)

func _build_particles() -> void:
        _fx = Control.new()
        _fx.set_anchors_preset(Control.PRESET_FULL_RECT)
        _fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _fx.draw.connect(_draw_fx)
        _root.add_child(_fx)
        _root.move_child(_fx, 1)   # above bg, below everything interactive
        var hour := int(Time.get_time_dict_from_system()["hour"])
        _fx_night = hour >= 19 or hour < 6
        # dust spawn field uses the REAL design viewport (1080x2400)
        for i in 34:
                _fx_dots.append({
                        "pos": Vector2(randf() * _root.size.x, randf() * _root.size.y),
                        "spd": 8.0 + randf() * 16.0,
                        "size": 2.0 + randf() * 3.5,
                        "phase": randf() * TAU,
                })

func _process(delta: float) -> void:
        # the striped background drifts slowly DOWN (v0.1.1 owner brainstorm)
        if _bg != null and is_instance_valid(_bg):
                _bg_off = fmod(_bg_off + delta * BG_SPEED, 1280.0)
                var vp := _root.size
                if vp.x > 0.0 and vp.y > 0.0:
                        var s: float = _bg.scale.x
                        _bg.region_rect = Rect2(0, -_bg_off, vp.x / s, vp.y / s)
        if _fx == null or not is_instance_valid(_fx):
                return
        var vr := _root.size
        for d in _fx_dots:
                d["pos"] = d["pos"] + Vector2(sin(d["phase"] + Time.get_ticks_msec() / 1900.0) * 6.0, -d["spd"]) * delta
                if d["pos"].y < -12.0:
                        d["pos"] = Vector2(randf() * vr.x, vr.y + 12.0)
                if d["pos"].x < -12.0:
                        d["pos"].x = vr.x + 12.0
                elif d["pos"].x > vr.x + 12.0:
                        d["pos"].x = -12.0
        _fx.queue_redraw()

func _draw_fx() -> void:
        # v0.1.1: ONLY the floating dust now - the "weird strips" (the slow
        # diagonal neon lines) are REMOVED per the owner brainstorm; the
        # background motion itself is the effect now.
        var dot_col := Color(1.0, 0.85, 0.45, 0.5) if not _fx_night \
                        else Color(0.75, 0.85, 1.0, 0.5)
        for d in _fx_dots:
                _fx.draw_circle(d["pos"], d["size"], dot_col)

# ---------------------------------------------------------------- quit

func _open_quit_confirm() -> void:
        if _sheet_open or _trophies_open:
                return
        _sheet_open = true
        _set_feed_lock(true)
        var vb := Arc.sheet(_root)
        var t := Arc.label("LEAVE GOGABOX?", 40, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(t)
        var sub := Arc.label("your coins, batteries and progress\nare safe - everything saves instantly.", 21, Color("8a6a40"), false)
        sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(sub)
        vb.add_child(Arc.button("YES, BYE", Vector2(480, 80), 26, Arc.BAD, func():
                get_tree().quit()))
        vb.add_child(Arc.button("STAY", Vector2(480, 80), 26, Arc.ACCENT,
                func(): _close_sheet()))
        Arc.fit_sheet(vb, 2)

# ------------------------------------------------------------ search

func _open_search() -> void:
        if _sheet_open or _trophies_open:
                return
        Jukebox.sfx("click", -4.0)
        var h := _sheet_height()
        var vb := _sheet_base(h)
        var title := Arc.label("FIND GAMES", 40, Arc.INK)
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(title)

        # v0.0.9 owner rule: the sheet itself scrolls up-down; every filter
        # group is a titled section inside that one scroll, so adding more
        # filter kinds later just lengthens the scroll (and a group that outgrows
        # ~3 chip rows gets its own inner vertical scroll).
        var scroll := BoxScroll.new()
        scroll.custom_minimum_size = Vector2(0, h - 330)
        scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
        vb.add_child(scroll)
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 14)
        v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        scroll.add_child(v)

        v.add_child(_chip_row(scroll, "AGE", Meta.used_ages(),
                        func(id: String): _filter_age = "" if _filter_age == id else id, "age"))
        v.add_child(_chip_row(scroll, "GENRE", Meta.used_genres(),
                        func(id: String): _filter_genre = "" if _filter_genre == id else id, "genre"))
        v.add_child(_chip_row(scroll, "MORE", Meta.used_subs(),
                        func(id: String): _filter_sub = "" if _filter_sub == id else id, "sub"))
        # STATES (single-select): none -> all games; favorites -> owned hearts;
        # mystery -> the unlisted black boxes. The grid headline follows.
        v.add_child(_state_row(scroll))

        var hint := Arc.label("filters work on owned + revealed games", 18,
                        Color("8a6a40"), false)
        hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(hint)
        # v0.0.9 owner rule: with NOTHING set the apply button is gray + dead;
        # it lights up the moment any filter/state is chosen.
        var apply_btn := Arc.button("APPLY FILTERS", Vector2(480, 78), 26, Arc.ACCENT, func():
                _close_sheet()
                _refresh()
                Arc.toast(_toast, "filters applied"))
        apply_btn.disabled = not _filters_dirty()
        vb.add_child(apply_btn)
        vb.add_child(Arc.button("CLEAR", Vector2(480, 64), 24, Color(0.42, 0.30, 0.16), func():
                _filter_age = ""
                _filter_genre = ""
                _filter_sub = ""
                _filter_state = ""
                _close_sheet()
                _refresh()))

func _filters_dirty() -> bool:
        return _filter_age != "" or _filter_genre != "" or _filter_sub != "" \
                        or _filter_state != ""

## A wrapped row of proper toggle buttons (icon + label in ONE control -
## no nested Panel-in-Button hacks, that's what overlapped weirdly).
## `scroll` is the sheet's BoxScroll: chips inside it are registered
## tappables (BoxScroll owns taps - an unregistered button is a dead button).
func _chip_row(scroll: BoxScroll, title_: String, ids: Array, on_toggle: Callable, kind: String) -> Control:
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.add_child(Arc.label(title_, 22, Arc.HOT))
        var wrap := HFlowContainer.new()
        wrap.add_theme_constant_override("h_separation", 8)
        wrap.add_theme_constant_override("v_separation", 8)
        box.add_child(wrap)
        for id in ids:
                var sid := String(id)
                var active := false
                match kind:
                        "age": active = _filter_age == sid
                        "genre": active = _filter_genre == sid
                        "sub": active = _filter_sub == sid
                var lbl := ""
                match kind:
                        "genre": lbl = Meta.genre_label(sid)
                        "sub": lbl = Meta.sub_label(sid)
                        "age": lbl = Meta.age_label(sid)
                var b := Button.new()
                b.text = " " + lbl
                b.toggle_mode = true
                b.button_pressed = active
                var icon_path := Meta.icon_for(kind, sid)
                if icon_path != "" and ResourceLoader.exists(icon_path):
                        b.icon = load(icon_path)
                        b.add_theme_constant_override("icon_max_width", 26)
                b.add_theme_font_override("font", Arc.font_ui())
                b.add_theme_font_size_override("font_size", 19)
                b.add_theme_color_override("font_color", Arc.CARD if active else Color("7a5a34"))
                b.add_theme_color_override("font_pressed_color", Arc.CARD)
                var sb := Arc.panel_style(Color(0.98, 0.62, 0.1) if active else Color(0, 0, 0, 0.14), 20)
                sb.content_margin_left = 16
                sb.content_margin_right = 16
                sb.content_margin_top = 8
                sb.content_margin_bottom = 8
                b.add_theme_stylebox_override("normal", sb)
                var sbh := sb.duplicate() as StyleBoxFlat
                sbh.bg_color = sbh.bg_color.lightened(0.08)
                b.add_theme_stylebox_override("hover", sbh)
                var sbp := sb.duplicate() as StyleBoxFlat
                sbp.bg_color = Color(0.85, 0.5, 0.06)
                b.add_theme_stylebox_override("pressed", sbp)
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                b.toggled.connect(func(_on: bool):
                        Jukebox.sfx("click", -4.0)
                        on_toggle.call(sid)
                        # rebuild the sheet so every chip shows its true state
                        _close_sheet()
                        _open_search())
                scroll.register_tappable(b, Arc._tap_emitter(b))
                wrap.add_child(b)
        return box

## Single-select STATES chips: ALL / FAVORITES / MYSTERY. Tapping the active
## chip again falls back to ALL. Only one can be on at any time.
func _state_row(scroll: BoxScroll) -> Control:
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.add_child(Arc.label("STATES", 22, Arc.HOT))
        var wrap := HFlowContainer.new()
        wrap.add_theme_constant_override("h_separation", 8)
        wrap.add_theme_constant_override("v_separation", 8)
        box.add_child(wrap)
        for st in [["", "All"], ["favorites", "Favorites"], ["mystery", "Mystery"]]:
                var sid := String(st[0])
                var lbl := String(st[1])
                var active := _filter_state == sid
                var b := Button.new()
                b.text = " " + lbl
                b.toggle_mode = true
                b.button_pressed = active
                b.add_theme_font_override("font", Arc.font_ui())
                b.add_theme_font_size_override("font_size", 19)
                b.add_theme_color_override("font_color", Arc.CARD if active else Color("7a5a34"))
                b.add_theme_color_override("font_pressed_color", Arc.CARD)
                var sb := Arc.panel_style(Color(0.98, 0.62, 0.1) if active else Color(0, 0, 0, 0.14), 20)
                sb.content_margin_left = 16
                sb.content_margin_right = 16
                sb.content_margin_top = 8
                sb.content_margin_bottom = 8
                b.add_theme_stylebox_override("normal", sb)
                var sbh := sb.duplicate() as StyleBoxFlat
                sbh.bg_color = sbh.bg_color.lightened(0.08)
                b.add_theme_stylebox_override("hover", sbh)
                var sbp := sb.duplicate() as StyleBoxFlat
                sbp.bg_color = Color(0.85, 0.5, 0.06)
                b.add_theme_stylebox_override("pressed", sbp)
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                b.toggled.connect(func(_on: bool):
                        Jukebox.sfx("click", -4.0)
                        # single-select: re-tap falls back to ALL
                        _filter_state = "" if _filter_state == sid else sid
                        _close_sheet()
                        _open_search())
                scroll.register_tappable(b, Arc._tap_emitter(b))
                wrap.add_child(b)
        return box

# ------------------------------------------------------------ help (? button)

func _open_help() -> void:
        if _sheet_open or _trophies_open:
                return
        Jukebox.sfx("click", -4.0)
        var h := _sheet_height()
        var vb := _sheet_base(h)
        var title := Arc.label("YOUR GAMES", 40, Arc.INK)
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(title)
        var sub := Arc.label("tap a game for the guide", 19, Color("8a6a40"), false)
        sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(sub)

        var scroll := BoxScroll.new()
        scroll.custom_minimum_size = Vector2(0, h - 250)
        scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
        vb.add_child(scroll)
        var list := VBoxContainer.new()
        list.add_theme_constant_override("separation", 10)
        list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        scroll.add_child(list)

        var shown := 0
        for g in GameReg.playable():
                var id := String(g["id"])
                if not Box.owns_game(id):
                        continue
                shown += 1
                list.add_child(_help_row(g, scroll))
        if shown == 0:
                var e := Arc.label("own a game and it shows up here", 20, Color("8a6a40"), false)
                e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                list.add_child(e)

        vb.add_child(Arc.button("CLOSE", Vector2(540, 64), 24, Color(0.42, 0.30, 0.16),
                        func(): _close_sheet()))
        Arc.fit_sheet(vb)

## Thumbnail + name header line, description under (simple list, no stats).
## v0.0.9 owner rule: this line shows the PRE-PLAY description (the tag line
## visible on the game page), not the long guide text - the guide's "THE
## GAME" section keeps the full desc.
func _help_row(g: Dictionary, scroll: BoxScroll) -> Control:
        var row := PanelContainer.new()
        row.add_theme_stylebox_override("panel", Arc.panel_style(Color(1, 1, 1, 0.5), 18, 10))
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 4)
        row.add_child(v)
        var head := HBoxContainer.new()
        head.add_theme_constant_override("separation", 12)
        v.add_child(head)
        var ic := TextureRect.new()
        var tp := String(g.get("thumb", ""))
        ic.texture = load(tp) if ResourceLoader.exists(tp) else null
        ic.custom_minimum_size = Vector2(96, 64)
        ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        ic.clip_contents = true
        head.add_child(ic)
        head.add_child(Arc.label(String(g["title"]), 26, Arc.INK))
        var d := Arc.label(String(g.get("tag", "")), 17, Color("6a4a28"), false)
        d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        v.add_child(d)
        scroll.register_tappable(row, func():
                Jukebox.sfx("click", -4.0)
                _open_guide(g))
        return row

## General guide: about, how to play, controls, then genres + age rating.
func _open_guide(g: Dictionary) -> void:
        _close_sheet()
        var h := _sheet_height()
        var vb := _sheet_base(h)
        var title := Arc.label(String(g["title"]).to_upper(), 38, Arc.INK)
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(title)

        var scroll := BoxScroll.new()
        scroll.custom_minimum_size = Vector2(0, h - 220)
        scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
        vb.add_child(scroll)
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 12)
        v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        scroll.add_child(v)

        v.add_child(Arc.label("THE GAME", 24, Arc.HOT))
        var about := Arc.label(String(g.get("desc", "")), 20, Color("6a4a28"), false)
        about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        about.custom_minimum_size = Vector2(540, 0)
        v.add_child(about)

        v.add_child(Arc.label("HOW TO PLAY", 24, Arc.HOT))
        for line in g.get("controls", []):
                var l := Arc.label("- " + String(line), 19, Arc.INK, false)
                l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                l.custom_minimum_size = Vector2(540, 0)
                v.add_child(l)

        v.add_child(Arc.label("GOOD TO KNOW", 24, Arc.HOT))
        var facts := ""
        if g.has("charges"):
                facts += "uses GOGABatteries: %d per round, pool %d (+1 every %d min)\n" \
                                % [int(g["charges"].get("per_round", 2)), int(g["charges"].get("capacity", 10)), int(g["charges"].get("regen_minutes", 5))]
        var win := Roadmap.window_text(String(g["id"]))
        if win != "":
                facts += win + "\n"
        facts += "entry fee %d GOGACoins" % int(g.get("fee", 0))
        var fk := Arc.label(facts, 18, Color("6a4a28"), false)
        fk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        fk.custom_minimum_size = Vector2(540, 0)
        v.add_child(fk)

        # GENRES / MORE TAGS / AGE each in their OWN labeled section (owner rule:
        # never mixed together in one pile)
        var geo: Dictionary = g.get("genres", {})
        if not (geo.get("main", []) as Array).is_empty():
                v.add_child(Arc.label("GENRES", 24, Arc.HOT))
                var grow := HFlowContainer.new()
                grow.add_theme_constant_override("h_separation", 8)
                grow.add_theme_constant_override("v_separation", 8)
                for gid in (geo.get("main", []) as Array):
                        grow.add_child(Arc.meta_chip("genre", String(gid)))
                v.add_child(grow)
        if not (geo.get("sub", []) as Array).is_empty():
                v.add_child(Arc.label("MORE TAGS", 24, Arc.HOT))
                var srow := HFlowContainer.new()
                srow.add_theme_constant_override("h_separation", 8)
                srow.add_theme_constant_override("v_separation", 8)
                for sid in (geo.get("sub", []) as Array):
                        srow.add_child(Arc.meta_chip("sub", String(sid)))
                v.add_child(srow)
        v.add_child(Arc.label("AGE", 24, Arc.HOT))
        var arow := HFlowContainer.new()
        arow.add_theme_constant_override("h_separation", 8)
        arow.add_theme_constant_override("v_separation", 8)
        arow.add_child(Arc.meta_chip("age", String(g.get("age", "everyone"))))
        v.add_child(arow)

        vb.add_child(Arc.button("BACK", Vector2(540, 64), 24, Color(0.42, 0.30, 0.16),
                        func():
                                _close_sheet()
                                _open_help()))
        Arc.fit_sheet(vb)

# ---------------------------------------------------------------- sheets

func _set_feed_lock(locked: bool) -> void:
        # sheets sit ON TOP of the feed scrolls; without this lock BoxScroll would
        # swallow the emulated mouse and sliders/buttons in sheets would "hang"
        if _feed_scroll != null and is_instance_valid(_feed_scroll):
                _feed_scroll.input_locked = locked
        if _strip_scroll != null and is_instance_valid(_strip_scroll):
                _strip_scroll.input_locked = locked

func _sheet_base(h := 0.0) -> VBoxContainer:
        _sheet_open = true
        _set_feed_lock(true)
        var vb := Arc.sheet(_root, h)
        return vb

func _close_sheet() -> void:
        _sheet_open = false
        _trophies_open = false
        _set_feed_lock(false)
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
        Arc.fit_sheet(vb)

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
        Arc.fit_sheet(vb, 2)

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

func _header_block(vb: VBoxContainer, g: Dictionary, faded := false, allow_fav := false,
                reg_scroll: BoxScroll = null) -> void:
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
        hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        head.add_child(hv)
        hv.add_child(Arc.label(String(g["title"]), 34, Arc.INK))
        hv.add_child(Arc.label(String(g["tag"]), 20, Color("8a6a40"), false))
        hv.add_child(Arc.label("best %d   last %d   plays %d" % [Box.stat(id, "best"),
                        Box.stat(id, "last"), Box.stat(id, "plays")], 20, Color("6a4a28"), false))
        if allow_fav:
                var hb := _heart_button(id)
                head.add_child(hb)
                # the header lives INSIDE the page's BoxScroll - raw button input
                # is swallowed there, so the heart must be a registered tappable
                if reg_scroll != null:
                        hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        reg_scroll.register_tappable(hb, Arc._tap_emitter(hb))

## v0.0.9 FAVORITES: the heart lives on the pre-play (owned game) page.
## Cream/white heart by default; RED when the game is in the FAVORITES feed
## (search -> STATES -> Favorites). One texture, modulate does the color.
func _heart_button(id: String) -> Button:
        var b := Button.new()
        b.custom_minimum_size = Vector2(64, 64)
        b.flat = true
        var ic := TextureRect.new()
        ic.texture = load("res://assets/ui/heart.png")
        ic.set_anchors_preset(Control.PRESET_FULL_RECT)
        ic.offset_left = 6
        ic.offset_top = 6
        ic.offset_right = -6
        ic.offset_bottom = -6
        ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(ic)
        var paint := func():
                ic.modulate = Color(1.0, 0.32, 0.32, 1.0) if Box.is_favorite(id) \
                                else Color(1, 1, 1, 0.55)
        paint.call()
        b.pressed.connect(func():
                var on := not Box.is_favorite(id)
                Box.set_favorite(id, on)
                paint.call()
                Jukebox.sfx("confirm" if on else "click", -4.0)
                Arc.toast(_toast, "added to favorites" if on else "removed from favorites"))
        return b

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

        var fee := int(g["fee"])
        # anti-softlock: ONLY the starter game (snake) is ever free to play
        var free_play: bool = id == "snake" and fee > 0 and Box.coins() < fee
        var can_pay: bool = fee <= 0 or free_play or Box.coins() >= fee
        var can_batt: bool = true
        var batt := Box.game_battery(id)
        if not batt.is_empty():
                # v0.1.1: a round drinks from the game pool AND the box bank
                # (store rule) - the button must check BOTH or it enables a
                # play that launch() will refuse.
                can_batt = int(batt["count"]) >= int(batt["per_round"]) \
                                and Box.box_batteries() >= int(batt["per_round"])
        var can_time := Roadmap.window_ok(id)
        var can_play := can_pay and can_batt and can_time
        # NOTE: the feed tile's "ready to play" chip calls Roadmap.can_play_now,
        # the same fee + pools + window oracle this page mirrors line by line.

        _header_block(content, g, false, true, scroll)

        # batteries + time-window info, right under the header
        if not batt.is_empty():
                var brow := HBoxContainer.new()
                brow.add_theme_constant_override("separation", 10)
                content.add_child(brow)
                brow.add_child(Arc.battery_control(int(batt["count"]), int(batt["cap"]), 64.0, 28.0))
                var btxt := "%d/%d GOGABatteries  ·  %d per round" % [int(batt["count"]), int(batt["cap"]), int(batt["per_round"])]
                if int(batt["count"]) < int(batt["cap"]):
                        btxt += "\n+1 in %s  ·  full in %s" % [Roadmap.fmt_clock(float(batt["regen_in"])),
                                Roadmap.fmt_clock(float((int(batt["cap"]) - int(batt["count"]) - 1) * int(batt["step"]) + int(batt["regen_in"])))]
                var bl := Arc.label(btxt, 18, Color("6a4a28"), false)
                bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                brow.add_child(bl)
                if Box.box_batteries() > 0 and int(batt["count"]) < int(batt["cap"]):
                        var refill := Arc.button("REFILL FROM BOX",
                                        Vector2(240, 56), 17, Color("3f7fb0"), func():
                                var moved := Box.refill_game_from_box(id)
                                Jukebox.sfx("confirm" if moved > 0 else "error", -4.0)
                                Arc.toast(_toast, "%d batteries moved (one round)" % moved if moved > 0 else "box pool is empty")
                                _close_sheet()
                                _open_game_page(g))
                        # inside a BoxScroll the feed scroll OWNS taps: without
                        # this the button captured a ghost press and hung
                        # pressed forever while nothing fired (owner L)
                        refill.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        scroll.register_tappable(refill, func():
                                refill.pressed.emit())
                        brow.add_child(refill)
        var win := Roadmap.window_text(id)
        if win != "":
                var wl := Arc.label(win, 18, Arc.HOT if can_time else Arc.BAD, false)
                wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                content.add_child(wl)

        var play_txt := "PLAY  -%d" % fee if (fee > 0 and not free_play) else "PLAY  FREE"
        var play_btn := Arc.coin_button(play_txt, Vector2(540, 92), 34, Arc.ACCENT) \
                        if (fee > 0 and not free_play) else Arc.button(play_txt, Vector2(540, 92), 34, Arc.ACCENT)
        content.add_child(play_btn)
        if not can_play:
                play_btn.disabled = true
                var why := ""
                if not can_time:
                        why = "this one %s - come back in the window" % win
                elif not can_pay:
                        why = "need %d more GOGACoins (snake is always free)" % (fee - Box.coins())
                elif not can_batt:
                        why = "batteries empty - +1 every 5 min, or refill from the box"
                var whyl := Arc.label(why, 18, Arc.BAD, false)
                whyl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                content.add_child(whyl)
        scroll.register_tappable(play_btn, func():
                Jukebox.sfx("click", -4.0)
                if play_btn.disabled:
                        return
                _close_sheet()
                GameHost.launch(router if router != null else self, id))

        # achievements: OWN up/down scroll area so a long trophy list never
        # spams the page (owner rule) - the rest of the page stays compact
        var ach: Array = g.get("ach", [])
        var got := 0
        for a in ach:
                if Box.has_achievement(id, String(a["id"])):
                        got += 1
        var a_head := Arc.label("ACHIEVEMENTS   %d / %d" % [got, ach.size()], 24, Arc.HOT)
        content.add_child(a_head)
        if ach.is_empty():
                var none := Arc.label("no trophies in this one yet", 18, Color("9a7a50"), false)
                content.add_child(none)
        else:
                var t_scroll := BoxScroll.new()
                t_scroll.custom_minimum_size = Vector2(0, clampf(ach.size() * 44.0 + 16.0, 96.0, 260.0))
                t_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                content.add_child(t_scroll)
                var t_list := VBoxContainer.new()
                t_list.add_theme_constant_override("separation", 10)
                t_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                t_scroll.add_child(t_list)
                for a in ach:
                        var done: bool = Box.has_achievement(id, String(a["id"]))
                        var row := Arc.label(("+ %s  -  %s" % [String(a["title"]), String(a["desc"])])
                                        if done else ("- %s  -  %s" % [String(a["title"]), String(a["desc"])]),
                                        18, Arc.GOOD if done else Color("9a7a50"), false)
                        row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                        row.custom_minimum_size = Vector2(540, 0)
                        t_list.add_child(row)

        var info := Arc.label("time %s   spent %d   earned %d" % [
                        Roadmap.fmt_time(_play_seconds(id)), Box.spent_in(id), Box.earned_in(id)],
                        18, Color("6a4a28"), false)
        info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        content.add_child(info)

        # GENRES / MORE TAGS / AGE live in the (previously empty) space between
        # RESET and CLOSE - each group in its own labeled spot.
        var geo: Dictionary = g.get("genres", {})
        if not (geo.get("main", []) as Array).is_empty():
                content.add_child(Arc.label("GENRES", 20, Arc.HOT))
                var grow := HFlowContainer.new()
                grow.add_theme_constant_override("h_separation", 8)
                grow.add_theme_constant_override("v_separation", 8)
                for gid in (geo.get("main", []) as Array):
                        grow.add_child(Arc.meta_chip("genre", String(gid)))
                content.add_child(grow)
        if not (geo.get("sub", []) as Array).is_empty():
                content.add_child(Arc.label("MORE TAGS", 20, Arc.HOT))
                var srow := HFlowContainer.new()
                srow.add_theme_constant_override("h_separation", 8)
                srow.add_theme_constant_override("v_separation", 8)
                for sid in (geo.get("sub", []) as Array):
                        srow.add_child(Arc.meta_chip("sub", String(sid)))
                content.add_child(srow)
        content.add_child(Arc.label("AGE", 20, Arc.HOT))
        var arow := HFlowContainer.new()
        arow.add_theme_constant_override("h_separation", 8)
        arow.add_theme_constant_override("v_separation", 8)
        arow.add_child(Arc.meta_chip("age", String(g.get("age", "everyone"))))
        content.add_child(arow)

        var reset_btn := Arc.button("RESET GAME PROGRESS", Vector2(540, 60), 20,
                        Color(0.6, 0.32, 0.24))
        content.add_child(reset_btn)
        scroll.register_tappable(reset_btn, func():
                Jukebox.sfx("click", -4.0)
                _confirm_reset(g))
        vb.add_child(Arc.button("CLOSE", Vector2(540, 64), 24, Color(0.42, 0.30, 0.16),
                        func(): _close_sheet()))
        Arc.fit_sheet(vb)

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
        Arc.fit_sheet(vb, 2)

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
        var btn := Arc.coin_button("UNLOCK  %d" % price, Vector2(540, 92), 30, Arc.GOOD, func():
                if Box.unlock_game(id, price):
                        Jukebox.sfx("unlock", -2.0)   # v0.0.9: OWN short chime
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
        Arc.fit_sheet(vb)

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
        Arc.fit_sheet(vb)

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
        Arc.fit_sheet(vb)

func _open_mystery_page(g: Dictionary) -> void:
        if _sheet_open:
                return
        Jukebox.sfx("click", -4.0)
        var id := String(g["id"])
        var rv: Dictionary = g.get("reveal", {})
        var vb := _sheet_base()
        # v0.0.7: the real mystery art (the old text "?" was the stale design;
        # the tile already used this artwork - now the pre-play page matches)
        var qc := HBoxContainer.new()
        qc.alignment = BoxContainer.ALIGNMENT_CENTER
        vb.add_child(qc)
        var q := TextureRect.new()
        q.texture = load("res://assets/ui/mystery_q.png")   # the REAL pre-play ? art (amber, tail included)
        q.custom_minimum_size = Vector2(300, 206)
        q.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        q.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        q.mouse_filter = Control.MOUSE_FILTER_IGNORE
        qc.add_child(q)
        vb.add_child(Arc.label("MYSTERY GAME", 32, Arc.INK))

        # live poll: the countdown ticks every second, and the moment the
        # notification permission flips (dialog granted / settings toggle) the
        # ALLOW REMINDERS button disappears without reopening the page
        var countdown: Label = null
        var panel := vb.get_parent()
        var tick := Timer.new()
        tick.wait_time = 1.0
        tick.autostart = true
        panel.add_child(tick)

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
                                countdown = Arc.label("", 22, Arc.INK, false)
                                countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                                vb.add_child(countdown)
                                var hint := Arc.label("of total box play time to reveal this one",
                                                19, Color("8a6a40"), false)
                                hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                                vb.add_child(hint)
                        else:
                                vb.add_child(Arc.label("revealing...", 22, Arc.INK, false))
                "real":
                        var left := Roadmap.time_left(id)
                        if left > 0.0:
                                countdown = Arc.label("", 24, Arc.INK)
                                countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                                vb.add_child(countdown)
                                var sub := Arc.label("we'll ping you when it's ready", 19, Color("8a6a40"), false)
                                sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                                vb.add_child(sub)
                                if not Notify.permission_granted():
                                        vb.add_child(Arc.button("ALLOW REMINDERS", Vector2(440, 60), 20,
                                                        Color("58a8d8"), func(): _ask_reminders()))
                        else:
                                vb.add_child(Arc.label("revealing...", 22, Arc.INK, false))
        tick.timeout.connect(func():
                if not is_instance_valid(vb):
                        return
                if countdown != null and is_instance_valid(countdown):
                        if String(rv.get("kind", "")) == "inbox":
                                var lft := Roadmap.inbox_left(id)
                                if lft <= 0.0:
                                        _close_sheet()
                                        _after_roadmap_change()
                                        return
                                countdown.text = "%s left\nplay any game" % Roadmap.fmt_clock(lft)
                        else:
                                var lft := Roadmap.time_left(id)
                                if lft <= 0.0:
                                        _close_sheet()
                                        _after_roadmap_change()
                                        return
                                countdown.text = "reveals in %s" % Roadmap.fmt_clock(lft)
                # permission flipped while the page is open -> refresh the button
                if String(rv.get("kind", "")) == "real" and Notify.permission_granted() \
                                and Roadmap.time_left(id) > 0.0:
                        var has_btn := false
                        for c in vb.get_children():
                                if c is Button and String((c as Button).text).begins_with("ALLOW"):
                                        has_btn = true
                        if has_btn:
                                _close_sheet()
                                _open_mystery_page(g))
        vb.add_child(Arc.button("CLOSE", Vector2(540, 64), 24, Color(0.42, 0.30, 0.16),
                        func(): _close_sheet()))
        Arc.fit_sheet(vb)

## ALLOW REMINDERS (v0.1.0, simple per owner). Root cause of the dead tap in
## v0.0.6..v0.0.9 was NEVER the OEM: GDScript called native.request_permission()
## while the Java method was requestPermission() - Godot does no case
## conversion, so every call silently failed (docs: "There is no coercing
## snake_case to camelCase"). Names now match exactly and the flow is the
## plain official one: tap -> the real system dialog. No watchdogs, no ladders.
func _ask_reminders() -> void:
        if not Notify.available():
                Arc.toast(_toast, "notification service missing on this device")
                return
        if Notify.permission_granted():
                Arc.toast(_toast, "reminders are already allowed")
                return
        Arc.toast(_toast, "asking the system...")
        Notify.request_permission()

# ------------------------------------------------------------ trophies & stats

func _open_trophies() -> void:
        if _sheet_open or _trophies_open:
                return
        Jukebox.sfx("click", -4.0)
        _sheet_open = false
        _trophies_open = true
        _set_feed_lock(true)

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

        # PRIVACY OF THE ROADMAP: only OWNED games appear here. Showing hidden or
        # locked games (even as rows) would leak how many games the box will grow.
        var rows := []
        for g in GameReg.playable():
                if Box.owns_game(String(g["id"])):
                        rows.append(g)

        if rows.is_empty():
                var e := Arc.label("own a game to start this wall", 20, Color("8a6a40"), false)
                e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                list.add_child(e)
        for g in rows:
                list.add_child(_stat_row(g))
        if rows.size() < GameReg.playable().size():
                var more := Arc.label("more games = more rows here...", 16, Color("8a6a40"), false)
                more.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                list.add_child(more)

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
        Ads.banner_show()   # back on the box: banner returns (fresh fill)
        Ads.refresh()       # re-preload interstitial + rewarded for next runs
        Roadmap.tick()
        _refresh()
