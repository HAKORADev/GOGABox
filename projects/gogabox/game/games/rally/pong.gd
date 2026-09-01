extends GogaGame
## PONG (v0.2.2 - the full rebuild; the owner: "currently it's just called a
## game for no reason" - fixed, it is a GAME now).
##
## THE SHAPE: position ask (the universal reload) -> options screen (the
## optionals strip + the shop) -> the run. The run never ends by itself -
## the pause sheet's END button is the ONLY way to bank the earnings.
##
## THE LAWS (owner v0.2.3 round):
## - a goal FOR the user = +1 point; a goal ON the user = -1 point
## - the ball heats x1.1 per EVERY hit (wall or platform), reset per serve;
##   it burns yellow -> red and the tail grows with the heat (PGB v1.3.8
##   trail, grown up); the ceiling is x5 and BOOST/STRIKE ride PAST it
## - the serve is born at the MIDDLE of the field, flying TOWARD the
##   platform that conceded (never glued to a pad again)
## - the platforms are WALLS: the ball's move is swept against the pad's
##   face plane, so it bounces exactly where it touched - a fast ball can
##   never tunnel through, teleport or "spawn weirdly" (owner report)
## - ONE GOGACoin on the court at a time: a new one spawns 5-20s after the
##   last one was collected; the last platform that kicked the ball earns
##   it; every 3 points pays one bonus coin
## - the AI reads the ball only inside a SHORT range around its own edge -
##   beyond it the pad drifts back to center, which makes it beatable
## - controls: hold anywhere, the platform follows the finger ALONG its
##   axis only - up/down finger wander never steals the paddle
## - powerups ride the ball: the last kicker's platform wears size mods
##   (FIXED px values, clamped), the ball wears speed mods
## - MORE ENEMIES: two extra platforms on the other walls, all of them
##   hunting the player (never each other)

const BALL_R := 16.0
const BALL_BASE := 340.0
const HEAT_STEP := 1.1           # x1.1 per hit (owner spec)
const HEAT_MAX := 5.0            # the burn ceiling (owner: "x5 is more better")
const SERVE_HOLD := 0.9          # the breath before the launch
const PAD_THICK := 26.0
const PAD_NORMAL := 168.0        # the NORMAL platform length (fixed px)
const PAD_MIN := 64.0            # never smaller than this
const PAD_MAX := 420.0           # never bigger than this
const PAD_STEP := 36.0           # wide/shrink fixed px (owner: no %)
const MEGA_T := 10.0             # mega/mini seconds
const COIN_MIN_T := 5.0
const COIN_MAX_T := 20.0
const COIN_R := 15.0
const PU_MIN_T := 8.0
const PU_MAX_T := 18.0
const PU_R := 22.0
const SCORE_PER_COIN := 3        # every 3 points = one bonus coin
const AI_SPEED := 430.0          # the main rival
const AI_SPEED_EXTRA := 356.0    # the extra walls hunt slower
const AI_THINK := 0.13           # reaction lag (not stupid, not a wall)
const AI_VISION := 0.42          # owner v0.2.3: the AI only READS the ball
                                 # inside this fraction of the field depth
                                 # from its own edge - outside it, it drifts
                                 # back to center and can be wrong-footed

const COL_COURT := Color("0e0e13")     # the dark (the owner's 0a0a0a, warmed)
const COL_LINE := Color(1, 1, 1, 0.07)
const COL_ENEMY := Color("e8402f")     # THE red (goals widget + enemy pads)
const COL_ENEMY_2 := Color("c43040")
const COL_BALL_COLD := Color("ffe14d") # bright yellow
const COL_BALL_HOT := Color("ff3820")  # the burn
const COL_COIN := Color("ffc93c")

# platform skins (the user's own color; the enemy stays red)
const SKINS := {
        "classic": {"name": "BLUE", "col": Color("3f7fd4"), "price": 0},
        "mint": {"name": "MINT", "col": Color("3fc48c"), "price": 120},
        "ember": {"name": "EMBER", "col": Color("e8783a"), "price": 120},
        "violet": {"name": "VIOLET", "col": Color("8a5ac4"), "price": 180},
        "gold": {"name": "GOLD", "col": Color("e8b23a"), "price": 300},
}
const UNLOCKS := {
        "pong_size": {"name": "SIZE PACK", "price": 400,
                        "sub": "wide / shrink forever - mega / mini for 10s"},
        "pong_speed": {"name": "SPEED PACK", "price": 350,
                        "sub": "ball boost +50% - strike +200% until the next hit"},
        "pong_sparkles": {"name": "PLATFORM SPARKLES", "price": 250,
                        "sub": "the court shreds wear your color + hit dust"},
        "pong_more": {"name": "MORE ENEMIES", "price": 500,
                        "sub": "two extra walls hunt you - more goals both ways"},
}

# ------------------------------------------------------------------ state
var landscape := false
var field := Rect2()
var pads: Array = []             # platform dicts (see _add_pad)
var pads_by_id := {}
var ball_pos := Vector2.ZERO
var ball_prev := Vector2.ZERO    # where the ball was BEFORE this frame's move
var ball_dir := Vector2.DOWN
var heat := 1.0                  # the x1.1^n burn
var boost_on := false            # +50% until respawn
var strike_on := false           # +200% until the next hit
var serve_t := 0.0               # >0 = the ball waits at the serve spot
var serve_from := "user"
var trail: Array = []            # [[pos, life], ...] - the PGB tail
var coins: Array = []            # [{p, pop}]
var coin_t := 0.0
var pus: Array = []              # [{id, p, pop}]
var pu_t := 0.0
var goals_user := 0
var goals_enemy := 0
var next_coin_at := SCORE_PER_COIN
var last_kicker := "user"
var rally := 0                   # returns this run (the old achievements)
var _held := -1                  # the steering finger
var _phase := "orient"           # orient -> options -> run
var _time := 0.0
var _flash_t := 0.0
var _flash_pos := Vector2.ZERO
var _dust: Array = []            # sparkle hit dust
var _shreds: Array = []          # the court's light shreds
var _motes: Array = []
var _coin_tex: Texture2D = preload("res://assets/ui/coin.png")
var _view: Node2D
var _goals_lbl_u: Label
var _goals_lbl_e: Label
var _heat_lbl: Label
var _overlay_panel: Control

class PongView:
        extends Node2D
        var g: Node2D
        func _draw() -> void:
                g._paint(self)

# ============================================================== SETUP

func _goga_setup() -> void:
        pause_end_run = true    # END in the pause sheet - the only payout
        var forced := start_orientation
        landscape = forced == "horizontal" if forced != "" \
                        else _auto_landscape()
        _build_world()
        _view = PongView.new()
        _view.g = self
        add_child(_view)
        set_hud_score_prefix("PONG")
        _heat_lbl = add_hud_chip("x1.00")
        add_hud_button("SHOP", func(): _shop_open())
        Jukebox.music("res://assets/audio/music/pong_theme.wav")
        if forced != "":
                _show_options()   # the ask is behind us (reload path)
        else:
                _show_orient_select()

func _auto_landscape() -> bool:
        var vp := get_viewport_rect().size
        return vp.x > vp.y

func orientation_settled() -> void:
        if _overlay_panel != null:
                landscape = _auto_landscape()
                _rebuild_for_orientation()
                _show_options()

