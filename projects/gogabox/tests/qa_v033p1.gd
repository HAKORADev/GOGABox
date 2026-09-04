extends Node
## qa_v033p1 - the visual QA for the v0.3.3 PATCH 1 round: the new
## OPTIONALS first screen (image boxes + shop button), the SHOP sheet,
## the power BUY POPUP (quantity arrows), the grayed SPENT rail slot,
## and the 2048 are-you-sure sheet.
##   DISPLAY=:99 godot --path . res://tests/qa_v033p1.tscn

const OUT := "/home/z/my-project/download/qa_v033p1/"

func _shot(path: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        get_viewport().get_texture().get_image().save_png(path)
        print("[qa] ", path)

var G

func _boot_matcher() -> void:
        if G != null and is_instance_valid(G):
                G.queue_free()
                await get_tree().create_timer(0.4).timeout
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        await get_tree().create_timer(0.3).timeout
        G = load("res://game/games/matcher/matcher.gd").new()
        G.game_id = "matcher"
        add_child(G)
        await get_tree().create_timer(0.7).timeout

func _run() -> void:
        DirAccess.make_dir_recursive_absolute(OUT)
        get_window().size = Vector2i(1080, 1920)
        await get_tree().create_timer(0.3).timeout

        # 1 - THE OPTIONALS FIRST SCREEN (the owner's redesign)
        await _boot_matcher()
        await get_tree().create_timer(0.3).timeout
        await _shot(OUT + "01_optionals_first.png")

        # 2 - THE SHOP SHEET (the shop is a BUTTON now)
        var shop_btn: Button = null
        for b in Arc._buttons_in(G.pick_sheet[2]):
                if b.text == "SHOP":
                        shop_btn = b
        if shop_btn != null:
                shop_btn.pressed.emit()
                await get_tree().create_timer(0.5).timeout
                await _shot(OUT + "02_shop_sheet.png")
                for b in Arc._buttons_in(G.shop_sheet[2]):
                        if b.text == "CLOSE":
                                b.pressed.emit()
                await get_tree().create_timer(0.4).timeout

        # 3 - THE POWER BUY POPUP (the quantity arrows, both balances)
        G._pick_close()
        G._start_mode("challenge")
        await get_tree().create_timer(0.7).timeout
        G.phase = "play"
        G.run_coins = 120
        G.charges["bomb"] = 0
        G.power_used["bomb"] = 1
        G._rail_tap("bomb")
        await get_tree().create_timer(0.5).timeout
        await _shot(OUT + "03_power_buy_popup.png")
        G._power_sheet_close()

        # 4 - THE GRAYED SPENT SLOT (all 3 used)
        G.power_used["bomb"] = 3
        G.charges["bomb"] = 0
        G._refresh_rail()
        await get_tree().create_timer(0.3).timeout
        await _shot(OUT + "04_spent_slot_gray.png")

        # 5 - THE 2048 ARE-YOU-SURE SHEET
        if G != null and is_instance_valid(G):
                G.queue_free()
                await get_tree().create_timer(0.4).timeout
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        await get_tree().create_timer(0.3).timeout
        var M = load("res://game/games/merge/merge2048.gd").new()
        M.game_id = "merge"
        add_child(M)
        await get_tree().create_timer(0.7).timeout
        M._options_open()
        await get_tree().create_timer(0.4).timeout
        M._size_confirm("6", false)
        await get_tree().create_timer(0.5).timeout
        await _shot(OUT + "05_2048_are_you_sure.png")
        M._confirm_pair_down()
        M._options_close()

        print("[qa] done")
        get_tree().quit(0)

func _ready() -> void:
        _run()
