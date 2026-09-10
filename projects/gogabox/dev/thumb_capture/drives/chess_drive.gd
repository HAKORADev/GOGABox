extends RefCounted
## checkmate auto-pilot for the thumbnail capture - v0.3.8-5 THE PARLOR
## ROOM edition. The drive drops the ready gate via the game's own probe
## reset (mid-flow round), keeps the tree alive, then plays HONEST legal
## moves for the user side (captures preferred - trades feed the new
## graveyard trays) while the CPU answers through the real tick.

var game            # actually game/games/chess/chess.gd

var _last := 0.0
var _mv_t := 1.2    # let the CPU's opening breathe first

func segments() -> Array:
	return []

func tick(t: float) -> void:
	if game == null or not is_instance_valid(game):
		return
	var dt: float = clampf(t - _last, 0.001, 0.05)
	_last = t
	# the parlor never sleeps: any sheet that paused the tree loses
	if game.get_tree().paused or game.paused:
		game.paused = false
		game.get_tree().paused = false
	if game.state == "ready":
		game.probe_reset(11)
		game.paused = false
		game.get_tree().paused = false
		return
	if game.state != "play":
		return
	_mv_t += dt
	if _mv_t < 0.9:
		return
	_mv_t = 0.0
	# the user's move: prefer a capture, else a random legal move
	var moves: Array = game.legal_moves(game.st)
	if moves.is_empty():
		return
	var pick: Dictionary = {}
	for m in moves:
		if int(game.st["b"][int(m["t"])]) != 0 or m["flag"] == "ep":
			pick = m
			break
	if pick.is_empty():
		pick = moves[randi() % moves.size()]
	game._player_move(pick)
