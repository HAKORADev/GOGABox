class_name SnakeFruits
extends RefCounted
## Snake v0.2.0 - the catalog side: fruits, power fruits with auras, the
## enemy color set, and the PLACES (day garden / night garden). Every fruit
## is HAND-PAINTED vector art in the game's own draw language - v0.2.0
## re-crafted every painter with real silhouettes, shading, stems and
## highlights (the owner looked at the v0.1.9 render sheet and the banana
## was guilty). Eat particles always use the eaten thing's colors.

## ------------------------------------------------------------- fruits
## price 0 = the default edible (always there). The rest live in the shop.
const FRUITS := {
        "apple":      {"name": "Apple",      "price": 0,   "body": Color("e8574a"), "acc": Color("58c470")},
        "banana":     {"name": "Banana",     "price": 80,  "body": Color("ffd23e"), "acc": Color("8a6a20")},
        "cherry":     {"name": "Cherry",     "price": 80,  "body": Color("d0344a"), "acc": Color("58c470")},
        "orange":     {"name": "Orange",     "price": 80,  "body": Color("ff9838"), "acc": Color("58c470")},
        "grapes":     {"name": "Grapes",     "price": 100, "body": Color("8a56c8"), "acc": Color("58c470")},
        "strawberry": {"name": "Strawberry", "price": 100, "body": Color("e84a5a"), "acc": Color("58c470")},
        "pear":       {"name": "Pear",       "price": 100, "body": Color("b8d45a"), "acc": Color("58c470")},
        "lemon":      {"name": "Lemon",      "price": 100, "body": Color("f7e83a"), "acc": Color("58c470")},
        "peach":      {"name": "Peach",      "price": 120, "body": Color("ffa878"), "acc": Color("58c470")},
        "watermelon": {"name": "Watermelon", "price": 150, "body": Color("4ac458"), "acc": Color("e8574a")},
        "pineapple":  {"name": "Pineapple",  "price": 150, "body": Color("e8b23a"), "acc": Color("58c470")},
}

## ------------------------------------------------------------- powers
## The owner's law: NEVER the same spawn-randomness, spawn-time or activation
## time. weight = the spawn roll; cd = seconds of cooldown after the fruit
## leaves the field; dur = active seconds once eaten (0 = PERMANENT - sprint
## and slog rewrite base speed forever via "perm"); good = celebration vs
## dread. eater needs the ENEMIES PACK owned.
const POWERS := {
        "slower": {"name": "SLOWER",  "weight": 20.0, "cd": Vector2(8.0, 14.0),
                "dur": 12.0, "good": true,  "aura": Color("7a9ad8"), "needs": "", "perm": 0.0},
        "faster": {"name": "FASTER",  "weight": 16.0, "cd": Vector2(10.0, 18.0),
                "dur": 8.0,  "good": true,  "aura": Color("ff8a3a"), "needs": "", "perm": 0.0},
        "ghost":  {"name": "GHOST",   "weight": 13.0, "cd": Vector2(12.0, 20.0),
                "dur": 7.0,  "good": true,  "aura": Color("b8a8e8"), "needs": "", "perm": 0.0},
        "magnet": {"name": "MAGNET",  "weight": 15.0, "cd": Vector2(10.0, 16.0),
                "dur": 10.0, "good": true,  "aura": Color("ffc93c"), "needs": "", "perm": 0.0},
        "golden": {"name": "GOLDEN",  "weight": 15.0, "cd": Vector2(9.0, 15.0),
                "dur": 10.0, "good": true,  "aura": Color("ffe86a"), "needs": "", "perm": 0.0},
        "wither": {"name": "WITHER",  "weight": 13.0, "cd": Vector2(10.0, 18.0),
                "dur": 8.0,  "good": false, "aura": Color("8ac44a"), "needs": "", "perm": 0.0},
        "sprint": {"name": "SPRINT",  "weight": 9.0,  "cd": Vector2(18.0, 30.0),
                "dur": 0.0,  "good": true,  "aura": Color("ff5a3a"), "needs": "", "perm": 1.5},
        "slog":   {"name": "SLOG",    "weight": 9.0,  "cd": Vector2(16.0, 26.0),
                "dur": 0.0,  "good": false, "aura": Color("9a86c8"), "needs": "", "perm": 0.5},
        "eater":  {"name": "EATER",   "weight": 11.0, "cd": Vector2(14.0, 22.0),
                "dur": 10.0, "good": true,  "aura": Color("e8402f"), "needs": "pack", "perm": 0.0},
}

