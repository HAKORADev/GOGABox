extends GogaGame3D
## TOWER BALL (v041-2) - the box's first 3D game, and the helix-jump-like
## graduation the owner parked in FUTURE_GAMES.md ("THE STACK BALL NOTE"):
## ONE tower law, TWO modes -
##   BALL     the classic stack-ball smash: hold to dive, shatter the disc
##            under you, never touch black (fire forgives), reach the
##            victory disc through 150..900 rows.
##   PLATFORM the neon-tower take, round-shaped: ride the bouncing ball on
##            a platform you steer, break the tower row by row, never let
##            the ball fall.
## The owner's contract (verbatim laws in the brainstorm sheet):
## rounds with ends (150-300-450-600-750-900 ladder), lives 3 (a crash
## costs one, the round continues; no lives ends the run), each win +1
## score, score bonus /5, a GOGACoin after every 6 rounds in a legal area
## that CAN be missed, skins for the ball and the breakables (5 + 5,
## first default), the fire ball after a long streak, touch + mouse/keys,
## vertical AND horizontal, "tap anywhere to start" through the universal
## overlay, the mode selection AS the optionals menu. The ball is
## BALLDOZER (the eyes ride every world); the game is geometrics - no
## words inside the world, no lore card.
## The 3D seat: world units = 10 design px; one DirectionalLight3D with
## soft shadows + a gentle sky; the tower draws ~1 mesh per row (vertex
## colored, one shared material) so a 900-row round is cheap.

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
const CAM_FOV := 46.0
const CAM_TILT := 35.0         # degrees above the horizon

# ------------------------------------------------- platform mode geometry
const BH := 3.0                # block height
const BPITCH := 3.35           # row pitch
const GAPX := 0.55             # gap between blocks
const PBALL_R := 1.8
const PADDLE_H := 1.8
const WIN_ROWS := 30           # alive rows above the bottom
const COIN_WINDOW := 8         # the coin's row window (then it pops)

# ------------------------------------------------- state
var mode := "ball"             # "ball" | "platform"
var phase := "boot"            # boot|intro|optionals|transition|run|serve|won|over
var round_idx := 1
var round_len := 150
var lives := TB.LIVES
var rng := RandomNumberGenerator.new()

# world
var world: Node3D
var cam: Camera3D
var sun: DirectionalLight3D
var env: WorldEnvironment
var pole: MeshInstance3D
var ball_mesh: MeshInstance3D
var ball_face: Node3D
var fire_p: CPUParticles3D
var ball_mat: StandardMaterial3D
var frag_layer: Node3D

# ball mode live
var top_row := 0
var discs := {}                # row -> disc state
var rows_data := []            # per-row data (pregenerated at round build)
var by := 0.0                  # ball y
var bvy := 0.0
var holding := false
var key_hold := false
var cam_y := 0.0
var shake_t := 0.0
var victory_y := 0.0

# fire
var streak := 0
var fire_t := 0.0
var stun_t := 0.0             # the crash grace: no smash while it runs

# coin
var coin_row_idx := -1
var coin_seg := -1
var coin_node: Coin3D = null
var coin_window := 0           # platform mode: rows cleared when it must die

# platform mode live
var rows := {}                 # row -> row state
var bottom_row := 0
var tower_off := 0.0
var tower_slide := 0.0
var px := 0.0                  # paddle x
var ptx := 0.0                 # paddle target x
var pvx := 0.0                 # paddle velocity (for english)
var bvx := 0.0
var bvy2 := 0.0
var bx := 0.0
var bby := 0.0                 # platform ball y
var ball_speed := 50.0
var serve_t := 0.0
var fw := 80.0
var fh := 120.0
var cols := 8
var reach_y := 0.0
var paddle_y := 0.0
var kill_y := 0.0
var pad_w := 14.0
var cam_d := 60.0
var wpp := 0.1                 # world units per design px (input mapping)
var keys := {}                 # held arrows
var cleared_this_round := 0

# hud
var lives_lbl: Label
var streak_lbl: Label
var banner: Label

# fragments (shared pool)
var _frags: Array = []
var _frag_cache := {}

# ----------------------------------------------------------------- setup

