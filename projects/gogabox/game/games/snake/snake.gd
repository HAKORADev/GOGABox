extends GogaGame
## Snake v0.1.9 - THE SNAKE GOES TO WAR. Built on the owner's v0.1.8 verdict:
##
##   FIXES: the snake starts SLOWER; the body is ONE smooth part (a ribbon
##   polygon - no circles, no beads); steering is an INVISIBLE ANALOG WHEEL
##   (touch anywhere, drag = absolute screen-space heading - "left when the
##   head is upside down stays left"); the eat particles wear the EATEN
##   thing's colors; the position (vertical/horizontal) is ASKED before the
##   run with phone art and OVERWRITES the auto choice; then the MODE menu
##   (classic walls / NO-WALLS wrap) with the scrollable OPTIONALS strip.
##
##   WAR: green enemy snakes with a real brain (coins weigh more than
##   apples, noose-encirclement when big, permanent deaths, the run only
##   ends when the USER dies), power fruits with auras (slower/faster/ghost/
##   magnet/golden/wither/snake-eater - every one with its own spawn rhythm
##   and duration, every one rewriting the AI), bugs that steal fruit and
##   bite WITHOUT killing, solid obstacles, a fruit wardrobe, and a shop
##   with labeled sections where every price wears the GOGACoin icon and
##   unaffordable things are grayed out and dead.
##
## Reference study: HAKORADev/Python_Game_Box_PGB - snake.py (A* brain) and
## the Snake3D store (the powers table, the bug penalty design, the CPU
## BFS+flood logic). This game is its own thing - smooth, not grid.

const START_SPEED := 300.0      # owner: "a little slower than that"
const SPEED_PER_APPLE := 6.0
const SPEED_MAX := 780.0
const START_LEN := 320.0
const LEN_PER_APPLE := 70.0
const WIDTH_START := 26.0
const WIDTH_PER_APPLE := 1.6
const WIDTH_MAX := 64.0         # "wide with a limit"
const TURN_RATE := 4.6          # rad/s - the wheel's bend budget
const WHEEL_DEADZONE := 12.0    # resting fingers never jitter the head

# war tuning
const ENEMY_SPEED_RATIO := 0.92
const EATER_BITE_PX := 66.0     # tail bitten off per bite
const EATER_GROW_PX := 55.0
const BUG_LEN_PENALTY := 66.0   # ~3 apples of body - hurts, never kills
const BUG_SCORE_PENALTY := 5
const MAGNET_RANGE := 330.0
const POWER_BOARD_LIFE := 10.0  # the aura fruit expires (Snake3D rule)
const LEN_FLOOR := 160.0        # no snake (or curse) grinds you to nothing

# shop (every price wears the coin icon - AGENTS.md price rule)
const PRICE_POWERUPS := 400
const PRICE_BUGS := 350
const PRICE_OBSTACLES := 300
const PRICE_ENEMIES := 1200     # THE most expensive thing in the shop

# ---------------------------------------------------------- palette (feel)
const FIELD := Color("f6e7cd")
const FIELD_DECO := Color("ecd9b4")
const WALL := Color("d9c39a")
const WRAP_LINE := Color("9ec49a")
const TONGUE_RED := Color("e8402f")
const EYE_WHITE := Color("fdfaf2")
const EYE_INK := Color("35210f")
const FLASH_RED := Color("e8402f")
const OBST_FILL := Color("cbb28a")
const OBST_EDGE := Color("8a6a40")
const BUG_SHELL := Color("4a3a20")
const BUG_BODY := Color("c4783c")

# skins survive as palettes over ONE gradient system: primary (head) ->
# milk (tail). classic is the owner's blue-melt design.
const PALETTES := {
        "classic": {"pri": Color("3f7fd4"), "milk": Color("faf3e3")},
        "lava": {"pri": Color("e8632a"), "milk": Color("ffe9c9")},
        "ice": {"pri": Color("57b8e8"), "milk": Color("f0f8fd")},
        "gold": {"pri": Color("e8b23a"), "milk": Color("fdf3d8")},
}

# ------------------------------------------------------------------ state
var board := Rect2(0, 0, 100, 100)
var banner_on := false
var orient := "vertical"        # the ASKED play position (overwrites auto)
var wrap_mode := false          # NO-WALLS mode
var _phase := "orient"          # orient -> mode -> ready -> run
var _time := 0.0
var _pal: Dictionary = PALETTES["classic"]

var player: SnakeBody
var enemies: Array = []         # [{body: SnakeBody, ai: SnakeAI, score, name, bite_cd}]
var bugs: Array = []            # [{pos, dir, phase, munch, hit_cd}]
var obstacles: Array = []       # Array[Rect2]

var edible_id := "apple"
var apple_pos := Vector2.ZERO
var apple_r := 26.0
var apple_pop := 0.0
var apple_live := false
var _apple_tween: Tween

var coin_pos := Vector2(-100, -100)
var coin_pop := 0.0
var coin_rot := 0.0
var coin_live := false
var _coin_tex: Texture2D
var _coin_tween: Tween

var power_pos := Vector2.ZERO
var power_id := ""
var power_pop := 0.0
var power_age := 0.0
var power_live := false
var power_cd := {}              # power id -> time it leaves cooldown
var power_next_at := 0.0
var _bite_cd := 0.0

var _eaten := 0
var _motes: Array = []
var _rings: Array = []
var _deco: Array = []
var _tongue_cd := 1.6
var _tongue_t := 0.0

# the invisible analog wheel
var _wheel_idx := -1
var _wheel_center := Vector2.ZERO
var _wheel_stick := Vector2.ZERO

var _view: Node2D
var _chips: Control
var _overlay_panel: Control     # the live select screen (orient/mode)
var _ready_card: Control

# snake draws itself + the field through one view node
class SnakeView:
        extends Node2D
        var g: Node2D

        func _draw() -> void:
                g._paint(self)

# ============================================================== SETUP

func _goga_setup() -> void:
        banner_on = bool(GameReg.get_game(game_id).get("banner", false))
        _load_skin()
        # the ASKED orientation overwrites the auto-sense every load
        var pref := String(Box.get_progress(game_id, "orient_pref", ""))
        orient = pref if pref != "" else _auto_orient()
        wrap_mode = bool(Box.get_progress(game_id, "mode_nowalls", false))
        _build_field()
        player = SnakeBody.new()
        player.base_speed = START_SPEED
        player.speed = START_SPEED
        player.setup(board.get_center(), 0.0, _pal["pri"], _pal["milk"])
        _view = SnakeView.new()
        _view.g = self
        add_child(_view)
        _coin_tex = load("res://assets/ui/coin.png")
        _build_chips()
        add_hud_button("SHOP", func(): _shop_open())
        Jukebox.music("res://assets/audio/music/snake_theme.wav")
        _new_run_objects()
        _show_orient_select()

func _auto_orient() -> String:
        var vp := get_viewport_rect().size
        return "horizontal" if vp.x > vp.y else "vertical"

## The field is the ASKED shape: vertical = ~9:16, horizontal = ~16:9,
## letterboxed inside whatever the device is doing (owner: the choice
## overwrites the sensor - the base for position-specific play later).
func _build_field() -> void:
        var vp := get_viewport_rect().size
        var top := 108.0
        var bottom := 14.0
        if banner_on:
                bottom = _banner_safe_px()
        var avail := Vector2(maxf(100.0, vp.x - 20.0),
                        maxf(100.0, vp.y - top - bottom - 8.0))
        var target_aspect := 9.0 / 16.0 if orient == "vertical" else 16.0 / 9.0
        var w := avail.y * target_aspect
        var h := avail.y
        if w > avail.x:
                w = avail.x
                h = w / target_aspect
        var origin := Vector2((vp.x - w) / 2.0, top + (avail.y - h) / 2.0)
        board = Rect2(origin, Vector2(w, h))
        _deco.clear()
        var rng := RandomNumberGenerator.new()
        rng.seed = 7
        for i in 6:
                _deco.append({
                        "fx": rng.randf_range(0.08, 0.92),
                        "fy": rng.randf_range(0.08, 0.92),
                        "r": rng.randf_range(18.0, 44.0),
                        "ph": rng.randf_range(0.0, TAU),
                        "amp": rng.randf_range(6.0, 18.0),
                })

## The 52dp Unity banner is a NATIVE view in REAL px (menu.gd math).
func _banner_safe_px() -> float:
        var dpi := DisplayServer.screen_get_dpi()
        var win := DisplayServer.window_get_size()
        var vp := get_viewport_rect().size
        if win.x <= 0 or win.y <= 0 or vp.x <= 0.0 or vp.y <= 0.0:
                return 64.0
        var px_per_logical := minf(float(win.x) / vp.x, float(win.y) / vp.y)
        var phys := 52.0 * dpi / 160.0 + 12.0
        return maxf(64.0, ceilf(phys / maxf(0.05, px_per_logical)))

