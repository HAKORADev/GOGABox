extends GogaGame
## COSMIC SPUD (v0.3.4) - the Brotato-competitor.
## THE GDD: docs/goga_docs/gogames_ideas/cosmic_spud.md (the law).
## THE CAMERA LAW: the arena (2400x1350) is much bigger than the screen;
## the camera follows SPUDNIK and clamps - walking to the edges only reveals
## more ground. THE CONTROLS: an invisible analog stick born under the
## finger + auto-shoot at the best target. THE ECONOMY: score = kills,
## XP = the double-duty ledger, COSMIC COINS = the game's own wallet.

const ARENA := Rect2(0, 0, 2400, 1350)
const ARENA_MARGIN := 90.0        # the ground paints past the bounds
const PLAYER_SPD := 210.0
const PLAYER_R := 22.0
const STICK_DEAD := 8.0
const STICK_MAX := 70.0
const IFRAME := 0.6
const MAGNET_BASE := 150.0

var meta: CSMeta
var world: Node2D
var fx: Node2D                    # the _draw overlay (rings, auras, beams)
var cam: Camera2D
var ground_scale := 1.0

var phase := "boot"               # boot | play | break | dead
var theme_id := "desert"
var night := false
var start_id := "soldier"

# the run's numbers
var run_wave := 1
var wave_clock := 0.0
var wave_spawning := true
var run_xp := 0
var run_level := 1
var run_ccoins := 0               # in-run cosmic coins (bank at the end)
var run_kills := 0
var run_merges := 0
var pending_levels := 0
var second_wind_used := false
var boss_alive := false

# the player
var p_pos := Vector2(1200, 675)
var p_hp := 100.0
var p_max_hp := 100.0
var p_aim := 0.0
var p_iframe := 0.0
var p_walk := 0.0
var p_node: Sprite2D
var stats := {}                   # the live stat block (see _base_stats)

# the entities
var enemies: Array = []
var bullets: Array = []
var ebullets: Array = []
var pickups: Array = []
var allies: Array = []
var props: Array = []             # [{rect: Rect2}] the solid decor
var zones: Array = []             # gravity wells / telegraphs
var weapons_run: Array = []       # [{id, tier, cd}]

# the stick
var stick_active := false
var stick_origin := Vector2.ZERO
var stick_vec := Vector2.ZERO
var stick_ghost: Node2D

# hud extras
var hp_bar: ColorRect
var hp_fill: ColorRect
var hp_txt: Label
var xp_bar: ColorRect
var xp_fill: ColorRect
var lvl_txt: Label
var wave_txt: Label
var cc_txt: Label
var boss_bar: ColorRect
var boss_fill: ColorRect
var boss_txt: Label
var _tex: Dictionary = {}

# ================================================================ textures
func _t(key: String) -> Texture2D:
        if not _tex.has(key):
                var base := "res://assets/games/cosmic_spud/"
                var paths := {
                        "hero": base + "hero/spudnik.png",
                        "blab": base + "enemies/blab.png", "sprinter": base + "enemies/sprinter.png",
                        "chunk": base + "enemies/chunk.png", "spitter": base + "enemies/spitter.png",
                        "wraith": base + "enemies/wraith.png", "brood": base + "enemies/brood.png",
                        "mender": base + "enemies/mender.png", "charger": base + "enemies/charger.png",
                        "boomling": base + "enemies/boomling.png", "splitter": base + "enemies/splitter.png",
                        "orbiter": base + "enemies/orbiter.png", "minion": base + "enemies/minion.png",
                        "boss_heap": base + "enemies/boss_heap.png",
                        "boss_prism": base + "enemies/boss_prism.png",
                        "boss_reaper": base + "enemies/boss_reaper.png",
                        "xp": base + "pickups/xp.png", "coin": base + "pickups/coin.png",
                        "heart": base + "pickups/heart.png",
                        "rock": base + "props/rock.png", "skull": base + "props/skull.png",
                        "crate": base + "props/crate.png", "barrel": base + "props/barrel.png",
                        "tree": base + "props/tree.png", "bench": base + "props/bench.png",
                        "fence": base + "props/fence.png", "shrub": base + "props/shrub.png",
                        "ferris": base + "props/ferris.png",
                        "circle": base + "fx/circle.png", "circle_soft": base + "fx/circle_soft.png",
                        "smoke": base + "fx/smoke.png", "star": base + "fx/star.png",
                        "flare": base + "fx/flare.png", "light": base + "fx/light.png",
                        "muzzle": base + "fx/muzzle.png", "dirt": base + "fx/dirt.png",
                        "fire": base + "fx/fire.png", "flame": base + "fx/flame.png",
                }
                for wid in CSData.WEAPON_ORDER:
                        paths["icon_" + wid] = base + "weapons/icon_" + wid + ".png"
                        paths["gun_" + wid] = base + "weapons/gun_" + wid + ".png"
                for proj in ["bolt", "pellet", "slug", "lance", "bomb", "shard",
                                "rail", "spit", "orb", "boomerang", "tracer"]:
                        paths["proj_" + proj] = base + "bullets/" + proj + ".png"
                _tex[key] = load(paths[key])
        return _tex[key]

# ================================================================ the stats
## the live stat block: START base x tree meta x run drafts x level picks
func _base_stats() -> Dictionary:
        var s: Dictionary = CSData.STARTS[start_id]
        var st := {
                "dmg_m": float(s["dmg"]), "spd_m": float(s["spd"]),
                "aspeed_m": float(s["aspeed"]), "range_m": float(s["range"]),
                "armor": int(s["armor"]), "crit": float(s["crit"]),
                "regen": float(s["regen"]), "magnet": 1.0,
                "proj_add": 0, "pierce_all": 0, "lifesteal": 0.0,
                "burn_hit": start_id == "pyro", "chill_hit": start_id == "frostbite",
                "ally_dmg": 1.0, "contact_cut": 1.0,
                "crit_mult": 2.0, "coin_m": 1.0,
        }
        if start_id == "soldier":
                st["dmg_m"] += 0.10
        if start_id == "brawler":
                st["contact_cut"] = 0.8
        if start_id == "engineer":
                st["ally_dmg"] = 1.25
        # THE TREE (meta perks)
        if meta.tree_node("o1"):
                st["dmg_m"] += 0.08
        if meta.tree_node("o2"):
                st["dmg_m"] += 0.08
        if meta.tree_node("o4"):
                st["crit"] += 0.10
        if meta.tree_node("o5"):
                st["crit_mult"] = 3.0
        if meta.tree_node("d1"):
                st["hp_bonus"] = 20.0
        if meta.tree_node("d2"):
                st["armor"] += 2
        if meta.tree_node("d3"):
                st["regen"] += 1.0
        if meta.tree_node("u1"):
                st["magnet"] += 0.30
        if meta.tree_node("u2"):
                st["coin_m"] += 0.10
        if meta.tree_node("l2"):
                st["ally_dmg"] += 0.25
        return st

func _max_hp() -> float:
        var base: float = float(CSData.STARTS[start_id]["hp"])
        var bonus := 0.0
        if meta.tree_node("d1"):
                bonus += 20.0
        # the run's accumulated +max_hp (drafts + level picks live in stats.hp_add)
        bonus += float(stats.get("hp_add", 0.0))
        return base + bonus

# ================================================================ setup
func _exit_tree() -> void:
        get_tree().paused = false     # THE UNFREEZE LAW

func _goga_setup() -> void:
        meta = CSMeta.load_meta()
        theme_id = meta.theme()
        night = meta.is_night()
        bonus_div_override = 200      # THE OWNER'S KILL-BONUS LAW (/200)
        var theme: Dictionary = CSData.THEMES[theme_id]
        world = Node2D.new()
        add_child(world)
        _build_ground(theme)
        _build_camera()
        fx = FxLayer.new()
        fx.game = self
        world.add_child(fx)
        _build_player()
        _build_hud_extras()
        _build_stick_ghost()
        add_hud_button("SHOP", func(): _shop_button())
        add_hud_button("TREE", func(): _tree_open())
        Jukebox.music(theme["night_music"] if night else theme["day_music"])
        _optionals_open()

# ------------------------------------------------------------------ ground
func _build_ground(theme: Dictionary) -> void:
        var tex_path: String = theme["night"] if night else theme["day"]
        var gt: Texture2D = load(tex_path)
        # the ground tiles 640x360; the paint extends ARENA_MARGIN past the
        # bounds (the owner's camera law: the world reads bigger than the box)
        var gw := gt.get_width()
        var gh := gt.get_height()
        for gy in range(-1, int((ARENA.size.y + ARENA_MARGIN * 2) / gh) + 1):
                for gx in range(-1, int((ARENA.size.x + ARENA_MARGIN * 2) / gw) + 1):
                        var cell := Sprite2D.new()
                        cell.texture = gt
                        cell.centered = false
                        cell.position = Vector2(gx * gw, gy * gh) - Vector2(ARENA_MARGIN, ARENA_MARGIN)
                        cell.z_index = -30
                        world.add_child(cell)
        var tint: Color = theme["tint_night"] if night else theme["tint_day"]
        # the park's dead ferris wheel watches from the top edge
        if theme_id == "park":
                var ferris := Sprite2D.new()
                ferris.texture = _t("ferris")
                ferris.position = Vector2(ARENA.size.x * 0.72, -60)
                ferris.modulate = Color(1, 1, 1, 0.5)
                ferris.z_index = -28
                world.add_child(ferris)
        _scatter_props(theme, tint)

func _scatter_props(theme: Dictionary, _tint: Color) -> void:
        var rng := RandomNumberGenerator.new()
        rng.seed = int(hash(theme_id) + (911 if night else 313))  # per-theme+time
        var kinds: Array = theme["night_props"] if night else theme["props"]
        var n := 26
        for i in n:
                var k: String = kinds[rng.randi() % kinds.size()]
                var tex := _t(k)
                var spr := Sprite2D.new()
                spr.texture = tex
                spr.position = Vector2(rng.randf_range(60, ARENA.size.x - 60),
                                rng.randf_range(60, ARENA.size.y - 60))
                spr.scale = Vector2.ONE * rng.randf_range(0.8, 1.5)
                spr.rotation = rng.randf_range(-0.2, 0.2)
                spr.z_index = -5
                world.add_child(spr)
                # big props are SOLID: a soft circle the units slide around
                var r := tex.get_width() * spr.scale.x * 0.35
                if k in ["rock", "crate", "tree", "barrel"]:
                        props.append({"c": spr.position, "r": r})

# ------------------------------------------------------------------ camera
func _build_camera() -> void:
        cam = Camera2D.new()
        cam.position = p_pos
        cam.make_current()
        add_child(cam)
        _apply_cam_zoom()

## THE ZOOM LAW: on huge logical viewports the camera zooms OUT so the
## visible world never exceeds ~1700x1000 - the view must never fit the
## whole ground (the camera law's guarantee, at any resolution).
func _apply_cam_zoom() -> void:
        var view := get_viewport_rect().size
        var z: float = maxf(maxf(1.0, view.x / 1700.0), view.y / 1000.0)
        cam.zoom = Vector2.ONE * z

func _cam_half() -> Vector2:
        return get_viewport_rect().size * 0.5 / (cam.zoom if cam != null else Vector2.ONE)

func _cam_clamp_pos(target: Vector2) -> Vector2:
        # the camera law: clamp to the arena + margin so the view NEVER fits the
        # whole ground - the edges always hold more world
        var half := _cam_half()
        var lo := Vector2(ARENA.position.x - ARENA_MARGIN, ARENA.position.y - ARENA_MARGIN) + half
        var hi := Vector2(ARENA.end.x + ARENA_MARGIN, ARENA.end.y + ARENA_MARGIN) - half
        if lo.x > hi.x:
                var mx := (ARENA.position.x + ARENA.end.x) * 0.5
                lo.x = mx
                hi.x = mx
        if lo.y > hi.y:
                var my := (ARENA.position.y + ARENA.end.y) * 0.5
                lo.y = my
                hi.y = my
        return Vector2(clampf(target.x, lo.x, hi.x), clampf(target.y, lo.y, hi.y))

# ------------------------------------------------------------------ player
func _build_player() -> void:
        p_pos = ARENA.get_center()
        p_node = Sprite2D.new()
        p_node.texture = _t("hero")
        p_node.z_index = 10
        world.add_child(p_node)
        stats = _base_stats()
        p_max_hp = _max_hp()
        p_hp = p_max_hp
        _rebuild_weapons()

func _rebuild_weapons() -> void:
        weapons_run.clear()
        var lo := meta.loadout()
        for wid in lo:
                weapons_run.append({"id": wid, "tier": 1, "cd": 0.0})

func _gun_nodes() -> void:
        pass  # guns render through the fx layer (rotated to the aim)

# ------------------------------------------------------------------ stick
class StickGhost extends Node2D:
        var game: Node
        func _draw() -> void:
                if not game.stick_active:
                        return
                draw_circle(Vector2.ZERO, 34.0, Color(1, 1, 1, 0.10))
                draw_arc(Vector2.ZERO, 34.0, 0, TAU, 40, Color(1, 1, 1, 0.35), 2.0)
                draw_circle(game.stick_vec, 16.0, Color(1, 1, 1, 0.30))

func _build_stick_ghost() -> void:
        stick_ghost = StickGhost.new()
        stick_ghost.game = self
        stick_ghost.z_index = 50
        add_child(stick_ghost)   # screen space (the game node is the root canvas)

