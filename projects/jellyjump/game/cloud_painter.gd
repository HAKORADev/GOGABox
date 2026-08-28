extends Node2D
## Procedural flat clouds, recycled vertically with parallax.
## Add as a child of Main; set camera_y each frame (main.gd does it).

const CLOUD_COUNT := 9
const BAND := 2400.0   # vertical span covered by recycled clouds

var _clouds: Array = []   # [{node, y_frac, scale, speed}]
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = 20260829
	for i in CLOUD_COUNT:
		var cloud := _make_cloud(_rng.randf_range(0.7, 1.6))
		add_child(cloud)
		_clouds.append({
			"node": cloud,
			"offset": _rng.randf_range(0.0, BAND),
			"speed": _rng.randf_range(8.0, 26.0) * (1 if _rng.randf() < 0.5 else -1),
			"x": _rng.randf_range(40, 680),
		})

func _make_cloud(sc: float) -> Node2D:
	var root := Node2D.new()
	var puffs := _rng.randi_range(4, 7)
	var alpha := _rng.randf_range(0.55, 0.85)
	for i in puffs:
		var c := _circle(_rng.randf_range(38, 74) * sc, Color(1, 1, 1, alpha))
		c.position = Vector2((i - puffs / 2.0) * 44.0 * sc, _rng.randf_range(-14, 14) * sc)
		root.add_child(c)
	return root

func _circle(r: float, color: Color) -> DrawableCircle:
	var c := DrawableCircle.new()
	c.radius = r
	c.color = color
	return c

## Call every frame with the camera's current y and delta.
func update_clouds(cam_y: float, delta: float) -> void:
	for cd in _clouds:
		var n: Node2D = cd["node"]
		cd["offset"] = fposmod(float(cd["offset"]) + float(cd["speed"]) * delta, BAND)
		# parallax: layer follows camera at 0.82x so clouds drift slower
		var world_y := cam_y * 0.82
		n.position = Vector2(float(cd["x"]), world_y - 1400.0 + float(cd["offset"]))
		# wrap clouds around the visible band
		var rel := n.position.y - cam_y
		if rel > 900.0:
			n.position.y -= BAND
		elif rel < -1500.0:
			n.position.y += BAND

class DrawableCircle extends Node2D:
	var radius := 40.0
	var color := Color.WHITE
	func _draw() -> void:
		draw_circle(Vector2.ZERO, radius, color)
