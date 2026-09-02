extends Node
## qa_v031 (patch II) - the visual QA: the v0.3.1 games plus THE NEW
## CURSED DARIO (the intro story square, the real Pixel Adventure art,
## the continuous ground, the crate bump with the coin pop, the night
## forest, the ghost-platform arena and the Witcher).
##   DISPLAY=:99 godot --path . res://tests/qa_v031.tscn

const OUT := "/home/z/my-project/download/qa_v031/"

func _shot(path: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)
	print("[qa] ", path)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	Box.reset_all()
	Box.dev_set_cheat("all_owned", 1)

	# ================= XO (regression: the marks stay small) ========
	var x: GogaGame = load("res://game/games/xo/xo.gd").new()
	x.game_id = "xo"
	add_child(x)
	await get_tree().create_timer(0.5).timeout
	x.board = [1, 0, 2, 0, 1, 0, 0, 0, 2]
	x._place(0, x.X)
	x._place(2, x.O)
	await get_tree().create_timer(0.12).timeout
	x._place(4, x.X)
	x._place(8, x.O)
	await get_tree().create_timer(0.35).timeout
	await _shot(OUT + "01_xo_marks.png")
	x.queue_free()

	# ================= FRUIT SLASHER (regression) ===================
	var s: GogaGame = load("res://game/games/slasher/slasher.gd").new()
	s.game_id = "slasher"
	add_child(s)
	await get_tree().create_timer(0.5).timeout
	s._orient_choice("vertical")
	s._start_run()
	await get_tree().create_timer(1.2).timeout
	await _shot(OUT + "02_slasher_portrait.png")
	s.queue_free()

	# ================= CURSED DARIO =================================
	var d: GogaGame = load("res://game/games/dario/dario.gd").new()
	d.game_id = "dario"
	add_child(d)
	await get_tree().create_timer(0.8).timeout
	# the INTRO: the scrollable story square with the DONE button
	await _shot(OUT + "03_dario_intro_box.png")
	# dismiss it like a player would
	d._pair_down(d._intro_pair)
	d._intro_pair = []
	d._locked = false
	await get_tree().create_timer(0.5).timeout
	# the level with the start bubble over Dario's head
	d._bubble_say("DARIO: ...where am I? The sky is wrong.", 30.0)
	await _shot(OUT + "04_dario_level1_day.png")
	# the crate bump: park under the first crate and jump
	d._load_level(0)
	d._pair_down(d._intro_pair)
	d._intro_pair = []
	d._locked = false
	await get_tree().process_frame
	for i in 40:
		d._goga_tick(1.0 / 60.0)
		if d.on_floor:
			break
	# the crate at col 41: walk him there
	d.p_node.position = Vector2(41.5 * 80.0, 9.0 * 80.0)
	for i in 60:
		d._goga_tick(1.0 / 60.0)
		if d.on_floor:
			break
	d._jump_queued = true
	for i in 26:
		d._goga_tick(1.0 / 60.0)
	await _shot(OUT + "05_dario_crate_bump.png")
	# the NIGHT forest
	Box.equip_item("dario", "theme", "night")
	d._apply_theme()
	d._load_level(2)
	d._pair_down(d._intro_pair)
	d._intro_pair = []
	d._locked = false
	await get_tree().create_timer(0.6).timeout
	await _shot(OUT + "06_dario_night_forest.png")
	# the WITCHER ARENA: the ghost ladder + her, in day
	Box.unequip_item("dario", "theme")
	d._apply_theme()
	d.level_i = 9
	d._load_level(9)
	d._pair_down(d._intro_pair)
	d._intro_pair = []
	d._locked = false
	d._start_boss(Vector2i(16, 6))
	d.p_node.position = Vector2(10.5 * 80.0, 10.4 * 80.0)
	await get_tree().create_timer(0.9).timeout
	d._cam_follow()
	d._bg_tick()
	await _shot(OUT + "07_dario_arena_ghosts.png")
	# and at night
	Box.equip_item("dario", "theme", "night")
	d._apply_theme()
	await get_tree().create_timer(0.4).timeout
	await _shot(OUT + "08_dario_witcher_night.png")
	print("[qa] done")
	get_tree().quit(0)

func _ready() -> void:
	_run.call_deferred()
