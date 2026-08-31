class_name SnakeAI
extends RefCounted
## Snake v0.1.9 - the enemy brain. The owner's spec, decoded:
##   * it eats apples AND coins, coins weigh more (two apples = one coin,
##     each coin = one) but score power-ups make apples profitable again;
##   * when it gets BIG it tries to WRAP ITSELF AROUND the player's snake;
##   * its death is permanent for the round - the run only ends when the
##     USER dies;
##   * every power in play REWRITES part of this brain (the owner: "make a
##     proper design that modifies the AI system for each different
##     power-up") - see _behavior() below.
##
## The brain only STEERS; the game owns eating, dying and power effects.

const TURN_RATE := 4.3          # rad/s - a whisk slower than the player
const ORBIT_RATE := 1.35        # rad/s around the player while encircling
const ORBIT_R0 := 250.0         # start radius of the noose
const ORBIT_R1 := 135.0         # tightened noose

var body: SnakeBody
var idx := 0                    # enemy index (color/name)
var _orbit_a := 0.0
var _orbit_r := ORBIT_R0
var _orbit_t := 0.0
var _panic := 0.0               # hard-avoid grace after a near miss

func _init(b: SnakeBody, i: int) -> void:
        body = b
        idx = i


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
        if beh["encircle"] and not target["forced"]:
                desired = _encircle_angle(g, player, delta, beh)
        # survival probes override everything
        var chosen := _safest_angle(g, desired)
        var d := wrapf(chosen - body.head_dir, -PI, PI)
        var max_step := TURN_RATE * delta * (1.35 if _panic > 0.0 else 1.0)
        _panic = maxf(0.0, _panic - delta)
        if absf(d) <= max_step:
                body.head_dir = chosen
        else:
                body.head_dir += signf(d) * max_step


## per-power brain rewrites - THE design table:
##   player GHOST  -> a noose cannot hold a phase-snake: encircle OFF.
##   player EATER  -> fear: keep the player's head at arm's length.
##   player WITHER -> the player is shrinking: noose threshold drops.
##   self FASTER   -> hunt: aim ahead of the player's head (cut him off).
##   self SLOWER   -> farm: prefer food the player is FAR from.
##   player MAGNET -> coins are about to fly: contest them harder.
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
        if player.has_power("magnet"):
                beh["coin_weight"] = 1.45
        if body.has_power("golden"):
                beh["apple_weight"] = 1.5    # score power-up: apples pay
        if body.has_power("faster"):
                beh["hunt"] = true
        if body.has_power("slower"):
                beh["farm"] = true
        var my_len: float = body.length_px + 60.0 * float(body.effects.get("eater", 0.0))
        beh["encircle"] = my_len >= beh["encircle_threshold"] * player.length_px
        return beh


## Value-over-distance target choice. Returns {angle, forced} - forced skips
## the encircle layer (hunting/fear/biting aim directly).
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
                var pv := 0.9
                if String(g.power_id) == "wither":
                        pv = 0.04        # the AI is NOT drinking that
                elif String(g.power_id) == "eater":
                        pv = 1.3
                cands.append({"p": g.power_pos, "v": pv})
        for c in cands:
                var p: Vector2 = c["p"]
                var v: float = c["v"]
                var d := _wrap_dist(body.head_pos, p, g)
                # farm mode: food the player is far from is worth more
                if beh["farm"] and player != null:
                        var dp := _wrap_dist(player.head_pos, p, g)
                        v *= clampf(dp / maxf(d, 60.0), 0.4, 2.2)
                var score := v / (60.0 + d)
                if score > best:
                        best = score
                        best_pos = p
        # SNAKE-EATER on the AI: the player's tail is literally food
        if body.has_power("eater") and player != null and player.alive:
                var tail := _tail_point(player)
                var d2 := _wrap_dist(body.head_pos, tail, g)
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
        # HUNT (self faster): cut the player off, aim ahead of his head
        if beh["hunt"] and player != null and player.alive \
                        and not beh["encircle"] and randf() < 0.9:
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
        var anchor: Vector2 = player.head_pos
        # hunt mode tightens faster (it is literally faster than him)
        if beh["hunt"]:
                _orbit_r = lerpf(ORBIT_R0, ORBIT_R1, clampf(_orbit_t / 8.0, 0.0, 1.0))
        var pt := anchor + Vector2.from_angle(_orbit_a) * _orbit_r
        return _angle_to(pt, g)


func _tail_point(s: SnakeBody) -> Vector2:
        var pts := s.body_points()
        return pts[maxi(0, pts.size() - 2)][0]


func _angle_to(p: Vector2, g: Node) -> float:
        var d := p - body.head_pos
        if g != null and g.wrap_mode:
                var b: Rect2 = g.board
                if absf(d.x) > b.size.x * 0.5:
                        d.x -= signf(d.x) * b.size.x
                if absf(d.y) > b.size.y * 0.5:
                        d.y -= signf(d.y) * b.size.y
        return d.angle()


func _wrap_dist(a: Vector2, b: Vector2, g: Node) -> float:
        var d := b - a
        if g.wrap_mode:
                var br: Rect2 = g.board
                if absf(d.x) > br.size.x * 0.5:
                        d.x -= signf(d.x) * br.size.x
                if absf(d.y) > br.size.y * 0.5:
                        d.y -= signf(d.y) * br.size.y
        return d.length()


## Probe seven headings; return the unblocked one closest to `desired`.
## Blocked = wall (classic), an obstacle, or any snake body (neck excepted).
func _safest_angle(g: Node, desired: float) -> float:
        var probes := [0.0, 0.45, -0.45, 0.95, -0.95, 1.55, -1.55]
        var dist := body.speed * 0.42 + body.width * 2.2
        var best_a := desired
        var best_blocked := 999
        var found_free := false
        for off in probes:
                var a := wrapf(desired + off, -PI, PI)
                var blocked := _probe(g, a, dist)
                if blocked == 0:
                        if not found_free or absf(off) < absf(best_a - desired):
                                best_a = a
                                found_free = true
                                best_blocked = 0
                        if off == 0.0:
                                return desired
                elif not found_free and blocked < best_blocked:
                        best_blocked = blocked
                        best_a = a
        if not found_free and best_blocked > 0:
                _panic = 0.5   # everything ahead is death - turn harder
        return best_a


func _probe(g: Node, angle: float, dist: float) -> int:
        var hits := 0
        var dir := Vector2.from_angle(angle)
        var hr := body.width * 0.5
        for k in [0.45, 0.75, 1.0]:
                var p: Vector2 = body.head_pos + dir * (dist * float(k))
                # walls (classic only - no-walls wraps)
                if not g.wrap_mode:
                        var b: Rect2 = g.board
                        if p.x - hr * 0.7 < b.position.x \
                                        or p.x + hr * 0.7 > b.end.x \
                                        or p.y - hr * 0.7 < b.position.y \
                                        or p.y + hr * 0.7 > b.end.y:
                                hits += 1
                                continue
                # obstacles
                var blocked_by_obs := false
                for o in g.obstacles:
                        if (o as Rect2).grow(hr * 0.6).has_point(p):
                                blocked_by_obs = true
                                break
                if blocked_by_obs:
                        hits += 1
                        continue
                # snake bodies (mine: neck excepted; everyone else: whole)
                for s in g.all_bodies():
                        if s == null or not s.alive:
                                continue
                        if s == body:
                                if s.self_bite(p, hr):
                                        hits += 1
                                        break
                        else:
                                if s.body_hit(p, hr * 0.9):
                                        hits += 1
                                        break
        return hits