func _goga_setup() -> void:
        rng.randomize()
        pause_end_run = true     # THE END LAW: the pause sheet banks the run
        lives_lbl = add_hud_chip("x3", "res://assets/ui/heart.png")
        streak_lbl = add_hud_chip("")
        add_hud_button("SHOP", func(): _shop_open())
        _goga_tk_ready()
        mode = String(Box.get_progress(game_id, "mode", "ball"))
        if mode != "ball" and mode != "platform":
                mode = "ball"
        _build_world()
        _build_round()           # the tower IS the intro scenery
        Jukebox.music("res://assets/audio/music/tb_theme.wav")
        # THE UNIVERSAL RELOAD: the host told us the picked position - the
        # flow skips the intro and the optionals and plays.
        if start_orientation != "":
                _start_run()
        else:
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
        sm.sky_top_color = Color(String(skin["sky_top"]))
        sm.sky_horizon_color = Color(String(skin["sky_bot"]))
        sm.ground_bottom_color = Color(String(skin["sky_bot"]))
        sm.ground_horizon_color = Color(String(skin["sky_bot"]))
        sm.sun_angle_max = 20.0
        sky.sky_material = sm
        e.sky = sky
        e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
        e.ambient_light_sky_contribution = 0.55
        e.ambient_light_energy = 1.0
        env.environment = e
        world.add_child(env)
        sun = DirectionalLight3D.new()
        sun.rotation_degrees = Vector3(-52, -28, 0)
        sun.light_energy = 1.15
        sun.light_color = Color(1.0, 0.96, 0.88)
        sun.shadow_enabled = true
        sun.directional_shadow_max_distance = 220.0
        sun.shadow_blur = 1.4
        world.add_child(sun)
        frag_layer = Node3D.new()
        world.add_child(frag_layer)
        _build_ball()
        _apply_sky(skin)

func _apply_sky(skin: Dictionary) -> void:
        var sm: ProceduralSkyMaterial = (env.environment.sky.sky_material
                        as ProceduralSkyMaterial)
        sm.sky_top_color = Color(String(skin["sky_top"]))
        sm.sky_horizon_color = Color(String(skin["sky_bot"]))
        sm.ground_bottom_color = Color(String(skin["sky_bot"]))
        sm.ground_horizon_color = Color(String(skin["sky_bot"]))

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
        ball_mat.albedo_color = TB.ball_color()
        ball_mat.roughness = 0.42
        ball_mat.metallic = 0.12
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
        fire_p = CPUParticles3D.new()
        fire_p.emitting = false
        fire_p.amount = 26
        fire_p.lifetime = 0.5
        fire_p.mesh = SphereMesh.new()
        (fire_p.mesh as SphereMesh).radius = BALL_R * 0.22
        (fire_p.mesh as SphereMesh).height = BALL_R * 0.44
        fire_p.direction = Vector3(0, 1, 0)
        fire_p.spread = 60.0
        fire_p.gravity = Vector3(0, 10, 0)
        fire_p.initial_velocity_min = 3.0
        fire_p.initial_velocity_max = 7.0
        fire_p.scale_amount_min = 0.6
        fire_p.scale_amount_max = 1.2
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

func _apply_ball_skin() -> void:
        ball_mat.albedo_color = TB.ball_color()

# ----------------------------------------------------------------- intro

var _intro_ui: Control = null

func _build_intro() -> void:
        phase = "intro"
        _intro_ui = Control.new()
        _intro_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
        _intro_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _overlay_root_ref().add_child(_intro_ui)
        var cc := CenterContainer.new()
        cc.set_anchors_preset(Control.PRESET_FULL_RECT)
        cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _intro_ui.add_child(cc)
        var vb := VBoxContainer.new()
        vb.add_theme_constant_override("separation", 22)
        vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
        cc.add_child(vb)
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

func _intro_start() -> void:
        Jukebox.sfx("tb_click", -6.0)
        if _intro_ui != null and is_instance_valid(_intro_ui):
                _intro_ui.queue_free()
                _intro_ui = null
        _optionals_open()

# ------------------------------------------------------------ optionals
# THE OWNER: "make the mode selection as the optionals menu" - the mode
# cards + the position cards (the snake ask design) + PLAY live here.

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
        lives = TB.LIVES
        round_idx = 1
        set_score(0)
        _lives_hud()
        _build_round()
        _transition()

func _lives_hud() -> void:
        if lives_lbl != null:
                lives_lbl.text = "x%d" % lives

# ----------------------------------------------------------------- rounds

func _build_round() -> void:
        round_len = TB.round_length(round_idx)
        if mode == "platform":
                _frame_field()          # cols must exist before the row data
        rows_data.clear()
        for i in round_len:
                if mode == "ball":
                        rows_data.append(TB.gen_row(i, round_len, rng,
                                        round_idx))
                else:
                        rows_data.append(TB.gen_blocks(i, cols, rng,
                                        round_idx, round_len))
        # the coin: the round AFTER every 6 wins carries one (the field
        # builds FIRST so the platform seat has its geometry)
        coin_row_idx = -1
        coin_seg = -1
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
                _build_platform_field()
                if TB.coin_due(score):
                        _spawn_air_coin()

func cols_placeholder() -> int:
        return cols

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
                                _serve_ball())

