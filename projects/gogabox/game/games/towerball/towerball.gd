extends GogaGame3D
## TOWER BALL (v041-2 r2) - the box's first 3D game. ONE tower law, TWO modes:
##   BALL     the Stack Ball smash (the owner's source: Stack Bounce, the
##            PlayCanvas decompile): the tower spins, hold to dive, shatter
##            the disc under you, never touch black (fire forgives), reach
##            the victory disc through the 150..900 ladder. THE FIRE is the
##            EXACT original boost: +0.03 a break, a 1.6s slow-mo charge at
##            full, a 0.6/s burn, a 0.15/s idle decay, a -0.5 floor cooldown.
##   PLATFORM the REAL Neon Tower (the owner's source, the famobi decompile):
##            the ball ORBITS the pole at a fixed radius and bounces on its
##            own; YOU ROTATE THE TOWER (swipe / arrows / gamepad) to steer
##            the gaps under it. Falls build the combo (their combo law:
##            score = combo+1, threshold 4 charges the SMASH-THROUGH); red
##            sectors and walls kill; rotating into a wall's side kills.
## r2 owner verdicts honored: NO lives (one crash = the run over), the empty
## widget is dead (the FIRE GAUGE lives left of the score, circular like the
## original), the ball EXISTS from the first frame (it bounces through the
## intro + the optionals as the living scenery), skins are DESIGNS (glass /
## rock / wood / water + ice / metal / rubber / gold - own materials, own
## break VFX, own SFX; black always black), the world LIVES (the sky follows
## the device's local day time: morning / noon / evening / night, sun and
## moon, drifting clouds, stars), gamepad (X + left/right), no lore -
## the character is BALLDOZER and the game is geometrics.
## The 3D seat: world units = 10 design px; one DirectionalLight3D with soft
## shadows; the tower draws ~1 mesh per alive row (vertex colored ArrayMesh).

const TB := preload("res://game/games/towerball/towerball_data.gd")
const Coin3DL := preload("res://game/core/game_coin3d.gd")

# ------------------------------------------------- ball mode geometry (1u = 10px)
const R_OUT := 15.0            # disc outer radius
const R_IN := 2.0              # disc inner radius (the pole hole)
const THICK := 1.6             # disc thickness
const PITCH := 4.6             # row pitch (46 design px)
const POLE_R := 1.2
const BALL_R := 3.0
const BOUNCE_V := 42.0
const GRAV := -150.0
const SMASH_V := -46.0
const FIRE_SMASH_MULT := 1.35
const MAX_FALL := -60.0
const WINDOW := 26             # alive discs ahead of the top
const BALL_Z := 8.0            # THE BALL'S FRONT SEAT: the ball bounces on
                               # the disc's front area (world angle 0, the
                               # camera's side) - NOT the center axis where
                               # the pole hid it (the owner: "the ball is
                               # not even a ball, not even exist")
const CAM_FOV := 46.0
const CAM_TILT := 35.0         # degrees above the horizon

# ------------------------------------------------- platform mode geometry
# THE NEON TOWER SCALE (the decompiled config, verbatim ratios)
const PBALL_R := TB.NT_BALL_R               # 0.8
const P_OFFSET := TB.NT_BALL_OFFSET         # 4.55 - the ball's orbit radius
const P_RING_R := TB.NT_RING_R              # 6.3
const P_RING_H := TB.NT_RING_H              # 1.2
const P_PITCH := TB.NT_INTER_RING           # 8.7 - the ring spacing
const P_POLE_R := TB.NT_POLE_R              # 2.8
const P_GRAV := TB.NT_GRAVITY               # -60
const P_DRAG := TB.NT_DRAG                  # 0.02 quadratic
const P_BOUNCE := TB.NT_BOUNCE_V            # 23
const P_APEX := TB.NT_APEX                  # 6
const P_WALL_DEG := TB.NT_WALL_DEG
const P_CAM_D := 15.5
const P_CAM_FOV := 46.0
const P_WINDOW := 22            # alive rings ahead of the ball
const COMBO_THRESHOLD := TB.NT_COMBO_THRESHOLD

# ------------------------------------------------- state
var mode := "ball"             # "ball" | "platform"
var phase := "boot"            # boot|intro|optionals|transition|run|serve|won|over
var round_idx := 1
var round_len := 150
var rng := RandomNumberGenerator.new()

# world
var world: Node3D
var cam: Camera3D
var sun: DirectionalLight3D
var sun_mesh: MeshInstance3D
var moon_mesh: MeshInstance3D
var env: WorldEnvironment
var pole: MeshInstance3D
var ball_mesh: MeshInstance3D
var ball_face: Node3D
var fire_p: CPUParticles3D
var trail_p: CPUParticles3D
var ball_mat: StandardMaterial3D
var frag_layer: Node3D
var sky_layer: Node3D          # clouds + stars
var _clouds: Array = []
var _stars: Node3D

# ball mode live
var top_row := 0
var discs := {}                # row -> disc state
var rows_data := []            # per-row data (pregenerated at round build)
var by := 0.0                  # ball y
var bvy := 0.0
var holding := false
var key_hold := false
var pad_hold := false
var cam_y := 0.0
var shake_t := 0.0
var victory_y := 0.0

# THE BOOST (the exact Stack Bounce law)
var boost_v := TB.BOOST_START
var boost_charge_t := 0.0      # the 1.6s slow-mo charge countdown
var boosting := false
var streak := 0.0              # the ORIGINAL is a float streak (pitch + score)
var stun_t := 0.0              # the crash grace: no smash while it runs

# coin
var coin_row_idx := -1
var coin_seg := -1
var coin_node: Coin3D = null
var coin_ring_idx := -1

# platform mode live
var rings := {}                 # row -> ring state {data, node, rot}
var p_top := 0                  # the next ring the ball can meet
var p_y := 0.0                 # ball y
var p_vy := 0.0
var p_combo := 0               # consecutive falls (the charge)
var p_pending := 0             # banked falls, applied on the next solid land
var p_cam_y := 0.0
var p_started := false
var ball_base_scale := 1.0     # the same Balldozer mesh, per-mode size
var keys := {}                 # held arrows / the pad's left-right

# hud
var gauge: Control             # THE FIRE GAUGE (the circular widget)
var banner: Label

# fragments (shared pool)
var _frags: Array = []
var _frag_cache := {}
var _waves: Array = []         # the break shockwaves

# ----------------------------------------------------------------- setup

func _goga_setup() -> void:
        rng.randomize()
        pause_end_run = true     # THE END LAW: the pause sheet banks the run
        gauge = _build_gauge()
        add_hud_widget(gauge)
        add_hud_button("SHOP", func(): _shop_open())
        _goga_tk_ready()
        mode = String(Box.get_progress(game_id, "mode", "ball"))
        if mode != "ball" and mode != "platform":
                mode = "ball"
        _build_world()
        _build_round()           # the tower IS the intro scenery
        Jukebox.music("res://assets/audio/music/tb_theme.wav")
        # r2 THE OPTIONALS LAW: the mode + position cards are the game's own
        # menu and ALWAYS show first - the run starts from PLAY. (r1 skipped
        # them on the reload path and the one-tap disease skipped them on the
        # fresh path; the owner saw neither. Both are dead.)
        _build_intro()
        tap_anywhere_start(_intro_start, "")
        check_achievements()

func _goga_tk_ready() -> void:
        if tk == null:
                return
        tk.press_started.connect(_on_press)
        tk.press_ended.connect(_on_release)

func _goga_pause_end_ok() -> bool:
        return phase == "run" or phase == "serve"

# --------------------------------------------------------- the fire gauge
## THE CIRCULAR WIDGET (the owner: "make it show the charge and heat of the
## fireball and the consumption time of it in a circular design like the
## original game"). One ring, three truths:
##   charging (boost_v 0..1): the amber arc grows clockwise; at full it
##            flashes into the charge-up white.
##   burning (boosting):     the ring burns fire-orange and DRAINS - the
##            remaining arc IS the remaining active time.
##   cooling (boost_v < 0):  a dim slate arc refills from the floor - the
##            cooldown before the charge can build again.

func _build_gauge() -> Control:
        var c := Control.new()
        c.custom_minimum_size = Vector2(78, 64)
        c.mouse_filter = Control.MOUSE_FILTER_IGNORE
        c.draw.connect(func(): _paint_gauge(c))
        return c

func _paint_gauge(c: Control) -> void:
        var mid := Vector2(39, 34)
        var r_out := 24.0
        var r_in := 16.0
        # the seat ring (the widget's body)
        _gauge_arc(c, mid, r_out + 3.0, 0.0, TAU,
                        Color(0.16, 0.10, 0.05, 0.55))
        var v := boost_v
        if boosting:
                # THE BURN: the arc IS the remaining active time
                var frac: float = clampf(v, 0.0, 1.0)
                var col := Color(1.0, 0.42, 0.08) if frac > 0.35 \
                                else Color(1.0, 0.24, 0.05)
                _gauge_arc(c, mid, r_out, -PI / 2.0,
                                -PI / 2.0 + TAU * frac, col)
                _gauge_arc(c, mid, r_in, -PI / 2.0,
                                -PI / 2.0 + TAU * frac,
                                Color(1.0, 0.85, 0.3, 0.85))
                c.draw_circle(mid, (r_in + r_out) * 0.5 - 1.0,
                                Color(0.32, 0.08, 0.02, 0.75))
                _gauge_flame(c, mid, 1.0)
        elif boost_charge_t > 0.0:
                # THE CHARGE-UP: the white flash ring fills over 1.6s
                var frac: float = 1.0 - boost_charge_t / TB.BOOST_CHARGE_TIME
                _gauge_arc(c, mid, r_out, -PI / 2.0,
                                -PI / 2.0 + TAU * frac, Color(1, 1, 1, 0.95))
                c.draw_circle(mid, (r_in + r_out) * 0.5 - 1.0,
                                Color(1.0, 0.55, 0.1, 0.5))
                _gauge_flame(c, mid, frac)
        elif v >= TB.BOOST_SHOW:
                # THE CHARGE: amber fills 0..1 (the heat grows with it)
                var frac: float = clampf(v, 0.0, 1.0)
                var col := Color(1.0, 0.55 - 0.25 * frac, 0.1 + 0.1 * frac)
                _gauge_arc(c, mid, r_out, -PI / 2.0,
                                -PI / 2.0 + TAU * frac, col)
                c.draw_circle(mid, (r_in + r_out) * 0.5 - 1.0,
                                Color(0.16, 0.10, 0.05, 0.72))
                _gauge_flame(c, mid, frac * 0.8)
        elif v < 0.0:
                # THE COOLDOWN: dim slate refills from the floor
                var frac: float = clampf((v - TB.BOOST_FLOOR)
                                / (0.0 - TB.BOOST_FLOOR), 0.0, 1.0)
                _gauge_arc(c, mid, r_out, -PI / 2.0,
                                -PI / 2.0 + TAU * frac,
                                Color(0.55, 0.58, 0.62, 0.5))
                c.draw_circle(mid, (r_in + r_out) * 0.5 - 1.0,
                                Color(0.16, 0.10, 0.05, 0.6))
        else:
                c.draw_circle(mid, (r_in + r_out) * 0.5 - 1.0,
                                Color(0.16, 0.10, 0.05, 0.45))
                _gauge_flame(c, mid, 0.25)

