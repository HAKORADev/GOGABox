extends GogaGame3D
## TOWER DESTROYER (v041-3) - the box's second 3D game, the FOUR-SEAT one.
## THE TEACHER: Voodoo's Fire Balls 3D (the owner's XAPK, study only -
## see towerdestroyer_data.gd for the provenance). THE GAME: the shooter
## sits at the BOTTOM of an endless descending tower (the tower ball law
## inverted: bottom-to-top progress), holds to fire balls up at the
## rotating platforms, breaks every colored segment, and NEVER lets a
## black segment land over his seat. One crash law: the BLACK LANDING.
##
## THE SEAT LAW (the LAN seed): every shooter is a PlayerSeat dictionary -
## angle, alive, score, is_cpu, personality - and the ONLY difference
## between the human and a CPU is the input source that drives its fire
## clock. The box's first multiplayer-shaped structure ("the current
## implementation is not true multiplayer ofc" - the owner); the future
## LAN seat swaps the input source, nothing else.
##
## THE FLOW (the universal law, r3): the game is PORTRAIT-ONLY, so there
## is no position ask - Screen 1 is CHOOSE PLAYERS (1/2/3/4, the house
## ask layout), Screen 2 the ready card (TAP ANYWHERE). The ask screens
## are the game's ROOT: back never closes them (the tower ball r3 back
## law), the shop sheet above them still closes.
##
## World units: 1u = 20 design px (the tower reads ~600px wide on the
## 1080 portrait canvas).

const TD := preload("res://game/games/towerdestroyer/towerdestroyer_data.gd")
const Coin3DL := preload("res://game/core/game_coin3d.gd")

const CAM_POS := Vector3(0, 24, 88)
const CAM_LOOK := Vector3(0, 27, 0)
const CAM_FOV := 55.0
const SPAWN_Y := 118.0            # platforms are born past the top of view
const GROUND_R := 22.0
const CANNON_H := 2.2

# ---------------------------------------------------------------- state
var phase := "boot"      # boot|players|ready|run|over
var players := 1
var rng := RandomNumberGenerator.new()

var world: Node3D
var cam: Camera3D
var env: WorldEnvironment
var sun: DirectionalLight3D
var ground: MeshInstance3D
var pole: MeshInstance3D
var frag_layer: Node3D

# the seats (THE LAN SEED): index 0 is always the human
var seats: Array = []    # [{angle, alive, score, is_cpu, pers, cannon, barrel, tag, tint, fire_clock, burst_left, burst_clock, target_id, react_clock}]
var run_destroyed := 0   # platforms destroyed by ANY seat (the coin clock)
var pending_coin := 0    # platforms until the coin's carrier spawns

# the tower
var plats: Array = []    # lowest-first: [{y, speed, rot, spin, slots, node, coin_slot, coin, depth}]
var next_depth := 0

# balls + fx
var balls: Array = []    # [{y, angle, radius, node, seat, vy}]
var _frags: Array = []   # pooled fragments
var holding := false
var key_hold := false
var pad_hold := false
var fire_clock := 0.0
var shake_t := 0.0

# hud
var _phase_ui: Control = null     # the live ask screen (the dim pair)
var _ready_card: Control = null

# ---------------------------------------------------------------- skins
func _ball_skin() -> Dictionary:
        var on := Box.item_on(game_id, "skin_ball")
        for s in TD.BALL_SKINS:
                if s["id"] == on:
                        return s
        return TD.BALL_SKINS[0]

func _cannon_skin() -> Dictionary:
        var on := Box.item_on(game_id, "skin_cannon")
        for s in TD.CANNON_SKINS:
                if s["id"] == on:
                        return s
        return TD.CANNON_SKINS[0]

# ----------------------------------------------------------------- setup

func _goga_setup() -> void:
        rng.randomize()
        pause_end_run = true     # the pause sheet banks the run
        add_hud_button("SHOP", func(): _shop_open())
        _build_world()
        players = maxi(1, mini(4, int(Box.get_progress(game_id, "players", 1))))
        _apply_cannon_skins()
        # portrait-only game: no position ask - Screen 1 is the players ask
        _show_players_select()
        check_achievements()

func _goga_pause_end_ok() -> bool:
        return phase == "run"

## THE BACK LAW (tower ball r3): the ask screens are the game's ROOT -
## back can never close them, no stuck state exists. The shop sheet
## above them still closes (the exact shape every game wears).
func _back_pressed() -> void:
        if phase in ["players", "ready"] and _sheet_stack.is_empty():
                return
        super._back_pressed()

# ----------------------------------------------------------------- world

func _build_world() -> void:
        world = Node3D.new()
        add_child(world)
        cam = Camera3D.new()
        cam.fov = CAM_FOV
        world.add_child(cam)
        cam.position = CAM_POS
        cam.look_at_from_position(CAM_POS, CAM_LOOK, Vector3.UP)
        cam.current = true
        # the dusk sky (the warm workshop light - photographs well too)
        env = WorldEnvironment.new()
        var e := Environment.new()
        e.background_mode = Environment.BG_SKY
        var sky := Sky.new()
        var sm := ProceduralSkyMaterial.new()
        sm.sky_top_color = Color("2c3564")
        sm.sky_horizon_color = Color("f2a06b")
        sm.ground_bottom_color = Color("241a12")
        sm.ground_horizon_color = Color("e8b184")
        sm.sun_angle_max = 30.0
        sky.sky_material = sm
        e.sky = sky
        e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
        e.ambient_light_sky_contribution = 0.5
        e.ambient_light_energy = 1.4
        e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
        env.environment = e
        world.add_child(env)
        sun = DirectionalLight3D.new()
        sun.rotation_degrees = Vector3(-48, -22, 0)
        sun.light_energy = 1.25
        sun.light_color = Color(1.0, 0.9, 0.78)
        sun.shadow_enabled = true
        sun.directional_shadow_max_distance = 260.0
        sun.shadow_blur = 1.3
        world.add_child(sun)
        # THE BOUNCE FILL: a soft front-below light so the platforms'
        # undersides (the faces the shooter stares at) read warm, not void
        var fill := DirectionalLight3D.new()
        fill.rotation_degrees = Vector3(58, 12, 0)
        fill.light_energy = 0.5
        fill.light_color = Color(1.0, 0.82, 0.62)
        fill.shadow_enabled = false
        world.add_child(fill)
        # the ground disc
        ground = MeshInstance3D.new()
        var gm := CylinderMesh.new()
        gm.top_radius = GROUND_R
        gm.bottom_radius = GROUND_R
        gm.height = 1.0
        gm.radial_segments = 48
        ground.mesh = gm
        ground.position.y = -0.5
        var gmat := StandardMaterial3D.new()
        gmat.albedo_color = Color("6b4a2c")
        gmat.roughness = 0.9
        ground.material_override = gmat
        world.add_child(ground)
        # the center cable (thin, dark - structure only, balls never
        # reach it; the giant-pillar look died on the rig's eye pass)
        pole = MeshInstance3D.new()
        var pm := CylinderMesh.new()
        pm.top_radius = 0.5
        pm.bottom_radius = 0.5
        pm.height = SPAWN_Y + 20.0
        pm.radial_segments = 12
        pole.mesh = pm
        pole.position.y = (SPAWN_Y + 20.0) * 0.5
        var pmat := StandardMaterial3D.new()
        pmat.albedo_color = Color(0.24, 0.2, 0.17)
        pmat.roughness = 0.8
        pole.material_override = pmat
        world.add_child(pole)
        frag_layer = Node3D.new()
        world.add_child(frag_layer)

