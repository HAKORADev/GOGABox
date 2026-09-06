extends GogaGame
## POP SIEGE (v0.3.5) - the bloon siege. 30 maps, 10 folk, 3 gears x 10
## upgrades each, in-range synergies, PopCoins, and the GOGACoin that hides
## inside a bloon every 10 waves. Landscape. THE LAWS live in the GDD
## (docs/goga_docs/gogames_ideas/pop_siege.md) - the hits law, the /1000 law,
## the 2x15 law, the >> law, the gear law, the rider law, the smooth law.

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
var phase := "idle"          # idle | spawn | clear | over
var countdown := 0.0
var speed_mult := 1
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
var road_draw: Node2D
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
var cards_box: GridContainer
var menu_box: VBoxContainer
var play_btn: Button
var selected_place := ""         # folk id being placed
var selected_folk: Dictionary = {}   # the placed folk tapped
var ghost: Sprite2D
var ghost_cell := Vector2i(-1, -9)
var _tex: Dictionary = {}
var _pop_pitch := 0

func _t(p: String) -> Texture2D:
        if not _tex.has(p):
                _tex[p] = load(A + p)
        return _tex[p]

func _fs(sz: int) -> int:
        # the big-text law inherited from the house style: keep the field UI loud
        return int(sz * 1.15)

# ------------------------------------------------------------------ helpers
func _cell_pos(c: int, r: int) -> Vector2:
        return Vector2(FIELD.x + (c + 0.5) * CELL, FIELD.y + (r + 0.5) * CELL)

func _cell_of(p: Vector2) -> Vector2i:
        return Vector2i(int((p.x - FIELD.x) / CELL), int((p.y - FIELD.y) / CELL))

func _in_field(p: Vector2) -> bool:
        return p.x >= FIELD.x and p.x < FIELD.x + COLS * CELL and p.y >= FIELD.y and p.y < FIELD.y + ROWS * CELL

func _blocked_cells() -> Dictionary:
        var b := {}
        for c in map["blocked"]:
                b[Vector2i(int(c[0]), int(c[1]))] = true
        for w in map.get("water", []):
                b[Vector2i(int(w[0]), int(w[1]))] = true
        var road := {}
        for pts in map["paths"]:
                for i in range(pts.size() - 1):
                        var a0: Vector2i = Vector2i(pts[i][0], pts[i][1])
                        var b0: Vector2i = Vector2i(pts[i + 1][0], pts[i + 1][1])
                        var steps: int = maxi(absi(b0.x - a0.x), absi(b0.y - a0.y))
                        for s in steps + 1:
                                var t := float(s) / maxf(1.0, float(steps))
                                road[Vector2i(roundi(a0.x + (b0.x - a0.x) * t), roundi(a0.y + (b0.y - a0.y) * t))] = true
        road[Vector2i(map["heart"][0], map["heart"][1])] = true
        for k in road:
                b[k] = true
        return b

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
        map = PDData.map_by_id(meta.current_map())
        night = meta.is_night(map["id"])
        coins = PDData.START_COINS
        lives = PDData.START_LIVES
        wave_n = 0
        victory_done = false
        set_hud_score_prefix("POPS")
        add_hud_button("SHOP", func(): _shop_open())
        add_hud_button("OPTIONALS", func(): _optionals_open())
        _build_field()
        _build_panel()
        _rebuild_cards()
        _build_night()
        Jukebox.music("res://assets/audio/music/ps_theme.wav")
        _next_wave_countdown(10.0)
        check_achievements()

# ------------------------------------------------------------ field build
func _build_field() -> void:
        field = Node2D.new()
        add_child(field)
        # the grain ground (tiled)
        var g := Sprite2D.new()
        g.texture = load(A + "tiles/%s.png" % map["theme"])
        g.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
        g.region_enabled = true
        g.region_rect = Rect2(0, 0, COLS * CELL, ROWS * CELL)
        g.centered = false
        g.position = FIELD
        field.add_child(g)
        # water cells (the shimmer shader)
        for w in map.get("water", []):
                var wr := ColorRect.new()
                wr.size = Vector2(CELL, CELL)
                wr.position = Vector2(FIELD.x + w[0] * CELL, FIELD.y + w[1] * CELL)
                var m := ShaderMaterial.new()
                m.shader = load("res://game/games/pop_siege/fx/ps_water.gdshader")
                m.set_shader_parameter("is_lava", 1.0 if map.get("water_kind", "") == "lava" else 0.0)
                wr.material = m
                field.add_child(wr)
        # the road
        _build_paths()
        road_draw = RoadDraw.new()
        road_draw.game = self
        field.add_child(road_draw)
        road_draw.queue_redraw()
        # props
        for bcell in map["blocked"]:
                var spr := Sprite2D.new()
                spr.texture = _t("props/%s.png" % bcell[2])
                spr.position = _cell_pos(bcell[0], bcell[1]) + Vector2(0, -6)
                spr.scale = Vector2(0.62, 0.62)
                field.add_child(spr)
        # decor scatter
        for dcell in map["decor"]:
                var spr := Sprite2D.new()
                spr.texture = _t("props/%s.png" % dcell[2])
                spr.position = _cell_pos(dcell[0], dcell[1]) + Vector2(rng.randf_range(-10, 10), rng.randf_range(-8, 8))
                spr.scale = Vector2(0.5, 0.5)
                spr.modulate.a = 0.92
                field.add_child(spr)
        # the heart house at every path's end
        heart_spr = Sprite2D.new()
        heart_spr.texture = _t("props/house.png")
        heart_spr.position = _cell_pos(map["heart"][0], map["heart"][1]) + Vector2(0, -14)
        heart_spr.scale = Vector2(0.78, 0.78)
        field.add_child(heart_spr)
        # layers
        folk_layer = Node2D.new(); field.add_child(folk_layer)
        bloon_layer = Node2D.new(); field.add_child(bloon_layer)
        bullet_layer = Node2D.new(); field.add_child(bullet_layer)
        fx_layer = Node2D.new(); field.add_child(fx_layer)
        ghost_draw = GhostDraw.new(); ghost_draw.game = self; field.add_child(ghost_draw)
        sel_draw = SelDraw.new(); sel_draw.game = self; field.add_child(sel_draw)
        zones2d = ZoneDraw.new(); zones2d.game = self; field.add_child(zones2d)
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

