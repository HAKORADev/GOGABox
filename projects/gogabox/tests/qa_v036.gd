extends Node
## qa_v036 - the GEOMETRY FLASH Xvfb shot driver (v0.3.6).
## Rigs (QA_GAME=gf + QA_RIG env):
##  gf/ready   - THE TAP ANYWHERE gate over the idle breathing world
##  gf/run     - a live NORMAL run: orbits, a spike fence, the pusher
##  gf/flip    - the FLIP mechanic mid-sail (gravity up, roof riding)
##  gf/sticky  - the STICKY leap mid-air
##  gf/coin    - the GOGACoin floating in the lane
##  gf/shop    - the shop sheet (skins/themes/tails)
##  gf/theme   - the SOLAR theme wearing the world
##  gf/death   - the pit death burst moment
##
##  QA_GAME=gf QA_RIG=run xvfb-run -a godot --path . --resolution 1920x1080 \
##      res://tests/qa_v036.tscn

var G: GogaGame

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        var rig := OS.get_environment("QA_RIG")
        if rig.is_empty():
                rig = "run"
        get_window().size = Vector2i(1920, 1080)
        ScaleRule.apply(get_window())
        Box.reset_all()                  # the TRUE first-run look (midnight)
        Box.dev_set_cheat("all_owned", 1)
        Box.dev_set_cheat("gogacoins", 0)
        Box.earn(5000)
        await _gf(rig)
        await _settle(6)
        var shot := "user://qa_v036_gf_%s.png" % rig
        var img := get_viewport().get_texture().get_image()
        img.save_png(shot)
        print("QA SHOT SAVED: ", shot)
        get_tree().quit(0)

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout

func _settle(frames: int) -> void:
        for i in frames:
                await get_tree().process_frame

func _boot() -> void:
        G = load("res://game/games/geometry/geometry.gd").new()
        G.game_id = "geometry"
        add_child(G)
        await _wait(1.0)

func _gf(rig: String) -> void:
        await _boot()
        G.probe_reset(4242)
        G.paused = false
        G.speed = G.BASE_SPEED
        match rig:
                "ready":
                        # the gate itself: back to the ready phase
                        G.queue_free()
                        await _wait(0.4)
                        await _boot()
                "run":
                        G._ready_start()
                        # sprint into the generated world: let chunks fly by
                        for i in 240:
                                G.probe_step(1.0 / 60.0)
                                if i % 12 == 0:
                                        G._do_action()          # the rhythm taps
                        G.mechanic = "normal"
                "flip":
                        G._ready_start()
                        G.mechanic = "flip"
                        G._do_action()                  # the sail up
                        for i in 20:
                                G.probe_step(1.0 / 60.0)
                "sticky":
                        G._ready_start()
                        G.mechanic = "sticky"
                        G._do_action()                  # the leap
                        for i in 14:
                                G.probe_step(1.0 / 60.0)
                "coin":
                        G._ready_start()
                        for i in 90:
                                G.probe_step(1.0 / 60.0)
                        G._coin_spawn()
                        G.coin["x"] = G.world_x + G.stand_x / G.us + 300.0
                        for i in 6:
                                G.probe_step(1.0 / 60.0)
                "shop":
                        G._ready_start()
                        G._shop_open()
                "theme":
                        Box.equip_item("geometry", "theme", "solar")
                        G._apply_theme()
                        G._ready_start()
                        for i in 60:
                                G.probe_step(1.0 / 60.0)
                "death":
                        G._ready_start()
                        for i in 60:
                                G.probe_step(1.0 / 60.0)
                        G.gsegs = [{"x0": -3000.0, "x1": G.world_x + G.stand_x / G.us - G.CELL, "spr": null}]
                        for i in 30:
                                G.probe_step(1.0 / 60.0)
                                if G.over_gate:
                                        break
                        print("[qa] death: over=%s pspr_visible=%s p.y=%.0f" % [
                                G.over_gate, G.pspr.visible, G.player["y"]])
