extends GogaGame
## POP SIEGE (v0.3.5-4) - the doors-roll patch. Grid-perfect fillet roads
## (the march line IS the beaten track), chevrons stamped on the march,
## RANDOM door crews that grow with the wave, the whole viewport sleeps at
## night, the shop scroll stays put through a buy, and the bomber's shell
## dies at its own blast (no more floating balls, no lingering wisps).

const COLS := 18
const ROWS := 10
# the layout law: the field and the panel COMPUTE from the real viewport
# (the box stretch is expand - the logical space is huge in landscape)
var CELL := 56.0
var FIELD := Vector2(16, 66)            # field top-left in the viewport
var PANEL_X := 1048.0                   # the folk panel's left edge
const A := "res://assets/games/pop_siege/"

# ------------------------------------------------------------------- state
var meta: PDMeta
var map: Dictionary
var night := false
var coins := PDData.START_COINS
var lives := PDData.START_LIVES
var wave_n := 0
var phase := "ready"         # ready | idle | spawn | clear | over
var countdown := 0.0
var speed_mult := 1          # x1 -> x2 -> x3 (the owner's law)
var auto_waves := true       # the A/M law (remembered across runs)
var victory_done := false
var shake_t := 0.0
var rng := RandomNumberGenerator.new()

var bloons: Array = []       # {id, kind, hp, max_hp, pi, dist, lane, spd, slow_f, slow_t,
                             #  glue_t, glue_dps, burn_dps, burn_t, stun_t, rider, depth, spr, frozen_by}
var bullets: Array = []      # pooled projectiles
var folk: Array = []         # placed folk {id, fid, gear, lvl, cell, pos, cd, mode, inflicted,
                             #  spr, badges:[], buffs:{}, timers:{}}
var traps: Array = []        # pyra fire traps {pos, t, dps, spr}
var patches: Array = []      # kolda permafrost {pos, t, r}
var zones2d: Node2D
var spawn_q: Array = []      # [{kind, at}] absolute times
var spawn_clock := 0.0
var wave_kinds: Array = []   # kinds used this wave (for the rider pick)
var rider_index := -1        # spawn index carrying the GOGACoin
var spawn_count := 0

var field: Node2D
var world: Node2D                      # THE WORLD SORT LAW (y-sorted props/heart/folk)
var ready_box: Control                 # the READY gate (the start law)
var next_btn: Button                   # the field NEXT WAVE button
var ghost_draw: Node2D
var sel_draw: Node2D
var night_rect: ColorRect
var fireflies: CPUParticles2D
var heart_spr: Sprite2D
var bloon_layer: Node2D
var fx_layer: Node2D
var bullet_layer: Node2D
var folk_layer: Node2D

var panel: Control
var chips: Dictionary = {}       # lives/coins/wave labels
var wave_lbl: Label              # the countdown line (NEVER tappable)
var cards_box: GridContainer
var card_panels: Dictionary = {} # fid -> card panel (the highlight paint)
var menu_box: VBoxContainer
var selected_place := ""         # folk id being placed
var selected_folk: Dictionary = {}   # the placed folk tapped
var ghost: Node2D                # base+head ghost while placing
var ghost_head: Sprite2D
var ghost_cell := Vector2i(-1, -9)
var _placing_drag := false       # the finger dragged (release places)
var _tex: Dictionary = {}
var _pop_pitch := 0
var _pop_frames: Array = []
var _boom_frames: Array = []

func _t(p: String) -> Texture2D:
        if not _tex.has(p):
                _tex[p] = load(A + p)
        return _tex[p]

func _fs(sz: int) -> int:
        # the big-text law inherited from the house style: keep the field UI loud
        return int(sz * 1.15)

func _frames(prefix: String, n: int) -> Array:
        var out: Array = []
        for i in n:
                var p := "%s%02d.png" % [prefix, i]
                if ResourceLoader.exists(A + p):
                        out.append(load(A + p))
        return out

# ------------------------------------------------------------------ helpers
func _cell_pos(c: float, r: float) -> Vector2:
        return Vector2(FIELD.x + (c + 0.5) * CELL, FIELD.y + (r + 0.5) * CELL)

func _cell_of(p: Vector2) -> Vector2i:
        return Vector2i(int((p.x - FIELD.x) / CELL), int((p.y - FIELD.y) / CELL))

func _in_field(p: Vector2) -> bool:
        return p.x >= FIELD.x and p.x < FIELD.x + COLS * CELL and p.y >= FIELD.y and p.y < FIELD.y + ROWS * CELL

func _blocked_cells() -> Dictionary:
        if _blocked_cache.is_empty():
                var b := {}
                for c in map["blocked"]:
                        b[Vector2i(int(c[0]), int(c[1]))] = true
                for w in map.get("water", []):
                        b[Vector2i(int(w[0]), int(w[1]))] = true
                # THE GRID LAW: the roads ARE cells now - the map's road_cells
                # are the paint truth AND the build truth (one source)
                for rc in map.get("road_cells", []):
                        b[Vector2i(int(rc[0]), int(rc[1]))] = true
                b[Vector2i(map["heart"][0], map["heart"][1])] = true
                _blocked_cache = b
        return _blocked_cache

var _blocked_cache: Dictionary = {}

func _buildable(c: Vector2i) -> bool:
        if c.x < 0 or c.x >= COLS or c.y < 0 or c.y >= ROWS:
                return false
        return not _blocked_cells().has(c)

# ------------------------------------------------------------------- setup
func _layout() -> void:
        # THE LAYOUT LAW: fit the 18x10 field + the folk panel into the REAL
        # logical viewport (whatever the stretch made of it)
        var vp := get_viewport_rect().size
        var panel_w := minf(560.0, vp.x * 0.30)
        var top := 62.0
        CELL = minf((vp.x - panel_w - 44.0) / float(COLS), (vp.y - top - 14.0) / float(ROWS))
        FIELD = Vector2(16.0, top + maxf(4.0, (vp.y - top - 14.0 - ROWS * CELL) * 0.5))
        PANEL_X = FIELD.x + COLS * CELL + 16.0

func _goga_setup() -> void:
        rng.randomize()
        _layout()
        pause_end_run = false
        meta = PDMeta.load_meta()
        auto_waves = meta.auto_waves()
        map = PDData.map_by_id(meta.current_map())
        night = meta.is_night(map["id"])
        coins = PDData.START_COINS
        lives = PDData.START_LIVES
        wave_n = 0
        victory_done = false
        _pop_frames = _frames("fx/pop_", 10)
        _boom_frames = _frames("fx/boom_", 7)
        set_hud_score_prefix("POPS")
        _score_icon()                        # THE SCORE ICON LAW: the layered bloon
        add_hud_button("SHOP", func(): _shop_open())
        add_hud_button("MAPS", func(): _maps_open())
        # the PAUSE button is dead (the owner: back does the same thing)
        _build_field()
        _build_panel()
        _rebuild_cards()
        _build_night()
        _build_ready()
        _goga_tk_ready()
        Jukebox.music("res://assets/audio/music/ps_theme.wav")
        check_achievements()

# ------------------------------------------------------------ the ready gate
func _build_ready() -> void:
        # THE START LAW: the siege never boots straight into the march. The
        # field shows itself, the plan is open - nothing moves until START.
        ready_box = Control.new()
        ready_box.set_anchors_preset(Control.PRESET_FULL_RECT)
        ready_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
        # the gate lives on the HUD overlay (a true viewport-anchored parent -
        # a Control under the game Node2D has no rect to fill)
        _overlay_root_ref().add_child(ready_box)
        var dim := ColorRect.new()
        dim.color = Color(0.06, 0.04, 0.02, 0.45)
        dim.set_anchors_preset(Control.PRESET_FULL_RECT)
        dim.mouse_filter = Control.MOUSE_FILTER_STOP
        ready_box.add_child(dim)
        var cc := CenterContainer.new()
        cc.set_anchors_preset(Control.PRESET_FULL_RECT)
        cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        ready_box.add_child(cc)
        var card := PanelContainer.new()
        var st := Arc.panel_style(Color(0.98, 0.94, 0.86, 0.97), 24, 26)
        card.add_theme_stylebox_override("panel", st)
        cc.add_child(card)
        var vb := VBoxContainer.new()
        vb.add_theme_constant_override("separation", 10)
        card.add_child(vb)
        var dn := "NIGHT" if night else "DAY"
        var title := Arc.label("%s  %s" % [String(map["name"]).to_upper(), dn], _fs(30), Arc.INK)
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(title)
        # THE DOORS SPEAK: multi-start maps tell their wave law up front
        var n_paths: int = (map["paths"] as Array).size()
        if n_paths > 1:
                var door_txt := "%d DOORS - EVERY WAVE ROLLS ITS OWN CREW - IT GROWS" % n_paths
                var dl := Arc.label(door_txt, _fs(16), Color(0.55, 0.44, 0.28))
                dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                vb.add_child(dl)
        var go := Arc.button("START", Vector2(340, 74), _fs(30), Arc.GOOD, func():
                _start_ready())
        vb.add_child(go)

func _start_ready() -> void:
        if ready_box != null and is_instance_valid(ready_box):
                ready_box.queue_free()
                ready_box = null
        phase = "idle"
        countdown = 0.0
        # THE FIRST WAVE LAW: wave 1 NEVER rides a countdown - the owner
        # calls it with the SEND button, in AUTO and MANUAL alike
        _refresh_chips()
        Jukebox.sfx("ps_click", -6.0)

## THE SCORE ICON LAW: a layered bloon next to the score (the owner asked
## for a bloon shape that reflects the layers and the damage).
func _score_icon() -> void:
        var chip := _score_chip_ref()
        if chip == null or not is_instance_valid(chip):
                return
        var h := chip.get_child(0)
        if h == null or not is_instance_valid(h) or h.get_child_count() == 0:
                return
        if (h as Control).has_meta("pops_icon"):
                return
        var ic := TextureRect.new()
        ic.texture = _t("ui/ic_pops.png")
        ic.custom_minimum_size = Vector2(34, 34)
        ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        ic.set_meta("pops_icon", true)
        (h as Control).add_child(ic)
        (h as Control).move_child(ic, 0)

# ------------------------------------------------------------ field build
func _build_field() -> void:
        field = Node2D.new()
        add_child(field)
        # the painted board (baked at build time - the map IS a picture)
        var g := Sprite2D.new()
        g.texture = load(A + "bakes/%s.webp" % map["id"])
        g.centered = false
        g.position = FIELD
        g.scale = Vector2(COLS * CELL / float(g.texture.get_width()), ROWS * CELL / float(g.texture.get_height()))
        field.add_child(g)
        # water shimmer (a light pass over the baked pools - the ice maps skip it)
        if map.get("water_kind", "water") != "ice":
                for w in map.get("water", []):
                        var wr := ColorRect.new()
                        wr.size = Vector2(CELL, CELL)
                        wr.position = Vector2(FIELD.x + w[0] * CELL, FIELD.y + w[1] * CELL)
                        wr.modulate = Color(1, 1, 1, 0.34)
                        wr.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        var m := ShaderMaterial.new()
                        m.shader = load("res://game/games/pop_siege/fx/ps_water.gdshader")
                        m.set_shader_parameter("is_lava", 1.0 if map.get("water_kind", "") == "lava" else 0.0)
                        wr.material = m
                        field.add_child(wr)
        # THE WORLD SORT LAW: props + the heart + the folk live in ONE
        # y-sorted layer seated at their BASE - a big tree finally covers the
        # small one behind it (the owner's z-order round)
        world = Node2D.new()
        world.y_sort_enabled = true
        field.add_child(world)
        var pscale := CELL / 62.0
        for bcell in map["blocked"]:
                var spr := Sprite2D.new()
                spr.texture = _t("props/%s.png" % bcell[2])
                # seated at the cell's BASE line; the texture draws up from it
                spr.position = _cell_pos(bcell[0], bcell[1]) + Vector2(0, CELL * 0.34)
                spr.offset = Vector2(0, -spr.texture.get_height() * 0.5 + 6.0)
                spr.scale = Vector2(pscale, pscale)
                world.add_child(spr)
        # the heart house at every path's end
        heart_spr = Sprite2D.new()
        heart_spr.texture = _t("props/house.png")
        var hs := CELL * 1.9 / float(heart_spr.texture.get_height())
        heart_spr.position = _cell_pos(map["heart"][0], map["heart"][1]) + Vector2(0, CELL * 0.5)
        heart_spr.offset = Vector2(0, -heart_spr.texture.get_height() * 0.5 + 8.0)
        heart_spr.scale = Vector2(hs, hs)
        world.add_child(heart_spr)
        # layers (the folk join the world sort; bloons/bullets/fx fly above)
        folk_layer = Node2D.new(); folk_layer.y_sort_enabled = true; world.add_child(folk_layer)
        bloon_layer = Node2D.new(); field.add_child(bloon_layer)
        bullet_layer = Node2D.new(); field.add_child(bullet_layer)
        fx_layer = Node2D.new(); field.add_child(fx_layer)
        ghost_draw = GhostDraw.new(); ghost_draw.game = self; field.add_child(ghost_draw)
        sel_draw = SelDraw.new(); sel_draw.game = self; field.add_child(sel_draw)
        zones2d = ZoneDraw.new(); zones2d.game = self; field.add_child(zones2d)
        _build_paths()
        _build_next_button()
        # fireflies (night law)
        fireflies = CPUParticles2D.new()
        fireflies.amount = 26
        fireflies.lifetime = 6.0
        fireflies.preprocess = 3.0
        fireflies.texture = _t("fx/firefly.png")
        fireflies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
        fireflies.emission_rect_extents = Vector2(COLS * CELL, ROWS * CELL) * 0.5
        fireflies.position = FIELD + Vector2(COLS, ROWS) * CELL * 0.5
        fireflies.gravity = Vector2.ZERO
        fireflies.initial_velocity_min = 6.0
        fireflies.initial_velocity_max = 16.0
        fireflies.color = Color(1.0, 0.95, 0.6, 0.7)
        fireflies.visible = night
        field.add_child(fireflies)

func _build_next_button() -> void:
        # THE NEXT WAVE button (the field's pink call): idle -> call now, roll
        # -> stack the next wave. Lives above the field, right under the panel.
        next_btn = Arc.button("SEND WAVE 1", Vector2(190, 52), _fs(19), Color(0.90, 0.24, 0.44), func(): _next_wave_pressed())
        next_btn.position = FIELD + Vector2(COLS * CELL - 202, ROWS * CELL + 8)
        if next_btn.position.y + 52 > get_viewport_rect().size.y:
                next_btn.position.y = get_viewport_rect().size.y - 58
        add_child(next_btn)

func _build_paths() -> void:
        # the dense spline points -> px polylines (the bake drew the SAME
        # points, so the road and the march agree pixel for pixel)
        # v0.3.5-6 THE CENTERLINE TRUTH (the owner: "the bloons are walking
        # on non-perfect grid-based movement so they are visualized out of
        # the center and on each direction they shift in much weirder
        # positions"): the path data is authored in CELL-CENTER coordinates
        # (the heart's walk-in point [17.5, 5.5] IS the house's center, the
        # door [-0.5, 1.5] pokes in from the edge) and the bake strokes the
        # road at point * 64 - the old runtime's extra + 0.5 marched every
        # bloon HALF A CELL off the painted road (up on horizontals, left on
        # verticals - the weird per-direction shift). The march rides the
        # raw point now, pixel for pixel with the paint.
        _paths_px.clear()
        for pts in map["paths"]:
                var px := PackedVector2Array()
                for c in pts:
                        px.append(Vector2(FIELD.x + c[0] * CELL, FIELD.y + c[1] * CELL))
                var lens := PackedFloat32Array()
                lens.resize(px.size())
                var total := 0.0
                lens[0] = 0.0
                for i in range(1, px.size()):
                        total += px[i - 1].distance_to(px[i])
                        lens[i] = total
                _paths_px.append({"pts": px, "lens": lens, "total": total})

var _paths_px: Array = []

func pos_on(pi: int, dist: float) -> Dictionary:
        var P: Dictionary = _paths_px[pi]
        var d := clampf(dist, 0.0, P["total"])
        var pts: PackedVector2Array = P["pts"]
        var lens: PackedFloat32Array = P["lens"]
        for i in range(1, pts.size()):
                if d <= lens[i] or i == pts.size() - 1:
                        var seg := maxf(0.001, lens[i] - lens[i - 1])
                        var t := clampf((d - lens[i - 1]) / seg, 0.0, 1.0)
                        return {"p": pts[i - 1].lerp(pts[i], t), "dir": (pts[i] - pts[i - 1]).normalized()}
        return {"p": pts[-1], "dir": Vector2.RIGHT}

# ------------------------------------------------------------ day / night
var night_lamp: Sprite2D

func _build_night() -> void:
        if night_rect != null:
                night_rect.queue_free()
                night_rect = null
        if night_lamp != null:
                night_lamp.queue_free()
                night_lamp = null
        if fireflies != null:
                fireflies.visible = night
        if not night:
                return
        # THE NIGHT LAW v2 (v0.3.5-4): the tint covers the WHOLE viewport -
        # tall trees poking above the board and everything past the frame
        # sleeps under the same night (the old rect stopped at the board
        # edge - the owner's "tall things are not affected by the night").
        # The folk panel and the HUD draw ABOVE this rect (tree order + the
        # HUD layer), so the UI never sleeps.
        night_rect = ColorRect.new()
        var vp := get_viewport_rect().size
        night_rect.size = vp + Vector2(28, 28)     # the shake margin
        night_rect.position = Vector2(-14, -14)
        night_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        night_rect.color = PDData.THEMES[map["theme"]]["night"]
        var mm := CanvasItemMaterial.new()
        mm.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
        night_rect.material = mm
        field.add_child(night_rect)
        if fireflies != null:
                field.add_child(fireflies)         # the fireflies glow ABOVE the tint
        var lamp := Sprite2D.new()
        lamp.texture = _t("fx/spark.png")
        lamp.position = heart_spr.position
        lamp.scale = Vector2(14.0, 14.0)
        lamp.modulate = Color(1.0, 0.8, 0.45, 0.30)
        var lm := CanvasItemMaterial.new()
        lm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
        lamp.material = lm
        field.add_child(lamp)
        night_lamp = lamp

