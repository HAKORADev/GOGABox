extends Object
## Pong Rally auto-pilot for the thumbnail capture (attract mode).
## v2 - the POSTER court:
##   A vertical pong duel can never fit a 3:2 poster at native spawn
##   positions (paddles at y=70 and y=1810, band is 720 tall). So the drive
##   slides BOTH paddles into the middle band and the game plays REAL
##   rallies between them - real assets, real physics, real score, just a
##   shorter court. This is the owner-approved staged-but-real pattern
##   (his matcher example: render the real thing, compose it better).
##   The post stage aims the crop band at FOCUS (recommended 0.583).

var game: GogaGame   # actually game/games/rally/rally.gd
const ENEMY_Y := 820.0
const PLAYER_Y := 1330.0
const FOCUS := 0.583   # band top = FOCUS*(1920-720) = 700 -> covers 700..1420

var _staged := false
var _wobble := 0.0
var _dead_since := -1.0
var _ghost_since := -1.0

const SPEED_CAP := 560.0   # keep the ball inside the paddle windows at the
                           # harness renderer's ~20fps (60fps phones are fine)

func segments() -> Array:
        return []

func tick(t: float) -> void:
        if game == null or not is_instance_valid(game):
                return
        if not game.playing:
                # attract restart: a miss red-modulates the paddle and stops
                # the run (finish_run -> over). Reset like snake_drive does.
                if _dead_since < 0.0:
                        _dead_since = t
                elif t - _dead_since > 0.6:
                        game.over = false
                        game.playing = true
                        game.player.modulate = Color.WHITE
                        game._serve(Vector2(0.45 if randf() < 0.5 else -0.45, 1.0))
                        _dead_since = -1.0
                return
        if not _staged:
                _stage_court()
                _staged = true
        _wobble = t
        var vp := game.get_viewport_rect().size
        var target_x: float = game.ball.position.x + sin(_wobble * 1.7) * 22.0
        game.player.position.x = lerpf(game.player.position.x,
                        clampf(target_x, 70.0, vp.x - 70.0), 0.28)
        # speed cap: at llvmpipe's ~20fps a faster ball steps >66px and
        # tunnels straight through the paddle bounce windows
        if game.base_speed > SPEED_CAP:
                game.base_speed = SPEED_CAP
                game.ball_v = game.ball_v.normalized() * SPEED_CAP
        # ghost-ball rescue: if the ball still escapes the court (tunneling),
        # re-serve after 0.4s so the rally never dies into an empty frame
        if game.ball.position.y < game.enemy.position.y - 80.0 or \
                        game.ball.position.y > game.player.position.y + 100.0:
                if _ghost_since < 0.0:
                        _ghost_since = t
                elif t - _ghost_since > 0.4:
                        game._serve(Vector2(0.45 if randf() < 0.5 else -0.45, 1.0))
                        _ghost_since = -1.0
        else:
                _ghost_since = -1.0

func _stage_court() -> void:
        game.enemy.position.y = ENEMY_Y
        game.player.position.y = PLAYER_Y
        # park the ball between the paddles so the first seconds are alive
        var vp := game.get_viewport_rect().size
        game.ball.position = Vector2(vp.x / 2.0, (ENEMY_Y + PLAYER_Y) / 2.0)
        game.ball_v = Vector2(0.45, 1.0).normalized() * game.base_speed
