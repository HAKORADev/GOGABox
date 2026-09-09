extends GogaGame
## MAZE ESCAPER (v0.3.7) - Geoquare's own puzzle: the endless neon maze.
## GDD: docs/goga_docs/gogames_ideas/maze.md - the PGB v1.3.8 sketch
## reborn with a REAL maze algorithm (the owner: the python one felt like
## "one single path with background noise instead of real maze").
##
## THE OWNER'S LAWS (binding, from the v0.3.7 message):
##   - THE REAL MAZE LAW: Wilson's algorithm (loop-erased random walks ->
##     a UNIFORM spanning tree) - every corridor is honest, the dead ends
##     are real, the solution is one thread through a genuinely branchy
##     labyrinth. No "openness noise" punched into a snake.
##   - THE RANDOM ENDS LAW: the start and the exit roll EVERY map (the
##     python game always used the same two corners) - a BFS-far pair, so
##     every map demands real reading, never memory.
##   - THE SCALE LAW: maps grow (+1 col every 2 maps, +1 row every 3) and
##     the cell shrinks to fit - but never below the MIN CELL, and the grid
##     caps there (the owner: "putting a limit"); every pixel of the board
##     area is used, centered.
##   - THE TIME LAW: time and scale are the enemies. Each map carries its
##     own budget = 10s + 0.8s per solution cell (clamped) - generous at
##     first, a real clock later. The timeout ends the run.
##   - THE SWIPE LAW: one swipe = one queued step (TouchKit). The queue
##     animates grid by grid and the animation SPEEDS UP as the queue
##     grows - fast fingers flow, the square never teleports.
##   - THE COIN LAW: every 5th map a GOGACoin waits ONE OR TWO STEPS off
##     the solution path - reachable, a detour, never exposing the route.
##   - THE FINDER LAW: the PATH FINDER (shop, standalone) earns one charge
##     every 2 maps (the PGB design). The HUD button next to the widgets
##     shows the charges; tap = it lights the next 8 solution cells for 8s
##     with a live countdown (same way, but better).
##   - SCORE: +1 per map. The box score bonus is /3 (registry coin_div).
##   - NO ENEMIES (the owner: the python ones were trash - time and scale
##     are the honest enemies).
##   - NEON like the Geometry Flash world. No faces on the square.
##
## Probe contract: probe_reset(seed) drives everything deterministically;
## maze cells / dist / path / player / queue / finder are public arrays and
## dicts; _swipe_dir + _step_move drive the verb directly; every law above
## is assertable headless.

const DIR := "res://assets/games/maze/"

# ---------------- the board (design px, scaled by US) -----------------------
const MARGIN := 26.0            # the board's side margins
const TOP_GAP := 128.0          # below the HUD row
const BOT_GAP := 26.0           # above the screen bottom
const MIN_CELL := 40.0          # the scale cap - the cell never goes smaller
const BASE_COLS := 11
const BASE_ROWS := 7

# ---------------- the clock -------------------------------------------------
const TIME_BASE := 10.0         # the flat part of every map's budget
const TIME_PER_CELL := 0.8      # + per solution cell (the map's real length)
const TIME_MIN := 24.0
const TIME_MAX := 99.0

# ---------------- the movement ---------------------------------------------
const MOVE_BASE := 5.5          # cells/s with an empty queue
const MOVE_PER_QUEUED := 1.2    # + speed per queued input (the owner's law)
const MOVE_MAX := 12.0
const QUEUE_CAP := 6
const DENY_SHAKE := 6.0

# ---------------- the finder ------------------------------------------------
const FINDER := {"name": "PATH FINDER", "price": 450,
        "desc": "one charge every 2 maps - it lights the next 4 cells, 8s"}
const FINDER_DUR := 8.0
# v0.3.7-1 THE SHY FINDER LAW (the owner, item 14: "the path finder shows
# too much, make it only 4 steps ahead and make it animated like a smooth
# path finder that shows the path one by one"): 8 lit cells read like a
# drawn answer. Four cells now - a nudge, not a solution - and the marks
# CASCADE in one by one (each cell fades in 0.12s after its predecessor).
const FINDER_STEPS := 4
const FINDER_STEP_DELAY := 0.12  # seconds between one mark and the next
const CHARGES_PER := 2          # +1 charge every 2 maps (the PGB design)

# ---------------- the content ----------------------------------------------
const THEMES := {
        "midnight": {"name": "MIDNIGHT", "price": 0,
                "top": Color(0.030, 0.045, 0.11), "mid": Color(0.055, 0.07, 0.16),
                "bot": Color(0.015, 0.025, 0.06), "wall": Color(0.62, 0.86, 1.0),
                "wall_dim": Color(0.20, 0.30, 0.52), "mark": Color(0.45, 0.95, 1.0),
                "exit": Color(0.55, 1.0, 0.65), "desc": "the calm blue neon"},
        "solar": {"name": "SOLAR", "price": 280,
                "top": Color(0.10, 0.05, 0.02), "mid": Color(0.16, 0.09, 0.03),
                "bot": Color(0.05, 0.02, 0.01), "wall": Color(1.0, 0.82, 0.55),
                "wall_dim": Color(0.50, 0.34, 0.16), "mark": Color(1.0, 0.75, 0.40),
                "exit": Color(1.0, 0.65, 0.45), "desc": "the amber heat"},
        "violet": {"name": "VIOLET RUSH", "price": 420,
                "top": Color(0.06, 0.02, 0.10), "mid": Color(0.10, 0.04, 0.17),
                "bot": Color(0.03, 0.01, 0.06), "wall": Color(0.90, 0.62, 1.0),
                "wall_dim": Color(0.38, 0.22, 0.55), "mark": Color(0.85, 0.55, 1.0),
                "exit": Color(1.0, 0.55, 0.90), "desc": "the deep magenta pulse"},
}
const SKINS := {
        "geoquare": {"name": "GEOQUARE", "price": 0, "col": Color(0.38, 0.89, 1.0),
                "desc": "the one that escaped the matrix"},
        "ember": {"name": "EMBER", "price": 140, "col": Color(1.0, 0.62, 0.32),
                "desc": "the warm one"},
        "toxin": {"name": "TOXIN", "price": 190, "col": Color(0.66, 1.0, 0.43),
                "desc": "the acid green"},
        "ghost": {"name": "GHOST", "price": 240, "col": Color(0.92, 0.96, 1.0),
                "desc": "the pale light"},
        "prism": {"name": "PRISM", "price": 320, "col": Color(1.0, 0.47, 0.92),
                "desc": "the pink violet"},
}
# v0.3.7-1 TAILS (the owner, item 12: "in maze escaper and snowy tower
# geometric, you can add tails in the shop to be used there, the overall
# theme makes it really good to have"): the Geometry Flash tail shelf
# travels here - same ids, same prices, one vocabulary across the box.
const TAILS := {
        "none": {"name": "NONE", "price": 0, "desc": "clean - no trail"},
        "neon": {"name": "NEON", "price": 160, "desc": "a cyan light ribbon"},
        "fire": {"name": "FIRE", "price": 230, "desc": "you burn backwards"},
        "rainbow": {"name": "RAINBOW", "price": 330, "desc": "the whole spectrum"},
        "gold": {"name": "GOLD", "price": 270, "desc": "gold sparks"},
        "match": {"name": "MATCH", "price": 290, "desc": "your own color"},
}

