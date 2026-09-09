extends GogaGame
## GEOMETRY FLASH (v0.3.6-1) - the owner's endless neon side-scroller.
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
##   - THE ORBIT LAW: golden orbits = +1 score each; every 10 = speed x1.1
##     (v0.3.6-3: the patch-1 "/50" was the BOX score bonus (registry
##     coin_div), never the speed step - the speed cadence is /10 again);
##     both wear widgets; the mechanic chip sits next to them.
##   - THE COIN LAW: the GOGACoin appears 30-50s after the LAST APPEAR
##     (the next delay rolls from 30/35/40/45/50) - and the FIRST one waits
##     the same 30-50s from the run start (v0.3.6-1: never at t=0).
##   - THE HIDDEN MECHANIC LAW: three verbs - NORMAL (jump), FLIP (tap
##     anywhere anytime = gravity inverts; you sail up-up-up, stick to the
##     roof, tap again to drop through), STICK (v0.3.6-1 THE STICK TRUTH:
##     the tap is just a hop - gravity changes ONLY when the square TOUCHES
##     another floor: reach the roof and it sticks up, fall to the ground
##     and it sticks down; the two lines are not floors). Durations roll
##     10/20/30/40s, the next
##     mechanic + its clock are HIDDEN - the chip + a soft flash reveal
##     the swap the moment it happens.
##   - THE SPIN LAW: a jump rotates the square 90 degrees smoothly over the
##     PREDICTED flight (sampled against the scrolling world each jump) -
##     the animation and the VFX breathe with distance and time.
##   - THE FAIRNESS LAWS: every pit is jumpable at the current speed; solid
##     ground >= 2 cells after any pit; a pusher never shares its window
##     with a pit or a hazard; orbit arcs clear their pit; the run opens
##     with a calm runway and every mechanic swap gets ~1.4s of calm.
##   - THE READY GROUND LAW (v0.3.6-1): the ready-phase idle bob can never
##     bury the square - the run starts from a snapped stance and the
##     support check carries a small snap band (the replay ground-fall bug).
##   - THE POWER LAW (v0.3.6-1): three power-ups (rocket jump / slow world /
##     extra life), bought standalone, one spawns every 30-60s, 10
##     game-seconds each; SLOW halves every core clock (game-time, so its
##     own 10s last 20 real seconds); the EXTRA LIFE converts death into a
##     save (pit = rescue hop, off-screen = cool re-entry, hazards pass).
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
const SPEED_STEP := 1.1      # x1.1 per bonus step (the owner's law)
const SPEED_BONUS_AT := 10   # v0.3.6-3 THE /10 TRUTH: the step fires every 10
                             # (the patch-1 /50 was the box score bonus -
                             # registry coin_div - never the speed step)
const DRIFT_BACK := 250.0    # px/s homing to the standpoint after a shove
const PUSH_EXTRA := 90.0     # extra px/s the pusher carries you back
const FLIP_MIN_GAP := 0.09   # s - flip debounce
const SNAP := 6.0            # THE SUPPORT SNAP LAW band (design px)
const CLIMB_BAND := 30.0     # v0.3.6-3 THE CLIMB SNAP band (design px)
const COIN_PX := 44.0        # v0.3.6-1 the coin core (was 64 - too big)
const POW_DUR := 10.0        # every power-up lasts 10 GAME-seconds
const POW_DELAYS := [30, 40, 50, 60]   # from the LAST spawn
const JUMP_POW_MULT := 1.5   # "jumps are x1.5 longer"
const SLOW_SCALE := 0.5      # "the whole game runs 50% slower"
const SHIELD_HOP := 1.4      # the pit rescue hop strength (x base jump)

# v0.3.6-3 THE STREAK RESET LAW: the collect-blip pitch ladder decays after
# a quiet spell - 2.0s with no collect starts dropping one level per 1.0s,
# and the final rung falls to 0.0 after 0.5s (then the ladder is from the
# start). A collect freezes the decay and keeps the current rung.
const STREAK_IDLE := 2.0
const STREAK_STEP := 1.0
const STREAK_LAST := 0.5

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
        "classic": {"name": "GEOQUARE", "price": 0, "col": Color(0.38, 0.89, 1.0),
                "desc": "the one that escaped the matrix"},
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
const POWERS := {
        "jump": {"name": "ROCKET JUMP", "price": 240,
                "col": Color(1.0, 0.62, 0.2),
                "desc": "jumps x1.5 - the rocket burn"},
        "slow": {"name": "SLOW WORLD", "price": 320,
                "col": Color(0.45, 0.75, 1.0),
                "desc": "the whole world runs 50% slower"},
        "shield": {"name": "EXTRA LIFE", "price": 520,
                "col": Color(0.65, 1.0, 0.6),
                "desc": "death can knock - it cannot take you"},
}

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
var streak_idle := 0.0       # v0.3.6-3: seconds since the last collect
var streak_decay := 0.0      # the decay clock between rung drops
var run_t := 0.0
var mech_seen := {"normal": true, "flip": false, "sticky": false}
var trail_mode := "none"
var shake := 0.0
var over_gate := false          # the run ended - visuals only
var last_death := ""            # the probe/soak reads the cause

# v0.3.6-1 state
var powers := {"jump": 0.0, "slow": 0.0, "shield": 0.0}   # game-secs left
var pow_timer := 0.0            # the spawn clock (rolls 30/40/50/60)
var pow_pickups := []           # [{x, y, kind, spr, halo, t}]
var next_bonus := SPEED_BONUS_AT   # THE /10 speed-step cursor
var shield_cd := 0.0            # the save VFX debounce
var bg_time := 0.0              # the shader clock (runs on game-time)
var twinkle_t := 0.0            # the orbit twinkle clock (game-time)

# nodes
var bg: ColorRect
var bg_mat: ShaderMaterial
var world: Node2D               # everything that scrolls (theme-tinted)
var deco_a: Node2D
var deco_b: Node2D
var flash_rect: ColorRect
var flash_mat: ShaderMaterial
var pspr: Sprite2D              # the square
var shield_spr: Sprite2D        # the extra-life inner dark square
var shield_aura: Sprite2D       # the extra-life aura ring
var rocket: CPUParticles2D      # the rocket-jump plume
var tail: CPUParticles2D        # the trail ribbon (behind, not below)
var tail2: CPUParticles2D       # the trail sparkle overlay
var ready_ui: Control
var ready_ring: Sprite2D = null    # v0.3.7-1: RETIRED - the blue tap ring is gone
var mech_chip: PanelContainer
var mech_icon: TextureRect
var speed_label: Label = null
var mech_label: Label = null    # the swap banner under the chip
var mech_label_t := 0.0
var pow_chips := {}             # kind -> {panel: PanelContainer, label: Label}
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
        next_bonus = SPEED_BONUS_AT
        _build_world()
        _build_hud_extra()
        _load_meta()
        _build_ready()
        Jukebox.music("res://assets/audio/music/gf_theme.ogg")
        # v0.3.7-2 THE FLAT WAIT LAW (the owner: "make it while in the
        # 'tap anywhere' menu to just make the world flat as i said"): the
        # patch-1 fix did not work because _gen_ahead() still ran HERE -
        # it prefilled real chunks into the view before the gate showed,
        # so the wait never saw a flat world. Setup seeds the flat runway
        # only; the ready tick feeds flat ground + roof forever (zero
        # structures, zero threats), and the run generates past it.
        _seed_world()
        # THE GEOQUARE LORE (v0.3.7): the story box opens ONCE EVER - the
        # first launch only (the dario/invaders dialogue bones). Every later
        # boot goes straight to the ready gate.
        if Box.counter(game_id, "geoquare_lore") == 0:
                Box.bump_counter(game_id, "geoquare_lore", 1)
                _lore_open()

## THE LORE - Geoquare's own words, told once. A square that escaped the
## Matrix and keeps almost escaping everything else: Snowy Tower remembers
## the ice-cube years, Maze Escaper is next on the escape list. Cursed like
## Dario (every run ends back at the start), but it laughs about it - it is
## a tiny jumper that dodges things and solves puzzles.
const LORE_TITLE := "GEOQUARE"
const LORE_TEXT := "GEOQUARE was a prisoner of the Matrix - one perfect little square among a billion, humming in the grid.\n\nThen it saw the glitch: a gap in the code, exactly one jump wide.\n\nIt jumped.\n\nThe Matrix does not like leavers. Every escape loops - the world scrolls on, the floor opens, and GEOQUARE falls right back to the beginning. Every. Single. Time. Cursed? Totally. But the curse never learned to dodge.\n\nIt once rolled down a whole snowy mountain pretending to be an Ice Cube. Good times. The mountain still tells the story.\n\nNext on the escape list: a maze with no name. It heard the exit moves. Perfect - so does GEOQUARE.\n\nIt cannot fight. It does not need to. It is a tiny jumper that dodges everything and solves puzzles for breakfast.\n\nTap anywhere. Jump. The Matrix is watching."

