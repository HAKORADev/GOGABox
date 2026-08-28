extends Node2D
## Jelly Jump orchestrator: sky/parallax, world generation, run lifecycle,
## ads-driven revive & double-coins, interstitial pacing.

const W := 720.0
const H := 1280.0
const METER := 10.0            # pixels per meter of score
const HILLS_PARALLAX := 0.35

const JellyPlayer := preload("res://game/player.gd")

var player: CharacterBody2D
var camera: Camera2D
var world: Node2D
var hills: Sprite2D
var sky: ColorRect
var sky_mat: ShaderMaterial
var clouds: Node2D
var ui: CanvasLayer

var state := "menu"            # menu | playing | gameover
var score := 0
var coins_run := 0
var gen_y := 0.0
var revived := false
var was_new_best := false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_build_backdrop()
	_build_world()
	_build_ui()
	_setup_input()
	_to_menu()

# ------------------------------------------------------------ construction

func _build_backdrop() -> void:
	sky = ColorRect.new()
	sky.size = Vector2(W, H)
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = load("res://game/sky.gdshader")
	sky.material = sky_mat
	add_child(sky)

	hills = Sprite2D.new()
	hills.texture = load("res://assets/sprites/bg_hills.png")
	hills.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	hills.region_enabled = true
	hills.region_rect = Rect2(0, 0, 1440, 256)
	hills.scale = Vector2(2.2, 2.2)
	hills.position = Vector2(W / 2.0, 600)
	add_child(hills)

func _build_world() -> void:
	world = Node2D.new()
	add_child(world)

	camera = Camera2D.new()
	camera.position = Vector2(W / 2.0, 0)
	add_child(camera)
	camera.make_current()

	clouds = load("res://game/cloud_painter.gd").new()
	add_child(clouds)

	player = CharacterBody2D.new()
	player.set_script(JellyPlayer)
	player.position = Vector2(W / 2.0, -200)
	world.add_child(player)
	player.landed.connect(_on_landed)

func _build_ui() -> void:
	ui = load("res://game/ui.gd").new()
	add_child(ui)
	ui.play_pressed.connect(_start_run)
	ui.retry_pressed.connect(_on_retry)
	ui.home_pressed.connect(_on_home)
	ui.revive_pressed.connect(_on_revive)
	ui.double_pressed.connect(_on_double)

func _setup_input() -> void:
	for action in [["move_left", [KEY_LEFT, KEY_A]], ["move_right", [KEY_RIGHT, KEY_D]]]:
		if not InputMap.has_action(action[0]):
			InputMap.add_action(action[0])
			for key in action[1]:
				var ev := InputEventKey.new()
				ev.physical_keycode = key
				InputMap.action_add_event(action[0], ev)

# ------------------------------------------------------------ run lifecycle

func _to_menu() -> void:
	state = "menu"
	player.control_enabled = false
	player.position = Vector2(W / 2.0, -260)
	player.velocity = Vector2.ZERO
	_clear_world()
	_seed_start_platform()
	ui.show_menu()

func _clear_world() -> void:
	var doomed: Array = []
	for c in world.get_children():
		if c != player:
			doomed.append(c)
	for c in doomed:
		c.free()
	gen_y = 0.0

func _seed_start_platform() -> void:
	var plat := JellyPlatform.make("grass", Vector2(W / 2.0, -60), 4, false, null)
	world.add_child(plat)
	gen_y = -60.0

func _start_run() -> void:
	state = "playing"
	score = 0
	coins_run = 0
	revived = false
	was_new_best = false
	_clear_world()
	_seed_start_platform()
	player.position = Vector2(W / 2.0, -200)
	player.velocity = Vector2.ZERO
	player.control_enabled = true
	camera.position.y = 0.0
	ui.show_hud()

func _on_retry() -> void:
	if Ads.desktop_sim:
		_start_run()
	else:
		Ads.maybe_interstitial(func(_shown: bool): _start_run())

func _on_home() -> void:
	if Ads.desktop_sim:
		_to_menu()
	else:
		Ads.maybe_interstitial(func(_shown: bool): _to_menu())

func _game_over() -> void:
	if state != "playing":
		return
	state = "gameover"
	player.control_enabled = false
	Sfx.play("gameover")
	GameState.add_coins(coins_run)
	Ads.register_run()
	was_new_best = GameState.submit_score(score)
	ui.show_game_over(score, coins_run, was_new_best, not revived)

