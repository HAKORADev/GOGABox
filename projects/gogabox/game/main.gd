extends Node2D
## GOGABox bootstrap: splash -> menu. Games are hosted on top of the menu
## (GameHost), achievement popups float above everything (Achiever).
## The Android BACK button routes here: pause game -> close sheet -> leave box.

var _splash_layer: CanvasLayer
var _splash_root: Control
var _splash_veil: ColorRect
var _splash_alive := false
var _menu: Node2D

func _ready() -> void:
        # v0.4.1 THE ICON LAW (the owner: "the app in windows has it's icon
        # correct, but the one appears in taskbar, task manager, windowed
        # window icon, all of them are not the same one as the icon"). The
        # exe resource icon was already the right face - the RUNTIME window
        # icon was a different rendering (the project svg). The window now
        # wears the canonical face directly at boot, before the first frame.
        if ScaleRule.is_pc():
                var face: Texture2D = load("res://icons/main_512x512.png")
                if face != null and face.get_image() != null:
                        DisplayServer.window_set_icon(face.get_image())
        # v0.4.0-17 THE PC BOOT WINDOW LAW: on a desktop, honor the persisted
        # fullscreen choice and shape the window to the menu (portrait)
        # BEFORE the menu reads the pixels - the first frame is already the
        # right shape. Phones: is_pc() is false, this is a no-op.
        ScaleRule.boot_window()
        # v0.1.3 THE RESOLUTION & SCALE RULE (ScaleRule.gd = source of truth):
        # internal resolution FIXED at 1080x1920 portrait / 1920x1080
        # landscape; stretch canvas_items + aspect EXPAND fills ANY window
        # edge-to-edge (no letterbox bars on any phone, nothing distorted -
        # extra aspect just becomes extra canvas in design px). The design
        # follows the REAL window px. menu is built immediately, the splash
        # covers it while the engine warms up
        _menu = Node2D.new()
        _menu.name = "Menu"
        _menu.set_script(load("res://game/menu/menu.gd"))
        add_child(_menu)
        # games launch THROUGH main: the menu hands GameHost this router so
        # on_game_entered/on_game_closed actually fire (v0.0.4 passed the menu
        # itself, so the hide never happened -> the big L survived on device).
        _menu.set("router", self)

        var achiever: Node = load("res://game/core/achiever.gd").new()
        add_child(achiever)

        _show_splash()

        # v0.3.8-5 THE COMFORT LAW (the owner: "high phone battery usage with
        # no reason and high heat even in just main menu ... it's really just
        # shitty optimization"): the BOX never needs 60 frames - the feed is
        # a list and the dust is 34 circles. The menu breathes at 30; a game
        # buys the full 60 the moment it launches (GameHost) and hands them
        # back on the way out. The background is still a living shader - just
        # half the refresh bill.
        Engine.max_fps = 30

        # v0.4.1 THE PC SEAT: the GOGACursor and the focus nuke (Tab/arrows
        # can never walk between buttons). v041-1: DYNAMIC SCALE IS NUKED
        # (the owner: "the dynamic scale tech, remove it, it just made the
        # app more blurry, your fixes worked more way better, nuke it") -
        # the honest 1:1 rendering + the mipmap law are the whole sharpness
        # story. v041-1 r2: THE EDGE VEIL IS RETIRED with the brown - the
        # sides are flat #0a0a0a and NOTHING paints above the app anymore
        # (the owner: "it is rendered even on top of the app in-resolution
        # area ... give the sides just a #0a0a0a color").
        _apply_gogacursor()
        get_tree().node_added.connect(_nuke_focus)

var _was_paused := false
var _resume_mute := false

## v0.3.8-5 THE SLEEP LAW (the owner: "the app always get closed whenever it
## takes less than a minute in the background ... likely it is not get
## frozen"). While the app is backgrounded Android destroys the render
## surface, but our scene tree KEPT RUNNING (process, physics, tweens,
## timers, the audio server) - a backgrounded box still burning CPU is
## exactly what Android's cached-app freezer + LMK punish with a quick
## death. Now APPLICATION_PAUSED freezes the whole tree and silences the
## master bus; APPLICATION_RESUMED wakes everything back up.
func _lifecycle(what: int) -> void:
        if what == NOTIFICATION_APPLICATION_PAUSED:
                if not _was_paused:
                        _was_paused = true
                        _resume_mute = AudioServer.is_bus_mute(0)
                        AudioServer.set_bus_mute(0, true)
                        get_tree().paused = true
        elif what == NOTIFICATION_APPLICATION_RESUMED:
                if _was_paused:
                        _was_paused = false
                        AudioServer.set_bus_mute(0, _resume_mute)
                        get_tree().paused = false
                        # the governor re-decides the design on the next
                        # frame after resume (a background kill may have
                        # changed the window under us)
                        if _menu != null and is_instance_valid(_menu) \
                                        and _menu.has_method("apply_resolution"):
                                _menu.call("apply_resolution")