# ================================================================ the HUD
func _build_hud_extras() -> void:
        if _hud_row != null and is_instance_valid(_hud_row):
                _hud_row.offset_top = 44.0
                _hud_row.offset_bottom = 104.0
        var vp := get_viewport_rect().size
        var root := _overlay_root_ref()
        var left := VBoxContainer.new()
        left.position = Vector2(14, 118)   # below the chrome band (the notch law)
        left.custom_minimum_size = Vector2(280, 0)
        left.add_theme_constant_override("separation", 4)
        root.add_child(left)
        # the HP bar
        hp_bar = ColorRect.new()
        hp_bar.color = Color(0.12, 0.09, 0.08, 0.82)
        hp_bar.custom_minimum_size = Vector2(280, 22)
        left.add_child(hp_bar)
        hp_fill = ColorRect.new()
        hp_fill.color = Color(0.36, 0.78, 0.42)
        hp_fill.position = Vector2(2, 2)
        hp_fill.size = Vector2(276, 18)
        hp_bar.add_child(hp_fill)
        hp_txt = Label.new()
        hp_txt.add_theme_font_size_override("font_size", 13)
        hp_txt.add_theme_color_override("font_color", Color.WHITE)
        hp_bar.add_child(hp_txt)
        # the XP bar
        xp_bar = ColorRect.new()
        xp_bar.color = Color(0.10, 0.10, 0.14, 0.82)
        xp_bar.custom_minimum_size = Vector2(280, 12)
        left.add_child(xp_bar)
        xp_fill = ColorRect.new()
        xp_fill.color = Color(0.35, 0.85, 1.0)
        xp_fill.position = Vector2(2, 2)
        xp_fill.size = Vector2(276, 8)
        xp_bar.add_child(xp_fill)
        var row := HBoxContainer.new()
        left.add_child(row)
        lvl_txt = _mk_label(row, "LV 1", 13, Color(0.7, 0.9, 1))
        wave_txt = _mk_label(row, "WAVE 1", 13, Color(1, 0.9, 0.5))
        # the cosmic coins chip (the game's OWN currency, distinct from the box)
        var cc := PanelContainer.new()
        var ccst := StyleBoxFlat.new()
        ccst.bg_color = Color(0.16, 0.12, 0.04, 0.85)
        ccst.corner_radius_top_left = 9
        ccst.corner_radius_top_right = 9
        ccst.corner_radius_bottom_left = 9
        ccst.corner_radius_bottom_right = 9
        ccst.content_margin_left = 10
        ccst.content_margin_right = 10
        ccst.content_margin_top = 3
        ccst.content_margin_bottom = 3
        cc.add_theme_stylebox_override("panel", ccst)
        cc.position = Vector2(vp.x - 150, 122)
        root.add_child(cc)
        var h := HBoxContainer.new()
        cc.add_child(h)
        var ic := TextureRect.new()
        ic.texture = _t("coin")
        ic.custom_minimum_size = Vector2(18, 18)
        ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        h.add_child(ic)
        cc_txt = Label.new()
        cc_txt.add_theme_font_size_override("font_size", 15)
        cc_txt.add_theme_color_override("font_color", Color(1, 0.82, 0.3))
        h.add_child(cc_txt)
        # the boss bar (hidden until a boss lives)
        boss_bar = ColorRect.new()
        boss_bar.color = Color(0.10, 0.06, 0.10, 0.85)
        boss_bar.custom_minimum_size = Vector2(420, 16)
        boss_bar.position = Vector2((vp.x - 420) * 0.5, 122)
        boss_bar.visible = false
        root.add_child(boss_bar)
        boss_fill = ColorRect.new()
        boss_fill.color = Color(0.9, 0.25, 0.35)
        boss_fill.position = Vector2(2, 2)
        boss_fill.size = Vector2(416, 12)
        boss_bar.add_child(boss_fill)
        boss_txt = Label.new()
        boss_txt.add_theme_font_size_override("font_size", 11)
        boss_txt.add_theme_color_override("font_color", Color.WHITE)
        boss_bar.add_child(boss_txt)
        _refresh_hud()

func _mk_label(row: Container, txt: String, sz: int, col: Color) -> Label:
        var l := Label.new()
        l.text = txt
        l.add_theme_font_size_override("font_size", sz)
        l.add_theme_color_override("font_color", col)
        row.add_child(l)
        return l

func _refresh_hud() -> void:
        if hp_fill != null:
                var f := clampf(p_hp / p_max_hp, 0.0, 1.0)
                hp_fill.size.x = 276.0 * f
                hp_fill.color = Color(0.36, 0.78, 0.42) if f > 0.35 else Color(0.9, 0.4, 0.3)
                hp_txt.text = "%d / %d" % [int(ceilf(p_hp)), int(p_max_hp)]
                hp_txt.position = Vector2((280 - hp_txt.size.x) * 0.5, 1)
        if xp_fill != null:
                var need := CSData.xp_for_run_level(run_level)
                xp_fill.size.x = 276.0 * clampf(float(run_xp) / float(need), 0.0, 1.0)
        if lvl_txt != null:
                lvl_txt.text = "LV %d" % run_level
                wave_txt.text = ("BOSS WAVE" if boss_alive else "WAVE %d" % run_wave)
                wave_txt.add_theme_color_override("font_color",
                                Color(1, 0.4, 0.45) if boss_alive else Color(1, 0.9, 0.5))
        if cc_txt != null:
                cc_txt.text = str(run_ccoins)
        if boss_fill != null:
                for e in enemies:
                        if e.get("boss", false):
                                boss_bar.visible = true
                                boss_fill.size.x = 416.0 * clampf(float(e["hp"]) / float(e["max_hp"]), 0.0, 1.0)
                                boss_txt.text = "%s  %d%%" % [e["name"], int(100.0 * float(e["hp"]) / float(e["max_hp"]))]
                                boss_txt.position = Vector2((420 - boss_txt.size.x) * 0.5, 0)
                                return
                boss_bar.visible = false

# ================================================================ the sheet
## every CS modal pauses the tree (the matcher picker law); the sheet chain
## itself is PROCESS_MODE_ALWAYS so the UI stays alive.
var _sheet_ids: Array = []

func _open_sheet(build: Callable, height := 0.0) -> VBoxContainer:
        get_tree().paused = true
        paused = true
        var v := sheet_push(height, "cs")
        _sheet_ids.append("cs")
        build.call(v)
        return v

func _goga_sheet_popped(id: String) -> void:
        _sheet_ids.erase(id)
        if _sheet_ids.is_empty():
                get_tree().paused = false
                paused = false

func _close_all_sheets() -> void:
        while sheet_open_count() > 0:
                sheet_pop()
        _sheet_ids.clear()
        get_tree().paused = false
        paused = false

# ================================================================ optionals
## THE GAME OPTIONALS MENU: the 6 STARTS (the owner's law: "each game start
## it gives 6 options in the game optionals menu while each one of them has
## different base skills set") + the theme chips + the GOGASHOP.
func _optionals_open() -> void:
        var v := _open_sheet(func(box: VBoxContainer): _build_optionals(box), 0.0)
        v.name = "cs_optionals"

func _build_optionals(box: VBoxContainer) -> void:
        var title := Label.new()
        title.text = "COSMIC SPUD"
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        title.add_theme_font_size_override("font_size", 30)
        title.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
        box.add_child(title)
        var sub := Label.new()
        sub.text = "pick one of the six starts - SPUDNIK wears every mask"
        sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sub.add_theme_font_size_override("font_size", 13)
        sub.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
        box.add_child(sub)
        var grid := GridContainer.new()
        grid.columns = 3
        grid.add_theme_constant_override("h_separation", 10)
        grid.add_theme_constant_override("v_separation", 10)
        grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        box.add_child(grid)
        var picked := start_id
        for sid in CSData.START_ORDER:
                grid.add_child(_start_card(sid))
        var theme_row := HBoxContainer.new()
        theme_row.alignment = BoxContainer.ALIGNMENT_CENTER
        theme_row.add_theme_constant_override("separation", 8)
        box.add_child(theme_row)
        var tl := _mk_label(theme_row, "THEME:", 13, Color(0.8, 0.8, 0.9))
        tl.custom_minimum_size = Vector2(70, 0)
        for tid in CSData.THEME_ORDER:
                var owned := meta.has_theme(tid)
                var b := Button.new()
                var th: Dictionary = CSData.THEMES[tid]
                var label_txt: String = th["name"]
                if night:
                        label_txt += " (NIGHT)"
                b.text = label_txt if owned else label_txt + " - %d CC" % int(th["price"])
                b.disabled = not owned
                b.add_theme_font_size_override("font_size", 12)
                b.tooltip_text = "tap to cycle day/night" if owned else "buy it in the GogaShop"
                b.pressed.connect(func():
                        if meta.has_theme(tid):
                                # tap cycles day/night for the OWNED theme
                                if theme_id == tid:
                                        night = not night
                                else:
                                        theme_id = tid
                                meta.set_theme(theme_id, night)
                                _close_all_sheets()
                                _goga_setup_retheme())
                theme_row.add_child(b)
        var shop_row := HBoxContainer.new()
        shop_row.alignment = BoxContainer.ALIGNMENT_CENTER
        shop_row.add_theme_constant_override("separation", 10)
        box.add_child(shop_row)
        var shop_b := Button.new()
        shop_b.text = "GOGASHOP"
        shop_b.add_theme_font_size_override("font_size", 15)
        shop_b.pressed.connect(func(): _gogashop_open())
        shop_row.add_child(shop_b)
        var tree_b := Button.new()
        tree_b.text = "SKILL TREE"
        tree_b.add_theme_font_size_override("font_size", 15)
        tree_b.pressed.connect(func(): _tree_open())
        shop_row.add_child(tree_b)
        var info := Label.new()
        var cl := meta.char_level()
        info.text = "SPUDNIK level %d   -   %d cosmic coins   -   weapon tier cap T%d" \
                        % [cl, meta.coins(), meta.tier_cap()]
        info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        info.add_theme_font_size_override("font_size", 12)
        info.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
        box.add_child(info)
        var go := Button.new()
        go.text = "DROP IN"
        go.add_theme_font_size_override("font_size", 20)
        go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        go.pressed.connect(func(): _start_run())
        box.add_child(go)

func _start_card(sid: String) -> Button:
        var s: Dictionary = CSData.STARTS[sid]
        var b := Button.new()
        b.custom_minimum_size = Vector2(230, 118)
        var st := StyleBoxFlat.new()
        st.bg_color = Color(0.13, 0.11, 0.16, 0.96)
        st.corner_radius_top_left = 12
        st.corner_radius_top_right = 12
        st.corner_radius_bottom_left = 12
        st.corner_radius_bottom_right = 12
        st.border_color = Color(1, 0.85, 0.4) if sid == start_id else Color(0.3, 0.3, 0.4)
        st.set_border_width_all(2)
        b.add_theme_stylebox_override("normal", st)
        var hov := st.duplicate()
        hov.border_color = Color(1, 0.95, 0.6)
        b.add_theme_stylebox_override("hover", hov)
        var vb := VBoxContainer.new()
        vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.set_anchors_preset(Control.PRESET_FULL_RECT)
        vb.add_theme_constant_override("separation", 1)
        vb.offset_left = 8
        vb.offset_top = 6
        vb.offset_right = -8
        b.add_child(vb)
        var nm := Label.new()
        nm.text = s["name"]
        nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        nm.add_theme_font_size_override("font_size", 14)
        nm.add_theme_color_override("font_color", s["tint"])
        vb.add_child(nm)
        var st_txt := Label.new()
        st_txt.text = "HP %d  DMG %d%%  SPD %d%%\nASPD %d%%  RNG %d%%  ARM %d" % [
                int(s["hp"]), int(s["dmg"] * 100), int(s["spd"] * 100),
                int(s["aspeed"] * 100), int(s["range"] * 100), int(s["armor"])]
        st_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        st_txt.add_theme_font_size_override("font_size", 11)
        st_txt.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
        vb.add_child(st_txt)
        var pk := Label.new()
        pk.text = s["perk"]
        pk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        pk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        pk.custom_minimum_size = Vector2(214, 0)
        pk.add_theme_font_size_override("font_size", 10)
        pk.add_theme_color_override("font_color", Color(0.6, 0.9, 0.7))
        vb.add_child(pk)
        b.pressed.connect(func():
                start_id = sid
                _close_all_sheets()
                _optionals_open())
        return b

func _optionals_refresh() -> void:
        pass  # (the card press re-opens the sheet; nothing else needed)

func _goga_setup_retheme() -> void:
        # a theme flip from the optionals re-paints the arena in place
        for c in world.get_children():
                c.queue_free()
        _tex.clear()
        var theme: Dictionary = CSData.THEMES[theme_id]
        _build_ground(theme)
        fx = FxLayer.new()
        fx.game = self
        world.add_child(fx)
        _build_player()
        Jukebox.music(theme["night_music"] if night else theme["day_music"])
        _optionals_open()

func _start_run() -> void:
        _close_all_sheets()
        _start_id_persist()
        run_wave = 1
        run_xp = 0
        run_level = 1
        run_ccoins = 0
        run_kills = 0
        run_merges = 0
        pending_levels = 0
        second_wind_used = false
        boss_alive = false
        enemies.clear()
        bullets.clear()
        ebullets.clear()
        pickups.clear()
        allies.clear()
        zones.clear()
        stats = _base_stats()
        p_max_hp = _max_hp()
        p_hp = p_max_hp
        p_pos = ARENA.get_center()
        cam.position = _cam_clamp_pos(p_pos)
        _rebuild_weapons()
        # THE ENGINEER's free drone
        if start_id == "engineer":
                _deploy_ally("drone", 1)
        _begin_wave(1)

func _start_id_persist() -> void:
        meta.d["last_start"] = start_id
        meta.save()

# ================================================================ the stick
func _goga_input(event: InputEvent) -> void:
        if event is InputEventScreenTouch or event is InputEventMouseButton:
                var pressed: bool = event.pressed if event is InputEventScreenTouch \
                                else (event.button_index == MOUSE_BUTTON_LEFT and event.pressed)
                var p := (event as InputEventScreenTouch).position \
                                if event is InputEventScreenTouch else (event as InputEventMouseButton).position
                if pressed and not stick_active:
                        # THE INVISIBLE STICK is born under ANY finger, anywhere
                        if sheet_open_count() == 0 and not over and phase == "play":
                                stick_active = true
                                stick_origin = p
                                stick_vec = Vector2.ZERO
                                stick_ghost.position = p
                                stick_ghost.queue_redraw()
                elif not pressed and stick_active:
                        stick_active = false
                        stick_vec = Vector2.ZERO
                        stick_ghost.queue_redraw()
        elif event is InputEventScreenDrag or event is InputEventMouseMotion:
                var p2 := (event as InputEventScreenDrag).position \
                                if event is InputEventScreenDrag else (event as InputEventMouseMotion).position
                if stick_active:
                        var d := p2 - stick_origin
                        if d.length() < STICK_DEAD:
                                stick_vec = Vector2.ZERO
                        else:
                                stick_vec = d.limit_length(STICK_MAX) / STICK_MAX
                        stick_ghost.queue_redraw()

