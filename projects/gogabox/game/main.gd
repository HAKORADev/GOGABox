extends Node2D
## GOGABox bootstrap: splash -> menu. Games are hosted on top of the menu
## (GameHost), achievement popups float above everything (Achiever).

var _splash_layer: CanvasLayer
var _splash_root: Control
var _splash_alive := false

func _ready() -> void:
	# menu is built immediately, the splash covers it while the engine warms up
	var menu := Node2D.new()
	menu.set_script(load("res://game/menu/menu.gd"))
	add_child(menu)

	var achiever: Node = load("res://game/core/achiever.gd").new()
	add_child(achiever)

	_show_splash()

func _show_splash() -> void:
	_splash_layer = CanvasLayer.new()
	_splash_layer.layer = 20
	add_child(_splash_layer)

	_splash_root = Control.new()
	_splash_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_splash_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_splash_layer.add_child(_splash_root)

	var art := TextureRect.new()
	art.texture = load("res://assets/ui/splash.png")
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_splash_root.add_child(art)

	# fade in + a slow gentle zoom (feels alive, not a static image)
	_splash_root.modulate.a = 0.0
	art.pivot_offset = art.size / 2.0
	var tw := _splash_root.create_tween()
	tw.tween_property(_splash_root, "modulate:a", 1.0, 0.35)
	tw.parallel().tween_property(art, "scale", Vector2(1.04, 1.04), 1.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	get_tree().create_timer(1.8).timeout.connect(_end_splash)
	_splash_alive = true

func _end_splash() -> void:
	if not _splash_alive:
		return
	_splash_alive = false
	if not is_instance_valid(_splash_root):
		return
	var out := create_tween()
	out.tween_property(_splash_root, "modulate:a", 0.0, 0.4)
	out.tween_callback(func():
		if is_instance_valid(_splash_layer):
			_splash_layer.queue_free())

func _input(event: InputEvent) -> void:
	# tap anywhere to skip the splash
	if _splash_alive and event is InputEventScreenTouch \
			and (event as InputEventScreenTouch).pressed:
		_end_splash()