## THE TAP LAW - the same as the snake's: the live window decides, the
## saved pref is remembered but decides nothing.
func _orient_choice(choice: String) -> void:
        Jukebox.sfx("confirm", -4.0)
        Box.set_progress(game_id, "orient_pref", choice)
        if choice == ("horizontal" if _auto_landscape() else "vertical"):
                _rebuild_for_orientation()
                _show_options()
        else:
                request_orientation_reload.emit(choice)

## v0.2.3 OWNER CALL: the ask "talks too much" - it is JUST the two phone
## cards now. No title, no subtitle, no walls line; the word under each
## phone is the whole sentence.
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
        _overlay_panel = dim

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

# ------------------------------------------------------- the options screen

func _opt_on(key: String) -> bool:
        return bool(Box.get_progress(game_id, "opt_" + key, false))

func _owned(key: String) -> bool:
        return Box.unlock_owned(game_id, key)

func _user_col() -> Color:
        var skin := Box.skin_on(game_id)
        if SKINS.has(skin):
                return SKINS[skin]["col"]
        return SKINS["classic"]["col"]

func _show_options() -> void:
        _phase = "options"
        _clear_overlay()
        var dim := _dim_layer()
        var cc := _center_in(dim)
        var panel := PanelContainer.new()
        panel.add_theme_stylebox_override("panel",
                        Arc.panel_style(Color(1, 1, 1, 0.96), 26, 24))
        cc.add_child(panel)
        var vb := VBoxContainer.new()
        vb.add_theme_constant_override("separation", 14)
        panel.add_child(vb)
        var t := Arc.label("CHOOSE YOUR GAME", 38, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(t)
        var sub := Arc.label("goals win - the END button banks the coins", 19,
                        Color("8a6a40"), false)
        sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(sub)
        vb.add_child(_options_strip())
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 14)
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        vb.add_child(row)
        row.add_child(Arc.button("SHOP", Vector2(220, 78), 26, Color("6a5ab8"),
                        func(): _shop_open()))
        row.add_child(Arc.button("START", Vector2(300, 78), 30, Arc.GOOD,
                        func():
                                _clear_overlay()
                                _begin_run()))
        var hint := Arc.fit_label("hold anywhere - your platform follows the" \
                + " finger - every hit heats the ball x1.1", 16,
                Color("8a6a40"), 600, false)
        hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(hint)
        _overlay_panel = dim

## The optionals strip: SIZE / SPEED / SPARKLES / MORE ENEMIES. Locked
## boxes wear the price and open the shop (the snake's language).
func _options_strip() -> Control:
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 12)
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        for cfg in [
                {"key": "size", "unlock": "pong_size",
                                "icon": "pong_opt_size.png", "name": "SIZE MOD"},
                {"key": "speed", "unlock": "pong_speed",
                                "icon": "pong_opt_speed.png", "name": "SPEED"},
                {"key": "sparkles", "unlock": "pong_sparkles",
                                "icon": "pong_opt_sparkle.png",
                                "name": "SPARKLES"},
                {"key": "more", "unlock": "pong_more",
                                "icon": "pong_opt_more.png", "name": "MORE ENEMIES"},
        ]:
                var owned: bool = _owned(cfg["unlock"])
                var b := Button.new()
                b.custom_minimum_size = Vector2(136, 150)
                var sb := Arc.panel_style(
                                Arc.CARD if owned else Color(0, 0, 0, 0.06),
                                18, 8)
                b.add_theme_stylebox_override("normal", sb)
                var sbp := sb.duplicate() as StyleBoxFlat
                sbp.bg_color = sbp.bg_color.darkened(0.06)
                b.add_theme_stylebox_override("pressed", sbp)
                var vb := VBoxContainer.new()
                vb.set_anchors_preset(Control.PRESET_FULL_RECT)
                vb.alignment = BoxContainer.ALIGNMENT_CENTER
                vb.add_theme_constant_override("separation", 6)
                vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
                b.add_child(vb)
                var ic := TextureRect.new()
                ic.texture = load("res://assets/ui/%s" % cfg["icon"])
                ic.custom_minimum_size = Vector2(64, 64)
                ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                ic.modulate = Color(1, 1, 1, 1.0 if owned else 0.45)
                ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
                vb.add_child(ic)
                var nm := Arc.fit_label(String(cfg["name"]), 15,
                                Arc.INK if owned else Color("9a8a70"), 124)
                nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
                vb.add_child(nm)
                var st := Arc.fit_label(("ON" if _opt_on(cfg["key"]) \
                                else "OFF") if owned \
                                else "%d" % int(UNLOCKS[cfg["unlock"]]["price"]),
                                16, Color("58c470") if _opt_on(cfg["key"]) \
                                else Color("8a6a40"), 124)
                st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                st.mouse_filter = Control.MOUSE_FILTER_IGNORE
                vb.add_child(st)
                if owned:
                        b.pressed.connect(func():
                                        Jukebox.sfx("confirm", -6.0)
                                        Box.set_progress(game_id,
                                                "opt_" + String(cfg["key"]),
                                                not _opt_on(cfg["key"]))
                                        _show_options())
                else:
                        b.pressed.connect(func(): _shop_open())
                row.add_child(b)
        return row

# ----------------------------------------------------------------- the shop
## v0.2.3 OWNER REPORTS, all fixed here: (1) a finger that STARTED on a
## button could never scroll the list - the shop is the snake's BoxScroll
## language now (raw touch scrolling + registered tappables), and it works
## in snake too because both shops share the same pattern; (2) the BLUE
## skin was a dead 0-coin row - a price-0 skin IS the owned default, shown
## ON/EQUIP exactly like the snake shop does; (3) opening the shop WHILE
## THE GAME RUNS hung the sheet - the run pauses the tree, so the sheet
## gets PROCESS_MODE_ALWAYS like every other in-game sheet.
func _shop_open() -> void:
        if _phase == "run":
                paused = true
                get_tree().paused = true
        _clear_overlay()
        var sheet := Arc.sheet(_overlay_root_ref(), 0.0)
        sheet.get_parent().get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
        var t := Arc.label("PONG SHOP", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := get_viewport_rect().size
        # the WIDTH lives here (the snake's sheet gets its 620 from the CLOSE
        # button sitting outside its scroll - pong's CLOSE rides INSIDE, so
        # the scroll itself must demand the real width or the sheet collapses)
        sc.custom_minimum_size = Vector2(560,
                        clampf(vp.y * 0.52, 300.0, 640.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        # ---- PLATFORM SKINS ----
        box.add_child(_shop_label("PLATFORM SKINS - your color"))
        for id in SKINS:
                var sk: Dictionary = SKINS[id]
                # a price-0 skin is OWNED BY DEFAULT (the blue) - never a
                # dead 0-coin button (the snake shop's law)
                var owned := Box.skin_owned(game_id, id) \
                                or int(sk["price"]) == 0
                var on: bool = Box.skin_on(game_id) == id \
                                or (int(sk["price"]) == 0 \
                                and Box.skin_on(game_id) == "")
                var txt := "%s" % sk["name"]
                if on:
                        txt += "  (ON)"
                elif owned:
                        txt += "  - EQUIP"
                var b: Button
                if owned:
                        b = Arc.button(txt, Vector2(560, 64), 22,
                                        (sk["col"] as Color).darkened(0.05),
                                        func(): _skin_action(id))
                else:
                        b = Arc.coin_button(txt + "  %d" % int(sk["price"]),
                                        Vector2(560, 64), 22,
                                        (sk["col"] as Color).darkened(0.05),
                                        func(): _skin_action(id))
                        if Box.coins() < int(sk["price"]):
                                b.disabled = true
                box.add_child(b)
        # ---- POWER-UPS + EXTRAS ----
        box.add_child(_shop_label("POWER-UPS - they ride the ball"))
        for key in ["pong_size", "pong_speed"]:
                box.add_child(_unlock_row(key))
        box.add_child(_shop_label("EXTRAS - the court wakes up"))
        for key in ["pong_sparkles", "pong_more"]:
                box.add_child(_unlock_row(key))
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                        func(): _shop_close()))
        # BoxScroll owns every tap inside the scroll: register the live
        # buttons as tappables; DISABLED (unaffordable) stays unregistered =
        # gray AND dead (the price rule)
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))
        _overlay_panel = sheet.get_parent()

