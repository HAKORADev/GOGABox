extends GogaGame
## 2048 — swipe merge puzzle, endless. Score feeds GOGACoins; big tiles
## trigger achievements. Clean board animation via tweens.

const GRID := 4
const CELL := 150
const GAP := 12
const ORIGIN := Vector2(27, 250)

var board: Array = []   # 2D of ints (0 = empty)
var tiles := {}         # Vector2i -> TileNode
var world: Node2D
var animating := false

class TileNode:
        extends Node2D
        var value := 0
        var panel: Panel
        var lab: Label

        func setup(v: int) -> void:
                if panel == null:
                        panel = Panel.new()
                        panel.position = Vector2(-CELL / 2.0, -CELL / 2.0)
                        panel.size = Vector2(CELL, CELL)
                        panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        add_child(panel)
                        lab = Arc.label("", 64, Color.WHITE)
                        lab.position = Vector2(-CELL / 2.0, -CELL / 2.0 + 6)
                        lab.size.x = CELL
                        lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                        panel.add_child(lab)
                value = v
                panel.add_theme_stylebox_override("panel", Arc.panel_style(_bg(v), 16))
                lab.text = str(v)
                lab.add_theme_font_size_override("font_size", _font_size(v))
                lab.add_theme_color_override("font_color", _fg(v))

        static func _bg(v: int) -> Color:
                if v > 2048:
                        return Color("6c5ab8")
                var colors := {
                        2: Color("efe6d8"), 4: Color("edd9b0"), 8: Color("f2b179"),
                        16: Color("f59563"), 32: Color("f67c5f"), 64: Color("f65e3b"),
                        128: Color("edcf72"), 256: Color("edcc61"), 512: Color("edc850"),
                        1024: Color("edc53f"), 2048: Color("edc22e"),
                }
                return colors.get(v, Color("3c3a32"))

        static func _fg(v: int) -> Color:
                return Arc.INK if v <= 4 else Color.WHITE

        static func _font_size(v: int) -> int:
                if v < 100: return 64
                if v < 1000: return 54
                if v < 10000: return 44
                return 36

func _goga_setup() -> void:
        tk.swiped.connect(_on_swipe)
        world = Node2D.new()
        add_child(world)
        var bg := Panel.new()
        bg.add_theme_stylebox_override("panel", Arc.panel_style(Color("bbada0"), 18))
        bg.position = ORIGIN
        bg.size = Vector2(GRID * CELL + (GRID + 1) * GAP, GRID * CELL + (GRID + 1) * GAP)
        bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(bg)
        for x in GRID:
                for y in GRID:
                        var hole := Panel.new()
                        hole.add_theme_stylebox_override("panel", Arc.panel_style(Color("cdc1b4"), 12))
                        hole.position = Vector2(ORIGIN.x + GAP + x * (CELL + GAP),
                                ORIGIN.y + GAP + y * (CELL + GAP))
                        hole.size = Vector2(CELL, CELL)
                        hole.mouse_filter = Control.MOUSE_FILTER_IGNORE
                        add_child(hole)
        board = []
        for x in GRID:
                var col := []
                col.resize(GRID)
                col.fill(0)
                board.append(col)
        _spawn_random()
        _spawn_random()
        # restore autosave? v1: runs always start fresh (entry fee = fresh board)

func _cell_pos(c: Vector2i) -> Vector2:
        return Vector2(ORIGIN.x + GAP + c.x * (CELL + GAP) + CELL / 2.0,
                ORIGIN.y + GAP + c.y * (CELL + GAP) + CELL / 2.0)

func _spawn_random() -> void:
        var empty: Array[Vector2i] = []
        for x in GRID:
                for y in GRID:
                        if int(board[x][y]) == 0:
                                empty.append(Vector2i(x, y))
        if empty.is_empty():
                return
        var c: Vector2i = empty[randi() % empty.size()]
        var v := 2 if randf() < 0.9 else 4
        board[c.x][c.y] = v
        var t := TileNode.new()
        t.position = _cell_pos(c)
        t.setup(v)
        world.add_child(t)
        tiles[c] = t
        t.scale = Vector2.ZERO
        var tw := t.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tw.tween_property(t, "scale", Vector2.ONE, 0.14)

func _on_swipe(dirv: Vector2i, _pos: Vector2) -> void:
        if animating:
                return
        var moved := _slide(dirv)
        if moved:
                animating = true
                await get_tree().create_timer(0.16).timeout
                _spawn_random()
                animating = false
                if _dead():
                        Jukebox.sfx("lose", -2.0)
                        check_achievements()
                        finish_run(score)

func _slide(dirv: Vector2i) -> bool:
        var moved := false
        var order := range(GRID)
        if dirv.x > 0 or dirv.y > 0:
                order.reverse()
        for i in order:
                for j in range(GRID):
                        var coords: Array[Vector2i] = []
                        var line: Array = []
                        for k in range(GRID):
                                var c := Vector2i(i, k) if dirv.x != 0 else Vector2i(k, i)
                                coords.append(c)
                                line.append(int(board[c.x][c.y]))
                        if dirv.x > 0 or dirv.y > 0:
                                line.reverse()
                                coords.reverse()
                        # classic compress + merge
                        var vals: Array = []
                        for v in line:
                                if v != 0:
                                        vals.append(v)
                        var out: Array = []
                        var k2 := 0
                        while k2 < vals.size():
                                if k2 + 1 < vals.size() and vals[k2] == vals[k2 + 1]:
                                        set_score(score + int(vals[k2]) * 2)
                                        out.append(int(vals[k2]) * 2)
                                        k2 += 2
                                else:
                                        out.append(int(vals[k2]))
                                        k2 += 1
                        while out.size() < GRID:
                                out.append(0)
                        for k3 in range(GRID):
                                var c2: Vector2i = coords[k3]
                                var nv: int = out[k3]
                                var old: int = int(board[c2.x][c2.y])
                                if nv != old:
                                        moved = true
                                board[c2.x][c2.y] = nv
                                _reposition(c2, nv)
        return moved

func _reposition(c: Vector2i, v: int) -> void:
        var t: TileNode = tiles.get(c)
        if v == 0:
                if t:
                        t.queue_free()
                        tiles.erase(c)
                return
        if t == null:
                t = TileNode.new()
                t.position = _cell_pos(c)
                t.setup(v)
                world.add_child(t)
                tiles[c] = t
                t.scale = Vector2.ONE
        else:
                var tw := t.create_tween()
                tw.tween_property(t, "position", _cell_pos(c), 0.1)
                if t.value != v:
                        # pop into the doubled value
                        tw.tween_callback(func():
                                t.setup(v)
                                t.scale = Vector2.ONE * 1.15)
                        tw.tween_property(t, "scale", Vector2.ONE, 0.09)
                        if v > 8:
                                Jukebox.sfx("pop", -8.0, 0.6 + 0.02 * (v / 16))
                        if v >= 32:
                                achievement_max("max_tile", v)
                        if v > 64:
                                add_run_coins(v / 32)
                                achievement_count("coins_taken", v / 32)

func _dead() -> bool:
        for x in GRID:
                for y in GRID:
                        if int(board[x][y]) == 0:
                                return false
        for x in GRID:
                for y in GRID:
                        var v := int(board[x][y])
                        if x + 1 < GRID and int(board[x + 1][y]) == v:
                                return false
                        if y + 1 < GRID and int(board[x][y + 1]) == v:
                                return false
        return true
