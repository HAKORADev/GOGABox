extends Node
## de_flight_rec - THE FLIGHT RECORDER (the owner's video stand-in):
## the owner filmed their finger and the run; the sandbox cannot open
## that link (it wears their Google session), so THIS rig films the same
## thing from inside: the REAL game boots, REAL finger gestures ride the
## engine queue, and every swipe's DISPOSITION is logged with the
## player's per-frame state. A movement corruption cannot hide here:
## each swipe is classified APPLIED / BUFFERED / REVERSED / NO-OP with
## the reason, and the frame sampler flags teleports (a pixel jump no
## honest cell-step can make) and face-turns-without-motion.

var g: GogaGame = null
var PM: GDScript

# the gesture pipeline: press -> drag* -> release (a REAL finger shape)
var gest_active := false
var gest_dir := Vector2i.ZERO
var gest_t := 0.0
var gest_step := 0

# the scenario: [time, dir, why] - the owner's own first minute
var scenario := [
        [0.3, Vector2i(-1, 0), "S1 first swipe LEFT at spawn (the spawn face)"],
        [1.1, Vector2i(-1, 0), "S1b second swipe LEFT (retry the first)"],
        [2.0, Vector2i(0, -1), "S2 swipe UP from standstill"],
        [2.7, Vector2i(0, -1), "S2b swipe UP again (retry)"],
        [3.5, Vector2i(1, 0), "S3 swipe RIGHT"],
        [4.0, Vector2i(0, 1), "S4 swipe DOWN while running"],
        [4.3, Vector2i(0, -1), "S4b rapid swipe UP (same beat)"],
        [4.6, Vector2i(-1, 0), "S4c rapid swipe LEFT (same beat)"],
        [4.9, Vector2i(1, 0), "S4d rapid swipe RIGHT (same beat)"],
        [5.6, Vector2i(1, 0), "S5 swipe the running way (free)"],
        [6.2, Vector2i(-1, 0), "S6 reversal mid-corridor"],
        [7.0, Vector2i(0, 1), "S7 swipe DOWN running"],
        [8.0, Vector2i(0, -1), "S8 swipe UP running"],
        [9.0, Vector2i(-1, 0), "S9 reversal again"],
        [10.0, Vector2i(1, 0), "S10 swipe RIGHT"],
]
var sc_i := 0
var T := 0.0

# the frame sampler
var px_prev := Vector2.ZERO
var px_prev_valid := false
var anomalies := 0

# the pending classification: each fired gesture reports what it DID
var pend := []               # [{at, dir, before, wait}]

func _log(s: String) -> void:
        print(s)

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.reset_all()
        Box.bump_counter("pacman", "lore_start", 1)
        Box.bump_counter("pacman", "lore_end", 1)
        PM = load("res://game/games/pacman/pacman.gd")
        g = PM.new()
        g.game_id = "pacman"
        ScaleRule.apply(get_window())
        add_child(g)
        await get_tree().process_frame
        await get_tree().process_frame
        g.probe_reset(4242)
        g.probe_step(1.5)      # the READY beat flows into the run
        _log("=== DE FLIGHT RECORDER === seed=4242 size=%dx%d cell=%.0f"
                        % [g.cols, g.rows, g.cell_px])
        var sp: Vector2i = g.player["cell"]
        _log("spawn cell=%s dir=%s open(L)=%s open(R)=%s open(U)=%s open(D)=%s"
                        % [sp, g.player["dir"],
                        PM.is_open(g.g, g.cols, sp.x, sp.y, Vector2i(-1, 0)),
                        PM.is_open(g.g, g.cols, sp.x, sp.y, Vector2i(1, 0)),
                        PM.is_open(g.g, g.cols, sp.x, sp.y, Vector2i(0, -1)),
                        PM.is_open(g.g, g.cols, sp.x, sp.y, Vector2i(0, 1))])