func _shop_label(txt: String) -> Label:
        return Arc.fit_label(txt, 24, Arc.HOT, 560)

func _unlock_row(key: String) -> Control:
        var u: Dictionary = UNLOCKS[key]
        if _owned(key):
                var l := Arc.fit_label("%s  - OWNED (toggle it in the optionals)" \
                                % u["name"], 20, Color("58c470"), 600)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        var vb := VBoxContainer.new()
        var b := Arc.coin_button("%s  %d" % [u["name"], u["price"]],
                        Vector2(560, 66), 22, Color("6a5ab8"),
                        func(): _buy_unlock(key, int(u["price"])))
        if Box.coins() < int(u["price"]):
                b.disabled = true
        vb.add_child(b)
        var s := Arc.fit_label(String(u["sub"]), 16, Color("8a6a40"), 560, false)
        s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(s)
        return vb

func _buy_unlock(key: String, price: int) -> void:
        if Box.coins() < price:
                Jukebox.sfx("error", -4.0)
                return
        if Box.buy_unlock(game_id, key, price):
                Jukebox.sfx("buy")
        _shop_open()

func _skin_action(id: String) -> void:
        # price-0 = the default skin: equipping it is always legal
        if Box.skin_owned(game_id, id) or int(SKINS[id]["price"]) == 0:
                Box.equip_skin(game_id, id)
                Jukebox.sfx("confirm", -4.0)
        else:
                var price := int(SKINS[id]["price"])
                if Box.coins() < price:
                        Jukebox.sfx("error", -4.0)
                        return
                if Box.buy_skin(game_id, id, price):
                        Jukebox.sfx("buy")
                        Box.equip_skin(game_id, id)
        _shop_open()

## v0.2.3 OWNER CALL: the END button belongs to the RUN only. Pausing from
## the position ask or the optionals/options screen shows RESUME + QUIT -
## no END row at all (the dead menu is the monetization path, it must not
## hang over a screen where nothing was earned yet).
func _goga_pause_end_ok() -> bool:
        return _phase == "run"

func _shop_close() -> void:
        # Arc.sheet appended dim + center at the end of the overlay root
        var kids := _overlay_root_ref().get_children()
        for i in range(maxi(0, kids.size() - 2), kids.size()):
                kids[i].queue_free()
        _overlay_panel = null
        if _phase == "run":
                get_tree().paused = false
                paused = false
        else:
                _show_options()

# ================================================== THE WORLD (per orientation)

func _rebuild_for_orientation() -> void:
        landscape = _auto_landscape()
        _build_world()

func _add_pad(id: String, is_user: bool, edge: String, axis: int,
                c: Vector2, ai_speed: float) -> void:
        var p := {
                "id": id, "user": is_user, "edge": edge, "axis": axis,
                "c": c, "len": PAD_NORMAL, "mega_t": 0.0, "mega_len": 0.0,
                "ai_speed": ai_speed, "ai_target": 0.0, "ai_t": 0.0,
                "err": 0.0,
        }
        pads.append(p)
        pads_by_id[id] = p

func _build_world() -> void:
        var vp := get_viewport_rect().size
        var top := 108.0
        field = Rect2(Vector2(24.0, top),
                        Vector2(maxf(200.0, vp.x - 48.0),
                                        maxf(200.0, vp.y - top - 24.0)))
        pads.clear()
        pads_by_id.clear()
        var main_axis := 0 if not landscape else 1   # 0 = moves along X
        var off := 54.0
        if not landscape:
                _add_pad("user", true, "bottom", main_axis,
                                Vector2(field.get_center().x,
                                                field.end.y - off), 0.0)
                _add_pad("enemy", false, "top", main_axis,
                                Vector2(field.get_center().x,
                                                field.position.y + off),
                                AI_SPEED)
                if _opt_on("more") and _owned("pong_more"):
                        _add_pad("extra_l", false, "left", 1,
                                        Vector2(field.position.x + 40.0,
                                                        field.get_center().y),
                                        AI_SPEED_EXTRA)
                        _add_pad("extra_r", false, "right", 1,
                                        Vector2(field.end.x - 40.0,
                                                        field.get_center().y),
                                        AI_SPEED_EXTRA)
        else:
                # v0.2.3 OWNER CALL: in horizontal the USER holds the RIGHT
                # edge (swapped with the enemy - "will be better!")
                _add_pad("user", true, "right", main_axis,
                                Vector2(field.end.x - off,
                                                field.get_center().y), 0.0)
                _add_pad("enemy", false, "left", main_axis,
                                Vector2(field.position.x + off,
                                                field.get_center().y),
                                AI_SPEED)
                if _opt_on("more") and _owned("pong_more"):
                        _add_pad("extra_t", false, "top", 0,
                                        Vector2(field.get_center().x,
                                                        field.position.y + 40.0),
                                        AI_SPEED_EXTRA)
                        _add_pad("extra_b", false, "bottom", 0,
                                        Vector2(field.get_center().x,
                                                        field.end.y - 40.0),
                                        AI_SPEED_EXTRA)
        coins.clear()
        pus.clear()
        trail.clear()
        _dust.clear()
        _motes.clear()
        _build_shreds()
        _build_goals_widget()

func _build_shreds() -> void:
        var rng := RandomNumberGenerator.new()
        rng.seed = 11
        _shreds.clear()
        for i in 42:
                _shreds.append({
                        "p": Vector2(rng.randf_range(field.position.x,
                                        field.end.x),
                                        rng.randf_range(field.position.y,
                                        field.end.y)),
                        "ph": rng.randf_range(0.0, TAU),
                        "spd": rng.randf_range(0.4, 1.3),
                        "r": rng.randf_range(1.4, 3.4),
                        "drift": rng.randf_range(4.0, 14.0),
                })

func _begin_run() -> void:
        _clear_overlay()
        _phase = "run"
        goals_user = 0
        goals_enemy = 0
        score = 0
        set_score(0)
        next_coin_at = SCORE_PER_COIN
        rally = 0
        coin_t = randf_range(COIN_MIN_T, COIN_MAX_T)
        pu_t = randf_range(PU_MIN_T, PU_MAX_T)
        _serve("user")
        _update_goals_widget()
        Jukebox.sfx("pong_serve", -6.0)

## THE SERVE (owner v0.2.3): the ball is born at the MIDDLE of the field
## and flies TOWARD the platform that conceded - never glued to a pad
## again (the owner's spawn-location report). Speed resets.
func _serve(from_edge: String) -> void:
        serve_from = from_edge
        heat = 1.0
        boost_on = false
        strike_on = false
        trail.clear()
        last_kicker = from_edge
        serve_t = SERVE_HOLD
        var p: Dictionary = pads_by_id.get(from_edge,
                        pads_by_id["user"])
        ball_pos = field.get_center()
        ball_prev = ball_pos
        # "toward the platform": the conceder's inward vector points FROM
        # their edge INTO the field, so flying at them is -inward, with a
        # little tangent skew so it never reads as a metronome
        var inward := _edge_inward(p["edge"])
        var skew := randf_range(-0.35, 0.35)
        ball_dir = (-inward + _edge_tangent(p["edge"]) * skew).normalized()
        _update_heat_chip()

