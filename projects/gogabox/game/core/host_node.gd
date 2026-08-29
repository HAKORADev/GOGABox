extends Node2D
## host_node - the live wrapper around one running game. Handles:
## the universal GOGABox loading screen, orientation switch in/out,
## entry-fee accounting, per-game play time + coin stats, run reporting
## (best/last/plays + coins), rewarded DOUBLE, interstitial pacing, and the
## game-over sheet. Built fully in code (arsenal style).

var game_def := {}
var router: Node
var fee := 0
var free_play := false
var game: GogaGame

var W := 720.0
var H := 1280.0

var _session_open := true
var _accum := 0.0        # play seconds accumulated since last flush

func configure(g: Dictionary, router_: Node, fee_: int, free_play_: bool) -> void:
	game_def = g
	router = router_
	fee = fee_
	free_play = free_play_

func _ready() -> void:
	var landscape := String(game_def.get("orientation", "portrait")) == "landscape"
	_apply_orientation(landscape)
	await get_tree().process_frame
	await get_tree().process_frame
	W = get_viewport_rect().size.x
	H = get_viewport_rect().size.y

	var bg := ColorRect.new()
	bg.color = Color("241407")
	bg.size = Vector2(W, H)
	add_child(bg)

	# ---- universal GOGABox loading screen (loads the script + assets) ----
	var id := String(game_def["id"])
	Ads.banner_hide()
	await Loader.load_game(self, game_def)

	if not _session_open:
		return
	game = (load(String(game_def["script"])) as GDScript).new()
	game.game_id = id
	game.request_finish.connect(_on_finish)
	game.request_quit.connect(_quit_to_menu)
	add_child(game)

func _process(delta: float) -> void:
	# play-time accounting for the global stats screen
	if game == null or not is_instance_valid(game) or game.over or game.paused:
		return
	_accum += delta
	if _accum >= 5.0:
		_flush_time()

func _flush_time() -> void:
	if _accum > 0.0:
		Box.add_time(String(game_def["id"]), _accum)
		_accum = 0.0

func _apply_orientation(landscape: bool) -> void:
	var root := get_window()
	if landscape:
		root.content_scale_size = Vector2i(1280, 720)
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	else:
		root.content_scale_size = Vector2i(720, 1280)
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_PORTRAIT)

func _restore() -> void:
	# box level: free rotation again; the menu re-lays itself out on resize
	_flush_time()
	var root := get_window()
	root.content_scale_size = Vector2i(720, 1280)
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR)

func _quit_to_menu() -> void:
	_session_open = false
	_flush_time()
	_restore()
	GameHost.end_session()
	if router != null and is_instance_valid(router) and router.has_method("on_game_closed"):
		router.call("on_game_closed")

func _exit_tree() -> void:
	if _session_open:
		_flush_time()

func _on_finish(final_score: int, earned: int) -> void:
	var id := String(game_def["id"])
	_flush_time()
	var res := Box.record_run(id, final_score)
	var total := earned
	# score -> coins conversion (score itself already may contain coin pickups)
	var bonus := _score_to_coins(final_score)
	total += bonus
	Box.earn(total)
	Box.add_earned(id, total)
	game.achievement_max("max_score", final_score)
	game.check_achievements()

	await get_tree().create_timer(0.55).timeout

	# ---- game over sheet ----
	var sheet := Arc.sheet(game._overlay_root_ref(), 0.0)
	sheet.get_parent().get_parent().process_mode = Node.PROCESS_MODE_ALWAYS

	var title := Arc.label("RUN OVER" if not res["new_best"] else "NEW BEST!",
			46, Arc.HOT if res["new_best"] else Arc.CARD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sheet.add_child(title)

	var stats := Arc.label("score %d   ·   best %d" % [final_score, int(res["best"])], 30, Arc.INK)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sheet.add_child(stats)

	var earn_row := Arc.chip("+%d GOGACoins" % total, "res://assets/ui/coin.png",
			Color(0, 0, 0, 0.08), 30, Color("8a5a14"))
	var cc := HBoxContainer.new()
	cc.alignment = BoxContainer.ALIGNMENT_CENTER
	cc.add_child(earn_row)
	sheet.add_child(cc)

	if not res["new_best"]:
		var hype := Arc.label("best %d" % int(res["best"]), 24, Color("8a6a40"))
		hype.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sheet.add_child(hype)

	if total > 0:
		sheet.add_child(Arc.button("DOUBLE  (watch ad)", Vector2(480, 84), 26, Arc.GOOD, func():
				Ads.show_rewarded(func(watched: bool):
						if watched:
								Box.earn(total)
								Box.add_earned(id, total)
								Arc.toast(game._toast_ref(), "+%d more GOGACoins!" % total)
								Jukebox.sfx("coin")))
				)

	sheet.add_child(Arc.button("PLAY AGAIN  (-%d)" % fee, Vector2(480, 84), 28, Arc.ACCENT, func():
			var can := free_play or fee == 0 or Box.coins() >= fee
			if can:
				if not free_play and fee > 0:
					Box.spend(fee)
					Box.add_spent(id, fee)
				Ads.register_run()
				_clear_game()
				game = (load(String(game_def["script"])) as GDScript).new()
				game.game_id = id
				game.request_finish.connect(_on_finish)
				game.request_quit.connect(_quit_to_menu)
				add_child(game)
			else:
				Arc.toast(game._toast_ref(), "Not enough GOGACoins")))

	sheet.add_child(Arc.button("BACK TO BOX", Vector2(480, 84), 28, Color(0.42, 0.30, 0.16), func():
			if Box.should_show_interstitial(3):
					Ads.maybe_interstitial(func(_shown: bool): _quit_to_menu())
			else:
					_quit_to_menu()))

	if res["new_best"]:
		Arc.confetti(sheet.get_parent().get_parent().get_parent(), Vector2(W / 2.0, H / 3.0))
		Jukebox.jingle_win()
	else:
		Jukebox.jingle_lose()

func _clear_game() -> void:
	if game != null and is_instance_valid(game):
		game.queue_free()
	game = null

func _score_to_coins(s: int) -> int:
	# per-game tuned generosity; always >= 1 coin for a real run
	match String(game_def["id"]):
		"snake": return 2 + s / 3
		"rally": return 1 + s / 4
		"lanes": return 2 + s / 100
		"slasher": return 2 + s / 20
		"hopper": return 2 + s / 60
		"merge": return 2 + s / 150
	return 1 + s / 100
