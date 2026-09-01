extends GogaGame
## SPACE DASH (v0.2.4) - the lane-dodger grew up. Not a dodge game with
## blocks anymore: the sky is FULL of enemy ships and score is KILLS.
##
## Owner contract (docs/goga_docs/gogames_ideas/dash.md):
##   - 5 lanes, guides as alpha values so the space bg shows through
##   - tap LEFT/RIGHT EDGE = move one lane that way (smooth, wall-blocked)
##   - press the MIDDLE = shoot (rapid taps AND holding both fire)
##   - anti-spam: one shot per max(30ms, one live frame) - studied, probed
##   - enemies: speeds/powers/defenses, shooters, splitters, shield bubbles,
##     orbiting shatter shards with a gap that faces the player, RARE ufo
##     elites (shotgun / double shotgun / power)
##   - dynamic difficulty reads KILLS (not score, not power) in tiers
##   - loot drops from WRECKS only: coins (1 per 5-10 kills from the last
##     coin), power points, weapon items + shield items (shop-gated)
##   - hearts: 3 to start, +1 per 1000 score, wreck = -500 score + 1 heart,
##     the death that takes the last heart ends the run
##   - weapon power ladders 0/1/3/6/10/15/20 PER WEAPON, death = 3 rungs down
##   - 4 weapons: yellow beams / red laser (piercing) / thunder (chain) /
##     bomb launcher (radius) - shop sells the last three + the shield
##   - shop: 7 real-art ship skins, 3 spaces (blue/green/yellow), no
##     optionals menu - shop, then TAP ANYWHERE TO START
##   - round fee 20 GOGACoins, run-end bonus = score/20 (registry coin_div)
##   - NO code-generated ships: everything wears Kenney CC0 sprites
##     (vendored, see assets.manifest.json); effects are code.

const DIR := "res://assets/games/lanes/"

const LANES := 5
const LANE_W := 190.0
const SHIP_Y_FRAC := 0.815          # ship row from the top
const SHIP_R := 52.0                # ship collision radius
const INVULN_T := 1.4               # post-wreck grace seconds
const WRECK_SCORE := -500           # owner: "each crash takes -500"
const HEART_EVERY := 1000           # +1 heart per 1000 score
const START_HEARTS := 3
const COIN_KILLS_MIN := 5           # owner: "1 coin between 5-10 enemies"
const COIN_KILLS_MAX := 10

## THE SPAM LAW (owner: "max shoots will be one per 30ms ... study it, not
## hardcode it"): the floor is the bigger of 30ms and ONE LIVE FRAME - a
## slow device can never fire more shots than it can draw, and a macro can
## never exceed 33/s. Human tap range (8-12/s) always passes.
const SPAM_FLOOR_MS := 30.0

## weapon power ladder (owner: 0 base, then 1, 3, 6, 10, 15, 20 max)
const POWER_LADDER := [0, 1, 3, 6, 10, 15, 20]
const POWER_MAX := 20
const DEATH_POWER_RUNGS := 3        # owner: dying takes 3 upgrades worth

## ---------------- the four weapons ----------------
const BEAM_CAD := 0.16              # yellow beams: fast, weak
const BEAM_DMG := 3
const LASER_LIVE := 2.0             # red laser: 2s continuity (owner)
const LASER_CD := 0.5
const LASER_TAP := 0.30             # a tap = a short pulse
const LASER_DPS := 24.0
const LASER_DPS_PER_LVL := 10.0
const LASER_HALF_W := 26.0          # pierce column half width (+ per lvl)
const THUNDER_LIVE := 5.0           # white thunder: 5s continuity (owner)
const THUNDER_CD := 2.0
const THUNDER_GAP := 0.22           # strike rhythm while held
const THUNDER_DMG := 8
const THUNDER_DMG_PER_LVL := 2
const THUNDER_BASE_HITS := 3        # chain hits; upgrades add hits (owner)
const THUNDER_JUMP := 340.0         # max jump distance between victims
const BOMB_CD := 2.0                # bomb launcher: single shots (owner)
const BOMB_DMG := 55.0
const BOMB_DMG_PER_LVL := 16.0
const BOMB_R := 170.0
const BOMB_R_PER_LVL := 16.0

## ---------------- enemy roster (real Kenney hulls, nose-down) ----------------
## hp/score/spd tuned per class; tier adds +8% hp steps (see _tier_hp)
const ETYPES := {
        "grunt": {"tex": "enemy_grunt.png", "hp": 2, "score": 10,
                "spd": [90.0, 130.0], "r": 60.0, "scale": 1.9},
        "grunt2": {"tex": "enemy_grunt2.png", "hp": 3, "score": 14,
                "spd": [100.0, 150.0], "r": 62.0, "scale": 1.9},
        "runner": {"tex": "enemy_runner.png", "hp": 2, "score": 22,
                "spd": [200.0, 270.0], "r": 58.0, "scale": 1.9, "sway": 26.0},
        "shooter": {"tex": "enemy_shooter.png", "hp": 3, "score": 26,
                "spd": [85.0, 120.0], "r": 60.0, "scale": 1.9, "fires": true},
        "splitter": {"tex": "enemy_splitter.png", "hp": 4, "score": 30,
                "spd": [90.0, 130.0], "r": 62.0, "scale": 1.9, "splits": true},
        "tank": {"tex": "enemy_tank.png", "hp": 12, "score": 60,
                "spd": [50.0, 75.0], "r": 84.0, "scale": 2.6, "big": true},
        "shielded": {"tex": "enemy_shielded.png", "hp": 3, "score": 40,
                "spd": [85.0, 120.0], "r": 62.0, "scale": 1.9, "bubble": 3},
        "shatter": {"tex": "enemy_shatter.png", "hp": 4, "score": 45,
                "spd": [70.0, 100.0], "r": 60.0, "scale": 1.9, "shards": true},
        "ufo_shot": {"tex": "enemy_ufo_red.png", "hp": 8, "score": 120,
                "spd": [60.0, 90.0], "r": 66.0, "scale": 2.1, "big": true,
                "elite": "shot"},
        "ufo_dbl": {"tex": "enemy_ufo_green.png", "hp": 11, "score": 170,
                "spd": [55.0, 80.0], "r": 66.0, "scale": 2.1, "big": true,
                "elite": "double"},
        "ufo_pow": {"tex": "enemy_ufo_yellow.png", "hp": 18, "score": 260,
                "spd": [70.0, 110.0], "r": 66.0, "scale": 2.3, "big": true,
                "elite": "power"},
}

## ship skins (real hulls; price 0 = owned default - the shop law)
const SKINS := {
        "orange": {"name": "Ember", "price": 0, "tex": "ship_orange.png"},
        "blue": {"name": "Azure", "price": 250, "tex": "ship_blue.png"},
        "green": {"name": "Verdant", "price": 250, "tex": "ship_green.png"},
        "veteran": {"name": "Veteran", "price": 400, "tex": "ship_veteran.png"},
        "phantom": {"name": "Phantom", "price": 450, "tex": "ship_phantom.png"},
        "horn": {"name": "Hornet", "price": 550, "tex": "ship_horn.png"},
        "titan": {"name": "Titan", "price": 700, "tex": "ship_titan.png"},
}

## spaces (backgrounds) - blue default, green, yellow (owner spec)
const SPACES := {
        "blue": {"name": "Deep Blue", "price": 0, "deep": Color("060a1c"),
                "neb1": Color("1a2f6e"), "neb2": Color("3d1f66"),
                "star": Color(0.82, 0.90, 1.0)},
        "green": {"name": "Emerald Drift", "price": 300, "deep": Color("04140e"),
                "neb1": Color("0f5c3a"), "neb2": Color("1a3d6e"),
                "star": Color(0.80, 1.0, 0.90)},
        "yellow": {"name": "Solar Gold", "price": 350, "deep": Color("1a1004"),
                "neb1": Color("8a5a14"), "neb2": Color("6e2a1a"),
                "star": Color(1.0, 0.95, 0.80)},
}

## shop weapons/shield (buying = the item EXISTS in the loot pool,
## "not equipped as base but bought so it exists in the game" - owner)
const SHOP_WEAPONS := {
        "laser": {"name": "Red Laser", "price": 450},
        "thunder": {"name": "Thunder", "price": 600},
        "bomb": {"name": "Bomb Launcher", "price": 700},
}
const SHOP_SHIELD := {"name": "Shield Power", "price": 500}