func _round_won() -> void:
        phase = "won"
        streak = 0
        fire_t = 0.0
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
        streak = 0
        fire_t = 0.0
        stun_t = 0.0
        victory_y = -float(round_len) * PITCH - 6.0
        _build_pole()
        _make_victory_disc()
        _ensure_discs()
        ball_mesh.visible = false     # the seat happens at the transition
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
        # fragments: the ring pops outward, each piece in its segment color
        var base := TB.ramp_color(TB.break_skin(), top_row)
        var skin := TB.break_skin()
        for i in 10:
                var ang := rng.randf_range(0.0, TAU)
                var seg_i := int(floor(fposmod(ang, TAU) / (TAU / float(count)))) % count
                var fc: Color = TB.BLACK if bool(black[seg_i]) \
                                else TB.ramp_color(skin, top_row)
                var rr := rng.randf_range(R_IN + 1.0, R_OUT - 1.0)
                _frag(fc, Vector3(sin(ang) * rr,
                                node.position.y + rng.randf_range(-0.6, 0.6),
                                cos(ang) * rr),
                        Vector3(sin(ang) * rng.randf_range(6.0, 15.0),
                                rng.randf_range(3.0, 11.0),
                                cos(ang) * rng.randf_range(6.0, 15.0)))
        node.queue_free()
        discs.erase(top_row)
        # the disc gave way on EVERY path (the crash's quiet tear included)
        # - only the STREAK and the sfx wait for an honest smash
        top_row += 1
        if not quiet:
                Jukebox.sfx("tb_break", -4.0, rng.randf_range(0.92, 1.1))
                streak += 1
                if fire_t <= 0.0 and streak >= TB.FIRE_AT:
                        _ignite_fire()
        _ensure_discs()

func _ignite_fire() -> void:
        fire_t = TB.FIRE_TIME
        streak = 0
        fire_p.emitting = true
        Jukebox.sfx("tb_fire", -2.0)
        achievement_count("fires", 1)

func _ball_tick(delta: float) -> void:
        if phase != "run":
                return
        stun_t = maxf(0.0, stun_t - delta)
        var want_hold: bool = (holding or key_hold) and stun_t <= 0.0
        var smashing := want_hold
        if smashing:
                bvy = SMASH_V * (FIRE_SMASH_MULT if fire_t > 0.0 else 1.0)
        else:
                bvy += GRAV * delta
                if bvy < MAX_FALL:
                        bvy = MAX_FALL
        by += bvy * delta
        # discs spin
        for r in discs:
                var d: Dictionary = discs[r]
                d["rot"] = float(d["rot"]) + float(d["data"]["rot"]) * delta
                if d["node"] != null and is_instance_valid(d["node"]):
                        (d["node"] as Node3D).rotation.y = float(d["rot"])
        # contact with the top disc (only while a tower remains - once the
        # last disc is gone the ball free-falls onto the victory disc:
        # a ghost contact plane up here would snap-catch it forever and
        # the round could never complete)
        var top_surface := -float(top_row) * PITCH + THICK * 0.5
        if top_row < round_len and bvy < 0.0 and by - BALL_R <= top_surface:
                by = top_surface + BALL_R
                var d: Dictionary = discs.get(top_row, {})
                var black_seg := false
                if not d.is_empty():
                        var data: Dictionary = d["data"]
                        var seg := TB.seg_under_ball(int(data["count"]),
                                        float(d["rot"]))
                        black_seg = bool(data["black"][seg])
                if smashing:
                        if black_seg and fire_t <= 0.0:
                                _crash(top_surface)
                        else:
                                _shatter_top()
                else:
                        # the bounce: the streak breaks, the ball floats up
                        bvy = BOUNCE_V
                        if streak > 0:
                                streak = 0
                        Jukebox.sfx("tb_bounce", -6.0,
                                        rng.randf_range(0.9, 1.12))
        # the victory disc
        if top_row >= round_len and by - BALL_R <= victory_y + THICK * 0.5:
                by = victory_y + THICK * 0.5 + BALL_R
                bvy = BOUNCE_V
                _round_won()
        # the ball's world seat: the mesh rides the physics every tick
        ball_mesh.position = Vector3(0, by, 0)
        # fire clock
        if fire_t > 0.0:
                fire_t -= delta
                if fire_t <= 0.0:
                        fire_p.emitting = false
        _hud_tick()
        _cam_follow(delta)

func _crash(surface_y: float) -> void:
        lives -= 1
        _lives_hud()
        streak = 0
        shake_t = 0.5
        Jukebox.sfx("tb_crash", -2.0)
        _frag(TB.BLACK, Vector3(0, surface_y + 1.0, 0),
                Vector3(0, 9.0, 0))
        for i in 8:
                var ang := rng.randf_range(0.0, TAU)
                _frag(TB.BLACK, Vector3(sin(ang) * 4.0, surface_y + 1.2,
                                cos(ang) * 4.0),
                        Vector3(sin(ang) * rng.randf_range(5.0, 11.0),
                                rng.randf_range(4.0, 9.0),
                                cos(ang) * rng.randf_range(5.0, 11.0)))
        if lives <= 0:
                fire_p.emitting = false
                _run_over()
                return
        # THE GRACE: the black segment gave way under the crash - the ball
        # drifts through the broken disc, stunned (no smash) for a beat.
        # Without it a held dive would chain-crash all three lives in a
        # second with no chance to react.
        _shatter_top(true)
        bvy = SMASH_V * 0.35
        stun_t = 0.65

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

