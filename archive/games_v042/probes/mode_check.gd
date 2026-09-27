extends SceneTree
## precise m07/m05 verification

var frames := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://game/games/marble/marble.gd").new()
	game.game_id = "marble"
	get_root().add_child(game)
	await process_frame
	await process_frame
	game._pick_level(6, false)   # m07: 1 path, twin shooters
	await process_frame
	await process_frame
	print("level=", game.level_idx + 1, " chains=", game.chains.size(),
			" hole0=", game.holes[0].position, " shooter=", game.shooter.position,
			" twinA=", game.twin_a, " mode=", "twin" if not game.twin_a.is_zero_approx() else "?")
	for i in 300:
		game._goga_tick(1.0 / 60.0)
	print("after 5s: marbles=", game.chains[0].marbles.size(), " rear_d=", game.chains[0].rear_d())
	game._pick_level(4, false)   # m05: slider
	await process_frame
	await process_frame
	print("level=", game.level_idx + 1, " chains=", game.chains.size(),
			" hole0=", game.holes[0].position, " shooter=", game.shooter.position,
			" slider=", game.slider)
	quit(0)