# ------------------------------------------------------------ right panel
func _build_panel() -> void:
        panel = Control.new()
        panel.position = Vector2(PANEL_X, 60)
        panel.size = Vector2(get_viewport_rect().size.x - PANEL_X - 10, get_viewport_rect().size.y - 60)
        add_child(panel)
        var vb := VBoxContainer.new()
        vb.set_anchors_preset(Control.PRESET_FULL_RECT)
        vb.add_theme_constant_override("separation", 8)
        panel.add_child(vb)
        # chips row: lives / popcoins / wave
        var chips_row := HBoxContainer.new()
        chips_row.add_theme_constant_override("separation", 6)
        vb.add_child(chips_row)
        chips["lives"] = Arc.chip("100", A + "ui/heart.png", Color(0.10, 0.06, 0.03, 0.55), _fs(24))
        chips_row.add_child(chips["lives"])
        chips["coins"] = Arc.chip("250", A + "ui/popcoin.png", Color(0.10, 0.06, 0.03, 0.55), _fs(24))
        chips_row.add_child(chips["coins"])
        chips["wave"] = Arc.chip("WAVE 0", A + "ui/ic_wave.png", Color(0.10, 0.06, 0.03, 0.55), _fs(24))
        chips_row.add_child(chips["wave"])
        # the wave row: speed (x1..x3) + A/M + the countdown line (NEVER a button)
        var wave_row := HBoxContainer.new()
        wave_row.add_theme_constant_override("separation", 6)
        vb.add_child(wave_row)
        var sp := Arc.button("x1", Vector2(58, 44), _fs(21), Color(0.22, 0.15, 0.08), func(): _toggle_speed())
        wave_row.add_child(sp)
        chips["speed_btn"] = sp
        var am := Arc.button("AUTO", Vector2(132, 44), _fs(18), Arc.GOOD, func(): _toggle_am())
        # v0.3.8-4: 132 fits "MANUAL" - the old 104 made the AUTO/MANUAL
        # toggle's text walk out the right side (the owner: "the word manual
        # is bigger than auto and makes the text goes to the right side")
        wave_row.add_child(am)
        chips["am_btn"] = am
        _paint_am()      # THE A/M TRUTH LAW: the button paints the RESTORED mode
        wave_lbl = Arc.label("PRESS START", _fs(22), Color(1, 0.95, 0.8))
        wave_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        wave_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        # v0.3.8-4: clip keeps the label's MINIMUM width at 0 - the row can
        # never push past the panel while the fitted font catches up
        wave_lbl.clip_text = true
        wave_row.add_child(wave_lbl)
        # the folk cards (2 columns x 5)
        cards_box = GridContainer.new()
        cards_box.columns = 2
        cards_box.add_theme_constant_override("h_separation", 6)
        cards_box.add_theme_constant_override("v_separation", 6)
        vb.add_child(cards_box)
        # the upgrade menu slot (the >> law lives here)
        menu_box = VBoxContainer.new()
        menu_box.add_theme_constant_override("separation", 4)
        vb.add_child(menu_box)
        _refresh_chips()

func _toggle_speed() -> void:
        speed_mult = 1 if speed_mult >= 3 else speed_mult + 1
        (chips["speed_btn"] as Button).text = "x%d" % speed_mult
        Jukebox.sfx("ps_click", -10.0, 0.9 + 0.1 * speed_mult)

func _toggle_am() -> void:
        auto_waves = not auto_waves
        meta.set_auto_waves(auto_waves)
        _paint_am()
        Jukebox.sfx("ps_click", -10.0, 1.1)

func _paint_am() -> void:
        var am := chips["am_btn"] as Button
        am.text = "AUTO" if auto_waves else "MANUAL"
        Arc.repaint_button(am, Arc.GOOD if auto_waves else Color(0.42, 0.44, 0.5))

func _chip_label(pc: PanelContainer) -> Label:
        # the Arc.chip wraps its label one panel deep
        for h in pc.get_children():
                for c in h.get_children():
                        if c is Label:
                                return c
        return null

func _refresh_chips() -> void:
        if chips.is_empty():
                return
        # v0.3.8-3 THE CHIP BUDGET (the lag law): per-damage pay means the
        # purse moves almost every frame - the old sig repainted EVERY chip,
        # the wave line, the button text AND every folk card + menu button
        # on each coin point. Each piece now moves only when ITS OWN value
        # moves; the afford paint runs on a flip, not on a heartbeat.
        var lc := int(coins)
        if lc != _chip_coins:
                _chip_coins = lc
                _chip_label(chips["coins"]).text = str(maxi(0, lc))
        var ll := maxi(0, lives)
        if ll != _chip_lives:
                _chip_lives = ll
                _chip_label(chips["lives"]).text = str(ll)
        if wave_n != _chip_wave:
                _chip_wave = wave_n
                _chip_label(chips["wave"]).text = "WAVE %d" % wave_n
        if wave_lbl != null:
                var line := ""
                if phase == "ready":
                        line = "PRESS START"
                elif phase == "idle":
                        if wave_n == 0:
                                line = "SEND THE FIRST WAVE"
                        elif auto_waves:
                                line = "NEXT WAVE IN %ds" % int(ceil(countdown))
                        else:
                                line = "WAVE %d READY" % (wave_n + 1)
                else:
                        line = "WAVE %d ROLLING" % wave_n
                if line != _chip_line:
                        _chip_line = line
                        # v0.3.8-4 THE FITTED WAVE LINE (the owner: "the words
                        # at the top that says send the first wave letters ve
                        # are out of resolution"): the line steps its font
                        # down until it fits the seat the x1 + AUTO/MANUAL
                        # buttons leave it.
                        # THE HONEST SEAT (the rig caught the E still cut):
                        # the label's OWN size.x is its text's minimum width -
                        # feeding it back as the seat can never shrink the
                        # font (399 in, 399 out). The seat is the ROW's real
                        # room: the panel minus the two fixed buttons, the
                        # gaps and a breath.
                        var seat: float = get_viewport_rect().size.x - 240.0
                        if panel != null and is_instance_valid(panel) \
                                        and panel.size.x > 200.0:
                                seat = panel.size.x - 58.0 - 132.0 - 12.0 - 10.0
                        # THE FIT EATS THE 1.15 (the rig caught the E cut
                        # twice): _fs multiplies by 1.15 - inflating the
                        # FITTED size back past the seat (fit 20 -> paint
                        # 23). Fit the LOUD size, use the fitted int as-is.
                        wave_lbl.add_theme_font_size_override("font_size",
                                        Arc.fit_size(line, _fs(22), seat,
                                        null, true, 13))
                        wave_lbl.text = line
        if next_btn != null and is_instance_valid(next_btn):
                var btxt := ""
                if phase == "idle":
                        btxt = "SEND WAVE %d" % (wave_n + 1)
                elif phase == "spawn" or phase == "clear":
                        btxt = "NEXT WAVE"
                if btxt != _chip_btxt:
                        _chip_btxt = btxt
                        next_btn.text = btxt
                var bvis := phase != "ready"
                if bvis != next_btn.visible:
                        next_btn.visible = bvis
        # the afford paint: only when a card's affordability or the selection
        # actually flipped (a string of booleans - the cheapest honest sig)
        # v0.3.8-4: the menu's OWN doors ride the sig too - the upgrade and
        # gear-up buttons the purse could not open MUST gray-in live when the
        # pops pay (the owner: "waited in that state and earned the money,
        # the button do not come available, it stays grayed-out")
        var asig := str(selected_place) + "|"
        for fid in card_panels:
                asig += "1" if coins >= int(PDData.FOLK[fid]["place"]) else "0"
        asig += "|" + str(int(menu_box != null and is_instance_valid(menu_box)))
        if menu_box != null and is_instance_valid(menu_box):
                # v0.3.8-4: has_meta FIRST - get_meta(key, default) still
                # ERRORS in Godot 4.7 when the key is missing (the boot log
                # proved it on the very first paint before the menu builds
                # its buttons).
                if menu_box.has_meta("up_btn"):
                        var upb: Button = menu_box.get_meta("up_btn")
                        if upb != null and is_instance_valid(upb):
                                asig += "1" if coins >= int(menu_box.get_meta("up_cost", 0)) else "0"
                if menu_box.has_meta("gear_btn"):
                        var gb: Button = menu_box.get_meta("gear_btn")
                        if gb != null and is_instance_valid(gb):
                                asig += "1" if coins >= int(menu_box.get_meta("gear_cost", 0)) else "0"
        if asig != _afford_sig:
                _afford_sig = asig
                _paint_cards()
                _paint_menu_afford()

var _chip_sig := ""
var _chip_coins := -1
var _chip_lives := -1
var _chip_wave := -1
var _chip_line := ""
var _chip_btxt := ""
var _afford_sig := ""