# ------------------------------------------------------------- the seats

const SEAT_TINTS := [Color("ffb020"), Color("e8574a"), Color("9d7ae8"), Color("4fc4a8")]

func _build_seats() -> void:
        _clear_seats()
        for i in players:
                # v042-1 THE 3D SEAT: in a LAN race the rivals are REMOTE
                # humans, never CPU (THE REAL-ONLY LAW) - their cannons
                # render here, their fire happens on their devices, their
                # scores ride lan_prog.
                var is_cpu := i > 0 and not lan_active
                var cannon := _build_cannon(_cannon_skin() if i == 0 \
                                else TD.CANNON_SKINS[0], is_cpu, SEAT_TINTS[i])
                var a: float = TD.SEAT_ANGLES[i]
                cannon.position = Vector3(sin(a) * TD.SEAT_R, 0.0, cos(a) * TD.SEAT_R)
                cannon.rotation.y = a     # the barrel faces the tower axis
                world.add_child(cannon)
                var seat := {
                        "angle": a, "alive": true, "score": 0,
                        "is_cpu": is_cpu, "pers": TD.cpu_personality(rng),
                        "cannon": cannon, "tag": null, "tint": SEAT_TINTS[i],
                        "fire_clock": 0.0, "burst_left": 0, "burst_clock": 0.0,
                        "react_clock": 0.0, "target_id": -1,
                }
                if lan_active and i > 0:
                        seat["tag"] = _build_lan_tag(i)
                elif is_cpu:
                        seat["tag"] = _build_cpu_tag(i)
                seats.append(seat)

func _clear_seats() -> void:
        for s in seats:
                if s["cannon"] != null and is_instance_valid(s["cannon"]):
                        s["cannon"].queue_free()
                if s["tag"] != null and is_instance_valid(s["tag"]):
                        s["tag"].queue_free()
        seats.clear()

## the cannon: base disc + the skin's barrel; CPUs wear a darker classic
## (the same design law, a crew tint on top). The crew reads BIG on the
## ground ring - the rig's eye pass killed the tiny-cone look.
func _build_cannon(skin: Dictionary, is_cpu: bool, tint: Color) -> Node3D:
        var root := Node3D.new()
        root.scale = Vector3(1.7, 1.7, 1.7)
        var body_mat := StandardMaterial3D.new()
        var bcol: Color = skin["body"]
        if is_cpu:
                bcol = bcol.darkened(0.25).lerp(tint, 0.22)
        body_mat.albedo_color = bcol
        body_mat.roughness = float(skin["rough"])
        body_mat.metallic = float(skin["metal"])
        if float(skin["alpha"]) < 1.0:
                body_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
                body_mat.albedo_color.a = float(skin["alpha"])
        if float(skin["emission"]) > 0.0:
                body_mat.emission_enabled = true
                body_mat.emission = bcol
                body_mat.emission_energy_multiplier = float(skin["emission"])
        var base := MeshInstance3D.new()
        var bm := CylinderMesh.new()
        bm.top_radius = 1.15
        bm.bottom_radius = 1.5
        bm.height = 1.0
        base.mesh = bm
        base.position.y = 0.5
        base.material_override = body_mat
        root.add_child(base)
        var barrel_mat := StandardMaterial3D.new()
        var rcol: Color = skin["barrel"]
        if is_cpu:
                rcol = rcol.darkened(0.25).lerp(tint, 0.22)
        barrel_mat.albedo_color = rcol
        barrel_mat.roughness = float(skin["rough"])
        barrel_mat.metallic = float(skin["metal"])
        var barrel := MeshInstance3D.new()
        var rm := CylinderMesh.new()
        rm.top_radius = float(skin["barrel_w"])
        rm.bottom_radius = float(skin["barrel_w"]) * 1.15
        rm.height = float(skin["barrel_len"])
        barrel.mesh = rm
        barrel.position.y = 1.0 + float(skin["barrel_len"]) * 0.5
        barrel.material_override = barrel_mat
        root.add_child(barrel)
        return root

## THE SKIN SEAT: the shop equips live - the human seat's cannon rebuilds
func _apply_cannon_skins() -> void:
        if seats.is_empty():
                return
        var skin := _cannon_skin()
        var s: Dictionary = seats[0]
        if s["cannon"] != null and is_instance_valid(s["cannon"]):
                s["cannon"].queue_free()
        var cannon := _build_cannon(skin, false, SEAT_TINTS[0])
        cannon.position = Vector3(sin(s["angle"]) * TD.SEAT_R, 0.0,
                        cos(s["angle"]) * TD.SEAT_R)
        cannon.rotation.y = s["angle"]
        world.add_child(cannon)
        s["cannon"] = cannon