func _process(delta: float) -> void:
        if g == null:
                return
        delta = minf(delta, 1.0 / 20.0)
        T += delta

        # the scenario beat
        while sc_i < scenario.size() and T >= float(scenario[sc_i][0]):
                var dir: Vector2i = scenario[sc_i][1]
                var why: String = scenario[sc_i][2]
                _log("[%6.2fs] SWIPE %s  # %s" % [T, _dn(dir), why])
                _fire_gesture(dir)
                sc_i += 1

        # the gesture legs (press + drags + release over ~0.2s)
        if gest_active:
                gest_t += delta
                if gest_t >= 0.04:
                        gest_t = 0.0
                        gest_step += 1
                        var center := _board_center()
                        if gest_step == 1:
                                var ev := InputEventScreenTouch.new()
                                ev.position = center
                                ev.pressed = true
                                ev.index = 0
                                Input.parse_input_event(ev)
                        elif gest_step <= 4:
                                var d := InputEventScreenDrag.new()
                                d.position = center + Vector2(gest_dir) \
                                                * (55.0 * (gest_step - 1))
                                d.relative = Vector2(gest_dir) * 55.0
                                d.index = 0
                                Input.parse_input_event(d)
                        elif gest_step == 5:
                                var ev2 := InputEventScreenTouch.new()
                                ev2.position = center + Vector2(gest_dir) * 240.0
                                ev2.pressed = false
                                ev2.index = 0
                                Input.parse_input_event(ev2)
                                gest_active = false

        # the pending classifications: one gesture + 4 frames later
        for p in pend:
                p["wait"] -= delta
        var ripe: Array = []
        for p in pend:
                if p["wait"] <= 0.0 and not gest_active:
                        ripe.append(p)
        for p in ripe:
                pend.erase(p)
                var after := _snap()
                _log("[%6.2fs]   -> %s   (dir=%s moving=%s t=%.2f buf=%s cell=%s)"
                                % [T, _classify(p["before"], after, p["dir"]),
                                after["dir"], after["moving"], after["t"],
                                after["buf"], after["cell"]])

        # the sampler: teleports + THE HONEST FLIGHT LAW + the bounds law
        if g.phase == "run":
                var f: Vector2i = g.player["from"]
                var t2: Vector2i = g.player["to"]
                var inb: bool = f.x >= 0 and f.y >= 0 and f.x < g.cols \
                                and f.y < g.rows and t2.x >= 0 and t2.y >= 0 \
                                and t2.x < g.cols and t2.y < g.rows
                if not inb:
                        anomalies += 1
                        _log("[%6.2fs] !! OOB SEAT from=%s to=%s cell=%s"
                                        % [T, f, t2, g.player["cell"]])
                else:
                        var adj: bool = (absi(f.x - t2.x) + absi(f.y - t2.y)) == 1
                        var wrap: bool = f.y == t2.y \
                                        and ((f.x == 0 and t2.x == g.cols - 1) \
                                        or (f.x == g.cols - 1 and t2.x == 0))
                        var stopped: bool = f == t2 and not g.player["moving"]
                        if not adj and not wrap and not stopped:
                                anomalies += 1
                                _log("[%6.2fs] !! DISHONEST FLIGHT %s -> %s"
                                                % [T, f, t2])
                var px: Vector2 = g._player_px()
                if px_prev_valid:
                        var jump := px.distance_to(px_prev)
                        var maxstep: float = g.cell_px * 1.35
                        if jump > maxstep:
                                anomalies += 1
                                _log("[%6.2fs] !! TELEPORT %.0fpx (> %.0f) at %s"
                                                % [T, jump, maxstep, px])
                px_prev = px
                px_prev_valid = true

        if T >= 12.0:
                _verdict()
                get_tree().quit(0 if anomalies == 0 else 1)

func _fire_gesture(dir: Vector2i) -> void:
        gest_active = true
        gest_dir = dir
        gest_step = 0
        gest_t = 0.039          # the first leg lands next frame
        pend.append({"at": T, "dir": dir, "before": _snap(), "wait": 0.45})

func _snap() -> Dictionary:
        return {"cell": g.player["cell"], "dir": g.player["dir"],
                "moving": g.player["moving"], "t": g.player["t"],
                "buf": g.buf, "phase": g.phase, "lives": g.lives}

## classify what the swipe DID one gesture later (the finger is honest,
## the disposition is the game's)
func _classify(before: Dictionary, after: Dictionary, dir: Vector2i) -> String:
        if String(before["phase"]) != "run":
                return "NO-OP(phase=%s)" % before["phase"]
        if after["buf"] == dir and before["buf"] != dir:
                return "BUFFERED"
        if after["dir"] == dir and bool(after["moving"]) \
                        and (not bool(before["moving"])
                        or Vector2i(before["dir"]) != dir):
                return "APPLIED"
        if dir == -Vector2i(before["dir"]) and Vector2i(after["dir"]) == dir:
                return "REVERSED"
        if Vector2i(before["dir"]) == dir and bool(before["moving"]):
                return "NO-OP(already going)"
        if Vector2i(before["dir"]) == dir and not bool(before["moving"]):
                return "NO-OP(same-as-face while stopped)"
        return "NO-OP(dropped)"

func _verdict() -> void:
        _log("=== FLIGHT LOG END: anomalies=%d lives=%d dots=%d phase=%s"
                        % [anomalies, g.lives, g.dots_run, g.phase])

func _dn(d: Vector2i) -> String:
        if d == Vector2i(-1, 0):
                return "LEFT "
        if d == Vector2i(1, 0):
                return "RIGHT"
        if d == Vector2i(0, -1):
                return "UP   "
        if d == Vector2i(0, 1):
                return "DOWN "
        return str(d)

func _board_center() -> Vector2:
        return g._cell_px(g.player["cell"])
