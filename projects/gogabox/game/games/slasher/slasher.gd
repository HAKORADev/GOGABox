extends GogaGame
## Fruit Slasher - v0.3.0 (the owner's verdict round: "work harder on it
## so it gets even better than the real fruit ninja"). The game now runs
## on the CLASSIC real art (the ChineseDron fruit-ninja set: apple,
## banana, basaha, peach, sandia - each with its two real cut halves, the
## flash glint, the smoke) on the CLASSIC WOOD BOARD, and the slice is
## the real thing: the fruit is replaced by its two pre-drawn halves,
## aligned to YOUR cut line, thrown apart with physical flips.
##
## Owner laws (v0.2.9 + the v0.3.0 verdict):
##   - the position ask first; portrait tosses from below (g 1560),
##     landscape lobs across from the left (g 1180) - two different games
##   - the ask shows ONLY the two phone cards (no hint text)
##   - fruit +1 (a small "+1" floats right at the cut); a fallen fruit
##     -2 (its own "-2" where it fell); the score floors at 0
##   - three hearts; a slashed bomb takes one - a REAL explosion (flash,
##     shockwave, smoke, sparks, shake); 0 hearts ends the run
##   - real juice: fruit-tinted droplets + splatter decals that stick to
##     the wood and fade
##   - a GOGACoin every 20s from the last one, slashed like a fruit
##   - the vegetables shop item keeps its options toggle (painted stand-in
##     art until a real veg pack lands - documented in slasher.md)
##   - run bonus /15 (registry coin_div 15)
##   - tiny sparkles only ("small cool things, not what you did")
##
## Probe contract: items/halves/hearts/score public; _spawn_pattern,
## _cut_item, _register_miss, _flush_loss drive the laws headless.

const MODES := {
        "vertical": {
                "gravity": 1560.0,
                "from_bottom": true,
                "vx": [-140.0, 140.0],
                "vy": [-1580.0, -1200.0],
                "spin": [-3.2, 3.2],
        },
        # v0.3.1: the owner - "the horizontal mode... it throws from the
        # left to the bottom, while it is supposed to be from the center
        # from bottom". BOTH positions now toss from the bottom; the
        # landscape spreads wider from the CENTER with lighter gravity.
        "horizontal": {
                "gravity": 1240.0,
                "from_bottom": true,
                "center_spread": 0.42,
                "vx": [-320.0, 320.0],
                "vy": [-1420.0, -1080.0],
                "spin": [-4.2, 4.2],
        },
}
const MISS_COST := 2
const START_HEARTS := 3
const COIN_EVERY_S := 20.0
const SLICE_HALF_V := 240.0
const VEG_PRICE := 1500
const LOSS_WINDOW := 0.9

const FRUITS := ["apple", "banana", "basaha", "peach", "sandia"]
const VEGGIES := ["carrot", "tomato", "eggplant", "broccoli", "corn", "pepper"]
## v0.3.1 PATCH III - THE SHAPED COLLISION (the owner: "each object should
## have a collision that shaped like it"): the long produce wears a
## CAPSULE along its own body, everything round wears an honest CIRCLE.
const ELONG := ["banana", "carrot", "eggplant", "corn"]
## the juice tints per fruit (the real flesh colors)
const JUICE := {
        "apple": Color("cde97e"), "banana": Color("ffe98a"),
        "basaha": Color("ff4f63"), "peach": Color("ffb377"),
        "sandia": Color("ff5f6d"),
        "carrot": Color("ff9e40"), "tomato": Color("ff5252"),
        "eggplant": Color("eceff1"), "broccoli": Color("9ccc65"),
        "corn": Color("ffe082"), "pepper": Color("aedd83"),
}

# ---------------------------------------------------------------- state
var _phase := "orient"
var orient := "vertical"
var items: Array = []
var halves: Array = []
var drops: Array = []
var splats: Array = []             # the juice stains on the wood
var sparks: Array = []             # bomb sparks
var smokes: Array = []             # bomb smoke puffs
var rings: Array = []              # shockwave rings
var floats: Array = []             # the +1 / -2 floaters
var glints: Array = []             # the blade glint sprites
var hearts := START_HEARTS
var clock := 0.0
var spawn_clock := 0.9
var coin_clock := COIN_EVERY_S
var mode_id := "fruits"
var slashed_total := 0
var missed_total := 0

# the loss window (kept for the sfx throttle only - each fall shows its
# own -2 floater now)
var loss_acc := 0
var loss_flush := 0.0

# scene
var world: Node2D
var bg_sprite: Sprite2D
var splat_painter: Node2D
var trail_painter: Node2D
var fx_painter: Node2D
var hearts_row: HBoxContainer
var heart_icons: Array = []
var trail: Array = []
var _shake := 0.0
var _time := 0.0
var _texs := {}
var _half_a := {}                  # fruit -> Texture2D (half 1)
var _half_b := {}
var _bomb_tex: Texture2D
var _coin_tex: Texture2D
var _heart_tex: Texture2D
var _flash_tex: Texture2D
var _smoke_tex: Texture2D
var _rng := RandomNumberGenerator.new()
var _miss_sfx_clock := 0.0
var _over := false
var _red_pulse: ColorRect

# ============================================================ setup / flow

func _goga_setup() -> void:
        _rng.randomize()
        tk.dragged.connect(_on_drag)
        _load_textures()
        var forced := start_orientation
        if forced != "":
                orient = forced
                _build_world()
                _show_options()
        else:
                _build_world()
                _show_orient_select()

