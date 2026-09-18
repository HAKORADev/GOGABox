extends SceneTree
## focused join debug

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://game/games/marble/marble.gd").new()
	game.game_id = "marble"
	get_root().add_child(game)
	await process_frame
	await process_frame
	game._start_level(0, false, 1)
	for i in 30:
		game._goga_tick(1.0 / 60.0)
	game.phase = "play"
	var cp = game.chains[0]
	cp.marbles.clear()
	cp.spawned = cp.quota   # KILL the feed so it cannot interfere
	for d in [-200.0, -104.0, 200.0, 296.0]:
		cp.marbles.append({"c": 3, "d": d, "kind": "m", "life": -1.0, "pow": "", "spr": null, "glow": null, "bonded": d > 100.0})
	for t in 500:
		game._tick_chain(cp, 1.0 / 60.0)
		if t % 40 == 0:
			var ds := []
			for m in cp.marbles:
				ds.append(int(m["d"] * 10) / 10.0)
			print("t=", t, " size=", cp.marbles.size(), " ds=", ds,
					" gapopen0=", cp.marbles[0].get("gap_open") if cp.marbles.size() > 0 else "-",
					" score=", game.run_level_score)
		if cp.marbles.is_empty():
			print("ALL POPPED at t=", t, " score=", game.run_level_score)
			break
	quit(0)
