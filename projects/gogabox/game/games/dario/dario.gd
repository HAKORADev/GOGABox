extends GogaGame
## Dario - a proper little platformer. Run, jump, stomp. Three hand-built
## levels of pits, walkers and coins, ending at the flag. Landscape.
##
## Controls (one thumb friendly): HOLD the left half to walk left, HOLD the
## right half to walk right, JUMP button (or swipe up) to jump. Release
## jump early for a shorter hop. Land on a walker to squash it (+5); touch
## one from the side (or fall into a pit) and the run ends.

const TS := 72                       # tile size (15 rows = exactly 1080)
const ROWS := 15
const GRAV := 2300.0
const JUMP_V := -880.0
const RUN_MAX := 430.0
const ACCEL := 2600.0

# ---- the three levels (48 cols x 15 rows). # ground, = ledge, o coin,
# E walker, P player, F flag. Rows shorter than 48 are padded with spaces.
const LEVELS := [
        [
                "                                                ",
                "                                                ",
                "                                                ",
                "                                                ",
                "                                                ",
                "                                                ",
                "                                                ",
                "            o o o                   o o         ",
                "          =======                 =====         ",
                "                                                ",
                " P    o o          E      o o    E            F ",
                "######    ################    ##################",
                "######    ################    ##################",
                "######    ################    ##################",
                "######    ################    ##################",
        ],
        [
                "                                                ",
                "                                                ",
                "                                                ",
                "                                                ",
                "                                                ",
                "                   o o                          ",
                "                  =====                 =====   ",
                "      o o                     o o o             ",
                "     =====                  ======              ",
                "                                                ",
                " P           E      o o   E    E  o o         F ",
                "########    ########    ##########    ##########",
                "########    ########    ##########    ##########",
                "########    ########    ##########    ##########",
                "########    ########    ##########    ##########",
        ],
        [
                "                                                ",
                "                                                ",
                "                                                ",
                "                                                ",
                "                                                ",
                "                 o o o            o o           ",
                "                =====            ====           ",
                "       o o                   o o                ",
                "      =====                 =====         ======",
                "                                                ",
                " P   E    o o      E       E        o o   o o F ",
                "##########    ########    ##########    ########",
                "##########    ########    ##########    ########",
                "##########    ########    ##########    ########",
                "##########    ########    ##########    ########",
        ],
]

var world: Node2D
var cam_x := 0.0
var level_i := 0
var grid: Array = []             # grid[row] = String of the level
var cols := 0
var solids := {}                 # Vector2i -> true (solid tiles)
var player: Sprite2D
var p_pos := Vector2.ZERO        # hitbox top-left
var p_vel := Vector2.ZERO
var on_ground := false
var jump_held := false
var dir_held := 0                # -1 left, 1 right, 0 idle
var walkers: Array = []          # {node, pos, dir, dead}
var coins_nodes: Array = []      # {node, got}
var flag_pos := Vector2.ZERO
var flag_node: Sprite2D
var level_label: Label
var _hero_idle: Texture2D
var _hero_jump: Texture2D
var _walk_tex: Texture2D
var _ending := false

func _goga_setup() -> void:
        _hero_idle = load("res://assets/games/dario/hero_idle.png")
        _hero_jump = load("res://assets/games/dario/hero_jump.png")
        _walk_tex = load("res://assets/games/dario/walker.png")
        var vp := get_viewport_rect().size
        world = Node2D.new()
        add_child(world)
        var sky := ColorRect.new()
        sky.color = Color("6ec2ea")
        sky.size = vp
        sky.z_index = -10
        sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
        world.add_child(sky)
        level_label = Arc.label("", 30, Color(1, 1, 1, 0.9))
        level_label.position = Vector2(24, 92)
        world.add_child(level_label)
        _build_jump_button()
        tk.swiped.connect(func(d: Vector2i, _p: Vector2):
                if d == Vector2i(0, -1):
                        _try_jump())
        _load_level(0)

# ------------------------------------------------------------- level build