func _cam_dist() -> float:
        var vp := get_viewport().get_visible_rect().size
        var aspect := vp.x / maxf(1.0, vp.y)
        var tanv := tan(deg_to_rad(CAM_FOV) * 0.5)
        var tanh_ := tanv * aspect
        var d := R_OUT / maxf(0.02, tanh_ * 0.66)
        # the floor keeps the STACK visible on wide windows (a close camera
        # hides the discs under the top one)
        return clampf(d, 54.0, 120.0)

func _hud_tick() -> void:
        if streak_lbl == null:
                return
        if fire_t > 0.0:
                streak_lbl.text = "FIRE"
        elif streak > 1:
                streak_lbl.text = "x%d" % streak
        else:
                streak_lbl.text = ""

# ============================================================ PLATFORM MODE
# the neon-tower take, round-shaped: the platform is yours, the ball
# bounces forever, the tower breaks row by row, the rows never stop.

func _frame_field() -> void:
        var vp := get_viewport().get_visible_rect().size
        var aspect := vp.x / maxf(1.0, vp.y)
        fh = clampf((vp.y - 300.0) / 10.0, 60.0, 170.0)
        fw = clampf(fh * aspect * 0.92, 55.0, 200.0)
        cols = clampi(int((fw - 4.0) / 12.0), 6, 14)
        reach_y = -fh * 0.04
        paddle_y = -fh * 0.42
        kill_y = paddle_y - 5.0
        cam_d = (fh * 0.56) / tan(deg_to_rad(24.0))
        wpp = (fh * 1.14) / vp.y
        ball_speed = maxf(46.0, fh * 0.40)
        pad_w = clampf(fw * 0.19, 12.0, 26.0)

func _build_platform_field() -> void:
        for k in rows:
                var d: Dictionary = rows[k]
                if d["node"] != null and is_instance_valid(d["node"]):
                        d["node"].queue_free()
        rows.clear()
        _clear_frags()
        bottom_row = 0
        tower_off = 0.0
        tower_slide = 0.0
        cleared_this_round = 0
        streak = 0
        fire_t = 0.0
        px = 0.0
        ptx = 0.0
        # platform mode: no pole - the tower is the field's own geometry
        # the walls: two slim rails framing the field
        for side in [-1.0, 1.0]:
                var wall := MeshInstance3D.new()
                var bm := BoxMesh.new()
                bm.size = Vector3(1.8, fh, 2.6)
                wall.mesh = bm
                wall.position = Vector3(side * (fw * 0.5 + 0.9),
                                paddle_y + fh * 0.5, 0)
                var wm := StandardMaterial3D.new()
                wm.albedo_color = Color(String(TB.break_skin()["pole"]))
                wm.albedo_color = wm.albedo_color.darkened(0.25)
                wm.roughness = 0.6
                wall.material_override = wm
                world.add_child(wall)
        _build_paddle()
        _ensure_rows()
        ball_mesh.visible = false

var paddle: MeshInstance3D = null

func _build_paddle() -> void:
        if paddle != null and is_instance_valid(paddle):
                paddle.queue_free()
        paddle = MeshInstance3D.new()
        var bm := BoxMesh.new()
        bm.size = Vector3(pad_w, PADDLE_H, 4.2)
        paddle.mesh = bm
        var pm := StandardMaterial3D.new()
        pm.albedo_color = TB.ramp_color(TB.break_skin(), 0).darkened(0.18)
        pm.roughness = 0.45
        paddle.material_override = pm
        paddle.position = Vector3(0, paddle_y, 0)
        world.add_child(paddle)

## the alive window rides the BOTTOM (cleared rows die, new rows bloom
## at the window's top - the tower never runs out)
func _ensure_rows() -> void:
        for r in range(bottom_row, mini(round_len, bottom_row + WIN_ROWS)):
                if not rows.has(r):
                        rows[r] = _make_block_row(r)
        var dead: Array = []
        for r in rows:
                if int(r) < bottom_row:
                        dead.append(r)
        for r in dead:
                var d: Dictionary = rows[r]
                if d["node"] != null and is_instance_valid(d["node"]):
                        d["node"].queue_free()
                rows.erase(r)

func _make_block_row(row: int) -> Dictionary:
        # THE PRESENCE LAW: breaks[i] = the block STANDS (all born standing,
        # hard ones included); rows_data[row] (the birth data) says whether
        # a standing block is breakable (true) or HARD (false).
        var breaks: Array = []
        for i in cols:
                breaks.append(true)
        var node := MeshInstance3D.new()
        node.mesh = _row_mesh(breaks, rows_data[row], row)
        node.material_override = _tower_material()
        node.position.y = _row_y(row) + tower_off
        world.add_child(node)
        return {"row": row, "breaks": breaks, "node": node}

func _row_y(row: int) -> float:
        return reach_y + BH * 0.5 + float(row) * BPITCH