# ---------------------------------------------------------------- state
var phase := "ready"                # ready | run | over
var world: Node2D
var bg_rect: ColorRect
var star_pool: Array = []           # parallax star sprites
var ship: Sprite2D
var ship_glow: Sprite2D
var flame: Sprite2D
var lane := 2
var lane_tween: Tween
var bank := 0.0                     # visual bank tilt
var shield_lvl := 0                 # player shield power 0..3
var hearts := START_HEARTS
var next_heart_at := HEART_EVERY
var kills := 0
var kills_since_coin := 0
var coin_target := 7                # rerolled 5..10 at every coin
var weapon := "beam"
var power := {"beam": 0, "laser": 0, "thunder": 0, "bomb": 0}
var firing := false                 # a fire-zone finger is DOWN
var fire_pulse := 0.0               # a tap keeps the weapon alive a moment
var last_shot_ms := 0
var frame_floor_ms := SPAM_FLOOR_MS
var beam_cd := 0.0                  # beam autofire rhythm
var laser_live := LASER_LIVE
var laser_cd := 0.0
var thunder_live := THUNDER_LIVE
var thunder_cd := 0.0
var thunder_clock := 0.0
var bomb_cd := 0.0
var spawn_clock := 1.2
var invuln := 0.0
var shake := 0.0
var flame_clock := 0.0
var flame_frame := 0

var enemies: Array = []             # dicts, see _spawn_enemy
var bolts: Array = []               # player beam bolts
var ebolts: Array = []              # enemy bolts
var bombs: Array = []               # bomb projectiles
var loots: Array = []               # coin / power / weapon / shield drops

var _tex: Dictionary = {}           # lazy texture cache
var fx: Node2D                      # the VFX painter (sparks/rings/popups)
var laser_beam: Node2D              # the continuous laser painter
var hud2: CanvasLayer               # hearts + weapon gauge + shield row
var hearts_row: HBoxContainer
var hearts_lbl: Label
var weapon_lbl: Label
var power_bar: Control
var shield_lbl: Label
var _power_state := {"lvl": 0}
var _ready_card: Control = null
var _shop_pair: Array = []          # THE PAIR LAW: the shop owns its dim+center
var _shop_from := "ready"
var _overlay_panel: Control = null  # non-shop overlay tracker (base has none)
var rng := RandomNumberGenerator.new()

# =========================================================== setup / world

func _goga_setup() -> void:
        rng.randomize()
        for k in ["ship_orange", "ship_blue", "ship_green", "ship_veteran",
                  "ship_phantom", "ship_horn", "ship_titan", "enemy_grunt",
                  "enemy_grunt2", "enemy_runner", "enemy_shooter",
                  "enemy_splitter", "enemy_tank", "enemy_shielded",
                  "enemy_shatter", "enemy_ufo_red", "enemy_ufo_green",
                  "enemy_ufo_yellow", "laser_yellow", "laser_red_bolt",
                  "laser_thunder", "enemy_bolt", "bomb", "fx_flare",
                  "fx_spark", "fx_smoke", "fx_star", "shield_1", "shield_2",
                  "shield_3", "item_power", "item_shield", "item_laser",
                  "item_thunder", "item_bomb", "fire_00", "fire_02",
                  "fire_04", "fire_06", "fire_08", "fire_10", "fire_12",
                  "fire_14", "fire_16", "fire_18"]:
                _tex[k] = load(DIR + k + ".png")
        _tex["coin"] = load("res://assets/ui/coin.png")
        _tex["heart"] = load("res://assets/ui/heart.png")

        world = Node2D.new()
        add_child(world)
        var vp := get_viewport_rect().size

        # --- deep space (shader; per-space palette from the shop) ---
        bg_rect = ColorRect.new()
        bg_rect.size = vp
        bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var mat := ShaderMaterial.new()
        mat.shader = load(DIR + "bg_space.gdshader")
        _apply_space(mat, _space_id())
        bg_rect.material = mat
        world.add_child(bg_rect)

        # --- parallax star sprites (the shader's far field + these near) ---
        for i in 26:
                var s := Sprite2D.new()
                s.texture = _tex["fx_star"]
                s.material = _add_mat()
                var d := 0.5 + rng.randf() * 0.5
                s.scale = Vector2.ONE * (0.04 + rng.randf() * 0.09)
                s.modulate = Color(1, 1, 1, 0.25 + d * 0.6)
                s.position = Vector2(rng.randf() * vp.x, rng.randf() * vp.y)
                s.set_meta("spd", 26.0 + d * 130.0)
                world.add_child(s)
                star_pool.append(s)

        # --- lane guides (ALPHA values - the owner's lane law) ---
        var guides := Node2D.new()
        guides.name = "guides"
        guides.draw.connect(_draw_guides.bind(guides))
        world.add_child(guides)

        # --- the VFX painter above the field, below the HUD ---
        fx = Node2D.new()
        fx.material = _add_mat()
        fx.draw.connect(_draw_fx)
        world.add_child(fx)

        laser_beam = Node2D.new()
        laser_beam.material = _add_mat()
        laser_beam.draw.connect(_draw_laser)
        world.add_child(laser_beam)

        _build_ship()
        _build_hud2()
        add_hud_button("SHOP", func(): _shop_open())
        Jukebox.music("res://assets/audio/music/dash_theme.wav")
        _show_ready_card()

func _add_mat() -> CanvasItemMaterial:
        var m := CanvasItemMaterial.new()
        m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
        return m

func _apply_space(mat: ShaderMaterial, sid: String) -> void:
        var sp: Dictionary = SPACES.get(sid, SPACES["blue"])
        mat.set_shader_parameter("deep_col", sp["deep"])
        mat.set_shader_parameter("neb1_col", sp["neb1"])
        mat.set_shader_parameter("neb2_col", sp["neb2"])
        mat.set_shader_parameter("star_col", sp["star"])

func _space_id() -> String:
        var on := Box.item_on(game_id, "space")
        return on if SPACES.has(on) else "blue"

func _lane_x(i: int) -> float:
        var vp := get_viewport_rect().size
        var cx := vp.x / 2.0
        return cx + (float(i) - float(LANES - 1) / 2.0) * LANE_W

func _ship_home() -> Vector2:
        var vp := get_viewport_rect().size
        return Vector2(_lane_x(lane), vp.y * SHIP_Y_FRAC)

func _build_ship() -> void:
        var skin := Box.skin_on(game_id)
        if not SKINS.has(skin):
                skin = "orange"
        ship = Sprite2D.new()
        ship.texture = _tex["ship_" + skin]
        ship.scale = Vector2.ONE * 2.2
        ship.position = _ship_home()
        world.add_child(ship)
        # additive engine light behind the hull (the lighting pass)
        ship_glow = Sprite2D.new()
        ship_glow.texture = _tex["fx_flare"]
        ship_glow.scale = Vector2.ONE * 0.55
        ship_glow.modulate = Color(0.5, 0.8, 1.0, 0.20)
        ship.add_child(ship_glow)
        # animated engine flame (real fire frames, flipped to exhaust)
        flame = Sprite2D.new()
        flame.texture = _tex["fire_00"]
        flame.flip_v = true
        flame.scale = Vector2(1.9, 2.1)
        flame.position = Vector2(0, 84)
        flame.modulate = Color(1.0, 0.72, 0.4, 0.85)
        flame.material = _add_mat()
        ship.add_child(flame)

func _build_hud2() -> void:
        # hearts + weapon gauge + shield - a quiet row above the bottom edge
        hud2 = CanvasLayer.new()
        add_child(hud2)
        var row := HBoxContainer.new()
        row.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
        row.offset_left = 18
        row.offset_top = -96
        row.offset_bottom = -40
        row.offset_right = 620
        row.add_theme_constant_override("separation", 10)
        row.mouse_filter = Control.MOUSE_FILTER_IGNORE
        hud2.add_child(row)
        hearts_row = HBoxContainer.new()
        hearts_row.add_theme_constant_override("separation", 4)
        hearts_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
        row.add_child(hearts_row)
        hearts_lbl = Arc.label("x%d" % hearts, 26, Color(1, 0.75, 0.78))
        hearts_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
        row.add_child(hearts_lbl)
        weapon_lbl = Arc.label("BEAMS", 26, Color(1, 0.92, 0.55))
        weapon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
        row.add_child(weapon_lbl)
        power_bar = Control.new()
        power_bar.custom_minimum_size = Vector2(150, 30)
        power_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
        power_bar.draw.connect(_draw_power_bar)
        row.add_child(power_bar)
        shield_lbl = Arc.label("", 24, Color(0.55, 0.9, 1.0))
        shield_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
        row.add_child(shield_lbl)
        _refresh_hud2()

