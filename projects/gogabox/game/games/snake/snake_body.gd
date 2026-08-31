class_name SnakeBody
extends RefCounted
## Snake v0.2.0 - ONE smooth snake, shared by the player and every enemy.
## THE MIRROR WORLD (owner spec): no-walls wrap is a MIRROR - exit the top
## wall at 80/100 and you enter the bottom wall at 20/100 (the along-wall
## coordinate flips, the heading is preserved). The trail KEEPS BOTH SIDES
## of every portal crossing together with the true traveled distance, so:
##   * the tail follows the head THROUGH the wall (no more vanish-teleport),
##   * the path length is exact - a 30-degree crossing lands on the same
##     mirrored line every time (the drift-loop bug is dead),
##   * the body renders as strips split at the breaks, with mirrored
##     continuation stubs poking out of the wall (the see-through trick),
##   * eating yourself THROUGH a wall is possible again (portal images).
## The body is still ONE ribbon polygon per strip (no circles, no beads),
## and the WIDTH is DERIVED from the target length now - it shrinks the
## same way it grows (owner symmetry rule).

const SAMPLE_STEP := 11.0        # ribbon sampling step along the trail
const GRAD_FACTOR := 0.96
const GRAD_MIN := 300.0
const GRAD_MAX := 2600.0
const SELF_SKIP := 2.2           # neck arc (x width) ignored for self-bites
const MAX_SEG := 220.0           # longer than this = a WRAP break, not a segment
const LEN_EASE := 110.0          # px/s the body grows/shrinks toward its target

# the shape law (width follows length, both ways - owner rule v0.2.0)
const START_LEN := 320.0
const LEN_PER_APPLE := 70.0
const LEN_FLOOR := 160.0
const WIDTH_START := 26.0
const WIDTH_PER_APPLE := 1.6
const WIDTH_MAX := 64.0
const PORTAL_MARGIN := 190.0     # near-edge band where portal copies matter

var head_pos := Vector2.ZERO
var head_dir := 0.0
var speed := 300.0
var base_speed := 300.0
var perm_mult := 1.0             # PERMANENT speed fruits (sprint/slog)
var length_px := START_LEN
var len_target := START_LEN
var width := WIDTH_START
var len_start := START_LEN       # where this snake started (width anchor)
var width_start := WIDTH_START
var width_max := WIDTH_MAX
var trail: Array[Vector2] = []   # [oldest ... newest = head]
var trail_brk: Array[bool] = []  # brk[i]: segment trail[i-1] -> trail[i] crossed a portal
var trail_warp: Array[float] = []# the true traveled distance across that break
var alive := true
var dying := false               # collapse in progress (paint keeps drawing)
var pal := {"pri": Color("3f7fd4"), "milk": Color("faf3e3")}
var effects := {}                # power id -> seconds left (slower/faster/...)
var flash := 0.0                 # 0..1 red death flash (ONLY the snake turns red)

# per-frame caches (rebuilt by body_points)
var _bp_cache: Array = []
var _bp_dirty := true


func setup(pos: Vector2, dir: float, pri: Color, milk: Color) -> void:
        head_pos = pos
        head_dir = dir
        pal = {"pri": pri, "milk": milk}
        alive = true
        dying = false
        flash = 0.0
        effects = {}
        perm_mult = 1.0
        trail.clear()
        trail_brk.clear()
        trail_warp.clear()
        var back := Vector2.from_angle(dir + PI)
        var n := int(length_px / SAMPLE_STEP)
        for i in range(n, 0, -1):
                _trail_push(head_pos + back * (SAMPLE_STEP * float(i)), false, 0.0)
        _trail_push(head_pos, false, 0.0)
        width = width_from_len(len_target)
        _bp_dirty = true


func _trail_push(p: Vector2, brk: bool, warp: float) -> void:
        trail.append(p)
        trail_brk.append(brk)
        trail_warp.append(warp)