## one row = ONE ArrayMesh (the same draw-call law as the discs).
## breaks[i] TRUE = the block stands; data[i] (the row's birth data)
## says whether it is breakable (true) or HARD (false).
func _row_mesh(breaks: Array, data: Array, row: int) -> ArrayMesh:
        var st := SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        var color := TB.ramp_color(TB.break_skin(), row)
        var usable := fw - 4.0
        var bw := (usable - float(cols - 1) * GAPX) / float(cols)
        var x0 := -usable * 0.5
        for i in cols:
                if not bool(breaks[i]):
                        continue
                var c: Color = color if bool(data[i]) else TB.BLACK
                var cx := x0 + float(i) * (bw + GAPX) + bw * 0.5
                _box(st, Vector3(cx, 0, 0), Vector3(bw, BH, 4.2), c)
        return st.commit()

## an axis-aligned box into the surface (6 faces, 24 verts)
func _box(st: SurfaceTool, c: Vector3, s: Vector3, col: Color) -> void:
        var hx := s.x * 0.5
        var hy := s.y * 0.5
        var hz := s.z * 0.5
        var faces := [
                [Vector3(-hx, hy, -hz), Vector3(hx, hy, -hz), Vector3(hx, hy, hz), Vector3(-hx, hy, hz), Vector3.UP],
                [Vector3(-hx, -hy, -hz), Vector3(-hx, -hy, hz), Vector3(hx, -hy, hz), Vector3(hx, -hy, -hz), Vector3.DOWN],
                [Vector3(-hx, -hy, hz), Vector3(-hx, hy, hz), Vector3(hx, hy, hz), Vector3(hx, -hy, hz), Vector3(0, 0, 1)],
                [Vector3(hx, -hy, -hz), Vector3(hx, hy, -hz), Vector3(-hx, hy, -hz), Vector3(-hx, -hy, -hz), Vector3(0, 0, -1)],
                [Vector3(hx, -hy, hz), Vector3(hx, hy, hz), Vector3(hx, hy, -hz), Vector3(hx, -hy, -hz), Vector3(1, 0, 0)],
                [Vector3(-hx, -hy, -hz), Vector3(-hx, hy, -hz), Vector3(-hx, hy, hz), Vector3(-hx, -hy, hz), Vector3(-1, 0, 0)],
        ]
        for f in faces:
                var n: Vector3 = f[4]
                _quad(st, c + f[0], c + f[1], c + f[2], c + f[3], n, col)

func _serve_ball() -> void:
        phase = "serve"
        serve_t = 1.0
        bx = px
        bby = paddle_y + PADDLE_H * 0.5 + PBALL_R
        bvx = 0.0
        bvy2 = 0.0
        streak = 0
        ball_mesh.visible = true

func _launch_ball() -> void:
        var ang := TB.serve_angle(rng)
        bvx = sin(ang) * ball_speed
        bvy2 = cos(ang) * ball_speed
        phase = "run"
        Jukebox.sfx("tb_serve", -6.0)

func _platform_tick(delta: float) -> void:
        # the paddle: keys ride the target, the drag rides the target,
        # the mouse rides the target - the paddle eases toward it
        var pvx_now := 0.0
        if keys.has("left"):
                ptx -= fw * 1.7 * delta
                pvx_now = -fw * 1.7
        if keys.has("right"):
                ptx += fw * 1.7 * delta
                pvx_now = fw * 1.7
        ptx = clampf(ptx, -fw * 0.5 + pad_w * 0.5 + 1.0,
                        fw * 0.5 - pad_w * 0.5 - 1.0)
        var old_px := px
        px = lerpf(px, ptx, 1.0 - exp(-16.0 * delta))
        pvx = (px - old_px) / maxf(0.0001, delta) * 0.25 + pvx_now * 0.1
        if paddle != null:
                paddle.position.x = px
        if phase == "serve":
                serve_t -= delta
                bx = px
                bby = paddle_y + PADDLE_H * 0.5 + PBALL_R
                if serve_t <= 0.0:
                        _launch_ball()
        elif phase == "run":
                _ball_physics(delta)
        _platform_ball_visual()
        if tower_slide > 0.0:
                tower_slide = maxf(0.0, tower_slide - delta)
                var k := tower_slide / 0.12
                tower_off = BPITCH * k
                for r in rows:
                        var d: Dictionary = rows[r]
                        if d["node"] != null and is_instance_valid(d["node"]):
                                (d["node"] as Node3D).position.y = \
                                                _row_y(int(r)) + tower_off
        if fire_t > 0.0:
                fire_t -= delta
                if fire_t <= 0.0:
                        fire_p.emitting = false
        _coin_air_tick(delta)
        _hud_tick()
        _platform_cam(delta)

func _platform_ball_visual() -> void:
        ball_mesh.position = Vector3(bx, bby, 0)
        ball_face.rotation.y = 0.0
        var sm: SphereMesh = ball_mesh.mesh
        sm.radius = PBALL_R
        sm.height = PBALL_R * 2.0

