extends Node
## qa_v032d - the visual QA for the v0.3.2 PATCH IV: the chicken-invaders
## fly-in train + structured hover, the steered protector body, the AWAKE
## triton (war clock bolts in the air), the monarch's REAL side-roll act,
## a rented verdant flying its FREE snakes, and the wave-end airdrops with
## the dash PILL.
##   DISPLAY=:99 godot --path . res://tests/qa_v032d.tscn

const OUT := "/home/z/my-project/download/qa_v032d/"

func _shot(path: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        get_viewport().get_texture().get_image().save_png(path)
        print("[qa] ", path)

var G: GogaGame

func _boot_game() -> void:
        G = load("res://game/games/invaders/invaders.gd").new()
        G.game_id = "invaders"
        add_child(G)
        await get_tree().create_timer(0.5).timeout

func _kill_game() -> void:
        if G != null and is_instance_valid(G):
                G.queue_free()
        G = null
        await get_tree().create_timer(0.4).timeout

func _run() -> void:
        DirAccess.make_dir_recursive_absolute(OUT)
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        get_window().size = Vector2i(1706, 960)
        await get_tree().create_timer(0.3).timeout

        # 1 - THE FLY-IN TRAIN: catch the wave mid-entrance (staggered curves)
        await _boot_game()
        G._show_ready_card()
        await get_tree().create_timer(0.2).timeout
        G._press(Vector2(400, 800), 0)
        await get_tree().create_timer(0.4).timeout
        G._story_end()
        await get_tree().create_timer(1.35).timeout
        await _shot(OUT + "01_flyin_train_curved.png")

        # 2 - THE STRUCTURED HOVER: the settled grid (96px pitch, no overlaps)
        await get_tree().create_timer(1.5).timeout
        G.move_axis = -0.8          # the steering bank rides into the shot
        await get_tree().create_timer(0.55).timeout
        await _shot(OUT + "02_structured_grid_steered_ship.png")
        G.move_axis = 0.0

        # 3 - THE AWAKE TRITON: war-clock bolts + the volley in the air
        for e in G.enemies.duplicate():
                if is_instance_valid(e["node"]):
                        e["node"].queue_free()
        G.enemies.clear()
        G.wave = 10
        G._start_boss_wave()
        G._story_end()
        await get_tree().create_timer(2.6).timeout   # wake + first war shots
        G._boss_move("volley")
        G.firing = true
        await get_tree().create_timer(0.5).timeout
        await _shot(OUT + "03_triton_awake_war_clock.png")

        # 4 - THE MONARCH SIDE-ROLL: the act sweeping the frame
        G._boss_cleanup(false)
        G.boss = {}
        G._spawn_boss("monarch", false)
        G._story_end()
        await get_tree().create_timer(1.5).timeout
        G._boss_move("rolleroll")
        await get_tree().create_timer(1.0).timeout   # mid-sweep
        await _shot(OUT + "04_monarch_side_roll_act.png")

        # 5 - THE RENTED VERDANT: free weaving snakes on their own line
        if G.boss.has("node") and is_instance_valid(G.boss["node"]):
                (G.boss["node"] as Sprite2D).position.y = 260.0
        G._defender_call("verdant")
        await get_tree().create_timer(0.6).timeout
        G.defender_fire_cd = 0.0
        G._defender_tick(0.016)
        await get_tree().create_timer(0.45).timeout
        await _shot(OUT + "05_defender_verdant_free_snakes.png")

        # 6 - THE AIRDROPS: the wave-end payment - coin + the dash PILL
        G.loots.clear()
        G._spawn_loot("coin", Vector2(G.get_viewport_rect().size.x * 0.38, 130.0))
        G._spawn_loot("power", Vector2(G.get_viewport_rect().size.x * 0.58, 180.0))
        await get_tree().create_timer(0.25).timeout
        await _shot(OUT + "06_airdrops_coin_and_pill.png")

        Box.reset_all()
        print("[qa_v032d] done")
        get_tree().quit(0)

func _ready() -> void:
        print("=== qa_v032d ===")
        _run()