## THE MIRROR WRAP. Crossing a wall flips the ALONG-WALL coordinate once
## (owner: top at 80 -> bottom at 20) and keeps the heading. Returns the
## wrapped point + which portals fired (for the trail break marks).
func wrap_point(p: Vector2, board: Rect2) -> Dictionary:
        var out := p
        var portals := 0
        if out.x < board.position.x:
                out.x = board.end.x - (board.position.x - out.x)
                out.y = board.end.y - (out.y - board.position.y)
                portals += 1
        elif out.x > board.end.x:
                out.x = board.position.x + (out.x - board.end.x)
                out.y = board.end.y - (out.y - board.position.y)
                portals += 1
        if out.y < board.position.y:
                out.y = board.end.y - (board.position.y - out.y)
                out.x = board.end.x - (out.x - board.position.x)
                portals += 1
        elif out.y > board.end.y:
                out.y = board.position.y + (out.y - board.end.y)
                out.x = board.end.x - (out.x - board.position.x)
                portals += 1
        return {"pos": out, "wrapped": portals > 0}


## The portal image of a point through the NEAR edges (the mirror map).
## A body point near the bottom wall is "really" right outside the top wall
## at the flipped x - collisions and pickups test these copies.
func portal_images(p: Vector2, board: Rect2) -> Array:
        var out: Array = []
        var m := PORTAL_MARGIN
        var fx := board.end.x - (p.x - board.position.x)
        var fy := board.end.y - (p.y - board.position.y)
        if p.x - board.position.x < m:
                out.append(Vector2(board.end.x + (p.x - board.position.x), fy))
        if board.end.x - p.x < m:
                out.append(Vector2(board.position.x - (board.end.x - p.x), fy))
        if p.y - board.position.y < m:
                out.append(Vector2(fx, board.end.y + (p.y - board.position.y)))
        if board.end.y - p.y < m:
                out.append(Vector2(fx, board.position.y - (board.end.y - p.y)))
        return out


## Advance one frame. world wrap: no-walls mirrors through the portals;
## walls-kill is checked by the game (classic mode).
func advance(delta: float, board: Rect2, wrap_mode: bool) -> Dictionary:
        var out := {"wrapped": false, "hit_wall": false}
        var mult := speed_mult()
        length_px = move_toward(length_px, len_target, LEN_EASE * delta)
        var step := speed * mult * delta
        var np := head_pos + Vector2.from_angle(head_dir) * step
        if wrap_mode:
                var w := wrap_point(np, board)
                out["wrapped"] = w["wrapped"]
                _trail_push(w["pos"], w["wrapped"], step if w["wrapped"] else 0.0)
                np = w["pos"]
        else:
                var hr := width * 0.5
                if np.x - hr * 0.7 < board.position.x \
                                or np.x + hr * 0.7 > board.end.x \
                                or np.y - hr * 0.7 < board.position.y \
                                or np.y + hr * 0.7 > board.end.y:
                        out["hit_wall"] = true
                _trail_push(np, false, 0.0)
        head_pos = np
        _trim_trail()
        width = width_from_len(len_target)
        _bp_dirty = true
        return out


## Effective speed multiplier: permanent fruits first, then the live powers.
func speed_mult() -> float:
        var mult := perm_mult
        if effects.has("slower"):
                mult *= 0.72
        if effects.has("faster"):
                mult *= 1.45
        return mult


## THE SHAPE LAW: width derives from target length. Apples fatten, bites /
## bugs / wither slim it - the same curve both ways (owner rule).
func width_from_len(lt: float) -> float:
        var w := width_start + WIDTH_PER_APPLE * (lt - len_start) / LEN_PER_APPLE
        return clampf(w, width_start, width_max)


func tick_effects(delta: float) -> void:
        for k in effects.keys():
                effects[k] = float(effects[k]) - delta
        var dead := []
        for k in effects:
                if float(effects[k]) <= 0.0:
                        dead.append(k)
        for k in dead:
                effects.erase(k)


func has_power(id: String) -> bool:
        return effects.has(id)


func apply_power(id: String, dur: float) -> void:
        effects[id] = dur


func grad_len() -> float:
        return clampf(length_px * GRAD_FACTOR, GRAD_MIN, GRAD_MAX)