func _ball_physics(delta: float) -> void:
        # substep the flight so a fast ball never tunnels a block
        var travel := Vector2(bvx, bvy2) * delta
        var steps := maxi(1, int(ceil(travel.length() / 0.9)))
        for i in steps:
                var dt := delta / float(steps)
                bx += bvx * dt
                bby += bvy2 * dt
                _ball_step(dt)
                if phase != "run":
                        return

func _ball_step(dt: float) -> void:
        # walls
        if bx > fw * 0.5 - PBALL_R and bvx > 0.0:
                bx = fw * 0.5 - PBALL_R
                bvx = -bvx
                Jukebox.sfx("tb_bounce", -14.0, 1.3)
        elif bx < -fw * 0.5 + PBALL_R and bvx < 0.0:
                bx = -fw * 0.5 + PBALL_R
                bvx = -bvx
                Jukebox.sfx("tb_bounce", -14.0, 1.3)
        # a soft ceiling high above the window (never reached in play)
        var ceil_y := reach_y + float(WIN_ROWS) * BPITCH + 8.0
        if bby > ceil_y and bvy2 > 0.0:
                bvy2 = -bvy2
        # blocks (the bottom row's band, then any row the ball is inside)
        _ball_vs_rows()
        if phase != "run":
                return
        # the paddle
        var pad_top := paddle_y + PADDLE_H * 0.5
        if bvy2 < 0.0 and bby - PBALL_R <= pad_top \
                        and bby - PBALL_R >= pad_top - 2.2 \
                        and absf(bx - px) <= pad_w * 0.5 + PBALL_R * 0.7:
                var off := (bx - px) / (pad_w * 0.5)
                var ang := TB.bounce_angle(off)
                bvx = sin(ang) * ball_speed + pvx * 0.22
                bvy2 = cos(ang) * ball_speed
                # renormalize + keep the ball climbing honestly
                var v := Vector2(bvx, bvy2)
                if v.length() < ball_speed * 0.6:
                        v = v.normalized() * ball_speed
                bvx = v.x
                bvy2 = maxf(v.y, ball_speed * 0.38)
                bby = pad_top + PBALL_R
                if streak > 0:
                        streak = 0
                Jukebox.sfx("tb_bounce", -6.0, rng.randf_range(0.9, 1.12))
        # the fall
        if bby - PBALL_R < kill_y:
                _p_crash()

func _ball_vs_rows() -> void:
        for r in rows:
                var d: Dictionary = rows[r]
                var breaks: Array = d["breaks"]
                var row_y: float = (d["node"] as Node3D).position.y
                var half_w := (fw - 4.0 - float(cols - 1) * GAPX) / float(cols)
                var usable := fw - 4.0
                var x0 := -usable * 0.5
                for i in cols:
                        if not bool(breaks[i]):
                                continue   # already broken - no block there
                        var bx0 := x0 + float(i) * (half_w + GAPX)
                        var cx := clampf(bx, bx0, bx0 + half_w)
                        var cy := clampf(bby, row_y - BH * 0.5,
                                        row_y + BH * 0.5)
                        var dx := bx - cx
                        var dy := bby - cy
                        var d2 := dx * dx + dy * dy
                        if d2 > PBALL_R * PBALL_R:
                                continue
                        _hit_block(int(r), i, d, dx, dy)
                        return

func _hit_block(row: int, i: int, d: Dictionary, dx: float, dy: float) -> void:
        var breaks: Array = d["breaks"]
        var node: Node3D = d["node"]
        var hard := false
        var data: Array = rows_data[row]
        if not bool(data[i]):
                hard = true
        if hard and fire_t <= 0.0:
                # the bounce: reflect on the shallower axis, nothing breaks
                if absf(dx) > absf(dy):
                        bvx = absf(bvx) * (1.0 if dx > 0.0 else -1.0)
                else:
                        bvy2 = absf(bvy2) * (1.0 if dy > 0.0 else -1.0)
                Jukebox.sfx("tb_bounce", -10.0, 0.8)
                return
        breaks[i] = false
        _rebuild_row(row, d)
        streak += 1
        if fire_t <= 0.0 and streak >= TB.FIRE_AT:
                _ignite_fire()
        var color: Color = TB.BLACK if hard \
                        else TB.ramp_color(TB.break_skin(), row)
        var usable := fw - 4.0
        var bw := (usable - float(cols - 1) * GAPX) / float(cols)
        var x0 := -usable * 0.5
        var bcx := x0 + float(i) * (bw + GAPX) + bw * 0.5
        for k in 4:
                _frag(color, Vector3(bcx + rng.randf_range(-bw * 0.3, bw * 0.3),
                                node.position.y + rng.randf_range(-1.0, 1.0), 0),
                        Vector3(rng.randf_range(-6.0, 6.0),
                                rng.randf_range(2.0, 8.0),
                                rng.randf_range(-3.0, 3.0)))
        Jukebox.sfx("tb_block", -4.0, rng.randf_range(0.92, 1.1))
        # the reflect: the ball leaves the block on the shallower axis
        if absf(dx) > absf(dy):
                bvx = absf(bvx) * (1.0 if dx > 0.0 else -1.0)
        else:
                bvy2 = absf(bvy2) * (1.0 if dy > 0.0 else -1.0)
        # the collapse: every BREAKABLE gone -> the row crumbles, the
        # tower slides down one row (the next row enters reach); the
        # hard blocks are the row's nails - they give way with it
        var left := 0
        for j in cols:
                if bool(breaks[j]) and bool(data[j]):
                        left += 1
        if left == 0:
                _collapse_row(row, d)