func _pad_serve_pos(p: Dictionary) -> Vector2:
        # kept as a probe helper (the pre-v0.2.3 serve spot); the live serve
        # is born at the field center now
        var inward := _edge_inward(String(p["edge"]))
        return (p["c"] as Vector2) + inward * 74.0

func _edge_inward(edge: String) -> Vector2:
        match edge:
                "bottom":
                        return Vector2.UP
                "top":
                        return Vector2.DOWN
                "left":
                        return Vector2.RIGHT
                _:
                        return Vector2.LEFT

func _edge_tangent(edge: String) -> Vector2:
        return Vector2(1, 0) if edge == "top" or edge == "bottom" \
                        else Vector2(0, 1)

func _edge_normal_pos(edge: String) -> float:
        match edge:
                "bottom":
                        return field.end.y
                "top":
                        return field.position.y
                "left":
                        return field.position.x
                _:
                        return field.end.x

# ================================================================= INPUT
# Hold anywhere: the platform follows the finger ALONG its axis only -
# up/down finger wander (vertical courts) never steals the paddle.

func _goga_input(event: InputEvent) -> void:
        if _phase != "run":
                return
        if event is InputEventScreenTouch:
                var t := event as InputEventScreenTouch
                if t.pressed and _held == -1:
                        _held = t.index
                        _follow_finger(t.position)
                elif not t.pressed and t.index == _held:
                        _held = -1
        elif event is InputEventScreenDrag:
                var d := event as InputEventScreenDrag
                if d.index == _held:
                        _follow_finger(d.position)

func _follow_finger(at: Vector2) -> void:
        var p: Dictionary = pads_by_id.get("user", null)
        if p == null:
                return
        var half := _pad_half_len(p)
        if int(p["axis"]) == 0:
                p["c"] = Vector2(clampf(at.x, field.position.x + half,
                                field.end.x - half), (p["c"] as Vector2).y)
        else:
                p["c"] = Vector2((p["c"] as Vector2).x,
                                clampf(at.y, field.position.y + half,
                                field.end.y - half))

# ================================================================ THE RUN

func _goga_tick(delta: float) -> void:
        _time += delta
        _tick_fx(delta)
        if _view != null and is_instance_valid(_view):
                _view.queue_redraw()
        if _phase != "run":
                return
        for p in pads:
                if float(p["mega_t"]) > 0.0:
                        p["mega_t"] = maxf(0.0, float(p["mega_t"]) - delta)
        if serve_t > 0.0:
                serve_t -= delta
                if serve_t <= 0.0:
                        Jukebox.sfx("pong_hit", -10.0, 1.3)
        else:
                ball_prev = ball_pos
                var spd := _ball_speed()
                ball_pos += ball_dir * spd * delta
                _push_trail()
        _tick_walls_and_goals()
        _tick_pads()
        _tick_coins(delta)
        _tick_pus(delta)
        for p in pads:
                if not bool(p["user"]):
                        _tick_ai(p, delta)

func _ball_speed() -> float:
        var s: float = BALL_BASE * heat
        if boost_on:
                s *= 1.5
        if strike_on:
                s *= 3.0
        return s

func _update_heat_chip() -> void:
        if _heat_lbl != null:
                var shown: float = heat * (1.5 if boost_on else 1.0) \
                                * (3.0 if strike_on else 1.0)
                _heat_lbl.text = "x%.2f" % shown

## THE HEAT (owner spec): every hit x1.1; the strike's +200% dies on the
## next hit of ANYTHING. Walls and platforms both feed the burn.
func _heat_hit() -> void:
        if strike_on:
                strike_on = false
        heat = minf(heat * HEAT_STEP, HEAT_MAX)
        _update_heat_chip()

func _push_trail() -> void:
        trail.append([ball_pos, 1.0])
        if trail.size() > 46:
                trail.pop_front()

# ------------------------------------------------------- walls + goals

func _tick_walls_and_goals() -> void:
        var guard := [false, false, false, false]   # top L bottom R guarded
        for p in pads:
                match String(p["edge"]):
                        "top":
                                guard[0] = true
                        "left":
                                guard[1] = true
                        "bottom":
                                guard[2] = true
                        "right":
                                guard[3] = true
        var r := BALL_R
        # top edge
        if ball_pos.y - r < field.position.y:
                if guard[0]:
                        _goal("top")
                        return
                ball_pos.y = field.position.y + r
                ball_dir.y = absf(ball_dir.y)
                _heat_hit()
                Jukebox.sfx("pong_wall", -12.0, _hit_pitch())
        # left edge
        if ball_pos.x - r < field.position.x:
                if guard[1]:
                        _goal("left")
                        return
                ball_pos.x = field.position.x + r
                ball_dir.x = absf(ball_dir.x)
                _heat_hit()
                Jukebox.sfx("pong_wall", -12.0, _hit_pitch())
        # bottom edge
        if ball_pos.y + r > field.end.y:
                if guard[2]:
                        _goal("bottom")
                        return
                ball_pos.y = field.end.y - r
                ball_dir.y = -absf(ball_dir.y)
                _heat_hit()
                Jukebox.sfx("pong_wall", -12.0, _hit_pitch())
        # right edge
        if ball_pos.x + r > field.end.x:
                if guard[3]:
                        _goal("right")
                        return
                ball_pos.x = field.end.x - r
                ball_dir.x = -absf(ball_dir.x)
                _heat_hit()
                Jukebox.sfx("pong_wall", -12.0, _hit_pitch())

func _hit_pitch() -> float:
        return clampf(0.85 + (heat - 1.0) * 0.35, 0.85, 2.0)

## A GOAL: the ball crossed a guarded edge. Any enemy edge = +1 for the
## user; the user's edge = -1 (never below 0). The scorer's prize lands
## and the next ball is born at the CONCEDER's edge.
func _goal(edge: String) -> void:
        _flash_t = 0.35
        _flash_pos = ball_pos
        if edge == String(pads_by_id["user"]["edge"]):
                goals_enemy += 1
                set_score(maxi(0, score - 1))
                Jukebox.sfx("pong_concede", -2.0)
                _toast_show("goal on you -1")
        else:
                goals_user += 1
                set_score(score + 1)
                rally += 1
                achievement_max("max_rally", rally)
                Jukebox.sfx("pong_goal", -2.0)
                if score >= next_coin_at:
                        next_coin_at += SCORE_PER_COIN
                        add_run_coins(1)
                        Jukebox.sfx("pong_coin", -4.0, 1.2)
                        _toast_show("3 points = +1 GOGACoin")
        _update_goals_widget()
        # the conceder serves next
        _serve(edge)

# ------------------------------------------------------------------ pads

func _pad_half_len(p: Dictionary) -> float:
        if float(p["mega_t"]) > 0.0:
                return float(p["mega_len"]) * 0.5
        return float(p["len"]) * 0.5

func _axis_of(p: Dictionary) -> int:
        return int(p["axis"])

