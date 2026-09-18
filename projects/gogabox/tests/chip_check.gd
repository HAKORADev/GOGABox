
extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var game = load("res://game/games/marble/marble.gd").new()
	game.game_id = "marble"
	get_root().add_child(game)
	await process_frame
	await process_frame
	var row = game._hud_row
	for i in row.get_child_count():
		var c = row.get_child(i)
		var txt := "?"
		for d in c.find_children("*", "Label", true, false):
			txt += " [" + (d as Label).text + "]"
		print(i, ": ", c.get_class(), txt)
	quit(0)