func _build_paths() -> void:
        _paths_px.clear()
        for pts in map["paths"]:
                var px := PackedVector2Array()
                for c in pts:
                        px.append(_cell_pos(c[0], c[1]))
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
func _build_night() -> void:
        if night_rect != null:
                night_rect.queue_free()
                night_rect = null
        if fireflies != null:
                fireflies.visible = night
        if not night:
                return
        # THE NIGHT LAW: a cold multiply tint (the ground still reads) +
        # the heart's warm lamp + the fireflies. Cheap on every phone.
        night_rect = ColorRect.new()
        night_rect.size = Vector2(COLS, ROWS) * CELL
        night_rect.position = FIELD
        night_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        night_rect.color = PDData.THEMES[map["theme"]]["night"]
        var mm := CanvasItemMaterial.new()
        mm.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
        night_rect.material = mm
        field.add_child(night_rect)
        var lamp := Sprite2D.new()
        lamp.texture = _t("fx/spark.png")
        lamp.position = heart_spr.position
        lamp.scale = Vector2(14.0, 14.0)
        lamp.modulate = Color(1.0, 0.8, 0.45, 0.30)
        var lm := CanvasItemMaterial.new()
        lm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
        lamp.material = lm
        field.add_child(lamp)

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
        # chips row: lives / popcoins / wave / speed
        var chips_row := HBoxContainer.new()
        chips_row.add_theme_constant_override("separation", 6)
        vb.add_child(chips_row)
        chips["lives"] = Arc.chip("100", "res://assets/ui/heart.png", Color(0.10, 0.06, 0.03, 0.55), _fs(24))
        chips_row.add_child(chips["lives"])
        chips["coins"] = Arc.chip("250", A + "ui/popcoin.png", Color(0.10, 0.06, 0.03, 0.55), _fs(24))
        chips_row.add_child(chips["coins"])
        chips["wave"] = Arc.chip("WAVE 0", "", Color(0.10, 0.06, 0.03, 0.55), _fs(24))
        chips_row.add_child(chips["wave"])
        var sp := Arc.button("x1", Vector2(58, 40), _fs(22), Color(0.22, 0.15, 0.08), func(): _toggle_speed())
        chips_row.add_child(sp)
        chips["speed_btn"] = sp
        # the PLAY row
        play_btn = Arc.button("PLAY WAVE 1", Vector2(0, 52), _fs(26), Arc.GOOD, func(): _play_pressed())
        play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        vb.add_child(play_btn)
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
        speed_mult = 2 if speed_mult == 1 else 1
        (chips["speed_btn"] as Button).text = "x%d" % speed_mult
        Jukebox.sfx("ps_click", -10.0)

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
        _chip_label(chips["lives"]).text = str(lives)
        _chip_label(chips["coins"]).text = str(coins)
        _chip_label(chips["wave"]).text = "WAVE %d%s" % [wave_n, " - SIEGE BROKEN" if victory_done and wave_n > PDData.VICTORY_WAVE else ""]
        if phase == "idle":
                play_btn.text = "PLAY WAVE %d  (%ds)" % [wave_n + 1, int(ceil(countdown))]
                Arc.repaint_button(play_btn, Arc.GOOD)
        elif phase == "spawn" or phase == "clear":
                play_btn.text = "WAVE %d ROLLING" % wave_n
                Arc.repaint_button(play_btn, Color(0.24, 0.17, 0.10))

# ------------------------------------------------------------ the folk cards
func _rebuild_cards() -> void:
        for c in cards_box.get_children():
                c.queue_free()
        for fid in PDData.folk_ids():
                if not meta.has_folk(fid):
                        continue
                var f: Dictionary = PDData.FOLK[fid]
                var b := Button.new()
                b.custom_minimum_size = Vector2(0, 92)
                b.clip_text = false
                var style := StyleBoxFlat.new()
                style.bg_color = Color(0.13, 0.09, 0.05, 0.92)
                style.set_corner_radius_all(12)
                b.add_theme_stylebox_override("normal", style)
                var hov := style.duplicate()
                hov.bg_color = Color(0.22, 0.15, 0.08, 0.95)
                b.add_theme_stylebox_override("hover", hov)
                b.add_theme_stylebox_override("pressed", hov)
                var h := HBoxContainer.new()
                h.set_anchors_preset(Control.PRESET_FULL_RECT)
                h.offset_left = 8
                h.add_theme_constant_override("separation", 6)
                h.mouse_filter = Control.MOUSE_FILTER_IGNORE
                var face := TextureRect.new()
                face.texture = _t("folk/%s_face.png" % fid)
                face.custom_minimum_size = Vector2(64, 64)
                face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                face.mouse_filter = Control.MOUSE_FILTER_IGNORE
                h.add_child(face)
                var vb := VBoxContainer.new()
                vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
                vb.add_theme_constant_override("separation", 0)
                h.add_child(vb)
                var nm := Arc.label(f["name"], _fs(22), Arc.CARD)
                vb.add_child(nm)
                var cost_row := HBoxContainer.new()
                cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
                cost_row.add_theme_constant_override("separation", 3)
                vb.add_child(cost_row)
                var cicon := TextureRect.new()
                cicon.texture = _t("ui/popcoin.png")
                cicon.custom_minimum_size = Vector2(20, 20)
                cicon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                cicon.mouse_filter = Control.MOUSE_FILTER_IGNORE
                cost_row.add_child(cicon)
                cost_row.add_child(Arc.label(str(f["place"]), _fs(20), Color(1, 0.85, 0.4)))
                b.add_child(h)
                var fid_c: String = fid
                b.pressed.connect(func(): _card_tapped(fid_c))
                cards_box.add_child(b)
                # affordability paint (refreshed with coins)
                b.modulate = Color(1, 1, 1, 1.0) if coins >= int(f["place"]) else Color(0.55, 0.55, 0.55, 0.85)

func _card_tapped(fid: String) -> void:
        var f: Dictionary = PDData.FOLK[fid]
        if coins < int(f["place"]):
                Jukebox.sfx("ps_tick_bad", -8.0)
                return
        _select_folk({})
        selected_place = fid
        if ghost == null:
                ghost = Sprite2D.new()
                ghost.texture = _t("folk/%s_g1.png" % fid)
                field.add_child(ghost)
        else:
                ghost.texture = _t("folk/%s_g1.png" % fid)
        ghost.visible = true
        ghost.modulate = Color(1, 1, 1, 0.75)
        Jukebox.sfx("ps_click", -10.0)

func _cancel_place() -> void:
        selected_place = ""
        if ghost != null:
                ghost.visible = false
        ghost_cell = Vector2i(-1, -9)
        ghost_draw.queue_redraw()

# ------------------------------------------------------------- selection
func _select_folk(f: Dictionary) -> void:
        selected_folk = f
        _build_menu()
        sel_draw.queue_redraw()

