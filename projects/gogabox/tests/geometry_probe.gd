extends SceneTree
## GOGABox geometry probe (v0.1.0): boots the REAL main scene at the logical
## viewports produced by main.gd's density rule and reports ANY visible
## Control poking outside the viewport. Exit 0 = everything fits.
##
## Headless Windows report fake sizes, so the probe pins the stretch math
## directly (aspect KEEP + explicit css/factor) - the exact same numbers the
## engine computes on real hardware:
##   config A: f=1.000  ->  720 x 1280  (720p-class phones, v0.0.9 geometry)
##   config B: f=0.667  -> 1080 x 1920  (owner's 1080-wide phone class;
##              on the real 9:20 device expand grows the room to 1080x2400 -
##              more height only adds scroll room, width is the binding axis)
##   config C: f=0.625  -> 1152 x 2048  (the density-rule cap)
##
## Run: godot --headless --path projects/gogabox -s res://tests/geometry_probe.gd

const CONFIGS := [
        {"name": "A 840x1493 (f=0.857, small-screen floor)", "f": 720.0 / 840.0},
        {"name": "B 1080x1920 (f=0.667, 1080-phone)", "f": 720.0 / 1080.0},
        {"name": "C 1152x2048 (f=0.625, cap)", "f": 720.0 / 1152.0},
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
        root.add_child(scene_root)     # main._ready applies its own f (headless -> 1.0)
        phase = 1
        offenders = []

func _tick() -> void:
        # re-pin the density AFTER main._ready and on every frame (menu's
        # _apply_base writes css back to 720x1280 - same value we want)
        root.content_scale_size = Vector2i(720, 1280)
        root.content_scale_factor = CONFIGS[cfg]["f"]
        if phase < 12:
                phase += 1
                return
        var vp_size: Vector2 = root.get_visible_rect().size
        print("logical viewport: %.0f x %.0f" % [vp_size.x, vp_size.y])
        offenders = []
        _scan(scene_root, vp_size)
        if offenders.is_empty():
                print("  FIT: all controls inside the viewport")
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