func _load_skin() -> void:
        var skin := Box.skin_on("snake")
        if skin == "" or not PALETTES.has(skin):
                skin = "classic"
        _pal = PALETTES[skin]
        # the player body wears the palette live (mid-run shop swaps repaint)
        if player != null:
                player.pal = {"pri": _pal["pri"], "milk": _pal["milk"]}

# ------------------------------------------------- world population

## (Re)builds everything that exists on the field for the CURRENT options.
func _new_run_objects() -> void:
        _eaten = 0
        enemies.clear()
        bugs.clear()
        obstacles.clear()
        apple_live = false
        coin_live = false
        power_live = false
        player.setup(board.get_center(), 0.0, _pal["pri"], _pal["milk"])
        player.base_speed = START_SPEED
        player.speed = START_SPEED
        if _opt_on("obstacles") and Box.unlock_owned(game_id, "obstacles"):
                _spawn_obstacles()
        if _opt_on("bugs") and Box.unlock_owned(game_id, "bugs"):
                for i in 2:
                        bugs.append(_new_bug())
        if _opt_on("enemies"):
                var n := 1
                if Box.unlock_owned(game_id, "pack"):
                        n = clampi(int(Box.get_progress(game_id, "enemy_count", 1)), 1, 10)
                for i in n:
                        _add_enemy(i)
        _spawn_fruit(true)
        _maybe_coin()

func _opt_on(key: String) -> bool:
        return bool(Box.get_progress(game_id, "opt_" + key, key == "enemies"))

func _set_opt(key: String, on: bool) -> void:
        Box.set_progress(game_id, "opt_" + key, on)

func _add_enemy(i: int) -> void:
        var col: Color = SnakeFruits.ENEMY_COLORS[i % 10]
        var b := SnakeBody.new()
        b.base_speed = START_SPEED * ENEMY_SPEED_RATIO
        b.speed = b.base_speed
        var ang := randf() * TAU
        var c := board.get_center() + Vector2.from_angle(ang) \
                        * minf(board.size.x, board.size.y) * 0.32
        b.setup(c, ang + PI, col, SnakeFruits.milk_for(col))
        enemies.append({
                "body": b,
                "ai": SnakeAI.new(b, i),
                "score": 0,
                "name": SnakeFruits.ENEMY_NAMES[i % 10],
                "bite_cd": 0.0,
        })

func _new_bug() -> Dictionary:
        var m := 80.0
        return {
                "pos": Vector2(randf_range(board.position.x + m, board.end.x - m),
                                randf_range(board.position.y + m, board.end.y - m)),
                "dir": randf() * TAU,
                "phase": randf() * TAU,
                "munch": 0.0,
                "hit_cd": 0.0,
        }

func _spawn_obstacles() -> void:
        obstacles.clear()
        for i in 3:
                var sz := Vector2(randf_range(90.0, 160.0), randf_range(70.0, 120.0))
                for attempt in 30:
                        var p := Vector2(randf_range(board.position.x + 110.0,
                                        board.end.x - 110.0 - sz.x),
                                        randf_range(board.position.y + 90.0,
                                        board.end.y - 90.0 - sz.y))
                        var r := Rect2(p, sz)
                        if r.grow(140.0).has_point(board.get_center()):
                                continue
                        var clear := true
                        for o in obstacles:
                                if (o as Rect2).grow(90.0).intersects(r):
                                        clear = false
                                        break
                        if clear:
                                obstacles.append(r)
                                break

# ============================================================== PHASES
# orient -> mode -> ready -> run. Every screen rebuilds the world under it.

func _clear_overlay_panel() -> void:
        if _overlay_panel != null and is_instance_valid(_overlay_panel):
                _overlay_panel.queue_free()
        _overlay_panel = null

## Screen 1: HOW DO YOU HOLD IT - the position ask (phone-position art),
## preselected from the last choice; picking OVERWRITES the auto sense.
func _show_orient_select() -> void:
        _phase = "orient"
        _clear_overlay_panel()
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
        vb.add_theme_constant_override("separation", 18)
        panel.add_child(vb)
        var t := Arc.label("HOW DO YOU HOLD IT?", 40, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(t)
        var sub := Arc.label("your snake field will be built this way", 20,
                        Color("8a6a40"), false)
        sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(sub)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 18)
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        vb.add_child(row)
        for choice in ["vertical", "horizontal"]:
                var on: bool = orient == choice
                var card := _phone_card(choice, on)
                card.pressed.connect(func():
                                Jukebox.sfx("confirm", -4.0)
                                orient = choice
                                Box.set_progress(game_id, "orient_pref", choice)
                                _build_field()
                                _new_run_objects()
                                _view.queue_redraw()
                                _show_mode_select())
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
        var l := Arc.label(kind.to_upper(), 26, Arc.INK if not selected \
                        else Color(0.16, 0.10, 0.05))
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.add_child(l)
        return b

## Screen 2: the mode menu + the OPTIONALS strip (left-right scrollable
## boxes). No-walls and the enemy are OPEN FROM START; power-ups / bugs /
## obstacles / fruits unlock in the shop - locked boxes wear a lock + coin
## price and tap through to the shop.
func _show_mode_select() -> void:
        _phase = "mode"
        _clear_overlay_panel()
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
                        Arc.panel_style(Color(1, 1, 1, 0.94), 26, 20))
        cc.add_child(panel)
        var vb := VBoxContainer.new()
        vb.add_theme_constant_override("separation", 14)
        panel.add_child(vb)
        var t := Arc.label("CHOOSE MODE", 38, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(t)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 14)
        row.alignment = BoxContainer.ALIGNMENT_CENTER
        vb.add_child(row)
        row.add_child(_mode_card("CLASSIC", "walls end the run", not wrap_mode,
                        func():
                                wrap_mode = false
                                Box.set_progress(game_id, "mode_nowalls", false)
                                _mode_picked()))
        row.add_child(_mode_card("NO-WALLS", "wrap edge to edge", wrap_mode,
                        func():
                                wrap_mode = true
                                Box.set_progress(game_id, "mode_nowalls", true)
                                _mode_picked()))
        var ot := Arc.label("OPTIONALS", 26, Color("6a5ab8"))
        ot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(ot)
        vb.add_child(_build_optionals_strip())
        var hint := Arc.label("locked boxes open in the shop", 16,
                        Color("8a6a40"), false)
        hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(hint)
        _overlay_panel = dim

func _mode_picked() -> void:
        _new_run_objects()
        _view.queue_redraw()
        _show_ready_card()

func _mode_card(txt: String, sub: String, selected: bool, cb: Callable) -> Button:
        var b := Button.new()
        b.custom_minimum_size = Vector2(280, 110)
        var sb := Arc.panel_style(Arc.GOOD if selected else Arc.CARD, 20, 10)
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
        vb.add_theme_constant_override("separation", 2)
        vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(vb)
        var l := Arc.label(txt, 30, Arc.INK if selected else Color(0.4, 0.32, 0.22))
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.add_child(l)
        var s := Arc.label(sub, 17, Color(0.35, 0.28, 0.18) if selected \
                        else Color(0.55, 0.48, 0.38), false)
        s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        s.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.add_child(s)
        b.pressed.connect(func():
                        Jukebox.sfx("click", -4.0)
                        cb.call())
        return b

## One optionals box: glyph + name + state line. Unlocked = toggle (enemy
## cycles the pack count when owned; fruits cycle their selector). Locked =
## gray, lock, coin price, tap opens the shop.
func _optional_box(icon: String, name_: String, state_fn: Callable,
                unlocked: bool, price: int, tap: Callable) -> Button:
        var b := Button.new()
        b.custom_minimum_size = Vector2(150, 160)
        var sb := Arc.panel_style(Arc.CARD, 18, 8)
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
        ic.texture = load("res://assets/ui/%s" % icon)
        ic.custom_minimum_size = Vector2(72, 72)
        ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.add_child(ic)
        var l := Arc.label(name_, 20, Arc.INK)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vb.add_child(l)
        var st := Arc.label(String(state_fn.call()), 16, Color("6a4a28"), false)
        st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        st.mouse_filter = Control.MOUSE_FILTER_IGNORE
        st.name = "state"
        vb.add_child(st)
        if not unlocked:
                b.disabled = true
                var sbd := Arc.panel_style(Color(0.82, 0.78, 0.7, 0.9), 18, 8)
                b.add_theme_stylebox_override("disabled", sbd)
                l.add_theme_color_override("font_color", Color(0.55, 0.5, 0.42))
                var lock_ic := TextureRect.new()
                lock_ic.texture = load("res://assets/ui/icon_lock.png")
                lock_ic.custom_minimum_size = Vector2(34, 34)
                lock_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                lock_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                lock_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
                lock_ic.position = Vector2(8, 8)
                b.add_child(lock_ic)
                # THE PRICE RULE: the GOGACoin icon rides every price
                var chip := Arc.chip(str(price), "res://assets/ui/coin.png",
                                Color(0, 0, 0, 0.55), 16, Arc.COIN)
                chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
                chip.position = Vector2(30, 122)
                b.add_child(chip)
        b.pressed.connect(func():
                        if not unlocked:
                                Jukebox.sfx("error", -4.0)
                                _shop_open()
                                return
                        Jukebox.sfx("click", -4.0)
                        tap.call()
                        # refresh the state line + the world behind the dim
                        st.text = String(state_fn.call())
                        _new_run_objects()
                        _view.queue_redraw())
        return b

