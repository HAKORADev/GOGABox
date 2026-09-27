extends Node
## qa_snake_ui - one-off visual QA for v0.2.0: screenshots the snake's
## screens (position ask, mode menu, PEACE mode menu, ready, running with
## the mouse-steer wiggle, the mirror-wall wrap stub, the NIGHT garden
## running, and the fixed-size shop). Frames land in --out.
##
##   godot --path . res://tests/qa_snake_ui.tscn ++ --out=/tmp/snakeqa_ui

var _out := "/tmp/snakeqa_ui"

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.split("=")[1]
	DirAccess.make_dir_recursive_absolute(_out)
	await _run()
	get_tree().quit(0)

func _shot(name_: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [_out, name_])
	print("[qa] shot ", name_)

func _drag(g: GogaGame, from: Vector2, to: Vector2, idx: int) -> void:
	var d := InputEventScreenDrag.new()
	d.index = idx
	d.position = to
	d.relative = to - from
	g._goga_input(d)

func _touch(g: GogaGame, at: Vector2, pressed: bool, idx: int) -> void:
	var t := InputEventScreenTouch.new()
	t.index = idx
	t.position = at
	t.pressed = pressed
	g._goga_input(t)

func _run() -> void:
	Box.reset_all()
	var game: GogaGame = load("res://game/games/snake/snake.gd").new()
	game.game_id = "snake"
	add_child(game)
	await get_tree().create_timer(0.6).timeout
	await _shot("1_position_ask")
	# same-position pick walks into the mode menu (the no-reload path)
	game._show_mode_select()
	await get_tree().create_timer(0.4).timeout
	await _shot("2_mode_optionals_day")
	# PEACE on: the style card lights up and the war boxes peace-lock
	game.peace = true
	Box.set_progress("snake", "style_peace", true)
	game._show_mode_select()
	await get_tree().create_timer(0.4).timeout
	await _shot("3_mode_peace_on")
	game.peace = false
	Box.set_progress("snake", "style_peace", false)
	# ready, then a real run with the mouse-style steering wiggle
	game._show_ready_card()
	await get_tree().create_timer(0.4).timeout
	await _shot("4_ready")
	game.wrap_mode = true
	game._start()
	for i in 200:
		var phase := float(i) * 0.05
		var anchor := Vector2(360.0, 700.0)
		var target := anchor + Vector2.from_angle(phase) * 90.0
		_drag(game, anchor, target, 2)
		_touch(game, target, false, 2)
		anchor = target
		await get_tree().process_frame
	await _shot("5_running_smooth")
	# the MIRROR wrap: drive the snake into the top wall and catch the stubs
	var p: SnakeBody = game.player
	p.head_pos = Vector2(game.board.get_center().x, game.board.position.y + 26.0)
	p.head_dir = -PI / 2.0
	p.speed = 420.0
	for i in 26:
		p.advance(1.0 / 30.0, game.board, true)
		game._goga_tick(1.0 / 30.0)
	await _shot("6_wrap_stub")
	# the NIGHT GARDEN (buy it, switch the place, let the flies gather)
	Box.earn(2000)
	Box.buy_item("snake", "place", "night", 0)
	game._cycle_place()
	for i in 60:
		var anchor := Vector2(300.0, 640.0)
		var target := anchor + Vector2(40.0, 0.0)
		_drag(game, anchor, target, 3)
		_touch(game, target, false, 3)
		await get_tree().process_frame
	await _shot("7_night_garden")
	# the shop: fixed size, always scrolling, every price with its coin
	game._shop_open()
	await get_tree().create_timer(0.5).timeout
	await _shot("8_shop")
	game._shop_close()
	_check_phase_back(game)
	await _shot("9_after_shop_close")
	Box.reset_all()

func _check_phase_back(g: GogaGame) -> void:
	print("[qa] phase after shop close: ", g._phase,
			" (night place: ", g.place, ")")
