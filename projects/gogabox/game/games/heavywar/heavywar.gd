extends GogaGame
## HEAVY WAR: ROGUE ARSENAL (v040-4) - the survival rogue-like rebuild.
## 100% OUR OWN pixels (tools/v0404_rogue_art.py) + our own numbers.
## The design law lives in docs/goga_docs/gogames_ideas/heavywar/04_ROGUE_REWORK.md:
##   * ONE RUN: 10 places x 10 waves, a BOSS after every 10th wave,
##     a tunnel between places; after place 10 the war loops, harder.
##   * HEALTH SYSTEM (no lives): hull hits 0 = the run ends.
##   * THE CONTROLS (Snowy Tower law, hopper v0.2.6): LEFT HALF = the analog
##     move zone (the first touch anchors; the X offset from the anchor is
##     the force); RIGHT HALF = AIM + FIRE (the finger IS the aim point,
##     the cannon tracks it and fires while it stays). NO NUKES.
##   * WAVES: budget + 3:00 cap; at the cap the budget keeps growing until
##     the field is clear (the owner's "keep increasing enemies over and over").
##   * ENEMIES SCALE WITH THE TANK: place + level + loop + shop power.
##   * SCORE = KILLS. One kill, one point.
##   * GOGACOIN: after COIN_KILLS kills or COIN_TIME seconds the next
##     enemy death carries a coin (the owner's time-or-kills law).
##   * THE SHOP: gogacoins buy hull/cannon/wheels/reload, the MG nests +
##     rocket pods, the 4 MINI TANKS and the skins. The magnet is a mini
##     tank - never an upgrade card.

enum GS { INTRO, PLACE, BOSS, TUNNEL, OVER }

const MUSIC_MENU := "res://assets/audio/sfx/rw_music_menu.ogg"
const MUSIC_WAR := "res://assets/audio/sfx/rw_music_war.ogg"
const MUSIC_PRESS := "res://assets/audio/sfx/rw_music_press.ogg"
const MUSIC_BOSS := "res://assets/audio/sfx/rw_music_boss.ogg"

# ------------------------------------------------------------ live canvas
var W := 1920.0
var H := 1080.0
var GROUND_Y := 984.0

# ------------------------------------------------------------- run state
var state: int = GS.INTRO
var meta: HWMeta
var run := {}
var place_i := 0              # 0-based place index (the real counter)
var wave := 1
var loop := 1
var t_state := 0.0

# nodes
var world: Node2D
var sky_node: Polygon2D
var sun_node: Node2D
var layer_far: Array = []     # [{spr, w}]
var layer_mid: Array = []
var layer_near: Array = []
var ground_spr: Array = []
var tank: Node2D
var turret_node: Node2D
var barrel_node: Sprite2D
var ent_layer: Node2D
var shot_layer: Node2D
var fx_layer: Node2D
var hud_draw: Control

# pools (the house way: dict entities)
var enemies: Array = []
var shots: Array = []
var eshots: Array = []
var rockets: Array = []
var drops: Array = []
var fx: Array = []
var decals: Array = []
var kills := 0
var boss_ent: Dictionary = {}

# player numbers
var p_hp := 100.0
var p_hp_max := 100.0
var p_shield := 0.0
var p_xp := 0
var p_level := 1
var p_xp_next := 60
var p_x := 960.0
var p_aim := -PI / 2
var p_invuln := 0.0
var p_recoil := 0.0
var p_wheel_spin := 0.0
var buffs := {}
var chill := {}                # enemy -> seconds left chilled

# weapons cadence
var cd_main := 0.0
var cd_mg := 0.0
var cd_rk := 0.0
var cd_mt_mg := 0.0
var cd_mt_ice := 0.0
var cd_mt_rk := 0.0
var mg_flash := 0.0

# wave director
var wave_state := "idle"       # idle/spawning/clearing/boss
var spawn_list: Array = []
var spawn_t := 0.0
var wave_clock := 0.0
var overbudget := 0            # extra enemies poured at the 3:00 cap
var banner := ""
var banner_t := 0.0

# the coin law
var coin_kills := 0
var coin_timer := 0.0
var coin_armed := false

# input (the hopper law: roles at touchdown, kept until lift)
var move_ptr := -1
var move_anchor := 0.0
var move_force := 0.0
var aim_ptr := -1
var aim_pos := Vector2(960.0, 400.0)
var mouse_aim := false

# parallax scroll
var scroll_x := 0.0

# shop/levelup bookkeeping
var shop_dirty := false

func _goga_setup() -> void:
	ScaleRule.apply(get_window())
	var vp := get_viewport_rect().size
	W = maxf(960.0, vp.x)
	H = maxf(540.0, vp.y)
	GROUND_Y = H - HWData.GROUND_H
	meta = HWMeta.load_meta()
	game_id = "heavywar"
	pause_end_run = false
	set_score(0)
	_run_reset()
	_build_world()
	_build_tank()
	_build_hud_bars()
	add_hud_button("SHOP", func(): _shop_open())
	_enter_intro()

# =================================================================
# THE RUN LEDGER
# =================================================================
func _run_reset() -> void:
	place_i = 0
	wave = 1
	loop = 1
	kills = 0
	run = {"places_done": 0, "bosses_met": 0, "bosses_killed": 0,
		"coins": 0}
	p_hp_max = 100.0 + _shop_lvl("armor") * 20
	p_hp = p_hp_max
	p_shield = 0.0
	p_xp = 0
	p_level = 1
	p_xp_next = 60
	p_x = W / 2.0
	p_aim = -PI / 2
	p_invuln = 0.0
	buffs = {"dmg": 0.0, "rate": 0.0, "speed": 0.0, "pierce": 0,
		"explosive": 0, "lifesteal": 0.0, "multi": 0, "dr": 0.0,
		"cd": 1.0, "crit": 0.0, "bounce": 0, "slow": 0.0}
	coin_kills = 0
	coin_timer = 0.0
	coin_armed = false
	wave_state = "idle"
	spawn_list = []
	enemies = []
	shots = []
	eshots = []
	rockets = []
	drops = []
	fx = []
	decals = []
	chill = {}

func _shop_lvl(id: String) -> int:
	var u: Dictionary = HWData.SHOP_UPG.get(id, {})
	if u.is_empty():
		return 0
	return int((meta.d.get("upg", {}) as Dictionary).get(id, 0))

func _mini_owned(id: String) -> bool:
	return Box.item_owned(game_id, "mini", id)

func _shop_power() -> float:
	return HWData.shop_index(_shop_lvl("mg") + _shop_lvl("mg_rack"),
		_shop_lvl("rockets") + _shop_lvl("rocket_rack"),
		_shop_lvl("armor"), _shop_lvl("cannon"), _shop_lvl("wheels"),
		_shop_lvl("reload"), (1 if _mini_owned("mt_rocket") else 0)
		+ (1 if _mini_owned("mt_mg") else 0)
		+ (1 if _mini_owned("mt_ice") else 0)
		+ (1 if _mini_owned("mt_magnet") else 0))

func _diff() -> float:
	return HWData.diff(place_i, p_level, loop, _shop_power())

# =================================================================
# THE WORLD (sky gradient + 3 silhouette planes + the ground band)
# =================================================================
func _build_world() -> void:
	world = Node2D.new()
	add_child(world)
	_sky_node()
	_layers()
	_ground()
	ent_layer = Node2D.new()
	world.add_child(ent_layer)
	shot_layer = Node2D.new()
	world.add_child(shot_layer)
	fx_layer = Node2D.new()
	world.add_child(fx_layer)

func _sky_node() -> void:
	var pl: Dictionary = HWData.PLACES[place_i % 10]
	sky_node = Polygon2D.new()
	sky_node.polygon = PackedVector2Array([Vector2(-40, -40),
		Vector2(W + 40, -40), Vector2(W + 40, GROUND_Y + 40),
		Vector2(-40, GROUND_Y + 40)])
	sky_node.vertex_colors = PackedColorArray([pl["sky_top"],
		pl["sky_top"], pl["sky_bot"], pl["sky_bot"]])
	world.add_child(sky_node)
	sun_node = Node2D.new()
	sun_node.set_script(null)
	sun_node.draw.connect(_draw_sun)
	world.add_child(sun_node)

func _draw_sun() -> void:
	var pl: Dictionary = HWData.PLACES[place_i % 10]
	var sx := W * 0.76
	var sy := GROUND_Y * 0.30
	sun_node.draw_circle(Vector2(sx, sy), 150.0,
		Color(pl["sun"], 0.16))
	sun_node.draw_circle(Vector2(sx, sy), 64.0, Color(pl["sun"], 0.35))
	sun_node.draw_circle(Vector2(sx, sy), 30.0, Color(pl["sun"], 0.95))

func _make_layer(path: String, speed: float, y_off: float, scale: float) -> Array:
	var tex: Texture2D = load(path)
	var tw := tex.get_width() * scale
	var th := tex.get_height() * scale
	var pair: Array = []
	for i in 3:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.scale = Vector2(scale, scale)
		world.add_child(s)
		pair.append({"spr": s, "w": tw})
	return pair

func _layers() -> void:
	var pl: Dictionary = HWData.PLACES[place_i % 10]
	layer_far = _make_layer(HWData.ART + "env/r_env_%s_far.png" % pl["key"],
		HWData.PLANE_FAR, 0.0, 1.0)
	layer_mid = _make_layer(HWData.ART + "env/r_env_%s_mid.png" % pl["key"],
		HWData.PLANE_MID, 0.0, 1.0)
	layer_near = _make_layer(HWData.ART + "env/r_env_%s_near.png" % pl["key"],
		HWData.PLANE_NEAR, 0.0, 1.0)
	_seat_layers()

func _seat_layers() -> void:
	# every plane's BOTTOM sits on the ground line; X rides the scroll
	for pair in ([layer_far, layer_mid, layer_near] as Array):
		if (pair as Array).is_empty():
			continue
		var th: float = (pair[0]["spr"] as Sprite2D).texture.get_height() \
			* (pair[0]["spr"] as Sprite2D).scale.y
		for e in (pair as Array):
			var s: Sprite2D = e["spr"]
			s.position.y = GROUND_Y - th
	_seat_ground()