func _load_textures() -> void:
        for k in FRUITS:
                _texs[k] = load("res://assets/games/slasher/classic/c_%s.png" % k)
                _half_a[k] = load("res://assets/games/slasher/classic/c_%s_h1.png" % k)
                _half_b[k] = load("res://assets/games/slasher/classic/c_%s_h2.png" % k)
        for k in VEGGIES:
                _texs[k] = load("res://assets/games/slasher/v_%s.png" % k)
                _half_a[k] = null                      # the painted stand-ins slice via the generic wedge
                _half_b[k] = null
        _bomb_tex = load("res://assets/games/slasher/classic/c_bomb.png")
        _coin_tex = load("res://assets/ui/coin.png")
        _heart_tex = load("res://assets/ui/heart.png")
        _flash_tex = load("res://assets/games/slasher/classic/c_flash.png")
        _smoke_tex = load("res://assets/games/slasher/classic/c_smoke.png")

func _auto_landscape() -> bool:
        var vp := get_viewport_rect().size
        return vp.x > vp.y

func orientation_settled() -> void:
        if _phase == "orient":
                orient = "horizontal" if _auto_landscape() else "vertical"
                _build_world()
                _show_options()

func _orient_choice(choice: String) -> void:
        Jukebox.sfx("confirm", -4.0)
        Box.set_progress(game_id, "orient_pref", choice)
        if choice == ("horizontal" if _auto_landscape() else "vertical"):
                orient = choice
                _show_options()
        else:
                request_orientation_reload.emit(choice)

func _clear_overlay() -> void:
        for n in _overlay_root_ref().get_children():
                n.queue_free()

func _dim_layer() -> ColorRect:
        var dim := ColorRect.new()
        dim.color = Color(0.03, 0.02, 0.01, 0.62)
        dim.set_anchors_preset(Control.PRESET_FULL_RECT)
        dim.mouse_filter = Control.MOUSE_FILTER_STOP
        _overlay_root_ref().add_child(dim)
        return dim

func _center_in(dim: Control) -> CenterContainer:
        var cc := CenterContainer.new()
        cc.set_anchors_preset(Control.PRESET_FULL_RECT)
        cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        dim.add_child(cc)
        return cc

func _phone_card(kind: String, selected: bool) -> Button:
        var b := Button.new()
        b.custom_minimum_size = Vector2(250, 300)
        var sb := Arc.panel_style(Arc.ACCENT if selected else Arc.CARD, 22, 12)
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
        var ic := TextureRect.new()
        ic.texture = load("res://assets/ui/phone_%s.png" % kind)
        ic.custom_minimum_size = Vector2(190, 190)
        ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.add_child(ic)
        var l := Arc.label(("VERTICAL" if kind == "vertical" \
                        else "HORIZONTAL"), 17,
                        Arc.INK if not selected else Color(0.16, 0.10, 0.05))
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.add_child(l)
        return b

## Screen 1: JUST the two cards (the owner: "there is more text that
## describe stuff, just let vertical and horizontal")
func _show_orient_select() -> void:
        _phase = "orient"
        _clear_overlay()
        var dim := _dim_layer()
        var cc := _center_in(dim)
        var panel := PanelContainer.new()
        panel.add_theme_stylebox_override("panel",
                        Arc.panel_style(Color(1, 1, 1, 0.96), 26, 24))
        cc.add_child(panel)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 18)
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        panel.add_child(row)
        var cur := "horizontal" if _auto_landscape() else "vertical"
        for choice in ["vertical", "horizontal"]:
                var card := _phone_card(choice, choice == cur)
                card.pressed.connect(func(): _orient_choice(choice))
                row.add_child(card)

## Screen 2: the produce toggle (vegetables need buying) + START
func _show_options() -> void:
        _phase = "options"
        _clear_overlay()
        var dim := _dim_layer()
        var cc := _center_in(dim)
        var panel := PanelContainer.new()
        panel.add_theme_stylebox_override("panel",
                        Arc.panel_style(Color(1, 1, 1, 0.97), 26, 24))
        cc.add_child(panel)
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 14)
        panel.add_child(box)
        var title := Arc.label("FRUIT SLASHER", 40, Arc.INK)
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(title)
        var owned := Box.item_owned(game_id, "produce", "veggies") \
                        or int(Box.dev_cheat("all_owned")) > 0
        mode_id = Box.item_on(game_id, "produce")
        if mode_id != "veggies":
                mode_id = "fruits"
        if owned:
                var row := HBoxContainer.new()
                row.add_theme_constant_override("separation", 10)
                row.alignment = BoxContainer.ALIGNMENT_CENTER
                box.add_child(row)
                row.add_child(Arc.button("FRUITS", Vector2(200, 70), 22,
                                Arc.GOOD if mode_id == "fruits" else Arc.CARD,
                                func():
                                        mode_id = "fruits"
                                        Box.equip_item(game_id, "produce", "fruits")
                                        Jukebox.sfx("confirm", -4.0)
                                        _show_options()))
                row.add_child(Arc.button("VEGETABLES", Vector2(240, 70), 22,
                                Arc.GOOD if mode_id == "veggies" else Arc.CARD,
                                func():
                                        mode_id = "veggies"
                                        Box.equip_item(game_id, "produce", "veggies")
                                        Jukebox.sfx("confirm", -4.0)
                                        _show_options()))
        else:
                var desc := Arc.fit_label("the vegetable basket is a shop "
                                + "item - one purchase, yours forever", 18,
                                Arc.HOT, 520)
                desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                box.add_child(desc)
                var buy := Arc.coin_button("BUY THE VEGETABLES  %d" % VEG_PRICE,
                                Vector2(520, 74), 22, Color("4a5ab8"), func():
                                        if Box.buy_item(game_id, "produce",
                                                        "veggies", VEG_PRICE):
                                                Jukebox.sfx("buy")
                                                mode_id = "veggies"
                                                Box.equip_item(game_id,
                                                        "produce", "veggies")
                                        _show_options())
                if Box.coins() < VEG_PRICE and not int(Box.dev_cheat("all_owned")) > 0:
                        buy.disabled = true
                var bc := HBoxContainer.new()
                bc.alignment = BoxContainer.ALIGNMENT_CENTER
                bc.add_child(buy)
                box.add_child(bc)
        var start := Arc.button("START", Vector2(520, 88), 30, Arc.GOOD,
                        func(): _start_run())
        var sc := HBoxContainer.new()
        sc.alignment = BoxContainer.ALIGNMENT_CENTER
        sc.add_child(start)
        box.add_child(sc)