## the CPU score tag: a HUD chip anchored to the seat's world position
## (the owner: "show it's score") - removed ACCURATELY at death
func _build_cpu_tag(i: int) -> Control:
        var chip := Arc.chip("%s 0" % TD.SEAT_NAMES[i], "", Color(0, 0, 0, 0.45),
                        18, SEAT_TINTS[i])
        _overlay_root_ref().add_child(chip)
        return chip

## the LAN rival's tag: the human's own name rides the cannon
func _build_lan_tag(i: int) -> Control:
        var chip := Arc.chip("%s 0" % _lan_name_of(i), "", Color(0, 0, 0, 0.45),
                        18, SEAT_TINTS[i])
        _overlay_root_ref().add_child(chip)
        return chip

## THE PERSPECTIVE MAP (v042-1): locally the human is always index 0, so
## local seat i rides the session seat (my_seat_no + i) on the n-circle -
## the same rotation the snl table wears.
func _lan_name_of(i: int) -> String:
        if lan_seats.is_empty():
                return "RIVAL"
        var n: int = lan_seats.size()
        var seat_no := posmod(LAN.my_seat_no() + i, n) + 1
        for s in lan_seats:
                if int(s.get("seat", -1)) == seat_no:
                        return String(s.get("name", "RIVAL")).to_upper()
        return "RIVAL"

func _lan_local_idx(seat_no: int) -> int:
        var n: int = maxi(1, lan_seats.size())
        return posmod(seat_no - LAN.my_seat_no(), n)

func _lan_session_seat(idx: int) -> int:
        var n: int = maxi(1, lan_seats.size())
        return posmod(LAN.my_seat_no() + idx, n) + 1

func _seat_world_pos(s: Dictionary, h := 0.0) -> Vector3:
        return Vector3(sin(s["angle"]) * TD.SEAT_R, h, cos(s["angle"]) * TD.SEAT_R)

# ----------------------------------------------------------- the ask flow

## THE ASK SEAT (the tower ball r3 shape): the ask screens are a RAW dim
## + panel pair tracked in _phase_ui - they never join the sheet stack,
## because back can never close them (the game's ROOT) and a stack entry
## would leak across the flow's walk.
func _ask_panel() -> VBoxContainer:
        _clear_phase_ui()
        var dim := ColorRect.new()
        dim.color = Color(0.09, 0.05, 0.02, 0.55)
        dim.set_anchors_preset(Control.PRESET_FULL_RECT)
        dim.mouse_filter = Control.MOUSE_FILTER_STOP
        _overlay_root_ref().add_child(dim)
        var cc := CenterContainer.new()
        cc.set_anchors_preset(Control.PRESET_FULL_RECT)
        cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        dim.add_child(cc)
        var panel := PanelContainer.new()
        panel.add_theme_stylebox_override("panel",
                Arc.panel_style(Color(1, 1, 1, 0.94), 26, 24))
        cc.add_child(panel)
        var vb := VBoxContainer.new()
        vb.add_theme_constant_override("separation", 16)
        panel.add_child(vb)
        _phase_ui = dim
        return vb

func _clear_phase_ui() -> void:
        if _phase_ui != null and is_instance_valid(_phase_ui):
                _phase_ui.queue_free()
        _phase_ui = null

## Screen 1: CHOOSE PLAYERS - the house ask layout (law 28): ONE short
## title, the choices as EQUAL side-by-side cards, ON marks the live pick.
## A pick walks straight to the ready card (the ask screens START the run
## path; nothing closes them).
func _show_players_select() -> void:
        phase = "players"
        var vb := _ask_panel()
        var t := Arc.label("HOW MANY PLAYERS", 40, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(t)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 14)
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        vb.add_child(row)
        for n in 4:
                var count := n + 1
                row.add_child(_count_card(count, players == count, func():
                        players = count
                        Box.set_progress(game_id, "players", players)
                        Jukebox.sfx("td_click", -6.0)
                        _show_ready_card()))
        var hint := Arc.label("the shop and the skins wait in the top bar",
                        16, Color("8a6a40"), false)
        hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(hint)
        Arc.fit_sheet(vb)

## the crew card (the snake mode card shape, one per seat count)
func _count_card(count: int, selected: bool, cb: Callable) -> Button:
        var b := Button.new()
        b.custom_minimum_size = Vector2(170, 110)
        var sb := Arc.panel_style(Arc.GOOD if selected else Arc.CARD, 20, 10)
        if not selected:
                sb.set_border_width_all(3)
                sb.border_color = Color(0, 0, 0, 0.12)
        b.add_theme_stylebox_override("normal", sb)
        var sbp := sb.duplicate() as StyleBoxFlat
        sbp.bg_color = sbp.bg_color.darkened(0.06)
        b.add_theme_stylebox_override("pressed", sbp)
        var v := VBoxContainer.new()
        v.set_anchors_preset(Control.PRESET_FULL_RECT)
        v.alignment = BoxContainer.ALIGNMENT_CENTER
        v.add_theme_constant_override("separation", 2)
        v.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(v)
        var l := Arc.label(str(count), 40, Arc.INK if not selected \
                        else Color(0.16, 0.10, 0.05))
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        v.add_child(l)
        var s := Arc.label("SOLO" if count == 1 else "+%d CPU" % (count - 1),
                        17, Color("6a4a28"), false)
        s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        s.mouse_filter = Control.MOUSE_FILTER_IGNORE
        v.add_child(s)
        b.pressed.connect(cb)
        return b

## Screen 2: THE READY CARD - "TAP ANYWHERE TO START" + the run subline,
## the snake's exact soft card. The tap rides the universal overlay
## (fires on RELEASE - the tap law).
func _show_ready_card() -> void:
        phase = "ready"
        _clear_phase_ui()
        var cc := CenterContainer.new()
        cc.set_anchors_preset(Control.PRESET_FULL_RECT)
        cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var panel := PanelContainer.new()
        panel.add_theme_stylebox_override("panel",
                        Arc.panel_style(Color(1, 1, 1, 0.82), 20))
        var lbl := Arc.label("TAP ANYWHERE TO START", 40, Arc.INK)
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        var sub := Arc.label(_ready_subline(), 18, Color("6a4a28"), false)
        sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 6)
        v.add_child(lbl)
        v.add_child(sub)
        panel.add_child(v)
        cc.add_child(panel)
        panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
        lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
        sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
        cc.modulate.a = 0.0
        _overlay_root_ref().add_child(cc)
        _ready_card = cc
        var tw := cc.create_tween()
        tw.tween_property(cc, "modulate:a", 1.0, 0.18)
        tw.parallel().tween_method(_card_step.bind(cc), 0.7, 1.0, 0.26) \
                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tap_anywhere_start(_ready_go, "")

