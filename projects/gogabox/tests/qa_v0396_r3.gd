extends Node
## qa_v0396_r3 - the v0.3.9-6 ROUND 3 repair probe (the qa_v0396 law):
## the owner's third report round, driven headless, exit 0 = pass.
##   1. THE TUNNEL LAW: the wrap seam opens INTO the maze - a body drives
##      THROUGH the seam and keeps going (no island, no stray outline).
##   2. THE WALL SEAT: a wall face stops the body AT the arrival cell,
##      from=to=cell, at its deepest pixel (no one-step-back).
##   3. THE HONEST EYES: an eaten eater's eyes BFS home to its OWN seat,
##      no ping-pong, and the round body returns at the seat.
##   4. THE PEN-EXIT LAW: every pen body leaves through the gate and a
##      live body NEVER re-enters the plaza (the house ban).
##   5. THE SEAT LAW II: the four eaters sit at the pen's four corners.
##   6. THE DEATH SEQUENCE: the catch seats Balldozer (swallowed), every
##      eater dies to eyes at once, the eyes fly home, THEN Balldozer's
##      eyes walk to the start place and the READY beat re-seats all -
##      the world BREATHES the whole way (no stall, no teleport).
##   7. THE ORDER RAIL: an order records ANYWHERE ahead (beyond the old
##      2.5-cell window), TWO slots build, FIFO spends at fitting cells.

var fails := 0
var PM: GDScript

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        print("=== qa_v0396_r3 ===")
        Box.reset_all()
        Box.bump_counter("pacman", "lore_start", 1)
        Box.bump_counter("pacman", "lore_end", 1)
        PM = load("res://game/games/pacman/pacman.gd")
        _tunnel_static()
        await _scene_game()
        _seats(g)
        _tunnel_live(g)
        _wall_seat(g)
        _rail(g)
        _eyes(g)
        _pen_exit(g)
        _death_seq(g)
        print("=== qa_v0396_r3: %s ===" % ("PASS" if fails == 0
                        else "%d FAILS" % fails))
        get_tree().quit(0 if fails == 0 else 1)

func _check(cond: bool, why := "") -> void:
        print("  %s: %s" % ["PASS" if cond else "FAIL", why])
        if not cond:
                fails += 1

# ---------------------------------------------------------------- the rig
var g: GogaGame = null

func _scene_game() -> void:
        g = PM.new()
        g.game_id = "pacman"
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame

func _fresh(seed_v: int) -> void:
        g.probe_reset(seed_v)
        g.probe_step(1.5)          # the READY beat done, phase = run
        g.mercy_t = 99999.0        # nobody dies while the probe watches

func _freeze_eaters() -> void:
        for e in g.eaters:
                e["state"] = "pen"
                e["pen_t"] = 99999.0
                e["moving"] = false

func _seat_player(c: Vector2i, d: Vector2i) -> void:
        g.player["cell"] = c
        g.player["from"] = c
        g.player["to"] = c + d
        g.player["t"] = 0.0
        g.player["moving"] = true
        g.player["dir"] = d

func _run(secs: float) -> void:
        var steps := int(secs * 60.0)
        for i in steps:
                g.probe_step(1.0 / 60.0)