## THE BALL vs THE PLATFORMS - v0.2.3 THE REAL BOUNCE (owner report: near
## a platform the ball "goes a little away and spawns weirdly, not a real
## hit"). The old code tested only the LANDED position against a band
## around the pad and then TELEPORTED the ball to a fixed offset inside
## that band - a fast ball could step over the band entirely (tunnel into
## the goal behind the pad) or reappear at a spot it never touched. Now
## the move is SWEPT: the segment ball_prev -> ball_pos is tested against
## the pad's face plane, the bounce happens AT the crossing point (the
## contact spot the player sees), and the ball is simply placed there -
## the same clean reflection a wall gets.
func _tick_pads() -> void:
        if serve_t > 0.0:
                return
        for p in pads:
                var hl := _pad_half_len(p)
                var ht := PAD_THICK * 0.5
                var axis := _axis_of(p)
                var c := p["c"] as Vector2
                var out_n := _edge_inward(String(p["edge"]))
                if ball_dir.dot(out_n) >= 0.0:
                        continue   # already leaving this pad
                # signed distance along the pad's inward normal (0 = the pad
                # CENTER plane); the ball's contact plane sits one half-
                # thickness + one radius in front of it
                var sdist := func(q: Vector2) -> float:
                        var d := q - c
                        return d.x * out_n.x + d.y * out_n.y
                var face := ht + BALL_R
                var s_a: float = sdist.call(ball_prev)
                var s_b: float = sdist.call(ball_pos)
                if s_b > face or s_a < s_b:
                        continue   # never reached the face (or moving away)
                # where along the move did the center cross the contact plane
                var t_hit := 0.0
                if s_a > face:
                        t_hit = clampf((s_a - face) \
                                        / maxf(0.0001, s_a - s_b), 0.0, 1.0)
                var hit_p := ball_prev.lerp(ball_pos, t_hit)
                # inside the pad's span (the same forgiving corner rule)?
                var tvec := _edge_tangent(String(p["edge"]))
                var ball_axis := hit_p.x if axis == 0 else hit_p.y
                var c_axis := c.x if axis == 0 else c.y
                if absf(ball_axis - c_axis) > hl + BALL_R * 0.55:
                        continue   # beside the pad - the goal law decides
                # ---- the bounce lands HERE (no teleport): sit on the plane
                ball_pos = hit_p
                var contact := hit_p - out_n * BALL_R   # on the pad's skin
                if bool(p["user"]):
                        last_kicker = "user"
                        rally += 1
                        achievement_max("max_rally", rally)
                        var offset := clampf((ball_axis - c_axis) \
                                        / maxf(hl, 1.0), -1.0, 1.0)
                        ball_dir = (out_n + tvec * offset * 0.85).normalized()
                else:
                        last_kicker = String(p["id"])
                        var aim := _ai_return_axis(p, out_n, tvec, ball_axis)
                        var k := clampf((aim - ball_axis) / 240.0, -0.9, 0.9)
                        ball_dir = (out_n + tvec * k).normalized()
                # never let a return crawl sideways forever
                if ball_dir.dot(out_n) < 0.35:
                        ball_dir = (out_n + tvec * signf(ball_dir.dot(tvec)) \
                                        * 0.55).normalized()
                _heat_hit()
                Jukebox.sfx("pong_hit", -6.0, _hit_pitch())
                _flash_t = maxf(_flash_t, 0.12)
                _flash_pos = ball_pos
                if _sparkles_on():
                        var dcol: Color = _user_col() if bool(p["user"]) \
                                        else COL_ENEMY
                        _dust_at(contact, ball_dir, dcol)
                break   # one honest bounce per frame

## The AI's return aim: the user's edge (ALL enemies hunt the player),
## with an error, nudged away from bad pickups on the way out.
func _ai_return_axis(p: Dictionary, out_n: Vector2, tvec: Vector2,
                ball_axis: float) -> float:
        var u: Dictionary = pads_by_id["user"]
        var ua := (u["c"] as Vector2).x if _axis_of(u) == 0 \
                        else (u["c"] as Vector2).y
        var honest := ua + float(p["err"]) * 0.4
        if pus.is_empty():
                return honest
        var best := honest
        var best_score := INF
        for cand in [honest - 150.0, honest - 75.0, honest, honest + 75.0,
                        honest + 150.0]:
                var s := absf(cand - honest) * 0.02
                var k := clampf((cand - ball_axis) / 240.0, -0.9, 0.9)
                var dirv := (out_n + tvec * k).normalized()
                for pu in pus:
                        var pid := String(pu["id"])
                        var bad := pid == "shrink" or pid == "mini"
                        var good := pid == "wide" or pid == "mega"
                        if not bad and not good:
                                continue
                        var to_p := ((pu["p"] as Vector2) - ball_pos)
                        var along := to_p.dot(dirv)
                        if along < 0.0 or along > 900.0:
                                continue
                        var perp := absf(to_p.cross(dirv))
                        if perp < 90.0:
                                s += (46.0 if bad else -16.0) / (1.0 + perp * 0.05)
                if s < best_score:
                        best_score = s
                        best = cand
        return best

## NOT hard, NOT stupid (v0.2.3 owner call: "shorter range of reading ball
## movements"): the pad only READS the ball inside AI_VISION of the field
## depth from its own edge. Outside that range it drifts back toward the
## middle - it cannot pre-position for a shot it has not seen yet, so a
## fast angled return beats it. Inside the range it still predicts with a
## folded wall bounce, thinks every AI_THINK seconds, carries a human
## error, and its speed cap means the heat eventually beats it too.
func _tick_ai(p: Dictionary, delta: float) -> void:
        p["ai_t"] = float(p["ai_t"]) - delta
        if float(p["ai_t"]) <= 0.0:
                p["ai_t"] = AI_THINK
                p["err"] = randf_range(-1.0, 1.0) * float(p["len"]) * 0.30
        var axis := _axis_of(p)
        var out_n := _edge_inward(String(p["edge"]))
        var toward := ball_dir.dot(out_n) < -0.05 and serve_t <= 0.0
        var c := p["c"] as Vector2
        var cur_axis := c.x if axis == 0 else c.y
        var target := cur_axis
        # THE VISION RANGE: distance from MY edge plane to the ball, along
        # the normal (axis 0 pads live on top/bottom edges -> the normal
        # coordinate is y; axis 1 pads live on left/right -> x)
        var sees := false
        if toward:
                var plane := _edge_normal_pos(String(p["edge"]))
                var bnorm := ball_pos.y if axis == 0 else ball_pos.x
                var depth := field.size.y if axis == 0 else field.size.x
                sees = absf(bnorm - plane) <= AI_VISION * depth
        if toward and sees:
                var baxis := ball_pos.x if axis == 0 else ball_pos.y
                var bnorm2 := ball_pos.y if axis == 0 else ball_pos.x
                var bdn := ball_dir.y if axis == 0 else ball_dir.x
                var pn := c.y if axis == 0 else c.x
                if absf(bdn) > 0.05:
                        var t := (pn - bnorm2) / bdn
                        if t > 0.0:
                                var vaxis := ball_dir.x if axis == 0 \
                                                else ball_dir.y
                                var pred := baxis + vaxis * t
                                var fmin := field.position.x + 8.0 \
                                                if axis == 0 \
                                                else field.position.y + 8.0
                                var fmax := field.end.x - 8.0 if axis == 0 \
                                                else field.end.y - 8.0
                                target = _fold_axis(pred, fmin, fmax) \
                                                + float(p["err"])
                        else:
                                target = cur_axis
                else:
                        target = cur_axis
        else:
                var mid := field.get_center().x if axis == 0 \
                                else field.get_center().y
                target = lerpf(cur_axis, mid, 0.5)
        var na := move_toward(cur_axis, target, float(p["ai_speed"]) * delta)
        p["c"] = Vector2(na, c.y) if axis == 0 else Vector2(c.x, na)