func _start_run() -> void:
        Jukebox.sfx("confirm", -4.0)
        _clear_overlay()
        _phase = "run"
        _build_hearts()
        spawn_clock = 0.7
        coin_clock = COIN_EVERY_S
        Jukebox.sfx("sl_launch", -8.0)

# ============================================================ the world

func _build_world() -> void:
        if world != null and is_instance_valid(world):
                world.queue_free()
        world = Node2D.new()
        add_child(world)
        # THE WOOD BOARD (the owner: "the game fruit ninja background was
        # look like a wood")
        bg_sprite = Sprite2D.new()
        bg_sprite.texture = load("res://assets/games/slasher/wood_%s.png"
                        % ("landscape" if orient == "horizontal" else "portrait"))
        var vp := get_viewport_rect().size
        bg_sprite.position = vp / 2.0
        # COVER the viewport whatever the logical size is (the density rule
        # makes it vary) - a slight wood stretch is invisible
        var tw := float(bg_sprite.texture.get_width())
        var th := float(bg_sprite.texture.get_height())
        bg_sprite.scale = Vector2(vp.x / tw, vp.y / th)
        bg_sprite.z_index = -12
        world.add_child(bg_sprite)
        # the tiny sparkles (the owner: "small cool things") + the juice
        # splats live on one painter just above the wood
        splat_painter = Node2D.new()
        splat_painter.z_index = -8
        splat_painter.draw.connect(_paint_splats)
        world.add_child(splat_painter)
        trail_painter = Node2D.new()
        trail_painter.z_index = 30
        trail_painter.draw.connect(_paint_trail)
        world.add_child(trail_painter)
        fx_painter = Node2D.new()
        fx_painter.z_index = 34
        fx_painter.draw.connect(_paint_fx)
        world.add_child(fx_painter)
        # the red bomb pulse (ONE per game - rebuilds must not stack it)
        if _red_pulse == null or not is_instance_valid(_red_pulse):
                _red_pulse = ColorRect.new()
                _red_pulse.color = Color(0.8, 0.1, 0.05, 0.0)
                _red_pulse.set_anchors_preset(Control.PRESET_FULL_RECT)
                _red_pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
                _hud.add_child(_red_pulse)

func _build_hearts() -> void:
        hearts_row = HBoxContainer.new()
        hearts_row.set_anchors_preset(Control.PRESET_TOP_WIDE)
        hearts_row.offset_left = 14
        hearts_row.offset_top = 86
        hearts_row.offset_right = -14
        hearts_row.add_theme_constant_override("separation", 6)
        _hud.add_child(hearts_row)
        for i in START_HEARTS:
                var h := TextureRect.new()
                h.texture = _heart_tex
                h.custom_minimum_size = Vector2(40, 40)
                h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                h.mouse_filter = Control.MOUSE_FILTER_IGNORE
                hearts_row.add_child(h)
                heart_icons.append(h)
        _refresh_hearts()

func _refresh_hearts() -> void:
        for i in heart_icons.size():
                var h: TextureRect = heart_icons[i]
                h.modulate = Color(0.95, 0.2, 0.25) if i < hearts \
                                else Color(0.16, 0.12, 0.12, 0.6)

# ============================================================ painters

func _paint_splats() -> void:
        # the juice stains stuck to the wood, fading slowly
        for s in splats:
                var t: float = clampf(float(s["life"]) / float(s["max"]), 0.0, 1.0)
                var col: Color = s["col"]
                col.a = 0.55 * t
                for blob in s["blobs"]:
                        var off: Vector2 = blob["off"]
                        var rr: float = float(blob["r"])
                        splat_painter.draw_circle(off, rr, col)
        # the tiny sparkles (4, slow, subtle)
        var vp := get_viewport_rect().size
        for i in 4:
                var ph := _time * (0.5 + 0.13 * i) + float(i) * 1.9
                var tw := 0.5 - 0.5 * cos(ph)
                if tw < 0.25:
                        continue
                var px := vp.x * (0.2 + 0.22 * i)
                var py := vp.y * (0.16 + 0.19 * ((i * 7) % 4)) + sin(ph) * 8.0
                splat_painter.draw_circle(Vector2(px, py), 2.2 + tw * 1.6,
                                Color(1, 1, 0.9, 0.30 * tw))

