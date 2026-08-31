class_name SnakeAI
extends RefCounted
## Snake v0.2.0 - the enemy brain, REBUILT FOR SURVIVAL (the owner: the old
## one "does not even stand for 10 seconds"). The core is a ROLLOUT: a fan
## of candidate headings is walked a few steps into a simulated future and
## scored by clearance - walls (mirror-portal aware), obstacles and every
## body on the field. Only the survivors get to want food; the best survivor
## closest to the desire wins. Food desire is still the owner's table:
## coins weigh more than apples, score powers flip it, being big enables the
## NOOSE around the player, and every power in play rewrites the table.
## The brain only STEERS; the game owns eating, dying and power effects.

const TURN_RATE := 4.3          # rad/s - a whisk slower than the player
const ORBIT_RATE := 1.35        # rad/s around the player while encircling
const ORBIT_R0 := 250.0         # start radius of the noose
const ORBIT_R1 := 150.0         # tightened noose
const ROLLOT_STEPS := 4         # simulated steps per candidate
const ROLLOT_T := 0.14          # seconds per simulated step
const CAND_SPREAD := PI * 0.83  # fan half-width around the desired heading
const CAND_COUNT := 13          # candidates across the fan

var body: SnakeBody
var idx := 0                    # enemy index (color/name)
var _orbit_a := 0.0
var _orbit_r := ORBIT_R0
var _orbit_t := 0.0
var _panic := 0.0               # hard-avoid grace after an all-die rollout
var _wobble_ph := 0.0           # per-enemy lane wobble (snakes are not rails)

func _init(b: SnakeBody, i: int) -> void:
        body = b
        idx = i
        _wobble_ph = randf() * TAU


## The world interface the game exposes (snake.gd):
## board, wrap_mode, apple_pos, apple_live, edible_id, coin_pos, coin_live,
## power_pos, power_live, power_id, obstacles: Array[Rect2], bugs: Array,
## player_body() -> SnakeBody, enemies: Array (other brains' bodies).
func think(delta: float, g: Node) -> void:
        if body == null or not body.alive:
                return
        var player: SnakeBody = g.player_body()
        var beh := _behavior(player)
        var target := _choose_target(g, player, beh)
        var desired: float = target["angle"]
        if beh["encircle"] and not target["forced"] and _panic <= 0.0:
                desired = _encircle_angle(g, player, delta, beh)
        var chosen := _survivor_angle(g, desired)
        var d := wrapf(chosen - body.head_dir, -PI, PI)
        var max_step := TURN_RATE * delta * (1.35 if _panic > 0.0 else 1.0)
        _panic = maxf(0.0, _panic - delta)
        if absf(d) <= max_step:
                body.head_dir = chosen
        else:
                body.head_dir += signf(d) * max_step


## per-power brain rewrites - THE design table (v0.2.0 adds sprint/slog):
##   player GHOST  -> a noose cannot hold a phase-snake: encircle OFF.
##   player EATER  -> fear: keep the player's head at arm's length.
##   player WITHER -> the player is shrinking: noose threshold drops.
##   player SLOG   -> the player is slow: noose threshold drops too.
##   player SPRINT -> give the speed demon room: noose threshold rises.
##   player MAGNET -> coins are about to fly: contest them harder.
##   self FASTER   -> hunt: aim ahead of the player's head (cut him off).
##   self SLOWER   -> farm: prefer food the player is FAR from.
##   self SPRINT   -> hunt lighter - speed is for food, not brawls.
##   self SLOG     -> pure farm, never chase.
##   self GOLDEN   -> apples pay triple: farm them hard.
##   self EATER    -> the player's tail is food.
func _behavior(player: SnakeBody) -> Dictionary:
        var beh := {
                "encircle_threshold": 2.0,
                "fear": false,
                "hunt": false,
                "farm": false,
                "coin_weight": 1.0,
                "apple_weight": 0.5,
                "encircle": false,
        }
        if player == null or not player.alive:
                beh["encircle_threshold"] = 999.0
                return beh
        if player.has_power("ghost"):
                beh["encircle_threshold"] = 999.0
        if player.has_power("eater"):
                beh["fear"] = true
        if player.has_power("wither"):
                beh["encircle_threshold"] = 1.3
        if player.has_power("slog"):
                beh["encircle_threshold"] = 1.45
        if player.has_power("sprint"):
                beh["encircle_threshold"] = 2.6
        if player.has_power("magnet"):
                beh["coin_weight"] = 1.45
        if body.has_power("golden"):
                beh["apple_weight"] = 1.5    # score power-up: apples pay
        if body.has_power("faster"):
                beh["hunt"] = true
        if body.has_power("slower"):
                beh["farm"] = true
        if body.has_power("sprint"):
                beh["hunt"] = true
                beh["hunt_soft"] = true
        if body.has_power("slog"):
                beh["farm"] = true
                beh["hunt"] = false
        var my_len: float = body.length_px + 60.0 * float(body.effects.get("eater", 0.0))
        beh["encircle"] = my_len >= beh["encircle_threshold"] * player.length_px
        return beh


