extends GogaGame
## MARBLE POPPER (v040-13) - the zuma seat graduated (the owner's rename law).
## A vertical marble shooter: chains roll carved paths toward a living idol;
## you fire marbles, match 3+, pop runs, ride cascades - 100 levels across
## 10 places, 5+5+5 skins, shop-spawned powerups, chain GOGACoins, the lives
## ladder and the challenge waves - the owner's GDD worked into laws.
## The chain engine is data + geometry (the owner: "this game is on
## algorithms, geometrics, level-designing").

const A := "res://assets/games/marble/"
const DESIGN := Vector2(1080, 1920)          # the box portrait design space
const RESAMPLE := 6.0                        # path sample step (px)
const FIRE_CD := 0.26
const FIRE_CD_FAST := 0.11
const SHOT_SPEED := 1500.0
const SHOT_SPEED_FAST := 2900.0
const POW_FIRST_DELAY := 20.0
const POW_DELAY_LO := 26.0
const POW_DELAY_HI := 40.0

# ---------------------------------------------------------------- state
var meta: MBMeta
var level_idx := 0                 # 0-based into MarbleData.levels()
var level: Dictionary = {}
var challenge := false
var challenge_wave := 1
var phase := "boot"                # boot | intro | preview | play | cleared | lost | wiped
var run_level_score := 0
var combo := 0
var combo_t := 0.0
var rng := RandomNumberGenerator.new()

# world
var world: Node2D                  # the design-space container (rides ORIGIN)
var ORIGIN := Vector2.ZERO
var bg_spr: Sprite2D
var chains: Array = []             # of ChainPath
var marble_layer: Node2D
var shot_layer: Node2D
var fx_layer: Node2D
var holes: Array = []              # of Node2D (idol per path)
var track_draw: Node2D

# shooter
var shooter: Node2D
var shooter_head: Sprite2D
var shooter_base: Sprite2D
var next_spr: Sprite2D
var load_c := 1
var next_c := 1
var fire_cd := 0.0
var aim := Vector2(0, -1)
var shooter_home := Vector2.ZERO   # the FIXED/twin current spot
var twin_a := Vector2.ZERO
var twin_b := Vector2.ZERO
var twin_active := 0
var twin_fading := false
var slider := false
var shots: Array = []              # {pos, vel, c, spr, rainbow}

# powers (the shop-spawned law)
var owned_pows: Array = []
var pow_clock := 20.0
var speed_t := 0.0
var vapor_t := 0.0
var rainbow_n := 0
var pow_name_t := 0.0
var pow_name_lbl: Label

# the GOGACoin chain law
var waves_since_coin := 0
var coin_pending := false

# preview
var preview_t := 0.0
var preview_arrows: Array = []     # of Sprite2D

# hud
var lives_lbl: Label
var pop_lbl: Label                 # the in-level pop score (small, under the bar)
var _tex_cache: Dictionary = {}

var cleared_card: Control = null   # the cleared/lost overlay cards
var ready_ui: Control = null

@onready var _pop_frames: Array = _frames("fx/fx_pop_", 12)
@onready var _ring_frames: Array = _frames("fx/fx_ring_", 8)

# ================================================================= textures
func _t(p: String) -> Texture2D:
        if not _tex_cache.has(p):
                _tex_cache[p] = load(A + p)
        return _tex_cache[p]

func _frames(prefix: String, n: int) -> Array:
        var out: Array = []
        for i in n:
                var p := "%s%02d.png" % [prefix, i]
                if ResourceLoader.exists(A + p):
                        out.append(load(A + p))
        return out

func _marble_tex(c: int) -> Texture2D:
        if c < 0:                                   # the rainbow
                return _t("marble_rainbow.png")
        var style := _marble_style()
        var p := "marble_%d_%d.png" % [c, style]
        if not ResourceLoader.exists(A + p):
                p = "marble_%d_0.png" % c
        return _t(p)

func _marble_style() -> int:
        var on := Box.item_on(game_id, "skin_marble")
        for s in MarbleData.MARBLE_SKINS:
                if s["id"] == on:
                        return int(s["style"])
        return 0

func _player_skin() -> String:
        var on := Box.item_on(game_id, "skin_player")
        for s in MarbleData.PLAYER_SKINS:
                if s["id"] == on:
                        return String(s["id"])
        return "classic"

func _hole_skin() -> String:
        var on := Box.item_on(game_id, "skin_hole")
        for s in MarbleData.HOLE_SKINS:
                if s["id"] == on:
                        return String(s["id"])
        return "classic"

# ================================================================= setup
func _goga_setup() -> void:
        rng.randomize()
        meta = MBMeta.load_meta()
        pause_end_run = false
        set_hud_score_prefix("LEVELS")
        add_hud_button("SHOP", func(): _shop_open())
        add_hud_button("LEVELS", func(): _levels_open())
        _build_lives_chip()
        _layout()
        _build_pow_name()
        level_idx = clampi(int(meta.d["unlock"]) - 1, 0, MarbleData.LEVELS_TOTAL - 1)
        if meta.all_cleared():
                meta.complete_all()
        _goga_tk_ready()
        _build_intro()
        Jukebox.music("res://assets/audio/music/mb_music_menu.ogg")
        check_achievements()

func _layout() -> void:
        var vp := get_viewport_rect().size
        ORIGIN = Vector2((vp.x - DESIGN.x) * 0.5, (vp.y - DESIGN.y) * 0.5)

func _build_lives_chip() -> void:
        if bool(meta.d["free_play"]):
                return          # THE FREE PLAY LAW: the lives system is removed
        lives_lbl = add_hud_chip("x%d" % meta.lives(), "res://assets/ui/heart.png")

func _build_pow_name() -> void:
        # the pickup name text with the black outline (the owner's law) -
        # floats mid-screen, never a timer widget (no duration reveal)
        pow_name_lbl = Arc.label("", 52, Color(1, 1, 1))
        pow_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        pow_name_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
        pow_name_lbl.offset_top = 300
        pow_name_lbl.offset_bottom = 380
        pow_name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
        pow_name_lbl.add_theme_constant_override("outline_size", 14)
        pow_name_lbl.modulate.a = 0.0
        pow_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _hud.add_child(pow_name_lbl)

# ------------------------------------------------------------------ intro
func _build_intro() -> void:
        phase = "intro"
        ready_ui = Control.new()
        ready_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
        ready_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _overlay_root_ref().add_child(ready_ui)
        var dim := ColorRect.new()
        dim.color = Color(0.04, 0.03, 0.07, 0.55)
        dim.set_anchors_preset(Control.PRESET_FULL_RECT)
        ready_ui.add_child(dim)
        var cc := CenterContainer.new()
        cc.set_anchors_preset(Control.PRESET_FULL_RECT)
        cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        ready_ui.add_child(cc)
        var vb := VBoxContainer.new()
        vb.add_theme_constant_override("separation", 14)
        cc.add_child(vb)
        var title := Arc.label("MARBLE POPPER", 74, Arc.INK)
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(title)
        var place := MarbleData.place(level_idx / 10)
        var sub := Arc.label("%s  -  LEVEL %d" % [place["name"], level_idx + 1], 30,
                Color(0.9, 0.8, 0.6))
        sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(sub)
        var tap := Arc.label("TAP ANYWHERE TO START", 44, Color(1, 1, 1))
        tap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        tap.add_theme_color_override("font_outline_color", Color(0, 0, 0))
        tap.add_theme_constant_override("outline_size", 12)
        vb.add_child(tap)
        var hint := Arc.label("match 3+ - never feed the idol", 24, Color(0.8, 0.75, 0.65))
        hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(hint)
        if not bool(meta.d["seen_story"]) and DisplayServer.get_name() != "headless":
                meta.mark_story()
                box_story_show("THE OLD IDOL",
                        "Deep in the shrines the old idol hungers - it only "
                        + "swallows marbles, and it never stops. Roll the "
                        + "chains, match three of a color, pop the runs before "
                        + "the chain slides home. Ten places guard the gate. "
                        + "One hundred paths. The idol waits.",
                        func(): pass, "PLAY", Color(0.85, 0.65, 0.3))

func _intro_go() -> void:
        if ready_ui != null and is_instance_valid(ready_ui):
                ready_ui.queue_free()
                ready_ui = null
        _start_level(level_idx, false, 1)

# ================================================================= level
func _start_level(idx: int, as_challenge: bool, wave: int) -> void:
        level_idx = idx
        challenge = as_challenge
        challenge_wave = wave
        level = MarbleData.level(idx)
        run_level_score = 0
        combo = 0
        combo_t = 0.0
        waves_since_coin = 0
        coin_pending = false
        pow_clock = POW_FIRST_DELAY
        speed_t = 0.0
        vapor_t = 0.0
        rainbow_n = 0
        owned_pows = _owned_pows()
        _clear_world()
        _build_world()
        _deal_colors()
        phase = "preview"
        preview_t = 0.0
        _show_pop_score(true)
        var pi := int(level["place"])
        var mus: String = ["mb_music_a", "mb_music_a", "mb_music_a", "mb_music_b",
                "mb_music_b", "mb_music_b", "mb_music_c", "mb_music_c",
                "mb_music_c", "mb_music_d"][pi]
        Jukebox.music("res://assets/audio/music/%s.ogg" % mus)
        Jukebox.sfx("mb_insert", -6.0)

