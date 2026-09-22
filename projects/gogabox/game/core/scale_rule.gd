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

## v041-1 r5 THE PHONE-ONLY LAW (the owner's fullscreen bottom band):
## desktops answer ZERO - the engine's Windows get_display_safe_area()
## is screen_get_usable_rect() = THE WORK AREA (monitor minus taskbar),
## so in fullscreen the taskbar height leaked in as a bogus bottom inset
## and the feed was padded up off the screen's bottom edge (the brown
## band with the lone page dot - "in windowed, it is ok, but fullscreen
## ... not too accurate"). A desktop window never overlaps a system bar
## the phone way: no notch, no gesture bar - the padding is a PHONE law.
static func safe_insets_design(win: Window) -> Vector4:
        if is_pc():
                return Vector4.ZERO
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

## v041-1 r5 THE ONE-WRITER NUKE (the owner: "try to nuke every single
## stupid and wrong windowing thing ... the same way you did with the
## brown-overlay bug"): the r1-r4 machinery is GONE - sync_window (a
## per-frame Window.size property write that fought the OS during every
## mode flip; the engine's own WM_SIZE echo is the only honest road on a
## real desktop, and every build through v041 shipped on it),
## final_transform_of (the r3 software-cursor relic - the cursor is
## OS-composited hardware since r4), _rewindow_deferred (the 0.05s timer
## that re-shaped the window twice) and the per-frame lock writes. The
## window now has ONE writer (ScaleRule, on state changes only) and the
## engine owns the present path. THE ENGINE PROOFS (4.7
## display_server_windows.cpp): window_set_size AND window_set_position
## silently RETURN when wd.fullscreen || wd.maximized, and
## window_set_position internally MOVES THE WINDOW AT wd.width/height
## (the bookkeeping size) - so a size-then-position pair can resize the
## window BACK to the stale bookkeeping size when the WM_SIZE echo has
## not been pumped yet (the owner's "mis-size windowed window, but not
## always"). re_window below therefore sets the POSITION FIRST and the
## SIZE LAST (window_set_size preserves the current rect position), and
## set_fullscreen normalizes the MAXIMIZED bookkeeping before/after the
## mode flips (the maximized pre_fs_rect is what made F11 bounce between
## two screen-covering look-alikes - the "corrupted fullscreen").
## The root Window (static helpers have no `get_window`).
static func root_window() -> Window:
        var tree := Engine.get_main_loop() as SceneTree
        return tree.root if tree != null else null

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
        var changed := false
        if win.content_scale_aspect != Window.CONTENT_SCALE_ASPECT_KEEP:
                win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
                changed = true
        RenderingServer.set_default_clear_color(PC_BAR_INK)
        if win.content_scale_size != design:
                win.content_scale_size = design
                changed = true
        # v041-1 r4 THE PRESENT-PATH NUKE (the owner: "track the code step
        # by step until you find and ensure this is the bug and nuke it").
        # r1's BAR PAINT LAW called RenderingServer.viewport_attach_to_screen
        # with an EMPTY rect here EVERY FRAME. The engine source (4.7
        # renderer_viewport.cpp) proves what that does: once the root
        # viewport is attached to a screen, the engine blits its render
        # target straight to the window, and with an empty rect the blit
        # destination is (0,0) + the viewport's INTERNAL size - the engine's
        # own letterbox mapping (attach_to_screen_rect = Rect2(margin,
        # screen_size), re-seated by Window::_update_viewport_size on every
        # WM resize) is overwritten every frame, the content loses its
        # centering margin, and because dst == rt->size the GLES3 blit's
        # clear-to-black branch never runs either - the window surface
        # outside the blit keeps STALE bytes. The rig (llvmpipe, WM-less)
        # still painted through it; the owner's real Windows GL driver
        # stopped presenting after the splash entirely (his film: the flat
        # splash-brown freeze, the menu never painting, the sticky black on
        # Maximize when the swapchain reallocated, the software cursor gone
        # with the dead render path). THE CALL IS GONE - the present path
        # is the engine's own again, the exact road every build through
        # v041 shipped on. The bars: windowed re_window shapes the window
        # to the design (no bars at all); fullscreen off-aspect letterboxes
        # through the engine (the GLES3 blit clears the bars near-black -
        # visually the #0a0a0a ink; the clear color above paints the render
        # target's own clear).
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

## v041-1 r5 THE TRUE WINDOWED LOCK (the owner: "lock the windowed window
## from getting stretched at all"). The r1 lock set ONLY RESIZE_DISABLED -
## and the engine's own style table (display_server_windows.cpp
## _get_window_style) proves that a locked window STILL wears
## WS_MAXIMIZEBOX: the maximize button stayed alive, a maximized window
## poisoned the engine's pre_fs_rect with a screen-covering rect, and the
## next fullscreen exit restored that rect as a "windowed" window that
## COVERS THE SCREEN - the owner's corrupted fullscreen ("it still say it
## is windowed while it is full screen", F11 bouncing between two
## look-alikes, F10 the only escape). The lock now kills BOTH flags in
## windowed (the style table strips WS_MAXIMIZEBOX when no_max_btn is
## set - the maximize button truly dies, the poisoned state can never
## form), clears both in fullscreen, and is IDEMPOTENT: the last applied
## value is cached - a repeated call with the same state writes NOTHING
## (each real write rebuilds the window style on Windows; a per-frame or
## mid-flip write was the flicker fuel).
static var _lock_applied := -1