func _fold_axis(v: float, lo: float, hi: float) -> float:
        var span := hi - lo
        if span <= 2.0:
                return lo + span * 0.5
        var m := fposmod(v - lo, span * 2.0)
        return lo + (m if m <= span else span * 2.0 - m)

# ----------------------------------------------------------------- coins

func _tick_coins(delta: float) -> void:
        # v0.2.3 OWNER LAW: ONE coin on the court at a time - a new one
        # spawns 5-20s after the LAST COLLECTED one (the timer restarts at
        # the spawn and again at the collection; an uncollected coin just
        # waits, no second coin ever piles up)
        coin_t -= delta
        if coin_t <= 0.0:
                coin_t = randf_range(COIN_MIN_T, COIN_MAX_T)
                if coins.is_empty():
                        coins.append({"p": _free_spot(90.0), "pop": 0.0})
        for c2 in coins:
                c2["pop"] = minf(1.0, float(c2["pop"]) + delta * 4.0)
        for i in coins.size():
                if (coins[i]["p"] as Vector2).distance_to(ball_pos) \
                                < COIN_R + BALL_R:
                        var at: Vector2 = coins[i]["p"]
                        coins.remove_at(i)
                        _burst(at, [COL_COIN, Color("fff3dc")], 8)
                        # the clock restarts FROM THE COLLECTION (owner rule)
                        coin_t = randf_range(COIN_MIN_T, COIN_MAX_T)
                        if last_kicker == "user":
                                add_run_coins(1)
                                Jukebox.sfx("pong_coin", -4.0)
                                _toast_show("GOGACoin - yours")
                        else:
                                Jukebox.sfx("pong_coin", -10.0, 0.7)
                                _toast_show("their kick took the coin")
                        break

# ------------------------------------------------------------- powerups

func _pu_pool() -> Array:
        var pool := []
        if _opt_on("size") and _owned("pong_size"):
                pool += ["wide", "wide", "shrink", "shrink", "mega", "mega",
                                "mini", "mini"]
        if _opt_on("speed") and _owned("pong_speed"):
                pool += ["boost", "boost", "strike"]
        return pool

func _tick_pus(delta: float) -> void:
        pu_t -= delta
        if pu_t <= 0.0:
                pu_t = randf_range(PU_MIN_T, PU_MAX_T)
                var pool := _pu_pool()
                if pool.size() > 0 and pus.size() < 2:
                        pus.append({"id": pool.pick_random(),
                                        "p": _free_spot(120.0), "pop": 0.0})
        for q in pus:
                q["pop"] = minf(1.0, float(q["pop"]) + delta * 4.0)
        for i in pus.size():
                if (pus[i]["p"] as Vector2).distance_to(ball_pos) \
                                < PU_R + BALL_R:
                        var at: Vector2 = pus[i]["p"]
                        var id := String(pus[i]["id"])
                        pus.remove_at(i)
                        _apply_pu(id, at)
                        break

## FIXED pixel values everywhere (owner rule) - and the clamps mean a pad
## at its floor cannot shrink again, at its ceiling cannot grow again.
func _apply_pu(id: String, at: Vector2) -> void:
        var kicker: Dictionary = pads_by_id.get(last_kicker,
                        pads_by_id["user"])
        var mine := bool(kicker["user"])
        var who := "YOUR PAD" if mine else "THEIR PAD"
        match id:
                "wide":
                        var nl: float = float(kicker["len"]) + PAD_STEP
                        if nl <= PAD_MAX:
                                kicker["len"] = nl
                                _pu_sfx(true, mine)
                        else:
                                _pu_sfx(true, mine)   # at the ceiling: nothing
                "shrink":
                        var nl2: float = float(kicker["len"]) - PAD_STEP
                        if nl2 >= PAD_MIN:
                                kicker["len"] = nl2
                                _pu_sfx(false, mine)
                        else:
                                _pu_sfx(false, mine)  # at the floor: nothing
                "mega":
                        kicker["mega_t"] = MEGA_T
                        kicker["mega_len"] = minf(PAD_NORMAL * 3.0, 560.0)
                        _pu_sfx(true, mine)
                "mini":
                        kicker["mega_t"] = MEGA_T
                        kicker["mega_len"] = maxf(PAD_NORMAL / 3.0, 40.0)
                        _pu_sfx(false, mine)
                "boost":
                        boost_on = true
                        _pu_sfx(mine, true)
                "strike":
                        strike_on = true
                        Jukebox.sfx("pong_strike", -4.0)
        _burst(at, [_pu_color(id), Color("fff3dc")], 10)
        _update_heat_chip()
        var txt := ""
        match id:
                "wide":
                        txt = "%s +%dpx" % [who, PAD_STEP]
                "shrink":
                        txt = "%s -%dpx" % [who, PAD_STEP]
                "mega":
                        txt = "%s MEGA x3 (10s)" % who
                "mini":
                        txt = "%s tiny x3 (10s)" % who
                "boost":
                        txt = "BALL +50% this volley"
                "strike":
                        txt = "STRIKE +200% - one hit!"
        _toast_show(txt)

func _pu_sfx(good: bool, mine: bool) -> void:
        # the sound follows MY perspective - their gain is my loss
        if good == mine:
                Jukebox.sfx("pong_pu_good", -4.0)
        else:
                Jukebox.sfx("pong_pu_bad", -3.0)

func _pu_color(id: String) -> Color:
        match id:
                "wide", "mega":
                        return Color("58c470")
                "shrink", "mini":
                        return Color("e8402f")
                "boost":
                        return Color("ffb43c")
                _:
                        return Color("ff5030")

func _free_spot(margin: float) -> Vector2:
        for i in 30:
                var p := Vector2(randf_range(field.position.x + margin,
                                field.end.x - margin),
                                randf_range(field.position.y + margin,
                                field.end.y - margin))
                if p.distance_to(ball_pos) < 150.0:
                        continue
                var clear := true
                for c2 in coins:
                        if (c2["p"] as Vector2).distance_to(p) < 80.0:
                                clear = false
                for q in pus:
                        if (q["p"] as Vector2).distance_to(p) < 90.0:
                                clear = false
                if clear:
                        return p
        return field.get_center()

# -------------------------------------------------------------------- fx

func _dust_at(p: Vector2, dir: Vector2, col: Color) -> void:
        # v0.2.3: the sparkles fly OFF THE HIT AREA - born at the contact
        # spot on the platform's skin, thrown along the bounce direction
        # (the owner: "sparkles appear from the area got hit by the ball")
        for i in 8:
                var spread := dir.rotated(randf_range(-0.9, 0.9))
                _dust.append({"p": p + Vector2(randf_range(-4, 4), \
                                randf_range(-4, 4)),
                                "v": spread * randf_range(90.0, 220.0),
                                "life": randf_range(0.35, 0.6), "col": col})

func _burst(p: Vector2, cols: Array, n: int) -> void:
        for i in n:
                _motes.append({"p": p, "v": Vector2(randf_range(-190.0, 190.0),
                                randf_range(-190.0, 190.0)),
                                "life": randf_range(0.3, 0.55),
                                "col": cols[i % cols.size()]})