# --------------------------------------------------------- tick: input
func _goga_input(event: InputEvent) -> void:
        if over:
                return
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
                if event.pressed:
                        var p: Vector2 = get_global_mouse_position()
                        if _in_field(p):
                                _press_at(p)
                else:
                        _release_at(get_global_mouse_position())
        elif event is InputEventMouseMotion and selected_place != "":
                _drag_to(get_global_mouse_position())
        elif event is InputEventScreenTouch:
                var st: InputEventScreenTouch = event
                if st.pressed and _in_field(st.position):
                        _press_at(st.position)
                elif not st.pressed:
                        _release_at(st.position)
        elif event is InputEventScreenDrag and selected_place != "":
                _drag_to(event.position)

func _press_at(p: Vector2) -> void:
        # a placed folk under the finger? select it; else start a placement drag
        for f in folk:
                if (f["pos"] as Vector2).distance_to(p) < CELL * 0.6:
                        _cancel_place()
                        _select_folk(f)
                        return
        # tapping empty field closes the menu
        if selected_place == "":
                _select_folk({})

func _drag_to(p: Vector2) -> void:
        if ghost != null and ghost.visible:
                ghost.position = p
                var c := _cell_of(p)
                if c != ghost_cell:
                        ghost_cell = c
                        var ok := _buildable(c)
                        Jukebox.sfx("ps_tick_ok" if ok else "ps_tick_bad", -14.0)
                ghost_draw.queue_redraw()

func _release_at(p: Vector2) -> void:
        if selected_place == "":
                return
        var c := _cell_of(p)
        if _buildable(c) and coins >= int(PDData.FOLK[selected_place]["place"]):
                _place_folk(selected_place, c)
        coins = coins  # (paint handled in place)
        _cancel_place()
        _rebuild_cards()
        _refresh_chips()

func _place_folk(fid: String, c: Vector2i) -> void:
        var fdef: Dictionary = PDData.FOLK[fid]
        coins -= int(fdef["place"])
        var pos := _cell_pos(c.x, c.y)
        var node := Node2D.new()
        node.position = pos
        folk_layer.add_child(node)
        var spr := Sprite2D.new()
        spr.texture = _t("folk/%s_g1.png" % fid)
        node.add_child(spr)
        var puff := _fx_spawn("smoke", pos + Vector2(0, 14), 0.5)
        puff.scale = Vector2(1.4, 1.4)
        var f := {
                "id": rng.randi(), "fid": fid, "gear": 1, "lvl": 1, "cell": c, "pos": pos,
                "cd": 0.0, "mode": 0, "inflicted": 0.0, "node": node, "spr": spr, "badges": [],
                "buffs": {"rate_f": 1.0, "rng_f": 1.0, "dmg_f": 0.0, "pierce_f": 0, "blast_f": 1.0, "coin_pop": 0},
                "timers": {}, "target": -1,
        }
        folk.append(f)
        _recompute_auras()
        Jukebox.sfx("ps_place", -6.0)
        _select_folk(f)
        # the FIRST-GLANCE law for multi-path maps
        if (map["paths"] as Array).size() > 1 and not meta.seen_multipath():
                meta.mark_multipath()
                Arc.toast(Arc.toast_overlay(self), "two roads - split your defense!")

# --------------------------------------------------------------- the laws
func _recompute_auras() -> void:
        # THE SYNERGY ENGINE: pairs earn their pacts; badges speak.
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
                # range recompute (the aura could have grown it)
                f["eff_rng"] = PDData.stat(fid, gear, f["lvl"], "rng") * CELL * CELL * float(f["buffs"]["rng_f"])
                if fid == "kaching" or PDData.FOLK[fid]["cls"] == "support":
                        f["eff_rng"] = PDData.stat(fid, gear, f["lvl"], "rng") * CELL
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

func _play_pressed() -> void:
        if phase != "idle" or over:
                return
        if countdown > 0.5:
                var bonus := 10 + wave_n          # the early-call bonus
                coins += bonus
                Jukebox.sfx("ps_coin", -8.0)
        countdown = 0.0
        _start_wave()

func _start_wave() -> void:
        wave_n += 1
        phase = "spawn"
        spawn_clock = 0.0
        spawn_q.clear()
        wave_kinds.clear()
        spawn_count = 0
        var stars := int(map["stars"])
        var groups := PDData.wave_groups(wave_n, stars)
        var n_paths: int = (map["paths"] as Array).size()
        var gi := 0
        for g in groups:
                for i in int(g["count"]):
                        spawn_q.append({
                                "kind": g["kind"],
                                "at": float(g["delay"]) + i * float(g["spacing"]),
                                "pi": (gi % n_paths) if n_paths > 1 else 0,   # multi-path alternation
                        })
                gi += 1
                wave_kinds.append(g["kind"])
        # THE RIDER LAW: every 10th wave hides a GOGACoin inside a bloon
        rider_index = -1
        if wave_n % PDData.RIDER_EVERY == 0 and spawn_q.size() > 0:
                rider_index = rng.randi_range(maxi(0, spawn_q.size() - maxi(1, spawn_q.size() / 3)), spawn_q.size() - 1)
        Jukebox.sfx("ps_horn", -10.0)
        if wave_n == PDData.VICTORY_WAVE or wave_n == 30:
                Jukebox.sfx("ps_wave_boss", -8.0)
        _refresh_chips()

func _end_wave() -> void:
        phase = "idle"
        # the wave pay: kaching income + the flat bonus
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
        coins += int(income) + 20 + wave_n * 2
        # records + achievements
        achievement_max("wave_best", wave_n)
        if wave_n == PDData.VICTORY_WAVE and not victory_done:
                victory_done = true
                Jukebox.sfx("ps_victory", -4.0)
                Arc.toast(Arc.toast_overlay(self), "THE SIEGE BREAKS! endless marches on...")
        # endless fatigue is applied in the movement law
        _next_wave_countdown(12.0)
        check_achievements()

# ---------------------------------------------------------------- bloons
var _bloon_seq := 0

func _spawn_bloon(kind: String, pi: int) -> void:
        var def: Dictionary = PDData.BLOONS[kind]
        var spr := Sprite2D.new()
        spr.texture = _t("bloons/%s.png" % kind)
        bloon_layer.add_child(spr)
        var lane := rng.randf_range(-CELL * 0.22, CELL * 0.22)
        _bloon_seq += 1
        var b := {
                "id": _bloon_seq, "kind": kind, "hp": float(def["hp"]), "max_hp": float(def["hp"]),
                "pi": pi, "dist": -rng.randf_range(0.0, 10.0), "lane": lane,
                "slow_f": 0.0, "slow_t": 0.0, "glue_t": 0.0, "glue_dps": 0.0, "burn_dps": 0.0, "burn_t": 0.0,
                "stun_t": 0.0, "rider": false, "depth": 0, "spr": spr, "frozen": false,
        }
        if def.get("blimp", false) and not meta.seen_blimp():
                meta.mark_blimp()
                Arc.toast(Arc.toast_overlay(self), "A BLIMP! bring the boom and fire.")
        bloons.append(b)
        _paint_bloon(b)

