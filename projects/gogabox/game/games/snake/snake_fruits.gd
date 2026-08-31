class_name SnakeFruits
extends RefCounted
## Snake v0.1.9 - the catalog side of the war: fruits, power fruits with
## auras, and the enemy color set. Every fruit is HAND-PAINTED vector art in
## the game's own draw language (same family as the v0.1.8 apple), so the
## whole game stays one visual voice. Eat particles always use the eaten
## thing's colors (owner fix: the blue-burst-on-apple bug).

## ------------------------------------------------------------- fruits
## price 0 = the default edible (always there). The rest live in the shop.
## Every fruit carries: body color, accent color, painter id.
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
## leaves the field; dur = active seconds once eaten; good = celebration vs
## dread. eater needs the ENEMIES PACK owned.
const POWERS := {
        "slower": {"name": "SLOWER",  "weight": 22.0, "cd": Vector2(8.0, 14.0),
                "dur": 12.0, "good": true,  "aura": Color("7a9ad8"), "needs": ""},
        "faster": {"name": "FASTER",  "weight": 18.0, "cd": Vector2(10.0, 18.0),
                "dur": 8.0,  "good": true,  "aura": Color("ff8a3a"), "needs": ""},
        "ghost":  {"name": "GHOST",   "weight": 14.0, "cd": Vector2(12.0, 20.0),
                "dur": 7.0,  "good": true,  "aura": Color("b8a8e8"), "needs": ""},
        "magnet": {"name": "MAGNET",  "weight": 16.0, "cd": Vector2(10.0, 16.0),
                "dur": 10.0, "good": true,  "aura": Color("ffc93c"), "needs": ""},
        "golden": {"name": "GOLDEN",  "weight": 16.0, "cd": Vector2(9.0, 15.0),
                "dur": 10.0, "good": true,  "aura": Color("ffe86a"), "needs": ""},
        "wither": {"name": "WITHER",  "weight": 14.0, "cd": Vector2(10.0, 18.0),
                "dur": 8.0,  "good": false, "aura": Color("8ac44a"), "needs": ""},
        "eater":  {"name": "EATER",   "weight": 12.0, "cd": Vector2(14.0, 22.0),
                "dur": 10.0, "good": true,  "aura": Color("e8402f"), "needs": "pack"},
}

## ------------------------------------------------------------- enemies
## Enemy #0 is the FREE opponent - the owner: "make the opponent snake green".
## The pack adds nine more; every enemy on the field wears its own color.
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
## draws around `pos` - no state, pure strokes, the same cream-field voice.

static func paint_fruit(v: CanvasItem, id: String, pos: Vector2, r: float,
                t: float) -> void:
        var wob := 1.0 + 0.035 * sin(t * 3.1)
        r *= wob
        match id:
                "banana": _banana(v, pos, r)
                "cherry": _cherry(v, pos, r)
                "grapes": _grapes(v, pos, r)
                "strawberry": _strawberry(v, pos, r)
                "watermelon": _watermelon(v, pos, r)
                "pear": _pear(v, pos, r)
                "lemon": _lemon(v, pos, r)
                "orange": _sphere_fruit(v, pos, r, FRUITS["orange"]["body"],
                                Color("ff9838").darkened(0.25), true)
                "peach": _peach(v, pos, r)
                "pineapple": _pineapple(v, pos, r)
                _: _apple(v, pos, r)


static func _leaf(v: CanvasItem, top: Vector2, r: float, col: Color) -> void:
        v.draw_line(top, top + Vector2(2, -r * 0.3), Color("8a5a14"), maxf(2.0, r * 0.12), true)
        var pts := PackedVector2Array()
        var lc := top + Vector2(r * 0.42, -r * 0.42)
        for i in 14:
                var a := TAU * float(i) / 14.0
                pts.append(lc + Vector2(cos(a) * r * 0.34, sin(a) * r * 0.2))
        v.draw_colored_polygon(pts, col)


static func _shine(v: CanvasItem, pos: Vector2, r: float) -> void:
        v.draw_circle(pos + Vector2(-r * 0.34, -r * 0.36), r * 0.2,
                        Color(1, 1, 1, 0.7))


static func _sphere_fruit(v: CanvasItem, pos: Vector2, r: float, body: Color,
                rim: Color, leafy: bool) -> void:
        v.draw_circle(pos, r + r * 0.1, rim)
        v.draw_circle(pos, r, body)
        _shine(v, pos, r)
        if leafy:
                _leaf(v, pos + Vector2(0, -r * 0.95), r, Color("58c470"))


static func _apple(v: CanvasItem, pos: Vector2, r: float) -> void:
        _sphere_fruit(v, pos, r, FRUITS["apple"]["body"],
                        FRUITS["apple"]["body"].darkened(0.3), true)


