extends GogaGame
## GEOMETRY FLASH (v0.3.6) - the owner's endless neon side-scroller.
## GDD: docs/goga_docs/gogames_ideas/geometry.md - PGB v1.3.8 sketch reborn.
## Asset study: Geometry Dash Lite 2.2.147 via tools/study (THE USAGE LAW:
## every texture is an original redesign, every sound synthesized - see
## tools/v036_gf_art.py + tools/v036_gf_sfx.py).
##
## THE OWNER'S LAWS (binding, from the GDD message):
##   - THE TAP LAW: touch = jump. That is the whole verb (plus the mechanic).
##   - THE LAYOUT LAW (the drawing): roof + ground + THREE line surfaces
##     between, each gap fits the square; jump apex clears the next line
##     "by a little distance" so you land ON a line or clip its underside.
##   - THE STANDPOINT LAW: the square lives BEFORE center (x = 0.32w);
##     a survived push drifts back there, never further - reaction time.
##   - THE PUSHER LAW: road blocks SHOVE, never kill; you can still jump;
##     pushed off-screen = the end ("out-of-screen from a block").
##   - THE PIT LAW: the ground AND the roof have opened stretches - fall
##     into one and the run ends (the roof pits matter in flip modes).
##   - THE ORBIT LAW: golden orbits = +1 score each; every 10 = speed x1.1;
##     both wear widgets; the mechanic chip sits next to them.
##   - THE COIN LAW: the GOGACoin appears 30-50s after the LAST APPEAR
##     (the next delay rolls from 30/35/40/45/50), not from the collection.
##   - THE HIDDEN MECHANIC LAW: three verbs - NORMAL (jump), FLIP (tap
##     anywhere anytime = gravity inverts; you sail up-up-up, stick to the
##     roof, tap again to drop through), STICKY (tap ON a surface = the
##     jump flips gravity WITH the leap - you arc off and stick far side;
##     mid-air taps do nothing). Durations roll 10/20/30/40s, the next
##     mechanic + its clock are HIDDEN - the chip + a soft flash reveal
##     the swap the moment it happens.
##   - THE SPIN LAW: a jump rotates the square 90 degrees smoothly over the
##     PREDICTED flight (sampled against the scrolling world each jump) -
##     the animation and the VFX breathe with distance and time.
##   - THE FAIRNESS LAWS: every pit is jumpable at the current speed; solid
##     ground >= 2 cells after any pit; a pusher never shares its window
##     with a pit or a hazard; orbit arcs clear their pit; the run opens
##     with a calm runway and every mechanic swap gets ~1.4s of calm.
##   - NO FACES on the square. Neon that feels FILLED. Gentle glow.
##
## Probe contract: phase/mechanic/world_x/speed/orbits arrays are public,
## rng is seeded via reset(seed), _do_action() drives the verb directly,
## gen_calm()/_chunk_at() expose the generator, solids/orbits/hazards/pushers
## are plain arrays - every law above is assertable headless.

const DIR := "res://assets/games/geometry/"

# ---------------- the layout law (design px @ 1080 height, scaled by US) ---
const ROOF_Y := 300.0        # the roof strip's underside (the flip floor)
const L3_Y := 460.0          # top line
const L2_Y := 620.0          # middle line
const L1_Y := 780.0          # first line (the jump-reachable one)
const GROUND_Y := 940.0      # the ground surface
const LINE_TH := 28.0        # platform line thickness
const CELL := 84.0           # the square's side
const HALF := CELL * 0.5
const STAND_FRAC := 0.32     # the standpoint, before center by a good gap

# ---------------- physics (design px/s) ------------------------------------
const GRAV := 3400.0
const JUMP_V := 1180.0       # apex = 1180^2/(2*3400) = 204.7 design px
const MAX_FALL := 2500.0
const BASE_SPEED := 430.0
const SPEED_STEP := 1.1      # x1.1 per 10 orbits (the owner's law)
const DRIFT_BACK := 250.0    # px/s homing to the standpoint after a shove
const PUSH_EXTRA := 90.0     # extra px/s the pusher carries you back
const FLIP_MIN_GAP := 0.09   # s - flip debounce

# ---------------- content tables -------------------------------------------
const THEMES := {
        "midnight": {"name": "MIDNIGHT", "price": 0,
                "top": Color(0.030, 0.045, 0.11), "mid": Color(0.055, 0.07, 0.16),
                "bot": Color(0.015, 0.025, 0.06), "line": Color(0.14, 0.20, 0.42),
                "world": Color(0.88, 0.94, 1.06), "haz": Color(1.0, 0.55, 0.62),
                "deco": Color(0.55, 0.72, 1.0), "flash": Color(0.75, 0.88, 1.0),
                "desc": "the calm blue neon"},
        "solar": {"name": "SOLAR", "price": 280,
                "top": Color(0.10, 0.05, 0.02), "mid": Color(0.16, 0.09, 0.03),
                "bot": Color(0.05, 0.02, 0.01), "line": Color(0.45, 0.24, 0.08),
                "world": Color(1.06, 0.94, 0.82), "haz": Color(1.0, 0.45, 0.35),
                "deco": Color(1.0, 0.72, 0.40), "flash": Color(1.0, 0.85, 0.60),
                "desc": "the amber heat"},
        "violet": {"name": "VIOLET RUSH", "price": 420,
                "top": Color(0.06, 0.02, 0.10), "mid": Color(0.10, 0.04, 0.17),
                "bot": Color(0.03, 0.01, 0.06), "line": Color(0.30, 0.14, 0.50),
                "world": Color(1.0, 0.88, 1.08), "haz": Color(1.0, 0.50, 0.95),
                "deco": Color(0.85, 0.55, 1.0), "flash": Color(0.95, 0.75, 1.0),
                "desc": "the deep magenta pulse"},
}
const SKINS := {
        "classic": {"name": "CLASSIC", "price": 0, "col": Color(0.38, 0.89, 1.0),
                "desc": "the cyan soul"},
        "ember": {"name": "EMBER", "price": 140, "col": Color(1.0, 0.62, 0.32),
                "desc": "the warm one"},
        "toxin": {"name": "TOXIN", "price": 190, "col": Color(0.66, 1.0, 0.43),
                "desc": "the acid green"},
        "ghost": {"name": "GHOST", "price": 240, "col": Color(0.92, 0.96, 1.0),
                "desc": "the pale light"},
        "prism": {"name": "PRISM", "price": 320, "col": Color(1.0, 0.47, 0.92),
                "desc": "the pink violet"},
}
const TAILS := {
        "none": {"name": "NONE", "price": 0, "desc": "clean - no trail"},
        "neon": {"name": "NEON", "price": 160, "desc": "a cyan light ribbon"},
        "fire": {"name": "FIRE", "price": 230, "desc": "you burn backwards"},
        "rainbow": {"name": "RAINBOW", "price": 330, "desc": "the whole spectrum"},
        "gold": {"name": "GOLD", "price": 270, "desc": "gold sparks"},
        "match": {"name": "MATCH", "price": 290, "desc": "your own color"},
}
const MECH_DURS := [10, 20, 30, 40]          # the hidden clock rolls
const COIN_DELAYS := [30, 35, 40, 45, 50]    # from the LAST APPEAR

# ---------------- state -----------------------------------------------------
var phase := "ready"            # ready | run
var us := 1.0                   # the design->screen unit (vp.y / 1080)
var rng := RandomNumberGenerator.new()
var world_x := 0.0              # scrolled design px
var speed := BASE_SPEED
var speed_level := 0
var gen_x := 0.0                # generator cursor (design px, world space)
var calm_until := 0.0           # world_x that must stay hazard-free
var mechanic := "normal"
var mech_left := 10.0
var last_mech := "normal"
var flip_cd := 0.0
var orbits := []                # [{x, y, spr, tw, t, taken}]
var hazards := []               # [{x, y, kind, spr, r}]
var pushers := []               # [{x, y0, y1, spr}]  (world px box)
var gsegs := []                 # ground segments [{x0, x1, spr}]
var rsegs := []                 # roof segments [{x0, x1, spr}]
var lines := []                 # line segs [{x0, x1, y, spr}]
var coin := {}                  # {x, y, spr, t} or {}
var coin_timer := 0.0
var player := {"x": 0.0, "y": GROUND_Y - HALF, "vy": 0.0, "g": 1, "ground": true,
        "rot": 0.0, "sq": 1.0}