func _clear_world() -> void:
        for c in chains:
                c.dispose()
        chains.clear()
        shots.clear()
        if world != null and is_instance_valid(world):
                world.queue_free()
        world = null
        preview_arrows.clear()

func _build_world() -> void:
        var vp := get_viewport_rect().size
        _layout()
        ORIGIN = Vector2((vp.x - DESIGN.x) * 0.5, (vp.y - DESIGN.y) * 0.5)
        world = Node2D.new()
        world.position = ORIGIN
        add_child(world)
        # the place background (full real viewport, the room law)
        bg_spr = Sprite2D.new()
        bg_spr.texture = _t(String(MarbleData.place(int(level["place"]))["bg"]))
        bg_spr.centered = false
        bg_spr.position = Vector2(-ORIGIN.x, -ORIGIN.y)
        var tex_size := bg_spr.texture.get_size()
        bg_spr.scale = Vector2(vp.x / tex_size.x, vp.y / tex_size.y)
        bg_spr.z_index = -10
        world.add_child(bg_spr)
        track_draw = TrackDraw.new(self)
        world.add_child(track_draw)
        track_draw.z_index = 0
        marble_layer = Node2D.new()
        world.add_child(marble_layer)
        marble_layer.z_index = 2
        shot_layer = Node2D.new()
        world.add_child(shot_layer)
        shot_layer.z_index = 4
        fx_layer = Node2D.new()
        world.add_child(fx_layer)
        fx_layer.z_index = 8
        # chains + idols
        var cols := _level_colors()
        var spd := float(level["speed"])
        var quota := int(level["quota"])
        var wave := int(level["wave"])
        if challenge:
                spd *= 1.0 + 0.12 * challenge_wave
                quota = int(ceil(quota * (1.0 + 0.25 * challenge_wave)))
                wave = maxi(5, wave - challenge_wave / 3)
                var extra: int = mini(7, cols.size() + (challenge_wave - 1) / 3)
                cols = MarbleData.COLOR_REVEAL.slice(0, extra)
        var paths: Array = level["paths"]
        for i in paths.size():
                var cp := ChainPath.new()
                cp.build(paths[i], spd, quota if paths.size() == 1 else int(ceil(quota / float(paths.size()))),
                        wave if paths.size() == 1 else maxi(5, wave - 3), cols, self, i)
                chains.append(cp)
                _build_hole(i)
        _build_shooter()
        _build_preview()
        track_draw.queue_redraw()

func _owned_pows() -> Array:
        var out: Array = []
        for p in MarbleData.POWERS:
                if Box.item_owned(game_id, "power", String(p["id"])):
                        out.append(String(p["id"]))
        return out

func _level_colors() -> Array:
        return MarbleData.place_colors(int(level["place"]))

func _deal_colors() -> void:
        var cols := _level_colors()
        load_c = cols[rng.randi_range(0, cols.size() - 1)]
        next_c = cols[rng.randi_range(0, cols.size() - 1)]
        _refresh_shooter_marbles()

# ------------------------------------------------------------------ hole
func _build_hole(pi: int) -> void:
        var cp: ChainPath = chains[pi]
        var h := Node2D.new()
        h.position = cp.end_pos()
        h.z_index = 6
        var skin := _hole_skin()
        var top := Sprite2D.new()
        top.texture = _t("hole_%s_top.png" % skin)
        top.name = "top"
        h.add_child(top)
        var bot := Sprite2D.new()
        bot.texture = _t("hole_%s_bot.png" % skin)
        bot.name = "bot"
        h.add_child(bot)
        world.add_child(h)
        holes.append(h)
        _hole_pose(h, 0.0)

func _hole_pose(h: Node2D, open_amt: float) -> void:
        # both jaws anchor AT the hole center (the arch meets the fangs);
        # open_amt slides them apart (the chew)
        var top: Sprite2D = h.get_node("top")
        var bot: Sprite2D = h.get_node("bot")
        var gap := 4.0 + open_amt * 26.0
        top.position.y = -(top.texture.get_size().y * 0.5) - gap
        bot.position.y = bot.texture.get_size().y * 0.5 + gap

# ------------------------------------------------------------------ shooter
func _build_shooter() -> void:
        var sh: Dictionary = level["shooter"]
        slider = String(sh.get("mode", "fixed")) == "slider"
        twin_a = Vector2.ZERO
        twin_b = Vector2.ZERO
        twin_active = 0
        if String(sh.get("mode", "fixed")) == "twin":
                var tw: Array = sh["twin"]
                twin_a = Vector2(tw[0][0], tw[0][1])
                twin_b = Vector2(tw[1][0], tw[1][1])
        shooter_home = Vector2(float(sh["x"]), float(sh["y"]))
        shooter = Node2D.new()
        shooter.position = shooter_home
        shooter.z_index = 7
        shooter_base = Sprite2D.new()
        shooter_base.texture = _t("shooter_base.png")
        shooter_base.scale = Vector2(0.9, 0.9)
        shooter.add_child(shooter_base)
        shooter_head = Sprite2D.new()
        shooter_head.texture = _t("shooter_%s.png" % _player_skin())
        shooter_head.position.y = -34
        shooter.add_child(shooter_head)
        next_spr = Sprite2D.new()
        next_spr.scale = Vector2(0.62, 0.62)
        next_spr.position = Vector2(0, 86)
        shooter.add_child(next_spr)
        world.add_child(shooter)
        aim = Vector2(0, -1)
        shooter_head.rotation = aim.angle() + PI / 2

func _refresh_shooter_marbles() -> void:
        shooter_head.texture = _t("shooter_%s.png" % _player_skin())
        next_spr.texture = _marble_tex(next_c)
        next_spr.modulate.a = 0.95

func _swap_loaded() -> void:
        var t := load_c
        load_c = next_c
        next_c = t
        _refresh_shooter_marbles()
        Jukebox.sfx("mb_swap", -6.0)

func _shoot_at(world_pos: Vector2) -> void:
        if fire_cd > 0.0:
                return
        var dir := (world_pos - shooter.position)
        if dir.length() < 8.0:
                return
        aim = dir.normalized()
        shooter_head.rotation = aim.angle() + PI / 2
        fire_cd = FIRE_CD_FAST if speed_t > 0.0 else FIRE_CD
        var c := load_c
        var rainbow := rainbow_n > 0
        if rainbow:
                rainbow_n -= 1
                c = -1
        load_c = next_c
        var cols := _level_colors()
        next_c = cols[rng.randi_range(0, cols.size() - 1)]
        _refresh_shooter_marbles()
        var spr := Sprite2D.new()
        spr.texture = _marble_tex(c)
        spr.position = shooter.position + aim * 64.0
        shot_layer.add_child(spr)
        shots.append({"pos": spr.position, "vel": aim * (SHOT_SPEED_FAST if speed_t > 0.0 else SHOT_SPEED),
                "c": c, "spr": spr, "rainbow": rainbow})
        Jukebox.sfx("mb_shoot1" if rng.randf() < 0.5 else "mb_shoot2", -4.0,
                1.1 if rainbow else 1.0)

# ------------------------------------------------------------------ preview
func _build_preview() -> void:
        for a in preview_arrows:
                if is_instance_valid(a):
                        a.queue_free()
        preview_arrows.clear()
        for cp in chains:
                for k in 3:
                        var s := Sprite2D.new()
                        s.texture = _t("arrow.png")
                        s.z_index = 3
                        marble_layer.add_child(s)
                        preview_arrows.append(s)

# ================================================================= HUD
func _show_pop_score(reset: bool) -> void:
        if pop_lbl == null:
                pop_lbl = add_hud_chip("0", "")
        if reset:
                pop_lbl.text = "0"
        pop_lbl.visible = phase == "play" or phase == "preview"

func _pop_score_add(n: int) -> void:
        run_level_score += n
        if pop_lbl != null:
                pop_lbl.text = str(run_level_score)

func _pow_name_show(txt: String) -> void:
        pow_name_lbl.text = txt
        pow_name_lbl.modulate.a = 1.0
        pow_name_t = 1.6

func _set_lives_chip() -> void:
        if lives_lbl != null and is_instance_valid(lives_lbl):
                lives_lbl.text = "x%d" % meta.lives()

# ================================================================ MENUS
func _sheet_open(sheet_height: float, id: String, sheet_width: float, build: Callable) -> void:
        get_tree().paused = true
        paused = true
        var vb := sheet_push(sheet_height, id, sheet_width)
        build.call(vb)