## v0.1.3 THE GOVERNOR - the resolution system's safety net. Every frame
## (menu in the box, splash included) re-decide the design. At steady state
## this is one Vector2i compare. On PHONES the design still follows the real
## window px (the window IS the screen - rotation is physical). On a PC the
## design follows the CONTENT (the menu's position choice, the game's
## orientation) - the window shape never picks a design anymore (v0.4.1,
## the vertical-fullscreen corruption's root kill). During a GAME the host
## owns content_scale_size; the governor must not fight it.
func _process(_delta: float) -> void:
        # v041-1 r4: the cursor is OS-composited hardware now (GogaCursor) -
        # no per-frame pointer work is needed anywhere in the box.
        if GameHost.active_host != null:
                return
        if _menu != null and is_instance_valid(_menu) \
                        and _menu.has_method("apply_resolution"):
                _menu.call("apply_resolution")
        # v041-1 r2: the edge veil is retired - the governor's only frame
        # duty left is the design re-decide above.

## v0.1.3: the design resolution lives in ScaleRule (1080x1920 portrait /
## 1920x1080 landscape, aspect EXPAND); the governor above + the menu's
## _apply_base keep it glued to the real window px.

## A game is its OWN WORLD: while it runs the menu is fully hidden AND stops
## processing - no layering weirdness, no taps leaking into the feed, no
## "double taps". v0.0.4 tried this but two engine facts defeated it:
##   1) Node2D.visible=false does NOT hide a child CanvasLayer (menu UI lives
##      on one) - so the menu kept rendering behind the game, and
##   2) launch() was handed the MENU as router, so this method never ran.
## menu.set_active() now handles BOTH the Node2D and the CanvasLayer.
func on_game_entered() -> void:
        # v0.1.1 OWNER RULE: the box theme is BOX-ONLY. It used to keep
        # looping under every game (the menu player was never told to stop -
        # a design flaw, not a leak). Stop it on the way in; the menu brings
        # it back on the way out.
        Jukebox.stop_music()
        if _menu != null and is_instance_valid(_menu) and _menu.has_method("set_active"):
                _menu.call("set_active", false)

func on_game_closed() -> void:
        if _menu != null and is_instance_valid(_menu) and _menu.has_method("set_active"):
                _menu.call("set_active", true)
                if _menu.has_method("on_game_closed"):
                        _menu.call("on_game_closed")
                # box theme back - it NEVER plays inside a game scene
                Jukebox.play_music_menu()
        # v041-1 r4: the box cursor re-arms when the box takes the pointer
        # back (a game may have replaced the image with its own; the engine
        # cache short-circuits the call when nothing moved).
        _apply_gogacursor()

func _show_splash() -> void:
        _splash_layer = CanvasLayer.new()
        _splash_layer.layer = 20
        add_child(_splash_layer)

        # v0.4.1 THE SPLASH FLICKER KILL (the owner's v010-era report: the
        # feed "made a little flick showing the feed then returns again to
        # continue the splash screen"). The old veil lived INSIDE the fading
        # splash root - the whole root (veil included) faded in over 0.3s,
        # so the freshly built feed showed THROUGH the half-transparent
        # veil for those frames. The veil is now a DIRECT child of the
        # layer, opaque from frame zero, and only the logo fades in on top
        # of it.
        _splash_veil = ColorRect.new()
        _splash_veil.color = Color(0.227451, 0.137255, 0.074510, 1.0)
        _splash_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
        _splash_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _splash_layer.add_child(_splash_veil)

        _splash_root = Control.new()
        _splash_root.set_anchors_preset(Control.PRESET_FULL_RECT)
        _splash_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _splash_layer.add_child(_splash_root)

        # v0.1.1 OWNER RULE (brainstorm): the old splash.png poster (G icon +
        # striped background + subtitle) is gone - the splash is THE LOGO
        # ONLY, centered on the flat box brown. Cleaner, and the boot splash
        # (project.godot) now matches it exactly.
        var center := CenterContainer.new()
        center.set_anchors_preset(Control.PRESET_FULL_RECT)
        center.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _splash_root.add_child(center)

        var art := TextureRect.new()
        art.texture = load("res://assets/ui/logo.png")
        art.custom_minimum_size = Vector2(560.0, 560.0 * 148.0 / 500.0)
        art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        art.mouse_filter = Control.MOUSE_FILTER_IGNORE
        center.add_child(art)

        # fade in + a slow gentle zoom (feels alive, not a static image)
        _splash_root.modulate.a = 0.0
        art.pivot_offset = art.size / 2.0
        var tw := _splash_root.create_tween()
        tw.tween_property(_splash_root, "modulate:a", 1.0, 0.3)
        tw.parallel().tween_property(art, "scale", Vector2(1.02, 1.02), 1.5) \
                        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

        get_tree().create_timer(1.8).timeout.connect(_end_splash)
        _splash_alive = true