func _paint_bloon(b: Dictionary) -> void:
        var spr: Sprite2D = b["spr"]
        var def: Dictionary = PDData.BLOONS[b["kind"]]
        spr.scale = Vector2.ONE * float(def["scl"])
        # ceramic cracks by hp (the honest shell)
        if b["kind"] == "ceramic":
                var ratio: float = b["hp"] / b["max_hp"]
                if ratio < 0.35:
                        spr.texture = _t("bloons/ceramic_c2.png")
                elif ratio < 0.7:
                        spr.texture = _t("bloons/ceramic_c1.png")
                else:
                        spr.texture = _t("bloons/ceramic.png")
        # the rider's faint golden shimmer
        spr.modulate = Color(1.06, 1.03, 0.85) if b["rider"] else Color.WHITE

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
                var at: Dictionary = pos_on(b["pi"], b["dist"])
                var dir: Vector2 = at["dir"]
                var nrm := Vector2(-dir.y, dir.x)
                var p: Vector2 = at["p"] + nrm * b["lane"]
                (b["spr"] as Sprite2D).position = p
                if b["dist"] >= float(_paths_px[b["pi"]]["total"]):
                        dead.append(b)
        for b in dead:
                _leak(b)

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
        var rbe := PDData.rbe(b["kind"])
        lives -= rbe
        Jukebox.sfx("ps_leak", -6.0)
        shake_t = 0.35 if rbe >= 40 else 0.18
        _heart_flash()
        _bloon_free(b)
        _refresh_chips()
        if lives <= 0 and not over:
                lives = 0
                _game_over()

func _heart_flash() -> void:
        heart_spr.modulate = Color(2.0, 0.6, 0.6)
        var tw := create_tween()
        tw.tween_property(heart_spr, "modulate", Color.WHITE, 0.5)

# ------------------------------------------------------------ damage + pop
func _hurt_bloon(b: Dictionary, dmg: float, cls: String, src: Variant, silent := false) -> bool:
        # the honest matrix (immunities block, BRUTUS halves sharp)
        var real := PDData.dmg_vs(b["kind"], cls, dmg)
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
        b["hp"] -= real
        add_score(1)                     # THE HITS LAW: every connected hit = 1 point
        if src != null:
                src["inflicted"] = float(src.get("inflicted", 0.0)) + real
        _paint_bloon(b)
        if b["hp"] <= 0.0:
                _pop_bloon(b, src)
        if not selected_folk.is_empty() and src == selected_folk:
                _menu_paint_live()
        return true

func _pop_bloon(b: Dictionary, src: Variant) -> void:
        var def: Dictionary = PDData.BLOONS[b["kind"]]
        # the pop: the ladder pitch climbs with depth (the star sound)
        var pitch_idx: int = clampi(int(b["depth"]), 0, 4)
        Jukebox.sfx("ps_pop%d" % pitch_idx, -6.0, randf_range(0.94, 1.06))
        var col := Color.WHITE
        match b["kind"]:
                "red": col = Color(0.95, 0.3, 0.3)
                "blue": col = Color(0.35, 0.55, 0.95)
                "green": col = Color(0.35, 0.8, 0.4)
                "yellow": col = Color(0.98, 0.85, 0.3)
                "pink": col = Color(0.98, 0.5, 0.75)
                "rainbow": col = Color(0.9, 0.6, 0.95)
                "ceramic": col = Color(0.85, 0.55, 0.3)
                "moab", "brutus":
                        col = Color(0.5, 0.6, 0.95)
                        Jukebox.sfx("ps_moab_pop", -4.0)
                        shake_t = 0.5
                        _boom_fx(b["spr"].position, 1.6)
                        _moabs_run += 1
                        achievement_max("moab_kills", _moabs_run)
        # the shockwave shader
        _shock_fx(b["spr"].position, col, 0.9 if def.get("blimp", false) else 0.5)
        # the coins (the pop pays)
        var pay := int(def["coins"])
        if src != null:
                pay += int((src as Dictionary)["buffs"].get("coin_pop", 0))
        coins += pay
        _pops_run += 1
        achievement_max("pops_run", _pops_run)
        # THE RIDER: the hidden GOGACoin flies to the wallet
        if b["rider"]:
                meta.d["riders"] = int(meta.d["riders"]) + 1
                add_run_coins(1)
                Jukebox.sfx("ps_gogacoin", -4.0)
                _fx_spawn("spark", b["spr"].position, 0.8, Color(1.0, 0.85, 0.3))
                Arc.toast(Arc.toast_overlay(self), "a GOGACoin was hiding in there!")
        # the children carry on (same path, spread)
        var kids: Array = def["kids"]
        var off := 2.0
        for k in kids:
                _spawn_child(k, b, off)
                off += 6.0
        _bloon_free(b)
        _refresh_chips()
        _rebuild_cards()

func _spawn_child(kind: String, parent: Dictionary, off: float) -> void:
        var def: Dictionary = PDData.BLOONS[kind]
        var spr := Sprite2D.new()
        spr.texture = _t("bloons/%s.png" % kind)
        bloon_layer.add_child(spr)
        _bloon_seq += 1
        var b := {
                "id": _bloon_seq, "kind": kind, "hp": float(def["hp"]), "max_hp": float(def["hp"]),
                "pi": parent["pi"], "dist": maxf(0.0, float(parent["dist"]) - off),
                "lane": clampf(float(parent["lane"]) + randf_range(-8, 8), -CELL * 0.24, CELL * 0.24),
                "slow_f": parent["slow_f"], "slow_t": parent["slow_t"], "glue_t": parent["glue_t"],
                "glue_dps": parent["glue_dps"], "burn_dps": parent["burn_dps"], "burn_t": parent["burn_t"],
                "stun_t": parent["stun_t"], "rider": false, "depth": int(parent["depth"]) + 1,
                "spr": spr, "frozen": parent["frozen"],
        }
        bloons.append(b)
        _paint_bloon(b)

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
        if phase == "idle" and not over:
                countdown -= d
                if countdown <= 0.0:
                        countdown = 0.0
                        _start_wave()
                else:
                        _refresh_chips()
        elif phase == "spawn" or phase == "clear":
                spawn_clock += d
                while spawn_q.size() > 0 and float(spawn_q[0]["at"]) <= spawn_clock:
                        var s: Dictionary = spawn_q.pop_front()
                        var b_idx := spawn_count
                        _spawn_bloon(s["kind"], int(s["pi"]))
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