func _rebuild_row(row: int, d: Dictionary) -> void:
        var node: MeshInstance3D = d["node"]
        node.mesh = _row_mesh(d["breaks"], rows_data[row], row)

func _collapse_row(row: int, d: Dictionary) -> void:
        # the hard blocks (still present) crumble away as debris
        var breaks: Array = d["breaks"]
        var data: Array = rows_data[row]
        var node: Node3D = d["node"]
        var usable := fw - 4.0
        var bw := (usable - float(cols - 1) * GAPX) / float(cols)
        var x0 := -usable * 0.5
        for i in cols:
                if not bool(breaks[i]) or bool(data[i]):
                        continue   # gone already, or a breakable (paid for)
                var bcx := x0 + float(i) * (bw + GAPX) + bw * 0.5
                for k in 3:
                        _frag(TB.BLACK, Vector3(bcx, node.position.y, 0),
                                Vector3(rng.randf_range(-4.0, 4.0),
                                        rng.randf_range(1.0, 5.0),
                                        rng.randf_range(-2.0, 2.0)))
        node.queue_free()
        rows.erase(row)
        bottom_row = maxi(bottom_row, row + 1)
        cleared_this_round += 1
        tower_slide = 0.12
        Jukebox.sfx("tb_collapse", -8.0)
        # the coin's window: rows cleared past its grace -> missed
        if coin_node != null and is_instance_valid(coin_node) \
                        and cleared_this_round > coin_window:
                Jukebox.sfx("tb_miss", -8.0)
                coin_node.queue_free()
                coin_node = null
        _ensure_rows()
        if bottom_row >= round_len:
                _round_won()

func _p_crash() -> void:
        lives -= 1
        _lives_hud()
        streak = 0
        shake_t = 0.5
        Jukebox.sfx("tb_crash", -2.0)
        for k in 10:
                var ang := rng.randf_range(0.0, TAU)
                _frag(TB.ball_color(), Vector3(bx, bby, 0),
                        Vector3(sin(ang) * rng.randf_range(4.0, 10.0),
                                rng.randf_range(2.0, 8.0),
                                rng.randf_range(-2.0, 2.0)))
        if lives <= 0:
                fire_p.emitting = false
                ball_mesh.visible = false
                _run_over()
        else:
                _serve_ball()

func _platform_cam(delta: float) -> void:
        shake_t = maxf(0.0, shake_t - delta)
        var target := Vector3(0, 0, cam_d)
        if shake_t > 0.0:
                var s := shake_t * shake_t * 1.2
                target += Vector3(rng.randf_range(-s, s),
                                rng.randf_range(-s, s), 0)
        cam.position = target
        # the subtle tilt: the blocks' top faces catch the sun - the 3D
        # reads without ever hiding the play line
        cam.rotation = Vector3(-0.09, 0, 0)
        cam.fov = 48.0

## THE COIN (platform): floats in the open air between the paddle zone
## and the tower bottom - a legal X, one window, then it pops
func _spawn_air_coin() -> void:
        coin_node = Coin3DL.new()
        var x := rng.randf_range(-fw * 0.5 + 14.0, fw * 0.5 - 14.0)
        var y := rng.randf_range(paddle_y + fh * 0.24, reach_y - 6.0)
        coin_node.position = Vector3(x, y, 0)
        world.add_child(coin_node)
        coin_node.set_diameter(Coin3DL.world_diameter(TB.COIN_DESIGN_PX,
                        cam, cam_d))
        coin_window = cleared_this_round + COIN_WINDOW

func _coin_air_tick(_delta: float) -> void:
        if coin_node == null or not is_instance_valid(coin_node):
                return
        if phase == "run" or phase == "serve":
                var dx := bx - coin_node.position.x
                var dy := bby - coin_node.position.y
                var rr := PBALL_R + 3.0
                if dx * dx + dy * dy <= rr * rr:
                        add_run_coins(1)
                        achievement_count("coins_taken", 1)
                        Jukebox.sfx("coin", -2.0)
                        coin_node.collect()
                        coin_node = null
                        return
        if cleared_this_round > coin_window:
                Jukebox.sfx("tb_miss", -8.0)
                coin_node.queue_free()
                coin_node = null

# ================================================================ shared VFX

