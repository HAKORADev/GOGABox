extends Node2D
## GOGABox bootstrap: splash -> menu. Games are hosted on top of the menu
## (GameHost), achievement popups float above everything (Achiever).
## The Android BACK button routes here: pause game -> close sheet -> leave box.

var _splash_layer: CanvasLayer
var _splash_root: Control
var _splash_alive := false
var _menu: Node2D

func _ready() -> void:
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

## v0.1.3 THE GOVERNOR - the resolution system's safety net. Every frame
## (menu in the box, splash included) re-decide the design from the REAL
## window pixels. At steady state this is one Vector2i compare; when the
## window changed (boot-in-landscape races, system-driven rotations the
## size_changed hook missed, resume after a background kill) the design and
## the whole layout self-correct within one frame. "Stuck in the wrong
## design" - the v0.1.2 opened-as-landscape screenshot - is structurally
## impossible now. During a GAME the host owns content_scale_size (its
## orientation lock + design swap); the governor must not fight it.
func _process(_delta: float) -> void:
        if GameHost.active_host != null:
                return
        if _menu != null and is_instance_valid(_menu) \
                        and _menu.has_method("apply_resolution"):
                _menu.call("apply_resolution")

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

func _show_splash() -> void:
        _splash_layer = CanvasLayer.new()
        _splash_layer.layer = 20
        add_child(_splash_layer)

        _splash_root = Control.new()
        _splash_root.set_anchors_preset(Control.PRESET_FULL_RECT)
        _splash_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _splash_layer.add_child(_splash_root)

        # opaque veil FIRST - without it the feed renders for a frame or two
        # while the logo decodes (the "menu flashes before the splash" glitch)
        var veil := ColorRect.new()
        veil.color = Color(0.227451, 0.137255, 0.074510, 1.0)
        veil.set_anchors_preset(Control.PRESET_FULL_RECT)
        veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _splash_root.add_child(veil)

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
        if not is_instance_valid(_splash_root):
                return
        var out := create_tween()
        out.tween_property(_splash_root, "modulate:a", 0.0, 0.4)
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

## Android BACK button (config/quit_on_go_back=false routes it here):
## in-game -> pause | sheet open -> close it | menu -> "leave GOGABox?"
func _notification(what: int) -> void:
        if what != NOTIFICATION_WM_GO_BACK_REQUEST:
                return
        if _splash_alive:
                _end_splash()
                return
        if GameHost.active_host != null and is_instance_valid(GameHost.active_host):
                GameHost.active_host.request_pause()
                return
        if _menu != null and is_instance_valid(_menu) and _menu.has_method("handle_back"):
                _menu.call("handle_back")
