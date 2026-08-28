extends CanvasLayer
## All screens (menu / HUD / game over / shop / daily), built in code.
## Communicates with main.gd through signals below.

signal play_pressed
signal revive_pressed
signal double_pressed
signal retry_pressed
signal home_pressed

const ACCENT := Color("6fc4a9")
const ACCENT_DARK := Color("3f8f6e")
const GOLD := Color("f0c040")
const DANGER := Color("e06a5a")
const PANEL_BG := Color(0.07, 0.10, 0.18, 0.94)
const BTN_BG := Color(0.14, 0.20, 0.32, 0.98)

var root: Control
var hud: Control
var menu: Control
var gameover: Control
var shop: Control
var daily: Control

var _score_label: Label
var _coins_label: Label
var _menu_coins: Label
var _menu_best: Label
var _go_score: Label
var _go_coins: Label
var _go_new_best: Label
var _go_revive: Button
var _go_double: Button
var _shop_grid: HBoxContainer
var _daily_info: Label
var _daily_claim: Button
var _daily_streak: Label
var _toast: Label
var _sim_banner: Control

func _ready() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_hud()
	_build_menu()
	_build_gameover()
	_build_shop()
	_build_daily()
	_build_toast()
	hide_all()
	GameState.coins_changed.connect(func(t): refresh_coins(t))

# ============================================================ building blocks

func _btn(text: String, font_size := 40, bg := BTN_BG) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", ACCENT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(22)
	sb.set_content_margin_all(18)
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	b.add_theme_stylebox_override("normal", sb)
	var sbp := sb.duplicate() as StyleBoxFlat
	sbp.bg_color = bg.lightened(0.12)
	b.add_theme_stylebox_override("hover", sbp)
	var sbd := sb.duplicate() as StyleBoxFlat
	sbd.bg_color = bg.darkened(0.2)
	b.add_theme_stylebox_override("pressed", sbd)
	b.add_theme_stylebox_override("disabled", sbd)
	b.pressed.connect(func(): Sfx.play("click"))
	return b

func _label(text: String, size := 34, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _panel(size: Vector2) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.set_corner_radius_all(28)
	sb.set_content_margin_all(36)
	pc.add_theme_stylebox_override("panel", sb)
	pc.custom_minimum_size = size
	return pc

func _center_holder(parent: Control) -> CenterContainer:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(cc)
	return cc

# ============================================================ HUD

func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)

	var coin_chip := HBoxContainer.new()
	coin_chip.position = Vector2(24, 24)
	coin_chip.add_theme_constant_override("separation", 10)
	hud.add_child(coin_chip)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/sprites/hud_coin.png")
	icon.custom_minimum_size = Vector2(44, 44)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_chip.add_child(icon)
	_coins_label = _label("0", 40, GOLD)
	coin_chip.add_child(_coins_label)

	_score_label = _label("0 m", 56)
	_score_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_score_label.position = Vector2(360 - 100, 22)
	_score_label.custom_minimum_size = Vector2(200, 70)
	_score_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hud.add_child(_score_label)

# ============================================================ menu

func _build_menu() -> void:
	menu = Control.new()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(menu)

	var title := _label("JELLY", 110, ACCENT)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(360 - 300, 200)
	title.custom_minimum_size = Vector2(600, 130)
	menu.add_child(title)
	var title2 := _label("JUMP", 110, Color.WHITE)
	title2.position = Vector2(360 - 300, 320)
	title2.custom_minimum_size = Vector2(600, 130)
	menu.add_child(title2)

	_menu_best = _label("Best: 0 m", 36, Color(1, 1, 1, 0.85))
	_menu_best.position = Vector2(0, 470)
	_menu_best.custom_minimum_size = Vector2(720, 50)
	menu.add_child(_menu_best)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 22)
	col.position = Vector2(160, 580)
	col.custom_minimum_size = Vector2(400, 0)
	menu.add_child(col)

	var play := _btn("PLAY", 52, ACCENT_DARK)
	play.custom_minimum_size = Vector2(400, 96)
	play.pressed.connect(func(): play_pressed.emit())
	col.add_child(play)

	var shop_btn := _btn("SKINS", 40)
	shop_btn.custom_minimum_size = Vector2(400, 84)
	shop_btn.pressed.connect(func(): _open(shop))
	col.add_child(shop_btn)

	var daily_btn := _btn("DAILY GIFT", 40)
	daily_btn.custom_minimum_size = Vector2(400, 84)
	daily_btn.pressed.connect(func(): _open_daily())
	col.add_child(daily_btn)

	var sound := _btn("Sound: ON", 30, Color(0.2, 0.2, 0.28, 0.9))
	sound.custom_minimum_size = Vector2(400, 64)
	sound.pressed.connect(func():
		GameState.data["sound"] = not bool(GameState.data["sound"])
		GameState.save()
		sound.text = "Sound: ON" if GameState.data["sound"] else "Sound: OFF")
	col.add_child(sound)

	_menu_coins = _label("0", 40, GOLD)
	_menu_coins.position = Vector2(0, 560)
	_menu_coins.custom_minimum_size = Vector2(720, 50)
	menu.add_child(_menu_coins)

	# simulated banner strip (desktop). On device the native banner overlays here.
	_sim_banner = ColorRect.new()
	_sim_banner.color = Color(0.06, 0.08, 0.1, 1.0)
	_sim_banner.position = Vector2(0, 1190)
	_sim_banner.size = Vector2(720, 90)
	var bl := _label("BANNER AD (simulated on desktop)", 24, Color(1, 1, 1, 0.5))
	bl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sim_banner.add_child(bl)
	menu.add_child(_sim_banner)

