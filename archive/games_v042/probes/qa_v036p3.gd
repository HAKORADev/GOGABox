extends Node
## qa_v036p3 - the GEOMETRY FLASH Xvfb shot driver (v0.3.6-3, patch 3).
## Rigs (QA_GAME=gf1 + QA_RIG env):
##  gf1/tail_back   - the square mid-rotation, the tail STILL screen-behind
##  gf1/stairs      - the block staircase chunk (the world law)
##  gf1/garden      - the rhythm garden chunk
##  gf1/spike3      - the small triple spike on the ground
##  gf1/rocket      - the jump-power burn ON the jump, from BELOW
##  gf1/rocket_roof - the burn from ABOVE off the roof
##  gf1/flip_push   - the flip switch puff from the side being left
##  gf1/collect     - the golden burst on collect
##  gf1/coin        - the coin spawned via THE COIN SPACE LAW (clear spot)
##  gf1/none_violet - the shop with a tail worn: the NONE row violet
##  gf1/roof_stairs - the hanging roof stairs (flip mode)
##  gf1/world       - a rich generated slice: the populated world
##
##  QA_RIG=<rig> xvfb-run -a godot --path . --resolution 1920x1080 \
##      res://tests/qa_v036p3.tscn

var G: GogaGame

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        var rig := OS.get_environment("QA_RIG")
        if rig.is_empty():
                rig = "stairs"
        get_window().size = Vector2i(1920, 1080)
        ScaleRule.apply(get_window())
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        Box.dev_set_cheat("gogacoins", 0)
        Box.earn(5000)
        await _gf(rig)
        await _settle(6)
        var shot := "user://qa_v036p3_gf1_%s.png" % rig
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

func _find_scroll(n: Node) -> void:
                for c in n.get_children():
                        if c is BoxScroll:
                                (c as BoxScroll).scroll_vertical = 20000
                                return
                        _find_scroll(c)

func _gf(rig: String) -> void:
        await _boot()
        G.probe_reset(4242)
        G.paused = false
        G.speed = G.BASE_SPEED
        match rig:
                "tail_back":
                        Box.equip_item("geometry", "tail", "fire")
                        G.trail_mode = "fire"
                        G._apply_tail()
                        G._ready_start()
                        G.mechanic = "flip"
                        for i in 26:
                                G.probe_step(1.0 / 60.0)
                        G._do_action()          # the flip - the square rotates
                        for i in 10:
                                G.probe_step(1.0 / 60.0)
                        print("[qa] tail_back: rot=%.1f tailx-off=%.1f" % [G.player["rot"],
                                (G.tail.position.x - G.pspr.position.x) / G.us])
                "stairs":
                        G._ready_start()
                        G.pushers.clear()
                        G.orbits.clear()
                        G._chunk_stairs(G.world_x + 1200.0)
                        for i in 40:
                                G.probe_step(1.0 / 60.0)
                "garden":
                        G._ready_start()
                        G.pushers.clear()
                        G.orbits.clear()
                        G._chunk_garden(G.world_x + 1200.0)
                        for i in 40:
                                G.probe_step(1.0 / 60.0)
                "spike3":
                        G._ready_start()
                        G.hazards.clear()
                        G._add_spike3(G.world_x + G.stand_x / G.us + 620.0, G.GROUND_Y)
                        for i in 22:
                                G.probe_step(1.0 / 60.0)
                "rocket":
                        G.powers["jump"] = 9.0
                        G._ready_start()
                        G._do_action()
                        for i in 5:
                                G.probe_step(1.0 / 60.0)
                "rocket_roof":
                        G.powers["jump"] = 9.0
                        G._ready_start()
                        G.mechanic = "flip"
                        G.rsegs = [{"x0": -3000.0, "x1": 60000.0, "spr": null}]
                        G.player["ground"] = false
                        G.player["g"] = -1
                        G.player["y"] = (G.ROOF_Y + G.HALF) * G.us
                        G.player["vy"] = 0.0
                        G.player["ground"] = true
                        G._do_action()
                        for i in 5:
                                G.probe_step(1.0 / 60.0)
                "flip_push":
                        G._ready_start()
                        G.mechanic = "flip"
                        G._do_action()
                        for i in 4:
                                G.probe_step(1.0 / 60.0)
                "collect":
                        G._ready_start()
                        for i in 40:
                                G.probe_step(1.0 / 60.0)
                        var oy: float = G.GROUND_Y - G.HALF
                        G._add_orbit(G.world_x + G.stand_x / G.us, oy)
                        G.probe_step(1.0 / 60.0)
                        G.probe_step(1.0 / 60.0)   # the burst frame
                "coin":
                        G._ready_start()
                        for i in 90:
                                G.probe_step(1.0 / 60.0)
                        G._coin_spawn()
                        if not G.coin.is_empty():
                                G.coin["x"] = G.world_x + G.stand_x / G.us + 300.0
                                print("[qa] coin clear spot=", G._coin_spot_clear(
                                        float(G.coin["x"]), float(G.coin["y"])))
                        for i in 6:
                                G.probe_step(1.0 / 60.0)
                "none_violet":
                        Box.equip_item("geometry", "tail", "neon")
                        G._ready_start()
                        G._shop_open()
                        await _wait(0.4)
                        _find_scroll(G._overlay_root_ref())
                "roof_stairs":
                        G._ready_start()
                        G.mechanic = "flip"
                        G.pushers.clear()
                        G.orbits.clear()
                        G._chunk_roof_stairs(G.world_x + 1100.0)
                        for i in 40:
                                G.probe_step(1.0 / 60.0)
                "world":
                        G._ready_start()
                        G.pushers.clear()
                        G.orbits.clear()
                        G.hazards.clear()
                        var wx: float = G.world_x + 900.0
                        wx += G._chunk_stairs(wx)
                        wx += G._chunk_garden(wx)
                        wx += G._chunk_pyramid(wx)
                        for i in 30:
                                G.probe_step(1.0 / 60.0)
                "deck":
                        G._ready_start()
                        G.pushers.clear()
                        G.orbits.clear()
                        G._chunk_deck(G.world_x + 1100.0)
                        for i in 30:
                                G.probe_step(1.0 / 60.0)
                "down":
                        G._ready_start()
                        G.pushers.clear()
                        G.orbits.clear()
                        G._chunk_down(G.world_x + 1000.0)
                        for i in 30:
                                G.probe_step(1.0 / 60.0)
                "mixed":
                        G._ready_start()
                        G.pushers.clear()
                        G.orbits.clear()
                        G.mechanic = "flip"
                        G._chunk_mixed(G.world_x + 1000.0)
                        for i in 30:
                                G.probe_step(1.0 / 60.0)
                "roof_yard":
                        G._ready_start()
                        G.mechanic = "flip"
                        G.pushers.clear()
                        G.orbits.clear()
                        G._chunk_roof_yard(G.world_x + 1000.0)
                        for i in 30:
                                G.probe_step(1.0 / 60.0)
                "collect_ring":
                        G._ready_start()
                        for i in 40:
                                G.probe_step(1.0 / 60.0)
                        var oy2: float = G.GROUND_Y - G.HALF
                        G._add_orbit(G.world_x + G.stand_x / G.us, oy2)
                        G.probe_step(1.0 / 60.0)
                        G.probe_step(1.0 / 60.0)
                _:
                        pass
        G.paused = true
        get_tree().paused = true     # freeze the one-shot VFX mid-life for the
        G.process_mode = Node.PROCESS_MODE_PAUSABLE   # (detach from the ALWAYS
        G._layout_world()            # rig root; llvmpipe frames are ~0.2s real)
