extends Node
## qa_v032c - the visual QA for the v0.3.2 PATCH III: the 22-row fixed-scale
## formation, the PROTECTOR story with its START button, the verdant snakes
## held and RELEASED (they finish their flight), the veteran's WHITE painted
## arch, the dash-sized wreck drops, the cyan shield of a tank, and the
## app answering again after a defender call (the unfreeze law).
##   DISPLAY=:99 godot --path . res://tests/qa_v032c.tscn

const OUT := "/home/z/my-project/download/qa_v032c/"

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

        # 1 - THE PROTECTOR story: the crafted lore + the START button
        await _boot_game()
        G._show_ready_card()
        await get_tree().create_timer(0.2).timeout
        G._press(Vector2(400, 800), 0)
        await get_tree().create_timer(0.4).timeout
        await _shot(OUT + "01_the_protector_story_start.png")
        G._story_end()
        await get_tree().create_timer(1.8).timeout

        # 2 - the fixed-scale formation: tight rows in the enemy zone, open sky
        G.firing = true
        await get_tree().create_timer(1.6).timeout
        await _shot(OUT + "02_fixed_scale_formation.png")

        # 3 - the verdant snakes: held stream, then RELEASED - they fly on
        G.firing = false
        G.weapon = "snake"
        G.wpower["snake"] = 4
        G._refresh_hud2()
        G.firing = true
        await get_tree().create_timer(1.1).timeout
        await _shot(OUT + "03_verdant_held_stream.png")
        G.firing = false                       # THE RELEASE LAW
        await get_tree().create_timer(0.45).timeout
        await _shot(OUT + "04_verdant_released_still_flying.png")

        # 4 - the veteran's WHITE painted arch
        G.weapon = "arc"
        G.wpower["arc"] = 3
        G._refresh_hud2()
        G.fire_cd = 0.0
        G._fire_arc()
        await get_tree().create_timer(0.35).timeout
        G._fire_arc()
        await get_tree().create_timer(0.3).timeout
        await _shot(OUT + "05_veteran_white_arcs.png")
        G.arcs.clear()

        # 5 - the wreck drops: the dash coin + the readable items
        G.weapon = "orb"
        G._refresh_hud2()
        G.enemies.clear()
        var coin_at: Vector2 = G.ship.position + Vector2(-220.0, -300.0)
        G._spawn_loot("coin", coin_at)
        G._spawn_loot("power", coin_at + Vector2(120.0, 60.0))
        G._spawn_loot("wswitch", coin_at + Vector2(240.0, -40.0))
        G.kills_since_coin = 4
        G._summon_kind("grunt", coin_at + Vector2(-140.0, -60.0))
        var we: Dictionary = G.enemies[G.enemies.size() - 1]
        we["state"] = "hover"
        G.coin_target = 5
        G._kill_enemy(we, true)
        await get_tree().create_timer(0.4).timeout
        await _shot(OUT + "06_wreck_drops_dash_sizes.png")

        # 6 - the shield: a cyan tank eats the hits
        G.loots.clear()
        G._summon_kind("tank", Vector2(G.get_viewport_rect().size.x * 0.62, 320.0))
        var tk: Dictionary = G.enemies[G.enemies.size() - 1]
        tk["state"] = "hover"
        G._hit_enemy(tk, 2)
        await get_tree().create_timer(0.3).timeout
        await _shot(OUT + "07_tank_shield_cyan.png")

        # 7 - THE UNFREEZE LAW: call a defender, close, the app answers
        G.loots.clear()
        G.enemies.clear()
        Box.earn(10000)
        G._defend_open()
        await get_tree().create_timer(0.3).timeout
        await _shot(OUT + "08_defend_menu.png")
        G._defender_call("verdant")
        G._sheet_close()
        await get_tree().create_timer(0.5).timeout
        await _shot(OUT + "09_defender_flying_radio.png")
        print("[qa] tree paused after close: ", get_tree().paused, " (must be false)")

        Box.reset_all()
        print("qa_v032c done")
        get_tree().quit(0)

func _ready() -> void:
        print("=== qa_v032c ===")
        _run()