func _build_optionals_strip() -> Control:
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
        sc.custom_minimum_size = Vector2(596, 176)   # scrolls INSIDE the panel
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 12)
        sc.add_child(row)
        # ENEMY - open from the start; the pack makes the count selectable
        var pack := Box.unlock_owned(game_id, "pack")
        row.add_child(_optional_box("opt_enemy.png", "ENEMY",
                        func(): return _enemy_state_txt(pack), true, 0,
                        func():
                                var on := not _opt_on("enemies")
                                if on:
                                        _set_opt("enemies", true)
                                elif pack:
                                        # OFF -> tap again cycles the count
                                        var n := clampi(int(Box.get_progress(
                                                game_id, "enemy_count", 1)), 1, 10)
                                        n = n % 10 + 1
                                        Box.set_progress(game_id, "enemy_count", n)
                                        _set_opt("enemies", true)
                                else:
                                        _set_opt("enemies", false)))
        # POWER-UPS
        var pu_unlocked := Box.unlock_owned(game_id, "powerups")
        row.add_child(_optional_box("opt_power.png", "POWER-UPS",
                        func(): return "ON" if _opt_on("powerups") else "OFF",
                        pu_unlocked, PRICE_POWERUPS,
                        func(): _set_opt("powerups", not _opt_on("powerups"))))
        # BUGS
        var bug_unlocked := Box.unlock_owned(game_id, "bugs")
        row.add_child(_optional_box("opt_bugs.png", "BUGS",
                        func(): return "ON" if _opt_on("bugs") else "OFF",
                        bug_unlocked, PRICE_BUGS,
                        func(): _set_opt("bugs", not _opt_on("bugs"))))
        # OBSTACLES
        var ob_unlocked := Box.unlock_owned(game_id, "obstacles")
        row.add_child(_optional_box("opt_obst.png", "OBSTACLES",
                        func(): return "ON" if _opt_on("obstacles") else "OFF",
                        ob_unlocked, PRICE_OBSTACLES,
                        func(): _set_opt("obstacles", not _opt_on("obstacles"))))
        # FRUITS - the wardrobe selector (needs at least one owned fruit)
        var owned := Box.items_owned(game_id, "fruit")
        row.add_child(_optional_box("opt_fruit.png", "FRUITS",
                        func(): return _fruit_state_txt(owned),
                        owned.size() > 0, 80,
                        func(): _cycle_fruit_mode(owned)))
        # register all boxes as BoxScroll tappables (BoxScroll owns taps)
        for b in row.get_children():
                if b is Button:
                        b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        sc.register_tappable(b, Arc._tap_emitter(b))
        return sc

func _enemy_state_txt(pack: bool) -> String:
        if not _opt_on("enemies"):
                return "OFF"
        if not pack:
                return "1 GREEN"
        var n := clampi(int(Box.get_progress(game_id, "enemy_count", 1)), 1, 10)
        return "%d SNAKES" % n

func _fruit_state_txt(owned: Array) -> String:
        var mode := String(Box.get_progress(game_id, "fruit_mode", "apple"))
        if mode == "all":
                return "ALL OWNED"
        if SnakeFruits.FRUITS.has(mode):
                return String(SnakeFruits.FRUITS[mode]["name"]).to_upper()
        return "APPLE"

func _cycle_fruit_mode(owned: Array) -> void:
        var mode := String(Box.get_progress(game_id, "fruit_mode", "apple"))
        var pool := ["apple", "all"]
        for f in owned:
                pool.append(String(f))
        var i := pool.find(mode)
        Box.set_progress(game_id, "fruit_mode", pool[(i + 1) % pool.size()])

# ------------------------------------------------------- ready / start

func _show_ready_card() -> void:
        _phase = "ready"
        _clear_overlay_panel()
        var cc := CenterContainer.new()
        cc.set_anchors_preset(Control.PRESET_FULL_RECT)
        cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var panel := PanelContainer.new()
        panel.add_theme_stylebox_override("panel",
                        Arc.panel_style(Color(1, 1, 1, 0.82), 20))
        var lbl := Arc.label("TAP ANYWHERE TO START", 40, Arc.INK)
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        panel.add_child(lbl)
        cc.add_child(panel)
        panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
        lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
        cc.modulate.a = 0.0
        _overlay_root_ref().add_child(cc)
        _ready_card = cc
        var tw := cc.create_tween()
        tw.tween_property(cc, "modulate:a", 1.0, 0.18)
        tw.parallel().tween_method(_card_step.bind(cc), 0.7, 1.0, 0.26) \
                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _card_step(s: float, cc: Control) -> void:
        if not is_instance_valid(cc):
                return
        cc.pivot_offset = cc.size / 2.0
        cc.scale = Vector2(s, s)

func _start() -> void:
        if _phase != "ready" or not player.alive:
                return
        _phase = "run"
        Jukebox.sfx("snake_start", -4.0)
        if _ready_card != null and is_instance_valid(_ready_card):
                var cc := _ready_card
                _ready_card = null
                var tw := cc.create_tween()
                tw.tween_method(_card_step.bind(cc), 1.0, 1.16, 0.12) \
                                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
                tw.tween_method(_card_step.bind(cc), 1.16, 0.0, 0.14) \
                                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
                tw.tween_callback(cc.queue_free)

# ============================================================== INPUT
# The INVISIBLE ANALOG WHEEL: the first finger to touch the field becomes
# the wheel center; the drag vector is the stick. The stick's angle is the
# head's TARGET heading in ABSOLUTE screen space - drag left = aim left,
# even when the head is upside down (owner's exact rule). The actual
# bending respects the capped turn rate. Release keeps the heading.

func _goga_input(event: InputEvent) -> void:
        if event is InputEventScreenTouch:
                var t := event as InputEventScreenTouch
                if t.pressed:
                        if _phase == "ready" and player.alive:
                                _start()
                        if _phase == "run" and _wheel_idx == -1:
                                _wheel_idx = t.index
                                _wheel_center = t.position
                                _wheel_stick = Vector2.ZERO
                elif t.index == _wheel_idx:
                        _wheel_idx = -1
                        _wheel_stick = Vector2.ZERO
        elif event is InputEventScreenDrag:
                var d := event as InputEventScreenDrag
                if d.index == _wheel_idx:
                        _wheel_stick = d.position - _wheel_center

func _steer(delta: float) -> void:
        var stick := _wheel_stick
        if stick.length() < WHEEL_DEADZONE:
                return
        var target := stick.angle()
        var diff := wrapf(target - player.head_dir, -PI, PI)
        var max_step := TURN_RATE * delta
        if absf(diff) <= max_step:
                player.head_dir = target
        else:
                player.head_dir += signf(diff) * max_step

# ============================================================== THE RUN

func _goga_tick(delta: float) -> void:
        _time += delta
        _tick_fx(delta)
        _tick_tongue(delta)
        if _phase == "run" and player.alive:
                _steer(delta)
                var adv := player.advance(delta, board, wrap_mode)
                player.tick_effects(delta)
                if adv["hit_wall"]:
                        _die()
                else:
                        _tick_pickups()
                        _tick_power_cycle(delta)
                        _tick_magnet(delta)
                        _tick_enemies(delta)
                        _tick_bugs(delta)
                        _check_player_collisions()
                        _tick_bites(delta)
        if _view != null and is_instance_valid(_view):
                _view.queue_redraw()
        if _chips != null and is_instance_valid(_chips):
                _chips.queue_redraw()

## World getters the AI reads.
func player_body() -> SnakeBody:
        return player

func all_bodies() -> Array:
        var out: Array = [player]
        for e in enemies:
                if (e["body"] as SnakeBody).alive:
                        out.append(e["body"])
        return out

# ------------------------------------------------------------- pickups

func _tick_pickups() -> void:
        var hr := player.head_r()
        if apple_live and apple_pop > 0.5 \
                        and player.head_pos.distance_to(apple_pos) < hr + apple_r * 0.8:
                _eat_fruit(player, true)
        if coin_live and coin_pop > 0.5 \
                        and player.head_pos.distance_to(coin_pos) < hr + 24.0:
                _take_coin(true, {})
        if power_live and power_pop > 0.5 \
                        and player.head_pos.distance_to(power_pos) < hr + apple_r:
                _apply_power(player, power_id, true)