func _paint_trail() -> void:
        # the blade ribbon
        if trail.size() >= 2:
                for pass_i in 2:
                        var w := 26.0 if pass_i == 0 else 9.0
                        var col := Color(1.0, 0.95, 0.8, 0.28) if pass_i == 0 \
                                        else Color(1, 1, 1, 0.92)
                        for i in range(1, trail.size()):
                                var p0: Dictionary = trail[i - 1]
                                var p1: Dictionary = trail[i]
                                var f0: float = clampf(1.0 - float(p0["age"]) / 0.30, 0.0, 1.0)
                                var f1: float = clampf(1.0 - float(p1["age"]) / 0.30, 0.0, 1.0)
                                var a: Vector2 = p0["pos"]
                                var b: Vector2 = p1["pos"]
                                var dir := (b - a).normalized()
                                if dir == Vector2.ZERO:
                                        continue
                                var perp := Vector2(-dir.y, dir.x)
                                var quad := PackedVector2Array([
                                                a + perp * w * 0.5 * f0,
                                                b + perp * w * 0.5 * f1,
                                                b - perp * w * 0.5 * f1,
                                                a - perp * w * 0.5 * f0])
                                var cc := col
                                cc.a *= minf(f0, f1)
                                trail_painter.draw_polygon(quad,
                                                PackedColorArray([cc, cc, cc, cc]))
        # the +1 / -2 floaters (one per event, right where it happened)
        var font := ThemeDB.fallback_font
        for f in floats:
                var t: float = clampf(float(f["life"]) / float(f["max"]), 0.0, 1.0)
                var c: Color = f["col"]
                c.a = minf(1.0, t * 1.7)
                var fs := int(float(f["size"]))
                trail_painter.draw_string_outline(font, Vector2(float(f["x"]) - 120.0,
                                float(f["y"])), String(f["txt"]),
                                HORIZONTAL_ALIGNMENT_CENTER, 240, fs, 5,
                                Color(0, 0, 0, c.a * 0.75))
                trail_painter.draw_string(font, Vector2(float(f["x"]) - 120.0,
                                float(f["y"])), String(f["txt"]),
                                HORIZONTAL_ALIGNMENT_CENTER, 240, fs, c)

func _paint_fx() -> void:
        # the bomb rings
        for r in rings:
                var t: float = 1.0 - clampf(float(r["life"]) / float(r["max"]), 0.0, 1.0)
                var rr: float = float(r["r0"]) + (float(r["r1"]) - float(r["r0"])) * t
                var c: Color = r["col"]
                c.a = (1.0 - t) * 0.8
                fx_painter.draw_arc(Vector2(float(r["x"]), float(r["y"])), rr,
                                0.0, TAU, 34, c, 6.0 * (1.0 - t) + 1.5)
        # the bomb sparks (fast bright dashes)
        for s in sparks:
                var t: float = clampf(float(s["life"]) / float(s["max"]), 0.0, 1.0)
                var p: Vector2 = s["pos"]
                var v: Vector2 = s["v"]
                var c := Color(1.0, 0.85, 0.3)
                c.a = t
                fx_painter.draw_line(p, p - v * 0.05, c, 3.0 * t + 0.5)

# ============================================================ the spawn

func _item_kind() -> String:
        var pool: Array = FRUITS if mode_id == "fruits" else VEGGIES
        return String(pool[_rng.randi() % pool.size()])

func _item_scale(kind: String, tex: Texture2D) -> float:
        # the drawn size wants ~118px for fruits, ~108 for the bomb
        if kind == "coin":
                return 84.0 / float(tex.get_width())
        if kind == "bomb":
                return 106.0 / float(tex.get_width())
        # v0.3.1: the vegs were "weirdly too small compared to the
        # correct size of the fruit" - their painted art sits smaller in
        # its canvas, so the target grows past the fruit's
        var target := 122.0 if mode_id == "fruits" else 150.0
        return target / float(tex.get_width())

func _launch(kind: String, at: Vector2 = Vector2.INF,
                speed := 1.0) -> void:
        var vp := get_viewport_rect().size
        var m: Dictionary = MODES[orient]
        var s := Sprite2D.new()
        var tex: Texture2D = _bomb_tex if kind == "bomb" \
                        else (_coin_tex if kind == "coin" else _texs[kind])
        s.texture = tex
        var pos := at
        var v := Vector2.ZERO
        if bool(m["from_bottom"]):
                if pos == Vector2.INF:
                        var spread := 0.36
                        if m.has("center_spread"):
                                # the landscape law: around the CENTER
                                spread = float(m["center_spread"])
                        pos = Vector2(vp.x * 0.5
                                        + _rng.randf_range(-spread, spread) * vp.x,
                                        vp.y + 70.0)
                v = Vector2(_rng.randf_range(m["vx"][0], m["vx"][1]),
                                _rng.randf_range(m["vy"][0], m["vy"][1]) * speed)
        else:
                if pos == Vector2.INF:
                        pos = Vector2(-70.0, _rng.randf_range(vp.y * 0.16,
                                        vp.y * 0.74))
                v = Vector2(_rng.randf_range(m["vx"][0], m["vx"][1]) * speed,
                                _rng.randf_range(m["vy"][0], m["vy"][1]))
        s.position = pos
        var sc := _item_scale(kind, tex)
        s.scale = Vector2.ONE * sc
        s.rotation = _rng.randf_range(0.0, TAU)
        world.add_child(s)
        items.append({
                "node": s, "kind": kind, "v": v,
                "spin": _rng.randf_range(m["spin"][0], m["spin"][1]),
                "sliced": false, "scale": sc, "g": float(m["gravity"]),
        })