# ---------------- state -----------------------------------------------------
var phase := "ready"            # ready | run
var us := 1.0
var rng := RandomNumberGenerator.new()
var cells: Array = []           # [r][c] -> {t,b,l,r: bool}  (true = wall)
var cols := BASE_COLS
var rows := BASE_ROWS
var cell_px := 60.0             # SCREEN px (the fit law)
var board := Vector2.ZERO       # the board's top-left (SCREEN px)
var start_cell := Vector2i.ZERO
var end_cell := Vector2i.ZERO
var dist_map := {}              # BFS dist from the start (per map)
var solution: Array = []        # the path cells (Vector2i), start..end
var map_i := 0                  # 0-based map index (the scale + coin clock)
var round_time := 30.0
var time_left := 30.0
var player := {"r": 0, "c": 0, "x": 0.0, "y": 0.0, "rot": 0.0, "sq": 1.0}
var queue: Array = []           # queued Vector2i dirs (the owner's law)
var moving := false
var move_from := Vector2.ZERO
var move_to := Vector2.ZERO
var move_cell := Vector2i.ZERO   # the cell this move lands on
var move_t := 0.0
var move_dur := 0.18
var deny_t := 0.0
var coin := {}                  # {cell: Vector2i} or {}
var finder_used := 0            # charges spent this run
var finder_left := 0.0          # the active window
var over_gate := false
var beat_t := 0.0

# nodes
var bg: ColorRect
var bg_mat: ShaderMaterial
var maze_layer: Node2D
var mark_layer: Node2D
var pspr: Sprite2D
var coin_spr: Sprite2D
var exit_glow: Sprite2D
var ready_ui: Control
var map_label: Label
var map_label_t := 0.0
var finder_btn: Button = null
var timer_label: Label = null
var tex := {}
# v0.3.7-1 the tail: recent positions + ages, painted as a fading ribbon
var tail_id := "none"
var trail: Array = []            # [{x, y, t}]

func _tex(p: String) -> Texture2D:
        if not tex.has(p):
                tex[p] = load(DIR + p)
        return tex[p]

func _vp() -> Vector2:
        return get_viewport_rect().size

func _theme() -> Dictionary:
        var tid := Box.item_on(game_id, "theme")
        if not THEMES.has(tid):
                tid = "midnight"
        return THEMES[tid]

# =================================================================== setup
func _goga_setup() -> void:
        rng.randomize()
        game_id = "maze"
        var vp := _vp()
        us = vp.y / 1080.0
        tk.swiped.connect(_swipe_dir)   # THE SWIPE LAW: one swipe, one queued step
        _build_world()
        _build_hud_extra()
        _load_meta()
        _build_ready()
        # v0.3.7-1 THE SHOP BUTTON (the owner, item 16: "looks like you have
        # forgot to do the shop... or just the button is missing? this is
        # very sussy"): the shop was FULLY BUILT and its opener never wired
        # - the _shop_open sheet existed with no door to it. The button
        # takes its seat in the HUD row like every other shop game's.
        add_hud_button("SHOP", func(): _shop_open())
        Jukebox.music("res://assets/audio/music/maze_theme.ogg")
        _new_map()

func _load_meta() -> void:
        var sid := Box.skin_on(game_id)
        if sid == "" or not SKINS.has(sid):
                sid = "geoquare"
        player["skin"] = sid
        pspr.texture = _tex("skin_%s.png" % sid)
        # v0.3.7-1: the tail rides the meta load (the geometry law)
        tail_id = String(Box.item_on(game_id, "tail"))
        if not TAILS.has(tail_id):
                tail_id = "none"
        trail.clear()

func _build_world() -> void:
        # the neon bg (the Geometry Flash shader, the maze themes tint it)
        bg = ColorRect.new()
        bg.size = _vp()
        bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
        bg_mat = ShaderMaterial.new()
        bg_mat.shader = load("res://game/games/geometry/fx/gf_bg.gdshader")
        bg.material = bg_mat
        add_child(bg)
        _apply_theme()
        # the layers
        maze_layer = Node2D.new()
        maze_layer.draw.connect(_draw_maze)
        add_child(maze_layer)
        mark_layer = Node2D.new()
        mark_layer.draw.connect(_draw_marks)
        add_child(mark_layer)
        # the exit portal
        exit_glow = Sprite2D.new()
        exit_glow.texture = _tex("p_glow.png")
        var em := CanvasItemMaterial.new()
        em.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
        exit_glow.material = em
        add_child(exit_glow)
        # the square (NOT theme-tinted - skins keep their identity)
        pspr = Sprite2D.new()
        add_child(pspr)
        # the coin sprite (hidden until a coin map)
        coin_spr = Sprite2D.new()
        coin_spr.texture = load("res://assets/ui/coin.png")
        coin_spr.scale = Vector2.ONE * (44.0 / 96.0) * us
        coin_spr.visible = false
        add_child(coin_spr)