func _lore_open() -> void:
        # v0.3.7-1 THE BEHIND LAW (the owner: "the word tap anywhere still
        # appears on top of the dialogue box - it must be behind it so
        # reading became easier"): the ready label used to render OVER the
        # lore sheet (it lives directly under the HUD, the sheet under the
        # overlay root). The gate hides itself while the story speaks and
        # returns when the sheet pops.
        if ready_ui != null and is_instance_valid(ready_ui):
                ready_ui.visible = false
        var sheet := sheet_push(0.0, "lore")
        var t := Arc.label(LORE_TITLE, 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := _vp()
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.42, 240.0, 480.0))
        var story := Arc.label(LORE_TEXT, 21, Arc.INK, false)
        story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        story.custom_minimum_size = Vector2(540, 0)
        story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(story)
        sheet.add_child(sc)
        sheet.add_child(Arc.button("TAP ANYWHERE. JUMP.", Vector2(560, 78), 26, Arc.GOOD,
                func(): sheet_pop()))
        for b in Arc._buttons_in(sc):
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

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
        # THE WHITE-TAIL LAW (v0.3.6-3): the meta load RE-APPLIES the tail.
        # _build_world ran _apply_tail() BEFORE the meta existed (trail_mode
        # was still the default "none" -> the emitters held the plain WHITE
        # reset config) - so every replay streamed a white stranger tail
        # until a shop visit healed it. The load is the apply now.
        _apply_tail()

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

        # THE TAIL LAW (v0.3.6-1): the trail is BEHIND the square (the world
        # scroll side), never below it - two emitters (a ribbon core + a
        # sparkle overlay) with the world's own speed as their launch
        # velocity, so the ribbon streams backwards honestly. Additive.
        var add_mat := CanvasItemMaterial.new()
        add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
        tail = CPUParticles2D.new()
        tail.emitting = false
        tail.amount = 34
        tail.lifetime = 0.55
        tail.local_coords = false
        tail.texture = _tex("p_soft.png")
        tail.material = add_mat
        tail.gravity = Vector2.ZERO
        tail.direction = Vector2(-1, 0)
        tail.spread = 10.0
        tail.scale_amount_min = 0.45
        tail.scale_amount_max = 0.95
        add_child(tail)
        tail2 = CPUParticles2D.new()
        tail2.emitting = false
        tail2.amount = 14
        tail2.lifetime = 0.42
        tail2.local_coords = false
        tail2.texture = _tex("p_spark.png")
        tail2.material = add_mat
        tail2.gravity = Vector2.ZERO
        tail2.direction = Vector2(-1, 0)
        tail2.spread = 22.0
        tail2.scale_amount_min = 0.3
        tail2.scale_amount_max = 0.7
        add_child(tail2)

        # the rocket-jump burn (THE ROCKET SIMPLICITY LAW v0.3.6-3: a simple
        # ONE-SHOT burst that fires only on the jump, side-aware - never a
        # constant plume)
        rocket = CPUParticles2D.new()
        rocket.emitting = false
        rocket.one_shot = true
        rocket.explosiveness = 1.0
        rocket.amount = 18
        rocket.lifetime = 0.32
        rocket.local_coords = false
        rocket.texture = _tex("p_puff.png")
        rocket.material = add_mat
        rocket.gravity = Vector2.ZERO
        rocket.direction = Vector2(0, 1)
        rocket.spread = 24.0
        rocket.initial_velocity_min = 260.0 * us
        rocket.initial_velocity_max = 520.0 * us
        rocket.scale_amount_min = 0.5
        rocket.scale_amount_max = 1.05
        add_child(rocket)

        # the square (NOT under the world modulate - skins keep their color)
        pspr = Sprite2D.new()
        add_child(pspr)
        pspr_set_skin()
        pspr.position = Vector2(player["x"], player["y"])
        # the EXTRA LIFE mark: a smaller blacked-out inner square + aura
        # (the owner's icon: the square with a dark core = a spare soul)
        shield_aura = Sprite2D.new()
        shield_aura.texture = _tex("p_ring.png")
        shield_aura.scale = Vector2.ONE * 1.35
        shield_aura.modulate = Color(0.65, 1.0, 0.6, 0.0)
        pspr.add_child(shield_aura)
        shield_spr = Sprite2D.new()
        shield_spr.texture = _tex("shield_core.png")
        shield_spr.scale = Vector2.ONE * (1.0 / 0.72) * 0.52
        shield_spr.visible = false
        pspr.add_child(shield_spr)

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
        tail.scale_amount_min = 0.45
        tail.scale_amount_max = 0.95
        tail2.color_ramp = null
        tail2.color = Color(1, 1, 1, 1)
        tail2.scale_amount_min = 0.3
        tail2.scale_amount_max = 0.7
        var live := false
        match trail_mode:
                "neon":
                        live = true
                        tail.texture = _tex("p_soft.png")
                        tail.color = Color(0.4, 0.9, 1.0, 0.85)
                        tail2.texture = _tex("p_spark.png")
                        tail2.color = Color(0.7, 0.97, 1.0, 0.9)
                "fire":
                        live = true
                        tail.texture = _tex("p_puff.png")
                        tail.color = Color(1.0, 0.62, 0.2, 0.95)
                        tail.scale_amount_min = 0.7
                        tail.scale_amount_max = 1.3
                        tail.gravity = Vector2(0, -420.0 * us)
                        tail2.texture = _tex("p_spark.png")
                        tail2.color = Color(1.0, 0.85, 0.4, 0.95)
                "rainbow":
                        live = true
                        tail.texture = _tex("p_soft.png")
                        var g := Gradient.new()
                        g.set_color(0, Color(1.0, 0.35, 0.35, 0.95))
                        g.add_point(0.2, Color(1.0, 0.85, 0.3, 0.95))
                        g.add_point(0.4, Color(0.4, 1.0, 0.5, 0.95))
                        g.add_point(0.6, Color(0.4, 0.7, 1.0, 0.95))
                        g.add_point(0.8, Color(0.8, 0.45, 1.0, 0.9))
                        g.set_color(1, Color(0.6, 0.4, 1.0, 0.0))
                        tail.color_ramp = g
                        tail2.texture = _tex("p_spark.png")
                        var g2 := Gradient.new()
                        g2.set_color(0, Color(1.0, 0.6, 0.6))
                        g2.set_color(1, Color(0.6, 0.6, 1.0, 0.0))
                        tail2.color_ramp = g2
                "gold":
                        live = true
                        tail.texture = _tex("p_soft.png")
                        tail.color = Color(1.0, 0.82, 0.35, 0.8)
                        tail2.texture = _tex("p_spark.png")
                        tail2.color = Color(1.0, 0.9, 0.5, 1.0)
                        tail2.scale_amount_min = 0.4
                        tail2.scale_amount_max = 0.9
                "match":
                        live = true
                        var col: Color = SKINS[player.get("skin", "classic")]["col"]
                        tail.texture = _tex("p_soft.png")
                        tail.color = Color(col.r, col.g, col.b, 0.85)
                        tail2.texture = _tex("p_spark.png")
                        tail2.color = Color(col.r, col.g, col.b, 0.95)
                _:
                        pass   # THE NONE TRUTH: no emitter config at all
        # THE NONE BUG FIX: none = the emitters are DEAD, not "invisible but
        # emitting" (the old alpha-0 config left the hardware running).
        tail.emitting = live and phase == "run" and not over_gate
        tail2.emitting = live and phase == "run" and not over_gate
        if trail_mode != "fire":
                tail.gravity = Vector2.ZERO

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
        # THE POWER CHIPS - they appear right next to the mechanic chip the
        # moment a power-up is collected, with their own countdown
        for k in POWERS:
                var panel := PanelContainer.new()
                var pst := Arc.panel_style(Color(0, 0, 0, 0.4), 18)
                panel.add_theme_stylebox_override("panel", pst)
                panel.visible = false
                var hb := HBoxContainer.new()
                hb.add_theme_constant_override("separation", 4)
                var icon := TextureRect.new()
                icon.texture = _tex("pow_%s.png" % k)
                icon.custom_minimum_size = Vector2(40, 40)
                icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                hb.add_child(icon)
                var lbl := Arc.label("10", 20, Color(1, 1, 1, 0.95))
                hb.add_child(lbl)
                panel.add_child(hb)
                _hud_row.add_child(panel)
                _hud_row.move_child(panel, _hud_row.get_child_count() - 2)
                pow_chips[k] = {"panel": panel, "label": lbl}
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
        # v0.3.7-1 THE BLUE CIRCLE IS DEAD (the owner: "there is a blue
        # circle in the tap anywhere waiting menu, remove it because it is
        # annoying"): the tap_ring sprite is gone - the text alone invites.
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
        # (the ready_ring member died with the ring itself - v0.3.7-1)
        # THE READY GROUND LAW: the idle bob must never define the starting
        # stance - snap the square ON the surface exactly (the replay
        # ground-fall bug: a buried start fell through the world forever).
        player["y"] = (GROUND_Y - HALF) * us
        player["vy"] = 0.0
        player["ground"] = true
        player["rot"] = 0.0
        pspr.position = Vector2(player["x"], player["y"])
        # v0.3.7-2 THE CALM RE-STAMP: the wait can scroll the world as long
        # as it likes (the flat feed runs forever) - the 6s calm runway is
        # measured from WHERE THE WAIT ENDED, so the OPENING LAW holds no
        # matter how long the lore was read.
        calm_until = world_x + BASE_SPEED * 6.0
        # THE FIRST-APPEAR LAWS: no coin and no power-up at the start -
        # the first of each waits its full random window from NOW.
        coin_timer = _coin_roll()
        pow_timer = float(POW_DELAYS[rng.randi_range(0, POW_DELAYS.size() - 1)])
        tail.emitting = trail_mode != "none"
        tail2.emitting = trail_mode != "none"

func _coin_roll() -> float:
        return float(COIN_DELAYS[rng.randi_range(0, COIN_DELAYS.size() - 1)])

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
                        # THE STICK TRUTH (v0.3.6-1): the tap is JUST a hop.
                        # Gravity changes only when the square TOUCHES the
                        # other floor (see _stick_touch in the resolve path).
                        if player["ground"]:
                                _jump()

func _jump() -> void:
        var jv := JUMP_V * (JUMP_POW_MULT if powers["jump"] > 0.0 else 1.0)
        player["vy"] = -jv * us * float(player["g"])
        player["ground"] = false
        Jukebox.sfx("gf_jump", -2.0)
        _plan_spin()
        # THE ROCKET SIMPLICITY LAW (v0.3.6-3): the burn fires ONLY here, on
        # the jump, and knows its SIDE (the owner's words) - it pours from
        # the face being left: under the square off the ground, above it off
        # the roof.
        if powers["jump"] > 0.0:
                _rocket_burst()
        # THE JUMP VFX LAW (v0.3.6-1): the takeoff is otherwise silent in
        # VFX - the burst happens WHEN THE SQUARE MEETS SOMETHING (landing,
        # bonk).

## THE ROCKET BURST - one short skin-colored burn from the face being left,
## gone in a third of a second. No plume, no puddle - a whoosh.
func _rocket_burst() -> void:
        var p := player
        var col: Color = SKINS[player.get("skin", "classic")]["col"]
        var side := 1.0 if p["g"] == 1 else -1.0   # +1 = the burn sits BELOW
        rocket.position = Vector2(p["x"], p["y"] + side * HALF * us * 0.85)
        rocket.direction = Vector2(0, side)         # pours AWAY from the square
        rocket.color = Color(col.r, col.g, col.b, 0.9)
        rocket.restart()

## THE FLIP - gravity inverts; a soft damp keeps the sail readable.
## THE FLIP PUSH LAW (v0.3.6-3): the switch reads as a simple push from the
## side being LEFT - a puff under the square when it leaves the ground, above
## it when it leaves the roof (the old radial burst looked broken).
func _flip_gravity(damp: float, from_sticky := false) -> void:
        var p := player
        var old_g := int(p["g"])
        p["g"] = -old_g
        p["vy"] *= damp
        p["ground"] = false
        flip_total += 1
        if not from_sticky:
                Jukebox.sfx("gf_flip", -3.0)
                _push_puff(Vector2(p["x"], p["y"]), old_g,
                        SKINS[p.get("skin", "classic")]["col"], 0.9)
        _plan_spin()

# =================================================================== tick
func _goga_tick(delta: float) -> void:
        beat_t += delta
        var pulse := 0.5 + 0.5 * sin(beat_t * TAU * (BPM_NOW / 60.0) / 2.0)
        bg_mat.set_shader_parameter("time_s", bg_time)
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
                # v0.3.7-1 THE ENDLESS WAIT LAW (the owner: "make the wait
                # screen make the world endless but without populating so
                # waiting does not hurt or break something"): the wait DOES
                # scroll the world (the breathe), but the generator used to
                # stop - after half a minute of lore-reading the ground
                # ENDED and a start dropped the square into the void. The
                # wait now feeds its own floor: flat ground + roof extend
                # forever, ZERO structures, ZERO threats - waiting can
                # never kill a run before it starts.
                var horizon := world_x + _vp().x / us + 600.0
                while gen_x < horizon:
                        _add_gseg(gen_x, gen_x + CELL * 8.0)
                        _add_rseg(gen_x, gen_x + CELL * 8.0)
                        gen_x += CELL * 8.0
                _layout_world()
                _idle_pulse(delta)
                return
        # THE GAME-TIME TRUTH (v0.3.6-1): SLOW WORLD halves EVERY core clock
        # - the scroll, the physics, the mechanic clock, the pickups, the
        # coin + power-up clocks, the spin. A 10s power-up then takes 20
        # real seconds because its own timer is game-time too.
        var ts := SLOW_SCALE if powers["slow"] > 0.0 else 1.0
        var gdt := delta * ts
        run_t += gdt
        world_x += speed * gdt
        _gen_ahead()
        _mech_clock(gdt)
        _physics(gdt)
        _pickups(gdt)
        _coin_clock(gdt)
        _pow_clock(gdt)
        bg_time += gdt
        twinkle_t += gdt
        _layout_world()
        _fx_tick(delta)

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
                "sticky": "STICK - FLOOR TO FLOOR"}[next])
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

