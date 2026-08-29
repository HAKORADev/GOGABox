extends GogaGame
## Snake — the classic, arcade edition. Swipe to steer, eat apples, grab
## GOGACoins on the grid. Speed ramps with score. Skins shop (GOGACoins).

const CELL := 44
const COLS := 16
const ROWS := 24
var ORIGIN := Vector2(8, 96)   # re-centered per device in _build_board()

var world: Node2D
var snake: Array[Vector2i] = []
var dir := Vector2i(0, 1)
var next_dir := Vector2i(0, 1)
var tick := 0.0
var step_time := 0.16
var food := Vector2i(-1, -1)
var coin_pos := Vector2i(-1, -1)
var grow := 0
var alive := true

var _food_tex: Texture2D
var _coin_tex: Texture2D
var _body_tex: Texture2D
var _head_tex: Texture2D
var _food_node: Sprite2D
var _coin_node: Sprite2D
var _nodes := {}  # Vector2i -> Sprite2D (segments)
var _board_panel: Panel
var _eaten := 0

func _goga_setup() -> void:
        _load_skin_textures()
        _build_board()
        _new_snake()
        _spawn_food()
        _maybe_spawn_coin()
        add_hud_button("SHOP", func(): _shop_open())
        tk.swiped.connect(_on_swipe)

func _load_skin_textures() -> void:
        var skin := Box.skin_on("snake")
        if skin == "":
                skin = "classic"
        _food_tex = load("res://assets/games/snake/apple.png")
        _coin_tex = load("res://assets/ui/coin.png")
        _body_tex = load("res://assets/games/snake/body_%s.png" % skin)
        _head_tex = load("res://assets/games/snake/head_%s.png" % skin)
        if _body_tex == null:
                _body_tex = load("res://assets/games/snake/body_classic.png")
                _head_tex = load("res://assets/games/snake/head_classic.png")

func _build_board() -> void:
        var vp := get_viewport_rect().size
        # center the board in the REAL viewport (tall phones expand it - never
        # assume 1280 height; see docs/RESOLUTION_RULE.md)
        var board_h := ROWS * CELL + 12
        ORIGIN = Vector2(8, maxf(96.0, (vp.y - board_h) / 2.0))
        _board_panel = Panel.new()
        _board_panel.add_theme_stylebox_override("panel",
                Arc.panel_style(Color("1e3320"), 18))
        _board_panel.position = ORIGIN
        _board_panel.size = Vector2(COLS * CELL + 12, ROWS * CELL + 12)
        _board_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(_board_panel)
        world = Node2D.new()
        add_child(world)
        _food_node = _mk_sprite(_food_tex)
        _coin_node = _mk_sprite(_coin_tex)
        _coin_node.scale = Vector2(0.8, 0.8) * (float(CELL) / 64.0)
        _food_node.position = Vector2(-100, -100)
        _coin_node.position = Vector2(-100, -100)

func _mk_sprite(tex: Texture2D) -> Sprite2D:
        var s := Sprite2D.new()
        s.texture = tex
        s.z_index = 2
        world.add_child(s)
        return s

func _cell_center(c: Vector2i) -> Vector2:
        return ORIGIN + Vector2(6 + c.x * CELL + CELL / 2.0, 6 + c.y * CELL + CELL / 2.0)

func _new_snake() -> void:
        snake = [Vector2i(7, 8), Vector2i(7, 7), Vector2i(7, 6)]
        _nodes.clear()
        for c in snake:
                _add_segment_node(c)
        dir = Vector2i(0, 1)
        next_dir = dir

func _add_segment_node(c: Vector2i) -> void:
        var s := Sprite2D.new()
        s.texture = _head_tex if _nodes.is_empty() else _body_tex
        s.position = _cell_center(c)
        world.add_child(s)
        _nodes[c] = s

func _in_bounds(c: Vector2i) -> bool:
        return c.x >= 0 and c.x < COLS and c.y >= 0 and c.y < ROWS

func _free_cell() -> Vector2i:
        for i in 300:
                var c := Vector2i(randi() % COLS, randi() % ROWS)
                if not snake.has(c) and c != food and c != coin_pos:
                        return c
        return Vector2i(-1, -1)

func _spawn_food() -> void:
        food = _free_cell()
        _food_node.position = _cell_center(food)
        _food_node.scale = Vector2.ONE * (float(CELL) / 100.0)

func _maybe_spawn_coin() -> void:
        if coin_pos.x >= 0:
                return
        if randf() < 0.45:
                coin_pos = _free_cell()
                _coin_node.position = _cell_center(coin_pos)