func _apply_theme() -> void:
        var t := _theme()
        bg_mat.set_shader_parameter("col_top", t["top"])
        bg_mat.set_shader_parameter("col_mid", t["mid"])
        bg_mat.set_shader_parameter("col_bot", t["bot"])
        bg_mat.set_shader_parameter("line_col", t["wall_dim"])
        bg_mat.set_shader_parameter("pulse", 0.25)

func _build_hud_extra() -> void:
        timer_label = add_hud_chip("30")
        # THE FINDER BUTTON - next to the top widgets (the owner's law); it
        # only exists once the finder is owned, and shows its charges. The
        # base helper returns void - the button is caught from the row after
        # the insert (it sits at index 1 + the flow count - 1).
        var flow_before: int = _flow_btns
        add_hud_button("FINDER", func(): _finder_tap())
        finder_btn = _hud_row.get_child(1 + _flow_btns - 1) as Button
        finder_btn.visible = false
        map_label = Arc.label("", 44, Color(1, 1, 1, 0))
        map_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
        map_label.offset_top = 150.0 * us
        map_label.offset_bottom = 220.0 * us
        map_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _hud.add_child(map_label)

func _build_ready() -> void:
        ready_ui = Control.new()
        ready_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
        ready_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _hud.add_child(ready_ui)
        var l := Arc.label("TAP ANYWHERE TO START", 54, Color(1, 1, 1, 0.95))
        l.set_anchors_preset(Control.PRESET_TOP_WIDE)
        l.offset_top = _vp().y * 0.42
        l.offset_bottom = _vp().y * 0.42 + 80.0
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        ready_ui.add_child(l)
        # v0.3.7-1 THE CLEAN GATE LAW (the owner, item 13: "the tap anywhere
        # wait screen shows a line under it about controls - remove it, we
        # never write too helpful stuff in the games, these things should
        # live in the guide, not here"): the how-to subline is GONE. The
        # gate speaks three words; the guide sheet owns the teaching.

# ============================================================ the real maze
## WILSON'S ALGORITHM - loop-erased random walks build a UNIFORM spanning
## tree: every valid maze is equally likely, the corridors branch honestly,
## the dead ends are real. This is the anti-"one path with noise" law.
func _wilson(nc: int, nr: int) -> Array:
        var grid: Array = []
        for r in nr:
                var row: Array = []
                for c in nc:
                        row.append({"t": true, "b": true, "l": true, "r": true,
                                        "in": false})
                grid.append(row)
        # the unvisited pool (swap-removed picks)
        var pool: Array = []
        for r in nr:
                for c in nc:
                        pool.append(Vector2i(c, r))
        # the seed cell joins the tree
        var seed_i := rng.randi_range(0, pool.size() - 1)
        var seed_cell: Vector2i = pool[seed_i]
        pool[seed_i] = pool[pool.size() - 1]
        pool.pop_back()
        grid[seed_cell.y][seed_cell.x]["in"] = true
        # the four grid directions: dr, dc, my wall, their wall
        var dirs := [[-1, 0, "t", "b"], [1, 0, "b", "t"],
                [0, -1, "l", "r"], [0, 1, "r", "l"]]
        while not pool.is_empty():
                # a random unvisited cell starts a loop-erased random walk
                var pi := rng.randi_range(0, pool.size() - 1)
                var head: Vector2i = pool[pi]
                var walk: Array = [head]
                var widx := {head: 0}
                while not grid[head.y][head.x]["in"]:
                        var d: Array = dirs[rng.randi_range(0, 3)]
                        var nxt := Vector2i(head.x + d[1], head.y + d[0])
                        if nxt.x < 0 or nxt.x >= nc or nxt.y < 0 or nxt.y >= nr:
                                continue
                        if widx.has(nxt):
                                # THE LOOP ERASE: everything after the twin dies
                                var cut: int = widx[nxt] + 1
                                while walk.size() > cut:
                                        var rm: Vector2i = walk.pop_back()
                                        widx.erase(rm)
                        else:
                                widx[nxt] = walk.size()
                                walk.append(nxt)
                        head = nxt
                # carve the erased walk into the tree - EVERY walk cell joins
                # (the old carve marked only the b ends, so each walk's first
                # cell stayed out of the pool's reach forever: the first
                # _new_map never returned)
                for i in walk.size() - 1:
                        var a: Vector2i = walk[i]
                        var b: Vector2i = walk[i + 1]
                        _carve(grid, a, b, dirs)
                        for v in [a, b]:
                                if not grid[v.y][v.x]["in"]:
                                        grid[v.y][v.x]["in"] = true
                                        var vi := pool.find(v)
                                        if vi >= 0:
                                                pool[vi] = pool[pool.size() - 1]
                                                pool.pop_back()
        return grid

func _carve(grid: Array, a: Vector2i, b: Vector2i, dirs: Array) -> void:
        for d in dirs:
                if a.x + d[1] == b.x and a.y + d[0] == b.y:
                        grid[a.y][a.x][d[2]] = false
                        grid[b.y][b.x][d[3]] = false
                        return

## BFS distances from one cell (the map's truth: reach + travel lengths).
func _bfs_dist(grid: Array, from: Vector2i, nc: int, nr: int) -> Dictionary:
        var dist := {from: 0}
        var q: Array = [from]
        var qi := 0
        var dirs := [[-1, 0, "t"], [1, 0, "b"], [0, -1, "l"], [0, 1, "r"]]
        while qi < q.size():
                var cur: Vector2i = q[qi]
                qi += 1
                var cd: int = dist[cur]
                for d in dirs:
                        if grid[cur.y][cur.x][d[2]]:
                                continue
                        var nxt := Vector2i(cur.x + d[1], cur.y + d[0])
                        if nxt.x < 0 or nxt.x >= nc or nxt.y < 0 or nxt.y >= nr:
                                continue
                        if dist.has(nxt):
                                continue
                        dist[nxt] = cd + 1
                        q.append(nxt)
        return dist