var stand_x := 0.0              # screen px standpoint
var orbit_streak := 0
var orbit_cool := 0.0
var run_t := 0.0
var mech_seen := {"normal": true, "flip": false, "sticky": false}
var trail_mode := "none"
var shake := 0.0
var over_gate := false          # the run ended - visuals only

# nodes
var bg: ColorRect
var bg_mat: ShaderMaterial
var world: Node2D               # everything that scrolls (theme-tinted)
var deco_a: Node2D
var deco_b: Node2D
var flash_rect: ColorRect
var flash_mat: ShaderMaterial
var pspr: Sprite2D              # the square
var tail: CPUParticles2D
var ready_ui: Control
var ready_ring: Sprite2D
var mech_chip: PanelContainer
var mech_icon: TextureRect
var speed_label: Label = null
var mech_label: Label = null    # the swap banner under the chip
var mech_label_t := 0.0
var tex := {}                   # name -> Texture2D
var beat_t := 0.0

func _tex(p: String) -> Texture2D:
        if not tex.has(p):
                tex[p] = load(DIR + p)
        return tex[p]

func _vp() -> Vector2:
        return get_viewport_rect().size

# =================================================================== setup
func _goga_setup() -> void:
        rng.randomize()
        game_id = "geometry"
        var vp := _vp()
        us = vp.y / 1080.0
        stand_x = vp.x * STAND_FRAC
        player["x"] = stand_x
        player["y"] = (GROUND_Y - HALF) * us     # SCREEN px - the us truth
        _build_world()
        _build_hud_extra()
        _load_meta()
        _build_ready()
        Jukebox.music("res://assets/audio/music/gf_theme.ogg")
        _seed_world()
        _gen_ahead()

func _load_meta() -> void:
        trail_mode = "none"
        var sid := Box.skin_on(game_id)
        if sid == "":
                sid = "classic"
        var skin_id := sid if SKINS.has(sid) else "classic"
        player["skin"] = skin_id
        pspr_set_skin()
        var tid := Box.item_on(game_id, "tail")
        if tid == "" or not TAILS.has(tid):
                tid = "none"
        trail_mode = tid

func pspr_set_skin() -> void:
        var sid: String = player.get("skin", "classic")
        pspr.texture = _tex("skin_%s.png" % sid)
        var art := 160.0 * 0.72                  # the drawn square inside the png
        var s := (CELL * us) / art
        pspr.scale = Vector2(s, s)

# =================================================================== world
func _build_world() -> void:
        # THE BG (shader, gentle)
        bg = ColorRect.new()
        bg.size = _vp()
        bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
        bg_mat = ShaderMaterial.new()
        bg_mat.shader = load("res://game/games/geometry/fx/gf_bg.gdshader")
        bg.material = bg_mat
        add_child(bg)

        # parallax deco (two depths, theme-colored, soft)
        deco_a = Node2D.new()
        deco_b = Node2D.new()
        add_child(deco_a)
        add_child(deco_b)
        for i in 3:
                var s1 := Sprite2D.new()
                s1.texture = _tex(["deco_diamond.png", "deco_square.png", "deco_ring.png"][i])
                s1.position = Vector2(_vp().x * (0.22 + 0.3 * i), 1080.0 * us * (0.22 + 0.24 * i))
                s1.scale = Vector2.ONE * (0.9 + 0.25 * i) * us
                s1.modulate = _theme()["deco"]
                s1.modulate.a = 0.10
                deco_a.add_child(s1)
        for i in 2:
                var s2 := Sprite2D.new()
                s2.texture = _tex(["deco_ring.png", "deco_diamond.png"][i])
                s2.position = Vector2(_vp().x * (0.5 + 0.34 * i), 1080.0 * us * (0.7 - 0.3 * i))
                s2.scale = Vector2.ONE * 0.55 * us
                s2.modulate = _theme()["deco"]
                s2.modulate.a = 0.14
                deco_b.add_child(s2)

        # THE WORLD (scrolling, theme modulate on the whole branch)
        world = Node2D.new()
        add_child(world)

        # the tail FIRST (it renders UNDER the square - the trail truth)
        tail = CPUParticles2D.new()
        tail.emitting = false
        tail.amount = 30
        tail.lifetime = 0.6
        tail.local_coords = false
        tail.texture = _tex("p_dot.png")
        add_child(tail)

        # the square (NOT under the world modulate - skins keep their color)
        pspr = Sprite2D.new()
        add_child(pspr)
        pspr_set_skin()
        pspr.position = Vector2(player["x"], player["y"] * us)

        # the swap flash (above the world, below the HUD canvas)
        flash_rect = ColorRect.new()
        flash_rect.size = _vp()
        flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        flash_mat = ShaderMaterial.new()
        flash_mat.shader = load("res://game/games/geometry/fx/gf_swap.gdshader")
        flash_mat.set_shader_parameter("intensity", 0.0)
        flash_rect.material = flash_mat
        add_child(flash_rect)

        # NOW the theme can dress every layer it just met
        _apply_theme()
        _apply_tail()

func _theme() -> Dictionary:
        var tid := Box.item_on(game_id, "theme")
        if not THEMES.has(tid):
                tid = "midnight"
        return THEMES[tid]

func _apply_theme() -> void:
        var t := _theme()
        bg_mat.set_shader_parameter("col_top", t["top"])
        bg_mat.set_shader_parameter("col_mid", t["mid"])
        bg_mat.set_shader_parameter("col_bot", t["bot"])
        bg_mat.set_shader_parameter("line_col", t["line"])
        if world != null:
                world.modulate = t["world"]
        flash_mat.set_shader_parameter("flash_col", t["flash"])
        for d in [deco_a, deco_b]:
                if d != null:
                        for c in d.get_children():
                                c.modulate = t["deco"]
                                c.modulate.a = 0.10 if c.get_parent() == deco_a else 0.14

func _apply_tail() -> void:
        tail.color_ramp = null
        tail.color = Color(1, 1, 1, 1)
        tail.scale_amount_min = 0.6
        tail.scale_amount_max = 1.2
        match trail_mode:
                "neon":
                        tail.texture = _tex("p_dot.png")
                        tail.color = Color(0.4, 0.9, 1.0, 0.9)
                "fire":
                        tail.texture = _tex("p_flame.png")
                        tail.color = Color(1.0, 0.62, 0.2, 0.95)
                        tail.scale_amount_min = 0.8
                        tail.scale_amount_max = 1.5
                "rainbow":
                        tail.texture = _tex("p_dot.png")
                        var g := Gradient.new()
                        g.set_color(0, Color(1, 0.3, 0.3))
                        g.set_color(1, Color(0.4, 0.5, 1.0, 0.0))
                        g.add_point(0.25, Color(1.0, 0.85, 0.3))
                        g.add_point(0.5, Color(0.4, 1.0, 0.5))
                        g.add_point(0.75, Color(0.5, 0.5, 1.0))
                        tail.color_ramp = g
                "gold":
                        tail.texture = _tex("p_spark.png")
                        tail.color = Color(1.0, 0.85, 0.4, 1.0)
                        tail.scale_amount_min = 0.8
                        tail.scale_amount_max = 1.4
                "match":
                        tail.texture = _tex("p_dot.png")
                        tail.color = SKINS[player.get("skin", "classic")]["col"]
                        tail.color.a = 0.95
                _:
                        tail.texture = _tex("p_dot.png")
                        tail.color = Color(1, 1, 1, 0)

# =================================================================== HUD
func _build_hud_extra() -> void:
        speed_label = add_hud_chip("x1.00")
        # THE MECHANIC CHIP - the owner's "next to the widgets" law
        mech_chip = PanelContainer.new()
        var st := Arc.panel_style(Color(0, 0, 0, 0.4), 18)
        mech_chip.add_theme_stylebox_override("panel", st)
        mech_icon = TextureRect.new()
        mech_icon.texture = _tex("chip_normal.png")
        mech_icon.custom_minimum_size = Vector2(46, 46)
        mech_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        mech_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        mech_chip.add_child(mech_icon)
        _hud_row.add_child(mech_chip)
        _hud_row.move_child(mech_chip, _hud_row.get_child_count() - 2)
        add_hud_button("SHOP", func(): _shop_open())
        # the swap banner label (floats under the chip for a moment)
        mech_label = Arc.label("", 30, Color(1, 1, 1, 0))
        mech_label.position = Vector2(96, 84)
        _hud.add_child(mech_label)

func _show_mech_banner(txt: String) -> void:
        mech_label.text = txt
        mech_label_t = 2.0
        mech_label.modulate = Color(1, 1, 1, 0)