func _sheet_refresh(sheet_height: float, id: String, sheet_width: float, build: Callable) -> void:
        if not _sheet_stack.is_empty() and String((_sheet_stack.back() as Dictionary).get("id", "")) == id:
                var old_sc := _find_box_scroll((_sheet_stack.back() as Dictionary)["cc"])
                if old_sc != null:
                        old_sc.preserve_key = "mb_" + id
                        old_sc.remember()
                sheet_pop()
        _sheet_open(sheet_height, id, sheet_width, build)
        if not _sheet_stack.is_empty():
                var sc := _find_box_scroll((_sheet_stack.back() as Dictionary)["cc"])
                if sc != null:
                        sc.preserve_key = "mb_" + id
                        sc.reinstate()

func _find_box_scroll(root: Node) -> BoxScroll:
        if root is BoxScroll:
                return root
        for c in root.get_children():
                var f := _find_box_scroll(c)
                if f != null:
                        return f
        return null

# ------------------------------------------------------------------ shop
func _shop_open() -> void:
        _sheet_open(get_viewport_rect().size.y * 0.90, "shop",
                minf(1500.0, get_viewport_rect().size.x * 0.62), func(vb: VBoxContainer):
                _build_shop(vb))

func _shop_refresh() -> void:
        _sheet_refresh(get_viewport_rect().size.y * 0.90, "shop",
                minf(1500.0, get_viewport_rect().size.x * 0.62), func(vb: VBoxContainer):
                _build_shop(vb))

func _shop_head(vb: VBoxContainer, title: String) -> void:
        var head := HBoxContainer.new()
        head.add_theme_constant_override("separation", 10)
        vb.add_child(head)
        head.add_child(Arc.label(title, 30, Arc.INK))
        var spacer := Control.new()
        spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        head.add_child(spacer)
        head.add_child(Arc.coin_chip())
        head.add_child(Arc.button("X", Vector2(56, 56), 26, Arc.BAD, func(): sheet_pop()))

func _shop_body(vb: VBoxContainer) -> VBoxContainer:
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
        vb.add_child(sc)
        var box := VBoxContainer.new()
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        box.add_theme_constant_override("separation", 8)
        sc.add_child(box)
        for b in Arc._buttons_in(sc):
                if not b.disabled:
                        b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        sc.register_tappable(b, Arc._tap_emitter(b))
        return box

func _skin_row(cat: String, item: Dictionary, apply_cb: Callable) -> Control:
        var owned := Box.item_owned(game_id, cat, String(item["id"])) or int(item["price"]) == 0
        var on := Box.item_on(game_id, cat) == String(item["id"]) \
                or (int(item["price"]) == 0 and Box.item_on(game_id, cat) == "")
        if on:
                return Arc.on_row("%s  (ON)" % item["name"])
        if owned:
                return Arc.button(String(item["name"]), Vector2(560, 60), 22, Arc.ACCENT, func():
                        Box.equip_item(game_id, cat, String(item["id"]))
                        Jukebox.sfx("mb_click", -6.0)
                        apply_cb.call()
                        _shop_refresh())
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        var price := int(item["price"])
        row.add_child(Arc.coin_button(str(price), Vector2(420, 60), 22, Arc.ACCENT, func():
                if Box.spend(price):
                        Box.buy_item(game_id, cat, String(item["id"]), price)
                        Jukebox.sfx("mb_coin", -4.0)
                        game_toast("%s IS YOURS" % String(item["name"]).to_upper())
                        _shop_refresh()
                else:
                        Jukebox.sfx("mb_deny", -6.0)
                        game_toast("NOT ENOUGH GOGACOINS")))
        return row

func _build_shop(vb: VBoxContainer) -> void:
        _shop_head(vb, "MARBLE POPPER SHOP")
        var box := _shop_body(vb)
        box.add_child(Arc.fit_label("PLAYER TOTEMS", 24, Arc.HOT, 560))
        for s in MarbleData.PLAYER_SKINS:
                box.add_child(_skin_row("skin_player", s, func(): _refresh_shooter_marbles()))
        box.add_child(Arc.fit_label("MARBLE CARVINGS", 24, Arc.HOT, 560))
        for s in MarbleData.MARBLE_SKINS:
                box.add_child(_skin_row("skin_marble", s, func(): _refresh_shooter_marbles()))
        box.add_child(Arc.fit_label("IDOL MOUTHS", 24, Arc.HOT, 560))
        for s in MarbleData.HOLE_SKINS:
                box.add_child(_skin_row("skin_hole", s, func(): pass))
        box.add_child(Arc.fit_label("POWERS - OWNED POWERS SPAWN IN THE CHAINS", 24, Arc.HOT, 560))
        for p in MarbleData.POWERS:
                box.add_child(_pow_row(p))
        box.add_child(Arc.button("CLOSE", Vector2(560, 72), 26, Arc.GOOD, func(): sheet_pop()))

func _pow_row(p: Dictionary) -> Control:
        var owned := Box.item_owned(game_id, "power", String(p["id"]))
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 10)
        var ic := TextureRect.new()
        ic.texture = _t("pow_%s.png" % p["id"])
        ic.custom_minimum_size = Vector2(52, 52)
        ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        row.add_child(ic)
        var vb := VBoxContainer.new()
        vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        vb.add_child(Arc.fit_label(String(p["name"]), 22, Arc.INK, 360))
        vb.add_child(Arc.fit_label(String(p["desc"]), 16, Color(0.5, 0.46, 0.4), 380))
        row.add_child(vb)
        if owned:
                row.add_child(Arc.label("OWNED", 20, Arc.GOOD))
        else:
                var price := int(p["price"])
                row.add_child(Arc.coin_button(str(price), Vector2(150, 56), 20, Arc.ACCENT, func():
                        if Box.spend(price):
                                Box.buy_item(game_id, "power", String(p["id"]), price)
                                Jukebox.sfx("mb_coin", -4.0)
                                game_toast("%s CAN SPAWN NOW" % String(p["name"]).to_upper())
                                _shop_refresh()
                        else:
                                Jukebox.sfx("mb_deny", -6.0)
                                game_toast("NOT ENOUGH GOGACOINS")))
        return row

# ------------------------------------------------------------------ levels
func _levels_open() -> void:
        _levels_stage_places()

func _levels_stage_places() -> void:
        _sheet_open(get_viewport_rect().size.y * 0.90, "levels",
                minf(1500.0, get_viewport_rect().size.x * 0.62), func(vb: VBoxContainer):
                _build_places(vb))

func _levels_stage_levels(pi: int) -> void:
        _sheet_refresh(get_viewport_rect().size.y * 0.90, "levels",
                minf(1500.0, get_viewport_rect().size.x * 0.62), func(vb: VBoxContainer):
                _build_place_levels(vb, pi))

func _build_places(vb: VBoxContainer) -> void:
        _shop_head(vb, "THE PLACES")
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
        vb.add_child(sc)
        var grid := GridContainer.new()
        grid.columns = 2
        grid.add_theme_constant_override("h_separation", 14)
        grid.add_theme_constant_override("v_separation", 12)
        grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sc.add_child(grid)
        var done_all := meta.all_cleared()
        for pi in MarbleData.PLACES.size():
                grid.add_child(_place_card(pi, done_all))
        for b in Arc._buttons_in(sc):
                if not b.disabled:
                        b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        sc.register_tappable(b, Arc._tap_emitter(b))

func _place_card(pi: int, done_all: bool) -> Control:
        var place := MarbleData.place(pi)
        var done_n := 0
        for lv in range(pi * 10 + 1, pi * 10 + 11):
                if meta.is_cleared(lv):
                        done_n += 1
        # a place is playable when its first level is unlocked (the ladder law)
        var unlocked := done_all or meta.is_unlocked(pi * 10 + 1)
        var box := PanelContainer.new()
        var st := Arc.panel_style(Color(0.98, 0.94, 0.86, 0.97) if unlocked
                else Color(0.62, 0.60, 0.58, 0.9), 14, 8)
        box.add_theme_stylebox_override("panel", st)
        var vb := VBoxContainer.new()
        vb.add_theme_constant_override("separation", 4)
        box.add_child(vb)
        var thumb := TextureRect.new()
        thumb.texture = _t(String(place["bg"]))
        thumb.custom_minimum_size = Vector2(300, 170)
        thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        thumb.modulate = Color(1, 1, 1, 1.0) if unlocked else Color(0.5, 0.5, 0.5)
        vb.add_child(thumb)
        var name_row := HBoxContainer.new()
        name_row.add_theme_constant_override("separation", 6)
        vb.add_child(name_row)
        name_row.add_child(Arc.label(String(place["name"]), 18, Arc.INK))
        name_row.add_child(Arc.label("%d/10" % done_n, 16, Color(0.55, 0.4, 0.16)))
        if not unlocked:
                var lock := TextureRect.new()
                lock.texture = load("res://assets/ui/icon_lock.png")
                lock.custom_minimum_size = Vector2(26, 26)
                lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                name_row.add_child(lock)
        var btn := Arc.button("ENTER", Vector2(0, 44), 18, Arc.GOOD, func(): _levels_stage_levels(pi))
        if not unlocked:
                btn.disabled = true
                Arc.gray_out_button(btn)
        btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        vb.add_child(btn)
        return box

