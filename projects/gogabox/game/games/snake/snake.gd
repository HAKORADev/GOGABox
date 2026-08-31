extends GogaGame
## Snake v0.1.8 - THE SMOOTH MAKEOVER. The grid is dead: the head owns a
## heading, the body is its trail, and steering bends the whole snake like
## silk. Hold the LEFT/RIGHT half of the screen to steer. Apples add length
## and a little width (capped), and the body color MELTS from blue into milk
## along a gradient that stretches as the snake grows. Full-screen field,
## portrait AND landscape - the mode is chosen once, when the game loads.
## Own SFX + its own music loop; death flashes ONLY the snake.

# ---------------------------------------------------------- palette (feel)
const FIELD := Color("f6e7cd")          # warm cream field (the reference vibe)
const FIELD_DECO := Color("ecd9b4")     # soft deco blobs on the field
const WALL := Color("d9c39a")           # rounded wall line (deadly edge)
const APPLE_RED := Color("e8574a")
const APPLE_LEAF := Color("58c470")
const APPLE_STEM := Color("8a5a14")
const TONGUE_RED := Color("e8402f")
const EYE_WHITE := Color("fdfaf2")
const EYE_INK := Color("35210f")
const FLASH_RED := Color("e8402f")
# skins survive as palettes over ONE gradient system: primary (head) ->
# milk (tail). classic is the owner's blue-melt design.
const PALETTES := {
        "classic": {"pri": Color("3f7fd4"), "milk": Color("faf3e3")},
        "lava": {"pri": Color("e8632a"), "milk": Color("ffe9c9")},
        "ice": {"pri": Color("57b8e8"), "milk": Color("f0f8fd")},
        "gold": {"pri": Color("e8b23a"), "milk": Color("fdf3d8")},
}

# --------------------------------------------------------------- tuning
const TURN_RATE := 4.6          # rad/s while holding a half
const START_SPEED := 430.0      # design px/s
const SPEED_PER_APPLE := 6.0
const SPEED_MAX := 880.0
const START_LEN := 320.0        # trail length in px
const LEN_PER_APPLE := 70.0
const WIDTH_START := 26.0       # body thickness (head is a bit fatter)
const WIDTH_PER_APPLE := 1.6
const WIDTH_MAX := 64.0         # owner: "wide with a limit"
const SAMPLE_STEP := 11.0        # body circle spacing (tight = silky)
const GRAD_FACTOR := 0.96        # the transition IS the body: head blue ->
                                 # tail milk, and it STRETCHES as you grow
const GRAD_MIN := 300.0
const GRAD_MAX := 2400.0
const SELF_SKIP := 2.2          # x width: neck arc ignored for self-bites

# --------------------------------------------------------------- state
var board := Rect2(0, 0, 100, 100)   # the deadly field, built at load
var banner_on := false
var head_pos := Vector2.ZERO
var head_dir := 0.0                  # radians
var speed := START_SPEED
var length_px := START_LEN
var len_target := START_LEN
var width := WIDTH_START
var trail: Array[Vector2] = []       # [oldest ... newest=head]
var apple_pos := Vector2.ZERO
var apple_r := 26.0
var apple_pop := 0.0                 # 0->1 pop-in (scale), no alpha fades
var coin_pos := Vector2(-100, -100)
var coin_pop := 0.0
var coin_rot := 0.0
var _coin_tex: Texture2D
var _eaten := 0
var alive := true
var _started := false
var _time := 0.0
var _flash_red := 0.0                # death blink - ONLY the snake turns red
var _pal: Dictionary = PALETTES["classic"]
var _motes: Array = []               # {p, v, r, c, life, max}
var _rings: Array = []               # {p, r0, r1, life, max, col}
var _apple_tween: Tween
var _coin_tween: Tween
var _tongue_cd := 1.6
var _tongue_t := 0.0
var _deco: Array = []                # precomputed drifting blobs
var _ready_card: Control
var _view: Node2D