func _goga_tick(delta: float) -> void:
        if not alive:
                return
        tick += delta
        if tick < step_time:
                return
        tick = 0.0
        _step()

func _step() -> void:
        dir = next_dir
        var head: Vector2i = snake[0] + dir
        if not _in_bounds(head) or snake.has(head):
                _die()
                return
        snake.push_front(head)
        var s := Sprite2D.new()
        s.texture = _body_tex
        _nodes[head] = s
        world.add_child(s)
        # keep z ordering: head on top
        if _nodes.has(snake[1]):
                (_nodes[snake[1]] as Sprite2D).texture = _body_tex

        var ate := false
        if head == food:
                ate = true
                _eaten += 1
                set_score(score + 1)   # owner rule: each apple = 1 score point
                grow += 1
                Jukebox.sfx("pop", -4.0, 1.0 + 0.02 * mini(20, _eaten))
                _spawn_food()
                _maybe_spawn_coin()
                # speed ramp (rescaled for 1-point apples: same curve shape)
                step_time = maxf(0.075, 0.16 - 0.002 * float(score))
        elif head == coin_pos:
                ate = true
                add_run_coins(1)   # owner rule: one pickup = ONE GOGACoin
                achievement_count("coins_taken", 1)
                achievement_max("coins_got", run_coins)
                Jukebox.sfx("coin", -4.0)
                coin_pos = Vector2i(-1, -1)
                _coin_node.position = Vector2(-100, -100)
                _maybe_spawn_coin()
        if not ate and grow <= 0:
                var tail: Vector2i = snake.pop_back()
                var n := _nodes.get(tail) as Sprite2D
                if n:
                        world.remove_child(n)
                        n.queue_free()
                _nodes.erase(tail)
        else:
                grow -= 1
        # redraw positions
        for i in snake.size():
                var c: Vector2i = snake[i]
                var n := _nodes.get(c) as Sprite2D
                if n:
                        n.position = _cell_center(c)
                        n.texture = _head_tex if i == 0 else _body_tex
        # flip head by direction
        var hn := _nodes.get(snake[0]) as Sprite2D
        if hn:
                hn.rotation = atan2(float(dir.x), float(-dir.y))

func _die() -> void:
        alive = false
        Jukebox.sfx("boom", -2.0)
        # final achievement sweep with the run score
        achievement_max("length", snake.size())
        check_achievements()
        var tw := create_tween().set_loops(3)
        tw.tween_property(world, "modulate", Color(1, 0.5, 0.5), 0.09)
        tw.tween_property(world, "modulate", Color.WHITE, 0.09)
        tw.finished.connect(func(): finish_run(score))

func _on_swipe(dirv: Vector2i, _pos: Vector2) -> void:
        if not alive:
                return
        # ignore 180-degree reversals
        if dirv == -dir and snake.size() > 1:
                return
        next_dir = dirv

# ------------------------------------------------------------- shop

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
                {"id": "classic", "name": "Classic", "price": 0},
                {"id": "lava", "name": "Lava", "price": 120},
                {"id": "ice", "name": "Ice", "price": 120},
                {"id": "gold", "name": "Gold", "price": 300},
        ]:
                var owned: bool = Box.skin_owned("snake", String(entry["id"])) or int(entry["price"]) == 0
                var on: bool = Box.skin_on("snake") == String(entry["id"]) \
                        or (int(entry["price"]) == 0 and Box.skin_on("snake") == "")
                var txt := String(entry["name"])
                if on:
                        txt += "  (on)"
                elif owned:
                        txt += "  (equip)"
                else:
                        txt += "  %d" % int(entry["price"])
                var col := Color("3fa060") if entry["id"] == "classic" \
                        else Color("d05a30") if entry["id"] == "lava" \
                        else Color("4aa8d8") if entry["id"] == "ice" else Color("d8b020")
                sheet.add_child(Arc.button(txt, Vector2(460, 66), 22, col, func():
                        _shop_action(String(entry["id"]), int(entry["price"]))))
        sheet.add_child(Arc.button("CLOSE", Vector2(460, 66), 24, Arc.ACCENT, func():
                get_tree().paused = false
                paused = false
                # remove only the sheet (last 2 overlay children), keep the toast alive
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
        # rebuild sprites with new skin
        var kids2 := _overlay_root_ref().get_children()
        for i in range(maxi(0, kids2.size() - 2), kids2.size()):
                kids2[i].queue_free()
        get_tree().paused = false
        paused = false
        _load_skin_textures()
        for c in _nodes:
                var n := _nodes[c] as Sprite2D
                if n:
                        n.texture = _head_tex if c == snake[0] else _body_tex