func _set_mech_chip() -> void:
        match mechanic:
                "flip":
                        mech_icon.texture = _tex("chip_flip.png")
                "sticky":
                        mech_icon.texture = _tex("chip_sticky.png")
                _:
                        mech_icon.texture = _tex("chip_normal.png")

# =================================================================== ready
func _build_ready() -> void:
        ready_ui = Control.new()
        ready_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
        ready_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _hud.add_child(ready_ui)
        var y_mid := (GROUND_Y - 260.0) * us
        ready_ring = Sprite2D.new()
        ready_ring.texture = _tex("tap_ring.png")
        ready_ring.position = Vector2(stand_x, y_mid)
        ready_ring.scale = Vector2.ONE * 1.4 * us
        ready_ring.modulate = _theme()["flash"]
        ready_ring.modulate.a = 0.55
        _hud.add_child(ready_ring)
        var l := Arc.label("TAP ANYWHERE TO START", 54, Color(1, 1, 1, 0.95))
        l.set_anchors_preset(Control.PRESET_TOP_WIDE)
        l.offset_top = y_mid - 170.0
        l.offset_bottom = y_mid - 80.0
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        ready_ui.add_child(l)
        var sub := Arc.label("jump - flip - stick to the beat", 28, Color(1, 1, 1, 0.55))
        sub.set_anchors_preset(Control.PRESET_TOP_WIDE)
        sub.offset_top = y_mid - 76.0
        sub.offset_bottom = y_mid - 30.0
        sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        ready_ui.add_child(sub)

func _ready_start() -> void:
        phase = "run"
        Jukebox.sfx("gf_start")
        if ready_ui != null:
                ready_ui.queue_free()
                ready_ui = null
        if ready_ring != null:
                ready_ring.queue_free()
                ready_ring = null
        tail.emitting = true

## THE OPENING LAW: solid world behind the start + THE CALM RUNWAY - the
## first ~6 seconds teach the feel before the first threat.
func _seed_world() -> void:
        _add_gseg(-1400.0, 0.0)
        _add_rseg(-1400.0, 0.0)
        gen_x = 0.0
        calm_until = world_x + BASE_SPEED * 6.0

# =================================================================== input
func _goga_input(event: InputEvent) -> void:
        if sheet_open_count() > 0:
                return
        if event is InputEventScreenTouch and event.pressed:
                if phase == "ready":
                        _ready_start()
                        return
                _do_action()

## THE TAP LAW - the one verb, per the live mechanic.
func _do_action() -> void:
        if phase != "run" or paused or over_gate:
                return
        match mechanic:
                "normal":
                        if player["ground"]:
                                _jump()
                "flip":
                        if flip_cd <= 0.0:
                                flip_cd = FLIP_MIN_GAP
                                _flip_gravity(0.42)
                "sticky":
                        if player["ground"]:
                                player["vy"] = -JUMP_V * us * float(player["g"])
                                _flip_gravity(1.0, true)
                                Jukebox.sfx("gf_sticky")

func _jump() -> void:
        player["vy"] = -JUMP_V * us * float(player["g"])
        player["ground"] = false
        Jukebox.sfx("gf_jump", -2.0)
        _plan_spin()
        _burst_at(Vector2(player["x"], player["y"] * us), 6, 0.5)

## THE FLIP - gravity inverts; a soft damp keeps the sail readable.
func _flip_gravity(damp: float, from_sticky := false) -> void:
        player["g"] = -int(player["g"])
        player["vy"] *= damp
        player["ground"] = false
        flip_total += 1
        if not from_sticky:
                Jukebox.sfx("gf_flip", -3.0)
                _burst_at(Vector2(player["x"], player["y"] * us), 10, 0.8)
        _plan_spin()

# =================================================================== tick
func _goga_tick(delta: float) -> void:
        beat_t += delta
        var pulse := 0.5 + 0.5 * sin(beat_t * TAU * (BPM_NOW / 60.0) / 2.0)
        bg_mat.set_shader_parameter("time_s", beat_t)
        bg_mat.set_shader_parameter("pulse", pulse if phase == "run" else pulse * 0.4)
        if mech_label_t > 0.0:
                mech_label_t -= delta
                var a: float = clampf(mech_label_t / 0.5, 0.0, 1.0)
                mech_label.modulate.a = a
        flip_cd = maxf(0.0, flip_cd - delta)
        if over_gate:
                return
        if phase == "ready":
                # the world breathes slowly behind the gate
                world_x += 60.0 * delta
                _layout_world()
                _idle_pulse(delta)
                return
        run_t += delta
        var dt := delta
        world_x += speed * dt
        _gen_ahead()
        _mech_clock(dt)
        _physics(dt)
        _pickups(dt)
        _coin_clock(dt)
        _layout_world()
        _fx_tick(dt)

const BPM_NOW := 124.0

## THE HIDDEN MECHANIC CLOCK - duration rolls 10/20/30/40, the next
## mechanic is a secret until the flash lands. Never the same twice.
func _mech_clock(dt: float) -> void:
        mech_left -= dt
        if mech_left > 0.0:
                return
        var pool := ["normal", "flip", "sticky"]
        pool.erase(last_mech)
        var next: String = pool[rng.randi_range(0, pool.size() - 1)]
        var dur := float(MECH_DURS[rng.randi_range(0, MECH_DURS.size() - 1)])
        mechanic = next
        mech_left = dur
        last_mech = next
        mech_seen[next] = true
        calm_until = world_x + speed * 1.4      # THE SWAP CALM LAW
        _set_mech_chip()
        _show_mech_banner({"normal": "NORMAL JUMP", "flip": "GRAVITY FLIP",
                "sticky": "STICKY LEAP"}[next])
        Jukebox.sfx("gf_swap", -2.0)
        flash_mat.set_shader_parameter("intensity", 1.0)
        var tw := flash_rect.create_tween()
        tw.tween_method(func(v): flash_mat.set_shader_parameter("intensity", v),
                1.0, 0.0, 0.55)

# ---------------------------------------------------------------- physics
func _physics(dt: float) -> void:
        var p := player
        # gravity - THE US TRUTH: the motion constants are design px/s, the
        # positions are screen px - every integration scales by us (the
        # tablets-at-1.33 floatiness the space-truth probe caught at 1.78)
        if not p["ground"]:
                p["vy"] += GRAV * us * float(p["g"]) * dt
                p["vy"] = clampf(p["vy"], -MAX_FALL * us, MAX_FALL * us)
        var prev_y: float = p["y"]
        p["y"] += p["vy"] * dt

        # the shove: while overlapping a pusher body you ride it back
        var pushed := _pusher_push(dt)

        # homing to the standpoint (never past it - the reaction gap)
        if not pushed and absf(p["x"] - stand_x) > 2.0 and p["y"] < GROUND_Y * us:
                var dir := 1.0 if p["x"] < stand_x else -1.0
                p["x"] += dir * minf(DRIFT_BACK * us * dt, absf(p["x"] - stand_x))

        # vertical resolve
        _vertical(prev_y)
        _support_check()

        # pits + edge + hazards
        _pit_check()
        if p["x"] < -HALF * us:
                _die("off screen")
                return
        _hazard_check()
        # the spin law rides gravity + landing
        _spin_tick(dt)
        if p["ground"]:
                _settle_rot()
        p["sq"] = minf(1.0, p["sq"] + dt * 6.0)

## THE SUPPORT TRUTH: grounded means SUPPORTED - walk off an edge and the
## fall (and its own spin plan) begins honestly.
func _support_check() -> void:
        var p := player
        if not p["ground"]:
                return
        var wx0: float = (p["x"] - HALF * us * 0.8) / us + world_x
        var wx1: float = (p["x"] + HALF * us * 0.8) / us + world_x
        var feet_y: float = p["y"] + HALF * us * float(p["g"])
        var has := false
        if p["g"] == 1:
                if absf(feet_y - GROUND_Y * us) < 2.0:
                        for s in gsegs:
                                if float(s["x0"]) <= wx1 and float(s["x1"]) >= wx0:
                                        has = true
                                        break
                if not has:
                        for l in lines:
                                if absf(feet_y - float(l["y"]) * us) < 2.0 \
                                                and float(l["x0"]) <= wx1 and float(l["x1"]) >= wx0:
                                        has = true
                                        break
                if not has:
                        for pu in pushers:
                                var rx0: float = float(pu["x"]) - world_x
                                if rx0 <= wx1 and rx0 + CELL >= wx0 \
                                                and absf(feet_y - float(pu["y0"]) * us) < 2.0:
                                        has = true
                                        break
        else:
                if absf(feet_y - ROOF_Y * us) < 2.0:
                        for s in rsegs:
                                if float(s["x0"]) <= wx1 and float(s["x1"]) >= wx0:
                                        has = true
                                        break
                if not has:
                        for l in lines:
                                var uy: float = (float(l["y"]) + LINE_TH) * us
                                if absf(feet_y - uy) < 2.0 \
                                                and float(l["x0"]) <= wx1 and float(l["x1"]) >= wx0:
                                        has = true
                                        break
                if not has:
                        for pu in pushers:
                                var rx0: float = float(pu["x"]) - world_x
                                if rx0 <= wx1 and rx0 + CELL >= wx0 \
                                                and absf(feet_y - float(pu["y1"]) * us) < 2.0:
                                        has = true
                                        break
        if not has:
                p["ground"] = false
                _plan_spin()

