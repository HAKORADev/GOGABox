extends Node
## gf_soak - the v0.3.6-1 world soak: long bot runs across every mechanic,
## speed levels and chunk types. Fails on script errors (godot exits nonzero
## on a script error inside _goga_tick) or an illegal death cause.
## godot --headless --path . res://tests/gf_soak.tscn

var G: GogaGame

func _ready() -> void:
        print("=== gf_soak ===")
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        get_window().size = Vector2i(1920, 1080)
        await get_tree().create_timer(0.2).timeout
        var bad := 0
        for seed_i in 5:
                var causes := {}
                var lives := 0
                var life_t := 0.0
                var max_life := 0.0
                G = load("res://game/games/geometry/geometry.gd").new()
                G.game_id = "geometry"
                add_child(G)
                await get_tree().create_timer(0.6).timeout
                G.probe_reset(500 + seed_i * 77)
                G.paused = false
                G.coin_timer = 1e9
                G.pow_timer = 1e9
                var taps := [8, 13, 21, 34]
                for i in 3600:                     # 60 game-seconds per seed
                        G._goga_tick(1.0 / 60.0)
                        life_t += 1.0 / 60.0
                        if G.over_gate:
                                lives += 1
                                var why: String = G.last_death
                                causes[why] = int(causes.get(why, 0)) + 1
                                if why == "" :
                                        print("[FAIL] seed %d: a death with NO cause (the old void bug)" % seed_i)
                                        bad += 1
                                max_life = maxf(max_life, life_t)
                                life_t = 0.0
                                # a fresh world per life - the calm runway law applies again
                                G.probe_reset(500 + seed_i * 77 + lives)
                                G.paused = false
                                G.coin_timer = 1e9
                                G.pow_timer = 1e9
                        if i % taps[i % taps.size()] == 0:
                                G._do_action()
                        if i % 600 == 300:
                                G.mechanic = ["normal", "flip", "sticky"][randi() % 3]
                                G._set_mech_chip()
                print("seed %d: score=%d speed=x%.2f lives=%d causes=%s best_life=%.1fs" %
                                [seed_i, G.score, G.speed / G.BASE_SPEED, lives, causes, max_life])
                if lives > 0 and max_life < 3.0:
                        # a dumb tap-bot should still survive the calm + a few chunks
                        print("[FAIL] seed %d: the best life was under 3s - the world spawns unfair" % seed_i)
                        bad += 1
                G.queue_free()
                await get_tree().create_timer(0.3).timeout
        print("RESULT: %s" % ("CLEAN" if bad == 0 else "DIRTY"))
        get_tree().quit(0 if bad == 0 else 1)