## The solution path via the BFS parent walk (shortest = the honest route).
func _bfs_path(grid: Array, from: Vector2i, to: Vector2i, nc: int, nr: int) -> Array:
        var prev := {from: from}
        var q: Array = [from]
        var qi := 0
        var dirs := [[-1, 0, "t"], [1, 0, "b"], [0, -1, "l"], [0, 1, "r"]]
        while qi < q.size():
                var cur: Vector2i = q[qi]
                qi += 1
                if cur == to:
                        break
                for d in dirs:
                        if grid[cur.y][cur.x][d[2]]:
                                continue
                        var nxt := Vector2i(cur.x + d[1], cur.y + d[0])
                        if nxt.x < 0 or nxt.x >= nc or nxt.y < 0 or nxt.y >= nr:
                                continue
                        if prev.has(nxt):
                                continue
                        prev[nxt] = cur
                        q.append(nxt)
        if not prev.has(to):
                return []
        var path: Array = [to]
        var cur := to
        while cur != from:
                cur = prev[cur]
                path.push_front(cur)
        return path

# ============================================================ the map flow
## THE FIT LAW: the cell fills the board area, never below MIN_CELL; when
## the grid would break the floor, the grid CAPS (the owner's limit).
func _fit_grid(want_c: int, want_r: int) -> void:
        var vp := _vp()
        var avail_w := vp.x - MARGIN * 2.0 * us
        var avail_h := vp.y - (TOP_GAP + BOT_GAP) * us
        cell_px = minf(avail_w / float(want_c), avail_h / float(want_r))
        cols = want_c
        rows = want_r
        if cell_px < MIN_CELL * us:
                cell_px = MIN_CELL * us
                cols = mini(want_c, int(avail_w / cell_px))
                rows = mini(want_r, int(avail_h / cell_px))
        board = Vector2((vp.x - cell_px * cols) * 0.5,
                (vp.y - cell_px * rows + (BOT_GAP - TOP_GAP) * us) * 0.5)

## THE MAP LAW: roll the size, weave the maze, pick a BFS-far start/end
## pair (never the same corners twice - the python game's sin), measure
## the honest solution, budget the clock.
func _new_map() -> void:
        var want_c := BASE_COLS + map_i / 2
        var want_r := BASE_ROWS + map_i / 3
        _fit_grid(want_c, want_r)
        cells = _wilson(cols, rows)
        # THE RANDOM ENDS LAW: a start, then the exit among the cells whose
        # travel distance sits in the far band (>= 62% of the deepest)
        var best_start := Vector2i.ZERO
        var best_end := Vector2i.ZERO
        var best_len := -1
        for attempt in 6:
                var sr := rng.randi_range(0, rows - 1)
                var sc := rng.randi_range(0, cols - 1)
                var s := Vector2i(sc, sr)
                dist_map = _bfs_dist(cells, s, cols, rows)
                var maxd := 0
                for k in dist_map:
                        maxd = maxi(maxd, int(dist_map[k]))
                var band: Array = []
                for k in dist_map:
                        if int(dist_map[k]) >= int(ceilf(maxd * 0.62)) and k != s:
                                band.append(k)
                if band.is_empty():
                        continue
                var e: Vector2i = band[rng.randi_range(0, band.size() - 1)]
                var path := _bfs_path(cells, s, e, cols, rows)
                if path.size() > best_len:
                        best_len = path.size()
                        best_start = s
                        best_end = e
                        solution = path
        start_cell = best_start
        end_cell = best_end
        dist_map = _bfs_dist(cells, start_cell, cols, rows)
        # THE TIME LAW - the budget reads the map's own real length
        round_time = clampf(TIME_BASE + solution.size() * TIME_PER_CELL,
                TIME_MIN, TIME_MAX)
        time_left = round_time
        # THE COIN LAW: every 5th map, one step or two OFF the path
        coin = {}
        if (map_i + 1) % 5 == 0:
                _coin_place()
        # the spawn: the square snaps onto the start, everything redraws
        player["r"] = start_cell.y
        player["c"] = start_cell.x
        player["x"] = _cell_center(start_cell).x
        player["y"] = _cell_center(start_cell).y
        player["rot"] = 0.0
        player["sq"] = 0.6
        queue.clear()
        moving = false
        finder_left = 0.0
        pspr.scale = _skin_scale()
        pspr.position = Vector2(player["x"], player["y"])
        _place_exit()
        _place_coin_spr()
        maze_layer.queue_redraw()
        mark_layer.queue_redraw()
        _update_finder_btn()
        if timer_label != null:
                timer_label.text = str(int(ceilf(time_left)))
        _flash_map_label("MAP %d" % (map_i + 1))

func _cell_center(cell: Vector2i) -> Vector2:
        return board + Vector2((float(cell.x) + 0.5) * cell_px,
                (float(cell.y) + 0.5) * cell_px)

func _place_exit() -> void:
        var c := _cell_center(end_cell)
        exit_glow.position = c
        exit_glow.scale = Vector2.ONE * (cell_px * 1.6 / 256.0)

func _place_coin_spr() -> void:
        if coin.is_empty():
                coin_spr.visible = false
                return
        coin_spr.visible = true
        coin_spr.position = _cell_center(coin["cell"])

## THE COIN PLACE: cells at BFS distance 1-2 from the solution (near it, so
## the detour is small) but NEVER on it (the coin must not expose the route).
func _coin_place() -> void:
        var on_path := {}
        for p in solution:
                on_path[p] = true
        var path_dist := _path_dist_map(on_path)
        var band: Array = []
        for k in path_dist:
                if not on_path.has(k) and int(path_dist[k]) >= 1 \
                                and int(path_dist[k]) <= 2:
                        band.append(k)
        if not band.is_empty():
                coin = {"cell": band[rng.randi_range(0, band.size() - 1)]}
        else:
                # a rare tight maze: any off-path cell keeps the law alive
                var off: Array = []
                for r in rows:
                        for c in cols:
                                var v := Vector2i(c, r)
                                if not on_path.has(v):
                                        off.append(v)
                if not off.is_empty():
                        coin = {"cell": off[rng.randi_range(0, off.size() - 1)]}