func _spawn_pattern() -> void:
        var speed := 0.92 + minf(0.5, clock / 90.0) + _rng.randf_range(-0.12, 0.16)
        if _rng.randf() < 0.08:
                speed *= 1.28
        var roll := _rng.randf()
        if roll < 0.38:
                _launch(_roll_kind(0.12), Vector2.INF, speed)
        elif roll < 0.62:
                _launch(_roll_kind(0.12), Vector2.INF, speed)
                _launch(_roll_kind(0.12), Vector2.INF, speed * 0.94)
        elif roll < 0.78:
                var vp := get_viewport_rect().size
                var m: Dictionary = MODES[orient]
                var spread := float(m.get("center_spread", 0.36))
                var at := Vector2(vp.x * 0.5 + _rng.randf_range(-spread, spread)
                                * vp.x * 0.6, vp.y + 60.0)
                for i in 3:
                        _launch(_roll_kind(0.0), at, speed * (1.0 - 0.09 * i))
        else:
                var vp := get_viewport_rect().size
                var m: Dictionary = MODES[orient]
                var n := 5
                var bomb_i := _rng.randi() % n
                if bool(m["from_bottom"]):
                        var base_x := _rng.randf_range(vp.x * 0.2, vp.x * 0.8)
                        var base_vy := _rng.randf_range(m["vy"][0], m["vy"][1]) * 0.9
                        var base_vx := _rng.randf_range(-90.0, 90.0)
                        for i in n:
                                var kind := _roll_kind(0.0)
                                if i == bomb_i:
                                        kind = "bomb"
                                var at := Vector2(base_x + (i - n / 2.0)
                                                * (vp.x * 0.11), vp.y + 60.0)
                                _launch_at(kind, at, Vector2(base_vx,
                                                base_vy * _rng.randf_range(0.92, 1.08)))
                else:
                        # v0.3.1: the landscape row = a WIDE row from the
                        # bottom center (the old left curtain is dead)
                        var base_x := _rng.randf_range(vp.x * 0.3, vp.x * 0.7)
                        var base_vy := _rng.randf_range(m["vy"][0], m["vy"][1]) * 0.92
                        var base_vx := _rng.randf_range(m["vx"][0], m["vx"][1])
                        for i in n:
                                var kind := _roll_kind(0.0)
                                if i == bomb_i:
                                        kind = "bomb"
                                var at := Vector2(base_x + (i - n / 2.0)
                                                * (vp.x * 0.12), vp.y + 60.0)
                                _launch_at(kind, at, Vector2(
                                                base_vx * _rng.randf_range(0.9, 1.1),
                                                base_vy * _rng.randf_range(0.92, 1.08)))
        Jukebox.sfx("sl_launch", -14.0, _rng.randf_range(0.9, 1.15))

func _launch_at(kind: String, at: Vector2, v: Vector2) -> void:
        var m: Dictionary = MODES[orient]
        var s := Sprite2D.new()
        s.texture = _bomb_tex if kind == "bomb" else _texs[kind]
        s.position = at
        var sc := _item_scale(kind, s.texture)
        s.scale = Vector2.ONE * sc
        s.rotation = _rng.randf_range(0.0, TAU)
        world.add_child(s)
        items.append({"node": s, "kind": kind, "v": v,
                "spin": _rng.randf_range(m["spin"][0], m["spin"][1]),
                "sliced": false, "scale": sc, "g": float(m["gravity"])})

func _roll_kind(bomb_chance: float) -> String:
        if _rng.randf() < bomb_chance:
                return "bomb"
        return _item_kind()

# ============================================================ the tick

