extends Node
## qa_v037p2 - the v0.3.7-2 Xvfb shot driver (the owner's "many visual
## tests" round). Rigs (QA_RIG env):
##  tower_geo    - GEOMETRIC style: the inner squares FIT the platforms,
##                 the coin is the REAL GOGACoin, the SAME-PHYSICS cube
##                 (no flip law - it tumbles like the normal square)
##  tower_tail   - the tail ribbon worn in GEOMETRIC
##  gf_flat      - the FLAT WAIT LAW: the tap-anywhere gate on the flat
##                 runway (no prefilled chunks in the view)
##  gf_mixed     - the remixed _chunk_mixed (no block overlap)
##  gf_ready     - the clean tap-anywhere gate (no blue circle)
##  gf_lore      - the lore sheet ABOVE the ready text
##  maze_shop    - the HUD SHOP button + the sheet (skins/tails/themes)
##  maze_tail    - the maze tail ribbon mid-run
##  cs_gore      - a bomb blast: gibs + blood + a fire pool + charred
##
##  QA_RIG=<rig> xvfb-run -a godot --path . res://tests/qa_v037p2.tscn

var G: GogaGame

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var rig := OS.get_environment("QA_RIG")
	if rig.is_empty():
		rig = "tower_geo"
	Box.reset_all()
	Box.dev_set_cheat("all_owned", 1)
	Box.dev_set_cheat("gogacoins", 0)
	Box.earn(20000)
	if rig.begins_with("tower"):
		await _tower(rig)
	elif rig.begins_with("gf"):
		await _gf(rig)
	elif rig.begins_with("maze"):
		await _maze(rig)
	elif rig.begins_with("cs"):
		await _cs(rig)
	await _settle(7)
	var shot := "user://qa_v037p2_%s.png" % rig
	var img := get_viewport().get_texture().get_image()
	img.save_png(shot)
	print("[qa_v037p2] saved ", shot)
	get_tree().quit(0)

func _settle(frames: int) -> void:
	for i in frames:
		await get_tree().process_frame

func _boot(id: String, w: int, h: int) -> void:
	get_window().size = Vector2i(w, h)
	ScaleRule.apply(get_window())
	G = load(GameReg.get_game(id)["script"]).new()
	G.game_id = id
	add_child(G)
	await _settle(4)

# ---------------------------------------------------------------- towers
func _tower(rig: String) -> void:
	await _boot("hopper", 1080, 1920)
	if rig == "tower_tail":
		Box.equip_item("hopper", "tail", "rainbow")
		G.tail_id = "rainbow"
	if not Box.item_owned("hopper", "style", "geometric"):
		Box.buy_item("hopper", "style", "geometric", 0)
	Box.equip_item("hopper", "style", "geometric")
	if G.has_method("_apply_geo_style"):
		G._apply_geo_style()
	G.phase = "run"
	# walk the cube right so the SAME physics reads (the v0.2.6 tumble -
	# the continuous walk-arc rotation, no discrete flip animation)
	for i in 90:
		G._set_axis(0.95)
		G._goga_tick(1.0 / 60.0)
		await _settle(1)
	G._set_axis(0.0)

# ------------------------------------------------------------- geometry
func _gf(rig: String) -> void:
	# the first-launch lore: pre-spend it BEFORE the boot so the run
	# rigs start clean (the lore opens at setup, not later)
	Box.bump_counter("geometry", "geoquare_lore", 1)
	await _boot("geometry", 1920, 1080)
	if rig == "gf_flat":
		# THE FLAT WAIT LAW: the gate sits on the flat runway - the view
		# holds flat ground + roof ONLY (setup no longer prefills chunks)
		await _settle(4)
		return
	if rig == "gf_lore":
		# the first-launch lore: hide the gate, open the sheet
		G.phase = "ready"
		G._lore_open()
		await _settle(4)
		return
	G.phase = "run"
	G._ready_start()
	if rig == "gf_mixed":
		# jump to a mixed chunk zone: seed the world at a chunk border
		G.world_x = 4000.0
		G.gen_x = 4000.0
		G.calm_until = 0.0
		G._gen_ahead()
		# scroll the camera there fast (simulate a long run)
		for i in 120:
			G.world_x += 40.0
			await _settle(1)
		await _settle(30)

# ----------------------------------------------------------------- maze
func _maze(rig: String) -> void:
	await _boot("maze", 1920, 1080)
	if not Box.item_owned("maze", "finder", "finder"):
		Box.buy_item("maze", "finder", "finder", 0)
	Box.equip_item("maze", "tail", "neon")
	G._load_meta()
	G.map_i = 20
	G._new_map()
	if rig == "maze_shop":
		G.phase = "run"
		G._shop_open()
		return
	G.phase = "run"
	if rig == "maze_tail":
		G.tail_id = "neon"
		# walk the route so the ribbon paints
		for i in 10:
			G._swipe_dir(Vector2i(1, 0))
		G.finder_used += 1
		G.finder_left = G.FINDER_DUR
	elif rig == "maze_finder":
		G.finder_used += 1
		G.finder_left = G.FINDER_DUR
		# let the cascade run to the 4th mark
		G.finder_left = G.FINDER_DUR - 0.9

# ----------------------------------------------------------- cosmic spud
func _cs(rig: String) -> void:
	await _boot("cosmic_spud", 1920, 1080)
	G._cs_close_all()
	G.phase = "play"
	# a few enemies + the show: one bomb boom, one molotov pool
	for i in 4:
		G._spawn_enemy([CSData.ENEMIES.keys()[0], CSData.ENEMIES.keys()[1], CSData.ENEMIES.keys()[2], CSData.ENEMIES.keys()[0]][i],
				G.p_pos + Vector2(140 + 70 * i, -40 + 40 * i))
	var center: Vector2 = G.p_pos + Vector2(160, 0)
	G._boom_at(center, 90.0, 40.0, false)
	G._fire_pool(center + Vector2(-180, 40), 14.0, 96.0, 3.4)
	await _settle(24)