## The multi-source BFS distance-to-the-solution map (the coin + the probe
## both read it). The path cells themselves sit at 0.
func _path_dist_map(on_path: Dictionary) -> Dictionary:
        var path_dist := {}
        var q: Array = []
        for p in on_path:
                path_dist[p] = 0
                q.append(p)
        var qi := 0
        var dirs := [[-1, 0, "t"], [1, 0, "b"], [0, -1, "l"], [0, 1, "r"]]
        while qi < q.size():
                var cur: Vector2i = q[qi]
                qi += 1
                for d in dirs:
                        if cells[cur.y][cur.x][d[2]]:
                                continue
                        var nxt := Vector2i(cur.x + d[1], cur.y + d[0])
                        if nxt.x < 0 or nxt.x >= cols or nxt.y < 0 or nxt.y >= rows:
                                continue
                        if path_dist.has(nxt):
                                continue
                        path_dist[nxt] = path_dist[cur] + 1
                        q.append(nxt)
        return path_dist

## The public read for the probe: how far a cell sits from the route.
func _cell_path_dist(cell: Vector2i) -> int:
        var on_path := {}
        for p in solution:
                on_path[p] = true
        var m := _path_dist_map(on_path)
        return int(m.get(cell, 99))

# =================================================================== input
func _goga_input(event: InputEvent) -> void:
        if sheet_open_count() > 0:
                return
        if event is InputEventScreenTouch and event.pressed:
                if phase == "ready":
                        phase = "run"
                        if ready_ui != null:
                                ready_ui.queue_free()
                                ready_ui = null
                        Jukebox.sfx("m_start", -4.0)
                        return
                return
        if event is InputEventScreenDrag and phase == "run":
                return   # drags are TouchKit's business

func _ready_done() -> bool:
        return ready_ui == null

# =================================================================== tick
func _goga_tick(delta: float) -> void:
        beat_t += delta
        bg_mat.set_shader_parameter("time_s", beat_t)
        if over_gate:
                return
        if phase == "ready":
                return
        # THE CLOCK - time is the honest enemy
        time_left -= delta
        if timer_label != null:
                var secs := int(ceilf(maxf(0.0, time_left)))
                timer_label.text = str(secs)
                timer_label.modulate = Color(1, 0.5, 0.5) if time_left < 10.0 \
                                else Color(1, 1, 1)
        if time_left <= 0.0:
                _time_over()
                return
        if map_label_t > 0.0:
                map_label_t -= delta
                map_label.modulate.a = clampf(map_label_t / 0.4, 0.0, 1.0)
        deny_t = maxf(0.0, deny_t - delta * 8.0)
        # THE FINDER WINDOW
        if finder_left > 0.0:
                finder_left -= delta
                if finder_left <= 0.0:
                        finder_left = 0.0
                _update_finder_btn()
                mark_layer.queue_redraw()
        _step_move(delta)
        # v0.3.7-1 THE TAIL RIBBON: the trail breathes with movement
        _tick_tail(delta)
        # the exit portal breathes
        var pulse := 1.0 + 0.10 * sin(beat_t * 4.0)
        exit_glow.scale = Vector2.ONE * (cell_px * 1.6 / 256.0) * pulse
        if not coin.is_empty():
                coin_spr.position = _cell_center(coin["cell"]) \
                                + Vector2(0, sin(beat_t * 3.0) * 5.0 * us)

# ---------------------------------------------------------------- movement
## THE SWIPE LAW: one swipe = one queued step. THE SPEED LAW: the deeper
## the queue, the faster the animation (never instant, never sluggish).
## v0.3.7-1 THE CONTROLS RESURRECTION (the owner: "the game controls do not
## even respond at all"): TouchKit's swiped signal carries TWO arguments
## (dir + position) and this handler declared ONE - every single swipe
## died inside the signal call ("Method expected 1 argument(s), but called
## with 2") before the queue ever saw a direction. The instrumented probe
## caught the ERROR verbatim. One signature - the game comes alive.
func _swipe_dir(dir: Vector2i, _at: Vector2 = Vector2.ZERO) -> void:
        if phase != "run" or over_gate:
                return
        if queue.size() >= QUEUE_CAP:
                return
        queue.append(dir)
        _step_move(0.0)

func _step_move(delta: float) -> void:
        if moving:
                move_t += delta
                var prog := clampf(move_t / move_dur, 0.0, 1.0)
                var eased := 1.0 - pow(1.0 - prog, 2.2)
                player["x"] = lerpf(move_from.x, move_to.x, eased)
                player["y"] = lerpf(move_from.y, move_to.y, eased)
                player["sq"] = 1.0 + 0.06 * sin(prog * PI)
                pspr.position = Vector2(player["x"], player["y"])
                pspr.rotation_degrees = player["rot"]
                var base := _skin_scale()
                pspr.scale = base * Vector2(2.0 - player["sq"], player["sq"])
                if prog >= 1.0:
                        moving = false
                        # THE ARRIVAL COMMITS: the cell lands BEFORE the
                        # arrival reads it (the old build never wrote r/c, so
                        # the coin, the exit and every route read the stale
                        # start cell forever)
                        player["r"] = move_cell.y
                        player["c"] = move_cell.x
                        _arrived()
                return
        if queue.is_empty():
                return
        # pop the next intent; a wall eats the input with a visible NO
        var dir: Vector2i = queue.pop_front()
        var wall_key := ""
        if dir == Vector2i(0, -1):
                wall_key = "t"
        elif dir == Vector2i(0, 1):
                wall_key = "b"
        elif dir == Vector2i(-1, 0):
                wall_key = "l"
        else:
                wall_key = "r"
        var pr: int = player["r"]
        var pc: int = player["c"]
        var nr2: int = pr + dir.y
        var nc2: int = pc + dir.x
        var blocked: bool = cells[pr][pc][wall_key] \
                or nr2 < 0 or nr2 >= rows or nc2 < 0 or nc2 >= cols
        if blocked:
                deny_t = 1.0
                player["rot"] = 0.0
                Jukebox.sfx("m_deny", -10.0, 1.0 + rng.randf() * 0.06)
                mark_layer.queue_redraw()
                if not queue.is_empty():
                        _step_move(0.0)   # keep the flow alive
                return
        # the move begins - the speed reads the queue (THE SPEED LAW)
        var speed := minf(MOVE_BASE + MOVE_PER_QUEUED * float(queue.size() + 1),
                MOVE_MAX)
        move_dur = 1.0 / speed
        move_from = Vector2(player["x"], player["y"])
        move_to = _cell_center(Vector2i(nc2, nr2))
        move_cell = Vector2i(nc2, nr2)
        player["rot"] = 0.0
        move_t = 0.0
        moving = true
        Jukebox.sfx("m_move", -14.0, 0.9 + 0.06 * float(queue.size()))
        mark_layer.queue_redraw()