func _ground() -> void:
	var pl: Dictionary = HWData.PLACES[place_i % 10]
	var tex: Texture2D = load(HWData.ART + "env/r_env_%s_ground.png" % pl["key"])
	var scale := (H - GROUND_Y + 10.0) / float(tex.get_height())
	for i in 2:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.scale = Vector2(scale, scale)
		world.add_child(s)
		ground_spr.append({"spr": s, "w": tex.get_width() * scale})
	_seat_ground()
	var band := ColorRect.new()
	band.color = Color(pl["ground_top"], 0.85)
	band.position = Vector2(-40, GROUND_Y - 4)
	band.size = Vector2(W + 80, 4)
	world.add_child(band)

func _seat_ground() -> void:
	if ground_spr.size() < 2:
		return
	var tw: float = ground_spr[0]["w"]
	var off := fposmod(scroll_x * HWData.PLANE_GROUND, tw)
	(ground_spr[0]["spr"] as Sprite2D).position.x = -off
	(ground_spr[1]["spr"] as Sprite2D).position.x = -off + tw
	_slide_layer(layer_far, HWData.PLANE_FAR)
	_slide_layer(layer_mid, HWData.PLANE_MID)
	_slide_layer(layer_near, HWData.PLANE_NEAR)

func _slide_layer(pair: Array, plane: float) -> void:
	if (pair as Array).is_empty():
		return
	var tw: float = pair[0]["w"]
	var off := fposmod(scroll_x * plane, tw)
	for i in (pair as Array).size():
		var s: Sprite2D = (pair[i] as Dictionary)["spr"]
		s.position.x = i * tw - off

func _swap_place_art() -> void:
	# kill the old planes, rebuild for the new place
	for pair in ([layer_far, layer_mid, layer_near] as Array):
		for e in (pair as Array):
			((e as Dictionary)["spr"] as Sprite2D).queue_free()
	for e in ground_spr:
		(e["spr"] as Sprite2D).queue_free()
	layer_far = []
	layer_mid = []
	layer_near = []
	ground_spr = []
	if sky_node != null and is_instance_valid(sky_node):
		sky_node.queue_free()
		sun_node.queue_free()
	_sky_node()
	_layers()
	_ground()
	# the rebuilt planes land at the END of the child list - drag the war
	# back on top: entities, shots, THE TANK (a _bolt_mini rebuild parks it
	# after the old planes) and the fx crown everything
	for n in [ent_layer, shot_layer, tank, fx_layer]:
		if n != null and is_instance_valid(n):
			world.move_child(n, world.get_child_count() - 1)

# =================================================================
# THE TANK (one big hull + turret + barrel + the flank mini tanks)
# =================================================================
func _build_tank() -> void:
	tank = Node2D.new()
	tank.position = Vector2(p_x, GROUND_Y - 44.0)
	tank.z_index = 50            # above the tunnel overlay (z 40)
	world.add_child(tank)
	var hull := Sprite2D.new()
	hull.texture = load(_skin_tex("hull"))
	hull.scale = Vector2(0.5, 0.5)
	tank.add_child(hull)
	turret_node = Node2D.new()
	turret_node.position = Vector2(4.0, -64.0)
	tank.add_child(turret_node)
	var tur := Sprite2D.new()
	tur.texture = load(_skin_tex("turret"))
	tur.scale = Vector2(0.5, 0.5)
	turret_node.add_child(tur)
	barrel_node = Sprite2D.new()
	barrel_node.texture = load(HWData.ART + "r_tank_barrel.png")
	barrel_node.scale = Vector2(0.34, 0.42)
	barrel_node.position = Vector2(62.0, -3.0)
	turret_node.add_child(barrel_node)
	# the flank mini tanks (bought ones bolt on, the magnet glow rides too)
	var mounts := [Vector2(-64.0, -6.0), Vector2(-6.0, -4.0),
		Vector2(44.0, -6.0), Vector2(96.0, -8.0)]
	var mi := 0
	for mid in ["mt_rocket", "mt_mg", "mt_ice", "mt_magnet"]:
		if _mini_owned(mid):
			var ms := Sprite2D.new()
			ms.texture = load(HWData.ART + HWData.MINIS[mid]["icon"] + ".png")
			ms.scale = Vector2(0.62, 0.62)
			ms.position = mounts[mi]
			tank.set_meta("mini_" + mid, ms)
			tank.add_child(ms)
		mi += 1

func _skin_tex(part: String) -> String:
	var sid := Box.skin_on(game_id)
	if sid == "" or not HWData.SKINS.has(sid):
		sid = "olive"
	return HWData.ART + "r_skin_%s_%s.png" % [sid, part]

func _apply_skin() -> void:
	if tank == null:
		return
	for c in tank.get_children():
		if c is Sprite2D and (c as Sprite2D).texture != null:
			var p := ((c as Sprite2D).texture.resource_path as String)
			if p.contains("_hull"):
				(c as Sprite2D).texture = load(_skin_tex("hull"))
			elif p.contains("_turret") and not p.contains("barrel"):
				(c as Sprite2D).texture = load(_skin_tex("turret"))

# =================================================================
# THE CONTROLS (Snowy Tower law): LEFT HALF = the analog move zone -
# the first touch anchors, the X offset from the anchor is the force,
# Y ignored. RIGHT HALF = AIM + FIRE - the finger IS the aim point.
# A finger takes its role at touchdown and keeps it until lift.
# =================================================================
func _goga_input(event: InputEvent) -> void:
	if state == GS.OVER or paused:
		return
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.pressed:
			_touch_down(e.index, e.position)
		else:
			_touch_up(e.index)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == move_ptr:
			move_force = clampf((d.position.x - move_anchor) / 150.0,
				-1.0, 1.0)
		elif d.index == aim_ptr:
			aim_pos = d.position

func _touch_down(idx: int, pos: Vector2) -> void:
	if state == GS.INTRO:
		_start_place()
		return
	if pos.x < W * 0.5:
		if move_ptr == -1:
			move_ptr = idx
			move_anchor = pos.x
			move_force = 0.0
	else:
		if aim_ptr == -1:
			aim_ptr = idx
			aim_pos = pos

func _touch_up(idx: int) -> void:
	if idx == move_ptr:
		move_ptr = -1
		move_force = 0.0
	elif idx == aim_ptr:
		aim_ptr = -1

# =================================================================
# THE STATE FLOW: intro -> place (10 waves) -> boss -> tunnel -> next
# =================================================================
func _enter_intro() -> void:
	state = GS.INTRO
	t_state = 0.0
	Jukebox.music(MUSIC_MENU)
	_banner("HEAVY WAR: ROGUE ARSENAL", 3.0)
	if not bool(meta.d["lore_seen"]):
		meta.see_lore()

func _start_place() -> void:
	state = GS.PLACE
	t_state = 0.0
	wave_state = "idle"
	wave_clock = 0.0
	Jukebox.music(MUSIC_WAR)
	_banner(String(HWData.PLACES[place_i % 10]["name"])
		+ ("  II" if place_i >= 10 else ""), 2.4)

func _goga_tick(delta: float) -> void:
	if paused or state == GS.OVER:
		return
	t_state += delta
	banner_t = maxf(0.0, banner_t - delta)
	p_recoil = maxf(0.0, p_recoil - delta * 8.0)
	mg_flash = maxf(0.0, mg_flash - delta * 7.0)
	if p_invuln > 0.0:
		p_invuln -= delta
	match state:
		GS.INTRO:
			_tick_world_scroll(delta, 1.0)
		GS.PLACE:
			_tick_place(delta)
		GS.BOSS:
			_tick_boss(delta)
		GS.TUNNEL:
			_tick_tunnel(delta)
	_update_player(delta)
	_update_shots(delta)
	_update_eshots(delta)
	_update_rockets(delta)
	_update_enemies(delta)
	_update_drops(delta)
	_update_fx(delta)
	if hud_draw != null:
		hud_draw.queue_redraw()

func _tick_world_scroll(delta: float, mul: float) -> void:
	scroll_x += HWData.WORLD_SPEED * mul * delta
	_seat_ground()
	# world drifts even when the tank idles - the war never stops moving

func _banner(txt: String, dur: float) -> void:
	banner = txt
	banner_t = dur

# ------------------------------------------------------------------ waves
func _tick_place(delta: float) -> void:
	_tick_world_scroll(delta, 1.0 + move_force * 0.0)
	wave_clock += delta
	match wave_state:
		"idle":
			_wave_start()
		"spawning":
			spawn_t += delta
			var guard := 0
			while spawn_list.size() > 0 \
					and float(spawn_list[0]) <= spawn_t and guard < 60:
				spawn_list.pop_front()
				_spawn_enemy()
				guard += 1
			if spawn_list.is_empty():
				wave_state = "clearing"
			# THE 3:00 LAW: at the cap the pour never stops
			if wave_clock >= HWData.WAVE_MAX_TIME:
				overbudget += 1
				if overbudget % 2 == 1:
					spawn_list.append(spawn_t + 0.6)
					spawn_list.append(spawn_t + 1.2)
					if overbudget % 6 == 1:
						wave_state = "spawning"
		"clearing":
			if enemies.is_empty():
				if wave >= HWData.WAVES_PER_PLACE:
					_spawn_boss()
				else:
					wave += 1
					wave_state = "idle"
					_banner("WAVE %d / %d" % [wave, HWData.WAVES_PER_PLACE], 1.6)
					p_hp = minf(p_hp_max, p_hp + 6.0)
					Jukebox.sfx("rw_clear", -6.0)
		"boss":
			pass
	# the press music rides the back half of the place
	if wave >= 6 and wave_state != "boss":
		Jukebox.music(MUSIC_PRESS)

func _wave_start() -> void:
	var budget := HWData.wave_budget(wave, place_i, loop, _shop_power())
	var iv := HWData.wave_interval(wave, _diff())
	spawn_list = []
	var tt := 0.0
	for i in budget:
		tt += iv * randf_range(0.7, 1.3)
		spawn_list.append(tt)
	spawn_t = 0.0
	wave_clock = 0.0
	overbudget = 0
	wave_state = "spawning"
	_banner("WAVE %d / %d" % [wave, HWData.WAVES_PER_PLACE], 1.6)
	Jukebox.sfx("rw_wave", -6.0)