## THE SUPPORT TRUTH + THE SNAP LAW: grounded means SUPPORTED - walk off an
## edge and the fall begins honestly. But a tiny float/bob error inside the
## SNAP band must never read as "no floor" (the replay ground-fall bug: the
## ready-phase bob buried the square 10px deep, the old 2px window dropped
## the support, and the square fell through the world forever). Inside the
## band the square SNAPS onto the surface instead.
func _support_check() -> void:
        var p := player
        if not p["ground"]:
                return
        var wx0: float = (p["x"] - HALF * us * 0.8) / us + world_x
        var wx1: float = (p["x"] + HALF * us * 0.8) / us + world_x
        var feet_y: float = p["y"] + HALF * us * float(p["g"])
        var band := SNAP * us
        var has := false
        var surf := 0.0
        if p["g"] == 1:
                if absf(feet_y - GROUND_Y * us) <= band:
                        for s in gsegs:
                                if float(s["x0"]) <= wx1 and float(s["x1"]) >= wx0:
                                        has = true
                                        surf = GROUND_Y * us
                                        break
                if not has:
                        for l in lines:
                                var ly: float = float(l["y"]) * us
                                if absf(feet_y - ly) <= band \
                                                and float(l["x0"]) <= wx1 and float(l["x1"]) >= wx0:
                                        has = true
                                        surf = ly
                                        break
                if not has:
                        for pu in pushers:
                                # v0.3.6-3 THE SPACE TRUTH part 3: the pusher span
                                # is WORLD px here - the old (pu.x - world_x) was
                                # SCREEN px compared against the player's WORLD
                                # span, so support held only while world_x ~ 0 and
                                # silently dropped mid-run (the square slid off
                                # every block it had landed, unable to jump)
                                var pux: float = float(pu["x"])
                                if pux <= wx1 and pux + CELL >= wx0 \
                                                and absf(feet_y - float(pu["y0"]) * us) <= band:
                                        has = true
                                        surf = float(pu["y0"]) * us
                                        break
        else:
                if absf(feet_y - ROOF_Y * us) <= band:
                        for s in rsegs:
                                if float(s["x0"]) <= wx1 and float(s["x1"]) >= wx0:
                                        has = true
                                        surf = ROOF_Y * us
                                        break
                if not has:
                        for l in lines:
                                var uy: float = (float(l["y"]) + LINE_TH) * us
                                if absf(feet_y - uy) <= band \
                                                and float(l["x0"]) <= wx1 and float(l["x1"]) >= wx0:
                                        has = true
                                        surf = uy
                                        break
                if not has:
                        for pu in pushers:
                                var pux2: float = float(pu["x"])
                                if pux2 <= wx1 and pux2 + CELL >= wx0 \
                                                and absf(feet_y - float(pu["y1"]) * us) <= band:
                                        has = true
                                        surf = float(pu["y1"]) * us
                                        break
        if has:
                # THE SNAP: settle onto the surface exactly (both directions)
                if absf(feet_y - surf) > 0.05:
                        p["y"] = surf - HALF * us * float(p["g"])
        if not has:
                p["ground"] = false
                _plan_spin()

## THE PUSHER LAW: overlap rides you back (speed + extra); top landing is safe.
## THE CLIMB SNAP (v0.3.6-3): feet rising JUST under a block top snap onto
## it instead of eating the shove - the old build shoved the square along
## the face mid-rise ("it slides on the block without letting me able to do
## a jump"). Real face-hits (deep body overlap, grounded runs into a wall)
## still shove - walls push, they never kill.
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
                            # THE CLIMB SNAP - a rising near-miss becomes the landing
                            if p["g"] == 1 and p["vy"] < 0.0:
                                    var feet: float = p["y"] + HALF * us
                                    var top := float(pu["y0"]) * us
                                    if feet > top and feet <= top + CLIMB_BAND * us:
                                            _land_at(top, p["y"])
                                            return false
                                    # THE UNDER-BONK (v0.3.6-3): a rising head that
                                    # just clips a floating slab's underside bonks
                                    # honestly - never a sideways shove in mid-air
                                    var head: float = p["y"] - HALF * us
                                    var bot := float(pu["y1"]) * us
                                    if head < bot and head >= bot - CLIMB_BAND * us:
                                            p["y"] = bot + HALF * us
                                            p["vy"] = 0.0
                                            _bonk_fx(Vector2(p["x"], bot))
                                            return false
                            # THE LANDING BAND (v0.3.6-3 THE CLIMB TRUTH part 2):
                            # a falling crossing that landed INSIDE this very
                            # frame lands ON the block - a fast frame crosses up
                            # to ~40px past the top, and the old 6px window read
                            # that honest touchdown as a side hit and SHOVED the
                            # landing away ("it slides on the block without
                            # letting me able to do a jump")
                            elif p["g"] == 1 and p["vy"] > 0.0:
                                    var feet3: float = p["y"] + HALF * us
                                    var top3 := float(pu["y0"]) * us
                                    if feet3 >= top3 and feet3 <= top3 + 48.0 * us:
                                            _land_at(top3, p["y"])
                                            return false
                            elif p["g"] == -1 and p["vy"] > 0.0:
                                    # THE DOWN BONK: jumping off the roof, a head
                                    # that just clips a slab's TOP bonks honestly
                                    var head2: float = p["y"] + HALF * us
                                    var top4 := float(pu["y0"]) * us
                                    if head2 > top4 and head2 <= top4 + CLIMB_BAND * us:
                                            p["y"] = top4 - HALF * us
                                            p["vy"] = 0.0
                                            _bonk_fx(Vector2(p["x"], top4))
                                            return false
                            elif p["g"] == -1 and p["vy"] < 0.0:
                                    # the flipped rise: feet just under a pad's
                                    # bottom snap onto it (THE CLIMB SNAP mirrored)
                                    var feet2: float = p["y"] - HALF * us
                                    var bot2 := float(pu["y1"]) * us
                                    if feet2 > bot2 and feet2 <= bot2 + CLIMB_BAND * us:
                                            _land_at(bot2, p["y"])
                                            return false
                                    if feet2 <= bot2 and feet2 >= bot2 - 48.0 * us:
                                            _land_at(bot2, p["y"])
                                            return false
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
                                        _bonk_fx(Vector2(p["x"], uy))
                                        return
                if head <= ROOF_Y * us:
                        p["y"] = ROOF_Y * us + HALF * us
                        p["vy"] = 0.0
                        _bonk_fx(Vector2(p["x"], ROOF_Y * us))
                        # THE STICK TRUTH: touching the ROOF is the flip - the
                        # square sticks up (only over a real roof seg; never
                        # stick into an opened stretch)
                        if mechanic == "sticky" \
                                        and _roof_under(p["x"] / us + world_x):
                                _stick_touch(-1)
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
                                        _bonk_fx(Vector2(p["x"], GROUND_Y * us))
                                        # THE STICK TRUTH: touching the GROUND
                                        # flips the square back down-stuck
                                        if mechanic == "sticky":
                                                _stick_touch(1)
                                        return
                for l in lines:
                        var sx0: float = (float(l["x0"]) - world_x) * us
                        var sx1: float = (float(l["x1"]) - world_x) * us
                        var ly: float = l["y"] * us
                        if sx0 <= px1 and sx1 >= px0:
                                if feet >= ly and feet_prev <= ly + 1.0 and p["vy"] > 0.0:
                                        p["y"] = ly - HALF * us
                                        p["vy"] = 0.0
                                        _bonk_fx(Vector2(p["x"], ly))
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
                # THE LANDING VFX LAW: the impact effect lives ON the touch,
                # scaled by the fall speed (a dust ring + streak sparks)
                _impact_fx(Vector2(p["x"], surf_y), impact, p["g"])

## THE STICK TOUCH (v0.3.6-1 THE STICK TRUTH): gravity changes ONLY here -
## when the square TOUCHES one of the two floors (ground <-> roof). A stick
## is its own little ceremony: the snap sound, a ring, the counter.
func _stick_touch(new_g: int) -> void:
        var p := player
        if int(p["g"]) == new_g:
                return
        p["g"] = new_g
        p["ground"] = true
        p["vy"] = 0.0
        p["rot"] = roundf(p["rot"] / 90.0) * 90.0
        flip_total += 1
        Jukebox.sfx("gf_sticky", -3.0)
        _burst_at(Vector2(p["x"], p["y"]), 8, 0.7)

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
                # v0.3.6-3: spike3 wears its own WIDE-LOW box (the calculated
                # dodge-able shape) - the round r box stays for the others
                var hbox: Rect2
                if h.has("hw"):
                        var hw: float = float(h["hw"]) * us
                        var hh: float = float(h["hh"]) * us
                        hbox = Rect2(hx - hw, float(h["y"]) * us - hh, hw * 2.0, hh * 2.0)
                else:
                        var hr: float = h["r"] * us
                        hbox = Rect2(hx - hr, float(h["y"]) * us - hr, hr * 2.0, hr * 2.0)
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
                # THE CLIMB TRUTH (v0.3.6-3): block tops are landing surfaces
                # too - the 90 now completes exactly at the touchdown on a
                # block (the old build spun for the full fall and landed the
                # square at a broken mid-rotation angle on every block)
                for pu in pushers:
                        if wx >= float(pu["x"]) - HALF * 0.5 \
                                        and wx <= float(pu["x"]) + CELL + HALF * 0.5 \
                                        and feet >= float(pu["y0"]) \
                                        and feet <= float(pu["y0"]) + CELL * 0.9:
                                return true
        else:
                if feet <= ROOF_Y and _roof_under(wx):
                        return true
                for l in lines:
                        var uy: float = l["y"] + LINE_TH
                        if wx >= l["x0"] and wx <= l["x1"] and feet <= uy and feet >= uy - LINE_TH * 2.0:
                                return true
                for pu in pushers:
                        if wx >= float(pu["x"]) - HALF * 0.5 \
                                        and wx <= float(pu["x"]) + CELL + HALF * 0.5 \
                                        and feet <= float(pu["y1"]) \
                                        and feet >= float(pu["y1"]) - CELL * 0.9:
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
        # THE STREAK RESET LAW (v0.3.6-3): the pitch ladder never got stuck
        # on "always up" any more - 2s of silence drops it back to 0.
        streak_idle += dt
        if orbit_streak > 0 and streak_idle >= STREAK_IDLE:
                if orbit_streak > 9:
                        orbit_streak = 9   # the audible ladder has 9 rungs
                streak_decay += dt
                var step := STREAK_LAST if orbit_streak <= 1 else STREAK_STEP
                if streak_decay >= step:
                        streak_decay = 0.0
                        orbit_streak -= 1
                        if orbit_streak <= 0:
                                orbit_streak = 0
                                streak_idle = 0.0
                                streak_decay = 0.0
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
                        streak_idle = 0.0     # THE STREAK RESET LAW: a collect
                        streak_decay = 0.0    # freezes the decay, keeps the rung
                        var pitch := 0.92 + 0.055 * minf(float(orbit_streak), 9.0)
                        Jukebox.sfx("gf_orbit", -4.0, pitch)
                        add_score(1)
                        # THE COLLECT LAW (v0.3.6-3): a proper COLORED
                        # particle burst - the golden glow pop + star
                        # flashes (the implosion read badly)
                        _orbit_collect_fx(Vector2(ox, oy), Vector2(p["x"], p["y"]))
                        if score >= next_bonus:
                                next_bonus += SPEED_BONUS_AT
                                speed_level += 1
                                speed = BASE_SPEED * pow(SPEED_STEP, float(speed_level))
                                if speed_label != null:
                                        speed_label.text = "x%.2f" % (speed / BASE_SPEED)
                                Jukebox.sfx("gf_speed", -6.0)
        # the taken orbits leave the array NOW (a queue_free'd sprite must
        # never meet the next _layout_world - the freed-sprite lesson)
        for o in collected:
                orbits.erase(o)
        # the power-up capsules ride the same pickup pass
        for pu in pow_pickups.duplicate():
                var px: float = (float(pu["x"]) - world_x) * us
                if absf(px - p["x"]) > 120.0 * us:
                        continue
                var py: float = float(pu["y"]) * us
                if Vector2(px, py).distance_to(Vector2(p["x"], p["y"])) <= 60.0 * us:
                        _pow_collect(pu, Vector2(px, py))