func half_width(d: float) -> float:
        var t := clampf(d / maxf(length_px, 1.0), 0.0, 1.0)
        var r := width * 0.5 * (1.0 - 0.42 * t)
        if t > 0.82:
                r *= 1.0 - 0.55 * (t - 0.82) / 0.18   # fine tail tip
        return maxf(2.6, r)


func body_color(d: float) -> Color:
        var t := clampf(d / grad_len(), 0.0, 1.0)
        var c: Color = (pal["pri"] as Color).lerp(pal["milk"] as Color, t)
        if flash > 0.0:
                c = c.lerp(Color("e8402f"), flash)
        return c


## Trim by TRUE traveled distance (break segments contribute their stored
## warp, never their field-diagonal straight length - the drift fix).
func _trim_trail() -> void:
        var keep := length_px + 90.0
        var acc := 0.0
        var cut := 0
        for i in range(trail.size() - 1, 0, -1):
                if trail_brk[i]:
                        acc += trail_warp[i]
                else:
                        acc += trail[i].distance_to(trail[i - 1])
                if acc > keep:
                        cut = i
                        break
        if cut > 0:
                for i in cut:
                        trail.pop_front()
                        trail_brk.pop_front()
                        trail_warp.pop_front()


## Walk the trail from the head backward at fixed arc steps:
## [ [pos, dist_from_head], ... ] - the body IS the path. Portal breaks
## contribute their warp to the arc but are never interpolated across;
## the body continues on the other side (the tail follows through).
func body_points() -> Array:
        if not _bp_dirty:
                return _bp_cache
        var out: Array = []
        if trail.size() < 2:
                _bp_cache = out
                _bp_dirty = false
                return out
        var head: Vector2 = trail[trail.size() - 1]
        out.append([head, 0.0])
        var acc := 0.0
        var next_at := SAMPLE_STEP
        for i in range(trail.size() - 1, 0, -1):
                var a: Vector2 = trail[i]
                var b: Vector2 = trail[i - 1]
                if trail_brk[i]:
                        acc += maxf(trail_warp[i], 0.0)
                        # pending samples pin at the entry point b until the arc passes it
                        while next_at <= acc and next_at <= length_px:
                                out.append([b, next_at])
                                next_at += SAMPLE_STEP
                else:
                        var seg := a.distance_to(b)
                        while acc + seg >= next_at and next_at <= length_px:
                                var t := clampf((next_at - acc) / maxf(seg, 0.001), 0.0, 1.0)
                                out.append([a.lerp(b, t), next_at])
                                next_at += SAMPLE_STEP
                        acc += seg
                if next_at > length_px or acc > length_px:
                        break
        _bp_cache = out
        _bp_dirty = false
        return out


## Head circle (at `hp`, radius `hr`) vs this snake's own body, neck
## excepted - PORTAL-AWARE: near an edge the mirrored copies are tested
## too, so wrapping into yourself is a real death (or a real bite).
func self_bite(hp: Vector2, hr: float, board: Rect2) -> bool:
        var skip := width * SELF_SKIP + 10.0
        var tests := [hp]
        for img in portal_images(hp, board):
                tests.append(img)
        for tp in tests:
                var step := 0.0
                for i in range(trail.size() - 1, 0, -1):
                        if trail_brk[i]:
                                step += trail_warp[i]
                                continue
                        var a: Vector2 = trail[i]
                        var b: Vector2 = trail[i - 1]
                        var seg := a.distance_to(b)
                        var t0 := maxf(0.0, skip - step)
                        var s := t0
                        while s <= seg:
                                var p := a.lerp(b, s / maxf(seg, 0.001))
                                var br := half_width(step + s)
                                if tp.distance_to(p) < (hr + br) * 0.58:
                                        return true
                                s += SAMPLE_STEP * 0.75
                        step += seg
                        if step > length_px:
                                break
        return false


