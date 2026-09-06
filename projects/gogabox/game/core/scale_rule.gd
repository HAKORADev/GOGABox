class_name ScaleRule
## v0.1.3 THE RESOLUTION & SCALE RULE - the ONE source of truth for how
## GOGABox maps its internal design onto ANY phone window.
##
## OWNER CONTRACT (v0.1.3, after the v0.1.2 device test):
##   "work hard on the resolution handler and scaling system to manage the
##    aspect ratios and resolutions for the phone window while keeping the
##    internal resolution the same for the app."
##   The three v0.1.2 device screenshots: portrait letterboxed (bars),
##   landscape-opened showed the PORTRAIT design dead-center with black
##   sides, and a rotation ping-pong left a squashed hybrid. All three are
##   the same disease: aspect KEEP letterboxes instead of filling, and the
##   design decision depended on catching one signal at the right moment.
##
## THE v0.1.3 SYSTEM (every piece structural, no signal-timing luck):
##   1. INTERNAL RESOLUTION IS FIXED: 1080x1920 portrait / 1920x1080
##      landscape (9:16 / 16:9, the owner's FHD+ renders 1:1 native). These
##      two constants are the only design sizes in the whole codebase.
##   2. THE WINDOW IS ALWAYS FILLED: project.godot stretch mode
##      canvas_items + aspect EXPAND. The engine scales the design by
##      min(win/design) and GROWS the canvas in the spare direction - the
##      design is the minimum room, any taller/wider phone gets extra
##      canvas in design px. NO bars on ANY device, NOTHING distorted.
##   3. THE DESIGN FOLLOWS THE WINDOW PIXELS: want_for() decides portrait
##      vs landscape from the REAL window px (DisplayServer), never from
##      design-space state that could stick.
##   4. THE GOVERNOR: menu.apply_resolution() (called by main._process
##      every frame) re-applies the rule and reflows when the design had to
##      move. get_window().size_changed stays hooked for same-frame swaps,
##      but the governor makes "stuck in the wrong design" structurally
##      impossible: even a missed signal is corrected within one frame.
##   5. SAFE AREA: window insets (notch / status bar / gesture bar) are
##      converted to design px and padded into the menu margins, so with
##      the canvas now reaching every edge nothing sits under a cutout.

const DESIGN_PORTRAIT := Vector2i(1080, 1920)
const DESIGN_LANDSCAPE := Vector2i(1920, 1080)

## The design that matches a REAL window pixel size. Degenerate (0 or
## negative, headless fakes) falls back to portrait - the boot default.
static func want_for(ws: Vector2i) -> Vector2i:
        if ws.x <= 0 or ws.y <= 0:
                return DESIGN_PORTRAIT
        return DESIGN_LANDSCAPE if ws.x > ws.y else DESIGN_PORTRAIT

## Apply the rule to the root window from the REAL window pixels.
## Returns true only when the design actually had to move (so callers can
## reflow). Cheap no-op at steady state - safe to call every frame.
static func apply(win: Window) -> bool:
        if win == null:
                return false
        var ws := DisplayServer.window_get_size()
        if ws.x <= 0 or ws.y <= 0:
                return false
        var want := want_for(ws)
        if win.content_scale_size == want:
                return false
        win.content_scale_size = want
        return true

## Real screen px per design px under aspect EXPAND: the engine scales by
## min(win/design) and stretches the canvas by exactly the same factor in
## BOTH directions (the spare axis just gets more design px), so min() is
## the scale - and win/vp for any axis equals it too.
static func scale_of(win: Window) -> float:
        var wpx := DisplayServer.window_get_size()
        var cs := win.content_scale_size
        if wpx.x <= 0 or wpx.y <= 0 or cs.x <= 0 or cs.y <= 0:
                return 1.0
        return minf(float(wpx.x) / float(cs.x), float(wpx.y) / float(cs.y))

## The OS safe area (display cutout / status bar / gesture navigation) as
## per-side insets converted to DESIGN px: Vector4(left, top, right, bottom).
## Everything outside the safe area is reachable-but-covered screen edge,
## which the menu pads into its page margins.
static func safe_insets_design(win: Window) -> Vector4:
        var wpx := DisplayServer.window_get_size()
        if wpx.x <= 0 or wpx.y <= 0:
                return Vector4.ZERO
        var area := DisplayServer.get_display_safe_area()
        if area.size.x <= 0 or area.size.y <= 0:
                return Vector4.ZERO
        # screen coords -> window-local (fullscreen on Android: pos 0,0)
        area.position -= DisplayServer.window_get_position()
        area = area.intersection(Rect2i(Vector2i.ZERO, wpx))
        if area.size.x <= 0 or area.size.y <= 0:
                return Vector4.ZERO
        var s := scale_of(win)
        if s <= 0.0:
                return Vector4.ZERO
        return Vector4(
                float(area.position.x) / s,
                float(area.position.y) / s,
                float(wpx.x - area.end.x) / s,
                float(wpx.y - area.end.y) / s)