# ------------------------------------------------------------------ spawns
func _spawn_enemy(kind := "") -> void:
	if enemies.size() >= 90:
		return
	var pool := HWData.pool_for(place_i)
	if kind == "":
		kind = String(pool[randi() % pool.size()])
	var def: Dictionary = HWData.ENEMIES[kind]
	var df := _diff()
	var hp := int(round(float(def["hp"]) * (1.0 + df * 0.52)))
	var spd := float(def["speed"]) * (1.0 + df * 0.045)
	var from_left := randf() < 0.5
	var e := {
		"kind": kind, "hp": hp, "maxhp": hp, "size": float(def["size"]),
		"speed": spd, "dir": -1 if not from_left else 1,
		"x": (-140.0) if from_left else (W + 140.0),
		"y": randf_range(90.0, maxf(200.0, GROUND_Y - 260.0)),
		"base_y": 0.0, "t": randf() * 10.0, "phase": randf() * TAU,
		"frame": 0, "frame_t": 0.0, "hit": 0.0,
		"shield": float(def.get("shield", 0)),
		"max_shield": float(def.get("shield", 0)),
		"move": String(def["move"]), "weapon": String(def["weapon"]),
		"shoot_t": randf_range(0.9, 2.2), "ground": def["move"] in ["ground", "static"],
		"chill": 0.0, "hover_x": randf_range(W * 0.2, W * 0.8),
		"diving": false,
	}
	e["base_y"] = e["y"]
	if e["move"] == "static":
		e["x"] = randf_range(W * 0.2, W * 0.8)
		e["y"] = GROUND_Y - e["size"] * 0.55
		e["base_y"] = e["y"]
	if e["move"] == "ground":
		e["y"] = GROUND_Y - e["size"] * 0.5
		e["base_y"] = e["y"]
	var spr := Sprite2D.new()
	spr.texture = load(HWData.ART + "enemies/r_e_%s0.png" % kind)
	spr.scale = Vector2(0.5, 0.5)
	spr.flip_h = not from_left
	spr.position = Vector2(e["x"], e["y"])
	e["spr"] = spr
	ent_layer.add_child(spr)
	enemies.append(e)

func _enemy_frame(e: Dictionary, delta: float) -> void:
	e["frame_t"] += delta
	if e["frame_t"] >= 0.34:
		e["frame_t"] = 0.0
		e["frame"] = 1 - int(e["frame"])
	var spr: Sprite2D = e["spr"]
	var f := int(e["frame"])
	var tex: Texture2D = load(HWData.ART + "enemies/r_e_%s%d.png" % [e["kind"], f])
	spr.texture = tex
	spr.position = Vector2(e["x"], e["y"])
	spr.flip_h = e["dir"] > 0
	if e["hit"] > 0.0:
		spr.modulate = Color(6.0, 6.0, 6.0)
	else:
		spr.modulate = Color(1, 1, 1)

# ------------------------------------------------------------ enemy moves
func _update_enemies(delta: float) -> void:
	var dead: Array = []
	for e in enemies.duplicate():
		var d: Dictionary = e
		# THE BOSS BRANCH: the boss rides its own brain + visuals
		if String(d.get("kind", "")) == "boss":
			_update_boss(d, delta)
			continue
		d["t"] += delta
		if d["hit"] > 0.0:
			d["hit"] -= delta
		if d["chill"] > 0.0:
			d["chill"] -= delta
		var spd: float = d["speed"] * (0.5 if d["chill"] > 0.0 else 1.0)
		match String(d["move"]):
			"straight":
				d["x"] += d["dir"] * spd * delta
				d["y"] = d["base_y"] + sin(d["t"] * 2.4 + d["phase"]) * 14.0
			"sine":
				d["x"] += d["dir"] * spd * delta
				d["y"] = d["base_y"] + sin(d["t"] * 1.8 + d["phase"]) * 30.0
			"hover":
				if absf(d["x"] - float(d["hover_x"])) > 26.0 \
						and not bool(d.get("arrived", false)):
					d["x"] += signf(float(d["hover_x"]) - float(d["x"])) \
						* spd * delta
					if absf(d["x"] - float(d["hover_x"])) <= 26.0:
						d["arrived"] = true
						d["dir"] = 1 if randf() < 0.5 else -1
				else:
					d["x"] += d["dir"] * spd * 0.55 * delta
					if d["x"] < 130.0:
						d["x"] = 130.0
						d["dir"] = 1
					elif d["x"] > W - 130.0:
						d["x"] = W - 130.0
						d["dir"] = -1
				d["y"] = d["base_y"] + sin(d["t"] * 1.7) * 14.0
			"dive":
				if not bool(d["diving"]) and absf(d["x"] - p_x) < 340.0:
					d["diving"] = true
					var ang := atan2((GROUND_Y - 90.0) - float(d["y"]),
						p_x - float(d["x"]))
					d["vx"] = cos(ang) * 380.0
					d["vy"] = sin(ang) * 380.0
				if bool(d["diving"]):
					d["x"] += float(d.get("vx", 0.0)) * delta
					d["y"] += float(d.get("vy", 0.0)) * delta
				else:
					d["x"] += d["dir"] * spd * delta
					d["y"] = d["base_y"] + sin(d["t"] * 3.0) * 20.0
			"ground":
				d["x"] += d["dir"] * spd * delta
			"static":
				pass
		# weapons
		if String(d["weapon"]) != "none" and p_invuln <= 0.0:
			var can := true
			if String(d["move"]) == "hover" and not bool(d.get("arrived", false)):
				can = false
			if can:
				d["shoot_t"] -= delta
				if float(d["shoot_t"]) <= 0.0:
					d["shoot_t"] = randf_range(1.1, 2.4) * maxf(0.55, 1.0 - _diff() * 0.03)
					_enemy_fire(d)
		# kamikaze ground hit
		if String(d["move"]) == "dive" and bool(d["diving"]) \
				and d["y"] > GROUND_Y - 30.0:
			_explode(d["x"], GROUND_Y - 20.0, 0.9)
			if absf(d["x"] - p_x) < 110.0:
				_damage_player(14.0)
			kill_enemy(d, false)
			dead.append(d)
			continue
		if d["x"] < -360.0 or d["x"] > W + 360.0:
			dead.append(d)
			((d["spr"] as Sprite2D)).queue_free()
			continue
		_enemy_frame(d, delta)
	for d in dead:
		enemies.erase(d)

func _enemy_fire(e: Dictionary) -> void:
	var src := Vector2(e["x"], e["y"] + e["size"] * 0.2)
	var tgt := Vector2(p_x, GROUND_Y - 100.0)
	var ang := (tgt - src).angle()
	var col: Color = HWData.PLACES[place_i % 10]["accent"]
	match String(e["weapon"]):
		"aimed":
			_eshot(src, Vector2.from_angle(ang) * 380.0, 9.0, "plasma")
			Jukebox.sfx("rw_eshot", -10.0)
		"spread":
			for i in 3:
				_eshot(src, Vector2.from_angle(ang + (i - 1) * 0.17) * 350.0,
					9.0, "plasma")
			Jukebox.sfx("rw_eshot", -9.0)
		"homing":
			_eshot(src, Vector2(e["dir"] * 160.0, 70.0), 13.0, "missile")
			Jukebox.sfx("rw_rocket", -12.0)
		"bomb":
			var b := {"x": e["x"], "y": e["y"] + e["size"] * 0.4,
				"vx": e["dir"] * 40.0, "vy": 40.0, "dmg": 16.0, "t": 0.0}
			_eshot_common(b, "bomb")
			Jukebox.sfx("rw_eshot", -12.0)
		"arc":
			_eshot(src, Vector2((tgt.x - src.x) * 0.8, -320.0), 13.0, "plasma")
			Jukebox.sfx("rw_eshot", -10.0)

func _eshot_common(b: Dictionary, kind: String) -> void:
	var spr := Sprite2D.new()
	spr.texture = load(HWData.ART + "shots/r_%s.png" % kind)
	spr.scale = Vector2(0.5, 0.5)
	spr.position = Vector2(b["x"], b["y"])
	b["spr"] = spr
	b["kind"] = kind
	shot_layer.add_child(spr)
	eshots.append(b)

func _eshot(pos: Vector2, vel: Vector2, dmg: float, kind: String) -> void:
	if eshots.size() >= 220:
		return
	var b := {"x": pos.x, "y": pos.y, "vx": vel.x, "vy": vel.y,
		"dmg": dmg, "t": 0.0, "homing": 2.2 if kind == "missile" else 0.0}
	_eshot_common(b, kind)

# ------------------------------------------------------------------ bosses
func _spawn_boss() -> void:
	wave_state = "boss"
	run["bosses_met"] = int(run["bosses_met"]) + 1
	var def: Dictionary = HWData.BOSSES[place_i % 10]
	var hp := HWData.boss_hp(place_i, loop, _shop_power())
	var b := {
		"kind": "boss", "boss_id": String(def["id"]),
		"name": String(def["name"]), "brain": String(def["brain"]),
		"hp": float(hp), "maxhp": float(hp), "size": float(def["size"]),
		"x": W + 260.0, "y": 210.0, "base_y": 210.0, "t": 0.0,
		"dir": -1, "frame": 0, "frame_t": 0.0, "hit": 0.0,
		"arrived": false, "vx": -110.0, "weapon_t": 1.6,
		"weapon_cycle": 0, "spawn_t": 6.0, "enraged": false,
		"chill": 0.0, "dash_dir": -1,
	}
	var spr := Sprite2D.new()
	spr.texture = load(HWData.ART + "bosses/r_b_%s0.png" % b["boss_id"])
	spr.scale = Vector2(0.5, 0.5)
	b["spr"] = spr
	ent_layer.add_child(spr)
	enemies.append(b)
	boss_ent = b
	state = GS.BOSS
	Jukebox.music(MUSIC_BOSS)
	_banner("BOSS  -  " + b["name"], 2.6)
	Jukebox.sfx("rw_boss_warn", -4.0)

func _tick_boss(delta: float) -> void:
	_tick_world_scroll(delta, 0.4)
	# the boss ENT is the clock: minions may live on, the fight ends when
	# the boss itself is gone from the pool
	if not boss_ent.is_empty() and enemies.has(boss_ent):
		return
	boss_ent = {}
	# boss down -> the place falls
	run["bosses_killed"] = int(run["bosses_killed"]) + 1
	_enter_tunnel()

