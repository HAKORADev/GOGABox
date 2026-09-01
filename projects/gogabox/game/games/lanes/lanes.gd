extends GogaGame
## SPACE DODGE (the game the box shipped as "Geometry Flash" until the
## v0.2.3 patch renamed it - the owner's real Geometry Flash is a future
## game) — 3-lane dodge. Tap left/right thirds (or swipe) to switch.
## Speed ramps every 20s PGB-style (+10%). Coins float between obstacles.

const LANES := 3
const LANE_W := 200.0

var world: Node2D
var ship: Sprite2D
var lane := 1
var scroll_speed := 320.0
var speed_mult := 1.0
var ramp_clock := 0.0
var obstacles: Array = []      # {node, lane, y}
var coins: Array = []          # {node, y}
var spawn_clock := 0.0
var coin_clock := 0.0
var playing := true

var _ship_tex: Texture2D
var _block_tex: Texture2D
var _coin_tex: Texture2D

func _goga_setup() -> void:
	tk.tapped.connect(_on_tap)
	tk.swiped.connect(_on_swipe)
	_ship_tex = load("res://assets/games/lanes/ship.png")
	_block_tex = load("res://assets/games/lanes/block.png")
	_coin_tex = load("res://assets/ui/coin.png")
	_build()

func _build() -> void:
	var vp := get_viewport_rect().size
	world = Node2D.new()
	add_child(world)

	var bg := ColorRect.new()
	bg.color = Color("141028")
	bg.size = vp
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(bg)
	# lane guides
	for i in range(LANES + 1):
		var g := ColorRect.new()
		g.color = Color("00e5ff22")
		g.position = Vector2(_lane_x(i) - LANE_W / 2.0, 0)
		g.size = Vector2(4, vp.y)
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world.add_child(g)

	ship = Sprite2D.new()
	ship.texture = _ship_tex
	ship.position = Vector2(_lane_x(lane), vp.y - 200)
	ship.scale = Vector2.ONE * 0.9
	world.add_child(ship)

func _lane_x(i: int) -> float:
	var vp := get_viewport_rect().size
	var usable := minf(vp.x, LANE_W * 3.0)
	var left := (vp.x - usable) / 2.0
	return left + LANE_W * (float(i) + 0.5)

func _on_tap(pos: Vector2) -> void:
	if not playing:
		return
	var vp := get_viewport_rect().size
	var target := 1
	if pos.x < vp.x / 3.0:
		target = lane - 1
	elif pos.x > vp.x * 2.0 / 3.0:
		target = lane + 1
	_move(target)

func _on_swipe(dirv: Vector2i, _pos: Vector2) -> void:
	if not playing:
		return
	if dirv.x < 0:
		_move(lane - 1)
	elif dirv.x > 0:
		_move(lane + 1)

func _move(target: int) -> void:
	if target < 0 or target >= LANES or target == lane:
		return
	lane = target
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(ship, "position:x", _lane_x(lane), 0.12)
	Jukebox.sfx("swap", -8.0, 1.3)

func _goga_tick(delta: float) -> void:
	if not playing:
		return
	var vp := get_viewport_rect().size
	ramp_clock += delta
	if ramp_clock >= 8.0:
		ramp_clock = 0.0
		speed_mult += 0.06
	# dodged-score accrues with distance
	set_score(score + int(60.0 * delta * speed_mult))

	spawn_clock -= delta
	if spawn_clock <= 0.0:
		spawn_clock = maxf(0.32, 0.85 / speed_mult)
		_spawn_obstacle()
	coin_clock -= delta
	if coin_clock <= 0.0:
		coin_clock = 1.7
		_spawn_coin()

	var eff := scroll_speed * speed_mult
	for o in obstacles.duplicate():
		var n: Sprite2D = o["node"]
		n.position.y += eff * delta
		if n.position.y > vp.y + 120:
			obstacles.erase(o)
			n.queue_free()
			achievement_count("dodged", 1)
			continue
		if absf(n.position.y - ship.position.y) < 70 and int(o["lane"]) == lane:
			playing = false
			_crash()
	for c in coins.duplicate():
		var n2: Sprite2D = c["node"]
		n2.position.y += eff * delta
		if n2.position.y > vp.y + 60:
			coins.erase(c)
			n2.queue_free()
			continue
		if absf(n2.position.y - ship.position.y) < 66 and int(c["lane"]) == lane:
			coins.erase(c)
			add_run_coins(3)
			achievement_count("coins_taken", 3)
			Jukebox.sfx("coin", -6.0)
			n2.queue_free()

func _spawn_obstacle() -> void:
	var s := Sprite2D.new()
	s.texture = _block_tex
	var l := randi() % LANES
	s.position = Vector2(_lane_x(l), -120)
	s.scale = Vector2.ONE * 0.8
	s.rotation = randf() * TAU
	world.add_child(s)
	obstacles.append({"node": s, "lane": l})

func _spawn_coin() -> void:
	var s := Sprite2D.new()
	s.texture = _coin_tex
	var l := randi() % LANES
	s.position = Vector2(_lane_x(l), -60)
	s.scale = Vector2.ONE * (56.0 / 128.0)
	world.add_child(s)
	coins.append({"node": s, "lane": l})

func _crash() -> void:
	Jukebox.sfx("boom", -2.0)
	achievement_max("max_height", 0)
	check_achievements()
	var tw := create_tween()
	tw.tween_property(ship, "rotation", 1.4, 0.35)
	tw.parallel().tween_property(ship, "modulate", Color(1, 0.4, 0.4, 0.2), 0.4)
	tw.tween_callback(func(): finish_run(score))