## ------------------------------------------------------------- places
## The garden the run plays in (owner v0.2.0): DAY GARDEN - green grass,
## a warm sun, soft shadows; NIGHT GARDEN - moonlight, stars and the tiny
## flies from the owner's 3D snake. Chosen before the run (optionals box +
## shop), night is a shop unlock. Everything the field painter needs lives
## here so the game stays one paint pass.
const PLACES := {
        "day":   {"name": "DAY GARDEN",   "price": 0,
                "field": Color("aed886"), "deco": Color("98cc72"), "deco2": Color("c2e49c"),
                "wall": Color("5f9444"), "wrap": Color("4f8a3e"), "ink": Color("2e4a1e"),
                "void": Color("8cc46a"), "shadow": Color(0.10, 0.22, 0.06, 0.16)},
        "night": {"name": "NIGHT GARDEN", "price": 250,
                "field": Color("2c3f55"), "deco": Color("26374c"), "deco2": Color("334962"),
                "wall": Color("5d82a6"), "wrap": Color("7ab8d8"), "ink": Color("cfe4f4"),
                "void": Color("1c2a3d"), "shadow": Color(0.02, 0.05, 0.12, 0.22)},
}

## ------------------------------------------------------------- enemies
## Enemy #0 is the FREE opponent - the owner: "make the opponent snake green".
const ENEMY_COLORS := [
        Color("3fae5c"),   # green - the free one
        Color("e8632a"),   # ember
        Color("8a56c8"),   # violet
        Color("38b8c8"),   # cyan
        Color("e84a8a"),   # pink
        Color("a8c438"),   # lime
        Color("4a6ae8"),   # blue
        Color("c84a4a"),   # red
        Color("e8d23a"),   # yellow
        Color("8a5a34"),   # soil
]
const ENEMY_NAMES := ["GREEN", "EMBER", "VIOLET", "CYAN", "PINK", "LIME",
        "BLUE", "RED", "SUN", "SOIL"]

## A soft milk companion color for any body color (the gradient tail).
static func milk_for(c: Color) -> Color:
        return c.lerp(Color("faf3e3"), 0.72)


static func fruit_body(id: String) -> Color:
        return FRUITS.get(id, FRUITS["apple"])["body"]


## The current edible's LOOK id: the optionals fruit selector picks apple /
## all-owned / a specific one; "all" rolls every owned fruit each spawn.
static func roll_edible(owned: Array, mode: String) -> String:
        if mode == "" or mode == "apple" or mode == "off":
                return "apple"
        if mode == "all":
                var pool := ["apple"]
                for f in owned:
                        if FRUITS.has(String(f)):
                                pool.append(String(f))
                return pool[randi() % pool.size()]
        if FRUITS.has(mode):
                return mode
        return "apple"


# ================================================================== PAINTERS
## r = the fruit radius. t = the game clock (breathing wobble). Every painter
## draws around `pos` - no state, pure strokes. v0.2.0 craft: real
## silhouettes, rim shading, stems, highlights - and a soft ground shadow.

static func paint_fruit(v: CanvasItem, id: String, pos: Vector2, r: float,
                t: float, shadow := true) -> void:
        var wob := 1.0 + 0.035 * sin(t * 3.1)
        r *= wob
        if shadow:
                _ground_shadow(v, pos, r)
        match id:
                "banana": _banana(v, pos, r)
                "cherry": _cherry(v, pos, r)
                "grapes": _grapes(v, pos, r)
                "strawberry": _strawberry(v, pos, r)
                "watermelon": _watermelon(v, pos, r)
                "pear": _pear(v, pos, r)
                "lemon": _lemon(v, pos, r)
                "orange": _orange(v, pos, r)
                "peach": _peach(v, pos, r)
                "pineapple": _pineapple(v, pos, r)
                _: _apple(v, pos, r)