func _boss_visual(b: Dictionary, delta: float) -> void:
	b["frame_t"] += delta
	if b["frame_t"] >= 0.3:
		b["frame_t"] = 0.0
		b["frame"] = 1 - int(b["frame"])
	var spr: Sprite2D = b["spr"]
	spr.texture = load(HWData.ART + "bosses/r_b_%s%d.png"
		% [b["boss_id"], int(b["frame"])])
	spr.position = Vector2(b["x"], b["y"])
	spr.flip_h = false
	spr.modulate = Color(6.0, 6.0, 6.0) if float(b["hit"]) > 0.0 \
		else Color(1, 1, 1)

func _boss_fire(b: Dictionary, ang: float, spd: float, dmg: float) -> void:
	_eshot(Vector2(b["x"], b["y"]) + Vector2.from_angle(ang) * b["size"] * 0.3,
		Vector2.from_angle(ang) * spd, dmg, "plasma")

func _update_boss(b: Dictionary, delta: float) -> void:
	b["t"] += delta
	if float(b.get("hit", 0.0)) > 0.0:
		b["hit"] = float(b["hit"]) - delta
	_boss_visual(b, delta)
	var enraged: bool = float(b["hp"]) < float(b["maxhp"]) * 0.4
	var rage := 0.72 if enraged else 1.0
	match String(b["brain"]):
		"flyer":
			if not bool(b["arrived"]):
				b["x"] += b["vx"] * delta
				if b["x"] <= W - 340.0:
					b["arrived"] = true
			else:
				b["y"] = 200.0 + sin(b["t"] * 1.1) * 40.0
				b["x"] += sin(b["t"] * 0.5) * 70.0 * delta
		"dropship":
			if not bool(b["arrived"]):
				b["y"] += 130.0 * delta
				if b["y"] >= 200.0:
					b["arrived"] = true
			else:
				b["y"] = 200.0 + sin(b["t"] * 0.9) * 24.0
				b["x"] += sin(b["t"] * 0.7) * 90.0 * delta
		"sidewinder":
			if not bool(b["arrived"]):
				b["x"] += 160.0 * delta
				if b["x"] <= W - 240.0:
					b["arrived"] = true
			else:
				b["x"] += b["dash_dir"] * (380.0 if enraged else 300.0) * delta
				if b["x"] < 190.0:
					b["x"] = 190.0
					b["dash_dir"] = 1
				elif b["x"] > W - 190.0:
					b["x"] = W - 190.0
					b["dash_dir"] = -1
				b["y"] = 230.0 + sin(b["t"] * 1.5) * 20.0
		"fortress":
			if not bool(b["arrived"]):
				b["x"] += -90.0 * delta
				if b["x"] <= W - 300.0:
					b["arrived"] = true
			else:
				b["y"] = 190.0 + sin(b["t"] * 0.6) * 22.0
		"weaver":
			if not bool(b["arrived"]):
				b["x"] += -140.0 * delta
				if b["x"] <= W * 0.62:
					b["arrived"] = true
			else:
				b["x"] += sin(b["t"] * 0.9) * 240.0 * delta
				b["y"] = 180.0 + sin(b["t"] * 1.3) * 60.0
		"prime":
			if not bool(b["arrived"]):
				b["x"] += -120.0 * delta
				if b["x"] <= W - 380.0:
					b["arrived"] = true
			else:
				b["y"] = 190.0 + sin(b["t"] * 1.2) * 44.0
				b["x"] += sin(b["t"] * 0.55) * 80.0 * delta
	if not bool(b["arrived"]):
		return
	# weapons
	b["weapon_t"] -= delta / maxf(0.55, rage)
	if b["weapon_t"] <= 0.0:
		b["weapon_t"] = 1.25 if not enraged else 0.9
		_boss_attack(b, enraged)
	# minion pressure
	b["spawn_t"] -= delta
	if b["spawn_t"] <= 0.0:
		b["spawn_t"] = 5.0 if not enraged else 3.2
		_spawn_enemy()

func _boss_attack(b: Dictionary, enraged: bool) -> void:
	var aim := atan2((GROUND_Y - 100.0) - float(b["y"]), p_x - float(b["x"]))
	var cycle := int(b["weapon_cycle"])
	b["weapon_cycle"] = cycle + 1
	var n := 9 if enraged else 7
	match String(b["brain"]):
		"flyer":
			match cycle % 3:
				0:
					for i in n:
						_boss_fire(b, aim + (i - n / 2.0) * 0.13, 380.0, 11.0)
				1:
					for i in 5:
						_boss_fire(b, aim + randf_range(-0.06, 0.06), 460.0, 9.0)
				2:
					_eshot(Vector2(b["x"], b["y"] + 30.0),
						Vector2(randf_range(-120, 120), 160.0), 14.0, "missile")
		"dropship":
			match cycle % 3:
				0:
					for i in 9:
						_boss_fire(b, PI / 2 - 0.7 + i * 0.16, 320.0, 11.0)
				1:
					for i in 3:
						_eshot(Vector2(b["x"] + (i - 1) * 60.0, b["y"] + 40.0),
							Vector2(0, 60.0), 15.0, "bomb")
				2:
					for i in 3:
						_boss_fire(b, aim + (i - 1) * 0.2, 420.0, 11.0)
		"sidewinder":
			match cycle % 2:
				0:
					for i in 3:
						_boss_fire(b, aim + (i - 1) * 0.08, 560.0, 8.0)
				1:
					for i in 5:
						_boss_fire(b, aim + (i - 2) * 0.15, 430.0, 9.0)
		"fortress":
			match cycle % 2:
				0:
					var m := 20 if enraged else 14
					for i in m:
						_boss_fire(b, TAU * i / m + b["t"] * 0.5, 280.0, 10.0)
				1:
					for i in 11:
						_boss_fire(b, aim + (i - 5) * 0.075, 440.0, 10.0)
		"weaver":
			match cycle % 3:
				0:
					for i in 5:
						_boss_fire(b, aim + (i - 2) * 0.16, 400.0, 10.0)
				1:
					for i in 2:
						_spawn_enemy()
				2:
					_eshot(Vector2(b["x"], b["y"]),
						Vector2((p_x - b["x"]) * 0.4, -260.0), 14.0, "plasma")
		"prime":
			match cycle % 4:
				0:
					for i in 11:
						_boss_fire(b, aim + (i - 5) * 0.12, 420.0, 11.0)
				1:
					var m := 22
					for i in m:
						_boss_fire(b, TAU * i / m + b["t"] * 0.5, 300.0, 10.0)
				2:
					for i in 4:
						_eshot(Vector2(b["x"], b["y"] + 30.0),
							Vector2(randf_range(-160, 160), 180.0), 14.0, "missile")
				3:
					for i in 3:
						_spawn_enemy()
	Jukebox.sfx("rw_eshot", -7.0)

# =================================================================
# THE PLAYER - one big tank part, aim-following turret, real cannonballs
# =================================================================
func _update_player(delta: float) -> void:
	if state in [GS.INTRO, GS.TUNNEL, GS.OVER]:
		# the tank still rolls during the tunnel (auto-drive)
		if state == GS.TUNNEL:
			p_x = move_toward(p_x, W * 0.5, 240.0 * delta)
		_tank_pose(delta)
		return
	# move: the analog force from the LEFT zone
	var spd := 260.0 * (1.0 + _shop_lvl("wheels") * 0.10) \
		* (1.0 + float(buffs["speed"]))
	p_x = clampf(p_x + move_force * spd * delta, 140.0, W - 140.0)
	if absf(move_force) > 0.02:
		p_wheel_spin += move_force * delta * 9.0
	# aim: the RIGHT zone finger, else dead ahead
	var pivot := Vector2(p_x + 4.0, GROUND_Y - 44.0 - 92.0)
	if aim_ptr != -1 or mouse_aim:
		var a := (aim_pos - pivot).angle()
		if a > -0.06 and a < PI / 2:
			a = -0.06
		elif a >= PI / 2 or a < -PI + 0.06:
			a = -PI + 0.06
		p_aim = lerp_angle(p_aim, a, 1.0 - pow(0.0001, delta))
	else:
		p_aim = lerp_angle(p_aim, -PI / 2, 1.0 - pow(0.001, delta))
	# cadence
	var cd_mul := float(buffs["cd"]) * pow(0.92, _shop_lvl("reload"))
	cd_main -= delta
	cd_mg -= delta
	cd_rk -= delta
	cd_mt_mg -= delta
	cd_mt_ice -= delta
	cd_mt_rk -= delta
	var fire := aim_ptr != -1
	if fire and cd_main <= 0.0:
		_fire_main()
		cd_main = maxf(0.14, 0.62 - _shop_lvl("cannon") * 0.02) \
			* cd_mul / (1.0 + float(buffs["rate"]))
	if (_shop_lvl("mg") > 0) and cd_mg <= 0.0:
		_fire_mg()
		cd_mg = maxf(0.05, 0.15 - _shop_lvl("mg_rack") * 0.015) \
			* cd_mul / (1.0 + float(buffs["rate"]))
	if (_shop_lvl("rockets") > 0) and cd_rk <= 0.0:
		_fire_rockets()
		cd_rk = maxf(0.5, 1.7 - _shop_lvl("rocket_rack") * 0.2) * cd_mul
	# the mini tanks answer the call too
	if _mini_owned("mt_mg") and cd_mt_mg <= 0.0:
		_mt_mg_fire()
		cd_mt_mg = 0.16 * cd_mul
	if _mini_owned("mt_ice") and cd_mt_ice <= 0.0:
		_mt_ice_fire()
		cd_mt_ice = 1.5 * cd_mul
	if _mini_owned("mt_rocket") and cd_mt_rk <= 0.0:
		_mt_rocket_fire()
		cd_mt_rk = 2.2 * cd_mul
	_tank_pose(delta)

func _tank_pose(delta: float) -> void:
	tank.position = Vector2(p_x, GROUND_Y - 44.0)
	turret_node.rotation = p_aim
	turret_node.scale.y = 1.0 if absf(p_aim) < PI * 0.55 else -1.0
	if tank.has_meta("mini_mt_mg"):
		var mt: Node2D = tank.get_meta("mini_mt_mg")
		mt.rotation = clampf(p_aim, -PI, 0.0) * 0.5

# ---------------------------------------------------------------- weapons
func _main_dmg() -> float:
	return (18.0 + _shop_lvl("cannon") * 4.5) * (1.0 + float(buffs["dmg"]))