func _load_level(i: int) -> void:
        level_i = i
        for c in world.get_children():
                if c != level_label:
                        c.queue_free()
        grid = []
        solids.clear()
        walkers.clear()
        coins_nodes.clear()
        var raw: Array = LEVELS[i]
        cols = 0
        for r in raw:
                cols = maxi(cols, String(r).length())
        for r in range(raw.size()):
                var line := String(raw[r]).lpad(cols, " ")
                grid.append(line)
                for c in range(cols):
                        var ch := line[c]
                        var cell := Vector2i(c, r)
                        if ch == "#" or ch == "=":
                                solids[cell] = true
        # world visuals
        for c in solids:
                var s := Sprite2D.new()
                s.texture = load("res://assets/games/dario/%s.png"
                        % ("brick" if grid[c.y][c.x] == "=" else "ground"))
                s.centered = false
                s.scale = Vector2.ONE * (float(TS) / 96.0)
                s.position = Vector2(c.x * TS, c.y * TS)
                s.z_index = 1
                world.add_child(s)
        for r in range(grid.size()):
                for c in range(cols):
                        var ch: String = grid[r][c]
                        var at := Vector2(c * TS, r * TS)
                        if ch == "P":
                                p_pos = at + Vector2(16, TS - 58)
                        elif ch == "F":
                                flag_pos = at + Vector2(TS / 2.0, -TS / 2.0)
                        elif ch == "o":
                                var coin := Sprite2D.new()
                                coin.texture = load("res://assets/ui/coin.png")
                                coin.scale = Vector2.ONE * 0.42
                                coin.position = at + Vector2(TS / 2.0, TS / 2.0)
                                coin.z_index = 2
                                world.add_child(coin)
                                coins_nodes.append({"node": coin})
                        elif ch == "E":
                                var w := Sprite2D.new()
                                w.texture = _walk_tex
                                w.scale = Vector2.ONE * (float(TS) / 88.0)
                                w.position = at + Vector2(TS / 2.0, TS / 2.0)
                                w.z_index = 2
                                world.add_child(w)
                                walkers.append({"node": w, "pos": w.position,
                                        "dir": -1.0, "dead": false})
        flag_node = Sprite2D.new()
        flag_node.texture = load("res://assets/games/dario/flag.png")
        flag_node.scale = Vector2.ONE * 0.9
        flag_node.position = flag_pos
        flag_node.z_index = 2
        world.add_child(flag_node)
        player = Sprite2D.new()
        player.texture = _hero_idle
        player.scale = Vector2.ONE * 0.78
        player.z_index = 3
        world.add_child(player)
        p_vel = Vector2.ZERO
        _ending = false
        level_label.text = "LEVEL %d / %d" % [i + 1, LEVELS.size()]

# ---------------------------------------------------------------- controls

func _build_jump_button() -> void:
        var vp := get_viewport_rect().size
        var b := Arc.button("JUMP", Vector2(200, 96), 34, Arc.HOT, func():
                _try_jump())
        # v0.2.6: lifted above the banner strip (dario wears the banner now)
        b.position = Vector2(vp.x - 224, vp.y - 120 - banner_bottom())
        _hud.add_child(b)

func _try_jump() -> void:
        if on_ground and not _ending:
                p_vel.y = JUMP_V
                jump_held = true
                Jukebox.sfx("hop", -6.0)

# ------------------------------------------------------------------- tick

func _goga_tick(delta: float) -> void:
        if _ending:
                return
        # horizontal intent from held touch halves (the JUMP button eats its
        # own events; TouchKit only sees board touches)
        dir_held = 0
        if tk.is_down():
                var mid := get_viewport_rect().size.x / 2.0
                var p := tk.press_pos().x
                if p < mid - 30:
                        dir_held = -1
                elif p > mid + 30:
                        dir_held = 1
        # horizontal move + collide
        var want := float(dir_held) * RUN_MAX
        p_vel.x = move_toward(p_vel.x, want, ACCEL * delta)
        p_vel.y += GRAV * delta
        _move_and_collide(p_vel.x * delta, 0.0)
        _move_and_collide(0.0, p_vel.y * delta)
        # sprite state
        player.texture = _hero_jump if not on_ground else _hero_idle
        player.flip_h = dir_held < 0
        player.position = p_pos + Vector2(20, 38)
        _tick_walkers(delta)
        if _ending:
                return
        _pickups()
        # camera follows, clamped to the level strip
        var vp := get_viewport_rect().size
        var strip := cols * TS
        cam_x = clampf(p_pos.x + 20 - vp.x / 2.0, 0.0, maxf(0.0, strip - vp.x))
        world.position = Vector2(-cam_x, 0.0)
        # pit
        if p_pos.y > ROWS * TS + 120:
                _die()