# ------------------------------------------------------------ folk firing
func _pick_target(f: Dictionary, rng_px: float) -> Dictionary:
        # modes: 0 first (max dist), 1 last (min dist), 2 strong (max hp), 3 close (min dist to folk)
        var best := {}
        var best_v := -1.0
        for b in bloons:
                var d2: float = (b["spr"] as Sprite2D).position.distance_to(f["pos"])
                if d2 > rng_px:
                        continue
                var at: Dictionary = pos_on(b["pi"], b["dist"])
                var v: float
                match int(f["mode"]):
                        0: v = b["dist"]
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
                # gear specials on their own clocks
                _tick_specials(f, g, delta, rng_px)
                if rate <= 0.0:
                        continue     # kaching (the bank) never fires
                f["cd"] = float(f["cd"]) - delta
                if float(f["cd"]) > 0.0:
                        continue
                var target := _pick_target(f, rng_px)
                if target.is_empty():
                        continue
                f["cd"] = rate / float(buffs["rate_f"])
                _fire_folk(f, target, g)

func _fire_folk(f: Dictionary, target: Dictionary, g: Dictionary) -> void:
        var fid: String = f["fid"]
        var rng_px: float = float(f.get("eff_rng", PDData.stat(fid, int(f["gear"]), int(f["lvl"]), "rng") * CELL))
        var dmg: float = PDData.stat(fid, f["gear"], f["lvl"], "dmg") + float(f["buffs"]["dmg_f"])
        var cls: String = PDData.FOLK[fid]["cls"]
        var from: Vector2 = f["pos"]
        var to: Vector2 = (target["spr"] as Sprite2D).position
        match fid:
                "darty":
                        var shots: int = int(g.get("shots", 1))
                        var tex := "fx/p_gold_dart.png" if f["gear"] >= 3 else "fx/p_dart.png"
                        for i in shots:
                                _bullet_spawn(from, to, tex, dmg, cls, int(g.get("pierce", 1)) + int(f["buffs"]["pierce_f"]), 7.5 * CELL, f)
                        Jukebox.sfx("ps_shoot_dart", -12.0, randf_range(0.95, 1.05))
                "boomo":
                        _rang_spawn(f, to, dmg, int(g.get("pierce", 3)) + int(f["buffs"]["pierce_f"]))
                        Jukebox.sfx("ps_shoot_rang", -12.0)
                "boomba":
                        _shell_spawn(f, to, dmg, float(g["blast"]) * float(f["buffs"]["blast_f"]), g)
                        Jukebox.sfx("ps_shoot_bomb", -10.0)
                "pyra":
                        _bullet_spawn(from, to, "fx/p_flame.png", dmg, cls, 2 + int(f["buffs"]["pierce_f"]), 5.4 * CELL, f,
                                {"aoe": float(g["blast"]), "burn_dps": PDData.stat("pyra", f["gear"], f["lvl"], "burn"),
                                "burn_t": float(g["burn_t"]), "src_f": f})
                        Jukebox.sfx("ps_shoot_flame", -14.0, randf_range(0.9, 1.1))
                "kolda":
                        # the pulse: everything in range feels the chill
                        for b in bloons.duplicate():
                                if (b["spr"] as Sprite2D).position.distance_to(from) <= rng_px:
                                        var slowed := _hurt_bloon(b, dmg, cls, f, true)
                                        if slowed or PDData.dmg_vs(b["kind"], cls, dmg) > 0.0:
                                                b["slow_f"] = maxf(b["slow_f"], float(g["slow"]))
                                                b["slow_t"] = maxf(b["slow_t"], float(g["slow_t"]))
                                                if f["gear"] >= 3 and bool(g.get("deep", false)) and not bool(PDData.BLOONS[b["kind"]].get("blimp", false)):
                                                        b["frozen"] = true
                                                        _frozen_timer(b, 0.8)
                                        _fx_spawn("snowflake", b["spr"].position, 0.3)
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
                        for b in bloons.duplicate():
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
                                for b in bloons.duplicate():
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
                                        for b in bloons.duplicate():
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
                                        for b in bloons:
                                                if bool(PDData.BLOONS[b["kind"]].get("blimp", false)) and (b["spr"] as Sprite2D).position.distance_to(f["pos"]) <= rng_px:
                                                        b["stun_t"] = maxf(b["stun_t"], float(g.get("blimp_freeze", 1.2)))
                                                        _fx_spawn("snowflake", b["spr"].position, 0.5)
                                                        break
                "zappy":
                        # G3: THE STORM - random strikes everywhere in range
                        if f["gear"] >= 3 and float(g.get("storm_every", 0.0)) > 0.0:
                                t["storm"] = float(t.get("storm", 0.0)) - delta
                                if float(t["storm"]) <= 0.0:
                                        t["storm"] = float(g["storm_every"])
                                        var in_rng := []
                                        for b in bloons:
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
        spr.texture = _t("fx/trap.png")
        spr.position = best["p"]
        fx_layer.add_child(spr)
        traps.append({"spr": spr, "t": 6.0, "dps": float(PDData.FOLK["pyra"]["gears"][f["gear"] - 1].get("trap_dps", 3.0)), "src": f})
        Jukebox.sfx("ps_trap", -12.0)

func _tick_traps(delta: float) -> void:
        for tr in traps.duplicate():
                tr["t"] -= delta
                for b in bloons.duplicate():
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
        bullet_layer.add_child(spr)
        var dir := (to - from).normalized()
        spr.rotation = dir.angle()
        bullets.append({
                "kind": "bullet", "spr": spr, "pos": from, "vel": dir * spd, "dmg": dmg,
                "cls": cls, "pierce": pierce, "hit_ids": {}, "src": src, "life": 1.6,
                "aoe": float(extra.get("aoe", 0.0)), "burn_dps": float(extra.get("burn_dps", 0.0)),
                "burn_t": float(extra.get("burn_t", 0.0)), "glue": bool(extra.get("glue", false)),
                "slow": float(extra.get("slow", 0.0)), "slow_t": float(extra.get("slow_t", 0.0)),
                "dps": float(extra.get("dps", 0.0)),
        })

func _rang_spawn(f: Dictionary, to: Vector2, dmg: float, pierce: int) -> void:
        var spr := Sprite2D.new()
        spr.texture = _t("fx/p_boomerang.png")
        spr.position = f["pos"]
        bullet_layer.add_child(spr)
        bullets.append({
                "kind": "rang", "spr": spr, "pos": f["pos"], "target": to, "t": 0.0,
                "dur": 1.1, "dmg": dmg, "cls": PDData.SHARP, "pierce": pierce, "hit_ids": {},
                "src": f, "out": true,
        })