func _fire_main() -> void:
	var pivot := Vector2(p_x + 4.0, GROUND_Y - 44.0 - 92.0)
	var n := 1 + int(buffs["multi"])
	for i in n:
		var a := p_aim + (i - (n - 1) / 2.0) * 0.09
		var crit := randf() < float(buffs["crit"])
		var s := {
			"x": pivot.x + cos(p_aim) * 120.0,
			"y": pivot.y + sin(p_aim) * 120.0,
			"vx": cos(a) * 1250.0, "vy": sin(a) * 1250.0,
			"dmg": _main_dmg() * (2.0 if crit else 1.0),
			"crit": crit, "pierce": int(buffs["pierce"]),
			"explosive": int(buffs["explosive"]), "t": 0.0, "kind": "ball",
		}
		var spr := Sprite2D.new()
		spr.texture = load(HWData.ART + "shots/r_ball_hot.png")
		spr.scale = Vector2(0.5, 0.5)
		spr.position = Vector2(s["x"], s["y"])
		s["spr"] = spr
		shot_layer.add_child(spr)
		shots.append(s)
	p_recoil = 1.0
	Jukebox.sfx("rw_cannon", -4.0)
	for i in 2:
		_fx("muzzle", pivot + Vector2.from_angle(p_aim) * 150.0, 0.12)

func _fire_mg() -> void:
	var pairs := 1 + _shop_lvl("mg_rack")
	var dmg := 4.0 * (1.0 + _shop_lvl("mg_rack") * 0.15) * (1.0 + float(buffs["dmg"]))
	for k in pairs:
		var offx := -46.0 - k * 26.0
		var offx2 := 62.0 + k * 26.0
		for ox in [offx, offx2]:
			var src := Vector2(p_x + ox, GROUND_Y - 44.0 - 64.0)
			var a := -PI / 2 + randf_range(-0.05, 0.05)
			var s := {"x": src.x, "y": src.y,
				"vx": cos(a) * 1650.0, "vy": sin(a) * 1650.0,
				"dmg": dmg, "pierce": 0, "explosive": 0, "t": 0.0,
				"kind": "mg"}
			var spr := Sprite2D.new()
			spr.texture = load(HWData.ART + "shots/r_ball.png")
			spr.scale = Vector2(0.22, 0.22)
			spr.position = Vector2(s["x"], s["y"])
			s["spr"] = spr
			shot_layer.add_child(spr)
			shots.append(s)
	mg_flash = 1.0
	Jukebox.sfx("rw_mg", -8.0, randf_range(0.94, 1.08))

func _fire_rockets() -> void:
	var n := 1 + _shop_lvl("rocket_rack")
	var dmg := 26.0 * (1.0 + _shop_lvl("rocket_rack") * 0.15) \
		* (1.0 + float(buffs["dmg"]))
	for i in n:
		var src := Vector2(p_x + 30.0 + i * 14.0 * (1 if i % 2 == 0 else -1),
			GROUND_Y - 44.0 - 40.0)
		_launch_rocket(src, dmg, 2.6)
	Jukebox.sfx("rw_rocket", -8.0)

func _launch_rocket(src: Vector2, dmg: float, homing: float) -> void:
	if rockets.size() >= 40:
		return
	var r := {"x": src.x, "y": src.y, "vx": randf_range(-40, 40), "vy": -330.0,
		"dmg": dmg, "homing": homing, "target": null, "t": 0.0,
		"launch": 0.32}
	var spr := Sprite2D.new()
	spr.texture = load(HWData.ART + "shots/r_rocket.png")
	spr.scale = Vector2(0.5, 0.5)
	spr.position = src
	r["spr"] = spr
	shot_layer.add_child(spr)
	rockets.append(r)

func _mt_mg_fire() -> void:
	var mt: Node2D = tank.get_meta("mini_mt_mg") if tank.has_meta("mini_mt_mg") else null
	if mt == null:
		return
	var src: Vector2 = mt.global_position
	var a := p_aim if aim_ptr != -1 else -PI / 2
	var s := {"x": src.x, "y": src.y - 8.0,
		"vx": cos(a) * 1500.0, "vy": sin(a) * 1500.0,
		"dmg": 5.0 * (1.0 + float(buffs["dmg"])), "pierce": 0,
		"explosive": 0, "t": 0.0, "kind": "mg"}
	var spr := Sprite2D.new()
	spr.texture = load(HWData.ART + "shots/r_ball.png")
	spr.scale = Vector2(0.24, 0.24)
	spr.position = Vector2(s["x"], s["y"])
	s["spr"] = spr
	shot_layer.add_child(spr)
	shots.append(s)
	Jukebox.sfx("rw_mg", -11.0, 1.15)

func _mt_ice_fire() -> void:
	var mt: Node2D = tank.get_meta("mini_mt_ice") if tank.has_meta("mini_mt_ice") else null
	if mt == null:
		return
	var src: Vector2 = mt.global_position
	var s := {"x": src.x, "y": src.y - 10.0, "vx": randf_range(-60, 60),
		"vy": -520.0, "dmg": 10.0, "pierce": 0, "explosive": 0, "t": 0.0,
		"kind": "ice"}
	var spr := Sprite2D.new()
	spr.texture = load(HWData.ART + "shots/r_iceball.png")
	spr.scale = Vector2(0.5, 0.5)
	spr.position = Vector2(s["x"], s["y"])
	s["spr"] = spr
	shot_layer.add_child(spr)
	shots.append(s)
	Jukebox.sfx("rw_icehit", -12.0, 1.3)

func _mt_rocket_fire() -> void:
	var mt: Node2D = tank.get_meta("mini_mt_rocket") if tank.has_meta("mini_mt_rocket") else null
	if mt == null:
		return
	_launch_rocket(mt.global_position as Vector2, 34.0 * (1.0 + float(buffs["dmg"])), 2.9)
	Jukebox.sfx("rw_rocket", -10.0, 1.1)

# ------------------------------------------------------------- shots tick
func _update_shots(delta: float) -> void:
	var dead: Array = []
	for s in shots:
		var d: Dictionary = s
		d["t"] += delta
		if d["kind"] == "ice":
			d["vy"] += 900.0 * delta
		d["x"] += d["vx"] * delta
		d["y"] += d["vy"] * delta
		var spr: Sprite2D = d["spr"]
		spr.position = Vector2(d["x"], d["y"])
		if d["kind"] == "ball" and d["t"] > 0.1:
			spr.texture = load(HWData.ART + "shots/r_ball.png")
		# off-screen + ground
		if d["x"] < -100.0 or d["x"] > W + 100.0 or d["y"] < -140.0:
			dead.append(d)
			spr.queue_free()
			continue
		if d["kind"] != "mg" and d["y"] > GROUND_Y - 6.0:
			_impact(d, Vector2(d["x"], GROUND_Y - 6.0), {})
			dead.append(d)
			spr.queue_free()
			continue
		# hits
		var hit_e: Dictionary = {}
		for e in enemies:
			var dd: Dictionary = e
			var dx: float = d["x"] - float(dd["x"])
			var dy: float = d["y"] - float(dd["y"])
			var rad: float = float(dd["size"]) * 0.5 + 14.0
			if dx * dx + dy * dy < rad * rad:
				hit_e = dd
				break
		if not hit_e.is_empty():
			var stop := _impact(d, Vector2(d["x"], d["y"]), hit_e)
			if stop or int(d["pierce"]) <= 0:
				dead.append(d)
				spr.queue_free()
			else:
				d["pierce"] = int(d["pierce"]) - 1
	for d in dead:
		shots.erase(d)

## returns true when the shot must die
func _impact(d: Dictionary, at: Vector2, hit_e: Dictionary) -> bool:
	var stopped := true
	if hit_e != null and not hit_e.is_empty():
		var dmg: float = d["dmg"]
		if bool(d.get("crit", false)):
			_fx_text(at, "CRIT", Color(1, 0.7, 0.3))
		if d["kind"] == "ice":
			hit_e["chill"] = 2.5
			_fx("icehit", at, 0.3)
			Jukebox.sfx("rw_icehit", -10.0)
		if float(buffs["slow"]) > 0.0 and d["kind"] != "ice":
			hit_e["chill"] = maxf(float(hit_e.get("chill", 0.0)), 1.2)
		_damage_enemy(hit_e, dmg)
		if float(buffs["lifesteal"]) > 0.0:
			p_hp = minf(p_hp_max, p_hp + dmg * float(buffs["lifesteal"]))
		if int(d.get("explosive", 0)) > 0:
			_explode(at.x, at.y, 0.8)
			for e in enemies.duplicate():
				var ee: Dictionary = e
				if ee == hit_e:
					continue
				var dx: float = float(ee["x"]) - at.x
				var dy: float = float(ee["y"]) - at.y
				if dx * dx + dy * dy < 130.0 * 130.0:
					_damage_enemy(ee, dmg * 0.5)
		# the ricochet card: hop to a second target
		if int(buffs["bounce"]) > 0 and not bool(d.get("bounced", false)):
			d["bounced"] = true
			var best: Dictionary = {}
			var bd := 1e9
			for e in enemies:
				var ee: Dictionary = e
				if ee == hit_e:
					continue
				var dx: float = float(ee["x"]) - at.x
				var dy: float = float(ee["y"]) - at.y
				var dist := dx * dx + dy * dy
				if dist < bd:
					bd = dist
					best = ee
			if not best.is_empty() and bd < 520.0 * 520.0:
				var dirv := Vector2(float(best["x"]) - at.x,
					float(best["y"]) - at.y).normalized()
				d["vx"] = dirv.x * 1100.0
				d["vy"] = dirv.y * 1100.0
				stopped = false
	else:
		_explode(at.x, at.y, 0.5)
		_decal(at.x)
	return stopped

