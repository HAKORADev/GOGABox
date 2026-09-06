extends Node
## qa_v035 - the PATCH-5 Xvfb shot driver. Rigs (QA_RIG env):
##   door   - THE DOOR with THE BIG TEXT law (x1.75) + the WORN theme card
##   info   - the RUN INFO sheet (the 5-line stat blocks)
##   arena  - the auras READING: the wraith's violet field, the warden's gold
##            ring, the mender's green care + THE AIM SIGHT line
##   armory - the armory with the cleaver's "rng 130 (melee)" card
##   DISPLAY=:95 QA_RIG=info godot --path . res://tests/qa_v035.tscn

var G: GogaGame

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        Box.dev_set_cheat("all_owned", 1)
        var rig := OS.get_environment("QA_RIG")
        if rig.is_empty():
                rig = "door"
        G = load("res://game/games/cosmic_spud/cosmic_spud.gd").new()
        G.game_id = "cosmic_spud"
        add_child(G)
        await get_tree().create_timer(1.2).timeout
        match rig:
                "door":
                        G._cs_close_all()
                        G.phase = "boot"
                        G._boot_hint = ""
                        Box.earn(2000)
                        G._shop_buy_theme("park", 0)   # own it: the door reads WORN
                        G._cs_close_all()
                        G._optionals_open()
                        await _settle()
                "info":
                        G._cs_close_all()
                        G._start_run()
                        G.phase = "play"
                        G._apply_stat("dmg", 0.20)
                        G._apply_stat("aspeed", 0.10)
                        G._apply_stat("dmg", -0.08)
                        G._apply_stat("armor", 2)
                        G.run_ccoins = 37
                        G.run_xp = 64
                        G._info_open()
                        await _settle()
                "armory":
                        G._cs_close_all()
                        G.phase = "boot"
                        G._armory_open()
                        await _settle()
                _:
                        G._cs_close_all()
                        G._start_run()
                        G.phase = "play"
                        G.weapons_run = [{"id": "cleaver", "tier": 2, "cd": 0.0}]
                        G._rebuild_slots()
                        await _wait_frames(5)
                        G.p_hp = G.p_max_hp * 0.55
                        G.run_xp = int(CSData.xp_for_run_level(G.run_level) * 0.62)
                        G.meta.d["seen_kinds"] = ["spitter", "wraith", "trishield",
                                        "mender", "warden"]   # silence the hint banners for the shot
                        var w1: Dictionary = G._spawn_enemy("wraith", G.p_pos + Vector2(210, -170))
                        var w2: Dictionary = G._spawn_enemy("warden", G.p_pos + Vector2(-260, -120))
                        var w3: Dictionary = G._spawn_enemy("mender", G.p_pos + Vector2(60, -300))
                        G._spawn_enemy("blab", G.p_pos + Vector2(-160, 120))
                        G._spawn_enemy("chunk", G.p_pos + Vector2(300, 80))
                        w1["aura"] = 250.0
                        w2["ward"] = 260.0
                        w3["heal"] = 500.0
                        await _wait_frames(30)
        var shot := OS.get_environment("QA_SHOT")
        if shot.is_empty():
                shot = "/tmp/qa_v035_%s.png" % rig
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(shot)
        print("qa_v035 shot: ", shot)
        get_tree().quit(0)

func _settle() -> void:
        await _wait_frames(12)

func _wait_frames(n: int) -> void:
        for i in n:
                await get_tree().process_frame
