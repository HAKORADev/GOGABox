extends RefCounted
## domino auto-pilot for the thumbnail capture - v0.3.8-5 THE WOW TABLE
## edition. The drive walks the REAL flow (tap to deal -> honest tiles),
## then plays like a player: tap a playable tile in the fan, tap its end
## slot, let the CPU answer. Stuck hands take from the two-row yard fan
## (or emit the real PASS button when the yard is dry). DBG_SPREAD=1 in
## the environment holds the yard fan open at t=4s for 1.8s so the
## verification pass can read the spread layout.

var game            # actually game/games/domino/domino.gd

var _last := 0.0
var _act_t := 0.0
var _idx := 7
var _spread_shown := false

func segments() -> Array:
        return []

func _touch(at: Vector2, pressed: bool) -> void:
        var e := InputEventScreenTouch.new()
        e.index = _idx
        e.position = at
        e.pressed = pressed
        game._goga_input(e)

func _tap(at: Vector2) -> void:
        _touch(at, true)
        _touch(at, false)

func tick(t: float) -> void:
        if game == null or not is_instance_valid(game):
                return
        var dt: float = clampf(t - _last, 0.001, 0.05)
        _last = t
        # the verification pass: hold the two-row yard fan open for a beat
        if OS.get_environment("DBG_SPREAD") != "" and not _spread_shown \
                        and t >= 4.0 and game.state == "play":
                _spread_shown = true
                game.spread = true
                game._relayout()
        if _spread_shown and t >= 5.8 and game.spread:
                game.spread = false
                game._relayout()
        if game.state == "ready":
                _act_t += dt
                if _act_t > 0.35:
                        _act_t = 0.0
                        _tap(game.board_rect.get_center())
                return
        if game.state != "play" or game.turn != game.P:
                return
        _act_t += dt
        if _act_t < 0.5:
                return
        _act_t = 0.0
        # the yard fan is up: take a tile from it (the honest manual draw)
        if game.spread:
                if game.spread_rects.size() > 0:
                        var mid: int = game.spread_rects.size() / 2
                        _tap((game.spread_rects[mid] as Rect2).get_center())
                return
        # THE OPENING: the glowing opener tile places on its own tap
        if game.opening:
                for i in game.hand_p.size():
                        if game._is_opener(i):
                                _tap((game.hand_rects[i] as Rect2).get_center())
                                return
                return
        # a playable tile? tap it, tap its end
        var e: Vector2i = game.ends(game.chain)
        var idx := -1
        # keep the hand flexible: play the tile whose pips the hand still
        # carries the most (the dumb first-fit strands the fan in two draws)
        var best := -1
        for i in game.hand_p.size():
                var cp2: int = game.can_play(game.hand_p[i], e.x, e.y)
                if cp2 == 0:
                        continue
                var a: int = int(game.hand_p[i][0])
                var b: int = int(game.hand_p[i][1])
                var keep := 0
                for j in game.hand_p.size():
                        if j == i:
                                continue
                        var ja: int = int(game.hand_p[j][0])
                        var jb: int = int(game.hand_p[j][1])
                        if cp2 & 1:
                                if ja == a or jb == a:
                                        keep += 1
                        if cp2 & 2:
                                if ja == b or jb == b:
                                        keep += 1
                if keep > best:
                        best = keep
                        idx = i
        if idx < 0:
                # stuck: the real PASS/draw door - emit the button's own handler
                if game.draw_btn != null and is_instance_valid(game.draw_btn):
                        game.draw_btn.pressed.emit()
                return
        var from: Vector2 = (game.hand_rects[idx] as Rect2).get_center()
        var held: Array = game.hand_p[idx]
        _tap(from)
        # v0.3.8-5: the tap may have AUTO-PLACED the tile (the opener law,
        # the single-fitting-end law) - the hand shrank under the drive's
        # feet; never re-read the stale slot
        if idx >= game.hand_p.size() or game.hand_p[idx] != held:
                return
        var cp: int = game.can_play(game.hand_p[idx], e.x, e.y)
        var to := Vector2.ZERO
        if cp == 1:
                to = game.end_l.get_center()
        elif cp == 2:
                to = game.end_r.get_center()
        else:
                to = game.end_r.get_center()
        _tap(to)