func _update_eshots(delta: float) -> void:
	var dead: Array = []
	for s in eshots:
		var d: Dictionary = s
		d["t"] += delta
		if float(d.get("homing", 0.0)) > 0.0:
			var ang := (Vector2(p_x, GROUND_Y - 90.0)
				- Vector2(d["x"], d["y"])).angle()
			var cur := Vector2(d["vx"], d["vy"]).angle()
			var na := cur + clampf(angle_difference(cur, ang),
				-float(d["homing"]) * delta, float(d["homing"]) * delta)
			var spd := Vector2(d["vx"], d["vy"]).length()
			d["vx"] = cos(na) * spd
			d["vy"] = sin(na) * spd
		if d["kind"] == "bomb" or d["kind"] == "plasma" and d["vy"] < 0.0:
			d["vy"] += 300.0 * delta
		d["x"] += d["vx"] * delta
		d["y"] += d["vy"] * delta
		var spr: Sprite2D = d["spr"]
		spr.position = Vector2(d["x"], d["y"])
		if d["kind"] == "missile":
			spr.rotation = Vector2(d["vx"], d["vy"]).angle() + PI / 2
		if d["x"] < -120.0 or d["x"] > W + 120.0 or d["y"] < -160.0 \
				or d["y"] > H + 120.0:
			dead.append(d)
			spr.queue_free()
			continue
		if d["y"] > GROUND_Y - 8.0:
			_explode(d["x"], GROUND_Y - 8.0, 0.55)
			dead.append(d)
			spr.queue_free()
			continue
		# tank hitbox: the hull slab
		if absf(d["x"] - p_x) < 130.0 and d["y"] > GROUND_Y - 150.0:
			_damage_player(float(d["dmg"]))
			_explode(d["x"], d["y"], 0.5)
			dead.append(d)
			spr.queue_free()
	for d in dead:
		eshots.erase(d)

func _update_rockets(delta: float) -> void:
	var dead: Array = []
	for s in rockets:
		var r: Dictionary = s
		r["t"] += delta
		if r["t"] < float(r["launch"]):
			r["vy"] -= 340.0 * delta
		else:
			if r["target"] == null or enemies.has(r["target"]) == false:
				var best: Dictionary = {}
				var bd := 1e9
				for e in enemies:
					var ee: Dictionary = e
					var dx: float = float(ee["x"]) - float(r["x"])
					var dy: float = float(ee["y"]) - float(r["y"])
					var dist := dx * dx + dy * dy
					if dist < bd:
						bd = dist
						best = ee
				r["target"] = best
			var tgt: Dictionary = r["target"]
			if not tgt.is_empty():
				var des := (Vector2(tgt["x"], tgt["y"])
					- Vector2(r["x"], r["y"])).angle()
				var cur := Vector2(r["vx"], r["vy"]).angle()
				var na := cur + clampf(angle_difference(cur, des),
					-float(r["homing"]) * delta, float(r["homing"]) * delta)
				var spd := minf(980.0, Vector2(r["vx"], r["vy"]).length()
					+ 620.0 * delta)
				r["vx"] = cos(na) * spd
				r["vy"] = sin(na) * spd
		r["x"] += r["vx"] * delta
		r["y"] += r["vy"] * delta
		var spr: Sprite2D = r["spr"]
		spr.position = Vector2(r["x"], r["y"])
		spr.rotation = Vector2(r["vx"], r["vy"]).angle() + PI / 2
		if r["x"] < -140.0 or r["x"] > W + 140.0 or r["y"] < -160.0:
			dead.append(r)
			spr.queue_free()
			continue
		var hit_e: Dictionary = {}
		for e in enemies:
			var ee: Dictionary = e
			var dx: float = r["x"] - float(ee["x"])
			var dy: float = r["y"] - float(ee["y"])
			var rad: float = float(ee["size"]) * 0.5 + 16.0
			if dx * dx + dy * dy < rad * rad:
				hit_e = ee
				break
		if not hit_e.is_empty():
			_damage_enemy(hit_e, float(r["dmg"]))
			_explode(r["x"], r["y"], 0.9)
			Jukebox.sfx("rw_boom_small", -8.0)
			dead.append(r)
			spr.queue_free()
	for d in dead:
		rockets.erase(d)

# ------------------------------------------------------------ damage/kill
func _damage_enemy(e: Dictionary, dmg: float) -> void:
	if e.is_empty() or dmg <= 0.0:
		return
	if float(e.get("shield", 0.0)) > 0.0:
		var sh := float(e["shield"]) - dmg
		if sh < 0.0:
			e["shield"] = 0.0
			e["hp"] = float(e["hp"]) + sh
		else:
			e["shield"] = sh
	else:
		e["hp"] = float(e["hp"]) - dmg
	e["hit"] = 0.09
	if float(e["hp"]) <= 0.0:
		kill_enemy(e, true)

func kill_enemy(e: Dictionary, pay: bool) -> void:
	var is_boss: bool = String(e.get("kind", "")) == "boss"
	enemies.erase(e)
	((e["spr"] as Sprite2D)).queue_free()
	if not pay:
		return
	# SCORE = KILLS (the owner's law): one kill, one point
	set_score(score + 1)
	kills += 1
	# XP orbs
	var xp := int(HWData.ENEMIES.get(String(e["kind"]), {}).get("xp", 8)) \
		if not is_boss else 90
	var orbs := 2 + xp / 8
	for i in orbs:
		_drop(Vector2(e["x"], e["y"]), "xp", maxi(1, xp / orbs))
	# THE GOGACOIN LAW
	coin_kills += 1
	coin_timer += 0.0
	if is_boss:
		# the boss pays the wallet DIRECTLY - ground drops would die in the
		# tunnel swap before the tank could reach them
		add_run_coins(5)
		run["coins"] = int(run["coins"]) + 5
		_fx_boom_chain(e["x"], e["y"])
		Jukebox.sfx("rw_boss_die", -2.0)
		_banner("BOSS DOWN  +5 GOGACOINS", 2.0)
	elif coin_armed:
		coin_armed = false
		coin_kills = 0
		coin_timer = 0.0
		_drop(Vector2(e["x"], e["y"]), "coin", 1)
	if String(e.get("kind", "")) == "splitter":
		for i in 2:
			_spawn_enemy("swarm")
	_explode(e["x"], e["y"], 0.8 if not is_boss else 1.4)
	Jukebox.sfx("rw_boom_small", -9.0)

func _damage_player(dmg: float) -> void:
	if p_invuln > 0.0 or state == GS.OVER:
		return
	var d := dmg * (1.0 - float(buffs["dr"]))
	if p_shield > 0.0:
		p_shield -= d
		if p_shield < 0.0:
			p_hp += p_shield
			p_shield = 0.0
		Jukebox.sfx("rw_shieldhit", -6.0)
	else:
		p_hp -= d
		Jukebox.sfx("rw_hurt", -4.0)
	p_invuln = 0.25
	if p_hp <= 0.0:
		p_hp = 0.0
		_game_over()

# ------------------------------------------------------------- pickups
func _magnet_radius() -> float:
	var base := 170.0 + float(p_level) * 8.0 + _shop_lvl("wheels") * 0.0
	if _mini_owned("mt_magnet"):
		base += 240.0
	return base

func _drop(pos: Vector2, kind: String, value: int) -> void:
	if drops.size() >= 120:
		return
	var spr := Sprite2D.new()
	var tex := "fx/r_xp0.png" if kind == "xp" else "fx/r_coin0.png"
	spr.texture = load(HWData.ART + tex)
	spr.scale = Vector2(0.5, 0.5)
	spr.position = pos
	var d := {"x": pos.x, "y": pos.y, "vx": randf_range(-90, 90),
		"vy": randf_range(-220, -90), "kind": kind, "value": value,
		"t": 0.0, "life": 22.0, "grounded": false, "spr": spr}
	shot_layer.add_child(spr)
	drops.append(d)

func _update_drops(delta: float) -> void:
	var dead: Array = []
	var mag := _magnet_radius()
	var center := Vector2(p_x, GROUND_Y - 90.0)
	for p in drops:
		var d: Dictionary = p
		d["t"] += delta
		d["life"] -= delta
		if d["life"] <= 0.0:
			dead.append(d)
			((d["spr"] as Sprite2D)).queue_free()
			continue
		if not bool(d["grounded"]):
			d["vy"] += 640.0 * delta
			d["x"] += d["vx"] * delta
			d["y"] += d["vy"] * delta
			if d["y"] >= GROUND_Y - 16.0:
				d["y"] = GROUND_Y - 16.0
				d["vy"] = -float(d["vy"]) * 0.3
				d["vx"] *= 0.5
				if absf(float(d["vy"])) < 40.0:
					d["grounded"] = true
					d["vy"] = 0.0
		var dist := center.distance_to(Vector2(d["x"], d["y"]))
		if bool(d["grounded"]) and dist < mag:
			var pull := (300.0 + (1.0 - dist / mag) * 780.0) * delta
			var dirv := (center - Vector2(d["x"], d["y"])).normalized()
			d["x"] += dirv.x * pull
			d["y"] += dirv.y * pull
		if dist < 52.0:
			if String(d["kind"]) == "xp":
				_gain_xp(int(d["value"]))
				Jukebox.sfx("rw_pick_xp", -10.0, randf_range(0.9, 1.15))
			else:
				add_run_coins(1)
				run["coins"] = int(run["coins"]) + 1
				Jukebox.sfx("rw_pick_coin", -6.0)
			dead.append(d)
			((d["spr"] as Sprite2D)).queue_free()
			continue
		var spr: Sprite2D = d["spr"]
		spr.position = Vector2(d["x"], d["y"] + sin(d["t"] * 4.0) * 2.0)
		# the flicker-then-fade law for expiring drops
		if d["life"] < 3.0:
			spr.visible = fmod(d["life"], 0.3) > 0.12
	for d in dead:
		drops.erase(d)

func _gain_xp(n: int) -> void:
	p_xp += n
	while p_xp >= p_xp_next:
		p_xp -= p_xp_next
		p_level += 1
		p_xp_next = maxi(24, int(round(float(p_xp_next) * 1.32)))
		_open_cards()

# ---------------------------------------------------------------- cards
var card_choices: Array = []

func _open_cards() -> void:
	if state == GS.OVER:
		return
	var pool := HWData.CARDS.duplicate()
	pool.shuffle()
	card_choices = pool.slice(0, 3)
	paused = true
	get_tree().paused = true
	var vb := sheet_push(0.0, "cards")
	var t := Arc.label("LEVEL %d  -  CHOOSE ONE" % p_level, 34, Arc.INK)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row)
	for c in card_choices:
		var cd: Dictionary = c
		var b := _card_button(cd)
		row.add_child(b)
	for b2 in Arc._buttons_in(vb):
		if b2.disabled:
			continue
		b2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Jukebox.sfx("rw_levelup", -4.0)

