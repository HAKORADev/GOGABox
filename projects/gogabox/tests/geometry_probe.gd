extends SceneTree
## GOGABox geometry probe (v0.1.3): verifies THE RESOLUTION & SCALE RULE
## end-to-end - aspect EXPAND (no letterbox bars, ever), the two fixed
## designs, the REAL decision code, and rotation ping-pong stability.
## Exit 0 = everything fits.
##
## THREE LAYERS OF VERIFICATION:
## 1. THE ASPECT MATRIX (pure ScaleRule.want_for): every realistic phone /
##    tablet window px must decide the correct design. This is the owner's
##    "handle different phones aspect ratios" contract at the decision level.
## 2. END-TO-END: boots the REAL main scene and lets the REAL
##    menu._apply_base apply the design via orientation_override (the
##    headless fake window never rotates and DisplayServer reports (0,0),
##    so the override is the honest test surface - the real-px path is
##    want_for(), unit-tested in layer 1). Then asserts:
##      - root.content_scale_size == the design (the code applied it - the
##        exact thing that was stuck-portrait in v0.1.1 / v0.1.2),
##      - the visible rect equals the ENGINE EXPAND math (window / min
##        scale) - catches any regression back to aspect KEEP letterboxing,
##      - no visible Control pokes outside the visible canvas.
## 3. ROTATION PING-PONG: landscape -> portrait -> landscape -> portrait on
##    one live scene - the owner's third screenshot ("switched in app then
##    returned") must never re-appear.
##
## Run: godot --headless --path projects/gogabox -s res://tests/geometry_probe.gd

const DESIGN_P := Vector2i(1080, 1920)
const DESIGN_L := Vector2i(1920, 1080)

# [real window px, expected design] - phones, tablets, odd aspects
const MATRIX := [
        [Vector2i(1080, 1920), DESIGN_P],      # 16:9 phone portrait
        [Vector2i(1080, 2340), DESIGN_P],      # 19.5:9 phone portrait
        [Vector2i(1080, 2400), DESIGN_P],      # FHD+ 20:9 (the owner's panel)
        [Vector2i(1440, 3200), DESIGN_P],      # QHD+ 20:9 portrait
        [Vector2i(1170, 2532), DESIGN_P],      # iPhone-class portrait
        [Vector2i(1536, 2048), DESIGN_P],      # 4:3 tablet portrait
        [Vector2i(768, 1024), DESIGN_P],       # small tablet portrait
        [Vector2i(1920, 1080), DESIGN_L],      # 16:9 landscape
        [Vector2i(2400, 1080), DESIGN_L],      # FHD+ landscape (owner)
        [Vector2i(2340, 1080), DESIGN_L],      # 19.5:9 landscape
        [Vector2i(3200, 1440), DESIGN_L],      # QHD+ landscape
        [Vector2i(2048, 1536), DESIGN_L],      # 4:3 tablet landscape
        [Vector2i(2688, 1242), DESIGN_L],      # iPhone-class landscape
        [Vector2i(0, 0), DESIGN_P],            # degenerate -> portrait guard
        [Vector2i(-1, 500), DESIGN_P],         # garbage -> portrait guard
]

# each config = one live scene, driven through orientation steps in sequence
const CONFIGS := [
        {"name": "portrait boot (universal design)", "steps": ["portrait"]},
        {"name": "landscape boot (opened-as-horizontal regression)", "steps": ["landscape"]},
        {"name": "rotation ping-pong (switched-in-app regression)",
                "steps": ["landscape", "portrait", "landscape", "portrait"]},
]
const SETTLE := 6       # frames per step

var cfg := 0
var step := 0
var phase := 0          # 0 = spawning, 1..SETTLE settling, SETTLE+1 = checks
var scene_root: Node
var offenders: Array = []
var matrix_fail := 0
var any_fail := false   # sticky across configs - no failure is ever forgotten

func _initialize() -> void:
        print("=== GOGABox geometry probe (v0.1.3 resolution & scale rule) ===")
        # THE RULE UNDER TEST: aspect EXPAND - the canvas always covers the
        # window (this line IS the no-letterbox-bars guarantee in engine terms)
        root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
        _matrix()
        process_frame.connect(_tick)
        _spawn()

func _matrix() -> void:
        print("--- layer 1: ScaleRule.want_for aspect matrix (%d windows) ---"
                        % MATRIX.size())
        for m in MATRIX:
                var got: Vector2i = _want_for_external(m[0])
                if got != m[1]:
                        matrix_fail += 1
                        print("  FAIL: window %s -> %s (want %s)"
                                        % [m[0], got, m[1]])
        print("  %s: %d/%d decisions correct" % [
                "PASS" if matrix_fail == 0 else "FAIL",
                MATRIX.size() - matrix_fail, MATRIX.size()])