# ================================================================ the tick
func _goga_tick(delta: float) -> void:
        if phase != "play" and phase != "break":
                return
        _tick_player(delta)
        _tick_weapons(delta)
        _tick_allies(delta)
        _tick_bullets(delta)
        _tick_ebullets(delta)
        _tick_enemies(delta)
        _tick_zones(delta)
        _tick_pickups(delta)
        _tick_waves(delta)
        _tick_fx(delta)
        _tick_camera(delta)
        fx.queue_redraw()
        _refresh_hud()

func _tick_player(delta: float) -> void:
        # the regen law
        if p_hp < p_max_hp and stats["regen"] > 0:
                p_hp = minf(p_max_hp, p_hp + stats["regen"] * delta)
        if p_iframe > 0:
                p_iframe -= delta
        # the stick move
        if stick_active and stick_vec.length() > 0.01:
                var v := stick_vec * PLAYER_SPD * float(stats["spd_m"])
                p_pos += v * delta
                p_walk += delta * 9.0
        else:
                p_walk = 0.0
        # solid props: slide out of the circles
        for pr in props:
                var d: Vector2 = p_pos - pr["c"]
                var dist := d.length()
                var rmin: float = float(pr["r"]) + PLAYER_R
                if dist < rmin and dist > 0.01:
                        p_pos = pr["c"] + d.normalized() * rmin
        p_pos.x = clampf(p_pos.x, ARENA.position.x + PLAYER_R, ARENA.end.x - PLAYER_R)
        p_pos.y = clampf(p_pos.y, ARENA.position.y + PLAYER_R, ARENA.end.y - PLAYER_R)
        # the walk bob + hurt flash
        p_node.position = p_pos + Vector2(0, sin(p_walk) * 2.0)
        p_node.rotation = p_aim
        var flash := 1.0 if p_iframe <= 0 else (0.5 + 0.5 * absf(sin(p_iframe * 30.0)))
        p_node.modulate = Color(1, flash, flash)

func _tick_camera(delta: float) -> void:
        var target := _cam_clamp_pos(p_pos)
        cam.position = cam.position.lerp(target, clampf(8.0 * delta, 0.0, 1.0))

# ================================================================ weapons
func _tick_weapons(delta: float) -> void:
        # aim: the best target for the FIRST weapon sets Spudnik's facing
        p_aim = _aim_angle()
        for w in weapons_run:
                w["cd"] -= delta * float(stats["aspeed_m"])
                if w["cd"] <= 0.0:
                        if _fire_weapon(w):
                                var mult: Dictionary = CSData.tier_mult(int(w["tier"]))
                                w["cd"] = float(CSData.WEAPONS[w["id"]]["cad"]) * float(mult["cad"])
                        else:
                                w["cd"] = 0.05   # nothing in range - retry soon

func _aim_angle() -> float:
        var best := p_aim
        var best_score := -1.0
        for e in enemies:
                var d: Vector2 = e["pos"] - p_pos
                var dist := d.length()
                if dist > 900.0:
                        continue
                var pr := 1.0
                if e.get("boss", false):
                        pr = 3.0
                elif e.get("elite", false):
                        pr = 2.0
                var sc := pr * 1000.0 - dist
                if sc > best_score:
                        best_score = sc
                        best = d.angle()
        return best

func _fire_weapon(w: Dictionary) -> bool:
        var wid: String = w["id"]
        var wd: Dictionary = CSData.WEAPONS[wid]
        var tier: int = int(w["tier"])
        var mult := CSData.tier_mult(tier)
        var rng: float = float(wd["rng"]) * float(stats["range_m"])
        var count: int = int(wd["count"]) + int(mult["count"]) + int(stats["proj_add"])
        var target: Variant = _pick_target(rng)
        if target == null:
                return false
        var te: Dictionary = target
        var base_a: float = (te["pos"] - p_pos).angle()
        var shot_name: String = wd["shot"]
        var pierce: int = int(wd["pierce"])
        if int(stats["pierce_all"]) > 0:
                pierce = 99
        for i in count:
                var a := base_a
                if count > 1:
                        a += (float(i) - float(count - 1) * 0.5) * float(wd["spread"])
                var dmg: float = float(wd["dmg"]) * float(mult["dmg"]) * float(stats["dmg_m"])
                var kind: String = wd["proj"]
                if kind == "strike":
                        _orbital_strike(te["pos"], dmg, float(wd.get("aoe", 60.0)))
                        continue
                _spawn_bullet(p_pos + Vector2.from_angle(a) * 26.0, a, wd, dmg, pierce, tier)
        Jukebox.sfx(shot_name, -6.0, randf_range(0.94, 1.06))
        return true

func _pick_target(rng: float) -> Variant:
        var best: Variant = null
        var best_score := -1.0
        for e in enemies:
                var d: Vector2 = e["pos"] - p_pos
                var dist := d.length()
                if dist > rng:
                        continue
                var pr := 1.0
                if e.get("boss", false):
                        pr = 3.0
                elif e.get("elite", false):
                        pr = 2.0
                var sc := pr * 1000.0 - dist
                if sc > best_score:
                        best_score = sc
                        best = e
        return best

func _spawn_bullet(pos: Vector2, a: float, wd: Dictionary, dmg: float,
                pierce: int, tier: int) -> void:
        var kind: String = wd["proj"]
        var spr := Sprite2D.new()
        spr.texture = _t("proj_" + ("lance" if kind == "lance" else kind))
        spr.position = pos
        spr.rotation = a
        spr.z_index = 6
        world.add_child(spr)
        var b := {
                "pos": pos, "a": a, "spd": float(wd["pspd"]), "dmg": dmg,
                "pierce": pierce, "hit": {}, "range_left": float(wd["rng"])
                                * float(stats["range_m"]),
                "aoe": float(wd.get("aoe", 0.0)), "burn": bool(wd.get("burn", false))
                                or bool(stats["burn_hit"]),
                "chill": float(wd.get("chill", 0.0)), "kind": kind,
                "node": spr, "turn": false, "tier": tier,
        }
        if kind == "boomerang":
                b["home"] = null
        bullets.append(b)

func _orbital_strike(at: Vector2, dmg: float, aoe: float) -> void:
        zones.append({"kind": "strike", "pos": at, "t": 0.55, "max": 0.55,
                "dmg": dmg, "aoe": aoe})
        Jukebox.sfx("cs_flash", -8.0)

# ================================================================ allies
func _deploy_ally(aid: String, level: int) -> void:
        var ad: Dictionary = CSData.ALLIES[aid]
        var spr := Sprite2D.new()
        spr.texture = _t(ad["tex"])
        spr.scale = Vector2.ONE * 0.8
        spr.modulate = Color(0.8, 1.0, 0.9)
        spr.z_index = 8
        world.add_child(spr)
        allies.append({"id": aid, "level": level, "pos": p_pos
                        + Vector2.from_angle(randf() * TAU) * 50.0, "node": spr,
                        "cd": 0.0, "state": "", "t": 0.0})

func _ally_cap() -> int:
        return meta.ally_slots()

func _tick_allies(delta: float) -> void:
        for a in allies:
                var aid: String = a["id"]
                var lv: int = int(a["level"])
                a["t"] += delta
                match aid:
                        "drone":
                                # orbits the player, shoots 2/s
                                var ang: float = float(a["t"]) * 1.6
                                a["pos"] = p_pos + Vector2.from_angle(ang) * 62.0
                                a["cd"] -= delta * float(stats["ally_dmg"])
                                if a["cd"] <= 0.0 and not enemies.is_empty():
                                        a["cd"] = 0.5
                                        var tgt: Dictionary = _nearest_enemy(a["pos"], 520.0)
                                        if tgt != null:
                                                var dir: Vector2 = tgt["pos"] - a["pos"]
                                                _ally_bullet(a["pos"], dir.angle(),
                                                                4.0 + 2.0 * lv * float(stats["ally_dmg"]))
                        "turret":
                                # plants at its spot, sweeps 360
                                if a["pos"].distance_to(p_pos) > 260.0:
                                        a["state"] = "move"
                                if a["state"] == "move":
                                        a["pos"] = a["pos"].move_toward(p_pos
                                                        + Vector2.from_angle(a["t"]) * 70.0, 190.0 * delta)
                                        if a["pos"].distance_to(p_pos) < 160.0:
                                                a["state"] = ""
                                a["cd"] -= delta * float(stats["ally_dmg"])
                                if a["cd"] <= 0.0:
                                        a["cd"] = 0.42
                                        var tgt2: Dictionary = _nearest_enemy(a["pos"], 440.0)
                                        if tgt2 != null:
                                                var d2: Vector2 = tgt2["pos"] - a["pos"]
                                                _ally_bullet(a["pos"], d2.angle(),
                                                                6.0 + 3.0 * lv * float(stats["ally_dmg"]))
                        "guard":
                                # bodyblock: stands between the player and the horde, taunts
                                var threat := Vector2.ZERO
                                var tn := 0
                                for e in enemies:
                                        if e["pos"].distance_to(p_pos) < 140.0:
                                                threat += e["pos"]
                                                tn += 1
                                if tn > 0:
                                        a["pos"] = a["pos"].lerp(p_pos + (threat / float(tn) - p_pos).normalized() * 40.0,
                                                        6.0 * delta)
                                else:
                                        a["pos"] = a["pos"].lerp(p_pos + Vector2(40, 40), 4.0 * delta)
                        "medic":
                                a["pos"] = a["pos"].lerp(p_pos + Vector2(-40, -40), 4.0 * delta)
                                p_hp = minf(p_max_hp, p_hp + (2.0 + lv) * delta)
                        "bomber":
                                a["cd"] -= delta
                                if a["state"] == "dive":
                                        var dtgt: Dictionary = a["target"]
                                        if dtgt == null or not is_instance_valid(dtgt.get("node")) \
                                                        or dtgt.get("dead", false):
                                                a["state"] = ""
                                                a["t"] = 0.0
                                        else:
                                                a["pos"] = a["pos"].move_toward(dtgt["pos"], 420.0 * delta)
                                                if a["pos"].distance_to(dtgt["pos"]) < 26.0:
                                                        _boom_at(a["pos"], 70.0, (14.0 + 6.0 * lv)
                                                                        * float(stats["ally_dmg"]), true)
                                                        a["node"].visible = false
                                                        a["state"] = "dead"
                                                        a["t"] = 0.0
                                elif a["state"] == "dead":
                                        if a["t"] >= 5.0:
                                                a["state"] = ""
                                                a["pos"] = p_pos
                                                a["node"].visible = true
                                elif a["cd"] <= 0.0 and not enemies.is_empty():
                                        var tgt3: Dictionary = _nearest_enemy(a["pos"], 400.0)
                                        if tgt3 != null:
                                                a["state"] = "dive"
                                                a["target"] = tgt3
                                                a["cd"] = 8.0
                                elif a["state"] == "":
                                        a["pos"] = a["pos"].lerp(p_pos + Vector2(50, -50), 3.0 * delta)
                        "scout":
                                a["pos"] = a["pos"].lerp(p_pos + Vector2(0, 60), 3.0 * delta)
                                for e in enemies:
                                        if e["pos"].distance_to(p_pos) < 300.0:
                                                e["marked"] = true
                a["node"].position = a["pos"]

func _nearest_enemy(from: Vector2, rng: float) -> Variant:
        var best: Variant = null
        var bd := rng
        for e in enemies:
                var d: float = e["pos"].distance_to(from)
                if d < bd:
                        bd = d
                        best = e
        return best

func _ally_bullet(pos: Vector2, a: float, dmg: float) -> void:
        var spr := Sprite2D.new()
        spr.texture = _t("proj_bolt")
        spr.modulate = Color(0.7, 1, 0.85)
        spr.position = pos
        spr.rotation = a
        spr.z_index = 6
        world.add_child(spr)
        bullets.append({"pos": pos, "a": a, "spd": 620.0, "dmg": dmg, "pierce": 0,
                "hit": {}, "range_left": 420.0, "aoe": 0.0, "burn": false, "chill": 0.0,
                "kind": "bolt", "node": spr, "turn": false, "tier": 1})

# ================================================================ bullets
func _tick_bullets(delta: float) -> void:
        var dead := []
        for b in bullets:
                if b["kind"] == "boomerang":
                        _tick_boomerang(b, delta, dead)
                        continue
                var step: Vector2 = Vector2.from_angle(b["a"]) * float(b["spd"]) * delta
                b["pos"] += step
                b["range_left"] -= step.length()
                b["node"].position = b["pos"]
                if b["kind"] == "orb":
                        # THE GRAVITY WELL: drags enemies while it flies
                        for e in enemies:
                                if e["pos"].distance_to(b["pos"]) < 140.0:
                                        e["pos"] = e["pos"].move_toward(b["pos"], 160.0 * delta)
                if b["range_left"] <= 0.0:
                        if float(b["aoe"]) > 0.0:
                                _boom_at(b["pos"], float(b["aoe"]), float(b["dmg"]), false)
                        dead.append(b)
                        continue
                for e in enemies:
                        var key: int = e["uid"]
                        if b["hit"].has(key):
                                continue
                        var hit_r: float = float(e["size"]) * 0.5 * float(e.get("scale_m", 1.0)) + 6.0
                        if e["pos"].distance_to(b["pos"]) > hit_r:
                                continue
                        # THE TRI-SHIELD LAW: the rings eat the bullet first
                        if e.get("rings", null) != null:
                                var res: int = _ring_bullet(e, b)
                                if res == 1:
                                        b["hit"][key] = true
                                        continue          # carved a ring - the bullet died
                                elif res == 2:
                                        continue          # passed a window - no hit yet
                        b["hit"][key] = true
                        var dmg: float = float(b["dmg"])
                        if e.get("marked", false):
                                dmg *= 1.15
                        if e.get("chill_t", 0.0) > 0.0:
                                dmg *= 1.10
                        dmg *= float(e.get("hurt_m", 1.0))
                        var crit := randf() < float(stats["crit"])
                        if crit:
                                dmg *= float(stats["crit_mult"])
                                Jukebox.sfx("cs_crit", -8.0, 1.2)
                        _hurt_enemy(e, dmg, crit)
                        if b["burn"]:
                                e["burn_t"] = 3.0
                        if float(b["chill"]) > 0.0:
                                e["chill_t"] = float(b["chill"])
                        if float(b["aoe"]) > 0.0:
                                _boom_at(b["pos"], float(b["aoe"]), float(b["dmg"]) * 0.6, false)
                                dead.append(b)
                                break
                        if int(b["pierce"]) <= 0:
                                dead.append(b)
                                break
                        b["pierce"] = int(b["pierce"]) - 1
        for b2 in dead:
                b2["node"].queue_free()
                bullets.erase(b2)