## Eater = the eater GROWS, the eaten SHRINKS. Wither curse inverts the
## fruit: it eats YOU instead (the owner's power-down). Score x3 while
## GOLDEN is live (the AI feels it too - "apples become profitable").
func _eat_fruit(by: SnakeBody, is_player: bool) -> void:
        var e := _enemy_of(by) if not is_player else {}
        var golden: bool = by.has_power("golden")
        if by.has_power("wither"):
                by.len_target = maxf(LEN_FLOOR, by.len_target - LEN_PER_APPLE)
                by.length_px = minf(by.length_px, by.len_target + LEN_PER_APPLE)
                Jukebox.sfx("power_bad", -4.0)
                _burst(apple_pos, [Color("8ac44a"), Color("8a6a40")], 9)
        else:
                by.len_target += LEN_PER_APPLE
                by.width = minf(by.width + WIDTH_PER_APPLE, WIDTH_MAX)
                by.speed = minf(by.speed + SPEED_PER_APPLE, SPEED_MAX)
                var pts: int = 3 if golden else 1
                if is_player:
                        _eaten += 1
                        set_score(score + pts)
                else:
                        e["score"] += pts
                Jukebox.sfx("snake_eat", -4.0, 1.0 + 0.016 * mini(24, _eaten))
                _burst(apple_pos, [SnakeFruits.fruit_body(edible_id),
                                SnakeFruits.FRUITS[edible_id]["acc"],
                                Color("fff3dc")], 11)
        _ring(apple_pos, SnakeFruits.fruit_body(edible_id))
        _spawn_fruit()
        _maybe_coin()

func _enemy_of(b: SnakeBody) -> Dictionary:
        for e in enemies:
                if e["body"] == b:
                        return e
        return {}

## one pickup = ONE GOGACoin (owner rule). The enemy collects coins too -
## a stolen coin is a lost coin (owner economy design).
func _take_coin(is_player: bool, e := {}) -> void:
        if is_player:
                add_run_coins(1)
                achievement_count("coins_taken", 1)
                achievement_max("coins_got", run_coins)
        else:
                e["score"] += 1
        Jukebox.sfx("coin", -4.0 if is_player else -8.0)
        _burst(coin_pos, [Arc.COIN, Color("fff3dc")], 9)
        _ring(coin_pos, Arc.COIN)
        coin_live = false
        coin_pop = 0.0
        coin_pos = Vector2(-100, -100)
        _maybe_coin()

func _maybe_coin() -> void:
        if coin_live:
                return
        if randf() < 0.45:
                var m := 40.0
                for i in 40:
                        var p := Vector2(randf_range(board.position.x + m, board.end.x - m),
                                        randf_range(board.position.y + m, board.end.y - m))
                        if p.distance_to(player.head_pos) > 200.0 and not _near_any_body(p, 30.0) \
                                        and (not apple_live or p.distance_to(apple_pos) > 60.0) \
                                        and not _in_obstacle(p, 40.0):
                                coin_pos = p
                                coin_live = true
                                coin_pop = 0.0
                                if _coin_tween != null and _coin_tween.is_valid():
                                        _coin_tween.kill()
                                _coin_tween = create_tween()
                                _coin_tween.tween_property(self, "coin_pop", 1.0, 0.22) \
                                                .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                                return

## MAGNET: a nearby coin flies to you "from further area" (owner power).
func _tick_magnet(delta: float) -> void:
        if not coin_live or not player.has_power("magnet"):
                return
        var d := player.head_pos.distance_to(coin_pos)
        if d < MAGNET_RANGE:
                coin_pos = coin_pos.move_toward(player.head_pos,
                                (500.0 - d) * 1.6 * delta)

# ------------------------------------------------------------- the fruit

func _spawn_fruit(first := false) -> void:
        var owned := Box.items_owned(game_id, "fruit")
        var mode := String(Box.get_progress(game_id, "fruit_mode", "apple"))
        edible_id = SnakeFruits.roll_edible(owned, mode)
        var m := apple_r + 20.0
        var best := Vector2.ZERO
        var best_d := -1.0
        for i in 60:
                var p := Vector2(randf_range(board.position.x + m, board.end.x - m),
                                randf_range(board.position.y + m, board.end.y - m))
                var dh := p.distance_to(player.head_pos)
                if dh < 170.0:
                        continue
                if not first and _near_any_body(p, 30.0):
                        continue
                if _in_obstacle(p, 50.0):
                        continue
                if dh > best_d:
                        best_d = dh
                        best = p
                if best_d > 420.0:
                        break
        apple_pos = best
        if best_d < 0.0:
                # tiny boards fallback: anywhere honest
                apple_pos = board.get_center() + Vector2(randf_range(-60.0, 60.0),
                                randf_range(-60.0, 60.0))
        apple_r = clampf(player.width * 0.85, 22.0, 42.0)
        apple_live = true
        apple_pop = 0.0
        if _apple_tween != null and _apple_tween.is_valid():
                _apple_tween.kill()
        _apple_tween = create_tween()
        _apple_tween.tween_property(self, "apple_pop", 1.0, 0.24) \
                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        _ring(apple_pos, SnakeFruits.fruit_body(edible_id))

func _near_any_body(p: Vector2, r: float) -> bool:
        for s in all_bodies():
                if s == null or not s.alive:
                        continue
                var step := 0.0
                var acc := 0.0
                var tr: Array[Vector2] = s.trail
                for i in range(tr.size() - 1, 0, -1):
                        var seg := tr[i].distance_to(tr[i - 1])
                        if seg > 220.0:
                                acc += seg
                                step += seg
                                continue
                        while step <= acc + seg:
                                var t := (step - acc) / maxf(seg, 0.001)
                                if tr[i].lerp(tr[i - 1], t).distance_to(p) < r:
                                        return true
                                step += 22.0
                        acc += seg
                        if step > s.length_px + 40.0:
                                break
        return false

func _in_obstacle(p: Vector2, pad: float) -> bool:
        for o in obstacles:
                if (o as Rect2).grow(pad).has_point(p):
                        return true
        return false

# ------------------------------------------------------------- powers

func _tick_power_cycle(delta: float) -> void:
        if not (_opt_on("powerups") and Box.unlock_owned(game_id, "powerups")):
                if power_live:
                        power_live = false
                return
        if power_live:
                power_age += delta
                if power_age > POWER_BOARD_LIFE:
                        _despawn_power()
                return
        if _time < power_next_at:
                return
        # weighted pick among types OFF cooldown (eater needs the pack)
        var pool: Array = []
        for id in SnakeFruits.POWERS:
                var p: Dictionary = SnakeFruits.POWERS[id]
                if float(power_cd.get(id, 0.0)) > _time:
                        continue
                if String(p["needs"]) == "pack" and not Box.unlock_owned(game_id, "pack"):
                        continue
                pool.append([id, float(p["weight"])])
        if pool.is_empty():
                power_next_at = _time + 2.0
                return
        var total := 0.0
        for it in pool:
                total += float(it[1])
        var roll := randf() * total
        var chosen: String = pool[0][0]
        for it in pool:
                roll -= float(it[1])
                if roll <= 0.0:
                        chosen = String(it[0])
                        break
        var m := apple_r + 26.0
        for i in 40:
                var p := Vector2(randf_range(board.position.x + m, board.end.x - m),
                                randf_range(board.position.y + m, board.end.y - m))
                if p.distance_to(player.head_pos) > 230.0 and not _near_any_body(p, 34.0) \
                                and (not apple_live or p.distance_to(apple_pos) > 90.0) \
                                and not _in_obstacle(p, 46.0):
                        power_pos = p
                        power_id = chosen
                        power_live = true
                        power_age = 0.0
                        power_pop = 0.0
                        var tw := create_tween()
                        tw.tween_property(self, "power_pop", 1.0, 0.26) \
                                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                        _ring(power_pos, SnakeFruits.POWERS[chosen]["aura"])
                        return
        power_next_at = _time + 2.0

func _despawn_power() -> void:
        if power_id != "":
                var p: Dictionary = SnakeFruits.POWERS[power_id]
                power_cd[power_id] = _time + randf_range(float(p["cd"].x), float(p["cd"].y))
        power_live = false
        power_pop = 0.0
        # every type keeps its OWN rhythm (owner: never uniform randomness)
        power_next_at = _time + randf_range(4.5, 8.0)

## The effect lands on WHOEVER ate it - the player AND the AI (symmetry).
func _apply_power(by: SnakeBody, id: String, is_player: bool) -> void:
        var p: Dictionary = SnakeFruits.POWERS[id]
        by.apply_power(id, float(p["dur"]))
        if bool(p["good"]):
                if id == "ghost":
                        Jukebox.sfx("ghost", -4.0)
                else:
                        var pitch := 1.0
                        if id == "faster":
                                pitch = 1.15
                        elif id == "slower":
                                pitch = 0.92
                        Jukebox.sfx("power_good", -3.0, pitch)
        else:
                Jukebox.sfx("power_bad", -2.0)
        _burst(power_pos, [p["aura"], Color("fff3dc")], 12)
        _ring(power_pos, p["aura"])
        if is_player:
                _toast_show("%s  %s" % [p["name"],
                                "DOWN - fruits shrink you!" if not bool(p["good"])
                                else "UP!"])
        _despawn_power()

# ------------------------------------------------------------- enemies