func _shell_spawn(f: Dictionary, to: Vector2, dmg: float, blast: float, g: Dictionary) -> void:
        var spr := Sprite2D.new()
        spr.texture = _t("fx/p_bomb.png")
        spr.position = f["pos"]
        bullet_layer.add_child(spr)
        bullets.append({
                "kind": "shell", "spr": spr, "pos": f["pos"], "from": f["pos"], "target": to,
                "t": 0.0, "dur": maxf(0.28, f["pos"].distance_to(to) / (6.8 * CELL)), "dmg": dmg,
                "blast": blast, "src": f,
                "frags": int(g.get("frags", 0)), "stun": float(g.get("stun", 0.0)),
                "moab_bonus": float(g.get("moab_bonus", 0.0)),
        })

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
                                for blo in bloons.duplicate():
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
                                                                for o in bloons.duplicate():
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
                                for blo in bloons.duplicate():
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
                if float(b.get("life", 1.0)) <= 0.0 or float(b.get("t", 0.0)) >= 9.0:
                        bullets.erase(b)
                        (b["spr"] as Node2D).queue_free()

func _explosion(b: Dictionary) -> void:
        var at: Vector2 = b["target"]
        _boom_fx(at, float(b["blast"]) / 52.0)
        Jukebox.sfx("ps_boom", -6.0, randf_range(0.9, 1.1))
        var dmg: float = float(b["dmg"])
        var cls := PDData.EXPLOSION
        for blo in bloons.duplicate():
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

func _boom_fx(at: Vector2, size: float) -> void:
        var quad := Sprite2D.new()
        quad.texture = _t("fx/ring.png")
        quad.position = at
        quad.scale = Vector2(size * 2.0, size * 2.0)
        fx_layer.add_child(quad)
        var m := ShaderMaterial.new()
        m.shader = load("res://game/games/pop_siege/fx/ps_boom.gdshader")
        m.set_shader_parameter("tint", Color(1.0, 0.8, 0.35))
        quad.material = m
        var tw := create_tween()
        tw.tween_method(func(v: float): m.set_shader_parameter("progress", v), 0.0, 1.0, 0.5)
        tw.tween_callback(quad.queue_free)

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
        hvb.add_child(Arc.label("GEAR %d  -  level %d/10" % [gear, lvl], _fs(18), Color(1, 0.85, 0.4)))
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
                r.add_child(Arc.label(_stat_text(key, v), _fs(19), Arc.CARD))
                if nx > 0.0:
                        var up_col := Color(0.5, 0.9, 0.5)
                        r.add_child(Arc.label(">>", _fs(17), up_col))
                        r.add_child(Arc.label("+" + _stat_text(key, nx - v), _fs(18), up_col))
                else:
                        r.add_child(Arc.label("MAX", _fs(16), Color(1, 0.85, 0.4)))
        # gear extras line (what this gear unlocked)
        var extras := _gear_extras(fid, gear)
        if extras != "":
                vb.add_child(Arc.label(extras, _fs(15), Color(0.65, 0.85, 1.0)))
        # active synergies by name
        var syn := _active_synergy_names(f)
        if syn != "":
                vb.add_child(Arc.label(syn, _fs(15), Color(0.7, 0.95, 0.7)))
        # the inflicted truth (the ES honor)
        var inf := Arc.label("inflicted %d" % int(float(f.get("inflicted", 0.0))), _fs(15), Color(0.8, 0.78, 0.7))
        vb.add_child(inf)
        menu_box.set_meta("inflicted_lbl", inf)
        # the buttons
        var cost := PDData.up_cost(fid, lvl)
        var up := Arc.coin_button("UPGRADE  %d" % cost, Vector2(0, 46), _fs(20), Arc.ACCENT, func():
                _do_upgrade(f))
        up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        vb.add_child(up)
        if lvl >= 10 and gear < 3:
                var gcost := PDData.gear_cost(fid, gear)
                var gb := Arc.coin_button("GEAR UP  %d" % gcost, Vector2(0, 46), _fs(20), Color(1.0, 0.62, 0.1), func():
                        _do_gearup(f))
                gb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                vb.add_child(gb)
        if gear >= 3 and lvl >= 10:
                vb.add_child(Arc.label("THE FINAL GEAR - it shines.", _fs(15), Color(1, 0.85, 0.4)))
        var row2 := HBoxContainer.new()
        row2.add_theme_constant_override("separation", 6)
        vb.add_child(row2)
        var modes := ["first", "last", "strong", "close"]
        var tb := Arc.button("TARGET: " + modes[int(f["mode"])], Vector2(0, 42), _fs(18), Color(0.3, 0.22, 0.12), func():
                f["mode"] = (int(f["mode"]) + 1) % 4
                Jukebox.sfx("ps_click", -10.0)
                _build_menu())
        tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row2.add_child(tb)
        var sell_price := int(float(PDData.FOLK[fid]["place"]) * 0.5 * float(lvl) * PDData.SELL_RATIO) + int(PDData.FOLK[fid]["place"]) / 3
        var sb := Arc.button("SELL %d" % sell_price, Vector2(0, 42), _fs(18), Arc.BAD, func():
                _do_sell(f))
        sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row2.add_child(sb)
        _paint_menu_afford(cost)

func _paint_menu_afford(cost: int) -> void:
        # gray the UPGRADE button when the wallet can't sing
        for n in menu_box.find_children("*", "Button", true, false):
                var b := n as Button
                if b.text.begins_with("UPGRADE"):
                        b.modulate = Color(1, 1, 1) if coins >= cost else Color(0.5, 0.5, 0.5, 0.8)

func _stat_text(key: String, v: float) -> String:
        match key:
                "rate": return "%.2f/s" % (1.0 / maxf(0.05, v))
                "rng": return "%d" % int(v * CELL)
                "slow": return "%d%%" % int(v * 100.0)
                "aura": return "+%d%%" % int(v * 100.0)
                "income": return "%d" % int(v)
                _: return "%.1f" % v

func _gear_extras(fid: String, gear: int) -> String:
        match [fid, gear]:
                ["pyra", 2]: return "unlocked: FIRE TRAPS on the road"
                ["pyra", 3]: return "unlocked: THE ETERNAL FLAME ring"
                ["boomba", 2]: return "unlocked: frag cluster"
                ["boomba", 3]: return "unlocked: mauler (+ vs blimps) + stun"
                ["boomo", 2]: return "unlocked: the orbit guard"
                ["boomo", 3]: return "unlocked: grinder (x2 hits vs blimps)"
                ["darty", 2]: return "unlocked: double dart"
                ["darty", 3]: return "unlocked: golden darts"
                ["gloop", 2]: return "unlocked: corrosive glue"
                ["gloop", 3]: return "unlocked: THE FLUX (teleports them back)"
                ["kolda", 2]: return "unlocked: permafrost patches"
                ["kolda", 3]: return "unlocked: deep freeze (+1 all dmg to frozen)"
                ["longeye", 2]: return "unlocked: FMJ (pops lead) + shrapnel"
                ["longeye", 3]: return "unlocked: assassin (+25 vs blimps)"
                ["zappy", 2]: return "unlocked: 15% stun"
                ["zappy", 3]: return "unlocked: THE STORM strikes"
                ["kaching", 2]: return "unlocked: interest +8%"
                ["kaching", 3]: return "unlocked: the golden egg (+120 every 5 waves)"
                ["marshal", 2]: return "unlocked: +8% range in the aura"
                ["marshal", 3]: return "unlocked: +1 pierce in the aura"
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
        return "pacts: " + ", ".join(PackedStringArray(names))