# ------------------------------------------------------------ the folk cards
func _rebuild_cards() -> void:
        for c in cards_box.get_children():
                c.queue_free()
        card_panels.clear()
        for fid in PDData.folk_ids():
                if not meta.has_folk(fid):
                        continue
                var f: Dictionary = PDData.FOLK[fid]
                # THE CARD LAW: a flat panel (no bare Button text layer - the
                # two-texts ghost bug class), one tap target, one truth paint
                var card := PanelContainer.new()
                card.custom_minimum_size = Vector2(0, 96)
                card.mouse_filter = Control.MOUSE_FILTER_STOP
                var style := StyleBoxFlat.new()
                style.bg_color = Color(0.13, 0.09, 0.05, 0.94)
                style.set_corner_radius_all(12)
                style.set_border_width_all(2)
                style.border_color = Color(0.35, 0.26, 0.14)
                style.set_content_margin_all(6)
                card.add_theme_stylebox_override("panel", style)
                var h := HBoxContainer.new()
                h.mouse_filter = Control.MOUSE_FILTER_IGNORE
                h.add_theme_constant_override("separation", 8)
                card.add_child(h)
                var face := TextureRect.new()
                face.texture = _t("folk/%s_face.png" % fid)
                face.custom_minimum_size = Vector2(66, 66)
                face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                face.mouse_filter = Control.MOUSE_FILTER_IGNORE
                h.add_child(face)
                var vb2 := VBoxContainer.new()
                vb2.mouse_filter = Control.MOUSE_FILTER_IGNORE
                vb2.alignment = BoxContainer.ALIGNMENT_CENTER
                vb2.add_theme_constant_override("separation", 0)
                h.add_child(vb2)
                vb2.add_child(Arc.label(f["name"], _fs(23), Arc.CARD))
                var cost_row := HBoxContainer.new()
                cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
                cost_row.add_theme_constant_override("separation", 4)
                vb2.add_child(cost_row)
                var cicon := TextureRect.new()
                cicon.texture = _t("ui/popcoin.png")
                cicon.custom_minimum_size = Vector2(22, 22)
                cicon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                cicon.mouse_filter = Control.MOUSE_FILTER_IGNORE
                cost_row.add_child(cicon)
                cost_row.add_child(Arc.label(str(f["place"]), _fs(21), Color(1, 0.85, 0.4)))
                var fid_c: String = fid
                card.gui_input.connect(func(ev: InputEvent):
                        # THE DRAG LAW v2: the card OWNS its touch stream. Godot
                        # routes the press's drags AND release back to THIS
                        # control (gui.touch_focus) - they never reach the raw
                        # stream, so the ghost and the placement live here.
                        if ev is InputEventScreenTouch:
                                var t := ev as InputEventScreenTouch
                                var gp: Vector2 = card.get_global_transform() * t.position
                                if t.pressed:
                                        _card_press = fid_c
                                        _card_drag = false
                                        _card_press_pos = gp
                                elif _card_press == fid_c:
                                        _card_press = ""
                                        if _card_drag:
                                                _card_drag = false
                                                _placing_drag = false
                                                if _in_field(gp):
                                                        _try_place_at(gp)
                                                else:
                                                        _cancel_place()
                                        else:
                                                _card_tapped(fid_c)
                        elif ev is InputEventScreenDrag and _card_press == fid_c:
                                var gd: Vector2 = card.get_global_transform() * ev.position
                                if not _card_drag and gd.distance_to(_card_press_pos) > 26.0:
                                        _begin_card_drag()
                                if _card_drag:
                                        _ghost_follow(gd)
                        elif ev is InputEventMouseMotion and _card_press == fid_c \
                                        and (ev as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT:
                                var gm: Vector2 = card.get_global_transform() * ev.position
                                if not _card_drag and gm.distance_to(_card_press_pos) > 26.0:
                                        _begin_card_drag()
                                if _card_drag:
                                        _ghost_follow(gm))
                cards_box.add_child(card)
                card_panels[fid] = {"panel": card, "style": style}
        _paint_cards()

func _paint_cards() -> void:
        # the highlight law: selected = gold border, poor = dim. ONE paint.
        for fid in card_panels:
                var e: Dictionary = card_panels[fid]
                var style: StyleBoxFlat = e["style"]
                var sel: bool = selected_place == fid
                style.bg_color = Color(0.24, 0.17, 0.08, 0.97) if sel else Color(0.13, 0.09, 0.05, 0.94)
                style.border_color = Color(1.0, 0.85, 0.35) if sel else Color(0.35, 0.26, 0.14)
                (e["panel"] as Control).modulate = Color(1, 1, 1, 1) if (sel or coins >= int(PDData.FOLK[fid]["place"])) else Color(0.52, 0.52, 0.52, 0.9)
                (e["panel"] as Control).queue_redraw()

func _card_tapped(fid: String) -> void:
        if selected_place == fid:
                _cancel_place()          # the second tap cancels
                Jukebox.sfx("ps_click", -12.0)
                return
        var f: Dictionary = PDData.FOLK[fid]
        if coins < int(f["place"]):
                Jukebox.sfx("ps_tick_bad", -8.0)
                return
        _select_folk({})
        selected_place = fid
        _ensure_ghost(fid)
        _paint_cards()
        Jukebox.sfx("ps_click", -10.0)

func _ensure_ghost(fid: String) -> void:
        if ghost == null or not is_instance_valid(ghost):
                ghost = Node2D.new()
                var base := Sprite2D.new()
                base.name = "base"
                ghost.add_child(base)
                ghost_head = Sprite2D.new()
                ghost_head.name = "head"
                ghost.add_child(ghost_head)
                field.add_child(ghost)
        (ghost.get_node("base") as Sprite2D).texture = _t("folk/%s_base.png" % fid)
        ghost_head.texture = _t("folk/%s_head_g1.png" % fid)
        var sc := CELL / 62.0
        ghost.scale = Vector2(sc, sc)
        ghost.visible = false
        ghost.modulate = Color(1, 1, 1, 0.75)

func _cancel_place() -> void:
        selected_place = ""
        if ghost != null and is_instance_valid(ghost):
                ghost.visible = false
        ghost_cell = Vector2i(-1, -9)
        _placing_drag = false
        ghost_draw.queue_redraw()
        _paint_cards()

# ------------------------------------------------------------- selection
func _select_folk(f: Dictionary) -> void:
        selected_folk = f
        _build_menu()
        sel_draw.queue_redraw()

# --------------------------------------------------------- tick: input
var _card_press := ""            # the folk card under the finger (drag&drop law)
var _card_drag := false

func _goga_input(event: InputEvent) -> void:
        if over:
                return
        # the ghost breathes with the finger/mouse even before a drag starts
        if event is InputEventMouseMotion and selected_place != "" and ghost != null and not tk.busy():
                _ghost_follow(get_global_mouse_position())
        # THE DRAG LAW part 2: drags that DO escape to the raw stream (mouse
        # emulation paths) still carry the placement - the card handler owns
        # the touch stream, this is the escape hatch
        if event is InputEventScreenDrag and _card_press != "" and not _card_drag:
                var p := (event as InputEventScreenDrag).position
                if p.distance_to(_card_press_pos) > 26.0:
                        _begin_card_drag()
                        if _card_drag:
                                _ghost_follow(p)
                elif _card_drag:
                        _ghost_follow(p)
        elif event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed \
                        and _card_press != "" and _card_drag:
                # a release that escaped the card's gui (rare) still places
                var p2 := (event as InputEventScreenTouch).position
                var fid := _card_press
                _card_press = ""
                _card_drag = false
                _placing_drag = false
                if _in_field(p2):
                        _try_place_at(p2)
                else:
                        _cancel_place()

var _card_press_pos := Vector2.ZERO

func _begin_card_drag() -> void:
        # the drag&drop law: pressing a card and MOVING picks the folk up
        var fid := _card_press
        if fid == "" or coins < int(PDData.FOLK[fid]["place"]):
                return
        if selected_place != fid:
                _select_folk({})
                selected_place = fid
                _ensure_ghost(fid)
                _paint_cards()
                Jukebox.sfx("ps_click", -10.0)
        _card_drag = true
        _placing_drag = true

func _goga_tk_ready() -> void:
        # TouchKit wiring: tap-tap placement AND raw field drags (the drag
        # that starts ON THE FIELD) - the card drags ride _goga_input above
        tk.tap_max_ms = 520.0        # a slow deliberate tap is still a tap
        tk.tapped.connect(func(p: Vector2): _field_tapped(p))
        tk.dragged.connect(func(_from: Vector2, to: Vector2):
                if selected_place != "":
                        _placing_drag = true
                        _ghost_follow(to))
        tk.press_ended.connect(func(p: Vector2):
                if selected_place != "" and _placing_drag:
                        _placing_drag = false
                        _try_place_at(p))

func _field_tapped(p: Vector2) -> void:
        if not _in_field(p):
                return
        # a placed folk under the finger? select it
        for f in folk:
                if (f["pos"] as Vector2).distance_to(p) < CELL * 0.6:
                        _cancel_place()
                        _select_folk(f)
                        return
        if selected_place != "":
                _try_place_at(p)
        elif not selected_folk.is_empty():
                _select_folk({})      # tapping empty field closes the menu

func _ghost_follow(p: Vector2) -> void:
        if ghost == null or not is_instance_valid(ghost):
                return
        ghost.visible = true
        ghost.position = p
        var c := _cell_of(p)
        if c != ghost_cell:
                ghost_cell = c
                var ok := _buildable(c)
                ghost.modulate = Color(1, 1, 1, 0.85) if ok else Color(1.0, 0.5, 0.45, 0.7)
                Jukebox.sfx("ps_tick_ok" if ok else "ps_tick_bad", -16.0)
        ghost_draw.queue_redraw()

func _try_place_at(p: Vector2) -> void:
        if selected_place == "":
                return
        var c := _cell_of(p)
        var afford := coins >= int(PDData.FOLK[selected_place]["place"])
        if _buildable(c) and afford:
                _place_folk(selected_place, c)
        else:
                Jukebox.sfx("ps_tick_bad", -10.0)
                _cancel_place()

func _place_folk(fid: String, c: Vector2i) -> void:
        var fdef: Dictionary = PDData.FOLK[fid]
        coins -= int(fdef["place"])
        var pos := _cell_pos(c.x, c.y)
        var node := Node2D.new()
        node.position = pos
        folk_layer.add_child(node)
        var sh := Sprite2D.new()
        sh.texture = _t("fx/shadow.png")
        sh.position = Vector2(0, CELL * 0.18)
        sh.scale = Vector2(CELL / 62.0, CELL / 62.0)
        node.add_child(sh)
        var spr := Sprite2D.new()
        spr.texture = _t("folk/%s_base.png" % fid)
        spr.scale = Vector2(CELL / 62.0, CELL / 62.0)
        node.add_child(spr)
        var head := Sprite2D.new()
        head.texture = _t("folk/%s_head_g1.png" % fid)
        _mount_head(head, spr, fid)
        node.add_child(head)
        var puff := _fx_spawn("smoke", pos + Vector2(0, 14), 0.5)
        puff.scale = Vector2(1.4, 1.4)
        var f := {
                "id": rng.randi(), "fid": fid, "gear": 1, "lvl": 1, "cell": c, "pos": pos,
                "cd": 0.0, "mode": 0, "inflicted": 0.0, "node": node, "spr": spr, "head": head,
                "badges": [],
                "invested": int(fdef["place"]),
                "buffs": {"rate_f": 1.0, "rng_f": 1.0, "dmg_f": 0.0, "pierce_f": 0, "blast_f": 1.0, "coin_pop": 0},
                "timers": {}, "target": -1, "aim_at": Vector2.ZERO, "aim_t": 0.0,
        }
        folk.append(f)
        _recompute_auras()
        Jukebox.sfx("ps_place", -6.0)
        _cancel_place()
        _select_folk(f)
        _refresh_chips()
        # the FIRST-GLANCE law for multi-door maps
        if (map["paths"] as Array).size() > 1 and not meta.seen_multipath():
                meta.mark_multipath()
                game_toast("THE DOORS ROLL AT RANDOM!")

# --------------------------------------------------------------- the laws
## THE PIVOT LAW v2 (measured from the art - the owner's round): aiming
## heads rotate around their OWN CENTER seated on the mount - a turret that
## spins in place, never the orbiting crossbow that detached from the body.
## Static heads (the bank, the drum) stay objects seated on the base.
func _mount_head(head: Sprite2D, spr: Sprite2D, fid: String) -> void:
        var sc := CELL / 62.0
        head.scale = Vector2(sc, sc)
        if PDData.head_static(fid):
                head.position = Vector2(0, -spr.texture.get_height() * spr.scale.y * 0.36)
                head.offset = Vector2(0, -head.texture.get_height() * 0.30)
        else:
                head.position = Vector2(0, -spr.texture.get_height() * spr.scale.y * 0.30)
                head.offset = Vector2.ZERO

# --------------------------------------------------------------- the laws
## THE SYNERGY ENGINE: pairs earn their pacts; badges speak.
func _recompute_auras() -> void:
        for f in folk:
                f["buffs"] = {"rate_f": 1.0, "rng_f": 1.0, "dmg_f": 0.0, "pierce_f": 0, "blast_f": 1.0, "coin_pop": 0}
                for b in (f["badges"] as Array):
                        b.queue_free()
                f["badges"] = []
                f["flags"] = {}
        for f in folk:
                var fid: String = f["fid"]
                var gear: int = f["gear"]
                for o in folk:
                        if o == f:
                                continue
                        var in_rng: bool = (o["pos"] as Vector2).distance_to(f["pos"]) <= PDData.stat(o["fid"], o["gear"], o["lvl"], "rng") * CELL * float(o["buffs"]["rng_f"]) + 8.0
                        if not in_rng:
                                continue
                        var oid: String = o["fid"]
                        # MARSHAL AURA (the drum beat)
                        if oid == "marshal" and fid != "marshal":
                                var lvl: int = o["lvl"]
                                f["buffs"]["rate_f"] += PDData.stat("marshal", o["gear"], lvl, "aura")
                                if o["gear"] >= 2:
                                        f["buffs"]["rng_f"] += 0.08
                                if o["gear"] >= 3:
                                        f["buffs"]["pierce_f"] += 1
                                _badge_add(f, "drum")
                        match [fid, oid]:
                                ["darty", "boomo"], ["boomo", "darty"]:
                                        f["buffs"]["rate_f"] += 0.15
                                        _badge_add(f, "swirl")
                                ["pyra", "kolda"]:
                                        if gear >= 2:
                                                f["flags"]["thermal"] = true
                                                _badge_add(f, "flame_snow")
                                ["zappy", "kolda"]:
                                        if gear >= 2:
                                                f["flags"]["supercond"] = true
                                                _badge_add(f, "bolt_snow")
                                ["longeye", "marshal"]:
                                        if gear >= 2:
                                                f["buffs"]["dmg_f"] += 3.0
                                                _badge_add(f, "crosshair")
                                ["boomba", "marshal"]:
                                        if gear >= 2:
                                                f["buffs"]["blast_f"] += 0.15
                                                _badge_add(f, "ring_drum")
                                ["kaching", "marshal"]:
                                        if gear >= 2:
                                                f["buffs"]["coin_pop"] += 2
                                                _badge_add(f, "coin_wing")
                                ["gloop", "pyra"]:
                                        if gear >= 3:
                                                f["flags"]["ignite"] = true
                                                _badge_add(f, "drop_flame")
                # range recompute (the aura could have grown it) - THE RANGE
                # TRUTH LAW: eff_rng is stat x CELL x the aura factor. The old
                # CELL x CELL typo made every shooter omniscient (the endless
                # range + the map brightening + the across-map snipes)
                f["eff_rng"] = PDData.stat(fid, gear, f["lvl"], "rng") * CELL * float(f["buffs"]["rng_f"])
        zones2d.queue_redraw()
        if not selected_folk.is_empty():
                _build_menu()

func _badge_add(f: Dictionary, bid: String) -> void:
        for b in (f["badges"] as Array):
                if b.get_meta("bid") == bid:
                        return
        var s := Sprite2D.new()
        s.texture = _t("ui/badge_%s.png" % bid)
        s.set_meta("bid", bid)
        s.position = Vector2(0, -46)
        s.scale = Vector2(0.8, 0.8)
        (f["node"] as Node2D).add_child(s)
        (f["badges"] as Array).append(s)

# =================================================================== WAVES
func _next_wave_countdown(sec: float) -> void:
        phase = "idle"
        countdown = sec
        _refresh_chips()

func _next_wave_pressed() -> void:
        # the field's call: idle -> send now (AUTO early birds keep the bonus),
        # rolling -> stack the next wave on the running one
        if over or phase == "ready":
                return
        if phase == "idle":
                if auto_waves and countdown > 0.5 and wave_n >= 1:
                        var bonus := 25 + 5 * wave_n    # the early-call bonus
                        coins += bonus
                        Jukebox.sfx("ps_coin", -8.0)
                countdown = 0.0
        _queue_wave()

func _queue_wave() -> void:
        # THE STACK LAW: waves APPEND into one spawn queue (absolute clock),
        # so calling mid-roll launches the next wave alongside the running one
        var first := phase == "idle" or phase == "ready"
        if first:
                phase = "spawn"
                spawn_clock = 0.0
                spawn_q.clear()
                spawn_count = 0
        wave_n += 1
        wave_kinds.append("wave%d" % wave_n)
        var stars := int(map["stars"])
        var groups := PDData.wave_groups(wave_n, stars)
        # THE RANDOM DOORS LAW (v0.3.5-4): every wave rolls its OWN door crew
        # - wave 1 from one random door, then two, then three (the crew grows
        # with the siege, capped at the map's doors) and every 5th wave
        # BURSTS from ALL of them. Random subsets - never the same rhythm.
        var n_paths: int = (map["paths"] as Array).size()
        var doors: Array = _pick_doors(wave_n, n_paths)
        var base := 0.0 if first else spawn_clock + 1.2
        var gi := 0
        for g in groups:
                for i in int(g["count"]):
                        var pi := 0
                        if n_paths > 1:
                                pi = int(doors[(i + gi) % doors.size()])
                        spawn_q.append({
                                "kind": g["kind"],
                                "at": base + float(g["delay"]) + i * float(g["spacing"]),
                                "pi": pi,
                                "w": wave_n,                                  # the wave's OWN difficulty bands
                        })
                gi += 1
        spawn_q.sort_custom(func(a, b): return float(a["at"]) < float(b["at"]))
        # the bank pays each wave the moment it marches (the kaching law)
        var income := 0.0
        for f in folk:
                if f["fid"] == "kaching":
                        income += PDData.stat("kaching", f["gear"], f["lvl"], "income")
                        if f["gear"] >= 2:
                                income += coins * float(PDData.FOLK["kaching"]["gears"][f["gear"] - 1].get("interest", 0.0))
                        if f["gear"] >= 3 and wave_n % 5 == 0:
                                var egg: float = PDData.FOLK["kaching"]["gears"][2]["egg"]
                                income += egg
                                Jukebox.sfx("ps_egg", -8.0)
                                _fx_spawn("spark", f["pos"], 0.6)
        if income > 0.0:
                coins += int(income)
        # THE RIDER LAW: every 10th wave hides a GOGACoin inside a bloon
        rider_index = -1
        if wave_n % PDData.RIDER_EVERY == 0 and spawn_q.size() > 0:
                rider_index = rng.randi_range(maxi(0, spawn_q.size() - maxi(1, spawn_q.size() / 3)), spawn_q.size() - 1)
        Jukebox.sfx("ps_horn", -10.0)
        if wave_n == PDData.VICTORY_WAVE or wave_n == 30:
                Jukebox.sfx("ps_wave_boss", -8.0)
        _refresh_chips()

## THE RANDOM DOORS LAW: the wave's door crew. Grows 1 -> 2 -> 3 with the
## wave (capped at the map's doors), rolls a RANDOM subset every wave, and
## every 5th wave bursts from ALL the doors at once.
func _pick_doors(w: int, n: int) -> Array:
        if n <= 1:
                return [0]
        if w % 5 == 0:
                return range(n)
        var k := 1 + int((w - 1) / 3.0)
        if w > 1 and rng.randf() < 0.3:
                k += 1                     # the jitter (never on the opening wave)
        k = clampi(k, 1, n)
        var pool := range(n)
        for i in range(pool.size() - 1, 0, -1):
                var j := rng.randi_range(0, i)
                var tmp = pool[i]
                pool[i] = pool[j]
                pool[j] = tmp
        return pool.slice(0, k)

func _end_wave() -> void:
        phase = "idle"
        # THE POP PAY LAW: PopCoins came from the pops alone (+ the kaching
        # bank at send time + the early-call bonus). No flat wave pay.
        # records + achievements
        achievement_max("wave_best", wave_n)
        if wave_n >= PDData.VICTORY_WAVE and not victory_done:
                victory_done = true
                Jukebox.sfx("ps_victory", -4.0)
                game_toast("THE SIEGE BREAKS!")
        # endless fatigue is applied in the movement law
        _next_wave_countdown(12.0)
        check_achievements()

# ---------------------------------------------------------------- bloons
var _bloon_seq := 0

# THE WHEEL ROSTER: strip + level colors speak at a glance
const KIND_COLORS := {
        "red": Color(0.95, 0.3, 0.3), "blue": Color(0.35, 0.55, 0.95),
        "green": Color(0.35, 0.8, 0.4), "yellow": Color(0.98, 0.85, 0.3),
        "pink": Color(0.98, 0.5, 0.75), "black": Color(0.25, 0.25, 0.3),
        "white": Color(0.95, 0.95, 1.0), "zebra": Color(0.85, 0.85, 0.9),
        "lead": Color(0.6, 0.63, 0.68), "rainbow": Color(0.9, 0.6, 0.95),
        "ceramic": Color(0.85, 0.55, 0.3),
}

func _bloon_tex(kind: String, lv: int) -> Texture2D:
        # THE WHEEL ART: lv1 wears the honest kind, deeper levels wear the
        # recolored wheel variants (a visible step per level)
        if lv <= 1:
                return _t("bloons/%s.png" % kind)
        return _t("bloons/%s_lv%d.png" % [kind, clampi(lv, 2, 8)])

## roll the wave's difficulty bands into ONE bloon (level, strips, armor).
func _roll_bloon_mods(kind: String, w: int) -> Array:
        var mods: Dictionary = PDData.wave_mods(w)
        var blimp: bool = bool(PDData.BLOONS[kind].get("blimp", false))
        var lv := 1
        var lv_max := int(mods["lv_max"])
        if lv_max > 1:
                lv = clampi(1 + int(floorf(pow(rng.randf(), 1.4) * lv_max)), 1, lv_max)
        var strips: Array = []
        var s_max := int(mods["blimp_strips_max"]) if blimp else int(mods["strips_max"])
        if s_max > 0:
                var n := int(floorf(pow(rng.randf(), 1.5) * (s_max + 1)))
                for i in n:
                        strips.append(_strip_kind(w))
        var armor := ""
        var roll := rng.randf()
        if roll < float(mods["rock"]):
                armor = PDData.ARMOR_ROCK
        elif roll < float(mods["rock"]) + float(mods["metal"]):
                armor = PDData.ARMOR_METAL
        var armor_hp := 0.0
        if armor != "":
                armor_hp = (20.0 + w * 0.6) if blimp else (2.0 + w * 0.12)
        return [lv, strips, armor, armor_hp]

func _strip_kind(w: int) -> String:
        var pool: Array = []
        for k in PDData.BLOONS:
                if not bool(PDData.BLOONS[k].get("blimp", false)) and PDData.unlock_band(k) <= w:
                        pool.append(k)
        if pool.is_empty():
                return "red"
        return pool[rng.randi() % pool.size()]

func _spawn_bloon(kind: String, pi: int, lv := 1, strips: Array = [], armor := "", armor_hp := 0.0) -> void:
        pi = clampi(pi, 0, maxi(0, _paths_px.size() - 1))   # a queued spawn never outlives its map
        var def: Dictionary = PDData.BLOONS[kind]
        var spr := Sprite2D.new()
        spr.texture = _bloon_tex(kind, lv)
        spr.visible = false     # THE OFF-STAGE LAW: born behind the map line
        bloon_layer.add_child(spr)
        # THE SINGLE FILE LAW: lane is dead - every bloon marches ON the path
        # center, one honest row (the owner's 4 + 11)
        var lane := 0.0
        _bloon_seq += 1
        # THE SHOT LAW v1 (v0.3.8-5): the wheel's health is the whole honest
        # stack - lv rings x the body's own thickness (black 003 = 3).
        var crack := PDData.body_hp(kind, lv)
        var b := {
                "id": _bloon_seq, "kind": kind, "lv": lv, "strips": strips, "armor": armor,
                "armor_hp": armor_hp,
                "hp": crack, "max_hp": crack,
                "pi": pi, "dist": -CELL * 0.5, "lane": lane, "seg": 1,
                "slow_f": 0.0, "slow_t": 0.0, "glue_t": 0.0, "glue_dps": 0.0, "burn_dps": 0.0, "burn_t": 0.0,
                "stun_t": 0.0, "rider": false, "depth": 0, "spr": spr, "frozen": false,
                "pay_f": 0.0, "paid": 0,
                "threat": PDData.threat(kind, lv, strips),
        }
        if armor != "":
                var sh := Sprite2D.new()
                sh.texture = _t("bloons/armor_%s.png" % armor)
                sh.name = "armor"
                spr.add_child(sh)
        if strips.size() > 0:
                var sd := StripDraw.new()
                sd.bloons_ref = b
                sd.game = self
                spr.add_child(sd)
                b["strip_draw"] = sd
        if def.get("blimp", false) and not meta.seen_blimp():
                meta.mark_blimp()
                game_toast("A BLIMP!")
        bloons.append(b)
        _paint_bloon(b)

func _paint_bloon(b: Dictionary) -> void:
        var spr: Sprite2D = b["spr"]
        var def: Dictionary = PDData.BLOONS[b["kind"]]
        var base_s: float = CELL * float(def["scl"])
        # THE WHEEL TRUTH: the texture speaks the color level
        spr.texture = _bloon_tex(b["kind"], int(b["lv"]))
        # ceramic cracks by hp (the honest shell)
        if b["kind"] == "ceramic":
                var ratio: float = float(b["hp"]) / maxf(1.0, float(b["max_hp"]))
                if ratio < 0.35:
                        spr.texture = _t("bloons/ceramic_c2.png")
                elif ratio < 0.7:
                        spr.texture = _t("bloons/ceramic_c1.png")
        spr.scale = Vector2(base_s / float(spr.texture.get_height()), base_s / float(spr.texture.get_height()))
        # the armor shell sits ON the body until it cracks
        var sh: Node2D = spr.get_node_or_null("armor")
        if sh != null:
                sh.visible = float(b.get("armor_hp", 0.0)) > 0.0
                (sh as Sprite2D).scale = Vector2(1.16, 1.16)
        # the rider's faint golden shimmer
        spr.modulate = Color(1.06, 1.03, 0.85) if b["rider"] else Color.WHITE
        _hp_bar(b)

func _hp_bar(b: Dictionary) -> void:
        # the tanks wear an honest bar (deep cracks + ceramics + blimps)
        var spr: Sprite2D = b["spr"]
        var bar: Node2D = b.get("bar", null)
        var worth_bar := float(b["max_hp"]) >= 10.0 or bool(PDData.BLOONS[b["kind"]].get("blimp", false))
        if not worth_bar:
                if bar != null and is_instance_valid(bar):
                        bar.queue_free()
                        b.erase("bar")
                return
        if bar == null or not is_instance_valid(bar):
                bar = HpBar.new()
                bar.position = Vector2(0, -spr.texture.get_height() * spr.scale.y * 0.5 - 10)
                spr.add_child(bar)
                b["bar"] = bar
        (bar as HpBar).ratio = clampf(float(b["hp"]) / maxf(1.0, float(b["max_hp"])), 0.0, 1.0)
        bar.w = maxf(34.0, spr.texture.get_width() * spr.scale.x * 0.7)
        bar.queue_redraw()

# ----------------------------------------------------- the spatial grid
# THE CORE LAW (the owner's optimization round): thousands of bloons march
# while the phones stay cool - targeting and collisions query a rebuilt
# bucket grid instead of scanning every bloon every frame.
var _bgrid: Dictionary = {}
var _bgrid_cs := 112.0

func _grid_key(p: Vector2) -> Vector2i:
        return Vector2i(int(floor(p.x / _bgrid_cs)), int(floor(p.y / _bgrid_cs)))

func _grid_near(p: Vector2, r: float) -> Array:
        var out: Array = []
        var k0 := _grid_key(p - Vector2(r, r))
        var k1 := _grid_key(p + Vector2(r, r))
        for cx in range(k0.x, k1.x + 1):
                for cy in range(k0.y, k1.y + 1):
                        var arr: Array = _bgrid.get(Vector2i(cx, cy), [])
                        for b in arr:
                                out.append(b)
        return out

## the cached march: one segment index per bloon, advanced in place (the
## old pos_on rescanned the whole polyline for every bloon every frame).
func _pos_on_cached(b: Dictionary) -> Dictionary:
        var P: Dictionary = _paths_px[b["pi"]]
        var d := clampf(float(b["dist"]), 0.0, float(P["total"]))
        var pts: PackedVector2Array = P["pts"]
        var lens: PackedFloat32Array = P["lens"]
        var i: int = int(b.get("seg", 1))
        if i < 1 or i >= pts.size():
                i = 1
        if d < lens[i - 1]:
                i = 1          # the flux shoved it back - rescan from the door
        while i < pts.size() - 1 and d > lens[i]:
                i += 1
        b["seg"] = i
        var seg := maxf(0.001, lens[i] - lens[i - 1])
        var t := clampf((d - lens[i - 1]) / seg, 0.0, 1.0)
        return {"p": pts[i - 1].lerp(pts[i], t), "dir": (pts[i] - pts[i - 1]).normalized()}

func _move_bloons(delta: float) -> void:
        var dead: Array = []
        for b in bloons:
                var def: Dictionary = PDData.BLOONS[b["kind"]]
                var spd: float = float(def["sp"]) * CELL * PDData.fatigue_for(wave_n)
                if b["stun_t"] > 0.0:
                        b["stun_t"] -= delta
                        spd = 0.0
                if b["slow_t"] > 0.0:
                        b["slow_t"] -= delta
                        spd *= (1.0 - b["slow_f"])
                if b["frozen"]:
                        spd = 0.0
                if b["glue_t"] > 0.0:
                        b["glue_t"] -= delta
                        spd *= 0.45
                        if b["glue_dps"] > 0.0:
                                _hurt_bloon(b, b["glue_dps"] * delta, PDData.FIRE, null, true)
                if b["burn_t"] > 0.0:
                        b["burn_t"] -= delta
                        _hurt_bloon(b, b["burn_dps"] * delta, PDData.FIRE, null, true)
                        _burn_paint(b)
                else:
                        _burn_paint(b)
                b["dist"] += spd * delta
                var at: Dictionary = _pos_on_cached(b)
                var p: Vector2 = at["p"]
                var spr: Sprite2D = b["spr"]
                spr.position = p
                # THE OFF-STAGE LAW: the march starts one grid behind the map
                # line - nothing exists to the eye until it is IN the field
                spr.visible = _in_field(p)
                if b["dist"] >= float(_paths_px[b["pi"]]["total"]):
                        dead.append(b)
        for b in dead:
                _leak(b)
        # the grid rebuilds once per tick - the whole siege queries it
        _bgrid.clear()
        for b in bloons:
                var k := _grid_key((b["spr"] as Sprite2D).position)
                if not _bgrid.has(k):
                        _bgrid[k] = [b]
                else:
                        (_bgrid[k] as Array).append(b)

func _burn_paint(b: Dictionary) -> void:
        var spr: Sprite2D = b["spr"]
        var burning: bool = b["burn_t"] > 0.0
        var glued: bool = b["glue_t"] > 0.0
        if burning and spr.material == null:
                var m := ShaderMaterial.new()
                m.shader = load("res://game/games/pop_siege/fx/ps_burn.gdshader")
                m.set_shader_parameter("seed", float(b["id"] % 17))
                spr.material = m
        elif not burning and spr.material != null:
                spr.material = null
        if burning:
                (spr.material as ShaderMaterial).set_shader_parameter("burn_t", clampf(b["burn_t"], 0.0, 1.0))
        if glued:
                spr.modulate = Color(0.75, 1.0, 0.6)
        elif not b["rider"]:
                spr.modulate = Color.WHITE
        if b["frozen"]:
                spr.self_modulate = Color(0.65, 0.85, 1.2)
        else:
                spr.self_modulate = Color.WHITE

func _leak(b: Dictionary) -> void:
        var dmg := int(b.get("threat", PDData.rbe(b["kind"])))
        lives -= dmg
        Jukebox.sfx("ps_leak", -6.0)
        shake_t = 0.35 if dmg >= 40 else 0.18
        _heart_flash()
        _bloon_free(b)
        _refresh_chips()
        if lives <= 0 and not over:
                lives = 0
                _refresh_chips()
                _game_over()

func _heart_flash() -> void:
        heart_spr.modulate = Color(2.0, 0.6, 0.6)
        var tw := create_tween()
        tw.tween_property(heart_spr, "modulate", Color.WHITE, 0.5)

# ------------------------------------------------------------ damage + pop
## v0.3.8-3 THE POPS LAW (the owner: "the damage here is counting money per
## thing, the damage here should mean layers popped or amount of damage
## given, the money relationship here is each single 1 damage points worth
## 1 money"): the two ledgers SPLIT -
##   the POPCOINS: 1 coin per 1 damage point dealt (the pay law v2 stands);
##   the SCORE: 1 per LAYER popped - a ring crack +1, a body pop +1. The
##   POPS chip finally counts POPS (it wore the damage total before -
##   money and score were the same number climbing in lockstep).
var _score_f := 0.0            # (retired with the split - kept for save compat)

func _hurt_bloon(b: Dictionary, dmg: float, cls: String, src: Variant, silent := false) -> bool:
        # THE ARMOR LAW: the shell eats the hit FIRST - and only its feared
        # class bites at all (metal fears fire, rock fears bombs)
        var body_dmg := dmg
        if float(b.get("armor_hp", 0.0)) > 0.0:
                if not PDData.armor_allows(String(b["armor"]), cls):
                        if not silent:
                                Jukebox.sfx("ps_tick_bad", -18.0, 1.6)
                                _fx_spawn("spark", b["spr"].position, 0.18, Color(0.8, 0.8, 0.8))
                        return false
                var a_real: float = maxf(0.0, dmg)
                var a_before := float(b["armor_hp"])
                b["armor_hp"] = a_before - a_real
                # THE PAY TRUTH: the shell earns what it ATE - the old code
                # paid the full hit even when 1 armor point met a 10-dmg shell
                # (money for damage that never happened)
                _pay_damage(b, minf(a_real, a_before), src)
                if float(b["armor_hp"]) > 0.0:
                        # the shell swallowed the whole shot - the body never felt it
                        if not selected_folk.is_empty() and src == selected_folk:
                                _menu_paint_live()
                        return true
                # v0.3.8-5 THE SHOT LAW v1 (the owner: "whatever is the damage
                # points, they have no meaning at all"): the shell just broke
                # and the LEFTOVER PUNCHES THROUGH - a 10-dmg fire shell on a
                # 3-armor red spends 3 on the shell and lands the remaining 7
                # straight on the body. Overkill is never eaten by the shell.
                b["armor_hp"] = 0.0
                _paint_bloon(b)
                if not silent:
                        _fx_spawn("smoke", b["spr"].position, 0.4)
                body_dmg = a_real - a_before
                if body_dmg <= 0.0:
                        if not selected_folk.is_empty() and src == selected_folk:
                                _menu_paint_live()
                        return true
        # the honest matrix (immunities block, the fat blimps halve sharp)
        var real := PDData.dmg_vs(b["kind"], cls, body_dmg)
        if real <= 0.0:
                if not silent:
                        Jukebox.sfx("ps_tick_bad", -18.0, 1.6)
                        _fx_spawn("spark", b["spr"].position, 0.18, Color(0.8, 0.8, 0.8))
                return false
        # THERMAL SHOCK: Pyra's fire bites harder into slowed bloons
        if src != null and (src as Dictionary).get("flags", {}).get("thermal", false) and (b["slow_t"] > 0.0 or b["frozen"]):
                real += 2.0
        # KOLDA G3: the deep freeze - frozen bloons take +1 from everything
        if b["frozen"]:
                real += 1.0
        var landed: bool = _flow_damage(b, real, src, silent)
        if not selected_folk.is_empty() and src == selected_folk:
                _menu_paint_live()
        return landed

## v0.3.8-6 THE FLOW LAW - the owner's own math, verbatim: "if we have a
## pussy that can take 3 at once and you give it 5, how much it will take?
## 3. currently the game takes one even if it can take 3 ... it will forever
## pop one layer at a time, forever". THE BUG: a shot's leftover died at the
## layer border - the pop spawned the children FRESH and the overflow was
## burned, so a 2-dmg dart and a 10000-dmg nuke both peeled exactly ONE
## layer per shot. THE FIX: damage is WATER now. It pours into the bloon,
## eats what the bloon HAS (min(damage, layers left)), and the LEFTOVER
## keeps pouring through the pop - the children and the strips the pop
## reveals ARE the next layer, and the water flows into them in the SAME
## shot, breadth order, until the shot runs dry or the whole chain is gone.
## An 8-dmg shot on a blue erases the blue AND its two reds in ONE shot.
## THE INFLICTED TRUTH (the owner: "it counts damage_points x
## bloons_collided_with_shot which is wrong - it should count damage points
## dealt, not total x bloons_collided blindly"): a layer only ever
## contributes what it TOOK - the counter carries the absorbed water, never
## the raw stat x collisions. Overkill past the last layer never happened.
func _flow_damage(entry: Dictionary, dmg: float, src: Variant, silent := false) -> bool:
        var remaining := maxf(0.0, dmg)
        var layers := 0                     # every layer THIS shot emptied
        var landed := false
        var pop_at: Vector2 = (entry["spr"] as Sprite2D).position
        var queue: Array = [entry]          # breadth order: the onion peels
        var qi := 0
        while qi < queue.size() and remaining > 0.0:
                var cur: Dictionary = queue[qi]
                qi += 1
                if float(cur["hp"]) <= 0.0 or not is_instance_valid(cur["spr"]):
                        continue
                # a layer can only take what it HAS (the owner's 3-of-5 law)
                var absorbed := minf(remaining, float(cur["hp"]))
                if absorbed <= 0.0:
                        break               # an immune shell blocks the water here
                remaining -= absorbed
                landed = true
                cur["hp"] = float(cur["hp"]) - absorbed
                if src != null:
                        src["inflicted"] = float(src.get("inflicted", 0.0)) + absorbed
                _paint_bloon(cur)
                # THE RING LADDER (v0.3.8-5 round 2 stands): rings_left lives
                # in DIVISION - ceil(hp / thickness). Rings crack the moment
                # the water crosses a border, every ring costs the body's own
                # thickness (red 1, ceramic 10, moab 200).
                var thick := maxf(1.0, PDData.crack_hp(String(cur["kind"]), int(cur["lv"])))
                if float(cur["hp"]) <= 0.0 or int(ceilf(float(cur["hp"]) / thick)) < int(cur["lv"]):
                        var new_lv := int(ceilf(float(cur["hp"]) / thick))
                        if new_lv < 0:
                                new_lv = 0
                        var crossed := int(cur["lv"]) - maxi(new_lv, 1)
                        if crossed > 0:
                                layers += crossed
                                add_score(crossed)
                                cur["lv"] = maxi(new_lv, 1)
                                cur["max_hp"] = PDData.body_hp(cur["kind"], int(cur["lv"]))
                        if float(cur["hp"]) <= 0.0:
                                layers += 1
                                # the pop reveals the next layer - the water
                                # flows straight into it, same shot
                                var next: Array = _pop_bloon(cur, src)
                                for nb in next:
                                        queue.append(nb)
                        elif crossed > 0:
                                _paint_bloon(cur)
        # THE POP PAY LAW v3: 1 layer = 1 popcoin - and the WHOLE shot's take
        # banks as ONE +nn at the entry (a chain wipe pays its full nn at
        # once, the owner's "one shot can eliminate the whole bloon").
        # Overkill past the last layer pays nothing (it never happened).
        if layers > 0:
                coins += layers
                _coin_text(pop_at, layers)
        return landed

## THE POP PAY LAW v2 (retired v0.3.8-4): paid per DAMAGE point - LongEye's
## 8-dmg bullet on a 1-hp red paid 8 coins for ONE layer. The armor shell
## still pays what it ATE (a shell is not a wheel layer - v0.3.8-3's law
## stands for it alone).
func _pay_damage(b: Dictionary, real: float, src: Variant) -> void:
        if real <= 0.0:
                return
        b["pay_f"] = float(b.get("pay_f", 0.0)) + real
        var n := int(b["pay_f"])
        if n > 0:
                b["pay_f"] = float(b["pay_f"]) - float(n)
                coins += n
                b["paid"] = int(b.get("paid", 0)) + n
        if src != null:
                src["inflicted"] = float(src.get("inflicted", 0.0)) + real

func _pop_bloon(b: Dictionary, src: Variant) -> Array:
        ## v0.3.8-6 THE FLOW LAW: the pop hands back the layer it revealed -
        ## the children (kids first, then the strips' inner bloons, in spawn
        ## order) so the shot's leftover water pours straight into them.
        var revealed: Array = []
        var def: Dictionary = PDData.BLOONS[b["kind"]]
        # the pop: the ladder pitch climbs with depth (the star sound)
        var pitch_idx: int = clampi(int(b["depth"]), 0, 4)
        Jukebox.sfx("ps_pop%d" % pitch_idx, -6.0, randf_range(0.94, 1.06))
        var col: Color = KIND_COLORS.get(b["kind"], Color(0.5, 0.6, 0.95))
        if def.get("blimp", false):
                col = Color(0.5, 0.6, 0.95)
                Jukebox.sfx("ps_moab_pop", -4.0)
                shake_t = 0.5
                _boom_fx(b["spr"].position, 1.7)
                _moabs_run += 1
                achievement_max("moab_kills", _moabs_run)
        # the splash frames (modulate speaks the bloon's color)
        _splash_fx(b["spr"].position, col)
        # the shockwave shader
        _shock_fx(b["spr"].position, col, 0.9 if def.get("blimp", false) else 0.5)
        # v0.3.8-3 THE POPS LAW: the body's final break is ONE pop (the ring
        # cracks each scored their own on the way down)
        add_score(1)
        # v0.3.8-4: the body pop's own coin rides the per-pop pay in
        # _hurt_bloon now - what lives here is the kaching GOLD-WING bonus
        # (+2 PopCoins per pop, the synergy's own law)
        var pay := int((src as Dictionary)["buffs"].get("coin_pop", 0)) \
                if src != null else 0
        if pay > 0:
                coins += pay
                _coin_text(b["spr"].position, pay)
        _pops_run += 1
        achievement_max("pops_run", _pops_run)
        # THE RIDER: the hidden GOGACoin flies to the wallet
        if b["rider"]:
                meta.d["riders"] = int(meta.d["riders"]) + 1
                add_run_coins(1)
                Jukebox.sfx("ps_gogacoin", -4.0)
                _fx_spawn("spark", b["spr"].position, 0.8, Color(1.0, 0.85, 0.3))
                game_toast("GOGACOIN!")
        # the children carry on (same path, spread) - and join the flow queue
        var off := 2.0
        for k in def["kids"]:
                var kid: Dictionary = _spawn_child(k, b, off)
                if not kid.is_empty():
                        revealed.append(kid)
                off += 6.0
        # THE STRIPS LAW: each band hid a bloon of that color - the counts
        # never showed, and the inner bloons can wear strips of their own
        var strips: Array = b.get("strips", [])
        var sof: float = 1.2
        for s in strips:
                var n := 1 + (1 if rng.randf() < 0.25 else 0)
                for i in n:
                        var inner_strips: Array = []
                        if wave_n >= PDData.STRIP_WAVE + 8 and int(b["depth"]) < 2 and rng.randf() < 0.3:
                                inner_strips.append(_strip_kind(wave_n))
                                if rng.randf() < 0.4:
                                        inner_strips.append(_strip_kind(wave_n))
                        var inner: Dictionary = _spawn_child(String(s), b, sof, 1, inner_strips)
                        if not inner.is_empty():
                                revealed.append(inner)
                        sof += 4.0
        _bloon_free(b)
        _refresh_chips()
        return revealed

func _splash_fx(at: Vector2, tint: Color) -> void:
        if _pop_frames.is_empty() or _splashes >= 22:
                return
        _splashes += 1
        var spr := Sprite2D.new()
        spr.texture = _pop_frames[0]
        spr.position = at
        spr.modulate = tint
        fx_layer.add_child(spr)
        var last := _pop_frames.size() - 1
        var tw := create_tween()
        tw.tween_method(func(i: int): _splash_frame(spr, i), 0, last, 0.32)
        tw.tween_callback(func():
                _splashes -= 1
                if is_instance_valid(spr):
                        spr.queue_free())

var _splashes := 0

func _splash_frame(spr: Sprite2D, i: int) -> void:
        if is_instance_valid(spr) and i >= 0 and i < _pop_frames.size():
                spr.texture = _pop_frames[i]

func _coin_text(at: Vector2, n: int) -> void:
        # the floaters cap themselves (a thousand pops must not spawn a
        # thousand labels - the pool law)
        if _coin_texts >= 14:
                return
        _coin_texts += 1
        var l := Arc.label("+%d" % n, int(CELL * 0.34), Color(1.0, 0.9, 0.45))
        l.position = at + Vector2(-14, -CELL * 0.5)
        fx_layer.add_child(l)
        var tw := create_tween().set_parallel(true)
        tw.tween_property(l, "position:y", l.position.y - CELL * 0.7, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tw.tween_property(l, "modulate:a", 0.0, 0.55).set_delay(0.12)
        tw.chain().tween_callback(func():
                _coin_texts -= 1
                if is_instance_valid(l):
                        l.queue_free())

var _coin_texts := 0

func _spawn_child(kind: String, parent: Dictionary, off: float, lv := 1, strips: Array = []) -> Dictionary:
        var def: Dictionary = PDData.BLOONS[kind]
        var spr := Sprite2D.new()
        spr.texture = _bloon_tex(kind, lv)
        bloon_layer.add_child(spr)
        _bloon_seq += 1
        # THE SHOT LAW v1 (v0.3.8-5): the wheel's health is the whole honest
        # stack - lv rings x the body's own thickness (black 003 = 3).
        var crack := PDData.body_hp(kind, lv)
        var b := {
                "id": _bloon_seq, "kind": kind, "lv": lv, "strips": strips, "armor": "",
                "armor_hp": 0.0,
                "hp": crack, "max_hp": crack,
                "pi": parent["pi"], "dist": maxf(0.0, float(parent["dist"]) - off),
                "lane": 0.0,      # THE SINGLE FILE LAW: children spread in TIME, not sideways
                "seg": 1,
                "slow_f": parent["slow_f"], "slow_t": parent["slow_t"], "glue_t": parent["glue_t"],
                "glue_dps": parent["glue_dps"], "burn_dps": parent["burn_dps"], "burn_t": parent["burn_t"],
                "stun_t": parent["stun_t"], "rider": false, "depth": int(parent["depth"]) + 1,
                "spr": spr, "frozen": parent["frozen"],
                "pay_f": 0.0, "paid": 0,
                "threat": PDData.threat(kind, lv, strips),
        }
        if strips.size() > 0:
                var sd := StripDraw.new()
                sd.bloons_ref = b
                sd.game = self
                spr.add_child(sd)
                b["strip_draw"] = sd
        bloons.append(b)
        _paint_bloon(b)
        return b

var _pops_run := 0
var _moabs_run := 0

func _bloon_free(b: Dictionary) -> void:
        bloons.erase(b)
        (b["spr"] as Node2D).queue_free()

# ================================================================ THE TICK
func _goga_tick(delta: float) -> void:
        var d := delta * float(speed_mult)
        if shake_t > 0.0:
                shake_t -= delta
                field.position = Vector2(rng.randf_range(-6, 6), rng.randf_range(-6, 6)) * (shake_t / 0.35)
                if shake_t <= 0.0:
                        field.position = Vector2.ZERO
        if phase == "idle" and not over and auto_waves and wave_n >= 1:
                # THE A/M LAW v2: only AUTO marches the clock, and NEVER for
                # the first wave - the owner opens every siege with the SEND
                # button (the timer is AUTO's between-waves clock only)
                countdown -= d
                if countdown <= 0.0:
                        countdown = 0.0
                        _queue_wave()
                        _refresh_chips()
                else:
                        _refresh_chips()
        elif phase == "spawn" or phase == "clear":
                spawn_clock += d
                while spawn_q.size() > 0 and float(spawn_q[0]["at"]) <= spawn_clock:
                        var s: Dictionary = spawn_q.pop_front()
                        var b_idx := spawn_count
                        var mods: Array = _roll_bloon_mods(String(s["kind"]), int(s.get("w", wave_n)))
                        _spawn_bloon(String(s["kind"]), int(s["pi"]), int(mods[0]), mods[1], String(mods[2]), float(mods[3]))
                        if b_idx == rider_index:
                                (bloons[-1] as Dictionary)["rider"] = true
                                _paint_bloon(bloons[-1])
                        spawn_count += 1
                if spawn_q.is_empty():
                        phase = "clear"
                if bloons.is_empty() and phase == "clear":
                        _end_wave()
                _refresh_chips()
        _tick_folk(d)
        _tick_bullets(d)
        _move_bloons(d)
        _tick_traps(d)
        # v0.3.8-4 THE EVERY-TICK TRUTH: the chips + the menu afford paint
        # run EVERY tick now - the paint is value-gated (a chip only moves
        # when its own number moves), so the idle-MANUAL siege (income
        # folk dripping, the SEND gate up) repaints honestly. The old
        # phase-only calls left the purse and the grayed buttons STALE
        # before the first wave (the rig caught the purse frozen at 650
        # through a paid pop).
        _refresh_chips()

# ------------------------------------------------------------ folk firing
func _pick_target(f: Dictionary, rng_px: float) -> Dictionary:
        # modes: 0 first (max dist), 1 last (min dist), 2 strong (max hp), 3 close (min dist to folk)
        # THE GRID LAW: the candidates come from the bucket grid, never a
        # whole-roster scan (thousands of bloons, cool phones)
        var best := {}
        var best_v := -1.0
        var near: Array = _grid_near(f["pos"], rng_px + _bgrid_cs)
        for b in near:
                var d2: float = (b["spr"] as Sprite2D).position.distance_to(f["pos"])
                if d2 > rng_px:
                        continue
                var v: float
                match int(f["mode"]):
                        0: v = float(b["dist"])
                        1: v = -float(b["dist"])
                        2: v = float(b["hp"])
                        _: v = -d2
                if v > best_v:
                        best_v = v
                        best = b
        return best

func _folk_pos(f: Dictionary) -> Vector2:
        return f["pos"]

func _tick_folk(delta: float) -> void:
        for f in folk:
                var fid: String = f["fid"]
                var g: Dictionary = PDData.FOLK[fid]["gears"][int(f["gear"]) - 1]
                var buffs: Dictionary = f["buffs"]
                var rate: float = PDData.stat(fid, f["gear"], f["lvl"], "rate")
                var rng_px: float = float(f.get("eff_rng", PDData.stat(fid, f["gear"], f["lvl"], "rng") * CELL))
                # the aim decays: the head holds its last shot's bearing for a
                # beat, then rests (no more firing at nothing - the wave-start
                # misfire glitch is dead WITH the endless range). THE PIVOT
                # LAW v2: static heads (bank/drum) never spin.
                f["aim_t"] = float(f.get("aim_t", 0.0)) - delta
                if float(f["aim_t"]) > 0.0 and f.get("head") != null and is_instance_valid(f["head"]) and not PDData.head_static(fid):
                        var head: Sprite2D = f["head"]
                        var want := ((f["aim_at"] as Vector2) - (f["pos"] as Vector2)).angle() + PDData.head_offset(fid)
                        head.rotation = lerp_angle(head.rotation, want, minf(1.0, delta * 12.0))
                # gear specials on their own clocks
                _tick_specials(f, g, delta, rng_px)
                if rate <= 0.0:
                        continue     # kaching (the bank) never fires
                f["cd"] = float(f["cd"]) - delta
                if float(f["cd"]) > 0.0:
                        continue
                # THE AIM LAW: the target search happens ONLY when the gadget
                # can actually shoot - no per-frame roster scans
                var tgt := _pick_target(f, rng_px)
                if tgt.is_empty():
                        continue
                f["cd"] = rate / float(buffs["rate_f"])
                f["aim_at"] = (tgt["spr"] as Sprite2D).position
                f["aim_t"] = 0.4
                _fire_folk(f, tgt, g)

func _fire_folk(f: Dictionary, target: Dictionary, g: Dictionary) -> void:
        var fid: String = f["fid"]
        var rng_px: float = float(f.get("eff_rng", PDData.stat(fid, int(f["gear"]), int(f["lvl"]), "rng") * CELL))
        var dmg: float = PDData.stat(fid, f["gear"], f["lvl"], "dmg") + float(f["buffs"]["dmg_f"])
        var cls: String = PDData.FOLK[fid]["cls"]
        var to: Vector2 = (target["spr"] as Sprite2D).position
        # THE MUZZLE LAW: the shot LEAVES from the head's business end along
        # the aim - the darts never crawl out of the base belly again
        var from: Vector2 = f["pos"] + (to - f["pos"]).normalized() * PDData.muzzle(fid) * CELL
        if not PDData.head_static(fid) and fid != "kolda":
                _fx_spawn("muzzle", from, 0.09, Color(1.0, 0.96, 0.8))
        match fid:
                "darty":
                        var shots: int = int(g.get("shots", 1))
                        var tex := "fx/p_dart_g%d.png" % clampi(int(f["gear"]), 1, 3)
                        if f["gear"] >= 3:
                                tex = "fx/p_gold_dart.png"
                        for i in shots:
                                _bullet_spawn(from, to, tex, dmg, cls, int(g.get("pierce", 1)) + int(f["buffs"]["pierce_f"]), 7.5 * CELL, f)
                        Jukebox.sfx("ps_shoot_dart", -12.0, randf_range(0.95, 1.05))
                "boomo":
                        _rang_spawn(f, to, dmg, int(g.get("pierce", 3)) + int(f["buffs"]["pierce_f"]))
                        Jukebox.sfx("ps_shoot_rang", -12.0)
                "boomba":
                        var bomb_tex := "fx/p_bomb_g3.png" if int(f["gear"]) >= 3 else "fx/p_bomb.png"
                        _shell_spawn(f, to, dmg, float(g["blast"]) * float(f["buffs"]["blast_f"]), g, bomb_tex)
                        Jukebox.sfx("ps_shoot_bomb", -10.0)
                "pyra":
                        _bullet_spawn(from, to, "fx/p_flame.png", dmg, cls, 2 + int(f["buffs"]["pierce_f"]), 5.4 * CELL, f,
                                {"aoe": float(g["blast"]), "burn_dps": PDData.stat("pyra", f["gear"], f["lvl"], "burn"),
                                "burn_t": float(g["burn_t"]), "src_f": f})
                        Jukebox.sfx("ps_shoot_flame", -14.0, randf_range(0.9, 1.1))
                "kolda":
                        # the pulse: everything in range feels the chill
                        for b in _grid_near(from, rng_px):
                                if (b["spr"] as Sprite2D).position.distance_to(from) <= rng_px:
                                        var slowed := _hurt_bloon(b, dmg, cls, f, true)
                                        if slowed or PDData.dmg_vs(b["kind"], cls, dmg) > 0.0:
                                                b["slow_f"] = maxf(b["slow_f"], float(g["slow"]))
                                                b["slow_t"] = maxf(b["slow_t"], float(g["slow_t"]))
                                                if f["gear"] >= 3 and bool(g.get("deep", false)) and not bool(PDData.BLOONS[b["kind"]].get("blimp", false)):
                                                        b["frozen"] = true
                                                        _frozen_timer(b, 0.8)
                                        _fx_spawn("snow", b["spr"].position, 0.3)
                        Jukebox.sfx("ps_freeze", -12.0, randf_range(0.95, 1.1))
                "gloop":
                        _bullet_spawn(from, to, "fx/p_goo.png", 0.0, "glue", 1, 5.9 * CELL, f,
                                {"glue": true, "slow": float(g["slow"]), "slow_t": float(g["slow_t"]),
                                "dps": float(g.get("dps", 0.0)), "src_f": f})
                        Jukebox.sfx("ps_shoot_goo", -12.0)
                "longeye":
                        _hitscan(from, to, dmg + (float(g.get("moab_bonus", 0.0)) if bool(PDData.BLOONS[target["kind"]].get("blimp", false)) else 0.0),
                                cls, f, bool(g.get("fmj", false)), float(g.get("splash", 0.0)))
                        Jukebox.sfx("ps_shoot_sniper", -10.0, randf_range(0.92, 1.08))
                "zappy":
                        _chain_zap(f, target, dmg, int(g.get("chain", 3)) + (2 if f.get("flags", {}).get("supercond", false) else 0), float(g.get("stun", 0.0)))
                "marshal":
                        # the drum pulse: a soft smack to everything in the aura
                        var hit_n := 0
                        for b in _grid_near(from, rng_px):
                                if (b["spr"] as Sprite2D).position.distance_to(from) <= rng_px:
                                        if _hurt_bloon(b, dmg, PDData.EXPLOSION, f, true):
                                                hit_n += 1
                        if hit_n > 0:
                                _fx_spawn("ring", from, 0.4)
                                Jukebox.sfx("ps_trap", -16.0)

func _tick_specials(f: Dictionary, g: Dictionary, delta: float, rng_px: float) -> void:
        var fid: String = f["fid"]
        var t: Dictionary = f["timers"]
        match fid:
                "pyra":
                        # G3: THE ETERNAL FLAME ring
                        if f["gear"] >= 3 and not f["node"].has_node("ring"):
                                var ring := Sprite2D.new()
                                ring.name = "ring"
                                ring.texture = _t("fx/ring.png")
                                var m := ShaderMaterial.new()
                                m.shader = load("res://game/games/pop_siege/fx/ps_aura.gdshader")
                                m.set_shader_parameter("tint", Color(1.0, 0.5, 0.12))
                                ring.material = m
                                var rr: float = rng_px * 0.55 * 2.0 / 96.0
                                ring.scale = Vector2(rr, rr)
                                (f["node"] as Node2D).add_child(ring)
                        if f["gear"] >= 3 and f["node"].has_node("ring"):
                                var dps: float = float(g.get("ring_dps", 2.0))
                                for b in _grid_near(f["pos"], rng_px * 0.55):
                                        if (b["spr"] as Sprite2D).position.distance_to(f["pos"]) <= rng_px * 0.55:
                                                _hurt_bloon(b, dps * delta, PDData.FIRE, f, true)
                        # G2+: the fire traps on the road
                        if f["gear"] >= 2 and bool(g.get("trap_every", 0.0) > 0.0):
                                t["trap"] = float(t.get("trap", 4.0)) - delta
                                if float(t["trap"]) <= 0.0:
                                        t["trap"] = float(g["trap_every"])
                                        _plant_trap(f, rng_px)
                "boomo":
                        # G2+: the orbit guard (a spinning rang that grinds)
                        if f["gear"] >= 2 and not f["node"].has_node("orbit"):
                                var orb := Sprite2D.new()
                                orb.name = "orbit"
                                orb.texture = _t("fx/p_boomerang.png")
                                (f["node"] as Node2D).add_child(orb)
                        if f["node"].has_node("orbit"):
                                var orb: Sprite2D = f["node"].get_node("orbit")
                                orb.position = Vector2(cos(Time.get_ticks_msec() / 1000.0 * 5.0), sin(Time.get_ticks_msec() / 1000.0 * 5.0)) * 0.6 * CELL
                                orb.rotation += delta * 9.0
                                t["orbit_hit"] = float(t.get("orbit_hit", 0.0)) - delta
                                if float(t["orbit_hit"]) <= 0.0:
                                        var hit := false
                                        for b in _grid_near(orb.global_position, 0.46 * CELL):
                                                if (b["spr"] as Sprite2D).position.distance_to(f["pos"] + orb.position) < 0.46 * CELL:
                                                        var dmg: float = float(g.get("orbit_dps", 1.0)) * (float(g.get("moab_x", 1.0)) if bool(PDData.BLOONS[b["kind"]].get("blimp", false)) else 1.0)
                                                        if _hurt_bloon(b, dmg, PDData.SHARP, f, true):
                                                                hit = true
                                        if hit:
                                                t["orbit_hit"] = 0.45
                "gloop":
                        # G3: THE FLUX - teleport the furthest bloon back (the ES homage)
                        if f["gear"] >= 3 and float(g.get("flux_every", 0.0)) > 0.0:
                                t["flux"] = float(t.get("flux", 3.0)) - delta
                                if float(t["flux"]) <= 0.0:
                                        var furthest := {}
                                        for b in bloons:
                                                if (b["spr"] as Sprite2D).position.distance_to(f["pos"]) <= rng_px and not bool(PDData.BLOONS[b["kind"]].get("blimp", false)):
                                                        if furthest.is_empty() or float(b["dist"]) > float(furthest["dist"]):
                                                                furthest = b
                                        if not furthest.is_empty():
                                                t["flux"] = float(g["flux_every"])
                                                furthest["dist"] = maxf(0.0, float(furthest["dist"]) - float(g["flux_back"]) * CELL)
                                                furthest["seg"] = 1
                                                furthest["glue_t"] = maxf(furthest["glue_t"], 1.5)
                                                Jukebox.sfx("ps_teleport", -10.0)
                                                _fx_spawn("spark", furthest["spr"].position, 0.4, Color(0.6, 1.0, 0.5))
                "kolda":
                        # G2+: permafrost patches under herself
                        if f["gear"] >= 2 and bool(g.get("patch", false)):
                                t["patch"] = float(t.get("patch", 0.0)) - delta
                                if float(t["patch"]) <= 0.0:
                                        t["patch"] = 3.0
                                        patches.append({"pos": f["pos"], "t": 3.0, "r": rng_px * 0.5})
                        # G3: the blimp deep-freeze chance pulse
                        if f["gear"] >= 3:
                                t["bf"] = float(t.get("bf", 0.0)) - delta
                                if float(t["bf"]) <= 0.0:
                                        t["bf"] = 6.0
                                        for b in _grid_near(f["pos"], rng_px):
                                                if bool(PDData.BLOONS[b["kind"]].get("blimp", false)) and (b["spr"] as Sprite2D).position.distance_to(f["pos"]) <= rng_px:
                                                        b["stun_t"] = maxf(b["stun_t"], float(g.get("blimp_freeze", 1.2)))
                                                        _fx_spawn("snow", b["spr"].position, 0.5)
                                                        break
                "zappy":
                        # G3: THE STORM - random strikes everywhere in range
                        if f["gear"] >= 3 and float(g.get("storm_every", 0.0)) > 0.0:
                                t["storm"] = float(t.get("storm", 0.0)) - delta
                                if float(t["storm"]) <= 0.0:
                                        t["storm"] = float(g["storm_every"])
                                        var in_rng := []
                                        for b in _grid_near(f["pos"], rng_px):
                                                if (b["spr"] as Sprite2D).position.distance_to(f["pos"]) <= rng_px:
                                                        in_rng.append(b)
                                        if in_rng.size() > 0:
                                                var victim: Dictionary = in_rng[rng.randi() % in_rng.size()]
                                                _zap_bolt(f["pos"], victim["spr"].position)
                                                _hurt_bloon(victim, PDData.stat("zappy", f["gear"], f["lvl"], "dmg"), PDData.ENERGY, f)
                                                Jukebox.sfx("ps_shoot_zap", -14.0, randf_range(0.9, 1.15))

func _frozen_timer(b: Dictionary, sec: float) -> void:
        var tw := create_tween()
        tw.tween_interval(sec)
        tw.tween_callback(func():
                if bloons.has(b):
                        b["frozen"] = false
                        _burn_paint(b))

func _plant_trap(f: Dictionary, rng_px: float) -> void:
        # a trap lands on the road inside her range
        var best := {}
        for tries in 14:
                var pi := rng.randi_range(0, (map["paths"] as Array).size() - 1)
                var at := pos_on(pi, rng.randf_range(20.0, float(_paths_px[pi]["total"]) - 20.0))
                if (at["p"] as Vector2).distance_to(f["pos"]) <= rng_px:
                        best = {"p": at["p"]}
                        break
        if best.is_empty():
                return
        var spr := Sprite2D.new()
        spr.texture = _t("fx/trap_00.png")
        spr.position = best["p"]
        fx_layer.add_child(spr)
        traps.append({"spr": spr, "t": 6.0, "dps": float(PDData.FOLK["pyra"]["gears"][f["gear"] - 1].get("trap_dps", 3.0)), "src": f})
        Jukebox.sfx("ps_trap", -12.0)

func _tick_traps(delta: float) -> void:
        for tr in traps.duplicate():
                tr["t"] -= delta
                for b in _grid_near(tr["spr"].position, 0.45 * CELL):
                        if (b["spr"] as Sprite2D).position.distance_to(tr["spr"].position) < 0.45 * CELL:
                                _hurt_bloon(b, float(tr["dps"]) * delta, PDData.FIRE, tr["src"], true)
                                b["burn_t"] = maxf(b["burn_t"], 1.2)
                                b["burn_dps"] = maxf(b["burn_dps"], float(tr["dps"]) * 0.6)
                if float(tr["t"]) <= 0.0:
                        traps.erase(tr)
                        tr["spr"].queue_free()
        for p in patches.duplicate():
                p["t"] -= delta
                if float(p["t"]) <= 0.0:
                        patches.erase(p)
        zones2d.queue_redraw()

# -------------------------------------------------------------- projectiles
func _bullet_spawn(from: Vector2, to: Vector2, tex: String, dmg: float, cls: String,
                pierce: int, spd: float, src: Variant, extra := {}) -> void:
        var spr := Sprite2D.new()
        spr.texture = _t(tex)
        spr.position = from
        if tex.contains("dart"):
                _trail_child(spr, Color(1, 1, 0.9, 0.5))
        bullet_layer.add_child(spr)
        var dir := (to - from).normalized()
        # the art truth: the dart arrows face UP in the atlas, the shells right
        spr.rotation = dir.angle() + (PI / 2.0 if tex.contains("dart") else 0.0)
        bullets.append({
                "kind": "bullet", "spr": spr, "pos": from, "vel": dir * spd, "dmg": dmg,
                "cls": cls, "pierce": pierce, "hit_ids": {}, "src": src, "life": 1.6,
                # v0.3.5-6 THE SHOT DIES AT ITS TARGET (the owner: "pyra's shot
                # have that old bomber ball bug which is goes then flies forever
                # in a weird floating way" - the same family the bomber shell
                # died of in v0.3.5-4): an aimed bullet's flight ends at the
                # aimed point + half a cell of grace, never a cross-field float
                "travel": 0.0, "max_d": from.distance_to(to) + 0.5 * CELL,
                "aoe": float(extra.get("aoe", 0.0)), "burn_dps": float(extra.get("burn_dps", 0.0)),
                "burn_t": float(extra.get("burn_t", 0.0)), "glue": bool(extra.get("glue", false)),
                "slow": float(extra.get("slow", 0.0)), "slow_t": float(extra.get("slow_t", 0.0)),
                "dps": float(extra.get("dps", 0.0)),
        })

func _rang_spawn(f: Dictionary, to: Vector2, dmg: float, pierce: int) -> void:
        var from: Vector2 = f["pos"] + (to - f["pos"]).normalized() * PDData.muzzle(f["fid"]) * CELL
        var spr := Sprite2D.new()
        spr.texture = _t("fx/p_boomerang.png")
        spr.position = from
        bullet_layer.add_child(spr)
        bullets.append({
                "kind": "rang", "spr": spr, "pos": from, "target": to, "t": 0.0,
                "dur": 1.1, "dmg": dmg, "cls": PDData.SHARP, "pierce": pierce, "hit_ids": {},
                "src": f, "out": true,
        })

func _shell_spawn(f: Dictionary, to: Vector2, dmg: float, blast: float, g: Dictionary, tex := "fx/p_bomb.png") -> void:
        var from: Vector2 = f["pos"] + (to - f["pos"]).normalized() * PDData.muzzle(f["fid"]) * CELL
        var spr := Sprite2D.new()
        spr.texture = _t(tex)
        spr.position = from
        _trail_child(spr, Color(0.8, 0.78, 0.72, 0.6))
        bullet_layer.add_child(spr)
        bullets.append({
                "kind": "shell", "spr": spr, "pos": from, "from": from, "target": to,
                "t": 0.0, "dur": maxf(0.28, f["pos"].distance_to(to) / (6.8 * CELL)), "dmg": dmg,
                "blast": blast, "src": f,
                "frags": int(g.get("frags", 0)), "stun": float(g.get("stun", 0.0)),
                "moab_bonus": float(g.get("moab_bonus", 0.0)),
        })

## the trail: a soft streak child that rides the bullet (darts + shells)
func _trail_child(spr: Sprite2D, tint: Color) -> void:
        var tr := Sprite2D.new()
        tr.texture = _t("fx/p_trail.png")
        tr.position = Vector2(-spr.texture.get_width() * 0.32, 0)
        tr.modulate = tint
        spr.add_child(tr)

func _hitscan(from: Vector2, to: Vector2, dmg: float, cls: String, f: Dictionary, fmj: bool, splash: float) -> void:
        # the sniper speaks instantly; a tracer whispers where it went
        var line := Line2D.new()
        line.points = PackedVector2Array([from, to])
        line.width = 3.0
        line.default_color = Color(1, 1, 0.85, 0.85)
        bullet_layer.add_child(line)
        var tw := create_tween()
        tw.tween_property(line, "modulate:a", 0.0, 0.12)
        tw.tween_callback(line.queue_free)
        for b in bloons.duplicate():
                var bp: Vector2 = (b["spr"] as Sprite2D).position
                var seg := to - from
                var t := clampf((bp - from).dot(seg) / maxf(1.0, seg.length_squared()), 0.0, 1.0)
                if bp.distance_to(from + seg * t) < 0.46 * CELL:
                        var use_cls := PDData.ENERGY if fmj else cls
                        _hurt_bloon(b, dmg, use_cls, f)
                        if splash > 0.0:
                                for o in bloons.duplicate():
                                        if o != b and (o["spr"] as Sprite2D).position.distance_to(bp) < splash * CELL:
                                                _hurt_bloon(o, dmg * 0.5, use_cls, f, true)

func _chain_zap(f: Dictionary, first: Dictionary, dmg: float, chain: int, stun: float) -> void:
        var pts := PackedVector2Array([f["pos"]])
        var current := first
        var hit_ids := {}
        for i in chain:
                if current.is_empty():
                        break
                pts.append((current["spr"] as Sprite2D).position)
                hit_ids[current["id"]] = true
                _hurt_bloon(current, dmg, PDData.ENERGY, f)
                if stun > 0.0 and rng.randf() < stun:
                        current["stun_t"] = maxf(current["stun_t"], 0.4)
                # the next hop: nearest un-hit bloon within 90px
                var next := {}
                var best_d := 1.6 * CELL
                for b in bloons:
                        if hit_ids.has(b["id"]):
                                continue
                        var dd: float = (b["spr"] as Sprite2D).position.distance_to(current["spr"].position)
                        if dd < best_d:
                                best_d = dd
                                next = b
                current = next
        _zap_draw(pts)
        Jukebox.sfx("ps_shoot_zap", -12.0, randf_range(0.9, 1.12))

func _zap_bolt(from: Vector2, to: Vector2) -> void:
        _zap_draw(PackedVector2Array([from, to]))

func _zap_draw(pts: PackedVector2Array) -> void:
        # the jagged lightning (the drawn glow pass)
        var line := Line2D.new()
        var jag := PackedVector2Array()
        for i in pts.size() - 1:
                var a: Vector2 = pts[i]
                var b: Vector2 = pts[i + 1]
                jag.append(a)
                for s in range(1, 4):
                        jag.append(a.lerp(b, float(s) / 4.0) + Vector2(randf_range(-6, 6), randf_range(-6, 6)))
        jag.append(pts[pts.size() - 1])
        line.points = jag
        line.width = 3.5
        line.default_color = Color(1.0, 0.95, 0.5, 0.95)
        bullet_layer.add_child(line)
        var tw := create_tween()
        tw.tween_property(line, "modulate:a", 0.0, 0.16)
        tw.tween_callback(line.queue_free)

func _tick_bullets(delta: float) -> void:
        for b in bullets.duplicate():
                match String(b["kind"]):
                        "bullet":
                                b["pos"] += (b["vel"] as Vector2) * delta
                                (b["spr"] as Sprite2D).position = b["pos"]
                                b["life"] = float(b["life"]) - delta
                                # THE SHOT DIES AT ITS TARGET: the flight ends at
                                # the aimed point (a missed shot never floats on)
                                b["travel"] = float(b.get("travel", 0.0)) + (b["vel"] as Vector2).length() * delta
                                if float(b["travel"]) >= float(b.get("max_d", 1e6)):
                                        b["life"] = 0.0
                                for blo in _grid_near(b["pos"], 0.4 * CELL):
                                        var bid: int = blo["id"]
                                        if (b["hit_ids"] as Dictionary).has(bid):
                                                continue
                                        if (blo["spr"] as Sprite2D).position.distance_to(b["pos"]) < 0.4 * CELL:
                                                (b["hit_ids"] as Dictionary)[bid] = true
                                                if bool(b["glue"]):
                                                        blo["glue_t"] = maxf(blo["glue_t"], float(b["slow_t"]))
                                                        blo["slow_f"] = maxf(blo["slow_f"], float(b["slow"]))
                                                        blo["slow_t"] = maxf(blo["slow_t"], float(b["slow_t"]))
                                                        blo["glue_dps"] = maxf(blo["glue_dps"], float(b["dps"]))
                                                        if (b["src"] as Dictionary).get("flags", {}).get("ignite", false):
                                                                blo["burn_t"] = maxf(blo["burn_t"], 2.0)
                                                                blo["burn_dps"] = maxf(blo["burn_dps"], 1.0)
                                                        Jukebox.sfx("ps_splat", -12.0)
                                                        _burn_paint(blo)
                                                else:
                                                        _hurt_bloon(blo, float(b["dmg"]), String(b["cls"]), b["src"])
                                                        if float(b.get("aoe", 0.0)) > 0.0:
                                                                for o in _grid_near(b["pos"], float(b["aoe"]) * CELL):
                                                                        if o != blo and (o["spr"] as Sprite2D).position.distance_to(b["pos"]) < float(b["aoe"]) * CELL:
                                                                                _hurt_bloon(o, float(b["dmg"]) * 0.6, String(b["cls"]), b["src"], true)
                                                                                if float(b["burn_dps"]) > 0.0:
                                                                                        o["burn_t"] = maxf(o["burn_t"], float(b["burn_t"]))
                                                                                        o["burn_dps"] = maxf(o["burn_dps"], float(b["burn_dps"]))
                                                        if float(b["burn_dps"]) > 0.0:
                                                                blo["burn_t"] = maxf(blo["burn_t"], float(b["burn_t"]))
                                                                blo["burn_dps"] = maxf(blo["burn_dps"], float(b["burn_dps"]))
                                                                _burn_paint(blo)
                                                b["pierce"] = int(b["pierce"]) - 1
                                                if int(b["pierce"]) <= 0:
                                                        b["life"] = 0.0
                                                break
                                if b["pos"].x < FIELD.x - 60 or b["pos"].x > FIELD.x + COLS * CELL + 60 or b["pos"].y < FIELD.y - 60 or b["pos"].y > FIELD.y + ROWS * CELL + 60:
                                        b["life"] = 0.0
                        "rang":
                                b["t"] = float(b["t"]) + delta
                                var half: float = float(b["dur"]) * 0.5
                                var tt: float = float(b["t"])
                                var from: Vector2 = (b["src"] as Dictionary)["pos"]
                                var to: Vector2 = b["target"]
                                if tt <= half:
                                        b["pos"] = from.lerp(to, tt / half)
                                else:
                                        b["pos"] = to.lerp(from, (tt - half) / (float(b["dur"]) - half))
                                (b["spr"] as Sprite2D).position = b["pos"]
                                (b["spr"] as Sprite2D).rotation += delta * 16.0
                                for blo in _grid_near(b["pos"], 0.4 * CELL):
                                        var bid: int = blo["id"]
                                        if (b["hit_ids"] as Dictionary).has(bid):
                                                continue
                                        if (blo["spr"] as Sprite2D).position.distance_to(b["pos"]) < 0.4 * CELL:
                                                (b["hit_ids"] as Dictionary)[bid] = true
                                                _hurt_bloon(blo, float(b["dmg"]), String(b["cls"]), b["src"])
                                if tt >= float(b["dur"]):
                                        b["t"] = 9.0
                        "shell":
                                b["t"] = float(b["t"]) + delta
                                var tt: float = float(b["t"]) / float(b["dur"])
                                var from: Vector2 = b["from"]
                                var to: Vector2 = b["target"]
                                b["pos"] = from.lerp(to, tt) + Vector2(0, -sin(tt * PI) * 42.0)
                                (b["spr"] as Sprite2D).position = b["pos"]
                                (b["spr"] as Sprite2D).rotation += delta * 7.0
                                if tt >= 1.0:
                                        _explosion(b)
                                        # THE SHELL TRUTH (v0.3.5-4): the bomb dies AT its
                                        # blast. The old shell never stopped - t kept counting
                                        # and from.lerp(to, tt) extrapolated it beyond the
                                        # target for up to 9 seconds while spinning (the
                                        # owner's "the ball floats in the sky somehow")
                                        b["t"] = 9.0
                                        (b["spr"] as Sprite2D).visible = false
                if float(b.get("life", 1.0)) <= 0.0 or float(b.get("t", 0.0)) >= 9.0:
                        bullets.erase(b)
                        (b["spr"] as Node2D).queue_free()

func _explosion(b: Dictionary) -> void:
        var at: Vector2 = b["target"]
        _boom_fx(at, float(b["blast"]))
        Jukebox.sfx("ps_boom", -6.0, randf_range(0.9, 1.1))
        var dmg: float = float(b["dmg"])
        var cls := PDData.EXPLOSION
        for blo in _grid_near(at, float(b["blast"]) * CELL + 0.3 * CELL):
                var d2: float = (blo["spr"] as Sprite2D).position.distance_to(at)
                if d2 <= float(b["blast"]) * CELL + 0.3 * CELL:
                        var use := dmg
                        if bool(PDData.BLOONS[blo["kind"]].get("blimp", false)):
                                use += float(b.get("moab_bonus", 0.0))
                        _hurt_bloon(blo, use, cls, b["src"])
                        if float(b.get("stun", 0.0)) > 0.0:
                                blo["stun_t"] = maxf(blo["stun_t"], float(b["stun"]))
        # the frags (G2+)
        if int(b.get("frags", 0)) > 0:
                for i in int(b["frags"]):
                        var a := TAU * float(i) / float(b["frags"])
                        var spr := Sprite2D.new()
                        spr.texture = _t("fx/frag.png")
                        spr.position = at
                        bullet_layer.add_child(spr)
                        bullets.append({
                                "kind": "bullet", "spr": spr, "pos": at, "vel": Vector2(cos(a), sin(a)) * 5.4 * CELL,
                                "dmg": dmg * 0.4, "cls": cls, "pierce": 1, "hit_ids": {}, "src": b["src"], "life": 0.3,
                        })

# ------------------------------------------------------------------- fx
func _fx_spawn(kind: String, at: Vector2, life: float, tint := Color.WHITE) -> Sprite2D:
        var spr := Sprite2D.new()
        spr.texture = _t("fx/%s.png" % kind)
        spr.position = at
        spr.modulate = tint
        fx_layer.add_child(spr)
        var tw := create_tween()
        tw.set_parallel(true)
        tw.tween_property(spr, "modulate:a", 0.0, life)
        tw.tween_property(spr, "scale", Vector2(1.5, 1.5), life)
        tw.chain().tween_callback(spr.queue_free)
        return spr

func _shock_fx(at: Vector2, tint: Color, size: float) -> void:
        var quad := Sprite2D.new()
        quad.texture = _t("fx/ring.png")
        quad.position = at
        quad.scale = Vector2(size, size)
        fx_layer.add_child(quad)
        var m := ShaderMaterial.new()
        m.shader = load("res://game/games/pop_siege/fx/ps_shock.gdshader")
        m.set_shader_parameter("tint", tint)
        quad.material = m
        var tw := create_tween()
        tw.tween_method(func(v: float): m.set_shader_parameter("progress", v), 0.0, 1.0, 0.34)
        tw.tween_callback(quad.queue_free)

func _boom_fx(at: Vector2, blast_cells: float) -> void:
        # THE BOOM TRUTH v2 (v0.3.5-4): one 128px canvas for every frame, the
        # fireball swells to the blast then the smoke fades to NOTHING - no
        # olive ring, no lingering mini-wisps (the owner screenshot the old
        # latest moments and they were buggy). SHORT: 0.30s frames + 0.34s
        # ring, and 2.0x the blast (the old 2.4x read over-intense).
        var px: float = blast_cells * 2.0 * CELL
        if _boom_frames.size() > 0:
                var fspr := Sprite2D.new()
                fspr.texture = _boom_frames[0]
                fspr.position = at
                fspr.scale = Vector2(px / 128.0, px / 128.0)
                fx_layer.add_child(fspr)
                var last := _boom_frames.size() - 1
                var ftw := create_tween()
                ftw.tween_method(func(i: int): _boom_frame(fspr, i), 0, last, 0.30)
                ftw.tween_callback(fspr.queue_free)
        var quad := Sprite2D.new()
        quad.texture = _t("fx/ring.png")
        quad.position = at
        quad.scale = Vector2(px / 128.0, px / 128.0)
        fx_layer.add_child(quad)
        var m := ShaderMaterial.new()
        m.shader = load("res://game/games/pop_siege/fx/ps_boom.gdshader")
        m.set_shader_parameter("tint", Color(1.0, 0.8, 0.35))
        quad.material = m
        var tw := create_tween()
        tw.tween_method(func(v: float): m.set_shader_parameter("progress", v), 0.0, 1.0, 0.34)
        tw.tween_callback(quad.queue_free)

func _boom_frame(fspr: Sprite2D, i: int) -> void:
        if is_instance_valid(fspr) and i >= 0 and i < _boom_frames.size():
                fspr.texture = _boom_frames[i]

# ======================================================== THE UPGRADE MENU
func _menu_paint_live() -> void:
        # the inflicted line breathes during combat (cheap: only when open)
        if menu_box.has_meta("inflicted_lbl"):
                (menu_box.get_meta("inflicted_lbl") as Label).text = "inflicted %d" % int(selected_folk.get("inflicted", 0.0))

func _build_menu() -> void:
        for c in menu_box.get_children():
                c.queue_free()
        menu_box.remove_meta("inflicted_lbl")
        if selected_folk.is_empty():
                return
        var f: Dictionary = selected_folk
        var fid: String = f["fid"]
        var fdef: Dictionary = PDData.FOLK[fid]
        var gear: int = f["gear"]
        var lvl: int = f["lvl"]
        var box := PanelContainer.new()
        var st := StyleBoxFlat.new()
        st.bg_color = Color(0.10, 0.07, 0.04, 0.96)
        st.set_corner_radius_all(14)
        st.set_content_margin_all(10)
        box.add_theme_stylebox_override("panel", st)
        box.size_flags_vertical = Control.SIZE_EXPAND_FILL
        menu_box.add_child(box)
        var vb := VBoxContainer.new()
        vb.add_theme_constant_override("separation", 3)
        box.add_child(vb)
        # the header: face, name, gear badge, level
        var head := HBoxContainer.new()
        head.add_theme_constant_override("separation", 8)
        vb.add_child(head)
        var face := TextureRect.new()
        face.texture = _t("folk/%s_face.png" % fid)
        face.custom_minimum_size = Vector2(56, 56)
        face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        head.add_child(face)
        var hvb := VBoxContainer.new()
        hvb.add_theme_constant_override("separation", 0)
        head.add_child(hvb)
        hvb.add_child(Arc.label(fdef["name"], _fs(26), Arc.CARD))
        hvb.add_child(Arc.label("GEAR %d  LEVEL %d/10" % [gear, lvl], _fs(18), Color(1, 0.85, 0.4)))
        hvb.add_child(Arc.label(fdef["role"], _fs(15), Color(0.85, 0.8, 0.72)))
        # THE >> LAW: every stat row speaks value >> +next
        for row in PDData.rows_for(fid):
                var key: String = row[1]
                var v := PDData.stat(fid, gear, lvl, key)
                var nx := PDData.next_stat(fid, gear, lvl, key)
                var r := HBoxContainer.new()
                r.add_theme_constant_override("separation", 6)
                vb.add_child(r)
                r.add_child(Arc.label(String(row[0]), _fs(17), Color(0.8, 0.75, 0.66)))
                var spacer := Control.new()
                spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                r.add_child(spacer)
                # v0.3.8-4 THE FITTED ROW: the value and the preview wear fit
                # labels on fixed seats - the RANGE line's tail can never walk
                # off the panel again (the owner: "it shows nn >> + and the
                # other text is out of screen")
                r.add_child(Arc.fit_label(_stat_text(key, v), _fs(19), Arc.CARD, 96.0))
                if nx > 0.0:
                        var up_col := Color(0.5, 0.9, 0.5)
                        r.add_child(Arc.label(">>", _fs(17), up_col))
                        r.add_child(Arc.fit_label(_stat_delta_text(key, v, nx), _fs(18), up_col, 110.0))
                else:
                        r.add_child(Arc.label("MAX", _fs(16), Color(1, 0.85, 0.4)))
        # gear extras line (what this gear unlocked)
        var extras := _gear_extras(fid, gear)
        if extras != "":
                vb.add_child(Arc.label("UNLOCKS " + extras, _fs(15), Color(0.65, 0.85, 1.0)))
        # active synergies by name
        var syn := _active_synergy_names(f)
        if syn != "":
                vb.add_child(Arc.label(syn, _fs(15), Color(0.7, 0.95, 0.7)))
        # the inflicted truth (the ES honor)
        var inf := Arc.label("INFLICTED %d" % int(float(f.get("inflicted", 0.0))), _fs(15), Color(0.8, 0.78, 0.7))
        vb.add_child(inf)
        menu_box.set_meta("inflicted_lbl", inf)
        # THE BUTTON TRUTH LAW: the level door UPGRADES; the gear door GEAR
        # UPS; a maxed folk speaks MAX and never wears a fake price again
        menu_box.set_meta("up_btn", null)
        menu_box.set_meta("gear_btn", null)
        if lvl < 10:
                var cost := PDData.up_cost(fid, lvl)
                var up := Arc.coin_button("UPGRADE  %d" % cost, Vector2(0, 46), _fs(20), Arc.ACCENT, func():
                        _do_upgrade(f))
                up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                vb.add_child(up)
                menu_box.set_meta("up_btn", up)
                menu_box.set_meta("up_cost", cost)
        if lvl >= 10 and gear < 3:
                var gcost := PDData.gear_cost(fid, gear)
                var gb := Arc.coin_button("GEAR UP  %d" % gcost, Vector2(0, 46), _fs(20), Color(1.0, 0.62, 0.1), func():
                        _do_gearup(f))
                gb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                vb.add_child(gb)
                menu_box.set_meta("gear_btn", gb)
                menu_box.set_meta("gear_cost", gcost)
        if gear >= 3 and lvl >= 10:
                vb.add_child(Arc.label("THE FINAL GEAR", _fs(15), Color(1, 0.85, 0.4)))
        var row2 := HBoxContainer.new()
        row2.add_theme_constant_override("separation", 6)
        vb.add_child(row2)
        var modes := ["FIRST", "LAST", "STRONG", "CLOSE"]
        var tb := Arc.button("TARGET: " + modes[int(f["mode"])], Vector2(0, 42), _fs(18), Color(0.3, 0.22, 0.12), func():
                f["mode"] = (int(f["mode"]) + 1) % 4
                Jukebox.sfx("ps_click", -10.0)
                _build_menu())
        tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row2.add_child(tb)
        var sell_price := int(float(f.get("invested", int(PDData.FOLK[fid]["place"]))) * PDData.SELL_RATIO)
        var sb := Arc.button("SELL %d" % sell_price, Vector2(0, 42), _fs(18), Arc.BAD, func():
                _do_sell(f))
        sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row2.add_child(sb)
        _paint_menu_afford()

func _paint_menu_afford() -> void:
        # THE GRAY LAW: the wallet speaks through the buttons - an upgrade or
        # gear door the purse cannot open wears gray (live, on every coin)
        if menu_box == null or not is_instance_valid(menu_box) or menu_box.get_child_count() == 0:
                return
        var up: Button = menu_box.get_meta("up_btn", null)
        if up != null and is_instance_valid(up):
                var c := int(menu_box.get_meta("up_cost", 0))
                up.modulate = Color(1, 1, 1) if coins >= c else Color(0.45, 0.45, 0.45, 0.85)
        var gb: Button = menu_box.get_meta("gear_btn", null)
        if gb != null and is_instance_valid(gb):
                var gc := int(menu_box.get_meta("gear_cost", 0))
                gb.modulate = Color(1, 1, 1) if coins >= gc else Color(0.45, 0.45, 0.45, 0.85)

func _stat_text(key: String, v: float) -> String:
        # v0.3.8-4 THE DIRECT SHOTS LAW (the owner: "just make it direct
        # shot/s is much cooler"): the value speaks shots PER SECOND - no
        # interval math is ever asked of the player. Range speaks CELLS (the
        # game's own unit law) - the old px number (434) read like a password.
        match key:
                "rate": return "%.2f/s" % (1.0 / maxf(0.05, v))
                "rng": return "%.1f" % v
                "slow": return "%d%%" % int(v * 100.0)
                "aura": return "+%d%%" % int(v * 100.0)
                "income": return "%d" % int(v)
                _: return "%.1f" % v

## v0.3.8-4 THE HONEST DELTA (the owner: "it says like +20.00/s while the
## increasement could be just extra 0.30/s"): the >> preview computes the
## gain in the SAME units the value wears. The old code fed the raw
## INTERVAL difference (a NEGATIVE number) into the per-second formatter -
## maxf(0.05, -0.03) = 0.05 -> 1/0.05 = "+20.00/s" out of thin air.
func _stat_delta_text(key: String, v: float, nx: float) -> String:
        match key:
                "rate":
                        var d := (1.0 / maxf(0.05, nx)) - (1.0 / maxf(0.05, v))
                        return "%+.2f/s" % d
                "rng": return "%+.1f" % (nx - v)
                "slow", "aura": return "+%d%%" % int(round((nx - v) * 100.0))
                "income": return "%+d" % int(round(nx - v))
                _: return "%+.1f" % (nx - v)

func _gear_extras(fid: String, gear: int) -> String:
        match [fid, gear]:
                ["pyra", 2]: return "FIRE TRAPS"
                ["pyra", 3]: return "THE ETERNAL FLAME"
                ["boomba", 2]: return "FRAG CLUSTER"
                ["boomba", 3]: return "MAULER + STUN"
                ["boomo", 2]: return "THE ORBIT GUARD"
                ["boomo", 3]: return "GRINDER X2 VS BLIMPS"
                ["darty", 2]: return "DOUBLE DART"
                ["darty", 3]: return "GOLDEN DARTS"
                ["gloop", 2]: return "CORROSIVE GLUE"
                ["gloop", 3]: return "THE FLUX"
                ["kolda", 2]: return "PERMAFROST PATCHES"
                ["kolda", 3]: return "DEEP FREEZE"
                ["longeye", 2]: return "FMJ + SHRAPNEL"
                ["longeye", 3]: return "ASSASSIN +25 VS BLIMPS"
                ["zappy", 2]: return "15% STUN"
                ["zappy", 3]: return "THE STORM"
                ["kaching", 2]: return "INTEREST +8%"
                ["kaching", 3]: return "THE GOLDEN EGG"
                ["marshal", 2]: return "AURA RANGE +8%"
                ["marshal", 3]: return "AURA PIERCE +1"
        return ""

func _active_synergy_names(f: Dictionary) -> String:
        var names := []
        for badge in (f["badges"] as Array):
                var bid := String(badge.get_meta("bid"))
                for s in PDData.SYNERGIES:
                        if s["badge"] == bid:
                                names.append(s["name"])
        if names.is_empty():
                return ""
        return "PACTS " + " ".join(PackedStringArray(names))

func _do_upgrade(f: Dictionary) -> void:
        var cost := PDData.up_cost(f["fid"], int(f["lvl"]))
        if int(f["lvl"]) >= 10 or coins < cost:
                Jukebox.sfx("ps_tick_bad", -8.0)
                return
        coins -= cost
        f["lvl"] = int(f["lvl"]) + 1
        f["invested"] = int(f.get("invested", 0)) + cost
        Jukebox.sfx("ps_upgrade", -6.0)
        _fx_spawn("spark", f["pos"], 0.5, Color(1, 0.9, 0.5))
        _recompute_auras()
        # v0.3.8-4 THE LIVE RING: the selection circle reads eff_rng - the
        # upgrade grew it, so the ring REDRAWS NOW (the owner: "the circle
        # does not get refreshed in real-time... i have to re-tap it")
        sel_draw.queue_redraw()
        _refresh_chips()
        _rebuild_cards()
        _build_menu()

func _do_gearup(f: Dictionary) -> void:
        var gear := int(f["gear"])
        var cost := PDData.gear_cost(f["fid"], gear)
        if int(f["lvl"]) < 10 or gear >= 3 or coins < cost:
                Jukebox.sfx("ps_tick_bad", -8.0)
                return
        coins -= cost
        f["gear"] = gear + 1
        f["lvl"] = 1
        f["invested"] = int(f.get("invested", 0)) + cost
        if f["gear"] == 3:
                meta.d["gears3"] = int(meta.d["gears3"]) + 1
                achievement_max("gears3", int(meta.d["gears3"]))
        # THE GEAR LAW: the folk REPAINTS - base AND head wear the new gear
        # (the head re-mounts through THE PIVOT LAW v2)
        var sc := CELL / 62.0
        (f["spr"] as Sprite2D).texture = _t("folk/%s_base.png" % f["fid"])
        (f["spr"] as Sprite2D).scale = Vector2(sc, sc)
        if f.get("head") != null and is_instance_valid(f["head"]):
                (f["head"] as Sprite2D).texture = _t("folk/%s_head_g%d.png" % [f["fid"], f["gear"]])
                _mount_head(f["head"], f["spr"], f["fid"])
        # the golden pillar (the gear-up shader)
        var pillar := Sprite2D.new()
        pillar.texture = _t("fx/spark.png")
        pillar.position = f["pos"]
        pillar.scale = Vector2(2.2, 6.0)
        fx_layer.add_child(pillar)
        var m := ShaderMaterial.new()
        m.shader = load("res://game/games/pop_siege/fx/ps_gearup.gdshader")
        pillar.material = m
        var tw := create_tween()
        tw.tween_method(func(v: float): m.set_shader_parameter("progress", v), 0.0, 1.0, 0.8)
        tw.tween_callback(pillar.queue_free)
        Jukebox.sfx("ps_gearup", -4.0)
        shake_t = 0.2
        _recompute_auras()
        sel_draw.queue_redraw()      # v0.3.8-4 THE LIVE RING (range grew)
        _refresh_chips()
        _build_menu()

func _do_sell(f: Dictionary) -> void:
        # THE SELL LAW: 70% of EVERYTHING invested (place + upgrades + gears)
        var back := int(float(f.get("invested", int(PDData.FOLK[f["fid"]]["place"]))) * PDData.SELL_RATIO)
        coins += back
        folk.erase(f)
        (f["node"] as Node2D).queue_free()
        Jukebox.sfx("ps_sell", -8.0)
        _recompute_auras()
        _select_folk({})
        _refresh_chips()
        _rebuild_cards()

# ================================================================= GAME OVER
func _game_over() -> void:
        if over:
                return
        phase = "over"
        # THE DEATH MENU LAW: every sheet dies FIRST and the tree unpauses;
        # over stays FALSE until finish_run flips it - the old pre-set guard
        # made finish_run bail and the death menu NEVER surface (the owner's
        # "when lose, the death menu does not show up")
        while _sheet_stack.size() > 0:
                sheet_pop()
        get_tree().paused = false
        paused = false
        Jukebox.sfx("ps_lose", -2.0)
        meta.record_run(map["id"], wave_n, score, _pops_run, _moabs_run, 0, 0)
        achievement_max("wave_run", wave_n)
        check_achievements()
        finish_run(score, run_coins)

# ================================================================ THE SHEETS
# THE SHEET PAUSE LAW: a game sheet (SHOP / MAPS) freezes the siege for real
# (the CS sheet-life pattern). The base chain runs PROCESS_MODE_ALWAYS, so the
# sheet stays alive while the world sleeps; the pop resumes if nothing's open.

func _sheet_open(sheet_height: float, id: String, sheet_width: float, build: Callable) -> void:
        get_tree().paused = true
        paused = true
        var vb := sheet_push(sheet_height, id, sheet_width)
        build.call(vb)

## THE REFRESH LAW (the owner's round: "each new buy opens another shop
## window"): one window - the SAME sheet dies and rebuilds in place. A buy
## refreshes the rows, never stacks a new window.
## THE SCROLL TRUTH (v0.3.5-4): the refresh keeps the scroll - the owner
## buys down at row 50, the refreshed list opens AT row 50, never at the
## top again (shop AND maps ride the same law).
var _sheet_scroll := {}      # sheet id -> the scroll offset to restore

func _sheet_refresh(sheet_height: float, id: String, sheet_width: float, build: Callable) -> void:
        if not _sheet_stack.is_empty() and String((_sheet_stack.back() as Dictionary).get("id", "")) == id:
                var old_sc := _find_box_scroll((_sheet_stack.back() as Dictionary)["cc"])
                if old_sc != null:
                        _sheet_scroll[id] = old_sc.scroll_vertical
                sheet_pop()
        _sheet_open(sheet_height, id, sheet_width, build)
        if _sheet_scroll.has(id):
                var want: int = int(_sheet_scroll[id])
                _sheet_scroll.erase(id)
                _restore_scroll_later(want)

func _find_box_scroll(root: Node) -> BoxScroll:
        if root is BoxScroll:
                return root
        for c in root.get_children():
                var f := _find_box_scroll(c)
                if f != null:
                        return f
        return null

func _restore_scroll_later(want: int) -> void:
        # the offset only sticks once the rebuilt sheet has laid out twice
        await get_tree().process_frame
        await get_tree().process_frame
        if _sheet_stack.is_empty():
                return
        var sc := _find_box_scroll((_sheet_stack.back() as Dictionary)["cc"])
        if sc != null:
                sc.scroll_vertical = want

func _goga_sheet_popped(_id: String) -> void:
        if _sheet_stack.is_empty() and not over:
                get_tree().paused = false
                paused = false

func _maps_open() -> void:
        _sheet_open(get_viewport_rect().size.y * 0.90, "maps", minf(1600.0, get_viewport_rect().size.x * 0.62), func(vb: VBoxContainer):
                _build_maps(vb))

func _maps_refresh() -> void:
        _sheet_refresh(get_viewport_rect().size.y * 0.90, "maps", minf(1600.0, get_viewport_rect().size.x * 0.62), func(vb: VBoxContainer):
                _build_maps(vb))

func _build_maps(vb: VBoxContainer) -> void:
        # THE MAPS WALL: the two-column thumbs, directly scrollable (BoxScroll
        # owns the raw touch - scroll works even when the finger hits a card)
        # THE CLOSE LAW: every game sheet wears its own X (the owner's round)
        var head := HBoxContainer.new()
        head.add_theme_constant_override("separation", 10)
        vb.add_child(head)
        head.add_child(Arc.label("THE MAPS", _fs(30), Arc.INK))
        var spacer := Control.new()
        spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        head.add_child(spacer)
        head.add_child(Arc.coin_chip())
        head.add_child(Arc.button("X", Vector2(56, 56), 26, Arc.BAD, func(): sheet_pop()))
        var vp := get_viewport_rect().size
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
        vb.add_child(sc)
        var inner := VBoxContainer.new()
        inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(inner)
        var grid := GridContainer.new()
        grid.columns = 2
        grid.add_theme_constant_override("h_separation", 14)
        grid.add_theme_constant_override("v_separation", 12)
        grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        inner.add_child(grid)
        for m in PDData.maps():
                grid.add_child(_map_card(m, sc))
        for b in Arc._buttons_in(sc):
                if not b.disabled:
                        b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        sc.register_tappable(b, Arc._tap_emitter(b))

func _map_card(m: Dictionary, sc: BoxScroll) -> Control:
        var owned := meta.has_map(m["id"])
        var nite := meta.is_night(m["id"])
        var box := PanelContainer.new()
        var st := StyleBoxFlat.new()
        st.bg_color = Color(0.97, 0.93, 0.85) if owned else Color(0.86, 0.82, 0.76)
        st.set_corner_radius_all(12)
        st.set_content_margin_all(8)
        box.add_theme_stylebox_override("panel", st)
        var vb := VBoxContainer.new()
        vb.add_theme_constant_override("separation", 4)
        box.add_child(vb)
        var thumb := TextureRect.new()
        var tpath := A + ("thumbs/%s.png" % m["id"]) if not nite else A + ("thumbs/%s_n.png" % m["id"])
        thumb.texture = load(tpath)
        thumb.custom_minimum_size = Vector2(320, 178)
        thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        vb.add_child(thumb)
        var stars := ""
        for i in int(m["stars"]):
                stars += "*"
        var name_row := HBoxContainer.new()
        name_row.add_theme_constant_override("separation", 6)
        vb.add_child(name_row)
        name_row.add_child(Arc.label(String(m["name"]), _fs(20), Arc.INK))
        name_row.add_child(Arc.label(stars, _fs(16), Color(0.9, 0.6, 0.1)))
        var bw := meta.best_wave(m["id"])
        var state_row := HBoxContainer.new()
        state_row.add_theme_constant_override("separation", 6)
        vb.add_child(state_row)
        var state_txt := "FREE" if int(m["price"]) == 0 else ("OWNED" if owned else "LOCKED")
        state_row.add_child(Arc.label(state_txt, _fs(15), Color(0.4, 0.35, 0.28)))
        var m_paths: int = (m["paths"] as Array).size()
        if m_paths > 1:
                state_row.add_child(Arc.label("%d DOORS" % m_paths, _fs(15), Color(0.75, 0.45, 0.12)))
        if bw > 0:
                state_row.add_child(Arc.label("BEST %d" % bw, _fs(15), Color(0.55, 0.4, 0.16)))
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 6)
        vb.add_child(row)
        # the day / night chips (BUNDLED - both are yours)
        for pair in [["DAY", false], ["NIGHT", true]]:
                var want_night: bool = bool(pair[1])
                var dn_btn := Arc.button(String(pair[0]), Vector2(76, 38), _fs(15),
                        Arc.ACCENT if want_night == nite else Color(0.72, 0.67, 0.58), func():
                        meta.set_night(m["id"], want_night)
                        # v0.3.5-6 THE LIVE NIGHT LAW (the owner: "if I opened
                        # map menu and selected night at the map I play on, it
                        # does not switch it dynamically which is bad"): the
                        # chip re-themes the LIVE field the moment it flips
                        if String(m["id"]) == String(map["id"]) and night != want_night:
                                night = want_night
                                _build_night()
                        Jukebox.sfx("ps_click", -10.0)
                        _maps_refresh())
                row.add_child(dn_btn)
        var action := Arc.button("PLAY", Vector2(0, 46), _fs(18), Arc.GOOD, func(): pass)
        if owned:
                if map["id"] == m["id"]:
                        action.text = "HERE"
                        action.disabled = true
                        Arc.gray_out_button(action)
                else:
                        action.pressed.connect(func(): _switch_map(m["id"]))
        else:
                action.text = "BUY"
                action.pressed.connect(func():
                        var price := int(m["price"])
                        if Box.spend(price):
                                meta.gogabuy_map(m["id"])
                                Jukebox.sfx("ps_gogacoin", -4.0)
                                game_toast("%s IS YOURS" % String(m["name"]).to_upper())
                                _maps_refresh()
                        else:
                                Jukebox.sfx("ps_tick_bad", -6.0)
                                game_toast("NOT ENOUGH GOGACOINS"))
                row.add_child(_coin_price(str(int(m["price"]))))
        action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(action)
        return box

func _coin_price(txt: String) -> Control:
        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", 5)
        var ic := TextureRect.new()
        ic.texture = load("res://assets/ui/coin.png")
        ic.custom_minimum_size = Vector2(28, 28)
        ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        h.add_child(ic)
        h.add_child(Arc.label(txt, _fs(20), Color(0.75, 0.5, 0.05)))
        return h

func _switch_map(mid: String) -> void:
        meta.set_current_map(mid)
        Jukebox.sfx("ps_place", -4.0)
        while _sheet_stack.size() > 0:
                sheet_pop()
        get_tree().paused = false
        paused = false
        finish_run(score, run_coins)   # banking the run; the host reloads into the pick

# ============================================================ THE SHOP
func _shop_open() -> void:
        _sheet_open(get_viewport_rect().size.y * 0.90, "shop", minf(1500.0, get_viewport_rect().size.x * 0.55), func(vb: VBoxContainer):
                _build_shop(vb))

func _build_shop(vb: VBoxContainer) -> void:
        # THE SHOP LAWS: WIDER sheet, BoxScroll body (scroll under the finger,
        # rows stay tappable - the registered-tappable law), one wallet chip,
        # and THE CLOSE LAW: the sheet wears its own X
        var head := HBoxContainer.new()
        head.add_theme_constant_override("separation", 10)
        vb.add_child(head)
        head.add_child(Arc.label("THE SHOP", _fs(30), Arc.INK))
        var spacer := Control.new()
        spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        head.add_child(spacer)
        head.add_child(Arc.coin_chip())
        head.add_child(Arc.button("X", Vector2(56, 56), 26, Arc.BAD, func(): sheet_pop()))
        var vp := get_viewport_rect().size
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
        vb.add_child(sc)
        var col := VBoxContainer.new()
        col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        col.add_theme_constant_override("separation", 6)
        sc.add_child(col)
        col.add_child(Arc.label("THE FOLK", _fs(22), Color(0.4, 0.3, 0.15)))
        for fid in PDData.folk_ids():
                col.add_child(_shop_folk_row(fid))
        col.add_child(Arc.label("THE MAPS", _fs(22), Color(0.4, 0.3, 0.15)))
        for m in PDData.maps():
                col.add_child(_shop_map_row(m))
        for b in Arc._buttons_in(sc):
                if not b.disabled:
                        b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        sc.register_tappable(b, Arc._tap_emitter(b))

func _shop_folk_row(fid: String) -> Control:
        var fdef: Dictionary = PDData.FOLK[fid]
        var owned := meta.has_folk(fid)
        var box := PanelContainer.new()
        var st := StyleBoxFlat.new()
        st.bg_color = Color(0.98, 0.94, 0.86)
        st.set_corner_radius_all(12)
        st.set_content_margin_all(8)
        box.add_theme_stylebox_override("panel", st)
        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", 10)
        box.add_child(h)
        var face := TextureRect.new()
        face.texture = _t("folk/%s_g1.png" % fid)
        face.custom_minimum_size = Vector2(66, 74)
        face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        h.add_child(face)
        var vb2 := VBoxContainer.new()
        vb2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        vb2.add_theme_constant_override("separation", 0)
        h.add_child(vb2)
        vb2.add_child(Arc.label(String(fdef["name"]), _fs(22), Arc.INK))
        vb2.add_child(Arc.label(String(fdef["role"]), _fs(15), Color(0.45, 0.4, 0.32)))
        if owned:
                var free_txt := "FREE" if int(fdef["goga"]) == 0 else "OWNED"
                h.add_child(Arc.label(free_txt, _fs(18), Arc.GOOD))
        else:
                var buy := Arc.coin_button("BUY %d" % int(fdef["goga"]), Vector2(210, 56), _fs(20), Arc.ACCENT, func():
                        if Box.spend(int(fdef["goga"])):
                                meta.gogabuy_folk(fid)
                                Jukebox.sfx("ps_gogacoin", -4.0)
                                game_toast("%s JOINS THE SIEGE" % String(fdef["name"]).to_upper())
                                _rebuild_cards()
                                _shop_refresh()
                        else:
                                Jukebox.sfx("ps_tick_bad", -6.0)
                                game_toast("NOT ENOUGH GOGACOINS"))
                h.add_child(buy)
        return box

func _shop_map_row(m: Dictionary) -> Control:
        var owned := meta.has_map(m["id"])
        var box := PanelContainer.new()
        var st := StyleBoxFlat.new()
        st.bg_color = Color(0.98, 0.94, 0.86)
        st.set_corner_radius_all(12)
        st.set_content_margin_all(8)
        box.add_theme_stylebox_override("panel", st)
        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", 10)
        box.add_child(h)
        var thumb := TextureRect.new()
        thumb.texture = load(A + "thumbs/%s.png" % m["id"])
        thumb.custom_minimum_size = Vector2(130, 74)
        thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        h.add_child(thumb)
        var vb3 := VBoxContainer.new()
        vb3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        vb3.add_theme_constant_override("separation", 0)
        h.add_child(vb3)
        vb3.add_child(Arc.label(String(m["name"]), _fs(20), Arc.INK))
        var stars := ""
        for i in int(m["stars"]):
                stars += "*"
        vb3.add_child(Arc.label(stars + "  DAY + NIGHT", _fs(14), Color(0.45, 0.4, 0.32)))
        if owned:
                var free_txt := "FREE" if int(m["price"]) == 0 else "OWNED"
                h.add_child(Arc.label(free_txt, _fs(18), Arc.GOOD))
        else:
                var buy := Arc.coin_button("BUY %d" % int(m["price"]), Vector2(210, 56), _fs(20), Arc.ACCENT, func():
                        if Box.spend(int(m["price"])):
                                meta.gogabuy_map(m["id"])
                                Jukebox.sfx("ps_gogacoin", -4.0)
                                game_toast("%s IS YOURS" % String(m["name"]).to_upper())
                                _shop_refresh()
                        else:
                                Jukebox.sfx("ps_tick_bad", -6.0)
                                game_toast("NOT ENOUGH GOGACOINS"))
                h.add_child(buy)
        return box

func _shop_refresh() -> void:
        _sheet_refresh(get_viewport_rect().size.y * 0.90, "shop", minf(1500.0, get_viewport_rect().size.x * 0.55), func(vb: VBoxContainer):
                _build_shop(vb))

# ============================================================ DRAW CLASSES
class GhostDraw extends Node2D:
        var game                 # the pop_siege (untyped: dynamic access)
        func _draw() -> void:
                var g = game
                if g.selected_place == "" or g.ghost_cell.x < 0:
                        return
                var c: Vector2i = g.ghost_cell
                var ok: bool = g._buildable(c)
                var col := Color(0.3, 0.9, 0.35, 0.4) if ok else Color(0.95, 0.25, 0.2, 0.4)
                draw_rect(Rect2(g.FIELD + Vector2(c) * g.CELL, Vector2(g.CELL, g.CELL)), col)
                if ok:
                        draw_arc(g._cell_pos(c.x, c.y), PDData.stat(g.selected_place, 1, 1, "rng") * g.CELL, 0, TAU, 40, Color(1, 1, 1, 0.35), 2.0)

class SelDraw extends Node2D:
        var game                 # the pop_siege (untyped: dynamic access)
        func _draw() -> void:
                var g = game
                if g.selected_folk.is_empty():
                        return
                var f: Dictionary = g.selected_folk
                var rng_px: float = float(f.get("eff_rng", 0.0))
                if rng_px <= 0.0:
                        return
                draw_circle(f["pos"], rng_px, Color(1, 1, 1, 0.07))
                draw_arc(f["pos"], rng_px, 0, TAU, 48, Color(1, 1, 1, 0.5), 2.5)
                # the target modes badge: a small ring marker
                draw_arc(f["pos"], 24.0, 0, TAU, 24, Color(1, 0.85, 0.4, 0.9), 3.0)

class ZoneDraw extends Node2D:
        var game                 # the pop_siege (untyped: dynamic access)
        func _draw() -> void:
                var g = game
                # the permafrost patches
                for p in g.patches:
                        draw_circle(p["pos"], p["r"], Color(0.55, 0.8, 1.0, 0.22 * clampf(p["t"], 0.0, 1.0)))

class HpBar extends Node2D:
        ## the honest tank bar (ceramic + blimps): back, fill, tip
        var ratio := 1.0
        var w := 40.0
        func _draw() -> void:
                var h := 7.0
                draw_rect(Rect2(-w / 2 - 1, -1, w + 2, h + 2), Color(0.08, 0.06, 0.04, 0.85))
                var col := Color(0.35, 0.9, 0.4)
                if ratio < 0.35:
                        col = Color(0.9, 0.3, 0.25)
                elif ratio < 0.7:
                        col = Color(0.95, 0.75, 0.25)
                if ratio > 0.01:
                        draw_rect(Rect2(-w / 2, 0, w * ratio, h), col)

class StripDraw extends Node2D:
        ## THE STRIPS LAW made visible: each band hides a bloon of that color
        ## (the counts never show). Drawn over the bloon body in TEXTURE local
        ## coords (the parent sprite's scale applies - one draw, no nodes).
        var bloons_ref
        var game                # the pop_siege (the KIND_COLORS table lives there)
        func _draw() -> void:
                if bloons_ref == null or not is_instance_valid(bloons_ref.get("spr")):
                        return
                var strips: Array = bloons_ref.get("strips", [])
                if strips.is_empty():
                        return
                var tex: Texture2D = (bloons_ref["spr"] as Sprite2D).texture
                var tw := float(tex.get_width()) * 0.74
                var th := float(tex.get_height())
                var bh := th / float(strips.size() + 2)
                for i in strips.size():
                        var col: Color = game.KIND_COLORS.get(String(strips[i]), Color(0.8, 0.8, 0.8))
                        var y := th * 0.5 - (strips.size() * bh) * 0.5 + i * bh
                        draw_rect(Rect2(-tw / 2, y, tw, maxf(2.0, bh * 0.66)), Color(col.r, col.g, col.b, 0.85))
