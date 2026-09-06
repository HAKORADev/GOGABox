extends Node
## qa_v035p1_pop - the POP SIEGE Xvfb shot driver (v0.3.5-1, the real-art
## patch). Rigs (QA_RIG env):
##   ready  - the START gate over the painted board
##   field  - the battlefield: gadgets with tracking heads, bloons marching
##   place  - the placement ghost + the gold card highlight
##   menu   - the upgrade menu (the >> law) with a placed gadget
##   maps   - THE MAPS wall (two columns, painted thumbs, D/N chips)
##   shop   - the wider scrollable shop
##   night  - the night grade + fireflies
##   nextw  - the pink NEXT WAVE button mid-roll
##   DISPLAY=:95 QA_RIG=maps godot --path . res://tests/qa_v035p1_pop.tscn

var G: GogaGame

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Box.reset_all()
	Box.dev_set_cheat("all_owned", 1)
	get_window().size = Vector2i(1920, 1080)
	await get_tree().create_timer(0.2).timeout
	var rig := OS.get_environment("QA_RIG")
	if rig.is_empty():
		rig = "field"
	G = load("res://game/games/pop_siege/pop_siege.gd").new()
	G.game_id = "pop_siege"
	add_child(G)
	await get_tree().create_timer(1.2).timeout
	match rig:
		"ready":
			pass
		"field":
			G._start_ready()
			G.coins = 3000
			G._place_folk("darty", Vector2i(4, 3))
			G._place_folk("pyra", Vector2i(6, 5))
			G._place_folk("boomba", Vector2i(3, 6))
			G._place_folk("kolda", Vector2i(7, 2))
			G._place_folk("marshal", Vector2i(9, 4))
			G._place_folk("kaching", Vector2i(11, 6))
			G._next_wave_pressed()
			for i in 200:
				await get_tree().process_frame
			G._goga_tick(0.4)
			G._goga_tick(0.4)
			await _wait_frames(40)
		"place":
			G._start_ready()
			G.coins = 3000
			G._place_folk("darty", Vector2i(4, 3))
			G._card_tapped("pyra")
			G._ghost_follow(G._cell_pos(8, 4))
			await _wait_frames(12)
		"menu":
			G._start_ready()
			G.coins = 3000
			G._place_folk("pyra", Vector2i(6, 4))
			G._select_folk(G.folk[0])
			G._spawn_bloon("rainbow", 0)
			await _wait_frames(20)
		"maps":
			G._maps_open()
			await _wait_frames(24)
		"shop":
			G._shop_open()
			await _wait_frames(24)
		"night":
			G.meta.set_night(G.map["id"], true)
			G.night = true
			G._build_night()
			G._start_ready()
			G.coins = 3000
			G._place_folk("zappy", Vector2i(5, 4))
			G._place_folk("kaching", Vector2i(7, 6))
			G._next_wave_pressed()
			for i in 120:
				await get_tree().process_frame
			await _wait_frames(30)
		"nextw":
			G._start_ready()
			G.coins = 3000
			G._place_folk("boomba", Vector2i(8, 5))
			G._next_wave_pressed()
			for i in 90:
				await get_tree().process_frame
			G._next_wave_pressed()
			await _wait_frames(30)
	var shot := OS.get_environment("QA_SHOT")
	if shot.is_empty():
		shot = "/tmp/qa_v035p1_pop_%s.png" % rig
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shot)
	print("qa_v035p1_pop shot: ", shot)
	get_tree().quit(0)

func _wait_frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
