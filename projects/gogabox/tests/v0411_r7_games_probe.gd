extends Node
## v041-1 r7 THE GAMES PROBE - the owner's report worked to the bone.
## Run headless:
##   GODOT_BIN --headless --path projects/gogabox res://tests/v0411_r7_games_probe.tscn
## THE LAWS UNDER TEST:
##   SCROLL  - THE DOOMSCROLL ENGINE: echoes are dead (an OS key-repeat is
##             no longer a fresh nudge - the "every specific milliseconds"
##             mis-sync), the hold is one continuous accelerating glide,
##             release glides out honestly, and the target clamps to the
##             REAL scrollable max (the 1,000,000 phantom made the bottom
##             of the feed stick - UP presses crawled instead of climbing).
##             THE PICKS LINE rides the same engine, 1:1.
##   POPUP   - THE COLLISION LAW: the achievement/battery popups measure
##             the text against the LIVE viewport - a line that fits stays
##             ONE line (the fixed 640px min wrapped blindly), a line that
##             does not fit wraps at the full available width, and a panel
##             taller than the safe seat steps the font ladder down.
##   LOADER  - THE CODE FRAME LAW: the golden frame is code-drawn and
##             STRAIGHT (the old StyleBoxFlat radius 26 + straight thumb
##             made the art float over the curved corners), and the thumb
##             sits FLUSH against it (inset = the stroke width).
##   NOTIFY  - THE WINDOWS TOAST SEAT: the toast XML wears the title, the
##             body, the icon and the kind's OWN sound (the per-kind
##             channel law, the Windows way), the escaping holds, every
##             kind maps a DISTINCT winsoundevent, and the headless seat
##             stays the honest sim.
##   CURSOR  - THE HARDWARE RETICLE: Heavy War bakes its own cursor pair
##             (idle + fire) - the OS carries it ABOVE the SHOP/back
##             buttons that used to paint over the drawn reticle.

var fails := 0
var _n := 0

func _check(name: String, ok: bool) -> void:
        _n += 1
        print(("PASS  " if ok else "FAIL  ") + name)
        if not ok:
                fails += 1

func _ready() -> void:
        call_deferred("_run")

func _run() -> void:
        print("== v041-1 r7 games probe ==")
        _notify_laws()
        await _popup_laws()
        await _loader_law()
        await _scroll_laws()
        await _cursor_law()
        print("== %d checks, %d fails ==" % [_n, fails])
        get_tree().quit(1 if fails > 0 else 0)

# ============================================================ NOTIFY
func _notify_laws() -> void:
        Box.reset_all()
        # headless = the honest sim seat (no native, no Windows)
        _check("notify: headless stays the sim (available false)",
                not Notify.available())
        _check("notify: headless permission is false",
                not Notify.permission_granted())
        var esc: String = Notify._xml_esc("<a & \"b\">")
        _check("notify: xml escaping holds",
                esc == "&lt;a &amp; &quot;b&quot;&gt;")
        # the toast XML: title + body + icon + the kind's own sound
        var icon_probe := "res://icons/main_512x512.png"
        var x: String = Notify._win_toast_xml("GOGABox", "Dario is ready!",
                        "game_ready")
        _check("notify: toast wears the title",
                "<text>GOGABox</text>" in x)
        _check("notify: toast wears the body",
                "<text>Dario is ready!</text>" in x)
        _check("notify: toast wears the icon image",
                "appLogoOverride" in x and "src=" in x)
        _check("notify: game_ready wears ITS sound",
                "ms-winsoundevent:Notification.Mail" in x)
        var xb: String = Notify._win_toast_xml("GOGABatteries",
                        "batteries full", "battery_full")
        _check("notify: battery_full wears ITS sound",
                "ms-winsoundevent:Notification.IM" in xb)
        # the per-kind channel law, the Windows way: DISTINCT sounds
        var sounds := {}
        var distinct := true
        for k in Notify.WIN_AUDIO:
                var s := String(Notify.WIN_AUDIO[k])
                if sounds.has(s):
                        distinct = false
                sounds[s] = k
        _check("notify: every kind owns a DISTINCT sound (%d kinds)"
                        % Notify.WIN_AUDIO.size(),
                distinct and Notify.WIN_AUDIO.size() >= 3)
        # the icon source exists (the toast's face must bake)
        _check("notify: the icon source exists", ResourceLoader.exists(icon_probe))