func _tick_fx(delta: float) -> void:
        for t in trail:
                t[1] = float(t[1]) - delta * (1.6 + 1.8 * heat)
        trail = trail.filter(func(t): return float(t[1]) > 0.0)
        for m in _motes:
                m["p"] = m["p"] as Vector2 + (m["v"] as Vector2) * delta
                m["v"] = (m["v"] as Vector2).lerp(Vector2.ZERO, 3.0 * delta)
                m["life"] = float(m["life"]) - delta
        _motes = _motes.filter(func(m): return float(m["life"]) > 0.0)
        for d in _dust:
                d["p"] = d["p"] as Vector2 + (d["v"] as Vector2) * delta
                d["life"] = float(d["life"]) - delta
        _dust = _dust.filter(func(d): return float(d["life"]) > 0.0)
        if _flash_t > 0.0:
                _flash_t -= delta
        for s in _shreds:
                s["ph"] = float(s["ph"]) + delta * float(s["spd"])

# ================================================================= PAINT

func _heat_norm() -> float:
        return clampf((heat - 1.0) / (HEAT_MAX - 1.0), 0.0, 1.0)

func _ball_color() -> Color:
        return COL_BALL_COLD.lerp(COL_BALL_HOT, _heat_norm())

func _sparkles_on() -> bool:
        return _opt_on("sparkles") and _owned("pong_sparkles")

func _paint(v: Node2D) -> void:
        var vp := get_viewport_rect().size
        v.draw_rect(Rect2(Vector2.ZERO, vp), COL_COURT)
        _paint_shreds(v)
        _paint_court(v)
        _paint_trail(v)
        _paint_coins(v)
        _paint_pus(v)
        _paint_pads(v)
        _paint_ball(v)
        _paint_fx(v)

func _paint_shreds(v: Node2D) -> void:
        var tint := _user_col() if _sparkles_on() else Color(1, 1, 1)
        for s in _shreds:
                var tw := 0.5 + 0.5 * sin(float(s["ph"]) * 2.0)
                # v0.2.3 OWNER CALL: the lights were "too mute" - brighter
                var a := 0.10 + 0.17 * tw
                var p := (s["p"] as Vector2) + Vector2(
                                sin(float(s["ph"]) * 0.8), 0.0) \
                                * float(s["drift"])
                var r: float = float(s["r"])
                var col := Color(tint.r, tint.g, tint.b, a)
                v.draw_circle(p, r + 2.2, Color(col.r, col.g, col.b, a * 0.45))
                v.draw_circle(p, r, col)

func _paint_court(v: Node2D) -> void:
        # the center line, dashed
        var mid := field.get_center()
        var n := 11
        for i in range(0, n, 2):
                var t := (float(i) + 0.5) / float(n)
                if landscape:
                        var y := lerpf(field.position.y, field.end.y, t)
                        v.draw_rect(Rect2(mid.x - 2.5, y - 14.0, 5.0, 28.0),
                                        COL_LINE)
                else:
                        var x := lerpf(field.position.x, field.end.x, t)
                        v.draw_rect(Rect2(x - 14.0, mid.y - 2.5, 28.0, 5.0),
                                        COL_LINE)
        # the guarded edges wear their owner's color
        var u: Dictionary = pads_by_id.get("user", null)
        if u != null:
            for p in pads:
                var col: Color = _user_col() if bool(p["user"]) else COL_ENEMY
                col.a = 0.32 if bool(p["user"]) else 0.24
                match String(p["edge"]):
                        "top":
                                v.draw_rect(Rect2(field.position.x,
                                                field.position.y,
                                                field.size.x, 5.0), col)
                        "bottom":
                                v.draw_rect(Rect2(field.position.x,
                                                field.end.y - 5.0,
                                                field.size.x, 5.0), col)
                        "left":
                                v.draw_rect(Rect2(field.position.x,
                                                field.position.y, 5.0,
                                                field.size.y), col)
                        "right":
                                v.draw_rect(Rect2(field.end.x - 5.0,
                                                field.position.y, 5.0,
                                                field.size.y), col)

func _paint_trail(v: Node2D) -> void:
        var hn := _heat_norm()
        var col := _ball_color()
        for t in trail:
                var life := float(t[1])
                var a := pow(clampf(life, 0.0, 1.0), 1.4) * (0.10 + 0.34 * hn)
                var rr := BALL_R * (0.32 + 0.55 * life) * (0.7 + 0.6 * hn)
                v.draw_circle(t[0] as Vector2, rr + 2.0,
                                Color(col.r, col.g, col.b, a * 0.4))
                v.draw_circle(t[0] as Vector2, rr,
                                Color(col.r, col.g, col.b, a))

func _paint_coins(v: Node2D) -> void:
        # v0.2.3 OWNER CALL: the REAL GOGACoin asset (the wallet's coin),
        # not a hand-drawn disc - same art as the HUD chip and the shop
        for c2 in coins:
                var p := c2["p"] as Vector2
                var pop := float(c2["pop"])
                var s: float = COIN_R * (0.62 + 0.38 * pop) * 2.35
                var bob := sin(_time * 3.0 + p.x) * 2.5
                var at := p + Vector2(0, bob)
                # a soft golden halo so the coin reads on the dark court
                v.draw_circle(at, s * 0.78,
                                Color(1.0, 0.85, 0.3, 0.14 + 0.08 * pop))
                v.draw_texture_rect(_coin_tex,
                                Rect2(at - Vector2(s, s) * 0.5,
                                Vector2(s, s)), false)

func _paint_pus(v: Node2D) -> void:
        for q in pus:
                var p := q["p"] as Vector2
                var pop := float(q["pop"])
                var col := _pu_color(String(q["id"]))
                var s := PU_R * (0.7 + 0.3 * pop)
                v.draw_rect(Rect2(p - Vector2(s, s), Vector2(s * 2, s * 2)),
                                Color(0.06, 0.06, 0.09, 0.92))
                v.draw_arc(p, s, 0.0, TAU, 4, col, 3.0)
                var w := s * 0.62
                match String(q["id"]):
                        "wide":
                                _arrow(v, p - Vector2(w * 0.4, 0),
                                                Vector2(-w, 0), col, 3.0)
                                _arrow(v, p + Vector2(w * 0.4, 0),
                                                Vector2(w, 0), col, 3.0)
                        "shrink":
                                _arrow(v, p - Vector2(w * 1.1, 0),
                                                Vector2(w * 0.6, 0), col, 3.0)
                                _arrow(v, p + Vector2(w * 1.1, 0),
                                                Vector2(-w * 0.6, 0), col, 3.0)
                        "mega":
                                _arrow(v, p - Vector2(w * 0.3, 0),
                                                Vector2(-w * 1.3, 0), col, 4.5)
                                _arrow(v, p + Vector2(w * 0.3, 0),
                                                Vector2(w * 1.3, 0), col, 4.5)
                        "mini":
                                _arrow(v, p - Vector2(w * 1.2, 0),
                                                Vector2(w * 0.7, 0), col, 4.5)
                                _arrow(v, p + Vector2(w * 1.2, 0),
                                                Vector2(-w * 0.7, 0), col, 4.5)
                        "boost":
                                _chevron(v, p - Vector2(6, 0), col, 3.0)
                        "strike":
                                _chevron(v, p - Vector2(11, 0), col, 3.0)
                                _chevron(v, p + Vector2(7, 0), col, 3.0)