func _build_place_levels(vb: VBoxContainer, pi: int) -> void:
        var head := HBoxContainer.new()
        head.add_theme_constant_override("separation", 10)
        vb.add_child(head)
        head.add_child(Arc.button("<", Vector2(56, 56), 26, Arc.CARD, func(): _levels_stage_places()))
        head.add_child(Arc.label(String(MarbleData.place(pi)["name"]), 30, Arc.INK))
        var spacer := Control.new()
        spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        head.add_child(spacer)
        head.add_child(Arc.coin_chip())
        head.add_child(Arc.button("X", Vector2(56, 56), 26, Arc.BAD, func(): sheet_pop()))
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
        vb.add_child(sc)
        var grid := GridContainer.new()
        grid.columns = 2
        grid.add_theme_constant_override("h_separation", 14)
        grid.add_theme_constant_override("v_separation", 12)
        grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sc.add_child(grid)
        var done_all := meta.all_cleared()
        for lv in range(pi * 10 + 1, pi * 10 + 11):
                grid.add_child(_level_card(lv, done_all))
        for b in Arc._buttons_in(sc):
                if not b.disabled:
                        b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        sc.register_tappable(b, Arc._tap_emitter(b))

func _level_card(lv: int, done_all: bool) -> Control:
        # lv is 1-based level number; the locked law rides the ladder
        var unlocked := done_all or meta.is_unlocked(lv)
        var cleared := meta.is_cleared(lv)
        var map := MarbleData.level(lv - 1)
        var box := PanelContainer.new()
        var st := Arc.panel_style(Color(0.98, 0.94, 0.86, 0.97) if unlocked
                else Color(0.62, 0.60, 0.58, 0.9), 14, 8)
        box.add_theme_stylebox_override("panel", st)
        var vb := VBoxContainer.new()
        vb.add_theme_constant_override("separation", 4)
        box.add_child(vb)
        var thumb := TextureRect.new()
        thumb.texture = load(A + "thumbs/%s.png" % map["id"])
        thumb.custom_minimum_size = Vector2(230, 306)
        thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        thumb.modulate = Color(1, 1, 1, 1.0) if unlocked else Color(0.45, 0.45, 0.45)
        vb.add_child(thumb)
        var stars := ""
        for i in meta.stars_for(lv):
                stars += "*"
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 6)
        vb.add_child(row)
        row.add_child(Arc.label("LV %d" % lv, 20, Arc.INK))
        if stars != "":
                row.add_child(Arc.label(stars, 16, Color(0.9, 0.6, 0.1)))
        if meta.best_for(lv) > 0:
                row.add_child(Arc.label("BEST %d" % meta.best_for(lv), 14, Color(0.5, 0.45, 0.38)))
        var mode_row := HBoxContainer.new()
        mode_row.add_theme_constant_override("separation", 6)
        vb.add_child(mode_row)
        if not unlocked:
                var lock := TextureRect.new()
                lock.texture = load("res://assets/ui/icon_lock.png")
                lock.custom_minimum_size = Vector2(40, 40)
                lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                lock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
                vb.add_child(lock)
                var why := Arc.label("clear level %d first" % (lv - 1), 14, Color(0.5, 0.45, 0.38))
                why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                vb.add_child(why)
        else:
                var normal := Arc.button("NORMAL", Vector2(0, 44), 17, Arc.GOOD, func():
                        _pick_level(lv, false))
                normal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                mode_row.add_child(normal)
                var chal := Arc.button("CHALLENGE", Vector2(0, 44), 17, Arc.HOT, func():
                        _pick_level(lv, true))
                chal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                mode_row.add_child(chal)
                if cleared:
                        var done_l := Arc.label("CLEARED", 14, Arc.GOOD)
                        done_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        vb.add_child(done_l)
        return box

func _pick_level(lv: int, as_challenge: bool) -> void:
        while _sheet_stack.size() > 0:
                sheet_pop()
        get_tree().paused = false
        paused = false
        _start_level(lv - 1, as_challenge, 1)

# ================================================================ CARDS
func _card_overlay() -> Array:
        # [root, vbox] - a small centered card above the world (not a sheet:
        # the run keeps its state; only taps are gated by phase)
        var root := Control.new()
        root.set_anchors_preset(Control.PRESET_FULL_RECT)
        root.mouse_filter = Control.MOUSE_FILTER_STOP
        _overlay_root_ref().add_child(root)
        var dim := ColorRect.new()
        dim.color = Color(0.05, 0.03, 0.06, 0.6)
        dim.set_anchors_preset(Control.PRESET_FULL_RECT)
        root.add_child(dim)
        var cc := CenterContainer.new()
        cc.set_anchors_preset(Control.PRESET_FULL_RECT)
        cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        root.add_child(cc)
        var card := PanelContainer.new()
        card.add_theme_stylebox_override("panel", Arc.panel_style(Color(0.98, 0.94, 0.86, 0.98), 22, 26))
        cc.add_child(card)
        var vb := VBoxContainer.new()
        vb.add_theme_constant_override("separation", 10)
        card.add_child(vb)
        return [root, vb]

func _close_card() -> void:
        if cleared_card != null and is_instance_valid(cleared_card):
                cleared_card.queue_free()
        cleared_card = null

# ------------------------------------------------------------------ cleared
func _show_cleared() -> void:
        phase = "cleared"
        Jukebox.sfx("mb_win", -4.0)
        Arc.confetti(_overlay_root_ref(), get_viewport_rect().size * 0.5)
        var was_new := meta.record_clear(level_idx + 1, run_level_score, _stars_earned())
        var bonus_life := false
        if was_new:
                Box.bump_counter(game_id, "levels_cleared", 1)
                Box.max_counter(game_id, "levels_max", level_idx + 1)
                bonus_life = meta.check_life_bonus()
        if meta.all_cleared():
                meta.complete_all()
        add_score(1)
        check_achievements()
        var card := _card_overlay()
        cleared_card = card[0]
        var vb: VBoxContainer = card[1]
        var t := Arc.label("LEVEL %d CLEARED!" % (level_idx + 1), 44, Arc.GOOD)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(t)
        vb.add_child(Arc.label("SCORE %d   BEST %d" % [run_level_score, meta.best_for(level_idx + 1)],
                22, Arc.INK))
        var stars := ""
        for i in _stars_earned():
                stars += "*"
        if stars != "":
                var st := Arc.label(stars, 30, Color(0.9, 0.6, 0.1))
                st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                vb.add_child(st)
        if bonus_life:
                var bl := Arc.label("+1 LIFE  (every 10 levels)", 22, Arc.HOT)
                bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                vb.add_child(bl)
                _set_lives_chip()
        var next_lv := level_idx + 2
        if next_lv <= MarbleData.LEVELS_TOTAL:
                var is_place_end := (level_idx + 1) % 10 == 0
                var nx := Arc.button("NEXT %s" % ("PLACE" if is_place_end else "LEVEL"),
                        Vector2(480, 76), 28, Arc.GOOD, func():
                        _close_card()
                        _start_level(next_lv - 1, false, 1))
                vb.add_child(nx)
                if is_place_end:
                        var np := Arc.label("%s awaits" % String(MarbleData.place(level_idx / 10 + 1)["name"]),
                                20, Color(0.55, 0.45, 0.3))
                        np.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        vb.add_child(np)
        else:
                var fin := Arc.label("ALL 100 LEVELS - THE BOX IS CLEAN!", 26, Arc.HOT)
                fin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                vb.add_child(fin)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 10)
        vb.add_child(row)
        row.add_child(Arc.button("REPLAY", Vector2(230, 64), 22, Arc.ACCENT, func():
                _close_card()
                _start_level(level_idx, false, 1)))
        row.add_child(Arc.button("LEVELS", Vector2(230, 64), 22, Arc.CARD, func():
                _close_card()
                _levels_open()))

func _stars_earned() -> int:
        var s := 1
        if combo >= 4:
                s += 1
        if run_level_score >= int(level["quota"]) * 50:
                s += 1
        return s