## THE ARRIVAL: the cell lands - the coin, the finder glow, the EXIT.
func _arrived() -> void:
        var here := Vector2i(player["c"], player["r"])
        if not coin.is_empty() and coin["cell"] == here:
                coin = {}
                coin_spr.visible = false
                add_run_coins(1)
                Jukebox.sfx("m_coin", -4.0)
                _ring_at(Vector2(player["x"], player["y"]), Color(1.0, 0.85, 0.4), 0.9)
        if here == end_cell:
                _escape()

## THE ESCAPE: +1 score, the ceremony, the next map (bigger, fresh ends).
func _escape() -> void:
        add_score(1)
        achievement_max("max_maps", score)
        achievement_count("escapes", 1)
        Jukebox.sfx("m_win", -3.0)
        _ring_at(Vector2(player["x"], player["y"]), _theme()["exit"], 1.3)
        _ring_at(Vector2(player["x"], player["y"]), Color(1, 1, 1), 0.7)
        map_i += 1
        _new_map()

func _time_over() -> void:
        if over_gate:
                return
        over_gate = true
        Jukebox.sfx("m_over", -2.0)
        achievement_count("escapes", 0)
        check_achievements()
        var t := get_tree().create_timer(0.6)
        t.timeout.connect(func(): finish_run(score))

## the one-ring collect ceremony (the owner's patch-3 simplification lives
## here too: JUST the circle)
func _ring_at(pos: Vector2, col: Color, power: float) -> void:
        var r := Sprite2D.new()
        r.texture = _tex("p_ring.png")
        r.position = pos
        r.scale = Vector2.ONE * 0.2 * us
        r.modulate = Color(col.r, col.g, col.b, 0.9)
        var m := CanvasItemMaterial.new()
        m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
        r.material = m
        add_child(r)
        var tw := r.create_tween()
        tw.set_parallel(true)
        tw.tween_property(r, "scale", Vector2.ONE * 1.5 * power * us, 0.32) \
                .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
        tw.tween_property(r, "modulate:a", 0.0, 0.32)
        tw.chain().tween_callback(func(): if is_instance_valid(r): r.queue_free())

# =================================================================== finder
## THE FINDER LAW: +1 charge every 2 maps; the tap lights the next 8
## solution cells for 8s with the live countdown on the button.
func _finder_charges() -> int:
        return maxi(0, map_i / CHARGES_PER - finder_used)

func _finder_tap() -> void:
        if not Box.item_owned(game_id, "finder", "finder"):
                return
        if phase != "run" or over_gate or finder_left > 0.0:
                return
        if _finder_charges() <= 0:
                Jukebox.sfx("m_deny", -10.0)
                return
        finder_used += 1
        # v0.3.7-1: the charge feeds its own trophy now (the old finder ach
        # id never joined the match table - it was a dead trophy)
        achievement_count("finder_used", 1)
        finder_left = FINDER_DUR
        Jukebox.sfx("m_finder", -4.0)
        _update_finder_btn()
        mark_layer.queue_redraw()

func _update_finder_btn() -> void:
        if finder_btn == null:
                return
        finder_btn.visible = Box.item_owned(game_id, "finder", "finder")
        if finder_left > 0.0:
                finder_btn.text = "FINDER %ds" % int(ceilf(finder_left))
        else:
                finder_btn.text = "FINDER x%d" % _finder_charges()

## The live route: the next (up to) 8 cells from HERE to the exit.
func _finder_route() -> Array:
        var from := Vector2i(player["c"], player["r"])
        var route := _bfs_path(cells, from, end_cell, cols, rows)
        if route.size() > 0:
                route.pop_front()   # the cell you stand on is not a marker
        while route.size() > FINDER_STEPS:
                route.pop_back()
        return route

# =================================================================== render
func _skin_scale() -> Vector2:
        var art := 160.0 * 0.72                  # the drawn square in the png
        var s := (cell_px * 0.62) / art
        return Vector2(s, s)

## THE MAZE WALLS: every wall is a neon stroke - the honest Wilson texture
## reads as a real labyrinth, not a corridor with noise. Walls sit ON the
## cell borders; a dim under-stroke is the glow bed.
func _draw_maze() -> void:
        if cells.is_empty():
                return
        var t := _theme()
        var lw := maxf(2.0, cell_px * 0.075)
        for pass_i in 2:
                var col: Color = t["wall_dim"] if pass_i == 0 else t["wall"]
                var w := lw * (2.2 if pass_i == 0 else 1.0)
                for r in rows:
                        for c in cols:
                                var cell: Dictionary = cells[r][c]
                                var x := board.x + float(c) * cell_px
                                var y := board.y + float(r) * cell_px
                                if cell["t"]:
                                        maze_layer.draw_line(Vector2(x, y),
                                                Vector2(x + cell_px, y), col, w)
                                if cell["l"]:
                                        maze_layer.draw_line(Vector2(x, y),
                                                Vector2(x, y + cell_px), col, w)
                                if r == rows - 1 and cell["b"]:
                                        maze_layer.draw_line(Vector2(x, y + cell_px),
                                                Vector2(x + cell_px, y + cell_px), col, w)
                                if c == cols - 1 and cell["r"]:
                                        maze_layer.draw_line(Vector2(x + cell_px, y),
                                                Vector2(x + cell_px, y + cell_px), col, w)
        # the start mark (a soft ring under the square's first cell)
        var sc := _cell_center(start_cell)
        maze_layer.draw_arc(sc, cell_px * 0.30, 0.0, TAU, 24,
                Color(t["mark"].r, t["mark"].g, t["mark"].b, 0.25), 2.0 * us)
        # the exit: the portal rings
        var ec := _cell_center(end_cell)
        var pulse := 1.0 + 0.08 * sin(beat_t * 4.0)
        maze_layer.draw_arc(ec, cell_px * 0.34 * pulse, 0.0, TAU, 26,
                t["exit"], 3.0 * us)
        maze_layer.draw_arc(ec, cell_px * 0.20 * pulse, 0.0, TAU, 20,
                Color(t["exit"].r, t["exit"].g, t["exit"].b, 0.6), 2.0 * us)
