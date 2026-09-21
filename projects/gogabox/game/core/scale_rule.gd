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

# ============================================================ THE PC LAWS
## v0.3.4-3 - GOGABox runs on WINDOWS too now (the owner's two-build wish:
## 64-bit + 32-bit, SSE2 baseline). The window laws that only matter on a
## desktop live here.
##
## v0.4.1 THE DESIGN FOLLOWS THE CONTENT LAW (the owner's vertical-fullscreen
## kill): the old want_for(window px) rule FORCED the LANDSCAPE design onto
## the portrait menu in fullscreen on a 16:9 monitor - the menu painted
## sideways-hybrid, clicks landed wrong, and the "black sides" were really
## the EXPAND canvas reaching past the content with live clicks inside. The
## law now: on a desktop the design is picked by WHAT IS SHOWING (the menu's
## position choice, the game's orientation) - the window's aspect NEVER
## picks a design again. The window either RESHAPES to the content (re_window)
## or the content letterboxes inside it with the flat #0a0a0a ink (KEEP).

## v041-1 r2 THE FLAT SIDES LAW (the owner: "give the sides just a
## #0a0a0a color, will be more focused on the game this way, later we may
## find a way to populate the sides more better"): the bars wear FLAT
## near-black ink - no brown, no edge veil on top of the app (the veil is
## retired with the brown). One honest color, focus on the game.
const PC_BAR_INK := Color(0.0392157, 0.0392157, 0.0392157)  # #0a0a0a

## v041-1 r3 THE WINDOW TRUTH LAW (the owner's r2 video: the app booting
## into a full-brown window, the menu clipped into a corner strip, the
## phantom empty screens, no cursor). RIG-REPRODUCED ROOT CAUSE: the root
## Window's internal `size` only updates through the WM-resize event or
## the Window PROPERTY path - a raw DisplayServer.window_set_size
## (re_window, the mode flips, a WM restore race) can leave Window.size
## STALE FOREVER: the stretch final-transform keeps mapping the design
## onto the BOOT rect while the real window moved (rig probe: ds_px=(1256,
## 705) with win.size=(720,1280) and the final transform frozen at the
## boot scale - everything the owner saw follows from that one desync).
## The watchdog re-seats OS truth through the property path -
## Window.set_size ALWAYS re-runs _update_viewport_size(), so the
## transform heals THE SAME FRAME, no WM event needed. No feedback loop:
## OS truth is read, never written back. Transient (0,0) reports during
## mode flips are skipped, headless probes are skipped.
static func sync_window(win: Window) -> bool:
        if win == null:
                return false
        if DisplayServer.get_name() == "headless":
                return false
        var real := DisplayServer.window_get_size()
        if real.x <= 0 or real.y <= 0:
                return false
        if win.size == real:
                return false
        win.size = real
        return true

## The root Window (static helpers have no `get_window`).
static func root_window() -> Window:
        var tree := Engine.get_main_loop() as SceneTree
        return tree.root if tree != null else null

## The engine's stretch mapping (design px -> real window px) rebuilt
## from DISPLAYSERVER TRUTH - singular-proof (v041-1 r3). The engine's
## get_final_transform() answers from Window.size, which the desync above
## can leave stale (or transiently 0x0 during mode flips - a singular
## matrix whose affine_inverse() poisoned the software cursor into
## invisibility on the owner's Windows). The box's PC stretch law is KEEP
## (apply_pc) - that branch is computed exactly from OS truth; anything
## else (phone EXPAND, headless fakes) falls back to the engine's own
## answer. Determinant is always > 0: real px and the design are nonzero.
static func final_transform_of(win: Window) -> Transform2D:
        if win == null:
                return Transform2D()
        if win.content_scale_aspect != Window.CONTENT_SCALE_ASPECT_KEEP:
                return win.get_final_transform()
        var wpx := DisplayServer.window_get_size()
        var cs := win.content_scale_size
        if wpx.x <= 0 or wpx.y <= 0 or cs.x <= 0 or cs.y <= 0:
                return win.get_final_transform()
        var f := win.content_scale_factor
        if f <= 0.0:
                f = 1.0
        var s := minf(float(wpx.x) / float(cs.x), float(wpx.y) / float(cs.y)) * f
        var margin := (Vector2(wpx) - Vector2(cs) * s) * 0.5
        return Transform2D(Vector2(s, 0.0), Vector2(0.0, s), margin)

## A real desktop session: not a phone/tablet, not the headless test runs.
## The headless guard keeps every probe and CI run on the phone rules.
static func is_pc() -> bool:
        if OS.has_feature("android") or OS.has_feature("ios"):
                return false
        if DisplayServer.get_name() == "headless":
                return false
        return OS.has_feature("windows") or OS.has_feature("linux") \
                        or OS.has_feature("macos")