static func _ground_shadow(v: CanvasItem, pos: Vector2, r: float) -> void:
        v.draw_circle(pos + Vector2(r * 0.18, r * 0.9), r * 0.92,
                        Color(0.08, 0.16, 0.04, 0.16))


static func _ellipse(v: CanvasItem, c: Vector2, rx: float, ry: float,
                col: Color, rot := 0.0) -> void:
        var pts := PackedVector2Array()
        for i in 20:
                var a := TAU * float(i) / 20.0
                pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
        v.draw_colored_polygon(pts, col)


## A sphere with rim shading + a soft top-left highlight (the craft base).
static func _sphere(v: CanvasItem, c: Vector2, r: float, body: Color,
                hi_scale := 1.0) -> void:
        v.draw_circle(c, r, body.darkened(0.28))
        v.draw_circle(c + Vector2(-r * 0.06, -r * 0.08), r * 0.94, body)
        v.draw_circle(c + Vector2(r * 0.16, r * 0.2), r * 0.82,
                        body.darkened(0.12))
        v.draw_circle(c + Vector2(-r * 0.32, -r * 0.34) * hi_scale, r * 0.2,
                        Color(1, 1, 1, 0.65))
        v.draw_circle(c + Vector2(-r * 0.18, -r * 0.22) * hi_scale, r * 0.34,
                        Color(1, 1, 1, 0.22))


static func _stem(v: CanvasItem, top: Vector2, r: float, lean := 0.25) -> void:
        v.draw_line(top, top + Vector2(r * lean, -r * 0.34),
                        Color("7a4a1e"), maxf(2.6, r * 0.13))


static func _leaf(v: CanvasItem, at: Vector2, r: float, ang := -0.7,
                col := Color("4ea24e")) -> void:
        var pts := PackedVector2Array()
        var L := r * 0.62
        for i in 12:
                var s := float(i) / 11.0
                var wid := sin(s * PI) * L * 0.4
                var dir := Vector2.from_angle(ang)
                var side := dir.orthogonal()
                pts.append(at + dir * L * s + side * wid)
        for i in range(11, -1, -1):
                var s := float(i) / 11.0
                var wid := sin(s * PI) * L * 0.4
                var dir := Vector2.from_angle(ang)
                var side := dir.orthogonal()
                pts.append(at + dir * L * s - side * wid)
        v.draw_colored_polygon(pts, col.darkened(0.15))
        v.draw_line(at, at + Vector2.from_angle(ang) * L, col.darkened(0.4),
                        maxf(1.6, r * 0.06))


static func _apple(v: CanvasItem, pos: Vector2, r: float) -> void:
        var body: Color = FRUITS["apple"]["body"]
        # two-lobe silhouette
        var pts := PackedVector2Array()
        for i in 26:
                var a := TAU * float(i) / 26.0 - PI * 0.5
                var rr := r * (1.0 + 0.07 * cos(2.0 * a))
                pts.append(pos + Vector2(cos(a) * rr * 1.02, sin(a) * rr * 0.98))
        v.draw_colored_polygon(pts, body.darkened(0.28))
        for i in 26:
                var a := TAU * float(i) / 26.0 - PI * 0.5
                var rr := r * (0.94 + 0.06 * cos(2.0 * a))
                pts[i] = pos + Vector2(cos(a) * rr * 0.98, sin(a) * rr * 0.94)
        v.draw_colored_polygon(pts, body)
        # top dimple + stem + leaf
        v.draw_circle(pos + Vector2(0, -r * 0.86), r * 0.2, body.darkened(0.32))
        _stem(v, pos + Vector2(0, -r * 0.82), r)
        _leaf(v, pos + Vector2(r * 0.16, -r * 1.02), r * 1.15, -0.5)
        v.draw_circle(pos + Vector2(-r * 0.32, -r * 0.3), r * 0.22,
                        Color(1, 1, 1, 0.5))
        v.draw_circle(pos + Vector2(-r * 0.16, -r * 0.18), r * 0.36,
                        Color(1, 1, 1, 0.16))