func _end_splash() -> void:
        if not _splash_alive:
                return
        _splash_alive = false
        var out := create_tween()
        if is_instance_valid(_splash_root):
                out.tween_property(_splash_root, "modulate:a", 0.0, 0.4)
        if _splash_veil != null and is_instance_valid(_splash_veil):
                out.parallel().tween_property(_splash_veil, "color:a", 0.0, 0.4)
        out.tween_callback(func():
                if is_instance_valid(_splash_layer):
                        _splash_layer.queue_free()
                # banner only joins AFTER the splash - never during it
                var menu := get_node_or_null("Menu")
                if menu != null and menu.has_method("on_splash_done"):
                        menu.call("on_splash_done"))

func _input(event: InputEvent) -> void:
        # tap anywhere to skip the splash
        if _splash_alive and event is InputEventScreenTouch \
                        and (event as InputEventScreenTouch).pressed:
                _end_splash()
                return
        # v0.4.1 THE WASD FALLBACK LAW (the owner: "make controls fallbacks,
        # like a game that has the arrow-keys defined only... making the WASD
        # keys be used same way... if a game has different use for both
        # arrows and WASD, then do nothing"): no game defines its own W/A/S/D
        # (Heavy War aliases them to the SAME directions), so the box
        # translates once, globally - every arrows-only game hears the keys.
        # v041-1 THE RELEASE LAW (the owner's cosmic spud report: "when
        # luckily move it, it keeps moving without stopping until i tap
        # another button"): only the PRESSES were ever forwarded - the
        # action system saw ui_up held FOREVER. The release rides now.
        if event is InputEventKey and not (event as InputEventKey).echo:
                var wk := (event as InputEventKey).keycode
                var ak := KEY_NONE
                match wk:
                        KEY_W: ak = KEY_UP
                        KEY_A: ak = KEY_LEFT
                        KEY_S: ak = KEY_DOWN
                        KEY_D: ak = KEY_RIGHT
                if ak != KEY_NONE:
                        _push_key(ak, (event as InputEventKey).pressed)
        # v0.4.1 THE GAMEPAD SEAT: d-pad = arrows, A/B/X/Y = the 1/2/3/4
        # keys, START = ESC (the back law). The translation lives in ONE
        # place - every game that already listens to those keys hears the
        # pad with zero per-game code, and the box menu scrolls with it.
        if event is InputEventJoypadButton:
                var jb := event as InputEventJoypadButton
                if jb.button_index == JOY_BUTTON_START:
                        if jb.pressed:
                                _go_back()
                                get_viewport().set_input_as_handled()
                        return
                var pk := _pad_button_key(jb.button_index)
                if pk != KEY_NONE:
                        _push_key(pk, jb.pressed)
                        get_viewport().set_input_as_handled()
                        return
        elif event is InputEventJoypadMotion:
                _pad_axes(event as InputEventJoypadMotion)
                return
        # v0.4.0-17 THE PC HOTKEY LAW (the owner's order): F11 or Alt+Enter
        # toggles fullscreen / windowed anywhere in the box. PC only, key
        # press only (no echo), and the splash keeps its skip touch.
        # v041-1 r4 THE HOLD LAW: the left button darkens the box cursor
        # (the hardware image swaps) - menu only, never over a game's seat.
        if event is InputEventMouseButton \
                        and (event as InputEventMouseButton).button_index \
                        == MOUSE_BUTTON_LEFT and ScaleRule.is_pc() \
                        and Box.pc_gogacursor() \
                        and GameHost.active_host == null:
                var pressed_now: bool = (event as InputEventMouseButton).pressed
                if pressed_now != _cur_held:
                        _cur_held = pressed_now
                        GogaCursorLib.set_held(_cur_held)
        if event is InputEventKey and (event as InputEventKey).pressed \
                        and not (event as InputEventKey).echo:
                var k := (event as InputEventKey).keycode
                if ScaleRule.is_pc():
                        if k == KEY_F11 or ((k == KEY_ENTER or k == KEY_KP_ENTER) \
                                        and (event as InputEventKey).alt_pressed):
                                ScaleRule.toggle_fullscreen()
                                get_viewport().set_input_as_handled()
                                return
                        # v0.4.1 THE ESC LAW: ESC is the phone's back button,
                        # 1:1 - pause game, close the top sheet, ask to leave.
                        if k == KEY_ESCAPE:
                                _go_back()
                                get_viewport().set_input_as_handled()
                                return
                        # v0.4.1 THE F10 POSITION LAW: flip the menu's
                        # position - main menu only, never under a sheet,
                        # never in a game (the owner's guard).
                        if k == KEY_F10 and GameHost.active_host == null \
                                        and _menu != null \
                                        and is_instance_valid(_menu) \
                                        and _menu.has_method("toggle_menu_position") \
                                        and not _menu.call("has_open_overlay"):
                                _menu.call("toggle_menu_position")
                                get_viewport().set_input_as_handled()
                                return