func _goga_tick(delta: float) -> void:
        _time += delta
        if _phase != "run":
                splat_painter.queue_redraw()
                return
        clock += delta
        spawn_clock -= delta
        if spawn_clock <= 0.0:
                spawn_clock = maxf(0.78, 1.4 - clock * 0.009)
                _spawn_pattern()
        coin_clock -= delta
        if coin_clock <= 0.0:
                coin_clock = COIN_EVERY_S
                _launch("coin")
        var vp := get_viewport_rect().size
        for p in items.duplicate():
                var n: Sprite2D = p["node"]
                if not is_instance_valid(n):
                        items.erase(p)
                        continue
                var v: Vector2 = p["v"]
                v.y += float(p["g"]) * delta
                p["v"] = v
                n.position += v * delta
                n.rotation += float(p["spin"]) * delta
                if n.position.y > vp.y + 110.0 or n.position.x > vp.x + 130.0:
                        items.erase(p)
                        if String(p["kind"]) != "bomb" \
                                        and String(p["kind"]) != "coin" \
                                        and not bool(p["sliced"]):
                                _register_miss(n.position)
                        n.queue_free()
        for h in halves.duplicate():
                var n: Node2D = h["node"]
                if not is_instance_valid(n):
                        halves.erase(h)
                        continue
                var v: Vector2 = h["v"]
                v.y += 1420.0 * delta
                h["v"] = v
                n.position += v * delta
                n.rotation += float(h["spin"]) * delta
                h["life"] = float(h["life"]) - delta
                if float(h["life"]) <= 0.0 or n.position.y > vp.y + 140.0:
                        halves.erase(h)
                        n.queue_free()
                elif float(h["life"]) < float(h["max"]) * 0.3:
                        n.modulate.a = float(h["life"]) / (float(h["max"]) * 0.3)
        for d in drops.duplicate():
                var n: Node = d["node"]
                if not is_instance_valid(n):
                        drops.erase(d)
                        continue
                var v: Vector2 = d["v"]
                v.y += 1250.0 * delta
                d["v"] = v
                n.position += v * delta
                d["life"] = float(d["life"]) - delta
                n.modulate.a = clampf(float(d["life"]) / float(d["max"]), 0.0, 1.0) * float(d.get("a0", 1.0))
                if float(d["life"]) <= 0.0:
                        drops.erase(d)
                        n.queue_free()
        for s in splats.duplicate():
                s["life"] = float(s["life"]) - delta
                if float(s["life"]) <= 0.0:
                        splats.erase(s)
        for s in sparks.duplicate():
                var pv: Vector2 = s["pos"]
                s["pos"] = pv + Vector2(s["v"]) * delta
                s["v"] = Vector2(s["v"]) + Vector2(0, 900) * delta
                s["life"] = float(s["life"]) - delta
                if float(s["life"]) <= 0.0:
                        sparks.erase(s)
        for s in smokes.duplicate():
                var n: Sprite2D = s["node"]
                s["life"] = float(s["life"]) - delta
                n.position += Vector2(s["v"]) * delta
                var t := 1.0 - clampf(float(s["life"]) / float(s["max"]), 0.0, 1.0)
                n.scale = Vector2.ONE * (float(s["s0"]) + t * float(s["s1"]))
                n.modulate.a = (1.0 - t) * 0.5
                if float(s["life"]) <= 0.0:
                        smokes.erase(s)
                        n.queue_free()
        for r in rings.duplicate():
                r["life"] = float(r["life"]) - delta
                if float(r["life"]) <= 0.0:
                        rings.erase(r)
        for f in floats.duplicate():
                f["life"] = float(f["life"]) - delta
                f["y"] = float(f["y"]) - 46.0 * delta
                if float(f["life"]) <= 0.0:
                        floats.erase(f)
        for g in glints.duplicate():
                g["life"] = float(g["life"]) - delta
                var gn: Sprite2D = g["node"]
                gn.modulate.a = clampf(float(g["life"]) / float(g["max"]), 0.0, 1.0)
                if float(g["life"]) <= 0.0:
                        glints.erase(g)
                        gn.queue_free()
        for t in trail:
                t["age"] = float(t["age"]) + delta
        while trail.size() > 0 and float(trail[0]["age"]) > 0.30:
                trail.pop_front()
        if loss_acc > 0:
                loss_flush -= delta
                if loss_flush <= 0.0:
                        _flush_loss()
        if _shake > 0.0:
                _shake = maxf(0.0, _shake - delta * 2.6)
                world.position = Vector2(_rng.randf_range(-1, 1),
                                _rng.randf_range(-1, 1)) * 15.0 * _shake
                if _shake == 0.0:
                        world.position = Vector2.ZERO
        _miss_sfx_clock = maxf(0.0, _miss_sfx_clock - delta)
        splat_painter.queue_redraw()
        trail_painter.queue_redraw()
        fx_painter.queue_redraw()

# ============================================================ the input

func _on_drag(from: Vector2, to: Vector2) -> void:
        if _phase != "run" or _over:
                return
        trail.append({"pos": to, "age": 0.0})
        if trail.size() > 26:
                trail.pop_front()
        var seg := to - from
        # v0.3.2 PATCH: TouchKit now emits the TRUE polyline segments
        # (prev sample -> this one, never anchor chords), so this floor is
        # 2px - a slow finger's per-frame steps must still cut. The old
        # 14px floor only made sense against the long anchor chords that
        # caused the owner's loop-around bug.
        if seg.length() < 2.0:
                return
        # v0.3.1 PATCH III - THE SHAPE LAW: the old code cut anything in a
        # ~200px swath around the swipe (a drawn CIRCLE around a fruit
        # clipped it - the owner's bug). Now every object owns its real
        # shape and the slash must CROSS it. Bombs are the exception: a
        # graze on their side detonates, no pass-through needed.
        for p in items.duplicate():
                var n: Sprite2D = p["node"]
                if bool(p["sliced"]):
                        continue
                var shp: Dictionary = _shape_of(p)
                if String(p["kind"]) == "bomb":
                        if _point_segment_dist(n.position, from, to) \
                                        < float(shp["r"]) + 14.0:
                                _cut_item(p, from, to)
                        continue
                if String(shp["type"]) == "capsule":
                        var axis: Vector2 = Vector2(0, -1).rotated(n.rotation) \
                                        * float(shp["half"])
                        if _seg_seg_dist(from, to, n.position + axis,
                                        n.position - axis) <= float(shp["r"]):
                                _cut_item(p, from, to)
                elif _seg_circle_hit(from, to, n.position, float(shp["r"])):
                        _cut_item(p, from, to)

## the item's own collision shape, sized from the DRAWN pixels (the blade
## ribbon is ~26px wide - the hit zone is the body, never a 200px swath)
func _shape_of(p: Dictionary) -> Dictionary:
        var shp: Dictionary = p.get("shape", {})
        if not shp.is_empty():
                return shp
        var n: Sprite2D = p["node"]
        var sc: float = float(p["scale"])
        var dw := float(n.texture.get_width()) * sc
        var dh := float(n.texture.get_height()) * sc
        if ELONG.has(String(p["kind"])):
                shp = {"type": "capsule", "half": dh * 0.34, "r": dw * 0.30}
        else:
                shp = {"type": "circle", "r": dw * 0.42}
        p["shape"] = shp
        return shp

## true when the segment REALLY crosses the disc (the owner: "the slash
## should only slash when the slash visual line really collides with the
## thing from side to side") - a line beside the disc, or a loop AROUND
## it that never enters, is not a cut
func _seg_circle_hit(a: Vector2, b: Vector2, c: Vector2, r: float) -> bool:
        return _point_segment_dist(c, a, b) < r