func _card_button(cd: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(300, 300)
	var sb := Arc.panel_style(Arc.CARD, 22)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 8
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", Arc.panel_style(Arc.CARD_2, 22))
	b.add_theme_stylebox_override("pressed", Arc.panel_style(Arc.CARD_2, 22))
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 18
	v.offset_bottom = -14
	v.add_theme_constant_override("separation", 10)
	b.add_child(v)
	var ic := TextureRect.new()
	ic.texture = load(HWData.ART + "ui/r_card_%s.png" % String(cd["icon"]))
	ic.custom_minimum_size = Vector2(0, 120)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(ic)
	var name_l := Arc.label(String(cd["name"]), 24, Arc.INK)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(name_l)
	var desc := Arc.label(String(cd["desc"]), 18, Color("6a4a28"), false)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(desc)
	b.pressed.connect(func():
		_pick_card(cd))
	return b

func _pick_card(cd: Dictionary) -> void:
	match String(cd["id"]):
		"dmg": buffs["dmg"] = float(buffs["dmg"]) + 0.20
		"rate": buffs["rate"] = float(buffs["rate"]) + 0.18
		"speed": buffs["speed"] = float(buffs["speed"]) + 0.15
		"hull":
			p_hp_max += 25.0
			p_hp = minf(p_hp_max, p_hp + 25.0)
		"heal": p_hp = p_hp_max
		"pierce": buffs["pierce"] = int(buffs["pierce"]) + 1
		"explosive": buffs["explosive"] = int(buffs["explosive"]) + 1
		"lifesteal": buffs["lifesteal"] = float(buffs["lifesteal"]) + 0.03
		"multi": buffs["multi"] = int(buffs["multi"]) + 1
		"armor": buffs["dr"] = minf(0.65, float(buffs["dr"]) + 0.15)
		"cd": buffs["cd"] = float(buffs["cd"]) * 0.85
		"shield": p_shield = minf(120.0, p_shield + 40.0)
		"crit": buffs["crit"] = float(buffs["crit"]) + 0.10
		"bounce": buffs["bounce"] = 1
		"slow": buffs["slow"] = 1.0
	Jukebox.sfx("rw_card", -4.0)
	sheet_pop()
	paused = false
	get_tree().paused = false

# --------------------------------------------------------------- tunnel
var tunnel := {}
var tunnel_node: Node2D

func _enter_tunnel() -> void:
	state = GS.TUNNEL
	tunnel = {"t": 0.0, "dur": 5.2, "swapped": false, "scroll": 0.0}
	Jukebox.sfx("rw_tunnel", -6.0)
	_banner("ENTERING THE TUNNEL", 1.6)
	# a calm coin trail pays the drive
	for i in 8:
		_drop(Vector2(W * 0.2 + i * 44.0, GROUND_Y - 84.0), "coin", 1)
	_build_tunnel()

func _build_tunnel() -> void:
	tunnel_node = Node2D.new()
	tunnel_node.z_index = 40
	tunnel_node.draw.connect(_draw_tunnel)
	add_child(tunnel_node)

func _draw_tunnel() -> void:
	if tunnel.is_empty() or tunnel_node == null:
		return
	var t: Dictionary = tunnel
	var wall := 150.0
	var top_h := wall + sin(float(t["scroll"]) * 0.021) * 26.0
	var bot_h := wall + sin(float(t["scroll"]) * 0.017 + 2.0) * 26.0
	# the dark
	tunnel_node.draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.024, 0.04, 0.94))
	# rock walls (jagged strips riding the scroll)
	var step := 110.0
	var off := fposmod(float(t["scroll"]) * 0.9, step)
	var pts_top := PackedVector2Array()
	pts_top.append(Vector2(-40, -40))
	pts_top.append(Vector2(W + 40, -40))
	var pts_bot := PackedVector2Array()
	pts_bot.append(Vector2(-40, H + 40))
	pts_bot.append(Vector2(W + 40, H + 40))
	var x := -off
	while x < W + step:
		pts_top.append(Vector2(x, top_h + sin(x * 0.05 + float(t["scroll"]) * 0.02) * 22.0))
		pts_bot.append(Vector2(x, H - bot_h + sin(x * 0.04 + float(t["scroll"]) * 0.015) * 22.0))
		x += step
	tunnel_node.draw_colored_polygon(pts_top, Color(0.10, 0.11, 0.14))
	tunnel_node.draw_colored_polygon(pts_bot, Color(0.10, 0.11, 0.14))
	# wall edge highlight
	for i in range(pts_top.size() - 2):
		tunnel_node.draw_line(pts_top[i + 2], pts_top[i + 1],
			Color(0.24, 0.26, 0.32), 3.0)
		tunnel_node.draw_line(pts_bot[i + 2], pts_bot[i + 1],
			Color(0.24, 0.26, 0.32), 3.0)
	# the lights every 220px
	var lo := fposmod(float(t["scroll"]) * 0.9, 220.0)
	var lx := -lo
	while lx < W + 220.0:
		var ly_t := top_h - 26.0
		var ly_b := H - bot_h + 26.0
		tunnel_node.draw_circle(Vector2(lx, ly_t), 10.0, Color(1.0, 0.85, 0.5, 0.9))
		tunnel_node.draw_circle(Vector2(lx, ly_b), 10.0, Color(1.0, 0.85, 0.5, 0.9))
		tunnel_node.draw_circle(Vector2(lx, ly_t), 34.0, Color(1.0, 0.8, 0.4, 0.10))
		tunnel_node.draw_circle(Vector2(lx, ly_b), 34.0, Color(1.0, 0.8, 0.4, 0.10))
		lx += 220.0
	# steel ribs every 300px
	var ro := fposmod(float(t["scroll"]), 300.0)
	var rx := -ro
	var rib := Color(0.30, 0.33, 0.40, 0.55)
	while rx < W + 300.0:
		tunnel_node.draw_line(Vector2(rx, top_h), Vector2(rx, H - bot_h), rib, 7.0)
		tunnel_node.draw_line(Vector2(rx + 7, top_h), Vector2(rx + 7, H - bot_h),
			Color(0.12, 0.13, 0.16, 0.8), 3.0)
		rx += 300.0
	# the exit glow grows as the tunnel ends
	var out_a: float = clampf((float(t["t"]) - float(t["dur"]) * 0.72)
		/ (float(t["dur"]) * 0.28), 0.0, 1.0)
	if out_a > 0.0:
		tunnel_node.draw_rect(Rect2(0, 0, W, H),
			Color(HWData.PLACES[place_i % 10]["sky_bot"], 0.55 * out_a))

func _free_tunnel() -> void:
	if tunnel_node != null and is_instance_valid(tunnel_node):
		tunnel_node.queue_free()
	tunnel_node = null

func _tick_tunnel(delta: float) -> void:
	var t: Dictionary = tunnel
	t["t"] += delta
	t["scroll"] = float(t["scroll"]) + HWData.WORLD_SPEED * 2.6 * delta
	if tunnel_node != null and is_instance_valid(tunnel_node):
		tunnel_node.queue_redraw()
	var speed_mul: float = 2.0 + float(t["t"]) * 0.5
	_tick_world_scroll(delta, speed_mul)
	if not bool(t["swapped"]) and float(t["t"]) >= float(t["dur"]) * 0.5:
		t["swapped"] = true
		place_i += 1
		if place_i % 10 == 0 and place_i > 0:
			loop += 1
		wave = 1
		enemies.clear()
		eshots.clear()
		drops.clear()
		_swap_place_art()
	# the drive out
	if float(t["t"]) >= float(t["dur"]):
		tunnel = {}
		_free_tunnel()
		_start_place()

# -------------------------------------------------------------------- fx
func _fx(kind: String, at: Vector2, life: float) -> void:
	if fx.size() >= 160:
		return
	var spr := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.add_animation("go")
	frames.set_animation_speed("go", 14.0)
	var n: int = {"muzzle": 2, "icehit": 3, "boom": 6, "smoke": 4}[kind]
	for i in n:
		frames.add_frame("go", load(HWData.ART + "fx/r_%s%d.png" % [kind, i]))
	spr.sprite_frames = frames
	spr.position = at
	spr.scale = Vector2(0.6, 0.6)
	fx_layer.add_child(spr)
	spr.play("go")
	fx.append({"spr": spr, "life": life, "kind": kind})

func _explode(x: float, y: float, sc: float) -> void:
	_fx("boom", Vector2(x, y), 0.42)

func _fx_text(at: Vector2, txt: String, col: Color) -> void:
	# cheap: reuse the banner system for crits (small)
	pass

func _fx_boom_chain(x: float, y: float) -> void:
	for i in 6:
		var t2 := get_tree().create_timer(0.13 * i)
		t2.timeout.connect(func():
			if state != GS.OVER:
				_explode(x + randf_range(-90, 90), y + randf_range(-60, 60), 1.1))

func _update_fx(delta: float) -> void:
	var dead: Array = []
	for f in fx:
		var d: Dictionary = f
		d["life"] -= delta
		if d["life"] <= 0.0:
			dead.append(d)
			((d["spr"] as AnimatedSprite2D)).queue_free()
	for d in dead:
		fx.erase(d)

func _decal(x: float) -> void:
	if decals.size() > 26:
		decals.pop_front()
	decals.append({"x": x, "y": GROUND_Y - 4.0, "t": 0.0})

# ------------------------------------------------------------------- over
func _game_over() -> void:
	if state == GS.OVER:
		return
	state = GS.OVER
	if not tunnel.is_empty():
		tunnel = {}
		_free_tunnel()
	Jukebox.stop_music()
	Jukebox.sfx("rw_gameover", -2.0)
	_explode(p_x, GROUND_Y - 80.0, 1.8)
	_explode(p_x - 60.0, GROUND_Y - 60.0, 1.3)
	meta.record_run(score, place_i + 1, loop, int(run["bosses_killed"]))
	check_achievements()
	# the hull burns before the sheet lands
	var tw := get_tree().create_timer(1.4)
	tw.timeout.connect(func():
		finish_run(score, int(run["coins"])))