func _ready_subline() -> String:
        var crew := "SOLO" if players == 1 else "%d SHOOTERS" % players
        return "%s  ·  ENDLESS  ·  1 PLATFORM = 1 POINT" % crew

func _card_step(s: float, cc: Control) -> void:
        if not is_instance_valid(cc):
                return
        cc.pivot_offset = cc.size / 2.0
        cc.scale = Vector2(s, s)

func _ready_go() -> void:
        Jukebox.sfx("td_click", -6.0)
        if _ready_card != null and is_instance_valid(_ready_card):
                _ready_card.queue_free()
        _ready_card = null
        _start_run()

# ------------------------------------------------------------- the run

func _start_run() -> void:
        phase = "run"
        set_score(0)
        run_coins = 0
        if _coins_label != null:
                _coins_label.text = "0"
        run_destroyed = 0
        pending_coin = 0
        _clear_tower()
        _build_seats()
        _apply_cannon_skins()
        for i in TD.ALIVE_AHEAD:
                _spawn_platform()
        # the crew achievement: the mode seat the owner's modes 1..4 ride
        if players == 4:
                achievement_count("mode4", 1)
        Jukebox.music("res://assets/audio/music/td_theme.ogg")

func _clear_tower() -> void:
        for p in plats:
                if p["node"] != null and is_instance_valid(p["node"]):
                        p["node"].queue_free()
        plats.clear()
        for b in balls:
                if b["node"] != null and is_instance_valid(b["node"]):
                        b["node"].queue_free()
        balls.clear()
        next_depth = 0

# ---------------------------------------------------------------- platforms

func _spawn_platform() -> void:
        var depth := next_depth
        next_depth += 1
        # THE FIRST BAND SEATS IN VIEW: the opening tower is seeded through
        # the visible band (the rig's eye pass caught 40s of dead air when
        # everything spawned at the 118 mark); after the seed, the top
        # feeds above the frame.
        var top := SPAWN_Y
        if depth < TD.ALIVE_AHEAD:
                top = 6.0 + float(depth) * TD.PITCH
        elif not plats.is_empty():
                # chain from the live top - a fresh ring enters just above
                # the visible band, never a floating gap behind it
                for p in plats:
                        top = maxf(top, float(p["y"]) + TD.PITCH)
        var slots := TD.build_slots(depth, rng)
        var p := {
                "y": top, "depth": depth,
                "speed": TD.platform_speed(TD.speed_base(run_destroyed),
                                rng.randf()),
                "rot": rng.randf_range(0.0, TAU),
                "spin": TD.spin_speed(rng.randf(), rng.randf()),
                "slots": slots, "node": null,
                "coin_slot": -1, "coin": null,
        }
        # THE COIN SEAT: the carrier spawns 2 platforms after the milestone
        if pending_coin > 0:
                pending_coin -= 1
                if pending_coin == 0:
                        var ci := TD.coin_slot(slots, rng)
                        if ci >= 0:
                                p["coin_slot"] = ci
        _build_platform_node(p)
        plats.append(p)
        # the toast rides ONE line at the moment the coin boards (law 29)
        if p["coin_slot"] >= 0:
                game_toast("A GOGACOIN RIDES THE TOWER")

## one platform = a Node3D of per-slot sector meshes (vertex-colored
## ArrayMesh, the tower ball two-tone law: top lit, sides darker)
func _build_platform_node(p: Dictionary) -> void:
        var root := Node3D.new()
        root.position.y = float(p["y"])
        p["node"] = root
        world.add_child(root)
        # THE VERTEX-COLOR MATERIAL (the tower ball law): the sector colors
        # live in the mesh vertices - without vertex_color_use_as_albedo the
        # whole tower renders default-white under dim ambient (the rig's eye
        # pass caught the near-black tower)
        var mat := StandardMaterial3D.new()
        mat.vertex_color_use_as_albedo = true
        mat.roughness = 0.85
        mat.metallic = 0.0
        p["mat"] = mat
        var ramp_idx := int(p["depth"]) % TD.RAMP.size()
        var n: int = (p["slots"] as Array).size()
        var arc := TD.slot_arc(n)
        for i in n:
                _slot_mesh(p, root, i, ramp_idx, arc)
        # the coin rides its slot's underside
        if int(p["coin_slot"]) >= 0:
                var coin := Coin3DL.new()
                coin.set_diameter(Coin3DL.world_diameter(TD.COIN_DESIGN_PX,
                                cam, CAM_POS.length()))
                var a := (float(p["coin_slot"]) + 0.5) * arc
                coin.position = Vector3(sin(a) * (TD.R_IN + (TD.R_OUT - TD.R_IN) * 0.5),
                                -0.9, cos(a) * (TD.R_IN + (TD.R_OUT - TD.R_IN) * 0.5))
                root.add_child(coin)
                p["coin"] = coin

## one slot's mesh (skipped for gaps) - an annular sector prism
func _slot_mesh(p: Dictionary, root: Node3D, i: int, ramp_idx: int,
                arc: float) -> void:
        var s: Dictionary = p["slots"][i]
        if s["kind"] == "gap":
                return
        var a0 := float(i) * arc
        var a1 := a0 + arc * 0.96
        var col: Color = TD.BLACK if s["kind"] == "black" \
                        else TD.ramp_color(ramp_idx, i)
        # gaps carry no hp (they never mesh); black wears its armor height
        var mesh := MeshInstance3D.new()
        mesh.mesh = _sector_mesh(a0, a1, col, float(s.get("hp", 2)))
        mesh.material_override = p["mat"]
        root.add_child(mesh)
        s["mesh"] = mesh
        s["a0"] = a0
        s["a1"] = a1