static func _banana(v: CanvasItem, pos: Vector2, r: float) -> void:
        var body: Color = FRUITS["banana"]["body"]
        var rim := body.darkened(0.35)
        var tipc := Color("6a4a14")
        # a REAL banana: one spine arc, tapered width (fat belly, pointy ends),
        # both edges offset RADIALLY so the curve stays honest
        var c := pos + Vector2(0, r * 1.05)
        var R := r * 1.35
        var a0 := deg_to_rad(25.0)
        var a1 := deg_to_rad(155.0)
        var steps := 22
        var left := PackedVector2Array()
        var right := PackedVector2Array()
        var spine := PackedVector2Array()
        for i in steps + 1:
                var t := float(i) / float(steps)
                var dir := Vector2.from_angle(lerpf(a0, a1, t))
                var w := r * 0.6 * pow(sin(PI * t), 0.62) + r * 0.05
                spine.append(c + dir * R)
                left.append(c + dir * (R + w * 0.5))
                right.append(c + dir * (R - w * 0.5))
        var poly := left
        for i in range(right.size() - 1, -1, -1):
                poly.append(right[i])
        v.draw_colored_polygon(poly, rim)
        var poly2 := PackedVector2Array()
        for p in poly:
                poly2.append(c + (p - c) * 0.9)
        v.draw_colored_polygon(poly2, body)
        # the spine ridge + a belly shade band (both follow the curve now)
        v.draw_polyline(spine, body.darkened(0.16), maxf(2.0, r * 0.08), true)
        var band := PackedVector2Array()
        for i in steps + 1:
                var t := float(i) / float(steps)
                band.append(c + Vector2.from_angle(lerpf(a0, a1, t)) * (R - r * 0.3))
        v.draw_polyline(band, body.darkened(0.24), maxf(2.4, r * 0.11), true)
        # stem chunk at one end, dark tip at the other
        var tA := (spine[1] - spine[0]).normalized()
        var tB := (spine[spine.size() - 1] - spine[spine.size() - 2]).normalized()
        v.draw_line(spine[0], spine[0] + tA * r * 0.34, tipc,
                        maxf(3.4, r * 0.17), true)
        v.draw_circle(spine[spine.size() - 1] + tB * r * 0.08, r * 0.11, tipc)
        # ripe speckles on the belly + a soft highlight on the back
        v.draw_circle(c + Vector2.from_angle(deg_to_rad(80.0)) * (R - r * 0.1),
                        r * 0.05, Color("8a6a20"))
        v.draw_circle(c + Vector2.from_angle(deg_to_rad(105.0)) * (R + r * 0.02),
                        r * 0.045, Color("8a6a20"))
        v.draw_circle(c + Vector2.from_angle(deg_to_rad(62.0)) * (R + r * 0.18),
                        r * 0.14, Color(1, 1, 1, 0.3))


static func _cherry(v: CanvasItem, pos: Vector2, r: float) -> void:
        var body: Color = FRUITS["cherry"]["body"]
        var off := Vector2(r * 0.58, r * 0.38)
        var knot := pos + Vector2(0, -r * 1.25)
        for s in [-1.0, 1.0]:
                var c := pos + off * Vector2(s, 1.0)
                _sphere(v, c, r * 0.58, body)
                v.draw_line(c + Vector2(0, -r * 0.5), knot + Vector2(s * r * 0.12, 0),
                                Color("4ea24e").darkened(0.3), maxf(2.0, r * 0.09))
        v.draw_line(knot, knot + Vector2(0, -r * 0.3),
                        Color("4ea24e").darkened(0.3), maxf(2.4, r * 0.1))
        _leaf(v, knot, r * 1.1, -0.35)


