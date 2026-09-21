extends Node
## v041-1 r3 THE WINDOW TRUTH PROBE - the owner's r2 video disease, pinned
## as a standing gate. RIG-REPRODUCED ROOT CAUSE: a raw
## DisplayServer.window_set_size leaves the root Window's internal size
## STALE (no WM resize event ever arrives on WM-less sessions / boot-time
## resizes / Windows restore races) - the stretch final-transform kept
## mapping the design onto the BOOT rect: the app rendered clipped into a
## corner ("the brown strip"), the ink filled the rest, and the cursor's
## inverse-transform could go singular (invisible pointer). The fix: THE
## WINDOW TRUTH LAW (ScaleRule.sync_window - OS truth re-seated through
## the Window property path, which always re-runs the engine's viewport
## sync) + THE SINGULARITY-PROOF CURSOR MAPPING
## (ScaleRule.final_transform_of - built from DisplayServer truth).
##
## X11 rig: real DisplayServer, no WM - the exact disease environment.
## Headless: the window laws are no-ops there - this probe skips.

var _fails := 0
var _checks := 0

func _ready() -> void:
        if DisplayServer.get_name() == "headless":
                print("SYNC_PROBE SKIP (headless - the window laws sleep)")
                get_tree().quit(0)
                return
        var main_scene: PackedScene = load("res://main.tscn")
        var app := main_scene.instantiate()
        app.name = "App"
        add_child(app)
        get_tree().create_timer(4.0).timeout.connect(_phase_a)

func _check(cond: bool, tag: String) -> void:
        _checks += 1
        if not cond:
                _fails += 1
                print("SYNC_PROBE FAIL: %s" % tag)

func _phase_a() -> void:
        var win := get_window()
        # --- 1. THE BOOT STATE IS HONEST (boot_window -> sync_window) ---
        var ds := DisplayServer.window_get_size()
        _check(win.size == ds,
                "boot: Window.size (%s) == DisplayServer truth (%s)" % [win.size, ds])
        _check(_transform_matches_truth(win), "boot: final transform matches OS truth")
        # --- 2. THE RAW DISEASE + THE WATCHDOG HEAL ---
        # the exact raw call that froze r2 (no WM event follows on the rig)
        DisplayServer.window_set_size(Vector2i(1256, 705))
        DisplayServer.window_set_position(Vector2i(40, 30))
        var healed: bool = ScaleRule.sync_window(win)
        _check(healed, "raw resize desynced Window.size and the watchdog healed it")
        _check(win.size == DisplayServer.window_get_size(),
                "heal: Window.size == OS truth after sync")
        await get_tree().process_frame
        await get_tree().process_frame
        _check(_transform_matches_truth(win),
                "heal: final transform matches OS truth after sync")
        # --- 3. THE GOVERNOR KEEPS IT HONEST (menu apply_pc every frame) ---
        DisplayServer.window_set_size(Vector2i(455, 810))
        # do NOT sync by hand - let the per-frame governor do the work
        var waited := 0.0
        while win.size != DisplayServer.window_get_size() and waited < 2.0:
                await get_tree().process_frame
                waited += get_process_delta_time()
        _check(win.size == DisplayServer.window_get_size(),
                "governor: desync self-healed within 2s (%.2fs)" % waited)
        await get_tree().process_frame
        await get_tree().process_frame
        _check(_transform_matches_truth(win), "governor: transform matches OS truth")
        # --- 4. THE CURSOR MAPPING IS SINGULARITY-PROOF ---
        var ft := ScaleRule.final_transform_of(win)
        _check(ft.determinant() > 0.0001, "cursor mapping: determinant > 0 (%f)" % ft.determinant())
        _check(is_finite(ft.origin.x) and is_finite(ft.origin.y),
                "cursor mapping: finite origin")
        var inv := ft.affine_inverse()
        var round_trip := ft * inv
        _check(absf(round_trip.get_scale().x - 1.0) < 0.001,
                "cursor mapping: inverse round-trips")
        # --- 5. THE MENU IS ALIVE INSIDE AN HONEST CANVAS ---
        var viewport_rect := win.get_viewport().get_visible_rect()
        _check(viewport_rect.size == Vector2(ScaleRule.DESIGN_PORTRAIT),
                "menu canvas: visible rect == design (%s)" % viewport_rect.size)
        # --- VERDICT ---
        print("SYNC_PROBE %d/%d checks passed" % [_checks - _fails, _checks])
        print("SYNC_PROBE %s" % ("ALL OK" if _fails == 0 else "FAILED"))
        get_tree().quit(0 if _fails == 0 else 1)

## The engine's healthy KEEP answer == the OS-truth math (within epsilon).
func _transform_matches_truth(win: Window) -> bool:
        var want := ScaleRule.final_transform_of(win)
        var got := win.get_final_transform()
        var ds := DisplayServer.window_get_size()
        if ds.x <= 0 or ds.y <= 0:
                return false
        var cs := win.content_scale_size
        var s := minf(float(ds.x) / float(cs.x), float(ds.y) / float(cs.y))
        var want_origin := (Vector2(ds) - Vector2(cs) * s) * 0.5
        return absf(got.get_scale().x - s) < 0.01 \
                        and absf(got.get_scale().y - s) < 0.01 \
                        and got.origin.distance_to(want_origin) < 1.0 \
                        and got.origin.distance_to(want.origin) < 1.0