## v041-1 r4 THE HOLD LAW: the code darkening rides the HARDWARE cursor -
## a second bitmap (the glyph modulated 0.55, same code shadow) swaps in
## while the left button is held. Menu only: a click never re-paints the
## box cursor over a game's own seat (the ownership law).

## Android BACK button (config/quit_on_go_back=false routes it here) - and
## since v0.4.1 the PC's ESC and the gamepad's START ride the same road:
## in-game -> pause | sheet open -> close it | menu -> "leave GOGABox?"
func _notification(what: int) -> void:
        # v0.3.8-5: the app lifecycle rides the same hook (THE SLEEP LAW)
        if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_RESUMED:
                _lifecycle(what)
                return
        # v0.4.1 THE UNFOCUS PAUSE LAW (the owner: "make the app get paused
        # when un-focused on both platforms, pause is just the back button
        # pause menu... make it pause+mute"): losing focus opens the pause
        # sheet and silences the box; coming back keeps the pause up - the
        # player presses RESUME when ready (prepare to return, no
        # freeze-then-jump).
        if what == NOTIFICATION_APPLICATION_FOCUS_OUT \
                        or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
                _box_focus_out()
                return
        if what == NOTIFICATION_APPLICATION_FOCUS_IN \
                        or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
                _box_focus_in()
                return
        if what != NOTIFICATION_WM_GO_BACK_REQUEST:
                return
        _go_back()

## The one back road (Android back / PC ESC / gamepad START).
func _go_back() -> void:
        if _splash_alive:
                _end_splash()
                return
        if GameHost.active_host != null and is_instance_valid(GameHost.active_host):
                GameHost.active_host.request_pause()
                return
        if _menu != null and is_instance_valid(_menu) and _menu.has_method("handle_back"):
                _menu.call("handle_back")

# ================================================ v0.4.1 THE PC SEAT

## v041-1 r4 THE HARDWARE GOGACURSOR (game/core/goga_cursor.gd): the
## owner's own 32x32 arrow as an OS-composited cursor, the code shadow
## baked real-alpha, the code hold/click darkening, 1:1 with the OS
## pointer by definition. The OS carries the whole seat now.
const GogaCursorLib := preload("res://game/core/goga_cursor.gd")
var _cur_held := false
var _pad_held := {}
var _focus_muted := false
var _pre_focus_mute := false

## v0.4.1 THE FOCUS NUKE (the owner: "pressing keyboard arrows, arrows work
## like moving from button to button... and tab button do the same... i do
## not want tab or arrows to do that thing for buttons at all"). Every
## button and slider that ever joins the tree is born focus-proof - the
## GUI focus walk is dead, so Tab and the arrows are FREE for the feed and
## the games (menu._input / game input keep them).
func _nuke_focus(n: Node) -> void:
        if n is BaseButton or n is HSlider or n is VSlider:
                (n as Control).focus_mode = Control.FOCUS_NONE

## v0.4.1 DYNAMIC SCALE - RETIRED v041-1 (the owner: "remove it, it just
## made the app more blurry... nuke it"). The RCAS sharpen pass, its shader,
## its settings row and its Box flag are gone; set_dynamic_scale stays as a
## harmless no-op so any stale settings call cannot error.
func set_dynamic_scale(_on: bool) -> void:
        pass