func _tick_boomerang(b: Dictionary, delta: float, dead: Array) -> void:
        if not b["turn"]:
                var step: Vector2 = Vector2.from_angle(b["a"]) * float(b["spd"]) * delta
                b["pos"] += step
                b["range_left"] -= step.length()
                if b["range_left"] <= 0.0:
                        b["turn"] = true
                        b["hit"] = {}       # the return trip hits again
        else:
                var to_p: Vector2 = p_pos - b["pos"]
                if to_p.length() < 18.0:
                        dead.append(b)
                        return
                b["pos"] += to_p.normalized() * float(b["spd"]) * delta
        b["node"].position = b["pos"]
        b["node"].rotation += 14.0 * delta
        for e in enemies:
                var key: int = e["uid"]
                if b["hit"].has(key):
                        continue
                if e["pos"].distance_to(b["pos"]) < float(e["size"]) * 0.5 + 8.0:
                        b["hit"][key] = true
                        _hurt_enemy(e, float(b["dmg"]), false)

# ================================================================ enemies
var _uid := 0

func _spawn_enemy(kind: String, pos: Vector2, elite := false) -> Dictionary:
        var ed: Dictionary = CSData.ENEMIES[kind]
        var hp: float = float(ed["hp"]) * CSData.hp_scale(run_wave)
        var spd: float = float(ed["spd"]) * CSData.spd_scale(run_wave)
        var dmg: float = float(ed["dmg"]) * CSData.dmg_scale(run_wave)
        var scale_m := 1.0
        var affix := ""
        if elite:
                var keys := CSData.ELITE_AFFIX.keys()
                affix = keys[randi() % keys.size()]
                var ax: Dictionary = CSData.ELITE_AFFIX[affix]
                hp *= 1.6 * float(ax.get("hp", 1.0))
                spd *= float(ax.get("spd", 1.0))
                dmg *= 1.3 * float(ax.get("dmg", 1.0))
                scale_m = float(ax.get("scale", 1.35))
        # bosses keep their own spawner
        var spr := Sprite2D.new()
        spr.texture = _t(ed["tex"])
        spr.scale = Vector2.ONE * scale_m
        spr.position = pos
        spr.z_index = 5
        world.add_child(spr)
        _uid += 1
        var e := {
                "uid": _uid, "kind": kind, "name": String(ed["name"]),
                "hp": hp, "max_hp": hp, "spd": spd, "dmg": dmg,
                "size": float(ed["size"]), "pos": pos, "node": spr,
                "scale_m": scale_m, "elite": elite, "affix": affix,
                "xp": int(ed["xp"]), "score": int(ed["score"]),
                "burn_t": 0.0, "burn_tick": 0.0, "chill_t": 0.0,
                "marked": false, "hurt_m": 1.0, "flash": 0.0,
                "shoot_cd": randf_range(0.0, 1.0), "state": "walk", "st": 0.0,
                "boss": false, "gen": 0,
        }
        if affix == "armored":
                e["hurt_m"] = CSData.ELITE_AFFIX["armored"]["hurt"]
        if kind == "trishield":
                e["rings"] = _mk_rings([90.0, 70.0, 50.0])
        enemies.append(e)
        return e

func _mk_rings(radii: Array) -> Array:
        # the python law: radii, thickness 8, counter-rotating rad/frame speeds,
        # cracks stored as angle intervals in each ring's LOCAL rotating frame
        var arr := []
        var speeds := [0.05, 0.03, 0.01, 0.008]
        for i in radii.size():
                arr.append({"r": float(radii[i]), "rot": randf() * TAU,
                        "spd": float(speeds[i % speeds.size()]) * (1.0 if i % 2 == 0 else -1.0),
                        "cracks": []})
        return arr

## returns 0 = no ring contact, 1 = carved a ring (bullet dies),
## 2 = passed through a window (bullet continues inward)
func _ring_bullet(e: Dictionary, b: Dictionary) -> int:
        var d: float = b["pos"].distance_to(e["pos"])
        var rings: Array = e["rings"]
        for ring in rings:
                var band: float = absf(d - float(ring["r"]))
                if band > 4.0 + 4.0:
                        continue
                # the LOCAL angle: the crack bookkeeping rotates WITH the ring
                var world_a: float = (b["pos"] - e["pos"]).angle()
                var local_a: float = world_a - float(ring["rot"])
                local_a = fposmod(local_a, TAU)
                if _in_crack(ring["cracks"], local_a):
                        continue    # the window is open - the bullet flies inward
                # CARVE: a crack of the bullet's diameter in the local frame
                var halfw := atan(6.0 / maxf(10.0, float(ring["r"])))
                ring["cracks"] = _carve(ring["cracks"], local_a - halfw, local_a + halfw)
                Jukebox.sfx("cs_shield_crack", -6.0, randf_range(0.9, 1.2))
                return 1
        if d < float(rings[rings.size() - 1]["r"]) - 4.0:
                return 2    # inside the innermost ring: the core is exposed
        return 0

func _in_crack(cracks: Array, a: float) -> bool:
        for c in cracks:
                if float(c[0]) <= a and a <= float(c[1]):
                        return true
                # the wrap case: an interval crossing 0/TAU
                if float(c[0]) > float(c[1]) and (a >= float(c[0]) or a <= float(c[1])):
                        return true
        return false

func _carve(cracks: Array, a0: float, a1: float) -> Array:
        # add [a0,a1] (wrapped into 0..TAU) and merge overlaps - the python's
        # interval-subtraction law, inverted
        var ivs := []
        for c in cracks:
                ivs.append([float(c[0]), float(c[1])])
        if a0 < 0.0:
                ivs.append([fposmod(a0, TAU), TAU])
                ivs.append([0.0, a1])
        elif a1 > TAU:
                ivs.append([a0, TAU])
                ivs.append([0.0, fposmod(a1, TAU)])
        else:
                ivs.append([a0, a1])
        ivs.sort_custom(func(x, y): return float(x[0]) < float(y[0]))
        var out: Array = []
        for iv in ivs:
                if not out.is_empty() and float(iv[0]) <= float(out[out.size() - 1][1]) + 0.001:
                        out[out.size() - 1][1] = maxf(float(out[out.size() - 1][1]), float(iv[1]))
                else:
                        out.append(iv)
        return out

func _tick_rings(e: Dictionary, delta: float) -> void:
        # the rings rotate; the cracks ride along (the python's local-frame law)
        for ring in e["rings"]:
                ring["rot"] = fposmod(float(ring["rot"]) + float(ring["spd"]) * 60.0
                                * delta, TAU)
        # THE PUSH-OUT LAW: the player cannot stand inside a ring
        var d: float = p_pos.distance_to(e["pos"])
        for ring in e["rings"]:
                var r: float = float(ring["r"])
                if absf(d - r) < 10.0 + PLAYER_R:
                        var away: Vector2 = (p_pos - e["pos"]).normalized()
                        p_pos = e["pos"] + away * (r + 10.0 + PLAYER_R)
                        d = p_pos.distance_to(e["pos"])

func _tick_enemies(delta: float) -> void:
        var to_kill := []
        for e in enemies:
                if e.get("dead", false):
                        continue
                e["st"] += delta
                # statuses
                if e["burn_t"] > 0.0:
                        e["burn_t"] -= delta
                        e["burn_tick"] -= delta
                        if e["burn_tick"] <= 0.0:
                                e["burn_tick"] = 0.5
                                _hurt_enemy(e, 1.0, false, true)
                if e["chill_t"] > 0.0:
                        e["chill_t"] -= delta
                var slow := 0.8 if e["chill_t"] > 0.0 else 1.0
                var spd: float = float(e["spd"]) * slow
                var to_p: Vector2 = p_pos - e["pos"]
                var dist: float = to_p.length()
                var kind: String = e["kind"]
                # ===== the per-kind AI =====
                if e.get("boss", false):
                        _boss_ai(e, delta, to_p, dist)
                elif kind == "spitter":
                        # KEEPS DISTANCE and actually shoots (the python's ranged never
                        # fired - fixed, the GDD law)
                        var keep: float = 260.0
                        var want: Vector2 = to_p.normalized()
                        if dist > keep + 40.0:
                                e["pos"] += want * spd * delta
                        elif dist < keep - 40.0:
                                e["pos"] -= want * spd * delta
                        else:
                                e["pos"] += want.orthogonal() * spd * 0.6 * delta
                        e["shoot_cd"] -= delta
                        if e["shoot_cd"] <= 0.0:
                                e["shoot_cd"] = 2.2
                                _enemy_bullet(e["pos"], to_p.angle(), float(e["dmg"]))
                elif kind == "charger":
                        if e["state"] == "walk":
                                e["pos"] += to_p.normalized() * spd * delta
                                if dist < 300.0:
                                        e["state"] = "wind"
                                        e["st"] = 0.0
                        elif e["state"] == "wind":
                                if e["st"] >= 0.6:
                                        e["state"] = "dash"
                                        e["st"] = 0.0
                                        e["dash_dir"] = to_p.normalized()
                        elif e["state"] == "dash":
                                e["pos"] += Vector2(e["dash_dir"]) * spd * 3.0 * delta
                                if e["st"] >= 0.5:
                                        e["state"] = "rest"
                                        e["st"] = 0.0
                        elif e["state"] == "rest":
                                if e["st"] >= 0.8:
                                        e["state"] = "walk"
                elif kind == "orbiter":
                        if e["state"] == "walk":
                                # orbit the player at 180px
                                var ang: float = (e["pos"] - p_pos).angle() + 1.9 * delta
                                e["pos"] = p_pos + Vector2.from_angle(ang) * 180.0
                                if e["st"] > randf_range(3.0, 5.0):
                                        e["state"] = "dive"
                                        e["st"] = 0.0
                        elif e["state"] == "dive":
                                e["pos"] += to_p.normalized() * spd * 2.4 * delta
                                if dist < 26.0 or e["st"] > 1.6:
                                        e["state"] = "walk"
                                        e["st"] = 0.0
                elif kind == "boomling":
                        if dist < 90.0 and e["state"] != "fuse":
                                e["state"] = "fuse"
                                e["st"] = 0.0
                        if e["state"] == "fuse":
                                spd = 0.0
                                if e["st"] >= 0.7:
                                        _boom_at(e["pos"], 60.0, 25.0 * CSData.dmg_scale(run_wave), true)
                                        to_kill.append(e)
                                        continue
                        else:
                                e["pos"] += to_p.normalized() * spd * delta
                else:
                        # the chase law (the python base)
                        e["pos"] += to_p.normalized() * spd * delta
                # ===== the auras =====
                if kind == "wraith" or e.get("aura", 0.0) > 0.0:
                        # 250px damage aura, 15 per 1s tick while inside (the python law)
                        if dist < float(e.get("aura", 250.0)) and p_iframe <= 0.0:
                                e["aura_tick"] = float(e.get("aura_tick", 0.0)) - delta
                                if e["aura_tick"] <= 0.0:
                                        e["aura_tick"] = 1.0
                                        _hurt_player(float(e.get("aura_dps", 15.0)), e)
                if kind == "mender":
                        # 500px heal: +10 to every OTHER enemy every 0.5s (the python law)
                        e["heal_tick"] = float(e.get("heal_tick", 0.0)) - delta
                        if e["heal_tick"] <= 0.0:
                                e["heal_tick"] = 0.5
                                for o in enemies:
                                        if o == e or o.get("dead", false):
                                                continue
                                        if o["pos"].distance_to(e["pos"]) < 500.0:
                                                o["hp"] = minf(float(o["max_hp"]), float(o["hp"]) + 10.0)
                                                _heal_flash(o)
                if e.get("rings", null) != null:
                        _tick_rings(e, delta)
                # ===== contact (the python law: the enemy's REMAINING HP hits you,
                # then the enemy dies on your skin) =====
                var touch_r: float = float(e["size"]) * 0.5 * float(e.get("scale_m", 1.0)) + PLAYER_R - 6.0
                if e.get("boss", false):
                        touch_r = float(e["size"]) * 0.5 + PLAYER_R - 10.0
                if dist < touch_r and p_iframe <= 0.0:
                        if e.get("boss", false):
                                _hurt_player(float(e["dmg"]), e)
                        else:
                                var raw := float(e["hp"])
                                var contact := clampf(raw, 1.0, 80.0) * float(stats["contact_cut"])
                                _hurt_player(contact, e)
                                to_kill.append(e)   # the splatter kills the enemy too
                                continue
                # the flash decay
                if e["flash"] > 0.0:
                        e["flash"] -= delta
                        e["node"].modulate = Color(3, 3, 3) if e["flash"] > 0.0 \
                                        else Color(1, 1, 1)
        # the flocking separation (the python law: 100px, force (1-d/100)*0.5)
        if enemies.size() <= 80:
                for i in enemies.size():
                        var a: Dictionary = enemies[i]
                        if a.get("dead", false) or a.get("boss", false):
                                continue
                        var push := Vector2.ZERO
                        for j in enemies.size():
                                if i == j:
                                        continue
                                var b: Dictionary = enemies[j]
                                var dd: Vector2 = a["pos"] - b["pos"]
                                var dl := dd.length()
                                if dl < 100.0 and dl > 0.01:
                                        push += dd / dl * (100.0 - dl) / 100.0
                        a["pos"] += push * 0.5 * 60.0 * delta
                        a["pos"] += Vector2(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3)) * 60.0 * delta
        for e2 in to_kill:
                _kill_enemy(e2, false)