func _tick_enemies(delta: float) -> void:
        for e in enemies:
                var b: SnakeBody = e["body"]
                if not b.alive:
                        continue
                b.tick_effects(delta)
                (e["ai"] as SnakeAI).think(delta, self)
                var adv := b.advance(delta, board, wrap_mode)
                if adv["hit_wall"] or b.self_bite(b.head_pos, b.head_r()) \
                                or _in_obstacle(b.head_pos, -b.head_r() * 0.3):
                        _kill_enemy(e)
                        continue
                # enemy head vs the PLAYER's body = the enemy dies...
                # ...UNLESS it wears the eater and found the tail zone: bite.
                var bite_pt: Array = []
                if b.has_power("eater") and player.alive \
                                and player.body_hit(b.head_pos, b.head_r() * 0.9,
                                        0.30, bite_pt):
                        if float(e["bite_cd"]) <= 0.0:
                                e["bite_cd"] = 0.45
                                player.len_target = maxf(LEN_FLOOR,
                                                player.len_target - EATER_BITE_PX)
                                player.length_px = maxf(LEN_FLOOR,
                                                player.length_px - EATER_BITE_PX)
                                b.len_target += EATER_GROW_PX
                                e["score"] += 1
                                Jukebox.sfx("tail_bite", -2.0)
                                _burst(bite_pt[0] if bite_pt.size() > 0 else b.head_pos,
                                                [b.pal["pri"], FLASH_RED], 10)
                        continue
                if player.alive and player.body_hit(b.head_pos, b.head_r() * 0.9):
                        _kill_enemy(e)
                        continue
                # pickups
                if apple_live and apple_pop > 0.5 and \
                                b.head_pos.distance_to(apple_pos) < b.head_r() + apple_r * 0.8:
                        _eat_fruit(b, false)
                if coin_live and coin_pop > 0.5 and \
                                b.head_pos.distance_to(coin_pos) < b.head_r() + 24.0:
                        _take_coin(false, e)
                if power_live and power_pop > 0.5 and \
                                b.head_pos.distance_to(power_pos) < b.head_r() + apple_r:
                        _apply_power(b, power_id, false)
                e["bite_cd"] = float(e["bite_cd"]) - delta

func _kill_enemy(e: Dictionary) -> void:
        var b: SnakeBody = e["body"]
        b.alive = false
        Jukebox.sfx("snake_die", -4.0, 0.8)
        _burst(b.head_pos, [b.pal["pri"], FLASH_RED, Color("fff3dc")], 14)
        _ring(b.head_pos, b.pal["pri"])
        # permanent for this round - no respawn (owner rule)

# ------------------------------------------------------------- bugs

func _tick_bugs(delta: float) -> void:
        for b in bugs:
                b["hit_cd"] = float(b["hit_cd"]) - delta
                if float(b["munch"]) > 0.0:
                        b["munch"] = float(b["munch"]) - delta
                        continue
                # wander: drift the heading, bounce off walls/obstacles
                b["dir"] = float(b["dir"]) + sin(_time * 1.7 + float(b["phase"])) * 1.4 * delta
                var sp := 175.0
                var np: Vector2 = (b["pos"] as Vector2) + Vector2.from_angle(float(b["dir"])) * sp * delta
                var m := 34.0
                if np.x < board.position.x + m or np.x > board.end.x - m:
                        b["dir"] = PI - float(b["dir"])
                        np.x = clampf(np.x, board.position.x + m, board.end.x - m)
                if np.y < board.position.y + m or np.y > board.end.y - m:
                        b["dir"] = -float(b["dir"])
                        np.y = clampf(np.y, board.position.y + m, board.end.y - m)
                if _in_obstacle(np, 18.0):
                        b["dir"] += PI * 0.7
                        np = b["pos"]
                b["pos"] = np
                # steal the fruit (Snake3D: the bug eats your food)
                if apple_live and apple_pop > 0.5 and \
                                        np.distance_to(apple_pos) < 26.0:
                        b["munch"] = 0.6
                        _burst(apple_pos, [SnakeFruits.fruit_body(edible_id)], 6)
                        Jukebox.sfx("pop_deep", -8.0)
                        _spawn_fruit()
                # bite the player: length + score bleed, NEVER death (owner/Snake3D)
                if b["hit_cd"] <= 0.0 and player.alive and not player.has_power("ghost") \
                                        and np.distance_to(player.head_pos) < player.head_r() + 16.0:
                        b["hit_cd"] = 1.5
                        player.len_target = maxf(LEN_FLOOR, player.len_target - BUG_LEN_PENALTY)
                        player.length_px = maxf(LEN_FLOOR, player.length_px - BUG_LEN_PENALTY * 0.5)
                        set_score(maxi(0, score - BUG_SCORE_PENALTY))
                        Jukebox.sfx("bug_hit", -2.0)
                        _burst(np, [BUG_BODY, FLASH_RED], 10)
                        _ring(np, FLASH_RED)
                # bugs nibble enemies too (no score, just body)
                for e in enemies:
                        var eb: SnakeBody = e["body"]
                        if eb.alive and b["hit_cd"] <= 0.0 and \
                                                np.distance_to(eb.head_pos) < eb.head_r() + 16.0:
                                b["hit_cd"] = 1.5
                                eb.len_target = maxf(LEN_FLOOR, eb.len_target - BUG_LEN_PENALTY * 0.6)

# ------------------------------------------------------- player collisions

func _check_player_collisions() -> void:
        var hr := player.head_r()
        var ghost := player.has_power("ghost")
        # arena walls still kill a ghost (the edge is the edge)
        if not wrap_mode:
                if player.head_pos.x - hr * 0.7 < board.position.x \
                                or player.head_pos.x + hr * 0.7 > board.end.x \
                                or player.head_pos.y - hr * 0.7 < board.position.y \
                                or player.head_pos.y + hr * 0.7 > board.end.y:
                        _die()
                        return
        if not ghost:
                if player.self_bite(player.head_pos, hr):
                        _die()
                        return
                if _in_obstacle(player.head_pos, -hr * 0.45):
                        _die()
                        return
                # enemy bodies are death
                for e in enemies:
                        var b: SnakeBody = e["body"]
                        if b.alive and b.body_hit(player.head_pos, hr * 0.9):
                                _die()
                                return
        # head-to-head: the LONGER snake survives the meeting
        for e in enemies:
                var b: SnakeBody = e["body"]
                if b.alive and player.head_pos.distance_to(b.head_pos) \
                                < (hr + b.head_r()) * 0.72:
                        if player.length_px >= b.length_px:
                                _kill_enemy(e)
                        elif not ghost:
                                _die()
                                return

## SNAKE-EATER (player side): touch the enemy's TAIL ONLY - bite segments
## off it, grow, score. The tail zone is the tailmost 30% (owner: "from
## there tails only").
func _tick_bites(delta: float) -> void:
        _bite_cd -= delta
        if _bite_cd > 0.0 or not player.has_power("eater"):
                return
        for e in enemies:
                var b: SnakeBody = e["body"]
                if not b.alive:
                        continue
                var bite_pt: Array = []
                if b.body_hit(player.head_pos, player.head_r() * 0.9, 0.30, bite_pt):
                        _bite_cd = 0.45
                        b.len_target = maxf(LEN_FLOOR, b.len_target - EATER_BITE_PX)
                        b.length_px = maxf(LEN_FLOOR, b.length_px - EATER_BITE_PX)
                        player.len_target += EATER_GROW_PX
                        set_score(score + 1)
                        Jukebox.sfx("tail_bite", -2.0)
                        _burst(bite_pt[0] if bite_pt.size() > 0 else player.head_pos,
                                        [b.pal["pri"], Color("58c470")], 10)
                        break

# ------------------------------------------------------------- death

func _die() -> void:
        if not player.alive:
                return
        player.alive = false
        Jukebox.sfx("snake_die", -2.0)
        Jukebox.stop_music()   # the run's music dies with the run
        achievement_max("length", 3 + _eaten)
        check_achievements()
        _burst(player.head_pos, [_pal["pri"], FLASH_RED, Color("fff3dc")], 12)
        _ring(player.head_pos, FLASH_RED)
        # OWNER FIX (stays from v0.1.8): flash ONLY the snake.
        var tw := create_tween().set_loops(3)
        tw.tween_property(player, "flash", 1.0, 0.09)
        tw.tween_property(player, "flash", 0.0, 0.09)
        tw.finished.connect(func(): finish_run(score))

# ----------------------------------------------------------------- fx

func _tick_fx(delta: float) -> void:
        for m in _motes:
                m["p"] = m["p"] as Vector2 + (m["v"] as Vector2) * delta
                m["v"] = (m["v"] as Vector2).lerp(Vector2.ZERO, 3.2 * delta)
                m["life"] = float(m["life"]) - delta
        _motes = _motes.filter(func(m): return float(m["life"]) > 0.0)
        for r in _rings:
                r["life"] = float(r["life"]) - delta
        _rings = _rings.filter(func(r): return float(r["life"]) > 0.0)
        if coin_pop > 0.0:
                coin_rot += 3.4 * delta

