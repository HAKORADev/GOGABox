class_name SnakeBody
extends RefCounted
## Snake v0.1.9 - ONE smooth snake, shared by the player and every enemy.
## The body is a SINGLE ribbon polygon extruded along the head's trail:
## no circles, no beads, no separate parts - "too smooth" (owner spec).
## The gradient (palette head-color -> milk) is per-vertex along the ribbon
## and its span STRETCHES as the snake grows (the v0.1.8 melt rule stays).

const SAMPLE_STEP := 11.0        # ribbon sampling step along the trail
const GRAD_FACTOR := 0.96
const GRAD_MIN := 300.0
const GRAD_MAX := 2600.0
const SELF_SKIP := 2.2           # neck arc (x width) ignored for self-bites
const MAX_SEG := 220.0           # longer than this = a WRAP break, not a segment
const LEN_EASE := 110.0          # px/s the body grows/shrinks toward its target

var head_pos := Vector2.ZERO
var head_dir := 0.0
var speed := 300.0
var base_speed := 300.0
var length_px := 320.0
var len_target := 320.0
var width := 26.0
var trail: Array[Vector2] = []   # [oldest ... newest = head]
var alive := true
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
        trail.clear()
        var back := Vector2.from_angle(dir + PI)
        var n := int(length_px / SAMPLE_STEP)
        for i in range(n, 0, -1):
                trail.append(head_pos + back * (SAMPLE_STEP * float(i)))
        trail.append(head_pos)
        _bp_dirty = true


## Advance one frame. world_wrap: null = walls kill at the board edge
## (checked by the game); a Callable(pos)->Dictionary{pos, wrapped} wraps.
func advance(delta: float, board: Rect2, wrap_mode: bool) -> Dictionary:
        var out := {"wrapped": false, "hit_wall": false}
        # speed = base * power multipliers
        var mult := 1.0
        if effects.has("slower"):
                mult *= 0.72
        if effects.has("faster"):
                mult *= 1.45
        length_px = move_toward(length_px, len_target, LEN_EASE * delta)
        head_dir += 0.0   # steering writes head_dir directly
        var step := speed * mult * delta
        var np := head_pos + Vector2.from_angle(head_dir) * step
        if wrap_mode:
                var w := wrap_point(np, board)
                out["wrapped"] = w["wrapped"]
                np = w["pos"]
        else:
                var hr := width * 0.5
                if np.x - hr * 0.7 < board.position.x \
                                or np.x + hr * 0.7 > board.end.x \
                                or np.y - hr * 0.7 < board.position.y \
                                or np.y + hr * 0.7 > board.end.y:
                        out["hit_wall"] = true
        head_pos = np
        trail.append(head_pos)
        _trim_trail()
        _bp_dirty = true
        return out


func wrap_point(p: Vector2, board: Rect2) -> Dictionary:
        var out := p
        var wrapped := false
        if p.x < board.position.x:
                out.x = board.end.x - fmod(board.position.x - p.x, board.size.x)
                wrapped = true
        elif p.x > board.end.x:
                out.x = board.position.x + fmod(p.x - board.end.x, board.size.x)
                wrapped = true
        if p.y < board.position.y:
                out.y = board.end.y - fmod(board.position.y - p.y, board.size.y)
                wrapped = true
        elif p.y > board.end.y:
                out.y = board.position.y + fmod(p.y - board.end.y, board.size.y)
                wrapped = true
        return {"pos": out, "wrapped": wrapped}


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


func _trim_trail() -> void:
        var keep := length_px + 90.0
        var acc := 0.0
        var cut := 0
        for i in range(trail.size() - 1, 0, -1):
                var seg := trail[i].distance_to(trail[i - 1])
                if seg > MAX_SEG:
                        cut = i
                        break
                acc += seg
                if acc > keep:
                        cut = i
                        break
        if cut > 0:
                for i in cut:
                        trail.pop_front()