func _enemy_bullet(pos: Vector2, a: float, dmg: float) -> void:
        var spr := Sprite2D.new()
        spr.texture = _t("proj_spit")
        spr.position = pos
        spr.rotation = a
        spr.z_index = 6
        world.add_child(spr)
        ebullets.append({"pos": pos, "a": a, "spd": 300.0, "dmg": dmg,
                "node": spr, "life": 3.0})

func _tick_ebullets(delta: float) -> void:
        var dead := []
        for b in ebullets:
                b["pos"] += Vector2.from_angle(b["a"]) * float(b["spd"]) * delta
                b["life"] -= delta
                b["node"].position = b["pos"]
                if b["life"] <= 0.0:
                        dead.append(b)
                        continue
                if b["pos"].distance_to(p_pos) < PLAYER_R + 6.0:
                        _hurt_player(float(b["dmg"]), null)
                        dead.append(b)
        for b2 in dead:
                b2["node"].queue_free()
                ebullets.erase(b2)

func _boss_ai(e: Dictionary, delta: float, to_p: Vector2, dist: float) -> void:
        var b: Dictionary = e["bdata"]
        if b.get("self_mend", 0.0) > 0.0:
                e["hp"] = minf(float(e["max_hp"]), float(e["hp"]) + float(b["self_mend"]) * delta)
        if b.get("burst", false) and e["state"] != "burst":
                e["burst_cd"] = float(e.get("burst_cd", 3.0)) - delta
                if e["burst_cd"] <= 0.0:
                        e["burst_cd"] = 4.0
                        e["state"] = "burst"
                        e["st"] = 0.0
                        # radial bursts THROUGH her own cracks
                        var n := 14
                        for i in n:
                                _enemy_bullet(e["pos"], float(i) / float(n) * TAU, float(e["dmg"]) * 0.6)
                        Jukebox.sfx("cs_boom", -8.0, 0.8)
        # the pattern families
        if b.get("slam", false):
                e["slam_cd"] = float(e.get("slam_cd", 3.5)) - delta
                if e["slam_cd"] <= 0.0 and dist < 260.0:
                        e["slam_cd"] = 5.0
                        zones.append({"kind": "slam", "pos": p_pos, "t": 0.8, "max": 0.8,
                                "dmg": float(e["dmg"]), "aoe": 120.0})
        if b.get("charge", false) or b.get("triple_charge", false):
                e["charge_cd"] = float(e.get("charge_cd", 2.0)) - delta
                if e["state"] == "walk" and e["charge_cd"] <= 0.0 and dist < 500.0:
                        e["state"] = "wind"
                        e["st"] = 0.0
                        e["charges_left"] = 3 if b.get("triple_charge", false) else 1
                elif e["state"] == "wind":
                        e["spd_m"] = 0.0
                        if e["st"] >= 0.55:
                                e["state"] = "dash"
                                e["st"] = 0.0
                                e["dash_dir"] = to_p.normalized()
                elif e["state"] == "dash":
                        e["pos"] += Vector2(e["dash_dir"]) * float(e["spd"]) * 3.4 * delta
                        if e["st"] >= 0.45:
                                e["charges_left"] = int(e.get("charges_left", 1)) - 1
                                e["tp_count"] = int(e.get("tp_count", 0)) + 1
                                if int(e.get("teleport", 0)) > 0 \
                                                and e["tp_count"] % int(e["teleport"]) == 0:
                                        # SPUD REAPER: teleport BEHIND the player
                                        e["pos"] = p_pos - to_p.normalized() * 140.0
                                if int(e["charges_left"]) > 0:
                                        e["state"] = "wind"
                                        e["st"] = 0.4
                                else:
                                        e["state"] = "walk"
                                        e["charge_cd"] = 3.2
        if b.get("summon", "") != "":
                e["summon_cd"] = float(e.get("summon_cd", 8.0)) - delta
                var hp_frac := float(e["hp"]) / float(e["max_hp"])
                if e["summon_cd"] <= 0.0 and (hp_frac < 0.66 or hp_frac < 0.33):
                        e["summon_cd"] = 9.0
                        for i in int(b["summon_n"]):
                                _spawn_enemy(String(b["summon"]), e["pos"]
                                                + Vector2.from_angle(randf() * TAU) * 70.0)
                        Jukebox.sfx("cs_boss_roar", -4.0)
        if e["state"] != "dash" and e["state"] != "wind":
                e["pos"] += to_p.normalized() * float(e["spd"]) * delta
        # the aura (the reaper's trail)
        if e.get("aura", 0.0) > 0.0 and dist < float(e["aura"]) and p_iframe <= 0.0:
                e["aura_tick"] = float(e.get("aura_tick", 0.0)) - delta
                if e["aura_tick"] <= 0.0:
                        e["aura_tick"] = 1.0
                        _hurt_player(float(e["aura_dps"]), e)

func _spawn_boss(wave: int) -> void:
        var cycle := int((wave - 1) / CSData.BOSS_CYCLE)   # 0-based
        var bid: String = CSData.BOSS_ORDER[cycle % CSData.BOSS_ORDER.size()]
        var bd: Dictionary = CSData.BOSSES[bid]
        var m := pow(CSData.BOSS_CYCLE_MULT, float(cycle))
        var e := _spawn_enemy("blab", p_pos + Vector2(0, -420), false)
        # rebuild the dict as the boss (a blab shell keeps the AI happy)
        e["kind"] = bid
        e["name"] = String(bd["name"])
        e["hp"] = float(bd["hp"]) * m
        e["max_hp"] = e["hp"]
        e["spd"] = float(bd["spd"])
        e["dmg"] = float(bd["dmg"]) * m
        e["size"] = float(bd["size"])
        e["xp"] = int(bd["xp"])
        e["score"] = int(bd["score"]) + cycle * CSData.BOSS_CYCLE_SCORE
        e["coins_drop"] = int(ceil(float(bd["coins"]) * m))
        e["boss"] = true
        e["bdata"] = bd
        e["node"].texture = _t(bd["tex"])
        e["node"].scale = Vector2.ONE * 1.6
        if bd.get("rings", null) != null:
                e["rings"] = _mk_rings(bd["rings"])
        boss_alive = true
        Jukebox.sfx("cs_boss_roar", -2.0)
        Jukebox.music("res://assets/audio/music/cs_boss.ogg")
        _banner("%s ARRIVES!" % String(bd["name"]), false)

# ================================================================ damage
func _hurt_enemy(e: Dictionary, dmg: float, crit := false, silent := false) -> void:
        if e.get("dead", false):
                return
        e["hp"] = float(e["hp"]) - dmg
        e["flash"] = 0.06
        if not silent:
                _dmg_number(e["pos"], dmg, crit)
        if float(stats["lifesteal"]) > 0.0 and not silent:
                p_hp = minf(p_max_hp, p_hp + dmg * float(stats["lifesteal"]))
        if e["hp"] <= 0.0:
                _kill_enemy(e, true)

func _kill_enemy(e: Dictionary, drops: bool) -> void:
        if e.get("dead", false):
                return
        e["dead"] = true
        run_kills += 1
        # THE SCORE LAW: the kill is the score
        var sc := int(e["score"])
        if e.get("elite", false):
                sc += CSData.ELITE_SCORE
        add_score(sc)
        # the death burst (the python 8-particle law, grown)
        _death_burst(e)
        Jukebox.sfx("cs_kill_big" if e.get("boss", false) else "cs_hit", -7.0,
                        randf_range(0.8, 1.3) if not e.get("boss", false) else 0.7)
        if drops:
                # the XP gem (the double-duty ledger banks it)
                _drop_pickup("xp", e["pos"], int(e["xp"]) * 2)
                # the coin drop: 8% (elites always, bosses per their table)
                var coin_m: float = float(stats["coin_m"])
                if e.get("coins_drop", 0) > 0:
                        for i in int(e["coins_drop"]):
                                _drop_pickup("coin", e["pos"] + Vector2.from_angle(randf() * TAU) * 20.0,
                                                maxi(1, int(round(coin_m))))
                elif e.get("elite", false):
                        for i in randi_range(3, 6):
                                _drop_pickup("coin", e["pos"] + Vector2.from_angle(randf() * TAU) * 20.0,
                                                maxi(1, int(round(coin_m))))
                elif randf() < 0.08:
                        _drop_pickup("coin", e["pos"], maxi(1, int(round(1 * coin_m))))
                if randf() < 0.06:
                        _drop_pickup("heart", e["pos"], 15)
                # the death-splits (the python laws)
                var kind: String = e["kind"]
                if kind == "brood":
                        for i in 2:
                                var m := _spawn_enemy("minion", e["pos"] + Vector2(-20 + i * 40, 10))
                                m["hp"] *= 1.0
                elif kind == "splitter":
                        var gen: int = int(e.get("gen", 0))
                        if gen < 2:
                                for i in 2:
                                        var s := _spawn_enemy("splitter", e["pos"]
                                                        + Vector2.from_angle(randf() * TAU) * 24.0)
                                        s["hp"] = float(e["max_hp"]) * 0.3
                                        s["max_hp"] = s["hp"]
                                        s["spd"] = float(s["spd"]) * 1.10
                                        s["gen"] = gen + 1
                                        s["size"] = float(s["size"]) * 0.75
                                        s["node"].scale = Vector2.ONE * 0.75
                # the vampiric elite drinks on touch (handled in contact)
        if e.get("boss", false):
                boss_alive = false
                Jukebox.sfx("cs_boom_big", -2.0)
                var th: Dictionary = CSData.THEMES[theme_id]
                Jukebox.music(th["night_music"] if night else th["day_music"])
        enemies.erase(e)
        e["node"].queue_free()

func _hurt_player(dmg: float, src: Variant) -> void:
        if p_iframe > 0.0 or over or phase != "play":
                return
        var actual: float = maxf(1.0, dmg - float(stats["armor"]))
        p_hp -= actual
        p_iframe = IFRAME
        _dmg_number(p_pos, actual, false, Color(1, 0.5, 0.5))
        Jukebox.sfx("cs_hurt", -4.0)
        if src != null and src is Dictionary and (src as Dictionary).get("affix", "") == "vampiric":
                var s: Dictionary = src
                s["hp"] = minf(float(s["max_hp"]), float(s["hp"]) + actual * 0.2)
        if p_hp <= 0.0:
                # SECOND WIND (the tree's d4)
                if meta.tree_node("d4") and not second_wind_used:
                        second_wind_used = true
                        p_hp = p_max_hp * 0.5
                        _banner("SECOND WIND!", false)
                        Jukebox.sfx("cs_levelup", -2.0)
                        _boom_at(p_pos, 260.0, 40.0, true)
                        return
                _die()

# ================================================================ pickups
func _drop_pickup(kind: String, pos: Vector2, v: int) -> void:
        var spr := Sprite2D.new()
        spr.texture = _t(kind)
        spr.position = pos
        spr.z_index = 4
        world.add_child(spr)
        pickups.append({"kind": kind, "v": v, "pos": pos, "node": spr, "bob": randf() * TAU})

func _tick_pickups(delta: float) -> void:
        var dead := []
        var magnet: float = MAGNET_BASE * float(stats["magnet"])
        for pk in pickups:
                pk["bob"] += delta * 4.0
                pk["node"].position = pk["pos"] + Vector2(0, sin(pk["bob"]) * 3.0)
                var to_p: Vector2 = p_pos - pk["pos"]
                var d := to_p.length()
                if d < magnet:
                        pk["pos"] += to_p.normalized() * 340.0 * delta
                if d < PLAYER_R + 12.0:
                        match String(pk["kind"]):
                                "xp":
                                        run_xp += int(pk["v"])
                                        Jukebox.sfx("cs_xp", -10.0, randf_range(0.95, 1.1))
                                        while run_xp >= CSData.xp_for_run_level(run_level):
                                                run_xp -= CSData.xp_for_run_level(run_level)
                                                run_level += 1
                                                pending_levels += 1
                                        if pending_levels > 0:
                                                _level_draft_open()
                                "coin":
                                        run_ccoins += int(pk["v"])
                                        Jukebox.sfx("cs_coin", -8.0)
                                "heart":
                                        p_hp = minf(p_max_hp, p_hp + float(pk["v"]))
                                        Jukebox.sfx("cs_heal", -6.0)
                        dead.append(pk)
        for pk2 in dead:
                pk2["node"].queue_free()
                pickups.erase(pk2)

func _tick_zones(delta: float) -> void:
        var dead := []
        for z in zones:
                z["t"] -= delta
                if z["t"] <= 0.0:
                        if z["kind"] == "strike":
                                _boom_at(z["pos"], float(z["aoe"]), float(z["dmg"]), true)
                        elif z["kind"] == "slam":
                                if p_pos.distance_to(z["pos"]) < float(z["aoe"]):
                                        _hurt_player(float(z["dmg"]), null)
                                _boom_at(z["pos"], float(z["aoe"]), 0.0, false)
                        dead.append(z)
        for z2 in dead:
                zones.erase(z2)

## the explosion law: damages enemies (and the player when `hits_player`)
func _boom_at(pos: Vector2, r: float, dmg: float, hits_player: bool) -> void:
        for e in enemies.duplicate():
                if e["pos"].distance_to(pos) < r + float(e["size"]) * 0.5:
                        _hurt_enemy(e, dmg)
        if hits_player and p_pos.distance_to(pos) < r + PLAYER_R:
                _hurt_player(dmg * 0.8, null)
        _shockwave(pos, r)
        Jukebox.sfx("cs_boom", -4.0)

