extends Node
## HEAVY WAR v040-5 film - THE VISION LAW: the rig has eyes, use them
## BEFORE the owner has to. Renders the code-drawn art to stills:
## the tank (all skins), EVERY enemy kind, every boss brain, the scrap
## shop, the menu, the HUD, and every place's environment.
## Run: xvfb-run godot --path . --rendering-driver opengl3 \
##        res://tests/hw5_film.tscn

var G: GogaGame = null
var shot_dir := "/home/z/my-project/gogabox/films/v040-6"

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true).timeout

func _shot(name: String) -> void:
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png("%s/%s.png" % [shot_dir, name])
        print("[FILM] shot ", name)

func _tap(idx: int, pos: Vector2, down: bool) -> void:
        var e := InputEventScreenTouch.new()
        e.index = idx
        e.position = pos
        e.pressed = down
        G._goga_input(e)

func _stage_enemy(kind: String, x: float, y: float) -> Dictionary:
        var def: Dictionary = HWData.ENEMIES[kind]
        var e := {
                "kind": kind, "hp": float(def["hp"]), "maxhp": float(def["hp"]),
                "size": float(def["size"]), "speed": 0.0, "dir": -1,
                "x": x, "y": y, "base_y": y, "t": randf() * 4.0, "phase": 0.0,
                "hit": 0.0, "shield": float(def.get("shield", 0)),
                "move": String(def["move"]), "weapon": String(def["weapon"]),
                "shoot_t": 999.0, "ground": false, "chill": 0.0,
                "hover_x": x, "diving": false, "laser_t": 0.0, "laser_on": false,
        }
        G.enemies.append(e)
        return e

func _stage_boss(idx: int, x: float, y: float) -> void:
        var def: Dictionary = HWData.BOSSES[idx]
        var b := {
                "kind": "boss", "boss_id": String(def["id"]),
                "name": String(def["name"]), "brain": String(def["brain"]),
                "hp": 1000.0, "maxhp": 1000.0, "size": float(def["size"]) * 0.7,
                "x": x, "y": y, "base_y": y, "t": 0.0, "dir": -1, "hit": 0.0,
                "arrived": true, "vx": 0.0, "weapon_t": 99.0, "weapon_cycle": 0,
                "spawn_t": 99.0, "enraged": idx == 9, "chill": 0.0, "dash_dir": -1,
                "scrap": 30, "xp": 40,
        }
        G.enemies.append(b)