static func _orange(v: CanvasItem, pos: Vector2, r: float) -> void:
        var body: Color = FRUITS["orange"]["body"]
        _sphere(v, pos, r, body)
        # the peel dimples: a loose ring of tiny pores
        for i in 9:
                var a := TAU * float(i) / 9.0 + 0.3
                v.draw_circle(pos + Vector2.from_angle(a) * r * 0.55, r * 0.05,
                                body.darkened(0.22))
        v.draw_circle(pos + Vector2(0, r * 0.78), r * 0.1, body.darkened(0.3))
        _stem(v, pos + Vector2(0, -r * 0.9), r, 0.1)
        _leaf(v, pos + Vector2(r * 0.12, -r * 1.05), r * 1.1, -0.45)


static func _grapes(v: CanvasItem, pos: Vector2, r: float) -> void:
        var body: Color = FRUITS["grapes"]["body"]
        var gr := r * 0.44
        var offs := [Vector2(-0.52, 0.35), Vector2(0.52, 0.35), Vector2(0, 0.72),
                Vector2(-0.26, 1.0), Vector2(0.26, 1.0), Vector2(0, 0.18),
                Vector2(-0.5, -0.05), Vector2(0.5, -0.05), Vector2(0, -0.22)]
        for o in offs:
                var c: Vector2 = pos + (o as Vector2) * r * 1.05
                v.draw_circle(c, gr, body.darkened(0.3))
                v.draw_circle(c + Vector2(-gr * 0.07, -gr * 0.09), gr * 0.88, body)
                v.draw_circle(c + Vector2(-gr * 0.28, -gr * 0.3), gr * 0.2,
                                Color(1, 1, 1, 0.4))
        _stem(v, pos + Vector2(0, -r * 0.62), r * 1.2, 0.3)
        _leaf(v, pos + Vector2(r * 0.2, -r * 0.85), r * 1.2, -0.5)


static func _strawberry(v: CanvasItem, pos: Vector2, r: float) -> void:
        var body: Color = FRUITS["strawberry"]["body"]
        # heart-cone silhouette (wide shoulders, soft point down)
        var pts := PackedVector2Array()
        for i in 24:
                var a := TAU * float(i) / 24.0 - PI * 0.5
                var sy := sin(a)
                var rr := r * (0.62 + 0.42 * pow(maxf(0.0, cos(a)), 0.7)
                                + 0.18 * maxf(0.0, -sy))
                pts.append(pos + Vector2(cos(a) * rr * 0.92, sy * rr * 1.08))
        v.draw_colored_polygon(pts, body.darkened(0.3))
        var pts2 := PackedVector2Array()
        for p in pts:
                pts2.append(pos + (p - pos) * 0.9)
        v.draw_colored_polygon(pts2, body)
        # the seeds sit IN the flesh (dark pit + pale core)
        for i in 7:
                var a := -0.9 + float(i) * 0.42
                var sp := pos + Vector2(cos(a) * r * 0.42,
                                r * 0.1 + sin(a) * r * 0.34)
                v.draw_circle(sp, r * 0.06, Color("7a2020"))
                v.draw_circle(sp + Vector2(0, -r * 0.02), r * 0.035, Color("ffe8b0"))
        # calyx: five pointed leaves + crown
        for k in 5:
                var a := -PI * 0.5 + (float(k) - 2.0) * 0.55
                var tip2 := pos + Vector2(0, -r * 0.62) + Vector2.from_angle(a) * r * 0.5
                v.draw_line(pos + Vector2(0, -r * 0.5), tip2,
                                Color("3e8a3e"), maxf(2.4, r * 0.11))
        _stem(v, pos + Vector2(0, -r * 0.7), r, 0.12)
        v.draw_circle(pos + Vector2(-r * 0.28, -r * 0.05), r * 0.18,
                        Color(1, 1, 1, 0.3))