## THE MENU'S POSITION CHOICE (v0.4.1, F10 + the settings row): "portrait"
## or "landscape". Separated from pc_kind on purpose - a landscape GAME
## must not leave the menu living sideways after it closes. Persisted by
## the menu through the Box settings (pc_position).
static var pc_position := "portrait"

## The design the MENU wants on a PC: from the position choice, never from
## the window's shape.
static func pc_menu_design() -> Vector2i:
        return DESIGN_LANDSCAPE if pc_position == "landscape" \
                        else DESIGN_PORTRAIT

## THE PC STRETCH LAW (v0.4.1 - the vertical slice generalized): on a
## desktop EVERY design renders KEEP-aspect - the window either matches the
## design (windowed, after re_window: no bars at all) or the bars wear the
## flat #0a0a0a ink (fullscreen, or any shape the user drags into). EXPAND is a
## phone law - a desktop canvas must never grow past its content again.
## Returns true when the mode had to move (callers may reflow).
static func apply_pc(win: Window, design: Vector2i) -> bool:
        if win == null:
                return false
        # v041-1 r3 THE WINDOW TRUTH LAW: heal any OS-vs-Window desync
        # FIRST (the governor runs this every frame - the freeze class is
        # structurally dead; see sync_window).
        sync_window(win)
        var changed := false
        if win.content_scale_aspect != Window.CONTENT_SCALE_ASPECT_KEEP:
                win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
                changed = true
        RenderingServer.set_default_clear_color(PC_BAR_INK)
        if win.content_scale_size != design:
                win.content_scale_size = design
                changed = true
        # v041-1 THE BAR PAINT LAW (the owner: "for the sides, they are
        # showing black"). Root cause, rig-verified: with aspect KEEP the
        # engine ATTACHES the root viewport to the design rect only - the
        # rest of the window is never rendered and shows the raw window
        # background (black), no matter what the clear color says. The fix
        # is one attach: hand the viewport the WHOLE window again; the canvas
        # transform still centers the design, and the margins wear the flat
        # #0a0a0a ink (v041-1 r2: the brown + the edge veil are retired).
        # Cheap RID call; re-asserted on every apply_pc (the governor runs
        # it every frame, so a window reshape can never leave it stale).
        RenderingServer.viewport_attach_to_screen(win.get_viewport_rid(),
                        Rect2i(), 0)
        return changed

## The vertical slice (kept for compatibility - apply_pc is the law now).
static func apply_vertical_slice(win: Window, design: Vector2i) -> bool:
        return apply_pc(win, design)

## The phone rule again: EXPAND fills every window edge-to-edge.
static func apply_expand(win: Window) -> bool:
        if win == null:
                return false
        if win.content_scale_aspect != Window.CONTENT_SCALE_ASPECT_EXPAND:
                win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
                return true
        return false

## Are the ink bars on screen right now? (one honest read - the round-2
## sides wear flat #0a0a0a and nothing paints above the app anymore).
static func bars_visible(win: Window) -> bool:
        if win == null:
                return false
        if win.content_scale_aspect != Window.CONTENT_SCALE_ASPECT_KEEP:
                return false
        var wpx := DisplayServer.window_get_size()
        var cs := win.content_scale_size
        if wpx.x <= 0 or wpx.y <= 0 or cs.x <= 0 or cs.y <= 0:
                return false
        var sw := float(wpx.x) / float(cs.x)
        var sh := float(wpx.y) / float(cs.y)
        return absf(sw - sh) > 0.005

# ================================================== THE PC WINDOW LAWS
## v0.4.0-17 (the owner's first Windows test round): the WINDOW follows the
## CONTENT in windowed mode. The owner: "it should be internally 1:1 ...
## 1280x720 or even 4K, all should work ... make pressing F11 or alt+enter
## go full screen or return windowed ... make it in vertical games to
## re-window itself to have no empty sides."
##   - THE 1:1 LAW: stretch canvas_items renders at the REAL window
##     resolution on every size (720p, FHD, 4K) - the design constants are
##     a logical canvas, never an upscale target. Nothing extra to code:
##     any window size works, and the laws below just pick a good shape.
##   - THE RE-WINDOW LAW: windowed, the window RESHAPES itself to the
##     content's aspect - portrait content (the box menu, portrait games)
##     gets a 9:16 window, landscape games get a 16:9 window - so the
##     vertical slice renders with NO empty sides. The vertical slice law
##     above stays as the fallback for whatever aspect the user drags the
##     window into (ink bars, never stretched).
##   - THE FULLSCREEN LAW: F11 / Alt+Enter anywhere, or the SETTINGS
##     toggle (Windows build), flips WINDOW_MODE_FULLSCREEN <-> WINDOWED.
##     Fullscreen is a monitor - it cannot reshape - so portrait content
##     falls back to the vertical slice with the flat ink sides. The
##     choice persists in the Box settings (pc_fullscreen) and re-applies
##     at boot.

