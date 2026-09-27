extends Node
func _ready() -> void:
	var game: GogaGame = load("res://game/games/snake/snake.gd").new()
	game.game_id = "snake"
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.peace = true
	game.score_bonus_enabled = false
	game._show_mode_select()
	game._show_ready_card()
	game._start()
	var p: SnakeBody = game.player
	p.len_target = 700.0
	p.length_px = 700.0
	for i in 190:
		p.head_dir += 0.085
		game._goga_tick(1.0 / 60.0)
		if i % 20 == 0:
			print("i=%d alive=%s len=%.1f target=%.1f peace=%s effects=%s collapse=%f" % [
				i, p.alive, p.length_px, p.len_target, game.peace, p.effects, game._collapse_t])
	get_tree().quit(0)