## Does the head circle touch ANY part of this snake's body (head-vs-other
## checks), portal-aware like self_bite? `tail_zone_frac` > 0 limits the
## check to the tailmost fraction (the SNAKE-EATER bite zone) and reports
## the bite point through out_bite.
func body_hit(hp: Vector2, hr: float, tail_zone_frac := 0.0,
                out_bite: Array = [], board: Rect2 = Rect2()) -> bool:
        var pts := body_points()
        var total := length_px
        var zone_from := total * (1.0 - tail_zone_frac) if tail_zone_frac > 0.0 else -1.0
        var best_d := INF
        var found := false
        var tests := [hp]
        if board.size.x > 1.0:
                for img in portal_images(hp, board):
                        tests.append(img)
        for tp in tests:
                for pinfo in pts:
                        var p: Vector2 = pinfo[0]
                        var d: float = pinfo[1]
                        if zone_from >= 0.0 and d < zone_from:
                                continue
                        var br := half_width(d)
                        var dist: float = tp.distance_to(p)
                        if dist < (hr + br) * 0.62 and dist < best_d:
                                best_d = dist
                                found = true
                                if out_bite != null and out_bite.is_empty():
                                        out_bite.append(p)
        return found


## SNAKE-EATER on YOURSELF (owner v0.2.0): self-collision while wearing
## eater is a BITE, not a death. Returns the arc distance of the contact
## point (beyond the neck) - everything past it leaves the body.
func bite_back(hp: Vector2, board: Rect2) -> float:
        var skip := width * SELF_SKIP + 10.0
        var pts := body_points()
        var best_d := -1.0
        var tests := [hp]
        for img in portal_images(hp, board):
                tests.append(img)
        for tp in tests:
                for pinfo in pts:
                        var d: float = pinfo[1]
                        if d < skip:
                                continue
                        if tp.distance_to(pinfo[0]) < width * 1.15 and d > best_d:
                                best_d = d
        return best_d


## THE RIBBON STRIPS: one closed polygon per portal-run (left edge -> tail
## cap -> right edge) with per-vertex gradient colors. `grow` widens (the
## outline pass). Returns an Array of {pts, cols} - the game paints each
## strip plus its mirrored wall stubs.
func ribbon(grow := 0.0, col_override := Color(0, 0, 0, 0)) -> Array:
        var pts := body_points()
        var strips: Array = []
        if pts.size() < 3:
                return strips
        # split the sampled path at portal jumps (consecutive samples farther
        # apart than MAX_SEG can only be a break)
        var runs: Array = []
        var run: Array = [pts[0]]
        for i in range(1, pts.size()):
                if (pts[i][0] as Vector2).distance_to(pts[i - 1][0]) > MAX_SEG:
                        runs.append(run)
                        run = [pts[i]]
                else:
                        run.append(pts[i])
        runs.append(run)
        for r in runs:
                var st := _ribbon_of_run(r, grow, col_override)
                if not st.is_empty():
                        strips.append(st)
        return strips


func _ribbon_of_run(pts: Array, grow: float, col_override: Color) -> Dictionary:
        var n := pts.size()
        if n < 3:
                return {}
        var left := PackedVector2Array()
        var right := PackedVector2Array()
        var cols := PackedColorArray()
        var cols_r := PackedColorArray()
        for i in n:
                var p: Vector2 = pts[i][0]
                var d: float = pts[i][1]
                var a: Vector2 = pts[maxi(0, i - 1)][0]
                var b: Vector2 = pts[mini(n - 1, i + 1)][0]
                var tangent := (a - b).normalized()
                if tangent == Vector2.ZERO:
                        tangent = Vector2.from_angle(head_dir)
                var nrm := Vector2(-tangent.y, tangent.x)
                var r := half_width(d) + grow
                var c := col_override if col_override.a > 0.0 else body_color(d)
                left.append(p + nrm * r)
                right.append(p - nrm * r)
                cols.append(c)
                cols_r.append(c)
        # tail cap: a rounded arc around the tip tangent - the body ends CLOSED
        var tail_p: Vector2 = pts[n - 1][0]
        var tail_d: float = pts[n - 1][1]
        var a2: Vector2 = pts[n - 2][0]
        var tangent2 := (tail_p - a2).normalized()
        if tangent2 == Vector2.ZERO:
                tangent2 = Vector2.from_angle(head_dir)
        var nrm2 := Vector2(-tangent2.y, tangent2.x)
        var r2 := half_width(tail_d) + grow
        var cap := PackedVector2Array()
        var cap_cols := PackedColorArray()
        var base_a := nrm2.angle()
        for i in range(1, 7):
                var ang := base_a + PI * float(i) / 7.0
                cap.append(tail_p + Vector2.from_angle(ang) * r2)
                cap_cols.append(col_override if col_override.a > 0.0 else body_color(tail_d))
        var poly := PackedVector2Array()
        var pc := PackedColorArray()
        for i in left.size():
                poly.append(left[i])
                pc.append(cols[i])
        for i in cap.size():
                poly.append(cap[i])
                pc.append(cap_cols[i])
        for i in range(right.size() - 1, -1, -1):
                poly.append(right[i])
                pc.append(cols_r[i])
        return {"pts": poly, "cols": pc}


