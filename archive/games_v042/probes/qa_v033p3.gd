extends Node
## qa_v033p3 - the visual QA for the v0.3.3 PATCH 3 round:
##   01 the optionals: EIGHT mood cards + name-only skins
##   02 the board on the template backdrop + checker cells
##   03 the ICON-ONLY power rail (no names, no prices)
##   04 the challenge HUD (goal/moves + R/W/L LIVES chips)
##   05 the four specials riding their gems (shader v2: bomb/rowh/colv/hyper)
##   06 the jelly board (the virus at the bottom + solids)
##   07 the ice crash board (the layer ladder + the rock)
##   08 the drop board (parcels on the top line)
##   09 the mine: pure dirt band + the board lift moment
##   10 the ice storm v2 (frosted blocks BEHIND the gems, snow caps)
##   DISPLAY=:99 godot --path . res://tests/qa_v033p3.tscn

const OUT := "/home/z/my-project/download/qa_v033p3/"

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
        G.mode = mode
        add_child(G)
        await get_tree().create_timer(0.7).timeout
        G._pick_close()
        await get_tree().create_timer(0.2).timeout
        G._start_mode(mode)
        await get_tree().create_timer(0.8).timeout
        G.phase = "hold"

func _run() -> void:
        DirAccess.make_dir_recursive_absolute(OUT)
        get_window().size = Vector2i(1080, 1920)
        await get_tree().create_timer(0.3).timeout

        # 1 - the optionals: 8 cards, name-only skins
        await _boot_matcher()
        G._pick_open(false)
        await get_tree().create_timer(0.5).timeout
        await _shot(OUT + "01_optionals_8_cards.png")
        G._pick_close()
        await get_tree().create_timer(0.3).timeout

        # 2 - the challenge board on the template look
        await _shot(OUT + "02_template_board.png")

        # 3+4 - the icon rail + the challenge HUD chips
        G.phase = "play"
        G.charges["line"] = 2
        G.charges["bomb"] = 1
        G.power_used["vapor"] = 3
        G._refresh_rail()
        await get_tree().create_timer(0.3).timeout
        await _shot(OUT + "03_icon_rail_challenge_hud.png")

        # 5 - the four specials riding gems (the shader v2)
        G.grid[2][2]["special"] = "bomb"
        G._dress_special(2, 2)
        G.grid[2][5]["special"] = "rowh"
        G._dress_special(2, 5)
        G.grid[5][2]["special"] = "colv"
        G._dress_special(5, 2)
        G.grid[5][5]["special"] = "hyper"
        G._dress_special(5, 5)
        await get_tree().create_timer(0.6).timeout
        await _shot(OUT + "04_specials_shader_v2.png")
        for p in [Vector2i(2, 2), Vector2i(2, 5), Vector2i(5, 2), Vector2i(5, 5)]:
                G.grid[p.x][p.y]["special"] = ""
                G.grid[p.x][p.y]["node"].material = null

        # 6 - the jelly board
        await _boot_matcher("jelly")
        await get_tree().create_timer(0.5).timeout
        await _shot(OUT + "05_jelly_board.png")

        # 7 - the ice crash board with a rock
        await _boot_matcher("icecrash")
        G.icel[3 * 8 + 4] = 5
        G.icel[4 * 8 + 4] = 6
        G._refresh_icel()
        await get_tree().create_timer(0.5).timeout
        await _shot(OUT + "06_icecrash_layers.png")

        # 8 - the drop board
        await _boot_matcher("drop")
        await get_tree().create_timer(0.5).timeout
        await _shot(OUT + "07_drop_parcels.png")

        # 9 - the mine (pure dirt + layers)
        await _boot_matcher("mine")
        G.earth[7][3]["kind"] = "clay"
        G.earth[7][3]["hp"] = 2
        if is_instance_valid(G.earth[7][3].get("node")):
                G.earth[7][3]["node"].texture = G._t("clay")
        G.earth[7][5]["kind"] = "rock"
        G.earth[7][5]["hp"] = 99
        if is_instance_valid(G.earth[7][5].get("node")):
                G.earth[7][5]["node"].texture = G._t("rock")
        await get_tree().create_timer(0.3).timeout
        await _shot(OUT + "08_mine_layers.png")

        # 10 - the ice storm v2
        await _boot_matcher("ice")
        G.frost = [0, 0, 3, 0, 0, 2, 0, 0]
        G._refresh_ice()
        await get_tree().create_timer(0.6).timeout
        await _shot(OUT + "09_ice_blocks_v2.png")

        # bonus - the butterflies grace moment (the spider alert)
        await _boot_matcher("butterflies")
        var wing := Vector2i(-1, -1)
        for r in 8:
                for c in 8:
                        if not G.grid[r][c].is_empty() and bool(G.grid[r][c].get("wing", false)):
                                wing = Vector2i(r, c)
                                break
                if wing.x >= 0:
                        break
        if wing.x >= 0:
                G.grid[0][wing.y] = G.grid[wing.x][wing.y]
                G.grid[wing.x][wing.y] = {}
                G.phase = "play"
                await G._rise_butterflies()
                await get_tree().create_timer(0.3).timeout
                await _shot(OUT + "10_spider_grace.png")

        print("[qa] done")
        get_tree().quit(0)

func _ready() -> void:
        _run()