## a corridor of `need` straight cells ending at a decision cell with an
## open perpendicular way; returns {} when none exists on this seed
func _find_rail_run(need: int) -> Dictionary:
        for y in range(1, g.rows - 1):
                for x in range(1, g.cols - 1):
                        for dv in [Vector2i(1, 0), Vector2i(0, 1)]:
                                var d: Vector2i = dv
                                var c := Vector2i(x, y)
                                var straight := 0
                                var jcell := Vector2i(-9, -9)
                                var ok := true
                                for step in need + 1:
                                        if not PM.is_open(g.g, g.cols,
                                                        c.x, c.y, d):
                                                ok = false
                                                break
                                        c += d
                                        straight += 1
                                        # a perpendicular open way?
                                        var perp: Vector2i = Vector2i(
                                                        -d.y, d.x)
                                        if PM.is_open(g.g, g.cols, c.x,
                                                        c.y, perp) \
                                                        or PM.is_open(g.g,
                                                        g.cols, c.x, c.y,
                                                        -perp):
                                                jcell = c
                                                break
                                if ok and jcell.x > -8 \
                                                and straight >= need:
                                        var jc: Vector2i = jcell
                                        var perp2: Vector2i = Vector2i(
                                                        -d.y, d.x)
                                        var o1: Vector2i = perp2
                                        if not PM.is_open(g.g, g.cols,
                                                        jc.x, jc.y, o1):
                                                o1 = -perp2
                                        # the second order must differ from
                                        # the run dir (a same-way swipe is
                                        # an honest no-op, not an order):
                                        # the OTHER perpendicular always is
                                        var o2: Vector2i = -perp2
                                        return {"start": Vector2i(x, y),
                                                "dir": d, "jcell": jc,
                                                "o1": o1, "o2": o2}
        return {}

# ------------------------------------------------------- 1. THE TUNNEL LAW
func _tunnel_static() -> void:
        for seed_v in [11, 42, 777, 4242]:
                var rng := RandomNumberGenerator.new()
                rng.seed = seed_v
                var sz: Vector2i = PM.gen_sizes(seed_v % 7)
                var m: Dictionary = PM.gen_maze(sz.x, sz.y, rng)
                var gg: Array = m["g"]
                var bad := 0
                for y in m["wraps"]:
                        # the seam cells open INTO the maze (both sides)
                        if not PM.is_open(gg, sz.x, 0, y, Vector2i(1, 0)):
                                bad += 1
                        if not PM.is_open(gg, sz.x, sz.x - 1, y,
                                        Vector2i(-1, 0)):
                                bad += 1
                        # the tunnel FLOWS: the far seam is walkable
                        var dmap: Dictionary = PM.bfs_steps(gg, sz.x,
                                        Vector2i(0, y))
                        if not dmap.has(Vector2i(sz.x - 1, y)):
                                bad += 1
                _check(bad == 0,
                                "de: seed %d every wrap tunnel opens INTO the maze and FLOWS (%d bad)"
                                % [seed_v, bad])
                # the stray outline source is gone: the spawn's reach map
                # covers the seam cells (they are honest corridor now)
                var seen: Dictionary = PM.reach(gg, sz.x,
                                Vector2i(m["plaza"].x, m["plaza"].y + 2))
                var miss := 0
                for y in m["wraps"]:
                        if not seen.has(Vector2i(0, y)):
                                miss += 1
                        if not seen.has(Vector2i(sz.x - 1, y)):
                                miss += 1
                _check(miss == 0,
                                "de: seed %d the seam cells are reachable corridor (no pocket islands)"
                                % seed_v)

func _tunnel_live(gg: GogaGame) -> void:
        _fresh(4242)
        _freeze_eaters()
        var row: int = gg.wraps[0]
        # the seat is the last node before the seam: (1,row) -> (0,row) is
        # the tunnel law's own open edge. The body drives LEFT: it must
        # visit x=0, EMERGE at x=cols-1, and KEEP GOING into the maze.
        _seat_player(Vector2i(1, row), Vector2i(-1, 0))
        var saw_seam := false
        var saw_far := false
        var kept := false
        for i in 300:
                gg.probe_step(1.0 / 60.0)
                var c: Vector2i = gg.player["cell"]
                if c.x == 0 and c.y == row:
                        saw_seam = true
                if saw_seam and c.x == gg.cols - 1 and c.y == row:
                        saw_far = true
                if saw_far and c.x <= gg.cols - 2:
                        kept = true
                        break
        _check(saw_seam,
                        "de: the body REACHES the seam cell (x=0) going left")
        _check(saw_far,
                        "de: the body CROSSES the seam and emerges at x=cols-1 (pass-through)")
        _check(kept,
                        "de: the tunnel KEEPS FLOWING: the body walks past the far seam into the maze")