static func apply_window_lock() -> void:
        if DisplayServer.get_name() == "headless":
                return
        var want := 0 if is_fullscreen() else 1
        if _lock_applied == want:
                return
        _lock_applied = want
        DisplayServer.window_set_flag(
                        DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, want == 1)
        DisplayServer.window_set_flag(
                        DisplayServer.WINDOW_FLAG_MAXIMIZE_DISABLED, want == 1)

## Re-shape the window to `kind` ("portrait" | "landscape") in WINDOWED
## mode, centered on the window's screen. Fullscreen: remember the kind and
## leave the monitor alone. Headless/no-display: no-op (probes stay safe).
## v041-1 r5 THE POSITION-FIRST ORDER: window_set_position MOVES the
## window at the engine's bookkeeping size (wd.width/height), so sizing
## first and positioning second could silently shrink the window back to
## the STALE size (the WM_SIZE echo had not pumped yet - the owner's
## "mis-size ... but not always"). Position first (a pure move at the
## current size), size last (window_set_size keeps the current rect
## position) - the end rect is exact in every pump timing.
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
        DisplayServer.window_set_position(
                        scr.position + (scr.size - want) / 2)
        DisplayServer.window_set_size(want)
        apply_window_lock()

## THE FULLSCREEN LAW: flip, persist, and on the way back to windowed
## re-window to the content kind so no empty sides return with it. The
## design does NOT ride the window shape anymore (KEEP + the content's
## design stay glued), so the stretched-window -> fullscreen -> restore
## scale bug is structurally dead: the design never depended on the window.
static func toggle_fullscreen() -> void:
        set_fullscreen(not is_fullscreen())

## THE FULLSCREEN LAW (v041-1 r5 THE MODE-TRUTH DANCE): every transition
## normalizes the engine's bookkeeping FIRST, flips ONCE, settles the
## shape after. THE MAXIMIZE TRAP (the engine source): entering
## fullscreen from a MAXIMIZED window saves the screen-covering rect as
## pre_fs_rect, and exiting restores it - a "windowed" window that
## covers the screen (the owner's corrupted fullscreen: "the app still
## say it is windowed while it is full screen", F11 dead, F10 the only
## escape). The dance: (1) entering - if the bookkeeping says MAXIMIZED,
## drop to WINDOWED first (the engine restores the pre-maximize rect),
## then fullscreen; (2) exiting - after WINDOWED, if the bookkeeping
## landed MAXIMIZED (was_maximized_pre_fs), force WINDOWED again (SW_NORMAL)
## before re_window shapes the real windowed size. One deferred settle
## (a single frame - never a timer, never a second re_window) finishes
## the job after the WM echo pumped. The design does NOT ride the window
## shape (KEEP + the content's design stay glued).
static func set_fullscreen(on: bool) -> void:
        if DisplayServer.get_name() == "headless":
                return
        if on == is_fullscreen():
                return
        # (1) entering: a MAXIMIZED start poisons pre_fs_rect - normalize.
        if on and DisplayServer.window_get_mode() \
                        == DisplayServer.WINDOW_MODE_MAXIMIZED:
                DisplayServer.window_set_mode(
                                DisplayServer.WINDOW_MODE_WINDOWED)
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN
                        if on else DisplayServer.WINDOW_MODE_WINDOWED)
        if Box.has_method("set_pc_fullscreen"):
                Box.set_pc_fullscreen(on)
        # (2) exiting: the engine may restore the pre-fs MAXIMIZED state
        # (was_maximized_pre_fs) - a covering "windowed" window. Force the
        # honest SW_NORMAL bookkeeping, then shape the window for real.
        if not on and DisplayServer.window_get_mode() \
                        == DisplayServer.WINDOW_MODE_MAXIMIZED:
                DisplayServer.window_set_mode(
                                DisplayServer.WINDOW_MODE_WINDOWED)
        apply_window_lock()
        if not on:
                re_window(pc_kind)
                _settle_deferred()

## One-frame-later settle: the lock flips only after the mode echo pumped
## (a mid-flip style rebuild was flicker fuel), and the windowed shape is
## asserted once more - one call, no timers, idempotent by construction.
static func _settle_deferred() -> void:
        var tree: SceneTree = Engine.get_main_loop() as SceneTree
        if tree == null:
                return
        tree.process_frame.connect(_settle_now, CONNECT_ONE_SHOT)

static func _settle_now() -> void:
        if is_fullscreen():
                return
        re_window(pc_kind)
        apply_window_lock()

## The boot law (main._ready): honor the persisted choice once.
static func boot_window() -> void:
        if not is_pc() or DisplayServer.get_name() == "headless":
                return
        var want_fs: bool = Box.has_method("pc_fullscreen") \
                        and Box.call("pc_fullscreen")
        if want_fs:
                # a MAXIMIZED bookkeeping at boot would poison pre_fs_rect
                # (the maximize trap) - normalize first, exactly like the
                # runtime dance.
                if DisplayServer.window_get_mode() \
                                == DisplayServer.WINDOW_MODE_MAXIMIZED:
                        DisplayServer.window_set_mode(
                                        DisplayServer.WINDOW_MODE_WINDOWED)
                DisplayServer.window_set_mode(
                                DisplayServer.WINDOW_MODE_FULLSCREEN)
        else:
                re_window(pc_kind)
        apply_window_lock()

static func _usable_rect() -> Rect2i:
        var scr := DisplayServer.window_get_current_screen()
        var r := DisplayServer.screen_get_usable_rect(scr)
        if r.size.x <= 0 or r.size.y <= 0:
                r = Rect2i(Vector2i.ZERO, Vector2i(1280, 720))
        return r
