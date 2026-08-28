extends Node2D
## One platform pad: 3 sprites (left/mid/right) + one-way StaticBody2D.
## Types: grass = static, stone = moves horizontally, dirt = crumbles on land.

class_name JellyPlatform

const TILE := 70.0
const VIS_H := 40.0   # visible height of the half-tiles

var type := "grass"
var width_tiles := 3
var body: StaticBody2D
var _origin_x := 0.0
var _amp := 0.0
var _speed := 1.0
var _phase := 0.0
var _crumbling := false
var _crumble_t := 0.0
var spring_body: StaticBody2D = null

static func make(p_type: String, pos: Vector2, tiles: int, with_spring: bool, spring_tex: Texture2D) -> JellyPlatform:
	var p := JellyPlatform.new()
	p.type = p_type
	p.width_tiles = tiles
	p.position = pos
	p._origin_x = pos.x
	var prefix := "plat_" + p_type + "_"
	for i in tiles:
		var s := Sprite2D.new()
		var part := "left" if i == 0 else ("right" if i == tiles - 1 else "mid")
		s.texture = load("res://assets/sprites/" + prefix + part + ".png")
		s.position = Vector2((i - (tiles - 1) / 2.0) * JellyPlatform.TILE, 0)
		p.add_child(s)

	p.body = StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(tiles * JellyPlatform.TILE, JellyPlatform.VIS_H)
	shape.shape = rect
	shape.position = Vector2(0, -JellyPlatform.VIS_H / 2.0)
	shape.one_way_collision = true
	shape.one_way_collision_margin = 6.0
	p.body.add_child(shape)
	p.add_child(p.body)

	if with_spring:
		p.spring_body = StaticBody2D.new()
		var ss := CollisionShape2D.new()
		var srect := RectangleShape2D.new()
		srect.size = Vector2(64, 30)
		ss.shape = srect
		ss.position = Vector2(0, -JellyPlatform.VIS_H - 15.0)
		ss.one_way_collision = true
		ss.one_way_collision_margin = 6.0
		p.spring_body.add_child(ss)
		var spr := Sprite2D.new()
		spr.texture = spring_tex
		spr.position = Vector2(0, -JellyPlatform.VIS_H - 25.0 + 25.0)
		p.spring_body.add_child(spr)
		p.add_child(p.spring_body)
	return p

func set_motion(amp: float, speed: float, phase: float) -> void:
	_amp = amp
	_speed = speed
	_phase = phase

func start_crumble() -> void:
	if _crumbling or type != "dirt":
		return
	_crumbling = true

func _process(delta: float) -> void:
	if _amp > 0.0 and not _crumbling:
		_phase += delta * _speed
		position.x = _origin_x + sin(_phase) * _amp
	if _crumbling:
		_crumble_t += delta
		modulate.a = clamp(1.0 - _crumble_t * 2.2, 0.0, 1.0)
		position.y += 60.0 * delta * _crumble_t
		if _crumble_t > 0.22 and body.get_child(0) is CollisionShape2D:
			(body.get_child(0) as CollisionShape2D).set_deferred("disabled", true)
		if _crumble_t > 0.9:
			queue_free()