## THE PUSHER LAW: overlap rides you back (speed + extra); top landing is safe.
func _pusher_push(dt: float) -> bool:
        var p := player
        var pl := Rect2(p["x"] - HALF * us, p["y"] - HALF * us, CELL * us, CELL * us)
        for pu in pushers:
            var r := Rect2((pu["x"] - world_x) * us, pu["y0"] * us,
                        CELL * us, (pu["y1"] - pu["y0"]) * us)
            if pl.intersects(r):
                    # standing on top (or hanging under, flipped) never shoves
                    var on_top: bool = p["g"] == 1 and absf(p["y"] + HALF * us - pu["y0"] * us) < 6.0
                    var on_bot: bool = p["g"] == -1 and absf(p["y"] - HALF * us - pu["y1"] * us) < 6.0
                    if not on_top and not on_bot:
                            p["x"] -= (speed + PUSH_EXTRA) * us * dt
                            _spin_settle_pause()
                            return true
        return false

## Landing / bonking against every surface in the window.
## THE SPACE TRUTH: segments live in WORLD px, the player in SCREEN px -
## every overlap test converts with (x - world_x) * us (the off-screen
## landing bug the QA rig caught: raw world*us vs screen matched only while
## world_x was tiny, and the square could stand on ground that had already
## scrolled away).
func _vertical(prev_y: float) -> void:
        var p := player
        var g: int = p["g"]
        var px0: float = p["x"] - HALF * us
        var px1: float = p["x"] + HALF * us
        var feet_prev := prev_y + HALF * us
        var feet: float = p["y"] + HALF * us
        var head_prev := prev_y - HALF * us
        var head: float = p["y"] - HALF * us

        if g == 1:
                # land on: ground segs, line tops, pusher tops
                var best_y := -1.0
                for s in gsegs:
                        var sx0: float = (float(s["x0"]) - world_x) * us
                        var sx1: float = (float(s["x1"]) - world_x) * us
                        if sx0 <= px1 and sx1 >= px0:
                                if feet_prev <= GROUND_Y * us + 1.0 and feet >= GROUND_Y * us:
                                        best_y = maxf(best_y, GROUND_Y * us)
                for l in lines:
                        var sx0: float = (float(l["x0"]) - world_x) * us
                        var sx1: float = (float(l["x1"]) - world_x) * us
                        var ly: float = l["y"] * us
                        if sx0 <= px1 and sx1 >= px0:
                                if feet_prev <= ly + 1.0 and feet >= ly:
                                        best_y = maxf(best_y, ly)
                for pu in pushers:
                        var rx0: float = (float(pu["x"]) - world_x) * us
                        var rx1 := rx0 + CELL * us
                        if rx1 >= px0 and rx0 <= px1:
                                if feet_prev <= float(pu["y0"]) * us + 1.0 and feet >= float(pu["y0"]) * us:
                                        best_y = maxf(best_y, float(pu["y0"]) * us)
                if best_y >= 0.0:
                        _land_at(best_y, prev_y)
                        return
                # bonk: line undersides + the roof underside + pusher bottoms
                for l in lines:
                        var sx0: float = (float(l["x0"]) - world_x) * us
                        var sx1: float = (float(l["x1"]) - world_x) * us
                        var uy: float = (float(l["y"]) + LINE_TH) * us
                        if sx0 <= px1 and sx1 >= px0:
                                if head_prev >= uy - 1.0 and head <= uy and p["vy"] < 0.0:
                                        p["y"] = uy + HALF * us
                                        p["vy"] = 0.0
                                        return
                if head <= ROOF_Y * us:
                        p["y"] = ROOF_Y * us + HALF * us
                        p["vy"] = 0.0
                        return
        else:
                # flipped: land UNDER the roof, under line undersides, pusher bottoms
                var best_y := -1.0
                for s in rsegs:
                        var sx0: float = (float(s["x0"]) - world_x) * us
                        var sx1: float = (float(s["x1"]) - world_x) * us
                        if sx0 <= px1 and sx1 >= px0:
                                if head_prev >= ROOF_Y * us - 1.0 and head <= ROOF_Y * us:
                                        best_y = ROOF_Y * us
                for l in lines:
                        var sx0: float = (float(l["x0"]) - world_x) * us
                        var sx1: float = (float(l["x1"]) - world_x) * us
                        var uy: float = (float(l["y"]) + LINE_TH) * us
                        if sx0 <= px1 and sx1 >= px0:
                                if head_prev >= uy - 1.0 and head <= uy:
                                        best_y = maxf(best_y, uy)
                for pu in pushers:
                        var rx0: float = (float(pu["x"]) - world_x) * us
                        var rx1 := rx0 + CELL * us
                        if rx1 >= px0 and rx0 <= px1:
                                if head_prev >= float(pu["y1"]) * us - 1.0 and head <= float(pu["y1"]) * us:
                                        best_y = maxf(best_y, float(pu["y1"]) * us)
                if best_y >= 0.0:
                        _land_at(best_y, prev_y)
                        return
                # bonk downward onto ground segs / line tops
                for s in gsegs:
                        var sx0: float = (float(s["x0"]) - world_x) * us
                        var sx1: float = (float(s["x1"]) - world_x) * us
                        if sx0 <= px1 and sx1 >= px0:
                                if feet >= GROUND_Y * us and feet_prev <= GROUND_Y * us + 1.0 and p["vy"] > 0.0:
                                        p["y"] = GROUND_Y * us - HALF * us
                                        p["vy"] = 0.0
                                        return
                for l in lines:
                        var sx0: float = (float(l["x0"]) - world_x) * us
                        var sx1: float = (float(l["x1"]) - world_x) * us
                        var ly: float = l["y"] * us
                        if sx0 <= px1 and sx1 >= px0:
                                if feet >= ly and feet_prev <= ly + 1.0 and p["vy"] > 0.0:
                                        p["y"] = ly - HALF * us
                                        p["vy"] = 0.0
                                        return

func _land_at(surf_y: float, prev_y: float) -> void:
        var p := player
        var impact := absf(p["vy"])
        if p["g"] == 1:
                p["y"] = surf_y - HALF * us
        else:
                p["y"] = surf_y + HALF * us
        p["vy"] = 0.0
        if not p["ground"]:
                p["ground"] = true
                p["sq"] = 0.72 if impact > 900.0 * us else 0.85
                Jukebox.sfx("gf_land", -8.0 if impact < 1200.0 * us else -4.0)
                _burst_at(Vector2(p["x"], p["y"] * us + (HALF * us * p["g"])),
                        4 + int(impact / (500.0 * us)), clampf(impact / (2600.0 * us), 0.3, 1.2))

## THE PIT LAW: inside an opened stretch past the surface = the fall ends it.
func _pit_check() -> void:
        var p := player
        var px: float = p["x"] / us + world_x
        if p["g"] == 1 and p["y"] > (GROUND_Y + CELL * 0.9) * us:
                if not _ground_under(px):
                        _die("pit")
        elif p["g"] == -1 and p["y"] < (ROOF_Y - CELL * 0.9) * us:
                if not _roof_under(px):
                        _die("pit")

func _ground_under(wx: float) -> bool:
        for s in gsegs:
                if wx >= s["x0"] and wx <= s["x1"]:
                        return true
        return false

func _roof_under(wx: float) -> bool:
        for s in rsegs:
                if wx >= s["x0"] and wx <= s["x1"]:
                        return true
        return false

