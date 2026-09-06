extends Node
## qa_v034p3 - the PATCH-3 Xvfb shot driver. Rigs (QA_RIG env):
##   option  - the BIGGER door: the 6 start cards + SKILLS button
##   market  - THE WAVE MARKET, ITEMS tab, the HOLD DECK chip + HOLD buttons
##   marketw - the market WEAPONS tab: rarities + held pin + YOUR LOADOUT
##   bench   - THE MERGE BENCH as its own menu (the pairs on the shelf)
##   stats   - THE STATS MENU: the multi-cost packs, no X
##   skills  - THE SKILLS MENU: the ten, the points header
##   shop    - THE SHOP (universal): the GOGACoins chip + PLACES tab
##   arena   - the HUD with SCORE + KILLS + GOGACoins widgets + a fight
##   DISPLAY=:95 QA_RIG=market godot --path . res://tests/qa_v034p3.tscn

var G: GogaGame

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.dev_set_cheat("all_owned", 1)
        var rig := OS.get_environment("QA_RIG")
        if rig.is_empty():
                rig = "arena"
        G = load("res://game/games/cosmic_spud/cosmic_spud.gd").new()
        G.game_id = "cosmic_spud"
        add_child(G)
        await get_tree().create_timer(1.2).timeout
        match rig:
                "option":
                        G.meta.d["tree"] = {"o1": true, "o2": true, "l1": true}
                        G.meta.d["coins"] = 860
                        G.meta.d["kills"] = 260
                        G.meta.save()
                        G._cs_close_all()
                        G._optionals_open()
                        await _settle()
                "market":
                        G._cs_close_all()
                        G._start_run()
                        await _wait_frames(10)
                        G.phase = "break"
                        G.run_wave = 6
                        G.run_ccoins = 1240
                        G._roll_shop_offers()
                        G.shop_offers_i[0]["held"] = true
                        G._market_open()
                        await _settle()
                "marketw":
                        G._cs_close_all()
                        G._start_run()
                        await _wait_frames(10)
                        G.phase = "break"
                        G.run_wave = 7
                        G.run_ccoins = 2100
                        G.meta.d["armory"] = [["smg", 1], ["smg", 1], ["shotgun", 2]]
                        G.meta.d["owned_allies"] = ["drone", "medic"]
                        G._roll_shop_offers()
                        G.shop_offers_w[0]["held"] = true
                        G.market_tab = "weapons"
                        G._market_open()
                        await _settle()
                "bench":
                        G._cs_close_all()
                        G._start_run()
                        await _wait_frames(10)
                        G.phase = "break"
                        G.run_wave = 5
                        G.run_ccoins = 900
                        G.meta.d["tree"] = {"l3": true}
                        G.meta.d["armory"] = [["smg", 1], ["smg", 1], ["shotgun", 2], ["shotgun", 2]]
                        G._merge_menu_open()
                        await _settle()
                "stats":
                        G._cs_close_all()
                        G._start_run()
                        await _wait_frames(10)
                        G.phase = "break"
                        G.pending_levels = 4
                        G._stats_menu_open()
                        await _settle()
                "skills":
                        G._cs_close_all()
                        G.meta.d["kills"] = 420
                        G.meta.d["skill_spent"] = 0
                        G.meta.d["skills"] = {"starch_rage": true}
                        G.meta.save()
                        G._skills_menu_open()
                        await _settle()
                "shop":
                        G._cs_close_all()
                        G.meta.d["coins"] = 1500
                        G._armory_tab = "themes"
                        G._shop_open()
                        await _settle()
                _:
                        G._cs_close_all()
                        G._start_run()
                        await _wait_frames(30)
                        G.run_kills = 37
                        G.score = 218
                        G.run_ccoins = 128
                        G._spawn_enemy("sprinter", G.p_pos + Vector2(240, -60))
                        G._spawn_enemy("chunk", G.p_pos + Vector2(-290, 50))
                        G._spawn_enemy("wraith", G.p_pos + Vector2(150, -200))
                        G._spawn_enemy("spitter", G.p_pos + Vector2(-150, 250))
                        await _wait_frames(45)
        var shot := OS.get_environment("QA_SHOT")
        if shot.is_empty():
                shot = "/tmp/qa_v034p3_%s.png" % rig
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(shot)
        print("qa_v034p3 shot: ", shot)
        get_tree().quit(0)

func _settle() -> void:
        await _wait_frames(12)

func _wait_frames(n: int) -> void:
        for i in n:
                await get_tree().process_frame
