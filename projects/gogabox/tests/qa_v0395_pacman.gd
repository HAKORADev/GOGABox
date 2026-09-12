extends Node
## qa_v0395_pacman - the v0.3.9-5 round probe (the qa_v0393 law):
## scene-level laws for the DOT EATER graduate, driven headless or on the
## Xvfb rig, exit 0 = pass. THE LAWS: the junction buffer (the owner's
## 5/7-8/10 mechanic), the wrap tunnels, the rush (blue, 7s, slower
## edible eaters), the life law (3 start, 500 dots = one more), the score
## law (mazes only), the coin cadence, and the endless random maze
## (fresh every maze, always connected).

var fails := 0
var g: GogaGame = null
var PM: GDScript

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.reset_all()
        # the lore never blocks a probe (the counter is the gate)
        Box.bump_counter("pacman", "lore_start", 1)
        Box.bump_counter("pacman", "lore_end", 1)
        PM = load("res://game/games/pacman/pacman.gd")
        print("=== qa_v0395_pacman ===")
        _boot()

func _check(cond: bool, why := "") -> int:
        print("  %s: %s" % ["PASS" if cond else "FAIL", why])
        return 0 if cond else 1

func _boot() -> void:
        g = PM.new()
        g.game_id = "pacman"
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        # the boot gate: TAP ANYWHERE TO START (the boot state)
        fails += _check(g.phase == "boot", "de: the boot gate waits (tap anywhere)")
        g.probe_reset(4242)
        fails += _check(g.phase == "ready", "de: probe_reset seats the READY beat")
        g.probe_step(1.5)
        fails += _check(g.phase == "run", "de: the READY beat flows into the run")
        fails += _check(g.lives == 3, "de: the run starts with 3 life points")
        fails += _check(g.dots_left > 0 and g.dots.size() == g.dots_left,
                "de: the maze wears its dots (%d)" % g.dots_left)
        fails += _check(g.score == 0, "de: dots are NOT score - the run opens 0")
        fails += _check(g.rush_chip != null and not g.rush_chip.visible,
                "de: the rush countdown widget hides while calm")

        # ---------------- THE JUNCTION BUFFER LAW ----------------
        # find a REAL straight corridor with a junction 4+ cells ahead
        # (walking OPEN edges only - a seat inside a wall is a lie)
        var hall := _find_corridor()
        fails += _check(hall.x >= 0,
                "de: the probe found a real corridor (from %s)" % str(hall))
        if hall.x >= 0:
                var jx := _junction_x(hall)
                # "we are at 5" of a 10-long path: a swipe is NOT recorded
                _seat_corridor(Vector2i(hall.x, hall.y), Vector2i(1, 0), 0.0)
                g.buf = Vector2i.ZERO
                var far_dir := Vector2i(0, -1)
                if PM.is_open(g.g, g.cols, jx, hall.y, Vector2i(0, 1)):
                        far_dir = Vector2i(0, 1)
                g._swipe_dir(far_dir, Vector2())
                fails += _check(g.buf == Vector2i.ZERO,
                        "de: a swipe too far from the corner is not recorded")
                # "at 7-8": seat two cells before the corner, mid-cell
                _seat_corridor(Vector2i(jx - 2, hall.y), Vector2i(1, 0), 0.2)
                var want_d := 2.0 - 0.2
                g.buf = Vector2i.ZERO
                g._swipe_dir(far_dir, Vector2())
                fails += _check(g.buf == far_dir,
                        "de: a swipe in the window is recorded (dist %.1f)" % want_d)
                # "one at 7-8 then another": the slot stays single
                g._swipe_dir(-far_dir, Vector2())
                fails += _check(g.buf == far_dir,
                        "de: a second swipe while the slot is full is not recorded")
                # the slot spends itself AT the corner: the turn applies
                var dir_before: Vector2i = g.player["dir"]
                for i in 12:
                        g.probe_step(0.2)
                fails += _check(g.player["dir"] == far_dir,
                                "de: the buffered turn applies at the corner")
                g.buf = Vector2i.ZERO
        # "doing it at 10 instantly": swiping INTO an open way while
        # standing turns now
        _seat_stopped(Vector2i(3, 5))
        if PM.is_open(g.g, g.cols, 3, 5, Vector2i(0, 1)):
                g._swipe_dir(Vector2i(0, 1), Vector2())
                fails += _check(g.player["moving"] and g.player["dir"] == Vector2i(0, 1),
                        "de: a swipe at the junction itself turns instantly")
        # THE MERCY: reversal mid-corridor flips the flight in place
        _seat_corridor(Vector2i(3, 5), Vector2i(1, 0), 0.5)
        g._swipe_dir(Vector2i(-1, 0), Vector2())
        fails += _check(g.player["dir"] == Vector2i(-1, 0)
                        and absf(float(g.player["t"]) - 0.5) < 0.01,
                "de: the reversal is instant and keeps the progress")

        # ---------------- THE WRAP LAW ----------------
        var wrap_row: int = g.wraps[0]
        _seat_corridor(Vector2i(0, wrap_row), Vector2i(-1, 0), 0.99)
        g.probe_step(0.4)
        var pc: Vector2i = g.player["cell"]
        fails += _check(pc.x >= g.cols - 2,
                "de: the wrap tunnel joins the sides (arrived at x=%d)" % pc.x)

        # ---------------- THE RUSH LAW ----------------
        var power := Vector2i(-1, -1)
        for key in g.dots.keys():
                if String(g.dots[key]) == "p":
                        power = key
                        break
        fails += _check(power.x >= 0, "de: the maze wears a BLUE magical dot")
        if power.x >= 0:
                _seat_stopped(power)
                g._eat_at(power)
                fails += _check(absf(g.rush_left - PM.RUSH_TIME) < 0.01
                                and g.rush_chip.visible,
                        "de: the BLUE dot starts the 7s rush + the widget shows")
                # the rush slows EVERY roaming body (pure law - no clock:
                # a stopped player under a running horde dies honestly)
                for e in g.eaters:
                        if e["state"] == "pen":
                                e["state"] = "fright"
                var slowed := true
                for e in g.eaters:
                        if e["state"] == "eyes":
                                continue
                        if g._eater_speed(e) >= PM.EATER_BASE_SPEED:
                                slowed = false
                fails += _check(slowed and g.eaters.size() > 0,
                        "de: the rush slows the ball-eaters")
                # pick any eater as the swallow victim (state it fright)
                var roamer: Dictionary = g.eaters[0]
                roamer["state"] = "fright"
                # swallow: seat the eater ON Balldozer
                roamer["cell"] = g.player["cell"]
                roamer["from"] = g.player["cell"]
                roamer["to"] = g.player["cell"]
                roamer["t"] = 0.0
                roamer["moving"] = false
                g._check_collisions()
                fails += _check(roamer["state"] == "eyes",
                        "de: a frightened ball-eater is EDIBLE (eyes run home)")
                fails += _check(g.eaten_this_rush >= 1,
                        "de: the swallow counts")
        # the rush ends: the widget hides and the hunt resumes
        g.rush_left = 0.01
        g.probe_step(0.05)
        fails += _check(not g.rush_chip.visible,
                "de: the rush countdown widget hides when it ends")

        # ---------------- THE LIFE LAW ----------------
        g.probe_reset(4242)
        g.probe_step(1.5)
        fails += _check(g.lives == 3, "de: still 3 lives before the bite")
        g._lose_life()
        g.probe_step(1.6)
        fails += _check(g.lives == 2 and g.phase == "ready",
                "de: a catch costs a life and the READY beat re-seats")
        # the 500th dot grants one
        g.dots_run = PM.DOTS_PER_LIFE - 1
        g.life_next = PM.DOTS_PER_LIFE
        var anydot := Vector2i(-1, -1)
        for key in g.dots.keys():
                if String(g.dots[key]) == "d":
                        anydot = key
                        break
        if anydot.x >= 0:
                var lives_before: int = g.lives
                g._eat_at(anydot)
                fails += _check(g.lives == lives_before + 1,
                        "de: the 500th dot grants ONE extra life")

        # ---------------- THE SCORE + COIN LAWS ----------------
        var score_before: int = g.score
        var keep := Vector2i(-1, -1)
        for key in g.dots.keys():
                if String(g.dots[key]) == "d":
                        keep = key
                        break
        fails += _check(keep.x >= 0, "de: a plain dot exists to finish on")
        g.dots = {keep: "d"}
        g.dots_left = 1
        g._eat_at(keep)
        fails += _check(g.score == score_before + 1 and g.phase == "clear",
                "de: every dot eaten = the maze is yours (+1)")
        fails += _check(g.dots_run > 0 and g.dots_lbl.text == str(g.dots_run),
                "de: the dot counter counts dots, never score")
        g.probe_step(1.8)
        fails += _check(g.phase == "ready" and g.maze_i == 1
                        and g.dots_left > 0,
                "de: the next maze weaves itself (endless, maze %d)" % g.maze_i)
        # THE RANDOM LAW: two seeds never weave the same maze
        var a: Dictionary = PM.gen_maze(g.cols, g.rows, _rng(11))
        var b: Dictionary = PM.gen_maze(g.cols, g.rows, _rng(12))
        fails += _check(_grid_key(a["g"]) != _grid_key(b["g"]),
                "de: the mazes are RANDOM - two seeds differ")
        # THE COIN LAW: entering the 4th maze wears a coin (after each 3)
        g.maze_i = PM.COIN_EVERY
        g._new_maze()
        var has_coin := false
        for key in g.dots.keys():
                if String(g.dots[key]) == "c":
                        has_coin = true
        fails += _check(has_coin,
                "de: after each 3 mazes a GOGACoin rests where a dot was")

        # ---------------- THE EATER DRIVES ----------------
        fails += _check(g.eaters.size() == 4, "de: four ball-eaters hunt")
        var kinds := {}
        for e in g.eaters:
                kinds[String(e["kind"])] = true
        fails += _check(kinds.size() == 4,
                "de: four drives - hunter, ambusher, flanker, mood")

        print("=== qa_v0395_pacman: %s ===" % ("PASS" if fails == 0
                        else "%d FAILS" % fails))
        get_tree().quit(0 if fails == 0 else 1)