func _run() -> void:
        DirAccess.make_dir_recursive_absolute(shot_dir)
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)
        Box.earn(5000)
        get_window().size = Vector2i(1920, 1080)
        ScaleRule.apply(get_window())
        await _wait(0.3)
        G = load("res://game/games/heavywar/heavywar.gd").new()
        G.game_id = "heavywar"
        add_child(G)
        await _wait(1.0)
        await _shot("01_intro")

        # the menu (tap anywhere -> deploy / scrap shop)
        _tap(9, Vector2(960, 540), true)
        _tap(9, Vector2(960, 540), false)
        await _wait(0.5)
        await _shot("02_menu")

        # the scrap shop sheet (menu button 2), then the box shop (button 3)
        G._menu_tap(Vector2(G.W / 2, G.H * 0.42 + 88.0 + 20.0 + 44.0))
        await _wait(0.7)
        await _shot("03_scrap_shop")
        if G._sheet_stack.size() > 0:
                G.sheet_pop()
        await _wait(0.4)
        G._menu_tap(Vector2(G.W / 2, G.H * 0.42 + (88.0 + 20.0) * 2.0 + 44.0))
        await _wait(0.7)
        await _shot("03b_box_shop")
        if G._sheet_stack.size() > 0:
                G.sheet_pop()
        await _wait(0.4)

        # deploy: some scrap money for the war chest look
        G._menu_tap(Vector2(G.W / 2, G.H * 0.42 + 20.0))
        await _wait(2.0)
        await _shot("04_place_iron")

        # ---- the TANK lineup: wheels + MGs + pods, all skins
        var skins := ["olive", "dune", "frost", "night", "magma"]
        for i in skins.size():
                Box.equip_skin("heavywar", skins[i])
                G._apply_skin()
                await _wait(0.25)
                await _shot("10_tank_%s" % skins[i])

        # ---- the enemies parade (2 rows of staged kinds)
        G.enemies.clear()
        var kinds: Array = HWData.ENEMIES.keys()
        for i in kinds.size():
                var k := String(kinds[i])
                var col := i % 7
                var row := i / 7
                _stage_enemy(k, 240.0 + col * 240.0, 200.0 + row * 210.0)
        G.p_x = 960.0
        await _wait(0.8)
        await _shot("20_enemy_parade_1")
        # hit flash on one
        if G.enemies.size() > 3:
                (G.enemies[3] as Dictionary)["hit"] = 0.09
        await _wait(0.15)
        await _shot("21_enemy_hitflash")

        # ---- the bosses
        G.enemies.clear()
        for i in 5:
                _stage_boss(i, 320.0 + i * 360.0, 240.0)
        await _wait(0.7)
        await _shot("22_bosses_1")
        G.enemies.clear()
        for i in range(5, 10):
                _stage_boss(i, 320.0 + (i - 5) * 360.0, 240.0)
        await _wait(0.7)
        await _shot("23_bosses_2")

        # ---- the drops: xp orbs, scrap cogs, a coin
        G.enemies.clear()
        for i in 6:
                G.drops.append({"x": 660.0 + i * 100.0, "y": 420.0,
                        "vx": 0.0, "vy": 0.0, "kind": "xp", "value": 1,
                        "t": float(i), "life": 30.0, "grounded": true,
                        "seed": float(i)})
        for i in 6:
                G.drops.append({"x": 660.0 + i * 100.0, "y": 560.0,
                        "vx": 0.0, "vy": 0.0, "kind": "scrap", "value": 1,
                        "t": float(i), "life": 30.0, "grounded": true,
                        "seed": float(i)})
        G.drops.append({"x": 960.0, "y": 700.0, "vx": 0.0, "vy": 0.0,
                "kind": "coin", "value": 1, "t": 0.0, "life": 30.0,
                "grounded": true, "seed": 0.0})
        await _wait(0.6)
        await _shot("24_drops")

        # ---- the fx: an explosion mid-burst
        G.enemies.clear()
        G.drops.clear()
        G._explode(960.0, 460.0, 1.5)
        G._explode(700.0, 560.0, 1.0)
        await _wait(0.14)
        await _shot("25_fx_boom")
        await _wait(0.25)
        await _shot("26_fx_boom_late")

        # ---- every place's environment (swap place_i + rebuild sky)
        for pi in 10:
                G.place_i = pi
                G._sky_node()
                G.scroll_x = float(pi) * 137.0
                G.enemies.clear()
                G.wave = 1
                G.wave_state = "idle"
                G.state = G.GS.PLACE
                G.banner_t = 0.0
                await _wait(0.45)
                await _shot("3x_place_%s" % String(HWData.PLACES[pi]["key"]))

        # ---- the tunnel: the portal approach + the drive inside ----
        G.place_i = 0
        G._sky_node()
        G.state = G.GS.PLACE
        G._enter_tunnel()
        G.tunnel["portal_x"] = 1250.0
        await _wait(0.4)
        await _shot("40_tunnel_portal")
        G.tunnel["phase"] = "inside"
        G.tunnel["inside_t"] = 1.0
        G.scroll_x = 900.0
        for i in 4:
                G.drops.append({"x": 900.0 + i * 90.0, "y": G.GROUND_Y - 88.0,
                        "vx": 0.0, "vy": 0.0, "kind": "coin", "value": 1,
                        "t": float(i), "life": 30.0, "grounded": true, "seed": float(i)})
        await _wait(0.5)
        await _shot("41_tunnel_inside")
        if G.tunnel_node != null and is_instance_valid(G.tunnel_node):
                G.tunnel_node.queue_free()
                G.tunnel_node = null
        G.tunnel = {}
        G.drops.clear()
        G.state = G.GS.PLACE

        # ---- the crosshair + HUD in action
        G.state = G.GS.PLACE
        _tap(3, Vector2(1400.0, 300.0), true)
        G.aim_ptr = 3
        G.aim_pos = Vector2(1400.0, 300.0)
        await _wait(0.4)
        await _shot("41_hud_aim")
        _tap(3, Vector2(1400.0, 300.0), false)

        # ---- THE THUMB FRAME: one composed shot for the thumbnail
        G.meta.set_upg("wheels", 3)
        G.meta.set_upg("mg", 1)
        G.meta.set_upg("rockets", 1)
        G.meta.set_upg("rocket_rack", 1)
        G.place_i = 0
        G._sky_node()
        G.state = G.GS.PLACE
        G.banner_t = 0.0
        G.wave_state = "clearing"   # no spawns while we compose
        G.enemies.clear()
        G.drops.clear()
        G.shots.clear()
        G.rockets.clear()
        G.fx.clear()
        G.hud_draw.visible = false
        if G._hud != null and is_instance_valid(G._hud):
                G._hud.visible = false
        # the incoming machines
        var te := {"hp": 50.0, "maxhp": 50.0, "speed": 0.0, "t": 1.2,
                "phase": 1.0, "hit": 0.0, "shield": 0.0, "shoot_t": 999.0,
                "ground": false, "chill": 0.0, "diving": false,
                "laser_t": 0.0, "laser_on": false, "arrived": true,
                "hover_x": 960.0, "base_y": 0.0}
        for st in [["carpet", 560.0, 430.0, -1], ["gunship", 1300.0, 400.0, 1],
                ["shredder", 1180.0, 560.0, 1], ["laserd", 600.0, 350.0, -1],
                ["fighter", 450.0, 700.0, -1]]:
                var d2: Dictionary = HWData.ENEMIES[String(st[0])]
                var e2 := te.duplicate()
                e2["kind"] = String(st[0])
                e2["size"] = float(d2["size"])
                e2["x"] = float(st[1])
                e2["y"] = float(st[2])
                e2["base_y"] = float(st[2])
                e2["dir"] = int(st[3])
                e2["move"] = String(d2["move"])
                e2["weapon"] = String(d2["weapon"])
                G.enemies.append(e2)
        for dd in [[620.0, 760.0, "xp"], [700.0, 800.0, "xp"], [560.0, 810.0, "xp"],
                [1000.0, 750.0, "xp"], [520.0, 880.0, "scrap"], [760.0, 880.0, "scrap"],
                [1080.0, 840.0, "scrap"], [900.0, 820.0, "coin"]]:
                G.drops.append({"x": float(dd[0]), "y": float(dd[1]), "vx": 0.0,
                        "vy": 0.0, "kind": String(dd[2]), "value": 1, "t": 0.4,
                        "life": 30.0, "grounded": true, "seed": 1.0})
        await _wait(0.5)
        await _shot("thumb_frame")
        G.enemies.clear()
        G.drops.clear()
        G.meta.set_upg("wheels", 0)
        G.meta.set_upg("mg", 0)
        G.meta.set_upg("rockets", 0)
        G.meta.set_upg("rocket_rack", 0)
        G.hud_draw.visible = true
        if G._hud != null and is_instance_valid(G._hud):
                G._hud.visible = true
        G.wave_state = "idle"

        # ---- CUTOUT PASS: entities over pure magenta for clean thumbnails
        RenderingServer.set_default_clear_color(Color(1, 0, 1))
        # hide every world sibling EXCEPT the tank
        for n in [G.sky_node, G.sun_node, G.env_draw, G.ent_draw,
                G.shot_draw, G.fx_draw]:
                if n != null and is_instance_valid(n):
                        n.visible = false
        G.hud_draw.visible = false
        G.enemies.clear()
        G.drops.clear()
        G.shots.clear()
        G.rockets.clear()
        G.fx.clear()
        # the tank alone (some scrap upgrades for the full loadout)
        G.meta.set_upg("wheels", 2)
        G.meta.set_upg("mg", 1)
        G.meta.set_upg("rockets", 1)
        await _wait(0.4)
        await _shot("cut_tank")
        G.meta.set_upg("wheels", 0)
        G.meta.set_upg("mg", 0)
        G.meta.set_upg("rockets", 0)
        # every enemy kind
        var kinds2: Array = HWData.ENEMIES.keys()
        for i in kinds2.size():
                G.enemies.clear()
                _stage_enemy(String(kinds2[i]), 960.0, 420.0)
                await _wait(0.22)
                await _shot("cut_e_%s" % String(kinds2[i]))
        # the bosses
        for i in 10:
                G.enemies.clear()
                _stage_boss(i, 960.0, 400.0)
                await _wait(0.22)
                await _shot("cut_b_%s" % String(HWData.BOSSES[i]["id"]))
        # the drops
        G.enemies.clear()
        G.drops.append({"x": 960.0, "y": 420.0, "vx": 0.0, "vy": 0.0,
                "kind": "xp", "value": 1, "t": 0.3, "life": 30.0,
                "grounded": true, "seed": 1.0})
        await _wait(0.2)
        await _shot("cut_xp")
        G.drops.clear()
        G.drops.append({"x": 960.0, "y": 420.0, "vx": 0.0, "vy": 0.0,
                "kind": "scrap", "value": 1, "t": 0.3, "life": 30.0,
                "grounded": true, "seed": 1.0})
        await _wait(0.2)
        await _shot("cut_scrap")
        G.drops.clear()
        G.drops.append({"x": 960.0, "y": 420.0, "vx": 0.0, "vy": 0.0,
                "kind": "coin", "value": 1, "t": 0.3, "life": 30.0,
                "grounded": true, "seed": 1.0})
        await _wait(0.2)
        await _shot("cut_coin")
        RenderingServer.set_default_clear_color(Color(0.1, 0.1, 0.12))
        for n in [G.sky_node, G.sun_node, G.env_draw, G.ent_draw,
                G.shot_draw, G.fx_draw]:
                if n != null and is_instance_valid(n):
                        n.visible = true
        G.hud_draw.visible = true

        print("[FILM] done")
        get_tree().quit(0)

func _ready() -> void:
        _run()