## v041-1 r4 THE HARDWARE GOGACURSOR SEAT (game/core/goga_cursor.gd
## holds the laws): the owner's arrow is an OS-COMPOSITED cursor now -
## Input.set_custom_mouse_cursor with the code-baked real-alpha shadow.
## r2's software cursor died with the r1 render freeze (the pointer
## vanished WITH the app's presentation on his Windows GPU); a hardware
## cursor is drawn by the OS itself - it cannot vanish, cannot lag, and
## is 1:1 with the OS pointer by definition. No 1x1 silencing anymore:
## the image IS the seat. A game that hides the mouse (Heavy War) hides
## it for the OS too; a game that sets its own image replaces ours;
## on_game_closed re-arms (the engine cache short-circuits the call).
func _apply_gogacursor() -> void:
        if not ScaleRule.is_pc():
                return
        _cur_held = false
        if Box.pc_gogacursor():
                GogaCursorLib.arm()
        else:
                GogaCursorLib.disarm()

func set_gogacursor(on: bool) -> void:
        if on:
                _apply_gogacursor()
        else:
                if ScaleRule.is_pc():
                        GogaCursorLib.disarm()

## v041-1 r2: THE EDGE VEIL IS RETIRED (was _build_edge_veil, a 95-layer
## shading the app's own edges from above). The owner saw it riding ON TOP
## of the in-resolution area and ordered the sides flat: "give the sides
## just a #0a0a0a color ... later we may find a way to populate the sides
## more better". Nothing paints above the app anymore - the bars are the
## clear color (ScaleRule.PC_BAR_INK), the app is the app.

## v0.4.1 THE UNFOCUS PAUSE LAW helpers. Mute rides the MASTER bus and is
## restored exactly as it was; the pause sheet stays up until the player
## presses RESUME.
func _box_focus_out() -> void:
        if _focus_muted:
                return
        _focus_muted = true
        _pre_focus_mute = AudioServer.is_bus_mute(0)
        AudioServer.set_bus_mute(0, true)
        if GameHost.active_host != null and is_instance_valid(GameHost.active_host):
                GameHost.active_host.call("ensure_pause_for_box")

func _box_focus_in() -> void:
        if not _focus_muted:
                return
        _focus_muted = false
        AudioServer.set_bus_mute(0, _pre_focus_mute)

# ------------------------------------------------ the gamepad seat

func _pad_button_key(btn: JoyButton) -> Key:
        match btn:
                JOY_BUTTON_DPAD_UP:
                        return KEY_UP
                JOY_BUTTON_DPAD_DOWN:
                        return KEY_DOWN
                JOY_BUTTON_DPAD_LEFT:
                        return KEY_LEFT
                JOY_BUTTON_DPAD_RIGHT:
                        return KEY_RIGHT
                # v041-1 THE FACE-BUTTON LAW (the owner: "1,2,3,4 i meant the
                # square, triangle, circle, cross, also ABXY in Xbox"): the
                # count rides the PlayStation pad's shape order - square,
                # triangle, circle, cross - which is the Xbox pad's X, Y, B, A
                # (Godot: X=left, Y=top, B=right, A=bottom).
                JOY_BUTTON_X:
                        return KEY_1
                JOY_BUTTON_Y:
                        return KEY_2
                JOY_BUTTON_B:
                        return KEY_3
                JOY_BUTTON_A:
                        return KEY_4
        return KEY_NONE

func _push_key(keycode: Key, pressed: bool) -> void:
        var ev := InputEventKey.new()
        ev.keycode = keycode
        ev.physical_keycode = keycode
        ev.pressed = pressed
        Input.parse_input_event(ev)

## The left stick speaks the d-pad's language (edge-triggered at 0.55).
func _pad_axes(ev: InputEventJoypadMotion) -> void:
        if ev.axis == JOY_AXIS_LEFT_X:
                _pad_axis("left", ev.axis_value < -0.55, KEY_LEFT)
                _pad_axis("right", ev.axis_value > 0.55, KEY_RIGHT)
        elif ev.axis == JOY_AXIS_LEFT_Y:
                _pad_axis("up", ev.axis_value < -0.55, KEY_UP)
                _pad_axis("down", ev.axis_value > 0.55, KEY_DOWN)

func _pad_axis(pname: String, on: bool, key: Key) -> void:
        var was := bool(_pad_held.get(pname, false))
        if on == was:
                return
        _pad_held[pname] = on
        _push_key(key, on)
