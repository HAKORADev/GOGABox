class_name Coin3D
extends Node3D
## THE 3D GOGACOIN (v041-2) - the coin.png of the 3D games.
## Every 2D game paints res://assets/ui/coin.png (the snake law); every 3D
## game seats THIS instead: a real gold coin - body, rim, the inner light
## ring and the blocky GOGA "G" on the face - with the pickup laws the 2D
## painters already ride: the fade-in scale ramp (~0.35s), the breathing
## pop, the warm halo, the spin. THE SCALE LAW: the caller states the
## on-screen size in DESIGN px and the play depth; world_diameter() turns
## that into the exact world-space size so the coin reads the same size
## the 2D coin reads (the 2D coin rides at ~64 design px in the games).

signal collect_finished

const GOLD := Color(0.95, 0.76, 0.22)
const GOLD_DEEP := Color(0.72, 0.5, 0.1)
const GOLD_FACE := Color(1.0, 0.86, 0.4)
const GOLD_G := Color(0.62, 0.42, 0.08)

var radius := 1.0            # world units, set via set_diameter()
var _body: Node3D
var _halo: MeshInstance3D
var _spin := true
var _spin_speed := 2.6       # rad/s
var _breath_t := 0.0
var _born := false
var _collected := false

func _ready() -> void:
        _body = Node3D.new()
        add_child(_body)
        _build()
        _birth()

## THE SCALE LAW: how big must the mesh be so its projected diameter
## reads `design_px` at `distance` world units from the camera? A
## perspective camera scales the world by the viewport height: the world
## height visible at `distance` is 2 * distance * tan(fov/2), so one
## design px (of the viewport's design height) equals that height divided
## by the viewport's design height.
static func world_diameter(design_px: float, cam: Camera3D,
                distance: float) -> float:
        var vp := cam.get_viewport().get_visible_rect().size
        if vp.y <= 0.0:
                return design_px * 0.01
        var fov: float = cam.fov
        var world_h := 2.0 * distance * tan(deg_to_rad(fov) * 0.5)
        return design_px * world_h / vp.y

func set_diameter(d: float) -> void:
        radius = maxf(0.01, d * 0.5)
        if _body != null:
                _build()

func _build() -> void:
        for c in _body.get_children():
                c.queue_free()
        var gold := StandardMaterial3D.new()
        gold.albedo_color = GOLD
        gold.metallic = 0.75
        gold.roughness = 0.32
        var deep := StandardMaterial3D.new()
        deep.albedo_color = GOLD_DEEP
        deep.metallic = 0.7
        deep.roughness = 0.38
        var face := StandardMaterial3D.new()
        face.albedo_color = GOLD_FACE
        face.metallic = 0.55
        face.roughness = 0.42
        var gmat := StandardMaterial3D.new()
        gmat.albedo_color = GOLD_G
        gmat.metallic = 0.4
        gmat.roughness = 0.5
        # the body: a squat cylinder (the rim reads through the side band)
        var body := MeshInstance3D.new()
        var cyl := CylinderMesh.new()
        cyl.top_radius = radius
        cyl.bottom_radius = radius
        cyl.height = radius * 0.22
        cyl.radial_segments = 40
        body.mesh = cyl
        body.rotation_degrees = Vector3(90, 0, 0)   # face along Z
        body.material_override = gold
        _body.add_child(body)
        # the rim: a slightly larger, thinner disc behind + in front
        for side in [-1.0, 1.0]:
                var rim := MeshInstance3D.new()
                var rc := CylinderMesh.new()
                rc.top_radius = radius * 1.06
                rc.bottom_radius = radius * 1.06
                rc.height = radius * 0.06
                rc.radial_segments = 40
                rim.mesh = rc
                rim.rotation_degrees = Vector3(90, 0, 0)
                rim.position.z = side * radius * 0.1
                rim.material_override = deep
                _body.add_child(rim)
        # the inner light ring (the coin.png's bright circle)
        var ring := MeshInstance3D.new()
        var tm := TorusMesh.new()
        tm.inner_radius = radius * 0.8
        tm.outer_radius = radius * 0.88
        tm.rings = 40
        ring.mesh = tm
        ring.material_override = face
        ring.position.z = radius * 0.12
        _body.add_child(ring)
        # THE GOGA G - the blocky glyph, five boxes on the face
        var g := Node3D.new()
        g.position.z = radius * 0.13
        var bars := [
                # [cx, cy, w, h] in fractions of the face radius
                [-0.08, 0.52, 0.9, 0.22],   # top bar
                [-0.5, 0.05, 0.22, 0.98],   # left vertical
                [-0.08, -0.42, 0.9, 0.2],   # bottom bar
                [0.34, -0.16, 0.22, 0.62],  # right vertical (lower half)
                [0.12, 0.02, 0.46, 0.2],    # the middle bar
        ]
        for b in bars:
                var bar := MeshInstance3D.new()
                var bm := BoxMesh.new()
                bm.size = Vector3(float(b[2]) * radius, float(b[3]) * radius,
                                radius * 0.06)
                bar.mesh = bm
                bar.position = Vector3(float(b[0]) * radius,
                                float(b[1]) * radius, 0.0)
                bar.material_override = gmat
                g.add_child(bar)
        _body.add_child(g)
        # the warm halo: a billboard quad, additive, behind the coin
        _halo = MeshInstance3D.new()
        var hq := QuadMesh.new()
        hq.size = Vector2(radius * 3.4, radius * 3.4)
        _halo.mesh = hq
        var hm := StandardMaterial3D.new()
        hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
        hm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
        hm.albedo_color = Color(1.0, 0.85, 0.35, 0.28)
        hm.no_depth_test = false
        _halo.material_override = hm
        _halo.position.z = -radius * 0.05
        _body.add_child(_halo)

## Node3D carries no opacity - the fade rides every GeometryInstance3D
## child (the body, rims, ring, glyph, halo).
func _set_trans(t: float) -> void:
        for c in _body.get_children():
                if c is GeometryInstance3D:
                        (c as GeometryInstance3D).transparency = t

## THE PICKUP LAWS (the 2D painters' ramp): born small, bloom to size in
## ~0.35s, then breathe.
func _birth() -> void:
        _body.scale = Vector3.ONE * 0.12
        _set_trans(1.0)
        var tw := create_tween()
        tw.tween_property(_body, "scale", Vector3.ONE, 0.35) \
                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tw.parallel().tween_method(_set_trans, 1.0, 0.0, 0.35)
        tw.tween_callback(func(): _born = true)

func _process(delta: float) -> void:
        if _collected:
                return
        if _spin:
                _body.rotation.y += _spin_speed * delta
        _breath_t += delta
        if _born:
                _body.scale = Vector3.ONE * (1.0 + 0.05 * sin(_breath_t * 3.4))

## THE COLLECT: pop + fly up + fade (the 2D pickup's exit, in 3D)
func collect() -> void:
        if _collected:
                return
        _collected = true
        var tw := create_tween()
        tw.set_parallel(true)
        tw.tween_property(_body, "position:y", _body.position.y + radius * 3.0,
                        0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        tw.tween_property(_body, "scale", Vector3.ONE * 1.35, 0.18)
        tw.chain().tween_method(_set_trans, 0.0, 1.0, 0.16)
        tw.chain().tween_callback(func():
                collect_finished.emit()
                queue_free())

func set_spin(on: bool) -> void:
        _spin = on