## the annular sector prism: top face + darker sides (the two-tone law)
func _sector_mesh(a0: float, a1: float, col: Color, hp: int) -> ArrayMesh:
        var st := SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        var r_in := TD.R_IN
        var r_out := TD.R_OUT
        var h := TD.THICK * (0.55 + 0.15 * float(hp))
        var top := col
        var side := col.darkened(0.22)
        var bottom := col.darkened(0.12)
        var steps := maxi(2, int((a1 - a0) / 0.22))
        for k in steps:
                var l0 := lerpf(a0, a1, float(k) / float(steps))
                var l1 := lerpf(a0, a1, float(k + 1) / float(steps))
                var p00 := Vector3(sin(l0) * r_in, h, cos(l0) * r_in)
                var p01 := Vector3(sin(l1) * r_in, h, cos(l1) * r_in)
                var p10 := Vector3(sin(l0) * r_out, h, cos(l0) * r_out)
                var p11 := Vector3(sin(l1) * r_out, h, cos(l1) * r_out)
                var b00 := p00; b00.y = 0.0
                var b01 := p01; b01.y = 0.0
                var b10 := p10; b10.y = 0.0
                var b11 := p11; b11.y = 0.0
                # top face (up)
                st.set_color(top)
                st.add_vertex(p10); st.add_vertex(p00); st.add_vertex(p01)
                st.add_vertex(p10); st.add_vertex(p01); st.add_vertex(p11)
                # outer wall
                st.set_color(side)
                st.add_vertex(b10); st.add_vertex(p11); st.add_vertex(p10)
                st.add_vertex(b10); st.add_vertex(b11); st.add_vertex(p11)
                # inner wall
                st.add_vertex(b00); st.add_vertex(p00); st.add_vertex(p01)
                st.add_vertex(b00); st.add_vertex(p01); st.add_vertex(b01)
                # BOTTOM face (the shooter looks UP at it - it must read)
                st.set_color(bottom)
                st.add_vertex(b00); st.add_vertex(b01); st.add_vertex(b11)
                st.add_vertex(b00); st.add_vertex(b11); st.add_vertex(b10)
                # end caps
                st.add_vertex(b00); st.add_vertex(b10); st.add_vertex(p10)
                st.add_vertex(b00); st.add_vertex(p10); st.add_vertex(p00)
                st.add_vertex(b01); st.add_vertex(p11); st.add_vertex(b11)
                st.add_vertex(b01); st.add_vertex(p01); st.add_vertex(p11)
        st.generate_normals()
        return st.commit()

# ------------------------------------------------------------------- tick

func _goga_tick(delta: float) -> void:
        _frags_tick(delta)
        if shake_t > 0.0:
                shake_t = maxf(0.0, shake_t - delta)
                var k := shake_t * 0.6
                cam.h_offset = sin(shake_t * 60.0) * k
                cam.v_offset = cos(shake_t * 51.0) * k
        else:
                cam.h_offset = 0.0
                cam.v_offset = 0.0
        if phase != "run":
                return
        _tower_tick(delta)
        _fire_tick(delta)
        _balls_tick(delta)
        _cpu_tick(delta)
        _tags_tick()

func _tower_tick(delta: float) -> void:
        var landed: Array = []
        for p in plats:
                p["y"] = float(p["y"]) - float(p["speed"]) * delta
                p["rot"] = fposmod(float(p["rot"]) + float(p["spin"]) * delta, TAU)
                if p["node"] != null and is_instance_valid(p["node"]):
                        (p["node"] as Node3D).position.y = float(p["y"])
                        (p["node"] as Node3D).rotation.y = float(p["rot"])
                if float(p["y"]) <= TD.MUZZLE_Y:
                        landed.append(p)
        for p in landed:
                _platform_lands(p)
        # keep the tower fed
        while plats.size() < TD.ALIVE_AHEAD:
                _spawn_platform()

## THE LANDING: a platform crossing the muzzle line is judged seat by
## seat - THE BLACK LAW: alive black over a seat kills THAT shooter;
## alive colored shatters harmlessly on the ground. The platform dies
## whole either way; a missed coin dies with it.
func _platform_lands(p: Dictionary) -> void:
        for s in seats:
                if not bool(s["alive"]):
                        continue
                if TD.seat_killed(p["slots"], float(p["rot"]), float(s["angle"])):
                        _kill_seat(s)
                        if lan_active and s != seats[0]:
                                var idx := seats.find(s)
                                _lan_alive[_lan_session_seat(idx)] = false
                                game_toast("%s IS OUT" % _lan_name_of(idx))
        if p["coin"] != null and is_instance_valid(p["coin"]):
                (p["coin"] as Node3D).queue_free()
                p["coin"] = null
                game_toast("THE COIN GOT AWAY")
        _shatter_platform(p, false)
        plats.erase(p)

## the shooter's death: sink the cannon, kill its input, remove the tag
## ACCURATELY (the owner: "show it's score and remove it accurately when
## it dies"). The human's death is the run's death.
func _kill_seat(s: Dictionary) -> void:
        s["alive"] = false
        Jukebox.sfx("td_die", -4.0)
        shake_t = maxf(shake_t, 0.5)
        var cannon: Node3D = s["cannon"]
        if cannon != null and is_instance_valid(cannon):
                var tw := cannon.create_tween()
                tw.tween_property(cannon, "position:y", -2.6, 0.55) \
                        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
        var tag: Control = s["tag"]
        if tag != null and is_instance_valid(tag):
                var tw2 := tag.create_tween()
                tw2.tween_property(tag, "modulate:a", 0.0, 0.4)
                tw2.tween_callback(tag.queue_free)
                s["tag"] = null
        if not bool(s["is_cpu"]):
                _run_over()

func _run_over() -> void:
        if over:
                return
        phase = "over"
        achievement_max("run_destroyed", run_destroyed)
        if lan_active:
                LAN.send_prog({"k": "dead", "s": score})
                _lan_alive[LAN.my_seat_no()] = false
                _lan_check_last()
        finish_run(score, run_coins)

# ================================================== THE LAN RACE (v042-1)
## THE 3D SEAT CORRECTION: Tower Destroyer is the box's LAN 3D game (the
## owner's word). THE RACE LAW (the tower ball pattern): identical seeded
## towers on every device (the match seed drives the platform RNG), every
## device simulates ONLY its own cannon, the landing judgments are
## identical by construction (black segments are indestructible, so every
## device rules the same deaths), scores ride lan_prog, and the verdict is
## THE LAST CANNON standing.

