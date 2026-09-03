extends Node
## qa_v032b - the visual QA for the v0.3.2 PATCH: the optionals-FIRST flow
## (snake-standard image boxes), the clean tap-anywhere card, the scrollable
## story sheet, the Neptune fight (dash hulls + the x-nn heart + 6 pips), the
## RING DUKE with his % chip under the body, the defend menu grays, the shop
## 2-in-1 rows, the defender radio bubbles and the Hideout sky.
##   DISPLAY=:99 godot --path . res://tests/qa_v032b.tscn

const OUT := "/home/z/my-project/download/qa_v032b/"

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

        # 1 - THE FLOW LAW: the game OPENS on the optionals (image boxes)
        await _boot_game()
        await _shot(OUT + "01_optionals_first.png")

        # 2 - the clean tap-anywhere card (no controls help)
        G._show_ready_card()
        await get_tree().create_timer(0.3).timeout
        await _shot(OUT + "02_ready_card.png")

        # 3 - the SCROLLABLE STORY sheet (paused, dario law)
        G._press(Vector2(400, 800), 0)
        await get_tree().create_timer(0.4).timeout
        await _shot(OUT + "03_story_sheet.png")
        G._story_end()
        await get_tree().create_timer(1.8).timeout

        # 4 - the Neptune fight: dash hulls, x nn + heart, 6 pips, firing
        G.firing = true
        await get_tree().create_timer(1.4).timeout
        await _shot(OUT + "04_neptune_fight.png")

        # 5 - the RING DUKE with the % chip riding under his body
        G.firing = false
        G.stage = 2
        G.wave = 10
        G._start_boss_wave()
        G._story_end()
        await get_tree().create_timer(2.4).timeout
        G.boss["state"] = "hover"
        G.boss["hp"] = int(G.boss["hp_max"] * 0.62)
        G._boss_chip_update()
        G.firing = true
        await get_tree().create_timer(0.8).timeout
        await _shot(OUT + "05_boss_duke.png")

        # 6 - the alpha bubble radio riding ABOVE the speakers
        G.firing = false
        Box.earn(5000)
        G._defender_call("titan")
        await get_tree().create_timer(0.6).timeout
        await _shot(OUT + "06_bubble_radio.png")

        # 7 - the defend menu with the honest grays (titan ON COVER)
        await get_tree().create_timer(6.5).timeout     # let the radio finish
        G._defend_open()
        await get_tree().create_timer(0.3).timeout
        await _shot(OUT + "07_defend_menu.png")
        G._sheet_close()

        # 8 - the shop: weapons + the 2-in-1 crew + the tour
        G._shop_open()
        await get_tree().create_timer(0.3).timeout
        await _shot(OUT + "08_shop.png")
        G._sheet_close()

        # 9 - the Hideout finale sky (the themes pack on - the dash shader)
        G._kill_dialog()
        G.queue_free()
        G = null
        await get_tree().create_timer(0.4).timeout
        Box.buy_item("invaders", "theme", "pack", 0)
        await _boot_game()
        G.themes_on = true
        G._apply_stage_sky(9, true)
        G._show_ready_card()
        G._press(Vector2(400, 800), 0)
        await get_tree().create_timer(0.4).timeout
        G._story_end()
        await get_tree().create_timer(1.8).timeout
        await _shot(OUT + "09_hideout_sky.png")

        print("[qa] done")
        get_tree().quit(0)

func _ready() -> void:
        print("=== qa_v032b: SPACE INVADERS PATCH ===")
        _run()
