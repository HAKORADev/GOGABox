extends CharacterBody2D
## The jelly ball: constant bounce, tilt/touch steering, screen wrap,
## squash&stretch + jelly shader wobble.

signal landed(kind: String)   # "grass" | "spring" | "dirt" (after bounce applied)

const GRAVITY := 2400.0
const JUMP_V := -1250.0
const SPRING_V := -2050.0
const MOVE_ACC := 5200.0
const MOVE_MAX := 800.0

var control_enabled := true
var _touch_dir := 0.0
var _wobble := 0.0
var _squash := 0.0
var _sprite: Sprite2D
var _mat: ShaderMaterial

func _ready() -> void:
	var prefix: String = GameState.skin()["prefix"]
	var tint: Color = GameState.skin()["tint"]
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/sprites/%s_stand.png" % prefix)
	_sprite.modulate = tint
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://game/jelly.gdshader")
	_sprite.material = _mat
	add_child(_sprite)

	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 24.0
	capsule.height = 64.0
	shape.shape = capsule
	add_child(shape)

	GameState.skin_changed.connect(_on_skin_changed)

func _on_skin_changed(_id: String) -> void:
	var sk: Dictionary = GameState.skin()
	_sprite.texture = load("res://assets/sprites/%s_stand.png" % sk["prefix"])
	_sprite.modulate = sk["tint"]

func set_touch_dir(dir: float) -> void:
	_touch_dir = dir

func bounce_stretch(amount: float) -> void:
	_squash = amount
	_wobble = 1.0

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta

	var dir := 0.0
	if control_enabled:
		dir = Input.get_axis("move_left", "move_right")
		if absf(_touch_dir) > 0.0:
			dir = clampf(_touch_dir, -1.0, 1.0)
	velocity.x = move_toward(velocity.x, dir * MOVE_MAX, MOVE_ACC * delta)
	if dir == 0.0:
		velocity.x = move_toward(velocity.x, 0.0, MOVE_ACC * 0.6 * delta)

	move_and_slide()

	# bounce off one-way floors (platform / spring)
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col.get_normal().y < -0.6:
			var obj := col.get_collider()
			var kind := "grass"
			if obj is StaticBody2D and obj.get_parent() is JellyPlatform:
				var plat := obj.get_parent() as JellyPlatform
				if plat.spring_body != null and obj == plat.spring_body:
					kind = "spring"
				elif plat.type == "dirt":
					kind = "dirt"
					plat.start_crumble()
			velocity.y = SPRING_V if kind == "spring" else JUMP_V
			_squash = 1.0 if kind == "spring" else 0.65
			_wobble = 1.0
			landed.emit(kind)
			break

	# screen wrap
	if global_position.x < -60.0:
		global_position.x = 780.0
	elif global_position.x > 780.0:
		global_position.x = -60.0

	# jelly decay
	_wobble = maxf(_wobble - delta * 3.2, 0.0)
	_squash = maxf(_squash - delta * 5.0, 0.0)
	if _mat != null:
		_mat.set_shader_parameter("wobble", _wobble)
		_mat.set_shader_parameter("squash", _squash)

	# sprite tilt from horizontal speed
	if _sprite != null:
		_sprite.rotation = clampf(velocity.x / MOVE_MAX, -1.0, 1.0) * 0.22