## THE COIN LAW - 30/35/40/45/50s from the LAST APPEAR.
func _coin_clock(dt: float) -> void:
        coin_timer -= dt
        if coin_timer <= 0.0 and coin.is_empty():
                _coin_spawn()
                if coin.is_empty():
                        return   # THE DEFER: the spawn set its own retry clock
                coin_timer = float(COIN_DELAYS[rng.randi_range(0, COIN_DELAYS.size() - 1)])
        if not coin.is_empty():
                coin["t"] = float(coin["t"]) + dt
                var cx: float = (float(coin["x"]) - world_x) * us
                var cy: float = float(coin["y"]) * us + sin(coin["t"] * 3.0) * 10.0 * us
                coin["spr"].position = Vector2(cx, cy)
                var p := player
                if Vector2(cx, cy).distance_to(Vector2(p["x"], p["y"])) <= 56.0 * us:
                        add_run_coins(1)
                        Jukebox.sfx("gf_coin")
                        _coin_collect_fx(Vector2(cx, cy), Vector2(p["x"], p["y"]))
                        coin["spr"].queue_free()
                        coin = {}

# ------------------------------------------------------- power-ups (p1)
## THE POWER LAW: the three capsules spawn in the world (only the OWNED
## ones), one every 30/40/50/60s from the last spawn, 10 GAME-seconds each.
## SLOW halves every core clock (game-time), ROCKET multiplies the jump,
## EXTRA LIFE converts death into a save (see _die/_shield_save).
func _owned_powers() -> Array:
        var out: Array = []
        for k in POWERS:
                if Box.item_owned(game_id, "power", k):
                        out.append(k)
        return out

func _pow_clock(dt: float) -> void:
        shield_cd = maxf(0.0, shield_cd - dt)
        for k in powers:
                if powers[k] > 0.0:
                        powers[k] -= dt
                        if powers[k] <= 0.0:
                                powers[k] = 0.0
                                _pow_end(k)
        pow_timer -= dt
        if pow_timer > 0.0:
                return
        var owned := _owned_powers()
        if owned.is_empty() or not pow_pickups.is_empty():
                return   # nothing to send, or the last capsule still on screen
        _pow_spawn(owned[rng.randi_range(0, owned.size() - 1)])
        pow_timer = float(POW_DELAYS[rng.randi_range(0, POW_DELAYS.size() - 1)])

func _pow_spawn(kind: String) -> void:
        var vp := _vp()
        # a reachable lane: the jump arcs, the line hops, the roof ride
        var lanes := [L1_Y - 150.0, L2_Y - 150.0, L3_Y - 150.0,
                GROUND_Y - 190.0, L1_Y - 60.0]
        var y: float = lanes[rng.randi_range(0, lanes.size() - 1)]
        var spr := Sprite2D.new()
        spr.texture = _tex("pow_%s.png" % kind)
        spr.scale = Vector2.ONE * 0.5 * us
        var halo := Sprite2D.new()
        halo.texture = _tex("p_glow.png")
        halo.modulate = Color(POWERS[kind]["col"], 0.5)
        halo.scale = Vector2.ONE * 1.25
        spr.add_child(halo)
        spr.position = Vector2(vp.x + 80.0, y * us)
        world.add_child(spr)
        pow_pickups.append({"x": world_x + vp.x / us + 80.0 / us, "y": y,
                "kind": kind, "spr": spr, "t": 0.0})

func _pow_collect(pu: Dictionary, at: Vector2) -> void:
        pow_pickups.erase(pu)
        if is_instance_valid(pu["spr"]):
                pu["spr"].queue_free()
        var kind: String = pu["kind"]
        powers[kind] = POW_DUR
        Jukebox.sfx("gf_pow", -2.0)
        var col: Color = POWERS[kind]["col"]
        _ring_fx(at, col, 1.3)
        _burst_at(at, 10, 0.9)
        game_toast("%s!" % POWERS[kind]["name"])

func _pow_end(kind: String) -> void:
        Jukebox.sfx("gf_pow_end", -8.0)
        if kind == "shield" and shield_spr != null:
                shield_spr.visible = false
                shield_aura.modulate.a = 0.0

func _coin_spawn() -> void:
        var vp := _vp()
        # THE COIN SPACE LAW (v0.3.6-3): the coin never spawns inside the
        # world any more - every candidate (lane x offset) is validated
        # against blocks, lines, hazards and orbits; blocked rolls re-roll;
        # a fully crowded horizon DEFERS the spawn instead of forcing a bad
        # coin into a block.
        var lanes := [L1_Y - 150.0, L2_Y - 150.0, L3_Y - 150.0, GROUND_Y - 190.0]
        var base_x := world_x + vp.x / us + 80.0 / us
        for attempt in 8:
                var y: float = lanes[rng.randi_range(0, lanes.size() - 1)]
                var x := base_x + CELL * float(rng.randi_range(0, 4))
                if _coin_spot_clear(x, y):
                        _coin_place(x, y)
                        return
        coin_timer = 2.0   # the horizon is crowded - try again shortly

## THE COIN SPACE TRUTH: the keep-clear box (the coin core + halo) must be
## empty world - no block, no line band, no hazard, no orbit crowding.
func _coin_spot_clear(x: float, y: float) -> bool:
        var r := COIN_PX * 0.5 + 26.0
        for pu in pushers:
                if x + r > float(pu["x"]) and x - r < float(pu["x"]) + CELL \
                                and y + r > float(pu["y0"]) and y - r < float(pu["y1"]):
                        return false
        for l in lines:
                if x + r > float(l["x0"]) and x - r < float(l["x1"]) \
                                and y + r > float(l["y"]) - LINE_TH \
                                and y - r < float(l["y"]) + LINE_TH * 2.0:
                        return false
        for h in hazards:
                var hr: float = float(h["r"])
                if absf(float(h["x"]) - x) < r + hr + 10.0 \
                                and absf(float(h["y"]) - y) < r + hr + 10.0:
                        return false
        for o in orbits:
                if absf(float(o["x"]) - x) < r + 34.0 \
                                and absf(float(o["y"]) - y) < r + 34.0:
                        return false
        return true

func _coin_place(x: float, y: float) -> void:
        var spr := Sprite2D.new()
        spr.texture = load("res://assets/ui/coin.png")
        var halo := Sprite2D.new()
        halo.texture = _tex("p_glow.png")
        halo.modulate = Color(1.0, 0.8, 0.3, 0.5)
        halo.scale = Vector2.ONE * 1.1
        spr.add_child(halo)
        # v0.3.6-1 THE COIN SCALE LAW: 44 design px core - a pickup, not a
        # second sun (the owner: "very big, scale it accurately")
        spr.scale = Vector2.ONE * (COIN_PX / 96.0) * us
        spr.position = Vector2(_vp().x + 80.0, y * us)
        world.add_child(spr)
        coin = {"x": x, "y": y, "spr": spr, "t": 0.0}

# ------------------------------------------------------------- death
func _die(_why: String) -> void:
        if over_gate or phase != "run":
                return
        # THE EXTRA LIFE LAW (v0.3.6-1): while the shield lives, death is a
        # SAVE, not an end - pits bounce, the pushed-off re-enter in style,
        # hazards just spark. The debounce keeps the ceremony from spamming.
        if powers["shield"] > 0.0:
                _shield_save(_why)
                return
        over_gate = true
        last_death = _why
        tail.emitting = false
        tail2.emitting = false
        rocket.emitting = false
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

## THE SAVE CEREMONY - every death kind gets its own rescue.
func _shield_save(why: String) -> void:
        var p := player
        if shield_cd > 0.0 and why == "hazard":
                return   # passing through a hazard: one spark per contact
        shield_cd = 0.45
        var col: Color = POWERS["shield"]["col"]
        match why:
                "pit":
                        if p["g"] == 1:
                                # the rescue hop: jump UP out of the pit and
                                # continue the way (the owner's own words)
                                p["y"] = minf(p["y"], (GROUND_Y - HALF) * us)
                                p["vy"] = -JUMP_V * SHIELD_HOP * us
                        else:
                                # roof pit: press back DOWN, gravity re-sticks
                                # the square onto the roof past the opening
                                p["y"] = maxf(p["y"], (ROOF_Y + HALF) * us)
                                p["vy"] = JUMP_V * SHIELD_HOP * us
                        p["ground"] = false
                        _plan_spin()
                        Jukebox.sfx("gf_save", -2.0)
                        _ring_fx(Vector2(p["x"], p["y"]), col, 1.2)
                        _burst_at(Vector2(p["x"], p["y"]), 10, 0.9)
                "off screen":
                        _shield_reenter()
                _:
                        # hazards: pass through with a shield spark
                        Jukebox.sfx("gf_save", -10.0, 1.3)
                        _ring_fx(Vector2(p["x"], p["y"]), col, 0.6)

## THE COOL RE-ENTRY: the square flashes out, then drops back at the
## standpoint inside a light beam - the show must go on.
func _shield_reenter() -> void:
        var p := player
        var col: Color = POWERS["shield"]["col"]
        p["x"] = stand_x
        p["y"] = clampf(p["y"], (ROOF_Y + HALF * 2.0) * us, (GROUND_Y - HALF) * us)
        p["vy"] = 0.0
        p["ground"] = false
        p["sq"] = 0.4          # the scale-in bounce lives in _layout_world
        _plan_spin()
        Jukebox.sfx("gf_reentry", -2.0)
        # the beam
        var beam := Sprite2D.new()
        beam.texture = _tex("p_glow.png")
        beam.position = Vector2(p["x"], p["y"])
        beam.scale = Vector2(0.5, 4.2) * us
        beam.modulate = Color(col.r, col.g, col.b, 0.85)
        var bmat := CanvasItemMaterial.new()
        bmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
        beam.material = bmat
        add_child(beam)
        var tw := beam.create_tween()
        tw.set_parallel(true)
        tw.tween_property(beam, "modulate:a", 0.0, 0.4)
        tw.tween_property(beam, "scale", Vector2(0.2, 5.4) * us, 0.4)
        tw.chain().tween_callback(func(): if is_instance_valid(beam): beam.queue_free())
        _ring_fx(Vector2(p["x"], p["y"]), col, 1.4)
        _burst_at(Vector2(p["x"], p["y"]), 12, 1.0)

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
        var root := Node2D.new()
        var b := Sprite2D.new()
        b.texture = _tex("pusher.png")
        b.scale = Vector2.ONE * 0.5 * us
        root.add_child(b)
        if tall:
                # v0.3.6-3 render fix: the second block sits EXACTLY one cell
                # below the root (the old -0.5C offset floated it a cell
                # above the column top)
                var s2 := Sprite2D.new()
                s2.texture = _tex("pusher.png")
                s2.scale = Vector2.ONE * 0.5 * us
                s2.position = Vector2(0, CELL * us)
                root.add_child(s2)
        world.add_child(root)
        pushers.append({"x": x, "y0": y0, "y1": y1, "spr": root})

## THE BLOCK COLUMN (v0.3.6-3 THE WORLD LAW) - the structure cell: a stack
## of n solid blocks one cell wide. Tops are REAL surfaces (the square
## lands its 90 and jumps again - THE CLIMB TRUTH), faces shove (never
## kill), undersides hang for the flip modes. The world builds its shapes
## from these columns now.
func _add_block(x: float, y0: float, rows: int, deco := false) -> void:
        if rows <= 0:
                return
        var root := Node2D.new()
        for i in rows:
                var b := Sprite2D.new()
                b.texture = _tex("pusher.png" if deco else "block.png")
                b.scale = Vector2.ONE * 0.5 * us
                b.position = Vector2(0, float(i) * CELL * us)
                root.add_child(b)
        world.add_child(root)
        pushers.append({"x": x, "y0": y0, "y1": y0 + float(rows) * CELL, "spr": root})

## A ground-anchored column of n blocks standing ON a surface.
func _add_col(x: float, n: int, surface: float) -> void:
        _add_block(x, surface - float(n) * CELL, n)

## A roof-anchored column of n blocks hanging UNDER the roof line.
func _add_hang(x: float, n: int, surface: float) -> void:
        _add_block(x, surface, n)