# ------------------------------------------------------- 2. THE WALL SEAT
func _wall_seat(gg: GogaGame) -> void:
        _fresh(777)
        _freeze_eaters()
        var seat := _find_wall_seat()
        _check(seat.x >= 0, "de: a wall-seat corridor exists on seed 777")
        if seat.x < 0:
                return
        _seat_player(seat, Vector2i(1, 0))
        var start_x: float = gg._player_px().x
        var max_x := start_x
        var stopped := false
        for i in 240:
                gg.probe_step(1.0 / 60.0)
                max_x = maxf(max_x, gg._player_px().x)
                if not gg.player["moving"]:
                        stopped = true
                        break
        _check(stopped, "de: the wall face STOPS the body")
        var end_x: float = gg._player_px().x
        var ok_seat: bool = gg.player["from"] == gg.player["cell"] \
                        and gg.player["to"] == gg.player["cell"]
        _check(ok_seat,
                        "de: the wall seat is from=to=cell (from %s to %s)"
                        % [str(gg.player["from"]), str(gg.player["to"])])
        _check(end_x >= start_x - 2.0 and end_x >= max_x - 2.0,
                        "de: no step-back: the body waits at its deepest px (start %.1f max %.1f end %.1f)"
                        % [start_x, max_x, end_x])
        # the way out is the finger: an open perpendicular starts instantly
        var d := Vector2i(0, -1)
        if not PM.is_open(gg.g, gg.cols, gg.player["cell"].x,
                        gg.player["cell"].y, d):
                d = Vector2i(0, 1)
        if PM.is_open(gg.g, gg.cols, gg.player["cell"].x,
                        gg.player["cell"].y, d):
                gg._swipe_dir(d)
                _check(gg.player["moving"],
                                "de: a swipe at the wall face starts instantly")

func _find_wall_seat() -> Vector2i:
        for y in range(1, g.rows - 1):
                for x in range(2, g.cols - 2):
                        var shut_r: bool = not PM.is_open(g.g, g.cols,
                                        x, y, Vector2i(1, 0))
                        var open_l: bool = PM.is_open(g.g, g.cols,
                                        x, y, Vector2i(-1, 0))
                        var open_l2: bool = PM.is_open(g.g, g.cols,
                                        x - 1, y, Vector2i(1, 0))
                        if shut_r and open_l and open_l2:
                                return Vector2i(x - 1, y)
        return Vector2i(-1, -1)

# --------------------------------------------------------- 5. THE SEATS
func _seats(gg: GogaGame) -> void:
        _fresh(4242)
        var want := [Vector2i(-1, -1), Vector2i(1, -1),
                        Vector2i(-1, 1), Vector2i(1, 1)]
        var got: Array = []
        for i in gg.eaters.size():
                var e: Dictionary = gg.eaters[i]
                var want_c: Vector2i = gg.plaza + want[i]
                got.append(e["cell"])
                _check(e["cell"] == want_c and e["state"] == "pen",
                                "de: eater %d sits at its OWN corner %s (got %s)"
                                % [i, str(want_c), str(e["cell"])])
        var uniq := {}
        for c in got:
                uniq[c] = true
        _check(uniq.size() == 4,
                        "de: the four seats are four DIFFERENT cells (no overlap)")

