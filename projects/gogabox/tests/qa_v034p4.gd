extends Node
## qa_v034p4 - the PATCH-4 Xvfb shot driver. Rigs (QA_RIG env):
##   shop   - THE SHOP, the universal GOGACoins list (PLACES/GUNS/LAB/CREW)
##   door   - the optionals door with the BUY + coin-icon price button
##   arena  - the HUD: the honest meters (HP mid, XP partial) + the universal
##            GOGACoins chip + the no-muzzle fight
##   DISPLAY=:95 QA_RIG=shop godot --path . res://tests/qa_v034p4.tscn

var G: GogaGame

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.dev_set_cheat("all_owned", 1)
        if OS.get_environment("QA_FIT") != "":
                for t in ["SHOTGUN  -  IN THE MARKET", "DECAYED DESERT  -  WORN NOW",
                                "THE GUNS - THEY JOIN THE WAVE MARKET"]:
                        print("QA_FIT: '%s' -> fs=%d w@20=%.0f" % [t,
                                        Arc.fit_size(t, 20, 1000.0, null, true),
                                        Arc.text_width(t, 20, true)])
        var rig := OS.get_environment("QA_RIG")
        if rig.is_empty():
                rig = "shop"
        G = load("res://game/games/cosmic_spud/cosmic_spud.gd").new()
        G.game_id = "cosmic_spud"
        add_child(G)
        await get_tree().create_timer(1.2).timeout
        match rig:
                "shop":
                        G._cs_close_all()
                        Box.earn(1200)
                        G._shop_open()
                        await _settle()
                        if OS.get_environment("QA_DUMP") != "":
                                var scroll: ScrollContainer = null
                                for bx in G.cs_sheets[0]["box"].get_children():
                                        if bx is ScrollContainer:
                                                scroll = bx
                                var shelf: Container = scroll.get_child(0)
                                for kid in shelf.get_children():
                                        var fs := -1
                                        var txt := ""
                                        if kid is Label:
                                                fs = (kid as Label).get_theme_font_size("font_size")
                                                txt = (kid as Label).text
                                        elif kid is Button:
                                                for k2 in _all_kids_btn(kid):
                                                        if k2 is Label:
                                                                fs = (k2 as Label).get_theme_font_size("font_size")
                                                                txt = (k2 as Label).text
                                        print("QA_ROW: %-14s h=%3.0f fs=%d w=%3.0f | %s" % [kid.get_class(),
                                                        kid.size.y, fs, kid.size.x, txt.left(40)])
                                print("QA_SHELF min_y=", shelf.get_combined_minimum_size().y,
                                                " scroll_min_y=", (shelf.get_parent() as Control).custom_minimum_size.y)
                "door":
                        G._cs_close_all()
                        G.phase = "boot"
                        G._boot_hint = ""
                        G._optionals_open()
                        await _settle()
                _:
                        G._cs_close_all()
                        G._start_run()
                        await _wait_frames(10)
                        # the honest meters: HP at 55%, XP most of the level, some coins
                        G.p_hp = G.p_max_hp * 0.55
                        G.run_xp = int(CSData.xp_for_run_level(G.run_level) * 0.62)
                        G.run_coins = 0
                        Box.earn(50)     # the wallet total - the HUD chip must NOT show this
                        G._spawn_enemy("sprinter", G.p_pos + Vector2(240, -60))
                        G._spawn_enemy("chunk", G.p_pos + Vector2(-290, 50))
                        G._spawn_enemy("wraith", G.p_pos + Vector2(150, -200))
                        G._spawn_enemy("spitter", G.p_pos + Vector2(-150, 250))
                        await _wait_frames(60)   # the meters animate toward their truth
        var shot := OS.get_environment("QA_SHOT")
        if shot.is_empty():
                shot = "/tmp/qa_v034p4_%s.png" % rig
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(shot)
        print("qa_v034p4 shot: ", shot)
        get_tree().quit(0)

func _settle() -> void:
        await _wait_frames(12)

func _all_kids_btn(root: Node) -> Array:
        var out: Array = []
        for c in root.get_children():
                out.append(c)
                out.append_array(_all_kids_btn(c))
        return out

func _wait_frames(n: int) -> void:
        for i in n:
                await get_tree().process_frame