func _hazard_check() -> void:
        var p := player
        var box := Rect2(p["x"] - HALF * us * 0.62, p["y"] - HALF * us * 0.62,
                CELL * us * 0.62, CELL * us * 0.62)
        for h in hazards:
                if h.get("taken", false):
                        continue
                var hx: float = (h["x"] - world_x) * us
                if absf(hx - p["x"]) > 140.0 * us:
                        continue
                var hr: float = h["r"] * us
                var hbox := Rect2(hx - hr, h["y"] * us - hr, hr * 2.0, hr * 2.0)
                if box.intersects(hbox):
                        _die("hazard")
                        return

# ------------------------------------------------------------- THE SPIN LAW
var spin_left := 0.0
var spin_total := 0.4
var spin_dir := 1.0
var spin_hold := 0.0

## Predict the flight against the SCROLLING world; rotate 90deg over it.
## Short hops snap, long sails glide - the animation breathes with time.
func _plan_spin() -> void:
        var p := player
        var g: float = float(p["g"])
        var vy: float = p["vy"]
        var y0: float = p["y"] / us
        var steps := 72
        var t_land := 0.55
        for i in range(1, steps + 1):
                var t := 1.5 * float(i) / float(steps)
                var y := y0 + vy / us * t + 0.5 * GRAV * g * t * t
                var wx := world_x + speed * t
                if _flight_lands(y, wx, g):
                        t_land = t
                        break
        spin_left = t_land
        spin_total = t_land
        spin_dir = float(p["g"])
        spin_hold = 0.0

func _flight_lands(y_feet_base: float, wx: float, g: float) -> bool:
        # feet position = y_feet_base + HALF (sign by gravity)
        var feet := y_feet_base + HALF * g
        if g == 1:
                if feet >= GROUND_Y and _ground_under(wx):
                        return true
                for l in lines:
                        if wx >= l["x0"] and wx <= l["x1"] and feet >= l["y"] and feet <= l["y"] + LINE_TH * 2.0:
                                return true
        else:
                if feet <= ROOF_Y and _roof_under(wx):
                        return true
                for l in lines:
                        var uy: float = l["y"] + LINE_TH
                        if wx >= l["x0"] and wx <= l["x1"] and feet <= uy and feet >= uy - LINE_TH * 2.0:
                                return true
        return false

func _spin_tick(dt: float) -> void:
        var p := player
        if p["ground"]:
                return
        if spin_left > 0.0:
                spin_left -= dt
                var prog := 1.0 - clampf(spin_left / maxf(0.0001, spin_total), 0.0, 1.0)
                var eased := 1.0 - pow(1.0 - prog, 2.4)          # ease-out glide
                if spin_hold <= 0.0:
                        p["rot"] = floorf(p["rot"] / 90.0) * 90.0 + eased * 90.0 * spin_dir
        # (the tail breathes through its fixed amount - the trail length is
        # the honest dynamic signal here)

func _spin_settle_pause() -> void:
        spin_hold = 0.12

func _settle_rot() -> void:
        var p := player
        var nearest := roundf(p["rot"] / 90.0) * 90.0
        p["rot"] = lerpf(p["rot"], nearest, 0.55)

# ------------------------------------------------------------- pickups
func _pickups(dt: float) -> void:
        var p := player
        orbit_cool = maxf(0.0, orbit_cool - dt)
        var collected: Array = []
        for o in orbits:
                if o.get("taken", false):
                        continue
                var ox: float = (o["x"] - world_x) * us
                if absf(ox - p["x"]) > 120.0 * us:
                        continue
                var oy: float = o["y"] * us
                if Vector2(ox, oy).distance_to(Vector2(p["x"], p["y"])) <= 58.0 * us:
                        o["taken"] = true
                        o["spr"].queue_free()
                        o["tw"].queue_free()
                        collected.append(o)
                        orbit_streak += 1
                        orbit_cool = 1.1
                        var pitch := 0.92 + 0.055 * minf(float(orbit_streak), 9.0)
                        Jukebox.sfx("gf_orbit", -4.0, pitch)
                        add_score(1)
                        _spark_at(Vector2(ox, oy))
                        if score % 10 == 0:
                                speed_level += 1
                                speed = BASE_SPEED * pow(SPEED_STEP, float(speed_level))
                                if speed_label != null:
                                        speed_label.text = "x%.2f" % (speed / BASE_SPEED)
                                Jukebox.sfx("gf_speed", -6.0)
        # the taken orbits leave the array NOW (a queue_free'd sprite must
        # never meet the next _layout_world - the freed-sprite lesson)
        for o in collected:
                orbits.erase(o)

## THE COIN LAW - 30/35/40/45/50s from the LAST APPEAR.
func _coin_clock(dt: float) -> void:
        coin_timer -= dt
        if coin_timer <= 0.0 and coin.is_empty():
                _coin_spawn()
                coin_timer = float(COIN_DELAYS[rng.randi_range(0, COIN_DELAYS.size() - 1)])
        if not coin.is_empty():
                coin["t"] = float(coin["t"]) + dt
                var cx: float = (float(coin["x"]) - world_x) * us
                var cy: float = float(coin["y"]) * us + sin(coin["t"] * 3.0) * 10.0 * us
                coin["spr"].position = Vector2(cx, cy)
                var p := player
                if Vector2(cx, cy).distance_to(Vector2(p["x"], p["y"])) <= 64.0 * us:
                        add_run_coins(1)
                        Jukebox.sfx("gf_coin")
                        _spark_at(Vector2(cx, cy), Color(1.0, 0.85, 0.4))
                        coin["spr"].queue_free()
                        coin = {}

func _coin_spawn() -> void:
        var vp := _vp()
        # a reachable lane: just over a line, or mid-air in a wide gap
        var lanes := [L1_Y - 150.0, L2_Y - 150.0, L3_Y - 150.0, GROUND_Y - 190.0]
        var y: float = lanes[rng.randi_range(0, lanes.size() - 1)]
        var spr := Sprite2D.new()
        spr.texture = load("res://assets/ui/coin.png")
        var halo := Sprite2D.new()
        halo.texture = _tex("p_glow.png")
        halo.modulate = Color(1.0, 0.8, 0.3, 0.55)
        halo.scale = Vector2.ONE * 1.5
        spr.add_child(halo)
        spr.scale = Vector2.ONE * (64.0 / 96.0) * us
        spr.position = Vector2(vp.x + 80.0, y * us)
        world.add_child(spr)
        coin = {"x": world_x + vp.x / us + 80.0 / us, "y": y, "spr": spr, "t": 0.0}

# ------------------------------------------------------------- death
func _die(_why: String) -> void:
        if over_gate or phase != "run":
                return
        over_gate = true
        tail.emitting = false
        Jukebox.sfx("gf_death")
        _death_burst()
        achievement_max("max_score", score)
        achievement_count("orbits", score)
        achievement_count("flips", flip_total)
        if mech_seen["flip"] and mech_seen["sticky"]:
                achievement_count("triple", 1)
        check_achievements()
        var t := get_tree().create_timer(0.62)
        t.timeout.connect(func():
                finish_run(score))

var flip_total := 0

# =================================================================== GEN
## THE GENERATOR - endless chunk stitching. Every builder honors THE
## FAIRNESS LAWS; weights tighten with the speed level; roof content only
## spawns when the live mechanic can actually reach it.
func _gen_ahead() -> void:
        var vp := _vp()
        var horizon := world_x + vp.x / us + 1800.0
        while gen_x < horizon:
                gen_x += _gen_chunk(gen_x)

func _level() -> int:
        return speed_level

func _max_pit_cells() -> float:
        # full hop air distance in cells, shrunk to a fair 62%
        var air_t := 2.0 * JUMP_V / GRAV
        var air_d := speed * air_t / CELL
        return clampf(air_d * 0.62, 1.7, 6.0)

func _add_gseg(x0: float, x1: float) -> void:
        gsegs.append({"x0": x0, "x1": x1, "spr": null})
func _add_rseg(x0: float, x1: float) -> void:
        rsegs.append({"x0": x0, "x1": x1, "spr": null})
func _add_line(x0: float, x1: float, y: float) -> void:
        lines.append({"x0": x0, "x1": x1, "y": y, "spr": null})

func _add_orbit(x: float, y: float) -> void:
        var spr := Sprite2D.new()
        spr.texture = _tex("orbit.png")
        spr.scale = Vector2.ONE * 0.5 * us
        var tw := Sprite2D.new()
        tw.texture = _tex("tw_0.png")
        tw.scale = Vector2.ONE * 0.8 * us
        tw.position = Vector2(20, -22) * us
        spr.add_child(tw)
        world.add_child(spr)
        orbits.append({"x": x, "y": y, "spr": spr, "tw": tw, "t": rng.randf() * 3.0,
                "taken": false})