func _refresh_hud2() -> void:
        for c in hearts_row.get_children():
                hearts_row.remove_child(c)
                c.queue_free()
        var shown := mini(hearts, 6)
        for i in shown:
                var h := TextureRect.new()
                h.texture = _tex["heart"]
                h.custom_minimum_size = Vector2(34, 30)
                h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                h.mouse_filter = Control.MOUSE_FILTER_IGNORE
                hearts_row.add_child(h)
        hearts_lbl.text = "x%d" % hearts if hearts > 6 else ""
        weapon_lbl.text = String({"beam": "BEAMS", "laser": "LASER",
                "thunder": "THUNDER", "bomb": "BOMBS"}[weapon]).to_upper()
        _power_state["lvl"] = weapon_level()
        shield_lbl.text = "SHIELD %d/3" % shield_lvl if shield_lvl > 0 else ""
        power_bar.queue_redraw()

func _draw_power_bar() -> void:
        # 6 ladder slots (0/1/3/6/10/15/20) - filled by power level
        var lvl := weapon_level()
        for i in range(1, POWER_LADDER.size()):
                var r := Rect2(i * 24 - 18, 4, 18, 20)
                var on := i <= lvl
                var col := Color(1, 0.92, 0.55, 0.95) if on \
                                else Color(1, 1, 1, 0.16)
                power_bar.draw_rect(r, col)
                power_bar.draw_rect(r, Color(0, 0, 0, 0.35), false, 2.0)

# ------------------------------------------------------------- ready card

func _show_ready_card() -> void:
        phase = "ready"
        _shop_pair_down()
        var root := _overlay_root_ref()
        if _ready_card != null and is_instance_valid(_ready_card):
                _ready_card.queue_free()
        var cc := CenterContainer.new()
        cc.set_anchors_preset(Control.PRESET_FULL_RECT)
        cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var panel := PanelContainer.new()
        panel.add_theme_stylebox_override("panel",
                        Arc.panel_style(Color(0.03, 0.05, 0.12, 0.86), 24))
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 6)
        var t := Arc.label("TAP ANYWHERE TO START", 40, Color(1, 0.92, 0.55))
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        var s := Arc.label("edge = move  ·  middle = shoot", 20,
                        Color(0.75, 0.85, 1.0), false)
        s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        v.add_child(t)
        v.add_child(s)
        panel.add_child(v)
        cc.add_child(panel)
        root.add_child(cc)
        _ready_card = cc

func _start() -> void:
        if phase != "ready":
                return
        phase = "run"
        Jukebox.sfx("dash_start", -4.0)
        if _ready_card != null and is_instance_valid(_ready_card):
                var cc := _ready_card
                _ready_card = null
                var tw := cc.create_tween()
                tw.tween_property(cc, "modulate:a", 0.0, 0.22)
                tw.tween_callback(cc.queue_free)

# ================================================================== SHOP
## THE PAIR LAW (v0.2.3 lesson, now box doctrine): the shop owns its exact
## dim+center siblings and frees BOTH, every open and every rebuy - a
## leaked STOP-mouse dim was pong's dark-overlay bug and it will not
## happen here. No optionals menu exists in this game: the shop is the
## only screen (owner call).

func _shop_open() -> void:
        _shop_from = phase
        if phase == "run":
                paused = true
                get_tree().paused = true
        _shop_pair_down()
        var root := _overlay_root_ref()
        var sheet := Arc.sheet(root, 0.0)
        sheet.get_parent().get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
        var kids := root.get_children()
        _shop_pair = [kids[kids.size() - 2], kids[kids.size() - 1]]
        var t := Arc.label("SPACE DASH SHOP", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.52, 300.0, 640.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        # ---- SHIP SKINS ----
        box.add_child(_shop_label("SHIP SKINS - real hulls"))
        for id in SKINS:
                box.add_child(_skin_row(id))
        # ---- WEAPONS (buying puts them in the LOOT pool) ----
        box.add_child(_shop_label("WEAPONS - they join the loot drops"))
        for id in SHOP_WEAPONS:
                box.add_child(_weapon_row(id))
        # ---- SHIELD ----
        box.add_child(_shop_label("POWER"))
        box.add_child(_shield_row())
        # ---- SPACES ----
        box.add_child(_shop_label("SPACES - the deep sky"))
        for id in SPACES:
                box.add_child(_space_row(id))
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                        func(): _shop_close()))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))
        _overlay_panel = null   # the shop tears down through its OWN pair

func _shop_label(txt: String) -> Label:
        return Arc.fit_label(txt, 24, Arc.HOT, 560)

func _price_btn(txt: String, price: int, col: Color, cb: Callable) -> Button:
        var b := Arc.coin_button("%s  %d" % [txt, price], Vector2(560, 64),
                        22, col, cb)
        if Box.coins() < price:
                b.disabled = true
        return b