# ============================================================ game over

func _build_gameover() -> void:
	gameover = Control.new()
	gameover.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(gameover)

	var cc := _center_holder(gameover)
	var pc := _panel(Vector2(560, 0))
	cc.add_child(pc)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	pc.add_child(col)

	var t := _label("GAME OVER", 62, DANGER)
	col.add_child(t)
	_go_new_best = _label("NEW BEST!", 36, GOLD)
	col.add_child(_go_new_best)
	_go_score = _label("0 m", 54)
	col.add_child(_go_score)
	_go_coins = _label("+0 coins", 36, GOLD)
	col.add_child(_go_coins)

	_go_revive = _btn("SAVE ME  (watch ad)", 32, ACCENT_DARK)
	_go_revive.custom_minimum_size = Vector2(460, 80)
	_go_revive.pressed.connect(func(): revive_pressed.emit())
	col.add_child(_go_revive)

	_go_double = _btn("DOUBLE COINS  (watch ad)", 32, ACCENT_DARK)
	_go_double.custom_minimum_size = Vector2(460, 80)
	_go_double.pressed.connect(func(): double_pressed.emit())
	col.add_child(_go_double)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)
	var retry := _btn("RETRY", 34)
	retry.custom_minimum_size = Vector2(220, 76)
	retry.pressed.connect(func(): retry_pressed.emit())
	row.add_child(retry)
	var home := _btn("HOME", 34)
	home.custom_minimum_size = Vector2(220, 76)
	home.pressed.connect(func(): home_pressed.emit())
	row.add_child(home)

# ============================================================ shop

func _build_shop() -> void:
	shop = Control.new()
	shop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shop)
	var cc := _center_holder(shop)
	var pc := _panel(Vector2(640, 0))
	cc.add_child(pc)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	pc.add_child(col)
	col.add_child(_label("SKINS", 56, ACCENT))
	_shop_grid = HBoxContainer.new()
	_shop_grid.add_theme_constant_override("separation", 14)
	col.add_child(_shop_grid)
	var close := _btn("CLOSE", 30)
	close.custom_minimum_size = Vector2(240, 66)
	close.pressed.connect(func(): _open(menu); refresh_menu())
	col.add_child(close)

func _build_shop_cards() -> void:
	for c in _shop_grid.get_children():
		c.queue_free()
	var active: String = GameState.data["skin"]
	for s in GameState.SKINS:
		var card := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = BTN_BG if s["id"] != active else ACCENT_DARK
		sb.set_corner_radius_all(18)
		sb.set_content_margin_all(14)
		card.add_theme_stylebox_override("panel", sb)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		card.add_child(col)
		var img := TextureRect.new()
		img.texture = load("res://assets/sprites/%s_stand.png" % s["prefix"])
		img.modulate = s["tint"]
		img.custom_minimum_size = Vector2(84, 110)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		col.add_child(img)
		col.add_child(_label(s["name"], 24))
		var owned: bool = GameState.owns(s["id"])
		var equipped: bool = s["id"] == active
		var price := _label(("EQUIPPED" if equipped else ("OWNED" if owned else "%d" % s["price"])), 22, GOLD)
		col.add_child(price)
		var b := _btn("BUY" if not owned else "USE", 24, ACCENT_DARK)
		b.custom_minimum_size = Vector2(100, 54)
		var skin_id: String = s["id"]
		b.pressed.connect(func(): _shop_action(skin_id))
		col.add_child(b)
		_shop_grid.add_child(card)

