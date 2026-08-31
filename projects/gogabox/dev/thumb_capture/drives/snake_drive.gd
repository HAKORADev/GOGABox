extends RefCounted
## snake auto-pilot for the thumbnail capture - v0.1.9 WAR edition. The
## drive walks the REAL flow (position ask -> mode menu -> tap to start),
## then steers by setting the invisible analog wheel's stick toward the
## fruit (bounded by the game's own turn rate), aiming at the board center
## when the look-ahead leaves the field. If it dies anyway, it quietly
## respawns so the capture keeps getting honest live frames.

var game            # actually game/games/snake/snake.gd (war era)

var _last := 0.0

func segments() -> Array:
        return []

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
                game._mode_picked()
                return
        if game._phase == "ready":
                game._start()
                return
        if not game.player.alive:
                # respawn for continued capture (death sheet is host chrome)
                game._new_run_objects()
                game.player.alive = true
                game._spawn_fruit(true)
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
        # steer THROUGH the wheel: the stick points at the desired heading
        game._wheel_stick = Vector2.from_angle(want) * 120.0