# call through a script instance so the probe tests the SHIPPED code, not a
# copy of it (no class_name load-order surprises in -s SceneTree mode)
func _want_for_external(ws: Vector2i) -> Vector2i:
        var s: GDScript = load("res://game/core/scale_rule.gd")
        return s.want_for(ws)

func _spawn() -> void:
        print("--- config %d: %s ---" % [cfg + 1, CONFIGS[cfg]["name"]])
        if scene_root != null and is_instance_valid(scene_root):
                scene_root.free()
        var ps: PackedScene = load("res://main.tscn")
        scene_root = ps.instantiate()
        root.add_child(scene_root)     # main builds the menu
        # v0.1.3: main._process is the per-frame governor - on DEVICE it is
        # the safety net, but the headless fake window never rotates and
        # would fight the override this probe drives. Kill exactly the
        # governor; the rest of main (splash etc.) keeps processing.
        scene_root.set_process(false)
        step = 0
        phase = 1
        offenders = []

func _drive(ov: String) -> void:
        # drive the REAL decision code with the override
        var menu := scene_root.get_node_or_null("Menu")
        if menu == null:
                print("  FAIL: Menu node not found in main.tscn instance")
                quit(1)
                return
        menu.set("orientation_override", ov)
        menu.call("_apply_base")

func _check_step() -> bool:
        var all_ok := true
        var ov: String = CONFIGS[cfg]["steps"][step]
        var want: Vector2i = DESIGN_L if ov == "landscape" else DESIGN_P
        var got: Vector2i = root.content_scale_size
        # 1. the REAL code applied the design
        if got != want:
                any_fail = true
                offenders.append("design NOT applied by menu._apply_base: %s != %s"
                                % [got, want])
        # 2. the engine honors aspect EXPAND: visible rect = window / scale,
        #    scale = min(win/design) - NEVER a letterboxed design-with-bars
        var win_sz: Vector2 = Vector2(root.size)
        var scale := minf(win_sz.x / float(want.x), win_sz.y / float(want.y))
        var expected_vp := win_sz / scale
        var vp_size: Vector2 = root.get_visible_rect().size
        print("  step '%s': design %s, visible canvas %.0f x %.0f (expand math %.0f x %.0f)"
                        % [ov, got, vp_size.x, vp_size.y, expected_vp.x, expected_vp.y])
        if (vp_size - expected_vp).length() > 2.0:
                any_fail = true
                offenders.append("visible rect %s != EXPAND math %s (aspect must stay EXPAND)"
                                % [vp_size, expected_vp])
        # 3. everything visible fits inside the canvas
        _scan(scene_root, vp_size)
        if offenders.is_empty():
                print("    FIT: all controls inside the visible canvas")
        else:
                any_fail = true
                print("    OUT OF BOUNDS (%d):" % offenders.size())
                for o in offenders:
                        print("      " + o)
        return all_ok

func _tick() -> void:
        # keep the stretch factor pinned (headless windows report fake sizes;
        # 1.0 is the design-space the device renders at)
        root.content_scale_factor = 1.0
        if phase == 1:
                phase = 2
                _drive(CONFIGS[cfg]["steps"][step])
                return
        if phase <= SETTLE:
                phase += 1
                return
        if phase == SETTLE + 1:
                phase = SETTLE + 2
                _check_step()
                # next step (ping-pong) or next config
                step += 1
                if step < CONFIGS[cfg]["steps"].size():
                        phase = 1
                        return
                cfg += 1
                if cfg < CONFIGS.size():
                        _spawn()
                else:
                        print("=== probe %s ===" % ("PASS" if matrix_fail == 0 and not any_fail else "FAIL"))
                        quit(0 if matrix_fail == 0 and not any_fail else 1)

func _scan(n: Node, vp_size: Vector2) -> void:
        if n is Control:
                var c := n as Control
                if c.is_visible_in_tree() and c.size.x > 1.0 and c.size.y > 1.0:
                        var r := c.get_global_rect()
                        if r.end.x > vp_size.x + 2.0 or r.end.y > vp_size.y + 2.0 \
                                        or r.position.x < -2.0 or r.position.y < -2.0:
                                offenders.append("%s <%s> rect=%s" % [
                                        c.get_path(), c.get_class(), r])
        for ch in n.get_children():
                _scan(ch, vp_size)