static func _pear(v: CanvasItem, pos: Vector2, r: float) -> void:
        var body: Color = FRUITS["pear"]["body"]
        var pts := PackedVector2Array()
        for i in 26:
                var a := TAU * float(i) / 26.0 - PI * 0.5
                var sy := sin(a)
                # small head on top, fat belly at the bottom
                var rr := r * (0.56 + 0.46 * pow(clampf(0.5 + sy * 0.9, 0.0, 1.0), 0.8))
                pts.append(pos + Vector2(cos(a) * rr * 0.94, sy * rr * 1.12))
        v.draw_colored_polygon(pts, body.darkened(0.3))
        var pts2 := PackedVector2Array()
        for p in pts:
                pts2.append(pos + (p - pos) * 0.9)
        v.draw_colored_polygon(pts2, body)
        # warm blush on the sun side
        v.draw_circle(pos + Vector2(r * 0.22, r * 0.3), r * 0.42,
                        Color("e8a86a").lerp(body, 0.35))
        v.draw_circle(pos + Vector2(-r * 0.24, -r * 0.05), r * 0.16,
                        Color(1, 1, 1, 0.32))
        _stem(v, pos + Vector2(0, -r * 0.78), r, 0.35)
        _leaf(v, pos + Vector2(r * 0.22, -r * 0.95), r, -0.3)


static func _lemon(v: CanvasItem, pos: Vector2, r: float) -> void:
        var body: Color = FRUITS["lemon"]["body"]
        var pts := PackedVector2Array()
        for i in 24:
                var a := TAU * float(i) / 24.0
                var nub := 1.0 + 0.14 * pow(absf(cos(a)), 8.0)
                pts.append(pos + Vector2(cos(a) * r * 1.18 * nub,
                                sin(a) * r * 0.86 * nub))
        v.draw_colored_polygon(pts, body.darkened(0.3))
        var pts2 := PackedVector2Array()
        for p in pts:
                pts2.append(pos + (p - pos) * 0.9)
        v.draw_colored_polygon(pts2, body)
        # peel texture hint + highlight
        for i in 6:
                var a := TAU * float(i) / 6.0 + 0.5
                v.draw_circle(pos + Vector2.from_angle(a) * Vector2(r * 0.7, r * 0.5),
                                r * 0.045, body.darkened(0.2))
        v.draw_circle(pos + Vector2(-r * 0.4, -r * 0.22), r * 0.2,
                        Color(1, 1, 1, 0.42))
        _leaf(v, pos + Vector2(r * 1.05, -r * 0.12), r * 0.9, -0.9)


static func _peach(v: CanvasItem, pos: Vector2, r: float) -> void:
        var body: Color = FRUITS["peach"]["body"]
        _sphere(v, pos, r, body)
        # the blush + the crease
        v.draw_circle(pos + Vector2(r * 0.26, r * 0.12), r * 0.5,
                        Color("f4685a").lerp(body, 0.45))
        v.draw_circle(pos + Vector2(r * 0.4, r * 0.28), r * 0.26,
                        Color("e8574a").lerp(body, 0.55))
        var crease := PackedVector2Array()
        for i in 8:
                var s := float(i) / 7.0
                var yy := lerpf(-r * 0.75, r * 0.85, s)
                crease.append(pos + Vector2(sin(s * PI) * r * 0.16, yy))
        v.draw_polyline(crease, body.darkened(0.28), maxf(1.8, r * 0.07), true)
        _stem(v, pos + Vector2(0, -r * 0.88), r, -0.2)
        _leaf(v, pos + Vector2(-r * 0.16, -r * 1.05), r * 1.15, -2.5)


static func _watermelon(v: CanvasItem, pos: Vector2, r: float) -> void:
        # a proud SLICE: rind, pale pith, red flesh, seeds in ranks
        var green: Color = FRUITS["watermelon"]["body"]
        var red: Color = FRUITS["watermelon"]["acc"]
        var arcs := [
                {"rr": 1.18, "col": green.darkened(0.35)},
                {"rr": 1.06, "col": green},
                {"rr": 0.94, "col": Color("f2f0d8")},
                {"rr": 0.86, "col": red.darkened(0.12)},
                {"rr": 0.78, "col": red},
        ]
        for ainfo in arcs:
                var rr: float = r * float(ainfo["rr"])
                var pts := PackedVector2Array()
                for i in 15:
                        var a := PI * float(i) / 14.0
                        pts.append(pos + Vector2(cos(a) * rr, -sin(a) * rr * 0.92))
                pts.append(pos + Vector2(0, r * 0.06))
                v.draw_colored_polygon(pts, ainfo["col"])
        # seeds
        for row in 2:
                for k in 3:
                        var a := PI * (0.3 + 0.4 * float(k)) / 2.0
                        var sp := pos + Vector2(cos(a) * r * (0.3 + 0.22 * float(row)),
                                        -sin(a) * r * (0.32 + 0.26 * float(row)) - r * 0.05)
                        v.draw_circle(sp, r * 0.055, Color("35210f"))
        v.draw_circle(pos + Vector2(-r * 0.5, -r * 0.55), r * 0.12,
                        Color(1, 1, 1, 0.3))


