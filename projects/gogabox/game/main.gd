extends Node2D
## GOGABox bootstrap: splash -> menu. Games are hosted on top of the menu
## (GameHost), achievement popups float above everything (Achiever).
## The Android BACK button routes here: pause game -> close sheet -> leave box.

var _splash_layer: CanvasLayer
var _splash_root: Control
var _splash_alive := false
var _menu: Node2D

func _ready() -> void:
        # v0.1.0 THE DENSITY RULE (owner: "make the resolution bigger / use the
        # phone native resolution so things look smaller"). With stretch
        # canvas_items+expand the 720 base was stretched 1.5x on a 1080-wide
        # phone, so every control rendered 1.5x bigger than its designer px.
        # We instead target a LOGICAL viewport equal to the device's real
        # pixels (clamped): content_scale_factor = 720 / short_side_px.
        #   1080x2400 phone -> 1080x2400 logical viewport (1.5x more room,
        #   everything physically smaller, text still rasterized sharp).
        # MUST run before the menu builds (it reads the viewport size).
        _apply_density()
        # menu is built immediately, the splash covers it while the engine warms up
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

## Content scale factor = 720 / target, where target = the device's short
## side in REAL px clamped to [840, 1152]:
##   - 1080p-class phones  -> ~0.667 (native logical resolution - the owner's
##     device; probe-verified: top bar + carousel arrows all fit),
##   - 1440p-class flagships -> capped at 0.625 so UI never gets microscopic,
##   - small/720p-class devices -> floored at 0.857 (logical 840 wide). The
##     measured UI needs ~796 logical px (top bar 764 + margins) - below that
##     the gear icon and the top-picks right arrow hang off-screen (probe:
##     config A). 840 leaves ~40px headroom for wider battery-chip labels.
## Headless tests: the virtual window is 720x1280 -> the floor applies ->
## tests see 840x1493. Rotation never changes the short side.
func _apply_density() -> void:
        var screen := DisplayServer.screen_get_size()
        var short_px := float(mini(screen.x, screen.y))
        var target := clampf(short_px, 840.0, 1152.0)
        get_window().content_scale_factor = 720.0 / target

## A game is its OWN WORLD: while it runs the menu is fully hidden AND stops
## processing - no layering weirdness, no taps leaking into the feed, no
## "double taps". v0.0.4 tried this but two engine facts defeated it:
##   1) Node2D.visible=false does NOT hide a child CanvasLayer (menu UI lives
##      on one) - so the menu kept rendering behind the game, and
##   2) launch() was handed the MENU as router, so this method never ran.
## menu.set_active() now handles BOTH the Node2D and the CanvasLayer.
func on_game_entered() -> void:
        if _menu != null and is_instance_valid(_menu) and _menu.has_method("set_active"):
                _menu.call("set_active", false)

func on_game_closed() -> void:
        if _menu != null and is_instance_valid(_menu) and _menu.has_method("set_active"):
                _menu.call("set_active", true)
                if _menu.has_method("on_game_closed"):
                        _menu.call("on_game_closed")

func _show_splash() -> void:
        _splash_layer = CanvasLayer.new()
        _splash_layer.layer = 20
        add_child(_splash_layer)

        _splash_root = Control.new()
        _splash_root.set_anchors_preset(Control.PRESET_FULL_RECT)
        _splash_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _splash_layer.add_child(_splash_root)

        # opaque veil FIRST - without it the feed renders for a frame or two
        # while splash.png decodes (the "menu flashes before the splash" glitch)
        var veil := ColorRect.new()
        veil.color = Color(0.227451, 0.137255, 0.074510, 1.0)
        veil.set_anchors_preset(Control.PRESET_FULL_RECT)
        veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _splash_root.add_child(veil)

        var art := TextureRect.new()
        art.texture = load("res://assets/ui/splash.png")
        art.set_anchors_preset(Control.PRESET_FULL_RECT)
        art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        # FIT (not COVER): COVER crops top/bottom on 20:9 screens and the
        # wordmark left the screen. The veil behind matches the art's bg color.
        art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        art.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _splash_root.add_child(art)

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