static func _banana(v: CanvasItem, pos: Vector2, r: float) -> void:
        var body: Color = FRUITS["banana"]["body"]
        var pts := PackedVector2Array()
        var pts2 := PackedVector2Array()
        for i in 16:
                var a := PI * (0.15 + 0.7 * float(i) / 15.0)
                var dir := Vector2(cos(a), -sin(a))
                pts.append(pos + dir * r * 1.25 - Vector2(0, r * 0.1))
                pts2.append(pos + dir * r * 0.72 - Vector2(0, r * 0.1))
        var poly := pts
        for i in range(pts2.size() - 1, -1, -1):
                poly.append(pts2[i])
        v.draw_colored_polygon(poly, body)
        v.draw_polyline(pts, body.darkened(0.3), maxf(2.0, r * 0.08), true)
        var tip_a: Vector2 = pts[0]
        var tip_b: Vector2 = pts[pts.size() - 1]
        v.draw_circle(tip_a, r * 0.12, Color("8a6a20"))
        v.draw_circle(tip_b, r * 0.12, Color("8a6a20"))


static func _cherry(v: CanvasItem, pos: Vector2, r: float) -> void:
        var body: Color = FRUITS["cherry"]["body"]
        var off := Vector2(r * 0.55, r * 0.35)
        for s in [-1.0, 1.0]:
                var c := pos + off * Vector2(s, 1.0)
                v.draw_circle(c, r * 0.62, body.darkened(0.25))
                v.draw_circle(c, r * 0.55, body)
                _shine(v, c, r * 0.55)
        v.draw_line(pos + Vector2(-r * 0.5, -r * 0.2), pos + Vector2(0, -r * 1.15),
                        Color("58c470"), maxf(2.0, r * 0.1), true)
        v.draw_line(pos + Vector2(r * 0.5, -r * 0.2), pos + Vector2(0, -r * 1.15),
                        Color("58c470"), maxf(2.0, r * 0.1), true)
        _leaf(v, pos + Vector2(0, -r * 1.15), r * 0.8, Color("58c470"))


static func _grapes(v: CanvasItem, pos: Vector2, r: float) -> void:
        var body: Color = FRUITS["grapes"]["body"]
        var gr := r * 0.42
        var offs := [Vector2(-0.5, 0.2), Vector2(0.5, 0.2), Vector2(0, 0.55),
                        Vector2(-0.25, 0.85), Vector2(0.25, 0.85), Vector2(0, 0.2)]
        for o in offs:
                var c: Vector2 = pos + (o as Vector2) * r * 1.15
                v.draw_circle(c, gr, body.darkened(0.22))
                v.draw_circle(c, gr * 0.86, body)
        _shine(v, pos + Vector2(-0.5, 0.2) * r * 1.15, gr * 0.86)
        _leaf(v, pos + Vector2(0, -r * 0.35), r, Color("58c470"))


static func _strawberry(v: CanvasItem, pos: Vector2, r: float) -> void:
        var body: Color = FRUITS["strawberry"]["body"]
        var pts := PackedVector2Array()
        for i in 20:
                var a := TAU * float(i) / 20.0
                var rr := r * (1.0 - 0.28 * maxf(0.0, sin(a)))
                pts.append(pos + Vector2(cos(a) * rr * 0.85, sin(a) * rr * 1.05))
        v.draw_colored_polygon(pts, body.darkened(0.2))
        v.draw_colored_polygon(pts, body)
        for i in 8:
                var a := TAU * float(i) / 8.0 + 0.4
                var sp := pos + Vector2(cos(a) * r * 0.4, sin(a) * r * 0.55)
                v.draw_circle(sp, r * 0.05, Color("ffe8b0"))
        var cap := PackedVector2Array()
        for i in 10:
                var a := PI + PI * float(i) / 9.0
                cap.append(pos + Vector2(0, -r * 0.55)
                                + Vector2(cos(a), -absf(sin(a)) * 0.8) * r * 0.5)
        v.draw_colored_polygon(cap, Color("58c470"))
        _leaf(v, pos + Vector2(0, -r * 1.0), r * 0.6, Color("58c470"))


static func _pear(v: CanvasItem, pos: Vector2, r: float) -> void:
        var body: Color = FRUITS["pear"]["body"]
        var pts := PackedVector2Array()
        for i in 22:
                var a := TAU * float(i) / 22.0
                var sy := sin(a)
                var rr := r * (0.78 + 0.3 * clampf(-sy + 0.4, 0.0, 1.0))
                pts.append(pos + Vector2(cos(a) * rr * 0.9, sy * rr * 1.1))
        v.draw_colored_polygon(pts, body.darkened(0.22))
        v.draw_colored_polygon(pts, body)
        _shine(v, pos + Vector2(-r * 0.2, -r * 0.45), r * 0.5)
        _leaf(v, pos + Vector2(0, -r * 1.05), r * 0.7, Color("58c470"))