func _on_revive() -> void:
	Ads.show_rewarded(func(ok: bool):
		if not ok or state != "gameover":
			return
		revived = true
		# drop the player on a fresh platform near where they died
		var y := camera.position.y + H * 0.25
		var plat := JellyPlatform.make("grass", Vector2(W / 2.0, y), 4, false, null)
		world.add_child(plat)
		gen_y = minf(gen_y, y)
		player.position = Vector2(W / 2.0, y - 220)
		player.velocity = Vector2.ZERO
		player.control_enabled = true
		state = "playing"
		ui.show_hud())

func _on_double() -> void:
	Ads.show_rewarded(func(ok: bool):
		if not ok or state != "gameover":
			return
		GameState.add_coins(coins_run)
		coins_run *= 2
		Sfx.play("buy")
		ui.show_game_over(score, coins_run, was_new_best, false))

# ------------------------------------------------------------ world generation

func _on_landed(kind: String) -> void:
	match kind:
		"spring": Sfx.play("spring")
		"dirt": Sfx.play("crumble")
		_: Sfx.play("jump", -4.0, _rng.randf_range(0.94, 1.06))

func _meters_at(y: float) -> int:
	return int(-y / METER)

func _spawn_next(from_y: float) -> float:
	var meters := _meters_at(from_y)
	var gap_min := 140.0 + minf(meters * 0.03, 130.0)
	var gap_max := minf(250.0 + minf(meters * 0.02, 60.0), 300.0)
	var y := from_y - _rng.randf_range(gap_min, gap_max)

	var r := _rng.randf()
	var type := "grass"
	if meters > 350 and r < 0.18:
		type = "dirt"
	elif meters > 120 and r < 0.36:
		type = "stone"
	var tiles := _rng.randi_range(2, 4)
	var half := tiles * 35.0
	var margin := half + 50.0
	var x := _rng.randf_range(margin, W - margin)

	var spring := type == "grass" and meters > 60 and _rng.randf() < 0.08
	var plat := JellyPlatform.make(type, Vector2(x, y), tiles, spring,
		load("res://assets/sprites/spring_up.png"))
	if type == "stone":
		var amp: float = minf(_rng.randf_range(60.0, 160.0), minf(x - margin, W - margin - x))
		plat.set_motion(amp, _rng.randf_range(1.2, 2.2), _rng.randf_range(0, TAU))
	world.add_child(plat)

	if _rng.randf() < 0.45:
		var n := _rng.randi_range(3, 4)
		for i in n:
			var coin := Area2D.new()
			var cs := CollisionShape2D.new()
			var circle := CircleShape2D.new()
			circle.radius = 30.0
			cs.shape = circle
			coin.add_child(cs)
			var s := Sprite2D.new()
			s.texture = load("res://assets/sprites/coin.png")
			coin.add_child(s)
			var cx := clampf(x + (i - (n - 1) / 2.0) * 74.0, 40.0, W - 40.0)
			coin.position = Vector2(cx, y - 110.0 + absf(i - (n - 1) / 2.0) * 26.0)
			coin.body_entered.connect(_on_coin_body.bind(coin))
			coin.set_meta("coin", true)
			world.add_child(coin)
	return y

func _on_coin_body(body: Node2D, coin: Area2D) -> void:
	if body != player:
		return
	if coin.has_meta("collected"):
		return
	coin.set_meta("collected", true)
	coins_run += 1
	Sfx.play("coin", -3.0, _rng.randf_range(0.96, 1.05))
	ui.refresh_coins(GameState.coins() + coins_run)
	coin.queue_free()

# ------------------------------------------------------------ per-frame

func _process(delta: float) -> void:
	if state == "playing":
		# camera follows only upward
		var target := player.position.y - 260.0
		if target < camera.position.y:
			camera.position.y = target
		score = maxi(score, int(-camera.position.y / METER))
		ui.set_score(score)

		# keep generating above the camera
		while gen_y > camera.position.y - H * 1.6:
			gen_y = _spawn_next(gen_y)

		# fell off the bottom
		if player.position.y > camera.position.y + H * 0.75:
			_game_over()

		# sky shifts toward night as you climb
		sky_mat.set_shader_parameter("altitude", float(score))

	# parallax layers
	hills.position.y = 600.0 + camera.position.y * (1.0 - HILLS_PARALLAX)
	hills.modulate.a = clampf(1.0 - (-camera.position.y) / 3000.0, 0.0, 1.0)
	hills.position.x = W / 2.0
	sky.position = camera.position - Vector2(W / 2.0, H / 2.0)
	clouds.update_clouds(camera.position.y, delta)

func _unhandled_input(event: InputEvent) -> void:
	if state != "playing":
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if not t.pressed:
			player.set_touch_dir(0.0)
		else:
			player.set_touch_dir(-1.0 if t.position.x < 360.0 else 1.0)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		player.set_touch_dir(-1.0 if d.position.x < 360.0 else 1.0)
