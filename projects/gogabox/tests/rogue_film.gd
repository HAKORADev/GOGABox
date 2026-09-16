extends Node
## ROGUE ARSENAL film probe (v040-4) - the simulated session: real finger
## events, real state, SCREENSHOTS at every beat (THE VISION LAW).
## Run: xvfb-run godot --path . --rendering-driver opengl3 \
##        res://tests/rogue_film.tscn

var G: GogaGame = null
var shot_dir := "/home/z/my-project/gogabox/films/v040-4"

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

func _drag(idx: int, pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = idx
	e.position = pos
	G._goga_input(e)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(shot_dir)
	Box.reset_all()
	Box.earn(3000)
	get_window().size = Vector2i(1920, 1080)
	ScaleRule.apply(get_window())
	await _wait(0.3)
	G = load("res://game/games/heavywar/heavywar.gd").new()
	G.game_id = "heavywar"
	add_child(G)
	await _wait(1.2)
	await _shot("01_intro")

	# the deploy tap
	_tap(9, Vector2(960, 540), true)
	_tap(9, Vector2(960, 540), false)
	await _wait(1.4)
	await _shot("02_place_start")

	# TWO FINGERS: left = analog roll, right = aim + fire
	_tap(1, Vector2(360, 980), true)
	_tap(2, Vector2(1300, 420), true)
	await _wait(0.6)
	await _shot("03_two_fingers")

	# chase enemies with the aim for a few beats
	for i in 10:
		if not G.enemies.is_empty():
			var e0: Dictionary = G.enemies[0]
			_drag(2, Vector2(float(e0["x"]), float(e0["y"])))
		_drag(1, Vector2(360.0 + sin(i * 1.1) * 180.0, 980.0))
		await _wait(0.5)
	await _shot("04_combat")
	await _shot("04b_combat2")

	# mini tanks bolted on: buy + show them
	Box.buy_item(G.game_id, "mini", "mt_ice",
		int(HWData.MINIS["mt_ice"]["price"]))
	Box.buy_item(G.game_id, "mini", "mt_magnet",
		int(HWData.MINIS["mt_magnet"]["price"]))
	G._bolt_mini("mt_ice")
	await _wait(0.5)
	await _shot("05_minis")

	# force the boss: the warning + the bar + the fight
	G.wave = HWData.WAVES_PER_PLACE
	for e in G.enemies.duplicate():
		G.kill_enemy(e, false)
	G.wave_state = "clearing"
	var tries := 0
	while G.state != G.GS.BOSS and tries < 40:
		await _wait(0.1)
		tries += 1
	await _wait(1.2)
	await _shot("06_boss_arrives")
	for i in 8:
		if not G.boss_ent.is_empty():
			_drag(2, Vector2(float(G.boss_ent["x"]), float(G.boss_ent["y"])))
		await _wait(0.5)
	await _shot("07_boss_fight")

	# level-up cards
	G._gain_xp(G.p_xp_next + 5)
	await _wait(0.6)
	await _shot("08_level_cards")
	if G.paused and G.card_choices.size() > 0:
		G._pick_card(G.card_choices[0])
	await _wait(0.4)

	# the shop sheet
	G._shop_open()
	await _wait(0.5)
	await _shot("09_shop")
	G._shop_close()
	await _wait(0.3)

	# kill the boss -> the tunnel -> the next place
	if not G.boss_ent.is_empty():
		G._damage_enemy(G.boss_ent, 999999.0)
	await _wait(1.6)
	await _shot("10_tunnel")
	await _wait(1.6)
	await _shot("10b_tunnel_mid")
	var tries2 := 0
	while G.state != G.GS.PLACE and tries2 < 90:
		await _wait(0.1)
		tries2 += 1
	await _wait(0.8)
	await _shot("11_next_place")

	# the end: hull to 0
	G.p_hp = 1.0
	G._damage_player(50.0)
	await _wait(0.9)
	await _shot("12_game_over")

	print("[FILM] done")
	get_tree().quit(0)

func _ready() -> void:
	_run.call_deferred()
