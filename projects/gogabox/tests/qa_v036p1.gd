extends Node
## qa_v036p1 - the GEOMETRY FLASH Xvfb shot driver (v0.3.6-1).
## Rigs (QA_GAME=gf1 + QA_RIG env):
##  gf1/tail_fire   - the FIRE tail streaming BEHIND the square (the tail law)
##  gf1/tail_gold   - the GOLD tail (sparkle overlay layer)
##  gf1/tail_none   - NONE = a clean square, no emitter at all (the none bug)
##  gf1/landing     - the impact ring ON the collision (the landing law)
##  gf1/collect     - the orbit implosion (star + inward ring + dive streaks)
##  gf1/death       - the layered death (double shockwave + ghost + shards)
##  gf1/powjump     - ROCKET JUMP live: the burn plume + the chip
##  gf1/powslow     - SLOW WORLD live: the chip + the paused-feel world
##  gf1/powshield   - EXTRA LIFE live: the dark core + aura + the chip
##  gf1/coin        - the resized GOGACoin (44px core)
##  gf1/powshop     - the shop with the POWER-UPS rows
##  gf1/stick_roof  - STICK mode stuck to the roof (the touch flip)
##
##  QA_RIG=run xvfb-run -a godot --path . --resolution 1920x1080 \
##      res://tests/qa_v036p1.tscn

var G: GogaGame

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        var rig := OS.get_environment("QA_RIG")
        if rig.is_empty():
                rig = "tail_fire"
        get_window().size = Vector2i(1920, 1080)
        ScaleRule.apply(get_window())
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        Box.dev_set_cheat("gogacoins", 0)
        Box.earn(5000)
        await _gf(rig)
        await _settle(6)
        var shot := "user://qa_v036p1_gf1_%s.png" % rig
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
                "tail_fire":
                        Box.equip_item("geometry", "tail", "fire")
                        G.trail_mode = "fire"
                        G._apply_tail()
                        G._ready_start()
                        for i in 70:
                                G.probe_step(1.0 / 60.0)
                "tail_gold":
                        Box.equip_item("geometry", "tail", "gold")
                        G.trail_mode = "gold"
                        G._apply_tail()
                        G._ready_start()
                        for i in 70:
                                G.probe_step(1.0 / 60.0)
                "tail_none":
                        G._ready_start()
                        for i in 70:
                                G.probe_step(1.0 / 60.0)
                        print("[qa] none: tail.emitting=%s tail2.emitting=%s" %
                                        [G.tail.emitting, G.tail2.emitting])
                "landing":
                        G._ready_start()
                        # a HIGH fall -> a big impact ring, and freeze the frame 2 steps
                        # after the touch (the ring lives 0.34s = the burst is young)
                        G.player["ground"] = false
                        G.player["y"] = (G.L2_Y - G.HALF) * G.us
                        G.player["vy"] = 0.0
                        for i in 60:
                                G.probe_step(1.0 / 60.0)
                                if G.player["ground"]:
                                        break
                        G.probe_step(1.0 / 60.0)
                        G.paused = true                # freeze the VFX alive
                        G._layout_world()
                "collect":
                        G._ready_start()
                        for i in 40:
                                G.probe_step(1.0 / 60.0)
                        var oy: float = G.GROUND_Y - G.HALF
                        G._add_orbit(G.world_x + G.stand_x / G.us, oy)
                        G.probe_step(1.0 / 60.0)
                        G.probe_step(1.0 / 60.0)   # the implosion frame
                "death":
                        G._ready_start()
                        for i in 60:
                                G.probe_step(1.0 / 60.0)
                        G._die("repro")
                        G.probe_step(1.0 / 60.0)
                        G.probe_step(1.0 / 60.0)
                "powjump":
                        G.powers["jump"] = 9.0
                        G._ready_start()
                        G._do_action()
                        for i in 12:
                                G.probe_step(1.0 / 60.0)
                "powslow":
                        G.powers["slow"] = 10.0
                        G._ready_start()
                        for i in 30:
                                G.probe_step(1.0 / 60.0)
                "powshield":
                        G.powers["shield"] = 10.0
                        G._ready_start()
                        for i in 30:
                                G.probe_step(1.0 / 60.0)
                "coin":
                        G._ready_start()
                        for i in 90:
                                G.probe_step(1.0 / 60.0)
                        G._coin_spawn()
                        G.coin["x"] = G.world_x + G.stand_x / G.us + 300.0
                        for i in 6:
                                G.probe_step(1.0 / 60.0)
                "powshop":
                        G._ready_start()
                        G._shop_open()
                        # scroll the sheet to the POWER-UPS rows
                        await _wait(0.4)
                        _find_scroll(G._overlay_root_ref())
                "stick_roof":
                        G._ready_start()
                        G.mechanic = "sticky"
                        G.rsegs = [{"x0": -3000.0, "x1": 60000.0, "spr": null}]
                        G.player["ground"] = false
                        G.player["g"] = 1
                        G.player["y"] = (G.L3_Y - G.HALF - 60.0) * G.us
                        G.player["vy"] = -1000.0 * G.us
                        for i in 30:
                                G.probe_step(1.0 / 60.0)
                                if G.player["g"] == -1:
                                        break
                        print("[qa] stick_roof: g=%d ground=%s y=%.0f" %
                                        [G.player["g"], G.player["ground"], G.player["y"]])
                _:
                        pass