func _skin_row(id: String) -> Control:
        var sk: Dictionary = SKINS[id]
        var owned := Box.skin_owned(game_id, id) or int(sk["price"]) == 0
        var on: bool = Box.skin_on(game_id) == id \
                        or (int(sk["price"]) == 0 and Box.skin_on(game_id) == "")
        if on:
                var l := Arc.fit_label("%s  (ON)" % sk["name"], 22,
                                Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        var txt: String = String(sk["name"])
        if owned:
                return Arc.button(txt + "  - EQUIP", Vector2(560, 60), 22,
                                Color("4a5ab8"), func():
                                        Box.equip_skin(game_id, id)
                                        Jukebox.sfx("confirm", -4.0)
                                        _rebuild_ship_skin()
                                        _shop_open())
        var b := _price_btn(txt, int(sk["price"]), Color("4a5ab8"), func():
                if Box.buy_skin(game_id, id, int(sk["price"])):
                        Jukebox.sfx("buy")
                        _rebuild_ship_skin()
                _shop_open())
        return b

func _weapon_row(id: String) -> Control:
        var w: Dictionary = SHOP_WEAPONS[id]
        if Box.item_owned(game_id, "weapons", id):
                var l := Arc.fit_label("%s  - IN THE LOOT" % w["name"], 22,
                                Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        return _price_btn(w["name"], int(w["price"]), Color("8a4ab8"), func():
                if Box.buy_item(game_id, "weapons", id, int(w["price"])):
                        Jukebox.sfx("buy")
                _shop_open())

func _shield_row() -> Control:
        if Box.item_owned(game_id, "shield", "__on__"):
                var l := Arc.fit_label("Shield Power  - IN THE LOOT", 22,
                                Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        return _price_btn(SHOP_SHIELD["name"], int(SHOP_SHIELD["price"]),
                        Color("4a8ab8"), func():
                                if Box.buy_unlock(game_id, "shield",
                                                int(SHOP_SHIELD["price"])):
                                        Jukebox.sfx("buy")
                                _shop_open())

func _space_row(id: String) -> Control:
        var sp: Dictionary = SPACES[id]
        var owned := Box.item_owned(game_id, "space", id) \
                        or int(sp["price"]) == 0
        var on := _space_id() == id \
                        or (int(sp["price"]) == 0 and Box.item_on(game_id, "space") == "")
        if on:
                var l := Arc.fit_label("%s  (ON)" % sp["name"], 22,
                                Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        if owned:
                return Arc.button(sp["name"] + "  - EQUIP", Vector2(560, 60),
                                22, Color("2a7a68"), func():
                                        Box.equip_item(game_id, "space", id)
                                        _apply_space(bg_rect.material
                                                        as ShaderMaterial, id)
                                        Jukebox.sfx("confirm", -4.0)
                                        _shop_open())
        return _price_btn(sp["name"], int(sp["price"]), Color("2a7a68"), func():
                if Box.buy_item(game_id, "space", id, int(sp["price"])):
                        Jukebox.sfx("buy")
                        _apply_space(bg_rect.material as ShaderMaterial, id)
                _shop_open())

func _shop_pair_down() -> void:
        for n in _shop_pair:
                if n != null and is_instance_valid(n):
                        n.queue_free()
        _shop_pair = []

func _shop_close() -> void:
        _shop_pair_down()
        _overlay_panel = null
        if _shop_from == "run":
                get_tree().paused = false
                paused = false
        else:
                _show_ready_card()

func _rebuild_ship_skin() -> void:
        if ship == null or not is_instance_valid(ship):
                return
        var pos := ship.position
        var rot := ship.rotation
        ship.queue_free()
        _build_ship()
        ship.position = pos
        ship.rotation = rot

# ================================================================== INPUT
## Multi-touch by index: an EDGE press moves a lane (instant, responsive);
## a MIDDLE press is THE fire finger (hold or rapid taps). The fire finger
## is tracked separately from move taps so "hold middle + tap edges" - the
## whole point of the control scheme - just works.

func _goga_input(event: InputEvent) -> void:
        if event is InputEventScreenTouch:
                var t := event as InputEventScreenTouch
                if t.pressed:
                        _press(t.position, t.index)
                elif t.index == _fire_idx:
                        _fire_idx = -1
                        firing = false   # only THE fire finger ends the hold

func _press(pos: Vector2, idx := 0) -> void:
        var vp := get_viewport_rect().size
        if phase == "ready":
                if not paused and not over:
                        _start()
                return
        if phase != "run" or over or paused:
                return
        # shield-aura + gauge refresh happen here; the run's own laws below
        if pos.x < vp.x * 0.30:
                _move_lane(-1)
        elif pos.x > vp.x * 0.70:
                _move_lane(1)
        else:
                firing = true
                _fire_idx = idx
                _tap_fire()

var _fire_idx := -1   # which touch owns the hold (move taps never end it)

func _move_lane(dir: int) -> void:
        var target := clampi(lane + dir, 0, LANES - 1)
        if target == lane:
                return          # wall end: blocked, no tween, no sound
        lane = target
        if lane_tween != null and lane_tween.is_valid():
                lane_tween.kill()
        lane_tween = create_tween().set_trans(Tween.TRANS_CUBIC) \
                        .set_ease(Tween.EASE_OUT)
        lane_tween.tween_property(ship, "position:x", _lane_x(lane), 0.14)
        bank = float(dir) * 0.30
        Jukebox.sfx("dash_swap", -10.0, 1.0 + 0.08 * float(dir))

## The spam law in one place. Returns true at most once per floor.
func _shot_ok() -> bool:
        frame_floor_ms = maxf(SPAM_FLOOR_MS,
                        1000.0 / maxf(10.0, Engine.get_frames_per_second()))
        var now := Time.get_ticks_msec()
        if now - last_shot_ms < int(frame_floor_ms):
                return false
        last_shot_ms = now
        return true

func _tap_fire() -> void:
        match weapon:
                "beam":
                        if _shot_ok():
                                _fire_beams()
                "laser":
                        fire_pulse = LASER_TAP   # a pulse, not the full 2s
                "thunder":
                        fire_pulse = 0.0
                        _strike_now()
                "bomb":
                        _drop_bomb()

# ================================================================ WEAPONS

func weapon_level() -> int:
        var p := int(power[weapon])
        var lvl := 0
        for i in POWER_LADDER.size():
                if p >= int(POWER_LADDER[i]):
                        lvl = i
        return lvl

func _add_power(n: int) -> void:
        var before := weapon_level()
        power[weapon] = clampi(int(power[weapon]) + n, 0, POWER_MAX)
        var after := weapon_level()
        if after > before:
                Jukebox.sfx("dash_upgrade", -4.0, 1.0 + 0.05 * float(after))
                _fx_ring(ship.position, 60.0 + 22.0 * float(after),
                                Color(1, 0.92, 0.55), 0.4)
        elif n > 0 and int(power[weapon]) >= POWER_MAX:
                # maxed weapon: extra points pay score instead (documented)
                _score_gain(25)
                _fx_popup(ship.position + Vector2(0, -70), "+25",
                                Color(1, 0.92, 0.55), 30)
        achievement_max("max_power", int(power[weapon]))
        _refresh_hud2()

func _fire_beams() -> void:
        var lvl := weapon_level()
        var n_beams := 1 + (lvl + 1) / 2     # L0:1 L1-2:2 L3-4:3 L5-6:4
        var dmg := BEAM_DMG + lvl
        var vp := get_viewport_rect().size
        for k in n_beams:
                var off := (float(k) - float(n_beams - 1) / 2.0) * 40.0
                var b := Sprite2D.new()
                b.texture = _tex["laser_yellow"]
                b.material = _add_mat()
                b.scale = Vector2(2.6, 3.2)
                b.position = ship.position + Vector2(off, -70)
                world.add_child(b)
                bolts.append({"node": b, "dmg": dmg})
        Jukebox.sfx("dash_beam", -7.0, 1.0 + 0.04 * float(lvl))

func _laser_on() -> bool:
        return (firing or fire_pulse > 0.0) and weapon == "laser" \
                        and laser_cd <= 0.0 and laser_live > 0.0

func _thunder_on() -> bool:
        return (firing or fire_pulse > 0.0) and weapon == "thunder" \
                        and thunder_cd <= 0.0 and thunder_live > 0.0

func _strike_now() -> void:
        # a tap = ONE strike (the hold rhythm owns it while the finger is
        # down); the cooldown + live budget still rule everything
        if weapon != "thunder" or thunder_cd > 0.0 or thunder_live <= 0.0:
                return
        if thunder_clock > 0.0:
                return
        _do_strike()

func _do_strike() -> void:
        if enemies.is_empty():
                return
        var lvl := weapon_level()
        var hits_wanted := THUNDER_BASE_HITS + lvl
        # the FIRST victim obeys the shatter law too: a covered candidate
        # is passed over for an open one
        var first := {}
        var tried: Array = []
        while true:
                var cand := _nearest_enemy(ship.position, 760.0, tried)
                if cand.is_empty():
                        break
                if cand.has("shards") and _point_shard_blocked(cand,
                                _ring_entry(cand, ship.position)):
                        tried.append(cand)
                        continue
                first = cand
                break
        if first.is_empty():
                return
        var chain: Array = [first]
        var cursor: Vector2 = first["node"].position
        while chain.size() < hits_wanted:
                var nxt := _nearest_enemy(cursor, THUNDER_JUMP, chain)
                if nxt.is_empty():
                        break
                # the shatter law rides the chain too: a strike must ENTER
                # through the seam - a covered candidate is skipped and the
                # chain hunts the next neighbor instead
                if nxt.has("shards") and _point_shard_blocked(nxt,
                                _ring_entry(nxt, cursor)):
                        var skip: Array = chain.duplicate()
                        skip.append(nxt)
                        var alt := _nearest_enemy(cursor, THUNDER_JUMP, skip)
                        if alt.is_empty():
                                break
                        chain.append(alt)
                        cursor = alt["node"].position
                        continue
                chain.append(nxt)
                cursor = nxt["node"].position
        # the bolt: ship -> v1 -> v2 ... jagged white
        var pts: Array = [ship.position + Vector2(0, -50)]
        var prev := ship.position
        for e in chain:
                pts.append_array(_jag(prev, e["node"].position))
                prev = e["node"].position
        _fx_bolt(pts)
        for e in chain:
                _hurt(e, THUNDER_DMG + THUNDER_DMG_PER_LVL * lvl)
                _fx_flash(e["node"].position, 0.5, Color(0.9, 0.95, 1.0))
        Jukebox.sfx("dash_thunder", -3.0)
        shake = maxf(shake, 5.0)

func _drop_bomb() -> void:
        if bomb_cd > 0.0 or weapon != "bomb":
                return
        bomb_cd = BOMB_CD
        var b := Sprite2D.new()
        b.texture = _tex["bomb"]
        b.scale = Vector2(2.4, 2.4)
        b.position = ship.position + Vector2(0, -60)   # nose points UP = thrown UP
        world.add_child(b)
        bombs.append({"node": b, "fuse": 1.7})
        Jukebox.sfx("dash_bomb", -5.0)

# ================================================== DIRECTOR (kills = law)
## The owner: difficulty from KILLS, not score, not power - kills cannot
## be farmed, so endless stays hard and competitive. 10 tiers, one per
## 25 kills; each tier raises pressure, speed, shooter ratio, elite odds
## and enemy hull strength.

func tier() -> int:
        return mini(10, kills / 25)

func _spawn_every() -> float:
        return lerpf(1.15, 0.42, float(tier()) / 10.0)

func _speed_mult() -> float:
        return 1.0 + float(tier()) * 0.09

func _shooter_ratio() -> float:
        return 0.10 + float(tier()) * 0.035

func _tier_hp(base: int) -> int:
        return base + tier() / 2

func _roll_kind() -> String:
        var T := tier()
        # rare elites first (owner: "intense enemies appear rarely")
        if T >= 2 and rng.randf() < 0.025 + float(T) * 0.010:
                if T >= 5 and rng.randf() < 0.30:
                        return "ufo_pow"
                return "ufo_dbl" if (T >= 4 and rng.randf() < 0.5) else "ufo_shot"
        var pool: Array = []
        pool.append_array(["grunt", "grunt", "grunt", "grunt2", "runner"])
        if T >= 1:
                pool.append_array(["grunt2", "runner", "shooter"])
        if T >= 2:
                pool.append_array(["splitter", "shielded", "shatter", "shooter"])
        if T >= 3:
                pool.append_array(["tank", "shooter"])
        if T >= 5:
                pool.append_array(["tank", "shielded", "shatter"])
        # the shooter ratio rides its own law: sometimes force one in
        if rng.randf() < _shooter_ratio():
                pool.append("shooter")
        return String(pool[rng.randi_range(0, pool.size() - 1)])

func _spawn_enemy(kind: String, lane_i := -1, at := Vector2.ZERO,
                small := false) -> Dictionary:
        var d: Dictionary = ETYPES[kind]
        var n := Sprite2D.new()
        n.texture = _tex[String(d["tex"]).get_basename()]
        n.material = null
        var sc: float = float(d["scale"]) * (0.62 if small else 1.0)
        n.scale = Vector2.ONE * sc
        var ln := lane_i if lane_i >= 0 else rng.randi_range(0, LANES - 1)
        n.position = at if at != Vector2.ZERO \
                        else Vector2(_lane_x(ln), -130.0)
        world.add_child(n)
        var e := {
                "node": n, "kind": kind, "lane": ln,
                "hp": _tier_hp(int(d["hp"])),
                "score": int(d["score"]) * (1 if not small else 0.4),
                "spd": rng.randf_range(float(d["spd"][0]),
                                float(d["spd"][1])) * _speed_mult() \
                                * (1.35 if small else 1.0),
                "r": float(d["r"]) * (0.62 if small else 1.0),
                "sway": float(d.get("sway", 0.0)),
                "phase": rng.randf() * TAU,
                "fires": bool(d.get("fires", false)),
                "fire_t": rng.randf_range(0.8, 1.8),
                "splits": bool(d.get("splits", false)),
                "big": bool(d.get("big", false)),
                "bubble": int(d.get("bubble", 0)),
                "flash": 0.0,
        }
        if bool(d.get("shards", false)):
                # 1..3 shards, different speeds and sizes (owner spec)
                var n_sh := 1 + (rng.randi() % mini(3, 1 + tier() / 3))
                var gap := TAU / float(n_sh)
                # THE FAIRNESS LAW (owner: "make sure to tweak it accurately
                # so there will be an entry that faces the user side"): the
                # SEAM between shards lands at PI/2 (screen +y = toward the
                # player) on spawn - shard k is offset HALF a spacing so a
                # gap, never a shard, faces the player at frame one.
                var shards: Array = []
                for k in n_sh:
                        shards.append({
                                "ang": PI * 0.5 + (float(k) + 0.5) * gap,
                                "spd": rng.randf_range(1.1, 2.2)
                                                * (1.0 if k % 2 == 0 else -1.0),
                                "rad": rng.randf_range(88.0, 122.0),
                                "w": rng.randf_range(30.0, 44.0),
                        })
                e["shards"] = shards
                e["gap"] = gap * 0.32    # half-arc of each shard's cover
        if e["big"]:
                var g := Sprite2D.new()
                g.texture = _tex["fx_flare"]
                g.material = _add_mat()
                g.scale = Vector2.ONE * 0.4
                g.modulate = Color(1.0, 0.5, 0.4, 0.16)
                n.add_child(g)
        enemies.append(e)
        if String(d.get("elite", "")) != "":
                Jukebox.sfx("dash_alert", -6.0)
                _fx_popup(Vector2(n.position.x, 120.0), "!",
                                Color(1, 0.4, 0.3), 46)
        return e

# ================================================================== TICK

func _goga_tick(delta: float) -> void:
        var vp := get_viewport_rect().size
        frame_floor_ms = maxf(SPAM_FLOOR_MS,
                        1000.0 / maxf(10.0, Engine.get_frames_per_second()))
        flame_clock += delta
        if flame_clock >= 0.07:
                flame_clock = 0.0
                flame_frame = (flame_frame + 1) % 10
                flame.texture = _tex["fire_%02d" % (flame_frame * 2)]
        # ship bank decays back to level
        bank = lerpf(bank, 0.0, minf(1.0, delta * 9.0))
        ship.rotation = bank
        # star drift + wrap
        for s in star_pool:
                s.position.y += float(s.get_meta("spd")) * delta
                if s.position.y > vp.y + 30:
                        s.position.y = -30
                        s.position.x = rng.randf() * vp.x
        if invuln > 0.0:
                invuln -= delta
                ship.modulate.a = 0.45 + 0.4 * absf(sin(invuln * 18.0))
                if invuln <= 0.0:
                        ship.modulate.a = 1.0
        shake = maxf(0.0, shake - delta * 34.0)
        world.position = Vector2(rng.randf_range(-1, 1),
                        rng.randf_range(-1, 1)) * shake
        _tick_fx(delta)   # the VFX live through ready/game-over too
        if phase == "ready":
                # idle bob so the ready screen breathes
                ship.position.y = _ship_home().y + sin(Time.get_ticks_msec()
                                / 1000.0 * 2.2) * 7.0

        if phase != "run" or over:
                fx.queue_redraw()
                laser_beam.queue_redraw()   # never freeze a stale beam
                return

        # ---- weapons clocks ----
        fire_pulse = maxf(0.0, fire_pulse - delta)
        beam_cd = maxf(0.0, beam_cd - delta)
        bomb_cd = maxf(0.0, bomb_cd - delta)
        if laser_cd > 0.0:
                laser_cd -= delta
                if laser_cd <= 0.0:
                        laser_live = LASER_LIVE
        elif _laser_on():
                laser_live -= delta
                _laser_burn(delta)
                if laser_live <= 0.0:
                        laser_cd = LASER_CD
        if thunder_cd > 0.0:
                thunder_cd -= delta
                if thunder_cd <= 0.0:
                        thunder_live = THUNDER_LIVE
        elif _thunder_on():
                thunder_live -= delta
                thunder_clock -= delta
                if thunder_clock <= 0.0:
                        thunder_clock = THUNDER_GAP
                        _do_strike()
                if thunder_live <= 0.0:
                        thunder_cd = THUNDER_CD
                        thunder_clock = 0.0
        else:
                thunder_clock = 0.0
        if firing and weapon == "beam" and beam_cd <= 0.0:
                beam_cd = BEAM_CAD
                _fire_beams()

        # ---- spawn director ----
        spawn_clock -= delta
        if spawn_clock <= 0.0:
                spawn_clock = _spawn_every() * rng.randf_range(0.8, 1.25)
                _spawn_enemy(_roll_kind())

        _tick_enemies(delta)
        _tick_bolts(delta, vp)
        _tick_ebolts(delta, vp)
        _tick_bombs(delta)
        _tick_loots(delta, vp)
        laser_beam.queue_redraw()
        fx.queue_redraw()

# ---------------------------------------------------------------- enemies

func _tick_enemies(delta: float) -> void:
        var vp := get_viewport_rect().size
        for e in enemies.duplicate():
            if not is_instance_valid(e["node"]):
                    enemies.erase(e)
                    continue
            var n: Sprite2D = e["node"]
            n.position.y += float(e["spd"]) * delta
            if float(e["sway"]) > 0.0:
                    e["phase"] += delta * 3.0
                    n.position.x = _lane_x(int(e["lane"])) \
                                    + sin(float(e["phase"])) * float(e["sway"])
            if e["bubble"] > 0:
                    e["phase"] += delta
            if e.has("shards"):
                    for sh in e["shards"]:
                            sh["ang"] += float(sh["spd"]) * delta
            if e["flash"] > 0.0:
                    e["flash"] -= delta
                    (n as Sprite2D).modulate = Color(1, 1, 1) \
                                    if e["flash"] <= 0.0 \
                                    else Color(3, 3, 3)
            # shooters fire red bolts down their lane
            if bool(e["fires"]):
                    e["fire_t"] -= delta
                    if e["fire_t"] <= 0.0:
                            e["fire_t"] = maxf(1.3, 2.5 - float(tier()) * 0.09)
                            _enemy_fire(n.position, Vector2(0, 1))
            var kind: Dictionary = ETYPES[e["kind"]]
            match String(kind.get("elite", "")):
                    "shot":
                            e["fire_t"] -= delta
                            if e["fire_t"] <= 0.0:
                                    e["fire_t"] = 1.7
                                    _shotgun(n.position, 5, 0.34)
                    "double":
                            e["fire_t"] -= delta
                            if e["fire_t"] <= 0.0:
                                    e["fire_t"] = 2.2
                                    _shotgun(n.position + Vector2(-40, 0),
                                                    4, 0.30)
                                    _shotgun(n.position + Vector2(40, 0),
                                                    4, 0.30)
                    "power":
                            e["fire_t"] -= delta
                            if e["fire_t"] <= 0.0:
                                    e["fire_t"] = 1.5
                                    _shotgun(n.position, 7, 0.5, 520.0)
            # hull vs ship = a wreck for BOTH (no score for dying on me)
            if invuln <= 0.0 and n.position.distance_to(ship.position) \
                                    < float(e["r"]) + SHIP_R:
                    _explode(e, false)
                    enemies.erase(e)
                    n.queue_free()
                    _wreck()
                    continue
            if n.position.y > vp.y + 160:
                    enemies.erase(e)
                    n.queue_free()

func _enemy_fire(at: Vector2, dir: Vector2, spd := 0.0) -> void:
        var b := Sprite2D.new()
        b.texture = _tex["enemy_bolt"]
        b.material = _add_mat()
        b.scale = Vector2(2.6, 2.6)
        b.position = at + dir * 40.0
        b.rotation = dir.angle() + PI / 2.0
        world.add_child(b)
        ebolts.append({"node": b, "v": dir.normalized()
                        * (spd if spd > 0 else 400.0 + float(tier()) * 14.0)})

func _shotgun(at: Vector2, n_pellets: int, spread: float,
                spd := 430.0) -> void:
        var aim := (ship.position - at).normalized()
        for k in n_pellets:
                var a := -spread * 0.5 + spread * float(k) \
                                / float(maxi(1, n_pellets - 1))
                _enemy_fire(at, aim.rotated(a), spd)

func _nearest_enemy(from: Vector2, max_d: float, skip: Array = []) -> Dictionary:
        var best := {}
        var bd := max_d
        for e in enemies:
                if e in skip or not is_instance_valid(e["node"]):
                        continue
                var d: float = e["node"].position.distance_to(from)
                if d < bd:
                        bd = d
                        best = e
        return best

# ------------------------------------------------------------------ bolts

func _tick_bolts(delta: float, vp: Vector2) -> void:
        for b in bolts.duplicate():
                var n: Sprite2D = b["node"]
                if not is_instance_valid(n):
                        bolts.erase(b)
                        continue
                n.position.y -= 1000.0 * delta
                if n.position.y < -80:
                        bolts.erase(b)
                        n.queue_free()
                        continue
                # pierce-free beam bolt: first hull OR shatter arc it meets
                for e in enemies:
                        if not is_instance_valid(e["node"]):
                                continue
                        if e.has("shards") and _point_shard_blocked(e, n.position):
                                bolts.erase(b)
                                n.queue_free()
                                _fx_sparks(n.position, 3,
                                                Color(0.6, 0.9, 1.0), 120.0)
                                Jukebox.sfx("dash_shield_hit", -14.0, 1.4)
                                break
                        if n.position.distance_to(e["node"].position) \
                                        < float(e["r"]):
                                _hurt(e, int(b["dmg"]))
                                bolts.erase(b)
                                n.queue_free()
                                break

func _tick_ebolts(delta: float, vp: Vector2) -> void:
        for b in ebolts.duplicate():
                var n: Sprite2D = b["node"]
                if not is_instance_valid(n):
                        ebolts.erase(b)
                        continue
                n.position += Vector2(b["v"]) * delta
                if n.position.y > vp.y + 60 or n.position.x < -60 \
                                or n.position.x > vp.x + 60:
                        ebolts.erase(b)
                        n.queue_free()
                        continue
                if invuln <= 0.0 and n.position.distance_to(ship.position) \
                                                < SHIP_R + 22.0:
                        ebolts.erase(b)
                        n.queue_free()
                        _wreck()

# ------------------------------------------------------------------ bombs

func _tick_bombs(delta: float) -> void:
        for b in bombs.duplicate():
                var n: Sprite2D = b["node"]
                if not is_instance_valid(n):
                        bombs.erase(b)
                        continue
                n.position.y -= 430.0 * delta
                b["fuse"] = float(b["fuse"]) - delta
                if Engine.get_frames_drawn() % 2 == 0:
                        _fx_puff(n.position + Vector2(0, 26), 0.5)
                var boom_at := n.position
                var hit := float(b["fuse"]) <= 0.0
                if not hit:
                        for e in enemies:
                                if is_instance_valid(e["node"]) \
                                                and n.position.distance_to(
                                                e["node"].position) \
                                                < float(e["r"]) + 26.0:
                                        hit = true
                                        break
                if hit:
                        bombs.erase(b)
                        n.queue_free()
                        _bomb_blast(boom_at)

func _bomb_blast(at: Vector2) -> void:
        var lvl := weapon_level()
        var r := BOMB_R + BOMB_R_PER_LVL * float(lvl)
        var dmg := BOMB_DMG + BOMB_DMG_PER_LVL * float(lvl)
        for e in enemies.duplicate():
                if not is_instance_valid(e["node"]):
                        continue
                var d: float = e["node"].position.distance_to(at)
                if d < r + float(e["r"]):
                        # shatters do NOT stop a blast wave (it is not a shot)
                        var falloff := lerpf(1.0, 0.45,
                                        clampf(d / maxf(1.0, r), 0.0, 1.0))
                        _hurt(e, int(round(dmg * falloff)))
        _fx_blast(at, r)
        Jukebox.sfx("dash_boom", -2.0)
        shake = maxf(shake, 13.0)

# ------------------------------------------------------------------- hurt

func _hurt(e: Dictionary, dmg: int) -> void:
        if not is_instance_valid(e["node"]):
                return
        if int(e.get("bubble", 0)) > 0:
                e["bubble"] = int(e["bubble"]) - 1
                e["flash"] = 0.06
                _fx_sparks(e["node"].position, 5, Color(0.55, 0.9, 1.0), 160.0)
                Jukebox.sfx("dash_shield_hit", -10.0)
                if int(e["bubble"]) == 0:
                        _fx_ring(e["node"].position, float(e["r"]) + 26.0,
                                        Color(0.55, 0.9, 1.0), 0.3)
                return
        e["hp"] = int(e["hp"]) - dmg
        e["flash"] = 0.06
        if int(e["hp"]) <= 0:
                _explode(e, true)

func _explode(e: Dictionary, pays: bool) -> void:
        var n: Sprite2D = e["node"]
        if not is_instance_valid(n):
                return
        var big := bool(e.get("big", false))
        _fx_explosion(n.position, 1.6 if big else 1.0,
                        Color(1.0, 0.75, 0.35))
        Jukebox.sfx("dash_boom_big" if big else "dash_boom_small",
                        -4.0 if big else -8.0,
                        randf_range(0.92, 1.1))
        shake = maxf(shake, 8.0 if big else 3.0)
        if pays:
                var sc := int(e["score"])
                _score_gain(sc)
                _fx_popup(n.position, "+%d" % sc,
                                Color(1, 0.95, 0.6) if not big
                                                else Color(1, 0.6, 0.4),
                                44 if big else 32)
                kills += 1
                achievement_count("kills", 1)
                achievement_max("best_kills", kills)
                _roll_drop(n.position, big)
                if bool(e.get("splits", false)):
                        var ln := int(e["lane"])
                        for off in [-1, 1]:
                                var nl := clampi(ln + off, 0, LANES - 1)
                                _spawn_enemy("grunt", nl,
                                        Vector2(_lane_x(nl),
                                                n.position.y - 40.0), true)
        enemies.erase(e)
        n.queue_free()

# ------------------------------------------------------------------- loot
## Everything comes from WRECKS (owner law). Coins: 1 per 5-10 kills
## counting from the last coin COLLECTED. Other items roll per kill;
## weapon/shield items only EXIST once bought in the shop.

func _roll_drop(at: Vector2, big: bool) -> void:
        kills_since_coin += 1
        if kills_since_coin >= coin_target:
                kills_since_coin = 0
                coin_target = rng.randi_range(COIN_KILLS_MIN, COIN_KILLS_MAX)
                _drop(at, "coin")
                return
        if rng.randf() < 0.16:
                _drop(at, "power")
                return
        if Box.item_owned(game_id, "shield", "__on__") \
                        and rng.randf() < 0.05:
                _drop(at, "shield")
                return
        for wid in SHOP_WEAPONS:
                if Box.item_owned(game_id, "weapons", wid) \
                                and rng.randf() < 0.05:
                        _drop(at, "w_" + wid)
                        return
        if big and rng.randf() < 0.5:
                _drop(at, "power")

func _drop(at: Vector2, kind: String) -> void:
        var n := Sprite2D.new()
        match kind:
                "coin":
                        n.texture = _tex["coin"]
                        n.scale = Vector2.ONE * (74.0 / 128.0)
                "power":
                        n.texture = _tex["item_power"]
                        n.scale = Vector2.ONE * 2.4
                "shield":
                        n.texture = _tex["shield_1"]
                        n.scale = Vector2.ONE * 0.5
                        n.modulate = Color(0.6, 1.0, 1.0, 0.95)
                "w_laser":
                        n.texture = _tex["item_laser"]
                        n.scale = Vector2.ONE * 2.2
                "w_thunder":
                        n.texture = _tex["item_thunder"]
                        n.scale = Vector2.ONE * 2.6
                "w_bomb":
                        n.texture = _tex["item_bomb"]
                        n.scale = Vector2.ONE * 2.2
        n.position = at
        world.add_child(n)
        loots.append({"node": n, "kind": kind})

func _tick_loots(delta: float, vp: Vector2) -> void:
        for l in loots.duplicate():
                var n: Sprite2D = l["node"]
                if not is_instance_valid(n):
                        loots.erase(l)
                        continue
                n.position.y += 230.0 * delta
                if l["kind"] == "coin":
                        n.rotation += delta * 3.0
                if n.position.y > vp.y + 70:
                        loots.erase(l)
                        n.queue_free()
                        continue
                if n.position.distance_to(ship.position) < SHIP_R + 42.0:
                        loots.erase(l)
                        _collect(String(l["kind"]), n.position)
                        n.queue_free()

func _collect(kind: String, at: Vector2) -> void:
        match kind:
                "coin":
                        add_run_coins(1)   # ONE goga coin (owner spec)
                        Jukebox.sfx("dash_coin", -5.0)
                        _fx_popup(at, "+1", Arc.COIN, 30)
                "power":
                        Jukebox.sfx("dash_pick", -5.0)
                        _add_power(1)
                        _fx_flash(at, 0.4, Color(0.6, 0.85, 1.0))
                "shield":
                        if shield_lvl < 3:
                                shield_lvl += 1
                                Jukebox.sfx("dash_shield", -4.0)
                                _fx_ring(ship.position, 90.0 + 24.0
                                                * float(shield_lvl),
                                                Color(0.55, 0.9, 1.0), 0.45)
                        else:
                                _score_gain(25)
                                Jukebox.sfx("dash_pick", -5.0)
                                _fx_popup(ship.position + Vector2(0, -70),
                                                "+25", Color(0.55, 0.9, 1.0),
                                                30)
                        _refresh_hud2()
                "w_laser", "w_thunder", "w_bomb":
                        var wid := kind.substr(2)
                        Jukebox.sfx("dash_weapon", -4.0)
                        if weapon == wid:
                                _add_power(2)   # same gun: feeds IT instead
                        else:
                                weapon = wid
                                _refresh_hud2()
                        _fx_ring(ship.position, 80.0, Color(1, 0.8, 0.9), 0.4)

# ------------------------------------------------- score / hearts / wreck

## ALL score gains ride THIS (kills, maxed-weapon refunds) so the +1-heart
## per 1000 law fires in one place. Losses (wrecks) go through set_score
## directly - a wreck must never re-arm the next heart EARLIER.
func _score_gain(v: int) -> void:
        add_score(v)
        while score >= next_heart_at:
                next_heart_at += HEART_EVERY
                hearts += 1
                Jukebox.sfx("dash_heart", -4.0)
                _fx_popup(ship.position + Vector2(0, -110), "+1 HEART",
                                Color(1, 0.6, 0.7), 34)
                _refresh_hud2()

## A wreck: shield eats it first (one level), else -500 score, -1 heart,
## -3 power rungs on the CURRENT weapon, 1.4s grace. The death that takes
## the last heart ends the run (owner law).
func _wreck() -> void:
        if invuln > 0.0 or over:
                return
        if shield_lvl > 0:
                shield_lvl -= 1
                invuln = 0.9
                Jukebox.sfx("dash_shield_hit", -4.0)
                _fx_ring(ship.position, 120.0, Color(0.55, 0.9, 1.0), 0.4)
                _fx_sparks(ship.position, 10, Color(0.55, 0.9, 1.0), 260.0)
                shake = maxf(shake, 7.0)
                _refresh_hud2()
                return
        hearts -= 1
        invuln = INVULN_T
        Jukebox.sfx("dash_hit", -2.0)
        Jukebox.sfx("dash_boom", -4.0)
        _fx_explosion(ship.position, 1.3, Color(1.0, 0.55, 0.35))
        shake = 16.0
        set_score(maxi(0, score + WRECK_SCORE))
        # power: exactly 3 rungs down the current weapon (owner law)
        var lvl := weapon_level()
        var dropped: int = POWER_LADDER[maxi(0, lvl - DEATH_POWER_RUNGS)]
        power[weapon] = dropped
        _refresh_hud2()
        if hearts <= 0:
                _game_over()
        _refresh_hud2()

func _game_over() -> void:
        if over:
                return
        phase = "over"
        Jukebox.sfx("dash_over", -3.0)
        Jukebox.stop_music()   # the run's music dies with the run
        achievement_max("max_power", int(power[weapon]))
        var tw := create_tween()
        tw.tween_property(ship, "modulate", Color(1, 0.5, 0.4, 0.0), 0.7)
        tw.parallel().tween_property(ship, "rotation", 1.2, 0.7)
        tw.parallel().tween_property(ship, "position:y",
                        ship.position.y + 160.0, 0.7)
        tw.tween_callback(func():
                check_achievements()
                finish_run(score))

# ---------------------------------------------------------- shatter shards

## Do the carrier's orbiting shards block this point? A shard COVERS the
## arc within `e["gap"]` (half-arc) around its own angle; the seam between
## two shards is the opening the owner asked for. Point angle is measured
## from the carrier's center in screen space (+y down = toward player).
func _point_shard_blocked(e: Dictionary, at: Vector2) -> bool:
        var c: Vector2 = e["node"].position
        var d := at.distance_to(c)
        for sh in e["shards"]:
                if absf(d - float(sh["rad"])) > float(sh["w"]) * 0.5 + 16.0:
                        continue
                var a := atan2(at.y - c.y, at.x - c.x)
                var diff := absf(wrapf(a - float(sh["ang"]), -PI, PI))
                if diff > float(e["gap"]):
                        continue   # outside this shard's cover - try the next
                return true   # covered by THIS shard's arc
        return false

## Where a SHOT travelling from `from_pt` toward the carrier crosses the
## shard ring (the entry point the shot must survive).
func _ring_entry(e: Dictionary, from_pt: Vector2) -> Vector2:
        var c: Vector2 = e["node"].position
        var r := float(e["shards"][0]["rad"])
        var dir := (c - from_pt).normalized()
        return c - dir * r

# -------------------------------------------------------------- the laser

var _laser_hits: Array = []   # impact points for the painter

func _laser_burn(delta: float) -> void:
        var lvl := weapon_level()
        var dps := LASER_DPS + LASER_DPS_PER_LVL * float(lvl)
        var half := LASER_HALF_W + 2.0 * float(lvl)
        var x := ship.position.x
        _laser_hits.clear()
        for e in enemies.duplicate():
                if not is_instance_valid(e["node"]):
                        continue
                var n: Sprite2D = e["node"]
                if absf(n.position.x - x) > half + float(e["r"]) * 0.5:
                        continue
                if n.position.y > ship.position.y:
                        continue   # the beam goes UP, not through the ship
                # the owner's shatter law: the beam must ENTER through the
                # open seam too - a covered ring entry stops the burn and
                # sparks at the crossing point instead
                if e.has("shards"):
                        var entry := _ring_entry(e, ship.position)
                        if _point_shard_blocked(e, entry):
                                if _laser_hits.size() < 6:
                                        _laser_hits.append(entry)
                                continue
                _laser_hits.append(n.position)
                e["hp"] = int(e["hp"]) - int(round(dps * delta))
                e["flash"] = 0.05
                if int(e["hp"]) <= 0:
                        _explode(e, true)
        if Engine.get_frames_drawn() % 6 == 0:
                Jukebox.sfx("dash_laser", -16.0, randf_range(0.98, 1.04))

# ================================================================ PAINTERS

func _draw_guides(g: Node2D) -> void:
        var vp := get_viewport_rect().size
        var col := Color(0.55, 0.85, 1.0, 0.10)   # ALPHA lanes (owner law)
        for i in range(LANES + 1):
                var x := _lane_x(0) - LANE_W / 2.0 + LANE_W * float(i)
                g.draw_line(Vector2(x, 0), Vector2(x, vp.y), col, 3.0)
        # a soft landing strip where the ship patrols
        g.draw_line(Vector2(_lane_x(0) - LANE_W / 2.0, vp.y * SHIP_Y_FRAC),
                        Vector2(_lane_x(LANES - 1) + LANE_W / 2.0,
                        vp.y * SHIP_Y_FRAC), Color(0.55, 0.85, 1.0, 0.05),
                        60.0)

func _draw_laser() -> void:
        if not _laser_on():
                return
        var lvl := weapon_level()
        var w := 10.0 + 2.0 * float(lvl)
        var top := Vector2(ship.position.x, 0.0)
        var from := ship.position + Vector2(0, -60)
        # outer glow, then the hot core
        laser_beam.draw_line(from, top, Color(1.0, 0.25, 0.2, 0.30), w * 3.2)
        laser_beam.draw_line(from, top, Color(1.0, 0.45, 0.3, 0.65), w * 1.5)
        laser_beam.draw_line(from, top, Color(1.0, 0.9, 0.8, 0.95), w * 0.55)
        for h in _laser_hits:
                laser_beam.draw_circle(h, w * 1.6, Color(1.0, 0.5, 0.3, 0.5))

# ---- fx state (one painter node, arrays + one _draw: mobile-cheap) ----
var _sparks: Array = []      # {p, v, life, t0, col}
var _rings: Array = []       # {p, r, life, t, col}
var _flashes: Array = []     # {p, s, life, t, col}
var _popups: Array = []      # {p, txt, life, t, col, size}
var _puffs: Array = []       # {p, life, t}
var _bolts: Array = []       # {pts, life, t}
var _blast: Array = []       # {p, r, life, t}

func _fx_sparks(at: Vector2, n: int, col: Color, spd: float) -> void:
        for i in n:
                _sparks.append({"p": at, "v": Vector2.from_angle(
                                rng.randf() * TAU) * rng.randf_range(
                                spd * 0.4, spd), "life": rng.randf_range(
                                0.25, 0.55), "t": 0.0, "col": col})

func _fx_ring(at: Vector2, r: float, col: Color, life := 0.35) -> void:
        _rings.append({"p": at, "r": r, "life": life, "t": 0.0, "col": col})

func _fx_flash(at: Vector2, s: float, col: Color) -> void:
        _flashes.append({"p": at, "s": s, "life": 0.16, "t": 0.0, "col": col})

func _fx_popup(at: Vector2, txt: String, col: Color, size := 32) -> void:
        _popups.append({"p": at, "txt": txt, "life": 0.75, "t": 0.0,
                        "col": col, "size": size})

func _fx_puff(at: Vector2, s: float) -> void:
        _puffs.append({"p": at, "life": 0.5, "t": 0.0, "s": s})

func _fx_bolt(pts: Array) -> void:
        _bolts.append({"pts": pts, "life": 0.13, "t": 0.0})

func _fx_blast(at: Vector2, r: float) -> void:
        _blast.append({"p": at, "r": r, "life": 0.45, "t": 0.0})

func _fx_explosion(at: Vector2, s: float, col: Color) -> void:
        _fx_flash(at, 1.4 * s, col)
        _fx_ring(at, 60.0 * s, col, 0.32)
        _fx_sparks(at, int(10 * s), col, 240.0 * s)
        for i in int(2 * s):
                _fx_puff(at + Vector2(rng.randf_range(-30, 30),
                                rng.randf_range(-30, 30)), 1.2 * s)

func _tick_fx(delta: float) -> void:
        for arr in [_sparks, _rings, _flashes, _popups, _puffs, _bolts,
                        _blast]:
                for it in arr.duplicate():
                        it["t"] = float(it["t"]) + delta
                        if it.has("v"):   # sparks fly (the only moving kind)
                                it["p"] = Vector2(it["p"]) \
                                                + Vector2(it["v"]) * delta
                                it["v"] = Vector2(Vector2(it["v"]).x * 0.98,
                                                Vector2(it["v"]).y * 0.98
                                                + 300.0 * delta)
                        if float(it["t"]) >= float(it["life"]):
                                arr.erase(it)

func _draw_fx() -> void:
        var f := Arc.font_big()
        for b in _bolts:
                var k: float = 1.0 - float(b["t"]) / float(b["life"])
                var pts: Array = b["pts"]
                for i in range(1, pts.size()):
                        laser_beam.draw_line(Vector2(pts[i - 1]),
                                        Vector2(pts[i]),
                                        Color(0.9, 0.95, 1.0, 0.9 * k), 7.0)
                        laser_beam.draw_line(Vector2(pts[i - 1]),
                                        Vector2(pts[i]),
                                        Color(1, 1, 1, 0.95 * k), 2.5)
        for s in _sparks:
                var k: float = 1.0 - float(s["t"]) / float(s["life"])
                fx.draw_circle(Vector2(s["p"]), 3.0 + 4.0 * k,
                                Color(Color(s["col"]), k * 0.9))
        for r in _rings:
                var k: float = float(r["t"]) / float(r["life"])
                fx.draw_arc(Vector2(r["p"]), float(r["r"]) * (0.4 + 0.9 * k),
                                0, TAU, 40,
                                Color(Color(r["col"]), (1.0 - k) * 0.8), 6.0)
        for fl in _flashes:
                var k: float = 1.0 - float(fl["t"]) / float(fl["life"])
                fx.draw_circle(Vector2(fl["p"]), 70.0 * float(fl["s"]) * k,
                                Color(Color(fl["col"]), k * 0.75))
        for p in _puffs:
                var k: float = float(p["t"]) / float(p["life"])
                fx.draw_circle(Vector2(p["p"]) + Vector2(0, -40.0 * k),
                                30.0 * float(p["s"]) * (0.6 + k * 0.8),
                                Color(0.35, 0.35, 0.4, (1.0 - k) * 0.30))
        for bl in _blast:
                var k: float = float(bl["t"]) / float(bl["life"])
                fx.draw_circle(Vector2(bl["p"]),
                                float(bl["r"]) * (0.35 + 0.75 * k),
                                Color(1.0, 0.7, 0.35, (1.0 - k) * 0.5))
                fx.draw_arc(Vector2(bl["p"]), float(bl["r"]) * (0.5 + 0.7 * k),
                                0, TAU, 48,
                                Color(1.0, 0.85, 0.5, (1.0 - k) * 0.9), 10.0)
        # the player shield aura - deeper level reads denser (owner law)
        if shield_lvl > 0 and is_instance_valid(ship):
                var a: float = [0.0, 0.12, 0.20, 0.30][shield_lvl]
                fx.draw_circle(ship.position, SHIP_R + 34.0
                                + 6.0 * float(shield_lvl),
                                Color(0.45, 0.85, 1.0, a))
                fx.draw_arc(ship.position, SHIP_R + 34.0
                                + 6.0 * float(shield_lvl), 0, TAU, 48,
                                Color(0.7, 0.95, 1.0, a + 0.25), 4.0)
        for p in _popups:
                var k: float = float(p["t"]) / float(p["life"])
                var pos := Vector2(p["p"]) + Vector2(0, -70.0 * k)
                var txt := String(p["txt"])
                var sz := int(p["size"])
                fx.draw_string(f, pos, txt, HORIZONTAL_ALIGNMENT_CENTER,
                                240.0, sz, Color(0, 0, 0, 0.5 * (1.0 - k)))
                fx.draw_string(f, pos, txt, HORIZONTAL_ALIGNMENT_CENTER,
                                240.0, sz,
                                Color(Color(p["col"]), 1.0 - k * k))

func _jag(a: Vector2, b: Vector2) -> Array:
        # 3-4 jagged sub-segments for the lightning painter
        var out: Array = []
        var n := 3 + (rng.randi() % 2)
        for i in range(1, n):
                var p := a.lerp(b, float(i) / float(n))
                var dir := (b - a).normalized().orthogonal()
                p += dir * rng.randf_range(-34.0, 34.0)
                out.append(p)
        out.append(b)
        return out