func _burst(p: Vector2, cols: Array, n: int) -> void:
        for i in n:
                _motes.append({
                        "p": p,
                        "v": Vector2.from_angle(randf() * TAU) * randf_range(90.0, 340.0),
                        "r": randf_range(4.0, 11.0),
                        "c": cols[i % cols.size()],
                        "life": randf_range(0.35, 0.65),
                        "max": 0.65,
                })

func _ring(p: Vector2, col: Color) -> void:
        _rings.append({"p": p, "r0": 8.0, "r1": 74.0, "life": 0.34, "max": 0.34,
                        "col": col})

func _tick_tongue(delta: float) -> void:
        _tongue_cd -= delta
        if _tongue_cd <= 0.0:
                _tongue_t = 0.26
                _tongue_cd = randf_range(1.4, 2.8)
        if _tongue_t > 0.0:
                _tongue_t -= delta

func _tongue_out() -> float:
        var out := 0.0
        if _tongue_t > 0.0:
                var prog := clampf(1.0 - _tongue_t / 0.26, 0.0, 1.0)
                out = sin(PI * prog)
        if player != null and player.alive and apple_live:
                var to_a := apple_pos - player.head_pos
                if to_a.length() < player.width * 3.4 \
                                and absf(player.head_dir - to_a.angle()) < 1.1:
                        out = maxf(out, 0.6)
        return out

# ================================================================== PAINT
## Everything the player sees, one pass: field, deco, border (walls OR the
## wrap markers), obstacles, rings, coin, fruit, power fruit, bugs, enemy
## snakes, the player snake, motes.

func _paint(v: Node2D) -> void:
        var vp := get_viewport_rect().size
        v.draw_rect(Rect2(Vector2.ZERO, vp), FIELD)
        # drifting deco blobs (super subtle, alive) - also OUTSIDE the field
        for d in _deco:
                var p := Vector2(
                                board.position.x + float(d["fx"]) * board.size.x
                                                + sin(_time * 0.22 + float(d["ph"])) * float(d["amp"]),
                                board.position.y + float(d["fy"]) * board.size.y
                                                + cos(_time * 0.18 + float(d["ph"]) * 1.7)
                                                * float(d["amp"]))
                v.draw_circle(p, float(d["r"]), Color(FIELD_DECO, 0.38))
        _paint_border(v)
        # obstacles
        for o in obstacles:
                v.draw_rect((o as Rect2).grow(3.0), OBST_EDGE, false, 4.0)
                v.draw_rect(o as Rect2, OBST_FILL)
                # brick seams
                var seam_y := (o as Rect2).position.y + (o as Rect2).size.y * 0.5
                v.draw_line(Vector2((o as Rect2).position.x + 6.0, seam_y),
                                Vector2((o as Rect2).end.x - 6.0, seam_y),
                                OBST_EDGE, 2.5)
        # rings
        for r in _rings:
                var t := 1.0 - float(r["life"]) / float(r["max"])
                var col: Color = r["col"]
                col.a = 0.55 * (1.0 - t)
                v.draw_arc(r["p"], lerpf(float(r["r0"]), float(r["r1"]), t), 0, TAU,
                                40, col, 4.0, true)
        # coin (under the snakes)
        if coin_live and coin_pop > 0.0 and _coin_tex != null:
                var cpop := (1.0 + 0.08 * sin(_time * 4.2)) * coin_pop
                var cs := 54.0 / float(_coin_tex.get_width())
                v.draw_set_transform(coin_pos, coin_rot,
                                Vector2(cs * cpop, cs / cpop * coin_pop))
                v.draw_texture(_coin_tex, -_coin_tex.get_size() / 2.0)
                v.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        # the edible (pop + breathing - never an alpha fade)
        if apple_live and apple_pop > 0.0:
                SnakeFruits.paint_fruit(v, edible_id, apple_pos, apple_r * apple_pop, _time)
        # the power fruit (the aura IS the type signal)
        if power_live and power_pop > 0.0:
                var blink := 1.0
                if power_age > POWER_BOARD_LIFE - 2.0:
                        blink = 0.55 + 0.45 * sin(_time * 14.0)   # about to leave
                SnakeFruits.paint_power_fruit(v, power_id, edible_id, power_pos,
                                apple_r * power_pop * blink, _time)
        # bugs on top of food, under snakes
        for b in bugs:
                _paint_bug(v, b)
        # snakes: enemies first (the player rides on top)
        for e in enemies:
                var b: SnakeBody = e["body"]
                if b.alive:
                        _paint_snake(v, b, false)
        if player != null:
                _paint_snake(v, player, true)
        # motes on top
        for m in _motes:
                var a := clampf(float(m["life"]) / float(m["max"]), 0.0, 1.0)
                var col: Color = m["c"]
                col.a = a
                v.draw_circle(m["p"], float(m["r"]) * (0.5 + 0.5 * a), col)

## CLASSIC: the rounded deadly wall line. NO-WALLS: a dashed open border +
## outward chevrons at the edge midpoints (this edge is a DOOR).
func _paint_border(v: Node2D) -> void:
        if not wrap_mode:
                v.draw_polyline(_rounded_rect(board, 26.0), WALL, 5.0, true)
                return
        var pts := _rounded_rect(board, 26.0)
        var dashed := PackedVector2Array()
        var run := 0.0
        var draw_on := true
        for i in range(1, pts.size()):
                var a: Vector2 = pts[i - 1]
                var b: Vector2 = pts[i]
                var seg := a.distance_to(b)
                var steps := int(seg / 14.0)
                for k in steps:
                        var p := a.lerp(b, float(k) / maxf(1, steps))
                        if draw_on:
                                dashed.append(p)
                        run += 14.0
                        if run > 26.0:
                                run = 0.0
                                draw_on = not draw_on
        v.draw_polyline(dashed, WRAP_LINE, 4.0, false)
        for i in 4:
                var mid := Vector2(board.get_center().x, board.position.y) \
                                if i == 0 else \
                                Vector2(board.end.x, board.get_center().y) if i == 1 \
                                else Vector2(board.get_center().x, board.end.y) if i == 2 \
                                else Vector2(board.position.x, board.get_center().y)
                var out_dir := Vector2.UP if i == 0 else Vector2.RIGHT if i == 1 \
                                else Vector2.DOWN if i == 2 else Vector2.LEFT
                for s in [-1.0, 1.0]:
                        var tip: Vector2 = mid + out_dir * 20.0
                        var wing: Vector2 = out_dir.rotated(PI * 0.5) * 13.0 * s
                        v.draw_polyline(PackedVector2Array([mid - out_dir * 4.0 + wing,
                                        tip, mid - out_dir * 4.0 - wing]),
                                        WRAP_LINE, 4.0, true)

## ONE snake = TWO polygons (the soft dark outline pass, then the gradient
## ribbon) + the head. No circles. TOO smooth.
func _paint_snake(v: Node2D, s: SnakeBody, is_player: bool) -> void:
        var ghost_a := 0.5 if s.has_power("ghost") else 1.0
        # outline pass: the same ribbon, 3.5px fatter, inked
        var under := s.ribbon(3.5,
                        (s.pal["pri"] as Color).darkened(0.45) * Color(1, 1, 1, ghost_a))
        if under.is_empty():
                return
        v.draw_polygon(under["pts"], under["cols"])
        var rib := s.ribbon()
        if ghost_a < 1.0:
                # per-vertex alpha for the ghost phase
                var pts2: PackedVector2Array = rib["pts"]
                var cols2 := PackedColorArray()
                for c in rib["cols"]:
                        var cc: Color = c
                        cc.a = ghost_a
                        cols2.append(cc)
                v.draw_polygon(pts2, cols2)
        else:
                v.draw_polygon(rib["pts"], rib["cols"])
        _paint_head(v, s, is_player)

func _paint_head(v: Node2D, s: SnakeBody, is_player: bool) -> void:
        var hr := s.head_r()
        var ghost_a := 0.5 if s.has_power("ghost") else 1.0
        var c := s.body_color(0.0)
        c.a = ghost_a
        var rim := c.darkened(0.24)
        rim.a = ghost_a
        var fwd := Vector2.from_angle(s.head_dir)
        var side := Vector2.from_angle(s.head_dir + PI / 2.0)
        var pos := s.head_pos
        # tongue BEHIND the head so its root hides under the face
        var tout := _tongue_out() if is_player else _enemy_tongue(s)
        if tout > 0.02 and s.alive:
                var base := pos + fwd * hr * 0.85
                var tip := base + fwd * hr * 1.5 * tout
                var fork := side * hr * 0.42 * tout
                var tcol := TONGUE_RED
                tcol.a = ghost_a
                v.draw_line(base, tip, tcol, 3.4, true)
                v.draw_line(tip, tip + (fwd * 0.45 + fork).normalized() * hr * 0.5
                                * tout, tcol, 3.0, true)
                v.draw_line(tip, tip + (fwd * 0.45 - fork).normalized() * hr * 0.5
                                * tout, tcol, 3.0, true)
        v.draw_circle(pos, hr + 2.6, rim)
        v.draw_circle(pos, hr, c)
        # eyes
        for sg in [-1.0, 1.0]:
                var e: Vector2 = pos + fwd * hr * 0.34 + side * hr * 0.52 * sg
                var ew := EYE_WHITE
                ew.a = ghost_a
                v.draw_circle(e, hr * 0.33, ew)
                if s.alive:
                        var ei := EYE_INK
                        ei.a = ghost_a
                        v.draw_circle(e + fwd * hr * 0.10, hr * 0.16, ei)
                else:
                        # x eyes - the run is over
                        var k := hr * 0.13
                        for q in [Vector2(k, k), Vector2(k, -k)]:
                                v.draw_line(e - q, e + q, EYE_INK, 3.0, true)