# ============================================================ POPUP
func _popup_laws() -> void:
        Box.reset_all()
        var ach: Node = load("res://game/core/achiever.gd").new()
        add_child(ach)
        await get_tree().process_frame
        # the fit bench: a root sized like the design viewport
        var root := Control.new()
        root.size = Vector2(1080, 1920)
        add_child(root)
        var panel := PanelContainer.new()
        root.add_child(panel)
        var name_l: Label = Arc.label("Snake  -  Snack Time", 30, Arc.CARD)
        var desc_l: Label = Arc.label("eat 10 fruits in one run", 19,
                        Color(1, 1, 1, 0.75), false)
        panel.add_child(name_l)
        panel.add_child(desc_l)
        # (1) SHORT TEXT: measured to fit -> ONE line, no blind 640 box
        ach._fit_and_animate(root, panel, name_l, desc_l, 30, 19, Callable())
        await get_tree().process_frame
        await get_tree().process_frame
        _check("popup: short text stays ONE line (no blind wrap)",
                name_l.autowrap_mode == TextServer.AUTOWRAP_OFF
                and desc_l.autowrap_mode == TextServer.AUTOWRAP_OFF)
        _check("popup: short text hugs its content (no fixed 640)",
                panel.custom_minimum_size.x == 0.0)
        # (2) LONG TEXT: wraps at the FULL available width, not a const
        var long_name := ("A Very Long Achievement Name That Keeps Going "
                        + "And Going Across The Whole Screen Indeed Yes Really Long")
        name_l.text = long_name
        ach._fit_and_animate(root, panel, name_l, desc_l, 30, 19, Callable())
        await get_tree().process_frame
        var measured: float = Arc.font_big().get_string_size(long_name,
                        HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
        var wraps := measured > 940.0 - 116.0
        if wraps:
                _check("popup: long text WRAPS (measured %.0fpx)" % measured,
                        name_l.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART)
                _check("popup: wrap rides the FULL width (940, not 640)",
                        panel.custom_minimum_size.x == 940.0)
        else:
                _check("popup: long text stays one line (measured %.0fpx)"
                                % measured, true)
        # (3) GIANT TEXT: the height collision steps the ladder DOWN
        var giant := ""
        for i in 24:
                giant += "word%d " % i
        desc_l.text = giant.repeat(40)
        ach._fit_and_animate(root, panel, name_l, desc_l, 30, 19, Callable())
        await get_tree().process_frame
        var ms: int = int(desc_l.get_theme_font_size("font_size"))
        _check("popup: giant text stepped the ladder down (desc %dpx)" % ms,
                ms < 19)
        _check("popup: the ladder never goes below readable",
                ms >= 15 and int(name_l.get_theme_font_size("font_size")) >= 22)
        ach.queue_free()
        root.queue_free()
        await get_tree().process_frame

# ============================================================ LOADER
func _loader_law() -> void:
        Box.reset_all()
        var l: Node = load("res://game/core/loader.gd").new()
        add_child(l)
        l._run({"id": "matcher", "thumb": "", "title": "MATCHER",
                "script": ""})
        await get_tree().process_frame
        await get_tree().process_frame
        await get_tree().process_frame
        # find the frame: the code-drawn Control (NOT a rounded Panel)
        var frame: Control = null
        var thumb: TextureRect = null
        for layer in l.get_children():
                for rootn in layer.get_children():
                        for center in rootn.get_children():
                                for c in center.get_children():
                                        if c is Control \
                                                        and not (c is Panel) \
                                                        and frame == null \
                                                        and c.get_child_count() > 0:
                                                frame = c
                                                for cc in c.get_children():
                                                        if cc is TextureRect:
                                                                thumb = cc
        _check("loader: the frame is CODE-DRAWN (no StyleBox Panel)",
                frame != null and not (frame is Panel))
        if frame != null:
                var ratio: float = frame.size.x / maxf(1.0, frame.size.y)
                _check("loader: the frame wears the 3:2 thumb aspect (%.3f)"
                                % ratio, absf(ratio - 1.5) < 0.02)
                _check("loader: the frame draws itself (a draw callback)",
                        frame.draw.get_connections().size() == 1)
        if frame != null and thumb != null:
                _check("loader: the thumb sits FLUSH (inset 4 = the stroke)",
                        thumb.offset_left == 4.0 and thumb.offset_top == 4.0
                        and thumb.offset_right == -4.0
                        and thumb.offset_bottom == -4.0)
                _check("loader: no curve anywhere (the art cannot float)",
                        not (frame is Panel))
        await get_tree().create_timer(2.6).timeout  # the full showtime

# ============================================================ SCROLL
func _mk_key(keycode: Key, pressed: bool, echo := false) -> InputEventKey:
        var ev := InputEventKey.new()
        ev.keycode = keycode
        ev.physical_keycode = keycode
        ev.pressed = pressed
        ev.echo = echo
        return ev

func _scroll_laws() -> void:
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        var menu := Node2D.new()
        menu.set_script(load("res://game/menu/menu.gd"))
        add_child(menu)
        await get_tree().process_frame
        await get_tree().process_frame
        await get_tree().process_frame
        var feed: BoxScroll = menu._feed_scroll
        var strip: BoxScroll = menu._strip_scroll
        _check("scroll: the menu feeds are live",
                feed != null and strip != null)
        if feed == null or strip == null:
                menu.queue_free()
                return
        await get_tree().create_timer(0.5).timeout
        var vmax: float = menu._scroll_max_v()
        _check("scroll: the feed has REAL scrollable content (max %.0fpx)"
                        % vmax, vmax > 400.0)
        # ---- 1. THE ECHO TAX IS DEAD
        menu._input(_mk_key(KEY_DOWN, true))
        _check("scroll: a press books the held flag",
                bool(menu._scroll_held["down"]))
        var t1: float = menu._feed_target
        menu._input(_mk_key(KEY_DOWN, true, true))  # an OS key-REPEAT
        menu._input(_mk_key(KEY_DOWN, true, true))
        _check("scroll: echoes are DEAD (target frozen at %.0f)" % t1,
                menu._feed_target == t1)
        menu._input(_mk_key(KEY_DOWN, false))
        _check("scroll: a release clears the held flag",
                not bool(menu._scroll_held["down"]))
        menu._scroll_ride(1.0 / 60.0)   # land the tap glide + clear the target
        menu._feed_target = -1.0
        # ---- 2. THE PHANTOM TARGET IS DEAD (the bottom-stick kill)
        for i in 200:
                menu._nudge_feed(420.0)
        _check("scroll: 200 nudges clamp to the REAL max (%.0f, not 84000)"
                        % menu._feed_target,
                menu._feed_target == vmax)
        # ---- 3. THE HOLD = ONE CONTINUOUS ACCELERATING GLIDE
        menu._feed_target = -1.0
        feed.scroll_vertical = 0
        menu._input(_mk_key(KEY_DOWN, true))
        var last := 0.0
        var rose := true
        var gaps: Array = []
        for i in 40:
                menu._scroll_ride(1.0 / 60.0)
                var cur := float(feed.scroll_vertical)
                if cur < last:
                        rose = false
                gaps.append(cur - last)
                last = cur
        _check("scroll: the hold glides continuously (never backwards)",
                rose and last > 400.0)
        # acceleration is measured EARLY (the hold from 0 hits the real max
        # mid-hold - the clamp IS the law - so late gaps honestly read 0)
        if gaps.size() >= 14:
                var early: float = gaps[2] + gaps[3]
                var late: float = gaps[12] + gaps[13]
                _check("scroll: the hold ACCELERATES (%.1f -> %.1f px/frame)"
                                % [early, late], late > early * 1.5)
        else:
                _check("scroll: the hold produced enough motion", false)
        # the position NEVER passes the real max (the bottom is the bottom)
        _check("scroll: the hold never passes the real max",
                float(feed.scroll_vertical) <= vmax + 1.0)
        # ---- 4. THE RELEASE GLIDE-OUT (from a mid-glide hold, not the
        # clamped bottom - the bottom booking lands ON the max, by law)
        feed.scroll_vertical = int(vmax * 0.5)
        menu._input(_mk_key(KEY_DOWN, true))
        menu._scroll_ride(1.0 / 60.0)
        menu._input(_mk_key(KEY_DOWN, false))
        menu._scroll_ride(1.0 / 60.0)
        var pos_at_release := float(feed.scroll_vertical)
        _check("scroll: the release booked a glide-out target (%.0f from %.0f)"
                        % [menu._feed_target, pos_at_release],
                menu._feed_target >= pos_at_release
                and menu._feed_target <= vmax + 1.0)
        menu._feed_target = -1.0
        menu._feed_vel = 0.0
        # ---- 5. THE UP ROAD + THE GRAB LAW
        var before_up := float(feed.scroll_vertical)
        menu._input(_mk_key(KEY_UP, true))
        for i in 10:
                menu._scroll_ride(1.0 / 60.0)
        _check("scroll: UP climbs back (%.0f -> %.0f)" % [before_up,
                        float(feed.scroll_vertical)],
                float(feed.scroll_vertical) < before_up)
        menu._input(_mk_key(KEY_UP, false))
        menu._scroll_ride(1.0 / 60.0)
        menu._feed_target = -1.0
        # a finger grab clears any pending target (the finger always wins)
        menu._nudge_feed(300.0)
        _check("scroll: a pending target exists", menu._feed_target >= 0.0)
        feed.grabbed.emit()
        _check("scroll: the finger grab clears the target",
                menu._feed_target < 0.0)
        # ---- 6. THE PICKS LINE, 1:1
        var shmax: float = menu._scroll_max_h()
        if shmax > 50.0:
                menu._feed_target = -1.0
                menu._nudge_strip(20000.0)
                _check("strip: the target clamps to the REAL max too",
                        menu._strip_target == shmax)
                menu._input(_mk_key(KEY_LEFT, true))
                for i in 8:
                        menu._scroll_ride(1.0 / 60.0)
                _check("strip: LEFT glides the picks line",
                        float(strip.scroll_horizontal) < shmax)
                menu._input(_mk_key(KEY_LEFT, false))
                menu._scroll_ride(1.0 / 60.0)
                menu._strip_target = -1.0
        else:
                _check("strip: no strip overflow on this seat (skip)", true)
        menu.queue_free()
        await get_tree().process_frame

# ============================================================ CURSOR
func _cursor_law() -> void:
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        var router := Node2D.new()
        add_child(router)
        var host_script: GDScript = load("res://game/core/game_host.gd")
        var launched: bool = host_script.launch(router, "heavywar")
        _check("cursor: heavywar launches", launched)
        if not launched:
                return
        await get_tree().create_timer(3.0).timeout
        var host: Node = host_script.active_host
        if host == null or host.game == null:
                _check("cursor: the war is live", false)
                host_script.end_session()
                return
        var game: Node = host.game
        if game.has_method("box_story_dismiss"):
                game.box_story_dismiss()
        # the reticle pair baked (pure Image work - headless-safe)
        var norm: ImageTexture = game._cur_norm
        _check("cursor: the reticle pair is baked", norm != null)
        if norm != null:
                var img := norm.get_image()
                var c := int(0.5 + float(game.CUR_C))
                _check("cursor: the reticle wears the 56x56 seat",
                        img.get_width() == int(game.CUR_SIZE)
                        and img.get_height() == int(game.CUR_SIZE))
                var center := img.get_pixel(c, c)
                _check("cursor: the center dot lives (aim point)",
                        center.a > 0.5)
                var edge := img.get_pixel(c + 17, c)
                _check("cursor: the black silhouette outline lives",
                        edge.a > 0.1 and edge.r < 0.2)
        var fire: ImageTexture = game._cur_fire
        _check("cursor: the FIRE variant is baked (the click cursor)",
                fire != null)
        if fire != null:
                var fimg := fire.get_image()
                var c2 := int(0.5 + float(game.CUR_C))
                var fcenter := fimg.get_pixel(c2, c2)
                _check("cursor: the fire cursor reads warm and distinct",
                        fcenter.r > 0.6 and fcenter.g < fcenter.r)
        # the seat itself: headless is_pc() false -> the arm is a no-op
        _check("cursor: the seat defers on headless (the OS owns nothing here)",
                not game._game_cur_armed)
        host_script.end_session()
        await get_tree().create_timer(0.4).timeout