static func _lemon(v: CanvasItem, pos: Vector2, r: float) -> void:
        var body: Color = FRUITS["lemon"]["body"]
        var pts := PackedVector2Array()
        for i in 22:
                var a := TAU * float(i) / 22.0
                var rr := r * (0.82 + 0.2 * pow(absf(cos(a)), 3.0))
                pts.append(pos + Vector2(cos(a) * rr * 1.2, sin(a) * rr * 0.85))
        v.draw_colored_polygon(pts, body.darkened(0.2))
        v.draw_colored_polygon(pts, body)
        _shine(v, pos + Vector2(-r * 0.35, -r * 0.25), r * 0.4)


static func _peach(v: CanvasItem, pos: Vector2, r: float) -> void:
        var body: Color = FRUITS["peach"]["body"]
        v.draw_circle(pos, r + r * 0.1, body.darkened(0.25))
        v.draw_circle(pos, r, body)
        v.draw_circle(pos + Vector2(r * 0.3, r * 0.2), r * 0.55,
                        Color("e8632a").lerp(body, 0.4))
        v.draw_line(pos + Vector2(0, -r * 0.2), pos + Vector2(0, r * 0.9),
                        body.darkened(0.3), maxf(2.0, r * 0.06), true)
        _shine(v, pos, r)
        _leaf(v, pos + Vector2(0, -r * 0.95), r, Color("58c470"))


static func _watermelon(v: CanvasItem, pos: Vector2, r: float) -> void:
        var green: Color = FRUITS["watermelon"]["body"]
        var red: Color = FRUITS["watermelon"]["acc"]
        var pts := PackedVector2Array()
        for i in 15:
                var a := PI * float(i) / 14.0
                pts.append(pos + Vector2(cos(a) * r * 1.15, sin(a) * r * 1.15))
        pts.append(pos)
        v.draw_colored_polygon(pts, green.darkened(0.2))
        var inner := PackedVector2Array()
        for i in 15:
                var a := PI * float(i) / 14.0
                inner.append(pos + Vector2(cos(a) * r * 0.98, sin(a) * r * 0.98))
        inner.append(pos)
        v.draw_colored_polygon(inner, red)
        for i in 5:
                var a := PI * (0.2 + 0.6 * float(i) / 4.0)
                var sp := pos + Vector2(cos(a) * r * 0.6, sin(a) * r * 0.55)
                v.draw_circle(sp, r * 0.07, Color("35210f"))
        _shine(v, pos + Vector2(-r * 0.3, -r * 0.5), r * 0.35)


static func _pineapple(v: CanvasItem, pos: Vector2, r: float) -> void:
        var body: Color = FRUITS["pineapple"]["body"]
        var pts := PackedVector2Array()
        for i in 18:
                var a := TAU * float(i) / 18.0
                pts.append(pos + Vector2(cos(a) * r * 0.82, sin(a) * r * 1.08))
        v.draw_colored_polygon(pts, body.darkened(0.25))
        v.draw_colored_polygon(pts, body)
        for i in 4:
                var yy := -r * 0.6 + i * r * 0.4
                v.draw_line(pos + Vector2(-r * 0.6, yy + r * 0.3),
                                pos + Vector2(r * 0.6, yy - r * 0.1),
                                body.darkened(0.3), maxf(1.5, r * 0.05), true)
                v.draw_line(pos + Vector2(r * 0.6, yy + r * 0.3),
                                pos + Vector2(-r * 0.6, yy - r * 0.1),
                                body.darkened(0.3), maxf(1.5, r * 0.05), true)
        for s in [-1.0, 0.0, 1.0]:
                var base := pos + Vector2(s * r * 0.3, -r * 1.0)
                v.draw_line(base, base + Vector2(s * r * 0.35, -r * 0.5),
                                Color("58c470"), maxf(3.0, r * 0.14), true)


## Power fruit = the current edible, smaller, wearing its AURA: a breathing
## double ring + orbiting sparks + a soft halo. The aura color IS the type
## signal (the owner: "power-ups and power-downs are in the fruit itself with
## different aura maybe?").
static func paint_power_fruit(v: CanvasItem, power_id: String, base_fruit: String,
                pos: Vector2, r: float, t: float) -> void:
        var aura: Color = POWERS[power_id]["aura"]
        var breathe := 1.0 + 0.06 * sin(t * 4.4)
        # halo
        v.draw_circle(pos, r * 2.1 * breathe, Color(aura, 0.13))
        # double aura rings
        for k in 2:
                var rr := r * (1.45 + 0.28 * float(k)) * breathe
                var a := 0.8 - 0.28 * float(k)
                v.draw_arc(pos, rr, 0, TAU, 42, Color(aura, a * (0.6 + 0.4 * sin(t * 5.0 + k))), 3.0, true)
        # orbiting sparks
        for i in 3:
                var a := t * 2.6 + TAU * float(i) / 3.0
                var sp := pos + Vector2(cos(a), sin(a)) * r * 1.75
                v.draw_circle(sp, r * 0.11, Color(aura, 0.9))
        paint_fruit(v, base_fruit, pos, r * 0.82, t * 1.4)