## enemies flick their tongues on their own rhythm
func _enemy_tongue(s: SnakeBody) -> float:
        var ph := s.head_pos.x * 0.031 + s.head_pos.y * 0.017
        var cycle := fmod(_time * 0.55 + ph, 1.0)
        return sin(PI * clampf(cycle / 0.18, 0.0, 1.0)) if cycle < 0.18 else 0.0

func _paint_bug(v: Node2D, b: Dictionary) -> void:
        var p: Vector2 = b["pos"]
        var dir: float = b["dir"]
        var t := _time * 9.0 + float(b["phase"])
        var fwd := Vector2.from_angle(dir)
        var side := Vector2(-fwd.y, fwd.x)
        # legs (3 per side, scuttling)
        for sg in [-1.0, 1.0]:
                for i in 3:
                        var base: Vector2 = p + fwd * (10.0 - 9.0 * float(i)) \
                                        + side * 8.0 * float(sg)
                        var kick := sin(t + float(i) * 2.1 + (0.0 if float(sg) > 0 else PI)) * 5.0
                        var tip: Vector2 = base + side * 9.0 * float(sg) + fwd * kick
                        v.draw_line(base, tip, BUG_SHELL, 3.0, true)
        # body + head
        v.draw_circle(p + fwd * 12.0, 9.0, BUG_SHELL)
        var pts := PackedVector2Array()
        for i in 16:
                var a := TAU * float(i) / 16.0
                pts.append(p + fwd * cos(a) * 14.0 + side * sin(a) * 11.0)
        v.draw_colored_polygon(pts, BUG_BODY)
        var mid := PackedVector2Array([p - fwd * 14.0, p + fwd * 14.0])
        v.draw_polyline(mid, BUG_SHELL, 2.5, true)
        # eyes on the head
        for sg in [-1.0, 1.0]:
                v.draw_circle(p + fwd * 17.0 + side * 4.5 * sg, 2.2,
                                Color("fdfaf2"))
        # antennae
        for sg in [-1.0, 1.0]:
                var a0 := p + fwd * 18.0
                v.draw_line(a0, a0 + fwd.rotated(0.5 * sg) * 10.0, BUG_SHELL, 2.0, true)

func _rounded_rect(rc: Rect2, rad: float) -> PackedVector2Array:
        var r := minf(rad, minf(rc.size.x, rc.size.y) / 2.0 - 2.0)
        var pts := PackedVector2Array()
        var corners := [
                [Vector2(rc.end.x - r, rc.position.y + r), 0.0],
                [Vector2(rc.end.x - r, rc.end.y - r), PI / 2.0],
                [Vector2(rc.position.x + r, rc.end.y - r), PI],
                [Vector2(rc.position.x + r, rc.position.y + r), PI * 1.5],
        ]
        for cinfo in corners:
                var center: Vector2 = cinfo[0]
                var a0: float = cinfo[1]
                for i in 9:
                        var a := a0 + (PI / 2.0) * float(i) / 8.0
                        pts.append(center + Vector2.from_angle(a) * r)
        pts.append(pts[0])
        return pts

# ------------------------------------------------------------- HUD chips
## Under the top bar: LEFT = the player's active powers (glyph + shrinking
## timer bar in the aura color), RIGHT = enemy score chips in their colors
## (dead ones gray out - "killed, and it stays dead").

func _build_chips() -> void:
        _chips = Control.new()
        _chips.set_anchors_preset(Control.PRESET_TOP_WIDE)
        _chips.offset_top = 84
        _chips.offset_bottom = 148
        _chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _chips.draw.connect(func(): _paint_chips(_chips))
        _hud.add_child(_chips)

func _paint_chips(c: Control) -> void:
        if _phase != "run" or player == null:
                return
        var f := Arc.font_ui()
        var x := 16.0
        # active powers, oldest activation first
        for id in player.effects:
                var p: Dictionary = SnakeFruits.POWERS.get(id, {})
                if p.is_empty():
                        continue
                var w := 96.0
                var rect := Rect2(x, 2, w, 40)
                c.draw_rect(rect, Color(0.16, 0.10, 0.05, 0.75))
                var aura: Color = p["aura"]
                c.draw_rect(rect, aura, false, 2.5)
                # remaining-time bar along the bottom edge
                var frac := clampf(float(player.effects[id]) / float(p["dur"]), 0.0, 1.0)
                c.draw_rect(Rect2(rect.position.x + 2, rect.end.y - 5,
                                (w - 4) * frac, 3.5), aura)
                _paint_glyph(c, id, rect.position + Vector2(18, 20), aura)
                c.draw_string(f, rect.position + Vector2(34, 26),
                                String(p["name"]), HORIZONTAL_ALIGNMENT_LEFT,
                                w - 36, 14, Color(1, 1, 1, 0.9))
                x += w + 8
        # enemy score chips, right-aligned
        var xr := c.get_viewport_rect().size.x - 16.0
        for i in range(enemies.size() - 1, -1, -1):
                var e: Dictionary = enemies[i]
                var b: SnakeBody = e["body"]
                var w := 84.0
                xr -= w
                var rect := Rect2(xr, 2, w, 40)
                var col: Color = b.pal["pri"]
                var alive: bool = b.alive
                c.draw_rect(rect, Color(0.16, 0.10, 0.05, 0.55 if alive else 0.3))
                c.draw_rect(rect, col * Color(1, 1, 1, 1.0 if alive else 0.4),
                                false, 2.5)
                c.draw_circle(rect.position + Vector2(16, 20), 7.0,
                                col * Color(1, 1, 1, 1.0 if alive else 0.35))
                c.draw_string(f, rect.position + Vector2(30, 27),
                                str(e["score"]), HORIZONTAL_ALIGNMENT_LEFT,
                                w - 32, 18,
                                Color(1, 1, 1, 0.92 if alive else 0.4))

## tiny vector glyphs for the power chips
func _paint_glyph(c: Control, id: String, at: Vector2, col: Color) -> void:
        match id:
                "slower":   # hourglass
                        c.draw_colored_polygon(PackedVector2Array([
                                        at + Vector2(-6, -7), at + Vector2(6, -7),
                                        at + Vector2(0, 0)]), col)
                        c.draw_colored_polygon(PackedVector2Array([
                                        at + Vector2(-6, 7), at + Vector2(6, 7),
                                        at + Vector2(0, 0)]), col)
                "faster":   # double chevron
                        for k in 2:
                                var ox := -4.0 + 7.0 * k
                                c.draw_polyline(PackedVector2Array([
                                                at + Vector2(ox - 2, -6), at + Vector2(ox + 3, 0),
                                                at + Vector2(ox - 2, 6)]), col, 2.6, true)
                "ghost":    # little dome ghost
                        var pts := PackedVector2Array()
                        for i in 10:
                                var a := PI + PI * float(i) / 9.0
                                pts.append(at + Vector2(cos(a), sin(a)) * 7.0)
                        for i in 3:
                                pts.append(at + Vector2(7.0 - 7.0 * float(i), 7.0)
                                                + Vector2(0, 0))
                        c.draw_polyline(pts, col, 2.4, true)
                "magnet":   # U magnet
                        c.draw_arc(at + Vector2(0, 2), 6.0, PI, TAU, 14, col, 3.2, true)
                        c.draw_line(at + Vector2(-6, 2), at + Vector2(-6, -4), col, 3.2)
                        c.draw_line(at + Vector2(6, 2), at + Vector2(6, -4), col, 3.2)
                "golden":   # 4-point star
                        c.draw_colored_polygon(PackedVector2Array([
                                        at + Vector2(0, -8), at + Vector2(2.4, -2.4),
                                        at + Vector2(8, 0), at + Vector2(2.4, 2.4),
                                        at + Vector2(0, 8), at + Vector2(-2.4, 2.4),
                                        at + Vector2(-8, 0), at + Vector2(-2.4, -2.4)]), col)
                "wither":   # down arrow through a fruit dot
                        c.draw_circle(at + Vector2(0, -3), 4.0, col)
                        c.draw_line(at + Vector2(0, 2), at + Vector2(0, 8), col, 2.6)
                        c.draw_polyline(PackedVector2Array([
                                        at + Vector2(-3, 5), at + Vector2(0, 8),
                                        at + Vector2(3, 5)]), col, 2.2, true)
                "eater":    # two fangs
                        c.draw_colored_polygon(PackedVector2Array([
                                        at + Vector2(-6, -7), at + Vector2(-1, -7),
                                        at + Vector2(-3.5, 4)]), col)
                        c.draw_colored_polygon(PackedVector2Array([
                                        at + Vector2(1, -7), at + Vector2(6, -7),
                                        at + Vector2(3.5, 4)]), col)

