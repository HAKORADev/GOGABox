extends Node
## REPLAY REPRO (v0.3.6-1) - the owner's report: "after playing the game for
## the first time, every run until i close the app and re-open it, it always
## make any other runs make the square go fall into the ground in a weird way".
## Simulates the host's PLAY AGAIN exactly: free the old game, new instance,
## ready tap, then watch the first seconds of the run.

var G: GogaGame = null
var bad := 0

func ck(cond: bool, what: String) -> void:
        if cond:
                print("[PASS] ", what)
        else:
                print("[FAIL] ", what)
                bad += 1

func _new_game() -> GogaGame:
        if G != null and is_instance_valid(G):
                G.queue_free()
                await get_tree().process_frame
                await get_tree().process_frame
        G = load("res://game/games/geometry/geometry.gd").new()
        G.game_id = "geometry"
        add_child(G)
        await get_tree().create_timer(0.5).timeout
        return G

func _watch(tag: String, secs: float) -> void:
        # the ground truth: while a gseg is under the square's column and gravity
        # is down, the square must never sink deep below the ground surface.
        var t := 0.0
        var prev_ground := true
        G.paused = false
        G.process_mode = Node.PROCESS_MODE_DISABLED   # the manual clock ONLY
        while t < secs:
                var dt := 1.0 / 60.0
                G._goga_tick(dt)
                t += dt
                var p: Dictionary = G.player
                var wx: float = p["x"] / G.us + G.world_x
                var over_solid: bool = false
                for s in G.gsegs:
                        if wx >= float(s["x0"]) - 20.0 and wx <= float(s["x1"]) + 20.0:
                                over_solid = true
                                break
                if p["ground"] != prev_ground:
                        print("  .. %s t=%.2f ground %s -> %s (y=%.1f vy=%.0f wx=%.0f solid=%s g=%d mech=%s)" %
                                        [tag, t, prev_ground, p["ground"], p["y"], p["vy"], wx, over_solid, p["g"], G.mechanic])
                        prev_ground = p["ground"]
                var sink: float = (p["y"] / G.us) - (G.GROUND_Y - G.HALF)
                if p["g"] == 1 and over_solid and p["ground"] and sink > 6.0:
                        print("  !! %s t=%.2f SINK %.1f px into solid ground (y=%.1f wx=%.0f)" % [tag, t, sink, p["y"], wx])
                if p["g"] == 1 and over_solid and not p["ground"] and sink > 30.0:
                        print("  !! %s t=%.2f FALLING THROUGH SOLID GROUND (y=%.1f vy=%.0f wx=%.0f)" % [tag, t, p["y"], p["vy"], wx])
                if G.over_gate:
                        print("  .. %s t=%.2f DIED (wx=%.0f)" % [tag, t, wx])
                        return

func _run() -> void:
        print("=== gf_replay_repro ===")
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        get_window().size = Vector2i(1920, 1080)
        await get_tree().create_timer(0.2).timeout

        # ---- RUN 1 (the first ever play)
        await _new_game()
        print("run1: phase=", G.phase, " y=", G.player["y"], " us=", G.us)
        G._ready_start()
        await _watch("run1", 6.0)
        # die like a real run ends
        G._die("repro")
        await get_tree().create_timer(0.8).timeout
        print("run1 over: ", G.over, " score=", G.score)

        # ---- RUN 2 (the host's PLAY AGAIN: fresh instance, same session)
        await _new_game()
        print("run2: phase=", G.phase, " y=", G.player["y"], " us=", G.us)
        G._ready_start()
        await _watch("run2", 8.0)
        print("run2 alive: ", not G.over_gate, " y=", G.player["y"], " ground=", G.player["ground"])

        # ---- RUN 3 (quick replay, no long idle)
        await _new_game()
        G._ready_start()
        await _watch("run3", 8.0)
        print("run3 alive: ", not G.over_gate)

        # ---- the coin clock across fresh instances (issue 2 evidence)
        await _new_game()
        print("coin_timer at boot: ", G.coin_timer, " (0 = a coin spawns at once)")
        G._ready_start()
        var coin_t := -1.0
        G.paused = false
        for i in int(31.0 * 60.0):
                G._goga_tick(1.0 / 60.0)
                if not G.coin.is_empty():
                        coin_t = i / 60.0
                        break
        print("first coin appeared at t=", coin_t, "s (law: never before 30s)")
        if coin_t >= 0.0 and coin_t < 29.5:
                bad += 1
                print("[FAIL] THE COIN LAW: a coin appeared before 30s from the run start")

        print("RESULT: ", "CLEAN" if bad == 0 else "%d FAILURES" % bad)
        get_tree().quit(0 if bad == 0 else 1)

func _ready() -> void:
        _run()