func _rng(seed_v: int) -> RandomNumberGenerator:
        var r := RandomNumberGenerator.new()
        r.seed = seed_v
        return r

## seat Balldozer mid-flight on a cell moving in dir (t = progress)
func _seat_corridor(cell: Vector2i, dir: Vector2i, t: float) -> void:
        g.player["cell"] = cell
        g.player["from"] = cell
        g.player["to"] = cell + g._wrap_to(cell, dir)
        g.player["t"] = t
        g.player["moving"] = true
        g.player["dir"] = dir
        g.phase = "run"

func _seat_stopped(cell: Vector2i) -> void:
        g.player["cell"] = cell
        g.player["from"] = cell
        g.player["to"] = cell
        g.player["t"] = 0.0
        g.player["moving"] = false
        # a KNOWN stale face (v0.3.9-6): the seat keeps whatever dir the
        # previous phase left - on the new size ladder that stale dir can BE
        # the swiped dir, and the `dir == pd` no-op swallowed the swipe (the
        # old 19x11 seed never collided; the 15x9 one does). The stand-at-a-
        # wall law is what this probe tests - seat the face honestly.
        g.player["dir"] = Vector2i(-1, 0)
        g.phase = "run"

## a horizontal corridor whose right run reaches a junction 4+ cells on
func _find_corridor() -> Vector2i:
        for y in range(1, g.rows - 1):
                for x in range(1, g.cols - 5):
                        if not PM.is_open(g.g, g.cols, x, y, Vector2i(1, 0)):
                                continue
                        var jx := _junction_x(Vector2i(x, y))
                        if jx - x >= 4 and PM.is_open(g.g, g.cols, jx, y,
                                        Vector2i(0, 1)):
                                return Vector2i(x, y)
        return Vector2i(-1, -1)

## the first junction x to the right of the corridor start (open edges only)
func _junction_x(from: Vector2i) -> int:
        var cur := from
        for i in g.cols:
                if not PM.is_open(g.g, g.cols, cur.x, cur.y, Vector2i(1, 0)):
                        return cur.x          # the walk stops here anyway
                cur = cur + Vector2i(1, 0)
                for nd in [Vector2i(0, 1), Vector2i(0, -1)]:
                        if PM.is_open(g.g, g.cols, cur.x, cur.y, nd):
                                return cur.x
        return -1

func _grid_key(gr: Array) -> String:
        var s := ""
        for row in gr:
                for c in row:
                        s += "%d%d%d%d" % [1 if c["t"] else 0,
                                        1 if c["b"] else 0,
                                        1 if c["l"] else 0,
                                        1 if c["r"] else 0]
        return s
