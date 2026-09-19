extends SceneTree
## THE SIM TELLS THE DESIGN (agents law 36): a bot plays GOLD MINER fast
## (drive _goga_tick with fixed dt, auto-launch when the swing lines up
## with the nearest gold) - the score/level curve picks the feel facts.

func _init() -> void:
        call_deferred("_run")

func _run() -> void:
        var game = load("res://game/games/goldminer/goldminer.gd").new()
        game.game_id = "goldminer"
        game.set_process(false)
        get_root().add_child(game)
        await process_frame
        await process_frame
        game._intro_go()
        var dt := 1.0 / 60.0
        var sim_t := 0.0
        var SIM := 300.0
        var report := 30.0
        var guard := 0
        while sim_t < SIM and guard < 400000 and not game.over:
                guard += 1
                # THE BOT: launch when the swing lines up with the best gold
                # - the tolerance is the CATCH WINDOW at that distance
                if game.phase == "swing":
                        var best_tol := -1.0
                        var best_dir := Vector2.ZERO
                        for it in game.items:
                                if String(it["kind"]).begins_with("gold") \
                                                and not bool(it["coin"]):
                                        var to: Vector2 = it["pos"] - game.anchor
                                        var dist := to.length()
                                        if dist < 40.0:
                                                continue
                                        var tol := asin(minf(1.0,
                                                (float(it["r"]) + 12.0) / dist))
                                        if tol > best_tol:
                                                best_tol = tol
                                                best_dir = to.normalized()
                        if best_dir != Vector2.ZERO:
                                var cur: Vector2 = game.claw_dir
                                if absf(cur.angle_to(best_dir)) < best_tol:
                                        game._on_tap(Vector2.ZERO)
                game._goga_tick(dt)
                sim_t += dt
                if sim_t >= report:
                        print("t=%3ds score=%3d ground=%d lives=%d banked=%d phase=%s rope=%.0f items=%d" % [
                                int(sim_t), game.score, game.level,
                                game.lives, game.things_banked, game.phase,
                                game.rope_len, game.items.size()])
                        report += 30.0
        print("SIM END: score=%d ground=%d lives=%d banked=%d over=%s" % [
                game.score, game.level, game.lives, game.things_banked,
                str(game.over)])
        quit(0)