func _move_and_collide(dx: float, dy: float) -> void:
        p_pos += Vector2(dx, dy)
        var box := Rect2(p_pos, Vector2(40, 56))
        if dy > 0.0:
                on_ground = false
        var c0 := Vector2i(int(floor(box.position.x / TS)),
                int(floor(box.position.y / TS)))
        var c1 := Vector2i(int(floor((box.position.x + box.size.x - 1) / TS)),
                int(floor((box.position.y + box.size.y - 1) / TS)))
        for cy in range(c0.y, c1.y + 1):
                for cx in range(c0.x, c1.x + 1):
                        if not solids.has(Vector2i(cx, cy)):
                                continue
                        var tile := Rect2(Vector2(cx * TS, cy * TS),
                                Vector2(TS, TS))
                        if not box.intersects(tile):
                                continue
                        if dy > 0.0:      # falling -> land
                                p_pos.y = tile.position.y - box.size.y
                                p_vel.y = 0.0
                                on_ground = true
                        elif dy < 0.0:    # rising -> bonk
                                p_pos.y = tile.position.y + tile.size.y
                                p_vel.y = 0.0
                        elif dx > 0.0:
                                p_pos.x = tile.position.x - box.size.x
                                p_vel.x = 0.0
                        elif dx < 0.0:
                                p_pos.x = tile.position.x + tile.size.x
                                p_vel.x = 0.0
                        box = Rect2(p_pos, Vector2(40, 56))

func _tick_walkers(delta: float) -> void:
        var pbox := Rect2(p_pos, Vector2(40, 56))
        for w in walkers:
                if bool(w["dead"]):
                        continue
                var node: Sprite2D = w["node"]
                var speed := 64.0
                var nx: float = w["pos"].x + float(w["dir"]) * speed * delta
                var feet_c := Vector2i(int(floor(nx / TS)),
                        int(floor((w["pos"].y + TS * 0.55) / TS)))
                var front_c := Vector2i(int(floor(
                        (nx + float(w["dir"]) * 30.0) / TS)),
                        int(floor(w["pos"].y / TS)))
                # turn at walls and ledges
                if solids.has(front_c) or not solids.has(feet_c):
                        w["dir"] = -float(w["dir"])
                        nx = w["pos"].x
                w["pos"] = Vector2(nx, w["pos"].y)
                node.position = w["pos"]
                node.flip_h = float(w["dir"]) > 0
                # player contact
                var wbox := Rect2(w["pos"] - Vector2(30, 30), Vector2(60, 56))
                if wbox.intersects(pbox):
                        if p_vel.y > 120.0 and pbox.position.y + pbox.size.y \
                                        < wbox.position.y + 34.0:
                                w["dead"] = true
                                node.queue_free()
                                p_vel.y = -520.0
                                add_score(5)
                                achievement_count("stomped", 1)
                                Jukebox.sfx("boom", -8.0, 1.4)
                        else:
                                _die()
                                return

func _pickups() -> void:
        var pbox := Rect2(p_pos, Vector2(40, 56))
        for cn in coins_nodes:
                if cn.has("got"):
                        continue
                var at: Vector2 = cn["node"].position
                if pbox.has_point(at):
                        cn["got"] = true
                        cn["node"].queue_free()
                        add_score(2)
                        add_run_coins(1)
                        Jukebox.sfx("coin", -6.0)
        # the flag ends the level
        if absf(p_pos.x + 20 - flag_pos.x) < TS * 0.7 \
                        and absf(p_pos.y + 28 - flag_pos.y) < TS * 1.4:
                _level_clear()

func _level_clear() -> void:
        if _ending:
                return
        _ending = true
        add_score(25)
        achievement_max("levels_done", level_i + 1)
        Jukebox.sfx("star", -2.0)
        var t := Arc.label("LEVEL CLEAR!", 64, Color(1, 1, 1))
        t.position = Vector2(get_viewport_rect().size.x / 2.0 - 190,
                get_viewport_rect().size.y / 2.0 - 40)
        t.z_index = 40
        world.add_child(t)
        var tw := create_tween()
        tw.tween_interval(0.9)
        tw.tween_callback(func():
                if level_i + 1 < LEVELS.size():
                        _load_level(level_i + 1)
                        _ending = false
                else:
                        check_achievements()
                        finish_run(score))

func _die() -> void:
        if _ending:
                return
        _ending = true
        Jukebox.sfx("boom", -2.0)
        check_achievements()
        var tw := create_tween().set_loops(3)
        tw.tween_property(world, "modulate", Color(1, 0.5, 0.5), 0.09)
        tw.tween_property(world, "modulate", Color.WHITE, 0.09)
        tw.finished.connect(func(): finish_run(score))