# ================================================================ waves
func _tick_waves(delta: float) -> void:
        if phase != "play":
                return
        wave_clock -= delta
        _spawn_stream(delta)
        if wave_clock <= 0.0 and not boss_alive:
                _wave_clear()

var _spawn_clock := 0.0
var _burst_clock := 0.0

func _begin_wave(w: int) -> void:
        run_wave = w
        phase = "play"
        var boss_wave := w % CSData.BOSS_CYCLE == 0
        wave_clock = CSData.BOSS_WAVE_SECS if boss_wave else CSData.WAVE_SECS
        _spawn_clock = 0.0
        _burst_clock = 2.0
        if boss_wave:
                _spawn_boss(w)
                wave_spawning = true
        else:
                Jukebox.sfx("cs_wave_horn", -4.0)
                _banner("WAVE %d" % w, true)

func _spawn_stream(delta: float) -> void:
        # the spawn law: interval stream + a burst every 5s (the GDD 3.1)
        _spawn_clock -= delta
        _burst_clock -= delta
        if _spawn_clock <= 0.0:
                _spawn_clock = CSData.spawn_interval(run_wave)
                _spawn_one()
        if _burst_clock <= 0.0:
                _burst_clock = 5.0
                _spawn_burst(CSData.burst_size(run_wave))

func _spawn_one() -> void:
        var pool := CSData.pool_for_wave(run_wave)
        var kind: String = pool[randi() % pool.size()]
        _spawn_enemy(kind, _spawn_pos(), randf() < CSData.elite_chance(run_wave))

func _spawn_burst(n: int) -> void:
        for i in n:
                _spawn_one()

func _spawn_pos() -> Vector2:
        # off the camera view: a ring around the player clamped to the arena+80
        var a := randf() * TAU
        var r := randf_range(620.0, 780.0)
        var p := p_pos + Vector2.from_angle(a) * r
        return Vector2(clampf(p.x, ARENA.position.x - 80.0, ARENA.end.x + 80.0),
                        clampf(p.y, ARENA.position.y - 80.0, ARENA.end.y + 80.0))

func _wave_clear() -> void:
        # leftover enemies become XP gems (the break cleans the field)
        for e in enemies.duplicate():
                _drop_pickup("xp", e["pos"], int(e["xp"]) * 2)
                e["node"].queue_free()
                enemies.erase(e)
        for b in ebullets:
                b["node"].queue_free()
        ebullets.clear()
        for b2 in bullets:
                b2["node"].queue_free()
        bullets.clear()
        p_hp = minf(p_max_hp, p_hp + CSData.WAVE_HEAL)
        var bonus := maxi(1, int(round((CSData.WAVE_COINS + 2 * run_wave)
                        * float(stats["coin_m"]))))
        run_ccoins += bonus
        phase = "break"
        _banner("WAVE %d CLEAR  +%d CC" % [run_wave, bonus], true)
        Jukebox.sfx("cs_levelup", -4.0)
        run_wave += 1
        _wave_break_open()

# ================================================================ the breaks
## the wave-break flow: clear -> the WAVE DRAFT (1 of 3, with teeth) ->
## the WAVE SHOP -> the next wave. The XP-level drafts interrupt any time.
var _draft_cards: Array = []
var _break_in_shop := false

func _wave_break_open() -> void:
        _break_in_shop = false
        if pending_levels > 0:
                _level_draft_open()      # levels first (they queue)
                return
        _wave_draft_open()

func _after_draft_or_shop() -> void:
        if pending_levels > 0:
                _level_draft_open()
                return
        if not _break_in_shop:
                _break_in_shop = true
                _wave_shop_open()
                return
        # the break is done - the next wave walks in
        _close_all_sheets()
        _begin_wave(run_wave)

# ------------------------------------------------------------- wave draft
func _wave_draft_open() -> void:
        _draft_cards = _roll_wave_drafts(3)
        _open_sheet(func(box: VBoxContainer): _build_draft(box), 0.0)

func _roll_wave_drafts(n: int) -> Array:
        # weighted pick without repeats
        var pool := []
        for d in CSData.WAVE_DRAFTS:
                pool.append({"d": d, "w": int(d["w"])})
        var out := []
        for i in n:
                var total := 0
                for p in pool:
                        total += int(p["w"])
                var r := randi() % total
                for p in pool:
                        r -= int(p["w"])
                        if r < 0:
                                out.append(p["d"])
                                pool.erase(p)
                                break
        return out

func _build_draft(box: VBoxContainer) -> void:
        var t := Label.new()
        t.text = "WAVE %d CLEARED - CHOOSE ONE" % (run_wave - 1)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        t.add_theme_font_size_override("font_size", 20)
        t.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
        box.add_child(t)
        var sub := Label.new()
        sub.text = "every card GIVES something - most TAKE something back"
        sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sub.add_theme_font_size_override("font_size", 12)
        sub.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9))
        box.add_child(sub)
        var row := HBoxContainer.new()
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        row.add_theme_constant_override("separation", 12)
        box.add_child(row)
        for d in _draft_cards:
                row.add_child(_draft_card(d))
        var skip := Button.new()
        skip.text = "SKIP - take nothing"
        skip.add_theme_font_size_override("font_size", 13)
        skip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        skip.pressed.connect(func(): _after_draft_or_shop())
        box.add_child(skip)

func _draft_card(d: Dictionary) -> Button:
        var b := Button.new()
        b.custom_minimum_size = Vector2(240, 130)
        var st := StyleBoxFlat.new()
        st.bg_color = Color(0.14, 0.12, 0.18, 0.97)
        st.corner_radius_top_left = 12
        st.corner_radius_top_right = 12
        st.corner_radius_bottom_left = 12
        st.corner_radius_bottom_right = 12
        st.set_border_width_all(2)
        st.border_color = Color(0.35, 0.6, 1.0) if (d["down"] as Dictionary).is_empty() \
                        else Color(1, 0.5, 0.4)
        b.add_theme_stylebox_override("normal", st)
        var vb := VBoxContainer.new()
        vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.set_anchors_preset(Control.PRESET_FULL_RECT)
        vb.offset_left = 8
        vb.offset_top = 10
        vb.offset_right = -8
        b.add_child(vb)
        var up := Label.new()
        up.text = d["t"]
        up.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        up.add_theme_font_size_override("font_size", 17)
        up.add_theme_color_override("font_color", Color(0.55, 1, 0.65))
        vb.add_child(up)
        var dn := Label.new()
        dn.text = d["d"]
        dn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        dn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        dn.add_theme_font_size_override("font_size", 13)
        dn.add_theme_color_override("font_color", Color(1, 0.55, 0.5) \
                        if not (d["down"] as Dictionary).is_empty() else Color(0.6, 0.8, 0.7))
        vb.add_child(dn)
        b.pressed.connect(func():
                _apply_draft(d)
                Jukebox.sfx("cs_draft", -4.0)
                _close_all_sheets()
                _after_draft_or_shop())
        return b

func _apply_draft(d: Dictionary) -> void:
        for k in d["up"]:
                _apply_stat(String(k), d["up"][k])
        for k2 in d["down"]:
                _apply_stat(String(k2), d["down"][k2])

func _apply_stat(k: String, v: Variant) -> void:
        match k:
                "dmg": stats["dmg_m"] = float(stats["dmg_m"]) + float(v)
                "spd": stats["spd_m"] = float(stats["spd_m"]) + float(v)
                "aspeed": stats["aspeed_m"] = float(stats["aspeed_m"]) + float(v)
                "range": stats["range_m"] = float(stats["range_m"]) + float(v)
                "armor": stats["armor"] = int(stats["armor"]) + int(v)
                "regen": stats["regen"] = float(stats["regen"]) + float(v)
                "crit": stats["crit"] = float(stats["crit"]) + float(v)
                "hp":
                        stats["hp_add"] = float(stats.get("hp_add", 0.0)) + float(v)
                        p_max_hp = _max_hp()
                        p_hp = clampf(p_hp + maxf(0.0, float(v)), 1.0, p_max_hp)
                "proj": stats["proj_add"] = int(stats["proj_add"]) + int(v)

# ------------------------------------------------------------ level draft
func _level_draft_open() -> void:
        _open_sheet(func(box: VBoxContainer): _build_level_draft(box), 0.0)

func _build_level_draft(box: VBoxContainer) -> void:
        var t := Label.new()
        t.text = "LEVEL %d - THE TREE OFFERS" % run_level
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        t.add_theme_font_size_override("font_size", 20)
        t.add_theme_color_override("font_color", Color(0.5, 0.9, 1))
        box.add_child(t)
        var row := HBoxContainer.new()
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        row.add_theme_constant_override("separation", 12)
        box.add_child(row)
        # 3 distinct picks from the LEVEL pool
        var pool := CSData.LEVEL_DRAFTS.duplicate()
        pool.shuffle()
        var picks := pool.slice(0, 3)
        for d in picks:
                var b := Button.new()
                b.custom_minimum_size = Vector2(220, 96)
                var st := StyleBoxFlat.new()
                st.bg_color = Color(0.1, 0.14, 0.2, 0.97)
                st.set_border_width_all(2)
                st.border_color = Color(0.4, 0.75, 1.0)
                st.corner_radius_top_left = 12
                st.corner_radius_top_right = 12
                st.corner_radius_bottom_left = 12
                st.corner_radius_bottom_right = 12
                b.add_theme_stylebox_override("normal", st)
                var l := Label.new()
                l.text = d["t"]
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                l.add_theme_font_size_override("font_size", 15)
                l.set_anchors_preset(Control.PRESET_CENTER)
                l.mouse_filter = Control.MOUSE_FILTER_IGNORE
                b.add_child(l)
                var dd: Dictionary = d
                b.pressed.connect(func():
                        _apply_stat(String(dd["k"]), dd["v"])
                        pending_levels -= 1
                        Jukebox.sfx("cs_levelup", -4.0)
                        _close_all_sheets()
                        if phase == "break":
                                _after_draft_or_shop())
                row.add_child(b)

# ============================================================== wave shop
func _shop_button() -> void:
        if phase == "play":
                _toast_show("the shop opens at the wave break - hold on!")
                return
        _wave_shop_open()

func _wave_shop_open() -> void:
        _open_sheet(func(box: VBoxContainer): _build_wave_shop(box), 0.0)

func _build_wave_shop(box: VBoxContainer) -> void:
        var t := Label.new()
        t.text = "WAVE SHOP  -  %d in-run coins" % run_ccoins
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        t.add_theme_font_size_override("font_size", 19)
        t.add_theme_color_override("font_color", Color(1, 0.82, 0.3))
        box.add_child(t)
        # THE WEAPON OFFERS: owned types first, T1 buys (tier caps apply)
        var sec := Label.new()
        sec.text = "- WEAPONS -"
        sec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sec.add_theme_font_size_override("font_size", 12)
        sec.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
        box.add_child(sec)
        var disc: float = meta.shop_discount()
        var owned_ids := []
        for wid in CSData.WEAPON_ORDER:
                if meta.has_weapon(wid):
                        owned_ids.append(wid)
        # 3 offers: prefer owned types, fall back to the rest
        var offers := owned_ids.duplicate()
        if offers.size() < 3:
                for wid in CSData.WEAPON_ORDER:
                        if not offers.has(wid):
                                offers.append(wid)
                        if offers.size() >= 3:
                                break
        offers = offers.slice(0, 3)
        var wrow := HBoxContainer.new()
        wrow.alignment = BoxContainer.ALIGNMENT_CENTER
        wrow.add_theme_constant_override("separation", 10)
        box.add_child(wrow)
        for wid in offers:
                var price := int(round(CSData.weapon_price(wid, 1) * disc))
                wrow.add_child(_buy_card(CSData.WEAPONS[wid]["name"], price,
                                "T1 - own it forever (GogaShop wallet)",
                                func(): _wave_buy_weapon(wid, price)))
        # THE CONSUMABLES
        var sec2 := Label.new()
        sec2.text = "- SUPPLIES -"
        sec2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sec2.add_theme_font_size_override("font_size", 12)
        sec2.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
        box.add_child(sec2)
        var crow := HBoxContainer.new()
        crow.alignment = BoxContainer.ALIGNMENT_CENTER
        crow.add_theme_constant_override("separation", 10)
        box.add_child(crow)
        for cid in CSData.CONSUMABLES:
                var cd: Dictionary = CSData.CONSUMABLES[cid]
                var price2 := int(round(int(cd["price"]) * disc))
                crow.add_child(_buy_card(cd["name"], price2, cd["desc"],
                                func(): _wave_buy_consumable(cid, price2)))
        # THE ALLIES (owned allies deploy / merge here - the owner's law)
        if not (meta.d["owned_allies"] as Array).is_empty():
                var sec3 := Label.new()
                sec3.text = "- ALLIES -"
                sec3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                sec3.add_theme_font_size_override("font_size", 12)
                sec3.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
                box.add_child(sec3)
                var arow := HBoxContainer.new()
                arow.alignment = BoxContainer.ALIGNMENT_CENTER
                arow.add_theme_constant_override("separation", 10)
                box.add_child(arow)
                for aid in meta.d["owned_allies"]:
                        var deployed := _allies_deployed(aid)
                        var price3 := int(round(CSData.ally_level_price(aid, deployed + 1) * disc))
                        arow.add_child(_buy_card(CSData.ALLIES[aid]["name"], price3,
                                        "deploy / raise to LV%d" % (deployed + 1),
                                        func(): _wave_buy_ally(aid, price3)))
        # THE MERGES (only when the WEAPON LAB is learned - the owner's law)
        if meta.merging_learned():
                var mrow := HBoxContainer.new()
                mrow.alignment = BoxContainer.ALIGNMENT_CENTER
                mrow.add_theme_constant_override("separation", 10)
                box.add_child(mrow)
                var pairs := _merge_pairs()
                if pairs.is_empty():
                        var none := Label.new()
                        none.text = "no merge pairs on the shelf (two same weapons, same tier)"
                        none.add_theme_font_size_override("font_size", 12)
                        none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        mrow.add_child(none)
                for pr in pairs.slice(0, 3):
                        var cost := int(round(float(pr["cost"]) * meta.merge_discount()))
                        mrow.add_child(_buy_card("MERGE: " + CSData.WEAPONS[pr["wid"]]["name"],
                                        cost, "T%d + T%d -> T%d (two copies consumed)"
                                        % [pr["tier"], pr["tier"], pr["tier"] + 1],
                                        func(): _wave_buy_merge(pr, cost)))
        var go := Button.new()
        go.text = "NEXT WAVE >"
        go.add_theme_font_size_override("font_size", 17)
        go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        go.pressed.connect(func(): _after_draft_or_shop())
        box.add_child(go)