# ================================================================== SHOP
## Scrollable, labeled sections in the owner's order: SKINS / FRUITS /
## POWER-UPS / BUGS / OBSTACLES / ENEMIES. EVERY price wears the GOGACoin
## icon (AGENTS.md price rule); unaffordable = grayed out AND dead.

func _shop_open() -> void:
        if paused:
                return
        get_tree().paused = true
        paused = true
        _shop_rebuild()

func _shop_rebuild() -> void:
        # drop any previous sheet (the toast layer stays)
        for k in _overlay_root_ref().get_children():
                if k != _toast_ref()["layer"]:
                        k.queue_free()
        var sheet := Arc.sheet(_overlay_root_ref(), 0.0)
        sheet.get_parent().get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
        var t := Arc.label("SNAKE SHOP", 40, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)

        # ---- SKINS ----
        sheet.add_child(_section_label("SKINS"))
        for entry in [
                {"id": "classic", "name": "Blue Melt", "price": 0},
                {"id": "lava", "name": "Lava", "price": 120},
                {"id": "ice", "name": "Ice", "price": 120},
                {"id": "gold", "name": "Gold", "price": 300},
        ]:
                var owned: bool = Box.skin_owned(game_id, String(entry["id"])) \
                                or int(entry["price"]) == 0
                var on: bool = Box.skin_on(game_id) == String(entry["id"]) \
                                or (int(entry["price"]) == 0 and Box.skin_on(game_id) == "")
                var txt := String(entry["name"])
                var col: Color = (_pal["pri"] as Color) if entry["id"] == "classic" \
                                else Color("d05a30") if entry["id"] == "lava" \
                                else Color("4aa8d8") if entry["id"] == "ice" else Color("d8b020")
                if on:
                        txt += "  (ON)"
                elif owned:
                        txt += "  - EQUIP"
                var b: Button
                if owned:
                        b = Arc.button(txt, Vector2(500, 66), 22, col,
                                        func(): _buy_skin_action(String(entry["id"])))
                else:
                        b = Arc.coin_button(txt + "  %d" % int(entry["price"]),
                                        Vector2(500, 66), 22, col,
                                        func(): _buy_skin_action(String(entry["id"])))
                        _gray_if_broke(b, int(entry["price"]))
                sheet.add_child(b)

        # ---- FRUITS ----
        sheet.add_child(_section_label("FRUITS - your edible wardrobe"))
        for id in SnakeFruits.FRUITS:
                var f: Dictionary = SnakeFruits.FRUITS[id]
                var price := int(f["price"])
                var owned2: bool = price == 0 or Box.item_owned(game_id, "fruit", id)
                var b: Button
                if owned2:
                        b = Arc.button("%s  - OWNED" % String(f["name"]).to_upper(),
                                        Vector2(500, 62), 20, SnakeFruits.fruit_body(id).darkened(0.1))
                        b.disabled = true
                else:
                        b = Arc.coin_button("%s  %d" % [String(f["name"]).to_upper(), price],
                                        Vector2(500, 62), 20, SnakeFruits.fruit_body(id).darkened(0.1),
                                        func(): _buy_item_action("fruit", id, price))
                        _gray_if_broke(b, price)
                sheet.add_child(b)

        # ---- POWER-UPS ----
        sheet.add_child(_section_label("POWER-UPS - aura fruits"))
        sheet.add_child(_unlock_row("POWER FRUITS",
                        "slower / faster / ghost / magnet / golden / wither",
                        "powerups", PRICE_POWERUPS))

        # ---- BUGS ----
        sheet.add_child(_section_label("BUGS - they bite, never kill"))
        sheet.add_child(_unlock_row("BUGS", "two beetles roam and steal fruit",
                        "bugs", PRICE_BUGS))

        # ---- OBSTACLES ----
        sheet.add_child(_section_label("OBSTACLES - deadly for everyone"))
        sheet.add_child(_unlock_row("OBSTACLES", "three block clusters per round",
                        "obstacles", PRICE_OBSTACLES))

        # ---- ENEMIES ----
        sheet.add_child(_section_label("ENEMIES - the pack"))
        var pack_owned := Box.unlock_owned(game_id, "pack")
        if pack_owned:
                var info := Arc.fit_label("OWNED - up to 10 snakes, each its own color. Pick the count from the ENEMY box in the optionals.",
                                20, Color("6a4a28"), 540, false)
                info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                info.custom_minimum_size = Vector2(540, 0)
                sheet.add_child(info)
                var ebtn := Arc.button("UNLOCKS SNAKE-EATER", Vector2(500, 62), 20,
                                Color("e8402f"))
                ebtn.disabled = true
                sheet.add_child(ebtn)
        else:
                var eb := Arc.coin_button("ENEMY PACK x10  %d" % PRICE_ENEMIES,
                                Vector2(500, 66), 22, Color("3fae5c"),
                                func(): _buy_pack_action())
                _gray_if_broke(eb, PRICE_ENEMIES)
                sheet.add_child(eb)

        sheet.add_child(Arc.button("CLOSE", Vector2(500, 70), 24, Arc.ACCENT, func():
                        _shop_close()))
        # THE scrollable sheet: overflow wraps into a BoxScroll, CLOSE pinned
        Arc.fit_sheet(sheet, 1)

func _section_label(txt: String) -> Label:
        # v0.1.5 lesson: Kenney Rocket runs WIDE - long section names blew the
        # sheet's min width up and shifted/ clipped the whole shop (seen in
        # the visual QA pass). fit or die.
        return Arc.fit_label(txt, 26, Arc.HOT, 540)

## THE RULE, enforced at the source: a price the wallet cannot pay is a
## GRAY, DEAD button (never a "buy" that just errors).
func _gray_if_broke(b: Button, price: int) -> void:
        if Box.coins() < price:
                b.disabled = true

func _unlock_row(name_: String, sub: String, cat: String, price: int) -> Control:
        if Box.unlock_owned(game_id, cat):
                var row2 := VBoxContainer.new()
                var l := Arc.fit_label("%s  - OWNED (toggle it in the optionals)" % name_,
                                20, Color("58c470"), 540)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                row2.add_child(l)
                var s2 := Arc.fit_label(sub, 16, Color("8a6a40"), 540, false)
                s2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                row2.add_child(s2)
                return row2
        var v := VBoxContainer.new()
        var b := Arc.coin_button("%s  %d" % [name_, price], Vector2(500, 66), 22,
                        Color("6a5ab8"), func(): _buy_unlock_action(cat, name_, price))
        _gray_if_broke(b, price)
        v.add_child(b)
        var s := Arc.fit_label(sub, 16, Color("8a6a40"), 540, false)
        s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        v.add_child(s)
        return v

func _shop_action_common() -> void:
        _shop_rebuild()

func _buy_skin_action(id: String) -> void:
        if Box.skin_owned(game_id, id):
                Box.equip_skin(game_id, id)
                Jukebox.sfx("confirm", -4.0)
        else:
                var price := 0
                for e in [{"id": "classic", "p": 0}, {"id": "lava", "p": 120},
                                {"id": "ice", "p": 120}, {"id": "gold", "p": 300}]:
                        if e["id"] == id:
                                price = int(e["p"])
                if Box.coins() < price:
                        Jukebox.sfx("error", -4.0)
                        return
                if Box.buy_skin(game_id, id, price):
                        Jukebox.sfx("buy")
                _load_skin()
        _shop_action_common()

func _buy_item_action(cat: String, id: String, price: int) -> void:
        if Box.coins() < price:
                Jukebox.sfx("error", -4.0)
                return
        if Box.buy_item(game_id, cat, id, price):
                Jukebox.sfx("buy")
        _shop_action_common()

func _buy_unlock_action(cat: String, name_: String, price: int) -> void:
        if Box.coins() < price:
                Jukebox.sfx("error", -4.0)
                return
        if Box.buy_unlock(game_id, cat, price):
                Jukebox.sfx("buy")
                _toast_show("%s UNLOCKED - find it in the optionals!" % name_)
        _shop_action_common()

func _buy_pack_action() -> void:
        if Box.coins() < PRICE_ENEMIES:
                Jukebox.sfx("error", -4.0)
                return
        if Box.buy_unlock(game_id, "pack", PRICE_ENEMIES):
                Jukebox.sfx("buy")
                _toast_show("THE PACK! 10 colors - SNAKE-EATER power unlocked!")
        _shop_action_common()

func _shop_close() -> void:
        get_tree().paused = false
        paused = false
        for k in _overlay_root_ref().get_children():
                if k != _toast_ref()["layer"]:
                        k.queue_free()
        _load_skin()
        if _phase != "run":
                _new_run_objects()
        _view.queue_redraw()