func _shop_action(id: String) -> void:
	if GameState.owns(id):
		GameState.equip_skin(id)
		Sfx.play("confirm")
	else:
		var sk: Dictionary = {}
		for s in GameState.SKINS:
			if s["id"] == id:
				sk = s
		if GameState.try_spend(int(sk["price"])):
			# refund-and-rebuy to keep buy_skin's atomic path simple
			GameState.add_coins(int(sk["price"]))
			if GameState.buy_skin(id):
				Sfx.play("buy")
				_toast_msg("Skin unlocked!")
		else:
			Sfx.play("error")
			_toast_msg("Not enough coins")
	_build_shop_cards()

# ============================================================ daily

func _build_daily() -> void:
	daily = Control.new()
	daily.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(daily)
	var cc := _center_holder(daily)
	var pc := _panel(Vector2(560, 0))
	cc.add_child(pc)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	pc.add_child(col)
	col.add_child(_label("DAILY GIFT", 56, ACCENT))
	_daily_streak = _label("", 32)
	col.add_child(_daily_streak)
	_daily_info = _label("", 40, GOLD)
	col.add_child(_daily_info)
	_daily_claim = _btn("CLAIM", 40, ACCENT_DARK)
	_daily_claim.custom_minimum_size = Vector2(300, 86)
	_daily_claim.pressed.connect(func():
		var reward: int = GameState.claim_daily()
		if reward > 0:
			Sfx.play("daily")
			_toast_msg("+%d coins!" % reward)
		_refresh_daily()
		refresh_coins(GameState.coins()))
	col.add_child(_daily_claim)
	var close := _btn("CLOSE", 30)
	close.custom_minimum_size = Vector2(240, 66)
	close.pressed.connect(func(): _open(menu); refresh_menu())
	col.add_child(close)

func _refresh_daily() -> void:
	_daily_streak.text = "Streak: %d day(s)" % GameState.daily_streak()
	if GameState.can_claim_daily():
		_daily_info.text = "Today's gift:\n%d coins" % GameState.daily_preview()
		_daily_claim.disabled = false
	else:
		_daily_info.text = "Already claimed.\nCome back tomorrow!"
		_daily_claim.disabled = true

func _open_daily() -> void:
	_refresh_daily()
	_open(daily)

# ============================================================ toast

func _build_toast() -> void:
	_toast = _label("", 34, Color.WHITE)
	_toast.position = Vector2(0, 1050)
	_toast.custom_minimum_size = Vector2(720, 60)
	_toast.modulate.a = 0.0
	root.add_child(_toast)

func _toast_msg(msg: String) -> void:
	_toast.text = msg
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.5)

# ============================================================ API for main.gd

func hide_all() -> void:
	for c in [hud, menu, gameover, shop, daily]:
		c.visible = false

func show_menu() -> void:
	hide_all()
	menu.visible = true
	refresh_menu()
	Ads.banner_show()
	Ads.banner_shown_changed.connect(_on_banner_changed, CONNECT_ONE_SHOT)

func refresh_menu() -> void:
	_menu_best.text = "Best: %d m" % GameState.best()
	_menu_coins.text = "%d" % GameState.coins()
	refresh_coins(GameState.coins())

func show_hud() -> void:
	hide_all()
	hud.visible = true
	Ads.banner_hide()
	set_score(0)
	refresh_coins(GameState.coins())

func set_score(m: int) -> void:
	_score_label.text = "%d m" % m

func show_game_over(score: int, coins_earned: int, new_best: bool, can_revive: bool) -> void:
	hide_all()
	Ads.banner_hide()
	gameover.visible = true
	_go_score.text = "%d m" % score
	_go_coins.text = "+%d coins" % coins_earned
	_go_new_best.visible = new_best
	_go_revive.visible = can_revive
	_go_double.disabled = coins_earned <= 0

func show_shop() -> void:
	_build_shop_cards()
	_open(shop)

func _open(what: Control) -> void:
	for c in [hud, menu, gameover, shop, daily]:
		c.visible = c == what

func refresh_coins(total: int) -> void:
	_coins_label.text = str(total)
	_menu_coins.text = str(total)

func _on_banner_changed(shown: bool) -> void:
	_sim_banner.visible = shown and Ads.desktop_sim
