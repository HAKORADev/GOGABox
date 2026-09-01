extends Node
## qa_tower - the v0.2.5 SNOWY TOWER visual QA: boots the REAL game scene,
## then screenshots the ready card, the live run (snow + walls + controls),
## a snow-loaded ball, a live powerup ring, the NIGHT place, the three
## other characters, the three other platform skins, and the shop.
## Run under Xvfb:
##   DISPLAY=:99 godot --path . res://tests/qa_tower.tscn

const OUT := "/home/z/my-project/download/qa_v025/"

func _shot(path: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("[qa] ", path)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	Box.reset_all()
	Box.unlock_game("hopper", 0)
	var g: GogaGame = load("res://game/games/hopper/hopper.gd").new()
	g.game_id = "hopper"
	add_child(g)
	await get_tree().create_timer(1.2).timeout
	await get_tree().process_frame

	# 1. the ready card over the living day sky
	await _shot(OUT + "01_ready_day.png")

	# 2. the live run: walking ball, falling snow, walls, controls
	g._start()
	await get_tree().create_timer(0.6).timeout
	g._set_move(1)
	await get_tree().create_timer(0.4).timeout
	g._set_move(0)
	await get_tree().create_timer(0.3).timeout
	await _shot(OUT + "02_run_day.png")

	# 3. a jump mid-air + +1 popup
	g._do_jump()
	await get_tree().create_timer(0.12).timeout
	await _shot(OUT + "03_jump.png")

	# 4. a snow-loaded ball (the heavy look) on a snowy platform
	for p in g.platforms:
		p["snow"] = 0.85
	g.snow_load = 0.85
	g.player.position = Vector2(g.px, g.py)
	await get_tree().create_timer(0.4).timeout
	await _shot(OUT + "04_snow_loaded.png")
	g.snow_load = 0.0

	# 5. a live powerup: the ring + glyph inside the jump button
	g.pw = {"id": "big", "t": 6.0}
	g._refresh_jump_ui()
	await get_tree().create_timer(0.3).timeout
	await _shot(OUT + "05_powerup_ring.png")

	# 6. the coin + pickup look: park a coin and a pickup on the player
	g.coins.append({"x": g.px + 60.0 * g.U, "y": g.py, "idx": 9999, "t": 0.0})
	g.pickups.append({"x": g.px - 70.0 * g.U, "y": g.py, "idx": 9998, "kind": "x2", "t": 0.0})
	g.pw = {"id": "", "t": 0.0}
	g._refresh_jump_ui()
	await get_tree().create_timer(0.25).timeout
	await _shot(OUT + "06_coin_pickup.png")
	g.coins.clear()
	g.pickups.clear()

	# 7. the characters: square / shard / egg
	for pair in [["square", "07_char_square.png"], ["shard", "08_char_shard.png"], ["egg", "09_char_egg.png"]]:
		g.char_id = pair[0]
		g.player.queue_redraw()
		await get_tree().create_timer(0.2).timeout
		await _shot(OUT + pair[1])
	g.char_id = "ball"
	g.player.queue_redraw()

	# 8. the platform skins: rock / metal / grass
	Box.dev_set_cheat("all_owned", 1)   # the QA owns everything it equips
	for pair in [["rock", "10_plat_rock.png"], ["metal", "11_plat_metal.png"], ["grass", "12_plat_grass.png"]]:
		Box.equip_item("hopper", "plat", pair[0])
		g.plat_layer.queue_redraw()
		await get_tree().create_timer(0.2).timeout
		await _shot(OUT + pair[1])
	Box.equip_item("hopper", "plat", "sand")
	g.plat_layer.queue_redraw()

	# 9. the NIGHT place (palette + modulate + stars + aurora)
	Box.equip_item("hopper", "place", "night")
	g._apply_place((g.sky.material as ShaderMaterial))
	g._day_night()
	await get_tree().create_timer(0.5).timeout
	await _shot(OUT + "13_night.png")

	# 10. the shop under the night sky
	Box.dev_set_cheat("gogacoins", 1)
	g._shop_open()
	await get_tree().create_timer(0.4).timeout
	await _shot(OUT + "14_shop.png")

	print("[qa] done")
	get_tree().quit(0)

func _ready() -> void:
	_run.call_deferred()