# ----------------------------------------------------- 7. THE ORDER RAIL
func _rail(gg: GogaGame) -> void:
        _fresh(777)
        _freeze_eaters()
        var run := _find_rail_run(4)
        _check(not run.is_empty(),
                        "de: a rail run (4 straight then a T) exists on seed 777")
        if run.is_empty():
                return
        _seat_player(run["start"], run["dir"])
        gg.probe_step(1.0 / 60.0)          # the run begins
        # record BEYOND the old 2.5-cell window: the old law dropped it
        var waited := 0.0
        while float(gg._junction_info()["d"]) <= 2.6 and waited < 4.0:
                gg.probe_step(1.0 / 60.0)
                waited += 1.0 / 60.0
        var dist_at_rec: float = float(gg._junction_info()["d"])
        gg._swipe_dir(run["o1"])
        _check(gg.rail.size() == 1 and gg.rail[0] == run["o1"],
                        "de: an order records ANYWHERE ahead (dist %.1f cells, rail %s)"
                        % [dist_at_rec, str(gg.rail)])
        gg._swipe_dir(run["o2"])
        _check(gg.rail.size() == 2,
                        "de: TWO orders build (rail %s)" % str(gg.rail))
        gg._swipe_dir(run["o1"])
        _check(gg.rail.size() == 2 and gg.rail[1] == run["o1"],
                        "de: a full rail takes the NEWEST order (FIFO shift)")
        # the ride: the head order spends at the first fitting decision
        var spent_dir := Vector2i(9, 9)
        var guard := 0.0
        var prev_size := 2
        while guard < 10.0 and not gg.rail.is_empty():
                gg.probe_step(1.0 / 60.0)
                guard += 1.0 / 60.0
                if gg.rail.size() < prev_size:
                        prev_size = gg.rail.size()
                        if spent_dir == Vector2i(9, 9):
                                spent_dir = gg.player["dir"]
        _check(spent_dir == run["o1"],
                        "de: the head order spent FIRST at the fitting cell (dir %s)"
                        % str(spent_dir))
        _check(gg.rail.is_empty(),
                        "de: the rail EMPTIES on the ride (orders spend or die honestly)")
        # and the body never flew into a wall: it still rides a real way
        var open_now := false
        for d2 in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1),
                        Vector2i(0, -1)]:
                if PM.is_open(gg.g, gg.cols, gg.player["cell"].x,
                                gg.player["cell"].y, d2):
                        open_now = true
        _check(open_now, "de: the body rides honest corridor the whole way")

# ------------------------------------------------------ 3. THE HONEST EYES
func _eyes(gg: GogaGame) -> void:
        _fresh(314)
        _freeze_eaters()
        var e: Dictionary = gg.eaters[1]     # its own seat: plaza + (1,-1)
        var far := Vector2i(1, 1)
        if gg._in_plaza(far):
                far = Vector2i(1, gg.rows - 2)
        e["state"] = "roam"
        e["pen_t"] = 0.0
        e["cell"] = far
        e["from"] = far
        e["to"] = far
        e["t"] = 0.0
        e["moving"] = false
        gg.probe_step(0.05)
        e["state"] = "eyes"                  # EATEN where it stands
        e["moving"] = false
        var seat: Vector2i = gg.plaza + Vector2i(e["corner"])
        var visits := {}
        var home_t := -1.0
        var flip_cell := Vector2i(-9, -9)
        var t := 0.0
        while t < 15.0:
                gg.probe_step(1.0 / 60.0)
                t += 1.0 / 60.0
                var key := str(e["cell"])
                visits[key] = int(visits.get(key, 0)) + 1
                if e["state"] != "eyes":
                        home_t = t
                        flip_cell = e["cell"]
                        break
        _check(home_t > 0.0,
                        "de: the eaten eyes reach home (%.2fs, no ping-pong)"
                        % home_t)
        if home_t > 0.0:
                _check(flip_cell == seat,
                                "de: the eyes arrive at their OWN seat %s (got %s)"
                                % [str(seat), str(flip_cell)])
        var worst := 0
        for k in visits:
                worst = maxi(worst, visits[k])
        _check(worst <= 12,
                        "de: no oscillation: no cell visited more than 12 frames (worst %d)"
                        % worst)
        # the round body returns and hunts again (the rebirth law)
        _check(e["state"] == "roam" or e["state"] == "fright",
                        "de: the body RE-APPEARS at the seat and hunts (state %s)"
                        % str(e["state"]))

