extends SceneTree
## GOGABox geometry probe (v0.1.1): boots the REAL main scene at the TWO
## universal designs - portrait 1080x2400 and landscape 2400x1080 - and
## reports ANY visible Control poking outside the design viewport.
## Exit 0 = everything fits.
##
## v0.1.1 THE UNIVERSAL RESOLUTION: stretch is canvas_items + aspect KEEP
## with a FIXED design per orientation, so the logical room IS the design on
## EVERY device - other window sizes only scale it up/down (letterboxed on
## odd aspects). There is no per-device density math left to probe; these
## two configs cover the whole matrix. The probe pins the stretch math
## directly (headless Windows report fake sizes) - the exact numbers the
## engine computes on real hardware.
##
## Run: godot --headless --path projects/gogabox -s res://tests/geometry_probe.gd

const CONFIGS := [
        {"name": "portrait 1080x2400 (universal design)", "css": Vector2i(1080, 2400)},
        {"name": "landscape 2400x1080 (universal design)", "css": Vector2i(2400, 1080)},
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
        root.add_child(scene_root)     # main builds the menu at the pinned design
        phase = 1
        offenders = []

func _tick() -> void:
        # re-pin the design EVERY frame (headless window is fake 720x1280;
        # with aspect KEEP the visible rect equals the design regardless)
        root.content_scale_size = CONFIGS[cfg]["css"]
        root.content_scale_factor = 1.0
        if phase < 12:
                phase += 1
                return
        var vp_size: Vector2 = root.get_visible_rect().size
        print("logical viewport: %.0f x %.0f" % [vp_size.x, vp_size.y])
        offenders = []
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