# ------------------------------------------------------------------ lost
func _show_lost() -> void:
        phase = "lost"
        Jukebox.sfx("mb_lose", -4.0)
        var lost_a_life: bool = meta.lose_life()
        _set_lives_chip()
        if challenge:
                meta.record_challenge_wave(level_idx + 1, challenge_wave - 1, false)
        var card := _card_overlay()
        cleared_card = card[0]
        var vb: VBoxContainer = card[1]
        var t := Arc.label("THE IDOL FED", 44, Arc.BAD)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(t)
        if meta.wiped_out():
                phase = "wiped"
                vb.add_child(Arc.label("ALL LIVES LOST - THE LADDER RESETS", 24, Arc.HOT))
                var go := Arc.button("BACK TO LEVEL 1", Vector2(480, 76), 26, Arc.ACCENT, func():
                        meta.reset_ladder()
                        _set_lives_chip()
                        _close_card()
                        _start_level(0, false, 1))
                vb.add_child(go)
        else:
                if lost_a_life and lives_lbl != null:
                        vb.add_child(Arc.label("A LIFE IS GONE - %d LEFT" % meta.lives(), 24, Arc.HOT))
                if challenge:
                        vb.add_child(Arc.label("CHALLENGE ENDED AT WAVE %d" % (challenge_wave - 1),
                                22, Arc.INK))
                var row := HBoxContainer.new()
                row.add_theme_constant_override("separation", 10)
                vb.add_child(row)
                row.add_child(Arc.button("RETRY", Vector2(230, 68), 24, Arc.GOOD, func():
                        _close_card()
                        _start_level(level_idx, false, 1)))
                row.add_child(Arc.button("LEVELS", Vector2(230, 68), 24, Arc.CARD, func():
                        _close_card()
                        _levels_open()))

# ------------------------------------------------------------------ challenge wave clear
func _show_wave_cleared() -> void:
        phase = "cleared"
        Jukebox.sfx("mb_bonus", -2.0)
        meta.record_challenge_wave(level_idx + 1, challenge_wave, false)
        var card := _card_overlay()
        cleared_card = card[0]
        var vb: VBoxContainer = card[1]
        var t := Arc.label("WAVE %d CLEARED" % challenge_wave, 42, Arc.GOOD)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(t)
        vb.add_child(Arc.label("the chain returns faster, longer, harder", 20, Arc.INK))
        vb.add_child(Arc.button("NEXT WAVE", Vector2(480, 74), 26, Arc.HOT, func():
                _close_card()
                challenge_wave += 1
                _start_level(level_idx, true, challenge_wave)))

# ================================================================ INPUT
func _goga_tk_ready() -> void:
        tk.tap_max_ms = 520.0
        tk.tapped.connect(func(p: Vector2): _field_tapped(p))
        tk.dragged.connect(func(from: Vector2, to: Vector2): _field_dragged(from, to))

func _field_tapped(p: Vector2) -> void:
        var wp := p - ORIGIN
        match phase:
                "intro":
                        _intro_go()
                "preview":
                        _begin_play()
                "play":
                        _play_tap(wp)
                _:
                        pass

func _field_dragged(from: Vector2, to: Vector2) -> void:
        if phase != "play" or not slider:
                return
        var dx := to.x - from.x
        shooter.position.x = clampf(shooter.position.x + dx, 150.0, DESIGN.x - 150.0)

func _play_tap(wp: Vector2) -> void:
        # the twin law: tap near the OTHER legal spot -> the launcher fades
        # out there and fades in at the new one (the owner's swap law)
        if not twin_a.is_zero_approx():
                var other := twin_b if twin_active == 0 else twin_a
                if wp.distance_to(other) < 170.0 and not twin_fading:
                        _twin_swap(other)
                        return
        if wp.distance_to(shooter.position + Vector2(0, -20)) < 130.0:
                _swap_loaded()
                return
        _shoot_at(wp)

func _twin_swap(target: Vector2) -> void:
        twin_fading = true
        var tw := create_tween()
        tw.tween_property(shooter, "modulate:a", 0.0, 0.22)
        tw.tween_callback(func():
                shooter.position = target
                twin_active = 1 - twin_active)
        tw.tween_property(shooter, "modulate:a", 1.0, 0.22)
        tw.tween_callback(func(): twin_fading = false)
        Jukebox.sfx("mb_swap", -8.0)

# ================================================================ TICK
func _goga_tick(delta: float) -> void:
        if pow_name_t > 0.0:
                pow_name_t -= delta
                pow_name_lbl.modulate.a = clampf(pow_name_t / 0.4, 0.0, 1.0)
        match phase:
                "preview":
                        _tick_preview(delta)
                "play":
                        _tick_play(delta)
                "eating":
                        eat_t -= delta
                        if eat_t <= 0.0:
                                phase = "lost"
                                _show_lost()
                _:
                        pass

func _begin_play() -> void:
        for a in preview_arrows:
                if is_instance_valid(a):
                        a.queue_free()
        preview_arrows.clear()
        phase = "play"
        game_toast("GO!")

func _tick_preview(delta: float) -> void:
        preview_t += delta
        var t := preview_t
        for ci in chains.size():
                var cp: ChainPath = chains[ci]
                for k in 3:
                        var ai := ci * 3 + k
                        if ai >= preview_arrows.size():
                                continue
                        var s: Sprite2D = preview_arrows[ai]
                        var d := fmod(t * 640.0 + cp.length * k / 3.0, cp.length)
                        s.position = cp.pos_at(d)
                        s.rotation = cp.angle_at(d) + PI / 2
        if t >= 1.6:
                _begin_play()

var eat_t := 0.0

func _tick_play(delta: float) -> void:
        fire_cd = maxf(0.0, fire_cd - delta)
        speed_t = maxf(0.0, speed_t - delta)
        vapor_t = maxf(0.0, vapor_t - delta)
        if combo_t > 0.0:
                combo_t -= delta
                if combo_t <= 0.0:
                        combo = 0
        # the pow spawn clock (1-2 per minute, the owner's rate law)
        if not owned_pows.is_empty() and not _pow_carrier_alive():
                pow_clock -= delta
                if pow_clock <= 0.0:
                        _spawn_pow_carrier()
                        pow_clock = rng.randf_range(POW_DELAY_LO, POW_DELAY_HI)
        for cp in chains:
                _tick_chain(cp, delta)
        _tick_shots(delta)
        _tick_holes(delta)
        if phase != "play":
                return
        # THE CLEAR LAW: quota spent, every chain empty
        var all_done := true
        for cp in chains:
                if cp.spawned < cp.quota or not cp.marbles.is_empty():
                        all_done = false
                        break
        if all_done:
                _on_level_complete()

func _tick_holes(delta: float) -> void:
        var t := Time.get_ticks_msec() / 1000.0
        for ci in chains.size():
                var cp: ChainPath = chains[ci]
                var h: Node2D = holes[ci]
                var front_d: float = cp.marbles.back()["d"] if not cp.marbles.is_empty() else -1.0
                var near := clampf(1.0 - (cp.length - maxf(front_d, 0.0)) / 320.0, 0.0, 1.0)
                var pulse := 1.0 + sin(t * 6.0) * 0.05
                if front_d >= cp.length * MarbleData.DANGER_ZONE and not cp.danger_played:
                        cp.danger_played = true
                        Jukebox.sfx("mb_danger", -2.0)
                if front_d >= cp.length * MarbleData.DANGER_ZONE:
                        pulse = 1.0 + sin(t * 14.0) * 0.12
                h.scale = Vector2(pulse, pulse)
                _hole_pose(h, near)

# ================================================================ CHAIN
func _tick_chain(cp: ChainPath, delta: float) -> void:
        # ---- the continuous feed (the hidden length law): one marble enters
        # as soon as the rearmost has stepped onto the path - the classic
        # stream; the quota stops it forever once reached
        if cp.spawned < cp.quota:
                if cp.marbles.is_empty():
                        _spawn_one(cp, 0.0)
                else:
                        var rear: float = cp.marbles[0]["d"]
                        if rear >= -MarbleData.CONTACT * 0.2:
                                _spawn_one(cp, rear - MarbleData.CONTACT)
        # ---- the movement pass (front to back; the smooth-contact law)
        var n := cp.marbles.size()
        var front_group_from := n - 1
        while front_group_from > 0 and (cp.marbles[front_group_from]["d"]
                        - cp.marbles[front_group_from - 1]["d"]) <= MarbleData.CONTACT:
                front_group_from -= 1
        # the whole front group rides ONE speed (its own front's position
        # decides the slow zone) - no intra-group compression, so no fake joins
        var group_mult := _slow_mult(cp.marbles[n - 1]["d"], cp)
        for i in range(n - 1, -1, -1):
                var m: Dictionary = cp.marbles[i]
                var in_front := i >= front_group_from
                var spd := cp.speed * (group_mult if in_front else 1.0) \
                        * (1.0 if in_front else MarbleData.CATCH_UP)
                m["d"] += spd * delta
                if i < n - 1:
                        var ahead: Dictionary = cp.marbles[i + 1]
                        var target: float = ahead["d"] - MarbleData.CONTACT
                        if m["d"] > target:
                                m["d"] = lerpf(m["d"], target, minf(1.0, delta * 20.0))
                        # THE BOND LAW: a pair carries a bonded state with
                        # hysteresis; the false->true transition IS the join
                        # event (first touch), immune to float noise
                        var gap: float = ahead["d"] - m["d"]
                        var prev: bool = m.get("bonded", true)
                        var nb := prev
                        if gap <= MarbleData.CONTACT * 1.001:
                                nb = true
                        elif gap > MarbleData.CONTACT * 1.05:
                                nb = false
                        if nb and not prev:
                                _on_join(cp, i)
                        m["bonded"] = nb
                else:
                        m["bonded"] = true
        # ---- the eat law
        if not cp.marbles.is_empty() and phase == "play":
                var front: Dictionary = cp.marbles.back()
                if front["d"] >= cp.length:
                        _on_marble_eaten(cp)
                        return
        cp.sync_sprites(delta)

