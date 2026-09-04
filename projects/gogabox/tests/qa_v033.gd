extends Node
## qa_v033 - the visual QA for v0.3.3 MATCHER: the mode picker, the happy
## board mid-play (flame + coin + combo), butterflies rising to the spider,
## the ice storm columns, the diamond mine earth band, and the power rail
## with its refill sheet.
##   DISPLAY=:99 godot --path . res://tests/qa_v033.tscn

const OUT := "/home/z/my-project/download/qa_v033/"

func _shot(path: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        get_viewport().get_texture().get_image().save_png(path)
        print("[qa] ", path)

var G

func _boot(mode: String) -> void:
        if G != null and is_instance_valid(G):
                G.queue_free()
                await get_tree().create_timer(0.4).timeout
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        await get_tree().create_timer(0.3).timeout
        G = load("res://game/games/matcher/matcher.gd").new()
        G.game_id = "matcher"
        G.mode = mode
        add_child(G)
        await get_tree().create_timer(0.6).timeout
        G._pick_close()
        G._start_mode(mode)
        await get_tree().create_timer(0.8).timeout

func _run() -> void:
        DirAccess.make_dir_recursive_absolute(OUT)
        get_window().size = Vector2i(1080, 1920)
        await get_tree().create_timer(0.3).timeout

        # 1 - THE MODE PICKER (the first moment)
        await _boot("challenge")
        G._pick_open(true)
        await get_tree().create_timer(0.5).timeout
        await _shot(OUT + "01_mode_picker.png")
        G._pick_close()

        # 2 - THE HAPPY BOARD mid-play: a flame gem + the coin + a combo
        G.phase = "hold"
        G._spawn_coin()
        # plant a flame next to the coin's column for the shot
        G.grid[5][2] = {"color": 2, "special": "flame", "wing": false,
                        "node": Sprite2D.new(), "ov": null, "wing_ov": null}
        G.grid[5][2]["node"].texture = G.tex_gem[2]
        G.grid[5][2]["node"].position = G._cell_pos(5, 2)
        G.world.add_child(G.grid[5][2]["node"])
        G._attach_special_overlay(5, 2)
        await get_tree().create_timer(0.4).timeout
        await _shot(OUT + "02_challenge_board_flame_coin.png")

        # 3 - THE POWER RAIL + REFILL SHEET (round balance economy)
        Box.unlock_game("matcher", 0)
        G._power_sheet("bomb")
        await get_tree().create_timer(0.4).timeout
        await _shot(OUT + "03_power_refill_sheet.png")
        G._power_sheet_close()

        # 4 - BUTTERFLIES: wings on the board + the spider above
        await _boot("butterflies")
        for c in [2, 5]:
                G._hatch_butterfly(ROWS_PLACE(4), c)
        G._hatch_butterfly(6, 3)
        await get_tree().create_timer(0.4).timeout
        await _shot(OUT + "04_butterflies_spider.png")

        # 5 - ICE STORM: tall columns + the heat chip
        await _boot("ice")
        G.frost = [2, 4, 1, 5, 3, 2, 4, 1]
        G._refresh_ice()
        G.temp = 0.6
        await get_tree().create_timer(0.4).timeout
        await _shot(OUT + "05_ice_storm_columns.png")

        # 6 - DIAMOND MINE: the earth band with treasures
        await _boot("mine")
        G.earth[0][2]["tr"] = "diamond"
        G.earth[1][5]["tr"] = "gold"
        G.earth[0][6]["tr"] = "artifact"
        # refresh the three sprites
        for rc in [Vector2i(0, 2), Vector2i(1, 5), Vector2i(0, 6)]:
                var e: Dictionary = G.earth[rc.x][rc.y]
                var old: Sprite2D = e["node"]
                var pos: Vector2 = old.position
                old.queue_free()
                e["node"] = G._earth_sprite(rc.x, rc.y, String(e["tr"]))
                e["node"].position = pos
        await get_tree().create_timer(0.4).timeout
        await _shot(OUT + "06_diamond_mine_earth.png")

        # 7 - PEACE: the pastel sky, no rail
        await _boot("peace")
        await get_tree().create_timer(0.3).timeout
        await _shot(OUT + "07_peace_pastel.png")

        Box.reset_all()
        print("[qa_v033] done")
        get_tree().quit(0)

func ROWS_PLACE(from_bottom: int) -> int:
        return 8 - from_bottom

func _ready() -> void:
        print("=== qa_v033 ===")
        _run()
