extends Node
## qa_v027 - the v0.2.7 visual QA (the owner's rule: LOOK before shipping).
## Tower: the now-VISIBLE coin + pickup, the top-left powerup widget, the
## dropper mid-fall, the size platform mid-breath, the vanish crack +
## shatter chunks, the shard settling on its TRUE side. 2048: the centered
## big board, a mid-slide blur of motion, the coin cell, the Deep Sea water
## tiles, the Minecraft block tiles, the theme shop.
## Run under Xvfb:
##   DISPLAY=:99 godot --path . res://tests/qa_v027.tscn

const OUT := "/home/z/my-project/download/qa_v027/"

func _shot(path: String) -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        img.save_png(path)
        print("[qa] ", path)

func _run() -> void:
        DirAccess.make_dir_recursive_absolute(OUT)
        Box.reset_all()
        Box.dev_set_cheat("all_owned", 1)

        # ================= the SNOWY TOWER =================
        var g: GogaGame = load("res://game/games/hopper/hopper.gd").new()
        g.game_id = "hopper"
        add_child(g)
        await get_tree().create_timer(1.2).timeout
        g._start()
        await get_tree().create_timer(0.3).timeout

        # 1. the coin + pickup VISIBLE (the owner collected ghosts before)
        g.coins.append({"x": g.px + 70.0 * g.U, "y": g.py - 10.0 * g.U, "idx": 9999, "t": 0.6})
        g.coins.append({"x": g.px + 150.0 * g.U, "y": g.py + 40.0 * g.U, "idx": 9998, "t": 0.08})
        g.pickups.append({"x": g.px - 90.0 * g.U, "y": g.py, "idx": 9997, "kind": "x2", "t": 0.5})
        await get_tree().create_timer(0.25).timeout
        await _shot(OUT + "01_tower_coin_pickup_visible.png")
        g.coins.clear()
        g.pickups.clear()

        # 2. the powerup widget TOP-LEFT next to the score
        g.pw = {"id": "big", "t": 7.4}
        g._refresh_pw_ui()
        await get_tree().create_timer(0.2).timeout
        await _shot(OUT + "02_tower_widget_topleft.png")
        g.pw = {"id": "", "t": 0.0}
        g._refresh_pw_ui()

        # 3. the vanish crack + the SHATTER chunks mid-air
        for p in g.platforms:
                if String(p["type"]) == "vanish":
                        p["ghost"] = true
                        p["visible"] = true
                        p["clock"] = 0.35
        g._shatter_platform(g.platforms[g.platforms.size() - 1])
        await get_tree().create_timer(0.12).timeout
        await _shot(OUT + "03_tower_break_chunks.png")

        # 4. a size platform mid-breath + a dropper falling under the ball
        var vp: Vector2 = g.get_viewport_rect().size
        var szp := {"idx": 9001, "x": vp.x * 0.62, "y": g.cam_y + vp.y * 0.30,
                        "w": 200.0 * g.U, "type": "size", "snow": 0.4, "visible": true,
                        "clock": 0.85, "ghost": false, "dir": 1.0, "spd": 0.0,
                        "dx": 0.0, "dy": 0.0, "base_w": 200.0 * g.U, "y0": 0.0,
                        "drop_v": 0.0, "drop_state": "idle"}
        szp["y0"] = float(szp["y"])
        g.platforms.append(szp)
        var drp := {"idx": 9002, "x": vp.x * 0.30, "y": g.cam_y + vp.y * 0.62,
                        "w": 180.0 * g.U, "type": "dropper", "snow": 0.2, "visible": true,
                        "clock": 0.0, "ghost": false, "dir": 1.0, "spd": 0.0,
                        "dx": 0.0, "dy": 0.0, "base_w": 180.0 * g.U, "y0": 0.0,
                        "drop_v": 260.0 * g.U, "drop_state": "down"}
        drp["y0"] = float(drp["y"])
        g.platforms.append(drp)
        await get_tree().create_timer(0.05).timeout
        await _shot(OUT + "04_tower_size_and_dropper.png")

        # 5. the shard resting on its TRUE side (the math fix, by eye)
        g.char_id = "shard"
        g.tumble_rot = H_SETTLE()
        g.player.rotation = g.tumble_rot
        g._update_support(1.0 / 60.0)
        g.player.queue_redraw()
        await get_tree().create_timer(0.2).timeout
        await _shot(OUT + "05_tower_shard_edge_down.png")
        g.char_id = "ball"
        g.player.queue_redraw()

        # 6. the banner reserve: the HUD + the world must clear the strip
        print("[qa] banner_bottom = %.1f (the strip's place)" % g.banner_bottom())

        g.queue_free()

        # ================= the 2048 =================
        var m: GogaGame = load("res://game/games/merge/merge2048.gd").new()
        m.game_id = "merge"
        add_child(m)
        await get_tree().create_timer(0.8).timeout
        # 7. the centered big board (classic)
        await _shot(OUT + "06_merge_classic_centered.png")

        # 8. the coin cell on the board
        var empty := Vector2i(-1, -1)
        for x in 4:
                for y in 4:
                        if int(m.board[x][y]) == 0:
                                empty = Vector2i(x, y)
                                break
        if empty.x >= 0:
                m.coin_cell = empty
                m.coin_t = 0.6
                m.coin_layer.queue_redraw()
                await get_tree().create_timer(0.2).timeout
                await _shot(OUT + "07_merge_coin_cell.png")
        m.coin_cell = Vector2i(-1, -1)

        # 9. a live slide (tiles mid-tween)
        m._on_swipe(Vector2i(0, 1), Vector2.ZERO)
        await get_tree().create_timer(0.06).timeout
        await _shot(OUT + "08_merge_mid_slide.png")
        await get_tree().create_timer(0.4).timeout

        # 10. the DEEP SEA theme (the water in the tiles)
        Box.equip_item("merge", "theme", "sea")
        m._apply_theme()
        await get_tree().create_timer(0.4).timeout
        m._on_swipe(Vector2i(-1, 0), Vector2.ZERO)
        await get_tree().create_timer(0.05).timeout
        await _shot(OUT + "09_merge_sea_water.png")
        await get_tree().create_timer(0.5).timeout

        # 11. the MINECRAFT theme (blocks + lava glow)
        Box.equip_item("merge", "theme", "minecraft")
        m._apply_theme()
        # stage a HOT tile so the lava glow + embers show for real
        for c in m.tiles:
                var t: Node = m.tiles[c]
                if is_instance_valid(t):
                        t.setup(512, m, m.cell)
                        m.board[c.x][c.y] = 512
                        break
        await get_tree().create_timer(0.4).timeout
        await _shot(OUT + "10_merge_minecraft.png")

        # 12. the theme shop
        m._shop_open()
        await get_tree().create_timer(0.4).timeout
        await _shot(OUT + "11_merge_shop.png")

        print("[qa] done")
        get_tree().quit(0)

func H_SETTLE() -> float:
        var s: Script = load("res://game/games/hopper/hopper.gd")
        return float(s.SHARD_SETTLE_ANG)

func _ready() -> void:
        _run.call_deferred()