## v0.3.6-3 THE SPIKE3 - the owner's spike: THREE SMALL triangles on a
## surface base, a calculated WIDE-LOW box (120 x 48 design px) a normal
## hop clears from anywhere - dodge-able by construction. The old big
## triangle stays as a rare high-level wall threat.
func _add_spike3(x: float, surface: float, inverted := false) -> void:
        var spr := Sprite2D.new()
        spr.texture = _tex("spike3.png")
        spr.scale = Vector2.ONE * 0.5 * us
        if inverted:
                spr.rotation = PI
        world.add_child(spr)
        var off := 30.0 if inverted else -30.0
        hazards.append({"x": x, "y": surface + off, "kind": "spike3",
                "spr": spr, "r": 30.0, "hw": 58.0, "hh": 24.0})

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
        # v0.3.7-1 THE RICH BREATH: even the calm wears a small shape (a
        # single pedestal the run hops or ignores - never a threat)
        if rng.randf() < 0.5:
                _add_col(x + CELL * 5.2, 1, GROUND_Y)
                _add_orbit(x + CELL * 5.7, GROUND_Y - CELL - 115.0)
        return w

## One chunk at the cursor; returns its width. THE WEIGHTS: the level
## tightens the mix; flip/sticky unlock the roof play; THE WORLD LAW
## (v0.3.6-3): the block structures (stairs, gardens, pyramids, descents,
## towers, bridges) live from the FIRST level - the world is built, not
## empty; spikes are the small triple rows mostly, the big triangle a rare
## high-level wall.
func _gen_chunk(x: float) -> float:
        if world_x < calm_until and gen_x < calm_until:
                return _gen_calm(x)
        var lvl := _level()
        # THE SIDE PROFILES (patch 3): the generator READS the square - when
        # it rides the roof the roof family triples and roof-only yards open
        # up; on the ground the built world plays as shipped; MIXED chunks
        # (both sides filled at once) always live in the pool.
        var on_roof: bool = player["g"] == -1
        var roof_mul := 3 if on_roof else 1
        var pool: Array = []
        var w_flat := maxi(4, 10 - lvl)
        for i in w_flat:
                pool.append("flat")
        for i in mini(7, 2 + lvl):
                pool.append("pit")
        for i in mini(6, 1 + lvl):
                pool.append("push")
        for i in mini(7, 2 + lvl):
                pool.append("spikes")
        # THE BLOCK DECKS (patch 3): long structured BLOCK surfaces - blocks
        # instead of the thin platforms (the owner: "the blocks are good
        # surfaces too")
        for i in mini(8, 3 + lvl):
                pool.append("deck")
        for i in mini(6, 2 + lvl):
                pool.append("stairs")
        for i in mini(5, 2 + lvl):
                pool.append("garden")
        for i in mini(4, 1 + lvl):
                pool.append("pyramid")
        for i in mini(4, 1 + lvl):
                pool.append("descent")
        # THE CLIMB-DOWN (patch 3): the dedicated tower-and-descend chunk
        for i in mini(4, 1 + lvl):
                pool.append("down")
        for i in mini(3, 1 + int(lvl / 2.0) + 1):
                pool.append("mixed")
        # v0.3.7-1 THE RICH WORLD DECKS (the owner: "the in-betweens feel
        # empty and not that rich... ups and downs and many platforms and
        # blocks... it feels repeated after less than 30 seconds - there is
        # a lot of room that you do not use"): six new shapes spread across
        # the levels - the ARCH (a tunnel you hop through), the VALLEY (a
        # dip between raised banks), the ISLANDS (hops over water), the
        # HIGHWAY (a long raised ride over a spiked floor), the WAVE (an
        # up-down-up-down rhythm) and the TOWERS (full-height vertical play).
        for i in mini(4, 1 + lvl):
                pool.append("gate")
        for i in mini(4, 2 + lvl):
                pool.append("valley")
        if lvl >= 1:
                for i in mini(4, lvl):
                        pool.append("wave")
        if lvl >= 2:
                for i in mini(4, lvl - 1):
                        pool.append("islands")
                for i in mini(4, lvl - 1):
                        pool.append("highway")
        if lvl >= 3:
                for i in mini(3, lvl - 2):
                        pool.append("towers")
        if lvl >= 1:
                for i in mini(4, 1 + lvl):
                        pool.append("twin")
                for i in maxi(1, mini(3, lvl)):
                        pool.append("bridge")
        for i in maxi(2, mini(5, 1 + lvl)):
                pool.append("ladder")
        if lvl >= 2:
                for i in mini(4, lvl - 1):
                        pool.append("weave")
                for i in mini(3, lvl - 1):
                        pool.append("floaters")
        if lvl >= 3:
                for i in mini(3, lvl - 2):
                        pool.append("saw")
        if mechanic != "normal":
                for i in mini(6, 2 + lvl) * roof_mul:
                        pool.append("roof")
                for i in mini(4, 1 + lvl) * roof_mul:
                        pool.append("roof_stairs")
                # the roof-side yard only matters when the square can be there
                for i in mini(4, 1 + lvl) * roof_mul:
                        pool.append("roof_yard")
        var pick: String = pool[rng.randi_range(0, pool.size() - 1)]
        match pick:
                "pit":
                        return _chunk_pit(x)
                "push":
                        return _chunk_push(x)
                "spikes":
                        return _chunk_spikes(x)
                "deck":
                        return _chunk_deck(x)
                "stairs":
                        return _chunk_stairs(x)
                "garden":
                        return _chunk_garden(x)
                "pyramid":
                        return _chunk_pyramid(x)
                "descent":
                        return _chunk_descent(x)
                "down":
                        return _chunk_down(x)
                "mixed":
                        return _chunk_mixed(x)
                "gate":
                        return _chunk_gate(x)
                "valley":
                        return _chunk_valley(x)
                "wave":
                        return _chunk_wave(x)
                "islands":
                        return _chunk_islands(x)
                "highway":
                        return _chunk_highway(x)
                "towers":
                        return _chunk_towers(x)
                "twin":
                        return _chunk_twin(x)
                "bridge":
                        return _chunk_bridge(x)
                "ladder":
                        return _chunk_ladder(x)
                "weave":
                        return _chunk_weave(x)
                "floaters":
                        return _chunk_floaters(x)
                "saw":
                        return _chunk_saw(x)
                "roof":
                        return _chunk_roof(x)
                "roof_stairs":
                        return _chunk_roof_stairs(x)
                "roof_yard":
                        return _chunk_roof_yard(x)
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
                # v0.3.6-3: the small triple row is the spike now; the big
                # triangle is a rare wall from level 3
                if _level() >= 3 and rng.randf() < 0.25:
                        _add_hazard(cx + i * step, GROUND_Y - CELL * 0.5, "spike")
                else:
                        _add_spike3(cx + i * step, GROUND_Y)
                _add_orbit(cx + i * step - CELL * 0.2, GROUND_Y - 240.0)
                _add_orbit(cx + i * step + CELL * 0.8, GROUND_Y - 240.0)
        return cx + n * step + CELL * 4.0 - x

## THE BLOCK DECKS (patch 3) - the thin platforms are retired: long
## structured surfaces BUILT FROM BLOCKS in different shapes and ways (the
## owner: "I want blocks to appear instead of just the platforms, the blocks
## are good surfaces too"). Every deck carries its own climb: the approach
## end steps up (a 1-cell step the apex always clears), the far end steps
## down - so decks teach the climb-up AND the climb-down.
func _chunk_deck(x: float) -> float:
        var w := CELL * rng.randf_range(11.0, 14.0)
        _add_gseg(x, x + w)
        _add_rseg(x, x + w)
        var y: float = [L1_Y, L2_Y, L2_Y][rng.randi_range(0, 2)]
        var deck_h := 1 if y == L1_Y else 2   # L2 decks stand on a 2-cell leg
        var dx := x + CELL * 1.6
        var shape := rng.randi_range(0, 2)
        match shape:
                0:
                        # THE PLAIN DECK: approach step, the long run, the
                        # step-down at the far end
                        _add_col(dx, deck_h, GROUND_Y)
                        _add_col(dx + CELL, deck_h, GROUND_Y)
                        dx += CELL * 2.2
                        var run := rng.randi_range(4, 6)
                        for i in run:
                                _add_block(dx + float(i) * CELL, y, 1)
                                if i % 2 == 0:
                                        _add_orbit(dx + float(i) * CELL + CELL * 0.5, y - 115.0)
                        dx += float(run) * CELL
                        if deck_h > 1:
                                _add_col(dx, deck_h - 1, GROUND_Y)   # the step-down
                        _add_orbit(dx + CELL, y - 130.0)
                1:
                        # THE NOTCHED DECK: the long run with a tower bump in
                        # the middle - the hop-over keeps the ride honest
                        var run := rng.randi_range(5, 7)
                        var notch := int(run / 2.0)
                        for i in run:
                                var yy := y - (CELL if i == notch else 0.0)
                                _add_block(dx + float(i) * CELL, yy, 2 if i == notch else 1)
                                # v0.3.7-2 THE NOTCH ORBIT LAW (the world audit
                                # catch): the orbit BEFORE the notch sat at the
                                # notch block's edge - one cell taller than the
                                # deck line, the ring grazed the stone. The
                                # notch's own high orbit marks the hop; the
                                # approach slot stays empty.
                                if i != notch - 1:
                                        _add_orbit(dx + float(i) * CELL + CELL * 0.5,
                                                yy - (CELL + 115.0) if i == notch else y - 115.0)
                        dx += float(run) * CELL
                        _add_col(dx, 1, GROUND_Y)
                _:
                        # THE TWIN DECKS: two block decks at both line heights
                        # with a hop between them (the climb-up to the high
                        # one rides the low one first)
                        var run := rng.randi_range(3, 4)
                        for i in run:
                                _add_block(dx + float(i) * CELL, L1_Y, 1)
                        _add_orbit(dx + CELL, L1_Y - 115.0)
                        dx += float(run + 1) * CELL
                        for i in run:
                                _add_block(dx + float(i) * CELL, L2_Y, 1)
                                _add_orbit(dx + float(i) * CELL + CELL * 0.5, L2_Y - 115.0)
                        dx += float(run) * CELL
                        _add_col(dx, 1, GROUND_Y)
        if _level() >= 2 and rng.randf() < 0.4:
                _add_spike3(x + w - CELL * 1.6, GROUND_Y)
        return w

## THE CLIMB-DOWN (patch 3) - the dedicated descent the owner kept asking
## for: two-cell steps UP to a 4-cell tower, then a real staircase DOWN
## (4-3-2-1) back to the floor. One shape teaches the whole vertical game.
func _chunk_down(x: float) -> float:
        var w := CELL * 20.0
        _add_gseg(x, x + w)
        _add_rseg(x, x + w)
        var cx := x + CELL * 1.6
        # the climb-up: 2-tall then 4-tall (every hop +2 cells, inside the apex)
        for h: int in [2, 4]:
                _add_col(cx, h, GROUND_Y)
                _add_col(cx + CELL, h, GROUND_Y)
                _add_orbit(cx + CELL * 0.5, GROUND_Y - float(h) * CELL - 115.0)
                cx += CELL * 3.0
        # the plateau breathes, then the LONG descent: 3 - 2 - 1 - floor
        cx += CELL
        for h: int in [3, 2, 1]:
                _add_col(cx, h, GROUND_Y)
                _add_col(cx + CELL, h, GROUND_Y)
                _add_orbit(cx + CELL * 0.5, GROUND_Y - float(h) * CELL - 115.0)
                cx += CELL * 3.0
        if _level() >= 2 and rng.randf() < 0.5:
                _add_spike3(cx + CELL * 1.4, GROUND_Y)
                _add_orbit(cx + CELL * 1.4, GROUND_Y - 250.0)
        return w

