extends RefCounted
## snake auto-pilot for the thumbnail capture - v0.1.8 SMOOTH edition.
## The grid is gone: the drive taps to start, then steers the heading
## toward the apple (bounded by the game's own turn rate) and steers away
## from walls by aiming at the board center when the look-ahead leaves the
## field. If it dies anyway, it quietly respawns so the capture keeps
## getting honest live frames.

var game            # actually game/games/snake/snake.gd (smooth era)

var _last := 0.0

func segments() -> Array:
        return []

func tick(t: float) -> void:
        if game == null or not is_instance_valid(game):
                return
        var dt: float = clampf(t - _last, 0.001, 0.05)
        _last = t
        if not game._started:
                game._start()
                return
        if not game.alive:
                # respawn for continued capture (death sheet is host chrome)
                game._new_snake()
                game.alive = true
                game._spawn_apple(true)
                return
        if game.over:
                return
        # look-ahead point; walls win over apples
        var look: Vector2 = game.head_pos \
                        + Vector2.from_angle(game.head_dir) * game.width * 9.0
        var margin: float = game.width * 2.0 + 26.0
        var want := 0.0
        var inside: bool = look.x > game.board.position.x + margin \
                and look.x < game.board.end.x - margin \
                and look.y > game.board.position.y + margin \
                and look.y < game.board.end.y - margin
        if inside and game.apple_pop > 0.5:
                want = (game.apple_pos - game.head_pos).angle()
        elif inside:
                want = game.head_dir   # keep straight
        else:
                want = (game.board.get_center() - game.head_pos).angle()
        var d: float = wrapf(want - game.head_dir, -PI, PI)
        game.head_dir += clampf(d, -game.TURN_RATE * dt, game.TURN_RATE * dt)