func _orbit_line(x0: float, y: float, n: int, step := CELL * 1.6) -> void:
        for i in n:
                _add_orbit(x0 + step * i, y)

func _orbit_arc(x0: float, w: float, base_y: float, dir := 1.0) -> void:
        # a jump arc over a pit of width w starting at x0 (dir -1 = under the roof)
        var n := maxi(3, int(w / (CELL * 0.9)))
        for i in n:
                var t := float(i) / float(n - 1)
                var x := x0 + w * t
                var y := base_y - dir * (sin(t * PI) * 170.0 + 60.0)
                _add_orbit(x, y)

func _add_pusher(x: float, surface: float, tall := false, up := true) -> void:
        var h := (CELL * 2.0) if tall else CELL
        var y0 := surface - h if up else surface
        var y1 := surface if up else surface + h
        var spr := Sprite2D.new()
        spr.texture = _tex("pusher.png")
        spr.scale = Vector2.ONE * 0.5 * us
        if tall:
                var s2 := Sprite2D.new()
                s2.texture = _tex("pusher.png")
                s2.scale = Vector2.ONE * 0.5 * us
                s2.position = Vector2(0, (-CELL * 0.5) if up else (CELL * 0.5)) * us
                spr.add_child(s2)
        world.add_child(spr)
        pushers.append({"x": x, "y0": y0, "y1": y1, "spr": spr})

func _add_hazard(x: float, y: float, kind: String) -> void:
        var spr := Sprite2D.new()
        var r := 34.0
        spr.texture = _tex("spike.png")
        spr.scale = Vector2.ONE * 0.5 * us
        if kind == "saw":
                spr.texture = _tex("saw.png")
                r = 38.0
        if kind == "spike_down":
                spr.rotation = PI
        world.add_child(spr)
        hazards.append({"x": x, "y": y, "kind": kind, "spr": spr, "r": r})

## A calm breath: flat ground + a welcome line of orbits.
func _gen_calm(x: float) -> float:
        var w := CELL * 7.0
        _add_gseg(x, x + w)
        _add_rseg(x, x + w)
        _orbit_line(x + CELL * 1.5, GROUND_Y - 190.0, 4)
        return w

## One chunk at the cursor; returns its width. THE WEIGHTS: the level
## tightens the mix; flip/sticky unlock the roof play.
func _gen_chunk(x: float) -> float:
        if world_x < calm_until and gen_x < calm_until:
                return _gen_calm(x)
        var lvl := _level()
        var pool: Array = []
        var w_flat := maxi(6, 14 - lvl)
        for i in w_flat:
                pool.append("flat")
        for i in mini(8, 2 + lvl):
                pool.append("pit")
        for i in mini(7, 1 + lvl):
                pool.append("push")
        for i in mini(7, 1 + lvl):
                pool.append("spikes")
        for i in mini(8, 2 + lvl):
                pool.append("lines")
        if lvl >= 2:
                for i in mini(4, lvl - 1):
                        pool.append("weave")
        if lvl >= 3:
                for i in mini(3, lvl - 2):
                        pool.append("saw")
        if mechanic != "normal":
                for i in mini(6, 2 + lvl):
                        pool.append("roof")
        var pick: String = pool[rng.randi_range(0, pool.size() - 1)]
        match pick:
                "pit":
                        return _chunk_pit(x)
                "push":
                        return _chunk_push(x)
                "spikes":
                        return _chunk_spikes(x)
                "lines":
                        return _chunk_lines(x)
                "weave":
                        return _chunk_weave(x)
                "saw":
                        return _chunk_saw(x)
                "roof":
                        return _chunk_roof(x)
                _:
                        return _chunk_flat(x)

func _chunk_flat(x: float) -> float:
        var w := CELL * rng.randf_range(6.0, 9.0)
        _add_gseg(x, x + w)
        _add_rseg(x, x + w)
        if rng.randf() < 0.7:
                var ly: float = [L1_Y - 150.0, L2_Y - 150.0, GROUND_Y - 190.0][rng.randi_range(0, 2)]
                _orbit_line(x + CELL, ly, rng.randi_range(3, 5))
        return w

func _chunk_pit(x: float) -> float:
        var lead := CELL * rng.randf_range(2.5, 4.0)
        var pit := CELL * rng.randf_range(1.8, _max_pit_cells())
        var tail_run := CELL * rng.randf_range(3.0, 4.5)     # THE 2-CELL LANDING LAW
        _add_gseg(x, x + lead)
        _add_rseg(x, x + lead + pit + tail_run)
        _orbit_arc(x + lead, pit, GROUND_Y)
        if _level() >= 4 and rng.randf() < 0.35:
                # the combo lesson: a pusher right after the pit's landing
                var px := x + lead + pit + tail_run + CELL * 1.2
                _add_gseg(x + lead + pit + tail_run, px + CELL * 5.0)
                _add_pusher(px, GROUND_Y, false)
                _orbit_line(px + CELL * 2.0, GROUND_Y - 250.0, 3)
                return px + CELL * 5.0 - x
        _add_gseg(x + lead + pit, x + lead + pit + tail_run)
        return lead + pit + tail_run

func _chunk_push(x: float) -> float:
        var n := rng.randi_range(1, mini(3, 1 + _level()))
        var cx := x + CELL * 2.0
        _add_gseg(x, cx + n * CELL * 5.0)
        _add_rseg(x, cx + n * CELL * 5.0)
        for i in n:
                _add_pusher(cx + i * CELL * 5.0, GROUND_Y, i == n - 1 and _level() >= 3)
                _orbit_line(cx + i * CELL * 5.0 + CELL * 1.6, GROUND_Y - 260.0, 2)
        return cx + n * CELL * 5.0 - x     # the segs end where the chunk ends -
                                           # no phantom cell of world hole

func _chunk_spikes(x: float) -> float:
        var n := rng.randi_range(1, mini(3, 1 + _level()))
        var cx := x + CELL * 2.0
        var step := CELL * rng.randf_range(3.0, 4.2)        # the rhythm window
        _add_gseg(x, cx + n * step + CELL * 4.0)
        _add_rseg(x, cx + n * step + CELL * 4.0)
        for i in n:
                _add_hazard(cx + i * step, GROUND_Y - CELL * 0.5, "spike")
                _add_orbit(cx + i * step - CELL * 0.2, GROUND_Y - 250.0)
                _add_orbit(cx + i * step + CELL * 0.8, GROUND_Y - 240.0)
        return cx + n * step + CELL * 4.0 - x

func _chunk_lines(x: float) -> float:
        var w := CELL * rng.randf_range(5.0, 8.0)
        var y: float = [L1_Y, L2_Y, L3_Y][rng.randi_range(0, 2)]
        var x0 := x + CELL * 1.5
        _add_gseg(x, x + w)
        _add_rseg(x, x + w)
        _add_line(x0, x0 + w - CELL * 2.0, y)
        _orbit_line(x0 + CELL, y - 120.0, maxi(2, int(w / CELL) - 3), CELL * 1.5)
        if _level() >= 2 and rng.randf() < 0.45:
                var hx := x0 + w - CELL * 2.6
                _add_hazard(hx, y - CELL * 0.5, "spike")
        return w

func _chunk_weave(x: float) -> float:
        var w := CELL * rng.randf_range(9.0, 12.0)
        _add_gseg(x, x + w)
        _add_rseg(x, x + w)
        var y_a := L1_Y
        var y_b := L2_Y
        _add_line(x + CELL, x + w * 0.45, y_a)
        _add_line(x + w * 0.55, x + w - CELL, y_b)
        # the safe zigzag teaches the lane rhythm
        var n := 6
        for i in n:
                var t := float(i) / float(n - 1)
                var ox: float = x + CELL * 1.5 + (w - CELL * 3.0) * t
                var oy: float = lerpf(y_a - 130.0, y_b - 130.0, snappedf(t, 0.5))
                _add_orbit(ox, oy)
        if rng.randf() < 0.6:
                _add_hazard(x + w * 0.5, GROUND_Y - CELL * 0.5, "spike")
        return w

func _chunk_saw(x: float) -> float:
        var w := CELL * rng.randf_range(7.0, 9.0)
        _add_gseg(x, x + w)
        _add_rseg(x, x + w)
        var y: float = [L2_Y - 210.0, L1_Y - 220.0, GROUND_Y - 320.0][rng.randi_range(0, 2)]
        var sx := x + w * 0.5
        _add_hazard(sx, y, "saw")
        _add_orbit(sx - CELL * 1.7, y)
        _add_orbit(sx + CELL * 1.7, y)
        return w