func _slow_mult(d: float, cp: ChainPath) -> float:
        if d >= cp.length * MarbleData.SLOW_ZONE:
                return MarbleData.SLOW_MULT
        return 1.0

func _on_join(cp: ChainPath, i: int) -> void:
        # the connection law: two matching ends that just met through a
        # closed gap pop as a cascade; non-matching ends just move together
        if i < 0 or i + 1 >= cp.marbles.size():
                return
        var a: Dictionary = cp.marbles[i]
        var b: Dictionary = cp.marbles[i + 1]
        if a["kind"] != "m" or b["kind"] != "m":
                return
        if a["c"] != b["c"]:
                return
        var left := i
        while left > 0 and cp.marbles[left - 1]["kind"] == "m" \
                        and cp.marbles[left - 1]["c"] == a["c"] \
                        and (cp.marbles[left]["d"] - cp.marbles[left - 1]["d"]) <= MarbleData.CONTACT * 1.1:
                left -= 1
        var right := i + 1
        while right < cp.marbles.size() - 1 and cp.marbles[right + 1]["kind"] == "m" \
                        and cp.marbles[right + 1]["c"] == a["c"] \
                        and (cp.marbles[right + 1]["d"] - cp.marbles[right]["d"]) <= MarbleData.CONTACT * 1.1:
                right += 1
        if right - left + 1 >= 3:
                combo += 1
                combo_t = 2.6
                meta.record_combo(combo)
                _pop_run(cp, left, right)

# ------------------------------------------------------------------ spawn
func _spawn_one(cp: ChainPath, d: float) -> void:
        var cols := cp.colors
        var m := {"c": cols[rng.randi_range(0, cols.size() - 1)], "d": d,
                "kind": "m", "life": -1.0, "pow": "", "spr": null, "glow": null, "bonded": true}
        # THE GOGACOIN RIDER LAW: every 10 waves from the last collected one,
        # a coin rides the chain in a collectable's place; a missed coin
        # re-appears in a later wave (the pending law)
        cp.wave_spawn_i += 1
        if cp.wave_spawn_i >= cp.wave:
                cp.wave_spawn_i = 0
                waves_since_coin += 1
                cp.coin_wave_ready = coin_pending or waves_since_coin >= MarbleData.COIN_WAVES
        if cp.coin_wave_ready:
                m["kind"] = "coin"
                m["life"] = MarbleData.COIN_LIFE
                cp.coin_wave_ready = false
                coin_pending = false
                waves_since_coin = 0
                Jukebox.sfx("mb_pow", -8.0)
        # the array is the ORDER LAW: d ascending (index 0 = the rearmost)
        cp.marbles.push_front(m)
        cp.spawned += 1

# ------------------------------------------------------------------ inserts
func _insert_shot(cp: ChainPath, hit_i: int, shot: Dictionary) -> void:
        var hit: Dictionary = cp.marbles[hit_i]
        var front_pos := cp.pos_at(hit["d"] + MarbleData.CONTACT)
        var rear_pos := cp.pos_at(hit["d"] - MarbleData.CONTACT)
        var front_side: bool = shot["pos"].distance_to(front_pos) < shot["pos"].distance_to(rear_pos)
        var c: int = hit["c"] if int(shot["c"]) < 0 else int(shot["c"])
        var m := {"c": c, "d": 0.0, "kind": "m", "life": -1.0, "pow": "",
                "spr": null, "glow": null, "bonded": true}
        var new_d: float = hit["d"] + (MarbleData.CONTACT if front_side else -MarbleData.CONTACT)
        if not cp.marbles.is_empty():
                new_d = minf(new_d, cp.marbles.back()["d"] + MarbleData.CONTACT)
        m["d"] = new_d
        cp.marbles.insert(hit_i + (1 if front_side else 0), m)
        cp.ensure_sprite(m)
        Jukebox.sfx("mb_insert", -8.0, 1.2)
        _match_check(cp, cp.marbles.find(m))

func _match_check(cp: ChainPath, i: int) -> void:
        if i < 0 or i >= cp.marbles.size():
                return
        var m: Dictionary = cp.marbles[i]
        if m["kind"] != "m":
                return
        var left := i
        while left > 0 and cp.marbles[left - 1]["kind"] == "m" \
                        and cp.marbles[left - 1]["c"] == m["c"] \
                        and (m["d"] - cp.marbles[left - 1]["d"]) <= MarbleData.CONTACT * 1.12:
                left -= 1
        var right := i
        while right < cp.marbles.size() - 1 and cp.marbles[right + 1]["kind"] == "m" \
                        and cp.marbles[right + 1]["c"] == m["c"] \
                        and (cp.marbles[right + 1]["d"] - m["d"]) <= MarbleData.CONTACT * 1.12:
                right += 1
        if right - left + 1 >= 3:
                combo += 1
                combo_t = 2.6
                meta.record_combo(combo)
                _pop_run(cp, left, right)

func _pop_run(cp: ChainPath, left: int, right: int) -> void:
        # the vapor law: a match eats one extra marble each side while active
        if vapor_t > 0.0:
                if left > 0 and cp.marbles[left - 1]["kind"] == "m":
                        left -= 1
                if right < cp.marbles.size() - 1 and cp.marbles[right + 1]["kind"] == "m":
                        right += 1
        var count := right - left + 1
        var pts := 10 * count + maxi(0, combo - 1) * 20
        _pop_score_add(pts)
        for i in range(left, right + 1):
                var m: Dictionary = cp.marbles[i]
                _spawn_pop_fx(cp.pos_at(m["d"]), MarbleData.COLOR_TINT.get(m["c"], Color.WHITE))
        var popped: Array = cp.marbles.slice(left, right + 1)
        cp.marbles = cp.marbles.slice(0, left) + cp.marbles.slice(right + 1)
        for m in popped:
                if m["spr"] != null and is_instance_valid(m["spr"]):
                        m["spr"].queue_free()
                if m["glow"] != null and is_instance_valid(m["glow"]):
                        m["glow"].queue_free()
        if combo > 1:
                Jukebox.sfx("mb_combo%d" % clampi(combo, 1, 10), -4.0)
        else:
                Jukebox.sfx("mb_pop", -4.0, 1.0 + rng.randf() * 0.2)
        if count >= 5:
                Jukebox.sfx("mb_bonus", -6.0)
        # the removed run may have left matching ends that now touch:
        # the join law catches them next ticks (no forced recursion)

# ------------------------------------------------------------------ shots
func _tick_shots(delta: float) -> void:
        var dead: Array = []
        for s in shots:
            var sd: Dictionary = s
            sd["pos"] += sd["vel"] * delta
            var spr: Sprite2D = sd["spr"]
            spr.position = sd["pos"]
            if int(sd["c"]) < 0:
                    spr.modulate = Color.from_hsv(fmod(Time.get_ticks_msec() / 1000.0 * 0.9, 1.0), 0.55, 1.0)
            var wp: Vector2 = sd["pos"] + ORIGIN
            if wp.x < -200 or wp.x > get_viewport_rect().size.x + 200 \
                            or wp.y < -200 or wp.y > get_viewport_rect().size.y + 200:
                    dead.append(sd)
                    continue
            var hit_done := false
            for cp in chains:
                    if hit_done:
                            continue
                    for i in cp.marbles.size():
                            var m: Dictionary = cp.marbles[i]
                            var mp: Vector2 = cp.pos_at(m["d"])
                            if sd["pos"].distance_to(mp) <= MarbleData.MARBLE_D * 0.72:
                                    if m["kind"] == "coin":
                                            _collect_coin(cp, m)
                                    elif m["kind"] == "pow":
                                            _collect_pow(cp, m)
                                    else:
                                            _insert_shot(cp, i, sd)
                                    hit_done = true
                                    break
            if hit_done:
                    dead.append(sd)
        for sd in dead:
                if is_instance_valid(sd["spr"]):
                        sd["spr"].queue_free()
                shots.erase(sd)

func _collect_coin(cp: ChainPath, m: Dictionary) -> void:
        add_run_coins(1)
        meta.record_coin()
        Jukebox.sfx("mb_coin", -2.0)
        game_toast("+1 GOGACOIN")
        _spawn_ring_fx(cp.pos_at(m["d"]), Color(1.0, 0.85, 0.3))
        cp.marbles.erase(m)
        if m["spr"] != null and is_instance_valid(m["spr"]):
                m["spr"].queue_free()
        if m["glow"] != null and is_instance_valid(m["glow"]):
                m["glow"].queue_free()
        check_achievements()