var _lan_alive := {}     # seat -> alive

func lan_match_start(seed_v: int, m_seats: Array) -> void:
        lan_active = true
        lan_seed = seed_v
        rng.seed = seed_v        # THE IDENTICAL TOWERS LAW
        players = m_seats.size()
        for s in m_seats:
                _lan_alive[int(s.get("seat", 1))] = true
        _clear_phase_ui()
        _start_run()
        game_toast("SAME TOWERS - LAST CANNON WINS")

func lan_solo() -> void:
        lan_active = false
        _show_players_select()

func lan_prog(from_dev: String, data: Dictionary) -> void:
        if not lan_active:
                return
        var seat := -1
        for st in lan_seats:
                if String(st.get("dev", "")) == from_dev:
                        seat = int(st.get("seat", -1))
                        break
        if seat < 0:
                return
        match String(data.get("k", "")):
                "score":
                        var idx := _lan_local_idx(seat)
                        if idx >= 0 and idx < seats.size():
                                seats[idx]["score"] = int(data.get("s", 0))
                "dead":
                        _lan_alive[seat] = false
                        game_toast("%s IS OUT" % _lan_name_of(_lan_local_idx(seat)))
                        _lan_check_last()

func lan_end(results: Array) -> void:
        pass

## THE LAST CANNON: every rival out while I stand = the win (+1, the
## towerball race verdict shape). The run keeps banking until my death.
func _lan_check_last() -> void:
        if phase == "over" or not lan_active:
                return
        for seat in _lan_alive:
                if bool(_lan_alive[seat]):
                        return
        if seats.is_empty() or not bool(seats[0]["alive"]):
                return
        add_score(1)
        game_toast("THE LAST CANNON  +1")
        check_achievements()

# ------------------------------------------------------------------- fire

func _fire_tick(delta: float) -> void:
        if seats.is_empty():
                return
        var human: Dictionary = seats[0]
        fire_clock -= delta
        var want := holding or key_hold or pad_hold
        if want and bool(human["alive"]) and fire_clock <= 0.0:
                fire_clock = 1.0 / TD.FIRE_RATE
                _fire_ball(human)

func _fire_ball(s: Dictionary) -> void:
        var skin := _ball_skin()
        var mat := StandardMaterial3D.new()
        mat.albedo_color = skin["color"]
        mat.roughness = float(skin["rough"])
        mat.metallic = float(skin["metal"])
        if float(skin["alpha"]) < 1.0:
                mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
                mat.albedo_color.a = float(skin["alpha"])
        if float(skin["emission"]) > 0.0:
                mat.emission_enabled = true
                mat.emission = skin["color"]
                mat.emission_energy_multiplier = float(skin["emission"]) * 1.6
        var m := MeshInstance3D.new()
        var sm := SphereMesh.new()
        sm.radius = TD.BALL_R
        sm.height = TD.BALL_R * 2.0
        sm.radial_segments = 16
        sm.rings = 8
        m.mesh = sm
        m.material_override = mat
        var a := float(s["angle"]) + rng.randf_range(-0.02, 0.02)
        var r := TD.SEAT_R + rng.randf_range(-0.9, 0.9)
        m.position = Vector3(sin(a) * r, CANNON_H + 1.2, cos(a) * r)
        world.add_child(m)
        balls.append({"y": CANNON_H + 1.2, "angle": a, "radius": r,
                "node": m, "seat": s})
        Jukebox.sfx("td_shot", -10.0, rng.randf_range(0.92, 1.1))

## THE BALL SWEEP: balls rise; the closing speed vs a descending platform
## is substepped (the tunneling law - a 48u/s ball crosses the 1.2u band
## inside one 30fps step). A hit lands when the ball is INSIDE a band:
## the LOWEST platform whose [y, y+THICK] contains the ball wins; gaps
## pass through to the platform above.
func _balls_tick(delta: float) -> void:
        var dead: Array = []
        for b in balls:
                var remaining := (TD.BALL_SPEED) * delta
                var hit := false
                var consumed := false
                while remaining > 0.0 and not consumed:
                        var step := minf(remaining, 0.4)
                        remaining -= step
                        b["y"] = float(b["y"]) + step
                        var target: Variant = _band_at(float(b["y"]))
                        if target != null:
                                hit = true
                                consumed = true
                                _ball_hits(b, target)
                        elif float(b["y"]) > SPAWN_Y + 14.0:
                                consumed = true
                (b["node"] as MeshInstance3D).position.y = float(b["y"])
                if hit or consumed:
                        dead.append(b)
                        continue
        for b in dead:
                if b["node"] != null and is_instance_valid(b["node"]):
                        (b["node"] as MeshInstance3D).queue_free()
                balls.erase(b)

## the lowest platform whose band CONTAINS y (the ball is inside it)
func _band_at(y: float) -> Variant:
        for p in plats:
                if float(p["y"]) <= y and y <= float(p["y"]) + TD.THICK:
                        return p
        return null

## the lowest platform whose band is at/above the ball (balls inside a
## band below y are already past it)
func _lowest_platform_at(y: float) -> Variant:
        for p in plats:
                if float(p["y"]) + TD.THICK >= y:
                        return p
        return null