## THE ROOF PLAY - only in flip/sticky: roof pits, roof pushers, hanging spikes.
func _chunk_roof(x: float) -> float:
        var w := CELL * rng.randf_range(7.0, 10.0)
        _add_gseg(x, x + w)
        if rng.randf() < 0.5:
                # the roof pit: ride the roof, drop through the lane, land back
                var lead := CELL * rng.randf_range(2.0, 3.0)
                var pit := CELL * rng.randf_range(1.8, _max_pit_cells())
                _add_rseg(x, x + lead)
                _add_rseg(x + lead + pit, x + w)
                _orbit_arc(x + lead, pit, ROOF_Y, -1.0)
        else:
                _add_rseg(x, x + w)
                var px := x + w * 0.45
                _add_pusher(px, ROOF_Y, false, false)
                _orbit_line(px - CELL * 2.2, ROOF_Y + 200.0, 3)
                if rng.randf() < 0.5:
                        _add_hazard(px + CELL * 2.4, ROOF_Y + CELL * 0.5, "spike_down")
        return w

# =================================================================== render
## Sync every object's sprite to the scroll + cull what fell behind.
func _layout_world() -> void:
        var vp := _vp()
        var kill_x := world_x - 1000.0
        # strips
        for s in gsegs:
                _sync_strip(s, false)
        for s in rsegs.duplicate():
                _sync_strip(s, true)
        for l in lines:
                if l["spr"] == null:
                        var sp := Sprite2D.new()
                        sp.texture = _tex("line.png")
                        sp.region_enabled = true
                        sp.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
                        sp.scale = Vector2(0.5 * us, 0.5 * us)
                        world.add_child(sp)
                        l["spr"] = sp
                var lw_tex: float = (float(l["x1"]) - float(l["x0"])) * 2.0   # texture is 2x design
                l["spr"].region_rect = Rect2(0, 0, lw_tex, 56)
                l["spr"].position = Vector2((float(l["x0"] + float(l["x1"])) * 0.5 - world_x) * us,
                        float(l["y"]) * us + LINE_TH * 0.5 * us)
        for pu in pushers:
                if pu["spr"].get_parent() == null:
                        world.add_child(pu["spr"])
                pu["spr"].position = Vector2((pu["x"] - world_x) * us + CELL * 0.5 * us,
                        (pu["y0"] + CELL * 0.5) * us)
        for h in hazards:
                h["spr"].position = Vector2((h["x"] - world_x) * us, h["y"] * us)
                if h["kind"] == "saw":
                        h["spr"].rotation += 0.06
        for o in orbits:
                o["spr"].position = Vector2((o["x"] - world_x) * us, o["y"] * us)
                o["t"] += 0.016
                o["tw"].texture = _tex("tw_%d.png" % (int(o["t"] * 8.0) % 4))
        if not coin.is_empty():
                pass  # the coin positions itself in _coin_clock
        # cull behind
        _cull(gsegs, kill_x, "x1")
        _cull(rsegs, kill_x, "x1")
        _cull(lines, kill_x, "x1")
        _cull_arr(pushers, kill_x + CELL * 4.0)
        _cull_arr(hazards, kill_x + CELL * 4.0)
        _cull_arr(orbits, kill_x + CELL * 2.0)
        # the square
        var p := player
        _spin_tick(0.016 if phase == "run" else 0.0)
        pspr.position = Vector2(p["x"] + (rng.randf() - 0.5) * shake,
                p["y"] * us + (rng.randf() - 0.5) * shake)
        pspr.rotation_degrees = p["rot"]
        var base_s: float = (CELL * us) / (160.0 * 0.72)
        pspr.scale = Vector2(base_s * (2.0 - p["sq"]), base_s * p["sq"])
        tail.position = pspr.position
        shake = maxf(0.0, shake - 1.4)
        # parallax
        var tpx := fmod(world_x * 0.25 * us, vp.x + 700.0)
        deco_a.position = Vector2(-tpx * 0.4, 0)
        deco_b.position = Vector2(-fmod(world_x * 0.5 * us, vp.x + 700.0) * 0.5, 0)

func _sync_strip(s: Dictionary, roof: bool) -> void:
        if s["spr"] == null:
                var sp := Sprite2D.new()
                sp.texture = _tex("strip.png")
                sp.region_enabled = true
                sp.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
                sp.scale = Vector2(0.5 * us, 0.5 * us)
                if roof:
                        sp.flip_v = true
                world.add_child(sp)
                s["spr"] = sp
        var w_tex: float = (float(s["x1"]) - float(s["x0"])) * 2.0    # texture is 2x design
        s["spr"].region_rect = Rect2(0, 0, w_tex, 600)
        var cx := (float(s["x0"]) + float(s["x1"])) * 0.5
        if roof:
                # the strip HANGS from the top: its bright edge sits ON ROOF_Y
                s["spr"].position = Vector2((cx - world_x) * us,
                        (ROOF_Y - 150.0) * us)
                s["spr"].flip_v = true
        else:
                s["spr"].position = Vector2((cx - world_x) * us,
                        (GROUND_Y + 150.0) * us)
                s["spr"].flip_v = false

func _cull(arr: Array, kill_x: float, key: String) -> void:
        for i in range(arr.size() - 1, -1, -1):
                var s: Dictionary = arr[i]
                if float(s[key]) < kill_x:
                        if s.get("spr") != null and is_instance_valid(s["spr"]):
                                s["spr"].queue_free()
                        arr.remove_at(i)

func _cull_arr(arr: Array, kill_x: float) -> void:
        for i in range(arr.size() - 1, -1, -1):
                var s: Dictionary = arr[i]
                if float(s["x"]) < kill_x:
                        if s.get("spr") != null and is_instance_valid(s["spr"]):
                                s["spr"].queue_free()
                        arr.remove_at(i)

# =================================================================== FX
func _burst_at(pos: Vector2, n: int, power: float) -> void:
        var p := CPUParticles2D.new()
        p.texture = _tex("p_burst.png")
        p.amount = maxi(4, n * 3)
        p.one_shot = true
        p.explosiveness = 1.0
        p.lifetime = 0.4
        p.direction = Vector2(0, -1)
        p.spread = 180.0
        p.initial_velocity_min = 120.0 * power * us
        p.initial_velocity_max = 340.0 * power * us
        p.gravity = Vector2(0, 900.0 * us)
        p.scale_amount_min = 0.3
        p.scale_amount_max = 0.8 * (0.6 + power)
        p.color = SKINS[player.get("skin", "classic")]["col"]
        p.position = pos
        p.emitting = true
        add_child(p)
        get_tree().create_timer(1.0).timeout.connect(func(): if is_instance_valid(p): p.queue_free())

func _spark_at(pos: Vector2, col := Color(1.0, 0.85, 0.4)) -> void:
        var p := CPUParticles2D.new()
        p.texture = _tex("p_spark.png")
        p.amount = 7
        p.one_shot = true
        p.explosiveness = 1.0
        p.lifetime = 0.35
        p.spread = 180.0
        p.initial_velocity_min = 60.0 * us
        p.initial_velocity_max = 200.0 * us
        p.scale_amount_min = 0.4
        p.scale_amount_max = 0.9
        p.color = col
        p.position = pos
        p.emitting = true
        add_child(p)
        var r := Sprite2D.new()
        r.texture = _tex("p_ring.png")
        r.position = pos
        r.scale = Vector2.ONE * 0.2 * us
        r.modulate = col
        r.modulate.a = 0.8
        add_child(r)
        var tw := r.create_tween()
        tw.set_parallel(true)
        tw.tween_property(r, "scale", Vector2.ONE * 1.1 * us, 0.3)
        tw.tween_property(r, "modulate:a", 0.0, 0.3)
        tw.chain().tween_callback(func():
                r.queue_free()
                if is_instance_valid(p):
                        p.queue_free())

func _death_burst() -> void:
        var p := player
        var pos := Vector2(p["x"], p["y"] * us)
        shake = 14.0
        _burst_at(pos, 16, 1.6)
        _burst_at(pos, 10, 1.0)
        var col: Color = SKINS[player.get("skin", "classic")]["col"]
        var shards := CPUParticles2D.new()
        shards.texture = _tex("p_shard.png")
        shards.amount = 12
        shards.one_shot = true
        shards.explosiveness = 1.0
        shards.lifetime = 0.7
        shards.spread = 180.0
        shards.initial_velocity_min = 260.0 * us
        shards.initial_velocity_max = 640.0 * us
        shards.gravity = Vector2(0, 1500.0 * us)
        shards.angular_velocity_min = -540.0
        shards.angular_velocity_max = 540.0
        shards.scale_amount_min = 0.5
        shards.scale_amount_max = 1.1
        shards.color = col
        shards.position = pos
        shards.emitting = true
        add_child(shards)
        pspr.visible = false
        get_tree().create_timer(1.2).timeout.connect(func():
                if is_instance_valid(shards):
                        shards.queue_free())

