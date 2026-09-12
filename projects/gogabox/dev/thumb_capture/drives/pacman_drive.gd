extends RefCounted
## pacman auto-pilot for the thumbnail capture - v0.3.9-6 THE REAL MAZE SHOT.
## The owner (the v0.3.9-6 report): "the game thumbnail is bad, do in-game
## capturing with some programmed modifications to make it cool".
## The drive jumps the run to the DENSE maze of the size ladder (35x17 - the
## weave at its most impressive), walks Balldozer through REAL swipes toward
## the nearest golden dot, and arms the BLUE RUSH so the frames wear the
## glow: blue frightened ball-eaters, the golden dots, the neon corridors.

var game            # game/games/pacman/pacman.gd

var _swipe_t := 0.0
var _armed := false
var _rushed := false

func segments() -> Array:
        return []

func tick(t: float) -> void:
        if game == null or not is_instance_valid(game):
                return
        # THE STORY SHEET: the fresh boot wears the first-start lore (the
        # save is reset) - walk the story off exactly like its button does
        if game.phase == "boot" and not game._story_pair.is_empty():
                game._story_end(Callable())
                return
        if game.phase == "boot":
                # the gate is up: arm the dense maze + start the run
                if not _armed:
                        _armed = true
                        if game.gate_ui != null and is_instance_valid(
                                        game.gate_ui):
                                game.gate_ui.queue_free()
                                game.gate_ui = null
                        game.maze_i = 12      # the ladder's 35x17 weave
                        game._new_maze()
                        game.phase = "run"
                return
        if game.phase != "run":
                return
        # THE RUSH (the programmed cool): the blue glow mid-chase, once
        if not _rushed:
                _rushed = true
                game.rush_left = game.RUSH_TIME
                game.eaten_this_rush = 0
                game.rush_chip.visible = true
                game.rush_lbl.text = "%.1f" % game.rush_left
                for e in game.eaters:
                        if e["state"] == "roam" or e["state"] == "pen":
                                e["state"] = "fright"
        # walk the chomp: one swipe every 0.14s toward the nearest dot
        _swipe_t += _step(t)
        if _swipe_t < 0.14:
                return
        _swipe_t = 0.0
        var here: Vector2i = game.player["cell"]
        var best := Vector2i(-1, -1)
        var bd := 1 << 30
        for key in game.dots.keys():
                var dd: int = absi(key.x - here.x) + absi(key.y - here.y)
                if dd < bd:
                        bd = dd
                        best = key
        if best.x < 0:
                return
        var pick := Vector2i(9, 9)
        var pd: int = 1 << 30
        for nd in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1),
                        Vector2i(1, 0)]:
                if not game._dir_open_at(here, nd):
                        continue
                var nxt: Vector2i = here + game._wrap_to(here, nd)
                var dd: int = absi(nxt.x - best.x) + absi(nxt.y - best.y)
                if dd < pd:
                        pd = dd
                        pick = nd
        if pick != Vector2i(9, 9):
                game._swipe_dir(pick, Vector2.ZERO)

var _last := 0.0
func _step(t: float) -> float:
        var d: float = clampf(t - _last, 0.001, 0.05)
        _last = t
        return d
