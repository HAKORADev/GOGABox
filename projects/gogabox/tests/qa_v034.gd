extends Node
## qa_v034 - the COSMIC SPUD Xvfb shot driver. Rigs (QA_RIG env):
##   arena  - the desert day run mid-wave: SPUDNIK + the swarm + the HUD
##   shield - a TRI-SHIELD up close with its rings + a carved window
##   boss   - THE PRISM MATRIARCH on the field with her 4 rings
##   option - the optionals menu: the 6 STARTS
##   shop   - the GOGASHOP weapons tab
##   tree   - the skill tree with a few nodes lit
##   night  - the park night theme mid-run
##   DISPLAY=:95 QA_RIG=arena godot --path . res://tests/qa_v034.tscn

var G: GogaGame

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Box.dev_set_cheat("all_owned", 1)
	var rig := OS.get_environment("QA_RIG")
	if rig.is_empty():
		rig = "arena"
	G = load("res://game/games/cosmic_spud/cosmic_spud.gd").new()
	G.game_id = "cosmic_spud"
	add_child(G)
	await get_tree().create_timer(1.2).timeout
	match rig:
		"option":
			G.meta.d["tree"] = {"o1": true, "o2": true, "l1": true}
			G._close_all_sheets()
			G._optionals_open()
			await _settle()
		"shop":
			G._close_all_sheets()
			G.meta.d["coins"] = 1200
			G._gogashop_open()
			await _settle()
		"tree":
			G._close_all_sheets()
			G.meta.d["tree"] = {"o1": true, "o2": true, "d1": true}
			G._tree_open()
			await _settle()
		"night":
			G._close_all_sheets()
			G.night = true
			G.theme_id = "park"
			G._goga_setup_retheme()
			G._close_all_sheets()
			G._start_run()
			await _wait_frames(50)
			G._spawn_enemy("wraith", G.p_pos + Vector2(300, -60))
			G._spawn_enemy("blab", G.p_pos + Vector2(260, 80))
			G._spawn_enemy("chunk", G.p_pos + Vector2(-320, 20))
			G._spawn_enemy("mender", G.p_pos + Vector2(-180, -160))
			await _wait_frames(30)
		_:
			G._close_all_sheets()
			G._start_run()
			await _wait_frames(40)
			if rig == "shield":
				G.enemies.clear()
				var t: Dictionary = G._spawn_enemy("trishield",
						G.p_pos + Vector2(240, -40))
				t["rings"] = G._mk_rings([90.0, 70.0, 50.0])
				# pre-carve a window so the shot shows the crack law
				t["rings"][0]["cracks"] = [[0.6, 1.4]]
				await _wait_frames(40)
			elif rig == "boss":
				G.enemies.clear()
				G._spawn_boss(20)
				await _wait_frames(40)
			else:
				G._spawn_enemy("sprinter", G.p_pos + Vector2(260, -80))
				G._spawn_enemy("chunk", G.p_pos + Vector2(-300, 60))
				G._spawn_enemy("wraith", G.p_pos + Vector2(150, -200))
				G._spawn_enemy("brood", G.p_pos + Vector2(-220, -160))
				await _wait_frames(45)
	var shot := OS.get_environment("QA_SHOT")
	if shot.is_empty():
		shot = "/tmp/qa_v034_%s.png" % rig
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shot)
	print("qa_v034 shot: ", shot)
	get_tree().quit(0)

func _wait_frames(n: int) -> void:
	for i in n:
		await get_tree().create_timer(0.1, true).timeout

func _settle() -> void:
	for i in 16:
		await get_tree().create_timer(0.1, true).timeout