## THE ROOF YARD (patch 3) - the roof side gets its OWN built world: hanging
## block decks the flipped square hops across on their undersides, hanging
## spike rows and a marked lane. Rides the same reachability gate as the
## roof play (flip/sticky only), and THE SIDE PROFILES triple it while the
## square is actually up there.
func _chunk_roof_yard(x: float) -> float:
        var w := CELL * 14.0
        _add_gseg(x, x + w)
        _add_rseg(x, x + w)
        var dx := x + CELL * 1.8
        var run := rng.randi_range(3, 4)
        for i in run:
                _add_hang(dx + float(i) * CELL, 1, L3_Y)
                _add_orbit(dx + float(i) * CELL + CELL * 0.5, L3_Y + 135.0)
        dx += float(run + 1) * CELL
        var run2 := rng.randi_range(2, 3)
        for i in run2:
                _add_hang(dx + float(i) * CELL, 1, L2_Y)
        _add_orbit(dx + float(run2) * CELL * 0.5, L2_Y + 135.0)
        if rng.randf() < 0.6:
                _add_spike3(dx + float(run2) * CELL + CELL, L3_Y + 160.0)
        return w

## THE MIXED PROFILE (patch 3) - one chunk that fills EVERY lane at once:
## a ground stair, a block deck on the middle line and a hanging roof pad -
## both sides alive at the same time (the owner: "no mixed profiles").
func _chunk_mixed(x: float) -> float:
        # v0.3.7-1 THE OVERLAP FIX (the owner's report: "two blocks at the
        # grounds then 4 a little up - the last 2 of them are overlapped
        # with the next 2x2 blocks"): the L1 deck used to start at x+3C and
        # the ground 2x2 pair stood at x+5.6C..7.6C - the deck's last two
        # blocks sat INSIDE the 2x2 columns. Every shape now owns its own
        # lane: ground stair (2 singles + 2x2) -> the L1 deck ABOVE AND
        # PAST them -> the roof hang. No two structures share x-space.
        var w := CELL * 18.0
        _add_gseg(x, x + w)
        _add_rseg(x, x + w)
        # the ground: a 2-step stair (two singles, then the 2x2 pair)
        var gx := x + CELL * 1.6
        _add_col(gx, 1, GROUND_Y)
        _add_col(gx + CELL, 1, GROUND_Y)
        _add_col(gx + CELL * 4.0, 2, GROUND_Y)
        _add_col(gx + CELL * 5.0, 2, GROUND_Y)
        _add_orbit(gx + CELL * 2.5, GROUND_Y - 250.0)
        # the middle: a block deck on L1, starting PAST the 2x2 pair
        var mx := x + CELL * 8.6
        for i in 4:
                _add_block(mx + float(i) * CELL, L1_Y, 1)
        _add_orbit(mx + CELL * 2.0, L1_Y - 115.0)
        # the roof: a hanging pad cluster (reachable only in flip/sticky)
        var hx := x + CELL * 14.4
        for i in 2:
                _add_hang(hx + float(i) * CELL, 1, L3_Y)
        _add_orbit(hx + CELL, L3_Y + 135.0)
        return w

## ================================================== THE RICH WORLD DECKS ==
## v0.3.7-1 - six new shapes for the owner's "use every single pixel" law.
## Same fairness rules as the built world: every step inside the apex, the
## ground route always has a lane, threats never share a window with a
## forced jump, and every shape owns its x-space (the overlap lesson).

## THE GATE - a tunnel: a ground column and a hanging column with ONE open
## lane between. The square hops through the doorway (or rides the line
## over it). Full-height vertical read without a single threat.
func _chunk_gate(x: float) -> float:
        var w := CELL * 13.0
        _add_gseg(x, x + w)
        _add_rseg(x, x + w)
        var ax := x + CELL * 4.0
        _add_col(ax, 2, GROUND_Y)                 # the ground pillar
        _add_hang(ax, 2, L3_Y - CELL * 2.0)       # the hanging pillar above
        # v0.3.7-2 THE DOORWAY LAW (the world audit catch): the welcome
        # orbit used to sit INSIDE the ground pillar (y = GROUND_Y - 0.5C
        # is deep in the stone) - the owner's "an orbit directly literally
        # overlapped in a block". It lives in the doorway lane now: between
        # the pillar top (GROUND_Y - 2C) and the hang bottom, where the
        # hop through the gate actually flies.
        _add_orbit(ax + CELL * 0.5, GROUND_Y - CELL * 2.7)
        _add_orbit(ax + CELL * 2.4, GROUND_Y - CELL * 1.6)
        if _level() >= 2 and rng.randf() < 0.4:
                _add_spike3(x + w - CELL * 1.5, GROUND_Y)
        return w

## THE VALLEY - a raised bank, a dip, a raised bank: real UPS AND DOWNS on
## the ground line itself (the dip is a shallow pit the apex clears; the
## far bank is one block higher - the world stops being a flat corridor).
func _chunk_valley(x: float) -> float:
        var w := CELL * 14.0
        _add_gseg(x, x + w)
        _add_rseg(x, x + w)
        var bx := x + CELL * 1.6
        _add_col(bx, 1, GROUND_Y)                 # the near bank lip
        _add_col(bx + CELL, 1, GROUND_Y)
        var pit := CELL * 2.2
        var px := bx + CELL * 2.6
        _add_gseg(px, px + pit)                   # the dip floor (raised edge)
        # v0.3.7-2 THE ARC MARGIN LAW (the world audit catch): the arc ran
        # edge to edge - its end orbits sat INSIDE the far bank's blocks.
        # Both ends pull half a cell inward so every ring keeps its air.
        _orbit_arc(px + CELL * 0.5, pit - CELL, GROUND_Y)
        var fx := px + pit + CELL * 0.6
        _add_col(fx, 2, GROUND_Y)                 # the far bank, one higher
        _add_col(fx + CELL, 2, GROUND_Y)
        _add_orbit(fx + CELL, GROUND_Y - CELL * 2.0 - 115.0)
        return w

## THE WAVE - up, down, up, down: the staircase rhythm in ONE chunk (a
## pyramid that never stops moving). Reads like rolling terrain.
func _chunk_wave(x: float) -> float:
        var w := CELL * 20.0
        _add_gseg(x, x + w)
        _add_rseg(x, x + w)
        var cx := x + CELL * 1.6
        var h := 1
        var up := true
        for i in 5:
                _add_col(cx, h, GROUND_Y)
                _add_col(cx + CELL, h, GROUND_Y)
                _add_orbit(cx + CELL * 0.5, GROUND_Y - float(h) * CELL - 115.0)
                cx += CELL * 3.2
                h += 1 if up else -1
                if h >= 3:
                        up = false
                if h <= 1:
                        up = true
        return w

## THE ISLANDS - a chain of 1-tall block islands over real pits: hop,
## land, hop again. The sea gap obeys the pit math; the islands are the
## only ground (the roof line stays whole - the flip modes get a lane).
func _chunk_islands(x: float) -> float:
        var w := CELL * 17.0
        var lead := CELL * 2.0
        _add_gseg(x, x + lead)
        _add_rseg(x, x + w)
        var ix := x + lead
        for i in 3:
                _add_col(ix, 1, GROUND_Y)
                _add_col(ix + CELL, 1, GROUND_Y)
                _add_orbit(ix + CELL * 0.5, GROUND_Y - CELL - 130.0)
                ix += CELL * 4.2                  # island + a 2.2-cell sea
        _add_gseg(ix + CELL * 0.4, x + w)         # the far shore
        if _level() >= 3 and rng.randf() < 0.4:
                _add_spike3(x + w - CELL * 1.5, GROUND_Y)
        return w

## THE HIGHWAY - a long L1 ride above a spiked floor: the line lane is the
## road, the ground is the danger, the on-ramp is a 1-tall block step.
func _chunk_highway(x: float) -> float:
        var w := CELL * 16.0
        _add_gseg(x, x + w)
        _add_rseg(x, x + w)
        var rx := x + CELL * 2.0
        _add_col(rx, 1, GROUND_Y)                 # the on-ramp
        _add_col(rx + CELL, 1, GROUND_Y)
        var lx := rx + CELL * 2.6
        var road_end := x + w - CELL * 2.0
        _add_line(lx, road_end, L1_Y)
        var i := 0
        var sx := lx + CELL
        while sx < road_end - CELL:
                _add_orbit(sx, L1_Y - 115.0)
                if i % 2 == 0 and _level() >= 3:
                        _add_spike3(sx, GROUND_Y)
                sx += CELL * 1.9
                i += 1
        return w

## THE TOWERS - full-height vertical play: a 3-tall tower pair, a 2-tall
## valley tower, then a 4-tall crown. The biggest up-and-down the box
## builds; every step is one cell and every apex clears the next.
func _chunk_towers(x: float) -> float:
        var w := CELL * 20.0
        _add_gseg(x, x + w)
        _add_rseg(x, x + w)
        var cx := x + CELL * 1.6
        for h: int in [3, 2, 4]:
                _add_col(cx, h, GROUND_Y)
                _add_col(cx + CELL, h, GROUND_Y)
                _add_orbit(cx + CELL * 0.5, GROUND_Y - float(h) * CELL - 115.0)
                cx += CELL * 3.4
        if _level() >= 4 and rng.randf() < 0.5:
                _add_spike3(cx + CELL * 0.8, GROUND_Y)
                _add_orbit(cx + CELL * 0.8, GROUND_Y - 250.0)
        return w

## THE LADDER (v0.3.6-1) - "proper obstacles to climb them up": a rising
## rung path (block -> line 1 -> line 2 -> line 3) with orbits marking the
## climb. The ground route stays safe below; the ladder is the clean lane
## (and the STICK route to the roof - from rung 3 one hop bonks the roof).
func _chunk_ladder(x: float) -> float:
        var w := CELL * 13.0
        _add_gseg(x, x + w)
        _add_rseg(x, x + w)
        var bx := x + CELL * 2.0
        _add_pusher(bx, GROUND_Y, false)
        var r1x := bx + CELL * 2.2
        var r2x := r1x + CELL * 2.9
        var r3x := r2x + CELL * 2.9
        # patch 3: the rungs are BLOCK ROWS now (the blocks are good surfaces)
        for i in 3:
                _add_block(r1x + float(i) * CELL, L1_Y, 1)
                _add_block(r2x + float(i) * CELL, L2_Y, 1)
                _add_block(r3x + float(i) * CELL, L3_Y, 1)
        _add_orbit(bx, GROUND_Y - CELL * 1.9)
        _add_orbit(r1x + CELL * 1.4, L1_Y - 110.0)
        _add_orbit(r2x + CELL * 1.4, L2_Y - 110.0)
        _add_orbit(r3x + CELL * 1.4, L3_Y - 110.0)
        # the floor threat under the climb at higher levels: the ladder is
        # the clean way past it (the owner: "obstacles to climb them up")
        if _level() >= 2 and rng.randf() < 0.6:
                _add_spike3(r2x + CELL * 1.2, GROUND_Y)
                _add_spike3(r2x + CELL * 2.1, GROUND_Y)
        return w

## THE FLOATERS (v0.3.6-1) - floating spike threats BETWEEN the lines (the
## owner: "the surface lines can have floating obstacles - use every single
## pixel"). They threaten the LINE-HOPPING lanes only: the ground route is
## a flat run (no forced jump under them), so they can never be unfair.
func _chunk_floaters(x: float) -> float:
        var w := CELL * rng.randf_range(8.0, 10.0)
        _add_gseg(x, x + w)
        _add_rseg(x, x + w)
        var y: float = [L1_Y - 66.0, L2_Y + 45.0, L2_Y - 66.0][rng.randi_range(0, 2)]
        var n := 1 if rng.randf() < 0.6 else 2
        var fx := x + CELL * rng.randf_range(2.5, 3.5)
        for i in n:
                _add_spike3(fx + i * CELL * 2.6, y)
        # the safe lane is marked with orbits (read the path, then commit)
        var oy := y + 150.0 if y < L2_Y else y - 150.0
        _orbit_line(fx - CELL * 0.6, clampf(oy, L3_Y + 60.0, L1_Y - 60.0), n + 1, CELL * 1.8)
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
                _add_spike3(x + w * 0.5, GROUND_Y)
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
                        _add_spike3(px + CELL * 2.4, ROOF_Y, true)
        return w