## the shortest distance between two segments (capsule vs slash line)
func _seg_seg_dist(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2) -> float:
        if _segs_cross(p1, p2, p3, p4):
                return 0.0
        return minf(_point_segment_dist(p1, p3, p4), \
                minf(_point_segment_dist(p2, p3, p4), \
                minf(_point_segment_dist(p3, p1, p2), _point_segment_dist(p4, p1, p2))))

func _segs_cross(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2) -> bool:
        var d1 := _cross(p3, p4, p1)
        var d2 := _cross(p3, p4, p2)
        var d3 := _cross(p1, p2, p3)
        var d4 := _cross(p1, p2, p4)
        return ((d1 > 0.0) != (d2 > 0.0)) and ((d3 > 0.0) != (d4 > 0.0))

func _cross(a: Vector2, b: Vector2, p: Vector2) -> float:
        return (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x)

# v0.3.1: no more glint sprite (the owner: "we do not need it
# since we have our own finger-slasher thing") - the blade ribbon
# IS the effect. v0.3.1 PATCH II: the swipe sound is GONE entirely
# (the owner: "remove the slash sound completely, the rest of the
# SFXs are good") - slicing is a SILENT act now; the cuts, bombs
# and combos keep their voices.

# ============================================================ the cut

## THE REAL SLICE (v0.3.0): the fruit is replaced by its TWO REAL HALVES
## (the classic art ships them pre-cut), aligned so the flat faces sit on
## YOUR cut line, thrown apart along the cut normal with opposite flips.
func _cut_item(p: Dictionary, from: Vector2, to: Vector2) -> void:
        items.erase(p)
        var n: Sprite2D = p["node"]
        var kind := String(p["kind"])
        var sc: float = float(p["scale"])
        var juice: Color = JUICE.get(kind, Color("ffc93c"))
        var cut_dir := (to - from).normalized()
        if cut_dir == Vector2.ZERO:
                cut_dir = Vector2(1, 0)
        var nv := Vector2(-cut_dir.y, cut_dir.x)
        if kind == "coin":
                _coin_slashed(n.position)
                n.queue_free()
                return
        if kind == "bomb":
                _bomb_slashed(n.position)
                n.queue_free()
                return
        add_score(1)
        slashed_total += 1
        achievement_count("slashed", 1)
        var cut_names := ["sl_cut_a", "sl_cut_b", "sl_cut_c"]
        Jukebox.sfx(cut_names[_rng.randi() % 3], -4.0,
                _rng.randf_range(0.9, 1.18))
        # THE +1 (the owner: "just make it +1 next to the cut")
        _push_float("+1", n.position + Vector2(0, -34.0),
                        Color(0.55, 1.0, 0.6), 34.0)
        # THE HALVES: the art's cut is vertical, so rotate the pair so that
        # vertical maps to the slash direction
        var base_rot := n.rotation + cut_dir.angle() - PI / 2.0
        var v: Vector2 = p["v"]
        if _half_a.get(kind) != null:
                for i in 2:
                        var tex: Texture2D = _half_a[kind] if i == 0 else _half_b[kind]
                        var half := Sprite2D.new()
                        half.texture = tex
                        half.position = n.position
                        half.rotation = base_rot
                        half.scale = Vector2.ONE * sc
                        world.add_child(half)
                        var side := 1.0 if i == 0 else -1.0
                        halves.append({
                                "node": half,
                                "v": v * 0.72 + nv * (SLICE_HALF_V * side)
                                                + Vector2(_rng.randf_range(-30, 30), -70.0),
                                "spin": side * _rng.randf_range(2.5, 6.5),
                                "life": 1.15, "max": 1.15,
                        })
        else:
                # the painted stand-ins (vegetables): the generic wedge cut
                for i in 2:
                        var tex: Texture2D = n.texture
                        var half := Sprite2D.new()
                        half.texture = tex
                        half.position = n.position
                        half.rotation = n.rotation
                        half.scale = Vector2.ONE * sc * Vector2(0.5, 1.0)
                        half.position += nv * (10.0 * (1 if i == 0 else -1))
                        world.add_child(half)
                        var side := 1.0 if i == 0 else -1.0
                        halves.append({
                                "node": half,
                                "v": v * 0.72 + nv * (SLICE_HALF_V * side),
                                "spin": side * _rng.randf_range(2.5, 6.5),
                                "life": 1.15, "max": 1.15,
                        })
        # THE JUICE: droplets thrown against the cut + a splat on the wood
        _splash(n.position, juice, cut_dir)
        _add_splat(n.position, juice)
        n.queue_free()

func _coin_slashed(at: Vector2) -> void:
        add_run_coins(1)
        Jukebox.sfx("sl_coin_s", -3.0)
        _splash(at, Color("ffd24a"), Vector2.UP, 10)
        _push_float("+COIN", at + Vector2(0, -34.0), Color("ffd24a"), 30.0)

