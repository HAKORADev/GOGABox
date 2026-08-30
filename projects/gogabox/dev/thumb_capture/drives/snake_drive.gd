extends Object
## snake auto-pilot for the thumbnail capture (attract mode).
## v2 - the POSTER edition:
##   1. centers the board (game spawns it left-aligned, device-agnostic)
##   2. ZOOMS the game node 1.35x so the board fills the 3:2 poster band
##      (still the real game at native resolution - this is a camera, not
##      a re-draw; the post stage then downscales to 960x640)
##   3. plays honest greedy snake: food first, nearby coin detours, avoids
##      walls/tail; auto-restarts after a death so long runs stay dense
##
## Tunables a capture operator may pass via the harness env of the drive:
##   ZOOM - how big the board reads in the poster (1.0 = no zoom)

var game: GogaGame   # actually game/games/snake/snake.gd
var ZOOM := 1.35

var _centered := false
var _dead_since := -1.0

func segments() -> Array:
        return []   # future: [{ "name": "speed_ramp", "at": 15.0 }]

func tick(t: float) -> void:
        if game == null or not is_instance_valid(game):
                return
        if not _centered:
                _center_board()
                _centered = true
        if not game.alive:
                if _dead_since < 0.0:
                        _dead_since = t
                elif t - _dead_since > 0.6:
                        _restart()
                        _dead_since = -1.0
                return
        var head: Vector2i = game.snake[0]
        var target: Vector2i = game.food
        if game.coin_pos.x >= 0 and head.distance_squared_to(game.coin_pos) \
                        < head.distance_squared_to(game.food) * 0.6:
                target = game.coin_pos   # grab a nearby coin on the way
        var d := target - head
        var prefs: Array = []
        if absi(d.x) >= absi(d.y):
                if d.x != 0:
                        prefs.append(Vector2i(signi(d.x), 0))
                if d.y != 0:
                        prefs.append(Vector2i(0, signi(d.y)))
        else:
                if d.y != 0:
                        prefs.append(Vector2i(0, signi(d.y)))
                if d.x != 0:
                        prefs.append(Vector2i(signi(d.x), 0))
        prefs.append(game.dir)
        for c in prefs:
                var cv: Vector2i = c
                if cv == -game.dir and game.snake.size() > 1:
                        continue
                var nxt: Vector2i = head + cv
                if game._in_bounds(nxt) and not game.snake.has(nxt):
                        game.next_dir = cv
                        return

## Center + zoom. After this the board spans ~95% of the frame width and
## the crop band slices the middle of the action.
func _center_board() -> void:
        var bw := float(game.COLS * game.CELL + 12)
        var bh := float(game.ROWS * game.CELL + 12)
        var vp := game.get_viewport_rect().size
        # native centering first
        var dx: float = (vp.x - bw) / 2.0 - game.ORIGIN.x
        game.ORIGIN.x += dx
        if game._board_panel != null:
                game._board_panel.position = game.ORIGIN
        for c in game._nodes:
                var n := game._nodes[c] as Sprite2D
                if n != null:
                        n.position = game._cell_center(c)
        game._food_node.position = game._cell_center(game.food)
        if game.coin_pos.x >= 0:
                game._coin_node.position = game._cell_center(game.coin_pos)
        # poster zoom: scale the whole live game, aim the board center at
        # the frame center (the crop band math in post.py aims at fy*H)
        game.scale = Vector2(ZOOM, ZOOM)
        var board_cx: float = game.ORIGIN.x + bw / 2.0
        var board_cy: float = game.ORIGIN.y + bh / 2.0
        game.position = Vector2(vp.x / 2.0 - board_cx * ZOOM,
                        vp.y / 2.0 - board_cy * ZOOM)

## Fresh honest run in place - the attract loop. NOTE: death routes through
## finish_run() which sets `over = true` (that stops _process -> _goga_tick);
## an attract restart MUST clear it again or the game freezes forever.
func _restart() -> void:
        game.over = false
        game.world.modulate = Color.WHITE
        # free the old segment sprites first - the game's own _new_snake()
        # only clears the dict (fine at boot, ghost-making on restart)
        for c in game._nodes:
                var n := game._nodes.get(c) as Sprite2D
                if n != null and is_instance_valid(n):
                        n.queue_free()
        game._new_snake()
        game._spawn_food()
        game.coin_pos = Vector2i(-1, -1)
        game._coin_node.position = Vector2(-100, -100)
        game._maybe_spawn_coin()
        game.step_time = 0.16
        game.tick = 0.0
        game.alive = true
        # re-center + re-zoom the new segment nodes (they spawned at ORIGIN,
        # which is already centered - just reapply the world color)
        for c in game._nodes:
                var n := game._nodes[c] as Sprite2D
                if n != null:
                        n.position = game._cell_center(c)
