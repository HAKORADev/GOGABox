extends GogaGame
## Fruit Slasher — the landscape one. Swipe to slash fruit arcs, avoid bombs.
## Combos feed achievements; golden fruit = GOGACoins.

var world: Node2D
var playing := true
var clock := 0.0
var spawn_clock := 0.6
var pieces: Array = []       # {node, kind, v, spin}
var trail: Line2D
var trail_pts: Array = []
var combo := 0
var combo_clock := 0.0
var slashed_total := 0

var _fruit_texs: Array = []
var _gold_tex: Texture2D
var _bomb_tex: Texture2D

func _goga_setup() -> void:
	for i in 5:
		_fruit_texs.append(load("res://assets/games/slasher/fruit_%d.png" % i))
	_gold_tex = load("res://assets/games/slasher/fruit_gold.png")
	_bomb_tex = load("res://assets/games/slasher/bomb.png")
	_build()
	tk.dragged.connect(_on_drag)
	tk.press_started.connect(func(_p): pass)

func _build() -> void:
	var vp := get_viewport_rect().size
	world = Node2D.new()
	add_child(world)
	var bg := ColorRect.new()
	bg.color = Color("2a1c10")
	bg.size = vp
	bg.z_index = -10
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(bg)
	var glow := ColorRect.new()
	glow.color = Color("4a2f18")
	glow.position = Vector2(0, vp.y * 0.62)
	glow.size = Vector2(vp.x, vp.y * 0.38)
	glow.z_index = -9
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(glow)

	trail = Line2D.new()
	trail.width = 10
	trail.default_color = Color(1, 1, 1, 0.9)
	trail.z_index = 30
	world.add_child(trail)

func _launch(kind: String) -> void:
	var vp := get_viewport_rect().size
	var s := Sprite2D.new()
	if kind == "bomb":
		s.texture = _bomb_tex
	elif kind == "gold":
		s.texture = _gold_tex
	else:
		s.texture = _fruit_texs[randi() % _fruit_texs.size()]
	var x := randf_range(vp.x * 0.15, vp.x * 0.85)
	s.position = Vector2(x, vp.y + 60)
	s.scale = Vector2.ONE * 0.75
	world.add_child(s)
	var upward := randf_range(-1450.0, -1250.0)
	pieces.append({
		"node": s, "kind": kind, "v": Vector2(randf_range(-120, 120), upward),
		"spin": randf_range(-3.0, 3.0), "sliced": false,
	})

func _goga_tick(delta: float) -> void:
	if not playing:
		return
	var vp := get_viewport_rect().size
	clock += delta
	spawn_clock -= delta
	if spawn_clock <= 0.0:
		spawn_clock = maxf(0.55, 1.25 - clock * 0.01)
		var burst := 1 + (randi() % 3 if clock > 20.0 else 0)
		for i in burst:
			var r := randf()
			_launch("bomb" if r < 0.16 else ("gold" if r > 0.93 else "fruit"))
		if burst > 1:
			Jukebox.sfx("sparkle", -12.0)

	# combo timer
	if combo > 0:
		combo_clock -= delta
		if combo_clock <= 0.0:
			combo = 0

	for p in pieces.duplicate():
		var n: Sprite2D = p["node"]
		var v: Vector2 = p["v"]
		v.y += 1500.0 * delta
		p["v"] = v
		n.position += v * delta
		n.rotation += float(p["spin"]) * delta
		if n.position.y > vp.y + 90:
			if String(p["kind"]) == "fruit" and not bool(p["sliced"]):
				pass  # missed fruit: no penalty in endless mode
			pieces.erase(p)
			n.queue_free()

	# fade trail
	for i in range(trail_pts.size() - 1, -1, -1):
		trail_pts[i] += Vector2(0, 0)
	trail.points = PackedVector2Array(trail_pts)
	if trail_pts.size() > 0:
		trail_pts.pop_front()

func _on_drag(from: Vector2, to: Vector2) -> void:
	if not playing:
		return
	trail_pts.append(to)
	if trail_pts.size() > 22:
		trail_pts.pop_front()
	# check hits along the recent segment
	var seg := to - from
	if seg.length() < 8.0:
		return
	var hit_combo := 0
	for p in pieces.duplicate():
		var n: Sprite2D = p["node"]
		if bool(p["sliced"]):
			continue
		var d := _point_segment_dist(n.position, from, to)
		if d < 62.0:
			p["sliced"] = true
			pieces.erase(p)
			match String(p["kind"]):
				"fruit":
					combo += 1
					combo_clock = 0.9
					hit_combo += 1
					slashed_total += 1
					achievement_count("slashed", 1)
					add_score(10 * maxi(1, combo))
					_splash(n.position, Color("ffb020"))
					Jukebox.sfx("pop", -6.0, 1.0 + 0.04 * combo)
				"gold":
					add_run_coins(10)
					achievement_count("coins_taken", 10)
					add_score(25)
					_splash(n.position, Color("ffc93c"))
					Jukebox.sfx("coin", -2.0)
				"bomb":
					_bomb_hit()
					return
	if hit_combo >= 2:
		achievement_max("best_combo", combo)
		if combo >= 5:
			achievement_max("best_combo", combo)

func _point_segment_dist(pt: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((pt - a).dot(ab) / maxf(0.001, ab.length_squared()), 0.0, 1.0)
	return pt.distance_to(a + ab * t)

func _splash(at: Vector2, col: Color) -> void:
	for i in 8:
		var d := ColorRect.new()
		d.color = col
		d.size = Vector2(8, 8)
		d.position = at
		d.z_index = 20
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world.add_child(d)
		var dir := Vector2.from_angle(randf() * TAU) * randf_range(60, 220)
		var tw := d.create_tween().set_parallel(true)
		tw.tween_property(d, "position", at + dir + Vector2(0, 300), 0.5) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(d, "modulate:a", 0.0, 0.5)
		tw.chain().tween_callback(d.queue_free)

func _bomb_hit() -> void:
	playing = false
	Jukebox.sfx("boom", 0.0)
	achievement_max("best_combo", combo)
	check_achievements()
	var tw := create_tween()
	tw.tween_property(world, "modulate", Color(1, 0.4, 0.4), 0.12)
	tw.tween_property(world, "modulate", Color.WHITE, 0.2)
	tw.tween_callback(func(): finish_run(score))