## the deny shake: the square's cell edge flashes
        if deny_t > 0.0:
                var pc := Vector2i(player["c"], player["r"])
                var p0 := board + Vector2(float(pc.x) * cell_px, float(pc.y) * cell_px)
                maze_layer.draw_rect(Rect2(p0, Vector2(cell_px, cell_px)),
                        Color(1.0, 0.4, 0.4, 0.4 * deny_t), false, 2.0 * us)

## v0.3.7-1 THE TAIL: record while the square travels, paint the fading
## ribbon under it. Points live 0.55s; the newest sits at the square.
func _tick_tail(delta: float) -> void:
        for p in trail:
                p["t"] = float(p["t"]) + delta
        while not trail.is_empty() and float(trail[0]["t"]) > 0.55:
                trail.pop_front()
        if moving and tail_id != "none":
                trail.append({"x": player["x"], "y": player["y"], "t": 0.0})
        mark_layer.queue_redraw()

func _tail_col(frac: float, i: int) -> Color:
        # frac 0..1 = old..new; i = the point index (the rainbow phase)
        match tail_id:
                "neon":
                        return Color(0.38, 0.89, 1.0, 0.85 * frac)
                "fire":
                        return Color(1.0, lerpf(0.25, 0.75, frac), 0.2, 0.9 * frac)
                "rainbow":
                        return Color.from_hsv(fmod(float(i) * 0.09 + beat_t * 0.35, 1.0),
                                        0.85, 1.0, 0.85 * frac)
                "gold":
                        return Color(1.0, 0.83, 0.3, 0.9 * frac)
                "match":
                        var c: Color = SKINS[String(player.get("skin", "geoquare"))]["col"]
                        c.a = 0.85 * frac
                        return c
        return Color(0, 0, 0, 0)

## the tail paints UNDER the square: newest = widest + brightest
func _draw_tail() -> void:
        if tail_id == "none" or trail.size() < 2:
                return
        for i in range(trail.size() - 1):
                var a: Dictionary = trail[i]
                var b: Dictionary = trail[i + 1]
                var frac: float = 1.0 - float(a["t"]) / 0.55
                var col := _tail_col(frac, i)
                if col.a <= 0.01:
                        continue
                mark_layer.draw_line(Vector2(a["x"], a["y"]),
                                Vector2(b["x"], b["y"]), col,
                                maxf(1.5, 9.0 * frac) * us)

## THE FINDER MARKS (only while the window is live).
## v0.3.7-1 THE SHY FINDER (the owner, item 14): the marks CASCADE - mark i
## fades in at (i * FINDER_STEP_DELAY) into the window, so the path draws
## itself one step at a time instead of flashing the whole answer.
func _draw_marks() -> void:
        # v0.3.7-1: the tail ribbon paints here too (under the finder marks)
        _draw_tail()
        if finder_left <= 0.0 or cells.is_empty():
                return
        var t := _theme()
        var route := _finder_route()
        var elapsed: float = FINDER_DUR - finder_left
        var frac := clampf(finder_left / FINDER_DUR, 0.0, 1.0)
        for i in route.size():
                var born := float(i) * FINDER_STEP_DELAY
                if elapsed < born:
                        continue
                var own := clampf((elapsed - born) / 0.18, 0.0, 1.0)
                var cc: Vector2i = route[i]
                var c := _cell_center(cc)
                var a: float = frac * (1.0 - 0.5 * float(i) / float(maxi(1, route.size()))) \
                                * own
                var rr: float = cell_px * (0.16 + 0.03 * sin(beat_t * 6.0 + float(i)))
                mark_layer.draw_circle(c, rr * 1.8,
                        Color(t["mark"].r, t["mark"].g, t["mark"].b, 0.10 * a))
                mark_layer.draw_circle(c, rr,
                        Color(t["mark"].r, t["mark"].g, t["mark"].b, 0.8 * a))

func _flash_map_label(txt: String) -> void:
        map_label.text = txt
        map_label_t = 1.2
        map_label.modulate.a = 0.0

# =================================================================== shop
## THE SHOP: square skins + maze themes + the PATH FINDER (standalone; the
## charges economy is the game's own).
var shop_id := ""

func _shop_open() -> void:
        if shop_id != "":
                return
        shop_id = "shop"
        # v0.3.7-1 THE BEHIND LAW (the visual QA catch): the ready gate used
        # to paint OVER the shop sheet (it lives directly under the HUD,
        # the sheet under the overlay root). The gate hides while a sheet
        # speaks - same law as the geometry lore box.
        if ready_ui != null and is_instance_valid(ready_ui):
                ready_ui.visible = false
        if phase == "run":
                paused = true
                get_tree().paused = true
        var sheet := sheet_push(0.0, "shop")
        var t := Arc.label("MAZE SHOP", 34, Arc.INK)
        t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sheet.add_child(t)
        var wallet := Arc.coin_chip()
        wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        sheet.add_child(wallet)
        var sc := BoxScroll.new()
        sc.game_safe = true
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var vp := _vp()
        sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.52, 300.0, 640.0))
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        sc.add_child(box)
        sheet.add_child(sc)
        box.add_child(_shop_label("SQUARES - the escapee's skin"))
        for id in SKINS:
                box.add_child(_skin_row(id))
        # v0.3.7-1 TAILS: the ribbon shelf (item 12)
        box.add_child(_shop_label("TAILS - the light you leave behind"))
        for id in TAILS:
                box.add_child(_tail_row(id))
        box.add_child(_shop_label("MAZE THEMES - the light of the walls"))
        for id in THEMES:
                box.add_child(_theme_row(id))
        box.add_child(_shop_label("HELPERS"))
        box.add_child(_finder_row())
        box.add_child(Arc.button("CLOSE", Vector2(560, 74), 24, Arc.GOOD,
                func(): sheet_pop()))
        for b in Arc._buttons_in(sc):
                if b.disabled:
                        continue
                b.mouse_filter = Control.MOUSE_FILTER_IGNORE
                sc.register_tappable(b, Arc._tap_emitter(b))

