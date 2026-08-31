extends RefCounted
## snake auto-pilot for the thumbnail capture - v0.2.0 MIRROR WORLD edition.
## The drive walks the REAL flow (position ask -> mode menu -> tap to
## start), then steers like a player: it feeds synthetic drag events whose
## motion points at the fruit (the game's own mouse-steering does the
## bending, bounded by the turn rate). Aims at the board center when the
## look-ahead leaves the field. If it dies anyway, it quietly restarts the
## run so the capture keeps getting honest live frames.

var game            # actually game/games/snake/snake.gd (mirror era)

var _last := 0.0
var _anchor := Vector2.ZERO
var _idx := 7

func segments() -> Array:
	return []

func _drag(to: Vector2) -> void:
	var d := InputEventScreenDrag.new()
	d.index = _idx
	d.position = to
	d.relative = to - _anchor
	_anchor = to
	game._goga_input(d)

func tick(t: float) -> void:
	if game == null or not is_instance_valid(game):
		return
	var dt: float = clampf(t - _last, 0.001, 0.05)
	_last = t
	# walk the phase machine to a running game
	if game._phase == "orient":
		game._show_mode_select()   # skips ahead: keep the auto field
		return
	if game._phase == "mode":
		game._show_ready_card()
		return
	if game._phase == "ready":
		game._start()
		return
	if not game.player.alive or game.over:
		# restart the run for continued capture (the dead menu is host chrome)
		game.over = false
		game._reset_world()
		game._show_ready_card()
		game._start()
		return
	# look-ahead point; walls win over fruit
	var pl = game.player
	var look: Vector2 = pl.head_pos \
			+ Vector2.from_angle(pl.head_dir) * pl.width * 9.0
	var margin: float = pl.width * 2.0 + 26.0
	var want := 0.0
	var inside: bool = look.x > game.board.position.x + margin \
			and look.x < game.board.end.x - margin \
			and look.y > game.board.position.y + margin \
			and look.y < game.board.end.y - margin
	if inside and game.apple_live and game.apple_pop > 0.5:
		want = (game.apple_pos - pl.head_pos).angle()
	elif inside:
		want = pl.head_dir   # keep straight
	else:
		want = (game.board.get_center() - pl.head_pos).angle()
	# steer through MOTION: drag the finger toward the desired heading, the
	# game's mouse-steering turns the head (its bend cap is the boss)
	if _anchor == Vector2.ZERO:
		_anchor = game.board.get_center()
	var step := Vector2.from_angle(want) * 46.0
	_drag(_anchor + step)
	_drag(_anchor + step * 2.0)