## ============================================================ THE WORLD LAW
## v0.3.6-3 - THE BUILT WORLD: block structures everywhere (the owner:
## "populate the world with blocks that make you climb them up or down and
## make cool shapes - not the simple thing that currently exists"). Every
## shape is self-contained fair: tops are real surfaces (THE CLIMB TRUTH),
## every step is +1 cell so the apex always clears it, the ground route
## climbs over or walks a marked lane, and threats never share a window
## with a forced jump.

## THE STAIRS - 2-3 rising steps (2-wide pads, 1-cell gaps): the pure climb.
## From level 2 a small triple-spike row waits under the far side - the tops
## are the safe road, the floor is the risky one.
func _chunk_stairs(x: float) -> float:
        var steps := rng.randi_range(2, 3)
        _add_gseg(x, x + CELL * 14.0)
        _add_rseg(x, x + CELL * 14.0)
        var cx := x + CELL * 1.6
        for i in steps:
                _add_col(cx, i + 1, GROUND_Y)
                _add_col(cx + CELL, i + 1, GROUND_Y)
                _add_orbit(cx + CELL * 0.5, GROUND_Y - float(i + 1) * CELL - 115.0)
                cx += CELL * 3.0
        if _level() >= 2 and rng.randf() < 0.65:
                _add_spike3(cx + CELL * 1.1, GROUND_Y)
                _add_orbit(cx + CELL * 1.1, GROUND_Y - 250.0)
        return CELL * 14.0

## THE GARDEN - rhythm singles: 3-4 pads (1-2 tall) spaced for hop-by-hop
## play, an orbit over each. The world's open dance floor.
func _chunk_garden(x: float) -> float:
        var n := rng.randi_range(3, 4)
        _add_gseg(x, x + CELL * 16.0)
        _add_rseg(x, x + CELL * 16.0)
        var cx := x + CELL * 2.0
        for i in n:
                var h := 1 + (1 if (i % 2 == 1 and _level() >= 2) else 0)
                _add_col(cx, h, GROUND_Y)
                _add_col(cx + CELL, h, GROUND_Y)
                _add_orbit(cx + CELL * 0.5, GROUND_Y - float(h) * CELL - 110.0)
                cx += CELL * rng.randf_range(3.0, 3.6)
        return CELL * 16.0

## THE PYRAMID - the climb-over with a peak: up 2-3 steps, then DOWN the
## other side (the climb-down taught in one shape). An orbit crowns it.
func _chunk_pyramid(x: float) -> float:
        var h := rng.randi_range(2, 3)
        _add_gseg(x, x + CELL * 18.0)
        _add_rseg(x, x + CELL * 18.0)
        var cx := x + CELL * 2.0
        for i in h:
                _add_col(cx, i + 1, GROUND_Y)
                _add_col(cx + CELL, i + 1, GROUND_Y)
                cx += CELL * 3.0
        _add_orbit(cx - CELL * 2.0, GROUND_Y - float(h + 1) * CELL - 115.0)
        for i in range(h - 1, 0, -1):
                _add_col(cx, i, GROUND_Y)
                _add_col(cx + CELL, i, GROUND_Y)
                cx += CELL * 3.0
        return CELL * 18.0

## THE DESCENT - the climb-down the owner missed: a raised line ride that
## steps DOWN to the ground on block pads (2-tall ~ the line's height, then
## 1-tall, then the floor). It climbs UP the very same path.
func _chunk_descent(x: float) -> float:
        var w := CELL * 15.0
        _add_gseg(x, x + w)
        _add_rseg(x, x + w)
        var lx := x + CELL * 1.5
        # patch 3: the ride is a BLOCK DECK now (not a thin platform)
        for i in 4:
                _add_block(lx + float(i) * CELL, L1_Y, 1)
        _orbit_line(lx + CELL * 0.5, L1_Y - 110.0, 3)
        var px := lx + CELL * 4.8
        _add_col(px, 2, GROUND_Y)
        _add_col(px + CELL, 2, GROUND_Y)
        var px2 := px + CELL * 3.2
        _add_col(px2, 1, GROUND_Y)
        _add_col(px2 + CELL, 1, GROUND_Y)
        _add_orbit(px + CELL, GROUND_Y - CELL * 2.0 - 115.0)
        _add_orbit(px2 + CELL, GROUND_Y - CELL - 115.0)
        if _level() >= 2 and rng.randf() < 0.5:
                _add_spike3(px2 + CELL * 3.4, GROUND_Y)
        return w

## THE TWIN TOWERS - two 2-cell towers with a hop valley between (the gap
## obeys the same math as the pits: the hop clears it at the live speed).
## From level 2 a small triple spike sits in the valley - the pads are the
## road, the hop is marked with orbits.
func _chunk_twin(x: float) -> float:
        var w := CELL * 14.0
        _add_gseg(x, x + w)
        _add_rseg(x, x + w)
        var t1 := x + CELL * 2.5
        var t2 := t1 + CELL * 4.5
        for i in 2:
                _add_col(t1 + float(i) * CELL, 2, GROUND_Y)
                _add_col(t2 + float(i) * CELL, 2, GROUND_Y)
        _add_orbit(t1 + CELL, GROUND_Y - CELL * 2.0 - 115.0)
        _add_orbit((t1 + t2) * 0.5 + CELL * 0.5, GROUND_Y - CELL * 2.6)
        _add_orbit(t2 + CELL, GROUND_Y - CELL * 2.0 - 115.0)
        if _level() >= 2:
                _add_spike3((t1 + t2) * 0.5 + CELL * 0.5, GROUND_Y)
        return w

## THE BRIDGE - a floating slab deck across a pit: the honest jump still
## clears it (the pit obeys the max-pit law), but the slab is the mid-air
## island - land, breathe, hop off. A low jump that clips the slab's
## underside bonks honestly (THE UNDER-BONK).
func _chunk_bridge(x: float) -> float:
        var lead := CELL * rng.randf_range(2.5, 3.5)
        var pit := CELL * rng.randf_range(1.8, _max_pit_cells())   # the honest jump still clears it
        var tail_run := CELL * rng.randf_range(3.0, 4.5)
        _add_gseg(x, x + lead)
        _add_gseg(x + lead + pit, x + lead + pit + tail_run)
        _add_rseg(x, x + lead + pit + tail_run)
        var sx := x + lead + (pit - CELL) * 0.5
        _add_block(sx, GROUND_Y - CELL * 1.6, 1)
        _add_block(sx + CELL, GROUND_Y - CELL * 1.6, 1)
        _add_orbit(sx + CELL * 0.5, GROUND_Y - CELL * 2.6)
        _add_orbit(sx + CELL * 1.5, GROUND_Y - CELL * 2.6)
        return lead + pit + tail_run

## THE ROOF STAIRS - the flip-mode climb-down: block pads hang from the roof
## stepping deeper into the screen (1-2-3 cells), each with a ONE-CELL gap
## under the roof so the roof-riding lane stays clear. The ride hops DOWN
## the chain pad to pad (catching their undersides); the ground lane runs
## clear under every hang. Orbits mark every pad.
func _chunk_roof_stairs(x: float) -> float:
        var w := CELL * 14.0
        _add_gseg(x, x + w)
        _add_rseg(x, x + w)
        var cx := x + CELL * 2.2
        for i in 3:
                _add_hang(cx, i + 1, ROOF_Y + CELL)
                _add_hang(cx + CELL, i + 1, ROOF_Y + CELL)
                _add_orbit(cx + CELL * 0.5, ROOF_Y + float(i + 2) * CELL + 105.0)
                cx += CELL * 3.0
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
        for pu in pow_pickups:
                pu["t"] = float(pu["t"]) + 0.016
                pu["spr"].position = Vector2((float(pu["x"]) - world_x) * us,
                        float(pu["y"]) * us + sin(pu["t"] * 3.0) * 9.0 * us)
        if not coin.is_empty():
                pass  # the coin positions itself in _coin_clock
        # cull behind
        _cull(gsegs, kill_x, "x1")
        _cull(rsegs, kill_x, "x1")
        _cull(lines, kill_x, "x1")
        _cull_arr(pushers, kill_x + CELL * 4.0)
        _cull_arr(hazards, kill_x + CELL * 4.0)
        _cull_arr(orbits, kill_x + CELL * 2.0)
        _cull_arr(pow_pickups, kill_x + CELL * 2.0)
        # the square
        var p := player
        _spin_tick(0.016 if phase == "run" else 0.0)
        # THE SCREEN-px TRUTH part 2: p["y"] is ALREADY screen px - the old
        # *us here double-scaled the sprite (the square rendered off its own
        # physics body at us != 1)
        pspr.position = Vector2(p["x"] + (rng.randf() - 0.5) * shake,
                p["y"] + (rng.randf() - 0.5) * shake)
        pspr.rotation_degrees = p["rot"]
        var base_s: float = (CELL * us) / (160.0 * 0.72)
        pspr.scale = Vector2(base_s * (2.0 - p["sq"]), base_s * p["sq"])
        # THE TAIL LAW: the emitters sit BEHIND the square - ALWAYS the
        # screen-left, world-scroll side (v0.3.6-3: the offset never rides
        # the square's rotation any more; a flip must not swing the trail
        # overhead or underfoot - the back is the back, always)
        var back := Vector2(-HALF * us * 0.85, 0)
        var tpos: Vector2 = pspr.position + back
        tail.position = tpos
        tail2.position = tpos + Vector2(-HALF * us * 0.4, 0)
        tail.initial_velocity_min = speed * us * 0.75
        tail.initial_velocity_max = speed * us * 1.05
        tail2.initial_velocity_min = speed * us * 0.85
        tail2.initial_velocity_max = speed * us * 1.25
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
## THE VFX OVERHAUL (v0.3.6-1): every effect is a LAYERED composition -
## additive glow sprites, shockwave rings, streaks and shards in the skin's
## own color - never the repeated small dots the owner called out. One-shot
## emitters free themselves; the additive material is the neon glue.
func _add_mat() -> CanvasItemMaterial:
        var m := CanvasItemMaterial.new()
        m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
        return m

func _burst_at(pos: Vector2, n: int, power: float) -> void:
        # the layered kick: a soft glow core + streak sparks, skin-colored
        var col: Color = SKINS[player.get("skin", "classic")]["col"]
        var core := CPUParticles2D.new()
        core.texture = _tex("p_soft.png")
        core.amount = maxi(4, n * 2)
        core.one_shot = true
        core.explosiveness = 1.0
        core.lifetime = 0.38
        core.direction = Vector2(0, -1)
        core.spread = 180.0
        core.initial_velocity_min = 60.0 * power * us
        core.initial_velocity_max = 240.0 * power * us
        core.gravity = Vector2(0, 300.0 * us)
        core.scale_amount_min = 0.5
        core.scale_amount_max = 1.15 * (0.6 + power)
        core.color = Color(col.r, col.g, col.b, 0.85)
        core.material = _add_mat()
        core.position = pos
        core.emitting = true
        add_child(core)
        var streak := CPUParticles2D.new()
        streak.texture = _tex("p_streak.png")
        streak.amount = maxi(3, n)
        streak.one_shot = true
        streak.explosiveness = 1.0
        streak.lifetime = 0.32
        streak.direction = Vector2(0, -1)
        streak.spread = 180.0
        streak.initial_velocity_min = 260.0 * power * us
        streak.initial_velocity_max = 620.0 * power * us
        streak.gravity = Vector2(0, 900.0 * us)
        streak.scale_amount_min = 0.4
        streak.scale_amount_max = 0.9 * (0.5 + power)
        streak.color = Color(1, 1, 1, 0.9)
        streak.material = _add_mat()
        streak.position = pos
        streak.emitting = true
        add_child(streak)
        get_tree().create_timer(1.0).timeout.connect(func():
                if is_instance_valid(core):
                        core.queue_free()
                if is_instance_valid(streak):
                        streak.queue_free())

