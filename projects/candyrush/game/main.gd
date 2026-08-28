extends Node2D
## Root screen switcher: skin-aware background + menu / game / shop screens.

const MENU := 0
const GAME := 1
const SHOP := 2

var _screen: Node = null
var _screen_kind := MENU
var _bg: TextureRect

func _ready() -> void:
	_bg = TextureRect.new()
	_bg.size = Vector2(720, 1280)
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(_bg)
	GameState.skin_changed.connect(func(_id): _apply_skin())
	_apply_skin()
	_switch(MENU)
	Ads.banner_show()

func _apply_skin() -> void:
	var s := Skins.get_skin(GameState.skin())
	_bg.texture = Skins.background(s)
	if s["dark"]:
		_bg.modulate = Color(0.9, 0.9, 1.0)
	else:
		_bg.modulate = Color.WHITE

func _clear() -> void:
	if _screen:
		_screen.queue_free()
		_screen = null

func _switch(kind: int) -> void:
	_clear()
	_screen_kind = kind
	match kind:
		MENU:
			var m := Node2D.new()
			m.set_script(load("res://game/ui/menu.gd"))
			m.play_pressed.connect(func(): _switch(GAME))
			m.shop_pressed.connect(func(): _switch(SHOP))
			add_child(m)
			_screen = m
			Ads.banner_show()
		GAME:
			var g := Node2D.new()
			g.set_script(load("res://game/ui/match3.gd"))
			g.request_menu.connect(func(): _switch(MENU))
			g.request_next_level.connect(func(): _switch(GAME))
			g.request_shop.connect(func(): _switch(SHOP))
			add_child(g)
			_screen = g
			Ads.banner_hide()
		SHOP:
			var sh := Node2D.new()
			sh.set_script(load("res://game/ui/shop.gd"))
			sh.back_pressed.connect(func(): _switch(MENU))
			add_child(sh)
			_screen = sh
			Ads.banner_show()