# ------------------------------------------------- 4. THE PEN-EXIT LAW
func _pen_exit(gg: GogaGame) -> void:
        _fresh(4242)
        var left := [false, false, false, false]
        var violations := 0
        var outside := 0
        var t := 0.0
        while t < 25.0 and outside < 4:
                gg.probe_step(1.0 / 60.0)
                t += 1.0 / 60.0
                outside = 0
                for i in gg.eaters.size():
                        var e: Dictionary = gg.eaters[i]
                        if gg._in_plaza(e["cell"]):
                                if left[i]:
                                        violations += 1   # the house ban
                        else:
                                left[i] = true
                                outside += 1
        _check(outside == 4,
                        "de: ALL FOUR pen bodies leave through the gate (%d out at %.1fs)"
                        % [outside, t])
        _check(violations == 0,
                        "de: THE HOUSE BAN holds: no live body re-enters the plaza (%d violations)"
                        % violations)

# ------------------------------------------------ 6. THE DEATH SEQUENCE
func _death_seq(gg: GogaGame) -> void:
        _fresh(4242)
        # the quartet ROAMS first (all four out by ~4s - the pen-exit law)
        # and Balldozer stands FAR from home: the sequence must EARN it
        _run(6.0)
        _seat_player(Vector2i(1, 1), Vector2i(1, 0))
        gg.player["moving"] = false
        var far_from_home: bool = gg.player["cell"] != gg._spawn_cell()
        _check(far_from_home,
                        "de: the catch lands far from the start place (cell %s)"
                        % str(gg.player["cell"]))
        var roaming := 0
        for e in gg.eaters:
                if e["state"] == "roam" or e["state"] == "fright":
                        roaming += 1
        _check(roaming == 4,
                        "de: all four eaters are OUT when the catch lands (%d roaming)"
                        % roaming)
        var start_lives: int = gg.lives
        gg._lose_life()          # the catch lands
        _check(gg.lives == start_lives - 1,
                        "de: the catch costs one life (%d left)" % gg.lives)
        _check(gg.phase == "dying" and gg.dying_phase == "ghosts",
                        "de: the sequence opens on the GHOSTS' fly-home")
        var swallowed: bool = not gg.player["moving"] \
                        and gg.player["from"] == gg.player["cell"] \
                        and gg.player["to"] == gg.player["cell"]
        _check(swallowed,
                        "de: THE SWALLOW SEATING: the body seats at the catch cell")
        var all_eyes := true
        for e in gg.eaters:
                if e["state"] != "eyes":
                        all_eyes = false
        _check(all_eyes, "de: EVERY eater dies to eyes at once")
        # THE WORLD BREATHES: the eyes actually fly (cells move, no stall)
        var before := []
        for e in gg.eaters:
                before.append(e["cell"])
        _run(0.5)
        var moved := 0
        for i in gg.eaters.size():
                if gg.eaters[i]["cell"] != before[i]:
                        moved += 1
        _check(moved > 0,
                        "de: no stall - the eyes FLY during the sequence (%d moved in 0.5s)"
                        % moved)
        # phase one ends when every body is home; phase two is Balldozer's
        var t := 0.0
        var walked := false
        var prev_cell: Vector2i = gg.player["cell"]
        while t < 25.0 and gg.phase == "dying":
                gg.probe_step(1.0 / 60.0)
                t += 1.0 / 60.0
                if gg.dying_phase == "player" \
                                and gg.player["cell"] != prev_cell:
                        walked = true
                        prev_cell = gg.player["cell"]
        _check(gg.phase != "dying",
                        "de: the sequence COMPLETES (%.1fs - ghosts home, then Balldozer's walk)"
                        % t)
        _check(walked,
                        "de: Balldozer's eyes WALK to the start place (no teleport)")
        var spawn: Vector2i = gg._spawn_cell()
        _check(gg.phase == "ready" and gg.player["cell"] == spawn,
                        "de: the body re-appears at the START place into the READY beat (cell %s)"
                        % str(gg.player["cell"]))
        var seated := true
        for e in gg.eaters:
                if e["state"] != "pen":
                        seated = false
        _check(seated, "de: the quartet re-seats in the pen for the next life")
