extends GogaGame
## Pong Rally — endless survival rally vs a ramping AI. Drag anywhere to move
## your paddle (bottom). Every return = +1 score. Ball never stops speeding up.

var world: Node2D
var ball: Sprite2D
var player: Sprite2D
var enemy: Sprite2D
var ball_v := Vector2(220, -260)
var base_speed := 300.0
var playing := true
var rally := 0
var ai_miss_timer := 0.0
var ai_wobble := 0.0

var _ball_tex: Texture2D
var _pad_tex: Texture2D

func _goga_setup() -> void:
	_ball_tex = load("res://assets/games/rally/ball.png")
	_pad_tex = load("res://assets/games/rally/paddle.png")
	_build()
	tk.dragged.connect(_on_drag)
	tk.press_started.connect(func(_p): pass)
	set_hud_score_prefix("RALLY")
	_score_label_ref().text = "0"

func _build() -> void:
	var vp := get_viewport_rect().size
	world = Node2D.new()
	add_child(world)
	var bg := ColorRect.new()
	bg.color = Color("1a1030")
	bg.size = vp
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(bg)
	# court lines
	for i in 9:
		var seg := ColorRect.new()
		seg.color = Color(1, 1, 1, 0.10)
		seg.position = Vector2(vp.x / 2.0 - 3, 40 + i * (vp.y - 80) / 9.0)
		seg.size = Vector2(6, (vp.y - 80) / 18.0)
		seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world.add_child(seg)

	enemy = Sprite2D.new()
	enemy.texture = _pad_tex
	enemy.position = Vector2(vp.x / 2.0, 70)
	world.add_child(enemy)
	player = Sprite2D.new()
	player.texture = _pad_tex
	player.position = Vector2(vp.x / 2.0, vp.y - 110)
	world.add_child(player)

	ball = Sprite2D.new()
	ball.texture = _ball_tex
	ball.position = Vector2(vp.x / 2.0, vp.y / 2.0)
	world.add_child(ball)
	_serve(Vector2(0.4 if randf() < 0.5 else -0.4, 1.0))

func _serve(dirv: Vector2) -> void:
	var vp := get_viewport_rect().size
	ball.position = Vector2(vp.x / 2.0, vp.y / 2.0)
	base_speed = 300.0
	ball_v = dirv.normalized() * base_speed

func _on_drag(_from: Vector2, to: Vector2) -> void:
	if not playing:
		return
	var vp := get_viewport_rect().size
	player.position.x = clampf(player.position.x + to.x - _from.x, 70, vp.x - 70)

func _goga_tick(delta: float) -> void:
	if not playing:
		return
	var vp := get_viewport_rect().size
	base_speed += 6.0 * delta          # the ramp: this is the whole game
	ball_v = ball_v.normalized() * base_speed
	ball.position += ball_v * delta

	# walls
	if ball.position.x < 24 or ball.position.x > vp.x - 24:
		ball_v.x = -ball_v.x
		ball.position.x = clampf(ball.position.x, 24, vp.x - 24)
		Jukebox.sfx("swap", -14.0, 1.6)

	# AI paddle: tracks with reaction error that shrinks as rally grows
	ai_wobble += delta
	var err := sin(ai_wobble * 2.1) * maxf(30.0, 190.0 - float(rally) * 9.0)
	var target_x := ball.position.x + err
	enemy.position.x = lerpf(enemy.position.x, clampf(target_x, 70, vp.x - 70), 1.0 - pow(0.0018, delta))

	# player paddle bounce (top side of paddle)
	if ball_v.y > 0 and ball.position.y > player.position.y - 26 \
			and ball.position.y < player.position.y + 40 \
			and absf(ball.position.x - player.position.x) < 96:
		ball_v.y = -absf(ball_v.y)
		ball_v.x += (ball.position.x - player.position.x) * 2.4
		rally += 1
		set_score(score + 1)
		achievement_max("max_rally", rally)
		Jukebox.sfx("pop", -6.0, 1.0 + 0.015 * mini(30, rally))

	# enemy paddle bounce
	if ball_v.y < 0 and ball.position.y < enemy.position.y + 26 \
			and ball.position.y > enemy.position.y - 40 \
			and absf(ball.position.x - enemy.position.x) < 96:
		ball_v.y = absf(ball_v.y)
		ball_v.x += (ball.position.x - enemy.position.x) * 1.6
		Jukebox.sfx("pop", -10.0, 0.8)

	# miss (below player)
	if ball.position.y > vp.y + 30:
		playing = false
		Jukebox.sfx("boom", -4.0)
		check_achievements()
		var tw := create_tween()
		tw.tween_property(player, "modulate", Color(1, 0.5, 0.5), 0.25)
		tw.tween_callback(func(): finish_run(score))