## Wall continuation runs for the MIRROR portals (v0.2.0): sample runs whose
## head-side or tail-side end sits near a wall, mapped through that wall's
## mirror - these paint OUTSIDE the wall so the tail visibly follows the
## head through (the see-through trick the owner asked for).
const STUB_PX := 64.0

func wall_stubs(board: Rect2) -> Array:
        var out: Array = []
        if not _brk_any():
                return out
        var pts := body_points()
        # split exactly like ribbon() does
        var runs: Array = []
        var run: Array = [pts[0]]
        for i in range(1, pts.size()):
                if (pts[i][0] as Vector2).distance_to(pts[i - 1][0]) > MAX_SEG:
                        runs.append(run)
                        run = [pts[i]]
                else:
                        run.append(pts[i])
        runs.append(run)
        for r in runs:
                if r.size() < 2:
                        continue
                for at_end in [false, true]:
                        var tip: Vector2 = (r[r.size() - 1] if at_end else r[0])[0]
                        var img := mirror_point(tip, board)
                        if tip.distance_to(img) < 1.0:
                                continue   # not near any wall
                        # collect up to 6 samples from that end, mirrored
                        var mapped: Array = []
                        var n := mini(6, r.size())
                        for k in n:
                                var idx: int = r.size() - 1 - k if at_end else k
                                var info: Array = r[idx]
                                mapped.append([mirror_point(info[0], board), info[1]])
                        if not at_end:
                                mapped.reverse()
                        out.append(mapped)
        return out


func _brk_any() -> bool:
        for b in trail_brk:
                if b:
                        return true
        return false


## Map a near-wall point through ITS nearest wall's mirror (the same map
## wrap_point applies at the crossing).
func mirror_point(p: Vector2, board: Rect2) -> Vector2:
        if p.y - board.position.y < STUB_PX:
                return Vector2(board.end.x - (p.x - board.position.x),
                                board.end.y + (p.y - board.position.y))
        if board.end.y - p.y < STUB_PX:
                return Vector2(board.end.x - (p.x - board.position.x),
                                board.position.y - (board.end.y - p.y))
        if p.x - board.position.x < STUB_PX:
                return Vector2(board.end.x + (p.x - board.position.x),
                                board.end.y - (p.y - board.position.y))
        if board.end.x - p.x < STUB_PX:
                return Vector2(board.position.x - (board.end.x - p.x),
                                board.end.y - (p.y - board.position.y))
        return p


## Build a small ribbon polygon for a mirrored stub run (same vertex
## scheme as _ribbon_of_run - widths and gradient colors ride along).
func stub_ribbon(run: Array) -> Dictionary:
        if run.size() < 3:
                return {}
        # pad the tip so the stub has body on both sides of the wall line
        var padded := run.duplicate()
        var tip: Array = run[run.size() - 1]
        var pre: Array = run[run.size() - 2] if run.size() >= 2 else tip
        var tan := ((tip[0] as Vector2) - (pre[0] as Vector2)).normalized()
        if tan == Vector2.ZERO:
                tan = Vector2.from_angle(head_dir)
        var ext: Array = [(tip[0] as Vector2) + tan * SAMPLE_STEP, tip[1]]
        padded.append(ext)
        return _ribbon_of_run(padded, 0.0, Color(0, 0, 0, 0))


## Total half width at the head (the head disc radius).
func head_r() -> float:
        return width * 0.5 * 1.22