## THE HIT LAWS: black eats the ball (spark, no damage - the armor);
## colored takes 1; the last colored's breaker banks the +1 (THE POINT
## LAW); the coin's slot pays the run wallet when ITS breaker lands.
func _ball_hits(b: Dictionary, p: Dictionary) -> void:
        var idx := TD.slot_at(float(b["angle"]), float(p["rot"]),
                (p["slots"] as Array).size())
        var s: Dictionary = p["slots"][idx]
        var hit_pos := Vector3(sin(float(b["angle"])) * float(b["radius"]),
                float(p["y"]), cos(float(b["angle"])) * float(b["radius"]))
        if s["kind"] == "gap":
                return          # through the hole - no interaction at all
        if s["kind"] == "black":
                _spark(hit_pos, Color(0.5, 0.5, 0.55))
                Jukebox.sfx("td_black", -6.0, rng.randf_range(0.9, 1.1))
                return
        # colored: one hit down
        s["hp"] = int(s["hp"]) - 1
        _spark(hit_pos, TD.ramp_color(int(p["depth"]) % TD.RAMP.size(), idx))
        if int(s["hp"]) > 0:
                Jukebox.sfx("td_hit", -8.0, rng.randf_range(0.9, 1.15))
                if s.get("mesh") != null and is_instance_valid(s["mesh"]):
                        (s["mesh"] as MeshInstance3D).scale = Vector3(1, 0.62, 1)
                return
        # the segment died
        _kill_segment(p, idx, hit_pos)
        var shooter: Dictionary = b["seat"]
        if int(p["coin_slot"]) == idx:
                run_coins += 1
                if _coins_label != null:
                        _coins_label.text = str(run_coins)
                achievement_count("coins_taken", 1)
                Jukebox.sfx("td_coin", -4.0)
                if p["coin"] != null and is_instance_valid(p["coin"]):
                        (p["coin"] as Coin3D).collect()
                p["coin"] = null
        if not _has_colored(p):
                # THE POINT LAW: the breaker of the LAST colored segment
                # banks the platform (+1 personal score)
                shooter["score"] = int(shooter["score"]) + 1
                run_destroyed += 1
                achievement_count("destroyed", 1)
                if shooter == seats[0]:
                        add_score(1)
                        if lan_active:
                                LAN.send_prog({"k": "score", "s": score})
                Jukebox.sfx("td_break", -5.0)
                _shatter_platform(p, true)
                plats.erase(p)
                if TD.coin_due(run_destroyed):
                        pending_coin = 2

func _has_colored(p: Dictionary) -> bool:
        for s in p["slots"]:
                if s["kind"] == "colored" and int(s["hp"]) > 0:
                        return true
        return false

func _kill_segment(p: Dictionary, idx: int, at: Vector3) -> void:
        var s: Dictionary = p["slots"][idx]
        if s.get("mesh") != null and is_instance_valid(s["mesh"]):
                var col: Color = TD.ramp_color(int(p["depth"]) % TD.RAMP.size(), idx)
                _burst_frags(at, col)
                (s["mesh"] as MeshInstance3D).queue_free()
        s["mesh"] = null
        s["kind"] = "gap"       # the seat opens - balls pass, lands forgive

## the platform's whole-body shatter (destroyed in the air = celebrate,
## landed = the pieces just slump)
func _shatter_platform(p: Dictionary, scored: bool) -> void:
        var n: int = (p["slots"] as Array).size()
        var arc := TD.slot_arc(n)
        for i in n:
                var s: Dictionary = p["slots"][i]
                if s["kind"] == "colored" and int(s["hp"]) > 0:
                        var a := (float(i) + 0.5) * arc
                        var at := Vector3(sin(a) * (TD.R_IN + (TD.R_OUT - TD.R_IN) * 0.5),
                                float(p["y"]),
                                cos(a) * (TD.R_IN + (TD.R_OUT - TD.R_IN) * 0.5))
                        _burst_frags(at, TD.ramp_color(int(p["depth"]) % TD.RAMP.size(), i))
                if s.get("mesh") != null and is_instance_valid(s["mesh"]):
                        (s["mesh"] as MeshInstance3D).queue_free()
                s["mesh"] = null
        if p["node"] != null and is_instance_valid(p["node"]):
                (p["node"] as Node3D).queue_free()
        p["node"] = null

# --------------------------------------------------------------------- cpu

## THE HUMAN TRIGGER (the owner: "make the cpu a little smart ... more
## human-like, like different detection and different shooting time based
## on the platform"): each CPU watches the lowest platform, reads the eta
## to the muzzle scaled by the platform's own speed, answers with ITS
## reaction delay, fires in ITS burst rhythm, and respects black with ITS
## discipline (a mistake wastes balls into the armor - it never kills).
func _cpu_tick(delta: float) -> void:
        if lan_active:
                return        # THE REAL-ONLY LAW: no CPU in a LAN race
        for i in range(1, seats.size()):
                var s: Dictionary = seats[i]
                if not bool(s["alive"]):
                        continue
                var p: Variant = _lowest_platform_at(TD.MUZZLE_Y + 0.2)
                s["fire_clock"] = float(s["fire_clock"]) - delta
                s["react_clock"] = float(s["react_clock"]) - delta
                s["burst_clock"] = float(s["burst_clock"]) - delta
                if p == null:
                        continue
                var pp: Dictionary = p
                var eta := maxf(0.0, (float(pp["y"]) - TD.MUZZLE_Y)
                        / maxf(0.2, float(pp["speed"])))
                var black_over := TD.seat_killed(pp["slots"], float(pp["rot"]),
                        float(s["angle"]))
                # a fresh platform pulls a fresh reaction beat
                var pid: int = pp["depth"]
                if int(s["target_id"]) != pid:
                        s["target_id"] = pid
                        s["react_clock"] = float(s["pers"]["reaction"])
                # the burst machine: bursts of N, then a human breathing gap
                if int(s["burst_left"]) <= 0 and float(s["burst_clock"]) <= 0.0:
                        s["burst_left"] = int(s["pers"]["burst_len"])
                var burst_ok := int(s["burst_left"]) > 0 \
                        and float(s["fire_clock"]) <= 0.0
                if float(s["react_clock"]) > 0.0:
                        continue
                if TD.cpu_wants_fire(s["pers"], eta, float(pp["speed"]),
                        black_over, burst_ok, rng.randf()):
                        s["burst_left"] = int(s["burst_left"]) - 1
                        if int(s["burst_left"]) <= 0:
                                s["burst_clock"] = float(s["pers"]["burst_pause"])
                        s["fire_clock"] = 1.0 / (TD.FIRE_RATE * 0.85)
                        _fire_ball(s)

## the CPU tags ride their seats (unprojected every frame)
func _tags_tick() -> void:
        for i in seats.size():
                var s: Dictionary = seats[i]
                var tag: Control = s["tag"]
                if tag == null or not is_instance_valid(tag):
                        continue
                if not bool(s["alive"]):
                        tag.visible = false
                        continue
                var wp := _seat_world_pos(s, 6.2)
                var sp := cam.unproject_position(wp)
                tag.position = sp - tag.size * 0.5
                var tag_name: String = TD.SEAT_NAMES[i]
                if lan_active:
                        tag_name = _lan_name_of(i)
                tag.get_child(0).get_child(tag.get_child(0).get_child_count() - 1).text = \
                        "%s %d" % [tag_name, s["score"]]

