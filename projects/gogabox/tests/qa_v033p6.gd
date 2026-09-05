extends Node
## qa_v033p6 - the PATCH 6 Xvfb shot driver. Three rigs, picked by QA_RIG:
##   spawn  - a mid-pour frame: the gems emerging from behind the top line
##   hint   - an armed power with its hint floating ABOVE the rail
##   ice2   - the SECOND LAYER: tier-1 freeze summons it (the heavy coat)
##   sweep  - the challenge loss theatre: the bottom-to-top clear mid-flight
##   DISPLAY=:95 QA_RIG=spawn godot --path . res://tests/qa_v033p6.tscn
## QA_SHOT picks the output png.

var G: GogaGame

func _ready() -> void:
        Box.dev_set_cheat("all_owned", 1)
        var rig := OS.get_environment("QA_RIG")
        if rig.is_empty():
                rig = "spawn"
        var mode := "challenge"
        if rig == "ice2":
                mode = "ice"
        G = load("res://game/games/matcher/matcher.gd").new()
        G.game_id = "matcher"
        G.mode = mode
        add_child(G)
        for i in 40:
                await get_tree().create_timer(0.25).timeout
                if G.pick_open:
                        break
        G._pick_close()
        G._start_mode(mode)
        var settle_frames := 10 if rig == "spawn" else 80
        for i in settle_frames:
                await get_tree().create_timer(0.25).timeout
                if G.grid.size() >= 8 and not G.busy and G.phase == "play" \
                                and not G.pick_open:
                        break
        match rig:
                "spawn":
                        # catch the pour MID-FLIGHT: re-arm a fresh deal and
                        # shoot the emergence window
                        G._deal_board()
                        await get_tree().create_timer(0.55).timeout
                "hint":
                        G.phase = "play"
                        G.busy = false
                        G.armed = "bomb"
                        G.charges["bomb"] = 1
                        G.power_used["bomb"] = 0
                        G._set_armed_cursor(true)
                        await get_tree().create_timer(0.5).timeout
                "ice2":
                        G.phase = "play"
                        G.busy = false
                        G.frost[3] = G.ROWS - 1
                        G.fronts = [{"col": 3, "f": 0.9, "speed": 0.6}]
                        for i in 120:
                                await get_tree().create_timer(0.05).timeout
                                if int(G.ice_tier[3]) >= 2:
                                        break
                        # let the second layer climb a little, then hold
                        G.fronts[0]["speed"] = 0.0
                        for i in 40:
                                G._tick_ice(0.05)
                        G.frost[3] = 4
                        G._refresh_ice()
                        await get_tree().create_timer(0.4).timeout
                "sweep":
                        G.phase = "play"
                        G.round_start = int(G.score)
                        G.round_bank = 0
                        G.round_clock = 0.15
                        G.ch_lives = 3
                        for i in 60:
                                await get_tree().create_timer(0.1).timeout
                                if G.ch_sweeping:
                                        break
                        await get_tree().create_timer(0.3).timeout
        await get_tree().create_timer(0.6).timeout
        if OS.get_environment("QA_SHOT") != "":
                for i in 3:
                        await get_tree().create_timer(0.25).timeout
                        var img := get_viewport().get_texture().get_image()
                        img.save_png(OS.get_environment("QA_SHOT"))
                        break
        print("[qa_v033p6] rig %s shot done" % rig)
        get_tree().quit(0)