## Walk the trail from the head backward at fixed arc steps:
## [ [pos, dist_from_head], ... ] - the body IS the path. Wrap breaks
## (segments longer than MAX_SEG) are skipped, never sampled.
func body_points() -> Array:
        if not _bp_dirty:
                return _bp_cache
        var out: Array = []
        var head: Vector2 = trail[trail.size() - 1]
        out.append([head, 0.0])
        var acc := 0.0
        var next_at := SAMPLE_STEP
        for i in range(trail.size() - 1, 0, -1):
                var a: Vector2 = trail[i]
                var b: Vector2 = trail[i - 1]
                var seg := a.distance_to(b)
                if seg > MAX_SEG:
                        # wrap break: the tail continues from b on the other
                        # side; arc distance still grows
                        acc += SAMPLE_STEP
                        if acc > length_px:
                                break
                        out.append([b, acc])
                        next_at = acc + SAMPLE_STEP
                        continue
                while acc + seg >= next_at and next_at <= length_px:
                        var t := (next_at - acc) / maxf(seg, 0.001)
                        out.append([a.lerp(b, t), next_at])
                        next_at += SAMPLE_STEP
                acc += seg
                if next_at > length_px:
                        break
        _bp_cache = out
        _bp_dirty = false
        return out


## Does the head circle at `hp` (radius `hr`) touch this snake's own body,
## ignoring the neck arc? (self-bite)
func self_bite(hp: Vector2, hr: float) -> bool:
        var skip := width * SELF_SKIP + 10.0
        var step := 0.0
        for i in range(trail.size() - 1, 0, -1):
                var a: Vector2 = trail[i]
                var b: Vector2 = trail[i - 1]
                var seg := a.distance_to(b)
                if seg > MAX_SEG:
                        step += seg
                        continue
                var t0 := maxf(0.0, skip - step)
                var s := t0
                while s <= seg:
                        var p := a.lerp(b, s / maxf(seg, 0.001))
                        var br := half_width(step + s)
                        if hp.distance_to(p) < (hr + br) * 0.58:
                                return true
                        s += SAMPLE_STEP * 0.75
                step += seg
                if step > length_px:
                        break
        return false


## Does the head circle touch ANY part of this snake's body (for head-vs-
## other-body checks)? `tail_zone_frac` > 0 limits the check to the tailmost
## fraction of the body (the SNAKE-EATER bite zone) and returns the bite
## point through out_bite.
func body_hit(hp: Vector2, hr: float, tail_zone_frac := 0.0,
                out_bite: Array = []) -> bool:
        var pts := body_points()
        var total := length_px
        var zone_from := total * (1.0 - tail_zone_frac) if tail_zone_frac > 0.0 else -1.0
        var best_d := INF
        var found := false
        for pinfo in pts:
                var p: Vector2 = pinfo[0]
                var d: float = pinfo[1]
                if zone_from >= 0.0 and d < zone_from:
                        continue
                var br := half_width(d)
                var dist := hp.distance_to(p)
                if dist < (hr + br) * 0.62 and dist < best_d:
                        best_d = dist
                        found = true
                        if out_bite != null and out_bite.is_empty():
                                out_bite.append(p)
        return found


## THE RIBBON: one closed polygon (left edge -> tail cap -> right edge) with
## a per-vertex color for the gradient. `grow` widens it (the outline pass).
## Returns {} or {pts: PackedVector2Array, cols: PackedColorArray}.
func ribbon(grow := 0.0, col_override := Color(0, 0, 0, 0)) -> Dictionary:
        var pts := body_points()
        if pts.size() < 3:
                return {}
        var n := pts.size()
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
        # tail cap: a small arc fanning around the last point
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
        for i in range(1, 6):
                var ang := base_a + PI * float(i) / 6.0
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


## Total half width at the head (the head disc radius).
func head_r() -> float:
        return width * 0.5 * 1.22