func _frag(color: Color, pos: Vector3, vel: Vector3) -> void:
        var m: MeshInstance3D = null
        for f in _frags:
                if not f["alive"]:
                        m = f["node"]
                        f["alive"] = true
                        f["vel"] = vel
                        f["life"] = 0.85
                        f["spin"] = Vector3(rng.randf_range(-6, 6),
                                        rng.randf_range(-6, 6),
                                        rng.randf_range(-6, 6))
                        m.position = pos
                        m.visible = true
                        var mat: StandardMaterial3D = _frag_mat(color)
                        m.material_override = mat
                        f["mat"] = mat
                        m.scale = Vector3.ONE * rng.randf_range(0.6, 1.3)
                        return
        # the pool is dry: grow it
        m = MeshInstance3D.new()
        var bm := BoxMesh.new()
        bm.size = Vector3(1.3, 1.3, 1.3)
        m.mesh = bm
        m.position = pos
        m.visible = true
        frag_layer.add_child(m)
        var mat := _frag_mat(color)
        m.material_override = mat
        _frags.append({"node": m, "alive": true, "vel": vel, "life": 0.85,
                "mat": mat, "spin": Vector3(rng.randf_range(-6, 6),
                        rng.randf_range(-6, 6), rng.randf_range(-6, 6))})

func _frag_mat(color: Color) -> StandardMaterial3D:
        var key := color.to_html()
        if _frag_cache.has(key):
                var shared: StandardMaterial3D = _frag_cache[key]
                var inst := shared.duplicate() as StandardMaterial3D
                inst.albedo_color = color
                inst.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
                return inst
        var m := StandardMaterial3D.new()
        m.albedo_color = color
        m.roughness = 0.55
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        _frag_cache[key] = m
        return m

func _frags_tick(delta: float) -> void:
        for f in _frags:
                if not bool(f["alive"]):
                        continue
                var n: MeshInstance3D = f["node"]
                var v: Vector3 = f["vel"]
                v.y += GRAV * 0.6 * delta
                f["vel"] = v
                n.position += v * delta
                n.rotation += (f["spin"] as Vector3) * delta
                f["life"] = float(f["life"]) - delta
                var mat: StandardMaterial3D = f["mat"]
                mat.albedo_color.a = clampf(float(f["life"]) / 0.85, 0.0, 1.0)
                if float(f["life"]) <= 0.0:
                        f["alive"] = false
                        n.visible = false

func _clear_frags() -> void:
        for f in _frags:
                f["alive"] = false
                (f["node"] as MeshInstance3D).visible = false

# ================================================================ skins/shop

func _apply_tower_skin() -> void:
        var skin := TB.break_skin()
        _apply_sky(skin)
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
                if paddle != null and is_instance_valid(paddle):
                        var pm2: StandardMaterial3D = paddle.material_override
                        pm2.albedo_color = TB.ramp_color(skin, 0).darkened(0.18)
                for r in rows:
                        var d: Dictionary = rows[r]
                        if d["node"] != null and is_instance_valid(d["node"]):
                                (d["node"] as MeshInstance3D).mesh = \
                                        _row_mesh(d["breaks"], rows_data[int(r)],
                                        int(r))

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
                        func(): _apply_tower_skin()))
        var back := Arc.button("CLOSE", Vector2(560, 72), 26, Arc.GOOD,
                func(): sheet_pop())
        sheet.add_child(back)
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

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
                                        TB.ball_color())
                else:
                        # the tower rows + the paddle under
                        for i in 3:
                                var y := 8.0 + float(i) * 16.0
                                glyph.draw_rect(Rect2(18, y, 60, 9),
                                        Color(0.3, 0.2, 0.1, 0.55))
                        glyph.draw_rect(Rect2(30, 62, 36, 8),
                                TB.ramp_color(TB.break_skin(), 0))
                        glyph.draw_circle(Vector2(48, 52), 6.0,
                                        TB.ball_color()))
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
# a 2D one. The game maps the events into its own world.

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
        elif event is InputEventMouseButton \
                        and (event as InputEventMouseButton).button_index \
                        == MOUSE_BUTTON_LEFT:
                holding = (event as InputEventMouseButton).pressed
        elif event is InputEventMouseMotion and ScaleRule.is_pc() \
                        and mode == "platform" and phase != "boot" \
                        and phase != "intro" and phase != "optionals":
                # the PC seat: the platform follows the mouse X (the neon
                # tower's native feel) - no button needed
                var vp := get_viewport().get_visible_rect().size
                ptx = ((event as InputEventMouseMotion).position.x \
                                - vp.x * 0.5) * wpp
        elif event is InputEventScreenDrag and mode == "platform":
                # the finger: delta steering (no teleport when the finger
                # lands far from the paddle)
                var dx: float = (event as InputEventScreenDrag).relative.x
                ptx += dx * wpp

func _goga_tick(delta: float) -> void:
        _frags_tick(delta)
        if mode == "ball":
                _ball_tick(delta)
        else:
                _platform_tick(delta)

func _on_press(_pos: Vector2) -> void:
        if mode == "platform" and phase == "serve":
                _launch_ball()
                return
        holding = true

func _on_release(_pos: Vector2) -> void:
        holding = false