func _do_upgrade(f: Dictionary) -> void:
        var cost := PDData.up_cost(f["fid"], int(f["lvl"]))
        if int(f["lvl"]) >= 10 or coins < cost:
                Jukebox.sfx("ps_tick_bad", -8.0)
                return
        coins -= cost
        f["lvl"] = int(f["lvl"]) + 1
        Jukebox.sfx("ps_upgrade", -6.0)
        _fx_spawn("spark", f["pos"], 0.5, Color(1, 0.9, 0.5))
        _recompute_auras()
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
        if f["gear"] == 3:
                meta.d["gears3"] = int(meta.d["gears3"]) + 1
                achievement_max("gears3", int(meta.d["gears3"]))
        # THE GEAR LAW: the folk REPAINTS - you see the power
        (f["spr"] as Sprite2D).texture = _t("folk/%s_g%d.png" % [f["fid"], f["gear"]])
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
        _refresh_chips()
        _build_menu()

func _do_sell(f: Dictionary) -> void:
        var back := int(float(PDData.FOLK[f["fid"]]["place"]) * 0.5 * float(f["lvl"]) * PDData.SELL_RATIO) + int(PDData.FOLK[f["fid"]]["place"]) / 3
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
        over = true
        phase = "over"
        Jukebox.sfx("ps_lose", -2.0)
        meta.record_run(map["id"], wave_n, score, _pops_run, _moabs_run, 0, 0)
        achievement_max("wave_run", wave_n)
        check_achievements()
        finish_run(score, run_coins)

# ================================================================ THE SHEETS
func _optionals_open() -> void:
        var vb := sheet_push(0.0, "optionals")
        var title := Arc.label("OPTIONALS", _fs(30), Arc.INK)
        vb.add_child(title)
        var maps_btn := Arc.button("MAPS", Vector2(0, 64), _fs(26), Arc.ACCENT, func():
                _maps_sheet())
        maps_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        vb.add_child(maps_btn)
        var guide := Arc.button("HOW TO PLAY", Vector2(0, 54), _fs(20), Color(0.9, 0.8, 0.6), func():
                _guide_sheet())
        guide.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        vb.add_child(guide)
        var restart := Arc.button("RESTART MAP", Vector2(0, 54), _fs(20), Color(0.85, 0.6, 0.3), func():
                _switch_map(map["id"]))
        restart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        vb.add_child(restart)

func _maps_sheet() -> void:
        # THE 2x15 LAW: two vertical columns of 15, thumbs, day+night bundled.
        sheet_pop()
        var vb := sheet_push(get_viewport_rect().size.y * 0.88, "maps")
        vb.add_child(Arc.label("THE MAPS - 30 sieges, day and night", _fs(26), Arc.INK))
        var scroll := ScrollContainer.new()
        scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
        vb.add_child(scroll)
        var grid := GridContainer.new()
        grid.columns = 2
        grid.add_theme_constant_override("h_separation", 10)
        grid.add_theme_constant_override("v_separation", 10)
        scroll.add_child(grid)
        for m in PDData.maps():
                grid.add_child(_map_card(m))

func _map_card(m: Dictionary) -> Control:
        var owned := meta.has_map(m["id"])
        var nite := meta.is_night(m["id"])
        var box := PanelContainer.new()
        var st := StyleBoxFlat.new()
        st.bg_color = Color(0.98, 0.94, 0.86) if owned else Color(0.88, 0.84, 0.78)
        st.set_corner_radius_all(12)
        st.set_content_margin_all(8)
        box.add_theme_stylebox_override("panel", st)
        var vb := VBoxContainer.new()
        vb.add_theme_constant_override("separation", 4)
        box.add_child(vb)
        var thumb := TextureRect.new()
        var tpath := A + ("thumbs/%s.png" % m["id"]) if not nite else A + ("thumbs/%s_n.png" % m["id"])
        thumb.texture = load(tpath)
        thumb.custom_minimum_size = Vector2(220, 124)
        thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        vb.add_child(thumb)
        var stars := ""
        for i in int(m["stars"]):
                stars += "*"
        var name_row := HBoxContainer.new()
        name_row.add_theme_constant_override("separation", 6)
        vb.add_child(name_row)
        name_row.add_child(Arc.label(String(m["name"]), _fs(19), Arc.INK))
        name_row.add_child(Arc.label(stars, _fs(16), Color(0.9, 0.6, 0.1)))
        var bw := meta.best_wave(m["id"])
        var state_txt := "FREE" if int(m["price"]) == 0 else ("OWNED" if owned else "locked")
        if bw > 0:
                state_txt += "  -  best wave %d" % bw
        vb.add_child(Arc.label(state_txt, _fs(15), Color(0.4, 0.35, 0.28)))
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 6)
        vb.add_child(row)
        # the day / night chips (BUNDLED - both are yours)
        for pair in [["DAY", false], ["NIGHT", true]]:
                var dn_btn := Arc.button(String(pair[0]), Vector2(70, 36), _fs(15),
                        Arc.ACCENT if bool(pair[1]) == nite else Color(0.75, 0.7, 0.6), func(): pass)
                var want_night: bool = bool(pair[1])
                dn_btn.pressed.connect(func():
                        meta.set_night(m["id"], want_night)
                        Jukebox.sfx("ps_click", -10.0)
                        _maps_sheet())
                row.add_child(dn_btn)
        var action := Arc.button("PLAY", Vector2(0, 40), _fs(18), Arc.GOOD, func(): pass)
        if owned:
                action.text = "PLAY" if map["id"] != m["id"] else "HERE NOW"
                action.pressed.connect(func():
                        if map["id"] == m["id"]:
                                sheet_pop()
                                return
                        _switch_map(m["id"]))
        else:
                action.text = "BUY"
                action.disabled = false
                action.pressed.connect(func():
                        var price := int(m["price"])
                        if Box.spend(price):
                                meta.gogabuy_map(m["id"])
                                Jukebox.sfx("ps_gogacoin", -4.0)
                                Arc.toast(Arc.toast_overlay(self), "%s is yours - day and night" % m["name"])
                                _maps_sheet()
                        else:
                                Jukebox.sfx("ps_tick_bad", -6.0)
                                Arc.toast(Arc.toast_overlay(self), "not enough GOGACoins"))
                row.add_child(_coin_price(str(int(m["price"]))))
        action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(action)
        return box