## one filled arc (a pie from the center - the classic gauge read)
func _gauge_arc(c: Control, mid: Vector2, radius: float, a0: float,
                a1: float, col: Color) -> void:
        if a1 <= a0:
                return
        var pts := PackedVector2Array()
        pts.append(mid)
        var steps := maxi(4, int(absf(a1 - a0) / 0.14))
        for i in steps + 1:
                var a: float = lerpf(a0, a1, float(i) / float(steps))
                pts.append(mid + Vector2(cos(a), sin(a)) * radius)
        c.draw_colored_polygon(pts, col)

## the little flame glyph in the gauge's eye (code-drawn: no icon asset)
func _gauge_flame(c: Control, mid: Vector2, heat: float) -> void:
        var col := Color(1.0, 0.62 + 0.3 * heat, 0.18, 0.55 + 0.4 * heat)
        var s := 8.0 + 3.0 * heat
        var pts := PackedVector2Array([
                mid + Vector2(0, -s * 1.5),
                mid + Vector2(s * 0.8, -s * 0.2),
                mid + Vector2(s * 0.5, s),
                mid + Vector2(-s * 0.5, s),
                mid + Vector2(-s * 0.8, -s * 0.2),
        ])
        c.draw_colored_polygon(pts, col)
        c.draw_circle(mid + Vector2(0, s * 0.35), s * 0.32,
                        Color(1.0, 0.95, 0.7, 0.5 + 0.4 * heat))

# ----------------------------------------------------------------- world

func _build_world() -> void:
        world = Node3D.new()
        add_child(world)
        var skin := TB.break_skin()
        cam = Camera3D.new()
        cam.fov = CAM_FOV
        world.add_child(cam)
        cam.current = true
        env = WorldEnvironment.new()
        var e := Environment.new()
        e.background_mode = Environment.BG_SKY
        var sky := Sky.new()
        var sm := ProceduralSkyMaterial.new()
        sky.sky_material = sm
        e.sky = sky
        e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
        e.ambient_light_sky_contribution = 0.7
        e.ambient_light_energy = 1.15
        e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
        env.environment = e
        world.add_child(env)
        sun = DirectionalLight3D.new()
        # THE CAMERA-SIDE LIGHT: pitch -55, azimuth -28 -> the light travels
        # AWAY from the camera (it shines from the camera's front-left-top):
        # the ball's face, the discs' tops and the tower's front all read warm
        sun.rotation_degrees = Vector3(-55, -28, 0)
        sun.light_energy = 1.3
        sun.light_color = Color(1.0, 0.96, 0.88)
        sun.shadow_enabled = true
        sun.directional_shadow_max_distance = 220.0
        sun.shadow_blur = 1.4
        world.add_child(sun)
        # THE LIVING WORLD SEAT: the sun disc, the moon, the stars, the clouds
        sun_mesh = MeshInstance3D.new()
        var smesh := SphereMesh.new()
        smesh.radius = 6.0
        smesh.height = 12.0
        sun_mesh.mesh = smesh
        var smat := StandardMaterial3D.new()
        smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        smat.albedo_color = Color(1.0, 0.93, 0.72)
        smat.emission_enabled = true
        smat.emission = Color(1.0, 0.9, 0.6)
        smat.emission_energy_multiplier = 2.2
        sun_mesh.material_override = smat
        world.add_child(sun_mesh)
        moon_mesh = MeshInstance3D.new()
        var mmesh := SphereMesh.new()
        mmesh.radius = 4.4
        mmesh.height = 8.8
        moon_mesh.mesh = mmesh
        var mmat := StandardMaterial3D.new()
        mmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        mmat.albedo_color = Color(0.92, 0.94, 1.0)
        mmat.emission_enabled = true
        mmat.emission = Color(0.8, 0.85, 1.0)
        mmat.emission_energy_multiplier = 1.1
        moon_mesh.material_override = mmat
        world.add_child(moon_mesh)
        sky_layer = Node3D.new()
        world.add_child(sky_layer)
        _stars = Node3D.new()
        sky_layer.add_child(_stars)
        for i in 90:
                var st := MeshInstance3D.new()
                var q := SphereMesh.new()
                q.radius = 0.22 + rng.randf() * 0.3
                q.height = q.radius * 2.0
                st.mesh = q
                var stm := StandardMaterial3D.new()
                stm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
                stm.albedo_color = Color(1, 1, 1)
                stm.emission_enabled = true
                stm.emission = Color(1, 1, 1)
                stm.emission_energy_multiplier = 1.6
                st.material_override = stm
                var ang := rng.randf_range(0.0, TAU)
                var el := rng.randf_range(0.05, 1.2)
                var dd := 240.0
                st.position = Vector3(cos(ang) * dd * cos(el),
                                sin(el) * dd, sin(ang) * dd * cos(el))
                _stars.add_child(st)
        for i in 7:
                var cl := MeshInstance3D.new()
                var cq := QuadMesh.new()
                cq.size = Vector2(70 + rng.randf() * 60.0,
                                26 + rng.randf() * 16.0)
                cl.mesh = cq
                var cm := StandardMaterial3D.new()
                cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
                cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
                cm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
                cm.albedo_color = Color(1, 1, 1, 0.5)
                cm.albedo_texture = _cloud_tex()
                cm.no_depth_test = false
                cl.material_override = cm
                cl.position = Vector3(rng.randf_range(-160, 160),
                                rng.randf_range(30, 130),
                                rng.randf_range(-140, -60))
                sky_layer.add_child(cl)
                _clouds.append({"n": cl, "spd": rng.randf_range(1.2, 3.0),
                                "base_a": 0.35 + rng.randf() * 0.25})
        frag_layer = Node3D.new()
        world.add_child(frag_layer)
        _build_ball()
        _apply_day_phase()
        _apply_sky(skin)

## one soft radial-gradient cloud texture, code-built once
var _cloud_tex_cache: GradientTexture2D = null

func _cloud_tex() -> Texture2D:
        if _cloud_tex_cache != null:
                return _cloud_tex_cache
        var g := Gradient.new()
        g.set_color(0, Color(1, 1, 1, 0.0))
        g.set_color(1, Color(1, 1, 1, 0.9))
        g.add_point(0.45, Color(1, 1, 1, 0.85))
        var t := GradientTexture2D.new()
        t.gradient = g
        t.fill = GradientTexture2D.FILL_RADIAL
        t.fill_from = Vector2(0.5, 0.5)
        t.fill_to = Vector2(0.5, 0.0)
        t.width = 128
        t.height = 64
        _cloud_tex_cache = t
        return t

## THE DAY PHASE LAW: the sky follows the DEVICE's local time - morning /
## noon / evening / night, each with its own light, its own sky, its own
## stars (night), its own sun/moon seat.
func _apply_day_phase() -> void:
        var t := Time.get_time_dict_from_system()
        var hour := float(t["hour"]) + float(t["minute"]) / 60.0
        var top: Color
        var hor: Color
        var sun_col: Color
        var energy := 1.15
        var amb := 1.0
        var stars_a := 0.0
        var night := false
        if hour >= 5.0 and hour < 8.0:          # MORNING
                top = Color("7fb8e8")
                hor = Color("ffd9a0")
                sun_col = Color(1.0, 0.86, 0.66)
                energy = 1.0
                amb = 0.95
        elif hour >= 8.0 and hour < 16.5:       # DAY
                top = Color("4f9fe8")
                hor = Color("cfeaff")
                sun_col = Color(1.0, 0.97, 0.9)
        elif hour >= 16.5 and hour < 20.0:      # EVENING
                top = Color("3d5a9e")
                hor = Color("ffb37a")
                sun_col = Color(1.0, 0.72, 0.45)
                energy = 1.1
                amb = 1.0
        else:                                    # NIGHT
                top = Color("0a1230")
                hor = Color("1c2a52")
                sun_col = Color(0.55, 0.62, 0.9)
                energy = 0.7
                amb = 0.8
                stars_a = 1.0
                night = true
        var sm: ProceduralSkyMaterial = (env.environment.sky.sky_material
                        as ProceduralSkyMaterial)
        sm.sky_top_color = top
        sm.sky_horizon_color = hor
        sm.ground_bottom_color = hor
        sm.ground_horizon_color = hor
        sun.light_color = sun_col
        sun.light_energy = energy
        env.environment.ambient_light_energy = amb
        # the sun/moon seats: the light's direction, pushed far out
        var sd := -sun.global_transform.basis.z
        sun_mesh.position = sd * 200.0
        sun_mesh.visible = not night
        moon_mesh.position = -sd * 200.0 + Vector3(0, 40, 0)
        moon_mesh.visible = night
        for st in _stars.get_children():
                (st as MeshInstance3D).material_override.emission_energy_multiplier \
                                = 1.6 * stars_a
                st.visible = stars_a > 0.05
        for cld in _clouds:
                var m: StandardMaterial3D = cld["n"].material_override
                m.albedo_color = Color(1, 1, 1, cld["base_a"]
                                * (0.25 if night else 1.0))

## the thumbnail's pose: the GOLDEN HOUR forced (the living world's best
## light for the capture rig)
func _force_golden_hour() -> void:
        var sm: ProceduralSkyMaterial = (env.environment.sky.sky_material
                        as ProceduralSkyMaterial)
        sm.sky_top_color = Color("4f86c8")
        sm.sky_horizon_color = Color("ffcf94")
        sm.ground_bottom_color = Color("ffcf94")
        sm.ground_horizon_color = Color("ffcf94")
        sun.light_color = Color(1.0, 0.84, 0.62)
        sun.light_energy = 1.45
        env.environment.ambient_light_energy = 1.1
        var sd := -sun.global_transform.basis.z
        sun_mesh.position = sd * 200.0
        sun_mesh.visible = true

func _apply_sky(skin: Dictionary) -> void:
        # the skin keeps its say on the sky ONLY as a gentle tint of the
        # horizon - the day phase owns the light (the one-theme law with
        # the living world on top)
        pass