func _collect_pow(cp: ChainPath, m: Dictionary) -> void:
        var kind := String(m["pow"])
        var pname := ""
        for p in MarbleData.POWERS:
                if p["id"] == kind:
                        pname = String(p["name"])
        _pow_name_show(pname)
        Jukebox.sfx("mb_powtake", -2.0)
        _spawn_ring_fx(cp.pos_at(m["d"]), MarbleData.POW_TINT.get(kind, Color.WHITE))
        cp.marbles.erase(m)
        if m["spr"] != null and is_instance_valid(m["spr"]):
                m["spr"].queue_free()
        if m["glow"] != null and is_instance_valid(m["glow"]):
                m["glow"].queue_free()
        match kind:
                "back":
                        for c in chains:
                                for mm in c.marbles:
                                        mm["d"] -= 300.0
                "bomb":
                        var at := cp.pos_at(m["d"])
                        var blast: Array = []
                        for mm in cp.marbles:
                                if cp.pos_at(mm["d"]).distance_to(at) <= 250.0:
                                        blast.append(mm)
                        for mm in blast:
                                _spawn_pop_fx(cp.pos_at(mm["d"]), Color(1.0, 0.6, 0.3))
                                cp.marbles.erase(mm)
                                if mm["spr"] != null and is_instance_valid(mm["spr"]):
                                        mm["spr"].queue_free()
                                if mm["glow"] != null and is_instance_valid(mm["glow"]):
                                        mm["glow"].queue_free()
                        Jukebox.sfx("mb_bomb", -2.0)
                "speed":
                        speed_t = 15.0
                "vapor":
                        vapor_t = 15.0
                "rainbow":
                        rainbow_n = 3
                "lightning":
                        var counts := {}
                        for mm in cp.marbles:
                                if mm["kind"] == "m":
                                        counts[mm["c"]] = int(counts.get(mm["c"], 0)) + 1
                        if not counts.is_empty():
                                var best_c: int = counts.keys()[0]
                                for k in counts:
                                        if counts[k] > counts[best_c]:
                                                best_c = k
                                var zapped: Array = []
                                for mm in cp.marbles:
                                        if mm["kind"] == "m" and mm["c"] == best_c and zapped.size() < 14:
                                                zapped.append(mm)
                                for mm in zapped:
                                        _spawn_pop_fx(cp.pos_at(mm["d"]), Color(0.6, 0.9, 1.0))
                                        cp.marbles.erase(mm)
                                        if mm["spr"] != null and is_instance_valid(mm["spr"]):
                                                mm["spr"].queue_free()
                                        if mm["glow"] != null and is_instance_valid(mm["glow"]):
                                                mm["glow"].queue_free()
                                Jukebox.sfx("mb_lightning", -2.0)

func _pow_carrier_alive() -> bool:
        for cp in chains:
                for m in cp.marbles:
                        if m["kind"] == "pow":
                                return true
        return false

func _spawn_pow_carrier() -> void:
        # the glowing marble slides into the richest chain (the shop law:
        # only owned kinds ever spawn)
        var best: ChainPath = chains[0]
        for cp in chains:
                if cp.marbles.size() > best.marbles.size():
                        best = cp
        if best.marbles.size() < 2:
                return
        var hit_i := rng.randi_range(1, best.marbles.size() - 1)
        var hit: Dictionary = best.marbles[hit_i]
        var m := {"c": 0, "d": hit["d"] + MarbleData.CONTACT, "kind": "pow",
                "pow": owned_pows[rng.randi_range(0, owned_pows.size() - 1)],
                "life": MarbleData.POW_LIFE, "spr": null, "glow": null, "bonded": true}
        m["d"] = minf(m["d"], best.marbles.back()["d"] + MarbleData.CONTACT)
        best.marbles.insert(hit_i + 1, m)
        best.ensure_sprite(m)
        Jukebox.sfx("mb_pow", -6.0)

# ------------------------------------------------------------------ eat / complete
func _on_marble_eaten(cp: ChainPath) -> void:
        # the idol chomps - the round ends (the owner's lives law)
        phase = "eating"
        eat_t = 0.9
        Jukebox.sfx("mb_danger", 0.0, 0.8)
        var ci := chains.find(cp)
        if ci >= 0 and ci < holes.size():
                var h: Node2D = holes[ci]
                var tw := create_tween()
                tw.tween_property(h, "scale", Vector2(1.25, 1.25), 0.12)
                tw.tween_property(h, "scale", Vector2(0.9, 0.9), 0.14)
                tw.tween_property(h, "scale", Vector2.ONE, 0.2)
        var front: Dictionary = cp.marbles.back()
        if front["spr"] != null and is_instance_valid(front["spr"]):
                var spr: Sprite2D = front["spr"]
                var tw2 := create_tween()
                tw2.tween_property(spr, "position", cp.end_pos(), 0.3)
                tw2.parallel().tween_property(spr, "scale", Vector2(0.1, 0.1), 0.3)
        cp.marbles.pop_back()

func _on_level_complete() -> void:
        if challenge:
                if challenge_wave >= MarbleData.WAVES_PER_CHALLENGE:
                        meta.record_challenge_wave(level_idx + 1, challenge_wave, true)
                        add_score(3)
                        check_achievements()
                        _show_challenge_won()
                else:
                        _show_wave_cleared()
        else:
                _show_cleared()

func _show_challenge_won() -> void:
        phase = "cleared"
        Jukebox.sfx("mb_win", -2.0)
        Arc.confetti(_overlay_root_ref(), get_viewport_rect().size * 0.5)
        var card := _card_overlay()
        cleared_card = card[0]
        var vb: VBoxContainer = card[1]
        var t := Arc.label("CHALLENGE COMPLETE!", 42, Arc.HOT)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(t)
        vb.add_child(Arc.label("all 10 waves survived - +3 points", 22, Arc.INK))
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 10)
        vb.add_child(row)
        row.add_child(Arc.button("NEXT LEVEL", Vector2(230, 66), 22, Arc.GOOD, func():
                _close_card()
                _start_level(mini(level_idx + 1, MarbleData.LEVELS_TOTAL - 1), false, 1)))
        row.add_child(Arc.button("LEVELS", Vector2(230, 66), 22, Arc.CARD, func():
                _close_card()
                _levels_open()))

# ================================================================ FX
func _spawn_pop_fx(at: Vector2, tint: Color) -> void:
        if _pop_frames.is_empty():
                return
        var spr := Sprite2D.new()
        spr.texture = _pop_frames[0]
        spr.position = at
        spr.modulate = tint
        fx_layer.add_child(spr)
        var tw := create_tween()
        for i in mini(_pop_frames.size(), 8):
                tw.tween_callback(func(): spr.texture = _pop_frames[mini(i + 1, _pop_frames.size() - 1)])
                tw.tween_interval(0.03)
        tw.parallel().tween_property(spr, "scale", Vector2(1.5, 1.5), 0.26)
        tw.tween_property(spr, "modulate:a", 0.0, 0.1)
        tw.tween_callback(spr.queue_free)

func _spawn_ring_fx(at: Vector2, tint: Color) -> void:
        if _ring_frames.is_empty():
                return
        var spr := Sprite2D.new()
        spr.texture = _ring_frames[0]
        spr.position = at
        spr.modulate = tint
        fx_layer.add_child(spr)
        var tw := create_tween()
        for i in mini(_ring_frames.size(), 6):
                tw.tween_callback(func(): spr.texture = _ring_frames[mini(i + 1, _ring_frames.size() - 1)])
                tw.tween_interval(0.05)
        tw.tween_property(spr, "modulate:a", 0.0, 0.16)
        tw.tween_callback(spr.queue_free)

# ================================================================ sheet sync
func _goga_sheet_popped(_id: String) -> void:
        if _sheet_stack.is_empty() and not over:
                get_tree().paused = false
                paused = false