func _coin_price(txt: String) -> Control:
        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", 4)
        var ic := TextureRect.new()
        ic.texture = load("res://assets/ui/coin.png")
        ic.custom_minimum_size = Vector2(22, 22)
        ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        h.add_child(ic)
        h.add_child(Arc.label(txt, _fs(18), Color(0.75, 0.5, 0.05)))
        return h

func _guide_sheet() -> void:
        sheet_pop()
        var vb := sheet_push(get_viewport_rect().size.y * 0.86, "guide")
        vb.add_child(Arc.label("HOW TO PLAY", _fs(28), Arc.INK))
        var lines := [
                "drag a folk card onto green grass - red cells are blocked or road",
                "tap a placed folk: every stat shows its value >> the next upgrade",
                "10 levels per gear, then GEAR UP - new powers, a bigger look",
                "folk near each other earn pacts - watch the badge icons appear",
                "every hit is 1 point; the run bonus is score /1000",
                "every 10 waves a GOGACoin hides inside a bloon - pop the right one",
                "the lead bloon shrugs off darts - boom and fire crack it",
                "black shrugs off booms, white shrugs off ice, zebra shrugs off both",
                "survive wave 40 and THE SIEGE BREAKS - then endless marches on",
        ]
        for ln in lines:
                vb.add_child(Arc.label("- " + ln, _fs(18), Color(0.35, 0.28, 0.2)))

func _switch_map(mid: String) -> void:
        meta.set_current_map(mid)
        meta.set_night(mid, meta.is_night(mid))
        Jukebox.sfx("ps_place", -4.0)
        finish_run(score, run_coins)   # banking the run; the host reloads into the pick

# ============================================================ THE SHOP
func _shop_open() -> void:
        var vb := sheet_push(get_viewport_rect().size.y * 0.86, "shop")
        var head := HBoxContainer.new()
        vb.add_child(head)
        head.add_child(Arc.label("THE SHOP", _fs(28), Arc.INK))
        var spacer := Control.new()
        spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        head.add_child(spacer)
        head.add_child(Arc.coin_chip())
        vb.add_child(Arc.label("folk for the field, maps for the war", _fs(17), Color(0.5, 0.42, 0.3)))
        var scroll := ScrollContainer.new()
        scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
        vb.add_child(scroll)
        var col := VBoxContainer.new()
        col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        col.add_theme_constant_override("separation", 6)
        scroll.add_child(col)
        col.add_child(Arc.label("THE FOLK", _fs(22), Color(0.4, 0.3, 0.15)))
        for fid in PDData.folk_ids():
                col.add_child(_shop_folk_row(fid))
        col.add_child(Arc.label("THE MAPS", _fs(22), Color(0.4, 0.3, 0.15)))
        for m in PDData.maps():
                col.add_child(_shop_map_row(m))

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
        face.texture = _t("folk/%s_face.png" % fid)
        face.custom_minimum_size = Vector2(56, 56)
        face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        h.add_child(face)
        var vb := VBoxContainer.new()
        vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        vb.add_theme_constant_override("separation", 0)
        h.add_child(vb)
        vb.add_child(Arc.label(String(fdef["name"]), _fs(21), Arc.INK))
        vb.add_child(Arc.label(String(fdef["role"]), _fs(15), Color(0.45, 0.4, 0.32)))
        if owned:
                var free_txt := "FREE" if int(fdef["goga"]) == 0 else "OWNED"
                h.add_child(Arc.label(free_txt, _fs(18), Arc.GOOD))
        else:
                var buy := Arc.coin_button("", Vector2(120, 44), _fs(18), Arc.ACCENT, func(): pass)
                buy.text = "BUY %d" % int(fdef["goga"])
                buy.pressed.connect(func():
                        if Box.spend(int(fdef["goga"])):
                                meta.gogabuy_folk(fid)
                                Jukebox.sfx("ps_gogacoin", -4.0)
                                Arc.toast(Arc.toast_overlay(self), "%s joins the siege!" % fdef["name"])
                                _rebuild_cards()
                                _shop_open()
                        else:
                                Jukebox.sfx("ps_tick_bad", -6.0)
                                Arc.toast(Arc.toast_overlay(self), "not enough GOGACoins"))
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
        thumb.custom_minimum_size = Vector2(120, 68)
        thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        h.add_child(thumb)
        var vb := VBoxContainer.new()
        vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        vb.add_theme_constant_override("separation", 0)
        h.add_child(vb)
        vb.add_child(Arc.label(String(m["name"]), _fs(20), Arc.INK))
        var stars := ""
        for i in int(m["stars"]):
                stars += "*"
        vb.add_child(Arc.label(stars + "  day + night together", _fs(14), Color(0.45, 0.4, 0.32)))
        if owned:
                var free_txt := "FREE" if int(m["price"]) == 0 else "OWNED"
                h.add_child(Arc.label(free_txt, _fs(18), Arc.GOOD))
        else:
                var buy := Arc.coin_button("BUY %d" % int(m["price"]), Vector2(130, 44), _fs(18), Arc.ACCENT, func(): pass)
                buy.pressed.connect(func():
                        if Box.spend(int(m["price"])):
                                meta.gogabuy_map(m["id"])
                                Jukebox.sfx("ps_gogacoin", -4.0)
                                Arc.toast(Arc.toast_overlay(self), "%s is yours - day and night" % m["name"])
                                _shop_open()
                        else:
                                Jukebox.sfx("ps_tick_bad", -6.0))
                h.add_child(buy)
        return box

# ============================================================ DRAW CLASSES
class RoadDraw extends Node2D:
        var game                 # the pop_siege (untyped: dynamic access)
        func _draw() -> void:
                var g = game
                var theme: Dictionary = PDData.THEMES[g.map["theme"]]
                for pts in g.map["paths"]:
                        var pl := PackedVector2Array()
                        for c in pts:
                                pl.append(g._cell_pos(c[0], c[1]))
                        # edge, body, dashes (the road reads at a glance)
                        draw_polyline(pl, theme["road_edge"], 34.0)
                        draw_polyline(pl, theme["road"], 28.0)
                        var dash := PackedVector2Array()
                        var total: float = g._paths_px[g.map["paths"].find(pts)]["total"]
                        var d := 0.0
                        while d < total:
                                var at: Dictionary = g.pos_on(g.map["paths"].find(pts), d)
                                dash.append(at["p"])
                                d += 26.0
                        for i in range(0, dash.size() - 1, 2):
                                draw_line(dash[i], dash[i + 1], theme["road_edge"], 3.0)
                        # the spawn pad
                        draw_circle(pl[0], 16.0, Color(0.35, 0.2, 0.12, 0.9))
                        draw_circle(pl[0], 10.0, Color(0.85, 0.3, 0.25, 0.95))

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