## BALLDOZER: the sphere + the eyes (every world, no mouth)
func _build_ball() -> void:
        ball_mesh = MeshInstance3D.new()
        var sph := SphereMesh.new()
        sph.radius = BALL_R
        sph.height = BALL_R * 2.0
        sph.radial_segments = 32
        sph.rings = 16
        ball_mesh.mesh = sph
        ball_mat = StandardMaterial3D.new()
        ball_mat.albedo_color = TB.ball_skin()["color"]
        ball_mat.roughness = TB.ball_skin()["rough"]
        ball_mat.metallic = TB.ball_skin()["metal"]
        if float(TB.ball_skin()["alpha"]) < 1.0:
                ball_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
                ball_mat.albedo_color.a = TB.ball_skin()["alpha"]
        ball_mesh.material_override = ball_mat
        world.add_child(ball_mesh)
        ball_face = Node3D.new()
        ball_mesh.add_child(ball_face)
        var eye_mat := StandardMaterial3D.new()
        eye_mat.albedo_color = Color(0.14, 0.1, 0.09)
        eye_mat.roughness = 0.3
        for sx in [-1.0, 1.0]:
                var eye := MeshInstance3D.new()
                var es := SphereMesh.new()
                es.radius = BALL_R * 0.19
                es.height = BALL_R * 0.38
                eye.mesh = es
                eye.position = Vector3(sx * BALL_R * 0.36,
                                BALL_R * 0.3, BALL_R * 0.82)
                eye.material_override = eye_mat
                ball_face.add_child(eye)
        # THE FIRE CROWN (the boost visuals ride the ball)
        fire_p = CPUParticles3D.new()
        fire_p.emitting = false
        fire_p.amount = 46
        fire_p.lifetime = 0.6
        fire_p.mesh = SphereMesh.new()
        (fire_p.mesh as SphereMesh).radius = BALL_R * 0.3
        (fire_p.mesh as SphereMesh).height = BALL_R * 0.6
        fire_p.direction = Vector3(0, 1, 0)
        fire_p.spread = 180.0
        fire_p.gravity = Vector3(0, 6, 0)
        fire_p.initial_velocity_min = 2.0
        fire_p.initial_velocity_max = 6.0
        fire_p.scale_amount_min = 0.6
        fire_p.scale_amount_max = 1.3
        var fr := Gradient.new()
        fr.set_color(0, Color(1.0, 0.85, 0.25, 0.9))
        fr.set_color(1, Color(0.95, 0.25, 0.05, 0.0))
        fire_p.color_ramp = fr
        var fm := StandardMaterial3D.new()
        fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        fm.vertex_color_use_as_albedo = true
        fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        fm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
        fire_p.material_override = fm
        ball_mesh.add_child(fire_p)
        # THE TRAIL (the skin's character + the fire's white)
        trail_p = CPUParticles3D.new()
        trail_p.emitting = false
        trail_p.amount = 26
        trail_p.lifetime = 0.45
        trail_p.mesh = SphereMesh.new()
        (trail_p.mesh as SphereMesh).radius = BALL_R * 0.3
        (trail_p.mesh as SphereMesh).height = BALL_R * 0.6
        trail_p.gravity = Vector3.ZERO
        trail_p.initial_velocity_min = 0.0
        trail_p.initial_velocity_max = 0.0
        trail_p.scale_amount_min = 0.4
        trail_p.scale_amount_max = 0.9
        var tr := Gradient.new()
        tr.set_color(0, Color(1, 1, 1, 0.5))
        tr.set_color(1, Color(1, 1, 1, 0.0))
        trail_p.color_ramp = tr
        trail_p.material_override = fm.duplicate()
        ball_mesh.add_child(trail_p)

func _apply_ball_skin() -> void:
        var s := TB.ball_skin()
        ball_mat.albedo_color = s["color"]
        ball_mat.roughness = s["rough"]
        ball_mat.metallic = s["metal"]
        if float(s["alpha"]) < 1.0:
                ball_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
                ball_mat.albedo_color.a = float(s["alpha"])
        else:
                ball_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED

# ----------------------------------------------------------------- intro

var _intro_ui: Control = null

func _build_intro() -> void:
        phase = "intro"
        _intro_ui = Control.new()
        _intro_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
        _intro_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _overlay_root_ref().add_child(_intro_ui)
        var vb := VBoxContainer.new()
        vb.add_theme_constant_override("separation", 22)
        vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _intro_ui.add_child(vb)
        # the logo rides HIGH - the bouncing ball owns the screen's center
        # (the r1 logo covered it: the owner never saw the ball)
        vb.anchor_left = 0.5
        vb.anchor_right = 0.5
        vb.anchor_top = 0.0
        vb.anchor_bottom = 0.0
        vb.offset_left = -310.0
        vb.offset_right = 310.0
        vb.offset_top = 150.0
        var logo := TextureRect.new()
        logo.texture = load("res://assets/games/towerball/logo.png")
        logo.custom_minimum_size = Vector2(620, 620.0 * 420.0 / 620.0)
        logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.add_child(logo)
        var tap := Arc.label("TAP ANYWHERE TO START", 44, Color(1, 1, 1))
        tap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        tap.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.02))
        tap.add_theme_constant_override("outline_size", 12)
        tap.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.add_child(tap)
        # the ball bounces on the top disc THROUGH the intro - the game is
        # alive from the first frame (the owner: "the ball is not even a
        # ball, not even exist" - never hidden again)
        ball_mesh.visible = true

func _intro_start() -> void:
        Jukebox.sfx("tb_click", -6.0)
        if _intro_ui != null and is_instance_valid(_intro_ui):
                _intro_ui.queue_free()
                _intro_ui = null
        _optionals_open()

# ------------------------------------------------------------ optionals
# THE OWNER: "make the mode selection as the optionals menu" - the mode
# cards + the position cards (the snake ask design) + PLAY live here.
# r2: the menu ALWAYS shows (fresh boot AND the position reload) - the
# game never starts itself.