func _buy_card(name_txt: String, price: int, sub_txt: String, cb: Callable) -> Button:
        var b := Button.new()
        b.custom_minimum_size = Vector2(190, 84)
        var st := StyleBoxFlat.new()
        st.bg_color = Color(0.12, 0.1, 0.15, 0.97)
        st.set_border_width_all(2)
        st.border_color = Color(0.85, 0.65, 0.2)
        st.corner_radius_top_left = 10
        st.corner_radius_top_right = 10
        st.corner_radius_bottom_left = 10
        st.corner_radius_bottom_right = 10
        b.add_theme_stylebox_override("normal", st)
        var vb := VBoxContainer.new()
        vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.set_anchors_preset(Control.PRESET_FULL_RECT)
        vb.offset_left = 6
        vb.offset_top = 6
        vb.offset_right = -6
        b.add_child(vb)
        var nm := Label.new()
        nm.text = name_txt
        nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        nm.add_theme_font_size_override("font_size", 13)
        nm.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
        vb.add_child(nm)
        var pr := Label.new()
        pr.text = "%d CC" % price
        pr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        pr.add_theme_font_size_override("font_size", 14)
        pr.add_theme_color_override("font_color", Color(1, 0.82, 0.3))
        vb.add_child(pr)
        var sb := Label.new()
        sb.text = sub_txt
        sb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        sb.add_theme_font_size_override("font_size", 9)
        sb.add_theme_color_override("font_color", Color(0.7, 0.72, 0.85))
        vb.add_child(sb)
        b.pressed.connect(cb)
        return b

func _toast_ccoins() -> void:
        _refresh_hud()

func _wave_buy_weapon(wid: String, price: int) -> void:
        if run_ccoins < price:
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("not enough coins")
                return
        run_ccoins -= price
        meta.add_armory(wid, 1)
        if weapons_run.size() < meta.weapon_slots():
                weapons_run.append({"id": wid, "tier": 1, "cd": 0.0})
        Jukebox.sfx("cs_buy", -4.0)
        _refresh_hud()
        _rebuild_sheet()

func _wave_buy_consumable(cid: String, price: int) -> void:
        if run_ccoins < price:
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("not enough coins")
                return
        run_ccoins -= price
        match cid:
                "heal30": p_hp = minf(p_max_hp, p_hp + 30.0)
                "plate": stats["armor"] = int(stats["armor"]) + 1
                "crate":
                        for e in enemies.duplicate():
                                _hurt_enemy(e, 60.0)
                        _shockwave(p_pos, 900.0)
        Jukebox.sfx("cs_buy", -4.0)
        _rebuild_sheet()

func _allies_deployed(aid: String) -> int:
        var n := 0
        for a in allies:
                if a["id"] == aid:
                        n += 1
        return n

func _wave_buy_ally(aid: String, price: int) -> void:
        if allies.size() >= _ally_cap():
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("the leash is full (%d allies)" % _ally_cap())
                return
        if run_ccoins < price:
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("not enough coins")
                return
        run_ccoins -= price
        var deployed := _allies_deployed(aid)
        if deployed == 0:
                _deploy_ally(aid, 1)
        else:
                for a in allies:
                        if a["id"] == aid:
                                a["level"] = int(a["level"]) + 1
                                break
        Jukebox.sfx("cs_buy", -4.0)
        _rebuild_sheet()

func _merge_pairs() -> Array:
        # two same weapons, same tier -> the next tier at half price (the law)
        var out := []
        for wid in CSData.WEAPON_ORDER:
                for tier in [1, 2]:
                        if meta.count_armory(wid, tier) >= 2:
                                out.append({"wid": wid, "tier": tier,
                                        "cost": CSData.merge_price(wid, tier)})
        return out

func _wave_buy_merge(pr: Dictionary, cost: int) -> void:
        var wid: String = pr["wid"]
        var tier: int = int(pr["tier"])
        if meta.tier_cap() < tier + 1:
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("SPUDNIK level %d gates T%d" % [meta.char_level(), tier + 1])
                return
        if run_ccoins < cost:
                Jukebox.sfx("cs_error", -6.0)
                _toast_show("not enough coins")
                return
        meta.remove_armory(wid, tier)
        meta.remove_armory(wid, tier)
        run_ccoins -= cost
        meta.add_armory(wid, tier + 1)
        run_merges += 1
        # the equipped copy upgrades too
        for w in weapons_run:
                if w["id"] == wid and int(w["tier"]) == tier:
                        w["tier"] = tier + 1
                        break
        Jukebox.sfx("cs_levelup", -3.0)
        _banner("MERGED! %s T%d" % [CSData.WEAPONS[wid]["name"], tier + 1], false)
        _rebuild_sheet()

func _rebuild_sheet() -> void:
        # the sheet content rebuilds (prices/pairs/labels live-state)
        _close_all_sheets()
        _wave_shop_open()

# ================================================================ gogashop
## THE UNIVERSAL SHOP, this game's shelf: weapons one by one at high prices,
## allies at the HIGHEST prices, themes - all in COSMIC COINS (the law).
var _shop_tab := "weapons"

func _gogashop_open() -> void:
        _open_sheet(func(box: VBoxContainer): _build_gogashop(box), 0.0)

func _build_gogashop(box: VBoxContainer) -> void:
        var t := Label.new()
        t.text = "THE GOGASHOP  -  %d cosmic coins" % meta.coins()
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        t.add_theme_font_size_override("font_size", 20)
        t.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
        box.add_child(t)
        var tabs := HBoxContainer.new()
        tabs.alignment = BoxContainer.ALIGNMENT_CENTER
        tabs.add_theme_constant_override("separation", 8)
        box.add_child(tabs)
        for tab in ["weapons", "allies", "themes", "loadout"]:
                var b := Button.new()
                b.text = tab.to_upper()
                b.add_theme_font_size_override("font_size", 12)
                if _shop_tab == tab:
                        b.disabled = true
                b.pressed.connect(func():
                        _shop_tab = tab
                        _close_all_sheets()
                        _gogashop_open())
                tabs.add_child(b)
        match _shop_tab:
                "weapons": _shop_weapons(box)
                "allies": _shop_allies(box)
                "themes": _shop_themes(box)
                "loadout": _shop_loadout(box)
        var back := Button.new()
        back.text = "BACK"
        back.add_theme_font_size_override("font_size", 14)
        back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        back.pressed.connect(func():
                _close_all_sheets()
                if phase == "boot":
                        _optionals_open()
                elif phase == "break":
                        _wave_shop_open())
        box.add_child(back)

func _shop_weapons(box: VBoxContainer) -> void:
        var grid := GridContainer.new()
        grid.columns = 3
        grid.add_theme_constant_override("h_separation", 8)
        grid.add_theme_constant_override("v_separation", 8)
        box.add_child(grid)
        for wid in CSData.WEAPON_ORDER:
                var wd: Dictionary = CSData.WEAPONS[wid]
                var owned := meta.has_weapon(wid)
                var price := CSData.weapon_price(wid, 1)
                var txt: String = wd["name"]
                txt += "\n%d dmg / %.2fs" % [int(wd["dmg"]), float(wd["cad"])]
                if owned:
                        txt += "\nOWNED"
                else:
                        txt += "\n%d CC" % price
                var b := Button.new()
                b.custom_minimum_size = Vector2(196, 74)
                b.text = txt
                b.add_theme_font_size_override("font_size", 11)
                b.disabled = owned or meta.coins() < price
                b.pressed.connect(func():
                        if meta.spend(price):
                                meta.add_armory(wid, 1)
                                Jukebox.sfx("cs_buy", -4.0)
                                _close_all_sheets()
                                _gogashop_open())
                grid.add_child(b)
        var note := Label.new()
        note.text = "every weapon starts T1 - merge copies to climb tiers (the WEAPON LAB teaches merging)"
        note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        note.add_theme_font_size_override("font_size", 11)
        note.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9))
        box.add_child(note)

func _shop_allies(box: VBoxContainer) -> void:
        var grid := GridContainer.new()
        grid.columns = 3
        grid.add_theme_constant_override("h_separation", 8)
        grid.add_theme_constant_override("v_separation", 8)
        box.add_child(grid)
        for aid in CSData.ALLY_ORDER:
                var ad: Dictionary = CSData.ALLIES[aid]
                var owned := meta.has_ally(aid)
                var price: int = int(ad["price"])
                var b := Button.new()
                b.custom_minimum_size = Vector2(196, 74)
                b.text = "%s\n%s\n%s" % [ad["name"],
                                "OWNED" if owned else "%d CC" % price, ad["desc"]]
                b.add_theme_font_size_override("font_size", 10)
                b.disabled = owned or meta.coins() < price
                b.pressed.connect(func():
                        if meta.spend(price):
                                meta.own_ally(aid)
                                Jukebox.sfx("cs_buy", -4.0)
                                _close_all_sheets()
                                _gogashop_open())
                grid.add_child(b)
        var note := Label.new()
        note.text = "allies cost the MOST on purpose (the owner's law) - they deploy in the wave shop and merge upward"
        note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        note.add_theme_font_size_override("font_size", 11)
        box.add_child(note)

func _shop_themes(box: VBoxContainer) -> void:
        var grid := GridContainer.new()
        grid.columns = 2
        grid.add_theme_constant_override("h_separation", 10)
        box.add_child(grid)
        for tid in CSData.THEME_ORDER:
                var th: Dictionary = CSData.THEMES[tid]
                var owned := meta.has_theme(tid)
                var price: int = int(th["price"])
                var b := Button.new()
                b.custom_minimum_size = Vector2(300, 90)
                var sub: String = "day + night variants"
                if tid == theme_id and owned:
                        sub += "  [ON]"
                b.text = "%s\n%s\n%s" % [th["name"],
                                "OWNED" if owned else "%d CC" % price, sub]
                b.add_theme_font_size_override("font_size", 12)
                b.disabled = owned or meta.coins() < price
                b.pressed.connect(func():
                        if meta.spend(price):
                                meta.own_theme(tid)
                                Jukebox.sfx("cs_buy", -4.0)
                                _close_all_sheets()
                                _gogashop_open())
                grid.add_child(b)

func _shop_loadout(box: VBoxContainer) -> void:
        var info := Label.new()
        info.text = "the 3 weapons Spudnik drops in with (tap to toggle)"
        info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        info.add_theme_font_size_override("font_size", 12)
        box.add_child(info)
        var grid := GridContainer.new()
        grid.columns = 4
        grid.add_theme_constant_override("h_separation", 8)
        box.add_child(grid)
        var lo := meta.loadout()
        for inst in meta.armory():
                var wid: String = inst[0]
                var tier: int = int(inst[1])
                var on := lo.has(wid)
                var b := Button.new()
                b.text = "%s T%d%s" % [CSData.WEAPONS[wid]["name"], tier, " [ON]" if on else ""]
                b.add_theme_font_size_override("font_size", 11)
                b.custom_minimum_size = Vector2(170, 56)
                b.pressed.connect(func():
                        var l2 := meta.loadout()
                        if l2.has(wid):
                                l2.erase(wid)
                        elif l2.size() < meta.weapon_slots():
                                l2.append(wid)
                        else:
                                _toast_show("the holster is full (%d slots)" % meta.weapon_slots())
                                return
                        meta.set_loadout(l2)
                        _close_all_sheets()
                        _gogashop_open())
                grid.add_child(b)
        var sell_note := Label.new()
        sell_note.text = "SELL: hold nothing sacred - duplicates sell from the wave shop merges (everything is bought AND sold for coins)"
        sell_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sell_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        sell_note.add_theme_font_size_override("font_size", 11)
        box.add_child(sell_note)

# =================================================================== tree
func _tree_open() -> void:
        _open_sheet(func(box: VBoxContainer): _build_tree(box), 0.0)

func _build_tree(box: VBoxContainer) -> void:
        var t := Label.new()
        t.text = "THE SKILL TREE  -  SPUDNIK LV%d  -  %d CC" % [meta.char_level(), meta.coins()]
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        t.add_theme_font_size_override("font_size", 18)
        t.add_theme_color_override("font_color", Color(0.6, 0.95, 1))
        box.add_child(t)
        var sub := Label.new()
        sub.text = "everything starts locked - unlock one by one for cosmic coins (the ubisoft law)"
        sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sub.add_theme_font_size_override("font_size", 11)
        sub.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9))
        box.add_child(sub)
        var grid := GridContainer.new()
        grid.columns = 5
        grid.add_theme_constant_override("h_separation", 8)
        grid.add_theme_constant_override("v_separation", 8)
        box.add_child(grid)
        var branches := {"OFFENSE": [], "DEFENSE": [], "UTILITY": [], "LAB": []}
        for nid in CSData.TREE_ORDER:
                var n: Dictionary = CSData.TREE[nid]
                branches[n["branch"]].append(nid)
        for bname in ["OFFENSE", "DEFENSE", "UTILITY", "LAB"]:
                var col := VBoxContainer.new()
                col.add_theme_constant_override("separation", 6)
                var bt := Label.new()
                bt.text = bname
                bt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                bt.add_theme_font_size_override("font_size", 12)
                bt.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
                col.add_child(bt)
                grid.add_child(col)
                for nid in branches[bname]:
                        col.add_child(_tree_node(nid))
        var back := Button.new()
        back.text = "BACK"
        back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        back.pressed.connect(func():
                _close_all_sheets()
                if phase == "boot":
                        _optionals_open()
                elif phase == "break":
                        _wave_shop_open())
        box.add_child(back)