## Value-over-distance target choice (portal-shortest). Returns
## {angle, forced} - forced skips the encircle layer.
func _choose_target(g: Node, player: SnakeBody, beh: Dictionary) -> Dictionary:
        var best := -1.0
        var best_pos := body.head_pos + Vector2.from_angle(body.head_dir) * 100.0
        var forced := false
        var cands: Array = []
        if g.apple_live:
                cands.append({"p": g.apple_pos, "v": beh["apple_weight"]})
        if g.coin_live:
                cands.append({"p": g.coin_pos, "v": beh["coin_weight"]})
        if g.power_live:
                var pid := String(g.power_id)
                var pv := 0.9
                if pid == "wither" or pid == "slog":
                        pv = 0.03       # the AI is NOT drinking a curse
                elif pid == "sprint" or pid == "eater":
                        pv = 1.3
                cands.append({"p": g.power_pos, "v": pv})
        for c in cands:
                var p: Vector2 = c["p"]
                var v: float = c["v"]
                var d := _portal_dist(body.head_pos, p, g)
                # farm mode: food the player is far from is worth more
                if beh["farm"] and player != null:
                        var dp := _portal_dist(player.head_pos, p, g)
                        v *= clampf(dp / maxf(d, 60.0), 0.4, 2.2)
                var score := v / (60.0 + d)
                if score > best:
                        best = score
                        best_pos = p
        # SNAKE-EATER on the AI: the player's tail is literally food
        if body.has_power("eater") and player != null and player.alive:
                var tail := _tail_point(player)
                var d2 := _portal_dist(body.head_pos, tail, g)
                var s2 := 1.5 / (60.0 + d2)
                if s2 > best:
                        best = s2
                        best_pos = tail
                        forced = true
        # FEAR: the player wears the eater - run from his head
        if beh["fear"] and player != null and player.alive:
                var away := body.head_pos - player.head_pos
                if away.length() < 300.0:
                        best_pos = body.head_pos + away.normalized() * 260.0 \
                                        + Vector2.from_angle(_orbit_a) * 60.0
                        forced = true
        # HUNT (self faster/sprint): cut the player off, aim ahead of his head.
        # sprint hunts SOFT: only when the cut is cheap (close by).
        if beh["hunt"] and player != null and player.alive \
                        and not beh["encircle"] and (not beh.get("hunt_soft", false)
                                        or body.head_pos.distance_to(player.head_pos) < 420.0) \
                        and randf() < 0.9:
                var ahead: Vector2 = player.head_pos \
                                + Vector2.from_angle(player.head_dir) * 180.0
                best_pos = ahead
                forced = true
        return {"angle": _angle_to(best_pos, g), "forced": forced}


## The noose: orbit the player's head and tighten. Food inside the noose is
## still food - the chooser already grabbed it (its value wins by distance).
func _encircle_angle(g: Node, player: SnakeBody, delta: float,
                beh: Dictionary) -> float:
        _orbit_t += delta
        _orbit_a = wrapf(_orbit_a + ORBIT_RATE * delta, -PI, PI)
        var t := clampf(_orbit_t / 14.0, 0.0, 1.0)
        _orbit_r = lerpf(ORBIT_R0, ORBIT_R1, t)
        if beh.get("hunt_soft", false):
                _orbit_r = lerpf(ORBIT_R0, ORBIT_R1 + 30.0, clampf(_orbit_t / 10.0, 0.0, 1.0))
        var anchor: Vector2 = player.head_pos
        var pt := anchor + Vector2.from_angle(_orbit_a) * _orbit_r
        return _angle_to(pt, g)


func _tail_point(s: SnakeBody) -> Vector2:
        var pts := s.body_points()
        return pts[maxi(0, pts.size() - 2)][0]