func _bomb_slashed(at: Vector2) -> void:
        ## THE REAL EXPLOSION: flash, shockwave, smoke, sparks, shake
        hearts -= 1
        _refresh_hearts()
        _shake = 1.5
        Jukebox.sfx("sl_bomb", -1.0)
        # the flash (a quick white-orange burst)
        rings.append({"x": at.x, "y": at.y, "r0": 8.0, "r1": 130.0,
                "life": 0.18, "max": 0.18, "col": Color(1.0, 0.95, 0.7)})
        # the shockwave
        rings.append({"x": at.x, "y": at.y, "r0": 20.0, "r1": 230.0,
                "life": 0.42, "max": 0.42, "col": Color(1.0, 0.6, 0.2)})
        # the smoke puffs
        for i in 10:
            var sm := Sprite2D.new()
            sm.texture = _smoke_tex
            sm.position = at + Vector2(_rng.randf_range(-26, 26),
                            _rng.randf_range(-26, 26))
            sm.rotation = _rng.randf_range(0.0, TAU)
            sm.z_index = 33
            world.add_child(sm)
            smokes.append({"node": sm, "v": Vector2(_rng.randf_range(-60, 60),
                            _rng.randf_range(-90, -10)),
                    "life": _rng.randf_range(0.5, 1.0), "max": 1.0,
                    "s0": 0.6, "s1": 2.0})
        # the sparks
        for i in 12:
            var ang := TAU * float(i) / 12.0 + _rng.randf_range(-0.2, 0.2)
            sparks.append({"pos": at, "v": Vector2(cos(ang), sin(ang))
                    * _rng.randf_range(260.0, 520.0),
                    "life": _rng.randf_range(0.24, 0.4), "max": 0.4})
        # the red pulse
        _red_pulse.color = Color(0.8, 0.1, 0.05, 0.28)
        var tw := create_tween()
        tw.tween_property(_red_pulse, "color:a", 0.0, 0.5)
        if hearts <= 0:
                _run_over()
        else:
                Jukebox.sfx("sl_heart", -4.0)
        _push_float("-1 HEART", at + Vector2(0, -40.0), Color(1, 0.5, 0.4), 30.0)

func _run_over() -> void:
        if _over:
                return
        _over = true
        _phase = "over"
        Jukebox.sfx("sl_over", -2.0)
        achievement_max("hearts_kept", hearts)
        achievement_max("max_score", score)
        check_achievements()
        var tw := create_tween()
        tw.tween_property(world, "modulate", Color(0.75, 0.55, 0.5), 0.4)
        tw.tween_interval(0.5)
        tw.tween_callback(func(): finish_run(score))

# ============================================================ the juice

func _splash(at: Vector2, col: Color, dir: Vector2, n := 14) -> void:
        ## the droplets: bigger, stretched along their motion, gravity-fed
        for i in n:
                var d := ColorRect.new()
                var sz := _rng.randf_range(7.0, 15.0)
                d.color = col
                d.size = Vector2(sz, sz * _rng.randf_range(1.25, 1.9))
                d.position = at + Vector2(_rng.randf_range(-12, 12),
                                _rng.randf_range(-12, 12))
                d.rotation = _rng.randf_range(0.0, TAU)
                d.z_index = 20
                d.mouse_filter = Control.MOUSE_FILTER_IGNORE
                world.add_child(d)
                var v := dir * _rng.randf_range(90.0, 300.0) \
                                + Vector2(_rng.randf_range(-190, 190),
                                _rng.randf_range(-300, 20))
                drops.append({"node": d, "v": v,
                                "life": _rng.randf_range(0.45, 0.85),
                                "max": 0.85, "a0": 0.95})
        if drops.size() > 240:
                drops = drops.slice(drops.size() - 240)

func _add_splat(at: Vector2, col: Color) -> void:
        ## the stain: 7-10 merged blobs + two drips, stuck to the wood
        var blobs := []
        var n := 7 + _rng.randi() % 4
        for i in n:
                var ang := TAU * float(i) / float(n) + _rng.randf_range(-0.3, 0.3)
                var dist := _rng.randf_range(6.0, 44.0)
                blobs.append({"off": Vector2(cos(ang), sin(ang)) * dist,
                                "r": _rng.randf_range(7.0, 20.0)})
        blobs.append({"off": Vector2.ZERO, "r": _rng.randf_range(14.0, 22.0)})
        blobs.append({"off": Vector2(_rng.randf_range(-8, 8), 34.0),
                        "r": _rng.randf_range(4.0, 7.0)})     # the drip
        splats.append({"x": at.x, "y": at.y, "blobs": blobs, "col": col,
                "life": 2.4, "max": 2.4})
        if splats.size() > 26:
                splats = splats.slice(splats.size() - 26)

func _push_float(txt: String, at: Vector2, col: Color, fsize: float) -> void:
        ## one floater per event (the owner: "+1 next to the cut and -2
        ## for each one that fails") - never merged, never zoned
        floats.append({"txt": txt, "x": at.x, "y": at.y, "col": col,
                "life": 0.65, "max": 0.65, "size": fsize})
        if floats.size() > 12:
                floats = floats.slice(floats.size() - 12)

func _register_miss(at: Vector2) -> void:
        ## a fruit fell unsliced: its own -2 right where it fell
        missed_total += 1
        if score > 0:
                set_score(maxi(0, score - MISS_COST))
        loss_acc += MISS_COST
        loss_flush = LOSS_WINDOW
        var vp := get_viewport_rect().size
        _push_float("-%d" % MISS_COST,
                        Vector2(clampf(at.x, 60.0, vp.x - 60.0), vp.y - 150.0),
                        Color(0.98, 0.42, 0.36), 32.0)
        if _miss_sfx_clock <= 0.0:
                Jukebox.sfx("sl_miss", -8.0)
                _miss_sfx_clock = 0.2

func _flush_loss() -> void:
        loss_acc = 0
        loss_flush = 0.0

# ============================================================ misc

## v0.3.1 PATCH II: the dynamic swipe voice block was REMOVED by owner law
## ("remove the slash sound completely"). The four sl_whoosh_* cuts and
## this function are gone from the game - silence IS the slash.

func _point_segment_dist(pt: Vector2, a: Vector2, b: Vector2) -> float:
        var ab := b - a
        var t := clampf((pt - a).dot(ab) / maxf(0.001, ab.length_squared()),
                        0.0, 1.0)
        return pt.distance_to(a + ab * t)