static func _pineapple(v: CanvasItem, pos: Vector2, r: float) -> void:
        var body: Color = FRUITS["pineapple"]["body"]
        # barrel body
        var pts := PackedVector2Array()
        for i in 22:
                var a := TAU * float(i) / 22.0
                pts.append(pos + Vector2(cos(a) * r * 0.88, sin(a) * r * 1.06))
        v.draw_colored_polygon(pts, body.darkened(0.32))
        var pts2 := PackedVector2Array()
        for p in pts:
                pts2.append(pos + (p - pos) * 0.92)
        v.draw_colored_polygon(pts2, body)
        # diamond lattice: two diagonal hatch sets + a dot in every diamond
        for i in 4:
                var yy := -r * 0.66 + float(i) * r * 0.44
                v.draw_line(pos + Vector2(-r * 0.62, yy + r * 0.3),
                                pos + Vector2(r * 0.62, yy - r * 0.14),
                                body.darkened(0.3), maxf(1.6, r * 0.055), true)
                v.draw_line(pos + Vector2(r * 0.62, yy + r * 0.3),
                                pos + Vector2(-r * 0.62, yy - r * 0.14),
                                body.darkened(0.3), maxf(1.6, r * 0.055), true)
        for ox in [-0.3, 0.3]:
                for oy in [-0.35, 0.1, 0.55]:
                        v.draw_circle(pos + Vector2(r * ox, r * oy), r * 0.05,
                                        body.darkened(0.38))
        # the crown: spiky leaves fanning up
        for k in 5:
                var a := -PI * 0.5 + (float(k) - 2.0) * 0.42
                var base := pos + Vector2(0, -r * 1.0)
                var tip2 := base + Vector2.from_angle(a) * r * (0.62 if absf(k - 2.0) > 1.0 else 0.8)
                v.draw_line(base, tip2, Color("3e8a3e"), maxf(3.0, r * 0.13), true)
                v.draw_circle(tip2, maxf(1.6, r * 0.06), Color("3e8a3e"))


## Power fruit = the current edible, smaller, wearing its AURA: a breathing
## double ring + orbiting sparks + a soft halo. The aura color IS the type
## signal (the owner: "power-ups and power-downs are in the fruit itself
## with different aura maybe?"). Permanent fruits (sprint/slog) pulse HARDER
## so they read as a bigger deal - they rewrite you forever.
static func paint_power_fruit(v: CanvasItem, power_id: String, base_fruit: String,
                pos: Vector2, r: float, t: float) -> void:
        var aura: Color = POWERS[power_id]["aura"]
        var perm := float(POWERS[power_id].get("perm", 0.0)) != 0.0
        var breathe := 1.0 + 0.06 * sin(t * 4.4)
        if perm:
                breathe *= 1.0 + 0.05 * sin(t * 9.0)
        # halo
        v.draw_circle(pos, r * 2.1 * breathe, Color(aura, 0.13))
        # double aura rings
        for k in 2:
                var rr := r * (1.45 + 0.28 * float(k)) * breathe
                var a := 0.8 - 0.28 * float(k)
                v.draw_arc(pos, rr, 0, TAU, 42,
                                Color(aura, a * (0.6 + 0.4 * sin(t * 5.0 + k))), 3.0, true)
        # orbiting sparks
        for i in 3:
                var a := t * 2.6 + TAU * float(i) / 3.0
                var sp := pos + Vector2(cos(a), sin(a)) * r * 1.75
                v.draw_circle(sp, r * 0.11, Color(aura, 0.9))
        paint_fruit(v, base_fruit, pos, r * 0.82, t * 1.4, false)