## Shortest delta a -> b: direct OR through a mirror portal (whichever is
## genuinely shorter in the mirrored world).
func _portal_delta(a: Vector2, b: Vector2, g: Node) -> Vector2:
        var best: Vector2 = b - a
        var best_len := best.length()
        if g.wrap_mode:
                var board: Rect2 = g.board
                for img in body.portal_images(b, board):
                        var d: Vector2 = img - a
                        if d.length() < best_len:
                                best = d
                                best_len = d.length()
        return best


func _portal_dist(a: Vector2, b: Vector2, g: Node) -> float:
        return _portal_delta(a, b, g).length()


func _angle_to(p: Vector2, g: Node) -> float:
        return _portal_delta(body.head_pos, p, g).angle()


## THE SURVIVOR PICK: a fan of candidate headings around `desired`, each
## walked ROLLOT_STEPS into a simulated future (turn-limited arcs, mirror
## portals fold the probes). A candidate DIES if any step lands on a wall
## (classic), an obstacle, or any body (its own neck excepted). Among the
## survivors the one closest to `desired` wins; lane wobble keeps snakes
## from stacking into a rail. All die -> the one that dies LAST + panic.
func _survivor_angle(g: Node, desired: float) -> float:
        var step_px: float = body.speed * body.speed_mult() * ROLLOT_T
        var hr := body.width * 0.5
        # prebuilt body sample arrays (cached per frame by each SnakeBody)
        var others: Array = []
        for s in g.all_bodies():
                if s == null or not s.alive or s == body:
                        continue
                others.append(s.body_points())
        var own := body.body_points()
        var skip := body.width * 2.4
        var best_survivor := desired
        var best_survivor_cost := -99999.0
        var best_dead := desired
        var best_dead_steps := -1
        for k in CAND_COUNT:
                var off: float = -CAND_SPREAD + (2.0 * CAND_SPREAD) * float(k) \
                                / float(CAND_COUNT - 1)
                var ang := wrapf(desired + off, -PI, PI)
                var dir := Vector2.from_angle(ang)
                var p := body.head_pos
                var dead_at := -1
                var min_clear := 9999.0
                for st in ROLLOT_STEPS:
                        p = p + dir * step_px
                        if g.wrap_mode:
                                # portals are FREE real estate: fold the probe, no edge cost
                                p = (body.wrap_point(p, g.board))["pos"]
                        else:
                                min_clear = minf(min_clear, _edge_clear(p, g.board) * 0.5)
                                if _outside(p, hr * 0.7, g.board):
                                        dead_at = st
                                        break
                        for o: Rect2 in g.obstacles:
                                if o.grow(hr * 0.5).has_point(p):
                                        dead_at = st
                                        break
                        if dead_at >= 0:
                                break
                        var clear := 9999.0
                        for pinfo in own:
                                if float(pinfo[1]) < skip:
                                        continue
                                clear = minf(clear, p.distance_to(pinfo[0]) - hr)
                        for opts in others:
                                for pinfo in opts:
                                        clear = minf(clear, p.distance_to(pinfo[0]) - hr)
                                if clear < 0.0:
                                        break
                        if clear < (hr + 6.0) * 0.62:
                                dead_at = st
                                break
                        min_clear = minf(min_clear, clear)
                var want := absf(off)
                var wobble := 0.035 * sin(_wobble_ph + float(k))
                if dead_at < 0:
                        var cost := -want + wobble + minf(min_clear, 260.0) * 0.004
                        if cost > best_survivor_cost:
                                best_survivor_cost = cost
                                best_survivor = ang
                elif dead_at > best_dead_steps:
                        best_dead_steps = dead_at
                        best_dead = ang
        if best_survivor_cost < -90000.0:
                # everything ahead dies - take the longest-lived death and PANIC
                _panic = 0.55
                return best_dead
        return best_survivor


## Distance from p to the nearest wall of the board (classic mode only -
## in no-walls every edge is a portal and portals cost nothing).
func _edge_clear(p: Vector2, board: Rect2) -> float:
        return minf(minf(p.x - board.position.x, board.end.x - p.x),
                        minf(p.y - board.position.y, board.end.y - p.y))


func _outside(p: Vector2, pad: float, board: Rect2) -> bool:
        return p.x - pad < board.position.x or p.x + pad > board.end.x \
                        or p.y - pad < board.position.y or p.y + pad > board.end.y