# snake draws itself + the field through one view node
class SnakeView:
        extends Node2D
        var g: Node2D

        func _draw() -> void:
                g._paint(self)

func _goga_setup() -> void:
        banner_on = bool(GameReg.get_game(game_id).get("banner", false))
        _load_skin()
        _build_field()
        _view = SnakeView.new()
        _view.g = self
        add_child(_view)
        _new_snake()
        _spawn_apple(true)
        _maybe_coin()
        _coin_tex = load("res://assets/ui/coin.png")
        add_hud_button("SHOP", func(): _shop_open())
        Jukebox.music("res://assets/audio/music/snake_theme.wav")
        _show_ready_card()

# ------------------------------------------------------------- the field

func _build_field() -> void:
        var vp := get_viewport_rect().size
        var top := 96.0
        var bottom := 14.0
        if banner_on:
                bottom = _banner_safe_px()
        board = Rect2(14, top, maxf(100.0, vp.x - 28.0),
                        maxf(100.0, vp.y - top - bottom - 6.0))
        # drifting deco blobs, positions as fractions of the board
        _deco.clear()
        var rng := RandomNumberGenerator.new()
        rng.seed = 7
        for i in 6:
                _deco.append({
                        "fx": rng.randf_range(0.08, 0.92),
                        "fy": rng.randf_range(0.08, 0.92),
                        "r": rng.randf_range(20.0, 52.0),
                        "ph": rng.randf_range(0.0, TAU),
                        "amp": rng.randf_range(8.0, 24.0),
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

# ------------------------------------------------------- ready / start

func _show_ready_card() -> void:
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

## Card pop around its own center: the pivot follows the laid-out size.
func _card_step(s: float, cc: Control) -> void:
        if not is_instance_valid(cc):
                return
        cc.pivot_offset = cc.size / 2.0
        cc.scale = Vector2(s, s)

func _start() -> void:
        if _started or not alive:
                return
        _started = true
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

func _goga_input(event: InputEvent) -> void:
        # first press anywhere starts the run (HUD buttons consume their own taps)
        if not _started and alive and event is InputEventScreenTouch \
                        and (event as InputEventScreenTouch).pressed:
                _start()

# ------------------------------------------------------------- the snake

func _new_snake() -> void:
        head_pos = board.get_center()
        head_dir = 0.0                 # heading right
        speed = START_SPEED
        length_px = START_LEN
        len_target = START_LEN
        width = WIDTH_START
        trail.clear()
        # prefill a straight tail BEHIND the head (oldest first)
        var back := Vector2.LEFT
        var n := int(START_LEN / SAMPLE_STEP)
        for i in range(n, 0, -1):
                trail.append(head_pos + back * (SAMPLE_STEP * float(i)))
        trail.append(head_pos)

func _goga_tick(delta: float) -> void:
        _time += delta
        _tick_fx(delta)
        # the body eases toward its target length (apples grow it smoothly)
        length_px = move_toward(length_px, len_target, 90.0 * delta)
        if alive and _started:
                _steer_and_move(delta)
                _check_bites()
        if alive:
                _tick_tongue(delta)
        if _view != null and is_instance_valid(_view):
                _view.queue_redraw()

func _steer_and_move(delta: float) -> void:
        var turn := 0.0
        if tk.is_down():
                var mid := get_viewport_rect().size.x / 2.0
                turn = -1.0 if tk.press_pos().x < mid else 1.0
        head_dir += turn * TURN_RATE * delta
        head_pos += Vector2.from_angle(head_dir) * speed * delta
        trail.append(head_pos)
        _trim_trail()

func _trim_trail() -> void:
        var keep := length_px + 80.0
        var acc := 0.0
        var cut := 0
        for i in range(trail.size() - 1, 0, -1):
                acc += trail[i].distance_to(trail[i - 1])
                if acc > keep:
                        cut = i
                        break
        if cut > 0:
                for i in cut:
                        trail.pop_front()

## Walk the trail from the head backward, at fixed arc steps. Yields
## [position, dist-from-head] pairs - the body IS the path.
func _body_points() -> Array:
        var out: Array = []
        var acc := 0.0
        var next_at := 0.0
        var head: Vector2 = trail[trail.size() - 1]
        out.append([head, 0.0])
        for i in range(trail.size() - 1, 0, -1):
                var a: Vector2 = trail[i]
                var b: Vector2 = trail[i - 1]
                var seg := a.distance_to(b)
                while acc + seg >= next_at and next_at <= length_px:
                        var t := (next_at - acc) / maxf(seg, 0.001)
                        out.append([a.lerp(b, t), next_at])
                        next_at += SAMPLE_STEP
                acc += seg
                if next_at > length_px:
                        break
        return out

func _half_width(d: float) -> float:
        # d = arc distance from the head; taper toward the tail tip
        var t := clampf(d / maxf(length_px, 1.0), 0.0, 1.0)
        var r := width * 0.5 * (1.0 - 0.42 * t)
        if t > 0.82:
                r *= 1.0 - 0.55 * (t - 0.82) / 0.18   # fine tail tip
        return maxf(3.0, r)

func _grad_len() -> float:
        # THE owner design: the transition runs the whole body (blue head ->
        # milk tail) and the longer the snake gets, the LONGER the transition
        # stretches along it.
        return clampf(length_px * GRAD_FACTOR, GRAD_MIN, GRAD_MAX)

func _body_color(d: float) -> Color:
        var t := clampf(d / _grad_len(), 0.0, 1.0)
        var c: Color = (_pal["pri"] as Color).lerp(_pal["milk"] as Color, t)
        if _flash_red > 0.0:
                c = c.lerp(FLASH_RED, _flash_red)
        return c

# ------------------------------------------------------------- collisions

func _check_bites() -> void:
        var hr := width * 0.5 * 1.22
        # walls (a little forgiving)
        if head_pos.x - hr * 0.7 < board.position.x \
                        or head_pos.x + hr * 0.7 > board.end.x \
                        or head_pos.y - hr * 0.7 < board.position.y \
                        or head_pos.y + hr * 0.7 > board.end.y:
                _die()
                return
        # apple / coin
        if apple_pop > 0.5 and head_pos.distance_to(apple_pos) < hr + apple_r * 0.8:
                _eat_apple()
        if head_pos.distance_to(coin_pos) < hr + 24.0 and coin_pop > 0.5:
                _take_coin()
        # self bite: walk the trail, ignore the neck arc
        var skip := width * SELF_SKIP + 10.0
        var acc := 0.0
        var step := 0.0
        for i in range(trail.size() - 1, 0, -1):
                var seg := trail[i].distance_to(trail[i - 1])
                while step <= acc + seg:
                        var t := (step - acc) / maxf(seg, 0.001)
                        var p: Vector2 = trail[i].lerp(trail[i - 1], t)
                        if step > skip:
                                var br := _half_width(step)
                                if head_pos.distance_to(p) < (hr + br) * 0.58:
                                        _die()
                                        return
                        step += SAMPLE_STEP * 0.75
                acc += seg
                if step > length_px:
                        break

# ------------------------------------------------------------- the apple

func _spawn_apple(first := false) -> void:
        var m := apple_r + 20.0
        var best := Vector2.ZERO
        var best_d := -1.0
        for i in 60:
                var p := Vector2(randf_range(board.position.x + m, board.end.x - m),
                                randf_range(board.position.y + m, board.end.y - m))
                var dh := p.distance_to(head_pos)
                if dh < 170.0:
                        continue
                if not first and _near_trail(p, 30.0):
                        continue
                if dh > best_d:
                        best_d = dh
                        best = p
                if best_d > 420.0:
                        break
        apple_pos = best
        apple_r = clampf(width * 0.85, 22.0, 42.0)
        apple_pop = 0.0
        if _apple_tween != null and _apple_tween.is_valid():
                _apple_tween.kill()
        _apple_tween = create_tween()
        _apple_tween.tween_property(self, "apple_pop", 1.0, 0.24) \
                        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        _ring(apple_pos, APPLE_RED)

func _near_trail(p: Vector2, r: float) -> bool:
        var step := 0.0
        var acc := 0.0
        for i in range(trail.size() - 1, 0, -1):
                var seg := trail[i].distance_to(trail[i - 1])
                while step <= acc + seg:
                        var t := (step - acc) / maxf(seg, 0.001)
                        if trail[i].lerp(trail[i - 1], t).distance_to(p) < r:
                                return true
                        step += SAMPLE_STEP * 2.0
                acc += seg
                if step > length_px + 40.0:
                        break
        return false

func _eat_apple() -> void:
        _eaten += 1
        set_score(score + 1)   # owner rule: each apple = 1 score point
        len_target += LEN_PER_APPLE
        width = minf(width + WIDTH_PER_APPLE, WIDTH_MAX)   # wide with a limit
        speed = minf(speed + SPEED_PER_APPLE, SPEED_MAX)
        Jukebox.sfx("snake_eat", -4.0, 1.0 + 0.016 * mini(24, _eaten))
        _burst(apple_pos, [APPLE_RED, _pal["milk"], _pal["pri"]], 11)
        _ring(apple_pos, APPLE_RED)
        _spawn_apple()
        _maybe_coin()

# --------------------------------------------------------------- the coin

func _maybe_coin() -> void:
        if coin_pop > 0.0:
                return
        if randf() < 0.45:
                var m := 40.0
                for i in 40:
                        var p := Vector2(randf_range(board.position.x + m, board.end.x - m),
                                        randf_range(board.position.y + m, board.end.y - m))
                        if p.distance_to(head_pos) > 200.0 and not _near_trail(p, 30.0) \
                                        and p.distance_to(apple_pos) > 60.0:
                                coin_pos = p
                                coin_pop = 0.0
                                if _coin_tween != null and _coin_tween.is_valid():
                                        _coin_tween.kill()
                                _coin_tween = create_tween()
                                _coin_tween.tween_property(self, "coin_pop", 1.0, 0.22) \
                                                .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                                return

func _take_coin() -> void:
        add_run_coins(1)   # owner rule: one pickup = ONE GOGACoin
        achievement_count("coins_taken", 1)
        achievement_max("coins_got", run_coins)
        Jukebox.sfx("coin", -4.0)
        _burst(coin_pos, [Arc.COIN, Color("fff3dc")], 9)
        _ring(coin_pos, Arc.COIN)
        coin_pop = 0.0
        coin_pos = Vector2(-100, -100)
        _maybe_coin()

# ----------------------------------------------------------------- tongue

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
        # leans out when an apple is close ahead
        if alive and apple_pop > 0.5:
                var to_a := apple_pos - head_pos
                if to_a.length() < width * 3.4 \
                                and absf(head_dir - to_a.angle()) < 1.1:
                        out = maxf(out, 0.6)
        return out

# ----------------------------------------------------------------- death

func _die() -> void:
        if not alive:
                return
        alive = false
        Jukebox.sfx("snake_die", -2.0)
        Jukebox.stop_music()   # the run's music dies with the run
        achievement_max("length", 3 + _eaten)
        check_achievements()
        _burst(head_pos, [_pal["pri"], FLASH_RED, Color("fff3dc")], 12)
        _ring(head_pos, FLASH_RED)
        # OWNER FIX: flash ONLY the snake - the old code tinted the whole world.
        var tw := create_tween().set_loops(3)
        tw.tween_property(self, "_flash_red", 1.0, 0.09)
        tw.tween_property(self, "_flash_red", 0.0, 0.09)
        tw.finished.connect(func(): finish_run(score))

# -------------------------------------------------------------------- fx

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

# ------------------------------------------------------------------ shop

func _shop_open() -> void:
        if paused:
                return
        get_tree().paused = true
        paused = true
        var sheet := Arc.sheet(_overlay_root_ref(), 0.0)
        sheet.get_parent().get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
        var t := Arc.label("SNAKE SKINS", 40, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        for entry in [
                {"id": "classic", "name": "Blue Melt", "price": 0},
                {"id": "lava", "name": "Lava", "price": 120},
                {"id": "ice", "name": "Ice", "price": 120},
                {"id": "gold", "name": "Gold", "price": 300},
        ]:
                var owned: bool = Box.skin_owned("snake", String(entry["id"])) \
                                or int(entry["price"]) == 0
                var on: bool = Box.skin_on("snake") == String(entry["id"]) \
                                or (int(entry["price"]) == 0 and Box.skin_on("snake") == "")
                var txt := String(entry["name"])
                if on:
                        txt += "  (on)"
                elif owned:
                        txt += "  (equip)"
                else:
                        txt += "  %d" % int(entry["price"])
                var col: Color = (_pal["pri"] as Color) if entry["id"] == "classic" \
                                else Color("d05a30") if entry["id"] == "lava" \
                                else Color("4aa8d8") if entry["id"] == "ice" else Color("d8b020")
                sheet.add_child(Arc.button(txt, Vector2(460, 66), 22, col, func():
                                _shop_action(String(entry["id"]), int(entry["price"]))))
        sheet.add_child(Arc.button("CLOSE", Vector2(460, 66), 24, Arc.ACCENT, func():
                        get_tree().paused = false
                        paused = false
                        # remove only the sheet (last 2 overlay children), keep the toast
                        var kids := _overlay_root_ref().get_children()
                        for i in range(maxi(0, kids.size() - 2), kids.size()):
                                kids[i].queue_free()))

func _shop_action(id: String, price: int) -> void:
        if Box.skin_owned("snake", id):
                Box.equip_skin("snake", id)
                Jukebox.sfx("confirm", -4.0)
        else:
                if Box.buy_skin("snake", id, price):
                        Jukebox.sfx("buy")
                else:
                        Jukebox.sfx("error", -4.0)
        var kids := _overlay_root_ref().get_children()
        for i in range(maxi(0, kids.size() - 2), kids.size()):
                kids[i].queue_free()
        get_tree().paused = false
        paused = false
        _load_skin()

# ================================================================== PAINT
## Everything the player sees, in one draw pass: field, deco, walls, rings,
## apple, coin, then the snake (tail first so the head rides on top).

func _paint(v: Node2D) -> void:
        var vp := get_viewport_rect().size
        # field
        v.draw_rect(Rect2(Vector2.ZERO, vp), FIELD)
        # drifting deco blobs (super subtle, alive)
        for d in _deco:
                var p := Vector2(
                                board.position.x + float(d["fx"]) * board.size.x
                                                + sin(_time * 0.22 + float(d["ph"])) * float(d["amp"]),
                                board.position.y + float(d["fy"]) * board.size.y
                                                + cos(_time * 0.18 + float(d["ph"]) * 1.7)
                                                * float(d["amp"]))
                v.draw_circle(p, float(d["r"]), Color(FIELD_DECO, 0.38))
        # walls (rounded)
        v.draw_polyline(_rounded_rect(board, 26.0), WALL, 5.0, true)
        # rings
        for r in _rings:
                var t := 1.0 - float(r["life"]) / float(r["max"])
                var col: Color = r["col"]
                col.a = 0.55 * (1.0 - t)
                v.draw_arc(r["p"], lerpf(float(r["r0"]), float(r["r1"]), t), 0, TAU,
                                40, col, 4.0, true)
        # coin (under the snake)
        if coin_pop > 0.0 and _coin_tex != null:
                var cpop := (1.0 + 0.08 * sin(_time * 4.2)) * coin_pop
                var cs := 54.0 / float(_coin_tex.get_width())
                v.draw_set_transform(coin_pos, coin_rot,
                                Vector2(cs * cpop, cs / cpop * coin_pop))
                v.draw_texture(_coin_tex, -_coin_tex.get_size() / 2.0)
                v.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        # apple (pop + breathing - never an alpha fade)
        if apple_pop > 0.0:
                _paint_apple(v)
        # the snake
        var pts := _body_points()
        for i in range(pts.size() - 1, -1, -1):
                var p: Vector2 = pts[i][0]
                var d: float = pts[i][1]
                var r := _half_width(d)
                var c := _body_color(d)
                v.draw_circle(p, r + 2.0, c.darkened(0.24))   # soft rim
                v.draw_circle(p, r, c)
        _paint_head(v)
        # motes on top
        for m in _motes:
                var a := clampf(float(m["life"]) / float(m["max"]), 0.0, 1.0)
                var col: Color = m["c"]
                col.a = a
                v.draw_circle(m["p"], float(m["r"]) * (0.5 + 0.5 * a), col)

func _paint_apple(v: Node2D) -> void:
        var pop := apple_pop * (1.0 + 0.045 * sin(_time * 3.2))
        var r := apple_r * pop
        var rim := APPLE_RED.darkened(0.3)
        v.draw_circle(apple_pos, r + 2.6, rim)
        v.draw_circle(apple_pos, r, APPLE_RED)
        v.draw_circle(apple_pos + Vector2(-r * 0.34, -r * 0.36), r * 0.22,
                        Color(1, 1, 1, 0.75))
        # stem + leaf
        var top := apple_pos + Vector2(0, -r * 0.95)
        v.draw_line(top, top + Vector2(2, -r * 0.3), APPLE_STEM, 4.0, true)
        var leaf_c := top + Vector2(r * 0.42, -r * 0.42)
        var pts := PackedVector2Array()
        for i in 14:
                var a := TAU * float(i) / 14.0
                pts.append(leaf_c + Vector2(cos(a) * r * 0.34, sin(a) * r * 0.2))
        v.draw_colored_polygon(pts, APPLE_LEAF)

func _paint_head(v: Node2D) -> void:
        var hr := width * 0.5 * 1.22
        var c := _body_color(0.0)
        var fwd := Vector2.from_angle(head_dir)
        var side := Vector2.from_angle(head_dir + PI / 2.0)
        # tongue BEHIND the head so its root hides under the face
        var tout := _tongue_out()
        if tout > 0.02:
                var base := head_pos + fwd * hr * 0.85
                var tip := base + fwd * hr * 1.5 * tout
                var fork := side * hr * 0.42 * tout
                v.draw_line(base, tip, TONGUE_RED, 3.4, true)
                v.draw_line(tip, tip + (fwd * 0.45 + fork).normalized() * hr * 0.5
                                * tout, TONGUE_RED, 3.0, true)
                v.draw_line(tip, tip + (fwd * 0.45 - fork).normalized() * hr * 0.5
                                * tout, TONGUE_RED, 3.0, true)
        # head disc
        v.draw_circle(head_pos, hr + 2.6, c.darkened(0.24))
        v.draw_circle(head_pos, hr, c)
        # eyes
        for s in [-1.0, 1.0]:
                var e: Vector2 = head_pos + fwd * hr * 0.34 + side * hr * 0.52 * s
                v.draw_circle(e, hr * 0.33, EYE_WHITE)
                if alive:
                        v.draw_circle(e + fwd * hr * 0.10, hr * 0.16, EYE_INK)
                else:
                        # x eyes - the run is over
                        var k := hr * 0.13
                        for q in [Vector2(k, k), Vector2(k, -k)]:
                                v.draw_line(e - q, e + q, EYE_INK, 3.0, true)

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