func _idle_pulse(delta: float) -> void:
        if ready_ring != null and is_instance_valid(ready_ring):
                var s := (1.25 + 0.18 * sin(beat_t * 4.0)) * us
                ready_ring.scale = Vector2.ONE * s
                ready_ring.modulate.a = 0.4 + 0.25 * sin(beat_t * 4.0)
        var p := player
        p["y"] = (GROUND_Y - HALF) * us + sin(beat_t * 2.4) * 6.0 * us
        pspr.position = Vector2(p["x"], p["y"])
        pspr.rotation_degrees = 0.0

func _fx_tick(_dt: float) -> void:
        pass  # all per-frame fx live in _layout_world today

# =================================================================== shop
var shop_id := ""

## THE SHOP - skins / themes / tails (buy-only law: a buy OWNS, the
## equip is its own tap - the CS lesson, kept forever).
func _shop_open() -> void:
        if shop_id != "":
                return
        shop_id = "shop"
        if phase == "run":
                paused = true
                get_tree().paused = true
        var sheet := sheet_push(0.0, "shop")
        var t := Arc.label("GEOMETRY SHOP", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := _vp()
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.52, 300.0, 640.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        box.add_child(_shop_label("SKINS - the square's soul"))
        for id in SKINS:
                box.add_child(_skin_row(id))
        box.add_child(_shop_label("THEMES - the world's light"))
        for id in THEMES:
                box.add_child(_theme_row(id))
        box.add_child(_shop_label("TAILS - buy once, toggle forever"))
        for id in TAILS:
                box.add_child(_tail_row(id))
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                func(): sheet_pop()))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _goga_sheet_popped(id: String) -> void:
        if id == "shop":
                shop_id = ""
                if phase == "run":
                        get_tree().paused = false
                        paused = false
                _load_meta()
                _apply_theme()
                _apply_tail()

func _shop_label(txt: String) -> Label:
        return Arc.fit_label(txt, 24, Arc.HOT, 560)

func _price_btn(txt: String, price: int, col: Color, cb: Callable) -> Button:
        var b := Arc.coin_button("%s  %d" % [txt, price], Vector2(560, 64), 22, col, cb)
        if Box.coins() < price:
                b.disabled = true
        return b

func _skin_row(id: String) -> Control:
        var c: Dictionary = SKINS[id]
        var owned := Box.skin_owned(game_id, id) or int(c["price"]) == 0
        var on: bool = Box.skin_on(game_id) == id \
                or (int(c["price"]) == 0 and Box.skin_on(game_id) == "")
        if on:
                var l := Arc.fit_label("%s  (ON) - %s" % [c["name"], c["desc"]], 22,
                        Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        if owned:
                return Arc.button("%s - WEAR" % c["name"], Vector2(560, 60), 22,
                        Color("4a5ab8"), func():
                                Box.equip_skin(game_id, id)
                                player["skin"] = id
                                Jukebox.sfx("confirm", -4.0)
                                pspr_set_skin()
                                _apply_tail()
                                _shop_reopen())
        return _price_btn(c["name"], int(c["price"]), Color("4a5ab8"), func():
                if Box.buy_skin(game_id, id, int(c["price"])):
                        Jukebox.sfx("buy")
                _shop_reopen())

## THE BUY-ONLY LAW, as one callable: the box layer auto-equips on buy,
## but the live world must NOT retheme mid-run - the worn light stays;
## LIGHT IT is its own tap. (The shop row + the probe both ride this.)
func _buy_theme(id: String) -> bool:
        var worn := Box.item_on(game_id, "theme")      # BEFORE the buy
        if not Box.buy_item(game_id, "theme", id, int(THEMES[id]["price"])):
                return false
        if worn == "" or not THEMES.has(worn):
                Box.unequip_item(game_id, "theme")
        else:
                Box.equip_item(game_id, "theme", worn)
        return true

func _theme_row(id: String) -> Control:
        var c: Dictionary = THEMES[id]
        var owned := Box.item_owned(game_id, "theme", id) or int(c["price"]) == 0
        var on: bool = Box.item_on(game_id, "theme") == id \
                or (int(c["price"]) == 0 and Box.item_on(game_id, "theme") == "")
        if on:
                var l := Arc.fit_label("%s  (ON) - %s" % [c["name"], c["desc"]], 22,
                        Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        if owned:
                return Arc.button("%s - LIGHT IT" % c["name"], Vector2(560, 60), 22,
                        Color("2a7a68"), func():
                                Box.equip_item(game_id, "theme", id)
                                Jukebox.sfx("confirm", -4.0)
                                _apply_theme()
                                _shop_reopen())
        return _price_btn(c["name"], int(c["price"]), Color("2a7a68"), func():
                if _buy_theme(id):
                        Jukebox.sfx("buy")
                _apply_theme()
                _shop_reopen())

func _tail_row(id: String) -> Control:
        var c: Dictionary = TAILS[id]
        if id == "none":
                var on_now := Box.item_on(game_id, "tail") in ["", "none"]
                if on_now:
                        var l0 := Arc.fit_label("%s  (ON)" % c["name"], 22, Color("58c470"), 560)
                        l0.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        return l0
                return Arc.button("%s - TRAIL OFF" % c["name"], Vector2(560, 60), 22,
                        Color("7a5a3a"), func():
                                Box.equip_item(game_id, "tail", "none")
                                Jukebox.sfx("confirm", -4.0)
                                _shop_reopen())
        if not Box.item_owned(game_id, "tail", id):
                return _price_btn("%s (%s)" % [c["name"], c["desc"]], int(c["price"]),
                        Color("8a4ab8"), func():
                                if Box.buy_item(game_id, "tail", id, int(c["price"])):
                                        Jukebox.sfx("buy")
                                _shop_reopen())
        if Box.item_on(game_id, "tail") == id:
                return Arc.button("%s  -  TURN OFF" % c["name"], Vector2(560, 60), 22,
                        Color("7a5a3a"), func():
                                Box.equip_item(game_id, "tail", "none")
                                Jukebox.sfx("confirm", -4.0)
                                _shop_reopen())
        return Arc.button("%s  -  TURN ON" % c["name"], Vector2(560, 60), 22,
                Color("8a4ab8"), func():
                        Box.equip_item(game_id, "tail", id)
                        Jukebox.sfx("confirm", -4.0)
                        _shop_reopen())

## THE REFRESH LAW - a buy rebuilds the SAME sheet.
func _shop_reopen() -> void:
        if shop_id != "":
                sheet_pop()
                _shop_open.call_deferred()

# =================================================================== probe
## The headless contract: a deterministic run any probe can drive.
func probe_reset(seed_v: int) -> void:
        rng.seed = seed_v
        for arr in [orbits, hazards, pushers, gsegs, rsegs, lines]:
                for o in arr:
                        if o.get("spr") != null and is_instance_valid(o["spr"]):
                                o["spr"].queue_free()
                arr.clear()
        if not coin.is_empty() and is_instance_valid(coin["spr"]):
                coin["spr"].queue_free()
        coin = {}
        world_x = 0.0
        gen_x = 0.0
        calm_until = 0.0
        speed = BASE_SPEED
        speed_level = 0
        score = 0
        set_score(0)
        mechanic = "normal"
        last_mech = "normal"
        mech_left = 10.0
        mech_seen = {"normal": true, "flip": false, "sticky": false}
        flip_total = 0
        orbit_streak = 0
        over_gate = false
        phase = "run"
        coin_timer = 1e9          # the probe spawns coins explicitly
        player["x"] = stand_x
        player["y"] = (GROUND_Y - HALF) * us     # SCREEN px
        player["vy"] = 0.0
        player["g"] = 1
        player["ground"] = true
        player["rot"] = 0.0
        paused = true             # THE PROBE CLOCK: the game only moves when
                                  # the probe steps it - no tick races
        _seed_world()
        _gen_ahead()
        _layout_world()

## Step the world without rendering pressure (the probe's clock).
func probe_step(dt: float) -> void:
        _goga_tick(dt)