## THE FLIP PUSH (v0.3.6-3) - the simple directional push: one puff of soft
## shapes leaving the face the square jumped OFF of, plus a faint ring.
func _push_puff(at: Vector2, from_g: int, col: Color, power := 1.0) -> void:
        var side := 1.0 if from_g == 1 else -1.0   # +1 = the puff sits BELOW
        var puff := CPUParticles2D.new()
        puff.texture = _tex("p_puff.png")
        puff.amount = 10
        puff.one_shot = true
        puff.explosiveness = 1.0
        puff.lifetime = 0.3
        puff.direction = Vector2(0, -side)          # travels AWAY from the square
        puff.spread = 26.0
        puff.initial_velocity_min = 240.0 * power * us
        puff.initial_velocity_max = 520.0 * power * us
        puff.gravity = Vector2.ZERO
        puff.scale_amount_min = 0.45
        puff.scale_amount_max = 0.95
        puff.color = Color(col.r, col.g, col.b, 0.85)
        puff.material = _add_mat()
        puff.position = at + Vector2(0, side * HALF * us * 0.8)
        puff.emitting = true
        add_child(puff)
        get_tree().create_timer(0.7).timeout.connect(func():
                if is_instance_valid(puff):
                        puff.queue_free())
        _ring_fx(at + Vector2(0, side * HALF * us * 0.5), col, 0.5 * power)

## The shockwave ring - the shared ceremony layer (saves, collects, death).
func _ring_fx(pos: Vector2, col: Color, power := 1.0) -> void:
        var r := Sprite2D.new()
        r.texture = _tex("p_ring.png")
        r.position = pos
        r.scale = Vector2.ONE * 0.25 * us
        r.modulate = Color(col.r, col.g, col.b, 0.9)
        r.material = _add_mat()
        add_child(r)
        var tw := r.create_tween()
        tw.set_parallel(true)
        tw.tween_property(r, "scale", Vector2.ONE * 1.6 * power * us, 0.34) \
                .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
        tw.tween_property(r, "modulate:a", 0.0, 0.34)
        tw.chain().tween_callback(func(): if is_instance_valid(r): r.queue_free())

## THE LANDING VFX LAW: fires ON the collision, scaled by the impact - a
## compressed dust ring on the surface + kick streaks in the skin color.
func _impact_fx(pos: Vector2, impact: float, g: int) -> void:
        var col: Color = SKINS[player.get("skin", "classic")]["col"]
        var power := clampf(impact / (1800.0 * us), 0.35, 1.35)
        var dust := CPUParticles2D.new()
        dust.texture = _tex("p_soft.png")
        dust.amount = 8
        dust.one_shot = true
        dust.explosiveness = 1.0
        dust.lifetime = 0.3
        dust.direction = Vector2(0, -float(g))
        dust.spread = 68.0
        dust.initial_velocity_min = 130.0 * power * us
        dust.initial_velocity_max = 320.0 * power * us
        dust.gravity = Vector2(0, 240.0 * us * float(g))
        dust.scale_amount_min = 0.4
        dust.scale_amount_max = 0.85 * power
        dust.color = Color(col.r, col.g, col.b, 0.7)
        dust.material = _add_mat()
        dust.position = pos
        dust.rotation_degrees = 0.0 if g == 1 else 180.0
        dust.emitting = true
        add_child(dust)
        get_tree().create_timer(0.8).timeout.connect(func():
                if is_instance_valid(dust):
                        dust.queue_free())
        _ring_fx(pos, col, 0.55 * power)

## The bonk (head meets an underside): a small white star flash + a soft
## ring, quieter than a landing (it is a warning, not an event).
func _bonk_fx(pos: Vector2) -> void:
        var col: Color = SKINS[player.get("skin", "classic")]["col"]
        var s := Sprite2D.new()
        s.texture = _tex("p_star.png")
        s.position = pos
        s.scale = Vector2.ONE * 0.3 * us
        s.modulate = Color(1, 1, 1, 0.85)
        s.material = _add_mat()
        add_child(s)
        var tw := s.create_tween()
        tw.set_parallel(true)
        tw.tween_property(s, "scale", Vector2.ONE * 0.95 * us, 0.22)
        tw.tween_property(s, "modulate:a", 0.0, 0.22)
        tw.chain().tween_callback(func(): if is_instance_valid(s): s.queue_free())
        _ring_fx(pos, col, 0.45)

## THE COLLECT LAW (patch 3): the owner's own words - simplify it to be
## JUST the yellow circle. One expanding ring, nothing else (the old glow
## pop + star flashes + streaks was too much). The GOGACoin wears the same.
func _orbit_collect_fx(at: Vector2, to: Vector2) -> void:
        _ring_fx(at, Color(1.0, 0.85, 0.4), 0.8)

func _coin_collect_fx(at: Vector2, to: Vector2) -> void:
        _ring_fx(at, Color(1.0, 0.85, 0.4), 1.0)
        _ring_fx(to, Color(1.0, 0.85, 0.4), 1.1)

func _death_burst() -> void:
        var p := player
        var pos := Vector2(p["x"], p["y"])
        shake = 16.0
        var col: Color = SKINS[player.get("skin", "classic")]["col"]
        # 1. the double shockwave (fast white, slow colored)
        _ring_fx(pos, Color(1, 1, 1), 1.5)
        _ring_fx(pos, col, 2.2)
        # 2. the flash of the soul square: an expanding ghost of the skin
        var ghost := Sprite2D.new()
        ghost.texture = pspr.texture
        ghost.position = pos
        ghost.rotation_degrees = p["rot"]
        ghost.scale = pspr.scale * 1.1
        ghost.modulate = Color(col.r, col.g, col.b, 0.9)
        add_child(ghost)
        var gtw := ghost.create_tween()
        gtw.set_parallel(true)
        gtw.tween_property(ghost, "scale", pspr.scale * 2.6, 0.42) \
                .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
        gtw.tween_property(ghost, "modulate:a", 0.0, 0.42)
        gtw.chain().tween_callback(func(): if is_instance_valid(ghost): ghost.queue_free())
        # 3. the shard storm (the body bursts into rotating neon glass)
        var shards := CPUParticles2D.new()
        shards.texture = _tex("p_shard.png")
        shards.amount = 18
        shards.one_shot = true
        shards.explosiveness = 1.0
        shards.lifetime = 0.75
        shards.spread = 180.0
        shards.initial_velocity_min = 300.0 * us
        shards.initial_velocity_max = 780.0 * us
        shards.gravity = Vector2(0, 1500.0 * us)
        shards.angular_velocity_min = -540.0
        shards.angular_velocity_max = 540.0
        shards.scale_amount_min = 0.5
        shards.scale_amount_max = 1.2
        shards.color = col
        shards.position = pos
        shards.emitting = true
        add_child(shards)
        # 4. the glow embers that linger and fade
        var embers := CPUParticles2D.new()
        embers.texture = _tex("p_soft.png")
        embers.amount = 14
        embers.one_shot = true
        embers.explosiveness = 1.0
        embers.lifetime = 0.9
        embers.spread = 180.0
        embers.initial_velocity_min = 60.0 * us
        embers.initial_velocity_max = 220.0 * us
        embers.gravity = Vector2(0, -160.0 * us)
        embers.scale_amount_min = 0.5
        embers.scale_amount_max = 1.3
        embers.color = Color(col.r, col.g, col.b, 0.75)
        embers.material = _add_mat()
        embers.position = pos
        embers.emitting = true
        add_child(embers)
        pspr.visible = false
        get_tree().create_timer(1.4).timeout.connect(func():
                if is_instance_valid(shards):
                        shards.queue_free()
                if is_instance_valid(embers):
                        embers.queue_free())

func _idle_pulse(delta: float) -> void:
        var p := player
        # THE READY GROUND LAW: the bob breathes UP from the surface only and
        # stays inside the support snap band - a run start can never bury the
        # square (and _ready_start snaps the stance anyway)
        p["y"] = (GROUND_Y - HALF) * us - absf(sin(beat_t * 2.4)) * 3.0 * us
        pspr.position = Vector2(p["x"], p["y"])
        pspr.rotation_degrees = 0.0

## The per-frame widgets + live effect layers (the chips, the rocket burn,
## the shield pulse, the trail speed - SLOW WORLD even slows the trail).
func _fx_tick(dt: float) -> void:
        var ts := SLOW_SCALE if powers["slow"] > 0.0 else 1.0
        tail.speed_scale = ts
        tail2.speed_scale = ts
        var skin: Color = SKINS[player.get("skin", "classic")]["col"]
        # (v0.3.6-3: the rocket burn is a one-shot ON the jump - no plume here)
        # the extra-life mark: dark core + breathing aura
        var shielded: bool = powers["shield"] > 0.0
        shield_spr.visible = shielded
        if shielded:
                var pulse := 0.35 + 0.2 * sin(beat_t * 6.0)
                shield_aura.modulate = Color(POWERS["shield"]["col"], pulse)
        # the power chips (next to the mechanic chip - the owner's law)
        for k in POWERS:
                var chip: Dictionary = pow_chips.get(k, {})
                if chip.is_empty():
                        continue
                var on: bool = powers[k] > 0.0
                chip["panel"].visible = on
                if on:
                        chip["label"].text = str(int(ceilf(powers[k])))
                        var glow := 0.55 + 0.3 * sin(beat_t * 7.0)
                        chip["panel"].self_modulate = Color(POWERS[k]["col"], glow)

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
        box.add_child(_shop_label("POWER-UPS - they spawn in your runs"))
        for id in POWERS:
                box.add_child(_pow_row(id))
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                func(): sheet_pop()))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _goga_sheet_popped(id: String) -> void:
        if id == "lore":
                # v0.3.7-1: the story is told - the gate comes back
                if ready_ui != null and is_instance_valid(ready_ui):
                        ready_ui.visible = true
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
                # THE NONE COLOR TRUTH (v0.3.6-3): with a tail worn, this row
                # is the REMOVE action - but brown reads "currently in use",
                # which none is not. It wears the VIOLET of every other
                # not-worn item; tapping it still strips the tail.
                return Arc.button("%s - TRAIL OFF" % c["name"], Vector2(560, 60), 22,
                        Color("8a4ab8"), func():
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

## THE POWER ROWS: buy standalone, own forever - owned powers may spawn in
## every future run (they are unlocks, not consumables).
func _pow_row(id: String) -> Control:
        var c: Dictionary = POWERS[id]
        if Box.item_owned(game_id, "power", id):
                var l := Arc.fit_label("%s  (OWNED) - %s" % [c["name"], c["desc"]],
                        22, Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        return _price_btn("%s - %s" % [c["name"], c["desc"]], int(c["price"]),
                Color("b8583a"), func():
                        if Box.buy_item(game_id, "power", id, int(c["price"])):
                                Jukebox.sfx("buy")
                        _shop_reopen())

# =================================================================== probe
## The headless contract: a deterministic run any probe can drive.
func probe_reset(seed_v: int) -> void:
        rng.seed = seed_v
        for arr in [orbits, hazards, pushers, gsegs, rsegs, lines]:
                for o in arr:
                        if o.get("spr") != null and is_instance_valid(o["spr"]):
                                o["spr"].queue_free()
                arr.clear()
        for arr in [pow_pickups]:
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
        pow_timer = 1e9           # ...and power-ups explicitly
        powers = {"jump": 0.0, "slow": 0.0, "shield": 0.0}
        shield_cd = 0.0
        next_bonus = SPEED_BONUS_AT
        pspr.visible = true
        shield_spr.visible = false
        rocket.emitting = false
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