func _optionals_open() -> void:
        phase = "optionals"
        var sheet := sheet_push(0.0, "optionals")
        var t := Arc.label("TOWER BALL", 42, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        sheet.add_child(Arc.fit_label("MODE", 24, Arc.HOT, 560))
        var mrow := HBoxContainer.new()
        mrow.add_theme_constant_override("separation", 14)
        mrow.alignment = BoxContainer.ALIGNMENT_CENTER
        sheet.add_child(mrow)
        for m in ["ball", "platform"]:
                var card := _mode_card(m, mode == m)
                card.pressed.connect(func():
                        mode = m
                        Box.set_progress(game_id, "mode", m)
                        Jukebox.sfx("tb_click", -6.0)
                        _shop_reopen("optionals"))
                mrow.add_child(card)
        sheet.add_child(Arc.fit_label("POSITION", 24, Arc.HOT, 560))
        var prow := HBoxContainer.new()
        prow.add_theme_constant_override("separation", 14)
        prow.alignment = BoxContainer.ALIGNMENT_CENTER
        sheet.add_child(prow)
        var live := _live_orient()
        for choice in ["vertical", "horizontal"]:
                var card := _pos_card(choice, live == choice)
                card.pressed.connect(func():
                        Jukebox.sfx("tb_click", -6.0)
                        Box.set_progress(game_id, "orient_pref", choice))
                prow.add_child(card)
        var play := Arc.button("PLAY", Vector2(560, 86), 32, Arc.GOOD,
                func(): _play_pressed())
        sheet.add_child(play)
        Arc.fit_sheet(sheet, 2)

func _live_orient() -> String:
        var vp := get_viewport().get_visible_rect().size
        return "horizontal" if vp.x > vp.y else "vertical"

func _play_pressed() -> void:
        var picked := String(Box.get_progress(game_id, "orient_pref", ""))
        if picked == "vertical" or picked == "horizontal":
                if picked != _live_orient():
                        request_orientation_reload.emit(picked)
                        return
        _start_run()

func _start_run() -> void:
        round_idx = 1
        set_score(0)
        run_coins = 0
        if _coins_label != null:
                _coins_label.text = "0"
        _build_round()
        _transition()

# ----------------------------------------------------------------- rounds

func _build_round() -> void:
        round_len = TB.round_length(round_idx)
        rows_data.clear()
        for i in round_len:
                if mode == "ball":
                        rows_data.append(TB.gen_row(i, round_len, rng,
                                        round_idx))
                else:
                        rows_data.append(TB.gen_ring(i, round_len, rng,
                                        round_idx))
        # the coin: the round AFTER every 6 wins carries one (the field
        # builds FIRST so the platform seat has its geometry)
        coin_row_idx = -1
        coin_seg = -1
        coin_ring_idx = -1
        if coin_node != null and is_instance_valid(coin_node):
                coin_node.queue_free()
        coin_node = null
        if mode == "ball":
                if TB.coin_due(score):
                        var cr := TB.coin_row(round_len, rng)
                        if cr >= 0:
                                coin_row_idx = cr
                                coin_seg = TB.pick_coin_seg(rows_data[cr], rng)
                _build_ball_tower()
        else:
                # the coin's seat rides a ring's GAP - decided BEFORE the
                # build (the ring nodes carry their coin at birth)
                if TB.coin_due(score):
                        coin_ring_idx = TB.coin_ring(round_len, rng)
                _build_platform_tower()

## the slide-in banner (wordless except the round number - UI, not lore)
func _transition() -> void:
        phase = "transition"
        if banner != null and is_instance_valid(banner):
                banner.queue_free()
        banner = Arc.label("ROUND %d" % round_idx, 64, Color(1, 1, 1))
        banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        banner.add_theme_color_override("font_outline_color",
                        Color(0.2, 0.1, 0.02))
        banner.add_theme_constant_override("outline_size", 14)
        banner.set_anchors_preset(Control.PRESET_CENTER)
        banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
        banner.grow_vertical = Control.GROW_DIRECTION_BOTH
        banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _overlay_root_ref().add_child(banner)
        banner.modulate.a = 0.0
        var tw := banner.create_tween()
        tw.tween_property(banner, "modulate:a", 1.0, 0.18)
        tw.tween_interval(0.7)
        tw.tween_property(banner, "modulate:a", 0.0, 0.3)
        tw.tween_callback(func():
                if banner != null and is_instance_valid(banner):
                        banner.queue_free()
                banner = null
                if phase == "transition":
                        phase = "run"
                        ball_mesh.visible = true
                        if mode == "platform":
                                p_started = true)

func _round_won() -> void:
        phase = "won"
        streak = 0.0
        boost_v = TB.BOOST_START
        boosting = false
        boost_charge_t = 0.0
        fire_p.emitting = false
        trail_p.emitting = false
        add_score(1)
        achievement_count("rounds_won", 1)
        achievement_max("round_max", round_idx)
        Jukebox.sfx("tb_win", -3.0)
        var vp := get_viewport().get_visible_rect().size
        Arc.confetti(_overlay_root_ref(), vp * 0.5)
        var tw := create_tween()
        tw.tween_interval(1.15)
        tw.tween_callback(func():
                if over:
                        return
                round_idx += 1
                _build_round()
                _transition())

func _run_over() -> void:
        if phase == "over":
                return
        phase = "over"
        var tw := create_tween()
        tw.tween_interval(0.55)
        tw.tween_callback(func(): finish_run(score, run_coins))

# ================================================================ BALL MODE
# THE STACK BALL SMASH - the tower spins, the ball dives, the discs shatter.

func _build_ball_tower() -> void:
        for k in discs:
                var d: Dictionary = discs[k]
                if d["node"] != null and is_instance_valid(d["node"]):
                        d["node"].queue_free()
        discs.clear()
        if victory_disc != null and is_instance_valid(victory_disc):
                victory_disc.queue_free()
        victory_disc = null
        _clear_frags()
        top_row = 0
        by = THICK * 0.5 + BALL_R
        bvy = 0.0
        cam_y = by
        streak = 0.0
        boost_v = TB.BOOST_START
        boosting = false
        boost_charge_t = 0.0
        fire_p.emitting = false
        trail_p.emitting = false
        stun_t = 0.0
        victory_y = -float(round_len) * PITCH - 6.0
        _build_pole()
        _make_victory_disc()
        _ensure_discs()
        ball_mesh.visible = true
        ball_base_scale = 1.0
        ball_mesh.scale = Vector3.ONE
        ball_mesh.position = Vector3(0, by, BALL_Z)
        _apply_ball_skin()
        _apply_tower_skin()
        _cam_follow(0.016)            # seat the camera for the intro too

## the victory disc: gold, safe, the round's end - the ball lands, the
## round is won
var victory_disc: MeshInstance3D = null

func _make_victory_disc() -> void:
        victory_disc = MeshInstance3D.new()
        var data := {"count": 12, "black": []}
        for i in 12:
                data["black"].append(false)
        victory_disc.mesh = _disc_mesh(data, Color("e8b830"))
        victory_disc.material_override = _tower_material()
        victory_disc.position.y = victory_y
        world.add_child(victory_disc)

func _build_pole() -> void:
        if pole != null and is_instance_valid(pole):
                pole.queue_free()
        pole = MeshInstance3D.new()
        var cyl := CylinderMesh.new()
        cyl.top_radius = POLE_R
        cyl.bottom_radius = POLE_R
        cyl.height = absf(victory_y) + 60.0
        cyl.radial_segments = 20
        pole.mesh = cyl
        var pm := StandardMaterial3D.new()
        pm.albedo_color = Color(String(TB.break_skin()["pole"]))
        pm.roughness = 0.6
        pole.material_override = pm
        pole.position.y = -cyl.height * 0.5 + 20.0
        world.add_child(pole)

## the alive window: every row in [top_row, top_row + WINDOW] gets its disc
func _ensure_discs() -> void:
        for r in range(top_row, mini(round_len, top_row + WINDOW + 1)):
                if not discs.has(r):
                        discs[r] = _make_disc(r)
        var dead: Array = []
        for r in discs:
                if int(r) < top_row:
                        dead.append(r)
        for r in dead:
                var d: Dictionary = discs[r]
                if d["node"] != null and is_instance_valid(d["node"]):
                        d["node"].queue_free()
                discs.erase(r)

func _make_disc(row: int) -> Dictionary:
        var data: Dictionary = rows_data[row]
        var node := MeshInstance3D.new()
        var color := TB.ramp_color(TB.break_skin(), row)
        node.mesh = _disc_mesh(data, color)
        node.material_override = _tower_material()
        node.position.y = -float(row) * PITCH
        world.add_child(node)
        var st := {"row": row, "data": data, "node": node,
                        "rot": rng.randf_range(0.0, TAU), "coin": null}
        if row == coin_row_idx and coin_seg >= 0:
                var coin: Coin3D = Coin3DL.new()
                var seg_ang := TAU / float(data["count"])
                var mid := (float(coin_seg) + 0.5) * seg_ang
                var r_mid := (R_IN + R_OUT) * 0.42
                coin.position = Vector3(sin(mid) * r_mid, THICK * 0.5 + 0.4,
                                cos(mid) * r_mid)
                coin.rotation_degrees = Vector3(-90, 0, 0)   # flat on the disc
                node.add_child(coin)
                coin.set_diameter(Coin3DL.world_diameter(TB.COIN_DESIGN_PX,
                                cam, _cam_dist()))
                st["coin"] = coin
                coin_node = coin
        return st

var _tower_mat: StandardMaterial3D = null

func _tower_material() -> StandardMaterial3D:
        if _tower_mat == null:
                _tower_mat = StandardMaterial3D.new()
                _tower_mat.albedo_color = Color.WHITE
                _tower_mat.vertex_color_use_as_albedo = true
                _tower_mat.roughness = 0.52
                _tower_mat.metallic = 0.05
        return _tower_mat

## one disc = ONE ArrayMesh: every segment baked in, vertex-colored
## (the draw-call law: ~1 draw per alive row, a 900-row round stays cheap)
func _disc_mesh(data: Dictionary, color: Color) -> ArrayMesh:
        var st := SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        var count := int(data["count"])
        var black: Array = data["black"]
        var seg := TAU / float(count)
        var gap := 0.014
        var h := THICK * 0.5
        var skin := TB.break_skin()
        var alpha := float(skin["alpha"])
        for i in count:
                var c: Color = TB.BLACK if bool(black[i]) else color
                var a0 := float(i) * seg + gap * 0.5
                var a1 := float(i + 1) * seg - gap * 0.5
                _quad(st,
                        Vector3(sin(a0) * R_IN, h, cos(a0) * R_IN),
                        Vector3(sin(a1) * R_IN, h, cos(a1) * R_IN),
                        Vector3(sin(a1) * R_OUT, h, cos(a1) * R_OUT),
                        Vector3(sin(a0) * R_OUT, h, cos(a0) * R_OUT),
                        Vector3.UP, c)
                _quad(st,
                        Vector3(sin(a0) * R_IN, -h, cos(a0) * R_IN),
                        Vector3(sin(a0) * R_OUT, -h, cos(a0) * R_OUT),
                        Vector3(sin(a1) * R_OUT, -h, cos(a1) * R_OUT),
                        Vector3(sin(a1) * R_IN, -h, cos(a1) * R_IN),
                        Vector3.DOWN, c)
                _quad(st,
                        Vector3(sin(a0) * R_OUT, -h, cos(a0) * R_OUT),
                        Vector3(sin(a0) * R_OUT, h, cos(a0) * R_OUT),
                        Vector3(sin(a1) * R_OUT, h, cos(a1) * R_OUT),
                        Vector3(sin(a1) * R_OUT, -h, cos(a1) * R_OUT),
                        _outward(a0, a1), c)
                _quad(st,
                        Vector3(sin(a0) * R_IN, -h, cos(a0) * R_IN),
                        Vector3(sin(a1) * R_IN, -h, cos(a1) * R_IN),
                        Vector3(sin(a1) * R_IN, h, cos(a1) * R_IN),
                        Vector3(sin(a0) * R_IN, h, cos(a0) * R_IN),
                        Vector3(0, 0, 0), c)   # inner wall (normal set below)
                _quad(st,
                        Vector3(sin(a0) * R_OUT, -h, cos(a0) * R_OUT),
                        Vector3(sin(a0) * R_IN, -h, cos(a0) * R_IN),
                        Vector3(sin(a0) * R_IN, h, cos(a0) * R_IN),
                        Vector3(sin(a0) * R_OUT, h, cos(a0) * R_OUT),
                        _side_normal(a0), c)
                _quad(st,
                        Vector3(sin(a1) * R_IN, -h, cos(a1) * R_IN),
                        Vector3(sin(a1) * R_OUT, -h, cos(a1) * R_OUT),
                        Vector3(sin(a1) * R_OUT, h, cos(a1) * R_OUT),
                        Vector3(sin(a1) * R_IN, h, cos(a1) * R_IN),
                        _side_normal(a1) * -1.0, c)
        return st.commit()

func _outward(a0: float, a1: float) -> Vector3:
        var mid := (a0 + a1) * 0.5
        return Vector3(sin(mid), 0, cos(mid))

func _side_normal(a: float) -> Vector3:
        return Vector3(cos(a), 0, -sin(a))

## one flat quad (two triangles), one normal, one color
func _quad(st: SurfaceTool, p1: Vector3, p2: Vector3, p3: Vector3,
                p4: Vector3, n: Vector3, c: Color) -> void:
        var nn := n
        if nn.length_squared() < 0.001:
                # the inner wall's normal points at the axis from the wall
                nn = Vector3(p1.x, 0, p1.z).normalized() * -1.0
        for p in [p1, p2, p3, p1, p3, p4]:
                st.set_normal(nn)
                st.set_color(c)
                st.add_vertex(p)

## the contact: the segment under the ball AT the frame of contact.
## `quiet` = the crash blast tore the disc open - no streak, no coin
## (the coin dies with its disc: it CAN be missed).
func _shatter_top(quiet := false) -> void:
        var d: Dictionary = discs.get(top_row, {})
        if d.is_empty():
                return
        var data: Dictionary = d["data"]
        var count := int(data["count"])
        var black: Array = data["black"]
        var seg := TB.seg_under_ball(count, float(d["rot"]))
        var node: Node3D = d["node"]
        # the coin seat: collect only when the CONTACT lands on the coin's
        # segment - the wrong segment pops the coin away (it can be missed)
        if top_row == coin_row_idx and coin_seg >= 0:
                if not quiet and seg == coin_seg and d["coin"] != null \
                                and is_instance_valid(d["coin"]):
                        add_run_coins(1)
                        achievement_count("coins_taken", 1)
                        Jukebox.sfx("coin", -2.0)
                        (d["coin"] as Coin3D).collect()
                else:
                        Jukebox.sfx("tb_miss", -8.0)
                coin_row_idx = -1
                coin_seg = -1
        # THE BREAK VFX: the disc dies as its own SEGMENTS (wedge fragments
        # in the segments' own colors) + the ring shockwave + the dust
        _break_vfx_disc(node.position.y, data, float(d["rot"]))
        node.queue_free()
        discs.erase(top_row)
        # the disc gave way on EVERY path (the crash's quiet tear included)
        # - only the STREAK and the boost wait for an honest smash
        top_row += 1
        if not quiet:
                var skin := TB.break_skin()
                Jukebox.sfx(String(skin["sfx"]), -4.0,
                                rng.randf_range(0.92, 1.1)
                                + minf(streak, 30.0) * 0.004)
                # THE EXACT BOOST LAW: +0.03 a break (Stack Bounce verbatim)
                if not boosting and boost_charge_t <= 0.0:
                        streak = streak + 1.0
                        boost_v = TB.boost_after_break(boost_v)
                        if TB.boost_ready(boost_v):
                                # the slow-mo charge: the world breathes,
                                # the ball heats up, then it BURNS
                                boost_charge_t = TB.BOOST_CHARGE_TIME
                                Jukebox.sfx("tb_charge", -3.0)
                else:
                        streak = streak + 1.0
        _ensure_discs()

## THE IGNITION (Stack Bounce boost() verbatim): the ball IS the fireball
func _ignite_fire() -> void:
        boosting = true
        fire_p.emitting = true
        trail_p.emitting = true
        ball_mat.emission_enabled = true
        ball_mat.emission = Color(1.0, 0.35, 0.05)
        ball_mat.emission_energy_multiplier = 1.6
        Jukebox.sfx("tb_fire", -2.0)
        Jukebox.loop("tb_fire_loop", -10.0)
        achievement_count("fires", 1)

## the burn-out (stopBoosting verbatim): the fire dies, the cooldown floor
func _extinguish_fire() -> void:
        boosting = false
        boost_v = TB.BOOST_FLOOR
        fire_p.emitting = false
        trail_p.emitting = false
        ball_mat.emission_enabled = false
        Jukebox.stop_loop("tb_fire_loop")

func _ball_tick(delta: float) -> void:
        # THE BOOST CLOCK (updateBoosting verbatim): the charge slow-mo,
        # the burn drain, the idle decay, the floor
        if boost_charge_t > 0.0:
                boost_charge_t -= delta
                if boost_charge_t <= 0.0:
                        boost_charge_t = 0.0
                        _ignite_fire()
        if boosting:
                boost_v = TB.boost_tick(boost_v, delta, true)
                if boost_v <= 0.0:
                        _extinguish_fire()
        elif boost_charge_t <= 0.0 and boost_v > TB.BOOST_FLOOR:
                boost_v = TB.boost_tick(boost_v, delta, false)
                if boost_v < TB.BOOST_FLOOR:
                        boost_v = TB.BOOST_FLOOR
        if phase != "run":
                if phase != "over" and phase != "won":
                        # the intro/optionals scenery bounce
                        _ball_idle(delta)
                if gauge != null:
                        gauge.queue_redraw()
                return
        stun_t = maxf(0.0, stun_t - delta)
        var want_hold: bool = (holding or key_hold or pad_hold) \
                        and stun_t <= 0.0
        var smashing := want_hold
        # the dive speed: the fireball dives deeper (m_fireSpeed's seat)
        var dive := SMASH_V * (FIRE_SMASH_MULT if boosting else 1.0)
        # the charge slow-mo: the TOWER breathes while the charge winds up
        var slomo := TB.BOOST_SLOMO if boost_charge_t > 0.0 else 1.0
        if smashing:
                bvy = dive
        else:
                bvy += GRAV * delta
                if bvy < MAX_FALL:
                        bvy = MAX_FALL
        by += bvy * delta
        # discs spin (the charge slow-mo rides their spin)
        for r in discs:
                var d: Dictionary = discs[r]
                d["rot"] = float(d["rot"]) + float(d["data"]["rot"]) * delta \
                                * slomo
                if d["node"] != null and is_instance_valid(d["node"]):
                        (d["node"] as Node3D).rotation.y = float(d["rot"])
        # contact with the top disc (only while a tower remains - once the
        # last disc is gone the ball free-falls onto the victory disc:
        # a ghost contact plane up here would snap-catch it forever and
        # the round could never complete)
        var top_surface := -float(top_row) * PITCH + THICK * 0.5
        if top_row < round_len and bvy < 0.0 and by - BALL_R <= top_surface:
                by = top_surface + BALL_R
                var d2: Dictionary = discs.get(top_row, {})
                var black_seg := false
                if not d2.is_empty():
                        var data: Dictionary = d2["data"]
                        var seg := TB.seg_under_ball(int(data["count"]),
                                        float(d2["rot"]))
                        black_seg = bool(data["black"][seg])
                if smashing:
                        if black_seg and not boosting:
                                _crash(top_surface)
                        else:
                                _shatter_top()
                else:
                        # the bounce: the ball floats up
                        bvy = BOUNCE_V
                        Jukebox.sfx("tb_bounce", -6.0,
                                        rng.randf_range(0.9, 1.12))
        # the victory disc
        if top_row >= round_len and by - BALL_R <= victory_y + THICK * 0.5:
                by = victory_y + THICK * 0.5 + BALL_R
                bvy = BOUNCE_V
                _round_won()
        # the ball's world seat: the mesh rides the physics every tick -
        # ON the disc's front area (the contact law's world angle 0)
        ball_mesh.position = Vector3(0, by, BALL_Z)
        _ball_wobble(delta, smashing)
        trail_p.emitting = boosting or smashing
        if gauge != null:
                gauge.queue_redraw()
        _cam_follow(delta)

## the intro/optionals scenery: the ball bounces on the top disc
func _ball_idle(delta: float) -> void:
        var top_surface := THICK * 0.5 + BALL_R
        bvy += GRAV * delta
        by += bvy * delta
        if by <= top_surface and bvy < 0.0:
                by = top_surface
                bvy = BOUNCE_V * 0.75
                Jukebox.sfx("tb_bounce", -16.0, rng.randf_range(0.9, 1.1))
        ball_mesh.position = Vector3(0, by, BALL_Z)
        for r in discs:
                var d: Dictionary = discs[r]
                d["rot"] = float(d["rot"]) + float(d["data"]["rot"]) * delta
                if d["node"] != null and is_instance_valid(d["node"]):
                        (d["node"] as Node3D).rotation.y = float(d["rot"])
        _cam_follow(delta)

## the ball's squash-stretch + the roll spin (the ball is ALIVE)
var _sq := 1.0

func _ball_wobble(delta: float, smashing: bool) -> void:
        var target := 0.86 if smashing else 1.0
        _sq = lerpf(_sq, target, 1.0 - exp(-9.0 * delta))
        var w := 1.0 / maxf(0.5, _sq)
        ball_mesh.scale = Vector3(ball_base_scale * w,
                        ball_base_scale * _sq, ball_base_scale * w)
        ball_face.rotation.y += delta * 2.2

## THE CRASH (r2: NO LIVES - the owner's law. One crash = the run over.)
func _crash(surface_y: float) -> void:
        streak = 0.0
        shake_t = 0.6
        Jukebox.sfx("tb_crash", -2.0)
        _red_flash()
        _frag(TB.BLACK, Vector3(0, surface_y + 1.0, 0),
                Vector3(0, 9.0, 0))
        for i in 10:
                var ang := rng.randf_range(0.0, TAU)
                _frag(TB.BLACK, Vector3(sin(ang) * 4.0, surface_y + 1.2,
                                cos(ang) * 4.0),
                        Vector3(sin(ang) * rng.randf_range(5.0, 11.0),
                                rng.randf_range(4.0, 9.0),
                                cos(ang) * rng.randf_range(5.0, 11.0)))
        _extinguish_fire()
        _shatter_top(true)
        bvy = SMASH_V * 0.35
        stun_t = 0.5
        _run_over()

## the red crash flash (a full-rect blush that dies fast)
var _flash: ColorRect = null

func _red_flash() -> void:
        if _flash != null and is_instance_valid(_flash):
                _flash.queue_free()
        _flash = ColorRect.new()
        _flash.color = Color(0.9, 0.1, 0.05, 0.32)
        _flash.set_anchors_preset(Control.PRESET_FULL_RECT)
        _flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _overlay_root_ref().add_child(_flash)
        var tw := _flash.create_tween()
        tw.tween_property(_flash, "color:a", 0.0, 0.4)
        tw.tween_callback(func():
                if _flash != null and is_instance_valid(_flash):
                        _flash.queue_free()
                _flash = null)

func _cam_follow(delta: float) -> void:
        cam_y = lerpf(cam_y, by, 1.0 - exp(-7.0 * delta))
        shake_t = maxf(0.0, shake_t - delta)
        var d := _cam_dist()
        var tilt := deg_to_rad(CAM_TILT)
        var focus := Vector3(0, cam_y - 3.0, 0)
        var target := focus + Vector3(0, sin(tilt) * d, cos(tilt) * d)
        if shake_t > 0.0:
                var s := shake_t * shake_t * 1.4
                target += Vector3(rng.randf_range(-s, s),
                                rng.randf_range(-s, s), 0)
        cam.position = target
        cam.look_at(focus, Vector3.UP)
        # the living sky rides with the camera (the clouds/stars never parallax
        # away into nothing)
        sky_layer.position.y = cam_y

func _cam_dist() -> float:
        var vp := get_viewport().get_visible_rect().size
        var aspect := vp.x / maxf(1.0, vp.y)
        var tanv := tan(deg_to_rad(CAM_FOV) * 0.5)
        var tanh_ := tanv * aspect
        var d := R_OUT / maxf(0.02, tanh_ * 0.66)
        # the floor keeps the STACK visible on wide windows (a close camera
        # hides the discs under the top one); portrait needs the FARTHER seat
        var floor_d := 54.0 if aspect > 1.2 else 66.0
        return clampf(d, floor_d, 130.0)

# ============================================================ PLATFORM MODE
# THE REAL NEON TOWER (the famobi decompile, round-shaped on the ladder):
# the ball ORBITS the pole at a fixed radius and bounces vertically on its
# own; the PLAYER rotates the TOWER of ring-platforms; falls through gaps
# build the combo (fall score = combo+1, the pending banks land on the next
# solid); the combo charge (4 falls) SMASHES the next solid platform; red
# sectors + walls kill; rotating a wall's side through the ball kills.

func _build_platform_tower() -> void:
        for k in rings:
                var d: Dictionary = rings[k]
                if d["node"] != null and is_instance_valid(d["node"]):
                        d["node"].queue_free()
        rings.clear()
        _clear_frags()
        p_top = 0
        p_y = P_APEX
        p_vy = 0.0
        p_combo = 0
        p_pending = 0
        p_cam_y = p_y
        p_started = false
        ball_base_scale = PBALL_R / BALL_R
        ball_mesh.scale = Vector3.ONE * ball_base_scale
        _ensure_rings()
        _build_pole_p()
        ball_mesh.visible = true
        ball_mesh.position = _p_ball_pos()
        _apply_ball_skin()
        _apply_tower_skin()
        _platform_cam(0.016)

func _build_pole_p() -> void:
        if pole != null and is_instance_valid(pole):
                pole.queue_free()
        pole = MeshInstance3D.new()
        var cyl := CylinderMesh.new()
        cyl.top_radius = P_POLE_R
        cyl.bottom_radius = P_POLE_R
        cyl.height = float(round_len) * P_PITCH + 80.0
        cyl.radial_segments = 20
        pole.mesh = cyl
        var pm := StandardMaterial3D.new()
        pm.albedo_color = Color(String(TB.break_skin()["pole"]))
        pm.roughness = 0.6
        pole.material_override = pm
        pole.position.y = -cyl.height * 0.5 + 24.0
        world.add_child(pole)

func _ring_y(row: int) -> float:
        return -float(row) * P_PITCH

## the alive window rides the ball's descent
func _ensure_rings() -> void:
        while p_top < round_len \
                        and _ring_y(p_top) > p_y - P_WINDOW * P_PITCH:
                if not rings.has(p_top):
                        rings[p_top] = _make_ring(p_top)
                p_top += 1
        var dead: Array = []
        for r in rings:
                if int(r) < p_top - P_WINDOW - 6:
                        dead.append(r)
        for r in dead:
                var d: Dictionary = rings[r]
                if d["node"] != null and is_instance_valid(d["node"]):
                        d["node"].queue_free()
                rings.erase(r)

func _make_ring(row: int) -> Dictionary:
        var data: Dictionary = rows_data[row]
        var node := MeshInstance3D.new()
        node.mesh = _ring_mesh(data, row)
        node.material_override = _tower_material()
        node.position.y = _ring_y(row)
        world.add_child(node)
        # the walls: small boxes standing on the rim, movers carry a speed
        var wall_nodes: Array = []
        for w in data["walls"]:
                var wm := MeshInstance3D.new()
                var bm := BoxMesh.new()
                var wd := deg_to_rad(P_WALL_DEG)
                var arc := P_RING_R * wd
                bm.size = Vector3(maxf(0.5, arc), float(w["h"]), 0.9)
                wm.mesh = bm
                var wmat := StandardMaterial3D.new()
                wmat.albedo_color = TB.BLACK
                wmat.roughness = 0.7
                wm.material_override = wmat
                var wr := Node3D.new()
                wr.rotation.y = float(w["a"])
                var rr := P_RING_R - 0.45
                wr.position = Vector3(0, P_RING_H * 0.5 + float(w["h"]) * 0.5,
                                0)
                wm.position = Vector3(0, 0, rr)
                wr.add_child(wm)
                node.add_child(wr)
                wall_nodes.append({"a": float(w["a"]), "h": float(w["h"]),
                        "spd": float(w["spd"]), "n": wr})
        var st := {"row": row, "data": data, "node": node,
                        "rot": 0.0, "walls": wall_nodes, "coin": null}
        if row == coin_ring_idx:
                var coin: Coin3D = Coin3DL.new()
                # the coin rides the guaranteed GAP's middle (the legal area:
                # fall through this ring's gap to collect it)
                var mid: float = float(data["gap0"]) + float(data["gap"]) * 0.5
                coin.position = Vector3(sin(mid) * P_RING_R * 0.55,
                                P_RING_H + 1.2, cos(mid) * P_RING_R * 0.55)
                node.add_child(coin)
                coin.set_diameter(Coin3DL.world_diameter(TB.COIN_DESIGN_PX,
                                cam, P_CAM_D))
                st["coin"] = coin
                coin_node = coin
        return st

## one ring = ONE ArrayMesh: the solid sectors in the row's color, the RED
## sectors in the danger ink (always red-black, every skin), the gaps open.
func _ring_mesh(data: Dictionary, row: int) -> ArrayMesh:
        var st := SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        var color := TB.ramp_color(TB.break_skin(), row)
        var h := P_RING_H * 0.5
        var r := P_RING_R
        var r_in := P_POLE_R + 0.4
        var gap0: float = float(data["gap0"])
        var gap: float = float(data["gap"])
        # the solids
        for s in data["solid"]:
                _ring_sector(st, float(s[0]), float(s[1]), r, r_in, h, color)
        # the reds
        for rd in data["red"]:
                _ring_sector(st, float(rd[0]), float(rd[1]), r, r_in, h,
                                Color("c62828"))
        return st.commit()

## one angular sector: top, bottom, outer wall - FANNED into sub-arcs
## (a [0, TAU] full-circle sector is four collinear points as ONE quad:
## the mesh collapses to a sliver - the r2 missing-rings root)
func _ring_sector(st: SurfaceTool, a0: float, a1: float, r: float,
                r_in: float, h: float, c: Color) -> void:
        if a1 - a0 < 0.004:
                return
        var steps := maxi(1, int(ceilf((a1 - a0) / 0.35)))
        for i in steps:
                var s0: float = lerpf(a0, a1, float(i) / float(steps))
                var s1: float = lerpf(a0, a1, float(i + 1) / float(steps))
                var mid := (s0 + s1) * 0.5
                var out := Vector3(sin(mid), 0, cos(mid))
                _quad(st,
                        Vector3(sin(s0) * r_in, h, cos(s0) * r_in),
                        Vector3(sin(s1) * r_in, h, cos(s1) * r_in),
                        Vector3(sin(s1) * r, h, cos(s1) * r),
                        Vector3(sin(s0) * r, h, cos(s0) * r),
                        Vector3.UP, c)
                _quad(st,
                        Vector3(sin(s0) * r_in, -h, cos(s0) * r_in),
                        Vector3(sin(s0) * r, -h, cos(s0) * r),
                        Vector3(sin(s1) * r, -h, cos(s1) * r),
                        Vector3(sin(s1) * r_in, -h, cos(s1) * r_in),
                        Vector3.DOWN, c)
                _quad(st,
                        Vector3(sin(s0) * r, -h, cos(s0) * r),
                        Vector3(sin(s0) * r, h, cos(s0) * r),
                        Vector3(sin(s1) * r, h, cos(s1) * r),
                        Vector3(sin(s1) * r, -h, cos(s1) * r),
                        out, c)

func _p_ball_pos() -> Vector3:
        # the ball rides the WORLD angle 0 (the camera's side), at its orbit
        # radius: the mesh's seat every tick
        return Vector3(0.0, p_y, P_OFFSET)

## the tower rotation: EVERY ring rotates together (the original's pole)
func _rotate_tower(amt: float) -> void:
        if absf(amt) < 0.000001:
                return
        # THE ORIGINAL'S getAvailableRotation: when the ball's center sits
        # inside a ring's vertical band, a sector edge sweeping through the
        # ball kills (isRotational). Compute the safe rotation across every
        # ring band the ball overlaps.
        var safe := amt
        var deadly := false
        for r in rings:
                var d: Dictionary = rings[r]
                var ry := _ring_y(int(r))
                # THE SLAB BAND: the ball's CENTER inside the ring's own
                # height (not resting on top - resting rotates free, the
                # original's verticalStart law)
                var band_top := ry + P_RING_H * 0.5
                var band_bot := ry - P_RING_H * 0.5
                if p_y > band_top or p_y < band_bot:
                        continue
                var sr := TB.ring_safe_rot(d["data"], float(d["rot"]), amt)
                if absf(sr) < absf(safe):
                        safe = sr
                        if absf(sr) < absf(amt) - 0.0005:
                                deadly = true
        # walls sweep too: a wall box crossing the ball's angle at its band
        for r in rings:
                var d: Dictionary = rings[r]
                var ry := _ring_y(int(r))
                if d.has("walls"):
                        for wn in d["walls"]:
                                var wh: float = float(wn["h"])
                                var wall_top := ry + P_RING_H * 0.5 + wh
                                var wall_bot := ry + P_RING_H * 0.5
                                if p_y > wall_top + PBALL_R \
                                                or p_y < wall_bot - PBALL_R:
                                        continue
                                var wa: float = float(wn["a"]) \
                                                + float(d["rot"])
                                var wd := deg_to_rad(P_WALL_DEG) * 0.5
                                var rel := fposmod(TB.NT_BALL_ANG - wa + PI,
                                                TAU) - PI
                                var half := PBALL_R / P_OFFSET
                                var dist := absf(rel) - wd - half
                                if dist < absf(safe):
                                        safe = signf(amt) * maxf(0.0, dist)
                                        if dist <= 0.0:
                                                deadly = true
        # apply: the tower turns, the rings carry their walls
        for r in rings:
                var d: Dictionary = rings[r]
                d["rot"] = float(d["rot"]) + safe
                if d["node"] != null and is_instance_valid(d["node"]):
                        (d["node"] as Node3D).rotation.y = float(d["rot"])
        if deadly:
                _p_crash()

func _platform_tick(delta: float) -> void:
        if not p_started:
                # the optionals/idle ride: the ball bounces on the top ring
                _p_idle(delta)
                return
        # THE GAUGE MIRROR: the platform's fire is the COMBO charge - the
        # same circular widget reads it (the charge fills with falls, the
        # burn state = the smash is armed)
        boost_v = clampf(float(p_combo) / float(COMBO_THRESHOLD), 0.0, 1.0)
        boosting = p_combo >= COMBO_THRESHOLD
        boost_charge_t = 0.0
        # THE ROTATION INPUT: keys/stick hold, the drag deltas already rode
        # the rings through _rotate_tower directly (the finger is an event,
        # not a state); the keys are a state
        var ki := 0.0
        if keys.has("left"):
                ki -= 1.0
        if keys.has("right"):
                ki += 1.0
        if ki != 0.0:
                _rotate_tower(ki * TB.NT_KEYBOARD_ROT * delta)
        # the ball's vertical physics (the original verbatim: the quadratic
        # drag a = g - sign(v)*v*v*drag)
        var a := P_GRAV - signf(p_vy) * p_vy * p_vy * P_DRAG
        p_vy += a * delta
        var prev_y := p_y
        p_y += p_vy * delta
        _ensure_rings()   # the alive window rides the descent
        # the rings: the movers tick, the contacts resolve
        for r in rings:
                var d: Dictionary = rings[r]
                var ry := _ring_y(int(r))
                # the movers
                for wn in d["walls"]:
                        if float(wn["spd"]) != 0.0:
                                wn["a"] = fposmod(float(wn["a"])
                                                + float(wn["spd"]) * delta,
                                                TAU)
                # the contact: falling onto this ring's band
                var band_top := ry + P_RING_H * 0.5
                if p_vy < 0.0 and prev_y - PBALL_R >= band_top \
                                and p_y - PBALL_R < band_top:
                        var what := TB.ring_at(d["data"], TB.NT_BALL_ANG,
                                        float(d["rot"]))
                        if what == "gap":
                                # through: the combo grows, keep falling
                                _p_fall_through(d)
                                continue
                        p_y = band_top + PBALL_R
                        if what == "red":
                                _p_crash()
                                return
                        _p_land(d)
                        break
        # the finish: below the last ring = the round is won
        if p_top >= round_len and p_y < _ring_y(round_len - 1) - P_PITCH:
                _round_won()
                return
        ball_mesh.position = _p_ball_pos()
        trail_p.emitting = p_vy < -18.0
        # the coin's air window: the ring coin dies when the ball passes it
        if coin_node != null and is_instance_valid(coin_node) \
                        and coin_ring_idx >= 0:
                var ry2 := _ring_y(coin_ring_idx)
                if p_y < ry2 - P_PITCH * 1.5:
                        Jukebox.sfx("tb_miss", -8.0)
                        coin_node.queue_free()
                        coin_node = null
                        coin_ring_idx = -1
        if gauge != null:
                gauge.queue_redraw()
        _platform_cam(delta)

## the optionals/idle ride: the ball bounces on the top ring (ring 0 is
## born fully solid - the original's "start" chunk)
func _p_idle(delta: float) -> void:
        var rest := P_RING_H * 0.5 + PBALL_R
        var a := P_GRAV - signf(p_vy) * p_vy * p_vy * P_DRAG
        p_vy += a * delta
        p_y += p_vy * delta
        if p_y <= rest and p_vy < 0.0:
                p_y = rest
                p_vy = P_BOUNCE * 0.55
        ball_mesh.position = _p_ball_pos()
        _platform_cam(delta)

## a solid landing: the combo resets UNLESS the charge SMASHES through
## (the original verbatim: the landing platform destroys itself and the
## ball keeps falling - the charge is consumed)
func _p_land(d: Dictionary) -> void:
        if p_combo >= COMBO_THRESHOLD:
                # THE SMASH-THROUGH (their combo law: threshold 4)
                Jukebox.sfx("tb_smash", -2.0)
                p_combo = 0
                p_pending = 0
                _break_vfx_ring(d)
                rings.erase(d["row"])
                (d["node"] as Node3D).queue_free()
                Jukebox.sfx(String(TB.break_skin()["sfx"]), -5.0)
                achievement_count("smashes", 1)
                return
        # the honest bounce: the pending banks, the combo dies
        p_vy = P_BOUNCE
        p_pending = 0
        p_combo = 0
        Jukebox.sfx("tb_bounce", -6.0, rng.randf_range(0.9, 1.12))

## a gap fall: the combo grows (the original: score = comboCounter+1)
func _p_fall_through(d: Dictionary) -> void:
        p_combo += 1
        p_pending += p_combo + 1
        Jukebox.sfx("tb_fall", -8.0,
                        1.0 + minf(float(p_combo), 9.0) * 0.06)
        # the coin: collect if THIS ring's gap carried it
        if int(d["row"]) == coin_ring_idx and d["coin"] != null \
                        and is_instance_valid(d["coin"]):
                add_run_coins(1)
                achievement_count("coins_taken", 1)
                Jukebox.sfx("coin", -2.0)
                (d["coin"] as Coin3D).collect()
                coin_ring_idx = -1
                coin_node = null

func _frag(c: Color, pos: Vector3, vel: Vector3) -> void:
        _break_piece(String(TB.break_skin()["vfx"]), c, pos, vel)

## THE CRASH (platform): red sector, a wall's side, no lives - the run over
func _p_crash() -> void:
        shake_t = 0.6
        Jukebox.sfx("tb_crash", -2.0)
        _red_flash()
        for i in 10:
                var ang := rng.randf_range(0.0, TAU)
                _frag(TB.BLACK, _p_ball_pos() + Vector3(sin(ang) * 1.5, 0.5,
                                cos(ang) * 1.5),
                        Vector3(sin(ang) * rng.randf_range(3.0, 7.0),
                                rng.randf_range(3.0, 7.0),
                                cos(ang) * rng.randf_range(3.0, 7.0)))
        _run_over()

func _platform_cam(delta: float) -> void:
        p_cam_y = lerpf(p_cam_y, p_y, 1.0 - exp(-6.5 * delta))
        shake_t = maxf(0.0, shake_t - delta)
        # THE AIM-DOWN FRAMING: the player aims at the rings UNDER the ball,
        # so the camera rides ~24 deg above the ball and pulls back far
        # enough that the whole ring fits the NARROW screen axis (portrait
        # needs the farther seat)
        var vp := get_viewport().get_visible_rect().size
        var aspect := vp.x / maxf(1.0, vp.y)
        var tanv := tan(deg_to_rad(P_CAM_FOV) * 0.5)
        var d: float = clampf(8.4 / maxf(0.02, tanv * aspect), 15.0, 34.0)
        var focus := Vector3(0, p_cam_y - 1.0, P_OFFSET)
        var target := focus + Vector3(0, 0.45 * d, d)
        if shake_t > 0.0:
                var s := shake_t * shake_t * 1.4
                target += Vector3(rng.randf_range(-s, s),
                                rng.randf_range(-s, s), 0)
        cam.position = target
        cam.look_at(focus, Vector3.UP)
        sky_layer.position.y = p_cam_y

## the coin seat helper (platform): the ring already carries the coin at
## build time; nothing else to place - kept for the caller symmetry
func _seat_ring_coin() -> void:
        pass

# ================================================================ THE VFX
# THE r2 BREAK SPECTACLE: the disc/ring dies as its own SEGMENTS (wedge
# fragments in the segments' own colors) + the ring shockwave + the dust.
# The skin's vfx style picks the debris character:
#   shard (glass/classic): flat sharp wedges, fast, glassy
#   rubble (rock):         chunky slow pieces + dust puffs
#   splinter (wood):       long thin planks, spinny
#   splash (water):        droplet spheres, arcing, then a mist puff

func _break_vfx_disc(pos_y: float, data: Dictionary, rot: float) -> void:
        var skin := TB.break_skin()
        var count := int(data["count"])
        var black: Array = data["black"]
        var seg := TAU / float(count)
        for i in count:
                var c: Color = TB.BLACK if bool(black[i]) \
                                else TB.ramp_color(skin, top_row)
                var a := float(i) * seg + seg * 0.5 + rot
                var rr := (R_IN + R_OUT) * 0.5
                _break_piece(skin["vfx"], c,
                        Vector3(sin(a) * rr, pos_y, cos(a) * rr),
                        Vector3(sin(a) * rng.randf_range(7.0, 16.0),
                                rng.randf_range(3.0, 12.0),
                                cos(a) * rng.randf_range(7.0, 16.0)))
        _shockwave(pos_y)

func _break_vfx_ring(d: Dictionary) -> void:
        var pos_y: float = (d["node"] as Node3D).position.y
        var skin := TB.break_skin()
        _break_piece(skin["vfx"], TB.ramp_color(skin, int(d["row"])),
                Vector3(0, pos_y, P_OFFSET),
                Vector3(0, 6.0, 2.0))
        for i in 8:
                var ang := rng.randf_range(0.0, TAU)
                _break_piece(skin["vfx"],
                        TB.ramp_color(skin, int(d["row"])),
                        Vector3(sin(ang) * P_RING_R * 0.6, pos_y,
                                        cos(ang) * P_RING_R * 0.6),
                        Vector3(sin(ang) * rng.randf_range(4.0, 9.0),
                                rng.randf_range(3.0, 8.0),
                                cos(ang) * rng.randf_range(4.0, 9.0)))
        _shockwave(pos_y)

func _break_piece(style: String, c: Color, pos: Vector3, vel: Vector3) -> void:
        var m := _frag_mesh(style, c)
        var n := MeshInstance3D.new()
        n.mesh = m
        n.position = pos
        n.material_override = _frag_mat(c, style)
        frag_layer.add_child(n)
        var spin := Vector3(rng.randf_range(-9, 9), rng.randf_range(-9, 9),
                rng.randf_range(-9, 9))
        if style == "rubble":
                vel = vel * 0.6 + Vector3(0, 3.0, 0)
                spin = spin * 0.4
        elif style == "splash":
                vel = vel * 0.8 + Vector3(0, 5.0, 0)
        elif style == "splinter":
                spin = Vector3(rng.randf_range(-14, 14),
                        rng.randf_range(-3, 3), rng.randf_range(-14, 14))
        _frags.append({"n": n, "vel": vel, "spin": spin, "t": 0.0,
                "life": 1.1 if style != "splash" else 0.85})

func _frag_mesh(style: String, c: Color) -> Mesh:
        var key := style
        var bm := BoxMesh.new()
        match style:
                "shard":
                        bm.size = Vector3(rng.randf_range(1.2, 2.4), 0.28,
                                rng.randf_range(1.2, 2.4))
                "rubble":
                        bm.size = Vector3(rng.randf_range(1.0, 2.2),
                                rng.randf_range(0.8, 1.6),
                                rng.randf_range(1.0, 2.2))
                "splinter":
                        bm.size = Vector3(rng.randf_range(0.5, 0.9),
                                0.34, rng.randf_range(2.6, 4.4))
                _:
                        # splash droplets + the classic wedge
                        bm.size = Vector3(rng.randf_range(0.5, 1.1),
                                rng.randf_range(0.5, 1.1),
                                rng.randf_range(0.5, 1.1))
        return bm

func _shockwave(pos_y: float) -> void:
        var n := MeshInstance3D.new()
        var tor := TorusMesh.new()
        tor.inner_radius = R_OUT * 0.55
        tor.outer_radius = R_OUT * 0.62
        n.mesh = tor
        n.position = Vector3(0, pos_y, 0)
        var m := StandardMaterial3D.new()
        m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        m.albedo_color = Color(1, 1, 1, 0.65)
        n.material_override = m
        frag_layer.add_child(n)
        _waves.append({"n": n, "t": 0.0})

func _frag_mat(c: Color, style: String) -> StandardMaterial3D:
        var key := style + str(c)
        if _frag_cache.has(key):
                return _frag_cache[key]
        var m := StandardMaterial3D.new()
        m.albedo_color = c
        m.roughness = float(TB.break_skin()["rough"])
        m.metallic = float(TB.break_skin()["metal"])
        if float(TB.break_skin()["alpha"]) < 1.0:
                m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
                m.albedo_color.a = float(TB.break_skin()["alpha"])
        _frag_cache[key] = m
        return m

func _frags_tick(delta: float) -> void:
        for f in _frags:
                if not is_instance_valid(f["n"]):
                        continue
                f["t"] += delta
                var n: MeshInstance3D = f["n"]
                f["vel"] += Vector3(0, -30.0, 0) * delta
                n.position += f["vel"] * delta
                n.rotation += f["spin"] * delta
                var k: float = 1.0 - f["t"] / float(f["life"])
                n.scale = Vector3.ONE * clampf(k, 0.05, 1.0)
                if f["t"] >= float(f["life"]):
                        n.queue_free()
        _frags = _frags.filter(func(f): return is_instance_valid(f["n"]) \
                        and f["t"] < float(f["life"]))
        for w in _waves:
                if not is_instance_valid(w["n"]):
                        continue
                w["t"] += delta
                var n: MeshInstance3D = w["n"]
                var k: float = w["t"] / 0.45
                n.scale = Vector3(1.0 + k * 2.6, 1.0 + k * 0.4,
                                1.0 + k * 2.6)
                (n.material_override as StandardMaterial3D) \
                                .albedo_color.a = 0.65 * (1.0 - k)
                if k >= 1.0:
                        n.queue_free()
        _waves = _waves.filter(func(w): return is_instance_valid(w["n"]) \
                        and w["t"] < 0.45)
        # the clouds drift (the living world, both modes)
        for cld in _clouds:
                var n2: Node3D = cld["n"]
                n2.position.x += float(cld["spd"]) * delta
                if n2.position.x > 180.0:
                        n2.position.x = -180.0

func _clear_frags() -> void:
        for f in _frags:
                if is_instance_valid(f["n"]):
                        f["n"].queue_free()
        _frags.clear()
        for w in _waves:
                if is_instance_valid(w["n"]):
                        w["n"].queue_free()
        _waves.clear()

# ================================================================ the skins

func _apply_tower_skin() -> void:
        var skin := TB.break_skin()
        if _tower_mat != null:
                _tower_mat.roughness = float(skin["rough"])
                _tower_mat.metallic = float(skin["metal"])
                if float(skin["alpha"]) < 1.0:
                        _tower_mat.transparency = \
                                        BaseMaterial3D.TRANSPARENCY_ALPHA
                else:
                        _tower_mat.transparency = \
                                        BaseMaterial3D.TRANSPARENCY_DISABLED
        if pole != null and is_instance_valid(pole):
                var pm: StandardMaterial3D = pole.material_override
                pm.albedo_color = Color(String(skin["pole"]))
        _apply_ball_skin()
        if mode == "ball":
                for r in discs:
                        var d: Dictionary = discs[r]
                        if d["node"] != null and is_instance_valid(d["node"]):
                                (d["node"] as MeshInstance3D).mesh = \
                                        _disc_mesh(d["data"],
                                        TB.ramp_color(skin, int(r)))
        else:
                for r in rings:
                        var d2: Dictionary = rings[r]
                        if d2["node"] != null \
                                        and is_instance_valid(d2["node"]):
                                (d2["node"] as MeshInstance3D).mesh = \
                                        _ring_mesh(d2["data"], int(r))

# ================================================================ the shop

func _shop_open() -> void:
        if over:
                return
        Jukebox.sfx("tb_click", -6.0)
        var sheet := sheet_push(0.0, "shop")
        var t := Arc.label("TOWER BALL SHOP", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport().get_visible_rect().size
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.52, 320.0, 640.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        box.add_child(Arc.fit_label("BALL SKINS", 24, Arc.HOT, 560))
        for s in TB.BALL_SKINS:
                box.add_child(_skin_row("skin_ball", s,
                        func(): _apply_ball_skin()))
        box.add_child(Arc.fit_label("BREAKABLE SKINS", 24, Arc.HOT, 560))
        for s in TB.BREAK_SKINS:
                box.add_child(_skin_row("skin_break", s,
                        func():
                                _apply_tower_skin()
                                _rebuild_world_look()))
        var back := Arc.button("CLOSE", Vector2(560, 72), 26, Arc.GOOD,
                func(): sheet_pop())
        sheet.add_child(back)
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

## the skin's own MATERIAL laws: the tower material's roughness/metallic/
## alpha ARE the design (glass IS glass, metal IS metal)
func _rebuild_world_look() -> void:
        if mode == "ball":
                _build_pole()
                _make_victory_disc()
                for r in discs:
                        var d: Dictionary = discs[r]
                        if d["node"] != null \
                                        and is_instance_valid(d["node"]):
                                (d["node"] as MeshInstance3D).mesh = \
                                        _disc_mesh(d["data"],
                                        TB.ramp_color(TB.break_skin(),
                                        int(r)))
        else:
                _build_pole_p()
                for r in rings:
                        var d2: Dictionary = rings[r]
                        if d2["node"] != null \
                                        and is_instance_valid(d2["node"]):
                                (d2["node"] as MeshInstance3D).mesh = \
                                        _ring_mesh(d2["data"], int(r))

## THE SHELF LAWS (the goldminer shape): the ON row, buys refresh in
## place, the shop SELLS and the game APPLIES live.
func _skin_row(cat: String, s: Dictionary, apply: Callable) -> Control:
        var id := String(s["id"])
        var price := int(s["price"])
        var owned := Box.item_owned(game_id, cat, id) or price == 0
        var on: bool = Box.item_on(game_id, cat) == id \
                or (price == 0 and Box.item_on(game_id, cat) == "")
        if on:
                return Arc.on_row("%s  (ON)" % s["name"])
        if owned:
                return Arc.button(s["name"], Vector2(560, 60), 22, Arc.ACCENT,
                        func():
                                Box.equip_item(game_id, cat, id)
                                Jukebox.sfx("tb_click", -4.0)
                                apply.call()
                                _shop_reopen("shop"))
        var b := Arc.coin_button("%s  %d" % [s["name"], price],
                        Vector2(560, 64), 22, Arc.ACCENT, func():
                                if Box.buy_item(game_id, cat, id, price):
                                        Jukebox.sfx("coin", -4.0)
                                        Box.equip_item(game_id, cat, id)
                                        apply.call()
                                _shop_reopen("shop"))
        if Box.coins() < price:
                b.disabled = true
        return b

func _shop_reopen(which: String) -> void:
        sheet_pop()
        if which == "shop":
                _shop_open()
        else:
                _optionals_open()

# ================================================================ the cards

func _mode_card(kind: String, selected: bool) -> Button:
        var b := Button.new()
        b.custom_minimum_size = Vector2(240, 190)
        var sb := Arc.panel_style(Arc.ACCENT if selected else Arc.CARD, 20, 10)
        if not selected:
                sb.set_border_width_all(3)
                sb.border_color = Color(0, 0, 0, 0.12)
        b.add_theme_stylebox_override("normal", sb)
        var sbp := sb.duplicate() as StyleBoxFlat
        sbp.bg_color = sbp.bg_color.darkened(0.06)
        b.add_theme_stylebox_override("pressed", sbp)
        var vb := VBoxContainer.new()
        vb.set_anchors_preset(Control.PRESET_FULL_RECT)
        vb.alignment = BoxContainer.ALIGNMENT_CENTER
        vb.add_theme_constant_override("separation", 10)
        vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(vb)
        var glyph := Control.new()
        glyph.custom_minimum_size = Vector2(96, 74)
        glyph.draw.connect(func():
                if kind == "ball":
                        # the helix: three arcs + the ball above
                        for i in 3:
                                var y := 56.0 - float(i) * 20.0
                                glyph.draw_arc(Vector2(48, y), 30.0,
                                        0.35, PI - 0.35, 24,
                                        Color(0.3, 0.2, 0.1, 0.8), 6.0)
                        glyph.draw_circle(Vector2(48, 10), 11.0,
                                TB.ball_skin()["color"])
                else:
                        # the tower rings + the orbiting ball
                        for i in 3:
                                var y := 8.0 + float(i) * 16.0
                                glyph.draw_rect(Rect2(14, y, 68, 9),
                                        Color(0.3, 0.2, 0.1, 0.55))
                        glyph.draw_circle(Vector2(48, 52), 7.0,
                                TB.ball_skin()["color"]))
        glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.add_child(glyph)
        var lbl := Arc.label("BALL" if kind == "ball" else "PLATFORM", 26,
                Arc.INK, true)
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.add_child(lbl)
        return b

func _pos_card(kind: String, selected: bool) -> Button:
        var b := Button.new()
        b.custom_minimum_size = Vector2(190, 190)
        var sb := Arc.panel_style(Arc.ACCENT if selected else Arc.CARD, 20, 10)
        if not selected:
                sb.set_border_width_all(3)
                sb.border_color = Color(0, 0, 0, 0.12)
        b.add_theme_stylebox_override("normal", sb)
        var sbp := sb.duplicate() as StyleBoxFlat
        sbp.bg_color = sbp.bg_color.darkened(0.06)
        b.add_theme_stylebox_override("pressed", sbp)
        var vb := VBoxContainer.new()
        vb.set_anchors_preset(Control.PRESET_FULL_RECT)
        vb.alignment = BoxContainer.ALIGNMENT_CENTER
        vb.add_theme_constant_override("separation", 10)
        vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(vb)
        var glyph := Control.new()
        glyph.custom_minimum_size = Vector2(96, 74)
        glyph.draw.connect(func():
                var phone := Color(0.25, 0.16, 0.08, 0.85)
                if kind == "vertical":
                        glyph.draw_rect(Rect2(30, 4, 36, 66), phone, false, 5.0)
                else:
                        glyph.draw_rect(Rect2(8, 24, 80, 30), phone, false, 5.0))
        glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.add_child(glyph)
        var lbl := Arc.label("VERTICAL" if kind == "vertical" \
                else "HORIZONTAL", 20, Arc.INK, true)
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.add_child(lbl)
        return b

# ================================================================ input
# THE OWNER'S LAW: controls in 3D are not different than 2D on the box
# side - TouchKit + the box key translation feed this game exactly like
# a 2D one. r2 adds THE GAMEPAD: X dives/launches, the stick/d-pad's
# left-right rotates the platform tower.

func _goga_input(event: InputEvent) -> void:
        if event is InputEventKey:
                var k := (event as InputEventKey).keycode
                var p := (event as InputEventKey).pressed
                match k:
                        KEY_SPACE, KEY_DOWN:
                                key_hold = p
                        KEY_LEFT:
                                if p: keys["left"] = true
                                else: keys.erase("left")
                        KEY_RIGHT:
                                if p: keys["right"] = true
                                else: keys.erase("right")
        elif event is InputEventJoypadButton:
                var jb := (event as InputEventJoypadButton).button_index
                var jp := (event as InputEventJoypadButton).pressed
                if jb == JOY_BUTTON_A:
                        pad_hold = jp
                        if jp and mode == "platform" and phase == "serve":
                                _p_launch()
                elif jb == JOY_BUTTON_X:
                        pad_hold = jp
        elif event is InputEventJoypadMotion:
                var axis := (event as InputEventJoypadMotion).axis
                var val := (event as InputEventJoypadMotion).axis_value
                if axis == JOY_AXIS_LEFT_X:
                        var dead := 0.25
                        if val < -dead:
                                keys["left"] = true
                                keys.erase("right")
                        elif val > dead:
                                keys["right"] = true
                                keys.erase("left")
                        else:
                                keys.erase("left")
                                keys.erase("right")
        elif event is InputEventMouseButton \
                        and (event as InputEventMouseButton).button_index \
                        == MOUSE_BUTTON_LEFT:
                holding = (event as InputEventMouseButton).pressed
        elif event is InputEventScreenDrag and mode == "platform" \
                        and phase == "run":
                # THE FINGER: the horizontal drag delta ROTATES THE TOWER
                # (the original's pointerRotationSensitivity: rad per px,
                # design px here)
                var dx: float = (event as InputEventScreenDrag).relative.x
                _rotate_tower(-dx * TB.NT_POINTER_ROT
                                * _design_px_per_screen_px())

func _design_px_per_screen_px() -> float:
        # the drag arrives in screen px; the sensitivity is design px
        var vp := get_viewport().get_visible_rect().size
        var win := DisplayServer.window_get_size()
        if win.x <= 0:
                return 1.0
        return vp.x / float(win.x)

func _goga_tick(delta: float) -> void:
        _frags_tick(delta)
        if mode == "ball":
                _ball_tick(delta)
        else:
                _platform_tick(delta)

func _on_press(_pos: Vector2) -> void:
        if mode == "platform":
                if phase == "serve":
                        _p_launch()
                return
        holding = true

func _on_release(_pos: Vector2) -> void:
        holding = false

## the platform run opens with the ball already bouncing - no serve phase
## in r2 (the original starts you falling immediately); kept for the
## gamepad X's launch call site
func _p_launch() -> void:
        pass