# ---------------------------------------------------------------- the frags

## the pooled fragment burst (breaks, shatters, the ground slump)
func _burst_frags(at: Vector3, col: Color) -> void:
        for i in 6:
                _spawn_frag(at, col)

func _spawn_frag(at: Vector3, col: Color) -> void:
        var m := MeshInstance3D.new()
        var bm := BoxMesh.new()
        var sz := rng.randf_range(0.35, 0.9)
        bm.size = Vector3(sz, sz * 0.7, sz)
        m.mesh = bm
        var mat := StandardMaterial3D.new()
        mat.albedo_color = col.darkened(rng.randf_range(0.0, 0.3))
        mat.roughness = 0.8
        m.material_override = mat
        m.position = at + Vector3(rng.randf_range(-1.4, 1.4),
                rng.randf_range(-0.4, 0.6), rng.randf_range(-1.4, 1.4))
        frag_layer.add_child(m)
        var vel := Vector3(rng.randf_range(-7.0, 7.0), rng.randf_range(2.0, 11.0),
                rng.randf_range(-7.0, 7.0))
        var spin := Vector3(rng.randf_range(-6, 6), rng.randf_range(-6, 6),
                rng.randf_range(-6, 6))
        _frags.append({"node": m, "vel": vel, "spin": spin, "life": 1.1})

func _frags_tick(delta: float) -> void:
        var dead: Array = []
        for f in _frags:
                f["life"] = float(f["life"]) - delta
                if float(f["life"]) <= 0.0:
                        dead.append(f)
                        continue
                f["vel"] = (f["vel"] as Vector3) + Vector3(0, -38.0 * delta, 0)
                var n: MeshInstance3D = f["node"]
                n.position += (f["vel"] as Vector3) * delta
                if n.position.y < 0.15:
                        n.position.y = 0.15
                        f["vel"] = Vector3((f["vel"] as Vector3).x * 0.5, 0.0,
                                (f["vel"] as Vector3).z * 0.5)
                n.rotation += (f["spin"] as Vector3) * delta
        for f in dead:
                if f["node"] != null and is_instance_valid(f["node"]):
                        (f["node"] as MeshInstance3D).queue_free()
                _frags.erase(f)

## the one-shot spark (black clangs, colored chips)
func _spark(at: Vector3, col: Color) -> void:
        for i in 3:
                _spawn_frag(at, col.lightened(0.2))

# ------------------------------------------------------------------- input
# THE BOX LAW: 3D or 2D, the input road is TouchKit + the box key
# translation. HOLD TO FIRE: touch hold / LMB hold / SPACE / DOWN /
# gamepad X (or A). The ask screens ignore it all (their own buttons).

func _goga_input(event: InputEvent) -> void:
        if event is InputEventKey:
                var k := (event as InputEventKey).keycode
                var p := (event as InputEventKey).pressed
                match k:
                        KEY_SPACE, KEY_DOWN:
                                key_hold = p
                        KEY_1, KEY_KP_1:
                                if p and phase == "players":
                                        _pick_players(1)
                        KEY_2, KEY_KP_2:
                                if p and phase == "players":
                                        _pick_players(2)
                        KEY_3, KEY_KP_3:
                                if p and phase == "players":
                                        _pick_players(3)
                        KEY_4, KEY_KP_4:
                                if p and phase == "players":
                                        _pick_players(4)
        elif event is InputEventJoypadButton:
                var jb := (event as InputEventJoypadButton).button_index
                var jp := (event as InputEventJoypadButton).pressed
                if jb == JOY_BUTTON_X or jb == JOY_BUTTON_A:
                        pad_hold = jp
        elif event is InputEventMouseButton \
                        and (event as InputEventMouseButton).button_index \
                        == MOUSE_BUTTON_LEFT:
                holding = (event as InputEventMouseButton).pressed

func _on_press(_pos: Vector2) -> void:
        holding = true

func _on_release(_pos: Vector2) -> void:
        holding = false

func _pick_players(count: int) -> void:
        players = count
        Box.set_progress(game_id, "players", players)
        Jukebox.sfx("td_click", -6.0)
        _show_ready_card()

func _goga_tk_ready() -> void:
        if tk == null:
                return
        tk.press_started.connect(_on_press)
        tk.press_ended.connect(_on_release)

# ================================================================ the shop

func _shop_open() -> void:
        if over:
                return
        Jukebox.sfx("td_click", -6.0)
        var sheet := sheet_push(0.0, "shop")
        var t := Arc.label("TOWER DESTROYER SHOP", 34, Arc.INK)
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
        box.add_child(Arc.fit_label("CANNON SKINS", 24, Arc.HOT, 560))
        for s in TD.CANNON_SKINS:
                box.add_child(_skin_row("skin_cannon", s,
                        func(): _apply_cannon_skins()))
        box.add_child(Arc.fit_label("BALL SKINS", 24, Arc.HOT, 560))
        for s in TD.BALL_SKINS:
                box.add_child(_skin_row("skin_ball", s, func(): pass))
        var back := Arc.button("CLOSE", Vector2(560, 72), 26, Arc.GOOD,
                func(): sheet_pop())
        sheet.add_child(back)
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

## THE SHELF LAWS (the goldminer shape): the ON row, buys refresh in
## place, the shop SELLS and the game APPLIES live, dry wallets disabled.
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
                                Jukebox.sfx("td_click", -4.0)
                                apply.call()
                                _shop_reopen())
        var b := Arc.coin_button("%s  %d" % [s["name"], price],
                Vector2(560, 64), 22, Arc.ACCENT, func():
                        if Box.buy_item(game_id, cat, id, price):
                                Jukebox.sfx("coin", -4.0)
                                Box.equip_item(game_id, cat, id)
                                apply.call()
                        _shop_reopen())
        if Box.coins() < price:
                b.disabled = true
        return b

func _shop_reopen() -> void:
        sheet_pop()
        _shop_open()