func _goga_sheet_popped(id: String) -> void:
        if id == "shop":
                shop_id = ""
                if phase == "run":
                        get_tree().paused = false
                        paused = false
                _load_meta()
                _apply_theme()
                maze_layer.queue_redraw()
                _update_finder_btn()
        # the gate comes back when the last sheet closes
        if shop_id == "" and sheet_open_count() == 0 \
                        and ready_ui != null and is_instance_valid(ready_ui):
                ready_ui.visible = true

func _shop_label(txt: String) -> Label:
        return Arc.fit_label(txt, 24, Arc.HOT, 560)

func _price_btn(txt: String, price: int, col: Color, cb: Callable) -> Button:
        var b := Arc.coin_button("%s  %d" % [txt, price], Vector2(560, 64), 22, col, cb)
        if Box.coins() < price:
                b.disabled = true
        return b

func _skin_row(id: String) -> Control:
        var c: Dictionary = SKINS[id]
        var owned := Box.skin_owned(game_id, id) or int(c["price"]) == 0
        var on: bool = Box.skin_on(game_id) == id \
                or (int(c["price"]) == 0 and Box.skin_on(game_id) == "")
        if on:
                var l := Arc.fit_label("%s  (ON) - %s" % [c["name"], c["desc"]], 22,
                        Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        if owned:
                return Arc.button("%s - WEAR" % c["name"], Vector2(560, 60), 22,
                        Color("4a5ab8"), func():
                                Box.equip_skin(game_id, id)
                                player["skin"] = id
                                Jukebox.sfx("confirm", -4.0)
                                pspr.texture = _tex("skin_%s.png" % id)
                                _shop_reopen())
        return _price_btn(c["name"], int(c["price"]), Color("4a5ab8"), func():
                if Box.buy_skin(game_id, id, int(c["price"])):
                        Jukebox.sfx("buy")
                        Box.equip_skin(game_id, id)
                        player["skin"] = id
                        pspr.texture = _tex("skin_%s.png" % id)
                _shop_reopen())

## v0.3.7-1 THE TAIL ROW: same bones as the theme row - owned wears, unowned
## buys. The wear refreshes the meta load (the ribbon follows instantly).
func _tail_row(id: String) -> Control:
        var c: Dictionary = TAILS[id]
        var owned := Box.item_owned(game_id, "tail", id) or int(c["price"]) == 0
        var on: bool = Box.item_on(game_id, "tail") == id \
                or (int(c["price"]) == 0 and Box.item_on(game_id, "tail") == "")
        if on:
                var l := Arc.fit_label("%s  (ON) - %s" % [c["name"], c["desc"]], 22,
                                Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        if owned:
                return Arc.button("%s  -  WEAR" % c["name"], Vector2(560, 60), 22,
                                Color("8a4ab8"), func():
                                                Box.equip_item(game_id, "tail", id)
                                                Jukebox.sfx("confirm", -4.0)
                                                _load_meta()
                                                _shop_reopen())
        return _price_btn("%s - %s" % [c["name"], c["desc"]], int(c["price"]),
                        Color("8a4ab8"), func():
                                        if Box.buy_item(game_id, "tail", id, int(c["price"])):
                                                        Jukebox.sfx("buy")
                                                        Box.equip_item(game_id, "tail", id)
                                                        _load_meta()
                                        _shop_reopen())

func _theme_row(id: String) -> Control:
        var c: Dictionary = THEMES[id]
        var owned := Box.item_owned(game_id, "theme", id) or int(c["price"]) == 0
        var on: bool = Box.item_on(game_id, "theme") == id \
                or (int(c["price"]) == 0 and Box.item_on(game_id, "theme") == "")
        if on:
                var l := Arc.fit_label("%s  (ON) - %s" % [c["name"], c["desc"]], 22,
                        Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        if owned:
                return Arc.button("%s - LIGHT IT" % c["name"], Vector2(560, 60), 22,
                        Color("2a7a68"), func():
                                Box.equip_item(game_id, "theme", id)
                                Jukebox.sfx("confirm", -4.0)
                                _apply_theme()
                                maze_layer.queue_redraw()
                                _shop_reopen())
        return _price_btn(c["name"], int(c["price"]), Color("2a7a68"), func():
                if Box.buy_item(game_id, "theme", id, int(c["price"])):
                        Jukebox.sfx("buy")
                        Box.equip_item(game_id, "theme", id)
                        _apply_theme()
                        maze_layer.queue_redraw()
                _shop_reopen())

func _finder_row() -> Control:
        if Box.item_owned(game_id, "finder", "finder"):
                var l := Arc.fit_label("%s  (OWNED) - %s" % [FINDER["name"],
                        FINDER["desc"]], 22, Color("58c470"), 560)
                l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                return l
        return _price_btn("%s - %s" % [FINDER["name"], FINDER["desc"]],
                int(FINDER["price"]), Color("b8583a"), func():
                        if Box.buy_item(game_id, "finder", "finder", int(FINDER["price"])):
                                Jukebox.sfx("buy")
                        _update_finder_btn()
                        _shop_reopen())

func _shop_reopen() -> void:
        if shop_id != "":
                sheet_pop()
                _shop_open.call_deferred()

# =================================================================== probe
## The headless contract: a deterministic maze any probe can drive.
func probe_reset(seed_v: int) -> void:
        rng.seed = seed_v
        map_i = 0
        score = 0
        set_score(0)
        finder_used = 0
        finder_left = 0.0
        over_gate = false
        queue.clear()
        moving = false
        deny_t = 0.0
        phase = "run"
        paused = true             # the probe steps the world itself
        _new_map()

func probe_step(dt: float) -> void:
        _goga_tick(dt)