# ================================================================ THE CHAIN PATH
class ChainPath extends RefCounted:
        ## One carved path + its marble chain. Data + geometry only; the game
        ## drives the laws. dist (d) runs along the resampled path; 0 = the
        ## entry, length = the idol's mouth.
        var pts := PackedVector2Array()
        var cum := PackedFloat32Array()
        var length := 0.0
        var marbles: Array = []          # ordered by d ascending
        var speed := 80.0
        var quota := 40
        var spawned := 0
        var wave := 10
        var wave_cool := 0.7
        var colors: Array = [1, 3, 6]
        var idx := 0
        var danger_played := false
        var wave_spawn_i := 0        # marbles spawned in the current wave
        var coin_wave_ready := false # the GOGACoin embeds on the next spawn
        var game: Node

        func build(raw: Array, spd: float, q: int, wv: int, cols: Array, g: Node, i: int) -> void:
                speed = spd
                quota = q
                wave = wv
                colors = cols.duplicate()
                game = g
                idx = i
                # catmull through the control points (end-clamped)
                var ctrl: Array = []
                ctrl.append(Vector2(raw[0][0], raw[0][1]))
                for v in raw:
                        ctrl.append(Vector2(v[0], v[1]))
                ctrl.append(Vector2(raw[raw.size() - 1][0], raw[raw.size() - 1][1]))
                var dense := PackedVector2Array()
                for s in range(1, ctrl.size() - 2):
                        var p0: Vector2 = ctrl[s - 1]
                        var p1: Vector2 = ctrl[s]
                        var p2: Vector2 = ctrl[s + 1]
                        var p3: Vector2 = ctrl[s + 2]
                        for tstep in 16:
                                var t := tstep / 16.0
                                var t2 := t * t
                                var t3 := t2 * t
                                var x := 0.5 * ((2.0 * p1.x) + (-p0.x + p2.x) * t \
                                        + (2.0 * p0.x - 5.0 * p1.x + 4.0 * p2.x - p3.x) * t2 \
                                        + (-p0.x + 3.0 * p1.x - 3.0 * p2.x + p3.x) * t3)
                                var y := 0.5 * ((2.0 * p1.y) + (-p0.y + p2.y) * t \
                                        + (2.0 * p0.y - 5.0 * p1.y + 4.0 * p2.y - p3.y) * t2 \
                                        + (-p0.y + 3.0 * p1.y - 3.0 * p2.y + p3.y) * t3)
                                dense.append(Vector2(x, y))
                dense.append(ctrl[ctrl.size() - 2])
                # arc-length resample every RESAMPLE px
                pts.clear()
                cum.clear()
                var step := 6.0
                pts.append(dense[0])
                cum.append(0.0)
                var prev: Vector2 = dense[0]
                var carry := 0.0
                for j in range(1, dense.size()):
                        var cur: Vector2 = dense[j]
                        var seg: float = prev.distance_to(cur)
                        if seg <= 0.0:
                                continue
                        var traveled := 0.0
                        while carry + seg - traveled >= step:
                                traveled += step - carry
                                carry = 0.0
                                var f := traveled / seg
                                var p := prev.lerp(cur, f)
                                pts.append(p)
                                cum.append(cum[cum.size() - 1] + step)
                        carry += seg - traveled
                        prev = cur
                var last: Vector2 = dense[dense.size() - 1]
                if pts[pts.size() - 1].distance_to(last) > 1.0:
                        pts.append(last)
                        cum.append(cum[cum.size() - 1] + pts[pts.size() - 2].distance_to(last))
                length = cum[cum.size() - 1]

        func pos_at(d: float) -> Vector2:
                if d <= 0.0:
                        var dir0 := (pts[0] - pts[1]).normalized()
                        return pts[0] + dir0 * (-d)
                if d >= length:
                        return pts[pts.size() - 1]
                var lo := 0
                var hi := cum.size() - 1
                while lo < hi - 1:
                        var mid := (lo + hi) / 2
                        if cum[mid] <= d:
                                lo = mid
                        else:
                                hi = mid
                var seg: float = cum[hi] - cum[lo]
                if seg <= 0.0:
                        return pts[lo]
                var f: float = (d - cum[lo]) / seg
                return pts[lo].lerp(pts[hi], f)

        func angle_at(d: float) -> float:
                var a := pos_at(d)
                var b := pos_at(d + 8.0)
                return (b - a).angle()

        func end_pos() -> Vector2:
                return pts[pts.size() - 1]

        func rear_d() -> float:
                var m := 0.0
                for x in marbles:
                        m = minf(m, x["d"])
                return m

        func ensure_sprite(m: Dictionary) -> void:
                if m["spr"] != null and is_instance_valid(m["spr"]):
                        return
                var spr := Sprite2D.new()
                if m["kind"] == "m":
                        spr.texture = game._marble_tex(int(m["c"]))
                elif m["kind"] == "coin":
                        spr.texture = load("res://assets/ui/coin.png")
                        spr.scale = Vector2(1.15, 1.15)
                else:
                        spr.texture = game._marble_tex(2)
                game.marble_layer.add_child(spr)
                m["spr"] = spr
                if m["kind"] == "pow":
                        var glow := Sprite2D.new()
                        glow.texture = game._t("pow_%s.png" % String(m["pow"]))
                        glow.scale = Vector2(0.72, 0.72)
                        spr.add_child(glow)
                        m["glow"] = glow
                        var halo := Sprite2D.new()
                        if ResourceLoader.exists("res://assets/games/geometry/p_glow.png"):
                                halo.texture = load("res://assets/games/geometry/p_glow.png")
                                halo.scale = Vector2(1.5, 1.5)
                                halo.modulate = MarbleData.POW_TINT.get(String(m["pow"]), Color.WHITE)
                                halo.show_behind_parent = true
                                spr.add_child(halo)
                elif m["kind"] == "coin":
                        var halo := Sprite2D.new()
                        if ResourceLoader.exists("res://assets/games/geometry/p_glow.png"):
                                halo.texture = load("res://assets/games/geometry/p_glow.png")
                                halo.scale = Vector2(1.4, 1.4)
                                halo.modulate = Color(1.0, 0.85, 0.3)
                                halo.show_behind_parent = true
                                spr.add_child(halo)

        func sync_sprites(delta: float) -> void:
                var t := Time.get_ticks_msec() / 1000.0
                var gone: Array = []
                for m in marbles:
                        ensure_sprite(m)
                        var spr: Sprite2D = m["spr"]
                        if spr == null or not is_instance_valid(spr):
                                continue
                        spr.position = pos_at(m["d"])
                        if m["kind"] == "m":
                                spr.rotation = m["d"] / (MarbleData.MARBLE_D * 0.5)
                        elif m["kind"] == "coin":
                                m["life"] -= delta
                                var lf: float = m["life"]
                                if lf <= 0.0:
                                        gone.append(m)
                                        continue
                                # the owner's law: 5s, then flicker and fade out
                                if lf < 1.0:
                                        spr.modulate.a = maxf(0.0, lf)
                                elif lf < 2.0:
                                        spr.modulate.a = 1.0 if fmod(t, 0.22) > 0.1 else 0.25
                                spr.scale = Vector2(1.15, 1.15) * (1.0 + sin(t * 7.0) * 0.07)
                        else:
                                m["life"] -= delta
                                if m["life"] <= 0.0:
                                        gone.append(m)
                                        continue
                                # the unmatched powerup marble pulses, then vanishes
                                if m["life"] < 1.0:
                                        spr.modulate.a = maxf(0.0, m["life"])
                                spr.rotation = 0.0
                                if m["glow"] != null and is_instance_valid(m["glow"]):
                                        m["glow"].rotation = t * 2.2
                                        m["glow"].scale = Vector2.ONE * (0.72 + sin(t * 6.0) * 0.07)
                for m in gone:
                        marbles.erase(m)
                        if m["spr"] != null and is_instance_valid(m["spr"]):
                                m["spr"].queue_free()
                        if m["glow"] != null and is_instance_valid(m["glow"]):
                                m["glow"].queue_free()
                        if m["kind"] == "coin":
                                # the missed coin re-appears in a later wave
                                game.coin_pending = true

        func dispose() -> void:
                marbles.clear()

# ================================================================ THE TRACK PAINT
class TrackDraw extends Node2D:
        var game: Node

        func _init(g: Node) -> void:
                game = g
                z_index = 0

        func _draw() -> void:
                for cp in game.chains:
                        var place := MarbleData.place(int(game.level["place"]))
                        var rim: Color = place["rim"]
                        var track: Color = place["track"]
                        var glow: Color = place["glow"]
                        var line := PackedVector2Array()
                        for p in cp.pts:
                                line.append(p)
                        draw_polyline(line, rim, MarbleData.MARBLE_D * 1.16)
                        draw_polyline(line, track, MarbleData.MARBLE_D * 0.98)
                        draw_polyline(line, rim.darkened(0.25), MarbleData.MARBLE_D * 0.30)
                        # the glow dashes down the middle (the route reads at a glance)
                        var dash := PackedVector2Array()
                        var d := 0.0
                        var on := true
                        while d < cp.length:
                                var nxt := minf(d + 34.0, cp.length)
                                if on:
                                        dash.append(cp.pos_at(d))
                                        dash.append(cp.pos_at(nxt))
                                d = nxt
                                on = not on
                        draw_polyline(dash, Color(glow, 0.30), 6.0)
                        # the entry portal
                        draw_circle(cp.pts[0], MarbleData.MARBLE_D * 0.72, rim)
                        draw_arc(cp.pts[0], MarbleData.MARBLE_D * 0.72, 0.0, TAU, 24,
                                Color(glow, 0.65), 5.0)
                        # the idol seat
                        draw_circle(cp.end_pos(), MarbleData.MARBLE_D * 0.85, rim.darkened(0.3))