func _arrow(v: Node2D, from: Vector2, vec: Vector2, col: Color,
                wd: float) -> void:
        var tip := from + vec
        v.draw_line(from, tip, col, wd)
        var d := vec.normalized()
        var side := Vector2(-d.y, d.x) * wd * 0.9
        v.draw_line(tip, tip - d * wd * 2.2 + side, col, wd)
        v.draw_line(tip, tip - d * wd * 2.2 - side, col, wd)

func _chevron(v: Node2D, at: Vector2, col: Color, wd: float) -> void:
        v.draw_line(at + Vector2(-4, -8), at + Vector2(4, 0), col, wd)
        v.draw_line(at + Vector2(4, 0), at + Vector2(-4, 8), col, wd)

func _paint_pads(v: Node2D) -> void:
        for p in pads:
                var col: Color = _user_col() if bool(p["user"]) else COL_ENEMY
                if String(p["id"]).begins_with("extra"):
                        col = COL_ENEMY_2
                var hl := _pad_half_len(p)
                var ht := PAD_THICK * 0.5
                var c := p["c"] as Vector2
                var tvec := _edge_tangent(String(p["edge"]))
                var axis_x := absf(tvec.x) > 0.5
                var dark := col.darkened(0.5)
                var lit := col.lightened(0.25)
                # outline pass (the capsule's dark rim)
                _capsule(v, c, hl + 3.0, ht + 3.0, axis_x, dark)
                _capsule(v, c, hl, ht, axis_x, col)
                # the inner sheen (a light stripe on the field side)
                var inner := c + _edge_inward(String(p["edge"])) * ht * 0.38
                _capsule(v, inner, hl * 0.86, ht * 0.30, axis_x, lit)
                # the mega/mini pulse
                if float(p["mega_t"]) > 0.0:
                        var pulse := 0.5 + 0.5 * sin(_time * 8.0)
                        v.draw_arc(c, hl + 10.0 + 3.0 * pulse, 0.0, TAU, 40,
                                        Color(lit.r, lit.g, lit.b,
                                        0.25 + 0.2 * pulse), 3.0)

func _capsule(v: Node2D, c: Vector2, hl: float, ht: float, axis_x: bool,
                col: Color) -> void:
        if axis_x:
                v.draw_rect(Rect2(c.x - hl, c.y - ht, hl * 2.0, ht * 2.0), col)
                v.draw_circle(Vector2(c.x - hl, c.y), ht, col)
                v.draw_circle(Vector2(c.x + hl, c.y), ht, col)
        else:
                v.draw_rect(Rect2(c.x - ht, c.y - hl, ht * 2.0, hl * 2.0), col)
                v.draw_circle(Vector2(c.x, c.y - hl), ht, col)
                v.draw_circle(Vector2(c.x, c.y + hl), ht, col)

func _paint_ball(v: Node2D) -> void:
        var col := _ball_color()
        var hn := _heat_norm()
        var pulse := 1.0 + 0.06 * sin(_time * (6.0 + 14.0 * hn))
        var r := BALL_R * pulse
        # the burn glow grows with the heat
        v.draw_circle(ball_pos, r + 14.0 + 10.0 * hn,
                        Color(col.r, col.g, col.b, 0.10 + 0.16 * hn))
        v.draw_circle(ball_pos, r + 5.0, Color(col.r, col.g, col.b, 0.30))
        v.draw_circle(ball_pos, r, col)
        v.draw_circle(ball_pos + Vector2(-r * 0.28, -r * 0.28), r * 0.30,
                        Color(1, 1, 1, 0.85))
        if strike_on:
                v.draw_arc(ball_pos, r + 9.0, 0.0, TAU, 24,
                                Color(1, 1, 1, 0.5 + 0.3 * sin(_time * 20.0)),
                                2.5)
        if serve_t > 0.0:
                var k := clampf(serve_t / SERVE_HOLD, 0.0, 1.0)
                v.draw_arc(ball_pos, r + 12.0 + 10.0 * (1.0 - k),
                                0.0, TAU, 30,
                                Color(col.r, col.g, col.b, 0.6 * k), 3.0)
        if _flash_t > 0.0:
                var a := clampf(_flash_t / 0.35, 0.0, 1.0)
                v.draw_arc(_flash_pos, 20.0 + (1.0 - a) * 90.0, 0.0, TAU, 30,
                                Color(1, 1, 1, a * 0.5), 4.0)

func _paint_fx(v: Node2D) -> void:
        for m in _motes:
                var a := clampf(float(m["life"]) / 0.4, 0.0, 1.0)
                var col: Color = m["col"]
                v.draw_circle(m["p"], 3.4,
                                Color(col.r, col.g, col.b, a * 0.9))
        for d in _dust:
                var a2 := clampf(float(d["life"]) / 0.5, 0.0, 1.0)
                var col2: Color = d["col"]
                v.draw_circle(d["p"], 2.6,
                                Color(col2.r, col2.g, col2.b, a2 * 0.7))

# ---------------------------------------------------------- overlay helpers

func _clear_overlay() -> void:
        if _overlay_panel != null and is_instance_valid(_overlay_panel):
                _overlay_panel.queue_free()
        _overlay_panel = null

func _dim_layer() -> ColorRect:
        var dim := ColorRect.new()
        dim.color = Color(0.04, 0.04, 0.06, 0.66)
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

# ---------------------------------------------------------- the goals widget

func _build_goals_widget() -> void:
        if _goals_lbl_u != null and is_instance_valid(_goals_lbl_u):
                _goals_lbl_u.get_parent().queue_free()
        var row := HBoxContainer.new()
        row.set_anchors_preset(Control.PRESET_TOP_WIDE)
        row.offset_top = 84
        row.offset_bottom = 130
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        row.add_theme_constant_override("separation", 12)
        row.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _overlay_root_ref().add_child(row)
        var sq_u := ColorRect.new()
        sq_u.color = _user_col()
        sq_u.custom_minimum_size = Vector2(22, 22)
        sq_u.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        sq_u.mouse_filter = Control.MOUSE_FILTER_IGNORE
        row.add_child(sq_u)
        _goals_lbl_u = Arc.label("0", 30, _user_col())
        _goals_lbl_u.mouse_filter = Control.MOUSE_FILTER_IGNORE
        row.add_child(_goals_lbl_u)
        var sep := Arc.label("-", 26, Color(1, 1, 1, 0.45))
        sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
        row.add_child(sep)
        _goals_lbl_e = Arc.label("0", 30, COL_ENEMY)
        _goals_lbl_e.mouse_filter = Control.MOUSE_FILTER_IGNORE
        row.add_child(_goals_lbl_e)
        var sq_e := ColorRect.new()
        sq_e.color = COL_ENEMY
        sq_e.custom_minimum_size = Vector2(22, 22)
        sq_e.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        sq_e.mouse_filter = Control.MOUSE_FILTER_IGNORE
        row.add_child(sq_e)
        _update_goals_widget()

func _update_goals_widget() -> void:
        if _goals_lbl_u != null and is_instance_valid(_goals_lbl_u):
                _goals_lbl_u.text = str(goals_user)
        if _goals_lbl_e != null and is_instance_valid(_goals_lbl_e):
                _goals_lbl_e.text = str(goals_enemy)

# ------------------------------------------------------------------- end

func finish_run(final_score: int, final_coins := -1) -> void:
        Jukebox.stop_music()
        super.finish_run(final_score, final_coins)

