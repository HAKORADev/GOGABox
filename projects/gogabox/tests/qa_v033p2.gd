extends Node
## qa_v033p2 - the visual QA for the v0.3.3 PATCH 2 round:
##   01 the optionals WITHOUT a shop row (the HUD wears the button)
##   02 the HUD SHOP sheet on top of the optionals (the stack)
##   03 the buy popup in GOGACoins (the global wallet law)
##   04 the donut skin board (the template backdrop + checker cells)
##   05 the smooth board mid-cascade (shader specials + pop tweens)
##   06 the butterflies run: the spider on the top rail + baked wings
##   07 the ice storm: vertical columns + the mode chips row
##   08 diamond mine: the bottom earth row + 60s clock
##   09 the top banner (a mine rise moment)
##   10 merge: the options sheet + the are-you-sure on top (the stack law)
##   DISPLAY=:99 godot --path . res://tests/qa_v033p2.tscn

const OUT := "/home/z/my-project/download/qa_v033p2/"

func _shot(path: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        get_viewport().get_texture().get_image().save_png(path)
        print("[qa] ", path)

var G

func _boot_matcher(mode := "challenge") -> void:
        if G != null and is_instance_valid(G):
                G.queue_free()
                await get_tree().create_timer(0.4).timeout
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        G = load("res://game/games/matcher/matcher.gd").new()
        G.game_id = "matcher"
        add_child(G)
        await get_tree().create_timer(0.7).timeout
        if mode != "challenge":
                G._pick_close()
                await get_tree().create_timer(0.2).timeout
                G._start_mode(mode)
                await get_tree().create_timer(0.8).timeout

func _run() -> void:
        DirAccess.make_dir_recursive_absolute(OUT)
        get_window().size = Vector2i(1080, 1920)
        await get_tree().create_timer(0.3).timeout

        # 1 - the optionals, no shop row, HUD wears the SHOP button
        await _boot_matcher()
        await get_tree().create_timer(0.4).timeout
        await _shot(OUT + "01_optionals_no_shop.png")

        # 2 - the shop ON TOP of the optionals (both sheets alive)
        G._shop_open()
        await get_tree().create_timer(0.5).timeout
        await _shot(OUT + "02_shop_over_optionals.png")
        G._shop_close()
        await get_tree().create_timer(0.3).timeout

        # 3 - the buy popup (GOGACoins)
        G._pick_close()
        await get_tree().create_timer(0.3).timeout
        G._start_mode("challenge")
        await get_tree().create_timer(0.6).timeout
        G.phase = "play"
        G.charges["line"] = 0
        G.power_used["line"] = 1
        G._rail_tap("line")
        await get_tree().create_timer(0.5).timeout
        await _shot(OUT + "03_buy_popup_wallet.png")
        G._power_sheet_close()
        await get_tree().create_timer(0.3).timeout

        # 4 - the donut skin board
        Box.equip_skin("matcher", "donut")
        G.skin = "donut"
        G._refresh_board_skin()
        G._pick_open(false)
        G._pick_close()
        await get_tree().create_timer(0.5).timeout
        await _shot(OUT + "04_donut_board.png")
        Box.equip_skin("matcher", "gem")
        G.skin = "gem"
        G._refresh_board_skin()

        # 5 - a cascade with specials (force a flame + let it pop)
        G.grid[2][2]["special"] = "flame"
        G._dress_special(2, 2)
        G.grid[2][3]["special"] = "star"
        G._dress_special(2, 3)
        G.grid[2][4]["special"] = "hyper"
        G._dress_special(2, 4)
        await _shot(OUT + "05_special_shader_gems.png")
        var pop := {}
        for c in 8:
                pop[2 * 8 + c] = true
        G._plan_melt([])
        await G._resolve_from_pop(pop)
        await get_tree().create_timer(0.4).timeout

        # 6 - butterflies: the spider + baked wings
        await _boot_matcher("butterflies")
        await get_tree().create_timer(0.6).timeout
        await _shot(OUT + "06_butterflies_spider.png")

        # 7 - ice storm: grow a tall column
        await _boot_matcher("ice")
        G.frost[3] = 5
        G.frost[6] = 3
        G._refresh_ice()
        await get_tree().create_timer(0.5).timeout
        await _shot(OUT + "07_ice_columns.png")

        # 8 - diamond mine: the bottom row
        await _boot_matcher("mine")
        await get_tree().create_timer(0.5).timeout
        await _shot(OUT + "08_mine_bottom_row.png")

        # 9 - the top banner
        G._banner("ROW CLEARED!  +25s", true)
        await get_tree().create_timer(0.35).timeout
        await _shot(OUT + "09_top_banner.png")

        # 10 - merge: options + confirm stacked
        if G != null and is_instance_valid(G):
                G.queue_free()
                await get_tree().create_timer(0.4).timeout
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        var ok := GameHost.launch(self, "merge")
        print("[qa] merge launch=", ok)
        for i in 30:
                await get_tree().create_timer(0.5).timeout
                if GameHost.active_host != null and GameHost.active_host.game != null:
                        break
        var mg = GameHost.active_host.game
        mg._options_open()
        await get_tree().create_timer(0.4).timeout
        mg._size_confirm("6", false)
        await get_tree().create_timer(0.4).timeout
        await _shot(OUT + "10_confirm_over_options.png")
        # NO walks back to the options (the stack law)
        mg.sheet_pop()
        await get_tree().create_timer(0.4).timeout
        await _shot(OUT + "11_back_to_options.png")

        print("[qa] done")
        get_tree().quit(0)

func _ready() -> void:
        _run()
