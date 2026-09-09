extends RefCounted
## maze auto-pilot for the thumbnail capture - v0.3.7-1 THE REAL MAP SHOT.
## The owner (item 11): "the thumbnail looks bad and unreal, make it from
## in-game capture for high level map with programmed changes to make it
## cooler if you want". The drive levels the run up to a LATE map (the big
## grid - the scale law's most impressive weave), buys + taps the PATH
## FINDER so the cascade marks glow mid-route, then walks the square the
## BFS route through swipes so frames catch REAL play: the square mid-maze,
## the portal ahead, the coin when a coin map rolls.

var game            # game/games/maze/maze.gd

var _swipe_t := 0.0
var _route: Array = []
var _route_i := 0
var _armed := false

func segments() -> Array:
	return []

func _dir_to(step: Vector2i) -> Vector2i:
	return step

func tick(t: float) -> void:
	if game == null or not is_instance_valid(game):
		return
	# walk the gate: arm the big map + the finder, then start
	if game.phase == "ready":
		if not _armed:
			_armed = true
			# a late map: +1 col every 2 maps, +1 row every 3 - map 24
			# reads as a dense honest labyrinth on the board
			Box.dev_set_cheat("gogacoins", 0)
			Box.earn(9000)
			if not Box.item_owned(game.game_id, "finder", "finder"):
				Box.buy_item(game.game_id, "finder", "finder", 0)
			Box.equip_item(game.game_id, "finder", "on")
			game.finder_used = 0
			game.map_i = 24
			game._new_map()
			if game.ready_ui != null and is_instance_valid(game.ready_ui):
				game.ready_ui.queue_free()
				game.ready_ui = null
			game.phase = "run"
			# the finder glow: one charge ON for the cascade marks
			game.finder_used += 1
			game.finder_left = game.FINDER_DUR
			_route = []
			_route_i = 0
		return
	if game.phase != "run" or game.over_gate:
		return
	# the finder marks need the live redraw clock; the game handles it
	# walk the route: one queued swipe every 0.16s (the queue animates)
	_swipe_t += get_delta(t)
	if _swipe_t < 0.16:
		return
	_swipe_t = 0.0
	var here := Vector2i(game.player["c"], game.player["r"])
	if _route.is_empty() or _route_i >= _route.size():
		_route = game._bfs_path(game.cells, here, game.end_cell,
				game.cols, game.rows)
		if _route.size() > 0:
			_route.pop_front()   # the cell we stand on
		_route_i = 0
	if _route_i < _route.size():
		var nxt: Vector2i = _route[_route_i]
		var d := nxt - here
		if absi(d.x) + absi(d.y) == 1:
			game._swipe_dir(_dir_to(d))
			_route_i += 1
		else:
			_route = []   # a stale route - recompute

var _last := 0.0
func get_delta(t: float) -> float:
	var d: float = clampf(t - _last, 0.001, 0.05)
	_last = t
	return d