## The content kind currently driving the window shape:
## "portrait" (the menu in its vertical position + portrait games) or
## "landscape". NOT the menu's persisted position choice - that is
## pc_position above; a landscape game re_windows the window and hands it
## back to pc_position's shape on the way out.
static var pc_kind := "portrait"

static func is_fullscreen() -> bool:
        var m := DisplayServer.window_get_mode()
        return m == DisplayServer.WINDOW_MODE_FULLSCREEN \
                        or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

## v041-1 THE WINDOWED LOCK LAW (the owner: "i want you to lock the windowed
## window from getting stretched at all, this will be better"). The windowed
## window is NOT user-resizable anymore: its shape is ALWAYS exactly the
## content's shape (re_window) - nothing can drag it off-aspect, so the
## whole stretch/mis-scale/resize-flicker family is structurally dead.
## Fullscreen ignores the flag (the monitor owns the shape there).
static func apply_window_lock() -> void:
        if DisplayServer.get_name() == "headless":
                return
        DisplayServer.window_set_flag(
                        DisplayServer.WINDOW_FLAG_RESIZE_DISABLED,
                        not is_fullscreen())

## Re-shape the window to `kind` ("portrait" | "landscape") in WINDOWED
## mode, centered on the window's screen. Fullscreen: remember the kind and
## leave the monitor alone. Headless/no-display: no-op (probes stay safe).
static func re_window(kind: String) -> void:
        if kind != "landscape" and kind != "portrait":
                return
        pc_kind = kind
        if DisplayServer.get_name() == "headless":
                return
        if is_fullscreen():
                return
        var scr := _usable_rect()
        var want: Vector2i
        if kind == "portrait":
                # 9:16 like the design, 90% of the screen height, sane caps
                var h := clampi(int(float(scr.size.y) * 0.9), 480, 1440)
                want = Vector2i(h * 9 / 16, h)
        else:
                # 16:9 like the design (the classic 1280x720 window), 80%
                # of the screen width, sane caps
                var w := clampi(int(float(scr.size.x) * 0.8), 640, 1600)
                want = Vector2i(w, w * 9 / 16)
        want.x = mini(want.x, scr.size.x)
        want.y = mini(want.y, scr.size.y)
        DisplayServer.window_set_size(want)
        DisplayServer.window_set_position(
                        scr.position + (scr.size - want) / 2)
        apply_window_lock()
        # v041-1 r3: the WM event may never come (boot-time resizes, WM-less
        # sessions, the Windows restore race) - re-seat the truth NOW so the
        # stretch transform is correct from the very first frame.
        sync_window(root_window())

## THE FULLSCREEN LAW: flip, persist, and on the way back to windowed
## re-window to the content kind so no empty sides return with it. The
## design does NOT ride the window shape anymore (KEEP + the content's
## design stay glued), so the stretched-window -> fullscreen -> restore
## scale bug is structurally dead: the design never depended on the window.
static func toggle_fullscreen() -> void:
        set_fullscreen(not is_fullscreen())

static func set_fullscreen(on: bool) -> void:
        if DisplayServer.get_name() == "headless":
                return
        if on == is_fullscreen():
                return
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN
                        if on else DisplayServer.WINDOW_MODE_WINDOWED)
        if Box.has_method("set_pc_fullscreen"):
                Box.set_pc_fullscreen(on)
        # v041-1: the lock flips with the mode (fullscreen unlocks the flag,
        # windowed locks the shape) and the window re-shapes to the content
        # kind AFTER the mode settled - the deferred pass makes the Windows
        # restore-animation race structurally dead (the owner's "fullscreen
        # in-game prevents me to go windowed until i exit the game").
        apply_window_lock()
        sync_window(root_window())
        if not on:
                re_window(pc_kind)
                _rewindow_deferred()

## One-frame-later re-assert of the windowed shape (static helper piggy-
## backing a fresh frame: DisplayServer calls land after the WM settled).
static func _rewindow_deferred() -> void:
        var tree: SceneTree = Engine.get_main_loop() as SceneTree
        if tree == null:
                return
        tree.create_timer(0.05).timeout.connect(func():
                if not is_fullscreen():
                        re_window(pc_kind)
                        apply_window_lock())

## The boot law (main._ready): honor the persisted choice once.
static func boot_window() -> void:
        if not is_pc() or DisplayServer.get_name() == "headless":
                return
        var want_fs: bool = Box.has_method("pc_fullscreen") \
                        and Box.call("pc_fullscreen")
        if want_fs:
                DisplayServer.window_set_mode(
                                DisplayServer.WINDOW_MODE_FULLSCREEN)
        else:
                re_window(pc_kind)
        apply_window_lock()
        sync_window(root_window())

static func _usable_rect() -> Rect2i:
        var scr := DisplayServer.window_get_current_screen()
        var r := DisplayServer.screen_get_usable_rect(scr)
        if r.size.x <= 0 or r.size.y <= 0:
                r = Rect2i(Vector2i.ZERO, Vector2i(1280, 720))
        return r