# =================================================================
# THE SHOP - skins + the permanent upgrades + the 4 MINI TANKS
# =================================================================
func _shop_open() -> void:
	if state in [GS.PLACE, GS.BOSS, GS.TUNNEL] and not paused:
		paused = true
		get_tree().paused = true
	var vb := sheet_push(0.0, "shop")
	var t := Arc.label("WAR CHEST", 34, Arc.INK)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var wallet := Arc.coin_chip()
	wallet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(wallet)
	var sc := BoxScroll.new()
	sc.game_safe = true
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vp := get_viewport_rect().size
	sc.custom_minimum_size = Vector2(560, clampf(vp.y * 0.5, 300.0, 620.0))
	vb.add_child(sc)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(box)
	box.add_child(_shop_lbl("MINI TANKS"))
	for id in HWData.MINIS:
		box.add_child(_shop_mini_row(id))
	box.add_child(_shop_lbl("UPGRADES"))
	for id in HWData.SHOP_UPG:
		box.add_child(_shop_upg_row(id))
	box.add_child(_shop_lbl("TANK SKINS"))
	for id in HWData.SKINS:
		box.add_child(_shop_skin_row(id))
	box.add_child(Arc.button("BACK TO WAR", Vector2(560, 74), 24, Arc.GOOD,
		func(): _shop_close()))
	for b in Arc._buttons_in(sc):
		if b.disabled:
			continue
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sc.register_tappable(b, Arc._tap_emitter(b))

func _shop_close() -> void:
	sheet_pop()

func _shop_reopen() -> void:
	if not _sheet_stack.is_empty() \
			and String(_sheet_stack[-1].get("id", "")) == "shop":
		sheet_pop()
		_shop_open()

func _shop_lbl(txt: String) -> Label:
	return Arc.fit_label(txt, 24, Arc.HOT, 560)

func _shop_price_btn(txt: String, price: int, cb: Callable) -> Button:
	var b := Arc.coin_button("%s  %d" % [txt, price], Vector2(560, 64),
		22, Arc.ACCENT, cb)
	if Box.coins() < price:
		b.disabled = true
	return b

func _shop_mini_row(id: String) -> Control:
	var m: Dictionary = HWData.MINIS[id]
	if _mini_owned(id):
		var l := Arc.fit_label("%s  -  BOLTED ON" % m["name"], 22, Arc.GOOD, 560)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return l
	return _shop_price_btn(String(m["name"]), int(m["price"]), func():
		if Box.buy_item(game_id, "mini", id, int(m["price"])):
			Jukebox.sfx("rw_buy", -4.0)
			_bolt_mini(id)
		_shop_reopen())

func _bolt_mini(id: String) -> void:
	# rebuild the tank so the new module shows
	for c in tank.get_children():
		c.queue_free()
	tank.remove_child(turret_node)
	_build_tank()

func _shop_upg_row(id: String) -> Control:
	var u: Dictionary = HWData.SHOP_UPG[id]
	var lvl := _shop_lvl(id)
	var maxed: bool = (lvl >= int(u.get("max", 1))) \
		if not bool(u.get("unlock", false)) else lvl >= 1
	if bool(u.get("unlock", false)):
		if lvl > 0:
			var l := Arc.fit_label("%s  -  INSTALLED" % u["name"], 22,
				Arc.GOOD, 560)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			return l
	elif maxed:
		var l2 := Arc.fit_label("%s  -  MAX" % u["name"], 22, Arc.GOOD, 560)
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return l2
	if u.has("requires") and _shop_lvl(String(u["requires"])) <= 0:
		var l3 := Arc.fit_label("%s  -  NEEDS %s" % [u["name"],
			HWData.SHOP_UPG[String(u["requires"])]["name"]], 20,
			Color("8a6a40"), 560)
		l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return l3
	var cost := int(float(u["base"]) * pow(float(u["step"]), lvl))
	return _shop_price_btn("%s  LV%d" % [u["name"], lvl], cost, func():
		if Box.buy_item(game_id, "upg", id, cost):
			Jukebox.sfx("rw_buy", -4.0)
		_shop_reopen())

func _shop_skin_row(id: String) -> Control:
	var sk: Dictionary = HWData.SKINS[id]
	var owned := Box.skin_owned(game_id, id) or int(sk["price"]) == 0
	var on := Box.skin_on(game_id) == id \
		or (int(sk["price"]) == 0 and Box.skin_on(game_id) == "")
	if on:
		var l := Arc.fit_label("%s  (ON)" % sk["name"], 22, Arc.GOOD, 560)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return l
	if owned:
		return Arc.button(String(sk["name"]), Vector2(560, 60), 22,
			Arc.ACCENT, func():
				Box.equip_skin(game_id, id)
				Jukebox.sfx("rw_click", -4.0)
				_apply_skin()
				_shop_reopen())
	return _shop_price_btn(String(sk["name"]), int(sk["price"]), func():
		if Box.buy_skin(game_id, id, int(sk["price"])):
			Jukebox.sfx("rw_buy", -4.0)
			_apply_skin()
		_shop_reopen())

func _goga_sheet_popped(id: String) -> void:
	if id == "cards":
		paused = false
		get_tree().paused = false
	elif id == "shop":
		if paused:
			paused = false
			get_tree().paused = false
		_apply_skin()

# =================================================================
# THE HUD BARS (hull / shield / xp + the wave clock + minis)
# =================================================================
var lbl_place: Label
var lbl_wave: Label
var lbl_lvl: Label
var lbl_kills: Label

func _build_hud_bars() -> void:
	hud_draw = Control.new()
	hud_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_draw.draw.connect(_draw_hud)
	_overlay_root_ref().add_child(hud_draw)
	var box := VBoxContainer.new()
	box.position = Vector2(14, 84)
	box.add_theme_constant_override("separation", 2)
	hud_draw.add_child(box)
	lbl_place = Arc.label("", 20, Color(1, 1, 1, 0.92), false)
	lbl_wave = Arc.label("", 16, Color(1, 1, 1, 0.7), false)
	box.add_child(lbl_place)
	box.add_child(lbl_wave)
	var box2 := VBoxContainer.new()
	box2.set_anchors_preset(Control.PRESET_TOP_WIDE)
	box2.offset_top = 84
	box2.offset_right = -14
	box2.alignment = BoxContainer.ALIGNMENT_END
	hud_draw.add_child(box2)
	lbl_kills = Arc.label("", 22, Color(1, 1, 1, 0.92), false)
	lbl_kills.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_lvl = Arc.label("", 16, Color(1, 1, 1, 0.7), false)
	lbl_lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box2.add_child(lbl_kills)
	box2.add_child(lbl_lvl)

func _draw_hud() -> void:
	if state == GS.INTRO:
		_draw_intro()
		return
	var x := 14.0
	var y := 152.0
	# hull
	var w := 340.0
	hud_draw.draw_rect(Rect2(x - 2, y - 2, w + 4, 22), Color(0, 0, 0, 0.55))
	var pct := clampf(p_hp / p_hp_max, 0.0, 1.0)
	var col := Color("7ac088") if pct > 0.5 \
		else (Color("c88860") if pct > 0.25 else Color("c06060"))
	hud_draw.draw_rect(Rect2(x, y, w * pct, 18), col)
	hud_draw.draw_rect(Rect2(x - 2, y - 2, w + 4, 22), Color(0, 0, 0, 0.4),
		false, 2.0)
	hud_draw.draw_string(Arc.font_ui(), Vector2(x + 8, y + 14),
		"HULL %d / %d" % [ceili(p_hp), int(p_hp_max)],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.9))
	# shield
	if p_shield > 0.0:
		hud_draw.draw_rect(Rect2(x, y + 22, w * clampf(p_shield / 120.0, 0, 1), 7),
			Color("78b8d8"))
	# xp bar
	hud_draw.draw_rect(Rect2(x, y + 32, w, 9), Color(0, 0, 0, 0.5))
	hud_draw.draw_rect(Rect2(x, y + 32, w * clampf(float(p_xp)
		/ float(p_xp_next), 0, 1), 9), Color("a8a0d8"))
	# the mini tank lights
	var mx := x + w + 18
	for mid in ["mt_rocket", "mt_mg", "mt_ice", "mt_magnet"]:
		var on := _mini_owned(mid)
		hud_draw.draw_circle(Vector2(mx, y + 8), 6.0,
			Color("ffb040") if on else Color(1, 1, 1, 0.16))
		mx += 20.0
	# the wave clock at the cap
	if state == GS.PLACE and wave_clock >= HWData.WAVE_MAX_TIME * 0.8:
		hud_draw.draw_string(Arc.font_ui(), Vector2(W / 2 - 60, 60),
			"%d:%02d" % [int(wave_clock) / 60, int(wave_clock) % 60],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 0.6, 0.4))
	# the boss bar
	for e in enemies:
		var d: Dictionary = e
		if String(d.get("kind", "")) == "boss":
			var bw := minf(W - 260.0, 620.0)
			var bx := W / 2.0 - bw / 2.0
			hud_draw.draw_rect(Rect2(bx - 4, 16, bw + 8, 20),
				Color(0, 0, 0, 0.7))
			hud_draw.draw_rect(Rect2(bx, 20, bw * clampf(
				float(d["hp"]) / float(d["maxhp"]), 0, 1), 12),
				Color("b85060"))
			hud_draw.draw_string(Arc.font_ui(), Vector2(W / 2, 12),
				String(d["name"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 13,
				Color(1, 1, 1, 0.9))
	# the banner
	if banner_t > 0.0 and banner != "":
		var a := minf(1.0, banner_t / 0.4)
		hud_draw.draw_string(Arc.font_ui(), Vector2(W / 2, H * 0.2), banner,
			HORIZONTAL_ALIGNMENT_CENTER, -1, 46,
			Color(1, 1, 1, a))
	# labels
	if lbl_place != null:
		lbl_place.text = String(HWData.PLACES[place_i % 10]["name"]) \
			+ ("  II" if place_i >= 10 else "")
		lbl_wave.text = "WAVE %d / %d" % [wave, HWData.WAVES_PER_PLACE]
		lbl_kills.text = "KILLS %d" % score
		lbl_lvl.text = "LVL %d   XP %d/%d" % [p_level, p_xp, p_xp_next]

func _draw_intro() -> void:
	var a := 0.7 + sin(t_state * 3.0) * 0.3
	hud_draw.draw_string(Arc.font_ui(), Vector2(W / 2, H * 0.62),
		"TAP TO DEPLOY", HORIZONTAL_ALIGNMENT_CENTER, -1, 40,
		Color(1, 1, 1, a))
	hud_draw.draw_string(Arc.font_ui(), Vector2(W / 2, H * 0.7),
		"LEFT HALF: hold + slide to roll      RIGHT HALF: hold to aim + fire",
		HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(1, 1, 1, 0.7))
