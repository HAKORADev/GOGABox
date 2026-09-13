extends Node
## de_probe_r3b - the round-3 EVIDENCE probe, PART TWO: the clean rooms.
## P2: the wall face with ALL eaters frozen (nobody can kill the body) -
##     every frame logs phase/cell/from/to/t/px so a bounce cannot hide.
## P3: the eyes journey from a FAR cell (the eaten eater no longer sits
##     in the pen where the eyes branch rebirths it instantly).

var PM: GDScript
var g: GogaGame = null
var T := 0.0
var stage := "p2"
var stage_t := 0.0
var log_lines := []
var p2_start_x := 0.0
var p2_end_x := 0.0
var p2_max_x := -1e9
var p2_end_state := {}
var p2_sample := 0
var p3_history := []
var p3_seen_cells := {}

func _log(s: String) -> void:
        print(s)
        log_lines.append(s)

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        PM = load("res://game/games/pacman/pacman.gd")
        Box.reset_all()
        Box.bump_counter("pacman", "lore_start", 1)
        Box.bump_counter("pacman", "lore_end", 1)
        g = PM.new()
        g.game_id = "pacman"
        ScaleRule.apply(get_window())
        add_child(g)
        g.probe_reset(777)
        _log("=== DE PROBE R3b === board.x=%.1f cell_px=%.1f vp=%s"
                        % [g.board.x, g.cell_px, str(g._vp())])
        _freeze_eaters()
        # seat the body 1 cell before a shut right edge, driving right
        var seat := _find_wall_seat()
        g.player["cell"] = seat
        g.player["from"] = seat
        g.player["to"] = seat + Vector2i(1, 0)
        g.player["t"] = 0.0
        g.player["moving"] = true
        g.player["dir"] = Vector2i(1, 0)
        p2_start_x = g._player_px().x
        _log(("--- P2 THE WALL FACE, CLEAN (from=%s to=%s) ---")
                        % [str(seat), str(seat + Vector2i(1, 0))])

func _freeze_eaters() -> void:
        for e in g.eaters:
                e["state"] = "pen"
                e["pen_t"] = 99999.0
                e["moving"] = false

func _dir_name(d: Vector2i) -> String:
        if d == Vector2i(-1, 0):
                return "L"
        if d == Vector2i(1, 0):
                return "R"
        if d == Vector2i(0, -1):
                return "U"
        if d == Vector2i(0, 1):
                return "D"
        return str(d)

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

func _process(delta: float) -> void:
        if g == null:
                return
        delta = minf(delta, 1.0 / 20.0)
        T += delta
        stage_t += delta
        match stage:
                "p2":
                        _run_p2(delta)
                "p3":
                        _run_p3(delta)
                "done":
                        pass

func _run_p2(delta: float) -> void:
        g.probe_step(delta)
        p2_sample += 1
        var px: Vector2 = g._player_px()
        if px.x > p2_max_x:
                p2_max_x = px.x
        if p2_sample % 3 == 0 or not g.player["moving"]:
                _log(("  [%.2f] phase=%s cell=%s from=%s to=%s t=%.2f "
                                + "moving=%s px=%.1f lives=%d")
                                % [T, g.phase, str(g.player["cell"]),
                                str(g.player["from"]), str(g.player["to"]),
                                g.player["t"], g.player["moving"], px.x,
                                g.lives])
        if not g.player["moving"] and g.phase == "run":
                p2_end_x = px.x
                p2_end_state = {
                        "cell": str(g.player["cell"]),
                        "from": str(g.player["from"]),
                        "to": str(g.player["to"]),
                        "px": px.x}
                _log(("  P2 STOP: start_x=%.1f max_x=%.1f end_x=%.1f "
                                + "end=%s") % [p2_start_x, p2_max_x, p2_end_x,
                                str(p2_end_state)])
                if p2_end_x < p2_start_x - 2.0:
                        _log(("  !! P2 THE STEP-BACK: the body ended %.1fpx "
                                        + "BEHIND its start") % [p2_start_x
                                        - p2_end_x])
                elif p2_end_x < p2_max_x - 2.0:
                        _log(("  !! P2 THE STEP-BACK: the body fell back "
                                        + "%.1fpx from its deepest point")
                                        % [p2_max_x - p2_end_x])
                else:
                        _log("  P2 OK: the body waits at its deepest point "
                                        + "(the wall face)")
                _start_p3()
        elif stage_t > 6.0:
                _log("  P2 TIMEOUT (still moving?)")
                _start_p3()

func _start_p3() -> void:
        stage = "p3"
        stage_t = 0.0
        g.probe_reset(314)
        g.probe_step(1.5)
        _freeze_eaters()
        # free ONE eater far from the pen, then eat it: watch the eyes
        var e: Dictionary = g.eaters[1]
        e["state"] = "roam"
        e["pen_t"] = 0.0
        var far := Vector2i(1, 1)
        if g._in_plaza(far):
                far = Vector2i(1, g.rows - 2)
        e["cell"] = far
        e["from"] = far
        e["to"] = far
        e["t"] = 0.0
        e["moving"] = false
        e["dir"] = Vector2i(-1, 0)
        g.probe_step(0.05)      # it takes one honest step (roam pick)
        e["state"] = "eyes"     # EATEN where it stands
        e["moving"] = false
        _log(("--- P3 THE EYES JOURNEY (eater %s eaten at %s, pen at %s) ---")
                        % [e["id"], str(e["cell"]), str(g.plaza)])

func _run_p3(delta: float) -> void:
        g.probe_step(delta)
        var e: Dictionary = g.eaters[1]
        if int(stage_t * 5.0) != int((stage_t - delta) * 5.0):
                var line := "%s@%s" % [_dir_name(e["dir"]), str(e["cell"])]
                p3_history.append(line)
                p3_seen_cells[str(e["cell"])] = int(
                                p3_seen_cells.get(str(e["cell"]), 0)) + 1
        var home: bool = e["state"] != "eyes"
        if home or stage_t > 25.0:
                _log(("  P3 end after %.1fs: state=%s cell=%s")
                                % [stage_t, e["state"], e["cell"]])
                _log("  P3 path: %s" % str(p3_history))
                _log("  P3 cell census: %s" % str(p3_seen_cells))
                if not home:
                        _log("  !! P3 THE OSCILLATION: the eyes never "
                                        + "reached home")
                else:
                        _log("  P3 OK: the eyes came home and rebirthed")
                _finish()

func _finish() -> void:
        _log("=== PROBE R3b END ===")
        var f := FileAccess.open("/tmp/probe_r3b.log", FileAccess.WRITE)
        for l in log_lines:
                f.store_line(l)
        f.close()
        get_tree().quit(0)
