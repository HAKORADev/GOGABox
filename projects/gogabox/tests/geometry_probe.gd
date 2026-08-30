extends SceneTree
## GOGABox geometry probe (v0.1.2): boots the REAL main scene at the TWO
## universal FHD designs - portrait 1080x1920 and landscape 1920x1080 - and
## reports ANY visible Control poking outside the design viewport.
## Exit 0 = everything fits.
##
## v0.1.2 END-TO-END: the probe does NOT pin content_scale_size itself
## anymore - it sets the menu's orientation_override and lets the REAL
## decision code (menu._apply_base, the code that had the stuck-portrait
## landscape bug) apply the design. If landscape ever renders the portrait
## design again, the visible-rect check below fails LOUDLY.
## (The headless window is fake and never rotates - verified: headless
## window_set_size is a no-op - so the override is the honest test surface.)
##
## Run: godot --headless --path projects/gogabox -s res://tests/geometry_probe.gd

const CONFIGS := [
        {"name": "portrait design 1080x1920 (universal FHD)", "css": Vector2i(1080, 1920), "ov": "portrait"},
        {"name": "landscape design 1920x1080 (universal FHD)", "css": Vector2i(1920, 1080), "ov": "landscape"},
]

var cfg := 0
var phase := 0          # 0 = spawning, 1..11 settling, 12 = walk
var scene_root: Node
var offenders: Array = []

func _initialize() -> void:
        print("=== GOGABox geometry probe ===")
        root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
        process_frame.connect(_tick)
        _spawn()

func _spawn() -> void:
        print("--- config %s ---" % CONFIGS[cfg]["name"])
        if scene_root != null and is_instance_valid(scene_root):
                scene_root.free()
        var ps: PackedScene = load("res://main.tscn")
        scene_root = ps.instantiate()
        root.add_child(scene_root)     # main builds the menu (deferred on the
                                       # very first spawn - applied in _tick)
        phase = 1
        offenders = []

func _tick() -> void:
        # keep the stretch factor pinned (headless windows report fake sizes;
        # 1.0 is the design-space the device renders at). content_scale_size
        # is deliberately NOT touched - menu._apply_base owns it in v0.1.2.
        root.content_scale_factor = 1.0
        if phase == 1:
                phase = 2
                # drive the REAL decision code with the override once the
                # menu exists (its _ready may be deferred on the first spawn)
                var menu := scene_root.get_node_or_null("Menu")
                if menu != null:
                        menu.set("orientation_override", CONFIGS[cfg]["ov"])
                        menu.call("_apply_base")
                else:
                        print("  FAIL: Menu node not found in main.tscn instance")
        if phase < 12:
                phase += 1
                return
        var vp_size: Vector2 = root.get_visible_rect().size
        var want: Vector2i = CONFIGS[cfg]["css"]
        print("logical viewport: %.0f x %.0f" % [vp_size.x, vp_size.y])
        offenders = []
        # v0.1.2 THE REGRESSION CHECK: the menu itself must have applied the
        # design (this is exactly what failed stuck-portrait in v0.1.1)
        if Vector2i(int(vp_size.x), int(vp_size.y)) != want:
                offenders.append("design NOT applied by menu._apply_base: visible rect %s != %s" % [vp_size, want])
        _scan(scene_root, vp_size)
        if offenders.is_empty():
                print("  FIT: all controls inside the design viewport")
        else:
                print("  OUT OF BOUNDS (%d):" % offenders.size())
                for o in offenders:
                        print("    " + o)
        cfg += 1
        if cfg < CONFIGS.size():
                _spawn()
        else:
                quit(0 if offenders.is_empty() else 1)

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