func _tree_node(nid: String) -> Button:
        var n: Dictionary = CSData.TREE[nid]
        var owned := meta.tree_has(nid)
        var can := meta.tree_can_buy(nid)
        var b := Button.new()
        b.custom_minimum_size = Vector2(180, 64)
        var st := StyleBoxFlat.new()
        st.bg_color = Color(0.16, 0.2, 0.24, 0.97) if owned else Color(0.09, 0.09, 0.12, 0.97)
        st.set_border_width_all(2)
        st.border_color = Color(0.4, 1, 0.6) if owned else (Color(1, 0.9, 0.4) if can \
                        else Color(0.28, 0.28, 0.34))
        st.corner_radius_top_left = 9
        st.corner_radius_top_right = 9
        st.corner_radius_bottom_left = 9
        st.corner_radius_bottom_right = 9
        b.add_theme_stylebox_override("normal", st)
        var vb := VBoxContainer.new()
        vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.set_anchors_preset(Control.PRESET_FULL_RECT)
        vb.offset_left = 5
        vb.offset_top = 4
        vb.offset_right = -5
        b.add_child(vb)
        var nm := Label.new()
        nm.text = ("* " if owned else "") + n["name"]
        nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        nm.add_theme_font_size_override("font_size", 11)
        nm.add_theme_color_override("font_color",
                        Color(0.55, 1, 0.65) if owned else (Color.WHITE if can else Color(0.55, 0.55, 0.62)))
        vb.add_child(nm)
        var ds := Label.new()
        var gate := ""
        if not owned and meta.char_level() < int(n["clv"]):
                gate = "  [LV%d]" % int(n["clv"])
        ds.text = n["desc"] + gate
        ds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        ds.add_theme_font_size_override("font_size", 9)
        ds.add_theme_color_override("font_color", Color(0.72, 0.75, 0.88))
        vb.add_child(ds)
        if not owned:
                var cs := Label.new()
                cs.text = "%d CC" % int(n["cost"])
                cs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                cs.add_theme_font_size_override("font_size", 10)
                cs.add_theme_color_override("font_color", Color(1, 0.82, 0.3))
                vb.add_child(cs)
        b.pressed.connect(func():
                if meta.tree_buy(nid):
                        Jukebox.sfx("cs_levelup", -3.0)
                        _close_all_sheets()
                        _tree_open()
                else:
                        Jukebox.sfx("cs_error", -6.0)
                        _toast_show("locked: unlock the chain + the level gate first"))
        return b

# =================================================================== death
func _die() -> void:
        if over or phase == "dead":
                return
        phase = "dead"
        Jukebox.sfx("cs_death", -2.0)
        # THE BANK: in-run coins -> the cosmic wallet; XP -> the character level
        meta.earn(run_ccoins)
        var gained := meta.bank_char_xp(int(run_kills * 2 + run_wave * 8))
        meta.record_run(run_wave - 1, score, run_kills, run_merges, start_id)
        achievement_max("cs_kills", int(meta.d["kills"]))
        achievement_max("cs_wave", run_wave - 1)
        achievement_max("cs_score", score)
        if run_merges > 0:
                achievement_count("cs_merge", run_merges)
        achievement_count("cs_runs", 1)
        check_achievements()
        _finish_cs(gained)

func _finish_cs(gained_levels: int) -> void:
        var msg := "wave %d  -  %d kills  -  +%d CC banked" % [run_wave - 1, run_kills, run_ccoins]
        if gained_levels > 0:
                msg += "  -  SPUDNIK leveled up x%d!" % gained_levels
        _banner(msg, false)
        # the box death menu takes it from here (the /200 bonus rides coin_div)
        finish_run(score)

# ================================================================ the banner
func _banner(txt: String, good := true) -> void:
        var root := _overlay_root_ref()
        var holder := Control.new()
        holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
        holder.set_anchors_preset(Control.PRESET_TOP_WIDE)
        holder.offset_top = 170.0
        holder.offset_bottom = 252.0
        root.add_child(holder)
        var l := Label.new()
        l.text = txt
        l.add_theme_font_size_override("font_size", 28)
        l.add_theme_color_override("font_color",
                        Color(1, 0.9, 0.5) if good else Color(1, 0.45, 0.45))
        l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
        l.add_theme_constant_override("shadow_offset_x", 2)
        l.add_theme_constant_override("shadow_offset_y", 2)
        l.set_anchors_preset(Control.PRESET_FULL_RECT)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        holder.add_child(l)
        l.pivot_offset = Vector2(l.size.x * 0.5, l.size.y * 0.5)
        l.scale = Vector2.ONE * 0.6
        var tw := l.create_tween()
        tw.tween_property(l, "scale", Vector2.ONE, 0.22) \
                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tw.tween_interval(1.5)
        tw.tween_property(holder, "modulate:a", 0.0, 0.3)
        tw.tween_callback(holder.queue_free)

# ==================================================================== FX
class FxLayer extends Node2D:
        var game: Node
        func _draw() -> void:
                # the layer passes ITSELF: every draw_* call in _draw_fx must
                # land on the node whose _draw is running (the GDScript
                # receiver trap - self there is the GAME, not this layer)
                game._draw_fx(self)

var _floaters: Array = []    # {pos, txt, col, t, max, size}
var _rings: Array = []       # {pos, r, max, t, col, w}
var _parts: Array = []       # {pos, vel, t, max, col, size, tex}

func _draw_fx(L: CanvasItem) -> void:
        # the auras (under everything)
        for e in enemies:
                if e.get("dead", false):
                        continue
                if e.get("aura", 0.0) > 0.0:
                        var breathe := 0.5 + 0.14 * sin(Time.get_ticks_msec() / 260.0)
                        L.draw_circle(e["pos"], float(e["aura"]),
                                        Color(0.72, 0.42, 1.0, 0.10 * breathe))
                        L.draw_arc(e["pos"], float(e["aura"]), 0, TAU, 48,
                                        Color(0.75, 0.45, 1.0, 0.35), 2.0)
                if e.get("marked", false):
                        L.draw_arc(e["pos"], float(e["size"]) * 0.7, 0, TAU, 24,
                                        Color(1, 0.9, 0.3, 0.5), 2.0)
                # the HP bar under a damaged enemy
                if e["hp"] < e["max_hp"]:
                        var w: float = 34.0 * float(e.get("scale_m", 1.0))
                        var yy: float = e["pos"].y - float(e["size"]) * float(e.get("scale_m", 1.0)) - 10.0
                        L.draw_rect(Rect2(e["pos"].x - w * 0.5, yy, w, 4), Color(0, 0, 0, 0.55))
                        L.draw_rect(Rect2(e["pos"].x - w * 0.5, yy, w * clampf(float(e["hp"]) / float(e["max_hp"]), 0, 1), 4),
                                        Color(0.95, 0.3, 0.3))
                # the tri-shield rings (the signature)
                if e.get("rings", null) != null:
                        _draw_rings(e, L)
                # the elite ring + tag
                if e.get("elite", false):
                        L.draw_arc(e["pos"], float(e["size"]) * 0.62 * float(e.get("scale_m", 1.0)),
                                        0, TAU, 32, Color(0.8, 0.4, 1.0, 0.8), 2.5)
                        L.draw_string(ThemeDB.fallback_font, e["pos"] + Vector2(-40, -float(e["size"]) - 18),
                                        String(e["affix"]).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 80, 9,
                                        Color(0.9, 0.6, 1.0))
                # the charger telegraph
                if e.get("state", "") == "wind" and e.get("dash_dir", null) != null:
                        var dd: Vector2 = e["dash_dir"]
                        L.draw_line(e["pos"], e["pos"] + dd * 240.0, Color(1, 0.4, 0.3, 0.5), 3.0)
        # the zones (strike telegraphs / slams)
        for z in zones:
                var f := 1.0 - float(z["t"]) / float(z["max"])
                L.draw_arc(z["pos"], float(z["aoe"]) * (0.4 + 0.6 * f), 0, TAU, 40,
                                Color(1, 0.6, 0.2, 0.7), 3.0)
                L.draw_circle(z["pos"], float(z["aoe"]) * f, Color(1, 0.6, 0.2, 0.10))
        # the aim line (a subtle laser sight)
        if phase == "play":
                L.draw_line(p_pos + Vector2.from_angle(p_aim) * 30.0,
                                p_pos + Vector2.from_angle(p_aim) * (70.0 + 26.0 * sin(Time.get_ticks_msec() / 180.0)),
                                Color(1, 0.9, 0.4, 0.35), 2.0)
        # the gun (rotates with the aim, offset to the hand)
        if p_node != null and is_instance_valid(p_node):
                var wid: String = weapons_run[0]["id"] if not weapons_run.is_empty() else "smg"
                var gt: Texture2D = _t("gun_" + wid)
                L.draw_set_transform(p_pos, p_aim, Vector2.ONE)
                L.draw_texture(gt, Vector2(10, -6) - Vector2(gt.get_width() * 0.2, gt.get_height() * 0.5))
                L.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        # the particles + rings + floaters
        for p in _parts:
                var a := float(p["t"]) / float(p["max"])
                if p.get("tex", "") != "":
                        L.draw_texture(_t(p["tex"]), p["pos"] - Vector2(16, 16),
                                        Color(1, 1, 1, a))
                else:
                        L.draw_circle(p["pos"], float(p["size"]) * a, Color(p["col"], a))
        for r in _rings:
                var ra := float(r["t"]) / float(r["max"])
                L.draw_circle(r["pos"], float(r["r"]) * (1.0 - ra * 0.4),
                                Color(r["col"], 0.25 * ra))
                L.draw_arc(r["pos"], float(r["r"]) * (1.2 - ra * 0.8), 0, TAU, 40,
                                Color(r["col"], ra), float(r["w"]))
        for f2 in _floaters:
                var fa := float(f2["t"]) / float(f2["max"])
                L.draw_string(ThemeDB.fallback_font, f2["pos"], f2["txt"],
                                HORIZONTAL_ALIGNMENT_CENTER, -1, int(f2["size"]),
                                Color(f2["col"], fa))

func _draw_rings(e: Dictionary, L: CanvasItem) -> void:
        # each ring draws its REMAINING arcs (the carved windows stay open)
        for ring in e["rings"]:
                var cracks: Array = ring["cracks"]
                var arcs := []
                if cracks.is_empty():
                        arcs.append([0.0, TAU])
                else:
                        var sorted := cracks.duplicate()
                        sorted.sort_custom(func(x, y): return float(x[0]) < float(y[0]))
                        var cursor := 0.0
                        for c in sorted:
                                var a0 := fposmod(float(c[0]), TAU)
                                var a1 := float(c[1])
                                if a0 >= cursor:
                                        arcs.append([cursor, a0])
                                cursor = maxf(cursor, a1)
                        if cursor < TAU:
                                arcs.append([cursor, TAU])
                var col := Color(0.35, 0.85, 1.0, 0.85)
                for arc in arcs:
                        var span: float = float(arc[1]) - float(arc[0])
                        if span <= 0.01:
                                continue
                        var segs := maxi(2, int(span / 0.12))
                        var prev := Vector2.ZERO
                        for i in segs + 1:
                                var a: float = float(arc[0]) + span * float(i) / float(segs)
                                # the ring's LOCAL frame rotates: world angle = local + rot
                                var wp: Vector2 = e["pos"] + Vector2.from_angle(a + float(ring["rot"])) * float(ring["r"])
                                if i > 0:
                                        L.draw_line(prev, wp, col, 6.0)
                                prev = wp

# ------------------------------------------------------------ fx helpers
func _dmg_number(pos: Vector2, v: float, crit: bool, col := Color(1, 1, 1)) -> void:
        _floaters.append({"pos": pos + Vector2(randf_range(-10, 10), -18),
                "txt": ("%d!" % int(round(v))) + (" CRIT" if crit else ""),
                "col": Color(1, 0.85, 0.3) if crit else col,
                "t": 0.7, "max": 0.7, "size": 18 if crit else 13})

func _shockwave(pos: Vector2, r: float) -> void:
        _rings.append({"pos": pos, "r": r, "t": 0.42, "max": 0.42,
                "col": Color(1, 0.7, 0.35), "w": 6.0})

func _death_burst(e: Dictionary) -> void:
        # the python 8-particle law, grown: 12-20 particles + a ring
        var n := 12 + (8 if e.get("boss", false) else 0)
        for i in n:
                var a := randf() * TAU
                var sp := randf_range(60.0, 260.0)
                _parts.append({"pos": e["pos"], "vel": Vector2.from_angle(a) * sp,
                        "t": 0.5, "max": 0.5, "col": Color(1, 0.55, 0.3),
                        "size": randf_range(3.0, 7.0), "tex": ""})
        _rings.append({"pos": e["pos"], "r": float(e["size"]), "t": 0.3,
                "max": 0.3, "col": Color(1, 0.6, 0.4), "w": 4.0})

func _heal_flash(e: Dictionary) -> void:
        _parts.append({"pos": e["pos"] + Vector2(randf_range(-14, 14), -10),
                "vel": Vector2(0, -60), "t": 0.4, "max": 0.4,
                "col": Color(0.5, 1, 0.6), "size": 5.0, "tex": ""})

func _tick_fx(delta: float) -> void:
        var dead := []
        for p in _parts:
                p["t"] -= delta
                if p["t"] <= 0.0:
                        dead.append(p)
                        continue
                p["pos"] += Vector2(p["vel"]) * delta
                p["vel"] = Vector2(p["vel"]) * 0.92
        for p2 in dead:
                _parts.erase(p2)
        var dead2 := []
        for r in _rings:
                r["t"] -= delta
                if r["t"] <= 0.0:
                        dead2.append(r)
        for r2 in dead2:
                _rings.erase(r2)
        var dead3 := []
        for f in _floaters:
                f["t"] -= delta
                f["pos"].y -= 40.0 * delta
                if f["t"] <= 0.0:
                        dead3.append(f)
        for f3 in dead3:
                _floaters.erase(f3)
